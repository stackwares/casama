/**
 * Cards for a plugin's tools (D-345): a plugin installed from GitHub ships
 * com.casama/cards/<tool>.json, its stdio server runs on the (fake) bot's computer, and a run
 * that calls the tool shows the filled card, or keeps the text when `when` doesn't match or the
 * card doesn't fill.
 */
import { once } from "node:events";
import { createServer, type IncomingMessage, type Server } from "node:http";
import type { AddressInfo } from "node:net";
import { fileURLToPath } from "node:url";
import {
  builtinTools,
  CredentialResolver,
  directSteps,
  type FixtureFile,
  forgetPluginSync,
  hashEmbedder,
  PLUGIN_CARD_SHOWN,
  PostgresMemoryStore,
  ReplayGateway,
  runAgent,
} from "@casama/agent";
import type { ExecChunk, McpServerSpec } from "@casama/sandbox";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp.js";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { z } from "zod";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = fileURLToPath(new URL("./fixtures/watchers.json", import.meta.url));
const C1 = "c".repeat(40);
let services: Server;
let servicesUrl = "";

const files: Record<string, string> = {
  "plugin.json": JSON.stringify({
    $schema: "https://agent-plugins.org/schemas/1.0.0/plugin.schema.json",
    name: "shop",
    version: "1.0.0",
    description: "Orders and events",
  }),
  "mcp.json": JSON.stringify({
    $schema: "https://agent-plugins.org/schemas/1.0.0/mcp.schema.json",
    mcpServers: { orders: { type: "stdio", command: "./bin/orders" } },
  }),
  "bin/orders": "#!/bin/sh\nexec node server.js\n",
  // A card from structured content, with an each row and a when.
  "com.casama/cards/get_order.json": JSON.stringify({
    format: 1,
    card: "Details",
    title: "Order {{result.id}}",
    rows: [
      { label: "Status", value: "{{result.status}}" },
      { each: "result.lines", label: "{{item.name}}", value: "{{item.qty}} × {{item.price}}" },
    ],
    footer: "Total {{result.total}}",
    when: "result.id",
  }),
  // Passes the checker, but the tool's start time isn't ISO, so the filled card fails ui.show's check.
  "com.casama/cards/next_event.json": JSON.stringify({
    format: 1,
    card: "Event",
    title: "{{result.title}}",
    start: "{{result.start}}",
    actions: false,
  }),
};
const tree = Object.entries(files).map(([path, text]) => ({
  path: `plugins/shop/${path}`,
  type: "blob",
  sha: Buffer.from(path).toString("hex"),
  size: text.length,
  mode: path.startsWith("bin/") ? "100755" : "100644",
}));

/** The plugin's server: get_order answers with structured content, next_event with JSON text. */
const mcpServer = () => {
  const server = new McpServer({ name: "orders", version: "1.0.0" });
  server.registerTool(
    "get_order",
    {
      description: "One order",
      inputSchema: { id: z.string() },
      annotations: { readOnlyHint: true },
    },
    async ({ id }) =>
      id === "none"
        ? { content: [{ type: "text", text: "No such order." }], structuredContent: {} }
        : {
            content: [{ type: "text", text: `Order ${id}: shipped, 2 lines, total $42.00` }],
            structuredContent: {
              id,
              status: "shipped",
              total: "$42.00",
              lines: [
                { name: "Mug", qty: 2, price: "$12.00" },
                { name: "Tea", qty: 1, price: "$18.00" },
              ],
            },
          },
  );
  server.registerTool(
    "next_event",
    { description: "The next event", inputSchema: {}, annotations: { readOnlyHint: true } },
    async () => ({
      content: [{ type: "text", text: JSON.stringify({ title: "Lunch", start: "soon" }) }],
    }),
  );
  return server;
};

const computer = {
  servers: {} as Record<string, McpServerSpec>,
  files: new Map<string, Uint8Array>(),
};
const handle = {
  ref: "fake-computer",
  async *exec(cmd: string): AsyncIterable<ExecChunk> {
    yield { type: "stdout", data: cmd.startsWith("printf") ? "/home/casama" : "" };
    yield { type: "exit", code: 0, timedOut: false, killed: false, truncated: false };
  },
  readFile: async (p: string) => {
    const f = computer.files.get(p);
    if (!f) throw new Error("not found");
    return f;
  },
  writeFile: async (p: string, d: Uint8Array) => void computer.files.set(p, d),
  setMcpServers: async (s: Record<string, McpServerSpec>) => void (computer.servers = s),
  mcpFetch: (key: string, init: RequestInit) => fetch(`${servicesUrl}/stdio/${key}`, init),
};

