import {
  existingWelcome,
  handleWelcomeAction,
  memoryStoreFor,
  milestone,
  PLATFORM_OPENROUTER_CREDENTIAL_ID,
  type StoredMemory,
  spaceName,
  startWelcome,
  storeFromConfig,
  track,
} from "@casama/agent";
import { ProviderId, routes } from "@casama/contracts";
import { contentKeys, type JwtClaims, schema, withUserSession } from "@casama/db";
import {
  CLOUD_LOCKED_MODEL,
  cloudRunPolicy,
  defaultModelFor,
  FEATURED_MODELS,
  lockCloudPolicy,
  parseMentions,
} from "@casama/domain";
import { withSpan } from "@casama/observability";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { and, desc, eq, inArray, isNotNull, isNull, sql } from "drizzle-orm";
import { streamSSE } from "hono/streaming";
import { enforceLimit } from "../../billing/limits.ts";
import { modelOverrides } from "../../env.ts";
import { getCloudModels } from "../../services/cloud-models.ts";
import { findTemplate } from "../../services/gallery.ts";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { iso } from "../util.ts";
import type { ModelListOutcome } from "../workflows.ts";
import { applyTemplate } from "./autonomy.ts";

const { bots, conversations, runs, modelCredentials } = schema;
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

const PREVIEW_MAX = 160;

/** One line of plain text for a chat list row: markdown marks dropped, whitespace collapsed. */
export function previewText(text: string): string {
  const plain = text
    .replace(/```[^\n]*\n?/g, " ")
    .replace(/!\[([^\]]*)\]\([^)]*\)/g, "$1")
    .replace(/\[([^\]]+)\]\([^)]*\)/g, "$1")
    .replace(/^\s{0,3}(#{1,6}|>|[-*+]|\d+\.)\s+/gm, "")
    .replace(/(\*\*|__|~~|`)/g, "")
    .replace(/\s+/g, " ")
    .trim();
  return plain.length > PREVIEW_MAX ? `${plain.slice(0, PREVIEW_MAX - 1).trimEnd()}…` : plain;
}

/** A message's preview, or null when it has nothing to show (a tool-only turn, a UI action). */
export function messagePreview(
  content: unknown,
): { text: string; file_name: string | null; file_mime: string | null } | null {
  if (!Array.isArray(content)) return null;
  const parts = content.filter((p): p is Record<string, unknown> => !!p && typeof p === "object");
  // A suggestion card has no text of its own (D-257): its title (or titles) stands in.
  const cards = parts.flatMap((p) =>
    p.type === "suggestion" && typeof p.title === "string"
      ? [p.title]
      : p.type === "suggestions" && Array.isArray(p.items)
        ? (p.items as Array<{ title?: unknown }>).flatMap((i) =>
            typeof i?.title === "string" ? [i.title] : [],
          )
        : [],
  );
  const text = previewText(
    [
      ...parts
        .filter((p) => p.type === "text" && typeof p.text === "string")
        .map((p) => p.text as string),
      ...cards,
    ].join(" "),
  );
  const file = parts.find((p) => p.type === "file" && typeof p.path === "string");
  if (!text && !file) return null;
  return {
    text,
    file_name: file
      ? String(file.name ?? (file.path as string).split("/").pop() ?? "").slice(0, 255)
      : null,
    file_mime: file && typeof file.mime_type === "string" ? file.mime_type : null,
  };
}

