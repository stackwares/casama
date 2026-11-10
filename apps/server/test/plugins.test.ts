/** Plugins (D-121): Agent Plugins 1.0 from GitHub, pinned, previewed, installed, updated, removed. */
import { once } from "node:events";
import { createServer, type IncomingMessage, type Server } from "node:http";
import type { AddressInfo } from "node:net";
import { fileURLToPath } from "node:url";
import { ComputerMcpAdapter, computerMcpFor, forgetPluginSync } from "@kasama/agent";
import type { ExecChunk, McpServerSpec } from "@kasama/sandbox";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp.js";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { z } from "zod";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = fileURLToPath(new URL("./fixtures/watchers.json", import.meta.url));
const C1 = "1".repeat(40);
const C2 = "2".repeat(40);
let head = C1;
let services: Server;
let servicesUrl = "";
const seenAuth: string[] = [];

const manifest = (version: string, secrets: unknown[]) =>
  JSON.stringify({
    $schema: "https://agent-plugins.org/schemas/1.0.0/plugin.schema.json",
    name: "weather",
    version,
    description: "Forecasts and maps",
    extensions: { "com.kasama": { secrets } },
  });
const mcp = (remote: string, extra: Record<string, unknown> = {}) =>
  JSON.stringify({
    $schema: "https://agent-plugins.org/schemas/1.0.0/mcp.schema.json",
    mcpServers: {
      forecast: { type: "stdio", command: "./bin/forecast", args: ["--data", "${PLUGIN_DATA}/cache"] },
      maps: { type: "streamable-http", url: remote },
      ...extra,
    },
  });
const blobs: Record<string, () => string> = {
  p1: () => manifest("1.0.0", [
    { name: "WEATHER_KEY", server: "forecast", env: "WEATHER_API_KEY", description: "Weather API key" },
    { name: "MAPS_TOKEN", server: "maps", header: "Authorization", format: "Bearer {{value}}" },
  ]),
  p2: () => manifest("2.0.0", [
    { name: "WEATHER_KEY", server: "forecast", env: "WEATHER_API_KEY", description: "Weather API key" },
    { name: "MAPS_TOKEN", server: "maps", header: "Authorization", format: "Bearer {{value}}" },
  ]),
  m1: () => mcp(`${servicesUrl}/remote`),
  m2: () => mcp(`${servicesUrl}/remote`, { tides: { type: "stdio", command: "./bin/tides" } }),
  s1: () => "---\nname: plan-trip\ndescription: Plan a trip around the weather\n---\n\nCheck the forecast first.\n",
  s2: () => "---\nname: plan-trip\ndescription: Plan a trip around the weather\n---\n\nCheck the forecast and tides first.\n",
  bin: () => "#!/bin/sh\nexec node server.js\n",
};
const tree = (p: string, m: string, s: string) => [
  { path: "plugins/weather/plugin.json", type: "blob", sha: p, size: 300, mode: "100644" },
  { path: "plugins/weather/mcp.json", type: "blob", sha: m, size: 300, mode: "100644" },
  { path: "plugins/weather/skills/plan-trip/SKILL.md", type: "blob", sha: s, size: 100, mode: "100644" },
  { path: "plugins/weather/bin/forecast", type: "blob", sha: "bin", size: 30, mode: "100755" },
  { path: "other/README.md", type: "blob", sha: "bin", size: 30, mode: "100644" },
];
const trees: Record<string, unknown[]> = { [C1]: tree("p1", "m1", "s1"), [C2]: tree("p2", "m2", "s2") };

