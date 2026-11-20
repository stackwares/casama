/**
 * Markets and money (RICH-CARDS-PLAN §6.2, §7.6, §7.8): crypto from CoinGecko (a free Demo key
 * when set), stocks from Finnhub (a key) and Yahoo Finance's public chart API (unofficial: only
 * on servers that don't bill people, or when `LIVE_STOCKS_UNOFFICIAL=on`), exchange rates from
 * Frankfurter (central bank reference rates, free for commercial use). Quotes are shown as delayed.
 */
import { type LiveCache, LiveDataError, type LiveHttp, type LiveSource } from "./core.ts";

export const COINGECKO: LiveSource = {
  id: "coingecko",
  name: "CoinGecko",
  url: "https://www.coingecko.com/",
};
export const FINNHUB: LiveSource = { id: "finnhub", name: "Finnhub", url: "https://finnhub.io/" };
export const YAHOO: LiveSource = {
  id: "yahoo_finance",
  name: "Yahoo Finance",
  url: "https://finance.yahoo.com/",
};
export const FRANKFURTER: LiveSource = {
  id: "frankfurter",
  name: "Frankfurter (central bank rates)",
  url: "https://frankfurter.dev/",
};

export type ChartRange = "1D" | "1W" | "1M" | "3M" | "1Y" | "5Y";
export const CHART_RANGES: ChartRange[] = ["1D", "1W", "1M", "3M", "1Y", "5Y"];

export interface QuoteData {
  symbol: string;
  name: string;
  kind: "stock" | "etf" | "index" | "crypto" | "fund" | "currency" | "commodity";
  exchange?: string;
  currency: string;
  price: number;
  change: number;
  changePct: number;
  prevClose?: number;
  open?: number;
  dayLow?: number;
  dayHigh?: number;
  low52?: number;
  high52?: number;
  volume?: number;
  marketCap?: number;
  logoUrl?: string;
  marketState: "pre" | "open" | "post" | "closed" | "24h";
  asOf: string;
  delayedMinutes?: number;
  chart?: { range: ChartRange; points: Array<[number, number]> };
  source: LiveSource;
}

/** Common tickers to CoinGecko ids, so "BTC" needs no search call. */
const COINS: Record<string, string> = {
  BTC: "bitcoin",
  ETH: "ethereum",
  SOL: "solana",
  XRP: "ripple",
  BNB: "binancecoin",
  DOGE: "dogecoin",
  ADA: "cardano",
  TRX: "tron",
  TON: "the-open-network",
  AVAX: "avalanche-2",
  LINK: "chainlink",
  DOT: "polkadot",
  POL: "polygon-ecosystem-token",
  MATIC: "polygon-ecosystem-token",
  LTC: "litecoin",
  SHIB: "shiba-inu",
  USDT: "tether",
  USDC: "usd-coin",
  BCH: "bitcoin-cash",
  XLM: "stellar",
  SUI: "sui",
  PEPE: "pepe",
  NEAR: "near",
  APT: "aptos",
  ARB: "arbitrum",
  OP: "optimism",
  ATOM: "cosmos",
  UNI: "uniswap",
  XMR: "monero",
  HBAR: "hedera-hashgraph",
  ICP: "internet-computer",
  FIL: "filecoin",
  AAVE: "aave",
  SAND: "the-sandbox",
  AXS: "axie-infinity",
};
const COIN_NAMES: Record<string, string> = {
  bitcoin: "BTC",
  ethereum: "ETH",
  ether: "ETH",
  solana: "SOL",
  ripple: "XRP",
  dogecoin: "DOGE",
  cardano: "ADA",
  litecoin: "LTC",
  polkadot: "DOT",
  tether: "USDT",
  "shiba inu": "SHIB",
  chainlink: "LINK",
  avalanche: "AVAX",
  toncoin: "TON",
  polygon: "POL",
  monero: "XMR",
  stellar: "XLM",
  axie: "AXS",
};

