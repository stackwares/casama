/**
 * Import an agent (D-122): turns an OpenClaw or Hermes Agent folder into a Casama bot template
 * (persona, skills, routines, memories) plus the files nothing maps to. Built from each project's
 * public documentation of its folder layout; no code from either project.
 *
 * - OpenClaw workspace: SOUL.md (persona), AGENTS.md (operating instructions), IDENTITY.md (name),
 *   USER.md (about the person), MEMORY.md (long-term memory), memory/YYYY-MM-DD.md (daily notes),
 *   skills/<name>/SKILL.md; scheduled jobs in cron/jobs.json (older versions; newer ones keep
 *   them in a database, which isn't imported).
 * - Hermes Agent home: SOUL.md (persona), memories/MEMORY.md and memories/USER.md (entries split
 *   by §), skills/<category>/<name>/SKILL.md, cron/jobs.json.
 */
import { isValidCron } from "./schedule.ts";
import { parseFrontMatter, SKILL_NAME } from "./skill-format.ts";

export type AgentKind = "openclaw" | "hermes";

export interface ImportedSkill {
  name: string;
  description: string;
  body_md: string;
  files: Array<{ path: string; content_base64: string; executable?: boolean }>;
  source: string;
}
export interface ImportedRoutine {
  name: string;
  instructions_md: string;
  schedule_cron: string;
  source: string;
}
export interface ImportedMemory {
  kind: "fact" | "episode" | "preference";
  content: string;
  source: string;
}

export interface AgentImportPlan {
  kind: AgentKind;
  /** The folder inside the upload the agent lives in ("" or e.g. ".openclaw/"). */
  root: string;
  name: string;
  persona_md: string;
  skills: ImportedSkill[];
  routines: ImportedRoutine[];
  memories: ImportedMemory[];
  /** Files with no Casama equivalent: copied to ~/imported/ on the bot's computer. */
  leftovers: string[];
  /** Files never imported (secrets, settings, databases, logs), with why. */
  skipped: Array<{ path: string; reason: string }>;
  /** What couldn't be mapped exactly (paused jobs, one-off times, trimmed text). */
  notes: string[];
}

export class AgentImportError extends Error {}

const LIMITS = {
  persona: 20_000,
  memory: 8000,
  memories: 200,
  skills: 30,
  routines: 20,
  dailyNotes: 60,
};

