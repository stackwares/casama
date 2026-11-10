/**
 * Routines and skills as files (D-124). A workspace's routines and skills as a folder of Markdown
 * files, for export, import and git sync:
 *
 *   kasama.json                         which folder is which bot
 *   <bot>/routines/<routine>.md         front matter (id, name, schedule, timezone, trigger,
 *                                        enabled, notify) + the instructions
 *   <bot>/skills/<name>/SKILL.md        a normal SKILL.md (+ id, enabled) and its files
 *   workspace/skills/<name>/SKILL.md    skills every bot in the workspace has
 */
import { isValidCron, isValidTimezone } from "./schedule.ts";
import { parseFrontMatter, SKILL_NAME } from "./skill-format.ts";

export const WORKSPACE_FOLDER = "workspace";
export const INDEX_FILE = "kasama.json";

export interface RoutineFile {
  id?: string;
  name: string;
  schedule: string | null;
  timezone: string;
  trigger: "schedule" | "webhook" | "github";
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

const front = (fields: Array<[string, string | boolean | null | undefined]>) =>
  `---\n${fields
    .filter(([, v]) => v !== undefined)
    .map(
      ([k, v]) =>
        `${k}: ${v === null ? "null" : typeof v === "boolean" ? String(v) : yamlValue(v as string)}`,
    )
    .join("\n")}\n---\n`;

export function renderRoutineFile(r: RoutineFile) {
  return `${front([
    ["id", r.id],
    ["name", r.name],
    ["schedule", r.schedule],
    ["timezone", r.timezone],
    ["trigger", r.trigger],
    ["enabled", r.enabled],
    ["notify", r.notify],
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

export function parseRoutineFile(text: string, path: string): RoutineFile {
  const { meta, body } = split(text, path);
  const name = (meta.name ?? "").trim();
  if (!name || name.length > 120)
    throw new WorkspaceFileError(path, "needs a name (up to 120 characters)");
  if (!body) throw new WorkspaceFileError(path, "needs instructions after the front matter");
  if (body.length > 20_000)
    throw new WorkspaceFileError(path, "instructions are over 20,000 characters");
  const trigger = (meta.trigger ?? "schedule").trim() as RoutineFile["trigger"];
  if (!["schedule", "webhook", "github"].includes(trigger))
    throw new WorkspaceFileError(path, "trigger must be schedule, webhook or github");
  const rawSchedule = (meta.schedule ?? "").trim();
  const schedule = rawSchedule === "" || rawSchedule === "null" ? null : rawSchedule;
  if (trigger === "schedule" && !schedule)
    throw new WorkspaceFileError(path, "a scheduled routine needs schedule (cron)");
  if (schedule && !isValidCron(schedule))
    throw new WorkspaceFileError(path, `"${schedule}" isn't a valid cron schedule`);
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
  format: "kasama.files";
  version: 1;
  /** Folder name → bot. */
  bots: Record<string, { id: string; name: string }>;
}

/** Reads kasama.json; without one, folders are matched to bots by name. */
export function parseIndex(text: string | undefined): FolderIndex | null {
  if (!text) return null;
  try {
    const j = JSON.parse(text) as FolderIndex;
    return j && j.format === "kasama.files" && j.bots && typeof j.bots === "object" ? j : null;
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
