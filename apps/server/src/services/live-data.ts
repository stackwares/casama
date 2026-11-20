/** Live data cards (docs/RICH-CARDS-PLAN.md): the engine's settings from the environment. */
import type { LiveConfig } from "@casama/agent";
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
  };
}
