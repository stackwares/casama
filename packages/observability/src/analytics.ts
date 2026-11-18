/**
 * Product analytics for Casama Cloud (D-208, ANALYTICS-PLAN §4.3; GA4 since D-397, docs/GA4-PLAN.md).
 * Captures typed catalog events to every configured provider when PRODUCT_ANALYTICS=on:
 * PostHog when POSTHOG_API_KEY is set, Google Analytics 4 (Measurement Protocol) when GA4_MEASUREMENT_ID
 * and GA4_API_SECRET are set. ANALYTICS_PROVIDERS (e.g. "ga4" or "posthog,ga4") narrows that list; unset
 * means every provider that has its keys. Off by default on self-hosted instances.
 * Callers respect user opt-out and workspace privacy settings before capturing.
 */
import { createHash } from "node:crypto";
import { PostHog } from "posthog-node";
import { Ga4ProductAnalytics } from "./ga4.ts";

export interface AnalyticsEvent {
  event: string;
  properties?: Record<string, unknown>;
}

export interface CaptureOptions {
  event: string;
  distinctId: string;
  properties?: Record<string, unknown>;
  orgId?: string;
  personless?: boolean;
  uuid?: string;
  timestamp?: Date;
  setOnce?: Record<string, string | number | boolean>;
  /** Only this provider gets the event (the desktop GA4 relay: PostHog already has it from the app). */
  only?: "posthog" | "ga4";
}

export interface ProductAnalytics {
  /** False for the null implementation: callers skip work (and never mark anything as reported). */
  readonly enabled: boolean;
  /** The providers this instance sends to (absent on test fakes). */
  readonly providers?: readonly AnalyticsProvider[];
  capture(opts: CaptureOptions): void;
  flush(): Promise<void>;
  close(): Promise<void>;
}

export type AnalyticsProvider = "posthog" | "ga4";

export interface Ga4Options {
  measurementId: string;
  apiSecret: string;
  /** Send to GA4's validation endpoint instead (nothing is recorded). */
  debug?: boolean;
  fetch?: typeof fetch;
  /** Milliseconds between sends; 0 sends only on flush. */
  flushInterval?: number;
  /** Catalog event → GA4 recommended twin (D-398); the server passes GA4_TWINS from @casama/contracts. */
  twins?: Record<string, { name: string; params: string[]; set?: Record<string, string | number> }>;
}

export interface AnalyticsOptions {
  enabled?: boolean;
  apiKey?: string;
  host?: string;
  version?: string;
  environment?: string;
  /** ANALYTICS_PROVIDERS: comma list; unset or empty = every provider whose keys are set. */
  providers?: string;
  ga4?: Partial<Ga4Options>;
}

/** Parses ANALYTICS_PROVIDERS. Null means "every provider that has its keys". Unknown names are ignored. */
export function parseAnalyticsProviders(value: string | undefined): Set<AnalyticsProvider> | null {
  const names = (value ?? "")
    .split(",")
    .map((s) => s.trim().toLowerCase())
    .filter(Boolean);
  if (!names.length) return null;
  const known = new Set<AnalyticsProvider>();
  for (const n of names) {
    if (n === "posthog" || n === "ga4") known.add(n);
    if (n === "none" || n === "off") return new Set();
  }
  return known;
}

class PostHogProductAnalytics implements ProductAnalytics {
  readonly enabled = true;
  readonly providers = ["posthog"] as const;
  private client: PostHog;
  private version: string;
  private environment: string;

  constructor(opts: AnalyticsOptions) {
    this.version = opts.version ?? "dev";
    this.environment = opts.environment ?? "development";
    this.client = new PostHog(opts.apiKey!, {
      host: opts.host ?? "https://us.i.posthog.com",
      flushAt: 20,
      flushInterval: 10_000,
      disableGeoip: true,
    });
  }

  capture(opts: CaptureOptions): void {
    if (opts.only && opts.only !== "posthog") return;
    const properties: Record<string, unknown> = {
      ...opts.properties,
      app: "casama",
      environment: this.environment,
      source: "server",
      platform: "server",
      server_version: this.version,
    };

    if (opts.orgId) {
      properties.workspace_id = opts.orgId;
    }

    if (opts.personless) {
      properties.$process_person_profile = false;
    }

    if (opts.setOnce) {
      properties.$set_once = opts.setOnce;
    }

    this.client.capture({
      distinctId: opts.distinctId,
      event: opts.event,
      properties,
      uuid: opts.uuid,
      timestamp: opts.timestamp,
    });
  }

