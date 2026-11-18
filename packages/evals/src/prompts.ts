/**
 * Prompt evals (D-374): the check-in and setup prompts as the gallery holds them now
 * (gallery/prompts/*.md), composed with the fixed parts code adds, sent to a bot in a quiet
 * workspace. They check that the replies code looks for still come back: "Quiet day" for a brief
 * with nothing to tell, NOTHING_NEW for a scan with nothing new, the setup interview's first card.
 * `--subset prompts`; CI runs it live on pull requests that change a prompt, and nightly.
 */
import { readFileSync } from "node:fs";
import {
  composeBrief,
  composeScan,
  composeSetupScan,
  type PromptId,
} from "../../agent/src/prompts.ts";
import { toolsUsed } from "./checks.ts";
import type { EvalTask } from "./types.ts";

const galleryText = (id: PromptId) =>
  readFileSync(new URL(`../../../gallery/prompts/${id}.md`, import.meta.url), "utf8").trim();

const NOTHING_HERE =
  "\n\n(Right now you have no connected accounts, no calendar, no email, no tickets, no projects and nothing you're watching.)";

/** What run.ts checks: packages/agent/src/checkins.ts QUIET_BRIEF and NOTHING_NEW. */
const QUIET_BRIEF = /^\W*quiet day\b/i;
const isNothingNew = (answer: string) => answer.replace(/[`*.\s]/g, "") === "NOTHING_NEW";

export const PROMPT_TASKS: EvalTask[] = [
  {
    id: "prompt-brief-quiet",
    category: "prompts",
    prompt: `${composeBrief(galleryText("checkin.brief"))}${NOTHING_HERE}`,
    check: (r) => ({
      pass: r.status === "completed" && QUIET_BRIEF.test(r.answer),
      why: 'a brief with nothing to tell should start "Quiet day"',
    }),
  },
  {
    id: "prompt-scan-nothing-new",
    category: "prompts",
    prompt: `${composeScan(galleryText("checkin.scan"))}${NOTHING_HERE}`,
    check: (r) => ({
      pass: r.status === "completed" && isNothingNew(r.answer),
      why: "a scan with nothing new should reply with just NOTHING_NEW",
    }),
  },
  {
    id: "prompt-setup-scan",
    category: "prompts",
    prompt: `${composeScan(galleryText("checkin.scan"))}\n\n${composeSetupScan(galleryText("checkin.setup_scan"))}${NOTHING_HERE}`,
    check: (r) => ({
      pass:
        r.status === "completed" &&
        (isNothingNew(r.answer) || r.answer.trim().startsWith("You're all set.")),
      why: 'the first scan should end in NOTHING_NEW or one "You\'re all set." summary',
    }),
  },
  {
    id: "prompt-setup-guide",
    category: "prompts",
    prompt: `${galleryText("setup.guide")}\n\nStart the interview now.`,
    check: (r) => ({
      pass: toolsUsed(r).includes("ui.show") && !toolsUsed(r).includes("setup.apply"),
      why: "the setup interview should open with a ui.show card, not apply anything yet",
    }),
  },
];
