import { describe, expect, it } from "vitest";
import {
  CALL_CONTEXT_TOKENS,
  CALL_CONTEXT_TURN_CHARS,
  CALL_CONTEXT_TURNS,
  earlierInConversation,
} from "../src/voice.ts";

describe("a new call hears the conversation's last turns (D-327)", () => {
  it("lists them oldest first, as the user and the bot", () => {
    const text = earlierInConversation(
      [
        { role: "user", text: "Book the dentist" },
        { role: "assistant", text: "Booked for  Tuesday\nat 10." },
      ],
      "Ava",
    );
    expect(text.split("\n")).toEqual([
      expect.stringContaining("Earlier in this conversation"),
      "User: Book the dentist",
      "Ava: Booked for Tuesday at 10.",
    ]);
  });

  it("is empty when there's nothing to carry over", () => {
    expect(earlierInConversation([], "Ava")).toBe("");
    expect(earlierInConversation([{ role: "user", text: "   " }], "Ava")).toBe("");
  });

  it("keeps the newest turns within the turn count and the token budget", () => {
    const turns = Array.from({ length: 40 }, (_, i) => ({
      role: (i % 2 ? "assistant" : "user") as "user" | "assistant",
      text: `turn ${i} ${"x".repeat(500)}`,
    }));
    const text = earlierInConversation(turns, "Ava");
    const lines = text.split("\n").slice(1);
    expect(lines.length).toBeLessThanOrEqual(CALL_CONTEXT_TURNS);
    // 600 tokens, about 2,400 characters, plus the heading: every turn of the call pays for them.
    expect(CALL_CONTEXT_TOKENS).toBe(600);
    expect(text.length).toBeLessThanOrEqual(CALL_CONTEXT_TOKENS * 4 + 200);
    expect(lines.at(-1)).toContain("turn 39");
    expect(text).not.toContain("turn 0 ");
    // Long turns are cut to their start, so the budget still holds several of them.
    expect(lines.length).toBeGreaterThanOrEqual(6);
    for (const line of lines) expect(line.length).toBeLessThanOrEqual(CALL_CONTEXT_TURN_CHARS + 10);
  });

  it("keeps more turns when they're short", () => {
    const turns = Array.from({ length: 30 }, (_, i) => ({
      role: (i % 2 ? "assistant" : "user") as "user" | "assistant",
      text: `short turn ${i}`,
    }));
    expect(earlierInConversation(turns, "Ava").split("\n").slice(1)).toHaveLength(
      CALL_CONTEXT_TURNS,
    );
  });

  it("shortens one very long turn instead of dropping everything", () => {
    const text = earlierInConversation([{ role: "assistant", text: "y".repeat(5000) }], "Ava");
    expect(text).toContain("…");
    expect(text.length).toBeLessThan(500);
  });
});
