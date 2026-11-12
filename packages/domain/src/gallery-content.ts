/**
 * More of Casama from the open gallery (D-241): starter bots, routine ideas and a reviewed list of
 * plugins, next to the looks, skills (D-184) and apps (D-239) already there. Pure checks: the
 * gallery checker runs them, and the server runs them again on every entry it reads.
 *
 * Each kind is written to its own file (bots.json, routines.json, plugins.json), never index.json,
 * because servers and apps from before this only know the index's look and skill types.
 */
import { isValidCron } from "./schedule.ts";
import type { BotTemplate, TemplateCategory } from "./templates.ts";

export const GALLERY_BOT_TYPE = "bot" as const;
export const GALLERY_ROUTINE_TYPE = "routine" as const;
export const GALLERY_PLUGIN_TYPE = "plugin" as const;

/** Bots and routine ideas are writing, like skills. A plugin entry is data pointing at code. */
export const BOT_LICENSES = ["MIT", "Apache-2.0", "CC0-1.0", "CC-BY-4.0"] as const;
export const ROUTINE_LICENSES = BOT_LICENSES;
export const PLUGIN_ENTRY_LICENSES = ["CC0-1.0"] as const;

export const GALLERY_TEMPLATE_CATEGORIES = [
  "work",
  "research",
  "build",
  "create",
  "life",
] as const satisfies readonly TemplateCategory[];

/** The cloud mascots the app ships (assets/mascots). */
export const GALLERY_MASCOTS = [
  "cool",
  "focused",
  "giggly",
  "lovey",
  "shy",
  "sleepy",
  "starry",
  "thinker",
  "winky",
  "wow",
] as const;

/**
 * A gallery bot can't start fully autonomous: it asks before risky actions at most, and the person
 * can raise that after reading what it does.
 */
export const GALLERY_BOT_AUTONOMY = ["ask_always", "ask_risky"] as const;

const ICON = /^[a-z0-9][a-z0-9-]{0,39}$/;
const SKILL_NAME = /^[a-z0-9][a-z0-9_-]{0,62}$/;
const COMMIT = /^[0-9a-f]{40}$/;
/** A plugin folder on GitHub: the repository, or a folder in it (`/tree/<ref>/<path>`). */
const GITHUB_URL =
  /^https:\/\/github\.com\/[A-Za-z0-9_.-]{1,100}\/[A-Za-z0-9_.-]{1,100}(\/tree\/[^/\s]{1,200}(\/[^\s]{1,300})?)?\/?$/;

function isRecord(v: unknown): v is Record<string, unknown> {
  return typeof v === "object" && v !== null && !Array.isArray(v);
}

function text(v: unknown, max: number, min = 1): string | undefined {
  if (typeof v !== "string") return undefined;
  const t = v.trim();
  return t.length >= min && t.length <= max ? t : undefined;
}

function onlyKeys(
  raw: Record<string, unknown>,
  allowed: string[],
  label: string,
  errors: string[],
) {
  for (const key of Object.keys(raw))
    if (!allowed.includes(key)) errors.push(`${label} can't have ${key}`);
}

// ---------------------------------------------------------------- bots

/** What bot.json holds; the name, author and license are in item.json. */
export type GalleryBotDocument = Omit<BotTemplate, "id" | "name">;

