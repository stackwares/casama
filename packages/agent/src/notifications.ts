import { createSign } from "node:crypto";
import type { Database } from "@casama/db";
import {
  type PushPrefs,
  pushGroup,
  pushGroupOn,
  pushIsHighPriority,
  type QuietHours,
  quietUntil,
} from "@casama/domain";
import { sql } from "drizzle-orm";
import { attentionHold, type HoldReason, type Why } from "./attention.ts";
import type { LiveTarget, LiveUpdate } from "./live-runs.ts";
import { WATCHER_NO_MATCH } from "./watcher-match.ts";

export interface PushMessage {
  title: string;
  body: string;
  /** Deep link path in the app, for example /approvals/{id} or /bots/{id}/chat. */
  link?: string;
  data?: Record<string, string>;
  /**
   * Buttons on the notification (D-247): the iOS category the app registered ("SUGGESTION": Do it,
   * Not now). Android apps that draw such pushes themselves get them as data messages instead.
   */
  category?: string;
  /** Send as a data-only, high-priority message the app draws itself (Android, D-247). */
  dataOnly?: boolean;
  /**
   * Replaces an earlier notification with the same tag on the phone instead of stacking a second
   * one (Android tag, iOS apns-collapse-id). Briefs use one per bot.
   */
  tag?: string;
  /** Android notification channel (D-325: replies, needs_you, routines, suggestions, account). */
  channel?: string;
  /** "high" for replies and requests, so Android's Doze doesn't hold them. */
  priority?: "high" | "normal";
  /** iOS/macOS stacking key on the lock screen (aps.thread-id). */
  threadId?: string;
  /** iOS/macOS app icon number (aps.badge). */
  badge?: number;
  /** iOS interruption level: time-sensitive for approvals someone is waiting on. */
  interruption?: "time-sensitive";
}

/** How long a notification's text may be. Phones show about two lines collapsed, more expanded. */
export const PUSH_BODY_CHARS = 240;

/**
 * Markdown as the plain text a notification shows (D-312). Phones draw a push's title and body as
 * plain text, so **bold** arrived with its asterisks; links keep their words, lists and lines run
 * together.
 */
