/** web.fetch (D-384): readable text from a page, capped, through the egress guard. */
import { describe, expect, it } from "vitest";
import { createSafeFetch } from "../src/safe-fetch.ts";
import type { SearchProvider } from "../src/search.ts";
import { registerAutonomyTools, WEB_FETCH_DEFAULT_CHARS } from "../src/tools/autonomy.ts";
import { ToolRegistry } from "../src/tools/registry.ts";
import { htmlToReadable } from "../src/web-read.ts";

const ctx = {
  runId: "00000000-0000-4000-8000-000000000001",
  botId: "00000000-0000-4000-8000-000000000002",
  orgId: "00000000-0000-4000-8000-000000000003",
};

function tools(
  fetchImpl: typeof fetch,
  extra: { searchFor?: () => Promise<SearchProvider | null> } = {},
) {
  const rows: unknown[] = [];
  const db = { execute: async (q: unknown) => (rows.push(q), []) } as never;
  const registry = new ToolRegistry();
  registerAutonomyTools(registry, { db, fetch: fetchImpl, searchFor: extra.searchFor });
  const run = async (name: string, args: unknown) => {
    const parsed = registry.parse(name, args).args as never;
    return registry.get(name)!.execute(parsed, ctx as never);
  };
  return { registry, run, rows };
}

const answer = (body: string, headers: Record<string, string>, status = 200) =>
  (async () => new Response(body, { status, headers })) as unknown as typeof fetch;

const PAGE = `<!doctype html><html><head><title>Opening hours &amp; prices</title>
<meta name="description" content="When we&#39;re open">
<style>body{color:red}</style><script>alert("x")</script></head>
<body><nav><a href="/">Home</a><a href="/shop">Shop</a></nav>
<header><h1>Site banner</h1></header>
<main><article><h1>Opening hours</h1>
<p>We are open <strong>Monday to Friday</strong>, 9:00&ndash;17:00. ${"Long text. ".repeat(60)}</p>
<ul><li>Saturday: 10:00</li><li>Sunday: closed</li></ul>
<p>See <a href="/prices?x=1">the price list</a> or <a href="#top">top</a>.</p>
<pre>line 1
  line 2</pre>
<div role="navigation">Skip me</div>
</article></main>
<footer>© 2026 Shop Ltd · Cookie settings</footer>
<form><input name="q"><button>Search</button></form></body></html>`;

describe("htmlToReadable", () => {
  it("keeps the title and main content and drops scripts, styles, menus and footers", () => {
    const r = htmlToReadable(PAGE, "https://shop.example/hours");
    expect(r.title).toBe("Opening hours & prices");
    expect(r.description).toBe("When we're open");
    expect(r.text).toContain("# Opening hours");
    expect(r.text).toContain("**Monday to Friday**, 9:00–17:00");
    expect(r.text).toContain("- Saturday: 10:00\n- Sunday: closed");
    expect(r.text).toContain("[the price list](https://shop.example/prices?x=1)");
    expect(r.text).toContain("```\nline 1\n  line 2\n```");
    expect(r.text).toContain(" top");
    for (const gone of [
      "alert",
      "color:red",
      "Home",
      "Site banner",
      "Cookie settings",
      "Skip me",
      "Search",
    ])
      expect(r.text, gone).not.toContain(gone);
  });

  it("uses the whole body when there is no main part", () => {
    const r = htmlToReadable(
      "<html><body><div><p>Hello <b>there</b></p><p>Bye</p></div></body></html>",
    );
    expect(r.text).toBe("Hello **there**\n\nBye");
  });
});

