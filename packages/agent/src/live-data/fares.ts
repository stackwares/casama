/**
 * Flight fares (docs/FLIGHT-SEARCH-PLAN.md): real prices and booking links from a chain of
 * providers, Kiwi.com's hosted MCP server first (free, no key), then Google Flights through SerpApi
 * (paid per search, only with a meter that may charge for it). Results are public data, kept in the
 * shared live cache for 30 minutes per route, dates, travellers, cabin and currency.
 */
import { createHash } from "node:crypto";
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StreamableHTTPClientTransport } from "@modelcontextprotocol/sdk/client/streamableHttp.js";
import {
  type AirportPick,
  airportByCode,
  currencyFor,
  homeAirports,
  resolveAirports,
} from "./airports.ts";
import { type Built, liveBlock } from "./cards.ts";
import { type LiveCache, LiveDataError, type LiveHttp, type LiveSource } from "./core.ts";
import type { Place } from "./places.ts";

export type FareProviderId = "kiwi" | "serpapi";
export const FARE_PROVIDERS: FareProviderId[] = ["kiwi", "serpapi"];
export type Cabin = "economy" | "premium" | "business" | "first";
export type FareSort = "best" | "cheapest" | "fastest";

export const KIWI: LiveSource = { id: "kiwi", name: "Kiwi.com", url: "https://www.kiwi.com/" };
export const GOOGLE_FLIGHTS: LiveSource = {
  id: "serpapi",
  name: "Google Flights",
  url: "https://www.google.com/travel/flights",
};
const SOURCES: Record<FareProviderId, LiveSource> = { kiwi: KIWI, serpapi: GOOGLE_FLIGHTS };

/** Seconds a search is kept for everyone. Fares move; half an hour is the most we trust one. */
export const FARES_TTL = 1800;
/** Options kept on a card; the model reads the first five. */
const MAX_OPTIONS = 20;
/** Where each provider's booking links may point. */
const LINK_HOSTS: Record<FareProviderId, RegExp> = {
  kiwi: /(^|\.)kiwi\.com$/,
  serpapi: /(^|\.)google\.com$/,
};

/** A search as the providers get it, after places and dates are checked. */
export interface FareQuery {
  from: { text: string; pick: AirportPick | null };
  to: { text: string; pick: AirportPick | null };
  /** YYYY-MM-DD, or YYYY-MM for the cheapest day in that month. */
  depart: string;
  ret?: string;
  /** For a month search with a return: nights at the destination. */
  nights?: number;
  adults: number;
  children: number;
  infants: number;
  cabin: Cabin;
  maxStops?: number;
  sort: FareSort;
  currency: string;
}

export interface FareLeg {
  from: string;
  to: string;
  /** Local times, YYYY-MM-DDTHH:MM. */
  depart: string;
  arrive: string;
  minutes: number;
  stops: number;
  /** Airports in between. */
  via: string[];
  airlines: string[];
  flights: string[];
}

export interface FareOption {
  id: string;
  /** Total for every traveller (both ways for a return trip). */
  price: number;
  airlines: string[];
  minutes: number;
  out: FareLeg;
  back?: FareLeg;
  bags?: { cabin: number; checked: number };
  link?: string;
}

export interface FareSearch {
  options: FareOption[];
  /** Google's usual range for this trip, and where today's lowest sits. */
  typical?: { low: number; high: number; level?: string };
  /** A page with every option (Google Flights). */
  searchUrl?: string;
  /** Google shows the outbound leg; the return is picked on its page. */
  outboundOnly?: boolean;
}

export interface FareProvider {
  id: FareProviderId;
  /** Paid providers run only with a meter that allows and records them. */
  paid: boolean;
  search(q: FareQuery, signal?: AbortSignal): Promise<FareSearch>;
}

/** Lets a run use (and pay for) a paid provider: limits, credits, and the usage row. */
export interface FaresMeter {
  /** Null when the provider may run now; otherwise why not, in a sentence. */
  allow(provider: FareProviderId): Promise<string | null>;
  /**
   * Records one real call. `billable` is false when it found nothing: the provider still cost
   * something upstream, but nobody pays for an empty search.
   */
  charge(provider: FareProviderId, info: { route: string; billable: boolean }): Promise<void>;
}

export interface FaresBilling {
  /** What a workspace is charged per Google Flights search that found fares, in USD. */
  priceUsd: number;
  /** What one SerpApi search costs the server, for the margin view (D-395). */
  upstreamUsd: number;
  /** Searches the whole server may make a month (just under the SerpApi plan). */
  monthlyCap: number;
  /** Billing is on: charge credits. Off (self-hosted): record the cost only. */
  billing: boolean;
}

