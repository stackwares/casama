/**
 * A run that failed because of Casama or a provider (a crash, a model that broke off or timed
 * out) costs the person nothing (D-275): its Casama-billed model usage is waived. Runs that
 * stopped at a limit, looped, or were stopped by the person are charged as before.
 */
import type { Database } from "@casama/db";
import { sql } from "drizzle-orm";

/** Failure codes that are never the person's doing. */
export const WAIVED_FAILURES = new Set([
  "run_error",
  "model_error",
  "model_timeout",
  "provider_error",
]);

/**
 * Waives a failed run's billable model usage: rows not yet settled stop being billable; rows
 * already settled come back as a refund, once per run. Returns the dollars waived.
 */
export async function waiveFailedRun(db: Database, runId: string): Promise<number> {
  return db.transaction(async (tx) => {
    const unbilled = await tx.execute<{ usd: string | null }>(sql`
      with w as (
        update public.usage_ledger set billable = false,
          meta = meta || jsonb_build_object('waived', 'failed_run')
        where run_id = ${runId}::uuid and billable and billed_at is null
          and kind in ('tokens_in', 'tokens_out')
        returning cost_usd)
      select sum(cost_usd)::text as usd from w`);
    const billed = await tx.execute<{ org_id: string; usd: string }>(sql`
      select org_id, sum(cost_usd)::text as usd from public.usage_ledger
      where run_id = ${runId}::uuid and billable and billed_at is not null
        and kind in ('tokens_in', 'tokens_out')
      group by org_id`);
    let refunded = 0;
    for (const b of billed) {
      const usd = Number(b.usd);
      if (usd <= 0) continue;
      await tx.execute(sql`select public.credit_apply(${b.org_id}::uuid, ${usd}, 'refund',
        ${`failed-run:${runId}`}, 'A run that failed on our side')`);
      refunded += usd;
    }
    return Number(unbilled[0]?.usd ?? 0) + refunded;
  });
}

/** Below this balance a workspace's owners hear that credits are running low (D-275). */
export const LOW_CREDIT_USD = 1;

/**
 * Workspaces using Casama's paid credits whose balance fell under LOW_CREDIT_USD (and above zero,
 * where running out has its own message), each owner told at most once a week. Returns who to tell.
 */
export async function lowCreditWorkspaces(db: Database) {
  return db.execute<{ org_id: string; balance: string; owner_id: string }>(sql`
    with bal as (
      select distinct on (l.org_id) l.org_id, l.balance_after as balance
      from public.credit_ledger l order by l.org_id, l.seq desc)
    select bal.org_id, bal.balance::text as balance, m.user_id as owner_id
    from bal
    join public.memberships m on m.org_id = bal.org_id and m.role = 'owner'
    where bal.balance > 0 and bal.balance < ${LOW_CREDIT_USD}
      and exists (select 1 from public.usage_ledger u where u.org_id = bal.org_id and u.billable
                  and u.created_at > now() - interval '1 day')
      and not exists (select 1 from public.notifications n where n.org_id = bal.org_id
                      and n.user_id = m.user_id and n.kind = 'credits_low'
                      and n.created_at > now() - interval '7 days')`);
}
