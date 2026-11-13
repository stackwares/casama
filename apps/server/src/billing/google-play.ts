/**
 * Google Play (Android subscriptions through `in_app_purchase`), D-070. Purchases are checked with
 * the Play Developer API (subscriptionsv2) and acknowledged; renewals, cancellations and refunds
 * arrive as real-time developer notifications (Pub/Sub push).
 */
import { timingSafeEqual } from "node:crypto";
import { createRemoteJWKSet, importPKCS8, jwtVerify, SignJWT } from "jose";
import {
  BillingError,
  type BillingProvider,
  type ParsedEvent,
  providerJson,
  type SubscriptionSnapshot,
  type SubscriptionStatus,
  type WebhookRequest,
} from "./types.ts";

export interface ServiceAccount {
  client_email: string;
  private_key: string;
  token_uri?: string;
}

export interface GooglePlayOptions {
  packageName: string;
  serviceAccount: ServiceAccount;
  baseUrl?: string;
  /** Pub/Sub push auth, either or both: a secret `?token=` on the push URL ... */
  rtdnToken?: string;
  /** ... or the push subscription's OIDC token (audience and optional service account email). */
  rtdnAudience?: string;
  rtdnEmail?: string;
  jwksUrl?: string;
  fetch?: typeof fetch;
}

type SubscriptionV2 = {
  subscriptionState: string;
  acknowledgementState?: string;
  latestOrderId?: string;
  externalAccountIdentifiers?: { obfuscatedExternalAccountId?: string };
  lineItems?: Array<{
    productId: string;
    expiryTime?: string;
    autoRenewingPlan?: { autoRenewEnabled?: boolean };
    offerDetails?: { basePlanId?: string; offerId?: string };
    /** Which phase of the offer the item is in; freeTrial during a free trial (D-249). */
    offerPhase?: { freeTrial?: object; basePrice?: object; introductoryPrice?: object };
  }>;
};

const SCOPE = "https://www.googleapis.com/auth/androidpublisher";

export class GooglePlayProvider implements BillingProvider {
  readonly id = "google_play" as const;
  private readonly opts: GooglePlayOptions;
  private readonly base: string;
  private token: { value: string; until: number } | null = null;
  private jwks: ReturnType<typeof createRemoteJWKSet> | null = null;

  constructor(opts: GooglePlayOptions) {
    this.opts = opts;
    this.base = (opts.baseUrl ?? "https://androidpublisher.googleapis.com").replace(/\/$/, "");
  }

  private get f() {
    return this.opts.fetch ?? fetch;
  }

  private async bearer() {
    if (this.token && this.token.until > Date.now()) return this.token.value;
    const sa = this.opts.serviceAccount;
    const tokenUri = sa.token_uri ?? "https://oauth2.googleapis.com/token";
    const now = Math.floor(Date.now() / 1000);
    const assertion = await new SignJWT({ scope: SCOPE })
      .setProtectedHeader({ alg: "RS256", typ: "JWT" })
      .setIssuer(sa.client_email)
      .setAudience(tokenUri)
      .setIssuedAt(now)
      .setExpirationTime(now + 3600)
      .sign(await importPKCS8(sa.private_key, "RS256"));
    const r = await providerJson<{ access_token: string; expires_in: number }>(
      "Google OAuth",
      this.f(tokenUri, {
        method: "POST",
        headers: { "content-type": "application/x-www-form-urlencoded" },
        body: new URLSearchParams({
          grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
          assertion,
        }),
        signal: AbortSignal.timeout(15_000),
      }),
    );
    this.token = {
      value: r.access_token,
      until: Date.now() + Math.max(60, r.expires_in - 120) * 1000,
    };
    return r.access_token;
  }

  private async call<T>(path: string, init: RequestInit = {}) {
    return providerJson<T>(
      "Google Play Developer API",
      this.f(`${this.base}/androidpublisher/v3/applications/${this.opts.packageName}${path}`, {
        ...init,
        headers: {
          authorization: `Bearer ${await this.bearer()}`,
          "content-type": "application/json",
        },
        signal: AbortSignal.timeout(15_000),
      }),
    );
  }

  async verifyWebhook(req: WebhookRequest) {
    const token = new URL(req.url).searchParams.get("token");
    if (this.opts.rtdnToken && token) {
      const a = Buffer.from(token);
      const b = Buffer.from(this.opts.rtdnToken);
      if (a.length === b.length && timingSafeEqual(a, b)) return;
      throw new BillingError("bad_signature", "Wrong push token", 401);
    }
    const auth = req.headers.get("authorization");
    if (this.opts.rtdnAudience && auth?.startsWith("Bearer ")) {
      this.jwks ??= createRemoteJWKSet(
        new URL(this.opts.jwksUrl ?? "https://www.googleapis.com/oauth2/v3/certs"),
      );
      try {
        const { payload } = await jwtVerify(auth.slice(7), this.jwks, {
          issuer: ["https://accounts.google.com", "accounts.google.com"],
          audience: this.opts.rtdnAudience,
        });
        if (this.opts.rtdnEmail && payload.email !== this.opts.rtdnEmail) throw new Error("email");
        if (this.opts.rtdnEmail && payload.email_verified !== true) throw new Error("unverified");
        return;
      } catch {
        throw new BillingError("bad_signature", "Push token does not verify", 401);
      }
    }
    throw new BillingError("bad_signature", "Unauthenticated push", 401);
  }

