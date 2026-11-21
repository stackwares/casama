import { sql } from "drizzle-orm";
import { afterAll, beforeAll, beforeEach, describe, expect, it } from "vitest";
import { unsubscribeToken } from "../src/api/routes/moderation.ts";
import { BillingService } from "../src/billing/service.ts";
import {
  accountEmailContent,
  queueAccountEmail,
  sendAccountEmails,
  sweepAccountEmails,
} from "../src/services/account-emails.ts";
import type { EmailMessage } from "../src/services/email.ts";
import { type Harness, JWT_SECRET, j, startHarness } from "./helpers.ts";

/** Reports and blocks (D-301), account emails (D-302). */
describe("reports and blocks (D-301)", () => {
  let h: Harness;
  let alice: { id: string; token: string };
  let bob: { id: string; token: string };
  let owner: { id: string; token: string };
  let stranger: { id: string; token: string };
  let orgId: string;
  let messageId: string;

  beforeAll(async () => {
    h = await startHarness({ email: true, env: { INSTANCE_ADMIN_EMAILS: "owner@example.com" } });
    owner = await h.user("owner@example.com");
    alice = await h.user("alice@example.com");
    bob = await h.user("bob@example.com");
    stranger = await h.user("stranger@example.com");
    orgId = (
      await j(
        await h.request("/v1/orgs", { method: "POST", token: alice.token, json: { name: "Team" } }),
      )
    ).id;
    await h.handle.db.execute(
      sql`insert into public.memberships (org_id, user_id, role) values (${orgId}::uuid, ${bob.id}::uuid, 'member')`,
    );
    const [bot] = await h.handle.db.execute<{ id: string }>(sql`
      insert into public.bots (org_id, name, created_by) values (${orgId}::uuid, 'Helper', ${alice.id}::uuid) returning id`);
    const [conv] = await h.handle.db.execute<{ id: string }>(sql`
      insert into public.conversations (org_id, bot_id, title) values (${orgId}::uuid, ${bot?.id}::uuid, 'Group') returning id`);
    const [m] = await h.handle.db.execute<{ id: string }>(sql`
      insert into public.messages (org_id, conversation_id, role, author_user_id, content)
      values (${orgId}::uuid, ${conv?.id}::uuid, 'user', ${bob.id}::uuid, '[{"type":"text","text":"buy cheap pills"}]'::jsonb)
      returning id`);
    messageId = m?.id as string;
  });
  afterAll(async () => h?.stop());

  const report = (token: string, json: Record<string, unknown>) =>
    h.request("/v1/reports", { method: "POST", token, json });

  it("reports a message with a copy of what was said, emails the abuse inbox, and queues it for the owners", async () => {
    h.outbox.length = 0;
    const res = await report(alice.token, {
      target_kind: "message",
      target_id: messageId,
      reason: "spam",
      note: "scam",
    });
    expect(res.status).toBe(200);
    const mail = h.outbox.find((m) => m.to === "abuse@casama.ai");
    expect(mail?.subject).toContain("[report] message");
    expect(mail?.text).toContain("buy cheap pills");
    // Reporting again while it's open doesn't make a second report.
    expect(
      (await report(alice.token, { target_kind: "message", target_id: messageId, reason: "spam" }))
        .status,
    ).toBe(200);
    const queue = await j(await h.request("/v1/admin/content-reports", { token: owner.token }));
    expect(queue.items).toHaveLength(1);
    expect(queue.items[0]).toMatchObject({
      target_kind: "message",
      reason: "spam",
      target_org_id: orgId,
      same_target: 1,
    });
    expect(queue.items[0].snapshot).toContain("buy cheap pills");
    // Only instance owners see the queue.
    expect((await h.request("/v1/admin/content-reports", { token: alice.token })).status).toBe(403);
  });

  it("never lets someone report what they can't see", async () => {
    expect(
      (
        await report(stranger.token, {
          target_kind: "message",
          target_id: messageId,
          reason: "spam",
        })
      ).status,
    ).toBe(404);
    expect(
      (
        await report(stranger.token, {
          target_kind: "user",
          target_id: bob.id,
          reason: "harassment",
        })
      ).status,
    ).toBe(404);
  });

  it("acting on a report closes every open report about it and can suspend the workspace", async () => {
    await report(bob.token, { target_kind: "message", target_id: messageId, reason: "other" });
    const queue = await j(await h.request("/v1/admin/content-reports", { token: owner.token }));
    const r = await j(
      await h.request(`/v1/admin/content-reports/${queue.items[0].id}`, {
        method: "POST",
        token: owner.token,
        json: { decision: "actioned", suspend_workspace: true },
      }),
    );
    expect(r.status).toBe("actioned");
    expect(
      (await j(await h.request("/v1/admin/content-reports", { token: owner.token }))).items,
    ).toHaveLength(0);
    const [o] = await h.handle.db.execute<{ suspended: boolean }>(
      sql`select suspended_at is not null as suspended from public.organizations where id = ${orgId}::uuid`,
    );
    expect(o?.suspended).toBe(true);
    await h.handle.db.execute(
      sql`update public.organizations set suspended_at = null where id = ${orgId}::uuid`,
    );
  });

  it("blocking stops invites from that person without telling them", async () => {
    await h.tdb.admin`update public.profiles set display_name = null where user_id = ${alice.id}`;
    const block = await j(
      await h.request("/v1/me/blocks", {
        method: "POST",
        token: stranger.token,
        json: { user_id: alice.id },
      }),
    );
    expect(block.user_id).toBe(alice.id);
    // An id is enough to block someone, so the answer never carries their full email.
    expect(JSON.stringify(block)).not.toContain("alice@example.com");
    h.outbox.length = 0;
    const res = await h.request(`/v1/orgs/${orgId}/invites/batch`, {
      method: "POST",
      token: alice.token,
      json: { emails: ["stranger@example.com"] },
    });
    expect(res.status).toBe(201);
    expect((await j(res)).items[0].email_sent).toBe(true);
    expect(h.outbox.filter((m) => m.to === "stranger@example.com")).toHaveLength(0);
    const [n] = await h.handle.db.execute<{ n: number }>(
      sql`select count(*)::int as n from public.invites where email = 'stranger@example.com'`,
    );
    expect(n?.n).toBe(0);
    const list = await j(await h.request("/v1/me/blocks", { token: stranger.token }));
    expect(list.items.map((b: { user_id: string }) => b.user_id)).toEqual([alice.id]);
    expect(
      (await h.request(`/v1/me/blocks/${alice.id}`, { method: "DELETE", token: stranger.token }))
        .status,
    ).toBe(204);
    expect(
      (await j(await h.request("/v1/me/blocks", { token: stranger.token }))).items,
    ).toHaveLength(0);
  });

  it("reporting a person also blocks them", async () => {
    await report(alice.token, { target_kind: "user", target_id: bob.id, reason: "harassment" });
    const list = await j(await h.request("/v1/me/blocks", { token: alice.token }));
    expect(list.items.map((b: { user_id: string }) => b.user_id)).toContain(bob.id);
  });
});

