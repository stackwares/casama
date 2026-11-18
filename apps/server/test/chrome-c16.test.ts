/**
 * Casama for Chrome Phase 4, C16 (D-323): coding agents on the person's computer check their work in
 * the person's own browser, through /mcp/browser. A fake browser device stands in for the
 * extension; coding.delegate runs against a fake computer.
 */
import { type ComputerService, registerCodingTools, ToolRegistry } from "@casama/agent";
import { signBrowserMcpToken, verifyBrowserMcpToken } from "@casama/domain";
import type { ExecChunk, ExecOptions, SandboxHandle } from "@casama/sandbox";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { WebSocket } from "ws";
import { internalToken } from "../src/api/routes/local.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

type Call = { action: string; args: Record<string, unknown>; run?: { id: string } };

async function fakeBrowser(serverUrl: string, token: string) {
  const calls: Call[] = [];
  const ws = new WebSocket(`${serverUrl.replace("http", "ws")}/v1/local-computer/connect`, {
    headers: { authorization: `Device ${token}` },
  });
  await new Promise<void>((resolve, reject) => {
    ws.once("message", () => resolve());
    ws.once("error", reject);
  });
  let url = "about:blank";
  ws.on("message", (raw) => {
    const m = JSON.parse(String(raw)) as { type: string; id: string; body?: string };
    if (m.type !== "request") return;
    const call = JSON.parse(Buffer.from(m.body ?? "", "base64").toString()) as Call;
    calls.push(call);
    if (call.action === "open") url = String(call.args.url);
    const answer =
      call.action === "screenshot"
        ? {
            ok: true,
            text: "Screenshot",
            image: { data: "iVBORw0KGgo=", media_type: "image/png" },
            url,
          }
        : call.action === "console"
          ? { ok: true, text: "error: TypeError: total is undefined (app.js:12)", url }
          : { ok: true, text: `${call.action} done`, url };
    const body = Buffer.from(JSON.stringify(answer)).toString("base64");
    ws.send(JSON.stringify({ type: "response", id: m.id, status: 200, headers: {} }));
    ws.send(JSON.stringify({ type: "chunk", id: m.id, data: body }));
    ws.send(JSON.stringify({ type: "end", id: m.id }));
  });
  return {
    calls,
    close: () =>
      ws.readyState === ws.CLOSED
        ? Promise.resolve()
        : new Promise<void>((r) => (ws.once("close", () => r()), ws.close())),
  };
}

