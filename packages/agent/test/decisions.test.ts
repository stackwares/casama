/**
 * Decision models (docs/DECISION-MODEL-PLAN.md, D-454): the OpenRouter adapter, decide() in each
 * mode, and the uses in a run: with a use off or in shadow the run does exactly what it did before.
 */
import { createDb, type DbHandle } from "@casama/db";
import { createAuthUser, startTestDatabase, type TestDatabase } from "@casama/db/testing";
import { type DecisionSettings, decisionSettings } from "@casama/domain";
import { afterAll, beforeAll, beforeEach, describe, expect, it } from "vitest";
import { z } from "zod";
import { NOTHING_NEW } from "../src/checkins.ts";
import { cutBytes, type DecisionDeps, decide, sweepDecisionLog } from "../src/decide.ts";
import { SCAN_GATE_QUESTIONS } from "../src/decision-uses.ts";
import {
  type DecisionBackend,
  type DecisionCall,
  decisionRequestBody,
  OpenRouterDecisions,
  parseDecisionResponse,
} from "../src/gateway/decisions.ts";
import type { GatewayEvent, ModelGateway, ModelRequest } from "../src/gateway/types.ts";
import {
  builtinTools,
  CredentialResolver,
  directSteps,
  hashEmbedder,
  PostgresMemoryStore,
  runAgent,
} from "../src/index.ts";

const Q = {
  ok: { type: "yesno" as const, ask: "Is it ok?" },
  kind: {
    type: "choice" as const,
    options: { person: "a person", notice: "a notice", other: "else" },
  },
  level: { type: "score" as const, levels: ["low", "mid", "high"] },
};

describe("the OpenRouter adapter", () => {
  it("sends yes/no as noul, choices as criteria, and refuses providers that keep data", () => {
    const body = decisionRequestBody({
      model: "typesafe/jev-1.14",
      state: "text",
      questions: Q,
      user: "org-1",
      timeoutMs: 1000,
    });
    expect(body).toEqual({
      model: "typesafe/jev-1.14",
      state: "text",
      questions: {
        ok: { type: "noul", instructions: "Is it ok?" },
        kind: {
          type: "choice",
          instructions: "Pick the option that fits best.",
          criteria: Q.kind.options,
        },
        level: {
          type: "score",
          instructions: "Pick the level that fits best.",
          criteria: ["low", "mid", "high"],
        },
      },
      provider: { data_collection: "deny" },
      user: "org-1",
    });
  });

  it("reads each answer type, usage and cost; anything missing is none", () => {
    const r = parseDecisionResponse(Q, {
      answers: {
        ok: { type: "noul", noul: 0.07 },
        kind: {
          type: "choice",
          choice: "notice",
          confidence: 0.75,
          probabilities: { person: 0.1, notice: 0.8, other: 0.1 },
        },
      },
      usage: { input_tokens: 476, output_tokens: 70, cost: 0.000019992 },
    });
    expect(r.answers.ok).toEqual({ type: "yesno", p: 0.07 });
    expect(r.answers.kind).toEqual({
      type: "choice",
      choice: "notice",
      p: { person: 0.1, notice: 0.8, other: 0.1 },
    });
    expect(r.answers.level).toEqual({ type: "none" });
    expect(r.inputTokens).toBe(476);
    expect(r.costUsd).toBeCloseTo(0.000019992);
    expect(parseDecisionResponse(Q, "nope").error).toBe("bad_body");
    expect(
      parseDecisionResponse(Q, { answers: { kind: { choice: "made-up" } } }).answers.kind,
    ).toEqual({ type: "none" });
  });

  it("turns a rate limit, a spent key, a timeout and a bad body into no answers", async () => {
    const call: DecisionCall = { model: "m", state: "s", questions: Q, timeoutMs: 50 };
    const status = (code: number) =>
      new OpenRouterDecisions("k", { fetch: async () => new Response("{}", { status: code }) });
    expect((await status(429).decide(call)).error).toBe("http_429");
    expect((await status(402).decide(call)).error).toBe("http_402");
    const slow = new OpenRouterDecisions("k", {
      fetch: (_url, init) =>
        new Promise((_, reject) =>
          init?.signal?.addEventListener("abort", () =>
            reject(Object.assign(new Error("t"), { name: "TimeoutError" })),
          ),
        ),
    });
    const r = await slow.decide(call);
    expect(r.error).toBe("timeout");
    expect(Object.values(r.answers).every((a) => a.type === "none")).toBe(true);
    const bad = new OpenRouterDecisions("k", { fetch: async () => new Response("not json") });
    expect((await bad.decide(call)).error).toBe("bad_body");
    let url = "";
    let auth = "";
    const ok = new OpenRouterDecisions("key-1", {
      base: "http://or.test/",
      fetch: async (u, init) => {
        url = String(u);
        auth = String((init?.headers as Record<string, string> | undefined)?.authorization);
        return Response.json({ answers: { ok: { noul: 0.9 } } });
      },
    });
    expect((await ok.decide(call)).answers.ok).toEqual({ type: "yesno", p: 0.9 });
    expect(url).toBe("http://or.test/api/alpha/decisions");
    expect(auth).toBe("Bearer key-1");
  });

  it("cuts the input at 24,000 bytes without splitting a character", () => {
    expect(cutBytes("short")).toBe("short");
    const long = "é".repeat(20_000); // 40,000 bytes
    const cut = cutBytes(long);
    expect(Buffer.byteLength(cut)).toBeLessThanOrEqual(24_000);
    expect(cut.endsWith("é")).toBe(true);
  });
});

