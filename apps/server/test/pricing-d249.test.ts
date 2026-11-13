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

    // The trial ends and the first payment goes through: the month tops up to Pro's $15.
    const sub = f.dodo.subs.get(subscriptionId);
    if (sub) sub.trial_period_days = 0;
    await dodoHook("subscription.renewed", subscriptionId);
    b = await billing(id, who.token);
    expect(b.subscriptions[0].status).toBe("active");
    expect(b.credits_usd).toBe(15);
    expect(b.limits.computer_hours).toBe(100);

    // One trial per person: their next workspace pays from the start.
    const second = await newOrg("Second", who);
    expect((await billing(second.id, who.token)).trial_available).toBe(false);
    expect((await buyPro(second.id, who.token)).trialDays).toBeUndefined();
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