export interface FaresDeps {
  http: LiveHttp;
  cache: LiveCache;
  order: FareProviderId[];
  kiwiUrl?: string;
  serpapiKey?: string;
  /** Tests swap the providers. */
  providers?: Partial<Record<FareProviderId, FareProvider>>;
}

// ---------- places, dates, arguments ----------

const DAY = /^\d{4}-\d{2}-\d{2}$/;
const MONTH = /^\d{4}-\d{2}$/;

function today(tz?: string | null) {
  try {
    return new Intl.DateTimeFormat("en-CA", { timeZone: tz ?? "UTC" }).format(new Date());
  } catch {
    return new Date().toISOString().slice(0, 10);
  }
}

function checkDate(v: unknown, what: string, tz?: string | null): string {
  const s = typeof v === "string" ? v.trim() : "";
  if (!DAY.test(s) && !MONTH.test(s))
    throw new LiveDataError(
      "bad_date",
      `Give the ${what} date as YYYY-MM-DD, or a month as YYYY-MM.`,
    );
  const now = today(tz);
  if (DAY.test(s) && (Number.isNaN(Date.parse(s)) || s < now))
    throw new LiveDataError("bad_date", `The ${what} date ${s} is in the past (today is ${now}).`);
  if (MONTH.test(s) && s < now.slice(0, 7))
    throw new LiveDataError("bad_date", `${s} is in the past (today is ${now}).`);
  return s;
}

function place(text: unknown, home: Place | null | undefined, what: string) {
  const t = typeof text === "string" ? text.trim() : "";
  if (!t) throw new LiveDataError("bad_place", `Where ${what}? Name a city or airport.`);
  if (/^(here|home|my (city|place|location)|near me)$/i.test(t)) {
    if (!home?.name)
      throw new LiveDataError(
        "no_place",
        "Which city? The person has no home city set (Settings → Cards).",
      );
    const pick = homeAirports(home);
    if (!pick) throw new LiveDataError("bad_place", `No airport with flights near ${home.name}.`);
    return { text: pick.codes[0] as string, pick };
  }
  return { text: t, pick: resolveAirports(t) };
}

const int = (v: unknown, lo: number, hi: number, dflt: number) => {
  const n = typeof v === "number" ? Math.round(v) : Number.NaN;
  return Number.isFinite(n) ? Math.min(hi, Math.max(lo, n)) : dflt;
};

/** The tool's arguments → a checked query. */
export function fareQuery(
  args: Record<string, unknown>,
  person: { homePlace?: Place | null; timezone?: string | null },
): FareQuery {
  const from = place(args.from, person.homePlace, "from");
  const to = place(args.to, person.homePlace, "to");
  const depart = checkDate(args.depart, "departure", person.timezone);
  const ret = args.return ? checkDate(args.return, "return", person.timezone) : undefined;
  if (ret && DAY.test(depart) && DAY.test(ret) && ret < depart)
    throw new LiveDataError("bad_date", "The return date is before the departure date.");
  if (ret && MONTH.test(ret) && !MONTH.test(depart))
    throw new LiveDataError(
      "bad_date",
      "Give the return as a date, or search a month with nights.",
    );
  const cabin = (["economy", "premium", "business", "first"] as const).includes(args.cabin as Cabin)
    ? (args.cabin as Cabin)
    : "economy";
  const sort = (["best", "cheapest", "fastest"] as const).includes(args.sort as FareSort)
    ? (args.sort as FareSort)
    : "best";
  const currency =
    typeof args.currency === "string" && /^[a-z]{3}$/i.test(args.currency)
      ? args.currency.toUpperCase()
      : currencyFor(from.pick?.country ?? person.homePlace?.country);
  return {
    from,
    to,
    depart,
    ret,
    nights: args.nights === undefined ? undefined : int(args.nights, 1, 60, 7),
    adults: int(args.adults, 1, 9, 1),
    children: int(args.children, 0, 8, 0),
    infants: int(args.infants, 0, 4, 0),
    cabin,
    maxStops: args.max_stops === undefined ? undefined : int(args.max_stops, 0, 2, 2),
    sort,
    currency,
  };
}

/** The cache key: every input that changes the answer, never the person. */
export function fareKey(q: FareQuery) {
  const where = (p: FareQuery["from"]) => p.pick?.codes.join("+") ?? p.text.toLowerCase();
  return [
    where(q.from),
    where(q.to),
    q.depart,
    q.ret ?? "",
    q.nights ?? "",
    `${q.adults}.${q.children}.${q.infants}`,
    q.cabin,
    q.maxStops ?? "",
    q.sort,
    q.currency,
  ].join("|");
}

