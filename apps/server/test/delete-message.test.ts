/**
 * Deleting one message (Add 11): the sender or whoever may delete the chat; the messages after it
 * are joined to the one before it, and the chat's head moves back when the last one goes.
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

/** Three messages in a row: the person, the bot, the person. */
const thread = async (conv: string, author: string) => {
  const ids: string[] = [];
  for (const [role, text] of [
    ["user", "hello"],
    ["assistant", "hi there"],
    ["user", "thanks"],
  ] as const) {
    const [row] = await h.tdb.admin<{ id: string }[]>`
      insert into public.messages (org_id, conversation_id, role, author_user_id, content)
      values (${orgId}, ${conv}, ${role}, ${role === "user" ? author : null},
        ${JSON.stringify([{ type: "text", text }])}::jsonb) returning id`;
    ids.push(row?.id as string);
  }
  return ids as [string, string, string];
};

const del = (conv: string, msg: string, token: string) =>
  h.request(`/v1/conversations/${conv}/messages/${msg}`, { method: "DELETE", token });

beforeAll(async () => {
  h = await startHarness();
  owner = await h.user("delmsg-owner@example.com");
  member = await h.user("delmsg-member@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "M" } }),
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

describe("deleting a message", () => {
  it("deletes a middle message and joins the rest", async () => {
    const conv = await conversation(member.token);
    const [first, reply, last] = await thread(conv, member.id);
    const res = await del(conv, reply, member.token);
    expect(res.status).toBe(200);
    const rows = await h.tdb.admin<{ id: string; parent: string | null }[]>`
      select id, parent_message_id as parent from public.messages
      where conversation_id = ${conv} order by created_at`;
    expect(rows.map((r) => r.id)).toEqual([first, last]);
    expect(rows[1]?.parent).toBe(first);
  });

  it("moves the head back when the last message goes", async () => {
    const conv = await conversation(member.token);
    const [, reply, last] = await thread(conv, member.id);
    expect((await del(conv, last, member.token)).status).toBe(200);
    const [c] = await h.tdb.admin<{ head: string | null }[]>`
      select head_message_id as head from public.conversations where id = ${conv}`;
    expect(c?.head).toBe(reply);
  });

  it("refuses someone else's message in someone else's chat", async () => {
    const conv = await conversation(owner.token);
    const [first] = await thread(conv, owner.id);
    expect((await del(conv, first, member.token)).status).toBe(403);
    // The bot's manager may.
    expect((await del(conv, first, owner.token)).status).toBe(200);
  });

  it("refuses while the bot is working in the chat", async () => {
    const conv = await conversation(member.token);
    const [first] = await thread(conv, member.id);
    await h.tdb.admin`insert into public.runs (org_id, bot_id, conversation_id, trigger, status)
      values (${orgId}, ${botId}, ${conv}, 'chat', 'running')`;
    expect((await del(conv, first, member.token)).status).toBe(409);
  });

  it("404s for a message in another chat", async () => {
    const a = await conversation(member.token);
    const b = await conversation(member.token);
    const [first] = await thread(a, member.id);
    expect((await del(b, first, member.token)).status).toBe(404);
  });
});
