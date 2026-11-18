// SPDX-License-Identifier: Apache-2.0
// A shared format, also used by the Apache-2.0 SDKs and tools (LICENSING.md).
/**
 * Packs (docs/PLUGINS-AND-PACKS-PLAN.md): a plugin that brings a setup. Agent Plugins 1.0 gives
 * each app a folder named after its reverse domain; Casama's is `com.casama/`. A plugin with
 * `com.casama/pack.json` also brings bots, routines, apps and looks, each in the gallery's own
 * format, plus install questions. Other apps that read the format use its skills and tool servers
 * and skip the folder.
 *
 * Pure checks: `casama-plugin-check`, the gallery checks and the server all run them, so what was
 * checked before publishing is what installs. Imports nothing outside Node, so the checker runs
 * with plain Node and nothing installed.
 */

import type { CheckedPlugin } from "./agent-plugins.ts";
import { APP_CATALOG } from "./apps.ts";
import { cronRunsPerWeek } from "./cron.ts";
import { lineDiff } from "./diff.ts";
import {
  checkSchemeDocument,
  checkThemeDocument,
  checkWallpaperDocument,
  type GalleryInput,
  galleryHasScripts,
  parseGalleryInputs,
} from "./gallery.ts";
import { checkAppDocument, type GalleryAppDocument } from "./gallery-apps.ts";
import { fillGalleryText, galleryInputDefaults, galleryPlaceholders } from "./gallery-catalog.ts";
import { checkBotDocument, checkRoutineDocument, GALLERY_MASCOTS } from "./gallery-content.ts";
import type { TemplateCategory } from "./templates.ts";

/** Casama's folder inside a plugin, and the file that makes the plugin a pack. */
export const PACK_DIR = "com.casama";
export const PACK_FILE = `${PACK_DIR}/pack.json`;
export const PACK_FORMAT = "casama.pack";
export const PACK_VERSION = 1;

export const PACK_LIMITS = {
  bots: 5,
  skills: 30,
  routines: 20,
  apps: 12,
  looks: 12,
  includes: 12,
  inputs: 6,
  examples: 3,
  rules: 20,
  knowledge: 5,
  knowledge_pages: 200,
} as const;

/** Kinds a pack can name from the gallery. A plugin can also be named by link and commit. */
export const PACK_INCLUDE_TYPES = [
  "skill",
  "app",
  "routine",
  "bot",
  "theme",
  "scheme",
  "wallpaper",
  "plugin",
] as const;
export type PackIncludeType = (typeof PACK_INCLUDE_TYPES)[number];

export type PackInclude =
  | { type: PackIncludeType; id: string }
  | { type: "plugin"; url: string; commit: string };

export const PACK_LOOK_TYPES = ["theme", "scheme", "wallpaper"] as const;
export type PackLookType = (typeof PACK_LOOK_TYPES)[number];

export interface PackDocument {
  /** The name people see ("Founder kit"); the plugin's `name` stays the pack's identity. */
  title: string | null;
  icon: string;
  summary: string;
  inputs: GalleryInput[];
  needs: { apps: string[] };
  includes: PackInclude[];
  workspace_skills: string[];
  examples: string[];
}

export interface PackBot {
  /** The file's name without `.json`. */
  id: string;
  name: string;
  description: string;
  category: TemplateCategory;
  icon: string;
  mascot: string;
  persona: string;
  starters: string[];
  autonomy: "ask_always" | "ask_risky";
  /** Folder names under `skills/`. */
  skills: string[];
  /** Routine ids under `com.casama/routines/`. */
  routines: string[];
  /** Server keys in `mcp.json`. */
  tools: string[];
  /** Rules that only narrow what the bot may do: ask first, or hand off to a person. */
  rules: PackRule[];
  /** Websites and GitHub repositories the bot reads, synced into its knowledge. */
  knowledge: PackKnowledge[];
}

export interface PackRule {
  match_kind: "tool" | "group" | "category";
  match_value: string;
  rule: "ask" | "hand_off";
}

export interface PackKnowledge {
  kind: "website" | "github";
  name: string;
  url: string;
  /** Websites: pages read at most (20 when unset). */
  max_pages: number;
}

export interface PackRoutine {
  id: string;
  name: string;
  description: string;
  category: TemplateCategory;
  icon: string;
  instructions_md: string;
  schedule_cron: string;
}

export interface PackApp {
  id: string;
  name: string;
  doc: GalleryAppDocument;
  logo?: string;
}

export interface PackLook {
  type: PackLookType;
  id: string;
  name: string;
  document: Record<string, unknown>;
}

/** What a pack can reach, worked out from its files, not claimed by its author. */
export interface PackReach {
  runs_code: boolean;
  computer: boolean;
  hosts: string[];
  secrets: string[];
  settings: string[];
  /** Scheduled runs a week, with the questions' defaults. */
  runs_per_week: number;
  /** Computers its local tool servers run on (one per bot that gets them). */
  computers: number;
  /** Knowledge sources its bots bring, and the most pages they read (each sync costs a little). */
  knowledge_sources: number;
  knowledge_pages: number;
}

