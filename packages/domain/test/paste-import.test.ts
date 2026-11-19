import { describe, expect, it } from "vitest";
import {
  cronFromWhen,
  PASTE_SOURCES,
  pasteImportPrompt,
  planPastedBot,
  scrubSecrets,
} from "../src/paste-import.ts";

const GROK_REPLY = `Sure! Here's my setup:

NAME: Inbox Chief
ABOUT: I keep Oliver's inbox under control and send a daily plan.
INSTRUCTIONS:
"""
You are Inbox Chief. Triage email every morning.
Be brief. Use bullet points.
"""
SCHEDULE: weekdays 08:30 | Summarize unread email and list what needs a reply
SCHEDULE: weekly fri 16:00 | Send a weekly review of open threads
SCHEDULE: every 2 hours | Check for urgent messages
SCHEDULE: when the moon is full | Howl
EVENT: New email from my boss | Flag it and ping me
EVENT: Meeting starts in 10 minutes | Send me the agenda
SKILL: Weekly Report | Builds the Friday report
"""
1. Open the sent folder
2. Count threads closed this week
3. Write a short report
"""
SKILL: triage | Sorts new mail into folders
APP: Gmail
APP: Google Calendar, Slack
ASK_FIRST: Sending an email
ASK_FIRST: Deleting anything
MEMORY: Oliver works at Stackwares
PREFERENCE: Likes short answers
`;

