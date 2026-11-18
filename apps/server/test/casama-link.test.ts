import { sql } from "drizzle-orm";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import type { LinkServers } from "../src/link/servers.ts";
import { type FakeCloudflare, startFakeCloudflare } from "./fake-cloudflare.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

/**
 * Casama Link, cloud side (D-296): a self-hosted server is linked to a workspace by a code an
 * admin approves, gets a public address through a tunnel, and keeps that address through restarts,
 * parking, suspension and a tunnel that disappears. Cloudflare is the fake in fake-cloudflare.ts.
 */
describe("Casama Link: linking and addresses", () => {
  let cf: FakeCloudflare;
  let h: Harness;
  let servers: LinkServers;
  let owner: { id: string; token: string };
  let member: { id: string; token: string };
  let orgId: string;
  let key: string;
  const instance = "0f6a3c1e-7b1d-4c55-9a52-000000000001";

  const connect = (path: string, init: { method?: string; key?: string; json?: unknown } = {}) =>
    h.request(`/link/v1${path}`, {
      method: init.method ?? "GET",
      headers: init.key ? { authorization: `Bearer ${init.key}` } : undefined,
      json: init.json,
    });
  const makeOrg = async (token: string, name: string) =>
    (await j(await h.request("/v1/orgs", { method: "POST", token, json: { name } }))).id as string;
  /** The whole link: the server asks, an admin approves, the server collects its key. */
  const link = async (token: string, org: string, instanceId: string, name = "Home Mac") => {
    const started = await j(
      await connect("/sign-in/start", {
        method: "POST",
        json: { instance_id: instanceId, instance_name: name, platform: "macos", version: "0.1.0" },
      }),
    );
    const approved = await h.request(`/v1/orgs/${org}/link/sign-ins/approve`, {
      method: "POST",
      token,
      json: { user_code: started.user_code },
    });
    expect(approved.status).toBe(200);
    const polled = await j(
      await connect("/sign-in/poll", {
        method: "POST",
        json: { device_code: started.device_code },
      }),
    );
    expect(polled.status).toBe("approved");
    return polled.key as string;
  };

  beforeAll(async () => {
    cf = await startFakeCloudflare();
    h = await startHarness({
      env: { BILLING_ENABLED: "true", PUBLIC_APP_URL: "https://app.example.test", ...cf.env() },
    });
    servers = h.deps.casamaLink?.servers as LinkServers;
    owner = await h.user("link-owner@example.com");
    member = await h.user("link-member@example.com");
    orgId = await makeOrg(owner.token, "Home");
  }, 60_000);
  afterAll(async () => {
    await h?.stop();
    await cf?.stop();
  });

  it("links a server with a code an admin approves, and hands out the key once", async () => {
    const res = await connect("/sign-in/start", {
      method: "POST",
      json: { instance_id: instance, instance_name: "Oliver's Mac", platform: "macos" },
    });
    expect(res.status).toBe(200);
    const started = await j(res);
    expect(started.user_code).toMatch(/^[A-Z0-9]{4}-[A-Z0-9]{4}$/);
    expect(started.verification_url).toBe(
      `https://app.example.test/link?code=${started.user_code}`,
    );
    expect(started.device_code).not.toContain(started.user_code);

    // Nothing to collect until someone approves.
    const waiting = await j(
      await connect("/sign-in/poll", {
        method: "POST",
        json: { device_code: started.device_code },
      }),
    );
    expect(waiting).toEqual({ status: "pending" });

    // The approval page shows which server asked; the code is forgiving about case and the dash.
    const shown = await h.request(
      `/v1/link/sign-ins/${started.user_code.toLowerCase().replace("-", "")}`,
      { token: owner.token },
    );
    expect(shown.status).toBe(200);
    expect(await j(shown)).toMatchObject({
      user_code: started.user_code,
      instance_name: "Oliver's Mac",
      platform: "macos",
      approved: false,
    });
    expect((await h.request(`/v1/link/sign-ins/${started.user_code}`)).status).toBe(401);

    // Only an admin of the workspace may link a server to it.
    const stranger = await h.request(`/v1/orgs/${orgId}/link/sign-ins/approve`, {
      method: "POST",
      token: member.token,
      json: { user_code: started.user_code },
    });
    expect(stranger.status).toBe(403);

    const approved = await h.request(`/v1/orgs/${orgId}/link/sign-ins/approve`, {
      method: "POST",
      token: owner.token,
      json: { user_code: started.user_code },
    });
    expect(approved.status).toBe(200);
    expect(await j(approved)).toEqual({ instance_name: "Oliver's Mac" });
    // A code is approved once.
    const again = await h.request(`/v1/orgs/${orgId}/link/sign-ins/approve`, {
      method: "POST",
      token: owner.token,
      json: { user_code: started.user_code },
    });
    expect(again.status).toBe(404);

    const polled = await j(
      await connect("/sign-in/poll", {
        method: "POST",
        json: { device_code: started.device_code },
      }),
    );
    expect(polled).toMatchObject({
      status: "approved",
      workspace: "Home",
      scopes: ["remote_access", "push"],
    });
    expect(polled.key).toMatch(/^kcc_/);
    key = polled.key;
    // The key is shown once: the same device code gets nothing more.
    const replay = await j(
      await connect("/sign-in/poll", {
        method: "POST",
        json: { device_code: started.device_code },
      }),
    );
    expect(replay).toEqual({ status: "expired" });

    // It can hold an address, and can't spend the workspace's credits.
    const who = await j(await connect("/whoami", { key }));
    expect(who).toMatchObject({
      org_id: orgId,
      instance_name: "Oliver's Mac",
      remote_access: true,
      computers: false,
      models: false,
    });
    const [audit] = await h.handle.db.execute<{ metadata: { via: string } }>(sql`
      select metadata from public.audit_log
      where org_id = ${orgId}::uuid and action = 'casama_link.key_created'`);
    expect(audit?.metadata.via).toBe("link");
  });

  it("refuses codes that are wrong, expired or never approved", async () => {
    expect((await h.request("/v1/link/sign-ins/ZZZZ-ZZZZ", { token: owner.token })).status).toBe(
      404,
    );
    const bad = await h.request(`/v1/orgs/${orgId}/link/sign-ins/approve`, {
      method: "POST",
      token: owner.token,
      json: { user_code: "ZZZZ-ZZZZ" },
    });
    expect(bad.status).toBe(404);
    expect(
      await j(
        await connect("/sign-in/poll", {
          method: "POST",
          json: { device_code: "kcl_nothing-here-0123456789" },
        }),
      ),
    ).toEqual({ status: "expired" });
    expect(
      (await connect("/sign-in/start", { method: "POST", json: { instance_id: "short" } })).status,
    ).toBe(400);

    const started = await j(
      await connect("/sign-in/start", { method: "POST", json: { instance_id: instance } }),
    );
    await h.handle.db.execute(sql`
      update public.link_sign_in_requests set expires_at = now() - interval '1 minute'
      where user_code = ${started.user_code}`);
    const late = await h.request(`/v1/orgs/${orgId}/link/sign-ins/approve`, {
      method: "POST",
      token: owner.token,
      json: { user_code: started.user_code },
    });
    expect(late.status).toBe(404);
  });

  it("gives the server an address through a tunnel, and the same one every time", async () => {
    expect(
      (await connect("/remote", { method: "PUT", json: { instance_id: instance } })).status,
    ).toBe(401);
    const res = await connect("/remote", {
      method: "PUT",
      key,
      json: { instance_id: instance, platform: "macos", version: "0.1.0" },
    });
    expect(res.status).toBe(200);
    const first = await j(res);
    expect(first.address).toMatch(/^https:\/\/[a-z][a-z0-9]{11}\.link\.test$/);
    expect(first.pages_address).toBe(first.address.replace(".link.test", "-p.link.test"));
    expect(first.generation).toBe(1);

    // One tunnel, routed by two proxied names, sending traffic only to the stack's own proxy.
    const host = new URL(first.address).host;
    const tunnel = cf.tunnelFor(host);
    expect(tunnel).toBeDefined();
    expect(first.token).toBe(`token-for-${tunnel?.id}`);
    expect(cf.live()).toHaveLength(1);
    expect(tunnel?.ingress).toEqual([
      { hostname: host, service: "http://caddy:80", originRequest: {} },
      {
        hostname: new URL(first.pages_address).host,
        service: "http://caddy:8790",
        originRequest: {},
      },
      { service: "http_status:404" },
    ]);
    expect([...cf.records.values()].map((r) => [r.type, r.proxied])).toEqual([
      ["CNAME", true],
      ["CNAME", true],
    ]);
    expect(cf.tunnelFor(new URL(first.pages_address).host)?.id).toBe(tunnel?.id);

    // Asking again changes nothing.
    const second = await j(
      await connect("/remote", { method: "PUT", key, json: { instance_id: instance } }),
    );
    expect(second).toMatchObject({
      address: first.address,
      token: first.token,
      generation: 1,
      server_id: first.server_id,
    });
    expect(cf.live()).toHaveLength(1);
    expect(cf.records.size).toBe(2);

    const beat = await j(
      await connect("/remote/heartbeat", {
        method: "POST",
        key,
        json: { instance_id: instance, generation: 1 },
      }),
    );
    expect(beat).toMatchObject({ status: "ok", generation: 1, address: first.address });

    // The server's status screen: the address and whether a connector is attached.
    expect(await j(await connect(`/remote?instance_id=${instance}`, { key }))).toMatchObject({
      status: "active",
      address: first.address,
      connector: { state: "inactive" },
    });
    cf.setConnected(host, true);
    expect(
      (await j(await connect(`/remote?instance_id=${instance}`, { key }))).connector.state,
    ).toBe("healthy");
    cf.setConnected(host, false);
  });

  it("shows the workspace its servers, and holds it to the plan's number", async () => {
    const list = await j(await h.request(`/v1/orgs/${orgId}/link/servers`, { token: owner.token }));
    expect(list.limit).toBe(1);
    expect(list.items).toHaveLength(1);
    expect(list.items[0]).toMatchObject({
      instance_name: "Oliver's Mac",
      status: "active",
      platform: "macos",
    });
    expect(
      (await h.request(`/v1/orgs/${orgId}/link/servers`, { token: member.token })).status,
    ).toBe(403);

    // Free connects one server: a second one is told so, and gets no tunnel.
    const second = await connect("/remote", {
      method: "PUT",
      key,
      json: { instance_id: "0f6a3c1e-7b1d-4c55-9a52-000000000002" },
    });
    expect(second.status).toBe(402);
    expect((await j(second)).code).toBe("plan_limit");
    expect(cf.live()).toHaveLength(1);

    // On Pro (three servers) it fits.
    await h.handle.db.execute(sql`
      update public.entitlements set limits = limits || '{"remote_servers": 3}'::jsonb
      where org_id = ${orgId}::uuid`);
    const now = await connect("/remote", {
      method: "PUT",
      key,
      json: { instance_id: "0f6a3c1e-7b1d-4c55-9a52-000000000002", instance_name: "Home server" },
    });
    expect(now.status).toBe(200);
    expect(cf.live()).toHaveLength(2);

    // An admin removes it, also when the server itself is gone; that frees the place.
    const servers2 = await j(
      await h.request(`/v1/orgs/${orgId}/link/servers`, { token: owner.token }),
    );
    const extra = servers2.items.find(
      (s: { instance_name: string }) => s.instance_name === "Home server",
    );
    const removed = await h.request(`/v1/orgs/${orgId}/link/servers/${extra.id}`, {
      method: "DELETE",
      token: owner.token,
    });
    expect(removed.status).toBe(200);
    expect(cf.live()).toHaveLength(1);
    expect(cf.records.size).toBe(2);
    await h.handle.db.execute(sql`
      update public.entitlements set limits = limits || '{"remote_servers": 1}'::jsonb
      where org_id = ${orgId}::uuid`);
  });

  it("a key that can spend but can't hold an address is refused", async () => {
    const made = await j(
      await h.request(`/v1/orgs/${orgId}/link/keys`, {
        method: "POST",
        token: owner.token,
        json: { instance_name: "computers-only" },
      }),
    );
    const res = await connect("/remote", {
      method: "PUT",
      key: made.key,
      json: { instance_id: instance },
    });
    expect(res.status).toBe(403);
    expect((await j(res)).code).toBe("remote_access_unavailable");
  });

  it("turning remote access off removes the tunnel and keeps the address for next time", async () => {
    const before = await j(
      await connect("/remote", { method: "PUT", key, json: { instance_id: instance } }),
    );
    const off = await connect(`/remote?instance_id=${instance}`, { method: "DELETE", key });
    expect(await j(off)).toEqual({ released: true });
    expect(cf.live()).toHaveLength(0);
    expect(cf.records.size).toBe(0);
    const beat = await j(
      await connect("/remote/heartbeat", {
        method: "POST",
        key,
        json: { instance_id: instance, generation: before.generation },
      }),
    );
    expect(beat.status).toBe("released");
    // A released address is a reservation, not a server on the list.
    const list = await j(await h.request(`/v1/orgs/${orgId}/link/servers`, { token: owner.token }));
    expect(list.items).toHaveLength(0);

    const back = await j(
      await connect("/remote", { method: "PUT", key, json: { instance_id: instance } }),
    );
    expect(back.address).toBe(before.address);
    expect(back.generation).toBeGreaterThan(before.generation);
    expect(back.token).not.toBe(before.token);
    expect(cf.tunnelFor(new URL(back.address).host)).toBeDefined();
  });

  it("a tunnel that disappeared is made again at the same address", async () => {
    const before = await j(
      await connect("/remote", { method: "PUT", key, json: { instance_id: instance } }),
    );
    const host = new URL(before.address).host;
    const lost = cf.tunnelFor(host);
    if (lost) lost.deleted_at = new Date().toISOString();
    const after = await j(
      await connect("/remote", { method: "PUT", key, json: { instance_id: instance } }),
    );
    expect(after.address).toBe(before.address);
    expect(after.generation).toBe(before.generation + 1);
    expect(cf.tunnelFor(host)?.id).not.toBe(lost?.id);
    // The server held the old generation, so its next check-in tells it to ask again.
    const beat = await j(
      await connect("/remote/heartbeat", {
        method: "POST",
        key,
        json: { instance_id: instance, generation: before.generation },
      }),
    );
    expect(beat.status).toBe("replaced");
  });

  it("a failure half-way leaves nothing doubled: the retry adopts what was made", async () => {
    await connect(`/remote?instance_id=${instance}`, { method: "DELETE", key });
    expect(cf.live()).toHaveLength(0);
    // The tunnel gets made, then the first DNS record fails.
    cf.failNext(/^POST \/zones\/.*\/dns_records$/, 1, 500);
    const failed = await connect("/remote", {
      method: "PUT",
      key,
      json: { instance_id: instance },
    });
    expect(failed.status).toBe(503);
    expect((await j(failed)).code).toBe("address_unavailable");
    expect(cf.live()).toHaveLength(1);

    const retried = await connect("/remote", {
      method: "PUT",
      key,
      json: { instance_id: instance },
    });
    expect(retried.status).toBe(200);
    expect(cf.live()).toHaveLength(1);
    expect(cf.records.size).toBe(2);
    expect(cf.tunnelFor(new URL((await j(retried)).address).host)).toBeDefined();
  });

  it("parks a server that stopped checking in, and brings it back when it returns", async () => {
    const before = await j(
      await connect("/remote", { method: "PUT", key, json: { instance_id: instance } }),
    );
    // Seen yesterday: left alone.
    await h.handle.db.execute(
      sql`update public.link_servers set last_seen_at = now() - interval '1 day' where instance_id = ${instance}`,
    );
    expect((await servers.sweep("on")).parked).toBe(0);

    await h.handle.db.execute(
      sql`update public.link_servers set last_seen_at = now() - interval '15 days' where instance_id = ${instance}`,
    );
    // dry-run only counts.
    expect(await servers.sweep("dry-run")).toMatchObject({ mode: "dry-run", parked: 1 });
    expect(cf.live()).toHaveLength(1);

    expect(await servers.sweep("on")).toMatchObject({ parked: 1, failed: 0 });
    expect(cf.live()).toHaveLength(0);
    expect(cf.records.size).toBe(0);
    // A parked server still holds its place on the plan.
    const list = await j(await h.request(`/v1/orgs/${orgId}/link/servers`, { token: owner.token }));
    expect(list.items[0]).toMatchObject({ status: "parked", status_reason: "not_seen" });

    const beat = await j(
      await connect("/remote/heartbeat", {
        method: "POST",
        key,
        json: { instance_id: instance, generation: before.generation },
      }),
    );
    expect(beat.status).toBe("parked");
    const back = await j(
      await connect("/remote", { method: "PUT", key, json: { instance_id: instance } }),
    );
    expect(back.address).toBe(before.address);
    expect(cf.live()).toHaveLength(1);
  });

  it("a removal the provider refused is finished by the next sweep", async () => {
    cf.failNext(/^DELETE \/accounts\/.*\/cfd_tunnel\/[^/]+$/, 1, 500);
    await connect(`/remote?instance_id=${instance}`, { method: "DELETE", key });
    // The server is told it has no address, even though the tunnel is still there.
    const beat = await j(
      await connect("/remote/heartbeat", { method: "POST", key, json: { instance_id: instance } }),
    );
    expect(beat.status).toBe("released");
    expect(cf.live()).toHaveLength(1);

    expect(await servers.sweep("on")).toMatchObject({ removed: 1, failed: 0 });
    expect(cf.live()).toHaveLength(0);
    await connect("/remote", { method: "PUT", key, json: { instance_id: instance } });
  });

  it("the instance owner sees every server and can take one address down", async () => {
    expect((await h.request("/v1/admin/link/servers", { token: member.token })).status).toBe(403);
    const all = await j(await h.request("/v1/admin/link/servers", { token: owner.token }));
    expect(all.zone).toBe("link.test");
    expect(all.tunnels).toBe(1);
    const mine = all.items.find((s: { status: string }) => s.status === "active");
    expect(mine).toMatchObject({ org_id: orgId, org_name: "Home" });

    const suspended = await h.request(`/v1/admin/link/servers/${mine.id}/suspend`, {
      method: "POST",
      token: owner.token,
      json: { reason: "Phishing page reported" },
    });
    expect(suspended.status).toBe(200);
    expect(await j(suspended)).toMatchObject({
      status: "suspended",
      status_reason: "Phishing page reported",
    });
    expect(cf.live()).toHaveLength(0);
    // The server can't get it back by asking.
    const refused = await connect("/remote", {
      method: "PUT",
      key,
      json: { instance_id: instance },
    });
    expect(refused.status).toBe(403);
    expect(
      (
        await j(
          await connect("/remote/heartbeat", {
            method: "POST",
            key,
            json: { instance_id: instance },
          }),
        )
      ).status,
    ).toBe("suspended");
    expect(cf.live()).toHaveLength(0);

    const lifted = await h.request(`/v1/admin/link/servers/${mine.id}/suspend`, {
      method: "DELETE",
      token: owner.token,
    });
    expect((await j(lifted)).status).toBe("parked");
    const back = await connect("/remote", { method: "PUT", key, json: { instance_id: instance } });
    expect(back.status).toBe(200);
    expect(cf.live()).toHaveLength(1);
  });

  it("a suspended workspace loses its addresses until the suspension is lifted", async () => {
    const res = await h.request(`/v1/admin/orgs/${orgId}/suspend`, {
      method: "POST",
      token: owner.token,
      json: { reason: "abuse" },
    });
    expect(res.status).toBe(200);
    expect(cf.live()).toHaveLength(0);
    expect(
      (
        await j(
          await connect("/remote/heartbeat", {
            method: "POST",
            key,
            json: { instance_id: instance },
          }),
        )
      ).status,
    ).toBe("suspended");
    expect(
      (await connect("/remote", { method: "PUT", key, json: { instance_id: instance } })).status,
    ).toBe(403);

    await h.request(`/v1/admin/orgs/${orgId}/suspend`, { method: "DELETE", token: owner.token });
    expect(
      (
        await j(
          await connect("/remote/heartbeat", {
            method: "POST",
            key,
            json: { instance_id: instance },
          }),
        )
      ).status,
    ).toBe("parked");
    expect(
      (await connect("/remote", { method: "PUT", key, json: { instance_id: instance } })).status,
    ).toBe(200);
  });

  it("another workspace's key never reaches this server's address", async () => {
    const otherOrg = await makeOrg(member.token, "Elsewhere");
    const otherKey = await link(member.token, otherOrg, instance, "Same id, other workspace");
    expect((await connect(`/remote?instance_id=${instance}`, { key: otherKey })).status).toBe(404);
    expect(
      (
        await j(
          await connect("/remote/heartbeat", {
            method: "POST",
            key: otherKey,
            json: { instance_id: instance },
          }),
        )
      ).status,
    ).toBe("unknown");
    expect(
      await j(
        await connect(`/remote?instance_id=${instance}`, { method: "DELETE", key: otherKey }),
      ),
    ).toEqual({ released: false });
    expect(cf.live()).toHaveLength(1);
  });

  it("revoking the key takes the address with it", async () => {
    const keys = await j(await h.request(`/v1/orgs/${orgId}/link/keys`, { token: owner.token }));
    const linked = keys.items.find(
      (k: { instance_name: string }) => k.instance_name === "Oliver's Mac",
    );
    expect(linked.scopes).toEqual(["remote_access", "push"]);
    const revoked = await h.request(`/v1/orgs/${orgId}/link/keys/${linked.id}`, {
      method: "DELETE",
      token: owner.token,
    });
    expect(revoked.status).toBe(200);
    expect(cf.live()).toHaveLength(0);
    expect(
      (await connect("/remote", { method: "PUT", key, json: { instance_id: instance } })).status,
    ).toBe(401);
  });

  it("with parking off, idle servers are left alone but a suspended workspace's tunnel still goes", async () => {
    const quiet = "0f6a3c1e-7b1d-4c55-9a52-000000000009";
    const other = await makeOrg(member.token, "Quiet");
    const quietKey = await link(member.token, other, quiet, "Quiet server");
    const made = await connect("/remote", {
      method: "PUT",
      key: quietKey,
      json: { instance_id: quiet },
    });
    expect(made.status).toBe(200);
    const before = cf.live().length;
    await h.handle.db.execute(
      sql`update public.link_servers set last_seen_at = now() - interval '40 days' where instance_id = ${quiet}`,
    );
    expect(await servers.sweep("off")).toMatchObject({ mode: "off", parked: 0, removed: 0 });
    expect(cf.live()).toHaveLength(before);

    // Suspended behind the upkeep's back (not through the admin route): the next sweep catches it.
    await h.handle.db.execute(
      sql`update public.organizations set suspended_at = now() where id = ${other}::uuid`,
    );
    expect((await servers.sweep("off")).removed).toBe(1);
    expect(cf.live()).toHaveLength(before - 1);
    await h.handle.db.execute(
      sql`update public.organizations set suspended_at = null where id = ${other}::uuid`,
    );
  });

  it("warns the owners once a day when the provider's included amounts are close", async () => {
    const { linkUpkeep } = await import("../src/link/upkeep.ts");
    const base = { db: h.handle.db, servers, parking: "off" as const, recordLimit: 200 };
    const notices = () =>
      h.handle.db.execute<{ user_id: string; payload: { body: string } }>(
        sql`select user_id, payload from public.notifications where kind = 'link_capacity'`,
      );
    // Far from any limit: nothing is said.
    expect((await linkUpkeep({ ...base, tunnelAlert: 700 })).warned).toBe(false);
    expect(await notices()).toHaveLength(0);

    // One server with an address, so there is something to count.
    const busy = "0f6a3c1e-7b1d-4c55-9a52-00000000000a";
    const busyOrg = await makeOrg(member.token, "Busy");
    const busyKey = await link(member.token, busyOrg, busy, "Busy server");
    expect(
      (await connect("/remote", { method: "PUT", key: busyKey, json: { instance_id: busy } }))
        .status,
    ).toBe(200);
    const tunnels = cf.live().length;
    expect(tunnels).toBeGreaterThan(0);
    const first = await linkUpkeep({ ...base, tunnelAlert: tunnels });
    expect(first).toMatchObject({ tunnels, warned: true });
    const sent = await notices();
    // With no admin list, the first account (the instance owner) is told.
    expect(sent.map((n) => n.user_id)).toEqual([owner.id]);
    expect(sent[0]?.payload.body).toContain("Cloudflare includes 1,000");
    // The same day: not again.
    expect((await linkUpkeep({ ...base, tunnelAlert: tunnels })).warned).toBe(false);
    expect(await notices()).toHaveLength(1);

    // A day on, DNS records running out is said in its own words.
    await h.handle.db.execute(
      sql`update public.notifications set created_at = now() - interval '2 days' where kind = 'link_capacity'`,
    );
    const records = await linkUpkeep({ ...base, tunnelAlert: 700, recordLimit: tunnels * 2 });
    expect(records.warned).toBe(true);
    expect((await notices()).at(-1)?.payload.body).toContain("DNS records");
  });

  it("forgets addresses nobody came back for", async () => {
    await h.handle.db.execute(sql`
      update public.link_servers set released_at = now() - interval '91 days'
      where instance_id = ${instance} and org_id = ${orgId}::uuid`);
    expect((await servers.sweep("on")).forgotten).toBe(1);
    // The other server, removed a moment ago, keeps its reservation.
    const left = await h.handle.db.execute<{ instance_name: string }>(sql`
      select instance_name from public.link_servers where org_id = ${orgId}::uuid`);
    expect(left.map((s) => s.instance_name)).toEqual(["Home server"]);
  });
});

describe("Casama Link on a server that gives out no addresses", () => {
  let h: Harness;
  beforeAll(async () => {
    h = await startHarness();
  }, 60_000);
  afterAll(() => h?.stop());

  it("answers that plainly", async () => {
    const user = await h.user("no-link@example.com");
    const res = await h.request("/v1/link/sign-ins/ABCD-EFGH", { token: user.token });
    expect(res.status).toBe(404);
    expect((await j(res)).code).toBe("link_unavailable");
    expect((await h.request("/link/v1/sign-in/start", { method: "POST", json: {} })).status).toBe(
      404,
    );
  });
});
