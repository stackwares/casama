/**
 * Local stand-ins for Dodo Payments and RevenueCat's REST API v2 (both app stores, D-297), using
 * their real request and response shapes.
 */
import { randomBytes } from "node:crypto";
import { createServer, type IncomingMessage, type Server } from "node:http";
import type { AddressInfo } from "node:net";
import { standardWebhookSignature } from "../src/billing/dodo.ts";
import { revenueCatSignature } from "../src/billing/revenuecat.ts";

type DodoSub = {
  subscription_id: string;
  status: string;
  product_id: string;
  customer: { customer_id: string; email: string };
  next_billing_date: string;
  cancel_at_next_billing_date: boolean;
  metadata: Record<string, string>;
  trial_period_days?: number;
  created_at?: string;
  addons?: Array<{ addon_id: string; quantity: number }>;
};
type DodoPayment = {
  payment_id: string;
  subscription_id: string | null;
  customer: { customer_id: string };
  metadata: Record<string, string>;
  product_cart: Array<{ product_id: string; quantity: number }>;
  status: string;
  /** In cents, as Dodo reports it. */
  total_amount: number;
  currency: string;
  created_at?: string;
  refunds?: Array<{ refund_id: string; amount: number; status: string; is_partial?: boolean }>;
};
/** RevenueCat's v2 subscription, as much of it as the server reads. */
export type RcSub = {
  object: "subscription";
  id: string;
  customer_id: string;
  original_customer_id: string;
  product_id: string;
  status: string;
  gives_access: boolean;
  auto_renewal_status: string;
  current_period_ends_at: number | null;
  store: string;
  store_subscription_identifier: string;
  environment: string;
};
export type RcPurchase = {
  object: "purchase";
  id: string;
  customer_id: string;
  original_customer_id: string;
  product_id: string;
  status: "owned" | "refunded";
  store: string;
  store_purchase_identifier: string;
  environment: string;
  quantity: number;
};
type RcStore = "app_store" | "mac_app_store" | "play_store";

export interface FakeBilling {
  url: string;
  requests: Array<{ method: string; path: string; auth?: string }>;
  dodo: {
    apiKey: string;
    webhookSecret: string;
    subs: Map<string, DodoSub>;
    payments: Map<string, DodoPayment>;
    checkouts: Map<
      string,
      {
        product_id: string;
        metadata: Record<string, string>;
        email?: string;
        trial_period_days?: number;
        /** A Pay What You Want amount, in cents. */
        amount?: number;
        /** An on-demand subscription (a mandate) and what it charges now, in cents. */
        on_demand?: { mandate_only?: boolean; product_price?: number };
      }
    >;
    /** Charges on on-demand subscriptions (domain renewals). */
    charges: Array<{ subscriptionId: string; paymentId: string; amount: number }>;
    /** Refunds asked for. */
    refunds: Array<{ refundId: string; paymentId: string; reason?: string }>;
    /** The next charge fails (payment status "failed"); `pending` answers 409 once. */
    failNextCharge: false | "failed" | "pending";
    /** Refund calls answer 500 while true. */
    failRefunds: boolean;
    usageEvents: Array<Record<string, unknown>>;
    /** Plan changes asked for (D-248): subscription id and the new product. */
    planChanges: Array<{
      subscriptionId: string;
      productId: string;
      body: Record<string, unknown>;
    }>;
    /** Pays a checkout: creates the subscription (or one-time payment) and returns ids. */
    complete(sessionId: string): { subscriptionId: string | null; paymentId: string };
    /** A signed Standard Webhooks delivery. */
    webhook(
      type: string,
      data: Record<string, unknown>,
      opts?: { secret?: string; ts?: number },
    ): {
      headers: Record<string, string>;
      body: string;
    };
  };
  revenuecat: {
    projectId: string;
    apiKey: string;
    webhookAuth: string;
    signingSecret: string;
    /** RevenueCat product id -> store product id. */
    products: Map<string, string>;
    subs: Map<string, RcSub>;
    purchases: Map<string, RcPurchase>;
    /** A subscription bought in a store for a customer (a workspace id). */
    subscribe(s: {
      customerId: string;
      productId: string;
      store?: RcStore;
      status?: string;
      environment?: string;
    }): RcSub;
    /** A one-time purchase (credit pack). */
    buy(p: {
      customerId: string;
      productId: string;
      store?: RcStore;
      environment?: string;
    }): RcPurchase;
    /** A webhook delivery with the Authorization header and signature RevenueCat would send. */
    event(
      type: string,
      e: Record<string, unknown> & { app_user_id: string },
      opts?: { auth?: string; secret?: string },
    ): { headers: Record<string, string>; body: string };
  };
  models: { calls: Array<Record<string, unknown>> };
  stop(): Promise<void>;
}