type ConvRow = typeof conversations.$inferSelect;
const convOut = (
  c: ConvRow,
  botIds: string[] = [],
  canDelete?: boolean,
  status?: "needs_you" | "working" | null,
) => ({
  ...(canDelete === undefined ? {} : { can_delete: canDelete }),
  id: c.id,
  bot_id: c.botId,
  title: c.title,
  last_message_at: c.lastMessageAt ? iso(c.lastMessageAt) : null,
  kind: (c.kind ?? "direct") as "direct",
  bot_ids: botIds.length ? botIds : [c.botId],
  created_at: iso(c.createdAt),
  // General and topics (D-253).
  is_main: c.isMain,
  parent_conversation_id: c.parentConversationId,
  anchor_message_id: c.anchorMessageId,
  ...(status === undefined ? {} : { status }),
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

/** Casama Cloud's shared key is not a row. It cannot be renamed, tested or deleted (D-186). */
function rejectCloudKey(id: string) {
  if (id === PLATFORM_OPENROUTER_CREDENTIAL_ID)
    throw new ApiError(
      403,
      "forbidden",
      "Casama Cloud's key stays with the workspace. Add your own key to use another model.",
    );
}

function cloudCredential(orgId: string) {
  return {
    id: PLATFORM_OPENROUTER_CREDENTIAL_ID,
    org_id: orgId,
    provider: "openrouter" as const,
    label: "Casama Cloud",
    base_url: null,
    key_hint: null,
    last_tested_at: null,
    last_test_ok: null,
    owner_user_id: null,
    status: "ok" as const,
    account: null,
    fallback_on_limit: false,
    embedding_model: null,
    created_at: "2026-11-11T00:00:00.000Z",
  };
}

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
  embedding_model: (c.settings as { embedding_model?: string } | null)?.embedding_model || null,
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
    const [run, visible] = await withUserSession(
      db,
      claims,
      async (tx) =>
        [
          (await tx.select().from(runs).where(eq(runs.id, id)))[0],
          // A private conversation's runs (personal device data) are only for its starter (audit 2026-11).
          (await tx.execute<{ ok: boolean }>(sql`select public.run_visible(${id}::uuid) as ok`))[0]
            ?.ok,
        ] as const,
    );
    if (!run || !visible) throw new ApiError(404, "run_not_found", "Run not found");
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
    // Casama's shared key is not a row. It is valid only while the server has one (D-186).
    if (ids.includes(PLATFORM_OPENROUTER_CREDENTIAL_ID) && !deps.env.CLOUD_MODEL_UPSTREAM_KEY)
      throw new ApiError(
        400,
        "validation_failed",
        "model_policy refers to a credential outside this organization",
        {
          errors: [{ path: "model_policy", message: "Unknown credential" }],
        },
      );
    const own = ids.filter((id) => id !== PLATFORM_OPENROUTER_CREDENTIAL_ID);
    if (!own.length) return;
    const found = await withUserSession(db, claims, (tx) =>
      tx
        .select({ id: modelCredentials.id })
        .from(modelCredentials)
        .where(and(eq(modelCredentials.orgId, orgId), inArray(modelCredentials.id, own))),
    );
    if (new Set(found.map((r) => r.id)).size !== new Set(own).size) {
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
    await enforceLimit(db, body.org_id, "max_bots", claims.sub);
    const modelPolicy =
      deps.env.BILLING_ENABLED && deps.env.CLOUD_MODEL_UPSTREAM_KEY
        ? cloudRunPolicy(await getCloudModels(db))
        : deps.env.BILLING_ENABLED || deps.env.CLOUD_MODEL_UPSTREAM_KEY
          ? lockCloudPolicy(
              body.model_policy ?? {},
              defaultModelFor("openrouter", modelOverrides(deps.env)) ?? CLOUD_LOCKED_MODEL,
            )
          : (body.model_policy ?? {});
    await checkPolicy(claims, body.org_id, modelPolicy);
    // A built-in starter bot or one from the gallery (D-241).
    const template = body.template_id ? await findTemplate(deps.env, body.template_id) : undefined;
    if (body.template_id && !template)
      throw new ApiError(404, "template_not_found", "That starter bot isn't available");
    const [bot] = await withUserSession(db, claims, (tx) =>
      tx
        .insert(bots)
        .values({
          orgId: body.org_id,
          createdBy: claims.sub,
          name: body.name,
          // An empty persona falls back to the template's instructions.
          personaMd: body.persona_md?.trim() || (template?.persona ?? ""),
          avatarUrl: body.avatar_url,
          modelPolicy,
          autonomy: body.autonomy ?? template?.autonomy ?? "ask_risky",
          visibility: body.visibility ?? "team",
          budget: { per_run_usd: 1, daily_usd: 10, ...body.budget },
        })
        .returning(),
    );
    if (!bot) throw new Error("bot insert returned nothing");
    if (template) await applyTemplate(db, bot.id, bot.orgId, claims.sub, template);
    await audit(
      bot.orgId,
      claims.sub,
      "bot.created",
      "bot",
      bot.id,
      body.template_id ? { template: body.template_id } : {},
    );
    track(db, {
      event: "bot_created",
      userId: claims.sub,
      orgId: bot.orgId,
      properties: {
        source: body.template_id ? "template" : "manual",
        template_id: body.template_id ?? null,
        autonomy: bot.autonomy,
      },
    });
    milestone(db, claims.sub, "first_bot_created", bot.orgId);
    return c.json(botOut(bot), 201);
  });

  app.openapi(routes.listBots, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { org_id, archived } = c.req.valid("query");
    const { rows, recent } = await withUserSession(db, claims, async (tx) => {
      const rows = await tx
        .select()
        .from(bots)
        .where(
          and(
            eq(bots.orgId, org_id),
            archived === "true" ? isNotNull(bots.archivedAt) : isNull(bots.archivedAt),
          ),
        )
        .orderBy(bots.sortKey, bots.createdAt);
      if (!rows.length) return { rows, recent: [] };
      // Each bot's most recent direct chat the caller can see (RLS hides others' private chats),
      // and its last few messages: a tool-only turn has no text, so the newest one with some wins.
      const recent = await tx.execute<{
        bot_id: string;
        conversation_id: string;
        role: string;
        author_user_id: string | null;
        content: unknown;
        created_at: string;
      }>(sql`
        with latest as (
          select distinct on (c.bot_id) c.id, c.bot_id
          from public.conversations c
          where c.org_id = ${org_id}::uuid and c.kind = 'direct' and c.last_message_at is not null
            and c.bot_id in (${sql.join(
              rows.map((b) => sql`${b.id}::uuid`),
              sql`, `,
            )})
          order by c.bot_id, c.last_message_at desc
        )
        select l.bot_id, l.id as conversation_id, m.role, m.author_user_id, m.content, m.created_at
        from latest l
        cross join lateral (
          select role, author_user_id, content, created_at from public.messages
          where conversation_id = l.id and role in ('user', 'assistant')
          order by created_at desc limit 6
        ) m
        order by l.bot_id, m.created_at desc`);
      return { rows, recent };
    });
    const last = new Map<
      string,
      NonNullable<ReturnType<typeof messagePreview>> & {
        from: "you" | "bot" | "someone";
        conversation_id: string;
        at: string;
      }
    >();
    for (const r of recent) {
      if (last.has(r.bot_id)) continue;
      const preview = messagePreview(contentKeys.open(r.content));
      if (!preview) continue;
      last.set(r.bot_id, {
        ...preview,
        from: r.role === "assistant" ? "bot" : r.author_user_id === claims.sub ? "you" : "someone",
        conversation_id: r.conversation_id,
        at: iso(r.created_at),
      });
    }
    return c.json(
      { items: rows.map((b) => ({ ...botOut(b), last_message: last.get(b.id) ?? null })) },
      200,
    );
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
        insert into public.conversations (org_id, bot_id, title, created_by, purpose, last_message_at, personal)
        values (${bot.org_id}::uuid, ${id}::uuid, 'Setup', ${claims.sub}::uuid, 'setup', now(), true) returning id`);
      const [run] = await tx.execute<{ id: string }>(sql`
        insert into public.runs (org_id, bot_id, conversation_id, created_by, trigger)
        values (${bot.org_id}::uuid, ${id}::uuid, ${conv?.id}::uuid, ${claims.sub}::uuid, 'chat') returning id`);
      await tx.execute(sql`
        insert into public.messages (org_id, conversation_id, role, author_user_id, content, run_id)
        values (${bot.org_id}::uuid, ${conv?.id}::uuid, 'user', ${claims.sub}::uuid,
                ${contentKeys.sealJson(bot.org_id, [{ type: "text", text: "Let's get you set up." }])}::jsonb, ${run?.id}::uuid)`);
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
      const ids = body.bot_ids
        ? [body.bot_id, ...body.bot_ids.filter((b) => b !== body.bot_id)]
        : [];
      if (ids.length > 10)
        throw new ApiError(400, "too_many_bots", "A group chat has up to 10 bots");
      if (body.bot_ids && ids.length < 2)
        throw new ApiError(400, "too_few_bots", "A group chat needs at least 2 bots");
      if (ids.length) {
        const seen = await tx.execute<{ id: string }>(sql`
          select id from public.bots where org_id = ${bot.orgId}::uuid and archived_at is null and public.can_access_bot(id)
            and id in (select jsonb_array_elements_text(${JSON.stringify(ids)}::jsonb)::uuid)`);
        if (seen.length !== ids.length)
          throw new ApiError(
            400,
            "bot_not_found",
            "Every bot must be in this workspace and visible to you",
          );
      }
      const [row] = await tx
        .insert(conversations)
        .values({
          orgId: bot.orgId,
          botId: body.bot_id,
          title: body.title,
          createdBy: claims.sub,
          kind: ids.length ? "group" : "direct",
          // A person's own chat with the bot: General or a topic under it (D-253).
          personal: !ids.length,
        })
        .returning();
      for (const [i, b] of ids.entries())
        await tx.execute(sql`
          insert into public.conversation_bots (conversation_id, bot_id, org_id, role, position)
          values (${row?.id}::uuid, ${b}::uuid, ${bot.orgId}::uuid, ${i === 0 ? "lead" : "member"}, ${i})`);
      return row ? { row, ids } : undefined;
    });
    if (!conv) throw new Error("conversation insert returned nothing");
    return c.json(convOut(conv.row, conv.ids, true), 201);
  });

  // Deleting chats: the database lets the person who started one, or a manager of its bot, delete
  // it (conversations_delete); messages and attachments go with it, runs and pages stay unlinked.
  const ACTIVE_RUN = sql`('queued', 'running', 'waiting_approval', 'waiting_takeover')`;
  const busyIds = async (ids: string[]) => {
    if (!ids.length) return new Set<string>();
    const rows = await db.execute<{ id: string }>(sql`
      select distinct conversation_id as id from public.runs
      where status in ${ACTIVE_RUN}
        and conversation_id in (select jsonb_array_elements_text(${JSON.stringify(ids)}::jsonb)::uuid)`);
    return new Set(rows.map((r) => r.id));
  };
  /** Removes the chat's photos and recordings, which aren't tied to it by a foreign key. */
  const dropMedia = (ids: string[]) =>
    ids.length
      ? db.execute(sql`delete from public.chat_media
          where conversation_id in (select jsonb_array_elements_text(${JSON.stringify(ids)}::jsonb)::uuid)`)
      : Promise.resolve();

  /** Also deleting what was made there (D-274): hidden now, purged with the Library's 30 days. */
  const dropCreations = (
    tx: Parameters<Parameters<typeof withUserSession>[2]>[0],
    ids: string[],
  ) =>
    ids.length
      ? tx.execute(sql`update public.creations set deleted_at = now(), updated_at = now()
          where deleted_at is null
            and conversation_id in (select jsonb_array_elements_text(${JSON.stringify(ids)}::jsonb)::uuid)`)
      : Promise.resolve();

  app.openapi(routes.deleteConversation, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const withCreations = c.req.valid("query").with_creations === "true";
    const conv = await withUserSession(db, claims, async (tx) => {
      const [row] = await tx.select().from(conversations).where(eq(conversations.id, id));
      if (!row) throw new ApiError(404, "conversation_not_found", "Conversation not found");
      if ((await busyIds([id])).size)
        throw new ApiError(
          409,
          "conversation_busy",
          "The bot is still working in this chat. Stop it first, then delete the chat.",
        );
      if (withCreations) await dropCreations(tx, [id]);
      const gone = await tx
        .delete(conversations)
        .where(eq(conversations.id, id))
        .returning({ id: conversations.id });
      if (!gone.length)
        throw new ApiError(
          403,
          "forbidden",
          "Only the person who started this chat or someone who manages the bot can delete it",
        );
      return row;
    });
    // What the bot made stays in the Library unless asked (D-274, changing D-220).
    if (withCreations) await dropMedia([id]);
    await audit(conv.orgId, claims.sub, "conversation.deleted", "conversation", id, {
      bot_id: conv.botId,
      kind: conv.kind,
    });
    return c.json({ deleted: id }, 200);
  });

  app.openapi(routes.deleteBotConversations, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const withCreations = c.req.valid("query").with_creations === "true";
    const out = await withUserSession(db, claims, async (tx) => {
      const [bot] = await tx
        .select({ id: bots.id, orgId: bots.orgId })
        .from(bots)
        .where(eq(bots.id, id));
      if (!bot) throw new ApiError(404, "bot_not_found", "Bot not found");
      const rows = await tx
        .select({ id: conversations.id })
        .from(conversations)
        .where(and(eq(conversations.botId, id), eq(conversations.kind, "direct")));
      const busy = await busyIds(rows.map((r) => r.id));
      const candidates = rows.map((r) => r.id).filter((r) => !busy.has(r));
      // RLS keeps only the ones this person may delete.
      if (withCreations) await dropCreations(tx, candidates);
      const gone = candidates.length
        ? await tx
            .delete(conversations)
            .where(
              sql`${conversations.id} in (select jsonb_array_elements_text(${JSON.stringify(candidates)}::jsonb)::uuid)`,
            )
            .returning({ id: conversations.id })
        : [];
      return { orgId: bot.orgId, ids: gone.map((g) => g.id), skipped: busy.size };
    });
    if (withCreations) await dropMedia(out.ids);
    if (out.ids.length)
      await audit(out.orgId, claims.sub, "conversation.deleted_all", "bot", id, {
        count: out.ids.length,
      });
    return c.json({ deleted: out.ids.length, skipped: out.skipped }, 200);
  });

  app.openapi(routes.listConversations, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const rows = await withUserSession(db, claims, async (tx) => {
      const [bot] = await tx.select({ id: bots.id }).from(bots).where(eq(bots.id, id));
      if (!bot) throw new ApiError(404, "bot_not_found", "Bot not found");
      const [m] = await tx.execute<{ ok: boolean }>(
        sql`select public.can_manage_bot(${id}::uuid) as ok`,
      );
      // Your General first (D-253), then the newest.
      const list = await tx
        .select()
        .from(conversations)
        .where(and(eq(conversations.botId, id), eq(conversations.kind, "direct")))
        .orderBy(
          desc(sql`(${conversations.isMain} and ${conversations.createdBy} = ${claims.sub}::uuid)`),
          desc(sql`coalesce(${conversations.lastMessageAt}, ${conversations.createdAt})`),
        )
        .limit(100);
      // What each one is waiting on: a run that needs the person, or one still going.
      const states = list.length
        ? await tx.execute<{ id: string; status: "needs_you" | "working" }>(sql`
            select conversation_id as id,
              case when bool_or(status in ('waiting_approval', 'waiting_takeover')) then 'needs_you' else 'working' end as status
            from public.runs
            where status in ('queued', 'running', 'waiting_approval', 'waiting_takeover')
              and conversation_id in (select jsonb_array_elements_text(${JSON.stringify(list.map((r) => r.id))}::jsonb)::uuid)
            group by conversation_id`)
        : [];
      return { list, manage: !!m?.ok, states: new Map(states.map((s) => [s.id, s.status])) };
    });
    return c.json(
      {
        // Someone else's General (a manager sees it) is just a chat to you.
        items: rows.list.map((r) =>
          convOut(
            { ...r, isMain: r.isMain && r.createdBy === claims.sub },
            [],
            rows.manage || r.createdBy === claims.sub,
            rows.states.get(r.id) ?? null,
          ),
        ),
      },
      200,
    );
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
      const leads = [...new Set(rows.map((r) => r.botId))];
      const managed = leads.length
        ? await tx.execute<{ id: string }>(sql`
            select id from unnest(${`{${leads.join(",")}}`}::uuid[]) as id where public.can_manage_bot(id)`)
        : [];
      const manages = new Set(managed.map((m) => m.id));
      return rows.map((r) =>
        convOut(
          r,
          members.filter((m) => m.conversation_id === r.id).map((m) => m.bot_id),
          manages.has(r.botId) || r.createdBy === claims.sub,
        ),
      );
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
      if (!m.parent) await tx.execute(sql`select set_config('casama.branch_root', 'on', true)`);
      const [msg] = await tx.execute<{ id: string }>(sql`
        insert into public.messages (org_id, conversation_id, role, author_user_id, content, run_id, parent_message_id)
        values (${m.org_id}::uuid, ${id}::uuid, 'user', ${claims.sub}::uuid,
                ${contentKeys.sealJson(m.org_id, [{ type: "text", text }, ...kept])}::jsonb, ${run?.id}::uuid, ${m.parent}::uuid)
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
      const [conv] = await tx.execute<{ org_id: string; bot_id: string }>(
        sql`select org_id, bot_id from public.conversations where id = ${id}::uuid`,
      );
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
        targets = [
          last?.bot_id && members.some((m) => m.id === last.bot_id) ? last.bot_id : conv.bot_id,
        ];
      }
      const [msg] = await tx.execute<{ id: string }>(sql`
        insert into public.messages (org_id, conversation_id, role, author_user_id, content)
        values (${conv.org_id}::uuid, ${id}::uuid, 'user', ${claims.sub}::uuid, ${contentKeys.sealJson(conv.org_id, parts)}::jsonb) returning id`);
      const runIds: string[] = [];
      for (const botId of targets) {
        const [run] = await tx.execute<{ id: string }>(sql`
          insert into public.runs (org_id, bot_id, conversation_id, created_by, trigger, trigger_message_id)
          values (${conv.org_id}::uuid, ${botId}::uuid, ${id}::uuid, ${claims.sub}::uuid, 'chat', ${msg?.id}::uuid) returning id`);
        if (run) runIds.push(run.id);
      }
      await tx.execute(
        sql`update public.conversations set last_message_at = now() where id = ${id}::uuid`,
      );
      return { messageId: msg?.id as string, runIds };
    });
    for (const r of created.runIds) await deps.workflows.startRun(r);
    return {
      message_id: created.messageId,
      run_id: created.runIds[0] as string,
      conversation_id: id,
      run_ids: created.runIds,
    };
  };

  app.openapi(routes.sendMessage, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const { text, attachments, ui_action, skills: picked } = c.req.valid("json");
    const [kind] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ kind: string }>(
        sql`select kind from public.conversations where id = ${id}::uuid`,
      ),
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
    // Welcome chat (D-129): its scripted card actions are answered without a model.
    if (ui_action?.name.startsWith("welcome.")) {
      const [conv] = await withUserSession(db, claims, (tx) =>
        tx.execute<{ org_id: string; bot_id: string; welcome: unknown }>(
          sql`select org_id, bot_id, welcome from public.conversations where id = ${id}::uuid`,
        ),
      );
      if (!conv) throw new ApiError(404, "conversation_not_found", "Conversation not found");
      if (conv.welcome) {
        const r = await handleWelcomeAction(
          {
            db,
            modelOverrides: modelOverrides(deps.env),
            platformModel: Boolean(deps.env.CLOUD_MODEL_UPSTREAM_KEY),
          },
          { orgId: conv.org_id, botId: conv.bot_id, conversationId: id, userId: claims.sub },
          {
            name: ui_action.name,
            surface_id: ui_action.surface_id,
            context: ui_action.context as Record<string, unknown> | undefined,
          },
          text,
        );
        if (r.queue) await deps.workflows.startRun(r.runId);
        return c.json({ message_id: r.messageId, run_id: r.runId, conversation_id: id }, 202);
      }
    }
    // Sent while the bot is working on something here: the message joins that run, which sees it
    // before its next step and decides whether to fold it in, switch, or finish first.
    if (!ui_action) {
      const joined = await withUserSession(db, claims, async (tx) => {
        const [active] = await tx.execute<{ id: string; org_id: string }>(sql`
          select r.id, r.org_id from public.runs r
          where r.conversation_id = ${id}::uuid and r.status in ('queued', 'running')
            and r.cancel_requested_at is null
            and exists (select 1 from public.messages m where m.run_id = r.id and m.role = 'user')
          order by r.created_at desc limit 1`);
        if (!active) return null;
        const [msg] = await tx.execute<{ id: string }>(sql`
          insert into public.messages (org_id, conversation_id, role, author_user_id, content, run_id)
          values (${active.org_id}::uuid, ${id}::uuid, 'user', ${claims.sub}::uuid,
                  ${contentKeys.sealJson(active.org_id, [
                    { type: "text", text },
                    ...(attachments ?? []).map((f) => ({ type: "file", ...f })),
                  ])}::jsonb, ${active.id}::uuid)
          returning id`);
        await tx
          .update(conversations)
          .set({ lastMessageAt: sql`now()` })
          .where(eq(conversations.id, id));
        return { runId: active.id, messageId: (msg as { id: string }).id };
      });
      if (joined) {
        await deps.workflows.signalRun(joined.runId).catch(() => {});
        return c.json(
          { message_id: joined.messageId, run_id: joined.runId, conversation_id: id, joined: true },
          202,
        );
      }
    }
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
                  ${contentKeys.sealJson(conv.orgId, [
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
      milestone(db, claims.sub, "first_message", created.orgId);
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

  app.openapi(routes.startWelcome, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const b = c.req.valid("json");
    const found = await existingWelcome(db, claims.sub);
    if (found)
      return c.json(
        {
          org_id: found.orgId,
          bot_id: found.botId,
          conversation_id: found.conversationId,
          created: false,
        },
        200,
      );
    const [m] = await db.execute<{ n: number }>(
      sql`select count(*)::int as n from public.memberships where user_id = ${claims.sub}::uuid`,
    );
    if ((m?.n ?? 0) > 0) throw new ApiError(409, "has_workspace", "You already have a workspace");
    const email = typeof claims.email === "string" ? claims.email : "";
    const first = (
      b.first_name ??
      (claims.user_metadata as { full_name?: string } | undefined)?.full_name?.split(" ")[0] ??
      email.split("@")[0] ??
      ""
    ).trim();
    // The name they gave in onboarding comes first, so the workspace is "Oliver's space", not
    // one made from the email.
    const [chosen] = await db.execute<{ preferred: string | null }>(sql`
      select nullif(btrim(preferred_name), '') as preferred from public.profiles
      where user_id = ${claims.sub}::uuid`);
    const base = chosen?.preferred ?? first;
    const name = spaceName(base);
    let orgId: string | undefined;
    for (let attempt = 0; attempt < 5 && !orgId; attempt++) {
      const slug = `${
        (base || "space")
          .toLowerCase()
          .replace(/[^a-z0-9]+/g, "-")
          .replace(/^-|-$/g, "")
          .slice(0, 30) || "space"
      }-${Math.random().toString(36).slice(2, 8)}`;
      try {
        const [row] = await withUserSession(db, claims, (tx) =>
          tx.execute<{ id: string }>(
            sql`select id from public.create_organization(${name}, ${slug})`,
          ),
        );
        orgId = row?.id;
      } catch (err) {
        if (
          (err as { code?: string }).code !== "23505" &&
          (err as { cause?: { code?: string } }).cause?.code !== "23505"
        )
          throw err;
      }
    }
    if (!orgId) throw new ApiError(409, "slug_taken", "Could not create your space; try again");
    if (deps.billing?.enabled) await deps.billing.recompute(orgId);
    // A new person gets what a new bot gets: its empty chat, with apps to connect and starter
    // requests. There is no scripted welcome chat any more.
    const w = await startWelcome(db, {
      orgId,
      userId: claims.sub,
      botName: b.bot_name ?? "Casama",
      modelOverrides: modelOverrides(deps.env),
      platformModel: Boolean(deps.env.CLOUD_MODEL_UPSTREAM_KEY),
    });
    track(db, {
      event: "workspace_created",
      userId: claims.sub,
      orgId: w.orgId,
      properties: { source: "welcome" },
    });
    track(db, {
      event: "bot_created",
      userId: claims.sub,
      orgId: w.orgId,
      properties: { source: "welcome" },
    });
    // Onboarding is the space and bot made in one step; nothing is left to walk through.
    track(db, {
      event: "onboarding_begin",
      userId: claims.sub,
      orgId: w.orgId,
      properties: { path: "auto" },
    });
    track(db, {
      event: "onboarding_complete",
      userId: claims.sub,
      orgId: w.orgId,
      properties: { path: "auto" },
    });
    milestone(db, claims.sub, "first_bot_created", w.orgId);
    return c.json(
      { org_id: w.orgId, bot_id: w.botId, conversation_id: w.conversationId, created: true },
      200,
    );
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
          ...(body.provider === "openai_compatible" && body.embedding_model
            ? { settings: { embedding_model: body.embedding_model } }
            : {}),
        })
        .returning();
      return row;
    });
    if (!cred) throw new Error("credential insert returned nothing");
    await audit(cred.orgId, claims.sub, "credential.created", "model_credential", cred.id, {
      provider: cred.provider,
    });
    track(db, {
      event: "model_key_added",
      userId: claims.sub,
      orgId: cred.orgId,
      properties: { provider: cred.provider },
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
    // Keys for services Casama no longer uses (fal, Deepgram, ElevenLabs, Cartesia, Fish Audio;
    // D-260) stay stored but aren't listed.
    const offered = new Set<string>(ProviderId.options);
    const items: Array<ReturnType<typeof credOut> | ReturnType<typeof cloudCredential>> = rows
      .filter((r) => offered.has(r.provider))
      .map(credOut);
    // Own keys stay first. Casama's key is last so a new bot prefers a key the workspace added.
    if (deps.env.CLOUD_MODEL_UPSTREAM_KEY) items.push(cloudCredential(org_id));
    return c.json({ items }, 200);
  });

  app.openapi(routes.testCredential, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    rejectCloudKey(id);
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
    rejectCloudKey(id);
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
      ...(body.embedding_model !== undefined && cred.provider === "openai_compatible"
        ? { embedding_model: body.embedding_model || null }
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
    rejectCloudKey(id);
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
    if (id === PLATFORM_OPENROUTER_CREDENTIAL_ID) {
      if (!deps.env.CLOUD_MODEL_UPSTREAM_KEY)
        throw new ApiError(404, "credential_not_found", "Credential not found");
      const [member] = await withUserSession(db, claims, (tx) =>
        tx.execute<{ ok: boolean }>(
          sql`select true as ok from public.memberships where user_id = ${claims.sub}::uuid limit 1`,
        ),
      );
      if (!member?.ok) throw new ApiError(404, "credential_not_found", "Credential not found");
      const featured = FEATURED_MODELS.openrouter ?? [];
      // The shared key runs one model, on Casama Cloud and on self-hosted servers that set it.
      const locked = deps.env.BILLING_ENABLED
        ? (await getCloudModels(db)).chat
        : (defaultModelFor("openrouter", modelOverrides(deps.env)) ?? CLOUD_LOCKED_MODEL);
      const known = featured.find((m) => m.id === locked);
      const items = [{ id: locked, name: known?.name ?? locked, featured: true }];
      return c.json({ items, source: "featured" as const }, 200);
    }
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

  // Memory goes through the workspace's store (D-137): built in, Honcho or Supermemory.
  const memFetch = () => deps.apps?.fetch ?? fetch;
  const storeOf = async (orgId: string) => memoryStoreFor(db, orgId, null, memFetch());
  const memoryBot = async (claims: JwtClaims, botId: string, manage = false) => {
    const [b] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ org_id: string; manage: boolean }>(
        sql`select org_id, public.can_manage_bot(id) as manage from public.bots where id = ${botId}::uuid`,
      ),
    );
    if (!b) throw new ApiError(404, "bot_not_found", "Bot not found");
    if (manage && !b.manage) throw new ApiError(404, "memory_not_found", "Memory not found");
    return b;
  };
  const memoryOut = (m: StoredMemory) => ({
    id: m.id,
    kind: m.kind,
    content: m.content,
    importance: Number(m.importance),
    pinned: m.pinned,
    created_at: iso(m.created_at),
    updated_at: iso(m.updated_at),
  });

  // Encryption at rest (D-136): the thread with content opened, for apps whose rows are sealed.
  app.openapi(routes.getConversationThread, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    // Paging (Fix 10): a page of what people read, instead of the whole branch.
    const { limit, before, around } = c.req.valid("query");
    const rows = await withUserSession(db, claims, async (tx) => {
      const [conv] = await tx.execute<{ id: string }>(
        sql`select id from public.conversations where id = ${id}::uuid`,
      );
      if (!conv) throw new ApiError(404, "conversation_not_found", "Conversation not found");
      return tx.execute<Record<string, unknown>>(
        sql`select * from public.conversation_thread(${id}::uuid, ${limit ?? null}::int, ${
          limit === undefined ? null : (before ?? null)
        }::uuid, ${limit === undefined ? null : (around ?? null)}::uuid)`,
      );
    });
    return c.json(
      {
        items: rows.map((r) => ({
          ...r,
          created_at: r.created_at ? iso(r.created_at as string) : null,
        })),
      },
      200,
    );
  });

  app.openapi(routes.updateMemory, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id, memoryId } = c.req.valid("param");
    const b = c.req.valid("json");
    const bot = await memoryBot(claims, id, true);
    const row = await (await storeOf(bot.org_id)).update(id, memoryId, b);
    if (!row) throw new ApiError(404, "memory_not_found", "Memory not found");
    return c.json(memoryOut(row), 200);
  });

  app.openapi(routes.deleteMemory, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id, memoryId } = c.req.valid("param");
    const bot = await memoryBot(claims, id, true);
    await (await storeOf(bot.org_id)).delete(id, memoryId);
    return c.json({ deleted: memoryId }, 200);
  });

  // Memory backends (D-137) -----------------------------------------------------
  const backendOut = async (orgId: string) => {
    const [b] = await db.execute<{
      provider: "honcho";
      base_url: string | null;
      workspace: string | null;
      updated_at: string;
    }>(sql`
      select provider, base_url, workspace, updated_at from public.org_memory_backends where org_id = ${orgId}::uuid`);
    return b
      ? {
          provider: b.provider,
          base_url: b.base_url,
          workspace: b.workspace,
          updated_at: iso(b.updated_at),
        }
      : { provider: "postgres" as const, base_url: null, workspace: null, updated_at: null };
  };
  const orgRole = async (claims: JwtClaims, orgId: string) => {
    const [r] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ member: boolean; admin: boolean }>(sql`
        select public.has_role(${orgId}::uuid, 'member') as member, public.has_role(${orgId}::uuid, 'admin') as admin`),
    );
    if (!r?.member) throw new ApiError(404, "org_not_found", "Workspace not found");
    return r;
  };

  app.openapi(routes.getMemoryBackend, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    await orgRole(claims, id);
    return c.json(await backendOut(id), 200);
  });

  app.openapi(routes.setMemoryBackend, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const b = c.req.valid("json");
    if (!(await orgRole(claims, id)).admin)
      throw new ApiError(403, "forbidden", "Only admins can change where memory is kept");
    const store = storeFromConfig(
      { provider: b.provider, key: b.api_key, base_url: b.base_url, workspace: b.workspace },
      id,
      memFetch(),
    );
    try {
      await store.list("00000000-0000-0000-0000-000000000000");
    } catch (e) {
      throw new ApiError(
        400,
        "memory_backend_failed",
        `Couldn't reach ${b.provider === "honcho" ? "Honcho" : "Supermemory"}: ${(e as Error).message}`,
      );
    }
    if (b.copy_existing) {
      // Copy the built-in memories first, so nothing is lost when the switch happens.
      const old = await storeOf(id);
      const bots = await db.execute<{ id: string }>(
        sql`select id from public.bots where org_id = ${id}::uuid`,
      );
      for (const bot of bots)
        for (const m of await old.list(bot.id))
          await store.write({
            orgId: id,
            botId: bot.id,
            kind: m.kind,
            content: m.content,
            importance: m.importance,
            pinned: m.pinned,
          });
    }
    await db.execute(sql`
      with old as (select vault_secret_id from public.org_memory_backends where org_id = ${id}::uuid)
      delete from vault.secrets where id in (select vault_secret_id from old)`);
    await db.execute(sql`
      insert into public.org_memory_backends (org_id, provider, vault_secret_id, base_url, workspace, created_by, updated_at)
      values (${id}::uuid, ${b.provider}, (select vault.create_secret(${b.api_key}, null, 'memory backend')), ${b.base_url ?? null}, ${b.workspace ?? null}, ${claims.sub}::uuid, now())
      on conflict (org_id) do update set provider = excluded.provider, vault_secret_id = excluded.vault_secret_id, base_url = excluded.base_url,
        workspace = excluded.workspace, created_by = excluded.created_by, updated_at = now()`);
    await db.execute(sql`insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id, metadata)
      values (${id}::uuid, 'user', ${claims.sub}::uuid, 'memory_backend.set', 'organization', ${id}::uuid, ${JSON.stringify({ provider: b.provider, copied: !!b.copy_existing })}::jsonb)`);
    return c.json(await backendOut(id), 200);
  });

  app.openapi(routes.deleteMemoryBackend, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    if (!(await orgRole(claims, id)).admin)
      throw new ApiError(403, "forbidden", "Only admins can change where memory is kept");
    await db.execute(sql`
      with gone as (delete from public.org_memory_backends where org_id = ${id}::uuid returning vault_secret_id)
      delete from vault.secrets where id in (select vault_secret_id from gone)`);
    return c.json(await backendOut(id), 200);
  });

  app.openapi(routes.listMemories, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const { q } = c.req.valid("query");
    const bot = await memoryBot(claims, id);
    const rows = await (await storeOf(bot.org_id)).list(id, q);
    return c.json({ items: rows.map(memoryOut) }, 200);
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
      const period_ = sql`u.org_id = ${org_id}::uuid and u.created_at >= ${since}`;
      // Waived charges (D-275) aren't usage the person pays for; they're reported on their own.
      const scope = sql`${period_} and coalesce(u.meta ->> 'waived', '') <> 'failed_run'`;
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
      // Per person, for admins only: what each member's work cost (D-275).
      const [adm] = await tx.execute<{ ok: boolean }>(
        sql`select public.has_role(${org_id}::uuid, 'admin') as ok`,
      );
      const people = adm?.ok
        ? await tx.execute<{
            user_id: string | null;
            name: string | null;
            cost: string;
            n: string;
          }>(sql`
            select r.created_by as user_id, p.display_name as name, sum(u.cost_usd) as cost,
                   count(distinct u.run_id) as n
            from public.usage_ledger u
            left join public.runs r on r.id = u.run_id
            left join public.profiles p on p.user_id = r.created_by
            where ${scope} group by r.created_by, p.display_name order by cost desc limit 200`)
        : null;
      const [w] = await tx.execute<{ usd: string | null }>(sql`
        select sum(u.cost_usd)::text as usd from public.usage_ledger u
        where ${period_} and u.meta ->> 'waived' = 'failed_run'`);
      return {
        since,
        bots_,
        days,
        models,
        kinds,
        runs: Number(r?.n ?? 0),
        people,
        waived: Number(w?.usd ?? 0),
      };
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
        ...(report.people
          ? {
              by_person: report.people.map((p) => ({
                user_id: p.user_id,
                name: p.name,
                cost_usd: Number(p.cost),
                runs: Number(p.n),
              })),
            }
          : {}),
        waived_usd: report.waived,
      },
      200,
    );
  });
}
