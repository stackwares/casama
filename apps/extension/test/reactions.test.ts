import { describe, expect, it } from "vitest";
import { chipLabel, mineOf, QUICK_REACTIONS, toggled, withMine } from "../src/lib/reactions.ts";

describe("reactions (D-331)", () => {
  it("offers the app's six quick reactions, in order", () => {
    expect(QUICK_REACTIONS).toEqual(["👍", "❤️", "😂", "😮", "😢", "👎"]);
  });

  it("sets, replaces and takes back your one reaction", () => {
    const start = [{ emoji: "👍", count: 2, mine: false }];
    const liked = withMine(start, "👍");
    expect(liked).toEqual([{ emoji: "👍", count: 3, mine: true }]);
    expect(mineOf(liked)).toBe("👍");
    const swapped = withMine(liked, "😂");
    expect(swapped).toEqual([
      { emoji: "👍", count: 2, mine: false },
      { emoji: "😂", count: 1, mine: true },
    ]);
    expect(withMine(swapped, null)).toEqual([{ emoji: "👍", count: 2, mine: false }]);
  });

  it("drops a chip when your reaction was its only one", () => {
    expect(withMine([{ emoji: "😮", count: 1, mine: true }], null)).toEqual([]);
  });

  it("tapping your own emoji takes it back", () => {
    const groups = [{ emoji: "❤️", count: 1, mine: true }];
    expect(toggled(groups, "❤️")).toBeNull();
    expect(toggled(groups, "👍")).toBe("👍");
  });

  it("labels chips for screen readers", () => {
    expect(chipLabel({ emoji: "👍", count: 2, mine: true })).toBe(
      "👍, 2 reactions, including yours",
    );
    expect(chipLabel({ emoji: "❤️", count: 1, mine: false })).toBe("❤️, 1 reaction");
  });
});
