/**
 * Live data cards (docs/RICH-CARDS-PLAN.md §13): providers parsed from recorded answers, the shared
 * cache (one call per key, stale answers on errors), sun and moon math, the cards the engine builds
 * and the canvases pinned cards become. No live calls.
 */
import { readFileSync } from "node:fs";
import { checkComponents } from "@casama/domain";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { moonIllumination, moonPhaseName, sunTimes } from "../src/live-data/astro.ts";
import { resolveWhen, unitsFor } from "../src/live-data/cards.ts";
import { liveCache, liveHttp } from "../src/live-data/core.ts";
import { LiveEngine } from "../src/live-data/engine.ts";
import { coinIdOf, findSymbol, thin } from "../src/live-data/markets.ts";
import { canvasFor, pinName } from "../src/live-data/pins.ts";
import { localParts, zonedTime } from "../src/live-data/tz.ts";
import { metCondition, wmoCondition } from "../src/live-data/weather.ts";

const fx = (name: string) =>
  readFileSync(new URL(`./fixtures/live/${name}`, import.meta.url), "utf8");

/** A fetch that answers from the recorded fixtures by host and path, and counts calls. */
function fakeFetch() {
  const calls: string[] = [];
  const f = (async (input: string | URL | Request) => {
    const url = new URL(String(input instanceof Request ? input.url : input));
    calls.push(url.host + url.pathname);
    const body = (() => {
      if (url.host === "geocoding-api.open-meteo.com") return fx("geo-manila.json");
      if (url.host === "api.met.no") return fx("met-manila.json");
      if (url.host === "api.open-meteo.com") return fx("om-manila.json");
      if (url.host === "api.coingecko.com" && url.pathname.endsWith("/markets"))
        return fx("cg-btc.json");
      if (url.host === "api.frankfurter.dev" && url.pathname.includes(".."))
        return JSON.stringify({
          rates: { "2026-11-18": { PHP: 63.1 }, "2026-11-19": { PHP: 63.695 } },
        });
      if (url.host === "api.frankfurter.dev") return fx("fx-usd-php.json");
      return null;
    })();
    if (body === null) return new Response("not found", { status: 404 });
    return new Response(body, { status: 200, headers: { "content-type": "application/json" } });
  }) as typeof fetch;
  return { fetch: f, calls };
}

// The fixtures were recorded on 2026-11-20 around 20:00 in Manila.
const FIXTURE_NOW = new Date("2026-11-20T12:30:00Z");

