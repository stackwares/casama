import type { OpenAPIHono } from "@hono/zod-openapi";
import { routes } from "@kasama/contracts";
import { type JwtClaims, schema, withUserSession } from "@kasama/db";
import { parseMentions, templateById } from "@kasama/domain";
import { withSpan } from "@kasama/observability";
import { and, desc, eq, inArray, isNotNull, isNull, sql } from "drizzle-orm";
import { streamSSE } from "hono/streaming";
import { enforceLimit } from "../../billing/limits.ts";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { iso } from "../util.ts";
import type { ModelListOutcome } from "../workflows.ts";
import { applyTemplate } from "./autonomy.ts";

const { bots, conversations, runs, memories, modelCredentials } = schema;
const TERMINAL_EVENTS = new Set(["run.completed", "run.failed", "run.cancelled"]);
const TERMINAL_STATUS = new Set(["completed", "failed", "cancelled"]);

function requireClaims(claims: JwtClaims | undefined): JwtClaims {
  if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
  return claims;
}

type BotRow = typeof bots.$inferSelect;
const botOut = (b: BotRow) => ({
  id: b.id,
  org_id: b.orgId,
  name: b.name,
  avatar_url: b.avatarUrl,
  persona_md: b.personaMd,
  model_policy: b.modelPolicy as Record<string, never>,
  autonomy: b.autonomy,
  visibility: b.visibility,
  budget: b.budget as { per_run_usd?: number; daily_usd?: number },
  status: b.status as "idle",
  default_computer_id: b.defaultComputerId ?? null,
  folder_id: b.folderId ?? null,
  sort_key: Number(b.sortKey ?? 0),
  archived_at: b.archivedAt ? iso(b.archivedAt) : null,
  setup_status: (b.setupStatus ?? "done") as "pending",
  created_at: iso(b.createdAt),
});

type ConvRow = typeof conversations.$inferSelect;
const convOut = (c: ConvRow, botIds: string[] = []) => ({
  id: c.id,
  bot_id: c.botId,
  title: c.title,
  last_message_at: c.lastMessageAt ? iso(c.lastMessageAt) : null,
  kind: (c.kind ?? "direct") as "direct",
  bot_ids: botIds.length ? botIds : [c.botId],
  created_at: iso(c.createdAt),
});

type RunRow = typeof runs.$inferSelect;
const runOut = (r: RunRow) => ({
  id: r.id,
  bot_id: r.botId,
  conversation_id: r.conversationId,
  parent_run_id: r.parentRunId,
  trigger: r.trigger,
  status: r.status as "queued",
  tokens_in: Number(r.tokensIn),
  tokens_out: Number(r.tokensOut),
  cost_usd: Number(r.costUsd),
  last_seq: r.lastSeq,
  started_at: r.startedAt ? iso(r.startedAt) : null,
  ended_at: r.endedAt ? iso(r.endedAt) : null,
  error: (r.error as { code: string; message: string } | null) ?? null,
  trace_id: r.traceId ?? null,
  created_at: iso(r.createdAt),
});

type CredRow = typeof modelCredentials.$inferSelect;
export const credOut = (c: CredRow) => ({
  id: c.id,
  org_id: c.orgId,
  provider: c.provider as "openai",
  label: c.label,
  base_url: c.baseUrl,
  key_hint: c.keyHint,
  last_tested_at: c.lastTestedAt ? iso(c.lastTestedAt) : null,
  last_test_ok: c.lastTestOk,
  owner_user_id: c.ownerUserId ?? null,
  status: c.status as "ok",
  account:
    c.provider === "chatgpt" ? ((c.oauth as { email?: string } | null)?.email ?? null) : null,
  fallback_on_limit:
    (c.settings as { fallback_on_limit?: boolean } | null)?.fallback_on_limit === true,
  created_at: iso(c.createdAt),
});

interface EventRow {
  run_id: string;
  seq: number;
  bot_id: string;
  type: string;
  payload: Record<string, unknown>;
  created_at: Date;
  [key: string]: unknown;
}
const eventOut = (e: EventRow) => ({
  v: 1,
  run_id: e.run_id,
  seq: e.seq,
  ts: iso(e.created_at),
  bot_id: e.bot_id,
  type: e.type,
  payload: e.payload,
});