const SKIP: Array<[RegExp, string]> = [
  [/(^|\/)\.env(\..*)?$/, "secrets"],
  [/(^|\/)auth\.json$/, "secrets"],
  [/(^|\/)credentials\//, "secrets"],
  [/(^|\/)openclaw\.json$/, "settings (may hold keys)"],
  [/(^|\/)config\.ya?ml$/, "settings (may hold keys)"],
  [/\.(sqlite|sqlite3|db)(-wal|-shm)?$/, "database"],
  [/(^|\/)(sessions|logs|state|agents)\//, "history and internal state"],
  [/(^|\/)cron\/(output|executions)/, "run history"],
  [/(^|\/)cron\/jobs-state\.json$/, "run history"],
  [/(^|\/)BOOTSTRAP\.md$/, "first-run script"],
  [/(^|\/)(\.git|node_modules|__pycache__)\//, "not needed"],
  [/(^|\/)\.DS_Store$/, "not needed"],
];

const text = (b: Uint8Array) => new TextDecoder().decode(b);
const b64 = (b: Uint8Array) => Buffer.from(b).toString("base64");

/** Strips a folder all files share (a ZIP of ".openclaw/" or "workspace/"), and finds the root. */
function rootOf(paths: string[]) {
  const markers = [
    "SOUL.md",
    "AGENTS.md",
    "IDENTITY.md",
    "memories/MEMORY.md",
    "memories/USER.md",
    "cron/jobs.json",
    "workspace/SOUL.md",
    "workspace/AGENTS.md",
  ];
  let best: string | null = null;
  for (const p of paths)
    for (const m of markers)
      if (p === m || p.endsWith(`/${m}`)) {
        const root = p.slice(0, p.length - m.length);
        if (best === null || root.length < best.length) best = root;
      }
  return best;
}

export function detectAgentKind(
  files: Map<string, Uint8Array>,
): { kind: AgentKind; root: string } | null {
  const paths = [...files.keys()];
  const root = rootOf(paths);
  if (root === null) return null;
  const has = (p: string) => files.has(root + p);
  if (
    has("memories/MEMORY.md") ||
    has("memories/USER.md") ||
    (has("SOUL.md") && has("config.yaml"))
  )
    return { kind: "hermes", root };
  const jobs = files.get(`${root}cron/jobs.json`);
  if (jobs && /"prompt"\s*:/.test(text(jobs)) && !/"payload"\s*:/.test(text(jobs)))
    return { kind: "hermes", root };
  return { kind: "openclaw", root };
}

/** Bullet items or paragraphs of a Markdown note, without headings. */
export function splitNote(md: string) {
  const out: string[] = [];
  let cur: string[] = [];
  const flush = () => {
    const t = cur.join("\n").trim();
    if (t.length >= 3) out.push(t);
    cur = [];
  };
  for (const line of md.split(/\r?\n/)) {
    if (/^\s*#{1,6}\s/.test(line) || /^\s*(---|\*\*\*)\s*$/.test(line)) {
      flush();
      continue;
    }
    if (/^\s*([-*+]|\d+[.)])\s+/.test(line)) {
      flush();
      cur.push(line.replace(/^\s*([-*+]|\d+[.)])\s+/, ""));
    } else if (line.trim() === "") flush();
    else cur.push(line.trim());
  }
  flush();
  return out;
}

/** "every 2h", "every 30m", "daily at 7am", "every day at 18:30", or a cron string → cron. */
export function cronFromText(s: string): string | null {
  const t = s.trim().toLowerCase();
  if (isValidCron(t)) return t;
  let m = /^every\s+(\d+)\s*(m|min|mins|minutes?|h|hr|hrs|hours?)$/.exec(t);
  if (m) {
    const n = Number(m[1]);
    if (m[2]?.startsWith("m"))
      return n > 0 && n < 60 && 60 % n === 0 ? `*/${n} * * * *` : n === 60 ? "0 * * * *" : null;
    if (n === 1) return "0 * * * *";
    return n > 0 && n < 24 && 24 % n === 0 ? `0 */${n} * * *` : n === 24 ? "0 0 * * *" : null;
  }
  m = /^(?:daily|every\s+day)(?:\s+at\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?)?$/.exec(t);
  if (m) {
    let h = Number(m[1] ?? 9);
    if (m[3] === "pm" && h < 12) h += 12;
    if (m[3] === "am" && h === 12) h = 0;
    return h < 24 ? `${Number(m[2] ?? 0)} ${h} * * *` : null;
  }
  return null;
}

/** Milliseconds between runs → cron, when it divides an hour or a day evenly. */
const cronFromEvery = (ms: number) => {
  const min = ms / 60_000;
  if (!Number.isInteger(min) || min <= 0) return null;
  return cronFromText(min % 60 === 0 ? `every ${min / 60}h` : `every ${min}m`);
};

const skillName = (raw: string) =>
  raw
    .toLowerCase()
    .replace(/[^a-z0-9_-]+/g, "-")
    .replace(/^[^a-z0-9]+/, "")
    .slice(0, 63) || "imported-skill";

function readSkills(
  files: Map<string, Uint8Array>,
  root: string,
  used: Set<string>,
  notes: string[],
) {
  const skills: ImportedSkill[] = [];
  const mds = [...files.keys()]
    .filter(
      (p) => p.startsWith(root) && /(^|\/)skills\/(.+\/)?SKILL\.md$/.test(p.slice(root.length)),
    )
    .sort();
  for (const p of mds) {
    const folder = p.slice(0, -"SKILL.md".length);
    const raw = text(files.get(p) as Uint8Array);
    const fm = /^﻿?---\r?\n([\s\S]*?)\r?\n---\r?\n?([\s\S]*)$/.exec(raw);
    const meta = fm ? parseFrontMatter(fm[1] ?? "") : {};
    const body = (fm ? (fm[2] ?? "") : raw).trim();
    const folderName = folder.replace(/\/$/, "").split("/").pop() ?? "skill";
    let name = SKILL_NAME.test(meta.name ?? "")
      ? (meta.name as string)
      : skillName(meta.name || folderName);
    if (used.has(name)) {
      let i = 2;
      while (used.has(`${name}-${i}`)) i++;
      name = `${name}-${i}`;
    }
    const description = (
      meta.description ||
      body.split("\n").find((l) => l.trim() && !l.startsWith("#")) ||
      name
    )
      .trim()
      .slice(0, 300);
    const extra = [...files.keys()].filter((f) => f.startsWith(folder) && f !== p);
    if (extra.length > 60) {
      notes.push(`Skill ${name}: kept the first 60 of its ${extra.length} files`);
      extra.length = 60;
    }
    for (const f of extra) used.add(f);
    used.add(p);
    used.add(name);
    skills.push({
      name,
      description,
      body_md: body.slice(0, 50_000),
      files: extra.map((f) => ({
        path: f.slice(folder.length),
        content_base64: b64(files.get(f) as Uint8Array),
      })),
      source: p.slice(root.length),
    });
  }
  return skills;
}

type Job = Record<string, unknown>;
const jobsOf = (raw: unknown): Job[] => {
  const list = Array.isArray(raw)
    ? raw
    : raw && typeof raw === "object" && Array.isArray((raw as { jobs?: unknown }).jobs)
      ? (raw as { jobs: unknown[] }).jobs
      : [];
  return list.filter((j): j is Job => !!j && typeof j === "object");
};
const str = (v: unknown) => (typeof v === "string" ? v : undefined);

function readJobs(
  files: Map<string, Uint8Array>,
  path: string,
  kind: AgentKind,
  notes: string[],
): ImportedRoutine[] {
  const f = files.get(path);
  if (!f) return [];
  let raw: unknown;
  try {
    raw = JSON.parse(text(f));
  } catch {
    notes.push("cron/jobs.json isn't valid JSON; no routines imported");
    return [];
  }
  const out: ImportedRoutine[] = [];
  for (const j of jobsOf(raw)) {
    const name = (str(j.name) ?? str(j.id) ?? str(j.jobId) ?? "Imported routine").slice(0, 120);
    const sched = (j.schedule && typeof j.schedule === "object" ? j.schedule : {}) as Record<
      string,
      unknown
    >;
    let cron: string | null = null;
    let instructions: string | undefined;
    if (kind === "openclaw") {
      const payload = (j.payload && typeof j.payload === "object" ? j.payload : {}) as Record<
        string,
        unknown
      >;
      instructions = str(payload.message) ?? str(payload.text);
      if (sched.kind === "cron")
        cron = str(sched.expr) && isValidCron(sched.expr as string) ? (sched.expr as string) : null;
      else if (sched.kind === "every" && typeof sched.everyMs === "number")
        cron = cronFromEvery(sched.everyMs);
      else if (sched.kind === "at" || j.at) {
        notes.push(`"${name}" ran once at a set time; not imported as a routine`);
        continue;
      }
    } else {
      instructions = str(j.prompt);
      cron =
        (str(sched.expr) && cronFromText(sched.expr as string)) ||
        (str(sched.display) && cronFromText(sched.display as string)) ||
        null;
      if (j.state === "completed") {
        notes.push(`"${name}" had already finished; not imported`);
        continue;
      }
    }
    if (!instructions?.trim()) {
      notes.push(`"${name}" has no instructions; not imported`);
      continue;
    }
    if (!cron) {
      notes.push(`"${name}": its schedule couldn't be read; not imported`);
      continue;
    }
    if (j.enabled === false) {
      notes.push(`"${name}" was paused; not imported (add it again if you want it)`);
      continue;
    }
    const tz = str(sched.tz) ?? str(j.timezone);
    if (tz) notes.push(`"${name}" used the ${tz} time zone; it now runs in yours`);
    out.push({
      name,
      instructions_md: instructions.slice(0, 20_000),
      schedule_cron: cron,
      source: path,
    });
  }
  return out;
}

/** Builds the import plan from a folder's files (paths use "/"). */
export function planAgentImport(files: Map<string, Uint8Array>): AgentImportPlan {
  const found = detectAgentKind(files);
  if (!found)
    throw new AgentImportError(
      "This doesn't look like an OpenClaw or Hermes Agent folder (no SOUL.md, AGENTS.md or memories/ found).",
    );
  const { kind, root } = found;
  const notes: string[] = [];
  const used = new Set<string>();
  const read = (p: string) => {
    const f = files.get(root + p);
    if (!f) return null;
    used.add(root + p);
    return text(f).trim();
  };
  // OpenClaw's home folder keeps the workspace in workspace/.
  const ws =
    kind === "openclaw" && [...files.keys()].some((p) => p.startsWith(`${root}workspace/`))
      ? "workspace/"
      : "";
  const memories: ImportedMemory[] = [];
  const addAll = (kindOf: ImportedMemory["kind"], items: string[], source: string) => {
    for (const c of items)
      memories.push({ kind: kindOf, content: c.slice(0, LIMITS.memory), source });
  };
  let name = kind === "openclaw" ? "Imported OpenClaw agent" : "Imported Hermes agent";
  const parts: string[] = [];
  const soul = read(`${ws}SOUL.md`);
  if (soul) parts.push(soul);
  const agents =
    read(`${ws}AGENTS.md`) ?? (kind === "hermes" ? (read(".hermes.md") ?? null) : null);
  if (agents) parts.push(`## How you work (imported)\n\n${agents}`);
  if (kind === "openclaw") {
    const identity = read(`${ws}IDENTITY.md`);
    const n = identity && /\bname\b\**\s*[:：]\s*\**\s*([^\n*]{1,80})/i.exec(identity);
    if (n?.[1]?.trim()) name = n[1].trim();
    if (identity) parts.unshift(`## Identity (imported)\n\n${identity}`);
    const user = read(`${ws}USER.md`);
    if (user) addAll("preference", splitNote(user), `${ws}USER.md`);
    const mem = read(`${ws}MEMORY.md`);
    if (mem) addAll("fact", splitNote(mem), `${ws}MEMORY.md`);
    const daily = [...files.keys()]
      .map((p) => p.slice(root.length))
      .filter((p) => new RegExp(`^${ws}memory/\\d{4}-\\d{2}-\\d{2}\\.md$`).test(p))
      .sort()
      .reverse();
    if (daily.length > LIMITS.dailyNotes)
      notes.push(
        `Kept the newest ${LIMITS.dailyNotes} of ${daily.length} daily notes as memories; the rest are in ~/imported/`,
      );
    for (const p of daily.slice(0, LIMITS.dailyNotes)) {
      const t = read(p);
      if (t)
        memories.push({
          kind: "episode",
          content: `Notes from ${p.slice(-13, -3)}:\n${t}`.slice(0, LIMITS.memory),
          source: p,
        });
    }
  } else {
    for (const [file, k] of [
      ["memories/MEMORY.md", "fact"],
      ["memories/USER.md", "preference"],
    ] as const) {
      const t = read(file);
      if (t)
        addAll(
          k,
          t
            .split("§")
            .map((e) => e.trim())
            .filter((e) => e.length >= 3),
          file,
        );
    }
  }
  let persona = parts.join("\n\n");
  if (persona.length > LIMITS.persona) {
    notes.push(
      "The persona was longer than 20,000 characters and was trimmed; the full files are in ~/imported/",
    );
    persona = persona.slice(0, LIMITS.persona);
    for (const p of [`${ws}SOUL.md`, `${ws}AGENTS.md`]) used.delete(root + p);
  }
  const skillsUsed = new Set<string>();
  let skills = readSkills(files, root + ws, skillsUsed, notes);
  for (const s of skillsUsed) if (s.includes("/")) used.add(s);
  if (kind === "openclaw" && ws)
    skills.push(
      ...readSkills(files, root, skillsUsed, notes).filter(
        (s) => !s.source.startsWith("workspace/"),
      ),
    );
  for (const s of skillsUsed) if (s.includes("/")) used.add(s);
  if (skills.length > LIMITS.skills) {
    notes.push(
      `Imported the first ${LIMITS.skills} of ${skills.length} skills; the rest are in ~/imported/`,
    );
    for (const s of skills.slice(LIMITS.skills)) used.delete(root + ws + s.source);
    skills = skills.slice(0, LIMITS.skills);
  }
  const jobsPath = `${root}cron/jobs.json`;
  let routines = readJobs(files, jobsPath, kind, notes);
  if (files.has(jobsPath)) used.add(jobsPath);
  if (routines.length > LIMITS.routines) {
    notes.push(`Imported the first ${LIMITS.routines} of ${routines.length} routines`);
    routines = routines.slice(0, LIMITS.routines);
  }
  if (memories.length > LIMITS.memories) {
    notes.push(`Imported ${LIMITS.memories} of ${memories.length} memories`);
    memories.length = LIMITS.memories;
  }
  if (kind === "openclaw" && files.has(`${root}${ws}HEARTBEAT.md`))
    notes.push(
      "HEARTBEAT.md (a periodic checklist) is in ~/imported/; make it a routine if you still want it",
    );
  const skipped: AgentImportPlan["skipped"] = [];
  const leftovers: string[] = [];
  for (const p of files.keys()) {
    if (used.has(p)) continue;
    const rel = p.startsWith(root) ? p.slice(root.length) : p;
    const skip = SKIP.find(([re]) => re.test(rel));
    if (skip) skipped.push({ path: rel, reason: skip[1] });
    else leftovers.push(rel);
  }
  return {
    kind,
    root,
    name: name.slice(0, 80),
    persona_md: persona,
    skills,
    routines,
    memories,
    leftovers: leftovers.sort(),
    skipped,
    notes,
  };
}

// ---------------------------------------------------------------------------
// ChatGPT or Claude memory, pasted back from a prompt
// ---------------------------------------------------------------------------

export const MEMORY_EXPORT_PROMPT = `Please list everything you remember about me from our past conversations and your saved memory. Reply with only the list, one item per line, in exactly this format and nothing else:

FACT: <something true about me, my work, my people or my things>
PREFERENCE: <how I like things done, my tastes, or how I want you to answer>

Write each item as a short standalone sentence about me. Don't number the lines or add headings.`;

/** Parses the answer to MEMORY_EXPORT_PROMPT; unlabeled lines become facts. */
export function parseMemoryExport(
  answer: string,
): Array<{ kind: "fact" | "preference"; content: string }> {
  const out: Array<{ kind: "fact" | "preference"; content: string }> = [];
  const seen = new Set<string>();
  for (const raw of answer.split(/\r?\n/)) {
    const line = raw
      .replace(/\*\*/g, "")
      .replace(/^\s*([-*•]|\d+[.)])\s+/, "")
      .trim();
    if (!line || /^```/.test(line)) continue;
    const m = /^(fact|preference|pref)\s*[:：-]\s*(.+)$/i.exec(line);
    const kind = m ? (m[1]?.toLowerCase().startsWith("pref") ? "preference" : "fact") : "fact";
    const content = (m ? (m[2] ?? "") : line).trim().slice(0, 8000);
    if (content.length < 3 || /^(here('| i)s|sure|i remember)\b.*:$/i.test(content)) continue;
    const key = content.toLowerCase();
    if (seen.has(key)) continue;
    seen.add(key);
    out.push({ kind, content });
  }
  return out.slice(0, 500);
}
