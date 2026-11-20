/**
 * Pinned cards (RICH-CARDS-PLAN §4.5, Stage A): a live card on the person's widgets is a D-455
 * canvas the server keeps fresh by itself, with no model run. Weather is written as an hourly
 * schedule (up to 14 entries), so it changes every hour while being written every few hours,
 * inside the canvas write limits; prices and rates are written when they change enough.
 */
import type { Database } from "@casama/db";
import {
  type CanvasContent,
  type CanvasEntryBody,
  checkEntry,
  DEFAULT_LOOK,
  type EntryInput,
} from "@casama/domain";
import { sql } from "drizzle-orm";
import { getCanvas, saveCanvas, widgetsAllowed } from "../canvas.ts";
import { CONDITION_WORDS, type Units } from "./cards.ts";
import type { LiveEngine } from "./engine.ts";
import { type LiveCardRow, loadLiveCard, refreshLiveCard } from "./refresh.ts";

export const PINNABLE = [
  "Weather",
  "Forecast",
  "Quote",
  "Watchlist",
  "Currency",
  "AirQuality",
  "Score",
  "Flight",
  "Parcel",
  "SunMoon",
];

/** How often the worker writes a pinned card again, in minutes. */
export const PIN_EVERY: Record<string, number> = {
  Weather: 180,
  Forecast: 180,
  Quote: 30,
  Watchlist: 30,
  Currency: 360,
  AirQuality: 120,
  Score: 15,
  Flight: 15,
  Parcel: 120,
  SunMoon: 720,
};

const temp = (c: number, u?: Partial<Units> | null) =>
  Math.round(u?.temp === "F" ? (c * 9) / 5 + 32 : c);

/** Background colours by condition and time of day, like the app's sky. */
export function skyLook(code: string, isDay: boolean): CanvasContent["look"] {
  const night = { from: "#1B2440", to: "#0A0F1F" };
  const sky: Record<string, { from: string; to: string }> = {
    clear: { from: "#4FA8F8", to: "#1C64D1" },
    mostly_clear: { from: "#5AAEF5", to: "#2A6FCF" },
    partly_cloudy: { from: "#7DA9D6", to: "#3E6A9E" },
    cloudy: { from: "#8C99A8", to: "#56626F" },
    fog: { from: "#A7AFB8", to: "#6F7781" },
  };
  const wet = { from: "#5D6E82", to: "#2C3A4B" };
  const storm = { from: "#4A4A66", to: "#1F1F33" };
  const snow = { from: "#B8CCE0", to: "#7D93AD" };
  const pick = !isDay
    ? night
    : (sky[code] ??
      (code.includes("snow") || code === "sleet"
        ? snow
        : code === "thunder" || code === "hail"
          ? storm
          : wet));
  return { ...DEFAULT_LOOK, background: { kind: "gradient", ...pick }, align: "start", icon: null };
}

const money = (v: number, cur: string) => {
  try {
    return new Intl.NumberFormat("en-US", {
      style: "currency",
      currency: cur,
      maximumFractionDigits: Math.abs(v) < 1 ? 4 : 2,
      notation: Math.abs(v) >= 1e6 ? "compact" : "standard",
    }).format(v);
  } catch {
    return `${v.toFixed(2)} ${cur}`;
  }
};
const signed = (v: number) => `${v >= 0 ? "▲" : "▼"} ${Math.abs(v).toFixed(2)}%`;

