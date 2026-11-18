import { type GeminiLiveUsage, geminiLiveCost, milestone, track, voicePrices } from "@casama/agent";
import { contentKeys, type Database as Db } from "@casama/db";
import { cloudCharge } from "@casama/domain";
import { sql } from "drizzle-orm";

/**
 * Live calls are billed on what the server can see, not only what the app reports (D-248): a
 * billable call starts with a hold of HOLD_MINUTES at the per-minute estimate, and the ended call
 * is charged at least its length on the clock at Gemini's listening-only rate.
 */
export const HOLD_MINUTES = 2;
/** Gemini Live audio in: $3 per 1M tokens, 25 tokens a second. */
export const LISTEN_FLOOR_PER_MINUTE = 0.0045;
/** A Gemini Live token lasts 30 minutes; no call outlives it. */
export const TOKEN_LIFE_SECONDS = 30 * 60;
/** A call with no heartbeat for this long is over (D-327): the app sends one every 30 seconds. */
export const SILENT_CALL_SECONDS = 120;

export interface SettleCall {
  orgId: string;
  botId: string;
  conversationId: string;
  /** The call's server record (D-327); older apps have none, so the hold is found by conversation. */
  liveCallId?: string | null;
  billable: boolean;
  /** What the app (or the last heartbeat) says the call lasted. */
  seconds: number;
  usage?: GeminiLiveUsage | null;
  provider?: string | null;
  /** The call's length on the server's clock; by default, the time since its hold was taken. */
  clockSeconds?: number;
  /** Keep at least the hold: the call never reported anything, so its hold is not refunded. */
  keepHold?: boolean;
}

/**
 * Records what a call cost and settles its hold: Google's price from the token counts (or the
 * per-minute estimate), at least the clock at the listening rate when billable, less the hold.
 */
export async function settleCall(db: Db, p: SettleCall) {
  const cost = p.usage
    ? geminiLiveCost(p.usage)
    : (p.seconds / 60) * voicePrices().geminiLivePerMinute;
  const [hold] = p.billable
    ? await db.execute<{ id: string; cost_usd: string; elapsed: string }>(sql`
        select id, cost_usd::text, extract(epoch from now() - created_at)::text as elapsed
        from public.usage_ledger
        where org_id = ${p.orgId}::uuid and kind = 'voice_seconds' and (meta->>'hold')::boolean
          and not coalesce((meta->>'settled')::boolean, false)
          and ${
            p.liveCallId
              ? sql`meta->>'live_call_id' = ${p.liveCallId}`
              : sql`meta->>'conversation_id' = ${p.conversationId}`
          }
        order by created_at desc limit 1`)
    : [];
  const clock = Math.min(p.clockSeconds ?? (hold ? Number(hold.elapsed) : 0), TOKEN_LIFE_SECONDS);
  const heldProviderCost = p.keepHold && hold ? Number(hold.cost_usd) / cloudCharge(1) : 0;
  const providerCost = p.billable
    ? Math.max(cost, (clock / 60) * LISTEN_FLOOR_PER_MINUTE, heldProviderCost)
    : cost;
  // Replaces the hold with the call's real price: negative when the call cost less than the hold,
  // so a short call isn't charged the hold.
  const charge = p.billable ? cloudCharge(providerCost) - Number(hold?.cost_usd ?? 0) : cost;
  if (hold)
    await db.execute(
      sql`update public.usage_ledger set meta = meta || '{"settled": true}'::jsonb where id = ${hold.id}::uuid`,
    );
  if (p.seconds > 0 || charge !== 0)
    await db.execute(sql`insert into public.usage_ledger (org_id, bot_id, kind, quantity, cost_usd, upstream_cost_usd, billable, meta)
      values (${p.orgId}::uuid, ${p.botId}::uuid, 'voice_seconds', ${Math.round(p.seconds)}, ${charge},
              ${p.billable ? cost : null}, ${p.billable},
              ${JSON.stringify({
                provider: p.provider ?? "gemini",
                conversation_id: p.conversationId,
                ...(p.liveCallId ? { live_call_id: p.liveCallId } : {}),
                ...(p.usage ? { tokens: p.usage } : { estimated: true }),
                ...(p.billable
                  ? {
                      key: "server",
                      provider_cost_usd: providerCost,
                      clock_seconds: Math.round(clock),
                    }
                  : {}),
              })}::jsonb)`);
  return { charge, providerCost, clock };
}

