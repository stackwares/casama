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

/** $0.25, $10: cents only when there are any. */
const usd = (n: number) => `$${Number.isInteger(n) ? n : n.toFixed(2)}`;

/**
 * Why a hosted computer won't start: the month's computer hours are used. Only computers stop;
 * chat, apps and models keep running on credits. Names the reset day (UTC) and the way out.
 */
export function computerHoursMessage(hours?: number | null, now = new Date()): string {
  const reset = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + 1, 1));
  const day = reset.toLocaleDateString("en-US", { month: "long", day: "numeric", timeZone: "UTC" });
  const used = hours != null ? `its ${hours} computer hours` : "its computer hours";
  return `The workspace used ${used} for this month, so its computer can't start. They reset on ${day}. Upgrade in Billing for more hours.`;
}

/** Checked at run start and after every model step. */
export function checkBudget(s: BudgetState): BudgetVerdict {
  if (over(s.cloudToday ?? 0, s.cloudDailyCap))
    return {
      ok: false,
      code: "cloud_daily_cap",
      // Names the amount: the app's credit meter shows the month's credits, so a bare "limit
      // reached" next to credits left reads as a bug (D-311).
      message: `This workspace used today's ${usd(s.cloudDailyCap ?? 0)} limit on Casama's models. It resets at midnight UTC. Upgrade in Billing for a higher daily limit.`,
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
