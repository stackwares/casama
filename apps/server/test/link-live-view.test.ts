import { sql } from "drizzle-orm";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { attachStream, signStreamToken } from "../src/api/routes/live.ts";
import { CloudflareTurn, type TurnProvider } from "../src/link/turn.ts";
import { OutsideRelay, OutsideRelayError } from "../src/services/outside-relay.ts";
import { type FakeCloudflare, startFakeCloudflare } from "./fake-cloudflare.ts";
import { proxyServer, settle } from "./fake-upstream.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

/**
 * Casama Link, live view away from the computer (D-296). A phone that came in through the
 * server's address can't reach the server's own relay, so Casama Cloud hands out credentials for
 * one outside (Cloudflare's TURN service, a fake here), on plans that include it. The server
 * gives them to the phone and to the bot's computer.
 */

const UPSTREAM = "turn.cloudflare.com:3478";

/** A relay provider that counts what it was asked for. */
function fakeTurn() {
  const asked: number[] = [];
  let failing = false;
  const provider: TurnProvider = {
    upstream: UPSTREAM,
    generate: async (ttl) => {
      if (failing) throw new Error("down");
      asked.push(ttl);
      return {
        urls: ["turn:turn.cloudflare.com:3478?transport=udp", "turns:turn.cloudflare.com:5349"],
        username: `user-${asked.length}`,
        credential: `secret-${asked.length}`,
      };
    },
  };
  return { provider, asked, fail: (on: boolean) => void (failing = on) };
}

describe("Casama Link: the relay for live view away from the computer (cloud side)", () => {
  let cf: FakeCloudflare;
  let h: Harness;
  let owner: { id: string; token: string };
  let orgId: string;
  let key: string;
  const turn = fakeTurn();
  const instance = "0f6a3c1e-7b1d-4c55-9a52-00000000a001";

  const connect = (path: string, init: { key?: string; json?: unknown } = {}) =>
    h.request(`/link/v1${path}`, {
      method: "POST",
      headers: init.key ? { authorization: `Bearer ${init.key}` } : undefined,
      json: init.json ?? {},
    });
  const setLiveView = (n: number) =>
    h.handle.db.execute(sql`
      update public.entitlements
      set limits = limits || ${JSON.stringify({ link_live_view: n })}::jsonb
      where org_id = ${orgId}::uuid`);

  beforeAll(async () => {
    cf = await startFakeCloudflare();
    h = await startHarness({
      env: { BILLING_ENABLED: "true", PUBLIC_APP_URL: "https://app.example.test", ...cf.env() },
      casamaLink: { turn: turn.provider },
    });
    owner = await h.user("relay-owner@example.com");
    orgId = (
      await j(
        await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "Home" } }),
      )
    ).id as string;
    const started = await j(
      await connect("/sign-in/start", {
        json: { instance_id: instance, instance_name: "Home Mac" },
      }),
    );
    await h.request(`/v1/orgs/${orgId}/link/sign-ins/approve`, {
      method: "POST",
      token: owner.token,
      json: { user_code: started.user_code },
    });
    key = (await j(await connect("/sign-in/poll", { json: { device_code: started.device_code } })))
      .key as string;
    const made = await h.request("/link/v1/remote", {
      method: "PUT",
      headers: { authorization: `Bearer ${key}` },
      json: { instance_id: instance },
    });
    expect(made.status).toBe(200);
  }, 60_000);
  afterAll(async () => {
    await h?.stop();
    await cf?.stop();
  });

  it("the Free plan doesn't have it, and the server is told so", async () => {
    const res = await connect("/turn-credentials", { key });
    expect(res.status).toBe(402);
    expect((await j(res)).code).toBe("plan_limit");
    expect(turn.asked).toHaveLength(0);
    const beat = await j(
      await connect("/remote/heartbeat", { key, json: { instance_id: instance } }),
    );
    expect(beat.live_view).toBe("plan");
  });

  it("a plan that has it gets credentials that last half a day", async () => {
    await setLiveView(1);
    const res = await connect("/turn-credentials", { key });
    expect(res.status).toBe(200);
    const body = await j(res);
    expect(body).toEqual({
      ice_servers: [
        {
          urls: ["turn:turn.cloudflare.com:3478?transport=udp", "turns:turn.cloudflare.com:5349"],
          username: "user-1",
          credential: "secret-1",
        },
      ],
      upstream: UPSTREAM,
      expires_in: 43_200,
    });
    expect(turn.asked).toEqual([43_200]);
    const beat = await j(
      await connect("/remote/heartbeat", { key, json: { instance_id: instance } }),
    );
    expect(beat.live_view).toBe("included");
  });

  it("holds to the asked life within limits, and refuses one that is too long", async () => {
    const short = await connect("/turn-credentials", { key, json: { ttl_seconds: 600 } });
    expect((await j(short)).expires_in).toBe(600);
    const long = await connect("/turn-credentials", { key, json: { ttl_seconds: 500_000 } });
    expect(long.status).toBe(400);
  });

  it("a key made for computers and models can't use the relay", async () => {
    const made = await j(
      await h.request(`/v1/orgs/${orgId}/link/keys`, {
        method: "POST",
        token: owner.token,
        json: { instance_name: "computers-only" },
      }),
    );
    const res = await connect("/turn-credentials", { key: made.key });
    expect(res.status).toBe(403);
    expect((await connect("/turn-credentials", {})).status).toBe(401);
  });

  it("a suspended workspace or server gets no relay, whatever its plan", async () => {
    const asked = turn.asked.length;
    await h.handle.db.execute(
      sql`update public.organizations set suspended_at = now() where id = ${orgId}::uuid`,
    );
    const res = await connect("/turn-credentials", { key });
    expect(res.status).toBe(403);
    expect((await j(res)).code).toBe("suspended");
    await h.handle.db.execute(
      sql`update public.organizations set suspended_at = null where id = ${orgId}::uuid`,
    );
    // The one server, taken down after a report.
    await h.handle.db.execute(sql`
      update public.link_servers set status = 'suspended'
      where org_id = ${orgId}::uuid and instance_id = ${instance}`);
    expect((await connect("/turn-credentials", { key })).status).toBe(403);
    await h.handle.db.execute(sql`
      update public.link_servers set status = 'active'
      where org_id = ${orgId}::uuid and instance_id = ${instance}`);
    expect(turn.asked).toHaveLength(asked);
    expect((await connect("/turn-credentials", { key })).status).toBe(200);
  });

  it("says so when the relay service is down, and counts a day's asks per key", async () => {
    turn.fail(true);
    const down = await connect("/turn-credentials", { key });
    expect(down.status).toBe(503);
    expect((await j(down)).code).toBe("relay_unavailable");
    turn.fail(false);
    // 24 a day for one key; some are used already.
    let last = 200;
    let given = 0;
    for (let i = 0; i < 30 && last === 200; i++) {
      const res = await connect("/turn-credentials", { key });
      last = res.status;
      if (last === 200) given++;
      else expect(Number(res.headers.get("retry-after"))).toBeGreaterThan(0);
    }
    expect(last).toBe(429);
    expect(given).toBeLessThan(24);
  });
});

