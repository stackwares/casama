import { describe, expect, it } from "vitest";
import {
  CALL_LIMIT_RANGES,
  callLifeSeconds,
  callLimits,
  checkCallLimits,
  DEFAULT_CALL_LIMITS,
  resolveCallLimits,
  setCallLimits,
} from "../src/call-limits.ts";

describe("call limits (D-426)", () => {
  it("defaults: one minute of quiet, an hour at most, three rings a day, 30 minutes apart", () => {
    expect(resolveCallLimits({})).toEqual(DEFAULT_CALL_LIMITS);
    expect(DEFAULT_CALL_LIMITS).toMatchObject({
      silence_seconds: 60,
      abandoned_seconds: 60,
      max_call_minutes: 60,
      warning_seconds: 60,
      ring_daily_cap: 3,
      ring_cooldown_minutes: 30,
    });
  });

  it("refuses unknown names and values out of range on save", () => {
    const r = checkCallLimits({
      silence_seconds: 5,
      abandoned_seconds: 30,
      nope: 1,
      ring_daily_cap: 2.5,
    });
    expect(r.errors).toEqual([
      "silence_seconds must be a whole number from 20 to 900",
      "abandoned_seconds must be a whole number from 60 to 900",
      expect.stringContaining("unknown limit nope"),
      "ring_daily_cap must be a whole number from 0 to 20",
    ]);
    expect(checkCallLimits({ silence_seconds: 30, ring_daily_cap: 0 })).toEqual({
      limits: { silence_seconds: 30, ring_daily_cap: 0 },
      errors: [],
    });
    expect(checkCallLimits([]).errors).toEqual(["call limits must be an object"]);
  });

  it("keeps loaded values in range and fitting together", () => {
    const l = resolveCallLimits({
      silence_seconds: 1,
      abandoned_seconds: 10_000,
      heartbeat_seconds: 60,
      max_call_minutes: 5,
      warning_seconds: 300,
    });
    expect(l.silence_seconds).toBe(CALL_LIMIT_RANGES.silence_seconds[0]);
    expect(l.abandoned_seconds).toBe(900);
    // A heartbeat at most a third of the wait for one; a warning at most half the call.
    expect(l.heartbeat_seconds).toBe(60);
    expect(resolveCallLimits({ heartbeat_seconds: 60 }).heartbeat_seconds).toBe(20);
    expect(l.warning_seconds).toBe(150);
  });

  it("applies a saved setting in this process, ignoring bad values", () => {
    setCallLimits({ silence_seconds: 30, max_call_minutes: 1 });
    expect(callLimits().silence_seconds).toBe(30);
    expect(callLimits().max_call_minutes).toBe(60);
    expect(callLifeSeconds()).toBe(65 * 60);
    setCallLimits(null);
    expect(callLimits()).toEqual(DEFAULT_CALL_LIMITS);
  });
});
