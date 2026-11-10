/**
 * Agent-to-agent server (D-140): bots a workspace publishes are A2A v1.0 agents.
 * - GET  /a2a/{botId}/.well-known/agent-card.json  the agent card (public, nothing secret)
 * - POST /a2a/{botId}  JSON-RPC: SendMessage, GetTask, CancelTask, ListTasks
 * Callers authenticate with a workspace API key (the hosted MCP's `ksk_` keys, D-117) and act as
 * the key's person, so tasks run with the bot's normal approvals, budgets and audit log.
 */
import { createHash, randomUUID } from "node:crypto";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { A2A_VERSION, type A2aAgentCard, type A2aMessage, type A2aState, type A2aTask } from "@kasama/agent";
import { routes } from "@kasama/contracts";
import { contentKeys, type JwtClaims, withUserSession } from "@kasama/db";
import { sql } from "drizzle-orm";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";

const hash = (t: string) => createHash("sha256").update(t).digest("hex");
const WAIT_MS = 55_000;

/** JSON-RPC error codes: the standard ones plus A2A's TaskNotFound (-32001) and others. */
const E = { parse: -32700, invalid: -32600, method: -32601, params: -32602, internal: -32603, notFound: -32001, notCancelable: -32002, version: -32009 };

export function registerA2aRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;
  const base = (c: { req: { url: string } }) => (deps.env.PUBLIC_API_URL ?? new URL(c.req.url).origin).replace(/\/$/, "");

  const published = async (botId: string) => {
    if (!/^[0-9a-f-]{36}$/.test(botId)) return null;
    const [b] = await db.execute<{ id: string; org_id: string; name: string; persona_md: string | null }>(sql`
      select b.id, b.org_id, b.name, b.persona_md from public.bots b join public.organizations o on o.id = b.org_id
      where b.id = ${botId}::uuid and b.archived_at is null and b.a2a_published and o.a2a_enabled`);
    return b ?? null;
  };

  const card = (c: { req: { url: string } }, b: NonNullable<Awaited<ReturnType<typeof published>>>): A2aAgentCard => ({
    name: b.name,
    description: (b.persona_md || `${b.name}, an AI teammate on Kasama.`).replace(/\s+/g, " ").slice(0, 500),
    version: "1.0.0",
    supportedInterfaces: [{ url: `${base(c)}/a2a/${b.id}`, protocolBinding: "JSONRPC", protocolVersion: A2A_VERSION }],
    capabilities: { streaming: false, pushNotifications: false },
    defaultInputModes: ["text/plain"],
    defaultOutputModes: ["text/plain"],
    skills: [{ id: "chat", name: "Ask the bot", description: `Give ${b.name} a task in plain language; it works with its own tools and returns the result.`, tags: ["assistant"] }],
    securitySchemes: { workspaceKey: { httpAuthSecurityScheme: { scheme: "Bearer", bearerFormat: "Kasama workspace API key" } } },
    securityRequirements: [{ workspaceKey: [] }],
  });

  app.get("/a2a/:botId/.well-known/agent-card.json", async (c) => {
    const b = await published(c.req.param("botId"));
    if (!b) return c.json({ error: "not_found" }, 404);
    c.header("cache-control", "public, max-age=300");
    return c.json(card(c, b));
  });

  // --- tasks ---------------------------------------------------------------------
  type Row = { id: string; context_id: string; run_id: string | null; status: string | null; cancel: boolean };
  const stateOf = (status: string | null): A2aState =>
    status === "completed"
      ? "TASK_STATE_COMPLETED"
      : status === "failed"
        ? "TASK_STATE_FAILED"
        : status === "cancelled"
          ? "TASK_STATE_CANCELED"
          : status === "queued"
            ? "TASK_STATE_SUBMITTED"
            : "TASK_STATE_WORKING";
  const agentMsg = (text: string, t: Row): A2aMessage => ({ role: "ROLE_AGENT", parts: [{ text }], messageId: randomUUID(), contextId: t.context_id, taskId: t.id });

  const taskOf = async (t: Row): Promise<A2aTask> => {
    const state = stateOf(t.status);
    const out: A2aTask = { id: t.id, contextId: t.context_id, status: { state, timestamp: new Date().toISOString() } };
    if (state === "TASK_STATE_COMPLETED" && t.run_id) {
      const [m] = await db.execute<{ content: Array<{ type?: string; text?: string }> }>(sql`
        select content from public.messages where run_id = ${t.run_id}::uuid and role = 'assistant' order by created_at desc limit 1`);
      const text = (Array.isArray(m?.content) ? m.content : []).filter((p) => p.type === "text").map((p) => p.text ?? "").join("");
      out.artifacts = [{ artifactId: `${t.id}-answer`, name: "answer", parts: [{ text }] }];
      out.status.message = agentMsg(text, t);
    } else if (t.status === "waiting_approval" || t.status === "waiting_takeover")
      out.status.message = agentMsg("Waiting for the bot's owner to approve a step.", t);
    else if (state === "TASK_STATE_FAILED") out.status.message = agentMsg("The task failed.", t);
    return out;
  };
  const load = async (taskId: string, botId: string, user: string) => {
    if (!/^[0-9a-f-]{36}$/.test(taskId)) return null;
    const [t] = await db.execute<Row>(sql`
      select t.id, t.context_id, t.run_id, r.status, r.cancel_requested_at is not null as cancel
      from public.a2a_tasks t left join public.runs r on r.id = t.run_id
      where t.id = ${taskId}::uuid and t.bot_id = ${botId}::uuid and t.caller_user_id = ${user}::uuid`);
    return t ?? null;
  };

  app.post("/a2a/:botId", async (c) => {
    const rpcError = (id: unknown, code: number, message: string, status = 200) => c.json({ jsonrpc: "2.0", id: id ?? null, error: { code, message } }, status as 200);
    const b = await published(c.req.param("botId"));
    if (!b) return rpcError(null, E.invalid, "No such A2A agent", 404);
    // A workspace API key of this bot's workspace.
    const tok = (c.req.header("authorization") ?? "").replace(/^Bearer\s+/i, "").trim();
    const [key] = tok.startsWith("ksk_")
      ? await db.execute<{ user_id: string }>(sql`
          update public.mcp_tokens set last_used_at = now()
          where token_hash = ${hash(tok)} and kind = 'api_key' and revoked_at is null and org_id = ${b.org_id}::uuid
            and exists (select 1 from public.memberships m where m.user_id = mcp_tokens.user_id and m.org_id = mcp_tokens.org_id)
          returning user_id`)
      : [];
    if (!key) {
      c.header("www-authenticate", 'Bearer realm="kasama-a2a"');
      return rpcError(null, E.invalid, "Use a workspace API key (Bearer ksk_…)", 401);
    }
    const version = c.req.header("a2a-version");
    let req: { jsonrpc?: string; id?: unknown; method?: string; params?: Record<string, unknown> };
    try {
      req = await c.req.json();
    } catch {
      return rpcError(null, E.parse, "Parse error");
    }
    if (version && !/^1(\.\d+)?$/.test(version.trim())) return c.json({ jsonrpc: "2.0", id: req.id ?? null, error: { code: E.version, message: `A2A version ${version} isn't supported`, data: [{ "@type": "VersionNotSupported", supportedVersions: [A2A_VERSION] }] } });
    if (req.jsonrpc !== "2.0" || typeof req.method !== "string") return rpcError(req.id, E.invalid, "Invalid request");
    const claims: JwtClaims = { sub: key.user_id, role: "authenticated", aal: "aal1" };
    const [visible] = await withUserSession(db, claims, (tx) => tx.execute<{ ok: boolean }>(sql`select public.can_access_bot(${b.id}::uuid) as ok`));
    if (!visible?.ok) return rpcError(req.id, E.invalid, "This key's person can't use this bot", 403);
    const p = req.params ?? {};
    const ok = (result: unknown) => c.json({ jsonrpc: "2.0", id: req.id ?? null, result });

    try {
      switch (req.method) {
        case "SendMessage": {
          const m = p.message as A2aMessage | undefined;
          const text = (m?.parts ?? []).map((x) => x.text ?? "").filter(Boolean).join("\n").trim();
          if (!m || m.role !== "ROLE_USER" || !text) return rpcError(req.id, E.params, "message needs role ROLE_USER and a text part");
          // The same context continues the same conversation; a task id continues its task's context.
          let contextId = typeof m.contextId === "string" && /^[0-9a-f-]{36}$/.test(m.contextId) ? m.contextId : null;
          if (m.taskId) {
            const prev = await load(m.taskId, b.id, key.user_id);
            if (!prev) return rpcError(req.id, E.notFound, "Task not found");
            contextId = prev.context_id;
          }
          const [prevConv] = contextId
            ? await db.execute<{ conversation_id: string }>(sql`
                select conversation_id from public.a2a_tasks where bot_id = ${b.id}::uuid and caller_user_id = ${key.user_id}::uuid and context_id = ${contextId}::uuid and conversation_id is not null
                order by created_at desc limit 1`)
            : [];
          contextId ??= randomUUID();
          let conversationId = prevConv?.conversation_id;
          if (!conversationId) {
            const [conv] = await db.execute<{ id: string }>(sql`
              insert into public.conversations (org_id, bot_id, title, created_by, last_message_at)
              values (${b.org_id}::uuid, ${b.id}::uuid, ${`A2A: ${text.replace(/\s+/g, " ").slice(0, 60)}`}, ${key.user_id}::uuid, now()) returning id`);
            conversationId = conv?.id as string;
          }
          const [run] = await db.execute<{ id: string }>(sql`
            insert into public.runs (org_id, bot_id, conversation_id, created_by, trigger)
            values (${b.org_id}::uuid, ${b.id}::uuid, ${conversationId}::uuid, ${key.user_id}::uuid, 'a2a') returning id`);
          await db.execute(sql`
            insert into public.messages (org_id, conversation_id, role, author_user_id, content, run_id)
            values (${b.org_id}::uuid, ${conversationId}::uuid, 'user', ${key.user_id}::uuid,
                    ${contentKeys.sealJson(b.org_id, [{ type: "text", text: `(Sent over A2A)\n${text}` }])}::jsonb, ${run?.id}::uuid)`);
          await db.execute(sql`update public.conversations set last_message_at = now() where id = ${conversationId}::uuid`);
          const [t] = await db.execute<{ id: string }>(sql`
            insert into public.a2a_tasks (org_id, bot_id, caller_user_id, context_id, conversation_id, run_id)
            values (${b.org_id}::uuid, ${b.id}::uuid, ${key.user_id}::uuid, ${contextId}::uuid, ${conversationId}::uuid, ${run?.id}::uuid) returning id`);
          await db.execute(sql`
            insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id, metadata)
            values (${b.org_id}::uuid, 'user', ${key.user_id}::uuid, 'a2a.task', 'bot', ${b.id}::uuid, ${JSON.stringify({ task_id: t?.id, run_id: run?.id })}::jsonb)`);
          await deps.workflows.startRun(run?.id as string);
          // Blocking by default: wait for the run to finish (or need an approval) within a minute.
          const cfg = (p.configuration ?? {}) as { returnImmediately?: boolean };
          const until = Date.now() + (cfg.returnImmediately ? 0 : WAIT_MS);
          let row = (await load(t?.id as string, b.id, key.user_id)) as Row;
          while (Date.now() < until && !["completed", "failed", "cancelled", "waiting_approval", "waiting_takeover"].includes(row.status ?? "")) {
            await new Promise((r) => setTimeout(r, 200));
            row = (await load(row.id, b.id, key.user_id)) as Row;
          }
          return ok({ task: await taskOf(row) });
        }
        case "GetTask": {
          const t = await load(String(p.id ?? ""), b.id, key.user_id);
          return t ? ok(await taskOf(t)) : rpcError(req.id, E.notFound, "Task not found");
        }
        case "CancelTask": {
          const t = await load(String(p.id ?? ""), b.id, key.user_id);
          if (!t) return rpcError(req.id, E.notFound, "Task not found");
          if (["completed", "failed", "cancelled"].includes(t.status ?? "")) return rpcError(req.id, E.notCancelable, "Task cannot be canceled");
          await db.execute(sql`update public.runs set cancel_requested_at = now() where id = ${t.run_id}::uuid`);
          await deps.workflows.signalRun(t.run_id as string).catch(() => {});
          const out = await taskOf(t);
          return ok({ ...out, status: { ...out.status, state: "TASK_STATE_CANCELED" } });
        }
        case "ListTasks": {
          const ctx = typeof p.contextId === "string" && /^[0-9a-f-]{36}$/.test(p.contextId) ? p.contextId : null;
          const size = Math.min(Math.max(Number(p.pageSize ?? 50), 1), 100);
          const rows = await db.execute<Row>(sql`
            select t.id, t.context_id, t.run_id, r.status, r.cancel_requested_at is not null as cancel
            from public.a2a_tasks t left join public.runs r on r.id = t.run_id
            where t.bot_id = ${b.id}::uuid and t.caller_user_id = ${key.user_id}::uuid ${ctx ? sql`and t.context_id = ${ctx}::uuid` : sql``}
            order by t.created_at desc limit ${size}`);
          return ok({ tasks: await Promise.all(rows.map(taskOf)), nextPageToken: "" });
        }
        default:
          return rpcError(req.id, E.method, `Method not found: ${req.method}`);
      }
    } catch (e) {
      return rpcError(req.id, E.internal, (e as Error).message.slice(0, 200));
    }
  });

  // --- settings --------------------------------------------------------------------
  const manageBot = async (claims: JwtClaims, id: string) => {
    const [b] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ org_id: string; manage: boolean; a2a_published: boolean; enabled: boolean }>(sql`
        select b.org_id, public.can_manage_bot(b.id) as manage, b.a2a_published, o.a2a_enabled as enabled
        from public.bots b join public.organizations o on o.id = b.org_id where b.id = ${id}::uuid`),
    );
    if (!b) throw new ApiError(404, "bot_not_found", "Bot not found");
    return b;
  };
  const status = (c: { req: { url: string } }, id: string, b: { a2a_published: boolean; enabled: boolean }) => ({
    workspace_enabled: b.enabled,
    published: b.a2a_published,
    agent_card_url: `${base(c)}/a2a/${id}/.well-known/agent-card.json`,
  });

  app.openapi(routes.getBotA2a, async (c) => {
    const claims = c.get("claims");
    if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
    const { id } = c.req.valid("param");
    return c.json(status(c, id, await manageBot(claims, id)), 200);
  });

  app.openapi(routes.setBotA2a, async (c) => {
    const claims = c.get("claims");
    if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
    const { id } = c.req.valid("param");
    const { published: on } = c.req.valid("json");
    const b = await manageBot(claims, id);
    if (!b.manage) throw new ApiError(403, "forbidden", "Only people who manage this bot can publish it");
    if (on && !b.enabled) throw new ApiError(409, "a2a_off", "Turn on agent-to-agent in workspace settings first");
    await db.execute(sql`update public.bots set a2a_published = ${on} where id = ${id}::uuid`);
    await db.execute(sql`
      insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id, metadata)
      values (${b.org_id}::uuid, 'user', ${claims.sub}::uuid, ${on ? "a2a.published" : "a2a.unpublished"}, 'bot', ${id}::uuid, '{}'::jsonb)`);
    return c.json(status(c, id, { ...b, a2a_published: on }), 200);
  });
}
