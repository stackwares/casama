import { describe, expect, it } from "vitest";
import { parseRoutineFile, parseSkillFile, parseWorkspaceFiles, renderRoutineFile, renderSkillFile, fileSlug } from "../src/workspace-files.ts";

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
      instructions: "Send my brief.\n\n- calendar\n- email",
    };
    const text = renderRoutineFile(r);
    expect(text).toContain('name: "Morning: brief"');
    expect(parseRoutineFile(text, "a/routines/x.md")).toEqual(r);
    expect(() => parseRoutineFile("---\nname: x\nschedule: nope\n---\nDo it", "p.md")).toThrow(/valid cron/);
    expect(() => parseRoutineFile("---\nname: x\n---\nDo it", "p.md")).toThrow(/needs schedule/);
    expect(parseRoutineFile("---\nname: Hook\ntrigger: webhook\n---\nDo it", "p.md")).toMatchObject({ schedule: null, trigger: "webhook", enabled: true, timezone: "UTC" });
    expect(() => parseRoutineFile("---\nname: x\nschedule: 0 7 * * *\ntimezone: Mars/Base\n---\nDo it", "p.md")).toThrow(/timezone/);
  });

  it("round-trips a skill and needs the folder to match its name", () => {
    const s = { name: "pr-labels", description: "Label PRs: by area", enabled: true, body: "Read the diff." };
    expect(parseSkillFile(renderSkillFile(s), "ada/skills/pr-labels/SKILL.md")).toEqual(s);
    expect(() => parseSkillFile(renderSkillFile(s), "ada/skills/other/SKILL.md")).toThrow(/folder name/);
  });

  it("reads a folder, reporting bad files without stopping", () => {
    const parsed = parseWorkspaceFiles(
      new Map([
        ["ada/routines/brief.md", enc("---\nname: Brief\nschedule: 0 7 * * *\n---\nBrief me")],
        ["ada/routines/broken.md", enc("no front matter")],
        ["ada/skills/pr-labels/SKILL.md", enc("---\nname: pr-labels\ndescription: Label\n---\nSteps")],
        ["ada/skills/pr-labels/scripts/run.sh", enc("echo")],
        ["workspace/skills/style/SKILL.md", enc("---\nname: style\ndescription: House style\n---\nRules")],
        ["README.md", enc("hi")],
      ]),
    );
    expect(parsed.routines.map((r) => r.routine.name)).toEqual(["Brief"]);
    expect(parsed.skills.map((s) => `${s.folder}/${s.skill.name}`)).toEqual(["ada/pr-labels", "workspace/style"]);
    expect(parsed.skills[0]?.files.map((f) => f.path)).toEqual(["scripts/run.sh"]);
    expect(parsed.errors).toEqual(["ada/routines/broken.md: must start with front matter between --- lines"]);
    expect(fileSlug("Ada Lovelace (ops)")).toBe("ada-lovelace-ops");
  });
});