// ---------- Kiwi.com (MCP) ----------

const KIWI_CABIN: Record<Cabin, string> = { economy: "M", premium: "W", business: "C", first: "F" };
const KIWI_SORT: Record<FareSort, string> = {
  best: "quality",
  cheapest: "price",
  fastest: "duration",
};
const dmy = (iso: string) => `${iso.slice(8, 10)}/${iso.slice(5, 7)}/${iso.slice(0, 4)}`;
const monthEnd = (ym: string) => {
  const d = new Date(Date.UTC(Number(ym.slice(0, 4)), Number(ym.slice(5, 7)), 0));
  return d.toISOString().slice(0, 10);
};

/** Kiwi's search-flight arguments for a query. */
export function kiwiArgs(q: FareQuery): Record<string, unknown> {
  const a: Record<string, unknown> = {
    // Kiwi resolves names itself; codes when we have them, so "Tokyo" means both airports.
    flyFrom: q.from.pick?.codes.join(",") ?? q.from.text,
    flyTo: q.to.pick?.codes.join(",") ?? q.to.text,
    adults: q.adults,
    children: q.children,
    infants: q.infants,
    cabinClass: KIWI_CABIN[q.cabin],
    currency: q.currency,
    locale: "en",
    sort: KIWI_SORT[q.sort],
  };
  if (MONTH.test(q.depart)) {
    const first = `${q.depart}-01`;
    const now = today();
    a.departureDate = dmy(first < now ? now : first);
    a.departureDateTo = dmy(monthEnd(q.depart));
    if (q.ret || q.nights) {
      a.nights_in_dst_from = q.nights ?? 7;
      a.nights_in_dst_to = q.nights ?? 7;
    }
  } else {
    a.departureDate = dmy(q.depart);
    if (q.ret) a.returnDate = dmy(q.ret);
  }
  if (q.maxStops !== undefined) a.max_sector_stopovers = q.maxStops;
  return a;
}

interface KiwiSegment {
  from?: string;
  to?: string;
  carrierName?: string;
  carrier?: string;
  flightNumber?: string;
}
interface KiwiLeg {
  route?: string[];
  departureTime?: string;
  arrivalTime?: string;
  durationSeconds?: number;
  stops?: number;
  segments?: KiwiSegment[];
}
interface KiwiItinerary {
  id?: string;
  price?: number;
  totalDurationSeconds?: number;
  bookingUrl?: string;
  baggage?: { cabinBag?: number; checkedBag?: number };
  outbound?: KiwiLeg;
  inbound?: KiwiLeg;
}
export interface KiwiResult {
  itineraries?: KiwiItinerary[];
  error?: string | null;
}

const hhmm = (s?: string) => (s ?? "").replace(" ", "T").slice(0, 16);
const uniq = <T>(xs: T[]) => [...new Set(xs)];

function safeLink(url: unknown, provider: FareProviderId): string | undefined {
  if (typeof url !== "string") return undefined;
  try {
    const u = new URL(url);
    return u.protocol === "https:" && LINK_HOSTS[provider].test(u.hostname)
      ? u.toString()
      : undefined;
  } catch {
    return undefined;
  }
}

function kiwiLeg(l: KiwiLeg | undefined): FareLeg | undefined {
  if (!l?.route?.length || !l.departureTime || !l.arrivalTime) return undefined;
  const segs = l.segments ?? [];
  return {
    from: l.route[0] as string,
    to: l.route[l.route.length - 1] as string,
    depart: hhmm(l.departureTime),
    arrive: hhmm(l.arrivalTime),
    minutes: Math.round((l.durationSeconds ?? 0) / 60),
    stops: l.stops ?? Math.max(0, l.route.length - 2),
    via: l.route.slice(1, -1),
    airlines: uniq(segs.map((s) => s.carrierName ?? s.carrier ?? "").filter(Boolean)),
    flights: segs.map((s) => s.flightNumber ?? "").filter(Boolean),
  };
}

const optionId = (provider: FareProviderId, price: number, legs: (FareLeg | undefined)[]) =>
  createHash("sha1")
    .update(
      `${provider}|${price}|${legs.map((l) => `${l?.depart}${l?.flights.join(",")}`).join("|")}`,
    )
    .digest("hex")
    .slice(0, 12);