describe("planPastedBot", () => {
  it("reads a full Grok Bot reply", () => {
    const p = planPastedBot(GROK_REPLY, "grok_bot");
    expect(p.recognized).toBe(true);
    expect(p.kind).toBe("grok_bot");
    expect(p.name).toBe("Inbox Chief");
    expect(p.description).toBe("I keep Oliver's inbox under control and send a daily plan.");
    expect(p.persona_md).toContain("You are Inbox Chief. Triage email every morning.\nBe brief.");
    expect(p.persona_md).toContain(
      "Check with me before:\n- Sending an email\n- Deleting anything",
    );
    expect(p.autonomy).toBe("ask_risky");
    expect(p.routines.map((r) => r.schedule_cron)).toEqual([
      "30 8 * * 1-5",
      "0 16 * * 5",
      "0 */2 * * *",
    ]);
    expect(p.routines[0]?.instructions_md).toBe(
      "Summarize unread email and list what needs a reply",
    );
    expect(p.notes.some((n) => n.includes("when the moon is full"))).toBe(true);
    expect(
      p.notes.some((n) => n.includes("New email from my boss") && n.includes("Messages")),
    ).toBe(true);
    expect(p.notes.some((n) => n.includes("Meeting starts") && n.includes("Meetings"))).toBe(true);
    expect(p.skills.map((s) => s.name)).toEqual(["weekly-report", "triage"]);
    expect(p.skills[0]?.description).toBe("Builds the Friday report");
    expect(p.skills[0]?.body_md).toContain("2. Count threads closed this week");
    expect(p.skills[1]?.body_md).toBe("Sorts new mail into folders");
    expect(p.connections.map((c) => c.name)).toEqual(["Gmail", "Google Calendar", "Slack"]);
    expect(p.memories).toEqual([
      { kind: "fact", content: "Oliver works at Stackwares", source: "MEMORY, line 27" },
      { kind: "preference", content: "Likes short answers", source: "PREFERENCE, line 28" },
    ]);
  });

  it("tolerates markdown: bold labels, headings, bullets and backtick fences", () => {
    const p = planPastedBot(
      `**Name:** Muse Helper

## Instructions
\`\`\`
Help me plan meals.
\`\`\`

## Schedules
- Every Monday at 8am | Plan the week's meals
- Daily at 7pm | Remind me to prep lunch

## Skills
- grocery-list | Makes a grocery list
- recipe-finder | Finds recipes

**Memories:**
- Vegetarian
- Lives in Manila
- Vegetarian
`,
      "muse",
    );
    expect(p.name).toBe("Muse Helper");
    expect(p.persona_md).toBe("Help me plan meals.");
    expect(p.routines.map((r) => r.schedule_cron)).toEqual(["0 8 * * 1", "0 19 * * *"]);
    expect(p.skills.map((s) => s.name)).toEqual(["grocery-list", "recipe-finder"]);
    expect(p.memories.map((m) => m.content)).toEqual(["Vegetarian", "Lives in Manila"]);
  });

  it("joins a schedule that wraps, and reads plain memory lines one by one", () => {
    const p = planPastedBot(
      "INSTRUCTIONS: Help.\nSCHEDULE: daily 09:00 | Summarize the news\nand email it to me\nMEMORIES:\nHas two cats\nWorks nights",
      "muse",
    );
    expect(p.routines.map((r) => r.instructions_md)).toEqual([
      "Summarize the news and email it to me",
    ]);
    expect(p.memories.map((m) => m.content)).toEqual(["Has two cats", "Works nights"]);
  });

  it("turns text with no format into the instructions, with a note", () => {
    const p = planPastedBot(
      "You are a friendly travel planner.\nAlways suggest trains first.",
      "other",
    );
    expect(p.recognized).toBe(false);
    expect(p.name).toBe("Imported bot");
    expect(p.persona_md).toBe("You are a friendly travel planner.\nAlways suggest trains first.");
    expect(p.notes[0]).toContain("didn't follow the setup format");
    expect(p.description).toBe("Imported from another app");
  });

  it("removes lines that look like keys before reading", () => {
    const p = planPastedBot(
      `NAME: Deployer
INSTRUCTIONS:
"""
Deploy the site.
Use the key sk-proj-abcdefghijklmnopqrstuvwxyz123456 for OpenAI.
Docs: https://docs.google.com/document/d/1AbCdEfGhIjKlMnOpQrStUvWxYz0123456789abcd/edit
"""`,
      "grok_bot",
    );
    expect(p.persona_md).not.toContain("sk-proj");
    expect(p.persona_md).toContain("Deploy the site.");
    expect(p.persona_md).toContain("docs.google.com");
    expect(p.notes).toContain("1 line that looked like a key, password or card number was removed");
  });

  it("asks before everything when the bot did", () => {
    const p = planPastedBot("NAME: Careful\nASK_FIRST: Anything that changes data", "duet");
    expect(p.autonomy).toBe("ask_always");
  });

  it("skips none lines, fixes duplicate skill names and gives a default name", () => {
    const p = planPastedBot(
      "INSTRUCTIONS: Be helpful.\nSCHEDULE: none\nEVENT: none\nAPP: none\nSKILL: Report | One\nSKILL: report | Two",
      "dots",
    );
    expect(p.name).toBe("My ChatGPT Dots");
    expect(p.persona_md).toBe("Be helpful.");
    expect(p.routines).toEqual([]);
    expect(p.connections).toEqual([]);
    expect(p.skills.map((s) => s.name)).toEqual(["report", "report-2"]);
    expect(p.notes.some((n) => n.includes("Dots doesn't list its memories"))).toBe(true);
  });

  it("keeps to the template limits", () => {
    const lines = ["NAME: Busy"];
    for (let i = 0; i < 25; i++) lines.push(`SCHEDULE: daily 09:00 | Job ${i}`);
    for (let i = 0; i < 35; i++) lines.push(`SKILL: s${i} | Skill ${i}`);
    lines.push(`INSTRUCTIONS: ${"x".repeat(21_000)}`);
    const p = planPastedBot(lines.join("\n"), "grok_bot");
    expect(p.routines).toHaveLength(20);
    expect(p.skills).toHaveLength(30);
    expect(p.persona_md).toHaveLength(20_000);
    expect(p.notes).toContain("Only the first 20 schedules were kept");
    expect(p.notes).toContain("Only the first 30 skills were kept");
  });
});

