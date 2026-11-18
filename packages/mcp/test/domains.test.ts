import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { InMemoryTransport } from "@modelcontextprotocol/sdk/inMemory.js";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { CasamaApi, createCasamaMcpServer } from "../src/server.ts";

const ORG = "44444444-4444-4444-8444-444444444444";
const OTHER = "77777777-7777-4777-8777-777777777777";
const DOMAIN = "66666666-6666-4666-8666-666666666666";

const textOf = (r: unknown) =>
  ((r as { content: Array<{ text: string }> }).content[0] as { text: string }).text;

function fakeApi(calls: string[]) {
  return (async (url: string | URL, init?: RequestInit) => {
    const u = new URL(String(url));
    calls.push(`${init?.method ?? "GET"} ${u.pathname}${u.search}`);
    const p = u.pathname;
    if (p === "/v1/orgs")
      return Response.json({
        items: [
          { id: ORG, name: "Crumb", slug: "crumb", role: "owner" },
          { id: OTHER, name: "Other", slug: "other", role: "member" },
        ],
      });
    if (p === `/v1/orgs/${ORG}/domains` && init?.method === "POST")
      return Response.json(
        { domain: { id: DOMAIN, ...JSON.parse(String(init.body)) } },
        { status: 201 },
      );
    if (p === `/v1/orgs/${ORG}/domains`)
      return Response.json({
        items: [{ id: DOMAIN, name: "bakery.com", state: "live", live: true }],
      });
    if (p === `/v1/orgs/${OTHER}/domains`) return Response.json({ items: [] });
    if (p === `/v1/domains/${DOMAIN}`) return Response.json({ id: DOMAIN, name: "bakery.com" });
    if (p === "/v1/domains/search")
      return Response.json({ items: [{ name: "crumb.com", available: true, price_usd: 16.99 }] });
    return Response.json({ title: "not found" }, { status: 404 });
  }) as typeof fetch;
}

describe("sites and domains tools", () => {
  const calls: string[] = [];
  let client: Client;
  let scoped: Client;

  beforeAll(async () => {
    const api = new CasamaApi({ apiUrl: "https://api.example", token: "t", fetch: fakeApi(calls) });
    const link = async (server: ReturnType<typeof createCasamaMcpServer>) => {
      const [a, b] = InMemoryTransport.createLinkedPair();
      await server.connect(a);
      const c = new Client({ name: "test", version: "1.0.0" });
      await c.connect(b);
      return c;
    };
    client = await link(createCasamaMcpServer(api));
    // Hosted /mcp: the token's workspace only.
    scoped = await link(createCasamaMcpServer(api, { scopeOrgId: OTHER }));
  });
  afterAll(async () => {
    await client?.close();
    await scoped?.close();
  });

  it("lists the tools; none buys", async () => {
    const names = (await client.listTools()).tools.map((t) => t.name);
    expect(names).toEqual(
      expect.arrayContaining([
        "list_sites",
        "list_domains",
        "get_domain",
        "check_domain",
        "connect_domain",
        "search_domains",
      ]),
    );
    expect(names.some((n) => /buy|renew|transfer/.test(n))).toBe(false);
  });

  it("finds a domain by name and reads it", async () => {
    const r = textOf(
      await client.callTool({ name: "get_domain", arguments: { domain: "bakery.com" } }),
    );
    expect(JSON.parse(r)).toMatchObject({ id: DOMAIN });
  });

  it("connects with the page and searches with the query", async () => {
    await client.callTool({
      name: "connect_domain",
      arguments: { name: "bakery.com", page_id: "55555555-5555-4555-8555-555555555555" },
    });
    expect(calls).toContain(`POST /v1/orgs/${ORG}/domains`);
    const s = textOf(
      await client.callTool({ name: "search_domains", arguments: { query: "crumb" } }),
    );
    expect(JSON.parse(s)[0]).toMatchObject({ name: "crumb.com" });
    expect(calls).toContain(`GET /v1/domains/search?org_id=${ORG}&q=crumb`);
  });

  it("a workspace-scoped token can't read another workspace's domain", async () => {
    const r = await scoped.callTool({ name: "get_domain", arguments: { domain: DOMAIN } });
    expect(r.isError).toBe(true);
    expect(textOf(r)).toContain("No domain");
  });
});
