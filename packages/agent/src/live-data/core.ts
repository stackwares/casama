/**
 * Live data (docs/RICH-CARDS-PLAN.md §4.1): providers called from the server through the egress
 * guard, a shared cache for public data (Postgres plus a small in-process LRU, one upstream call per
 * key at a time), and daily volume counts. No person or workspace ever goes into a cache key.
 */
import type { Database } from "@casama/db";
import { sql } from "drizzle-orm";

export const LIVE_USER_AGENT = "Casama/1.0 (+https://casama.ai; hello@casama.ai)";

/** A provider as a card's footer names it. */
export interface LiveSource {
  id: string;
  name: string;
  url?: string;
  license?: string;
}

export class LiveDataError extends Error {
  readonly code: string;
  constructor(code: string, message: string) {
    super(message);
    this.code = code;
  }
}

export interface LiveHttp {
  json<T = unknown>(
    url: string,
    init?: { headers?: Record<string, string>; signal?: AbortSignal; timeoutMs?: number },
  ): Promise<T>;
  text(
    url: string,
    init?: { headers?: Record<string, string>; signal?: AbortSignal },
  ): Promise<string>;
  post<T = unknown>(url: string, body: unknown, headers?: Record<string, string>): Promise<T>;
  /** The guarded fetch underneath, for a client that needs one (Kiwi.com's MCP server). */
  raw?: typeof fetch;
}

/** Fetches JSON and text from fixed provider hosts, with our User-Agent and a 6-second limit. */
export function liveHttp(fetchImpl: typeof fetch, timeoutMs = 6000): LiveHttp {
  const go = async (
    url: string,
    init?: {
      headers?: Record<string, string>;
      signal?: AbortSignal;
      method?: string;
      body?: string;
      timeoutMs?: number;
    },
  ) => {
    const ctrl = new AbortController();
    const timer = setTimeout(() => ctrl.abort(new Error("timeout")), init?.timeoutMs ?? timeoutMs);
    const signal = init?.signal ? AbortSignal.any([ctrl.signal, init.signal]) : ctrl.signal;
    try {
      const res = await fetchImpl(url, {
        method: init?.method ?? "GET",
        body: init?.body,
        headers: { "user-agent": LIVE_USER_AGENT, accept: "application/json", ...init?.headers },
        signal,
      });
      if (res.status === 404)
        throw new LiveDataError("not_found", `Nothing found (${new URL(url).host}).`);
      if (res.status === 429)
        throw new LiveDataError(
          "rate_limited",
          `${new URL(url).host} is busy; try again in a minute.`,
        );
      if (!res.ok)
        throw new LiveDataError("upstream", `${new URL(url).host} answered ${res.status}.`);
      return res;
    } catch (err) {
      if (err instanceof LiveDataError) throw err;
      throw new LiveDataError(
        "upstream",
        `${new URL(url).host} didn't answer (${err instanceof Error ? err.message : String(err)}).`,
      );
    } finally {
      clearTimeout(timer);
    }
  };
  return {
    raw: fetchImpl,
    async json<T>(
      url: string,
      init?: { headers?: Record<string, string>; signal?: AbortSignal; timeoutMs?: number },
    ) {
      const res = await go(url, init);
      return (await res.json()) as T;
    },
    async text(url: string, init?: { headers?: Record<string, string>; signal?: AbortSignal }) {
      const res = await go(url, init);
      return res.text();
    },
    async post<T>(url: string, body: unknown, headers?: Record<string, string>) {
      const res = await go(url, {
        method: "POST",
        body: JSON.stringify(body),
        headers: { "content-type": "application/json", ...headers },
      });
      return (await res.json()) as T;
    },
  };
}

interface Entry {
  payload: unknown;
  fetchedAt: number;
  expiresAt: number;
}

/** What a cached call returns: the value, when it was fetched, and whether it's past its time. */
export interface Cached<T> {
  value: T;
  fetchedAt: Date;
  stale: boolean;
  cached: boolean;
}

export interface LiveCache {
  get<T>(
    provider: string,
    key: string,
    ttlSeconds: number,
    load: () => Promise<T>,
    opts?: { force?: boolean; minAgeSeconds?: number },
  ): Promise<Cached<T>>;
}

/**
 * The shared cache. A fresh row answers without a call; a miss calls once per key across this
 * process (concurrent misses wait for the same call); a failed call serves a row up to six times
 * its time to live, marked stale. `force` (a person's ↻) calls again unless the row is younger than
 * `minAgeSeconds`.
 */
