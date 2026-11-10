/**
 * Coding agents (SPEC: Post-v1 roadmap → Coding agents; D-097). `coding.delegate` hands a coding
 * task to Claude Code, Codex or Cursor's agent and reports a summary, diff stats and any pull
 * request link:
 * - my_computer: the run's owner's own computer through the desktop companion, with their own
 *   sign-ins (the companion's shell permission and shared folders apply);
 * - bot_computer: the bot's computer; the agent's CLI is installed on first use and its API key
 *   comes from a named secret, in that process's environment only;
 * - cloud: Cursor's cloud agents API, polled until the agent finishes.
 */
import type { Database } from "@kasama/db";
import type { SandboxHandle } from "@kasama/sandbox";
import { sql } from "drizzle-orm";
import { z } from "zod";
import type { ComputerService } from "../computers.ts";
import { loadSecrets } from "../secrets.ts";
import { runStreaming, shq } from "./computer.ts";
import { type ToolContext, ToolError, type ToolRegistry } from "./registry.ts";

export const CODING_AGENTS = {
  claude_code: {
    label: "Claude Code",
    bin: "claude",
    install: "npm install -g @anthropic-ai/claude-code",
    keyName: "ANTHROPIC_API_KEY",
    command: (task: string, local: boolean) =>
      `claude -p ${shq(task)} --output-format json ${local ? "--permission-mode acceptEdits" : "--dangerously-skip-permissions"}`,
  },
  codex: {
    label: "Codex",
    bin: "codex",
    install: "npm install -g @openai/codex",
    keyName: "OPENAI_API_KEY",
    command: (task: string) => `codex exec --full-auto ${shq(task)}`,
  },
  cursor: {
    label: "Cursor",
    bin: "cursor-agent",
    install: "curl -fsS https://cursor.com/install | bash",
    keyName: "CURSOR_API_KEY",
    command: (task: string) => `cursor-agent -p --force --output-format json ${shq(task)}`,
  },
} as const;
export type CodingAgent = keyof typeof CODING_AGENTS;

export interface CodingDeps {
  db: Database;
  computers?: ComputerService;
  fetch?: typeof fetch;
  /** Cursor's API (tests point it at a fake). */
  cursorApiUrl?: string;
  /** Seconds between cloud status checks (tests use less). */
  pollSeconds?: number;
}

/** The text an agent's output ends with: a JSON `result` when it prints one, else the tail. */
export function summarizeAgentOutput(out: string) {
  const lines = out.trim().split("\n").reverse();
  for (const line of lines) {
    const t = line.trim();
    if (!t.startsWith("{")) continue;
    try {
      const j = JSON.parse(t) as { result?: unknown; is_error?: boolean };
      if (typeof j.result === "string") return { text: j.result, error: j.is_error === true };
    } catch {
      // not JSON
    }
  }
  const tail = out.trim();
  return { text: tail.length > 3000 ? `…${tail.slice(-3000)}` : tail, error: false };
}

/** The person a run acts for (sender, routine creator, or a parent run's). */
async function actingUser(db: Database, runId: string) {
  const [r] = await db.execute<{ u: string | null }>(sql`
    with recursive up as (
      select x.id, x.parent_run_id, x.created_by, x.routine_id, 0 as depth from public.runs x where x.id = ${runId}::uuid
      union all
      select p.id, p.parent_run_id, p.created_by, p.routine_id, up.depth + 1
      from public.runs p join up on p.id = up.parent_run_id where up.depth < 8
    )
    select coalesce(up.created_by, rt.created_by) as u from up
    left join public.routines rt on rt.id = up.routine_id
    where coalesce(up.created_by, rt.created_by) is not null order by up.depth limit 1`);
  return r?.u ?? null;
}

async function cancelled(db: Database, runId: string) {
  const [r] = await db
    .execute<{ c: Date | null }>(
      sql`select cancel_requested_at as c from public.runs where id = ${runId}::uuid`,
    )
    .catch(() => [] as Array<{ c: Date | null }>);
  return !!r?.c;
}

const schema = z.object({
  agent: z.enum(["claude_code", "codex", "cursor"]),
  task: z.string().min(1).max(20_000),
  where: z.enum(["my_computer", "bot_computer", "cloud"]),
  folder: z
    .string()
    .max(1000)
    .optional()
    .describe("Project folder on the computer (my_computer: inside a shared folder)"),
  repo: z.string().max(500).optional().describe("cloud: the GitHub repository URL"),
  branch: z.string().max(200).optional().describe("Branch to work on (created if missing)"),
  open_pr: z.boolean().optional().describe("cloud: open a pull request when done"),
  timeout_min: z.number().int().min(1).max(120).optional(),
});

