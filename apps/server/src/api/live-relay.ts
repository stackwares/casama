/**
 * The live-call relay (billing audit 2026-11-17, D-333): a call paid from credits connects to
 * the server instead of Gemini, and the server passes every frame through unchanged while it counts
 * Gemini's own usageMetadata. The app holds only a relay secret, so it can't reach Gemini on the
 * server's key without the relay, and what the call is charged no longer rests on the app's report.
 *
 * The app needs no change: it connects to the session's `connect_url` with `?access_token=` and
 * speaks the same protocol (setup, audio, session resumption) as it did to Gemini.
 *
 * Call limits (D-426): the relay also keeps a call inside its limits while it runs: its longest
 * length, and the workspace's credits, daily limit, monthly quota and the bot's daily budget (runs
 * check the same before every step, D-022). About `warning_seconds` before a limit it tells the
 * bot to warn the person; at the limit it asks the bot for a short goodbye, then closes the stream
 * with CALL_OVER_CLOSE and ends the call: billed, recap posted. After that it takes no reconnect.
 */
import { createHash, randomBytes, timingSafeEqual } from "node:crypto";
import type { IncomingMessage, Server } from "node:http";
import type { Duplex } from "node:stream";
import { addGeminiUsage, emptyGeminiUsage, type GeminiLiveUsage, voicePrices } from "@casama/agent";
import { contentKeys } from "@casama/db";
import { callLimits, cloudCharge } from "@casama/domain";
import { sql } from "drizzle-orm";
import { type RawData, WebSocket, WebSocketServer } from "ws";
import {
  type CallLimitReason,
  callHeadroom,
  endCallForLimit,
  relayCounts,
} from "../billing/live-calls.ts";
import { OpenSockets } from "./drain.ts";
import type { AppDeps } from "./types.ts";

const PATH = /^\/v1\/voice\/live\/([0-9a-f-]{36})\/relay$/;
/** How often a relayed call's usage is written down while it runs. */
const FLUSH_MS = 5_000;
/** How often an open relay checks that its call hasn't been ended (by the app or the sweep). */
const CHECK_MS = 15_000;
/** Frames held while the provider connection opens; more than this means something is wrong. */
const MAX_PENDING = 256;
/** The bot's goodbye: about this long is kept for it (D-426). */
const GOODBYE_SECONDS = 20;
/** The relay's limit timings (D-426); tests shorten them. */
export const relayTiming = {
  /** How often a relayed call checks its limits. */
  guardMs: 20_000,
  /** The first check after (re)connecting. */
  firstGuardMs: 3_000,
  /** The longest the bot's goodbye may take. */
  goodbyeMaxMs: 30_000,
  /** After the stream closes, the app has this long to end the call itself before the relay does. */
  appEndGraceMs: 8_000,
};
/** Close code for "this call is over, don't reconnect" (D-426); the app reads it. */
export const CALL_OVER_CLOSE = 4410;

/** Words the bot is given when a limit is near or reached (D-426). */
export function limitNote(
  reason: CallLimitReason,
  stage: "warn" | "goodbye",
  maxMinutes = callLimits().max_call_minutes,
) {
  const why: Record<CallLimitReason, [string, string]> = {
    max_length: [
      `this call reaches its ${maxMinutes}-minute limit in about a minute`,
      `this call has reached its ${maxMinutes}-minute limit`,
    ],
    credits: [
      "the workspace is nearly out of credits for this call",
      "the workspace is out of credits for this call",
    ],
    daily_cap: [
      "the workspace has nearly used today's spending limit",
      "the workspace has used today's spending limit",
    ],
    quota: [
      "the workspace has nearly reached its monthly spending limit",
      "the workspace has reached its monthly spending limit",
    ],
    bot_budget: ["you've nearly used your daily budget", "you've used your daily budget"],
  };
  const sayWhy =
    reason === "max_length"
      ? "the call is reaching its time limit"
      : reason === "credits"
        ? "you're nearly out of credits"
        : "you're nearly at the spending limit";
  return stage === "warn"
    ? `(Note from Casama, not from the user: ${why[reason][0]}. At the next natural pause, tell the user in one short sentence that ${sayWhy} and you'll have to hang up soon, then carry on.)`
    : `(Note from Casama, not from the user: ${why[reason][1]}, so the call ends now. Say goodbye in one or two short sentences: say why, and that anything left carries on in the chat. Don't call tools or start anything new.)`;
}

