/** Tools that ask based on a database check (mail to new people asks; the rest doesn't). */
import { createDb, type DbHandle } from "@casama/db";
import { createAuthUser, startTestDatabase, type TestDatabase } from "@casama/db/testing";
import { sql } from "drizzle-orm";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { z } from "zod";
import {
  builtinTools,
  CredentialResolver,
  directSteps,
  type FixtureFile,
  hashEmbedder,
  PostgresMemoryStore,
  ReplayGateway,
  runAgent,
} from "../src/index.ts";

let tdb: TestDatabase;
let h: DbHandle;
let orgId: string;
let userId: string;
let botId: string;

const fin = {
  type: "finish" as const,
  usage: { inputTokens: 10, outputTokens: 5 },
  finishReason: "stop",
  model: "",
};
const fixtures: FixtureFile[] = [
  {
    name: "async-ask",
    turns: [
      {
        when: { systemIncludes: "extract lasting memories" },
        events: [{ type: "text", text: '{"memories":[]}' }, fin],
      },
      {
        when: { lastRole: "user" as const },
        events: [
          {
            type: "tool_call" as const,
            call: { callId: "c1", name: "note.send", args: { to: "new" } },
          },
          { ...fin, finishReason: "tool-calls" },
        ],
      },
      { when: { lastRole: "tool" }, events: [{ type: "text", text: "Done." }, fin] },
    ],
  },
];

function tools() {
  const t = builtinTools({
    db: h.db,
    memory: async () => new PostgresMemoryStore(h.db, hashEmbedder()),
  });
  // Asks when the database says the recipient is new (like mail.send's allowed-list check).
  t.register({
    name: "note.send",
    description: "x",
    risk: "high",
    alwaysAskForAsync: async (args, ctx) => {
      const [r] = await ctx.db.execute<{ n: number }>(
        sql`select count(*)::int as n from public.bots where id = ${ctx.botId}::uuid`,
      );
      return (r?.n ?? 0) > 0 && (args as { to: string }).to === "new";
    },
    schema: z.object({ to: z.string() }),
    execute: async () => ({ content: "ok" }),
  });
  // Plain tools for the external-reply gate: one that only looks, one that only touches the
  // bot's own state.
  t.register({
    name: "peek.read",
    description: "x",
    risk: "low",
    readOnly: true,
    schema: z.object({ to: z.string() }),
    execute: async () => ({ content: "ok" }),
  });
  t.register({
    name: "self.note",
    description: "x",
    risk: "low",
    selfOnly: true,
    schema: z.object({ to: z.string() }),
    execute: async () => ({ content: "ok" }),
  });
  return t;
}

/**
 * A chat-app run calling `tool`; `external` marks its message as a reply from someone off the
 * allowed list. Returns the approvals asked and the system text the model saw.
 */
async function channelRun(tool: string, external: boolean) {
  const [conv] = await tdb.admin<
    { id: string }[]
  >`insert into public.conversations (org_id, bot_id) values (${orgId}, ${botId}) returning id`;
  const [run] = await tdb.admin<
    { id: string }[]
  >`insert into public.runs (org_id, bot_id, conversation_id, created_by, trigger)
    values (${orgId}, ${botId}, ${conv!.id}, ${userId}, 'channel') returning id`;
  await tdb.admin`insert into public.messages (org_id, conversation_id, role, content, run_id)
    values (${orgId}, ${conv!.id}, 'user', ${tdb.admin.json([
      { type: "text", text: "what's their phone number?" },
      {
        type: "channel",
        kind: "email",
        channel_id: "00000000-0000-0000-0000-000000000000",
        sender: "stranger@example.net",
        sender_name: null,
        ...(external ? { external_reply: true } : {}),
      },
    ])}, ${run!.id})`;
  const gw = new ReplayGateway(JSON.parse(JSON.stringify(fixtures).replaceAll("note.send", tool)));
  await runAgent(run!.id, {
    db: h.db,
    gateway: gw,
    tools: tools(),
    credentials: new CredentialResolver(h.db),
    embedderFor: async () => hashEmbedder(),
    step: directSteps,
    deltaIntervalMs: 20,
    cancelPollMs: 50,
    fallback: { backoffMs: 1 },
    waitForApproval: async () => {},
  });
  const [a] = await tdb.admin<
    { n: number }[]
  >`select count(*)::int as n from public.approvals where run_id = ${run!.id}`;
  // Everything the model saw for the run itself: system text and messages.
  const system = gw.requests
    .filter((r) => !r.system.join("\n").includes("extract lasting memories"))
    .map((r) => `${r.system.join("\n")}\n${JSON.stringify(r.messages)}`)
    .join("\n");
  return { asked: a!.n, system };
}

