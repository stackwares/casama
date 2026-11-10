/** Spaces (D-099): workspace look, invite links, per-workspace badges. */
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
let owner: { id: string; token: string };
let friend: { id: string; token: string };
let late: { id: string; token: string };
let home: string;
let work: string;

beforeAll(async () => {
  h = await startHarness({ env: { PUBLIC_APP_URL: "https://app.example.com" } });
  owner = await h.user("space-owner@example.com");
  friend = await h.user("space-friend@example.com");
  late = await h.user("space-late@example.com");
  home = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "Home" } }),
    )
  ).id;
  work = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "Work" } }),
    )
  ).id;
}, 60_000);
afterAll(() => h?.stop());

describe("spaces", () => {
  it("lets admins give a space an icon and color", async () => {
    const res = await h.request(`/v1/orgs/${home}`, {
      method: "PATCH",
      token: owner.token,
      json: { icon: "house", color: "#22aa66" },
    });
    expect(await j(res)).toMatchObject({ name: "Home", icon: "house", color: "#22aa66" });
    const orgs = await j(await h.request("/v1/orgs", { token: owner.token }));
    expect(orgs.items.find((o: { id: string }) => o.id === home)).toMatchObject({ icon: "house" });
    expect(
      (
        await h.request(`/v1/orgs/${home}`, {
          method: "PATCH",
          token: friend.token,
          json: { name: "x" },
        })
      ).status,
    ).toBe(403);
  });

  it("joins with an invite link once, with the link's role", async () => {
    const link = await j(
      await h.request(`/v1/orgs/${home}/invite-links`, {
        method: "POST",
        token: owner.token,
        json: { role: "admin", max_uses: 1, expires_in_days: 7 },
      }),
    );
    expect(link.url).toBe(`https://app.example.com/join/${link.token}`);
    expect(link.token).toMatch(/^kjoin_/);
    const joined = await j(
      await h.request(`/v1/invite-links/${link.token}/accept`, {
        method: "POST",
        token: friend.token,
      }),
    );
    expect(joined).toMatchObject({ id: home, role: "admin" });
    const used = await h.request(`/v1/invite-links/${link.token}/accept`, {
      method: "POST",
      token: late.token,
    });
    expect(used.status).toBe(404);
    const list = await j(await h.request(`/v1/orgs/${home}/invite-links`, { token: owner.token }));
    expect(list.items[0]).toMatchObject({ uses: 1, max_uses: 1, role: "admin" });
    expect(JSON.stringify(list)).not.toContain(link.token);
  });

  it("stops a revoked link and keeps links admin-only", async () => {
    const link = await j(
      await h.request(`/v1/orgs/${work}/invite-links`, {
        method: "POST",
        token: owner.token,
        json: {},
      }),
    );
    expect((await h.request(`/v1/orgs/${work}/invite-links`, { token: late.token })).status).toBe(
      403,
    );
    expect(
      (
        await h.request(`/v1/orgs/${work}/invite-links/${link.id}`, {
          method: "DELETE",
          token: owner.token,
        })
      ).status,
    ).toBe(204);
    expect(
      (
        await h.request(`/v1/invite-links/${link.token}/accept`, {
          method: "POST",
          token: late.token,
        })
      ).status,
    ).toBe(404);
  });

  it("counts approvals and unread notifications per space", async () => {
    await h.tdb.admin`insert into public.notifications (user_id, org_id, kind, payload) values
      (${owner.id}, ${work}, 'x', '{}'), (${owner.id}, ${work}, 'x', '{}'), (${owner.id}, ${home}, 'x', '{}')`;
    const badges = await j(await h.request("/v1/me/badges", { token: owner.token }));
    const by = Object.fromEntries(
      badges.items.map((b: { org_id: string; unread: number }) => [b.org_id, b.unread]),
    );
    expect(by).toEqual({ [home]: 1, [work]: 2 });
  });
});
