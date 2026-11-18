/**
 * The gallery as bots see it (D-315): every kind in one list for gallery.search and
 * gallery.suggest (packages/agent/src/tools/gallery.ts), built from the gallery readers here.
 *
 * Workspace gallery policy: blocked items (and, in allowlist mode, anything not listed) are left
 * out; with no database every workspace is treated as `open`. Retired items stay in the list,
 * marked, so a suggestion of one is refused.
 */
import type { GalleryCatalog, GalleryEntry, GalleryEntryAccess } from "@casama/agent";
import type { Database } from "@casama/db";
import { galleryPolicyDecision } from "@casama/domain";
import type { Env } from "../env.ts";
import {
  galleryApps,
  galleryBots,
  galleryIndex,
  galleryLists,
  galleryPlugins,
  galleryRoutines,
} from "./gallery.ts";

const KEEP = 60_000;

/** The optional catalog fields (D-315) when a record carries them. */
function extras(
  raw: unknown,
): Pick<GalleryEntry, "access" | "needs" | "tags" | "featured" | "retired"> {
  if (!raw || typeof raw !== "object") return {};
  const r = raw as Record<string, unknown>;
  const list = (v: unknown) =>
    Array.isArray(v) ? v.filter((x): x is string => typeof x === "string") : undefined;
  const needs =
    r.needs && typeof r.needs === "object" ? (r.needs as Record<string, unknown>) : null;
  return {
    ...(r.access && typeof r.access === "object" ? { access: r.access as GalleryEntryAccess } : {}),
    ...(needs ? { needs: { apps: list(needs.apps), skills: list(needs.skills) } } : {}),
    ...(list(r.tags) ? { tags: list(r.tags) } : {}),
    ...(typeof r.featured === "boolean" ? { featured: r.featured } : {}),
    ...(r.retired === true ? { retired: true } : {}),
  };
}

const str = (v: unknown) => (typeof v === "string" && v ? v : undefined);

/** Every gallery item for agents, cached a minute (each reader caches its file for longer). */
export function galleryForAgents(
  env: Env,
  fetchImpl: typeof fetch = fetch,
  opts: { db?: Database } = {},
): GalleryCatalog {
  let cache: { at: number; items: Promise<GalleryEntry[]> } | null = null;
  const load = async (): Promise<GalleryEntry[]> => {
    const none = <T>(p: Promise<T[]>) => p.catch(() => [] as T[]);
    const [index, apps, bots, routines, plugins] = await Promise.all([
      galleryIndex(env, fetchImpl)
        .then((i) => i.items)
        .catch(() => []),
      none(galleryApps(env, fetchImpl)),
      none(galleryBots(env, fetchImpl)),
      none(galleryRoutines(env, fetchImpl)),
      none(galleryPlugins(env, fetchImpl)),
    ]);
    const out: GalleryEntry[] = [];
    for (const i of index) {
      const raw = i as unknown as Record<string, unknown>;
      out.push({
        type: i.type,
        id: i.id,
        name: i.name,
        description: str(raw.description),
        icon: str(raw.icon),
        category: i.category,
        ...extras(raw),
      });
    }
    for (const a of apps)
      out.push({
        type: "app",
        id: a.id,
        name: a.name,
        description: a.description,
        category: a.category,
        ...extras(a),
      });
    for (const b of bots)
      out.push({
        type: "bot",
        id: b.id,
        name: b.name,
        description: b.description,
        icon: b.icon,
        category: b.category,
        ...extras(b),
      });
    for (const r of routines)
      out.push({
        type: "routine",
        id: r.id,
        name: r.name,
        description: r.description,
        icon: r.icon,
        category: r.category,
        ...extras(r),
      });
    for (const p of plugins)
      out.push({
        type: "plugin",
        id: p.id,
        name: p.name,
        description: p.description,
        icon: p.icon,
        ...extras(p),
      });
    return out;
  };
  const all = async () => {
    const now = Date.now();
    if (!cache || now - cache.at > KEEP) {
      const items = load();
      cache = { at: now, items };
      items.catch(() => {
        cache = null;
      });
    }
    return cache.items;
  };
  return {
    async searchWords() {
      return (await galleryLists(env, fetchImpl).catch(() => null))?.searchWords;
    },
    async items(orgId: string) {
      const items = await all();
      if (!opts.db) return items;
      const { galleryPolicyFor } = await import("./gallery-install.ts");
      const policy = await galleryPolicyFor(opts.db, orgId).catch(() => null);
      if (!policy) return items;
      // As a member sees it: blocked items never come up; ones needing approval still may.
      return items.filter(
        (i) =>
          galleryPolicyDecision(policy, { type: i.type, id: i.id, access: i.access }).decision !==
          "block",
      );
    },
  };
}
