import type { Server } from "node:http";
import type { AddressInfo } from "node:net";
import { VERSION } from "@casama/mcp";
import { serve } from "@hono/node-server";
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StreamableHTTPClientTransport } from "@modelcontextprotocol/sdk/client/streamableHttp.js";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, startHarness } from "./helpers.ts";

/** /mcp/docs: the docs tools for anyone building on Casama, with no sign-in. */
describe("docs MCP endpoint", () => {
  let h: Harness;
  let server: Server;
  let client: Client;
  let serverBase = "";

  const textOf = (r: unknown) =>
    (r as { content: Array<{ text: string }> }).content.map((c) => c.text).join("\n");

  beforeAll(async () => {
    // A gallery address (never fetched here) so gallery_search is offered (D-315).
    h = await startHarness({ env: { GALLERY_URL: "http://127.0.0.1:9" } });
    server = serve({ fetch: h.app.fetch, port: 0 }) as unknown as Server;
    await new Promise((r) => server.once("listening", r));
    const base = `http://127.0.0.1:${(server.address() as AddressInfo).port}`;
    serverBase = base;
    client = new Client({ name: "agent", version: "1.0.0" });
    await client.connect(new StreamableHTTPClientTransport(new URL(`${base}/mcp/docs`)));
  }, 180_000);
  afterAll(async () => {
    await client?.close();
    server?.close();
    await h?.stop();
  });

  it("serves the docs tools without a token, and no account tools", async () => {
    const names = (await client.listTools()).tools.map((t) => t.name).sort();
    expect(names).toEqual([
      "gallery_search",
      "get_api_operation",
      "list_doc_pages",
      "read_doc",
      "search_docs",
    ]);
  });

  it("answers /server-card with the MCP server card, no sign-in", async () => {
    const res = await fetch(`${serverBase}/mcp/docs/server-card`, {
      headers: { origin: "https://x.example" },
    });
    expect(res.status).toBe(200);
    expect(res.headers.get("content-type")).toContain("application/json");
    expect(res.headers.get("cache-control")).toContain("max-age");
    expect(res.headers.get("access-control-allow-origin")).toBe("*");
    const card = (await res.json()) as {
      name: string;
      version: string;
      remotes: Array<{ url: string; type: string }>;
    };
    expect(card.name).toBe("ai.casama/docs");
    expect(card.version).toBe(VERSION);
    expect(card.remotes).toEqual([{ type: "streamable-http", url: `${serverBase}/mcp/docs` }]);
  });

  it("searches and reads the docs shipped with the server", async () => {
    const hits = textOf(
      await client.callTool({ name: "search_docs", arguments: { query: "plugin secrets" } }),
    );
    expect(hits).toContain("/develop/plugins");
    const page = textOf(
      await client.callTool({ name: "read_doc", arguments: { page: "/develop/plugins" } }),
    );
    expect(page).toContain("# Plugins");
  });

  it("looks up operations in this server's OpenAPI document", async () => {
    const op = textOf(
      await client.callTool({
        name: "get_api_operation",
        arguments: { query: "POST /v1/conversations/abc/messages" },
      }),
    );
    expect(op).toContain("operationId: sendMessage");
    expect(op).toContain("run_id");
  });

  it("leaves /mcp itself behind sign-in", async () => {
    const res = await h.request("/mcp", { method: "POST", json: {} });
    expect(res.status).toBe(401);
  });
});
