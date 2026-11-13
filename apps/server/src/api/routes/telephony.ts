/**
 * Calls for you (D-141), the API side:
 * - workspace telephony settings (the workspace's Twilio account; admins)
 * - a call's live transcript, ending it, or taking it over to the person's own phone
 * - Twilio's status webhook (signed)
 * - the media stream bridge: Twilio Media Streams (μ-law audio over WebSocket) to a realtime voice
 *   session minted by the worker, with the bot speaking first.
 */
import type { IncomingMessage, Server } from "node:http";
import type { Duplex } from "node:stream";
import {
  addGeminiUsage,
  base64ToPcm16,
  callInstructions,
  emptyGeminiUsage,
  geminiLiveCost,
  hashStreamToken,
  mulawToPcm16,
  pcm16ToBase64,
  pcm16ToMulaw,
  resamplePcm16,
  TwilioClient,
  twilioSignature,
} from "@casama/agent";
import { routes } from "@casama/contracts";
import { type JwtClaims, withUserSession } from "@casama/db";
import { cloudCharge } from "@casama/domain";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { sql } from "drizzle-orm";
import { WebSocket, WebSocketServer } from "ws";
import { billsCalls } from "../../billing/calls.ts";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { iso } from "../util.ts";

/** Calls bridged by this process, so "end" can hang up right away. */
const bridges = new Map<string, () => void>();

type Tel = {
  account_sid: string;
  from_number: string;
  token: string;
  allow_personal_numbers: boolean;
  daily_cap: number;
};
async function telephony(db: AppDeps["db"], orgId: string) {
  const [t] = await db.execute<Tel>(sql`
    select t.account_sid, t.from_number, v.decrypted_secret as token, t.allow_personal_numbers, t.daily_cap
    from public.org_telephony t join vault.decrypted_secrets v on v.id = t.vault_secret_id where t.org_id = ${orgId}::uuid`);
  return t ?? null;
}
const twilioOf = (deps: AppDeps, t: Tel) =>
  new TwilioClient({
    accountSid: t.account_sid,
    authToken: t.token,
    apiUrl: deps.env.TWILIO_API_URL,
    fetch: deps.apps?.fetch ?? fetch,
  });

const STATUS: Record<string, string> = {
  queued: "queued",
  initiated: "ringing",
  ringing: "ringing",
  "in-progress": "in_progress",
  completed: "completed",
  busy: "busy",
  failed: "failed",
  "no-answer": "no_answer",
  canceled: "failed",
};

