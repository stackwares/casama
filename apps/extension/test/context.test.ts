import { describe, expect, it } from "vitest";
import { clock, contextBlock, messageText, SELECTION_CAP, sentRecord } from "../src/lib/context.ts";

const ctx = {
  url: "https://news.example.com/a",
  title: "Rates rise",
  selection: "The bank raised rates.",
  text: "Full article text.",
  textKind: "page" as const,
};

describe("the context block (D-152, extended)", () => {
  it("keeps only the chips that are on, in the quick-ask format", () => {
    expect(contextBlock(ctx, { page: true, selection: true })).toBe(
      "Browser tab: Rates rise (https://news.example.com/a)\n\nSelected text:\nThe bank raised rates.",
    );
    expect(contextBlock(ctx, { text: true })).toBe("Page text:\nFull article text.");
    expect(contextBlock(ctx, {})).toBe("");
    expect(messageText("  What changed?  ", ctx, { page: true })).toBe(
      "What changed?\n\nBrowser tab: Rates rise (https://news.example.com/a)",
    );
  });

  it("cuts a selection at 8,000 characters and names PDFs and transcripts", () => {
    const long = "x".repeat(SELECTION_CAP + 50);
    expect(contextBlock({ selection: long }, { selection: true })).toHaveLength(
      "Selected text:\n".length + SELECTION_CAP + 1,
    );
    expect(contextBlock({ text: "p", textKind: "pdf" }, { text: true })).toBe("PDF text:\np");
    expect(
      contextBlock(
        {
          url: "https://youtube.com/watch?v=1",
          text: "[0:01] hi",
          textKind: "transcript",
          videoTime: 75,
        },
        { page: true, text: true },
      ),
    ).toBe(
      "Browser tab: (https://youtube.com/watch?v=1)\n\nVideo position: 1:15\n\nVideo transcript:\n[0:01] hi",
    );
  });

  it("records what was sent without the content itself", () => {
    const r = sentRecord(ctx, { page: true, text: true }, "abc", ["Screenshot"]);
    expect(r.parts).toEqual(["Page address and title", "Page text", "Screenshot"]);
    expect(r.url).toBe(ctx.url);
    expect(r.chars).toBe(3);
    expect(sentRecord(ctx, {}, "", []).url).toBeUndefined();
  });

  it("writes clock times", () => {
    expect(clock(5)).toBe("0:05");
    expect(clock(3725)).toBe("1:02:05");
  });

  it("sends nothing from a blocked page, even with every chip on", () => {
    const ctx = {
      url: "https://app.casama.ai/x",
      title: "Inbox",
      selection: "secret",
      blocked: "Casama's own pages can't be read or sent to a bot.",
    };
    const all = { page: true, selection: true, text: true, screenshot: true };
    expect(contextBlock(ctx, all)).toBe("");
    expect(messageText("hi", ctx, all)).toBe("hi");
    const r = sentRecord(ctx, all, "hi", []);
    expect(r.parts).toEqual([]);
    expect(r.url).toBeUndefined();
  });
});
