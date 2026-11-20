/**
 * Live data cards (docs/RICH-CARDS-PLAN.md §4.4–4.6): refreshing a shown card and its other
 * views without the model, reports of wrong data, pinning a card to the widgets, and the person's
 * home city and units. Who may touch a card is decided by row-level security on `live_cards`
 * (whoever can read its run's chat; personal cards only their person).
 */
import {
  type LiveCardRow,
  LiveDataError,
  LiveEngine,
  liveCache,
  liveHttp,
  loadLiveCard,
  lookupPlaces,
  PinError,
  type Place,
  pinLiveCard,
  refreshLiveCard,
  unpinLiveCard,
} from "@casama/agent";
import { routes } from "@casama/contracts";
import { type JwtClaims, withUserSession } from "@casama/db";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { sql } from "drizzle-orm";
import { liveDataConfigFromEnv } from "../../services/live-data.ts";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";

const requireSession = (c: {
  get(k: "claims"): JwtClaims | undefined;
  get(k: "widgetKey"): unknown;
  get(k: "watchKey"): unknown;
}) => {
  const claims = c.get("claims");
  if (!claims || c.get("widgetKey") || c.get("watchKey"))
    throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
  return claims;
};

/** Requests per person per minute on these routes (on top of the API's own limit). */
const PER_MINUTE = 60;

