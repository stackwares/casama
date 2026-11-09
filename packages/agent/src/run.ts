import { randomUUID } from "node:crypto";
import type { Database } from "@kasama/db";
import { checkBudget, RUN_DEFAULTS } from "@kasama/domain";
import type { Logger } from "@kasama/observability";
import type { SandboxHandle } from "@kasama/sandbox";
import { sql } from "drizzle-orm";
import type { ComputerService } from "./computers.ts";
import { buildContext, offloadLargeResult } from "./context.ts";
import type { CredentialResolver, ModelPolicy } from "./credentials.ts";
import type { Embedder } from "./embeddings.ts";
import { DeltaCoalescer, EventBus } from "./events.ts";
import { type FallbackOptions, withFallback } from "./gateway/fallback.ts";
import { capabilitiesOf, costOf } from "./gateway/registry.ts";
import {
  type ChatMessage,
  collect,
  type ModelGateway,
  type ResolvedModel,
  type ToolCall,
  type Usage,
} from "./gateway/types.ts";
import { COMPACTION_SYSTEM, extractMemories, MemoryService } from "./memory.ts";
import { Redactor } from "./redact.ts";
import { ToolError, ToolRegistry } from "./tools/registry.ts";

/** Runs fn as a durable, checkpointed step (DBOS.runStep in the worker; direct call in tests). */
export type StepRunner = <T>(name: string, fn: () => Promise<T>) => Promise<T>;
export const directSteps: StepRunner = (_name, fn) => fn();

export interface RunDeps {
  /** System connection (worker role): not subject to user RLS. */
  db: Database;
  gateway: ModelGateway;
  tools: ToolRegistry;
  credentials: CredentialResolver;
  embedderFor: (orgId: string) => Promise<Embedder | null>;
  /** Computers (Phase 2). Without it, computer tools are not offered. */
  computers?: ComputerService;
  step: StepRunner;
  logger?: Logger;
  limits?: { maxSteps?: number; wallTimeMs?: number };
  fallback?: FallbackOptions;
  deltaIntervalMs?: number;
  cancelPollMs?: number;
}

const TERMINAL = new Set(["completed", "failed", "cancelled"]);

interface RunInfo {
  runId: string;
  orgId: string;
  botId: string;
  conversationId: string | null;
  createdBy: string | null;
  trigger: string;
  status: string;
  perRunLimit: number | null;
  dailyLimit: number | null;
  botName: string;
  persona: string;
  autonomy: "ask_always" | "ask_risky" | "autonomous";
  policy: ModelPolicy;
  timezone: string;
  now: string;
  summary: string;
  current: { id: string; text: string } | null;
  history: ChatMessage[];
  skills: Array<{ name: string; description: string }>;
}

type StepOutcome = { ok: true } | { ok: false; code: string; message: string };

/** Plain text of a message's content parts. */
export function partsText(content: unknown): string {
  if (typeof content === "string") return content;
  if (!Array.isArray(content)) return "";
  return content
    .map((p) =>
      p && typeof p === "object" && (p as { type?: string }).type === "text"
        ? String((p as { text?: unknown }).text ?? "")
        : "",
    )
    .join("");
}

/**
 * agentRun: admit, build context, then alternate model steps and tool steps until the model
 * gives a final answer or a limit is hit; then save the message, extract memories and finish.
 * Every side effect happens inside a step, so a crash resumes at the last finished step.
 */