export interface CheckedPack {
  document: PackDocument;
  bots: PackBot[];
  routines: PackRoutine[];
  apps: PackApp[];
  looks: PackLook[];
  /** Skills that go to the whole workspace: named in `workspace_skills`, or named by no bot. */
  workspaceSkills: string[];
  reach: PackReach;
  warnings: string[];
}

/** An app a pack's app must not pretend to be. */
export interface KnownApp {
  id: string;
  name: string;
  url: string;
}

export class PackError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "PackError";
  }
}

const ID = /^[a-z0-9][a-z0-9-]{0,62}$/;
const ICON = /^[a-z0-9][a-z0-9-]{0,39}$/;
const COMMIT = /^[0-9a-f]{40}$/;
const GITHUB_URL =
  /^https:\/\/github\.com\/[A-Za-z0-9_.-]{1,100}\/[A-Za-z0-9_.-]{1,100}(\/tree\/[^/\s]{1,200}(\/[^\s]{1,300})?)?\/?$/;

const isRecord = (v: unknown): v is Record<string, unknown> =>
  typeof v === "object" && v !== null && !Array.isArray(v);

function text(v: unknown, max: number, min = 1): string | undefined {
  if (typeof v !== "string") return undefined;
  const t = v.trim();
  return t.length >= min && t.length <= max ? t : undefined;
}

function json(files: Map<string, string>, path: string, warnings: string[]): unknown {
  const t = files.get(path);
  if (t === undefined) return undefined;
  try {
    return JSON.parse(t);
  } catch {
    warnings.push(`Skipped ${path}: not valid JSON`);
    return undefined;
  }
}

/** Ids from a list of strings, keeping only valid, known ones (a warning for each other). */
function names(
  raw: unknown,
  label: string,
  known: Set<string>,
  what: string,
  warnings: string[],
): string[] {
  if (raw === undefined) return [];
  if (!Array.isArray(raw)) {
    warnings.push(`${label} must be a list; ignored`);
    return [];
  }
  const out: string[] = [];
  for (const x of raw) {
    if (typeof x !== "string" || !known.has(x)) warnings.push(`${label}: no ${what} ${String(x)}`);
    else if (!out.includes(x)) out.push(x);
  }
  return out;
}

/**
 * The name people see: pack.json's `title`, else the plugin's name made readable
 * ("meetings-handled" → "Meetings handled").
 */
export function packTitle(doc: { title?: string | null } | null | undefined, name: string): string {
  if (doc?.title) return doc.title;
  const words = name.replace(/[-_.]+/g, " ").trim();
  return words ? words[0]?.toUpperCase() + words.slice(1) : name;
}

/** Checks `com.casama/pack.json`. Throws PackError when the file can't be a pack at all. */
export function checkPackDocument(raw: unknown, warnings: string[] = []): PackDocument {
  if (!isRecord(raw)) throw new PackError("pack.json must be a JSON object");
  if (raw.format !== PACK_FORMAT) throw new PackError(`pack.json format must be "${PACK_FORMAT}"`);
  if (raw.version !== PACK_VERSION)
    throw new PackError(`pack.json version ${String(raw.version)} isn't one Casama reads (1)`);
  const allowed = [
    "format",
    "version",
    "title",
    "icon",
    "summary",
    "inputs",
    "needs",
    "includes",
    "workspace_skills",
    "examples",
  ];
  for (const k of Object.keys(raw))
    if (!allowed.includes(k)) warnings.push(`pack.json: ignored unknown field ${k}`);
  const summary = text(raw.summary, 160);
  if (!summary) throw new PackError("pack.json needs a summary of 1 to 160 characters");
  let title: string | null = null;
  if (raw.title !== undefined) {
    title = text(raw.title, 64) ?? null;
    if (!title)
      warnings.push("pack.json: title must be 1 to 64 characters; using the plugin's name");
  }
  let icon = "package";
  if (raw.icon !== undefined) {
    if (typeof raw.icon === "string" && ICON.test(raw.icon)) icon = raw.icon;
    else warnings.push("pack.json: icon must be a Lucide icon name; using package");
  }
  let inputs: GalleryInput[] = [];
  if (raw.inputs !== undefined) {
    const errors: string[] = [];
    if (Array.isArray(raw.inputs) && raw.inputs.length === 0) inputs = [];
    else inputs = parseGalleryInputs(raw.inputs, errors) ?? [];
    if (errors.length) throw new PackError(`pack.json inputs: ${errors.join("; ")}`);
  }
  const needs = { apps: [] as string[] };
  if (raw.needs !== undefined) {
    const apps = isRecord(raw.needs) ? raw.needs.apps : undefined;
    if (
      !isRecord(raw.needs) ||
      Object.keys(raw.needs).some((k) => k !== "apps") ||
      (apps !== undefined &&
        !(
          Array.isArray(apps) &&
          apps.length <= 10 &&
          apps.every((a) => typeof a === "string" && /^[a-z0-9][a-z0-9_.:-]{0,80}$/.test(a))
        ))
    )
      warnings.push("pack.json: needs must be { apps: [up to 10 app ids] }; ignored");
    else needs.apps = [...new Set((apps as string[] | undefined) ?? [])];
  }
  const includes: PackInclude[] = [];
  if (raw.includes !== undefined) {
    if (!Array.isArray(raw.includes) || raw.includes.length > PACK_LIMITS.includes)
      throw new PackError(`pack.json includes must be at most ${PACK_LIMITS.includes} items`);
    raw.includes.forEach((x, i) => {
      const at = `pack.json includes[${i}]`;
      if (!isRecord(x) || !PACK_INCLUDE_TYPES.includes(x.type as PackIncludeType)) {
        warnings.push(`${at}: needs a type (${PACK_INCLUDE_TYPES.join(", ")}); skipped`);
        return;
      }
      if (x.type === "plugin" && x.url !== undefined) {
        const url = typeof x.url === "string" && GITHUB_URL.test(x.url) ? x.url : undefined;
        const commit = typeof x.commit === "string" && COMMIT.test(x.commit) ? x.commit : undefined;
        if (!url || !commit || Object.keys(x).some((k) => !["type", "url", "commit"].includes(k)))
          warnings.push(`${at}: a plugin needs a github.com url and its full commit; skipped`);
        else if (includes.some((y) => "url" in y && y.url === url))
          warnings.push(`${at}: listed twice; skipped`);
        else includes.push({ type: "plugin", url, commit });
        return;
      }
      if (
        typeof x.id !== "string" ||
        !/^([a-z0-9-]{1,40}:)?[a-z0-9][a-z0-9-]{0,62}$/.test(x.id) ||
        Object.keys(x).some((k) => k !== "type" && k !== "id")
      ) {
        warnings.push(`${at}: needs { type, id } of a gallery item; skipped`);
        return;
      }
      if (includes.some((y) => "id" in y && y.type === x.type && y.id === x.id))
        warnings.push(`${at}: listed twice; skipped`);
      else includes.push({ type: x.type as PackIncludeType, id: x.id });
    });
  }
  let examples: string[] = [];
  if (raw.examples !== undefined) {
    const list = Array.isArray(raw.examples) ? raw.examples.map((e) => text(e, 160)) : [];
    if (!list.length || list.length > PACK_LIMITS.examples || list.some((e) => !e))
      warnings.push("pack.json: examples must be 1 to 3 prompts of up to 160 characters; ignored");
    else examples = list as string[];
  }
  const workspace_skills = Array.isArray(raw.workspace_skills)
    ? raw.workspace_skills.filter((s): s is string => typeof s === "string")
    : [];
  return { title, icon, summary, inputs, needs, includes, workspace_skills, examples };
}

