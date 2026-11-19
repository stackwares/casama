/**
 * Sets up the Casama GA4 property for product analytics and funnels (D-398, docs/GA4-PLAN.md).
 * Idempotent: lists what exists first, creates only what's missing, never deletes or archives.
 *   node scripts/ga4-setup.mts            dry run (default): prints the plan, changes nothing
 *   node scripts/ga4-setup.mts --apply    creates the missing pieces and sets data retention
 *   --property <id>                       another property (default GA4_PROPERTY_ID or 563408057)
 *
 * What it sets up:
 *   - event-scoped custom dimensions for the catalog's funnel and money properties (at most 45 of
 *     GA4's free 50, so there's headroom); user-scoped ones for plan, sign-up platform, distribution
 *     and environment
 *   - custom metrics for the numbers worth summing (duration_s, minutes_since_signup)
 *   - key events: sign_up, signed_up, onboarding_complete, first_value, purchase, start_click,
 *     download_click
 *   - event data retention of 14 months, reset on new activity
 * It reports, and never changes, the data streams, Google Signals and any Google Ads links.
 *
 * Credentials: see scripts/ga4-lib.mts. For --apply the account needs Editor on the property.
 */
import { ADMIN, type Api, accessToken, api, listAll, loadCatalog, propertyId } from "./ga4-lib.mts";

export const MAX_EVENT_DIMENSIONS = 45;
export const MAX_USER_DIMENSIONS = 25;
export const MAX_METRICS = 5;

/** Params the casama.ai Worker sends with website events (not in the app catalog). */
export const WEBSITE_PARAMS = ["visit_source", "item_type"];

/** Event-scoped dimensions in priority order: super properties, then funnel and money props. */
export const EVENT_DIMENSION_PRIORITY = [
  "app",
  "environment",
  "source",
  "platform",
  "distribution",
  "server_kind",
  "plan",
  "interval",
  "default_plan",
  "default_period",
  "store",
  "kind",
  "method",
  "step",
  "step_index",
  "feature",
  "milestone",
  "provider",
  "trigger_kind",
  "paywall_kind",
  "surface",
  "screen",
  "error_code",
  "outcome",
  "reason",
  "via",
  "role",
  "path",
  "status",
  "channel",
  "action",
  "choice",
  "is_sign_up",
  "is_new_user",
  "template_id",
  "skill_id",
  "app_id",
  "conversation_kind",
  "ended_by",
  "mode",
  "result",
  "decision",
  "visit_source",
  "item_type",
];
/** Never registered: ids with one value per workspace or person would only fill GA4's (other) row. */
export const NEVER_DIMENSIONS = new Set(["workspace_id", "user_id", "transaction_id"]);

export const USER_DIMENSIONS = ["plan", "signup_platform", "distribution", "environment"];

export const METRICS: { parameterName: string; measurementUnit: "STANDARD" | "SECONDS" }[] = [
  { parameterName: "duration_s", measurementUnit: "SECONDS" },
  { parameterName: "minutes_since_signup", measurementUnit: "STANDARD" },
];

export const KEY_EVENTS = [
  "sign_up",
  "signed_up",
  "onboarding_complete",
  "first_value",
  "purchase",
  "start_click",
  "download_click",
];

export const RETENTION = {
  eventDataRetention: "FOURTEEN_MONTHS",
  resetUserDataOnNewActivity: true,
};

export interface CustomDimension {
  parameterName: string;
  displayName: string;
  scope: "EVENT" | "USER";
  description?: string;
}
export interface CustomMetric {
  parameterName: string;
  displayName: string;
  scope: "EVENT";
  measurementUnit: string;
  description?: string;
}