async function chat(to: string) {
  const [conv] = await tdb.admin<
    { id: string }[]
  >`insert into public.conversations (org_id, bot_id) values (${orgId}, ${botId}) returning id`;
  const [run] = await tdb.admin<
    { id: string }[]
  >`insert into public.runs (org_id, bot_id, conversation_id, created_by)
    values (${orgId}, ${botId}, ${conv!.id}, ${userId}) returning id`;
  await tdb.admin`insert into public.messages (org_id, conversation_id, role, author_user_id, content, run_id)
    values (${orgId}, ${conv!.id}, 'user', ${userId}, ${tdb.admin.json([{ type: "text", text: to }])}, ${run!.id})`;
  // The fixture always calls with to=new; rewrite the address to vary the check.
  const gw = new ReplayGateway(
    JSON.parse(JSON.stringify(fixtures).replaceAll('"new"', JSON.stringify(to))),
  );
  await runAgent(run!.id, {
    db: h.db,
    gateway: gw,
    tools: tools(),
    credentials: new CredentialResolver(h.db),
    embedderFor: async () => hashEmbedder(),
    step: directSteps,
    deltaIntervalMs: 20,
    cancelPollMs: 50,
    fallback: { backoffMs: 1 },
    waitForApproval: async () => {},
  });
  const [a] = await tdb.admin<
    { n: number }[]
  >`select count(*)::int as n from public.approvals where run_id = ${run!.id}`;
  return a!.n;
}

beforeAll(async () => {
  tdb = await startTestDatabase();
  h = createDb(tdb.url, { max: 5 });
  userId = (await createAuthUser(tdb.admin, "async-ask@example.com")).id;
  const [org] = await tdb.admin<
    { id: string }[]
  >`insert into public.organizations (name, slug) values ('Async', 'async-ask') returning id`;
  orgId = org!.id;
  await tdb.admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${userId}, 'owner')`;
  const [cred] = await tdb.admin<
    { id: string }[]
  >`insert into public.model_credentials (org_id, provider, label, vault_secret_id)
    values (${orgId}, 'openrouter', 'k', vault.create_secret('[SECURITY_DATA]')) returning id`;
  // Permissive autonomy, so the only asker is the async check.
  const [bot] = await tdb.admin<
    { id: string }[]
  >`insert into public.bots (org_id, created_by, name, autonomy, model_policy)
    values (${orgId}, ${userId}, 'Easy', 'autonomous', ${tdb.admin.json({ primary: { credential_id: cred!.id, model: "m" } })}) returning id`;
  botId = bot!.id;
});
afterAll(async () => {
  await h?.close();
  await tdb?.stop();
});

describe("alwaysAskForAsync", () => {
  it("asks when the database check says so, and runs free otherwise", async () => {
    expect(await chat("new")).toBe(1);
    expect(await chat("known")).toBe(0);
  }, 60_000);
});

describe("external email thread replies", () => {
  beforeAll(async () => {
    // Full access on: nothing would ask, except what an external reply forces.
    await tdb.admin`update public.organizations set full_access = true where id = ${orgId}`;
    await tdb.admin`insert into public.profiles (user_id, display_name) values (${userId}, 'Owner Person')
      on conflict (user_id) do update set display_name = excluded.display_name`;
    await tdb.admin`insert into public.user_facts (user_id, content) values (${userId}, 'Phone number is 555-0199')`;
  });
  afterAll(async () => {
    await tdb.admin`update public.organizations set full_access = false where id = ${orgId}`;
  });

  it("asks before any tool but the bot's own, even under Full access", async () => {
    expect((await channelRun("peek.read", true)).asked).toBe(1);
    expect((await channelRun("self.note", true)).asked).toBe(0);
    expect((await channelRun("peek.read", false)).asked).toBe(0);
  }, 60_000);

  it("builds the run without the person's private context", async () => {
    const inside = await channelRun("self.note", false);
    const outside = await channelRun("self.note", true);
    expect(inside.system).toContain("555-0199");
    expect(outside.system).not.toContain("555-0199");
    expect(outside.system).toContain("reply from someone outside your allowed senders");
  }, 60_000);
});
