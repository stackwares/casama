/**
 * RevenueCat for App Store (iOS and the Mac App Store build) and Google Play purchases (D-297).
 * The apps buy through the RevenueCat SDK with the workspace id as the app user id, so a RevenueCat
 * customer is a workspace. The server never trusts a webhook body: it checks the authorization
 * header (and the HMAC signature when one is set up), then re-reads the customer's subscriptions
 * and purchases with the REST API v2.
 */
import { createHmac, timingSafeEqual } from "node:crypto";
import {
  BillingError,
  type BillingProvider,
  type ParsedEvent,
  providerJson,
  type StoreCustomer,
  type StorePurchase,
  type SubscriptionSnapshot,
  type SubscriptionStatus,
  type WebhookRequest,
} from "./types.ts";

export interface RevenueCatOptions {
  projectId: string;
  /** A v2 secret key with read access to customers, subscriptions, purchases and products. */
  apiKey: string;
  /** The Authorization header value set on the webhook in RevenueCat's dashboard. */
  webhookAuth: string;
  /** The webhook's signing secret, when signatures are turned on. */
  signingSecret?: string;
  baseUrl?: string;
  fetch?: typeof fetch;
}

/** RevenueCat's store names (REST, lowercase) and the store a purchase lives in. */
const STORES: Record<string, "app_store" | "google_play"> = {
  app_store: "app_store",
  mac_app_store: "app_store",
  play_store: "google_play",
};

type RcSubscription = {
  id: string;
  customer_id: string;
  product_id: string | null;
  status: string;
  gives_access: boolean;
  auto_renewal_status?: string | null;
  current_period_ends_at?: number | null;
  store: string;
  store_subscription_identifier?: string | number | null;
  environment?: string;
};

type RcPurchase = {
  id: string;
  customer_id: string;
  product_id: string;
  status: string;
  store: string;
  store_purchase_identifier?: string | null;
  environment?: string;
};

type RcList<T> = { items: T[]; next_page?: string | null };

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
/** Workspace ids are UUIDs; anything else (an anonymous RevenueCat id) is not a workspace. */
export const isWorkspaceId = (id: unknown): id is string => typeof id === "string" && UUID.test(id);

function status(s: RcSubscription): SubscriptionStatus {
  switch (s.status) {
    case "trialing":
      return "trialing";
    case "active":
      return "active";
    case "in_grace_period":
      return "grace";
    case "in_billing_retry":
      return s.gives_access ? "grace" : "on_hold";
    case "paused":
      return "paused";
    case "expired":
      return "expired";
    case "incomplete":
      return "pending";
    default:
      return s.gives_access ? "active" : "expired";
  }
}

/** The signature header: `t=<unix seconds>,v1=<hex HMAC-SHA256 of "t.body">`. */
export function revenueCatSignature(secret: string, t: string, body: string) {
  return createHmac("sha256", secret).update(`${t}.${body}`).digest("hex");
}

const same = (a: string, b: string) => {
  const x = Buffer.from(a);
  const y = Buffer.from(b);
  return x.length === y.length && timingSafeEqual(x, y);
};

export class RevenueCatProvider implements BillingProvider {
  readonly id = "revenuecat" as const;
  private readonly opts: RevenueCatOptions;
  /** https://api.revenuecat.com/v2, or wherever REVENUECAT_API_URL points. */
  private readonly root: string;
  private readonly base: string;
  /** RevenueCat product id -> store product id; products rarely change, so it's kept. */
  private products = new Map<string, string>();

  constructor(opts: RevenueCatOptions) {
    this.opts = opts;
    this.root = (opts.baseUrl ?? "https://api.revenuecat.com/v2").replace(/\/$/, "");
    this.base = `${this.root}/projects/${encodeURIComponent(opts.projectId)}`;
  }

  private call<T>(pathOrUrl: string) {
    const f = this.opts.fetch ?? fetch;
    const url = pathOrUrl.startsWith("http")
      ? pathOrUrl
      : pathOrUrl.startsWith("/v2/") // next_page links: /v2/projects/...
        ? `${this.root}${pathOrUrl.slice(3)}`
        : `${this.base}${pathOrUrl}`;
    return providerJson<T>(
      "RevenueCat",
      f(url, {
        headers: { authorization: `Bearer ${this.opts.apiKey}`, accept: "application/json" },
        signal: AbortSignal.timeout(15_000),
      }),
    );
  }

  /** Every item of a list, following next_page (a customer has a handful). */
  private async all<T>(path: string): Promise<T[]> {
    const out: T[] = [];
    let next: string | null | undefined = path;
    for (let page = 0; next && page < 20; page++) {
      const r: RcList<T> = await this.call<RcList<T>>(next);
      out.push(...(r.items ?? []));
      next = r.next_page;
    }
    return out;
  }