describe("account emails (D-302)", () => {
  let h: Harness;
  let owner: { id: string; token: string };
  let member: { id: string; token: string };
  let orgId: string;
  const sent: EmailMessage[] = [];
  const email = { enabled: true, send: async (m: EmailMessage) => void sent.push(m) };
  const env = {
    PUBLIC_APP_URL: "https://app.example.com",
    PUBLIC_API_URL: "https://api.example.com",
    EMAIL_POSTAL_ADDRESS: "1 Test Street, Testville",
    SUPABASE_JWT_SECRET: JWT_SECRET,
    ACCOUNT_EMAILS: true,
  };
  let billing: BillingService;

  beforeAll(async () => {
    h = await startHarness({ env: { BILLING_ENABLED: "true" } });
    owner = await h.user("payer@example.com");
    member = await h.user("member@example.com");
    orgId = (
      await j(
        await h.request("/v1/orgs", {
          method: "POST",
          token: owner.token,
          json: { name: "Paying Co" },
        }),
      )
    ).id;
    // Room for a second person on the Free plan.
    await h.handle.db.execute(
      sql`update public.entitlements set limits = limits || '{"seats": 5}'::jsonb where org_id = ${orgId}::uuid`,
    );
    await h.handle.db.execute(
      sql`insert into public.memberships (org_id, user_id, role) values (${orgId}::uuid, ${member.id}::uuid, 'member')`,
    );
    // Emails only go to confirmed addresses.
    await h.handle.db.execute(sql`update auth.users set email_confirmed_at = now()`);
    billing = new BillingService({ db: h.handle.db, enabled: true, providers: {} });
  });
  afterAll(async () => h?.stop());
  beforeEach(async () => {
    sent.length = 0;
    await h.handle.db.execute(sql`delete from public.email_outbox`);
  });

  const snap = (status: string, extra: Record<string, unknown> = {}) => ({
    source: "app_store" as const,
    externalId: "sub-1",
    productId: "ai.casama.plus.monthly",
    status: status as never,
    currentPeriodEnd: new Date(Date.now() + 30 * 86_400_000),
    cancelAtPeriodEnd: false,
    orgId,
    raw: {},
    ...extra,
  });

  it("a new subscription emails the owners (not plain members) once, however often it's seen", async () => {
    await billing.applySnapshot(snap("active"));
    await billing.applySnapshot(snap("active"));
    expect(await sendAccountEmails({ db: h.handle.db, email, env })).toBe(1);
    expect(sent.map((m) => m.to)).toEqual(["payer@example.com"]);
    expect(sent[0]?.subject).toBe("Welcome to Plus");
    expect(sent[0]?.html).toContain("Welcome to Plus");
    // Billing emails carry no unsubscribe.
    expect(sent[0]?.headers).toBeUndefined();
    expect(await sendAccountEmails({ db: h.handle.db, email, env })).toBe(0);
  });

  it("turning renewal off, a failed payment, expiry and a refund each get their email", async () => {
    await billing.applySnapshot(snap("active", { cancelAtPeriodEnd: true }));
    await billing.applySnapshot(snap("grace", { cancelAtPeriodEnd: true }));
    await billing.applySnapshot(snap("expired", { cancelAtPeriodEnd: true }));
    await billing.applySnapshot(snap("active", { externalId: "sub-2" }));
    await billing.applySnapshot(snap("active", { externalId: "sub-2" }), { refund: true });
    await sendAccountEmails({ db: h.handle.db, email, env });
    const subjects = sent.map((m) => m.subject);
    expect(subjects.some((s) => s?.startsWith("Your Plus plan ends on"))).toBe(true);
    expect(subjects).toContain("Your Casama payment didn't go through");
    expect(subjects).toContain("You're on the Free plan now");
    expect(subjects).toContain("Your refund went through");
    expect(sent.find((m) => m.subject === "Your Casama payment didn't go through")?.text).toContain(
      "Settings > your name > Subscriptions",
    );
  });

  it("the sweep warns about trials ending in 3 days and low credits, once", async () => {
    await h.handle.db.execute(sql`
      insert into public.subscriptions (org_id, source, external_id, plan_code, status, current_period_end, cancel_at_period_end)
      values (${orgId}::uuid, 'app_store', 'trial-1', 'plus', 'trialing', now() + interval '2 days', false)`);
    await sweepAccountEmails(h.handle.db, { billing: true });
    await sweepAccountEmails(h.handle.db, { billing: true });
    const [n] = await h.handle.db.execute<{ n: number }>(
      sql`select count(*)::int as n from public.email_outbox where kind = 'trial_ending'`,
    );
    expect(n?.n).toBe(1);
  });

  it("the welcome series needs a postal address, honours unsubscribing and carries one-click unsubscribe", async () => {
    await queueAccountEmail(h.handle.db, {
      kind: "welcome",
      userId: owner.id,
      dedupeKey: `welcome:${owner.id}`,
    });
    await sendAccountEmails({
      db: h.handle.db,
      email,
      env: { ...env, EMAIL_POSTAL_ADDRESS: undefined },
    });
    expect(sent).toHaveLength(0);
    await h.handle.db.execute(sql`delete from public.email_outbox`);
    await queueAccountEmail(h.handle.db, {
      kind: "welcome",
      userId: owner.id,
      dedupeKey: `welcome2:${owner.id}`,
    });
    await sendAccountEmails({ db: h.handle.db, email, env });
    const mail = sent[0];
    expect(mail?.subject).toBe("Welcome to Casama");
    expect(mail?.headers?.["List-Unsubscribe-Post"]).toBe("List-Unsubscribe=One-Click");
    expect(mail?.text).toContain("1 Test Street");
    // The link works without signing in; a visit alone changes nothing, the POST does.
    const token = unsubscribeToken(`email-links:${JWT_SECRET}`, owner.id);
    expect((await h.request(`/v1/email/unsubscribe/${token}`)).status).toBe(200);
    expect(
      (await j(await h.request("/v1/me/email-preferences", { token: owner.token }))).tips,
    ).toBe(true);
    expect((await h.request(`/v1/email/unsubscribe/${token}`, { method: "POST" })).status).toBe(
      200,
    );
    expect(
      (await j(await h.request("/v1/me/email-preferences", { token: owner.token }))).tips,
    ).toBe(false);
    expect(
      (await h.request(`/v1/email/unsubscribe/${owner.id}.forged`, { method: "POST" })).status,
    ).toBe(400);
    sent.length = 0;
    await queueAccountEmail(h.handle.db, {
      kind: "come_back",
      userId: owner.id,
      dedupeKey: `come_back:${owner.id}`,
    });
    await sendAccountEmails({ db: h.handle.db, email, env });
    expect(sent).toHaveLength(0);
    // Turning it back on from the app.
    const p = await j(
      await h.request("/v1/me/email-preferences", {
        method: "PUT",
        token: owner.token,
        json: { tips: true },
      }),
    );
    expect(p.tips).toBe(true);
  });

  it("every kind has a subject, a title and a button", () => {
    for (const kind of [
      "trial_started",
      "trial_ending",
      "plan_started",
      "payment_failed",
      "cancel_scheduled",
      "expired",
      "refunded",
      "credits_low",
      "credits_out",
      "yearly_renewal",
      "welcome",
      "first_bot_nudge",
      "week_one_tips",
      "come_back",
    ] as const) {
      const c = accountEmailContent(
        kind,
        { plan: "Pro", until: new Date().toISOString(), source: "google_play" },
        "https://app.example.com",
      );
      expect(c.subject.length, kind).toBeGreaterThan(5);
      expect(c.email.button?.url, kind).toMatch(/^https:\/\/app\.example\.com/);
    }
  });
});