/** The canvas for a card: its entries (one, or a schedule) and look. Null when it can't be pinned. */
export function canvasFor(
  card: Record<string, unknown>,
  units?: Partial<Units> | null,
): CanvasContent | null {
  const c = card;
  const entries: Array<EntryInput & { at: string | null }> = [];
  let look: CanvasContent["look"] = { ...DEFAULT_LOOK };
  switch (c.component) {
    case "Weather":
    case "Forecast": {
      const place = String((c.place as { name?: string })?.name ?? "");
      const deg = units?.temp === "F" ? "°F" : "°C";
      const hours = (
        (c.hours as Array<{ t: string; temp: number; code: string; isDay: boolean }>) ?? []
      ).slice(0, 14);
      const day = c.day as { high?: number; low?: number } | undefined;
      if (c.component === "Weather" && hours.length) {
        hours.forEach((h, i) => {
          entries.push({
            at: i === 0 ? null : h.t,
            template: "number",
            title: place,
            value: temp(h.temp, units),
            unit: deg,
            footer: `${cap(CONDITION_WORDS[h.code] ?? "")}${day?.high !== undefined ? ` · H ${temp(day.high, units)}° L ${temp(day.low ?? 0, units)}°` : ""}`,
            short: `${place} ${temp(h.temp, units)}${deg} ${CONDITION_WORDS[h.code] ?? ""}`,
            tiny: `${temp(h.temp, units)}° ${CONDITION_WORDS[h.code] ?? ""}`,
          });
        });
        look = skyLook(hours[0]?.code ?? "cloudy", hours[0]?.isDay ?? true);
      } else {
        const days = (
          (c.days as Array<{ date: string; high: number; low: number; code: string }>) ?? []
        ).slice(0, 5);
        entries.push({
          at: null,
          template: "list",
          title: place,
          items: days.map(
            (d) =>
              `${weekday(d.date)} ${temp(d.low, units)}–${temp(d.high, units)}° ${CONDITION_WORDS[d.code] ?? ""}`,
          ),
          short: `${place}: ${days.map((d) => `${weekday(d.date)} ${temp(d.high, units)}°`).join(" ")}`,
        });
        look = skyLook(days[0]?.code ?? "cloudy", true);
      }
      break;
    }
    case "Quote": {
      const pct = Number(c.changePct ?? 0);
      entries.push({
        at: null,
        template: "number",
        title: String(c.symbol),
        value: Number(Number(c.price).toPrecision(8)),
        unit: String(c.currency ?? ""),
        footer: `${signed(pct)}${c.delayedMinutes ? " · delayed" : ""}`,
        short: `${c.symbol} ${money(Number(c.price), String(c.currency ?? "USD"))} ${signed(pct)}`,
        tiny: `${c.symbol} ${money(Number(c.price), String(c.currency ?? "USD"))}`,
      });
      look = { ...DEFAULT_LOOK, accent: pct >= 0 ? "#1F9D55" : "#D64545" };
      break;
    }
    case "Watchlist": {
      const quotes =
        (c.quotes as Array<{
          symbol: string;
          price: number;
          currency: string;
          changePct: number;
        }>) ?? [];
      entries.push({
        at: null,
        template: "list",
        title: String(c.title ?? "Watchlist"),
        items: quotes
          .slice(0, 5)
          .map((q) => `${q.symbol} ${money(q.price, q.currency)} ${signed(q.changePct)}`),
        short: quotes
          .slice(0, 3)
          .map((q) => `${q.symbol} ${signed(q.changePct)}`)
          .join(" · "),
      });
      break;
    }
    case "Currency": {
      const rates = (c.rates as Array<{ to: string; rate: number }>) ?? [];
      const r = rates[0];
      if (!r) return null;
      entries.push({
        at: null,
        template: "number",
        title: `1 ${c.base} in ${r.to}`,
        value: Number(r.rate.toPrecision(6)),
        unit: r.to,
        footer: `Rate of ${c.date}`,
        short: `1 ${c.base} = ${r.rate.toFixed(4)} ${r.to}`,
        tiny: `${c.base}/${r.to} ${r.rate.toFixed(2)}`,
      });
      break;
    }
    case "AirQuality": {
      const place = String((c.place as { name?: string })?.name ?? "");
      entries.push({
        at: null,
        template: "number",
        title: `Air · ${place}`,
        value: Number(c.aqi),
        of: 300,
        unit: "AQI",
        short: `${place} air: AQI ${c.aqi}`,
        tiny: `AQI ${c.aqi}`,
      });
      break;
    }
    case "SunMoon": {
      const sun = c.sun as { sunrise?: string; sunset?: string };
      const place = String((c.place as { name?: string })?.name ?? "");
      entries.push({
        at: null,
        template: "text",
        title: place,
        text: `Sunrise ${sun.sunrise?.slice(11, 16) ?? "—"} · Sunset ${sun.sunset?.slice(11, 16) ?? "—"}`,
        short: `${place} ☀ ${sun.sunrise?.slice(11, 16) ?? "—"}–${sun.sunset?.slice(11, 16) ?? "—"}`,
      });
      break;
    }
    case "Score": {
      const g = ((c.games as Array<{
        teams: Array<{ abbr?: string; name: string; score?: string }>;
        detail: string;
        state: string;
      }>) ?? [])[0];
      if (!g) return null;
      const line = g.teams
        .map((t) => `${t.abbr ?? t.name}${g.state !== "pre" ? ` ${t.score ?? ""}` : ""}`)
        .join(" – ");
      entries.push({
        at: null,
        template: "text",
        title: String(c.league ?? ""),
        text: line,
        footer: g.detail,
        short: `${line} (${g.detail})`,
      });
      break;
    }
    case "Flight": {
      const from = c.from as {
        code?: string;
        gate?: string;
        estimated?: string;
        scheduled?: string;
      };
      const to = c.to as { code?: string };
      entries.push({
        at: null,
        template: "text",
        title: `${c.flight} ${from.code ?? ""}→${to.code ?? ""}`,
        text: `${cap(String(c.status))}${from.gate ? ` · Gate ${from.gate}` : ""}`,
        footer: (from.estimated ?? from.scheduled ?? "").slice(11, 16),
        short: `${c.flight} ${c.status}${from.gate ? ` gate ${from.gate}` : ""}`,
      });
      break;
    }
    case "Parcel": {
      const ev = ((c.events as Array<{ text: string }>) ?? [])[0];
      entries.push({
        at: null,
        template: "text",
        title: `Parcel ${String(c.tracking).slice(-6)}`,
        text: cap(String(c.status).replaceAll("_", " ")),
        footer: ev?.text?.slice(0, 40),
        short: `Parcel: ${String(c.status).replaceAll("_", " ")}`,
      });
      break;
    }
    default:
      return null;
  }
  if (!entries.length) return null;
  const checked: Array<CanvasEntryBody & { at: string | null }> = entries.map((e, i) => ({
    ...checkEntry(e, { where: `entry ${i + 1}` }).entry,
    at: e.at,
  }));
  return { look, entries: checked };
}

