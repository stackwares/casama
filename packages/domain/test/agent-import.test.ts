import { describe, expect, it } from "vitest";
import { AgentImportError, cronFromText, detectAgentKind, parseMemoryExport, planAgentImport, splitNote } from "../src/agent-import.ts";

const folder = (o: Record<string, string>) => new Map(Object.entries(o).map(([k, v]) => [k, new TextEncoder().encode(v)]));

describe("import an agent", () => {
  it("maps an OpenClaw home folder (workspace and cron jobs)", () => {
    const plan = planAgentImport(
      folder({
        ".openclaw/workspace/SOUL.md": "You are Juno, calm and direct.",
        ".openclaw/workspace/AGENTS.md": "Check memory before answering.",
        ".openclaw/workspace/IDENTITY.md": "- **Name:** Juno\n- **Emoji:** 🦉",
        ".openclaw/workspace/USER.md": "# About Oliver\n- Prefers short answers\n- Works in Cebu time",
        ".openclaw/workspace/MEMORY.md": "- The NAS is at 10.0.0.5\n\nThe car is due for service in March.",
        ".openclaw/workspace/memory/2026-11-01.md": "Talked about the trip.",
        ".openclaw/workspace/memory/2026-11-02.md": "Booked flights.",
        ".openclaw/workspace/skills/Weekly Report/SKILL.md": "---\nname: Weekly Report\ndescription: Write the weekly report\n---\nSteps here.",
        ".openclaw/workspace/skills/Weekly Report/template.md": "# Week",
        ".openclaw/workspace/canvas/index.html": "<p>hi</p>",
        ".openclaw/workspace/HEARTBEAT.md": "- check mail",
        ".openclaw/openclaw.json": '{"apiKey":"sk-secret"}',
        ".openclaw/credentials/telegram.json": "{}",
        ".openclaw/state/openclaw.sqlite": "x",
        ".openclaw/cron/jobs.json": JSON.stringify({
          version: 1,
          jobs: [
            { jobId: "a", name: "Morning brief", enabled: true, schedule: { kind: "cron", expr: "0 7 * * *", tz: "Asia/Manila" }, payload: { kind: "agentTurn", message: "Send my brief" } },
            { jobId: "b", name: "Hourly check", schedule: { kind: "every", everyMs: 3_600_000 }, payload: { kind: "systemEvent", text: "Check inbox" } },
            { jobId: "c", name: "Reminder", schedule: { kind: "at", atMs: 1 }, payload: { kind: "systemEvent", text: "Call mom" } },
            { jobId: "d", name: "Old", enabled: false, schedule: { kind: "cron", expr: "0 9 * * 1" }, payload: { kind: "agentTurn", message: "x" } },
          ],
        }),
      }),
    );
    expect(plan.kind).toBe("openclaw");
    expect(plan.name).toBe("Juno");
    expect(plan.persona_md).toContain("calm and direct");
    expect(plan.persona_md).toContain("Check memory before answering.");
    expect(plan.memories.filter((m) => m.kind === "preference").map((m) => m.content)).toEqual(["Prefers short answers", "Works in Cebu time"]);
    expect(plan.memories.filter((m) => m.kind === "fact")).toHaveLength(2);
    expect(plan.memories.filter((m) => m.kind === "episode").map((m) => m.content)[0]).toContain("2026-11-02");
    expect(plan.skills).toHaveLength(1);
    expect(plan.skills[0]).toMatchObject({ name: "weekly-report", description: "Write the weekly report" });
    expect(plan.skills[0]?.files.map((f) => f.path)).toEqual(["template.md"]);
    expect(plan.routines.map((r) => [r.name, r.schedule_cron])).toEqual([["Morning brief", "0 7 * * *"], ["Hourly check", "0 * * * *"]]);
    expect(plan.notes.join("\n")).toMatch(/Reminder.*once/);
    expect(plan.notes.join("\n")).toMatch(/Old.*paused/);
    expect(plan.leftovers).toEqual(["workspace/HEARTBEAT.md", "workspace/canvas/index.html"]);
    expect(plan.skipped.map((s) => s.path).sort()).toEqual(["credentials/telegram.json", "openclaw.json", "state/openclaw.sqlite"]);
  });

  it("maps a Hermes Agent home folder", () => {
    const files = folder({
      "hermes/SOUL.md": "You are Hermes, a meticulous assistant.",
      "hermes/config.yaml": "model: x",
      "hermes/.env": "OPENAI_API_KEY=sk",
      "hermes/memories/MEMORY.md": "Repo uses pnpm\n§\nDeploys go through CI §  Tests need Docker",
      "hermes/memories/USER.md": "Likes bullet points § Lives in Cebu",
      "hermes/skills/devops/deploy-check/SKILL.md": "---\nname: deploy-check\ndescription: Check a deploy\n---\nRun the checks.",
      "hermes/cron/jobs.json": JSON.stringify([
        { id: "1", name: "Daily digest", prompt: "Summarize my feeds", schedule: { kind: "cron", expr: "0 8 * * *", display: "0 8 * * *" }, enabled: true },
        { id: "2", name: "Every two hours", prompt: "Check builds", schedule: { kind: "interval", display: "every 2h" } },
        { id: "3", name: "Done", prompt: "x", schedule: { kind: "once", display: "in 30m" }, state: "completed" },
      ]),
      "hermes/cron/output/1/2026.md": "old run",
      "hermes/notes/ideas.md": "ideas",
    });
    expect(detectAgentKind(files)?.kind).toBe("hermes");
    const plan = planAgentImport(files);
    expect(plan.persona_md).toBe("You are Hermes, a meticulous assistant.");
    expect(plan.memories.map((m) => `${m.kind}:${m.content}`)).toEqual([
      "fact:Repo uses pnpm",
      "fact:Deploys go through CI",
      "fact:Tests need Docker",
      "preference:Likes bullet points",
      "preference:Lives in Cebu",
    ]);
    expect(plan.skills.map((s) => s.name)).toEqual(["deploy-check"]);
    expect(plan.routines.map((r) => r.schedule_cron)).toEqual(["0 8 * * *", "0 */2 * * *"]);
    expect(plan.leftovers).toEqual(["notes/ideas.md"]);
    expect(plan.skipped.map((s) => s.path).sort()).toEqual([".env", "config.yaml", "cron/output/1/2026.md"]);
  });

  it("rejects unknown folders and reads schedules and notes", () => {
    expect(() => planAgentImport(folder({ "README.md": "hi" }))).toThrow(AgentImportError);
    expect(cronFromText("daily at 7pm")).toBe("0 19 * * *");
    expect(cronFromText("every 15m")).toBe("*/15 * * * *");
    expect(cronFromText("every 7m")).toBeNull();
    expect(splitNote("# H\n- a item\n- b item\n\npara one\nline two")).toEqual(["a item", "b item", "para one\nline two"]);
  });

  it("parses memories pasted back from ChatGPT or Claude", () => {
    const got = parseMemoryExport("Here's what I remember:\nFACT: Works at Acme\n- PREFERENCE: Short answers\n**Fact:** Has two cats\nLikes hiking\nFACT: Works at Acme\n```");
    expect(got).toEqual([
      { kind: "fact", content: "Works at Acme" },
      { kind: "preference", content: "Short answers" },
      { kind: "fact", content: "Has two cats" },
      { kind: "fact", content: "Likes hiking" },
    ]);
  });
});
