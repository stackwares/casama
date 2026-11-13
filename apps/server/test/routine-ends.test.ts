/** Routines that end (D-262): ends_at and max_runs, enforced by the worker, set by bots and the API. */
import { registerAutonomyTools, ToolRegistry } from "@casama/agent";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import {
  claimDueRoutines,
  expireRoutines,
  runRoutineNow,
  startRoutineForMessage,
} from "../src/worker/routines.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
let owner: { id: string; token: string };
let orgId: string;
let botId: string;
let runId: string;
const reg = new ToolRegistry();

const ctx = () => ({ runId, botId, orgId, output: async () => {}, emit: async () => {} }) as never;
const call = (name: string, args: unknown) => reg.get(name)!.execute(args as never, ctx());
const inHours = (n: number) => new Date(Date.now() + n * 3600_000).toISOString();

type Row = {
  id: string;
  enabled: boolean;
  next_run_at: Date | null;
  ends_at: Date | null;
  max_runs: number | null;
  run_count: number;
  schedule_cron: string | null;
  timezone: string;
  name: string;
  trigger: { type: string; event?: string; place?: string };
};
const row = async (id: string) =>
  (
    await h.tdb.admin<Row[]>`
      select id, enabled, next_run_at, ends_at, max_runs, run_count, schedule_cron, timezone, name, trigger
      from public.routines where id = ${id}`
  )[0]!;
const byName = async (name: string) =>
  (
    await h.tdb.admin<
      { id: string }[]
    >`select id from public.routines where bot_id = ${botId} and name = ${name}`
  )[0]!.id;
const due = (id: string) =>
  h.tdb
    .admin`update public.routines set next_run_at = now() - interval '1 minute' where id = ${id}`;
const runCount = async (id: string) =>
  (
    await h.tdb.admin<
      { n: number }[]
    >`select count(*)::int as n from public.runs where routine_id = ${id}`
  )[0]!.n;

beforeAll(async () => {
  h = await startHarness();
  owner = await h.user("routine-ends@example.com");
  await h.tdb
    .admin`update public.profiles set timezone = 'America/Chicago' where user_id = ${owner.id}`;
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "Ends" } }),
    )
  ).id;
  const cred = await j(
    await h.request("/v1/credentials", {
      method: "POST",
      token: owner.token,
      json: { org_id: orgId, provider: "openrouter", label: "k", api_key: "sk-or-v1-abcdefabcdef" },
    }),
  );
  botId = (
    await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: owner.token,
        json: {
          org_id: orgId,
          name: "Ender",
          autonomy: "ask_risky",
          budget: { per_run_usd: 2, daily_usd: 20 },
          model_policy: { primary: { credential_id: cred.id, model: "m" } },
        },
      }),
    )
  ).id;
  const [run] = await h.tdb.admin<{ id: string }[]>`
    insert into public.runs (org_id, bot_id, trigger, status, created_by)
    values (${orgId}, ${botId}, 'chat', 'running', ${owner.id}) returning id`;
  runId = run!.id;
  registerAutonomyTools(reg, { db: h.handle.db } as never);
}, 60_000);
afterAll(async () => h?.stop());

