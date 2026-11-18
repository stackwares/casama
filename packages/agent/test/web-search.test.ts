/** Web search providers, the fallback chain, the cache and who searches for a workspace (D-384). */
import { describe, expect, it } from "vitest";
import {
  CachedSearchProvider,
  DeepSeekSearchProvider,
  FallbackSearchProvider,
  ParallelSearchProvider,
  runSearch,
  SearchCache,
  type SearchProvider,
  type SearchResult,
  SerperSearchProvider,
  searchProviderFor,
  serverSearchChain,
  unwrapGoogleLink,
  workspaceSearchProvider,
} from "../src/search.ts";

type Seen = { url: string; init: RequestInit };
const recorder = (answer: () => Response) => {
  const seen: Seen[] = [];
  const f = (async (url: string, init: RequestInit = {}) => {
    seen.push({ url, init });
    return answer();
  }) as typeof fetch;
  return { seen, f };
};
const header = (s: Seen, name: string) => new Headers(s.init.headers).get(name);
const body = (s: Seen) => JSON.parse(String(s.init.body)) as Record<string, unknown>;

describe("ParallelSearchProvider", () => {
  it("asks fast mode with the key and reads excerpts", async () => {
    const { seen, f } = recorder(() =>
      Response.json({
        search_id: "search_1",
        results: [
          {
            url: "https://a.example/",
            title: "A",
            publish_date: "2026-10-01",
            excerpts: ["one", "two"],
          },
          { url: "https://a.example/", title: "dupe", excerpts: [] },
          { url: "https://b.example/", title: null, excerpts: ["b"] },
        ],
      }),
    );
    const p = new ParallelSearchProvider("pk", { fetch: f, base: "https://parallel.test/" });
    expect(p.costUsd).toBe(0.001);
    expect(await p.search("casama ai", 5)).toEqual([
      { title: "A", url: "https://a.example/", snippet: "2026-10-01 — one … two" },
      { title: "https://b.example/", url: "https://b.example/", snippet: "b" },
    ]);
    const s = seen[0] as Seen;
    expect(s.url).toBe("https://parallel.test/v1/search");
    expect(s.init.method).toBe("POST");
    expect(header(s, "x-api-key")).toBe("pk");
    expect(body(s)).toMatchObject({
      objective: "casama ai",
      search_queries: ["casama ai"],
      mode: "fast",
      advanced_settings: { max_results: 5 },
    });
  });

  it("caps results at 10 (more cost extra) and reports errors", async () => {
    const { seen, f } = recorder(() => Response.json({ results: [] }));
    await new ParallelSearchProvider("k", { fetch: f }).search("x", 20);
    expect(body(seen[0] as Seen)).toMatchObject({ advanced_settings: { max_results: 10 } });
    const bad = recorder(() => new Response("no", { status: 401 }));
    await expect(new ParallelSearchProvider("k", { fetch: bad.f }).search("x")).rejects.toThrow(
      "Parallel returned 401",
    );
  });

  it.skipIf(!process.env.PARALLEL_TEST_KEY)("searches for real", async () => {
    const r = await new ParallelSearchProvider(process.env.PARALLEL_TEST_KEY as string).search(
      "casama ai assistant",
      5,
    );
    expect(r.length).toBeGreaterThan(0);
    expect(r[0]?.url).toMatch(/^https?:\/\//);
  });
});

describe("SerperSearchProvider", () => {
  it("posts q and num, puts the answer box first and unwraps Google links", async () => {
    const { seen, f } = recorder(() =>
      Response.json({
        answerBox: { title: "Box", link: "https://box.example/", answer: "42" },
        organic: [
          { title: "Box again", link: "https://box.example/", snippet: "dupe" },
          {
            title: "Wrapped",
            link: "https://www.google.com/goto?url=https%3A%2F%2Freal.example%2Fp",
            snippet: "s",
            date: "Mar 1, 2026",
          },
          { link: "https://c.example/" },
        ],
      }),
    );
    const p = new SerperSearchProvider("sk", { fetch: f, base: "https://serper.test" });
    expect(p.costUsd).toBe(0.001);
    expect(await p.search("life", 3)).toEqual([
      { title: "Box", url: "https://box.example/", snippet: "42" },
      { title: "Wrapped", url: "https://real.example/p", snippet: "Mar 1, 2026 — s" },
      { title: "https://c.example/", url: "https://c.example/", snippet: "" },
    ]);
    const s = seen[0] as Seen;
    expect(s.url).toBe("https://serper.test/search");
    expect(header(s, "x-api-key")).toBe("sk");
    expect(body(s)).toEqual({ q: "life", num: 3 });
  });

  it("leaves ordinary links alone and reports errors", async () => {
    expect(unwrapGoogleLink("https://example.com/goto?url=https://x.example")).toBe(
      "https://example.com/goto?url=https://x.example",
    );
    expect(unwrapGoogleLink("https://www.google.com/goto?url=javascript:alert(1)")).toBe(
      "https://www.google.com/goto?url=javascript:alert(1)",
    );
    const bad = recorder(() => new Response("", { status: 403 }));
    await expect(new SerperSearchProvider("k", { fetch: bad.f }).search("x")).rejects.toThrow(
      "Serper returned 403",
    );
  });

  it.skipIf(!process.env.SERPER_TEST_KEY)("searches for real", async () => {
    const r = await new SerperSearchProvider(process.env.SERPER_TEST_KEY as string).search(
      "casama ai assistant",
      5,
    );
    expect(r.length).toBeGreaterThan(0);
    expect(r[0]?.url).toMatch(/^https?:\/\//);
  });
});

describe("DeepSeekSearchProvider", () => {
  it("sends a Bearer key and at most 128 characters, and prefers the summary", async () => {
    const { seen, f } = recorder(() =>
      Response.json({
        results: [
          {
            title: "D",
            url: "https://d.example/",
            snippet: "short",
            summary: "long summary",
            date: "2026-10-17T00:00:00Z",
            rerank_score: 2,
          },
          {
            title: "E",
            url: "https://e.example/",
            snippet: "only snippet",
            summary: "",
            date: null,
          },
        ],
      }),
    );
    const p = new DeepSeekSearchProvider("dk", { fetch: f, base: "https://ds.test" });
    expect(p.costUsd).toBe(0.00075);
    expect(await p.search("q".repeat(300), 4)).toEqual([
      { title: "D", url: "https://d.example/", snippet: "2026-10-17 — long summary" },
      { title: "E", url: "https://e.example/", snippet: "only snippet" },
    ]);
    const s = seen[0] as Seen;
    expect(s.url).toBe("https://ds.test/v1/tools/search");
    expect(header(s, "authorization")).toBe("Bearer dk");
    expect(body(s)).toEqual({ query: "q".repeat(128), count: 4 });
  });

  it("reports errors", async () => {
    const bad = recorder(() => new Response("", { status: 402 }));
    await expect(new DeepSeekSearchProvider("k", { fetch: bad.f }).search("x")).rejects.toThrow(
      "DeepSeek Search returned 402",
    );
  });
});

const fake = (
  id: string,
  costUsd: number,
  answer: () => SearchResult[] | Promise<SearchResult[]>,
) => {
  const calls: string[] = [];
  const p: SearchProvider & { calls: string[] } = {
    id,
    costUsd,
    calls,
    async search(q) {
      calls.push(q);
      return answer();
    },
  };
  return p;
};
const hit = (url: string): SearchResult => ({ title: url, url, snippet: "" });

describe("FallbackSearchProvider", () => {
  it("falls through errors and empty answers and reports the answering provider's cost", async () => {
    const a = fake("a", 0.005, () => {
      throw new Error("down");
    });
    const b = fake("b", 0.002, () => []);
    const c = fake("c", 0.001, () => [hit("https://c/")]);
    const d = fake("d", 0, () => [hit("https://d/")]);
    const failed: string[] = [];
    const chain = new FallbackSearchProvider([a, b, c, d], { onError: (id) => failed.push(id) });
    expect(chain.id).toBe("a>b>c>d");
    expect(await runSearch(chain, "q")).toEqual({
      results: [hit("https://c/")],
      providerId: "c",
      costUsd: 0.001,
      cached: false,
    });
    expect(failed).toEqual(["a"]);
    expect(d.calls).toEqual([]);
  });

  it("gives the first empty answer when nobody finds anything, and throws when all fail", async () => {
    const empty = new FallbackSearchProvider([fake("a", 0.001, () => []), fake("b", 0, () => [])]);
    expect(await runSearch(empty, "q")).toMatchObject({ results: [], providerId: "a" });
    const down = new FallbackSearchProvider([
      fake("a", 0.001, () => {
        throw new Error("one");
      }),
      fake("b", 0, () => {
        throw new Error("two");
      }),
    ]);
    await expect(down.search("q")).rejects.toThrow("two");
  });
});

describe("search cache", () => {
  it("answers a repeat (any spacing or case) for free until it expires", async () => {
    let now = 0;
    const cache = new SearchCache({ ttlMs: 1000, now: () => now });
    const inner = fake("serper", 0.001, () => [hit("https://x/")]);
    const p = new CachedSearchProvider(inner, cache, "org1");
    expect(await runSearch(p, "Casama  AI")).toMatchObject({
      costUsd: 0.001,
      cached: false,
      providerId: "serper",
    });
    expect(await runSearch(p, " casama ai ")).toEqual({
      results: [hit("https://x/")],
      providerId: "cache",
      costUsd: 0,
      cached: true,
    });
    // Another count is another question.
    expect(await runSearch(p, "casama ai", 3)).toMatchObject({ cached: false });
    now = 1001;
    expect(await runSearch(p, "casama ai")).toMatchObject({ cached: false });
    expect(inner.calls).toHaveLength(3);
  });

  it("keeps workspaces apart, skips empty answers and stays bounded", async () => {
    const cache = new SearchCache({ maxEntries: 2 });
    const inner = fake("p", 0.001, () => [hit("https://x/")]);
    await runSearch(new CachedSearchProvider(inner, cache, "org1"), "q");
    expect(await runSearch(new CachedSearchProvider(inner, cache, "org2"), "q")).toMatchObject({
      cached: false,
    });
    const none = fake("p", 0.001, () => []);
    await runSearch(new CachedSearchProvider(none, cache, "org3"), "nothing");
    await runSearch(new CachedSearchProvider(none, cache, "org3"), "nothing");
    expect(none.calls).toHaveLength(2);
    await runSearch(new CachedSearchProvider(inner, cache, "org1"), "q3");
    expect(cache.size).toBe(2);
    // org1's "q" was the oldest and is gone.
    expect(await runSearch(new CachedSearchProvider(inner, cache, "org1"), "q")).toMatchObject({
      cached: false,
    });
  });
});

describe("who searches for a workspace", () => {
  it("builds the server chain from SEARCH_PROVIDER_ORDER and the keys it has, SearXNG last", () => {
    const ids = (c: SearchProvider[]) => c.map((p) => p.id);
    expect(
      ids(serverSearchChain({ keys: { parallel: "p", serper: "s" }, searxngUrl: "http://sx" })),
    ).toEqual(["parallel", "serper", "searxng"]);
    // Without a key a provider is skipped; DeepSeek only when named.
    expect(ids(serverSearchChain({ keys: { serper: "s", deepseek: "d" } }))).toEqual(["serper"]);
    expect(
      ids(
        serverSearchChain({
          order: "deepseek, SERPER,bogus,serper",
          keys: { parallel: "p", serper: "s", deepseek: "d" },
          searxngUrl: "http://sx",
        }),
      ),
    ).toEqual(["deepseek", "serper", "searxng"]);
    expect(serverSearchChain({ keys: {} })).toEqual([]);
    // An unset compose variable arrives empty and means the default order.
    expect(ids(serverSearchChain({ order: "", keys: { parallel: "p", serper: "s" } }))).toEqual([
      "parallel",
      "serper",
    ]);
  });

  it("puts the workspace's own key first, then the server chain, cached per workspace", async () => {
    const own = workspaceSearchProvider({ provider: "tavily", key: "t" }) as SearchProvider;
    expect(own.id).toBe("tavily");
    expect(workspaceSearchProvider({ provider: "parallel", key: "p" })?.id).toBe("parallel");
    expect(workspaceSearchProvider({ provider: "serper", key: "s" })?.id).toBe("serper");
    expect(workspaceSearchProvider({ provider: "brave_search", key: "b" })?.id).toBe(
      "brave_search",
    );
    expect(workspaceSearchProvider({ provider: "openai", key: "o" })).toBeNull();

    const server = serverSearchChain({ keys: { parallel: "p" }, searxngUrl: "http://sx" });
    const p = searchProviderFor({ orgId: "o", own, server, cache: new SearchCache() });
    expect(p?.id).toBe("tavily>parallel>searxng");
    expect(searchProviderFor({ orgId: "o", own: null, server: [] })).toBeNull();
    expect(searchProviderFor({ orgId: "o", own: null, server })?.id).toBe("parallel>searxng");

    // The workspace key answers first; a failing one falls back to the server's.
    const mine = fake("mine", 0.005, () => {
      throw new Error("bad key");
    });
    const theirs = fake("server", 0.001, () => [hit("https://s/")]);
    const chosen = searchProviderFor({
      orgId: "o",
      own: mine,
      server: [theirs],
      cache: new SearchCache(),
    });
    expect(await runSearch(chosen as SearchProvider, "q")).toMatchObject({
      providerId: "server",
      costUsd: 0.001,
      serverPaid: true,
    });
    expect(await runSearch(chosen as SearchProvider, "q")).toMatchObject({
      providerId: "cache",
      costUsd: 0,
    });
  });

  it("says which answers the server paid for (D-400)", async () => {
    const mine = fake("mine", 0.005, () => [hit("https://m/")]);
    const theirs = fake("server", 0.001, () => [hit("https://s/")]);
    const own = await runSearch(
      searchProviderFor({ orgId: "o", own: mine, server: [theirs] }) as SearchProvider,
      "q",
    );
    expect(own).toMatchObject({ providerId: "mine", costUsd: 0.005 });
    expect(own.serverPaid).toBeUndefined();
    const server = await runSearch(
      searchProviderFor({ orgId: "o", own: null, server: [theirs] }) as SearchProvider,
      "q",
    );
    expect(server).toMatchObject({ providerId: "server", costUsd: 0.001, serverPaid: true });
  });
});
