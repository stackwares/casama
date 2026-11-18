/**
 * Routine files (D-124) carry every trigger kind and routine ends (D-262), and import follows the
 * API's rules: no switching on a routine past its end or out of runs, and a one-time routine
 * keeps its pending run.
 */
import { applyWorkspaceFiles } from "@casama/agent";
import { parseRoutineFile } from "@casama/domain";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
let owner: { id: string; token: string };
let orgId: string;
let botId: string;
let calId: string;

const future = (days: number) => new Date(Date.now() + days * 86_400_000).toISOString();
const b64 = (s: string) => Buffer.from(s).toString("base64");

const exportFiles = async () => {
  const ex = await j(
    await h.request(`/v1/orgs/${orgId}/files/export`, { method: "POST", token: owner.token }),
  );
  return new Map<string, string>(
    (ex.files as Array<{ path: string; content_base64: string }>).map((f) => [
      f.path,
      Buffer.from(f.content_base64, "base64").toString(),
    ]),
  );
};
const importFiles = async (files: Map<string, string>, dryRun = false) =>
  j(
    await h.request(`/v1/orgs/${orgId}/files/import`, {
      method: "POST",
      token: owner.token,
      json: {
        files: [...files].map(([path, c]) => ({ path, content_base64: b64(c) })),
        dry_run: dryRun,
      },
    }),
  );
const row = async (name: string) =>
  (
    await h.tdb.admin<
      {
        id: string;
        trigger: Record<string, unknown>;
        schedule_cron: string | null;
        enabled: boolean;
        next_run_at: Date | null;
        ends_at: Date | null;
        max_runs: number | null;
        run_count: number;
        instructions_md: string;
      }[]
    >`select id, trigger, schedule_cron, enabled, next_run_at, ends_at, max_runs, run_count, instructions_md
      from public.routines where org_id = ${orgId} and name = ${name}`
  )[0];
const iso = (d: Date | string | null | undefined) => (d ? new Date(d).toISOString() : null);

const RUN_AT = future(3);
const ENDS_AT = future(90);

beforeAll(async () => {
  h = await startHarness();
  owner = await h.user("routine-files@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "RF" } }),
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
          name: "Ada",
          model_policy: { primary: { credential_id: cred.id, model: "m" } },
        },
      }),
    )
  ).id;
  const [cal] = await h.tdb.admin<{ id: string }[]>`
    insert into public.integrations (org_id, kind, name, config) values (${orgId}, 'mcp', 'gcal', '{"app":"google_calendar","url":"https://mcp.test/remote"}') returning id`;
  calId = cal!.id;
  const ins = (
    name: string,
    trigger: Record<string, unknown>,
    extra: { cron?: string; next?: string | null; ends?: string; max?: number } = {},
  ) => h.tdb.admin`
    insert into public.routines (org_id, bot_id, created_by, name, instructions_md, schedule_cron, timezone, trigger, next_run_at, ends_at, max_runs)
    values (${orgId}, ${botId}, ${owner.id}, ${name}, ${`Do ${name}.`}, ${extra.cron ?? null}, 'Asia/Manila', ${trigger as never},
            ${extra.next ?? null}, ${extra.ends ?? null}, ${extra.max ?? null})`;
  await ins(
    "Weekly",
    { type: "schedule" },
    {
      cron: "0 9 * * 1",
      next: future(1),
      ends: ENDS_AT,
      max: 10,
    },
  );
  await ins("Once", { type: "once" }, { next: RUN_AT });
  await ins("Mail", { type: "message", channel_kind: "email", sender: "*@acme.com" });
  await ins("Before meetings", {
    type: "calendar_event",
    integration_id: calId,
    offset_minutes: -15,
    checked_at: "2026-11-01T00:00:00.000Z",
  });
  await ins("Home", { type: "device", event: "arrive", place: "Home" }, { max: 5 });
  await ins("Hook", { type: "webhook", vault_secret_id: "00000000-0000-0000-0000-000000000000" });
  // A check-in is the bot's check-in settings, never a file.
  await h.tdb.admin`
    insert into public.routines (org_id, bot_id, name, instructions_md, schedule_cron, timezone, trigger, kind, next_run_at)
    values (${orgId}, ${botId}, 'Morning brief', 'Brief.', '0 8 * * *', 'UTC', '{"type":"schedule"}', 'brief', now())`;
}, 60_000);
afterAll(async () => h?.stop());

