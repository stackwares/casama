/**
 * Prometheus metrics (D-075): the spec's dashboard numbers, computed from Postgres on each scrape
 * (cheap aggregates over short windows), plus in-process HTTP counters. Served at /metrics; set
 * METRICS_TOKEN to require a bearer token.
 */
import type { Database } from "@kasama/db";
import { sql } from "drizzle-orm";
import type { MiddlewareHandler } from "hono";

const http = new Map<string, number>();
const latency = { count: 0, sum: 0 };

export const httpMetrics: MiddlewareHandler = async (c, next) => {
  const t0 = performance.now();
  await next();
  const cls = `${Math.floor(c.res.status / 100)}xx`;
  http.set(cls, (http.get(cls) ?? 0) + 1);
  latency.count++;
  latency.sum += (performance.now() - t0) / 1000;
};

type Line = [name: string, labels: Record<string, string>, value: number];

export async function renderMetrics(db: Database) {
  const lines: Line[] = [];
  const help: Record<string, [string, string]> = {};
  const add = (
    name: string,
    type: string,
    doc: string,
    rows: Array<[Record<string, string>, number]>,
  ) => {
    help[name] = [type, doc];
    for (const [l, v] of rows) lines.push([name, l, v]);
  };
  const num = (v: unknown) => (v == null ? Number.NaN : Number(v));

  const runs = await db.execute<{ status: string; n: number }>(sql`
    select status, count(*)::int as n from public.runs where created_at > now() - interval '15 minutes' group by 1`);
  add(
    "kasama_runs_15m",
    "gauge",
    "Runs created in the last 15 minutes by status",
    runs.map((r) => [{ status: r.status }, r.n]),
  );
  const finished = runs
    .filter((r) => ["completed", "failed"].includes(r.status))
    .reduce((a, r) => a + r.n, 0);
  const failed = runs.find((r) => r.status === "failed")?.n ?? 0;
  add("kasama_run_failure_ratio_15m", "gauge", "Failed / finished runs over the last 15 minutes", [
    [{}, finished ? failed / finished : 0],
  ]);

  const [t] = await db.execute<{ p50: number | null; p95: number | null; n: number }>(sql`
    select percentile_cont(0.5) within group (order by extract(epoch from first_token_at - created_at)) as p50,
           percentile_cont(0.95) within group (order by extract(epoch from first_token_at - created_at)) as p95,
           count(*)::int as n
    from public.runs where first_token_at is not null and created_at > now() - interval '1 hour'`);
  add("kasama_time_to_first_token_seconds", "gauge", "Run start to first model token, last hour", [
    [{ quantile: "0.5" }, num(t?.p50)],
    [{ quantile: "0.95" }, num(t?.p95)],
  ]);

  const [cs] = await db.execute<{ p50: number | null; p95: number | null }>(sql`
    with s as (
      select e.run_id, e.payload->>'computer_id' as cid, e.payload->>'state' as state, e.created_at,
             lag(e.payload->>'state') over w as prev, lag(e.created_at) over w as prev_at
      from public.run_events e
      where e.type = 'computer.state' and e.created_at > now() - interval '1 hour'
      window w as (partition by e.run_id, e.payload->>'computer_id' order by e.seq))
    select percentile_cont(0.5) within group (order by extract(epoch from created_at - prev_at)) as p50,
           percentile_cont(0.95) within group (order by extract(epoch from created_at - prev_at)) as p95
    from s where state = 'running' and prev in ('provisioning', 'starting')`);
  add("kasama_computer_start_seconds", "gauge", "Computer provisioning or wake time, last hour", [
    [{ quantile: "0.5" }, num(cs?.p50)],
    [{ quantile: "0.95" }, num(cs?.p95)],
  ]);

  const comps = await db.execute<{ state: string; n: number }>(
    sql`select state, count(*)::int as n from public.computers where kind <> 'local' group by 1`,
  );
  add(
    "kasama_computers",
    "gauge",
    "Computers by state",
    comps.map((r) => [{ state: r.state }, r.n]),
  );

  const [cost] = await db.execute<{ avg: number | null }>(sql`
    select avg(cost_usd)::float as avg from public.runs where status = 'completed' and created_at > now() - interval '1 hour'`);
  add("kasama_cost_per_run_usd", "gauge", "Average cost of completed runs, last hour", [
    [{}, num(cost?.avg)],
  ]);

  const queues = await db
    .execute<{ q: string; n: number }>(sql`
      select coalesce(queue_name, 'none') as q, count(*)::int as n from dbos.workflow_status
      where status in ('ENQUEUED', 'PENDING') group by 1`)
    .catch(() => [] as Array<{ q: string; n: number }>);
  add(
    "kasama_queue_depth",
    "gauge",
    "Workflows enqueued or running by queue",
    queues.map((r) => [{ queue: r.q }, r.n]),
  );

  add(
    "kasama_http_requests_total",
    "counter",
    "API responses by status class",
    [...http].map(([k, v]) => [{ class: k }, v]),
  );
  add("kasama_http_request_seconds_sum", "counter", "Total API response time", [[{}, latency.sum]]);
  add("kasama_http_request_seconds_count", "counter", "API responses timed", [[{}, latency.count]]);

  const out: string[] = [];
  for (const [name, [type, doc]] of Object.entries(help)) {
    out.push(`# HELP ${name} ${doc}`, `# TYPE ${name} ${type}`);
    for (const [n, l, v] of lines.filter((x) => x[0] === name)) {
      const labels = Object.entries(l)
        .map(([k, val]) => `${k}="${val.replace(/["\\\n]/g, "_")}"`)
        .join(",");
      out.push(`${n}${labels ? `{${labels}}` : ""} ${Number.isNaN(v) ? "NaN" : v}`);
    }
  }
  return `${out.join("\n")}\n`;
}