function hostOf(url: string) {
  try {
    return new URL(url).hostname.toLowerCase();
  } catch {
    return "";
  }
}

/**
 * Checks the `com.casama/` folder of a plugin that was already checked (`checkPlugin`). Returns
 * undefined when the plugin has no `pack.json`. A broken `pack.json` makes the plugin a plain
 * plugin, with a warning; a broken item is skipped with a warning.
 */
export function checkPack(
  files: Map<string, string>,
  plugin: Pick<CheckedPlugin, "skills" | "servers" | "secrets" | "hosts"> & {
    settings?: { name: string }[];
  },
  opts: { knownApps?: KnownApp[]; skillFiles?: Map<string, string[]> } = {},
): CheckedPack | undefined {
  const warnings: string[] = [];
  const raw = json(files, PACK_FILE, warnings);
  if (raw === undefined) {
    if (files.has(PACK_FILE)) throw new PackError("com.casama/pack.json isn't valid JSON");
    return undefined;
  }
  const document = checkPackDocument(raw, warnings);
  const skillNames = new Set(plugin.skills.map((s) => s.name));
  const serverKeys = new Set(plugin.servers.map((s) => s.key));
  const under = (dir: string) =>
    [...files.keys()]
      .filter((p) => p.startsWith(`${PACK_DIR}/${dir}/`))
      .sort((a, b) => {
        const x = a.replace(/\.json$/, "");
        const y = b.replace(/\.json$/, "");
        return x < y ? -1 : x > y ? 1 : 0;
      });

  // ---- routines (before bots, which name them)
  const routines: PackRoutine[] = [];
  for (const path of under("routines")) {
    const m = /^com\.casama\/routines\/([^/]+)\.json$/.exec(path);
    if (!m) continue;
    const id = m[1] as string;
    if (!ID.test(id)) {
      warnings.push(`Skipped ${path}: the file name must be lowercase letters, digits and dashes`);
      continue;
    }
    if (routines.length >= PACK_LIMITS.routines) {
      warnings.push(`Skipped ${path}: a pack holds at most ${PACK_LIMITS.routines} routines`);
      continue;
    }
    const r = json(files, path, warnings);
    if (!isRecord(r)) {
      if (r !== undefined) warnings.push(`Skipped ${path}: must be an object`);
      continue;
    }
    const { name, ...rest } = r;
    const n = text(name, 120);
    // Placeholders are checked against the questions below; the checker sees the defaults.
    const filled = fillTemplate(rest, ["instructions_md", "schedule_cron"], document.inputs);
    const { doc, errors } = checkRoutineDocument(filled);
    if (!n) errors.push("name must be 1 to 120 characters");
    if (!doc || errors.length) {
      warnings.push(`Skipped ${path}: ${errors.join("; ")}`);
      continue;
    }
    routines.push({
      id,
      name: n as string,
      ...doc,
      instructions_md: rest.instructions_md as string,
      schedule_cron: rest.schedule_cron as string,
    });
  }
  const routineIds = new Set(routines.map((r) => r.id));

  // ---- bots
  const bots: PackBot[] = [];
  for (const path of under("bots")) {
    const m = /^com\.casama\/bots\/([^/]+)\.json$/.exec(path);
    if (!m) continue;
    const id = m[1] as string;
    if (!ID.test(id)) {
      warnings.push(`Skipped ${path}: the file name must be lowercase letters, digits and dashes`);
      continue;
    }
    if (bots.length >= PACK_LIMITS.bots) {
      warnings.push(`Skipped ${path}: a pack holds at most ${PACK_LIMITS.bots} bots`);
      continue;
    }
    const b = json(files, path, warnings);
    if (!isRecord(b)) {
      if (b !== undefined) warnings.push(`Skipped ${path}: must be an object`);
      continue;
    }
    const { name, skills, routines: rs, tools, autonomy, rules, knowledge, ...rest } = b;
    const n = text(name, 80);
    // A pack never raises its own trust: autonomous becomes ask-before-risky (principle 7).
    let level = autonomy;
    if (autonomy === "autonomous") {
      warnings.push(`${path}: a pack's bot asks before risky actions at most; autonomy lowered`);
      level = "ask_risky";
    }
    const filled = fillTemplate(
      { ...rest, autonomy: level },
      ["persona", "starters"],
      document.inputs,
    );
    const { doc, errors } = checkBotDocument(filled);
    if (!n) errors.push("name must be 1 to 80 characters");
    if (!doc || errors.length) {
      warnings.push(`Skipped ${path}: ${errors.join("; ")}`);
      continue;
    }
    bots.push({
      id,
      name: n as string,
      description: doc.description,
      category: doc.category,
      icon: doc.icon,
      mascot: GALLERY_MASCOTS.includes(doc.mascot as never) ? doc.mascot : "cool",
      persona: rest.persona as string,
      starters: (rest.starters as string[] | undefined) ?? [],
      autonomy: doc.autonomy as PackBot["autonomy"],
      skills: names(skills, `${path} skills`, skillNames, "skill", warnings),
      routines: names(rs, `${path} routines`, routineIds, "routine", warnings),
      tools: names(tools, `${path} tools`, serverKeys, "tool server", warnings),
      rules: packRules(rules, path, warnings),
      knowledge: packKnowledge(knowledge, path, warnings),
    });
  }

  // ---- apps
  const known = opts.knownApps ?? APP_CATALOG.map((a) => ({ id: a.id, name: a.name, url: a.url }));
  const apps: PackApp[] = [];
  for (const path of under("apps")) {
    const m = /^com\.casama\/apps\/([^/]+)\/app\.json$/.exec(path);
    if (!m) continue;
    const id = m[1] as string;
    if (!ID.test(id)) {
      warnings.push(
        `Skipped ${path}: the folder name must be lowercase letters, digits and dashes`,
      );
      continue;
    }
    if (apps.length >= PACK_LIMITS.apps) {
      warnings.push(`Skipped ${path}: a pack holds at most ${PACK_LIMITS.apps} apps`);
      continue;
    }
    const a = json(files, path, warnings);
    if (!isRecord(a)) {
      if (a !== undefined) warnings.push(`Skipped ${path}: must be an object`);
      continue;
    }
    const { name, ...rest } = a;
    const n = text(name, 60);
    const { doc, errors } = checkAppDocument(rest);
    if (!n) errors.push("name must be 1 to 60 characters");
    if (doc && n) {
      // A stranger's server can't wear a known app's name (plan §9.2).
      const host = hostOf(doc.url);
      const twin = known.find(
        (k) => k.name.trim().toLowerCase() === n.toLowerCase() && hostOf(k.url) !== host,
      );
      if (twin) errors.push(`"${n}" is ${twin.name}'s name, but this app talks to ${host}`);
    }
    if (!doc || errors.length) {
      warnings.push(`Skipped ${path}: ${errors.join("; ")}`);
      continue;
    }
    const logo = files.get(`${PACK_DIR}/apps/${id}/logo.svg`);
    apps.push({ id, name: n as string, doc, ...(logo ? { logo } : {}) });
  }

  // ---- looks
  const looks: PackLook[] = [];
  for (const type of PACK_LOOK_TYPES) {
    for (const path of under(`looks/${type}s`)) {
      const m = new RegExp(`^com\\.casama/looks/${type}s/([^/]+)\\.json$`).exec(path);
      if (!m) continue;
      const id = m[1] as string;
      if (!ID.test(id)) {
        warnings.push(
          `Skipped ${path}: the file name must be lowercase letters, digits and dashes`,
        );
        continue;
      }
      if (looks.length >= PACK_LIMITS.looks) {
        warnings.push(`Skipped ${path}: a pack holds at most ${PACK_LIMITS.looks} looks`);
        continue;
      }
      const l = json(files, path, warnings);
      if (!isRecord(l)) {
        if (l !== undefined) warnings.push(`Skipped ${path}: must be an object`);
        continue;
      }
      const { name, ...document } = l;
      const n = text(name, 60);
      const errors =
        type === "theme"
          ? checkThemeDocument(document)
          : type === "scheme"
            ? checkSchemeDocument(document)
            : checkWallpaperDocument(document, []);
      if (!n) errors.push("name must be 1 to 60 characters");
      if (errors.length) {
        warnings.push(`Skipped ${path}: ${errors.join("; ")}`);
        continue;
      }
      looks.push({ type, id, name: n as string, document });
    }
  }

  // ---- questions: every placeholder used is asked, every question is used
  const used = new Set<string>();
  const texts: string[] = [
    ...bots.flatMap((b) => [b.persona, ...b.starters]),
    ...routines.flatMap((r) => [r.instructions_md, r.schedule_cron]),
  ];
  for (const t of texts)
    for (const p of galleryPlaceholders(t)) used.add(p.split(".")[0] as string);
  for (const key of used)
    if (!document.inputs.some((i) => i.key === key))
      throw new PackError(`{{${key}}} is used but pack.json asks no question with that key`);
  for (const i of document.inputs)
    if (!used.has(i.key)) warnings.push(`pack.json: question ${i.key} isn't used anywhere`);

  // ---- skills: workspace or bot
  if (plugin.skills.length > PACK_LIMITS.skills)
    throw new PackError(`A pack holds at most ${PACK_LIMITS.skills} skills`);
  const byBot = new Set(bots.flatMap((b) => b.skills));
  const ws = document.workspace_skills.filter((s) => {
    if (skillNames.has(s)) return true;
    warnings.push(`pack.json workspace_skills: no skill ${s}`);
    return false;
  });
  document.workspace_skills = ws;
  const workspaceSkills = plugin.skills
    .map((s) => s.name)
    .filter((n) => ws.includes(n) || !byBot.has(n));

  // ---- reach
  const defaults = galleryInputDefaults(document.inputs);
  const stdio = plugin.servers.filter((s) => s.type === "stdio");
  const scripts = galleryHasScripts([...(opts.skillFiles?.values() ?? [])].flat());
  const toolBots = bots.filter((b) =>
    b.tools.length ? b.tools.some((t) => stdio.some((s) => s.key === t)) : true,
  );
  const reach: PackReach = {
    runs_code: stdio.length > 0 || scripts,
    computer: stdio.length > 0 || scripts,
    hosts: [
      ...new Set([
        ...plugin.hosts,
        ...apps.map((a) => hostOf(a.doc.url)),
        ...bots.flatMap((b) => b.knowledge.map((k) => hostOf(k.url))),
      ]),
    ].sort(),
    secrets: plugin.secrets.map((s) => s.name),
    settings: (plugin.settings ?? []).map((s) => s.name),
    runs_per_week:
      Math.round(
        routines.reduce(
          (sum, r) => sum + cronRunsPerWeek(fillGalleryText(r.schedule_cron, defaults)),
          0,
        ) * 100,
      ) / 100,
    computers: stdio.length ? Math.max(1, toolBots.length) : 0,
    knowledge_sources: bots.reduce((n, b) => n + b.knowledge.length, 0),
    knowledge_pages: bots.reduce(
      (n, b) => n + b.knowledge.reduce((m, k) => m + (k.kind === "website" ? k.max_pages : 0), 0),
      0,
    ),
  };

  return { document, bots, routines, apps, looks, workspaceSkills, reach, warnings };
}

