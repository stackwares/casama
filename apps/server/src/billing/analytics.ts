/**
 * What a subscription snapshot means for product analytics (D-208, ANALYTICS-PLAN §6.8): classifies a
 * change between what we stored and what the provider now reports. Pure, so it is easy to test.
 */
import { ENTITLED, type SubscriptionStatus } from "./types.ts";

export interface SubState {
  status: SubscriptionStatus;
  plan_code: string;
  period_end: Date | null;
}

export type SubscriptionChange =
  | "started"
  | "trial_started"
  | "trial_converted"
  | "renewed"
  | "recovered"
  | "grace"
  | "cancelled"
  | "expired"
  | "refunded"
  | "plan_changed";

const TROUBLED: SubscriptionStatus[] = ["past_due", "grace", "on_hold", "paused"];

/** Null when nothing worth an event happened (the same snapshot seen again, a restore, a re-fetch). */
export function subscriptionChange(
  old: SubState | undefined,
  next: SubState,
): SubscriptionChange | null {
  if (!old) {
    if (next.status === "trialing") return "trial_started";
    return ENTITLED.includes(next.status) ? "started" : null;
  }
  if (old.status !== next.status) {
    if (next.status === "refunded") return "refunded";
    if (next.status === "cancelled") return "cancelled";
    if (next.status === "expired") return "expired";
    if (old.status === "trialing" && next.status === "active") return "trial_converted";
    if (TROUBLED.includes(old.status) && next.status === "active") return "recovered";
    if (next.status === "grace" || next.status === "past_due") return "grace";
    return null;
  }
  if (old.plan_code !== next.plan_code) return "plan_changed";
  const advanced =
    old.period_end && next.period_end && next.period_end.getTime() > old.period_end.getTime();
  return advanced && next.status === "active" ? "renewed" : null;
}

/** The changes that mean money arrived (a trial start does not). */
export const PAID_CHANGES: SubscriptionChange[] = ["started", "trial_converted", "renewed"];
