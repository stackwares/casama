/**
 * decide(): one question set to a decision model, with today's behaviour as the answer whenever
 * there is no confident one (docs/DECISION-MODEL-PLAN.md, D-454).
 *
 * - `off`: nothing is called; every answer is `none`.
 * - `shadow`: every shadow model is asked side by side and logged in decision_log. The caller gets
 *   `none` back and does exactly what it does today. Nobody is charged.
 * - `on`: the chosen model is asked and its answers returned; the caller acts only on confident
 *   ones. Charged like other background calls on Casama Cloud.
 *
 * The log holds question names and probabilities, never the text that was judged.
 */

import type { Database } from "@casama/db";
import {
  cloudOpenRouterCharge,
  cloudOpenRouterCost,
  type DecisionMode,
  type DecisionSettings,
  type DecisionUse,
  type DecisionUseSettings,
  decisionModeOf,
  decisionSettings,
  shadowModelsOf,
} from "@casama/domain";
import { sql } from "drizzle-orm";
import type {
  DecisionAnswer,
  DecisionBackend,
  DecisionQuestion,
  DecisionResult,
} from "./gateway/decisions.ts";

/** Above about 32 KB Jev switches to a slower, less accurate mode; every use stays under it. */
export const DECISION_STATE_BYTES = 24_000;

export interface DecisionDeps {
  /** Live settings (instance_settings "decisions", short cache). */
  settings: () => Promise<DecisionSettings>;
  /** Null when the server has no OpenRouter key for decisions: every use is off. */
  backend: DecisionBackend | null;
  /** Casama Cloud: calls of a use that is on are charged to the workspace like background calls. */
  billable: boolean;
  logger?: { warn: (msg: string, fields?: Record<string, unknown>) => void };
}

export interface DecideInput<U extends DecisionUse> {
  use: U;
  orgId: string;
  botId: string | null;
  runId: string | null;
  /** What it was about, when not the run itself (a suggestion, a watcher). */
  subjectId?: string | null;
  state: string;
  questions: Record<string, DecisionQuestion>;
  /**
   * Shadow only: wait for the shadow calls (default). False sends them off the main path, for uses
   * where half a second would be felt (the tool-call gate, the effort picker).
   */
  wait?: boolean;
}

export interface Decision<U extends DecisionUse> {
  mode: DecisionMode;
  /** The acting model's answers when `on`; every answer `none` otherwise. */
  answers: Record<string, DecisionAnswer>;
  /** The use's thresholds (defaults when settings can't be read). */
  t: DecisionUseSettings<U>;
  /** The acting row's id when `on`, for markDecision(). */
  logId: string | null;
}

/**
 * Shadow calls sent off the main path, by run and use, until their rows are written. Kept here and
 * not on the Decision: a durable step's result is serialized, so a promise in it comes back as a
 * plain object (that failed every chat run with a tool step on 2026-11-20).
 */
const inFlight = new Map<string, Promise<void>>();

/** Resolves when this run's shadow rows for `use` are written; at once when none are pending. */
export function shadowSettled(runId: string | null, use: DecisionUse): Promise<void> {
  return (runId && inFlight.get(`${runId}:${use}`)) || Promise.resolve();
}

const none = (questions: Record<string, DecisionQuestion>) =>
  Object.fromEntries(Object.keys(questions).map((k) => [k, { type: "none" } as DecisionAnswer]));

/** Cuts text to at most `max` UTF-8 bytes without splitting a character. */
export function cutBytes(text: string, max = DECISION_STATE_BYTES): string {
  const bytes = Buffer.from(text, "utf8");
  if (bytes.length <= max) return text;
  // A cut mid-character decodes to U+FFFD at the end; drop it.
  return bytes
    .subarray(0, max)
    .toString("utf8")
    .replace(/\uFFFD+$/, "");
}

/** The chance of yes, or null when there was no answer. */
export function yes(answers: Record<string, DecisionAnswer>, name: string): number | null {
  const a = answers[name];
  return a?.type === "yesno" ? a.p : null;
}

