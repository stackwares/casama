// SPDX-License-Identifier: Apache-2.0
// A shared format, also used by the Apache-2.0 SDKs and tools (LICENSING.md).
/**
 * Casama gallery items (D-184): themes, color schemes, wallpapers and skills that anyone can
 * contribute. Pure checks. The checker script and the server both use these.
 */
import { createHash } from "node:crypto";
import { parseSkillMd, SkillFormatError } from "./skill-format.ts";

export const GALLERY_TYPES = ["theme", "scheme", "wallpaper", "skill"] as const;
export type GalleryType = (typeof GALLERY_TYPES)[number];

export const LOOK_LICENSES = ["CC0-1.0", "CC-BY-4.0"] as const;
export const SKILL_LICENSES = ["MIT", "Apache-2.0"] as const;

/** Fonts the app can draw without an extra download step failing the checker. */
export const GALLERY_FONTS = [
  "Libre Baskerville",
  "Lato",
  "Google Sans",
  "Noto Serif",
  "Fraunces",
  "Figtree",
  "Inter",
  "Plus Jakarta Sans",
  "DM Sans",
  "Manrope",
  "Nunito",
  "Outfit",
  "Poppins",
  "Lexend",
  "Work Sans",
  "Rubik",
  "Sora",
  "Urbanist",
  "Quicksand",
  "Onest",
  "Geist",
  "Atkinson Hyperlegible",
  "IBM Plex Sans",
  "Noto Sans",
  "Source Sans 3",
  "Open Sans",
  "Roboto",
  "Playfair Display",
  "Instrument Serif",
  "DM Serif Display",
  "Young Serif",
  "Lora",
  "Newsreader",
  "Source Serif 4",
  "Merriweather",
  "EB Garamond",
  "Crimson Pro",
  "Bricolage Grotesque",
  "Space Grotesk",
  "Fredoka",
  "Baloo 2",
] as const;

export const WALLPAPER_PATTERNS = [
  "none",
  "clouds",
  "doodles",
  "treats",
  "garden",
  "space",
  "pets",
  "sea",
  "tech",
] as const;

/** Palettes every app version draws; a mesh names one of these as its fallback. */
export const WALLPAPER_FALLBACK_PALETTES = [
  "theme",
  "casama",
  "lavender",
  "cotton",
  "peach",
  "sunset",
  "mint",
  "ocean",
  "forest",
  "graphite",
] as const;

/** Every built-in palette. The last five arrived with mesh gradients (D-200), so older apps skip items that name them. */
export const WALLPAPER_PALETTES = [
  ...WALLPAPER_FALLBACK_PALETTES,
  "northern",
  "twilight",
  "berry",
  "citrus",
  "reef",
] as const;

/** Mesh colors stay this light (light) or dark (night) so text on transparent headers reads. */
export const MESH_MIN_LIGHT_LUMINANCE = 0.55;
export const MESH_MAX_DARK_LUMINANCE = 0.05;

const HEX = /^#[0-9A-Fa-f]{6}$/;
const ID = /^[a-z0-9][a-z0-9-]{0,62}$/;
const TAG = /^[a-z0-9][a-z0-9-]{0,23}$/;

export interface SeedColors {
  seed: string;
  background: string;
  onBackground: string;
}

/** SHA-256 over sorted path + length + bytes. The index stores this; install checks it. */
export function galleryHash(files: { path: string; bytes: Uint8Array }[]): string {
  const hash = createHash("sha256");
  for (const f of [...files].sort((a, b) => (a.path < b.path ? -1 : a.path > b.path ? 1 : 0))) {
    hash.update(f.path);
    hash.update("\0");
    hash.update(String(f.bytes.byteLength));
    hash.update("\0");
    hash.update(f.bytes);
  }
  return hash.digest("hex");
}

function channel(c: number) {
  const s = c / 255;
  return s <= 0.04045 ? s / 12.92 : ((s + 0.055) / 1.055) ** 2.4;
}

