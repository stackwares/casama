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
});
