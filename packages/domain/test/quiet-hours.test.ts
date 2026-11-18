import { describe, expect, it } from "vitest";
import { quietUntil } from "../src/quiet-hours.ts";

const q = { enabled: true, start: "22:00", end: "07:00" };

describe("quietUntil", () => {
  it("handles windows across midnight in the person's timezone", () => {
    // 23:30 in Chicago (UTC-6 in November) = 05:30 UTC.
    const end = quietUntil(new Date("2026-11-10T05:30:00Z"), "America/Chicago", q);
    expect(end?.toISOString()).toBe("2026-11-10T13:00:00.000Z");
    // 06:59 local is still quiet; 07:00 isn't.
    expect(quietUntil(new Date("2026-11-10T12:59:00Z"), "America/Chicago", q)).not.toBeNull();
    expect(quietUntil(new Date("2026-11-10T13:00:00Z"), "America/Chicago", q)).toBeNull();
    // Noon is fine.
    expect(quietUntil(new Date("2026-11-10T18:00:00Z"), "America/Chicago", q)).toBeNull();
  });

  it("supports same-day windows and off switches", () => {
    const lunch = { enabled: true, start: "12:00", end: "13:00" };
    expect(quietUntil(new Date("2026-11-10T12:30:00Z"), "UTC", lunch)?.toISOString()).toBe(
      "2026-11-10T13:00:00.000Z",
    );
    expect(
      quietUntil(new Date("2026-11-10T12:30:00Z"), "UTC", { ...lunch, enabled: false }),
    ).toBeNull();
    expect(quietUntil(new Date("2026-11-10T12:30:00Z"), "Not/AZone", lunch)).not.toBeNull();
  });
});
