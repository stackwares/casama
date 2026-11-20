/**
 * The rest of the live data (RICH-CARDS-PLAN §6): holidays, earthquakes, storms, encyclopedia
 * summaries, word definitions, books, sports scores, flights, parcels and films. Free public
 * sources where they exist; paid ones (flights, parcels, films) only with a key.
 */
import { type LiveCache, LiveDataError, type LiveHttp, type LiveSource } from "./core.ts";

export const NAGER: LiveSource = {
  id: "nager_date",
  name: "Nager.Date",
  url: "https://date.nager.at/",
};
export const USGS: LiveSource = { id: "usgs", name: "USGS", url: "https://earthquake.usgs.gov/" };
export const GDACS: LiveSource = {
  id: "gdacs",
  name: "GDACS (EU JRC)",
  url: "https://www.gdacs.org/",
};
export const WIKIPEDIA: LiveSource = {
  id: "wikipedia",
  name: "Wikipedia",
  url: "https://www.wikipedia.org/",
  license: "CC BY-SA 4.0",
};
export const WIKTIONARY: LiveSource = {
  id: "free_dictionary",
  name: "Wiktionary via Free Dictionary API",
  url: "https://dictionaryapi.dev/",
  license: "CC BY-SA 3.0",
};
export const OPEN_LIBRARY: LiveSource = {
  id: "open_library",
  name: "Open Library",
  url: "https://openlibrary.org/",
};
export const ESPN: LiveSource = { id: "espn", name: "ESPN", url: "https://www.espn.com/" };
export const AVIATIONSTACK: LiveSource = {
  id: "aviationstack",
  name: "aviationstack",
  url: "https://aviationstack.com/",
};
export const SEVENTEEN_TRACK: LiveSource = {
  id: "17track",
  name: "17TRACK",
  url: "https://www.17track.net/",
};
export const TMDB: LiveSource = { id: "tmdb", name: "TMDB", url: "https://www.themoviedb.org/" };

export interface WorldDeps {
  http: LiveHttp;
  cache: LiveCache;
  /** Public endpoints without published terms (ESPN): only where `LIVE_STOCKS_UNOFFICIAL` allows. */
  unofficial: boolean;
  aviationstackKey?: string;
  seventeenTrackKey?: string;
  tmdbKey?: string;
}

// ---------------------------------------------------------------------------------------------
// Holidays
// ---------------------------------------------------------------------------------------------

export interface Holiday {
  date: string;
  name: string;
  localName?: string;
  types?: string[];
}

export async function holidays(d: WorldDeps, country: string, year: number) {
  const cc = country.trim().toUpperCase();
  if (!/^[A-Z]{2}$/.test(cc))
    throw new LiveDataError("bad_country", "Give a two-letter country code, like PH or US.");
  const r = await d.cache.get(NAGER.id, `${cc}|${year}`, 7 * 86400, () =>
    d.http.json<
      Array<{ date: string; name: string; localName?: string; types?: string[]; global?: boolean }>
    >(`https://date.nager.at/api/v3/PublicHolidays/${year}/${cc}`),
  );
  const list: Holiday[] = r.value
    .filter((h) => h.global !== false)
    .map((h) => ({
      date: h.date,
      name: h.name,
      localName: h.localName !== h.name ? h.localName : undefined,
      types: h.types,
    }));
  return { list, fetchedAt: r.fetchedAt, stale: r.stale };
}

// ---------------------------------------------------------------------------------------------
// Earthquakes and storms
// ---------------------------------------------------------------------------------------------

export interface Quake {
  id: string;
  magnitude: number;
  place: string;
  time: string;
  lat: number;
  lng: number;
  depthKm: number;
  distanceKm?: number;
  tsunami?: boolean;
  felt?: number;
  alert?: string;
  url?: string;
}

export function distanceKm(a: { lat: number; lng: number }, b: { lat: number; lng: number }) {
  const R = 6371;
  const dLat = ((b.lat - a.lat) * Math.PI) / 180;
  const dLng = ((b.lng - a.lng) * Math.PI) / 180;
  const s =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((a.lat * Math.PI) / 180) * Math.cos((b.lat * Math.PI) / 180) * Math.sin(dLng / 2) ** 2;
  return Math.round(2 * R * Math.asin(Math.sqrt(s)));
}

