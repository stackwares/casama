/**
 * Apple App Store (iOS subscriptions through `in_app_purchase`), D-070. Purchases are checked
 * with the App Store Server API; renewals, expiries and refunds arrive as App Store Server
 * Notifications V2. Every signed payload is a JWS whose x5c chain must lead to Apple Root CA - G3.
 */
import { X509Certificate } from "node:crypto";
import { readFileSync } from "node:fs";
import { compactVerify, importPKCS8, SignJWT } from "jose";
import {
  BillingError,
  type BillingProvider,
  type ParsedEvent,
  providerJson,
  type SubscriptionSnapshot,
  type SubscriptionStatus,
  type WebhookRequest,
} from "./types.ts";

export const APPLE_ROOT_G3 = new URL("./certs/AppleRootCA-G3.pem", import.meta.url);

// DER encodings of the marker extensions Apple puts on its signing certificates.
const OID_LEAF = Buffer.from("060a2a864886f76364060b01", "hex"); // 1.2.840.113635.100.6.11.1
const OID_INTERMEDIATE = Buffer.from("060a2a864886f76364060201", "hex"); // 1.2.840.113635.100.6.2.1

export function loadRoots(pems: string[]): X509Certificate[] {
  return pems.flatMap((pem) =>
    pem
      .split(/(?=-----BEGIN CERTIFICATE-----)/)
      .filter((p) => p.includes("BEGIN CERTIFICATE"))
      .map((p) => new X509Certificate(p)),
  );
}

/** Verifies an Apple-signed JWS (x5c chain to a trusted root) and returns its payload. */
export async function verifyAppleJws<T>(
  jws: string,
  roots: X509Certificate[],
  now = new Date(),
): Promise<T> {
  const bad = (why: string): never => {
    throw new BillingError("bad_signature", `Apple signature rejected: ${why}`, 401);
  };
  const [h] = jws.split(".");
  let header: { alg?: string; x5c?: string[] };
  try {
    header = JSON.parse(Buffer.from(h ?? "", "base64url").toString("utf8"));
  } catch {
    return bad("malformed header");
  }
  if (header.alg !== "ES256") bad("unexpected algorithm");
  if (!Array.isArray(header.x5c) || header.x5c.length !== 3) bad("certificate chain missing");
  const [leaf, intermediate] = (header.x5c as string[]).map(
    (b) => new X509Certificate(Buffer.from(b, "base64")),
  ) as [X509Certificate, X509Certificate, X509Certificate];
  const root = roots.find((r) => intermediate.checkIssued(r) && intermediate.verify(r.publicKey));
  if (!root) bad("chain does not lead to a trusted root");
  if (!intermediate.ca) bad("intermediate is not a CA");
  if (!(leaf.checkIssued(intermediate) && leaf.verify(intermediate.publicKey)))
    bad("leaf not issued by the intermediate");
  for (const c of [leaf, intermediate]) {
    if (now < new Date(c.validFrom) || now > new Date(c.validTo)) bad("certificate expired");
  }
  if (!leaf.raw.includes(OID_LEAF)) bad("leaf is not an App Store signing certificate");
  if (!intermediate.raw.includes(OID_INTERMEDIATE)) bad("intermediate is not Apple's WWDR CA");
  try {
    const { payload } = await compactVerify(jws, leaf.publicKey, { algorithms: ["ES256"] });
    return JSON.parse(new TextDecoder().decode(payload)) as T;
  } catch {
    return bad("signature does not verify");
  }
}

export interface AppStoreOptions {
  issuerId: string;
  keyId: string;
  /** The in-app purchase key (.p8 PEM). */
  privateKey: string;
  bundleId: string;
  environment?: "production" | "sandbox";
  baseUrl?: string;
  /** Trusted roots as PEM; defaults to Apple Root CA - G3 shipped with Casama. */
  rootPems?: string[];
  fetch?: typeof fetch;
}

type TransactionInfo = {
  transactionId: string;
  originalTransactionId: string;
  productId: string;
  bundleId: string;
  expiresDate?: number;
  appAccountToken?: string;
  revocationDate?: number;
  type?: string;
  environment?: string;
  /** 1 = introductory offer; with offerDiscountType FREE_TRIAL it is a free trial (D-249). */
  offerType?: number;
  offerDiscountType?: string;
};
type RenewalInfo = { autoRenewStatus?: number; originalTransactionId?: string };

const STATUS: Record<number, SubscriptionStatus> = {
  1: "active",
  2: "expired",
  3: "on_hold",
  4: "grace",
  5: "refunded",
};

export class AppStoreProvider implements BillingProvider {
  readonly id = "app_store" as const;
  private readonly opts: AppStoreOptions;
  private readonly base: string;
  private readonly roots: X509Certificate[];
  private token: { value: string; until: number } | null = null;

  constructor(opts: AppStoreOptions) {
    this.opts = opts;
    this.base = (
      opts.baseUrl ??
      (opts.environment === "sandbox"
        ? "https://api.storekit-sandbox.itunes.apple.com"
        : "https://api.storekit.itunes.apple.com")
    ).replace(/\/$/, "");
    this.roots = loadRoots(opts.rootPems ?? [readFileSync(APPLE_ROOT_G3, "utf8")]);
  }

