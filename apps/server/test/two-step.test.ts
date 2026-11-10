/** Two-step sign-in required by a workspace (D-092): owner and admin powers need an aal2 session. */
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
let owner: { id: string; email: string; token: string };
let ownerAal2: string;
let member: { id: string; email: string; token: string };
let orgId: string;

beforeAll(async () => {
  h = await startHarness();
  owner = await h.user("mfa-owner@example.com");
  ownerAal2 = await h.tokenFor(owner, { aal: "aal2" });
  member = await h.user("mfa-member@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "MFA" } }),
    )
  ).id;
  await h.tdb
    .admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${member.id}, 'member')`;
}, 60_000);
afterAll(() => h?.stop());

const addKey = (token: string) =>
  h.request("/v1/credentials", {
    method: "POST",
    token,
    json: { org_id: orgId, provider: "openrouter", label: "k", api_key: "sk-or-v1-abcdefabcdef" },
  });

describe("requiring two-step sign-in", () => {
  it("needs a two-step session to turn it on", async () => {
    const res = await h.request(`/v1/orgs/${orgId}/settings`, {
      method: "PATCH",
      token: owner.token,
      json: { require_mfa: true },
    });
    expect(res.status).toBe(403);
    expect((await j(res)).code).toBe("mfa_required");
    const ok = await h.request(`/v1/orgs/${orgId}/settings`, {
      method: "PATCH",
      token: ownerAal2,
      json: { require_mfa: true },
    });
    expect(ok.status).toBe(200);
    expect((await j(ok)).require_mfa).toBe(true);
    const orgs = await j(await h.request("/v1/orgs", { token: owner.token }));
    expect(orgs.items.find((o: { id: string }) => o.id === orgId).require_mfa).toBe(true);
  });

  it("holds back admin powers at aal1 with a clear error, and allows them at aal2", async () => {
    const blocked = await addKey(owner.token);
    expect(blocked.status).toBe(403);
    expect((await j(blocked)).code).toBe("mfa_required");
    expect((await addKey(ownerAal2)).status).toBe(201);
  });

  it("leaves members alone", async () => {
    const res = await h.request(`/v1/bots?org_id=${orgId}`, { token: member.token });
    expect(res.status).toBe(200);
    const denied = await addKey(member.token);
    expect(denied.status).toBe(403);
    expect((await j(denied)).code).toBe("forbidden");
  });
});
