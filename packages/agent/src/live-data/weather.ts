/**
 * Weather (RICH-CARDS-PLAN §6.1, §7.1–7.4). MET Norway's Locationforecast first (free, also for
 * commercial use, CC BY 4.0); Open-Meteo for rain chances, UV and as the fallback, where its terms
 * allow (its free API is non-commercial: a server that bills people needs `LIVE_OPEN_METEO_KEY`);
 * NWS for alerts in the US. Everything is normalized to SI units, our own condition codes and
 * times in the place's zone.
 */
import { sunTimes } from "./astro.ts";
import { coord, type LiveCache, LiveDataError, type LiveHttp, type LiveSource } from "./core.ts";
import type { Place } from "./places.ts";
import { addDays, isoInZone, localParts, zonedTime } from "./tz.ts";

export const MET_NORWAY: LiveSource = {
  id: "met_norway",
  name: "MET Norway",
  url: "https://api.met.no/",
  license: "CC BY 4.0",
};
export const OPEN_METEO: LiveSource = {
  id: "open_meteo",
  name: "Open-Meteo",
  url: "https://open-meteo.com/",
  license: "CC BY 4.0",
};
export const NWS: LiveSource = {
  id: "nws",
  name: "US National Weather Service",
  url: "https://www.weather.gov/",
};
export const OPEN_METEO_AIR: LiveSource = {
  id: "open_meteo_air",
  name: "CAMS via Open-Meteo",
  url: "https://open-meteo.com/en/docs/air-quality-api",
  license: "CC BY 4.0",
};

/** Our own condition codes (the app has words and art for each). */
export const CONDITIONS = [
  "clear",
  "mostly_clear",
  "partly_cloudy",
  "cloudy",
  "fog",
  "drizzle",
  "light_rain",
  "rain",
  "heavy_rain",
  "showers",
  "thunder",
  "light_snow",
  "snow",
  "heavy_snow",
  "sleet",
  "hail",
] as const;
export type Condition = (typeof CONDITIONS)[number];

/** How bad a condition is, to pick a day's headline condition. */
const SEVERITY: Record<Condition, number> = {
  clear: 0,
  mostly_clear: 1,
  partly_cloudy: 2,
  cloudy: 3,
  fog: 4,
  drizzle: 5,
  light_rain: 6,
  showers: 7,
  rain: 8,
  light_snow: 8,
  sleet: 9,
  snow: 9,
  heavy_rain: 10,
  heavy_snow: 10,
  hail: 11,
  thunder: 12,
};

export function metCondition(symbol: string | undefined): Condition {
  const s = (symbol ?? "").replace(/_(day|night|polartwilight)$/, "");
  if (!s) return "cloudy";
  if (s.includes("thunder")) return "thunder";
  if (s.includes("sleet")) return "sleet";
  if (s.includes("snow"))
    return s.startsWith("heavy") ? "heavy_snow" : s.startsWith("light") ? "light_snow" : "snow";
  if (s.includes("rainshowers")) return s.startsWith("heavy") ? "heavy_rain" : "showers";
  if (s.includes("rain"))
    return s.startsWith("heavy") ? "heavy_rain" : s.startsWith("light") ? "light_rain" : "rain";
  if (s === "fog") return "fog";
  if (s === "clearsky") return "clear";
  if (s === "fair") return "mostly_clear";
  if (s === "partlycloudy") return "partly_cloudy";
  return "cloudy";
}

/** WMO weather codes (Open-Meteo) to ours. */
export function wmoCondition(code: number | undefined): Condition {
  switch (code) {
    case 0:
      return "clear";
    case 1:
      return "mostly_clear";
    case 2:
      return "partly_cloudy";
    case 3:
      return "cloudy";
    case 45:
    case 48:
      return "fog";
    case 51:
    case 53:
    case 55:
    case 56:
    case 57:
      return "drizzle";
    case 61:
      return "light_rain";
    case 63:
      return "rain";
    case 65:
      return "heavy_rain";
    case 66:
    case 67:
      return "sleet";
    case 71:
    case 85:
      return "light_snow";
    case 73:
      return "snow";
    case 75:
    case 86:
      return "heavy_snow";
    case 77:
      return "snow";
    case 80:
    case 81:
      return "showers";
    case 82:
      return "heavy_rain";
    case 95:
      return "thunder";
    case 96:
    case 99:
      return "hail";
    default:
      return "cloudy";
  }
}

