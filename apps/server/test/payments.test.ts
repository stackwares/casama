/** Payments (D-142): always asked, single-use Stripe Issuing cards, placeholders, real-time authorization. */
import { createHmac } from "node:crypto";
import { once } from "node:events";
import { createServer, type Server } from "node:http";
import type { AddressInfo } from "node:net";
import { fileURLToPath } from "node:url";
import {
  bannedPurchase,
  expireCards,
  merchantMatches,
  registerPaymentTools,
  resolveCardPlaceholders,
  StripeIssuingProvider,
  ToolRegistry,
} from "@kasama/agent";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = fileURLToPath(new URL("./fixtures/payments.json", import.meta.url));
const WHSEC = "whsec_test_payments_secret";
let h: Harness;
let stripe: Server;
let stripeUrl = "";
const cards: Array<Record<string, string>> = [];
const canceled: string[] = [];
let owner: { id: string; token: string };
let orgId = "";
let botId = "";

beforeAll(async () => {
  stripe = createServer(async (req, res) => {
    const chunks: Buffer[] = [];
    for await (const c of req) chunks.push(c as Buffer);
    const params = Object.fromEntries(new URLSearchParams(Buffer.concat(chunks).toString()));
    const url = new URL(req.url ?? "/", "http://x");
    const send = (s: number, x: unknown) =>
      res.writeHead(s, { "content-type": "application/json" }).end(JSON.stringify(x));
    if (req.headers.authorization !== "Bearer sk_test_issuing")
      return send(401, { error: { message: "Invalid API key" } });
    if (url.pathname === "/v1/issuing/cardholders")
      return send(200, { id: "ich_1", name: params.name });
    if (url.pathname === "/v1/issuing/cards" && req.method === "POST") {
      cards.push(params);
      return send(200, { id: `ic_${cards.length}`, last4: "4242" });
    }
    const m = url.pathname.match(/^\/v1\/issuing\/cards\/(ic_\d+)$/);
    if (m && req.method === "GET")
      return send(200, {
        id: m[1],
        number: "4242424242424242",
        cvc: "123",
        exp_month: 3,
        exp_year: 2031,
        cardholder: { name: "Ana Test" },
      });
    if (m && req.method === "POST") {
      if (params.status === "canceled") canceled.push(m[1] as string);
      return send(200, { id: m[1], status: params.status });
    }
    send(404, { error: { message: "no route" } });
  }).listen(0, "127.0.0.1");
  await once(stripe, "listening");
  stripeUrl = `http://127.0.0.1:${(stripe.address() as AddressInfo).port}`;
  h = await startHarness({
    env: { STRIPE_API_URL: stripeUrl },
    worker: {
      fixtures: FIXTURES,
      egressExemptCidrs: ["127.0.0.1/32"],
      providerBases: { stripe: stripeUrl },
    },
  });
  owner = await h.user("pay@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "Pay" } }),
    )
  ).id;
  const cred = (
    await j(
      await h.request("/v1/credentials", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, provider: "openrouter", label: "m", api_key: "sk-or-pay" },
      }),
    )
  ).id;
  botId = (
    await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: owner.token,
        json: {
          org_id: orgId,
          name: "Penny",
          autonomy: "autonomous",
          model_policy: { primary: { credential_id: cred, model: "fixture-main" } },
        },
      }),
    )
  ).id;
}, 90_000);
afterAll(async () => {
  await h?.stop();
  stripe?.close();
});

const waitFor = async <T>(
  fn: () => Promise<T | undefined | null | false>,
  what: string,
  ms = 30_000,
): Promise<T> => {
  const until = Date.now() + ms;
  for (;;) {
    const v = await fn();
    if (v) return v;
    if (Date.now() > until) throw new Error(`timed out waiting for ${what}`);
    await new Promise((r) => setTimeout(r, 100));
  }
};
const hook = (event: unknown) => {
  const body = JSON.stringify(event);
  const t = Math.floor(Date.now() / 1000);
  const sig = createHmac("sha256", WHSEC).update(`${t}.${body}`).digest("hex");
  return h.request(`/hooks/payments/${orgId}`, {
    method: "POST",
    headers: { "content-type": "application/json", "stripe-signature": `t=${t},v1=${sig}` },
    body,
  });
};

