/** One real call per live tool (RICH-CARDS-PLAN §13): `node scripts/live-data-smoke.ts [tool]`. Not run in CI. */

import { liveCache, liveHttp } from "../src/live-data/core.ts";
import { LiveEngine, type LiveTool } from "../src/live-data/engine.ts";

const engine = new LiveEngine(liveHttp(fetch), liveCache(null), {
  openMeteo: true,
  unofficial: true,
  finnhubKey: process.env.LIVE_FINNHUB_KEY,
  aviationstackKey: process.env.LIVE_AVIATIONSTACK_KEY,
  seventeenTrackKey: process.env.LIVE_17TRACK_KEY,
  tmdbKey: process.env.LIVE_TMDB_KEY,
});
const cases: Array<[LiveTool, Record<string, unknown>]> = [
  ["weather", { place: "Manila", when: "tomorrow" }],
  ["weather", { place: "San Francisco" }],
  ["weather", { place: "Tokyo", when: "week" }],
  ["alerts", { place: "Miami" }],
  ["air", { place: "Manila" }],
  ["sun", { place: "Reykjavik" }],
  ["quote", { symbols: ["BTC"] }],
  ["quote", { symbols: ["AAPL"], range: "1M" }],
  ["quote", { symbols: ["apple", "TSLA", "ETH", "PSEi"] }],
  ["markets", { view: "overview" }],
  ["markets", { view: "gainers" }],
  ["fx", { from: "USD", to: ["PHP"], amount: 100 }],
  ["fx", { from: "EUR", to: ["USD", "JPY", "GBP"] }],
  ["time", { places: ["Manila", "San Francisco", "London"] }],
  ["holidays", { country: "PH" }],
  ["quakes", { place: "Manila" }],
  ["quakes", {}],
  ["storms", { place: "Manila" }],
  ["lookup", { topic: "Jollibee" }],
  ["define", { word: "serendipity" }],
  ["book", { query: "Dune" }],
  ["sports", { league: "nba" }],
  ["sports", { league: "epl", view: "standings" }],
];
const only = process.argv[2];
for (const [tool, args] of cases) {
  if (only && only !== tool) continue;
  const t = Date.now();
  try {
    const r = await engine.run(tool, args, { timezone: "Asia/Manila" });
    console.log(
      `✓ ${tool} ${JSON.stringify(args)} ${Date.now() - t}ms ${JSON.stringify(r.built.card).length}B\n  ${r.built.text.slice(0, 220)}`,
    );
  } catch (e) {
    console.log(`✗ ${tool} ${JSON.stringify(args)}: ${e instanceof Error ? e.message : e}`);
  }
}