const cap = (s: string) => s.charAt(0).toUpperCase() + s.slice(1);
const weekday = (date: string) =>
  new Date(`${date}T12:00:00Z`).toLocaleDateString("en-US", { weekday: "short", timeZone: "UTC" });

/** A canvas name for a card: "Weather · Manila", "BTC", at most 40 characters. */
export function pinName(card: Record<string, unknown>) {
  const place = (card.place as { name?: string } | undefined)?.name;
  const base =
    card.component === "Quote"
      ? `Price · ${card.symbol}`
      : card.component === "Currency"
        ? `Rate · ${card.base}`
        : `${card.component}${place ? ` · ${place}` : card.title ? ` · ${card.title}` : ""}`;
  return base.slice(0, 40);
}

export class PinError extends Error {
  readonly code: string;
  constructor(code: string, message: string) {
    super(message);
    this.code = code;
  }
}

/** Pins a card for [userId]: refreshes it, writes the canvas, and marks the card pinned. */
export async function pinLiveCard(
  db: Database,
  engine: LiveEngine,
  row: LiveCardRow & { bot_id?: string | null },
  userId: string,
  units?: Partial<Units> | null,
) {
  if (!PINNABLE.includes(row.card))
    throw new PinError("not_pinnable", "This card can't go on a widget.");
  const [b] = await db.execute<{ bot_id: string | null }>(
    sql`select bot_id from public.live_cards where id = ${row.id}::uuid`,
  );
  const botId = b?.bot_id;
  if (!botId) throw new PinError("not_pinnable", "This card has no bot to keep it on a widget.");
  const fresh = await refreshLiveCard(db, engine, row, {});
  const content = canvasFor(fresh.card, units);
  if (!content)
    throw new PinError("not_pinnable", "This card has nothing to show on a widget right now.");
  const allowed = await widgetsAllowed(db, userId, botId);
  const canvas = await saveCanvas(db, {
    orgId: row.org_id,
    userId,
    botId,
    runId: null,
    name: pinName(fresh.card),
    content,
    allowed,
    private: row.card === "Parcel" || row.card === "Flight",
    until: null,
  });
  await db.execute(sql`
    update public.live_cards set pinned_canvas_id = ${canvas.id}::uuid, pinned_units = ${JSON.stringify(units ?? null)}::jsonb
    where id = ${row.id}::uuid`);
  return canvas;
}

export async function unpinLiveCard(db: Database, id: string, userId: string) {
  const [r] = await db.execute<{ pinned_canvas_id: string | null }>(sql`
    select pinned_canvas_id from public.live_cards where id = ${id}::uuid`);
  await db.execute(
    sql`update public.live_cards set pinned_canvas_id = null where id = ${id}::uuid`,
  );
  if (r?.pinned_canvas_id)
    await db.execute(
      sql`delete from public.widget_canvases where id = ${r.pinned_canvas_id}::uuid and user_id = ${userId}::uuid`,
    );
}

/**
 * The worker's job (every few minutes): pinned cards past their rhythm are fetched and written
 * again. Returns the people whose widgets changed, for refresh pushes.
 */
export async function refreshPins(
  db: Database,
  engine: LiveEngine,
  now = new Date(),
): Promise<string[]> {
  const rows = await db.execute<{
    id: string;
    card: string;
    updated: Date | string;
    user_id: string;
  }>(sql`
    select l.id, l.card, c.set_at as updated, c.user_id
    from public.live_cards l join public.widget_canvases c on c.id = l.pinned_canvas_id
    where c.status <> 'paused'
    order by c.set_at limit 200`);
  const changed = new Set<string>();
  for (const r of rows) {
    const every = (PIN_EVERY[r.card] ?? 60) * 60_000;
    if (now.valueOf() - new Date(r.updated).valueOf() < every) continue;
    const row = await loadLiveCard(db, r.id);
    if (!row) continue;
    const [u] = await db.execute<{ pinned_units: Partial<Units> | null }>(
      sql`select pinned_units from public.live_cards where id = ${r.id}::uuid`,
    );
    try {
      const canvas = await pinLiveCard(db, engine, row, r.user_id, u?.pinned_units);
      if (canvas.status === "shown") changed.add(r.user_id);
    } catch {
      // A limit or a provider failure: the widget keeps what it had; try again next round.
    }
  }
  return [...changed];
}

export { getCanvas };