export interface WeatherNow {
  temp: number;
  feels?: number;
  code: Condition;
  isDay: boolean;
  humidity?: number;
  windKph?: number;
  windDir?: number;
  gustKph?: number;
  pressureHpa?: number;
  uv?: number;
  cloud?: number;
  dewPoint?: number;
}
export interface WeatherHour {
  t: string;
  temp: number;
  code: Condition;
  isDay: boolean;
  mm?: number;
  chance?: number;
  windKph?: number;
}
export interface WeatherDay {
  date: string;
  high: number;
  low: number;
  code: Condition;
  precipMm?: number;
  chance?: number;
  windKph?: number;
  uv?: number;
  sunrise?: string;
  sunset?: string;
}
export interface WeatherData {
  tz: string;
  now: WeatherNow;
  hours: WeatherHour[];
  days: WeatherDay[];
  updatedAt: string;
  sources: LiveSource[];
}

interface MetSeries {
  time: string;
  data: {
    instant: { details: Record<string, number> };
    next_1_hours?: { summary?: { symbol_code?: string }; details?: Record<string, number> };
    next_6_hours?: { summary?: { symbol_code?: string }; details?: Record<string, number> };
    next_12_hours?: { summary?: { symbol_code?: string }; details?: Record<string, number> };
  };
}

const r1 = (v: number | undefined) =>
  v === undefined || Number.isNaN(v) ? undefined : Math.round(v * 10) / 10;
const ms2kph = (v: number | undefined) =>
  v === undefined ? undefined : Math.round(v * 3.6 * 10) / 10;

function isDaylight(at: Date, lat: number, lng: number, tz: string) {
  const p = localParts(at, tz);
  const s = sunTimes(zonedTime(p.date, tz, 12), lat, lng);
  if (s.polar) return s.polar === "day";
  if (!s.sunrise || !s.sunset) return p.hour >= 6 && p.hour < 18;
  return at >= s.sunrise && at < s.sunset;
}

function dayPicker(hours: WeatherHour[], date: string) {
  const own = hours.filter((h) => h.t.startsWith(date));
  const daytime = own.filter((h) => h.isDay);
  const pool = daytime.length ? daytime : own;
  if (!pool.length) return "cloudy" as Condition;
  // The worst condition that lasts at least two of the day's hours (one shower isn't the day).
  const counts = new Map<Condition, number>();
  for (const h of pool) counts.set(h.code, (counts.get(h.code) ?? 0) + 1);
  const lasting = [...counts.entries()].filter(([, n]) => n >= Math.min(2, pool.length));
  return (
    (lasting.length ? lasting : [...counts.entries()]).sort(
      (a, b) => SEVERITY[b[0]] - SEVERITY[a[0]],
    )[0]?.[0] ?? "cloudy"
  );
}

