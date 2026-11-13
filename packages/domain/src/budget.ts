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
  /** Prepaid credit balance when the plan is credit-gated (Casama Cloud, D-070); null = no gate. */
  credits?: number | null;
  /** Billable usage not yet turned into a credit deduction (settlement runs once a minute). */
  unbilledUsd?: number;
  /** Credits this call must still have left before it starts (a worst-case estimate). */
  reserveUsd?: number;
  /** What this workspace has been charged today for Casama's model key, and that day's cap. */
  cloudToday?: number;
  cloudDailyCap?: number | null;
  /** Computer-seconds this month and the plan's monthly computer hours. */
  computerSeconds?: number;
  computerHours?: number | null;
}

export type BudgetVerdict =
  | { ok: true }
  | {
      ok: false;
      code:
        | "budget_exceeded"
        | "daily_budget_exceeded"
        | "quota_exceeded"
        | "out_of_credits"
        | "cloud_daily_cap"
        | "cloud_model_not_allowed"
        | "computer_hours_exceeded"
        | "plan_limit";
      message: string;
    };

const over = (spent: number, limit?: number | null) =>
  limit != null && limit >= 0 && spent >= limit;

/** Checked at run start and after every model step. */
export function checkBudget(s: BudgetState): BudgetVerdict {
  if (over(s.cloudToday ?? 0, s.cloudDailyCap))
    return {
      ok: false,
      code: "cloud_daily_cap",
      message:
        "This workspace reached its daily limit on Casama's models. It resets at midnight UTC, or add your own key.",
    };
  if (s.credits != null) {
    const left = s.credits - (s.unbilledUsd ?? 0);
    if (left <= 0 || (s.reserveUsd != null && left < s.reserveUsd))
      return {
        ok: false,
        code: "out_of_credits",
        message: "The workspace is out of credits. Add credits or change plans in Billing.",
      };
  }
  if (over((s.computerSeconds ?? 0) / 3600, s.computerHours))
    return {
      ok: false,
      code: "computer_hours_exceeded",
      message: `The workspace used its ${s.computerHours} computer hours for this month.`,
    };
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