/** The fake computer: what computerd was told, and MCP requests forwarded to a local server. */
const computer = {
  servers: {} as Record<string, McpServerSpec>,
  files: new Map<string, Uint8Array>(),
  commands: [] as string[],
};
const handle = {
  ref: "fake-computer",
  async *exec(cmd: string): AsyncIterable<ExecChunk> {
    computer.commands.push(cmd);
    yield { type: "stdout", data: cmd.startsWith("printf") ? "/home/kasama" : "" };
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
let member: { id: string; token: string };
let orgId: string;
let botId: string;

const mcpServer = (tool: string) => {
  const server = new McpServer({ name: tool, version: "1.0.0" });
  server.registerTool(
    tool,
    { description: `The ${tool}`, inputSchema: { place: z.string() }, annotations: { readOnlyHint: true } },
    async ({ place }) => ({ content: [{ type: "text", text: `${tool} for ${place}` }] }),
  );
  return server;
};

beforeAll(async () => {
  services = createServer(async (req: IncomingMessage, res) => {
    const chunks: Buffer[] = [];
    for await (const c of req) chunks.push(c as Buffer);
    const raw = Buffer.concat(chunks).toString();
    const url = new URL(req.url ?? "/", "http://x");
    const send = (v: unknown, status = 200) => res.writeHead(status, { "content-type": "application/json" }).end(JSON.stringify(v));
    if (url.pathname === "/repos/acme/agent-plugins") return send({ default_branch: "main" });
    if (url.pathname === "/repos/acme/agent-plugins/commits/main") return send({ sha: head });
    const t = /^\/repos\/acme\/agent-plugins\/git\/trees\/([0-9a-f]{40})$/.exec(url.pathname);
    if (t?.[1] && trees[t[1]]) return send({ tree: trees[t[1]], truncated: false });
    const b = /^\/repos\/acme\/agent-plugins\/git\/blobs\/(\w+)$/.exec(url.pathname);
    const blob = b?.[1] ? blobs[b[1]] : undefined;
    if (blob) return send({ content: Buffer.from(blob()).toString("base64"), encoding: "base64" });
    if (url.pathname === "/remote" || url.pathname.startsWith("/stdio/")) {
      if (url.pathname === "/remote") seenAuth.push(String(req.headers.authorization ?? ""));
      const server = mcpServer(url.pathname === "/remote" ? "map" : "forecast");
      const transport = new StreamableHTTPServerTransport({ sessionIdGenerator: undefined });
      res.on("close", () => void transport.close());
      await server.connect(transport);
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
  owner = await h.user("plugins@example.com");
  member = await h.user("plugins-member@example.com");
  orgId = (await j(await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "P" } }))).id;
  await h.tdb.admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${member.id}, 'member')`;
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
        json: { org_id: orgId, name: "Planner", model_policy: { primary: { credential_id: cred.id, model: "m" } } },
      }),
    )
  ).id;
  await h.tdb.admin`insert into public.computers (org_id, kind, owner_bot_id, name, provider) values (${orgId}, 'private', ${botId}, 'Planner computer', 'e2b')`;
}, 60_000);
afterAll(async () => {
  await h?.stop();
  services?.close();
});

const URL_ = "https://github.com/acme/agent-plugins/tree/main/plugins/weather";

describe("plugins", () => {
  let pluginId: string;

  it("previews what a plugin adds: skills, servers, hosts and secrets", async () => {
    const p = await j(await h.request("/v1/plugins/preview", { method: "POST", token: owner.token, json: { org_id: orgId, url: URL_ } }));
    expect(p).toMatchObject({ name: "weather", version: "1.0.0", repo: "acme/agent-plugins", path: "plugins/weather", commit: C1 });
    expect(p.skills).toEqual([{ name: "plan-trip", description: "Plan a trip around the weather" }]);
    expect(p.servers.map((s: { key: string; type: string }) => `${s.key}:${s.type}`)).toEqual(["forecast:stdio", "maps:streamable-http"]);
    expect(p.hosts).toEqual(["127.0.0.1"]);
    expect(p.secrets.map((s: { name: string }) => s.name)).toEqual(["WEATHER_KEY", "MAPS_TOKEN"]);
  });

  it("installs pinned to the commit, needs its secrets, and lists every server's tools", async () => {
    const base = { org_id: orgId, bot_id: botId, url: URL_, commit: C1 };
    const missing = await h.request("/v1/plugins", { method: "POST", token: owner.token, json: base });
    expect(missing.status).toBe(400);
    expect((await h.request("/v1/plugins", { method: "POST", token: member.token, json: base })).status).toBe(403);
    const res = await h.request("/v1/plugins", {
      method: "POST",
      token: owner.token,
      json: { ...base, secrets: { WEATHER_KEY: "wk-123", MAPS_TOKEN: "mt-456" } },
    });
    expect(res.status).toBe(201);
    const p = await j(res);
    pluginId = p.id;
    expect(p.commit).toBe(C1);
    expect(p.skills.map((s: { name: string }) => s.name)).toEqual(["plan-trip"]);
    const forecast = p.servers.find((s: { key: string }) => s.key === "forecast");
    const maps = p.servers.find((s: { key: string }) => s.key === "maps");
    expect(forecast).toMatchObject({ status: "ok", tools: [{ name: "forecast", risk: "low" }] });
    expect(maps).toMatchObject({ status: "ok", tools: [{ name: "map", risk: "low" }] });
    expect(seenAuth).toContain("Bearer mt-456");
    // The package went to the computer, with the secret only in the server's environment.
    const spec = Object.values(computer.servers)[0] as McpServerSpec;
    expect(spec).toMatchObject({
      command: "/home/kasama/.kasama/plugins/weather/bin/forecast",
      args: ["--data", "/home/kasama/.kasama/plugin-data/weather/cache"],
      cwd: "/home/kasama/.kasama/plugins/weather",
    });
    expect(spec.env).toMatchObject({ WEATHER_API_KEY: "wk-123", PLUGIN_ROOT: "/home/kasama/.kasama/plugins/weather" });
    expect(new TextDecoder().decode(computer.files.get("/home/kasama/.kasama/plugins/weather/bin/forecast"))).toContain("exec node");
    expect(computer.files.has("/home/kasama/.kasama/plugins/weather/skills/plan-trip/SKILL.md")).toBe(false);
    expect(computer.commands.some((c) => c.startsWith("chmod +x") && c.includes("bin/forecast"))).toBe(true);
    const [cfg] = await h.tdb.admin<{ config: unknown }[]>`select config from public.integrations where kind = 'computer_mcp'`;
    expect(JSON.stringify(cfg?.config)).not.toContain("wk-123");
  });

  it("a run calls the plugin's tool on the bot's computer", async () => {
    forgetPluginSync();
    const [rec] = await h.tdb.admin<{ id: string; name: string }[]>`select id, name from public.integrations where kind = 'computer_mcp'`;
    const adapter = new ComputerMcpAdapter(
      { id: rec!.id, org_id: orgId, kind: "computer_mcp", name: rec!.name, config: {}, secret: null },
      { fetch, secrets: [], computerMcp: computerMcpFor(h.handle.db, botId, async () => handle as never) },
    );
    expect(await adapter.callTool("forecast", { place: "Cebu" })).toBe("forecast for Cebu");
    await adapter.close();
  });

  it("shows an update as a diff and carries secrets over", async () => {
    head = C2;
    const u = await j(await h.request(`/v1/plugins/${pluginId}/update`, { token: owner.token }));
    expect(u).toMatchObject({
      up_to_date: false,
      from_version: "1.0.0",
      to_version: "2.0.0",
      skills_changed: ["plan-trip"],
      servers_added: ["tides"],
      servers_removed: [],
      secrets_added: [],
    });
    const up = await h.request(`/v1/plugins/${pluginId}/update`, { method: "POST", token: owner.token, json: { commit: C2 } });
    const p = await j(up);
    expect(up.status, JSON.stringify(p)).toBe(200);
    expect(p.commit).toBe(C2);
    expect(p.servers.map((s: { key: string }) => s.key)).toEqual(["forecast", "maps", "tides"]);
    expect(Object.values(computer.servers).find((s) => s.command.endsWith("forecast"))?.env?.WEATHER_API_KEY).toBe("wk-123");
    const [sk] = await h.tdb.admin<{ body_md: string }[]>`select body_md from public.skills where plugin_id = ${pluginId}`;
    expect(sk?.body_md).toContain("tides");
  });

  it("uninstalling removes everything it added", async () => {
    expect((await h.request(`/v1/plugins/${pluginId}`, { method: "DELETE", token: member.token })).status).toBe(403);
    expect((await h.request(`/v1/plugins/${pluginId}`, { method: "DELETE", token: owner.token })).status).toBe(200);
    const [n] = await h.tdb.admin<{ skills: number; ints: number; files: number }[]>`
      select (select count(*)::int from public.skills where source = 'plugin') as skills,
             (select count(*)::int from public.integrations where plugin_id is not null or kind = 'computer_mcp') as ints,
             (select count(*)::int from public.plugin_files) as files`;
    expect(n).toEqual({ skills: 0, ints: 0, files: 0 });
    expect(computer.servers).toEqual({});
    expect(computer.commands.at(-1)).toContain("rm -rf");
    expect((await j(await h.request(`/v1/plugins?bot_id=${botId}`, { token: owner.token }))).items).toEqual([]);
  });
});
