import { createServer } from "node:http";
import type { AddressInfo } from "node:net";
import { sql } from "drizzle-orm";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

describe("owner admin console (Phase 6)", () => {
  let h: Harness;
  let owner: { id: string; token: string };
  let member: { id: string; token: string };
  let orgId: string;
  const releases = createServer((_req, res) => {
    res.writeHead(200, { "content-type": "application/json" });
    res.end(
      JSON.stringify({ tag_name: "v0.9.1", html_url: "https://example.com/releases/v0.9.1" }),
    );
  });

  beforeAll(async () => {
    await new Promise<void>((r) => releases.listen(0, "127.0.0.1", r));
    process.env.TEST_UPDATE_CHECK_URL = `http://127.0.0.1:${(releases.address() as AddressInfo).port}/latest`;
    h = await startHarness();
    owner = await h.user("admin-owner@example.com");
    member = await h.user("admin-member@example.com");
    orgId = (
      await j(
        await h.request("/v1/orgs", {
          method: "POST",
          token: member.token,
          json: { name: "Tenant" },
        }),
      )
    ).id;
  }, 60_000);
  afterAll(async () => {
    await h?.stop();
    releases.close();
  });

  it("only the instance owner (the first user when no emails are set) can open it", async () => {
    expect((await h.request("/v1/admin/overview", { token: member.token })).status).toBe(403);
    const res = await h.request("/v1/admin/overview", { token: owner.token });
    expect(res.status).toBe(200);
    expect(await j(res)).toMatchObject({ users: 2, orgs: 1, version: expect.any(String) });
  });

  it("rejects old owner proof before reads, writes and validation, while keeping discovery", async () => {
    const stale = await h.tokenFor(
      { id: owner.id, email: "admin-owner@example.com" },
      {
        amr: [{ method: "password", timestamp: Math.floor(Date.now() / 1000) - 600 }],
      },
    );
    expect((await h.request("/v1/admin/overview", { token: stale })).status).toBe(200);
    const read = await h.request("/v1/admin/users", { token: stale });
    expect(read.status).toBe(403);
    expect(await j(read)).toMatchObject({ code: "admin_reauthentication_required" });
    const write = await h.request(`/v1/admin/orgs/${orgId}/limits`, {
      token: stale,
      method: "PATCH",
      json: {},
    });
    expect(write.status).toBe(403);
    expect(await j(write)).toMatchObject({ code: "admin_confirmation_required" });
    expect((await h.request("/v1/orgs", { token: stale })).status).toBe(200);
    expect((await h.request("/v1/admin/users", { token: member.token })).status).toBe(403);
  });

  it("an owner with two-step sign-in must have passed it in this session", async () => {
    const [factor] = await h.tdb.admin<{ id: string }[]>`
      insert into auth.mfa_factors (id, user_id, friendly_name, factor_type, status, created_at, updated_at)
      values (gen_random_uuid(), ${owner.id}::uuid, 'test', 'totp', 'verified', now(), now())
      returning id`;
    try {
      const who = { id: owner.id, email: "admin-owner@example.com" };
      const aal1 = await h.tokenFor(who, { aal: "aal1" });
      const read = await h.request("/v1/admin/users", { token: aal1 });
      expect(read.status).toBe(403);
      expect(await j(read)).toMatchObject({ code: "admin_reauthentication_required" });
      const write = await h.request(`/v1/admin/orgs/${orgId}/limits`, {
        token: aal1,
        method: "PATCH",
        json: {},
      });
      expect(await j(write)).toMatchObject({ code: "admin_confirmation_required" });
      // A fresh passkey is a first step only (Supabase: aal1, user verification preferred, D-450).
      const now = Math.floor(Date.now() / 1000);
      const passkey = await h.tokenFor(who, {
        aal: "aal1",
        amr: [{ method: "passkey", timestamp: now }],
      });
      expect((await h.request("/v1/admin/users", { token: passkey })).status).toBe(403);
      const passkeyAndCode = await h.tokenFor(who, {
        aal: "aal2",
        amr: [
          { method: "totp", timestamp: now },
          { method: "passkey", timestamp: now },
        ],
      });
      expect((await h.request("/v1/admin/users", { token: passkeyAndCode })).status).toBe(200);
      // Discovery still works, and a session that passed the code gets in.
      expect((await h.request("/v1/admin/overview", { token: aal1 })).status).toBe(200);
      const aal2 = await h.tokenFor(who, { aal: "aal2" });
      expect((await h.request("/v1/admin/users", { token: aal2 })).status).toBe(200);
    } finally {
      await h.tdb.admin`delete from auth.mfa_factors where id = ${factor!.id}::uuid`;
    }
  });

  it("lists users and workspaces, and sets quotas", async () => {
    const usersRes = await h.request("/v1/admin/users", { token: owner.token });
    const users = await j(usersRes);
    if (!users.items) throw new Error(JSON.stringify(users));
    expect(users.items.map((u: { email: string }) => u.email)).toEqual([
      "admin-owner@example.com",
      "admin-member@example.com",
    ]);
    const orgs = await j(await h.request("/v1/admin/orgs", { token: owner.token }));
    expect(orgs.items[0]).toMatchObject({ id: orgId, name: "Tenant", members: 1 });
    const set = await j(
      await h.request(`/v1/admin/orgs/${orgId}/limits`, {
        method: "PATCH",
        token: owner.token,
        json: { limits: { max_bots: 3, monthly_usd: 25 } },
      }),
    );
    expect(set.limits).toEqual({ max_bots: 3, monthly_usd: 25 });
  });

  it("restricts vendor monitoring to the instance owner and validates settings", async () => {
    for (const [path, method] of [
      ["/v1/admin/vendors", "GET"],
      ["/v1/admin/vendors/resend", "PUT"],
      ["/v1/admin/vendors/resend/check", "POST"],
    ] as const) {
      const response = await h.request(path, {
        token: member.token,
        method,
        ...(method === "PUT"
          ? {
              json: {
                limit_value: 100,
                period: "day",
                period_start: null,
                expires_at: null,
                warn_at: 0.8,
                enabled: true,
              },
            }
          : {}),
      });
      expect(response.status).toBe(403);
    }
    const response = await h.request("/v1/admin/vendors", { token: owner.token });
    expect(response.status).toBe(200);
    const vendors = await j(response);
    expect(vendors.items.some((v: { vendor: string }) => v.vendor === "resend")).toBe(true);
    expect(
      (
        await h.request("/v1/admin/vendors/resend", {
          method: "PUT",
          token: owner.token,
          json: {
            limit_value: 100,
            period: "day",
            period_start: null,
            expires_at: null,
            warn_at: 0,
            enabled: true,
          },
        })
      ).status,
    ).toBe(400);
    expect(
      (
        await h.request("/v1/admin/vendors/resend", {
          method: "PUT",
          token: owner.token,
          json: {
            limit_value: 100,
            period: "day",
            period_start: null,
            expires_at: null,
            warn_at: 0.9,
            enabled: true,
          },
        })
      ).status,
    ).toBe(200);
  });

  it("shows services and health", async () => {
    const s = await j(await h.request("/v1/admin/services", { token: owner.token }));
    const byName = Object.fromEntries(s.items.map((i: { name: string }) => [i.name, i]));
    expect(byName.Database).toMatchObject({ configured: true, healthy: true });
    expect(byName["Sandbox supervisor"]).toMatchObject({ configured: false });
  });

  it("tells the owner when a newer release exists", async () => {
    const u = await j(await h.request("/v1/admin/updates", { token: owner.token }));
    expect(u).toMatchObject({
      latest: "0.9.1",
      update_available: true,
      url: "https://example.com/releases/v0.9.1",
    });
  });

  it("shows what usage was charged against what it cost the server (D-395)", async () => {
    const db = h.handle.db;
    await db.execute(sql`
      insert into public.usage_ledger (org_id, kind, quantity, cost_usd, upstream_cost_usd, billable, meta) values
        (${orgId}::uuid, 'tokens_in', 1000, 1.477, 1.055, true, '{}'),
        (${orgId}::uuid, 'app_calls', 1, 0.0028, 0.002, true, '{}'),
        (${orgId}::uuid, 'computer_seconds', 3600, 0.5, null, true, '{}'),
        (${orgId}::uuid, 'tokens_out', 10, 0.1, 0.07, false, '{"waived": "failed_run"}'),
        (${orgId}::uuid, 'tokens_in', 50, 0.9, null, false, '{}')`);
    expect((await h.request("/v1/admin/margin", { token: member.token })).status).toBe(403);
    const m = await j(await h.request("/v1/admin/margin?days=7", { token: owner.token }));
    expect(m.days).toBe(7);
    // Charged: every billable row. Tracked: those whose cost is known. Cost: waived rows too.
    expect(m.charged_usd).toBeCloseTo(1.9798, 6);
    expect(m.charged_tracked_usd).toBeCloseTo(1.4798, 6);
    expect(m.upstream_usd).toBeCloseTo(1.127, 6);
    expect(m.by_day).toHaveLength(1);
    expect(m.by_kind[0]).toMatchObject({ kind: "tokens_in" });
    expect(m.by_kind[0].charged_usd).toBeCloseTo(1.477, 6);
    expect(m.top_orgs[0]).toMatchObject({ org_id: orgId, name: "Tenant" });
    // Rows on the workspace's own key (not billable, no cost to the server) stay out.
    expect(m.by_kind.map((k: { kind: string }) => k.kind).sort()).toEqual([
      "app_calls",
      "computer_seconds",
      "tokens_in",
      "tokens_out",
    ]);
  });
});
