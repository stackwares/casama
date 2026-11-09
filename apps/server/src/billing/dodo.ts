/**
 * Dodo Payments (merchant of record) for web, desktop, credit packs and Cloud Connect (D-070).
 * Hosted checkout and customer portal; Standard Webhooks signatures; usage events for metered plans.
 */
import { createHmac, timingSafeEqual } from "node:crypto";
import {
  BillingError,
  type BillingProvider,
  type ParsedEvent,
  providerJson,
  type SubscriptionSnapshot,
  type SubscriptionStatus,
  type WebhookRequest,
} from "./types.ts";

export interface DodoOptions {
  apiKey: string;
  /** whsec_... from the Dodo dashboard. */
  webhookSecret: string;
  /** test or live; or a full base URL (tests). */
  environment?: "test" | "live";
  baseUrl?: string;
  fetch?: typeof fetch;
  /** Allowed clock skew for webhook timestamps. */
  toleranceSeconds?: number;
}

const STATUS: Record<string, SubscriptionStatus> = {
  pending: "pending",
  active: "active",
  on_hold: "on_hold",
  paused: "paused",
  cancelled: "cancelled",
  failed: "expired",
  expired: "expired",
  past_due: "past_due",
};

type DodoSubscription = {
  subscription_id: string;
  status: string;
  product_id: string;
  customer?: { customer_id?: string; email?: string };
  next_billing_date?: string | null;
  cancel_at_next_billing_date?: boolean;
  metadata?: Record<string, unknown>;
};

/** Standard Webhooks: HMAC-SHA256 over `id.timestamp.body` with the base64 secret after `whsec_`. */
export function standardWebhookSignature(secret: string, id: string, ts: string, body: string) {
  const key = Buffer.from(secret.startsWith("whsec_") ? secret.slice(6) : secret, "base64");
  return createHmac("sha256", key).update(`${id}.${ts}.${body}`).digest("base64");
}

export function verifyStandardWebhook(
  secret: string,
  headers: Headers,
  body: string,
  toleranceSeconds = 300,
  now = Date.now(),
) {
  const id = headers.get("webhook-id");
  const ts = headers.get("webhook-timestamp");
  const sigs = headers.get("webhook-signature");
  if (!id || !ts || !sigs) throw new BillingError("bad_signature", "Missing webhook headers", 401);
  const t = Number(ts);
  if (!Number.isFinite(t) || Math.abs(now / 1000 - t) > toleranceSeconds)
    throw new BillingError("bad_signature", "Webhook timestamp is outside the tolerance", 401);
  const expected = Buffer.from(standardWebhookSignature(secret, id, ts, body));
  const ok = sigs.split(" ").some((s) => {
    const [version, sig] = s.split(",", 2);
    if (version !== "v1" || !sig) return false;
    const got = Buffer.from(sig);
    return got.length === expected.length && timingSafeEqual(got, expected);
  });
  if (!ok) throw new BillingError("bad_signature", "Webhook signature does not match", 401);
}

export class DodoProvider implements BillingProvider {
  readonly id = "dodo" as const;
  private readonly opts: DodoOptions;
  private readonly base: string;

  constructor(opts: DodoOptions) {
    this.opts = opts;
    this.base = (
      opts.baseUrl ??
      (opts.environment === "live"
        ? "https://live.dodopayments.com"
        : "https://test.dodopayments.com")
    ).replace(/\/$/, "");
  }

  private call<T>(path: string, init: RequestInit = {}) {
    const f = this.opts.fetch ?? fetch;
    return providerJson<T>(
      "Dodo Payments",
      f(`${this.base}${path}`, {
        ...init,
        headers: {
          authorization: `Bearer ${this.opts.apiKey}`,
          "content-type": "application/json",
          ...(init.headers as Record<string, string>),
        },
        signal: AbortSignal.timeout(15_000),
      }),
    );
  }

  async verifyWebhook(req: WebhookRequest) {
    verifyStandardWebhook(
      this.opts.webhookSecret,
      req.headers,
      req.rawBody,
      this.opts.toleranceSeconds,
    );
  }