/** MET Norway's forecast, normalized: hourly where it has hours, then 6-hourly steps. */
export async function metForecast(http: LiveHttp, place: Place, tz: string): Promise<WeatherData> {
  const url = `https://api.met.no/weatherapi/locationforecast/2.0/complete?lat=${coord(place.lat)}&lon=${coord(place.lng)}`;
  const body = await http.json<{
    properties?: { meta?: { updated_at?: string }; timeseries?: MetSeries[] };
  }>(url);
  const series = body.properties?.timeseries ?? [];
  if (!series.length) throw new LiveDataError("upstream", "MET Norway sent no forecast.");
  const hours: WeatherHour[] = [];
  const byDay = new Map<string, { temps: number[]; mm: number; wind: number[]; uv: number[] }>();
  for (const s of series) {
    const at = new Date(s.time);
    const d = s.data.instant.details;
    const step = s.data.next_1_hours ?? s.data.next_6_hours;
    const isDay = isDaylight(at, place.lat, place.lng, tz);
    const p = localParts(at, tz);
    const slot = byDay.get(p.date) ?? { temps: [], mm: 0, wind: [], uv: [] };
    if (typeof d.air_temperature === "number") slot.temps.push(d.air_temperature);
    for (const k of ["air_temperature_max", "air_temperature_min"])
      if (typeof s.data.next_6_hours?.details?.[k] === "number")
        slot.temps.push(s.data.next_6_hours.details[k] as number);
    if (s.data.next_1_hours) slot.mm += s.data.next_1_hours.details?.precipitation_amount ?? 0;
    else if (s.data.next_6_hours && p.hour % 6 === 0)
      slot.mm += s.data.next_6_hours.details?.precipitation_amount ?? 0;
    if (typeof d.wind_speed === "number") slot.wind.push(d.wind_speed);
    if (typeof d.ultraviolet_index_clear_sky === "number")
      slot.uv.push(d.ultraviolet_index_clear_sky);
    byDay.set(p.date, slot);
    if (
      hours.length < 72 &&
      (s.data.next_1_hours ||
        hours.length === 0 ||
        at.valueOf() - Date.parse(hours[hours.length - 1]?.t ?? "") >= 3600000)
    )
      hours.push({
        t: isoInZone(at, tz),
        temp: r1(d.air_temperature) ?? 0,
        code: metCondition(step?.summary?.symbol_code),
        isDay,
        mm: r1(step?.details?.precipitation_amount),
        windKph: ms2kph(d.wind_speed),
      });
  }
  const first = series[0] as MetSeries;
  const fd = first.data.instant.details;
  const nowAt = new Date(first.time);
  const now: WeatherNow = {
    temp: r1(fd.air_temperature) ?? 0,
    feels: r1(fd.apparent_air_temperature),
    code: metCondition((first.data.next_1_hours ?? first.data.next_6_hours)?.summary?.symbol_code),
    isDay: isDaylight(nowAt, place.lat, place.lng, tz),
    humidity: r1(fd.relative_humidity),
    windKph: ms2kph(fd.wind_speed),
    windDir: fd.wind_from_direction,
    gustKph: ms2kph(fd.wind_speed_of_gust),
    pressureHpa: r1(fd.air_pressure_at_sea_level),
    uv: r1(fd.ultraviolet_index_clear_sky),
    cloud: r1(fd.cloud_area_fraction),
    dewPoint: r1(fd.dew_point_temperature),
  };
  const days: WeatherDay[] = [...byDay.entries()]
    .filter(([, v]) => v.temps.length >= 2)
    .slice(0, 10)
    .map(([date, v]) => {
      const sun = sunTimes(zonedTime(date, tz, 12), place.lat, place.lng);
      return {
        date,
        high: Math.round(Math.max(...v.temps)),
        low: Math.round(Math.min(...v.temps)),
        code: dayPicker(hours, date),
        precipMm: Math.round(v.mm * 10) / 10,
        windKph: v.wind.length ? ms2kph(Math.max(...v.wind)) : undefined,
        uv: v.uv.length ? r1(Math.max(...v.uv)) : undefined,
        sunrise: sun.sunrise ? isoInZone(sun.sunrise, tz) : undefined,
        sunset: sun.sunset ? isoInZone(sun.sunset, tz) : undefined,
      };
    });
  // Days past the hourly range have only 6-hour symbols: take the midday one.
  for (const day of days) {
    if (hours.some((h) => h.t.startsWith(day.date))) continue;
    const noon = series.find((s) => {
      const p = localParts(new Date(s.time), tz);
      return p.date === day.date && p.hour >= 10 && p.hour <= 14;
    });
    day.code = metCondition(
      noon?.data.next_6_hours?.summary?.symbol_code ??
        noon?.data.next_12_hours?.summary?.symbol_code,
    );
  }
  return {
    tz,
    now,
    hours: hours.filter((h) => Date.parse(h.t) >= Date.now() - 3600000).slice(0, 48),
    days,
    updatedAt: body.properties?.meta?.updated_at ?? new Date().toISOString(),
    sources: [MET_NORWAY],
  };
}

