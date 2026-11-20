import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { InMemoryTransport } from "@modelcontextprotocol/sdk/inMemory.js";
import { describe, expect, it } from "vitest";
import { CasamaApi, createCasamaMcpServer } from "../src/server.ts";

// Connector directories (Claude, ChatGPT) reject tools that don't say whether they only read or can
// change things. Every tool carries a title and an explicit readOnlyHint; tools that write also say
// whether they are destructive, and every tool says whether it reaches outside Casama.
describe("tool annotations", () => {
  it("every tool has a title and explicit hints", async () => {
    const api = new CasamaApi({
      apiUrl: "https://api.example",
      token: "t",
      fetch: (async () => Response.json({})) as typeof fetch,
    });
    const server = createCasamaMcpServer(api, {
      docs: { pages: async () => [], openapi: async () => ({ paths: {} }) } as never,
      gallery: { records: async () => [] } as never,
      checkPlugin: () => ({ ok: true, errors: [], warnings: [] }) as never,
    });
    const [a, b] = InMemoryTransport.createLinkedPair();
    await server.connect(a);
    const client = new Client({ name: "test", version: "1.0.0" });
    await client.connect(b);
    const tools = (await client.listTools()).tools;
    expect(tools.length).toBeGreaterThanOrEqual(20);
    for (const t of tools) {
      const ann = t.annotations ?? {};
      expect(t.title ?? ann.title, `${t.name} title`).toBeTruthy();
      expect(typeof ann.readOnlyHint, `${t.name} readOnlyHint`).toBe("boolean");
      expect(typeof ann.openWorldHint, `${t.name} openWorldHint`).toBe("boolean");
      if (!ann.readOnlyHint)
        expect(typeof ann.destructiveHint, `${t.name} destructiveHint`).toBe("boolean");
    }
    const byName = Object.fromEntries(tools.map((t) => [t.name, t.annotations]));
    expect(byName.ask_bot?.destructiveHint).toBe(true);
    expect(byName.decide_approval?.destructiveHint).toBe(true);
    expect(byName.list_bots?.readOnlyHint).toBe(true);
    await client.close();
  });
});
