/**
 * Web search: the workspace's own Brave Search, Tavily, Parallel or Serper key, else the server's
 * own chain (Parallel, Serper, optionally DeepSeek, D-384), else the server's SearXNG
 * (SEARXNG_URL, D-179), which is free to run. Answers are cached for a few hours (D-384).
 */
export interface SearchResult {
  title: string;
  url: string;
  snippet: string;
}

export interface SearchProvider {
  readonly id: string;
  /** What one query costs whoever pays for it, in USD (recorded in usage_ledger). */
  readonly costUsd: number;
  search(query: string, count?: number): Promise<SearchResult[]>;
}

export class BraveSearchProvider implements SearchProvider {
  readonly id = "brave_search";
  readonly costUsd = 0.005;
  private readonly key: string;
  private readonly base: string;
  private readonly fetchImpl: typeof fetch;
  constructor(key: string, opts: { base?: string; fetch?: typeof fetch } = {}) {
    this.key = key;
    this.base = (opts.base ?? "https://api.search.brave.com").replace(/\/$/, "");
    this.fetchImpl = opts.fetch ?? fetch;
  }
  async search(query: string, count = 8) {
    const res = await this.fetchImpl(
      `${this.base}/res/v1/web/search?q=${encodeURIComponent(query)}&count=${count}`,
      {
        headers: { "x-subscription-token": this.key, accept: "application/json" },
      },
    );
    if (!res.ok) throw new Error(`Brave Search returned ${res.status}`);
    const json = (await res.json()) as {
      web?: { results?: Array<{ title: string; url: string; description?: string }> };
    };
    return (json.web?.results ?? []).slice(0, count).map((r) => ({
      title: r.title,
      url: r.url,
      snippet: (r.description ?? "").replace(/<[^>]+>/g, ""),
    }));
  }
}

export class TavilySearchProvider implements SearchProvider {
  readonly id = "tavily";
  readonly costUsd = 0.008;
  private readonly key: string;
  private readonly base: string;
  private readonly fetchImpl: typeof fetch;
  constructor(key: string, opts: { base?: string; fetch?: typeof fetch } = {}) {
    this.key = key;
    this.base = (opts.base ?? "https://api.tavily.com").replace(/\/$/, "");
    this.fetchImpl = opts.fetch ?? fetch;
  }
  async search(query: string, count = 8) {
    const res = await this.fetchImpl(`${this.base}/search`, {
      method: "POST",
      headers: { authorization: `Bearer ${this.key}`, "content-type": "application/json" },
      body: JSON.stringify({ query, max_results: count }),
    });
    if (!res.ok) throw new Error(`Tavily returned ${res.status}`);
    const json = (await res.json()) as {
      results?: Array<{ title: string; url: string; content?: string }>;
    };
    return (json.results ?? []).map((r) => ({
      title: r.title,
      url: r.url,
      snippet: r.content ?? "",
    }));
  }
}

/**
 * A SearXNG instance (https://docs.searxng.org) run by the server owner: no key and no per-query
 * price. Its settings must allow the JSON format (`search.formats` includes `json`).
 */
export class SearxngSearchProvider implements SearchProvider {
  readonly id = "searxng";
  readonly costUsd = 0;
  private readonly base: string;
  private readonly fetchImpl: typeof fetch;
  constructor(base: string, opts: { fetch?: typeof fetch } = {}) {
    this.base = base.replace(/\/$/, "");
    this.fetchImpl = opts.fetch ?? fetch;
  }
  async search(query: string, count = 8) {
    const res = await this.fetchImpl(
      `${this.base}/search?q=${encodeURIComponent(query)}&format=json&safesearch=1`,
      { headers: { accept: "application/json" }, signal: AbortSignal.timeout(15_000) },
    );
    if (!res.ok) throw new Error(`SearXNG returned ${res.status}`);
    const json = (await res.json()) as {
      results?: Array<{ title?: string; url?: string; content?: string }>;
    };
    const seen = new Set<string>();
    const out: SearchResult[] = [];
    for (const r of json.results ?? []) {
      if (!r.url || seen.has(r.url)) continue;
      seen.add(r.url);
      out.push({ title: r.title ?? r.url, url: r.url, snippet: r.content ?? "" });
      if (out.length >= count) break;
    }
    return out;
  }
}

