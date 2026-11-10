/** Bot sharing (D-131): private bots visible only to people listed; chat, edit and admin access. */
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
let owner: { id: string; token: string };
let ana: { id: string; token: string };
let ben: { id: string; token: string };
let orgId: string;
let botId: string;

const access = (token: string, json: unknown) =>
  h.request(`/v1/bots/${botId}/access`, { method: "PUT", token, json });
const sees = async (token: string) =>
  (
    (await j(await h.request(`/v1/bots?org_id=${orgId}`, { token }))).items as Array<{ id: string }>
  ).some((b) => b.id === botId);
const yours = async (token: string) =>
  (await j(await h.request(`/v1/bots/${botId}/access`, { token }))).your_access;

beforeAll(async () => {
  h = await startHarness();
  owner = await h.user("share-owner@example.com");
  ana = await h.user("share-ana@example.com");
  ben = await h.user("share-ben@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "S" } }),
    )
  ).id;
  for (const u of [ana, ben])
    await h.tdb
      .admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${u.id}, 'member')`;
  const created = await j(
    await h.request("/v1/bots", {
      method: "POST",
      token: owner.token,
      json: { org_id: orgId, name: "Private helper", visibility: "private" },
    }),
  );
  botId = created.id;
}, 60_000);
afterAll(async () => {
  await h?.stop();
});

describe("bot sharing", () => {
  it("a private bot is visible only to its creator until someone is listed", async () => {
    expect(await sees(owner.token)).toBe(true);
    expect(await sees(ana.token)).toBe(false);
    const res = await access(owner.token, {
      visibility: "private",
      entries: [{ user_id: ana.id, access: "chat" }],
    });
    expect(res.status).toBe(200);
    expect((await j(res)).entries).toEqual([
      { user_id: ana.id, email: "share-ana@example.com", role: null, access: "chat" },
    ]);
    expect(await sees(ana.token)).toBe(true);
    expect(await sees(ben.token)).toBe(false);
    expect(
      (await j(await h.request(`/v1/bots/${botId}/access`, { token: ana.token }))).your_access,
    ).toBe("chat");
  });

  it("chat access can't edit; edit access can edit but not share; admin access can share", async () => {
    expect(await yours(ana.token)).toBe("chat");
    await access(owner.token, {
      visibility: "private",
      entries: [{ user_id: ana.id, access: "edit" }],
    });
    expect(await yours(ana.token)).toBe("edit");
    const [can] = await h.tdb.admin<{ ok: boolean }[]>`
      select (select public.can_manage_bot(${botId}::uuid) from (select set_config('request.jwt.claims', ${JSON.stringify({ sub: ana.id, role: "authenticated" })}, true)) s) as ok`;
    expect(can?.ok).toBe(true);
    expect((await access(ana.token, { visibility: "team", entries: [] })).status).toBe(403);
    await access(owner.token, {
      visibility: "private",
      entries: [{ user_id: ana.id, access: "admin" }],
    });
    expect(
      (
        await access(ana.token, {
          visibility: "private",
          entries: [
            { user_id: ana.id, access: "admin" },
            { user_id: ben.id, access: "chat" },
          ],
        })
      ).status,
    ).toBe(200);
    expect(await sees(ben.token)).toBe(true);
  });

  it("a role can be granted, outsiders refused, and 'team' means everyone can chat", async () => {
    const outsider = await h.user("share-outsider@example.com");
    expect(
      (
        await access(owner.token, {
          visibility: "private",
          entries: [{ user_id: outsider.id, access: "chat" }],
        })
      ).status,
    ).toBe(400);
    await access(owner.token, {
      visibility: "private",
      entries: [{ role: "member", access: "chat" }],
    });
    expect(await sees(ben.token)).toBe(true);
    expect(await yours(ben.token)).toBe("chat");
    await access(owner.token, { visibility: "team", entries: [] });
    expect(await sees(ana.token)).toBe(true);
    const [audit] = await h.tdb.admin<
      { n: number }[]
    >`select count(*)::int as n from public.audit_log where action = 'bot.access_changed'`;
    expect(audit?.n).toBeGreaterThan(3);
  });
});
