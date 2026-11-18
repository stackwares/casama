/** Starter requests for an empty chat (D-338): the saved list, or rules while a new one is written. */

import {
  lastAppAdded,
  ruleStarters,
  starterSignals,
  startersStale,
  storedStarters,
} from "@casama/agent";
import { routes } from "@casama/contracts";
import { withUserSession } from "@casama/db";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { sql } from "drizzle-orm";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";

export function registerStarterRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;
  app.openapi(routes.getBotStarters, async (c) => {
    const claims = c.get("claims");
    if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
    const botId = c.req.valid("param").id;
    // Row-level security decides who sees the bot.
    const [bot] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ org_id: string }>(
        sql`select org_id from public.bots where id = ${botId}::uuid and archived_at is null`,
      ),
    );
    if (!bot) throw new ApiError(404, "bot_not_found", "No such bot");
    const ids = { userId: claims.sub, orgId: bot.org_id, botId };
    const saved = await storedStarters(db, claims.sub, botId);
    const stale = startersStale(saved, await lastAppAdded(db, botId));
    let refreshing = false;
    if (stale) {
      // The worker writes the new list; the app asks again shortly. Enqueued once an hour at most.
      refreshing = await deps.workflows
        .refreshStarters(ids.userId, ids.orgId, ids.botId)
        .then(() => true)
        .catch(() => false);
    }
    if (saved?.items.length)
      return c.json({ items: saved.items, source: saved.source, refreshing }, 200);
    const signals = await starterSignals(db, ids);
    const items = ruleStarters(signals ?? { apps: [], timezone: "UTC", now: new Date() });
    return c.json({ items, source: "rules" as const, refreshing }, 200);
  });
}
