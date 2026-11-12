/**
 * The open gallery (D-184). The API caches index.json and checks a skill's files against the
 * index hash before installing them. Apps (D-239) come from apps.json, cached the same way, and
 * join the built-in catalog. An empty GALLERY_URL turns the gallery off.
 */
import {
  APP_CATALOG,
  BOT_TEMPLATES,
  type BotTemplate,
  botTemplateFromGallery,
  type CatalogApp,
  catalogAppFromGallery,
  checkPluginDocument,
  checkRoutineDocument,
  GALLERY_APP_TYPE,
  GALLERY_BOT_TYPE,
  GALLERY_PLUGIN_TYPE,
  GALLERY_ROUTINE_TYPE,
  GALLERY_TYPES,
  type GalleryPluginDocument,
  type GalleryRoutineDocument,
  type GalleryType,
  galleryHash,
} from "@casama/domain";
import { ApiError } from "../api/errors.ts";
import type { Env } from "../env.ts";
import { bundleFrom, type CatalogSkill, loadCatalog, type SkillBundle } from "./skills.ts";

export interface GalleryAuthor {
  name: string;
  url?: string;
}

export interface GalleryRecord {
  id: string;
  type: GalleryType;
  name: string;
  author: GalleryAuthor;
  license: string;
  tags: string[];
  featured: boolean;
  retired: boolean;
  version: number;
  sha256: string;
  category?: string;
  /** Features the look needs from the app (doodles, mesh, scheme-colors). */
  requires?: string[];
  /** The look's document as the index carries it, with `glyphs` resolved into `doodles`. */
  document?: Record<string, unknown>;
  files: string[];
}

interface IndexFile {
  schema: number;
  items: GalleryRecord[];
}

interface Cache {
  /** The index file's full address. */
  url: string;
  etag: string;
  at: number;
  index: IndexFile | null;
  /** How long this entry stays. A failure is kept briefly so a down host isn't hit on every tap. */
  ttl: number;
}

const OK_TTL = 15 * 60 * 1000;
const MISS_TTL = 30 * 1000;
/** The gallery's files: looks and skills in index.json, every newer kind in its own (D-239, D-241). */
type GalleryFile = "index.json" | "apps.json" | "bots.json" | "routines.json" | "plugins.json";

/** One entry per file. */
const caches = new Map<string, Cache>();

export function resetGalleryCache() {
  caches.clear();
}

/** `off` turns the gallery off. An empty env value is treated as unset and uses the default site. */
function galleryBase(env: Env): string | null {
  const url = env.GALLERY_URL.trim();
  if (!url || url === "off") return null;
  return url;
}

function originOf(url: string) {
  return new URL(url).origin;
}

function join(base: string, path: string) {
  if (path.includes("..") || path.startsWith("/"))
    throw new ApiError(400, "gallery_bad_path", "That gallery file isn't allowed.");
  return `${base.replace(/\/$/, "")}/${path}`;
}

async function readIndex(
  env: Env,
  fetchImpl: typeof fetch,
  file: GalleryFile = "index.json",
): Promise<IndexFile | null> {
  const base = galleryBase(env);
  if (!base) return null;
  const url = join(base, file);
  const now = Date.now();
  const cache = caches.get(file);
  const same = cache?.url === url ? cache : undefined;
  if (same && now - same.at < same.ttl) return same.index;
  const headers: Record<string, string> = {};
  if (same?.etag) headers["If-None-Match"] = same.etag;
  const miss = (etag: string, index: IndexFile | null = null) => {
    caches.set(file, { url, etag, at: now, index, ttl: index ? OK_TTL : MISS_TTL });
    return index;
  };
  let res: Response;
  try {
    res = await fetchImpl(url, { headers, signal: AbortSignal.timeout(10_000) });
  } catch {
    return miss(same?.etag ?? "");
  }
  if (res.status === 304 && same?.index) {
    caches.set(file, { ...same, at: now, ttl: OK_TTL });
    return same.index;
  }
  if (!res.ok) return miss("");
  let index: IndexFile;
  try {
    index = (await res.json()) as IndexFile;
  } catch {
    return miss("");
  }
  if (!Array.isArray(index?.items)) return miss("");
  caches.set(file, { url, etag: res.headers.get("etag") ?? "", at: now, index, ttl: OK_TTL });
  return index;
}

/** Looks and skills only: an index from a newer gallery may carry types this server doesn't know. */
const knownType = (i: GalleryRecord) =>
  (GALLERY_TYPES as readonly string[]).includes(String(i.type));

