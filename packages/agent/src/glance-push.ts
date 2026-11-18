/**
 * Widget refresh pushes (D-405, docs/WIDGETS-PLAN.md §8.3 step 4, §8.9).
 *
 * When something a widget shows changes, the person's widgets are told to fetch the glance again.
 * The push carries nothing to read: Apple gets `{"aps":{"content-changed":true}}` as a WidgetKit
 * push, Android a data-only `{kind: "glance"}` message. So Apple, Google and Casama Cloud's relay
 * learn only that something changed.
 *
 * - Needs-you changes (an approval or takeover asked or answered, a suggestion made or answered)
 *   go at once, Apple priority 10.
 * - Everything else (a run started or finished, a routine changed, a brief, an inbox row) is
 *   gathered into at most one push every five minutes per person, Apple priority 5.
 *
 * The worker and the API each run one: the worker hears run events and inbox rows, the API the
 * answers and routine changes people make there.
 */
import type { Database } from "@casama/db";
import { sql } from "drizzle-orm";
import { type ApnsClient, apnsTokenGone } from "./apns.ts";
import type { PushSender } from "./notifications.ts";

export interface WidgetPushTarget {
  /** Apple's WidgetKit push token (hex) or an Android phone's Firebase token. */
  token: string;
  kind: "apns_widgets" | "fcm";
  /** Apple tokens from a development build go to Apple's sandbox. */
  sandbox: boolean;
}

export interface WidgetPushSender {
  sendWidgets(
    targets: WidgetPushTarget[],
    o: { urgent: boolean },
  ): Promise<{ invalidTokens: string[] }>;
}

/** The topic Apple wants for widget pushes: the app's bundle id plus `.push-type.widgets`. */
export const widgetTopic = (appBundleId: string) => `${appBundleId}.push-type.widgets`;

/** The body of an Apple widget push: nothing but "it changed". */
export const APPLE_WIDGET_BODY = JSON.stringify({ aps: { "content-changed": true } });

/** WidgetKit pushes straight to Apple: Firebase can't send them (the token isn't Firebase's). */
export class ApnsWidgetSender {
  private readonly client: ApnsClient;
  private readonly topic: string;
  constructor(client: ApnsClient, o: { appBundleId?: string } = {}) {
    this.client = client;
    this.topic = widgetTopic(o.appBundleId ?? "ai.casama.app");
  }

  async send(targets: WidgetPushTarget[], o: { urgent: boolean }) {
    const invalidTokens: string[] = [];
    const headers = () => ({
      "apns-topic": this.topic,
      "apns-push-type": "widgets",
      "apns-priority": o.urgent ? "10" : "5",
      // A refresh that can't be delivered within the hour is replaced by the widget's own.
      "apns-expiration": String(Math.floor(Date.now() / 1000) + 3600),
    });
    for (const sandbox of [false, true]) {
      const tokens = targets.filter((t) => t.sandbox === sandbox).map((t) => t.token);
      if (!tokens.length) continue;
      try {
        const results = await this.client.sendAll(tokens, headers, APPLE_WIDGET_BODY, {
          sandbox,
        });
        invalidTokens.push(...results.filter(apnsTokenGone).map((r) => r.token));
      } catch {
        // Apple out of reach: the widgets refresh on their own schedule anyway.
      }
    }
    return { invalidTokens };
  }
}

/**
 * How this server sends widget refresh pushes: Apple tokens with its own Apple key, else through
 * Casama Cloud's relay when the server sends its notifications that way, else not at all (said
 * once); Android tokens with the server's push sender (its own Firebase key or the relay).
 */
