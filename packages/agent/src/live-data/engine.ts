/**
 * The live data engine (RICH-CARDS-PLAN §4): one function per data tool that resolves its
 * arguments (a place to coordinates, a name to a ticker), fetches through the shared cache and
 * builds the card. Tools, the refresh route and pinned widgets all call it, so a refreshed card is
 * the same card. `resolved` is what the `live_cards` row keeps to repeat the call without the model.
 */
import {
  airCard,
  alertCard,
  type Built,
  bookCard,
  currencyCard,
  definitionCard,
  filmCard,
  flightCard,
  holidaysCard,
  METRIC,
  parcelCard,
  quakeCard,
  quoteCard,
  scoreCard,
  standingsCard,
  stormCard,
  summaryCard,
  sunMoonCard,
  type Units,
  unitsForZone,
  watchlistCard,
  weatherCard,
  worldClockCard,
} from "./cards.ts";
import { type LiveCache, LiveDataError, type LiveHttp } from "./core.ts";
import {
  FARE_PROVIDERS,
  type FareProviderId,
  type FaresAffiliate,
  type FaresBilling,
  type FaresCompare,
  type FaresDeps,
  type FaresMeter,
  fareQuery,
  faresCard,
  searchFares,
  withAffiliate,
  withCompare,
} from "./fares.ts";
import {
  anyQuote,
  CHART_RANGES,
  type ChartRange,
  FRANKFURTER,
  fxRates,
  type MarketsDeps,
  movers,
  OVERVIEW,
  type QuoteData,
  stocksAvailable,
} from "./markets.ts";
import { cityOfZone, lookupPlace, type Place } from "./places.ts";
import { isZone, localParts } from "./tz.ts";
import { getWeather, NWS, nwsAlerts, OPEN_METEO_AIR, openMeteoAir } from "./weather.ts";
import {
  define,
  findBook,
  findFilm,
  flightStatus,
  holidays,
  LEAGUES,
  quakes,
  scoreboard,
  standings,
  storms,
  trackParcel,
  type WorldDeps,
  wikiSummary,
} from "./world.ts";

export interface LiveConfig {
  /** Open-Meteo may be called: its key, or a server that doesn't bill people (its free tier is non-commercial). */
  openMeteo: boolean;
  openMeteoKey?: string;
  coingeckoKey?: string;
  finnhubKey?: string;
  /** Public endpoints without published API terms (Yahoo Finance, ESPN). */
  unofficial: boolean;
  aviationstackKey?: string;
  seventeenTrackKey?: string;
  tmdbKey?: string;
  /** Flight fares (docs/FLIGHT-SEARCH-PLAN.md): Kiwi.com's MCP server, free and keyless. */
  kiwiMcpUrl?: string;
  /** Google Flights through SerpApi: paid per search, used only by a run that may pay for it. */
  serpapiKey?: string;
  /** The fares chain, in order (default Kiwi, then Google Flights). */
  faresOrder?: FareProviderId[];
  /** Charging for Google Flights searches on the server's key (the tool's meter). */
  faresBilling?: FaresBilling;
  /** Affiliate booking links (FLIGHT-SEARCH-PLAN Phase 4): a template and the hosts it wraps. */
  faresAffiliate?: FaresAffiliate;
  /** The Aviasales compare link under Fares cards (LIVE_FARES_COMPARE_URL). */
  faresCompare?: FaresCompare;
}

/** What the engine knows about the person a run acts for. */
export interface LivePerson {
  homePlace?: Place | null;
  timezone?: string | null;
  units?: Partial<Units> | null;
}

export interface LiveResult {
  built: Built;
  /** The arguments to repeat this call (a place already looked up), stored on the card. */
  resolved: Record<string, unknown>;
  /** A card only its person may see (a parcel, a flight). */
  personal?: boolean;
  /** Fetched again sooner than this is pointless, in seconds. */
  minRefresh: number;
}

export type LiveTool =
  | "weather"
  | "air"
  | "sun"
  | "alerts"
  | "quote"
  | "markets"
  | "fx"
  | "time"
  | "holidays"
  | "quakes"
  | "storms"
  | "lookup"
  | "define"
  | "book"
  | "film"
  | "sports"
  | "flight"
  | "fares"
  | "parcel";