  async parseEvent(req: WebhookRequest): Promise<ParsedEvent> {
    const body = JSON.parse(req.rawBody) as { message?: { data?: string; messageId?: string } };
    const msg = body.message;
    if (!msg?.data || !msg.messageId)
      throw new BillingError("bad_event", "Not a Pub/Sub push message", 400);
    const n = JSON.parse(Buffer.from(msg.data, "base64").toString("utf8")) as {
      packageName?: string;
      subscriptionNotification?: { notificationType: number; purchaseToken: string };
      voidedPurchaseNotification?: { purchaseToken: string; productType?: number };
    };
    if (n.packageName && n.packageName !== this.opts.packageName)
      throw new BillingError("wrong_app", "Notification for another app", 400);
    const base = { eventId: msg.messageId, payload: n };
    if (n.voidedPurchaseNotification && (n.voidedPurchaseNotification.productType ?? 1) === 1)
      return {
        ...base,
        type: "voided",
        kind: "subscription",
        externalId: n.voidedPurchaseNotification.purchaseToken,
        refund: true,
      };
    if (n.subscriptionNotification)
      return {
        ...base,
        type: `subscription.${n.subscriptionNotification.notificationType}`,
        kind: "subscription",
        externalId: n.subscriptionNotification.purchaseToken,
        // 12 = SUBSCRIPTION_REVOKED (refunded and access removed).
        revoke: n.subscriptionNotification.notificationType === 12,
      };
    return { ...base, type: "other", kind: "ignored" };
  }

  async fetchSubscription(purchaseToken: string): Promise<SubscriptionSnapshot> {
    const s = await this.call<SubscriptionV2>(
      `/purchases/subscriptionsv2/tokens/${encodeURIComponent(purchaseToken)}`,
    );
    const item = s.lineItems?.[0];
    const end = item?.expiryTime ? new Date(item.expiryTime) : null;
    const state = s.subscriptionState.replace("SUBSCRIPTION_STATE_", "");
    const status: SubscriptionStatus =
      state === "ACTIVE"
        ? item?.offerPhase?.freeTrial
          ? "trialing"
          : "active"
        : state === "IN_GRACE_PERIOD"
          ? "grace"
          : state === "ON_HOLD"
            ? "on_hold"
            : state === "PAUSED"
              ? "paused"
              : state === "CANCELED"
                ? end && end > new Date()
                  ? "active"
                  : "expired"
                : state === "PENDING"
                  ? "pending"
                  : "expired";
    return {
      source: "google_play",
      externalId: purchaseToken,
      productId: item
        ? item.offerDetails?.basePlanId
          ? `${item.productId}:${item.offerDetails.basePlanId}`
          : item.productId
        : "",
      status,
      currentPeriodEnd: end,
      cancelAtPeriodEnd: state === "CANCELED" || item?.autoRenewingPlan?.autoRenewEnabled === false,
      customerId: null,
      orgId: s.externalAccountIdentifiers?.obfuscatedExternalAccountId ?? null,
      raw: s,
    };
  }

  async verifyPurchase(args: { productId: string; purchaseToken?: string }) {
    if (!args.purchaseToken)
      throw new BillingError("bad_purchase", "purchase_token is required for Google Play", 400);
    const snap = await this.fetchSubscription(args.purchaseToken);
    const raw = snap.raw as SubscriptionV2;
    const productId = args.productId.split(":")[0] as string;
    if (raw.acknowledgementState === "ACKNOWLEDGEMENT_STATE_PENDING" && snap.status !== "pending") {
      await this.call(
        `/purchases/subscriptions/${encodeURIComponent(productId)}/tokens/${encodeURIComponent(args.purchaseToken)}:acknowledge`,
        { method: "POST", body: "{}" },
      );
    }
    return snap;
  }

  async verifyConsumable(args: { productId: string; purchaseToken?: string }) {
    if (!args.purchaseToken)
      throw new BillingError("bad_purchase", "purchase_token is required for Google Play", 400);
    const path = `/purchases/products/${encodeURIComponent(args.productId)}/tokens/${encodeURIComponent(args.purchaseToken)}`;
    const p = await this.call<{
      purchaseState?: number;
      consumptionState?: number;
      orderId?: string;
    }>(path);
    // 0 purchased, 1 cancelled, 2 pending.
    if (p.purchaseState !== 0)
      throw new BillingError("purchase_pending", "The purchase hasn't gone through yet", 409);
    // Consuming lets the same pack be bought again; credits are keyed by the order, so a retry
    // after consuming doesn't credit twice.
    if (p.consumptionState !== 1)
      await this.call(`${path}:consume`, { method: "POST", body: "{}" });
    return { purchaseId: p.orderId ?? args.purchaseToken, revoked: false };
  }
}
