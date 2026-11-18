/**
 * A small Supabase Realtime client (Phoenix protocol, vsn 1.0.0) for one private channel: the
 * person's own `user:<id>` topic, where the server announces device requests (D-149) the moment a
 * bot or one of their devices asks. The app listens on the same topic (client/lib/core).
 *
 * Only what's needed: join with the access token, heartbeats every 20 s (which also keep Chrome's
 * service worker awake while a browser kind is on), a fresh token when it changes, and reconnects
 * with backoff. Messages other than broadcasts are ignored.
 */

export interface RealtimeOptions {
  /** The server's Auth address (Supabase), e.g. https://auth.casama.ai. */
  authUrl: string;
  anonKey: string;
  topic: string;
  /** A current access token, or null when signed out. */
  token: () => Promise<string | null>;
  /** A broadcast arrived: its event name and payload. */
  onBroadcast: (event: string, payload: Record<string, unknown>) => void;
  /** Joined (true) or lost (false). */
  onStatus?: (joined: boolean) => void;
  /** For tests. */
  WebSocketImpl?: typeof WebSocket;
  heartbeatMs?: number;
}

export function realtimeUrl(authUrl: string, anonKey: string) {
  const u = new URL("realtime/v1/websocket", authUrl.endsWith("/") ? authUrl : `${authUrl}/`);
  u.protocol = u.protocol === "https:" ? "wss:" : "ws:";
  u.searchParams.set("apikey", anonKey);
  u.searchParams.set("vsn", "1.0.0");
  return u.toString();
}

export class Realtime {
  private ws: WebSocket | null = null;
  private ref = 0;
  private beat?: ReturnType<typeof setInterval>;
  private retry?: ReturnType<typeof setTimeout>;
  private backoff = 1000;
  private closed = false;
  private lastToken: string | null = null;
  joined = false;

  private readonly o: RealtimeOptions;

  constructor(o: RealtimeOptions) {
    this.o = o;
  }

  private send(
    event: string,
    payload: Record<string, unknown>,
    topic = `realtime:${this.o.topic}`,
  ) {
    if (this.ws?.readyState !== 1) return;
    this.ws.send(JSON.stringify({ topic, event, payload, ref: String(++this.ref) }));
  }

  async start() {
    this.closed = false;
    clearTimeout(this.retry);
    // Offline or signed out for now: try again later rather than stop for good.
    const token = await this.o.token().catch(() => null);
    if (this.closed) return;
    if (!token) {
      this.retry = setTimeout(() => void this.start(), this.backoff);
      this.backoff = Math.min(this.backoff * 2, 30_000);
      return;
    }
    this.lastToken = token;
    const Impl = this.o.WebSocketImpl ?? WebSocket;
    const ws = new Impl(realtimeUrl(this.o.authUrl, this.o.anonKey));
    this.ws = ws;
    ws.onopen = () => {
      this.send("phx_join", {
        config: {
          broadcast: { ack: false, self: false },
          presence: { key: "" },
          postgres_changes: [],
          private: true,
        },
        access_token: token,
      });
      clearInterval(this.beat);
      this.beat = setInterval(() => void this.heartbeat(), this.o.heartbeatMs ?? 20_000);
    };
    ws.onmessage = (ev) => {
      let m: { event?: string; payload?: Record<string, unknown>; topic?: string };
      try {
        m = JSON.parse(String(ev.data));
      } catch {
        return;
      }
      if (m.topic !== `realtime:${this.o.topic}`) return;
      if (m.event === "phx_reply" && (m.payload as { status?: string })?.status === "ok") {
        if (!this.joined) {
          this.joined = true;
          this.backoff = 1000;
          this.o.onStatus?.(true);
        }
        return;
      }
      if (m.event === "phx_error" || m.event === "phx_close") {
        ws.close();
        return;
      }
      if (m.event === "broadcast") {
        const b = m.payload as { event?: string; payload?: Record<string, unknown> };
        if (b?.event) this.o.onBroadcast(b.event, b.payload ?? {});
      }
    };
    ws.onclose = () => {
      if (this.ws !== ws) return;
      this.ws = null;
      clearInterval(this.beat);
      if (this.joined) this.o.onStatus?.(false);
      this.joined = false;
      if (this.closed) return;
      this.retry = setTimeout(() => void this.start(), this.backoff);
      this.backoff = Math.min(this.backoff * 2, 30_000);
    };
    ws.onerror = () => {};
  }

  /** A heartbeat; a new access token (they last an hour) goes to the channel too. */
  private async heartbeat() {
    this.send("heartbeat", {}, "phoenix");
    const token = await this.o.token().catch(() => null);
    if (token && token !== this.lastToken) {
      this.lastToken = token;
      this.send("access_token", { access_token: token });
    }
  }

  stop() {
    this.closed = true;
    clearTimeout(this.retry);
    clearInterval(this.beat);
    const ws = this.ws;
    this.ws = null;
    if (this.joined) this.o.onStatus?.(false);
    this.joined = false;
    ws?.close();
  }
}
