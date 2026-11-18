import { afterEach, expect, it } from "vitest";
import {
  Ga4ProductAnalytics,
  ga4Params,
  getProductAnalytics,
  initProductAnalytics,
  parseAnalyticsProviders,
  setProductAnalytics,
} from "../src/index.ts";

afterEach(() => setProductAnalytics(null));

function recorder() {
  const calls: { url: string; body: Record<string, unknown> }[] = [];
  const fetch = (async (url: string, init: RequestInit) => {
    calls.push({ url, body: JSON.parse(String(init.body)) });
    return new Response(null, { status: 204 });
  }) as unknown as typeof globalThis.fetch;
  return { calls, fetch };
}

it("parses ANALYTICS_PROVIDERS: unset means every configured provider, none turns all off", () => {
  expect(parseAnalyticsProviders(undefined)).toBeNull();
  expect(parseAnalyticsProviders(" ")).toBeNull();
  expect([...(parseAnalyticsProviders("GA4, posthog, mixpanel") ?? [])].sort()).toEqual([
    "ga4",
    "posthog",
  ]);
  expect(parseAnalyticsProviders("none")?.size).toBe(0);
});

it("picks providers from keys and ANALYTICS_PROVIDERS", () => {
  const ga4 = { measurementId: "G-TEST", apiSecret: "s", flushInterval: 0 };
  expect(initProductAnalytics({ enabled: false, apiKey: "phc", ga4 }).enabled).toBe(false);
  expect(initProductAnalytics({ enabled: true, ga4 })).toBeInstanceOf(Ga4ProductAnalytics);
  expect(
    initProductAnalytics({ enabled: true, apiKey: "phc", ga4, providers: "ga4" }),
  ).toBeInstanceOf(Ga4ProductAnalytics);
  const both = initProductAnalytics({ enabled: true, apiKey: "phc", ga4 }) as unknown as {
    sinks: unknown[];
  };
  expect(both.sinks).toHaveLength(2);
  expect(
    initProductAnalytics({ enabled: true, apiKey: "phc", ga4, providers: "none" }).enabled,
  ).toBe(false);
  expect(initProductAnalytics({ enabled: true, providers: "posthog", ga4 }).enabled).toBe(false);
  void getProductAnalytics().close();
});

it("cleans params to GA4's types and limits", () => {
  const many = Object.fromEntries(Array.from({ length: 30 }, (_, i) => [`p${i}`, i]));
  expect(Object.keys(ga4Params(many))).toHaveLength(25);
  expect(
    ga4Params({
      a: true,
      b: false,
      c: "x".repeat(150),
      d: null,
      e: { x: 1 },
      $set: "no",
      f: Number.NaN,
    }),
  ).toEqual({ a: 1, b: 0, c: "x".repeat(100) });
});

it("sends person events with user_id, skips personless events and rollups, maps purchase", async () => {
  const { calls, fetch } = recorder();
  const ga4 = new Ga4ProductAnalytics({
    measurementId: "G-TEST",
    apiSecret: "sec",
    fetch,
    flushInterval: 0,
    environment: "production",
  });
  ga4.capture({
    event: "signed_up",
    distinctId: "u1",
    properties: { method: "email", is_sign_up: true },
  });
  ga4.capture({
    event: "purchase",
    distinctId: "u1",
    orgId: "o1",
    uuid: "tx-1",
    properties: { plan: "plus" },
  });
  ga4.capture({ event: "run_refused", distinctId: "workspace:o1", personless: true });
  ga4.capture({ event: "usage_daily", distinctId: "u2", properties: { runs_started: 3 } });
  await ga4.close();

  expect(calls).toHaveLength(1);
  expect(calls[0]?.url).toBe(
    "https://www.google-analytics.com/mp/collect?measurement_id=G-TEST&api_secret=sec",
  );
  const body = calls[0]?.body as {
    user_id: string;
    client_id: string;
    events: { name: string; params: Record<string, unknown> }[];
  };
  expect(body.user_id).toBe("u1");
  expect(body.client_id).toMatch(/^[0-9a-f-]{36}$/);
  expect(body.events.map((e) => e.name)).toEqual(["signed_up", "purchase"]);
  expect(body.events[0]?.params).toMatchObject({
    app: "casama",
    environment: "production",
    method: "email",
    is_sign_up: 1,
  });
  expect(body.events[1]?.params).toMatchObject({
    currency: "USD",
    transaction_id: "tx-1",
    workspace_id: "o1",
    plan: "plus",
  });
});

it("uses the validation endpoint in debug mode and never throws on a failed send", async () => {
  const urls: string[] = [];
  const fetch = (async (url: string) => {
    urls.push(url);
    throw new Error("offline");
  }) as unknown as typeof globalThis.fetch;
  const ga4 = new Ga4ProductAnalytics({
    measurementId: "G-T",
    apiSecret: "s",
    debug: true,
    fetch,
    flushInterval: 0,
  });
  ga4.capture({ event: "signed_out", distinctId: "u1" });
  await expect(ga4.flush()).resolves.toBeUndefined();
  expect(urls[0]).toContain("/debug/mp/collect");
});

it("adds the catalog's recommended twin and the plan user property (D-398)", async () => {
  const { calls, fetch } = recorder();
  const ga4 = new Ga4ProductAnalytics({
    measurementId: "G-T",
    apiSecret: "s",
    fetch,
    flushInterval: 0,
    twins: { signed_up: { name: "sign_up", params: ["method"], set: { x: 1 } } },
  });
  ga4.capture({
    event: "signed_up",
    distinctId: "u1",
    properties: { method: "google", extra: "no" },
  });
  ga4.capture({ event: "subscription_changed", distinctId: "u1", properties: { plan: "pro" } });
  await ga4.close();
  const body = calls[0]?.body as {
    user_properties?: Record<string, { value: string }>;
    events: { name: string; params: Record<string, unknown> }[];
  };
  expect(body.events.map((e) => e.name)).toEqual(["signed_up", "sign_up", "subscription_changed"]);
  expect(body.events[1]?.params).toMatchObject({ method: "google", x: 1, app: "casama" });
  expect(body.events[1]?.params.extra).toBeUndefined();
  expect(body.user_properties).toEqual({ plan: { value: "pro" } });
});
