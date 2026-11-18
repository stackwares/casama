/** Full access (D-394): owners and admins switch it for the workspace; members can see it. */
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
let owner: { id: string; email: string; token: string };
let member: { id: string; email: string; token: string };
let orgId: string;

beforeAll(async () => {
  h = await startHarness();
  owner = await h.user("full-owner@example.com");
  member = await h.user("full-member@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "Full" } }),
    )
  ).id;
  await h.tdb
    .admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${member.id}, 'member')`;
}, 60_000);
afterAll(() => h?.stop());

const settings = async (token: string) =>
  j(await h.request(`/v1/orgs/${orgId}/settings`, { token }));
const patch = (token: string, json: Record<string, unknown>) =>
  h.request(`/v1/orgs/${orgId}/settings`, { method: "PATCH", token, json });

describe("full access", () => {
  it("is off for a new workspace", async () => {
    expect((await settings(owner.token)).full_access).toBe(false);
    expect((await settings(member.token)).full_access).toBe(false);
  });

  it("a member can't turn it on", async () => {
    expect((await patch(member.token, { full_access: true })).status).toBe(403);
    expect((await settings(owner.token)).full_access).toBe(false);
  });

  it("an owner turns it on and off, members see it, and it's in the audit log", async () => {
    const on = await patch(owner.token, { full_access: true });
    expect(on.status).toBe(200);
    expect((await j(on)).full_access).toBe(true);
    expect((await settings(member.token)).full_access).toBe(true);
    // Other settings sent alone leave it as it is.
    expect((await j(await patch(owner.token, { llm_tracing: false }))).full_access).toBe(true);
    const [a] = await h.tdb.admin<{ n: number }[]>`
      select count(*)::int as n from public.audit_log
      where org_id = ${orgId} and action = 'org.settings' and metadata ->> 'full_access' = 'true'`;
    expect(a?.n).toBe(1);
    expect((await j(await patch(owner.token, { full_access: false }))).full_access).toBe(false);
  });
});
