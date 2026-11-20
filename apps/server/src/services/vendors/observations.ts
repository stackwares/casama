import type { Database } from "@casama/db";
import { sql } from "drizzle-orm";
import { parseResendQuota } from "./count.ts";

const finite = (value: string | null) =>
  value !== null && value.trim() !== "" && Number.isFinite(Number(value)) && Number(value) >= 0
    ? Number(value)
    : null;
async function record(
  db: Database,
  vendor: string,
  now: Date,
  used: number | null,
  remaining: number | null,
  limit: number | null,
  resets: string | null,
) {
  await db.execute(sql`insert into public.vendor_observations(vendor,observed_at,used,remaining,limit_value,resets_at)
 values (${vendor},${now.toISOString()}::timestamptz,${used},${remaining},${limit},${resets}::timestamptz)
 on conflict(vendor) do update set observed_at=excluded.observed_at,used=excluded.used,remaining=excluded.remaining,limit_value=excluded.limit_value,resets_at=excluded.resets_at
 where public.vendor_observations.observed_at <= excluded.observed_at`);
}
/** Callbacks never throw: monitoring must not change an otherwise successful vendor request. */
export async function observeResend(
  db: Database,
  headers: Headers,
  now = new Date(),
): Promise<void> {
  try {
    const quota = parseResendQuota(headers);
    if (quota.daily !== null)
      await record(
        db,
        "resend_daily",
        now,
        quota.daily,
        null,
        null,
        new Date(
          Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + 1),
        ).toISOString(),
      );
    if (quota.monthly !== null)
      await record(
        db,
        "resend",
        now,
        quota.monthly,
        null,
        null,
        new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + 1, 1)).toISOString(),
      );
  } catch {
    /* Own counts remain available if snapshot persistence fails. */
  }
}
export async function observeUnsplash(
  db: Database,
  headers: Headers,
  now = new Date(),
): Promise<void> {
  try {
    const limit = finite(headers.get("x-ratelimit-limit"));
    const remaining = finite(headers.get("x-ratelimit-remaining"));
    if (limit === null || limit <= 0 || remaining === null || remaining > limit) return;
    // Unsplash doesn't supply an exact reset timestamp. Expire this observation after one hour.
    await record(db, "unsplash", now, limit - remaining, remaining, limit, null);
  } catch {
    /* Request success is independent from monitoring storage. */
  }
}
