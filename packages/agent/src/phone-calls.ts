/**
 * Phone-call voice (SPEC: Phone-call voice; D-135). `voice.call_user` rings the person:
 * - iOS: a PushKit VoIP push through APNs, which the app must turn into a CallKit call.
 * - Android: a high-priority FCM data message; the app shows its own calling screen.
 * - Desktop and web: a `call` notification row, which the app shows as a ringing banner.
 * Answering opens the live call (D-065) in the run's conversation and the bot speaks first.
 * A declined or missed call becomes a normal push with the reason. Quiet hours apply.
 *
 * Ring limits (D-426): the person can stop a bot from phoning them, a person gets at most
 * `ring_daily_cap` rings a day (their time zone), and a bot waits `ring_cooldown_minutes` before
 * ringing the same person again. Over a limit there's no ring: one ordinary notification with the
 * reason instead (once per cooldown, however often the bot tries), and the bot is told why.
 */
import { createHmac, timingSafeEqual } from "node:crypto";
import { contentKeys, type Database } from "@casama/db";
import { callLimits, isValidTimezone } from "@casama/domain";
import { sql } from "drizzle-orm";
import { z } from "zod";
import { actingUserOf } from "./acting.ts";
import { ApnsClient, apnsTokenGone } from "./apns.ts";
import type { NotificationService } from "./notifications.ts";
import { ToolError, type ToolRegistry } from "./tools/registry.ts";

/** How long a call rings before it counts as missed. */
export const RING_SECONDS = 45;

export interface CallPayload {
  call_id: string;
  bot_id: string;
  bot_name: string;
  reason: string;
  conversation_id: string | null;
}

/** Sends VoIP pushes (iOS PushKit). */
export interface VoipSender {
  send(tokens: string[], call: CallPayload): Promise<{ invalidTokens: string[] }>;
}

export class RecordingVoipSender implements VoipSender {
  readonly sent: Array<{ tokens: string[]; call: CallPayload }> = [];
  async send(tokens: string[], call: CallPayload) {
    this.sent.push({ tokens, call });
    return { invalidTokens: [] };
  }
}

/** iPhone call rings through APNs (PushKit), on the shared Apple client. */
export class ApnsVoipSender implements VoipSender {
  private readonly client: ApnsClient;
  private readonly topic: string;
  constructor(o: { keyP8: string; keyId: string; teamId: string; topic: string; url?: string }) {
    // Call rings always go to one host (production, or the test server in `url`).
    this.client = new ApnsClient({ ...o, sandboxUrl: o.url });
    this.topic = o.topic;
  }

  async send(tokens: string[], call: CallPayload) {
    const results = await this.client.sendAll(
      tokens,
      () => ({
        "apns-topic": this.topic,
        "apns-push-type": "voip",
        "apns-priority": "10",
        "apns-expiration": String(Math.floor(Date.now() / 1000) + RING_SECONDS),
      }),
      JSON.stringify({ aps: {}, kind: "call", ...call }),
    );
    // Other 400s are about the request, not the token (D-271).
    return { invalidTokens: results.filter(apnsTokenGone).map((r) => r.token) };
  }
}

export interface PhoneCallDeps {
  db: Database;
  notifications?: NotificationService;
  voip?: VoipSender;
  /** Signs Android rings' decline tokens ([callDeclineSecret]); none: no token is sent. */
  declineSecret?: string;
}

/**
 * The secret behind ring decline tokens (D-424): the JWT secret, so nothing new has to be
 * configured. The API checks with the same one.
 */
export const callDeclineSecret = (jwtSecret: string) => `call-decline:${jwtSecret}`;

/**
 * A ring's decline token (D-424): Decline on Android's calling screen with the app closed has no
 * sign-in to hand, so the ring carries this, good for declining that one call only.
 */
export function callDeclineToken(secret: string, callId: string): string {
  return createHmac("sha256", secret).update(`decline:${callId}`).digest("base64url").slice(0, 32);
}

