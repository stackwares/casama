/** Voice (Phase 6, D-065): dictation, read aloud, live-call sessions, tool forwarding, transcripts. */
import type { OpenAPIHono } from "@hono/zod-openapi";
import { VOICE_PRICES } from "@kasama/agent";
import { routes } from "@kasama/contracts";
import { type JwtClaims, schema, withUserSession } from "@kasama/db";
import { eq, sql } from "drizzle-orm";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";

const { bots, conversations } = schema;
const MAX_AUDIO = 10 * 1024 * 1024;
const TOOL_WAIT_MS = 25_000;

function requireClaims(claims: JwtClaims | undefined): JwtClaims {
  if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
  return claims;
}

export function registerVoiceRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;
  const visibleBot = async (claims: JwtClaims, botId: string) => {
    const [b] = await withUserSession(db, claims, (tx) =>
      tx.select().from(bots).where(eq(bots.id, botId)),
    );
    if (!b) throw new ApiError(404, "bot_not_found", "Bot not found");
    return b;
  };
  const visibleConversation = async (claims: JwtClaims, id: string, botId: string) => {
    const [conv] = await withUserSession(db, claims, (tx) =>
      tx.select().from(conversations).where(eq(conversations.id, id)),
    );
    if (!conv || conv.botId !== botId)
      throw new ApiError(404, "conversation_not_found", "Conversation not found");
    return conv;
  };
  const unwrap = <T>(r: ({ ok: true } & T) | { ok: false; error: string }): T => {
    if (!r.ok) throw new ApiError(409, "voice_unavailable", r.error);
    return r;
  };

  app.openapi(routes.transcribeAudio, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { bot_id, language } = c.req.valid("query");
    const bot = await visibleBot(claims, bot_id);
    const mime = c.req.header("content-type") ?? "";
    if (!/^audio\/|^video\/webm|^application\/octet-stream/.test(mime))
      throw new ApiError(
        400,
        "bad_audio",
        "Send the recording as the raw body with an audio/* content type",
      );
    const audio = new Uint8Array(await c.req.arrayBuffer());
    if (audio.length === 0 || audio.length > MAX_AUDIO)
      throw new ApiError(400, "bad_audio", "Recordings must be between 1 byte and 10 MB");
    const r = unwrap(
      await deps.workflows.voiceTranscribe(
        bot.orgId,
        bot.id,
        Buffer.from(audio).toString("base64"),
        mime,
        language,
      ),
    );
    return c.json({ text: r.text, provider: r.provider, seconds: r.seconds }, 200);
  });

  app.openapi(routes.messageSpeech, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const [m] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ org_id: string; role: string }>(
        sql`select org_id, role from public.messages where id = ${id}::uuid`,
      ),
    );
    if (!m) throw new ApiError(404, "message_not_found", "Message not found");
    if (m.role !== "assistant")
      throw new ApiError(409, "not_speakable", "Only bot messages can be read aloud");
    const r = unwrap(await deps.workflows.voiceSpeak(m.org_id, id));
    const [row] = await db.execute<{ mime: string; audio: Buffer }>(sql`
      select mime, audio from public.tts_cache where message_id = ${id}::uuid and voice_key = ${r.voiceKey}`);
    if (!row) throw new ApiError(409, "voice_unavailable", "Audio is not ready");
    return c.body(new Uint8Array(row.audio), 200, {
      "content-type": row.mime,
      "cache-control": "private, max-age=86400",
    }) as never;
  });

  app.openapi(routes.createVoiceSession, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { bot_id, conversation_id } = c.req.valid("json");
    const bot = await visibleBot(claims, bot_id);
    const conv = conversation_id
      ? await visibleConversation(claims, conversation_id, bot.id)
      : (
          await withUserSession(db, claims, (tx) =>
            tx
              .insert(conversations)
              .values({
                orgId: bot.orgId,
                botId: bot.id,
                title: "Voice call",
                createdBy: claims.sub,
              })
              .returning(),
          )
        )[0];
    if (!conv) throw new Error("conversation insert returned nothing");
    const s = unwrap(await deps.workflows.voiceSession(bot.orgId, bot.id));
    return c.json(
      {
        provider: "openai" as const,
        model: s.model,
        client_secret: s.clientSecret,
        expires_at: s.expiresAt,
        connect_url: s.connectUrl,
        conversation_id: conv.id,
        tools: s.tools,
      },
      200,
    );
  });

  app.openapi(routes.voiceTool, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const body = c.req.valid("json");
    const bot = await visibleBot(claims, body.bot_id);
    await visibleConversation(claims, body.conversation_id, bot.id);
    const [run] = await db.execute<{ id: string }>(sql`
      insert into public.runs (org_id, bot_id, conversation_id, created_by, trigger, voice_call)
      values (${bot.orgId}::uuid, ${bot.id}::uuid, ${body.conversation_id}::uuid, ${claims.sub}::uuid, 'voice',
              ${JSON.stringify({ call_id: body.call_id, name: body.name, arguments: body.arguments ?? {} })}::jsonb)
      returning id`);
    const runId = (run as { id: string }).id;
    await deps.workflows.startRun(runId);
    const until = Date.now() + TOOL_WAIT_MS;
    for (;;) {
      const [r] = await db.execute<{
        status: string;
        voice_call: { result?: string };
        error: { message?: string } | null;
      }>(sql`select status, voice_call, error from public.runs where id = ${runId}::uuid`);
      const status = r?.status ?? "queued";
      if (status === "completed")
        return c.json(
          {
            status: "completed" as const,
            run_id: runId,
            output: r?.voice_call.result ?? "",
            approval_id: null,
          },
          200,
        );
      if (status === "failed" || status === "cancelled")
        return c.json(
          {
            status: "failed" as const,
            run_id: runId,
            output: `The tool failed: ${r?.error?.message ?? status}`,
            approval_id: null,
          },
          200,
        );
      if (status === "waiting_approval") {
        const [a] = await db.execute<{ id: string }>(
          sql`select id from public.approvals where run_id = ${runId}::uuid and status = 'pending' limit 1`,
        );
        return c.json(
          {
            status: "waiting_approval" as const,
            run_id: runId,
            output:
              "This action needs the user's approval in the Kasama app. Tell them, and continue when they approve.",
            approval_id: a?.id ?? null,
          },
          200,
        );
      }
      if (Date.now() > until)
        return c.json(
          {
            status: "running" as const,
            run_id: runId,
            output: "Still working on it; the result will appear in the chat.",
            approval_id: null,
          },
          200,
        );
      await new Promise((r) => setTimeout(r, 100));
    }
  });

  app.openapi(routes.saveVoiceTranscript, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { conversation_id, turns, seconds } = c.req.valid("json");
    const [conv] = await withUserSession(db, claims, (tx) =>
      tx.select().from(conversations).where(eq(conversations.id, conversation_id)),
    );
    if (!conv) throw new ApiError(404, "conversation_not_found", "Conversation not found");
    for (const t of turns) {
      await db.execute(sql`
        insert into public.messages (org_id, conversation_id, role, author_user_id, content)
        values (${conv.orgId}::uuid, ${conv.id}::uuid, ${t.role}, ${t.role === "user" ? claims.sub : null}::uuid,
                ${JSON.stringify([{ type: "text", text: t.text, voice: true }])}::jsonb)`);
    }
    await db.execute(
      sql`update public.conversations set last_message_at = now() where id = ${conv.id}::uuid`,
    );
    if (seconds > 0)
      await db.execute(sql`insert into public.usage_ledger (org_id, bot_id, kind, quantity, cost_usd)
        values (${conv.orgId}::uuid, ${conv.botId}::uuid, 'voice_seconds', ${seconds}, ${(seconds / 60) * VOICE_PRICES.realtimePerMinute})`);
    return c.json({ saved: turns.length }, 200);
  });
}
