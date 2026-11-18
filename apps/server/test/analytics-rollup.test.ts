import { createDb } from "@casama/db";
import { createAuthUser, startTestDatabase } from "@casama/db/testing";
import type { CaptureOptions, ProductAnalytics } from "@casama/observability";
import { expect, it } from "vitest";
import { rollupUuid, runDailyAnalyticsRollup } from "../src/worker/analytics-rollup.ts";

class Recorder implements ProductAnalytics {
  readonly enabled = true;
  events: CaptureOptions[] = [];
  capture(o: CaptureOptions) {
    this.events.push(o);
  }
  async flush() {}
  async close() {}
}

it("rolls up yesterday: interactive runs per person, all runs per workspace, opt-outs skipped", async () => {
  const tdb = await startTestDatabase();
  const h = createDb(tdb.url, { max: 2 });
  try {
    const a = await createAuthUser(tdb.admin, "a@example.com");
    const b = await createAuthUser(tdb.admin, "b@example.com");
    await tdb.admin`update public.profiles set analytics_opt_out = true where user_id = ${b.id}`;
    const orgRows = await tdb.admin<
      { id: string }[]
    >`insert into public.organizations (name, slug, created_by)
      values ('W', 'w-' || gen_random_uuid(), ${a.id}) returning id`;
    const org = orgRows[0] as { id: string };
    const botRows = await tdb.admin<
      { id: string }[]
    >`insert into public.bots (org_id, name, created_by)
      values (${org.id}, 'Bot', ${a.id}) returning id`;
    const bot = botRows[0] as { id: string };
    const day = new Date("2027-02-03T12:00:00Z");
    const run = (by: string, trigger: string, status: string, cost: number) =>
      tdb.admin`insert into public.runs (org_id, bot_id, created_by, trigger, status, cost_usd, created_at)
        values (${org.id}, ${bot.id}, ${by}, ${trigger}, ${status}, ${cost}, ${day.toISOString()})`;
    await run(a.id, "chat", "completed", 0.5);
    await run(a.id, "chat", "failed", 0.25);
    await run(a.id, "routine", "completed", 1); // automation: workspace only
    await run(b.id, "chat", "completed", 2); // opted out: no usage_daily
    await tdb.admin`insert into public.runs (org_id, bot_id, created_by, trigger, status, cost_usd, created_at)
      values (${org.id}, ${bot.id}, ${a.id}, 'chat', 'completed', 9, '2027-02-02T23:00:00Z')`; // other day

    // An approval decided by the person, and computer time in the workspace.
    const runIdRows = await tdb.admin<
      { id: string }[]
    >`select id from public.runs where org_id = ${org.id} limit 1`;
    await tdb.admin`insert into public.approvals (org_id, bot_id, run_id, call_id, tool_name, risk, status, decided_by, decided_at)
      values (${org.id}, ${bot.id}, ${(runIdRows[0] as { id: string }).id}, 'c1', 'email.send', 'high', 'approved', ${a.id}, ${day.toISOString()})`;
    await tdb.admin`insert into public.usage_ledger (org_id, bot_id, kind, quantity, cost_usd, created_at)
      values (${org.id}, ${bot.id}, 'computer_seconds', 120, 0.01, ${day.toISOString()})`;

    // A workspace that opted out: its runs appear in neither rollup, even for a person who has not opted out.
    const quietRows = await tdb.admin<
      { id: string }[]
    >`insert into public.organizations (name, slug, created_by, analytics_opt_out)
      values ('Q', 'q-' || gen_random_uuid(), ${a.id}, true) returning id`;
    const quiet = quietRows[0] as { id: string };
    const quietBotRows = await tdb.admin<
      { id: string }[]
    >`insert into public.bots (org_id, name, created_by)
      values (${quiet.id}, 'Quiet', ${a.id}) returning id`;
    const quietBot = quietBotRows[0] as { id: string };
    await tdb.admin`insert into public.runs (org_id, bot_id, created_by, trigger, status, cost_usd, created_at)
      values (${quiet.id}, ${quietBot.id}, ${a.id}, 'chat', 'completed', 5, ${day.toISOString()})`;

    const rec = new Recorder();
    const out = await runDailyAnalyticsRollup(h.db, { date: day, analytics: rec });
    expect(out).toEqual({ people: 1, workspaces: 1 });
    expect(rec.events.some((e) => e.orgId === quiet.id)).toBe(false);

    const usage = rec.events.find((e) => e.event === "usage_daily");
    expect(usage?.distinctId).toBe(a.id);
    expect(usage?.properties).toMatchObject({
      runs_started: 2,
      runs_completed: 1,
      runs_failed: 1,
      bots_used: 1,
    });
    expect(usage?.properties?.cost_usd).toBeCloseTo(0.75);
    expect(usage?.uuid).toBe(rollupUuid("usage_daily", a.id, "2027-02-03"));

    const ws = rec.events.find((e) => e.event === "workspace_daily");
    expect(ws).toMatchObject({
      distinctId: `workspace:${org.id}`,
      personless: true,
      orgId: org.id,
    });
    expect(ws?.properties).toMatchObject({
      runs_total: 4,
      runs_by_trigger_chat: 3,
      runs_by_trigger_routine: 1,
      computer_seconds: 120,
      approvals_approved: 1,
      members_active: 2,
      bots_active: 1,
    });
    // No text or names ever leave: only numbers.
    for (const e of rec.events)
      for (const v of Object.values(e.properties ?? {})) expect(typeof v).toBe("number");

    // A retry produces the same ids, so PostHog merges instead of doubling.
    const again = new Recorder();
    await runDailyAnalyticsRollup(h.db, { date: day, analytics: again });
    expect(again.events.map((e) => e.uuid)).toEqual(rec.events.map((e) => e.uuid));
  } finally {
    await h.close();
    await tdb.stop();
  }
});

it("rollup ids are valid, stable UUIDs", () => {
  const id = rollupUuid("usage_daily", "u1", "2027-02-03");
  expect(id).toMatch(/^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/);
  expect(rollupUuid("usage_daily", "u1", "2027-02-03")).toBe(id);
  expect(rollupUuid("usage_daily", "u2", "2027-02-03")).not.toBe(id);
});