/** The event-scoped params we want, which known ones didn't fit, and which listed ones aren't known. */
export function wantedEventDimensions(
  catalog = loadCatalog(),
  max = MAX_EVENT_DIMENSIONS,
): { wanted: string[]; leftOut: string[]; unknown: string[] } {
  const known = new Set<string>([...catalog.super_properties, ...WEBSITE_PARAMS]);
  for (const e of catalog.events) for (const k of Object.keys(e.properties ?? {})) known.add(k);
  const unknown = EVENT_DIMENSION_PRIORITY.filter((p) => !known.has(p));
  const ordered = EVENT_DIMENSION_PRIORITY.filter((p) => known.has(p) && !NEVER_DIMENSIONS.has(p));
  // Everything else the catalog sends that isn't numeric-looking or an id, after the priority list.
  const rest = [...known]
    .filter((p) => !ordered.includes(p) && !NEVER_DIMENSIONS.has(p) && !p.includes("*"))
    .sort();
  return { wanted: ordered.slice(0, max), leftOut: [...ordered.slice(max), ...rest], unknown };
}

export function dimension(parameterName: string, scope: "EVENT" | "USER"): CustomDimension {
  return {
    parameterName,
    displayName: scope === "USER" ? `user_${parameterName}` : parameterName,
    scope,
    description: "Casama analytics catalog (scripts/ga4-setup.mts)",
  };
}

export interface Plan {
  dimensions: CustomDimension[];
  metrics: CustomMetric[];
  keyEvents: string[];
  retention: typeof RETENTION | null;
}

/** What to create, given what exists. Matching is by scope + parameter name (or event name). */
export function plan(
  existing: {
    dimensions: Pick<CustomDimension, "parameterName" | "scope">[];
    metrics: Pick<CustomMetric, "parameterName">[];
    keyEvents: { eventName: string }[];
    retention?: { eventDataRetention?: string; resetUserDataOnNewActivity?: boolean };
  },
  wantedEvent: string[],
): Plan {
  const have = new Set(existing.dimensions.map((d) => `${d.scope}:${d.parameterName}`));
  const eventSlots = Math.max(
    0,
    MAX_EVENT_DIMENSIONS - existing.dimensions.filter((d) => d.scope === "EVENT").length,
  );
  const userSlots = Math.max(
    0,
    MAX_USER_DIMENSIONS - existing.dimensions.filter((d) => d.scope === "USER").length,
  );
  const dimensions = [
    ...wantedEvent
      .filter((p) => !have.has(`EVENT:${p}`))
      .slice(0, eventSlots)
      .map((p) => dimension(p, "EVENT")),
    ...USER_DIMENSIONS.filter((p) => !have.has(`USER:${p}`))
      .slice(0, userSlots)
      .map((p) => dimension(p, "USER")),
  ];
  const haveMetrics = new Set(existing.metrics.map((m) => m.parameterName));
  const metricSlots = Math.max(0, MAX_METRICS - existing.metrics.length);
  const metrics = METRICS.filter((m) => !haveMetrics.has(m.parameterName))
    .slice(0, metricSlots)
    .map((m) => ({
      parameterName: m.parameterName,
      displayName: m.parameterName,
      scope: "EVENT" as const,
      measurementUnit: m.measurementUnit,
      description: "Casama analytics catalog (scripts/ga4-setup.mts)",
    }));
  const haveKeys = new Set(existing.keyEvents.map((k) => k.eventName));
  const keyEvents = KEY_EVENTS.filter((k) => !haveKeys.has(k));
  const r = existing.retention;
  const retention =
    r?.eventDataRetention === RETENTION.eventDataRetention &&
    r?.resetUserDataOnNewActivity === RETENTION.resetUserDataOnNewActivity
      ? null
      : RETENTION;
  return { dimensions, metrics, keyEvents, retention };
}