const hash = (s: string) => createHash("sha256").update(s).digest("hex");

/** The relay's public address for a call, or null when the relay is off. */
export function relayUrl(deps: Pick<AppDeps, "env">, liveCallId: string): string | null {
  const mode = deps.env.LIVE_CALL_RELAY;
  const base = deps.env.PUBLIC_API_URL;
  if (mode === "off" || !base) return null;
  return `${base.replace(/\/$/, "").replace(/^http/, "ws")}/v1/voice/live/${liveCallId}/relay`;
}

/** Stores a call's provider token behind a new relay secret, which is returned for the app. */
export async function createRelay(
  db: AppDeps["db"],
  call: { id: string; orgId: string },
  provider: { connectUrl: string; clientSecret: string; expiresAt: string },
) {
  const secret = randomBytes(32).toString("base64url");
  await db.execute(sql`
    insert into public.live_call_relays (live_call_id, org_id, secret_hash, provider_url, provider_token, expires_at)
    values (${call.id}::uuid, ${call.orgId}::uuid, ${hash(secret)}, ${provider.connectUrl},
            ${contentKeys.sealJson(call.orgId, { token: provider.clientSecret })}::jsonb, ${provider.expiresAt}::timestamptz)`);
  return secret;
}

/** Adds what a relay saw to its call's total. */
async function addUsage(db: AppDeps["db"], id: string, u: GeminiLiveUsage) {
  if (
    !u.input_audio_tokens &&
    !u.input_text_tokens &&
    !u.output_audio_tokens &&
    !u.output_text_tokens &&
    !u.input_unattributed_tokens
  )
    return;
  await db.execute(sql`
    update public.live_call_relays set usage = jsonb_build_object(
      'input_audio_tokens', coalesce((usage->>'input_audio_tokens')::bigint, 0) + ${u.input_audio_tokens},
      'input_text_tokens', coalesce((usage->>'input_text_tokens')::bigint, 0) + ${u.input_text_tokens},
      'output_audio_tokens', coalesce((usage->>'output_audio_tokens')::bigint, 0) + ${u.output_audio_tokens},
      'output_text_tokens', coalesce((usage->>'output_text_tokens')::bigint, 0) + ${u.output_text_tokens},
      'input_unattributed_tokens', coalesce((usage->>'input_unattributed_tokens')::bigint, 0) + ${u.input_unattributed_tokens ?? 0})
    where live_call_id = ${id}::uuid`);
}

/** Open relays in this process, by call, so the end of a call can write their last counts first. */
const open = new Map<string, Set<() => Promise<void>>>();

/**
 * Every relayed call in this process (D-402): a stopping API carries them through a handover, then
 * closes them with the restart code, after their last counts are written, so the app resumes the
 * call on the new server.
 */
export const relayedCalls = new OpenSockets();

/**
 * What the relay counted for a call, after writing down what open connections in this process
 * still hold; null when the call wasn't relayed.
 */
export async function relayedUsage(
  db: AppDeps["db"],
  liveCallId: string,
): Promise<GeminiLiveUsage | null> {
  for (const flush of open.get(liveCallId) ?? []) await flush().catch(() => undefined);
  return relayCounts(db, liveCallId);
}

function reject(socket: Duplex, status: number, text: string) {
  socket.write(`HTTP/1.1 ${status} ${text}\r\nConnection: close\r\nContent-Length: 0\r\n\r\n`);
  socket.destroy();
}

