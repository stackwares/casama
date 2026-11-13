/** Bots that change their own setup (D-242): MCP servers, connections, cards, rules, knowledge, quiet. */
import { once } from "node:events";
import { createServer, type IncomingMessage, type Server } from "node:http";
import type { AddressInfo } from "node:net";
import { registerSettingsTools, ToolRegistry } from "@casama/agent";
import type { ExecChunk, McpServerSpec } from "@casama/sandbox";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp.js";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { z } from "zod";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
let services: Server;
let servicesUrl: string;
let owner: { id: string; token: string };
let orgId: string;
let botId: string;
let runId: string;
const reg = new ToolRegistry();
const seenAuth: string[] = [];
const events: Array<{ type: string; payload: Record<string, unknown> }> = [];
/** Accounts the fake Composio (https://composio.test) reports as signed in. */
let composioAccounts: Array<{ toolkit: { slug: string }; status: string }> = [];

const computer = { servers: {} as Record<string, McpServerSpec>, commands: [] as string[] };
const handle = {
  ref: "fake-settings-computer",
  async *exec(cmd: string): AsyncIterable<ExecChunk> {
    computer.commands.push(cmd);
    yield { type: "stdout", data: cmd.startsWith("printf") ? "/home/casama" : "" };
    yield { type: "exit", code: 0, timedOut: false, killed: false, truncated: false };
  },
  readFile: async () => {
    throw new Error("not found");
  },
  writeFile: async () => {},
  setMcpServers: async (s: Record<string, McpServerSpec>) => void (computer.servers = s),
  mcpFetch: (key: string, init: RequestInit) => fetch(`${servicesUrl}/stdio/${key}`, init),
};

const ctx = () =>
  ({
    runId,
    botId,
    orgId,
    output: async () => {},
    emit: async (type: string, payload: Record<string, unknown>) =>
      void events.push({ type, payload }),
    computer: async () => handle,
  }) as never;
const call = (name: string, args: unknown) => {
  const def = reg.get(name)!;
  return def.execute(def.schema.parse(args) as never, ctx());
};
const def = (name: string) => reg.get(name)!;

const mcpServer = (tool: string) => {
  const server = new McpServer({ name: tool, version: "1.0.0" });
  server.registerTool(
    tool,
    { description: `The ${tool}`, inputSchema: { q: z.string() } },
    async ({ q }) => ({ content: [{ type: "text", text: `${tool}: ${q}` }] }),
  );
  return server;
};

beforeAll(async () => {
  services = createServer(async (req: IncomingMessage, res) => {
    const chunks: Buffer[] = [];
    for await (const c of req) chunks.push(c as Buffer);
    const raw = Buffer.concat(chunks).toString();
    const path = new URL(req.url ?? "/", "http://x").pathname;
    if (path === "/remote" || path.startsWith("/stdio/")) {
      if (path === "/remote") seenAuth.push(String(req.headers.authorization ?? ""));
      const server = mcpServer(path === "/remote" ? "lookup" : "weather");
      const transport = new StreamableHTTPServerTransport({ sessionIdGenerator: undefined });
      res.on("close", () => void transport.close());
      await server.connect(transport);
      return transport.handleRequest(req, res, raw ? JSON.parse(raw) : undefined);
    }
    res.writeHead(404).end();
  }).listen(0, "127.0.0.1");
  await once(services, "listening");
  servicesUrl = `http://127.0.0.1:${(services.address() as AddressInfo).port}`;
  h = await startHarness();
  owner = await h.user("settings@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "S" } }),
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
          name: "Fixer",
          model_policy: { primary: { credential_id: cred.id, model: "m" } },
        },
      }),
    )
  ).id;
  await h.tdb
    .admin`insert into public.computers (org_id, kind, owner_bot_id, name, provider) values (${orgId}, 'private', ${botId}, 'c', 'e2b')`;
  const [run] = await h.tdb.admin<{ id: string }[]>`
    insert into public.runs (org_id, bot_id, trigger, status, created_by)
    values (${orgId}, ${botId}, 'chat', 'running', ${owner.id}) returning id`;
  runId = run!.id;
  // "https://mcp.test" is the local fake server.
  const fakeFetch = (async (u: string | URL | Request, init?: RequestInit) => {
    const url = String(u instanceof Request ? u.url : u);
    if (url.startsWith("https://composio.test/api/v3/connected_accounts?"))
      return Response.json({ items: composioAccounts });
    return fetch(url.replace("https://mcp.test", servicesUrl), init);
  }) as typeof fetch;
  registerSettingsTools(reg, {
    db: h.handle.db,
    fetch: fakeFetch,
    galleryApps: async () => [{ id: "cal-com", name: "Cal.com" }],
  });
}, 60_000);
afterAll(async () => {
  await h?.stop();
  services?.close();
});