export async function runAgent(runId: string, deps: RunDeps): Promise<{ status: string }> {
  const { step, db } = deps;
  const limits = { ...RUN_DEFAULTS, ...deps.limits };
  const log = deps.logger;

  const info = await step("load", () => loadRun(db, runId));
  if (!info) return { status: "missing" };
  if (TERMINAL.has(info.status)) return { status: info.status };

  // In-process caches only (never persisted in step outputs): keys and the redactor.
  let redactorCache: Redactor | undefined;
  const redactor = async () => {
    if (!redactorCache) {
      redactorCache = new Redactor();
      for (const choice of policyChoices(info.policy)) {
        const m = await deps.credentials.resolve(info.orgId, choice).catch(() => null);
        redactorCache.add(m?.apiKey, "model_key");
      }
    }
    return redactorCache;
  };
  const bus = async () => new EventBus(db, await redactor());
  const chainFor = async (choices: Array<{ credential_id: string; model: string } | undefined>) => {
    const out: ResolvedModel[] = [];
    for (const c of choices) if (c) out.push(await deps.credentials.resolve(info.orgId, c));
    return out;
  };

  try {
    const admitted = await step("admit", () => admit(db, info, bus));
    if (!admitted.ok) {
      await step("reject", () => finishFailed(db, info, admitted, bus));
      return { status: "failed" };
    }

    const recalled = await step("recall", async () => {
      if (!info.current) return [];
      const memory = new MemoryService(db, await deps.embedderFor(info.orgId));
      return memory.recall(info.botId, info.current.text);
    });

    const primaryModel = info.policy.primary?.model ?? "unknown";
    const caps = capabilitiesOf(primaryModel);
    const available = deps.tools.available({
      computer: !!deps.computers,
      desktop: false,
      vision: caps.vision,
    });
    const toolSpecs = deps.tools.specs(available);

    const contextFor = (summary: string) =>
      buildContext({
        botName: info.botName,
        persona: info.persona,
        autonomy: info.autonomy,
        now: new Date(info.now),
        timezone: info.timezone,
        skills: info.skills,
        memories: recalled.map((m) => ({ kind: m.kind, content: m.content })),
        summary,
        history: info.history,
        current: info.current ? { role: "user", content: info.current.text } : undefined,
        contextWindow: caps.contextWindow,
        computer: !!deps.computers,
      });

    let ctx = contextFor(info.summary);
    if (ctx.toCompact.length > 0) {
      const summary = await step("compact", () =>
        compact(db, deps, info, ctx.toCompact, chainFor, bus).catch((err) => {
          log?.warn("compaction failed", { run_id: runId, error: (err as Error).message });
          return info.summary;
        }),
      );
      ctx = contextFor(summary);
    }

    const turn: ChatMessage[] = [];
    let final: { text: string; messageId: string } | null = null;

    for (let i = 0; ; i++) {
      const check = await step(`check-${i}`, () => checkRun(db, info, i, limits));
      if (check === "cancelled") {
        await step("cancel", () => finishCancelled(db, info, bus));
        return { status: "cancelled" };
      }
      if (check !== "ok") {
        await step("limit", () => finishFailed(db, info, check, bus));
        return { status: "failed" };
      }

      const out = await step(`model-${i}`, () =>
        modelStep(
          deps,
          info,
          i,
          { system: ctx.system, messages: [...ctx.messages, ...turn], tools: toolSpecs },
          chainFor,
          bus,
          redactor,
        ),
      );
      if (out.cancelled) {
        await step("cancel", () => finishCancelled(db, info, bus));
        return { status: "cancelled" };
      }
      if (out.toolCalls.length === 0) {
        final = { text: out.text, messageId: out.messageId };
        break;
      }
      turn.push({ role: "assistant", content: out.text, toolCalls: out.toolCalls });
      for (const call of out.toolCalls) {
        const res = await step(`tool-${i}-${call.callId}`, () =>
          toolStep(deps, info, call, bus, redactor),
        );
        turn.push({ role: "tool", callId: call.callId, name: call.name, content: res.content });
      }
    }

    const finalMessage = final;
    await step("finish", () => saveFinalMessage(db, info, finalMessage, bus));
    await step("memory", () =>
      extractStep(
        deps,
        info,
        finalMessage.text,
        recalled.map((m) => m.content),
        chainFor,
        bus,
      ).catch((err) => {
        log?.warn("memory extraction failed", { run_id: runId, error: (err as Error).message });
        return 0;
      }),
    );
    await step("complete", () => finishCompleted(db, info, finalMessage.messageId, bus));
    return { status: "completed" };
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    log?.error("run failed", { run_id: runId, error: message });
    await step("fail", () =>
      finishFailed(
        db,
        info,
        {
          ok: false,
          code: errorCode(err),
          message: "The run failed. See the run timeline for details.",
        },
        bus,
      ),
    );
    return { status: "failed" };
  }
}

