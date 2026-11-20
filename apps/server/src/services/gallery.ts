/**
 * The open gallery (D-184). The API caches index.json and checks a skill's files against the
 * index hash before installing them. Apps (D-239) come from apps.json, cached the same way, and
 * join the built-in catalog. An empty GALLERY_URL turns the gallery off.
 *
 * Gallery v2 (D-315): every derived file is checked against a signed manifest (manifest.json and
 * manifest.sig) when the catalog is signed; extra catalogs (GALLERY_SOURCES) join with namespaced
 * ids (`source:id`); items newer than this server (`min_server`) are left out everywhere.
 */
import {
  APP_CATALOG,
  BOT_TEMPLATES,
  type BotTemplate,
  botTemplateFromGallery,
  builtInCodingAgents,
  type CatalogApp,
  type CodingAgentSpec,
  catalogAppFromGallery,
  checkPluginDocument,
  checkRoutineDocument,
  compareGalleryVersions,
  fillGalleryDocument,
  GALLERY_APP_TYPE,
  GALLERY_BOT_TYPE,
  GALLERY_PLUGIN_TYPE,
  GALLERY_ROUTINE_TYPE,
  GALLERY_TYPES,
  type GalleryInput,
  type GalleryLists,
  type GalleryManifest,
  type GalleryPluginDocument,
  type GalleryRoutineDocument,
  type GalleryType,
  galleryHash,
  galleryInputDefaults,
  galleryManifestCovers,
  mergeCodingAgents,
  parseGalleryLists,
  parseGalleryManifest,
  verifyGalleryManifest,
} from "@casama/domain";
import { ApiError } from "../api/errors.ts";
import type { Env } from "../env.ts";
import { CASAMA_VERSION } from "../version.ts";
import { bundleFrom, type CatalogSkill, loadCatalog, type SkillBundle } from "./skills.ts";

export interface GalleryAuthor {
  name: string;
  url?: string;
  handle?: string;
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
  /** The extra catalog it came from (D-315); its id is then `source:id`. */
  source?: string;
  /** Absolute URL of its painted cover picture (cover.webp), when it has one. */
  cover?: string;
  min_server?: string;
  [extra: string]: unknown;
}

interface IndexFile {
  schema: number;
  items: GalleryRecord[];
}

interface Cache {
  /** The index file's full address. */
  url: string;
  etag: string;
  /** sha256 of the cached bytes, to notice a manifest that moved on while the file answered 304. */
  sha: string;
  at: number;
  index: IndexFile | null;
  /** How long this entry stays. A failure is kept briefly so a down host isn't hit on every tap. */
  ttl: number;
}

const OK_TTL = 15 * 60 * 1000;
const MISS_TTL = 30 * 1000;
/** The gallery's files: looks and skills in index.json, every newer kind in its own (D-239, D-241, D-315). */
export type GalleryFile =
  | "index.json"
  | "apps.json"
  | "bots.json"
  | "routines.json"
  | "plugins.json"
  | "sets.json"
  | "authors.json"
  | "coding-agents.json"
  | "lists.json"
  | "prompts.json";
const CODING_AGENTS_FILE = "coding-agents.json" satisfies GalleryFile;

/** One entry per source and file. */
const caches = new Map<string, Cache>();
/** One signed manifest per source. */
const manifests = new Map<
  string,
  { at: number; ttl: number; ok: boolean; manifest: GalleryManifest | null }
>();

export function resetGalleryCache() {
  caches.clear();
  manifests.clear();
  skillMdCache.clear();
}

/** Problems worth an operator's attention (a bad signature). Tests and the API may replace it. */
let warn: (msg: string, extra?: Record<string, unknown>) => void = (msg, extra) =>
  console.warn(JSON.stringify({ level: "warn", msg, ...extra }));
export function setGalleryWarn(fn: typeof warn) {
  warn = fn;
}

// ---------------------------------------------------------------- sources (D-315)

/** The Casama gallery's signing key (Ed25519, base64 raw); GALLERY_PUBLIC_KEY overrides it. */
export const CASAMA_GALLERY_PUBLIC_KEY = "9cpyf5B04R5VEPqkryFMIe2qdSsg7vhgZRJMNOgc9cQ=";
export const CASAMA_GALLERY_URL = "https://gallery.casama.ai";

export interface GallerySource {
  /** null for the main catalog (GALLERY_URL); its items carry no `source`. */
  name: string | null;
  base: string;
  key: string;
  signature: "required" | "optional" | "off";
}

const SOURCE_NAME = /^[a-z0-9][a-z0-9-]{0,39}$/;