describe("bot settings tools", () => {
  it("asks first for anything that widens reach, and not for what narrows it", () => {
    expect(def("mcp.add").alwaysAsk).toBe(true);
    expect(def("connections.attach").alwaysAsk).toBe(true);
    expect(def("rules.add").alwaysAskFor?.({ rule: "allow" } as never)).toBe(true);
    expect(def("rules.add").alwaysAskFor?.({ rule: "ask" } as never)).toBe(false);
    expect(def("rules.remove").alwaysAskFor?.({ rule: "ask" } as never)).toBe(true);
    expect(def("rules.remove").alwaysAskFor?.({ rule: "allow" } as never)).toBe(false);
    expect(def("notifications.quiet").alwaysAskFor?.({ quiet: "default" } as never)).toBe(true);
    expect(def("notifications.quiet").alwaysAskFor?.({ quiet: "always" } as never)).toBe(false);
    expect(
      def("mcp.add").destinationHost?.({ url: "https://mcp.test/remote" } as never, ctx()),
    ).toBe("mcp.test");
  });

  it("adds a remote MCP server with a key, lists its tools and attaches it", async () => {
    await expect(
      call("mcp.add", { name: "plain", url: "http://mcp.test/remote", why: "x" }),
    ).rejects.toThrow(/https/);
    const r = await call("mcp.add", {
      name: "lookup",
      url: "https://mcp.test/remote",
      auth_value: "tok-1",
      why: "Look things up",
    });
    expect(r.content).toMatch(/Added lookup with 1 tools \(lookup\)/);
    expect(seenAuth).toContain("Bearer tok-1");
    const [i] = await h.tdb.admin<
      { name: string; kind: string; status: string; added_by: string; attached: boolean }[]
    >`
      select i.name, i.kind, i.status, i.config ->> 'added_by_bot' as added_by,
             exists (select 1 from public.bot_integrations bi where bi.integration_id = i.id and bi.bot_id = ${botId}) as attached
      from public.integrations i where i.org_id = ${orgId} and i.kind = 'mcp'`;
    expect(i).toMatchObject({ kind: "mcp", status: "ok", added_by: botId, attached: true });
    expect(i?.name).toMatch(/^lookup_[0-9a-f]{6}$/);
    await expect(
      call("mcp.add", { name: "lookup", url: "https://mcp.test/remote", why: "x" }),
    ).rejects.toThrow(/already have/);
    expect((await call("connections.list", {})).content).toMatch(
      /lookup_\w+: mcp, ok, 1 tools, yours/,
    );
  });

  it("runs a server by command on its own computer", async () => {
    const r = await call("mcp.add", {
      name: "weather",
      command: "npx",
      args: ["-y", "weather-mcp"],
      env: { UNITS: "metric" },
      why: "Forecasts",
    });
    expect(r.content).toMatch(/Added weather with 1 tools/);
    const spec = Object.values(computer.servers)[0] as McpServerSpec & {
      command: string;
      args: string[];
      env: Record<string, string>;
      cwd: string;
    };
    expect(spec).toMatchObject({ kind: "stdio", command: "npx", args: ["-y", "weather-mcp"] });
    expect(spec.env.UNITS).toBe("metric");
    expect(spec.cwd).toMatch(/^\/home\/casama\/\.casama\/mcp\/weather_/);
    expect(computer.commands.some((c) => c.startsWith("mkdir -p"))).toBe(true);
  });

  it("attaches a workspace connection, and removes or detaches", async () => {
    const [shared] = await h.tdb.admin<{ id: string }[]>`
      insert into public.integrations (org_id, kind, name, config) values (${orgId}, 'mcp', 'shared', '{"url":"https://mcp.test/remote"}') returning id`;
    await call("connections.attach", { name: "shared", tools: ["lookup"] });
    const [link] = await h.tdb.admin<{ tool_allowlist: string[] }[]>`
      select tool_allowlist from public.bot_integrations where bot_id = ${botId} and integration_id = ${shared!.id}`;
    expect(link?.tool_allowlist).toEqual(["lookup"]);
    expect((await call("mcp.remove", { name: "shared" })).content).toBe("Detached shared.");
    expect((await call("mcp.remove", { name: "lookup" })).content).toBe("Deleted lookup.");
    const rows = await h.tdb.admin<{ name: string }[]>`
      select name from public.integrations where org_id = ${orgId} order by name`;
    expect(rows.map((r) => r.name)).toEqual(["shared", expect.stringMatching(/^weather_/)]);
    await expect(call("connections.attach", { name: "nope" })).rejects.toThrow(/No connection/);
  });

  it("shows cards the app handles itself: a look and a plugin", async () => {
    events.length = 0;
    await call("appearance.suggest", { preset: "ocean", mode: "dark", why: "Calmer at night" });
    await call("plugins.suggest", {
      url: "https://github.com/acme/agent-plugins/tree/main/plugins/weather",
      name: "Weather",
      why: "Forecasts for your trips",
    });
    const actions = JSON.stringify(events.map((e) => e.payload.messages));
    expect(events.map((e) => e.type)).toEqual(["ui.shown", "ui.shown"]);
    expect(actions).toContain('"name":"app:appearance","context":{"preset":"ocean","mode":"dark"}');
    expect(actions).toContain(
      `/bots/${botId}/plugins?install=${encodeURIComponent("https://github.com/acme/agent-plugins/tree/main/plugins/weather")}`,
    );
    expect(() => def("appearance.suggest").schema.parse({ why: "nothing" })).toThrow();
    expect(() =>
      def("plugins.suggest").schema.parse({ url: "https://evil.test/x", name: "x", why: "x" }),
    ).toThrow();
  });

  it("offers connect buttons for apps, skipping ones already connected (D-259)", async () => {
    events.length = 0;
    const r = await call("connections.offer", {
      apps: ["google_calendar", "gmail"],
      why: "So I can see your schedule and inbox",
    });
    expect(r.content).toMatch(/connect Google Calendar and Gmail is in the chat/);
    const ui = JSON.stringify(events.map((e) => e.payload.messages));
    expect(ui).toContain('"name":"app:connect","context":{"app":"google_calendar"}');
    expect(ui).toContain('"name":"app:connect","context":{"app":"gmail"}');
    expect(ui).toContain("Connect Gmail");
    await expect(call("connections.offer", { apps: ["google"], why: "x" })).rejects.toThrow(
      /No app called google\. Use ids from: .*gmail.*cal-com/,
    );
    // A gallery app gets a button too.
    events.length = 0;
    const gallery = await call("connections.offer", { apps: ["cal-com"], why: "Book meetings" });
    expect(gallery.content).toMatch(/connect Cal\.com is in the chat/);
    expect(JSON.stringify(events.map((e) => e.payload.messages))).toContain(
      '"name":"app:connect","context":{"app":"cal-com"}',
    );
    await h.tdb.admin`
      insert into public.integrations (org_id, kind, name, config) values (${orgId}, 'mcp', 'gcal', '{"app":"google_calendar","url":"https://mcp.test/remote"}')`;
    events.length = 0;
    const again = await call("connections.offer", { apps: ["google_calendar"], why: "x" });
    expect(again.content).toMatch(/No card shown. Google Calendar is already connected/);
    expect(events).toHaveLength(0);
    await h.tdb.admin`delete from public.integrations where org_id = ${orgId} and name = 'gcal'`;
  });

  it("sees Gmail connected through managed Composio and shows no card for it", async () => {
    const [secret] = await h.tdb.admin<{ id: string }[]>`
      select vault.create_secret('cmp-key', null, 'composio managed') as id`;
    await h.tdb.admin`
      insert into public.integrations (org_id, kind, name, config, vault_secret_id, status)
      values (${orgId}, 'composio', 'apps', '{"managed": true, "toolkits": ["gmail", "googlecalendar"], "base_url": "https://composio.test"}'::jsonb, ${secret!.id}, 'ok')`;
    // Gmail signed in; Calendar's sign-in page opened but never finished.
    composioAccounts = [
      { toolkit: { slug: "gmail" }, status: "ACTIVE" },
      { toolkit: { slug: "googlecalendar" }, status: "INITIATED" },
    ];
    events.length = 0;
    const r = await call("connections.offer", { apps: ["gmail"], why: "To read your inbox" });
    expect(r.content).toMatch(/No card shown. Gmail is already connected/);
    expect(events).toHaveLength(0);
    const both = await call("connections.offer", {
      apps: ["gmail", "google_calendar"],
      why: "x",
    });
    expect(both.content).toMatch(
      /connect Google Calendar is in the chat.*Gmail is already connected/,
    );
    const ui = JSON.stringify(events.map((e) => e.payload.messages));
    expect(ui).toContain("Connect Google Calendar");
    expect(ui).not.toContain("Connect Gmail");
    await h.tdb.admin`delete from public.integrations where org_id = ${orgId} and name = 'apps'`;
  });

  it("adds and removes its own action rules, never waving payments through", async () => {
    await call("rules.add", { match_kind: "category", match_value: "send", rule: "ask" });
    await expect(
      call("rules.add", { match_kind: "category", match_value: "pay", rule: "allow" }),
    ).rejects.toThrow(/Payments/);
    const list = (await call("rules.list", {})).content;
    const id = /- ([0-9a-f]{8}):/.exec(list)?.[1] as string;
    await expect(call("rules.remove", { id, rule: "allow" })).rejects.toThrow(/That rule is ask/);
    await call("rules.remove", { id, rule: "ask" });
    expect((await call("rules.list", {})).content).toBe("No rules.");
  });

  it("adds knowledge sources to itself and removes them", async () => {
    await call("knowledge.add", { name: "Docs", url: "https://docs.example.com" });
    await call("knowledge.add", {
      name: "Repo",
      repo_url: "https://github.com/acme/handbook/tree/main/docs",
    });
    const rows = await h.tdb.admin<
      { name: string; kind: string; bot_id: string; config: Record<string, unknown> }[]
    >`
      select name, kind, bot_id, config from public.knowledge_sources where org_id = ${orgId} order by name`;
    expect(rows).toMatchObject([
      {
        name: "Docs",
        kind: "website",
        bot_id: botId,
        config: { url: "https://docs.example.com/" },
      },
      {
        name: "Repo",
        kind: "github",
        config: { owner: "acme", repo: "handbook", ref: "main", path: "docs" },
      },
    ]);
    await call("knowledge.remove", { name: "Docs" });
    await expect(call("knowledge.remove", { name: "Docs" })).rejects.toThrow(/no knowledge source/);
  });

  it("quiets itself for the person it works for", async () => {
    await call("notifications.quiet", { quiet: "custom", start: "22:00", end: "07:00" });
    const [s] = await h.tdb.admin<{ quiet: string; quiet_hours: Record<string, unknown> }[]>`
      select quiet, quiet_hours from public.user_bot_settings where user_id = ${owner.id} and bot_id = ${botId}`;
    expect(s).toMatchObject({
      quiet: "custom",
      quiet_hours: { enabled: true, start: "22:00", end: "07:00" },
    });
    await expect(
      call("notifications.quiet", { quiet: "custom", start: "09:00", end: "09:00" }),
    ).rejects.toThrow(/HH:MM/);
  });
});
