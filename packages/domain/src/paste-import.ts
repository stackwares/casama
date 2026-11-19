/**
 * Paste a bot's setup (D-415): a person sends their old bot (Grok Bot, Meta Muse, ChatGPT Dots,
 * Claude Duet or Cowork, or anything else) a prompt asking it to describe itself in a fixed format,
 * then pastes the reply into Casama. This turns the reply into the same plan the folder import
 * (D-122) gives, so the same review screen and the template import (D-110) create the bot.
 *
 * No model reads the paste: the format is strict enough to read line by line, and text that doesn't
 * follow it becomes the bot's instructions, with a note saying so. Lines that look like keys or
 * passwords are removed first.
 */

import { cronFromText } from "./agent-import.ts";
import { isValidCron } from "./schedule.ts";

export const PASTE_SOURCES = [
  "grok_bot",
  "muse",
  "dots",
  "duet",
  "hark",
  "instinct",
  "other",
] as const;
export type PasteSource = (typeof PASTE_SOURCES)[number];

export const PASTE_SOURCE_NAMES: Record<PasteSource, string> = {
  grok_bot: "Grok Bot",
  muse: "Meta Muse",
  dots: "ChatGPT Dots",
  duet: "Claude Duet",
  hark: "Hark Pro",
  instinct: "Instinct",
  other: "another app",
};

/** Bumped when the format changes, so a reply can be matched to the prompt that asked for it. */
export const PASTE_PROMPT_VERSION = 1;

const INTRO: Record<PasteSource, string> = {
  grok_bot:
    "I'm moving you, my Grok Bot, to another app. Describe how you are set up: your instructions, your schedules and events, your skills or recorded workflows, the apps you use, and what you check with me first.",
  muse: "I'm moving you, my Muse, to another app. Describe how you are set up: your instructions, your schedules and events, your skills, the apps you use, what you check with me first, and what's in your memory files.",
  dots: "I'm moving you, my dot, to another app. Describe how you are set up: your instructions, the apps you use, what you check with me first, and what you remember about me.",
  duet: "I'm moving you to another app. Describe how you are set up: your instructions, your scheduled tasks (including any morning brief), your skills, the apps you use, what you check with me first, and what you remember about me.",
  hark: "I'm moving you, my Hark assistant, to another app. Describe how you are set up: what you do for me, your scheduled tasks, the sites and apps you use for me, what you check with me first, and what you remember about me.",
  instinct:
    "I'm moving you to another app. Text me back your setup as plain lines, with no formatting.",
  other:
    "I'm moving you to another app. Describe how you are set up: your instructions, your schedules, your skills, the apps you use, what you check with me first, and what you remember about me.",
};

/** The prompt to send the old bot. */
export function pasteImportPrompt(source: PasteSource): string {
  // Instinct is reached by text message: a short prompt, and a reply with no fences.
  if (source === "instinct")
    return `${INTRO.instinct}

NAME: your name
ABOUT: one sentence on what you do for me
INSTRUCTIONS: how I asked you to work, word for word
SCHEDULE: <when> | <what you do then> (one line for each regular check-in)
ASK_FIRST: something you check with me before doing
MEMORY: one thing you know about me (one line each)
PREFERENCE: one way I like things done

Write each <when> like: daily 09:00, weekdays 09:00, weekly mon 08:00. Never include passwords, card numbers or codes.`;
  const schedules =
    source === "dots"
      ? ""
      : `SCHEDULE: <when> | <what you do then>
EVENT: <what starts it> | <what you do then>
`;
  return `${INTRO[source]}

Reply with only the block below, filled in. Repeat a line for each item. Leave out any line that doesn't apply. Never include passwords, keys or tokens.

NAME: <your name>
ABOUT: <one sentence on what you do>
INSTRUCTIONS:
"""
<your full instructions, word for word>
"""
${schedules}SKILL: <short-name> | <one line on what it does>
"""
<its steps>
"""
APP: <an app or service you use>
ASK_FIRST: <something you check with me before doing>
MEMORY: <one thing you remember about me>
PREFERENCE: <one way I like things done>
${
  source === "dots"
    ? ""
    : `
Write each <when> in one of these forms, in my local time: daily 09:00, weekdays 09:00, weekly mon 08:00, monthly 1 09:00, every 2 hours, every 30 minutes.
`
}`;
}