export function registerCodingTools(registry: ToolRegistry, deps: CodingDeps) {
  registry.register({
    name: "coding.delegate",
    description:
      "Hand a coding task to a coding agent (Claude Code, Codex or Cursor) and wait for its result: on the user's own computer (my_computer, through the desktop app, with their sign-ins), on your computer (bot_computer), or Cursor's cloud agents (cloud, needs repo). Returns a summary, the changed files and any pull request link. Be specific in the task.",
    risk: "medium",
    riskFor: (a: z.infer<typeof schema>) => (a.open_pr ? "high" : "medium"),
    untrustedOutput: true,
    schema,
    async execute(args, ctx) {
      const agent = CODING_AGENTS[args.agent];
      if (args.where === "cloud") return cloudCursor(deps, args, ctx);
      const local = args.where === "my_computer";
      const h = local ? await localHandle(deps, ctx, agent.label) : await botHandle(ctx);
      const cwd = args.folder;
      const env: Record<string, string> = {};
      const run = (cmd: string, timeoutMs = 120_000) =>
        runStreaming({ output: async () => {} }, h, cmd, { cwd, timeoutMs, env });
      if (!local) {
        // The bot's computer: install the CLI once, and pass its key from a named secret.
        const secret = (await loadSecrets(deps.db, ctx.orgId, ctx.botId)).find(
          (s) => s.name === agent.keyName,
        );
        if (!secret)
          throw new ToolError(
            "missing_secret",
            `Add a secret named ${agent.keyName} (Settings → Secrets) so ${agent.label} can run on the bot's computer.`,
          );
        env[agent.keyName] = secret.value;
        const has = await run(`command -v ${agent.bin}`);
        if (has.code !== 0) {
          await ctx.output(`Installing ${agent.label}…\n`);
          const inst = await run(agent.install, 600_000);
          if (inst.code !== 0)
            throw new ToolError(
              "install_failed",
              `Could not install ${agent.label}: ${inst.out.slice(-500)}`,
            );
        }
      } else {
        const has = await run(`command -v ${agent.bin}`);
        if (has.code !== 0)
          throw new ToolError(
            "agent_not_installed",
            `${agent.label} is not installed on your computer (the \`${agent.bin}\` command was not found).`,
          );
      }
      if (args.branch) {
        const b = await run(`git checkout -B ${shq(args.branch)}`);
        if (b.code !== 0)
          throw new ToolError(
            "git_failed",
            `Could not switch to ${args.branch}: ${b.out.slice(-300)}`,
          );
      }
      // Stop when the run is cancelled.
      const ctrl = new AbortController();
      const poll = setInterval(async () => {
        if (await cancelled(deps.db, ctx.runId)) ctrl.abort(new Error("cancelled"));
      }, 1000);
      let r: Awaited<ReturnType<typeof runStreaming>>;
      try {
        await ctx.output(`${agent.label} is working…\n`);
        r = await runStreaming(ctx, h, agent.command(args.task, local), {
          cwd,
          env,
          timeoutMs: (args.timeout_min ?? 30) * 60_000,
          signal: ctrl.signal,
        });
      } finally {
        clearInterval(poll);
      }
      const summary = summarizeAgentOutput(r.out);
      const diff = await run("git diff --stat HEAD 2>/dev/null | tail -n 30");
      const status = r.timedOut
        ? "timed out"
        : r.code === 0 && !summary.error
          ? "finished"
          : `failed (exit ${r.code})`;
      const parts = [
        `${agent.label} ${status}${local ? " on your computer" : " on the bot's computer"}.`,
        summary.text ? `\nSummary:\n${summary.text}` : "",
        diff.code === 0 && diff.out.trim() ? `\nChanged files:\n${diff.out.trim()}` : "",
        args.branch ? `\nBranch: ${args.branch}` : "",
      ];
      return {
        content: parts.join("\n"),
        preview: `${agent.label} ${status}: ${summary.text.replace(/\s+/g, " ").slice(0, 160)}`,
      };
    },
  });
}

async function botHandle(ctx: ToolContext): Promise<SandboxHandle> {
  if (!ctx.computer)
    throw new ToolError(
      "no_computer",
      "This bot has no computer. Use my_computer or cloud instead.",
    );
  return ctx.computer();
}

