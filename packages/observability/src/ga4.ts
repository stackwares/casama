/**
 * Google Analytics 4 sink for server product events (D-397, docs/GA4-PLAN.md), over the Measurement
 * Protocol (https://developers.google.com/analytics/devguides/collection/protocol/ga4).
 *
 * Every event goes to one web data stream ("Casama server") with `user_id` set to the Casama user id, so GA4's
 * User-ID identity joins it to the same person's app events. `client_id` is derived from the user id, because
 * the server has no browser or app instance. GA4 has no personless mode, so personless events and the daily
 * rollups are skipped (it would count each workspace as a user, and it measures engagement itself).
 */
import type { CaptureOptions, Ga4Options, ProductAnalytics } from "./analytics.ts";
import { deterministicUuid } from "./analytics.ts";

/** Events GA4 doesn't get: rollups (GA4 has its own engagement numbers). */
export const GA4_SKIPPED_EVENTS = new Set(["usage_daily", "workspace_daily"]);

const MAX_EVENTS_PER_REQUEST = 25;
const MAX_PARAMS = 25;
const MAX_VALUE_LENGTH = 100;
/** GA4 rejects timestamps further back than 72 hours; older events are sent without one. */
const MAX_BACKDATE_MS = 72 * 3600 * 1000;

interface Ga4Event {
  name: string;
  params: Record<string, string | number>;
}

interface Pending {
  clientId: string;
  userId: string;
  timestampMicros?: number;
  events: Ga4Event[];
  userProperties?: Record<string, string>;
}

/** A catalog event's GA4 recommended twin (D-398): `params` copied from the event, `set` added. */
export interface Ga4Twin {
  name: string;
  params: string[];
  set?: Record<string, string | number>;
}

/** Event properties that also become GA4 user properties, so reports can be split by them. */
const USER_PROPERTIES = ["plan"] as const;

/**
 * GA4 param values are strings or numbers: booleans become 1/0, text is cut at 100 characters, objects,
 * arrays, nulls and PostHog's `$` keys are dropped, and at most 25 params are kept (super properties first).
 */
export function ga4Params(properties: Record<string, unknown>): Record<string, string | number> {
  const out: Record<string, string | number> = {};
  let n = 0;
  for (const [key, value] of Object.entries(properties)) {
    if (n >= MAX_PARAMS) break;
    if (key.startsWith("$") || key.length > 40) continue;
    let v: string | number | undefined;
    if (typeof value === "string") v = value.slice(0, MAX_VALUE_LENGTH);
    else if (typeof value === "number" && Number.isFinite(value)) v = value;
    else if (typeof value === "boolean") v = value ? 1 : 0;
    if (v === undefined) continue;
    out[key] = v;
    n++;
  }
  return out;
}

/**
 * The GA4 events for a catalog event: the event itself, plus its recommended twin when the catalog names
 * one. Empty when GA4 doesn't get it.
 */
export function toGa4Events(
  opts: CaptureOptions,
  superProps: Record<string, unknown>,
  twins: Record<string, Ga4Twin> = {},
): Ga4Event[] {
  const event = toGa4Event(opts, superProps);
  if (!event) return [];
  const twin = Object.hasOwn(twins, opts.event) ? twins[opts.event] : undefined;
  if (!twin) return [event];
  const params: Record<string, unknown> = { ...superProps, ...twin.set };
  for (const p of twin.params)
    if (opts.properties?.[p] !== undefined) params[p] = opts.properties[p];
  return [event, { name: twin.name, params: ga4Params(params) }];
}

/** The GA4 event for a catalog event, or null when GA4 doesn't get it. */
export function toGa4Event(
  opts: CaptureOptions,
  superProps: Record<string, unknown>,
): Ga4Event | null {
  if (opts.personless || GA4_SKIPPED_EVENTS.has(opts.event)) return null;
  if (opts.distinctId.startsWith("workspace:")) return null;
  const props: Record<string, unknown> = { ...superProps, ...opts.properties };
  if (opts.orgId) props.workspace_id = opts.orgId;
  if (opts.event === "purchase") {
    // GA4's recommended purchase event: its revenue reports dedupe by transaction_id. No value until plans
    // carry prices in the event (same as PostHog).
    props.currency = "USD";
    if (opts.uuid) props.transaction_id = opts.uuid;
  }
  return { name: opts.event, params: ga4Params(props) };
}