describe("Cloudflare's relay service", () => {
  it("asks for credentials with the key's token and leaves out what phones can't use", async () => {
    const calls: Array<{ url: string; auth: string | null; body: unknown }> = [];
    const turn = new CloudflareTurn({
      keyId: "key-1",
      apiToken: "token-1",
      apiUrl: "https://rtc.example.test/v1/",
      fetch: (async (url: string, init: RequestInit) => {
        calls.push({
          url,
          auth: new Headers(init.headers).get("authorization"),
          body: JSON.parse(String(init.body)),
        });
        return Response.json(
          {
            iceServers: [
              { urls: ["stun:stun.cloudflare.com:3478", "stun:stun.cloudflare.com:53"] },
              {
                urls: [
                  "turn:turn.cloudflare.com:3478?transport=udp",
                  "turn:turn.cloudflare.com:53?transport=udp",
                  "turn:turn.cloudflare.com:3478?transport=tcp",
                  "turns:turn.cloudflare.com:5349?transport=tcp",
                ],
                username: "u",
                credential: "c",
              },
            ],
          },
          { status: 201 },
        );
      }) as typeof fetch,
    });
    expect(await turn.generate(7200)).toEqual({
      urls: [
        "turn:turn.cloudflare.com:3478?transport=udp",
        "turn:turn.cloudflare.com:3478?transport=tcp",
        "turns:turn.cloudflare.com:5349?transport=tcp",
      ],
      username: "u",
      credential: "c",
    });
    expect(calls).toEqual([
      {
        url: "https://rtc.example.test/v1/turn/keys/key-1/credentials/generate-ice-servers",
        auth: "Bearer token-1",
        body: { ttl: 7200 },
      },
    ]);
  });

  it("fails plainly when the service refuses or gives nothing to relay with", async () => {
    const answering = (res: Response) =>
      new CloudflareTurn({ keyId: "k", apiToken: "t", fetch: (async () => res) as typeof fetch });
    await expect(answering(new Response("no", { status: 403 })).generate(60)).rejects.toThrow(
      "403",
    );
    await expect(
      answering(Response.json({ iceServers: [{ urls: ["stun:x"] }] })).generate(60),
    ).rejects.toThrow("no credentials");
  });
});

