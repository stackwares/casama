import { randomUUID } from "node:crypto";
import type { Database } from "@kasama/db";
import { APPROVAL_TTL_MS, checkBudget, needsApproval, RUN_DEFAULTS } from "@kasama/domain";
import type { Logger } from "@kasama/observability";
import { collectExec, type SandboxHandle } from "@kasama/sandbox";
import { sql } from "drizzle-orm";
import { z } from "zod";
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
import {
  createAdapter,
  type IntegrationToolInfo,
  integrationToolName,
  loadIntegration,
  refreshIntegration,
  wrapIntegrationOutput,
} from "./integrations.ts";
import { COMPACTION_SYSTEM, extractMemories, MemoryService } from "./memory.ts";
import type { NotificationService } from "./notifications.ts";
import { Redactor } from "./redact.ts";
import { safeFetch } from "./safe-fetch.ts";
import {
  hasPlaceholders,
  loadSecrets,
  type NamedSecret,
  resolvePlaceholders,
  SecretError,
} from "./secrets.ts";
import {
  activeUserLease,
  createTakeover,
  finishTakeover,
  handBackMessage,
  pauseForUser,
  resumeFromUser,
  TAKEOVER_TOOL,
  TAKEOVER_TTL_MS,
  takeoverState,
} from "./takeover.ts";
import { type ToolDefinition, ToolError, ToolRegistry } from "./tools/registry.ts";

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
  /** Push and in-app notifications (approval requests, routine results). */
  notifications?: NotificationService;
  /** Durable wait for an approval decision (DBOS.recv in the worker; polling by default). */
  waitForApproval?: (approvalId: string, runId: string, timeoutMs: number) => Promise<void>;
  /** Guarded fetch for integration calls (private ranges blocked). */
  fetch?: typeof fetch;
  /**
   * Durable wait until `done` returns true or the timeout passes (user control, takeover).
   * The worker checks in a step and sleeps on DBOS.recv; the default polls.
   */
  waitUntil?: (name: string, done: () => Promise<boolean>, timeoutMs: number) => Promise<void>;
}

const pollUntil = async (_name: string, done: () => Promise<boolean>, timeoutMs: number) => {
  const until = Date.now() + timeoutMs;
  while (Date.now() < until && !(await done())) await new Promise((r) => setTimeout(r, 300));
};

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
  current: { id: string; text: string; files?: FilePart[] } | null;
  history: ChatMessage[];
  skills: Array<{ name: string; description: string }>;
  botOwner: string | null;
  parentRunId: string | null;
  /** Subagents: tool allowlist and time limit from the run's budget. */
  allowedTools: string[] | null;
  wallTimeMs: number | null;
  routine: { id: string; notify: boolean; createdBy: string | null; name: string } | null;
  /** A tool call forwarded from a live voice call: run only this call (D-065). */
  voiceCall: { call_id: string; name: string; arguments: Record<string, unknown> } | null;
}

type StepOutcome = { ok: true } | { ok: false; code: string; message: string };

/** Plain text of a message's content parts. */
const IMAGE_TYPES = new Set(["image/png", "image/jpeg", "image/gif", "image/webp"]);
const MAX_IMAGE_BYTES = 5 * 1024 * 1024;

/** Reads up to four attached images from the bot's computer for a vision model. */
async function loadImages(computers: ComputerService, botId: string, files: FilePart[]) {
  const wanted = files
    .filter((f) => IMAGE_TYPES.has(f.mime_type) && f.size <= MAX_IMAGE_BYTES)
    .slice(0, 4);
  if (!wanted.length) return [];
  const row = await computers.forBot(botId);
  const handle = await computers.ensureRunning(row.id);
  const out: Array<{ data: Uint8Array; mediaType: string }> = [];
  for (const f of wanted) {
    const data = await handle.readFile(`~/${f.path}`);
    if (data.length <= MAX_IMAGE_BYTES) out.push({ data, mediaType: f.mime_type });
  }
  return out;
}

export interface FilePart {
  path: string;
  name: string;
  mime_type: string;
  size: number;
}

/** Files attached to a message. */
export function partsFiles(content: unknown): FilePart[] {
  if (!Array.isArray(content)) return [];
  return content.filter(
    (p): p is FilePart & { type: "file" } =>
      !!p &&
      typeof p === "object" &&
      (p as { type?: string }).type === "file" &&
      typeof (p as { path?: unknown }).path === "string",
  );
}

const kb = (n: number) =>
  n >= 1024 * 1024
    ? `${(n / 1024 / 1024).toFixed(1)} MB`
    : `${Math.max(1, Math.round(n / 1024))} KB`;

