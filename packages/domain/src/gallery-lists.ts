/**
 * Content lists from the gallery (D-372): small first-party lists that change more often than we
 * release, kept in `gallery/lists/<id>.json` and published as `lists.json` (signed with the rest
 * of the manifest). Every reader keeps its built-in copy as the fallback: a list that is missing,
 * can't be read or has no usable entries changes nothing.
 *
 * Readers are lenient on purpose (shipped apps and servers must never break on a newer list):
 * unknown keys are ignored, a bad entry is skipped and the rest are kept. `checkGalleryList` is
 * the strict version the tests run over the gallery's own files.
 */
import type { CatalogApp } from "./apps.ts";

/** The record type every entry of lists.json carries. */
export const GALLERY_LIST_TYPE = "list";

/** The lists this version reads; lists.json may carry others, which are ignored. */
export const GALLERY_LIST_IDS = ["search-words", "welcome", "starters", "app-curation"] as const;
export type GalleryListId = (typeof GALLERY_LIST_IDS)[number];

function isRecord(v: unknown): v is Record<string, unknown> {
  return typeof v === "object" && v !== null && !Array.isArray(v);
}

const str = (v: unknown, max: number, min = 1): string | undefined => {
  if (typeof v !== "string") return undefined;
  const t = v.trim();
  return t.length >= min && t.length <= max ? t : undefined;
};

// ---------------------------------------------------------------- search words

/** A word and the other words people use for the same thing. */
export type SearchWords = Record<string, string[]>;