describe("payments", () => {
  it("even an autonomous bot asks with the amount; the card is single-use, scoped and filled only by tools", async () => {
    const bad = await h.request(`/v1/orgs/${orgId}/payments`, {
      method: "PUT",
      token: owner.token,
      json: {
        secret_key: "sk_wrong_key",
        webhook_secret: WHSEC,
        cardholder: {
          name: "Ana Test",
          email: "pay@example.com",
          line1: "1 Main St",
          city: "Austin",
          state: "TX",
          postal_code: "78701",
          country: "US",
        },
      },
    });
    expect(bad.status).toBe(400);
    const set = await j(
      await h.request(`/v1/orgs/${orgId}/payments`, {
        method: "PUT",
        token: owner.token,
        json: {
          secret_key: "sk_test_issuing",
          webhook_secret: WHSEC,
          cardholder: {
            name: "Ana Test",
            email: "pay@example.com",
            line1: "1 Main St",
            city: "Austin",
            state: "TX",
            postal_code: "78701",
            country: "US",
          },
          monthly_cap_usd: 300,
          bot_monthly_cap_usd: 150,
        },
      }),
    );
    expect(set).toMatchObject({
      connected: true,
      monthly_cap_usd: 300,
      webhook_url: expect.stringContaining(`/hooks/payments/${orgId}`),
    });

    const conv = await j(
      await h.request("/v1/conversations", {
        method: "POST",
        token: owner.token,
        json: { bot_id: botId },
      }),
    );
    const runId = (
      await j(
        await h.request(`/v1/conversations/${conv.id}/messages`, {
          method: "POST",
          token: owner.token,
          json: { text: "Buy the train tickets for Friday" },
        }),
      )
    ).run_id;
    const approval = await waitFor(async () => {
      const p = await j(
        await h.request(`/v1/approvals?org_id=${orgId}&status=pending`, { token: owner.token }),
      );
      return p.items.find((a: { run_id: string }) => a.run_id === runId);
    }, "approval");
    expect(approval.summary).toContain("payments.request");
    expect(approval.summary).toContain("for $89.50");
    expect(approval.args_redacted).toMatchObject({ amount: "$89.50", merchant: "Amtrak" });
    expect(cards).toHaveLength(0);
    // "Always allow" doesn't stick for payments.
    await h.request(`/v1/approvals/${approval.id}/decision`, {
      method: "POST",
      token: owner.token,
      json: { decision: "approved", always_allow: true },
    });
    await waitFor(
      async () =>
        (await j(await h.request(`/v1/runs/${runId}`, { token: owner.token }))).status ===
        "completed",
      "run",
    );
    expect(
      await h.tdb.admin`select 1 from public.tool_grants where tool_name = 'payments.request'`,
    ).toHaveLength(0);

    expect(cards[0]).toMatchObject({
      cardholder: "ich_1",
      currency: "usd",
      type: "virtual",
      "spending_controls[spending_limits][0][amount]": "9398",
      "spending_controls[spending_limits][0][interval]": "all_time",
      "spending_controls[blocked_categories][0]": "security_brokers_dealers",
    });
    const [r] = await h.tdb.admin<
      { id: string; status: string; expires_at: Date }[]
    >`select id, status, expires_at from public.payment_requests where run_id = ${runId}`;
    expect(r!.status).toBe("issued");
    expect(new Date(r!.expires_at).getTime() - Date.now()).toBeGreaterThan(55 * 60_000);
    const evs = (
      await j(await h.request(`/v1/runs/${runId}/events?limit=200`, { token: owner.token }))
    ).items as Array<{ type: string; payload: Record<string, unknown> }>;
    expect(JSON.stringify(evs)).not.toContain("4242424242424242");

    // Only tools fill the placeholders, only for this run's live card; the values are reported for redaction.
    const payments = {
      db: h.handle.db,
      providerFor: async () => ({
        provider: new StripeIssuingProvider({
          secretKey: "sk_test_issuing",
          cardholderId: "ich_1",
          apiUrl: stripeUrl,
        }),
        monthlyCapUsd: 300,
        botMonthlyCapUsd: 150,
      }),
    };
    const redacted: string[] = [];
    const filled = await resolveCardPlaceholders(
      payments,
      { orgId, runId },
      {
        number: `{{card:${r!.id}:number}}`,
        exp: `{{card:${r!.id}:exp}}`,
        cvc: `{{card:${r!.id}:cvc}}`,
      },
      { onValue: (v) => redacted.push(v) },
    );
    expect(filled).toEqual({ number: "4242424242424242", exp: "03/31", cvc: "123" });
    expect(redacted).toEqual(expect.arrayContaining(["4242424242424242", "123"]));
    const [other] = await h.tdb.admin<
      { id: string }[]
    >`insert into public.runs (org_id, bot_id, created_by) values (${orgId}, ${botId}, ${owner.id}) returning id`;
    await expect(
      resolveCardPlaceholders(payments, { orgId, runId: other!.id }, `{{card:${r!.id}:number}}`),
    ).rejects.toThrow(/isn't one this task was given/);

    // Real-time authorization: wrong merchant, too much, then the right one; then it's used up.
    const auth = (merchant: string, amount: number) => ({
      type: "issuing_authorization.request",
      data: {
        object: {
          id: "iauth_1",
          card: { id: "ic_1" },
          pending_request: { amount, currency: "usd" },
          merchant_data: { name: merchant },
        },
      },
    });
    expect(
      (
        await h.request(`/hooks/payments/${orgId}`, {
          method: "POST",
          headers: { "stripe-signature": "t=1,v1=bad" },
          body: "{}",
        })
      ).status,
    ).toBe(400);
    expect(await j(await hook(auth("STEAM GAMES", 5000)))).toEqual({ approved: false });
    expect(await j(await hook(auth("AMTRAK .COM", 9500)))).toEqual({ approved: false });
    expect(await j(await hook(auth("AMTRAK .COM", 9200)))).toEqual({ approved: true });
    await hook({
      type: "issuing_authorization.created",
      data: {
        object: {
          id: "iauth_1",
          approved: true,
          amount: 9200,
          card: { id: "ic_1" },
          merchant_data: { name: "AMTRAK .COM" },
        },
      },
    });
    const [used] = await h.tdb.admin<
      { status: string; spent_cents: string }[]
    >`select status, spent_cents from public.payment_requests where id = ${r!.id}`;
    expect(used).toMatchObject({ status: "used", spent_cents: "9200" });
    expect(canceled).toContain("ic_1");
    expect(await j(await hook(auth("AMTRAK .COM", 100)))).toEqual({ approved: false });
  }, 60_000);

  it("hard bans, monthly caps and the one-hour expiry", async () => {
    expect(bannedPurchase("Coinbase", "buy some bitcoin")).not.toBeNull();
    expect(bannedPurchase("Amazon", "a $50 gift card for mom")).not.toBeNull();
    expect(bannedPurchase("Venmo", "pay back Sam")).not.toBeNull();
    expect(bannedPurchase("Amtrak", "train tickets")).toBeNull();
    expect(merchantMatches("Luigi's Trattoria", "SQ *LUIGIS TRATTORIA")).toBe(true);
    expect(merchantMatches("Amtrak", "UNITED AIRLINES")).toBe(false);

    const reg = new ToolRegistry();
    const payments = {
      db: h.handle.db,
      providerFor: async () => ({
        provider: new StripeIssuingProvider({
          secretKey: "sk_test_issuing",
          cardholderId: "ich_1",
          apiUrl: stripeUrl,
        }),
        monthlyCapUsd: 300,
        botMonthlyCapUsd: 150,
      }),
    };
    registerPaymentTools(reg, payments);
    const [run] = await h.tdb.admin<
      { id: string }[]
    >`insert into public.runs (org_id, bot_id, created_by) values (${orgId}, ${botId}, ${owner.id}) returning id`;
    const ctx = {
      runId: run!.id,
      botId,
      orgId,
      output: async () => {},
      emit: async () => {},
    } as never;
    const pay = (merchant: string, amount: number, reason = "supplies") =>
      reg
        .get("payments.request")!
        .execute({ merchant, amount, currency: "USD", reason } as never, ctx);
    await expect(pay("Binance", 20, "crypto")).rejects.toThrow(/can't pay for securities, crypto/);
    // 92 was spent this month by this bot; its cap is 150.
    await expect(pay("Office Depot", 70)).rejects.toThrow(/this bot's monthly limit of \$150/);
    const ok = await pay("Office Depot", 40);
    expect(ok.preview).toBe("$40.00 at Office Depot");
    await h.tdb
      .admin`update public.payment_requests set expires_at = now() - interval '1 minute' where status = 'issued'`;
    expect(await expireCards(payments)).toBe(1);
    expect(canceled).toContain("ic_2");
    expect(
      (
        await h.tdb.admin<
          { status: string }[]
        >`select status from public.payment_requests where merchant = 'Office Depot'`
      )[0]!.status,
    ).toBe("expired");
  });
});
