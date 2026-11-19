/**
 * Apple's push service (APNs) over HTTP/2 with a token (.p8) key, as Apple's provider API
 * documents. Shared by iPhone call rings (PushKit, D-135), widget refresh pushes (D-405) and
 * alerts to Apple Watches' own tokens (D-410).
 */
import { createPrivateKey, createSign } from "node:crypto";
import { connect } from "node:http2";
import type { PushMessage } from "./notifications.ts";

export const APNS_PRODUCTION_URL = "https://api.push.apple.com";
export const APNS_SANDBOX_URL = "https://api.sandbox.push.apple.com";

export interface ApnsKey {
  keyP8: string;
  keyId: string;
  teamId: string;
  /** Production host; tests point it at a local server. Default: Apple's. */
  url?: string;
  /**
   * The development host, for tokens from debug builds. Default: Apple's sandbox, unless [url] is
   * set, in which case everything goes to [url] (a test server or a proxy).
   */
  sandboxUrl?: string;
}

export interface ApnsResult {
  token: string;
  code: number;
  body: string;
}

/** 410 Unregistered, and 400 only with BadDeviceToken, mean the token is gone (D-271). */
export function apnsTokenGone(r: { code: number; body: string }) {
  return r.code === 410 || (r.code === 400 && /BadDeviceToken/.test(r.body));
}

export class ApnsClient {
  private readonly o: ApnsKey & { url: string; sandboxUrl: string };
  private jwt: { value: string; at: number } | null = null;

  constructor(o: ApnsKey) {
    this.o = {
      ...o,
      url: o.url ?? APNS_PRODUCTION_URL,
      sandboxUrl: o.sandboxUrl ?? o.url ?? APNS_SANDBOX_URL,
    };
  }

  /** The provider token: ES256, refreshed every 40 minutes (Apple wants 20 to 60). */
  token() {
    if (this.jwt && Date.now() - this.jwt.at < 40 * 60_000) return this.jwt.value;
    const b64 = (x: object) => Buffer.from(JSON.stringify(x)).toString("base64url");
    const unsigned = `${b64({ alg: "ES256", kid: this.o.keyId })}.${b64({ iss: this.o.teamId, iat: Math.floor(Date.now() / 1000) })}`;
    const sig = createSign("SHA256")
      .update(unsigned)
      .sign({ key: createPrivateKey(this.o.keyP8), dsaEncoding: "ieee-p1363" }, "base64url");
    this.jwt = { value: `${unsigned}.${sig}`, at: Date.now() };
    return this.jwt.value;
  }

  /**
   * Sends one push per token over one connection, in order. [headers] is read for each token, so
   * a time in it (apns-expiration) is as fresh as the request. Rejects on a connection error.
   */
  async sendAll(
    tokens: string[],
    headers: (token: string) => Record<string, string>,
    body: string,
    o: { sandbox?: boolean } = {},
  ): Promise<ApnsResult[]> {
    const out: ApnsResult[] = [];
    if (!tokens.length) return out;
    const session = connect(o.sandbox ? this.o.sandboxUrl : this.o.url);
    // A connection that fails (Apple out of reach) fails the request waiting on it, instead of
    // surfacing as an uncaught 'error' on the session.
    let failWaiting: ((e: Error) => void) | null = null;
    let sessionError: Error | null = null;
    session.on("error", (e: Error) => {
      sessionError = e;
      failWaiting?.(e);
    });
    try {
      for (const t of tokens) {
        const status = await new Promise<{ code: number; body: string }>((resolve, reject) => {
          if (sessionError) return reject(sessionError);
          failWaiting = reject;
          const req = session.request({
            ":method": "POST",
            ":path": `/3/device/${t}`,
            authorization: `bearer ${this.token()}`,
            ...headers(t),
            "content-type": "application/json",
          });
          let code = 0;
          let text = "";
          req.on("response", (h) => {
            code = Number(h[":status"]);
          });
          req.on("data", (d: Buffer) => {
            text += d.toString();
          });
          req.on("end", () => resolve({ code, body: text }));
          req.on("error", reject);
          req.end(body);
        });
        out.push({ token: t, ...status });
      }
    } finally {
      session.close();
    }
    return out;
  }
}

/** Where a push to a watch's own token goes (D-410): Apple's token and its environment. */
export interface WatchPushTarget {
  token: string;
  sandbox: boolean;
}

/**
 * Sends alerts straight to Apple Watches' own tokens (D-410, docs/WATCH-PROTOCOL.md §4): with this
 * server's Apple key, or through Casama Cloud's relay (CloudRelayPushSender.sendWatch).
 */
export interface WatchAlertSender {
  sendWatch(targets: WatchPushTarget[], message: PushMessage): Promise<{ invalidTokens: string[] }>;
}

/** The watch app's bundle id, under the phone app's. */
export const watchAppTopic = (appBundleId = "ai.casama.app") => `${appBundleId}.watchkitapp`;

/**
 * An alert's body as Apple reads it: the same category, thread and data as the phone's copy, so the
 * watch app's notification layouts and buttons work on either.
 */
export function apnsAlertBody(message: PushMessage): string {
  return JSON.stringify({
    aps: {
      alert: { title: message.title, body: message.body },
      sound: "default",
      ...(message.category ? { category: message.category } : {}),
      ...(message.threadId ? { "thread-id": message.threadId } : {}),
      ...(message.interruption ? { "interruption-level": message.interruption } : {}),
    },
    ...message.data,
    ...(message.link ? { link: message.link } : {}),
    ...(message.tag ? { tag: message.tag } : {}),
  });
}

/**
 * Alerts to Apple Watch apps' own tokens (D-410, Phase 5), so a watch away from its phone hears
 * a request. Each carries the phone copy's `apns-collapse-id`, so a watch that gets both shows one.
 */
export class ApnsWatchSender implements WatchAlertSender {
  private readonly client: ApnsClient;
  private readonly topic: string;
  constructor(client: ApnsClient, o: { appBundleId?: string } = {}) {
    this.client = client;
    this.topic = watchAppTopic(o.appBundleId);
  }

  async sendWatch(targets: WatchPushTarget[], message: PushMessage) {
    const invalidTokens: string[] = [];
    const body = apnsAlertBody(message);
    const headers = () => ({
      "apns-topic": this.topic,
      "apns-push-type": "alert",
      "apns-priority": message.priority === "normal" ? "5" : "10",
      "apns-expiration": String(Math.floor(Date.now() / 1000) + 86_400),
      ...(message.tag && Buffer.byteLength(message.tag) <= 64
        ? { "apns-collapse-id": message.tag }
        : {}),
    });
    for (const sandbox of [false, true]) {
      const tokens = targets.filter((t) => t.sandbox === sandbox).map((t) => t.token);
      if (!tokens.length) continue;
      try {
        const results = await this.client.sendAll(tokens, headers, body, { sandbox });
        invalidTokens.push(...results.filter(apnsTokenGone).map((r) => r.token));
      } catch {
        // Apple out of reach: the phone's copy still mirrors to the watch.
      }
    }
    return { invalidTokens };
  }
}