export function registerBotRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;

  /** Loads a run the caller can see, or 404. */
  const visibleRun = async (claims: JwtClaims, id: string) => {
    const [run] = await withUserSession(db, claims, (tx) =>
      tx.select().from(runs).where(eq(runs.id, id)),
    );
    if (!run) throw new ApiError(404, "run_not_found", "Run not found");
    return run;
  };

  const audit = (
    orgId: string,
    actor: string,
    action: string,
    targetType: string,
    targetId: string,
    metadata: object = {},
  ) =>
    db.execute(sql`insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id, metadata)
                   values (${orgId}::uuid, 'user', ${actor}::uuid, ${action}, ${targetType}, ${targetId}::uuid, ${JSON.stringify(metadata)}::jsonb)`);

  /** Model choices must point at credentials in the bot's own org. */
  const checkPolicy = async (
    claims: JwtClaims,
    orgId: string,
    policy:
      | {
          primary?: { credential_id: string };
          fallbacks?: Array<{ credential_id: string }>;
          cheap?: { credential_id: string };
        }
      | undefined,
  ) => {
    if (!policy) return;
    const ids = [policy.primary, ...(policy.fallbacks ?? []), policy.cheap]
      .filter(Boolean)
      .map((c) => (c as { credential_id: string }).credential_id);
    if (!ids.length) return;
    const found = await withUserSession(db, claims, (tx) =>
      tx
        .select({ id: modelCredentials.id })
        .from(modelCredentials)
        .where(and(eq(modelCredentials.orgId, orgId), inArray(modelCredentials.id, ids))),
    );
    if (new Set(found.map((r) => r.id)).size !== new Set(ids).size) {
      throw new ApiError(
        400,
        "validation_failed",
        "model_policy refers to a credential outside this organization",
        {
          errors: [{ path: "model_policy", message: "Unknown credential" }],
        },
      );
    }
  };

  app.openapi(routes.createBot, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const body = c.req.valid("json");
    const org = await withUserSession(db, claims, (tx) =>
      tx.execute(sql`select public.is_member(${body.org_id}::uuid) as ok`),
    );
    if (!(org[0] as { ok?: boolean } | undefined)?.ok)
      throw new ApiError(404, "org_not_found", "Organization not found");
    await checkPolicy(claims, body.org_id, body.model_policy);
    await enforceLimit(db, body.org_id, "max_bots");
    const [bot] = await withUserSession(db, claims, (tx) =>
      tx
        .insert(bots)
        .values({
          orgId: body.org_id,
          createdBy: claims.sub,
          name: body.name,
          // An empty persona falls back to the template's instructions.
          personaMd:
            body.persona_md?.trim() ||
            (body.template_id ? (templateById(body.template_id)?.persona ?? "") : ""),
          avatarUrl: body.avatar_url,
          modelPolicy: body.model_policy ?? {},
          autonomy:
            body.autonomy ??
            (body.template_id ? templateById(body.template_id)?.autonomy : undefined) ??
            "ask_risky",
          visibility: body.visibility ?? "team",
          budget: { per_run_usd: 1, daily_usd: 10, ...body.budget },
        })
        .returning(),
    );
    if (!bot) throw new Error("bot insert returned nothing");
    if (body.template_id) await applyTemplate(db, bot.id, bot.orgId, claims.sub, body.template_id);
    await audit(
      bot.orgId,
      claims.sub,
      "bot.created",
      "bot",
      bot.id,
      body.template_id ? { template: body.template_id } : {},
    );
    return c.json(botOut(bot), 201);
  });

  app.openapi(routes.listBots, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { org_id, archived } = c.req.valid("query");
    const rows = await withUserSession(db, claims, (tx) =>
      tx
        .select()
        .from(bots)
        .where(
          and(
            eq(bots.orgId, org_id),
            archived === "true" ? isNotNull(bots.archivedAt) : isNull(bots.archivedAt),
          ),
        )
        .orderBy(bots.sortKey, bots.createdAt),
    );
    return c.json({ items: rows.map(botOut) }, 200);
  });

  app.openapi(routes.startBotSetup, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const created = await withUserSession(db, claims, async (tx) => {
      const [bot] = await tx.execute<{ org_id: string; manage: boolean; suspended: boolean }>(sql`
        select b.org_id, public.can_manage_bot(b.id) as manage, o.suspended_at is not null as suspended
        from public.bots b join public.organizations o on o.id = b.org_id where b.id = ${id}::uuid and b.archived_at is null`);
      if (!bot) throw new ApiError(404, "bot_not_found", "Bot not found");
      if (!bot.manage)
        throw new ApiError(403, "forbidden", "Only people who manage this bot can set it up");
      if (bot.suspended)
        throw new ApiError(
          403,
          "workspace_suspended",
          "This workspace is suspended. Contact the instance owner.",
        );
      const [conv] = await tx.execute<{ id: string }>(sql`
        insert into public.conversations (org_id, bot_id, title, created_by, purpose, last_message_at)
        values (${bot.org_id}::uuid, ${id}::uuid, 'Setup', ${claims.sub}::uuid, 'setup', now()) returning id`);
      const [run] = await tx.execute<{ id: string }>(sql`
        insert into public.runs (org_id, bot_id, conversation_id, created_by, trigger)
        values (${bot.org_id}::uuid, ${id}::uuid, ${conv?.id}::uuid, ${claims.sub}::uuid, 'chat') returning id`);
      await tx.execute(sql`
        insert into public.messages (org_id, conversation_id, role, author_user_id, content, run_id)
        values (${bot.org_id}::uuid, ${conv?.id}::uuid, 'user', ${claims.sub}::uuid,
                ${JSON.stringify([{ type: "text", text: "Let's get you set up." }])}::jsonb, ${run?.id}::uuid)`);
      await tx.execute(
        sql`update public.bots set setup_status = 'pending' where id = ${id}::uuid and setup_status <> 'pending'`,
      );
      return { conversation_id: conv?.id as string, run_id: run?.id as string };
    });
    await deps.workflows.startRun(created.run_id);
    return c.json(created, 201);
  });

  app.openapi(routes.createConversation, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const body = c.req.valid("json");
    const conv = await withUserSession(db, claims, async (tx) => {
      const [bot] = await tx
        .select({ orgId: bots.orgId })
        .from(bots)
        .where(eq(bots.id, body.bot_id));
      if (!bot) throw new ApiError(404, "bot_not_found", "Bot not found");
      // A group chat (D-118): the lead first, then the others, all in this workspace and visible to you.
      const ids = body.bot_ids ? [body.bot_id, ...body.bot_ids.filter((b) => b !== body.bot_id)] : [];
      if (ids.length > 10) throw new ApiError(400, "too_many_bots", "A group chat has up to 10 bots");
      if (body.bot_ids && ids.length < 2) throw new ApiError(400, "too_few_bots", "A group chat needs at least 2 bots");
      if (ids.length) {
        const seen = await tx.execute<{ id: string }>(sql`
          select id from public.bots where org_id = ${bot.orgId}::uuid and archived_at is null and public.can_access_bot(id)
            and id in (select jsonb_array_elements_text(${JSON.stringify(ids)}::jsonb)::uuid)`);
        if (seen.length !== ids.length) throw new ApiError(400, "bot_not_found", "Every bot must be in this workspace and visible to you");
      }
      const [row] = await tx
        .insert(conversations)
        .values({ orgId: bot.orgId, botId: body.bot_id, title: body.title, createdBy: claims.sub, kind: ids.length ? "group" : "direct" })
        .returning();
      for (const [i, b] of ids.entries())
        await tx.execute(sql`
          insert into public.conversation_bots (conversation_id, bot_id, org_id, role, position)
          values (${row?.id}::uuid, ${b}::uuid, ${bot.orgId}::uuid, ${i === 0 ? "lead" : "member"}, ${i})`);
      return row ? { row, ids } : undefined;
    });
    if (!conv) throw new Error("conversation insert returned nothing");
    return c.json(convOut(conv.row, conv.ids), 201);
  });

  app.openapi(routes.listConversations, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const rows = await withUserSession(db, claims, async (tx) => {
      const [bot] = await tx.select({ id: bots.id }).from(bots).where(eq(bots.id, id));
      if (!bot) throw new ApiError(404, "bot_not_found", "Bot not found");
      return tx
        .select()
        .from(conversations)
        .where(and(eq(conversations.botId, id), eq(conversations.kind, "direct")))
        .orderBy(desc(sql`coalesce(${conversations.lastMessageAt}, ${conversations.createdAt})`))
        .limit(100);
    });
    return c.json({ items: rows.map((r) => convOut(r)) }, 200);
  });

  app.openapi(routes.listGroupChats, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { org_id } = c.req.valid("query");
    const out = await withUserSession(db, claims, async (tx) => {
      const rows = await tx
        .select()
        .from(conversations)
        .where(and(eq(conversations.orgId, org_id), eq(conversations.kind, "group")))
        .orderBy(desc(sql`coalesce(${conversations.lastMessageAt}, ${conversations.createdAt})`))
        .limit(100);
      const members = rows.length
        ? await tx.execute<{ conversation_id: string; bot_id: string }>(sql`
            select conversation_id, bot_id from public.conversation_bots
            where conversation_id in (select jsonb_array_elements_text(${JSON.stringify(rows.map((r) => r.id))}::jsonb)::uuid)
            order by position`)
        : [];
      return rows.map((r) => convOut(r, members.filter((m) => m.conversation_id === r.id).map((m) => m.bot_id)));
    });
    return c.json({ items: out }, 200);
  });

  app.openapi(routes.editMessage, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id, message_id } = c.req.valid("param");
    const { text } = c.req.valid("json");
    const created = await withUserSession(db, claims, async (tx) => {
      const [m] = await tx.execute<{
        org_id: string;
        bot_id: string;
        parent: string | null;
        role: string;
        content: unknown;
      }>(sql`
        select m.org_id, c.bot_id, m.parent_message_id as parent, m.role, m.content
        from public.messages m join public.conversations c on c.id = m.conversation_id
        where m.id = ${message_id}::uuid and m.conversation_id = ${id}::uuid`);
      if (!m) throw new ApiError(404, "message_not_found", "Message not found");
      if (m.role !== "user")
        throw new ApiError(400, "not_editable", "Only your own messages can be edited");
      const [busy] = await tx.execute<{ id: string }>(sql`
        select id from public.runs where conversation_id = ${id}::uuid
          and status in ('queued', 'running', 'waiting_approval', 'waiting_takeover') limit 1`);
      if (busy)
        throw new ApiError(
          409,
          "run_in_progress",
          "Wait for the bot to finish, or stop it, before editing",
        );
      const [run] = await tx.execute<{ id: string }>(sql`
        insert into public.runs (org_id, bot_id, conversation_id, created_by, trigger)
        values (${m.org_id}::uuid, ${m.bot_id}::uuid, ${id}::uuid, ${claims.sub}::uuid, 'chat') returning id`);
      // The new text keeps the original's attachments and picked skills.
      const kept = Array.isArray(m.content)
        ? (m.content as Array<{ type?: string }>).filter((p) => p.type !== "text")
        : [];
      if (!m.parent) await tx.execute(sql`select set_config('kasama.branch_root', 'on', true)`);
      const [msg] = await tx.execute<{ id: string }>(sql`
        insert into public.messages (org_id, conversation_id, role, author_user_id, content, run_id, parent_message_id)
        values (${m.org_id}::uuid, ${id}::uuid, 'user', ${claims.sub}::uuid,
                ${JSON.stringify([{ type: "text", text }, ...kept])}::jsonb, ${run?.id}::uuid, ${m.parent}::uuid)
        returning id`);
      await tx.execute(sql`
        update public.conversations set head_message_id = ${msg?.id}::uuid, last_message_at = now() where id = ${id}::uuid`);
      return { runId: run?.id as string, messageId: msg?.id as string };
    });
    try {
      await deps.workflows.startRun(created.runId);
    } catch {
      await db.execute(sql`update public.runs set status = 'failed', ended_at = now(),
        error = ${JSON.stringify({ code: "enqueue_failed", message: "The run could not be started." })}::jsonb
        where id = ${created.runId}::uuid`);
    }
    return c.json(
      { message_id: created.messageId, run_id: created.runId, conversation_id: id },
      202,
    );
  });

  app.openapi(routes.switchBranch, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const { message_id } = c.req.valid("json");
    const head = await withUserSession(db, claims, async (tx) => {
      const [m] = await tx.execute<{ leaf: string | null }>(sql`
        select public.branch_leaf(m.id) as leaf from public.messages m
        where m.id = ${message_id}::uuid and m.conversation_id = ${id}::uuid`);
      if (!m?.leaf) throw new ApiError(404, "message_not_found", "Message not found");
      await tx.execute(
        sql`update public.conversations set head_message_id = ${m.leaf}::uuid where id = ${id}::uuid`,
      );
      return m.leaf;
    });
    return c.json({ head_message_id: head }, 200);
  });

  /** A message in a group chat (D-118): the mentioned bots (or @everyone's lead, or whoever spoke last) each get a run. */
  const sendGroup = async (claims: JwtClaims, id: string, text: string, parts: unknown[]) => {
    const created = await withUserSession(db, claims, async (tx) => {
      const [conv] = await tx.execute<{ org_id: string; bot_id: string }>(sql`select org_id, bot_id from public.conversations where id = ${id}::uuid`);
      if (!conv) throw new ApiError(404, "conversation_not_found", "Conversation not found");
      const members = await tx.execute<{ id: string; name: string; role: string }>(sql`
        select b.id, b.name, cb.role from public.conversation_bots cb join public.bots b on b.id = cb.bot_id
        where cb.conversation_id = ${id}::uuid order by cb.position`);
      const { everyone, botIds } = parseMentions(text, members);
      let targets = everyone ? [conv.bot_id] : botIds;
      if (!targets.length) {
        const [last] = await tx.execute<{ bot_id: string }>(sql`
          select bot_id from public.messages where conversation_id = ${id}::uuid and role = 'assistant' and bot_id is not null
          order by created_at desc limit 1`);
        targets = [last?.bot_id && members.some((m) => m.id === last.bot_id) ? last.bot_id : conv.bot_id];
      }
      const [msg] = await tx.execute<{ id: string }>(sql`
        insert into public.messages (org_id, conversation_id, role, author_user_id, content)
        values (${conv.org_id}::uuid, ${id}::uuid, 'user', ${claims.sub}::uuid, ${JSON.stringify(parts)}::jsonb) returning id`);
      const runIds: string[] = [];
      for (const botId of targets) {
        const [run] = await tx.execute<{ id: string }>(sql`
          insert into public.runs (org_id, bot_id, conversation_id, created_by, trigger, trigger_message_id)
          values (${conv.org_id}::uuid, ${botId}::uuid, ${id}::uuid, ${claims.sub}::uuid, 'chat', ${msg?.id}::uuid) returning id`);
        if (run) runIds.push(run.id);
      }
      await tx.execute(sql`update public.conversations set last_message_at = now() where id = ${id}::uuid`);
      return { messageId: msg?.id as string, runIds };
    });
    for (const r of created.runIds) await deps.workflows.startRun(r);
    return { message_id: created.messageId, run_id: created.runIds[0] as string, conversation_id: id, run_ids: created.runIds };
  };

  app.openapi(routes.sendMessage, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const { text, attachments, ui_action, skills: picked } = c.req.valid("json");
    const [kind] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ kind: string }>(sql`select kind from public.conversations where id = ${id}::uuid`),
    );
    if (kind?.kind === "group")
      return c.json(
        await sendGroup(claims, id, text, [
          { type: "text", text },
          ...(attachments ?? []).map((f) => ({ type: "file", ...f })),
          ...(picked ?? []).map((name) => ({ type: "skill", name })),
        ]),
        202,
      );
    return withSpan("chat.send", { conversation_id: id }, async (span) => {
      const created = await withUserSession(db, claims, async (tx) => {
        const [conv] = await tx.select().from(conversations).where(eq(conversations.id, id));
        if (!conv) throw new ApiError(404, "conversation_not_found", "Conversation not found");
        const [org] = await tx.execute<{ suspended: boolean }>(
          sql`select suspended_at is not null as suspended from public.organizations where id = ${conv.orgId}::uuid`,
        );
        if (org?.suspended)
          throw new ApiError(
            403,
            "workspace_suspended",
            "This workspace is suspended. Contact the instance owner.",
          );
        const [run] = await tx
          .insert(runs)
          .values({
            orgId: conv.orgId,
            botId: conv.botId,
            conversationId: conv.id,
            createdBy: claims.sub,
            trigger: "chat",
          })
          .returning();
        if (!run) throw new Error("run insert returned nothing");
        const [msg] = await tx.execute<{ id: string }>(sql`
          insert into public.messages (org_id, conversation_id, role, author_user_id, content, run_id)
          values (${conv.orgId}::uuid, ${conv.id}::uuid, 'user', ${claims.sub}::uuid,
                  ${JSON.stringify([
                    { type: "text", text },
                    ...(attachments ?? []).map((f) => ({ type: "file", ...f })),
                    ...(ui_action ? [{ type: "ui_action", ...ui_action }] : []),
                    ...(picked ?? []).map((name) => ({ type: "skill", name })),
                  ])}::jsonb, ${run.id}::uuid)
          returning id`);
        await tx
          .update(conversations)
          .set({ lastMessageAt: sql`now()` })
          .where(eq(conversations.id, conv.id));
        return { runId: run.id, messageId: (msg as { id: string }).id, orgId: conv.orgId };
      });
      span.setAttribute("run_id", created.runId);
      span.setAttribute("org_id", created.orgId);
      try {
        await deps.workflows.startRun(created.runId);
      } catch (err) {
        await db.execute(sql`update public.runs set status = 'failed', ended_at = now(),
          error = ${JSON.stringify({ code: "enqueue_failed", message: "The run could not be started." })}::jsonb
          where id = ${created.runId}::uuid`);
        throw err;
      }
      return c.json(
        { message_id: created.messageId, run_id: created.runId, conversation_id: id },
        202,
      );
    });
  });

  app.openapi(routes.getRun, async (c) => {
    const claims = requireClaims(c.get("claims"));
    return c.json(runOut(await visibleRun(claims, c.req.valid("param").id)), 200);
  });

  app.openapi(routes.cancelRun, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const run = await visibleRun(claims, id);
    if (TERMINAL_STATUS.has(run.status))
      throw new ApiError(409, "run_finished", `The run is already ${run.status}`);
    await withUserSession(db, claims, (tx) =>
      tx.execute(sql`select public.request_run_cancel(${id}::uuid)`),
    );
    await deps.workflows.signalRun(id);
    return c.json(runOut(await visibleRun(claims, id)), 202);
  });

  app.openapi(routes.listRunEvents, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const query = c.req.valid("query");
    const run = await visibleRun(claims, id);
    const lastEventId = Number(c.req.header("last-event-id") ?? Number.NaN);
    const after = Number.isFinite(lastEventId) ? lastEventId : (query.after_seq ?? 0);
    const limit = query.limit ?? 500;
    // Access was checked above under the user's session; the run id scopes every query below.
    const fetchAfter = (seq: number) =>
      db.execute<EventRow>(sql`
        select run_id, seq, bot_id, type, payload, created_at from public.run_events
        where run_id = ${id}::uuid and seq > ${seq} order by seq limit ${limit}`);

    if (!(c.req.header("accept") ?? "").includes("text/event-stream")) {
      const rows = await fetchAfter(after);
      const [fresh] = await db.execute<{ status: string }>(
        sql`select status from public.runs where id = ${id}::uuid`,
      );
      return c.json(
        { items: rows.map(eventOut), run_status: (fresh?.status ?? run.status) as "queued" },
        200,
      );
    }

    return streamSSE(c, async (stream) => {
      let last = after;
      let finished = false;
      let pending = Promise.resolve();
      let wake: (() => void) | undefined;
      const flush = () => {
        pending = pending.then(async () => {
          for (;;) {
            const rows = await fetchAfter(last);
            for (const row of rows) {
              await stream.writeSSE({
                event: "run_event",
                id: String(row.seq),
                data: JSON.stringify(eventOut(row)),
              });
              last = row.seq;
              if (TERMINAL_EVENTS.has(row.type)) finished = true;
            }
            if (rows.length < limit) break;
          }
          if (finished) wake?.();
        });
        return pending;
      };
      const unsubscribe = deps.hub.subscribe(id, () => void flush());
      stream.onAbort(() => {
        finished = true;
        wake?.();
      });
      try {
        await flush();
        if (!finished && TERMINAL_STATUS.has(run.status)) finished = true;
        while (!finished) {
          await new Promise<void>((resolve) => {
            wake = resolve;
            setTimeout(resolve, 15_000);
          });
          if (!finished) await stream.writeSSE({ event: "ping", data: "{}" });
          // Safety net if a notification was missed.
          await flush();
        }
      } finally {
        unsubscribe();
      }
    });
  });

  app.openapi(routes.createCredential, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const body = c.req.valid("json");
    const [{ allowed } = { allowed: false }] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ allowed: boolean }>(
        sql`select public.has_role(${body.org_id}::uuid, 'admin') as allowed`,
      ),
    );
    if (!allowed) throw new ApiError(403, "forbidden", "Only owners and admins can add model keys");
    if (body.provider === "chatgpt") {
      throw new ApiError(
        400,
        "validation_failed",
        "Connect a ChatGPT plan with ChatGPT sign-in (POST /v1/credentials/chatgpt/start)",
        { errors: [{ path: "provider", message: "Use ChatGPT sign-in" }] },
      );
    }
    if (body.provider === "openai_compatible" && !body.base_url) {
      throw new ApiError(400, "validation_failed", "base_url is required for openai_compatible", {
        errors: [{ path: "base_url", message: "Required" }],
      });
    }
    if (body.provider !== "openai_compatible" && !body.api_key) {
      throw new ApiError(400, "validation_failed", "api_key is required", {
        errors: [{ path: "api_key", message: "Required" }],
      });
    }
    // Vault writes need the server's role; the key is never stored anywhere else or returned.
    const cred = await db.transaction(async (tx) => {
      const [secret] = body.api_key
        ? await tx.execute<{ id: string }>(
            sql`select vault.create_secret(${body.api_key}, null, 'model credential') as id`,
          )
        : [];
      const [row] = await tx
        .insert(modelCredentials)
        .values({
          orgId: body.org_id,
          provider: body.provider,
          label: body.label,
          baseUrl: body.base_url,
          vaultSecretId: secret?.id ?? null,
          keyHint: body.api_key ? body.api_key.slice(-4) : null,
          createdBy: claims.sub,
        })
        .returning();
      return row;
    });
    if (!cred) throw new Error("credential insert returned nothing");
    await audit(cred.orgId, claims.sub, "credential.created", "model_credential", cred.id, {
      provider: cred.provider,
    });
    return c.json(credOut(cred), 201);
  });

  app.openapi(routes.listCredentials, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { org_id } = c.req.valid("query");
    const rows = await withUserSession(db, claims, (tx) =>
      tx
        .select()
        .from(modelCredentials)
        .where(eq(modelCredentials.orgId, org_id))
        .orderBy(modelCredentials.createdAt),
    );
    return c.json({ items: rows.map(credOut) }, 200);
  });

  app.openapi(routes.testCredential, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const body = (await c.req.json().catch(() => ({}))) as { model?: unknown };
    const model =
      typeof body.model === "string" && body.model.length <= 200 ? body.model : undefined;
    const [cred] = await withUserSession(db, claims, (tx) =>
      tx.select().from(modelCredentials).where(eq(modelCredentials.id, id)),
    );
    if (!cred) throw new ApiError(404, "credential_not_found", "Credential not found");
    if (cred.provider === "chatgpt") {
      // A ChatGPT plan is personal: only the person who signed in may use or test it.
      if (cred.ownerUserId !== claims.sub)
        throw new ApiError(403, "forbidden", "Only the person who connected this plan can test it");
    } else {
      const [{ allowed } = { allowed: false }] = await withUserSession(db, claims, (tx) =>
        tx.execute<{ allowed: boolean }>(
          sql`select public.has_role(${cred.orgId}::uuid, 'admin') as allowed`,
        ),
      );
      if (!allowed)
        throw new ApiError(403, "forbidden", "Only owners and admins can test model keys");
    }
    return c.json(await deps.workflows.testCredential(id, cred.orgId, model), 200);
  });

  /** Whether the caller may change or delete a credential: admins, or the owner of a personal one. */
  const canManage = async (claims: JwtClaims, cred: CredRow) => {
    if (cred.ownerUserId && cred.ownerUserId === claims.sub) return true;
    const [{ allowed } = { allowed: false }] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ allowed: boolean }>(
        sql`select public.has_role(${cred.orgId}::uuid, 'admin') as allowed`,
      ),
    );
    return allowed;
  };

  app.openapi(routes.updateCredential, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const body = c.req.valid("json");
    const [cred] = await withUserSession(db, claims, (tx) =>
      tx.select().from(modelCredentials).where(eq(modelCredentials.id, id)),
    );
    if (!cred) throw new ApiError(404, "credential_not_found", "Credential not found");
    if (body.fallback_on_limit !== undefined && cred.ownerUserId !== claims.sub)
      throw new ApiError(403, "forbidden", "Only the plan's owner can change this setting");
    if (!(await canManage(claims, cred)))
      throw new ApiError(403, "forbidden", "Only owners and admins can change model keys");
    const settings = {
      ...((cred.settings as Record<string, unknown> | null) ?? {}),
      ...(body.fallback_on_limit !== undefined
        ? { fallback_on_limit: body.fallback_on_limit }
        : {}),
    };
    const [row] = await db
      .update(modelCredentials)
      .set({ label: body.label ?? cred.label, settings })
      .where(eq(modelCredentials.id, id))
      .returning();
    if (!row) throw new ApiError(404, "credential_not_found", "Credential not found");
    await audit(row.orgId, claims.sub, "credential.updated", "model_credential", row.id, {
      fields: Object.keys(body),
    });
    return c.json(credOut(row), 200);
  });

  app.openapi(routes.deleteCredential, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const [cred] = await withUserSession(db, claims, (tx) =>
      tx.select().from(modelCredentials).where(eq(modelCredentials.id, id)),
    );
    if (!cred) throw new ApiError(404, "credential_not_found", "Credential not found");
    if (!(await canManage(claims, cred)))
      throw new ApiError(403, "forbidden", "Only owners and admins can delete model keys");
    if (cred.provider === "chatgpt") {
      // Revoke at OpenAI first; the credential is deleted even if OpenAI can't be reached.
      const revoked = await deps.workflows.revokeCredential(id).catch((err: unknown) => ({
        ok: false,
        error: (err as Error).message,
      }));
      if (!revoked.ok)
        deps.logger.warn("chatgpt revocation failed", { credential_id: id, error: revoked.error });
    }
    await db.transaction(async (tx) => {
      await tx.delete(modelCredentials).where(eq(modelCredentials.id, id));
      if (cred.vaultSecretId)
        await tx.execute(sql`delete from vault.secrets where id = ${cred.vaultSecretId}::uuid`);
    });
    await audit(cred.orgId, claims.sub, "credential.deleted", "model_credential", cred.id, {
      provider: cred.provider,
    });
    return c.body(null, 204);
  });

  // Model lists change rarely; a short cache keeps the picker fast and the providers unbothered.
  const modelCache = new Map<string, { at: number; value: ModelListOutcome }>();
  app.openapi(routes.listCredentialModels, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    // RLS limits this to members of the key's workspace; the key itself never leaves the worker.
    const [cred] = await withUserSession(db, claims, (tx) =>
      tx.select().from(modelCredentials).where(eq(modelCredentials.id, id)),
    );
    if (!cred) throw new ApiError(404, "credential_not_found", "Credential not found");
    const hit = modelCache.get(id);
    let value = hit && Date.now() - hit.at < 10 * 60_000 ? hit.value : undefined;
    if (!value) {
      value = await deps.workflows.listCredentialModels(id, cred.orgId).catch(() => ({
        models: [],
        source: "featured" as const,
        error: "Could not load the model list.",
      }));
      if (value.source === "live") modelCache.set(id, { at: Date.now(), value });
    }
    return c.json({ items: value.models, source: value.source, error: value.error }, 200);
  });

  app.openapi(routes.listMemories, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const { q } = c.req.valid("query");
    const rows = await withUserSession(db, claims, async (tx) => {
      const [bot] = await tx.select({ id: bots.id }).from(bots).where(eq(bots.id, id));
      if (!bot) throw new ApiError(404, "bot_not_found", "Bot not found");
      const where = q
        ? and(eq(memories.botId, id), sql`${memories.tsv} @@ websearch_to_tsquery('simple', ${q})`)
        : eq(memories.botId, id);
      return tx
        .select()
        .from(memories)
        .where(where)
        .orderBy(desc(memories.pinned), desc(memories.updatedAt))
        .limit(500);
    });
    return c.json(
      {
        items: rows.map((m) => ({
          id: m.id,
          kind: m.kind as "fact",
          content: m.content,
          importance: m.importance,
          pinned: m.pinned,
          created_at: iso(m.createdAt),
          updated_at: iso(m.updatedAt),
        })),
      },
      200,
    );
  });

  app.openapi(routes.getUsage, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { org_id, period = "month" } = c.req.valid("query");
    type Sums = { cost: string; tin: string; tout: string };
    const sums = sql`sum(u.cost_usd) as cost,
      sum(case when u.kind = 'tokens_in' then u.quantity else 0 end) as tin,
      sum(case when u.kind = 'tokens_out' then u.quantity else 0 end) as tout`;
    const report = await withUserSession(db, claims, async (tx) => {
      const [m] = await tx.execute<{ ok: boolean }>(
        sql`select public.is_member(${org_id}::uuid) as ok`,
      );
      if (!m?.ok) throw new ApiError(404, "org_not_found", "Organization not found");
      const [s] = await tx.execute<{ t: Date }>(
        sql`select date_trunc(${period}, now() at time zone 'utc') at time zone 'utc' as t`,
      );
      const since = s?.t ?? new Date();
      const scope = sql`u.org_id = ${org_id}::uuid and u.created_at >= ${since}`;
      const bots_ = await tx.execute<Sums & { bot_id: string | null; name: string | null }>(sql`
        select u.bot_id, b.name, ${sums}
        from public.usage_ledger u left join public.bots b on b.id = u.bot_id
        where ${scope} group by u.bot_id, b.name order by cost desc`);
      const days = await tx.execute<Sums & { day: string }>(sql`
        select to_char(date_trunc('day', u.created_at at time zone 'utc'), 'YYYY-MM-DD') as day, ${sums}
        from public.usage_ledger u where ${scope} group by 1 order by 1`);
      const models = await tx.execute<Sums & { model: string | null }>(sql`
        select u.model, ${sums} from public.usage_ledger u
        where ${scope} group by u.model order by cost desc`);
      const kinds = await tx.execute<{ kind: string; quantity: string; cost: string }>(sql`
        select u.kind, sum(u.quantity) as quantity, sum(u.cost_usd) as cost
        from public.usage_ledger u where ${scope} group by u.kind order by cost desc`);
      const [r] = await tx.execute<{ n: string }>(
        sql`select count(distinct u.run_id) as n from public.usage_ledger u where ${scope}`,
      );
      return { since, bots_, days, models, kinds, runs: Number(r?.n ?? 0) };
    });
    const num = (r: Sums) => ({
      cost_usd: Number(r.cost),
      tokens_in: Number(r.tin),
      tokens_out: Number(r.tout),
    });
    const by_bot = report.bots_.map((r) => ({ bot_id: r.bot_id, name: r.name, ...num(r) }));
    return c.json(
      {
        period,
        since: iso(report.since),
        total_cost_usd: by_bot.reduce((n, b) => n + b.cost_usd, 0),
        by_bot,
        by_day: report.days.map((r) => ({ day: r.day, ...num(r) })),
        by_model: report.models.map((r) => ({ model: r.model, ...num(r) })),
        by_kind: report.kinds.map((r) => ({
          kind: r.kind,
          quantity: Number(r.quantity),
          cost_usd: Number(r.cost),
        })),
        runs: report.runs,
      },
      200,
    );
  });
}
