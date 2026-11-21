/**
 * Flight fares on the server (docs/FLIGHT-SEARCH-PLAN.md §7, §13): the env → engine config, and the
 * meter that lets a run use Google Flights: the server's monthly allowance, the plan's daily
 * searches, credits, and the usage row it writes.
 */
import { type FaresBilling, faresMeter } from "@casama/agent";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { liveDataConfigFromEnv } from "../src/services/live-data.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
let orgId = "";
let ctx: { orgId: string; botId: string; runId: string };
const cfg: FaresBilling = { priceUsd: 0.05, upstreamUsd: 0.025, monthlyCap: 5, billing: true };

beforeAll(async () => {
  h = await startHarness({});
  const owner = await h.user("fares@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "Fares" } }),
    )
  ).id;
  const bot = await j(
    await h.request("/v1/bots", {
      method: "POST",
      token: owner.token,
      json: { org_id: orgId, name: "Trips" },
    }),
  );
  const [run] = await h.tdb.admin<
    { id: string }[]
  >`insert into public.runs (org_id, bot_id, created_by) values (${orgId}, ${bot.id}, ${owner.id}) returning id`;
  ctx = { orgId, botId: bot.id, runId: run!.id };
}, 90_000);
afterAll(async () => {
  await h?.stop();
});

describe("fares config", () => {
  const env = (over: Record<string, unknown> = {}) =>
    ({
      LIVE_DATA: "on",
      LIVE_OPEN_METEO: "auto",
      LIVE_UNOFFICIAL: "auto",
      LIVE_FARES: "auto",
      LIVE_KIWI_MCP_URL: "https://mcp.kiwi.com",
      LIVE_SERPAPI_MONTHLY_CAP: 225,
      LIVE_SERPAPI_COST_USD: 0.025,
      LIVE_FARES_GOOGLE_PRICE_USD: 0.05,
      BILLING_ENABLED: false,
      ...over,
    }) as never;

  it("turns Kiwi on with no keys and Google on with a key, in order", () => {
    const plain = liveDataConfigFromEnv(env())!;
    expect(plain.kiwiMcpUrl).toBe("https://mcp.kiwi.com");
    expect(plain.serpapiKey).toBeUndefined();
    expect(plain.faresOrder).toEqual(["kiwi", "serpapi"]);
    expect(plain.faresBilling?.billing).toBe(false);
    const cloud = liveDataConfigFromEnv(
      env({
        BILLING_ENABLED: true,
        LIVE_SERPAPI_KEY: "k",
        LIVE_FARES_ORDER: "serpapi, nope, kiwi",
        LIVE_SERPAPI_MONTHLY_CAP: 900,
      }),
    )!;
    expect(cloud.serpapiKey).toBe("k");
    expect(cloud.faresOrder).toEqual(["serpapi", "kiwi"]);
    expect(cloud.faresBilling).toEqual({
      priceUsd: 0.05,
      upstreamUsd: 0.025,
      monthlyCap: 900,
      billing: true,
    });
    expect(liveDataConfigFromEnv(env({ LIVE_FARES: "off" }))!.kiwiMcpUrl).toBeUndefined();
  });

  it("wraps booking links only with a safe affiliate template", () => {
    expect(liveDataConfigFromEnv(env())!.faresAffiliate).toBeUndefined();
    expect(
      liveDataConfigFromEnv(env({ LIVE_FARES_AFFILIATE_URL: "http://x.example/{url}" }))!
        .faresAffiliate,
    ).toBeUndefined();
    expect(
      liveDataConfigFromEnv(
        env({
          LIVE_FARES_AFFILIATE_URL: "https://tp.example/r?u={url}",
          LIVE_FARES_AFFILIATE_HOSTS: "kiwi.com,www.kiwi.com",
        }),
      )!.faresAffiliate,
    ).toEqual({ template: "https://tp.example/r?u={url}", hosts: ["kiwi.com", "www.kiwi.com"] });
  });
});

describe("fares meter", () => {
  it("allows Google, charges one search, and records an empty one at $0", async () => {
    const m = faresMeter(h.handle.db, ctx, cfg);
    expect(await m.allow("serpapi")).toBeNull();
    await m.charge("serpapi", { route: "Manila→Tokyo", billable: true });
    await m.charge("serpapi", { route: "Manila→Nowhere", billable: false });
    const rows = await h.tdb.admin<
      {
        cost_usd: string;
        upstream_cost_usd: string;
        billable: boolean;
        meta: Record<string, unknown>;
      }[]
    >`select cost_usd, upstream_cost_usd, billable, meta from public.usage_ledger
      where org_id = ${orgId} and kind = 'data_calls' order by created_at, id`;
    expect(rows).toHaveLength(2);
    expect(Number(rows[0]!.cost_usd)).toBeCloseTo(0.05, 6);
    expect(Number(rows[0]!.upstream_cost_usd)).toBeCloseTo(0.025, 6);
    expect(rows[0]!.billable).toBe(true);
    expect(rows[0]!.meta).toMatchObject({
      provider: "serpapi",
      service: "flight_fares",
      key: "server",
    });
    expect(Number(rows[1]!.cost_usd)).toBe(0);
    expect(rows[1]!.billable).toBe(false);
  });

  it("stops at the plan's daily searches and at no credits", async () => {
    await h.tdb.admin`
      insert into public.entitlements (org_id, plan_code, limits, overrides)
      select ${orgId}, code, limits || '{"credit_gate": true}'::jsonb, '{}'::jsonb from public.plans where code = 'free'`;
    const m = faresMeter(h.handle.db, ctx, cfg);
    // Free allows 3 a day and two were used; the workspace has no credits.
    expect(await m.allow("serpapi")).toMatch(/credits/);
    await h.tdb.admin`
      update public.entitlements set overrides = '{"fares_google_daily": 2}'::jsonb where org_id = ${orgId}`;
    expect(await m.allow("serpapi")).toMatch(/used up/);
    // A server that doesn't bill never asks for credits and never charges.
    const free = faresMeter(h.handle.db, ctx, { ...cfg, billing: false });
    await h.tdb.admin`
      update public.entitlements set overrides = '{"fares_google_daily": 50}'::jsonb where org_id = ${orgId}`;
    expect(await free.allow("serpapi")).toBeNull();
    await free.charge("serpapi", { route: "a→b", billable: true });
    const [last] = await h.tdb.admin<{ cost_usd: string; billable: boolean }[]>`
      select cost_usd, billable from public.usage_ledger where org_id = ${orgId} and kind = 'data_calls'
      order by created_at desc, id desc limit 1`;
    expect(Number(last!.cost_usd)).toBe(0);
    expect(last!.billable).toBe(false);
  });

  it("stops at the server's monthly allowance", async () => {
    await h.tdb.admin`
      insert into public.live_data_daily (day, provider, calls) values (current_date, 'fares-serpapi', 5)
      on conflict (day, provider) do update set calls = 5`;
    const m = faresMeter(h.handle.db, ctx, { ...cfg, billing: false });
    expect(await m.allow("serpapi")).toMatch(/monthly allowance/);
    expect(await m.allow("kiwi")).toBeNull();
  });
});
