import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { InMemoryTransport } from "@modelcontextprotocol/sdk/inMemory.js";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import {
  createCasamaDocsMcpServer,
  type DocsSource,
  RemoteGallery,
  searchGalleryRecords,
  searchWordsFrom,
} from "../src/server.ts";

const FILES: Record<string, unknown> = {
  "index.json": {
    schema: 1,
    items: [
      {
        type: "skill",
        id: "inbox-digest",
        name: "Inbox digest",
        description: "Summarize unread email.",
        tags: ["email"],
        access: { reads: ["email"] },
      },
      { type: "theme", id: "forest-night", name: "Forest night", tags: ["dark", "green"] },
      { type: "skill", id: "old-mail", name: "Old mail digest", retired: true },
    ],
  },
  "routines.json": {
    schema: 1,
    items: [
      {
        type: "routine",
        id: "morning-email",
        name: "Morning email summary",
        description: "Every weekday at 8.",
        needs: { apps: ["gmail"] },
      },
    ],
  },
  "bots.json": { schema: 1, items: [] },
};

function fakeFetch(calls: string[]) {
  return (async (url: string | URL) => {
    const u = String(url);
    calls.push(u);
    const name = u.split("/").pop() as string;
    if (FILES[name]) return Response.json(FILES[name]);
    return new Response("not found", { status: 404 });
  }) as typeof fetch;
}

const noDocs: DocsSource = {
  docs: async () => {
    throw new Error("unused");
  },
  openapi: async () => ({}),
};

const textOf = (r: unknown) =>
  ((r as { content: Array<{ text: string }> }).content[0] as { text: string }).text;

describe("searchGalleryRecords", () => {
  it("ranks by name, skips retired items and filters kinds", () => {
    const items = (FILES["index.json"] as { items: never[] }).items;
    expect(searchGalleryRecords(items, "mail digest").map((i) => i.id)).toEqual(["inbox-digest"]);
    expect(searchGalleryRecords(items, "dark", { types: ["theme"] }).map((i) => i.id)).toEqual([
      "forest-night",
    ]);
  });
});

describe("search words from the gallery (D-372)", () => {
  it("reads lists.json, skips bad words and falls back to its own", async () => {
    expect(
      searchWordsFrom({
        items: [
          {
            type: "list",
            id: "search-words",
            document: { words: { jungle: ["forest", 3], "<x>": ["y"] } },
          },
        ],
      }),
    ).toEqual({ jungle: ["forest"] });
    expect(searchWordsFrom({ items: [] })).toBeUndefined();
    const items = (FILES["index.json"] as { items: never[] }).items;
    const words = { jungle: ["forest"] };
    expect(searchGalleryRecords(items, "jungle", { synonyms: words }).map((i) => i.id)).toEqual([
      "forest-night",
    ]);
    expect(searchGalleryRecords(items, "jungle")).toEqual([]);
    const gallery = new RemoteGallery({
      galleryUrl: "https://g.example",
      fetch: (async () =>
        Response.json({
          schema: 1,
          items: [{ type: "list", id: "search-words", document: { words } }],
        })) as typeof fetch,
    });
    expect(await gallery.searchWords()).toEqual(words);
    const offline = new RemoteGallery({
      galleryUrl: "https://g.example",
      fetch: (async () => new Response("down", { status: 503 })) as typeof fetch,
    });
    expect(await offline.searchWords()).toBeUndefined();
  });
});

describe("gallery_search tool", () => {
  const calls: string[] = [];
  let client: Client;

  beforeAll(async () => {
    const server = createCasamaDocsMcpServer(noDocs, {
      gallery: new RemoteGallery({ galleryUrl: "https://g.example/", fetch: fakeFetch(calls) }),
    });
    const [a, b] = InMemoryTransport.createLinkedPair();
    await server.connect(a);
    client = new Client({ name: "test", version: "1.0.0" });
    await client.connect(b);
  });
  afterAll(async () => client?.close());

  it("is listed, read-only", async () => {
    const { tools } = await client.listTools();
    const g = tools.find((t) => t.name === "gallery_search");
    expect(g?.annotations?.readOnlyHint).toBe(true);
  });

  it("searches every catalog file once and links each item's page", async () => {
    const r = textOf(
      await client.callTool({ name: "gallery_search", arguments: { query: "unread email" } }),
    );
    expect(r).toContain("## Inbox digest (skill/inbox-digest)");
    expect(r).toContain('access: {"reads":["email"]}');
    expect(r).toContain("## Morning email summary (routine/morning-email)");
    expect(r).toContain('needs: {"apps":["gmail"]}');
    expect(r).toContain("page: https://g.example/i/skill/inbox-digest/");
    expect(r).not.toContain("old-mail");
    const n = calls.length;
    await client.callTool({
      name: "gallery_search",
      arguments: { query: "theme", types: ["theme"] },
    });
    expect(calls.length).toBe(n);
    expect(calls.some((c) => c.endsWith("/apps.json"))).toBe(true);
  });

  it("says when nothing matches", async () => {
    const r = textOf(
      await client.callTool({ name: "gallery_search", arguments: { query: "zebra accounting" } }),
    );
    expect(r).toMatch(/Nothing in the gallery matches/);
  });
});
