/** Check-ins (D-114): per-bot settings, the "For you" feed, and accepting or dismissing suggestions. */

import { applyCheckins, checkinPlanError, handleComposioEvent, track } from "@casama/agent";
import { routes } from "@casama/contracts";
import { contentKeys, type JwtClaims, withUserSession } from "@casama/db";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { sql } from "drizzle-orm";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { iso } from "../util.ts";

const claimsOf = (c: { get(k: "claims"): JwtClaims | undefined }) => {
  const claims = c.get("claims");
  if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
  return claims;
};

export function registerCheckinRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;

  const bot = async (claims: JwtClaims, id: string) => {
    const [b] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ org_id: string; manage: boolean }>(sql`
        select org_id, public.can_manage_bot(id) as manage from public.bots where id = ${id}::uuid and archived_at is null`),
    );
    if (!b) throw new ApiError(404, "bot_not_found", "Bot not found");
    return b;
  };
  const settings = async (id: string) => {
    const [s] = await db.execute<{
      enabled: boolean;
      brief_time: string;
      scan_every_hours: number;
      daily_cap_usd: string;
    }>(sql`
      select enabled, brief_time, scan_every_hours, daily_cap_usd from public.bot_checkins where bot_id = ${id}::uuid`);
    return {
      enabled: s?.enabled ?? false,
      brief_time: s?.brief_time ?? "08:00",
      scan_every_hours: s?.scan_every_hours ?? 3,
      daily_cap_usd: Number(s?.daily_cap_usd ?? 1),
    };
  };

  app.openapi(routes.getBotCheckins, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    await bot(claims, id);
    return c.json(await settings(id), 200);
  });

  app.openapi(routes.setBotCheckins, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    const body = c.req.valid("json");
    const b = await bot(claims, id);
    if (!b.manage)
      throw new ApiError(
        403,
        "forbidden",
        "Only people who manage this bot can change its check-ins",
      );
    // Proactive bots (D-247): the plan sets how many bots check in and how often.
    if (body.enabled) {
      const why = await checkinPlanError(db, {
        orgId: b.org_id,
        botId: id,
        scanEveryHours: body.scan_every_hours,
      });
      if (why) throw new ApiError(402, "plan_limit", why);
    }
    // Briefs and suggestions go to whoever turned check-ins on, in their timezone.
    await applyCheckins(db, {
      orgId: b.org_id,
      botId: id,
      userId: claims.sub,
      enabled: body.enabled,
      briefTime: body.brief_time,
      scanEveryHours: body.scan_every_hours,
      dailyCapUsd: body.daily_cap_usd,
    });
    return c.json(await settings(id), 200);
  });

  app.openapi(routes.getForYou, async (c) => {
    const claims = claimsOf(c);
    const { org_id } = c.req.valid("query");
    const out = await withUserSession(db, claims, async (tx) => {
      const briefs = await tx.execute<{
        bot_id: string;
        conversation_id: string;
        content: Array<{ type?: string; text?: string }>;
        created_at: string;
      }>(sql`
        select distinct on (rt.bot_id) rt.bot_id, m.conversation_id, m.content, m.created_at
        from public.routines rt
        join public.bot_checkins ck on ck.bot_id = rt.bot_id and ck.enabled and ck.user_id = ${claims.sub}::uuid
        join public.runs r on r.routine_id = rt.id
        join public.messages m on m.run_id = r.id and m.role = 'assistant'
        where rt.org_id = ${org_id}::uuid and rt.kind = 'brief' and m.created_at > now() - interval '36 hours'
        order by rt.bot_id, m.created_at desc`);
      const suggestions = await tx.execute<{
        id: string;
        bot_id: string;
        title: string;
        body_md: string;
        push_text: string | null;
        proposed_action: { tool: string; args?: Record<string, unknown> } | null;
        sources: string[];
        urgency: "normal";
        expires_at: string;
        created_at: string;
      }>(sql`
        select id, bot_id, title, body_md, push_text, proposed_action, sources, urgency, expires_at, created_at from public.suggestions
        where org_id = ${org_id}::uuid and user_id = ${claims.sub}::uuid and status = 'pending' and expires_at > now()
        order by case urgency when 'urgent' then 0 when 'normal' then 1 else 2 end, created_at desc limit 30`);
      const approvals = await tx.execute<{
        id: string;
        bot_id: string;
        summary: string;
        risk: string;
        created_at: string;
      }>(sql`
        select id, bot_id, summary, risk, created_at from public.approvals
        where org_id = ${org_id}::uuid and status = 'pending' and expires_at > now() order by created_at desc limit 20`);
      return { briefs, suggestions, approvals };
    });
    return c.json(
      {
        // Text is taken here, not in SQL: content may be sealed (D-136).
        briefs: out.briefs.map(({ content, ...b }) => ({
          ...b,
          text: (Array.isArray(content) ? content : [])
            .filter((p) => p.type === "text")
            .map((p) => p.text ?? "")
            .join(" "),
          created_at: iso(b.created_at),
        })),
        suggestions: out.suggestions.map((s) => ({
          ...s,
          expires_at: iso(s.expires_at),
          created_at: iso(s.created_at),
        })),
        approvals: out.approvals.map((a) => ({ ...a, created_at: iso(a.created_at) })),
      },
      200,
    );
  });

  /** A pending suggestion of this person's. */
  const mine = async (claims: JwtClaims, id: string) => {
    const [s] = await withUserSession(db, claims, (tx) =>
      tx.execute<{
        id: string;
        org_id: string;
        bot_id: string;
        title: string;
        body_md: string;
        proposed_action: unknown;
        status: string;
        created_at: string;
        message_id: string | null;
      }>(sql`
        select id, org_id, bot_id, title, body_md, proposed_action, status, created_at, message_id from public.suggestions where id = ${id}::uuid`),
    );
    if (!s) throw new ApiError(404, "suggestion_not_found", "Suggestion not found");
    if (s.status !== "pending")
      throw new ApiError(409, "suggestion_closed", `This suggestion was already ${s.status}`);
    return s;
  };
  // Proactive bots (D-247): how often suggestions are taken up, and how fast.
  const resolved = (
    claims: JwtClaims,
    s: { org_id: string; created_at: string },
    result: "accepted" | "dismissed" | "dismissed_forever",
  ) =>
    track(db, {
      event: "suggestion_resolved",
      userId: claims.sub,
      orgId: s.org_id,
      properties: {
        result,
        age_hours: Math.round((Date.now() - new Date(s.created_at).getTime()) / 360_000) / 10,
      },
    });

  app.openapi(routes.acceptSuggestion, async (c) => {
    const claims = claimsOf(c);
    const s = await mine(claims, c.req.valid("param").id);
    // The bot does it in a normal chat, so its tools go through the usual approvals.
    const text = [
      `Please do this now: ${s.title}`,
      s.body_md,
      s.proposed_action ? `The action you suggested: ${JSON.stringify(s.proposed_action)}` : "",
    ]
      .filter(Boolean)
      .join("\n\n");
    const created = await withUserSession(db, claims, async (tx) => {
      // A topic under the person's General (D-253), started from the suggestion's card there; it
      // posts its result back when the work is done.
      const [conv] = await tx.execute<{ id: string }>(sql`
        insert into public.conversations (org_id, bot_id, title, created_by, last_message_at, anchor_message_id, posts_result)
        values (${s.org_id}::uuid, ${s.bot_id}::uuid, ${s.title.slice(0, 200)}, ${claims.sub}::uuid, now(), ${s.message_id}::uuid, true) returning id`);
      const [run] = await tx.execute<{ id: string }>(sql`
        insert into public.runs (org_id, bot_id, conversation_id, created_by, trigger)
        values (${s.org_id}::uuid, ${s.bot_id}::uuid, ${conv?.id}::uuid, ${claims.sub}::uuid, 'chat') returning id`);
      await tx.execute(sql`
        insert into public.messages (org_id, conversation_id, role, author_user_id, content, run_id)
        values (${s.org_id}::uuid, ${conv?.id}::uuid, 'user', ${claims.sub}::uuid, ${contentKeys.sealJson(s.org_id, [{ type: "text", text }])}::jsonb, ${run?.id}::uuid)`);
      return { conversation_id: conv?.id as string, run_id: run?.id as string };
    });
    await db.execute(
      sql`update public.suggestions set status = 'accepted', resolved_at = now() where id = ${s.id}::uuid`,
    );
    resolved(claims, s, "accepted");
    await deps.workflows.startRun(created.run_id);
    return c.json(created, 202);
  });

  app.openapi(routes.dismissSuggestion, async (c) => {
    const claims = claimsOf(c);
    const s = await mine(claims, c.req.valid("param").id);
    const { dont_suggest_again } = c.req.valid("json");
    await db.execute(
      sql`update public.suggestions set status = 'dismissed', resolved_at = now() where id = ${s.id}::uuid`,
    );
    resolved(claims, s, dont_suggest_again ? "dismissed_forever" : "dismissed");
    if (dont_suggest_again)
      await db.execute(sql`
        insert into public.memories (org_id, bot_id, kind, content, importance, pinned)
        values (${s.org_id}::uuid, ${s.bot_id}::uuid, 'preference', ${contentKeys.seal(s.org_id, `Don't suggest this again: ${s.title}`.slice(0, 8000))}, 0.9, true)`);
    return c.json({ ok: true }, 200);
  });

  // App events start scans (D-247): Composio posts new mail and calendar changes here.
  app.post("/hooks/composio", async (c) => {
    const secret = deps.env.COMPOSIO_WEBHOOK_SECRET;
    if (!secret) return c.json({ error: "not_configured" }, 404);
    const body = await c.req.text();
    if (body.length > 1_000_000) return c.json({ error: "too_large" }, 413);
    const out = await handleComposioEvent(
      db,
      secret,
      {
        id: c.req.header("webhook-id"),
        timestamp: c.req.header("webhook-timestamp"),
        signature: c.req.header("webhook-signature"),
      },
      body,
    );
    if (!out.ok) return c.json({ error: out.reason }, out.reason === "bad_signature" ? 401 : 400);
    return c.json({ ok: true, scans: out.scans ?? 0 }, 200);
  });
}
