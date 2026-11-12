import { describe, expect, it } from "vitest";
import {
  BOT_TEMPLATES,
  isValidCron,
  isValidTimezone,
  needsApproval,
  nextRunAt,
  subagentBudget,
} from "../src/index.ts";

const base = {
  autonomy: "ask_risky" as const,
  risk: "low" as const,
  readOnly: false,
  untrustedSinceApproval: false,
  granted: false,
};

describe("needsApproval", () => {
  it("ask_risky: high risk always, medium only when it sends data out after untrusted input (D-213)", () => {
    expect(needsApproval({ ...base, risk: "high" })).toBe(true);
    expect(needsApproval({ ...base, risk: "medium" })).toBe(false);
    expect(needsApproval({ ...base, risk: "medium", untrustedSinceApproval: true })).toBe(false);
    expect(needsApproval({ ...base, risk: "medium", sendsOut: true })).toBe(false);
    expect(
      needsApproval({ ...base, risk: "medium", untrustedSinceApproval: true, sendsOut: true }),
    ).toBe(true);
    expect(
      needsApproval({ ...base, risk: "low", untrustedSinceApproval: true, sendsOut: true }),
    ).toBe(false);
    expect(needsApproval({ ...base, risk: "medium", confirmUnderDefault: true })).toBe(true);
  });
  it("self-only tools (the bot's own notes, schedule, tasks, messages to the person) never ask (D-155)", () => {
    for (const autonomy of ["ask_always", "ask_risky", "autonomous"] as const)
      expect(
        needsApproval({
          ...base,
          autonomy,
          risk: "medium",
          selfOnly: true,
          untrustedSinceApproval: true,
        }),
      ).toBe(false);
  });
  it("ask_always asks for anything with side effects; read-only never asks", () => {
    expect(needsApproval({ ...base, autonomy: "ask_always" })).toBe(true);
    expect(needsApproval({ ...base, autonomy: "ask_always", readOnly: true })).toBe(false);
  });
  it("autonomous only asks when the provider forces it; grants skip asking", () => {
    expect(needsApproval({ ...base, autonomy: "autonomous", risk: "high" })).toBe(false);
    expect(
      needsApproval({ ...base, autonomy: "autonomous", risk: "high", forceHighRisk: true }),
    ).toBe(true);
    expect(needsApproval({ ...base, risk: "high", granted: true })).toBe(false);
    expect(needsApproval({ ...base, risk: "high", granted: true, forceHighRisk: true })).toBe(true);
  });
});

describe("schedules", () => {
  it("validates cron and timezones", () => {
    expect(isValidCron("0 8 * * *")).toBe(true);
    expect(isValidCron("0 8 * *")).toBe(false);
    expect(isValidCron("99 8 * * *")).toBe(false);
    expect(isValidTimezone("America/Chicago")).toBe(true);
    expect(isValidTimezone("Mars/Base")).toBe(false);
  });
  it("computes 08:00 in the owner's timezone, across daylight saving changes", () => {
    // 2026-03-08 is the US spring-forward day: 08:00 CDT = 13:00 UTC; the day before 08:00 CST = 14:00 UTC.
    expect(
      nextRunAt("0 8 * * *", "America/Chicago", new Date("2026-03-07T00:00:00Z")).toISOString(),
    ).toBe("2026-03-07T14:00:00.000Z");
    expect(
      nextRunAt("0 8 * * *", "America/Chicago", new Date("2026-03-07T15:00:00Z")).toISOString(),
    ).toBe("2026-03-08T13:00:00.000Z");
    expect(nextRunAt("0 8 * * *", "UTC", new Date("2026-03-07T08:00:00Z")).toISOString()).toBe(
      "2026-03-08T08:00:00.000Z",
    );
  });
});

describe("delegation and templates", () => {
  it("gives subagents 20% of the parent's remaining budget", () => {
    expect(subagentBudget(1, 0.5)).toBe(0.1);
    expect(subagentBudget(1, 1)).toBe(0.01);
    expect(subagentBudget(null, 0)).toBe(0.5);
  });
  it("ships starter personas with unique ids, real instructions and valid schedules", () => {
    expect(BOT_TEMPLATES.length).toBeGreaterThanOrEqual(20);
    expect(new Set(BOT_TEMPLATES.map((t) => t.id)).size).toBe(BOT_TEMPLATES.length);
    const mascots = [
      "winky",
      "sleepy",
      "starry",
      "lovey",
      "cool",
      "thinker",
      "giggly",
      "shy",
      "focused",
      "wow",
    ];
    for (const t of BOT_TEMPLATES) {
      expect(t.persona.length).toBeGreaterThan(200);
      expect(t.starters.length).toBeGreaterThanOrEqual(2);
      expect(mascots).toContain(t.mascot);
      for (const r of t.routines ?? []) expect(isValidCron(r.schedule_cron)).toBe(true);
    }
  });
});
