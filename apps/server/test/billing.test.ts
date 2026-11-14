import { fileURLToPath } from "node:url";
import { PLATFORM_OPENROUTER_CREDENTIAL_ID } from "@casama/agent";
import { withUserSession } from "@casama/db";
import { sql } from "drizzle-orm";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { billingEnv, type FakeBilling, makeTestPki, startFakeBilling } from "./fake-billing.ts";
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
    expect((await h.request("/connect/v1/whoami")).status).toBe(404);
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

  it("an App Store purchase unlocks the workspace on the web; refunds and expiry remove it", async () => {
    const orgId = await newOrg("iPhone buyer");
    const sub = f.apple.add({ productId: "ai.casama.pro.monthly", appAccountToken: orgId });
    const res = await h.request(`/v1/orgs/${orgId}/billing/purchases`, {
      method: "POST",
      token: owner.token,
      json: {
        source: "app_store",
        product_id: "ai.casama.pro.monthly",
        transaction_id: sub.transactionId,
      },
    });
    expect(res.status).toBe(200);
    expect(await j(res)).toMatchObject({ plan_code: "pro", source: "app_store" });
    // The web app reads the same entitlement.
    expect((await billing(orgId)).plan_code).toBe("pro");

    // Turning off auto-renew keeps access until the period ends.
    sub.autoRenewStatus = 0;
    const off = await f.apple.notification(
      "DID_CHANGE_RENEWAL_STATUS",
      sub.originalTransactionId,
      "AUTO_RENEW_DISABLED",
    );
    expect((await hook("app_store", off)).status).toBe(200);
    expect(await billing(orgId)).toMatchObject({ plan_code: "pro", cancel_at_period_end: true });

    // A notification signed outside Apple's chain is rejected.
    const fake = await f.apple.notification(
      "REFUND",
      sub.originalTransactionId,
      undefined,
      makeTestPki("Evil"),
    );
    expect((await hook("app_store", fake)).status).toBe(401);
    expect((await billing(orgId)).plan_code).toBe("pro");

    sub.revocationDate = Date.now();
    sub.status = 5;
    expect(
      (await hook("app_store", await f.apple.notification("REFUND", sub.originalTransactionId)))
        .status,
    ).toBe(200);
    expect((await billing(orgId)).plan_code).toBe("free");

    // Expiry.
    const org2 = await newOrg("Expires");
    const s2 = f.apple.add({ productId: "ai.casama.pro.yearly", appAccountToken: org2 });
    await h.request(`/v1/orgs/${org2}/billing/purchases`, {
      method: "POST",
      token: owner.token,
      json: {
        source: "app_store",
        product_id: "ai.casama.pro.yearly",
        transaction_id: s2.transactionId,
      },
    });
    expect((await billing(org2)).plan_code).toBe("pro_yearly");
    s2.status = 2;
    s2.expiresDate = Date.now() - 1000;
    await hook(
      "app_store",
      await f.apple.notification("EXPIRED", s2.originalTransactionId, "VOLUNTARY"),
    );
    expect((await billing(org2)).plan_code).toBe("free");
  });

  it("a store purchase cannot be claimed by another workspace (Restore Purchases is safe)", async () => {
    const mine = await newOrg("Mine");
    const theirs = await newOrg("Theirs");
    const sub = f.apple.add({ productId: "ai.casama.pro.monthly", appAccountToken: mine });
    const claim = await h.request(`/v1/orgs/${theirs}/billing/purchases`, {
      method: "POST",
      token: owner.token,
      json: {
        source: "app_store",
        product_id: "ai.casama.pro.monthly",
        transaction_id: sub.transactionId,
      },
    });
    expect(claim.status).toBe(409);
    // Restoring in the right workspace works and is idempotent.
    for (let i = 0; i < 2; i++) {
      const r = await h.request(`/v1/orgs/${mine}/billing/purchases`, {
        method: "POST",
        token: owner.token,
        json: {
          source: "app_store",
          product_id: "ai.casama.pro.monthly",
          transaction_id: sub.transactionId,
        },
      });
      expect(r.status).toBe(200);
    }
    expect((await billing(mine)).subscriptions).toHaveLength(1);
  });

  it("a sandbox App Store purchase is found in Apple's sandbox, before and after release", async () => {
    // TestFlight, development builds and App Review buy in the sandbox. Production answers 404
    // for those, and 401 for everything until the app's first release is live.
    for (const locked of [true, false]) {
      f.apple.productionLocked = locked;
      const orgId = await newOrg(`TestFlight buyer ${locked}`);
      const sub = f.apple.add({
        productId: "ai.casama.pro.monthly",
        appAccountToken: orgId,
        sandbox: true,
      });
      const res = await h.request(`/v1/orgs/${orgId}/billing/purchases`, {
        method: "POST",
        token: owner.token,
        json: {
          source: "app_store",
          product_id: "ai.casama.pro.monthly",
          transaction_id: sub.transactionId,
        },
      });
      expect(res.status).toBe(200);
      expect((await billing(orgId)).plan_code).toBe("pro");
      // Apple's notifications for it are checked against the sandbox too.
      sub.autoRenewStatus = 0;
      expect(
        (
          await hook(
            "app_store",
            await f.apple.notification("DID_CHANGE_RENEWAL_STATUS", sub.originalTransactionId),
          )
        ).status,
      ).toBe(200);
    }
    f.apple.productionLocked = false;
  });

  it("credit packs bought in the stores credit the workspace once (D-244)", async () => {
    const orgId = await newOrg("Pack buyer");
    const buy = (json: Record<string, unknown>, org = orgId) =>
      h.request(`/v1/orgs/${org}/billing/purchases`, { method: "POST", token: owner.token, json });
    const tx = f.apple.add({ productId: "ai.casama.credits.10" });
    const ios = {
      source: "app_store",
      product_id: "ai.casama.credits.10",
      transaction_id: tx.transactionId,
    };
    expect((await buy(ios)).status).toBe(200);
    expect((await billing(orgId)).credits_usd).toBe(11);
    // Reporting the same purchase again changes nothing; another workspace can't reuse it.
    expect((await buy(ios)).status).toBe(200);
    expect((await billing(orgId)).credits_usd).toBe(11);
    const other = await newOrg("Pack thief");
    expect((await buy(ios, other)).status).toBe(409);

    f.google.products.set("pack-token-1", {
      productId: "casama_credits_25",
      orderId: "GPA.1234-5678",
      purchaseState: 0,
      consumptionState: 0,
    });
    const android = {
      source: "google_play",
      product_id: "casama_credits_25",
      purchase_token: "pack-token-1",
    };
    expect((await buy(android)).status).toBe(200);
    expect(f.google.consumed).toContain("pack-token-1");
    expect((await billing(orgId)).credits_usd).toBe(36);
    expect((await buy(android)).status).toBe(200);
    expect((await billing(orgId)).credits_usd).toBe(36);
    // A pending purchase isn't credited yet.
    f.google.products.set("pack-token-2", {
      productId: "casama_credits_10",
      orderId: "GPA.9",
      purchaseState: 2,
      consumptionState: 0,
    });
    expect(
      (
        await buy({
          source: "google_play",
          product_id: "casama_credits_10",
          purchase_token: "pack-token-2",
        })
      ).status,
    ).toBe(409);
  });

  it("Google Play purchases are verified and acknowledged; RTDN refunds remove access", async () => {
    const orgId = await newOrg("Android buyer");
    f.google.add("play-token-1", { productId: "casama_pro", basePlanId: "monthly", orgId });
    const res = await h.request(`/v1/orgs/${orgId}/billing/purchases`, {
      method: "POST",
      token: owner.token,
      json: {
        source: "google_play",
        product_id: "casama_pro:monthly",
        purchase_token: "play-token-1",
      },
    });
    expect(res.status).toBe(200);
    expect((await j(res)).plan_code).toBe("pro");
    expect(f.google.acknowledged).toContain("play-token-1");

    // Pushes without the secret token are rejected.
    const voided = f.google.rtdn({
      voidedPurchaseNotification: {
        purchaseToken: "play-token-1",
        orderId: "GPA.1",
        productType: 1,
      },
    });
    expect((await hook("google_play", voided, {}, "?token=wrong-token-0000000")).status).toBe(401);
    expect((await hook("google_play", voided)).status).toBe(401);

    // Cancelled but not expired: still entitled until the period ends.
    (f.google.subs.get("play-token-1") as { subscriptionState: string }).subscriptionState =
      "SUBSCRIPTION_STATE_CANCELED";
    const cancel = f.google.rtdn({
      subscriptionNotification: {
        version: "1.0",
        notificationType: 3,
        purchaseToken: "play-token-1",
        subscriptionId: "casama_pro",
      },
    });
    expect((await hook("google_play", cancel, {}, `?token=${f.google.rtdnToken}`)).status).toBe(
      200,
    );
    expect(await billing(orgId)).toMatchObject({ plan_code: "pro", cancel_at_period_end: true });

    expect((await hook("google_play", voided, {}, `?token=${f.google.rtdnToken}`)).status).toBe(
      200,
    );
    expect((await billing(orgId)).plan_code).toBe("free");
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
    f.google.products.set("pack-token-r", {
      productId: "casama_credits_10",
      orderId: "GPA.R-1",
      purchaseState: 0,
      consumptionState: 0,
    });
    const bought = await h.request(`/v1/orgs/${orgId}/billing/purchases`, {
      method: "POST",
      token: owner.token,
      json: {
        source: "google_play",
        product_id: "casama_credits_10",
        purchase_token: "pack-token-r",
      },
    });
    expect(bought.status).toBe(200);
    expect((await billing(orgId)).credits_usd).toBe(11);
    const voided = f.google.rtdn({
      voidedPurchaseNotification: {
        purchaseToken: "pack-token-r",
        orderId: "GPA.R-1",
        productType: 2,
      },
    });
    expect((await hook("google_play", voided, {}, `?token=${f.google.rtdnToken}`)).status).toBe(
      200,
    );
    expect((await billing(orgId)).credits_usd).toBe(1);

    // A refunded Pro subscription: what it added for the month comes back out.
    const sub = f.apple.add({ productId: "ai.casama.pro.monthly", appAccountToken: orgId });
    await h.request(`/v1/orgs/${orgId}/billing/purchases`, {
      method: "POST",
      token: owner.token,
      json: {
        source: "app_store",
        product_id: "ai.casama.pro.monthly",
        transaction_id: sub.transactionId,
      },
    });
    // Pro tops the month up to its $15 (D-249) over Free's $1.
    expect((await billing(orgId)).credits_usd).toBe(15);
    await hook("app_store", await f.apple.notification("REFUND", sub.originalTransactionId));
    const after = await billing(orgId);
    expect(after.plan_code).toBe("free");
    // Pro topped the month up by $14 over Free's $1; the refund takes those $14 back.
    expect(after.credits_usd).toBe(1);
  });
});