const WORD = /^[a-z0-9][a-z0-9' -]{0,30}$/;

/** `{ words: { mail: ["email", …] } }` → the map, bad words dropped; undefined when nothing's left. */
export function parseSearchWords(raw: unknown): SearchWords | undefined {
  const words = isRecord(raw) && isRecord(raw.words) ? raw.words : undefined;
  if (!words) return undefined;
  const out: SearchWords = {};
  let n = 0;
  for (const [k, v] of Object.entries(words)) {
    if (n >= 500) break;
    const key = k.trim().toLowerCase();
    if (!WORD.test(key) || !Array.isArray(v)) continue;
    const list = [
      ...new Set(
        v
          .filter((x): x is string => typeof x === "string")
          .map((x) => x.trim().toLowerCase())
          .filter((x) => WORD.test(x) && x !== key),
      ),
    ].slice(0, 12);
    if (!list.length) continue;
    out[key] = list;
    n++;
  }
  return n ? out : undefined;
}

// ---------------------------------------------------------------- welcome chat

/** One focus choice of the welcome chat. Ids are fixed (analytics); the words around them aren't. */
export interface WelcomeFocusContent {
  id: string;
  label?: string;
  /** What the bot says it can do for this pick. */
  intro?: string;
  /** The first task card when nothing is connected. */
  first_task?: { label: string; placeholder: string; prefix: string };
  /** Starter bot ids worth suggesting for this pick. */
  starters?: string[];
  /** The main connection: app ids from the catalog. */
  apps?: string[];
}

const ITEM_ID = /^[a-z0-9][a-z0-9_-]{0,62}$/;

const idList = (v: unknown, max: number): string[] | undefined =>
  Array.isArray(v)
    ? [...new Set(v.filter((x): x is string => typeof x === "string" && ITEM_ID.test(x)))].slice(
        0,
        max,
      )
    : undefined;

/**
 * `{ focus: [...] }` → the entries for focus ids this version knows (others are skipped, so a new
 * id never reaches analytics or the cards before code knows it). Only valid fields are kept.
 */
export function parseWelcomeContent(
  raw: unknown,
  knownIds: readonly string[],
): WelcomeFocusContent[] {
  const list = isRecord(raw) && Array.isArray(raw.focus) ? raw.focus : [];
  const out: WelcomeFocusContent[] = [];
  for (const f of list) {
    if (!isRecord(f) || typeof f.id !== "string" || !knownIds.includes(f.id)) continue;
    if (out.some((x) => x.id === f.id)) continue;
    const entry: WelcomeFocusContent = { id: f.id };
    const label = str(f.label, 40);
    if (label) entry.label = label;
    const intro = str(f.intro, 400);
    if (intro) entry.intro = intro;
    if (isRecord(f.first_task)) {
      const t = f.first_task;
      const l = str(t.label, 120);
      const p = str(t.placeholder, 120);
      const prefix = typeof t.prefix === "string" && t.prefix.length <= 200 ? t.prefix : undefined;
      if (l && p && prefix !== undefined) entry.first_task = { label: l, placeholder: p, prefix };
    }
    const starters = idList(f.starters, 4);
    if (starters) entry.starters = starters;
    const apps = idList(f.apps, 4);
    if (apps) entry.apps = apps;
    out.push(entry);
  }
  return out;
}

// ---------------------------------------------------------------- empty-state starters

export interface LibraryStarter {
  id: string;
  label: string;
  /** The request typed into quick ask. */
  prompt: string;
  /** Lucide icon name; the app falls back to its own when it doesn't ship that icon. */
  icon: string;
  /** Hue of the cover's tint, 0 to 360. */
  hue: number;
}

export interface TextStarter {
  id: string;
  text: string;
}

/** Things to start from on empty screens: the Library, Tasks and Help & support. */
export interface EmptyStarters {
  library?: LibraryStarter[];
  tasks?: TextStarter[];
  support?: TextStarter[];
}

const ICON = /^[a-z0-9][a-z0-9-]{0,39}$/;

function textStarters(v: unknown, max: number, maxLen: number): TextStarter[] | undefined {
  if (!Array.isArray(v)) return undefined;
  const out: TextStarter[] = [];
  for (const s of v) {
    if (out.length >= max) break;
    if (!isRecord(s) || typeof s.id !== "string" || !ITEM_ID.test(s.id)) continue;
    const text = str(s.text, maxLen);
    if (text && !out.some((x) => x.id === s.id)) out.push({ id: s.id, text });
  }
  return out.length ? out : undefined;
}

/** `{ library, tasks, support }` → the usable entries of each; a list with none is left out. */
export function parseEmptyStarters(raw: unknown): EmptyStarters {
  if (!isRecord(raw)) return {};
  const out: EmptyStarters = {};
  if (Array.isArray(raw.library)) {
    const library: LibraryStarter[] = [];
    for (const s of raw.library) {
      if (library.length >= 9) break;
      if (!isRecord(s) || typeof s.id !== "string" || !ITEM_ID.test(s.id)) continue;
      const label = str(s.label, 40);
      // A trailing space is kept: "Make a short video of " waits for the rest.
      const prompt = str(s.prompt, 300) ? (s.prompt as string).trimStart() : undefined;
      const icon = typeof s.icon === "string" && ICON.test(s.icon) ? s.icon : "sparkles";
      const hue = typeof s.hue === "number" && s.hue >= 0 && s.hue <= 360 ? s.hue : 265;
      if (label && prompt && !library.some((x) => x.id === s.id))
        library.push({ id: s.id, label, prompt, icon, hue });
    }
    if (library.length) out.library = library;
  }
  const tasks = textStarters(raw.tasks, 6, 160);
  if (tasks) out.tasks = tasks;
  const support = textStarters(raw.support, 6, 120);
  if (support) out.support = support;
  return out;
}

// ---------------------------------------------------------------- app catalog curation

/**
 * Display fields over the built-in app catalog. Never sign-in details: scopes, MCP addresses,
 * OAuth clients and Zoho's hosts stay in code.
 */
export interface AppCuration {
  apps: Array<{
    id: string;
    name?: string;
    description?: string;
    color?: string;
    featured?: boolean;
  }>;
  /** Ids shown first, in this order; the rest keep theirs. */
  order?: string[];
  /** The apps an empty chat offers to connect first, in order. */
  starter_apps?: string[];
}

const COLOR = /^[0-9A-Fa-f]{6}$/;

export function parseAppCuration(raw: unknown): AppCuration | undefined {
  if (!isRecord(raw)) return undefined;
  const apps: AppCuration["apps"] = [];
  for (const a of Array.isArray(raw.apps) ? raw.apps : []) {
    if (apps.length >= 200) break;
    if (!isRecord(a) || typeof a.id !== "string" || !ITEM_ID.test(a.id)) continue;
    if (apps.some((x) => x.id === a.id)) continue;
    const name = str(a.name, 60);
    const description = str(a.description, 300);
    const color = typeof a.color === "string" && COLOR.test(a.color) ? a.color : undefined;
    const featured = typeof a.featured === "boolean" ? a.featured : undefined;
    apps.push({
      id: a.id,
      ...(name ? { name } : {}),
      ...(description ? { description } : {}),
      ...(color ? { color } : {}),
      ...(featured !== undefined ? { featured } : {}),
    });
  }
  const order = idList(raw.order, 200);
  const starter = idList(raw.starter_apps, 8);
  if (!apps.length && !order?.length && !starter?.length) return undefined;
  return {
    apps,
    ...(order?.length ? { order } : {}),
    ...(starter?.length ? { starter_apps: starter } : {}),
  };
}

/**
 * The catalog with the curation's display fields on the apps it names (`builtIn` ids only: a
 * gallery app is curated in its own entry), then the curation's order. Everything that signs in or
 * connects is left as it is.
 */
export function curateCatalog<T extends CatalogApp>(
  apps: T[],
  curation: AppCuration | undefined,
  builtIn: ReadonlySet<string>,
): T[] {
  if (!curation) return apps;
  const by = new Map(curation.apps.map((a) => [a.id, a]));
  const out = apps.map((a) => {
    const c = builtIn.has(a.id) ? by.get(a.id) : undefined;
    if (!c) return a;
    return {
      ...a,
      ...(c.name ? { name: c.name } : {}),
      ...(c.description ? { description: c.description } : {}),
      ...(c.color ? { color: c.color } : {}),
      ...(c.featured !== undefined ? { popular: c.featured } : {}),
    };
  });
  const order = curation.order ?? [];
  if (!order.length) return out;
  const rank = new Map(order.map((id, i) => [id, i]));
  return out
    .map((a, i) => ({ a, i }))
    .sort((x, y) => {
      const rx = rank.get(x.a.id) ?? order.length + x.i;
      const ry = rank.get(y.a.id) ?? order.length + y.i;
      return rx - ry;
    })
    .map((x) => x.a);
}

// ---------------------------------------------------------------- the file

/** Every list this version reads, parsed; a list that's missing or unusable is undefined. */
export interface GalleryLists {
  searchWords?: SearchWords;
  welcome?: unknown;
  starters?: EmptyStarters;
  appCuration?: AppCuration;
}

/** lists.json's records → the lists. Welcome stays raw: only the agent knows its focus ids. */
export function parseGalleryLists(records: unknown[]): GalleryLists {
  const out: GalleryLists = {};
  for (const r of records) {
    if (!isRecord(r) || r.type !== GALLERY_LIST_TYPE || r.retired === true) continue;
    const doc = r.document;
    switch (r.id) {
      case "search-words":
        out.searchWords ??= parseSearchWords(doc);
        break;
      case "welcome":
        out.welcome ??= doc;
        break;
      case "starters": {
        const s = parseEmptyStarters(doc);
        if (Object.keys(s).length) out.starters ??= s;
        break;
      }
      case "app-curation":
        out.appCuration ??= parseAppCuration(doc);
        break;
    }
  }
  return out;
}

/**
 * Strict check of one list's document, for the gallery's own files: anything the lenient reader
 * would drop is an error here.
 */
export function checkGalleryList(
  id: string,
  doc: unknown,
  opts: { welcomeIds?: readonly string[] } = {},
): string[] {
  const errors: string[] = [];
  if (!isRecord(doc)) return ["the list must be an object"];
  const count = (v: unknown) =>
    Array.isArray(v) ? v.length : isRecord(v) ? Object.keys(v).length : 0;
  switch (id) {
    case "search-words": {
      const got = parseSearchWords(doc);
      const words = isRecord(doc.words) ? doc.words : {};
      if (!got || Object.keys(got).length !== Object.keys(words).length)
        errors.push("every word must be lowercase with a list of other words");
      for (const [k, v] of Object.entries(words))
        if (!Array.isArray(v) || got?.[k]?.length !== v.length)
          errors.push(`words.${k}: bad, repeated or more than 12 words`);
      break;
    }
    case "welcome": {
      const ids = opts.welcomeIds ?? [];
      const got = parseWelcomeContent(doc, ids);
      if (got.length !== count(doc.focus)) errors.push("every focus needs an id the app knows");
      (Array.isArray(doc.focus) ? doc.focus : []).forEach((f, i) => {
        const g = got.find((x) => isRecord(f) && x.id === f.id);
        if (!g || !isRecord(f)) return;
        for (const k of ["label", "intro", "first_task", "starters", "apps"] as const)
          if (f[k] !== undefined && g[k] === undefined) errors.push(`focus[${i}].${k} isn't valid`);
      });
      break;
    }
    case "starters": {
      const got = parseEmptyStarters(doc);
      for (const k of ["library", "tasks", "support"] as const)
        if (doc[k] !== undefined && (got[k]?.length ?? 0) !== count(doc[k]))
          errors.push(`${k}: an entry is missing a field, repeats an id or is too long`);
      break;
    }
    case "app-curation": {
      const got = parseAppCuration(doc);
      if (!got) errors.push("app-curation names no apps");
      else if (got.apps.length !== count(doc.apps)) errors.push("apps: a bad or repeated entry");
      if (
        doc.starter_apps !== undefined &&
        (got?.starter_apps?.length ?? 0) !== count(doc.starter_apps)
      )
        errors.push("starter_apps: at most 8 app ids");
      const allowed = ["id", "name", "description", "color", "featured"];
      for (const a of Array.isArray(doc.apps) ? doc.apps : [])
        if (isRecord(a))
          for (const k of Object.keys(a))
            if (!allowed.includes(k))
              errors.push(`apps.${String(a.id)}.${k}: only display fields (${allowed.join(", ")})`);
      break;
    }
    default:
      errors.push(`unknown list ${id}`);
  }
  return errors;
}
