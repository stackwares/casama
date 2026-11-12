/**
 * Product analytics milestones (D-208, ANALYTICS-PLAN §6.12): once-only activation markers per person.
 * The row in analytics_milestones is the guard, so a milestone fires once however often the code runs,
 * and it doubles as first-party activation data. Nothing is sent for people who opted out.
 */
import type { Database } from "@casama/db";
import {
  captureError,
  deterministicUuid,
  getProductAnalytics,
  type ProductAnalytics,
} from "@casama/observability";
import { sql } from "drizzle-orm";

/** Triggers that mean a person did the work (everything else is automation). */
const INTERACTIVE = new Set(["chat", "mention", "voice"]);

/**
 * Records a milestone for a person and, only the first time and if analytics is on and they have not
 * opted out, sends it. Returns true when this call reached it first.
 */
export async function reachMilestone(
  db: Database,
  userId: string,
  milestone: string,
  opts: {
    orgId?: string;
    /** Event name when it is not `milestone_reached` (portfolio names such as `first_value`). */
    event?: string;
    properties?: Record<string, string | number | boolean>;
    setOnce?: Record<string, string | number | boolean>;
    analytics?: ProductAnalytics;
  } = {},
): Promise<boolean> {
  const rows = await db.execute<{
    inserted: number;
    created_at: Date | string;
    opt_out: boolean;
  }>(sql`
    with ins as (
      insert into public.analytics_milestones (user_id, milestone)
      values (${userId}::uuid, ${milestone}) on conflict do nothing returning 1
    )
    select (select count(*) from ins)::int as inserted, p.created_at,
      (p.analytics_opt_out or coalesce((select o.analytics_opt_out from public.organizations o
        where o.id = ${opts.orgId ?? null}::uuid), false)) as opt_out
    from public.profiles p where p.user_id = ${userId}::uuid`);
  const row = rows[0];
  if (!row || row.inserted === 0) return false;
  const analytics = opts.analytics ?? getProductAnalytics();
  if (!analytics.enabled || row.opt_out) return true;
  const minutes = Math.max(
    0,
    Math.round((Date.now() - new Date(row.created_at).getTime()) / 60_000),
  );
  analytics.capture({
    event: opts.event ?? "milestone_reached",
    distinctId: userId,
    orgId: opts.orgId,
    uuid: deterministicUuid("milestone", milestone, userId),
    properties: {
      ...(opts.event ? {} : { milestone }),
      minutes_since_signup: minutes,
      ...opts.properties,
    },
    setOnce: { [`${milestone}_at`]: new Date().toISOString(), ...opts.setOnce },
  });
  return true;
}

/** Called when a run completes: a person's first finished run is their first value (F2, F3). */
export async function runCompletedMilestones(
  db: Database,
  run: { userId: string | null | undefined; orgId: string; trigger: string },
  analytics?: ProductAnalytics,
): Promise<void> {
  if (!run.userId || !INTERACTIVE.has(run.trigger)) return;
  const a = analytics ?? getProductAnalytics();
  if (
    await reachMilestone(db, run.userId, "first_run_completed", { orgId: run.orgId, analytics: a })
  ) {
    await reachMilestone(db, run.userId, "first_value", {
      orgId: run.orgId,
      event: "first_value",
      properties: { kind: run.trigger === "voice" ? "voice" : "chat" },
      setOnce: { first_value_kind: run.trigger === "voice" ? "voice" : "chat" },
      analytics: a,
    });
  }
}

// --- live events -------------------------------------------------------------------------------

const consentCache = new Map<string, { at: number; allowed: boolean }>();
const CONSENT_TTL_MS = 60_000;

/** Forgets cached opt-outs (tests, and right after a person or admin changes a switch). */
export function clearAnalyticsConsentCache() {
  consentCache.clear();
}

/** False when the person or the workspace opted out of usage analytics (cached for a minute). */
async function analyticsAllowed(
  db: Database,
  userId: string | null,
  orgId: string | null,
): Promise<boolean> {
  const key = `${userId ?? ""}|${orgId ?? ""}`;
  const hit = consentCache.get(key);
  if (hit && Date.now() - hit.at < CONSENT_TTL_MS) return hit.allowed;
  const rows = await db.execute<{ allowed: boolean }>(sql`
    select not (
      coalesce((select analytics_opt_out from public.profiles where user_id = ${userId}::uuid), false)
      or coalesce((select analytics_opt_out from public.organizations where id = ${orgId}::uuid), false)
    ) as allowed`);
  const allowed = rows[0]?.allowed ?? true;
  consentCache.set(key, { at: Date.now(), allowed });
  return allowed;
}

/**
 * Sends one live product event after the database change is committed. Never throws and never
 * blocks the caller: analytics must not break a purchase, a bot or a sign-in. Attributed to the
 * person when known, otherwise to the workspace (personless). Only ids, enums, counts and booleans:
 * callers must not pass names, text or URLs.
 */
export function track(
  db: Database,
  e: {
    event: string;
    userId?: string | null;
    orgId?: string | null;
    properties?: Record<string, string | number | boolean | null>;
    /** Deterministic id for once-only events (a retry then merges instead of counting twice). */
    uuid?: string;
    setOnce?: Record<string, string | number | boolean>;
  },
  analytics?: ProductAnalytics,
): void {
  const a = analytics ?? getProductAnalytics();
  if (!a.enabled) return;
  void (async () => {
    const userId = e.userId ?? null;
    const orgId = e.orgId ?? null;
    if (!userId && !orgId) return;
    if (!(await analyticsAllowed(db, userId, orgId))) return;
    a.capture({
      event: e.event,
      distinctId: userId ?? `workspace:${orgId}`,
      orgId: orgId ?? undefined,
      personless: !userId,
      uuid: e.uuid,
      properties: Object.fromEntries(
        Object.entries(e.properties ?? {}).filter(([, v]) => v !== null),
      ),
      setOnce: e.setOnce,
    });
  })().catch((err) => captureError(err, { step: "analytics-track", event: e.event }));
}