/** Of two reports of a call's tokens, the one that costs more (either may be missing). */
export function higherUsage(
  a: GeminiLiveUsage | null | undefined,
  b: GeminiLiveUsage | null | undefined,
): GeminiLiveUsage | null {
  if (!a) return b ?? null;
  if (!b) return a;
  return geminiLiveCost(b) > geminiLiveCost(a) ? b : a;
}

/** What the server's relay counted for a call (billing audit 2026-11-17), or null if not relayed. */
export async function relayCounts(db: Db, liveCallId: string): Promise<GeminiLiveUsage | null> {
  const [r] = await db.execute<{ usage: Record<string, unknown> }>(
    sql`select usage from public.live_call_relays where live_call_id = ${liveCallId}::uuid`,
  );
  if (!r) return null;
  const n = (k: string) => Number(r.usage?.[k] ?? 0) || 0;
  const unattributed = n("input_unattributed_tokens");
  return {
    input_audio_tokens: n("input_audio_tokens"),
    input_text_tokens: n("input_text_tokens"),
    output_audio_tokens: n("output_audio_tokens"),
    output_text_tokens: n("output_text_tokens"),
    ...(unattributed > 0 ? { input_unattributed_tokens: unattributed } : {}),
  };
}

type LiveCallRow = {
  id: string;
  org_id: string;
  bot_id: string;
  conversation_id: string;
  user_id: string;
  provider: string;
  billable: boolean;
  usage: GeminiLiveUsage | null;
  started_at: string;
  last_seen_at: string;
};

/**
 * Marks a call ended once (the app hanging up and the sweep can race; only one wins) and returns
 * it, or null when it had already ended.
 */
export async function claimCallEnd(
  db: Db,
  id: string,
  reason: "hung_up" | "silent",
  seconds: number | null,
) {
  const [row] = await db.execute<LiveCallRow>(sql`
    update public.live_calls set ended_at = now(), end_reason = ${reason},
      seconds = coalesce(${seconds}::int,
        least(extract(epoch from last_seen_at - started_at), ${TOKEN_LIFE_SECONDS})::int)
    where id = ${id}::uuid and ended_at is null
    returning id, org_id, bot_id, conversation_id, user_id, provider, billable, usage,
      started_at::text, last_seen_at::text`);
  return row ?? null;
}

/**
 * Calls whose app went quiet (every minute, from the worker): no heartbeat for 2 minutes means the
 * app was swiped away, crashed or lost the network for good. Each is ended and billed the length
 * up to its last heartbeat, with the token counts that heartbeat carried.
 *
 * The app talks to Google directly, so the server can't cut a quiet call off: its token may still
 * be in use. Billable calls are therefore charged at least the clock up to now (at most the token's
 * life) at the listening rate, and a call that never sent a heartbeat keeps its hold (billing audit
 * 2026-11-17; before, a client that never sent one paid nothing).
 */
