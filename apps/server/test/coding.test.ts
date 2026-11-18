/** Coding agents (D-097): coding.delegate on the bot's computer, the user's computer, and the cloud. */
import { createServer, type Server } from "node:http";
import type { AddressInfo } from "node:net";
import {
  type ComputerService,
  changedPaths,
  commitSubject,
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
function fakeHandle(opts: { installed?: boolean; status?: string[] } = {}) {
  const ran: Array<{ cmd: string; opts?: ExecOptions }> = [];
  let installed = opts.installed ?? false;
  // `git status` answers in order: before the agent runs, then after.
  const status = [...(opts.status ?? [])];
  const handle = {
    ref: "fake",
    async *exec(cmd: string, o?: ExecOptions): AsyncIterable<ExecChunk> {
      ran.push({ cmd, opts: o });
      let out = "";
      let code = 0;
      if (cmd.startsWith("claude -p 'hang'")) {
        // A long agent: ends only when the caller's signal aborts.
        await new Promise<void>((resolve) =>
          o?.signal?.addEventListener("abort", () => resolve(), { once: true }),
        );
        code = 137;
      } else if (cmd.startsWith("command -v")) code = installed ? 0 : 1;
      else if (cmd.startsWith("npm install")) installed = true;
      else if (cmd.startsWith("claude -p"))
        out =
          'thinking…\n{"type":"result","result":"Fixed the failing test in sum.ts","is_error":false}\n';
      else if (cmd.includes("t3 thread start . 'ask'")) {
        out = '{"threadId":"t1","status":"waiting","reply":"Which port?","error":null}\n';
        code = 2;
      } else if (cmd.includes("t3 thread start"))
        out =
          '{"threadId":"t1","runId":"r1","status":"completed","reply":"Added the test.","error":null}\n';
      else if (cmd.startsWith("git status")) out = status.shift() ?? "";
      else if (cmd.startsWith("git add")) out = "b1c2d3e\n";
      else if (cmd.startsWith("git rev-parse")) out = `${"a".repeat(40)}\n`;
      else if (cmd.startsWith("git diff")) out = " sum.ts | 2 +-\n 1 file changed\n";
      else if (cmd.startsWith("git ls-files")) out = "notes.md\n";

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
    expect(
      summarizeAgentOutput(
        "exec\nhook: PostToolUse Completed\n<<<casama-agent-result>>>\nAdded the checkbox and a test.\n",
      ).text,
    ).toBe("Added the checkbox and a test.");
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
      "git rev-parse",
      "claude -p",
      "git diff",
      "git ls-files",
    ]);
    // An existing branch is checked out as it is; `-B` would reset it and drop its commits.
    const checkout = ran.find((x) => x.cmd.startsWith("git checkout"))!;
    expect(checkout.cmd).not.toContain("-B");
    expect(checkout.cmd).toBe("git checkout 'fix/test' 2>/dev/null || git checkout -b 'fix/test'");
    // Changes count from where the agent started, so its commits are reported too.
    expect(ran.find((x) => x.cmd.startsWith("git diff"))!.cmd).toContain(
      `--stat ${"a".repeat(40)}`,
    );
    expect(r.content).toContain("New files (not committed):\nnotes.md");
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
    ).rejects.toThrow(/OPENAI_API_KEY \(Settings → Advanced → Secrets\)/);
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
    // Its sandbox lets it run tests and git without a prompt, writing only inside the project.
    expect(claude.cmd).toContain('"sandbox":{"enabled":true,"autoAllowBashIfSandboxed":true}');
    expect(claude.opts?.env).toEqual({});
    expect(ran.some((x) => x.cmd.startsWith("npm install"))).toBe(false);
    expect(r.content).toContain("on your computer");
  });

  it("runs Codex with flags current Codex accepts", async () => {
    const { handle, ran } = fakeHandle({ installed: true });
    const comps = await h.tdb.admin<{ id: string }[]>`
      select computer_id as id from public.local_devices where user_id = ${owner.id} limit 1`;
    const computers = {
      ensureRunning: async (id: string) => (id === comps[0]!.id ? handle : null),
    } as unknown as ComputerService;
    await tool(computers).execute(
      { agent: "codex", task: "Add a test", where: "my_computer", folder: "/Users/me/Shared/app" },
      ctx().ctx as never,
    );
    const codex = ran.find((x) => x.cmd.includes("codex exec"))!;
    expect(codex.cmd).toContain("--sandbox workspace-write");
    expect(codex.cmd).not.toContain("--full-auto"); // removed in codex-cli 0.169
    // Its final message, not the tail of its logs, is the summary.
    expect(codex.cmd).toContain('-o "$f"');
    // No branch: nothing is committed for it.
    expect(ran.some((x) => x.cmd.startsWith("git status") || x.cmd.startsWith("git add"))).toBe(
      false,
    );
  });

  it("commits Codex's changes on the branch, leaving files changed before it alone", async () => {
    const { handle, ran } = fakeHandle({
      installed: true,
      status: [
        "A  docs/GUIDE.md\0",
        "A  docs/GUIDE.md\0 M index.html\0?? it's new.txt\0R  b.js\0a.js\0",
      ],
    });
    const comps = await h.tdb.admin<{ id: string }[]>`
      select computer_id as id from public.local_devices where user_id = ${owner.id} limit 1`;
    const computers = {
      ensureRunning: async (id: string) => (id === comps[0]!.id ? handle : null),
    } as unknown as ComputerService;
    const r = await tool(computers).execute(
      {
        agent: "codex",
        task: "Add a split evenly note",
        where: "my_computer",
        folder: "/Users/me/Shared/app",
        branch: "claude-tip",
      },
      ctx().ctx as never,
    );
    const codex = ran.find((x) => x.cmd.includes("codex exec"))!;
    expect(codex.cmd).toContain("Casama commits your changes on claude-tip");
    const commit = ran.find((x) => x.cmd.startsWith("git add"))!;
    expect(commit.cmd).toContain(
      "git add -A -- 'index.html' 'it'\\''s new.txt' 'b.js' && git commit -q -m ",
    );
    expect(commit.cmd).toContain(
      "-- 'index.html' 'it'\\''s new.txt' 'b.js' && git rev-parse --short HEAD",
    );
    expect(commit.cmd).not.toContain("GUIDE.md");
    expect(commit.cmd).toContain("Made by Codex through Casama.");
    expect(r.content).toContain("Committed b1c2d3e on claude-tip for Codex (3 files).");
    expect(r.content).toContain(
      "Left uncommitted (already changed before Codex started):\ndocs/GUIDE.md",
    );
  });

  it("runs Pi on the user's computer only", async () => {
    const comps = await h.tdb.admin<{ id: string }[]>`
      select computer_id as id from public.local_devices where user_id = ${owner.id} limit 1`;
    const { handle, ran } = fakeHandle({ installed: true });
    const computers = {
      ensureRunning: async (id: string) => (id === comps[0]!.id ? handle : null),
    } as unknown as ComputerService;
    await tool(computers).execute(
      { agent: "pi", task: "Add a test", where: "my_computer", folder: "/Users/me/Shared/app" },
      ctx().ctx as never,
    );
    expect(ran.map((x) => x.cmd)).toContain("pi -p --no-session 'Add a test'");
    await expect(
      tool().execute(
        { agent: "pi", task: "x", where: "bot_computer" },
        ctx(fakeHandle({ installed: true }).handle).ctx as never,
      ),
    ).rejects.toThrow(/Pi runs only on the user's own computer/);
  });

  it("runs T3 Code on the user's computer only, in a T3 project", async () => {
    const comps = await h.tdb.admin<{ id: string }[]>`
      select computer_id as id from public.local_devices where user_id = ${owner.id} limit 1`;
    const { handle, ran } = fakeHandle({ installed: true });
    const computers = {
      ensureRunning: async (id: string) => (id === comps[0]!.id ? handle : null),
    } as unknown as ComputerService;
    const folder = "/Users/me/Shared/app";
    const r = await tool(computers).execute(
      { agent: "t3code", task: "Add a test", where: "my_computer", folder },
      ctx().ctx as never,
    );
    const start = ran.find((x) => x.cmd.includes("t3 thread start"))!;
    expect(start.cmd).toBe(
      "t3 thread list --json >/dev/null 2>&1 || t3 project add . >/dev/null 2>&1; t3 thread start . 'Add a test' --wait --json",
    );
    expect(start.opts?.cwd).toBe(folder);
    expect(r.content).toContain("T3 Code finished on your computer.");
    expect(r.content).toContain("Summary:\nAdded the test.");

    const asked = await tool(computers).execute(
      { agent: "t3code", task: "ask", where: "my_computer", folder },
      ctx().ctx as never,
    );
    expect(asked.content).toContain("T3 Code is waiting for an answer on your computer.");
    expect(asked.content).toContain("Which port?");
    expect(asked.content).toContain("answer it in its thread in T3 Code");

    await expect(
      tool(computers).execute(
        { agent: "t3code", task: "x", where: "my_computer" },
        ctx().ctx as never,
      ),
    ).rejects.toThrow(/T3 Code needs the project folder/);
    await expect(
      tool().execute(
        { agent: "t3code", task: "x", where: "bot_computer", folder },
        ctx(fakeHandle({ installed: true }).handle).ctx as never,
      ),
    ).rejects.toThrow(/T3 Code runs only on the user's own computer/);
  });

  it("reads T3 Code's reply and its error", () => {
    expect(
      summarizeAgentOutput('{"threadId":"t","status":"completed","reply":"done","error":null}'),
    ).toEqual({ text: "done", error: false });
    expect(
      summarizeAgentOutput(
        '{"threadId":"t","status":"failed","reply":null,"error":"rate limited"}',
      ),
    ).toEqual({ text: "rate limited", error: true });
  });

  it("parses git status and makes commit subjects", () => {
    expect([...changedPaths(" M a.ts\0?? dir/b c.md\0R  new.ts\0old.ts\0")]).toEqual([
      "a.ts",
      "dir/b c.md",
      "new.ts",
    ]);
    expect(commitSubject("\n**Split evenly** note added. Tests pass.\nMore", "Codex")).toBe(
      "Split evenly note added. Tests pass.",
    );
    expect(commitSubject("", "Codex")).toBe("Changes by Codex");
    expect(commitSubject("x".repeat(100), "Codex")).toHaveLength(72);
  });

  it("stops the agent when the run is cancelled", async () => {
    const { handle, ran } = fakeHandle({ installed: true });
    const reg = new ToolRegistry();
    registerCodingTools(reg, { db: h.handle.db, cursorApiUrl: cursorUrl, pollSeconds: 0.01 });
    // The agent's command for this test: one that runs until it's stopped.
    const ctrl = new AbortController();
    const c = { ...ctx(handle).ctx, signal: ctrl.signal };
    const agentRun = reg
      .get("coding.delegate")!
      .execute({ agent: "claude_code", task: "hang", where: "bot_computer" }, c as never);
    await new Promise((r) => setTimeout(r, 50));
    ctrl.abort(new Error("cancelled"));
    await agentRun.catch(() => {});
    const agent = ran.find((x) => x.cmd.startsWith("claude -p"))!;
    expect(agent.opts?.signal?.aborted).toBe(true);
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