describe("weather", () => {
  beforeEach(() => {
    vi.useFakeTimers({ toFake: ["Date"] });
    vi.setSystemTime(FIXTURE_NOW);
  });
  afterEach(() => vi.useRealTimers());

  it("maps provider codes to ours", () => {
    expect(metCondition("lightrainshowers_day")).toBe("showers");
    expect(metCondition("heavyrainandthunder")).toBe("thunder");
    expect(metCondition("clearsky_night")).toBe("clear");
    expect(metCondition("fair_day")).toBe("mostly_clear");
    expect(metCondition("lightsnow")).toBe("light_snow");
    expect(wmoCondition(95)).toBe("thunder");
    expect(wmoCondition(61)).toBe("light_rain");
    expect(wmoCondition(2)).toBe("partly_cloudy");
  });

  it("builds tomorrow's card from MET Norway with Open-Meteo's rain chances", async () => {
    const { fetch, calls } = fakeFetch();
    const engine = new LiveEngine(liveHttp(fetch), liveCache(null), {
      openMeteo: true,
      unofficial: false,
    });
    const r = await engine.run("weather", { place: "Manila", when: "tomorrow" }, {});
    const c = r.built.card as Record<string, unknown>;
    expect(c.component).toBe("Weather");
    expect(c.when).toBe("2026-11-21");
    expect((c.place as { name: string; tz: string }).tz).toBe("Asia/Manila");
    const day = c.day as { high: number; low: number; chance?: number };
    expect(day.high).toBeGreaterThan(day.low);
    expect(typeof day.chance).toBe("number");
    expect((c.hours as unknown[]).length).toBeGreaterThan(0);
    for (const h of c.hours as Array<{ t: string }>)
      expect(h.t.startsWith("2026-11-21")).toBe(true);
    const live = c.live as { source: { name: string }; sources?: Array<{ name: string }> };
    expect(live.source.name).toBe("MET Norway");
    expect(live.sources?.[0]?.name).toBe("Open-Meteo");
    expect(r.built.text).toMatch(/Manila, PH on 2026-11-21/);
    expect(c.summary).toBe(r.built.text);
    // The place is kept looked up, so a refresh needs no geocoding.
    expect((r.resolved.place as { lat: number }).lat).toBeCloseTo(14.6, 1);
    expect(calls.filter((x) => x.includes("met.no"))).toHaveLength(1);
    // The card passes the same checks a plugin's card would.
    expect(() => checkComponents([{ id: "root", ...c }])).not.toThrow();
  });

  it("doesn't call Open-Meteo where its free terms don't allow it", async () => {
    const { fetch, calls } = fakeFetch();
    const engine = new LiveEngine(liveHttp(fetch), liveCache(null), {
      openMeteo: false,
      unofficial: false,
    });
    const r = await engine.run("weather", { place: "14.6,120.98" }, {});
    expect(calls.some((x) => x.startsWith("api.open-meteo.com"))).toBe(false);
    expect((r.built.card as { now?: unknown }).now).toBeTruthy();
    expect(engine.available()).not.toContain("air");
  });

  it("uses the person's home city, then their time zone's city", async () => {
    const { fetch } = fakeFetch();
    const engine = new LiveEngine(liveHttp(fetch), liveCache(null), {
      openMeteo: false,
      unofficial: false,
    });
    const home = await engine.run(
      "weather",
      {},
      { homePlace: { name: "Home", lat: 14.6, lng: 120.98, tz: "Asia/Manila" } },
    );
    expect((home.built.card.place as { name: string }).name).toBe("Home");
    const zone = await engine.run("weather", {}, { timezone: "Asia/Manila" });
    expect((zone.built.card.place as { name: string }).name).toBe("Manila");
    expect(zone.built.text).toMatch(/time zone/);
    await expect(engine.run("weather", {}, {})).rejects.toThrow(/Which place/);
  });

  it("reads days in the place's own zone", () => {
    expect(resolveWhen("tomorrow", "Asia/Manila", FIXTURE_NOW).date).toBe("2026-11-21");
    expect(resolveWhen("today", "America/Los_Angeles", FIXTURE_NOW).date).toBe("2026-11-20");
    expect(resolveWhen("week", "UTC").week).toBe(true);
    expect(resolveWhen("saturday", "Asia/Manila", FIXTURE_NOW).date).toBe("2026-11-21");
  });
});

describe("markets and money", () => {
  it("knows coins by ticker and name, and leaves stock names for search", async () => {
    expect(coinIdOf("btc")).toEqual({ id: "bitcoin", symbol: "BTC" });
    expect(coinIdOf("Bitcoin")).toEqual({ id: "bitcoin", symbol: "BTC" });
    expect(coinIdOf("ETH-USD")?.id).toBe("ethereum");
    expect(coinIdOf("AAPL")).toBeNull();
    const d = { http: liveHttp(fetch), cache: liveCache(null), unofficial: false };
    expect(await findSymbol(d, "AAPL")).toBe("AAPL");
    expect(await findSymbol(d, "PSEi")).toBe("PSEI.PS");
    expect(await findSymbol(d, "S&P 500")).toBe("^GSPC");
    // A lowercase name needs a search, which only unofficial sources offer.
    expect(await findSymbol(d, "apple")).toBeNull();
  });

  it("builds a crypto quote with a one-day chart", async () => {
    const { fetch } = fakeFetch();
    const engine = new LiveEngine(liveHttp(fetch), liveCache(null), {
      openMeteo: false,
      unofficial: false,
    });
    const r = await engine.run("quote", { symbols: ["BTC"] }, {});
    const c = r.built.card as Record<string, unknown>;
    expect(c.component).toBe("Quote");
    expect(c.symbol).toBe("BTC");
    expect(c.marketState).toBe("24h");
    expect((c.chart as { points: unknown[] }).points.length).toBeGreaterThan(5);
    expect((c.live as { source: { name: string } }).source.name).toBe("CoinGecko");
  });

  it("says stocks aren't set up without a provider", async () => {
    const { fetch } = fakeFetch();
    const engine = new LiveEngine(liveHttp(fetch), liveCache(null), {
      openMeteo: false,
      unofficial: false,
    });
    await expect(engine.run("quote", { symbols: ["AAPL"] }, {})).rejects.toThrow(
      /Stock prices aren't set up/,
    );
    expect(engine.available()).not.toContain("markets");
  });

  it("converts currencies with a trend", async () => {
    const { fetch } = fakeFetch();
    const engine = new LiveEngine(liveHttp(fetch), liveCache(null), {
      openMeteo: false,
      unofficial: false,
    });
    const r = await engine.run("fx", { from: "usd", to: ["php"], amount: 100 }, {});
    const c = r.built.card as Record<string, unknown>;
    expect(c.base).toBe("USD");
    expect((c.rates as Array<{ to: string }>)[0]?.to).toBe("PHP");
    expect((c.trend as { points: unknown[] }).points).toHaveLength(2);
    expect(r.built.text).toMatch(/100 USD = 6369\.50 PHP/);
    await expect(engine.run("fx", { from: "USD", to: ["pesos"] }, {})).rejects.toThrow(
      /currency code/,
    );
  });

  it("thins long charts and keeps the last point", () => {
    const pts = Array.from({ length: 500 }, (_, i) => [i, i * 2] as [number, number]);
    const t = thin(pts, 100);
    expect(t).toHaveLength(100);
    expect(t[t.length - 1]).toEqual([499, 998]);
  });
});

