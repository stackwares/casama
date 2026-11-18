/**
 * Casama's funnels, computed by GA4 (D-398): the Data API's runFunnelReport (v1alpha), one
 * definition per funnel below, so the numbers are reproducible instead of hand-built explorations.
 *   node scripts/ga4-funnels.mts                       every funnel, last 28 days, production only
 *   node scripts/ga4-funnels.mts --funnel F2           one funnel
 *   node scripts/ga4-funnels.mts --days 7              another window
 *   node scripts/ga4-funnels.mts --breakdown platform  split each step (platform | environment |
 *                                                      or any GA4 dimension api name)
 *   node scripts/ga4-funnels.mts --all-environments    don't filter to environment=production
 *   node scripts/ga4-funnels.mts --json                raw rows as JSON
 *   node scripts/ga4-funnels.mts --list                print the definitions and exit (no API call)
 * Credentials: see scripts/ga4-lib.mts (Viewer on the property is enough).
 *
 * App and server events join by user (the Casama user id is GA4's user_id). Website steps come
 * from casama.ai's Worker with a visitor id that lasts one day and can't be linked to an account,
 * so W1 is an open funnel: each step counts whoever reached it, and the website → sign-up
 * step reads as "how many signed up" next to "how many clicked", not as one person's path.
 */
import { accessToken, api, DATA, flag, loadCatalog, propertyId } from "./ga4-lib.mts";

/** GA4 events that aren't in the catalog: recommended twins and website events (D-398). */
export const EXTRA_EVENTS = [
  "sign_up",
  "login",
  "tutorial_begin",
  "tutorial_complete",
  "begin_checkout",
  "share",
  "join_group",
  "page_view",
  "start_click",
  "download_click",
  "qr_open",
  "invite_open",
  "gallery_open",
  "film_play",
  "copy_install",
  "plan_click",
];

/** Events sent from the website Worker: they carry no `environment` param. */
export const WEBSITE_EVENTS = new Set([
  "page_view",
  "start_click",
  "download_click",
  "qr_open",
  "invite_open",
  "gallery_open",
  "film_play",
  "copy_install",
  "plan_click",
]);

export interface FunnelStep {
  name: string;
  /** Any of these events completes the step. */
  events: string[];
}
export interface Funnel {
  id: string;
  title: string;
  open: boolean;
  steps: FunnelStep[];
  note?: string;
}

export const FUNNELS: Funnel[] = [
  {
    id: "W1",
    title: "Website to active user",
    open: true,
    note: "Website steps are visitor-day scoped and can't join app users; read the steps side by side.",
    steps: [
      { name: "Visited casama.ai", events: ["page_view"] },
      { name: "Clicked Start or a download", events: ["start_click", "download_click"] },
      { name: "Signed up", events: ["sign_up"] },
      { name: "First value", events: ["first_value"] },
    ],
  },
  {
    id: "F1",
    title: "Sign-in",
    open: false,
    steps: [
      { name: "Started sign-in", events: ["sign_in_started"] },
      { name: "Signed in", events: ["sign_in_completed"] },
      { name: "New account", events: ["signed_up"] },
    ],
  },
  {
    id: "F2",
    title: "Onboarding",
    open: false,
    steps: [
      { name: "Signed up", events: ["signed_up"] },
      { name: "Onboarding began", events: ["onboarding_begin"] },
      { name: "Onboarding complete", events: ["onboarding_complete"] },
      { name: "First value", events: ["first_value"] },
    ],
  },
  {
    id: "F3",
    title: "Activation",
    open: false,
    steps: [
      { name: "First value", events: ["first_value"] },
      { name: "Created a bot", events: ["bot_created"] },
      { name: "Reached a milestone", events: ["milestone_reached"] },
    ],
  },
  {
    id: "F4",
    title: "Connections",
    open: false,
    steps: [
      { name: "Started connecting", events: ["connection_started"] },
      { name: "Connected", events: ["connection_added"] },
    ],
  },
  {
    id: "F5",
    title: "Computers",
    open: false,
    steps: [
      { name: "Asked for a computer", events: ["computer_start_requested"] },
      { name: "Computer ready", events: ["computer_ready"] },
    ],
  },
  {
    id: "F6",
    title: "Paywall to purchase",
    open: false,
    steps: [
      { name: "Saw the paywall", events: ["paywall_view"] },
      { name: "Started a purchase", events: ["purchase_started", "begin_checkout"] },
      { name: "Purchased", events: ["purchase"] },
    ],
  },
  {
    id: "F6b",
    title: "Limit to purchase",
    open: false,
    steps: [
      { name: "Hit a limit", events: ["limit_reached"] },
      { name: "Saw the paywall", events: ["paywall_view"] },
      { name: "Purchased", events: ["purchase"] },
    ],
  },
  {
    id: "F7",
    title: "Team invites",
    open: false,
    steps: [
      { name: "Invite created", events: ["invite_created"] },
      { name: "Member joined", events: ["member_joined"] },
    ],
  },
  {
    id: "F8",
    title: "Calls",
    open: false,
    steps: [
      { name: "Call started", events: ["call_started"] },
      { name: "Call ended", events: ["call_ended"] },
    ],
  },
];

