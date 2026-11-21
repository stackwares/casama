/**
 * Price watches on Fares cards (docs/FLIGHT-SEARCH-PLAN.md §9, D-471). A person (or their bot,
 * through `live.fares` with `watch`) watches a card's route; the worker checks it every 6 hours with
 * free providers only (the refresh path has no meter, so paid ones are skipped) and pushes when the
 * fare reaches the target or drops 10% under the last push, at most once a day. A watch ends after
 * the departure date or 60 days.
 */
import type { Database } from "@casama/db";
import { sql } from "drizzle-orm";
import type { LiveEngine } from "./engine.ts";
import { fareMoney } from "./fares.ts";
import { loadLiveCard, refreshLiveCard } from "./refresh.ts";

/** Active watches a workspace may have. */
export const WATCHES_PER_WORKSPACE = 5;
/** Hours between checks of one watch. */
export const WATCH_EVERY_HOURS = 6;
/** Days a watch lasts at most. */
export const WATCH_MAX_DAYS = 60;
/** A drop this much under the last push (or the first price) is worth a push. */
export const WATCH_DROP = 0.1;
const DAY = 86_400_000;
const HOUR = 3_600_000;

export class WatchError extends Error {
  readonly code: string;
  constructor(code: string, message: string) {
    super(message);
    this.code = code;
  }
}

export type FareWatchRow = {
  id: string;
  org_id: string;
  user_id: string;
  bot_id: string | null;
  live_card_id: string;
  route: string;
  below: number | null;
  currency: string;
  first_price: number | null;
  last_price: number | null;
  last_checked_at: string | null;
  pushed_price: number | null;
  pushed_at: string | null;
  next_check_at: string;
  ends_at: string;
  created_at: string;
};

/** The pieces of a Fares card a watch reads. */
type FaresData = {
  component?: string;
  from?: { label?: string };
  to?: { label?: string };
  depart?: string;
  return?: string;
  nights?: number;
  currency?: string;
  cheapest?: number;
  options?: unknown[];
};

const shortDay = (d: string) => {
  const t = new Date(`${d.length === 7 ? `${d}-01` : d}T00:00:00Z`);
  if (Number.isNaN(t.valueOf())) return d;
  const month = t.toLocaleString("en", { month: "short", timeZone: "UTC" });
  return d.length === 7 ? month : `${month} ${t.getUTCDate()}`;
};

/** "Manila → Tokyo · Mar 12–19". */
export function watchRoute(card: FaresData) {
  const from = card.from?.label ?? "?";
  const to = card.to?.label ?? "?";
  const dates = card.depart
    ? card.return
      ? `${shortDay(card.depart)}–${shortDay(card.return)}`
      : shortDay(card.depart)
    : "";
  return `${from} → ${to}${dates ? ` · ${dates}` : ""}`.slice(0, 160);
}

/** The card's cheapest fare, or null when it has none. */
export function cheapestFare(card: FaresData): number | null {
  if (!card.options?.length) return null;
  const n = Number(card.cheapest);
  return Number.isFinite(n) && n > 0 ? n : null;
}

/** When a watch ends: the end of the departure day (or month), at most 60 days from now. */
export function watchEnds(depart: string | undefined, now = new Date()): Date {
  const cap = new Date(now.valueOf() + WATCH_MAX_DAYS * DAY);
  if (!depart) return cap;
  const m = /^(\d{4})-(\d{2})(?:-(\d{2}))?$/.exec(depart);
  if (!m) return cap;
  const end = m[3]
    ? new Date(Date.UTC(+m[1]!, +m[2]! - 1, +m[3]!, 23, 59, 59))
    : new Date(Date.UTC(+m[1]!, +m[2]!, 0, 23, 59, 59));
  return end < cap ? end : cap;
}

