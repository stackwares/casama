/**
 * Local MCP servers on a user's computer (D-096): the desktop app registers them, the worker lists
 * and calls their tools through the API's device tunnel to the companion's computerd, which bridges
 * to a real stdio MCP server.
 */
import { mkdtempSync, rmSync } from "node:fs";
import { createServer, type Server } from "node:http";
import type { AddressInfo } from "node:net";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { createAdapter, LocalSignInNeededError } from "@casama/agent";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { internalToken } from "../src/api/routes/local.ts";
import { computerdBinary, type FakeDevice, startFakeDevice } from "./fake-device.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = fileURLToPath(new URL("./fixtures/local.json", import.meta.url));
const FAKE_SERVER = fileURLToPath(
  new URL("../../../dart/computerd/test/fixtures/fake_mcp_server.dart", import.meta.url),
);

/**
 * A local MCP server at an address (D-363): "/locked" wants a sign-in it never gets; "/mcp" asks
 * the person a question during a call and answers with what they said.
 */
function startHttpMcp(): Promise<Server> {
  const answers = new Map<string, (v: Record<string, unknown>) => void>();
  const server = createServer(async (req, res) => {
    const chunks: Buffer[] = [];
    for await (const c of req) chunks.push(c as Buffer);
    if (req.url === "/locked") {
      res.writeHead(401, {
        "www-authenticate":
          'Bearer resource_metadata="http://127.0.0.1/.well-known/oauth-protected-resource"',
        "content-type": "application/json",
      });
      return res.end('{"error":"unauthorized"}');
    }
    const m = JSON.parse(Buffer.concat(chunks).toString() || "{}");
    if (m.method === undefined && m.id !== undefined) {
      answers.get(String(m.id))?.(m.result ?? { action: "error" });
      res.writeHead(202);
      return res.end();
    }
    if (m.id === undefined) {
      res.writeHead(202);
      return res.end();
    }
    const json = (body: unknown) => {
      res.writeHead(200, { "content-type": "application/json" });
      res.end(JSON.stringify(body));
    };
    if (m.method === "initialize")
      return json({
        jsonrpc: "2.0",
        id: m.id,
        result: {
          protocolVersion: "2025-06-18",
          capabilities: { tools: {} },
          serverInfo: { name: "asker", version: "1" },
        },
      });
    if (m.method === "tools/list")
      return json({
        jsonrpc: "2.0",
        id: m.id,
        result: { tools: [{ name: "ask", inputSchema: { type: "object" } }] },
      });
    // tools/call ask: the question on this request's stream, then the answer.
    res.writeHead(200, { "content-type": "text/event-stream" });
    const qid = `q${answers.size + 1}`;
    const got = new Promise<Record<string, unknown>>((r) => answers.set(qid, r));
    res.write(
      `event: message\ndata: ${JSON.stringify({
        jsonrpc: "2.0",
        id: qid,
        method: "elicitation/create",
        params: {
          message: "Which project?",
          requestedSchema: {
            type: "object",
            properties: { project: { type: "string" } },
            required: ["project"],
          },
        },
      })}\n\n`,
    );
    const a = await got;
    const text =
      a.action === "accept"
        ? `working on ${(a.content as { project: string }).project}`
        : `no answer: ${a.action}`;
    res.end(
      `event: message\ndata: ${JSON.stringify({ jsonrpc: "2.0", id: m.id, result: { content: [{ type: "text", text }] } })}\n\n`,
    );
  });
  return new Promise((r) => server.listen(0, "127.0.0.1", () => r(server)));
}

