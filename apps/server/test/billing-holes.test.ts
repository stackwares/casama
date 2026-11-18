import { MediaRouter } from "@casama/agent";
import { withUserSession } from "@casama/db";
import { sql } from "drizzle-orm";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { billingEnv, type FakeBilling, startFakeBilling } from "./fake-billing.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

// Holes from docs/MONETIZATION-AUDIT-2026-11-13.md and expiring credits (D-246).
describe("billing holes (D-246)", () => {
  let h: Harness;
  let f: FakeBilling;
  const db = () => h.handle.db;
  const balance = async (orgId: string) =>
    Number(
      (
        await db().execute<{ b: string }>(
          sql`select balance_after as b from public.credit_ledger where org_id = ${orgId}::uuid order by seq desc limit 1`,
        )
      )[0]?.b ?? 0,
    );
  const apply = (orgId: string, delta: number, reason: string, reference: string) =>
    db().execute(
      sql`select public.credit_apply(${orgId}::uuid, ${delta}, ${reason}, ${reference}, null)`,
    );

  beforeAll(async () => {
    f = await startFakeBilling();
    h = await startHarness({ env: billingEnv(f) });
    // The server records that it bills as it starts.
    for (let i = 0; i < 50; i++) {
      const [s] = await db().execute<{ enabled: boolean }>(
        sql`select enabled from public.billing_settings where id`,
      );
      if (s?.enabled) break;
      await new Promise((r) => setTimeout(r, 100));
    }
  }, 180_000);
  afterAll(async () => {
    await h?.stop();
    await f?.stop();
  });

  it("a workspace made outside the API (a direct database call) starts on the free plan, not unlimited", async () => {
    const u = await h.user("direct-rpc@example.com");
    const [org] = await withUserSession(
      db(),
      { sub: u.id, role: "authenticated", email: u.email },
      (tx) =>
        tx.execute<{ id: string; plan: string }>(
          sql`select id, plan from public.create_organization('Sneaky', ${`sneaky-${Date.now()}`})`,
        ),
    );
    expect(org?.plan).toBe("free");
    const [e] = await db().execute<{ plan_code: string; limits: Record<string, unknown> }>(
      sql`select plan_code, limits from public.entitlements where org_id = ${org?.id}::uuid`,
    );
    expect(e?.plan_code).toBe("free");
    expect(e?.limits.credit_gate).toBe(true);
    expect(e?.limits.unlimited).toBeUndefined();
  });

  it("one person owns at most 5 workspaces; only the first free one gets free credits", async () => {
    const u = await h.user("many-spaces@example.com");
    const ids: string[] = [];
    for (let i = 0; i < 5; i++) {
      const res = await h.request("/v1/orgs", {
        method: "POST",
        token: u.token,
        json: { name: `Space ${i}` },
      });
      expect(res.status).toBe(201);
      ids.push((await j(res)).id);
    }
    const sixth = await h.request("/v1/orgs", {
      method: "POST",
      token: u.token,
      json: { name: "Six" },
    });
    expect(sixth.status).toBe(402);
    expect((await j(sixth)).code).toBe("workspace_limit");
    expect(await balance(ids[0] as string)).toBe(1);
    expect(await balance(ids[1] as string)).toBe(0);
  });

  it("credits are spent soonest-expiring first, and lapsed credits come off the balance once", async () => {
    const u = await h.user("expiry@example.com");
    const orgId = (
      await j(
        await h.request("/v1/orgs", { method: "POST", token: u.token, json: { name: "Expiry" } }),
      )
    ).id as string;
    // $1 free (lapses after next month) and a $10 pack (12 months).
    await apply(orgId, 10, "purchase", "test:pack");
    expect(await balance(orgId)).toBe(11);
    // Spending $1.50 empties the monthly lot first, then takes $0.50 from the pack.
    await apply(orgId, -1.5, "usage", "test:use");
    const lots = await db().execute<{ reason: string; remaining: string }>(
      sql`select reason, remaining from public.credit_lots where org_id = ${orgId}::uuid order by created_at`,
    );
    expect(lots.map((l) => [l.reason, Number(l.remaining)])).toEqual([
      ["grant", 0],
      ["purchase", 9.5],
    ]);
    // The pack lapses: it comes off the balance once, even if expiry runs twice.
    await db().execute(
      sql`update public.credit_lots set expires_at = now() - interval '1 second' where org_id = ${orgId}::uuid and reason = 'purchase'`,
    );
    await db().execute(sql`select public.expire_credits()`);
    await db().execute(sql`select public.expire_credits()`);
    expect(await balance(orgId)).toBeCloseTo(0, 6);
  });

  it("a top-up after a negative balance only adds the part above zero as spendable credit", async () => {
    const u = await h.user("debt@example.com");
    const orgId = (
      await j(
        await h.request("/v1/orgs", { method: "POST", token: u.token, json: { name: "Debt" } }),
      )
    ).id as string;
    await apply(orgId, -3, "usage", "test:debt"); // $1 - $3 = -$2
    await apply(orgId, 10, "purchase", "test:pack2"); // -$2 + $10 = $8
    const [lot] = await db().execute<{ remaining: string }>(
      sql`select sum(remaining)::text as remaining from public.credit_lots where org_id = ${orgId}::uuid`,
    );
    expect(Number(lot?.remaining)).toBeCloseTo(8, 6);
    expect(await balance(orgId)).toBeCloseTo(8, 6);
  });

  it("one inviter's friends earn the welcome bonus at most twice the reward cap (D-248)", async () => {
    const inviter = await h.user("inviter-cap@example.com");
    const friends: string[] = [];
    for (let i = 0; i < 3; i++) {
      const f = await h.user(`invited-cap-${i}@example.com`);
      await h.request("/v1/orgs", {
        method: "POST",
        token: f.token,
        json: { name: `Friend ${i}` },
      });
      await db().execute(
        sql`update auth.users set email_confirmed_at = now() where id = ${f.id}::uuid`,
      );
      await db().execute(
        sql`insert into public.referrals (invitee_id, inviter_id, code) values (${f.id}::uuid, ${inviter.id}::uuid, 'CAPTEST')`,
      );
      await db().execute(
        sql`insert into public.analytics_milestones (user_id, milestone) values (${f.id}::uuid, 'first_value') on conflict do nothing`,
      );
      friends.push(f.id);
    }
    // A reward cap of 1: the welcome bonus goes to 2 friends, not 3.
    await db().execute(sql`select * from public.worker_reward_referrals(2, 2, 1, 100)`);
    const rows = await db().execute<{ welcome_usd: string | null }>(sql`
      select welcome_usd from public.referrals where inviter_id = ${inviter.id}::uuid order by created_at`);
    expect(rows.filter((r) => r.welcome_usd != null)).toHaveLength(2);
  });

  it("media says which side runs on the server's key", () => {
    const side = {
      id: "x",
      generateImage: async () => [],
      generateVideo: async () => ({}),
    } as never;
    const r = new MediaRouter(side, side, { image: "openrouter", video: null });
    expect(r.paidBy("image")).toBe("openrouter");
    expect(r.paidBy("video")).toBeNull();
  });
});
