/**
 * Flight fares (docs/FLIGHT-SEARCH-PLAN.md §13): airports, arguments, both providers parsed from
 * recorded answers (fixtures/fares, Phase 0 on 2026-11-21), the provider chain with its meter and
 * cache, and the Fares card. No live calls.
 */
import { readFileSync } from "node:fs";
import { beforeEach, describe, expect, it } from "vitest";
import { homeAirports, resolveAirports } from "../src/live-data/airports.ts";
import { liveCache, liveHttp } from "../src/live-data/core.ts";
import { LiveEngine } from "../src/live-data/engine.ts";
import {
  type FareProvider,
  type FareQuery,
  type FareSearch,
  type FaresMeter,
  fareQuery,
  faresCard,
  kiwiArgs,
  parseKiwi,
  parseSerp,
  resetFareProviders,
  searchFares,
  serpParams,
} from "../src/live-data/fares.ts";

const fixture = (name: string) =>
  JSON.parse(readFileSync(new URL(`./fixtures/fares/${name}`, import.meta.url), "utf8"));
const KIWI = parseKiwi(fixture("kiwi-mnl-tyo-return.json"));
const SERP = parseSerp(fixture("serpapi-mnl-tyo-return.json"), true);

const person = { timezone: "Asia/Manila", homePlace: null };
const trip = (over: Record<string, unknown> = {}) =>
  fareQuery(
    { from: "Manila", to: "Tokyo", depart: "2027-03-12", return: "2027-03-19", ...over },
    person,
  );

function provider(id: "kiwi" | "serpapi", answer: () => FareSearch, paid = id === "serpapi") {
  const p = {
    id,
    paid,
    calls: 0,
    async search(_q: FareQuery) {
      p.calls++;
      return answer();
    },
  };
  return p as FareProvider & { calls: number };
}

function meter(deny: string | null = null) {
  const m = {
    charges: [] as { provider: string; billable: boolean }[],
    async allow() {
      return deny;
    },
    async charge(provider: string, info: { billable: boolean }) {
      m.charges.push({ provider, billable: info.billable });
    },
  };
  return m as FaresMeter & { charges: { provider: string; billable: boolean }[] };
}

const deps = (providers: Record<string, FareProvider>, order = ["kiwi", "serpapi"]) => ({
  http: liveHttp(fetch),
  cache: liveCache(null),
  order: order as ("kiwi" | "serpapi")[],
  providers,
});

beforeEach(() => resetFareProviders());

describe("airports", () => {
  it("resolves codes, cities with several airports, cities and home", () => {
    expect(resolveAirports("MNL")?.codes).toEqual(["MNL"]);
    expect(resolveAirports("Tokyo")?.codes).toEqual(["HND", "NRT"]);
    expect(resolveAirports("london")?.codes).toContain("LGW");
    expect(resolveAirports("Cebu")?.codes[0]).toBe("CEB");
    expect(resolveAirports("Cebu")?.country).toBe("PH");
    expect(resolveAirports("Zzyzxville")).toBeNull();
    const home = homeAirports({ name: "Quezon City", lat: 14.68, lng: 121.04, country: "PH" });
    expect(home?.codes[0]).toBe("MNL");
    expect(home?.label).toBe("Quezon City");
  });
});