describe("local MCP servers", () => {
  let httpMcp: Server;
  let h: Harness;
  let owner: { id: string; email: string; token: string };
  let teammate: { id: string; email: string; token: string };
  let orgId: string;
  let botId: string;
  let otherBotId: string;
  let device: { id: string; computer_id: string; token: string };
  let fake: FakeDevice;
  let home: string;
  let integrationId: string;

  beforeAll(async () => {
    computerdBinary();
    home = mkdtempSync(join(tmpdir(), "casama-local-mcp-"));
    h = await startHarness({ worker: { fixtures: FIXTURES }, local: true });
    owner = await h.user("mcp-owner@example.com");
    teammate = await h.user("mcp-teammate@example.com");
    orgId = (
      await j(
        await h.request("/v1/orgs", {
          method: "POST",
          token: owner.token,
          json: { name: "Local MCP" },
        }),
      )
    ).id;
    await h.tdb
      .admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${teammate.id}, 'admin')`;
    const cred = await j(
      await h.request("/v1/credentials", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, provider: "openrouter", label: "k", api_key: "sk-local-mcp-key" },
      }),
    );
    const mk = async (name: string) =>
      (
        await j(
          await h.request("/v1/bots", {
            method: "POST",
            token: owner.token,
            json: {
              org_id: orgId,
              name,
              model_policy: { primary: { credential_id: cred.id, model: "fixture-main" } },
            },
          }),
        )
      ).id as string;
    botId = await mk("Ada");
    otherBotId = await mk("Rex");
    device = await j(
      await h.request("/v1/local-devices", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, name: "Laptop", platform: "macos" },
      }),
    );
    await h.request(`/v1/local-devices/${device.id}`, {
      method: "PATCH",
      token: owner.token,
      json: { capabilities: { mcp: true }, allowed_roots: [home], allowed_bot_ids: [botId] },
    });
    httpMcp = await startHttpMcp();
    const httpBase = `http://127.0.0.1:${(httpMcp.address() as AddressInfo).port}`;
    fake = await startFakeDevice({
      serverUrl: h.serverUrl as string,
      token: device.token,
      roots: [home],
      capabilities: ["mcp"],
      mcpServers: {
        fake: { kind: "stdio", command: "dart", args: ["run", FAKE_SERVER] },
        locked: { kind: "loopback", url: `${httpBase}/locked` },
        asker: { kind: "loopback", url: `${httpBase}/mcp` },
      },
    });
  }, 240_000);
  afterAll(async () => {
    await fake?.close();
    httpMcp?.close();
    await h?.stop();
    rmSync(home, { recursive: true, force: true });
  });

  it("registers the device's servers as local integrations attached to its allowed bots", async () => {
    const res = await h.request(`/v1/local-devices/${device.id}/mcp-servers`, {
      method: "PUT",
      token: owner.token,
      json: {
        servers: [
          {
            key: "fake",
            label: "Fake tools",
            kind: "stdio",
            summary: "dart run fake_mcp_server.dart",
          },
        ],
      },
    });
    expect(res.status).toBe(200);
    const { items } = await j(res);
    expect(items).toHaveLength(1);
    expect(items[0]).toMatchObject({
      kind: "local_mcp",
      device: { owner_user_id: owner.id, label: "Fake tools" },
    });
    integrationId = items[0].id;
    const [att] = await h.tdb.admin<{ bot_id: string }[]>`
      select bot_id from public.bot_integrations where integration_id = ${integrationId}`;
    expect(att?.bot_id).toBe(botId);
    // Nobody else registers servers for this computer.
    const other = await h.request(`/v1/local-devices/${device.id}/mcp-servers`, {
      method: "PUT",
      token: teammate.token,
      json: { servers: [] },
    });
    expect(other.status).toBe(404);
  });

  it("lists the tools through the worker and the tunnel without a run", async () => {
    const r = await j(
      await h.request(`/v1/integrations/${integrationId}/test`, {
        method: "POST",
        token: owner.token,
      }),
    );
    expect(r.ok).toBe(true);
    expect(r.tools).toEqual(["echo", "slow"]);
  }, 60_000);

  it("lets a member test the servers on their own computer, and nobody else's", async () => {
    const member = await h.user("mcp-member@example.com");
    const other = await h.user("mcp-other-member@example.com");
    await h.tdb.admin`insert into public.memberships (org_id, user_id, role)
      values (${orgId}, ${member.id}, 'member'), (${orgId}, ${other.id}, 'member')`;
    const own = await j(
      await h.request("/v1/local-devices", {
        method: "POST",
        token: member.token,
        json: { org_id: orgId, name: "Member laptop", platform: "macos" },
      }),
    );
    const { items } = await j(
      await h.request(`/v1/local-devices/${own.id}/mcp-servers`, {
        method: "PUT",
        token: member.token,
        json: {
          servers: [
            { key: "notes", label: "Notes", kind: "stdio", summary: "notes-mcp" },
            // A bearer token or header is a key kept on the computer; the Integration schema's
            // auth is oauth | api_key | none, and anything else breaks the app's decoder.
            { key: "paid", label: "Paid", kind: "loopback", summary: "paid", auth: "token" },
            { key: "raw", label: "Raw", kind: "loopback", summary: "raw", auth: "header" },
          ],
        },
      }),
    );
    expect(
      Object.fromEntries(
        (items as { device: { label: string }; auth: string }[]).map((i) => [
          i.device.label,
          i.auth,
        ]),
      ),
    ).toEqual({ Notes: "none", Paid: "api_key", Raw: "api_key" });
    const test = (token: string, id: string) =>
      h.request(`/v1/integrations/${id}/test`, { method: "POST", token });
    // Their computer isn't connected, so the test runs and reports why it failed.
    const res = await test(member.token, items[0].id);
    expect(res.status).toBe(200);
    expect((await j(res)).ok).toBe(false);
    expect((await test(other.token, items[0].id)).status).toBe(403);
    expect((await test(member.token, integrationId)).status).toBe(403);
  }, 60_000);

  it("only the computer's owner attaches it to bots", async () => {
    const denied = await h.request(`/v1/bots/${otherBotId}/integrations`, {
      method: "POST",
      token: teammate.token,
      json: { integration_id: integrationId },
    });
    expect(denied.status).toBe(403);
  });

  it("calls tools for an allowed bot's run, with progress, and refuses other bots", async () => {
    const [run] = await h.tdb.admin<{ id: string }[]>`
      insert into public.runs (org_id, bot_id, trigger, status) values (${orgId}, ${botId}, 'chat', 'running') returning id`;
    const [rec] = await h.tdb.admin<{ config: Record<string, unknown>; name: string }[]>`
      select config, name from public.integrations where id = ${integrationId}`;
    const record = {
      id: integrationId,
      org_id: orgId,
      kind: "local_mcp" as const,
      name: rec!.name,
      config: rec!.config,
      secret: null,
    };
    const local = { apiUrl: h.serverUrl as string, internalToken: internalToken(h.deps.env) };
    const activity = (runId: string) => ({
      run_id: runId,
      bot: "Ada",
      tool: "local_mcp.fake.echo",
      summary: "fake: echo",
    });
    const adapter = createAdapter(record, {
      fetch,
      secrets: [],
      local,
      activity: activity(run!.id),
    });
    expect(await adapter.callTool("echo", { text: "hello" })).toBe("echo: hello");
    const progress: string[] = [];
    expect(await adapter.callTool("slow", {}, { onProgress: (t) => progress.push(t) })).toBe(
      "slow done",
    );
    expect(progress).toEqual(["Progress 1/2", "Progress 2/2"]);
    await adapter.close?.();
    expect(fake.activities.some((a) => a.tool === "local_mcp.fake.echo")).toBe(true);

    const [otherRun] = await h.tdb.admin<{ id: string }[]>`
      insert into public.runs (org_id, bot_id, trigger, status) values (${orgId}, ${otherBotId}, 'chat', 'running') returning id`;
    const refused = createAdapter(record, {
      fetch,
      secrets: [],
      local,
      activity: activity(otherRun!.id),
    });
    await expect(refused.callTool("echo", { text: "x" })).rejects.toThrow(/not allowed/);
    await refused.close?.();
  }, 60_000);

  it("reports a server that needs a sign-in, and passes a server's question to the person (D-363)", async () => {
    const [run] = await h.tdb.admin<{ id: string }[]>`
      insert into public.runs (org_id, bot_id, trigger, status) values (${orgId}, ${botId}, 'chat', 'running') returning id`;
    const [rec] = await h.tdb.admin<{ config: Record<string, unknown>; name: string }[]>`
      select config, name from public.integrations where id = ${integrationId}`;
    const local = { apiUrl: h.serverUrl as string, internalToken: internalToken(h.deps.env) };
    const adapterFor = (server: string) =>
      createAdapter(
        {
          id: integrationId,
          org_id: orgId,
          kind: "local_mcp" as const,
          name: `${server}_x`,
          config: { ...rec!.config, server, label: server },
          secret: null,
        },
        {
          fetch,
          secrets: [],
          local,
          activity: { run_id: run!.id, bot: "Ada", tool: `local_mcp.${server}.x`, summary: server },
        },
      );

    const locked = adapterFor("locked");
    const err = await locked.listTools().catch((e: unknown) => e);
    expect(err).toBeInstanceOf(LocalSignInNeededError);
    expect((err as Error).message).toMatch(/locked needs a sign-in/);
    await locked.close?.();

    const asker = adapterFor("asker");
    const asked: Array<{ message: string; schema: Record<string, unknown> }> = [];
    const text = await asker.callTool(
      "ask",
      {},
      {
        onQuestion: async (q) => {
          asked.push(q);
          return { action: "accept", content: { project: "Casama" } };
        },
      },
    );
    expect(asked[0]?.message).toBe("Which project?");
    expect(asked[0]?.schema).toMatchObject({ required: ["project"] });
    expect(text).toBe("working on Casama");
    // Without someone to ask, the question is declined for the person.
    expect(await asker.callTool("ask", {})).toBe("no answer: decline");
    await asker.close?.();
  }, 120_000);
});
