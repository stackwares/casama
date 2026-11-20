import { describe, expect, it } from "vitest";
import { checkBudget, computerHoursMessage } from "../src/index.ts";

describe("checkBudget", () => {
  const base = { runCost: 0, botToday: 0, orgPeriod: 0 };
  it("passes with no limits", () => expect(checkBudget(base)).toEqual({ ok: true }));
  it("checks quota, then daily, then per-run", () => {
    expect(
      checkBudget({ ...base, orgPeriod: 50, quotaLimit: 50, runCost: 9, perRunLimit: 1 }),
    ).toMatchObject({
      code: "quota_exceeded",
    });
    expect(checkBudget({ ...base, botToday: 10, dailyLimit: 10 })).toMatchObject({
      code: "daily_budget_exceeded",
    });
    expect(checkBudget({ ...base, runCost: 1.01, perRunLimit: 1 })).toMatchObject({
      code: "budget_exceeded",
    });
    expect(checkBudget({ ...base, runCost: 0.5, perRunLimit: 1 })).toEqual({ ok: true });
  });

  it("credit-gated plans stop at zero credits; no gate means no check (self-hosted)", () => {
    expect(checkBudget({ ...base, credits: 0 })).toMatchObject({
      ok: false,
      code: "out_of_credits",
    });
    expect(checkBudget({ ...base, credits: -0.2 })).toMatchObject({
      ok: false,
      code: "out_of_credits",
    });
    expect(checkBudget({ ...base, credits: 0.01 })).toEqual({ ok: true });
    expect(checkBudget({ ...base, credits: null })).toEqual({ ok: true });
    expect(checkBudget({ ...base, credits: 1, unbilledUsd: 1 })).toMatchObject({
      code: "out_of_credits",
    });
    expect(checkBudget({ ...base, credits: 0.02, reserveUsd: 0.05 })).toMatchObject({
      code: "out_of_credits",
    });
    expect(checkBudget({ ...base, credits: 1, unbilledUsd: 0.2, reserveUsd: 0.05 })).toEqual({
      ok: true,
    });
  });

  it("stops Casama's key at the workspace's daily cap", () => {
    expect(checkBudget({ ...base, cloudToday: 0.25, cloudDailyCap: 0.25 })).toMatchObject({
      code: "cloud_daily_cap",
      message: expect.stringContaining("today's $0.25 limit"),
    });
    expect(checkBudget({ ...base, cloudToday: 12, cloudDailyCap: 10 })).toMatchObject({
      message: expect.stringContaining("today's $10 limit"),
    });
    expect(checkBudget({ ...base, cloudToday: 0.1, cloudDailyCap: 0.25 })).toEqual({ ok: true });
    expect(checkBudget({ ...base, cloudToday: 100, cloudDailyCap: null })).toEqual({ ok: true });
  });

  it("computer hours never stop a run, only the computer (D-442)", () => {
    expect(checkBudget({ ...base, credits: 5 })).toEqual({ ok: true });
    expect(computerHoursMessage(5, new Date("2026-11-20T10:00:00Z"))).toBe(
      "The workspace used its 5 computer hours for this month, so its computer can't start. They reset on December 1. Upgrade in Billing for more hours.",
    );
    expect(computerHoursMessage(null, new Date("2026-12-31T23:00:00Z"))).toContain(
      "used its computer hours for this month, so its computer can't start. They reset on January 1.",
    );
  });
});
