/**
 * Daily usage and workspace analytics rollups (ANALYTICS-PLAN §6.11).
 * Runs at 00:20 UTC to summarize yesterday's metrics in Postgres and emit deterministic PostHog events.
 * People who opted out (profiles.analytics_opt_out) and workspaces that opted out (organizations.analytics_opt_out)
 * are excluded in SQL.
 *
 * usage_daily counts only what a person did themselves (runs they started in chat, mention or voice, and the
 * approvals they decided): routines, watchers, webhooks and other automated triggers never make a person look
 * active. Automation is counted in workspace_daily, which is sent personless. Every property is a number.
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

/** Usage kinds counted per workspace, and the property each becomes (seconds, so no money leaves). */
const LEDGER_KINDS: Record<string, string> = {
  computer_seconds: "computer_seconds",
  voice_seconds: "voice_seconds",
  stt_seconds: "dictation_seconds",
};

type Props = Record<string, number>;

const textArray = (xs: readonly string[]) =>
  sql`array(select jsonb_array_elements_text(${JSON.stringify(xs)}::text::jsonb))`;

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

  // --- people ---------------------------------------------------------------------------------
  const people = new Map<string, Props>();
  const person = (id: string): Props => {
    let p = people.get(id);
    if (!p) {
      p = {};
      people.set(id, p);
    }
    return p;
  };

  const runRows = await db.execute<{
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
      and r.trigger = any(${textArray(INTERACTIVE_TRIGGERS)})
      and p.analytics_opt_out = false
      and o.analytics_opt_out = false
    group by r.created_by
  `);
  for (const row of runRows)
    Object.assign(person(row.user_id), {
      runs_started: Number(row.runs_started),
      runs_completed: Number(row.runs_completed),
      runs_failed: Number(row.runs_failed),
      runs_cancelled: Number(row.runs_cancelled),
      bots_used: Number(row.bots_used),
      cost_usd: Number(row.cost_usd),
    });

  const approvalRows = await db.execute<{ user_id: string; approved: number; denied: number }>(sql`
    select a.decided_by as user_id,
      (count(*) filter (where a.status = 'approved'))::int as approved,
      (count(*) filter (where a.status = 'denied'))::int as denied
    from public.approvals a
    join public.profiles p on p.user_id = a.decided_by
    join public.organizations o on o.id = a.org_id
    where a.decided_at >= ${start}::timestamptz and a.decided_at <= ${end}::timestamptz
      and a.status in ('approved', 'denied') and a.decided_by is not null
      and p.analytics_opt_out = false and o.analytics_opt_out = false
    group by a.decided_by
  `);
  for (const row of approvalRows)
    Object.assign(person(row.user_id), {
      approvals_approved: Number(row.approved),
      approvals_denied: Number(row.denied),
    });

  for (const [userId, properties] of people)
    analytics.capture({
      event: "usage_daily",
      distinctId: userId,
      uuid: rollupUuid("usage_daily", userId, dateStr),
      timestamp: endOfDay,
      properties: { runs_started: 0, ...properties },
    });

  // --- workspaces (personless) ----------------------------------------------------------------
  const orgs = new Map<string, Props>();
  const org = (id: string): Props => {
    let p = orgs.get(id);
    if (!p) {
      p = { runs_total: 0, runs_failed: 0, cost_usd: 0 };
      orgs.set(id, p);
    }
    return p;
  };

  const triggerRows = await db.execute<{
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
  for (const row of triggerRows) {
    const p = org(row.org_id);
    p.runs_total = (p.runs_total ?? 0) + Number(row.runs);
    p.runs_failed = (p.runs_failed ?? 0) + Number(row.runs_failed);
    p.cost_usd = (p.cost_usd ?? 0) + Number(row.cost_usd);
    p[`runs_by_trigger_${row.trigger}`] = Number(row.runs);
  }

  const activeRows = await db.execute<{
    org_id: string;
    members_active: number;
    bots_active: number;
  }>(sql`
    select r.org_id, count(distinct r.created_by)::int as members_active, count(distinct r.bot_id)::int as bots_active
    from public.runs r join public.organizations o on o.id = r.org_id
    where r.created_at >= ${start}::timestamptz and r.created_at <= ${end}::timestamptz
      and o.analytics_opt_out = false
    group by r.org_id
  `);
  for (const row of activeRows)
    Object.assign(org(row.org_id), {
      members_active: Number(row.members_active),
      bots_active: Number(row.bots_active),
    });

  const ledgerRows = await db.execute<{ org_id: string; kind: string; quantity: number }>(sql`
    select l.org_id, l.kind, coalesce(sum(l.quantity), 0)::float as quantity
    from public.usage_ledger l join public.organizations o on o.id = l.org_id
    where l.created_at >= ${start}::timestamptz and l.created_at <= ${end}::timestamptz
      and l.kind = any(${textArray(Object.keys(LEDGER_KINDS))})
      and o.analytics_opt_out = false
    group by l.org_id, l.kind
  `);
  for (const row of ledgerRows) {
    const name = LEDGER_KINDS[row.kind];
    if (name) org(row.org_id)[name] = Number(row.quantity);
  }

  const orgApprovalRows = await db.execute<{
    org_id: string;
    approved: number;
    denied: number;
  }>(sql`
    select a.org_id,
      (count(*) filter (where a.status = 'approved'))::int as approved,
      (count(*) filter (where a.status = 'denied'))::int as denied
    from public.approvals a join public.organizations o on o.id = a.org_id
    where a.decided_at >= ${start}::timestamptz and a.decided_at <= ${end}::timestamptz
      and a.status in ('approved', 'denied') and o.analytics_opt_out = false
    group by a.org_id
  `);
  for (const row of orgApprovalRows)
    Object.assign(org(row.org_id), {
      approvals_approved: Number(row.approved),
      approvals_denied: Number(row.denied),
    });

  for (const [orgId, properties] of orgs)
    analytics.capture({
      event: "workspace_daily",
      distinctId: `workspace:${orgId}`,
      orgId,
      personless: true,
      uuid: rollupUuid("workspace_daily", orgId, dateStr),
      timestamp: endOfDay,
      properties,
    });

  await analytics.flush();
  return { people: people.size, workspaces: orgs.size };
}

/** One id per (event, entity, day), so a retried rollup merges in PostHog instead of doubling. */
export const rollupUuid = (kind: string, id: string, date: string) =>
  deterministicUuid("rollup", kind, id, date);