describe("Casama for Chrome C16: coding agents use your browser", () => {
  let h: Harness;
  let owner: { id: string; token: string };
  let member: { id: string; token: string };
  let orgId: string;
  let botId: string;
  let device: { id: string; token: string };
  let browser: Awaited<ReturnType<typeof fakeBrowser>>;
  let secret: string;
  let runId: string;
  const newRun = async (by: string, status = "running") =>
    (
      await h.tdb.admin<{ id: string }[]>`
        insert into public.runs (org_id, bot_id, trigger, status, created_by)
        values (${orgId}, ${botId}, 'chat', ${status}, ${by}) returning id`
    )[0]!.id;
  const rpc = (token: string | null, body: unknown, method = "POST") =>
    fetch(`${h.serverUrl}/mcp/browser`, {
      method,
      headers: {
        "content-type": "application/json",
        accept: "application/json, text/event-stream",
        ...(token ? { authorization: `Bearer ${token}` } : {}),
      },
      ...(method === "POST" ? { body: JSON.stringify(body) } : {}),
    });
  const tokenFor = (run: string, exp = Math.floor(Date.now() / 1000) + 600) =>
    signBrowserMcpToken({ run, device: device.id, exp }, secret);

  beforeAll(async () => {
    h = await startHarness({ local: true });
    secret = internalToken(h.deps.env);
    owner = await h.user("c16-owner@example.com");
    member = await h.user("c16-member@example.com");
    orgId = (
      await j(
        await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "C16" } }),
      )
    ).id;
    await h.tdb
      .admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${member.id}, 'member')`;
    const cred = await j(
      await h.request("/v1/credentials", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, provider: "openrouter", label: "k", api_key: "sk-c16-key" },
      }),
    );
    botId = (
      await j(
        await h.request("/v1/bots", {
          method: "POST",
          token: owner.token,
          json: {
            org_id: orgId,
            name: "Dev",
            model_policy: { primary: { credential_id: cred.id, model: "m" } },
          },
        }),
      )
    ).id;
    device = await j(
      await h.request("/v1/local-devices", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, name: "Chrome", platform: "chrome" },
      }),
    );
    await h.request(`/v1/local-devices/${device.id}`, {
      method: "PATCH",
      token: owner.token,
      json: { allowed_bot_ids: [botId] },
    });
    browser = await fakeBrowser(h.serverUrl as string, device.token);
    runId = await newRun(owner.id);
  }, 120_000);
  afterAll(async () => {
    await browser?.close().catch(() => {});
    await h?.stop();
  });

  it("signs tokens that name the run and the browser, and refuses forged or expired ones", () => {
    const t = tokenFor(runId);
    expect(verifyBrowserMcpToken(t, secret)).toMatchObject({ run: runId, device: device.id });
    expect(verifyBrowserMcpToken(t, "another-secret")).toBeNull();
    expect(verifyBrowserMcpToken(`${t.slice(0, -2)}xx`, secret)).toBeNull();
    expect(
      verifyBrowserMcpToken(tokenFor(runId, Math.floor(Date.now() / 1000) - 1), secret),
    ).toBeNull();
    expect(verifyBrowserMcpToken("kmcp_abc", secret)).toBeNull();
  });

  it("speaks MCP: initialize, tools/list and tools/call reach the person's browser", async () => {
    const t = tokenFor(runId);
    const init = await j(
      await rpc(t, {
        jsonrpc: "2.0",
        id: 1,
        method: "initialize",
        params: { protocolVersion: "2025-06-18" },
      }),
    );
    expect(init.result).toMatchObject({
      protocolVersion: "2025-06-18",
      capabilities: { tools: {} },
      serverInfo: { name: "casama-browser" },
    });
    expect((await rpc(t, { jsonrpc: "2.0", method: "notifications/initialized" })).status).toBe(
      202,
    );
    const list = await j(await rpc(t, { jsonrpc: "2.0", id: 2, method: "tools/list" }));
    const names = list.result.tools.map((x: { name: string }) => x.name);
    expect(names).toEqual(
      expect.arrayContaining(["open", "snapshot", "click", "screenshot", "console"]),
    );
    expect(names).not.toContain("upload");
    expect(
      list.result.tools.find((x: { name: string }) => x.name === "read").annotations,
    ).toMatchObject({
      readOnlyHint: true,
    });

    const opened = await j(
      await rpc(t, {
        jsonrpc: "2.0",
        id: 3,
        method: "tools/call",
        params: { name: "open", arguments: { url: "http://localhost:5173/" } },
      }),
    );
    expect(opened.result.content[0]).toEqual({ type: "text", text: "open done" });
    expect(browser.calls.at(-1)).toMatchObject({
      action: "open",
      args: { url: "http://localhost:5173/" },
      run: { id: runId },
    });
    const shot = await j(
      await rpc(t, {
        jsonrpc: "2.0",
        id: 4,
        method: "tools/call",
        params: { name: "screenshot", arguments: {} },
      }),
    );
    expect(shot.result.content[1]).toEqual({
      type: "image",
      data: "iVBORw0KGgo=",
      mimeType: "image/png",
    });
    const clicked = await j(
      await rpc(t, {
        jsonrpc: "2.0",
        id: 5,
        method: "tools/call",
        params: { name: "click", arguments: { ref: "e2" } },
      }),
    );
    expect(clicked.result.isError).toBeUndefined();
    expect(browser.calls.at(-1)?.args.ref).toBe("@e2");
    // Casama's own pages stay off limits, as for a bot.
    const casama = await j(
      await rpc(t, {
        jsonrpc: "2.0",
        id: 6,
        method: "tools/call",
        params: { name: "open", arguments: { url: "https://app.casama.ai/settings" } },
      }),
    );
    expect(casama.result.isError).toBe(true);
    expect(casama.result.content[0].text).toMatch(/Casama's own pages/);
    const unknown = await j(
      await rpc(t, {
        jsonrpc: "2.0",
        id: 7,
        method: "tools/call",
        params: { name: "upload", arguments: {} },
      }),
    );
    expect(unknown.error.code).toBe(-32602);
  });

  it("refuses without a token, with a forged one, after the run ends, and for someone else's run", async () => {
    expect((await rpc(null, { jsonrpc: "2.0", id: 1, method: "tools/list" })).status).toBe(401);
    expect(
      (await rpc("kbmcp_forged.x", { jsonrpc: "2.0", id: 1, method: "tools/list" })).status,
    ).toBe(401);
    expect((await rpc(tokenFor(runId), null, "GET")).status).toBe(405);
    // No batches: one call at a time.
    const batch = await rpc(tokenFor(runId), [
      {
        jsonrpc: "2.0",
        id: 1,
        method: "tools/call",
        params: { name: "open", arguments: { url: "https://a.example/" } },
      },
      {
        jsonrpc: "2.0",
        id: 2,
        method: "tools/call",
        params: { name: "open", arguments: { url: "https://b.example/" } },
      },
    ]);
    expect(batch.status).toBe(400);
    const done = await newRun(owner.id, "completed");
    expect(
      (await rpc(tokenFor(done), { jsonrpc: "2.0", id: 1, method: "tools/list" })).status,
    ).toBe(401);
    // A member's run, with a token somehow naming the owner's browser: the tunnel's owner check.
    const theirs = await newRun(member.id);
    const before = browser.calls.length;
    const r = await j(
      await rpc(tokenFor(theirs), {
        jsonrpc: "2.0",
        id: 1,
        method: "tools/call",
        params: { name: "read", arguments: {} },
      }),
    );
    expect(r.result.isError).toBe(true);
    expect(r.result.content[0].text).toMatch(/owner/);
    expect(browser.calls.length).toBe(before);
  });

  it("coding.delegate gives Claude Code and Codex on the person's computer the browser, token kept off the command line", async () => {
    const [comp] = await h.tdb.admin<{ id: string }[]>`
      insert into public.computers (org_id, kind, name, provider) values (${orgId}, 'local', 'Laptop', 'local') returning id`;
    await h.tdb.admin`
      insert into public.local_devices (org_id, user_id, computer_id, name, platform, token_hash, enabled, allowed_bot_ids, last_seen_at)
      values (${orgId}, ${owner.id}, ${comp!.id}, 'Laptop', 'macos', 'h-c16', true, ${[botId]}, now() - interval '1 hour')`;
    const ran: Array<{ cmd: string; opts?: ExecOptions }> = [];
    const handle = {
      ref: "fake",
      async *exec(cmd: string, o?: ExecOptions): AsyncIterable<ExecChunk> {
        ran.push({ cmd, opts: o });
        const out = cmd.startsWith("claude -p")
          ? '{"type":"result","result":"Fixed the total and checked it in the browser","is_error":false}\n'
          : "";
        yield { type: "stdout", data: out };
        yield { type: "exit", code: 0, timedOut: false, killed: false, truncated: false };
      },
    } as unknown as SandboxHandle;
    const computers = {
      ensureRunning: async (id: string) => (id === comp!.id ? handle : null),
    } as unknown as ComputerService;
    const reg = new ToolRegistry();
    registerCodingTools(reg, {
      db: h.handle.db,
      computers,
      browserMcp: {
        publicApiUrl: h.serverUrl as string,
        tunnel: { apiUrl: h.serverUrl as string, internalToken: secret },
      },
    });
    const ctx = {
      runId,
      botId,
      orgId,
      output: async () => {},
      emit: async () => {},
    };
    const r = await reg
      .get("coding.delegate")!
      .execute(
        { agent: "claude_code", task: "Fix the cart total", where: "my_computer" },
        ctx as never,
      );
    const claude = ran.find((x) => x.cmd.startsWith("claude -p"))!;
    expect(claude.cmd).toContain("--mcp-config");
    expect(claude.cmd).toContain(`${h.serverUrl}/mcp/browser`);
    expect(claude.cmd).toContain("--allowedTools mcp__casama_browser");
    expect(claude.cmd).toContain("${CASAMA_BROWSER_TOKEN}");
    expect(claude.cmd).toContain("casama_browser tools");
    const token = claude.opts?.env?.CASAMA_BROWSER_TOKEN as string;
    expect(token).toMatch(/^kbmcp_/);
    expect(claude.cmd).not.toContain(token);
    expect(verifyBrowserMcpToken(token, secret)).toMatchObject({ run: runId, device: device.id });
    expect(r.content).toContain("could use your browser");
    // The token works on the endpoint.
    const list = await j(await rpc(token, { jsonrpc: "2.0", id: 1, method: "tools/list" }));
    expect(list.result.tools.length).toBeGreaterThan(5);

    ran.length = 0;
    await reg
      .get("coding.delegate")!
      .execute({ agent: "codex", task: "Add a test", where: "my_computer" }, ctx as never);
    const codex = ran.find((x) => x.cmd.includes("codex exec"))!;
    expect(codex.cmd).toContain(`mcp_servers.casama_browser.url="${h.serverUrl}/mcp/browser"`);
    expect(codex.cmd).toContain(
      'mcp_servers.casama_browser.bearer_token_env_var="CASAMA_BROWSER_TOKEN"',
    );
    expect(codex.opts?.env?.CASAMA_BROWSER_TOKEN).toMatch(/^kbmcp_/);

    // Browser offline: nothing extra.
    await browser.close();
    ran.length = 0;
    await reg
      .get("coding.delegate")!
      .execute({ agent: "claude_code", task: "Again", where: "my_computer" }, ctx as never);
    const again = ran.find((x) => x.cmd.startsWith("claude -p"))!;
    expect(again.cmd).not.toContain("--mcp-config");
    expect(again.opts?.env?.CASAMA_BROWSER_TOKEN).toBeUndefined();
  }, 60_000);
});
