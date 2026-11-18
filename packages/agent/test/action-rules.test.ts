/** Action rules in a run (D-115): email to the user's domain sends, external email waits, hand-offs. */
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
const sent: string[] = [];

const fin = {
  type: "finish" as const,
  usage: { inputTokens: 10, outputTokens: 5 },
  finishReason: "stop",
  model: "",
};
const send = (id: string, to: string) => ({
  type: "tool_call" as const,
  call: { callId: id, name: "mail__send", args: { to, subject: "Hi", body: "Hello" } },
});
const fixtures: FixtureFile[] = [
  {
    name: "rules",
    turns: [
      {
        when: { systemIncludes: "extract lasting memories" },
        events: [{ type: "text", text: '{"memories":[]}' }, fin],
      },
      {
        when: { lastRole: "user", lastUserIncludes: "email the team" },
        events: [send("c1", "ana@acme.com"), { ...fin, finishReason: "tool-calls" }],
      },
      {
        when: { lastRole: "user", lastUserIncludes: "email the client" },
        events: [send("c2", "eve@client.example"), { ...fin, finishReason: "tool-calls" }],
      },
      {
        when: { lastRole: "user", lastUserIncludes: "change my password" },
        events: [
          {
            type: "tool_call",
            call: {
              callId: "c3",
              name: "mail__send",
              args: { to: "it@acme.com", subject: "change password", body: "x" },
            },
          },
          { ...fin, finishReason: "tool-calls" },
        ],
      },
      {
        when: { lastRole: "tool", lastToolName: "mail.send" },
        events: [{ type: "text", text: "Done." }, fin],
      },
    ],
  },
];

function tools() {
  const t = builtinTools({
    db: h.db,
    memory: async () => new PostgresMemoryStore(h.db, hashEmbedder()),
  });
  t.register({
    name: "mail.send",
    description: "Send an email",
    risk: "high",
    schema: z.object({ to: z.string(), subject: z.string(), body: z.string() }),
    async execute(args) {
      sent.push(args.to);
      return { content: `sent to ${args.to}` };
    },
  });
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
  return run!.id;
}

const deps = (gateway: ReplayGateway) => ({
  db: h.db,
  gateway,
  tools: tools(),
  credentials: new CredentialResolver(h.db),
  embedderFor: async () => hashEmbedder(),
  step: directSteps,
  deltaIntervalMs: 20,
  cancelPollMs: 50,
  fallback: { backoffMs: 1 },
  waitForApproval: async () => {},
});

beforeAll(async () => {
  tdb = await startTestDatabase();
  h = createDb(tdb.url, { max: 5 });
  userId = (await createAuthUser(tdb.admin, "rules@example.com")).id;
  const [org] = await tdb.admin<
    { id: string }[]
  >`insert into public.organizations (name, slug) values ('Rules', 'rules') returning id`;
  orgId = org!.id;
  await tdb.admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${userId}, 'owner')`;
  const [cred] = await tdb.admin<{ id: string }[]>`
    insert into public.model_credentials (org_id, provider, label, vault_secret_id) values (${orgId}, 'openrouter', 'k', vault.create_secret('sk-test-123456')) returning id`;
  const [bot] = await tdb.admin<{ id: string }[]>`
    insert into public.bots (org_id, created_by, name, autonomy, model_policy) values (${orgId}, ${userId}, 'Mailer', 'ask_risky',
      ${tdb.admin.json({ primary: { credential_id: cred!.id, model: "m" } })}) returning id`;
  botId = bot!.id;
  // Ask before sending anything, except email inside the company.
  await tdb.admin`insert into public.action_rules (org_id, bot_id, match_kind, match_value, rule) values (${orgId}, null, 'category', 'send', 'ask')`;
  await tdb.admin`insert into public.action_rules (org_id, bot_id, match_kind, match_value, target, rule)
    values (${orgId}, ${botId}, 'category', 'send', ${tdb.admin.json({ domains: ["acme.com"] })}, 'allow_within_limits')`;
});
afterAll(async () => {
  await h?.close();
  await tdb?.stop();
});

describe("action rules in a run", () => {
  it("email to the company domain sends without approval", async () => {
    const runId = await chat("Please email the team");
    await runAgent(runId, deps(new ReplayGateway(fixtures)));
    expect(sent).toContain("ana@acme.com");
    const [a] = await tdb.admin<
      { n: number }[]
    >`select count(*)::int as n from public.approvals where run_id = ${runId}`;
    expect(a?.n).toBe(0);
  });

  it("external email waits for approval", async () => {
    const runId = await chat("Please email the client");
    await runAgent(runId, deps(new ReplayGateway(fixtures)));
    const [a] = await tdb.admin<
      { tool_name: string }[]
    >`select tool_name from public.approvals where run_id = ${runId}`;
    expect(a?.tool_name).toBe("mail.send");
    expect(sent).not.toContain("eve@client.example");
  });

  it("password changes are always handed to the person", async () => {
    const runId = await chat("Please change my password");
    await runAgent(runId, deps(new ReplayGateway(fixtures)));
    expect(sent).not.toContain("it@acme.com");
    const evs = await tdb.admin<
      { payload: { message?: string } }[]
    >`select payload from public.run_events where run_id = ${runId} and type = 'tool.failed'`;
    expect(JSON.stringify(evs)).toContain("always done by the person");
  });

  it("no tool lets a bot change rules", () => {
    expect(
      tools()
        .specs(tools().available({ computer: true, desktop: true, vision: true }))
        .some((t) => /rule/i.test(t.name)),
    ).toBe(false);
  });
});