describe("arguments", () => {
  it("checks dates and fills currency from the departure country", () => {
    const q = trip();
    expect(q.currency).toBe("PHP");
    expect(q.from.pick?.codes).toEqual(["MNL"]);
    expect(q.adults).toBe(1);
    expect(fareQuery({ from: "London", to: "Paris", depart: "2027-05-02" }, person).currency).toBe(
      "GBP",
    );
    expect(() => trip({ depart: "2020-01-01" })).toThrow(/past/);
    expect(() => trip({ return: "2027-03-01" })).toThrow(/before/);
    expect(() => trip({ depart: "March" })).toThrow(/YYYY-MM-DD/);
    expect(() => trip({ from: "here" })).toThrow(/home city/);
  });

  it("maps a query to Kiwi's and Google's parameters", () => {
    const k = kiwiArgs(trip({ cabin: "business", max_stops: 0 }));
    expect(k).toMatchObject({
      flyFrom: "MNL",
      flyTo: "HND,NRT",
      departureDate: "12/03/2027",
      returnDate: "19/03/2027",
      cabinClass: "C",
      currency: "PHP",
      max_sector_stopovers: 0,
    });
    const month = kiwiArgs(trip({ depart: "2027-04", return: undefined, nights: 5 }));
    expect(month).toMatchObject({ departureDate: "01/04/2027", departureDateTo: "30/04/2027" });
    expect(month.nights_in_dst_from).toBe(5);
    expect(serpParams(trip())).toMatchObject({
      engine: "google_flights",
      departure_id: "MNL",
      arrival_id: "HND,NRT",
      type: "1",
      gl: "ph",
    });
    // Google needs codes and exact dates.
    expect(serpParams(trip({ depart: "2027-04", return: undefined }))).toBeNull();
    expect(serpParams(trip({ to: "Zzyzxville" }))).toBeNull();
  });
});

describe("providers", () => {
  it("parses Kiwi's recorded answer", () => {
    expect(KIWI.options).toHaveLength(6);
    const o = KIWI.options[0];
    expect(o?.price).toBe(17772);
    expect(o?.out).toMatchObject({ from: "MNL", to: "NRT", stops: 0, depart: "2027-03-12T12:15" });
    expect(o?.airlines).toContain("Cebu Pacific");
    expect(o?.back?.to).toBe("MNL");
    expect(new URL(o?.link ?? "").hostname).toMatch(/kiwi\.com$/);
    expect(o?.bags).toEqual({ cabin: 1, checked: 0 });
  });

  it("parses Google Flights' recorded answer", () => {
    expect(SERP.options).toHaveLength(6);
    expect(SERP.options[0]?.price).toBe(16057);
    expect(SERP.options[0]?.out.from).toBe("MNL");
    expect(SERP.typical).toMatchObject({ low: 13000, high: 29500, level: "typical" });
    expect(SERP.outboundOnly).toBe(true);
    expect(new URL(SERP.searchUrl ?? "").hostname).toBe("www.google.com");
  });

  it("drops booking links that point anywhere else", () => {
    const r = parseKiwi({
      itineraries: [
        {
          price: 1,
          bookingUrl: "https://evil.example/kiwi.com",
          outbound: {
            route: ["MNL", "CEB"],
            departureTime: "2027-01-01T10:00:00",
            arrivalTime: "2027-01-01T11:00:00",
          },
        },
      ],
    });
    expect(r.options[0]?.link).toBeUndefined();
  });
});