describe("the shared cache", () => {
  it("calls once for concurrent asks, then answers from memory", async () => {
    const cache = liveCache(null);
    let calls = 0;
    const load = async () => {
      calls++;
      await new Promise((r) => setTimeout(r, 20));
      return { v: calls };
    };
    const [a, b] = await Promise.all([
      cache.get("p", "k", 60, load),
      cache.get("p", "k", 60, load),
    ]);
    expect(a.value).toEqual({ v: 1 });
    expect(b.value).toEqual({ v: 1 });
    const c = await cache.get("p", "k", 60, load);
    expect(c.cached).toBe(true);
    expect(calls).toBe(1);
  });

  it("serves a stale answer when the provider fails, and a forced refresh calls again", async () => {
    let now = 1_000_000;
    const cache = liveCache(null, { now: () => now });
    await cache.get("p", "k", 60, async () => 1);
    now += 61_000;
    const stale = await cache.get("p", "k", 60, async () => {
      throw new Error("down");
    });
    expect(stale).toMatchObject({ value: 1, stale: true });
    now += 1_000;
    const forced = await cache.get("p", "k", 60, async () => 2, { force: true });
    expect(forced.value).toBe(2);
    // A forced refresh right after a fetch is answered from the cache (the ↻ floor).
    const again = await cache.get("p", "k", 60, async () => 3, { force: true, minAgeSeconds: 15 });
    expect(again.value).toBe(2);
    now += 60 * 6000;
    await expect(
      cache.get("p", "k", 60, async () => Promise.reject(new Error("down"))),
    ).rejects.toThrow("down");
  });
});

describe("sun and moon", () => {
  it("puts sunrise and sunset where they belong", () => {
    const tz = "Asia/Manila";
    const s = sunTimes(zonedTime("2026-11-21", tz, 12), 14.6, 120.98);
    const rise = localParts(s.sunrise as Date, tz);
    const set = localParts(s.sunset as Date, tz);
    // timeanddate.com: 05:59 and 17:25 that day.
    expect(Math.abs(rise.hour * 60 + rise.minute - (5 * 60 + 59))).toBeLessThanOrEqual(3);
    expect(Math.abs(set.hour * 60 + set.minute - (17 * 60 + 25))).toBeLessThanOrEqual(3);
    // Polar night in Svalbard in December.
    expect(sunTimes(new Date("2026-12-21T12:00:00Z"), 78.2, 15.6).polar).toBe("night");
  });

  it("knows the moon's phase", () => {
    // A full moon: 2026-11-24 (approximately).
    const m = moonIllumination(new Date("2026-11-24T12:00:00Z"));
    expect(m.fraction).toBeGreaterThan(0.9);
    expect(["full_moon", "waxing_gibbous", "waning_gibbous"]).toContain(moonPhaseName(m.phase));
  });
});

