/**
 * Price watches (docs/FLIGHT-SEARCH-PLAN.md §9): when a watch ends, when a new price is worth a
 * push, and the push's words. The database side is in apps/server/test/fare-watches.test.ts.
 */
import { describe, expect, it } from "vitest";
import {
  cheapestFare,
  nextCheck,
  shouldPush,
  WATCH_EVERY_HOURS,
  watchEnds,
  watchPushText,
  watchRoute,
} from "../src/live-data/watches.ts";

const now = new Date("2026-11-21T08:00:00Z");
const HOUR = 3_600_000;

describe("watch rules", () => {
  it("ends after the departure day, the departure month, or 60 days", () => {
    expect(watchEnds("2026-12-05", now).toISOString()).toBe("2026-12-05T23:59:59.000Z");
    expect(watchEnds("2026-12", now).toISOString()).toBe("2026-12-31T23:59:59.000Z");
    expect(watchEnds("2027-06-01", now).toISOString()).toBe("2027-01-20T08:00:00.000Z");
    expect(watchEnds(undefined, now).valueOf()).toBe(now.valueOf() + 60 * 24 * HOUR);
  });

  it("checks again in about six hours, spread over an hour", () => {
    expect(nextCheck(now, () => 0.5).valueOf()).toBe(now.valueOf() + WATCH_EVERY_HOURS * HOUR);
    expect(nextCheck(now, () => 0).valueOf()).toBe(now.valueOf() + 5.5 * HOUR);
    expect(nextCheck(now, () => 1).valueOf()).toBe(now.valueOf() + 6.5 * HOUR);
  });

  it("pushes at the target, lower than the last push, once a day", () => {
    const w = { below: 9000, first_price: 10_200, pushed_price: null, pushed_at: null };
    expect(shouldPush(w, 9500, now)).toBe(false);
    // A 10% drop is news even above the target.
    expect(shouldPush(w, 9100, now)).toBe(true);
    expect(shouldPush(w, 9000, now)).toBe(true);
    const pushed = {
      ...w,
      pushed_price: 8900,
      pushed_at: new Date(now.valueOf() - 2 * HOUR).toISOString(),
    };
    expect(shouldPush(pushed, 8000, now)).toBe(false);
    const yesterday = { ...pushed, pushed_at: new Date(now.valueOf() - 25 * HOUR).toISOString() };
    expect(shouldPush(yesterday, 8000, now)).toBe(true);
    expect(shouldPush(yesterday, 8900, now)).toBe(false);
  });

  it("without a target, pushes on a 10% drop from the first price or the last push", () => {
    const w = { below: null, first_price: 10_000, pushed_price: null, pushed_at: null };
    expect(shouldPush(w, 9100, now)).toBe(false);
    expect(shouldPush(w, 9000, now)).toBe(true);
    const old = new Date(now.valueOf() - 30 * HOUR).toISOString();
    expect(shouldPush({ ...w, pushed_price: 9000, pushed_at: old }, 8200, now)).toBe(false);
    expect(shouldPush({ ...w, pushed_price: 9000, pushed_at: old }, 8100, now)).toBe(true);
    expect(shouldPush({ ...w, first_price: null }, 1, now)).toBe(false);
  });

  it("names the route and the drop", () => {
    const card = {
      from: { label: "Manila" },
      to: { label: "Tokyo" },
      depart: "2027-03-12",
      return: "2027-03-19",
      cheapest: 8940,
      options: [{}],
    };
    const route = watchRoute(card);
    expect(route).toBe("Manila → Tokyo · Mar 12–Mar 19");
    expect(cheapestFare(card)).toBe(8940);
    expect(cheapestFare({ ...card, options: [] })).toBeNull();
    const t = watchPushText({ route, currency: "PHP" }, 8940, 10_200);
    expect(t.title).toBe("Fare drop: Manila → Tokyo");
    expect(t.body).toMatch(/is now .*8,940.*\(was .*10,200\)/);
  });
});