export class Ga4ProductAnalytics implements ProductAnalytics {
  readonly enabled = true;
  private queue: Pending[] = [];
  private timer: ReturnType<typeof setInterval> | undefined;
  private readonly url: string;
  private readonly doFetch: typeof fetch;
  private readonly superProps: Record<string, unknown>;
  private readonly twins: Record<string, Ga4Twin>;
  readonly providers = ["ga4"] as const;

  constructor(opts: Ga4Options & { version?: string; environment?: string }) {
    this.twins = opts.twins ?? {};
    const base = opts.debug
      ? "https://www.google-analytics.com/debug/mp/collect"
      : "https://www.google-analytics.com/mp/collect";
    this.url = `${base}?measurement_id=${encodeURIComponent(opts.measurementId)}&api_secret=${encodeURIComponent(opts.apiSecret)}`;
    this.doFetch = opts.fetch ?? fetch;
    this.superProps = {
      app: "casama",
      environment: opts.environment ?? "development",
      source: "server",
      platform: "server",
      server_version: opts.version ?? "dev",
    };
    const every = opts.flushInterval ?? 10_000;
    if (every > 0) {
      this.timer = setInterval(() => void this.flush(), every);
      this.timer.unref?.();
    }
  }

  capture(opts: CaptureOptions): void {
    if (opts.only && opts.only !== "ga4") return;
    const events = toGa4Events(opts, this.superProps, this.twins);
    if (!events.length) return;
    const userProperties: Record<string, string> = {};
    for (const k of USER_PROPERTIES) {
      const v = opts.properties?.[k];
      if (typeof v === "string" && v) userProperties[k] = v.slice(0, 36);
    }
    const userId = opts.distinctId;
    const clientId = deterministicUuid("ga4", userId);
    const ts = opts.timestamp?.getTime();
    const timestampMicros =
      ts !== undefined && Date.now() - ts < MAX_BACKDATE_MS ? ts * 1000 : undefined;
    // Events share a request only when they share the person and the timestamp (it is per request).
    const last = this.queue.at(-1);
    if (
      last &&
      last.userId === userId &&
      last.timestampMicros === timestampMicros &&
      last.events.length + events.length <= MAX_EVENTS_PER_REQUEST
    ) {
      last.events.push(...events);
      if (Object.keys(userProperties).length)
        last.userProperties = { ...last.userProperties, ...userProperties };
    } else {
      this.queue.push({
        clientId,
        userId,
        timestampMicros,
        events,
        ...(Object.keys(userProperties).length ? { userProperties } : {}),
      });
    }
    if (this.queue.length >= 20) void this.flush();
  }

  async flush(): Promise<void> {
    const batch = this.queue;
    this.queue = [];
    await Promise.allSettled(
      batch.map(async (p) => {
        const res = await this.doFetch(this.url, {
          method: "POST",
          headers: { "content-type": "application/json" },
          body: JSON.stringify({
            client_id: p.clientId,
            user_id: p.userId,
            ...(p.timestampMicros ? { timestamp_micros: p.timestampMicros } : {}),
            non_personalized_ads: true,
            ...(p.userProperties
              ? {
                  user_properties: Object.fromEntries(
                    Object.entries(p.userProperties).map(([k, value]) => [k, { value }]),
                  ),
                }
              : {}),
            events: p.events,
          }),
        });
        if (!res.ok) throw new Error(`GA4 answered ${res.status}`);
      }),
    );
  }

  async close(): Promise<void> {
    if (this.timer) clearInterval(this.timer);
    await this.flush();
  }
}