/** `off` turns the gallery off. An empty env value is treated as unset and uses the default site. */
function galleryBase(env: Env): string | null {
  const url = env.GALLERY_URL.trim();
  if (!url || url === "off") return null;
  return url;
}

/** Every catalog this server reads: the main one first, then GALLERY_SOURCES. */
export function gallerySources(env: Pick<Env, "GALLERY_URL"> & Partial<Env>): GallerySource[] {
  const out: GallerySource[] = [];
  const mode = env.GALLERY_SIGNATURE ?? "optional";
  const main = galleryBase(env as Env);
  if (main) {
    const own = main.replace(/\/$/, "") === CASAMA_GALLERY_URL;
    const key = env.GALLERY_PUBLIC_KEY?.trim() || (own ? CASAMA_GALLERY_PUBLIC_KEY : "");
    out.push({ name: null, base: main, key, signature: key ? mode : "off" });
  }
  for (const raw of (env.GALLERY_SOURCES ?? "").split(",")) {
    const entry = raw.trim();
    if (!entry) continue;
    const [left, key = ""] = entry.split("#") as [string, string?];
    const eq = left.indexOf("=");
    let name = eq > 0 ? left.slice(0, eq).trim().toLowerCase() : "";
    const url = (eq > 0 ? left.slice(eq + 1) : left).trim();
    let parsed: URL;
    try {
      parsed = new URL(url);
    } catch {
      warn("gallery source skipped: not a URL", { source: entry.slice(0, 80) });
      continue;
    }
    if (!name)
      name = (parsed.hostname.split(".")[0] ?? "").toLowerCase().replace(/[^a-z0-9-]/g, "");
    if (!SOURCE_NAME.test(name) || out.some((s) => s.name === name)) {
      warn("gallery source skipped: bad or repeated name", { name });
      continue;
    }
    out.push({ name, base: url, key: key.trim(), signature: key.trim() ? mode : "off" });
  }
  return out;
}

function sourceOf(env: Env, name: string | undefined | null): GallerySource | undefined {
  return gallerySources(env).find((s) => s.name === (name ?? null));
}

/** Splits `source:id` into its catalog and the catalog's own id. */
export function splitGalleryId(id: string): { source: string | null; id: string } {
  const i = id.indexOf(":");
  return i < 0 ? { source: null, id } : { source: id.slice(0, i), id: id.slice(i + 1) };
}

const nsId = (src: GallerySource, id: string) => (src.name ? `${src.name}:${id}` : id);

function originOf(url: string) {
  return new URL(url).origin;
}

function join(base: string, path: string) {
  if (path.includes("..") || path.startsWith("/"))
    throw new ApiError(400, "gallery_bad_path", "That gallery file isn't allowed.");
  return `${base.replace(/\/$/, "")}/${path}`;
}

/** Whether an item asks for a newer server than this one. */
export function tooNewForServer(item: object): boolean {
  const v = (item as { min_server?: unknown }).min_server;
  return (
    typeof v === "string" &&
    /^\d+\.\d+\.\d+$/.test(v) &&
    compareGalleryVersions(v, CASAMA_VERSION) > 0
  );
}

// ---------------------------------------------------------------- the signed manifest (D-315)

async function sourceManifest(
  src: GallerySource,
  fetchImpl: typeof fetch,
): Promise<{ ok: boolean; manifest: GalleryManifest | null }> {
  if (src.signature === "off" || !src.key) return { ok: true, manifest: null };
  const cacheKey = `${src.name ?? ""}|${src.base}|${src.key}|${src.signature}`;
  const now = Date.now();
  const hit = manifests.get(cacheKey);
  if (hit && now - hit.at < hit.ttl) return hit;
  const keep = (ok: boolean, manifest: GalleryManifest | null) => {
    const v = { at: now, ttl: ok ? OK_TTL : MISS_TTL, ok, manifest };
    manifests.set(cacheKey, v);
    return v;
  };
  const required = src.signature === "required";
  let sig: string | null = null;
  try {
    const res = await fetchImpl(join(src.base, "manifest.sig"), {
      signal: AbortSignal.timeout(10_000),
    });
    if (res.ok) sig = (await res.text()).trim();
  } catch {
    // Unreachable: the index fetch below fails the same way, or it's a required signature.
  }
  if (!sig) {
    if (required) warn("gallery signature missing", { source: src.name ?? "main" });
    return keep(!required, null);
  }
  let bytes: Uint8Array;
  try {
    const res = await fetchImpl(join(src.base, "manifest.json"), {
      signal: AbortSignal.timeout(10_000),
    });
    if (!res.ok) throw new Error(`manifest.json ${res.status}`);
    bytes = new Uint8Array(await res.arrayBuffer());
  } catch (err) {
    warn("gallery manifest unreadable", { source: src.name ?? "main", error: String(err) });
    return keep(false, null);
  }
  // A signature that is there but doesn't verify is never trusted, in either mode.
  if (!verifyGalleryManifest(bytes, sig, src.key)) {
    warn("gallery signature doesn't verify; the gallery is unavailable", {
      source: src.name ?? "main",
    });
    return keep(false, null);
  }
  let manifest: GalleryManifest | undefined;
  try {
    manifest = parseGalleryManifest(JSON.parse(Buffer.from(bytes).toString("utf8")));
  } catch {
    manifest = undefined;
  }
  if (!manifest) {
    warn("gallery manifest isn't valid", { source: src.name ?? "main" });
    return keep(false, null);
  }
  return keep(true, manifest);
}

