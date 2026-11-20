/**
 * Places (RICH-CARDS-PLAN §4.6): a place name to coordinates and a time zone, from Open-Meteo's
 * geocoding (GeoNames data, CC BY 4.0). Cached 30 days; shared by weather, time and maps.
 */
import { type LiveCache, LiveDataError, type LiveHttp, type LiveSource } from "./core.ts";

export interface Place {
  name: string;
  region?: string;
  country?: string;
  countryName?: string;
  lat: number;
  lng: number;
  tz?: string;
  population?: number;
}

export const GEONAMES: LiveSource = {
  id: "open_meteo_geocoding",
  name: "GeoNames via Open-Meteo",
  url: "https://open-meteo.com/en/docs/geocoding-api",
  license: "CC BY 4.0",
};

interface GeoResult {
  name: string;
  latitude: number;
  longitude: number;
  country_code?: string;
  country?: string;
  admin1?: string;
  timezone?: string;
  population?: number;
  feature_code?: string;
}

const LATLNG = /^\s*(-?\d{1,2}(?:\.\d+)?)\s*,\s*(-?\d{1,3}(?:\.\d+)?)\s*$/;

/** "Springfield, US" → name "Springfield", country hint "US". */
function splitQuery(q: string) {
  const parts = q
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean);
  const name = parts[0] ?? q.trim();
  const hint = parts.slice(1).join(" ").toLowerCase();
  return { name, hint };
}

export async function lookupPlaces(
  http: LiveHttp,
  cache: LiveCache,
  query: string,
  count = 5,
): Promise<Place[]> {
  const m = LATLNG.exec(query);
  if (m) {
    const lat = Number(m[1]);
    const lng = Number(m[2]);
    if (Math.abs(lat) > 90 || Math.abs(lng) > 180)
      throw new LiveDataError("bad_place", "Coordinates are out of range.");
    return [{ name: `${lat.toFixed(2)}, ${lng.toFixed(2)}`, lat, lng }];
  }
  const { name, hint } = splitQuery(query);
  if (name.length < 2) throw new LiveDataError("bad_place", "Say which place.");
  const key = `${name.toLowerCase()}|${count}`;
  const { value } = await cache.get(GEONAMES.id, key, 30 * 86400, async () => {
    const url = `https://geocoding-api.open-meteo.com/v1/search?name=${encodeURIComponent(name)}&count=${Math.max(count, 10)}&language=en&format=json`;
    const r = await http.json<{ results?: GeoResult[] }>(url);
    return (r.results ?? []).map(
      (g): Place => ({
        name: g.name,
        region: g.admin1,
        country: g.country_code,
        countryName: g.country,
        lat: g.latitude,
        lng: g.longitude,
        tz: g.timezone,
        population: g.population,
      }),
    );
  });
  let places = value;
  if (hint) {
    const matched = places.filter((p) =>
      [p.country, p.countryName, p.region].some(
        (v) =>
          v &&
          (v.toLowerCase() === hint ||
            v.toLowerCase().includes(hint) ||
            hint.includes(v.toLowerCase())),
      ),
    );
    if (matched.length) places = matched;
  }
  // Biggest first, so "Manila" is the capital and not a village of the same name.
  places = [...places].sort((a, b) => (b.population ?? 0) - (a.population ?? 0));
  if (!places.length) throw new LiveDataError("not_found", `No place called "${query}" was found.`);
  return places.slice(0, count);
}

export async function lookupPlace(http: LiveHttp, cache: LiveCache, query: string) {
  const [first] = await lookupPlaces(http, cache, query, 5);
  return first as Place;
}

/** The main city of a time zone ("Asia/Manila" → "Manila"), for "here" without a home place. */
export function cityOfZone(tz: string) {
  const last = tz.split("/").pop() ?? tz;
  return last.replaceAll("_", " ");
}
