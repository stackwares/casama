/**
 * Renaming and pinning chats (Improve app 2): the person who started one or a manager of its bot
 * may; a pinned chat lists after General and before the rest.
 */
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
let owner: { id: string; token: string };
let member: { id: string; token: string };
let orgId: string;
let botId: string;

const conversation = async (token: string) =>
  (
    await j(
      await h.request("/v1/conversations", { method: "POST", token, json: { bot_id: botId } }),
    )
  ).id as string;

const patch = (id: string, token: string, json: Record<string, unknown>) =>
  h.request(`/v1/conversations/${id}`, { method: "PATCH", token, json });

beforeAll(async () => {
  h = await startHarness();
  owner = await h.user("rename-owner@example.com");
  member = await h.user("rename-member@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "R" } }),
    )
  ).id;
  await h.tdb
    .admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${member.id}, 'member')`;
  botId = (
    await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, name: "Ada", visibility: "team" },
      }),
    )
  ).id;
}, 120_000);
afterAll(async () => {
  await h?.stop();
});

describe("renaming and pinning conversations", () => {
  it("renames a topic and clears the name again", async () => {
    await conversation(member.token); // General
    const topic = await conversation(member.token);
    const renamed = await j(await patch(topic, member.token, { title: "  Q3 report  " }));
    expect(renamed.title).toBe("Q3 report");
    expect(renamed.pinned).toBe(false);
    const cleared = await j(await patch(topic, member.token, { title: "" }));
    expect(cleared.title).toBeNull();
  });

  it("pins a topic so it lists right after General", async () => {
    const general = await conversation(owner.token);
    const older = await conversation(owner.token);
    await conversation(owner.token); // newest
    const pinned = await j(await patch(older, owner.token, { pinned: true }));
    expect(pinned.pinned).toBe(true);
    const list = await j(
      await h.request(`/v1/bots/${botId}/conversations`, { token: owner.token }),
    );
    const ids = list.items.map((c: { id: string }) => c.id);
    expect(ids[0]).toBe(general);
    expect(ids[1]).toBe(older);
    const unpinned = await j(await patch(older, owner.token, { pinned: false }));
    expect(unpinned.pinned).toBe(false);
  });

  it("refuses someone who neither started it nor manages the bot", async () => {
    const theirs = await conversation(owner.token);
    const res = await patch(theirs, member.token, { title: "Mine now" });
    expect(res.status).toBe(403);
    const [row] = await h.tdb.admin<{ title: string | null }[]>`
      select title from public.conversations where id = ${theirs}`;
    expect(row?.title).toBeNull();
  });

  it("lets a manager rename someone else's chat", async () => {
    const mine = await conversation(member.token);
    const res = await patch(mine, owner.token, { title: "Renamed by the owner" });
    expect(res.status).toBe(200);
  });

  it("404s for a chat that isn't there", async () => {
    const res = await patch("00000000-0000-4000-8000-000000000000", owner.token, { pinned: true });
    expect(res.status).toBe(404);
  });
});