  private async bearer() {
    if (this.token && this.token.until > Date.now()) return this.token.value;
    const key = await importPKCS8(this.opts.privateKey, "ES256");
    const now = Math.floor(Date.now() / 1000);
    const value = await new SignJWT({ bid: this.opts.bundleId })
      .setProtectedHeader({ alg: "ES256", kid: this.opts.keyId, typ: "JWT" })
      .setIssuer(this.opts.issuerId)
      .setIssuedAt(now)
      .setExpirationTime(now + 20 * 60)
      .setAudience("appstoreconnect-v1")
      .sign(key);
    this.token = { value, until: Date.now() + 15 * 60_000 };
    return value;
  }

  private async call<T>(path: string) {
    const f = this.opts.fetch ?? fetch;
    return providerJson<T>(
      "App Store Server API",
      f(`${this.base}${path}`, {
        headers: { authorization: `Bearer ${await this.bearer()}` },
        signal: AbortSignal.timeout(15_000),
      }),
    );
  }

  private async verified<T extends { bundleId?: string }>(jws: string) {
    const p = await verifyAppleJws<T>(jws, this.roots);
    if (p.bundleId && p.bundleId !== this.opts.bundleId)
      throw new BillingError("wrong_app", "This purchase belongs to another app", 400);
    return p;
  }

  async verifyWebhook(req: WebhookRequest) {
    const { signedPayload } = JSON.parse(req.rawBody) as { signedPayload?: string };
    if (!signedPayload) throw new BillingError("bad_signature", "Missing signedPayload", 401);
    const p = await verifyAppleJws<{ data?: { bundleId?: string } }>(signedPayload, this.roots);
    if (p.data?.bundleId && p.data.bundleId !== this.opts.bundleId)
      throw new BillingError("wrong_app", "Notification for another app", 400);
  }

  async parseEvent(req: WebhookRequest): Promise<ParsedEvent> {
    const { signedPayload } = JSON.parse(req.rawBody) as { signedPayload: string };
    const n = await verifyAppleJws<{
      notificationType: string;
      subtype?: string;
      notificationUUID: string;
      data?: { signedTransactionInfo?: string };
    }>(signedPayload, this.roots);
    const type = n.subtype ? `${n.notificationType}.${n.subtype}` : n.notificationType;
    const base = { eventId: n.notificationUUID, type, payload: n };
    if (!n.data?.signedTransactionInfo) return { ...base, kind: "ignored" };
    const tx = await this.verified<TransactionInfo>(n.data.signedTransactionInfo);
    // A refunded credit pack takes its credits back (D-248).
    if (tx.type === "Consumable" && n.notificationType === "REFUND")
      return { ...base, kind: "pack_refund", references: [`app_store:${tx.transactionId}`] };
    if (tx.type && tx.type !== "Auto-Renewable Subscription") return { ...base, kind: "ignored" };
    return {
      ...base,
      kind: "subscription",
      externalId: tx.originalTransactionId,
      refund: n.notificationType === "REFUND",
      revoke: n.notificationType === "REVOKE",
    };
  }

  async fetchSubscription(originalTransactionId: string): Promise<SubscriptionSnapshot> {
    const r = await this.call<{
      data: Array<{
        lastTransactions: Array<{
          originalTransactionId: string;
          status: number;
          signedTransactionInfo: string;
          signedRenewalInfo?: string;
        }>;
      }>;
    }>(`/inApps/v1/subscriptions/${encodeURIComponent(originalTransactionId)}`);
    const last = r.data
      .flatMap((g) => g.lastTransactions)
      .find((t) => t.originalTransactionId === originalTransactionId);
    if (!last) throw new BillingError("not_found", "Subscription not found at Apple", 404);
    const tx = await this.verified<TransactionInfo>(last.signedTransactionInfo);
    const renewal = last.signedRenewalInfo
      ? await verifyAppleJws<RenewalInfo>(last.signedRenewalInfo, this.roots)
      : {};
    return {
      source: "app_store",
      externalId: originalTransactionId,
      productId: tx.productId,
      status: tx.revocationDate
        ? "refunded"
        : STATUS[last.status] === "active" &&
            tx.offerType === 1 &&
            tx.offerDiscountType === "FREE_TRIAL"
          ? "trialing"
          : (STATUS[last.status] ?? "expired"),
      currentPeriodEnd: tx.expiresDate ? new Date(tx.expiresDate) : null,
      cancelAtPeriodEnd: renewal.autoRenewStatus === 0,
      customerId: null,
      orgId: tx.appAccountToken ?? null,
      raw: { status: last.status, transaction: tx, renewal },
    };
  }

  async verifyPurchase(args: { productId: string; transactionId?: string }) {
    if (!args.transactionId)
      throw new BillingError("bad_purchase", "transaction_id is required for App Store", 400);
    const r = await this.call<{ signedTransactionInfo: string }>(
      `/inApps/v1/transactions/${encodeURIComponent(args.transactionId)}`,
    );
    const tx = await this.verified<TransactionInfo>(r.signedTransactionInfo);
    if (tx.productId !== args.productId)
      throw new BillingError("bad_purchase", "The transaction is for another product", 400);
    return this.fetchSubscription(tx.originalTransactionId);
  }

  async verifyConsumable(args: { productId: string; transactionId?: string }) {
    if (!args.transactionId)
      throw new BillingError("bad_purchase", "transaction_id is required for App Store", 400);
    const r = await this.call<{ signedTransactionInfo: string }>(
      `/inApps/v1/transactions/${encodeURIComponent(args.transactionId)}`,
    );
    const tx = await this.verified<TransactionInfo>(r.signedTransactionInfo);
    if (tx.productId !== args.productId)
      throw new BillingError("bad_purchase", "The transaction is for another product", 400);
    return { purchaseId: tx.transactionId, revoked: !!tx.revocationDate };
  }
}