/** Common index names to Yahoo symbols. */
const INDEXES: Record<string, string> = {
  "S&P 500": "^GSPC",
  SPX: "^GSPC",
  "S&P": "^GSPC",
  NASDAQ: "^IXIC",
  "NASDAQ COMPOSITE": "^IXIC",
  DOW: "^DJI",
  "DOW JONES": "^DJI",
  DJIA: "^DJI",
  PSEI: "PSEI.PS",
  "PSE INDEX": "PSEI.PS",
  NIKKEI: "^N225",
  "NIKKEI 225": "^N225",
  FTSE: "^FTSE",
  "FTSE 100": "^FTSE",
  DAX: "^GDAXI",
  "HANG SENG": "^HSI",
  HSI: "^HSI",
  VIX: "^VIX",
  "RUSSELL 2000": "^RUT",
  GOLD: "GC=F",
  SILVER: "SI=F",
  OIL: "CL=F",
  "CRUDE OIL": "CL=F",
  WTI: "CL=F",
  BRENT: "BZ=F",
  "NATURAL GAS": "NG=F",
  COPPER: "HG=F",
};

export interface MarketsDeps {
  http: LiveHttp;
  cache: LiveCache;
  coingeckoKey?: string;
  finnhubKey?: string;
  /** Yahoo Finance's public endpoints may be used. */
  unofficial: boolean;
}

export function stocksAvailable(d: MarketsDeps) {
  return Boolean(d.finnhubKey) || d.unofficial;
}

/** "btc", "Bitcoin", "BTC-USD" → a crypto id; null when it isn't a known coin. */
export function coinIdOf(raw: string): { id: string; symbol: string } | null {
  const s = raw
    .trim()
    .toUpperCase()
    .replace(/[-/]?(USD|USDT|PHP|EUR)$/, "");
  if (COINS[s]) return { id: COINS[s] as string, symbol: s };
  const byName = COIN_NAMES[raw.trim().toLowerCase()];
  if (byName) return { id: COINS[byName] as string, symbol: byName };
  return null;
}

const cg = (d: MarketsDeps) =>
  d.coingeckoKey ? { headers: { "x-cg-demo-api-key": d.coingeckoKey } } : undefined;

interface CgMarket {
  id: string;
  symbol: string;
  name: string;
  image?: string;
  current_price: number;
  market_cap?: number;
  total_volume?: number;
  high_24h?: number;
  low_24h?: number;
  price_change_24h?: number;
  price_change_percentage_24h?: number;
  ath?: number;
  atl?: number;
  last_updated?: string;
  sparkline_in_7d?: { price?: number[] };
}

async function coinSearch(d: MarketsDeps, q: string) {
  const { value } = await d.cache.get(
    COINGECKO.id,
    `search|${q.toLowerCase()}`,
    7 * 86400,
    async () => {
      const r = await d.http.json<{
        coins?: Array<{ id: string; symbol: string; market_cap_rank?: number }>;
      }>(`https://api.coingecko.com/api/v3/search?query=${encodeURIComponent(q)}`, cg(d));
      const c =
        (r.coins ?? []).find((x) => x.symbol.toUpperCase() === q.toUpperCase()) ?? r.coins?.[0];
      return c && (c.market_cap_rank ?? 9999) < 1500
        ? { id: c.id, symbol: c.symbol.toUpperCase() }
        : null;
    },
  );
  return value;
}

export async function cryptoQuotes(
  d: MarketsDeps,
  coins: Array<{ id: string; symbol: string }>,
  vs = "usd",
  force = false,
): Promise<{ quotes: QuoteData[]; fetchedAt: Date; stale: boolean }> {
  const ids = [...new Set(coins.map((c) => c.id))].sort();
  const key = `markets|${vs}|${ids.join(",")}`;
  const r = await d.cache.get(
    COINGECKO.id,
    key,
    60,
    () =>
      d.http.json<CgMarket[]>(
        `https://api.coingecko.com/api/v3/coins/markets?vs_currency=${vs}&ids=${ids.join(",")}&sparkline=true&price_change_percentage=24h`,
        cg(d),
      ),
    { force, minAgeSeconds: 15 },
  );
  const quotes = r.value.map((m): QuoteData => {
    const spark = m.sparkline_in_7d?.price ?? [];
    const end = Date.parse(m.last_updated ?? "") || Date.now();
    const step = spark.length > 1 ? (7 * 86400000) / (spark.length - 1) : 0;
    // The last 24 hours of the 7-day line make the 1D chart.
    const all = spark.map((p, i): [number, number] => [end - (spark.length - 1 - i) * step, p]);
    const day = all.filter(([t]) => t >= end - 86400000);
    return {
      symbol: m.symbol.toUpperCase(),
      name: m.name,
      kind: "crypto",
      currency: vs.toUpperCase(),
      price: m.current_price,
      change: m.price_change_24h ?? 0,
      changePct: m.price_change_percentage_24h ?? 0,
      prevClose:
        m.price_change_24h !== undefined ? m.current_price - m.price_change_24h : undefined,
      dayLow: m.low_24h,
      dayHigh: m.high_24h,
      volume: m.total_volume,
      marketCap: m.market_cap,
      logoUrl: m.image?.startsWith("https://") ? m.image : undefined,
      marketState: "24h",
      asOf: m.last_updated ?? new Date().toISOString(),
      chart: day.length > 1 ? { range: "1D", points: thin(day, 96) } : undefined,
      source: COINGECKO,
    };
  });
  // Keep the order asked for.
  const order = new Map(coins.map((c, i) => [c.id, i]));
  quotes.sort(
    (a, b) =>
      (order.get(r.value.find((m) => m.symbol.toUpperCase() === a.symbol)?.id ?? "") ?? 0) -
      (order.get(r.value.find((m) => m.symbol.toUpperCase() === b.symbol)?.id ?? "") ?? 0),
  );
  return { quotes, fetchedAt: r.fetchedAt, stale: r.stale };
}

