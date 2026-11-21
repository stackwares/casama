/**
 * Billing fixes from the bug hunt of 2026-11-21: refunds of older store renewals, sandbox credit
 * packs, partial refunds of web credit packs, and the yearly plan-change top-up.
 */
import { randomUUID } from "node:crypto";
import { sql } from "drizzle-orm";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { billingEnv, type FakeBilling, startFakeBilling } from "./fake-billing.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

describe("billing fixes (bug hunt 2026-11-21)", () => {
  let f: FakeBilling;
  let h: Harness;
  let owner: { id: string; token: string };

  let made = 0;
  const newOrg = async (name: string) => {
    const maker = await h.user(`fixes-maker-${++made}@example.com`);
    const id = (
      await j(await h.request("/v1/orgs", { method: "POST", token: maker.token, json: { name } }))
    ).id as string;
    await h.handle.db.execute(
      sql`update public.memberships set user_id = ${owner.id}::uuid where org_id = ${id}::uuid and user_id = ${maker.id}::uuid`,
    );
    return id;
  };
  const billing = async (orgId: string) =>
    j(await h.request(`/v1/orgs/${orgId}/billing`, { token: owner.token }));
  const hook = (source: string, body: string, headers: Record<string, string> = {}) =>
    h.request(`/hooks/billing/${source}`, {
      method: "POST",
      headers: { "content-type": "application/json", ...headers },
      body,
    });
  const credits = (orgId: string) => h.deps.billing?.balance(orgId) as Promise<number>;
  const monthlyCredits = async (code: string) => {
    const [p] = await h.handle.db.execute<{ c: string }>(
      sql`select limits->>'monthly_credits_usd' as c from public.plans where code = ${code}`,
    );
    return Number(p?.c);
  };

  const dodoHook = async (type: string, data: Record<string, unknown>) => {
    const w = f.dodo.webhook(type, data);
    return hook("dodo", w.body, w.headers);
  };
  const buyPackOnWeb = async (orgId: string) => {
    const res = await h.request(`/v1/orgs/${orgId}/billing/checkout`, {
      method: "POST",
      token: owner.token,
      json: { pack_code: "credits_10" },
    });
    expect(res.status).toBe(200);
    const { url } = await j(res);
    return f.dodo.complete((url as string).split("/pay/")[1] as string);
  };

  beforeAll(async () => {
    f = await startFakeBilling();
    h = await startHarness({ env: billingEnv(f) });
    await h.handle.db.execute(sql`update public.billing_settings set max_owned_workspaces = 100`);
    await h.handle.db.execute(
      sql`update public.credit_packs set dodo_product_id = 'pdt_pack_10' where code = 'credits_10'`,
    );
    owner = await h.user("fixes-owner@example.com");
  }, 180_000);
  afterAll(async () => {
    await h?.stop();
    await f?.stop();
  });

  it("a yearly plan change tops up by the time left in this grant month, not the year", async () => {
    const orgId = await newOrg("Yearly upgrader");
    // The paid year ends in 11 months and 10 days, so this grant month ends in 10 days.
    const end = new Date(Date.now() + 10 * 86_400_000);
    end.setUTCMonth(end.getUTCMonth() + 11);
    const [sub] = await h.handle.db.execute<{ id: string }>(sql`
      insert into public.subscriptions (org_id, source, external_id, plan_code, status, current_period_end)
      values (${orgId}::uuid, 'dodo', ${`sub_${randomUUID()}`}, 'pro_yearly', 'active', ${end.toISOString()}::timestamptz)
      returning id`);
    await h.deps.billing?.recompute(orgId);
    const before = await credits(orgId);
    await h.handle.db.execute(
      sql`update public.subscriptions set plan_code = 'max_yearly' where id = ${sub?.id}::uuid`,
    );
    await h.deps.billing?.recompute(orgId);
    const topUp = (await credits(orgId)) - before;
    const start = new Date(end);
    start.setUTCFullYear(start.getUTCFullYear() - 1);
    const monthEnd = new Date(start);
    monthEnd.setUTCMonth(monthEnd.getUTCMonth() + 1);
    const share = (monthEnd.getTime() - Date.now()) / (monthEnd.getTime() - start.getTime());
    const extra = (await monthlyCredits("max_yearly")) - (await monthlyCredits("pro_yearly"));
    expect(extra).toBeGreaterThan(0);
    expect(topUp).toBeCloseTo(extra * share, 1);
  });

  it("a partial refund of a web credit pack takes back its share, never more than is left", async () => {
    const orgId = await newOrg("Partial pack refund");
    await h.handle.db.execute(
      sql`update public.entitlements set plan_code = 'pro' where org_id = ${orgId}::uuid`,
    );
    const start = await credits(orgId);
    const p = await buyPackOnWeb(orgId);
    await dodoHook("payment.succeeded", { payload_type: "Payment", payment_id: p.paymentId });
    expect(await credits(orgId)).toBeCloseTo(start + 10, 6);
    const pay = f.dodo.payments.get(p.paymentId) as NonNullable<
      ReturnType<typeof f.dodo.payments.get>
    >;
    pay.total_amount = 1500;
    // A third of the price back: $3.33 of the $10, rounded down in the customer's favour.
    pay.refunds = [{ refund_id: "pr_1", amount: 500, status: "succeeded", is_partial: true }];
    await dodoHook("refund.succeeded", {
      payload_type: "Refund",
      refund_id: "pr_1",
      payment_id: p.paymentId,
      is_partial: true,
    });
    expect(await credits(orgId)).toBeCloseTo(start + 6.67, 6);
    // The month's credits are untouched: the pack's own credits paid for the refund.
    const [month] = await h.handle.db.execute<{ remaining: string }>(sql`
      select coalesce(sum(remaining), 0)::text as remaining from public.credit_lots
      where org_id = ${orgId}::uuid and reason = 'grant'`);
    expect(Number(month?.remaining)).toBeCloseTo(start, 6);
    // Most of the pack is spent, then another half of the price comes back: only what's left of
    // the pack goes, and the balance doesn't go below zero.
    await h.deps.billing?.credit(orgId, -(start + 5), "usage", `spend-${orgId}`);
    expect(await credits(orgId)).toBeCloseTo(1.67, 6);
    pay.refunds.push({ refund_id: "pr_2", amount: 750, status: "succeeded", is_partial: true });
    await dodoHook("refund.succeeded", {
      payload_type: "Refund",
      refund_id: "pr_2",
      payment_id: p.paymentId,
      is_partial: true,
    });
    expect(await credits(orgId)).toBeCloseTo(0, 6);
    // The same refund delivered again takes nothing more.
    await dodoHook("refund.succeeded", {
      payload_type: "Refund",
      refund_id: "pr_2",
      payment_id: p.paymentId,
      is_partial: true,
    });
    expect(await credits(orgId)).toBeCloseTo(0, 6);
  });

  it("sandbox credit packs (TestFlight, Play testing) credit for 7 days and are marked sandbox", async () => {
    const orgId = await newOrg("Sandbox packs");
    const start = await credits(orgId);
    const test = f.revenuecat.buy({
      customerId: orgId,
      productId: "ai.casama.credits.10",
      environment: "sandbox",
    });
    const real = f.revenuecat.buy({ customerId: orgId, productId: "ai.casama.credits.10" });
    const res = await h.request(`/v1/orgs/${orgId}/billing/purchases`, {
      method: "POST",
      token: owner.token,
      json: { source: "app_store", product_id: "ai.casama.credits.10" },
    });
    expect(res.status).toBe(200);
    // App Review must see the purchase work: the credits arrive.
    expect(await credits(orgId)).toBeCloseTo(start + 20, 6);
    const rows = await h.handle.db.execute<{
      reference: string;
      sandbox: boolean;
      days: string | null;
    }>(sql`
      select l.reference, c.sandbox, (extract(epoch from l.expires_at - l.created_at) / 86400)::text as days
      from public.credit_lots l join public.credit_ledger c
        on c.org_id = l.org_id and c.reason = l.reason and c.reference = l.reference
      where l.org_id = ${orgId}::uuid and l.reason = 'purchase'`);
    const byRef = new Map(rows.map((r) => [r.reference, r]));
    const sandbox = byRef.get(`revenuecat:${test.id}`);
    expect(sandbox?.sandbox).toBe(true);
    expect(Number(sandbox?.days)).toBeCloseTo(7, 3);
    // A real store pack still never lapses (D-418).
    expect(byRef.get(`revenuecat:${real.id}`)).toMatchObject({ sandbox: false, days: null });
    // Syncing again changes nothing.
    await h.deps.billing?.syncStoreCustomer(orgId);
    expect(await credits(orgId)).toBeCloseTo(start + 20, 6);
    // Seven days on, the sandbox credits lapse; the real pack stays.
    await h.handle.db.execute(sql`
      update public.credit_lots set expires_at = now() - interval '1 second'
      where org_id = ${orgId}::uuid and reference = ${`revenuecat:${test.id}`}`);
    await h.handle.db.execute(sql`select public.expire_credits()`);
    expect(await credits(orgId)).toBeCloseTo(start + 10, 6);
  });
});