export function plainText(md: string): string {
  return (
    md
      // Code fences and inline code keep their text.
      .replace(/```[^\n]*\n?([\s\S]*?)```/g, "$1")
      .replace(/`([^`]*)`/g, "$1")
      // Images go, links keep their words.
      .replace(/!\[([^\]]*)\]\([^)]*\)/g, "$1")
      .replace(/\[([^\]]+)\]\([^)]*\)/g, "$1")
      // Headings, quotes, list markers and rules at the start of a line.
      .replace(/^[ \t]*#{1,6}[ \t]+/gm, "")
      .replace(/^[ \t]*>[ \t]?/gm, "")
      .replace(/^[ \t]*(?:[-*+]|\d+[.)])[ \t]+/gm, "")
      .replace(/^[ \t]*(?:-{3,}|\*{3,}|_{3,})[ \t]*$/gm, "")
      // Bold, italics and strikethrough (an unclosed ** left by a cut too).
      .replace(/(\*\*|__)(.+?)\1/g, "$2")
      .replace(/(^|[\s(])([*_])(\S(?:.*?\S)?)\2(?=[\s).,;:!?]|$)/gm, "$1$3")
      .replace(/~~(.+?)~~/g, "$1")
      .replace(/\*\*|__/g, "")
  );
}

/**
 * A notification's title and body as phones should show them (D-312): plain text, the body's
 * first line dropped when it only repeats the title (a brief's "Morning brief — Mon 16 Nov"), lines
 * joined, and cut at a word with "…".
 */
export function pushText(title: string, body: string, max = PUSH_BODY_CHARS) {
  const t = plainText(title).replace(/\s+/g, " ").trim();
  const lines = plainText(body)
    .split(/\n+/)
    .map((l) => l.replace(/\s+/g, " ").trim())
    .filter(Boolean);
  const key = (s: string) =>
    s
      .toLowerCase()
      .replace(/[^\p{L}\p{N} ]/gu, " ")
      .replace(/\s+/g, " ")
      .trim();
  // Only a heading line (# or wholly bold) that starts with the title's words goes: a sentence
  // that happens to start with the bot's name stays.
  const shortTitle = key(t.replace(/^.*?:\s*/, ""));
  const first = body.trim().split(/\n/)[0]?.trim() ?? "";
  const heading = /^#{1,6}\s/.test(first) || /^(\*\*|__)[^*_]+\1$/.test(first);
  if (lines.length > 1 && heading && shortTitle && key(lines[0] as string).startsWith(shortTitle))
    lines.shift();
  // A line ending in a colon or a full stop reads on into the next; others get a separator.
  let b = lines.reduce(
    (out, l) => (!out ? l : /[.:!?;…]$/.test(out) ? `${out} ${l}` : `${out} · ${l}`),
    "",
  );
  if (b.length > max) {
    const cut = b.slice(0, max - 1);
    const space = cut.lastIndexOf(" ");
    b = `${(space > max * 0.6 ? cut.slice(0, space) : cut).replace(/[\s·,;:–—-]+$/, "")}…`;
  }
  return { title: t, body: b };
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
  /**
   * A followed run's state for the phones that follow it (D-324): iPhone Live Activities and
   * Android's live notification. Never alerts. Unset: this server sends none, and the app keeps
   * the picture up to date while it is open.
   */
  sendLive?(targets: LiveTarget[], update: LiveUpdate): Promise<{ invalidTokens: string[] }>;
  /**
   * Tells Android phones' widgets to fetch the glance again (D-405): a data-only `{kind:
   * "glance"}` message at normal priority, one per phone however many changes it stands for.
   * Unset: this server sends none.
   */
  sendGlance?(tokens: string[]): Promise<{ invalidTokens: string[] }>;
}

/** The Firebase message that refreshes an Android phone's widgets (D-405): nothing to read in it. */
export function fcmGlanceMessage(token: string) {
  return {
    token,
    data: { kind: "glance" },
    // A refresh nobody saw in time is replaced by the next one anyway.
    android: { priority: "NORMAL", ttl: "3600s", collapse_key: "glance" },
  };
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
  readonly live: Array<{ targets: LiveTarget[]; update: LiveUpdate; at: number }> = [];
  async sendLive(targets: LiveTarget[], update: LiveUpdate) {
    this.live.push({ targets, update, at: Date.now() });
    return { invalidTokens: [] };
  }
  readonly glance: Array<{ tokens: string[]; at: number }> = [];
  async sendGlance(tokens: string[]) {
    this.glance.push({ tokens, at: Date.now() });
    return { invalidTokens: [] };
  }
}

/** A live update as an Android data message (LiveRunReceiver reads it): strings only. */
/**
 * The words a Live Activity started by a push shows (app_en.arb's island labels in English): the
 * app gives its own when it starts one, and replaces these the next time it opens.
 */
export const LIVE_ACTIVITY_LABELS = {
  open: "Open",
  stop: "Stop",
  review: "Review",
  allow: "Allow",
  deny: "Deny",
  needs_ok: "Needs your OK",
  working: "Working",
  take_over: "Wants you to take over",
  finished: "Finished",
  problem: "Stopped with a problem",
  stale: "Open Casama for the latest",
} as const;

export function liveData(update: LiveUpdate): Record<string, string> {
  const s = update.state;
  return {
    kind: "live",
    run_id: update.run_id,
    bot_id: update.bot_id,
    bot_name: update.bot_name,
    bot_avatar: update.bot_avatar ?? "",
    started_at: String(update.started_at),
    link: update.link,
    event: update.event,
    phase: s.phase,
    step: s.step,
    steps: String(s.steps),
    approval_id: s.approval_id ?? "",
    risk: s.risk ?? "",
    updated_at: String(s.updated_at),
    ended_at: s.ended_at == null ? "" : String(s.ended_at),
    stale_at: String(update.stale_at),
    dismiss_at: update.dismiss_at == null ? "" : String(update.dismiss_at),
  };
}

/**
 * A live update as one Firebase HTTP v1 message, or null when it can't be addressed (an iPhone
 * row without the phone's own Firebase token). iPhones: Firebase passes `apns.live_activity_token`
 * to Apple as a Live Activity push (decision 8), no alert, so it never buzzes. Android: a
 * data-only message the app draws itself; steps go at normal priority, changes at high.
 */
export function fcmLiveMessage(target: LiveTarget, update: LiveUpdate) {
  if (target.platform === "ios") {
    if (!target.fcm_token) return null;
    return {
      token: target.fcm_token,
      apns: {
        live_activity_token: target.token,
        headers: { "apns-priority": String(update.priority) },
        payload: {
          aps: {
            timestamp: update.state.updated_at,
            event: update.event,
            "content-state": update.state,
            // An ended activity doesn't go stale: Finished stays as it is until it leaves.
            ...(update.event === "end"
              ? update.dismiss_at != null
                ? { "dismissal-date": update.dismiss_at }
                : {}
              : { "stale-date": update.stale_at }),
            // Push-to-start (Phase 6): the activity's fixed part, as the app would have made it,
            // and a silent alert that lights the screen (no sound).
            ...(update.event === "start"
              ? {
                  "attributes-type": "RunActivityAttributes",
                  attributes: {
                    run_id: update.run_id,
                    bot_id: update.bot_id,
                    bot_name: update.bot_name,
                    ...(update.bot_avatar ? { bot_avatar: update.bot_avatar } : {}),
                    started_at: update.started_at,
                    link: update.link,
                    labels: LIVE_ACTIVITY_LABELS,
                  },
                  alert: {
                    title: update.bot_name,
                    body: update.state.step || LIVE_ACTIVITY_LABELS.working,
                  },
                }
              : {}),
          },
        },
      },
    };
  }
  return {
    token: target.token,
    data: liveData(update),
    android: {
      priority: update.priority === 10 ? "HIGH" : "NORMAL",
      // A step nobody saw in time is replaced by the next one anyway.
      ttl: update.priority === 10 ? "3600s" : "120s",
      collapse_key: `live-${update.run_id}`,
    },
  };
}

/**
 * One FCM HTTP v1 message body. Every new field is optional, so old apps get the same push as
 * before plus fields they ignore (D-325).
 */
export function fcmMessage(token: string, message: PushMessage): Record<string, unknown> {
  if (message.dataOnly)
    return {
      token,
      data: {
        ...message.data,
        title: message.title,
        body: message.body,
        ...(message.link ? { link: message.link } : {}),
        ...(message.category ? { category: message.category } : {}),
        ...(message.channel ? { channel: message.channel } : {}),
        ...(message.tag ? { tag: message.tag } : {}),
      },
      android: { priority: "HIGH" },
    };
  const androidNotification = {
    ...(message.tag ? { tag: message.tag } : {}),
    ...(message.channel ? { channel_id: message.channel } : {}),
  };
  const android = {
    ...(message.priority === "high" ? { priority: "HIGH" } : {}),
    ...(Object.keys(androidNotification).length ? { notification: androidNotification } : {}),
  };
  const apnsHeaders = {
    ...(message.tag ? { "apns-collapse-id": message.tag } : {}),
    ...(message.priority === "high" ? { "apns-priority": "10" } : {}),
  };
  return {
    token,
    notification: { title: message.title, body: message.body },
    data: {
      ...message.data,
      ...(message.link ? { link: message.link } : {}),
      ...(message.tag ? { tag: message.tag } : {}),
    },
    ...(Object.keys(android).length ? { android } : {}),
    apns: {
      ...(Object.keys(apnsHeaders).length ? { headers: apnsHeaders } : {}),
      payload: {
        aps: {
          sound: "default",
          ...(message.category ? { category: message.category } : {}),
          ...(message.threadId ? { "thread-id": message.threadId } : {}),
          ...(typeof message.badge === "number" ? { badge: message.badge } : {}),
          ...(message.interruption ? { "interruption-level": message.interruption } : {}),
        },
      },
    },
    ...(message.tag ? { webpush: { notification: { tag: message.tag } } } : {}),
  };
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
          body: JSON.stringify({ message: fcmMessage(token, message) }),
        },
      );
      if (await fcmTokenGone(res)) invalidTokens.push(token);
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
      if (await fcmTokenGone(res)) invalidTokens.push(token);
    }
    return { invalidTokens };
  }

  async sendLive(targets: LiveTarget[], update: LiveUpdate) {
    const invalidTokens: string[] = [];
    const access = await this.accessToken();
    for (const target of targets) {
      const message = fcmLiveMessage(target, update);
      if (!message) continue;
      try {
        const res = await this.fetchImpl(
          `https://fcm.googleapis.com/v1/projects/${this.account.project_id}/messages:send`,
          {
            method: "POST",
            headers: { authorization: `Bearer ${access}`, "content-type": "application/json" },
            body: JSON.stringify({ message }),
          },
        );
        // An ended activity's token is gone too; the row goes either way.
        if (await fcmTokenGone(res)) invalidTokens.push(target.token);
      } catch {
        // One phone out of reach doesn't keep the others from hearing.
      }
    }
    return { invalidTokens };
  }

  async sendGlance(tokens: string[]) {
    const invalidTokens: string[] = [];
    if (!tokens.length) return { invalidTokens };
    const access = await this.accessToken();
    for (const token of tokens) {
      try {
        const res = await this.fetchImpl(
          `https://fcm.googleapis.com/v1/projects/${this.account.project_id}/messages:send`,
          {
            method: "POST",
            headers: { authorization: `Bearer ${access}`, "content-type": "application/json" },
            body: JSON.stringify({ message: fcmGlanceMessage(token) }),
          },
        );
        if (await fcmTokenGone(res)) invalidTokens.push(token);
      } catch {
        // One phone out of reach doesn't keep the others from hearing.
      }
    }
    return { invalidTokens };
  }
}

