import { type GeminiLiveUsage, geminiLiveCost, milestone, track, voicePrices } from "@casama/agent";
import type { Database as Db } from "@casama/db";
import { callLifeSeconds, callLimits, cloudCharge, cloudModelDailyCap } from "@casama/domain";
import { sql } from "drizzle-orm";
import { postCallRecap } from "../services/call-recap.ts";

/**
 * Live calls are billed on what the server can see, not only what the app reports (D-248): a
 * billable call starts with a hold of HOLD_MINUTES at the per-minute estimate, and the ended call
 * is charged at least its length on the clock at Gemini's listening-only rate.
 */
export const HOLD_MINUTES = 2;
/** Gemini Live audio in: $3 per 1M tokens, 25 tokens a second. */
export const LISTEN_FLOOR_PER_MINUTE = 0.0045;
/**
 * How long a call can last on the clock (D-426): its token lives the longest call plus a few
 * minutes (`callLifeSeconds`), and no call is billed past that. A call with no heartbeat for
 * `abandoned_seconds` is over; both are in Admin → Call limits.
 */
const lifeSeconds = () => callLifeSeconds();
/** After its longest length, a call gets this long for its goodbye before the sweep ends it. */
export const OVERLONG_GRACE_SECONDS = 120;

/** Why a call was ended for it (D-426): its length, or money running out. */
export type CallLimitReason = "max_length" | "credits" | "daily_cap" | "quota" | "bot_budget";

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
  const clock = Math.min(p.clockSeconds ?? (hold ? Number(hold.elapsed) : 0), lifeSeconds());
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
 * it, or null when it had already ended. A call a limit was ending keeps that limit as its reason,
 * whoever gets there first (D-426).
 */
export async function claimCallEnd(
  db: Db,
  id: string,
  reason: "hung_up" | "silent" | CallLimitReason,
  seconds: number | null,
) {
  const [row] = await db.execute<LiveCallRow>(sql`
    update public.live_calls set ended_at = now(),
      end_reason = case when limit_wrap_at is not null then coalesce(limit_reason, ${reason}) else ${reason} end,
      seconds = coalesce(${seconds}::int,
        least(extract(epoch from last_seen_at - started_at), ${lifeSeconds()})::int)
    where id = ${id}::uuid and ended_at is null
    returning id, org_id, bot_id, conversation_id, user_id, provider, billable, usage,
      started_at::text, last_seen_at::text`);
  return row ?? null;
}

/**
 * Calls whose app went quiet (every minute, from the worker): no heartbeat for `abandoned_seconds`
 * (Admin → Call limits, D-426) means the app was swiped away, crashed or lost the network for
 * good. Each is ended and billed the length up to its last heartbeat, with the token counts that
 * heartbeat carried. A call still going past its longest length (plus time for a goodbye) is ended
 * the same way: the relay ends calls paid from credits itself, the app the rest, and this catches
 * an app that didn't (one from before D-426): its next heartbeat hears the call is over.
 *
 * The app talks to Google directly, so the server can't cut a quiet call off: its token may still
 * be in use. Billable calls are therefore charged at least the clock up to now (at most the token's
 * life) at the listening rate, and a call that never sent a heartbeat keeps its hold (billing audit
 * 2026-11-17; before, a client that never sent one paid nothing).
 */
export async function endSilentCalls(db: Db) {
  const limits = callLimits();
  const due = await db.execute<{ id: string; overlong: boolean }>(sql`
    select id, last_seen_at >= now() - make_interval(secs => ${limits.abandoned_seconds}) as overlong
    from public.live_calls
    where ended_at is null
      and (last_seen_at < now() - make_interval(secs => ${limits.abandoned_seconds})
        or started_at < now() - make_interval(secs => ${limits.max_call_minutes * 60 + OVERLONG_GRACE_SECONDS}))
    order by last_seen_at limit 100`);
  let ended = 0;
  for (const d of due) {
    if (d.overlong)
      await db.execute(sql`
        update public.live_calls set limit_reason = coalesce(limit_reason, 'max_length'),
          limit_wrap_at = coalesce(limit_wrap_at, now())
        where id = ${d.id}::uuid and ended_at is null`);
    const call = await claimCallEnd(db, d.id, d.overlong ? "max_length" : "silent", null);
    if (!call) continue;
    const length = Math.max(
      0,
      Math.min((Date.parse(call.last_seen_at) - Date.parse(call.started_at)) / 1000, lifeSeconds()),
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
            Math.min((Date.now() - Date.parse(call.started_at)) / 1000, lifeSeconds()),
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
          ended_by: d.overlong ? "max_length" : "server",
        },
      });
      milestone(db, call.user_id, "first_voice_call", call.org_id);
    }
    ended++;
  }
  return ended;
}

/**
 * Ends a call for a limit (D-426), once, when the app hasn't already: billed what the relay
 * counted (at least its clock), with the recap posted. Returns false when it had already ended.
 */