export function parseKiwi(r: KiwiResult): FareSearch {
  if (r.error) throw new LiveDataError("upstream", `Kiwi.com: ${String(r.error).slice(0, 200)}`);
  const options: FareOption[] = [];
  for (const it of r.itineraries ?? []) {
    const out = kiwiLeg(it.outbound);
    if (!out || typeof it.price !== "number") continue;
    const back = kiwiLeg(it.inbound);
    options.push({
      id: optionId("kiwi", it.price, [out, back]),
      price: it.price,
      airlines: uniq([...out.airlines, ...(back?.airlines ?? [])]),
      minutes:
        Math.round((it.totalDurationSeconds ?? 0) / 60) || out.minutes + (back?.minutes ?? 0),
      out,
      ...(back ? { back } : {}),
      ...(it.baggage
        ? { bags: { cabin: it.baggage.cabinBag ?? 0, checked: it.baggage.checkedBag ?? 0 } }
        : {}),
      link: safeLink(it.bookingUrl, "kiwi"),
    });
  }
  return { options: options.slice(0, MAX_OPTIONS) };
}

/** Calls Kiwi.com's hosted MCP server (Streamable HTTP) through the given fetch. */
export function kiwiProvider(url: string, fetchImpl: typeof fetch): FareProvider {
  return {
    id: "kiwi",
    paid: false,
    async search(q, signal) {
      const client = new Client({ name: "casama", version: "1.0.0" });
      const transport = new StreamableHTTPClientTransport(new URL(url), { fetch: fetchImpl });
      try {
        await client.connect(transport, { signal, timeout: 15_000 });
        const res = await client.callTool(
          { name: "search-flight", arguments: kiwiArgs(q) },
          undefined,
          { signal, timeout: 25_000 },
        );
        if (res.isError) {
          const text = (res.content as { text?: string }[] | undefined)?.[0]?.text ?? "error";
          throw new LiveDataError("upstream", `Kiwi.com: ${text.slice(0, 200)}`);
        }
        let body = res.structuredContent as KiwiResult | undefined;
        if (!body) {
          const text = (res.content as { text?: string }[] | undefined)?.[0]?.text ?? "{}";
          body = JSON.parse(text) as KiwiResult;
        }
        return parseKiwi(body);
      } catch (err) {
        if (err instanceof LiveDataError) throw err;
        throw new LiveDataError(
          "upstream",
          `Kiwi.com didn't answer (${err instanceof Error ? err.message.slice(0, 120) : String(err)}).`,
        );
      } finally {
        await client.close().catch(() => {});
      }
    },
  };
}

// ---------- Google Flights (SerpApi) ----------

const SERP_CABIN: Record<Cabin, number> = { economy: 1, premium: 2, business: 3, first: 4 };
const SERP_SORT: Record<FareSort, number> = { best: 1, cheapest: 2, fastest: 5 };

/** SerpApi's google_flights parameters, without the key. Null when Google can't take the query. */
export function serpParams(q: FareQuery): Record<string, string> | null {
  // Google needs airport codes and exact dates.
  if (!q.from.pick || !q.to.pick || !DAY.test(q.depart) || (q.ret && !DAY.test(q.ret))) return null;
  const p: Record<string, string> = {
    engine: "google_flights",
    departure_id: q.from.pick.codes.join(","),
    arrival_id: q.to.pick.codes.join(","),
    outbound_date: q.depart,
    type: q.ret ? "1" : "2",
    travel_class: String(SERP_CABIN[q.cabin]),
    adults: String(q.adults),
    sort_by: String(SERP_SORT[q.sort]),
    currency: q.currency,
    hl: "en",
  };
  if (q.ret) p.return_date = q.ret;
  if (q.children) p.children = String(q.children);
  if (q.infants) p.infants_on_lap = String(q.infants);
  if (q.maxStops !== undefined) p.stops = String(q.maxStops + 1);
  if (q.from.pick.country) p.gl = q.from.pick.country.toLowerCase();
  return p;
}

interface SerpFlight {
  departure_airport?: { id?: string; time?: string };
  arrival_airport?: { id?: string; time?: string };
  airline?: string;
  flight_number?: string;
}
interface SerpOption {
  flights?: SerpFlight[];
  total_duration?: number;
  price?: number;
}
export interface SerpResult {
  error?: string;
  best_flights?: SerpOption[];
  other_flights?: SerpOption[];
  price_insights?: { typical_price_range?: [number, number]; price_level?: string };
  search_metadata?: { google_flights_url?: string; status?: string };
}

