import { LimitResetCampaignInput } from "@casama/contracts";
import { createDb, type DbHandle } from "@casama/db";
import { createAuthUser, startTestDatabase, type TestDatabase } from "@casama/db/testing";
import { afterAll, beforeAll, expect, it } from "vitest";
import { LimitResets } from "../src/billing/limit-resets.ts";

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