export function widgetPushSender(o: {
  push: PushSender;
  apple?: ApnsWidgetSender | null;
  /** Told once when Apple tokens are skipped for want of a key. */
  onNoApple?: () => void;
}): WidgetPushSender {
  const relay =
    typeof (o.push as Partial<WidgetPushSender>).sendWidgets === "function"
      ? (o.push as unknown as WidgetPushSender)
      : null;
  let told = false;
  return {
    async sendWidgets(targets, opts) {
      const invalid: string[] = [];
      const viaRelay: WidgetPushTarget[] = [];
      const apple = targets.filter((t) => t.kind === "apns_widgets");
      const android = targets.filter((t) => t.kind === "fcm");
      if (apple.length) {
        if (o.apple) invalid.push(...(await o.apple.send(apple, opts)).invalidTokens);
        else if (relay) viaRelay.push(...apple);
        else if (!told) {
          told = true;
          o.onNoApple?.();
        }
      }
      if (android.length) {
        if (relay) viaRelay.push(...android);
        else if (o.push.sendGlance)
          invalid.push(
            ...(
              await o.push.sendGlance(android.map((t) => t.token)).catch(() => ({
                invalidTokens: [] as string[],
              }))
            ).invalidTokens,
          );
      }
      if (viaRelay.length && relay)
        invalid.push(...(await relay.sendWidgets(viaRelay, opts)).invalidTokens);
      return { invalidTokens: invalid };
    },
  };
}

/** Records widget pushes (tests). */
export class RecordingWidgetPushSender implements WidgetPushSender {
  readonly sent: Array<{ targets: WidgetPushTarget[]; urgent: boolean; at: number }> = [];
  invalid: string[] = [];
  async sendWidgets(targets: WidgetPushTarget[], o: { urgent: boolean }) {
    this.sent.push({ targets, urgent: o.urgent, at: Date.now() });
    return { invalidTokens: targets.map((t) => t.token).filter((t) => this.invalid.includes(t)) };
  }
}

/** Inbox kinds that wait on the person: their widgets hear at once. */
export const GLANCE_URGENT_KINDS = new Set(["approval_request", "takeover", "suggestion"]);

/** Run events that change a Needs you row: at once. */
const URGENT_EVENTS = new Set([
  "approval.requested",
  "approval.resolved",
  "takeover.requested",
  "takeover.resolved",
]);
/** Run events that change a bot's state or what it finished: gathered. */
const BATCH_EVENTS = new Set(["run.started", "run.completed", "run.failed", "run.cancelled"]);
/** Bot tools that change routines (Up next): gathered, once the tool has finished. */
const ROUTINE_TOOLS = /^routines[._](create|update|delete|pause|resume|enable|disable)/;

export interface GlancePusherOptions {
  /** At most one gathered push per person this often (ms). Default 5 minutes. */
  batchEveryMs?: number;
  /** Urgent changes wait this long so a burst becomes one push (ms). Default 500. */
  urgentDelayMs?: number;
  now?: () => number;
  onError?: (error: Error) => void;
}

interface PersonState {
  lastSentAt: number;
  urgent?: ReturnType<typeof setTimeout>;
  batch?: ReturnType<typeof setTimeout>;
}

export class GlancePusher {
  private readonly db: Database;
  private readonly sender: WidgetPushSender;
  private readonly o: Required<Omit<GlancePusherOptions, "onError">> & {
    onError?: (e: Error) => void;
  };
  private readonly people = new Map<string, PersonState>();
  private readonly inFlight = new Set<Promise<void>>();
  /** Routine tool calls started, by call id, until they finish. */
  private readonly routineCalls = new Map<string, number>();
  private stopped = false;

  constructor(db: Database, sender: WidgetPushSender, o: GlancePusherOptions = {}) {
    this.db = db;
    this.sender = sender;
    this.o = {
      batchEveryMs: o.batchEveryMs ?? 5 * 60_000,
      urgentDelayMs: o.urgentDelayMs ?? 500,
      now: o.now ?? Date.now,
      onError: o.onError,
    };
  }

  /** Something this person's widgets show changed. Never throws. */
  changed(userId: string | null | undefined, o: { urgent: boolean }) {
    if (!userId || this.stopped) return;
    let p = this.people.get(userId);
    if (!p) {
      if (this.people.size > 20_000) this.people.clear();
      p = { lastSentAt: 0 };
      this.people.set(userId, p);
    }
    const state = p;
    if (o.urgent) {
      if (state.urgent) return;
      state.urgent = setTimeout(() => this.fire(userId, true), this.o.urgentDelayMs);
      state.urgent.unref?.();
      return;
    }
    // An urgent push on its way covers this too; so does a gathered one already waiting.
    if (state.urgent || state.batch) return;
    const wait = Math.max(0, state.lastSentAt + this.o.batchEveryMs - this.o.now());
    state.batch = setTimeout(() => this.fire(userId, false), wait);
    state.batch.unref?.();
  }