/** One search's answer and what it cost, from the provider that actually answered (D-384). */
export interface SearchOutcome {
  results: SearchResult[];
  /** The provider that answered ("cache" for a cached answer). */
  providerId: string;
  costUsd: number;
  cached: boolean;
  /** Answered by the server's own chain, so the server paid `costUsd` (D-400). */
  serverPaid?: boolean;
}

/** A provider that knows which of its parts answered: the fallback chain and the cache. */
export interface MeteredSearchProvider extends SearchProvider {
  searchMetered(query: string, count?: number): Promise<SearchOutcome>;
}

/** Search with [p] and say what it cost: the answering provider's price, 0 for a cache hit. */
export async function runSearch(
  p: SearchProvider,
  query: string,
  count = 8,
): Promise<SearchOutcome> {
  if ("searchMetered" in p && typeof p.searchMetered === "function")
    return (p as MeteredSearchProvider).searchMetered(query, count);
  return {
    results: await p.search(query, count),
    providerId: p.id,
    costUsd: p.costUsd,
    cached: false,
  };
}

/**
 * Serper (https://serper.dev): Google results, $0.001 a query at volume (D-384).
 * POST /search with `X-API-KEY`; the answer box, when there is one, comes first.
 */
/**
 * Serper warns that Google result links can come back wrapped as google.com/goto?url=… (and
 * offers a /resolve endpoint for them); the real address is in the `url` parameter.
 */
