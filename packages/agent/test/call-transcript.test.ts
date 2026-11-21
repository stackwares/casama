/** A voice call's transcript turns are the app's, not model output (D-478). */
import { describe, expect, it } from "vitest";
import { CALL_TRANSCRIPT_LABEL, callTranscriptTurn } from "../src/run.ts";

describe("call transcript turns", () => {
  it("knows a saved transcript turn from a reply the bot wrote", () => {
    expect(callTranscriptTurn([{ type: "text", text: "Booked it.", voice: true, call: "x" }])).toBe(
      true,
    );
    expect(callTranscriptTurn([{ type: "text", text: "Booked it." }])).toBe(false);
    expect(callTranscriptTurn("Booked it.")).toBe(false);
    expect(callTranscriptTurn(null)).toBe(false);
    expect(CALL_TRANSCRIPT_LABEL).toContain("transcript");
  });
});