/** The run owner's own computer (desktop companion) that allows this bot. */
async function localHandle(
  deps: CodingDeps,
  ctx: ToolContext,
  label: string,
): Promise<SandboxHandle> {
  if (!deps.computers)
    throw new ToolError("no_computer", "Personal computers are not set up on this server.");
  const user = await actingUser(deps.db, ctx.runId);
  const [d] = await deps.db.execute<{ computer_id: string | null }>(sql`
    select computer_id from public.local_devices
    where org_id = ${ctx.orgId}::uuid and user_id = ${user}::uuid and enabled and ${ctx.botId}::uuid = any(allowed_bot_ids)
    order by last_seen_at desc nulls last limit 1`);
  if (!d?.computer_id)
    throw new ToolError(
      "no_local_computer",
      `To use ${label} on your computer, turn on "Use this computer for bots" in the desktop app and allow this bot there.`,
    );
  const h = await deps.computers.ensureRunning(d.computer_id).catch((err: unknown) => {
    throw new ToolError("device_offline", (err as Error).message);
  });
  return (
    h.withActivity?.({
      run_id: ctx.runId,
      bot: "",
      tool: "coding.delegate",
      summary: `${label} is working`,
    }) ?? h
  );
}

interface CursorAgent {
  id: string;
  status?: string;
  summary?: string;
  target?: { url?: string; prUrl?: string; branchName?: string };
}

async function cloudCursor(deps: CodingDeps, args: z.infer<typeof schema>, ctx: ToolContext) {
  if (args.agent !== "cursor")
    throw new ToolError(
      "cloud_unsupported",
      "Only Cursor's cloud agents are supported in the cloud. Use my_computer or bot_computer.",
    );
  if (!args.repo)
    throw new ToolError("repo_required", "Cloud agents need the GitHub repository (repo).");
  const key = (await loadSecrets(deps.db, ctx.orgId, ctx.botId)).find(
    (s) => s.name === "CURSOR_API_KEY",
  );
  if (!key)
    throw new ToolError(
      "missing_secret",
      "Add a secret named CURSOR_API_KEY (Settings → Secrets) to use Cursor's cloud agents.",
    );
  const base = (deps.cursorApiUrl ?? "https://api.cursor.com").replace(/\/$/, "");
  const f = deps.fetch ?? fetch;
  const call = async (method: string, path: string, body?: unknown) => {
    const res = await f(`${base}${path}`, {
      method,
      headers: { authorization: `Bearer ${key.value}`, "content-type": "application/json" },
      body: body ? JSON.stringify(body) : undefined,
      signal: AbortSignal.timeout(30_000),
    });
    const text = await res.text();
    if (!res.ok)
      throw new ToolError("cursor_error", `Cursor answered ${res.status}: ${text.slice(0, 300)}`);
    return (text ? JSON.parse(text) : {}) as CursorAgent;
  };
  const created = await call("POST", "/v0/agents", {
    prompt: { text: args.task },
    source: { repository: args.repo, ...(args.branch ? { ref: args.branch } : {}) },
    target: { autoCreatePr: args.open_pr === true },
  });
  await ctx.output(`Cursor cloud agent started (${created.id}).\n`);
  const deadline = Date.now() + (args.timeout_min ?? 60) * 60_000;
  let last = created.status ?? "";
  let agent = created;
  for (;;) {
    if (await cancelled(deps.db, ctx.runId)) {
      await call("DELETE", `/v0/agents/${created.id}`).catch(() => {});
      throw new ToolError("cancelled", "The run was cancelled; the cloud agent was stopped.");
    }
    if (Date.now() > deadline)
      throw new ToolError("timed_out", "The cloud agent did not finish in time.");
    await new Promise((r) => setTimeout(r, (deps.pollSeconds ?? 10) * 1000));
    agent = await call("GET", `/v0/agents/${created.id}`);
    if (agent.status && agent.status !== last) {
      last = agent.status;
      await ctx.output(`Status: ${agent.status}\n`);
    }
    if (["FINISHED", "ERROR", "EXPIRED", "CANCELLED"].includes(agent.status ?? "")) break;
  }
  const ok = agent.status === "FINISHED";
  const lines = [
    `Cursor cloud agent ${ok ? "finished" : (agent.status ?? "stopped").toLowerCase()}.`,
    agent.summary ? `\nSummary:\n${agent.summary}` : "",
    agent.target?.prUrl ? `\nPull request: ${agent.target.prUrl}` : "",
    agent.target?.branchName ? `\nBranch: ${agent.target.branchName}` : "",
    agent.target?.url ? `\nAgent: ${agent.target.url}` : "",
  ];
  return {
    content: lines.join("\n"),
    preview: `Cursor ${ok ? "finished" : agent.status}${agent.target?.prUrl ? `: ${agent.target.prUrl}` : ""}`,
  };
}
