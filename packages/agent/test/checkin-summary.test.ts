import { describe, expect, it } from "vitest";
import { summaryText, withoutAllSet } from "../src/checkins.ts";

describe("setup scan summary", () => {
  it("sets the count to the suggestions really saved", () => {
    expect(
      summaryText(
        "You're all set. Found 4 things to start on, like lining up tomorrow's flight.",
        3,
      ),
    ).toBe("You're all set. Found 3 things to start on, like lining up tomorrow's flight.");
    expect(summaryText("You're all set. Found two things to start on.", 1)).toBe(
      "You're all set. Found 1 thing to start on.",
    );
  });

  it("falls back to a plain line", () => {
    expect(summaryText("NOTHING_NEW", 2)).toBe("You're all set. Found 2 things to start on.");
    expect(summaryText("anything", 0)).toContain("keep an eye on things");
  });

  it("drops the opening when the chat already said it", () => {
    expect(withoutAllSet("You're all set. Found 3 things to start on, like a ride.")).toBe(
      "Found 3 things to start on, like a ride.",
    );
    expect(withoutAllSet("You’re all set; found 1 thing.")).toBe("Found 1 thing.");
    expect(withoutAllSet("Found 1 thing.")).toBe("Found 1 thing.");
  });
});
