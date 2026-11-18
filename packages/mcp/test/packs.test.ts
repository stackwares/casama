import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { InMemoryTransport } from "@modelcontextprotocol/sdk/inMemory.js";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { CasamaApi, createCasamaMcpServer } from "../src/server.ts";

const ORG = "44444444-4444-4444-8444-444444444444";
const C = "a".repeat(40);

describe("pack tools", () => {
  const calls: Array<{ path: string; body: unknown }> = [];
  let client: Client;

  beforeAll(async () => {
    const fetchImpl = (async (url: string | URL, init?: RequestInit) => {
      const u = new URL(String(url));
      const body = init?.body ? JSON.parse(String(init.body)) : null;
      calls.push({ path: `${init?.method ?? "GET"} ${u.pathname}${u.search}`, body });
      if (u.pathname === "/v1/orgs")
        return Response.json({ items: [{ id: ORG, name: "Crumb", slug: "crumb", role: "owner" }] });
      if (u.pathname === "/v1/packs" && init?.method === "POST")
        return Response.json({ status: "installed", items: [] }, { status: 201 });
      if (u.pathname === "/v1/packs") return Response.json({ items: [{ name: "hello-pack" }] });
      if (u.pathname === "/v1/packs/preview")
        return Response.json({ name: "hello-pack", commit: C });
      return Response.json({ title: "not found" }, { status: 404 });
    }) as typeof fetch;
    const api = new CasamaApi({ apiUrl: "https://api.example", token: "t", fetch: fetchImpl });
    const server = createCasamaMcpServer(api);
    const [a, b] = InMemoryTransport.createLinkedPair();
    await server.connect(a);
    client = new Client({ name: "test", version: "1.0.0" });
    await client.connect(b);
  });
  afterAll(async () => client?.close());

  it("lists, previews and installs packs, with no secrets over MCP", async () => {
    const tools = (await client.listTools()).tools;
    expect(tools.map((t) => t.name)).toEqual(
      expect.arrayContaining(["list_packs", "preview_pack", "install_pack"]),
    );
    const install = tools.find((t) => t.name === "install_pack");
    expect(Object.keys(install?.inputSchema.properties ?? {})).not.toContain("secrets");
    await client.callTool({ name: "list_packs", arguments: {} });
    expect(calls.at(-1)?.path).toBe(`GET /v1/packs?org_id=${ORG}`);
    await client.callTool({
      name: "preview_pack",
      arguments: { url: "https://github.com/acme/packs" },
    });
    expect(calls.at(-1)?.body).toEqual({ org_id: ORG, url: "https://github.com/acme/packs" });
    await client.callTool({
      name: "install_pack",
      arguments: { url: "https://github.com/acme/packs", commit: C, inputs: { team: "Crumb" } },
    });
    expect(calls.at(-1)).toEqual({
      path: "POST /v1/packs",
      body: {
        org_id: ORG,
        url: "https://github.com/acme/packs",
        commit: C,
        inputs: { team: "Crumb" },
      },
    });
  });
});