interface OmForecast {
  timezone?: string;
  current?: Record<string, number>;
  hourly?: Record<string, Array<number | string>>;
  daily?: Record<string, Array<number | string>>;
}

export function openMeteoBase(key?: string) {
  return key ? "https://customer-api.open-meteo.com" : "https://api.open-meteo.com";
}

export async function openMeteoForecast(
  http: LiveHttp,
  place: Place,
  tz: string,
  key?: string,
): Promise<WeatherData> {
  const q = new URLSearchParams({
    latitude: String(coord(place.lat)),
    longitude: String(coord(place.lng)),
    timezone: tz,
    forecast_days: "10",
    wind_speed_unit: "kmh",
    current:
      "temperature_2m,apparent_temperature,relative_humidity_2m,is_day,weather_code,wind_speed_10m,wind_direction_10m,wind_gusts_10m,pressure_msl,cloud_cover,uv_index,dew_point_2m",
    hourly:
      "temperature_2m,precipitation_probability,precipitation,weather_code,is_day,wind_speed_10m",
    daily:
      "weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,precipitation_sum,uv_index_max,wind_speed_10m_max,sunrise,sunset",
  });
  if (key) q.set("apikey", key);
  const r = await http.json<OmForecast>(`${openMeteoBase(key)}/v1/forecast?${q}`);
  const c = r.current ?? {};
  const h = r.hourly ?? {};
  const d = r.daily ?? {};
  const time = (h.time ?? []) as string[];
  // Open-Meteo's local times have no offset: add the zone's.
  const withZone = (local: string) =>
    isoInZone(
      zonedTime(
        local.slice(0, 10),
        tz,
        Number(local.slice(11, 13) || 0),
        Number(local.slice(14, 16) || 0),
      ),
      tz,
    );
  const nowMs = Date.now() - 3600000;
  const hours: WeatherHour[] = [];
  time.forEach((t, i) => {
    const iso = withZone(t);
    if (Date.parse(iso) < nowMs || hours.length >= 48) return;
    hours.push({
      t: iso,
      temp: r1(h.temperature_2m?.[i] as number) ?? 0,
      code: wmoCondition(h.weather_code?.[i] as number),
      isDay: h.is_day?.[i] === 1,
      mm: r1(h.precipitation?.[i] as number),
      chance: h.precipitation_probability?.[i] as number | undefined,
      windKph: r1(h.wind_speed_10m?.[i] as number),
    });
  });
  const days: WeatherDay[] = ((d.time ?? []) as string[]).map((date, i) => ({
    date,
    high: Math.round(d.temperature_2m_max?.[i] as number),
    low: Math.round(d.temperature_2m_min?.[i] as number),
    code: wmoCondition(d.weather_code?.[i] as number),
    precipMm: r1(d.precipitation_sum?.[i] as number),
    chance: d.precipitation_probability_max?.[i] as number | undefined,
    windKph: r1(d.wind_speed_10m_max?.[i] as number),
    uv: r1(d.uv_index_max?.[i] as number),
    sunrise: d.sunrise?.[i] ? withZone(String(d.sunrise[i])) : undefined,
    sunset: d.sunset?.[i] ? withZone(String(d.sunset[i])) : undefined,
  }));
  if (!days.length) throw new LiveDataError("upstream", "Open-Meteo sent no forecast.");
  return {
    tz,
    now: {
      temp: r1(c.temperature_2m) ?? 0,
      feels: r1(c.apparent_temperature),
      code: wmoCondition(c.weather_code),
      isDay: c.is_day === 1,
      humidity: r1(c.relative_humidity_2m),
      windKph: r1(c.wind_speed_10m),
      windDir: c.wind_direction_10m,
      gustKph: r1(c.wind_gusts_10m),
      pressureHpa: r1(c.pressure_msl),
      uv: r1(c.uv_index),
      cloud: r1(c.cloud_cover),
      dewPoint: r1(c.dew_point_2m),
    },
    hours,
    days,
    updatedAt: new Date().toISOString(),
    sources: [OPEN_METEO],
  };
}