describe("routine files: every trigger and routine ends", () => {
  it("exports every trigger kind as a file that imports back unchanged", async () => {
    const files = await exportFiles();
    const routines = [...files].filter(([p]) => p.includes("/routines/"));
    expect(routines.map(([p]) => p).sort()).toEqual([
      "ada/routines/before-meetings.md",
      "ada/routines/home.md",
      "ada/routines/hook.md",
      "ada/routines/mail.md",
      "ada/routines/once.md",
      "ada/routines/weekly.md",
    ]);
    const parsed = Object.fromEntries(routines.map(([p, t]) => [p, parseRoutineFile(t, p)]));
    expect(parsed["ada/routines/weekly.md"]).toMatchObject({
      trigger: "schedule",
      schedule: "0 9 * * 1",
      endsAt: ENDS_AT,
      maxRuns: 10,
    });
    expect(parsed["ada/routines/once.md"]).toMatchObject({
      trigger: "once",
      schedule: null,
      runAt: RUN_AT,
    });
    expect(parsed["ada/routines/mail.md"]).toMatchObject({
      trigger: "message",
      triggerConfig: { channel_kind: "email", sender: "*@acme.com" },
    });
    // Casama's own bookkeeping (checked_at) stays out of the file.
    expect(parsed["ada/routines/before-meetings.md"]?.triggerConfig).toEqual({
      integration_id: calId,
      offset_minutes: -15,
    });
    expect(parsed["ada/routines/home.md"]).toMatchObject({
      trigger: "device",
      triggerConfig: { event: "arrive", place: "Home" },
      maxRuns: 5,
    });
    expect(parsed["ada/routines/hook.md"]).toMatchObject({ trigger: "webhook", schedule: null });

    const back = await importFiles(files);
    expect(back).toMatchObject({ created: [], updated: [], errors: [], unchanged: 6 });
  });

  it("creates every trigger kind from files, with its end", async () => {
    const files = await exportFiles();
    const keep = ["Weekly", "Once", "Mail", "Before meetings", "Home"];
    for (const n of keep)
      await h.tdb.admin`delete from public.routines where org_id = ${orgId} and name = ${n}`;
    const r = await importFiles(new Map([...files].filter(([p]) => !p.endsWith("hook.md"))));
    expect(r.errors).toEqual([]);
    expect(r.created.sort()).toHaveLength(5);
    const weekly = await row("Weekly");
    expect(weekly).toMatchObject({ schedule_cron: "0 9 * * 1", max_runs: 10, enabled: true });
    expect(iso(weekly?.ends_at)).toBe(ENDS_AT);
    expect(weekly?.next_run_at).not.toBeNull();
    const once = await row("Once");
    expect(once?.trigger).toEqual({ type: "once" });
    expect(iso(once?.next_run_at)).toBe(RUN_AT);
    expect((await row("Mail"))?.trigger).toEqual({
      type: "message",
      channel_kind: "email",
      sender: "*@acme.com",
    });
    expect((await row("Before meetings"))?.trigger).toEqual({
      type: "calendar_event",
      integration_id: calId,
      offset_minutes: -15,
    });
    expect(await row("Home")).toMatchObject({
      trigger: { type: "device", event: "arrive", place: "Home" },
      max_runs: 5,
      next_run_at: null,
    });
    // And the new rows export to the same files.
    const again = await exportFiles();
    for (const [p, t] of again)
      if (p.includes("/routines/"))
        expect(parseRoutineFile(t, p)).toMatchObject({
          ...parseRoutineFile(files.get(p) as string, p),
          id: expect.any(String),
        });
  });

  it("keeps a one-time routine's pending run when its file changes something else", async () => {
    const files = await exportFiles();
    const p = "ada/routines/once.md";
    const edited = (files.get(p) as string).replace("Do Once.", "Do Once, carefully.");
    const r = await importFiles(new Map([[p, edited]]));
    expect(r.updated).toEqual([p]);
    const once = await row("Once");
    expect(once?.instructions_md).toBe("Do Once, carefully.");
    expect(once?.enabled).toBe(true);
    expect(iso(once?.next_run_at)).toBe(RUN_AT);
    // A hand-written file without run_at keeps it too.
    const noRunAt = edited.replace(/run_at: .*\n/, "").replace("carefully", "gently");
    expect((await importFiles(new Map([[p, noRunAt]]))).errors).toEqual([]);
    expect(iso((await row("Once"))?.next_run_at)).toBe(RUN_AT);
    // Moving it moves the run.
    const later = future(5);
    await importFiles(
      new Map([[p, noRunAt.replace("trigger: once", `run_at: ${later}\ntrigger: once`)]]),
    );
    expect(iso((await row("Once"))?.next_run_at)).toBe(later);
  });

  it("won't switch on a routine that ran out of runs or is past its end, as the API won't", async () => {
    const weekly = await row("Weekly");
    // It ran its 10 times and switched itself off.
    await h.tdb
      .admin`update public.routines set run_count = 10, enabled = false, next_run_at = null where id = ${weekly!.id}`;
    const files = await exportFiles();
    const p = "ada/routines/weekly.md";
    const off = files.get(p) as string;
    expect(off).toContain("enabled: false");
    const on = off.replace("enabled: false", "enabled: true");
    const r = await importFiles(new Map([[p, on]]));
    expect(r.updated).toEqual([]);
    expect(r.errors.join()).toMatch(/already ran its 10 times/);
    expect(await row("Weekly")).toMatchObject({ enabled: false, next_run_at: null });

    // Git sync applies files the same way (no person behind it).
    const viaSync = await applyWorkspaceFiles(h.handle.db, orgId, new Map([[p, Buffer.from(on)]]));
    expect(viaSync.errors.join()).toMatch(/already ran its 10 times/);
    expect((await row("Weekly"))?.enabled).toBe(false);

    // A new limit counts from now, so raising it switches the routine back on.
    const raised = on.replace("max_runs: 10", "max_runs: 3");
    expect((await importFiles(new Map([[p, raised]]))).errors).toEqual([]);
    expect(await row("Weekly")).toMatchObject({ enabled: true, max_runs: 3, run_count: 0 });
    expect((await row("Weekly"))?.next_run_at).not.toBeNull();

    // Past its end: off it stays.
    await h.tdb
      .admin`update public.routines set ends_at = now() - interval '1 day', enabled = false, next_run_at = null where id = ${weekly!.id}`;
    const ended = (await exportFiles()).get(p) as string;
    const r2 = await importFiles(new Map([[p, ended.replace("enabled: false", "enabled: true")]]));
    expect(r2.errors.join()).toMatch(/end time \(ends_at\) has passed/);
    expect((await row("Weekly"))?.enabled).toBe(false);
    // Removing the end in the file removes it.
    const noEnd = ended
      .replace(/ends_at: .*/, "ends_at: null")
      .replace("enabled: false", "enabled: true");
    expect((await importFiles(new Map([[p, noEnd]]))).errors).toEqual([]);
    expect(await row("Weekly")).toMatchObject({ enabled: true, ends_at: null });
  });

  it("keeps the run count when max_runs is unchanged, and refuses changing an event trigger's kind", async () => {
    const home = await row("Home");
    await h.tdb.admin`update public.routines set run_count = 2 where id = ${home!.id}`;
    const files = await exportFiles();
    const p = "ada/routines/home.md";
    const text = files.get(p) as string;
    await importFiles(new Map([[p, text.replace('"place":"Home"', '"place":"Work"')]]));
    expect(await row("Home")).toMatchObject({
      run_count: 2,
      max_runs: 5,
      trigger: { type: "device", event: "arrive", place: "Work" },
    });
    const toSchedule = text
      .replace("trigger: device", "trigger: schedule")
      .replace("schedule: null", 'schedule: "0 9 * * *"')
      .replace(/device: .*\n/, "");
    const r = await importFiles(new Map([[p, toSchedule]]));
    expect(r.errors.join()).toMatch(/device routine can't become a schedule one/);
    const badCal = (files.get("ada/routines/before-meetings.md") as string).replace(
      calId,
      "44444444-4444-4444-8444-444444444444",
    );
    const r2 = await importFiles(new Map([["ada/routines/before-meetings.md", badCal]]));
    expect(r2.errors.join()).toMatch(/isn't a calendar connected in this workspace/);
  });
});