export async function quakes(
  d: WorldDeps,
  opts: {
    near?: { lat: number; lng: number };
    radiusKm?: number;
    minMagnitude?: number;
    days?: number;
  },
) {
  const min = opts.minMagnitude ?? (opts.near ? 2.5 : 4.5);
  const feed = min >= 4.5 ? "4.5" : min >= 2.5 ? "2.5" : "1.0";
  const span = (opts.days ?? 1) > 1 ? "week" : "day";
  const r = await d.cache.get(USGS.id, `${feed}_${span}`, 300, () =>
    d.http.json<{
      features?: Array<{
        id: string;
        properties: {
          mag: number;
          place: string;
          time: number;
          tsunami?: number;
          felt?: number;
          alert?: string;
          url?: string;
        };
        geometry: { coordinates: [number, number, number] };
      }>;
    }>(`https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/${feed}_${span}.geojson`),
  );
  let list: Quake[] = (r.value.features ?? []).map((f) => ({
    id: f.id,
    magnitude: Math.round(f.properties.mag * 10) / 10,
    place: f.properties.place,
    time: new Date(f.properties.time).toISOString(),
    lng: f.geometry.coordinates[0],
    lat: f.geometry.coordinates[1],
    depthKm: Math.round(f.geometry.coordinates[2]),
    tsunami: f.properties.tsunami === 1,
    felt: f.properties.felt ?? undefined,
    alert: f.properties.alert ?? undefined,
    url: f.properties.url,
  }));
  list = list.filter((q) => q.magnitude >= min);
  if (opts.near) {
    const near = opts.near;
    list = list
      .map((q) => ({ ...q, distanceKm: distanceKm(near, q) }))
      .filter((q) => (q.distanceKm ?? 0) <= (opts.radiusKm ?? 1000))
      .sort((a, b) => Date.parse(b.time) - Date.parse(a.time));
  } else list.sort((a, b) => b.magnitude - a.magnitude);
  return { list: list.slice(0, 10), fetchedAt: r.fetchedAt, stale: r.stale };
}

export interface Storm {
  id: string;
  name: string;
  alert: string;
  category?: string;
  windKph?: number;
  lat: number;
  lng: number;
  from?: string;
  to?: string;
  countries?: string;
  url?: string;
  distanceKm?: number;
  track?: Array<{ lat: number; lng: number }>;
}

/** Active tropical cyclones from GDACS, nearest first when a place is given. */
export async function storms(d: WorldDeps, near?: { lat: number; lng: number }) {
  const r = await d.cache.get(GDACS.id, "tc_active", 600, async () => {
    const body = await d.http.json<{
      features?: Array<{
        geometry: { coordinates: [number, number] };
        properties: {
          eventid: number;
          name: string;
          eventname?: string;
          alertlevel?: string;
          fromdate?: string;
          todate?: string;
          iscurrent?: string;
          affectedcountries?: Array<{ countryname: string }>;
          severitydata?: { severity?: number; severitytext?: string; severityunit?: string };
          url?: { report?: string };
        };
      }>;
    }>(
      "https://www.gdacs.org/gdacsapi/api/events/geteventlist/SEARCH?eventlist=TC&alertlevel=Green;Orange;Red",
    );
    const recent = Date.now() - 3 * 86400000;
    return (body.features ?? [])
      .filter(
        (f) => f.properties.iscurrent === "true" || Date.parse(f.properties.todate ?? "") > recent,
      )
      .slice(0, 20)
      .map(
        (f): Storm => ({
          id: String(f.properties.eventid),
          name: (f.properties.eventname ?? f.properties.name).replace(/-\d{2}$/, ""),
          alert: (f.properties.alertlevel ?? "Green").toLowerCase(),
          category: f.properties.severitydata?.severitytext?.slice(0, 120),
          windKph:
            f.properties.severitydata?.severityunit === "km/h"
              ? Math.round(f.properties.severitydata.severity ?? 0)
              : undefined,
          lng: f.geometry.coordinates[0],
          lat: f.geometry.coordinates[1],
          from: f.properties.fromdate,
          to: f.properties.todate,
          countries:
            (f.properties.affectedcountries ?? [])
              .map((c) => c.countryname)
              .slice(0, 6)
              .join(", ") || undefined,
          url: f.properties.url?.report,
        }),
      );
  });
  let list = r.value;
  if (near)
    list = list
      .map((s) => ({ ...s, distanceKm: distanceKm(near, s) }))
      .sort((a, b) => (a.distanceKm ?? 0) - (b.distanceKm ?? 0));
  return { list: list.slice(0, 6), fetchedAt: r.fetchedAt, stale: r.stale };
}

