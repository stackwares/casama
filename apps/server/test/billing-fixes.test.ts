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

  beforeAll(async () => {
    f = await startFakeBilling();
    h = await startHarness({ env: billingEnv(f) });
    await h.handle.db.execute(sql`update public.billing_settings set max_owned_workspaces = 100`);
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
});
