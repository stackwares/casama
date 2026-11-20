import { z } from "zod";
import type { Env } from "../../env.ts";
import { NameComRegistrar } from "../../sites/namecom.ts";
import { readCloudUsage } from "./usage-cloud.ts";

export interface Reading {
  used: number | null;
  remaining: number | null;
  limit_value: number | null;
  resets_at: string | null;
  source: "api" | "own_count" | "manual";
}
const amount = (n: unknown) => {
  if (n === null || n === undefined || (typeof n === "string" && n.trim() === ""))
    throw new Error("invalid_reading");
  const v = Number(n);
  if (!Number.isFinite(v)) throw new Error("invalid_reading");
  return v;
};
async function json(url: string, key: string, f: typeof fetch) {
  const r = await f(url, {
    headers: { authorization: `Bearer ${key}` },
    signal: AbortSignal.timeout(15000),
  });
  if (!r.ok) throw new Error(`provider_http_${r.status}`);
  return r.json();
}
/** Official balance endpoints; no provider response text is persisted or logged. */
export async function readBalance(
  vendor: string,
  env: Env,
  f: typeof fetch = fetch,
): Promise<Reading | null> {
  let remaining: number;
  if (vendor === "openrouter" && env.VENDOR_OPENROUTER_MANAGEMENT_KEY) {
    const data = z
      .object({ data: z.object({ total_credits: z.number(), total_usage: z.number() }) })
      .parse(
        await json("https://openrouter.ai/api/v1/credits", env.VENDOR_OPENROUTER_MANAGEMENT_KEY, f),
      ).data;
    remaining = amount(data?.total_credits) - amount(data?.total_usage);
  } else if (vendor === "deepseek" && env.DEEPSEEK_SEARCH_API_KEY) {
    const data = z
      .object({
        balance_infos: z.array(z.object({ currency: z.string(), total_balance: z.string() })),
      })
      .parse(await json("https://api.deepseek.com/user/balance", env.DEEPSEEK_SEARCH_API_KEY, f));
    const usd = data.balance_infos?.find((b: { currency: string }) => b.currency === "USD");
    if (!usd) throw new Error("usd_balance_unavailable");
    remaining = amount(usd.total_balance);
  } else if (vendor === "namecom" && env.NAMECOM_USERNAME && env.NAMECOM_API_TOKEN) {
    const registrar = new NameComRegistrar({
      username: env.NAMECOM_USERNAME,
      token: env.NAMECOM_API_TOKEN,
      apiUrl: env.NAMECOM_API_URL,
      fetch: f,
    });
    const balance = await registrar.balanceUsd();
    if (balance === null) throw new Error("invalid_reading");
    remaining = amount(balance);
  } else if (vendor === "twilio" && env.VENDOR_TWILIO_ACCOUNT_SID && env.VENDOR_TWILIO_AUTH_TOKEN) {
    const r = await f(
      `https://api.twilio.com/2010-04-01/Accounts/${encodeURIComponent(env.VENDOR_TWILIO_ACCOUNT_SID)}/Balance.json`,
      {
        headers: {
          authorization: `Basic ${Buffer.from(`${env.VENDOR_TWILIO_ACCOUNT_SID}:${env.VENDOR_TWILIO_AUTH_TOKEN}`).toString("base64")}`,
        },
        signal: AbortSignal.timeout(15000),
      },
    );
    if (!r.ok) throw new Error(`provider_http_${r.status}`);
    const data = z
      .object({ currency: z.literal("USD"), balance: z.string() })
      .parse(await r.json());
    remaining = amount(data.balance);
  } else return null;
  return { used: null, remaining, limit_value: null, resets_at: null, source: "api" };
}

/** Analytics endpoints verified against vendors' public references. */
export async function readUsage(
  vendor: string,
  env: Env,
  now: Date,
  f: typeof fetch = fetch,
): Promise<Reading | null> {
  const start = Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1);
  const end = Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + 1, 1);
  let used: number;
  if (vendor === "openrouter_daily" && env.CLOUD_MODEL_UPSTREAM_KEY) {
    const data = z
      .object({ data: z.object({ usage_daily: z.number().nonnegative() }) })
      .parse(await json("https://openrouter.ai/api/v1/key", env.CLOUD_MODEL_UPSTREAM_KEY, f));
    return {
      used: data.data.usage_daily,
      remaining: null,
      limit_value: env.OPENROUTER_DAILY_CAP_USD,
      resets_at: new Date(
        Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + 1),
      ).toISOString(),
      source: "api",
    };
  }
  if (vendor === "maptiler" && env.VENDOR_MAPTILER_SERVICE_TOKEN) {
    const r = await f(
      "https://service.maptiler.com/v1/analytics/api_usage/timeline?period=current_billing_period&classifier=services&group=request",
      {
        headers: { authorization: `Token ${env.VENDOR_MAPTILER_SERVICE_TOKEN}` },
        signal: AbortSignal.timeout(15000),
      },
    );
    if (!r.ok) throw new Error(`provider_http_${r.status}`);
    const data = z
      .object({
        datasets: z.array(
          z.object({ group_id: z.string(), data: z.array(z.object({ value: z.number() })) }),
        ),
      })
      .parse(await r.json());
    used = data.datasets
      .filter((d) => d.group_id === "request")
      .reduce((n, d) => n + d.data.reduce((a, p) => a + p.value, 0), 0);
    // Account billing boundaries can differ from calendar months; don't invent a reset date.
    return { used, remaining: null, limit_value: null, resets_at: null, source: "api" };
  }
  if (vendor === "composio" && env.VENDOR_COMPOSIO_ORG_KEY) {
    const r = await f("https://backend.composio.dev/api/v3.1/org/usage/summary", {
      method: "POST",
      headers: { "x-org-api-key": env.VENDOR_COMPOSIO_ORG_KEY, "content-type": "application/json" },
      body: JSON.stringify({ from: start, to: now.getTime(), entity_types: ["tool_calls"] }),
      signal: AbortSignal.timeout(15000),
    });
    if (!r.ok) throw new Error(`provider_http_${r.status}`);
    const data = z
      .object({ entities: z.object({ tool_calls: z.object({ total_quantity: z.string() }) }) })
      .parse(await r.json());
    used = amount(data.entities.tool_calls.total_quantity);
    return {
      used,
      remaining: null,
      limit_value: null,
      resets_at: new Date(end).toISOString(),
      source: "api",
    };
  }
  return readCloudUsage(vendor, env, now, f);
}