/**
 * Whether FCM says the device token itself is dead. 404 (UNREGISTERED) always is; a 400 only when
 * it names the token, because a bad payload also answers 400 and used to unsubscribe every phone
 * it was sent to (D-271).
 */
export async function fcmTokenGone(res: Response) {
  if (res.status === 404) return true;
  if (res.status !== 400) return false;
  const body = await res.text().catch(() => "");
  return /UNREGISTERED|registration token|message\.token/i.test(body);
}

/**
 * What kind of push a watch reads (D-410, docs/WATCH-PROTOCOL.md §4), from the inbox kind the
 * phone already reads in `kind` (which keeps its own values, such as `approval_request`).
 */
export function watchKind(kind: string, message: Record<string, unknown> = {}): string {
  switch (kind) {
    case "approval_request":
    case "approval":
      return "approval";
    case "suggestion":
      return "suggestion";
    case "reply":
      return message.failed === true ? "failed" : "reply";
    case "routine_result":
      return message.brief === true ? "brief" : "routine";
    case "checkin_summary":
      return "brief";
    case "takeover":
      return "takeover";
    default:
      return "other";
  }
}

/** Inbox kinds whose push names the reply it is about (message_id, §4). */
const REPLY_KINDS = new Set(["reply", "routine_result", "checkin_summary"]);