export function callDeclineTokenValid(secret: string, callId: string, token: string): boolean {
  const a = Buffer.from(token);
  const b = Buffer.from(callDeclineToken(secret, callId));
  return a.length === b.length && timingSafeEqual(a, b);
}

/**
 * Rings the person's devices for a new call row. Answers whether anything could ring (D-438): a
 * phone took the ring, or they have a computer or browser set up, which shows the banner. A ring
 * that reached nothing doesn't count toward the ring limits.
 */
export async function ringCall(
  deps: PhoneCallDeps,
  userId: string,
  call: CallPayload,
): Promise<boolean> {
  const { db } = deps;
  let reached = 0;
  const voip = await db.execute<{ token: string }>(
    sql`select token from public.voip_tokens where user_id = ${userId}::uuid`,
  );
  if (voip.length && deps.voip) {
    const { invalidTokens } = await deps.voip
      .send(
        voip.map((v) => v.token),
        call,
      )
      .catch(() => ({ invalidTokens: [] as string[] }));
    for (const t of invalidTokens)
      await db.execute(sql`delete from public.voip_tokens where token = ${t}`);
    reached += voip.length - invalidTokens.length;
  }
  // Android (and any FCM device): a high-priority data message. iOS FCM tokens skip it; they ring through PushKit.
  const android = await db.execute<{ fcm_token: string }>(sql`
    select fcm_token from public.devices where user_id = ${userId}::uuid and platform = 'android'`);
  if (android.length && deps.notifications?.push.sendCall) {
    reached += android.length;
    await deps.notifications.push
      .sendCall(
        android.map((d) => d.fcm_token),
        {
          kind: "call",
          ...stringify(call),
          ...(deps.declineSecret
            ? { decline_token: callDeclineToken(deps.declineSecret, call.call_id) }
            : {}),
        },
        RING_SECONDS,
      )
      .catch(() => {});
  }
  // Desktop and web: the in-app banner, through the notifications Realtime topic (no push).
  await db.execute(sql`
    insert into public.notifications (user_id, kind, payload, push_status)
    values (${userId}::uuid, 'call', ${JSON.stringify({ title: call.bot_name, body: call.reason, ...call })}::jsonb, 'sent')`);
  if (reached > 0) return true;
  const [screens] = await db.execute<{ n: number }>(sql`
    select count(*)::int as n from public.devices where user_id = ${userId}::uuid and platform not in ('ios', 'android')`);
  return (screens?.n ?? 0) > 0;
}

/**
 * Stops the ring on the person's other devices once the call is answered, declined or missed
 * (D-425): a `call_cancel` data message to their phones (Android ends its calling screen, even with
 * the app closed; an iPhone ends its CallKit ring if the app is running) and a `call` row, which the
 * desktop and web banners and open apps hear over Realtime. Every device gets it: the one that
 * answered knows it did and keeps its call.
 */
export async function cancelRing(deps: PhoneCallDeps, userId: string, callId: string) {
  const { db } = deps;
  const phones = await db.execute<{ fcm_token: string }>(sql`
    select fcm_token from public.devices where user_id = ${userId}::uuid and platform in ('android', 'ios')`);
  if (phones.length && deps.notifications?.push.sendCall)
    await deps.notifications.push
      .sendCall(
        phones.map((d) => d.fcm_token),
        { kind: "call_cancel", call_id: callId },
        RING_SECONDS,
      )
      .catch(() => {});
  await db.execute(sql`
    insert into public.notifications (user_id, kind, payload, push_status)
    values (${userId}::uuid, 'call', ${JSON.stringify({ call_id: callId, ended: true })}::jsonb, 'sent')`);
}

const stringify = (c: CallPayload) =>
  Object.fromEntries(Object.entries(c).map(([k, v]) => [k, v ?? ""])) as Record<string, string>;

