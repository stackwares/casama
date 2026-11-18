/**
 * Compares two eval reports (D-106): token use and success, task by task. Used to check lazy tool
 * loading: run the same subset with the worker's LAZY_TOOLS_THRESHOLD at 0 (off) and default (on).
 *
 *   node packages/evals/src/compare.ts results/lazy-off.json results/lazy-on.json
 *
 * Exit code 1 when success drops or input tokens fall by less than --min-saving (default 0.3 for
 * bots with many tools; pass --min-saving 0 to only guard success).
 */
import { readFileSync } from "node:fs";
import { parseArgs } from "node:util";
import type { EvalReport } from "./types.ts";

export function compareReports(before: EvalReport, after: EvalReport) {
  const inBefore = before.tokens_in ?? 0;
  const inAfter = after.tokens_in ?? 0;
  const saving = inBefore > 0 ? 1 - inAfter / inBefore : 0;
  const byId = new Map(before.tasks.map((t) => [t.id, t]));
  const regressions = after.tasks
    .filter((t) => !t.skipped && byId.get(t.id)?.pass && !t.pass)
    .map((t) => t.id);
  return {
    saving,
    success_before: before.success_rate,
    success_after: after.success_rate,
    success_delta: after.success_rate - before.success_rate,
    regressions,
  };
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const { values, positionals } = parseArgs({
    allowPositionals: true,
    options: { "min-saving": { type: "string", default: "0.3" } },
  });
  const [a, b] = positionals;
  if (!a || !b) {
    console.error("usage: compare.ts <before.json> <after.json> [--min-saving 0.3]");
    process.exit(2);
  }
  const before = JSON.parse(readFileSync(a, "utf8")) as EvalReport;
  const after = JSON.parse(readFileSync(b, "utf8")) as EvalReport;
  const c = compareReports(before, after);
  console.log(
    `${before.label ?? a} → ${after.label ?? b}: input tokens ${(c.saving * 100).toFixed(1)}% lower, success ${(c.success_before * 100).toFixed(0)}% → ${(c.success_after * 100).toFixed(0)}%${c.regressions.length ? `, newly failing: ${c.regressions.join(", ")}` : ""}`,
  );
  const minSaving = Number(values["min-saving"]);
  if (c.success_delta < 0 || c.saving < minSaving) process.exit(1);
}
