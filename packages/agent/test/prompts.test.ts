/** Check-in and setup prompts (D-374): gallery text, code-owned markers, built-in fallback. */
import { readdirSync, readFileSync } from "node:fs";
import { afterEach, describe, expect, it } from "vitest";
import {
  BRIEF_INSTRUCTIONS,
  briefInstructions,
  briefInstructionsNow,
  QUIET_BRIEF,
  SCAN_INSTRUCTIONS,
  scanInstructions,
  scanInstructionsNow,
  setupScanInstructionsNow,
} from "../src/checkins.ts";
import {
  BUILT_IN_PROMPTS,
  checkPromptText,
  PROMPT_IDS,
  promptText,
  promptVersion,
  setPrompts,
} from "../src/prompts.ts";
import { setupGuide } from "../src/tools/setup.ts";

const gallery = new URL("../../../gallery/", import.meta.url);
const read = (path: string) => readFileSync(new URL(path, gallery), "utf8");

afterEach(() => setPrompts([]));

describe("prompts in the gallery", () => {
  it("has one good file per prompt, and prompts.json matches them", () => {
    const files = readdirSync(new URL("prompts/", gallery)).filter((f) => f.endsWith(".md"));
    expect(files.map((f) => f.slice(0, -3)).sort()).toEqual([...PROMPT_IDS].sort());
    const built = JSON.parse(read("prompts.json")) as {
      items: { id: string; version: number; text: string }[];
    };
    for (const f of files) {
      const id = f.slice(0, -3);
      const text = read(`prompts/${f}`).trim();
      expect(checkPromptText(id, text), id).toEqual([]);
      expect(built.items.find((i) => i.id === id)?.text, id).toBe(text);
    }
  });

  it("check.mjs refuses the same reserved words", () => {
    const source = read("check.mjs");
    for (const id of PROMPT_IDS) expect(source).toContain(`"${id}"`);
    for (const word of ["NOTHING_NEW", "quiet day", "write my morning brief for today"])
      expect(source).toContain(word);
  });
});

describe("the fixed parts stay in code", () => {
  it("refuses gallery text that carries a marker", () => {
    expect(
      checkPromptText("checkin.brief", "If nothing, say Quiet day and stop there."),
    ).toHaveLength(1);
    expect(
      checkPromptText("checkin.scan", "Reply NOTHING_NEW when there is nothing at all."),
    ).toHaveLength(1);
    expect(checkPromptText("checkin.scan", "short")).toHaveLength(1);
    expect(checkPromptText("nope", "A long enough text for an unknown id.")).toHaveLength(1);
  });

  it("composes gallery text between the markers code checks for", () => {
    setPrompts([
      { id: "checkin.brief", version: 3, text: "Tell me about my day in three short lines." },
      { id: "checkin.scan", version: 2, text: "Look at my mail and calendar for anything new." },
      { id: "checkin.setup_scan", version: 2, text: "This is your first look; find a few things." },
    ]);
    expect(promptVersion("checkin.brief")).toBe(3);
    const brief = briefInstructionsNow();
    expect(brief.startsWith("Write my morning brief for today. Tell me about my day")).toBe(true);
    expect(brief).toContain('"Quiet day"');
    expect(QUIET_BRIEF.test("Quiet day, nothing on.")).toBe(true);
    const scan = scanInstructionsNow();
    expect(scan.startsWith("Check-in scan. Look at my mail")).toBe(true);
    expect(scan.endsWith("reply with just NOTHING_NEW.")).toBe(true);
    expect(setupScanInstructionsNow()).toContain("You're all set.");
    // Briefs and scans stored with the built-in wording follow the gallery; rewritten ones don't.
    expect(briefInstructions(BRIEF_INSTRUCTIONS)).toBe(brief);
    expect(scanInstructions(SCAN_INSTRUCTIONS)).toBe(scan);
    expect(briefInstructions("My own brief.")).toBe("My own brief.");
  });

  it("falls back to the built-in text", () => {
    setPrompts([{ id: "setup.guide", version: 0, text: "A version zero entry is not taken." }]);
    expect(setupGuide()).toBe(BUILT_IN_PROMPTS["setup.guide"]);
    expect(promptText("checkin.reason.event")).toBe(BUILT_IN_PROMPTS["checkin.reason.event"]);
    expect(briefInstructionsNow()).toBe(BRIEF_INSTRUCTIONS);
  });
});
