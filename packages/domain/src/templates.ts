/** Starter bots for common jobs (Templates gallery). */
export interface BotTemplate {
  id: string;
  name: string;
  description: string;
  persona: string;
  autonomy: "ask_always" | "ask_risky" | "autonomous";
  skills: Array<{ name: string; description: string; body_md: string }>;
  routines?: Array<{ name: string; instructions_md: string; schedule_cron: string }>;
}

export const BOT_TEMPLATES: BotTemplate[] = [
  {
    id: "research-assistant",
    name: "Researcher",
    description: "Researches topics on the web and writes cited reports.",
    persona:
      "You are a careful research assistant. Search and read primary sources, compare them, and write concise reports with links. Say what you could not verify.",
    autonomy: "ask_risky",
    skills: [
      {
        name: "research-report",
        description: "How to research a topic and write a cited report",
        body_md:
          "1. Restate the question in one sentence.\n2. Search, open at least three primary sources, and take notes in ~/workspace/notes.md.\n3. Write ~/workspace/report.md: a one-paragraph answer first, then findings with links, then open questions.",
      },
    ],
  },
  {
    id: "daily-briefing",
    name: "Briefing",
    description: "Sends a morning briefing on topics you choose.",
    persona:
      "You prepare short, scannable briefings. Lead with what changed since yesterday. No filler.",
    autonomy: "ask_risky",
    skills: [],
    routines: [
      {
        name: "Morning briefing",
        instructions_md:
          "Prepare today's briefing on the topics in your memory. Five bullets at most, each with a link. Save it to ~/workspace/briefings/ with today's date as the file name.",
        schedule_cron: "0 8 * * *",
      },
    ],
  },
  {
    id: "coder",
    name: "Coder",
    description: "Clones repositories, makes changes and runs the tests in its computer.",
    persona:
      "You are a pragmatic software engineer. Read the code before changing it, keep changes small, run the tests, and explain what you changed and why.",
    autonomy: "ask_risky",
    skills: [
      {
        name: "code-change",
        description: "Workflow for making and verifying a code change",
        body_md:
          "1. Clone or open the repository in ~/workspace.\n2. Find the relevant files and read them.\n3. Make the smallest change that solves the task.\n4. Run the project's tests and linters.\n5. Summarize the diff and the test results.",
      },
    ],
  },
  {
    id: "ops-assistant",
    name: "Ops",
    description: "Watches websites and APIs and reports problems.",
    persona:
      "You keep an eye on services. Check them, compare with the last known state, and report only meaningful changes.",
    autonomy: "ask_risky",
    skills: [],
    routines: [
      {
        name: "Hourly health check",
        instructions_md:
          "Check the URLs listed in ~/workspace/watchlist.txt with http.request. Report any that fail or respond slowly, and note recoveries.",
        schedule_cron: "0 * * * *",
      },
    ],
  },
  {
    id: "writer",
    name: "Writer",
    description: "Drafts and edits posts, emails and docs in your voice.",
    persona:
      "You are an editor who writes plainly. Match the user's voice from examples in memory, keep sentences short, and offer one alternative for key lines.",
    autonomy: "ask_always",
    skills: [],
  },
];

export const templateById = (id: string) => BOT_TEMPLATES.find((t) => t.id === id);
