import { fileURLToPath } from "node:url";
import { sql } from "drizzle-orm";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { billingEnv, type FakeBilling, startFakeBilling } from "./fake-billing.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

const CHAT = fileURLToPath(new URL("./fixtures/chat.json", import.meta.url));

/** D-249: the Pro trial, extra people on Pro and Max, and the revised plan limits. */
describe("pricing D-249", () => {
  let f: FakeBilling;
  let h: Harness;
  let admin: { id: string; token: string };
  let made = 0;

  /** A workspace made by a new person, who is returned with it. */
  const newOrg = async (name: string, maker?: { id: string; token: string }) => {
    const who = maker ?? (await h.user(`d249-maker-${++made}@example.com`));
    const id = (
      await j(await h.request("/v1/orgs", { method: "POST", token: who.token, json: { name } }))
    ).id as string;
    return { id, who };
  };
  const billing = async (orgId: string, token: string) =>
    j(await h.request(`/v1/orgs/${orgId}/billing`, { token }));
  const dodoHook = async (type: string, subscriptionId: string) => {
    const w = f.dodo.webhook(type, {
      payload_type: "Subscription",
      subscription_id: subscriptionId,
    });
    const r = await h.request("/hooks/billing/dodo", {
      method: "POST",
      headers: { "content-type": "application/json", ...w.headers },
      body: w.body,
    });
    expect(r.status).toBe(200);
  };
  const buyPro = async (orgId: string, token: string) => {
    const res = await h.request(`/v1/orgs/${orgId}/billing/checkout`, {
      method: "POST",
      token,
      json: { plan_code: "pro" },
    });
    expect(res.status).toBe(200);
    const session = ((await j(res)).url as string).split("/pay/")[1] as string;
    const trialDays = f.dodo.checkouts.get(session)?.trial_period_days;
    const { subscriptionId } = f.dodo.complete(session);
    await dodoHook("subscription.active", subscriptionId as string);
    return { subscriptionId: subscriptionId as string, trialDays };
  };

  beforeAll(async () => {
    f = await startFakeBilling();
    h = await startHarness({ env: billingEnv(f), worker: { fixtures: CHAT } });
    admin = await h.user("d249-admin@example.com");
    await h.handle.db.execute(
      sql`update public.plans set dodo_product_id = 'pdt_sub_pro' where code = 'pro'`,
    );
    await h.handle.db.execute(
      sql`update public.billing_settings set dodo_seat_addon_month = 'adn_seat_m', dodo_seat_addon_year = 'adn_seat_y'`,
    );
  }, 180_000);
  afterAll(async () => {
    await h?.stop();
    await f?.stop();
  });

  it("prices fit every store and limits match the plan table", async () => {
    const r = await j(await h.request("/v1/billing/plans", { token: admin.token }));
    // The paywall's picks (D-332): Plus opens it, Pro is badged.
    expect(
      r.plans
        .filter((p: { paywall_default: boolean }) => p.paywall_default)
        .map((p: { code: string }) => p.code),
    ).toEqual(["plus"]);
    expect(
      r.plans
        .filter((p: { paywall_popular: boolean }) => p.paywall_popular)
        .map((p: { code: string }) => p.code),
    ).toEqual(["pro", "pro_yearly"]);
    expect(
      Object.fromEntries(
        r.plans.map((p: { code: string; price_label: string | null }) => [p.code, p.price_label]),
      ),
    ).toEqual({
      free: null,
      plus: "$15 / month",
      plus_yearly: "$150 / year",
      pro: "$49 / month",
      pro_yearly: "$490 / year",
      max: "$99 / month",
      max_yearly: "$899 / year",
    });
    const { id, who } = await newOrg("Free");
    const b = await billing(id, who.token);
    expect(b.limits).toMatchObject({
      max_bots: 3,
      seats: 1,
      max_running_computers: 1,
      computer_size: 1,
    });
    expect(b.trial_available).toBe(true);
    expect(b.extra_seats).toBe(0);
  });

  it("a first Pro purchase on the web starts a 7-day trial with a smaller allowance, then pays", async () => {
    const { id, who } = await newOrg("Trial");
    const { subscriptionId, trialDays } = await buyPro(id, who.token);
    expect(trialDays).toBe(7);
    let b = await billing(id, who.token);
    expect(b).toMatchObject({ plan_code: "pro", credits_usd: 2, trial_available: false });
    expect(b.subscriptions[0].status).toBe("trialing");
    expect(b.limits).toMatchObject({ computer_hours: 10, seats: 3, computer_size: 2 });
    expect(b.limits.max_bots).toBeUndefined();
    // No switching plans during the trial (billing audit 2026-11-17).
    await h.handle.db.execute(
      sql`update public.plans set dodo_product_id = 'pdt_sub_max' where code = 'max'`,
    );
    const toMax = () =>
      h.request(`/v1/orgs/${id}/billing/checkout`, {
        method: "POST",
        token: who.token,
        json: { plan_code: "max" },
      });
    const during = await toMax();
    expect(during.status).toBe(409);
    expect((await j(during)).code).toBe("trialing");

    // The trial ends and the first payment goes through: the month tops up to Pro's $15.
    const sub = f.dodo.subs.get(subscriptionId);
    if (sub) sub.trial_period_days = 0;
    await dodoHook("subscription.renewed", subscriptionId);
    b = await billing(id, who.token);
    expect(b.subscriptions[0].status).toBe("active");
    expect(b.credits_usd).toBe(15);
    expect(b.limits.computer_hours).toBe(100);

    // Moving up to Max three days before renewal is charged pro rata, so the extra credits are
    // too: a tenth of Max's $30 less Pro's $15, not all of it (billing audit 2026-11-17).
    // A period that started 27 days ago: its end, and the grant labelled for it.
    if (sub) sub.next_billing_date = new Date(Date.now() + 3 * 86400_000).toISOString();
    await h.handle.db.execute(sql`
      update public.subscriptions set current_period_end = now() + interval '3 days' where org_id = ${id}::uuid`);
    await h.handle.db.execute(sql`
      update public.credit_ledger c
         set reference = 'monthly:' || public.grant_month(s.id) || ':pro'
        from public.subscriptions s
       where s.org_id = ${id}::uuid and c.org_id = s.org_id and c.reason = 'grant'
         and c.reference like 'monthly:%:pro'`);
    expect((await toMax()).status).toBe(200);
    b = await billing(id, who.token);
    expect(b.plan_code).toBe("max");
    expect(b.credits_usd).toBeGreaterThan(15);
    expect(b.credits_usd).toBeLessThan(15 + 2);
    await h.handle.db.execute(
      sql`update public.plans set dodo_product_id = null where code = 'max'`,
    );

    // One trial per person: their next workspace pays from the start.
    const second = await newOrg("Second", who);
    expect((await billing(second.id, who.token)).trial_available).toBe(false);
    expect((await buyPro(second.id, who.token)).trialDays).toBeUndefined();
  });

  it("one inbox gets one set of free credits and one trial (billing audit 2026-11-17)", async () => {
    // A "+tag" and dotted Gmail account on the same inbox: no second $1, no second trial.
    const first = await newOrg("Inbox", await h.user("d249.inbox@gmail.com"));
    expect(await billing(first.id, first.who.token)).toMatchObject({ credits_usd: 1 });
    const alias = await newOrg("Alias", await h.user("d249inbox+again@googlemail.com"));
    let b = await billing(alias.id, alias.who.token);
    expect(b).toMatchObject({ plan_code: "free", credits_usd: 0, trial_available: true });
    await buyPro(first.id, first.who.token);
    expect((await billing(alias.id, alias.who.token)).trial_available).toBe(false);

    // Two checkouts at once in two workspaces both offered the trial: only the first one gets it,
    // the other gives nothing until it's paid.
    const racer = await h.user("d249-racer@example.com");
    const one = await newOrg("Race one", racer);
    const two = await newOrg("Race two", racer);
    const open = async (orgId: string) => {
      const res = await h.request(`/v1/orgs/${orgId}/billing/checkout`, {
        method: "POST",
        token: racer.token,
        json: { plan_code: "pro" },
      });
      const session = ((await j(res)).url as string).split("/pay/")[1] as string;
      expect(f.dodo.checkouts.get(session)?.trial_period_days).toBe(7);
      return session;
    };
    const s1 = await open(one.id);
    const s2 = await open(two.id);
    const sub1 = f.dodo.complete(s1).subscriptionId as string;
    await dodoHook("subscription.active", sub1);
    const sub2 = f.dodo.complete(s2).subscriptionId as string;
    await dodoHook("subscription.active", sub2);
    expect(await billing(one.id, racer.token)).toMatchObject({ plan_code: "pro", credits_usd: 2 });
    b = await billing(two.id, racer.token);
    expect(b).toMatchObject({ plan_code: "free", credits_usd: 0 });
    expect(b.subscriptions[0].status).toBe("trialing");
    // Paying turns it on.
    const paid = f.dodo.subs.get(sub2);
    if (paid) paid.trial_period_days = 0;
    await dodoHook("subscription.renewed", sub2);
    expect(await billing(two.id, racer.token)).toMatchObject({ plan_code: "pro", credits_usd: 15 });
  });

  it("Pro and Max sell extra people on a web subscription", async () => {
    const { id, who } = await newOrg("Team");
    // They subscribed before in another workspace, so this one pays from the start.
    const other = await newOrg("Old", who);
    await h.handle.db.execute(sql`
      insert into public.subscriptions (org_id, source, external_id, plan_code, status)
      values (${other.id}::uuid, 'dodo', ${`sub_old_${other.id}`}, 'plus', 'expired')`);
    const { subscriptionId } = await buyPro(id, who.token);

    const free = await newOrg("No plan");
    const onFree = await h.request(`/v1/orgs/${free.id}/billing/seats`, {
      method: "PUT",
      token: free.who.token,
      json: { extra: 1 },
    });
    expect(onFree.status).toBe(402);

    const res = await h.request(`/v1/orgs/${id}/billing/seats`, {
      method: "PUT",
      token: who.token,
      json: { extra: 2 },
    });
    expect(res.status).toBe(200);
    const b = await j(res);
    expect(b).toMatchObject({ extra_seats: 2, limits: { seats: 5 } });
    expect(f.dodo.planChanges.at(-1)).toMatchObject({
      subscriptionId,
      body: { product_id: "pdt_sub_pro", addons: [{ addon_id: "adn_seat_m", quantity: 2 }] },
    });

    // Saving the plan in the Admin screen keeps the extra people.
    const saved = await h.request("/v1/admin/plans/pro", {
      method: "PUT",
      token: admin.token,
      json: { price_label: "$49 / month" },
    });
    expect(saved.status).toBe(200);
    expect((await billing(id, who.token)).limits.seats).toBe(5);

    // Four people can't drop to no extra seats.
    for (let i = 0; i < 3; i++) {
      const u = await h.user(`d249-team-${i}@example.com`);
      await h.handle.db.execute(
        sql`insert into public.memberships (org_id, user_id, role) values (${id}::uuid, ${u.id}::uuid, 'member')`,
      );
    }
    const tooFew = await h.request(`/v1/orgs/${id}/billing/seats`, {
      method: "PUT",
      token: who.token,
      json: { extra: 0 },
    });
    expect(tooFew.status).toBe(409);
    expect((await j(tooFew)).code).toBe("seats_in_use");
  });

  it("a store trial after the person's trial was used keeps Pro but gets no trial credits", async () => {
    const { id: web, who } = await newOrg("Web trial");
    await buyPro(web, who.token);
    expect(await billing(web, who.token)).toMatchObject({ plan_code: "pro", credits_usd: 2 });

    // The same person starts the App Store's free week in another workspace.
    const { id: phone } = await newOrg("Store trial", who);
    const sub = f.revenuecat.subscribe({
      customerId: phone,
      productId: "ai.casama.pro.monthly",
      status: "trialing",
    });
    const res = await h.request(`/v1/orgs/${phone}/billing/purchases`, {
      method: "POST",
      token: who.token,
      json: {
        source: "app_store",
        product_id: "ai.casama.pro.monthly",
        transaction_id: sub.store_subscription_identifier,
      },
    });
    expect(res.status).toBe(200);
    let b = await billing(phone, who.token);
    expect(b).toMatchObject({ plan_code: "pro" });
    // Only the Free month it had before (if any): no trial grant.
    const grants = await h.handle.db.execute<{ reference: string }>(
      sql`select reference from public.credit_ledger where org_id = ${phone}::uuid and reason = 'grant'`,
    );
    expect(grants.map((g) => g.reference).filter((r) => r.endsWith(":trial"))).toEqual([]);
    expect(Number(b.credits_usd)).toBeLessThanOrEqual(1);
    expect(b.subscriptions[0].status).toBe("trialing");

    // Paying tops the month up to Pro's $15 as usual.
    sub.status = "active";
    const w = f.revenuecat.event("RENEWAL", { app_user_id: phone });
    expect((await h.request("/hooks/billing/revenuecat", { method: "POST", ...w })).status).toBe(
      200,
    );
    b = await billing(phone, who.token);
    expect(b).toMatchObject({ plan_code: "pro", credits_usd: 15 });
  });

  it("a store trial that is the person's first gets the trial allowance", async () => {
    const { id, who } = await newOrg("First store trial");
    const sub = f.revenuecat.subscribe({
      customerId: id,
      productId: "ai.casama.pro.monthly",
      status: "trialing",
    });
    const res = await h.request(`/v1/orgs/${id}/billing/purchases`, {
      method: "POST",
      token: who.token,
      json: {
        source: "app_store",
        product_id: "ai.casama.pro.monthly",
        transaction_id: sub.store_subscription_identifier,
      },
    });
    expect(res.status).toBe(200);
    expect(await billing(id, who.token)).toMatchObject({ plan_code: "pro", credits_usd: 2 });
  });

  it("store subscriptions can't carry extra people", async () => {
    const { id, who } = await newOrg("Phone");
    await h.handle.db.execute(sql`
      insert into public.subscriptions (org_id, source, external_id, plan_code, status, current_period_end)
      values (${id}::uuid, 'app_store', ${`otx_${id}`}, 'max', 'active', now() + interval '20 days')`);
    const r = await h.request(`/v1/orgs/${id}/billing/seats`, {
      method: "PUT",
      token: who.token,
      json: { extra: 1 },
    });
    expect(r.status).toBe(409);
    expect((await j(r)).code).toBe("subscribed_in_store");
  });
});