function errorCode(err: unknown) {
  const msg = err instanceof Error ? err.message : "";
  if (msg === "model_credential_not_found") return "model_credential_not_found";
  if (msg === "no model configured") return "no_model_configured";
  const status = (err as { status?: number }).status;
  if (status === 401 || status === 403) return "model_auth_failed";
  if (status === 429) return "model_rate_limited";
  return "run_error";
}

const policyChoices = (p: ModelPolicy) =>
  [p.primary, ...(p.fallbacks ?? []), p.cheap].filter((c): c is NonNullable<typeof c> => !!c);

async function loadRun(db: Database, runId: string): Promise<RunInfo | null> {
  const [row] = await db.execute<{
    id: string;
    org_id: string;
    bot_id: string;
    conversation_id: string | null;
    created_by: string | null;
    trigger: string;
    status: string;
    run_budget: Record<string, unknown>;
    name: string;
    persona_md: string;
    autonomy: RunInfo["autonomy"];
    model_policy: ModelPolicy;
    bot_budget: Record<string, unknown>;
    timezone: string | null;
    summary: string | null;
    summary_through: Date | null;
  }>(sql`
    select r.id, r.org_id, r.bot_id, r.conversation_id, r.created_by, r.trigger, r.status, r.budget as run_budget,
           b.name, b.persona_md, b.autonomy, b.model_policy, b.budget as bot_budget,
           p.timezone, c.summary, c.summary_through
    from public.runs r
    join public.bots b on b.id = r.bot_id
    left join public.profiles p on p.user_id = r.created_by
    left join public.conversations c on c.id = r.conversation_id
    where r.id = ${runId}::uuid`);
  if (!row) return null;

  let current: RunInfo["current"] = null;
  let history: ChatMessage[] = [];
  if (row.conversation_id) {
    const msgs = await db.execute<{
      id: string;
      role: string;
      content: unknown;
      run_id: string | null;
      created_at: Date;
    }>(sql`
      select id, role, content, run_id, created_at from public.messages
      where conversation_id = ${row.conversation_id}::uuid and role in ('user', 'assistant')
        and (${row.summary_through}::timestamptz is null or created_at > ${row.summary_through}::timestamptz)
      order by created_at, id`);
    const idx = msgs.findIndex((m) => m.role === "user" && m.run_id === runId);
    const currentRow = idx >= 0 ? msgs[idx] : undefined;
    if (currentRow) current = { id: currentRow.id, text: partsText(currentRow.content) };
    history = (idx >= 0 ? msgs.slice(0, idx) : msgs)
      .map((m) => ({ role: m.role as "user" | "assistant", content: partsText(m.content) }))
      .filter((m) => m.content.length > 0);
  }
  const skills = await db.execute<{ name: string; description: string }>(sql`
    select distinct on (name) name, description from public.skills
    where org_id = ${row.org_id}::uuid and enabled and (bot_id is null or bot_id = ${row.bot_id}::uuid)
    order by name, bot_id nulls last`);

  const num = (v: unknown) => (v === undefined || v === null || v === "" ? null : Number(v));
  return {
    runId: row.id,
    orgId: row.org_id,
    botId: row.bot_id,
    conversationId: row.conversation_id,
    createdBy: row.created_by,
    trigger: row.trigger,
    status: row.status,
    perRunLimit: num(row.run_budget?.per_run_usd ?? row.bot_budget?.per_run_usd),
    dailyLimit: num(row.bot_budget?.daily_usd),
    botName: row.name,
    persona: row.persona_md,
    autonomy: row.autonomy,
    policy: row.model_policy ?? {},
    timezone: row.timezone ?? "UTC",
    now: new Date().toISOString(),
    summary: row.summary ?? "",
    current,
    history,
    skills: [...skills],
  };
}