// ---------------------------------------------------------------------------------------------

let tdb: TestDatabase;
let h: DbHandle;
let orgId: string;
let userId: string;
let credId: string;

/** A decision model that answers every yes/no with `p[model]` (default 0.5), and counts calls. */
function fakeBackend(p: Record<string, number | Record<string, number>> = {}) {
  const calls: DecisionCall[] = [];
  const backend: DecisionBackend = {
    async decide(call) {
      calls.push(call);
      const given = p[call.model];
      const answers = Object.fromEntries(
        Object.entries(call.questions).map(([name, q]) => {
          const v = typeof given === "number" ? given : (given?.[name] ?? 0.5);
          return [
            name,
            q.type === "yesno"
              ? { type: "yesno" as const, p: v }
              : q.type === "choice"
                ? {
                    type: "choice" as const,
                    choice: Object.keys(q.options)[0] as string,
                    p: { [Object.keys(q.options)[0] as string]: v },
                  }
                : { type: "score" as const, score: 0 },
          ];
        }),
      );
      return { answers, inputTokens: 400, costUsd: 0.00002, latencyMs: 12 };
    },
  };
  return { backend, calls };
}

function decisionDeps(
  raw: Partial<DecisionSettings> | Record<string, unknown>,
  backend: DecisionBackend,
  billable = false,
): DecisionDeps {
  const settings = decisionSettings(raw);
  return { settings: async () => settings, backend, billable };
}