export function registerTelephonyRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;
  const claimsOf = (c: { get(k: "claims"): JwtClaims | undefined }) => {
    const claims = c.get("claims");
    if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
    return claims;
  };
  const admin = async (claims: JwtClaims, orgId: string) => {
    const [r] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ admin: boolean; member: boolean }>(
        sql`select public.has_role(${orgId}::uuid, 'admin') as admin, public.has_role(${orgId}::uuid, 'member') as member`,
      ),
    );
    if (!r?.member) throw new ApiError(404, "org_not_found", "Workspace not found");
    if (!r.admin) throw new ApiError(403, "forbidden", "Only admins can set up phone calls");
  };
  const settingsOut = async (orgId: string) => {
    const t = await telephony(db, orgId);
    return t
      ? {
          connected: true,
          account_sid: t.account_sid,
          from_number: t.from_number,
          allow_personal_numbers: t.allow_personal_numbers,
          daily_cap: t.daily_cap,
        }
      : {
          connected: false,
          account_sid: null,
          from_number: null,
          allow_personal_numbers: false,
          daily_cap: 10,
        };
  };

  app.openapi(routes.getTelephony, async (c) => {
    const { id } = c.req.valid("param");
    await admin(claimsOf(c), id);
    return c.json(await settingsOut(id), 200);
  });

  app.openapi(routes.setTelephony, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    const b = c.req.valid("json");
    await admin(claims, id);
    const cur = await telephony(db, id);
    const token = b.auth_token ?? cur?.token;
    if (!token) throw new ApiError(400, "validation_failed", "Paste the Twilio auth token");
    // Check the account answers before saving.
    const res = await (deps.apps?.fetch ?? fetch)(
      `${(deps.env.TWILIO_API_URL ?? "https://api.twilio.com").replace(/\/$/, "")}/2010-04-01/Accounts/${b.account_sid}.json`,
      {
        headers: {
          authorization: `Basic ${Buffer.from(`${b.account_sid}:${token}`).toString("base64")}`,
        },
      },
    ).catch(() => null);
    if (!res?.ok)
      throw new ApiError(
        400,
        "twilio_failed",
        "Twilio didn't accept that account SID and auth token",
      );
    await db.execute(sql`
      with old as (select vault_secret_id from public.org_telephony where org_id = ${id}::uuid)
      delete from vault.secrets where id in (select vault_secret_id from old) and ${b.auth_token ? 1 : 0} = 1`);
    await db.execute(sql`
      insert into public.org_telephony (org_id, account_sid, from_number, vault_secret_id, allow_personal_numbers, daily_cap, updated_at)
      values (${id}::uuid, ${b.account_sid}, ${b.from_number},
              ${b.auth_token ? sql`(select vault.create_secret(${b.auth_token}, null, 'twilio'))` : sql`(select vault_secret_id from public.org_telephony where org_id = ${id}::uuid)`},
              ${b.allow_personal_numbers ?? false}, ${b.daily_cap ?? 10}, now())
      on conflict (org_id) do update set account_sid = excluded.account_sid, from_number = excluded.from_number, vault_secret_id = excluded.vault_secret_id,
        allow_personal_numbers = excluded.allow_personal_numbers, daily_cap = excluded.daily_cap, updated_at = now()`);
    await db.execute(sql`insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id, metadata)
      values (${id}::uuid, 'user', ${claims.sub}::uuid, 'telephony.set', 'organization', ${id}::uuid, ${JSON.stringify({ from_number: b.from_number, allow_personal_numbers: b.allow_personal_numbers ?? false, daily_cap: b.daily_cap ?? 10 })}::jsonb)`);
    return c.json(await settingsOut(id), 200);
  });

  app.openapi(routes.deleteTelephony, async (c) => {
    const { id } = c.req.valid("param");
    await admin(claimsOf(c), id);
    await db.execute(sql`
      with gone as (delete from public.org_telephony where org_id = ${id}::uuid returning vault_secret_id)
      delete from vault.secrets where id in (select vault_secret_id from gone)`);
    return c.json(await settingsOut(id), 200);
  });

  // --- calls -------------------------------------------------------------------------
  type CallRow = {
    id: string;
    org_id: string;
    bot_id: string;
    number: string;
    purpose: string;
    status: string;
    provider_call_id: string | null;
    transcript: Array<{ role: "bot" | "callee"; text: string; at?: string }>;
    seconds: number | null;
    started_at: string | null;
    ended_at: string | null;
    created_at: string;
  };
  const callOut = (r: CallRow) => ({
    id: r.id,
    bot_id: r.bot_id,
    number: r.number,
    purpose: r.purpose,
    status: r.status as "queued",
    transcript: r.transcript.map((t) => ({ role: t.role, text: t.text })),
    seconds: r.seconds,
    started_at: r.started_at ? iso(r.started_at) : null,
    ended_at: r.ended_at ? iso(r.ended_at) : null,
    created_at: iso(r.created_at),
  });
  const myCall = async (claims: JwtClaims, id: string) => {
    const [r] = await withUserSession(db, claims, (tx) =>
      tx.execute<CallRow>(sql`
        select id, org_id, bot_id, number, purpose, status, provider_call_id, transcript, seconds, started_at, ended_at, created_at
        from public.outbound_calls where id = ${id}::uuid`),
    );
    if (!r) throw new ApiError(404, "call_not_found", "Call not found");
    return r;
  };
  const live = (s: string) => ["queued", "ringing", "in_progress"].includes(s);

  app.openapi(routes.getOutboundCall, async (c) =>
    c.json(callOut(await myCall(claimsOf(c), c.req.valid("param").id)), 200),
  );

  app.openapi(routes.endOutboundCall, async (c) => {
    const claims = claimsOf(c);
    const call = await myCall(claims, c.req.valid("param").id);
    if (live(call.status)) {
      await db.execute(
        sql`update public.outbound_calls set status = 'ended_by_user', ended_at = now() where id = ${call.id}::uuid`,
      );
      bridges.get(call.id)?.();
      const t = await telephony(db, call.org_id);
      if (t && call.provider_call_id)
        await twilioOf(deps, t)
          .updateCall(call.provider_call_id, { status: "completed" })
          .catch(() => {});
    }
    return c.json(callOut(await myCall(claims, call.id)), 200);
  });

  app.openapi(routes.takeOverOutboundCall, async (c) => {
    const claims = claimsOf(c);
    const call = await myCall(claims, c.req.valid("param").id);
    const { phone } = c.req.valid("json");
    if (!live(call.status) || !call.provider_call_id)
      throw new ApiError(409, "call_over", "This call has already ended");
    if (phone)
      await db.execute(
        sql`update public.profiles set phone_number = ${phone} where user_id = ${claims.sub}::uuid`,
      );
    const [p] = await db.execute<{ phone_number: string | null; display_name: string | null }>(sql`
      select phone_number, display_name from public.profiles where user_id = ${claims.sub}::uuid`);
    if (!p?.phone_number)
      throw new ApiError(400, "phone_required", "Add your phone number to take over calls");
    const t = await telephony(db, call.org_id);
    if (!t) throw new ApiError(409, "no_telephony", "Phone calls aren't set up");
    // Twilio leaves the media stream and connects the other side to the person's phone.
    await twilioOf(deps, t).updateCall(call.provider_call_id, {
      twiml: `<Response><Say>One moment, connecting you now.</Say><Dial callerId="${t.from_number}">${p.phone_number}</Dial></Response>`,
    });
    await db.execute(
      sql`update public.outbound_calls set status = 'taken_over' where id = ${call.id}::uuid`,
    );
    bridges.get(call.id)?.();
    return c.json(callOut(await myCall(claims, call.id)), 200);
  });

  // Twilio's status callbacks, signed with the account's auth token.
  app.post("/hooks/telephony/:id", async (c) => {
    const id = c.req.param("id");
    if (!/^[0-9a-f-]{36}$/.test(id)) return c.text("", 404);
    const [call] = await db.execute<{ org_id: string; status: string }>(
      sql`select org_id, status from public.outbound_calls where id = ${id}::uuid`,
    );
    const t = call ? await telephony(db, call.org_id) : null;
    if (!call || !t) return c.text("", 404);
    const params = Object.fromEntries(new URLSearchParams(await c.req.text())) as Record<
      string,
      string
    >;
    const u = new URL(c.req.url);
    const url = deps.env.PUBLIC_API_URL
      ? `${deps.env.PUBLIC_API_URL.replace(/\/$/, "")}${u.pathname}${u.search}`
      : c.req.url;
    if (c.req.header("x-twilio-signature") !== twilioSignature(url, params, t.token))
      return c.text("bad signature", 401);
    const status = STATUS[params.CallStatus ?? ""] ?? null;
    const seconds = params.CallDuration ? Number(params.CallDuration) : null;
    // A call the person ended or took over keeps that status; only its length is added.
    const keep = ["ended_by_user", "taken_over"].includes(call.status);
    await db.execute(sql`
      update public.outbound_calls set
        status = ${keep ? call.status : (status ?? call.status)},
        seconds = coalesce(${seconds}::int, seconds),
        started_at = case when ${status} = 'in_progress' then coalesce(started_at, now()) else started_at end,
        ended_at = case when ${status} in ('completed', 'busy', 'failed', 'no_answer') then coalesce(ended_at, now()) else ended_at end
      where id = ${id}::uuid`);
    if (seconds !== null && status === "completed") {
      const minutes = Math.ceil(seconds / 60);
      await db.execute(sql`
        insert into public.usage_ledger (org_id, bot_id, kind, quantity, cost_usd, billable, meta)
        select org_id, bot_id, 'phone_minutes', ${minutes}, ${minutes * 0.014}, false, ${JSON.stringify({ call_id: id, seconds })}::jsonb
        from public.outbound_calls where id = ${id}::uuid`);
    }
    return c.body(null, 204);
  });
}