let h: Harness;
let owner: { id: string; token: string };
let orgId: string;
let botId: string;
let computerId: string;
let tool: { order: string; event: string };

beforeAll(async () => {
  services = createServer(async (req: IncomingMessage, res) => {
    const chunks: Buffer[] = [];
    for await (const c of req) chunks.push(c as Buffer);
    const raw = Buffer.concat(chunks).toString();
    const url = new URL(req.url ?? "/", "http://x");
    const send = (v: unknown, status = 200) =>
      res.writeHead(status, { "content-type": "application/json" }).end(JSON.stringify(v));
    if (url.pathname === "/repos/acme/shop-plugin") return send({ default_branch: "main" });
    if (url.pathname === "/repos/acme/shop-plugin/commits/main") return send({ sha: C1 });
    if (url.pathname === `/repos/acme/shop-plugin/git/trees/${C1}`)
      return send({ tree, truncated: false });
    const b = /^\/repos\/acme\/shop-plugin\/git\/blobs\/(\w+)$/.exec(url.pathname);
    if (b?.[1]) {
      const text = files[Buffer.from(b[1], "hex").toString()];
      if (text !== undefined)
        return send({ content: Buffer.from(text).toString("base64"), encoding: "base64" });
    }
    if (url.pathname.startsWith("/stdio/")) {
      const transport = new StreamableHTTPServerTransport({ sessionIdGenerator: undefined });
      res.on("close", () => void transport.close());
      await mcpServer().connect(transport);
      return transport.handleRequest(req, res, raw ? JSON.parse(raw) : undefined);
    }
    send({}, 404);
  }).listen(0, "127.0.0.1");
  await once(services, "listening");
  servicesUrl = `http://127.0.0.1:${(services.address() as AddressInfo).port}`;
  h = await startHarness({
    env: { GITHUB_API_URL: servicesUrl },
    worker: { fixtures: FIXTURES, egressExemptCidrs: ["127.0.0.0/8"] },
  });
  (h.deps as { computers?: unknown }).computers = {
    ensureRunning: async () => handle,
    byId: async () => ({ state: "running" }),
  };
  owner = await h.user("cards@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "C" } }),
    )
  ).id;
  const cred = await j(
    await h.request("/v1/credentials", {
      method: "POST",
      token: owner.token,
      json: { org_id: orgId, provider: "openrouter", label: "k", api_key: "sk-or-v1-abcdefabcdef" },
    }),
  );
  botId = (
    await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: owner.token,
        json: {
          org_id: orgId,
          name: "Shopper",
          model_policy: { primary: { credential_id: cred.id, model: "fixture-primary" } },
        },
      }),
    )
  ).id;
  const [c] = await h.tdb.admin<{ id: string }[]>`
    insert into public.computers (org_id, kind, owner_bot_id, name, provider)
    values (${orgId}, 'private', ${botId}, 'Shopper computer', 'e2b') returning id`;
  computerId = c!.id;
}, 60_000);
afterAll(async () => {
  await h?.stop();
  services?.close();
});

const runDeps = (fixtures: FixtureFile[]) => {
  const embedder = hashEmbedder();
  return {
    db: h.handle.db,
    gateway: new ReplayGateway(fixtures),
    tools: builtinTools({
      db: h.handle.db,
      memory: async () => new PostgresMemoryStore(h.handle.db, embedder),
    }),
    credentials: new CredentialResolver(h.handle.db),
    embedderFor: async () => embedder,
    step: directSteps,
    deltaIntervalMs: 20,
    cancelPollMs: 50,
    fallback: { backoffMs: 1 },
    computers: {
      forBot: async () => ({ id: computerId, org_id: orgId, kind: "private" }),
      ensureRunning: async () => handle,
      touch: async () => {},
    } as never,
  };
};

const finish = () => ({
  type: "finish" as const,
  usage: { inputTokens: 1000, outputTokens: 100 },
  finishReason: "stop",
  model: "",
});

/** One request: the model calls `name` with `args`, then says CARD or TEXT by what it was told. */
const fixturesFor = (ask: string, name: string, args: Record<string, unknown>): FixtureFile[] => [
  {
    name: "plugin-cards",
    turns: [
      {
        when: { lastUserIncludes: ask, lastRole: "user" },
        events: [{ type: "tool_call", call: { callId: "c1", name, args } }, finish()],
      },
      {
        when: { lastRole: "tool", lastToolResultIncludes: "Shown to the person as a card" },
        events: [{ type: "text", text: "CARD" }, finish()],
      },
      { when: { lastRole: "tool" }, events: [{ type: "text", text: "TEXT" }, finish()] },
    ],
  },
];

