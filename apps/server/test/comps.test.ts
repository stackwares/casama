import { sql } from "drizzle-orm";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { formatCompCode, normalizeCompCode } from "../src/billing/comps.ts";
import { billingEnv, type FakeBilling, startFakeBilling } from "./fake-billing.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

/** Free plans for friends (docs/COMP-PLANS-PLAN.md). */
describe("comps", () => {
  let f: FakeBilling;
  let h: Harness;
  let admin: { id: string; token: string };
  let proCredits: number;
  let made = 0;

  const person = async (name: string) => {
    const u = await h.user(`${name}-${++made}@example.com`);
    const org = (
      await j(await h.request("/v1/orgs", { method: "POST", token: u.token, json: { name } }))
    ).id as string;
    return { ...u, org };
  };
  const billing = async (p: { org: string; token: string }) =>
    j(await h.request(`/v1/orgs/${p.org}/billing`, { token: p.token }));
  const asAdmin = (path: string, method = "GET", json?: unknown) =>
    h.request(path, { method, token: admin.token, json });
  const settle = () => h.deps.billing?.settle();
  const grants = async (org: string) =>
    h.handle.db.execute<{ reference: string; delta: string }>(sql`
      select reference, delta::text from public.credit_ledger
      where org_id = ${org}::uuid and reason = 'grant' and reference like 'monthly:%:pro%' order by created_at`);

  beforeAll(async () => {
    f = await startFakeBilling();
    h = await startHarness({
      env: { ...billingEnv(f), INSTANCE_ADMIN_EMAILS: "comp-admin@example.com" },
    });
    await h.handle.db.execute(
      sql`update public.plans set dodo_product_id = 'pdt_sub_pro', limits = limits - 'trial_days' where code = 'pro'`,
    );
    admin = await h.user("comp-admin@example.com");
    const [p] = await h.handle.db.execute<{ c: string }>(
      sql`select limits->>'monthly_credits_usd' as c from public.plans where code = 'pro'`,
    );
    proCredits = Number(p?.c);
  }, 180_000);
  afterAll(async () => {
    await h?.stop();
    await f?.stop();
  });

  it("reads codes however they're typed", () => {
    expect(formatCompCode("ABCDE12345")).toBe("G-ABCDE-12345");
    expect(normalizeCompCode("g-abcde-12345")).toBe("ABCDE12345");
    expect(normalizeCompCode("https://casama.ai/g/G-ABCDE-12345?x=1")).toBe("ABCDE12345");
    expect(normalizeCompCode("abcdeI2345")).toBe("ABCDE12345");
    expect(normalizeCompCode("ABCDE1234")).toBeNull();
  });

  it("is refused while switched off, and to anyone but the instance owner", async () => {
    const p = await person("off");
    const off = await asAdmin("/v1/admin/comps", "POST", {
      email: p.email,
      plan_code: "pro",
      months: 3,
    });
    expect(off.status).toBe(409);
    expect((await j(off)).code).toBe("comps_off");
    for (const [method, path] of [
      ["GET", "/v1/admin/comps"],
      ["GET", "/v1/admin/comp-codes"],
      ["GET", "/v1/admin/comp-settings"],
    ] as const)
      expect((await h.request(path, { method, token: p.token })).status).toBe(403);
    const hosted = await h.app.request("/v1/admin/comps", {}, { casamaClaims: { sub: admin.id } });
    expect(hosted.status).toBe(403);
    const on = await asAdmin("/v1/admin/comp-settings", "PUT", {
      enabled: true,
      grant_plans: ["plus", "pro", "max"],
      code_plans: ["plus", "pro"],
      max_months: 12,
      max_active: 50,
    });
    expect(on.status).toBe(200);
    const weekly = await asAdmin("/v1/admin/comp-settings", "PUT", {
      enabled: true,
      grant_plans: ["pro_weekly"],
      code_plans: [],
      max_months: 12,
      max_active: 50,
    });
    expect(weekly.status).toBe(400);
  });

  it("gives the plan, its credits every month, and drops back to Free at the end", async () => {
    const p = await person("friend");
    const res = await asAdmin("/v1/admin/comps", "POST", {
      email: p.email.toUpperCase(),
      plan_code: "pro",
      months: 3,
      note: "Beta friend",
    });
    expect(res.status).toBe(200);
    const comp = await j(res);
    expect(comp).toMatchObject({ org_id: p.org, plan_code: "pro", months: 3, from: "grant" });
    expect(comp.email).toMatch(/^fr••••@example\.com$/);

    const b = await billing(p);
    expect(b.plan_code).toBe("pro");
    // Older apps parse `source` as a closed enum and get "Ends on <date>" with nothing to manage.
    expect(b.source).toBe("default");
    expect(b.cancel_at_period_end).toBe(true);
    expect(b.subscriptions).toEqual([]);
    expect(b.comp).toMatchObject({ plan_code: "pro", from: "grant" });
    expect(new Date(b.comp.ends_at).getTime()).toBeGreaterThan(Date.now() + 80 * 86_400_000);
    expect(await grants(p.org)).toEqual([
      expect.objectContaining({ reference: expect.stringMatching(/:pro:comp$/) }),
    ]);
    expect(Number((await grants(p.org))[0]?.delta)).toBe(proCredits);
    // A comp doesn't use up the owner's free trial.
    expect(b.trial_available).toBe(true);

    // A month later the sweep grants the second month, once. The clock can't move, so the first
    // month's grant is relabelled as last month's: this month's is then due.
    await h.handle.db.execute(sql`
      update public.credit_ledger set reference = replace(reference,
          to_char(now() at time zone 'utc', 'YYYY-MM'),
          to_char((now() at time zone 'utc') - interval '1 month', 'YYYY-MM'))
      where org_id = ${p.org}::uuid and reference like 'monthly:%:pro:comp'`);
    await settle();
    await settle();
    expect(await grants(p.org)).toHaveLength(2);

    // Buying the same plan is refused until its last week.
    const early = await h.request(`/v1/orgs/${p.org}/billing/checkout`, {
      method: "POST",
      token: p.token,
      json: { plan_code: "pro" },
    });
    expect(early.status).toBe(409);
    expect((await j(early)).code).toBe("comped");

    // The end passes: back to Free, with the comp marked expired.
    await h.handle.db.execute(sql`
      update public.comps set ends_at = now() - interval '1 second', starts_at = starts_at - interval '3 months' where id = ${comp.id}::uuid`);
    await h.handle.db.execute(sql`
      update public.subscriptions set current_period_end = now() - interval '1 second' where external_id = ${`comp:${comp.id}`}`);
    await settle();
    const after = await billing(p);
    expect(after.plan_code).toBe("free");
    expect(after.comp ?? null).toBeNull();
    const [row] = await h.handle.db.execute<{ end_reason: string }>(
      sql`select end_reason from public.comps where id = ${comp.id}::uuid`,
    );
    expect(row?.end_reason).toBe("expired");
  });

  it("extends and revokes, and refuses a second comp or a bad plan", async () => {
    const p = await person("extend");
    const comp = await j(
      await asAdmin("/v1/admin/comps", "POST", { user_id: p.id, plan_code: "plus", months: 1 }),
    );
    const again = await asAdmin("/v1/admin/comps", "POST", {
      user_id: p.id,
      plan_code: "pro",
      months: 1,
    });
    expect((await j(again)).code).toBe("comp_exists");
    expect(
      (
        await j(
          await asAdmin("/v1/admin/comps", "POST", {
            user_id: p.id,
            plan_code: "pro_yearly",
            months: 1,
          }),
        )
      ).code,
    ).toBe("plan_not_allowed");
    expect(
      (
        await j(
          await asAdmin("/v1/admin/comps", "POST", { user_id: p.id, plan_code: "pro", months: 13 }),
        )
      ).code,
    ).toBe("months_not_allowed");
    expect(
      (
        await j(
          await asAdmin("/v1/admin/comps", "POST", {
            email: "nobody@example.com",
            plan_code: "pro",
            months: 1,
          }),
        )
      ).code,
    ).toBe("user_not_found");

    const ext = await j(await asAdmin(`/v1/admin/comps/${comp.id}`, "PATCH", { extend_months: 2 }));
    expect(ext.months).toBe(3);
    expect(new Date(ext.ends_at).getTime()).toBeGreaterThan(new Date(comp.ends_at).getTime());
    const [sub] = await h.handle.db.execute<{ end: Date }>(sql`
      select current_period_end as end from public.subscriptions where external_id = ${`comp:${comp.id}`}`);
    expect(new Date(sub!.end).toISOString()).toBe(ext.ends_at);

    const rev = await j(await asAdmin(`/v1/admin/comps/${comp.id}`, "PATCH", { revoke: true }));
    expect(rev.end_reason).toBe("revoked");
    expect((await billing(p)).plan_code).toBe("free");
    const list = await j(await asAdmin("/v1/admin/comps?running=true"));
    expect(list.find((c: { id: string }) => c.id === comp.id)).toBeUndefined();
  });

  it("ends when the friend pays for the plan, and counts the conversion", async () => {
    const p = await person("payer");
    const comp = await j(
      await asAdmin("/v1/admin/comps", "POST", { user_id: p.id, plan_code: "pro", months: 1 }),
    );
    // In the last week the plan can be bought to keep it.
    await h.handle.db.execute(sql`
      update public.comps set ends_at = now() + interval '3 days' where id = ${comp.id}::uuid`);
    await h.handle.db.execute(sql`
      update public.subscriptions set current_period_end = now() + interval '3 days' where external_id = ${`comp:${comp.id}`}`);
    const res = await h.request(`/v1/orgs/${p.org}/billing/checkout`, {
      method: "POST",
      token: p.token,
      json: { plan_code: "pro" },
    });
    expect(res.status).toBe(200);
    const session = ((await j(res)).url as string).split("/pay/")[1] as string;
    const paid = f.dodo.complete(session);
    const w = f.dodo.webhook("subscription.active", {
      payload_type: "Subscription",
      subscription_id: paid.subscriptionId,
    });
    expect(
      (
        await h.request("/hooks/billing/dodo", {
          method: "POST",
          headers: { "content-type": "application/json", ...w.headers },
          body: w.body,
        })
      ).status,
    ).toBe(200);
    await settle();
    const [row] = await h.handle.db.execute<{ end_reason: string; converted: boolean }>(sql`
      select end_reason, converted_at is not null as converted from public.comps where id = ${comp.id}::uuid`);
    expect(row).toEqual({ end_reason: "replaced_by_purchase", converted: true });
    const b = await billing(p);
    expect(b.plan_code).toBe("pro");
    expect(b.source).toBe("dodo");
    // The paid month tops up to the plan's full amount, as from Free: the comp's credits don't
    // count against it.
    const [month] = await h.handle.db.execute<{ total: string }>(sql`
      select coalesce(sum(delta), 0)::text as total from public.credit_ledger
      where org_id = ${p.org}::uuid and reason = 'grant' and reference like 'monthly:%' and reference not like '%:comp'`);
    expect(Number(month?.total)).toBe(proCredits);
  });

  it("redeems a gift code once per person, never past its uses, only by a workspace owner", async () => {
    const created = await asAdmin("/v1/admin/comp-codes", "POST", {
      plan_code: "pro",
      months: 2,
      max_redemptions: 2,
      note: "Friends",
    });
    expect(created.status).toBe(200);
    const code = await j(created);
    expect(code.code).toMatch(/^G-[0-9A-Z]{5}-[0-9A-Z]{5}$/);
    expect(code.link).toBe(`https://casama.ai/g/${code.code}`);
    expect(
      (await j(await asAdmin("/v1/admin/comp-codes", "POST", { plan_code: "max", months: 1 })))
        .code,
    ).toBe("plan_not_allowed");
    const listed = await j(await asAdmin("/v1/admin/comp-codes"));
    expect(JSON.stringify(listed)).not.toContain(code.code.slice(2, 7));

    const preview = await h.request(`/v1/comp/preview?code=${encodeURIComponent(code.code)}`);
    expect(await j(preview)).toEqual({ plan_code: "pro", plan_name: "Pro", months: 2 });
    expect((await h.request("/v1/comp/preview?code=G-00000-00000")).status).toBe(404);

    const a = await person("redeem-a");
    const b = await person("redeem-b");
    const c = await person("redeem-c");
    // Only the workspace's owner can redeem into it.
    const notOwner = await h.request("/v1/me/comp/redeem", {
      method: "POST",
      token: b.token,
      json: { code: code.code, org_id: a.org },
    });
    expect(notOwner.status).toBe(403);

    // Two at once for the last places: both of two uses go, never three.
    const results = await Promise.all(
      [a, b, c].map((p) =>
        h.request("/v1/me/comp/redeem", {
          method: "POST",
          token: p.token,
          json: { code: code.code.toLowerCase(), org_id: p.org },
        }),
      ),
    );
    const ok = results.filter((r) => r.status === 200);
    expect(ok).toHaveLength(2);
    const failed = results.find((r) => r.status !== 200);
    expect((await j(failed!)).code).toBe("comp_code_used_up");
    const [used] = await h.handle.db.execute<{ n: number }>(sql`
      select redeemed_count as n from public.comp_codes where id = ${code.id}::uuid`);
    expect(used?.n).toBe(2);

    // One gift code per person, ever.
    const second = await j(
      await asAdmin("/v1/admin/comp-codes", "POST", { plan_code: "plus", months: 1 }),
    );
    const winner = (await Promise.all(ok.map((r) => j(r)))).at(0) as { org_id: string };
    const who = [a, b, c].find((p) => p.org === winner.org_id)!;
    const twice = await h.request("/v1/me/comp/redeem", {
      method: "POST",
      token: who.token,
      json: { code: second.code, org_id: who.org },
    });
    expect((await j(twice)).code).toBe("comp_code_used");

    // A disabled code is gone from the preview and can't be redeemed.
    await asAdmin(`/v1/admin/comp-codes/${second.id}`, "PATCH", { disabled: true });
    expect((await h.request(`/v1/comp/preview?code=${second.code}`)).status).toBe(404);
    const d = await person("redeem-d");
    const disabled = await h.request("/v1/me/comp/redeem", {
      method: "POST",
      token: d.token,
      json: { code: second.code, org_id: d.org },
    });
    expect((await j(disabled)).code).toBe("comp_code_expired");
  });

  it("reminds a week before the end, once", async () => {
    const p = await person("remind");
    const comp = await j(
      await asAdmin("/v1/admin/comps", "POST", { user_id: p.id, plan_code: "pro", months: 2 }),
    );
    await h.handle.db.execute(sql`
      update public.comps set starts_at = now() - interval '50 days', ends_at = now() + interval '5 days'
      where id = ${comp.id}::uuid`);
    await settle();
    await settle();
    const [n] = await h.handle.db.execute<{ pushes: number; emails: number }>(sql`
      select (select count(*)::int from public.notifications where user_id = ${p.id}::uuid and kind = 'comp_ending') as pushes,
        (select count(*)::int from public.email_outbox where org_id = ${p.org}::uuid and kind = 'comp_ending') as emails`);
    expect(n).toEqual({ pushes: 1, emails: 1 });
  });

  it("keeps an append-only log", async () => {
    const [n] = await h.handle.db.execute<{ n: number }>(
      sql`select count(*)::int as n from public.comp_events`,
    );
    expect(n?.n).toBeGreaterThan(5);
    await expect(h.handle.db.execute(sql`delete from public.comp_events`)).rejects.toThrow();
  });
});
