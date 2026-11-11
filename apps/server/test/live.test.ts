import type { Server } from "node:http";
import type { AddressInfo } from "node:net";
import { fileURLToPath } from "node:url";
import { dockerAvailable, type SandboxStack, startSandboxStack } from "@casama/sandbox/testing";
import { connectLive, type LiveClient } from "@casama/sandbox/testing-stream";
import { serve } from "@hono/node-server";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { attachStream } from "../src/api/routes/live.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

const enabled = (await dockerAvailable()) && process.env.SKIP_DOCKER_TESTS !== "1";
const FIXTURES = fileURLToPath(new URL("./fixtures/live.json", import.meta.url));
const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

describe.skipIf(!enabled)("live computer (Phase 5 gate)", () => {
  let stack: SandboxStack;
  let h: Harness;
  let server: Server;
  let base: string;
  let owner: { id: string; token: string };
  let orgId: string;
  let botId: string;
  let computerId: string;
  const clients: LiveClient[] = [];

  const session = async (mode: "view" | "control") => {
    const res = await h.request(`/v1/computers/${computerId}/stream-session`, {
      method: "POST",
      token: owner.token,
      json: { mode },
    });
    expect(res.status).toBe(200);
    const s = await j(res);
    // The harness app answers on its own origin; point the signaling URL at the real server.
    const url = new URL(s.signaling_url);
    return { ...s, signaling_url: `${base.replace("http", "ws")}${url.pathname}${url.search}` };
  };
  const open = async (mode: "view" | "control") => {
    const s = await session(mode);
    const c = await connectLive({ url: s.signaling_url, iceServers: s.ice_servers });
    clients.push(c);
    return c;
  };
  const chat = async (text: string) => {
    const conv = await j(
      await h.request("/v1/conversations", {
        method: "POST",
        token: owner.token,
        json: { bot_id: botId },
      }),
    );
    const sent = await j(
      await h.request(`/v1/conversations/${conv.id}/messages`, {
        method: "POST",
        token: owner.token,
        json: { text },
      }),
    );
    return sent.run_id as string;
  };
  const run = async (id: string) => j(await h.request(`/v1/runs/${id}`, { token: owner.token }));
  const waitStatus = async (id: string, status: string, timeoutMs = 90_000) => {
    const until = Date.now() + timeoutMs;
    for (;;) {
      const r = await run(id);
      if (r.status === status) return r;
      if (Date.now() > until) throw new Error(`run ${id} is ${r.status}, wanted ${status}`);
      await sleep(250);
    }
  };
  const events = async (id: string) =>
    (await j(await h.request(`/v1/runs/${id}/events?limit=1000`, { token: owner.token })))
      .items as Array<{
      type: string;
      payload: Record<string, unknown>;
    }>;

  beforeAll(async () => {
    stack = await startSandboxStack({ streamIdleStopMs: 2000 });
    h = await startHarness({ worker: { fixtures: FIXTURES }, sandbox: stack });
    server = serve({ fetch: h.app.fetch, port: 0 }) as unknown as Server;
    await new Promise((r) => server.once("listening", r));
    attachStream(server, h.deps);
    base = `http://127.0.0.1:${(server.address() as AddressInfo).port}`;
    owner = await h.user("live-owner@example.com");
    orgId = (
      await j(
        await h.request("/v1/orgs", {
          method: "POST",
          token: owner.token,
          json: { name: "Live Org" },
        }),
      )
    ).id;
    const cred = await j(
      await h.request("/v1/credentials", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, provider: "openrouter", label: "k", api_key: "sk-live-test-key" },
      }),
    );
    botId = (
      await j(
        await h.request("/v1/bots", {
          method: "POST",
          token: owner.token,
          json: {
            org_id: orgId,
            name: "Ada",
            autonomy: "autonomous",
            model_policy: { primary: { credential_id: cred.id, model: "fixture-main" } },
          },
        }),
      )
    ).id;
    const list = await j(await h.request(`/v1/computers?org_id=${orgId}`, { token: owner.token }));
    computerId = list.items[0].id;
    const patched = await h.request(`/v1/computers/${computerId}`, {
      method: "PATCH",
      token: owner.token,
      json: { profile: "desktop", name: "Team desktop" },
    });
    expect((await j(patched)).profile).toBe("desktop");
  }, 240_000);

  afterAll(async () => {
    for (const c of clients) await c.close().catch(() => {});
    server?.close();
    await h?.stop();
    await stack?.stop();
  }, 180_000);

  it("streams live through the API and TURN relay with low latency; viewers cannot control", async () => {
    const viewer = await open("view");
    const firstFrame = await viewer.firstFrameMs;
    const rtts: number[] = [];
    for (let i = 0; i < 7; i++) rtts.push(await viewer.ping());
    rtts.sort((a, b) => a - b);
    console.log(`first frame ${firstFrame} ms; data-channel RTT median ${rtts[3]?.toFixed(1)} ms`);
    expect(rtts[3]).toBeLessThan(500);

    viewer.send("control/request");
    await sleep(800);
    expect(viewer.events.some((e) => e.event === "control/host" && e.payload?.has_host)).toBe(
      false,
    );
    // A control token without the lease cannot take control either.
    const sneaky = await open("control");
    await sneaky.firstFrameMs;
    sneaky.send("control/request");
    await sleep(800);
    expect(sneaky.events.some((e) => e.event === "control/host" && e.payload?.has_host)).toBe(
      false,
    );
    await sneaky.close();
  }, 120_000);

  it("take control mid-run pauses the bot; hand back with a note resumes it", async () => {
    const taken = await j(
      await h.request(`/v1/computers/${computerId}/lease`, {
        method: "POST",
        token: owner.token,
        json: {},
      }),
    );
    expect(taken).toMatchObject({ holder_type: "user", you: true });

    const runId = await chat("Please check the screen for me.");
    await waitStatus(runId, "waiting_takeover");

    const controller = await open("control");
    await controller.firstFrameMs;
    controller.send("control/request");
    expect((await controller.waitFor("control/host")).payload?.has_host).toBe(true);
    await controller.ping();
    controller.move(400, 300);
    await sleep(500);
    const handle = await h.computers?.ensureRunning(computerId);
    const { collectExec } = await import("@casama/sandbox");
    expect((await collectExec(handle!.exec("xdotool getmouselocation"))).stdout).toContain(
      "x:400 y:300",
    );

    const released = await j(
      await h.request(`/v1/computers/${computerId}/lease`, {
        method: "DELETE",
        token: owner.token,
        json: { note: "I closed the popup." },
      }),
    );
    expect(released.holder_type).toBe("bot");
    await waitStatus(runId, "completed");
    const evs = await events(runId);
    const leases = evs.filter((e) => e.type === "lease.changed").map((e) => e.payload.holder_type);
    expect(leases).toEqual(["user", "bot"]);
    const done = evs.find((e) => e.type === "tool.completed");
    expect(done).toBeTruthy();
    // The proxy took control away once the lease ended.
    await sleep(6000);
    expect(
      controller.events.filter((e) => e.event === "control/host").pop()?.payload?.has_host,
    ).toBe(false);
    await controller.close();
  }, 180_000);

  it("request_takeover waits for a person, notifies them and returns their note", async () => {
    const runId = await chat("Please sign in to the site for me.");
    await waitStatus(runId, "waiting_takeover");
    const open = await j(await h.request(`/v1/takeovers?org_id=${orgId}`, { token: owner.token }));
    expect(open.items).toHaveLength(1);
    expect(open.items[0].reason).toContain("sign in");
    const [note] = await h.handle.db.execute<{ payload: { link: string } }>(
      (await import("drizzle-orm"))
        .sql`select payload from public.notifications where kind = 'takeover'`,
    );
    expect(note?.payload.link).toContain(`/computer/live?c=${computerId}`);

    await h.request(`/v1/computers/${computerId}/lease`, {
      method: "POST",
      token: owner.token,
      json: {},
    });
    await h.request(`/v1/computers/${computerId}/lease`, {
      method: "DELETE",
      token: owner.token,
      json: { note: "Signed in as the team account." },
    });
    await waitStatus(runId, "completed");
    const evs = await events(runId);
    expect(evs.find((e) => e.type === "takeover.resolved")?.payload).toMatchObject({
      outcome: "completed",
      note: "Signed in as the team account.",
    });
  }, 120_000);

  it("a dismissed takeover lets the bot continue", async () => {
    const runId = await chat("Please sign in to the site again.");
    await waitStatus(runId, "waiting_takeover");
    const open = await j(await h.request(`/v1/takeovers?org_id=${orgId}`, { token: owner.token }));
    const res = await h.request(`/v1/takeovers/${open.items[0].id}/dismiss`, {
      method: "POST",
      token: owner.token,
      json: { note: "Not now." },
    });
    expect(res.status).toBe(200);
    await waitStatus(runId, "completed");
    const evs = await events(runId);
    expect(evs.find((e) => e.type === "takeover.resolved")?.payload.outcome).toBe("dismissed");
  }, 120_000);

  it("a bot completes a task in a Linux desktop app (Mousepad)", async () => {
    const runId = await chat("Please write a note in Mousepad.");
    const final = await waitStatus(runId, "completed", 120_000);
    expect(final.status).toBe("completed");
    const file = await h.request(
      `/v1/computers/${computerId}/files?path=${encodeURIComponent("note.txt")}`,
      { token: owner.token },
    );
    expect(file.status).toBe(200);
    expect((await file.text()).trim()).toBe("Hello from Casama");
  }, 180_000);
});