/** For the log: name -> probability, or {choice, p} for a choice, or score. No text. */
function logAnswers(answers: Record<string, DecisionAnswer>) {
  const out: Record<string, unknown> = {};
  for (const [k, a] of Object.entries(answers)) {
    if (a.type === "yesno") out[k] = Math.round(a.p * 10_000) / 10_000;
    else if (a.type === "choice") out[k] = { choice: a.choice, p: a.p };
    else if (a.type === "score") out[k] = { score: a.score };
  }
  return out;
}

async function record(
  db: Database,
  deps: DecisionDeps,
  input: DecideInput<DecisionUse>,
  model: string,
  shadow: boolean,
  r: DecisionResult,
): Promise<string | null> {
  const [row] = await db.execute<{ id: string }>(sql`
    insert into public.decision_log
      (org_id, bot_id, run_id, subject_id, use, model, shadow, answers, error, input_tokens, cost_usd, latency_ms)
    values (${input.orgId}::uuid, ${input.botId}::uuid, ${input.runId}::uuid, ${input.subjectId ?? null}::uuid,
      ${input.use}, ${model}, ${shadow}, ${JSON.stringify(logAnswers(r.answers))}::jsonb,
      ${r.error ?? null}, ${r.inputTokens}, ${r.costUsd}, ${Math.round(r.latencyMs)})
    returning id`);
  if (r.costUsd > 0 || r.inputTokens > 0) {
    // Shadow calls are Casama's: at no cost to the workspace (not billable, cost 0 so no budget
    // moves), with what Casama paid kept as the upstream cost. A use that is on is charged like
    // the bot's other background calls.
    const billable = !shadow && deps.billable;
    const cost = shadow ? 0 : billable ? cloudOpenRouterCharge(r.costUsd) : r.costUsd;
    const upstream = deps.billable || shadow ? cloudOpenRouterCost(r.costUsd) : null;
    const meta = JSON.stringify({
      purpose: `decide:${input.use}`,
      provider_cost_usd: r.costUsd,
      ...(shadow ? { shadow: true } : {}),
      ...(deps.billable ? { key: "server" } : {}),
    });
    await db.execute(sql`
      insert into public.usage_ledger (org_id, bot_id, run_id, kind, quantity, cost_usd, upstream_cost_usd, model, source, billable, meta)
      values (${input.orgId}::uuid, ${input.botId}::uuid, ${input.runId}::uuid, 'tokens_in', ${r.inputTokens},
        ${cost}, ${upstream}, ${model}, 'key', ${billable}, ${meta}::jsonb)`);
    if (!shadow && input.runId && cost > 0)
      await db.execute(sql`
        update public.runs set tokens_in = tokens_in + ${r.inputTokens}, cost_usd = cost_usd + ${cost}
        where id = ${input.runId}::uuid`);
  }
  return row?.id ?? null;
}

/** Asks the decision model for `use`, as its settings say. Never throws. */
export async function decide<U extends DecisionUse>(
  db: Database,
  deps: DecisionDeps | undefined,
  input: DecideInput<U>,
): Promise<Decision<U>> {
  let settings: DecisionSettings;
  try {
    settings = deps ? await deps.settings() : decisionSettings(null);
  } catch {
    settings = decisionSettings(null);
  }
  const t = settings.uses[input.use] as DecisionUseSettings<U>;
  const off: Decision<U> = { mode: "off", answers: none(input.questions), t, logId: null };
  if (!deps?.backend) return off;
  const mode = decisionModeOf(settings, input.use);
  if (mode === "off") return off;
  const backend = deps.backend;
  const state = cutBytes(input.state);
  const ask = (model: string) =>
    backend
      .decide({
        model,
        state,
        questions: input.questions,
        user: input.orgId,
        timeoutMs: settings.timeout_ms,
      })
      .catch(
        (): DecisionResult => ({
          answers: none(input.questions),
          inputTokens: 0,
          costUsd: 0,
          latencyMs: 0,
          error: "failed",
        }),
      );
  const warn = (e: unknown) =>
    deps.logger?.warn("decision log failed", { use: input.use, error: String(e) });

  if (mode === "shadow") {
    const all = Promise.all(
      shadowModelsOf(settings).map(async (model) => {
        const r = await ask(model);
        await record(db, deps, input, model, true, r).catch(warn);
      }),
    );
    const settled = all.then(
      () => undefined,
      () => undefined,
    );
    if (input.wait !== false) await settled;
    else if (input.runId) {
      const key = `${input.runId}:${input.use}`;
      inFlight.set(key, settled);
      void settled.then(() => {
        if (inFlight.get(key) === settled) inFlight.delete(key);
      });
    }
    return { mode, answers: none(input.questions), t, logId: null };
  }

  const r = await ask(settings.model);
  const logId = await record(db, deps, input, settings.model, false, r).catch((e) => {
    warn(e);
    return null;
  });
  return { mode, answers: r.answers, t, logId };
}

