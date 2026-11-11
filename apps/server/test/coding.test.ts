/** Coding agents (D-097): coding.delegate on the bot's computer, the user's computer, and the cloud. */
import { createServer, type Server } from "node:http";
import type { AddressInfo } from "node:net";
import {
  type ComputerService,
  registerCodingTools,
  summarizeAgentOutput,
  ToolRegistry,
} from "@casama/agent";
import type { ExecChunk, ExecOptions, SandboxHandle } from "@casama/sandbox";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
let owner: { id: string; token: string };
let orgId: string;
let botId: string;
let runId: string;
let cursor: Server;
let cursorUrl: string;
const cursorCalls: Array<{ method: string; path: string; body: unknown }> = [];

/** A computer that answers known commands and records what ran. */
function fakeHandle(opts: { installed?: boolean } = {}) {
  const ran: Array<{ cmd: string; opts?: ExecOptions }> = [];
  let installed = opts.installed ?? false;
  const handle = {
    ref: "fake",
    async *exec(cmd: string, o?: ExecOptions): AsyncIterable<ExecChunk> {
      ran.push({ cmd, opts: o });
      let out = "";
      let code = 0;
      if (cmd.startsWith("command -v")) code = installed ? 0 : 1;
      else if (cmd.startsWith("npm install")) installed = true;
      else if (cmd.startsWith("claude -p"))
        out =
          'thinking…\n{"type":"result","result":"Fixed the failing test in sum.ts","is_error":false}\n';
      else if (cmd.startsWith("git diff")) out = " sum.ts | 2 +-\n 1 file changed\n";
      yield { type: "stdout", data: out };
      yield { type: "exit", code, timedOut: false, killed: false, truncated: false };
    },
  } as unknown as SandboxHandle;
  return { handle, ran };
}

function ctx(computer?: SandboxHandle) {
  const output: string[] = [];
  return {
    output,
    ctx: {
      runId,
      botId,
      orgId,
      output: async (c: string) => void output.push(c),
      emit: async () => {},
      computer: computer ? async () => computer : undefined,
    },
  };
}

beforeAll(async () => {
  let polls = 0;
  cursor = createServer(async (req, res) => {
    const chunks: Buffer[] = [];
    for await (const c of req) chunks.push(c as Buffer);
    const body = chunks.length ? JSON.parse(Buffer.concat(chunks).toString()) : undefined;
    cursorCalls.push({ method: req.method ?? "", path: req.url ?? "", body });
    res.setHeader("content-type", "application/json");
    if (req.headers.authorization !== "Bearer cursor-key-123") return res.writeHead(401).end("{}");
    if (req.method === "POST") return res.end(JSON.stringify({ id: "bc-1", status: "CREATING" }));
    polls++;
    res.end(
      JSON.stringify(
        polls < 2
          ? { id: "bc-1", status: "RUNNING" }
          : {
              id: "bc-1",
              status: "FINISHED",
              summary: "Added input validation",
              target: {
                prUrl: "https://github.com/acme/app/pull/7",
                branchName: "cursor/validation",
              },
            },
      ),
    );
  }).listen(0, "127.0.0.1");
  await new Promise((r) => cursor.once("listening", r));
  cursorUrl = `http://127.0.0.1:${(cursor.address() as AddressInfo).port}`;
  h = await startHarness();
  owner = await h.user("coding-owner@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "Code" } }),
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
          name: "Dev",
          model_policy: { primary: { credential_id: cred.id, model: "m" } },
        },
      }),
    )
  ).id;
  for (const [name, value, host] of [
    ["ANTHROPIC_API_KEY", "sk-ant-secret-1", "api.anthropic.com"],
    ["CURSOR_API_KEY", "cursor-key-123", "api.cursor.com"],
  ])
    await h.request("/v1/secrets", {
      method: "POST",
      token: owner.token,
      json: { org_id: orgId, name, value, allowed_hosts: [host] },
    });
  const [run] = await h.tdb.admin<{ id: string }[]>`
    insert into public.runs (org_id, bot_id, trigger, status, created_by)
    values (${orgId}, ${botId}, 'chat', 'running', ${owner.id}) returning id`;
  runId = run!.id;
}, 60_000);
afterAll(async () => {
  await h?.stop();
  cursor?.close();
});