describe("Hark and Instinct", () => {
  it("reads a plain Instinct text reply sent as several messages", () => {
    const p = planPastedBot(
      `NAME: Ivy
ABOUT: I run errands for you by text
INSTRUCTIONS: Book the cheapest option. Text me before paying.

SCHEDULE: weekdays 08:00 | Text me today's plan
MEMORY: Allergic to peanuts
MEMORY: Card ending 4242 is the default
MEMORY: Pay with 4242 4242 4242 4242
PREFERENCE: Window seats`,
      "instinct",
    );
    expect(p.name).toBe("Ivy");
    expect(p.persona_md).toBe("Book the cheapest option. Text me before paying.");
    expect(p.routines.map((r) => r.schedule_cron)).toEqual(["0 8 * * 1-5"]);
    expect(p.memories.map((m) => m.content)).toEqual([
      "Allergic to peanuts",
      "Card ending 4242 is the default",
      "Window seats",
    ]);
    expect(p.notes).toContain("1 line that looked like a key, password or card number was removed");
  });

  it("notes Hark's missing memory in Europe", () => {
    const p = planPastedBot(
      "INSTRUCTIONS: Find deals.\nSCHEDULE: daily 07:00 | Check prices",
      "hark",
    );
    expect(p.name).toBe("My Hark Pro");
    expect(p.notes.some((n) => n.includes("Hark keeps no memory"))).toBe(true);
  });

  it("keeps the Instinct prompt short enough for a text and free of fences", () => {
    const prompt = pasteImportPrompt("instinct");
    expect(prompt).not.toContain('"""');
    expect(prompt.length).toBeLessThan(800);
    expect(planPastedBot(prompt, "instinct").recognized).toBe(true);
  });

  it("keeps phone numbers", () => {
    expect(scrubSecrets("Call +63 999 366 0119").removed).toBe(0);
  });
});

describe("cronFromWhen", () => {
  it.each([
    ["daily 09:00", "0 9 * * *"],
    ["daily 9pm", "0 21 * * *"],
    ["every day at 7:15 am", "15 7 * * *"],
    ["weekdays 09:00", "0 9 * * 1-5"],
    ["Every weekday at 8:30", "30 8 * * 1-5"],
    ["weekends 10:00", "0 10 * * 0,6"],
    ["weekly mon 08:00", "0 8 * * 1"],
    ["every friday at 4pm", "0 16 * * 5"],
    ["Mondays 9am", "0 9 * * 1"],
    ["every sat", "0 9 * * 6"],
    ["monthly 1 09:00", "0 9 1 * *"],
    ["monthly on the 15th at 6pm", "0 18 15 * *"],
    ["every 2 hours", "0 */2 * * *"],
    ["every hour", "0 * * * *"],
    ["hourly", "0 * * * *"],
    ["every 30 minutes", "*/30 * * * *"],
    ["daily 09:00 PST", "0 9 * * *"],
    ["0 9 * * 1", "0 9 * * 1"],
  ])("%s → %s", (when, cron) => expect(cronFromWhen(when)).toBe(cron));

  it.each(["whenever", "every 7 minutes", "monthly 31 09:00", "daily 25:00", ""])(
    "%s → null",
    (when) => expect(cronFromWhen(when)).toBeNull(),
  );
});

describe("pasteImportPrompt", () => {
  it("has a prompt for every source, and leaves schedules out for Dots", () => {
    for (const s of PASTE_SOURCES) expect(pasteImportPrompt(s)).toContain("INSTRUCTIONS:");
    expect(pasteImportPrompt("grok_bot")).toContain("Grok Bot");
    expect(pasteImportPrompt("grok_bot")).toContain("SCHEDULE:");
    expect(pasteImportPrompt("dots")).not.toContain("SCHEDULE:");
  });

  it("reads its own example back", () => {
    const p = planPastedBot(pasteImportPrompt("grok_bot"), "grok_bot");
    expect(p.recognized).toBe(true);
  });
});

describe("scrubSecrets", () => {
  it.each([
    "OPENAI_API_KEY=sk-abcdefghijklmnopqrstuvwx",
    "token: ghp_abcdefghijklmnopqrstuvwxyz0123",
    "Authorization: Bearer abcdefghijklmnop1234567890",
    "password: hunter2!",
    "xoxb-1234567890-abcdefghij",
  ])("removes %s", (line) =>
    expect(scrubSecrets(`keep\n${line}`)).toEqual({ text: "keep\n", removed: 1 }),
  );

  it("keeps ordinary lines", () => {
    const text = "Use a friendly tone.\nThe token limit is high.\nhttps://example.com/a/b";
    expect(scrubSecrets(text)).toEqual({ text, removed: 0 });
  });
});