export async function readExisting(call: Api, property: string) {
  const base = `${ADMIN}/v1beta/properties/${property}`;
  const [dimensions, metrics, keyEvents, retention, streams, adsLinks] = await Promise.all([
    listAll<CustomDimension>(call, `${base}/customDimensions`, "customDimensions"),
    listAll<CustomMetric>(call, `${base}/customMetrics`, "customMetrics"),
    listAll<{ eventName: string }>(call, `${base}/keyEvents`, "keyEvents"),
    call<{ eventDataRetention?: string; resetUserDataOnNewActivity?: boolean }>(
      "GET",
      `${base}/dataRetentionSettings`,
    ),
    listAll<{ displayName: string; type: string; webStreamData?: { measurementId: string } }>(
      call,
      `${base}/dataStreams`,
      "dataStreams",
    ),
    listAll<{ customerId: string }>(call, `${base}/googleAdsLinks`, "googleAdsLinks"),
  ]);
  const signals = await call<{ state?: string }>(
    "GET",
    `${ADMIN}/v1alpha/properties/${property}/googleSignalsSettings`,
  ).catch((e: Error) => ({ state: `unknown (${e.message.slice(0, 80)})` }));
  return { dimensions, metrics, keyEvents, retention, streams, adsLinks, signals };
}

export async function applyPlan(call: Api, property: string, p: Plan): Promise<void> {
  const base = `${ADMIN}/v1beta/properties/${property}`;
  for (const d of p.dimensions) await call("POST", `${base}/customDimensions`, d);
  for (const m of p.metrics) await call("POST", `${base}/customMetrics`, m);
  for (const eventName of p.keyEvents)
    await call("POST", `${base}/keyEvents`, { eventName, countingMethod: "ONCE_PER_EVENT" });
  if (p.retention)
    await call(
      "PATCH",
      `${base}/dataRetentionSettings?updateMask=eventDataRetention,resetUserDataOnNewActivity`,
      p.retention,
    );
}

async function main(argv: string[]) {
  const apply = argv.includes("--apply");
  const property = propertyId(argv);
  const { wanted, leftOut, unknown } = wantedEventDimensions();
  const call = api(await accessToken());
  const existing = await readExisting(call, property);
  const p = plan(existing, wanted);

  console.log(
    `GA4 property ${property}${apply ? "" : " (dry run: nothing changes; --apply to write)"}\n`,
  );
  console.log("Data streams:");
  for (const s of existing.streams)
    console.log(
      `  - ${s.displayName} (${s.type}${s.webStreamData ? `, ${s.webStreamData.measurementId}` : ""})`,
    );
  console.log(
    `Google Signals: ${existing.signals.state ?? "unknown"} (left as is; Casama keeps it off)`,
  );
  console.log(
    `Google Ads links: ${existing.adsLinks.length ? existing.adsLinks.map((l) => l.customerId).join(", ") : "none"} (left as is)\n`,
  );
  console.log(
    `Custom dimensions: ${existing.dimensions.length} exist; creating ${p.dimensions.length}:`,
  );
  for (const d of p.dimensions) console.log(`  + ${d.scope.toLowerCase()}: ${d.parameterName}`);
  if (leftOut.length)
    console.log(
      `  Not registered (over the cap of ${MAX_EVENT_DIMENSIONS}): ${leftOut.join(", ")}`,
    );
  if (unknown.length)
    console.log(`  Listed but not in the catalog (skipped): ${unknown.join(", ")}`);
  console.log(
    `Custom metrics: creating ${p.metrics.length}: ${p.metrics.map((m) => m.parameterName).join(", ") || "-"}`,
  );
  console.log(`Key events: creating ${p.keyEvents.length}: ${p.keyEvents.join(", ") || "-"}`);
  console.log(
    `Data retention: ${existing.retention.eventDataRetention ?? "?"}${p.retention ? ` → ${RETENTION.eventDataRetention}, reset on new activity` : " (already right)"}`,
  );

  if (!apply) return;
  await applyPlan(call, property, p);
  console.log("\nApplied.");
}

if (import.meta.url === `file://${process.argv[1]}`) {
  main(process.argv.slice(2)).catch((e) => {
    console.error(e instanceof Error ? e.message : e);
    process.exit(1);
  });
}
