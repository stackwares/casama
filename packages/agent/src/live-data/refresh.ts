/**
 * Refreshing a shown card without the model (RICH-CARDS-PLAN §4.4): the stored call runs again
 * through the shared cache. The client sends only the card's id and, for another view, a value
 * from the card's own list; arguments never come from the client.
 */
import type { Database } from "@casama/db";
import { sql } from "drizzle-orm";
import { type Built, CONDITION_WORDS } from "./cards.ts";
import { LiveDataError } from "./core.ts";
import type { LiveEngine, LiveTool } from "./engine.ts";
import { CHART_RANGES } from "./markets.ts";
import { livePerson, withRef } from "./tools.ts";

/** Refreshes a person may ask for per card per day. */
export const REFRESHES_PER_DAY = 600;

export type LiveCardRow = {
  id: string;
  org_id: string;
  user_id: string | null;
  card: string;
  tool: LiveTool;
  args: Record<string, unknown>;
  data: Record<string, unknown>;
  fetched_at: Date | string;
  refreshes_day: number;
  refresh_day: string | Date;
  pinned_canvas_id: string | null;
};

/** The view a client may ask for, by tool, from a fixed list. */
export function viewArgs(tool: LiveTool, view: string | undefined): Record<string, unknown> | null {
  if (!view) return {};
  if (tool === "weather" && ["now", "today", "tomorrow", "week"].includes(view))
    return { when: view };
  if (tool === "quote" && (CHART_RANGES as string[]).includes(view)) return { range: view };
  if (tool === "sports" && ["scores", "standings"].includes(view)) return { view };
  if (tool === "markets" && ["overview", "gainers", "losers", "active"].includes(view))
    return { view };
  return null;
}

export async function loadLiveCard(db: Database, id: string) {
  const [row] = await db.execute<LiveCardRow>(sql`
    select id, org_id, user_id, card, tool, args, data, fetched_at, refreshes_day, refresh_day, pinned_canvas_id
    from public.live_cards where id = ${id}::uuid`);
  return row ?? null;
}

/**
 * Runs a card's call again. `view` changes what it shows (another day, chart range); `save` keeps
 * the result as the card's latest data. Errors become a stale card with the old data, so the app
 * shows "Couldn't update" instead of losing the card.
 */
export async function refreshLiveCard(
  db: Database,
  engine: LiveEngine,
  row: LiveCardRow,
  opts: { view?: string; force?: boolean; save?: boolean } = {},
): Promise<{ card: Record<string, unknown>; error?: string; built?: Built }> {
  const over = viewArgs(row.tool, opts.view);
  if (over === null) throw new LiveDataError("bad_view", "That card has no such view.");
  const today = new Date().toISOString().slice(0, 10);
  const day =
    typeof row.refresh_day === "string"
      ? row.refresh_day.slice(0, 10)
      : row.refresh_day.toISOString().slice(0, 10);
  const used = day === today ? row.refreshes_day : 0;
  if (used >= REFRESHES_PER_DAY)
    throw new LiveDataError(
      "rate_limited",
      "This card has been refreshed a lot today; try tomorrow.",
    );
  await db.execute(sql`
    update public.live_cards set refreshes_day = ${used + 1}, refresh_day = current_date where id = ${row.id}::uuid`);
  const person = await livePerson(db, row.user_id);
  try {
    const r = await engine.run(row.tool, { ...row.args, ...over }, person, { force: opts.force });
    const card = withRef(r.built.card, row.id);
    if (opts.save !== false && !opts.view)
      await db.execute(sql`
        update public.live_cards set data = ${JSON.stringify(card)}::jsonb, fetched_at = now() where id = ${row.id}::uuid`);
    return { card, built: r.built };
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    const live = (row.data.live ?? {}) as Record<string, unknown>;
    return { card: { ...row.data, live: { ...live, ref: row.id, stale: true } }, error: message };
  }
}

/** A canvas's text for a pinned card: a big number or a short line, from the card. */
export function pinText(built: Built) {
  const c = built.card as Record<string, unknown>;
  switch (c.component) {
    case "Weather": {
      const now = c.now as { temp?: number; code?: string } | undefined;
      const day = c.day as { high?: number; low?: number; code?: string } | undefined;
      const place = (c.place as { name?: string })?.name ?? "";
      return {
        template: "number" as const,
        value: now?.temp !== undefined ? Math.round(now.temp) : Math.round(day?.high ?? 0),
        unit: "°",
        label: `${place} · ${CONDITION_WORDS[now?.code ?? day?.code ?? "cloudy"] ?? ""}`,
      };
    }
    case "Quote": {
      return {
        template: "number" as const,
        value: Number(c.price),
        unit: String(c.currency ?? ""),
        label: `${c.symbol} ${Number(c.changePct ?? 0) >= 0 ? "▲" : "▼"} ${Math.abs(Number(c.changePct ?? 0)).toFixed(2)}%`,
      };
    }
    default:
      return { template: "text" as const, text: built.short ?? built.text.slice(0, 80) };
  }
}
