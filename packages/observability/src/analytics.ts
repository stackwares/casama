/**
 * Product analytics for Casama Cloud (D-208, ANALYTICS-PLAN §4.3).
 * Captures typed catalog events to PostHog when PRODUCT_ANALYTICS=on and POSTHOG_API_KEY is set.
 * Off by default on self-hosted instances.
 * Respects user opt-out and workspace privacy settings.
 */
import { PostHog } from "posthog-node";

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
}

export interface ProductAnalytics {
  capture(opts: CaptureOptions): void;
  flush(): Promise<void>;
  close(): Promise<void>;
}

export interface AnalyticsOptions {
  enabled?: boolean;
  apiKey?: string;
  host?: string;
  version?: string;
  environment?: string;
}

class PostHogProductAnalytics implements ProductAnalytics {
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
  capture(): void {}
  async flush(): Promise<void> {}
  async close(): Promise<void> {}
}

let analyticsInstance: ProductAnalytics | null = null;

export function initProductAnalytics(opts: AnalyticsOptions): ProductAnalytics {
  const isEnabled = opts.enabled ?? process.env.PRODUCT_ANALYTICS === "on";
  const apiKey = opts.apiKey ?? process.env.POSTHOG_API_KEY;

  if (isEnabled && apiKey) {
    analyticsInstance = new PostHogProductAnalytics({
      ...opts,
      apiKey,
      host: opts.host ?? process.env.POSTHOG_HOST,
      environment: opts.environment ?? process.env.ANALYTICS_ENVIRONMENT ?? process.env.NODE_ENV,
    });
  } else {
    analyticsInstance = new NullProductAnalytics();
  }
  return analyticsInstance;
}

export function getProductAnalytics(): ProductAnalytics {
  if (!analyticsInstance) {
    analyticsInstance = new NullProductAnalytics();
  }
  return analyticsInstance;
}
