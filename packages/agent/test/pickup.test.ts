import { createDb, type DbHandle } from "@casama/db";
import { createAuthUser, startTestDatabase, type TestDatabase } from "@casama/db/testing";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import {
  builtinTools,
  CredentialResolver,
  continueAfterUpdate,
  directSteps,
  type FixtureFile,
  hashEmbedder,
  PostgresMemoryStore,
  pickupNote,
  ReplayGateway,
  runAgent,
  UPDATED_ERROR_CODE,
} from "../src/index.ts";

// A run that a Casama update interrupted is picked up by a new run in the same chat (D-402).

let tdb: TestDatabase;
let h: DbHandle;
let orgId: string;
let userId: string;
let botId: string;

beforeAll(async () => {
  tdb = await startTestDatabase();
  h = createDb(tdb.url, { max: 5 });
  userId = (await createAuthUser(tdb.admin, "pickup@example.com")).id;
  const [org] = await tdb.admin<
    { id: string }[]
  >`insert into public.organizations (name, slug) values ('Pickup Org', 'pickup-org') returning id`;
  orgId = org!.id;
  await tdb.admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${userId}, 'owner')`;
  const [cred] = await tdb.admin<{ id: string }[]>`
    insert into public.model_credentials (org_id, provider, label, vault_secret_id)
    values (${orgId}, 'openrouter', 'Main', vault.create_secret('sk-pickup-test')) returning id`;
  const policy = { primary: { credential_id: cred!.id, model: "fixture-primary" } };
  const [bot] = await tdb.admin<{ id: string }[]>`
    insert into public.bots (org_id, created_by, name, persona_md, model_policy, budget)
    values (${orgId}, ${userId}, 'Ada', 'Brief.', ${tdb.admin.json(policy)},
            ${tdb.admin.json({ per_run_usd: 5, daily_usd: 50 })})
    returning id`;
  botId = bot!.id;
});
afterAll(async () => {
  await h?.close();
  await tdb?.stop();
});

/** A chat run that asked something, started two actions and then failed as "updated". */
async function interruptedRun(opts: { kind?: string; trigger?: string } = {}) {
  const [conv] = await tdb.admin<{ id: string }[]>`
    insert into public.conversations (org_id, bot_id, kind)
    values (${orgId}, ${botId}, ${opts.kind ?? "direct"}) returning id`;
  const [run] = await tdb.admin<{ id: string }[]>`
    insert into public.runs (org_id, bot_id, conversation_id, created_by, trigger)
    values (${orgId}, ${botId}, ${conv!.id}, ${userId}, ${opts.trigger ?? "chat"}) returning id`;
  await tdb.admin`
    insert into public.messages (org_id, conversation_id, role, author_user_id, content, run_id)
    values (${orgId}, ${conv!.id}, 'user', ${userId},
            ${tdb.admin.json([{ type: "text", text: "Email Sam the report" }])}, ${run!.id})`;
  await tdb.admin`select public.append_run_event(${run!.id}, 'tool.started',
    ${tdb.admin.json({ call_id: "c1", tool: "files.read", args_redacted: { path: "report.pdf" } })})`;
  await tdb.admin`select public.append_run_event(${run!.id}, 'tool.started',
    ${tdb.admin.json({ call_id: "c2", tool: "email.send", args_redacted: { to: "sam@example.com" } })})`;
  await tdb.admin`update public.runs set status = 'failed', ended_at = now(),
    error = ${tdb.admin.json({ code: UPDATED_ERROR_CODE, message: "updated" })} where id = ${run!.id}`;
  return { runId: run!.id, conversationId: conv!.id };
}

describe("pickupNote", () => {
  it("lists the actions already started and asks to check before repeating", () => {
    const note = pickupNote([
      { tool: "files.read", args: { path: "a.txt" } },
      { tool: "email.send", args: {} },
      { tool: null, args: null },
    ]);
    expect(note).toContain("Casama was updated");
    expect(note).toContain('- files.read {"path":"a.txt"}');
    expect(note).toContain("- email.send\n");
    expect(note).toContain("never repeat an action");
  });

  it("says so when nothing was started, and sums up long lists", () => {
    expect(pickupNote([])).toContain("You hadn't started any actions yet.");
    const many = Array.from({ length: 35 }, (_, i) => ({ tool: `t${i}`, args: {} }));
    const note = pickupNote(many);
    expect(note).toContain("5 earlier actions, then");
    expect(note).not.toContain("- t4\n");
    expect(note).toContain("- t34");
  });

  it("cuts long arguments", () => {
    const note = pickupNote([{ tool: "files.write", args: { text: "x".repeat(500) } }]);
    expect(note).toContain("…");
    expect(note.length).toBeLessThan(1500);
  });
});

describe("continueAfterUpdate", () => {
  it("starts one pickup run in the same chat, which answers from the note", async () => {
    const { runId, conversationId } = await interruptedRun();
    const next = await continueAfterUpdate(h.db, runId);
    expect(next).toBeTruthy();
    const [run] = await tdb.admin<
      { conversation_id: string; trigger: string; status: string; budget: Record<string, string> }[]
    >`select conversation_id, trigger, status, budget from public.runs where id = ${next!}`;
    expect(run?.conversation_id).toBe(conversationId);
    expect(run?.trigger).toBe("chat");
    expect(run?.status).toBe("queued");
    expect(run?.budget.resumes).toBe(runId);
    expect(run?.budget.task).toContain("- email.send");

    // Only once, and never a pickup of a pickup.
    expect(await continueAfterUpdate(h.db, runId)).toBeNull();
    expect(await continueAfterUpdate(h.db, next!)).toBeNull();

    // The pickup run sees the note as what to do now and the person's request in the history,
    // without the "ended without a reply" note a failed run otherwise gets.
    const fixtures: FixtureFile[] = [
      {
        name: "pickup",
        turns: [
          {
            when: { lastRole: "user", lastUserIncludes: "Casama was updated" },
            events: [
              { type: "text", text: "Picked it up: the email to Sam already went out." },
              {
                type: "finish",
                usage: { inputTokens: 10, outputTokens: 5 },
                finishReason: "stop",
                model: "",
              },
            ],
          },
        ],
      },
    ];
    const gateway = new ReplayGateway(fixtures);
    const embedder = hashEmbedder();
    const result = await runAgent(next!, {
      db: h.db,
      gateway,
      tools: builtinTools({
        db: h.db,
        memory: async () => new PostgresMemoryStore(h.db, embedder),
      }),
      credentials: new CredentialResolver(h.db),
      embedderFor: async () => embedder,
      step: directSteps,
      deltaIntervalMs: 20,
      cancelPollMs: 50,
      fallback: { backoffMs: 1 },
    });
    expect(result.status).toBe("completed");
    const main = gateway.requests.find(
      (r) => !r.system.join("\n").includes("extract lasting memories"),
    );
    const sent = JSON.stringify(main?.messages ?? []);
    expect(sent).toContain("Email Sam the report");
    expect(sent).toContain("Casama was updated");
    expect(sent).not.toContain("ended without a reply");
    const [reply] = await tdb.admin<{ content: unknown }[]>`
      select content from public.messages where run_id = ${next!} and role = 'assistant'`;
    expect(JSON.stringify(reply?.content)).toContain("already went out");
  });

  it("leaves group chats, routines and runs without a request alone; keeps a chat app's trigger", async () => {
    const group = await interruptedRun({ kind: "group" });
    expect(await continueAfterUpdate(h.db, group.runId)).toBeNull();
    const routine = await interruptedRun({ trigger: "routine" });
    expect(await continueAfterUpdate(h.db, routine.runId)).toBeNull();
    // A chat app's run is picked up as a chat app's run, so its reply goes back there.
    const channel = await interruptedRun({ trigger: "channel" });
    const picked = await continueAfterUpdate(h.db, channel.runId);
    const [p] = await tdb.admin<
      { trigger: string }[]
    >`select trigger from public.runs where id = ${picked!}`;
    expect(p?.trigger).toBe("channel");
    const [run] = await tdb.admin<{ id: string }[]>`
      insert into public.runs (org_id, bot_id, created_by) values (${orgId}, ${botId}, ${userId}) returning id`;
    expect(await continueAfterUpdate(h.db, run!.id)).toBeNull();
  });
});
