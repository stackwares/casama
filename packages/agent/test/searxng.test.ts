/** SearXNG web search (D-179): the server's free search for workspaces without a key. */
import { describe, expect, it } from "vitest";
import { SearxngSearchProvider } from "../src/search.ts";

describe("SearxngSearchProvider", () => {
  it("asks for JSON, drops duplicate links and keeps the count", async () => {
    let asked = "";
    const fake = (async (url: string) => {
      asked = url;
      return Response.json({
        results: [
          { title: "A", url: "https://a.example/", content: "first" },
          { title: "A again", url: "https://a.example/", content: "dupe" },
          { url: "https://b.example/" },
          { title: "C", url: "https://c.example/", content: "third" },
        ],
      });
    }) as typeof fetch;
    const p = new SearxngSearchProvider("http://searxng:8080/", { fetch: fake });
    expect(p.costUsd).toBe(0);
    expect(await p.search("casama ai", 2)).toEqual([
      { title: "A", url: "https://a.example/", snippet: "first" },
      { title: "https://b.example/", url: "https://b.example/", snippet: "" },
    ]);
    expect(asked).toBe("http://searxng:8080/search?q=casama%20ai&format=json&safesearch=1");
  });

  it("reports an instance that refuses JSON", async () => {
    const fake = (async () => new Response("Forbidden", { status: 403 })) as typeof fetch;
    await expect(new SearxngSearchProvider("http://s").search("x")).rejects.toThrow();
    await expect(
      new SearxngSearchProvider("http://s", { fetch: fake }).search("x"),
    ).rejects.toThrow("SearXNG returned 403");
  });

  it.skipIf(!process.env.SEARXNG_TEST_URL)("searches a real instance", async () => {
    const r = await new SearxngSearchProvider(process.env.SEARXNG_TEST_URL as string).search(
      "casama",
      5,
    );
    expect(r.length).toBeGreaterThan(0);
    expect(r[0]?.url).toMatch(/^https?:\/\//);
  });
});
