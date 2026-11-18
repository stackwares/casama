/**
 * Message reactions on the agent side (D-331): notes in the history a bot reads, a run digest's
 * liked / went-wrong signal, and bots reacting themselves.
 */
import type { Database } from "@casama/db";
import { normalizeReaction, reactionSentiment } from "@casama/domain";
import { sql } from "drizzle-orm";

/** Only the most recent turns carry reaction notes, so old ones cost nothing. */
export const REACTION_HISTORY_TURNS = 50;

/**
 * "[Reactions: ❤️ from Oliver, 👍 from Writer]" per message id, for the messages that have any.
 * The reading bot's own reactions say "you".
 */
export async function reactionNotes(
  db: Database,
  messageIds: string[],
  selfBotId: string,
): Promise<Map<string, string>> {
  const out = new Map<string, string>();
  const ids = messageIds.slice(-REACTION_HISTORY_TURNS);
  if (!ids.length) return out;
  const rows = await db
    .execute<{ message_id: string; emoji: string; bot_id: string | null; name: string | null }>(sql`
      select r.message_id, r.emoji, r.bot_id,
        case when r.bot_id is not null then b.name
             when r.external_sender is not null then nullif(trim(r.external_name), '')
             else nullif(trim(p.display_name), '') end as name
      from public.message_reactions r
      left join public.bots b on b.id = r.bot_id
      left join public.profiles p on p.user_id = r.user_id
      where r.message_id in (select jsonb_array_elements_text(${JSON.stringify(ids)}::jsonb)::uuid)
      order by r.created_at, r.id`)
    .catch(() => []);
  const by = new Map<string, string[]>();
  for (const r of rows) {
    const who = r.bot_id === selfBotId ? "you" : (r.name ?? (r.bot_id ? "a bot" : "someone"));
    by.set(r.message_id, [...(by.get(r.message_id) ?? []), `${r.emoji} from ${who}`]);
  }
  for (const [id, list] of by) out.set(id, `[Reactions: ${list.join(", ")}]`);
  return out;
}

/**
 * Sets the run digest's `reaction` from what people reacted to the run's replies with: the most
 * recent reaction that says something (👍 ❤️ liked, 👎 😡 something went wrong) wins; none clears
 * it. Bots' reactions don't count.
 */
export async function syncRunReaction(
  db: Database,
  runId: string,
): Promise<"positive" | "negative" | null> {
  const rows = await db.execute<{ emoji: string }>(sql`
    select r.emoji from public.message_reactions r join public.messages m on m.id = r.message_id
    where m.run_id = ${runId}::uuid and m.role = 'assistant' and r.bot_id is null
    order by r.updated_at desc, r.created_at desc`);
  let sentiment: "positive" | "negative" | null = null;
  for (const r of rows) {
    sentiment = reactionSentiment(r.emoji);
    if (sentiment) break;
  }
  await db.execute(
    sql`update public.run_digests set reaction = ${sentiment} where run_id = ${runId}::uuid and reaction is distinct from ${sentiment}`,
  );
  return sentiment;
}

/** The run a message belongs to, when it's a bot's reply. */
export async function replyRunOf(db: Database, messageId: string): Promise<string | null> {
  const [m] = await db.execute<{ run_id: string | null }>(
    sql`select run_id from public.messages where id = ${messageId}::uuid and role = 'assistant'`,
  );
  return m?.run_id ?? null;
}

export class ReactionError extends Error {
  readonly code: "invalid_emoji" | "message_not_found" | "not_reactable";
  constructor(code: ReactionError["code"], message: string) {
    super(message);
    this.code = code;
  }
}

/**
 * A bot's reaction to a message in a conversation it works in (null emoji removes it). One per
 * bot per message: another emoji replaces it.
 */
export async function setBotReaction(
  db: Database,
  a: { botId: string; conversationId: string; messageId: string; emoji: string | null },
) {
  const [m] = await db.execute<{ role: string }>(sql`
    select role from public.messages where id = ${a.messageId}::uuid and conversation_id = ${a.conversationId}::uuid`);
  if (!m) throw new ReactionError("message_not_found", "No such message in this chat.");
  if (m.role !== "user" && m.role !== "assistant")
    throw new ReactionError("not_reactable", "Only messages people read take reactions.");
  const emoji = a.emoji === null ? null : normalizeReaction(a.emoji);
  if (a.emoji !== null && !emoji)
    throw new ReactionError("invalid_emoji", "A reaction is exactly one emoji.");
  const [had] = await db.execute<{ emoji: string }>(
    sql`select emoji from public.message_reactions where message_id = ${a.messageId}::uuid and bot_id = ${a.botId}::uuid`,
  );
  const previous = had?.emoji ?? null;
  if (emoji === null) {
    if (previous)
      await db.execute(
        sql`delete from public.message_reactions where message_id = ${a.messageId}::uuid and bot_id = ${a.botId}::uuid`,
      );
  } else if (emoji !== previous) {
    await db.execute(sql`
      insert into public.message_reactions (message_id, conversation_id, org_id, bot_id, emoji, source)
      select m.id, m.conversation_id, m.org_id, ${a.botId}::uuid, ${emoji}, 'bot'
      from public.messages m where m.id = ${a.messageId}::uuid
      on conflict (message_id, bot_id) where bot_id is not null
      do update set emoji = excluded.emoji`);
  }
  return { emoji, previous };
}

/**
 * A reaction from someone in a chat app (D-331 Phase 3), who has no Casama account: set, replaced
 * or removed. `removed` is the emoji they took back (Slack keeps several per person, so taking
 * back one we don't hold changes nothing); null `emoji` and no `removed` removes theirs. Returns
 * false when nothing changed.
 */
export async function setChannelReaction(
  db: Database,
  a: {
    channelId: string;
    sender: string;
    senderName?: string | null;
    messageId: string;
    emoji: string | null;
    removed?: string | null;
  },
) {
  const [m] = await db.execute<{ role: string; run_id: string | null }>(
    sql`select role, run_id from public.messages where id = ${a.messageId}::uuid`,
  );
  if (!m || (m.role !== "user" && m.role !== "assistant")) return false;
  const who = `${a.channelId}:${a.sender}`.slice(0, 400);
  const name = a.senderName?.trim().slice(0, 200) || null;
  if (a.emoji === null) {
    const removed = a.removed ? normalizeReaction(a.removed) : null;
    if (a.removed && !removed) return false;
    const gone = await db.execute<{ id: string }>(sql`
      delete from public.message_reactions
      where message_id = ${a.messageId}::uuid and external_sender = ${who}
        and (${removed}::text is null or emoji = ${removed}::text)
      returning id`);
    if (!gone.length) return false;
  } else {
    const emoji = normalizeReaction(a.emoji);
    if (!emoji) return false;
    await db.execute(sql`
      insert into public.message_reactions (message_id, conversation_id, org_id, external_sender, external_name, emoji, source)
      select m.id, m.conversation_id, m.org_id, ${who}, ${name}, ${emoji}, 'channel'
      from public.messages m where m.id = ${a.messageId}::uuid
      on conflict (message_id, external_sender) where external_sender is not null
      do update set emoji = excluded.emoji, external_name = coalesce(excluded.external_name, message_reactions.external_name)`);
  }
  if (m.role === "assistant" && m.run_id) await syncRunReaction(db, m.run_id);
  return true;
}
