import { describe, expect, it } from "vitest";
import { looksLikePdf } from "../src/lib/pdf.ts";
import { isYouTubeVideo, transcriptText } from "../src/lib/youtube.ts";

describe("video transcripts (A6)", () => {
  it("knows a video page", () => {
    expect(isYouTubeVideo("https://www.youtube.com/watch?v=abc")).toBe(true);
    expect(isYouTubeVideo("https://m.youtube.com/shorts/abc")).toBe(true);
    expect(isYouTubeVideo("https://www.youtube.com/feed")).toBe(false);
    expect(isYouTubeVideo("https://youtube.com.evil.test/watch")).toBe(false);
  });

  it("merges caption events into timed sentences", () => {
    const text = transcriptText([
      { tStartMs: 0, segs: [{ utf8: "Hello" }, { utf8: " there" }] },
      { tStartMs: 1500, segs: [{ utf8: "everyone." }] },
      { tStartMs: 2000, segs: [{ utf8: "\n" }] },
      { tStartMs: 65_000, segs: [{ utf8: "Interest rates" }] },
      { tStartMs: 90_000, segs: [{ utf8: "went up." }] },
    ]);
    expect(text).toBe("[0:00] Hello there everyone.\n[1:05] Interest rates went up.");
  });
});

describe("PDFs (A5)", () => {
  it("spots a PDF by its address", () => {
    expect(looksLikePdf("https://example.com/paper.PDF?x=1")).toBe(true);
    expect(looksLikePdf("https://example.com/paper")).toBe(false);
  });
});