export interface PastedBotPlan {
  kind: PasteSource;
  name: string;
  description: string;
  persona_md: string;
  autonomy: "ask_always" | "ask_risky";
  skills: Array<{
    name: string;
    description: string;
    body_md: string;
    files: never[];
    source: string;
  }>;
  routines: Array<{ name: string; instructions_md: string; schedule_cron: string; source: string }>;
  memories: Array<{ kind: "fact" | "preference"; content: string; source: string }>;
  connections: Array<{ kind: string; name: string }>;
  notes: string[];
  /** False when no part of the format was found and the whole paste became the instructions. */
  recognized: boolean;
}

const LIMIT = {
  name: 80,
  description: 300,
  persona: 20_000,
  memory: 8000,
  memories: 200,
  skills: 30,
  skillBody: 50_000,
  routines: 20,
  connections: 30,
  text: 100_000,
};

// ---- secrets ---------------------------------------------------------------------------------

const SECRET_PATTERNS: RegExp[] = [
  /\b(sk|pk|rk|xai|gsk|sk-ant|sk-proj|sk-or)-[A-Za-z0-9_-]{16,}/,
  /\bgh[pousr]_[A-Za-z0-9]{20,}/,
  /\bgithub_pat_[A-Za-z0-9_]{20,}/,
  /\bxox[abprs]-[A-Za-z0-9-]{10,}/,
  /\bAKIA[0-9A-Z]{16}\b/,
  /\bAIza[0-9A-Za-z_-]{30,}/,
  /\beyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}/,
  /\bbearer\s+[A-Za-z0-9._~+/-]{16,}/i,
  /-----BEGIN [A-Z ]*PRIVATE KEY-----/,
  /\b(password|passwd|pwd|api[_ -]?key|secret|token)\s*[:=]\s*(?=\S*[\d!@#$%^&*])\S{6,}/i,
  // A long run of key-like characters with both letters and digits.
  /(?=[A-Za-z0-9+/_-]*\d)(?=[A-Za-z0-9+/_-]*[A-Za-z])\b[A-Za-z0-9+/_-]{40,}\b/,
];

/** A 13 to 19 digit number (spaces or dashes allowed) that passes the Luhn check. */
function hasCardNumber(line: string) {
  for (const m of line.matchAll(/\b\d(?:[ -]?\d){12,18}\b/g)) {
    const digits = m[0].replace(/\D/g, "");
    let sum = 0;
    for (let i = 0; i < digits.length; i++) {
      let d = Number(digits[digits.length - 1 - i]);
      if (i % 2 === 1) {
        d *= 2;
        if (d > 9) d -= 9;
      }
      sum += d;
    }
    if (sum % 10 === 0) return true;
  }
  return false;
}

/** Removes lines that look like keys, passwords or card numbers; says how many went. */
export function scrubSecrets(text: string): { text: string; removed: number } {
  let removed = 0;
  const lines = text.split("\n").map((line) => {
    // Links are left alone: a long document id in a URL isn't a key.
    const bare = line.replace(/https?:\/\/\S+/g, "");
    if (SECRET_PATTERNS.some((p) => p.test(bare)) || hasCardNumber(bare)) {
      removed++;
      return "";
    }
    return line;
  });
  return { text: lines.join("\n"), removed };
}

// ---- schedules -------------------------------------------------------------------------------

const DAYS: Record<string, number> = {
  sun: 0,
  sunday: 0,
  sundays: 0,
  mon: 1,
  monday: 1,
  mondays: 1,
  tue: 2,
  tues: 2,
  tuesday: 2,
  tuesdays: 2,
  wed: 3,
  weds: 3,
  wednesday: 3,
  wednesdays: 3,
  thu: 4,
  thur: 4,
  thurs: 4,
  thursday: 4,
  thursdays: 4,
  fri: 5,
  friday: 5,
  fridays: 5,
  sat: 6,
  saturday: 6,
  saturdays: 6,
};

/** "09:00", "9am", "9:30 pm", "noon" → [hour, minute]; 9:00 when there is no time. */
function timeOf(s: string | undefined): [number, number] | null {
  const t = (s ?? "").trim().replace(/^at\s+/, "");
  if (!t) return [9, 0];
  if (t === "noon" || t === "midday") return [12, 0];
  if (t === "midnight") return [0, 0];
  const m = /^(\d{1,2})(?:[:.h](\d{2}))?\s*(am|pm|a\.m\.|p\.m\.)?$/.exec(t);
  if (!m) return null;
  let h = Number(m[1]);
  const min = Number(m[2] ?? 0);
  const ap = m[3]?.replaceAll(".", "");
  if (ap === "pm" && h < 12) h += 12;
  if (ap === "am" && h === 12) h = 0;
  if (h > 23 || min > 59) return null;
  return [h, min];
}

/**
 * The schedule forms the prompt asks for (and common ways of saying them) → cron, or null.
 * "daily 09:00", "weekdays 9am", "weekly mon 08:00", "every monday at 8", "monthly 1 09:00",
 * "every 2 hours", "every 30 minutes", or a cron expression.
 */
export function cronFromWhen(raw: string): string | null {
  const s = raw
    .trim()
    .toLowerCase()
    .replace(/\s+/g, " ")
    .replace(/[,.]$/, "")
    // A time zone written after the time is dropped: routines run in the person's own.
    .replace(/(\d|am|pm)\s+(local( time)?|my time|[a-z]{2,4}t|utc|gmt)([+-]\d+)?$/, "$1");
  if (!s) return null;
  if (isValidCron(s)) return s;
  const plain = cronFromText(
    s
      .replace(/^every (hour|minute)$/, "every 1 $1")
      .replace(/^every (\d+) (hours?|minutes?|mins?|hrs?)$/, "every $1$2")
      .replace(/^hourly$/, "every 1h"),
  );
  if (plain) return plain;
  let m = /^(?:daily|every ?day|each day)(?: (?:at )?(.+))?$/.exec(s);
  if (m) {
    const t = timeOf(m[1]);
    return t ? `${t[1]} ${t[0]} * * *` : null;
  }
  m = /^(?:weekdays|every weekday|each weekday|mon(?:day)?-fri(?:day)?)(?: (?:at )?(.+))?$/.exec(s);
  if (m) {
    const t = timeOf(m[1]);
    return t ? `${t[1]} ${t[0]} * * 1-5` : null;
  }
  m = /^(?:weekends|every weekend)(?: (?:at )?(.+))?$/.exec(s);
  if (m) {
    const t = timeOf(m[1]);
    return t ? `${t[1]} ${t[0]} * * 0,6` : null;
  }
  m = /^(?:weekly (?:on )?|every |each |on )?([a-z]+)(?: (?:at )?(.+))?$/.exec(s);
  if (m?.[1] && m[1] in DAYS) {
    const t = timeOf(m[2]);
    return t ? `${t[1]} ${t[0]} * * ${DAYS[m[1]]}` : null;
  }
  m =
    /^(?:monthly(?: on)?(?: the)?|every month on the) (\d{1,2})(?:st|nd|rd|th)?(?: (?:at )?(.+))?$/.exec(
      s,
    );
  if (m) {
    const day = Number(m[1]);
    const t = timeOf(m[2]);
    return t && day >= 1 && day <= 28 ? `${t[1]} ${t[0]} ${day} * *` : null;
  }
  return null;
}

// ---- reading the reply -----------------------------------------------------------------------

type Label =
  | "name"
  | "about"
  | "instructions"
  | "schedule"
  | "event"
  | "skill"
  | "app"
  | "ask_first"
  | "memory"
  | "preference";

const LABELS: Array<[RegExp, Label]> = [
  [/^(bot ?)?name$/, "name"],
  [/^(about|description)$/, "about"],
  [/^(instructions?|system prompt|persona|prompt)$/, "instructions"],
  [/^(schedules?|scheduled tasks?|routines?)$/, "schedule"],
  [/^(events?|triggers?)$/, "event"],
  [/^(skills?|workflows?|recorded workflows?)$/, "skill"],
  [/^(apps?|tools?|integrations?|connections?|connected apps?)$/, "app"],
  [
    /^(ask[ _-]?first|ask before|approvals?|check with me first|ask[ _-]?first rules?)$/,
    "ask_first",
  ],
  [/^(memory|memories|facts?|what i remember)$/, "memory"],
  [/^(preferences?)$/, "preference"],
];

const BLOCK_LABELS = new Set<Label>(["instructions", "skill", "about"]);

const clean = (line: string) =>
  line
    .replace(/\*\*|__/g, "")
    .replace(/^\s*(?:[-*•]|\d+[.)])\s+/, "")
    .trim();

