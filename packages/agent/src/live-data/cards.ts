/**
 * From live data to cards (RICH-CARDS-PLAN §4.2, §7): each builder returns the card's fields (SI
 * units and ISO times; the app converts them to the person's units) and a short text for the model,
 * which it shouldn't repeat in full. Numbers in cards come only from here.
 */
import type { LiveBlock } from "@casama/domain";
import { moonIllumination, moonPhaseName, moonTimes, sunTimes } from "./astro.ts";
import type { LiveSource } from "./core.ts";
import type { FxData, QuoteData } from "./markets.ts";
import type { Place } from "./places.ts";
import { addDays, isoInZone, localParts, offsetMinutes, zonedTime } from "./tz.ts";
import type { AirData, WeatherAlertItem, WeatherData } from "./weather.ts";
import type {
  Book,
  Definition,
  Film,
  FlightData,
  Game,
  Holiday,
  ParcelData,
  Quake,
  StandingRow,
  Storm,
  WikiSummary,
} from "./world.ts";

export interface Units {
  temp: "C" | "F";
  wind: "kph" | "mph" | "ms" | "kn";
  precip: "mm" | "in";
  distance: "km" | "mi";
}

export const METRIC: Units = { temp: "C", wind: "kph", precip: "mm", distance: "km" };
export const US_UNITS: Units = { temp: "F", wind: "mph", precip: "in", distance: "mi" };

/** The units a country uses, for people who haven't chosen. */
export function unitsFor(country?: string): Units {
  return country === "US" || country === "LR" || country === "MM" ? US_UNITS : METRIC;
}

const temp = (c: number, u: Units) =>
  u.temp === "F" ? `${Math.round((c * 9) / 5 + 32)}°F` : `${Math.round(c)}°C`;
const speed = (kph: number, u: Units) =>
  u.wind === "mph"
    ? `${Math.round(kph / 1.609)} mph`
    : u.wind === "ms"
      ? `${Math.round(kph / 3.6)} m/s`
      : u.wind === "kn"
        ? `${Math.round(kph / 1.852)} kn`
        : `${Math.round(kph)} km/h`;

export const CONDITION_WORDS: Record<string, string> = {
  clear: "clear",
  mostly_clear: "mostly clear",
  partly_cloudy: "partly cloudy",
  cloudy: "cloudy",
  fog: "foggy",
  drizzle: "drizzle",
  light_rain: "light rain",
  rain: "rain",
  heavy_rain: "heavy rain",
  showers: "showers",
  thunder: "thunderstorms",
  light_snow: "light snow",
  snow: "snow",
  heavy_snow: "heavy snow",
  sleet: "sleet",
  hail: "hail",
};

export interface Built {
  /** The card's own fields (the component, without id). */
  card: Record<string, unknown> & { component: string };
  /** What the model reads. */
  text: string;
  /** Shown on the timeline. */
  preview: string;
  /** For a Lock Screen and a pinned widget: about 24 and 80 characters. */
  tiny?: string;
  short?: string;
}

export function liveBlock(
  sources: LiveSource[],
  fetchedAt: Date,
  staleSeconds: number,
  extra: Partial<LiveBlock> & { stale?: boolean } = {},
): LiveBlock & { stale?: boolean; sources?: LiveSource[] } {
  const [first, ...more] = sources;
  return {
    source: { id: first?.id, name: first?.name ?? "", url: first?.url, license: first?.license },
    ...(more.length ? { sources: more } : {}),
    fetchedAt: fetchedAt.toISOString(),
    staleAfter: new Date(fetchedAt.valueOf() + staleSeconds * 1000).toISOString(),
    ...extra,
  };
}

export function placeOut(p: Place, tz: string) {
  return {
    name: p.name,
    ...(p.region && p.region !== p.name ? { region: p.region } : {}),
    ...(p.country ? { country: p.country } : {}),
    lat: Math.round(p.lat * 100) / 100,
    lng: Math.round(p.lng * 100) / 100,
    tz,
  };
}

