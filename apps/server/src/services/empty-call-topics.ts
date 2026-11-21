/**
 * Empty "Voice call" topics (D-478): a call that never got a word in (the microphone refused, the
 * connection failed) left a new topic with nothing in it, one per attempt. A topic a call made for
 * itself goes again when the call ends and the topic still has no messages, no runs and no other
 * call. A call placed in an existing chat never removes that chat. The call's billing rows don't
 * point at the topic, so they stay.
 */
import type { Database } from "@casama/db";
import { sql } from "drizzle-orm";

/** The topic itself is unused: no message, no run, no call still open in it. */
const unused = sql`
  not exists (select 1 from public.messages m where m.conversation_id = c.id)
  and not exists (select 1 from public.runs r where r.conversation_id = c.id)
  and not exists (select 1 from public.live_calls o where o.conversation_id = c.id and o.ended_at is null)`;

/** Removes a topic made for a call that couldn't start, if nothing has used it. */
export async function dropUnusedCallTopic(db: Database, conversationId: string) {
  await db.execute(sql`
    delete from public.conversations c
    where c.id = ${conversationId}::uuid and c.title = 'Voice call' and ${unused}`);
}

/**
 * Removes the topics of ended calls that the call made for itself (created with the call) and that
 * nothing used. [liveCallId]: just that call's; otherwise calls that ended in the last day (the
 * worker's sweep, for calls whose app went quiet). Returns how many went.
 */
export async function dropEmptyCallTopics(db: Database, liveCallId?: string): Promise<number> {
  const rows = await db.execute<{ id: string }>(sql`
    delete from public.conversations c
    using public.live_calls l
    where l.conversation_id = c.id and l.ended_at is not null
      and ${liveCallId ? sql`l.id = ${liveCallId}::uuid` : sql`l.ended_at > now() - interval '1 day'`}
      and c.title = 'Voice call'
      and c.created_at between l.started_at - interval '1 minute' and l.started_at + interval '1 minute'
      and ${unused}
    returning c.id`);
  return rows.length;
}