describe("the chain", () => {
  it("uses Kiwi first and never pays when it answers", async () => {
    const kiwi = provider("kiwi", () => KIWI);
    const serp = provider("serpapi", () => SERP);
    const m = meter();
    const a = await searchFares(deps({ kiwi, serpapi: serp }), trip(), { meter: m });
    expect(a.provider).toBe("kiwi");
    expect(serp.calls).toBe(0);
    expect(m.charges).toEqual([]);
  });

  it("falls back to Google Flights and charges one search", async () => {
    const kiwi = provider("kiwi", () => {
      throw new Error("down");
    });
    const serp = provider("serpapi", () => SERP);
    const m = meter();
    const d = deps({ kiwi, serpapi: serp });
    const a = await searchFares(d, trip(), { meter: m });
    expect(a.provider).toBe("serpapi");
    expect(m.charges).toEqual([{ provider: "serpapi", billable: true }]);
    // The same search again comes from the cache: no call, no charge.
    await searchFares(d, trip(), { meter: m });
    expect(serp.calls).toBe(1);
    expect(m.charges).toHaveLength(1);
  });

  it("never uses the paid provider without a meter (refreshes, watches)", async () => {
    const kiwi = provider("kiwi", () => {
      throw new Error("down");
    });
    const serp = provider("serpapi", () => SERP);
    await expect(searchFares(deps({ kiwi, serpapi: serp }), trip())).rejects.toMatchObject({
      code: "providers_down",
    });
    expect(serp.calls).toBe(0);
  });

  it("tells the model why Google was left out", async () => {
    const kiwi = provider("kiwi", () => {
      throw new Error("down");
    });
    const serp = provider("serpapi", () => SERP);
    const err = await searchFares(deps({ kiwi, serpapi: serp }), trip(), {
      meter: meter("Today's Google Flights searches are used up."),
    }).catch((e) => e);
    expect(err.code).toBe("providers_down");
    expect(err.message).toContain("used up");
    expect(err.message).toContain("google.com/travel/flights");
    expect(serp.calls).toBe(0);
  });

  it("doesn't charge for an empty Google search", async () => {
    const kiwi = provider("kiwi", () => ({ options: [] }));
    const serp = provider("serpapi", () => ({ options: [] }));
    const m = meter();
    await expect(
      searchFares(deps({ kiwi, serpapi: serp }), trip(), { meter: m }),
    ).rejects.toMatchObject({
      code: "no_fares",
    });
    expect(m.charges).toEqual([{ provider: "serpapi", billable: false }]);
  });

  it("asks Google first when the person wants the comparison", async () => {
    const kiwi = provider("kiwi", () => KIWI);
    const serp = provider("serpapi", () => SERP);
    const a = await searchFares(deps({ kiwi, serpapi: serp }), trip(), {
      meter: meter(),
      preferGoogle: true,
    });
    expect(a.provider).toBe("serpapi");
    expect(kiwi.calls).toBe(0);
  });

  it("skips Google for a month search", async () => {
    const kiwi = provider("kiwi", () => {
      throw new Error("down");
    });
    const serp = provider("serpapi", () => SERP);
    await expect(
      searchFares(deps({ kiwi, serpapi: serp }), trip({ depart: "2027-04", return: undefined }), {
        meter: meter(),
      }),
    ).rejects.toMatchObject({ code: "providers_down" });
    expect(serp.calls).toBe(0);
  });
});

describe("the card", () => {
  it("shows the options and gives the model five short lines", () => {
    const q = trip({ sort: "cheapest" });
    const built = faresCard(q, {
      ...SERP,
      provider: "serpapi",
      fetchedAt: new Date(),
      stale: false,
    });
    expect(built.card.component).toBe("Fares");
    expect(built.card.cheapest).toBe(16057);
    const prices = (built.card.options as { price: number }[]).map((o) => o.price);
    expect(prices).toEqual([...prices].sort((a, b) => a - b));
    const lines = built.text.split("\n");
    expect(lines.filter((l) => /^\d\. /.test(l))).toHaveLength(5);
    expect(built.text).toContain("Typical");
    expect(built.text.length).toBeLessThan(1200);
    expect(built.preview).toMatch(/from/);
    expect((built.card.live as { source: { name: string } }).source.name).toBe("Google Flights");
  });
});

describe("engine", () => {
  it("offers live.fares with Kiwi and keeps the trip for refreshes", async () => {
    const engine = new LiveEngine(liveHttp(fetch), liveCache(null), {
      openMeteo: false,
      unofficial: false,
      kiwiMcpUrl: "https://mcp.kiwi.com",
    });
    engine.fareProviders = { kiwi: provider("kiwi", () => KIWI) };
    expect(engine.available()).toContain("fares");
    const r = await engine.run(
      "fares",
      { from: "Manila", to: "Tokyo", depart: "2027-03-12", return: "2027-03-19" },
      person,
    );
    expect(r.built.card.component).toBe("Fares");
    expect(r.resolved).toMatchObject({ from: "Manila", to: "Tokyo", currency: "PHP" });
    expect(r.personal).toBeUndefined();
    const off = new LiveEngine(liveHttp(fetch), liveCache(null), {
      openMeteo: false,
      unofficial: false,
    });
    expect(off.available()).not.toContain("fares");
  });
});
