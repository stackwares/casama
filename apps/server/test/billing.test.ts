import { fileURLToPath } from "node:url";
import { PLATFORM_OPENROUTER_CREDENTIAL_ID } from "@casama/agent";
import { withUserSession } from "@casama/db";
import { sql } from "drizzle-orm";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { billingEnv, type FakeBilling, startFakeBilling } from "./fake-billing.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

const CHAT = fileURLToPath(new URL("./fixtures/chat.json", import.meta.url));

describe("billing off (self-hosted default)", () => {
  let h: Harness;
  let token: string;
  let orgId: string;
  beforeAll(async () => {
    h = await startHarness();
    token = (await h.user("selfhost-billing@example.com")).token;
    orgId = (
      await j(await h.request("/v1/orgs", { method: "POST", token, json: { name: "Home" } }))
    ).id;
  }, 120_000);
  afterAll(async () => h?.stop());

  it("has no paywall, no limits and no billing endpoints", async () => {
    const b = await j(await h.request(`/v1/orgs/${orgId}/billing`, { token }));
    expect(b).toMatchObject({
      enabled: false,
      plan_code: "selfhost",
      unlimited: true,
      credits_usd: 0,
    });
    expect(b.daily ?? null).toBeNull();
    const plans = await j(await h.request("/v1/billing/plans", { token }));
    expect(plans).toEqual({ enabled: false, plans: [], packs: [] });
    const co = await h.request(`/v1/orgs/${orgId}/billing/checkout`, {
      method: "POST",
      token,
      json: { plan_code: "pro" },
    });
    expect(co.status).toBe(409);
    expect((await h.request("/hooks/billing/dodo", { method: "POST", body: "{}" })).status).toBe(
      404,
    );
    expect((await h.request("/link/v1/whoami")).status).toBe(404);
    for (let i = 0; i < 4; i++) {
      const r = await h.request("/v1/bots", {
        method: "POST",
        token,
        json: { org_id: orgId, name: `Bot ${i}` },
      });
      expect(r.status).toBe(201);
    }
  });
});