describe("Casama Link: the server's relay for viewers away from it", () => {
  /** A Casama Cloud that answers the relay endpoint. */
  function cloud() {
    const state = { status: 200, upstream: UPSTREAM, calls: 0, down: false };
    const doFetch = (async (_url: string, init: RequestInit) => {
      state.calls++;
      if (state.down) throw new Error("offline");
      expect(new Headers(init.headers).get("authorization")).toBe("Bearer kcc_test");
      if (state.status === 402)
        return Response.json({ code: "plan_limit", message: "Plus and up" }, { status: 402 });
      if (state.status !== 200) return Response.json({ code: "x" }, { status: state.status });
      return Response.json({
        ice_servers: [
          {
            urls: ["turn:turn.cloudflare.com:3478?transport=udp"],
            username: `u${state.calls}`,
            credential: `c${state.calls}`,
          },
        ],
        upstream: state.upstream,
        expires_in: 43_200,
      });
    }) as typeof fetch;
    return { state, fetch: doFetch };
  }
  const HOUR = 3_600_000;
  const relay = (c: ReturnType<typeof cloud>, clock: { t: number }) =>
    new OutsideRelay({
      cloud: { url: "https://cloud.example.test/", key: "kcc_test" },
      upstream: UPSTREAM,
      fetch: c.fetch,
      now: () => clock.t,
    });

  it("asks once and reuses what it holds while that is good for hours", async () => {
    const c = cloud();
    const clock = { t: 1_000_000 };
    const r = relay(c, clock);
    expect(r.cached()).toBeNull();
    const first = await r.get();
    expect(first).toMatchObject({ username: "u1", credential: "c1" });
    expect(first.key).toMatch(/^[0-9a-f]{16}$/);
    expect(first.key).not.toContain("u1");
    clock.t += 5 * HOUR;
    expect(await r.get()).toBe(first);
    expect(r.cached()).toBe(first);
    expect(c.state.calls).toBe(1);
    // Under six hours left: a viewer gets new ones, and so does the streamer from then on.
    clock.t += 2 * HOUR;
    const second = await r.get();
    expect(second.username).toBe("u2");
    expect(second.key).not.toBe(first.key);
    expect(r.cached()).toBe(second);
    expect(c.state.calls).toBe(2);
  });

  it("two viewers at once share one ask", async () => {
    const c = cloud();
    const r = relay(c, { t: 0 });
    const [a, b] = await Promise.all([r.get(), r.get()]);
    expect(a).toBe(b);
    expect(c.state.calls).toBe(1);
  });

  it("a plan without it is an answer, remembered for a minute", async () => {
    const c = cloud();
    c.state.status = 402;
    const clock = { t: 0 };
    const r = relay(c, clock);
    const refused = await r.get().catch((e) => e);
    expect(refused).toBeInstanceOf(OutsideRelayError);
    expect(refused.problem).toBe("plan");
    await expect(r.get()).rejects.toMatchObject({ problem: "plan" });
    expect(c.state.calls).toBe(1);
    // The plan changed: after a minute the next viewer is asked for again.
    c.state.status = 200;
    clock.t += 61_000;
    expect((await r.get()).username).toBe("u2");
  });

  it("keeps using what it holds when Casama Cloud can't be reached", async () => {
    const c = cloud();
    const clock = { t: 0 };
    const r = relay(c, clock);
    const held = await r.get();
    clock.t += 8 * HOUR;
    c.state.down = true;
    expect(await r.get()).toBe(held);
    // Nothing held that still works: say it isn't available.
    clock.t += 4 * HOUR;
    await expect(r.get()).rejects.toMatchObject({ problem: "unavailable" });
    expect(r.cached()).toBeNull();
  });

  it("refuses credentials for a relay its computers aren't forwarded to", async () => {
    const c = cloud();
    c.state.upstream = "relay.elsewhere.example:3478";
    const warned: string[] = [];
    const r = new OutsideRelay({
      cloud: { url: "https://cloud.example.test", key: "kcc_test" },
      upstream: UPSTREAM,
      fetch: c.fetch,
      logger: { warn: (m) => void warned.push(m) },
    });
    await expect(r.get()).rejects.toMatchObject({ problem: "unavailable" });
    expect(warned).toHaveLength(1);
    expect(r.cached()).toBeNull();
  });
});

