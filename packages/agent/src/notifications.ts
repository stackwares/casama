import { createSign } from "node:crypto";
import type { Database } from "@kasama/db";
import { type QuietHours, quietUntil } from "@kasama/domain";
import { sql } from "drizzle-orm";
import { attentionHold, type HoldReason, type Why } from "./attention.ts";

export interface PushMessage {
  title: string;
  body: string;
  /** Deep link path in the app, for example /approvals/{id} or /bots/{id}/chat. */
  link?: string;
  data?: Record<string, string>;
}

/** Sends push notifications to device tokens. */
export interface PushSender {
  send(tokens: string[], message: PushMessage): Promise<{ invalidTokens: string[] }>;
  /** A data-only, high-priority message that rings (Android calls, D-135). */
  sendCall?(
    tokens: string[],
    data: Record<string, string>,
    ttlSeconds: number,
  ): Promise<{ invalidTokens: string[] }>;
}

/** Records pushes (tests and installs without FCM). */
export class RecordingPushSender implements PushSender {
  readonly sent: Array<{ tokens: string[]; message: PushMessage; at: number }> = [];
  readonly calls: Array<{ tokens: string[]; data: Record<string, string>; ttlSeconds: number }> =
    [];
  async send(tokens: string[], message: PushMessage) {
    this.sent.push({ tokens, message, at: Date.now() });
    return { invalidTokens: [] };
  }
  async sendCall(tokens: string[], data: Record<string, string>, ttlSeconds: number) {
    this.calls.push({ tokens, data, ttlSeconds });
    return { invalidTokens: [] };
  }
}

/** Firebase Cloud Messaging HTTP v1 (APNs through FCM) with a service account. */
export class FcmPushSender implements PushSender {
  private readonly account: { client_email: string; private_key: string; project_id: string };
  private token: { value: string; expires: number } | null = null;
  private readonly fetchImpl: typeof fetch;

  constructor(serviceAccountJson: string, fetchImpl: typeof fetch = fetch) {
    this.account = JSON.parse(serviceAccountJson);
    this.fetchImpl = fetchImpl;
  }

  private async accessToken() {
    if (this.token && this.token.expires > Date.now() + 60_000) return this.token.value;
    const now = Math.floor(Date.now() / 1000);
    const b64 = (o: object) => Buffer.from(JSON.stringify(o)).toString("base64url");
    const unsigned = `${b64({ alg: "RS256", typ: "JWT" })}.${b64({
      iss: this.account.client_email,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600,
    })}`;
    const signature = createSign("RSA-SHA256")
      .update(unsigned)
      .sign(this.account.private_key, "base64url");
    const res = await this.fetchImpl("https://oauth2.googleapis.com/token", {
      method: "POST",
      headers: { "content-type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
        assertion: `${unsigned}.${signature}`,
      }),
    });
    if (!res.ok) throw new Error(`FCM auth failed with ${res.status}`);
    const json = (await res.json()) as { access_token: string; expires_in: number };
    this.token = { value: json.access_token, expires: Date.now() + json.expires_in * 1000 };
    return this.token.value;
  }

  async send(tokens: string[], message: PushMessage) {
    const invalidTokens: string[] = [];
    const access = await this.accessToken();
    for (const token of tokens) {
      const res = await this.fetchImpl(
        `https://fcm.googleapis.com/v1/projects/${this.account.project_id}/messages:send`,
        {
          method: "POST",
          headers: { authorization: `Bearer ${access}`, "content-type": "application/json" },
          body: JSON.stringify({
            message: {
              token,
              notification: { title: message.title, body: message.body },
              data: { ...message.data, ...(message.link ? { link: message.link } : {}) },
              apns: { payload: { aps: { sound: "default" } } },
            },
          }),
        },
      );
      if (res.status === 404 || res.status === 400) invalidTokens.push(token);
    }
    return { invalidTokens };
  }

  async sendCall(tokens: string[], data: Record<string, string>, ttlSeconds: number) {
    const invalidTokens: string[] = [];
    const access = await this.accessToken();
    for (const token of tokens) {
      const res = await this.fetchImpl(
        `https://fcm.googleapis.com/v1/projects/${this.account.project_id}/messages:send`,
        {
          method: "POST",
          headers: { authorization: `Bearer ${access}`, "content-type": "application/json" },
          body: JSON.stringify({
            message: { token, data, android: { priority: "HIGH", ttl: `${ttlSeconds}s` } },
          }),
        },
      );
      if (res.status === 404 || res.status === 400) invalidTokens.push(token);
    }
    return { invalidTokens };
  }
}

