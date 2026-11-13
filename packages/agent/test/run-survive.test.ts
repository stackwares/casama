/**
 * Runs that survive (D-268): waiting for a person doesn't use up the time limit, a reply cut off at
 * the output limit is continued, a stream that breaks part-way is tried again, an action in flight
 * when the worker restarted isn't done twice, and a long task is trimmed to fit the context.
 */
import { createDb, type DbHandle } from "@casama/db";
import { createAuthUser, startTestDatabase, type TestDatabase } from "@casama/db/testing";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { z } from "zod";
import { isContextOverflow, trimTurn } from "../src/context.ts";
import { withFallback } from "../src/gateway/fallback.ts";
import {
  type ChatMessage,
  type GatewayEvent,
  ModelCallError,
  type ModelGateway,
  type ResolvedModel,
} from "../src/gateway/types.ts";
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
let credId: string;

beforeAll(async () => {
  tdb = await startTestDatabase();
  h = createDb(tdb.url, { max: 5 });
  userId = (await createAuthUser(tdb.admin, "survivor@example.com")).id;
  const [org] = await tdb.admin<
    { id: string }[]
  >`insert into public.organizations (name, slug) values ('Survive Org', 'survive-org') returning id`;
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

async function startRun(text: string) {
  const policy = { primary: { credential_id: credId, model: "fixture-primary" } };
  const [bot] = await tdb.admin<{ id: string }[]>`
    insert into public.bots (org_id, created_by, name, model_policy, budget)
    values (${orgId}, ${userId}, 'Ada', ${tdb.admin.json(policy)}, ${tdb.admin.json({ per_run_usd: 50, daily_usd: 500 })})
    returning id`;
  const [convo] = await tdb.admin<
    { id: string }[]
  >`insert into public.conversations (org_id, bot_id) values (${orgId}, ${bot!.id}) returning id`;
  const [run] = await tdb.admin<{ id: string }[]>`
    insert into public.runs (org_id, bot_id, conversation_id, created_by) values (${orgId}, ${bot!.id}, ${convo!.id}, ${userId}) returning id`;
  await tdb.admin`
    insert into public.messages (org_id, conversation_id, role, author_user_id, content, run_id)
    values (${orgId}, ${convo!.id}, 'user', ${userId}, ${tdb.admin.json([{ type: "text", text }])}, ${run!.id})`;
  return run!.id;
}

const finish = (finishReason = "stop") => ({
  type: "finish" as const,
  usage: { inputTokens: 100, outputTokens: 10 },
  finishReason,
  model: "",
});
const memories = {
  when: { systemIncludes: "extract lasting memories" },
  events: [{ type: "text" as const, text: '{"memories":[]}' }, finish()],
};

/** Calls made to the probe tools, in order. */
const probed: string[] = [];
function deps(gateway: ModelGateway, extra: Partial<Parameters<typeof runAgent>[1]> = {}) {
  const embedder = hashEmbedder();
  const tools = builtinTools({
    db: h.db,
    memory: async () => new PostgresMemoryStore(h.db, embedder),
  });
  tools.register({
    name: "probe.send",
    description: "Sends something outside (always asks).",
    risk: "high",
    alwaysAsk: true,
    schema: z.object({ to: z.string() }),
    async execute(args) {
      probed.push(`send ${args.to}`);
      return { content: `Sent to ${args.to}.` };
    },
  });
  tools.register({
    name: "probe.post",
    description: "Posts something outside.",
    risk: "medium",
    schema: z.object({ to: z.string() }),
    async execute(args) {
      probed.push(`post ${args.to}`);
      return { content: `Posted to ${args.to}.` };
    },
  });
  tools.register({
    name: "probe.look",
    description: "Looks at something.",
    risk: "low",
    readOnly: true,
    schema: z.object({ at: z.string() }),
    async execute(args) {
      probed.push(`look ${args.at}`);
      return { content: `Saw ${args.at}. ${"x".repeat(Number(args.at) || 0)}` };
    },
  });
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
    ...extra,
  };
}

const replies = async (runId: string) =>
  (
    await tdb.admin<{ content: Array<{ text?: string }> }[]>`
      select content from public.messages where run_id = ${runId} and role = 'assistant' order by created_at`
  ).map((m) => m.content[0]?.text);

/** The messages of the last request that carried tool results (the memory step comes after it). */
const lastWithTools = (gateway: ReplayGateway) =>
  gateway.requests.filter((r) => r.messages.some((m) => m.role === "tool")).at(-1)?.messages ?? [];

describe("runs that survive (D-268)", () => {
  it("time spent waiting for an approval doesn't count toward the run's time limit", async () => {
    const fixtures: FixtureFile[] = [
      {
        name: "late-approval",
        turns: [
          memories,
          {
            when: { lastRole: "user", lastUserIncludes: "send the invoice" },
            events: [
              {
                type: "tool_call",
                call: { callId: "s1", name: "probe__send", args: { to: "acme" } },
              },
              finish(),
            ],
          },
          {
            when: { lastRole: "tool", lastToolName: "probe.send" },
            events: [{ type: "text", text: "Invoice sent." }, finish()],
          },
        ],
      },
    ];
    const runId = await startRun("Please send the invoice");
    const r = await runAgent(
      runId,
      deps(new ReplayGateway(fixtures), {
        // The limit is 1 second; the person takes 1.5 seconds to approve.
        limits: { wallTimeMs: 1000 },
        waitForApproval: async (approvalId) => {
          await new Promise((res) => setTimeout(res, 1500));
          await tdb.admin`update public.approvals set status = 'approved', decided_by = ${userId}, decided_at = now() where id = ${approvalId}`;
        },
      }),
    );
    expect(r.status).toBe("completed");
    expect(probed).toContain("send acme");
    expect(await replies(runId)).toEqual(["Invoice sent."]);
  });

  it("a reply cut off at the output limit is continued instead of passing as finished", async () => {
    const fixtures: FixtureFile[] = [
      {
        name: "cut-off",
        turns: [
          memories,
          {
            when: { lastRole: "user", lastUserIncludes: "cut off at the output limit" },
            events: [{ type: "text", text: "and the second half." }, finish()],
          },
          {
            when: { lastRole: "user", lastUserIncludes: "write the long report" },
            events: [{ type: "text", text: "The first half, " }, finish("length")],
          },
        ],
      },
    ];
    const gateway = new ReplayGateway(fixtures);
    const runId = await startRun("Write the long report");
    expect((await runAgent(runId, deps(gateway))).status).toBe("completed");
    expect(await replies(runId)).toEqual(["The first half, ", "and the second half."]);
    // The model was shown what it had written so far.
    const second = gateway.requests.find((r) =>
      r.messages.at(-1)?.content.includes("cut off at the output limit"),
    );
    expect(second?.messages.at(-2)).toMatchObject({
      role: "assistant",
      content: "The first half, ",
    });
  });

  it("a stream that breaks after it started is tried again, and the half-written draft is taken back", async () => {
    let calls = 0;
    const gateway: ModelGateway = {
      async *stream(req): AsyncIterable<GatewayEvent> {
        if (req.system.join("\n").includes("extract lasting memories")) {
          yield { type: "text", text: '{"memories":[]}' };
          yield { ...finish(), model: req.model.model };
          return;
        }
        calls++;
        if (calls === 1) {
          yield { type: "text", text: "Half an ans" };
          await new Promise((res) => setTimeout(res, 60));
          throw new ModelCallError("upstream connection reset", { retryable: true, status: 502 });
        }
        yield { type: "text", text: "The whole answer." };
        yield { ...finish(), model: req.model.model };
      },
    };
    const runId = await startRun("Answer me");
    expect((await runAgent(runId, deps(gateway))).status).toBe("completed");
    expect(calls).toBe(2);
    expect(await replies(runId)).toEqual(["The whole answer."]);
    const taken = await tdb.admin<{ payload: { content: unknown[] } }[]>`
      select payload from public.run_events where run_id = ${runId} and type = 'message.completed' order by seq`;
    expect(taken[0]?.payload.content).toEqual([]);
  });

  it("an error that can't be helped by trying again still fails at once", async () => {
    let calls = 0;
    const gateway: ModelGateway = {
      // biome-ignore lint/correctness/useYield: it fails before producing anything
      async *stream(): AsyncIterable<GatewayEvent> {
        calls++;
        throw new ModelCallError("invalid api key", { retryable: false, status: 401 });
      },
    };
    const runId = await startRun("Answer me again");
    expect((await runAgent(runId, deps(gateway))).status).toBe("failed");
    expect(calls).toBe(1);
  });

  it("an action that was in flight when the worker restarted isn't done a second time", async () => {
    const fixtures: FixtureFile[] = [
      {
        name: "restart",
        turns: [
          memories,
          {
            when: { lastRole: "user", lastUserIncludes: "post and look" },
            events: [
              {
                type: "tool_call",
                call: { callId: "p1", name: "probe__post", args: { to: "forum" } },
              },
              {
                type: "tool_call",
                call: { callId: "l1", name: "probe__look", args: { at: "page" } },
              },
              finish(),
            ],
          },
          {
            when: { lastRole: "tool" },
            events: [{ type: "text", text: "Checked." }, finish()],
          },
        ],
      },
    ];
    const gateway = new ReplayGateway(fixtures);
    const runId = await startRun("Post and look");
    probed.length = 0;
    // What the first, interrupted attempt left behind: both calls had started.
    await tdb.admin`insert into public.run_tool_attempts (run_id, call_id) values (${runId}, '0-p1'), (${runId}, '0-l1')`;
    expect((await runAgent(runId, deps(gateway))).status).toBe("completed");
    // Looking is repeated; posting isn't, and the model is told why.
    expect(probed).toEqual(["look page"]);
    const toolResults = lastWithTools(gateway).filter((m) => m.role === "tool");
    expect(toolResults[0]?.content).toContain("restarted while this action was running");
    expect(toolResults[1]?.content).toContain("Saw page");
  });

  it("a long task has its oldest results trimmed before the context overflows", async () => {
    const turns = Array.from({ length: 12 }, (_, n) => ({
      when:
        n === 0
          ? ({ lastRole: "user", lastUserIncludes: "look at everything" } as const)
          : ({ lastRole: "tool", lastToolResultIncludes: `Saw ${7999 + n}.` } as const),
      events: [
        {
          type: "tool_call" as const,
          call: { callId: `k${n}`, name: "probe__look", args: { at: String(8000 + n) } },
        },
        finish(),
      ],
    }));
    const fixtures: FixtureFile[] = [
      {
        name: "long-task",
        turns: [
          memories,
          {
            when: { lastRole: "tool", lastToolResultIncludes: "Saw 8011." },
            events: [{ type: "text", text: "Looked at all of it." }, finish()],
          },
          ...turns,
        ],
      },
    ];
    const gateway = new ReplayGateway(fixtures);
    const runId = await startRun("Look at everything");
    expect(
      (await runAgent(runId, deps(gateway, { limits: { contextWindow: 12_000 } }))).status,
    ).toBe("completed");
    const last = { messages: lastWithTools(gateway) };
    const results = last.messages.filter((m) => m.role === "tool");
    expect(results).toHaveLength(12);
    expect(results[0]?.content).toContain("dropped to save space");
    expect(results.at(-1)?.content).not.toContain("dropped to save space");
    const size = last.messages.reduce((n, m) => n + m.content.length, 0) / 4;
    expect(size).toBeLessThan(12_000);
  });
});

describe("trimTurn", () => {
  const big = (n: number): ChatMessage => ({
    role: "tool",
    callId: `c${n}`,
    name: "probe.look",
    content: `result ${n} ${"y".repeat(8000)}`,
  });
  it("does nothing under the threshold and trims the oldest first above it", () => {
    const turn = [big(1), big(2), big(3), big(4), big(5), big(6)];
    expect(trimTurn([...turn], 0, 100_000)).toBe(0);
    const t = [...turn];
    expect(trimTurn(t, 0, 14_000)).toBeGreaterThan(0);
    expect(t[0]?.content).toContain("dropped to save space");
    expect(t[0]?.content.startsWith("result 1 ")).toBe(true);
    // The newest four are never touched.
    for (const m of t.slice(2)) expect(m.content).not.toContain("dropped to save space");
  });
  it("trims the same way every time, so a replayed run sends the same prompt", () => {
    const a = [big(1), big(2), big(3), big(4), big(5), big(6), big(7)];
    const b = a.map((m) => ({ ...m }));
    trimTurn(a, 500, 14_000);
    trimTurn(b, 500, 14_000);
    expect(a).toEqual(b);
  });
  it("recognises a provider's context-length refusal", () => {
    expect(
      isContextOverflow(new Error("This model's maximum context length is 128000 tokens")),
    ).toBe(true);
    expect(isContextOverflow(new Error("prompt is too long: 250000 tokens > 200000 maximum"))).toBe(
      true,
    );
    expect(isContextOverflow(new Error("rate limit exceeded"))).toBe(false);
  });
});

describe("thinking doesn't count as silence", () => {
  const model: ResolvedModel = { provider: "openrouter", model: "thinker", apiKey: "k" };
  it("a model that thinks past the first-output timeout isn't cut off", async () => {
    let calls = 0;
    const gateway: ModelGateway = {
      async *stream(): AsyncIterable<GatewayEvent> {
        calls++;
        for (let i = 0; i < 6; i++) {
          await new Promise((res) => setTimeout(res, 15));
          yield { type: "progress" };
        }
        yield { type: "text", text: "thought it through" };
      },
    };
    let text = "";
    const seen: string[] = [];
    for await (const ev of withFallback(gateway, [model], {
      firstTokenTimeoutMs: 40,
      idleTimeoutMs: 40,
      sleep: async () => {},
    })({ system: [], messages: [] })) {
      seen.push(ev.type);
      if (ev.type === "text") text += ev.text;
    }
    expect(text).toBe("thought it through");
    expect(calls).toBe(1);
    // Progress is for the timers only; callers never see it.
    expect(seen).toEqual(["text"]);
  });
});