// ---------------------------------------------------------------------------------------------
// Reference
// ---------------------------------------------------------------------------------------------

export interface WikiSummary {
  title: string;
  description?: string;
  extract: string;
  imageUrl?: string;
  url: string;
  lang: string;
}

export async function wikiSummary(d: WorldDeps, topic: string, lang = "en") {
  const l = /^[a-z]{2,3}$/.test(lang) ? lang : "en";
  const r = await d.cache.get(WIKIPEDIA.id, `${l}|${topic.toLowerCase()}`, 7 * 86400, async () => {
    const title = encodeURIComponent(topic.trim().replaceAll(" ", "_"));
    let body = await d.http
      .json<Record<string, unknown>>(
        `https://${l}.wikipedia.org/api/rest_v1/page/summary/${title}?redirect=true`,
      )
      .catch(() => null);
    if (!body || body.type === "disambiguation" || !body.extract) {
      // Search for the best page and read its summary.
      const s = await d.http.json<{ pages?: Array<{ key: string }> }>(
        `https://${l}.wikipedia.org/w/rest.php/v1/search/page?q=${encodeURIComponent(topic)}&limit=1`,
      );
      const key = s.pages?.[0]?.key;
      if (!key) throw new LiveDataError("not_found", `Wikipedia has no page about "${topic}".`);
      body = await d.http.json<Record<string, unknown>>(
        `https://${l}.wikipedia.org/api/rest_v1/page/summary/${encodeURIComponent(key)}`,
      );
    }
    const thumb = (body.originalimage ?? body.thumbnail) as { source?: string } | undefined;
    const urls = body.content_urls as { desktop?: { page?: string } } | undefined;
    return {
      title: String(body.title ?? topic),
      description: typeof body.description === "string" ? body.description : undefined,
      extract: String(body.extract ?? "").slice(0, 1200),
      imageUrl: thumb?.source?.startsWith("https://") ? thumb.source : undefined,
      url: urls?.desktop?.page ?? `https://${l}.wikipedia.org/wiki/${encodeURIComponent(topic)}`,
      lang: l,
    } satisfies WikiSummary;
  });
  return { summary: r.value, fetchedAt: r.fetchedAt, stale: r.stale };
}

export interface Definition {
  word: string;
  phonetic?: string;
  audioUrl?: string;
  senses: Array<{ pos?: string; meaning: string; example?: string }>;
  synonyms: string[];
  url?: string;
}