export class LiveEngine {
  readonly http: LiveHttp;
  readonly cache: LiveCache;
  readonly config: LiveConfig;
  /** Tests swap the fare providers. */
  fareProviders?: FaresDeps["providers"];
  constructor(http: LiveHttp, cache: LiveCache, config: LiveConfig) {
    this.http = http;
    this.cache = cache;
    this.config = config;
  }

  private get markets(): MarketsDeps {
    return {
      http: this.http,
      cache: this.cache,
      coingeckoKey: this.config.coingeckoKey,
      finnhubKey: this.config.finnhubKey,
      unofficial: this.config.unofficial,
    };
  }
  private get world(): WorldDeps {
    return {
      http: this.http,
      cache: this.cache,
      unofficial: this.config.unofficial,
      aviationstackKey: this.config.aviationstackKey,
      seventeenTrackKey: this.config.seventeenTrackKey,
      tmdbKey: this.config.tmdbKey,
    };
  }

  /** Which tools this server can answer. */
  available(): LiveTool[] {
    const all: LiveTool[] = [
      "weather",
      "air",
      "sun",
      "alerts",
      "quote",
      "fx",
      "time",
      "holidays",
      "quakes",
      "storms",
      "lookup",
      "define",
      "book",
    ];
    if (stocksAvailable(this.markets)) all.push("markets");
    if (this.config.unofficial) all.push("sports");
    if (this.config.aviationstackKey) all.push("flight");
    if (this.config.kiwiMcpUrl || this.config.serpapiKey) all.push("fares");
    if (this.config.seventeenTrackKey) all.push("parcel");
    if (this.config.tmdbKey) all.push("film");
    if (!this.config.openMeteo) return all.filter((t) => t !== "air");
    return all;
  }

  /** A place from what the person said, their home place, or their time zone's city. */
  async place(
    raw: unknown,
    person: LivePerson,
  ): Promise<{ place: Place; tz: string; note?: string }> {
    if (raw && typeof raw === "object" && typeof (raw as Place).lat === "number") {
      const p = raw as Place;
      return { place: p, tz: p.tz && isZone(p.tz) ? p.tz : "UTC" };
    }
    const q = typeof raw === "string" ? raw.trim() : "";
    const here = !q || /^(here|home|my (city|place|location)|current location|near me)$/i.test(q);
    if (here && person.homePlace?.lat !== undefined) {
      const p = person.homePlace;
      return { place: p, tz: p.tz && isZone(p.tz) ? p.tz : (person.timezone ?? "UTC") };
    }
    if (here) {
      const tz =
        person.timezone && isZone(person.timezone) && person.timezone.includes("/")
          ? person.timezone
          : null;
      if (!tz)
        throw new LiveDataError(
          "no_place",
          "Which place? The person has no home city set (Settings → Cards).",
        );
      const p = await lookupPlace(this.http, this.cache, cityOfZone(tz));
      return {
        place: p,
        tz: p.tz ?? tz,
        note: `Used ${p.name} from the person's time zone; they can set a home city in Settings → Cards.`,
      };
    }
    const p = await lookupPlace(this.http, this.cache, q);
    return { place: p, tz: p.tz && isZone(p.tz) ? p.tz : "UTC" };
  }

  /** The person's units: what they chose, else their time zone's (never the place's). */
  units(person: LivePerson, _country?: string): Units {
    return { ...unitsForZone(person.timezone), ...(person.units ?? {}) } as Units;
  }

  async run(
    tool: LiveTool,
    args: Record<string, unknown>,
    person: LivePerson,
    opts: { force?: boolean; meter?: FaresMeter } = {},
  ): Promise<LiveResult> {
    const r = await this.runRaw(tool, args, person, opts);
    // The card carries its own words: Copy as text, screen readers and older apps' fallbacks.
    r.built.card = { ...r.built.card, summary: r.built.text.slice(0, 600) };
    return r;
  }