function luminance(hex: string) {
  const n = Number.parseInt(hex.slice(1), 16);
  const r = channel((n >> 16) & 255);
  const g = channel((n >> 8) & 255);
  const b = channel(n & 255);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/** WCAG contrast. AA text is 4.5. */
export function contrastRatio(a: string, b: string): number {
  const l1 = luminance(a);
  const l2 = luminance(b);
  const [hi, lo] = l1 >= l2 ? [l1, l2] : [l2, l1];
  return (hi + 0.05) / (lo + 0.05);
}

function isRecord(v: unknown): v is Record<string, unknown> {
  return typeof v === "object" && v !== null && !Array.isArray(v);
}

export interface GalleryAuthor {
  name: string;
  url?: string;
  /** Stable author id for author pages, GitHub-login style (D-315). */
  handle?: string;
}

/** Every kind of gallery item, by folder. `index.json` carries only {@link GALLERY_TYPES}. */
export const GALLERY_KINDS = [
  "theme",
  "scheme",
  "wallpaper",
  "skill",
  "app",
  "bot",
  "routine",
  "plugin",
  "set",
] as const;
export type GalleryKind = (typeof GALLERY_KINDS)[number];

/** How much a run of the item tends to cost, in plain steps (D-315). */
export const GALLERY_CREDIT_LEVELS = ["none", "low", "medium", "high"] as const;
export type GalleryCreditLevel = (typeof GALLERY_CREDIT_LEVELS)[number];

/** The kinds each newer item.json field is allowed on. */
export const GALLERY_EXAMPLE_KINDS = ["skill", "app", "bot"] as const;
export const GALLERY_ACCESS_KINDS = ["skill", "app", "routine", "bot", "plugin"] as const;
export const GALLERY_NEEDS_KINDS = ["routine", "bot"] as const;
export const GALLERY_INPUT_KINDS = ["routine", "bot"] as const;

export const GALLERY_INPUT_TYPES = ["text", "choice", "time", "timezone"] as const;
export type GalleryInputType = (typeof GALLERY_INPUT_TYPES)[number];

/** One changelog line; the list is newest first and its top version is the item's version. */
export interface GalleryChangelogEntry {
  version: number;
  date: string;
  note: string;
  breaking?: boolean;
}

/** What an item can touch, in plain words, shown before someone adds it. */
export interface GalleryAccess {
  reads?: string[];
  writes?: string[];
  runs_code?: boolean;
  computer?: boolean;
  credits?: GalleryCreditLevel;
}

/** Gallery or built-in apps and gallery skills a routine or bot needs before it works. */
export interface GalleryNeeds {
  apps?: string[];
  skills?: string[];
}

/**
 * A question asked when a routine or bot is added. Its answer fills `{{key}}` in the document.
 * `default` is required: servers from before inputs (and anyone who skips the form) get it.
 */
export interface GalleryInput {
  key: string;
  label: string;
  type: GalleryInputType;
  default: string;
  options?: string[];
  help?: string;
}

/** Another gallery item, by kind and id. */
export interface GalleryItemRef {
  type: GalleryKind;
  id: string;
}

/** Month-day window an item is seasonal in; may wrap the year end (`12-01` to `01-06`). */
export interface GallerySeason {
  from: string;
  to: string;
}

export interface GalleryMeta {
  name: string;
  author: GalleryAuthor;
  license: string;
  tags: string[];
  featured: boolean;
  retired: boolean;
  version: number;
  category?: string;
  /** A Lucide icon name for a skill's tile (`notebook-pen`). Unknown names fall back in the app. */
  icon?: string;
  /** `YYYY-MM-DD` the item was added. Required in the catalog; missing only when allowed. */
  added?: string;
  /** `YYYY-MM-DD` of the latest change: `updated`, else the top changelog date, else `added`. */
  updated?: string;
  changelog?: GalleryChangelogEntry[];
  pick?: string;
  examples?: string[];
  access?: GalleryAccess;
  needs?: GalleryNeeds;
  inputs?: GalleryInput[];
  remix_of?: GalleryItemRef;
  replaced_by?: GalleryItemRef;
  min_app?: string;
  min_server?: string;
  season?: GallerySeason;
}

export interface GalleryMetaOptions {
  /** The item's kind, so kind-only fields (examples, access, needs, inputs) are checked. */
  kind?: GalleryKind;
  /** Accept an item.json without `added` (a submission before it gets its date). */
  allowMissingAdded?: boolean;
}

const DATE = /^(\d{4})-(\d{2})-(\d{2})$/;
const MONTH_DAY = /^(\d{2})-(\d{2})$/;
const SEMVER = /^\d{1,4}\.\d{1,4}\.\d{1,4}$/;
const HANDLE = /^[a-z0-9][a-z0-9-]{0,38}$/;
const INPUT_KEY = /^[a-z][a-z0-9_]{0,31}$/;
const TIME = /^([01]\d|2[0-3]):[0-5]\d$/;
const TIMEZONE = /^(UTC|[A-Za-z]+(\/[A-Za-z0-9_+-]+){1,2})$/;
const DAYS_IN_MONTH = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

/** A real calendar date written `YYYY-MM-DD`. */
export function isGalleryDate(v: unknown): v is string {
  if (typeof v !== "string") return false;
  const m = DATE.exec(v);
  if (!m) return false;
  const [y, mo, d] = [Number(m[1]), Number(m[2]), Number(m[3])];
  const date = new Date(Date.UTC(y, mo - 1, d));
  return date.getUTCFullYear() === y && date.getUTCMonth() === mo - 1 && date.getUTCDate() === d;
}

function isMonthDay(v: unknown): v is string {
  if (typeof v !== "string") return false;
  const m = MONTH_DAY.exec(v);
  if (!m) return false;
  const mo = Number(m[1]);
  const d = Number(m[2]);
  return mo >= 1 && mo <= 12 && d >= 1 && d <= (DAYS_IN_MONTH[mo - 1] ?? 0);
}

/** Compares `x.y.z` versions: negative when a is lower. */
export function compareGalleryVersions(a: string, b: string): number {
  const pa = a.split(".").map(Number);
  const pb = b.split(".").map(Number);
  for (let i = 0; i < 3; i++) {
    const d = (pa[i] ?? 0) - (pb[i] ?? 0);
    if (d) return d;
  }
  return 0;
}

/** Whether a `MM-DD` window covers a date (`YYYY-MM-DD`, or today in UTC). */
export function galleryInSeason(season: GallerySeason, date?: string): boolean {
  const day = (date ?? new Date().toISOString().slice(0, 10)).slice(5, 10);
  return season.from <= season.to
    ? day >= season.from && day <= season.to
    : day >= season.from || day <= season.to;
}

/** Whether a skill's files include code it would run (scripts, examples). */
export function galleryHasScripts(paths: string[]): boolean {
  return paths.some((p) => /\.(py|sh|bash|zsh|js|mjs|cjs|ts|mts|rb|pl|ps1|php|go)$/i.test(p));
}

/** Strings of at most `max` characters, `min..maxItems` of them. Errors go under `label`. */
function shortList(
  raw: unknown,
  label: string,
  max: number,
  minItems: number,
  maxItems: number,
  errors: string[],
): string[] | undefined {
  if (
    !Array.isArray(raw) ||
    raw.length < minItems ||
    raw.length > maxItems ||
    !raw.every((x) => typeof x === "string" && x.trim().length >= 1 && x.trim().length <= max)
  ) {
    errors.push(`${label} must be ${minItems} to ${maxItems} lines of at most ${max} characters`);
    return;
  }
  return raw.map((x) => (x as string).trim());
}

function itemRef(raw: unknown, label: string, errors: string[]): GalleryItemRef | undefined {
  if (
    !isRecord(raw) ||
    !GALLERY_KINDS.includes(raw.type as never) ||
    typeof raw.id !== "string" ||
    !ID.test(raw.id) ||
    Object.keys(raw).some((k) => k !== "type" && k !== "id")
  ) {
    errors.push(`${label} must be { "type": kind, "id": gallery id }`);
    return;
  }
  return { type: raw.type as GalleryKind, id: raw.id };
}

const allowedOn = (kinds: readonly string[], kind: GalleryKind | undefined) =>
  kind === undefined || kinds.includes(kind);

function parseChangelog(raw: unknown, version: number, errors: string[]) {
  if (!Array.isArray(raw) || raw.length < 1 || raw.length > 50) {
    errors.push("changelog must be 1 to 50 entries, newest first");
    return;
  }
  const out: GalleryChangelogEntry[] = [];
  raw.forEach((e, i) => {
    const at = `changelog[${i}]`;
    if (!isRecord(e)) {
      errors.push(`${at} must be an object`);
      return;
    }
    for (const k of Object.keys(e))
      if (!["version", "date", "note", "breaking"].includes(k))
        errors.push(`${at} can't have ${k}`);
    if (typeof e.version !== "number" || !Number.isInteger(e.version) || e.version < 1)
      errors.push(`${at}.version must be a positive integer`);
    if (!isGalleryDate(e.date)) errors.push(`${at}.date must be YYYY-MM-DD`);
    const note = typeof e.note === "string" ? e.note.trim() : "";
    if (note.length < 1 || note.length > 160) errors.push(`${at}.note must be 1 to 160 characters`);
    if (e.breaking !== undefined && typeof e.breaking !== "boolean")
      errors.push(`${at}.breaking must be true or false`);
    out.push({
      version: e.version as number,
      date: e.date as string,
      note,
      ...(e.breaking === true ? { breaking: true } : {}),
    });
  });
  for (let i = 1; i < out.length; i++) {
    const prev = out[i - 1] as GalleryChangelogEntry;
    const cur = out[i] as GalleryChangelogEntry;
    if (!(cur.version < prev.version))
      errors.push("changelog versions must go strictly down, newest first");
    if (cur.date > prev.date) errors.push("changelog dates must not go up, newest first");
  }
  if (out[0] && out[0].version !== version)
    errors.push(`changelog's top entry must be version ${version}`);
  return out;
}

function parseAccess(raw: unknown, errors: string[]): GalleryAccess | undefined {
  if (!isRecord(raw)) {
    errors.push("access must be an object");
    return;
  }
  for (const k of Object.keys(raw))
    if (!["reads", "writes", "runs_code", "computer", "credits"].includes(k))
      errors.push(`access can't have ${k}`);
  const out: GalleryAccess = {};
  for (const key of ["reads", "writes"] as const) {
    if (raw[key] === undefined) continue;
    const list = shortList(raw[key], `access.${key}`, 40, 1, 8, errors);
    if (list) out[key] = list;
  }
  for (const key of ["runs_code", "computer"] as const) {
    if (raw[key] === undefined) continue;
    if (typeof raw[key] !== "boolean") errors.push(`access.${key} must be true or false`);
    else out[key] = raw[key] as boolean;
  }
  if (raw.credits !== undefined) {
    if (!GALLERY_CREDIT_LEVELS.includes(raw.credits as never))
      errors.push(`access.credits must be one of ${GALLERY_CREDIT_LEVELS.join(", ")}`);
    else out.credits = raw.credits as GalleryCreditLevel;
  }
  return out;
}

function parseNeeds(raw: unknown, errors: string[]): GalleryNeeds | undefined {
  if (!isRecord(raw)) {
    errors.push("needs must be an object");
    return;
  }
  const out: GalleryNeeds = {};
  for (const k of Object.keys(raw))
    if (k !== "apps" && k !== "skills") errors.push(`needs can't have ${k}`);
  for (const key of ["apps", "skills"] as const) {
    const list = raw[key];
    if (list === undefined) continue;
    if (
      !Array.isArray(list) ||
      list.length < 1 ||
      list.length > 10 ||
      !list.every((x) => typeof x === "string" && /^[a-z0-9][a-z0-9_-]{0,62}$/.test(x)) ||
      new Set(list).size !== list.length
    )
      errors.push(`needs.${key} must be 1 to 10 different ids`);
    else out[key] = list as string[];
  }
  return out;
}

/** Install questions, checked (shared by gallery items and packs). */
export function parseGalleryInputs(raw: unknown, errors: string[]): GalleryInput[] | undefined {
  return parseInputs(raw, errors);
}

function parseInputs(raw: unknown, errors: string[]): GalleryInput[] | undefined {
  if (!Array.isArray(raw) || raw.length < 1 || raw.length > 6) {
    errors.push("inputs must be 1 to 6 questions");
    return;
  }
  const out: GalleryInput[] = [];
  raw.forEach((q, i) => {
    const at = `inputs[${i}]`;
    if (!isRecord(q)) {
      errors.push(`${at} must be an object`);
      return;
    }
    const start = errors.length;
    for (const k of Object.keys(q))
      if (!["key", "label", "type", "default", "options", "help"].includes(k))
        errors.push(`${at} can't have ${k}`);
    const key = typeof q.key === "string" && INPUT_KEY.test(q.key) ? q.key : undefined;
    if (!key) errors.push(`${at}.key must be lowercase letters, digits or _ (up to 32)`);
    else if (out.some((x) => x.key === key)) errors.push(`${at}.key ${key} is used twice`);
    const label = typeof q.label === "string" ? q.label.trim() : "";
    if (label.length < 1 || label.length > 60)
      errors.push(`${at}.label must be 1 to 60 characters`);
    const type = GALLERY_INPUT_TYPES.find((t) => t === q.type);
    if (!type) errors.push(`${at}.type must be one of ${GALLERY_INPUT_TYPES.join(", ")}`);
    let options: string[] | undefined;
    if (type === "choice") options = shortList(q.options, `${at}.options`, 60, 2, 8, errors);
    else if (q.options !== undefined) errors.push(`${at}.options are only for choice`);
    const help = q.help === undefined ? undefined : typeof q.help === "string" ? q.help.trim() : "";
    if (help !== undefined && (help.length < 1 || help.length > 120))
      errors.push(`${at}.help must be 1 to 120 characters`);
    const def = typeof q.default === "string" ? q.default.trim() : undefined;
    if (def === undefined || def.length < 1 || def.length > 120)
      errors.push(`${at}.default must be 1 to 120 characters (what older servers use)`);
    else if (type) {
      const why = checkInputValue(type, def, options);
      if (why) errors.push(`${at}.default ${why}`);
    }
    if (errors.length === start)
      out.push({
        key: key as string,
        label,
        type: type as GalleryInputType,
        default: def as string,
        ...(options ? { options } : {}),
        ...(help ? { help } : {}),
      });
  });
  return out;
}

/** Why an answer doesn't fit its question's type, or undefined when it does. */
export function checkInputValue(
  type: GalleryInputType,
  value: string,
  options?: string[],
): string | undefined {
  if (value.length < 1 || value.length > 120) return "must be 1 to 120 characters";
  if (type === "time" && !TIME.test(value)) return "must be a time such as 07:30";
  if (type === "timezone" && !TIMEZONE.test(value))
    return "must be a time zone such as Europe/Berlin";
  if (type === "choice" && !(options ?? []).includes(value)) return "must be one of the options";
  if (/[{}]/.test(value)) return "can't contain { or }";
  return;
}

export function parseGalleryMeta(
  raw: unknown,
  licenses: readonly string[],
  options: GalleryMetaOptions = {},
): { meta?: GalleryMeta; errors: string[] } {
  const errors: string[] = [];
  if (!isRecord(raw)) return { errors: ["item.json must be an object"] };
  const kind = options.kind;
  const name = typeof raw.name === "string" ? raw.name.trim() : "";
  if (name.length < 1 || name.length > 60) errors.push("name must be 1 to 60 characters");
  const author = isRecord(raw.author) ? raw.author : null;
  const authorName = author && typeof author.name === "string" ? author.name.trim() : "";
  if (authorName.length < 1 || authorName.length > 80) errors.push("author.name is required");
  let url: string | undefined;
  if (author && author.url != null) {
    if (typeof author.url !== "string" || !/^https:\/\/[^\s]+$/.test(author.url))
      errors.push("author.url must be an https link");
    else url = author.url;
  }
  let handle: string | undefined;
  if (author && author.handle !== undefined) {
    if (typeof author.handle !== "string" || !HANDLE.test(author.handle))
      errors.push("author.handle must be lowercase letters, digits and dashes (up to 39)");
    else handle = author.handle;
  }
  const license = typeof raw.license === "string" ? raw.license : "";
  if (!licenses.includes(license)) errors.push(`license must be one of ${licenses.join(", ")}`);
  const tags = Array.isArray(raw.tags) ? raw.tags : [];
  if (tags.length > 8) errors.push("at most 8 tags");
  const cleanTags: string[] = [];
  for (const t of tags) {
    if (typeof t !== "string" || !TAG.test(t)) errors.push(`bad tag ${String(t)}`);
    else cleanTags.push(t);
  }
  const version = raw.version == null ? 1 : raw.version;
  if (typeof version !== "number" || !Number.isInteger(version) || version < 1)
    errors.push("version must be a positive integer");
  const category = raw.category == null ? undefined : raw.category;
  if (category != null && (typeof category !== "string" || category.length > 40))
    errors.push("category must be a short string");
  const icon = raw.icon == null ? undefined : raw.icon;
  if (icon != null && (typeof icon !== "string" || !/^[a-z0-9][a-z0-9-]{0,39}$/.test(icon)))
    errors.push("icon must be a Lucide icon name such as notebook-pen");
  const featured = raw.featured === true;

  // Gallery v2 fields (D-315).
  let added: string | undefined;
  if (raw.added === undefined) {
    if (!options.allowMissingAdded) errors.push("added must be the YYYY-MM-DD it was added");
  } else if (!isGalleryDate(raw.added)) errors.push("added must be a YYYY-MM-DD date");
  else added = raw.added;
  let changelog: GalleryChangelogEntry[] | undefined;
  if (raw.changelog !== undefined && typeof version === "number")
    changelog = parseChangelog(raw.changelog, version, errors);
  else if (typeof version === "number" && version > 1)
    errors.push("changelog is required once version is above 1");
  let updated: string | undefined;
  if (raw.updated !== undefined) {
    if (!isGalleryDate(raw.updated)) errors.push("updated must be a YYYY-MM-DD date");
    else updated = raw.updated;
  }
  updated = updated ?? changelog?.[0]?.date ?? added;
  if (updated && added && updated < added) errors.push("updated can't be before added");
  if (updated && changelog?.[0] && updated < changelog[0].date)
    errors.push("updated can't be before the latest changelog entry");
  let pick: string | undefined;
  if (raw.pick !== undefined) {
    pick = typeof raw.pick === "string" ? raw.pick.trim() : "";
    if (!featured) errors.push("pick is only for featured items");
    if (pick.length < 1 || pick.length > 140) errors.push("pick must be 1 to 140 characters");
  }
  let examples: string[] | undefined;
  if (raw.examples !== undefined) {
    if (!allowedOn(GALLERY_EXAMPLE_KINDS, kind)) errors.push(`examples aren't for a ${kind}`);
    examples = shortList(raw.examples, "examples", 160, 1, 3, errors);
  }
  let access: GalleryAccess | undefined;
  if (raw.access !== undefined) {
    if (!allowedOn(GALLERY_ACCESS_KINDS, kind)) errors.push(`access isn't for a ${kind}`);
    access = parseAccess(raw.access, errors);
  }
  let needs: GalleryNeeds | undefined;
  if (raw.needs !== undefined) {
    if (!allowedOn(GALLERY_NEEDS_KINDS, kind)) errors.push(`needs aren't for a ${kind}`);
    needs = parseNeeds(raw.needs, errors);
  }
  let inputs: GalleryInput[] | undefined;
  if (raw.inputs !== undefined) {
    if (!allowedOn(GALLERY_INPUT_KINDS, kind)) errors.push(`inputs aren't for a ${kind}`);
    inputs = parseInputs(raw.inputs, errors);
  }
  const remix_of =
    raw.remix_of === undefined ? undefined : itemRef(raw.remix_of, "remix_of", errors);
  const replaced_by =
    raw.replaced_by === undefined ? undefined : itemRef(raw.replaced_by, "replaced_by", errors);
  const versions: Partial<Record<"min_app" | "min_server", string>> = {};
  for (const key of ["min_app", "min_server"] as const) {
    if (raw[key] === undefined) continue;
    if (typeof raw[key] !== "string" || !SEMVER.test(raw[key] as string))
      errors.push(`${key} must be a version such as 0.2.0`);
    else versions[key] = raw[key] as string;
  }
  let season: GallerySeason | undefined;
  if (raw.season !== undefined) {
    const s = raw.season;
    if (
      !isRecord(s) ||
      !isMonthDay(s.from) ||
      !isMonthDay(s.to) ||
      s.from === s.to ||
      Object.keys(s).some((k) => k !== "from" && k !== "to")
    )
      errors.push('season must be { "from": "MM-DD", "to": "MM-DD" }');
    else season = { from: s.from as string, to: s.to as string };
  }
  if (errors.length) return { errors };
  return {
    errors,
    meta: {
      name,
      author: { name: authorName, ...(url ? { url } : {}), ...(handle ? { handle } : {}) },
      license,
      tags: cleanTags,
      featured,
      retired: raw.retired === true,
      version: version as number,
      ...(typeof category === "string" ? { category } : {}),
      ...(typeof icon === "string" ? { icon } : {}),
      ...(added ? { added } : {}),
      ...(updated ? { updated } : {}),
      ...(changelog ? { changelog } : {}),
      ...(pick ? { pick } : {}),
      ...(examples ? { examples } : {}),
      ...(access ? { access } : {}),
      ...(needs ? { needs } : {}),
      ...(inputs ? { inputs } : {}),
      ...(remix_of ? { remix_of } : {}),
      ...(replaced_by ? { replaced_by } : {}),
      ...versions,
      ...(season ? { season } : {}),
    },
  };
}

/**
 * The newer fields an index record carries after the older ones, in the order both checkers write
 * them (D-315). `access` is the item's, with `runs_code` and `computer` forced on when a skill
 * brings scripts; `tested` comes from tested.json.
 */
export function galleryRecordExtras(
  meta: GalleryMeta,
  extra: { access?: GalleryAccess; tested?: { version: number; date: string } } = {},
): Record<string, unknown> {
  const access = extra.access ?? meta.access;
  return {
    ...(meta.changelog ? { changelog: meta.changelog } : {}),
    ...(meta.pick ? { pick: meta.pick } : {}),
    ...(meta.examples ? { examples: meta.examples } : {}),
    ...(access ? { access } : {}),
    ...(meta.needs ? { needs: meta.needs } : {}),
    ...(meta.inputs ? { inputs: meta.inputs } : {}),
    ...(meta.remix_of ? { remix_of: meta.remix_of } : {}),
    ...(meta.replaced_by ? { replaced_by: meta.replaced_by } : {}),
    ...(meta.min_app ? { min_app: meta.min_app } : {}),
    ...(meta.min_server ? { min_server: meta.min_server } : {}),
    ...(meta.season ? { season: meta.season } : {}),
    ...(extra.tested ? { tested: extra.tested } : {}),
  };
}

/** A skill's access with code and a computer marked when it brings scripts. */
export function galleryAccessFor(
  kind: GalleryKind,
  access: GalleryAccess | undefined,
  paths: string[],
): { access?: GalleryAccess; errors: string[] } {
  if (kind !== "skill" || !galleryHasScripts(paths)) return { access, errors: [] };
  const errors: string[] = [];
  if (access?.runs_code === false || access?.computer === false)
    errors.push("access says no code or computer, but the skill brings scripts");
  return { access: { ...access, runs_code: true, computer: true }, errors };
}

function checkSeeds(label: string, raw: unknown, errors: string[]): SeedColors | undefined {
  if (!isRecord(raw)) {
    errors.push(`${label} must be an object with seed, background and onBackground`);
    return;
  }
  const seed = raw.seed;
  const background = raw.background;
  const onBackground = raw.onBackground;
  for (const [key, value] of [
    ["seed", seed],
    ["background", background],
    ["onBackground", onBackground],
  ] as const) {
    if (typeof value !== "string" || !HEX.test(value))
      errors.push(`${label}.${key} must be a #RRGGBB color`);
  }
  if (
    typeof background === "string" &&
    typeof onBackground === "string" &&
    HEX.test(background) &&
    HEX.test(onBackground) &&
    contrastRatio(background, onBackground) < 4.5
  )
    errors.push(`${label} text on background is below WCAG AA (4.5:1)`);
  if (
    typeof seed === "string" &&
    typeof background === "string" &&
    typeof onBackground === "string"
  )
    return { seed, background, onBackground };
  return;
}

/** The six colors a full scheme gives together, per brightness; `appBar` may join them. */
export const SCHEME_COLOR_KEYS = [
  "primary",
  "primaryContainer",
  "secondary",
  "secondaryContainer",
  "tertiary",
  "tertiaryContainer",
] as const;

/** Whether a scheme's light or dark side gives exact colors next to its seeds. */
function hasSchemeColors(raw: unknown): boolean {
  return (
    isRecord(raw) &&
    (SCHEME_COLOR_KEYS.some((k) => raw[k] !== undefined) || raw.appBar !== undefined)
  );
}

/**
 * A full scheme's exact colors on one side (`light` or `dark`), next to its seeds: all six of
 * {@link SCHEME_COLOR_KEYS} or none, `appBar` optional. Accents need 4.5:1 on `background`, and
 * `onBackground` needs 4.5:1 on each container.
 */
export function checkSchemeColors(label: string, raw: unknown, errors: string[]): void {
  if (!isRecord(raw) || !hasSchemeColors(raw)) return;
  const given = SCHEME_COLOR_KEYS.filter((k) => raw[k] !== undefined);
  if (given.length !== SCHEME_COLOR_KEYS.length) {
    errors.push(`${label} must give all of ${SCHEME_COLOR_KEYS.join(", ")} or none`);
    return;
  }
  let valid = true;
  for (const key of [...SCHEME_COLOR_KEYS, ...(raw.appBar !== undefined ? ["appBar"] : [])]) {
    const value = raw[key];
    if (typeof value !== "string" || !HEX.test(value)) {
      errors.push(`${label}.${key} must be a #RRGGBB color`);
      valid = false;
    }
  }
  const background = raw.background;
  const onBackground = raw.onBackground;
  if (!valid || typeof background !== "string" || !HEX.test(background)) return;
  if (typeof onBackground !== "string" || !HEX.test(onBackground)) return;
  for (const key of ["primary", "secondary", "tertiary"] as const) {
    if (contrastRatio(raw[key] as string, background) < 4.5)
      errors.push(`${label}.${key} on background is below WCAG AA (4.5:1)`);
  }
  for (const key of ["primaryContainer", "secondaryContainer", "tertiaryContainer"] as const) {
    if (contrastRatio(onBackground, raw[key] as string) < 4.5)
      errors.push(`${label} text on ${key} is below WCAG AA (4.5:1)`);
  }
}

/** Lucide's icon nodes by name, as `assets/lucide/icon-nodes.json` holds them. */
export type LucideNodes = Record<string, [string, Record<string, unknown>][]>;

/** One element of a doodle, in Lucide's node format. */
export type DoodleElement = [string, Record<string, string | number>];

const DOODLE_POSITION = [-2, 26] as const;
const DOODLE_SIZE = [0, 26] as const;
/** Each tag's attributes: required, optional, and which are sizes rather than positions. */
const DOODLE_TAGS: Record<string, { required: string[]; optional: string[]; sizes: string[] }> = {
  path: { required: ["d"], optional: [], sizes: [] },
  circle: { required: ["cx", "cy", "r"], optional: [], sizes: ["r"] },
  ellipse: { required: ["cx", "cy", "rx", "ry"], optional: [], sizes: ["rx", "ry"] },
  rect: {
    required: ["x", "y", "width", "height"],
    optional: ["rx", "ry"],
    sizes: ["width", "height", "rx", "ry"],
  },
  line: { required: ["x1", "y1", "x2", "y2"], optional: [], sizes: [] },
  polyline: { required: ["points"], optional: [], sizes: [] },
  polygon: { required: ["points"], optional: [], sizes: [] },
};
const PATH_DATA = /^[MmLlHhVvCcSsQqTtAaZz0-9eE.,+\-\s]+$/;
const NUMBER = /^\s*[+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?\s*$/;

function numberOf(v: unknown): number | undefined {
  if (typeof v === "number") return Number.isFinite(v) ? v : undefined;
  if (typeof v === "string" && NUMBER.test(v)) return Number(v);
  return;
}

/**
 * A wallpaper's own doodles: 1 to 24, each 1 to 24 elements on a 24 × 24 grid, drawn as strokes.
 * Tags and attributes are a fixed list; numbers may be numbers or numeric strings.
 */
export function checkDoodles(raw: unknown, errors: string[]): void {
  if (!Array.isArray(raw) || raw.length < 1 || raw.length > 24) {
    errors.push("doodles must be 1 to 24 drawings");
    return;
  }
  raw.forEach((doodle, i) => {
    const at = `doodles[${i}]`;
    if (!Array.isArray(doodle) || doodle.length < 1 || doodle.length > 24) {
      errors.push(`${at} must be 1 to 24 elements`);
      return;
    }
    doodle.forEach((element, j) => {
      const where = `${at}[${j}]`;
      if (!Array.isArray(element) || element.length !== 2 || !isRecord(element[1])) {
        errors.push(`${where} must be [tag, attributes]`);
        return;
      }
      const [tag, attrs] = element as [unknown, Record<string, unknown>];
      const spec = typeof tag === "string" ? DOODLE_TAGS[tag] : undefined;
      if (!spec) {
        errors.push(`${where} tag must be one of ${Object.keys(DOODLE_TAGS).join(", ")}`);
        return;
      }
      for (const key of Object.keys(attrs)) {
        if (!spec.required.includes(key) && !spec.optional.includes(key))
          errors.push(`${where} ${tag} can't have ${key}`);
      }
      for (const key of spec.required) {
        if (attrs[key] === undefined) errors.push(`${where} ${tag} needs ${key}`);
      }
      for (const key of [...spec.required, ...spec.optional]) {
        const value = attrs[key];
        if (value === undefined) continue;
        if (key === "d") {
          if (typeof value !== "string" || value.length > 1500 || !PATH_DATA.test(value))
            errors.push(`${where} d must be at most 1500 characters of path commands and numbers`);
          continue;
        }
        if (key === "points") {
          const numbers =
            typeof value === "string" && /^[0-9eE.,+\-\s]+$/.test(value)
              ? value
                  .trim()
                  .split(/[\s,]+/)
                  .map(numberOf)
              : [];
          if (
            numbers.length < 2 ||
            numbers.length % 2 !== 0 ||
            numbers.some((n) => n === undefined || n < DOODLE_POSITION[0] || n > DOODLE_POSITION[1])
          )
            errors.push(`${where} points must be an even count of numbers between -2 and 26`);
          continue;
        }
        const n = numberOf(value);
        const [lo, hi] = spec.sizes.includes(key) ? DOODLE_SIZE : DOODLE_POSITION;
        if (n === undefined || n < lo || n > hi)
          errors.push(`${where} ${key} must be a number between ${lo} and ${hi}`);
      }
    });
  });
}

/** Lucide icons by name as doodles, without Lucide's `key` attributes. */
export function resolveGlyphs(names: string[], lucide: LucideNodes): DoodleElement[][] {
  return names.map((name) =>
    (lucide[name] ?? []).map(([tag, attrs]) => {
      const { key: _key, ...rest } = attrs;
      return [tag, rest as Record<string, string | number>];
    }),
  );
}

function checkGlyphs(raw: unknown, errors: string[], lucide?: LucideNodes) {
  if (!Array.isArray(raw) || raw.length < 1 || raw.length > 24) {
    errors.push("glyphs must be 1 to 24 Lucide icon names");
    return;
  }
  raw.forEach((name, i) => {
    if (typeof name !== "string" || !/^[a-z0-9][a-z0-9-]*$/.test(name))
      errors.push(`glyphs[${i}] must be a Lucide icon name`);
    else if (lucide && !Object.hasOwn(lucide, name))
      errors.push(`glyphs[${i}] ${name} isn't a Lucide icon`);
  });
}

/** What a look needs from the app: newer apps hide items that need something they can't draw. */
export const GALLERY_REQUIREMENTS = ["doodles", "mesh", "scheme-colors"] as const;
export type GalleryRequirement = (typeof GALLERY_REQUIREMENTS)[number];

/** The features a theme, scheme or wallpaper document uses, sorted. */
export function galleryRequires(type: GalleryType, raw: unknown): GalleryRequirement[] {
  if (!isRecord(raw)) return [];
  const found = new Set<GalleryRequirement>();
  const wallpaper = (w: unknown) => {
    if (!isRecord(w)) return;
    if (w.mesh !== undefined) found.add("mesh");
    if (w.doodles !== undefined || w.glyphs !== undefined) found.add("doodles");
  };
  const scheme = (sc: unknown) => {
    if (isRecord(sc) && (hasSchemeColors(sc.light) || hasSchemeColors(sc.dark)))
      found.add("scheme-colors");
  };
  if (type === "wallpaper") wallpaper(raw);
  if (type === "scheme") scheme(raw);
  if (type === "theme") {
    wallpaper(raw.wallpaper);
    scheme(raw.scheme);
  }
  return GALLERY_REQUIREMENTS.filter((r) => found.has(r));
}

/**
 * The document as index.json carries it: a wallpaper's `glyphs` (its own, or a theme's) resolved
 * into `doodles`, so apps need no copy of Lucide. Other documents are returned as they are.
 */
export function galleryIndexDocument(
  type: GalleryType,
  raw: unknown,
  lucide: LucideNodes,
): unknown {
  if (!isRecord(raw)) return raw;
  const withDoodles = (w: Record<string, unknown>) =>
    Array.isArray(w.glyphs) && w.doodles === undefined
      ? { ...w, doodles: resolveGlyphs(w.glyphs as string[], lucide) }
      : w;
  if (type === "wallpaper") return withDoodles(raw);
  if (type === "theme" && isRecord(raw.wallpaper))
    return { ...raw, wallpaper: withDoodles(raw.wallpaper) };
  return raw;
}

/** Options for the document checks: Lucide's nodes, so `glyphs` names can be checked. */
export interface GalleryCheckOptions {
  lucide?: LucideNodes;
}

export function checkSchemeDocument(raw: unknown): string[] {
  const errors: string[] = [];
  if (!isRecord(raw)) return ["scheme.json must be an object"];
  checkSeeds("light", raw.light, errors);
  checkSeeds("dark", raw.dark, errors);
  checkSchemeColors("light", raw.light, errors);
  checkSchemeColors("dark", raw.dark, errors);
  return errors;
}

/**
 * A mesh gradient: `light` and `dark` are nine #RRGGBB colors each, row by row from the top left;
 * `points` (optional) are nine [x, y] fractions of the window. Corners sit at the corners and edge
 * points on their edge; the app pins them there anyway.
 */
function checkMesh(raw: unknown, errors: string[]) {
  if (!isRecord(raw)) {
    errors.push("mesh must be an object with light, dark and optional points");
    return;
  }
  for (const key of ["light", "dark"] as const) {
    const colors = raw[key];
    if (!Array.isArray(colors) || colors.length !== 9) {
      errors.push(`mesh.${key} must be nine #RRGGBB colors`);
      continue;
    }
    colors.forEach((c, i) => {
      if (typeof c !== "string" || !HEX.test(c)) {
        errors.push(`mesh.${key}[${i}] must be a #RRGGBB color`);
        return;
      }
      const lum = luminance(c);
      if (key === "light" && lum < MESH_MIN_LIGHT_LUMINANCE)
        errors.push(
          `mesh.light[${i}] ${c} is too dark for text on top (luminance under ${MESH_MIN_LIGHT_LUMINANCE})`,
        );
      if (key === "dark" && lum > MESH_MAX_DARK_LUMINANCE)
        errors.push(
          `mesh.dark[${i}] ${c} is too light for text on top (luminance over ${MESH_MAX_DARK_LUMINANCE})`,
        );
    });
  }
  const points = raw.points;
  if (points === undefined) return;
  if (!Array.isArray(points) || points.length !== 9) {
    errors.push("mesh.points must be nine [x, y] pairs");
    return;
  }
  points.forEach((p, i) => {
    if (
      !Array.isArray(p) ||
      p.length !== 2 ||
      !p.every((v) => typeof v === "number" && Number.isFinite(v) && v >= 0 && v <= 1)
    ) {
      errors.push(`mesh.points[${i}] must be [x, y] between 0 and 1`);
      return;
    }
    const [x, y] = p as [number, number];
    const col = i % 3;
    const row = Math.floor(i / 3);
    if ((col !== 1 && x !== col / 2) || (row !== 1 && y !== row / 2))
      errors.push(`mesh.points[${i}] must stay on its corner or edge`);
    if ((col === 1 && (x < 0.2 || x > 0.8)) || (row === 1 && (y < 0.2 || y > 0.8)))
      errors.push(`mesh.points[${i}] must stay between 0.2 and 0.8 inside the window`);
  });
}

function checkWallpaperFields(raw: unknown, errors: string[], options: GalleryCheckOptions = {}) {
  if (!isRecord(raw)) {
    errors.push("wallpaper must be an object");
    return;
  }
  if (raw.glyphs !== undefined && raw.doodles !== undefined)
    errors.push("wallpaper has glyphs and doodles; give one");
  else if (raw.glyphs !== undefined) checkGlyphs(raw.glyphs, errors, options.lucide);
  else if (raw.doodles !== undefined) checkDoodles(raw.doodles, errors);
  if (raw.mesh !== undefined) {
    checkMesh(raw.mesh, errors);
    // Older apps ignore the mesh and draw the palette, so it must be one they know.
    if (
      typeof raw.palette === "string" &&
      !WALLPAPER_FALLBACK_PALETTES.includes(raw.palette as never)
    )
      errors.push(
        `with a mesh, wallpaper.palette is the fallback and must be one of ${WALLPAPER_FALLBACK_PALETTES.join(", ")}`,
      );
  }
  if (typeof raw.pattern !== "string" || !WALLPAPER_PATTERNS.includes(raw.pattern as never))
    errors.push(`wallpaper.pattern must be one of ${WALLPAPER_PATTERNS.join(", ")}`);
  if (typeof raw.palette !== "string" || !WALLPAPER_PALETTES.includes(raw.palette as never))
    errors.push(`wallpaper.palette must be one of ${WALLPAPER_PALETTES.join(", ")}`);
  if (typeof raw.intensity !== "number" || raw.intensity < 0 || raw.intensity > 1)
    errors.push("wallpaper.intensity must be between 0 and 1");
}

export function checkThemeDocument(raw: unknown, options: GalleryCheckOptions = {}): string[] {
  const errors: string[] = [];
  if (!isRecord(raw)) return ["theme.json must be an object"];
  if (raw.v !== 2) errors.push("theme.json v must be 2");
  if (typeof raw.scheme === "string") {
    if (!ID.test(raw.scheme)) errors.push("scheme id must be lowercase letters, digits and dashes");
  } else {
    if (!isRecord(raw.scheme)) errors.push("scheme must be an id or light and dark seeds");
    else {
      checkSeeds("scheme.light", raw.scheme.light, errors);
      checkSeeds("scheme.dark", raw.scheme.dark, errors);
      checkSchemeColors("scheme.light", raw.scheme.light, errors);
      checkSchemeColors("scheme.dark", raw.scheme.dark, errors);
    }
  }
  for (const key of ["headingFont", "bodyFont"] as const) {
    const font = raw[key];
    if (typeof font !== "string" || !GALLERY_FONTS.includes(font as never))
      errors.push(`${key} must be one of the app's fonts`);
  }
  checkWallpaperFields(raw.wallpaper, errors, options);
  return errors;
}

export function checkWallpaperDocument(
  raw: unknown,
  files: { path: string; bytes: number }[],
  options: GalleryCheckOptions = {},
): string[] {
  const errors: string[] = [];
  if (!isRecord(raw)) return ["wallpaper.json must be an object"];
  if (raw.kind === "pattern") {
    if (raw.mesh !== undefined) errors.push('a wallpaper with a mesh is kind "mesh"');
    checkWallpaperFields(raw, errors, options);
    return errors;
  }
  if (raw.kind === "mesh") {
    if (raw.mesh === undefined) errors.push("a mesh wallpaper needs a mesh");
    checkWallpaperFields(raw, errors, options);
    return errors;
  }
  if (raw.kind === "image") {
    const file = raw.file;
    if (typeof file !== "string" || !/^[A-Za-z0-9._-]+\.(webp|jpe?g)$/.test(file)) {
      errors.push("image file must be a webp or jpeg in this folder");
      return errors;
    }
    const found = files.find((f) => f.path === file);
    if (!found) errors.push(`missing ${file}`);
    else if (found.bytes > 2 * 1024 * 1024) errors.push(`${file} is over 2 MB`);
    const extra = (key: string, limit: number, label: string) => {
      const name = raw[key];
      if (name === undefined) return;
      if (typeof name !== "string" || !/^[A-Za-z0-9._-]+\.(webp|jpe?g)$/.test(name))
        errors.push(`${key} must be a webp or jpeg in this folder`);
      else {
        const f = files.find((x) => x.path === name);
        if (!f) errors.push(`missing ${name}`);
        else if (f.bytes > limit) errors.push(`${name} is over ${label}`);
      }
    };
    // A small copy for gallery cards, so a grid doesn't download every full-size image.
    extra("thumb", 200 * 1024, "200 KB");
    // The same picture for dark mode, and its small copy (D-388).
    extra("dark", 2 * 1024 * 1024, "2 MB");
    if (raw.darkThumb !== undefined && raw.dark === undefined) errors.push("darkThumb needs dark");
    extra("darkThumb", 200 * 1024, "200 KB");
    return errors;
  }
  errors.push('wallpaper kind must be "pattern", "mesh" or "image"');
  return errors;
}

export function checkSkillDocument(id: string, skillMd: string): string[] {
  try {
    const parsed = parseSkillMd(skillMd);
    if (parsed.name !== id) return [`SKILL.md name is ${parsed.name}; the folder is ${id}`];
    return [];
  } catch (err) {
    return [err instanceof SkillFormatError ? err.message : "SKILL.md is not a skill"];
  }
}

export function checkGalleryId(id: string): string | undefined {
  return ID.test(id) ? undefined : "folder name must be lowercase letters, digits and dashes";
}