/** Twilio Media Streams ⇄ realtime voice (D-141). */
export function attachTelephony(server: Server, deps: AppDeps) {
  const wss = new WebSocketServer({ noServer: true });
  server.on("upgrade", (req: IncomingMessage, socket: Duplex, head: Buffer) => {
    const id = new URL(req.url ?? "/", "http://api").pathname.match(
      /^\/telephony\/stream\/([0-9a-f-]{36})$/,
    )?.[1];
    if (!id) return;
    wss.handleUpgrade(req, socket, head, (twilio) => bridge(deps, id, twilio));
  });
}

async function appendLine(db: AppDeps["db"], id: string, role: "bot" | "callee", text: string) {
  if (!text.trim()) return;
  await db.execute(sql`
    update public.outbound_calls set transcript = transcript || ${JSON.stringify([{ role, text: text.trim(), at: new Date().toISOString() }])}::jsonb
    where id = ${id}::uuid`);
}

function bridge(deps: AppDeps, id: string, twilio: WebSocket) {
  const { db } = deps;
  let ai: WebSocket | null = null;
  let streamSid = "";
  let started = false;
  let gemini = false;
  const close = () => {
    bridges.delete(id);
    if (ai && ai.readyState <= WebSocket.OPEN) ai.close();
    if (twilio.readyState <= WebSocket.OPEN) twilio.close();
  };
  twilio.on("close", close);
  twilio.on("error", close);
  twilio.on("message", async (raw) => {
    let m: {
      event?: string;
      streamSid?: string;
      start?: { streamSid: string; callSid: string; customParameters?: Record<string, string> };
      media?: { payload: string };
    };
    try {
      m = JSON.parse(String(raw));
    } catch {
      return;
    }
    if (m.event === "start" && !started) {
      started = true;
      streamSid = m.start?.streamSid ?? m.streamSid ?? "";
      const [call] = await db.execute<{
        org_id: string;
        bot_id: string;
        user_id: string;
        number: string;
        purpose: string;
        notes: string | null;
        status: string;
        token: string;
      }>(sql`
        select c.org_id, c.bot_id, c.user_id, c.number, c.purpose, c.notes, c.status, c.stream_token_hash as token from public.outbound_calls c where c.id = ${id}::uuid`);
      // The stream proves itself with the call's one-time token (sent as a TwiML parameter).
      if (
        !call ||
        call.token !== hashStreamToken(m.start?.customParameters?.token ?? "") ||
        !["ringing", "in_progress", "queued"].includes(call.status)
      )
        return close();
      await db.execute(
        sql`update public.outbound_calls set status = 'in_progress', started_at = coalesce(started_at, now()), stream_token_hash = 'used' where id = ${id}::uuid`,
      );
      const [who] = await db.execute<{ name: string; bot: string }>(sql`
        select coalesce(p.display_name, split_part(u.email, '@', 1), 'the person') as name, b.name as bot
        from public.bots b, auth.users u left join public.profiles p on p.user_id = u.id where b.id = ${call.bot_id}::uuid and u.id = ${call.user_id}::uuid`);
      // A call on the server's voice key needs credits, like an in-app call.
      if (
        deps.billing &&
        (await billsCalls(deps, call.org_id)) &&
        (await deps.billing.balance(call.org_id)) <= 0
      ) {
        await db.execute(
          sql`update public.outbound_calls set status = 'failed', error = 'out_of_credits', ended_at = now() where id = ${id}::uuid`,
        );
        return close();
      }
      const s = await deps.workflows.voiceSession(
        call.org_id,
        call.bot_id,
        callInstructions({
          personName: who?.name ?? "the person",
          botName: who?.bot ?? "the assistant",
          purpose: call.purpose,
          notes: call.notes,
          number: call.number,
        }),
        true,
      );
      if (!s.ok) {
        await db.execute(
          sql`update public.outbound_calls set status = 'failed', error = ${s.error}, ended_at = now() where id = ${id}::uuid`,
        );
        return close();
      }
      if (s.provider === "gemini") {
        gemini = true;
        ai = geminiBridge(deps, id, s, twilio, () => streamSid, close);
        bridges.set(id, close);
        return;
      }
      const wsUrl = `${(deps.env.OPENAI_REALTIME_URL ?? "wss://api.openai.com/v1/realtime").replace(/\/$/, "")}?model=${encodeURIComponent(s.model)}`;
      ai = new WebSocket(wsUrl, { headers: { authorization: `Bearer ${s.clientSecret}` } });
      bridges.set(id, close);
      ai.on("open", () => ai?.send(JSON.stringify({ type: "response.create" })));
      ai.on("close", close);
      ai.on("error", close);
      ai.on("message", async (data) => {
        let e: { type?: string; delta?: string; transcript?: string; name?: string };
        try {
          e = JSON.parse(String(data));
        } catch {
          return;
        }
        switch (e.type) {
          case "response.output_audio.delta":
            if (e.delta && twilio.readyState === WebSocket.OPEN)
              twilio.send(
                JSON.stringify({ event: "media", streamSid, media: { payload: e.delta } }),
              );
            break;
          case "input_audio_buffer.speech_started":
            // Barge-in: the other person talks over the bot, so stop its audio.
            if (twilio.readyState === WebSocket.OPEN)
              twilio.send(JSON.stringify({ event: "clear", streamSid }));
            ai?.send(JSON.stringify({ type: "response.cancel" }));
            break;
          case "conversation.item.input_audio_transcription.completed":
            await appendLine(db, id, "callee", e.transcript ?? "");
            break;
          case "response.output_audio_transcript.done":
            await appendLine(db, id, "bot", e.transcript ?? "");
            break;
          case "response.function_call_arguments.done":
            // end_call: let the goodbye finish playing, then leave the stream (Twilio hangs up).
            if (e.name === "end_call") setTimeout(close, 2500);
            break;
        }
      });
    } else if (m.event === "media" && ai?.readyState === WebSocket.OPEN && m.media?.payload) {
      if (gemini) {
        // 8 kHz μ-law from the phone → 16 kHz PCM for Gemini.
        const pcm = resamplePcm16(
          mulawToPcm16(Buffer.from(m.media.payload, "base64")),
          8000,
          16000,
        );
        ai.send(
          JSON.stringify({
            realtimeInput: {
              audio: { data: pcm16ToBase64(pcm), mimeType: "audio/pcm;rate=16000" },
            },
          }),
        );
      } else ai.send(JSON.stringify({ type: "input_audio_buffer.append", audio: m.media.payload }));
    } else if (m.event === "stop") close();
  });
}

