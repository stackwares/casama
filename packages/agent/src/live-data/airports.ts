/**
 * Airports for flight fares (docs/FLIGHT-SEARCH-PLAN.md §6): a place a person names → IATA codes,
 * from a bundled OurAirports extract (public domain; `scripts/airports-extract.mjs` rebuilds
 * `airports.json`). Kiwi.com resolves names itself; Google Flights (SerpApi) needs codes, and the
 * card shows them. Loaded on first use, about 4,000 rows.
 */
import { readFileSync } from "node:fs";
import type { Place } from "./places.ts";

/** [iata, name, city, country, lat, lng, size: 2 large, 1 medium, 0 small] */
type Row = [string, string, string, string, number, number, number];

export interface Airport {
  code: string;
  name: string;
  city: string;
  country: string;
  lat: number;
  lng: number;
  size: number;
}

/** What a place resolves to: a label for the card and the airports to search. */
export interface AirportPick {
  label: string;
  codes: string[];
  country?: string;
}

/**
 * Cities with several airports, by the name people use. OurAirports lists Narita under "Narita"
 * and Gatwick under "Crawley", so a city search alone would miss them.
 */
export const METROS: Record<string, string[]> = {
  tokyo: ["HND", "NRT"],
  osaka: ["KIX", "ITM"],
  seoul: ["ICN", "GMP"],
  shanghai: ["PVG", "SHA"],
  beijing: ["PEK", "PKX"],
  taipei: ["TPE", "TSA"],
  bangkok: ["BKK", "DMK"],
  jakarta: ["CGK", "HLP"],
  "kuala lumpur": ["KUL", "SZB"],
  manila: ["MNL"],
  dubai: ["DXB", "DWC"],
  istanbul: ["IST", "SAW"],
  london: ["LHR", "LGW", "STN", "LTN", "LCY", "SEN"],
  paris: ["CDG", "ORY", "BVA"],
  milan: ["MXP", "LIN", "BGY"],
  rome: ["FCO", "CIA"],
  moscow: ["SVO", "DME", "VKO"],
  stockholm: ["ARN", "BMA", "NYO"],
  "new york": ["JFK", "EWR", "LGA"],
  "new york city": ["JFK", "EWR", "LGA"],
  nyc: ["JFK", "EWR", "LGA"],
  chicago: ["ORD", "MDW"],
  washington: ["IAD", "DCA", "BWI"],
  "washington dc": ["IAD", "DCA", "BWI"],
  "san francisco": ["SFO", "OAK", "SJC"],
  "bay area": ["SFO", "OAK", "SJC"],
  "los angeles": ["LAX", "BUR", "LGB", "SNA", "ONT"],
  miami: ["MIA", "FLL"],
  houston: ["IAH", "HOU"],
  dallas: ["DFW", "DAL"],
  toronto: ["YYZ", "YTZ"],
  montreal: ["YUL"],
  "sao paulo": ["GRU", "CGH", "VCP"],
  "são paulo": ["GRU", "CGH", "VCP"],
  "rio de janeiro": ["GIG", "SDU"],
  "buenos aires": ["EZE", "AEP"],
  "mexico city": ["MEX", "NLU"],
  sydney: ["SYD"],
  melbourne: ["MEL", "AVV"],
  "hong kong": ["HKG"],
  singapore: ["SIN"],
};

let cache: Airport[] | null = null;
let byCode: Map<string, Airport> | null = null;

export function airports(): Airport[] {
  if (cache) return cache;
  const rows = JSON.parse(
    readFileSync(new URL("./airports.json", import.meta.url), "utf8"),
  ) as Row[];
  cache = rows.map(([code, name, city, country, lat, lng, size]) => ({
    code,
    name,
    city,
    country,
    lat,
    lng,
    size,
  }));
  byCode = new Map(cache.map((a) => [a.code, a]));
  return cache;
}

export function airportByCode(code: string): Airport | undefined {
  airports();
  return byCode?.get(code.toUpperCase());
}

const norm = (s: string) =>
  s
    .normalize("NFD")
    .replace(/\p{Diacritic}/gu, "")
    .toLowerCase()
    .replace(/[.,]/g, " ")
    .replace(/\s+/g, " ")
    .trim();

/** The parts of a municipality: "Cebu City/Lapu-Lapu City" → cebu city, lapu-lapu city, cebu. */
function cityParts(city: string): string[] {
  const parts = norm(city)
    .split(/[/()]/)
    .map((p) => p.trim())
    .filter(Boolean);
  return [...parts, ...parts.map((p) => p.replace(/ city$/, ""))];
}