const CG_DAYS: Record<ChartRange, string> = {
  "1D": "1",
  "1W": "7",
  "1M": "30",
  "3M": "90",
  "1Y": "365",
  "5Y": "1825",
};

export async function cryptoChart(d: MarketsDeps, id: string, range: ChartRange, vs = "usd") {
  const { value } = await d.cache.get(
    COINGECKO.id,
    `chart|${id}|${vs}|${range}`,
    range === "1D" ? 120 : 3600,
    () =>
      d.http.json<{ prices?: Array<[number, number]> }>(
        `https://api.coingecko.com/api/v3/coins/${encodeURIComponent(id)}/market_chart?vs_currency=${vs}&days=${CG_DAYS[range]}`,
        cg(d),
      ),
  );
  return thin(value.prices ?? [], 120);
}

/** Every nth point, keeping the last, so a chart stays small on the wire. */
export function thin(points: Array<[number, number]>, max: number) {
  if (points.length <= max) return points.map(([t, p]) => [t, round(p)] as [number, number]);
  const step = (points.length - 1) / (max - 1);
  const out: Array<[number, number]> = [];
  for (let i = 0; i < max; i++) {
    const [t, p] = points[Math.round(i * step)] as [number, number];
    out.push([t, round(p)]);
  }
  return out;
}
const round = (p: number) =>
  Math.abs(p) >= 1 ? Math.round(p * 10000) / 10000 : Number(p.toPrecision(6));

const YF_RANGE: Record<ChartRange, [string, string]> = {
  "1D": ["1d", "5m"],
  "1W": ["5d", "30m"],
  "1M": ["1mo", "1d"],
  "3M": ["3mo", "1d"],
  "1Y": ["1y", "1d"],
  "5Y": ["5y", "1wk"],
};

interface YfMeta {
  currency?: string;
  symbol: string;
  exchangeName?: string;
  fullExchangeName?: string;
  instrumentType?: string;
  regularMarketTime?: number;
  regularMarketPrice?: number;
  fiftyTwoWeekHigh?: number;
  fiftyTwoWeekLow?: number;
  regularMarketDayHigh?: number;
  regularMarketDayLow?: number;
  regularMarketVolume?: number;
  longName?: string;
  shortName?: string;
  chartPreviousClose?: number;
  previousClose?: number;
  currentTradingPeriod?: Record<"pre" | "regular" | "post", { start: number; end: number }>;
}

const YF_HEADERS = { headers: { "user-agent": "Mozilla/5.0 (compatible; Casama/1.0)" } };

function yfKind(t?: string): QuoteData["kind"] {
  switch (t) {
    case "ETF":
      return "etf";
    case "INDEX":
      return "index";
    case "MUTUALFUND":
      return "fund";
    case "CURRENCY":
      return "currency";
    case "FUTURE":
      return "commodity";
    case "CRYPTOCURRENCY":
      return "crypto";
    default:
      return "stock";
  }
}

