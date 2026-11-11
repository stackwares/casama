/**
 * Web search: the workspace's own Brave Search or Tavily key, else the server's SearXNG
 * (SEARXNG_URL, D-179), which is free to run.
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