export function unwrapGoogleLink(link: string) {
  try {
    const u = new URL(link);
    if (
      /(^|\.)google\.[a-z.]+$/.test(u.hostname) &&
      (u.pathname === "/goto" || u.pathname === "/url")
    ) {
      const real = u.searchParams.get("url") ?? u.searchParams.get("q");
      if (real && /^https?:\/\//.test(real)) return real;
    }
  } catch {}
  return link;
}

export class SerperSearchProvider implements SearchProvider {
  readonly id = "serper";
  readonly costUsd = 0.001;
  private readonly key: string;
  private readonly base: string;
  private readonly fetchImpl: typeof fetch;
  constructor(key: string, opts: { base?: string; fetch?: typeof fetch } = {}) {
    this.key = key;
    this.base = (opts.base ?? "https://google.serper.dev").replace(/\/$/, "");
    this.fetchImpl = opts.fetch ?? fetch;
  }
  async search(query: string, count = 8) {
    const res = await this.fetchImpl(`${this.base}/search`, {
      method: "POST",
      headers: { "x-api-key": this.key, "content-type": "application/json" },
      body: JSON.stringify({ q: query, num: Math.min(Math.max(count, 1), 20) }),
      signal: AbortSignal.timeout(15_000),
    });
    if (!res.ok) throw new Error(`Serper returned ${res.status}`);
    const json = (await res.json()) as {
      answerBox?: { title?: string; link?: string; answer?: string; snippet?: string };
      organic?: Array<{ title?: string; link?: string; snippet?: string; date?: string }>;
    };
    const out: SearchResult[] = [];
    const box = json.answerBox;
    if (box?.link && (box.answer || box.snippet)) {
      const url = unwrapGoogleLink(box.link);
      out.push({
        title: box.title ?? url,
        url,
        snippet: [box.answer, box.snippet].filter(Boolean).join(" — "),
      });
    }
    for (const r of json.organic ?? []) {
      if (!r.link) continue;
      const url = unwrapGoogleLink(r.link);
      if (out.some((o) => o.url === url)) continue;
      out.push({
        title: r.title ?? url,
        url,
        snippet: [r.date, r.snippet].filter(Boolean).join(" — "),
      });
    }
    return out.slice(0, count);
  }
}

/**
 * Tries each provider in order and falls through to the next on an error or no results (D-384).
 * The cost reported is the one of the provider that answered; providers that failed cost nothing
 * we can see (a failed request isn't billed by any of them).
 */
export class FallbackSearchProvider implements MeteredSearchProvider {
  readonly id: string;
  readonly providers: readonly SearchProvider[];
  private readonly onError?: (providerId: string, err: unknown) => void;
  constructor(
    providers: SearchProvider[],
    opts: { onError?: (providerId: string, err: unknown) => void } = {},
  ) {
    if (!providers.length) throw new Error("FallbackSearchProvider needs at least one provider");
    this.providers = providers;
    this.id = providers.map((p) => p.id).join(">");
    this.onError = opts.onError;
  }
  /** The first provider's price: what a query costs when the chain works as intended. */
  get costUsd() {
    return this.providers[0]?.costUsd ?? 0;
  }
  async search(query: string, count = 8) {
    return (await this.searchMetered(query, count)).results;
  }
  async searchMetered(query: string, count = 8): Promise<SearchOutcome> {
    let lastError: unknown = null;
    let empty: SearchOutcome | null = null;
    for (const p of this.providers) {
      try {
        const outcome = await runSearch(p, query, count);
        if (outcome.results.length) return outcome;
        // No results is an answer too: keep the first one in case every provider agrees.
        empty ??= outcome;
      } catch (err) {
        lastError = err;
        this.onError?.(p.id, err);
      }
    }
    if (empty) return empty;
    throw lastError instanceof Error ? lastError : new Error("Every search provider failed");
  }
}

/** Lower case, single spaces: "  Casama  AI " and "casama ai" are one query. */
export function normalizeQuery(q: string) {
  return q.normalize("NFKC").trim().replace(/\s+/g, " ").toLowerCase();
}

/**
 * Remembers answers by (provider chain, normalized query, count) for `ttlMs` (default 6 hours),
 * least recently used first out past `maxEntries` (D-384). In memory, per worker process: a
 * restart forgets it, which only costs a few repeat queries. Only answers with results are kept.
 */
export class SearchCache {
  private readonly map = new Map<string, { at: number; results: SearchResult[] }>();
  readonly ttlMs: number;
  readonly maxEntries: number;
  private readonly now: () => number;
  constructor(opts: { ttlMs?: number; maxEntries?: number; now?: () => number } = {}) {
    this.ttlMs = opts.ttlMs ?? 6 * 60 * 60 * 1000;
    this.maxEntries = opts.maxEntries ?? 2_000;
    this.now = opts.now ?? Date.now;
  }
  static key(chain: string, query: string, count: number) {
    return `${chain}\u0000${count}\u0000${normalizeQuery(query)}`;
  }
  get(key: string): SearchResult[] | null {
    const hit = this.map.get(key);
    if (!hit) return null;
    if (this.now() - hit.at > this.ttlMs) {
      this.map.delete(key);
      return null;
    }
    // Move to the newest end.
    this.map.delete(key);
    this.map.set(key, hit);
    return hit.results;
  }
  set(key: string, results: SearchResult[]) {
    this.map.delete(key);
    this.map.set(key, { at: this.now(), results });
    while (this.map.size > this.maxEntries) {
      const oldest = this.map.keys().next().value;
      if (oldest === undefined) break;
      this.map.delete(oldest);
    }
  }
  get size() {
    return this.map.size;
  }
}

/**
 * [inner] with a [SearchCache] in front. `scope` keeps answers apart where they must be: a
 * workspace's own key is scoped to the workspace (its own bill), the server's chain is shared.
 * A cache hit costs 0 and says so (`cached`).
 */
export class CachedSearchProvider implements MeteredSearchProvider {
  readonly id: string;
  private readonly inner: SearchProvider;
  private readonly cache: SearchCache;
  private readonly scope: string;
  constructor(inner: SearchProvider, cache: SearchCache, scope = "") {
    this.inner = inner;
    this.cache = cache;
    this.scope = scope;
    this.id = inner.id;
  }
  get costUsd() {
    return this.inner.costUsd;
  }
  async search(query: string, count = 8) {
    return (await this.searchMetered(query, count)).results;
  }
  async searchMetered(query: string, count = 8): Promise<SearchOutcome> {
    const key = SearchCache.key(`${this.scope}|${this.inner.id}`, query, count);
    const hit = this.cache.get(key);
    if (hit) return { results: hit, providerId: "cache", costUsd: 0, cached: true };
    const outcome = await runSearch(this.inner, query, count);
    if (outcome.results.length) this.cache.set(key, outcome.results);
    return outcome;
  }
}

/**
 * Parallel Search (https://docs.parallel.ai, `POST /v1/search`): results with markdown excerpts
 * chosen for the query, made for agents. Fast mode is $1 per 1,000 requests with up to 10
 * results (D-384); each result past 10 costs $0.001 more, so the count is capped at 10.
 */
export class ParallelSearchProvider implements SearchProvider {
  readonly id = "parallel";
  readonly costUsd = 0.001;
  private readonly key: string;
  private readonly base: string;
  private readonly fetchImpl: typeof fetch;
  constructor(key: string, opts: { base?: string; fetch?: typeof fetch } = {}) {
    this.key = key;
    this.base = (opts.base ?? "https://api.parallel.ai").replace(/\/$/, "");
    this.fetchImpl = opts.fetch ?? fetch;
  }
  async search(query: string, count = 8) {
    const n = Math.min(Math.max(count, 1), 10);
    const res = await this.fetchImpl(`${this.base}/v1/search`, {
      method: "POST",
      headers: { "x-api-key": this.key, "content-type": "application/json" },
      body: JSON.stringify({
        objective: query,
        search_queries: [query.slice(0, 200)],
        mode: "fast",
        // About 600 characters an answer: snippets, not whole pages (web.fetch reads those).
        max_chars_total: n * 600,
        advanced_settings: { max_results: n },
      }),
      signal: AbortSignal.timeout(20_000),
    });
    if (!res.ok) throw new Error(`Parallel returned ${res.status}`);
    const json = (await res.json()) as {
      results?: Array<{
        url?: string;
        title?: string | null;
        publish_date?: string | null;
        excerpts?: string[];
      }>;
    };
    const out: SearchResult[] = [];
    for (const r of json.results ?? []) {
      if (!r.url || out.some((o) => o.url === r.url)) continue;
      const excerpt = (r.excerpts ?? []).join(" … ").replace(/\s+/g, " ").trim();
      out.push({
        title: r.title || r.url,
        url: r.url,
        snippet: [r.publish_date, excerpt.slice(0, 700)].filter(Boolean).join(" — "),
      });
      if (out.length >= count) break;
    }
    return out;
  }
}

/**
 * DeepSeek's Search API (https://api-docs.deepseek.com/guides/search, `POST /v1/tools/search`,
 * launched October 2026): $0.75 per 1,000 searches that return results (D-384). Never used
 * unless the server owner names it in SEARCH_PROVIDER_ORDER and sets DEEPSEEK_SEARCH_API_KEY:
 * queries go to DeepSeek's servers in China, which some people and companies can't accept.
 */
export class DeepSeekSearchProvider implements SearchProvider {
  readonly id = "deepseek";
  readonly costUsd = 0.00075;
  private readonly key: string;
  private readonly base: string;
  private readonly fetchImpl: typeof fetch;
  constructor(key: string, opts: { base?: string; fetch?: typeof fetch } = {}) {
    this.key = key;
    this.base = (opts.base ?? "https://api.deepseek.com").replace(/\/$/, "");
    this.fetchImpl = opts.fetch ?? fetch;
  }
  async search(query: string, count = 8) {
    const res = await this.fetchImpl(`${this.base}/v1/tools/search`, {
      method: "POST",
      headers: { authorization: `Bearer ${this.key}`, "content-type": "application/json" },
      // The API takes queries of at most 128 characters.
      body: JSON.stringify({ query: query.slice(0, 128), count: Math.min(Math.max(count, 1), 50) }),
      signal: AbortSignal.timeout(20_000),
    });
    if (!res.ok) throw new Error(`DeepSeek Search returned ${res.status}`);
    const json = (await res.json()) as {
      results?: Array<{
        title?: string;
        url?: string;
        snippet?: string;
        summary?: string;
        date?: string | null;
      }>;
    };
    const out: SearchResult[] = [];
    for (const r of json.results ?? []) {
      if (!r.url || out.some((o) => o.url === r.url)) continue;
      out.push({
        title: r.title || r.url,
        url: r.url,
        // The summary is written for models; the snippet is the short fallback.
        snippet: [r.date?.slice(0, 10), r.summary || r.snippet].filter(Boolean).join(" — "),
      });
      if (out.length >= count) break;
    }
    return out;
  }
}

/** The providers a server can name in SEARCH_PROVIDER_ORDER (D-384). */
export const SERVER_SEARCH_PROVIDERS = ["parallel", "serper", "deepseek", "searxng"] as const;
export type ServerSearchProviderId = (typeof SERVER_SEARCH_PROVIDERS)[number];

/**
 * The server's own search chain from SEARCH_PROVIDER_ORDER and the keys it has (D-384): each
 * named provider with a key (or SearXNG with a URL), in order; unknown names and providers
 * without a key are skipped, and a configured SearXNG not named comes last. DeepSeek is included
 * only when named, never by default.
 */
export function serverSearchChain(opts: {
  order?: string;
  keys: { parallel?: string; serper?: string; deepseek?: string };
  searxngUrl?: string;
  fetch?: typeof fetch;
  bases?: { parallel?: string; serper?: string; deepseek?: string };
}): SearchProvider[] {
  // Empty (an unset compose variable) means the default.
  const order = (opts.order?.trim() || "parallel,serper,searxng")
    .split(",")
    .map((s) => s.trim().toLowerCase())
    .filter(Boolean);
  const out: SearchProvider[] = [];
  for (const id of new Set(order)) {
    if (id === "parallel" && opts.keys.parallel)
      out.push(
        new ParallelSearchProvider(opts.keys.parallel, {
          fetch: opts.fetch,
          base: opts.bases?.parallel,
        }),
      );
    else if (id === "serper" && opts.keys.serper)
      out.push(
        new SerperSearchProvider(opts.keys.serper, { fetch: opts.fetch, base: opts.bases?.serper }),
      );
    else if (id === "deepseek" && opts.keys.deepseek)
      out.push(
        new DeepSeekSearchProvider(opts.keys.deepseek, {
          fetch: opts.fetch,
          base: opts.bases?.deepseek,
        }),
      );
    // The server owner's own instance (a configured, trusted address, so not egress-filtered).
    else if (id === "searxng" && opts.searxngUrl)
      out.push(new SearxngSearchProvider(opts.searxngUrl));
  }
  // A configured SearXNG is always the last resort, named or not: it is free.
  if (opts.searxngUrl && !out.some((p) => p.id === "searxng"))
    out.push(new SearxngSearchProvider(opts.searxngUrl));
  return out;
}

/** Workspace key providers that run web search, in the order a workspace's keys are tried. */
export const WORKSPACE_SEARCH_PROVIDERS = ["brave_search", "tavily", "parallel", "serper"] as const;

/** A search provider for a workspace's own key. */
export function workspaceSearchProvider(
  key: { provider: string; key: string },
  opts: {
    fetch?: typeof fetch;
    bases?: { brave?: string; tavily?: string; parallel?: string; serper?: string };
  } = {},
): SearchProvider | null {
  const f = opts.fetch;
  switch (key.provider) {
    case "brave_search":
      return new BraveSearchProvider(key.key, { fetch: f, base: opts.bases?.brave });
    case "tavily":
      return new TavilySearchProvider(key.key, { fetch: f, base: opts.bases?.tavily });
    case "parallel":
      return new ParallelSearchProvider(key.key, { fetch: f, base: opts.bases?.parallel });
    case "serper":
      return new SerperSearchProvider(key.key, { fetch: f, base: opts.bases?.serper });
    default:
      return null;
  }
}

/**
 * The provider web.search uses for a workspace (D-384): its own key first, then the server's
 * chain (SEARCH_PROVIDER_ORDER, SearXNG last), each falling through to the next on an error or
 * no results; cached per workspace (a shared cache would let one workspace see, from a cost-0
 * answer, that another searched the same words). Null when there is nothing to search with.
 */
/** One of the server's own search providers: what it answers, the server pays for (D-400). */
export class ServerPaidSearchProvider implements MeteredSearchProvider {
  readonly inner: SearchProvider;
  constructor(inner: SearchProvider) {
    this.inner = inner;
  }
  get id() {
    return this.inner.id;
  }
  get costUsd() {
    return this.inner.costUsd;
  }
  async search(query: string, count = 8) {
    return (await this.searchMetered(query, count)).results;
  }
  async searchMetered(query: string, count = 8): Promise<SearchOutcome> {
    return { ...(await runSearch(this.inner, query, count)), serverPaid: true };
  }
}

export function searchProviderFor(opts: {
  orgId: string;
  own: SearchProvider | null;
  server: SearchProvider[];
  cache?: SearchCache;
  onError?: (providerId: string, err: unknown) => void;
}): SearchProvider | null {
  const chain = [
    ...(opts.own ? [opts.own] : []),
    ...opts.server.map((p) => new ServerPaidSearchProvider(p)),
  ];
  if (!chain.length) return null;
  const inner =
    chain.length === 1
      ? (chain[0] as SearchProvider)
      : new FallbackSearchProvider(chain, { onError: opts.onError });
  return opts.cache ? new CachedSearchProvider(inner, opts.cache, opts.orgId) : inner;
}
