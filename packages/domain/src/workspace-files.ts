/**
 * Routines and skills as files (D-124). A workspace's routines and skills as a folder of Markdown
 * files, for export, import and git sync:
 *
 *   casama.json                         which folder is which bot
 *   <bot>/routines/<routine>.md         front matter (id, name, schedule, run_at, timezone,
 *                                        trigger, calendar/message/device, enabled, notify,
 *                                        ends_at, max_runs) + the instructions
 *   <bot>/skills/<name>/SKILL.md        a normal SKILL.md (+ id, enabled) and its files
 *   workspace/skills/<name>/SKILL.md    skills every bot in the workspace has
 */
import { isValidCron, isValidTimezone } from "./schedule.ts";
import { parseFrontMatter, SKILL_NAME } from "./skill-format.ts";

export const WORKSPACE_FOLDER = "workspace";
export const INDEX_FILE = "casama.json";

export const ROUTINE_FILE_TRIGGERS = [
  "schedule",
  "once",
  "webhook",
  "github",
  "calendar_event",
  "message",
  "device",
] as const;
export type RoutineFileTrigger = (typeof ROUTINE_FILE_TRIGGERS)[number];

/** The front matter key that holds an event trigger's settings (the API's Routine field). */
export const TRIGGER_CONFIG_KEY = {
  calendar_event: "calendar",
  message: "message",
  device: "device",
} as const;
type ConfigTrigger = keyof typeof TRIGGER_CONFIG_KEY;
export const hasTriggerConfig = (t: RoutineFileTrigger): t is ConfigTrigger =>
  t in TRIGGER_CONFIG_KEY;

export interface RoutineFile {
  id?: string;
  name: string;
  schedule: string | null;
  timezone: string;
  trigger: RoutineFileTrigger;
  /**
   * once: when it runs (ISO 8601). null or missing keeps the routine's pending run; null is
   * also what an export writes once it has run.
   */
  runAt?: string | null;
  /** calendar_event, message and device: the trigger's settings, as the API shows them. */
  triggerConfig?: Record<string, unknown>;
  /**
   * When it ends (D-262), for every trigger but once. Missing leaves the routine's end as it is;
   * null removes it.
   */
  endsAt?: string | null;
  /** How many more runs (D-262), 1–10,000. Missing leaves it; null removes it. */
  maxRuns?: number | null;
  enabled: boolean;
  notify: boolean;
  instructions: string;
}

export interface SkillFile {
  id?: string;
  name: string;
  description: string;
  enabled: boolean;
  body: string;
}

export class WorkspaceFileError extends Error {
  readonly path: string;
  constructor(path: string, message: string) {
    super(`${path}: ${message}`);
    this.path = path;
  }
}

/** A folder-safe name for a bot or routine. */
export const fileSlug = (s: string) =>
  s
    .toLowerCase()
    .normalize("NFKD")
    .replace(/[^\w\s-]/g, "")
    .trim()
    .replace(/[\s_]+/g, "-")
    .replace(/-+/g, "-")
    .slice(0, 60) || "item";