/** A message's text, with its attachments listed so the model knows where to find them. */
export function partsText(content: unknown): string {
  if (typeof content === "string") return content;
  if (!Array.isArray(content)) return "";
  const text = content
    .map((p) =>
      p && typeof p === "object" && (p as { type?: string }).type === "text"
        ? String((p as { text?: unknown }).text ?? "")
        : "",
    )
    .join("");
  const notes: string[] = [];
  for (const p of content) {
    if (!p || typeof p !== "object") continue;
    const part = p as { type?: string; surface_id?: unknown; name?: unknown; context?: unknown };
    // D-086: interactive UI the bot showed, and what the person did on it.
    if (part.type === "ui")
      notes.push(`(You showed an interactive UI, ${String(part.surface_id)}.)`);
    if (part.type === "ui_action") {
      notes.push(
        `On your UI ${String(part.surface_id)} I chose "${String(part.name)}" with: ${JSON.stringify(part.context ?? {})}`,
      );
    }
  }
  const withNotes = [text, ...notes].filter(Boolean).join("\n\n");
  const files = partsFiles(content);
  if (!files.length) return withNotes;
  const list = files.map((f) => `- ${f.path} (${f.mime_type || "file"}, ${kb(f.size)})`).join("\n");
  return `${withNotes}${withNotes ? "\n\n" : ""}Attached files (on your computer, under the home folder):\n${list}`;
}

/**
 * agentRun: admit, build context, then alternate model steps and tool steps until the model
 * gives a final answer or a limit is hit; then save the message, extract memories and finish.
 * Every side effect happens inside a step, so a crash resumes at the last finished step.
 */
