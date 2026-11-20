/**
 * Decision model settings (docs/DECISION-MODEL-PLAN.md §5.4, D-454): instance_settings
 * "decisions", read with the same short cache as the cloud models, so an owner's change reaches
 * every process within seconds. Every use is off until the owner sets it.
 */

import type { DecisionDeps } from "@casama/agent";
import { OpenRouterDecisions } from "@casama/agent";
import type { Database } from "@casama/db";
import { type DecisionSettings, type DecisionUse, decisionSettings } from "@casama/domain";
import { sql } from "drizzle-orm";

const KEY = "decisions";
const TTL_MS = 10_000;

let cached: { at: number; value: DecisionSettings } | null = null;

export async function getDecisionSettings(db: Database): Promise<DecisionSettings> {
  if (cached && Date.now() - cached.at < TTL_MS) return cached.value;
  const [row] = await db.execute<{ value: unknown }>(
    sql`select value from public.instance_settings where key = ${KEY}`,
  );
  const value = decisionSettings(row?.value);
  cached = { at: Date.now(), value };
  return value;
}

export async function setDecisionSettings(db: Database, value: unknown): Promise<DecisionSettings> {
  const stored = decisionSettings(value);
  await db.execute(sql`
    insert into public.instance_settings (key, value, updated_at)
    values (${KEY}, ${JSON.stringify(stored)}::jsonb, now())
    on conflict (key) do update set value = excluded.value, updated_at = now()`);
  cached = { at: Date.now(), value: stored };
  return stored;
}

/** Tests: forget the cached settings. */
export function resetDecisionSettingsCache() {
  cached = null;
}

/**
 * What runs need to ask a decision model: the server's shared OpenRouter key (Casama's on Cloud,
 * the owner's own on a self-hosted server). No key: every use stays off.
 */
export function decisionDeps(
  db: Database,
  opts: {
    key?: string;
    /** Casama Cloud bills acting calls like background calls. */
    billable: boolean;
    fetch?: typeof fetch;
    /** OpenRouter's base for tests (".../api/v1" is accepted). */
    base?: string;
    logger?: DecisionDeps["logger"];
  },
): DecisionDeps {
  return {
    settings: () => getDecisionSettings(db),
    backend: opts.key
      ? new OpenRouterDecisions(opts.key, {
          fetch: opts.fetch,
          base: opts.base?.replace(/\/api\/v1\/?$/, ""),
        })
      : null,
    billable: opts.billable,
    logger: opts.logger,
  };
}

// ---------------------------------------------------------------------------------------------
// Results: each model's answers against what really happened, at every threshold (plan §7.4)
// ---------------------------------------------------------------------------------------------

export type DecisionLogRow = {
  use: DecisionUse;
  model: string;
  answers: Record<string, unknown>;
  outcome: Record<string, unknown> | null;
  error: string | null;
  latency_ms: number;
  cost_usd: number;
};

interface Signal {
  use: DecisionUse;
  name: string;
  /** One number per row from its answers; null when it didn't answer. */
  value: (a: Record<string, unknown>) => number | null;
  /** The code acts at or below the threshold ("<=") or at or above it (">="). */
  acts: "<=" | ">=";
  labelled: (o: Record<string, unknown>) => boolean;
  /** The thing that happened: a find, a flag, an accept, a failed run, a told person. */
  positive: (o: Record<string, unknown>) => boolean;
  severe?: (o: Record<string, unknown>) => boolean;
}

const p = (a: Record<string, unknown>, k: string) =>
  typeof a[k] === "number" ? (a[k] as number) : null;
const maxOf = (...v: Array<number | null>) =>
  v.some((x) => x == null) ? null : Math.max(...(v as number[]));