/** "now", "today", "tomorrow", a weekday or a date → the date in the place's zone, or null for now. */
export function resolveWhen(
  when: string | undefined,
  tz: string,
  now = new Date(),
): { date: string | null; week: boolean } {
  const today = localParts(now, tz).date;
  const w = (when ?? "now").trim().toLowerCase();
  if (w === "now" || w === "current" || w === "") return { date: null, week: false };
  if (w === "week" || w === "7 days" || w === "forecast" || w === "weekend")
    return { date: null, week: true };
  if (w === "today" || w === "tonight") return { date: today, week: false };
  if (w === "tomorrow") return { date: addDays(today, 1), week: false };
  if (/^\d{4}-\d{2}-\d{2}$/.test(w)) return { date: w, week: false };
  const days = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"];
  const idx = days.findIndex((d) => w.startsWith(d.slice(0, 3)));
  if (idx >= 0) {
    const cur = days.findIndex((d) => d.startsWith(localParts(now, tz).weekday.toLowerCase()));
    const ahead = (idx - cur + 7) % 7 || 7;
    return { date: addDays(today, ahead), week: false };
  }
  return { date: null, week: false };
}

export function weatherCard(
  place: Place,
  w: WeatherData,
  opts: {
    when?: string;
    units: Units;
    alerts?: WeatherAlertItem[];
    fetchedAt: Date;
    stale?: boolean;
    forecast?: boolean;
  },
): Built {
  const tz = w.tz;
  const { date, week } = resolveWhen(opts.when, tz);
  const today = localParts(new Date(), tz).date;
  const day = date ? w.days.find((d) => d.date === date) : undefined;
  const live = liveBlock(w.sources, opts.fetchedAt, 30 * 60, {
    stale: opts.stale,
    views: ["now", "today", "tomorrow", "week"],
  });
  const where = [place.name, place.country].filter(Boolean).join(", ");
  if (week || opts.forecast) {
    const days = w.days.slice(0, 10);
    const lines = days
      .slice(0, 7)
      .map(
        (d) =>
          `${d.date}: ${CONDITION_WORDS[d.code]}, ${temp(d.low, opts.units)}–${temp(d.high, opts.units)}${d.chance !== undefined ? `, rain ${d.chance}%` : d.precipMm ? `, ${d.precipMm} mm` : ""}`,
      );
    return {
      card: { component: "Forecast", place: placeOut(place, tz), days, today, live },
      text: `Forecast for ${where}:\n${lines.join("\n")}`,
      preview: `${place.name}: ${days.length} days`,
      tiny: `${place.name} ${temp(days[0]?.high ?? 0, opts.units)}`,
      short: `${place.name}: ${lines[0] ?? ""}`,
    };
  }
  if (date && !day) return weatherCard(place, w, { ...opts, when: "week" });
  const hours = (date ? w.hours.filter((h) => h.t.startsWith(date)) : w.hours).slice(0, 24);
  const todayDay = w.days.find((d) => d.date === today);
  const head = day ?? todayDay;
  const sun = date ? day : todayDay;
  const rainHours = hours.filter((h) => (h.chance ?? 0) >= 50 || (h.mm ?? 0) >= 0.5);
  const rainLine = rainHours.length
    ? `rain likely around ${rainHours
        .slice(0, 3)
        .map((h) => h.t.slice(11, 16))
        .join(", ")}${rainHours.length > 3 ? "…" : ""}`
    : "no rain expected";
  const text = date
    ? `${where} on ${date}: ${CONDITION_WORDS[day?.code ?? "cloudy"]}, ${temp(day?.low ?? 0, opts.units)} to ${temp(day?.high ?? 0, opts.units)}${day?.chance !== undefined ? `, ${day.chance}% chance of rain` : day?.precipMm ? `, ${day.precipMm} mm of rain` : ""}, wind up to ${speed(day?.windKph ?? 0, opts.units)}${day?.uv ? `, UV ${Math.round(day.uv)}` : ""}; ${rainLine}.`
    : `${where} now: ${temp(w.now.temp, opts.units)}${w.now.feels !== undefined ? ` (feels ${temp(w.now.feels, opts.units)})` : ""}, ${CONDITION_WORDS[w.now.code]}, humidity ${Math.round(w.now.humidity ?? 0)}%, wind ${speed(w.now.windKph ?? 0, opts.units)}. Today ${temp(head?.low ?? 0, opts.units)}–${temp(head?.high ?? 0, opts.units)}; ${rainLine}.`;
  const alerts = (opts.alerts ?? []).map((a) => ({
    severity: a.severity,
    event: a.event,
    until: a.end,
  }));
  return {
    card: {
      component: "Weather",
      place: placeOut(place, tz),
      when: date ?? "now",
      ...(date ? {} : { now: w.now }),
      ...(head ? { day: head } : {}),
      hours,
      days: w.days.slice(0, 7),
      ...(sun?.sunrise ? { sunrise: sun.sunrise, sunset: sun.sunset } : {}),
      ...(alerts.length ? { alerts } : {}),
      live,
    },
    text: `${text}${alerts.length ? ` Alerts: ${alerts.map((a) => a.event).join(", ")}.` : ""}`,
    preview: date ? `${place.name} ${date}` : `${place.name} ${temp(w.now.temp, opts.units)}`,
    tiny: date
      ? `${temp(day?.high ?? 0, opts.units)} ${CONDITION_WORDS[day?.code ?? "cloudy"]}`
      : `${temp(w.now.temp, opts.units)} ${CONDITION_WORDS[w.now.code]}`,
    short: text.slice(0, 80),
  };
}

