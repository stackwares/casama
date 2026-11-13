/** Voice (Phase 6, D-065): dictation, read aloud, live-call sessions, tool forwarding, transcripts. */

import {
  answerGreeting,
  callGreeting,
  callNotAnswered,
  geminiLiveCost,
  milestone,
  track,
  VOICE_PRICES,
} from "@casama/agent";
import { routes } from "@casama/contracts";
import { contentKeys, type JwtClaims, schema, withUserSession } from "@casama/db";
import { cloudCharge } from "@casama/domain";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { eq, sql } from "drizzle-orm";
import { billsCalls as billsCallsOn } from "../../billing/calls.ts";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";

const { bots, conversations } = schema;
const MAX_AUDIO = 10 * 1024 * 1024;
// A voice tool waits at most this long before answering "still working" (the result then goes
// to the chat), so the caller isn't left in silence for long.
const TOOL_WAIT_MS = 12_000;

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
  const unwrap = <T>(r: ({ ok: true } & T) | { ok: false; error: string; code?: string }): T => {
    if (!r.ok) throw new ApiError(409, r.code ?? "voice_unavailable", r.error);
    return r;
  };
  const billsCalls = (orgId: string) => billsCallsOn(deps, orgId);

  /**
   * Live calls are billed on what the server can see, not only what the app reports (D-248): a
   * billable call starts with a hold of HOLD_MINUTES at the per-minute estimate, and the saved call
   * is charged at least its length on the clock at Gemini's listening-only rate. A call that never
   * reports keeps its hold.
   */
  const HOLD_MINUTES = 2;
  const LISTEN_FLOOR_PER_MINUTE = 0.0045; // Gemini Live audio in: $3 per 1M tokens, 25 tokens a second
  const TOKEN_LIFE_SECONDS = 30 * 60;

  /** Credits left once usage not yet settled is counted. */
  const creditsLeft = async (orgId: string) => {
    const [r] = await db.execute<{ unbilled: string }>(sql`
      select coalesce(sum(cost_usd), 0)::text as unbilled from public.usage_ledger
      where org_id = ${orgId}::uuid and billable and billed_at is null`);
    return ((await deps.billing?.balance(orgId)) ?? 0) - Number(r?.unbilled ?? 0);
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
    const { bot_id, call_id } = c.req.valid("json");
    let { conversation_id } = c.req.valid("json");
    const bot = await visibleBot(claims, bot_id);
    // An answered phone call (D-135): its conversation, and the bot opens with why it called.
    let greeting: string | undefined;
    if (call_id) {
      const [call] = await db.execute<{
        reason: string;
        conversation_id: string | null;
        bot_id: string;
      }>(sql`
        select reason, conversation_id, bot_id from public.voice_calls
        where id = ${call_id}::uuid and user_id = ${claims.sub}::uuid and status = 'answered'`);
      if (!call || call.bot_id !== bot.id)
        throw new ApiError(404, "call_not_found", "Call not found");
      greeting = callGreeting(call.reason);
      conversation_id = call.conversation_id ?? conversation_id;
    }
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
                personal: true,
              })
              .returning(),
          )
        )[0];
    if (!conv) throw new Error("conversation insert returned nothing");
    // A call the person started (D-234): the bot picks up and says hi first, like answering a phone.
    if (!greeting) {
      const [p] = await db.execute<{ name: string | null }>(sql`
        select coalesce(nullif(btrim(preferred_name), ''), nullif(split_part(btrim(display_name), ' ', 1), '')) as name
        from public.profiles where user_id = ${claims.sub}::uuid`);
      greeting = answerGreeting(p?.name);
    }
    // Calls included on Casama Cloud are paid from credits: none left, no call.
    const billable = !!deps.billing && (await billsCalls(bot.orgId));
    if (billable && (await creditsLeft(bot.orgId)) <= 0)
      throw new ApiError(
        402,
        "out_of_credits",
        "Live calls are paid from your workspace's credits, and there are none left.",
      );
    const s = unwrap(await deps.workflows.voiceSession(bot.orgId, bot.id, greeting));
    if (billable) {
      const hold = HOLD_MINUTES * VOICE_PRICES.geminiLivePerMinute;
      await db.execute(sql`insert into public.usage_ledger (org_id, bot_id, kind, quantity, cost_usd, billable, meta)
        values (${bot.orgId}::uuid, ${bot.id}::uuid, 'voice_seconds', 0, ${cloudCharge(hold)}, true,
                ${JSON.stringify({ hold: true, conversation_id: conv.id, provider: s.provider, key: "server", provider_cost_usd: hold })}::jsonb)`);
    }
    return c.json(
      {
        provider: s.provider,
        model: s.model,
        client_secret: s.clientSecret,
        expires_at: s.expiresAt,
        connect_url: s.connectUrl,
        setup: s.setup,
        conversation_id: conv.id,
        tools: s.tools,
        speak_first: true,
      },
      200,
    );
  });

  app.openapi(routes.voiceTool, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const body = c.req.valid("json");
    const bot = await visibleBot(claims, body.bot_id);
    await visibleConversation(claims, body.conversation_id, bot.id);
    // start_task: a bigger job becomes an ordinary chat run in the call's conversation, with the
    // bot's full tools; the call doesn't wait for it.
    if (body.name === "start_task") {
      const task = String(body.arguments?.task ?? "").trim();
      if (!task) throw new ApiError(400, "task_required", "Describe the task to start.");
      const runId = await withUserSession(db, claims, async (tx) => {
        const [r] = await tx.execute<{ id: string }>(sql`
          insert into public.runs (org_id, bot_id, conversation_id, created_by, trigger)
          values (${bot.orgId}::uuid, ${bot.id}::uuid, ${body.conversation_id}::uuid, ${claims.sub}::uuid, 'chat')
          returning id`);
        const id = (r as { id: string }).id;
        await tx.execute(sql`
          insert into public.messages (org_id, conversation_id, role, author_user_id, content, run_id)
          values (${bot.orgId}::uuid, ${body.conversation_id}::uuid, 'user', ${claims.sub}::uuid,
                  ${contentKeys.sealJson(bot.orgId, [{ type: "text", text: task, voice: true }])}::jsonb, ${id}::uuid)`);
        await tx.execute(
          sql`update public.conversations set last_message_at = now() where id = ${body.conversation_id}::uuid`,
        );
        return id;
      });
      await deps.workflows.startRun(runId);
      return c.json(
        {
          status: "completed" as const,
          run_id: runId,
          output:
            "Started in the background. The result will appear in this chat; tell the user, and carry on the conversation.",
          approval_id: null,
        },
        200,
      );
    }
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
              "This action needs the user's approval in the Casama app. Tell them, and continue when they approve.",
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
    const { conversation_id, turns, seconds, provider, usage } = c.req.valid("json");
    // Every call is Gemini Live (D-260). Gemini reports what the call used; price that rather than
    // estimating by the minute.
    const cost = usage ? geminiLiveCost(usage) : (seconds / 60) * VOICE_PRICES.geminiLivePerMinute;
    const [conv] = await withUserSession(db, claims, (tx) =>
      tx.select().from(conversations).where(eq(conversations.id, conversation_id)),
    );
    if (!conv) throw new ApiError(404, "conversation_not_found", "Conversation not found");
    for (const t of turns) {
      await db.execute(sql`
        insert into public.messages (org_id, conversation_id, role, author_user_id, content)
        values (${conv.orgId}::uuid, ${conv.id}::uuid, ${t.role}, ${t.role === "user" ? claims.sub : null}::uuid,
                ${contentKeys.sealJson(conv.orgId, [{ type: "text", text: t.text, voice: true }])}::jsonb)`);
    }
    await db.execute(
      sql`update public.conversations set last_message_at = now() where id = ${conv.id}::uuid`,
    );
    // Calls on the server's key on Casama Cloud come out of credits (Google's price × markup),
    // at least the call's length on the clock, less the hold taken when it started (D-248).
    const billable = await billsCalls(conv.orgId);
    const [hold] = billable
      ? await db.execute<{ id: string; cost_usd: string; elapsed: string }>(sql`
          select id, cost_usd::text, extract(epoch from now() - created_at)::text as elapsed
          from public.usage_ledger
          where org_id = ${conv.orgId}::uuid and kind = 'voice_seconds' and (meta->>'hold')::boolean
            and meta->>'conversation_id' = ${conv.id} and not coalesce((meta->>'settled')::boolean, false)
          order by created_at desc limit 1`)
      : [];
    const clock = hold ? Math.min(Number(hold.elapsed), TOKEN_LIFE_SECONDS) : 0;
    const providerCost = billable ? Math.max(cost, (clock / 60) * LISTEN_FLOOR_PER_MINUTE) : cost;
    // Replaces the hold with the call's real price: negative when the call cost less than the
    // hold, so a short call isn't charged the hold.
    const charge = billable ? cloudCharge(providerCost) - Number(hold?.cost_usd ?? 0) : cost;
    if (hold)
      await db.execute(
        sql`update public.usage_ledger set meta = meta || '{"settled": true}'::jsonb where id = ${hold.id}::uuid`,
      );
    if (seconds > 0 || charge !== 0)
      await db.execute(sql`insert into public.usage_ledger (org_id, bot_id, kind, quantity, cost_usd, billable, meta)
        values (${conv.orgId}::uuid, ${conv.botId}::uuid, 'voice_seconds', ${seconds}, ${charge}, ${billable},
                ${JSON.stringify({ provider: provider ?? "gemini", ...(usage ? { tokens: usage } : { estimated: true }), ...(billable ? { key: "server", provider_cost_usd: providerCost, clock_seconds: Math.round(clock) } : {}) })}::jsonb)`);
    if (seconds > 0) {
      track(db, {
        event: "call_ended",
        userId: claims.sub,
        orgId: conv.orgId,
        properties: { provider: provider ?? "gemini", duration_s: Math.round(seconds), billable },
      });
      milestone(db, claims.sub, "first_voice_call", conv.orgId);
    }
    return c.json({ saved: turns.length }, 200);
  });

  // Phone calls (D-135) -------------------------------------------------------
  type CallRow = {
    id: string;
    bot_id: string;
    bot_name: string;
    reason: string;
    status: "ringing";
    conversation_id: string | null;
    expires_at: string;
    created_at: string;
  };
  const callOut = (r: CallRow) => ({
    ...r,
    expires_at: new Date(r.expires_at).toISOString(),
    created_at: new Date(r.created_at).toISOString(),
  });
  const myCall = async (claims: JwtClaims, id: string) => {
    const [r] = await db.execute<CallRow>(sql`
      select vc.id, vc.bot_id, b.name as bot_name, vc.reason, vc.status, vc.conversation_id, vc.expires_at, vc.created_at
      from public.voice_calls vc join public.bots b on b.id = vc.bot_id where vc.id = ${id}::uuid and vc.user_id = ${claims.sub}::uuid`);
    if (!r) throw new ApiError(404, "call_not_found", "Call not found");
    return r;
  };

  app.openapi(routes.listRingingCalls, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const rows = await db.execute<CallRow>(sql`
      select vc.id, vc.bot_id, b.name as bot_name, vc.reason, vc.status, vc.conversation_id, vc.expires_at, vc.created_at
      from public.voice_calls vc join public.bots b on b.id = vc.bot_id
      where vc.user_id = ${claims.sub}::uuid and vc.status = 'ringing' and vc.expires_at > now() order by vc.created_at desc`);
    return c.json({ items: rows.map(callOut) }, 200);
  });

  app.openapi(routes.getVoiceCall, async (c) => {
    const claims = requireClaims(c.get("claims"));
    return c.json(callOut(await myCall(claims, c.req.valid("param").id)), 200);
  });

  app.openapi(routes.answerVoiceCall, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    await myCall(claims, id);
    const [ok] = await db.execute<{ id: string }>(sql`
      update public.voice_calls set status = 'answered', answered_at = now()
      where id = ${id}::uuid and status = 'ringing' and expires_at > now() returning id`);
    if (!ok) throw new ApiError(409, "call_over", "This call has already ended");
    return c.json(callOut(await myCall(claims, id)), 200);
  });

  app.openapi(routes.declineVoiceCall, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    await myCall(claims, id);
    await callNotAnswered({ db }, id, "declined");
    return c.json(callOut(await myCall(claims, id)), 200);
  });
}
