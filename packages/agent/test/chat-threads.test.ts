/**
 * One chat, several things happening at once (D-413): a message sent while the reply is being
 * written, a message sent in a run's last seconds, two messages added at the same moment, and a
 * second run starting while the first still works.
 */
import { createDb, type DbHandle } from "@casama/db";
import { createAuthUser, startTestDatabase, type TestDatabase } from "@casama/db/testing";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import {
  builtinTools,
  CredentialResolver,
  type FixtureFile,
  hashEmbedder,
  type NotificationService,
  PostgresMemoryStore,
  ReplayGateway,
  replyPush,
  runAgent,
} from "../src/index.ts";

let tdb: TestDatabase;
let h: DbHandle;
let orgId: string;
let userId: string;
let credId: string;

beforeAll(async () => {
  tdb = await startTestDatabase();
  h = createDb(tdb.url, { max: 5 });
  userId = (await createAuthUser(tdb.admin, "threads@example.com")).id;
  const [org] = await tdb.admin<
    { id: string }[]
  >`insert into public.organizations (name, slug) values ('Thread Org', 'thread-org') returning id`;
  orgId = org!.id;
  await tdb.admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${userId}, 'owner')`;
  const [cred] = await tdb.admin<{ id: string }[]>`
    insert into public.model_credentials (org_id, provider, label, vault_secret_id)
    values (${orgId}, 'openrouter', 'Main', vault.create_secret('sk-test-threads-1234567890')) returning id`;
  credId = cred!.id;
});
afterAll(async () => {
  await h?.close();
  await tdb?.stop();
});

async function makeBot() {
  const policy = {
    primary: { credential_id: credId, model: "fixture-primary" },
    cheap: { credential_id: credId, model: "fixture-cheap" },
  };
  const [bot] = await tdb.admin<{ id: string }[]>`
    insert into public.bots (org_id, created_by, name, persona_md, model_policy, budget)
    values (${orgId}, ${userId}, 'Ada', 'Friendly and brief.', ${tdb.admin.json(policy)},
            ${tdb.admin.json({ per_run_usd: 5, daily_usd: 50 })})
    returning id`;
  return bot!.id;
}

async function makeChat(botId: string) {
  const [c] = await tdb.admin<{ id: string }[]>`
    insert into public.conversations (org_id, bot_id, created_by) values (${orgId}, ${botId}, ${userId}) returning id`;
  return c!.id;
}

/** A message from the person, the way the send route adds it: at the end of the shown branch. */
async function say(conversationId: string, text: string, runId: string | null = null) {
  const [m] = await tdb.admin<{ id: string }[]>`
    insert into public.messages (org_id, conversation_id, role, author_user_id, content, run_id)
    values (${orgId}, ${conversationId}, 'user', ${userId}, ${tdb.admin.json([{ type: "text", text }])}, ${runId})
    returning id`;
  return m!.id;
}

async function startRun(botId: string, text: string, conversationId?: string) {
  const convo = conversationId ?? (await makeChat(botId));
  const [run] = await tdb.admin<{ id: string }[]>`
    insert into public.runs (org_id, bot_id, conversation_id, created_by) values (${orgId}, ${botId}, ${convo}, ${userId}) returning id`;
  const messageId = await say(convo, text, run!.id);
  return { runId: run!.id, conversationId: convo, messageId };
}

/** What the app shows: the branch ending at the conversation's head, oldest first. */
async function thread(conversationId: string) {
  const rows = await tdb.admin<{ role: string; content: Array<{ text?: string }> }[]>`
    select role, content from public.conversation_thread(${conversationId})`;
  return rows.map((r) => `${r.role}: ${r.content[0]?.text ?? ""}`);
}

const finish = () => ({
  type: "finish" as const,
  usage: { inputTokens: 1000, outputTokens: 100 },
  finishReason: "stop",
  model: "",
});

const fixtures: FixtureFile[] = [
  {
    name: "chat-threads",
    turns: [
      {
        when: { systemIncludes: "extract lasting memories" },
        events: [{ type: "text", text: '{"memories":[]}' }, finish()],
      },
      {
        when: { lastRole: "user", lastUserIncludes: "the second thing" },
        events: [{ type: "text", text: "Second done." }, finish()],
      },
      {
        when: { lastRole: "user", lastUserIncludes: "the first thing" },
        events: [{ type: "text", text: "First done." }, finish()],
      },
    ],
  },
];

type Deps = Parameters<typeof runAgent>[1];

/** Runs each step directly; `before` lets a test do something right before a named step. */
function deps(
  gateway: ReplayGateway,
  extra: Partial<Deps> = {},
  before: Record<string, () => Promise<unknown>> = {},
) {
  const embedder = hashEmbedder();
  const step: Deps["step"] = async (name, fn) => {
    const hook = before[name];
    if (hook) {
      delete before[name];
      await hook();
    }
    return fn();
  };
  return {
    db: h.db,
    gateway,
    tools: builtinTools({ db: h.db, memory: async () => new PostgresMemoryStore(h.db, embedder) }),
    credentials: new CredentialResolver(h.db),
    embedderFor: async () => embedder,
    step,
    deltaIntervalMs: 20,
    cancelPollMs: 50,
    fallback: { backoffMs: 1 },
    ...extra,
  } satisfies Deps;
}

describe("one chat, several things at once", () => {
  it("a message sent while the reply is being written leaves that reply in the chat, and its own run knows it", async () => {
    const botId = await makeBot();
    const first = await startRun(botId, "Do the first thing");
    const started: string[] = [];
    const startRunSpy = async (id: string) => void started.push(id);
    // The person sends another message after the run's last look and before the reply is saved.
    const gateway = new ReplayGateway(fixtures);
    expect(
      (
        await runAgent(
          first.runId,
          deps(
            gateway,
            { startRun: startRunSpy },
            {
              finish: () => say(first.conversationId, "Now do the second thing", first.runId),
            },
          ),
        )
      ).status,
    ).toBe("completed");

    // The reply went under both messages instead of onto a side branch nobody sees.
    expect(await thread(first.conversationId)).toEqual([
      "user: Do the first thing",
      "user: Now do the second thing",
      "assistant: First done.",
    ]);
    // The message the run never saw got a run of its own.
    expect(started).toHaveLength(1);
    const [moved] = await tdb.admin<{ run_id: string }[]>`
      select run_id from public.messages where conversation_id = ${first.conversationId}
        and role = 'user' order by created_at desc limit 1`;
    expect(moved?.run_id).toBe(started[0]);

    // That run sees what was already answered, so it doesn't do the first request again.
    const next = new ReplayGateway(fixtures);
    expect((await runAgent(started[0] as string, deps(next))).status).toBe("completed");
    const req = next.requests.find((r) => JSON.stringify(r.messages).includes("the second thing"));
    const said = req?.messages.map((m) => `${m.role}: ${String(m.content)}`) ?? [];
    expect(said.slice(0, 2)).toEqual(["user: Do the first thing", "assistant: First done."]);
    expect(said).toHaveLength(3);
    expect(said[2]).toContain("Now do the second thing");
    expect(await thread(first.conversationId)).toEqual([
      "user: Do the first thing",
      "user: Now do the second thing",
      "assistant: First done.",
      "assistant: Second done.",
    ]);
  });

  it("a message sent in a run's last seconds, after its last look, is still answered", async () => {
    const botId = await makeBot();
    const first = await startRun(botId, "Do the first thing");
    const started: string[] = [];
    // The reply is saved and the run has looked for leftovers; it is still "running" while it
    // writes memories, so the send route attaches the new message to it.
    expect(
      (
        await runAgent(
          first.runId,
          deps(
            new ReplayGateway(fixtures),
            { startRun: async (id) => void started.push(id) },
            {
              memory: () => say(first.conversationId, "Now do the second thing", first.runId),
            },
          ),
        )
      ).status,
    ).toBe("completed");
    expect(started).toHaveLength(1);
    const [left] = await tdb.admin<{ run_id: string; status: string }[]>`
      select m.run_id, r.status from public.messages m join public.runs r on r.id = m.run_id
      where m.conversation_id = ${first.conversationId} and m.role = 'user'
      order by m.created_at desc limit 1`;
    expect(left).toEqual({ run_id: started[0], status: "queued" });
    expect((await runAgent(started[0] as string, deps(new ReplayGateway(fixtures)))).status).toBe(
      "completed",
    );
    expect(await thread(first.conversationId)).toEqual([
      "user: Do the first thing",
      "assistant: First done.",
      "user: Now do the second thing",
      "assistant: Second done.",
    ]);
  });

  it("a reply stays with its question when the person switched to another branch", async () => {
    const botId = await makeBot();
    const chat = await makeChat(botId);
    await say(chat, "Hello");
    const [hi] = await tdb.admin<{ id: string }[]>`
      insert into public.messages (org_id, conversation_id, role, content, bot_id)
      values (${orgId}, ${chat}, 'assistant', ${tdb.admin.json([{ type: "text", text: "Hi." }])}, ${botId})
      returning id`;
    const first = await startRun(botId, "Do the first thing", chat);
    // Before the reply is saved the person edits their message: a sibling, and the shown branch
    // moves to it.
    const edit = async () => {
      const [e] = await tdb.admin<{ id: string }[]>`
        insert into public.messages (org_id, conversation_id, role, author_user_id, content, parent_message_id)
        values (${orgId}, ${chat}, 'user', ${userId}, ${tdb.admin.json([{ type: "text", text: "Never mind" }])}, ${hi!.id})
        returning id`;
      await tdb.admin`update public.conversations set head_message_id = ${e!.id} where id = ${chat}`;
    };
    expect(
      (await runAgent(first.runId, deps(new ReplayGateway(fixtures), {}, { finish: edit }))).status,
    ).toBe("completed");
    // The branch being shown is untouched; the reply sits under the message it answers.
    expect(await thread(chat)).toEqual(["user: Hello", "assistant: Hi.", "user: Never mind"]);
    const [reply] = await tdb.admin<{ parent_message_id: string }[]>`
      select parent_message_id from public.messages where run_id = ${first.runId} and role = 'assistant'`;
    expect(reply?.parent_message_id).toBe(first.messageId);
  });

  it("two messages added at the same moment both stay in the chat, one after the other", async () => {
    const botId = await makeBot();
    const chat = await makeChat(botId);
    await say(chat, "Hello");
    let inserted = () => {};
    const gate = new Promise<void>((resolve) => {
      inserted = resolve;
    });
    // Two connections, as two devices of one account: the first holds its insert open while the
    // second one arrives.
    const slow = tdb.admin.begin(async (tx) => {
      await tx`
        insert into public.messages (org_id, conversation_id, role, author_user_id, content)
        values (${orgId}, ${chat}, 'user', ${userId}, ${tx.json([{ type: "text", text: "From the phone" }])})`;
      inserted();
      await new Promise((r) => setTimeout(r, 300));
    });
    await gate;
    const fast = tdb.admin`
      insert into public.messages (org_id, conversation_id, role, author_user_id, content)
      values (${orgId}, ${chat}, 'user', ${userId}, ${tdb.admin.json([{ type: "text", text: "From the desktop" }])})`;
    await Promise.all([slow, fast]);
    expect(await thread(chat)).toEqual([
      "user: Hello",
      "user: From the phone",
      "user: From the desktop",
    ]);
  });

  it("a second run in the chat is told the earlier request is already being worked on", async () => {
    const botId = await makeBot();
    const first = await startRun(botId, "Do the first thing");
    // The first run waits for the person's yes; they send something else meanwhile.
    await tdb.admin`update public.runs set status = 'waiting_approval', started_at = now() where id = ${first.runId}`;
    const second = await startRun(botId, "Now do the second thing", first.conversationId);
    const gateway = new ReplayGateway(fixtures);
    expect((await runAgent(second.runId, deps(gateway))).status).toBe("completed");
    const req = gateway.requests.find((r) =>
      JSON.stringify(r.messages).includes("the second thing"),
    );
    const earlier = req?.messages.find(
      (m) => typeof m.content === "string" && m.content.startsWith("Do the first thing"),
    );
    expect(earlier?.content).toContain("already working on this in another run");
    await tdb.admin`update public.runs set status = 'cancelled', ended_at = now() where id = ${first.runId}`;
  });
});

describe("a reply's notification opens the chat it was said in", () => {
  it("links a group chat as the group, and a bot's own chat as that chat", async () => {
    const botId = await makeBot();
    const direct = await startRun(botId, "Do the first thing");
    const [group] = await tdb.admin<{ id: string }[]>`
      insert into public.conversations (org_id, bot_id, created_by, kind, title)
      values (${orgId}, ${botId}, ${userId}, 'group', 'Launch') returning id`;
    const inGroup = await startRun(botId, "Do the first thing", group!.id);
    const sent: Array<{ link?: string }> = [];
    const notifications = {
      notify: async (_user: string, _org: string, _kind: string, payload: { link?: string }) => {
        sent.push(payload);
      },
    } as unknown as NotificationService;
    for (const r of [direct, inGroup])
      await replyPush(
        h.db,
        notifications,
        {
          runId: r.runId,
          orgId,
          botId,
          botName: "Ada",
          conversationId: r.conversationId,
          createdBy: userId,
          trigger: "chat",
          parentRunId: null,
        },
        { ok: true, text: "Done." },
        0,
      );
    expect(sent.map((p) => p.link)).toEqual([
      `/bots/${botId}/chat?c=${direct.conversationId}`,
      // Before, the group's thread opened in the bot's own chat screen, under one bot's name.
      `/groups/${group!.id}`,
    ]);
    await tdb.admin`update public.runs set status = 'cancelled', ended_at = now() where id in ${tdb.admin([direct.runId, inGroup.runId])}`;
  });
});
