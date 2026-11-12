/**
 * Daily usage and workspace analytics rollups (ANALYTICS-PLAN §6.11).
 * Runs at 00:20 UTC to summarize yesterday's metrics in Postgres and emit deterministic PostHog events.
 * Opted-out users and opted-out workspaces are excluded in SQL queries.
 */
import { sql } from "drizzle-orm";
import type { Database } from "@casama/db";
import { getProductAnalytics } from "@casama/observability";

export async function runDailyAnalyticsRollup(db: Database, targetDate?: Date): Promise<void> {
  const analytics = getProductAnalytics();
  const date = targetDate ?? new Date(Date.now() - 24 * 60 * 60 * 1000);
  const dateStr = date.toISOString().slice(0, 10);
  const startOfDay = new Date(`${dateStr}T00:00:00.000Z`);
  const endOfDay = new Date(`${dateStr}T23:59:59.999Z`);

  // 1. Person usage_daily: summarize active people who haven't opted out
  // Count runs, tokens, costs, approvals, messages
  const userRows = await db.execute<{
    user_id: string;
    runs_started: number;
    runs_completed: number;
    runs_failed: number;
    runs_cancelled: number;
    cost_usd: number;
  }>(sql`
    select 
      r.user_id,
      count(*)::int as runs_started,
      count(*) filter (where r.status = 'completed')::int as runs_completed,
      count(*) filter (where r.status = 'failed')::int as runs_failed,
      count(*) filter (where r.status = 'cancelled')::int as runs_cancelled,
      coalesce(sum(r.cost_usd), 0)::float as cost_usd
    from public.runs r
    join public.profiles p on p.user_id = r.user_id
    where r.created_at >= ${startOfDay.toISOString()}::timestamptz
      and r.created_at <= ${endOfDay.toISOString()}::timestamptz
      and r.user_id is not null
      and p.analytics_opt_out = false
    group by r.user_id
  `);

  for (const row of userRows) {
    analytics.capture({
      event: "usage_daily",
      distinctId: row.user_id,
      uuid: `rollup:usage_daily:${row.user_id}:${dateStr}`,
      timestamp: endOfDay,
      properties: {
        runs_started: Number(row.runs_started || 0),
        runs_completed: Number(row.runs_completed || 0),
        runs_failed: Number(row.runs_failed || 0),
        runs_cancelled: Number(row.runs_cancelled || 0),
        cost_usd: Number(row.cost_usd || 0),
      },
    });
  }

  // 2. Workspace workspace_daily: personless workspace activity rollup
  const orgRows = await db.execute<{
    org_id: string;
    runs_total: number;
    runs_completed: number;
    runs_failed: number;
    cost_usd: number;
  }>(sql`
    select
      r.org_id,
      count(*)::int as runs_total,
      count(*) filter (where r.status = 'completed')::int as runs_completed,
      count(*) filter (where r.status = 'failed')::int as runs_failed,
      coalesce(sum(r.cost_usd), 0)::float as cost_usd
    from public.runs r
    join public.organizations o on o.id = r.org_id
    where r.created_at >= ${startOfDay.toISOString()}::timestamptz
      and r.created_at <= ${endOfDay.toISOString()}::timestamptz
      and r.org_id is not null
    group by r.org_id
  `);

  for (const row of orgRows) {
    analytics.capture({
      event: "workspace_daily",
      distinctId: `workspace:${row.org_id}`,
      orgId: row.org_id,
      personless: true,
      uuid: `rollup:workspace_daily:${row.org_id}:${dateStr}`,
      timestamp: endOfDay,
      properties: {
        runs_total: Number(row.runs_total || 0),
        runs_completed: Number(row.runs_completed || 0),
        runs_failed: Number(row.runs_failed || 0),
        cost_usd: Number(row.cost_usd || 0),
      },
    });
  }

  await analytics.flush();
}