const yamlValue = (v: string) =>
  v === "" || /[:#\n"'{}[\],&*!|>%@`]|^\s|\s$/.test(v) ? JSON.stringify(v) : v;

/** A value written as is (an inline JSON map, which is also YAML). */
interface Raw {
  raw: string;
}

const front = (fields: Array<[string, string | number | boolean | Raw | null | undefined]>) =>
  `---\n${fields
    .filter(([, v]) => v !== undefined)
    .map(
      ([k, v]) =>
        `${k}: ${
          v === null
            ? "null"
            : typeof v === "object"
              ? v.raw
              : typeof v === "string"
                ? yamlValue(v)
                : String(v)
        }`,
    )
    .join("\n")}\n---\n`;

/** An event trigger's settings as one line of JSON, keys sorted so files don't churn. */
const configLine = (c: Record<string, unknown>): Raw => ({
  raw: JSON.stringify(
    Object.fromEntries(
      Object.entries(c)
        .filter(([, v]) => v !== undefined && v !== null)
        .sort(([a], [b]) => a.localeCompare(b)),
    ),
  ),
});

export function renderRoutineFile(r: RoutineFile) {
  const once = r.trigger === "once";
  const configKey = hasTriggerConfig(r.trigger) ? TRIGGER_CONFIG_KEY[r.trigger] : undefined;
  return `${front([
    ["id", r.id],
    ["name", r.name],
    ["schedule", r.schedule],
    ["run_at", once ? (r.runAt ?? null) : undefined],
    ["timezone", r.timezone],
    ["trigger", r.trigger],
    ...(configKey
      ? ([[configKey, configLine(r.triggerConfig ?? {})]] as Array<[string, Raw]>)
      : []),
    ["enabled", r.enabled],
    ["notify", r.notify],
    // A once routine ends after its run; every other routine says whether it ends, so that
    // removing the end in the file removes it in Casama.
    ["ends_at", once ? undefined : (r.endsAt ?? null)],
    ["max_runs", once ? undefined : (r.maxRuns ?? null)],
  ])}\n${r.instructions.trim()}\n`;
}

const bool = (v: string | undefined, dflt: boolean) =>
  v === undefined || v === "" ? dflt : v.trim().toLowerCase() === "true";
const split = (text: string, path: string) => {
  const m = /^﻿?---\r?\n([\s\S]*?)\r?\n---\r?\n?([\s\S]*)$/.exec(text);
  if (!m) throw new WorkspaceFileError(path, "must start with front matter between --- lines");
  return { meta: parseFrontMatter(m[1] ?? ""), body: (m[2] ?? "").trim() };
};
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;

/** undefined when the key is missing, null when it says null (or is empty), else the text. */
const optional = (meta: Record<string, string>, key: string) => {
  if (!(key in meta)) return undefined;
  const v = (meta[key] ?? "").trim();
  return v === "" || v === "null" || v === "~" ? null : v;
};

const dateField = (meta: Record<string, string>, key: string, path: string) => {
  const v = optional(meta, key);
  if (v == null) return v;
  const t = Date.parse(v);
  if (Number.isNaN(t))
    throw new WorkspaceFileError(path, `${key} must be a date and time, like 2027-03-31T17:00:00Z`);
  return new Date(t).toISOString();
};

const scalar = (v: string): unknown => {
  const t = v.trim();
  if (t === "true" || t === "false") return t === "true";
  if (/^-?\d+$/.test(t)) return Number(t);
  if (/^["']/.test(t)) {
    try {
      return t.startsWith('"') ? JSON.parse(t) : t.slice(1, -1).replace(/''/g, "'");
    } catch {
      return t;
    }
  }
  return t;
};

/**
 * An event trigger's settings: an inline JSON map (what export writes) or an indented YAML map
 * of plain values.
 */
const configField = (meta: Record<string, string>, key: string, path: string) => {
  const raw = (meta[key] ?? "").trim();
  if (!raw || raw === "null")
    throw new WorkspaceFileError(path, `a ${key} routine needs its ${key} settings`);
  let v: unknown;
  if (raw.startsWith("{")) {
    try {
      v = JSON.parse(raw);
    } catch {
      throw new WorkspaceFileError(path, `${key} isn't valid JSON`);
    }
  } else {
    const out: Record<string, unknown> = {};
    for (const line of raw.split(/\r?\n/)) {
      if (!line.trim() || line.trim().startsWith("#")) continue;
      const m = /^\s*([A-Za-z0-9_]+):\s*(.*)$/.exec(line);
      if (!m?.[1]) throw new WorkspaceFileError(path, `${key} must be a map of settings`);
      out[m[1]] = scalar(m[2] ?? "");
    }
    v = out;
  }
  if (!v || typeof v !== "object" || Array.isArray(v))
    throw new WorkspaceFileError(path, `${key} must be a map of settings`);
  return v as Record<string, unknown>;
};

export function parseRoutineFile(text: string, path: string): RoutineFile {
  const { meta, body } = split(text, path);
  const name = (meta.name ?? "").trim();
  if (!name || name.length > 120)
    throw new WorkspaceFileError(path, "needs a name (up to 120 characters)");
  if (!body) throw new WorkspaceFileError(path, "needs instructions after the front matter");
  if (body.length > 20_000)
    throw new WorkspaceFileError(path, "instructions are over 20,000 characters");
  const trigger = ((meta.trigger ?? "").trim() || "schedule") as RoutineFileTrigger;
  if (!ROUTINE_FILE_TRIGGERS.includes(trigger))
    throw new WorkspaceFileError(
      path,
      "trigger must be schedule, once, webhook, github, calendar_event, message or device",
    );
  const schedule = optional(meta, "schedule") ?? null;
  if (trigger === "schedule" && !schedule)
    throw new WorkspaceFileError(path, "a scheduled routine needs schedule (cron)");
  if (schedule && trigger !== "schedule")
    throw new WorkspaceFileError(
      path,
      `schedule is only for schedule triggers (this one is ${trigger}); set it to null`,
    );
  if (schedule && !isValidCron(schedule))
    throw new WorkspaceFileError(path, `"${schedule}" isn't a valid cron schedule`);
  const runAt = dateField(meta, "run_at", path);
  if (runAt && trigger !== "once")
    throw new WorkspaceFileError(path, "run_at is only for once triggers");
  const endsAt = dateField(meta, "ends_at", path);
  const rawMax = optional(meta, "max_runs");
  const maxRuns = rawMax == null ? rawMax : Number(rawMax);
  if (maxRuns != null && !(Number.isInteger(maxRuns) && maxRuns >= 1 && maxRuns <= 10_000))
    throw new WorkspaceFileError(path, "max_runs must be a whole number from 1 to 10,000");
  if (trigger === "once" && (endsAt || maxRuns != null))
    throw new WorkspaceFileError(
      path,
      "a once routine already ends after its run: remove ends_at and max_runs",
    );
  const triggerConfig = hasTriggerConfig(trigger)
    ? configField(meta, TRIGGER_CONFIG_KEY[trigger], path)
    : undefined;
  const timezone = (meta.timezone ?? "UTC").trim() || "UTC";
  if (!isValidTimezone(timezone))
    throw new WorkspaceFileError(path, `unknown timezone ${timezone}`);
  const id = meta.id?.trim();
  return {
    id: id && UUID.test(id) ? id : undefined,
    name,
    schedule,
    timezone,
    trigger,
    ...(trigger === "once" && runAt !== undefined ? { runAt } : {}),
    ...(triggerConfig ? { triggerConfig } : {}),
    ...(trigger !== "once" && endsAt !== undefined ? { endsAt } : {}),
    ...(trigger !== "once" && maxRuns !== undefined ? { maxRuns } : {}),
    enabled: bool(meta.enabled, true),
    notify: bool(meta.notify, true),
    instructions: body,
  };
}

export function renderSkillFile(s: SkillFile) {
  return `${front([
    ["name", s.name],
    ["description", s.description],
    ["id", s.id],
    ["enabled", s.enabled],
  ])}\n${s.body.trim()}\n`;
}

export function parseSkillFile(text: string, path: string): SkillFile {
  const { meta, body } = split(text, path);
  const name = (meta.name ?? "").trim();
  if (!SKILL_NAME.test(name))
    throw new WorkspaceFileError(path, "the skill name must be lowercase letters, digits, - or _");
  const folder = path.split("/").slice(-2, -1)[0];
  if (folder && folder !== name)
    throw new WorkspaceFileError(path, `the folder name must match the skill name (${name})`);
  const description = (meta.description ?? "").trim();
  if (!description) throw new WorkspaceFileError(path, "the skill needs a description");
  const id = meta.id?.trim();
  return {
    id: id && UUID.test(id) ? id : undefined,
    name,
    description: description.slice(0, 300),
    enabled: bool(meta.enabled, true),
    body: body.slice(0, 50_000),
  };
}

export interface FolderIndex {
  format: "casama.files";
  version: 1;
  /** Folder name → bot. */
  bots: Record<string, { id: string; name: string }>;
}

/** Reads casama.json; without one, folders are matched to bots by name. */
export function parseIndex(text: string | undefined): FolderIndex | null {
  if (!text) return null;
  try {
    const j = JSON.parse(text) as FolderIndex;
    return j && j.format === "casama.files" && j.bots && typeof j.bots === "object" ? j : null;
  } catch {
    return null;
  }
}

export interface ParsedWorkspaceFiles {
  routines: Array<{ folder: string; path: string; routine: RoutineFile }>;
  skills: Array<{
    folder: string;
    path: string;
    skill: SkillFile;
    files: Array<{ path: string; content: Uint8Array }>;
  }>;
  errors: string[];
}

/** Every routine and skill in a folder of files. Bad files are reported, not fatal. */
export function parseWorkspaceFiles(files: Map<string, Uint8Array>): ParsedWorkspaceFiles {
  const out: ParsedWorkspaceFiles = { routines: [], skills: [], errors: [] };
  const text = (b: Uint8Array) => new TextDecoder().decode(b);
  const skillDirs = new Set<string>();
  for (const [p, b] of files) {
    const r = /^([^/]+)\/routines\/[^/]+\.md$/.exec(p);
    if (r) {
      try {
        out.routines.push({
          folder: r[1] as string,
          path: p,
          routine: parseRoutineFile(text(b), p),
        });
      } catch (e) {
        out.errors.push((e as Error).message);
      }
      continue;
    }
    const s = /^([^/]+)\/skills\/([^/]+)\/SKILL\.md$/.exec(p);
    if (s) {
      const dir = p.slice(0, -"SKILL.md".length);
      skillDirs.add(dir);
      try {
        out.skills.push({
          folder: s[1] as string,
          path: p,
          skill: parseSkillFile(text(b), p),
          files: [],
        });
      } catch (e) {
        out.errors.push((e as Error).message);
      }
    }
  }
  for (const sk of out.skills) {
    const dir = sk.path.slice(0, -"SKILL.md".length);
    for (const [p, b] of files)
      if (p.startsWith(dir) && p !== sk.path)
        sk.files.push({ path: p.slice(dir.length), content: b });
  }
  out.routines.sort((a, b) => a.path.localeCompare(b.path));
  out.skills.sort((a, b) => a.path.localeCompare(b.path));
  return out;
}
