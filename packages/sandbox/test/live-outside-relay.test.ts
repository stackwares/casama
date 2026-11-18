import { type ChildProcess, spawn } from "node:child_process";
import { randomUUID } from "node:crypto";
import { existsSync, mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { WebSocket } from "ws";
import { dockerAvailable, type SandboxStack, startSandboxStack } from "../src/testing.ts";
import { connectLive, type LiveClient } from "../src/testing-stream.ts";
import { type IceServer, turnCredentials, turnIceServer } from "../src/turn.ts";
import { collectExec, type SandboxHandle, type StreamRelay } from "../src/types.ts";

/**
 * Casama Link, live view away from the computer (D-296), against Cloudflare's real relay.
 *
 * The viewer away from home is Chrome, whose WebRTC is the same library the phone apps use, and
 * it may only use the relay outside. The bot's computer reaches that relay through the forwarder
 * in the stack's relay container, its only way there. Runs only with a real TURN key and Chrome:
 *
 *   CF_TURN_KEY_ID=… CF_TURN_API_TOKEN=… pnpm --filter @casama/sandbox vitest run test/live-outside-relay.test.ts
 *
 * (The werift test viewer can't be the one away: with Neko on the other side, relay to relay
 * through Cloudflare, it never connects, while Chrome connects every time. Seen 2026-11-14.)
 */
const keyId = process.env.CF_TURN_KEY_ID;
const apiToken = process.env.CF_TURN_API_TOKEN;
const chromePath =
  process.env.CHROME_PATH ?? "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
const enabled =
  !!keyId &&
  !!apiToken &&
  existsSync(chromePath) &&
  (await dockerAvailable()) &&
  process.env.SKIP_DOCKER_TESTS !== "1";

async function cloudflareRelay(): Promise<IceServer> {
  const res = await fetch(
    `https://rtc.live.cloudflare.com/v1/turn/keys/${keyId}/credentials/generate-ice-servers`,
    {
      method: "POST",
      headers: { authorization: `Bearer ${apiToken}`, "content-type": "application/json" },
      body: JSON.stringify({ ttl: 900 }),
    },
  );
  if (!res.ok) throw new Error(`the relay service answered ${res.status}`);
  const { iceServers } = (await res.json()) as { iceServers: IceServer[] };
  const turn = iceServers.find((s) => s.username && s.credential);
  if (!turn) throw new Error("no credentials");
  return turn;
}

/** Headless Chrome, driven over the DevTools protocol. */
class Chrome {
  private proc!: ChildProcess;
  private ws!: WebSocket;
  private dir = mkdtempSync(join(tmpdir(), "casama-chrome-"));
  private id = 0;
  private waiting = new Map<number, (v: unknown) => void>();
  private listeners: Array<(line: string) => void> = [];

  async start() {
    const port = 9300 + Math.floor(Math.random() * 600);
    this.proc = spawn(
      chromePath,
      [
        "--headless=new",
        `--remote-debugging-port=${port}`,
        `--user-data-dir=${this.dir}`,
        "--no-first-run",
        "--no-default-browser-check",
        "about:blank",
      ],
      { stdio: "ignore" },
    );
    let page: { webSocketDebuggerUrl: string } | undefined;
    for (let i = 0; i < 100 && !page; i++) {
      await new Promise((r) => setTimeout(r, 200));
      try {
        const targets = (await (
          await fetch(`http://127.0.0.1:${port}/json/list`)
        ).json()) as Array<{
          type: string;
          webSocketDebuggerUrl: string;
        }>;
        page = targets.find((t) => t.type === "page");
      } catch {
        // Not up yet.
      }
    }
    if (!page) throw new Error("Chrome didn't start");
    this.ws = new WebSocket(page.webSocketDebuggerUrl);
    await new Promise((r) => this.ws.once("open", r));
    this.ws.on("message", (raw) => {
      const m = JSON.parse(String(raw));
      if (m.id) this.waiting.get(m.id)?.(m);
      if (m.method === "Runtime.consoleAPICalled") {
        const line = m.params.args.map((a: { value?: unknown }) => String(a.value)).join(" ");
        for (const l of this.listeners) l(line);
      }
    });
    await this.call("Runtime.enable");
  }

  private call(method: string, params: Record<string, unknown> = {}) {
    return new Promise<{
      result?: { result?: { value?: unknown } };
      exceptionDetails?: unknown;
    }>((resolve) => {
      const n = ++this.id;
      this.waiting.set(n, resolve as (v: unknown) => void);
      this.ws.send(JSON.stringify({ id: n, method, params }));
    });
  }

  async evaluate(expression: string) {
    const r = (await this.call("Runtime.evaluate", {
      expression,
      awaitPromise: true,
      returnByValue: true,
    })) as { result?: { result?: { value?: unknown }; exceptionDetails?: { text?: string } } };
    if (r.result?.exceptionDetails) throw new Error(`page: ${r.result.exceptionDetails.text}`);
    return r.result?.result?.value;
  }

  onConsole(f: (line: string) => void) {
    this.listeners.push(f);
  }

  stop() {
    this.ws?.close();
    this.proc?.kill("SIGKILL");
    rmSync(this.dir, { recursive: true, force: true });
  }
}

/**
 * Chrome watches the computer through the relay outside only. The test carries Neko's signaling
 * between the stream's WebSocket (which needs the supervisor's header, so a page can't open it)
 * and the page. Resolves with the number of video packets received.
 */
async function watchFromAway(
  chrome: Chrome,
  url: string,
  headers: Record<string, string>,
  relay: IceServer,
) {
  const tab = `v${randomUUID().slice(0, 8)}`;
  const sig = new WebSocket(url, { headers });
  // Neko speaks first: hold its messages until the page is ready.
  const held: string[] = [];
  sig.on("message", (raw) => held.push(String(raw)));
  await new Promise((resolve, reject) => {
    sig.once("open", resolve);
    sig.once("error", reject);
  });
  chrome.onConsole((line) => {
    if (line.startsWith(`${tab} `)) sig.send(line.slice(tab.length + 1));
  });
  await chrome.evaluate(`(() => {
    const out = (m) => console.log(${JSON.stringify(tab)} + " " + JSON.stringify(m));
    const pc = new RTCPeerConnection({ iceServers: [${JSON.stringify(relay)}], iceTransportPolicy: "relay" });
    let answered = false;
    const early = [];
    pc.onicecandidate = (e) => {
      if (!e.candidate) return;
      const m = { event: "signal/candidate", payload: e.candidate.toJSON() };
      answered ? out(m) : early.push(m);
    };
    // Candidates can come before the offer; they wait for it, as in the app.
    const waitingCandidates = [];
    let queue = Promise.resolve();
    window[${JSON.stringify(tab)}] = { pc, handle: (msg) => (queue = queue.then(async () => {
      if (msg.event === "signal/provide") {
        await pc.setRemoteDescription({ type: "offer", sdp: msg.payload.sdp });
        for (const c of waitingCandidates.splice(0)) await pc.addIceCandidate(c).catch(() => {});
        const a = await pc.createAnswer();
        await pc.setLocalDescription(a);
        out({ event: "signal/answer", payload: { sdp: a.sdp } });
        answered = true;
        for (const m of early.splice(0)) out(m);
      } else if (msg.event === "signal/candidate") {
        if (pc.remoteDescription) await pc.addIceCandidate(msg.payload).catch(() => {});
        else waitingCandidates.push(msg.payload);
      }
    })) };
    return true;
  })()`);
  const onNeko = (raw: string) => {
    const msg = JSON.parse(raw) as { event: string };
    if (msg.event === "system/init")
      sig.send(JSON.stringify({ event: "signal/request", payload: { video: {}, audio: {} } }));
    if (msg.event === "signal/provide" || msg.event === "signal/candidate")
      void chrome.evaluate(`window[${JSON.stringify(tab)}].handle(${JSON.stringify(msg)}); true`);
  };
  sig.removeAllListeners("message");
  for (const m of held.splice(0)) onNeko(m);
  sig.on("message", (raw) => onNeko(String(raw)));

  const started = Date.now();
  let packets = 0;
  while (packets === 0 && Date.now() - started < 45_000) {
    await new Promise((r) => setTimeout(r, 1000));
    packets = Number(
      await chrome.evaluate(`(async () => {
        let n = 0;
        (await window[${JSON.stringify(tab)}].pc.getStats()).forEach((s) => {
          if (s.type === "inbound-rtp" && s.kind === "video") n = s.packetsReceived;
        });
        return n;
      })()`),
    );
  }
  return { packets, ms: Date.now() - started, close: () => sig.close() };
}

describe.skipIf(!enabled)("live view away from the computer, through Cloudflare's relay", () => {
  let stack: SandboxStack;
  let h: SandboxHandle;
  let outside: IceServer;
  const chrome = new Chrome();
  const ref = randomUUID();
  const clients: LiveClient[] = [];
  const closers: Array<() => void> = [];
  const relayFor = (s: IceServer, key: string): StreamRelay => ({
    urls: s.urls,
    username: s.username as string,
    credential: s.credential as string,
    key,
  });
  const nekoPid = async () => (await collectExec(h.exec("pgrep -x neko || true"))).stdout.trim();

  beforeAll(async () => {
    outside = await cloudflareRelay();
    await chrome.start();
    stack = await startSandboxStack({
      streamIdleStopMs: 1500,
      turnForwardTo: "turn.cloudflare.com:3478",
    });
    h = await stack.provider.create({ ref, profile: "desktop" });
  }, 240_000);
  afterAll(async () => {
    for (const c of closers) c();
    for (const c of clients) await c.close().catch(() => {});
    chrome.stop();
    await stack?.stop();
  }, 120_000);

  it("a viewer at home first: the streamer has only the server's own relay", async () => {
    const ep = await h.streamEndpoint({ mode: "view" });
    const home = await connectLive({
      url: ep.url,
      headers: ep.headers,
      iceServers: [
        turnIceServer(
          stack.turn.host,
          stack.turn.udpPort,
          turnCredentials(stack.turn.secret, "home", 300),
        ),
      ],
    });
    clients.push(home);
    await home.firstFrameMs;
    expect(home.videoPackets()).toBeGreaterThan(0);
    expect(await nekoPid()).not.toBe("");
  }, 120_000);

  it("a viewer away: the streamer starts again with the relay outside, and video comes through Cloudflare", async () => {
    const before = await nekoPid();
    const ep = await h.streamEndpoint({ mode: "view", relay: relayFor(outside, "key-1") });
    const away = await watchFromAway(chrome, ep.url, ep.headers, outside);
    closers.push(away.close);
    console.log(`through Cloudflare: video after ${away.ms} ms`);
    expect(away.packets).toBeGreaterThan(0);
    expect(await nekoPid()).not.toBe(before);
  }, 120_000);

  it("another viewer away with the same relay joins without restarting the streamer", async () => {
    const before = await nekoPid();
    const ep = await h.streamEndpoint({ mode: "view", relay: relayFor(outside, "key-1") });
    const second = await watchFromAway(chrome, ep.url, ep.headers, outside);
    closers.push(second.close);
    expect(second.packets).toBeGreaterThan(0);
    expect(await nekoPid()).toBe(before);
  }, 120_000);
});
