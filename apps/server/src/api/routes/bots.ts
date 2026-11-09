import type { OpenAPIHono } from "@hono/zod-openapi";
import { routes } from "@kasama/contracts";
import { type JwtClaims, schema, withUserSession } from "@kasama/db";
import { templateById } from "@kasama/domain";
import { withSpan } from "@kasama/observability";
import { and, desc, eq, inArray, sql } from "drizzle-orm";
import { streamSSE } from "hono/streaming";
import { enforceLimit } from "../../billing/limits.ts";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { iso } from "../util.ts";
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
  created_at: iso(b.createdAt),
});

type ConvRow = typeof conversations.$inferSelect;
const convOut = (c: ConvRow) => ({
  id: c.id,
  bot_id: c.botId,
  title: c.title,
  last_message_at: c.lastMessageAt ? iso(c.lastMessageAt) : null,
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
  created_at: iso(r.createdAt),
});

type CredRow = typeof modelCredentials.$inferSelect;
const credOut = (c: CredRow) => ({
  id: c.id,
  org_id: c.orgId,
  provider: c.provider as "openai",
  label: c.label,
  base_url: c.baseUrl,
  key_hint: c.keyHint,
  last_tested_at: c.lastTestedAt ? iso(c.lastTestedAt) : null,
  last_test_ok: c.lastTestOk,
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
          personaMd:
            body.persona_md ??
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
    const { org_id } = c.req.valid("query");
    const rows = await withUserSession(db, claims, (tx) =>
      tx.select().from(bots).where(eq(bots.orgId, org_id)).orderBy(bots.createdAt),
    );
    return c.json({ items: rows.map(botOut) }, 200);
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
      const [row] = await tx
        .insert(conversations)
        .values({ orgId: bot.orgId, botId: body.bot_id, title: body.title, createdBy: claims.sub })
        .returning();
      return row;
    });
    if (!conv) throw new Error("conversation insert returned nothing");
    return c.json(convOut(conv), 201);
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
        .where(eq(conversations.botId, id))
        .orderBy(desc(sql`coalesce(${conversations.lastMessageAt}, ${conversations.createdAt})`))
        .limit(100);
    });
    return c.json({ items: rows.map(convOut) }, 200);
  });

  app.openapi(routes.sendMessage, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const { text } = c.req.valid("json");
    return withSpan("chat.send", { conversation_id: id }, async (span) => {
      const created = await withUserSession(db, claims, async (tx) => {
        const [conv] = await tx.select().from(conversations).where(eq(conversations.id, id));
        if (!conv) throw new ApiError(404, "conversation_not_found", "Conversation not found");
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
                  ${JSON.stringify([{ type: "text", text }])}::jsonb, ${run.id}::uuid)
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
    const [{ allowed } = { allowed: false }] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ allowed: boolean }>(
        sql`select public.has_role(${cred.orgId}::uuid, 'admin') as allowed`,
      ),
    );
    if (!allowed)
      throw new ApiError(403, "forbidden", "Only owners and admins can test model keys");
    return c.json(await deps.workflows.testCredential(id, cred.orgId, model), 200);
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
    const rows = await withUserSession(db, claims, async (tx) => {
      const [m] = await tx.execute<{ ok: boolean }>(
        sql`select public.is_member(${org_id}::uuid) as ok`,
      );
      if (!m?.ok) throw new ApiError(404, "org_not_found", "Organization not found");
      return tx.execute<{
        bot_id: string | null;
        name: string | null;
        cost: string;
        tin: string;
        tout: string;
        since: Date;
      }>(sql`
        with since as (select date_trunc(${period}, now() at time zone 'utc') at time zone 'utc' as t)
        select u.bot_id, b.name, sum(u.cost_usd) as cost,
               sum(case when u.kind = 'tokens_in' then u.quantity else 0 end) as tin,
               sum(case when u.kind = 'tokens_out' then u.quantity else 0 end) as tout,
               (select t from since) as since
        from public.usage_ledger u left join public.bots b on b.id = u.bot_id
        where u.org_id = ${org_id}::uuid and u.created_at >= (select t from since)
        group by u.bot_id, b.name order by cost desc`);
    });
    const [sinceRow] = await db.execute<{ t: Date }>(
      sql`select date_trunc(${period}, now() at time zone 'utc') at time zone 'utc' as t`,
    );
    const by_bot = rows.map((r) => ({
      bot_id: r.bot_id,
      name: r.name,
      cost_usd: Number(r.cost),
      tokens_in: Number(r.tin),
      tokens_out: Number(r.tout),
    }));
    return c.json(
      {
        period,
        since: iso(sinceRow?.t ?? new Date()),
        total_cost_usd: by_bot.reduce((n, b) => n + b.cost_usd, 0),
        by_bot,
      },
      200,
    );
  });
}