/** A label line: "SCHEDULE: …", "**Schedule:** …", "## Schedules", "Instructions:". */
function labelOf(line: string): { label: Label; rest: string } | null {
  const heading = /^\s*#{1,6}\s+(.+?)\s*:?\s*$/.exec(line);
  const text = heading ? (heading[1] ?? "") : clean(line);
  const m = heading ? [text, text, ""] : /^([A-Za-z][A-Za-z _-]{1,30}?)\s*[:：]\s*(.*)$/.exec(text);
  if (!m) return null;
  const key = (m[1] ?? "").toLowerCase().replace(/\*|_$/g, "").trim();
  for (const [re, label] of LABELS) if (re.test(key)) return { label, rest: (m[2] ?? "").trim() };
  return null;
}

const FENCE = /^\s*("""|```|''')\w*\s*$/;

interface Entry {
  label: Label;
  inline: string;
  body: string[];
  line: number;
}

function readEntries(text: string): Entry[] {
  const out: Entry[] = [];
  let cur: Entry | null = null;
  let fenced = false;
  const lines = text.split("\n");
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i] ?? "";
    if (FENCE.test(line)) {
      fenced = !fenced;
      continue;
    }
    if (!fenced) {
      const l = labelOf(line);
      if (l) {
        cur = { label: l.label, inline: l.rest, body: [], line: i + 1 };
        out.push(cur);
        continue;
      }
    }
    if (!cur) continue;
    // Bullets under a list label are items of their own ("SCHEDULES:\n- daily 09:00 | …").
    if (!fenced && !BLOCK_LABELS.has(cur.label) && cur.label !== "name") {
      const item = clean(line);
      if (!item) continue;
      const bullet = /^\s*(?:[-*•]|\d+[.)])\s+/.test(line);
      if (!cur.inline) cur.inline = item;
      // A schedule or event that wraps onto the next line goes on; other lists are one per line.
      else if (
        (cur.label === "schedule" || cur.label === "event") &&
        !bullet &&
        !item.includes("|")
      )
        cur.inline = `${cur.inline} ${item}`;
      else {
        cur = { label: cur.label, inline: item, body: [], line: i + 1 };
        out.push(cur);
      }
      continue;
    }
    cur.body.push(line);
  }
  return out;
}

const trimBlock = (lines: string[]) =>
  lines
    .join("\n")
    .replace(/^\s*\n|\n\s*$/g, "")
    .trim();

/** "a | b", else "a — b" or "a: b"; returns [a, b]. */
function pair(s: string): [string, string] {
  for (const sep of [/\s*\|\s*/, /\s+[—–]\s+/, /\s+-\s+/, /\s*->\s*|\s*→\s*/])
    if (sep.test(s)) {
      const [a, ...b] = s.split(sep);
      return [(a ?? "").trim(), b.join(" ").trim()];
    }
  const colon = /^([^:]{3,60}):\s+(.+)$/.exec(s);
  if (colon) return [(colon[1] ?? "").trim(), (colon[2] ?? "").trim()];
  return [s.trim(), ""];
}

const skillSlug = (raw: string) =>
  raw
    .toLowerCase()
    .replace(/[^a-z0-9_-]+/g, "-")
    .replace(/^[^a-z0-9]+/, "")
    .replace(/-+$/, "")
    .slice(0, 63) || "imported-skill";

const shortName = (s: string, max = 60) => {
  const one = s.replace(/\s+/g, " ").trim();
  if (one.length <= max) return one.replace(/[.:]$/, "");
  const cut = one.slice(0, max);
  return `${cut.slice(0, Math.max(cut.lastIndexOf(" "), 20))}…`;
};

/** The closest Casama trigger for an event, for the note. */
function closestTrigger(event: string) {
  const e = event.toLowerCase();
  if (/meeting|calendar|event starts|invite/.test(e)) return "a Meetings routine";
  if (/email|e-mail|inbox|message|dm|mention|slack|teams|whatsapp|sms/.test(e))
    return "a Messages routine";
  if (/github|pull request|\bpr\b|issue|commit/.test(e)) return "a GitHub trigger";
  return "a webhook trigger, or a routine that checks on a schedule";
}

/** Reads a reply to pasteImportPrompt (or any pasted setup) into a plan. */
export function planPastedBot(input: string, source: PasteSource): PastedBotPlan {
  const from = PASTE_SOURCE_NAMES[source];
  const notes: string[] = [];
  const raw = input.replace(/\r\n?/g, "\n").replace(/^﻿/, "").slice(0, LIMIT.text);
  if (input.length > LIMIT.text)
    notes.push("The paste was long, so only the first 100,000 characters were read");
  const { text, removed } = scrubSecrets(raw);
  if (removed)
    notes.push(
      removed === 1
        ? "1 line that looked like a key, password or card number was removed"
        : `${removed} lines that looked like keys, passwords or card numbers were removed`,
    );

  const entries = readEntries(text);
  const of = (label: Label) => entries.filter((e) => e.label === label);
  const recognized = entries.some((e) => e.label !== "name");

  const nameEntry = of("name")[0];
  const name = (
    nameEntry?.inline ||
    (nameEntry ? trimBlock(nameEntry.body).split("\n")[0] : "") ||
    (source === "other" ? "Imported bot" : `My ${from}`)
  )
    .replace(/^["'<]+|["'>]+$/g, "")
    .trim()
    .slice(0, LIMIT.name);

  const aboutEntry = of("about")[0];
  const about = (
    [aboutEntry?.inline, aboutEntry ? trimBlock(aboutEntry.body) : ""].filter(Boolean).join(" ") ||
    `Imported from ${from}`
  )
    .replace(/\s+/g, " ")
    .slice(0, LIMIT.description);

  let persona = of("instructions")
    .map((e) => [e.inline, trimBlock(e.body)].filter(Boolean).join("\n"))
    .filter(Boolean)
    .join("\n\n");
  if (!recognized) {
    // A name line, when there is one, is the name rather than part of the instructions.
    persona = text
      .split("\n")
      .filter((_, i) => i + 1 !== nameEntry?.line)
      .join("\n")
      .trim();
    if (persona)
      notes.push(
        "This didn't follow the setup format, so everything you pasted became the bot's instructions. Check them, or send your bot the prompt and paste its reply instead.",
      );
  }

  const askFirst = of("ask_first")
    .map((e) => e.inline)
    .filter((x) => x && !/^none\b|^n\/a$/i.test(x));
  let autonomy: PastedBotPlan["autonomy"] = "ask_risky";
  if (askFirst.length) {
    persona =
      `${persona}\n\nCheck with me before:\n${askFirst.map((a) => `- ${a}`).join("\n")}`.trim();
    if (
      askFirst.some((a) =>
        /^(everything|anything|any action|every action|all actions|always)\b/i.test(a),
      )
    )
      autonomy = "ask_always";
  }
  if (persona.length > LIMIT.persona) {
    persona = persona.slice(0, LIMIT.persona);
    notes.push("The instructions were over 20,000 characters and were cut short");
  }

  const routines: PastedBotPlan["routines"] = [];
  for (const e of of("schedule")) {
    const [when, what] = pair(e.inline);
    const job = (what || trimBlock(e.body)).trim();
    if (!when || /^none\b|^n\/a$/i.test(when)) continue;
    if (!job) {
      notes.push(`The schedule "${shortName(when)}" says nothing about what to do; not imported`);
      continue;
    }
    const cron = cronFromWhen(when);
    if (!cron) {
      notes.push(
        `"${shortName(job)}": its time ("${shortName(when, 40)}") couldn't be read; add it as a routine yourself`,
      );
      continue;
    }
    if (routines.length >= LIMIT.routines) {
      notes.push(`Only the first ${LIMIT.routines} schedules were kept`);
      break;
    }
    routines.push({
      name: shortName(job),
      instructions_md: job.slice(0, 20_000),
      schedule_cron: cron,
      source: `SCHEDULE, line ${e.line}`,
    });
  }

  for (const e of of("event")) {
    const [trigger, what] = pair(e.inline);
    if (!trigger || /^none\b|^n\/a$/i.test(trigger)) continue;
    notes.push(
      `"${shortName(trigger, 50)}"${what ? ` (${shortName(what, 50)})` : ""} runs on an event, so it wasn't brought over. Make it as ${closestTrigger(trigger)}.`,
    );
  }

  const skills: PastedBotPlan["skills"] = [];
  const usedSkills = new Set<string>();
  // "SKILLS:" followed by one bullet per skill is a list, not one skill's steps.
  const skillEntries = of("skill").flatMap((e) => {
    const lines = e.body.filter((l) => l.trim());
    if (e.inline || !lines.length || !lines.every((l) => /^\s*(?:[-*•]|\d+[.)])\s+.*\|/.test(l)))
      return [e];
    return lines.map((l, i) => ({ ...e, inline: clean(l), body: [], line: e.line + i + 1 }));
  });
  for (const e of skillEntries) {
    const [rawName, desc] = pair(e.inline);
    const body = trimBlock(e.body);
    if (!rawName && !body) continue;
    if (/^none\b|^n\/a$/i.test(rawName)) continue;
    let slug = skillSlug(rawName || desc || body.split("\n")[0] || "");
    const base = slug;
    for (let n = 2; usedSkills.has(slug); n++) slug = `${base.slice(0, 60)}-${n}`;
    if (rawName && slug !== rawName)
      notes.push(`The skill "${shortName(rawName, 40)}" is named "${slug}" here`);
    const description = (desc || body.split("\n").find((l) => l.trim()) || rawName)
      .trim()
      .slice(0, 300);
    if (skills.length >= LIMIT.skills) {
      notes.push(`Only the first ${LIMIT.skills} skills were kept`);
      break;
    }
    usedSkills.add(slug);
    skills.push({
      name: slug,
      description: description || slug,
      body_md: (body || description || slug).slice(0, LIMIT.skillBody),
      files: [],
      source: `SKILL, line ${e.line}`,
    });
  }

  const connections: PastedBotPlan["connections"] = [];
  const seenApps = new Set<string>();
  for (const e of of("app")) {
    for (const part of e.inline.split(/\s*[,;]\s*/)) {
      const app = part
        .replace(/\s*\(.*\)$/, "")
        .trim()
        .slice(0, 120);
      const key = app.toLowerCase();
      if (!app || /^none\b|^n\/a$/i.test(app) || seenApps.has(key)) continue;
      if (connections.length >= LIMIT.connections) break;
      seenApps.add(key);
      connections.push({ kind: "app", name: app });
    }
  }

  const memories: PastedBotPlan["memories"] = [];
  const seenMem = new Set<string>();
  for (const e of [...of("memory"), ...of("preference")].sort((a, b) => a.line - b.line)) {
    const content = [e.inline, trimBlock(e.body)]
      .filter(Boolean)
      .join(" ")
      .trim()
      .slice(0, LIMIT.memory);
    const key = content.toLowerCase();
    if (content.length < 3 || /^none\b|^n\/a$/i.test(content) || seenMem.has(key)) continue;
    if (memories.length >= LIMIT.memories) {
      notes.push(`Only the first ${LIMIT.memories} memories were kept`);
      break;
    }
    seenMem.add(key);
    memories.push({
      kind: e.label === "preference" ? "preference" : "fact",
      content,
      source: `${e.label.toUpperCase()}, line ${e.line}`,
    });
  }

  if (source === "hark" && memories.length === 0 && recognized)
    notes.push(
      "Hark keeps no memory in the EEA, the UK or Switzerland; tell your new bot what matters in chat",
    );
  if (source === "dots" && memories.length === 0 && recognized)
    notes.push(
      "ChatGPT Dots doesn't list its memories one by one; tell your new bot what matters in chat",
    );

  return {
    kind: source,
    name,
    description: about,
    persona_md: persona,
    autonomy,
    skills,
    routines,
    memories,
    connections,
    notes,
    recognized,
  };
}