function eventFilter(event: string, production: boolean) {
  const filter: Record<string, unknown> = { eventName: event };
  if (production && !WEBSITE_EVENTS.has(event)) {
    filter.funnelParameterFilterExpression = {
      funnelParameterFilter: {
        eventParameterName: "environment",
        stringFilter: { matchType: "EXACT", value: "production" },
      },
    };
  }
  return { funnelEventFilter: filter };
}

/** The runFunnelReport request body for one funnel. */
export function funnelRequest(
  f: Funnel,
  opts: { days?: number; production?: boolean; breakdown?: string } = {},
) {
  const production = opts.production ?? true;
  const body: Record<string, unknown> = {
    dateRanges: [{ startDate: `${opts.days ?? 28}daysAgo`, endDate: "today" }],
    funnel: {
      isOpenFunnel: f.open,
      steps: f.steps.map((s) => ({
        name: s.name,
        filterExpression:
          s.events.length === 1
            ? eventFilter(s.events[0]!, production)
            : { orGroup: { expressions: s.events.map((e) => eventFilter(e, production)) } },
      })),
    },
  };
  if (opts.breakdown) {
    const name = ["environment", "distribution", "server_kind", "source"].includes(opts.breakdown)
      ? `customEvent:${opts.breakdown}`
      : opts.breakdown;
    body.funnelBreakdown = { breakdownDimension: { name }, limit: 10 };
  }
  return body;
}

interface FunnelTable {
  dimensionHeaders?: { name: string }[];
  metricHeaders?: { name: string }[];
  rows?: { dimensionValues: { value: string }[]; metricValues: { value: string }[] }[];
}

/** Readable rows from the funnelTable: step (and breakdown), users, completion %, abandon %. */
export function tableRows(t: FunnelTable): string[][] {
  const dims = (t.dimensionHeaders ?? []).map((h) => h.name);
  const mets = (t.metricHeaders ?? []).map((h) => h.name);
  const m = (row: { metricValues: { value: string }[] }, name: string) =>
    row.metricValues[mets.indexOf(name)]?.value ?? "";
  const pct = (v: string) => (v === "" ? "" : `${(Number(v) * 100).toFixed(1)}%`);
  return (t.rows ?? []).map((r) => [
    ...dims.map((_, i) => r.dimensionValues[i]?.value ?? ""),
    m(r, "activeUsers"),
    pct(m(r, "funnelStepCompletionRate")),
    pct(m(r, "funnelStepAbandonmentRate")),
  ]);
}

function printTable(head: string[], rows: string[][]) {
  const w = head.map((h, i) => Math.max(h.length, ...rows.map((r) => (r[i] ?? "").length)));
  const line = (r: string[]) => r.map((c, i) => (c ?? "").padEnd(w[i]!)).join("  ");
  console.log(line(head));
  console.log(w.map((n) => "-".repeat(n)).join("  "));
  for (const r of rows) console.log(line(r));
}

async function main(argv: string[]) {
  const only = flag(argv, "--funnel");
  const funnels = only ? FUNNELS.filter((f) => f.id.toLowerCase() === only.toLowerCase()) : FUNNELS;
  if (!funnels.length)
    throw new Error(`No funnel "${only}"; known: ${FUNNELS.map((f) => f.id).join(", ")}`);
  if (argv.includes("--list")) {
    for (const f of funnels)
      console.log(
        `${f.id} ${f.title}${f.open ? " (open)" : ""}: ${f.steps.map((s) => s.events.join("|")).join(" → ")}`,
      );
    return;
  }
  const property = propertyId(argv);
  const days = Number(flag(argv, "--days") ?? 28);
  const breakdown = flag(argv, "--breakdown");
  const production = !argv.includes("--all-environments");
  const json = argv.includes("--json");
  const call = api(await accessToken());
  const out: Record<string, unknown> = {};
  for (const f of funnels) {
    const res = await call<{ funnelTable?: FunnelTable }>(
      "POST",
      `${DATA}/v1alpha/properties/${property}:runFunnelReport`,
      funnelRequest(f, { days, production, breakdown }),
    );
    if (json) {
      out[f.id] = res.funnelTable ?? {};
      continue;
    }
    console.log(
      `\n${f.id} ${f.title}${f.open ? " (open funnel)" : ""}, last ${days} days${production ? ", production" : ""}`,
    );
    if (f.note) console.log(`  ${f.note}`);
    const t = res.funnelTable ?? {};
    const head = [
      ...(t.dimensionHeaders ?? []).map((h) => h.name),
      "users",
      "completion",
      "abandoned",
    ];
    printTable(head, tableRows(t));
  }
  if (json) console.log(JSON.stringify(out, null, 2));
}

// Catalog check at import time is cheap and keeps the definitions honest when run by hand.
export function unknownSteps(catalog = loadCatalog()): string[] {
  const known = new Set([...catalog.events.map((e) => e.name), ...EXTRA_EVENTS]);
  return FUNNELS.flatMap((f) => f.steps.flatMap((s) => s.events)).filter((e) => !known.has(e));
}

if (import.meta.url === `file://${process.argv[1]}`) {
  main(process.argv.slice(2)).catch((e) => {
    console.error(e instanceof Error ? e.message : e);
    process.exit(1);
  });
}