describe("bot tools", () => {
  it("creates a repeating routine that ends at a time and after some runs, and lists both", async () => {
    const ends = inHours(24 * 30);
    const made = await call("routines.create", {
      name: "Standup",
      instructions: "Ask about the day.",
      schedule_cron: "0 9 * * 1-5",
      ends_at: ends,
      max_runs: 3,
    });
    expect(made.content).toContain("3 of 3 runs left");
    const r = await row(await byName("Standup"));
    expect(new Date(r.ends_at!).toISOString()).toBe(ends);
    expect(r.max_runs).toBe(3);
    expect(r.run_count).toBe(0);
    const listed = await call("routines.list", {});
    expect(listed.content).toContain(`ends ${ends}`);
    expect(listed.content).toContain("3 of 3 runs left");
  });

  it("refuses ends on a one-time routine, an end in the past, and an end before the first run", async () => {
    await expect(
      call("routines.create", { name: "a", instructions: "b", in_minutes: 5, max_runs: 2 }),
    ).rejects.toMatchObject({ code: "invalid_schedule" });
    await expect(
      call("routines.create", {
        name: "a",
        instructions: "b",
        schedule_cron: "0 9 * * *",
        ends_at: inHours(-1),
      }),
    ).rejects.toMatchObject({ code: "invalid_time" });
    // Monthly on the 1st, ending in an hour: it would never run.
    const soon = new Date(Date.now() + 3600_000);
    const day = soon.getUTCDate() === 1 ? 2 : 1;
    await expect(
      call("routines.create", {
        name: "a",
        instructions: "b",
        schedule_cron: `0 0 ${day} * *`,
        timezone: "UTC",
        ends_at: soon.toISOString(),
      }),
    ).rejects.toThrow(/end before its first run/);
  });

  it("updates name, timezone and schedule; switches between once and repeating", async () => {
    await call("routines.create", { name: "Ping", instructions: "Ping.", in_minutes: 30 });
    const id = await byName("Ping");
    // Once → repeating.
    const repeat = await call("routines.update", {
      routine_id: id,
      schedule_cron: "30 7 * * *",
      name: "Morning ping",
      timezone: "Europe/Berlin",
    });
    expect(repeat.content).toContain("Europe/Berlin");
    let r = await row(id);
    expect(r.trigger.type).toBe("schedule");
    expect(r.schedule_cron).toBe("30 7 * * *");
    expect(r.name).toBe("Morning ping");
    expect(r.timezone).toBe("Europe/Berlin");
    expect(new Date(r.next_run_at!).getTime()).toBeGreaterThan(Date.now());
    // Repeating → once, with ends dropped (a one-time routine ends after its run).
    await call("routines.update", { routine_id: id, max_runs: 4 });
    expect((await row(id)).max_runs).toBe(4);
    const before = Date.now();
    await call("routines.update", { routine_id: id, in_minutes: 10 });
    r = await row(id);
    expect(r.trigger.type).toBe("once");
    expect(r.schedule_cron).toBeNull();
    expect(r.max_runs).toBeNull();
    const delay = new Date(r.next_run_at!).getTime() - before;
    expect(delay).toBeGreaterThan(9 * 60_000);
    expect(delay).toBeLessThan(11 * 60_000);
    // A time in the past, and two schedules at once, are refused.
    await expect(
      call("routines.update", { routine_id: id, run_at: inHours(-2) }),
    ).rejects.toMatchObject({ code: "invalid_time" });
    await expect(
      call("routines.update", { routine_id: id, run_at: inHours(2), schedule_cron: "0 9 * * *" }),
    ).rejects.toMatchObject({ code: "invalid_schedule" });
  });

  it("a finished one-time routine resumes only with a new time", async () => {
    await call("routines.create", { name: "Done once", instructions: "x", in_minutes: 1 });
    const id = await byName("Done once");
    await due(id);
    await claimDueRoutines(h.handle.db);
    expect((await row(id)).enabled).toBe(false);
    await expect(call("routines.update", { routine_id: id, enabled: true })).rejects.toThrow(
      /already run/,
    );
    await call("routines.update", { routine_id: id, enabled: true, in_minutes: 60 });
    const r = await row(id);
    expect(r.enabled).toBe(true);
    expect(new Date(r.next_run_at!).getTime()).toBeGreaterThan(Date.now() + 50 * 60_000);
  });

  it("an ended routine resumes only once its end moves; a new max_runs counts from now", async () => {
    await call("routines.create", {
      name: "Thrice",
      instructions: "x",
      schedule_cron: "0 * * * *",
      max_runs: 1,
    });
    const id = await byName("Thrice");
    await due(id);
    await claimDueRoutines(h.handle.db);
    let r = await row(id);
    expect([r.enabled, r.run_count, r.next_run_at]).toEqual([false, 1, null]);
    await expect(call("routines.update", { routine_id: id, enabled: true })).rejects.toMatchObject({
      code: "routine_ended",
    });
    await call("routines.update", { routine_id: id, enabled: true, max_runs: 2 });
    r = await row(id);
    expect([r.enabled, r.run_count, r.max_runs]).toEqual([true, 0, 2]);
    // null removes it.
    await call("routines.update", { routine_id: id, max_runs: null, ends_at: inHours(48) });
    r = await row(id);
    expect(r.max_runs).toBeNull();
    expect(r.ends_at).not.toBeNull();
    await call("routines.update", { routine_id: id, ends_at: null });
    expect((await row(id)).ends_at).toBeNull();
  });

  it("edits a device routine's event, and only a device routine takes one", async () => {
    await h.tdb.admin`
      insert into public.routines (org_id, bot_id, created_by, name, instructions_md, trigger)
      values (${orgId}, ${botId}, ${owner.id}, 'Home', 'Welcome home', '{"type":"device","event":"arrive","place":"Home"}')`;
    const id = await byName("Home");
    await expect(
      call("routines.update", { routine_id: id, on_device_event: { event: "leave" } }),
    ).rejects.toMatchObject({ code: "place_required" });
    await call("routines.update", {
      routine_id: id,
      on_device_event: { event: "leave", place: "Office" },
      max_runs: 5,
    });
    const r = await row(id);
    expect(r.trigger).toEqual({ type: "device", event: "leave", place: "Office" });
    expect(r.max_runs).toBe(5);
    expect(r.next_run_at).toBeNull();
    await expect(
      call("routines.update", { routine_id: id, schedule_cron: "0 9 * * *" }),
    ).rejects.toThrow(/device event/);
    const sched = await byName("Morning ping");
    await expect(
      call("routines.update", { routine_id: sched, on_device_event: { event: "wake" } }),
    ).rejects.toMatchObject({ code: "invalid_schedule" });
  });
});