export async function galleryIndex(env: Env, fetchImpl: typeof fetch = fetch) {
  const url = galleryBase(env);
  if (!url) return { enabled: false as const, available: false, items: [] as GalleryRecord[] };
  const index = await readIndex(env, fetchImpl);
  return {
    enabled: true as const,
    available: index != null,
    items: (index?.items ?? []).filter(knownType),
  };
}

/** A gallery app as the catalog offers it, with its logo's address when it has one. */
export type GalleryCatalogApp = CatalogApp & { logoUrl?: string };

/**
 * The gallery's apps (D-239), checked again here so a broken or hostile entry never reaches the
 * catalog. Retired entries and ids a built-in app already uses are left out. Empty when the
 * gallery is off or can't be reached: built-in apps never depend on it.
 */
export async function galleryApps(
  env: Env,
  fetchImpl: typeof fetch = fetch,
): Promise<GalleryCatalogApp[]> {
  const base = galleryBase(env);
  if (!base) return [];
  const index = await readIndex(env, fetchImpl, "apps.json");
  if (!index) return [];
  const builtIn = new Set(APP_CATALOG.map((a) => a.id));
  const seen = new Set<string>();
  const out: GalleryCatalogApp[] = [];
  for (const item of index.items as unknown[]) {
    if (typeof item !== "object" || item === null) continue;
    const i = item as Omit<Partial<GalleryRecord>, "type"> & { type?: string };
    if (i.type !== GALLERY_APP_TYPE || i.retired === true) continue;
    if (typeof i.id !== "string" || !/^[a-z0-9][a-z0-9-]{0,62}$/.test(i.id)) continue;
    if (builtIn.has(i.id) || builtIn.has(i.id.replaceAll("-", "_")) || seen.has(i.id)) continue;
    const name = typeof i.name === "string" ? i.name.trim() : "";
    if (name.length < 1 || name.length > 60) continue;
    const app = catalogAppFromGallery(i.id, name, i.document);
    if (!app) continue;
    seen.add(i.id);
    const logo = `apps/${i.id}/logo.svg`;
    out.push({
      ...app,
      ...(Array.isArray(i.files) && i.files.includes(logo) ? { logoUrl: join(base, logo) } : {}),
    });
  }
  return out;
}

export async function galleryItem(
  env: Env,
  type: GalleryType,
  id: string,
  fetchImpl: typeof fetch = fetch,
): Promise<{
  item: GalleryRecord;
  document: Record<string, unknown> | null;
  skillMd: string | null;
}> {
  const listed = await galleryIndex(env, fetchImpl);
  if (!listed.enabled)
    throw new ApiError(404, "gallery_disabled", "The gallery is turned off on this server.");
  const item = listed.items.find((i) => i.type === type && i.id === id);
  if (!item) throw new ApiError(404, "gallery_not_found", "That gallery item isn't there.");
  const base = galleryBase(env);
  if (!base)
    throw new ApiError(404, "gallery_disabled", "The gallery is turned off on this server.");
  if (type === "skill") {
    const skillPath = item.files.find((f) => f.endsWith("/SKILL.md") || f === "SKILL.md");
    if (!skillPath)
      throw new ApiError(502, "gallery_unavailable", "This skill has no instructions.");
    const res = await fetchImpl(join(base, skillPath), { signal: AbortSignal.timeout(10_000) });
    if (!res.ok)
      throw new ApiError(502, "gallery_unavailable", "The gallery didn't return this skill.");
    return { item, document: null, skillMd: await res.text() };
  }
  // The index's copy has `glyphs` already turned into doodles; the file on disk doesn't.
  if (item.document) return { item, document: item.document, skillMd: null };
  const docName =
    type === "theme" ? "theme.json" : type === "scheme" ? "scheme.json" : "wallpaper.json";
  const docPath = item.files.find((f) => f.endsWith(`/${docName}`));
  if (!docPath) throw new ApiError(502, "gallery_unavailable", "This item has no document.");
  const res = await fetchImpl(join(base, docPath), { signal: AbortSignal.timeout(10_000) });
  if (!res.ok)
    throw new ApiError(502, "gallery_unavailable", "The gallery didn't return this item.");
  return { item, document: (await res.json()) as Record<string, unknown>, skillMd: null };
}

