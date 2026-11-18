/** Starter requests (D-338): reading the model's reply, the rules, the local time and staleness. */
import { BOT_TEMPLATES } from "@casama/domain";
import { describe, expect, it } from "vitest";
import {
  localTime,
  parseStarters,
  personaTemplate,
  ruleStarters,
  STARTERS_REVISED_AT,
  type StarterSignals,
  starterPrompt,
  startersStale,
  technicalRole,
} from "../src/starters.ts";

const four = [
  { emoji: "🌱", text: "Plan a calm Sunday for me" },
  { emoji: "📬", text: "Sum up my unread emails" },
  { emoji: "🧁", text: "Find a quick cupcake recipe" },
  { emoji: "🎁", text: "Help me pick a birthday gift" },
];

describe("parseStarters", () => {
  it("reads a JSON array, even with words around it", () => {
    expect(parseStarters(`Here you go:\n${JSON.stringify(four)}\nEnjoy`)).toEqual(four);
  });

  it("cleans each one: trailing period, missing emoji, duplicates, links and tech words dropped", () => {
    const out = parseStarters(
      JSON.stringify([
        { emoji: "🌱", text: "Plan a calm Sunday for me." },
        { emoji: "not an emoji", text: "Help me write a thank-you note" },
        { emoji: "🌱", text: "plan a calm sunday for me" },
        { emoji: "🔗", text: "Open https://example.com for me" },
        { emoji: "🧰", text: "Call the API and show the JSON" },
        { emoji: "🧁", text: "Find a quick cupcake recipe" },
        { emoji: "🎁", text: "Help me pick a birthday gift" },
      ]),
    );
    expect(out.map((s) => s.text)).toEqual([
      "Plan a calm Sunday for me",
      "Help me write a thank-you note",
      "Find a quick cupcake recipe",
      "Help me pick a birthday gift",
    ]);
    expect(out[1]?.emoji).toBe("✨");
  });

  it("keeps tech words for a technical role", () => {
    const coding = [
      { emoji: "🐛", text: "Fix the failing test in my repo" },
      { emoji: "🔍", text: "Review my pull request for bugs" },
      { emoji: "🧪", text: "Add tests for the API endpoint" },
      { emoji: "⚡", text: "Speed up my slow build" },
    ];
    expect(parseStarters(JSON.stringify(coding))).toEqual([]);
    expect(parseStarters(JSON.stringify(coding), { technical: true })).toEqual(coding);
  });

  it("fewer than four usable, or not JSON, is a failed reply", () => {
    expect(parseStarters(JSON.stringify(four.slice(0, 3)))).toEqual([]);
    expect(parseStarters("Plan your day, write a message")).toEqual([]);
    expect(parseStarters("[not json]")).toEqual([]);
  });
});

describe("localTime", () => {
  it("uses the person's timezone and falls back to UTC for a bad one", () => {
    const at = new Date("2026-11-17T23:30:00Z");
    expect(localTime(at, "Asia/Manila")).toMatchObject({
      hour: 7,
      dayName: "Wednesday",
      part: "morning",
    });
    expect(localTime(at, "Nowhere/Land")).toMatchObject({ hour: 23, part: "night" });
  });
});

describe("ruleStarters", () => {
  const base = { apps: [] as string[], timezone: "UTC" };

  it("always gives four everyday requests without technical words", () => {
    const out = ruleStarters({ ...base, now: new Date("2026-11-17T09:00:00Z") });
    expect(out).toHaveLength(4);
    expect(out[0]?.text).toBe("Help me plan my day");
    for (const s of out) expect(s.text).not.toMatch(/workspace|computer|folder|file/i);
  });

  it("puts connected apps first and fits the time of day", () => {
    const out = ruleStarters({
      apps: ["composio", "gmail", "googlecalendar"],
      timezone: "UTC",
      now: new Date("2026-11-17T19:00:00Z"),
    });
    expect(out.slice(0, 3).map((s) => s.text)).toEqual([
      "Sum up my unread emails",
      "What's on my calendar tomorrow?",
      "Give me an easy dinner idea for tonight",
    ]);
  });

  it("a bot made from a starter bot leads with that role, not everyday chores", () => {
    const coder = BOT_TEMPLATES.find((t) => t.id === "coder");
    if (!coder) throw new Error("no coder template");
    const out = ruleStarters({
      ...base,
      persona: `${coder.persona}\n\nAlso prefer TypeScript.`,
      now: new Date("2026-11-17T19:00:00Z"),
    });
    expect(out).toHaveLength(4);
    expect(out.slice(0, 3).map((s) => s.text)).toEqual(coder.starters.slice(0, 3));
    expect(out.map((s) => s.text)).not.toContain("Give me an easy dinner idea for tonight");
  });

  it("weekends suggest something fun", () => {
    const out = ruleStarters({ ...base, now: new Date("2026-11-21T10:00:00Z") });
    expect(out[0]?.text).toBe("Find something fun to do this weekend");
  });
});