export function attachLiveRelay(server: Server, deps: AppDeps) {
  const { db } = deps;
  const wss = new WebSocketServer({ noServer: true });
  server.on("upgrade", async (req: IncomingMessage, socket: Duplex, head: Buffer) => {
    const url = new URL(req.url ?? "/", "http://api");
    const id = url.pathname.match(PATH)?.[1];
    if (!id) return;
    try {
      const secret = url.searchParams.get("access_token") ?? "";
      const [row] = await db.execute<{
        secret_hash: string;
        provider_url: string;
        provider_token: unknown;
        ended: boolean;
        expired: boolean;
      }>(sql`
        select r.secret_hash, r.provider_url, r.provider_token,
          (lc.ended_at is not null or lc.limit_closed_at is not null) as ended, r.expires_at <= now() as expired
        from public.live_call_relays r join public.live_calls lc on lc.id = r.live_call_id
        where r.live_call_id = ${id}::uuid`);
      const given = Buffer.from(hash(secret));
      const want = Buffer.from(row?.secret_hash ?? "");
      if (!row || !secret || given.length !== want.length || !timingSafeEqual(given, want))
        return reject(socket, 401, "Unauthorized");
      if (row.ended || row.expired) return reject(socket, 410, "Gone");
      const token = String(
        (contentKeys.open(row.provider_token) as { token?: string } | null)?.token ?? "",
      );
      wss.handleUpgrade(req, socket, head, (client) =>
        relay(deps, id, client, `${row.provider_url}?access_token=${encodeURIComponent(token)}`),
      );
    } catch (err) {
      deps.logger.warn("live relay refused", { error: (err as Error).message });
      reject(socket, 500, "Internal Server Error");
    }
  });
}

