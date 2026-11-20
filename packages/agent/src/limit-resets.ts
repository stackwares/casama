import { type SQL, sql } from "drizzle-orm";

/**
 * When a saved reset last cleared a workspace's daily limit today (UTC), or null (D-443).
 * Counts that cover only part of the day's spend (Casama Link, check-ins) start again from here;
 * the full daily total subtracts `public.limit_reset_offset` instead. A reset used while nothing
 * had been spent yet has a zero offset and nothing to clear, so it isn't a starting point.
 */
export function dailyResetAt(org: SQL): SQL {
  return sql`(select max(lr.used_at) from public.limit_resets lr
    where lr.org_id = ${org} and lr.used_at is not null and lr.undone_at is null
      and lr.daily_offset_usd > 0
      and lr.used_at >= date_trunc('day', now() at time zone 'utc') at time zone 'utc')`;
}
