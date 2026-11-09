import { describe, expect, it } from "vitest";
import { checkBudget } from "../src/index.ts";

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
  });

  it("monthly computer hours from the plan", () => {
    expect(checkBudget({ ...base, computerSeconds: 5 * 3600, computerHours: 5 })).toMatchObject({
      ok: false,
      code: "computer_hours_exceeded",
    });
    expect(checkBudget({ ...base, computerSeconds: 3600, computerHours: 5 })).toEqual({ ok: true });
    expect(checkBudget({ ...base, computerSeconds: 1e9 })).toEqual({ ok: true });
  });
});