/** Downloads a gallery skill and refuses it when the bytes don't match the index. */
export async function fetchGallerySkill(
  env: Env,
  id: string,
  fetchImpl: typeof fetch = fetch,
): Promise<{ bundle: SkillBundle; sha256: string; category: string | null }> {
  const listed = await galleryIndex(env, fetchImpl);
  if (!listed.enabled)
    throw new ApiError(404, "gallery_disabled", "The gallery is turned off on this server.");
  if (!listed.available)
    throw new ApiError(502, "gallery_unavailable", "The gallery can't be reached right now.");
  const item = listed.items.find((i) => i.type === "skill" && i.id === id && !i.retired);
  if (!item) throw new ApiError(404, "gallery_not_found", "That skill isn't in the gallery.");
  const base = galleryBase(env);
  if (!base)
    throw new ApiError(404, "gallery_disabled", "The gallery is turned off on this server.");
  const host = originOf(base);
  const files: { path: string; bytes: Uint8Array; relative: string }[] = [];
  for (const file of item.files) {
    const url = join(base, file);
    if (new URL(url).origin !== host)
      throw new ApiError(400, "gallery_bad_path", "That gallery file isn't allowed.");
    const res = await fetchImpl(url, { signal: AbortSignal.timeout(10_000) });
    if (!res.ok)
      throw new ApiError(502, "gallery_unavailable", `The gallery didn't return ${file}.`);
    const bytes = new Uint8Array(await res.arrayBuffer());
    const relative = file.split("/").slice(2).join("/");
    files.push({ path: file, bytes, relative });
  }
  const sha256 = galleryHash(files.map((f) => ({ path: f.relative, bytes: f.bytes })));
  if (sha256 !== item.sha256)
    throw new ApiError(400, "gallery_hash_mismatch", "This skill doesn't match the gallery index.");
  const skill = files.find((f) => f.relative === "SKILL.md");
  if (!skill) throw new ApiError(502, "gallery_unavailable", "This skill has no instructions.");
  const extra = files
    .filter((f) => f.relative !== "SKILL.md" && f.relative !== "item.json")
    .map((f) => ({
      path: f.relative,
      content: Buffer.from(f.bytes),
      executable: f.bytes[0] === 0x23 && f.bytes[1] === 0x21,
    }));
  return {
    bundle: bundleFrom(Buffer.from(skill.bytes).toString("utf8"), extra),
    sha256,
    category: item.category ?? null,
  };
}

// ---------------------------------------------------------------- bots, routines, plugins (D-241)

const ITEM_ID = /^[a-z0-9][a-z0-9-]{0,62}$/;

type RawItem = Omit<Partial<GalleryRecord>, "type"> & { type?: string };

/** The live, well-formed items of one type in one of the newer files. */
async function liveItems(
  env: Env,
  fetchImpl: typeof fetch,
  file: GalleryFile,
  type: string,
): Promise<(RawItem & { id: string; name: string })[]> {
  if (!galleryBase(env)) return [];
  const index = await readIndex(env, fetchImpl, file);
  if (!index) return [];
  const seen = new Set<string>();
  const out: (RawItem & { id: string; name: string })[] = [];
  for (const raw of index.items as unknown[]) {
    if (typeof raw !== "object" || raw === null) continue;
    const i = raw as RawItem;
    if (i.type !== type || i.retired === true) continue;
    if (typeof i.id !== "string" || !ITEM_ID.test(i.id) || seen.has(i.id)) continue;
    const name = typeof i.name === "string" ? i.name.trim() : "";
    if (name.length < 1 || name.length > 60) continue;
    seen.add(i.id);
    out.push({ ...i, id: i.id, name });
  }
  return out;
}

/** Who made a gallery item, for the app to credit. */
function authorOf(i: RawItem): GalleryAuthor {
  const a = i.author;
  const name = a && typeof a.name === "string" ? a.name.trim().slice(0, 80) : "";
  const url = a && typeof a.url === "string" && a.url.startsWith("https://") ? a.url : undefined;
  return { name: name || "Unknown", ...(url ? { url } : {}) };
}

/** A gallery starter bot, credited to its author. */
export type GalleryBot = BotTemplate & { author: GalleryAuthor };

/**
 * The gallery's starter bots, checked again here; ids a built-in bot uses are left out. Empty when
 * the gallery is off or can't be reached.
 */
export async function galleryBots(
  env: Env,
  fetchImpl: typeof fetch = fetch,
): Promise<GalleryBot[]> {
  const builtIn = new Set(BOT_TEMPLATES.map((t) => t.id));
  const out: GalleryBot[] = [];
  for (const i of await liveItems(env, fetchImpl, "bots.json", GALLERY_BOT_TYPE)) {
    if (builtIn.has(i.id)) continue;
    const t = botTemplateFromGallery(i.id, i.name, i.document);
    if (t) out.push({ ...t, author: authorOf(i) });
  }
  return out;
}

