/** Web search with a bring-your-own key. */
export interface SearchResult {
  title: string;
  url: string;
  snippet: string;
}

export interface SearchProvider {
  readonly id: string;
  search(query: string, count?: number): Promise<SearchResult[]>;
}

export class BraveSearchProvider implements SearchProvider {
  readonly id = "brave_search";
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