describe("billing on (Casama Cloud, Phase 7 gate)", () => {
  let f: FakeBilling;
  let h: Harness;
  let owner: { id: string; token: string };
  let member: { id: string; token: string };

  // Each workspace is made by its own person, because only someone's first free workspace gets free
  // credits (D-246); `owner` takes over the maker's seat so the tests can act on it.
  let made = 0;
  const newOrg = async (name: string) => {
    const maker = await h.user(`cloud-maker-${++made}@example.com`);
    const id = (
      await j(await h.request("/v1/orgs", { method: "POST", token: maker.token, json: { name } }))
    ).id as string;
    // Hand the maker's seat to `owner` (the free plan has one seat).
    await h.handle.db.execute(
      sql`update public.memberships set user_id = ${owner.id}::uuid where org_id = ${id}::uuid and user_id = ${maker.id}::uuid`,
    );
    return id;
  };
  const billing = async (orgId: string, token = owner.token) =>
    j(await h.request(`/v1/orgs/${orgId}/billing`, { token }));
  const hook = (source: string, body: string, headers: Record<string, string> = {}, query = "") =>
    h.request(`/hooks/billing/${source}${query}`, {
      method: "POST",
      headers: { "content-type": "application/json", ...headers },
      body,
    });
  const dodoHook = async (type: string, data: Record<string, unknown>) => {
    const w = f.dodo.webhook(type, data);
    return hook("dodo", w.body, w.headers);
  };
  const buyOnWeb = async (orgId: string, what: { plan_code?: string; pack_code?: string }) => {
    const res = await h.request(`/v1/orgs/${orgId}/billing/checkout`, {
      method: "POST",
      token: owner.token,
      json: what,
    });
    expect(res.status).toBe(200);
    const { url } = await j(res);
    const session = (url as string).split("/pay/")[1] as string;
    return f.dodo.complete(session);
  };

  beforeAll(async () => {
    f = await startFakeBilling();
    h = await startHarness({ env: billingEnv(f), worker: { fixtures: CHAT } });
    // This suite makes many workspaces for one person; the default is 5 (D-246).
    await h.handle.db.execute(sql`update public.billing_settings set max_owned_workspaces = 100`);
    // Trials have their own suite (pricing-d249.test.ts); here a purchase is paid at once.
    await h.handle.db.execute(
      sql`update public.plans set dodo_product_id = 'pdt_sub_pro', limits = limits - 'trial_days' where code = 'pro'`,
    );
    await h.handle.db.execute(
      sql`update public.credit_packs set dodo_product_id = 'pdt_pack_10' where code = 'credits_10'`,
    );
    owner = await h.user("cloud-owner@example.com");
    member = await h.user("cloud-member@example.com");
  }, 180_000);
  afterAll(async () => {
    await h?.stop();
    await f?.stop();
  });

  it("shows today's spend against the plan's daily cap, the limit that stops runs (D-311)", async () => {
    const orgId = await newOrg("Daily cap");
    expect((await billing(orgId)).daily).toMatchObject({ used_usd: 0, cap_usd: 0.25 });
    await h.handle.db.execute(sql`
      insert into public.usage_ledger (org_id, kind, quantity, cost_usd, billable, created_at) values
        (${orgId}::uuid, 'tokens_in', 1000, 0.2, true, now()),
        (${orgId}::uuid, 'app_calls', 2, 0.1, true, now()),
        (${orgId}::uuid, 'computer_seconds', 60, 0.5, true, now()),
        (${orgId}::uuid, 'tokens_in', 1000, 3, true, now() - interval '2 days')`);
    const d = (await billing(orgId)).daily;
    // Computers have their own monthly hours; yesterday's spend doesn't count.
    expect(d.used_usd).toBeCloseTo(0.3, 6);
    expect(d.cap_usd).toBe(0.25);
    expect(new Date(d.resets_at).getUTCHours()).toBe(0);
    expect(new Date(d.resets_at).getTime()).toBeGreaterThan(Date.now());
  });

  it("starts new workspaces on the free plan with included credits and its limits", async () => {
    const orgId = await newOrg("Free tier");
    const b = await billing(orgId);
    expect(b).toMatchObject({ enabled: true, plan_code: "free", unlimited: false, credits_usd: 1 });
    expect(b.limits.max_bots).toBe(3);
    for (const name of ["One", "Two", "Extra"])
      expect(
        (
          await h.request("/v1/bots", {
            method: "POST",
            token: owner.token,
            json: { org_id: orgId, name },
          })
        ).status,
      ).toBe(201);
    const fourth = await h.request("/v1/bots", {
      method: "POST",
      token: owner.token,
      json: { org_id: orgId, name: "Three" },
    });
    expect(fourth.status).toBe(402);
    expect((await j(fourth)).code).toBe("plan_limit");

    // Archive one, add another, then bring the archived one back: the limit still holds (the app
    // unarchives straight through PostgREST, so the database enforces it).
    const asOwner = <T>(fn: Parameters<typeof withUserSession<T>>[2]) =>
      withUserSession(h.handle.db, { sub: owner.id }, fn);
    const [one] = await h.handle.db.execute<{ id: string }>(
      sql`select id from public.bots where org_id = ${orgId}::uuid and name = 'One'`,
    );
    await asOwner((tx) =>
      tx.execute(sql`update public.bots set archived_at = now() where id = ${one?.id}::uuid`),
    );
    expect(
      (
        await h.request("/v1/bots", {
          method: "POST",
          token: owner.token,
          json: { org_id: orgId, name: "Three" },
        })
      ).status,
    ).toBe(201);
    const restore = asOwner((tx) =>
      tx.execute(sql`update public.bots set archived_at = null where id = ${one?.id}::uuid`),
    );
    await expect(restore).rejects.toMatchObject({ cause: { code: "PT402" } });
    await expect(
      asOwner((tx) =>
        tx.execute(
          sql`insert into public.bots (org_id, created_by, name) values (${orgId}::uuid, ${owner.id}::uuid, 'Direct')`,
        ),
      ),
    ).rejects.toMatchObject({ cause: { code: "PT402" } });
    // Archiving and renaming are never blocked.
    await asOwner((tx) =>
      tx.execute(
        sql`update public.bots set name = 'Two!' where org_id = ${orgId}::uuid and name = 'Two'`,
      ),
    );
    const plans = await j(await h.request("/v1/billing/plans", { token: owner.token }));
    expect(plans.plans.map((p: { code: string }) => p.code)).toEqual([
      "free",
      "plus",
      "plus_yearly",
      "pro",
      "pro_yearly",
      "max",
      "max_yearly",
    ]);
    expect(plans.plans.find((p: { code: string }) => p.code === "pro").price_label).toBe(
      "$49 / month",
    );
    expect(plans.plans.find((p: { code: string }) => p.code === "pro").web).toBe(true);
  });

  it("weekly plans (D-432) are listed only to apps that ask, without a trial or extra people", async () => {
    const codes = async (q = "") =>
      (await j(await h.request(`/v1/billing/plans${q}`, { token: owner.token }))).plans.map(
        (p: { code: string }) => p.code,
      ) as string[];
    // Shipped apps parse the interval strictly: they never see `week`.
    expect((await codes()).some((c) => c.endsWith("_weekly"))).toBe(false);
    const all = await j(await h.request("/v1/billing/plans?periods=week", { token: owner.token }));
    const weekly = all.plans.filter((p: { interval: string }) => p.interval === "week");
    expect(weekly.map((p: { code: string }) => p.code)).toEqual([
      "plus_weekly",
      "pro_weekly",
      "max_weekly",
    ]);
    const proWeek = weekly.find((p: { code: string }) => p.code === "pro_weekly");
    expect(proWeek.price_label).toBe("$19.99 / week");
    expect(proWeek.limits.trial_days).toBeUndefined();
    expect(proWeek.limits.extra_seat_usd).toBeUndefined();
    expect(proWeek.limits.seats).toBe(3);
    expect(proWeek.store_product_ids).toEqual({
      app_store: "ai.casama.pro.weekly",
      google_play: "casama_pro:weekly",
    });
  });

  it("weekly plans grant a quarter of the monthly credits once per paid week (D-432)", async () => {
    await h.handle.db.execute(
      sql`update public.plans set dodo_product_id = 'pdt_sub_pro_week' where code = 'pro_weekly'`,
    );
    const org = await newOrg("Weekly");
    const b = await buyOnWeb(org, { plan_code: "pro_weekly" });
    const sub = f.dodo.subs.get(b.subscriptionId as string) as { next_billing_date: string };
    sub.next_billing_date = new Date(Date.now() + 3 * 86_400_000).toISOString();
    await dodoHook("subscription.active", { subscription_id: b.subscriptionId });
    const grants = async () =>
      h.handle.db.execute<{ reference: string; delta: string }>(sql`
        select reference, delta::text from public.credit_ledger
        where org_id = ${org}::uuid and reason = 'grant' and delta > 0 and reference not like '%:free'
        order by created_at`);
    const [w1] = await h.handle.db.execute<{ d: string }>(sql`
      select to_char((now() at time zone 'utc') + interval '3 days' - interval '7 days', 'YYYY-MM-DD') as d`);
    expect((await grants()).map((g) => [g.reference, Number(g.delta)])).toEqual([
      [`monthly:${w1?.d}:pro_weekly`, 3.75],
    ]);
    await h.deps.billing?.settle();
    expect((await grants()).length).toBe(1);
    // The next paid week grants again, once.
    sub.next_billing_date = new Date(Date.now() + 10 * 86_400_000).toISOString();
    await dodoHook("subscription.renewed", { subscription_id: b.subscriptionId });
    await dodoHook("subscription.renewed", { subscription_id: b.subscriptionId });
    expect((await grants()).map((g) => Number(g.delta))).toEqual([3.75, 3.75]);
    const s = await billing(org);
    expect(s).toMatchObject({ plan_code: "pro_weekly", interval: "week" });
  });

  it("a Dodo purchase on the web unlocks the workspace everywhere (iOS and Android read the same entitlement)", async () => {
    const orgId = await newOrg("Web buyer");
    await h.request(`/v1/orgs/${orgId}/invites`, {
      method: "POST",
      token: owner.token,
      json: { email: "cloud-member@example.com" },
    });
    const join = () =>
      h.handle.db.execute(
        sql`insert into public.memberships (org_id, user_id, role) values (${orgId}::uuid, ${member.id}::uuid, 'member') on conflict do nothing`,
      );
    // Free has one seat (D-244): the owner. A second person needs a paid plan.
    await expect(join()).rejects.toMatchObject({ cause: { code: "PT402" } });
    const { subscriptionId } = await buyOnWeb(orgId, { plan_code: "pro" });
    expect(f.dodo.checkouts.size).toBeGreaterThan(0);
    const res = await dodoHook("subscription.active", {
      payload_type: "Subscription",
      subscription_id: subscriptionId,
    });
    expect(res.status).toBe(200);
    await join();
    // The phone apps call the same endpoint with their own session: the plan is the workspace's.
    const onPhone = await billing(orgId, member.token);
    // Upgrading in the month tops the month's grant up to Pro's $10, not $1 + $10 (D-246).
    expect(onPhone).toMatchObject({ plan_code: "pro", source: "dodo", credits_usd: 15 });
    expect(onPhone.limits.max_bots).toBeUndefined();
    // Customer portal for the web subscription.
    const portal = await j(
      await h.request(`/v1/orgs/${orgId}/billing/portal`, {
        method: "POST",
        token: owner.token,
        json: {},
      }),
    );
    expect(portal.url).toContain("/portal/cus_");
    // Members cannot buy or manage.
    const denied = await h.request(`/v1/orgs/${orgId}/billing/checkout`, {
      method: "POST",
      token: member.token,
      json: { plan_code: "pro" },
    });
    expect(denied.status).toBe(403);
  });

  it("verifies Standard Webhooks signatures, processes each event once and never trusts the payload", async () => {
    const orgId = await newOrg("Signatures");
    const { subscriptionId } = await buyOnWeb(orgId, { plan_code: "pro" });
    const data = { payload_type: "Subscription", subscription_id: subscriptionId };
    const forged = f.dodo.webhook("subscription.active", data, {
      secret: `whsec_${Buffer.from("wrong").toString("base64")}`,
    });
    expect((await hook("dodo", forged.body, forged.headers)).status).toBe(401);
    const stale = f.dodo.webhook("subscription.active", data, {
      ts: Math.floor(Date.now() / 1000) - 3600,
    });
    expect((await hook("dodo", stale.body, stale.headers)).status).toBe(401);
    // The provider says it is cancelled; a webhook claiming "active" must not grant the plan.
    (f.dodo.subs.get(subscriptionId as string) as { status: string }).status = "cancelled";
    const lie = f.dodo.webhook("subscription.active", data);
    expect((await hook("dodo", lie.body, lie.headers)).status).toBe(200);
    expect((await billing(orgId)).plan_code).toBe("free");
    // Replays are ignored.
    const again = await j(await hook("dodo", lie.body, lie.headers));
    expect(again.duplicate).toBe(true);
    const [n] = await h.handle.db.execute<{ n: number }>(
      sql`select count(*)::int as n from public.billing_events where event_id = ${lie.headers["webhook-id"]}`,
    );
    expect(n?.n).toBe(1);
  });

  it("cancel and refund webhooks remove access", async () => {
    const orgA = await newOrg("Cancels");
    const a = await buyOnWeb(orgA, { plan_code: "pro" });
    await dodoHook("subscription.active", { subscription_id: a.subscriptionId });
    expect((await billing(orgA)).plan_code).toBe("pro");
    (f.dodo.subs.get(a.subscriptionId as string) as { status: string }).status = "cancelled";
    await dodoHook("subscription.cancelled", { subscription_id: a.subscriptionId });
    expect((await billing(orgA)).plan_code).toBe("free");

    const orgB = await newOrg("Refunds");
    const b = await buyOnWeb(orgB, { plan_code: "pro" });
    await dodoHook("subscription.active", { subscription_id: b.subscriptionId });
    expect((await billing(orgB)).plan_code).toBe("pro");
    // Dodo may still report the subscription active after a refund; access goes anyway.
    const res = await dodoHook("refund.succeeded", {
      payload_type: "Refund",
      refund_id: "ref_1",
      payment_id: b.paymentId,
    });
    expect(res.status).toBe(200);
    const after = await billing(orgB);
    expect(after.plan_code).toBe("free");
    expect(after.subscriptions[0].status).toBe("refunded");
    // A later renewal event cannot bring a refunded subscription back.
    await dodoHook("subscription.renewed", { subscription_id: b.subscriptionId });
    expect((await billing(orgB)).plan_code).toBe("free");
  });

  it("billing audit 2026-11-17: a refund takes back its own period, not the subscription for good", async () => {
    const org = await newOrg("Partial refunds");
    const b = await buyOnWeb(org, { plan_code: "pro" });
    await dodoHook("subscription.active", { subscription_id: b.subscriptionId });
    expect((await billing(org)).plan_code).toBe("pro");
    const pay = f.dodo.payments.get(b.paymentId) as NonNullable<
      ReturnType<typeof f.dodo.payments.get>
    >;
    // A partial (goodwill) refund leaves the plan.
    pay.refunds = [{ refund_id: "rp_1", amount: 500, status: "succeeded", is_partial: true }];
    await dodoHook("refund.succeeded", {
      payload_type: "Refund",
      refund_id: "rp_1",
      payment_id: b.paymentId,
      is_partial: true,
    });
    expect((await billing(org)).plan_code).toBe("pro");
    // A full refund of an older renewal (paid two months ago) leaves it too.
    pay.created_at = new Date(Date.now() - 60 * 86_400_000).toISOString();
    pay.refunds = [{ refund_id: "rp_2", amount: pay.total_amount, status: "succeeded" }];
    await dodoHook("refund.succeeded", {
      payload_type: "Refund",
      refund_id: "rp_2",
      payment_id: b.paymentId,
    });
    expect((await billing(org)).plan_code).toBe("pro");
    // A full refund of this period's payment takes the period back, with its credits.
    pay.created_at = new Date().toISOString();
    await dodoHook("refund.succeeded", {
      payload_type: "Refund",
      refund_id: "rp_3",
      payment_id: b.paymentId,
    });
    let after = await billing(org);
    expect(after.plan_code).toBe("free");
    expect(after.subscriptions[0].status).toBe("refunded");
    expect(after.credits_usd).toBeLessThanOrEqual(1);
    // The customer pays for the next period: the plan is back.
    const sub = f.dodo.subs.get(b.subscriptionId as string) as { next_billing_date: string };
    sub.next_billing_date = new Date(Date.now() + 60 * 86_400_000).toISOString();
    await dodoHook("subscription.renewed", { subscription_id: b.subscriptionId });
    after = await billing(org);
    expect(after.plan_code).toBe("pro");
    expect(after.subscriptions[0].status).toBe("active");
  });

  it("billing audit 2026-11-17: monthly credits follow the paid period, once per period", async () => {
    const org = await newOrg("Periods");
    const b = await buyOnWeb(org, { plan_code: "pro" });
    // The period started 28 days ago and renews in two days.
    const sub = f.dodo.subs.get(b.subscriptionId as string) as { next_billing_date: string };
    sub.next_billing_date = new Date(Date.now() + 2 * 86_400_000).toISOString();
    await dodoHook("subscription.active", { subscription_id: b.subscriptionId });
    const grants = async () =>
      h.handle.db.execute<{ reference: string }>(sql`
        select reference from public.credit_ledger
        where org_id = ${org}::uuid and reason = 'grant' and delta > 0 and reference not like '%:free'`);
    const [label] = await h.handle.db.execute<{ m: string }>(sql`
      select to_char((now() at time zone 'utc') + interval '2 days' - interval '1 month', 'YYYY-MM') as m`);
    expect((await grants()).map((g) => g.reference)).toEqual([`monthly:${label?.m}:pro`]);
    // The minute sweep doesn't grant the calendar month on top, however often it runs.
    await h.deps.billing?.settle();
    await h.deps.billing?.settle();
    expect((await grants()).length).toBe(1);
    // Renewal: the next period's grant, once.
    sub.next_billing_date = new Date(Date.now() + 32 * 86_400_000).toISOString();
    await dodoHook("subscription.renewed", { subscription_id: b.subscriptionId });
    await dodoHook("subscription.renewed", { subscription_id: b.subscriptionId });
    const [next] = await h.handle.db.execute<{ m: string }>(sql`
      select to_char((now() at time zone 'utc') + interval '32 days' - interval '1 month', 'YYYY-MM') as m`);
    const refs = (await grants()).map((g) => g.reference);
    if (next?.m !== label?.m)
      expect(refs.sort()).toEqual([`monthly:${label?.m}:pro`, `monthly:${next?.m}:pro`].sort());
    else expect(refs.length).toBe(1);
  });

  it("credit packs add credits once and refunds take them back", async () => {
    const orgId = await newOrg("Credits");
    // Credit packs come with a paid plan (D-246): a free workspace is sent to upgrade.
    const refused = await h.request(`/v1/orgs/${orgId}/billing/checkout`, {
      method: "POST",
      token: owner.token,
      json: { pack_code: "credits_10" },
    });
    expect(refused.status).toBe(402);
    expect((await j(refused)).code).toBe("paid_plan_required");
    await h.handle.db.execute(
      sql`update public.entitlements set plan_code = 'pro' where org_id = ${orgId}::uuid`,
    );
    const p = await buyOnWeb(orgId, { pack_code: "credits_10" });
    await dodoHook("payment.succeeded", { payload_type: "Payment", payment_id: p.paymentId });
    await dodoHook("payment.succeeded", { payload_type: "Payment", payment_id: p.paymentId });
    expect((await billing(orgId)).credits_usd).toBe(11);
    await dodoHook("refund.succeeded", {
      payload_type: "Refund",
      refund_id: "r2",
      payment_id: p.paymentId,
    });
    expect((await billing(orgId)).credits_usd).toBe(1);
  });

  // App Store and Google Play purchases come through RevenueCat (D-297): the workspace id is the
  // RevenueCat customer, and the server re-reads the customer for every report and webhook.
  const purchase = (orgId: string, json: Record<string, unknown>) =>
    h.request(`/v1/orgs/${orgId}/billing/purchases`, { method: "POST", token: owner.token, json });
  const rcHook = (
    type: string,
    e: Record<string, unknown> & { app_user_id: string },
    opts?: { auth?: string; secret?: string },
  ) => {
    const w = f.revenuecat.event(type, e, opts);
    return hook("revenuecat", w.body, w.headers);
  };

  it("an App Store purchase unlocks the workspace on the web; refunds and expiry remove it", async () => {
    const orgId = await newOrg("iPhone buyer");
    const sub = f.revenuecat.subscribe({ customerId: orgId, productId: "ai.casama.pro.monthly" });
    const res = await purchase(orgId, {
      source: "app_store",
      product_id: "ai.casama.pro.monthly",
      transaction_id: sub.store_subscription_identifier,
    });
    expect(res.status).toBe(200);
    expect(await j(res)).toMatchObject({ plan_code: "pro", source: "app_store" });
    // The web app reads the same entitlement.
    expect((await billing(orgId)).plan_code).toBe("pro");

    // Turning off auto-renew keeps access until the period ends.
    sub.auto_renewal_status = "will_not_renew";
    expect(
      (await rcHook("CANCELLATION", { app_user_id: orgId, cancel_reason: "UNSUBSCRIBE" })).status,
    ).toBe(200);
    expect(await billing(orgId)).toMatchObject({ plan_code: "pro", cancel_at_period_end: true });

    // A webhook without RevenueCat's authorization header or signature is rejected.
    const refund = {
      app_user_id: orgId,
      cancel_reason: "CUSTOMER_SUPPORT",
      transaction_id: sub.store_subscription_identifier,
    };
    expect((await rcHook("CANCELLATION", refund, { auth: "wrong-wrong-wrong-wrong" })).status).toBe(
      401,
    );
    expect((await rcHook("CANCELLATION", refund, { secret: "not-the-secret" })).status).toBe(401);
    expect((await billing(orgId)).plan_code).toBe("pro");

    // A refund ends it for good, even though the store still reports the period.
    expect((await rcHook("CANCELLATION", refund)).status).toBe(200);
    expect((await billing(orgId)).plan_code).toBe("free");
    expect((await rcHook("RENEWAL", { app_user_id: orgId })).status).toBe(200);
    expect((await billing(orgId)).plan_code).toBe("free");

    // Expiry, on the Mac App Store build (the same App Store products).
    const org2 = await newOrg("Expires");
    const s2 = f.revenuecat.subscribe({
      customerId: org2,
      productId: "ai.casama.pro.yearly",
      store: "mac_app_store",
    });
    expect(
      (await purchase(org2, { source: "app_store", product_id: "ai.casama.pro.yearly" })).status,
    ).toBe(200);
    expect((await billing(org2)).plan_code).toBe("pro_yearly");
    s2.status = "expired";
    s2.gives_access = false;
    s2.current_period_ends_at = Date.now() - 1000;
    expect((await rcHook("EXPIRATION", { app_user_id: org2, store: "MAC_APP_STORE" })).status).toBe(
      200,
    );
    expect((await billing(org2)).plan_code).toBe("free");
  });

  it("webhooks are processed once, ignore other stores and anonymous customers", async () => {
    const orgId = await newOrg("Webhook once");
    f.revenuecat.subscribe({ customerId: orgId, productId: "ai.casama.plus.monthly" });
    const w = f.revenuecat.event("INITIAL_PURCHASE", { app_user_id: orgId });
    expect(await j(await hook("revenuecat", w.body, w.headers))).toMatchObject({
      duplicate: false,
    });
    expect(await j(await hook("revenuecat", w.body, w.headers))).toMatchObject({ duplicate: true });
    expect((await billing(orgId)).plan_code).toBe("plus");
    expect((await rcHook("TEST", { app_user_id: orgId })).status).toBe(200);
    expect((await rcHook("INITIAL_PURCHASE", { app_user_id: orgId, store: "STRIPE" })).status).toBe(
      200,
    );
    expect(
      (await rcHook("INITIAL_PURCHASE", { app_user_id: "$RCAnonymousID:abc", aliases: [] })).status,
    ).toBe(200);
    // A customer RevenueCat doesn't know (no purchases yet) changes nothing.
    const empty = await newOrg("Nothing bought");
    expect((await rcHook("TRANSFER", { app_user_id: empty })).status).toBe(200);
    expect((await billing(empty)).plan_code).toBe("free");
  });

  it("a store purchase cannot be claimed by another workspace (Restore Purchases is safe)", async () => {
    const mine = await newOrg("Mine");
    const theirs = await newOrg("Theirs");
    const sub = f.revenuecat.subscribe({ customerId: mine, productId: "ai.casama.pro.monthly" });
    // Nothing was bought under the other workspace.
    const claim = await purchase(theirs, {
      source: "app_store",
      product_id: "ai.casama.pro.monthly",
    });
    expect(claim.status).toBe(409);
    expect((await j(claim)).code).toBe("purchase_not_found");
    // Restoring in the right workspace works and is idempotent.
    for (let i = 0; i < 2; i++)
      expect(
        (await purchase(mine, { source: "app_store", product_id: "ai.casama.pro.monthly" })).status,
      ).toBe(200);
    expect((await billing(mine)).subscriptions).toHaveLength(1);
    // If RevenueCat moved the subscription to the other workspace (a restore with transfers on),
    // it stays with the workspace it was bought for.
    sub.customer_id = theirs;
    const moved = await purchase(theirs, {
      source: "app_store",
      product_id: "ai.casama.pro.monthly",
    });
    expect(moved.status).toBe(409);
    expect((await j(moved)).code).toBe("purchase_in_use");
    expect((await billing(theirs)).plan_code).toBe("free");
    expect((await billing(mine)).plan_code).toBe("pro");
  });

  it("a sandbox purchase (TestFlight, App Review) counts like any other", async () => {
    const orgId = await newOrg("TestFlight buyer");
    f.revenuecat.subscribe({
      customerId: orgId,
      productId: "ai.casama.pro.monthly",
      environment: "sandbox",
    });
    expect(
      (await purchase(orgId, { source: "app_store", product_id: "ai.casama.pro.monthly" })).status,
    ).toBe(200);
    expect((await billing(orgId)).plan_code).toBe("pro");
  });

  it("credit packs bought in the stores credit the workspace once (D-244)", async () => {
    const orgId = await newOrg("Pack buyer");
    f.revenuecat.buy({ customerId: orgId, productId: "ai.casama.credits.10" });
    const ios = { source: "app_store", product_id: "ai.casama.credits.10" };
    expect((await purchase(orgId, ios)).status).toBe(200);
    expect((await billing(orgId)).credits_usd).toBe(11);
    // Reporting the same purchase again changes nothing.
    expect((await purchase(orgId, ios)).status).toBe(200);
    expect((await billing(orgId)).credits_usd).toBe(11);

    // Several purchases: the server reads every page of the customer's purchases.
    for (let i = 0; i < 3; i++)
      f.revenuecat.buy({ customerId: orgId, productId: "casama_credits_25", store: "play_store" });
    const android = { source: "google_play", product_id: "casama_credits_25" };
    expect((await purchase(orgId, android)).status).toBe(200);
    expect((await billing(orgId)).credits_usd).toBe(86);
    // The webhook for one of them adds nothing more.
    expect(
      (await rcHook("NON_RENEWING_PURCHASE", { app_user_id: orgId, store: "PLAY_STORE" })).status,
    ).toBe(200);
    expect((await billing(orgId)).credits_usd).toBe(86);

    // A pack RevenueCat moved to another workspace isn't credited twice.
    const pack = [...f.revenuecat.purchases.values()].find((p) => p.customer_id === orgId) as {
      customer_id: string;
    };
    const other = await newOrg("Pack thief");
    pack.customer_id = other;
    const stolen = await purchase(other, ios);
    expect(stolen.status).toBe(409);
    expect((await billing(other)).credits_usd).toBe(1);
  });

  it("Google Play subscriptions unlock the workspace; cancelling keeps access to the period end", async () => {
    const orgId = await newOrg("Android buyer");
    const sub = f.revenuecat.subscribe({
      customerId: orgId,
      productId: "casama_pro:monthly",
      store: "play_store",
    });
    const res = await purchase(orgId, { source: "google_play", product_id: "casama_pro:monthly" });
    expect(res.status).toBe(200);
    expect((await j(res)).plan_code).toBe("pro");
    // The wrong store for the product isn't a match.
    expect(
      (await purchase(orgId, { source: "app_store", product_id: "casama_pro:monthly" })).status,
    ).toBe(409);

    sub.auto_renewal_status = "will_not_renew";
    expect(
      (
        await rcHook("CANCELLATION", {
          app_user_id: orgId,
          store: "PLAY_STORE",
          cancel_reason: "UNSUBSCRIBE",
        })
      ).status,
    ).toBe(200);
    expect(await billing(orgId)).toMatchObject({ plan_code: "pro", cancel_at_period_end: true });

    // Billing retry without access pauses the plan; recovering brings it back.
    sub.status = "in_billing_retry";
    sub.gives_access = false;
    await rcHook("BILLING_ISSUE", { app_user_id: orgId, store: "PLAY_STORE" });
    expect((await billing(orgId)).plan_code).toBe("free");
    sub.status = "active";
    sub.gives_access = true;
    await rcHook("RENEWAL", { app_user_id: orgId, store: "PLAY_STORE" });
    expect((await billing(orgId)).plan_code).toBe("pro");
  });

  it("billable usage becomes credit deductions; out of credits stops runs; metered plans report to Dodo", async () => {
    const orgId = await newOrg("Usage");
    await h.handle.db.execute(sql`
      insert into public.usage_ledger (org_id, kind, quantity, cost_usd) values
        (${orgId}::uuid, 'computer_seconds', 3600, 0.4),
        (${orgId}::uuid, 'tokens_in', 1000, 5)`);
    await h.deps.billing?.settle();
    // Only the platform cost (computers) is charged; the BYO-key tokens are not.
    expect((await billing(orgId)).credits_usd).toBeCloseTo(0.6, 6);
    const usage = await j(
      await h.request(`/v1/orgs/${orgId}/billing/usage`, { token: owner.token }),
    );
    expect(usage.items).toEqual([
      { kind: "computer_seconds", instance: null, quantity: 3600, cost_usd: 0.4 },
    ]);
    expect(usage.credits.map((c: { reason: string }) => c.reason)).toEqual(["usage", "grant"]);

    // Spend the rest. On Casama Cloud every bot runs on Casama's key (D-188), so a bot made
    // with the workspace's own key is switched to it, and no credits stops every run.
    await h.handle.db.execute(
      sql`insert into public.usage_ledger (org_id, kind, quantity, cost_usd) values (${orgId}::uuid, 'computer_seconds', 9000, 1)`,
    );
    await h.deps.billing?.settle();
    const cred = await j(
      await h.request("/v1/credentials", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, provider: "openrouter", label: "k", api_key: "sk-usage-key" },
      }),
    );
    const bot = await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: owner.token,
        json: {
          org_id: orgId,
          name: "Spender",
          model_policy: { primary: { credential_id: cred.id, model: "fixture-main" } },
        },
      }),
    );
    expect(bot.model_policy.primary.credential_id).toBe(PLATFORM_OPENROUTER_CREDENTIAL_ID);
    const listed = await j(
      await h.request(`/v1/credentials?org_id=${orgId}`, { token: owner.token }),
    );
    expect(listed.items.at(-1)).toMatchObject({
      id: PLATFORM_OPENROUTER_CREDENTIAL_ID,
      label: "Casama Cloud",
    });
    expect(
      (
        await h.request(`/v1/credentials/${PLATFORM_OPENROUTER_CREDENTIAL_ID}`, {
          method: "DELETE",
          token: owner.token,
        })
      ).status,
    ).toBe(403);
    const cloudBot = await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: owner.token,
        json: {
          org_id: orgId,
          name: "Cloud",
          model_policy: {
            primary: { credential_id: PLATFORM_OPENROUTER_CREDENTIAL_ID, model: "meta/muse-ember" },
          },
        },
      }),
    );
    const cloudConv = await j(
      await h.request("/v1/conversations", {
        method: "POST",
        token: owner.token,
        json: { bot_id: cloudBot.id },
      }),
    );
    const cloudSent = await j(
      await h.request(`/v1/conversations/${cloudConv.id}/messages`, {
        method: "POST",
        token: owner.token,
        json: { text: "hi" },
      }),
    );
    let cloudRun: { status: string; error?: { code?: string } } = { status: "queued" };
    for (let i = 0; i < 100 && !["failed", "completed"].includes(cloudRun.status); i++) {
      await new Promise((r) => setTimeout(r, 200));
      cloudRun = await j(await h.request(`/v1/runs/${cloudSent.run_id}`, { token: owner.token }));
    }
    expect(cloudRun.status).toBe("failed");
    expect(cloudRun.error?.code).toBe("out_of_credits");

    // Metered plan: usage rows are sent to Dodo as usage events.
    await h.handle.db.execute(
      sql`update public.plans set limits = limits || '{"metered": true}'::jsonb where code = 'pro'`,
    );
    const { subscriptionId } = await buyOnWeb(orgId, { plan_code: "pro" });
    await dodoHook("subscription.active", { subscription_id: subscriptionId });
    await h.handle.db.execute(
      sql`insert into public.usage_ledger (org_id, kind, quantity, cost_usd) values (${orgId}::uuid, 'stream_seconds', 60, 0.01)`,
    );
    await h.deps.billing?.settle();
    expect(f.dodo.usageEvents.some((e) => e.event_name === "stream_seconds")).toBe(true);
    await h.handle.db.execute(
      sql`update public.plans set limits = limits - 'metered' where code = 'pro'`,
    );
  }, 60_000);

  it("grants included credits once a month and keeps owner overrides across plan changes", async () => {
    const orgId = await newOrg("Monthly");
    await h.deps.billing?.recompute(orgId);
    await h.deps.billing?.recompute(orgId);
    expect((await billing(orgId)).credits_usd).toBe(1);
    await h.handle.db.execute(
      sql`update public.entitlements set overrides = '{"max_bots": 7}'::jsonb where org_id = ${orgId}::uuid`,
    );
    await h.deps.billing?.recompute(orgId);
    const b = await billing(orgId);
    expect(b.limits.max_bots).toBe(7);
    expect(b.limits.computer_hours).toBe(5);
  });

  it("shows the plan's monthly credits, not an override's: overrides never grant credits", async () => {
    const orgId = await newOrg("Overridden");
    await h.handle.db.execute(
      sql`update public.entitlements set overrides = '{"monthly_credits_usd": 15, "cloud_daily_usd": 10}'::jsonb where org_id = ${orgId}::uuid`,
    );
    await h.deps.billing?.recompute(orgId);
    const b = await billing(orgId);
    expect(b.plan_code).toBe("free");
    expect(b.limits.cloud_daily_usd).toBe(10);
    expect(b.limits.monthly_credits_usd).toBe(1);
    expect(b.credits_usd).toBe(1);
  });

  it("a web subscriber changing plans is moved in place, never subscribed twice (D-248)", async () => {
    await h.handle.db.execute(
      sql`update public.plans set dodo_product_id = 'pdt_sub_max' where code = 'max'`,
    );
    const orgId = await newOrg("Upgrader");
    const { subscriptionId } = await buyOnWeb(orgId, { plan_code: "pro" });
    await dodoHook("subscription.active", {
      payload_type: "Subscription",
      subscription_id: subscriptionId,
    });
    expect((await billing(orgId)).plan_code).toBe("pro");
    const checkout = (plan: string) =>
      h.request(`/v1/orgs/${orgId}/billing/checkout`, {
        method: "POST",
        token: owner.token,
        json: { plan_code: plan },
      });
    const before = f.dodo.checkouts.size;
    const res = await checkout("max");
    expect(res.status).toBe(200);
    expect((await j(res)).changed).toBe(true);
    expect(f.dodo.checkouts.size).toBe(before);
    expect(f.dodo.planChanges).toContainEqual(
      expect.objectContaining({ subscriptionId, productId: "pdt_sub_max" }),
    );
    expect((await billing(orgId)).plan_code).toBe("max");
    // The plan it already has can't be bought again.
    expect((await checkout("max")).status).toBe(409);
  });

  it("refunds take back what they brought: a store pack's credits, a subscription's monthly credits (D-248)", async () => {
    const orgId = await newOrg("Refunder");
    const pack = f.revenuecat.buy({
      customerId: orgId,
      productId: "casama_credits_10",
      store: "play_store",
    });
    expect(
      (await purchase(orgId, { source: "google_play", product_id: "casama_credits_10" })).status,
    ).toBe(200);
    expect((await billing(orgId)).credits_usd).toBe(11);
    pack.status = "refunded";
    expect(
      (
        await rcHook("CANCELLATION", {
          app_user_id: orgId,
          store: "PLAY_STORE",
          cancel_reason: "CUSTOMER_SUPPORT",
        })
      ).status,
    ).toBe(200);
    expect((await billing(orgId)).credits_usd).toBe(1);

    // A refunded Pro subscription: what it added for the month comes back out.
    const sub = f.revenuecat.subscribe({ customerId: orgId, productId: "ai.casama.pro.monthly" });
    expect(
      (await purchase(orgId, { source: "app_store", product_id: "ai.casama.pro.monthly" })).status,
    ).toBe(200);
    // Pro tops the month up to its $15 (D-249) over Free's $1.
    expect((await billing(orgId)).credits_usd).toBe(15);
    await rcHook("CANCELLATION", {
      app_user_id: orgId,
      cancel_reason: "CUSTOMER_SUPPORT",
      transaction_id: sub.store_subscription_identifier,
    });
    const after = await billing(orgId);
    expect(after.plan_code).toBe("free");
    // Pro topped the month up by $14 over Free's $1; the refund takes those $14 back.
    expect(after.credits_usd).toBe(1);
  });
});