export function alertCard(
  place: Place,
  tz: string,
  alerts: WeatherAlertItem[],
  fetchedAt: Date,
  source: LiveSource,
): Built {
  return {
    card: {
      component: "WeatherAlert",
      place: placeOut(place, tz),
      alerts,
      live: liveBlock([source], fetchedAt, 10 * 60),
    },
    text: alerts.length
      ? `Active alerts for ${place.name}: ${alerts.map((a) => `${a.event} (${a.severity}${a.end ? `, until ${a.end}` : ""})`).join("; ")}.`
      : `No active weather alerts for ${place.name}.`,
    preview: `${alerts.length} alerts`,
  };
}

export function airCard(
  place: Place,
  tz: string,
  a: AirData,
  fetchedAt: Date,
  source: LiveSource,
): Built {
  const band =
    a.aqi <= 50
      ? "good"
      : a.aqi <= 100
        ? "moderate"
        : a.aqi <= 150
          ? "unhealthy for sensitive groups"
          : a.aqi <= 200
            ? "unhealthy"
            : a.aqi <= 300
              ? "very unhealthy"
              : "hazardous";
  return {
    card: {
      component: "AirQuality",
      place: placeOut(place, tz),
      ...a,
      live: liveBlock([source], fetchedAt, 60 * 60),
    },
    text: `Air quality in ${place.name}: US AQI ${a.aqi} (${band})${a.dominant ? `, mostly ${a.dominant.replace("_", ".")}` : ""}${a.uv !== undefined ? `; UV ${a.uv}` : ""}.`,
    preview: `AQI ${a.aqi}`,
    tiny: `AQI ${a.aqi}`,
  };
}