const SIGNALS: Signal[] = [
  {
    use: "scan_gate",
    name: "scan_gate",
    value: (a) => maxOf(p(a, "needs_attention"), p(a, "from_person"), p(a, "time_bound")),
    acts: "<=",
    labelled: (o) => typeof o.suggested === "boolean" && o.pending !== true,
    positive: (o) => o.suggested === true,
    severe: (o) => o.accepted === true,
  },
  {
    use: "reply_check",
    name: "reply_check",
    value: (a) => maxOf(p(a, "overclaims"), p(a, "unfinished")),
    acts: ">=",
    labelled: (o) => o.checked === true,
    positive: (o) => o.checker_flagged === true,
  },
  {
    use: "reply_check",
    name: "reply_check:memory",
    value: (a) => p(a, "worth_remembering"),
    acts: "<=",
    labelled: (o) => typeof o.memories === "number" && o.memory_skipped !== true,
    positive: (o) => (o.memories as number) > 0,
  },
  {
    use: "reply_check",
    name: "reply_check:correction",
    value: (a) => p(a, "corrects_previous"),
    acts: ">=",
    labelled: (o) => typeof o.regex_correction === "boolean",
    positive: (o) => o.regex_correction === true,
  },
  {
    use: "push_score",
    name: "push_score",
    value: (a) => p(a, "worth_a_push"),
    acts: "<=",
    labelled: (o) => o.status === "accepted" || o.status === "dismissed",
    positive: (o) => o.status === "accepted",
  },
  {
    use: "tool_gate",
    name: "tool_gate",
    value: (a) => p(a, "asked_for"),
    acts: "<=",
    labelled: (o) => typeof o.run_status === "string",
    positive: () => false,
  },
  {
    use: "long_run",
    name: "long_run",
    value: (a) => p(a, "repeating"),
    acts: ">=",
    labelled: (o) => typeof o.run_status === "string",
    positive: (o) => o.run_status === "failed" || o.run_status === "cancelled",
  },
  {
    use: "effort",
    name: "effort",
    value: (a) => {
      const e = a.effort as { choice?: unknown; p?: Record<string, unknown> } | undefined;
      return typeof e?.p?.quick === "number" ? e.p.quick : null;
    },
    acts: ">=",
    labelled: (o) => typeof o.run_status === "string",
    positive: (o) => o.run_status !== "completed",
  },
  {
    use: "watcher_gate",
    name: "watcher_gate",
    value: (a) => p(a, "matches"),
    acts: "<=",
    labelled: (o) => typeof o.told === "boolean",
    positive: (o) => o.told === true,
  },
];

const THRESHOLDS = Array.from({ length: 19 }, (_, i) => Math.round((i + 1) * 5) / 100);

function percentile(sorted: number[], q: number) {
  if (!sorted.length) return 0;
  return sorted[Math.min(sorted.length - 1, Math.floor(q * sorted.length))] as number;
}

/** The results table from log rows (pure, for tests). */
export function decisionResults(rows: DecisionLogRow[]) {
  const items = [];
  for (const s of SIGNALS) {
    const mine = rows.filter((r) => r.use === s.use);
    for (const model of [...new Set(mine.map((r) => r.model))].sort()) {
      const of = mine.filter((r) => r.model === model);
      const scored = of
        .map((r) => ({ v: s.value(r.answers ?? {}), o: r.outcome ?? {} }))
        .filter((x): x is { v: number; o: Record<string, unknown> } => x.v != null);
      const labelled = scored.filter((x) => s.labelled(x.o));
      const lat = of
        .filter((r) => !r.error)
        .map((r) => r.latency_ms)
        .sort((a, b) => a - b);
      items.push({
        use: s.use,
        signal: s.name,
        model,
        rows: of.length,
        answered: scored.length,
        errors: of.filter((r) => r.error).length,
        latency_p50_ms: percentile(lat, 0.5),
        latency_p95_ms: percentile(lat, 0.95),
        cost_usd: Math.round(of.reduce((n, r) => n + Number(r.cost_usd || 0), 0) * 1e6) / 1e6,
        labelled: labelled.length,
        positives: labelled.filter((x) => s.positive(x.o)).length,
        thresholds: THRESHOLDS.map((th) => {
          const acted = scored.filter((x) => (s.acts === "<=" ? x.v <= th : x.v >= th));
          const actedLabelled = acted.filter((x) => s.labelled(x.o));
          return {
            threshold: th,
            acted: acted.length,
            acted_positive: actedLabelled.filter((x) => s.positive(x.o)).length,
            acted_negative: actedLabelled.filter((x) => !s.positive(x.o)).length,
            acted_severe: s.severe ? actedLabelled.filter((x) => s.severe?.(x.o)).length : 0,
          };
        }),
      });
    }
  }
  return items;
}

/** Results over the last `days`, optionally for one use. Shadow rows and acting rows together. */
export async function loadDecisionResults(db: Database, days: number, use?: DecisionUse) {
  const rows = await db.execute<DecisionLogRow>(sql`
    select use, model, answers, outcome, error, latency_ms, cost_usd::float8 as cost_usd
    from public.decision_log
    where created_at > now() - make_interval(days => ${days})
      and (${use ?? null}::text is null or use = ${use ?? null})
    order by created_at desc limit 50000`);
  return { days, items: decisionResults([...rows]) };
}
