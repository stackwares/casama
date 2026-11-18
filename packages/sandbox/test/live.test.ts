import { randomUUID } from "node:crypto";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { dockerAvailable, type SandboxStack, startSandboxStack } from "../src/testing.ts";
import { connectLive, type LiveClient } from "../src/testing-stream.ts";
import { turnCredentials, turnIceServer } from "../src/turn.ts";
import { collectExec, type SandboxHandle } from "../src/types.ts";

const enabled = (await dockerAvailable()) && process.env.SKIP_DOCKER_TESTS !== "1";

describe.skipIf(!enabled)("live view (Neko over TURN)", () => {
  let stack: SandboxStack;
  let h: SandboxHandle;
  const ref = randomUUID();
  const clients: LiveClient[] = [];
  const ice = () => {
    const creds = turnCredentials(stack.turn.secret, "test-user", 300);
    return [turnIceServer(stack.turn.host, stack.turn.udpPort, creds)];
  };
  const open = async (mode: "view" | "control") => {
    const ep = await h.streamEndpoint({ mode });
    const c = await connectLive({ url: ep.url, headers: ep.headers, iceServers: ice() });
    clients.push(c);
    return c;
  };

  beforeAll(async () => {
    stack = await startSandboxStack({ streamIdleStopMs: 1500 });
    h = await stack.provider.create({ ref, profile: "desktop" });
  }, 180_000);
  afterAll(async () => {
    for (const c of clients) await c.close().catch(() => {});
    await stack?.stop();
  }, 120_000);

  it("streams the desktop through the relay with low latency", async () => {
    const viewer = await open("view");
    const firstFrame = await viewer.firstFrameMs;
    const rtts: number[] = [];
    for (let i = 0; i < 5; i++) rtts.push(await viewer.ping());
    rtts.sort((a, b) => a - b);
    console.log(`first frame ${firstFrame} ms, data-channel RTT median ${rtts[2]?.toFixed(1)} ms`);
    expect(viewer.videoPackets()).toBeGreaterThan(0);
    expect(rtts[2]).toBeLessThan(500);
  }, 90_000);

  it("a viewer cannot take control; a controller can and moves the pointer", async () => {
    const viewer = clients[0] as LiveClient;
    viewer.send("control/request");
    await new Promise((r) => setTimeout(r, 1000));
    expect(viewer.events.some((e) => e.event === "control/host" && e.payload?.has_host)).toBe(
      false,
    );

    const controller = await open("control");
    await controller.firstFrameMs;
    controller.send("control/request");
    const host = await controller.waitFor("control/host");
    expect(host.payload?.has_host).toBe(true);
    await controller.ping(); // data channel is up
    controller.move(321, 234);
    await new Promise((r) => setTimeout(r, 500));
    const loc = await collectExec(h.exec("xdotool getmouselocation"));
    expect(loc.stdout).toContain("x:321 y:234");
  }, 90_000);

  it("stops the streamer after the last viewer leaves", async () => {
    for (const c of clients.splice(0)) await c.close();
    await new Promise((r) => setTimeout(r, 4000));
    const ps = await collectExec(h.exec("pgrep -x neko || echo none"));
    expect(ps.stdout.trim()).toBe("none");
  }, 30_000);
});
