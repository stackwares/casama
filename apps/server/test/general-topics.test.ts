/**
 * General and topics (D-253): one General conversation per person and bot, other chats as topics
 * under it, briefs and suggestion cards posted in General, Do it opening a topic that posts its
 * result back, and nothing posted into General while a run is working there.
 */
import { fileURLToPath } from "node:url";
import { applyCheckins, postSuggestions, postTopicResults, resultLine } from "@casama/agent";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { claimDueRoutines } from "../src/worker/routines.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = fileURLToPath(new URL("./fixtures/general-topics.json", import.meta.url));
let h: Harness;
let owner: { id: string; token: string };
let orgId: string;
let botId: string;
let generalId: string;

type Part = { type: string; text?: string; suggestion_id?: string; conversation_id?: string };
const settle = async () => {
  for (let i = 0; i < 200; i++) {
    const [r] = await h.tdb.admin<{ n: number }[]>`
      select count(*)::int as n from public.runs where status in ('queued', 'running')`;
    if (!r?.n) return;
    await new Promise((res) => setTimeout(res, 100));
  }
  throw new Error("runs did not settle");
};
const thread = (conversationId: string) =>
  h.tdb.admin<{ id: string; role: string; content: Part[]; run_id: string | null }[]>`
    select id, role, content, run_id from public.conversation_thread(${conversationId})`;
const list = async () =>
  (await j(await h.request(`/v1/bots/${botId}/conversations`, { token: owner.token }))).items as {
    id: string;
    is_main: boolean;
    parent_conversation_id: string | null;
    anchor_message_id: string | null;
    status: string | null;
  }[];
const newChat = async () =>
  j(
    await h.request("/v1/conversations", {
      method: "POST",
      token: owner.token,
      json: { bot_id: botId },
    }),
  );
const send = async (conversationId: string, text: string) => {
  const sent = await j(
    await h.request(`/v1/conversations/${conversationId}/messages`, {
      method: "POST",
      token: owner.token,
      json: { text },
    }),
  );
  await settle();
  return sent;
};
const addSuggestion = async (title: string, pushText: string) => {
  const [s] = await h.tdb.admin<{ id: string }[]>`
    insert into public.suggestions (org_id, bot_id, user_id, title, body_md, push_text)
    values (${orgId}, ${botId}, ${owner.id}, ${title}, 'Concert at 8.', ${pushText}) returning id`;
  return s?.id as string;
};

beforeAll(async () => {
  h = await startHarness({ worker: { fixtures: FIXTURES } });
  owner = await h.user("general@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "G" } }),
    )
  ).id;
  const cred = await j(
    await h.request("/v1/credentials", {
      method: "POST",
      token: owner.token,
      json: { org_id: orgId, provider: "openrouter", label: "k", api_key: "sk-or-v1-abcdefabcdef" },
    }),
  );
  botId = (
    await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: owner.token,
        json: {
          org_id: orgId,
          name: "Aide",
          model_policy: { primary: { credential_id: cred.id, model: "fixture-main" } },
        },
      }),
    )
  ).id;
}, 60_000);
afterAll(async () => h?.stop());