describe("Casama Link: live view on a server with remote access", () => {
  let h: Harness;
  let owner: { id: string; token: string };
  let computerId: string;
  const state = { status: 200, calls: 0 };
  const streams: Array<{ mode?: string; relay?: { key: string; username: string } }> = [];

  const start = (host?: string) =>
    h.request(`/v1/computers/${computerId}/stream-session`, {
      method: "POST",
      token: owner.token,
      headers: host ? { host } : undefined,
      json: { mode: "view" },
    });

  beforeAll(async () => {
    h = await startHarness({
      env: {
        CASAMA_REMOTE_ACCESS: "on",
        PUBLIC_API_URL: "https://ab12cd34ef56.link.example.test",
        CASAMA_LOCAL_URL: "http://localhost:8080",
      },
    });
    owner = await h.user("away-owner@example.com");
    const orgId = (
      await j(
        await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "Home" } }),
      )
    ).id as string;
    // Every workspace starts with a team computer; this one has a desktop.
    const [row] = await h.tdb.admin`
      update public.computers set profile = 'desktop'
      where org_id = ${orgId} and kind = 'team' returning id`;
    computerId = row?.id as string;
    const handle = {
      streamEndpoint: async (opts: (typeof streams)[number]) => {
        streams.push(opts);
        return { url: "ws://127.0.0.1:9", headers: {} };
      },
    };
    const deps = h.deps as unknown as Record<string, unknown>;
    deps.computers = { ensureRunning: async () => handle, touch: async () => {} };
    deps.live = {
      turnSecret: "turn-secret",
      turnHost: "127.0.0.1",
      turnPort: 3478,
      tokenSecret: "stream-secret",
    };
    deps.outsideRelay = new OutsideRelay({
      cloud: { url: "https://cloud.example.test", key: "kcc_test" },
      upstream: UPSTREAM,
      fetch: (async () => {
        state.calls++;
        if (state.status === 402)
          return Response.json({ code: "plan_limit", message: "no" }, { status: 402 });
        if (state.status !== 200) return Response.json({}, { status: state.status });
        return Response.json({
          ice_servers: [
            {
              urls: ["turn:turn.cloudflare.com:3478?transport=udp"],
              username: "outside-user",
              credential: "outside-secret",
            },
          ],
          upstream: UPSTREAM,
          expires_in: 43_200,
        });
      }) as typeof fetch,
    });
  }, 60_000);
  afterAll(async () => {
    await h?.stop();
  });

  it("the app on the server's own machine keeps to that machine and its relay", async () => {
    const res = await start("localhost:8080");
    expect(res.status).toBe(200);
    const s = await j(res);
    expect(s.signaling_url).toMatch(/^ws:\/\/localhost:8080\/v1\/computers\//);
    expect(s.screenshot_url).toMatch(/^http:\/\/localhost:8080\//);
    expect(s.ice_servers).toHaveLength(1);
    expect(s.ice_servers[0].urls[0]).toBe("turn:127.0.0.1:3478?transport=udp");
    // Nobody asked Casama Cloud: live view at home works with no internet.
    expect(state.calls).toBe(0);
  });

  it("a phone that came in through the address gets the relay outside", async () => {
    const res = await start("ab12cd34ef56.link.example.test");
    expect(res.status).toBe(200);
    const s = await j(res);
    expect(s.signaling_url).toMatch(/^wss:\/\/ab12cd34ef56\.link\.example\.test\/v1\//);
    expect(s.ice_servers).toEqual([
      {
        urls: ["turn:turn.cloudflare.com:3478?transport=udp"],
        username: "outside-user",
        credential: "outside-secret",
      },
    ]);
    expect(s.ice_transport_policy).toBe("relay");
    expect(state.calls).toBe(1);
  });

  it("the bot's computer is given the same relay when the stream opens", async () => {
    const proxy = await proxyServer((s) => attachStream(s, h.deps));
    try {
      const token = signStreamToken("stream-secret", {
        sub: owner.id,
        cid: computerId,
        mode: "view",
        exp: Date.now() + 60_000,
      });
      // The fake computer has no streamer to connect to; what it was asked for is the point.
      await proxy.connect(`/v1/computers/${computerId}/stream?token=${token}`).catch(() => {});
      await settle();
      expect(streams).toHaveLength(1);
      expect(streams[0]?.mode).toBe("view");
      expect(streams[0]?.relay).toMatchObject({
        username: "outside-user",
        credential: "outside-secret",
        urls: ["turn:turn.cloudflare.com:3478?transport=udp"],
      });
      expect(streams[0]?.relay?.key).toMatch(/^[0-9a-f]{16}$/);
    } finally {
      proxy.close();
    }
  });

  it("says why when the plan doesn't have it, before the computer is woken", async () => {
    // What is held is dropped once the plan says no.
    const deps = h.deps as unknown as { outsideRelay: OutsideRelay };
    const held = deps.outsideRelay;
    deps.outsideRelay = new OutsideRelay({
      cloud: { url: "https://cloud.example.test", key: "kcc_test" },
      upstream: UPSTREAM,
      fetch: (async () =>
        Response.json({ code: "plan_limit", message: "no" }, { status: 402 })) as typeof fetch,
    });
    try {
      const res = await start("ab12cd34ef56.link.example.test");
      expect(res.status).toBe(409);
      expect((await j(res)).code).toBe("live_view_needs_plan");
      // At home it is as it always was.
      expect((await start("127.0.0.1:8080")).status).toBe(200);
    } finally {
      deps.outsideRelay = held;
    }
  });
});