/** The missed-call card: a `call` part the app draws, and a text part for older apps. */
async function postMissedCard(
  db: Database,
  c: { org_id: string; conversation_id: string | null; reason: string },
) {
  const reason = c.reason.trim().slice(0, 300);
  const part = {
    type: "call",
    live_call_id: null,
    seconds: 0,
    kind: "phone",
    ended: "missed",
    started_at: null,
    ended_at: new Date().toISOString(),
    turns: 0,
    tasks: [],
    actions: [],
    summary: { status: "skipped" },
    next_steps: [],
    ...(reason ? { reason } : {}),
  };
  const text = reason ? `Missed call\n${reason}` : "Missed call";
  await db.execute(sql`
    insert into public.messages (org_id, conversation_id, role, content)
    values (${c.org_id}::uuid, ${c.conversation_id}::uuid, 'assistant',
            ${contentKeys.sealJson(c.org_id, [{ type: "text", text }, part])}::jsonb)`);
  await db.execute(
    sql`update public.conversations set last_message_at = now() where id = ${c.conversation_id}::uuid`,
  );
}

/** A declined or missed call becomes a normal push with the reason. */
export async function callNotAnswered(
  deps: PhoneCallDeps,
  callId: string,
  status: "declined" | "missed",
) {
  const [c] = await deps.db.execute<{
    user_id: string;
    org_id: string;
    bot_id: string;
    reason: string;
    conversation_id: string | null;
    name: string;
  }>(sql`
    update public.voice_calls vc set status = ${status}, ended_at = now()
    from public.bots b where vc.id = ${callId}::uuid and vc.status = 'ringing' and b.id = vc.bot_id
    returning vc.user_id, vc.org_id, vc.bot_id, vc.reason, vc.conversation_id, b.name`);
  if (!c) return false;
  // From the API, its caller stops the ring itself (with the API's push sender).
  if (deps.notifications) await cancelRing(deps, c.user_id, callId);
  const message = {
    title: status === "missed" ? `Missed call from ${c.name}` : `${c.name} wanted to talk`,
    body: c.reason,
    link: c.conversation_id
      ? `/bots/${c.bot_id}/chat?c=${c.conversation_id}`
      : `/bots/${c.bot_id}/chat`,
    bot_id: c.bot_id,
    call_id: callId,
  };
  // A missed ring leaves a slim call card in its chat (call card plan §3.1), so the person can
  // see why and call back from there.
  if (status === "missed" && c.conversation_id) await postMissedCard(deps.db, c).catch(() => {});
  if (deps.notifications)
    await deps.notifications
      .notify(c.user_id, c.org_id, "call_missed", { ...message, urgent: true })
      .catch(() => {});
  // From the API (no push sender): the worker's minute tick sends it.
  else
    await deps.db.execute(sql`
      insert into public.notifications (user_id, org_id, kind, payload, push_status, push_after)
      values (${c.user_id}::uuid, ${c.org_id}::uuid, 'call_missed', ${JSON.stringify(message)}::jsonb, 'deferred', now())`);
  return true;
}

/** Calls nobody answered in time (every minute, from the worker). */
export async function expireCalls(deps: PhoneCallDeps) {
  const due = await deps.db.execute<{ id: string }>(
    sql`select id from public.voice_calls where status = 'ringing' and expires_at < now() limit 100`,
  );
  for (const c of due) await callNotAnswered(deps, c.id, "missed");
  return due.length;
}

export type RingBlock = "may_not_call" | "cooldown" | "daily_cap";