beforeAll(async () => {
  tdb = await startTestDatabase();
  h = createDb(tdb.url, { max: 5 });
  userId = (await createAuthUser(tdb.admin, "decide@example.com")).id;
  const [org] = await tdb.admin<
    { id: string }[]
  >`insert into public.organizations (name, slug) values ('Decide', 'decide-org') returning id`;
  orgId = org!.id;
  await tdb.admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${userId}, 'owner')`;
  const [cred] = await tdb.admin<{ id: string }[]>`
    insert into public.model_credentials (org_id, provider, label, vault_secret_id)
    values (${orgId}, 'openrouter', 'Main', vault.create_secret('sk-live-SECRET-1234567890')) returning id`;
  credId = cred!.id;
});
afterAll(async () => {
  await h?.close();
  await tdb?.stop();
});

const logOf = (runId: string) =>
  tdb.admin<
    {
      use: string;
      model: string;
      shadow: boolean;
      action: string;
      answers: Record<string, unknown>;
      outcome: Record<string, unknown> | null;
    }[]
  >`select use, model, shadow, action, answers, outcome from public.decision_log where run_id = ${runId} order by model`;
const ledgerOf = (runId: string) =>
  tdb.admin<
    {
      model: string;
      billable: boolean;
      cost_usd: string;
      upstream_cost_usd: string | null;
      meta: Record<string, unknown>;
    }[]
  >`select model, billable, cost_usd, upstream_cost_usd, meta from public.usage_ledger where run_id = ${runId} and meta ->> 'purpose' like 'decide:%'`;

async function newBot(autonomy = "ask_risky") {
  const policy = { primary: { credential_id: credId, model: "fixture-primary" } };
  const [bot] = await tdb.admin<{ id: string }[]>`
    insert into public.bots (org_id, created_by, name, autonomy, model_policy, budget)
    values (${orgId}, ${userId}, 'Ada', ${autonomy}, ${tdb.admin.json(policy)}, ${tdb.admin.json({ per_run_usd: 50, daily_usd: 500 })})
    returning id`;
  return bot!.id;
}

describe("decide()", () => {
  it("off, or with no key, calls nothing and logs nothing", async () => {
    const botId = await newBot();
    const [run] = await tdb.admin<
      { id: string }[]
    >`insert into public.runs (org_id, bot_id, created_by) values (${orgId}, ${botId}, ${userId}) returning id`;
    const fake = fakeBackend();
    const input = {
      use: "scan_gate" as const,
      orgId,
      botId,
      runId: run!.id,
      state: "x",
      questions: SCAN_GATE_QUESTIONS,
    };
    const off = await decide(h.db, decisionDeps({}, fake.backend), input);
    expect(off.mode).toBe("off");
    const noKey = await decide(
      h.db,
      { ...decisionDeps({ uses: { scan_gate: { mode: "shadow" } } }, fake.backend), backend: null },
      input,
    );
    expect(noKey.mode).toBe("off");
    expect(await decide(h.db, undefined, input)).toMatchObject({ mode: "off" });
    expect(fake.calls).toHaveLength(0);
    expect(await logOf(run!.id)).toHaveLength(0);
  });

  it("in shadow asks every shadow model, logs them, charges nobody and acts on nothing", async () => {
    const botId = await newBot();
    const [run] = await tdb.admin<
      { id: string }[]
    >`insert into public.runs (org_id, bot_id, created_by) values (${orgId}, ${botId}, ${userId}) returning id`;
    const fake = fakeBackend({ "a/one": 0.02, "b/two": 0.6 });
    const d = await decide(
      h.db,
      decisionDeps(
        { shadow_models: ["a/one", "b/two"], uses: { scan_gate: { mode: "shadow" } } },
        fake.backend,
        true,
      ),
      {
        use: "scan_gate",
        orgId,
        botId,
        runId: run!.id,
        state: "x",
        questions: SCAN_GATE_QUESTIONS,
      },
    );
    expect(d.mode).toBe("shadow");
    expect(Object.values(d.answers).every((a) => a.type === "none")).toBe(true);
    const log = await logOf(run!.id);
    expect(log.map((r) => [r.model, r.shadow])).toEqual([
      ["a/one", true],
      ["b/two", true],
    ]);
    // Probabilities only, never the text.
    expect(log[0]?.answers).toEqual({ needs_attention: 0.02, from_person: 0.02, time_bound: 0.02 });
    const ledger = await ledgerOf(run!.id);
    expect(ledger).toHaveLength(2);
    for (const row of ledger) {
      expect(row.billable).toBe(false);
      expect(Number(row.cost_usd)).toBe(0);
      expect(Number(row.upstream_cost_usd)).toBeGreaterThan(0);
      expect(row.meta).toMatchObject({ purpose: "decide:scan_gate", shadow: true });
    }
  });

  it("on asks the chosen model, returns its answers and charges like a background call", async () => {
    const botId = await newBot();
    const [run] = await tdb.admin<
      { id: string }[]
    >`insert into public.runs (org_id, bot_id, created_by) values (${orgId}, ${botId}, ${userId}) returning id`;
    const fake = fakeBackend({ "a/one": 0.95 });
    const d = await decide(
      h.db,
      decisionDeps(
        { model: "a/one", shadow_models: ["b/two"], uses: { reply_check: { mode: "on" } } },
        fake.backend,
        true,
      ),
      { use: "reply_check", orgId, botId, runId: run!.id, state: "x", questions: Q },
    );
    expect(d.mode).toBe("on");
    expect(d.answers.ok).toEqual({ type: "yesno", p: 0.95 });
    expect(d.logId).toBeTruthy();
    expect(fake.calls.map((c) => c.model)).toEqual(["a/one"]);
    const [row] = await ledgerOf(run!.id);
    expect(row?.billable).toBe(true);
    expect(Number(row?.cost_usd)).toBeGreaterThan(0);
  });
});

// ---------------------------------------------------------------------------------------------
// The scan gate in a scan run
// ---------------------------------------------------------------------------------------------

const GMAIL = "composio.apps.gmail_fetch_emails";
const CALENDAR = "composio.apps.googlecalendar_events_list";
let mail = "";
const inbox = (...ids: string[]) =>
  JSON.stringify({
    data: {
      messages: ids.map((id) => ({ messageId: id, threadId: `t-${id}`, subject: `Mail ${id}` })),
    },
  });
const calendarEmpty = '{"data":{"items":[]}}';
const finish: GatewayEvent = {
  type: "finish",
  usage: { inputTokens: 100, outputTokens: 10 },
  finishReason: "stop",
  model: "",
};
function scripted(reply: (req: ModelRequest, n: number) => GatewayEvent[]) {
  const requests: ModelRequest[] = [];
  const gateway: ModelGateway = {
    async *stream(req) {
      requests.push(req);
      for (const ev of reply(req, requests.length)) yield ev;
      yield finish;
    },
  };
  return { gateway, requests };
}
const isMemoryPass = (req: ModelRequest) =>
  req.system.join("\n").includes("extract lasting memories");
const isChecker = (req: ModelRequest) =>
  req.system.join("\n").includes("You check an AI teammate's final reply");

function runDeps(
  gateway: ModelGateway,
  decisions?: DecisionDeps,
  extra?: (t: ReturnType<typeof builtinTools>) => void,
) {
  const embedder = hashEmbedder();
  const tools = builtinTools({
    db: h.db,
    memory: async () => new PostgresMemoryStore(h.db, embedder),
  });
  const read = (name: string, result: () => string) =>
    tools.register({
      name,
      description: `Reads ${name}.`,
      risk: "low",
      readOnly: true,
      schema: z.object({}).passthrough(),
      async execute() {
        return { content: result() };
      },
    });
  read(GMAIL, () => mail);
  read(CALENDAR, () => calendarEmpty);
  read("composio.apps.googlecalendar_find_event", () => calendarEmpty);
  tools.register({
    name: "suggestions.add",
    description: "Suggests something to the person.",
    risk: "low",
    schema: z.object({ title: z.string() }),
    async execute() {
      return { content: "Suggested." };
    },
  });
  extra?.(tools);
  return {
    db: h.db,
    gateway,
    tools,
    credentials: new CredentialResolver(h.db),
    embedderFor: async () => embedder,
    step: directSteps,
    deltaIntervalMs: 20,
    cancelPollMs: 50,
    fallback: { backoffMs: 1, sleep: async () => {} },
    waitForApproval: async () => {},
    decisions,
  };
}

async function scanBot() {
  const botId = await newBot();
  await tdb.admin`
    insert into public.bot_checkins (bot_id, org_id, user_id, enabled, daily_cap_usd)
    values (${botId}, ${orgId}, ${userId}, true, 1)`;
  const [routine] = await tdb.admin<{ id: string }[]>`
    insert into public.routines (org_id, bot_id, name, instructions_md, kind, notify, created_by)
    values (${orgId}, ${botId}, 'Check-in scan', 'Check-in scan.', 'scan', false, ${userId}) returning id`;
  return { botId, routineId: routine!.id };
}
async function scan(b: { botId: string; routineId: string }) {
  const [run] = await tdb.admin<{ id: string }[]>`
    insert into public.runs (org_id, bot_id, created_by, trigger, routine_id, budget)
    values (${orgId}, ${b.botId}, ${userId}, 'routine', ${b.routineId}, ${tdb.admin.json({ task: "Check-in scan." })})
    returning id`;
  return run!.id;
}
const quietModel = () =>
  scripted((req) => [{ type: "text", text: isMemoryPass(req) ? '{"memories":[]}' : NOTHING_NEW }]);

describe("the scan gate", () => {
  beforeEach(() => {
    mail = inbox("m1");
  });

  it("on: changed reads it is sure hold nothing end the scan without the model, at most 3 in a row", async () => {
    const bot = await scanBot();
    const fake = fakeBackend({ "a/one": 0.02 });
    const decisions = decisionDeps(
      { model: "a/one", uses: { scan_gate: { mode: "on" } } },
      fake.backend,
    );
    // The first scan has no digest to compare with: the gate decides.
    const statuses: number[] = [];
    for (let k = 0; k < 4; k++) {
      mail = inbox(`n${k}`);
      const m = quietModel();
      const runId = await scan(bot);
      expect((await runAgent(runId, runDeps(m.gateway, decisions))).status).toBe("completed");
      statuses.push(m.requests.filter((r) => !isMemoryPass(r)).length);
    }
    // Three skipped, the fourth goes to the model.
    expect(statuses).toEqual([0, 0, 0, 1]);
    const actions = await tdb.admin<{ action: string }[]>`
      select action from public.decision_log where bot_id = ${bot.botId} order by created_at`;
    expect(actions.map((a) => a.action)).toEqual(["skipped", "skipped", "skipped", "ran"]);
  });

  it("on: an unsure answer runs the model as today", async () => {
    const bot = await scanBot();
    const decisions = decisionDeps(
      { model: "a/one", uses: { scan_gate: { mode: "on" } } },
      fakeBackend({ "a/one": { needs_attention: 0.02, from_person: 0.4, time_bound: 0.01 } })
        .backend,
    );
    const m = quietModel();
    await runAgent(await scan(bot), runDeps(m.gateway, decisions));
    expect(m.requests.filter((r) => !isMemoryPass(r))).toHaveLength(1);
  });

  it("shadow: the model runs as today, the answers are logged and labelled", async () => {
    const bot = await scanBot();
    const decisions = decisionDeps(
      { shadow_models: ["a/one", "b/two"], uses: { scan_gate: { mode: "shadow" } } },
      fakeBackend({ "a/one": 0.01, "b/two": 0.01 }).backend,
    );
    const m = quietModel();
    const runId = await scan(bot);
    await runAgent(runId, runDeps(m.gateway, decisions));
    expect(m.requests.filter((r) => !isMemoryPass(r))).toHaveLength(1);
    expect((await logOf(runId)).map((r) => r.shadow)).toEqual([true, true]);
    const swept = await sweepDecisionLog(h.db);
    expect(swept.labelled).toBeGreaterThanOrEqual(2);
    expect((await logOf(runId))[0]?.outcome).toMatchObject({ suggested: false, accepted: false });
  });
});

// ---------------------------------------------------------------------------------------------
// The reply check and the tool-call gate in a chat run
// ---------------------------------------------------------------------------------------------

async function chat(botId: string, text: string) {
  const [conv] = await tdb.admin<
    { id: string }[]
  >`insert into public.conversations (org_id, bot_id) values (${orgId}, ${botId}) returning id`;
  const [run] = await tdb.admin<{ id: string }[]>`
    insert into public.runs (org_id, bot_id, conversation_id, created_by) values (${orgId}, ${botId}, ${conv!.id}, ${userId}) returning id`;
  await tdb.admin`insert into public.messages (org_id, conversation_id, role, author_user_id, content, run_id)
    values (${orgId}, ${conv!.id}, 'user', ${userId}, ${tdb.admin.json([{ type: "text", text }])}, ${run!.id})`;
  return run!.id;
}
const oneStep = (tool: string) =>
  scripted((req, n) => {
    if (isMemoryPass(req)) return [{ type: "text", text: '{"memories":[]}' }];
    if (isChecker(req)) return [{ type: "text", text: '{"ok":true}' }];
    const last = req.messages.at(-1);
    if (last?.role === "tool") return [{ type: "text", text: "Sent it." }];
    return n < 10
      ? [
          {
            type: "tool_call",
            call: { callId: `c${n}`, name: tool.replace(".", "__"), args: { to: "a@b.c" } },
          },
        ]
      : [{ type: "text", text: "Done." }];
  });
const sender = (sent: string[]) => (t: ReturnType<typeof builtinTools>) =>
  t.register({
    name: "mail.send",
    description: "Sends a mail.",
    risk: "medium",
    sendsOut: true,
    schema: z.object({ to: z.string() }),
    async execute(args) {
      sent.push(args.to);
      return { content: "sent" };
    },
  });

describe("the reply check", () => {
  it("off: a one-step run is not checked, as today", async () => {
    const botId = await newBot("autonomous");
    const m = oneStep("mail.send");
    await runAgent(await chat(botId, "mail a@b.c"), runDeps(m.gateway, undefined, sender([])));
    expect(m.requests.some(isChecker)).toBe(false);
  });

  it("on: a confident flag sends a one-step run to today's checker; the label is kept", async () => {
    const botId = await newBot("autonomous");
    const m = oneStep("mail.send");
    const decisions = decisionDeps(
      { model: "a/one", uses: { reply_check: { mode: "on" } } },
      fakeBackend({ "a/one": { overclaims: 0.97, unfinished: 0.1, worth_remembering: 0.5 } })
        .backend,
    );
    const runId = await chat(botId, "mail a@b.c");
    await runAgent(runId, runDeps(m.gateway, decisions, sender([])));
    expect(m.requests.some(isChecker)).toBe(true);
    const [row] = await logOf(runId);
    expect(row?.action).toBe("flagged");
    expect(row?.outcome).toMatchObject({ checked: true, checker_flagged: false, memories: 0 });
  });

  it("on: a confident 'nothing to remember' skips the memory call", async () => {
    const botId = await newBot("autonomous");
    const m = oneStep("mail.send");
    const decisions = decisionDeps(
      { model: "a/one", uses: { reply_check: { mode: "on" } } },
      fakeBackend({ "a/one": { overclaims: 0.1, unfinished: 0.1, worth_remembering: 0.02 } })
        .backend,
    );
    const runId = await chat(botId, "mail a@b.c");
    await runAgent(runId, runDeps(m.gateway, decisions, sender([])));
    expect(m.requests.some(isMemoryPass)).toBe(false);
    expect(m.requests.some(isChecker)).toBe(false);
    expect((await logOf(runId))[0]?.outcome).toMatchObject({ memory_skipped: true });
  });
});

describe("the tool-call gate", () => {
  it("on: an outgoing call the person likely didn't ask for asks first", async () => {
    const botId = await newBot("autonomous");
    const sent: string[] = [];
    const decisions = decisionDeps(
      { model: "a/one", uses: { tool_gate: { mode: "on" } } },
      fakeBackend({ "a/one": { asked_for: 0.03, outside_party: 0.9 } }).backend,
    );
    const runId = await chat(botId, "summarise my inbox");
    await runAgent(runId, runDeps(oneStep("mail.send").gateway, decisions, sender(sent)));
    const approvals = await tdb.admin<
      { tool_name: string }[]
    >`select tool_name from public.approvals where run_id = ${runId}`;
    expect(approvals.map((a) => a.tool_name)).toContain("mail.send");
    expect((await logOf(runId)).some((r) => r.action === "asked")).toBe(true);
  });

  it("shadow: nothing asks that didn't before", async () => {
    const botId = await newBot("autonomous");
    const sent: string[] = [];
    const decisions = decisionDeps(
      { shadow_models: ["a/one"], uses: { tool_gate: { mode: "shadow" } } },
      fakeBackend({ "a/one": 0.01 }).backend,
    );
    const runId = await chat(botId, "summarise my inbox");
    await runAgent(runId, runDeps(oneStep("mail.send").gateway, decisions, sender(sent)));
    const approvals = await tdb.admin`select 1 from public.approvals where run_id = ${runId}`;
    expect(approvals).toHaveLength(0);
    expect(sent.length).toBeGreaterThan(0);
  });
});

// ---------------------------------------------------------------------------------------------
// The watcher gate and push scoring, outside runs
// ---------------------------------------------------------------------------------------------

describe("the watcher gate", () => {
  async function watcher(botId: string, condition: string) {
    const [task] = await tdb.admin<
      { id: string }[]
    >`insert into public.tasks (org_id, title) values (${orgId}, 'Quote') returning id`;
    await tdb.admin`
      insert into public.watchers (org_id, bot_id, created_by, name, kind, target, condition_md, check_every_seconds)
      values (${orgId}, ${botId}, ${userId}, 'Reply', 'reply', ${tdb.admin.json({ task_id: task!.id })}, ${condition}, 60)`;
    return task!.id;
  }
  const comment = (taskId: string, body: string) =>
    tdb.admin`insert into public.task_comments (org_id, task_id, author_type, author_user_id, body_md) values (${orgId}, ${taskId}, 'user', ${userId}, ${body})`;

  it("on: a change it is sure doesn't match starts no run; shadow starts it as today", async () => {
    const { checkWatchers } = await import("../src/watchers.ts");
    const botId = await newBot();
    const taskId = await watcher(botId, "the client approves the quote");
    const started: string[] = [];
    const check = (decisions: DecisionDeps, at: number) =>
      checkWatchers(
        { db: h.db, fetch, startRun: async (id) => void started.push(id), decisions },
        new Date(Date.now() + at * 60_000),
      );
    const on = decisionDeps(
      { model: "a/one", uses: { watcher_gate: { mode: "on" } } },
      fakeBackend({ "a/one": 0.03 }).backend,
    );
    await comment(taskId, "first");
    await check(on, 2); // baseline
    await comment(taskId, "Can we talk on Monday?");
    expect(await check(on, 4)).toEqual([]);
    const shadow = decisionDeps(
      { shadow_models: ["a/one"], uses: { watcher_gate: { mode: "shadow" } } },
      fakeBackend({ "a/one": 0.03 }).backend,
    );
    await comment(taskId, "Approved, go ahead");
    const fired = await check(shadow, 6);
    expect(fired).toHaveLength(1);
    const rows = await tdb.admin<{ action: string; run_id: string | null; shadow: boolean }[]>`
      select action, run_id, shadow from public.decision_log where bot_id = ${botId} order by created_at`;
    expect(rows.map((r) => [r.shadow, r.action])).toEqual([
      [false, "skipped"],
      [true, "none"],
    ]);
    expect(rows[1]?.run_id).toBe(fired[0]);
  });
});

describe("push scoring", () => {
  it("on: a normal suggestion it scores low waits for the brief; urgent ones are never scored", async () => {
    const { NotificationService, RecordingPushSender } = await import("../src/index.ts");
    const { sendDueSuggestions } = await import("../src/checkins.ts");
    const botId = await newBot();
    const push = new RecordingPushSender();
    const notifications = new NotificationService(h.db, push);
    const fake = fakeBackend({ "a/one": 0.05 });
    const decisions = decisionDeps(
      { model: "a/one", uses: { push_score: { mode: "on" } } },
      fake.backend,
    );
    const due: Array<[string, string]> = [
      ["Read the newsletter", "normal"],
      ["Your card was declined", "urgent"],
    ];
    for (const [title, urgency] of due)
      await tdb.admin`
        insert into public.suggestions (org_id, bot_id, user_id, title, urgency, notify_at)
        values (${orgId}, ${botId}, ${userId}, ${title}, ${urgency}, now() - interval '1 minute')`;
    expect(await sendDueSuggestions(h.db, notifications, 100, decisions)).toBe(2);
    expect(fake.calls).toHaveLength(1);
    const rows = await tdb.admin<
      { urgency: string; push_status: string; held_reason: string | null }[]
    >`
      select urgency, push_status, held_reason from public.notifications
      where user_id = ${userId} and kind = 'suggestion' order by urgency`;
    expect(rows).toEqual([
      { urgency: "low", push_status: "held", held_reason: "low_urgency" },
      { urgency: "urgent", push_status: "sent", held_reason: null },
    ]);
    const [log] = await tdb.admin<{ action: string; subject_id: string }[]>`
      select action, subject_id from public.decision_log where use = 'push_score' and bot_id = ${botId}`;
    expect(log?.action).toBe("held");
  });
});

describe("the long-run check", () => {
  it("on: a run it is sure is repeating itself hears the 'deliver now' note early, once", async () => {
    const botId = await newBot("autonomous");
    let step = 0;
    const m = scripted((req) => {
      if (isMemoryPass(req)) return [{ type: "text", text: '{"memories":[]}' }];
      if (isChecker(req)) return [{ type: "text", text: '{"ok":true}' }];
      step++;
      return step < 7
        ? [
            {
              type: "tool_call",
              call: { callId: `r${step}`, name: "mail__send", args: { to: "a@b.c" } },
            },
          ]
        : [{ type: "text", text: "Done." }];
    });
    const decisions = decisionDeps(
      { model: "a/one", uses: { long_run: { mode: "on", first_step: 2, every: 2 } } },
      fakeBackend({ "a/one": { making_progress: 0.1, repeating: 0.97 } }).backend,
    );
    const runId = await chat(botId, "mail a@b.c");
    await runAgent(runId, runDeps(m.gateway, decisions, sender([])));
    const noted = m.requests.filter((r) =>
      r.messages.some((x) => x.role === "user" && x.content.includes("repeating the same steps")),
    );
    expect(noted.length).toBeGreaterThan(0);
    const rows = await logOf(runId);
    expect(rows.filter((r) => r.action === "warned")).toHaveLength(1);
  });
});

describe("in the worker", () => {
  it("shadow reply checks survive steps whose results are serialized, and still get labelled", async () => {
    // The worker keeps each step's result serialized (superjson); a promise in one comes back as
    // a plain object. A JSON round trip does the same to a promise.
    const serializing = async <T>(_name: string, fn: () => Promise<T>): Promise<T> => {
      const v = await fn();
      return v === undefined ? v : (JSON.parse(JSON.stringify(v)) as T);
    };
    const botId = await newBot("autonomous");
    const m = oneStep("mail.send");
    const fake = fakeBackend({ "a/one": 0.5 });
    const slow: DecisionBackend = {
      decide: (c) => new Promise((r) => setTimeout(() => r(fake.backend.decide(c)), 150)),
    };
    const decisions = decisionDeps(
      { shadow_models: ["a/one"], uses: { reply_check: { mode: "shadow" } } },
      slow,
    );
    const runId = await chat(botId, "mail a@b.c");
    const res = await runAgent(runId, {
      ...runDeps(m.gateway, decisions, sender([])),
      step: serializing,
    });
    expect(res.status).toBe("completed");
    await new Promise((r) => setTimeout(r, 500));
    const [row] = await logOf(runId);
    expect(row?.shadow).toBe(true);
    expect(row?.outcome).toMatchObject({ memories: 0, regex_correction: false });
  });
});