async function spend(db: Database, info: RunInfo) {
  const [row] = await db.execute<{
    run_cost: string;
    bot_today: string;
    org_period: string;
    quota: string | null;
  }>(sql`
    select
      (select cost_usd from public.runs where id = ${info.runId}::uuid) as run_cost,
      (select coalesce(sum(cost_usd), 0) from public.usage_ledger
        where bot_id = ${info.botId}::uuid and created_at >= date_trunc('day', now() at time zone 'utc') at time zone 'utc') as bot_today,
      (select coalesce(sum(cost_usd), 0) from public.usage_ledger
        where org_id = ${info.orgId}::uuid and created_at >= date_trunc('month', now() at time zone 'utc') at time zone 'utc') as org_period,
      (select max_cost_usd from public.quotas where org_id = ${info.orgId}::uuid and period = 'month') as quota`);
  return checkBudget({
    runCost: Number(row?.run_cost ?? 0),
    perRunLimit: info.perRunLimit,
    botToday: Number(row?.bot_today ?? 0),
    dailyLimit: info.dailyLimit,
    orgPeriod: Number(row?.org_period ?? 0),
    quotaLimit: row?.quota == null ? null : Number(row.quota),
  });
}

async function admit(
  db: Database,
  info: RunInfo,
  bus: () => Promise<EventBus>,
): Promise<StepOutcome> {
  if (!info.policy.primary)
    return {
      ok: false,
      code: "no_model_configured",
      message: "This bot has no model. Add a model key and pick a model in the bot settings.",
    };
  const verdict = await spend(db, info);
  if (!verdict.ok) return verdict;
  await db.execute(
    sql`update public.runs set status = 'running', started_at = coalesce(started_at, now()) where id = ${info.runId}::uuid`,
  );
  await db.execute(sql`update public.bots set status = 'working' where id = ${info.botId}::uuid`);
  await (await bus()).append(info.runId, "run.started", {
    trigger: info.trigger,
    model: info.policy.primary.model,
    computer_id: null,
  });
  return { ok: true };
}

async function checkRun(
  db: Database,
  info: RunInfo,
  i: number,
  limits: { maxSteps: number; wallTimeMs: number },
) {
  const [run] = await db.execute<{ cancel_requested_at: Date | null; started_at: Date | null }>(
    sql`select cancel_requested_at, started_at from public.runs where id = ${info.runId}::uuid`,
  );
  if (run?.cancel_requested_at) return "cancelled" as const;
  if (i >= limits.maxSteps)
    return {
      ok: false as const,
      code: "max_steps_exceeded",
      message: `The run stopped after ${limits.maxSteps} steps.`,
    };
  if (run?.started_at && Date.now() - new Date(run.started_at).getTime() > limits.wallTimeMs) {
    return {
      ok: false as const,
      code: "wall_time_exceeded",
      message: "The run took longer than its time limit.",
    };
  }
  const verdict = await spend(db, info);
  if (!verdict.ok) return verdict;
  return "ok" as const;
}

/** Records usage in the ledger and on the run, and emits running totals. */
async function recordUsage(
  db: Database,
  info: RunInfo,
  model: string,
  usage: Usage,
  bus: EventBus,
) {
  const caps = capabilitiesOf(model);
  const costIn = (usage.inputTokens * caps.inputPrice) / 1_000_000;
  const costOut = (usage.outputTokens * caps.outputPrice) / 1_000_000;
  await db.execute(sql`
    insert into public.usage_ledger (org_id, bot_id, run_id, kind, quantity, cost_usd, model) values
      (${info.orgId}::uuid, ${info.botId}::uuid, ${info.runId}::uuid, 'tokens_in', ${usage.inputTokens}, ${costIn}, ${model}),
      (${info.orgId}::uuid, ${info.botId}::uuid, ${info.runId}::uuid, 'tokens_out', ${usage.outputTokens}, ${costOut}, ${model})`);
  const [totals] = await db.execute<{
    tokens_in: string;
    tokens_out: string;
    cost_usd: string;
  }>(sql`
    update public.runs set tokens_in = tokens_in + ${usage.inputTokens}, tokens_out = tokens_out + ${usage.outputTokens},
      cost_usd = cost_usd + ${costOf(model, usage)}
    where id = ${info.runId}::uuid returning tokens_in, tokens_out, cost_usd`);
  await bus.append(info.runId, "usage", {
    tokens_in: Number(totals?.tokens_in ?? 0),
    tokens_out: Number(totals?.tokens_out ?? 0),
    cost_usd: Number(totals?.cost_usd ?? 0),
  });
}