/** Why a bot may not ring this person now, or null when it may (D-426). */
export async function ringBlocked(
  db: Database,
  userId: string,
  botId: string,
  limits = callLimits(),
): Promise<{ block: RingBlock; until?: Date } | null> {
  const [r] = await db.execute<{
    may_call: boolean | null;
    timezone: string | null;
    last_ring: string | null;
  }>(sql`
    select
      (select may_call from public.user_bot_settings where user_id = ${userId}::uuid and bot_id = ${botId}::uuid) as may_call,
      (select timezone from public.profiles where user_id = ${userId}::uuid) as timezone,
      (select max(created_at)::text from public.voice_calls
        where user_id = ${userId}::uuid and bot_id = ${botId}::uuid and blocked is null and reached) as last_ring`);
  if (r?.may_call === false) return { block: "may_not_call" };
  // The daily cap first: it lasts longer, so it's the more useful thing to tell the bot.
  const tz = r?.timezone && isValidTimezone(r.timezone) ? r.timezone : "UTC";
  const [today] = await db.execute<{ n: number }>(sql`
    select count(*)::int as n from public.voice_calls
    where user_id = ${userId}::uuid and blocked is null and reached
      and created_at >= date_trunc('day', now() at time zone ${tz}) at time zone ${tz}`);
  if ((today?.n ?? 0) >= limits.ring_daily_cap) return { block: "daily_cap" };
  if (r?.last_ring && limits.ring_cooldown_minutes > 0) {
    const until = new Date(Date.parse(r.last_ring) + limits.ring_cooldown_minutes * 60_000);
    if (until.getTime() > Date.now()) return { block: "cooldown", until };
  }
  return null;
}

/** What the bot is told when a limit stopped its ring. */
function blockedReply(block: RingBlock, until: Date | undefined, cap: number) {
  switch (block) {
    case "may_not_call":
      return "They've turned off calls from you in your settings, so I didn't ring them; they got a notification with the reason instead. Don't try to call again; message them.";
    case "cooldown": {
      const mins = until ? Math.max(1, Math.ceil((until.getTime() - Date.now()) / 60_000)) : 0;
      return `You rang them a short while ago, so I didn't ring again; they got a notification with the reason instead. You can call again in about ${mins} minute${mins === 1 ? "" : "s"}, but only if it's still worth interrupting them.`;
    }
    case "daily_cap":
      return cap === 0
        ? "Bots can't phone people on this server, so I didn't ring them; they got a notification with the reason instead. Message them."
        : `They've had ${cap} call${cap === 1 ? "" : "s"} from bots today, the most a day, so I didn't ring; they got a notification with the reason instead. Don't try to call again today; message them.`;
  }
}