/** Adds Open-Meteo's rain chances and UV to MET Norway's forecast (MET has neither for most places). */
export function mergeChances(met: WeatherData, om: WeatherData): WeatherData {
  const byHour = new Map(om.hours.map((h) => [h.t.slice(0, 13), h]));
  const byDay = new Map(om.days.map((d) => [d.date, d]));
  return {
    ...met,
    now: { ...met.now, uv: om.now.uv ?? met.now.uv },
    hours: met.hours.map((h) => ({
      ...h,
      chance: byHour.get(h.t.slice(0, 13))?.chance ?? h.chance,
    })),
    // MET's forecast starts now, so today's high and low would miss the hours already gone:
    // Open-Meteo's daily figures cover the whole day.
    days: met.days.map((d) => {
      const o = byDay.get(d.date);
      return {
        ...d,
        high: Number.isFinite(o?.high) ? (o?.high as number) : d.high,
        low: Number.isFinite(o?.low) ? (o?.low as number) : d.low,
        chance: o?.chance ?? d.chance,
        uv: o?.uv ?? d.uv,
      };
    }),
    sources: [...met.sources, OPEN_METEO],
  };
}

export interface WeatherAlertItem {
  severity: "minor" | "moderate" | "severe" | "extreme" | "unknown";
  event: string;
  headline?: string;
  area?: string;
  start?: string;
  end?: string;
  instruction?: string;
  issuer?: string;
  url?: string;
}

/** Active NWS alerts for a point in the US; other countries have no alerts source yet. */
export async function nwsAlerts(http: LiveHttp, place: Place): Promise<WeatherAlertItem[]> {
  if (place.country && place.country !== "US") return [];
  const r = await http.json<{
    features?: Array<{
      properties: {
        severity?: string;
        event?: string;
        headline?: string;
        areaDesc?: string;
        onset?: string;
        effective?: string;
        ends?: string;
        expires?: string;
        instruction?: string;
        senderName?: string;
        "@id"?: string;
      };
    }>;
  }>(`https://api.weather.gov/alerts/active?point=${coord(place.lat, 4)},${coord(place.lng, 4)}`, {
    headers: { accept: "application/geo+json" },
  });
  return (r.features ?? []).slice(0, 6).map(({ properties: p }) => ({
    severity: (["minor", "moderate", "severe", "extreme"].includes(String(p.severity).toLowerCase())
      ? String(p.severity).toLowerCase()
      : "unknown") as WeatherAlertItem["severity"],
    event: p.event ?? "Alert",
    headline: p.headline?.slice(0, 300),
    area: p.areaDesc?.slice(0, 200),
    start: p.onset ?? p.effective,
    end: p.ends ?? p.expires,
    instruction: p.instruction?.slice(0, 600),
    issuer: p.senderName,
    url: p["@id"],
  }));
}

export interface AirData {
  aqi: number;
  scale: "us";
  dominant?: string;
  pollutants: Array<{ id: string; value: number; unit: string }>;
  hours: Array<{ t: string; aqi: number }>;
  pollen?: Array<{ kind: string; value: number }>;
  uv?: number;
}

