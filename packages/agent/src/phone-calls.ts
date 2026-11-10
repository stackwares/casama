/**
 * Phone-call voice (SPEC: Phone-call voice; D-135). `voice.call_user` rings the person:
 * - iOS: a PushKit VoIP push through APNs, which the app must turn into a CallKit call.
 * - Android: a high-priority FCM data message; the app shows its own calling screen.
 * - Desktop and web: a `call` notification row, which the app shows as a ringing banner.
 * Answering opens the live call (D-065) in the run's conversation and the bot speaks first.
 * A declined or missed call becomes a normal push with the reason. Quiet hours apply.
 */
import { createPrivateKey, createSign } from "node:crypto";
import { connect } from "node:http2";
import type { Database } from "@kasama/db";
import { sql } from "drizzle-orm";
import { z } from "zod";
import { actingUserOf } from "./acting.ts";
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

/** APNs over HTTP/2 with a token (.p8) key, as Apple's provider API documents. */
export class ApnsVoipSender implements VoipSender {
  private readonly o: { keyP8: string; keyId: string; teamId: string; topic: string; url: string };
  private jwt: { value: string; at: number } | null = null;
  constructor(o: { keyP8: string; keyId: string; teamId: string; topic: string; url?: string }) {
    this.o = { ...o, url: o.url ?? "https://api.push.apple.com" };
  }

  private token() {
    // Apple wants the token refreshed between 20 and 60 minutes.
    if (this.jwt && Date.now() - this.jwt.at < 40 * 60_000) return this.jwt.value;
    const b64 = (x: object) => Buffer.from(JSON.stringify(x)).toString("base64url");
    const unsigned = `${b64({ alg: "ES256", kid: this.o.keyId })}.${b64({ iss: this.o.teamId, iat: Math.floor(Date.now() / 1000) })}`;
    const sig = createSign("SHA256").update(unsigned).sign({ key: createPrivateKey(this.o.keyP8), dsaEncoding: "ieee-p1363" }, "base64url");
    this.jwt = { value: `${unsigned}.${sig}`, at: Date.now() };
    return this.jwt.value;
  }

  async send(tokens: string[], call: CallPayload) {
    const invalidTokens: string[] = [];
    if (!tokens.length) return { invalidTokens };
    const session = connect(this.o.url);
    try {
      for (const t of tokens) {
        const status = await new Promise<number>((resolve, reject) => {
          const req = session.request({
            ":method": "POST",
            ":path": `/3/device/${t}`,
            authorization: `bearer ${this.token()}`,
            "apns-topic": this.o.topic,
            "apns-push-type": "voip",
            "apns-priority": "10",
            "apns-expiration": String(Math.floor(Date.now() / 1000) + RING_SECONDS),
            "content-type": "application/json",
          });
          let code = 0;
          req.on("response", (h) => {
            code = Number(h[":status"]);
          });
          req.on("data", () => {});
          req.on("end", () => resolve(code));
          req.on("error", reject);
          req.end(JSON.stringify({ aps: {}, kind: "call", ...call }));
        });
        // 400 BadDeviceToken and 410 Unregistered mean the token is gone.
        if (status === 410 || status === 400) invalidTokens.push(t);
      }
    } finally {
      session.close();
    }
    return { invalidTokens };
  }
}

export interface PhoneCallDeps {
  db: Database;
  notifications?: NotificationService;
  voip?: VoipSender;
}

/** Rings the person's devices for a new call row. */
export async function ringCall(deps: PhoneCallDeps, userId: string, call: CallPayload) {
  const { db } = deps;
  const voip = await db.execute<{ token: string }>(sql`select token from public.voip_tokens where user_id = ${userId}::uuid`);
  if (voip.length && deps.voip) {
    const { invalidTokens } = await deps.voip.send(voip.map((v) => v.token), call).catch(() => ({ invalidTokens: [] as string[] }));
    for (const t of invalidTokens) await db.execute(sql`delete from public.voip_tokens where token = ${t}`);
  }
  // Android (and any FCM device): a high-priority data message. iOS FCM tokens skip it; they ring through PushKit.
  const android = await db.execute<{ fcm_token: string }>(sql`
    select fcm_token from public.devices where user_id = ${userId}::uuid and platform = 'android'`);
  if (android.length && deps.notifications?.push.sendCall)
    await deps.notifications.push.sendCall(android.map((d) => d.fcm_token), { kind: "call", ...stringify(call) }, RING_SECONDS).catch(() => {});
  // Desktop and web: the in-app banner, through the notifications Realtime topic (no push).
  await db.execute(sql`
    insert into public.notifications (user_id, kind, payload, push_status)
    values (${userId}::uuid, 'call', ${JSON.stringify({ title: call.bot_name, body: call.reason, ...call })}::jsonb, 'sent')`);
}

