import { describe, expect, it } from "vitest";
import {
  isReactionEmoji,
  normalizeReaction,
  QUICK_REACTIONS,
  reactionSentiment,
  summarizeReactions,
} from "../src/reactions.ts";

describe("normalizeReaction", () => {
  it("keeps every quick reaction as is", () => {
    for (const e of QUICK_REACTIONS) expect(normalizeReaction(e)).toBe(e);
  });

  it("takes skin tones, ZWJ sequences, flags and keycaps", () => {
    for (const e of ["👍🏽", "👩‍👩‍👧‍👦", "🏳️‍🌈", "🇵🇭", "1️⃣", "#️⃣", "🏴󠁧󠁢󠁳󠁣󠁴󠁿", "🫠"])
      expect(normalizeReaction(e)).toBe(e);
  });

  it("gives a text-style pictograph its emoji form", () => {
    expect(normalizeReaction("❤")).toBe("❤️");
    expect(normalizeReaction(" ❤️ ")).toBe("❤️");
  });

  it("refuses text, several emoji, and bare digits", () => {
    for (const s of ["", " ", "lol", "ok👍", "👍👍", "1", "#", "❤️ ❤️", "<3", "a⃣"])
      expect(isReactionEmoji(s)).toBe(false);
  });

  it("refuses very long sequences", () => {
    expect(isReactionEmoji("👍".repeat(20))).toBe(false);
  });
});

describe("reactionSentiment", () => {
  it("reads likes and complaints, whatever the skin tone", () => {
    expect(reactionSentiment("👍")).toBe("positive");
    expect(reactionSentiment("👍🏿")).toBe("positive");
    expect(reactionSentiment("❤")).toBe("positive");
    expect(reactionSentiment("👎")).toBe("negative");
    expect(reactionSentiment("😡")).toBe("negative");
    expect(reactionSentiment("😢")).toBe("negative");
    expect(reactionSentiment("😮")).toBeNull();
    expect(reactionSentiment("🦄")).toBeNull();
  });
});

describe("summarizeReactions", () => {
  it("groups by emoji, most first, and marks yours", () => {
    const out = summarizeReactions(
      [
        { emoji: "😂", user_id: "u1", bot_id: null },
        { emoji: "❤️", user_id: "u2", bot_id: null },
        { emoji: "❤️", user_id: null, bot_id: "b1" },
      ],
      "u1",
    );
    expect(out).toEqual([
      { emoji: "❤️", count: 2, mine: false, users: ["u2"], bots: ["b1"] },
      { emoji: "😂", count: 1, mine: true, users: ["u1"], bots: [] },
    ]);
  });
});
