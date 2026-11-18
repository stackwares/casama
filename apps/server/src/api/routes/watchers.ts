/** Watchers (D-116): list, pause or resume, and delete a bot's watchers. */

import { routes } from "@casama/contracts";
import { type JwtClaims, withUserSession } from "@casama/db";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { sql } from "drizzle-orm";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { iso } from "../util.ts";

type Row = {
  id: string;
  bot_id: string;
  name: string;
  kind: "time";
  target: Record<string, unknown>;
  condition_md: string;
  status: "active";
  check_every_seconds: number;
  fired_count: number;
  last_checked_at: string | null;
  last_error: string | null;
  expires_at: string | null;
  conversation_id: string | null;
  created_at: string;
};
const COLS = sql`id, bot_id, name, kind, target, condition_md, status, check_every_seconds, fired_count, last_checked_at, last_error, expires_at, conversation_id, created_at`;
const out = (r: Row) => ({
  ...r,
  last_checked_at: r.last_checked_at ? iso(r.last_checked_at) : null,
  expires_at: r.expires_at ? iso(r.expires_at) : null,
  created_at: iso(r.created_at),
});

const claimsOf = (c: { get(k: "claims"): JwtClaims | undefined }) => {
  const claims = c.get("claims");
  if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
  return claims;
};

export function registerWatcherRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;

  app.openapi(routes.listWatchers, async (c) => {
    const claims = claimsOf(c);
    const rows = await withUserSession(db, claims, (tx) =>
      tx.execute<Row>(sql`select ${COLS} from public.watchers where bot_id = ${c.req.valid("query").bot_id}::uuid
        order by case status when 'active' then 0 when 'paused' then 1 else 2 end, created_at desc limit 200`),
    );
    return c.json({ items: rows.map(out) }, 200);
  });

  app.openapi(routes.updateWatcher, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    const { status } = c.req.valid("json");
    const [row] = await withUserSession(db, claims, (tx) =>
      tx.execute<Row>(sql`update public.watchers set status = ${status}, next_check_at = case when ${status} = 'active' then now() else next_check_at end
        where id = ${id}::uuid and status in ('active', 'paused') returning ${COLS}`),
    );
    if (!row)
      throw new ApiError(404, "watcher_not_found", "Watcher not found (or you can't change it)");
    return c.json(out(row), 200);
  });

  app.openapi(routes.deleteWatcher, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    const rows = await withUserSession(db, claims, (tx) =>
      tx.execute<{ id: string }>(
        sql`delete from public.watchers where id = ${id}::uuid returning id`,
      ),
    );
    if (!rows[0])
      throw new ApiError(404, "watcher_not_found", "Watcher not found (or you can't change it)");
    return c.json({ deleted: id }, 200);
  });
}