describe("General and topics", () => {
  it("the first chat is General; later ones are topics under it, listed after it", async () => {
    const first = await newChat();
    expect(first.is_main).toBe(true);
    generalId = first.id;
    const topic = await newChat();
    expect(topic).toMatchObject({ is_main: false, parent_conversation_id: generalId });
    await send(topic.id, "hello there");
    const items = await list();
    expect(items[0]).toMatchObject({ id: generalId, is_main: true });
    expect(items.map((c) => c.id)).toContain(topic.id);
  });

  it("briefs post in General", async () => {
    await applyCheckins(h.handle.db, {
      orgId,
      botId,
      userId: owner.id,
      enabled: true,
      briefTime: "08:00",
      scanEveryHours: 6,
      dailyCapUsd: 1,
    });
    await h.tdb.admin`
      update public.routines set next_run_at = now() - interval '1 minute' where bot_id = ${botId} and kind = 'brief'`;
    const ids = await claimDueRoutines(h.handle.db);
    expect(ids).toHaveLength(1);
    for (const id of ids) await h.deps.workflows.startRun(id);
    await settle();
    const [run] = await h.tdb.admin<{ conversation_id: string }[]>`
      select conversation_id from public.runs where id = ${ids[0] as string}`;
    expect(run?.conversation_id).toBe(generalId);
    const texts = (await thread(generalId)).map((m) => m.content[0]?.text);
    expect(texts).toContain("Morning! Two meetings today and nothing urgent.");
  });

  it("a suggestion becomes a card in General", async () => {
    const id = await addSuggestion("Book a ride", "Want me to book a ride to the concert at 7?");
    expect(await postSuggestions(h.handle.db)).toBe(1);
    const card = (await thread(generalId)).at(-1);
    expect(card?.role).toBe("assistant");
    expect(card?.run_id).toBeNull();
    // Only the card (D-257): the bot's own line is its body, no separate bubble above it.
    expect(card?.content).toHaveLength(1);
    expect(card?.content[0]).toMatchObject({
      type: "suggestion",
      suggestion_id: id,
      title: "Book a ride",
      body: "Want me to book a ride to the concert at 7?",
    });
    const [s] = await h.tdb.admin<{ message_id: string }[]>`
      select message_id from public.suggestions where id = ${id}`;
    expect(s?.message_id).toBe(card?.id);
    // Posted once.
    expect(await postSuggestions(h.handle.db)).toBe(0);
  });

  it("Do it opens a topic from the card, which posts its result back to General once", async () => {
    const [s] = await h.tdb.admin<{ id: string; message_id: string }[]>`
      select id, message_id from public.suggestions where title = 'Book a ride'`;
    const accepted = await j(
      await h.request(`/v1/suggestions/${s?.id}/accept`, { method: "POST", token: owner.token }),
    );
    await settle();
    const topic = (await list()).find((c) => c.id === accepted.conversation_id);
    expect(topic).toMatchObject({
      is_main: false,
      parent_conversation_id: generalId,
      anchor_message_id: s?.message_id,
    });
    // The run's own completion step posts it; the sweep finds nothing left.
    let back: Part[] | undefined;
    for (let i = 0; i < 50 && !back; i++) {
      back = (await thread(generalId)).find((m) => m.content[1]?.type === "topic")?.content;
      if (!back) await new Promise((res) => setTimeout(res, 100));
    }
    expect(back?.[0]?.text).toBe("Booked an Uber for 7:15 tonight.");
    expect(back?.[1]).toMatchObject({ type: "topic", conversation_id: accepted.conversation_id });
    expect(await postTopicResults(h.handle.db)).toBe(0);
    // The person's follow-up in the topic stays in the topic.
    await send(accepted.conversation_id, "make it 7:30");
    expect(await postTopicResults(h.handle.db)).toBe(0);
    const posts = (await thread(generalId)).filter((m) => m.content[1]?.type === "topic");
    expect(posts).toHaveLength(1);
  });

  it("nothing is posted into General while a run works there; the sweep posts it after", async () => {
    const [busy] = await h.tdb.admin<{ id: string }[]>`
      insert into public.runs (org_id, bot_id, conversation_id, created_by, status)
      values (${orgId}, ${botId}, ${generalId}, ${owner.id}, 'running') returning id`;
    await addSuggestion("Pay the Acme invoice", "The Acme invoice is due tomorrow. Pay it?");
    expect(await postSuggestions(h.handle.db)).toBe(0);
    await h.tdb
      .admin`update public.runs set status = 'completed', ended_at = now() where id = ${busy?.id as string}`;
    expect(await postSuggestions(h.handle.db)).toBe(1);
  });

  it("an unanswered card holds new suggestions back; answering it lets the next in (D-257)", async () => {
    const [acme] = await h.tdb.admin<{ id: string }[]>`
      select id from public.suggestions where title = 'Pay the Acme invoice'`;
    const next = await addSuggestion(
      "Renew the domain",
      "Your domain renews Friday. Renew it now?",
    );
    // General ends in the Acme card, still pending: nothing new stacks on it.
    expect(await postSuggestions(h.handle.db)).toBe(0);
    await h.request(`/v1/suggestions/${acme?.id}/dismiss`, {
      method: "POST",
      token: owner.token,
      json: { dont_suggest_again: false },
    });
    let posted: string | null = null;
    for (let i = 0; i < 50 && !posted; i++) {
      await postSuggestions(h.handle.db);
      const [r] = await h.tdb.admin<{ message_id: string | null }[]>`
        select message_id from public.suggestions where id = ${next}`;
      posted = r?.message_id ?? null;
      if (!posted) await new Promise((res) => setTimeout(res, 100));
    }
    expect(posted).toBeTruthy();
  });

  it("several waiting suggestions come as one list card (D-257)", async () => {
    const [renew] = await h.tdb.admin<{ id: string }[]>`
      select id from public.suggestions where title = 'Renew the domain'`;
    await h.request(`/v1/suggestions/${renew?.id}/dismiss`, {
      method: "POST",
      token: owner.token,
      json: { dont_suggest_again: false },
    });
    await new Promise((res) => setTimeout(res, 300));
    const ids = [
      await addSuggestion("Reply to Ana", "Ana asked twice. Reply?"),
      await addSuggestion("Check the Cloud bill", "Google Cloud is at 50% of its cap. Look?"),
      await addSuggestion("File the receipt", "A receipt came in. File it?"),
    ];
    expect(await postSuggestions(h.handle.db)).toBe(3);
    const card = (await thread(generalId)).at(-1) as {
      content: Array<Part & { items?: Array<{ suggestion_id: string }> }>;
    };
    expect(card.content).toHaveLength(1);
    expect(card.content[0]?.type).toBe("suggestions");
    expect(card.content[0]?.items?.map((i) => i.suggestion_id)).toEqual(ids);
  });

  it("a status shows what each chat waits on", async () => {
    const topic = await newChat();
    await h.tdb.admin`
      insert into public.runs (org_id, bot_id, conversation_id, created_by, status)
      values (${orgId}, ${botId}, ${topic.id}, ${owner.id}, 'waiting_approval')`;
    expect((await list()).find((c) => c.id === topic.id)?.status).toBe("needs_you");
    await h.tdb
      .admin`update public.runs set status = 'cancelled' where conversation_id = ${topic.id}`;
    expect((await list()).find((c) => c.id === topic.id)?.status).toBeNull();
  });

  it("deleting General makes the latest remaining chat General", async () => {
    await h.tdb
      .admin`update public.runs set status = 'completed' where conversation_id = ${generalId} and status <> 'completed'`;
    const res = await h.request(`/v1/conversations/${generalId}`, {
      method: "DELETE",
      token: owner.token,
    });
    expect(res.status).toBe(200);
    const items = await list();
    const mains = items.filter((c) => c.is_main);
    expect(mains).toHaveLength(1);
    expect(items[0]?.id).toBe(mains[0]?.id);
    expect(
      items.filter((c) => !c.is_main).every((c) => c.parent_conversation_id === mains[0]?.id),
    ).toBe(true);
  });

  it("a chat app's thread, a ticket or a watcher never becomes General or a topic", async () => {
    const other = (
      await j(
        await h.request("/v1/bots", {
          method: "POST",
          token: owner.token,
          json: { org_id: orgId, name: "Other" },
        }),
      )
    ).id as string;
    // Made the way the chat-app, ticket and watcher code makes them: no personal flag.
    const [thread] = await h.tdb.admin<{ id: string; is_main: boolean; parent: string | null }[]>`
      insert into public.conversations (org_id, bot_id, title, created_by)
      values (${orgId}, ${other}, 'WhatsApp: Ana', ${owner.id})
      returning id, is_main, parent_conversation_id as parent`;
    expect(thread).toMatchObject({ is_main: false, parent: null });
    // The person's first own chat with the bot is General.
    const mine = await j(
      await h.request("/v1/conversations", {
        method: "POST",
        token: owner.token,
        json: { bot_id: other },
      }),
    );
    expect(mine.is_main).toBe(true);
  });

  it("suggestions from before General stay out of it", async () => {
    const id = await addSuggestion("An old idea", "Remember this?");
    await h.tdb.admin`update public.suggestions set post_card = false where id = ${id}`;
    expect(await postSuggestions(h.handle.db)).toBe(0);
  });

  it("a result line is the reply's first sentence, without markdown", () => {
    expect(resultLine("**Done.** Booked it for 7:15.")).toBe("Done.");
    expect(resultLine("No full stop here")).toBe("No full stop here");
    expect(resultLine("x".repeat(300))).toHaveLength(200);
  });
});