function marketState(meta: YfMeta, now = Date.now() / 1000): QuoteData["marketState"] {
  const p = meta.currentTradingPeriod;
  if (!p) return "closed";
  if (now >= p.regular.start && now < p.regular.end) return "open";
  if (now >= p.pre.start && now < p.pre.end) return "pre";
  if (now >= p.post.start && now < p.post.end) return "post";
  return "closed";
}

export async function yahooQuote(
  d: MarketsDeps,
  symbol: string,
  range: ChartRange = "1D",
  force = false,
) {
  const [r, i] = YF_RANGE[range];
  const res = await d.cache.get(
    YAHOO.id,
    `chart|${symbol}|${range}`,
    range === "1D" ? 60 : 3600,
    async () => {
      const body = await d.http.json<{
        chart?: {
          result?: Array<{
            meta: YfMeta;
            timestamp?: number[];
            indicators?: { quote?: Array<{ close?: Array<number | null> }> };
          }>;
          error?: { description?: string };
        };
      }>(
        `https://query1.finance.yahoo.com/v8/finance/chart/${encodeURIComponent(symbol)}?range=${r}&interval=${i}`,
        YF_HEADERS,
      );
      const res0 = body.chart?.result?.[0];
      if (!res0) throw new LiveDataError("not_found", `No market data for ${symbol}.`);
      return res0;
    },
    { force, minAgeSeconds: 15 },
  );
  const { meta, timestamp = [], indicators } = res.value;
  const closes = indicators?.quote?.[0]?.close ?? [];
  const points = timestamp
    .map((t, k): [number, number | null] => [t * 1000, closes[k] ?? null])
    .filter((p): p is [number, number] => typeof p[1] === "number");
  const price = meta.regularMarketPrice ?? points[points.length - 1]?.[1] ?? 0;
  const prev =
    range === "1D"
      ? (meta.previousClose ?? meta.chartPreviousClose)
      : (meta.chartPreviousClose ?? points[0]?.[1]);
  const change = prev ? price - prev : 0;
  const q: QuoteData = {
    symbol: meta.symbol,
    name: meta.longName ?? meta.shortName ?? meta.symbol,
    kind: yfKind(meta.instrumentType),
    exchange: meta.fullExchangeName ?? meta.exchangeName,
    currency: meta.currency ?? "USD",
    price,
    change,
    changePct: prev ? (change / prev) * 100 : 0,
    prevClose: prev,
    dayLow: meta.regularMarketDayLow,
    dayHigh: meta.regularMarketDayHigh,
    low52: meta.fiftyTwoWeekLow,
    high52: meta.fiftyTwoWeekHigh,
    volume: meta.regularMarketVolume,
    marketState: marketState(meta),
    asOf: meta.regularMarketTime
      ? new Date(meta.regularMarketTime * 1000).toISOString()
      : new Date().toISOString(),
    delayedMinutes: 15,
    chart: points.length > 1 ? { range, points: thin(points, 120) } : undefined,
    source: YAHOO,
  };
  return { quote: q, fetchedAt: res.fetchedAt, stale: res.stale };
}

export async function finnhubQuote(d: MarketsDeps, symbol: string, force = false) {
  const key = d.finnhubKey as string;
  const res = await d.cache.get(
    FINNHUB.id,
    `quote|${symbol}`,
    60,
    async () => {
      const [q, p] = await Promise.all([
        d.http.json<{
          c: number;
          d: number;
          dp: number;
          h: number;
          l: number;
          o: number;
          pc: number;
          t: number;
        }>(
          `https://finnhub.io/api/v1/quote?symbol=${encodeURIComponent(symbol)}&token=${encodeURIComponent(key)}`,
        ),
        d.http
          .json<{
            name?: string;
            logo?: string;
            currency?: string;
            exchange?: string;
            marketCapitalization?: number;
          }>(
            `https://finnhub.io/api/v1/stock/profile2?symbol=${encodeURIComponent(symbol)}&token=${encodeURIComponent(key)}`,
          )
          .catch(() => ({}) as Record<string, never>),
      ]);
      if (!q.c) throw new LiveDataError("not_found", `No quote for ${symbol}.`);
      return { q, p };
    },
    { force, minAgeSeconds: 15 },
  );
  const { q, p } = res.value;
  const quote: QuoteData = {
    symbol,
    name: p.name ?? symbol,
    kind: "stock",
    exchange: p.exchange,
    currency: p.currency ?? "USD",
    price: q.c,
    change: q.d,
    changePct: q.dp,
    prevClose: q.pc,
    open: q.o,
    dayLow: q.l,
    dayHigh: q.h,
    marketCap: p.marketCapitalization ? p.marketCapitalization * 1e6 : undefined,
    logoUrl: p.logo?.startsWith("https://") ? p.logo : undefined,
    marketState: "closed",
    asOf: new Date(q.t * 1000).toISOString(),
    delayedMinutes: 15,
    source: FINNHUB,
  };
  return { quote, fetchedAt: res.fetchedAt, stale: res.stale };
}

