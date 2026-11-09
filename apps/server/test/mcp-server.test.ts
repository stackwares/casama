import { fileURLToPath } from "node:url";
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { InMemoryTransport } from "@modelcontextprotocol/sdk/inMemory.js";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { createKasamaMcpServer, KasamaApi } from "../../../packages/mcp/src/server.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = fileURLToPath(new URL("./fixtures/chat.json", import.meta.url));

/** The Kasama MCP server (Phase 8, D-077) driven by a real MCP client over the test API. */
describe("Kasama MCP server", () => {
  let h: Harness;
  let client: Client;

  beforeAll(async () => {
    h = await startHarness({ worker: { fixtures: FIXTURES } });
    const u = await h.user("mcp-user@example.com");
    const org = await j(
      await h.request("/v1/orgs", { method: "POST", token: u.token, json: { name: "MCP Lab" } }),
    );
    const cred = await j(
      await h.request("/v1/credentials", {
        method: "POST",
        token: u.token,
        json: { org_id: org.id, provider: "openrouter", label: "k", api_key: "sk-mcp-key" },
      }),
    );
    await h.request("/v1/bots", {
      method: "POST",
      token: u.token,
      json: {
        org_id: org.id,
        name: "Helper",
        model_policy: { primary: { credential_id: cred.id, model: "fixture-main" } },
      },
    });
    const api = new KasamaApi({
      apiUrl: "http://kasama.test",
      token: u.token,
      fetch: (async (url: string, init?: RequestInit) =>
        h.app.request(String(url).replace("http://kasama.test", ""), init)) as typeof fetch,
    });
    const [a, b] = InMemoryTransport.createLinkedPair();
    await createKasamaMcpServer(api, { pollMs: 100 }).connect(a);
    client = new Client({ name: "test", version: "1.0.0" });
    await client.connect(b);
  }, 180_000);
  afterAll(async () => {
    await client?.close();
    await h?.stop();
  });

  const call = async (name: string, args: Record<string, unknown> = {}) => {
    const r = (await client.callTool({ name, arguments: args })) as {
      content: Array<{ text: string }>;
      isError?: boolean;
    };
    return { text: r.content.map((c) => c.text).join(""), isError: r.isError };
  };

  it("lists its tools", async () => {
    const tools = (await client.listTools()).tools.map((t) => t.name).sort();
    expect(tools).toEqual([
      "ask_bot",
      "decide_approval",
      "get_run",
      "list_approvals",
      "list_bots",
      "list_workspaces",
    ]);
  });

  it("lists workspaces and bots", async () => {
    expect((await call("list_workspaces")).text).toContain("MCP Lab");
    expect(JSON.parse((await call("list_bots")).text)[0]).toMatchObject({ name: "Helper" });
  });

  it("asks a bot and waits for the reply, then reads the run", async () => {
    const r = await call("ask_bot", { bot: "helper", message: "Hi there" });
    expect(r.text).toContain("Hello! How can I help?");
    expect(r.text).toContain("status: completed");
    const runId = /run_id: (\S+)/.exec(r.text)?.[1];
    const run = JSON.parse((await call("get_run", { run_id: runId })).text);
    expect(run.run.status).toBe("completed");
    expect(run.events.some((e: { type: string }) => e.type === "run.completed")).toBe(true);
  }, 60_000);

  it("reports unknown bots helpfully", async () => {
    const r = await call("ask_bot", { bot: "Nobody", message: "x" });
    expect(r.isError).toBe(true);
    expect(r.text).toContain("Bots: Helper");
  });
});