async function modelStep(
  deps: RunDeps,
  info: RunInfo,
  i: number,
  req: { system: string[]; messages: ChatMessage[]; tools: ReturnType<ToolRegistry["specs"]> },
  chainFor: (
    c: Array<{ credential_id: string; model: string } | undefined>,
  ) => Promise<ResolvedModel[]>,
  busFn: () => Promise<EventBus>,
  redactorFn: () => Promise<Redactor>,
) {
  const bus = await busFn();
  const redactor = await redactorFn();
  const chain = await chainFor([info.policy.primary, ...(info.policy.fallbacks ?? [])]);
  const messageId = randomUUID();
  const coalescer = new DeltaCoalescer(
    (text) =>
      bus
        .append(info.runId, "message.delta", { message_id: messageId, text })
        .then(() => undefined),
    deps.deltaIntervalMs ?? 200,
  );
  const ctrl = new AbortController();
  let cancelled = false;
  const poll = setInterval(async () => {
    const [r] = await deps.db
      .execute<{ c: Date | null }>(
        sql`select cancel_requested_at as c from public.runs where id = ${info.runId}::uuid`,
      )
      .catch(() => [] as Array<{ c: Date | null }>);
    if (r?.c) {
      cancelled = true;
      ctrl.abort(new Error("cancelled"));
    }
  }, deps.cancelPollMs ?? 500);

  let text = "";
  const toolCalls: ToolCall[] = [];
  let usage: Usage = { inputTokens: 0, outputTokens: 0 };
  let model = chain[0]?.model ?? "unknown";
  try {
    const stream = withFallback(deps.gateway, chain, {
      ...deps.fallback,
      onAttempt: (a) =>
        deps.logger?.info("model attempt", {
          run_id: info.runId,
          step: i,
          model: a.model,
          attempt: a.attempt,
          error: a.error,
        }),
    })({ system: req.system, messages: req.messages, tools: req.tools, abortSignal: ctrl.signal });
    for await (const ev of stream) {
      if (ev.type === "text") {
        text += ev.text;
        coalescer.push(redactor.text(ev.text));
      } else if (ev.type === "tool_call") {
        toolCalls.push({ ...ev.call, name: ToolRegistry.fromWire(ev.call.name) });
      } else {
        usage = ev.usage;
        model = ev.model || model;
      }
    }
  } catch (err) {
    if (!cancelled) {
      await coalescer.drain().catch(() => {});
      throw err;
    }
  } finally {
    clearInterval(poll);
  }
  await coalescer.drain();
  if (cancelled)
    return { cancelled: true as const, text: "", toolCalls: [] as ToolCall[], messageId };
  await recordUsage(deps.db, info, model, usage, bus);
  return { cancelled: false as const, text: redactor.text(text), toolCalls, messageId };
}