  /** The same, for several people (a run's starter and its bot's owner). */
  changedMany(userIds: Array<string | null | undefined>, o: { urgent: boolean }) {
    for (const u of new Set(userIds)) this.changed(u, o);
  }

  /** An inbox row was added for this person (NotificationService.onNotify). */
  notified = (userId: string, kind: string) => {
    this.changed(userId, { urgent: GLANCE_URGENT_KINDS.has(kind) });
  };

  /** A run event happened (EventBus.observe). Never throws or blocks. */
  observe = (runId: string, type: string, payload: Record<string, unknown>) => {
    if (this.stopped) return;
    let urgent: boolean;
    if (URGENT_EVENTS.has(type)) urgent = true;
    else if (BATCH_EVENTS.has(type)) urgent = false;
    else if (type === "tool.started") {
      if (!ROUTINE_TOOLS.test(String(payload.tool ?? ""))) return;
      if (this.routineCalls.size > 5000) this.routineCalls.clear();
      this.routineCalls.set(String(payload.call_id ?? ""), this.o.now());
      return;
    } else if (type === "tool.completed") {
      if (!this.routineCalls.delete(String(payload.call_id ?? ""))) return;
      urgent = false;
    } else return;
    this.track(
      (async () => {
        // Only people with a widget that can hear: one small read, and nothing for everyone else.
        const rows = await this.db.execute<{ user_id: string }>(sql`
          select distinct k.user_id from public.runs r
          join public.bots b on b.id = r.bot_id
          join public.widget_keys k on k.push_token is not null and k.org_id = r.org_id
            and k.user_id in (r.created_by, b.created_by)
          where r.id = ${runId}::uuid`);
        for (const r of rows) this.changed(r.user_id, { urgent });
      })(),
    );
  };

  private fire(userId: string, urgent: boolean) {
    const p = this.people.get(userId);
    if (p) {
      if (p.urgent) clearTimeout(p.urgent);
      if (p.batch) clearTimeout(p.batch);
      p.urgent = undefined;
      p.batch = undefined;
      p.lastSentAt = this.o.now();
    }
    this.track(this.send(userId, urgent));
  }

  /** Sends now to every widget of this person's that has a push token. */
  async send(userId: string, urgent: boolean) {
    const rows = await this.db.execute<{
      push_token: string;
      push_kind: "apns_widgets" | "fcm";
      push_sandbox: boolean | null;
    }>(sql`
      select distinct push_token, push_kind, push_sandbox from public.widget_keys
      where user_id = ${userId}::uuid and push_token is not null and push_kind is not null`);
    if (!rows.length) return;
    const { invalidTokens } = await this.sender.sendWidgets(
      rows.map((r) => ({
        token: r.push_token,
        kind: r.push_kind,
        sandbox: r.push_sandbox === true,
      })),
      { urgent },
    );
    // The key still reads the glance; only the token is gone.
    if (invalidTokens.length)
      await this.db.execute(sql`
        update public.widget_keys set push_token = null, push_kind = null, push_sandbox = null
        where push_token in (${sql.join(
          invalidTokens.map((t) => sql`${t}`),
          sql`, `,
        )})`);
  }

  private track(work: Promise<void>) {
    const p = work.catch((e: Error) => this.o.onError?.(e));
    this.inFlight.add(p);
    void p.finally(() => this.inFlight.delete(p));
  }

  /** Whether anything is waiting to go for this person (tests). */
  pending(userId: string) {
    const p = this.people.get(userId);
    return { urgent: !!p?.urgent, batch: !!p?.batch };
  }

  /** Waits for every push in flight, not for waiting timers (tests and shutdown). */
  async idle() {
    while (this.inFlight.size) await Promise.all([...this.inFlight]);
  }

  /** Drops every waiting push and hears nothing more. */
  stop() {
    this.stopped = true;
    for (const p of this.people.values()) {
      if (p.urgent) clearTimeout(p.urgent);
      if (p.batch) clearTimeout(p.batch);
    }
    this.people.clear();
  }
}