/** A bot's rules: only ones that narrow (ask, hand off). Anything else is skipped with a warning. */
function packRules(raw: unknown, path: string, warnings: string[]): PackRule[] {
  if (raw === undefined) return [];
  if (!Array.isArray(raw)) {
    warnings.push(`${path} rules: must be a list`);
    return [];
  }
  const out: PackRule[] = [];
  for (const r of raw) {
    if (out.length >= PACK_LIMITS.rules) {
      warnings.push(`${path} rules: at most ${PACK_LIMITS.rules}`);
      break;
    }
    const kind = isRecord(r) ? r.match_kind : undefined;
    const value = isRecord(r) ? r.match_value : undefined;
    const rule = isRecord(r) ? r.rule : undefined;
    if (rule === "allow" || rule === "allow_within_limits") {
      warnings.push(`${path} rules: a pack's rules can only ask or hand off, not allow`);
      continue;
    }
    if (
      (kind !== "tool" && kind !== "group" && kind !== "category") ||
      typeof value !== "string" ||
      !value.trim() ||
      value.length > 200 ||
      (rule !== "ask" && rule !== "hand_off")
    ) {
      warnings.push(`${path} rules: skipped one that isn't {match_kind, match_value, rule}`);
      continue;
    }
    out.push({ match_kind: kind, match_value: value.trim(), rule });
  }
  return out;
}

