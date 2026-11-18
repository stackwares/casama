/**
 * Plugin tools on your own computer (D-344): a plugin's stdio server placed on the installer's
 * desktop companion. A real computerd in companion mode gets the package and the server list over
 * the device tunnel; the bot calls the tools in its owner's runs only; offline, reconnect, settings
 * and removal behave.
 */
import { once } from "node:events";
import { existsSync, mkdtempSync, readFileSync, rmSync } from "node:fs";
import { createServer, type Server } from "node:http";
import type { AddressInfo } from "node:net";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { createAdapter, othersComputerToolsHint } from "@casama/agent";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { internalToken } from "../src/api/routes/local.ts";
import { computerdBinary, type FakeDevice, startFakeDevice } from "./fake-device.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = fileURLToPath(new URL("./fixtures/local.json", import.meta.url));
const FAKE_SERVER = fileURLToPath(
  new URL("../../../dart/computerd/test/fixtures/fake_mcp_server.dart", import.meta.url),
);
const COMMIT = "3".repeat(40);

const blobs: Record<string, () => string> = {
  manifest: () =>
    JSON.stringify({
      $schema: "https://agent-plugins.org/schemas/1.0.0/plugin.schema.json",
      name: "notes",
      version: "1.0.0",
      description: "Notes on your own computer",
      extensions: {
        "com.casama": {
          secrets: [{ name: "NOTES_KEY", server: "notes", env: "NOTES_KEY", description: "Key" }],
          settings: [{ name: "FOLDER", label: "Folder", server: "notes", env: "NOTES_FOLDER" }],
        },
      },
    }),
  mcp: () =>
    JSON.stringify({
      $schema: "https://agent-plugins.org/schemas/1.0.0/mcp.schema.json",
      mcpServers: {
        notes: {
          type: "stdio",
          command: "dart",
          args: ["run", "${PLUGIN_ROOT}/server.dart"],
          env: { NOTES_CACHE: "${PLUGIN_DATA}/cache" },
        },
      },
    }),
  server: () => readFileSync(FAKE_SERVER, "utf8"),
};
const TREE = [
  { path: "notes/plugin.json", type: "blob", sha: "manifest", size: 300, mode: "100644" },
  { path: "notes/mcp.json", type: "blob", sha: "mcp", size: 300, mode: "100644" },
  { path: "notes/server.dart", type: "blob", sha: "server", size: 3000, mode: "100644" },
];