async function readIndex(
  src: GallerySource,
  fetchImpl: typeof fetch,
  file: GalleryFile = "index.json",
): Promise<IndexFile | null> {
  const url = join(src.base, file);
  const signed = await sourceManifest(src, fetchImpl);
  if (!signed.ok) return null;
  const manifest = signed.manifest;
  const key = `${src.name ?? ""}|${file}`;
  const now = Date.now();
  const cache = caches.get(key);
  let same = cache?.url === url ? cache : undefined;
  // The manifest moved on: what's cached is no longer what it vouches for.
  if (same && manifest && manifest.files[file] !== same.sha) same = undefined;
  if (same && now - same.at < same.ttl) return same.index;
  const headers: Record<string, string> = {};
  if (same?.etag) headers["If-None-Match"] = same.etag;
  const miss = (etag: string, index: IndexFile | null = null) => {
    caches.set(key, { url, etag, sha: "", at: now, index, ttl: index ? OK_TTL : MISS_TTL });
    return index;
  };
  let res: Response;
  try {
    res = await fetchImpl(url, { headers, signal: AbortSignal.timeout(10_000) });
  } catch {
    return miss(same?.etag ?? "");
  }
  if (res.status === 304 && same?.index) {
    caches.set(key, { ...same, at: now, ttl: OK_TTL });
    return same.index;
  }
  if (!res.ok) return miss("");
  let bytes: Uint8Array;
  try {
    bytes = new Uint8Array(await res.arrayBuffer());
  } catch {
    return miss("");
  }
  if (manifest && !galleryManifestCovers(manifest, file, bytes)) {
    warn("gallery file doesn't match its signed manifest", { source: src.name ?? "main", file });
    return miss("");
  }
  let index: IndexFile;
  try {
    index = JSON.parse(Buffer.from(bytes).toString("utf8")) as IndexFile;
  } catch {
    return miss("");
  }
  // authors.json lists `authors`; every other file `items`.
  if (!Array.isArray(index?.items) && !Array.isArray((index as { authors?: unknown })?.authors))
    return miss("");
  if (!Array.isArray(index.items)) index.items = [];
  const sha = manifest?.files[file] ?? "";
  caches.set(key, { url, etag: res.headers.get("etag") ?? "", sha, at: now, index, ttl: OK_TTL });
  return index;
}

const COVER_PATH = /^(sets|bots|routines|skills|plugins)\/[a-z0-9][a-z0-9-]{0,62}\/cover\.webp$/;

/**
 * A record with its painted cover (cover.webp) as an absolute URL on its own catalog's address,
 * the way an app's logo becomes `logoUrl`. Anything but a plain cover path is dropped, so a
 * catalog can never hand the app an arbitrary URL.
 */
function withCover(src: GallerySource, i: RawItem): RawItem {
  if (!("cover" in i)) return i;
  const { cover, ...rest } = i;
  return typeof cover === "string" && COVER_PATH.test(cover)
    ? { ...rest, cover: join(src.base, cover) }
    : rest;
}

