/** Live data cards (docs/RICH-CARDS-PLAN.md): the engine's settings from the environment. */
import {
  FARE_PROVIDERS,
  type FareProviderId,
  faresAffiliate,
  type LiveConfig,
} from "@casama/agent";
import type { Env } from "../env.ts";

export function liveDataConfigFromEnv(
  env: Pick<
    Env,
    | "LIVE_DATA"
    | "LIVE_OPEN_METEO"
    | "LIVE_OPEN_METEO_KEY"
    | "LIVE_UNOFFICIAL"
    | "LIVE_COINGECKO_KEY"
    | "LIVE_FINNHUB_KEY"
    | "LIVE_AVIATIONSTACK_KEY"
    | "LIVE_17TRACK_KEY"
    | "LIVE_TMDB_KEY"
    | "LIVE_FARES"
    | "LIVE_FARES_ORDER"
    | "LIVE_KIWI_MCP_URL"
    | "LIVE_SERPAPI_KEY"
    | "LIVE_SERPAPI_MONTHLY_CAP"
    | "LIVE_SERPAPI_COST_USD"
    | "LIVE_FARES_GOOGLE_PRICE_USD"
    | "LIVE_FARES_AFFILIATE_URL"
    | "LIVE_FARES_AFFILIATE_HOSTS"
    | "BILLING_ENABLED"
  >,
): LiveConfig | null {
  if (env.LIVE_DATA === "off") return null;
  const billing = env.BILLING_ENABLED === true;
  const auto = (v: "auto" | "on" | "off") => (v === "auto" ? !billing : v === "on");
  return {
    openMeteo: Boolean(env.LIVE_OPEN_METEO_KEY) || auto(env.LIVE_OPEN_METEO),
    openMeteoKey: env.LIVE_OPEN_METEO_KEY,
    unofficial: auto(env.LIVE_UNOFFICIAL),
    coingeckoKey: env.LIVE_COINGECKO_KEY,
    finnhubKey: env.LIVE_FINNHUB_KEY,
    aviationstackKey: env.LIVE_AVIATIONSTACK_KEY,
    seventeenTrackKey: env.LIVE_17TRACK_KEY,
    tmdbKey: env.LIVE_TMDB_KEY,
    ...faresConfig(env, billing),
  };
}

/** Flight fares: the provider chain and how Google Flights searches are paid for. */
function faresConfig(
  env: Parameters<typeof liveDataConfigFromEnv>[0],
  billing: boolean,
): Partial<LiveConfig> {
  if (env.LIVE_FARES === "off") return {};
  const order = (env.LIVE_FARES_ORDER ?? "")
    .split(",")
    .map((s) => s.trim())
    .filter((s): s is FareProviderId => (FARE_PROVIDERS as string[]).includes(s));
  return {
    kiwiMcpUrl: env.LIVE_KIWI_MCP_URL,
    serpapiKey: env.LIVE_SERPAPI_KEY || undefined,
    faresOrder: order.length ? order : FARE_PROVIDERS,
    faresBilling: {
      priceUsd: env.LIVE_FARES_GOOGLE_PRICE_USD,
      upstreamUsd: env.LIVE_SERPAPI_COST_USD,
      monthlyCap: env.LIVE_SERPAPI_MONTHLY_CAP,
      billing,
    },
    faresAffiliate: faresAffiliate(env.LIVE_FARES_AFFILIATE_URL, env.LIVE_FARES_AFFILIATE_HOSTS),
  };
}
