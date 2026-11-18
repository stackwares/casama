/** A workspace requires the app lock (D-375): admins set it, and every member's workspace list says so. */
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
let owner: { id: string; email: string; token: string };
let member: { id: string; email: string; token: string };
let orgId: string;

beforeAll(async () => {
  h = await startHarness();
  owner = await h.user("applock-owner@example.com");
  member = await h.user("applock-member@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "Locked" } }),
    )
  ).id;
  await h.tdb
    .admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${member.id}, 'member')`;
}, 60_000);
afterAll(() => h?.stop());

const listed = async (token: string) =>
  (await j(await h.request("/v1/orgs", { token }))).items.find(
    (o: { id: string }) => o.id === orgId,
  );

describe("requiring the app lock", () => {
  it("is off for a new workspace", async () => {
    const settings = await j(await h.request(`/v1/orgs/${orgId}/settings`, { token: owner.token }));
    expect(settings.require_app_lock).toBe(false);
    expect((await listed(member.token)).require_app_lock).toBe(false);
  });

  it("a member can't turn it on or off", async () => {
    const res = await h.request(`/v1/orgs/${orgId}/settings`, {
      method: "PATCH",
      token: member.token,
      json: { require_app_lock: true },
    });
    expect(res.status).toBe(403);
    expect((await listed(owner.token)).require_app_lock).toBe(false);
  });

  it("an owner turns it on, and members see it on their workspace list and in /v1/me", async () => {
    const res = await h.request(`/v1/orgs/${orgId}/settings`, {
      method: "PATCH",
      token: owner.token,
      json: { require_app_lock: true },
    });
    expect(res.status).toBe(200);
    expect((await j(res)).require_app_lock).toBe(true);
    expect((await listed(member.token)).require_app_lock).toBe(true);
    const me = await j(await h.request("/v1/me", { token: member.token }));
    expect(me.organizations.find((o: { id: string }) => o.id === orgId).require_app_lock).toBe(
      true,
    );
    // Other settings sent alone leave it as it is.
    const other = await h.request(`/v1/orgs/${orgId}/settings`, {
      method: "PATCH",
      token: owner.token,
      json: { llm_tracing: false },
    });
    expect((await j(other)).require_app_lock).toBe(true);
    const off = await h.request(`/v1/orgs/${orgId}/settings`, {
      method: "PATCH",
      token: owner.token,
      json: { require_app_lock: false },
    });
    expect((await j(off)).require_app_lock).toBe(false);
  });
});
