/**
 * Chat apps (D-413): an answer goes where its own question came from. A Telegram forum topic is
 * answered in that topic, and each run answers with the target its own message brought, so a
 * second Discord command can't take the first one's answer.
 */
import { createDb, type DbHandle } from "@casama/db";
import { createAuthUser, startTestDatabase, type TestDatabase } from "@casama/db/testing";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import {
  ADAPTERS,
  handleInbound,
  loadChannel,
  postApprovalToChannel,
  replyToChannel,
  type WebhookRequest,
} from "../src/channels/index.ts";

const req = (body: unknown): WebhookRequest => ({
  method: "POST",
  url: "https://api.example.com/hooks/channels/x",
  headers: {},
  body: JSON.stringify(body),
});

/** A fetch that records what was sent and says yes. */
function recorder() {
  const calls: Array<{ url: string; body: Record<string, unknown> }> = [];
  const f = (async (url: string, init: RequestInit = {}) => {
    const body =
      typeof init.body === "string"
        ? (JSON.parse(init.body) as Record<string, unknown>)
        : init.body instanceof FormData
          ? Object.fromEntries([...init.body.entries()].map(([k, v]) => [k, String(v)]))
          : {};
    calls.push({ url: String(url), body });
    return new Response(JSON.stringify({ ok: true, result: { message_id: 1 } }), { status: 200 });
  }) as unknown as typeof fetch;
  return { calls, f };
}

describe("Telegram groups with topics", () => {
  const a = ADAPTERS.telegram;
  const cfg = { api_base: "http://telegram.test" };
  const message = (extra: Record<string, unknown>) => ({
    update_id: 7,
    message: {
      message_id: 55,
      chat: { id: -100123, type: "supergroup", is_forum: true },
      from: { id: 42, first_name: "Ana" },
      text: "status?",
      ...extra,
    },
  });

  it("a topic is its own thread, and the answer, the typing and an approval go to that topic", async () => {
    const [m] = a.normalize(req(message({ is_topic_message: true, message_thread_id: 9 })), {});
    expect(m).toMatchObject({
      threadKey: "chat:-100123:topic:9",
      reply: { chat_id: -100123, message_thread_id: 9 },
    });
    const { calls, f } = recorder();
    const reply = m?.reply as Record<string, unknown>;
    await a.send(cfg, { bot_token: "t" }, reply, "All good.", f);
    await a.typing?.(cfg, { bot_token: "t" }, reply, f);
    await a.sendApproval?.(cfg, { bot_token: "t" }, reply, { id: "a1", summary: "Send it?" }, f);
    // Before, none of them named the topic, so all three landed in the group's General topic.
    expect(calls.map((c) => c.body.message_thread_id)).toEqual([9, 9, 9]);
    expect(calls.map((c) => c.body.chat_id)).toEqual([-100123, -100123, -100123]);
  });

  it("a chat without topics is one thread, answered as before", async () => {
    // A reply in an ordinary group has a thread id too; only topic messages are topics.
    const [m] = a.normalize(req(message({ message_thread_id: 3 })), {});
    expect(m).toMatchObject({ threadKey: "chat:-100123", reply: { chat_id: -100123 } });
    const { calls, f } = recorder();
    await a.send(cfg, { bot_token: "t" }, m?.reply as Record<string, unknown>, "Hi.", f);
    expect(calls[0]?.body).not.toHaveProperty("message_thread_id");
  });
});

describe("each run answers where its own message came from", () => {
  let tdb: TestDatabase;
  let h: DbHandle;
  let channelId: string;

  beforeAll(async () => {
    tdb = await startTestDatabase();
    h = createDb(tdb.url, { max: 5 });
    const user = await createAuthUser(tdb.admin, "discord-owner@example.com");
    const [org] = await tdb.admin<{ id: string }[]>`
      insert into public.organizations (name, slug) values ('Reply Org', 'reply-org') returning id`;
    await tdb.admin`insert into public.memberships (org_id, user_id, role) values (${org!.id}, ${user.id}, 'owner')`;
    const [bot] = await tdb.admin<{ id: string }[]>`
      insert into public.bots (org_id, created_by, name) values (${org!.id}, ${user.id}, 'Ada') returning id`;
    const [channel] = await tdb.admin<{ id: string }[]>`
      insert into public.channels (org_id, bot_id, kind, name, config, allowed_senders, created_by)
      values (${org!.id}, ${bot!.id}, 'discord', 'Server', ${tdb.admin.json({ api_base: "http://discord.test" })}, '{u1}', ${user.id})
      returning id`;
    channelId = channel!.id;
  });
  afterAll(async () => {
    await h?.close();
    await tdb?.stop();
  });

  const command = (id: string, token: string, text: string) => ({
    messageId: id,
    threadKey: "discord:ch1",
    sender: "u1",
    senderName: "Ana",
    text,
    reply: { channel_id: "ch1", application_id: "app1", token, at: Date.now() },
  });

  it("two commands in one channel: each answer, and each approval, goes to its own command", async () => {
    const c = await loadChannel(h.db, channelId);
    const deps = { startRoutine: async () => null };
    // The second command arrives while the first is still being answered.
    const [first] = await handleInbound(h.db, c!, [command("i1", "token-one", "summarize")], deps);
    const [second] = await handleInbound(h.db, c!, [command("i2", "token-two", "translate")], deps);
    const [conv] = await tdb.admin<{ conversation_id: string }[]>`
      select conversation_id from public.runs where id = ${first!}`;

    const { calls, f } = recorder();
    await replyToChannel(
      h.db,
      { conversationId: conv!.conversation_id, runId: first },
      "The summary.",
      f,
    );
    await replyToChannel(
      h.db,
      { conversationId: conv!.conversation_id, runId: second },
      "The translation.",
      f,
    );
    // Words said before acting carry no files, and still go to their own command.
    await replyToChannel(
      h.db,
      { conversationId: conv!.conversation_id, speakingRunId: first },
      "On it.",
      f,
    );
    // Before, all of them went to the newest command's token; the first stayed on "thinking…".
    expect(calls.map((x) => [x.url.split("/").at(-1), x.body.content])).toEqual([
      ["token-one", "The summary."],
      ["token-two", "The translation."],
      ["token-one", "On it."],
    ]);
  });

  it("a reply with no run of its own goes to the thread's newest message, as before", async () => {
    const [conv] = await tdb.admin<{ conversation_id: string }[]>`
      select conversation_id from public.channel_threads where channel_id = ${channelId}`;
    const { calls, f } = recorder();
    await replyToChannel(h.db, { conversationId: conv!.conversation_id }, "A routine's news.", f);
    expect(calls[0]?.url.endsWith("/token-two")).toBe(true);
    // Discord has no approval buttons here: nothing is posted, and nothing throws.
    expect(
      await postApprovalToChannel(h.db, conv!.conversation_id, { id: "a1", summary: "x" }, f),
    ).toBe(false);
  });
});
