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
