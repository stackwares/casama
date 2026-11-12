import { expect, it } from "vitest";
import { PAID_CHANGES, type SubState, subscriptionChange } from "../src/billing/analytics.ts";

const at = (d: string) => new Date(`${d}T00:00:00Z`);
const s = (status: SubState["status"], plan = "pro", end = "2027-03-01"): SubState => ({
  status,
  plan_code: plan,
  period_end: at(end),
});

it("classifies subscription changes, and stays quiet when nothing changed", () => {
  expect(subscriptionChange(undefined, s("active"))).toBe("started");
  expect(subscriptionChange(undefined, s("trialing"))).toBe("trial_started");
  expect(subscriptionChange(undefined, s("pending"))).toBeNull();
  expect(subscriptionChange(s("trialing"), s("active"))).toBe("trial_converted");
  expect(
    subscriptionChange(s("active", "pro", "2027-03-01"), s("active", "pro", "2027-04-01")),
  ).toBe("renewed");
  expect(subscriptionChange(s("past_due"), s("active"))).toBe("recovered");
  expect(subscriptionChange(s("active"), s("grace"))).toBe("grace");
  expect(subscriptionChange(s("active"), s("cancelled"))).toBe("cancelled");
  expect(subscriptionChange(s("active"), s("expired"))).toBe("expired");
  expect(subscriptionChange(s("active"), s("refunded"))).toBe("refunded");
  expect(subscriptionChange(s("active", "pro"), s("active", "pro_yearly"))).toBe("plan_changed");
  // The same snapshot again (a webhook retry, Restore Purchases, an app launch) is not an event.
  expect(subscriptionChange(s("active"), s("active"))).toBeNull();
  expect(
    subscriptionChange(s("active", "pro", "2027-04-01"), s("active", "pro", "2027-03-01")),
  ).toBeNull();
});

it("only starts, trial conversions and renewals mean money arrived", () => {
  expect(PAID_CHANGES).toEqual(["started", "trial_converted", "renewed"]);
});
