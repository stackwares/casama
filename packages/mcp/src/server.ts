/**
 * Kasama MCP server (Phase 8, D-077): control your bots from AI coding tools. Tools: list
 * workspaces and bots, ask a bot (waits for its reply), read runs, list and decide approvals.
 * Authentication reuses the CLI's login (`kasama login`), refreshing the session as needed, or a
 * token in KASAMA_TOKEN.
 */
import { readFileSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";

export const VERSION = "0.8.0";

type Session = { access_token: string; refresh_token?: string; expires_at?: number };

export interface KasamaApiOptions {
  apiUrl: string;
  /** A fixed access token (KASAMA_TOKEN), or the CLI's session file. */
  token?: string;
  sessionFile?: string;
  fetch?: typeof fetch;
}

export class KasamaApi {
  readonly opts: KasamaApiOptions;
  private session: Session | null = null;

  constructor(opts: KasamaApiOptions) {
    this.opts = { ...opts, apiUrl: opts.apiUrl.replace(/\/$/, "") };
  }

  private get f() {
    return this.opts.fetch ?? fetch;
  }

  private async token(): Promise<string> {
    if (this.opts.token) return this.opts.token;
    const file = this.opts.sessionFile ?? defaultSessionFile();
    this.session ??= JSON.parse(readFileSync(file, "utf8")) as Session;
    const s = this.session;
    if (s.expires_at && s.expires_at * 1000 < Date.now() + 60_000 && s.refresh_token) {
      const cfg = (await (await this.f(`${this.opts.apiUrl}/v1/config`)).json()) as {
        supabase_url: string;
        supabase_anon_key: string;
      };
      const r = await this.f(`${cfg.supabase_url}/auth/v1/token?grant_type=refresh_token`, {
        method: "POST",
        headers: { apikey: cfg.supabase_anon_key, "content-type": "application/json" },
        body: JSON.stringify({ refresh_token: s.refresh_token }),
      });
      if (!r.ok) throw new Error("The Kasama session expired. Run `kasama login` again.");
      const next = (await r.json()) as Session & { user?: unknown };
      this.session = next;
      writeFileSync(file, JSON.stringify(next), { mode: 0o600 });
    }
    return this.session.access_token;
  }

  async call<T = Record<string, unknown>>(
    path: string,
    init: { method?: string; json?: unknown } = {},
  ): Promise<T> {
    const r = await this.f(`${this.opts.apiUrl}${path}`, {
      method: init.method ?? (init.json === undefined ? "GET" : "POST"),
      headers: {
        authorization: `Bearer ${await this.token()}`,
        ...(init.json !== undefined ? { "content-type": "application/json" } : {}),
      },
      body: init.json === undefined ? undefined : JSON.stringify(init.json),
    });
    const body = (await r.json().catch(() => ({}))) as T & { detail?: string; title?: string };
    if (!r.ok) throw new Error(`${body.detail ?? body.title ?? r.statusText} (HTTP ${r.status})`);
    return body;
  }
}

export function defaultSessionFile() {
  const dir =
    process.env.KASAMA_CONFIG_DIR ??
    (process.platform === "win32"
      ? join(process.env.APPDATA ?? homedir(), "kasama")
      : join(homedir(), ".config", "kasama"));
  return join(dir, "session.json");
}

const text = (s: string) => ({ content: [{ type: "text" as const, text: s }] });
const json = (v: unknown) => text(JSON.stringify(v, null, 2));

type Org = { id: string; name: string; slug: string; role: string };
type Bot = { id: string; name: string; status: string; org_id: string };

export function createKasamaMcpServer(
  api: KasamaApi,
  opts: { pollMs?: number; timeoutMs?: number } = {},
) {
  const server = new McpServer({ name: "kasama", version: VERSION });

  const orgs = async () => (await api.call<{ items: Org[] }>("/v1/orgs")).items;
  const resolveOrg = async (org?: string) => {
    const all = await orgs();
    const o = org
      ? all.find(
          (x) => x.id === org || x.slug === org || x.name.toLowerCase() === org.toLowerCase(),
        )
      : all[0];
    if (!o) throw new Error(org ? `No workspace "${org}"` : "You are not in any workspace yet");
    return o;
  };
  const bots = async (org?: string) => {
    const o = await resolveOrg(org);
    return (await api.call<{ items: Bot[] }>(`/v1/bots?org_id=${o.id}`)).items;
  };
  const resolveBot = async (bot: string, org?: string) => {
    const list = await bots(org);
    const b = list.find((x) => x.id === bot || x.name.toLowerCase() === bot.toLowerCase());
    if (!b)
      throw new Error(`No bot "${bot}". Bots: ${list.map((x) => x.name).join(", ") || "none"}`);
    return b;
  };

  server.registerTool(
    "list_workspaces",
    { title: "List workspaces", description: "Kasama workspaces you belong to, with your role." },
    async () =>
      json((await orgs()).map((o) => ({ id: o.id, name: o.name, slug: o.slug, role: o.role }))),
  );

  server.registerTool(
    "list_bots",
    {
      title: "List bots",
      description:
        "Bots in a workspace (default: your first workspace), with their current status.",
      inputSchema: { workspace: z.string().optional().describe("Workspace slug, name or id") },
    },
    async ({ workspace }) =>
      json((await bots(workspace)).map((b) => ({ id: b.id, name: b.name, status: b.status }))),
  );

  server.registerTool(
    "ask_bot",
    {
      title: "Ask a bot",
      description:
        "Send a message to a Kasama bot and wait for its reply. The bot can use its own computer and tools; risky actions may wait for approval (see list_approvals). Pass conversation_id to continue a thread.",
      inputSchema: {
        bot: z.string().describe("Bot name or id"),
        message: z.string().min(1).max(20_000),
        conversation_id: z.string().optional(),
        workspace: z.string().optional(),
      },
    },
    async ({ bot, message, conversation_id, workspace }) => {
      const b = await resolveBot(bot, workspace);
      const conv =
        conversation_id ??
        (await api.call<{ id: string }>("/v1/conversations", { json: { bot_id: b.id } })).id;
      const sent = await api.call<{ run_id: string }>(`/v1/conversations/${conv}/messages`, {
        json: { text: message },
      });
      const deadline = Date.now() + (opts.timeoutMs ?? 10 * 60_000);
      let run: { status: string; cost_usd?: number; error?: { message: string } | null } = {
        status: "queued",
      };
      while (
        !["completed", "failed", "cancelled", "waiting_approval"].includes(run.status) &&
        Date.now() < deadline
      ) {
        await new Promise((r) => setTimeout(r, opts.pollMs ?? 1000));
        run = await api.call(`/v1/runs/${sent.run_id}`);
      }
      const events = (
        await api.call<{ items: Array<{ type: string; payload: Record<string, unknown> }> }>(
          `/v1/runs/${sent.run_id}/events?limit=1000`,
        )
      ).items;
      const reply = events
        .filter((e) => e.type === "message.completed")
        .flatMap((e) => (e.payload.content as Array<{ type: string; text?: string }>) ?? [])
        .filter((p) => p.type === "text")
        .map((p) => p.text)
        .join("\n");
      const tools = events.filter((e) => e.type === "tool.started").map((e) => e.payload.tool);
      const lines = [
        reply || (run.status === "completed" ? "(no text reply)" : ""),
        "",
        `status: ${run.status}${run.status === "waiting_approval" ? " (approve with decide_approval)" : ""}`,
        run.error ? `error: ${run.error.message}` : "",
        tools.length ? `tools used: ${tools.join(", ")}` : "",
        `conversation_id: ${conv}`,
        `run_id: ${sent.run_id}`,
        run.cost_usd != null ? `cost: $${run.cost_usd.toFixed(4)}` : "",
      ].filter((l, i) => l !== "" || i === 1);
      return text(lines.join("\n").trim());
    },
  );

  server.registerTool(
    "get_run",
    {
      title: "Get a run",
      description: "A run's status, cost and its recent events (tool calls, outputs, errors).",
      inputSchema: { run_id: z.string() },
    },
    async ({ run_id }) => {
      const run = await api.call(`/v1/runs/${run_id}`);
      const events = (
        await api.call<{ items: Array<{ type: string; payload: Record<string, unknown> }> }>(
          `/v1/runs/${run_id}/events?limit=200`,
        )
      ).items
        .filter((e) => e.type !== "message.delta")
        .map((e) => ({ type: e.type, ...e.payload }));
      return json({ run, events: events.slice(-60) });
    },
  );

  server.registerTool(
    "list_approvals",
    {
      title: "List approvals",
      description: "Actions waiting for a person's approval in a workspace.",
      inputSchema: { workspace: z.string().optional() },
    },
    async ({ workspace }) => {
      const o = await resolveOrg(workspace);
      return json(
        (await api.call<{ items: unknown[] }>(`/v1/approvals?org_id=${o.id}&status=pending`)).items,
      );
    },
  );

  server.registerTool(
    "decide_approval",
    {
      title: "Approve or deny",
      description:
        "Approve or deny a pending action. The bot continues (or skips the step) right away.",
      inputSchema: {
        approval_id: z.string(),
        decision: z.enum(["approve", "deny"]),
      },
      annotations: { destructiveHint: true },
    },
    async ({ approval_id, decision }) =>
      json(
        await api.call(`/v1/approvals/${approval_id}/decision`, {
          json: { decision: decision === "approve" ? "approved" : "denied" },
        }),
      ),
  );

  return server;
}