describe("the worker", () => {
  it("max_runs: runs that many times, then switches off; run now doesn't count", async () => {
    const [r0] = await h.tdb.admin<{ id: string }[]>`
      insert into public.routines (org_id, bot_id, created_by, name, instructions_md, schedule_cron, timezone, next_run_at, max_runs)
      values (${orgId}, ${botId}, ${owner.id}, 'Twice', 'x', '0 * * * *', 'UTC', now() - interval '1 minute', 2) returning id`;
    const id = r0!.id;
    await runRoutineNow(h.handle.db, id);
    expect((await row(id)).run_count).toBe(0);
    await claimDueRoutines(h.handle.db);
    let r = await row(id);
    expect([r.enabled, r.run_count]).toEqual([true, 1]);
    expect(new Date(r.next_run_at!).getTime()).toBeGreaterThan(Date.now());
    await due(id);
    await claimDueRoutines(h.handle.db);
    r = await row(id);
    expect([r.enabled, r.run_count, r.next_run_at]).toEqual([false, 2, null]);
    await due(id);
    await claimDueRoutines(h.handle.db);
    expect(await runCount(id)).toBe(3); // two scheduled, one manual
  });

  it("ends_at: a next run past the end switches it off instead", async () => {
    const [r0] = await h.tdb.admin<{ id: string }[]>`
      insert into public.routines (org_id, bot_id, created_by, name, instructions_md, schedule_cron, timezone, next_run_at, ends_at)
      values (${orgId}, ${botId}, ${owner.id}, 'Daily till soon', 'x', '0 0 * * *', 'UTC', now() - interval '1 minute', now() + interval '2 hours') returning id`;
    const id = r0!.id;
    await claimDueRoutines(h.handle.db);
    const r = await row(id);
    // It ran this time (due before the end), but tomorrow's midnight is past the end.
    expect(await runCount(id)).toBe(1);
    expect([r.enabled, r.next_run_at]).toEqual([false, null]);
  });

  it("a routine due after its end doesn't run; the sweep switches off ended event routines", async () => {
    const [late] = await h.tdb.admin<{ id: string }[]>`
      insert into public.routines (org_id, bot_id, created_by, name, instructions_md, schedule_cron, timezone, next_run_at, ends_at)
      values (${orgId}, ${botId}, ${owner.id}, 'Late', 'x', '0 * * * *', 'UTC', now() - interval '1 minute', now() - interval '2 minutes') returning id`;
    const [msg] = await h.tdb.admin<{ id: string }[]>`
      insert into public.routines (org_id, bot_id, created_by, name, instructions_md, trigger, ends_at)
      values (${orgId}, ${botId}, ${owner.id}, 'Mail', 'x', '{"type":"message","sender":"a@b.c"}', now() - interval '1 minute') returning id`;
    await claimDueRoutines(h.handle.db);
    expect(await runCount(late!.id)).toBe(0);
    expect(await startRoutineForMessage(h.handle.db, msg!.id, "hello")).toBeNull();
    expect(await expireRoutines(h.handle.db)).toBeGreaterThanOrEqual(2);
    expect((await row(late!.id)).enabled).toBe(false);
    expect((await row(msg!.id)).enabled).toBe(false);
  });

  it("event routines count runs toward max_runs", async () => {
    const [msg] = await h.tdb.admin<{ id: string }[]>`
      insert into public.routines (org_id, bot_id, created_by, name, instructions_md, trigger, max_runs)
      values (${orgId}, ${botId}, ${owner.id}, 'One mail', 'x', '{"type":"message","sender":"a@b.c"}', 1) returning id`;
    expect(await startRoutineForMessage(h.handle.db, msg!.id, "first")).toBeTruthy();
    expect((await row(msg!.id)).enabled).toBe(false);
    expect(await startRoutineForMessage(h.handle.db, msg!.id, "second")).toBeNull();
  });
});