export function liveCache(
  db: Database | null,
  opts: { maxEntries?: number; now?: () => number } = {},
): LiveCache {
  const mem = new Map<string, Entry>();
  const flying = new Map<string, Promise<unknown>>();
  const max = opts.maxEntries ?? 2000;
  const now = opts.now ?? Date.now;
  const remember = (k: string, e: Entry) => {
    mem.delete(k);
    mem.set(k, e);
    if (mem.size > max) mem.delete(mem.keys().next().value as string);
  };
  const count = (provider: string, field: "calls" | "cache_hits" | "errors") =>
    db
      ?.execute(sql`insert into public.live_data_daily (day, provider, ${sql.raw(field)})
        values (current_date, ${provider}, 1)
        on conflict (day, provider) do update set ${sql.raw(field)} = public.live_data_daily.${sql.raw(field)} + 1`)
      .catch(() => {});
  const readDb = async (provider: string, key: string): Promise<Entry | null> => {
    if (!db) return null;
    const [r] = await db
      .execute<{ payload: unknown; fetched_at: Date | string; expires_at: Date | string }>(sql`
        select payload, fetched_at, expires_at from public.live_data_cache
        where provider = ${provider} and key = ${key}`)
      .catch(() => [] as never[]);
    if (!r) return null;
    return {
      payload: r.payload,
      fetchedAt: new Date(r.fetched_at).getTime(),
      expiresAt: new Date(r.expires_at).getTime(),
    };
  };
  const writeDb = async (provider: string, key: string, e: Entry) => {
    if (!db) return;
    await db
      .execute(sql`insert into public.live_data_cache (provider, key, payload, fetched_at, expires_at)
        values (${provider}, ${key}, ${JSON.stringify(e.payload)}::jsonb, ${new Date(e.fetchedAt).toISOString()}::timestamptz, ${new Date(e.expiresAt).toISOString()}::timestamptz)
        on conflict (provider, key) do update set payload = excluded.payload, fetched_at = excluded.fetched_at, expires_at = excluded.expires_at`)
      .catch(() => {});
  };
  return {
    async get<T>(
      provider: string,
      key: string,
      ttlSeconds: number,
      load: () => Promise<T>,
      o: { force?: boolean; minAgeSeconds?: number } = {},
    ): Promise<Cached<T>> {
      const k = `${provider}\u0000${key}`;
      const t = now();
      let e = mem.get(k) ?? null;
      if (!e) {
        e = await readDb(provider, key);
        if (e) remember(k, e);
      }
      const young = e && t - e.fetchedAt < (o.minAgeSeconds ?? 0) * 1000;
      if (e && t < e.expiresAt && (!o.force || young)) {
        void count(provider, "cache_hits");
        return {
          value: e.payload as T,
          fetchedAt: new Date(e.fetchedAt),
          stale: false,
          cached: true,
        };
      }
      let p = flying.get(k) as Promise<T> | undefined;
      if (!p) {
        p = load();
        flying.set(k, p);
        p.finally(() => flying.delete(k)).catch(() => {});
      }
      try {
        const value = await p;
        const fresh: Entry = {
          payload: value,
          fetchedAt: now(),
          expiresAt: now() + ttlSeconds * 1000,
        };
        remember(k, fresh);
        void count(provider, "calls");
        void writeDb(provider, key, fresh);
        return { value, fetchedAt: new Date(fresh.fetchedAt), stale: false, cached: false };
      } catch (err) {
        void count(provider, "errors");
        const old = e && t - e.fetchedAt < ttlSeconds * 6000 ? e : null;
        if (old)
          return {
            value: old.payload as T,
            fetchedAt: new Date(old.fetchedAt),
            stale: true,
            cached: true,
          };
        throw err;
      }
    },
  };
}

/** Deletes cache rows a day past their time (the hourly worker job). */
export async function pruneLiveCache(db: Database) {
  await db.execute(
    sql`delete from public.live_data_cache where expires_at < now() - interval '1 day'`,
  );
  await db.execute(sql`delete from public.live_data_daily where day < current_date - 120`);
}

/** Rounds a coordinate for a cache key or a provider call: 0.1° ≈ 11 km, 0.01° ≈ 1 km. */
export const roundTo = (v: number, step: number) => Math.round(v / step) * step;
export const coord = (v: number, digits = 2) => Number(v.toFixed(digits));
