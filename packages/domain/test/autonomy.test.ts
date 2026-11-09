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
  it("ask_risky: high risk always, medium only after untrusted input", () => {
    expect(needsApproval({ ...base, risk: "high" })).toBe(true);
    expect(needsApproval({ ...base, risk: "medium" })).toBe(false);
    expect(needsApproval({ ...base, risk: "medium", untrustedSinceApproval: true })).toBe(true);
    expect(needsApproval({ ...base, risk: "low", untrustedSinceApproval: true })).toBe(false);
    expect(needsApproval({ ...base, risk: "medium", confirmUnderDefault: true })).toBe(true);
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
  it("ships five starter templates with valid schedules", () => {
    expect(BOT_TEMPLATES).toHaveLength(5);
    for (const t of BOT_TEMPLATES)
      for (const r of t.routines ?? []) expect(isValidCron(r.schedule_cron)).toBe(true);
  });
});