/** In-app inbox row plus push to the user's devices. */
export class NotificationService {
  readonly db: Database;
  readonly push: PushSender;
  constructor(db: Database, push: PushSender) {
    this.db = db;
    this.push = push;
  }

  async notify(
    userId: string,
    orgId: string | null,
    kind: string,
    message: PushMessage & Record<string, unknown> & { bot_id?: string; urgent?: boolean },
    /**
     * Proactive messages (D-153: check-ins, suggestions, triggered routines): their urgency, why
     * they were sent, and whether attention rules may hold them (briefs carry the held ones, so
     * they aren't held themselves).
     */
    proactive?: { urgency: "low" | "normal" | "urgent"; why: Why; hold?: boolean },
  ) {
    const urgent = message.urgent || proactive?.urgency === "urgent";
    // Attention rules: non-urgent proactive messages wait for the next brief while the person is busy.
    const held: HoldReason | null =
      proactive && !urgent && proactive.hold !== false
        ? proactive.urgency === "low"
          ? "low_urgency"
          : await attentionHold(this.db, userId, message.bot_id ?? null).catch(() => null)
        : null;
    // Quiet hours (D-109): the inbox row now, the push when the window ends (unless urgent).
    const later = urgent || held ? null : await this.quietUntil(userId, message.bot_id ?? null);
    const payload = proactive
      ? { ...message, why: proactive.why, urgency: proactive.urgency }
      : message;
    const [row] = await this.db.execute<{ id: string }>(sql`
      insert into public.notifications (user_id, org_id, kind, payload, push_status, push_after, urgency, held_reason)
      values (${userId}::uuid, ${orgId}::uuid, ${kind}, ${JSON.stringify(payload)}::jsonb,
              ${held ? "held" : later ? "deferred" : "sent"}, ${later?.toISOString() ?? null}::timestamptz,
              ${proactive?.urgency ?? null}, ${held}) returning id`);
    // The inbox row is in; a push provider error mustn't fail the caller.
    if (!later && !held) await this.pushTo(userId, row?.id ?? "", kind, message).catch(() => {});
    return row?.id;
  }

  /** When this person's quiet hours (or their override for this bot) end, if they're on now. */
  async quietUntil(userId: string, botId: string | null, now = new Date()): Promise<Date | null> {
    const [p] = await this.db.execute<{
      timezone: string | null;
      quiet_hours: QuietHours | null;
      bot_quiet: string | null;
      bot_hours: QuietHours | null;
    }>(sql`
      select p.timezone, p.quiet_hours, s.quiet as bot_quiet, s.quiet_hours as bot_hours
      from public.profiles p
      left join public.user_bot_settings s on s.user_id = p.user_id and s.bot_id = ${botId}::uuid
      where p.user_id = ${userId}::uuid`);
    if (!p || p.bot_quiet === "always") return null;
    const hours = p.bot_quiet === "custom" ? p.bot_hours : p.quiet_hours;
    return quietUntil(now, p.timezone ?? "UTC", hours);
  }

  private async pushTo(userId: string, notificationId: string, kind: string, message: PushMessage) {
    const devices = await this.db.execute<{ fcm_token: string }>(
      sql`select fcm_token from public.devices where user_id = ${userId}::uuid`,
    );
    if (!devices.length) return;
    const { invalidTokens } = await this.push.send(
      devices.map((d) => d.fcm_token),
      {
        title: message.title,
        body: message.body,
        link: message.link,
        data: { notification_id: notificationId, kind },
      },
    );
    for (const t of invalidTokens)
      await this.db.execute(sql`delete from public.devices where fcm_token = ${t}`);
  }

  /** Sends pushes whose quiet hours have ended (every minute, from the worker). */
  async sendDeferred(limit = 200) {
    const due = await this.db.execute<{
      id: string;
      user_id: string;
      kind: string;
      payload: PushMessage;
      read: boolean;
    }>(sql`
      update public.notifications set push_status = 'sent'
      where id in (select id from public.notifications where push_status = 'deferred' and push_after <= now()
                   order by push_after limit ${limit} for update skip locked)
      returning id, user_id, kind, payload, read_at is not null as read`);
    for (const n of due) {
      // Already seen in the app: no need to buzz the phone now.
      if (n.read) continue;
      await this.pushTo(n.user_id, n.id, n.kind, n.payload).catch(() => {});
    }
    return due.length;
  }
}
