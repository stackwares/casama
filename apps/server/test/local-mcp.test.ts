/**
 * Local MCP servers on a user's computer (D-096): the desktop app registers them, the worker lists
 * and calls their tools through the API's device tunnel to the companion's computerd, which bridges
 * to a real stdio MCP server.
 */
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { createAdapter } from "@kasama/agent";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { internalToken } from "../src/api/routes/local.ts";
import { computerdBinary, type FakeDevice, startFakeDevice } from "./fake-device.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = fileURLToPath(new URL("./fixtures/local.json", import.meta.url));
const FAKE_SERVER = fileURLToPath(
  new URL("../../../dart/computerd/test/fixtures/fake_mcp_server.dart", import.meta.url),
);

describe("local MCP servers", () => {
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
    home = mkdtempSync(join(tmpdir(), "kasama-local-mcp-"));
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
    fake = await startFakeDevice({
      serverUrl: h.serverUrl as string,
      token: device.token,
      roots: [home],
      capabilities: ["mcp"],
      mcpServers: { fake: { kind: "stdio", command: "dart", args: ["run", FAKE_SERVER] } },
    });
  }, 240_000);
  afterAll(async () => {
    await fake?.close();
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
});
