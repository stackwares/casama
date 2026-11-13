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

/** The suggestion as the bot's message in General: its line, then a card with Do it / Not now. */
async function postSuggestion(db: Database, s: Unposted, afterRun?: string) {
  const conversationId = await mainConversation(db, s.org_id, s.bot_id, s.user_id);
  const line = s.push_text?.trim() || s.title;
  const id = await postFromBot(db, {
    orgId: s.org_id,
    conversationId,
    botId: s.bot_id,
    afterRun,
    parts: [
      { type: "text", text: line },
      {
        type: "suggestion",
        suggestion_id: s.id,
        title: s.title,
        ...(s.body_md ? { body: s.body_md.slice(0, 2000) } : {}),
      },
    ],
  });
  if (id)
    await db.execute(
      sql`update public.suggestions set message_id = ${id}::uuid where id = ${s.id}::uuid and message_id is null`,
    );
  return id;
}

/**
 * Posts pending suggestions that aren't in General yet: those of one run (right after it ends), or
 * every one whose run has ended and whose time has come (the minute sweep). A run's own
 * suggestions wait for it to finish, so the cards come after what it said.
 */
export async function postSuggestions(db: Database, opts: { runId?: string; limit?: number } = {}) {
  const rows = await db.execute<Unposted>(sql`
    select s.id, s.org_id, s.bot_id, s.user_id, s.title, s.body_md, s.push_text
    from public.suggestions s
    left join public.runs r on r.id = s.run_id
    where s.status = 'pending' and s.message_id is null and s.expires_at > now()
      and (s.notify_at is null or s.notify_at <= now())
      and ${opts.runId ? sql`s.run_id = ${opts.runId}::uuid` : sql`(r.id is null or r.status in ('completed', 'failed', 'cancelled'))`}
    order by s.created_at
    limit ${opts.limit ?? 100}`);
  let posted = 0;
  for (const s of rows) if (await postSuggestion(db, s, opts.runId)) posted++;
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
    from public.runs r
    join public.conversations c on c.id = r.conversation_id
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