const tool = (computers?: ComputerService) => {
  const reg = new ToolRegistry();
  registerCodingTools(reg, {
    db: h.handle.db,
    computers,
    cursorApiUrl: cursorUrl,
    pollSeconds: 0.01,
  });
  return reg.get("coding.delegate")!;
};

describe("coding.delegate", () => {
  it("reads an agent's JSON result or the tail of its output", () => {
    expect(summarizeAgentOutput('x\n{"result":"done","is_error":false}').text).toBe("done");
    expect(summarizeAgentOutput("plain output\nall good").text).toBe("plain output\nall good");
  });

  it("runs Claude Code on the bot's computer: installs it, passes the key only to that process", async () => {
    const { handle, ran } = fakeHandle();
    const { ctx: c, output } = ctx(handle);
    const r = await tool().execute(
      {
        agent: "claude_code",
        task: "Fix the failing test",
        where: "bot_computer",
        folder: "app",
        branch: "fix/test",
      },
      c as never,
    );
    expect(ran.map((x) => x.cmd.split(" ").slice(0, 2).join(" "))).toEqual([
      "command -v",
      "npm install",
      "git checkout",
      "claude -p",
      "git diff",
    ]);
    const claude = ran.find((x) => x.cmd.startsWith("claude -p"))!;
    expect(claude.cmd).toContain("--dangerously-skip-permissions");
    expect(claude.opts?.env).toEqual({ ANTHROPIC_API_KEY: "sk-ant-secret-1" });
    expect(claude.opts?.cwd).toBe("app");
    expect(r.content).toContain("Claude Code finished on the bot's computer");
    expect(r.content).toContain("Fixed the failing test in sum.ts");
    expect(r.content).toContain("sum.ts | 2 +-");
    expect(output.join("")).toContain("Installing Claude Code");
  });

  it("asks for the key when the secret is missing", async () => {
    const { handle } = fakeHandle({ installed: true });
    await expect(
      tool().execute(
        { agent: "codex", task: "x", where: "bot_computer" },
        ctx(handle).ctx as never,
      ),
    ).rejects.toThrow(/OPENAI_API_KEY/);
  });

  it("runs on the user's own computer through the companion, with their sign-ins", async () => {
    const [comp] = await h.tdb.admin<{ id: string }[]>`
      insert into public.computers (org_id, kind, name, provider) values (${orgId}, 'local', 'Laptop', 'local') returning id`;
    await h.tdb.admin`
      insert into public.local_devices (org_id, user_id, computer_id, name, platform, token_hash, enabled, allowed_bot_ids)
      values (${orgId}, ${owner.id}, ${comp!.id}, 'Laptop', 'macos', 'h', true, ${[botId]})`;
    const { handle, ran } = fakeHandle({ installed: true });
    const computers = {
      ensureRunning: async (id: string) => (id === comp!.id ? handle : null),
    } as unknown as ComputerService;
    const r = await tool(computers).execute(
      {
        agent: "claude_code",
        task: "Refactor",
        where: "my_computer",
        folder: "/Users/me/Shared/app",
      },
      ctx().ctx as never,
    );
    const claude = ran.find((x) => x.cmd.startsWith("claude -p"))!;
    expect(claude.cmd).toContain("--permission-mode acceptEdits");
    expect(claude.opts?.env).toEqual({});
    expect(ran.some((x) => x.cmd.startsWith("npm install"))).toBe(false);
    expect(r.content).toContain("on your computer");
  });

  it("starts a Cursor cloud agent, follows it and reports the pull request", async () => {
    const { ctx: c, output } = ctx();
    const r = await tool().execute(
      {
        agent: "cursor",
        task: "Add validation",
        where: "cloud",
        repo: "https://github.com/acme/app",
        open_pr: true,
      },
      c as never,
    );
    expect(cursorCalls[0]).toMatchObject({
      method: "POST",
      path: "/v0/agents",
      body: {
        prompt: { text: "Add validation" },
        source: { repository: "https://github.com/acme/app" },
        target: { autoCreatePr: true },
      },
    });
    expect(r.content).toContain("https://github.com/acme/app/pull/7");
    expect(output.join("")).toContain("Status: FINISHED");
  });

  it("raises the risk when a pull request may be opened", () => {
    const t = tool();
    expect(
      t.riskFor?.({ agent: "cursor", task: "x", where: "cloud", open_pr: true } as never),
    ).toBe("high");
    expect(t.riskFor?.({ agent: "codex", task: "x", where: "bot_computer" } as never)).toBe(
      "medium",
    );
  });
});