describe("plugin tools on your own computer", () => {
  let github: Server;
  let h: Harness;
  let owner: { id: string; token: string };
  let teammate: { id: string; token: string };
  let orgId: string;
  let botId: string;
  let device: { id: string; computer_id: string; token: string };
  let fake: FakeDevice;
  let home: string;
  let pluginId: string;
  let integration: { id: string; name: string; config: Record<string, unknown> };

  const run = async (userId: string) => {
    const [r] = await h.tdb.admin<{ id: string }[]>`
      insert into public.runs (org_id, bot_id, trigger, status, created_by)
      values (${orgId}, ${botId}, 'chat', 'running', ${userId}) returning id`;
    return r?.id as string;
  };
  const adapterFor = (runId: string) =>
    createAdapter(
      { ...integration, org_id: orgId, kind: "local_mcp", secret: null },
      {
        fetch,
        secrets: [],
        local: { apiUrl: h.serverUrl as string, internalToken: internalToken(h.deps.env) },
        activity: { run_id: runId, bot: "Ada", tool: "notes", summary: "notes" },
      },
    );
  const connect = () =>
    startFakeDevice({
      serverUrl: h.serverUrl as string,
      token: device.token,
      roots: [home],
      capabilities: ["mcp"],
    });
  const waitFor = async (check: () => boolean | Promise<boolean>) => {
    for (let i = 0; i < 100; i++) {
      if (await check()) return;
      await new Promise((r) => setTimeout(r, 100));
    }
    throw new Error("timed out");
  };

  beforeAll(async () => {
    computerdBinary();
    home = mkdtempSync(join(tmpdir(), "casama-plugin-companion-"));
    github = createServer((req, res) => {
      const url = new URL(req.url ?? "/", "http://x");
      const send = (v: unknown, status = 200) =>
        res.writeHead(status, { "content-type": "application/json" }).end(JSON.stringify(v));
      if (url.pathname === "/repos/acme/tools") return send({ default_branch: "main" });
      if (url.pathname === "/repos/acme/tools/commits/main") return send({ sha: COMMIT });
      if (url.pathname === `/repos/acme/tools/git/trees/${COMMIT}`)
        return send({ tree: TREE, truncated: false });
      const b = /^\/repos\/acme\/tools\/git\/blobs\/(\w+)$/.exec(url.pathname);
      const blob = b?.[1] ? blobs[b[1]] : undefined;
      if (blob)
        return send({ content: Buffer.from(blob()).toString("base64"), encoding: "base64" });
      send({}, 404);
    }).listen(0, "127.0.0.1");
    await once(github, "listening");
    h = await startHarness({
      env: { GITHUB_API_URL: `http://127.0.0.1:${(github.address() as AddressInfo).port}` },
      worker: { fixtures: FIXTURES },
      local: true,
    });
    owner = await h.user("plugin-companion-owner@example.com");
    teammate = await h.user("plugin-companion-teammate@example.com");
    orgId = (
      await j(
        await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "PC" } }),
      )
    ).id;
    await h.tdb.admin`insert into public.memberships (org_id, user_id, role)
      values (${orgId}, ${teammate.id}, 'admin')`;
    const cred = await j(
      await h.request("/v1/credentials", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, provider: "openrouter", label: "k", api_key: "sk-or-v1-abcdefabcd" },
      }),
    );
    botId = (
      await j(
        await h.request("/v1/bots", {
          method: "POST",
          token: owner.token,
          json: {
            org_id: orgId,
            name: "Ada",
            model_policy: { primary: { credential_id: cred.id, model: "fixture-main" } },
          },
        }),
      )
    ).id;
    device = await j(
      await h.request("/v1/local-devices", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, name: "Oli's Mac", platform: "macos" },
      }),
    );
    // Local tools on; the bot is NOT among the computer's allowed bots: placing a plugin there
    // lets it reach exactly those servers and nothing else.
    await h.request(`/v1/local-devices/${device.id}`, {
      method: "PATCH",
      token: owner.token,
      json: { capabilities: { mcp: true }, allowed_roots: [home], allowed_bot_ids: [] },
    });
    fake = await connect();
  }, 240_000);
  afterAll(async () => {
    await fake?.close();
    await h?.stop();
    github?.close();
    rmSync(home, { recursive: true, force: true });
  });

  const install = (token: string, deviceId: string) =>
    h.request("/v1/plugins", {
      method: "POST",
      token,
      json: {
        org_id: orgId,
        bot_id: botId,
        url: "https://github.com/acme/tools/tree/main/notes",
        commit: COMMIT,
        secrets: { NOTES_KEY: "key-123" },
        settings: { FOLDER: "Work" },
        device_id: deviceId,
      },
    });

  it("refuses someone else's computer", async () => {
    const res = await install(teammate.token, device.id);
    expect(res.status).toBe(403);
    expect((await j(res)).code).toBe("device_not_yours");
  });

  it("installs on the owner's computer: package there, tools listed through the tunnel", async () => {
    const res = await install(owner.token, device.id);
    const body = await j(res);
    expect(res.status, JSON.stringify(body)).toBe(201);
    pluginId = body.id;
    expect(body.runs_on).toMatchObject({
      device_id: device.id,
      device_name: "Oli's Mac",
      owner_user_id: owner.id,
      online: true,
    });
    expect(body.servers[0]).toMatchObject({ key: "notes", status: "ok" });
    expect(body.servers[0].tools.map((t: { name: string }) => t.name)).toEqual(["echo", "slow"]);
    expect(existsSync(join(home, ".casama/plugins/notes/server.dart"))).toBe(true);
    const [row] = await h.tdb.admin<
      { id: string; name: string; kind: string; config: Record<string, unknown> }[]
    >`select id, name, kind, config from public.integrations where plugin_id = ${pluginId}`;
    expect(row?.kind).toBe("local_mcp");
    // The secret stays in Vault, never in the config.
    expect(JSON.stringify(row?.config)).not.toContain("key-123");
    integration = { id: row?.id as string, name: row?.name as string, config: row?.config ?? {} };
    // The person's own server list doesn't pick it up or remove it.
    const own = await j(
      await h.request(`/v1/local-devices/${device.id}/mcp-servers`, {
        method: "PUT",
        token: owner.token,
        json: { servers: [] },
      }),
    );
    expect(own.items).toEqual([]);
    expect(
      (await h.tdb.admin`select 1 from public.integrations where id = ${integration.id}`).length,
    ).toBe(1);
  }, 120_000);

  it("calls the tools in the owner's runs, with secrets and settings resolved there", async () => {
    const a = adapterFor(await run(owner.id));
    expect(await a.callTool("echo", { text: "hi" })).toBe("echo: hi");
    expect(await a.callTool("env", { name: "NOTES_KEY" })).toBe("key-123");
    expect(await a.callTool("env", { name: "NOTES_FOLDER" })).toBe("Work");
    expect(await a.callTool("env", { name: "NOTES_CACHE" })).toBe(
      join(home, ".casama/plugin-data/notes/cache"),
    );
    await a.close?.();
  }, 60_000);

  it("tells other people's runs why the tools aren't there", async () => {
    expect(await othersComputerToolsHint(h.deps.db, botId, owner.id)).toBeNull();
    expect(await othersComputerToolsHint(h.deps.db, botId, teammate.id)).toMatch(
      /only that person can use them.*notes \(on .+'s computer\)/,
    );
  });

  it("refuses anyone else's runs with a plain reason", async () => {
    const a = adapterFor(await run(teammate.id));
    await expect(a.callTool("echo", { text: "x" })).rejects.toThrow(/not allowed|own computer/);
    await a.close?.();
  }, 60_000);

  it("says the computer is offline, then works again once it reconnects", async () => {
    await fake.close();
    await waitFor(() => !h.deps.devices?.online(device.computer_id));
    const off = adapterFor(await run(owner.id));
    await expect(off.callTool("echo", { text: "x" })).rejects.toThrow(/offline/);
    await off.close?.();
    // A fresh computerd knows nothing; the API hands the plugin over again when it connects.
    fake = await connect();
    const back = adapterFor(await run(owner.id));
    let text = "";
    await waitFor(async () => {
      text = await back.callTool("echo", { text: "again" }).catch(() => "");
      return text === "echo: again";
    });
    expect(text).toBe("echo: again");
    await back.close?.();
  }, 120_000);

  it("only the owner changes it; anyone who manages the bot can remove it, from the computer too", async () => {
    const denied = await h.request(`/v1/plugins/${pluginId}/settings`, {
      method: "PATCH",
      token: teammate.token,
      json: { settings: { FOLDER: "Home" } },
    });
    expect(denied.status).toBe(403);
    const ok = await h.request(`/v1/plugins/${pluginId}/settings`, {
      method: "PATCH",
      token: owner.token,
      json: { settings: { FOLDER: "Home" } },
    });
    expect(ok.status).toBe(200);
    const a = adapterFor(await run(owner.id));
    expect(await a.callTool("env", { name: "NOTES_FOLDER" })).toBe("Home");
    await a.close?.();

    const removed = await h.request(`/v1/plugins/${pluginId}`, {
      method: "DELETE",
      token: teammate.token,
    });
    expect(removed.status).toBe(200);
    expect(existsSync(join(home, ".casama/plugins/notes"))).toBe(false);
    const gone = adapterFor(await run(owner.id));
    await expect(gone.callTool("echo", { text: "x" })).rejects.toThrow();
    await gone.close?.();
  }, 120_000);
});