/** What the code did with an acting answer: skipped, ran, flagged, asked, held, lowered. */
export async function markDecision(db: Database, logId: string | null, action: string) {
  if (!logId) return;
  await db
    .execute(
      sql`update public.decision_log set action = ${action.slice(0, 40)} where id = ${logId}::uuid`,
    )
    .catch(() => {});
}

/**
 * Adds to the label of a run's rows for a use (all models, shadow and acting): what really
 * happened, known later in the same run.
 */
export async function labelDecisions(
  db: Database,
  where: { runId: string | null; use: DecisionUse; subjectId?: string | null },
  outcome: Record<string, unknown>,
) {
  if (!where.runId && !where.subjectId) return;
  await db
    .execute(sql`
      update public.decision_log set outcome = coalesce(outcome, '{}'::jsonb) || ${JSON.stringify(outcome)}::jsonb
      where use = ${where.use}
        and (${where.runId}::uuid is null or run_id = ${where.runId}::uuid)
        and (${where.subjectId ?? null}::uuid is null or subject_id = ${where.subjectId ?? null}::uuid)`)
    .catch(() => {});
}

/**
 * Worker sweep (hourly): labels from what the product recorded, then the 90-day cleanup.
 * - scan_gate: did the scan make a suggestion; was one accepted.
 * - push_score: accepted or dismissed.
 * - long_run, effort: how the run ended.
 * - tool_gate: whether an approval asked for that run was refused (rare; the hand-made set is the
 *   real label).
 * watcher_gate and reply_check are labelled in the run itself (labelDecisions).
 */
export async function sweepDecisionLog(
  db: Database,
): Promise<{ labelled: number; purged: number }> {
  const counts = await Promise.all([
    db.execute<{ n: number }>(sql`
      with u as (
        update public.decision_log d set outcome = jsonb_build_object(
          'suggested', exists (select 1 from public.suggestions s where s.run_id = d.run_id),
          'accepted', exists (select 1 from public.suggestions s where s.run_id = d.run_id and s.status = 'accepted'),
          'pending', exists (select 1 from public.suggestions s where s.run_id = d.run_id and s.status = 'pending'))
        from public.runs r
        where d.use = 'scan_gate' and d.action <> 'skipped' and r.id = d.run_id and r.status in ('completed', 'failed', 'cancelled')
          and d.created_at > now() - interval '30 days'
          and (d.outcome is null or (d.outcome ->> 'pending')::boolean)
        returning 1)
      select count(*)::int as n from u`),
    db.execute<{ n: number }>(sql`
      with u as (
        update public.decision_log d set outcome = jsonb_build_object('status', s.status)
        from public.suggestions s
        where d.use = 'push_score' and s.id = d.subject_id and s.status <> 'pending'
          and d.created_at > now() - interval '30 days'
          and (d.outcome is null or d.outcome ->> 'status' is distinct from s.status)
        returning 1)
      select count(*)::int as n from u`),
    db.execute<{ n: number }>(sql`
      with u as (
        update public.decision_log d set outcome = coalesce(d.outcome, '{}'::jsonb) || jsonb_build_object('run_status', r.status)
        from public.runs r
        where d.use in ('long_run', 'effort', 'tool_gate') and r.id = d.run_id
          and r.status in ('completed', 'failed', 'cancelled')
          and d.created_at > now() - interval '30 days'
          and (d.outcome is null or not d.outcome ? 'run_status')
        returning 1)
      select count(*)::int as n from u`),
  ]);
  const [purged] = await db.execute<{ n: number }>(sql`
    with d as (delete from public.decision_log where created_at < now() - interval '90 days' returning 1)
    select count(*)::int as n from d`);
  return {
    labelled: counts.reduce((n, rows) => n + (rows[0]?.n ?? 0), 0),
    purged: purged?.n ?? 0,
  };
}