export function registerLiveCardRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;
  let built: LiveEngine | null | undefined;
  const need = () => {
    if (deps.liveEngine !== undefined) built = deps.liveEngine;
    if (built === undefined) {
      const config = liveDataConfigFromEnv(deps.env);
      built = config
        ? new LiveEngine(liveHttp(deps.apps?.fetch ?? fetch), liveCache(db), config)
        : null;
    }
    if (!built) throw new ApiError(404, "not_available", "Live data cards are off on this server");
    return built;
  };
  const windows = new Map<string, { start: number; n: number }>();
  const limit = (userId: string) => {
    const t = Date.now();
    const w = windows.get(userId);
    if (!w || t - w.start > 60_000) windows.set(userId, { start: t, n: 1 });
    else if (++w.n > PER_MINUTE)
      throw new ApiError(429, "rate_limited", "Too many card refreshes; wait a minute");
    if (windows.size > 20_000) windows.clear();
  };

  /** The card if this person may see it (row-level security), else 404. */
  const visible = async (claims: JwtClaims, id: string): Promise<LiveCardRow> => {
    const [seen] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ id: string }>(sql`select id from public.live_cards where id = ${id}::uuid`),
    );
    const row = seen ? await loadLiveCard(db, id) : null;
    if (!row) throw new ApiError(404, "card_not_found", "Card not found");
    return row;
  };

  const out = (row: LiveCardRow, card: Record<string, unknown>, error?: string) => ({
    id: row.id,
    card,
    fetched_at: new Date(error ? row.fetched_at : Date.now()).toISOString(),
    error: error ?? null,
    pinned: Boolean(row.pinned_canvas_id),
  });

  app.openapi(routes.getLiveCards, async (c) => {
    const claims = requireSession(c);
    const ids = c.req
      .valid("query")
      .ids.split(",")
      .map((s) => s.trim())
      .filter((s) => /^[0-9a-f-]{36}$/i.test(s))
      .slice(0, 20);
    if (!ids.length) return c.json({ items: [] }, 200);
    const rows = await withUserSession(db, claims, (tx) =>
      tx.execute<{
        id: string;
        data: Record<string, unknown>;
        fetched_at: Date | string;
        pinned_canvas_id: string | null;
      }>(sql`
        select id, data, fetched_at, pinned_canvas_id from public.live_cards
        where id in (${sql.join(
          ids.map((i) => sql`${i}::uuid`),
          sql`, `,
        )})`),
    );
    return c.json(
      {
        items: rows.map((r) => ({
          id: r.id,
          card: r.data,
          fetched_at: new Date(r.fetched_at).toISOString(),
          error: null,
          pinned: Boolean(r.pinned_canvas_id),
        })),
      },
      200,
    );
  });

  app.openapi(routes.refreshLiveCard, async (c) => {
    const claims = requireSession(c);
    limit(claims.sub);
    const e = need();
    const { id } = c.req.valid("param");
    const body = c.req.valid("json");
    const row = await visible(claims, id);
    try {
      const r = await refreshLiveCard(db, e, row, { view: body.view, force: body.force });
      return c.json(out(row, r.card, r.error), 200);
    } catch (err) {
      if (err instanceof LiveDataError)
        throw new ApiError(err.code === "rate_limited" ? 429 : 400, err.code, err.message);
      throw err;
    }
  });

  app.openapi(routes.reportLiveCard, async (c) => {
    const claims = requireSession(c);
    limit(claims.sub);
    const { id } = c.req.valid("param");
    const row = await visible(claims, id);
    const live = (row.data.live ?? {}) as { source?: { id?: string } };
    await db.execute(sql`
      insert into public.live_card_reports (live_card_id, org_id, user_id, card, provider, snapshot)
      values (${row.id}::uuid, ${row.org_id}::uuid, ${claims.sub}::uuid, ${row.card}, ${live.source?.id ?? null},
              ${JSON.stringify(row.data)}::jsonb)`);
    return c.json({ ok: true }, 200);
  });

  app.openapi(routes.pinLiveCard, async (c) => {
    const claims = requireSession(c);
    limit(claims.sub);
    const e = need();
    const { id } = c.req.valid("param");
    const body = c.req.valid("json");
    const row = await visible(claims, id);
    const [m] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ ok: boolean }>(sql`select public.is_member(${row.org_id}::uuid) as ok`),
    );
    if (!m?.ok) throw new ApiError(403, "forbidden", "Not a member of this workspace");
    try {
      const canvas = await pinLiveCard(db, e, row, claims.sub, body.units ?? null);
      deps.glance?.changed(claims.sub, { urgent: true });
      return c.json({ canvas_id: canvas.id, status: canvas.status }, 200);
    } catch (err) {
      if (err instanceof PinError) throw new ApiError(400, err.code, err.message);
      if (
        err instanceof Error &&
        "code" in err &&
        typeof (err as { code: unknown }).code === "string"
      )
        throw new ApiError(400, String((err as { code: string }).code), err.message);
      throw err;
    }
  });

  app.openapi(routes.unpinLiveCard, async (c) => {
    const claims = requireSession(c);
    const { id } = c.req.valid("param");
    await visible(claims, id);
    await unpinLiveCard(db, id, claims.sub);
    deps.glance?.changed(claims.sub, { urgent: true });
    return c.json({ ok: true }, 200);
  });

  const prefsOf = async (userId: string) => {
    const [p] = await db.execute<{
      home_place: Place | null;
      card_units: Record<string, string> | null;
    }>(sql`
      select home_place, card_units from public.profiles where user_id = ${userId}::uuid`);
    const h = p?.home_place;
    return {
      home_place: h
        ? {
            name: h.name,
            region: h.region ?? null,
            country: h.country ?? null,
            country_name: h.countryName ?? null,
            lat: h.lat,
            lng: h.lng,
            tz: h.tz ?? null,
          }
        : null,
      units: p?.card_units ?? null,
    };
  };

  app.openapi(routes.getCardPrefs, async (c) => {
    const claims = requireSession(c);
    return c.json(await prefsOf(claims.sub), 200);
  });

  app.openapi(routes.updateCardPrefs, async (c) => {
    const claims = requireSession(c);
    const body = c.req.valid("json");
    if (body.home_place !== undefined) {
      const h = body.home_place;
      // A city, rounded: nobody's street is kept (§4.6).
      const place: Place | null = h
        ? {
            name: h.name.slice(0, 80),
            region: h.region ?? undefined,
            country: h.country ?? undefined,
            countryName: h.country_name ?? undefined,
            lat: Math.round(h.lat * 100) / 100,
            lng: Math.round(h.lng * 100) / 100,
            tz: h.tz ?? undefined,
          }
        : null;
      if (place && (Math.abs(place.lat) > 90 || Math.abs(place.lng) > 180))
        throw new ApiError(400, "bad_place", "Coordinates out of range");
      await db.execute(
        sql`update public.profiles set home_place = ${place ? JSON.stringify(place) : null}::jsonb where user_id = ${claims.sub}::uuid`,
      );
    }
    if (body.units !== undefined)
      await db.execute(
        sql`update public.profiles set card_units = ${body.units ? JSON.stringify(body.units) : null}::jsonb where user_id = ${claims.sub}::uuid`,
      );
    return c.json(await prefsOf(claims.sub), 200);
  });

  app.openapi(routes.searchPlaces, async (c) => {
    const claims = requireSession(c);
    limit(claims.sub);
    const e = need();
    const { q } = c.req.valid("query");
    try {
      const places = await lookupPlaces(e.http, e.cache, q, 8);
      return c.json(
        {
          items: places.map((p) => ({
            name: p.name,
            region: p.region ?? null,
            country: p.country ?? null,
            country_name: p.countryName ?? null,
            lat: p.lat,
            lng: p.lng,
            tz: p.tz ?? null,
          })),
        },
        200,
      );
    } catch (err) {
      if (err instanceof LiveDataError) return c.json({ items: [] }, 200);
      throw err;
    }
  });
}