async function toolStep(
  deps: RunDeps,
  info: RunInfo,
  call: ToolCall,
  busFn: () => Promise<EventBus>,
  redactorFn: () => Promise<Redactor>,
) {
  const bus = await busFn();
  const redactor = await redactorFn();
  const started = Date.now();
  await bus.append(info.runId, "tool.started", {
    call_id: call.callId,
    tool: call.name,
    args_redacted: redactor.value(call.args),
  });
  try {
    const { def, args } = deps.tools.parse(call.name, call.args);
    const emit = (type: string, payload: Record<string, unknown>) =>
      bus.append(info.runId, type, payload).then(() => undefined);
    // The computer is started or restored on first use and touched on every call.
    let computer: { id: string; handle: SandboxHandle } | undefined;
    const getComputer = async () => {
      if (!deps.computers)
        throw new ToolError("no_computer", "This bot has no computer available.");
      if (!computer) {
        const row = await deps.computers.forBot(info.botId);
        computer = { id: row.id, handle: await deps.computers.ensureRunning(row.id, emit) };
      } else {
        await deps.computers.touch(computer.id);
      }
      return computer;
    };
    const res = await def.execute(args, {
      runId: info.runId,
      botId: info.botId,
      orgId: info.orgId,
      output: (chunk) =>
        bus
          .append(info.runId, "tool.output", { call_id: call.callId, chunk: redactor.text(chunk) })
          .then(() => undefined),
      emit,
      computer: deps.computers ? async () => (await getComputer()).handle : undefined,
      checkpoint: deps.computers
        ? async (label: string) => {
            const c = await getComputer();
            const { checkpointId } = await (deps.computers as ComputerService).checkpoint(
              c.id,
              label,
              info.runId,
              c.handle,
            );
            await emit("checkpoint.created", {
              checkpoint_id: checkpointId,
              label: label.slice(0, 200),
            });
            return { checkpointId, label };
          }
        : undefined,
    });
    if (computer) await deps.computers?.touch(computer.id);
    // Large outputs go to a file in the computer; the model gets a preview and the path.
    const sink = deps.computers
      ? {
          write: async (name: string, text: string) => {
            const path = `/home/kasama/.kasama/outputs/${name}`;
            await (await getComputer()).handle.writeFile(path, new TextEncoder().encode(text));
            return path;
          },
        }
      : undefined;
    const off = await offloadLargeResult(res.content, { name: `${call.callId}.txt`, sink });
    const content = redactor.text(off.content);
    await bus.append(info.runId, "tool.completed", {
      call_id: call.callId,
      result_preview: redactor.text(res.preview ?? content).slice(0, 500),
      artifact_path: res.artifactPath ?? off.artifactPath,
      duration_ms: Date.now() - started,
    });
    return { content };
  } catch (err) {
    const code = err instanceof ToolError ? err.code : "tool_error";
    const message = redactor.text(err instanceof Error ? err.message : String(err));
    await bus.append(info.runId, "tool.failed", {
      call_id: call.callId,
      error_code: code,
      message,
    });
    return { content: `Error (${code}): ${message}` };
  }
}

async function compact(
  db: Database,
  deps: RunDeps,
  info: RunInfo,
  older: ChatMessage[],
  chainFor: (
    c: Array<{ credential_id: string; model: string } | undefined>,
  ) => Promise<ResolvedModel[]>,
  busFn: () => Promise<EventBus>,
) {
  const chain = await chainFor([info.policy.cheap ?? info.policy.primary]);
  const transcript = older
    .filter((m) => m.role !== "tool")
    .map((m) => `${m.role.toUpperCase()}: ${m.content}`)
    .join("\n");
  const r = await collect(
    withFallback(
      deps.gateway,
      chain,
      deps.fallback,
    )({
      system: [COMPACTION_SYSTEM],
      messages: [
        {
          role: "user",
          content: `Previous summary:\n${info.summary || "(none)"}\n\nNew messages:\n${transcript}`,
        },
      ],
      maxOutputTokens: 800,
    }),
  );
  const summary = r.text.trim();
  if (!summary || !info.conversationId) return info.summary;
  // Fold everything before the current message into the summary.
  await db.execute(sql`
    update public.conversations set summary = ${summary},
      summary_through = (select max(created_at) from public.messages
                         where conversation_id = ${info.conversationId}::uuid and (${info.current?.id ?? null}::uuid is null or id <> ${info.current?.id ?? null}::uuid)
                           and created_at <= coalesce((select created_at from public.messages where id = ${info.current?.id ?? null}::uuid), now()))
    where id = ${info.conversationId}::uuid`);
  const memory = new MemoryService(db, await deps.embedderFor(info.orgId));
  const bus = await busFn();
  const { id } = await memory.write({
    orgId: info.orgId,
    botId: info.botId,
    kind: "episode",
    content: summary,
    sourceRunId: info.runId,
  });
  await bus.append(info.runId, "memory.written", { memory_id: id, kind: "episode" });
  await recordUsage(db, info, r.model || chain[0]?.model || "unknown", r.usage, bus);
  return summary;
}

