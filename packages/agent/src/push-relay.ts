/**
 * Push through Casama Cloud (D-296). The store apps can only be addressed with Casama's own
 * Firebase key, so a self-hosted server can't push to them itself (D-080). A server linked to
 * Casama Cloud hands its notifications to the cloud's relay, which sends them with that key.
 *
 * With private notifications on, the relay is given no text at all: the phone shows "New
 * activity" and the app loads what happened from the person's own server when it opens. The ids
 * that take the app to the right place still go along; they say nothing by themselves.
 *
 * Calls ring the same way: Android through Firebase, iPhones through Apple's call pushes, which
 * only Casama's own Apple key can send to the store app.
 */
import type { WidgetPushTarget } from "./glance-push.ts";
import type { LiveTarget, LiveUpdate } from "./live-runs.ts";
import type { PushMessage, PushSender } from "./notifications.ts";
import type { CallPayload, VoipSender } from "./phone-calls.ts";

export interface CloudRelayOptions {
  /** Whether to keep the text on this server (read each time, so the switch works at once). */
  private?: () => boolean | Promise<boolean>;
  fetch?: typeof fetch;
  onError?: (error: Error) => void;
}

export const PRIVATE_PUSH_TITLE = "Casama";
export const PRIVATE_PUSH_BODY = "New activity";

/** The same message with nothing to read in it. */
export function withoutText(message: PushMessage): PushMessage {
  return { ...message, title: PRIVATE_PUSH_TITLE, body: PRIVATE_PUSH_BODY };
}

/**
 * A run's live state with nothing to read in it (D-324): the phase and times stay ("working",
 * "needs you"); the bot's name and the step don't. The phone fills in its own words for the phase.
 */
export function liveWithoutText(update: LiveUpdate): LiveUpdate {
  return {
    ...update,
    bot_name: PRIVATE_PUSH_TITLE,
    // Shown as Casama: no bot's icon either.
    bot_avatar: null,
    state: { ...update.state, step: "", detail: null },
  };
}

/**
 * A call's ring with nothing to read in it: which bot calls and why stay on the server. The phone
 * rings as "Casama", and the app loads the rest when the call is answered.
 */
export function callWithoutText<T extends object>(call: T): T {
  return {
    ...call,
    ...("bot_name" in call ? { bot_name: PRIVATE_PUSH_TITLE } : {}),
    ...("reason" in call ? { reason: "" } : {}),
  };
}

export class CloudRelayPushSender implements PushSender {
  private readonly base: string;
  private readonly key: string;
  private readonly o: CloudRelayOptions;
  /**
   * The cloud said this key can't send this kind (or has no relay for it): stop asking until the
   * server restarts. Notifications and iPhone call rings are refused separately, since a cloud
   * can run one without the other.
   */
  private readonly refused = new Set<"push" | "voip" | "widget">();

  constructor(cloud: { url: string; key: string }, o: CloudRelayOptions = {}) {
    this.base = cloud.url.replace(/\/$/, "");
    this.key = cloud.key;
    this.o = o;
  }

  private async post(body: Record<string, unknown>, kind: "push" | "voip" | "widget" = "push") {
    if (this.refused.has(kind)) return { invalidTokens: [] };
    try {
      const res = await (this.o.fetch ?? fetch)(`${this.base}/link/v1/push`, {
        method: "POST",
        headers: { authorization: `Bearer ${this.key}`, "content-type": "application/json" },
        body: JSON.stringify(body),
        signal: AbortSignal.timeout(20_000),
      });
      if (res.status === 401 || res.status === 403 || res.status === 404) {
        this.refused.add(kind);
        this.o.onError?.(
          new Error(`Casama Cloud's push relay refused this server (${res.status})`),
        );
        return { invalidTokens: [] };
      }
      if (!res.ok) throw new Error(`Casama Cloud's push relay answered ${res.status}`);
      const json = (await res.json()) as { invalid_tokens?: string[] };
      return { invalidTokens: json.invalid_tokens ?? [] };
    } catch (e) {
      // A push that didn't go out is not worth failing the run for; the inbox row is there.
      this.o.onError?.(e as Error);
      return { invalidTokens: [] };
    }
  }

  async send(tokens: string[], message: PushMessage) {
    if (!tokens.length) return { invalidTokens: [] };
    const hide = (await this.o.private?.()) ?? false;
    return this.post({ tokens, message: hide ? withoutText(message) : message });
  }

  async sendCall(tokens: string[], data: Record<string, string>, ttlSeconds: number) {
    if (!tokens.length) return { invalidTokens: [] };
    const hide = (await this.o.private?.()) ?? false;
    return this.post({
      tokens,
      call: { data: hide ? callWithoutText(data) : data, ttl_seconds: ttlSeconds },
    });
  }

  /** A followed run's state for the phones that follow it (D-324). */
  async sendLive(targets: LiveTarget[], update: LiveUpdate) {
    if (!targets.length) return { invalidTokens: [] };
    const hide = (await this.o.private?.()) ?? false;
    return this.post({
      tokens: targets.map((t) => t.token),
      live: { targets, update: hide ? liveWithoutText(update) : update },
    });
  }

  /**
   * An iPhone's call ring (PushKit). Only Casama's own Apple key can ring the store app, so it
   * goes through the relay like everything else.
   */
  async sendVoip(tokens: string[], call: CallPayload) {
    if (!tokens.length) return { invalidTokens: [] };
    const hide = (await this.o.private?.()) ?? false;
    return this.post({ tokens, voip: { call: hide ? callWithoutText(call) : call } }, "voip");
  }

  /** This relay as the sender of iPhone call rings. */
  voip(): VoipSender {
    return { send: (tokens, call) => this.sendVoip(tokens, call) };
  }

  /**
   * Widget refresh pushes (D-405): only the tokens go, since the pushes carry nothing to read.
   * The cloud sends iPhone and Mac ones with Casama's Apple key and Android ones with Firebase.
   */
  async sendWidgets(targets: WidgetPushTarget[], o: { urgent: boolean }) {
    if (!targets.length) return { invalidTokens: [] };
    return this.post(
      { tokens: targets.map((t) => t.token), widget: { targets, urgent: o.urgent } },
      "widget",
    );
  }

  /** Android widgets only, through the same relay body. */
  async sendGlance(tokens: string[]) {
    return this.sendWidgets(
      tokens.map((token) => ({ token, kind: "fcm" as const, sandbox: false })),
      { urgent: false },
    );
  }
}
