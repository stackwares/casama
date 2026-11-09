import type { Database } from "@kasama/db";
import { sql } from "drizzle-orm";
import { ApiError } from "../api/errors.ts";

/** The workspace's effective limits (plan limits plus owner overrides), from its entitlement. */
export async function orgLimits(db: Database, orgId: string) {
  const [e] = await db.execute<{ limits: Record<string, unknown> }>(
    sql`select limits from public.entitlements where org_id = ${orgId}::uuid order by created_at desc limit 1`,
  );
  return e?.limits ?? {};
}

const COUNTS = {
  max_bots: (orgId: string) =>
    sql`select count(*)::int as n from public.bots where org_id = ${orgId}::uuid`,
  max_computers: (orgId: string) =>
    sql`select count(*)::int as n from public.computers where org_id = ${orgId}::uuid and provider <> 'local'`,
} as const;

/** Paywall check before creating a bot or computer (D-070). No limit set = no check. */
export async function enforceLimit(db: Database, orgId: string, key: keyof typeof COUNTS) {
  const limit = (await orgLimits(db, orgId))[key];
  if (typeof limit !== "number") return;
  const [r] = await db.execute<{ n: number }>(COUNTS[key](orgId));
  if ((r?.n ?? 0) >= limit) {
    const what = key === "max_bots" ? "bots" : "computers";
    throw new ApiError(
      402,
      "plan_limit",
      `Your plan allows ${limit} ${what}. Upgrade in Billing to add more.`,
    );
  }
}
