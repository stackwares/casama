/** Attention rules (D-153): "Less like this" on a proactive message becomes a memory for its bot. */

import { track } from "@casama/agent";
import { routes } from "@casama/contracts";
import { contentKeys } from "@casama/db";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { sql } from "drizzle-orm";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";

export function registerAttentionRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;
  app.openapi(routes.lessLikeThis, async (c) => {
    const claims = c.get("claims");
    if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
    const [n] = await db.execute<{
      org_id: string | null;
      payload: { title?: string; bot_id?: string; why?: { rule?: string } };
    }>(sql`
      select org_id, payload from public.notifications where id = ${c.req.valid("param").id}::uuid and user_id = ${claims.sub}::uuid`);
    if (!n) throw new ApiError(404, "notification_not_found", "No such notification");
    const botId = n.payload?.bot_id;
    if (!botId || !n.org_id)
      throw new ApiError(404, "no_bot", "This message didn't come from a bot");
    const [b] = await db.execute<{ id: string }>(
      sql`select id from public.bots where id = ${botId}::uuid and org_id = ${n.org_id}::uuid`,
    );
    if (!b) throw new ApiError(404, "bot_not_found", "That bot is gone");
    // The bot's memory is shared by everyone who uses it: keep only the message's kind and title
    // (not the why, which names places and apps), unpinned (audit 2026-11).
    const kind = n.payload.why?.rule?.startsWith("Routine") ? "routine results" : "suggestions";
    const text = `Someone using this bot asked for fewer ${kind} like "${(n.payload.title ?? "this").slice(0, 120)}". Send these only when they really matter, or fold them into the brief.`;
    await db.execute(sql`
      insert into public.memories (org_id, bot_id, kind, content, importance, pinned)
      values (${n.org_id}::uuid, ${botId}::uuid, 'preference', ${contentKeys.seal(n.org_id, text)}, 0.7, false)`);
    track(db, {
      event: "proactive_muted",
      userId: claims.sub,
      orgId: n.org_id,
      properties: { kind },
    });
    return c.json({ ok: true }, 200);
  });
}