export function sunMoonCard(place: Place, tz: string, date: string): Built {
  const noon = zonedTime(date, tz, 12);
  const s = sunTimes(noon, place.lat, place.lng);
  const prev = sunTimes(zonedTime(addDays(date, -1), tz, 12), place.lat, place.lng);
  const len = s.sunrise && s.sunset ? (s.sunset.valueOf() - s.sunrise.valueOf()) / 60000 : null;
  const prevLen =
    prev.sunrise && prev.sunset ? (prev.sunset.valueOf() - prev.sunrise.valueOf()) / 60000 : null;
  const m = moonIllumination(noon);
  const mt = moonTimes(zonedTime(date, tz, 0), place.lat, place.lng);
  const iso = (d: Date | null) => (d ? isoInZone(d, tz) : undefined);
  const card = {
    component: "SunMoon",
    place: placeOut(place, tz),
    date,
    sun: {
      sunrise: iso(s.sunrise),
      sunset: iso(s.sunset),
      noon: iso(s.solarNoon),
      dawn: iso(s.dawn),
      dusk: iso(s.dusk),
      goldenMorningEnd: iso(s.goldenMorningEnd),
      goldenEveningStart: iso(s.goldenEveningStart),
      dayMinutes: len === null ? undefined : Math.round(len),
      changeMinutes:
        len === null || prevLen === null ? undefined : Math.round((len - prevLen) * 10) / 10,
      ...(s.polar ? { polar: s.polar } : {}),
    },
    moon: {
      phase: Math.round(m.phase * 1000) / 1000,
      name: moonPhaseName(m.phase),
      illumination: Math.round(m.fraction * 100),
      rise: iso(mt.rise),
      set: iso(mt.set),
    },
    live: liveBlock([{ id: "astro", name: "Calculated by Casama" }], new Date(), 6 * 3600),
  };
  const t = (d?: string) => d?.slice(11, 16) ?? "—";
  return {
    card,
    text: `${place.name} on ${date}: sunrise ${t(card.sun.sunrise)}, sunset ${t(card.sun.sunset)} (local time), golden hour from ${t(card.sun.goldenEveningStart)}; moon ${moonPhaseName(m.phase).replace("_", " ")}, ${card.moon.illumination}% lit.`,
    preview: `Sunrise ${t(card.sun.sunrise)}`,
  };
}

const money = (v: number, cur: string) => {
  try {
    return new Intl.NumberFormat("en-US", {
      style: "currency",
      currency: cur,
      maximumFractionDigits: Math.abs(v) < 1 ? 6 : 2,
    }).format(v);
  } catch {
    return `${v.toFixed(2)} ${cur}`;
  }
};
const pct = (v: number) => `${v >= 0 ? "+" : ""}${v.toFixed(2)}%`;

export function quoteCard(q: QuoteData, fetchedAt: Date, stale: boolean): Built {
  const { source, ...rest } = q;
  return {
    card: {
      component: "Quote",
      ...rest,
      live: liveBlock([source], fetchedAt, q.marketState === "closed" ? 3600 : 60, {
        stale,
        delayed: q.delayedMinutes ?? null,
        views: ["1D", "1W", "1M", "3M", "1Y", "5Y"],
      }),
    },
    text: `${q.name} (${q.symbol}): ${money(q.price, q.currency)}, ${pct(q.changePct)} ${q.kind === "crypto" ? "in 24 h" : q.chart?.range && q.chart.range !== "1D" ? `over ${q.chart.range}` : "today"}${q.marketState !== "24h" ? `, market ${q.marketState}` : ""}${q.delayedMinutes ? `, delayed ${q.delayedMinutes} min` : ""}.`,
    preview: `${q.symbol} ${money(q.price, q.currency)}`,
    tiny: `${q.symbol} ${money(q.price, q.currency)}`,
    short: `${q.symbol} ${money(q.price, q.currency)} ${pct(q.changePct)}`,
  };
}

export function watchlistCard(
  title: string | undefined,
  quotes: QuoteData[],
  fetchedAt: Date,
  stale: boolean,
): Built {
  const sources = [...new Map(quotes.map((q) => [q.source.id, q.source])).values()];
  const rows = quotes.map(({ source: _s, ...q }) => ({
    ...q,
    chart: q.chart
      ? {
          range: q.chart.range,
          points: q.chart.points.filter(
            (_, i, a) => i % Math.ceil(a.length / 40) === 0 || i === a.length - 1,
          ),
        }
      : undefined,
  }));
  return {
    card: {
      component: "Watchlist",
      ...(title ? { title } : {}),
      quotes: rows,
      live: liveBlock(sources, fetchedAt, 60, {
        stale,
        delayed: quotes.some((q) => q.delayedMinutes) ? 15 : null,
      }),
    },
    text: quotes
      .map((q) => `${q.symbol} ${money(q.price, q.currency)} ${pct(q.changePct)}`)
      .join("; "),
    preview: `${quotes.length} quotes`,
    short: quotes
      .slice(0, 3)
      .map((q) => `${q.symbol} ${pct(q.changePct)}`)
      .join(" · "),
  };
}