/** A bot's knowledge sources: https websites and GitHub repositories. */
function packKnowledge(raw: unknown, path: string, warnings: string[]): PackKnowledge[] {
  if (raw === undefined) return [];
  if (!Array.isArray(raw)) {
    warnings.push(`${path} knowledge: must be a list`);
    return [];
  }
  const out: PackKnowledge[] = [];
  for (const k of raw) {
    if (out.length >= PACK_LIMITS.knowledge) {
      warnings.push(`${path} knowledge: at most ${PACK_LIMITS.knowledge} sources`);
      break;
    }
    if (!isRecord(k)) continue;
    const url = typeof k.url === "string" ? k.url.trim() : "";
    const kind = k.kind === "github" ? "github" : k.kind === "website" ? "website" : undefined;
    const name = typeof k.name === "string" && k.name.trim() ? k.name.trim().slice(0, 200) : url;
    let ok = false;
    try {
      const u = new URL(url);
      ok =
        u.protocol === "https:" &&
        (kind !== "github" || (u.host === "github.com" && u.pathname.split("/").length >= 3));
    } catch {}
    if (!kind || !ok) {
      warnings.push(
        `${path} knowledge: skipped ${url || "a source"} (an https website or a github.com repository)`,
      );
      continue;
    }
    const pages =
      typeof k.max_pages === "number" && Number.isInteger(k.max_pages)
        ? Math.min(Math.max(k.max_pages, 1), PACK_LIMITS.knowledge_pages)
        : 20;
    out.push({ kind, name, url, max_pages: kind === "website" ? pages : 0 });
  }
  return out;
}

