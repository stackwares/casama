/**
 * Writes one real card per live tool to packages/contracts/fixtures/live-cards.json (RICH-CARDS-PLAN
 * §13): the shapes the app's tests render. Calls the real providers; run by hand, not in CI.
 */
import { writeFileSync } from "node:fs";
import { liveCache, liveHttp } from "../src/live-data/core.ts";
import { LiveEngine, type LiveTool } from "../src/live-data/engine.ts";

const engine = new LiveEngine(liveHttp(fetch), liveCache(null), {
  openMeteo: true,
  unofficial: true,
});
const cases: Array<[string, LiveTool, Record<string, unknown>]> = [
  ["weather_now", "weather", { place: "San Francisco" }],
  ["weather_tomorrow", "weather", { place: "Manila", when: "tomorrow" }],
  ["forecast", "weather", { place: "Tokyo", when: "week" }],
  ["alerts", "alerts", { place: "Miami" }],
  ["air", "air", { place: "Manila" }],
  ["sun", "sun", { place: "Reykjavik" }],
  ["quote_crypto", "quote", { symbols: ["BTC"] }],
  ["quote_stock", "quote", { symbols: ["AAPL"], range: "1M" }],
  ["watchlist", "quote", { symbols: ["AAPL", "TSLA", "ETH", "PSEi"] }],
  ["fx", "fx", { from: "USD", to: ["PHP"], amount: 100 }],
  ["fx_many", "fx", { from: "EUR", to: ["USD", "JPY", "GBP"] }],
  ["clock", "time", { places: ["Manila", "San Francisco", "London"] }],
  ["holidays", "holidays", { country: "PH" }],
  ["quakes", "quakes", { place: "Manila" }],
  ["storms", "storms", { place: "Manila" }],
  ["summary", "lookup", { topic: "Jollibee" }],
  ["define", "define", { word: "serendipity" }],
  ["book", "book", { query: "Dune" }],
  ["scores", "sports", { league: "nba" }],
  ["standings", "sports", { league: "epl", view: "standings" }],
];
const out: Record<string, unknown> = {};
for (const [name, tool, args] of cases) {
  try {
    const r = await engine.run(tool, args, { timezone: "Asia/Manila" });
    out[name] = r.built.card;
  } catch (e) {
    console.error(`skipped ${name}: ${e instanceof Error ? e.message : e}`);
  }
}
writeFileSync(
  new URL("../../contracts/fixtures/live-cards.json", import.meta.url),
  `${JSON.stringify(out, null, 1)}\n`,
);
console.log(`wrote ${Object.keys(out).length} cards`);