describe("the API", () => {
  it("creates, shows and changes ends; refuses resuming an ended routine", async () => {
    const ends = inHours(24 * 10);
    const res = await h.request("/v1/routines", {
      method: "POST",
      token: owner.token,
      json: {
        bot_id: botId,
        name: "API daily",
        instructions: "x",
        trigger: "schedule",
        schedule_cron: "0 8 * * *",
        ends_at: ends,
        max_runs: 4,
      },
    });
    expect(res.status).toBe(201);
    const created = await j(res);
    expect(created).toMatchObject({ max_runs: 4, run_count: 0 });
    expect(new Date(created.ends_at).toISOString()).toBe(ends);

    const once = await h.request("/v1/routines", {
      method: "POST",
      token: owner.token,
      json: {
        bot_id: botId,
        name: "API once",
        instructions: "x",
        trigger: "once",
        run_at: inHours(1),
        max_runs: 2,
      },
    });
    expect(once.status).toBe(400);

    const patch = (json: Record<string, unknown>) =>
      h.request(`/v1/routines/${created.id}`, { method: "PATCH", token: owner.token, json });
    const cleared = await j(await patch({ ends_at: null, max_runs: null }));
    expect(cleared).toMatchObject({ ends_at: null, max_runs: null });

    await h.tdb
      .admin`update public.routines set max_runs = 2, run_count = 2, enabled = false, next_run_at = null where id = ${created.id}`;
    expect((await patch({ enabled: true })).status).toBe(400);
    const resumed = await j(await patch({ enabled: true, max_runs: 3 }));
    expect(resumed).toMatchObject({ enabled: true, max_runs: 3, run_count: 0 });
    expect(resumed.next_run_at).toBeTruthy();
    expect((await patch({ ends_at: inHours(-1) })).status).toBe(400);

    // A repeating routine given run_at runs once.
    const at = inHours(3);
    const switched = await j(await patch({ run_at: at }));
    expect(switched).toMatchObject({ trigger: "once", schedule_cron: null, max_runs: null });
    expect(new Date(switched.next_run_at).toISOString()).toBe(at);
  });
});
