/** Attention rules (D-153): "Less like this" on a proactive message becomes a memory for its bot. */
import type { OpenAPIHono } from "@hono/zod-openapi";
import { routes } from "@kasama/contracts";
import { contentKeys } from "@kasama/db";
import { sql } from "drizzle-orm";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";

export function registerAttentionRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;
  app.openapi(routes.lessLikeThis, async (c) => {
    const claims = c.get("claims");
    if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
    const [n] = await db.execute<{ org_id: string | null; payload: { title?: string; bot_id?: string; why?: { rule?: string } } }>(sql`
      select org_id, payload from public.notifications where id = ${c.req.valid("param").id}::uuid and user_id = ${claims.sub}::uuid`);
    if (!n) throw new ApiError(404, "notification_not_found", "No such notification");
    const botId = n.payload?.bot_id;
    if (!botId || !n.org_id) throw new ApiError(404, "no_bot", "This message didn't come from a bot");
    const [b] = await db.execute<{ id: string }>(sql`select id from public.bots where id = ${botId}::uuid and org_id = ${n.org_id}::uuid`);
    if (!b) throw new ApiError(404, "bot_not_found", "That bot is gone");
    const text = `The person wants fewer messages like this: "${n.payload.title ?? "an update"}"${n.payload.why?.rule ? ` (sent because: ${n.payload.why.rule})` : ""}. Send these only when they really matter, or fold them into the brief.`;
    await db.execute(sql`
      insert into public.memories (org_id, bot_id, kind, content, importance, pinned)
      values (${n.org_id}::uuid, ${botId}::uuid, 'preference', ${contentKeys.seal(n.org_id, text.slice(0, 8000))}, 0.9, true)`);
    return c.json({ ok: true }, 200);
  });
}
