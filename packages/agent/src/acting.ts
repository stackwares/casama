import type { Database } from "@kasama/db";
import { sql } from "drizzle-orm";

/** The person a run acts for: its sender, the routine's creator, or a parent run's. */
export async function actingUserOf(db: Database, runId: string): Promise<string | null> {
  const [r] = await db.execute<{ u: string | null }>(sql`
    with recursive up as (
      select x.id, x.parent_run_id, x.created_by, x.routine_id, 0 as depth from public.runs x where x.id = ${runId}::uuid
      union all
      select p.id, p.parent_run_id, p.created_by, p.routine_id, up.depth + 1
      from public.runs p join up on p.id = up.parent_run_id where up.depth < 8
    )
    select coalesce(up.created_by, rt.created_by) as u from up
    left join public.routines rt on rt.id = up.routine_id
    where coalesce(up.created_by, rt.created_by) is not null order by up.depth limit 1`);
  return r?.u ?? null;
}
