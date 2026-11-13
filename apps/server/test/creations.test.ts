/**
 * The Library (D-274): pages and generated media appear on their own, visibility follows where
 * they were made, and pins, renames, deleting with Undo and the purge work.
 */
import { purgeDeletedCreations } from "@casama/agent";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
let owner: { id: string; token: string };
let member: { id: string; token: string };
let orgId = "";
let botId = "";
let convId = "";

beforeAll(async () => {
  h = await startHarness();
  owner = await h.user("lib-owner@example.com");
  member = await h.user("lib-member@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "Lib" } }),
    )
  ).id;
  await h.tdb
    .admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${member.id}, 'member')`;
  botId = (
    await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, name: "Maker" },
      }),
    )
  ).id;
  convId = (
    await j(
      await h.request("/v1/conversations", {
        method: "POST",
        token: owner.token,
        json: { bot_id: botId },
      }),
    )
  ).id;
}, 60_000);
afterAll(async () => h?.stop());

const media = async (name: string, type: string, conversation: string | null = convId) => {
  const [m] = await h.tdb.admin<{ id: string }[]>`
    insert into public.chat_media (org_id, bot_id, conversation_id, name, content_type, bytes, size)
    values (${orgId}, ${botId}, ${conversation}, ${name}, ${type}, ${Buffer.from("0123456789")}, 10)
    returning id`;
  return m!.id;
};
const list = async (token: string, query = "") =>
  j(await h.request(`/v1/creations?org_id=${orgId}${query}`, { token }));

describe("the Library (D-274)", () => {
  it("fills itself from pages and media, newest first, with kinds for the filter chips", async () => {
    await h.tdb.admin`
      insert into public.pages (org_id, bot_id, created_by, title, html, visibility)
      values (${orgId}, ${botId}, ${owner.id}, 'Launch tracker', '<p>hi</p>', 'workspace')`;
    await media("beach.png", "image/png");
    await media("teaser.mp4", "video/mp4");
    const all = await list(owner.token);
    expect(all.items.map((c: { title: string }) => c.title)).toEqual([
      "teaser",
      "beach",
      "Launch tracker",
    ]);
    expect(all.kinds).toEqual(["image", "page", "video"]);
    expect(all.items[1]).toMatchObject({
      kind: "image",
      has_cover: true,
      bot_name: "Maker",
      can_change: true,
    });
    const images = await list(owner.token, "&kind=image");
    expect(images.items).toHaveLength(1);
    expect(
      (await list(owner.token, "&q=track")).items.map((c: { title: string }) => c.title),
    ).toEqual(["Launch tracker"]);
  });

  it("pages through results with a cursor", async () => {
    const first = await list(owner.token, "&limit=2");
    expect(first, JSON.stringify(first)).toHaveProperty("items");
    expect(first.items).toHaveLength(2);
    expect(first.next_cursor).toBeTruthy();
    const next = await list(owner.token, `&limit=2&cursor=${first.next_cursor}`);
    expect(next.items.map((c: { title: string }) => c.title)).toEqual(["Launch tracker"]);
    expect(next.next_cursor).toBeNull();
  });

  it("serves the bytes with byte ranges, and a picture as its own cover", async () => {
    const beach = (await list(owner.token, "&kind=image")).items[0];
    const full = await h.request(`/v1/creations/${beach.id}/content`, { token: owner.token });
    expect(full.status).toBe(200);
    expect(await full.text()).toBe("0123456789");
    const part = await h.request(`/v1/creations/${beach.id}/content`, {
      token: owner.token,
      headers: { range: "bytes=2-4" },
    });
    expect(part.status).toBe(206);
    expect(await part.text()).toBe("234");
    expect(
      (await h.request(`/v1/creations/${beach.id}/cover`, { token: owner.token })).status,
    ).toBe(200);
  });

  it("pins and recently opened are per person; renames are for the owner or managers", async () => {
    const beach = (await list(owner.token, "&kind=image")).items[0];
    await h.request(`/v1/creations/${beach.id}`, {
      method: "PATCH",
      token: owner.token,
      json: { pinned: true, opened: true },
    });
    expect((await list(owner.token, "&pinned=true")).items).toHaveLength(1);
    expect((await list(member.token, "&pinned=true")).items).toHaveLength(0);
    expect(
      (await list(owner.token, "&sort=opened")).items.map((c: { id: string }) => c.id),
    ).toEqual([beach.id]);
    const denied = await h.request(`/v1/creations/${beach.id}`, {
      method: "PATCH",
      token: member.token,
      json: { title: "Mine now" },
    });
    expect(denied.status).toBe(403);
    const renamed = await j(
      await h.request(`/v1/creations/${beach.id}`, {
        method: "PATCH",
        token: owner.token,
        json: { title: "Beach at dusk", label: "Poster" },
      }),
    );
    expect(renamed).toMatchObject({ title: "Beach at dusk", label: "Poster", pinned: true });
  });

  it("delete hides it with Undo; the purge removes it and its bytes after 30 days", async () => {
    const teaser = (await list(owner.token, "&kind=video")).items[0];
    expect(
      (await h.request(`/v1/creations/${teaser.id}`, { method: "DELETE", token: member.token }))
        .status,
    ).toBe(403);
    await h.request(`/v1/creations/${teaser.id}`, { method: "DELETE", token: owner.token });
    expect((await list(owner.token, "&kind=video")).items).toHaveLength(0);
    expect(
      (await list(owner.token, "&deleted=true")).items.map((c: { id: string }) => c.id),
    ).toEqual([teaser.id]);
    await h.request(`/v1/creations/${teaser.id}/restore`, { method: "POST", token: owner.token });
    expect((await list(owner.token, "&kind=video")).items).toHaveLength(1);

    await h.request(`/v1/creations/${teaser.id}`, { method: "DELETE", token: owner.token });
    expect(await purgeDeletedCreations(h.handle.db)).toBe(0);
    await h.tdb
      .admin`update public.creations set deleted_at = now() - interval '31 days' where id = ${teaser.id}`;
    expect(await purgeDeletedCreations(h.handle.db)).toBe(1);
    expect(
      await h.tdb.admin`select 1 from public.chat_media where id = ${teaser.media_id}`,
    ).toHaveLength(0);
    expect(await h.tdb.admin`select 1 from public.creations where id = ${teaser.id}`).toHaveLength(
      0,
    );
  });

  it("deleting a chat keeps what was made, private to its person, unless asked to delete it too", async () => {
    const own = (
      await j(
        await h.request("/v1/conversations", {
          method: "POST",
          token: owner.token,
          json: { bot_id: botId },
        }),
      )
    ).id;
    const kept = await media("kept.png", "image/png", own);
    const del = await h.request(`/v1/conversations/${own}`, {
      method: "DELETE",
      token: owner.token,
    });
    expect(del.status).toBe(200);
    const [row] = await h.tdb.admin<{ conversation_id: string | null; made_for: string }[]>`
      select conversation_id, made_for from public.creations where media_id = ${kept}`;
    expect(row).toEqual({ conversation_id: null, made_for: owner.id });
    expect((await list(owner.token, "&q=kept")).items).toHaveLength(1);
    expect((await list(member.token, "&q=kept")).items).toHaveLength(0);

    const other = (
      await j(
        await h.request("/v1/conversations", {
          method: "POST",
          token: owner.token,
          json: { bot_id: botId },
        }),
      )
    ).id;
    const gone = await media("gone.png", "image/png", other);
    await h.request(`/v1/conversations/${other}?with_creations=true`, {
      method: "DELETE",
      token: owner.token,
    });
    expect(await h.tdb.admin`select 1 from public.chat_media where id = ${gone}`).toHaveLength(0);
  });

  it("an outsider can't see or open anything", async () => {
    const stranger = await h.user("lib-stranger@example.com");
    expect((await list(stranger.token)).items).toHaveLength(0);
    const any = (await list(owner.token)).items[0];
    expect((await h.request(`/v1/creations/${any.id}`, { token: stranger.token })).status).toBe(
      404,
    );
  });
});
