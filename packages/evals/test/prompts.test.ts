import { describe, expect, it } from "vitest";
import { BRIEF_OPENING, SCAN_OPENING } from "../../agent/src/prompts.ts";
import { PROMPT_TASKS } from "../src/prompts.ts";
import type { EvalRun } from "../src/types.ts";

const run = (answer: string, tools: string[] = []): EvalRun => ({
  status: "completed",
  answer,
  events: tools.map((name) => ({ type: "tool.started", payload: { tool: name } })),
  file: async () => null,
});
const task = (id: string) => {
  const t = PROMPT_TASKS.find((x) => x.id === id);
  if (!t) throw new Error(id);
  return t;
};

describe("prompt evals (D-374)", () => {
  it("send the gallery's text with the fixed parts code adds", () => {
    expect(task("prompt-brief-quiet").prompt.startsWith(BRIEF_OPENING)).toBe(true);
    expect(task("prompt-brief-quiet").prompt).toContain('"Quiet day"');
    expect(task("prompt-scan-nothing-new").prompt.startsWith(SCAN_OPENING)).toBe(true);
    expect(task("prompt-setup-scan").prompt).toContain("You're all set.");
    expect(task("prompt-setup-guide").prompt).toContain("ui.show");
  });

  it("check for the replies code looks for", async () => {
    expect((await task("prompt-brief-quiet").check(run("Quiet day, nothing on."))).pass).toBe(true);
    expect((await task("prompt-brief-quiet").check(run("Today you have..."))).pass).toBe(false);
    expect((await task("prompt-scan-nothing-new").check(run("NOTHING_NEW"))).pass).toBe(true);
    expect((await task("prompt-scan-nothing-new").check(run("Nothing new today."))).pass).toBe(
      false,
    );
    expect(
      (await task("prompt-setup-scan").check(run("You're all set. Found 2 things."))).pass,
    ).toBe(true);
    expect((await task("prompt-setup-guide").check(run("", ["ui.show"]))).pass).toBe(true);
    expect((await task("prompt-setup-guide").check(run("", ["ui.show", "setup.apply"]))).pass).toBe(
      false,
    );
  });
});