/** The next check: 6 hours on, give or take 30 minutes, so watches started together spread out. */
export function nextCheck(now = new Date(), rand = Math.random) {
  return new Date(now.valueOf() + WATCH_EVERY_HOURS * HOUR + Math.round((rand() - 0.5) * HOUR));
}

/**
 * Whether a new price is worth a push: at or under the target (and lower than what was last
 * pushed), or 10% under the last push (or the first price) when there is no target. At most one
 * push a day.
 */
export function shouldPush(
  w: Pick<FareWatchRow, "below" | "first_price" | "pushed_price" | "pushed_at">,
  price: number,
  now = new Date(),
): boolean {
  if (w.pushed_at && now.valueOf() - new Date(w.pushed_at).valueOf() < DAY) return false;
  const pushed = w.pushed_price === null ? null : Number(w.pushed_price);
  if (w.below !== null && price <= Number(w.below)) return pushed === null || price < pushed;
  const base = pushed ?? (w.first_price === null ? null : Number(w.first_price));
  return base !== null && price <= base * (1 - WATCH_DROP);
}

/** The push's words. */
export function watchPushText(
  w: Pick<FareWatchRow, "route" | "currency">,
  price: number,
  was: number | null,
) {
  const now = fareMoney(price, w.currency);
  return {
    title: `Fare drop: ${w.route.split(" · ")[0]}`,
    body: `${w.route} is now ${now}${was && was > price ? ` (was ${fareMoney(was, w.currency)})` : ""}. Open the card to book.`,
  };
}

const cols = sql`id, org_id, user_id, bot_id, live_card_id, route, below::float8 as below, currency,
  first_price::float8 as first_price, last_price::float8 as last_price, last_checked_at,
  pushed_price::float8 as pushed_price, pushed_at, next_check_at, ends_at, created_at`;

/** Starts (or updates the target of) a person's watch on a Fares card. */
export async function startFareWatch(
  db: Database,
  input: { cardId: string; userId: string; botId?: string | null; below?: number | null },
  now = new Date(),
): Promise<FareWatchRow> {
  const row = await loadLiveCard(db, input.cardId);
  if (row?.card !== "Fares")
    throw new WatchError("not_watchable", "Only a Fares card's price can be watched.");
  const data = row.data as FaresData;
  const ends = watchEnds(data.depart, now);
  if (ends <= now) throw new WatchError("not_watchable", "This trip's departure date has passed.");
  const below = input.below && input.below > 0 ? Math.round(input.below * 100) / 100 : null;
  const [mine] = await db.execute<{ id: string }>(sql`
    select id from public.fare_watches
    where live_card_id = ${row.id}::uuid and user_id = ${input.userId}::uuid and stopped_at is null`);
  if (mine) {
    const [w] = await db.execute<FareWatchRow>(sql`
      update public.fare_watches set below = ${below} where id = ${mine.id}::uuid returning ${cols}`);
    return w!;
  }
  const [n] = await db.execute<{ n: number }>(sql`
    select count(*)::int as n from public.fare_watches where org_id = ${row.org_id}::uuid and stopped_at is null`);
  if ((n?.n ?? 0) >= WATCHES_PER_WORKSPACE)
    throw new WatchError(
      "too_many_watches",
      `This workspace already watches ${WATCHES_PER_WORKSPACE} fares; stop one first (Settings → Cards).`,
    );
  const price = cheapestFare(data);
  const [b] = await db.execute<{ bot_id: string | null }>(
    sql`select bot_id from public.live_cards where id = ${row.id}::uuid`,
  );
  const [w] = await db.execute<FareWatchRow>(sql`
    insert into public.fare_watches
      (org_id, user_id, bot_id, live_card_id, route, below, currency, first_price, last_price,
       last_checked_at, next_check_at, ends_at)
    values (${row.org_id}::uuid, ${input.userId}::uuid, ${input.botId ?? b?.bot_id ?? null}::uuid,
            ${row.id}::uuid, ${watchRoute(data)}, ${below}, ${(data.currency ?? "USD").slice(0, 3)},
            ${price}, ${price}, ${price === null ? null : now.toISOString()}::timestamptz,
            ${nextCheck(now).toISOString()}::timestamptz, ${ends.toISOString()}::timestamptz)
    returning ${cols}`);
  return w!;
}