/** The raw records of one file from every source, namespaced, without items too new for this server. */
async function recordsOf(
  env: Env,
  fetchImpl: typeof fetch,
  file: GalleryFile,
): Promise<{ available: boolean; any: boolean; items: { src: GallerySource; raw: RawItem }[] }> {
  const sources = gallerySources(env);
  if (!sources.length) return { available: false, any: false, items: [] };
  const lists = await Promise.all(sources.map((src) => readIndex(src, fetchImpl, file)));
  const items: { src: GallerySource; raw: RawItem }[] = [];
  lists.forEach((index, n) => {
    const src = sources[n] as GallerySource;
    for (const raw of (index?.items ?? []) as unknown[]) {
      if (typeof raw !== "object" || raw === null) continue;
      const i = withCover(src, raw as RawItem);
      if (tooNewForServer(i)) continue;
      if (src.name) {
        if (typeof i.id !== "string" || !ITEM_ID.test(i.id)) continue;
        items.push({ src, raw: { ...i, id: nsId(src, i.id), source: src.name } });
      } else items.push({ src, raw: i });
    }
  });
  // The main catalog decides availability; an extra one being down only hides its own items.
  return { available: lists[0] != null, any: true, items };
}

/** Looks and skills only: an index from a newer gallery may carry types this server doesn't know. */
const knownType = (i: { type?: unknown }) =>
  (GALLERY_TYPES as readonly string[]).includes(String(i.type));

export async function galleryIndex(env: Env, fetchImpl: typeof fetch = fetch) {
  const got = await recordsOf(env, fetchImpl, "index.json");
  if (!got.any) return { enabled: false as const, available: false, items: [] as GalleryRecord[] };
  return {
    enabled: true as const,
    available: got.available,
    items: got.items.map((x) => x.raw as GalleryRecord).filter(knownType),
  };
}

/** A gallery app as the catalog offers it, with its logo's address when it has one. */
export type GalleryCatalogApp = CatalogApp & { logoUrl?: string } & GalleryExtras;

/**
 * The gallery's apps (D-239), checked again here so a broken or hostile entry never reaches the
 * catalog. Retired entries and ids a built-in app already uses are left out. Empty when the
 * gallery is off or can't be reached: built-in apps never depend on it.
 */
