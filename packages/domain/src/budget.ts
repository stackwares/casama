export interface BudgetState {
  /** Cost of this run so far. */
  runCost: number;
  /** Per-run cap from the run or bot budget. */
  perRunLimit?: number | null;
  /** This bot's cost today (UTC). */
  botToday: number;
  dailyLimit?: number | null;
  /** The org's cost in the current quota period. */
  orgPeriod: number;
  quotaLimit?: number | null;
}

export type BudgetVerdict =
  | { ok: true }
  | {
      ok: false;
      code: "budget_exceeded" | "daily_budget_exceeded" | "quota_exceeded";
      message: string;
    };

const over = (spent: number, limit?: number | null) =>
  limit != null && limit >= 0 && spent >= limit;

/** Checked at run start and after every model step. */
export function checkBudget(s: BudgetState): BudgetVerdict {
  if (over(s.orgPeriod, s.quotaLimit))
    return {
      ok: false,
      code: "quota_exceeded",
      message: `The organization reached its cost quota of $${s.quotaLimit}.`,
    };
  if (over(s.botToday, s.dailyLimit))
    return {
      ok: false,
      code: "daily_budget_exceeded",
      message: `This bot reached its daily budget of $${s.dailyLimit}.`,
    };
  if (over(s.runCost, s.perRunLimit))
    return {
      ok: false,
      code: "budget_exceeded",
      message: `This run reached its budget of $${s.perRunLimit}.`,
    };
  return { ok: true };
}

export const RUN_DEFAULTS = { maxSteps: 40, wallTimeMs: 30 * 60_000 } as const;