/** The given template fields filled with the questions' defaults, for checking. */
function fillTemplate(
  raw: Record<string, unknown>,
  fields: string[],
  inputs: GalleryInput[],
): Record<string, unknown> {
  const values = galleryInputDefaults(inputs);
  const out = { ...raw };
  for (const f of fields) {
    const v = out[f];
    if (typeof v === "string") out[f] = fillGalleryText(v, values);
    else if (Array.isArray(v))
      out[f] = v.map((x) => (typeof x === "string" ? fillGalleryText(x, values) : x));
  }
  return out;
}

/** A pack's routine or bot with the person's answers filled in. */
export function fillPackBot(b: PackBot, values: Record<string, string>): PackBot {
  return {
    ...b,
    name: fillGalleryText(b.name, values),
    description: fillGalleryText(b.description, values),
    persona: fillGalleryText(b.persona, values),
    starters: b.starters.map((s) => fillGalleryText(s, values)),
  };
}

export function fillPackRoutine(r: PackRoutine, values: Record<string, string>): PackRoutine {
  return {
    ...r,
    name: fillGalleryText(r.name, values),
    description: fillGalleryText(r.description, values),
    instructions_md: fillGalleryText(r.instructions_md, values),
    schedule_cron: fillGalleryText(r.schedule_cron, values),
  };
}

// ---------------------------------------------------------------- update diffs

/** What a pack's summary keeps for diffs: each item's identity and the text that matters. */
export interface PackSnapshot {
  version: string | null;
  bots: Record<string, string>;
  routines: Record<string, string>;
  skills: Record<string, string>;
  apps: Record<string, string>;
  looks: Record<string, string>;
  servers: Record<string, string>;
  hosts: string[];
  secrets: string[];
  schedules: Record<string, string>;
  runs_per_week: number;
  runs_code: boolean;
}

export function packSnapshot(
  pack: CheckedPack,
  plugin: Pick<CheckedPlugin, "servers" | "secrets"> & { manifest: { version?: string } },
  skills: { name: string; md: string }[],
): PackSnapshot {
  const rec = <T>(list: T[], key: (x: T) => string, val: (x: T) => string) =>
    Object.fromEntries(list.map((x) => [key(x), val(x)]));
  return {
    version: plugin.manifest.version ?? null,
    bots: rec(
      pack.bots,
      (b) => b.id,
      (b) =>
        [
          `name: ${b.name}`,
          `autonomy: ${b.autonomy}`,
          `skills: ${b.skills.join(", ")}`,
          `routines: ${b.routines.join(", ")}`,
          `tools: ${b.tools.join(", ")}`,
          ...b.rules.map((r) => `rule: ${r.rule} ${r.match_kind} ${r.match_value}`),
          ...b.knowledge.map((k) => `knowledge: ${k.kind} ${k.url}`),
          "",
          b.persona,
        ].join("\n"),
    ),
    routines: rec(
      pack.routines,
      (r) => r.id,
      (r) => `name: ${r.name}\nschedule: ${r.schedule_cron}\n\n${r.instructions_md}`,
    ),
    skills: rec(
      skills,
      (s) => s.name,
      (s) => s.md,
    ),
    apps: rec(
      pack.apps,
      (a) => a.id,
      (a) => JSON.stringify({ name: a.name, ...a.doc }, null, 2),
    ),
    looks: rec(
      pack.looks,
      (l) => `${l.type}/${l.id}`,
      (l) => JSON.stringify(l.document),
    ),
    servers: rec(
      plugin.servers,
      (s) => s.key,
      (s) => JSON.stringify(s),
    ),
    hosts: pack.reach.hosts,
    secrets: plugin.secrets.map((s) => s.name),
    schedules: rec(
      pack.routines,
      (r) => r.id,
      (r) => r.schedule_cron,
    ),
    runs_per_week: pack.reach.runs_per_week,
    runs_code: pack.reach.runs_code,
  };
}

export interface PackKindDiff {
  added: string[];
  removed: string[];
  changed: { id: string; diff: string[] }[];
}