export function currencyCard(
  fx: FxData,
  fetchedAt: Date,
  stale: boolean,
  source: LiveSource,
): Built {
  const lines = fx.rates.map(
    (r) =>
      `${fx.amount} ${fx.base} = ${(fx.amount * r.rate).toFixed(r.rate * fx.amount >= 100 ? 2 : 4)} ${r.to}`,
  );
  return {
    card: {
      component: "Currency",
      ...fx,
      live: liveBlock([source], fetchedAt, 3 * 3600, { stale }),
    },
    text: `${lines.join("; ")} (reference rates of ${fx.date}).`,
    preview: lines[0] ?? "",
    tiny: lines[0]?.slice(0, 24),
    short: lines.join(" · ").slice(0, 80),
  };
}

export function worldClockCard(places: Array<{ place: Place; tz: string }>, at?: string): Built {
  const now = at ? new Date(at) : new Date();
  const rows = places.map(({ place, tz }) => {
    const p = localParts(now, tz);
    return {
      name: place.name,
      tz,
      country: place.country,
      time: `${String(p.hour).padStart(2, "0")}:${String(p.minute).padStart(2, "0")}`,
      date: p.date,
      offset: offsetMinutes(now, tz),
    };
  });
  return {
    card: {
      component: "WorldClock",
      places: rows.map(({ name, tz, country }) => ({ name, tz, ...(country ? { country } : {}) })),
      ...(at ? { at } : {}),
    },
    text: rows
      .map(
        (r) =>
          `${r.name}: ${r.time} on ${r.date} (UTC${r.offset >= 0 ? "+" : "-"}${Math.floor(Math.abs(r.offset) / 60)}${Math.abs(r.offset) % 60 ? `:${String(Math.abs(r.offset) % 60).padStart(2, "0")}` : ""})`,
      )
      .join("; "),
    preview: rows.map((r) => `${r.name} ${r.time}`).join(", "),
  };
}

export function holidaysCard(
  country: string,
  list: Holiday[],
  fetchedAt: Date,
  opts: { upcoming: boolean; tz?: string },
): Built {
  const today = opts.tz
    ? localParts(new Date(), opts.tz).date
    : new Date().toISOString().slice(0, 10);
  const shown = opts.upcoming
    ? list.filter((h) => h.date >= today).slice(0, 12)
    : list.slice(0, 30);
  return {
    card: {
      component: "Holidays",
      country,
      holidays: shown,
      today,
      live: liveBlock(
        [{ id: "nager_date", name: "Nager.Date", url: "https://date.nager.at/" }],
        fetchedAt,
        86400,
      ),
    },
    text: shown.length
      ? shown.map((h) => `${h.date} ${h.name}`).join("; ")
      : "No more public holidays this year.",
    preview: `${shown.length} holidays`,
  };
}

export function quakeCard(
  list: Quake[],
  fetchedAt: Date,
  near?: { name: string; lat: number; lng: number },
): Built {
  return {
    card: {
      component: "Quake",
      ...(near ? { near } : {}),
      quakes: list,
      live: liveBlock(
        [{ id: "usgs", name: "USGS", url: "https://earthquake.usgs.gov/" }],
        fetchedAt,
        10 * 60,
      ),
    },
    text: list.length
      ? list
          .slice(0, 6)
          .map(
            (q) =>
              `M${q.magnitude} ${q.place} at ${q.time}${q.distanceKm !== undefined ? ` (${q.distanceKm} km away)` : ""}${q.tsunami ? ", tsunami flag" : ""}`,
          )
          .join("; ")
      : `No earthquakes of that size${near ? ` near ${near.name}` : ""} in the last day.`,
    preview: `${list.length} earthquakes`,
  };
}