const stringify = (c: CallPayload) => Object.fromEntries(Object.entries(c).map(([k, v]) => [k, v ?? ""])) as Record<string, string>;

/** A declined or missed call becomes a normal push with the reason. */
export async function callNotAnswered(deps: PhoneCallDeps, callId: string, status: "declined" | "missed") {
  const [c] = await deps.db.execute<{ user_id: string; org_id: string; bot_id: string; reason: string; conversation_id: string | null; name: string }>(sql`
    update public.voice_calls vc set status = ${status}, ended_at = now()
    from public.bots b where vc.id = ${callId}::uuid and vc.status = 'ringing' and b.id = vc.bot_id
    returning vc.user_id, vc.org_id, vc.bot_id, vc.reason, vc.conversation_id, b.name`);
  if (!c) return false;
  const message = {
    title: status === "missed" ? `Missed call from ${c.name}` : `${c.name} wanted to talk`,
    body: c.reason,
    link: c.conversation_id ? `/bots/${c.bot_id}/chat?c=${c.conversation_id}` : `/bots/${c.bot_id}/chat`,
    bot_id: c.bot_id,
    call_id: callId,
  };
  if (deps.notifications) await deps.notifications.notify(c.user_id, c.org_id, "call_missed", { ...message, urgent: true }).catch(() => {});
  // From the API (no push sender): the worker's minute tick sends it.
  else
    await deps.db.execute(sql`
      insert into public.notifications (user_id, org_id, kind, payload, push_status, push_after)
      values (${c.user_id}::uuid, ${c.org_id}::uuid, 'call_missed', ${JSON.stringify(message)}::jsonb, 'deferred', now())`);
  return true;
}

/** Calls nobody answered in time (every minute, from the worker). */
export async function expireCalls(deps: PhoneCallDeps) {
  const due = await deps.db.execute<{ id: string }>(sql`select id from public.voice_calls where status = 'ringing' and expires_at < now() limit 100`);
  for (const c of due) await callNotAnswered(deps, c.id, "missed");
  return due.length;
}

export function registerPhoneCallTools(registry: ToolRegistry, deps: PhoneCallDeps) {
  const { db } = deps;
  registry.register({
    name: "voice.call_user",
    description:
      "Phone the person: their phone rings like a normal call and, if they answer, you talk live in this conversation and speak first. Use only when something is worth interrupting them for and talking is better than a message. Say why in `reason` (shown on the ringing screen). Quiet hours apply; if they're on, a notification is sent instead.",
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
          return { content: "It's their quiet hours, so I didn't call; they'll get a notification with the reason when quiet hours end.", preview: "quiet hours" };
        }
      }
      const [ringing] = await db.execute<{ id: string }>(sql`
        select id from public.voice_calls where user_id = ${user}::uuid and status = 'ringing' and expires_at > now() limit 1`);
      if (ringing) throw new ToolError("already_ringing", "Their phone is already ringing for another call.");
      const [call] = await db.execute<{ id: string }>(sql`
        insert into public.voice_calls (org_id, bot_id, user_id, run_id, conversation_id, reason, expires_at)
        values (${ctx.orgId}::uuid, ${ctx.botId}::uuid, ${user}::uuid, ${ctx.runId}::uuid, ${b?.conversation_id ?? null}::uuid, ${args.reason},
                now() + make_interval(secs => ${RING_SECONDS}))
        returning id`);
      await ringCall(deps, user, { call_id: call!.id, bot_id: ctx.botId, bot_name: b?.name ?? "Kasama", reason: args.reason, conversation_id: b?.conversation_id ?? null });
      return {
        content: `Calling them now (call ${call!.id}). If they answer, the live call opens in this conversation and you speak first. If they don't pick up within ${RING_SECONDS} seconds, they get a notification with the reason.`,
        preview: args.reason,
      };
    },
  });
}

/** What the bot says first when the person answers (added to the live call's instructions). */
export function callGreeting(reason: string) {
  return `You phoned the user and they just answered. You called because: ${reason}\nSpeak first: greet them briefly, say why you called, then listen.`;
}
