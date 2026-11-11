/**
 * The open gallery (D-184). The API caches index.json and checks a skill's files against the
 * index hash before installing them. An empty GALLERY_URL turns the gallery off.
 */
import { type GalleryType, galleryHash } from "@casama/domain";
import { ApiError } from "../api/errors.ts";
import type { Env } from "../env.ts";
import { bundleFrom, type SkillBundle } from "./skills.ts";

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
  files: string[];
}

interface IndexFile {
  schema: number;
  items: GalleryRecord[];
}

interface Cache {
  url: string;
  etag: string;
  at: number;
  index: IndexFile | null;
  /** How long this entry stays. A failure is kept briefly so a down host isn't hit on every tap. */
  ttl: number;
}

const OK_TTL = 15 * 60 * 1000;
const MISS_TTL = 30 * 1000;
let cache: Cache | undefined;

export function resetGalleryCache() {
  cache = undefined;
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

async function readIndex(env: Env, fetchImpl: typeof fetch): Promise<IndexFile | null> {
  const url = galleryBase(env);
  if (!url) return null;
  const now = Date.now();
  if (cache && cache.url === url && now - cache.at < cache.ttl) return cache.index;
  const headers: Record<string, string> = {};
  if (cache && cache.url === url && cache.etag) headers["If-None-Match"] = cache.etag;
  let res: Response;
  try {
    res = await fetchImpl(join(url, "index.json"), {
      headers,
      signal: AbortSignal.timeout(10_000),
    });
  } catch {
    cache = {
      url,
      etag: cache?.url === url ? cache.etag : "",
      at: now,
      index: null,
      ttl: MISS_TTL,
    };
    return null;
  }
  if (res.status === 304 && cache?.url === url && cache.index) {
    cache = { ...cache, at: now, ttl: OK_TTL };
    return cache.index;
  }
  if (!res.ok) {
    cache = { url, etag: "", at: now, index: null, ttl: MISS_TTL };
    return null;
  }
  const index = (await res.json()) as IndexFile;
  cache = {
    url,
    etag: res.headers.get("etag") ?? "",
    at: now,
    index,
    ttl: OK_TTL,
  };
  return index;
}

export async function galleryIndex(env: Env, fetchImpl: typeof fetch = fetch) {
  const url = galleryBase(env);
  if (!url) return { enabled: false as const, available: false, items: [] as GalleryRecord[] };
  const index = await readIndex(env, fetchImpl);
  return { enabled: true as const, available: index != null, items: index?.items ?? [] };
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
