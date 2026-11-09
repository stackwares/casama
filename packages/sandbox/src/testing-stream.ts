/**
 * A live-view client for tests: speaks the Neko signaling protocol (D-054) over a WebSocket and
 * receives the stream with werift (a pure TypeScript WebRTC stack), relayed through TURN only.
 * Mirrors what the Flutter app does with flutter_webrtc.
 */
import { RTCPeerConnection } from "werift";
import { WebSocket } from "ws";
import type { IceServer } from "./turn.ts";

type Message = { event: string; payload?: Record<string, unknown> };

export interface LiveClient {
  /** Every signaling event received, in order. */
  events: Message[];
  /** Resolves when the first video RTP packet arrives; the value is ms since connect(). */
  firstFrameMs: Promise<number>;
  videoPackets(): number;
  send(event: string, payload?: Record<string, unknown>): void;
  waitFor(event: string, timeoutMs?: number): Promise<Message>;
  /** Round trip over the data channel (Neko ping/pong), in ms. */
  ping(): Promise<number>;
  /** Moves the remote pointer (only works while this session is the host). */
  move(x: number, y: number): void;
  close(): Promise<void>;
}

const OP_MOVE = 0x01;
const OP_PING = 0x07;
const OP_PONG = 0x03;

export async function connectLive(opts: {
  url: string;
  headers?: Record<string, string>;
  iceServers: IceServer[];
  timeoutMs?: number;
}): Promise<LiveClient> {
  const started = Date.now();
  const ws = new WebSocket(opts.url, { headers: opts.headers });
  const events: Message[] = [];
  const waiters: Array<{ event: string; resolve: (m: Message) => void }> = [];
  await new Promise<void>((resolve, reject) => {
    ws.once("open", () => resolve());
    ws.once("error", reject);
    ws.once("unexpected-response", (_req, res) =>
      reject(new Error(`signaling refused: ${res.statusCode}`)),
    );
  });
  const send = (event: string, payload?: Record<string, unknown>) =>
    ws.send(JSON.stringify(payload ? { event, payload } : { event }));

  const pc = new RTCPeerConnection({
    iceServers: opts.iceServers.flatMap((s) =>
      s.urls
        .filter((u) => u.startsWith("turn:") && u.includes("transport=udp"))
        .map((urls) => ({
          urls: urls.replace("?transport=udp", ""),
          username: s.username,
          credential: s.credential,
        })),
    ),
    iceTransportPolicy: "relay",
  });
  let packets = 0;
  let resolveFrame: (ms: number) => void = () => {};
  const firstFrameMs = new Promise<number>((r) => {
    resolveFrame = r;
  });
  pc.onTrack.subscribe((track) => {
    if (track.kind !== "video") return;
    track.onReceiveRtp.subscribe(() => {
      packets++;
      if (packets === 1) resolveFrame(Date.now() - started);
    });
  });
  let channel: { send(d: Buffer): void } | undefined;
  const pongs: Array<(ms: number) => void> = [];
  const channelReady = new Promise<void>((resolve) => {
    pc.onDataChannel.subscribe((dc) => {
      channel = dc;
      dc.onMessage.subscribe((data) => {
        if (typeof data === "string" || data.length < 3) return;
        if (data.readUInt8(0) === OP_PONG) pongs.shift()?.(0);
      });
      resolve();
    });
  });
  pc.onIceCandidate.subscribe((c) => {
    if (c) send("signal/candidate", c.toJSON() as unknown as Record<string, unknown>);
  });

  ws.on("message", async (raw) => {
    const msg = JSON.parse(String(raw)) as Message;
    events.push(msg);
    for (let i = waiters.length - 1; i >= 0; i--) {
      if (waiters[i]?.event === msg.event) waiters.splice(i, 1)[0]?.resolve(msg);
    }
    if (msg.event === "signal/provide") {
      await pc.setRemoteDescription({ type: "offer", sdp: String(msg.payload?.sdp) });
      const answer = await pc.createAnswer();
      await pc.setLocalDescription(answer);
      send("signal/answer", { sdp: pc.localDescription?.sdp ?? answer.sdp });
    } else if (msg.event === "signal/candidate" && msg.payload) {
      await pc.addIceCandidate(msg.payload as never).catch(() => {});
    }
  });

  const waitFor = (event: string, timeoutMs = opts.timeoutMs ?? 30_000) => {
    const seen = events.find((e) => e.event === event);
    if (seen) return Promise.resolve(seen);
    return new Promise<Message>((resolve, reject) => {
      const t = setTimeout(
        () =>
          reject(
            new Error(
              `timed out waiting for ${event}; got ${events.map((e) => e.event).join(", ")}`,
            ),
          ),
        timeoutMs,
      );
      waiters.push({
        event,
        resolve: (m) => {
          clearTimeout(t);
          resolve(m);
        },
      });
    });
  };

  await waitFor("system/init");
  send("signal/request", { video: {}, audio: {} });

  return {
    events,
    firstFrameMs,
    videoPackets: () => packets,
    send,
    waitFor,
    async ping() {
      await channelReady;
      const buf = Buffer.alloc(3 + 8);
      buf.writeUInt8(OP_PING, 0);
      buf.writeUInt16BE(8, 1);
      const now = Date.now();
      buf.writeUInt32BE(Math.floor(now / 0xffffffff), 3);
      buf.writeUInt32BE(now % 0xffffffff, 7);
      const t0 = performance.now();
      await new Promise<number>((resolve, reject) => {
        const t = setTimeout(() => reject(new Error("no pong")), 5000);
        pongs.push((v) => {
          clearTimeout(t);
          resolve(v);
        });
        channel?.send(buf);
      });
      return performance.now() - t0;
    },
    move(x, y) {
      const buf = Buffer.alloc(3 + 4);
      buf.writeUInt8(OP_MOVE, 0);
      buf.writeUInt16BE(4, 1);
      buf.writeUInt16BE(x, 3);
      buf.writeUInt16BE(y, 5);
      channel?.send(buf);
    },
    async close() {
      ws.close();
      await pc.close();
    },
  };
}