/** A built-in starter bot, or one from the gallery. */
export async function findTemplate(
  env: Env,
  id: string,
  fetchImpl: typeof fetch = fetch,
): Promise<BotTemplate | undefined> {
  return (
    BOT_TEMPLATES.find((t) => t.id === id) ??
    (await galleryBots(env, fetchImpl)).find((t) => t.id === id)
  );
}

export type GalleryRoutine = GalleryRoutineDocument & {
  id: string;
  name: string;
  author: GalleryAuthor;
  featured: boolean;
};

/** Routine ideas from the gallery, checked again here. */
export async function galleryRoutines(
  env: Env,
  fetchImpl: typeof fetch = fetch,
): Promise<GalleryRoutine[]> {
  const out: GalleryRoutine[] = [];
  for (const i of await liveItems(env, fetchImpl, "routines.json", GALLERY_ROUTINE_TYPE)) {
    const { doc } = checkRoutineDocument(i.document);
    if (doc)
      out.push({
        id: i.id,
        name: i.name,
        author: authorOf(i),
        featured: i.featured === true,
        ...doc,
      });
  }
  return out;
}

export type GalleryPlugin = GalleryPluginDocument & {
  id: string;
  name: string;
  author: GalleryAuthor;
};

/** Plugins someone reviewed, each pinned to the reviewed commit. */
export async function galleryPlugins(
  env: Env,
  fetchImpl: typeof fetch = fetch,
): Promise<GalleryPlugin[]> {
  const out: GalleryPlugin[] = [];
  for (const i of await liveItems(env, fetchImpl, "plugins.json", GALLERY_PLUGIN_TYPE)) {
    const { doc } = checkPluginDocument(i.document);
    if (doc) out.push({ id: i.id, name: i.name, author: authorOf(i), ...doc });
  }
  return out;
}

// ---------------------------------------------------------------- the skill catalog (D-241)

/** SKILL.md text by the skill's hash: a changed skill gets a new hash, so entries never go stale. */
const skillMdCache = new Map<string, string>();

async function skillMdOf(env: Env, item: GalleryRecord, fetchImpl: typeof fetch) {
  const hit = skillMdCache.get(item.sha256);
  if (hit !== undefined) return hit;
  const base = galleryBase(env);
  const path = item.files.find((f) => f.endsWith("/SKILL.md"));
  if (!base || !path) return null;
  try {
    const res = await fetchImpl(join(base, path), { signal: AbortSignal.timeout(10_000) });
    if (!res.ok) return null;
    const text = await res.text();
    if (skillMdCache.size > 500) skillMdCache.clear();
    skillMdCache.set(item.sha256, text);
    return text;
  } catch {
    return null;
  }
}

/** A catalog entry and where an install takes it from. */
export type CatalogEntry = CatalogSkill & { from: "gallery" | "bundled" };

/**
 * The skill catalog: the gallery's skills when it can be read, so a merged change reaches every
 * server without a release, and the bundled `skills/` for anything the gallery doesn't have (or
 * all of it when the gallery is off or down). Gallery skills outside the catalog's categories
 * are left out, since the app groups by them.
 */
export async function skillCatalog(
  env: Env,
  fetchImpl: typeof fetch = fetch,
): Promise<{ categories: string[]; skills: CatalogEntry[] }> {
  const bundled = loadCatalog();
  const categories = bundled.categories;
  const listed = await galleryIndex(env, fetchImpl);
  const fromGallery = new Map<string, CatalogEntry>();
  const live = listed.items.filter(
    (i) => i.type === "skill" && !i.retired && i.category && categories.includes(i.category),
  );
  await Promise.all(
    live.map(async (i) => {
      const md = await skillMdOf(env, i, fetchImpl);
      if (md === null) return;
      try {
        const bundle = bundleFrom(
          md,
          i.files
            .filter((f) => !f.endsWith("/SKILL.md") && !f.endsWith("/item.json"))
            .map((f) => ({
              path: f.split("/").slice(2).join("/"),
              content: Buffer.alloc(0),
              executable: false,
            })),
        );
        if (bundle.name !== i.id) return;
        const icon = (i as { icon?: unknown }).icon;
        fromGallery.set(i.id, {
          ...bundle,
          id: i.id,
          category: i.category as string,
          icon: typeof icon === "string" ? icon : null,
          from: "gallery",
        });
      } catch {
        // A skill this server can't read stays out; its bundled copy (if any) stands in.
      }
    }),
  );
  const skills: CatalogEntry[] = bundled.skills.map(
    (s) => fromGallery.get(s.id) ?? { ...s, from: "bundled" as const },
  );
  for (const [id, entry] of fromGallery) if (!skills.some((s) => s.id === id)) skills.push(entry);
  return { categories, skills };
}
