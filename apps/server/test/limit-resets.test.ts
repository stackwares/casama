import { dailyResetAt } from "@casama/agent";
import { LimitResetCampaignInput } from "@casama/contracts";
import { createDb, type DbHandle } from "@casama/db";
import { createAuthUser, startTestDatabase, type TestDatabase } from "@casama/db/testing";
import { sql } from "drizzle-orm";
import { afterAll, beforeAll, expect, it } from "vitest";
import { LimitResets } from "../src/billing/limit-resets.ts";
import { callHeadroom } from "../src/billing/live-calls.ts";

let t: TestDatabase;
let h: DbHandle;
let service: LimitResets;
let owner: string;
let org: string;
beforeAll(async () => {
  t = await startTestDatabase();
  h = createDb(t.url);
  service = new LimitResets(h.db, true);
  owner = (await createAuthUser(t.admin, "reset-owner@example.com")).id;
  const [o] =
    await t.admin`insert into public.organizations(name,slug,created_by,plan) values ('Resets','resets',${owner},'free') returning id`;
  org = o!.id;
  await t.admin`insert into public.memberships(org_id,user_id,role) values (${org},${owner},'owner')`;
  await t.admin`insert into public.entitlements(org_id,plan_code,limits) select ${org},code,limits from public.plans where code='free'`;
}, 120000);
/** The period's included credits arrived and were spent, so a reset has something to refill. */
async function grantSpent(id: string, amount = 1, spend = amount) {
  await t.admin`select public.credit_apply(${id},${amount},'grant','monthly:' || public.grant_month(null) || ':free',null)`;
  await t.admin`select public.credit_apply(${id},${-spend},'usage',${`spend-${id}-${spend}`},null)`;
}
/** A free workspace with one owner and its plan, as settlement leaves it. */
async function freeWorkspace(slug: string) {
  const user = await createAuthUser(t.admin, `${slug}@example.com`);
  const [o] =
    await t.admin`insert into public.organizations(name,slug,created_by,plan) values (${slug},${slug},${user.id},'free') returning id`;
  await t.admin`insert into public.memberships(org_id,user_id,role) values (${o!.id},${user.id},'owner')`;
  await t.admin`insert into public.entitlements(org_id,plan_code,limits) select ${o!.id},code,limits from public.plans where code='free'`;
  return { id: o!.id as string, owner: user.id };
}
/** A live campaign for [ids], handed out. */
async function handOut(ids: string[], extra: Record<string, unknown> = {}) {
  const c = await service.create(
    owner,
    LimitResetCampaignInput.parse({
      name: "Test",
      message: "Saved",
      audience: { workspace_ids: ids },
      starts_at: new Date(Date.now() - 1000).toISOString(),
      expires_at: new Date(Date.now() + 86400000).toISOString(),
      ...extra,
    }),
  );
  await service.action(owner, c.id, "schedule");
  await service.tick();
  return c;
}
afterAll(async () => {
  await h?.close();
  await t?.stop();
});
it("launches once, refills included credits once under concurrent redemption, and preserves purchased credit", async () => {
  await service.setSettings(owner, {
    enabled: true,
    per_period: 1,
    max_held: 3,
    notify_owners: true,
  });
  const input = LimitResetCampaignInput.parse({
    name: "Outage",
    message: "A reset for you",
    audience: { workspace_ids: [org] },
    starts_at: new Date(Date.now() - 1000).toISOString(),
    expires_at: new Date(Date.now() + 86400000).toISOString(),
  });
  const campaign = await service.create(owner, input);
  await service.action(owner, campaign.id, "schedule");
  await service.tick();
  await service.tick();
  const [count] =
    await t.admin`select count(*)::int as n from public.limit_resets where org_id=${org}`;
  expect(count!.n).toBe(1);
  await grantSpent(org);
  await t.admin`select public.credit_apply(${org},10,'purchase','test-purchase',null)`;
  const results = await Promise.allSettled([
    service.redeem(org, owner),
    service.redeem(org, owner),
  ]);
  expect(results.filter((r) => r.status === "fulfilled")).toHaveLength(1);
  const [credits] =
    await t.admin`select remaining::text from public.credit_lots where reference='test-purchase'`;
  expect(Number(credits!.remaining)).toBe(10);
  const [reset] =
    await t.admin`select remaining,expires_at from public.credit_lots where reason='reset'`;
  expect(Number(reset!.remaining)).toBe(1);
  expect(reset!.expires_at).not.toBeNull();
});
it("keeps audit events immutable and client writes forbidden", async () => {
  await expect(t.admin`update public.limit_reset_events set action='tampered'`).rejects.toThrow(
    "append only",
  );
  await expect(
    t.admin.begin(async (tx) => {
      await tx`set local role authenticated`;
      await tx`insert into public.limit_resets(org_id,campaign_id) select org_id,campaign_id from public.limit_resets limit 1`;
    }),
  ).rejects.toThrow("permission denied");
});
it("undo removes only unspent reset credit and refuses repeated undo", async () => {
  const [reset] =
    await t.admin`select id from public.limit_resets where org_id=${org} and used_at is not null`;
  await t.admin`select public.credit_apply(${org},-0.25,'usage','spend-reset',null)`;
  await service.resetAction(owner, reset!.id, "undo");
  const [credit] =
    await t.admin`select remaining from public.credit_lots where reference='test-purchase'`;
  expect(Number(credit!.remaining)).toBe(10);
  const [balance] =
    await t.admin`select balance_after from public.credit_ledger where org_id=${org} order by seq desc limit 1`;
  expect(Number(balance!.balance_after)).toBe(10);
  await expect(service.resetAction(owner, reset!.id, "undo")).rejects.toThrow("once");
});
it("refuses disabled redemption and non-owner redemption", async () => {
  await service.setSettings(owner, {
    enabled: false,
    per_period: 1,
    max_held: 3,
    notify_owners: true,
  });
  await expect(service.redeem(org, owner)).rejects.toThrow("disabled");
  await t.admin`update public.entitlements set limits=jsonb_set(limits,'{seats}','2') where org_id=${org}`;
  const other = await createAuthUser(t.admin, "reset-member@example.com");
  await t.admin`insert into public.memberships(org_id,user_id,role) values (${org},${other.id},'admin')`;
  await expect(service.redeem(org, other.id)).rejects.toThrow("Only workspace owners");
});
it("allows only mutable fields after launch and honors pause, expiry and budget", async () => {
  await service.setSettings(owner, {
    enabled: true,
    per_period: 10,
    max_held: 3,
    notify_owners: true,
  });
  const input = LimitResetCampaignInput.parse({
    name: "States",
    message: "Saved",
    audience: { workspace_ids: [org] },
    starts_at: new Date(Date.now() - 1000).toISOString(),
    expires_at: new Date(Date.now() + 86400000).toISOString(),
    max_per_use_usd: 0.5,
    budget_usd: 0,
  });
  const campaign = await service.create(owner, input);
  await service.action(owner, campaign.id, "schedule");
  await service.tick();
  await service.update(owner, campaign.id, { ...input, message: "Updated" });
  await expect(
    service.update(owner, campaign.id, { ...input, refill_percent: 50 }),
  ).rejects.toThrow("fixed");
  await expect(service.redeem(org, owner)).rejects.toThrow("not available");
  await service.action(owner, campaign.id, "pause");
  await expect(service.redeem(org, owner)).rejects.toThrow("No reset");
  await service.action(owner, campaign.id, "resume");
  await service.update(owner, campaign.id, { ...input, budget_usd: 1 });
  expect((await service.redeem(org, owner)).refilled_usd).toBe(0.5);
  await expect(service.action(owner, campaign.id, "delete")).rejects.toThrow("state");
});
it("meter resets use offsets and leave the usage ledger intact", async () => {
  await t.admin`insert into public.usage_ledger(org_id,kind,quantity,cost_usd,billable) values (${org},'tokens_in',100,0.3,true),(${org},'computer_seconds',3600,0.1,true)`;
  const input = LimitResetCampaignInput.parse({
    name: "Meters",
    message: "Refill",
    audience: { workspace_ids: [org] },
    starts_at: new Date(Date.now() - 1000).toISOString(),
    expires_at: new Date(Date.now() + 86400000).toISOString(),
    reset_computer: true,
  });
  const c = await service.create(owner, input);
  await service.action(owner, c.id, "schedule");
  await service.tick();
  await service.redeem(org, owner);
  const [offset] =
    await t.admin`select public.limit_reset_offset(${org},'daily') as daily, public.limit_reset_offset(${org},'computer') as computer`;
  expect(Number(offset!.daily)).toBe(0.3);
  expect(Number(offset!.computer)).toBe(3600);
  const [usage] =
    await t.admin`select sum(cost_usd) as total from public.usage_ledger where org_id=${org}`;
  expect(Number(usage!.total)).toBe(0.4);
});
it("queues arrival and expiry reminder once per owner using the notification queue", async () => {
  const { NotificationService, RecordingPushSender } = await import("@casama/agent");
  const notes = new NotificationService(h.db, new RecordingPushSender());
  const c = await service.create(
    owner,
    LimitResetCampaignInput.parse({
      name: "Notices",
      message: "Plain reset notice",
      audience: { workspace_ids: [org] },
      starts_at: new Date(Date.now() - 1000).toISOString(),
      expires_at: new Date(Date.now() + 86400000).toISOString(),
    }),
  );
  await service.action(owner, c.id, "schedule");
  await service.tick();
  await service.notices(notes, "reset-owner@example.com");
  await service.notices(notes, "reset-owner@example.com");
  const [n] =
    await t.admin`select count(*)::int as n from public.notifications where user_id=${owner} and kind='reset_given' and payload->>'body'='Plain reset notice'`;
  expect(n!.n).toBe(1);
  const [r] =
    await t.admin`select arrival_sent_at,reminder_sent_at from public.limit_resets where campaign_id=${c.id}`;
  expect(r!.arrival_sent_at).not.toBeNull();
  expect(r!.reminder_sent_at).not.toBeNull();
});
it("exports complete audit rows as CSV", async () => {
  let csv = "";
  for await (const chunk of service.csv(undefined, org)) {
    csv += chunk;
  }
  expect(csv.startsWith("id,created_at,action,")).toBe(true);
  expect(csv).toContain('"used"');
  expect(csv).toContain(org);
});
it("enforces a shared campaign budget across concurrent workspaces", async () => {
  const workspaces: Array<{ id: string; owner: string }> = [];
  for (let i = 0; i < 2; i++) {
    const user = await createAuthUser(t.admin, `reset-budget-${i}@example.com`);
    const [o] =
      await t.admin`insert into public.organizations(name,slug,created_by,plan) values ('Budget',${`reset-budget-${i}`},${user.id},'free') returning id`;
    await t.admin`insert into public.memberships(org_id,user_id,role) values (${o!.id},${user.id},'owner')`;
    await t.admin`insert into public.entitlements(org_id,plan_code,limits) select ${o!.id},code,limits from public.plans where code='free'`;
    await grantSpent(o!.id);
    workspaces.push({ id: o!.id, owner: user.id });
  }
  const c = await service.create(
    owner,
    LimitResetCampaignInput.parse({
      name: "Budget lock",
      message: "Saved",
      audience: { workspace_ids: workspaces.map((w) => w.id) },
      starts_at: new Date(Date.now() - 1000).toISOString(),
      expires_at: new Date(Date.now() + 86400000).toISOString(),
      refill_percent: 50,
      budget_usd: 0.5,
    }),
  );
  await service.action(owner, c.id, "schedule");
  await service.tick();
  const uses = await Promise.allSettled(workspaces.map((w) => service.redeem(w.id, w.owner)));
  expect(uses.filter((u) => u.status === "fulfilled")).toHaveLength(1);
  const [spent] =
    await t.admin`select refilled_usd from public.limit_reset_campaigns where id=${c.id}`;
  expect(Number(spent!.refilled_usd)).toBe(0.5);
});
it("refills no more than the period granted: a second free workspace gets nothing", async () => {
  const w = await freeWorkspace("reset-second-free");
  // Settlement records a $0 grant for a person's second free workspace (D-246).
  await t.admin`select public.credit_apply(${w.id},0,'grant','monthly:' || public.grant_month(null) || ':free',null)`;
  await handOut([w.id]);
  const [saved] = await service.saved(w.id, true);
  expect(saved!.refill_usd).toBe(0);
  expect(saved!.unavailable_reason).toBe("nothing_to_refill");
  await expect(service.redeem(w.id, w.owner)).rejects.toThrow("nothing to refill");
});
it("a trial refills to its own smaller grant, not the plan's amount", async () => {
  const w = await freeWorkspace("reset-partial-grant");
  await grantSpent(w.id, 0.4);
  await handOut([w.id]);
  expect((await service.redeem(w.id, w.owner)).refilled_usd).toBe(0.4);
});
it("the billing summary's resets never fail: none held, or no billing period", async () => {
  const empty = await freeWorkspace("reset-none-held");
  expect(await service.saved(empty.id, true)).toEqual([]);
  const w = await freeWorkspace("reset-no-period");
  await handOut([w.id]);
  await t.admin`delete from public.entitlements where org_id=${w.id}`;
  const [saved] = await service.saved(w.id, true);
  expect(saved!.can_use).toBe(false);
  expect(saved!.unavailable_reason).toBe("no_billing_period");
});
it("on a negative balance, counts only what became spendable", async () => {
  const w = await freeWorkspace("reset-negative");
  await grantSpent(w.id, 1, 1.3);
  const c = await handOut([w.id]);
  const used = await service.redeem(w.id, w.owner);
  expect(used.refilled_usd).toBeCloseTo(0.7, 6);
  const [row] =
    await t.admin`select r.refilled_usd as reset, c.refilled_usd as campaign from public.limit_resets r join public.limit_reset_campaigns c on c.id=r.campaign_id where c.id=${c.id}`;
  expect(Number(row!.reset)).toBeCloseTo(0.7, 6);
  expect(Number(row!.campaign)).toBeCloseTo(0.7, 6);
});
it("hands nothing out while switched off, and launches once switched back on", async () => {
  const w = await freeWorkspace("reset-switched-off");
  const settings = { per_period: 10, max_held: 3, notify_owners: true };
  await service.setSettings(owner, { enabled: false, ...settings });
  const c = await handOut([w.id]);
  const given = async () =>
    (
      await t.admin`select count(*)::int as n from public.limit_resets where campaign_id=${c.id}`
    )[0]!.n;
  expect(await given()).toBe(0);
  expect((await service.campaigns()).find((x) => x.id === c.id)!.state).toBe("scheduled");
  await service.setSettings(owner, { enabled: true, ...settings });
  await service.tick();
  expect(await given()).toBe(1);
});
it("voice calls, Link and check-ins see today's limit cleared by a reset", async () => {
  const w = await freeWorkspace("reset-daily-everywhere");
  await grantSpent(w.id);
  // Free's daily limit is $0.25; $0.30 spent today is over it.
  await t.admin`insert into public.usage_ledger(org_id,kind,quantity,cost_usd,billable,billed_at) values (${w.id},'tokens_in',100,0.3,true,now())`;
  const call = {
    id: crypto.randomUUID(),
    orgId: w.id,
    botId: crypto.randomUUID(),
    startedAt: new Date().toISOString(),
  };
  const before = await callHeadroom(h.db, call, 100, null);
  expect(before.reason).toBe("daily_cap");
  expect(before.left).toBeLessThan(0);
  const at = sql`select ${dailyResetAt(sql`${w.id}::uuid`)} as at`;
  expect((await h.db.execute<{ at: Date | null }>(at))[0]!.at).toBeNull();
  await handOut([w.id]);
  await service.redeem(w.id, w.owner);
  const after = await callHeadroom(h.db, call, 100, null);
  expect(after.left).toBeGreaterThan(0.2);
  // Link and check-ins count only their own spend, from the moment the limit was cleared.
  expect((await h.db.execute<{ at: Date | null }>(at))[0]!.at).not.toBeNull();
});