describe("web.fetch", () => {
  it("returns readable text, wrapped as untrusted, with the page's title", async () => {
    const { run, registry } = tools(answer(PAGE, { "content-type": "text/html; charset=utf-8" }));
    const def = registry.get("web.fetch")!;
    expect(def.readOnly).toBe(true);
    expect(def.untrustedOutput).toBe(true);
    expect(def.risk).toBe("low");
    const r = await run("web.fetch", { url: "https://shop.example/hours" });
    expect(r.content).toMatch(/^<untrusted source="web">/);
    expect(r.content).toContain("URL: https://shop.example/hours\nTitle: Opening hours & prices");
    expect(r.content).toContain("HTTP 200, text/html; charset=utf-8");
    expect(r.content).not.toContain("<script");
    expect(r.preview).toBe("Opening hours & prices");
  });

  it("caps the text and says where to read on", async () => {
    const long = `<html><body><main>${"<p>abcdefghij</p>".repeat(5000)}</main></body></html>`;
    const { run } = tools(answer(long, { "content-type": "text/html" }));
    const first = await run("web.fetch", { url: "https://x.example/" });
    expect(first.content).toContain(`Cut at character ${WEB_FETCH_DEFAULT_CHARS} of`);
    const small = await run("web.fetch", {
      url: "https://x.example/",
      max_chars: 500,
      start: 1000,
    });
    expect(small.content).toContain("Call web.fetch again with start=1500");
    const { registry } = tools(answer("", {}));
    expect(() =>
      registry.parse("web.fetch", { url: "https://x.example/", max_chars: 100_001 }),
    ).toThrow();
  });

  it("passes plain text and JSON through and describes PDFs instead of reading them", async () => {
    const json = await tools(answer('{"ok":true}', { "content-type": "application/json" })).run(
      "web.fetch",
      {
        url: "https://api.example/x",
      },
    );
    expect(json.content).toContain('{"ok":true}');
    const pdf = await tools(
      answer("%PDF-1.7 binary", { "content-type": "application/pdf", "content-length": "1234" }),
    ).run("web.fetch", { url: "https://x.example/a.pdf" });
    expect(pdf.content).toContain("This link is a PDF (1234 bytes)");
    expect(pdf.content).not.toContain("%PDF");
  });

  it("follows redirects through the same fetch, at most five", async () => {
    const asked: string[] = [];
    const hop = (async (url: string) => {
      asked.push(url);
      return url.endsWith("/final")
        ? new Response("<html><body><p>Arrived</p></body></html>", {
            headers: { "content-type": "text/html" },
          })
        : new Response(null, { status: 302, headers: { location: "/final" } });
    }) as typeof fetch;
    const r = await tools(hop).run("web.fetch", { url: "https://x.example/start" });
    expect(asked).toEqual(["https://x.example/start", "https://x.example/final"]);
    expect(r.content).toContain("URL: https://x.example/final");
    expect(r.content).toContain("Arrived");
    const loop = (async () =>
      new Response(null, {
        status: 301,
        headers: { location: "/again" },
      })) as unknown as typeof fetch;
    await expect(tools(loop).run("web.fetch", { url: "https://x.example/" })).rejects.toThrow(
      /too many times/,
    );
  });

  it("refuses private and internal addresses, also after a redirect", async () => {
    const { run } = tools(createSafeFetch());
    for (const url of [
      "http://127.0.0.1:8080/",
      "http://169.254.169.254/latest/meta-data/",
      "http://[::1]/",
      "http://10.0.0.5/",
    ])
      await expect(run("web.fetch", { url }), url).rejects.toMatchObject({
        code: "blocked_address",
      });
    const safe = createSafeFetch();
    const redirecting = (async (url: string, init?: RequestInit) =>
      url.startsWith("https://public.example")
        ? new Response(null, { status: 302, headers: { location: "http://127.0.0.1/admin" } })
        : safe(url, init)) as typeof fetch;
    await expect(
      tools(redirecting).run("web.fetch", { url: "https://public.example/" }),
    ).rejects.toMatchObject({
      code: "blocked_address",
    });
  });
});

describe("web.search", () => {
  it("records the answering provider's cost, and 0 for a cached answer", async () => {
    const { CachedSearchProvider, SearchCache } = await import("../src/search.ts");
    const inner: SearchProvider = {
      id: "serper",
      costUsd: 0.001,
      search: async () => [{ title: "T", url: "https://t.example/", snippet: "s" }],
    };
    const cached = new CachedSearchProvider(inner, new SearchCache(), ctx.orgId);
    const { run, rows } = tools(answer("", {}), { searchFor: async () => cached });
    const first = await run("web.search", { query: "x" });
    expect(first.content).toContain("https://t.example/");
    await run("web.search", { query: "X " });
    const params = rows.map((q) => JSON.stringify((q as { queryChunks: unknown[] }).queryChunks));
    expect(params[0]).toContain("0.001");
    expect(params[0]).toContain('{\\"provider\\":\\"serper\\"}');
    expect(params[1]).toContain('\\"cached\\":true');
  });

  it("explains how to set search up when nothing is configured", async () => {
    const { run } = tools(answer("", {}), { searchFor: async () => null });
    await expect(run("web.search", { query: "x" })).rejects.toThrow(/SearXNG/);
  });
});