export function parseSerp(r: SerpResult, roundTrip: boolean): FareSearch {
  if (r.error && !/hasn't returned any results/i.test(r.error))
    throw new LiveDataError("upstream", `Google Flights: ${r.error.slice(0, 200)}`);
  const searchUrl = safeLink(r.search_metadata?.google_flights_url, "serpapi");
  const options: FareOption[] = [];
  for (const o of [...(r.best_flights ?? []), ...(r.other_flights ?? [])]) {
    const fl = o.flights ?? [];
    const first = fl[0];
    const last = fl[fl.length - 1];
    if (!first || !last || typeof o.price !== "number") continue;
    const out: FareLeg = {
      from: first.departure_airport?.id ?? "",
      to: last.arrival_airport?.id ?? "",
      depart: hhmm(first.departure_airport?.time),
      arrive: hhmm(last.arrival_airport?.time),
      minutes: o.total_duration ?? 0,
      stops: fl.length - 1,
      via: fl
        .slice(1)
        .map((f) => f.departure_airport?.id ?? "")
        .filter(Boolean),
      airlines: uniq(fl.map((f) => f.airline ?? "").filter(Boolean)),
      flights: fl.map((f) => f.flight_number ?? "").filter(Boolean),
    };
    options.push({
      id: optionId("serpapi", o.price, [out]),
      price: o.price,
      airlines: out.airlines,
      minutes: out.minutes,
      out,
      link: searchUrl,
    });
  }
  const range = r.price_insights?.typical_price_range;
  return {
    options: options.slice(0, MAX_OPTIONS),
    ...(range
      ? { typical: { low: range[0], high: range[1], level: r.price_insights?.price_level } }
      : {}),
    ...(searchUrl ? { searchUrl } : {}),
    ...(roundTrip ? { outboundOnly: true } : {}),
  };
}

export function serpapiProvider(key: string, http: LiveHttp): FareProvider {
  return {
    id: "serpapi",
    paid: true,
    async search(q, signal) {
      const p = serpParams(q);
      if (!p)
        throw new LiveDataError(
          "unsupported",
          "Google Flights needs airport codes and exact dates.",
        );
      const url = `https://serpapi.com/search.json?${new URLSearchParams({ ...p, api_key: key })}`;
      const r = await http.json<SerpResult>(url, { signal, timeoutMs: 20_000 });
      return parseSerp(r, Boolean(q.ret));
    },
  };
}

// ---------- the chain ----------

/** Providers that failed lately, skipped for a minute so a slow one doesn't slow every search. */
const resting = new Map<FareProviderId, number>();

export interface FaresAnswer extends FareSearch {
  provider: FareProviderId;
  fetchedAt: Date;
  stale: boolean;
  /** Why a paid provider was left out, for the model. */
  note?: string;
}

export function providersFor(d: FaresDeps): Partial<Record<FareProviderId, FareProvider>> {
  return {
    ...(d.kiwiUrl ? { kiwi: kiwiProvider(d.kiwiUrl, d.http.raw ?? fetch) } : {}),
    ...(d.serpapiKey ? { serpapi: serpapiProvider(d.serpapiKey, d.http) } : {}),
    ...d.providers,
  };
}

/**
 * Runs the chain: each provider in order until one finds fares. A paid provider runs only with a
 * meter that allows it, is charged only when it was really called (not a cache hit), and is never
 * used for a month search (Google needs exact dates).
 */
export async function searchFares(
  d: FaresDeps,
  q: FareQuery,
  opts: { force?: boolean; meter?: FaresMeter; preferGoogle?: boolean } = {},
): Promise<FaresAnswer> {
  const all = providersFor(d);
  let order = d.order.filter((p) => all[p]);
  if (opts.preferGoogle)
    order = [...order.filter((p) => p === "serpapi"), ...order.filter((p) => p !== "serpapi")];
  const errors: string[] = [];
  let note: string | undefined;
  let empty = false;
  const key = fareKey(q);
  for (const id of order) {
    const p = all[id] as FareProvider;
    if (p.paid) {
      if (id === "serpapi" && !serpParams(q)) continue;
      if (!opts.meter) continue;
      const why = await opts.meter.allow(id);
      if (why) {
        note = why;
        continue;
      }
    }
    if ((resting.get(id) ?? 0) > Date.now() && !opts.force) {
      errors.push(`${SOURCES[id].name} is resting after an error`);
      continue;
    }
    let called = false;
    try {
      const r = await d.cache.get(
        `fares-${id}`,
        key,
        FARES_TTL,
        async () => {
          called = true;
          return p.search(q);
        },
        { force: opts.force, minAgeSeconds: 300 },
      );
      if (called && p.paid && opts.meter)
        await opts.meter.charge(id, {
          route: `${q.from.text}→${q.to.text}`,
          billable: r.value.options.length > 0,
        });
      if (!r.value.options.length) {
        empty = true;
        continue;
      }
      return {
        ...r.value,
        provider: id,
        fetchedAt: r.fetchedAt,
        stale: r.stale,
        ...(note ? { note } : {}),
      };
    } catch (err) {
      // A failed call is never charged (SerpApi doesn't bill errors either).
      resting.set(id, Date.now() + 60_000);
      errors.push(err instanceof Error ? err.message : String(err));
    }
  }
  if (empty)
    throw new LiveDataError(
      "no_fares",
      `No flights found ${q.from.text} → ${q.to.text} on those dates. Try nearby dates, another airport, or allowing stops.${note ? ` (${note})` : ""}`,
    );
  throw new LiveDataError(
    "providers_down",
    `Flight prices aren't available right now${errors.length ? ` (${errors.join("; ").slice(0, 300)})` : ""}.${note ? ` ${note}` : ""} Offer the person a Google Flights search link instead: https://www.google.com/travel/flights?q=${encodeURIComponent(`flights from ${q.from.text} to ${q.to.text} on ${q.depart}${q.ret ? ` returning ${q.ret}` : ""}`)}`,
  );
}

/** For tests: forget which providers are resting. */
export function resetFareProviders() {
  resting.clear();
}

// ---------- the card ----------

export function fareMoney(v: number, currency: string) {
  try {
    return new Intl.NumberFormat("en", {
      style: "currency",
      currency,
      maximumFractionDigits: 0,
    }).format(v);
  } catch {
    return `${currency} ${Math.round(v).toLocaleString("en")}`;
  }
}

const dur = (m: number) =>
  `${Math.floor(m / 60)}h${m % 60 ? ` ${String(m % 60).padStart(2, "0")}m` : ""}`;
const time = (iso: string) => iso.slice(11, 16);
const shortDate = (iso: string) =>
  DAY.test(iso)
    ? new Date(`${iso}T00:00:00Z`).toLocaleDateString("en", {
        day: "numeric",
        month: "short",
        timeZone: "UTC",
      })
    : new Date(`${iso}-01T00:00:00Z`).toLocaleDateString("en", {
        month: "long",
        year: "numeric",
        timeZone: "UTC",
      });

export function sortFares(options: FareOption[], sort: FareSort): FareOption[] {
  if (sort === "cheapest") return [...options].sort((a, b) => a.price - b.price);
  if (sort === "fastest")
    return [...options].sort((a, b) => a.minutes - b.minutes || a.price - b.price);
  return options;
}

const legLine = (l: FareLeg) =>
  `${l.from} ${time(l.depart)} → ${l.to} ${time(l.arrive)}${l.arrive.slice(0, 10) > l.depart.slice(0, 10) ? " (+1)" : ""}, ${l.stops ? `${l.stops} stop${l.stops > 1 ? "s" : ""} via ${l.via.join(", ")}` : "direct"}, ${dur(l.minutes)}`;

function place2(p: FareQuery["from"]) {
  const codes = p.pick?.codes ?? [];
  const first = codes[0] ? airportByCode(codes[0]) : undefined;
  return { label: p.pick?.label ?? p.text, codes, ...(first ? { country: first.country } : {}) };
}

export function faresCard(q: FareQuery, a: FaresAnswer): Built {
  const options = sortFares(a.options, q.sort);
  const cheapest = Math.min(...options.map((o) => o.price));
  const fastest = Math.min(...options.map((o) => o.minutes));
  const from = place2(q.from);
  const to = place2(q.to);
  const travellers = q.adults + q.children + q.infants;
  const dates = `${shortDate(q.depart)}${q.ret ? ` – ${shortDate(q.ret)}` : q.nights ? `, ${q.nights} nights` : ""}`;
  const who = `${travellers} traveller${travellers > 1 ? "s" : ""}`;
  const head = `Fares ${from.label} → ${to.label}, ${dates}, ${who}, ${q.cabin} (${SOURCES[a.provider].name}, ${q.ret || q.nights ? "return-trip" : "one-way"} totals in ${q.currency}${a.outboundOnly ? "; return flights are picked on Google's page" : ""}):`;
  const lines = options.slice(0, 5).map((o, i) => {
    const airline = o.airlines.join(" + ") || "Airline n/a";
    return `${i + 1}. ${fareMoney(o.price, q.currency)} ${airline}, ${legLine(o.out)}${o.back ? `; back ${legLine(o.back)}` : ""}`;
  });
  const typical = a.typical
    ? `Typical ${fareMoney(a.typical.low, q.currency)}–${fareMoney(a.typical.high, q.currency)} (Google)${a.typical.level ? `: today's prices are ${a.typical.level}` : ""}.`
    : "";
  const text = [head, ...lines, typical, a.note ? `(${a.note})` : ""].filter(Boolean).join("\n");
  return {
    card: {
      component: "Fares",
      from,
      to,
      depart: q.depart,
      ...(q.ret ? { return: q.ret } : {}),
      ...(q.nights ? { nights: q.nights } : {}),
      travellers: { adults: q.adults, children: q.children, infants: q.infants },
      cabin: q.cabin,
      currency: q.currency,
      sort: q.sort,
      roundTrip: Boolean(q.ret || q.nights),
      ...(a.outboundOnly ? { outboundOnly: true } : {}),
      cheapest,
      fastest,
      options,
      ...(a.typical ? { typical: a.typical } : {}),
      ...(a.searchUrl ? { searchUrl: a.searchUrl } : {}),
      live: liveBlock(
        [SOURCES[a.provider]],
        a.fetchedAt,
        FARES_TTL,
        a.stale ? { stale: true } : {},
      ),
    },
    text,
    preview: `${from.label} → ${to.label} from ${fareMoney(cheapest, q.currency)}`,
    tiny: `${from.codes[0] ?? from.label}→${to.codes[0] ?? to.label} ${fareMoney(cheapest, q.currency)}`,
    short: `${from.label} → ${to.label}, ${dates}: from ${fareMoney(cheapest, q.currency)}`,
  };
}

/**
 * Affiliate booking links (FLIGHT-SEARCH-PLAN Phase 4). [template] is the affiliate network's link
 * with `{url}` where the booking page goes (URL-encoded), for example a Travelpayouts link; only
 * booking links on [hosts] (default kiwi.com) are wrapped. Set with LIVE_FARES_AFFILIATE_URL.
 */
export type FaresAffiliate = { template: string; hosts: string[] };

/** A checked affiliate setting, or undefined when the template is missing or unsafe. */
export function faresAffiliate(
  template: string | undefined,
  hosts: string | undefined,
): FaresAffiliate | undefined {
  if (!template?.includes("{url}")) return undefined;
  try {
    if (new URL(template.replace("{url}", "x")).protocol !== "https:") return undefined;
  } catch {
    return undefined;
  }
  const list = (hosts ?? "kiwi.com")
    .split(",")
    .map((h) => h.trim().toLowerCase())
    .filter(Boolean);
  return { template, hosts: list.length ? list : ["kiwi.com"] };
}

const onHost = (link: string, hosts: string[]) => {
  try {
    const h = new URL(link).hostname.toLowerCase();
    return hosts.some((x) => h === x || h.endsWith(`.${x}`));
  } catch {
    return false;
  }
};

/**
 * Wraps a Fares card's booking links in the affiliate template. A card with wrapped links says so
 * (`affiliate: true`), and the app shows the disclosure line under it.
 */
export function withAffiliate(built: Built, aff: FaresAffiliate | undefined): Built {
  if (!aff) return built;
  const card = built.card as { options?: FareOption[] };
  let wrapped = false;
  const options = (card.options ?? []).map((o) => {
    if (!o.link || !onHost(o.link, aff.hosts)) return o;
    wrapped = true;
    return { ...o, link: aff.template.replace("{url}", encodeURIComponent(o.link)) };
  });
  if (!wrapped) return built;
  return { ...built, card: { ...built.card, options, affiliate: true } };
}

/**
 * A "compare" link under a Fares card (D-471): the same trip as a search on Aviasales, opened through
 * the affiliate network so a booking there earns Casama a share. [template] is an https link with
 * `{url}` where the Aviasales search goes, URL-encoded, for example
 * `https://tp.media/r?marker=…&trs=…&p=4114&u={url}`. Set with LIVE_FARES_COMPARE_URL.
 */
export type FaresCompare = { template: string };

/** A checked compare setting, or undefined when the template is missing or unsafe. */
export function faresCompare(template: string | undefined): FaresCompare | undefined {
  const t = template?.trim();
  if (!t?.includes("{url}")) return undefined;
  try {
    if (new URL(t.replace("{url}", "x")).protocol !== "https:") return undefined;
  } catch {
    return undefined;
  }
  return { template: t };
}

/** IATA city codes for the cities [METROS] lists with more than one airport. */
const CITY_CODES: Record<string, string> = {
  "HND,NRT": "TYO",
  "ITM,KIX": "OSA",
  "GMP,ICN": "SEL",
  "PVG,SHA": "SHA",
  "PEK,PKX": "BJS",
  "TPE,TSA": "TPE",
  "BKK,DMK": "BKK",
  "CGK,HLP": "JKT",
  "KUL,SZB": "KUL",
  "DWC,DXB": "DXB",
  "IST,SAW": "IST",
  "LCY,LGW,LHR,LTN,SEN,STN": "LON",
  "BVA,CDG,ORY": "PAR",
  "BGY,LIN,MXP": "MIL",
  "CIA,FCO": "ROM",
  "DME,SVO,VKO": "MOW",
  "ARN,BMA,NYO": "STO",
  "EWR,JFK,LGA": "NYC",
  "MDW,ORD": "CHI",
  "BWI,DCA,IAD": "WAS",
  "OAK,SFO,SJC": "SFO",
  "BUR,LAX,LGB,ONT,SNA": "LAX",
  "FLL,MIA": "MIA",
  "HOU,IAH": "HOU",
  "DAL,DFW": "DFW",
  "YTZ,YYZ": "YTO",
  "CGH,GRU,VCP": "SAO",
  "GIG,SDU": "RIO",
  "AEP,EZE": "BUE",
  "MEX,NLU": "MEX",
  "AVV,MEL": "MEL",
};

/** One code Aviasales understands for a place: its airport, or the city code for several. */
function placeCode(codes: unknown): string | undefined {
  const list = Array.isArray(codes)
    ? codes.filter((c): c is string => typeof c === "string" && /^[A-Z]{3}$/.test(c))
    : [];
  if (list.length <= 1) return list[0];
  return CITY_CODES[[...list].sort().join(",")] ?? list[0];
}

const ddmm = (day: string | undefined) => {
  const m = /^\d{4}-(\d{2})-(\d{2})/.exec(day ?? "");
  return m ? `${m[2]}${m[1]}` : undefined;
};

const CABIN_LETTER: Record<Cabin, string> = {
  economy: "",
  premium: "w",
  business: "c",
  first: "f",
};

/**
 * The card's trip as an Aviasales search page: `ORIGIN DDMM DEST [DDMM] [cabin] adults [children
 * [infants]]`, for example `https://www.aviasales.com/search/TYO1203MNL1903c21`. A month search
 * takes the cheapest option's days. Undefined when a place has no airport code or there is no day.
 */
export function aviasalesSearchUrl(card: Record<string, unknown>): string | undefined {
  const from = placeCode((card.from as { codes?: unknown } | undefined)?.codes);
  const to = placeCode((card.to as { codes?: unknown } | undefined)?.codes);
  if (!from || !to || from === to) return undefined;
  const options = (card.options as FareOption[] | undefined) ?? [];
  const cheapest = [...options].sort((a, b) => a.price - b.price)[0];
  const depart = String(card.depart ?? "");
  const out = DAY.test(depart) ? ddmm(depart) : ddmm(cheapest?.out.depart);
  if (!out) return undefined;
  const roundTrip = card.roundTrip === true;
  const ret = roundTrip
    ? ddmm(
        typeof card.return === "string" && DAY.test(card.return)
          ? card.return
          : cheapest?.back?.depart,
      )
    : "";
  if (roundTrip && !ret) return undefined;
  const t = (card.travellers ?? {}) as { adults?: number; children?: number; infants?: number };
  const n = (v: unknown, min: number) => Math.min(9, Math.max(min, Math.floor(Number(v) || 0)));
  const adults = n(t.adults ?? 1, 1);
  const children = n(t.children, 0);
  const infants = n(t.infants, 0);
  const people = `${adults}${children || infants ? children : ""}${infants ? infants : ""}`;
  const cabin = CABIN_LETTER[card.cabin as Cabin] ?? "";
  return `https://www.aviasales.com/search/${from}${out}${to}${ret}${cabin}${people}`;
}

/**
 * Adds the compare link to a Fares card that has fares: `compare: {name, url}`, and `affiliate:
 * true` so the app shows the disclosure line. The words the model reads don't change.
 */
export function withCompare(built: Built, cmp: FaresCompare | undefined): Built {
  if (!cmp) return built;
  const card = built.card as Record<string, unknown>;
  if (!(card.options as unknown[] | undefined)?.length) return built;
  const search = aviasalesSearchUrl(card);
  if (!search) return built;
  const url = cmp.template.replace("{url}", encodeURIComponent(search));
  return {
    ...built,
    card: { ...built.card, compare: { name: "Aviasales", url }, affiliate: true },
  };
}