export function registerPhoneCallTools(registry: ToolRegistry, deps: PhoneCallDeps) {
  const { db } = deps;
  registry.register({
    name: "voice.call_user",
    description:
      "Phone the person: their phone rings like a normal call and, if they answer, you talk live in this conversation and speak first. Use only when something is worth interrupting them for and talking is better than a message. Say why in `reason` (shown on the ringing screen). Quiet hours apply, and so do ring limits (calls a day, time between calls, and whether they let you call at all); when one stops the call a notification is sent instead and you're told why.",
    risk: "medium",
    category: "send",
    schema: z.object({ reason: z.string().min(1).max(300) }),
    async execute(args, ctx) {
      const user = await actingUserOf(db, ctx.runId);
      if (!user) throw new ToolError("no_person", "There's nobody to call.");
      const [b] = await db.execute<{ name: string; conversation_id: string | null }>(sql`
        select b.name, r.conversation_id from public.bots b, public.runs r where b.id = ${ctx.botId}::uuid and r.id = ${ctx.runId}::uuid`);
      if (deps.notifications) {
        const quiet = await deps.notifications.quietUntil(user, ctx.botId);
        if (quiet) {
          await deps.notifications.notify(user, ctx.orgId, "call_missed", {
            title: `${b?.name ?? "Your bot"} wanted to call`,
            body: args.reason,
            link: `/bots/${ctx.botId}/chat${b?.conversation_id ? `?c=${b.conversation_id}` : ""}`,
            bot_id: ctx.botId,
          });
          return {
            content:
              "It's their quiet hours, so I didn't call; they'll get a notification with the reason when quiet hours end.",
            preview: "quiet hours",
          };
        }
      }
      const limits = callLimits();
      const blocked = await ringBlocked(db, user, ctx.botId, limits);
      if (blocked) {
        // One notification per cooldown (at least an hour) for blocked tries, however often the bot
        // tries: a limit exists so the person isn't pestered.
        const quietFor = Math.max(60, limits.ring_cooldown_minutes);
        const [told] = await db.execute<{ id: string }>(sql`
          select id from public.voice_calls
          where user_id = ${user}::uuid and bot_id = ${ctx.botId}::uuid and blocked is not null
            and created_at > now() - make_interval(mins => ${quietFor}) limit 1`);
        await db.execute(sql`
          insert into public.voice_calls (org_id, bot_id, user_id, run_id, conversation_id, reason, status, blocked, expires_at, ended_at)
          values (${ctx.orgId}::uuid, ${ctx.botId}::uuid, ${user}::uuid, ${ctx.runId}::uuid, ${b?.conversation_id ?? null}::uuid,
                  ${args.reason}, 'cancelled', ${blocked.block}, now(), now())`);
        if (!told && deps.notifications)
          await deps.notifications
            .notify(user, ctx.orgId, "call_missed", {
              title: `${b?.name ?? "Your bot"} wanted to call`,
              body: args.reason,
              link: `/bots/${ctx.botId}/chat${b?.conversation_id ? `?c=${b.conversation_id}` : ""}`,
              bot_id: ctx.botId,
            })
            .catch(() => {});
        return {
          content: blockedReply(blocked.block, blocked.until, limits.ring_daily_cap),
          preview: `not called: ${blocked.block.replace(/_/g, " ")}`,
        };
      }
      const [ringing] = await db.execute<{ id: string }>(sql`
        select id from public.voice_calls where user_id = ${user}::uuid and status = 'ringing' and expires_at > now() limit 1`);
      if (ringing)
        throw new ToolError("already_ringing", "Their phone is already ringing for another call.");
      const [call] = await db.execute<{ id: string }>(sql`
        insert into public.voice_calls (org_id, bot_id, user_id, run_id, conversation_id, reason, expires_at)
        values (${ctx.orgId}::uuid, ${ctx.botId}::uuid, ${user}::uuid, ${ctx.runId}::uuid, ${b?.conversation_id ?? null}::uuid, ${args.reason},
                now() + make_interval(secs => ${RING_SECONDS}))
        returning id`);
      const reached = await ringCall(deps, user, {
        call_id: call!.id,
        bot_id: ctx.botId,
        bot_name: b?.name ?? "Casama",
        reason: args.reason,
        conversation_id: b?.conversation_id ?? null,
      });
      if (!reached) {
        // Nothing to ring (no phone or computer set up for calls): it doesn't count toward the
        // ring limits (D-438), so a later try once the app is set up isn't held back.
        await db.execute(
          sql`update public.voice_calls set reached = false where id = ${call!.id}::uuid`,
        );
        return {
          content: `They have no phone or computer set up to ring (call ${call!.id}): it only shows in the app if it's open now. If they don't pick up within ${RING_SECONDS} seconds, they get a notification with the reason. Their phone may need the Casama app opened, signed in, with notifications on.`,
          preview: args.reason,
        };
      }
      return {
        content: `Calling them now (call ${call!.id}). If they answer, the live call opens in this conversation and you speak first. If they don't pick up within ${RING_SECONDS} seconds, they get a notification with the reason.`,
        preview: args.reason,
      };
    },
  });
}

/**
 * The person started the call (D-234): the bot answers like a phone, greeting them first so they
 * aren't left talking into silence. [name]: what they like to be called, when known.
 */
export function answerGreeting(name?: string | null) {
  const who = name?.trim() ? ` (${name.trim()})` : "";
  return `The user${who} just called you and the line is open. Speak first: say hi warmly in one short sentence${who ? ", using their name" : ""}, and ask what you can do for them. Then listen.`;
}

/** What the bot says first when the person answers (added to the live call's instructions). */
export function callGreeting(reason: string) {
  return `You phoned the user and they just answered. You called because: ${reason}\nSpeak first: greet them briefly, say why you called, then listen.`;
}