/** Stops a person's watch on a card. Answers whether one was running. */
export async function stopFareWatch(db: Database, cardId: string, userId: string) {
  const rows = await db.execute(sql`
    update public.fare_watches set stopped_at = now(), stopped_why = 'person'
    where live_card_id = ${cardId}::uuid and user_id = ${userId}::uuid and stopped_at is null
    returning id`);
  return rows.length > 0;
}

/** A person's active watches, newest first. */
export async function listFareWatches(db: Database, userId: string): Promise<FareWatchRow[]> {
  return db.execute<FareWatchRow>(sql`
    select ${cols} from public.fare_watches
    where user_id = ${userId}::uuid and stopped_at is null and ends_at > now()
    order by created_at desc limit 50`);
}

export type WatchNotify = (
  userId: string,
  orgId: string,
  message: { title: string; body: string; link?: string; bot_id?: string },
) => Promise<unknown>;

/**
 * The worker's job (every few minutes): watches past their time end; due ones are checked once
 * through the card's own refresh (free providers, shared cache) and push when the price is worth
 * it. Answers how many were checked and pushed.
 */
export async function sweepFareWatches(
  db: Database,
  engine: LiveEngine,
  notify: WatchNotify | undefined,
  now = new Date(),
  limit = 25,
): Promise<{ checked: number; pushed: number; ended: number }> {
  const ended = await db.execute(sql`
    update public.fare_watches set stopped_at = ${now.toISOString()}::timestamptz, stopped_why = 'ended'
    where stopped_at is null and ends_at <= ${now.toISOString()}::timestamptz returning id`);
  const due = await db.execute<FareWatchRow>(sql`
    select ${cols} from public.fare_watches
    where stopped_at is null and next_check_at <= ${now.toISOString()}::timestamptz
    order by next_check_at limit ${limit}`);
  let checked = 0;
  let pushed = 0;
  for (const w of due) {
    const row = await loadLiveCard(db, w.live_card_id);
    if (!row) {
      await db.execute(sql`
        update public.fare_watches set stopped_at = now(), stopped_why = 'card_gone' where id = ${w.id}::uuid`);
      continue;
    }
    // Claimed before the call, so a slow provider or a crash doesn't check it again at once.
    await db.execute(sql`
      update public.fare_watches set next_check_at = ${nextCheck(now).toISOString()}::timestamptz
      where id = ${w.id}::uuid`);
    let price: number | null = null;
    try {
      const r = await refreshLiveCard(db, engine, row, {});
      if (!r.error) price = cheapestFare(r.card as FaresData);
    } catch {
      // The card's daily limit or a bad call: try at the next check.
    }
    checked++;
    if (price === null) continue;
    await db.execute(sql`
      update public.fare_watches set last_price = ${price}, last_checked_at = ${now.toISOString()}::timestamptz,
        first_price = coalesce(first_price, ${price})
      where id = ${w.id}::uuid`);
    if (!notify || !shouldPush(w, price, now)) continue;
    const was = w.pushed_price ?? w.first_price;
    try {
      await notify(w.user_id, w.org_id, {
        ...watchPushText(w, price, was),
        ...(w.bot_id ? { link: `/bots/${w.bot_id}/chat`, bot_id: w.bot_id } : {}),
      });
      await db.execute(sql`
        update public.fare_watches set pushed_price = ${price}, pushed_at = ${now.toISOString()}::timestamptz
        where id = ${w.id}::uuid`);
      pushed++;
    } catch {
      // The push failed: the next check tries again.
    }
  }
  return { checked, pushed, ended: ended.length };
}