/** In-app inbox row plus push to the user's devices. */
export class NotificationService {
  readonly db: Database;
  readonly push: PushSender;
  /**
   * Alerts straight to Apple Watches' own tokens (D-410): this server's Apple key, or Casama
   * Cloud's relay. Unset: Apple Watches get only the iPhone's pushes, mirrored. Wear OS watches'
   * tokens go through [push] as data messages either way.
   */
  watch?: import("./apns.ts").WatchAlertSender;
  /**
   * Hears every inbox row this service adds, after it is written, whatever the push settings
   * (the widgets' refresh pushes, D-405). Must not throw or block.
   */
  onNotify?: (userId: string, kind: string) => void;
  constructor(db: Database, push: PushSender) {
    this.db = db;
    this.push = push;
  }

  private heard(userId: string, kind: string) {
    try {
      this.onNotify?.(userId, kind);
    } catch {
      // A listener's trouble is its own.
    }
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
    // Phones draw plain text (D-312): the inbox row and the push carry the same clean words.
    message = { ...message, ...pushText(message.title, message.body) };
    const payload = proactive
      ? { ...message, why: proactive.why, urgency: proactive.urgency }
      : message;
    // Per-kind settings (D-325): a group that's off keeps the inbox row and sends no push. A reply
    // to a chat that's on screen on any of the person's devices is read already and doesn't buzz.
    const prefs = await this.prefs(userId);
    const focused =
      kind === "reply" && typeof message.conversation_id === "string"
        ? await chatOnScreen(this.db, userId, message.conversation_id).catch(() => false)
        : false;
    if (!pushGroupOn(prefs, pushGroup(kind)) || focused) {
      const [row] = await this.db.execute<{ id: string }>(sql`
        insert into public.notifications (user_id, org_id, kind, payload, push_status, urgency, read_at)
        values (${userId}::uuid, ${orgId}::uuid, ${kind}, ${JSON.stringify(payload)}::jsonb, 'off',
                ${proactive?.urgency ?? null}, ${focused ? new Date().toISOString() : null}::timestamptz)
        returning id`);
      this.heard(userId, kind);
      return row?.id;
    }
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
    const [row] = await this.db.execute<{ id: string }>(sql`
      insert into public.notifications (user_id, org_id, kind, payload, push_status, push_after, urgency, held_reason)
      values (${userId}::uuid, ${orgId}::uuid, ${kind}, ${JSON.stringify(payload)}::jsonb,
              ${held ? "held" : later ? "deferred" : "sent"}, ${later?.toISOString() ?? null}::timestamptz,
              ${proactive?.urgency ?? null}, ${held}) returning id`);
    this.heard(userId, kind);
    // The inbox row is in; a push provider error mustn't fail the caller.
    if (!later && !held)
      await this.pushTo(userId, row?.id ?? "", kind, { ...message, urgent }, prefs, orgId).catch(
        () => {},
      );
    return row?.id;
  }