const readBody = async (req: IncomingMessage) => {
  let s = "";
  for await (const c of req) s += c;
  return s;
};

export async function startFakeBilling(
  opts: {
    /** When set, opening a checkout URL "pays" it and delivers the signed webhook to this API. */
    deliverTo?: string;
    port?: number;
  } = {},
): Promise<FakeBilling> {
  const requests: FakeBilling["requests"] = [];
  // ---- Dodo
  const dodoKey = `dodo_test_${randomBytes(8).toString("hex")}`;
  const webhookSecret = `whsec_${randomBytes(24).toString("base64")}`;
  const subs = new Map<string, DodoSub>();
  const payments = new Map<string, DodoPayment>();
  const checkouts: FakeBilling["dodo"]["checkouts"] = new Map();
  const usageEvents: Array<Record<string, unknown>> = [];
  const planChanges: FakeBilling["dodo"]["planChanges"] = [];
  // ---- RevenueCat
  const rcKey = `sk_${randomBytes(12).toString("hex")}`;
  const rcProducts = new Map<string, string>();
  const rcSubs = new Map<string, RcSub>();
  const rcPurchases = new Map<string, RcPurchase>();
  const rcProject = "projtest01";
  const rcProduct = (storeId: string) => {
    for (const [id, s] of rcProducts) if (s === storeId) return id;
    const id = `prod${randomBytes(5).toString("hex")}`;
    rcProducts.set(id, storeId);
    return id;
  };
  const modelCalls: Array<Record<string, unknown>> = [];

  let url = "";

  const server: Server = createServer(async (req, res) => {
    const u = new URL(req.url ?? "/", "http://x");
    const path = u.pathname;
    const auth = req.headers.authorization;
    requests.push({ method: req.method ?? "GET", path, auth });
    const send = (status: number, body?: unknown, type = "application/json") => {
      res.writeHead(status, { "content-type": type });
      res.end(body === undefined ? "" : typeof body === "string" ? body : JSON.stringify(body));
    };
    try {
      const body = req.method === "GET" ? "" : await readBody(req);
      // ---------------- Hosted checkout and portal pages (local stand-ins)
      const pay = path.match(/^\/pay\/([^/]+)$/);
      if (pay && req.method === "GET") {
        if (!checkouts.has(pay[1] as string)) return send(404, "No such checkout", "text/plain");
        const r = self.dodo.complete(pay[1] as string);
        if (opts.deliverTo) {
          const w = r.subscriptionId
            ? self.dodo.webhook("subscription.active", {
                payload_type: "Subscription",
                subscription_id: r.subscriptionId,
              })
            : self.dodo.webhook("payment.succeeded", {
                payload_type: "Payment",
                payment_id: r.paymentId,
              });
          const res2 = await fetch(`${opts.deliverTo}/hooks/billing/dodo`, {
            method: "POST",
            headers: w.headers,
            body: w.body,
          });
          if (!res2.ok)
            return send(502, `Webhook failed: ${res2.status} ${await res2.text()}`, "text/plain");
        }
        return send(
          200,
          "<html><body><h1>Payment complete</h1><p>You can return to Casama.</p></body></html>",
          "text/html",
        );
      }
      if (path.startsWith("/portal/"))
        return send(200, "<html><body><h1>Customer portal</h1></body></html>", "text/html");
      // ---------------- Dodo
      if (path.startsWith("/dodo/")) {
        if (auth !== `Bearer ${dodoKey}`) return send(401, { code: "UNAUTHORIZED" });
        const p = path.slice(5);
        if (p === "/checkouts" && req.method === "POST") {
          const b = JSON.parse(body);
          const id = `cks_${randomBytes(6).toString("hex")}`;
          checkouts.set(id, {
            product_id: b.product_cart[0].product_id,
            metadata: b.metadata ?? {},
            email: b.customer?.email,
            trial_period_days: b.subscription_data?.trial_period_days,
            amount: b.product_cart[0].amount,
            on_demand: b.subscription_data?.on_demand,
          });
          return send(200, { session_id: id, checkout_url: `${url}/pay/${id}` });
        }
        let m = p.match(/^\/subscriptions\/([^/]+)\/change-plan$/);
        if (m && req.method === "POST") {
          const s = subs.get(m[1] as string);
          if (!s) return send(404, { code: "NOT_FOUND" });
          const b = JSON.parse(body) as Record<string, unknown>;
          s.product_id = b.product_id as string;
          s.addons = (b.addons as DodoSub["addons"]) ?? [];
          planChanges.push({
            subscriptionId: m[1] as string,
            productId: b.product_id as string,
            body: b,
          });
          return send(200, {});
        }
        m = p.match(/^\/subscriptions\/([^/]+)\/charge$/);
        if (m && req.method === "POST") {
          const s = subs.get(m[1] as string);
          if (!s) return send(404, { code: "NOT_FOUND" });
          if (self.dodo.failNextCharge === "pending") {
            self.dodo.failNextCharge = false;
            return send(409, { code: "PAYMENT_PENDING" });
          }
          const b = JSON.parse(body) as {
            product_price: number;
            metadata?: Record<string, string>;
          };
          const paymentId = `pay_${randomBytes(6).toString("hex")}`;
          const failed = self.dodo.failNextCharge === "failed";
          self.dodo.failNextCharge = false;
          payments.set(paymentId, {
            payment_id: paymentId,
            subscription_id: s.subscription_id,
            customer: { customer_id: s.customer.customer_id },
            metadata: { ...s.metadata, ...(b.metadata ?? {}) },
            product_cart: [{ product_id: s.product_id, quantity: 1 }],
            status: failed ? "failed" : "succeeded",
            total_amount: b.product_price,
            currency: "USD",
          });
          self.dodo.charges.push({
            subscriptionId: s.subscription_id,
            paymentId,
            amount: b.product_price,
          });
          return send(200, { payment_id: paymentId });
        }
        if (p === "/refunds" && req.method === "POST") {
          if (self.dodo.failRefunds) return send(500, { code: "INTERNAL" });
          const b = JSON.parse(body) as { payment_id: string; reason?: string };
          const pay = payments.get(b.payment_id);
          if (!pay) return send(404, { code: "NOT_FOUND" });
          const refundId = `ref_${randomBytes(6).toString("hex")}`;
          self.dodo.refunds.push({ refundId, paymentId: b.payment_id, reason: b.reason });
          return send(200, {
            refund_id: refundId,
            payment_id: b.payment_id,
            status: "succeeded",
            amount: pay.total_amount,
          });
        }
        m = p.match(/^\/subscriptions\/([^/]+)$/);
        if (m) {
          const s = subs.get(m[1] as string);
          return s ? send(200, s) : send(404, { code: "NOT_FOUND" });
        }
        m = p.match(/^\/payments\/([^/]+)$/);
        if (m) {
          const pay = payments.get(m[1] as string);
          return pay ? send(200, pay) : send(404, { code: "NOT_FOUND" });
        }
        m = p.match(/^\/customers\/([^/]+)\/customer-portal\/session$/);
        if (m && req.method === "POST")
          return send(200, {
            link: `${url}/portal/${m[1]}?return=${u.searchParams.get("return_url")}`,
          });
        if (p === "/events/ingest" && req.method === "POST") {
          const b = JSON.parse(body) as { events: Array<Record<string, unknown>> };
          usageEvents.push(...b.events);
          return send(200, { ingested_count: b.events.length });
        }
        return send(404, { code: "NOT_FOUND" });
      }
      // ---------------- RevenueCat REST API v2
      const rcBase = `/rc/v2/projects/${rcProject}`;
      if (path.startsWith("/rc/")) {
        if (auth !== `Bearer ${rcKey}`) return send(401, { type: "authentication_error" });
        if (!path.startsWith(rcBase)) return send(404, { type: "resource_missing" });
        const p = path.slice(rcBase.length);
        // Lists come two items a page, so the server has to follow next_page.
        const page = <T extends { id: string }>(all: T[]) => {
          const after = u.searchParams.get("starting_after");
          const from = after ? all.findIndex((x) => x.id === after) + 1 : 0;
          const items = all.slice(from, from + 2);
          const more = from + 2 < all.length;
          const q = new URLSearchParams(u.searchParams);
          q.set("starting_after", items.at(-1)?.id ?? "");
          return send(200, {
            object: "list",
            items,
            next_page: more ? `/v2/projects/${rcProject}${p}?${q}` : null,
          });
        };
        if (p === "/products")
          return page(
            [...rcProducts].map(([id, store_identifier]) => ({
              object: "product",
              id,
              store_identifier,
            })),
          );
        let m = p.match(/^\/customers\/([^/]+)\/(subscriptions|purchases)$/);
        if (m) {
          const c = decodeURIComponent(m[1] as string);
          const subsOf = [...rcSubs.values()].filter((x) => x.customer_id === c);
          const buysOf = [...rcPurchases.values()].filter((x) => x.customer_id === c);
          if (!subsOf.length && !buysOf.length) return send(404, { type: "resource_missing" });
          return m[2] === "subscriptions" ? page(subsOf) : page(buysOf);
        }
        m = p.match(/^\/subscriptions\/([^/]+)$/);
        if (m) {
          const sub = rcSubs.get(decodeURIComponent(m[1] as string));
          return sub ? send(200, sub) : send(404, { type: "resource_missing" });
        }
        if (p === "/subscriptions") {
          const id = u.searchParams.get("store_subscription_identifier");
          return page([...rcSubs.values()].filter((x) => x.store_subscription_identifier === id));
        }
        return send(404, { type: "resource_missing" });
      }
      // ---------------- Model upstream (OpenAI-compatible)
      if (path === "/models/chat/completions" && req.method === "POST") {
        if (auth !== "Bearer upstream-key") return send(401, { error: "bad key" });
        const b = JSON.parse(body) as Record<string, unknown> & { stream?: boolean };
        modelCalls.push(b);
        const usage = { prompt_tokens: 120, completion_tokens: 30, cost: 0.0009 };
        if (!b.stream)
          return send(200, {
            id: "gen-1",
            choices: [
              { index: 0, message: { role: "assistant", content: "Hello from the cloud." } },
            ],
            usage,
          });
        res.writeHead(200, { "content-type": "text/event-stream" });
        for (const piece of ["Hello", " from", " the cloud."])
          res.write(
            `data: ${JSON.stringify({ choices: [{ index: 0, delta: { content: piece } }] })}\n\n`,
          );
        res.write(`data: ${JSON.stringify({ choices: [], usage })}\n\n`);
        res.end("data: [DONE]\n\n");
        return;
      }
      return send(404, {});
    } catch (err) {
      return send(500, { error: (err as Error).message });
    }
  });
  await new Promise<void>((r) => server.listen(opts.port ?? 0, "127.0.0.1", r));
  url = `http://127.0.0.1:${(server.address() as AddressInfo).port}`;

  const self: FakeBilling = {
    url,
    requests,
    dodo: {
      apiKey: dodoKey,
      webhookSecret,
      subs,
      payments,
      checkouts,
      planChanges,
      usageEvents,
      charges: [],
      refunds: [],
      failNextCharge: false,
      failRefunds: false,
      complete(sessionId) {
        const ck = checkouts.get(sessionId);
        if (!ck) throw new Error(`no checkout ${sessionId}`);
        const customer = {
          customer_id: `cus_${randomBytes(5).toString("hex")}`,
          email: ck.email ?? "buyer@example.com",
        };
        const paymentId = `pay_${randomBytes(6).toString("hex")}`;
        let subscriptionId: string | null = null;
        if (ck.product_id.startsWith("pdt_sub_")) {
          subscriptionId = `sub_${randomBytes(6).toString("hex")}`;
          subs.set(subscriptionId, {
            subscription_id: subscriptionId,
            status: "active",
            product_id: ck.product_id,
            customer,
            next_billing_date: new Date(Date.now() + 30 * 86400_000).toISOString(),
            cancel_at_next_billing_date: false,
            metadata: ck.metadata,
            trial_period_days: ck.trial_period_days ?? 0,
            created_at: new Date().toISOString(),
            addons: [],
          });
        }
        payments.set(paymentId, {
          payment_id: paymentId,
          subscription_id: subscriptionId,
          customer,
          metadata: ck.metadata,
          product_cart: [{ product_id: ck.product_id, quantity: 1 }],
          status: "succeeded",
          total_amount: ck.amount ?? ck.on_demand?.product_price ?? 1500,
          currency: "USD",
        });
        return { subscriptionId, paymentId };
      },
      webhook(type, data, opts = {}) {
        const id = `msg_${randomBytes(8).toString("hex")}`;
        const ts = String(opts.ts ?? Math.floor(Date.now() / 1000));
        const body = JSON.stringify({
          business_id: "bus_test",
          type,
          timestamp: new Date().toISOString(),
          data,
        });
        const sig = standardWebhookSignature(opts.secret ?? webhookSecret, id, ts, body);
        return {
          headers: {
            "content-type": "application/json",
            "webhook-id": id,
            "webhook-timestamp": ts,
            "webhook-signature": `v1,${sig}`,
          },
          body,
        };
      },
    },
    revenuecat: {
      projectId: rcProject,
      apiKey: rcKey,
      webhookAuth: randomBytes(16).toString("hex"),
      signingSecret: randomBytes(16).toString("hex"),
      products: rcProducts,
      subs: rcSubs,
      purchases: rcPurchases,
      subscribe(s) {
        const status = s.status ?? "active";
        const sub: RcSub = {
          object: "subscription",
          id: `sub${randomBytes(6).toString("hex")}`,
          customer_id: s.customerId,
          original_customer_id: s.customerId,
          product_id: rcProduct(s.productId),
          status,
          gives_access: ["active", "trialing", "in_grace_period"].includes(status),
          auto_renewal_status: "will_renew",
          current_period_ends_at: Date.now() + 30 * 86400_000,
          store: s.store ?? "app_store",
          store_subscription_identifier: String(2000000000 + Math.floor(Math.random() * 1e8)),
          environment: s.environment ?? "production",
        };
        rcSubs.set(sub.id, sub);
        return sub;
      },
      buy(b) {
        const pur: RcPurchase = {
          object: "purchase",
          id: `purch${randomBytes(6).toString("hex")}`,
          customer_id: b.customerId,
          original_customer_id: b.customerId,
          product_id: rcProduct(b.productId),
          status: "owned",
          store: b.store ?? "app_store",
          store_purchase_identifier: `GPA.${randomBytes(4).toString("hex")}`,
          environment: b.environment ?? "production",
          quantity: 1,
        };
        rcPurchases.set(pur.id, pur);
        return pur;
      },
      event(type, e, opts = {}) {
        const body = JSON.stringify({
          api_version: "1.0",
          event: {
            id: `evt_${randomBytes(8).toString("hex")}`,
            type,
            event_timestamp_ms: Date.now(),
            app_id: "app_test",
            original_app_user_id: e.app_user_id,
            aliases: [e.app_user_id],
            store: "APP_STORE",
            environment: "PRODUCTION",
            ...e,
          },
        });
        const t = String(Math.floor(Date.now() / 1000));
        return {
          headers: {
            "content-type": "application/json",
            authorization: opts.auth ?? self.revenuecat.webhookAuth,
            "x-revenuecat-webhook-signature": `t=${t},v1=${revenueCatSignature(opts.secret ?? self.revenuecat.signingSecret, t, body)}`,
          },
          body,
        };
      },
    },
    models: { calls: modelCalls },
    stop: () => new Promise((r) => server.close(() => r())),
  };
  return self;
}

/** Billing env for a harness pointed at the fakes. */
export function billingEnv(f: FakeBilling): Record<string, string> {
  return {
    BILLING_ENABLED: "true",
    DODO_API_KEY: f.dodo.apiKey,
    DODO_WEBHOOK_SECRET: f.dodo.webhookSecret,
    DODO_API_URL: `${f.url}/dodo`,
    REVENUECAT_PROJECT_ID: f.revenuecat.projectId,
    REVENUECAT_API_KEY: f.revenuecat.apiKey,
    REVENUECAT_WEBHOOK_AUTH: f.revenuecat.webhookAuth,
    REVENUECAT_WEBHOOK_SIGNING_SECRET: f.revenuecat.signingSecret,
    REVENUECAT_API_URL: `${f.url}/rc/v2`,
    CLOUD_MODEL_UPSTREAM_URL: `${f.url}/models`,
    CLOUD_MODEL_UPSTREAM_KEY: "upstream-key",
  };
}