export async function define(d: WorldDeps, word: string) {
  const w = word.trim().toLowerCase();
  if (!/^[\p{L}' -]{1,40}$/u.test(w))
    throw new LiveDataError("bad_word", "Give one word or a short phrase.");
  const r = await d.cache.get(WIKTIONARY.id, w, 30 * 86400, async () => {
    const body = await d.http.json<
      Array<{
        word: string;
        phonetic?: string;
        phonetics?: Array<{ text?: string; audio?: string }>;
        meanings?: Array<{
          partOfSpeech?: string;
          definitions?: Array<{ definition: string; example?: string; synonyms?: string[] }>;
          synonyms?: string[];
        }>;
        sourceUrls?: string[];
      }>
    >(`https://api.dictionaryapi.dev/api/v2/entries/en/${encodeURIComponent(w)}`);
    const e = body[0];
    if (!e) throw new LiveDataError("not_found", `No definition for "${word}".`);
    const audio = body
      .flatMap((x) => x.phonetics ?? [])
      .find((p) => p.audio?.startsWith("https://"))?.audio;
    const senses: Definition["senses"] = [];
    const synonyms = new Set<string>();
    for (const x of body)
      for (const m of x.meanings ?? []) {
        for (const s of m.synonyms ?? []) synonyms.add(s);
        for (const def of (m.definitions ?? []).slice(0, 3))
          if (senses.length < 8)
            senses.push({ pos: m.partOfSpeech, meaning: def.definition, example: def.example });
      }
    return {
      word: e.word,
      phonetic: e.phonetic ?? body.flatMap((x) => x.phonetics ?? []).find((p) => p.text)?.text,
      audioUrl: audio,
      senses,
      synonyms: [...synonyms].slice(0, 10),
      url: e.sourceUrls?.[0],
    } satisfies Definition;
  });
  return { def: r.value, fetchedAt: r.fetchedAt, stale: r.stale };
}

export interface Book {
  title: string;
  author?: string;
  year?: number;
  pages?: number;
  rating?: number;
  ratings?: number;
  coverUrl?: string;
  subjects?: string[];
  url: string;
}

export async function findBook(d: WorldDeps, query: string) {
  const r = await d.cache.get(OPEN_LIBRARY.id, query.toLowerCase(), 7 * 86400, async () => {
    const body = await d.http.json<{
      docs?: Array<{
        key: string;
        title: string;
        author_name?: string[];
        first_publish_year?: number;
        number_of_pages_median?: number;
        ratings_average?: number;
        ratings_count?: number;
        cover_i?: number;
        subject?: string[];
      }>;
    }>(
      `https://openlibrary.org/search.json?q=${encodeURIComponent(query)}&limit=1&fields=key,title,author_name,first_publish_year,number_of_pages_median,ratings_average,ratings_count,cover_i,subject`,
      { timeoutMs: 12000 },
    );
    const b = body.docs?.[0];
    if (!b) throw new LiveDataError("not_found", `No book matches "${query}".`);
    return {
      title: b.title,
      author: b.author_name?.slice(0, 2).join(", "),
      year: b.first_publish_year,
      pages: b.number_of_pages_median,
      rating: b.ratings_average ? Math.round(b.ratings_average * 10) / 10 : undefined,
      ratings: b.ratings_count,
      coverUrl: b.cover_i ? `https://covers.openlibrary.org/b/id/${b.cover_i}-L.jpg` : undefined,
      subjects: b.subject?.slice(0, 4),
      url: `https://openlibrary.org${b.key}`,
    } satisfies Book;
  });
  return { book: r.value, fetchedAt: r.fetchedAt, stale: r.stale };
}

// ---------------------------------------------------------------------------------------------
// Sports (ESPN's public scoreboards)
// ---------------------------------------------------------------------------------------------

/** Leagues people ask for, to ESPN's sport and league path. */
export const LEAGUES: Record<string, { path: string; name: string; kind: "team" | "race" }> = {
  nba: { path: "basketball/nba", name: "NBA", kind: "team" },
  wnba: { path: "basketball/wnba", name: "WNBA", kind: "team" },
  ncaab: {
    path: "basketball/mens-college-basketball",
    name: "NCAA Men's Basketball",
    kind: "team",
  },
  epl: { path: "soccer/eng.1", name: "Premier League", kind: "team" },
  laliga: { path: "soccer/esp.1", name: "LaLiga", kind: "team" },
  seriea: { path: "soccer/ita.1", name: "Serie A", kind: "team" },
  bundesliga: { path: "soccer/ger.1", name: "Bundesliga", kind: "team" },
  ligue1: { path: "soccer/fra.1", name: "Ligue 1", kind: "team" },
  ucl: { path: "soccer/uefa.champions", name: "Champions League", kind: "team" },
  mls: { path: "soccer/usa.1", name: "MLS", kind: "team" },
  nfl: { path: "football/nfl", name: "NFL", kind: "team" },
  mlb: { path: "baseball/mlb", name: "MLB", kind: "team" },
  nhl: { path: "hockey/nhl", name: "NHL", kind: "team" },
  f1: { path: "racing/f1", name: "Formula 1", kind: "race" },
};

export interface Game {
  id: string;
  league: string;
  name: string;
  start: string;
  state: "pre" | "in" | "post";
  detail: string;
  clock?: string;
  period?: number;
  venue?: string;
  teams: Array<{
    name: string;
    abbr?: string;
    score?: string;
    logoUrl?: string;
    color?: string;
    record?: string;
    home?: boolean;
    winner?: boolean;
  }>;
  url?: string;
}

interface EspnEvent {
  id: string;
  name: string;
  date: string;
  status: {
    displayClock?: string;
    period?: number;
    type: { state: "pre" | "in" | "post"; detail?: string; shortDetail?: string };
  };
  links?: Array<{ href?: string }>;
  competitions?: Array<{
    venue?: { fullName?: string };
    competitors?: Array<{
      homeAway?: string;
      score?: string | { displayValue?: string };
      winner?: boolean;
      order?: number;
      team?: { displayName?: string; abbreviation?: string; logo?: string; color?: string };
      athlete?: { displayName?: string; flag?: { href?: string } };
      records?: Array<{ summary?: string }>;
    }>;
  }>;
}

function espnGame(league: string, e: EspnEvent): Game {
  const c = e.competitions?.[0];
  const teams = (c?.competitors ?? []).slice(0, 20).map((t) => ({
    name: t.team?.displayName ?? t.athlete?.displayName ?? "?",
    abbr: t.team?.abbreviation,
    score: typeof t.score === "object" ? t.score?.displayValue : t.score,
    logoUrl: (t.team?.logo ?? t.athlete?.flag?.href)?.startsWith("https://")
      ? (t.team?.logo ?? t.athlete?.flag?.href)
      : undefined,
    color: t.team?.color,
    record: t.records?.[0]?.summary,
    home: t.homeAway === "home",
    winner: t.winner,
  }));
  // Away team first, as scoreboards show it ("GSW at MEM").
  teams.sort((a, b) => Number(a.home) - Number(b.home));
  return {
    id: e.id,
    league,
    name: e.name,
    start: e.date,
    state: e.status.type.state,
    detail: e.status.type.shortDetail ?? e.status.type.detail ?? "",
    clock: e.status.displayClock,
    period: e.status.period,
    venue: c?.venue?.fullName,
    teams,
    url: e.links?.[0]?.href,
  };
}

export async function scoreboard(
  d: WorldDeps,
  league: string,
  opts: { team?: string; date?: string } = {},
) {
  if (!d.unofficial)
    throw new LiveDataError("no_provider", "Sports scores aren't set up on this server.");
  const l = LEAGUES[league];
  if (!l) throw new LiveDataError("bad_league", `Leagues: ${Object.keys(LEAGUES).join(", ")}.`);
  const date = opts.date?.replaceAll("-", "");
  const r = await d.cache.get(ESPN.id, `scoreboard|${league}|${date ?? "today"}`, 30, () =>
    d.http.json<{ events?: EspnEvent[] }>(
      `https://site.api.espn.com/apis/site/v2/sports/${l.path}/scoreboard${date ? `?dates=${date}` : ""}`,
      ESPN_HEADERS,
    ),
  );
  let games = (r.value.events ?? []).map((e) => espnGame(l.name, e));
  if (opts.team) {
    const t = opts.team.toLowerCase();
    games = games.filter((g) =>
      g.teams.some((x) => x.name.toLowerCase().includes(t) || x.abbr?.toLowerCase() === t),
    );
  }
  return { games: games.slice(0, 12), fetchedAt: r.fetchedAt, stale: r.stale };
}

/** ESPN's edge refuses user agents with a link in them. */
const ESPN_HEADERS = { headers: { "user-agent": "Mozilla/5.0 (compatible; Casama/1.0)" } };

export interface StandingRow {
  rank: number;
  team: string;
  logoUrl?: string;
  played?: number;
  won?: number;
  drawn?: number;
  lost?: number;
  points?: number;
  diff?: string;
  pct?: string;
}

export async function standings(d: WorldDeps, league: string) {
  if (!d.unofficial)
    throw new LiveDataError("no_provider", "Sports standings aren't set up on this server.");
  const l = LEAGUES[league];
  if (l?.kind !== "team") throw new LiveDataError("bad_league", "Standings are for team leagues.");
  const r = await d.cache.get(ESPN.id, `standings|${league}`, 1800, () =>
    d.http.json<{
      children?: Array<{
        name?: string;
        standings?: {
          entries?: Array<{
            team: { displayName: string; logos?: Array<{ href?: string }> };
            stats: Array<{ name: string; value?: number; displayValue?: string }>;
          }>;
        };
      }>;
    }>(`https://site.api.espn.com/apis/v2/sports/${l.path}/standings`, ESPN_HEADERS),
  );
  const groups = (r.value.children ?? []).map((g) => ({
    name: g.name ?? l.name,
    rows: (g.standings?.entries ?? []).map((e): StandingRow => {
      const st = Object.fromEntries(e.stats.map((s) => [s.name, s]));
      const num = (k: string) =>
        typeof st[k]?.value === "number" ? (st[k]?.value as number) : undefined;
      return {
        rank: num("rank") ?? num("playoffSeed") ?? 0,
        team: e.team.displayName,
        logoUrl: e.team.logos?.[0]?.href,
        played: num("gamesPlayed"),
        won: num("wins"),
        drawn: num("ties"),
        lost: num("losses"),
        points: num("points"),
        diff: st.pointDifferential?.displayValue ?? st.differential?.displayValue,
        pct: st.winPercent?.displayValue,
      };
    }),
  }));
  for (const g of groups) {
    g.rows.sort((a, b) => (a.rank || 999) - (b.rank || 999) || (b.points ?? 0) - (a.points ?? 0));
    g.rows.forEach((row, i) => {
      if (!row.rank) row.rank = i + 1;
    });
  }
  return { league: l.name, groups, fetchedAt: r.fetchedAt, stale: r.stale };
}

// ---------------------------------------------------------------------------------------------
// Flights, parcels and films: paid providers, on only with a key
// ---------------------------------------------------------------------------------------------

export interface FlightData {
  flight: string;
  airline?: string;
  status: string;
  from: {
    code?: string;
    name?: string;
    terminal?: string;
    gate?: string;
    scheduled?: string;
    estimated?: string;
    actual?: string;
    delay?: number;
  };
  to: {
    code?: string;
    name?: string;
    terminal?: string;
    gate?: string;
    baggage?: string;
    scheduled?: string;
    estimated?: string;
    actual?: string;
    delay?: number;
  };
  aircraft?: string;
}

export async function flightStatus(d: WorldDeps, flight: string, date?: string) {
  if (!d.aviationstackKey)
    throw new LiveDataError(
      "no_provider",
      "Flight status isn't set up on this server (an aviationstack key, LIVE_AVIATIONSTACK_KEY).",
    );
  const iata = flight.replace(/\s+/g, "").toUpperCase();
  if (!/^[A-Z0-9]{2}\d{1,4}[A-Z]?$/.test(iata))
    throw new LiveDataError("bad_flight", "Give a flight number like PR102.");
  const r = await d.cache.get(AVIATIONSTACK.id, `${iata}|${date ?? "today"}`, 120, async () => {
    const body = await d.http.json<{
      data?: Array<{
        flight_status?: string;
        flight_date?: string;
        airline?: { name?: string };
        flight?: { iata?: string };
        aircraft?: { iata?: string } | null;
        departure?: Record<string, string | number | null>;
        arrival?: Record<string, string | number | null>;
      }>;
    }>(
      `https://api.aviationstack.com/v1/flights?access_key=${encodeURIComponent(d.aviationstackKey as string)}&flight_iata=${iata}${date ? `&flight_date=${date}` : ""}`,
    );
    const f = body.data?.[0];
    if (!f) throw new LiveDataError("not_found", `No flight ${iata} found.`);
    const end = (x?: Record<string, string | number | null>) => ({
      code: (x?.iata as string) ?? undefined,
      name: (x?.airport as string) ?? undefined,
      terminal: (x?.terminal as string) ?? undefined,
      gate: (x?.gate as string) ?? undefined,
      baggage: (x?.baggage as string) ?? undefined,
      scheduled: (x?.scheduled as string) ?? undefined,
      estimated: (x?.estimated as string) ?? undefined,
      actual: (x?.actual as string) ?? undefined,
      delay: typeof x?.delay === "number" ? x.delay : undefined,
    });
    return {
      flight: f.flight?.iata ?? iata,
      airline: f.airline?.name,
      status: f.flight_status ?? "scheduled",
      from: end(f.departure),
      to: end(f.arrival),
      aircraft: f.aircraft?.iata,
    } satisfies FlightData;
  });
  return { flight: r.value, fetchedAt: r.fetchedAt, stale: r.stale };
}

export interface ParcelData {
  tracking: string;
  carrier?: string;
  status:
    | "info_received"
    | "in_transit"
    | "out_for_delivery"
    | "delivered"
    | "exception"
    | "not_found";
  eta?: string;
  events: Array<{ time: string; place?: string; text: string }>;
}

export async function trackParcel(d: WorldDeps, tracking: string) {
  if (!d.seventeenTrackKey)
    throw new LiveDataError(
      "no_provider",
      "Parcel tracking isn't set up on this server (a 17TRACK key, LIVE_17TRACK_KEY).",
    );
  const number = tracking.replace(/\s+/g, "").toUpperCase();
  if (!/^[A-Z0-9-]{6,40}$/.test(number))
    throw new LiveDataError("bad_tracking", "That doesn't look like a tracking number.");
  const post = async (path: string) => {
    const res = await fetchJsonPost(d, `https://api.17track.net/track/v2.2/${path}`, [{ number }]);
    return res;
  };
  await post("register").catch(() => {});
  const body = (await post("gettrackinfo")) as {
    data?: {
      accepted?: Array<{
        carrier?: number;
        track_info?: {
          latest_status?: { status?: string };
          time_metrics?: { estimated_delivery_date?: { from?: string } };
          tracking?: {
            providers?: Array<{
              provider?: { name?: string };
              events?: Array<{ time_iso?: string; location?: string; description?: string }>;
            }>;
          };
        };
      }>;
    };
  };
  const a = body.data?.accepted?.[0]?.track_info;
  if (!a) throw new LiveDataError("not_found", "The carrier has no news on that number yet.");
  const map: Record<string, ParcelData["status"]> = {
    InfoReceived: "info_received",
    InTransit: "in_transit",
    OutForDelivery: "out_for_delivery",
    Delivered: "delivered",
    Exception: "exception",
    DeliveryFailure: "exception",
    Expired: "exception",
    NotFound: "not_found",
  };
  const provider = a.tracking?.providers?.[0];
  return {
    parcel: {
      tracking: number,
      carrier: provider?.provider?.name,
      status: map[a.latest_status?.status ?? ""] ?? "in_transit",
      eta: a.time_metrics?.estimated_delivery_date?.from,
      events: (provider?.events ?? [])
        .slice(0, 12)
        .map((e) => ({ time: e.time_iso ?? "", place: e.location, text: e.description ?? "" })),
    } satisfies ParcelData,
    fetchedAt: new Date(),
    stale: false,
  };
}

function fetchJsonPost(d: WorldDeps, url: string, body: unknown) {
  return d.http.post(url, body, { "17token": d.seventeenTrackKey as string });
}

export interface Film {
  kind: "movie" | "show";
  title: string;
  year?: string;
  overview?: string;
  rating?: number;
  posterUrl?: string;
  genres?: string[];
  runtime?: number;
  url: string;
}

export async function findFilm(
  d: WorldDeps,
  query: string,
  kind: "movie" | "show" | "any" = "any",
) {
  if (!d.tmdbKey)
    throw new LiveDataError(
      "no_provider",
      "Film and TV details aren't set up on this server (a TMDB key, LIVE_TMDB_KEY).",
    );
  const r = await d.cache.get(TMDB.id, `${kind}|${query.toLowerCase()}`, 86400, async () => {
    const body = await d.http.json<{
      results?: Array<{
        id: number;
        media_type?: string;
        title?: string;
        name?: string;
        release_date?: string;
        first_air_date?: string;
        overview?: string;
        vote_average?: number;
        poster_path?: string;
      }>;
    }>(`https://api.themoviedb.org/3/search/multi?query=${encodeURIComponent(query)}`, {
      headers: { authorization: `Bearer ${d.tmdbKey}` },
    });
    const f = (body.results ?? []).find((x) =>
      kind === "any"
        ? x.media_type === "movie" || x.media_type === "tv"
        : x.media_type === (kind === "show" ? "tv" : "movie"),
    );
    if (!f) throw new LiveDataError("not_found", `Nothing on TMDB matches "${query}".`);
    const isTv = f.media_type === "tv";
    return {
      kind: isTv ? "show" : "movie",
      title: f.title ?? f.name ?? query,
      year: (f.release_date ?? f.first_air_date ?? "").slice(0, 4) || undefined,
      overview: f.overview?.slice(0, 600),
      rating: f.vote_average ? Math.round(f.vote_average * 10) / 10 : undefined,
      posterUrl: f.poster_path ? `https://image.tmdb.org/t/p/w500${f.poster_path}` : undefined,
      url: `https://www.themoviedb.org/${isTv ? "tv" : "movie"}/${f.id}`,
    } satisfies Film;
  });
  return { film: r.value, fetchedAt: r.fetchedAt, stale: r.stale };
}