export interface PackDiff {
  bots: PackKindDiff;
  routines: PackKindDiff;
  skills: PackKindDiff;
  apps: PackKindDiff;
  looks: PackKindDiff;
  servers: PackKindDiff;
  hosts_added: string[];
  secrets_added: string[];
  schedules_changed: string[];
  runs_per_week: { from: number; to: number };
  /** New hosts, secrets, tool servers or code: the update asks first. */
  reach_grew: boolean;
  empty: boolean;
}

function kindDiff(a: Record<string, string>, b: Record<string, string>): PackKindDiff {
  return {
    added: Object.keys(b).filter((k) => !(k in a)),
    removed: Object.keys(a).filter((k) => !(k in b)),
    changed: Object.keys(b)
      .filter((k) => k in a && a[k] !== b[k])
      .map((id) => ({ id, diff: lineDiff(a[id] as string, b[id] as string, { maxLines: 200 }) })),
  };
}

export function diffPacks(before: PackSnapshot, after: PackSnapshot): PackDiff {
  const kinds = {
    bots: kindDiff(before.bots, after.bots),
    routines: kindDiff(before.routines, after.routines),
    skills: kindDiff(before.skills, after.skills),
    apps: kindDiff(before.apps, after.apps),
    looks: kindDiff(before.looks, after.looks),
    servers: kindDiff(before.servers, after.servers),
  };
  const hosts_added = after.hosts.filter((h) => !before.hosts.includes(h));
  const secrets_added = after.secrets.filter((s) => !before.secrets.includes(s));
  const schedules_changed = Object.keys(after.schedules).filter(
    (k) => k in before.schedules && before.schedules[k] !== after.schedules[k],
  );
  const reach_grew =
    hosts_added.length > 0 ||
    secrets_added.length > 0 ||
    kinds.servers.added.length > 0 ||
    kinds.servers.changed.length > 0 ||
    kinds.apps.added.length > 0 ||
    (after.runs_code && !before.runs_code);
  const empty =
    Object.values(kinds).every((k) => !k.added.length && !k.removed.length && !k.changed.length) &&
    !hosts_added.length &&
    !secrets_added.length;
  return {
    ...kinds,
    hosts_added,
    secrets_added,
    schedules_changed,
    runs_per_week: { from: before.runs_per_week, to: after.runs_per_week },
    reach_grew,
    empty,
  };
}

// ---------------------------------------------------------------- export (Share as pack)

export interface PackExportSkill {
  name: string;
  description: string;
  body_md: string;
  files: { path: string; base64: string; executable: boolean }[];
}

export interface PackExportSpec {
  name: string;
  description: string;
  summary: string;
  icon?: string;
  author?: string;
  bots: {
    name: string;
    description: string;
    persona: string;
    starters: string[];
    autonomy: "ask_always" | "ask_risky" | "autonomous";
    mascot?: string | null;
    skills: PackExportSkill[];
    routines: { name: string; instructions_md: string; schedule_cron: string }[];
    /** Apps it uses, by catalog id. */
    apps: string[];
    /** Its plugins, by link and commit. */
    plugins: { url: string; commit: string }[];
  }[];
  workspaceSkills: PackExportSkill[];
  look?: { type: PackLookType; name: string; document: Record<string, unknown> };
}

export interface PackExportFile {
  path: string;
  /** Text files are utf-8; skill files keep their bytes as base64. */
  text?: string;
  base64?: string;
  executable?: boolean;
}

