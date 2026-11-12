/**
 * Daily usage and workspace analytics rollups (ANALYTICS-PLAN §6.11).
 * Runs at 00:20 UTC to summarize yesterday's metrics in Postgres and emit deterministic PostHog events.
 * People who opted out (profiles.analytics_opt_out) and workspaces that opted out (organizations.analytics_opt_out)
 * are excluded in SQL.
 *
 * usage_daily counts only runs a person started themselves (chat, mention, voice): routines, watchers,
 * webhooks and other automated triggers never make a person look active. They are counted in
 * workspace_daily, which is sent personless.
 */
import type { Database } from "@casama/db";
import {
  deterministicUuid,
  getProductAnalytics,
  type ProductAnalytics,
} from "@casama/observability";
import { sql } from "drizzle-orm";

/** Triggers that mean a person did something (everything else is automation). */
export const INTERACTIVE_TRIGGERS = ["chat", "mention", "voice"] as const;

export async function runDailyAnalyticsRollup(
  db: Database,
  opts: { date?: Date; analytics?: ProductAnalytics } = {},
): Promise<{ people: number; workspaces: number }> {
  const analytics = opts.analytics ?? getProductAnalytics();
  if (!analytics.enabled) return { people: 0, workspaces: 0 };
  const date = opts.date ?? new Date(Date.now() - 24 * 60 * 60 * 1000);
  const dateStr = date.toISOString().slice(0, 10);
  const start = `${dateStr}T00:00:00.000Z`;
  const end = `${dateStr}T23:59:59.999Z`;
  const endOfDay = new Date(end);
  const interactive = sql`array(select jsonb_array_elements_text(${JSON.stringify(INTERACTIVE_TRIGGERS)}::text::jsonb))`;

  const people = await db.execute<{
    user_id: string;
    runs_started: number;
    runs_completed: number;
    runs_failed: number;
    runs_cancelled: number;
    bots_used: number;
    cost_usd: number;
  }>(sql`
    select
      r.created_by as user_id,
      count(*)::int as runs_started,
      (count(*) filter (where r.status = 'completed'))::int as runs_completed,
      (count(*) filter (where r.status = 'failed'))::int as runs_failed,
      (count(*) filter (where r.status = 'cancelled'))::int as runs_cancelled,
      count(distinct r.bot_id)::int as bots_used,
      coalesce(sum(r.cost_usd), 0)::float as cost_usd
    from public.runs r
    join public.profiles p on p.user_id = r.created_by
    join public.organizations o on o.id = r.org_id
    where r.created_at >= ${start}::timestamptz
      and r.created_at <= ${end}::timestamptz
      and r.created_by is not null
      and r.trigger = any(${interactive})
      and p.analytics_opt_out = false
      and o.analytics_opt_out = false
    group by r.created_by
  `);

  for (const row of people) {
    analytics.capture({
      event: "usage_daily",
      distinctId: row.user_id,
      uuid: rollupUuid("usage_daily", row.user_id, dateStr),
      timestamp: endOfDay,
      properties: {
        runs_started: Number(row.runs_started),
        runs_completed: Number(row.runs_completed),
        runs_failed: Number(row.runs_failed),
        runs_cancelled: Number(row.runs_cancelled),
        bots_used: Number(row.bots_used),
        cost_usd: Number(row.cost_usd),
      },
    });
  }

  const workspaces = await db.execute<{
    org_id: string;
    trigger: string;
    runs: number;
    runs_failed: number;
    cost_usd: number;
  }>(sql`
    select
      r.org_id,
      r.trigger,
      count(*)::int as runs,
      (count(*) filter (where r.status = 'failed'))::int as runs_failed,
      coalesce(sum(r.cost_usd), 0)::float as cost_usd
    from public.runs r
    join public.organizations o on o.id = r.org_id
    where r.created_at >= ${start}::timestamptz
      and r.created_at <= ${end}::timestamptz
      and o.analytics_opt_out = false
    group by r.org_id, r.trigger
  `);

  interface Agg {
    runs_total: number;
    runs_failed: number;
    cost_usd: number;
    [key: string]: number;
  }
  const byOrg = new Map<string, Agg>();
  for (const row of workspaces) {
    const props: Agg = byOrg.get(row.org_id) ?? { runs_total: 0, runs_failed: 0, cost_usd: 0 };
    props.runs_total += Number(row.runs);
    props.runs_failed += Number(row.runs_failed);
    props.cost_usd += Number(row.cost_usd);
    props[`runs_by_trigger_${row.trigger}`] = Number(row.runs);
    byOrg.set(row.org_id, props);
  }
  for (const [orgId, properties] of byOrg) {
    analytics.capture({
      event: "workspace_daily",
      distinctId: `workspace:${orgId}`,
      orgId,
      personless: true,
      uuid: rollupUuid("workspace_daily", orgId, dateStr),
      timestamp: endOfDay,
      properties,
    });
  }

  await analytics.flush();
  return { people: people.length, workspaces: byOrg.size };
}

/** One id per (event, entity, day), so a retried rollup merges in PostHog instead of doubling. */
export const rollupUuid = (kind: string, id: string, date: string) =>
  deterministicUuid("rollup", kind, id, date);
