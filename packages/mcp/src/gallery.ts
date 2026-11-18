/**
 * The Casama gallery as an MCP tool (D-315): `gallery_search` finds ready-made skills, apps,
 * routines, bots, plugins, starter sets and looks in the public catalog files at
 * gallery.casama.ai, so a coding agent checks the gallery before writing a new one. No sign-in.
 */
import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { tokens } from "./docs.ts";

/** One catalog record, as the gallery's JSON files carry it (fields this tool reads). */
export interface GalleryRecord {
  type: string;
  id: string;
  name: string;
  description?: string;
  tags?: string[];
  category?: string;
  featured?: boolean;
  retired?: boolean;
  version?: number;
  access?: Record<string, unknown>;
  needs?: { apps?: string[]; skills?: string[] };
  files?: string[];
  [key: string]: unknown;
}

/** The catalog files that hold items. */
export const GALLERY_ITEM_FILES = [
  "index.json",
  "apps.json",
  "bots.json",
  "routines.json",
  "plugins.json",
  "sets.json",
] as const;

export const GALLERY_SEARCH_KINDS = [
  "skill",
  "app",
  "routine",
  "bot",
  "plugin",
  "set",
  "theme",
  "scheme",
  "wallpaper",
] as const;

export interface GallerySource {
  /** The catalog's base address, for links. */
  readonly base: string;
  items(): Promise<GalleryRecord[]>;
  /** Search words from the gallery (D-372), when it has them. */
  searchWords?(): Promise<Record<string, string[]> | undefined>;
}

/** The public catalog, fetched on first use and again after an hour. A missing file is skipped. */
export class RemoteGallery implements GallerySource {
  private cache: { at: number; value: Promise<GalleryRecord[]> } | null = null;
  private words: { at: number; value: Promise<Record<string, string[]> | undefined> } | null = null;
  readonly base: string;
  private readonly opts: { fetch?: typeof fetch; refreshMs?: number; now?: () => number };

  constructor(
    opts: {
      galleryUrl?: string;
      fetch?: typeof fetch;
      refreshMs?: number;
      now?: () => number;
    } = {},
  ) {
    this.base = (opts.galleryUrl ?? "https://gallery.casama.ai").replace(/\/$/, "");
    this.opts = opts;
  }

  private async file(name: string): Promise<GalleryRecord[]> {
    const r = await (this.opts.fetch ?? fetch)(`${this.base}/${name}`, {
      signal: AbortSignal.timeout(15_000),
    }).catch(() => null);
    if (!r?.ok) return [];
    const body = (await r.json().catch(() => null)) as { items?: unknown } | null;
    if (!Array.isArray(body?.items)) return [];
    return body.items.filter(
      (i): i is GalleryRecord =>
        !!i &&
        typeof i === "object" &&
        typeof (i as GalleryRecord).id === "string" &&
        typeof (i as GalleryRecord).name === "string" &&
        typeof (i as GalleryRecord).type === "string",
    );
  }

  /** The gallery's search words (lists.json, D-372); undefined when it has none, so SYNONYMS stands. */
  searchWords(): Promise<Record<string, string[]> | undefined> {
    const now = (this.opts.now ?? Date.now)();
    const hit = this.words;
    if (hit && now - hit.at < (this.opts.refreshMs ?? 3_600_000)) return hit.value;
    const value = (this.opts.fetch ?? fetch)(`${this.base}/lists.json`, {
      signal: AbortSignal.timeout(15_000),
    })
      .then((r) => (r.ok ? r.json() : null))
      .then((body) => searchWordsFrom(body))
      .catch(() => undefined);
    this.words = { at: now, value };
    return value;
  }

  items() {
    const now = (this.opts.now ?? Date.now)();
    const hit = this.cache;
    if (hit && now - hit.at < (this.opts.refreshMs ?? 3_600_000)) return hit.value;
    const value = Promise.all(GALLERY_ITEM_FILES.map((f) => this.file(f))).then((all) => {
      const items = all.flat();
      if (!items.length) throw new Error(`Couldn't load the gallery at ${this.base}`);
      return items;
    });
    const kept = value.catch((e) => {
      if (hit) {
        this.cache = hit;
        return hit.value;
      }
      this.cache = null;
      throw e;
    });
    this.cache = { at: now, value: kept };
    return kept;
  }
}

