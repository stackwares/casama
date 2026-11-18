/**
 * General and topics (D-253): each person has one General conversation with a bot, where briefs,
 * routine results and proactive messages land; work runs in topics under it.
 *
 * Posts into General (a suggestion's card, a topic's result) only go in while no run is working
 * there: a run's reply is attached to the message it answers, so a post in between would push the
 * reply onto a hidden branch. Anything that has to wait goes out on the next minute's sweep.
 */
import { contentKeys, type Database } from "@casama/db";
import { sql } from "drizzle-orm";

/** The person's General conversation with a bot, made when they have none. */
export async function mainConversation(db: Database, orgId: string, botId: string, userId: string) {
  const [r] = await db.execute<{ id: string }>(
    sql`select public.main_conversation(${orgId}::uuid, ${botId}::uuid, ${userId}::uuid) as id`,
  );
  return r?.id as string;
}

async function busy(db: Database, conversationId: string, except?: string) {
  const [r] = await db.execute<{ busy: boolean }>(sql`
    select exists (select 1 from public.runs where conversation_id = ${conversationId}::uuid
      and status in ('queued', 'running', 'waiting_approval', 'waiting_takeover', 'waiting_computer')
      and (id <> ${except ?? null}::uuid) is not false) as busy`);
  return r?.busy === true;
}

/** Posts a message from the bot into a conversation; null when a run is working there. */
export async function postFromBot(
  db: Database,
  p: {
    orgId: string;
    conversationId: string;
    botId: string;
    parts: unknown[];
    /** A run that has already said its last word (posts right after it ends). */
    afterRun?: string;
  },
): Promise<string | null> {
  if (await busy(db, p.conversationId, p.afterRun)) return null;
  const [m] = await db.execute<{ id: string }>(sql`
    insert into public.messages (org_id, conversation_id, role, content, bot_id)
    values (${p.orgId}::uuid, ${p.conversationId}::uuid, 'assistant', ${contentKeys.sealJson(p.orgId, p.parts)}::jsonb, ${p.botId}::uuid)
    returning id`);
  await db.execute(
    sql`update public.conversations set last_message_at = now() where id = ${p.conversationId}::uuid`,
  );
  return m?.id ?? null;
}

type Unposted = {
  id: string;
  org_id: string;
  bot_id: string;
  user_id: string;
  title: string;
  body_md: string;
  push_text: string | null;
};

/** How many suggestions one message lists (D-257); the rest come with the next one. */
const BATCH = 5;
/** An open question older than this no longer holds new suggestions back: the person moved on. */
const OPEN_FOR_MS = 24 * 3600_000;

/**
 * Whether General ends in a question nobody answered yet (D-257): a card (a bot form, quick
 * tasks, the setup offer) or a suggestion that's still pending. New suggestions then wait, so
 * prompts never stack; they stay under Needs you, and their pushes still follow the attention rules.
 */
async function openQuestion(db: Database, conversationId: string) {
  const [m] = await db.execute<{ role: string; content: unknown; created_at: string }>(sql`
    select role, content, created_at from public.messages where conversation_id = ${conversationId}::uuid
    order by created_at desc limit 1`);
  if (m?.role !== "assistant") return false;
  if (Date.now() - new Date(m.created_at).getTime() > OPEN_FOR_MS) return false;
  const parts = contentKeys.open(m.content);
  if (!Array.isArray(parts)) return false;
  if (parts.some((p) => p && typeof p === "object" && p.type === "ui")) return true;
  const ids = parts.flatMap((p) =>
    p && typeof p === "object"
      ? p.type === "suggestion" && typeof p.suggestion_id === "string"
        ? [p.suggestion_id as string]
        : p.type === "suggestions" && Array.isArray(p.items)
          ? (p.items as Array<{ suggestion_id?: unknown }>).flatMap((i) =>
              typeof i?.suggestion_id === "string" ? [i.suggestion_id] : [],
            )
          : []
      : [],
  );
  if (!ids.length) return false;
  const [r] = await db.execute<{ open: boolean }>(sql`
    select exists (select 1 from public.suggestions where status = 'pending' and expires_at > now()
      and id in (select jsonb_array_elements_text(${JSON.stringify(ids)}::jsonb)::uuid)) as open`);
  return r?.open === true;
}

/** A suggestion as a card item: its title, and the bot's own one line (else the start of the body). */
const item = (s: Unposted) => ({
  suggestion_id: s.id,
  title: s.title,
  body: (s.push_text?.trim() || s.body_md.trim()).slice(0, 400),
});

/**
 * One message in General for a person's waiting suggestions (D-257): one card, or one list card
 * with a Do it for each. No separate line above it.
 */
async function postBatch(db: Database, batch: Unposted[], afterRun?: string) {
  const first = batch[0] as Unposted;
  const conversationId = await mainConversation(db, first.org_id, first.bot_id, first.user_id);
  if (await openQuestion(db, conversationId)) return null;
  const id = await postFromBot(db, {
    orgId: first.org_id,
    conversationId,
    botId: first.bot_id,
    afterRun,
    parts:
      batch.length === 1
        ? [{ type: "suggestion", ...item(first) }]
        : [{ type: "suggestions", items: batch.map(item) }],
  });
  if (id)
    await db.execute(sql`
      update public.suggestions set message_id = ${id}::uuid
      where message_id is null and id in (select jsonb_array_elements_text(${JSON.stringify(batch.map((b) => b.id))}::jsonb)::uuid)`);
  return id;
}

