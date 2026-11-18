/**
 * Message reactions (D-331, docs/REACTIONS-PLAN.md): an emoji on a message, one per person per
 * message. Whoever can read the chat sees them and may react; a reaction on a bot's reply sets the
 * run digest's liked / went-wrong signal. Reactions start no run.
 */
import { syncRunReaction } from "@casama/agent";
import { routes } from "@casama/contracts";
import { type JwtClaims, withUserSession } from "@casama/db";
import { normalizeReaction, summarizeReactions } from "@casama/domain";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { sql } from "drizzle-orm";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { iso } from "../util.ts";

/** Reaction changes a person may make in a minute. */
export const REACTIONS_PER_MINUTE = 60;
/** People listed per emoji in a summary; the full list is GET …/reactions. */
const USERS_PER_EMOJI = 20;

const requireClaims = (claims: JwtClaims | undefined): JwtClaims => {
  if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
  return claims;
};

type ReactionRow = {
  emoji: string;
  user_id: string | null;
  bot_id: string | null;
};

/** The reactions on one message, grouped, as [claims] sees them. */
export async function reactionSummary(
  db: AppDeps["db"],
  claims: JwtClaims,
  messageIds: string[],
): Promise<Map<string, ReturnType<typeof summarizeReactions>>> {
  const out = new Map<string, ReturnType<typeof summarizeReactions>>();
  if (!messageIds.length) return out;
  const rows = await withUserSession(db, claims, (tx) =>
    tx.execute<ReactionRow & { message_id: string }>(sql`
      select message_id, emoji, user_id, bot_id from public.message_reactions
      where message_id in (select jsonb_array_elements_text(${JSON.stringify(messageIds)}::jsonb)::uuid)
      order by created_at, id`),
  );
  const by = new Map<string, ReactionRow[]>();
  for (const r of rows) by.set(r.message_id, [...(by.get(r.message_id) ?? []), r]);
  for (const [id, list] of by)
    out.set(
      id,
      summarizeReactions(list, claims.sub).map((g) => ({
        ...g,
        users: g.users.slice(0, USERS_PER_EMOJI),
      })),
    );
  return out;
}

export function registerReactionRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;

  // A fixed window per person (in memory, like the API's own limiter).
  const windows = new Map<string, { start: number; count: number }>();
  const limit = (userId: string) => {
    const t = Date.now();
    let w = windows.get(userId);
    if (!w || t - w.start >= 60_000) {
      w = { start: t, count: 0 };
      windows.set(userId, w);
      if (windows.size > 50_000)
        for (const [k, v] of windows) if (t - v.start >= 60_000) windows.delete(k);
    }
    if (++w.count > REACTIONS_PER_MINUTE)
      throw new ApiError(429, "rate_limited", "Too many reactions. Wait a moment and try again.", {
        headers: { "retry-after": String(Math.max(1, Math.ceil((w.start + 60_000 - t) / 1000))) },
      });
  };

  /** The message, when the caller can read it and it takes reactions. */
  const messageOf = async (claims: JwtClaims, conversationId: string, messageId: string) => {
    const [m] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ id: string; role: string; run_id: string | null }>(sql`
        select id, role, run_id from public.messages
        where id = ${messageId}::uuid and conversation_id = ${conversationId}::uuid`),
    );
    if (!m) throw new ApiError(404, "message_not_found", "Message not found");
    if (m.role !== "user" && m.role !== "assistant")
      throw new ApiError(400, "not_reactable", "Only messages people read take reactions");
    return m;
  };

  /** A bot's reply changed reactions: the run digest's signal follows. */
  const afterChange = async (m: { role: string; run_id: string | null }) => {
    if (m.role === "assistant" && m.run_id) await syncRunReaction(db, m.run_id).catch(() => null);
  };

  const summaryOut = async (claims: JwtClaims, messageId: string) => ({
    message_id: messageId,
    reactions: (await reactionSummary(db, claims, [messageId])).get(messageId) ?? [],
  });

  app.openapi(routes.setReaction, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id, message_id } = c.req.valid("param");
    const emoji = normalizeReaction(c.req.valid("json").emoji);
    if (!emoji) throw new ApiError(400, "invalid_emoji", "A reaction is exactly one emoji");
    limit(claims.sub);
    const m = await messageOf(claims, id, message_id);
    await withUserSession(db, claims, (tx) =>
      tx.execute(sql`
        insert into public.message_reactions (message_id, conversation_id, org_id, user_id, emoji, source)
        select m.id, m.conversation_id, m.org_id, ${claims.sub}::uuid, ${emoji}, 'app'
        from public.messages m where m.id = ${message_id}::uuid
        on conflict (message_id, user_id) where user_id is not null
        do update set emoji = excluded.emoji, source = excluded.source
        where message_reactions.emoji is distinct from excluded.emoji`),
    );
    await afterChange(m);
    return c.json(await summaryOut(claims, message_id), 200);
  });

  app.openapi(routes.removeReaction, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id, message_id } = c.req.valid("param");
    limit(claims.sub);
    const m = await messageOf(claims, id, message_id);
    await withUserSession(db, claims, (tx) =>
      tx.execute(sql`
        delete from public.message_reactions
        where message_id = ${message_id}::uuid and user_id = ${claims.sub}::uuid`),
    );
    await afterChange(m);
    return c.json(await summaryOut(claims, message_id), 200);
  });

  app.openapi(routes.listMessageReactions, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id, message_id } = c.req.valid("param");
    await messageOf(claims, id, message_id);
    // Names and pictures of whoever reacted: people who can read this chat, its bots, and chat-app
    // senders. Read with the server's connection once the caller is known to see the message.
    const rows = await db.execute<{
      emoji: string;
      user_id: string | null;
      bot_id: string | null;
      name: string | null;
      avatar_url: string | null;
      source: "app" | "api" | "channel" | "bot";
      created_at: string;
    }>(sql`
      select r.emoji, r.user_id, r.bot_id, r.source, r.created_at,
        case when r.bot_id is not null then b.name
             when r.external_sender is not null then nullif(trim(r.external_name), '')
             else nullif(trim(p.display_name), '') end as name,
        case when r.bot_id is not null then b.avatar_url
             when r.user_id is not null then p.avatar_url end as avatar_url
      from public.message_reactions r
      left join public.bots b on b.id = r.bot_id
      left join public.profiles p on p.user_id = r.user_id
      where r.message_id = ${message_id}::uuid
      order by r.created_at, r.id`);
    return c.json(
      {
        message_id,
        items: rows.map((r) => ({
          emoji: r.emoji,
          user_id: r.user_id,
          bot_id: r.bot_id,
          name: r.name ?? (r.user_id === claims.sub ? "You" : "Someone"),
          avatar_url: r.avatar_url,
          source: r.source,
          created_at: iso(r.created_at),
        })),
      },
      200,
    );
  });
}
