import { describe, expect, it } from "vitest";
import {
  fileSlug,
  parseRoutineFile,
  parseSkillFile,
  parseWorkspaceFiles,
  renderRoutineFile,
  renderSkillFile,
} from "../src/workspace-files.ts";

const enc = (s: string) => new TextEncoder().encode(s);

describe("routines and skills as files", () => {
  it("round-trips a routine and checks it", () => {
    const r = {
      id: "11111111-1111-4111-8111-111111111111",
      name: "Morning: brief",
      schedule: "0 7 * * 1-5",
      timezone: "Asia/Manila",
      trigger: "schedule" as const,
      enabled: false,
      notify: true,
      endsAt: null,
      maxRuns: null,
      instructions: "Send my brief.\n\n- calendar\n- email",
    };
    const text = renderRoutineFile(r);
    expect(text).toContain('name: "Morning: brief"');
    expect(parseRoutineFile(text, "a/routines/x.md")).toEqual(r);
    expect(() => parseRoutineFile("---\nname: x\nschedule: nope\n---\nDo it", "p.md")).toThrow(
      /valid cron/,
    );
    expect(() => parseRoutineFile("---\nname: x\n---\nDo it", "p.md")).toThrow(/needs schedule/);
    expect(parseRoutineFile("---\nname: Hook\ntrigger: webhook\n---\nDo it", "p.md")).toMatchObject(
      { schedule: null, trigger: "webhook", enabled: true, timezone: "UTC" },
    );
    expect(() =>
      parseRoutineFile(
        "---\nname: x\nschedule: 0 7 * * *\ntimezone: Mars/Base\n---\nDo it",
        "p.md",
      ),
    ).toThrow(/timezone/);
  });

  it("round-trips every trigger kind, with ends (D-262)", () => {
    const base = {
      id: "22222222-2222-4222-8222-222222222222",
      name: "Trip prep",
      timezone: "Asia/Manila",
      enabled: true,
      notify: false,
      instructions: "Get me ready.",
    };
    const cases = [
      {
        ...base,
        trigger: "schedule" as const,
        schedule: "0 9 * * 1",
        endsAt: "2027-03-31T17:00:00.000Z",
        maxRuns: 10,
      },
      { ...base, trigger: "once" as const, schedule: null, runAt: "2027-01-02T03:04:05.000Z" },
      { ...base, trigger: "once" as const, schedule: null, runAt: null, enabled: false },
      { ...base, trigger: "webhook" as const, schedule: null, endsAt: null, maxRuns: 3 },
      { ...base, trigger: "github" as const, schedule: null, endsAt: null, maxRuns: null },
      {
        ...base,
        trigger: "calendar_event" as const,
        schedule: null,
        triggerConfig: {
          integration_id: "33333333-3333-4333-8333-333333333333",
          offset_minutes: -15,
          title_match: 'Board: "Q1" #review',
          outside_guests: true,
        },
        endsAt: null,
        maxRuns: null,
      },
      {
        ...base,
        trigger: "message" as const,
        schedule: null,
        triggerConfig: { channel_kind: "email", sender: "*@acme.com" },
        endsAt: "2027-01-01T00:00:00.000Z",
        maxRuns: null,
      },
      {
        ...base,
        trigger: "device" as const,
        schedule: null,
        triggerConfig: { event: "arrive", place: "Home" },
        endsAt: null,
        maxRuns: 5,
      },
    ];
    for (const r of cases) {
      const text = renderRoutineFile(r);
      expect(parseRoutineFile(text, "a/routines/x.md")).toEqual(r);
    }
    const cal = renderRoutineFile(cases[5] as (typeof cases)[number]);
    // One line of JSON, keys sorted, so git diffs stay small.
    expect(cal).toContain(
      'calendar: {"integration_id":"33333333-3333-4333-8333-333333333333","offset_minutes":-15,"outside_guests":true,"title_match":"Board: \\"Q1\\" #review"}',
    );
    expect(renderRoutineFile(cases[1] as (typeof cases)[number])).not.toContain("ends_at");
  });

  it("reads hand-written trigger settings and old files, and checks the new fields", () => {
    expect(
      parseRoutineFile(
        '---\nname: Home\ntrigger: device\ndevice:\n  event: arrive\n  place: "Home: main"\n  minutes_before: 5\n---\nHi',
        "p.md",
      ),
    ).toMatchObject({ triggerConfig: { event: "arrive", place: "Home: main", minutes_before: 5 } });
    // A file from before D-262 says nothing about ends: they're left as they are.
    const old = parseRoutineFile("---\nname: x\nschedule: 0 7 * * *\n---\nDo it", "p.md");
    expect(old).not.toHaveProperty("endsAt");
    expect(old).not.toHaveProperty("maxRuns");
    expect(parseRoutineFile("---\nname: x\ntrigger: once\n---\nDo it", "p.md")).not.toHaveProperty(
      "runAt",
    );
    const bad = (front: string, msg: RegExp) =>
      expect(() => parseRoutineFile(`---\nname: x\n${front}\n---\nDo it`, "p.md")).toThrow(msg);
    bad("trigger: device", /needs its device settings/);
    bad("trigger: message\nmessage: {nope", /valid JSON/);
    bad("trigger: message\nmessage: [1]", /valid JSON|map of settings/);
    bad("trigger: once\nrun_at: tomorrow", /run_at must be a date/);
    bad("trigger: once\nrun_at: 2027-01-01T00:00:00Z\nmax_runs: 2", /already ends after its run/);
    bad("schedule: 0 7 * * *\nrun_at: 2027-01-01T00:00:00Z", /only for once/);
    bad("trigger: webhook\nschedule: 0 7 * * *", /only for schedule triggers/);
    bad("schedule: 0 7 * * *\nmax_runs: 0", /1 to 10,000/);
    bad("schedule: 0 7 * * *\nmax_runs: 2.5", /1 to 10,000/);
    bad("schedule: 0 7 * * *\nends_at: soon", /ends_at must be a date/);
    bad("trigger: sometimes", /trigger must be/);
  });

  it("round-trips a skill and needs the folder to match its name", () => {
    const s = {
      name: "pr-labels",
      description: "Label PRs: by area",
      enabled: true,
      body: "Read the diff.",
    };
    expect(parseSkillFile(renderSkillFile(s), "ada/skills/pr-labels/SKILL.md")).toEqual(s);
    expect(() => parseSkillFile(renderSkillFile(s), "ada/skills/other/SKILL.md")).toThrow(
      /folder name/,
    );
  });

  it("reads a folder, reporting bad files without stopping", () => {
    const parsed = parseWorkspaceFiles(
      new Map([
        ["ada/routines/brief.md", enc("---\nname: Brief\nschedule: 0 7 * * *\n---\nBrief me")],
        ["ada/routines/broken.md", enc("no front matter")],
        [
          "ada/skills/pr-labels/SKILL.md",
          enc("---\nname: pr-labels\ndescription: Label\n---\nSteps"),
        ],
        ["ada/skills/pr-labels/scripts/run.sh", enc("echo")],
        [
          "workspace/skills/style/SKILL.md",
          enc("---\nname: style\ndescription: House style\n---\nRules"),
        ],
        ["README.md", enc("hi")],
      ]),
    );
    expect(parsed.routines.map((r) => r.routine.name)).toEqual(["Brief"]);
    expect(parsed.skills.map((s) => `${s.folder}/${s.skill.name}`)).toEqual([
      "ada/pr-labels",
      "workspace/style",
    ]);
    expect(parsed.skills[0]?.files.map((f) => f.path)).toEqual(["scripts/run.sh"]);
    expect(parsed.errors).toEqual([
      "ada/routines/broken.md: must start with front matter between --- lines",
    ]);
    expect(fileSlug("Ada Lovelace (ops)")).toBe("ada-lovelace-ops");
  });
});