export function checkBotDocument(raw: unknown): { doc?: GalleryBotDocument; errors: string[] } {
  const errors: string[] = [];
  if (!isRecord(raw)) return { errors: ["bot.json must be an object"] };
  onlyKeys(
    raw,
    [
      "description",
      "category",
      "icon",
      "mascot",
      "persona",
      "starters",
      "autonomy",
      "skills",
      "routines",
    ],
    "bot.json",
    errors,
  );
  const description = text(raw.description, 300);
  if (!description) errors.push("description must be 1 to 300 characters");
  const category = GALLERY_TEMPLATE_CATEGORIES.find((c) => c === raw.category);
  if (!category) errors.push(`category must be one of ${GALLERY_TEMPLATE_CATEGORIES.join(", ")}`);
  const icon = typeof raw.icon === "string" && ICON.test(raw.icon) ? raw.icon : undefined;
  if (!icon) errors.push("icon must be a Lucide icon name such as notebook-pen");
  const mascot = GALLERY_MASCOTS.find((m) => m === raw.mascot);
  if (!mascot) errors.push(`mascot must be one of ${GALLERY_MASCOTS.join(", ")}`);
  const persona = text(raw.persona, 20_000, 20);
  if (!persona) errors.push("persona must be 20 to 20,000 characters of standing instructions");
  const starters = Array.isArray(raw.starters) ? raw.starters.map((s) => text(s, 160)) : [];
  if (
    !Array.isArray(raw.starters) ||
    starters.length < 1 ||
    starters.length > 6 ||
    starters.some((s) => !s)
  )
    errors.push("starters must be 1 to 6 first messages of at most 160 characters");
  const autonomy = GALLERY_BOT_AUTONOMY.find((a) => a === raw.autonomy);
  if (!autonomy) errors.push(`autonomy must be ${GALLERY_BOT_AUTONOMY.join(" or ")}`);

  const skills: GalleryBotDocument["skills"] = [];
  if (raw.skills !== undefined) {
    if (!Array.isArray(raw.skills) || raw.skills.length > 10)
      errors.push("skills must be at most 10");
    else
      raw.skills.forEach((s, i) => {
        const at = `skills[${i}]`;
        if (!isRecord(s)) {
          errors.push(`${at} must be an object`);
          return;
        }
        onlyKeys(s, ["name", "description", "body_md"], at, errors);
        const name = typeof s.name === "string" && SKILL_NAME.test(s.name) ? s.name : undefined;
        const desc = text(s.description, 300);
        const body = text(s.body_md, 50_000);
        if (!name)
          errors.push(`${at}.name must be lowercase letters, digits, dashes or underscores`);
        if (!desc) errors.push(`${at}.description must be 1 to 300 characters`);
        if (!body) errors.push(`${at}.body_md must be 1 to 50,000 characters`);
        if (name && skills.some((k) => k.name === name))
          errors.push(`${at}.name ${name} is used twice`);
        if (name && desc && body) skills.push({ name, description: desc, body_md: body });
      });
  }
  const routines: NonNullable<GalleryBotDocument["routines"]> = [];
  if (raw.routines !== undefined) {
    if (!Array.isArray(raw.routines) || raw.routines.length > 5)
      errors.push("routines must be at most 5");
    else
      raw.routines.forEach((r, i) => {
        const at = `routines[${i}]`;
        if (!isRecord(r)) {
          errors.push(`${at} must be an object`);
          return;
        }
        onlyKeys(r, ["name", "instructions_md", "schedule_cron"], at, errors);
        const name = text(r.name, 120);
        const instructions = text(r.instructions_md, 20_000);
        const cron =
          typeof r.schedule_cron === "string" && isValidCron(r.schedule_cron)
            ? r.schedule_cron
            : undefined;
        if (!name) errors.push(`${at}.name must be 1 to 120 characters`);
        if (!instructions) errors.push(`${at}.instructions_md must be 1 to 20,000 characters`);
        if (!cron) errors.push(`${at}.schedule_cron must be a 5-field cron expression`);
        if (name && instructions && cron)
          routines.push({ name, instructions_md: instructions, schedule_cron: cron });
      });
  }
  if (errors.length) return { errors };
  return {
    errors,
    doc: {
      description: description as string,
      category: category as TemplateCategory,
      icon: icon as string,
      mascot: mascot as string,
      persona: persona as string,
      starters: starters as string[],
      autonomy: autonomy as GalleryBotDocument["autonomy"],
      skills,
      ...(routines.length ? { routines } : {}),
    },
  };
}

/** The starter bot a gallery entry becomes on a server. */
export function botTemplateFromGallery(
  id: string,
  name: string,
  raw: unknown,
): BotTemplate | undefined {
  const { doc } = checkBotDocument(raw);
  return doc ? { id, name, ...doc } : undefined;
}