export async function runAgent(runId: string, deps: RunDeps): Promise<{ status: string }> {
  const { step, db } = deps;
  const log = deps.logger;

  const info = await step("load", () => loadRun(db, runId));
  if (!info) return { status: "missing" };
  if (TERMINAL.has(info.status)) return { status: info.status };
  const limits = {
    ...RUN_DEFAULTS,
    ...deps.limits,
    ...(info.wallTimeMs ? { wallTimeMs: info.wallTimeMs } : {}),
  };

  // In-process caches only (never persisted in step outputs): keys, secrets and the redactor.
  let redactorCache: Redactor | undefined;
  let secretsCache: NamedSecret[] | undefined;
  const secrets = async () => {
    secretsCache ??= await loadSecrets(db, info.orgId, info.botId);
    return secretsCache;
  };
  const redactor = async () => {
    if (!redactorCache) {
      const r = new Redactor();
      for (const choice of policyChoices(info.policy)) {
        const m = await deps.credentials.resolve(info.orgId, choice).catch(() => null);
        r.add(m?.apiKey, "model_key");
      }
      // Every secret this bot could use is scrubbed from events, logs and model input.
      for (const sec of await secrets()) r.add(sec.value, sec.name);
      redactorCache = r;
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

    // Integration tools (MCP, OpenAPI, Composio, Pipedream) allowed for this bot.
    const integrationSpecs = await step("integrations", () =>
      loadIntegrationTools(db, info, deps.fetch ?? safeFetch, secrets).catch((err) => {
        log?.warn("integration tools unavailable", {
          run_id: runId,
          error: (err as Error).message,
        });
        return [] as IntegrationToolSpec[];
      }),
    );
    const registry = deps.tools.with(
      integrationDefs(db, integrationSpecs, deps.fetch ?? safeFetch, secrets),
    );

    const primaryModel = info.policy.primary?.model ?? "unknown";
    const caps = capabilitiesOf(primaryModel);
    const allowed = info.allowedTools;
    // Desktop tools only for bots whose computer has a desktop.
    const desktop = deps.computers
      ? await step("computer-profile", async () => {
          const row = await deps.computers?.forBot(info.botId).catch(() => null);
          return row?.profile === "desktop";
        })
      : false;
    const available = registry.available(
      { computer: !!deps.computers, desktop, vision: caps.vision },
      allowed ? (name) => allowed.some((a) => name === a || name.startsWith(`${a}.`)) : undefined,
    );
    const toolSpecs = registry.specs(available);

    // Voice calls: the realtime model chose the tool; run just that call with the same approvals.
    if (info.voiceCall) {
      const vc = info.voiceCall;
      const call: ToolCall = {
        callId: vc.call_id,
        name: ToolRegistry.fromWire(vc.name),
        args: vc.arguments ?? {},
      };
      if (!available.some((d) => d.name === call.name)) {
        await step("voice-unknown", () =>
          finishFailed(
            db,
            info,
            { ok: false, code: "unknown_tool", message: `Unknown tool ${vc.name}` },
            bus,
          ),
        );
        return { status: "failed" };
      }
      const gate = await step("voice-gate", () =>
        approvalGate(deps, registry, info, call, false, bus, redactor),
      );
      let blocked: string | null = null;
      if (gate.approvalId) {
        const wait = deps.waitForApproval ?? ((id, run, ms) => pollApproval(db, id, run, ms));
        await wait(gate.approvalId, info.runId, APPROVAL_TTL_MS);
        const outcome = await step("voice-resolve", () =>
          resolveApproval(db, info, gate.approvalId as string, bus),
        );
        if (outcome === "cancelled") {
          await step("cancel", () => finishCancelled(db, info, bus));
          return { status: "cancelled" };
        }
        if (outcome !== "approved")
          blocked = outcome === "denied" ? "The user denied this action." : "The approval expired.";
      }
      const res = blocked
        ? await step("voice-blocked", () => blockedStep(deps, info, call, blocked as string, bus))
        : await step("voice-tool", () =>
            toolStep(deps, registry, info, call, bus, redactor, secrets),
          );
      await step("voice-finish", async () => {
        await db.execute(sql`update public.runs set voice_call = voice_call || ${JSON.stringify({ result: res.content.slice(0, 20_000) })}::jsonb
          where id = ${info.runId}::uuid`);
        if (await setTerminal(db, info, "completed", null))
          await (await bus()).append(info.runId, "run.completed", { final_message_id: null });
      });
      return { status: "completed" };
    }

    // Images attached to this message go to vision models as images; every model sees the file list.
    const images =
      caps.vision && deps.computers && info.current?.files?.length
        ? await loadImages(deps.computers, info.botId, info.current.files).catch((err) => {
            log?.warn("attachment images not loaded", {
              run_id: runId,
              error: (err as Error).message,
            });
            return [];
          })
        : [];
    const contextFor = (summary: string) =>
      buildContext({
        botName: info.botName,
        persona:
          info.trigger === "subagent" || info.trigger === "delegation"
            ? `${info.persona}\n\nYou are working on a task handed to you by another run. Finish it, then reply with a concise summary of what you did and found.`.trim()
            : info.persona,
        autonomy: info.autonomy,
        now: new Date(info.now),
        timezone: info.timezone,
        skills: info.skills,
        memories: recalled.map((m) => ({ kind: m.kind, content: m.content })),
        summary,
        history: info.history,
        current: info.current
          ? { role: "user", content: info.current.text, ...(images.length ? { images } : {}) }
          : undefined,
        contextWindow: caps.contextWindow,
        computer: !!deps.computers,
        routine: info.routine ? { id: info.routine.id, name: info.routine.name } : undefined,
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
    // Untrusted content read since the last approval (web pages, outside services).
    let untrusted = false;

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
        const gate = await step(`gate-${i}-${call.callId}`, () =>
          approvalGate(deps, registry, info, call, untrusted, bus, redactor),
        );
        let blocked: string | null = null;
        if (gate.approvalId) {
          const wait = deps.waitForApproval ?? ((id, run, ms) => pollApproval(db, id, run, ms));
          await wait(gate.approvalId, info.runId, APPROVAL_TTL_MS);
          const outcome = await step(`resolve-${i}-${call.callId}`, () =>
            resolveApproval(db, info, gate.approvalId as string, bus),
          );
          if (outcome === "cancelled") {
            await step("cancel", () => finishCancelled(db, info, bus));
            return { status: "cancelled" };
          }
          if (outcome === "approved") untrusted = false;
          else {
            blocked =
              outcome === "denied"
                ? "The user denied this action. Do not retry it; continue without it or ask the user what to do instead."
                : "The approval request expired without a decision. Continue without this action.";
          }
        }
        const waitUntil = deps.waitUntil ?? pollUntil;
        // A bot asking a person to take over the screen waits here, durably.
        if (!blocked && call.name === TAKEOVER_TOOL && deps.computers) {
          const started = await step(`takeover-${i}-${call.callId}`, () =>
            startTakeoverStep(deps, info, call, bus),
          );
          if ("error" in started) {
            const res = await step(`blocked-${i}-${call.callId}`, () =>
              blockedStep(deps, info, call, started.error, bus),
            );
            turn.push({ role: "tool", callId: call.callId, name: call.name, content: res.content });
            continue;
          }
          let state = "pending";
          await waitUntil(
            `takeover-${call.callId}`,
            async () => {
              state = await takeoverState(db, started.id);
              return !["pending", "taken"].includes(state);
            },
            TAKEOVER_TTL_MS,
          );
          if (state === "cancelled") {
            await step("cancel", () => finishCancelled(db, info, bus));
            return { status: "cancelled" };
          }
          const content = await step(`takeover-done-${i}-${call.callId}`, async () => {
            const text = await finishTakeover(db, info.runId, started.id, bus);
            await completeToolEvent(deps, info, call, text, bus);
            return text;
          });
          turn.push({ role: "tool", callId: call.callId, name: call.name, content });
          continue;
        }
        // While a person controls the screen, screen tools (and shell, unless allowed) wait.
        let handBack: string | null = null;
        const def = registry.get(call.name);
        if (!blocked && deps.computers && def?.requires?.computer) {
          const hold = await step(`lease-${i}-${call.callId}`, async () => {
            const row = await deps.computers?.forBot(info.botId).catch(() => null);
            if (!row) return null;
            const lease = await activeUserLease(db, row.id);
            if (!lease || (!def.screen && lease.allowShell)) return null;
            await pauseForUser(db, info.runId, row.id, bus);
            return row.id;
          });
          if (hold) {
            await waitUntil(
              `lease-${call.callId}`,
              async () => {
                const lease = await activeUserLease(db, hold);
                const [r] = await db.execute<{ cancel: Date | null }>(
                  sql`select cancel_requested_at as cancel from public.runs where id = ${info.runId}::uuid`,
                );
                return !lease || !!r?.cancel || (!def.screen && lease.allowShell);
              },
              24 * 3600 * 1000,
            );
            const note = await step(`lease-resume-${i}-${call.callId}`, () =>
              resumeFromUser(db, info.runId, hold, bus),
            );
            handBack = handBackMessage(note);
          }
        }
        const res = blocked
          ? await step(`blocked-${i}-${call.callId}`, () =>
              blockedStep(deps, info, call, blocked as string, bus),
            )
          : await step(`tool-${i}-${call.callId}`, () =>
              toolStep(deps, registry, info, call, bus, redactor, secrets),
            );
        if (res.untrusted) untrusted = true;
        turn.push({
          role: "tool",
          callId: call.callId,
          name: call.name,
          content: handBack ? `${handBack}\n\n${res.content}` : res.content,
        });
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
    if (info.routine?.notify && deps.notifications) {
      const notifications = deps.notifications;
      const routine = info.routine;
      await step("notify", async () => {
        const to = routine.createdBy ?? info.botOwner;
        if (!to) return;
        await notifications
          .notify(to, info.orgId, "routine_result", {
            title: `${info.botName}: ${routine.name}`,
            body: finalMessage.text.replace(/\s+/g, " ").slice(0, 240),
            link: `/bots/${info.botId}/chat${info.conversationId ? `?c=${info.conversationId}` : ""}`,
            bot_id: info.botId,
            run_id: info.runId,
          })
          .catch((err) =>
            log?.warn("routine notification failed", {
              run_id: runId,
              error: (err as Error).message,
            }),
          );
      });
    }
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
    bot_owner: string | null;
    parent_run_id: string | null;
    routine_id: string | null;
    routine_notify: boolean | null;
    routine_created_by: string | null;
    routine_name: string | null;
    voice_call: RunInfo["voiceCall"];
  }>(sql`
    select r.id, r.org_id, r.bot_id, r.conversation_id, r.created_by, r.trigger, r.status, r.budget as run_budget,
           b.name, b.persona_md, b.autonomy, b.model_policy, b.budget as bot_budget, b.created_by as bot_owner,
           coalesce(p.timezone, po.timezone) as timezone, c.summary, c.summary_through, r.parent_run_id,
           r.routine_id, rt.notify as routine_notify, rt.created_by as routine_created_by, rt.name as routine_name, r.voice_call
    from public.runs r
    join public.bots b on b.id = r.bot_id
    left join public.profiles p on p.user_id = r.created_by
    left join public.profiles po on po.user_id = b.created_by
    left join public.conversations c on c.id = r.conversation_id
    left join public.routines rt on rt.id = r.routine_id
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
    if (currentRow)
      current = {
        id: currentRow.id,
        text: partsText(currentRow.content),
        files: partsFiles(currentRow.content),
      };
    history = (idx >= 0 ? msgs.slice(0, idx) : msgs)
      .map((m) => ({ role: m.role as "user" | "assistant", content: partsText(m.content) }))
      .filter((m) => m.content.length > 0);
  }
  // Subagent runs carry their task in the run's budget instead of a conversation message.
  const task = typeof row.run_budget?.task === "string" ? (row.run_budget.task as string) : null;
  if (!current && task) current = { id: `task-${row.id}`, text: task };
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
    botOwner: row.bot_owner,
    parentRunId: row.parent_run_id,
    allowedTools: Array.isArray(row.run_budget?.tools) ? (row.run_budget.tools as string[]) : null,
    wallTimeMs:
      typeof row.run_budget?.timeout_s === "number"
        ? (row.run_budget.timeout_s as number) * 1000
        : null,
    routine: row.routine_id
      ? {
          id: row.routine_id,
          notify: row.routine_notify ?? false,
          createdBy: row.routine_created_by,
          name: row.routine_name ?? "",
        }
      : null,
    voiceCall: row.voice_call ?? null,
  };
}

async function spend(db: Database, info: RunInfo) {
  const [row] = await db.execute<{
    run_cost: string;
    bot_today: string;
    org_period: string;
    quota: string | null;
    limits: Record<string, unknown> | null;
    credits: string | null;
    computer_seconds: string;
  }>(sql`
    select
      (select cost_usd from public.runs where id = ${info.runId}::uuid) as run_cost,
      (select coalesce(sum(cost_usd), 0) from public.usage_ledger
        where bot_id = ${info.botId}::uuid and created_at >= date_trunc('day', now() at time zone 'utc') at time zone 'utc') as bot_today,
      (select coalesce(sum(cost_usd), 0) from public.usage_ledger
        where org_id = ${info.orgId}::uuid and created_at >= date_trunc('month', now() at time zone 'utc') at time zone 'utc') as org_period,
      (select max_cost_usd from public.quotas where org_id = ${info.orgId}::uuid and period = 'month') as quota,
      (select limits from public.entitlements where org_id = ${info.orgId}::uuid order by created_at desc limit 1) as limits,
      (select balance_after from public.credit_ledger where org_id = ${info.orgId}::uuid order by seq desc limit 1) as credits,
      (select coalesce(sum(quantity), 0) from public.usage_ledger
        where org_id = ${info.orgId}::uuid and kind = 'computer_seconds'
          and created_at >= date_trunc('month', now() at time zone 'utc') at time zone 'utc') as computer_seconds`);
  // Entitlements are the only billing input (D-070): a monthly cost cap, credits, computer hours.
  const limits = row?.limits ?? {};
  const num = (v: unknown) => (typeof v === "number" ? v : null);
  const caps = [row?.quota == null ? null : Number(row.quota), num(limits.monthly_usd)].filter(
    (v): v is number => v != null,
  );
  return checkBudget({
    runCost: Number(row?.run_cost ?? 0),
    perRunLimit: info.perRunLimit,
    botToday: Number(row?.bot_today ?? 0),
    dailyLimit: info.dailyLimit,
    orgPeriod: Number(row?.org_period ?? 0),
    quotaLimit: caps.length ? Math.min(...caps) : null,
    credits: limits.credit_gate === true ? Number(row?.credits ?? 0) : null,
    computerSeconds: Number(row?.computer_seconds ?? 0),
    computerHours: num(limits.computer_hours),
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
    let first = true;
    for await (const ev of stream) {
      // Time to first token (text or tool call), for dashboards and the load test.
      if (first && (ev.type === "text" || ev.type === "tool_call")) {
        first = false;
        void deps.db
          .execute(
            sql`update public.runs set first_token_at = coalesce(first_token_at, now()) where id = ${info.runId}::uuid`,
          )
          .catch(() => {});
      }
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
  registry: ToolRegistry,
  info: RunInfo,
  call: ToolCall,
  busFn: () => Promise<EventBus>,
  redactorFn: () => Promise<Redactor>,
  secretsFn: () => Promise<NamedSecret[]>,
): Promise<{ content: string; untrusted: boolean }> {
  const bus = await busFn();
  const redactor = await redactorFn();
  const started = Date.now();
  let untrusted = false;
  try {
    const parsed = registry.parse(call.name, call.args);
    const def = parsed.def;
    let args = parsed.args as Record<string, unknown>;
    untrusted = def.untrustedOutput === true;
    const emit = (type: string, payload: Record<string, unknown>) =>
      bus.append(info.runId, type, payload).then(() => undefined);
    // The computer is started or restored on first use and touched on every call.
    let computer: { id: string; handle: SandboxHandle } | undefined;
    const getComputer = async () => {
      if (!deps.computers)
        throw new ToolError("no_computer", "This bot has no computer available.");
      if (!computer) {
        const row = await deps.computers.forBot(info.botId);
        const h = await deps.computers.ensureRunning(row.id, emit);
        // Tell a personal computer which bot is acting, so its overlay can show it (D-066).
        const activity = {
          run_id: info.runId,
          bot: info.botName,
          tool: call.name,
          summary: describeCall(
            call.name,
            redactor.value(call.args) as Record<string, unknown>,
          ).slice(0, 200),
        };
        computer = { id: row.id, handle: h.withActivity?.(activity) ?? h };
      } else {
        await deps.computers.touch(computer.id);
      }
      return computer;
    };
    const toolCtx = {
      runId: info.runId,
      botId: info.botId,
      orgId: info.orgId,
      output: (chunk: string) =>
        bus
          .append(info.runId, "tool.output", { call_id: call.callId, chunk: redactor.text(chunk) })
          .then(() => undefined),
      emit,
      computer: deps.computers ? async () => (await getComputer()).handle : undefined,
    };
    // {{secret:NAME}} placeholders are filled in only now, only for tools that accept them,
    // and only when the destination host is in the secret's allowlist.
    if (hasPlaceholders(args)) {
      if (!def.acceptsSecrets)
        throw new ToolError(
          "secrets_not_accepted",
          `${def.name} does not accept {{secret:...}} placeholders.`,
        );
      const host = (await def.destinationHost?.(args as never, toolCtx)) ?? null;
      try {
        args = resolvePlaceholders(args, await secretsFn(), host);
      } catch (err) {
        if (err instanceof SecretError) throw new ToolError(err.code, err.message);
        throw err;
      }
    }
    const res = await def.execute(args as never, {
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
    return { content, untrusted };
  } catch (err) {
    const code = err instanceof ToolError ? err.code : "tool_error";
    const message = redactor.text(err instanceof Error ? err.message : String(err));
    await bus.append(info.runId, "tool.failed", {
      call_id: call.callId,
      error_code: code,
      message,
    });
    return { content: `Error (${code}): ${message}`, untrusted };
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
  // Interactive UIs shown during the run stay with the reply, so they are there after a reload.
  const shown = await db.execute<{ payload: { surface_id: string; messages: unknown[] } }>(sql`
    select payload from public.run_events
    where run_id = ${info.runId}::uuid and type = 'ui.shown' order by seq`);
  const ui = [...shown].map((r) => ({
    type: "ui",
    surface_id: r.payload.surface_id,
    messages: r.payload.messages,
  }));
  const content: Array<Record<string, unknown>> = [{ type: "text", text: final.text }, ...ui];
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
  await db.execute(
    sql`update public.approvals set status = 'expired' where run_id = ${info.runId}::uuid and status = 'pending'`,
  );
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

// ---------------------------------------------------------------------------
// Approvals
// ---------------------------------------------------------------------------

/** One-line, human-readable summary of a tool call for approval cards and push notifications. */
function describeCall(tool: string, args: Record<string, unknown>) {
  const key = ["command", "url", "query", "prompt", "title", "task", "path", "content"].find(
    (k) => typeof args[k] === "string",
  );
  const detail = key ? String(args[key]).replace(/\s+/g, " ").slice(0, 160) : "";
  return detail ? `${tool}: ${detail}` : tool;
}

/**
 * Records tool.started, applies the approval policy and, when needed, creates the approval
 * request, pauses the run and notifies the bot's owner. Idempotent per call.
 */
async function approvalGate(
  deps: RunDeps,
  registry: ToolRegistry,
  info: RunInfo,
  call: ToolCall,
  untrusted: boolean,
  busFn: () => Promise<EventBus>,
  redactorFn: () => Promise<Redactor>,
): Promise<{ approvalId: string | null }> {
  const bus = await busFn();
  const redactor = await redactorFn();
  const argsRedacted = redactor.value(call.args);
  await bus.append(info.runId, "tool.started", {
    call_id: call.callId,
    tool: call.name,
    args_redacted: argsRedacted,
  });
  let def: ToolDefinition;
  let args: Record<string, unknown>;
  try {
    const parsed = registry.parse(call.name, call.args);
    def = parsed.def;
    args = parsed.args as Record<string, unknown>;
  } catch {
    return { approvalId: null }; // the tool step reports the error
  }
  const risk = def.riskFor?.(args as never) ?? def.risk;
  const [grant] = await deps.db.execute<{ id: string }>(
    sql`select id from public.tool_grants where bot_id = ${info.botId}::uuid and tool_name = ${call.name}`,
  );
  // On the user's own machine (desktop companion), high-risk actions always ask (D-066).
  const onLocal =
    risk === "high" && def.requires?.computer && deps.computers
      ? await deps.computers
          .forBot(info.botId)
          .then((c) => c.kind === "local")
          .catch(() => false)
      : false;
  const needed = needsApproval({
    autonomy: info.autonomy,
    risk,
    readOnly: def.readOnly === true,
    confirmUnderDefault: def.confirm === true,
    untrustedSinceApproval: untrusted,
    granted: !!grant,
    forceHighRisk: onLocal,
  });
  if (!needed) return { approvalId: null };

  const summary = `${info.botName} wants to run ${describeCall(call.name, argsRedacted as Record<string, unknown>)}`;
  const expires = new Date(Date.now() + APPROVAL_TTL_MS).toISOString();
  const inserted = await deps.db.execute<{ id: string; expires_at: Date }>(sql`
    insert into public.approvals (org_id, bot_id, run_id, call_id, tool_name, args_redacted, summary, risk, expires_at)
    values (${info.orgId}::uuid, ${info.botId}::uuid, ${info.runId}::uuid, ${call.callId}, ${call.name},
            ${JSON.stringify(argsRedacted)}::jsonb, ${summary.slice(0, 500)}, ${risk}, ${expires}::timestamptz)
    on conflict (run_id, call_id) do update set summary = excluded.summary
    returning id, expires_at`);
  const approval = inserted[0];
  if (!approval) throw new Error("approval insert returned nothing");
  await deps.db.execute(
    sql`update public.runs set status = 'waiting_approval' where id = ${info.runId}::uuid and status = 'running'`,
  );
  await deps.db.execute(
    sql`update public.bots set status = 'waiting' where id = ${info.botId}::uuid`,
  );
  await bus.append(info.runId, "approval.requested", {
    approval_id: approval.id,
    tool: call.name,
    args_redacted: argsRedacted,
    risk,
    expires_at: new Date(approval.expires_at).toISOString(),
  });
  const recipients = new Set([info.createdBy, info.botOwner].filter((u): u is string => !!u));
  for (const user of recipients) {
    await deps.notifications
      ?.notify(user, info.orgId, "approval_request", {
        title: `${info.botName} needs your approval`,
        body: summary.slice(0, 240),
        link: `/approvals/${approval.id}`,
        approval_id: approval.id,
        bot_id: info.botId,
        run_id: info.runId,
      })
      .catch((err) =>
        deps.logger?.warn("approval notification failed", { error: (err as Error).message }),
      );
  }
  return { approvalId: approval.id };
}

/** Default wait: polls until the approval is decided, the run is cancelled, or the timeout passes. */
async function pollApproval(db: Database, approvalId: string, _runId: string, timeoutMs: number) {
  const until = Date.now() + timeoutMs;
  while (Date.now() < until) {
    const [row] = await db.execute<{ status: string; cancel: Date | null }>(sql`
      select a.status, r.cancel_requested_at as cancel from public.approvals a join public.runs r on r.id = a.run_id
      where a.id = ${approvalId}::uuid`);
    if (row?.status !== "pending" || row.cancel) return;
    await new Promise((r) => setTimeout(r, 250));
  }
}

/** Reads the decision (expiring it if still pending), resumes the run and emits approval.resolved. */
async function resolveApproval(
  db: Database,
  info: RunInfo,
  approvalId: string,
  busFn: () => Promise<EventBus>,
) {
  const [run] = await db.execute<{ cancel: Date | null }>(
    sql`select cancel_requested_at as cancel from public.runs where id = ${info.runId}::uuid`,
  );
  const [row] = await db.execute<{ status: string; decided_by: string | null }>(sql`
    update public.approvals set status = case when status = 'pending' then 'expired' else status end
    where id = ${approvalId}::uuid returning status, decided_by`);
  const status = (row?.status ?? "expired") as "approved" | "denied" | "expired";
  if (!run?.cancel) {
    await db.execute(
      sql`update public.runs set status = 'running' where id = ${info.runId}::uuid and status = 'waiting_approval'`,
    );
    await db.execute(sql`update public.bots set status = 'working' where id = ${info.botId}::uuid`);
  }
  await (await busFn()).append(info.runId, "approval.resolved", {
    approval_id: approvalId,
    decision: status,
    decided_by: row?.decided_by ?? null,
  });
  return run?.cancel ? ("cancelled" as const) : status;
}

/** A denied or expired step: the model is told, the run continues. */
async function blockedStep(
  _deps: RunDeps,
  info: RunInfo,
  call: ToolCall,
  message: string,
  busFn: () => Promise<EventBus>,
) {
  await (await busFn()).append(info.runId, "tool.failed", {
    call_id: call.callId,
    error_code: "approval_denied",
    message,
  });
  return { content: message, untrusted: false };
}

/** Creates a takeover request for the bot's desktop computer (the wait happens in the run loop). */
async function startTakeoverStep(
  deps: RunDeps,
  info: RunInfo,
  call: ToolCall,
  busFn: () => Promise<EventBus>,
): Promise<{ id: string } | { error: string }> {
  const reason = String((call.args as { reason?: unknown }).reason ?? "")
    .slice(0, 1000)
    .trim();
  if (!reason) return { error: "Give a reason so the person knows what to do." };
  const computers = deps.computers;
  const row = await computers?.forBot(info.botId).catch(() => null);
  if (!computers || !row) return { error: "Takeover needs a computer." };
  // The page the bot is on, so the person lands where they are needed.
  const url = await currentBrowserUrl(computers, row.id);
  if (row.profile !== "desktop") {
    // A person needs a screen: switch this computer to the desktop profile (files are kept).
    await deps.db.execute(
      sql`update public.computers set profile = 'desktop' where id = ${row.id}::uuid`,
    );
    await computers.stop(row.id).catch(() => {});
  }
  const handle = await computers.ensureRunning(row.id);
  if (url) {
    // Reopen it in a visible window (desktop computers run the browser headed).
    const quoted = `'${url.replace(/'/g, "'\\''")}'`;
    await collectExec(
      handle.exec(`agent-browser close >/dev/null 2>&1; agent-browser open ${quoted}`, {
        timeoutMs: 60_000,
      }),
    ).catch(() => {});
  }
  const id = await createTakeover(deps.db, info, row.id, reason, busFn, deps.notifications);
  return { id };
}

/** The browser's current page, if the computer is running and the browser has one open. */
async function currentBrowserUrl(
  computers: ComputerService,
  computerId: string,
): Promise<string | null> {
  const row = await computers.byId(computerId).catch(() => null);
  if (!row || !["running", "idle"].includes(row.state)) return null;
  try {
    const handle = await computers.ensureRunning(computerId);
    const r = await collectExec(handle.exec("agent-browser get url", { timeoutMs: 15_000 }));
    const url = r.stdout
      .trim()
      .split(/\s+/)
      .find((t) => /^https?:\/\//.test(t));
    return url ?? null;
  } catch {
    return null;
  }
}

/** Records a tool call that finished outside toolStep (takeover). */
async function completeToolEvent(
  _deps: RunDeps,
  info: RunInfo,
  call: ToolCall,
  text: string,
  busFn: () => Promise<EventBus>,
) {
  await (await busFn()).append(info.runId, "tool.completed", {
    call_id: call.callId,
    result_preview: text.slice(0, 200),
    artifact_path: null,
    duration_ms: 0,
  });
}

// ---------------------------------------------------------------------------
// Integration tools
// ---------------------------------------------------------------------------

export interface IntegrationToolSpec {
  integrationId: string;
  kind: string;
  integration: string;
  tool: string;
  fullName: string;
  description: string;
  inputSchema: Record<string, unknown>;
  risk: "low" | "medium" | "high";
}

const INTEGRATION_CACHE_MS = 24 * 60 * 60 * 1000;

/** The integration tools a bot may use (refreshing caches older than 24 hours). Serializable. */
async function loadIntegrationTools(
  db: Database,
  info: RunInfo,
  fetchImpl: typeof fetch,
  secretsFn: () => Promise<NamedSecret[]>,
): Promise<IntegrationToolSpec[]> {
  const rows = await db.execute<{
    id: string;
    kind: string;
    name: string;
    tools_cache: IntegrationToolInfo[];
    tools_cached_at: Date | null;
    risk_overrides: Record<string, "low" | "medium" | "high">;
    tool_allowlist: string[] | null;
  }>(sql`
    select i.id, i.kind, i.name, i.tools_cache, i.tools_cached_at, i.risk_overrides, bi.tool_allowlist
    from public.bot_integrations bi join public.integrations i on i.id = bi.integration_id
    where bi.bot_id = ${info.botId}::uuid and i.status <> 'error'`);
  const out: IntegrationToolSpec[] = [];
  for (const row of rows) {
    let tools = row.tools_cache ?? [];
    if (
      !row.tools_cached_at ||
      Date.now() - new Date(row.tools_cached_at).getTime() > INTEGRATION_CACHE_MS
    ) {
      const r = await refreshIntegration(db, row.id, {
        fetch: fetchImpl,
        secrets: await secretsFn(),
      });
      if (r.ok) tools = r.tools;
    }
    for (const t of tools) {
      if (row.tool_allowlist && !row.tool_allowlist.includes(t.name)) continue;
      out.push({
        integrationId: row.id,
        kind: row.kind,
        integration: row.name,
        tool: t.name,
        fullName: integrationToolName({ kind: row.kind as "mcp", name: row.name }, t.name),
        description: t.description.slice(0, 1000),
        inputSchema: t.inputSchema ?? { type: "object" },
        risk: row.risk_overrides?.[t.name] ?? t.risk ?? "medium",
      });
    }
  }
  return out;
}

/** Tool definitions that call integrations; output is untrusted. */
function integrationDefs(
  db: Database,
  specs: IntegrationToolSpec[],
  fetchImpl: typeof fetch,
  secretsFn: () => Promise<NamedSecret[]>,
): ToolDefinition[] {
  return specs.map((spec) => ({
    name: spec.fullName,
    description: `[${spec.kind}:${spec.integration}] ${spec.description}`,
    risk: spec.risk,
    untrustedOutput: true,
    jsonSchema: { type: "object", ...spec.inputSchema },
    schema: z.record(z.string(), z.unknown()),
    async execute(args: Record<string, unknown>) {
      const rec = await loadIntegration(db, spec.integrationId);
      if (!rec) throw new ToolError("integration_not_found", "This integration was removed.");
      const adapter = createAdapter(rec, { fetch: fetchImpl, secrets: await secretsFn() });
      try {
        const text = await adapter.callTool(spec.tool, args);
        return {
          content: wrapIntegrationOutput(rec, text),
          preview: text.replace(/\s+/g, " ").slice(0, 200),
        };
      } finally {
        await adapter.close?.();
      }
    },
  }));
}