  private async storeProductId(productId: string): Promise<string> {
    let id = this.products.get(productId);
    if (id) return id;
    const items = await this.all<{ id: string; store_identifier: string }>("/products?limit=100");
    this.products = new Map(items.map((p) => [p.id, p.store_identifier]));
    id = this.products.get(productId);
    if (!id)
      throw new BillingError("unknown_product", `RevenueCat has no product ${productId}`, 400);
    return id;
  }

  async verifyWebhook(req: WebhookRequest) {
    const auth = req.headers.get("authorization") ?? "";
    const expected = this.opts.webhookAuth;
    if (!same(auth, expected) && !same(auth, `Bearer ${expected}`))
      throw new BillingError("bad_signature", "Webhook authorization does not match", 401);
    if (this.opts.signingSecret) {
      const header = req.headers.get("x-revenuecat-webhook-signature") ?? "";
      const parts = Object.fromEntries(
        header.split(",").map((p) => p.trim().split("=", 2) as [string, string]),
      );
      if (
        !parts.t ||
        !parts.v1 ||
        !same(parts.v1, revenueCatSignature(this.opts.signingSecret, parts.t, req.rawBody))
      )
        throw new BillingError("bad_signature", "Webhook signature does not match", 401);
    }
  }

  async parseEvent(req: WebhookRequest): Promise<ParsedEvent> {
    const body = JSON.parse(req.rawBody) as { event?: Record<string, unknown> };
    const ev = body.event ?? {};
    const type = String(ev.type ?? "unknown");
    const base = { eventId: String(ev.id ?? ""), type, payload: body };
    if (!base.eventId) throw new BillingError("bad_event", "Webhook event has no id", 400);
    // Only the app stores; a TEST event or another store's event changes nothing here.
    const store = String(ev.store ?? "").toLowerCase();
    if (type === "TEST" || !(store in STORES)) return { ...base, kind: "ignored" };
    const ids = new Set<string>();
    for (const v of [
      ev.app_user_id,
      ev.original_app_user_id,
      ...((ev.aliases as unknown[]) ?? []),
      ...((ev.transferred_from as unknown[]) ?? []),
      ...((ev.transferred_to as unknown[]) ?? []),
    ])
      if (isWorkspaceId(v)) ids.add(v.toLowerCase());
    const refund = type === "CANCELLATION" && ev.cancel_reason === "CUSTOMER_SUPPORT";
    const refundStoreIds = refund
      ? [ev.transaction_id, ev.original_transaction_id].filter(
          (x): x is string => typeof x === "string" && x.length > 0,
        )
      : [];
    if (!ids.size) return { ...base, kind: "ignored" };
    return { ...base, kind: "customers", customerIds: [...ids], refundStoreIds };
  }

  private async snapshot(s: RcSubscription): Promise<SubscriptionSnapshot | null> {
    const source = STORES[s.store];
    if (!source || !s.product_id) return null;
    return {
      source,
      externalId: s.id,
      productId: await this.storeProductId(s.product_id),
      status: status(s),
      currentPeriodEnd: s.current_period_ends_at ? new Date(s.current_period_ends_at) : null,
      cancelAtPeriodEnd: s.auto_renewal_status === "will_not_renew",
      customerId: s.customer_id,
      orgId: isWorkspaceId(s.customer_id) ? s.customer_id.toLowerCase() : null,
      raw: s,
    };
  }

  async fetchSubscription(externalId: string): Promise<SubscriptionSnapshot> {
    const s = await this.call<RcSubscription>(`/subscriptions/${encodeURIComponent(externalId)}`);
    const snap = await this.snapshot(s);
    if (!snap) throw new BillingError("not_found", "Not an app-store subscription", 404);
    return snap;
  }

  async storeCustomer(customerId: string): Promise<StoreCustomer> {
    const c = encodeURIComponent(customerId);
    let subs: RcSubscription[];
    let buys: RcPurchase[];
    try {
      [subs, buys] = await Promise.all([
        this.all<RcSubscription>(`/customers/${c}/subscriptions?limit=50`),
        this.all<RcPurchase>(`/customers/${c}/purchases?limit=50`),
      ]);
    } catch (err) {
      // A workspace that never opened the store has no RevenueCat customer.
      if (err instanceof BillingError && err.code === "not_found")
        return { subscriptions: [], purchases: [] };
      throw err;
    }
    const subscriptions = (await Promise.all(subs.map((s) => this.snapshot(s)))).filter(
      (s): s is SubscriptionSnapshot => !!s,
    );
    const purchases: StorePurchase[] = [];
    for (const p of buys) {
      const source = STORES[p.store];
      if (!source) continue;
      purchases.push({
        source,
        id: p.id,
        productId: await this.storeProductId(p.product_id),
        status: p.status === "refunded" ? "refunded" : "owned",
        sandbox: p.environment?.toLowerCase() === "sandbox",
      });
    }
    return { subscriptions, purchases };
  }

  async findSubscription(storeId: string): Promise<string | null> {
    const r = await this.call<RcList<RcSubscription>>(
      `/subscriptions?store_subscription_identifier=${encodeURIComponent(storeId)}`,
    );
    return r.items?.[0]?.id ?? null;
  }
}