  private async runRaw(
    tool: LiveTool,
    args: Record<string, unknown>,
    person: LivePerson,
    opts: { force?: boolean; meter?: FaresMeter },
  ): Promise<LiveResult> {
    if (!this.available().includes(tool))
      throw new LiveDataError("no_provider", `${tool} data isn't set up on this server.`);
    const force = opts.force ?? false;
    switch (tool) {
      case "weather": {
        const { place, tz, note } = await this.place(args.place, person);
        const w = await getWeather(
          {
            http: this.http,
            cache: this.cache,
            openMeteo: this.config.openMeteo,
            openMeteoKey: this.config.openMeteoKey,
          },
          place,
          tz,
          force,
        );
        const alerts =
          place.country === "US" ? await nwsAlerts(this.http, place).catch(() => []) : [];
        const built = weatherCard(place, w.data, {
          when: typeof args.when === "string" ? args.when : undefined,
          units: this.units(person, place.country),
          alerts,
          fetchedAt: w.fetchedAt,
          stale: w.stale,
        });
        if (note) built.text = `${built.text} (${note})`;
        return {
          built,
          resolved: { place: { ...place, tz }, when: args.when ?? "now" },
          minRefresh: 60,
        };
      }
      case "alerts": {
        const { place, tz } = await this.place(args.place, person);
        if (place.country && place.country !== "US")
          return {
            built: alertCard(place, tz, [], new Date(), NWS),
            resolved: { place: { ...place, tz } },
            minRefresh: 60,
          };
        const r = await this.cache.get(
          NWS.id,
          `${place.lat.toFixed(2)},${place.lng.toFixed(2)}`,
          300,
          () => nwsAlerts(this.http, place),
          { force, minAgeSeconds: 60 },
        );
        return {
          built: alertCard(place, tz, r.value, r.fetchedAt, NWS),
          resolved: { place: { ...place, tz } },
          minRefresh: 60,
        };
      }
      case "air": {
        const { place, tz } = await this.place(args.place, person);
        const r = await this.cache.get(
          OPEN_METEO_AIR.id,
          `${place.lat.toFixed(1)},${place.lng.toFixed(1)}|${tz}`,
          3600,
          () => openMeteoAir(this.http, place, tz, this.config.openMeteoKey),
          { force, minAgeSeconds: 300 },
        );
        return {
          built: airCard(place, tz, r.value, r.fetchedAt, OPEN_METEO_AIR),
          resolved: { place: { ...place, tz } },
          minRefresh: 300,
        };
      }
      case "sun": {
        const { place, tz } = await this.place(args.place, person);
        const date =
          typeof args.date === "string" && /^\d{4}-\d{2}-\d{2}$/.test(args.date)
            ? args.date
            : localParts(new Date(), tz).date;
        return {
          built: sunMoonCard(place, tz, date),
          resolved: { place: { ...place, tz }, date: args.date },
          minRefresh: 3600,
        };
      }
      case "quote": {
        const symbols = (Array.isArray(args.symbols) ? args.symbols : [args.symbols])
          .filter((s): s is string => typeof s === "string" && !!s.trim())
          .slice(0, 12);
        if (!symbols.length)
          throw new LiveDataError("bad_symbol", "Name a ticker or coin, like AAPL or BTC.");
        const range = (
          CHART_RANGES.includes(args.range as ChartRange) ? args.range : "1D"
        ) as ChartRange;
        const vs =
          typeof args.currency === "string" && /^[a-z]{3}$/i.test(args.currency)
            ? args.currency.toLowerCase()
            : "usd";
        if (symbols.length === 1) {
          const r = await anyQuote(this.markets, symbols[0] as string, { range, force, vs });
          return {
            built: quoteCard(r.quote, r.fetchedAt, r.stale),
            resolved: { symbols, range, currency: vs },
            minRefresh: 15,
          };
        }
        const results = await Promise.allSettled(
          symbols.map((s) => anyQuote(this.markets, s, { force, vs })),
        );
        const ok = results.filter(
          (r): r is PromiseFulfilledResult<Awaited<ReturnType<typeof anyQuote>>> =>
            r.status === "fulfilled",
        );
        if (!ok.length) throw (results[0] as PromiseRejectedResult).reason;
        const missing = symbols.filter((_, i) => results[i]?.status === "rejected");
        const built = watchlistCard(
          typeof args.title === "string" ? args.title : undefined,
          ok.map((r) => r.value.quote),
          ok[0]?.value.fetchedAt ?? new Date(),
          ok.some((r) => r.value.stale),
        );
        if (missing.length) built.text += ` (No data for ${missing.join(", ")}.)`;
        return { built, resolved: { symbols, currency: vs, title: args.title }, minRefresh: 15 };
      }
      case "markets": {
        const view = String(args.view ?? "overview");
        if (view === "overview") {
          const results = await Promise.allSettled(
            OVERVIEW.map((s) => anyQuote(this.markets, s, { force })),
          );
          const quotes = results.flatMap((r) =>
            r.status === "fulfilled" ? [r.value.quote] : [],
          ) as QuoteData[];
          if (!quotes.length) throw new LiveDataError("upstream", "No market data right now.");
          return {
            built: watchlistCard("Markets", quotes, new Date(), false),
            resolved: { view },
            minRefresh: 30,
          };
        }
        const kind = view === "losers" ? "losers" : view === "active" ? "active" : "gainers";
        const r = await movers(this.markets, kind);
        const title = { gainers: "Top gainers", losers: "Top losers", active: "Most active" }[kind];
        return {
          built: watchlistCard(title, r.quotes, r.fetchedAt, r.stale),
          resolved: { view },
          minRefresh: 60,
        };
      }
      case "fx": {
        const to = (Array.isArray(args.to) ? args.to : [args.to])
          .filter((s): s is string => typeof s === "string")
          .slice(0, 8);
        const amount =
          typeof args.amount === "number" && Number.isFinite(args.amount) && args.amount > 0
            ? args.amount
            : 1;
        const r = await fxRates(
          { http: this.http, cache: this.cache },
          String(args.from ?? "USD"),
          to,
          {
            amount,
            date:
              typeof args.date === "string" && /^\d{4}-\d{2}-\d{2}$/.test(args.date)
                ? args.date
                : undefined,
            trendDays: to.length === 1 ? 30 : undefined,
            force,
          },
        );
        return {
          built: currencyCard(r.data, r.fetchedAt, r.stale, FRANKFURTER),
          resolved: {
            from: r.data.base,
            to: r.data.rates.map((x) => x.to),
            amount,
            date: args.date,
          },
          minRefresh: 600,
        };
      }
      case "time": {
        const names = (Array.isArray(args.places) ? args.places : [args.places])
          .filter((s): s is string => typeof s === "string" && !!s.trim())
          .slice(0, 8);
        if (!names.length) throw new LiveDataError("no_place", "Name the places.");
        const places = await Promise.all(
          names.map(async (n) => {
            if (isZone(n) && n.includes("/"))
              return { place: { name: cityOfZone(n), lat: 0, lng: 0, tz: n } as Place, tz: n };
            return this.place(n, person);
          }),
        );
        const at =
          typeof args.at === "string" && !Number.isNaN(Date.parse(args.at))
            ? new Date(args.at).toISOString()
            : undefined;
        return {
          built: worldClockCard(places, at),
          resolved: { places: names, at: args.at },
          minRefresh: 3600,
        };
      }
      case "holidays": {
        const country = String(args.country ?? person.homePlace?.country ?? "").toUpperCase();
        const year =
          typeof args.year === "number"
            ? args.year
            : Number(
                localParts(
                  new Date(),
                  person.timezone && isZone(person.timezone) ? person.timezone : "UTC",
                ).year,
              );
        const r = await holidays(this.world, country, year);
        return {
          built: holidaysCard(country, r.list, r.fetchedAt, {
            upcoming: args.upcoming !== false && !args.year,
            tz: person.timezone ?? undefined,
          }),
          resolved: { country, year: args.year, upcoming: args.upcoming },
          minRefresh: 3600,
        };
      }
      case "quakes": {
        const near =
          args.place || args.near ? await this.place(args.place ?? args.near, person) : null;
        const r = await quakes(this.world, {
          near: near ? near.place : undefined,
          radiusKm: typeof args.radius_km === "number" ? args.radius_km : undefined,
          minMagnitude: typeof args.min_magnitude === "number" ? args.min_magnitude : undefined,
          days: typeof args.days === "number" ? args.days : near ? 7 : 1,
        });
        return {
          built: quakeCard(
            r.list,
            r.fetchedAt,
            near ? { name: near.place.name, lat: near.place.lat, lng: near.place.lng } : undefined,
          ),
          resolved: {
            place: near ? { ...near.place, tz: near.tz } : undefined,
            min_magnitude: args.min_magnitude,
            radius_km: args.radius_km,
            days: args.days,
          },
          minRefresh: 60,
        };
      }
      case "storms": {
        const near = args.place ? await this.place(args.place, person) : null;
        const r = await storms(this.world, near?.place);
        return {
          built: stormCard(
            r.list,
            r.fetchedAt,
            near ? { name: near.place.name, lat: near.place.lat, lng: near.place.lng } : undefined,
          ),
          resolved: { place: near ? { ...near.place, tz: near.tz } : undefined },
          minRefresh: 60,
        };
      }
      case "lookup": {
        const r = await wikiSummary(
          this.world,
          String(args.topic ?? ""),
          typeof args.lang === "string" ? args.lang : "en",
        );
        return {
          built: summaryCard(r.summary, r.fetchedAt),
          resolved: { topic: args.topic, lang: args.lang },
          minRefresh: 86400,
        };
      }
      case "define": {
        const r = await define(this.world, String(args.word ?? ""));
        return {
          built: definitionCard(r.def, r.fetchedAt),
          resolved: { word: args.word },
          minRefresh: 86400,
        };
      }
      case "book": {
        const r = await findBook(this.world, String(args.query ?? ""));
        return {
          built: bookCard(r.book, r.fetchedAt),
          resolved: { query: args.query },
          minRefresh: 86400,
        };
      }
      case "film": {
        const r = await findFilm(
          this.world,
          String(args.query ?? ""),
          (args.kind as "movie" | "show") ?? "any",
        );
        return {
          built: filmCard(r.film, r.fetchedAt),
          resolved: { query: args.query, kind: args.kind },
          minRefresh: 86400,
        };
      }
      case "sports": {
        const league = String(args.league ?? "")
          .toLowerCase()
          .replace(/[\s.-]/g, "");
        const alias: Record<string, string> = {
          premierleague: "epl",
          pl: "epl",
          championsleague: "ucl",
          formula1: "f1",
          formulaone: "f1",
          serie_a: "seriea",
        };
        const l = alias[league] ?? league;
        if (!LEAGUES[l])
          throw new LiveDataError("bad_league", `Leagues: ${Object.keys(LEAGUES).join(", ")}.`);
        if (args.view === "standings") {
          const r = await standings(this.world, l);
          return {
            built: standingsCard(
              r.league,
              r.groups,
              r.fetchedAt,
              typeof args.team === "string" ? args.team : undefined,
            ),
            resolved: { league: l, view: "standings", team: args.team },
            minRefresh: 300,
          };
        }
        const r = await scoreboard(this.world, l, {
          team: typeof args.team === "string" ? args.team : undefined,
          date: typeof args.date === "string" ? args.date : undefined,
        });
        return {
          built: scoreCard(LEAGUES[l]?.name ?? l, r.games, r.fetchedAt),
          resolved: { league: l, team: args.team, date: args.date },
          minRefresh: 10,
        };
      }
      case "flight": {
        const r = await flightStatus(
          this.world,
          String(args.flight ?? ""),
          typeof args.date === "string" ? args.date : undefined,
        );
        return {
          built: flightCard(r.flight, r.fetchedAt),
          resolved: { flight: args.flight, date: args.date },
          personal: true,
          minRefresh: 30,
        };
      }
      case "fares": {
        const q = fareQuery(args, person);
        const a = await searchFares(
          {
            http: this.http,
            cache: this.cache,
            order: this.config.faresOrder?.length ? this.config.faresOrder : FARE_PROVIDERS,
            kiwiUrl: this.config.kiwiMcpUrl,
            serpapiKey: this.config.serpapiKey,
            providers: this.fareProviders,
          },
          q,
          { force, meter: opts.meter, preferGoogle: args.compare_google === true },
        );
        return {
          built: withCompare(
            withAffiliate(faresCard(q, a), this.config.faresAffiliate),
            this.config.faresCompare,
          ),
          // A refresh repeats the same trip; the places stay as the person named them.
          resolved: {
            from: args.from,
            to: args.to,
            depart: q.depart,
            ...(q.ret ? { return: q.ret } : {}),
            ...(q.nights ? { nights: q.nights } : {}),
            adults: q.adults,
            children: q.children,
            infants: q.infants,
            cabin: q.cabin,
            ...(q.maxStops !== undefined ? { max_stops: q.maxStops } : {}),
            sort: q.sort,
            currency: q.currency,
          },
          minRefresh: 300,
        };
      }
      case "parcel": {
        const r = await trackParcel(this.world, String(args.tracking ?? ""));
        return {
          built: parcelCard(r.parcel, r.fetchedAt),
          resolved: { tracking: args.tracking },
          personal: true,
          minRefresh: 300,
        };
      }
    }
  }
}

export { METRIC };
