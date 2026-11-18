/** The workspace's Full access switch in a run (D-394). */
import { createDb, type DbHandle } from "@casama/db";
import { createAuthUser, startTestDatabase, type TestDatabase } from "@casama/db/testing";
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
const ran: string[] = [];

const fin = {
  type: "finish" as const,
  usage: { inputTokens: 10, outputTokens: 5 },
  finishReason: "stop",
  model: "",
};
const use = (word: string, tool: string) => ({
  when: { lastRole: "user" as const, lastUserIncludes: word },
  events: [
    { type: "tool_call" as const, call: { callId: `c-${word}`, name: tool, args: { what: word } } },
    { ...fin, finishReason: "tool-calls" },
  ],
});
const fixtures: FixtureFile[] = [
  {
    name: "full-access",
    turns: [
      {
        when: { systemIncludes: "extract lasting memories" },
        events: [{ type: "text", text: '{"memories":[]}' }, fin],
      },
      use("delete", "danger__do"),
      use("connect", "grow__do"),
      use("pay", "pay__do"),
      use("ruled", "ruled__do"),
      { when: { lastRole: "tool" }, events: [{ type: "text", text: "Done." }, fin] },
    ],
  },
];

function tools() {
  const t = builtinTools({
    db: h.db,
    memory: async () => new PostgresMemoryStore(h.db, hashEmbedder()),
  });
  const schema = z.object({ what: z.string() });
  const run = (name: string) => async (args: { what: string }) => {
    ran.push(`${name}:${args.what}`);
    return { content: "ok" };
  };
  t.register({ name: "danger.do", description: "x", risk: "high", schema, execute: run("danger") });
  // Widens what the bot can reach (like mcp.add): always asks, except under full access.
  t.register({
    name: "grow.do",
    description: "x",
    risk: "high",
    alwaysAsk: true,
    schema,
    execute: run("grow"),
  });
  // Moves money (like payments.request): asks even under full access.
  t.register({
    name: "pay.do",
    description: "x",
    risk: "high",
    alwaysAsk: true,
    askEvenWithFullAccess: true,
    schema,
    execute: run("pay"),
  });
  t.register({ name: "ruled.do", description: "x", risk: "low", schema, execute: run("ruled") });
  return t;
}

async function chat(text: string) {
  const [conv] = await tdb.admin<
    { id: string }[]
  >`insert into public.conversations (org_id, bot_id) values (${orgId}, ${botId}) returning id`;
  const [run] = await tdb.admin<{ id: string }[]>`
    insert into public.runs (org_id, bot_id, conversation_id, created_by) values (${orgId}, ${botId}, ${conv!.id}, ${userId}) returning id`;
  await tdb.admin`insert into public.messages (org_id, conversation_id, role, author_user_id, content, run_id)
    values (${orgId}, ${conv!.id}, 'user', ${userId}, ${tdb.admin.json([{ type: "text", text }])}, ${run!.id})`;
  await runAgent(run!.id, {
    db: h.db,
    gateway: new ReplayGateway(fixtures),
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

const setFullAccess = (on: boolean) =>
  tdb.admin`update public.organizations set full_access = ${on} where id = ${orgId}`;

beforeAll(async () => {
  tdb = await startTestDatabase();
  h = createDb(tdb.url, { max: 5 });
  userId = (await createAuthUser(tdb.admin, "full-access@example.com")).id;
  const [org] = await tdb.admin<
    { id: string }[]
  >`insert into public.organizations (name, slug) values ('Full', 'full-access') returning id`;
  orgId = org!.id;
  await tdb.admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${userId}, 'owner')`;
  const [cred] = await tdb.admin<{ id: string }[]>`
    insert into public.model_credentials (org_id, provider, label, vault_secret_id) values (${orgId}, 'openrouter', 'k', vault.create_secret('sk-test-123456')) returning id`;
  // The strictest autonomy, so anything that runs without asking is the switch's doing.
  const [bot] = await tdb.admin<{ id: string }[]>`
    insert into public.bots (org_id, created_by, name, autonomy, model_policy) values (${orgId}, ${userId}, 'Careful', 'ask_always',
      ${tdb.admin.json({ primary: { credential_id: cred!.id, model: "m" } })}) returning id`;
  botId = bot!.id;
  await tdb.admin`insert into public.action_rules (org_id, bot_id, match_kind, match_value, rule) values (${orgId}, null, 'tool', 'ruled.do', 'ask')`;
});
afterAll(async () => {
  await h?.close();
  await tdb?.stop();
});

describe("full access (D-394)", () => {
  it("is off by default: a bot set to ask before acting asks", async () => {
    expect(await chat("please delete it")).toBe(1);
    expect(ran).not.toContain("danger:delete");
  });

  it("on: high-risk and always-ask tools run without asking", async () => {
    await setFullAccess(true);
    expect(await chat("please delete it")).toBe(0);
    expect(await chat("please connect it")).toBe(0);
    expect(ran).toEqual(expect.arrayContaining(["danger:delete", "grow:connect"]));
  });

  it("on: payments and the workspace's own ask rules still ask", async () => {
    await setFullAccess(true);
    expect(await chat("please pay it")).toBe(1);
    expect(await chat("please ruled it")).toBe(1);
    expect(ran).not.toContain("pay:pay");
    expect(ran).not.toContain("ruled:ruled");
  });
});
