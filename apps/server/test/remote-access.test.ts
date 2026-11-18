import { existsSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { sql } from "drizzle-orm";
import { afterAll, beforeAll, beforeEach, describe, expect, it } from "vitest";
import { supabaseUrlFor } from "../src/api/routes/system.ts";
import type { LinkServers } from "../src/link/servers.ts";
import { RemoteAccess, type RemoteAccessOptions } from "../src/services/remote-access.ts";
import { type FakeCloudflare, startFakeCloudflare } from "./fake-cloudflare.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

/**
 * Casama Link on the self-hosted server (D-296): it keeps the connector's secret in step with
 * Casama Cloud, takes it away when the address is gone, and says where things stop. The cloud is a
 * real harness with a fake Cloudflare; the connector and the outside world are stubs.
 */
describe("Casama Link: a self-hosted server keeps its address", () => {
  const CLOUD = "https://cloud.test";
  const instance = "5d2c9f10-aaaa-4bbb-8ccc-000000000001";
  let cf: FakeCloudflare;
  let cloud: Harness;
  let servers: LinkServers;
  let owner: { id: string; token: string };
  let orgId: string;
  let key: string;
  let address: string;
  let dir: string;
  let tokenFile: string;
  /** What the stubs answer: the connector's readiness, the address from outside, the cloud itself. */
  let world: { connector: "ready" | "blocked" | "missing"; outside: boolean; cloudUp: boolean };
  let clock: number;

  const linkKey = async () => {
    const started = await j(
      await cloud.request("/link/v1/sign-in/start", {
        method: "POST",
        json: { instance_id: instance, instance_name: "Home Mac" },
      }),
    );
    await cloud.request(`/v1/orgs/${orgId}/link/sign-ins/approve`, {
      method: "POST",
      token: owner.token,
      json: { user_code: started.user_code },
    });
    const polled = await j(
      await cloud.request("/link/v1/sign-in/poll", {
        method: "POST",
        json: { device_code: started.device_code },
      }),
    );
    return polled.key as string;
  };

  /** The network as this server sees it: Casama Cloud, its connector, and its own address. */
  const net: typeof fetch = async (input, init) => {
    const url = String(input);
    if (url.startsWith(CLOUD)) {
      if (!world.cloudUp) throw new Error("getaddrinfo ENOTFOUND cloud.test");
      return cloud.app.request(url.slice(CLOUD.length), init as RequestInit);
    }
    if (url === "http://connector:2000/ready") {
      if (world.connector === "missing") throw new Error("connect ECONNREFUSED");
      return world.connector === "ready"
        ? Response.json({ status: 200, readyConnections: 4 })
        : Response.json({ status: 503, readyConnections: 0 }, { status: 503 });
    }
    if (url === `${address}/readyz`)
      return world.outside ? Response.json({ status: "ok" }) : new Response("", { status: 530 });
    throw new Error(`unexpected request to ${url}`);
  };

  const server = (over: Partial<RemoteAccessOptions> = {}) =>
    new RemoteAccess({
      enabled: true,
      cloud: { url: CLOUD, key },
      instanceId: instance,
      publicUrl: address,
      pagesUrl: address.replace(".link.test", "-p.link.test"),
      localUrl: "http://localhost:8080",
      tokenFile,
      connectorUrl: "http://connector:2000",
      version: "0.1.0",
      fetch: net,
      now: () => clock,
      ...over,
    });
  const secret = () => (existsSync(tokenFile) ? readFileSync(tokenFile, "utf8") : null);
  const liveToken = () => `token-for-${cf.tunnelFor(new URL(address).host)?.id}`;

  beforeAll(async () => {
    cf = await startFakeCloudflare();
    cloud = await startHarness({ env: { BILLING_ENABLED: "true", ...cf.env() } });
    servers = cloud.deps.casamaLink?.servers as LinkServers;
    owner = await cloud.user("remote-owner@example.com");
    orgId = (
      await j(
        await cloud.request("/v1/orgs", {
          method: "POST",
          token: owner.token,
          json: { name: "Home" },
        }),
      )
    ).id;
    key = await linkKey();
    // What turning remote access on does first: ask for the address, then set the server up with it.
    address = (
      await j(
        await cloud.request("/link/v1/remote", {
          method: "PUT",
          headers: { authorization: `Bearer ${key}` },
          json: { instance_id: instance },
        }),
      )
    ).address;
    dir = mkdtempSync(join(tmpdir(), "casama-link-"));
    tokenFile = join(dir, "token");
  }, 60_000);
  afterAll(async () => {
    await cloud?.stop();
    await cf?.stop();
    if (dir) rmSync(dir, { recursive: true, force: true });
  });
  beforeEach(() => {
    world = { connector: "ready", outside: true, cloudUp: true };
    clock = Date.parse("2026-11-14T08:00:00Z");
    rmSync(tokenFile, { force: true });
    rmSync(`${tokenFile}.json`, { force: true });
  });

  it("turned off, it leaves no secret for the connector to run with", async () => {
    writeFileSync(tokenFile, "left-over");
    const ra = server({ enabled: false });
    await ra.start();
    expect(secret()).toBeNull();
    expect(ra.status()).toMatchObject({ state: "off", address: null, problem: null, linked: true });
    expect(await ra.check()).toMatchObject({ state: "off" });
  });

  it("turned on, it fetches the secret and comes online once the connector connects", async () => {
    const ra = server();
    await ra.start();
    ra.stop();
    expect(secret()).toBe(liveToken());
    // The connector needs a moment after its secret arrives.
    expect(ra.status()).toMatchObject({ state: "starting", address, problem: null });
    const checked = await ra.check();
    expect(checked).toMatchObject({
      state: "online",
      address,
      local_address: "http://localhost:8080",
      connections: 4,
      problem: null,
    });
    expect(checked.checked_at).toBe(new Date(clock).toISOString());
    // The cloud saw it check in.
    const [row] = await cloud.handle.db.execute<{ seen: boolean }>(sql`
      select last_seen_at is not null as seen from public.link_servers where instance_id = ${instance}`);
    expect(row?.seen).toBe(true);
  });

  it("without a link it says so", async () => {
    const ra = server({ cloud: undefined });
    await ra.start();
    ra.stop();
    expect(ra.status()).toMatchObject({
      state: "needs_attention",
      problem: "not_linked",
      linked: false,
    });
    expect(secret()).toBeNull();
  });

  it("losing touch with Casama Cloud doesn't take a working address down", async () => {
    const ra = server();
    await ra.start();
    ra.stop();
    await ra.check();
    world.cloudUp = false;
    const checked = await ra.check();
    expect(checked).toMatchObject({ state: "online", problem: "cloud_unreachable" });
    expect(secret()).toBe(liveToken());
    world.cloudUp = true;
    expect(await ra.check()).toMatchObject({ state: "online", problem: null });
  });

  it("says where it stops: a blocked network, a connector that isn't running, a silent address", async () => {
    const ra = server();
    await ra.start();
    ra.stop();
    clock += 3 * 60_000;
    world.connector = "blocked";
    expect(await ra.check()).toMatchObject({
      state: "offline",
      problem: "connector_blocked",
      connections: 0,
    });
    world.connector = "missing";
    expect(await ra.check()).toMatchObject({
      state: "offline",
      problem: "connector_missing",
      connections: null,
    });
    world.connector = "ready";
    world.outside = false;
    expect(await ra.check()).toMatchObject({ state: "offline", problem: "address_unanswered" });
  });

  it("gets a new secret when the cloud parked the tunnel, at the same address", async () => {
    const ra = server();
    await ra.start();
    ra.stop();
    const before = secret();
    await cloud.handle.db.execute(
      sql`update public.link_servers set last_seen_at = now() - interval '20 days' where instance_id = ${instance}`,
    );
    expect((await servers.sweep("on")).parked).toBe(1);
    expect(cf.live()).toHaveLength(0);

    await ra.checkIn();
    expect(secret()).toBe(liveToken());
    expect(secret()).not.toBe(before);
    expect(ra.status().problem).toBeNull();
  });

  it("repairs a tunnel that went missing while the cloud's record looked fine", async () => {
    const ra = server();
    await ra.start();
    ra.stop();
    await ra.check();
    const lost = cf.tunnelFor(new URL(address).host);
    if (lost) lost.deleted_at = new Date().toISOString();
    world.connector = "blocked";
    // The cloud still says ok, so a check-in alone changes nothing.
    await ra.checkIn();
    expect(secret()).toBe(`token-for-${lost?.id}`);

    await ra.watchConnector();
    expect(secret()).toBe(`token-for-${lost?.id}`);
    // Still disconnected five minutes on: ask for the tunnel again.
    clock += 6 * 60_000;
    await ra.watchConnector();
    expect(cf.tunnelFor(new URL(address).host)?.id).not.toBe(lost?.id);
    expect(secret()).toBe(liveToken());
  });

  it("turned off while this server still runs, it doesn't bring the address back", async () => {
    // `casama selfhost remote off` releases the address first, then restarts the stack, which can
    // take minutes; meanwhile the server still runs with remote access on. Found 2026-11-14
    // against the real Cloudflare: the repair asked for the address again and made a new tunnel.
    const ra = server();
    await ra.start();
    ra.stop();
    await ra.check();
    const released = await cloud.request(`/link/v1/remote?instance_id=${instance}`, {
      method: "DELETE",
      headers: { authorization: `Bearer ${key}` },
    });
    expect((await j(released)).released).toBe(true);
    expect(cf.live()).toHaveLength(0);
    world.connector = "blocked";
    await ra.watchConnector();
    clock += 6 * 60_000;
    await ra.watchConnector();
    expect(cf.live()).toHaveLength(0);
    expect(ra.status()).toMatchObject({ state: "needs_attention", problem: "removed" });
    // Turned on again later (the CLI or the app asks for the address): it comes back.
    await cloud.request("/link/v1/remote", {
      method: "PUT",
      headers: { authorization: `Bearer ${key}` },
      json: { instance_id: instance },
    });
    world.connector = "ready";
    await ra.checkIn();
    expect(secret()).toBe(liveToken());
  });

  it("an address set up differently from the one the cloud gives is refused, not half-run", async () => {
    const ra = server({ publicUrl: "https://somewhere-else.example" });
    await ra.start();
    ra.stop();
    expect(secret()).toBeNull();
    expect(ra.status()).toMatchObject({ state: "needs_attention", problem: "address_changed" });
  });

  it("a suspended address has its secret taken away, and gets it back when lifted", async () => {
    const ra = server();
    await ra.start();
    ra.stop();
    const [row] = await cloud.handle.db.execute<{ id: string }>(
      sql`select id from public.link_servers where instance_id = ${instance}`,
    );
    await servers.suspendServer(row?.id as string, "reported", owner.id);
    await ra.checkIn();
    expect(secret()).toBeNull();
    expect(ra.status()).toMatchObject({ state: "needs_attention", problem: "suspended" });

    await servers.unsuspendServer(row?.id as string, owner.id);
    await ra.checkIn();
    expect(secret()).toBe(liveToken());
    expect(ra.status().problem).toBeNull();
  });

  it("removed from the workspace, it stops and doesn't ask for the address back by itself", async () => {
    const ra = server();
    await ra.start();
    ra.stop();
    const [row] = await cloud.handle.db.execute<{ id: string }>(
      sql`select id from public.link_servers where instance_id = ${instance}`,
    );
    await servers.removeServer(orgId, row?.id as string, owner.id);
    await ra.checkIn();
    expect(secret()).toBeNull();
    expect(ra.status()).toMatchObject({ state: "needs_attention", problem: "removed" });
    await ra.checkIn();
    expect(cf.live()).toHaveLength(0);
    // Turning it on again (the app or the CLI asks for the address) brings it back.
    await cloud.request("/link/v1/remote", {
      method: "PUT",
      headers: { authorization: `Bearer ${key}` },
      json: { instance_id: instance },
    });
    await ra.checkIn();
    expect(secret()).toBe(liveToken());
  });

  it("a revoked key ends it", async () => {
    const ra = server();
    await ra.start();
    ra.stop();
    const keys = await j(
      await cloud.request(`/v1/orgs/${orgId}/link/keys`, { token: owner.token }),
    );
    await cloud.request(`/v1/orgs/${orgId}/link/keys/${keys.items[0].id}`, {
      method: "DELETE",
      token: owner.token,
    });
    await ra.checkIn();
    expect(secret()).toBeNull();
    expect(ra.status()).toMatchObject({ state: "needs_attention", problem: "key_rejected" });
  });
});

describe("Casama Link: the server's own status and local address", () => {
  let h: Harness;
  let owner: { token: string };
  let member: { token: string };
  beforeAll(async () => {
    h = await startHarness({
      env: {
        CASAMA_LOCAL_URL: "http://localhost:8080",
        PUBLIC_API_URL: "https://abc.link.test",
      },
    });
    owner = await h.user("status-owner@example.com");
    member = await h.user("status-member@example.com");
  }, 60_000);
  afterAll(() => h?.stop());

  it("only the instance owner sees the status; a server that never turned it on says off", async () => {
    expect((await h.request("/v1/admin/remote-access")).status).toBe(401);
    expect((await h.request("/v1/admin/remote-access", { token: member.token })).status).toBe(403);
    const res = await h.request("/v1/admin/remote-access", { token: owner.token });
    expect(await j(res)).toEqual({
      state: "off",
      address: null,
      pages_address: null,
      local_address: "http://localhost:8080",
      linked: false,
      problem: null,
      connections: null,
      checked_at: null,
      // No Firebase key of its own and no link to Casama Cloud: notifications stay in the inbox.
      push: "off",
      private_notifications: false,
      invites: false,
    });
    const checked = await h.request("/v1/admin/remote-access/check", {
      method: "POST",
      token: owner.token,
    });
    expect((await j(checked)).state).toBe("off");
  });

  it("the app on the server's own machine is pointed at the local address, everyone else at the public one", async () => {
    const config = async (host?: string) =>
      (await j(await h.request("/v1/config", { headers: host ? { host } : {} }))).supabase_url;
    expect(await config("localhost:8080")).toBe("http://localhost:8080");
    expect(await config("127.0.0.1:8080")).toBe("http://localhost:8080");
    expect(await config("abc.link.test")).toBe("http://127.0.0.1:54321");
    expect(await config()).toBe("http://127.0.0.1:54321");
    // Without a local address set, nothing changes for anyone.
    expect(supabaseUrlFor({ SUPABASE_URL: "https://x.example" }, "localhost:8080")).toBe(
      "https://x.example",
    );
    // A look-alike host is not this machine.
    expect(
      supabaseUrlFor(
        { SUPABASE_URL: "https://x.example", CASAMA_LOCAL_URL: "http://localhost:8080" },
        "localhost.evil.example",
      ),
    ).toBe("https://x.example");
  });
});
