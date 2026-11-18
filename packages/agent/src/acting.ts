import type { Database } from "@casama/db";
import { sql } from "drizzle-orm";

/**
 * The person a run acts for: its sender, the routine's creator, or a parent run's. A run started
 * by a linked bot (trigger 'link', D-143) acts for nobody, even though it's recorded under the
 * owner: someone else wrote its request, so the owner's personal data and logins stay out of reach
 * (audit 2026-11).
 */
export async function actingUserOf(db: Database, runId: string): Promise<string | null> {
  const [r] = await db.execute<{ u: string | null; linked: boolean }>(sql`
    with recursive up as (
      select x.id, x.parent_run_id, x.created_by, x.routine_id, x.trigger, 0 as depth from public.runs x where x.id = ${runId}::uuid
      union all
      select p.id, p.parent_run_id, p.created_by, p.routine_id, p.trigger, up.depth + 1
      from public.runs p join up on p.id = up.parent_run_id where up.depth < 8
    )
    select (select coalesce(up.created_by, rt.created_by) from up left join public.routines rt on rt.id = up.routine_id
            where coalesce(up.created_by, rt.created_by) is not null order by up.depth limit 1) as u,
           exists (select 1 from up where up.trigger = 'link') as linked`);
  return r?.linked ? null : (r?.u ?? null);
}

/**
 * Who a run's messages and schedules belong to: the person it acts for (walking up sub-runs and
 * routines), else the bot's creator; with that person's timezone. One rule for every tool.
 */
export async function personForRun(
  db: Database,
  runId: string,
): Promise<{ userId: string | null; timezone: string | null }> {
  const acting = await actingUserOf(db, runId);
  const [r] = await db.execute<{ user_id: string | null; timezone: string | null }>(sql`
    select coalesce(${acting}::uuid, b.created_by) as user_id, p.timezone
    from public.runs r join public.bots b on b.id = r.bot_id
    left join public.profiles p on p.user_id = coalesce(${acting}::uuid, b.created_by)
    where r.id = ${runId}::uuid`);
  return { userId: r?.user_id ?? null, timezone: r?.timezone ?? null };
}