// ---------------------------------------------------------------- routines

/** A routine idea: what it does and when, ready to fill in the new-routine sheet. */
export interface GalleryRoutineDocument {
  description: string;
  category: TemplateCategory;
  icon: string;
  instructions_md: string;
  schedule_cron: string;
}

export function checkRoutineDocument(raw: unknown): {
  doc?: GalleryRoutineDocument;
  errors: string[];
} {
  const errors: string[] = [];
  if (!isRecord(raw)) return { errors: ["routine.json must be an object"] };
  onlyKeys(
    raw,
    ["description", "category", "icon", "instructions_md", "schedule_cron"],
    "routine.json",
    errors,
  );
  const description = text(raw.description, 200);
  if (!description) errors.push("description must be 1 to 200 characters");
  const category = GALLERY_TEMPLATE_CATEGORIES.find((c) => c === raw.category);
  if (!category) errors.push(`category must be one of ${GALLERY_TEMPLATE_CATEGORIES.join(", ")}`);
  const icon = typeof raw.icon === "string" && ICON.test(raw.icon) ? raw.icon : undefined;
  if (!icon) errors.push("icon must be a Lucide icon name such as calendar-check");
  const instructions = text(raw.instructions_md, 20_000, 10);
  if (!instructions) errors.push("instructions_md must be 10 to 20,000 characters");
  const cron =
    typeof raw.schedule_cron === "string" && isValidCron(raw.schedule_cron)
      ? raw.schedule_cron
      : undefined;
  if (!cron) errors.push("schedule_cron must be a 5-field cron expression such as 0 9 * * 1-5");
  if (errors.length) return { errors };
  return {
    errors,
    doc: {
      description: description as string,
      category: category as TemplateCategory,
      icon: icon as string,
      instructions_md: instructions as string,
      schedule_cron: cron as string,
    },
  };
}

// ---------------------------------------------------------------- plugins

/**
 * A plugin someone reviewed: where it lives on GitHub and the exact commit that was reviewed.
 * Installing from the directory installs that commit, never whatever the branch holds later.
 */
export interface GalleryPluginDocument {
  description: string;
  url: string;
  commit: string;
  icon?: string;
  /** Short phrases for what it adds (skills, a server, a secret it asks for). */
  adds: string[];
}

export function checkPluginDocument(raw: unknown): {
  doc?: GalleryPluginDocument;
  errors: string[];
} {
  const errors: string[] = [];
  if (!isRecord(raw)) return { errors: ["plugin.json must be an object"] };
  onlyKeys(raw, ["description", "url", "commit", "icon", "adds"], "plugin.json", errors);
  const description = text(raw.description, 300);
  if (!description) errors.push("description must be 1 to 300 characters");
  const url = typeof raw.url === "string" && GITHUB_URL.test(raw.url) ? raw.url : undefined;
  if (!url) errors.push("url must be a github.com repository or folder link");
  const commit = typeof raw.commit === "string" && COMMIT.test(raw.commit) ? raw.commit : undefined;
  if (!commit) errors.push("commit must be the full 40-character commit that was reviewed");
  let icon: string | undefined;
  if (raw.icon !== undefined) {
    icon = typeof raw.icon === "string" && ICON.test(raw.icon) ? raw.icon : undefined;
    if (!icon) errors.push("icon must be a Lucide icon name such as puzzle");
  }
  const adds = Array.isArray(raw.adds) ? raw.adds.map((a) => text(a, 80)) : [];
  if (adds.length < 1 || adds.length > 6 || adds.some((a) => !a))
    errors.push("adds must be 1 to 6 short phrases of at most 80 characters");
  if (errors.length) return { errors };
  return {
    errors,
    doc: {
      description: description as string,
      url: url as string,
      commit: commit as string,
      ...(icon ? { icon } : {}),
      adds: adds as string[],
    },
  };
}