async function run(ask: string, name: string, args: Record<string, unknown> = {}) {
  const [convo] = await h.tdb.admin<{ id: string }[]>`
    insert into public.conversations (org_id, bot_id) values (${orgId}, ${botId}) returning id`;
  const [r] = await h.tdb.admin<{ id: string }[]>`
    insert into public.runs (org_id, bot_id, conversation_id, created_by)
    values (${orgId}, ${botId}, ${convo!.id}, ${owner.id}) returning id`;
  await h.tdb.admin`
    insert into public.messages (org_id, conversation_id, role, author_user_id, content, run_id)
    values (${orgId}, ${convo!.id}, 'user', ${owner.id}, ${h.tdb.admin.json([{ type: "text", text: ask }])}, ${r!.id})`;
  forgetPluginSync();
  const out = await runAgent(r!.id, runDeps(fixturesFor(ask, name, args)) as never);
  const events = await h.tdb.admin<{ type: string; payload: Record<string, unknown> }[]>`
    select type, payload from public.run_events where run_id = ${r!.id} order by seq`;
  const [reply] = await h.tdb.admin<{ content: Array<Record<string, unknown>> }[]>`
    select content from public.messages
    where conversation_id = ${convo!.id} and role = 'assistant' order by created_at desc limit 1`;
  return { status: out.status, events, reply: reply?.content ?? [] };
}

describe("plugin cards", () => {
  it("installs the plugin with its cards kept in the summary", async () => {
    const res = await h.request("/v1/plugins", {
      method: "POST",
      token: owner.token,
      json: {
        org_id: orgId,
        bot_id: botId,
        url: "https://github.com/acme/shop-plugin/tree/main/plugins/shop",
        commit: C1,
      },
    });
    const p = await j(res);
    expect(res.status, JSON.stringify(p)).toBe(201);
    expect(p.servers[0]).toMatchObject({ status: "ok" });
    const [row] = await h.tdb.admin<
      { summary: { cards: Array<{ tool: string; card: string }> } }[]
    >`
      select summary from public.plugins where id = ${p.id}`;
    expect(row?.summary.cards.map((c) => `${c.tool}:${c.card}`)).toEqual([
      "get_order:Details",
      "next_event:Event",
    ]);
    // The card files aren't copied to the computer: they're Casama's, not the server's.
    expect([...computer.files.keys()].some((k) => k.includes("com.casama"))).toBe(false);
    const [i] = await h.tdb.admin<{ name: string }[]>`
      select name from public.integrations where plugin_id = ${p.id}`;
    tool = {
      order: `computer_mcp.${i!.name}.get_order`,
      event: `computer_mcp.${i!.name}.next_event`,
    };
  });

  it("shows the filled card, and the model is told so", async () => {
    const r = await run("show order 7", tool.order, { id: "A-7" });
    expect(r.status).toBe("completed");
    const shown = r.events.filter((e) => e.type === "ui.shown");
    expect(shown).toHaveLength(1);
    expect(shown[0]?.payload.plugin_card).toBe("get_order");
    const messages = shown[0]?.payload.messages as Array<Record<string, unknown>>;
    const last = messages.at(-1) as { updateComponents: { components: unknown[] } };
    const comps = last.updateComponents.components;
    expect(comps).toEqual([
      {
        id: "root",
        component: "Details",
        title: "Order A-7",
        rows: [
          { label: "Status", value: "shipped" },
          { label: "Mug", value: "2 × $12.00" },
          { label: "Tea", value: "1 × $18.00" },
        ],
        footer: "Total $42.00",
      },
    ]);
    // The model got the plain result plus the card line (its fixture answers CARD on that line).
    expect(r.reply.find((p) => p.type === "text")?.text).toBe("CARD");
    // The card stays with the reply, like ui.show's.
    expect(r.reply.filter((p) => p.type === "ui")).toHaveLength(1);
    expect(PLUGIN_CARD_SHOWN).toMatch(/^Shown to the person as a card/);
  });

  it("keeps the text when `when` has no value", async () => {
    const r = await run("show order none", tool.order, { id: "none" });
    expect(r.status).toBe("completed");
    expect(r.events.some((e) => e.type === "tool.completed")).toBe(true);
    expect(r.events.filter((e) => e.type === "ui.shown")).toEqual([]);
    expect(r.reply.find((p) => p.type === "text")?.text).toBe("TEXT");
  });

  it("keeps the text when the filled card doesn't pass the check", async () => {
    const r = await run("what's next", tool.event);
    expect(r.status).toBe("completed");
    expect(r.events.filter((e) => e.type === "ui.shown")).toEqual([]);
    expect(r.events.some((e) => e.type === "tool.failed")).toBe(false);
    expect(r.reply.find((p) => p.type === "text")?.text).toBe("TEXT");
  });
});