/**
 * Posts pending suggestions that aren't in General yet: those of one run (right after it ends), or
 * every one whose run has ended and whose time has come (the minute sweep, which also posts what
 * waited behind an open question). A run's own suggestions wait for it to finish, so the card comes
 * after what it said. Returns how many suggestions were posted.
 */
export async function postSuggestions(db: Database, opts: { runId?: string; limit?: number } = {}) {
  const rows = await db.execute<Unposted>(sql`
    select s.id, s.org_id, s.bot_id, s.user_id, s.title, s.body_md, s.push_text
    from public.suggestions s
    left join public.runs r on r.id = s.run_id
    where s.status = 'pending' and s.message_id is null and s.post_card and s.expires_at > now()
      and (s.notify_at is null or s.notify_at <= now())
      and ${opts.runId ? sql`s.run_id = ${opts.runId}::uuid` : sql`(r.id is null or r.status in ('completed', 'failed', 'cancelled'))`}
    order by s.created_at
    limit ${opts.limit ?? 100}`);
  const groups = new Map<string, Unposted[]>();
  for (const s of rows) {
    const key = `${s.bot_id}:${s.user_id}`;
    groups.set(key, [...(groups.get(key) ?? []), s]);
  }
  let posted = 0;
  for (const [key, group] of groups) {
    // One poster at a time per person and bot (the minute sweep and an answered card can meet):
    // the batch is read again under the lock, so a suggestion is never posted twice.
    posted += await db.transaction(async (tx) => {
      await tx.execute(sql`select pg_advisory_xact_lock(hashtextextended(${`general:${key}`}, 0))`);
      const still = await tx.execute<{ id: string }>(sql`
        select id from public.suggestions where message_id is null
          and id in (select jsonb_array_elements_text(${JSON.stringify(group.map((g) => g.id))}::jsonb)::uuid)`);
      const ids = new Set(still.map((r) => r.id));
      const batch = group.filter((g) => ids.has(g.id)).slice(0, BATCH);
      if (!batch.length) return 0;
      return (await postBatch(tx as unknown as Database, batch, opts.runId)) ? batch.length : 0;
    });
  }
  return posted;
}

/** The first sentence or line of a reply, for the one-line result in General. */
export function resultLine(text: string) {
  const flat = text
    .replace(/[*_`#>]/g, "")
    .replace(/\s+/g, " ")
    .trim();
  const first = flat.match(/^(.{1,200}?[.!?])(\s|$)/)?.[1] ?? flat;
  return first.length > 200 ? `${first.slice(0, 199)}…` : first;
}

/**
 * Topics opened for a piece of work post their result back to General: after the run that did the
 * work, and after later runs nobody asked for in the topic (a routine, a watcher). The person's own
 * back-and-forth in a topic stays there.
 */
export async function postTopicResults(
  db: Database,
  opts: { runId?: string; limit?: number } = {},
) {
  const rows = await db.execute<{
    run_id: string;
    org_id: string;
    bot_id: string;
    topic_id: string;
    parent_id: string;
    title: string | null;
    content: unknown;
  }>(sql`
    select r.id as run_id, r.org_id, r.bot_id, c.id as topic_id, c.parent_conversation_id as parent_id, c.title,
      (select m.content from public.messages m where m.run_id = r.id and m.role = 'assistant'
       order by m.created_at desc limit 1) as content
    from public.conversations c
    join public.runs r on r.conversation_id = c.id
    where c.posts_result and c.parent_conversation_id is not null
      and r.status = 'completed' and r.ended_at > now() - interval '1 day'
      and (c.result_run_id is null or r.ended_at > (select ended_at from public.runs where id = c.result_run_id))
      and (r.trigger <> 'chat' or not exists (
        select 1 from public.runs p where p.conversation_id = r.conversation_id and p.created_at < r.created_at))
      ${opts.runId ? sql`and r.id = ${opts.runId}::uuid` : sql``}
    order by r.ended_at
    limit ${opts.limit ?? 50}`);
  let posted = 0;
  for (const r of rows) {
    const reply = partsText(contentKeys.open(r.content));
    const line = resultLine(reply) || "Done.";
    const id = await postFromBot(db, {
      orgId: r.org_id,
      conversationId: r.parent_id,
      botId: r.bot_id,
      afterRun: opts.runId,
      parts: [
        { type: "text", text: line },
        { type: "topic", conversation_id: r.topic_id, title: r.title ?? "" },
      ],
    });
    if (!id) continue;
    await db.execute(
      sql`update public.conversations set result_run_id = ${r.run_id}::uuid where id = ${r.topic_id}::uuid`,
    );
    posted++;
  }
  return posted;
}

function partsText(content: unknown) {
  if (!Array.isArray(content)) return "";
  return content
    .map((p) => (p && typeof p === "object" && "text" in p ? String(p.text ?? "") : ""))
    .join("\n")
    .trim();
}