async function saveFinalMessage(
  db: Database,
  info: RunInfo,
  final: { text: string; messageId: string },
  busFn: () => Promise<EventBus>,
) {
  const bus = await busFn();
  const content = [{ type: "text", text: final.text }];
  if (info.conversationId) {
    await db.execute(sql`
      insert into public.messages (id, org_id, conversation_id, role, content, run_id)
      values (${final.messageId}::uuid, ${info.orgId}::uuid, ${info.conversationId}::uuid, 'assistant', ${JSON.stringify(content)}::jsonb, ${info.runId}::uuid)
      on conflict (id) do nothing`);
    const title = info.current?.text.replace(/\s+/g, " ").trim().slice(0, 60) || null;
    await db.execute(sql`
      update public.conversations set last_message_at = now(), title = coalesce(title, ${title})
      where id = ${info.conversationId}::uuid`);
  }
  await bus.append(info.runId, "message.completed", { message_id: final.messageId, content });
}

async function extractStep(
  deps: RunDeps,
  info: RunInfo,
  finalText: string,
  known: string[],
  chainFor: (
    c: Array<{ credential_id: string; model: string } | undefined>,
  ) => Promise<ResolvedModel[]>,
  busFn: () => Promise<EventBus>,
) {
  if (!info.current) return 0;
  const chain = await chainFor([info.policy.cheap ?? info.policy.primary]);
  const cheap = chain[0];
  if (!cheap) return 0;
  const gateway = { stream: withFallback(deps.gateway, chain, deps.fallback) };
  const r = await extractMemories(
    { stream: (req) => gateway.stream(req) },
    cheap,
    [
      { role: "user", content: info.current.text },
      { role: "assistant", content: finalText },
    ],
    known,
  );
  const bus = await busFn();
  const memory = new MemoryService(deps.db, await deps.embedderFor(info.orgId));
  for (const m of r.memories) {
    const { id } = await memory.write({
      orgId: info.orgId,
      botId: info.botId,
      kind: m.kind,
      content: m.content,
      importance: m.importance,
      sourceRunId: info.runId,
    });
    await bus.append(info.runId, "memory.written", { memory_id: id, kind: m.kind });
  }
  await recordUsage(deps.db, info, r.model, r.usage, bus);
  return r.memories.length;
}

async function setTerminal(db: Database, info: RunInfo, status: string, error: unknown) {
  const rows = await db.execute<{ id: string }>(sql`
    update public.runs set status = ${status}, ended_at = now(), error = ${error ? JSON.stringify(error) : null}::jsonb
    where id = ${info.runId}::uuid and status not in ('completed', 'failed', 'cancelled') returning id`);
  await db.execute(sql`
    update public.bots set status = 'idle' where id = ${info.botId}::uuid
      and not exists (select 1 from public.runs where bot_id = ${info.botId}::uuid and status = 'running' and id <> ${info.runId}::uuid)`);
  return rows.length > 0;
}

async function finishCompleted(
  db: Database,
  info: RunInfo,
  finalMessageId: string,
  busFn: () => Promise<EventBus>,
) {
  if (await setTerminal(db, info, "completed", null)) {
    await (await busFn()).append(info.runId, "run.completed", { final_message_id: finalMessageId });
  }
}

async function finishFailed(
  db: Database,
  info: RunInfo,
  outcome: { ok?: false; code: string; message: string },
  busFn: () => Promise<EventBus>,
) {
  if (await setTerminal(db, info, "failed", { code: outcome.code, message: outcome.message })) {
    await (await busFn()).append(info.runId, "run.failed", {
      error_code: outcome.code,
      message: outcome.message,
    });
  }
}

async function finishCancelled(db: Database, info: RunInfo, busFn: () => Promise<EventBus>) {
  const [run] = await db.execute<{ cancelled_by: string | null }>(
    sql`select cancelled_by from public.runs where id = ${info.runId}::uuid`,
  );
  if (await setTerminal(db, info, "cancelled", null)) {
    await (await busFn()).append(info.runId, "run.cancelled", {
      cancelled_by: run?.cancelled_by ?? null,
    });
  }
}