export async function galleryApps(
  env: Env,
  fetchImpl: typeof fetch = fetch,
): Promise<GalleryCatalogApp[]> {
  const got = await recordsOf(env, fetchImpl, "apps.json");
  const builtIn = new Set(APP_CATALOG.map((a) => a.id));
  const seen = new Set<string>();
  const out: GalleryCatalogApp[] = [];
  for (const { src, raw: i } of got.items) {
    if (i.type !== GALLERY_APP_TYPE || i.retired === true) continue;
    if (typeof i.id !== "string") continue;
    const own = splitGalleryId(i.id).id;
    if (!/^[a-z0-9][a-z0-9-]{0,62}$/.test(own)) continue;
    if (!src.name && (builtIn.has(i.id) || builtIn.has(i.id.replaceAll("-", "_")))) continue;
    if (seen.has(i.id)) continue;
    const name = typeof i.name === "string" ? i.name.trim() : "";
    if (name.length < 1 || name.length > 60) continue;
    const app = catalogAppFromGallery(i.id, name, i.document);
    if (!app) continue;
    seen.add(i.id);
    const logo = `apps/${own}/logo.svg`;
    out.push({
      ...app,
      ...extrasOf(i),
      ...(Array.isArray(i.files) && i.files.includes(logo)
        ? { logoUrl: join(src.base, logo) }
        : {}),
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
  const base = sourceOf(env, item.source)?.base;
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
): Promise<{
  bundle: SkillBundle;
  sha256: string;
  category: string | null;
  version: number;
  access?: Record<string, unknown>;
}> {
  const listed = await galleryIndex(env, fetchImpl);
  if (!listed.enabled)
    throw new ApiError(404, "gallery_disabled", "The gallery is turned off on this server.");
  if (!listed.available && !splitGalleryId(id).source)
    throw new ApiError(502, "gallery_unavailable", "The gallery can't be reached right now.");
  const item = listed.items.find((i) => i.type === "skill" && i.id === id && !i.retired);
  if (!item) throw new ApiError(404, "gallery_not_found", "That skill isn't in the gallery.");
  const base = sourceOf(env, item.source)?.base;
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
    .filter(
      (f) => f.relative !== "SKILL.md" && f.relative !== "item.json" && f.relative !== "tests.json",
    )
    .map((f) => ({
      path: f.relative,
      content: Buffer.from(f.bytes),
      executable: f.bytes[0] === 0x23 && f.bytes[1] === 0x21,
    }));
  return {
    bundle: bundleFrom(Buffer.from(skill.bytes).toString("utf8"), extra),
    sha256,
    category: item.category ?? null,
    version: typeof item.version === "number" ? item.version : 1,
    ...(isRecord(item.access) ? { access: item.access } : {}),
  };
}

// ---------------------------------------------------------------- bots, routines, plugins (D-241)

const ITEM_ID = /^[a-z0-9][a-z0-9-]{0,62}$/;

type RawItem = Omit<Partial<GalleryRecord>, "type"> & { type?: string; [k: string]: unknown };

function isRecord(v: unknown): v is Record<string, unknown> {
  return typeof v === "object" && v !== null && !Array.isArray(v);
}

/** The gallery v2 fields an index record carries (D-315), passed through as they are. */
export interface GalleryExtras {
  added?: string;
  updated?: string;
  changelog?: { version: number; date: string; note: string; breaking?: boolean }[];
  pick?: string;
  examples?: string[];
  access?: Record<string, unknown>;
  needs?: { apps?: string[]; skills?: string[] };
  inputs?: GalleryInput[];
  remix_of?: { type: string; id: string };
  replaced_by?: { type: string; id: string };
  min_app?: string;
  min_server?: string;
  season?: { from: string; to: string };
  tested?: { version: number; date: string };
  source?: string;
  version?: number;
  tags?: string[];
  /** Absolute URL of the item's painted cover picture (cover.webp), when it has one. */
  cover?: string;
  /** Raw placeholder fields of a routine or bot with install questions (D-315). */
  template?: Record<string, unknown>;
}

const EXTRA_KEYS = [
  "added",
  "updated",
  "changelog",
  "pick",
  "examples",
  "access",
  "needs",
  "inputs",
  "remix_of",
  "replaced_by",
  "min_app",
  "min_server",
  "season",
  "tested",
  "source",
  "version",
  "tags",
  "template",
  "cover",
] as const;

export function extrasOf(i: Record<string, unknown>): GalleryExtras {
  const out: Record<string, unknown> = {};
  for (const k of EXTRA_KEYS) if (i[k] !== undefined && i[k] !== null) out[k] = i[k];
  return out as GalleryExtras;
}

/** The live, well-formed items of one type in one of the newer files, from every source. */
async function liveItems(
  env: Env,
  fetchImpl: typeof fetch,
  file: GalleryFile,
  type: string,
  opts: { retired?: boolean } = {},
): Promise<(RawItem & { id: string; name: string })[]> {
  const got = await recordsOf(env, fetchImpl, file);
  const seen = new Set<string>();
  const out: (RawItem & { id: string; name: string })[] = [];
  for (const { raw: i } of got.items) {
    if (i.type !== type || (i.retired === true && !opts.retired)) continue;
    if (typeof i.id !== "string" || seen.has(i.id)) continue;
    if (!ITEM_ID.test(splitGalleryId(i.id).id)) continue;
    const name = typeof i.name === "string" ? i.name.trim() : "";
    if (name.length < 1 || name.length > 60) continue;
    seen.add(i.id);
    out.push({ ...i, id: i.id, name });
  }
  return out;
}

/** Who made a gallery item, for the app to credit. */
function authorOf(i: RawItem): GalleryAuthor {
  const a = i.author as { name?: unknown; url?: unknown; handle?: unknown } | undefined;
  const name = a && typeof a.name === "string" ? a.name.trim().slice(0, 80) : "";
  const url = a && typeof a.url === "string" && a.url.startsWith("https://") ? a.url : undefined;
  const handle =
    a && typeof a.handle === "string" && /^[a-z0-9][a-z0-9-]{0,38}$/.test(a.handle)
      ? a.handle
      : undefined;
  return { name: name || "Unknown", ...(url ? { url } : {}), ...(handle ? { handle } : {}) };
}

const inputsOf = (i: RawItem) => (Array.isArray(i.inputs) ? (i.inputs as GalleryInput[]) : []);

/**
 * A routine or bot document with install answers filled in (D-315). The record's `document` has
 * the defaults filled already (older servers read it as is); `template` holds the raw placeholder
 * fields, which take the answers and replace the same fields of the document.
 */
function filledDocument(
  kind: "routine" | "bot",
  i: RawItem,
  values?: Record<string, string>,
): unknown {
  const answers = { ...galleryInputDefaults(inputsOf(i)), ...values };
  if (!isRecord(i.document)) return i.document;
  if (isRecord(i.template))
    return { ...i.document, ...(fillGalleryDocument(kind, i.template, answers) as object) };
  return fillGalleryDocument(kind, i.document, answers);
}

/** A gallery starter bot, credited to its author. */
export type GalleryBot = BotTemplate & { author: GalleryAuthor } & GalleryExtras;

/** A bot entry as a template, its `{{key}}` placeholders filled from answers (defaults otherwise). */
export function botFromRecord(
  i: RawItem & { id: string; name: string },
  values?: Record<string, string>,
): GalleryBot | undefined {
  const filled = filledDocument("bot", i, values);
  const t = botTemplateFromGallery(i.id, i.name, filled);
  return t ? { ...t, author: authorOf(i), ...extrasOf(i) } : undefined;
}

/**
 * The gallery's starter bots, checked again here, including its copies of the built-in ones
 * (D-372). Empty when the gallery is off or can't be reached.
 */
export async function galleryBots(
  env: Env,
  fetchImpl: typeof fetch = fetch,
): Promise<GalleryBot[]> {
  const out: GalleryBot[] = [];
  for (const i of await liveItems(env, fetchImpl, "bots.json", GALLERY_BOT_TYPE)) {
    const t = botFromRecord(i);
    if (t) out.push(t);
  }
  return out;
}

/**
 * Every starter bot, in the order the app lists them (D-372): the built-in ones first, each
 * replaced by the main gallery's copy when it has a good one (an edit there now reaches every
 * server), then the gallery's own. The built-in copy stays the fallback offline or when the
 * gallery's copy fails its check. Built-in ids stay built-in for the workspace's gallery rules.
 */
export async function starterBots(
  env: Env,
  fetchImpl: typeof fetch = fetch,
): Promise<(BotTemplate | GalleryBot)[]> {
  const fromGallery = await galleryBots(env, fetchImpl).catch(() => [] as GalleryBot[]);
  const byId = new Map(fromGallery.map((t) => [t.id, t]));
  const builtIn = new Set(BOT_TEMPLATES.map((t) => t.id));
  return [
    ...BOT_TEMPLATES.map((t) => byId.get(t.id) ?? t),
    ...fromGallery.filter((t) => !builtIn.has(t.id)),
  ];
}

/** A starter bot by id: the gallery's copy first, the built-in one when the gallery has none. */
export async function findTemplate(
  env: Env,
  id: string,
  fetchImpl: typeof fetch = fetch,
): Promise<BotTemplate | undefined> {
  return (await starterBots(env, fetchImpl)).find((t) => t.id === id);
}

// ---------------------------------------------------------------- content lists (D-372)

/**
 * The main catalog's content lists (lists.json): search words, welcome chat words, empty-state
 * starters and app catalog curation. Extra catalogs never supply them. Every list is optional:
 * empty when the gallery is off, down or doesn't have it, and each reader keeps its own copy.
 */
export async function galleryLists(
  env: Env,
  fetchImpl: typeof fetch = fetch,
): Promise<GalleryLists> {
  const got = await recordsOf(env, fetchImpl, "lists.json").catch(() => null);
  if (!got) return {};
  return parseGalleryLists(got.items.filter((x) => x.src.name === null).map((x) => x.raw));
}

export type GalleryRoutine = GalleryRoutineDocument & {
  id: string;
  name: string;
  author: GalleryAuthor;
  featured: boolean;
} & GalleryExtras;

/** A routine entry as an idea, its placeholders filled from answers (defaults otherwise). */
export function routineFromRecord(
  i: RawItem & { id: string; name: string },
  values?: Record<string, string>,
): GalleryRoutine | undefined {
  const filled = filledDocument("routine", i, values);
  const { doc } = checkRoutineDocument(filled);
  if (!doc) return undefined;
  return {
    id: i.id,
    name: i.name,
    author: authorOf(i),
    featured: i.featured === true,
    ...extrasOf(i),
    ...doc,
  };
}

/** Routine ideas from the gallery, checked again here. */
export async function galleryRoutines(
  env: Env,
  fetchImpl: typeof fetch = fetch,
): Promise<GalleryRoutine[]> {
  const out: GalleryRoutine[] = [];
  for (const i of await liveItems(env, fetchImpl, "routines.json", GALLERY_ROUTINE_TYPE)) {
    const r = routineFromRecord(i);
    if (r) out.push(r);
  }
  return out;
}

export type GalleryPlugin = GalleryPluginDocument & {
  id: string;
  name: string;
  author: GalleryAuthor;
  featured: boolean;
} & GalleryExtras;

/** Plugins someone reviewed, each pinned to the reviewed commit. */
export async function galleryPlugins(
  env: Env,
  fetchImpl: typeof fetch = fetch,
): Promise<GalleryPlugin[]> {
  const out: GalleryPlugin[] = [];
  for (const i of await liveItems(env, fetchImpl, "plugins.json", GALLERY_PLUGIN_TYPE)) {
    const { doc } = checkPluginDocument(i.document);
    if (doc)
      out.push({
        id: i.id,
        name: i.name,
        author: authorOf(i),
        featured: i.featured === true,
        ...extrasOf(i),
        ...doc,
      });
  }
  return out;
}

// ---------------------------------------------------------------- every kind, raw (D-315)

/** The file each kind lives in. */
export const GALLERY_FILE_OF: Record<string, GalleryFile> = {
  theme: "index.json",
  scheme: "index.json",
  wallpaper: "index.json",
  skill: "index.json",
  app: "apps.json",
  bot: "bots.json",
  routine: "routines.json",
  plugin: "plugins.json",
  set: "sets.json",
};

/** One raw item of any kind, retired ones included (installed copies still need them). */
export async function galleryRecord(
  env: Env,
  type: string,
  id: string,
  fetchImpl: typeof fetch = fetch,
): Promise<(RawItem & { id: string; name: string }) | undefined> {
  const file = GALLERY_FILE_OF[type];
  if (!file) return undefined;
  const items = await liveItems(env, fetchImpl, file, type, { retired: true });
  return items.find((i) => i.id === id);
}

/** Every raw item of the given kinds, retired included. */
export async function galleryRecords(
  env: Env,
  types: string[],
  fetchImpl: typeof fetch = fetch,
): Promise<(RawItem & { id: string; name: string; type: string })[]> {
  const files = [...new Set(types.map((t) => GALLERY_FILE_OF[t]).filter(Boolean))] as GalleryFile[];
  const out: (RawItem & { id: string; name: string; type: string })[] = [];
  for (const file of files)
    for (const type of types.filter((t) => GALLERY_FILE_OF[t] === file))
      for (const i of await liveItems(env, fetchImpl, file, type, { retired: true }))
        out.push({ ...i, type });
  return out;
}

export interface GallerySetRecord {
  id: string;
  name: string;
  description: string;
  icon: string;
  author: GalleryAuthor;
  featured: boolean;
  items: { type: string; id: string }[];
  source?: string;
  added?: string;
  /** Absolute URL of the set's painted cover picture (cover.webp), when it has one. */
  cover?: string;
}

/** Starter sets (sets.json); an extra catalog's set points at its own items. */
export async function gallerySets(
  env: Env,
  fetchImpl: typeof fetch = fetch,
): Promise<GallerySetRecord[]> {
  const out: GallerySetRecord[] = [];
  for (const i of await liveItems(env, fetchImpl, "sets.json", "set")) {
    const doc = isRecord(i.document) ? i.document : (i as Record<string, unknown>);
    const items = Array.isArray(doc.items) ? doc.items : [];
    const prefix = i.source ? `${i.source}:` : "";
    const refs = items
      .filter(
        (x): x is { type: string; id: string } =>
          isRecord(x) && typeof x.type === "string" && typeof x.id === "string",
      )
      .map((x) => ({ type: x.type, id: `${prefix}${x.id}` }));
    if (refs.length < 1) continue;
    out.push({
      id: i.id,
      name: i.name,
      description: typeof doc.description === "string" ? doc.description : "",
      icon: typeof doc.icon === "string" ? doc.icon : "package",
      author: authorOf(i),
      featured: i.featured === true,
      items: refs,
      ...(i.source ? { source: String(i.source) } : {}),
      ...(typeof i.added === "string" ? { added: i.added } : {}),
      ...(typeof i.cover === "string" ? { cover: i.cover } : {}),
    });
  }
  return out;
}

/** authors.json from every source; an extra catalog's authors point at its own items. */
export async function galleryAuthors(
  env: Env,
  fetchImpl: typeof fetch = fetch,
): Promise<
  { handle: string; name: string; url?: string; items: { type: string; id: string }[] }[]
> {
  const sources = gallerySources(env);
  const out: {
    handle: string;
    name: string;
    url?: string;
    items: { type: string; id: string }[];
  }[] = [];
  for (const src of sources) {
    const index = (await readIndex(src, fetchImpl, "authors.json")) as unknown as {
      authors?: unknown[];
    } | null;
    // authors.json has `authors`, not `items`: read it without the items check.
    const list = index && Array.isArray(index.authors) ? index.authors : [];
    for (const a of list) {
      if (!isRecord(a) || typeof a.handle !== "string" || typeof a.name !== "string") continue;
      const items = (Array.isArray(a.items) ? a.items : [])
        .filter(
          (x): x is { type: string; id: string } =>
            isRecord(x) && typeof x.type === "string" && typeof x.id === "string",
        )
        .map((x) => ({ type: x.type, id: nsId(src, x.id) }));
      out.push({
        handle: src.name ? `${src.name}:${a.handle}` : a.handle,
        name: a.name.slice(0, 80),
        ...(typeof a.url === "string" && a.url.startsWith("https://") ? { url: a.url } : {}),
        items,
      });
    }
  }
  return out;
}

// ---------------------------------------------------------------- the skill catalog (D-241)

/** SKILL.md text by the skill's hash: a changed skill gets a new hash, so entries never go stale. */
const skillMdCache = new Map<string, string>();

async function skillMdOf(env: Env, item: GalleryRecord, fetchImpl: typeof fetch) {
  const hit = skillMdCache.get(item.sha256);
  if (hit !== undefined) return hit;
  const base = sourceOf(env, item.source)?.base;
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
 * are left out, since the app groups by them. Only the main catalog's skills join it.
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
    (i) =>
      i.type === "skill" &&
      !i.retired &&
      !i.source &&
      i.category &&
      categories.includes(i.category),
  );
  await Promise.all(
    live.map(async (i) => {
      const md = await skillMdOf(env, i, fetchImpl);
      if (md === null) return;
      try {
        const bundle = bundleFrom(
          md,
          i.files
            .filter(
              (f) =>
                !f.endsWith("/SKILL.md") && !f.endsWith("/item.json") && !f.endsWith("/tests.json"),
            )
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

/** Items left out because they need a newer server (D-315), for the nightly gallery check. */
export async function galleryTooNew(
  env: Env,
  fetchImpl: typeof fetch = fetch,
): Promise<{ type: string; id: string; min_server: string }[]> {
  const out: { type: string; id: string; min_server: string }[] = [];
  const sources = gallerySources(env);
  for (const file of new Set(Object.values(GALLERY_FILE_OF)))
    for (const src of sources) {
      const index = await readIndex(src, fetchImpl, file).catch(() => null);
      for (const raw of (index?.items ?? []) as unknown[]) {
        if (!isRecord(raw) || typeof raw.id !== "string" || typeof raw.type !== "string") continue;
        if (tooNewForServer(raw))
          out.push({ type: raw.type, id: nsId(src, raw.id), min_server: String(raw.min_server) });
      }
    }
  return out;
}

// ---------------------------------------------------------------- coding agents (D-370)

/** Refusals already logged, so a bad entry is reported once per version of the file. */
const codingWarned = new Set<string>();

/**
 * The coding agents catalog: coding-agents.json from the main gallery merged over the built-in
 * agents. Its entries become commands on people's computers, so it's read only from the main
 * catalog and only when that catalog is signed and its manifest vouches for the file (extra
 * catalogs and unsigned galleries never add commands). An entry that fails its check is refused
 * and the built-in agent of that id (if any) is kept; anything unreachable falls back to the
 * built-in list.
 */
export async function galleryCodingAgents(
  env: Env,
  fetchImpl: typeof fetch = fetch,
): Promise<CodingAgentSpec[]> {
  const main = gallerySources(env).find((s) => s.name === null);
  if (!main) return builtInCodingAgents();
  try {
    const signed = await sourceManifest(main, fetchImpl);
    if (!signed.ok || !signed.manifest || !Object.hasOwn(signed.manifest.files, CODING_AGENTS_FILE))
      return builtInCodingAgents();
    const index = await readIndex(main, fetchImpl, CODING_AGENTS_FILE);
    if (!index) return builtInCodingAgents();
    const { agents, refused } = mergeCodingAgents(index.items, { tooNew: tooNewForServer });
    for (const r of refused) {
      const key = `${signed.manifest.files[CODING_AGENTS_FILE]}|${r.id}`;
      if (codingWarned.has(key)) continue;
      codingWarned.add(key);
      warn("gallery coding agent refused; the built-in one is kept", {
        id: r.id,
        errors: r.errors.slice(0, 5),
      });
    }
    return agents;
  } catch {
    return builtInCodingAgents();
  }
}

/**
 * The check-in and setup prompts (D-374): `prompts.json` from the main catalog only, never an extra
 * source, so only reviewed first-party text reaches people's bots. Null when the gallery is off,
 * can't be reached or has no such file; the caller keeps what it has (or the built-in text).
 */
export async function galleryPrompts(
  env: Env,
  fetchImpl: typeof fetch = fetch,
): Promise<unknown[] | null> {
  const main = gallerySources(env).find((s) => s.name === null);
  if (!main) return null;
  const index = await readIndex(main, fetchImpl, "prompts.json").catch(() => null);
  return index ? (index.items as unknown[]) : null;
}