describe("units", () => {
  it("follows the country", () => {
    expect(unitsFor("US").temp).toBe("F");
    expect(unitsFor("PH").temp).toBe("C");
    expect(unitsFor(undefined).wind).toBe("kph");
  });
});

describe("pinned cards", () => {
  beforeEach(() => {
    vi.useFakeTimers({ toFake: ["Date"] });
    vi.setSystemTime(FIXTURE_NOW);
  });
  afterEach(() => vi.useRealTimers());

  it("turn weather into an hourly schedule and prices into a number", async () => {
    const { fetch } = fakeFetch();
    const engine = new LiveEngine(liveHttp(fetch), liveCache(null), {
      openMeteo: true,
      unofficial: false,
    });
    const w = await engine.run("weather", { place: "Manila" }, {});
    const canvas = canvasFor(w.built.card, { temp: "F" });
    expect(canvas?.entries?.length).toBeGreaterThan(1);
    expect(canvas?.entries?.length).toBeLessThanOrEqual(14);
    expect(canvas?.entries?.[0]?.at).toBeNull();
    expect(canvas?.entries?.[0]?.template).toBe("number");
    expect(canvas?.entries?.[0]?.unit).toBe("°F");
    expect(canvas?.look.background.kind).toBe("gradient");
    expect(pinName(w.built.card)).toBe("Weather · Manila");
    const q = await engine.run("quote", { symbols: ["BTC"] }, {});
    const qc = canvasFor(q.built.card);
    expect(qc?.entries?.[0]).toMatchObject({ template: "number", title: "BTC" });
    expect(qc?.entries?.[0]?.tiny.length).toBeLessThanOrEqual(24);
    expect(canvasFor({ component: "Recipe" })).toBeNull();
  });
});

describe("cards from pages", async () => {
  const { cardFromLd, ingredient, isoDuration, jsonLd } = await import("../src/live-data/page.ts");
  const page = `<html><script type="application/ld+json">{"@context":"https://schema.org","@graph":[{"@type":"WebPage"},{"@type":"Recipe","name":"Chicken Adobo","image":["https://x.test/a.jpg"],"totalTime":"PT1H30M","recipeYield":"4 servings","recipeIngredient":["2 lbs chicken","1/2 cup soy sauce","1 ½ cups water","salt to taste"],"recipeInstructions":[{"@type":"HowToStep","text":"Marinate."},{"@type":"HowToStep","text":"Simmer <b>30</b> minutes."}],"nutrition":{"calories":"646 kcal"}}]}</script></html>`;

  it("reads a recipe's own ingredients and steps", () => {
    const card = cardFromLd(jsonLd(page), "https://www.panlasang.test/adobo/");
    expect(card).toMatchObject({
      component: "Recipe",
      title: "Chicken Adobo",
      time: "1 h 30 min",
      servings: 4,
      calories: 646,
    });
    expect(card?.ingredients).toEqual([
      { text: "chicken", qty: 2, unit: "lbs" },
      { text: "soy sauce", qty: 0.5, unit: "cup" },
      { text: "water", qty: 1.5, unit: "cups" },
      { text: "salt to taste" },
    ]);
    expect(card?.steps).toEqual(["Marinate.", "Simmer 30 minutes."]);
    expect(card?.source).toEqual({
      name: "panlasang.test",
      url: "https://www.panlasang.test/adobo/",
    });
    expect(() =>
      checkComponents([{ id: "root", ...(card as Record<string, unknown>) }], { fromBot: true }),
    ).not.toThrow();
  });

  it("parses durations and quantities", () => {
    expect(isoDuration("PT120M")).toBe("2 h");
    expect(isoDuration("PT45M")).toBe("45 min");
    expect(ingredient("3 cloves garlic")).toEqual({ text: "garlic", qty: 3, unit: "cloves" });
    expect(ingredient("a pinch of salt")).toEqual({ text: "a pinch of salt" });
  });

  it("returns nothing for pages without data it draws", () => {
    expect(cardFromLd(jsonLd("<html></html>"), "https://x.test/")).toBeNull();
  });
});
