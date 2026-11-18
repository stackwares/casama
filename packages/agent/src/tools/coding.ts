/**
 * Coding agents (SPEC: Post-v1 roadmap → Coding agents; D-097). `coding.delegate` hands a coding
 * task to a coding agent (Claude Code, Codex, Cursor's agent, Pi, T3 Code, Kimi Code, whatever the
 * catalog lists, D-370, or the person's own, D-371) and reports a summary, diff stats and any pull
 * request link:
 * - my_computer: the run's owner's own computer through the desktop companion, with their own
 *   sign-ins (the companion's shell permission and shared folders apply; an agent beyond the
 *   built-in five needs one Allow on that computer);
 * - bot_computer: the bot's computer; the agent's CLI is installed on first use and its API key
 *   comes from a named secret, in that process's environment only;
 * - cloud: Cursor's cloud agents API, polled until the agent finishes.
 */
import type { Database } from "@casama/db";
import {
  AGENT_RESULT_MARKER,
  BROWSER_MCP_HINT,
  builtInCodingAgents,
  type CodingAgentSpec,
  describeCodingAgents,
  OWN_AGENT_PREFIX,
  ownCodingAgentSpec,
  PREALLOWED_CODING_AGENTS,
  renderCodingCommand,
  signBrowserMcpToken,
  summarizeAgentOutput,
} from "@casama/domain";
import type { SandboxHandle } from "@casama/sandbox";
import { sql } from "drizzle-orm";
import { z } from "zod";
import { actingUserOf } from "../acting.ts";
import type { ComputerService } from "../computers.ts";
import { loadSecrets } from "../secrets.ts";
import { browserDevicesFor, firstOnline, mineAllowed, type TunnelDeps } from "../user-browser.ts";
import { runStreaming, shq } from "./computer.ts";
import { type ToolContext, ToolError, type ToolRegistry } from "./registry.ts";

/** The environment variable that carries the browser's MCP token, kept off the command line. */
export const BROWSER_TOKEN_ENV = "CASAMA_BROWSER_TOKEN";

/** Claude Code: the person's browser as an HTTP MCP server, its tools allowed without a prompt. */
export function claudeBrowserFlags(url: string) {
  const config = {
    mcpServers: {
      casama_browser: {
        type: "http",
        url,
        headers: { Authorization: `Bearer \${${BROWSER_TOKEN_ENV}}` },
      },
    },
  };
  return `--mcp-config ${shq(JSON.stringify(config))} --allowedTools mcp__casama_browser`;
}

/** Codex: the same server, its bearer token read from the environment. */
export function codexBrowserFlags(url: string) {
  return [
    `-c ${shq(`mcp_servers.casama_browser.url=${JSON.stringify(url)}`)}`,
    `-c ${shq(`mcp_servers.casama_browser.bearer_token_env_var=${JSON.stringify(BROWSER_TOKEN_ENV)}`)}`,
  ].join(" ");
}

/**
 * The built-in agents (D-097, D-362), the fallback when the gallery's list (D-370) can't be read.
 * Their commands are the templates in `BUILT_IN_CODING_AGENTS` (@casama/domain).
 */
export const CODING_AGENTS: Record<string, CodingAgentSpec> = Object.fromEntries(
  builtInCodingAgents().map((a) => [a.id, a]),
);
export type CodingAgent = string;

export { AGENT_RESULT_MARKER, summarizeAgentOutput };

export interface CodingDeps {
  db: Database;
  computers?: ComputerService;
  fetch?: typeof fetch;
  /** Cursor's API (tests point it at a fake). */
  cursorApiUrl?: string;
  /** Seconds between cloud status checks (tests use less). */
  pollSeconds?: number;
  /**
   * The person's own browser for Claude Code and Codex on their computer (D-323 C16): the API's
   * public address (the agent calls `<publicApiUrl>/mcp/browser`) and the device tunnel.
   */
  browserMcp?: { publicApiUrl: string; tunnel: TunnelDeps };
  /**
   * The coding agents catalog (D-370): the signed gallery's list merged over the built-in one.
   * Without it, the built-in agents.
   */
  catalog?: () => Promise<CodingAgentSpec[]>;
}

/** Every changed, staged or new path in the folder, NUL-separated so any file name survives. */
const GIT_STATUS = "git status --porcelain=v1 -z --untracked-files=all 2>/dev/null";

