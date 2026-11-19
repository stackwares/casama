/**
 * Sends that arrive together (D-413): two devices of one account at the same moment, a message
 * typed while a routine works in the chat, and a group send that is retried.
 */
import { randomUUID } from "node:crypto";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
let ana: { id: string; token: string };
let org: string;
let bot: string;

const newBot = async (name: string) =>
  (
    await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: ana.token,
        json: { org_id: org, name },
      }),
    )
  ).id as string;

const newChat = async (botId: string, more: string[] = []) =>
  (
    await j(
      await h.request("/v1/conversations", {
        method: "POST",
        token: ana.token,
        json: more.length ? { bot_id: botId, bot_ids: more, title: "Team" } : { bot_id: botId },
      }),
    )
  ).id as string;

const send = (conversationId: string, text: string, key?: string) =>
  h.request(`/v1/conversations/${conversationId}/messages`, {
    method: "POST",
    token: ana.token,
    json: { text },
    ...(key ? { headers: { "idempotency-key": key } } : {}),
  });

const runsIn = (conversationId: string) =>
  h.tdb.admin<{ id: string; trigger: string }[]>`
    select id, trigger from public.runs where conversation_id = ${conversationId} order by created_at`;

/** What the app shows: the branch ending at the conversation's head. */
const thread = async (conversationId: string) =>
  (
    await h.tdb.admin<{ content: Array<{ text?: string }> }[]>`
      select content from public.conversation_thread(${conversationId})`
  ).map((r) => r.content[0]?.text);

beforeAll(async () => {
  h = await startHarness({});
  ana = await h.user("two-devices@example.com");
  org = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: ana.token, json: { name: "Two" } }),
    )
  ).id;
  await h.tdb
    .admin`update public.entitlements set limits = limits - 'max_bots' where org_id = ${org}`;
  bot = await newBot("Ada");
}, 60_000);
afterAll(async () => {
  await h?.stop();
});

describe("sends that arrive together", () => {
  it("two devices sending at the same moment get one run, and both messages stay in the chat", async () => {
    const chat = await newChat(bot);
    // Several rounds: without the lock both sends found no run working and each started one.
    const texts = ["from the phone", "from the desktop", "from the web", "from the tablet"];
    const answers = await Promise.all(texts.map((t) => send(chat, t)));
    expect(answers.map((r) => r.status)).toEqual([202, 202, 202, 202]);
    const bodies = await Promise.all(answers.map((r) => j(r)));
    const runs = await runsIn(chat);
    expect(runs).toHaveLength(1);
    expect(new Set(bodies.map((b) => b.run_id))).toEqual(new Set([runs[0]?.id]));
    // One of them started the run; the others joined it.
    expect(bodies.filter((b) => b.joined === true)).toHaveLength(3);
    expect((await thread(chat)).sort()).toEqual([...texts].sort());
  });

  it("a message typed while a routine works in the chat gets its own run", async () => {
    const chat = await newChat(bot);
    const [brief] = await h.tdb.admin<{ id: string }[]>`
      insert into public.runs (org_id, bot_id, conversation_id, created_by, trigger, status)
      values (${org}, ${bot}, ${chat}, ${ana.id}, 'routine', 'running') returning id`;
    await h.tdb.admin`
      insert into public.messages (org_id, conversation_id, role, author_user_id, content, run_id)
      values (${org}, ${chat}, 'user', ${ana.id}, ${h.tdb.admin.json([{ type: "text", text: "Write the morning brief" }])}, ${brief!.id})`;
    const sent = await j(await send(chat, "what's on my calendar?"));
    expect(sent.joined).toBeUndefined();
    expect(sent.run_id).not.toBe(brief!.id);
    expect((await runsIn(chat)).map((r) => r.trigger)).toEqual(["routine", "chat"]);
    // The next message joins the run the person's own message started, not the routine's.
    const more = await j(await send(chat, "and tomorrow?"));
    expect(more).toMatchObject({ run_id: sent.run_id, joined: true });
    await h.tdb
      .admin`update public.runs set status = 'completed', ended_at = now() where conversation_id = ${chat}`;
  });

  it("a group send retried with the same key posts once and wakes each bot once", async () => {
    const lead = await newBot("Lead");
    const writer = await newBot("Writer");
    const chat = await newChat(lead, [writer]);
    const key = randomUUID();
    const first = await j(await send(chat, "@Lead @Writer plan the launch", key));
    expect(first.message_id).toBe(key);
    expect(first.run_ids).toHaveLength(2);
    // The app got no answer and sends it again; and once more while a copy is still in flight.
    const [again, twice] = await Promise.all([
      send(chat, "@Lead @Writer plan the launch", key),
      send(chat, "@Lead @Writer plan the launch", key),
    ]);
    for (const r of [again, twice]) {
      expect(r.status).toBe(202);
      expect(await j(r)).toMatchObject({
        message_id: key,
        run_id: first.run_id,
        run_ids: first.run_ids,
      });
    }
    expect(await runsIn(chat)).toHaveLength(2);
    expect(await thread(chat)).toEqual(["@Lead @Writer plan the launch"]);
  });

  it("two copies of a new group send at the same moment post it once", async () => {
    const lead = await newBot("Lead Two");
    const chat = await newChat(lead, [await newBot("Writer Two")]);
    const key = randomUUID();
    const [a, b] = await Promise.all([
      send(chat, "@Lead Two start", key),
      send(chat, "@Lead Two start", key),
    ]);
    expect([a.status, b.status]).toEqual([202, 202]);
    const [x, y] = [await j(a), await j(b)];
    expect(x.message_id).toBe(key);
    expect(y).toMatchObject({ message_id: key, run_id: x.run_id });
    expect(await runsIn(chat)).toHaveLength(1);
    expect(await thread(chat)).toEqual(["@Lead Two start"]);
  });
});