export function stormCard(
  list: Storm[],
  fetchedAt: Date,
  near?: { name: string; lat: number; lng: number },
): Built {
  return {
    card: {
      component: "Storm",
      ...(near ? { near } : {}),
      storms: list,
      live: liveBlock(
        [{ id: "gdacs", name: "GDACS (EU JRC)", url: "https://www.gdacs.org/" }],
        fetchedAt,
        10 * 60,
      ),
    },
    text: list.length
      ? list
          .map(
            (s) =>
              `${s.name}: ${s.alert} alert${s.windKph ? `, winds ${s.windKph} km/h` : ""}${s.distanceKm !== undefined ? `, ${s.distanceKm} km away` : ""}${s.countries ? `, ${s.countries}` : ""}`,
          )
          .join("; ")
      : "No active tropical storms.",
    preview: `${list.length} storms`,
  };
}

export function summaryCard(s: WikiSummary, fetchedAt: Date): Built {
  return {
    card: {
      component: "Summary",
      title: s.title,
      ...(s.description ? { subtitle: s.description } : {}),
      ...(s.imageUrl ? { imageUrl: s.imageUrl } : {}),
      text: s.extract,
      url: s.url,
      source: { name: "Wikipedia", url: s.url },
      live: liveBlock(
        [{ id: "wikipedia", name: "Wikipedia", url: s.url, license: "CC BY-SA 4.0" }],
        fetchedAt,
        7 * 86400,
      ),
    },
    text: `${s.title}${s.description ? ` (${s.description})` : ""}: ${s.extract}`,
    preview: s.title,
  };
}

export function definitionCard(d: Definition, fetchedAt: Date): Built {
  return {
    card: {
      component: "Definition",
      word: d.word,
      ...(d.phonetic ? { phonetic: d.phonetic } : {}),
      ...(d.audioUrl ? { audioUrl: d.audioUrl } : {}),
      senses: d.senses,
      ...(d.synonyms.length ? { synonyms: d.synonyms } : {}),
      source: { name: "Wiktionary", ...(d.url ? { url: d.url } : {}) },
      live: liveBlock(
        [
          {
            id: "free_dictionary",
            name: "Wiktionary",
            url: d.url ?? "https://www.wiktionary.org/",
            license: "CC BY-SA 3.0",
          },
        ],
        fetchedAt,
        30 * 86400,
      ),
    },
    text: `${d.word}${d.phonetic ? ` ${d.phonetic}` : ""}: ${d.senses
      .slice(0, 3)
      .map((s) => `(${s.pos ?? ""}) ${s.meaning}`)
      .join(" ")}`,
    preview: d.word,
  };
}

export function bookCard(b: Book, fetchedAt: Date): Built {
  const facts = [
    b.author && { label: "Author", value: b.author },
    b.year && { label: "First published", value: String(b.year) },
    b.pages && { label: "Pages", value: String(b.pages) },
    b.subjects?.length && { label: "Subjects", value: b.subjects.join(", ") },
  ].filter(Boolean);
  return {
    card: {
      component: "Media",
      kind: "book",
      title: b.title,
      ...(b.author ? { subtitle: b.author } : {}),
      ...(b.coverUrl ? { imageUrl: b.coverUrl } : {}),
      ...(b.year ? { year: String(b.year) } : {}),
      ...(b.rating ? { rating: b.rating, ratingMax: 5 } : {}),
      facts,
      url: b.url,
      source: { name: "Open Library", url: b.url },
      live: liveBlock(
        [{ id: "open_library", name: "Open Library", url: b.url }],
        fetchedAt,
        7 * 86400,
      ),
    },
    text: `${b.title}${b.author ? ` by ${b.author}` : ""}${b.year ? ` (${b.year})` : ""}${b.rating ? `, rated ${b.rating}/5 on Open Library` : ""}.`,
    preview: b.title,
  };
}

