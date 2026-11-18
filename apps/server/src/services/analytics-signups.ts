/**
 * `signed_up` events (D-208, ANALYTICS-PLAN §4.3, §6.1). Sign-up is a database trigger the API never
 * sees, so the worker sweeps profiles that have not been reported yet. It reads the sign-up method
 * through a security-definer function (the worker never reads auth.* itself, D-095).
 * Only the provider name leaves (email, google, apple…): never an address or a name.
 */
import type { Database } from "@casama/db";
import {
  deterministicUuid,
  getProductAnalytics,
  type ProductAnalytics,
} from "@casama/observability";
import { sql } from "drizzle-orm";

export async function sweepSignups(db: Database, analytics?: ProductAnalytics): Promise<number> {
  const a = analytics ?? getProductAnalytics();
  // With analytics off nothing is sent and nobody is marked, so turning it on later starts from then.
  if (!a.enabled) return 0;
  const rows = await db.execute<{ user_id: string; created_at: Date | string; provider: string }>(
    sql`select user_id, created_at, provider from public.worker_new_signups(200)`,
  );
  if (rows.length === 0) return 0;
  for (const r of rows) {
    const at = new Date(r.created_at);
    a.capture({
      event: "signed_up",
      distinctId: r.user_id,
      uuid: deterministicUuid("signed_up", r.user_id),
      timestamp: at,
      properties: { method: r.provider },
      setOnce: { signup_method: r.provider, signup_at: at.toISOString() },
    });
  }
  await a.flush();
  const ids = rows.map((r) => r.user_id);
  await db.execute(
    sql`select public.worker_mark_signups_sent(array(select jsonb_array_elements_text(${JSON.stringify(ids)}::text::jsonb))::uuid[])`,
  );
  return rows.length;
}