/** A name to a ticker ("apple" → AAPL), through Yahoo's search where allowed. */
export async function findSymbol(d: MarketsDeps, query: string): Promise<string | null> {
  const q = query.trim();
  const up = q.toUpperCase();
  if (INDEXES[up]) return INDEXES[up] as string;
  // "AAPL", "BRK.B", "^GSPC", "jfc.ps" read as tickers; a lowercase word ("apple") is a name.
  const looksLikeTicker =
    /^[\^A-Z0-9.=-]{1,12}$/.test(up) && (q === up || /[.^=]/.test(q) || q.length <= 4);
  if (looksLikeTicker) return up;
  if (!d.unofficial) return null;
  const { value } = await d.cache.get(
    YAHOO.id,
    `search|${query.toLowerCase()}`,
    7 * 86400,
    async () => {
      const r = await d.http.json<{ quotes?: Array<{ symbol: string; quoteType?: string }> }>(
        `https://query1.finance.yahoo.com/v1/finance/search?q=${encodeURIComponent(query)}&quotesCount=5&newsCount=0`,
        YF_HEADERS,
      );
      return (
        r.quotes?.find((x) =>
          ["EQUITY", "ETF", "INDEX", "MUTUALFUND", "FUTURE"].includes(x.quoteType ?? ""),
        )?.symbol ?? null
      );
    },
  );
  return value;
}

/** One quote for any symbol or name: crypto, an index, a stock or an ETF. */
export async function anyQuote(
  d: MarketsDeps,
  raw: string,
  opts: { range?: ChartRange; force?: boolean; vs?: string } = {},
) {
  const coin = coinIdOf(raw);
  if (coin) {
    const r = await cryptoQuotes(d, [coin], (opts.vs ?? "usd").toLowerCase(), opts.force);
    const q = r.quotes[0];
    if (!q) throw new LiveDataError("not_found", `No price for ${raw}.`);
    if (opts.range && opts.range !== "1D") {
      const points = await cryptoChart(
        d,
        coin.id,
        opts.range,
        (opts.vs ?? "usd").toLowerCase(),
      ).catch(() => []);
      if (points.length > 1) {
        const first = points[0]?.[1] as number;
        q.chart = { range: opts.range, points };
        q.change = q.price - first;
        q.changePct = (q.change / first) * 100;
        q.prevClose = first;
      }
    }
    return { quote: q, fetchedAt: r.fetchedAt, stale: r.stale };
  }
  if (!stocksAvailable(d))
    throw new LiveDataError(
      "no_provider",
      "Stock prices aren't set up on this server (a Finnhub key, LIVE_FINNHUB_KEY). Crypto and currency rates work.",
    );
  const symbol = await findSymbol(d, raw);
  if (!symbol) {
    // Maybe a coin by another name.
    const c = await coinSearch(d, raw).catch(() => null);
    if (c) return anyQuote(d, c.symbol, opts);
    throw new LiveDataError("not_found", `No ticker matches "${raw}". Try the symbol, like AAPL.`);
  }
  if (d.unofficial) return yahooQuote(d, symbol, opts.range ?? "1D", opts.force);
  return finnhubQuote(d, symbol, opts.force);
}