export function filmCard(f: Film, fetchedAt: Date): Built {
  return {
    card: {
      component: "Media",
      kind: f.kind,
      title: f.title,
      ...(f.year ? { year: f.year } : {}),
      ...(f.posterUrl ? { imageUrl: f.posterUrl } : {}),
      ...(f.rating ? { rating: f.rating, ratingMax: 10 } : {}),
      ...(f.overview ? { text: f.overview } : {}),
      url: f.url,
      source: { name: "TMDB", url: f.url },
      live: liveBlock([{ id: "tmdb", name: "TMDB", url: f.url }], fetchedAt, 86400),
    },
    text: `${f.title}${f.year ? ` (${f.year})` : ""}${f.rating ? `, TMDB ${f.rating}/10` : ""}: ${f.overview ?? ""}`,
    preview: f.title,
  };
}

export function scoreCard(league: string, games: Game[], fetchedAt: Date): Built {
  const live = games.some((g) => g.state === "in");
  return {
    card: {
      component: "Score",
      league,
      games,
      live: liveBlock(
        [{ id: "espn", name: "ESPN", url: "https://www.espn.com/" }],
        fetchedAt,
        live ? 30 : 600,
      ),
    },
    text: games.length
      ? games
          .slice(0, 8)
          .map(
            (g) =>
              `${g.teams.map((t) => `${t.abbr ?? t.name}${t.score !== undefined && g.state !== "pre" ? ` ${t.score}` : ""}`).join(" – ")} (${g.detail})`,
          )
          .join("; ")
      : `No ${league} games then.`,
    preview: `${games.length} games`,
  };
}

export function standingsCard(
  league: string,
  groups: Array<{ name: string; rows: StandingRow[] }>,
  fetchedAt: Date,
  team?: string,
): Built {
  const trimmed = groups.slice(0, 2).map((g) => ({ name: g.name, rows: g.rows.slice(0, 20) }));
  return {
    card: {
      component: "Standings",
      league,
      groups: trimmed,
      ...(team ? { highlight: team } : {}),
      live: liveBlock(
        [{ id: "espn", name: "ESPN", url: "https://www.espn.com/" }],
        fetchedAt,
        1800,
      ),
    },
    text: trimmed
      .map(
        (g) =>
          `${g.name}: ${g.rows
            .slice(0, 6)
            .map(
              (r) =>
                `${r.rank}. ${r.team}${r.points !== undefined ? ` ${r.points} pts` : r.pct ? ` ${r.pct}` : ""}`,
            )
            .join(", ")}`,
      )
      .join("; "),
    preview: league,
  };
}

export function flightCard(f: FlightData, fetchedAt: Date): Built {
  return {
    card: {
      component: "Flight",
      ...f,
      live: liveBlock(
        [{ id: "aviationstack", name: "aviationstack", url: "https://aviationstack.com/" }],
        fetchedAt,
        120,
      ),
    },
    text: `${f.flight}${f.airline ? ` (${f.airline})` : ""} ${f.from.code}→${f.to.code}: ${f.status}; departs ${f.from.estimated ?? f.from.scheduled}${f.from.gate ? ` gate ${f.from.gate}` : ""}, arrives ${f.to.estimated ?? f.to.scheduled}${f.from.delay ? `, ${f.from.delay} min late` : ""}.`,
    preview: `${f.flight} ${f.status}`,
    tiny: `${f.flight} ${f.status}`,
  };
}

export function parcelCard(p: ParcelData, fetchedAt: Date): Built {
  return {
    card: {
      component: "Parcel",
      ...p,
      live: liveBlock(
        [{ id: "17track", name: "17TRACK", url: "https://www.17track.net/" }],
        fetchedAt,
        3600,
      ),
    },
    text: `Parcel ${p.tracking}${p.carrier ? ` (${p.carrier})` : ""}: ${p.status.replaceAll("_", " ")}${p.eta ? `, expected ${p.eta}` : ""}; last: ${p.events[0]?.text ?? "no scans yet"}.`,
    preview: p.status,
    tiny: p.status.replaceAll("_", " "),
  };
}