export async function endSilentCalls(db: Db) {
  const due = await db.execute<{ id: string }>(sql`
    select id from public.live_calls
    where ended_at is null and last_seen_at < now() - make_interval(secs => ${SILENT_CALL_SECONDS})
    order by last_seen_at limit 100`);
  let ended = 0;
  for (const d of due) {
    const call = await claimCallEnd(db, d.id, "silent", null);
    if (!call) continue;
    const length = Math.max(
      0,
      Math.min(
        (Date.parse(call.last_seen_at) - Date.parse(call.started_at)) / 1000,
        TOKEN_LIFE_SECONDS,
      ),
    );
    const relayed = await relayCounts(db, call.id);
    await settleCall(db, {
      orgId: call.org_id,
      botId: call.bot_id,
      conversationId: call.conversation_id,
      liveCallId: call.id,
      billable: call.billable,
      seconds: length,
      usage: higherUsage(relayed, call.usage),
      provider: call.provider,
      clockSeconds: call.billable
        ? Math.max(
            length,
            Math.min((Date.now() - Date.parse(call.started_at)) / 1000, TOKEN_LIFE_SECONDS),
          )
        : length,
      keepHold:
        call.billable && !call.usage && length <= 0 && !(relayed && geminiLiveCost(relayed) > 0),
    });
    await postCallRecap(db, call, length);
    if (length > 0) {
      track(db, {
        event: "call_ended",
        userId: call.user_id,
        orgId: call.org_id,
        properties: {
          provider: call.provider,
          duration_s: Math.round(length),
          billable: call.billable,
          ended_by: "server",
        },
      });
      milestone(db, call.user_id, "first_voice_call", call.org_id);
    }
    ended++;
  }
  return ended;
}

/** One job started on a call, for the recap. */
export interface CallTask {
  run_id: string;
  task: string;
  status: string;
}

/** "3:12", or "1:02:05" past an hour. */
export function callLength(seconds: number) {
  const s = Math.max(0, Math.round(seconds));
  const h = Math.floor(s / 3600);
  const m = Math.floor((s % 3600) / 60);
  const ss = String(s % 60).padStart(2, "0");
  return h > 0 ? `${h}:${String(m).padStart(2, "0")}:${ss}` : `${m}:${ss}`;
}

/**
 * The recap at the end of a call, in its chat (D-327 §8): how long it was and what was started on
 * it, with each job's run. The app shows the `call` part as a card; the text part is for older apps
 * and anything else that reads the chat. Nothing for a call that never connected and started nothing.
 */
export async function postCallRecap(
  db: Db,
  call: { id: string; org_id: string; conversation_id: string },
  seconds: number,
) {
  const rows = await db.execute<{ run_id: string; status: string; content: unknown }>(sql`
    select r.id as run_id, r.status, m.content
    from public.live_calls lc
    cross join lateral unnest(lc.task_run_ids) with ordinality as t(run_id, n)
    join public.runs r on r.id = t.run_id
    left join lateral (
      select content from public.messages
      where run_id = r.id and role = 'user' order by created_at limit 1
    ) m on true
    where lc.id = ${call.id}::uuid
    order by t.n`);
  const tasks: CallTask[] = rows.map((r) => {
    const parts = r.content == null ? null : contentKeys.open(r.content);
    const text = Array.isArray(parts)
      ? parts
          .filter((p): p is { type: "text"; text: string } => p?.type === "text")
          .map((p) => p.text ?? "")
          .join(" ")
      : "";
    return { run_id: r.run_id, task: text.trim().slice(0, 300), status: r.status };
  });
  if (Math.round(seconds) <= 0 && tasks.length === 0) return null;
  const text = [
    `Call ended · ${callLength(seconds)}`,
    ...(tasks.length ? [`Started on the call: ${tasks.map((t) => t.task).join("; ")}`] : []),
  ].join("\n");
  const content = [
    { type: "text", text },
    { type: "call", live_call_id: call.id, seconds: Math.round(seconds), tasks },
  ];
  const [m] = await db.execute<{ id: string }>(sql`
    insert into public.messages (org_id, conversation_id, role, content)
    values (${call.org_id}::uuid, ${call.conversation_id}::uuid, 'assistant',
            ${contentKeys.sealJson(call.org_id, content)}::jsonb)
    returning id`);
  await db.execute(
    sql`update public.conversations set last_message_at = now() where id = ${call.conversation_id}::uuid`,
  );
  return m?.id ?? null;
}