const WORD = /^[a-z0-9][a-z0-9' -]{0,30}$/;

/** lists.json → its search-words map; bad words are skipped, and nothing usable gives undefined. */
export function searchWordsFrom(body: unknown): Record<string, string[]> | undefined {
  const items = (body as { items?: unknown } | null)?.items;
  if (!Array.isArray(items)) return undefined;
  const list = items.find(
    (i) => i && typeof i === "object" && (i as { id?: unknown }).id === "search-words",
  ) as { document?: { words?: unknown } } | undefined;
  const words = list?.document?.words;
  if (!words || typeof words !== "object" || Array.isArray(words)) return undefined;
  const out: Record<string, string[]> = {};
  for (const [k, v] of Object.entries(words)) {
    if (!WORD.test(k) || !Array.isArray(v)) continue;
    const forms = v.filter((x): x is string => typeof x === "string" && WORD.test(x)).slice(0, 12);
    if (forms.length) out[k] = forms;
  }
  return Object.keys(out).length ? out : undefined;
}

/** The fallback for the gallery's search-words list (D-372). */
const SYNONYMS: Record<string, string[]> = {
  mail: ["email", "gmail", "outlook"],
  email: ["mail", "gmail", "inbox"],
  cal: ["calendar"],
  calendar: ["meeting", "schedule"],
  todo: ["task"],
  note: ["notion"],
  money: ["finance", "budget", "bill"],
  digest: ["brief", "summary"],
  summary: ["digest", "summarize"],
  look: ["theme", "scheme", "wallpaper"],
  code: ["github", "developer"],
};

/** Names count most, then tags and category, then the description. Retired items never match. */
export function searchGalleryRecords(
  items: GalleryRecord[],
  query: string,
  opts: { types?: readonly string[]; limit?: number; synonyms?: Record<string, string[]> } = {},
): GalleryRecord[] {
  const words = [...new Set(tokens(query))];
  const weights = new Map<string, number>();
  for (const w of words) {
    weights.set(w, 1);
    for (const s of (opts.synonyms ?? SYNONYMS)[w] ?? [])
      for (const t of tokens(s)) if (!weights.has(t)) weights.set(t, 0.5);
  }
  const types = opts.types?.length ? new Set(opts.types) : null;
  return items
    .filter((i) => i.retired !== true && (!types || types.has(i.type)))
    .map((item) => {
      const name = new Set(tokens(`${item.name} ${item.id.replaceAll("-", " ")}`));
      const tags = new Set(tokens([...(item.tags ?? []), item.category ?? ""].join(" ")));
      const desc = new Set(tokens(item.description ?? ""));
      let score = !words.length && types ? 0.1 : 0;
      for (const [t, w] of weights)
        score += ((name.has(t) ? 3 : 0) + (tags.has(t) ? 2 : 0) + (desc.has(t) ? 1 : 0)) * w;
      return { item, score: score > 0 ? score + (item.featured ? 0.25 : 0) : 0 };
    })
    .filter((s) => s.score > 0)
    .sort((a, b) => b.score - a.score || a.item.name.localeCompare(b.item.name))
    .slice(0, opts.limit ?? 5)
    .map((s) => s.item);
}

const text = (s: string) => ({ content: [{ type: "text" as const, text: s }] });

export function registerGalleryTools(server: McpServer, source: GallerySource) {
  server.registerTool(
    "gallery_search",
    {
      title: "Search the Casama gallery",
      description:
        "Search the Casama gallery (gallery.casama.ai) for ready-made skills, apps, routines, bots, plugins, starter sets and looks before writing a new one. Returns the best matches with what each can access, what it needs and its page. Add one in Casama from its page, or start from it with `casama init --from-gallery bot/<id>` or `plugin/<id>`.",
      inputSchema: {
        query: z.string().min(1).max(200),
        types: z.array(z.enum(GALLERY_SEARCH_KINDS)).max(9).optional(),
        limit: z.number().int().min(1).max(10).optional(),
      },
      annotations: { readOnlyHint: true, openWorldHint: false },
    },
    async ({ query, types, limit }) => {
      const synonyms = await source.searchWords?.().catch(() => undefined);
      const hits = searchGalleryRecords(await source.items(), query, {
        types,
        limit: limit ?? 5,
        synonyms,
      });
      if (!hits.length)
        return text(
          `Nothing in the gallery matches "${query}". Nothing to reuse: build it, and consider submitting it to the gallery.`,
        );
      return text(
        hits
          .map((h) =>
            [
              `## ${h.name} (${h.type}/${h.id})`,
              h.description ?? "",
              h.access ? `access: ${JSON.stringify(h.access)}` : "",
              h.needs ? `needs: ${JSON.stringify(h.needs)}` : "",
              `page: ${source.base}/i/${h.type}/${h.id}/`,
            ]
              .filter(Boolean)
              .join("\n"),
          )
          .join("\n\n"),
      );
    },
  );
}