const kmBetween = (a: { lat: number; lng: number }, b: { lat: number; lng: number }) => {
  const r = Math.PI / 180;
  const x = (b.lng - a.lng) * r * Math.cos(((a.lat + b.lat) / 2) * r);
  const y = (b.lat - a.lat) * r;
  return Math.sqrt(x * x + y * y) * 6371;
};

/** The largest airports within `km` of a place, nearest first among the largest. */
export function nearestAirports(place: { lat: number; lng: number }, km = 150): Airport[] {
  return airports()
    .filter((a) => a.size >= 1)
    .map((a) => ({ a, d: kmBetween(place, a) }))
    .filter((x) => x.d <= km)
    .sort((x, y) => y.a.size - x.a.size || x.d - y.d)
    .slice(0, 3)
    .map((x) => x.a);
}

/**
 * A place a person names → airports: an IATA code, a city with several airports, a city, or an
 * airport's name. Null when nothing matches (Kiwi may still know the place).
 */
export function resolveAirports(raw: string): AirportPick | null {
  const q = norm(raw.replace(/\(([A-Z]{3})\)/, " $1 "));
  if (!q) return null;
  const code = raw.trim().toUpperCase();
  if (/^[A-Z]{3}$/.test(code)) {
    const a = airportByCode(code);
    if (a) return { label: `${a.city || a.name} (${a.code})`, codes: [a.code], country: a.country };
  }
  const city = q.replace(/,.*$/, "").trim();
  const metro = METROS[city];
  if (metro) {
    const first = airportByCode(metro[0] as string);
    return {
      label: raw.trim().replace(/,.*$/, ""),
      codes: metro.filter((c) => airportByCode(c)),
      country: first?.country,
    };
  }
  const all = airports();
  const inCity = all
    .filter((a) => cityParts(a.city).includes(city))
    .sort((a, b) => b.size - a.size);
  const pick = inCity.length ? inCity : all.filter((a) => norm(a.name).includes(q));
  if (!pick.length) return null;
  const top = pick[0] as Airport;
  // A city's airports, largest first; small fields only when nothing larger serves it.
  const codes = pick
    .filter((a) => a.country === top.country && a.size >= Math.min(top.size, 1))
    .slice(0, 3)
    .map((a) => a.code);
  return { label: raw.trim().replace(/,.*$/, ""), codes, country: top.country };
}

/** The person's home place → its airports. */
export function homeAirports(place: Place): AirportPick | null {
  const near = nearestAirports(place);
  if (!near.length) return null;
  return {
    label: place.name,
    codes: near.map((a) => a.code),
    country: (near[0] as Airport).country,
  };
}

/** The currency fares are usually sold in, by the departure country. */
const CURRENCY: Record<string, string> = {
  PH: "PHP",
  US: "USD",
  GB: "GBP",
  JP: "JPY",
  KR: "KRW",
  CN: "CNY",
  HK: "HKD",
  TW: "TWD",
  SG: "SGD",
  MY: "MYR",
  TH: "THB",
  VN: "VND",
  ID: "IDR",
  IN: "INR",
  AU: "AUD",
  NZ: "NZD",
  CA: "CAD",
  MX: "MXN",
  BR: "BRL",
  AR: "ARS",
  CL: "CLP",
  CO: "COP",
  PE: "PEN",
  AE: "AED",
  SA: "SAR",
  QA: "QAR",
  TR: "TRY",
  IL: "ILS",
  EG: "EGP",
  ZA: "ZAR",
  NG: "NGN",
  KE: "KES",
  CH: "CHF",
  SE: "SEK",
  NO: "NOK",
  DK: "DKK",
  PL: "PLN",
  CZ: "CZK",
  HU: "HUF",
  RO: "RON",
  DE: "EUR",
  FR: "EUR",
  ES: "EUR",
  IT: "EUR",
  NL: "EUR",
  BE: "EUR",
  AT: "EUR",
  PT: "EUR",
  IE: "EUR",
  FI: "EUR",
  GR: "EUR",
  LU: "EUR",
  SK: "EUR",
  SI: "EUR",
  EE: "EUR",
  LV: "EUR",
  LT: "EUR",
  HR: "EUR",
  MT: "EUR",
  CY: "EUR",
};

export function currencyFor(country?: string): string {
  return (country && CURRENCY[country]) || "USD";
}