function relay(deps: AppDeps, id: string, client: WebSocket, providerUrl: string) {
  const { db } = deps;
  const upstream = new WebSocket(providerUrl);
  const pending: Array<[RawData, boolean]> = [];
  let unsaved = emptyGeminiUsage();
  let closed = false;

  const flush = async () => {
    const u = unsaved;
    unsaved = emptyGeminiUsage();
    await addUsage(db, id, u);
  };
  const flushes = open.get(id) ?? new Set();
  flushes.add(flush);
  open.set(id, flushes);

  const timer = setInterval(() => void flush().catch(() => undefined), FLUSH_MS);
  const check = setInterval(async () => {
    const [r] = await db
      .execute<{ ended: boolean }>(sql`
        select (lc.ended_at is not null or r.expires_at <= now()) as ended
        from public.live_calls lc join public.live_call_relays r on r.live_call_id = lc.id
        where lc.id = ${id}::uuid`)
      .catch(() => [] as Array<{ ended: boolean }>);
    // The call was ended (the app hung up, or the sweep ended a quiet one): so is the stream.
    if (r?.ended) close(1000, "call ended");
  }, CHECK_MS);

  // Limits (D-426) -------------------------------------------------------------------------
  let wrapping = false;
  let finishing = false;
  let goodbyeAt = 0;
  let goodbyeAudioMs = 0;
  let goodbyeTimer: ReturnType<typeof setTimeout> | undefined;
  let wrapReason: CallLimitReason = "max_length";
  let lastSample: { at: number; charge: number } | null = null;

  /** Speaks to the model as the app's own notes do: a user turn it answers at once. */
  const inject = (text: string) => {
    if (upstream.readyState !== WebSocket.OPEN) return false;
    upstream.send(
      JSON.stringify({
        clientContent: { turns: [{ role: "user", parts: [{ text }] }], turnComplete: true },
      }),
    );
    return true;
  };

  /** Closes the stream for good, then ends the call unless the app does it first. */
  const finish = async (reason: CallLimitReason) => {
    if (finishing) return;
    finishing = true;
    clearTimeout(goodbyeTimer);
    await db
      .execute(
        sql`update public.live_calls set limit_closed_at = coalesce(limit_closed_at, now()) where id = ${id}::uuid`,
      )
      .catch(() => undefined);
    await close(CALL_OVER_CLOSE, `call over: ${reason}`);
    // The app posts its transcript and ends the call when the stream closes, so its last turns
    // land before the recap; an app that doesn't is ended here.
    setTimeout(
      () =>
        void endCallForLimit(db, id, reason).catch((err) =>
          deps.logger.warn("call limit end failed", { error: (err as Error).message }),
        ),
      relayTiming.appEndGraceMs,
    ).unref?.();
  };

  const goodbye = async (reason: CallLimitReason) => {
    if (wrapping) return;
    wrapping = true;
    wrapReason = reason;
    const [mine] = await db.execute<{ id: string }>(sql`
      update public.live_calls set limit_reason = ${reason}, limit_wrap_at = now()
      where id = ${id}::uuid and limit_wrap_at is null and ended_at is null returning id`);
    // Another connection already said goodbye (this one is a reconnect), or the call ended.
    if (!mine || !inject(limitNote(reason, "goodbye"))) return void (await finish(reason));
    goodbyeAt = Date.now();
    goodbyeAudioMs = 0;
    goodbyeTimer = setTimeout(() => void finish(reason), relayTiming.goodbyeMaxMs);
    deps.logger.info("call limit reached", { live_call_id: id, reason });
  };

  /** The bot finished its goodbye: close once the app has played it. */
  const goodbyeHeard = (text: string) => {
    // 24 kHz, 16-bit mono PCM: 48 bytes a millisecond.
    for (const m of text.matchAll(/"data"\s*:\s*"([A-Za-z0-9+/=]+)"/g))
      goodbyeAudioMs += ((m[1]?.length ?? 0) * 3) / 4 / 48;
    if (!goodbyeAudioMs || !text.includes('"turnComplete"')) return;
    const playing = Math.max(0, goodbyeAt + goodbyeAudioMs - Date.now());
    clearTimeout(goodbyeTimer);
    goodbyeTimer = setTimeout(
      () => void finish(wrapReason),
      Math.min(playing + 1500, Math.max(0, goodbyeAt + relayTiming.goodbyeMaxMs - Date.now())),
    );
  };

  const guardTick = async () => {
    if (closed || wrapping || finishing) return;
    const [c] = await db.execute<{
      org_id: string;
      bot_id: string;
      billable: boolean;
      started_at: string;
      limit_reason: CallLimitReason | null;
      warned: boolean;
      wrapped: boolean;
      ended: boolean;
    }>(sql`
      select org_id, bot_id, billable, started_at::text, limit_reason,
        limit_warned_at is not null as warned, limit_wrap_at is not null as wrapped,
        ended_at is not null as ended
      from public.live_calls where id = ${id}::uuid`);
    if (!c || c.ended) return;
    // A goodbye already began on an earlier connection: this reconnect only closes the call.
    if (c.wrapped) return void (await finish(c.limit_reason ?? "max_length"));
    const limits = callLimits();
    const elapsed = (Date.now() - Date.parse(c.started_at)) / 1000;
    const maxSeconds = limits.max_call_minutes * 60;
    let stop: CallLimitReason | null = elapsed >= maxSeconds ? "max_length" : null;
    let warn: CallLimitReason | null =
      !stop && elapsed >= maxSeconds - limits.warning_seconds ? "max_length" : null;
    if (!stop && c.billable && deps.billing) {
      await flush();
      const room = await callHeadroom(
        db,
        { id, orgId: c.org_id, botId: c.bot_id, startedAt: c.started_at },
        await deps.billing.balance(c.org_id),
        await relayCounts(db, id),
      );
      // What the call spends a second: measured between checks, at least the per-minute price.
      const now = Date.now();
      const estimate = cloudCharge(voicePrices().geminiLivePerMinute) / 60;
      const measured = lastSample
        ? (room.callCharge - lastSample.charge) / Math.max(1, (now - lastSample.at) / 1000)
        : 0;
      lastSample = { at: now, charge: room.callCharge };
      const perSecond = Math.max(estimate, measured);
      if (room.reason && room.left <= perSecond * GOODBYE_SECONDS) stop = room.reason;
      else if (
        room.reason &&
        room.left <=
          perSecond * (limits.warning_seconds + relayTiming.guardMs / 1000 + GOODBYE_SECONDS)
      )
        warn = room.reason;
    }
    if (stop) return void (await goodbye(stop));
    if (!warn || (c.warned && c.limit_reason === warn) || upstream.readyState !== WebSocket.OPEN)
      return;
    const [first] = await db.execute<{ id: string }>(sql`
      update public.live_calls set limit_warned_at = now(), limit_reason = ${warn}
      where id = ${id}::uuid and ended_at is null and limit_wrap_at is null
        and (limit_warned_at is null or limit_reason is distinct from ${warn})
      returning id`);
    if (first) inject(limitNote(warn, "warn"));
  };
  const runGuard = () =>
    void guardTick().catch((err) =>
      deps.logger.warn("call limit check failed", { error: (err as Error).message }),
    );
  const guard = setInterval(runGuard, relayTiming.guardMs);
  // Soon after (re)connecting too: a reconnect after a goodbye began closes at once.
  const firstGuard = setTimeout(runGuard, relayTiming.firstGuardMs);

  const untrack = relayedCalls.add((code, reason) => close(code, reason));
  let saved: Promise<void> = Promise.resolve();
  const close = (code = 1000, reason = "") => {
    if (closed) return saved;
    closed = true;
    untrack();
    clearInterval(timer);
    clearInterval(check);
    clearInterval(guard);
    clearTimeout(firstGuard);
    if (!finishing) clearTimeout(goodbyeTimer);
    if (upstream.readyState <= WebSocket.OPEN) upstream.close();
    if (client.readyState <= WebSocket.OPEN) client.close(code, reason);
    saved = flush()
      .catch((err) =>
        deps.logger.warn("live relay usage not saved", { error: (err as Error).message }),
      )
      .finally(() => {
        flushes.delete(flush);
        if (!flushes.size) open.delete(id);
      });
    return saved;
  };

  client.on("message", (data, isBinary) => {
    if (upstream.readyState === WebSocket.OPEN) upstream.send(data, { binary: isBinary });
    else if (upstream.readyState === WebSocket.CONNECTING && pending.length < MAX_PENDING)
      pending.push([data, isBinary]);
    else close(1011, "provider unavailable");
  });
  upstream.on("open", () => {
    for (const [data, isBinary] of pending.splice(0)) upstream.send(data, { binary: isBinary });
  });
  upstream.on("message", (data, isBinary) => {
    if (client.readyState === WebSocket.OPEN) client.send(data, { binary: isBinary });
    const text = Array.isArray(data)
      ? Buffer.concat(data).toString("utf8")
      : Buffer.from(data as ArrayBuffer).toString("utf8");
    if (wrapping && !finishing && goodbyeAt) goodbyeHeard(text);
    if (!text.includes('"usageMetadata"')) return;
    try {
      const m = JSON.parse(text) as { usageMetadata?: unknown };
      if (m.usageMetadata) unsaved = addGeminiUsage(unsaved, m.usageMetadata);
    } catch {
      // Not JSON: nothing to count.
    }
  });
  // Gemini's close code and reason (a goAway, a bad setup) reach the app as they were.
  upstream.on("close", (code, reason) => {
    const ok =
      (code >= 1000 && code <= 1014 && code !== 1004 && code !== 1005 && code !== 1006) ||
      (code >= 3000 && code <= 4999);
    close(
      ok ? code : 1011,
      reason
        .toString()
        .replace(/[^\x20-\x7e]/g, "")
        .slice(0, 120),
    );
  });
  upstream.on("error", () => close(1011, "provider unavailable"));
  client.on("close", () => close());
  client.on("error", () => close());
}
