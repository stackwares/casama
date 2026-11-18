/**
 * After k6: time to first token and completion for the load test's runs, from Postgres.
 *   node --env-file=../../.env load/report.ts [data]
 */
import { readFileSync } from "node:fs";
import postgres from "postgres";

const data = JSON.parse(readFileSync(process.argv[2] ?? "/tmp/casama-load.json", "utf8")) as {
  org_id: string;
};
const sql = postgres(process.env.DATABASE_URL as string, { max: 1 });
const rows = await sql<
  {
    trigger: string;
    runs: number;
    completed: number;
    p50: number;
    p95: number;
    max: number;
    start_p95: number;
  }[]
>`
  select trigger, count(*)::int as runs, count(*) filter (where status = 'completed')::int as completed,
    round(percentile_cont(0.5) within group (order by extract(epoch from first_token_at - created_at))::numeric, 3)::float as p50,
    round(percentile_cont(0.95) within group (order by extract(epoch from first_token_at - created_at))::numeric, 3)::float as p95,
    round(max(extract(epoch from first_token_at - created_at))::numeric, 3)::float as max,
    round(percentile_cont(0.95) within group (order by extract(epoch from started_at - created_at))::numeric, 3)::float as start_p95
  from public.runs where org_id = ${data.org_id}::uuid group by trigger order by trigger`;
console.table(rows);
await sql.end();
// Every run must have finished with a first token; no runs (or unfinished ones) is a failure, not 0 s.
const incomplete = rows.length === 0 || rows.some((r) => r.completed < r.runs || r.p95 === null);
const worst = Math.max(...rows.map((r) => r.p95 ?? Number.POSITIVE_INFINITY));
const pass = !incomplete && worst < 3;
console.log(
  `p95 time to first token: ${worst}s (gate: under 3 s; all runs complete: ${!incomplete}) -> ${pass ? "PASS" : "FAIL"}`,
);
process.exit(pass ? 0 : 1);