  async parseEvent(req: WebhookRequest): Promise<ParsedEvent> {
    const body = JSON.parse(req.rawBody) as { type: string; data?: Record<string, unknown> };
    const eventId = req.headers.get("webhook-id") as string;
    const base = { eventId, type: body.type, payload: body };
    const data = body.data ?? {};
    if (body.type.startsWith("subscription.") && typeof data.subscription_id === "string")
      return { ...base, kind: "subscription", externalId: data.subscription_id };
    if (body.type === "payment.succeeded" && typeof data.payment_id === "string")
      return { ...base, kind: "payment", paymentId: data.payment_id };
    if (
      (body.type === "refund.succeeded" || body.type === "dispute.lost") &&
      typeof data.payment_id === "string"
    )
      return {
        ...base,
        kind: "refund",
        paymentId: data.payment_id,
        refundId: String(data.refund_id ?? data.dispute_id ?? eventId),
      };
    return { ...base, kind: "ignored" };
  }

  async fetchSubscription(externalId: string): Promise<SubscriptionSnapshot> {
    const s = await this.call<DodoSubscription>(`/subscriptions/${encodeURIComponent(externalId)}`);
    return {
      source: "dodo",
      externalId: s.subscription_id,
      productId: s.product_id,
      status: STATUS[s.status] ?? "pending",
      currentPeriodEnd: s.next_billing_date ? new Date(s.next_billing_date) : null,
      cancelAtPeriodEnd: !!s.cancel_at_next_billing_date,
      customerId: s.customer?.customer_id ?? null,
      orgId: typeof s.metadata?.org_id === "string" ? s.metadata.org_id : null,
      raw: s,
    };
  }

  async fetchPayment(paymentId: string) {
    const p = await this.call<{
      payment_id: string;
      subscription_id?: string | null;
      customer?: { customer_id?: string };
      metadata?: Record<string, unknown>;
      product_cart?: Array<{ product_id: string; quantity: number }> | null;
      status?: string | null;
    }>(`/payments/${encodeURIComponent(paymentId)}`);
    return {
      paymentId: p.payment_id,
      subscriptionId: p.subscription_id ?? null,
      customerId: p.customer?.customer_id ?? null,
      orgId: typeof p.metadata?.org_id === "string" ? p.metadata.org_id : null,
      productIds: (p.product_cart ?? []).flatMap((i) =>
        Array.from({ length: Math.max(1, i.quantity) }, () => i.product_id),
      ),
      status: p.status ?? null,
    };
  }

  async createCheckout(args: {
    productId: string;
    orgId: string;
    email?: string | null;
    customerId?: string | null;
    returnUrl: string;
  }) {
    const r = await this.call<{ session_id: string; checkout_url: string | null }>("/checkouts", {
      method: "POST",
      body: JSON.stringify({
        product_cart: [{ product_id: args.productId, quantity: 1 }],
        customer: args.customerId
          ? { customer_id: args.customerId }
          : args.email
            ? { email: args.email }
            : undefined,
        return_url: args.returnUrl,
        metadata: { org_id: args.orgId },
      }),
    });
    if (!r.checkout_url)
      throw new BillingError("provider_error", "Dodo returned no checkout URL", 502);
    return { url: r.checkout_url, sessionId: r.session_id };
  }

  async customerPortal(args: { customerId: string; returnUrl: string }) {
    const q = new URLSearchParams({ return_url: args.returnUrl });
    const r = await this.call<{ link: string }>(
      `/customers/${encodeURIComponent(args.customerId)}/customer-portal/session?${q}`,
      { method: "POST" },
    );
    return { url: r.link };
  }

  async reportUsage(
    events: Array<{
      eventId: string;
      customerId: string;
      name: string;
      timestamp: Date;
      metadata: Record<string, string | number>;
    }>,
  ) {
    for (let i = 0; i < events.length; i += 1000) {
      await this.call("/events/ingest", {
        method: "POST",
        body: JSON.stringify({
          events: events.slice(i, i + 1000).map((e) => ({
            event_id: e.eventId,
            customer_id: e.customerId,
            event_name: e.name,
            timestamp: e.timestamp.toISOString(),
            metadata: e.metadata,
          })),
        }),
      });
    }
  }
}