describe("starterPrompt", () => {
  const signals: StarterSignals = {
    botName: "Casama",
    persona: "A friendly personal assistant.",
    person: { name: "Sam", facts: ["Loves baking", "Has two kids"], learn: true },
    apps: ["gmail"],
    recent: ["Write a birthday message for my mom"],
    timezone: "Europe/Berlin",
    now: new Date("2026-11-17T08:00:00Z"),
  };

  it("lists the signals and keeps the name out", () => {
    const p = starterPrompt(signals);
    expect(p).toContain("Tuesday morning");
    expect(p).toContain("Connected apps: gmail");
    expect(p).toContain("- Loves baking");
    expect(p).toContain("- Write a birthday message for my mom");
    expect(p).not.toContain("Sam");
  });

  it("says when nothing is known yet", () => {
    const p = starterPrompt({ ...signals, person: null, recent: [] });
    expect(p).toContain("nothing yet");
  });
});

describe("roles", () => {
  it("finds the starter bot a persona came from by its opening line", () => {
    const coder = BOT_TEMPLATES.find((t) => t.id === "coder");
    expect(personaTemplate(`${coder?.persona}\nMore notes`)?.id).toBe("coder");
    expect(personaTemplate("A friendly personal assistant.")).toBeNull();
    expect(personaTemplate("")).toBeNull();
  });

  it("knows which roles are technical", () => {
    const coder = BOT_TEMPLATES.find((t) => t.id === "coder");
    const fitness = BOT_TEMPLATES.find((t) => t.id === "fitness-coach");
    expect(technicalRole(coder?.persona ?? "")).toBe(true);
    expect(technicalRole(fitness?.persona ?? "")).toBe(false);
    expect(technicalRole("You are a backend developer who loves Go.")).toBe(true);
    expect(technicalRole("A friendly personal assistant.")).toBe(false);
  });

  it("puts the role and its example requests in the prompt", () => {
    const coder = BOT_TEMPLATES.find((t) => t.id === "coder");
    const p = starterPrompt({
      botName: "Dev Bot",
      persona: coder?.persona ?? "",
      person: null,
      apps: [],
      recent: [],
      timezone: "UTC",
      now: new Date("2026-11-17T08:00:00Z"),
    });
    expect(p).toContain("write for this role");
    expect(p).toContain(`- ${coder?.starters[0]}`);
  });
});

describe("startersStale", () => {
  it("a list written before starters followed the role is written again", () => {
    const before = new Date(STARTERS_REVISED_AT.getTime() - 60_000);
    const after = new Date(STARTERS_REVISED_AT.getTime() + 60_000);
    const now = new Date(STARTERS_REVISED_AT.getTime() + 3_600_000);
    expect(startersStale({ items: four, source: "ai", generatedAt: before }, null, now)).toBe(true);
    expect(startersStale({ items: four, source: "ai", generatedAt: after }, null, now)).toBe(false);
  });

  const now = new Date("2026-11-19T12:00:00Z");
  const ago = (h: number) => new Date(now.getTime() - h * 3_600_000);

  it("a model's list lasts most of a day; rules only a few hours", () => {
    expect(startersStale(null, null, now)).toBe(true);
    expect(startersStale({ items: four, source: "ai", generatedAt: ago(19) }, null, now)).toBe(
      false,
    );
    expect(startersStale({ items: four, source: "ai", generatedAt: ago(21) }, null, now)).toBe(
      true,
    );
    expect(startersStale({ items: four, source: "rules", generatedAt: ago(2) }, null, now)).toBe(
      false,
    );
    expect(startersStale({ items: four, source: "rules", generatedAt: ago(4) }, null, now)).toBe(
      true,
    );
  });

  it("an app connected since makes it stale, but not within 10 minutes of the last list", () => {
    const saved = { items: four, source: "ai" as const, generatedAt: ago(1) };
    expect(startersStale(saved, ago(0.5), now)).toBe(true);
    expect(startersStale(saved, ago(2), now)).toBe(false);
    const fresh = { items: four, source: "ai" as const, generatedAt: ago(0.1) };
    expect(startersStale(fresh, ago(0.05), now)).toBe(false);
  });
});