/** The paths in `git status --porcelain=v1 -z` output (a rename's old name is skipped). */
export function changedPaths(out: string): Set<string> {
  const paths = new Set<string>();
  const parts = out.split("\0");
  for (let i = 0; i < parts.length; i++) {
    const e = parts[i]!;
    if (e.length < 4) continue;
    paths.add(e.slice(3));
    if (e[0] === "R" || e[0] === "C") i++; // the next part is the old name
  }
  return paths;
}

/** A commit subject from an agent's summary: its first line, without markdown, at most 72. */
export function commitSubject(summary: string, label: string) {
  const line = (summary.split("\n").find((l) => l.trim()) ?? "")
    .replace(/[*_`#>]/g, "")
    .replace(/\s+/g, " ")
    .trim();
  const subject = line || `Changes by ${label}`;
  return subject.length > 72 ? `${subject.slice(0, 71).trimEnd()}…` : subject;
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
  agent: z
    .string()
    .min(2)
    .max(40)
    .describe(
      "The agent's id from the list in this tool's description, or the id of one of the user's own agents (own_…)",
    ),
  task: z.string().min(1).max(20_000),
  where: z.enum(["my_computer", "bot_computer", "cloud"]),
  folder: z
    .string()
    .max(1000)
    .optional()
    .describe("Project folder on the computer (my_computer: inside a shared folder)"),
  repo: z.string().max(500).optional().describe("cloud: the GitHub repository URL"),
  branch: z
    .string()
    .max(200)
    .optional()
    .describe(
      "Branch to work on (created if missing). Codex on my_computer can't commit from its sandbox, so its changes are committed on this branch for it when it finishes",
    ),
  open_pr: z.boolean().optional().describe("cloud: open a pull request when done"),
  timeout_min: z.number().int().min(1).max(120).optional(),
});

/** The tool's description, built from the catalog. */
export function codingDescription(agents: CodingAgentSpec[]) {
  return `Hand a coding task to a coding agent and wait for its result: on the user's own computer (my_computer, through the desktop app, with their sign-ins), on your computer (bot_computer; only agents that aren't marked my_computer only), or Cursor's cloud agents (cloud, cursor only, needs repo). Agents: ${describeCodingAgents(agents)}. The user may also have added their own agents on their computer (ids start with ${OWN_AGENT_PREFIX}, my_computer only). Returns a summary, the changed files and any pull request link. Be specific in the task.`;
}

/** The catalog, or the built-in agents when it can't be read. */
async function catalogOf(deps: CodingDeps): Promise<CodingAgentSpec[]> {
  if (!deps.catalog) return Object.values(CODING_AGENTS);
  try {
    const list = await deps.catalog();
    return list.length ? list : Object.values(CODING_AGENTS);
  } catch {
    return Object.values(CODING_AGENTS);
  }
}

/** The person's own agents on one of their devices (D-371), or on all of them in this workspace. */
async function ownAgents(
  db: Database,
  q: { orgId: string; userId: string; deviceId?: string },
): Promise<CodingAgentSpec[]> {
  const rows = await db
    .execute<{
      key: string;
      label: string;
      bin: string;
      command: string;
      result: string;
      timeout_min: number;
    }>(sql`
      select a.key, a.label, a.bin, a.command, a.result, a.timeout_min
      from public.own_coding_agents a
      join public.local_devices d on d.id = a.device_id and d.user_id = a.user_id
      where a.org_id = ${q.orgId}::uuid and a.user_id = ${q.userId}::uuid
        ${q.deviceId ? sql`and a.device_id = ${q.deviceId}::uuid` : sql``}
      order by a.label`)
    .catch(() => []);
  return rows.map((r) => ownCodingAgentSpec(r));
}

export function registerCodingTools(registry: ToolRegistry, deps: CodingDeps) {
  // The description lists the catalog; it's refreshed whenever the catalog is read.
  let described = codingDescription(Object.values(CODING_AGENTS));
  const refresh = () =>
    catalogOf(deps).then((list) => {
      described = codingDescription(list);
      return list;
    });
  if (deps.catalog) void refresh().catch(() => {});
  registry.register({
    name: "coding.delegate",
    get description() {
      return described;
    },
    risk: "medium",
    riskFor: (a: z.infer<typeof schema>) => (a.open_pr ? "high" : "medium"),
    untrustedOutput: true,
    schema,
    async execute(args, ctx) {
      if (args.where === "cloud") return cloudCursor(deps, args, ctx);
      const local = args.where === "my_computer";
      const own = args.agent.startsWith(OWN_AGENT_PREFIX);
      const catalog = own ? [] : await refresh();
      let agent = catalog.find((a) => a.id === args.agent);
      if (!own && !agent)
        throw new ToolError(
          "unknown_agent",
          `There is no coding agent "${args.agent}". Agents: ${describeCodingAgents(catalog)}.`,
        );
      if (own && !local)
        throw new ToolError(
          "local_only",
          "The user's own agents run only on their own computer (my_computer).",
        );
      if (agent && !local && !agent.where.includes("bot_computer"))
        throw new ToolError(
          "local_only",
          `${agent.label} runs only on the user's own computer (my_computer), with their sign-in.`,
        );
      // T3 Code works in a T3 project; without a folder it would make one of the home folder.
      if (agent?.needsFolder && !args.folder)
        throw new ToolError(
          "folder_required",
          `${agent.label} needs the project folder to work in (folder).`,
        );
      let device: LocalDevice | null = null;
      let h: SandboxHandle;
      if (local) {
        device = await localDevice(deps, ctx, agent?.label ?? "a coding agent");
        if (own) {
          // Only the device's owner's own agents, on that device (D-371).
          const mine = await ownAgents(deps.db, {
            orgId: ctx.orgId,
            userId: device.userId,
            deviceId: device.id,
          });
          agent = mine.find((a) => a.id === args.agent);
          if (!agent)
            throw new ToolError(
              "unknown_agent",
              `There is no agent "${args.agent}" on ${device.name}.${mine.length ? ` The user's own agents there: ${mine.map((a) => `${a.id} (${a.label})`).join(", ")}.` : " The user hasn't added any agents of their own there."}`,
            );
        } else if (
          agent &&
          !PREALLOWED_CODING_AGENTS.includes(agent.id) &&
          !device.allowedAgents.includes(agent.id)
        )
          // A new agent needs one Allow on that computer, even with commands on (D-370).
          throw new ToolError(
            "agent_not_allowed",
            `${agent.label} hasn't run on ${device.name} before. Ask the user to open Casama on that computer, go to Settings → Use this computer for bots → Advanced → Coding Agents and tap Allow next to ${agent.label}, then try again.`,
          );
        h = await deviceHandle(deps, ctx, device, agent?.label ?? "");
      } else h = await botHandle(ctx);
      if (!agent) throw new ToolError("unknown_agent", `There is no coding agent "${args.agent}".`);
      const spec: CodingAgentSpec = agent;
      const cwd = args.folder;
      const env: Record<string, string> = {};
      const run = (cmd: string, timeoutMs = 120_000) =>
        runStreaming({ output: async () => {} }, h, cmd, { cwd, timeoutMs, env });
      const { install, keyName } = spec;
      if (!local && install && keyName) {
        // The bot's computer: install the CLI once, and pass its key from a named secret.
        const secret = (await loadSecrets(deps.db, ctx.orgId, ctx.botId)).find(
          (s) => s.name === keyName,
        );
        if (!secret)
          throw new ToolError(
            "missing_secret",
            `Add a secret named ${keyName} (Settings → Advanced → Secrets) so ${spec.label} can run on the bot's computer.`,
          );
        env[keyName] = secret.value;
        const has = await run(`command -v ${spec.bin}`);
        if (has.code !== 0) {
          await ctx.output(`Installing ${spec.label}…\n`);
          const inst = await run(install, 600_000);
          if (inst.code !== 0)
            throw new ToolError(
              "install_failed",
              `Could not install ${spec.label}: ${inst.out.slice(-500)}`,
            );
        }
      } else {
        const has = await run(`command -v ${spec.bin}`);
        if (has.code !== 0)
          throw new ToolError(
            "agent_not_installed",
            `${spec.label} is not installed on your computer (the \`${spec.bin}\` command was not found).`,
          );
      }
      if (args.branch) {
        // Switch to the branch, creating it only when it's missing: `checkout -B` would reset an
        // existing branch to the current commit and drop its work.
        const b = await run(
          `git checkout ${shq(args.branch)} 2>/dev/null || git checkout -b ${shq(args.branch)}`,
        );
        if (b.code !== 0)
          throw new ToolError(
            "git_failed",
            `Could not switch to ${args.branch}: ${b.out.slice(-300)}`,
          );
      }
      // Where the agent starts, so its commits count as changes too, not only uncommitted edits.
      const base = (await run("git rev-parse HEAD 2>/dev/null")).out.trim();
      // Codex's workspace-write sandbox keeps .git read-only, even listed as a writable root, so
      // on the user's computer it can edit and test but never commit. With a branch to work on,
      // Casama commits for it: only the paths it changed, not what was already changed before.
      const commitsForAgent = local && spec.commitsForAgent && !!args.branch;
      const before = commitsForAgent
        ? changedPaths((await run(GIT_STATUS)).out)
        : new Set<string>();
      // C16: Claude Code and Codex on the person's computer may check their work in the person's
      // own browser, when it's paired, online and lets this bot in.
      const timeoutMin = args.timeout_min ?? spec.timeoutMin ?? 30;
      const browserMcp =
        local && spec.browser
          ? await browserForAgent(deps, ctx, timeoutMin).catch(() => null)
          : null;
      if (browserMcp) env[BROWSER_TOKEN_ENV] = browserMcp.token;
      const task = [
        args.task,
        commitsForAgent
          ? `Don't run git commit or other git writes: your sandbox can't write to .git. Casama commits your changes on ${args.branch} when you finish.`
          : "",
        browserMcp ? BROWSER_MCP_HINT : "",
      ]
        .filter(Boolean)
        .join("\n\n");
      const browserFlags = browserMcp
        ? spec.browser === "claude"
          ? claudeBrowserFlags(browserMcp.url)
          : codexBrowserFlags(browserMcp.url)
        : null;
      const command = renderCodingCommand(
        spec,
        local ? "my_computer" : "bot_computer",
        { task, folder: args.folder },
        browserFlags,
      );
      // Stop when the run is cancelled.
      const ctrl = new AbortController();
      if (ctx.signal?.aborted) ctrl.abort(new Error("cancelled"));
      ctx.signal?.addEventListener("abort", () => ctrl.abort(new Error("cancelled")), {
        once: true,
      });
      const poll = setInterval(async () => {
        if (await cancelled(deps.db, ctx.runId)) ctrl.abort(new Error("cancelled"));
      }, 1000);
      let r: Awaited<ReturnType<typeof runStreaming>>;
      try {
        await ctx.output(`${spec.label} is working…\n`);
        r = await runStreaming(ctx, h, command, {
          cwd,
          env,
          timeoutMs: timeoutMin * 60_000,
          signal: ctrl.signal,
        });
      } finally {
        clearInterval(poll);
      }
      const summary = summarizeAgentOutput(r.out, spec.result);
      const commitNotes: string[] = [];
      if (commitsForAgent && r.code === 0 && !r.timedOut && !summary.error) {
        const after = changedPaths((await run(GIT_STATUS)).out);
        const mine = [...after].filter((p) => !before.has(p));
        const theirs = [...after].filter((p) => before.has(p));
        if (mine.length) {
          const list = mine.map(shq).join(" ");
          const msg = `${commitSubject(summary.text, spec.label)}\n\nMade by ${spec.label} through Casama.`;
          const c = await run(
            `git add -A -- ${list} && git commit -q -m ${shq(msg)} -- ${list} && git rev-parse --short HEAD`,
          );
          const sha = c.out.trim().split("\n").pop() ?? "";
          commitNotes.push(
            c.code === 0
              ? `\nCommitted ${sha} on ${args.branch} for ${spec.label} (${mine.length} file${mine.length === 1 ? "" : "s"}).`
              : `\nCould not commit ${spec.label}'s changes: ${c.out.trim().slice(-300)}`,
          );
        }
        if (theirs.length)
          commitNotes.push(
            `\nLeft uncommitted (already changed before ${spec.label} started):\n${theirs.slice(0, 30).join("\n")}`,
          );
      }
      const diff = await run(
        `git diff --stat ${/^[0-9a-f]{40}$/.test(base) ? base : "HEAD"} 2>/dev/null | tail -n 30`,
      );
      const untracked = await run(
        "git ls-files --others --exclude-standard 2>/dev/null | head -n 30",
      );
      const exit = !r.timedOut && r.code !== 0 ? spec.exitMessages[String(r.code)] : undefined;
      const status = r.timedOut
        ? "timed out"
        : r.code === 0 && !summary.error
          ? "finished"
          : exit
            ? exit.status
            : `failed (exit ${r.code})`;
      const parts = [
        `${spec.label} ${status}${local ? " on your computer" : " on the bot's computer"}.`,
        summary.text ? `\nSummary:\n${summary.text}` : "",
        ...commitNotes,
        diff.code === 0 && diff.out.trim() ? `\nChanged files:\n${diff.out.trim()}` : "",
        untracked.code === 0 && untracked.out.trim()
          ? `\nNew files (not committed):\n${untracked.out.trim()}`
          : "",
        exit?.note ? `\n${exit.note}` : "",
        args.branch ? `\nBranch: ${args.branch}` : "",
        browserMcp ? `\n${spec.label} could use your browser to check its work.` : "",
      ];
      return {
        content: parts.join("\n"),
        preview: `${spec.label} ${status}: ${summary.text.replace(/\s+/g, " ").slice(0, 160)}`,
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

interface LocalDevice {
  id: string;
  userId: string;
  name: string;
  computerId: string;
  /** Agents beyond the built-in five that the person allowed on this computer (D-370). */
  allowedAgents: string[];
}

/** The run owner's own computer (desktop companion) that allows this bot. */
async function localDevice(
  deps: CodingDeps,
  ctx: ToolContext,
  label: string,
): Promise<LocalDevice> {
  if (!deps.computers)
    throw new ToolError("no_computer", "Personal computers are not set up on this server.");
  const user = await actingUserOf(deps.db, ctx.runId);
  const [d] = await deps.db.execute<{
    id: string;
    user_id: string;
    name: string;
    computer_id: string | null;
    allowed: string[] | null;
  }>(sql`
    select id, user_id, name, computer_id, allowed_coding_agents as allowed from public.local_devices
    where org_id = ${ctx.orgId}::uuid and user_id = ${user}::uuid and enabled and ${ctx.botId}::uuid = any(allowed_bot_ids)
      and computer_id is not null
    order by last_seen_at desc nulls last limit 1`);
  if (!d?.computer_id)
    throw new ToolError(
      "no_local_computer",
      `To use ${label} on your computer, turn on "Use this computer for bots" in the desktop app and allow this bot there.`,
    );
  return {
    id: d.id,
    userId: d.user_id,
    name: d.name,
    computerId: d.computer_id,
    allowedAgents: d.allowed ?? [],
  };
}

async function deviceHandle(
  deps: CodingDeps,
  ctx: ToolContext,
  d: LocalDevice,
  label: string,
): Promise<SandboxHandle> {
  const h = await deps.computers!.ensureRunning(d.computerId).catch((err: unknown) => {
    throw new ToolError("device_offline", (err as Error).message);
  });
  return (
    h.withActivity?.({
      run_id: ctx.runId,
      bot: "",
      bot_id: ctx.botId,
      tool: "coding.delegate",
      summary: `${label} is working`,
    }) ?? h
  );
}

/**
 * The person's paired browser for a coding agent (C16): its MCP address and a token bound to this
 * run and that browser, ending a little after the agent's time limit. Null without one.
 */
async function browserForAgent(deps: CodingDeps, ctx: ToolContext, timeoutMin: number) {
  const b = deps.browserMcp;
  if (!b) return null;
  if (!(await mineAllowed(deps.db, ctx.runId))) return null;
  const userId = await actingUserOf(deps.db, ctx.runId);
  const ids = await browserDevicesFor(deps.db, { orgId: ctx.orgId, botId: ctx.botId, userId });
  const device = await firstOnline(b.tunnel, ids);
  if (!device) return null;
  const token = signBrowserMcpToken(
    { run: ctx.runId, device, exp: Math.floor(Date.now() / 1000) + (timeoutMin + 5) * 60 },
    b.tunnel.internalToken,
  );
  return { url: `${b.publicApiUrl.replace(/\/$/, "")}/mcp/browser`, token, device };
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
      "Add a secret named CURSOR_API_KEY (Settings → Advanced → Secrets) to use Cursor's cloud agents.",
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