/**
 * The phone side of a call on Gemini Live: Twilio's 8 kHz μ-law becomes 16 kHz PCM for Gemini, and
 * Gemini's 24 kHz PCM becomes μ-law for the phone. Transcripts are saved a turn at a time.
 */
function geminiBridge(
  deps: AppDeps,
  id: string,
  s: { connectUrl: string; clientSecret: string; setup: Record<string, unknown> | null },
  twilio: WebSocket,
  streamSid: () => string,
  close: () => void,
) {
  const { db } = deps;
  const ai = new WebSocket(`${s.connectUrl}?access_token=${encodeURIComponent(s.clientSecret)}`);
  let bot = "";
  let callee = "";
  // What the call used, from Gemini's usageMetadata, recorded once when the stream ends.
  let usage = emptyGeminiUsage();
  let startedAt: number | null = null;
  let recorded = false;
  const recordUsage = async () => {
    if (recorded || startedAt === null) return;
    recorded = true;
    const seconds = Math.max(1, Math.round((Date.now() - startedAt) / 1000));
    // The voice model inside a phone call is paid from credits like an in-app call (D-244). The
    // phone line itself is the workspace's own Twilio account.
    const cost = geminiLiveCost(usage);
    const [call] = await db.execute<{ org_id: string }>(
      sql`select org_id from public.outbound_calls where id = ${id}::uuid`,
    );
    const billable = !!call && (await billsCalls(deps, call.org_id));
    await db.execute(sql`
      insert into public.usage_ledger (org_id, bot_id, kind, quantity, cost_usd, billable, meta)
      select org_id, bot_id, 'voice_seconds', ${seconds}, ${billable ? cloudCharge(cost) : cost}, ${billable},
             ${JSON.stringify({ provider: "gemini", phone_call: id, tokens: usage, ...(billable ? { key: "server", provider_cost_usd: cost } : {}) })}::jsonb
      from public.outbound_calls where id = ${id}::uuid`);
  };
  const flush = async () => {
    const [b, c] = [bot, callee];
    bot = "";
    callee = "";
    if (c) await appendLine(db, id, "callee", c);
    if (b) await appendLine(db, id, "bot", b);
  };
  const toPhone = (payload: string) => {
    if (twilio.readyState === WebSocket.OPEN)
      twilio.send(JSON.stringify({ event: "media", streamSid: streamSid(), media: { payload } }));
  };
  ai.on("open", () => ai.send(JSON.stringify({ setup: s.setup ?? {} })));
  ai.on("close", () => {
    void recordUsage();
    close();
  });
  ai.on("error", close);
  ai.on("message", async (data) => {
    let e: {
      setupComplete?: unknown;
      usageMetadata?: unknown;
      serverContent?: {
        modelTurn?: { parts?: Array<{ inlineData?: { data?: string } }> };
        interrupted?: boolean;
        turnComplete?: boolean;
        inputTranscription?: { text?: string };
        outputTranscription?: { text?: string };
      };
      toolCall?: { functionCalls?: Array<{ id?: string; name?: string }> };
    };
    try {
      e = JSON.parse(String(data));
    } catch {
      return;
    }
    if (e.usageMetadata) usage = addGeminiUsage(usage, e.usageMetadata);
    if (e.setupComplete) {
      startedAt = Date.now();
      // The bot speaks first: it placed the call.
      ai.send(
        JSON.stringify({
          clientContent: {
            turns: [
              { role: "user", parts: [{ text: "(The call has connected. Start speaking.)" }] },
            ],
            turnComplete: true,
          },
        }),
      );
      return;
    }
    const sc = e.serverContent;
    if (sc) {
      for (const part of sc.modelTurn?.parts ?? []) {
        if (!part.inlineData?.data) continue;
        const pcm = resamplePcm16(base64ToPcm16(part.inlineData.data), 24000, 8000);
        toPhone(Buffer.from(pcm16ToMulaw(pcm)).toString("base64"));
      }
      if (sc.inputTranscription?.text) callee += sc.inputTranscription.text;
      if (sc.outputTranscription?.text) bot += sc.outputTranscription.text;
      if (sc.interrupted && twilio.readyState === WebSocket.OPEN)
        // Barge-in: the other person talks over the bot, so drop its queued audio.
        twilio.send(JSON.stringify({ event: "clear", streamSid: streamSid() }));
      if (sc.turnComplete || sc.interrupted) await flush();
    }
    for (const call of e.toolCall?.functionCalls ?? []) {
      ai.send(
        JSON.stringify({
          toolResponse: {
            functionResponses: [{ id: call.id, name: call.name, response: { result: "ok" } }],
          },
        }),
      );
      // end_call: let the goodbye finish playing, then leave the stream (Twilio hangs up).
      if (call.name === "end_call")
        setTimeout(async () => {
          await flush();
          close();
        }, 2500);
    }
  });
  return ai;
}
