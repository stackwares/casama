/**
 * Deleting chats: the person who started one or a manager of its bot deletes it with its messages
 * and media; usage stays; a chat the bot is working in is refused (one) or skipped (all).
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

/** A user message, a photo and a finished run with usage, as a chat leaves behind. */
const fill = async (conv: string) => {
  await h.tdb.admin`insert into public.messages (org_id, conversation_id, role, content)
    values (${orgId}, ${conv}, 'user', '[{"type":"text","text":"hello"}]'::jsonb)`;
  await h.tdb
    .admin`insert into public.chat_media (org_id, bot_id, conversation_id, content_type, bytes, size)
    values (${orgId}, ${botId}, ${conv}, 'image/png', '\\x89504e47'::bytea, 4)`;
  const [run] = await h.tdb.admin<{ id: string }[]>`
    insert into public.runs (org_id, bot_id, conversation_id, trigger, status)
    values (${orgId}, ${botId}, ${conv}, 'chat', 'completed') returning id`;
  return run?.id as string;
};

const count = async (table: "messages" | "chat_media", conv: string) => {
  const rows =
    table === "messages"
      ? await h.tdb.admin<
          { n: number }[]
        >`select count(*)::int as n from public.messages where conversation_id = ${conv}`
      : await h.tdb.admin<
          { n: number }[]
        >`select count(*)::int as n from public.chat_media where conversation_id = ${conv}`;
  return rows[0]?.n ?? 0;
};

beforeAll(async () => {
  h = await startHarness();
  owner = await h.user("delete-owner@example.com");
  member = await h.user("delete-member@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "D" } }),
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

describe("deleting conversations", () => {
  it("says who may delete each chat", async () => {
    const mine = await conversation(member.token);
    const theirs = await conversation(owner.token);
    const list = await j(
      await h.request(`/v1/bots/${botId}/conversations`, { token: member.token }),
    );
    const flag = (id: string) =>
      list.items.find((c: { id: string }) => c.id === id)?.can_delete as boolean;
    expect(flag(mine)).toBe(true);
    expect(flag(theirs)).toBe(false);
    // The bot's creator manages it, so may delete any of its chats.
    const asOwner = await j(
      await h.request(`/v1/bots/${botId}/conversations`, { token: owner.token }),
    );
    expect(asOwner.items.every((c: { can_delete: boolean }) => c.can_delete)).toBe(true);
  });

  it("deletes a chat with its messages and media, keeps the run, and audits it", async () => {
    const conv = await conversation(member.token);
    const run = await fill(conv);
    const res = await h.request(`/v1/conversations/${conv}`, {
      method: "DELETE",
      token: member.token,
    });
    expect(res.status).toBe(200);
    expect(await j(res)).toEqual({ deleted: conv });
    expect(await count("messages", conv)).toBe(0);
    expect(await count("chat_media", conv)).toBe(0);
    const [kept] = await h.tdb.admin<{ conversation_id: string | null }[]>`
      select conversation_id from public.runs where id = ${run}`;
    expect(kept).toEqual({ conversation_id: null });
    const [log] = await h.tdb.admin<{ metadata: Record<string, unknown> }[]>`
      select metadata from public.audit_log where action = 'conversation.deleted' and target_id = ${conv}`;
    expect(log?.metadata).toMatchObject({ bot_id: botId, kind: "direct" });
    expect(JSON.stringify(log?.metadata)).not.toContain("hello");
    // Gone means gone.
    const again = await h.request(`/v1/conversations/${conv}`, {
      method: "DELETE",
      token: member.token,
    });
    expect(again.status).toBe(404);
  });

  it("refuses someone else's chat, and one the bot is still working in", async () => {
    const theirs = await conversation(owner.token);
    const denied = await h.request(`/v1/conversations/${theirs}`, {
      method: "DELETE",
      token: member.token,
    });
    expect(denied.status).toBe(403);

    await h.tdb.admin`insert into public.runs (org_id, bot_id, conversation_id, trigger, status)
      values (${orgId}, ${botId}, ${theirs}, 'chat', 'running')`;
    const busy = await h.request(`/v1/conversations/${theirs}`, {
      method: "DELETE",
      token: owner.token,
    });
    expect(busy.status).toBe(409);
    expect((await j(busy)).code).toBe("conversation_busy");
    await h.tdb
      .admin`update public.runs set status = 'completed' where conversation_id = ${theirs}`;
  });

  it("deletes all of a person's chats with a bot, or all of them for a manager", async () => {
    const a = await conversation(member.token);
    const b = await conversation(member.token);
    const owners = await conversation(owner.token);
    await fill(a);
    await h.tdb.admin`insert into public.runs (org_id, bot_id, conversation_id, trigger, status)
      values (${orgId}, ${botId}, ${b}, 'chat', 'waiting_approval')`;

    const res = await j(
      await h.request(`/v1/bots/${botId}/conversations`, {
        method: "DELETE",
        token: member.token,
      }),
    );
    expect(res.skipped).toBe(1);
    const left = await h.tdb.admin<{ id: string }[]>`
      select id from public.conversations where bot_id = ${botId}`;
    const ids = left.map((r) => r.id);
    expect(ids).not.toContain(a);
    expect(ids).toContain(b);
    expect(ids).toContain(owners);
    expect(await count("chat_media", a)).toBe(0);

    await h.tdb.admin`update public.runs set status = 'completed' where conversation_id = ${b}`;
    const all = await j(
      await h.request(`/v1/bots/${botId}/conversations`, {
        method: "DELETE",
        token: owner.token,
      }),
    );
    expect(all.skipped).toBe(0);
    const [rest] = await h.tdb.admin<{ n: number }[]>`
      select count(*)::int as n from public.conversations where bot_id = ${botId}`;
    expect(rest?.n).toBe(0);
  });
});