export async function openMeteoAir(
  http: LiveHttp,
  place: Place,
  tz: string,
  key?: string,
): Promise<AirData> {
  const q = new URLSearchParams({
    latitude: String(coord(place.lat)),
    longitude: String(coord(place.lng)),
    timezone: tz,
    current:
      "us_aqi,pm2_5,pm10,ozone,nitrogen_dioxide,sulphur_dioxide,carbon_monoxide,uv_index,alder_pollen,birch_pollen,grass_pollen,mugwort_pollen,olive_pollen,ragweed_pollen",
    hourly: "us_aqi",
    forecast_days: "2",
  });
  if (key) q.set("apikey", key);
  const base = key
    ? "https://customer-air-quality-api.open-meteo.com"
    : "https://air-quality-api.open-meteo.com";
  const r = await http.json<OmForecast>(`${base}/v1/air-quality?${q}`);
  const c = r.current ?? {};
  if (typeof c.us_aqi !== "number")
    throw new LiveDataError("not_found", "No air quality data for this place.");
  const pollutants = [
    { id: "pm2_5", value: c.pm2_5, unit: "µg/m³" },
    { id: "pm10", value: c.pm10, unit: "µg/m³" },
    { id: "o3", value: c.ozone, unit: "µg/m³" },
    { id: "no2", value: c.nitrogen_dioxide, unit: "µg/m³" },
    { id: "so2", value: c.sulphur_dioxide, unit: "µg/m³" },
    { id: "co", value: c.carbon_monoxide, unit: "µg/m³" },
  ].filter((p): p is { id: string; value: number; unit: string } => typeof p.value === "number");
  // The pollutant whose share of its own "unhealthy" level is highest.
  const limits: Record<string, number> = {
    pm2_5: 35,
    pm10: 150,
    o3: 140,
    no2: 190,
    so2: 200,
    co: 10000,
  };
  const dominant = [...pollutants].sort(
    (a, b) => b.value / (limits[b.id] ?? 1) - a.value / (limits[a.id] ?? 1),
  )[0]?.id;
  const pollen = [
    ["alder", c.alder_pollen],
    ["birch", c.birch_pollen],
    ["grass", c.grass_pollen],
    ["mugwort", c.mugwort_pollen],
    ["olive", c.olive_pollen],
    ["ragweed", c.ragweed_pollen],
  ]
    .filter((p): p is [string, number] => typeof p[1] === "number")
    .map(([kind, value]) => ({ kind, value }));
  const time = (r.hourly?.time ?? []) as string[];
  const hours = time
    .map((t, i) => ({
      t: isoInZone(zonedTime(t.slice(0, 10), tz, Number(t.slice(11, 13))), tz),
      aqi: r.hourly?.us_aqi?.[i] as number,
    }))
    .filter((h) => typeof h.aqi === "number" && Date.parse(h.t) >= Date.now() - 3600000)
    .slice(0, 24);
  return {
    aqi: Math.round(c.us_aqi),
    scale: "us",
    dominant,
    pollutants,
    hours,
    pollen: pollen.length ? pollen : undefined,
    uv: r1(c.uv_index),
  };
}

/** Cache keys round to 0.1° (~11 km): neighbours share an answer, nobody's address is kept. */
export const weatherKey = (place: Place, tz: string) =>
  `${place.lat.toFixed(1)},${place.lng.toFixed(1)}|${tz}`;

export interface WeatherDeps {
  http: LiveHttp;
  cache: LiveCache;
  /** Open-Meteo may be used (its key, or a server that doesn't bill people). */
  openMeteo: boolean;
  openMeteoKey?: string;
}

/** The forecast for a place: MET Norway plus Open-Meteo's chances, or whichever answers. */
export async function getWeather(deps: WeatherDeps, place: Place, tz: string, force = false) {
  const key = weatherKey(place, tz);
  const met = deps.cache
    .get(MET_NORWAY.id, key, 30 * 60, () => metForecast(deps.http, place, tz), {
      force,
      minAgeSeconds: 60,
    })
    .catch((e: unknown) => e as Error);
  const om = deps.openMeteo
    ? deps.cache
        .get(
          OPEN_METEO.id,
          key,
          60 * 60,
          () => openMeteoForecast(deps.http, place, tz, deps.openMeteoKey),
          {
            force,
            minAgeSeconds: 300,
          },
        )
        .catch((e: unknown) => e as Error)
    : Promise.resolve(null);
  const [m, o] = await Promise.all([met, om]);
  if (!(m instanceof Error) && o && !(o instanceof Error))
    return { data: mergeChances(m.value, o.value), fetchedAt: m.fetchedAt, stale: m.stale };
  if (!(m instanceof Error)) return { data: m.value, fetchedAt: m.fetchedAt, stale: m.stale };
  if (o && !(o instanceof Error)) return { data: o.value, fetchedAt: o.fetchedAt, stale: o.stale };
  throw m instanceof LiveDataError
    ? m
    : new LiveDataError("upstream", "No weather provider answered.");
}

export { addDays };
