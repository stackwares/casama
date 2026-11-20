import { sql } from "drizzle-orm";
import { exportPKCS8, generateKeyPair } from "jose";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import type { Env } from "../src/env.ts";
import { checkVendor, listVendors } from "../src/services/vendors/index.ts";
import { observeResend, observeUnsplash } from "../src/services/vendors/observations.ts";
import { readBalance, readUsage } from "../src/services/vendors/readers.ts";
import { vendorUsageSweep } from "../src/services/vendors/sweep.ts";
import { readCloudUsage } from "../src/services/vendors/usage-cloud.ts";
import { type Harness, startHarness } from "./helpers.ts";

const env = {
  INSTANCE_ADMIN_EMAILS: "vendor-admin@example.com",
  VENDOR_ALERT_EMAILS: "vendor-admin@example.com",
} as Env;
const response = (value: unknown) => (async () => Response.json(value)) as typeof fetch;
describe("vendor readers", () => {
  it("subtracts OpenRouter lifetime usage from purchased credits", async () => {
    expect(
      (
        await readBalance(
          "openrouter",
          { ...env, VENDOR_OPENROUTER_MANAGEMENT_KEY: "fixture" },
          response({ data: { total_credits: 100, total_usage: 25 } }),
        )
      )?.remaining,
    ).toBe(75);
  });
  it("selects DeepSeek USD rather than adding unlike currencies", async () => {
    expect(
      (
        await readBalance(
          "deepseek",
          { ...env, DEEPSEEK_SEARCH_API_KEY: "fixture" },
          response({
            balance_infos: [
              { currency: "CNY", total_balance: "100" },
              { currency: "USD", total_balance: "2.50" },
            ],
          }),
        )
      )?.remaining,
    ).toBe(2.5);
  });
  it("reads Twilio USD balance", async () => {
    expect(
      (
        await readBalance(
          "twilio",
          {
            ...env,
            VENDOR_TWILIO_ACCOUNT_SID: `AC${"a".repeat(32)}`,
            VENDOR_TWILIO_AUTH_TOKEN: "fixture",
          },
          response({ currency: "USD", balance: "12.29" }),
        )
      )?.remaining,
    ).toBe(12.29);
  });
  it("reuses Name.com balance response", async () => {
    expect(
      (
        await readBalance(
          "namecom",
          {
            ...env,
            NAMECOM_USERNAME: "fixture",
            NAMECOM_API_TOKEN: "fixture",
            NAMECOM_API_URL: "https://api.name.com",
          },
          response({ balance: 25 }),
        )
      )?.remaining,
    ).toBe(25);
  });
  it("does not turn absent credentials into a zero balance", async () => {
    expect(await readBalance("openrouter", env)).toBeNull();
  });
  it("counts only actual MapTiler requests, excluding projected usage", async () => {
    const reading = await readUsage(
      "maptiler",
      { ...env, VENDOR_MAPTILER_SERVICE_TOKEN: "fixture" },
      new Date(),
      response({
        datasets: [
          { group_id: "request", data: [{ value: 10 }], estimated_data: { value: 100 } },
          { group_id: "session", data: [{ value: 3 }] },
        ],
      }),
    );
    expect(reading?.used).toBe(10);
    expect(reading?.resets_at).toBeNull();
  });
  it("reads Composio tool totals", async () => {
    expect(
      (
        await readUsage(
          "composio",
          { ...env, VENDOR_COMPOSIO_ORG_KEY: "fixture" },
          new Date(),
          response({ entities: { tool_calls: { total_quantity: "123" } } }),
        )
      )?.used,
    ).toBe(123);
  });
});
describe("cloud usage readers", () => {
  it("sums Cloudflare period costs without double-counting cumulative totals", async () => {
    const data = {
      success: true,
      result: [
        { BillingCurrency: "USD", ContractedCost: 2, CumulatedContractedCost: 100 },
        { BillingCurrency: "USD", ContractedCost: 3, CumulatedContractedCost: 103 },
      ],
    };
    expect(
      (
        await readCloudUsage(
          "cloudflare",
          {
            ...env,
            VENDOR_CLOUDFLARE_ACCOUNT_ID: "fixture",
            VENDOR_CLOUDFLARE_BILLING_TOKEN: "fixture",
          },
          new Date(),
          response(data),
        )
      )?.used,
    ).toBe(5);
  });
  it("exchanges signed HERE credentials and sums paginated usage", async () => {
    let calls = 0;
    const f = (async (url: unknown, init?: RequestInit) => {
      calls++;
      if (String(url).includes("oauth2/token")) {
        expect(new Headers(init?.headers).get("authorization")).toContain("oauth_signature=");
        return Response.json({ access_token: "fixture" });
      }
      return Response.json(
        calls === 2
          ? { items: [{ usageValue: "10" }], nextOffset: 100 }
          : { items: [{ usageValue: "2" }], nextOffset: 0 },
      );
    }) as typeof fetch;
    expect(
      (
        await readCloudUsage(
          "here",
          {
            ...env,
            VENDOR_HERE_KEY_ID: "fixture",
            VENDOR_HERE_KEY_SECRET: "fixture",
            VENDOR_HERE_REALM: "fixture",
            VENDOR_HERE_FEATURE_ID: "raster",
          },
          new Date(),
          f,
        )
      )?.used,
    ).toBe(12);
    expect(calls).toBe(3);
  });
  it("authenticates Google monitoring and follows all metric pages", async () => {
    const keys = await generateKeyPair("RS256", { extractable: true });
    const sa = JSON.stringify({
      client_email: "fixture@example.com",
      project_id: "fixture",
      private_key: await exportPKCS8(keys.privateKey),
    });
    let calls = 0;
    const f = (async (url: unknown) => {
      calls++;
      if (String(url).includes("oauth2.googleapis.com"))
        return Response.json({ access_token: "fixture" });
      expect(new URL(String(url)).searchParams.get("interval.startTime")).toBe(
        "2027-03-14T08:00:00.000Z",
      );
      expect(new URL(String(url)).searchParams.get("filter")).toContain(
        'metric.labels.method="confirmedMethod"',
      );
      return Response.json({
        timeSeries: [{ points: [{ value: { int64Value: "5" } }] }],
        ...(calls === 2 ? { nextPageToken: "next" } : {}),
      });
    }) as typeof fetch;
    expect(
      (
        await readCloudUsage(
          "google_maps",
          { ...env, GOOGLE_USAGE_SA_JSON: sa, GOOGLE_USAGE_TILE_METHOD: "confirmedMethod" },
          new Date("2027-03-14T20:00:00Z"),
          f,
        )
      )?.used,
    ).toBe(10);
    expect(calls).toBe(3);
  });
});
describe("vendor monitoring persistence and alert dedupe", () => {
  let h: Harness;
  const messages: { to: string; subject: string }[] = [];
  const sender = {
    enabled: true,
    async send(m: { to: string; subject: string }) {
      messages.push(m);
    },
  };
  beforeAll(async () => {
    h = await startHarness();
    await h.user("vendor-admin@example.com");
  }, 60000);
  afterAll(async () => h?.stop());
  it("reads UTC counts and sends one warning, then one recovery", async () => {
    const db = h.handle.db;
    await db.execute(sql`update public.vendor_limits set enabled=false`);
    await db.execute(
      sql`update public.vendor_limits set enabled=true,limit_value=100,period='month' where vendor='resend'`,
    );
    await db.execute(
      sql`insert into public.vendor_counts(vendor,day,count) values ('resend','2027-03-02',80)`,
    );
    const now = new Date("2027-03-02T01:00:00Z");
    await vendorUsageSweep(db, env, sender, { now });
    await vendorUsageSweep(db, env, sender, { now });
    expect(messages).toHaveLength(1);
    expect((await checkVendor(db, env, "resend", { now }))?.latest).toMatchObject({
      status: "low",
      used: 80,
      remaining: 20,
    });
    await db.execute(sql`update public.vendor_limits set limit_value=200 where vendor='resend'`);
    await vendorUsageSweep(db, env, sender, { now });
    await vendorUsageSweep(db, env, sender, { now });
    expect(messages).toHaveLength(2);
    expect(messages[1]?.subject).toContain("back to normal");
    expect((await listVendors(db)).find((v) => v.vendor === "resend")?.latest?.status).toBe("ok");
  });
  it("alerts only after failures span three hours and repeats once daily", async () => {
    const db = h.handle.db;
    await db.execute(sql`update public.vendor_limits set enabled=false`);
    await db.execute(sql`update public.vendor_limits set enabled=true where vendor='openrouter'`);
    const failing = { ...env, VENDOR_OPENROUTER_MANAGEMENT_KEY: "fixture" };
    const f = (async () => new Response("", { status: 503 })) as typeof fetch;
    const initial = messages.length;
    await vendorUsageSweep(db, failing, sender, {
      now: new Date("2027-03-03T01:00:00Z"),
      fetch: f,
    });
    await vendorUsageSweep(db, failing, sender, {
      now: new Date("2027-03-03T03:59:00Z"),
      fetch: f,
    });
    expect(messages).toHaveLength(initial);
    await vendorUsageSweep(db, failing, sender, {
      now: new Date("2027-03-03T04:00:00Z"),
      fetch: f,
    });
    await vendorUsageSweep(db, failing, sender, {
      now: new Date("2027-03-03T05:00:00Z"),
      fetch: f,
    });
    expect(messages).toHaveLength(initial + 1);
    const [notice] = await db.execute(
      sql`select push_status from public.notifications where kind='vendor_usage' and payload->>'vendor_alert_key' like 'openrouter:%'`,
    );
    expect(notice?.push_status).toBe("deferred");
    await vendorUsageSweep(db, failing, sender, {
      now: new Date("2027-03-04T01:00:00Z"),
      fetch: f,
    });
    expect(messages).toHaveLength(initial + 2);
  });
  it("sends both renewal reminders and one Monday summary", async () => {
    const db = h.handle.db;
    await db.execute(sql`update public.vendor_limits set enabled=false`);
    await db.execute(
      sql`update public.vendor_limits set enabled=true,expires_at='2027-03-25T00:00:00Z' where vendor='contabo'`,
    );
    const initial = messages.length;
    await vendorUsageSweep(db, env, sender, { now: new Date("2027-03-11T01:00:00Z") });
    await vendorUsageSweep(db, env, sender, { now: new Date("2027-03-22T01:00:00Z") });
    await vendorUsageSweep(db, env, sender, { now: new Date("2027-03-22T02:00:00Z") });
    expect(messages).toHaveLength(initial + 3);
    expect(messages.filter((m) => m.subject.includes("weekly vendor"))).toHaveLength(1);
  });
  it("uses provider header observations and ignores expired snapshots", async () => {
    const db = h.handle.db;
    const now = new Date("2027-03-23T10:00:00Z");
    await observeResend(
      db,
      new Headers({ "x-resend-daily-quota": "90", "x-resend-monthly-quota": "2500" }),
      now,
    );
    expect((await checkVendor(db, env, "resend_daily", { now }))?.latest).toMatchObject({
      used: 90,
      status: "low",
      source: "api",
    });
    await observeUnsplash(
      db,
      new Headers({ "x-ratelimit-limit": "1000", "x-ratelimit-remaining": "100" }),
      now,
    );
    expect((await checkVendor(db, env, "unsplash", { now }))?.latest).toMatchObject({
      used: 900,
      remaining: 100,
      status: "low",
      source: "api",
    });
    expect(
      (await checkVendor(db, env, "unsplash", { now: new Date("2027-03-23T12:00:00Z") }))?.latest
        ?.error,
    ).toBe("not_configured");
  });
});
