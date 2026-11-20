/**
 * Bot widgets (docs/BOT-WIDGET-PLAN.md §9.2): what bots keep on a person's Canvas widgets.
 *
 * Widgets read canvases and their pictures with their widget key (read-only, held to the key's
 * hourly allowance, private keys get names only). The person pauses, hides on a locked phone,
 * clears and allows bots with their session. Bots write through `widget.*` in the worker.
 */
import {
  canvasListVersion,
  canvasOut,
  getCanvas,
  listCanvases,
  placements,
  readPainting,
  readPicture,
  recordCanvasSeen,
  setWidgetsAllowed,
  widgetGrants,
} from "@casama/agent";
import { type Canvas, routes } from "@casama/contracts";
import { type JwtClaims, withUserSession } from "@casama/db";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { sql } from "drizzle-orm";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { iso } from "../util.ts";
import { matchesVersion } from "./glance.ts";

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

export function registerCanvasRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;

  const isMember = async (claims: JwtClaims, orgId: string) => {
    const [r] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ ok: boolean }>(sql`select public.is_member(${orgId}::uuid) as ok`),
    );
    return r?.ok === true;
  };

  app.openapi(routes.getCanvases, async (c) => {
    const widget = c.get("widgetKey");
    const claims = c.get("claims");
    if (!claims || c.get("watchKey"))
      throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
    const q = c.req.valid("query");
    let orgId: string;
    let priv = false;
    if (widget) {
      if (q.org_id && q.org_id !== widget.orgId)
        throw new ApiError(403, "forbidden", "This widget key reads another workspace");
      orgId = widget.orgId;
      // A private key (app lock, D-405) shows names and bots only, until Show details is on.
      priv = widget.private;
      await recordCanvasSeen(db, widget.id, q.sizes);
    } else {
      if (!q.org_id) throw new ApiError(400, "org_required", "Say which workspace (org_id)");
      if (!(await isMember(claims, q.org_id)))
        throw new ApiError(404, "org_not_found", "Workspace not found");
      orgId = q.org_id;
    }
    const now = Date.now();
    const rows = await listCanvases(db, {
      userId: claims.sub,
      orgId,
      shownOnly: !!widget,
      now: new Date(now),
    });
    const items: Canvas[] = rows.map((r) => canvasOut(r, { private: priv, now }));
    const session = !widget;
    const grants = session ? await widgetGrants(db, claims.sub, orgId) : [];
    const placed = session ? await placements(db, claims.sub, orgId, now) : [];
    const body = {
      private: priv,
      items,
      grants: grants.map((g) => ({ bot_id: g.bot_id, bot: g.bot, created_at: iso(g.created_at) })),
      placed,
    };
    const version = canvasListVersion(body);
    c.header("etag", `"${version}"`);
    c.header("cache-control", "private, no-cache");
    if (matchesVersion(c.req.header("if-none-match"), version)) return c.body(null, 304) as never;
    return c.json({ version, made_at: new Date(now).toISOString(), ...body }, 200);
  });

  app.openapi(routes.getCanvasPicture, async (c) => {
    const widget = c.get("widgetKey");
    const claims = c.get("claims");
    if (!claims || c.get("watchKey"))
      throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
    const { id, hash } = c.req.valid("param");
    const row = await getCanvas(db, id, claims.sub);
    if (!row || (widget && (row.org_id !== widget.orgId || widget.private)))
      throw new ApiError(404, "picture_not_found", "Picture not found");
    const bytes = hash.startsWith("painting-")
      ? await readPainting(hash.slice("painting-".length))
      : await readPicture(db, deps.objects, id, hash);
    if (!bytes) throw new ApiError(404, "picture_not_found", "Picture not found");
    return c.body(bytes as never, 200, {
      "content-type": "image/jpeg",
      // The hash is in the address: the same address is always the same picture.
      "cache-control": "private, max-age=31536000, immutable",
    }) as never;
  });

  app.openapi(routes.updateCanvas, async (c) => {
    const claims = requireSession(c);
    const { id } = c.req.valid("param");
    const b = c.req.valid("json");
    const [row] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ id: string; status: string }>(sql`
        update public.widget_canvases set
          status = case
            when ${b.status ?? null}::text = 'paused' and status = 'shown' then 'paused'
            when ${b.status ?? null}::text = 'shown' and status = 'paused' then 'shown'
            else status end,
          hide_when_locked = coalesce(${b.hide_when_locked ?? null}::boolean, hide_when_locked)
        where id = ${id}::uuid returning id, status`),
    );
    if (!row) throw new ApiError(404, "canvas_not_found", "Canvas not found");
    deps.glance?.changed(claims.sub, { urgent: true });
    const out = await getCanvas(db, id, claims.sub);
    return c.json(canvasOut(out as NonNullable<typeof out>), 200);
  });

  app.openapi(routes.deleteCanvas, async (c) => {
    const claims = requireSession(c);
    const { id } = c.req.valid("param");
    const [row] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ id: string }>(
        sql`delete from public.widget_canvases where id = ${id}::uuid returning id`,
      ),
    );
    if (!row) throw new ApiError(404, "canvas_not_found", "Canvas not found");
    deps.glance?.changed(claims.sub, { urgent: true });
    return c.json({ deleted: row.id }, 200);
  });

  app.openapi(routes.setCanvasGrant, async (c) => {
    const claims = requireSession(c);
    const b = c.req.valid("json");
    // Only bots the person can use (sharing rules, D-131).
    const [ok] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ ok: boolean }>(sql`select public.can_access_bot(${b.bot_id}::uuid) as ok`),
    );
    if (!ok?.ok) throw new ApiError(404, "bot_not_found", "Bot not found");
    const r = await setWidgetsAllowed(db, claims.sub, b.bot_id, b.allowed);
    if (r.shown || r.cleared) deps.glance?.changed(claims.sub, { urgent: true });
    return c.json({ allowed: b.allowed, ...r }, 200);
  });
}
