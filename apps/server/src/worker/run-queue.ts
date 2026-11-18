/**
 * The runs queue is partitioned by workspace (billing audit 2026-11-17): each workspace runs at
 * most RUN_WORKSPACE_CONCURRENCY runs at once, and the rest wait their turn. Before, one workspace
 * could start as many runs as the server had slots, all passing one credit check before any spend
 * was recorded, and fill every slot other workspaces needed.
 *
 * Every enqueue on the runs queue passes the run's workspace id as its partition key: on a
 * partitioned queue a run without one is never started.
 */
import type { Database } from "@casama/db";
import { sql } from "drizzle-orm";

type Exec = Pick<Database, "execute">;

/** Key for runs whose row can't be found (a run deleted before it started). */
const NO_WORKSPACE = "none";

/** The partition a run is queued under: its workspace. */
export async function runPartitionKey(db: Exec, runId: string): Promise<string> {
  const [r] = await db.execute<{ org_id: string }>(
    sql`select org_id::text as org_id from public.runs where id = ${runId}::uuid`,
  );
  return r?.org_id ?? NO_WORKSPACE;
}

/**
 * Gives queued runs that have no partition key (enqueued by an older process, before the queue
 * was partitioned) their workspace's, so they still start.
 */
export async function keyQueuedRuns(db: Exec): Promise<number> {
  const rows = await db.execute<{ workflow_uuid: string }>(sql`
    update dbos.workflow_status w
       set queue_partition_key = coalesce(
         (select r.org_id::text from public.runs r
           where w.workflow_uuid ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
             and r.id = w.workflow_uuid::uuid), ${NO_WORKSPACE})
     where w.queue_name = 'runs' and w.status = 'ENQUEUED' and w.queue_partition_key is null
     returning w.workflow_uuid`);
  return rows.length;
}
