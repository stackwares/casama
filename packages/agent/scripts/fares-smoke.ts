/**
 * Real fare searches (FLIGHT-SEARCH-PLAN §12 Phase 0): `node scripts/fares-smoke.ts [kiwi|google]`.
 * kiwi: Kiwi.com's free MCP server. google: Google Flights through SerpApi with LIVE_SERPAPI_KEY
 * (costs one search of the plan). Not run in CI.
 */
import { liveCache, liveHttp } from "../src/live-data/core.ts";
import { type FaresMeter, fareQuery, faresCard, searchFares } from "../src/live-data/fares.ts";

const which = process.argv[2] ?? "kiwi";
const meter: FaresMeter = {
  allow: async () => null,
  charge: async (p, info) => console.log(`(charge ${p}: billable ${info.billable})`),
};
const q = fareQuery(
  { from: "Manila", to: "Tokyo", depart: "2027-03-12", return: "2027-03-19", sort: "cheapest" },
  { timezone: "Asia/Manila" },
);
const t0 = Date.now();
const a = await searchFares(
  {
    http: liveHttp(fetch),
    cache: liveCache(null),
    order: which === "google" ? ["serpapi"] : ["kiwi"],
    kiwiUrl: "https://mcp.kiwi.com",
    serpapiKey: process.env.LIVE_SERPAPI_KEY,
  },
  q,
  { meter },
);
console.log(`${a.provider} in ${Date.now() - t0} ms, ${a.options.length} options\n`);
console.log(faresCard(q, a).text);