export async function endCallForLimit(db: Db, id: string, reason: CallLimitReason) {
  const [open] = await db.execute<{ started_at: string }>(
    sql`select started_at::text from public.live_calls where id = ${id}::uuid and ended_at is null`,
  );
  if (!open) return false;
  const length = Math.max(
    0,
    Math.min((Date.now() - Date.parse(open.started_at)) / 1000, lifeSeconds()),
  );
  const call = await claimCallEnd(db, id, reason, Math.round(length));
  if (!call) return false;
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
    clockSeconds: length,
  });
  await postCallRecap(db, call, length);
  track(db, {
    event: "call_ended",
    userId: call.user_id,
    orgId: call.org_id,
    properties: {
      provider: call.provider,
      duration_s: Math.round(length),
      billable: call.billable,
      ended_by: reason,
    },
  });
  milestone(db, call.user_id, "first_voice_call", call.org_id);
  return true;
}

/** How much a call paid from credits may still spend before a limit stops it (D-426). */
export interface CallHeadroom {
  /** USD (as charged) left under the tightest limit, after what this call has used so far. */
  left: number;
  /** The tightest limit, or null when none applies. */
  reason: Exclude<CallLimitReason, "max_length"> | null;
  /** What this call has been charged so far, beyond its hold (already in the ledger). */
  callCharge: number;
}

/**
 * What's left under each limit a run also stops at (D-022): the workspace's credits, its daily
 * limit on Casama's keys, its monthly cost quota, and the bot's daily budget. The call's own use so
 * far is the relay's counts priced like the final bill (at least its clock at the listening rate),
 * less its hold, which the ledger already holds. [balance]: the workspace's credit balance.
 */
export async function callHeadroom(
  db: Db,
  call: { id: string; orgId: string; botId: string; startedAt: string },
  balance: number,
  usage: GeminiLiveUsage | null,
): Promise<CallHeadroom> {
  const [row] = await db.execute<{
    unbilled: string;
    cloud_today: string;
    org_period: string;
    bot_today: string;
    quota: string | null;
    limits: Record<string, unknown> | null;
    plan_code: string | null;
    bot_daily: unknown;
    hold: string | null;
  }>(sql`
    select
      (select coalesce(sum(cost_usd), 0) from public.usage_ledger
        where org_id = ${call.orgId}::uuid and billable and billed_at is null)::text as unbilled,
      greatest(0, (select coalesce(sum(cost_usd), 0) from public.usage_ledger
        where org_id = ${call.orgId}::uuid and billable
          and kind <> all('{computer_seconds,stream_seconds}'::text[])
          and created_at >= date_trunc('day', now() at time zone 'utc') at time zone 'utc')
        -- A saved reset that cleared today's limit (D-443) counts from where it left off.
        - public.limit_reset_offset(${call.orgId}::uuid, 'daily'))::text as cloud_today,
      (select coalesce(sum(cost_usd), 0) from public.usage_ledger
        where org_id = ${call.orgId}::uuid
          and created_at >= date_trunc('month', now() at time zone 'utc') at time zone 'utc')::text as org_period,
      (select coalesce(sum(cost_usd), 0) from public.usage_ledger
        where bot_id = ${call.botId}::uuid
          and created_at >= date_trunc('day', now() at time zone 'utc') at time zone 'utc')::text as bot_today,
      (select max_cost_usd::text from public.quotas where org_id = ${call.orgId}::uuid and period = 'month') as quota,
      (select limits from public.entitlements where org_id = ${call.orgId}::uuid order by created_at desc limit 1) as limits,
      (select plan_code from public.entitlements where org_id = ${call.orgId}::uuid order by created_at desc limit 1) as plan_code,
      (select budget->'daily_usd' from public.bots where id = ${call.botId}::uuid) as bot_daily,
      (select cost_usd::text from public.usage_ledger
        where org_id = ${call.orgId}::uuid and kind = 'voice_seconds' and (meta->>'hold')::boolean
          and not coalesce((meta->>'settled')::boolean, false) and meta->>'live_call_id' = ${call.id}
        order by created_at desc limit 1) as hold`);
  const clock = Math.min((Date.now() - Date.parse(call.startedAt)) / 1000, lifeSeconds());
  const providerCost = Math.max(
    usage ? geminiLiveCost(usage) : 0,
    (Math.max(0, clock) / 60) * LISTEN_FLOOR_PER_MINUTE,
  );
  const callCharge = Math.max(0, cloudCharge(providerCost) - Number(row?.hold ?? 0));
  const limits = row?.limits ?? {};
  const num = (v: unknown) => (typeof v === "number" && v >= 0 ? v : null);
  const quotas = [row?.quota == null ? null : Number(row.quota), num(limits.monthly_usd)].filter(
    (v): v is number => v != null,
  );
  const options: Array<[Exclude<CallLimitReason, "max_length">, number]> = [
    ["credits", balance - Number(row?.unbilled ?? 0)],
    [
      "daily_cap",
      cloudModelDailyCap(row?.plan_code, limits.cloud_daily_usd) - Number(row?.cloud_today ?? 0),
    ],
  ];
  if (quotas.length) options.push(["quota", Math.min(...quotas) - Number(row?.org_period ?? 0)]);
  const botDaily = num(row?.bot_daily);
  if (botDaily != null) options.push(["bot_budget", botDaily - Number(row?.bot_today ?? 0)]);
  let best: CallHeadroom = { left: Number.POSITIVE_INFINITY, reason: null, callCharge };
  for (const [reason, room] of options) {
    const left = room - callCharge;
    if (left < best.left) best = { left, reason, callCharge };
  }
  return best;
}

export { type CallTask, callLength, postCallRecap } from "../services/call-recap.ts";
