import { readFileSync } from "node:fs";
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { InMemoryTransport } from "@modelcontextprotocol/sdk/inMemory.js";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { createCasamaDocsMcpServer, findOperations, RemoteDocs, typeOf } from "../src/server.ts";

const OPENAPI = JSON.parse(
  readFileSync(new URL("../../contracts/openapi.json", import.meta.url), "utf8"),
);
const LLMS_FULL = `<!-- page: https://docs.casama.ai/ -->
---
layout: home
title: Casama
---

<!-- page: https://docs.casama.ai/develop/plugins -->
# Plugins

A plugin gives a bot new skills and new tools in one install, in the Agent Plugins format.

## Secrets

Declare secrets under the com.casama extension so people are asked for them when they install.

## Limits

A plugin can have at most a few hundred files, and Casama never runs npm install for you.

<!-- page: https://docs.casama.ai/self-hosting/ -->
# Self-hosting

Casama runs on your own hardware with one install script and Docker Compose.
`;

function fakeFetch(calls: string[]) {
  return (async (url: string | URL) => {
    const u = String(url);
    calls.push(u);
    if (u.endsWith("/llms-full.txt")) return new Response(LLMS_FULL);
    if (u.endsWith("/api/openapi.json")) return Response.json(OPENAPI);
    return new Response("not found", { status: 404 });
  }) as typeof fetch;
}

const textOf = (r: unknown) =>
  ((r as { content: Array<{ text: string }> }).content[0] as { text: string }).text;

describe("docs tools", () => {
  const calls: string[] = [];
  let client: Client;

  beforeAll(async () => {
    const docs = new RemoteDocs({ fetch: fakeFetch(calls) });
    const server = createCasamaDocsMcpServer(docs, {
      checkPlugin: (dir) => ({
        ok: dir === "good",
        errors: dir === "good" ? [] : ["plugin.json is missing"],
        warnings: [],
        tips: [],
        skills: [],
        files: 1,
        bytes: 10,
      }),
    });
    const [a, b] = InMemoryTransport.createLinkedPair();
    await server.connect(a);
    client = new Client({ name: "test", version: "1.0.0" });
    await client.connect(b);
  });
  afterAll(async () => client?.close());

  it("lists the docs tools, read-only", async () => {
    const { tools } = await client.listTools();
    expect(tools.map((t) => t.name).sort()).toEqual([
      "check_plugin",
      "get_api_operation",
      "list_doc_pages",
      "read_doc",
      "search_docs",
    ]);
    expect(tools.every((t) => t.annotations?.readOnlyHint)).toBe(true);
  });

  it("searches sections and fetches the docs once", async () => {
    const r = textOf(
      await client.callTool({ name: "search_docs", arguments: { query: "plugin secrets" } }),
    );
    expect(r).toContain("Plugins › Secrets");
    expect(r).toContain("https://docs.casama.ai/develop/plugins#secrets");
    await client.callTool({ name: "search_docs", arguments: { query: "npm install" } });
    expect(calls.filter((c) => c.endsWith("llms-full.txt"))).toHaveLength(1);
  });

  it("reads a page by any form of its address, or one section", async () => {
    for (const page of [
      "/develop/plugins",
      "develop/plugins.md",
      "https://docs.casama.ai/develop/plugins#limits",
    ]) {
      const r = textOf(await client.callTool({ name: "read_doc", arguments: { page } }));
      expect(r).toContain("# Plugins");
      expect(r).toContain("markdown: https://docs.casama.ai/develop/plugins.md");
    }
    const folder = textOf(
      await client.callTool({ name: "read_doc", arguments: { page: "/self-hosting/index.md" } }),
    );
    expect(folder).toContain("# Self-hosting");
    const one = textOf(
      await client.callTool({
        name: "read_doc",
        arguments: { page: "/develop/plugins", section: "limits" },
      }),
    );
    expect(one).toContain("npm install");
    expect(one).not.toContain("com.casama");
    const missing = textOf(
      await client.callTool({ name: "read_doc", arguments: { page: "/develop/plugin-secrets" } }),
    );
    expect(missing).toContain("No page");
    expect(missing).toContain("Plugins");
  });

  it("looks up API operations by id, path or keywords", async () => {
    const byPath = textOf(
      await client.callTool({ name: "get_api_operation", arguments: { query: "GET /readyz" } }),
    );
    expect(byPath).toContain("## GET /readyz");
    expect(byPath).toContain("operationId: readyz");
    const kw = textOf(
      await client.callTool({ name: "get_api_operation", arguments: { query: "create bot" } }),
    );
    expect(kw).toMatch(/## POST \/v1\/bots\b/);
    expect(kw).toContain("Request body");
  });

  it("checks a plugin when a checker is given", async () => {
    const bad = textOf(await client.callTool({ name: "check_plugin", arguments: { path: "bad" } }));
    expect(bad).toContain("plugin.json is missing");
    expect(bad).toContain("Not installable");
    const good = textOf(
      await client.callTool({ name: "check_plugin", arguments: { path: "good" } }),
    );
    expect(good).toContain("Ready to install");
  });
});

describe("OpenAPI helpers", () => {
  it("matches concrete paths to templates", () => {
    const path = Object.keys(OPENAPI.paths).find((p) => /\{[^}]+\}/.test(p)) as string;
    const concrete = path.replace(/\{[^}]+\}/g, "00000000-0000-0000-0000-000000000000");
    const ops = findOperations(OPENAPI, concrete);
    expect(ops.length).toBeGreaterThan(0);
    expect(ops.every((o) => o.path === path)).toBe(true);
  });

  it("renders schemas as compact types", () => {
    const doc = {
      components: {
        schemas: {
          Bot: { type: "object", properties: { id: { type: "string" } }, required: ["id"] },
        },
      },
    };
    expect(
      typeOf(doc, {
        type: "object",
        required: ["bot"],
        properties: {
          bot: { $ref: "#/components/schemas/Bot" },
          tags: { type: "array", items: { type: "string" } },
          mode: { enum: ["a", "b"] },
          note: { type: ["string", "null"] },
        },
      }),
    ).toBe(
      '{\n  bot: {\n    id: string;\n  };\n  tags?: Array<string>;\n  mode?: "a" | "b";\n  note?: string | null;\n}',
    );
  });
});

describe("RemoteDocs", () => {
  it("keeps the last good copy when a refresh fails", async () => {
    let now = 0;
    let up = true;
    const docs = new RemoteDocs({
      now: () => now,
      fetch: (async (url: string) =>
        up
          ? new Response(String(url).endsWith(".txt") ? LLMS_FULL : "{}")
          : new Response("down", { status: 503 })) as typeof fetch,
    });
    expect((await docs.docs()).pages).toHaveLength(3);
    up = false;
    now = 4_000_000;
    expect((await docs.docs()).pages).toHaveLength(3);
  });

  it("throws when nothing was ever loaded", async () => {
    const docs = new RemoteDocs({
      fetch: (async () => new Response("down", { status: 503 })) as typeof fetch,
    });
    await expect(docs.docs()).rejects.toThrow(/HTTP 503/);
  });
});
