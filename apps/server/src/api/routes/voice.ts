/** Voice (Phase 6, D-065): dictation, read aloud, live-call sessions, tool forwarding, transcripts. */

import {
  answerGreeting,
  CALL_CONTEXT_TURNS,
  callDeclineSecret,
  callDeclineTokenValid,
  callGreeting,
  callNotAnswered,
  cancelRing,
  earlierInConversation,
  milestone,
  todayLine,
  track,
  voicePrices,
} from "@casama/agent";
import { routes } from "@casama/contracts";
import { contentKeys, type JwtClaims, schema, withUserSession } from "@casama/db";
import { callLimits, cloudCharge, isValidTimezone } from "@casama/domain";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { eq, sql } from "drizzle-orm";
import { billsCalls as billsCallsOn } from "../../billing/calls.ts";
import {
  callHeadroom,
  claimCallEnd,
  HOLD_MINUTES,
  higherUsage,
  postCallRecap,
  settleCall,
} from "../../billing/live-calls.ts";
import { createRelay, relayedUsage, relayUrl } from "../live-relay.ts";

/** Live calls on the server's key one workspace can have open at once. */
const MAX_OPEN_BILLABLE_CALLS = 3;

import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";

const { bots, conversations } = schema;
const MAX_AUDIO = 10 * 1024 * 1024;
// A voice tool waits at most this long before answering "still working" (the result then goes
// to the chat), so the caller isn't left in silence for long.
const TOOL_WAIT_MS = 12_000;
const TERMINAL_RUN = new Set(["completed", "failed", "cancelled"]);
/** run_id for a call tool that started no run (stop_task with nothing to stop, show_screen). */
const NO_RUN = "00000000-0000-0000-0000-000000000000";

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

  // Live-call billing (D-248, D-327) lives in billing/live-calls.ts: a hold when the call starts,
  // settled when the app hangs up or when the worker ends a call whose app went quiet.

  /** The caller's own live call, or 404. */
  const myLiveCall = async (claims: JwtClaims, id: string) => {
    const [call] = await db.execute<{
      id: string;
      org_id: string;
      bot_id: string;
      conversation_id: string;
      billable: boolean;
      provider: string;
      ended_at: string | null;
      started_at: string;
    }>(sql`
      select id, org_id, bot_id, conversation_id, billable, provider, ended_at::text, started_at::text
      from public.live_calls where id = ${id}::uuid and user_id = ${claims.sub}::uuid`);
    if (!call) throw new ApiError(404, "call_not_found", "Call not found");
    return call;
  };

  /** Saves turns as chat messages, each once by its id when it has one (D-327). */
  const saveTurns = async (
    conv: { orgId: string; id: string },
    userId: string,
    liveCallId: string | null,
    turns: Array<{ role: "user" | "assistant"; text: string; id?: string }>,
  ) => {
    let saved = 0;
    for (const t of turns) {
      await db.transaction(async (tx) => {
        if (liveCallId && t.id) {
          const [fresh] = await tx.execute(sql`
            insert into public.live_call_turns (live_call_id, turn_id) values (${liveCallId}::uuid, ${t.id})
            on conflict do nothing returning turn_id`);
          if (!fresh) return;
        }
        const [m] = await tx.execute<{ id: string }>(sql`
          insert into public.messages (org_id, conversation_id, role, author_user_id, content)
          values (${conv.orgId}::uuid, ${conv.id}::uuid, ${t.role}, ${t.role === "user" ? userId : null}::uuid,
                  ${contentKeys.sealJson(conv.orgId, [{ type: "text", text: t.text, voice: true }])}::jsonb)
          returning id`);
        if (liveCallId && t.id && m)
          await tx.execute(sql`
            update public.live_call_turns set message_id = ${m.id}::uuid
            where live_call_id = ${liveCallId}::uuid and turn_id = ${t.id}`);
        saved++;
      });
    }
    if (saved)
      await db.execute(
        sql`update public.conversations set last_message_at = now() where id = ${conv.id}::uuid`,
      );
    return saved;
  };

  /** The conversation's last turns, for the new call's instructions (D-327). */
  const callContext = async (orgId: string, conversationId: string, botName: string) => {
    const rows = await db.execute<{ role: "user" | "assistant"; content: unknown }>(sql`
      select role, content from public.messages
      where conversation_id = ${conversationId}::uuid and org_id = ${orgId}::uuid
        and role in ('user', 'assistant')
      order by created_at desc limit ${CALL_CONTEXT_TURNS}`);
    const turns = rows
      .reverse()
      .map((r) => {
        const parts = contentKeys.open(r.content);
        // A call's recap card isn't something either side said.
        if (Array.isArray(parts) && parts.some((p) => p?.type === "call"))
          return { role: r.role, text: "" };
        const text = Array.isArray(parts)
          ? parts
              .filter((p): p is { type: "text"; text: string } => p?.type === "text")
              .map((p) => p.text ?? "")
              .join("\n")
          : typeof parts === "string"
            ? parts
            : "";
        return { role: r.role, text };
      })
      .filter((t) => t.text.trim());
    return earlierInConversation(turns, botName);
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
    // Context carries over (D-327): the conversation's last turns, so a call picks up where the
    // chat, or the last call, left off. Only for a conversation that already existed.
    const earlier = conversation_id ? await callContext(bot.orgId, conv.id, bot.name) : "";
    // The date and time, as a chat is told them: without it "remind me tomorrow at nine" left the
    // model guessing the date for the reminder's run_at.
    const [zone] = await db.execute<{ timezone: string | null }>(
      sql`select timezone from public.profiles where user_id = ${claims.sub}::uuid`,
    );
    const today = todayLine(
      new Date(),
      zone?.timezone && isValidTimezone(zone.timezone) ? zone.timezone : "UTC",
    );
    // The server's record of the call (D-327): heartbeats keep it open, and a call whose app goes
    // quiet is ended and billed by the worker. A billable call is written with its hold under a
    // per-workspace lock *before* the provider's token is made, so parallel starts can't all pass
    // one credit check, and only a few can be open at once (billing audit 2026-11-17).
    const hold = HOLD_MINUTES * voicePrices().geminiLivePerMinute;
    const limits = callLimits();
    const live = await db.transaction(async (tx) => {
      if (billable) {
        await tx.execute(
          sql`select pg_advisory_xact_lock(hashtext('live_call_start:' || ${bot.orgId}))`,
        );
        const [open] = await tx.execute<{ n: number; unbilled: string }>(sql`
          select
            (select count(*)::int from public.live_calls
              where org_id = ${bot.orgId}::uuid and billable and ended_at is null
                and last_seen_at > now() - make_interval(secs => ${limits.abandoned_seconds})) as n,
            (select coalesce(sum(cost_usd), 0) from public.usage_ledger
              where org_id = ${bot.orgId}::uuid and billable and billed_at is null)::text as unbilled`);
        if ((open?.n ?? 0) >= MAX_OPEN_BILLABLE_CALLS)
          throw new ApiError(
            429,
            "too_many_calls",
            `A workspace can have ${MAX_OPEN_BILLABLE_CALLS} live calls at once. End one and try again.`,
          );
        const balance = (await deps.billing?.balance(bot.orgId)) ?? 0;
        const left = balance - Number(open?.unbilled ?? 0);
        if (left <= 0 || left < cloudCharge(hold))
          throw new ApiError(
            402,
            "out_of_credits",
            "Live calls are paid from your workspace's credits, and there are none left.",
          );
        // The other limits the relay stops a call at (D-426): no call starts already past one.
        const room = await callHeadroom(
          tx,
          {
            id: "00000000-0000-0000-0000-000000000000",
            orgId: bot.orgId,
            botId: bot.id,
            startedAt: new Date().toISOString(),
          },
          balance,
          null,
        );
        if (room.reason && room.reason !== "credits" && room.left <= 0)
          throw new ApiError(
            402,
            room.reason === "bot_budget"
              ? "daily_budget_exceeded"
              : room.reason === "quota"
                ? "quota_exceeded"
                : "cloud_daily_cap",
            room.reason === "bot_budget"
              ? "This bot used its daily budget, so it can't take a call until tomorrow (UTC)."
              : room.reason === "quota"
                ? "The workspace reached its monthly spending limit."
                : "This workspace used today's spending limit. It resets at midnight UTC.",
          );
      }
      const [row] = await tx.execute<{ id: string }>(sql`
        insert into public.live_calls (org_id, bot_id, conversation_id, user_id, phone_call_id, provider, billable)
        values (${bot.orgId}::uuid, ${bot.id}::uuid, ${conv.id}::uuid, ${claims.sub}::uuid,
                ${call_id ?? null}::uuid, 'gemini', ${billable})
        returning id`);
      if (!row) throw new Error("live call insert returned nothing");
      if (billable)
        // A hold costs Casama nothing yet: the settling row carries what the call cost (D-395).
        await tx.execute(sql`insert into public.usage_ledger (org_id, bot_id, kind, quantity, cost_usd, upstream_cost_usd, billable, meta)
          values (${bot.orgId}::uuid, ${bot.id}::uuid, 'voice_seconds', 0, ${cloudCharge(hold)}, 0, true,
                  ${JSON.stringify({ hold: true, conversation_id: conv.id, live_call_id: row.id, provider: "gemini", key: "server", provider_cost_usd: hold })}::jsonb)`);
      return row;
    });
    let s: Extract<Awaited<ReturnType<typeof deps.workflows.voiceSession>>, { ok: true }>;
    try {
      s = unwrap(
        await deps.workflows.voiceSession(
          bot.orgId,
          bot.id,
          [earlier, today, greeting].filter(Boolean).join("\n\n"),
        ),
      );
    } catch (e) {
      // No token, no call: drop this call's record and its unsettled hold.
      await db.execute(
        sql`delete from public.usage_ledger where org_id = ${bot.orgId}::uuid and billed_at is null and meta->>'live_call_id' = ${live.id}`,
      );
      await db.execute(sql`delete from public.live_calls where id = ${live.id}::uuid`);
      throw e;
    }
    if (s.provider !== "gemini")
      await db.execute(
        sql`update public.live_calls set provider = ${s.provider} where id = ${live.id}::uuid`,
      );
    // A call paid from credits goes through the server's relay, which counts what Gemini reports;
    // the app gets a relay secret, never the Gemini token (billing audit 2026-11-17).
    let connectUrl = s.connectUrl;
    let clientSecret = s.clientSecret;
    const relay = billable && s.provider === "gemini" ? relayUrl(deps, live.id) : null;
    if (relay) {
      clientSecret = await createRelay(db, { id: live.id, orgId: bot.orgId }, s);
      connectUrl = relay;
    }
    return c.json(
      {
        provider: s.provider,
        model: s.model,
        client_secret: clientSecret,
        expires_at: s.expiresAt,
        connect_url: connectUrl,
        setup: s.setup,
        conversation_id: conv.id,
        tools: s.tools,
        speak_first: true,
        live_call_id: live.id,
        // Call limits (D-426): the app hangs up on silence and beats at the server's pace; a call
        // the relay doesn't carry is ended at its longest length by the app (and the sweep).
        limits: {
          silence_seconds: limits.silence_seconds,
          heartbeat_seconds: limits.heartbeat_seconds,
          max_call_seconds: limits.max_call_minutes * 60,
          warning_seconds: limits.warning_seconds,
          app_ends_at_max: !relay,
        },
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
      // Jobs started on a call are the call's (D-327): stop_task stops them, the recap lists them.
      if (body.live_call_id)
        await db.execute(sql`
          update public.live_calls set task_run_ids = array_append(task_run_ids, ${runId}::uuid)
          where id = ${body.live_call_id}::uuid and user_id = ${claims.sub}::uuid
            and conversation_id = ${body.conversation_id}::uuid`);
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
    // stop_task (D-327): stops what start_task began on this call, and nothing else. Cancelling
    // goes through the person's own session, so it can't reach a run they couldn't stop in the app.
    if (body.name === "stop_task") {
      const live = body.live_call_id ? await myLiveCall(claims, body.live_call_id) : null;
      if (live && live.conversation_id !== body.conversation_id)
        throw new ApiError(404, "call_not_found", "Call not found");
      const tasks = live
        ? await db.execute<{ id: string; status: string }>(sql`
            select r.id, r.status from public.live_calls lc
            join public.runs r on r.id = any(lc.task_run_ids)
            where lc.id = ${live.id}::uuid
            order by r.created_at desc`)
        : [];
      const open = tasks.filter((t) => !TERMINAL_RUN.has(t.status));
      for (const t of open) {
        await withUserSession(db, claims, (tx) =>
          tx.execute(sql`select public.request_run_cancel(${t.id}::uuid)`),
        );
        await deps.workflows.signalRun(t.id);
      }
      return c.json(
        {
          status: "completed" as const,
          run_id: open[0]?.id ?? tasks[0]?.id ?? NO_RUN,
          output: open.length
            ? `Stopped ${open.length === 1 ? "the task" : `${open.length} tasks`} started on this call. Tell the user briefly.`
            : "Nothing started on this call is still running. Tell the user.",
          approval_id: null,
        },
        200,
      );
    }
    // show_screen is the app's to answer (D-327); an app that doesn't know it sends it here.
    if (body.name === "show_screen")
      return c.json(
        {
          status: "completed" as const,
          run_id: NO_RUN,
          output:
            "This app can't show the screen on a call. Tell the user they can watch it from the chat.",
          approval_id: null,
        },
        200,
      );
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

  app.openapi(routes.saveVoiceTurns, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { live_call_id, turns } = c.req.valid("json");
    const call = await myLiveCall(claims, live_call_id);
    // Turns may still arrive after the call ended (a retried post): they're saved all the same.
    const saved = await saveTurns(
      { orgId: call.org_id, id: call.conversation_id },
      claims.sub,
      call.id,
      turns,
    );
    return c.json({ saved }, 200);
  });

  app.openapi(routes.voiceHeartbeat, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const { usage } = c.req.valid("json");
    const [row] = await db.execute<{ ended: boolean }>(sql`
      update public.live_calls set
        last_seen_at = case when ended_at is null then now() else last_seen_at end,
        usage = case when ended_at is null then coalesce(${usage ? JSON.stringify(usage) : null}::jsonb, usage) else usage end
      where id = ${id}::uuid and user_id = ${claims.sub}::uuid
      returning ended_at is not null as ended`);
    if (!row) throw new ApiError(404, "call_not_found", "Call not found");
    return c.json({ ended: row.ended }, 200);
  });

  app.openapi(routes.saveVoiceTranscript, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { conversation_id, live_call_id, turns, seconds, provider, usage } = c.req.valid("json");
    const [conv] = await withUserSession(db, claims, (tx) =>
      tx.select().from(conversations).where(eq(conversations.id, conversation_id)),
    );
    if (!conv) throw new ApiError(404, "conversation_not_found", "Conversation not found");
    const live = live_call_id ? await myLiveCall(claims, live_call_id) : null;
    if (live && live.conversation_id !== conv.id)
      throw new ApiError(404, "call_not_found", "Call not found");
    await saveTurns(conv, claims.sub, live?.id ?? null, turns);
    // A call with a server record ends once: if the worker already ended it (the app went quiet),
    // it was billed then, and this only saves the turns.
    if (live) {
      const claimed = await claimCallEnd(db, live.id, "hung_up", seconds);
      if (!claimed) return c.json({ saved: turns.length }, 200);
      // The recap card (D-327 §8): the call's length and what was started on it.
      await postCallRecap(db, claimed, seconds);
    }
    // Every call is Gemini Live (D-260). Gemini reports what the call used; price that rather than
    // estimating by the minute. Calls on the server's key on Casama Cloud come out of credits
    // (Google's price × markup), at least the call's length on the clock, less the hold (D-248).
    const billable = live ? live.billable : await billsCalls(conv.orgId);
    // A relayed call is charged what Gemini reported through the relay, or the app's counts when
    // those come to more.
    const relayed = live ? await relayedUsage(db, live.id) : null;
    await settleCall(db, {
      orgId: conv.orgId,
      botId: conv.botId,
      conversationId: conv.id,
      liveCallId: live?.id,
      billable,
      seconds,
      usage: higherUsage(relayed, usage),
      provider,
      ...(live
        ? { clockSeconds: Math.max(0, (Date.now() - Date.parse(live.started_at)) / 1000) }
        : {}),
    });
    if (seconds > 0) {
      track(db, {
        event: "call_ended",
        userId: claims.sub,
        orgId: conv.orgId,
        properties: {
          provider: provider ?? "gemini",
          duration_s: Math.round(seconds),
          billable,
          ended_by: "app",
        },
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
    // The person's other devices stop ringing (D-425).
    await cancelRing({ db, notifications: deps.notifications }, claims.sub, id);
    return c.json(callOut(await myCall(claims, id)), 200);
  });

  app.openapi(routes.declineVoiceCall, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    await myCall(claims, id);
    if (await callNotAnswered({ db }, id, "declined"))
      await cancelRing({ db, notifications: deps.notifications }, claims.sub, id);
    return c.json(callOut(await myCall(claims, id)), 200);
  });

  // Decline on Android's calling screen with the app closed (D-424): no sign-in there, so the
  // ring's own token (from the push) declines that one call. Not in the API contract: only the
  // app's background handler sends it.
  app.post("/v1/calls/:id/decline-ring", async (c) => {
    const secret = deps.env.SUPABASE_JWT_SECRET;
    const id = c.req.param("id");
    const body = (await c.req.json().catch(() => null)) as { token?: unknown } | null;
    const token = typeof body?.token === "string" ? body.token : "";
    if (
      !secret ||
      !/^[0-9a-f-]{36}$/i.test(id) ||
      !callDeclineTokenValid(callDeclineSecret(secret), id, token)
    )
      return c.json({ error: "invalid_token" }, 403);
    const declined = await callNotAnswered({ db }, id, "declined");
    if (declined) {
      const [u] = await db.execute<{ user_id: string }>(
        sql`select user_id from public.voice_calls where id = ${id}::uuid`,
      );
      if (u) await cancelRing({ db, notifications: deps.notifications }, u.user_id, id);
    }
    return c.json({ declined }, 200);
  });
}