  async flush(): Promise<void> {
    await this.client.flush();
  }

  async close(): Promise<void> {
    await this.client.shutdown(2000);
  }
}

class NullProductAnalytics implements ProductAnalytics {
  readonly enabled = false;
  capture(): void {}
  async flush(): Promise<void> {}
  async close(): Promise<void> {}
}

/** Sends each event to several providers; enabled when any of them is. */
class FanOutProductAnalytics implements ProductAnalytics {
  readonly enabled = true;
  readonly sinks: ProductAnalytics[];
  readonly providers: readonly AnalyticsProvider[];
  constructor(sinks: ProductAnalytics[]) {
    this.sinks = sinks;
    this.providers = sinks.flatMap((s) => s.providers ?? []);
  }
  capture(opts: CaptureOptions): void {
    for (const s of this.sinks) {
      try {
        s.capture(opts);
      } catch {
        // One provider failing never stops the others or the caller.
      }
    }
  }
  async flush(): Promise<void> {
    await Promise.allSettled(this.sinks.map((s) => s.flush()));
  }
  async close(): Promise<void> {
    await Promise.allSettled(this.sinks.map((s) => s.close()));
  }
}

let analyticsInstance: ProductAnalytics | null = null;

export function initProductAnalytics(opts: AnalyticsOptions): ProductAnalytics {
  const isEnabled = opts.enabled ?? process.env.PRODUCT_ANALYTICS === "on";
  const apiKey = opts.apiKey ?? process.env.POSTHOG_API_KEY;
  const wanted = parseAnalyticsProviders(opts.providers ?? process.env.ANALYTICS_PROVIDERS);
  const want = (p: AnalyticsProvider) => wanted === null || wanted.has(p);
  const environment = opts.environment ?? process.env.ANALYTICS_ENVIRONMENT ?? process.env.NODE_ENV;
  const measurementId = opts.ga4?.measurementId ?? process.env.GA4_MEASUREMENT_ID;
  const apiSecret = opts.ga4?.apiSecret ?? process.env.GA4_API_SECRET;

  const sinks: ProductAnalytics[] = [];
  if (isEnabled && apiKey && want("posthog")) {
    sinks.push(
      new PostHogProductAnalytics({
        ...opts,
        apiKey,
        host: opts.host ?? process.env.POSTHOG_HOST,
        environment,
      }),
    );
  }
  if (isEnabled && measurementId && apiSecret && want("ga4")) {
    sinks.push(
      new Ga4ProductAnalytics({
        ...opts.ga4,
        measurementId,
        apiSecret,
        debug: opts.ga4?.debug ?? process.env.GA4_DEBUG === "1",
        version: opts.version,
        environment,
      }),
    );
  }
  analyticsInstance =
    sinks.length === 0
      ? new NullProductAnalytics()
      : sinks.length === 1
        ? sinks[0]!
        : new FanOutProductAnalytics(sinks);
  return analyticsInstance;
}

/** Replaces the instance (tests pass a recording fake). */
export function setProductAnalytics(instance: ProductAnalytics | null) {
  analyticsInstance = instance;
}

export async function closeProductAnalytics(): Promise<void> {
  await analyticsInstance?.close();
}

export function getProductAnalytics(): ProductAnalytics {
  if (!analyticsInstance) {
    analyticsInstance = new NullProductAnalytics();
  }
  return analyticsInstance;
}

/**
 * A deterministic UUID (v5-shaped, from SHA-1) per key, so a retried once-only event or rollup
 * merges in PostHog instead of counting twice. PostHog rejects event ids that are not UUIDs.
 */
export function deterministicUuid(...parts: string[]): string {
  const h = createHash("sha1")
    .update(`casama:${parts.join(":")}`)
    .digest("hex");
  const variant = ((Number.parseInt(h.slice(16, 18), 16) & 0x3f) | 0x80)
    .toString(16)
    .padStart(2, "0");
  return `${h.slice(0, 8)}-${h.slice(8, 12)}-5${h.slice(13, 16)}-${variant}${h.slice(18, 20)}-${h.slice(20, 32)}`;
}
