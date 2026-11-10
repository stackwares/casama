import { createDb, type DbHandle } from "@kasama/db";
import { createAuthUser, startTestDatabase, type TestDatabase } from "@kasama/db/testing";
import { forcedIds, runSpanId, runTraceId } from "@kasama/observability";
import { trace } from "@opentelemetry/api";
import {
  InMemorySpanExporter,
  SimpleSpanProcessor,
  TracerProvider,
} from "@opentelemetry/sdk-trace";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { z } from "zod";
import {
  builtinTools,
  CredentialResolver,
  directSteps,
  type FixtureFile,
  hashEmbedder,
  MemoryService,
  PostgresMemoryStore,
  ReplayGateway,
  runAgent,
} from "../src/index.ts";
import { LangfuseSink } from "../src/langfuse.ts";
import { planLazyTools, registerToolsLoad, toolGroup } from "../src/lazy-tools.ts";

const SECRET = "sk-live-SECRET-1234567890";

let tdb: TestDatabase;
let h: DbHandle;
let orgId: string;
let userId: string;
let credId: string;

beforeAll(async () => {
  tdb = await startTestDatabase();
  h = createDb(tdb.url, { max: 5 });
  const user = await createAuthUser(tdb.admin, "runner@example.com");
  userId = user.id;
  const [org] = await tdb.admin<
    { id: string }[]
  >`insert into public.organizations (name, slug) values ('Run Org', 'run-org') returning id`;
  orgId = org!.id;
  await tdb.admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${userId}, 'owner')`;
  await tdb.admin`update public.profiles set timezone = 'America/Chicago' where user_id = ${userId}`;
  const [cred] = await tdb.admin<{ id: string }[]>`
    insert into public.model_credentials (org_id, provider, label, vault_secret_id)
    values (${orgId}, 'openrouter', 'Main', vault.create_secret(${SECRET})) returning id`;
  credId = cred!.id;
});
afterAll(async () => {
  await h?.close();
  await tdb?.stop();
});

async function makeBot(opts: { budget?: object; fallbacks?: boolean } = {}) {
  const policy = {
    primary: { credential_id: credId, model: "fixture-primary" },
    ...(opts.fallbacks ? { fallbacks: [{ credential_id: credId, model: "fixture-backup" }] } : {}),
    cheap: { credential_id: credId, model: "fixture-cheap" },
  };
  const [bot] = await tdb.admin<{ id: string }[]>`
    insert into public.bots (org_id, created_by, name, persona_md, model_policy, budget)
    values (${orgId}, ${userId}, 'Ada', 'Friendly and brief.', ${tdb.admin.json(policy)},
            ${tdb.admin.json(opts.budget ?? { per_run_usd: 5, daily_usd: 50 })})
    returning id`;
  return bot!.id;
}

async function startRun(botId: string, text: string, conversationId?: string) {
  const convo =
    conversationId ??
    (
      await tdb.admin<
        { id: string }[]
      >`insert into public.conversations (org_id, bot_id) values (${orgId}, ${botId}) returning id`
    )[0]!.id;
  const [run] = await tdb.admin<{ id: string }[]>`
    insert into public.runs (org_id, bot_id, conversation_id, created_by) values (${orgId}, ${botId}, ${convo}, ${userId}) returning id`;
  await tdb.admin`
    insert into public.messages (org_id, conversation_id, role, author_user_id, content, run_id)
    values (${orgId}, ${convo}, 'user', ${userId}, ${tdb.admin.json([{ type: "text", text }])}, ${run!.id})`;
  return { runId: run!.id, conversationId: convo };
}

const events = (runId: string) =>
  tdb.admin<{ seq: number; type: string; payload: Record<string, unknown> }[]>`
    select seq, type, payload from public.run_events where run_id = ${runId} order by seq`;

const finish = (n = 10) => ({
  type: "finish" as const,
  usage: { inputTokens: 1000 * n, outputTokens: 100 * n },
  finishReason: "stop",
  model: "",
});

const fixtures: FixtureFile[] = [
  {
    name: "memory-extraction",
    turns: [
      {
        when: { systemIncludes: "extract lasting memories", lastUserIncludes: "teal" },
        events: [
          {
            type: "text",
            text: '{"memories":[{"kind":"preference","content":"The user\'s favorite color is teal.","importance":0.8}]}',
          },
          finish(1),
        ],
      },
      {
        when: { systemIncludes: "extract lasting memories" },
        events: [{ type: "text", text: '{"memories":[]}' }, finish(1)],
      },
    ],
  },
  {
    name: "chat",
    turns: [
      {
        when: { lastRole: "user", lastUserIncludes: "favorite color is teal" },
        events: [
          { type: "text", text: "Noted, saving that. " },
          {
            type: "tool_call",
            call: {
              callId: "c1",
              name: "memory__write",
              args: { content: "Favorite color: teal", kind: "preference" },
            },
          },
          finish(),
        ],
      },
      {
        when: { lastRole: "tool", lastToolName: "memory.write" },
        events: [{ type: "text", text: "Got it, teal it is." }, finish()],
      },
      {
        when: { lastUserIncludes: "what is my favorite color" },
        events: [{ type: "text", text: "Your favorite color is teal." }, finish()],
      },
      {
        when: { lastUserIncludes: "leak" },
        events: [{ type: "text", text: `The key is ${SECRET} ok` }, finish()],
      },
      {
        when: { lastUserIncludes: "slow", lastRole: "user" },
        delayMs: 150,
        events: Array.from({ length: 40 }, () => ({ type: "text" as const, text: "word " })).concat(
          [finish()] as never,
        ),
      },
      {
        when: { lastUserIncludes: "loop" },
        events: [
          {
            type: "tool_call",
            call: { callId: "x", name: "memory__search", args: { query: "anything" } },
          },
          finish(100),
        ],
      },
      {
        when: { model: "fixture-primary", lastUserIncludes: "failover" },
        error: { message: "rate limited", status: 429 },
        events: [],
      },
      {
        when: { model: "fixture-backup", lastUserIncludes: "failover" },
        events: [{ type: "text", text: "Answered by the backup." }, finish()],
      },
      {
        when: { lastUserIncludes: "weekly report", lastRole: "user" },
        events: [
          {
            type: "tool_call",
            call: { callId: "s1", name: "skills__load", args: { name: "weekly-report" } },
          },
          finish(),
        ],
      },
      {
        when: { lastUserIncludes: "weekly report", lastRole: "tool", lastToolName: "skills.load" },
        events: [{ type: "text", text: "Here is the report in three bullets." }, finish()],
      },
      {
        when: { lastUserIncludes: "bad tool", lastRole: "user" },
        events: [
          {
            type: "tool_call",
            call: { callId: "b1", name: "skills__load", args: { name: "nope" } },
          },
          finish(),
        ],
      },
      {
        when: { lastRole: "tool", lastToolName: "skills.load" },
        events: [{ type: "text", text: "That skill does not exist." }, finish()],
      },
    ],
  },
];

function deps(gateway: ReplayGateway, extra: Partial<Parameters<typeof runAgent>[1]> = {}) {
  const embedder = hashEmbedder();
  return {
    db: h.db,
    gateway,
    tools: builtinTools({ db: h.db, memory: async () => new PostgresMemoryStore(h.db, embedder) }),
    credentials: new CredentialResolver(h.db),
    embedderFor: async () => embedder,
    step: directSteps,
    deltaIntervalMs: 20,
    cancelPollMs: 50,
    fallback: { backoffMs: 1 },
    ...extra,
  };
}

describe("runAgent", () => {
  it("runs tools, streams events with gap-free seq, saves the message and extracts memories", async () => {
    const gateway = new ReplayGateway(fixtures);
    const botId = await makeBot();
    const { runId, conversationId } = await startRun(
      botId,
      "Please remember my favorite color is teal",
    );
    expect(await runAgent(runId, deps(gateway))).toEqual({ status: "completed" });

    const evs = await events(runId);
    expect(evs.map((e) => e.seq)).toEqual(evs.map((_, i) => i + 1));
    const types = evs.map((e) => e.type);
    expect(types[0]).toBe("run.started");
    expect(types.at(-1)).toBe("run.completed");
    expect(types).toEqual(
      expect.arrayContaining([
        "message.delta",
        "tool.started",
        "memory.written",
        "tool.completed",
        "message.completed",
        "usage",
      ]),
    );
    expect(types.indexOf("tool.started")).toBeLessThan(types.indexOf("tool.completed"));

    const [msg] = await tdb.admin<{ content: Array<{ text: string }> }[]>`
      select content from public.messages where conversation_id = ${conversationId} and role = 'assistant'`;
    expect(msg?.content[0]?.text).toBe("Got it, teal it is.");

    const mems = await tdb.admin<
      { kind: string; content: string }[]
    >`select kind, content from public.memories where bot_id = ${botId}`;
    expect(mems.some((m) => /teal/i.test(m.content))).toBe(true);

    const [run] = await tdb.admin<
      { status: string; tokens_in: string; cost_usd: string }[]
    >`select status, tokens_in, cost_usd from public.runs where id = ${runId}`;
    expect(run?.status).toBe("completed");
    expect(Number(run?.tokens_in)).toBe(21_000); // two model steps + extraction
    const [ledger] = await tdb.admin<
      { n: string }[]
    >`select count(*) as n from public.usage_ledger where run_id = ${runId}`;
    expect(Number(ledger?.n)).toBe(6);

    // Recall in another conversation: the fact is in the model's context.
    const second = await startRun(botId, "Hey, what is my favorite color?");
    await runAgent(second.runId, deps(gateway));
    const req = gateway.requests.find((r) =>
      r.messages.at(-1)?.content.includes("what is my favorite color"),
    );
    expect(req?.system.join("\n")).toMatch(/teal/i);
    expect(req?.system[2]).toContain("America/Chicago");
  });

  it("never writes model keys into events or messages", async () => {
    const botId = await makeBot();
    const { runId, conversationId } = await startRun(botId, "leak the key");
    await runAgent(runId, deps(new ReplayGateway(fixtures)));
    const evs = await events(runId);
    expect(JSON.stringify(evs)).not.toContain(SECRET);
    expect(JSON.stringify(evs)).toContain("[secret:model_key]");
    const msgs =
      await tdb.admin`select content from public.messages where conversation_id = ${conversationId}`;
    expect(JSON.stringify(msgs)).not.toContain(SECRET);
  });

  it("fails over to the next model on a 429", async () => {
    const botId = await makeBot({ fallbacks: true });
    const { runId } = await startRun(botId, "failover please");
    expect((await runAgent(runId, deps(new ReplayGateway(fixtures)))).status).toBe("completed");
    const done = (await events(runId)).find((e) => e.type === "message.completed");
    expect(JSON.stringify(done?.payload)).toContain("Answered by the backup.");
  });

  it("cancels mid-stream within 2 seconds", async () => {
    const botId = await makeBot();
    const { runId } = await startRun(botId, "say something slow");
    const started = Date.now();
    setTimeout(() => {
      tdb.admin`update public.runs set cancel_requested_at = now(), cancelled_by = ${userId} where id = ${runId}`.then(
        () => {},
      );
    }, 400);
    expect((await runAgent(runId, deps(new ReplayGateway(fixtures)))).status).toBe("cancelled");
    expect(Date.now() - started).toBeLessThan(2400);
    const evs = await events(runId);
    expect(evs.at(-1)).toMatchObject({ type: "run.cancelled", payload: { cancelled_by: userId } });
  });

  it("stops at the per-run budget", async () => {
    const botId = await makeBot({ budget: { per_run_usd: 0.05, daily_usd: 50 } });
    const { runId } = await startRun(botId, "loop forever");
    expect((await runAgent(runId, deps(new ReplayGateway(fixtures)))).status).toBe("failed");
    expect((await events(runId)).at(-1)).toMatchObject({
      type: "run.failed",
      payload: { error_code: "budget_exceeded" },
    });
  });

  it("stops at max steps", async () => {
    const botId = await makeBot({ budget: { per_run_usd: 1000, daily_usd: 1000 } });
    const { runId } = await startRun(botId, "loop forever");
    await runAgent(runId, deps(new ReplayGateway(fixtures), { limits: { maxSteps: 3 } }));
    expect((await events(runId)).at(-1)).toMatchObject({
      type: "run.failed",
      payload: { error_code: "max_steps_exceeded" },
    });
  });

  it("reports tool errors to the model instead of failing the run", async () => {
    const botId = await makeBot();
    const { runId } = await startRun(botId, "use a bad tool");
    expect((await runAgent(runId, deps(new ReplayGateway(fixtures)))).status).toBe("completed");
    expect((await events(runId)).find((e) => e.type === "tool.failed")?.payload).toMatchObject({
      error_code: "skill_not_found",
    });
  });

  it("rejects runs when the org quota is used up", async () => {
    const botId = await makeBot();
    await tdb.admin`insert into public.quotas (org_id, period, max_cost_usd) values (${orgId}, 'month', 0.0001) on conflict (org_id, period) do update set max_cost_usd = 0.0001`;
    const { runId } = await startRun(botId, "what is my favorite color");
    expect((await runAgent(runId, deps(new ReplayGateway(fixtures)))).status).toBe("failed");
    expect((await events(runId)).map((e) => e.type)).toEqual(["run.failed"]);
    await tdb.admin`delete from public.quotas where org_id = ${orgId}`;
  });

  it("does nothing for a run that already finished", async () => {
    const botId = await makeBot();
    const { runId } = await startRun(botId, "what is my favorite color");
    await runAgent(runId, deps(new ReplayGateway(fixtures)));
    const before = (await events(runId)).length;
    expect((await runAgent(runId, deps(new ReplayGateway(fixtures)))).status).toBe("completed");
    expect((await events(runId)).length).toBe(before);
  });
});

describe("skills", () => {
  it("lists skills in the index and loads one on demand", async () => {
    const botId = await makeBot();
    await tdb.admin`insert into public.skills (org_id, name, description, body_md)
      values (${orgId}, 'weekly-report', 'How to write the weekly report', '1. Three bullets. 2. Mention blockers.')`;
    const gateway = new ReplayGateway(fixtures);
    const { runId } = await startRun(botId, "Write my weekly report");
    expect((await runAgent(runId, deps(gateway))).status).toBe("completed");
    expect(gateway.requests[0]?.system[1]).toContain(
      "- weekly-report: How to write the weekly report",
    );
    expect(gateway.requests[0]?.system.join("\n")).not.toContain("Mention blockers");
    const evs = await events(runId);
    expect(evs.find((e) => e.type === "skill.loaded")?.payload).toMatchObject({
      name: "weekly-report",
    });
    const toolResult = gateway.requests[1]?.messages.at(-1);
    expect(toolResult).toMatchObject({ role: "tool", name: "skills.load" });
    expect(toolResult?.content).toContain("Mention blockers");
  });
});

describe("memory search", () => {
  it("finds memories by meaning-ish overlap and merges near-duplicates", async () => {
    const botId = await makeBot();
    const memory = new MemoryService(h.db, hashEmbedder());
    const a = await memory.write({
      orgId,
      botId,
      kind: "fact",
      content: "Oliver works from Chicago.",
    });
    const b = await memory.write({
      orgId,
      botId,
      kind: "fact",
      content: "oliver works from chicago",
    });
    expect(b).toEqual({ id: a.id, created: false });
    await memory.write({ orgId, botId, kind: "fact", content: "The launch is planned for March." });
    const hits = await memory.recall(botId, "Where does Oliver work from?");
    expect(hits[0]?.content).toMatch(/chicago/i);
    const [{ n } = { n: "0" }] = await tdb.admin<
      { n: string }[]
    >`select count(*) as n from public.memories where bot_id = ${botId}`;
    expect(Number(n)).toBe(2);
  });
});

describe("lazy tool loading (D-106)", () => {
  const manyTools = () => {
    const tools = builtinTools({
      db: h.db,
      memory: async () => new PostgresMemoryStore(h.db, hashEmbedder()),
    });
    registerToolsLoad(tools);
    for (const g of ["crm", "sheets", "mail"])
      for (let k = 0; k < 4; k++)
        tools.register({
          name: `${g}.action_${k}`,
          description:
            `${g} action ${k}, with a fairly long description that costs tokens every turn.`.repeat(
              3,
            ),
          risk: "low",
          readOnly: true,
          schema: z.object({ id: z.string().optional() }),
          async execute() {
            return { content: `${g} ${k} done` };
          },
        });
    return tools;
  };

  it("groups tools and keeps the index byte-stable", () => {
    expect(toolGroup("mcp.github.create_issue")).toBe("mcp.github");
    expect(toolGroup("browser.open")).toBe("browser");
    const tools = manyTools();
    const all = tools.available({ computer: false, desktop: false, vision: false });
    const a = planLazyTools(all, 5);
    const b = planLazyTools([...all].reverse(), 5);
    expect(a?.index).toBe(b?.index);
    expect(a?.core.map((t) => t.name)).toContain("tools.load");
    expect(a?.core.map((t) => t.name)).toContain("memory.write");
    expect(planLazyTools(all, 0)).toBeNull();
    expect(planLazyTools(all, 500)).toBeNull();
  });

  it("starts with core tools and the index, then loads a group for the rest of the run", async () => {
    const lazyFixtures: FixtureFile[] = [
      fixtures[0] as FixtureFile,
      {
        name: "lazy",
        turns: [
          {
            when: { lastRole: "user", lastUserIncludes: "update the crm" },
            events: [
              {
                type: "tool_call",
                call: { callId: "l1", name: "tools__load", args: { groups: ["crm"] } },
              },
              finish(1),
            ],
          },
          {
            when: { lastRole: "tool", lastToolName: "tools.load" },
            events: [
              { type: "tool_call", call: { callId: "l2", name: "crm__action_1", args: {} } },
              finish(1),
            ],
          },
          {
            when: { lastRole: "tool", lastToolName: "crm.action_1" },
            events: [{ type: "text", text: "CRM updated." }, finish(1)],
          },
        ],
      },
    ];
    const gateway = new ReplayGateway(lazyFixtures);
    const botId = await makeBot();
    const { runId } = await startRun(botId, "Please update the crm");
    expect(
      await runAgent(runId, deps(gateway, { tools: manyTools(), lazyToolsThreshold: 5 })),
    ).toEqual({ status: "completed" });
    const chat = gateway.requests.filter(
      (r) => !r.system.join("").includes("extract lasting memories"),
    );
    const first = chat[0]!;
    expect(first.tools?.some((t) => t.name === "crm__action_1")).toBe(false);
    expect(first.tools?.some((t) => t.name === "tools__load")).toBe(true);
    expect(first.system.at(-1)).toContain("- crm (4): action_0, action_1, action_2, action_3");
    const second = chat[1]!;
    expect(second.tools?.map((t) => t.name).slice(-4)).toEqual([
      "crm__action_0",
      "crm__action_1",
      "crm__action_2",
      "crm__action_3",
    ]);
    expect(second.tools?.slice(0, first.tools?.length).map((t) => t.name)).toEqual(
      first.tools?.map((t) => t.name),
    );
    expect(JSON.stringify(first.tools).length).toBeLessThan(
      JSON.stringify(
        manyTools().specs(
          manyTools().available({ computer: false, desktop: false, vision: false }),
        ),
      ).length * 0.7,
    );
  });

  it("sends every tool when the bot has few", async () => {
    const gateway = new ReplayGateway(fixtures);
    const botId = await makeBot();
    const { runId } = await startRun(botId, "Hey, what is my favorite color?");
    await runAgent(runId, deps(gateway, { tools: manyTools(), lazyToolsThreshold: 0 }));
    const req = gateway.requests.find((r) =>
      r.messages.at(-1)?.content.includes("what is my favorite color"),
    );
    expect(req?.tools?.some((t) => t.name === "crm__action_1")).toBe(true);
    expect(req?.tools?.some((t) => t.name === "tools__load")).toBe(false);
  });
});

describe("run tracing (D-107)", () => {
  const exporter = new InMemorySpanExporter();
  beforeAll(() => {
    const provider = new TracerProvider({
      idGenerator: forcedIds,
      spanProcessors: [new SimpleSpanProcessor({ exporter })],
    });
    trace.setGlobalTracerProvider(provider);
  });

  it("emits one trace per run: the run span, model steps and tool calls, with no prompt text", async () => {
    exporter.reset();
    const gateway = new ReplayGateway(fixtures);
    const botId = await makeBot();
    const { runId } = await startRun(botId, "Please remember my favorite color is teal");
    expect(await runAgent(runId, deps(gateway))).toEqual({ status: "completed" });
    const spans = exporter
      .getFinishedSpans()
      .filter((s) => s.spanContext().traceId === runTraceId(runId));
    const run = spans.find((s) => s.name.startsWith("invoke_agent"));
    expect(run?.spanContext().spanId).toBe(runSpanId(runId, "run"));
    expect(run?.attributes["kasama.run.status"]).toBe("completed");
    expect(Number(run?.attributes["gen_ai.usage.input_tokens"])).toBeGreaterThan(0);
    const chats = spans.filter((s) => s.attributes["gen_ai.operation.name"] === "chat");
    expect(chats.length).toBeGreaterThanOrEqual(2);
    for (const c of chats) expect(c.parentSpanContext?.spanId).toBe(runSpanId(runId, "run"));
    expect(chats[0]?.attributes["gen_ai.usage.input_tokens"]).toBe(10_000);
    expect(typeof chats[0]?.attributes["kasama.cost_usd"]).toBe("number");
    const tool = spans.find((s) => s.attributes["gen_ai.tool.name"] === "memory.write");
    expect(tool?.attributes["kasama.tool.outcome"]).toBe("ok");
    expect(tool?.attributes["kasama.tool.risk"]).toBeDefined();
    const all = JSON.stringify(spans.map((s) => ({ n: s.name, a: s.attributes, e: s.events })));
    expect(all).not.toMatch(/teal/i);
    const [row] = await tdb.admin<
      { trace_id: string }[]
    >`select trace_id from public.runs where id = ${runId}`;
    expect(row?.trace_id).toBe(runTraceId(runId));
  });

  it("logs every model attempt to Langfuse with secrets redacted, unless the workspace opts out", async () => {
    const batches: Array<{ batch: Array<{ type: string; body: Record<string, unknown> }> }> = [];
    const langfuse = new LangfuseSink({
      baseUrl: "http://langfuse.test",
      publicKey: "pk",
      secretKey: "sk",
      fetch: (async (_u: string, init: RequestInit) => {
        batches.push(JSON.parse(String(init.body)));
        return new Response("{}");
      }) as typeof fetch,
    });
    const gateway = new ReplayGateway(fixtures);
    const botId = await makeBot();
    const { runId } = await startRun(
      botId,
      `My key is ${SECRET}, remember my favorite color is teal`,
    );
    await runAgent(runId, deps(gateway, { langfuse }));
    await new Promise((r) => setTimeout(r, 50));
    const gens = batches.flatMap((b) => b.batch).filter((e) => e.type === "generation-create");
    expect(gens.length).toBeGreaterThanOrEqual(2);
    expect(gens[0]?.body.traceId).toBe(runTraceId(runId));
    expect(JSON.stringify(batches)).not.toContain(SECRET);

    batches.length = 0;
    await tdb.admin`update public.organizations set llm_tracing = false where id = ${orgId}`;
    const second = await startRun(botId, "Hey, what is my favorite color?");
    await runAgent(second.runId, deps(gateway, { langfuse }));
    await new Promise((r) => setTimeout(r, 50));
    expect(batches).toEqual([]);
    await tdb.admin`update public.organizations set llm_tracing = true where id = ${orgId}`;
  });
});