/** A name that fits Agent Plugins (lowercase, digits, dots and dashes). */
export function packSlug(s: string, fallback = "pack"): string {
  const slug = s
    .toLowerCase()
    .normalize("NFKD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 60)
    .replace(/-+$/g, "");
  return slug || fallback;
}

function skillMd(s: PackExportSkill): string {
  const desc = s.description.replace(/\r?\n/g, " ").trim();
  return `---\nname: ${s.name}\ndescription: ${JSON.stringify(desc)}\n---\n\n${s.body_md.trim()}\n`;
}

/**
 * The files of a pack built from a workspace's setup. Only what the spec lists goes in: callers
 * never pass keys, chats, memories or the model (plan §7 E, a fixed include list).
 */
export function buildPackFiles(spec: PackExportSpec): PackExportFile[] {
  const name = packSlug(spec.name);
  const files: PackExportFile[] = [];
  const add = (path: string, value: unknown) =>
    files.push({ path, text: `${JSON.stringify(value, null, 2)}\n` });
  add("plugin.json", {
    $schema: "https://agent-plugins.org/schemas/1.0.0/plugin.schema.json",
    name,
    version: "1.0.0",
    description: spec.description.slice(0, 300) || spec.summary,
    ...(spec.author ? { author: { name: spec.author } } : {}),
    keywords: ["casama", "pack"],
  });
  const skillNames = new Set<string>();
  const addSkill = (s: PackExportSkill) => {
    let n = s.name;
    for (let i = 2; skillNames.has(n); i++) n = `${s.name}-${i}`;
    skillNames.add(n);
    files.push({ path: `skills/${n}/SKILL.md`, text: skillMd({ ...s, name: n }) });
    for (const f of s.files)
      files.push({
        path: `skills/${n}/${f.path}`,
        base64: f.base64,
        executable: f.executable,
      });
    return n;
  };
  const workspace = spec.workspaceSkills.map(addSkill);
  const includes: PackInclude[] = [];
  const needs = new Set<string>();
  const usedIds = new Set<string>();
  const freeId = (base: string) => {
    let id = packSlug(base, "item");
    for (let i = 2; usedIds.has(id); i++) id = `${packSlug(base, "item")}-${i}`;
    usedIds.add(id);
    return id;
  };
  for (const b of spec.bots) {
    const botId = freeId(b.name);
    const skills = b.skills.map(addSkill);
    const routines = b.routines.map((r) => {
      const id = freeId(r.name);
      add(`${PACK_DIR}/routines/${id}.json`, {
        name: r.name.slice(0, 120),
        description: r.name.slice(0, 200),
        category: "work",
        icon: "calendar-clock",
        instructions_md: r.instructions_md,
        schedule_cron: r.schedule_cron,
      });
      return id;
    });
    for (const a of b.apps) needs.add(a);
    for (const p of b.plugins)
      if (!includes.some((x) => "url" in x && x.url === p.url))
        includes.push({ type: "plugin", url: p.url, commit: p.commit });
    const persona =
      b.persona.trim().length >= 20 ? b.persona : `${b.persona.trim()}\n\nYou are ${b.name}.`;
    add(`${PACK_DIR}/bots/${botId}.json`, {
      name: b.name.slice(0, 80),
      description: (b.description || b.name).slice(0, 300),
      category: "work",
      icon: "bot",
      mascot:
        b.mascot && GALLERY_MASCOTS.includes(b.mascot.replace(/^mascot:/, "") as never)
          ? b.mascot.replace(/^mascot:/, "")
          : "cool",
      persona,
      starters: b.starters.length
        ? b.starters.slice(0, 3).map((x) => x.slice(0, 160))
        : ["What can you help me with?"],
      autonomy: b.autonomy === "autonomous" ? "ask_risky" : b.autonomy,
      skills,
      routines,
    });
  }
  if (spec.look)
    add(`${PACK_DIR}/looks/${spec.look.type}s/${freeId(spec.look.name)}.json`, {
      name: spec.look.name,
      ...spec.look.document,
    });
  add(PACK_FILE, {
    format: PACK_FORMAT,
    version: PACK_VERSION,
    title: spec.name.trim().slice(0, 64),
    icon: spec.icon ?? "package",
    summary: spec.summary.slice(0, 160),
    ...(needs.size ? { needs: { apps: [...needs].slice(0, 10) } } : {}),
    ...(includes.length ? { includes: includes.slice(0, PACK_LIMITS.includes) } : {}),
    ...(workspace.length ? { workspace_skills: workspace } : {}),
  });
  return files;
}

// ---------------------------------------------------------------- the key scan before export

/** Common key shapes. The workspace's own secret values are checked by the caller too. */
const KEY_SHAPES: Array<[string, RegExp]> = [
  ["an OpenAI or Anthropic key", /\bsk-(?:ant-|proj-)?[A-Za-z0-9_-]{20,}/],
  ["a GitHub token", /\b(?:ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9]{30,}|\bgithub_pat_[A-Za-z0-9_]{40,}/],
  ["a Slack token", /\bxox[abpors]-[A-Za-z0-9-]{10,}/],
  ["an AWS access key", /\b(?:AKIA|ASIA)[A-Z0-9]{16}\b/],
  ["a Google API key", /\bAIza[0-9A-Za-z_-]{35}\b/],
  ["a Stripe key", /\b(?:sk|rk)_(?:live|test)_[A-Za-z0-9]{20,}/],
  ["a private key", /-----BEGIN (?:RSA |EC |OPENSSH |)PRIVATE KEY-----/],
  ["a Bearer token", /\bBearer\s+[A-Za-z0-9._~+/-]{30,}=*/],
];

export interface SecretFinding {
  path: string;
  line: number;
  what: string;
}

/** Lines in text files that look like keys, or contain one of `known` (the workspace's secrets). */
export function findSecretsInFiles(
  files: PackExportFile[],
  known: { label: string; value: string }[] = [],
): SecretFinding[] {
  const out: SecretFinding[] = [];
  for (const f of files) {
    const t = f.text ?? (f.base64 && Buffer.from(f.base64, "base64").toString("utf8")) ?? "";
    if (!t || t.slice(0, 2000).includes("\u0000")) continue;
    t.split("\n").forEach((line, i) => {
      for (const k of known)
        if (k.value.length >= 8 && line.includes(k.value))
          out.push({ path: f.path, line: i + 1, what: `your secret ${k.label}` });
      for (const [what, re] of KEY_SHAPES)
        if (re.test(line)) out.push({ path: f.path, line: i + 1, what });
    });
  }
  return out;
}

/** A stable hash of what a person can edit on an item, to tell later whether they changed it. */
export function packItemHash(parts: Array<string | number | boolean | null | undefined>): string {
  // FNV-1a over the joined parts: not for security, only to spot a change.
  let h = 0x811c9dc5;
  const s = parts.map((p) => String(p ?? "")).join("\u0000");
  for (let i = 0; i < s.length; i++) {
    h ^= s.charCodeAt(i);
    h = Math.imul(h, 0x01000193) >>> 0;
  }
  return h.toString(16).padStart(8, "0") + s.length.toString(16);
}