/** Today's biggest movers (Yahoo's screeners): gainers, losers or most active, US markets. */
export async function movers(d: MarketsDeps, kind: "gainers" | "losers" | "active") {
  if (!d.unofficial)
    throw new LiveDataError(
      "no_provider",
      "Market movers need a market data provider on this server.",
    );
  const id = { gainers: "day_gainers", losers: "day_losers", active: "most_actives" }[kind];
  const r = await d.cache.get(YAHOO.id, `movers|${id}`, 300, async () => {
    const body = await d.http.json<{
      finance?: {
        result?: Array<{
          quotes?: Array<{
            symbol: string;
            shortName?: string;
            longName?: string;
            regularMarketPrice?: number;
            regularMarketChange?: number;
            regularMarketChangePercent?: number;
            currency?: string;
            marketCap?: number;
          }>;
        }>;
      };
    }>(
      `https://query1.finance.yahoo.com/v1/finance/screener/predefined/saved?scrIds=${id}&count=10`,
      YF_HEADERS,
    );
    return body.finance?.result?.[0]?.quotes ?? [];
  });
  const quotes: QuoteData[] = r.value.slice(0, 10).map((q) => ({
    symbol: q.symbol,
    name: q.longName ?? q.shortName ?? q.symbol,
    kind: "stock",
    currency: q.currency ?? "USD",
    price: q.regularMarketPrice ?? 0,
    change: q.regularMarketChange ?? 0,
    changePct: q.regularMarketChangePercent ?? 0,
    marketCap: q.marketCap,
    marketState: "closed",
    asOf: new Date().toISOString(),
    delayedMinutes: 15,
    source: YAHOO,
  }));
  return { quotes, fetchedAt: r.fetchedAt, stale: r.stale };
}

export const OVERVIEW = [
  "^GSPC",
  "^IXIC",
  "^DJI",
  "^N225",
  "^FTSE",
  "PSEI.PS",
  "GC=F",
  "CL=F",
  "BTC",
  "ETH",
];

// ---------------------------------------------------------------------------------------------
// Exchange rates
// ---------------------------------------------------------------------------------------------

export interface FxData {
  base: string;
  amount: number;
  date: string;
  rates: Array<{ to: string; rate: number }>;
  trend?: { to: string; points: Array<[string, number]> };
}

const CURRENCY = /^[A-Z]{3}$/;

export async function fxRates(
  d: { http: LiveHttp; cache: LiveCache },
  from: string,
  to: string[],
  opts: { amount?: number; date?: string; trendDays?: number; force?: boolean } = {},
) {
  const base = from.toUpperCase();
  const targets = [...new Set(to.map((t) => t.toUpperCase()))].filter((t) => t !== base);
  for (const c of [base, ...targets])
    if (!CURRENCY.test(c))
      throw new LiveDataError("bad_currency", `"${c}" isn't a currency code like USD or PHP.`);
  if (!targets.length) throw new LiveDataError("bad_currency", "Name a currency to convert to.");
  const when = opts.date ?? "latest";
  const r = await d.cache.get(
    FRANKFURTER.id,
    `${when}|${base}|${targets.sort().join(",")}`,
    when === "latest" ? 3 * 3600 : 30 * 86400,
    () =>
      d.http.json<{ base: string; date: string; rates: Record<string, number> }>(
        `https://api.frankfurter.dev/v1/${when}?base=${base}&symbols=${targets.join(",")}`,
      ),
    { force: opts.force, minAgeSeconds: 600 },
  );
  const rates = targets
    .filter((t) => typeof r.value.rates[t] === "number")
    .map((t) => ({ to: t, rate: r.value.rates[t] as number }));
  if (!rates.length)
    throw new LiveDataError("not_found", `No rate for ${base} to ${targets.join(", ")}.`);
  let trend: FxData["trend"];
  const first = rates[0];
  if (opts.trendDays && first) {
    const end = new Date(Date.parse(r.value.date) || Date.now());
    const start = new Date(end.valueOf() - opts.trendDays * 86400000).toISOString().slice(0, 10);
    const t = await d.cache
      .get(FRANKFURTER.id, `series|${start}|${base}|${first.to}`, 6 * 3600, () =>
        d.http.json<{ rates: Record<string, Record<string, number>> }>(
          `https://api.frankfurter.dev/v1/${start}..?base=${base}&symbols=${first.to}`,
        ),
      )
      .catch(() => null);
    if (t)
      trend = {
        to: first.to,
        points: Object.entries(t.value.rates)
          .map(([date, v]) => [date, v[first.to] as number] as [string, number])
          .filter(([, v]) => typeof v === "number")
          .sort((a, b) => a[0].localeCompare(b[0])),
      };
  }
  const data: FxData = { base, amount: opts.amount ?? 1, date: r.value.date, rates, trend };
  return { data, fetchedAt: r.fetchedAt, stale: r.stale };
}