  /** The person's push settings (D-325); missing or unreadable means everything on. */
  async prefs(userId: string): Promise<PushPrefs> {
    const [p] = await this.db
      .execute<{ push_prefs: PushPrefs | null }>(
        sql`select push_prefs from public.profiles where user_id = ${userId}::uuid`,
      )
      .catch(() => []);
    return p?.push_prefs ?? {};
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

  private async pushTo(
    userId: string,
    notificationId: string,
    kind: string,
    message: PushMessage & Record<string, unknown>,
    prefs?: PushPrefs,
    orgId?: string | null,
  ) {
    const devices = await this.db.execute<{
      fcm_token: string;
      platform: string;
      data_pushes: boolean;
      push_version: number;
    }>(
      sql`select fcm_token, platform, data_pushes, push_version from public.devices where user_id = ${userId}::uuid`,
    );
    // The person's watches with their own push token (D-410), in the workspace this is about.
    const watches = await this.db
      .execute<{ push_token: string; push_kind: "apns" | "fcm"; push_sandbox: boolean | null }>(sql`
        select distinct on (push_token) push_token, push_kind, push_sandbox from public.watch_keys
        where user_id = ${userId}::uuid and push_token is not null
          ${orgId ? sql`and org_id = ${orgId}::uuid` : sql``}`)
      .catch(
        () =>
          [] as Array<{
            push_token: string;
            push_kind: "apns" | "fcm";
            push_sandbox: boolean | null;
          }>,
      );
    if (!devices.length && !watches.length) return;
    prefs ??= await this.prefs(userId);
    const str = (v: unknown) => (typeof v === "string" && v ? v : null);
    const group = pushGroup(kind);
    const conversationId = str(message.conversation_id);
    const botId = str(message.bot_id);
    const runId = str(message.run_id);
    const approvalId = kind === "approval_request" ? str(message.approval_id) : null;
    const risk = str(message.risk);
    // A suggestion carries its id and the buttons to act on it from the notification (D-247).
    const suggestionId = kind === "suggestion" ? str(message.suggestion_id) : null;
    // "Hide reply text" (D-325): the lock screen says who replied, not what.
    const hidden =
      kind === "reply" && prefs.hide_reply_text === true
        ? { body: message.failed === true ? "Couldn't finish" : `${message.title} replied` }
        : {};
    const text = { ...pushText(message.title, message.body), ...hidden };
    // A watch that gets both the phone's copy (mirrored) and its own shows one: Apple folds pushes
    // with the same collapse id, so every push a watch can get has one (§4).
    const appleWatch = watches.some((w) => w.push_kind === "apns");
    const tag = str(message.tag) ?? (appleWatch && notificationId ? `n-${notificationId}` : null);
    // Which reply a reply, routine or brief push is about, so a watch can show it (§4).
    const messageId =
      str(message.message_id) ??
      (runId && REPLY_KINDS.has(kind)
        ? ((
            await this.db
              .execute<{ id: string }>(sql`
                select id from public.messages where run_id = ${runId}::uuid and role = 'assistant'
                order by created_at desc limit 1`)
              .catch(() => [] as Array<{ id: string }>)
          )[0]?.id ?? null)
        : null);
    // Whose push it is, so the web app's notification shows the bot's own picture (mascot,
    // image or initials) instead of only Chrome's logo. Long values (an inline image) stay out.
    const [bot] = botId
      ? await this.db
          .execute<{ name: string; avatar_url: string | null }>(
            sql`select name, avatar_url from public.bots where id = ${botId}::uuid`,
          )
          .catch(() => [])
      : [];
    const botAvatar = bot?.avatar_url && bot.avatar_url.length <= 500 ? bot.avatar_url : null;
    // Approvals below high risk get Approve / Deny on the notification; high risk opens the app.
    const approvalButtons = approvalId !== null && risk !== "high";
    const base: PushMessage = {
      ...text,
      link: message.link,
      ...(tag ? { tag } : {}),
      channel: group,
      priority: pushIsHighPriority(group) ? "high" : "normal",
      threadId: conversationId ?? botId ?? kind,
      badge: await this.badge(userId).catch(() => undefined),
      ...(approvalId !== null && message.urgent === true
        ? { interruption: "time-sensitive" as const }
        : {}),
      data: {
        notification_id: notificationId,
        kind,
        // The watch's kinds (D-410, §4); `kind` keeps the values phones already read.
        watch_kind: watchKind(kind, message),
        link: str(message.link) ?? "/",
        ...(tag ? { tag } : {}),
        ...(conversationId ? { conversation_id: conversationId } : {}),
        ...(botId ? { bot_id: botId } : {}),
        ...(bot?.name ? { bot_name: bot.name } : {}),
        ...(botAvatar ? { bot_avatar: botAvatar } : {}),
        ...(approvalId ? { approval_id: approvalId } : {}),
        ...(approvalId && risk ? { risk } : {}),
        ...(suggestionId ? { suggestion_id: suggestionId } : {}),
        ...(runId && REPLY_KINDS.has(kind) ? { run_id: runId } : {}),
        ...(messageId ? { message_id: messageId } : {}),
      },
      ...(suggestionId
        ? { category: "SUGGESTION" }
        : approvalButtons
          ? { category: "APPROVAL" }
          : // A reply's quick replies on the watch (D-410); phones without the category ignore it.
            kind === "reply" && message.failed !== true
            ? { category: "REPLY" }
            : {}),
    };
    // Casama for Chrome (D-323) always draws its own, with Approve and Deny on approvals.
    const drawsItself = (d: { platform: string; data_pushes: boolean; push_version: number }) =>
      d.platform === "chrome" ||
      (d.platform === "android" &&
        ((suggestionId !== null && d.data_pushes) || (approvalId !== null && d.push_version >= 2)));
    const invalid: string[] = [];
    for (const [list, msg] of [
      [devices.filter((d) => !drawsItself(d)), base],
      // Self-drawn pushes say whose they are: one browser can be signed in to several accounts.
      [
        devices.filter(drawsItself),
        { ...base, dataOnly: true, data: { ...base.data, user_id: userId } },
      ],
    ] as const) {
      if (!list.length) continue;
      const { invalidTokens } = await this.push.send(
        list.map((d) => d.fcm_token),
        msg,
      );
      invalid.push(...invalidTokens);
    }
    for (const t of invalid)
      await this.db.execute(sql`delete from public.devices where fcm_token = ${t}`);
    if (watches.length) await this.pushToWatches(watches, base, userId);
  }

  /**
   * The same push to the person's watches' own tokens (D-410, §4): a Wear OS watch gets a
   * data-only message it draws itself (title and body in the data), an Apple Watch an alert straight
   * to Apple with the phone copy's category, data and collapse id. Tokens Apple or Firebase say are
   * gone are cleared from their keys.
   */
  private async pushToWatches(
    watches: Array<{ push_token: string; push_kind: "apns" | "fcm"; push_sandbox: boolean | null }>,
    base: PushMessage,
    userId: string,
  ) {
    const invalid: string[] = [];
    const wear = watches.filter((w) => w.push_kind === "fcm").map((w) => w.push_token);
    if (wear.length) {
      const { invalidTokens } = await this.push
        .send(wear, {
          ...base,
          dataOnly: true,
          data: { ...base.data, title: base.title, body: base.body, user_id: userId },
        })
        .catch(() => ({ invalidTokens: [] as string[] }));
      invalid.push(...invalidTokens);
    }
    const apple = watches.filter((w) => w.push_kind === "apns");
    if (apple.length && this.watch) {
      const { invalidTokens } = await this.watch
        .sendWatch(
          apple.map((w) => ({ token: w.push_token, sandbox: w.push_sandbox === true })),
          base,
        )
        .catch(() => ({ invalidTokens: [] as string[] }));
      invalid.push(...invalidTokens);
    }
    for (const t of invalid)
      await this.db.execute(sql`
        update public.watch_keys set push_token = null, push_kind = null, push_sandbox = null
        where push_token = ${t}`);
  }

  /**
   * "Open on iPhone" / "Open on phone" from a watch (D-410): a notification on the person's own
   * phones that opens [link], with no inbox row. Answers how many phones it went to.
   */
  async handoff(
    userId: string,
    o: { title: string; link: string; body?: string; tag?: string },
  ): Promise<number> {
    const phones = await this.db.execute<{ fcm_token: string }>(sql`
      select fcm_token from public.devices
      where user_id = ${userId}::uuid and platform in ('ios', 'android')`);
    if (!phones.length) return 0;
    const tokens = phones.map((p) => p.fcm_token);
    const { invalidTokens } = await this.push.send(tokens, {
      ...pushText(o.title, o.body ?? "From your watch"),
      link: o.link,
      tag: o.tag ?? "watch-handoff",
      priority: "high",
      data: { kind: "other", watch_kind: "other", link: o.link, tag: o.tag ?? "watch-handoff" },
    });
    for (const t of invalidTokens)
      await this.db.execute(sql`delete from public.devices where fcm_token = ${t}`);
    return tokens.length - invalidTokens.length;
  }

  /**
   * The app icon's number (D-325), the same sum the app shows: pending approvals and takeovers that
   * wait on this person, plus unread notifications that aren't requests.
   */
  async badge(userId: string): Promise<number> {
    const [r] = await this.db.execute<{ n: number }>(sql`
      select (
        (select count(*) from public.approvals a
           join public.runs r on r.id = a.run_id
           join public.bots b on b.id = a.bot_id
         where a.status = 'pending' and a.expires_at > now()
           and (r.created_by = ${userId}::uuid or b.created_by = ${userId}::uuid))
        + (select count(*) from public.takeover_requests t
             join public.runs r on r.id = t.run_id
             join public.bots b on b.id = t.bot_id
           where t.status = 'pending' and t.expires_at > now()
             and (r.created_by = ${userId}::uuid or b.created_by = ${userId}::uuid))
        + (select count(*) from public.notifications n
           where n.user_id = ${userId}::uuid and n.read_at is null
             and n.kind not in ('approval_request', 'approval', 'takeover'))
      )::int as n`);
    return r?.n ?? 0;
  }

  /** Sends pushes whose quiet hours have ended (every minute, from the worker). */
  async sendDeferred(limit = 200) {
    const due = await this.db.execute<{
      id: string;
      user_id: string;
      org_id: string | null;
      kind: string;
      payload: PushMessage & Record<string, unknown>;
      read: boolean;
    }>(sql`
      update public.notifications set push_status = 'sent'
      where id in (select id from public.notifications where push_status = 'deferred' and push_after <= now()
                   order by push_after limit ${limit} for update skip locked)
      returning id, user_id, org_id, kind, payload, read_at is not null as read`);
    for (const n of due) {
      // Already seen in the app: no need to buzz the phone now.
      if (n.read) continue;
      await this.pushTo(n.user_id, n.id, n.kind, n.payload, undefined, n.org_id).catch(() => {});
    }
    return due.length;
  }
}

/** How long a focus report from the app counts (D-325): the app refreshes it every 30 s. */
export const FOCUS_FRESH_SECONDS = 45;

/** Whether any of the person's app installs has this conversation open and in front (D-325). */
export async function chatOnScreen(db: Database, userId: string, conversationId: string) {
  const [r] = await db.execute<{ on: boolean }>(sql`
    select exists (select 1 from public.chat_focus where user_id = ${userId}::uuid
                   and conversation_id = ${conversationId}::uuid
                   and updated_at > now() - make_interval(secs => ${FOCUS_FRESH_SECONDS})) as on`);
  return r?.on === true;
}

/** A run must take this long before its reply pushes (D-325): quicker answers arrive while you look. */
export const REPLY_PUSH_MIN_MS = 10_000;

export interface ReplyRun {
  runId: string;
  orgId: string;
  botId: string;
  botName: string;
  conversationId: string | null;
  createdBy: string | null;
  trigger: string;
  parentRunId: string | null;
}

/**
 * "Reply ready" and "Couldn't finish" (D-325): a chat run someone started tells them when it ends,
 * if it took a while. Voice (they're on the call), chat apps (Telegram and Slack push for
 * themselves), routines (their own step), sub-runs and cancelled runs never do.
 */
export async function replyPush(
  db: Database,
  notifications: NotificationService | undefined,
  run: ReplyRun,
  outcome: { ok: true; text: string } | { ok: false; message: string },
  minMs = REPLY_PUSH_MIN_MS,
) {
  if (!notifications || !run.createdBy || !run.conversationId || run.parentRunId) return;
  // A watcher that fired has news the person asked to be told (D-413): always, however fast it
  // was. Before, nothing told them; its answer sat in a chat they had no reason to open.
  const watcher = run.trigger === "watcher";
  if (run.trigger !== "chat" && run.trigger !== "mention" && !watcher) return;
  // The change wasn't what it watched for: the person isn't told.
  if (watcher && outcome.ok && outcome.text.trim() === WATCHER_NO_MATCH) return;
  const [r] = await db.execute<{ ms: number; title: string | null; kind: string | null }>(sql`
    select (extract(epoch from (now() - r.created_at)) * 1000)::float8 as ms,
           c.title, c.kind
    from public.runs r left join public.conversations c on c.id = r.conversation_id
    where r.id = ${run.runId}::uuid`);
  // How long the person has waited, queue included.
  if (!r || r.ms < (watcher ? 0 : minMs)) return;
  // The phone already says "Casama" above a push: the default bot shows the chat's title (D-312).
  const title =
    run.botName.trim().toLowerCase() === "casama" ? r.title?.trim() || "Casama" : run.botName;
  const body = outcome.ok
    ? outcome.text.trim() || "Sent you a card"
    : `Couldn't finish: ${outcome.message}`;
  return notifications.notify(run.createdBy, run.orgId, "reply", {
    title,
    // notify() makes it plain text and cuts it (D-312).
    body: body.slice(0, 4000),
    // A group chat opens as the group (D-413): the bot's own chat screen showed the group's
    // thread under one bot's name and sent into it by direct-chat rules.
    link:
      r.kind === "group"
        ? `/groups/${run.conversationId}`
        : `/bots/${run.botId}/chat?c=${run.conversationId}`,
    bot_id: run.botId,
    run_id: run.runId,
    conversation_id: run.conversationId,
    tag: `reply-${run.conversationId}`,
    ...(outcome.ok ? {} : { failed: true }),
  });
}
