/**
 * Ticket board work (SPEC: Post-v1 roadmap → Ticket board; D-098). Assigning a ticket to a bot, or
 * a person commenting on a bot's ticket, starts a run in the ticket's thread; when the run ends the
 * ticket moves on (review, done, or blocked) if the bot didn't move it itself.
 */
import type { Database } from "@kasama/db";
import { sql } from "drizzle-orm";
import { contentKeys } from "@kasama/db";

type TicketRow = {
  id: string;
  org_id: string;
  title: string;
  details_md: string;
  status: string;
  priority: string;
  due_at: Date | null;
  assignee_bot_id: string | null;
  conversation_id: string | null;
  review_required: boolean;
  created_by_user_id: string | null;
  assignee_user_id: string | null;
  project_id?: string | null;
};

const FINISHED = new Set(["done"]);

function brief(t: TicketRow) {
  return [
    `You are assigned the ticket "${t.title}" (id ${t.id}).`,
    `Priority: ${t.priority}.${t.due_at ? ` Due: ${new Date(t.due_at).toISOString().slice(0, 10)}.` : ""}`,
    t.details_md ? `\n${t.details_md}\n` : "",
    "Work on it now. Post progress on the ticket with tasks.comment. When you finish, use tasks.update with " +
      (t.review_required
        ? 'status "in_review" and a short result (a person reviews it).'
        : 'status "done" and a short result.') +
      ' If you are stuck, use tasks.update with status "blocked" and say why.',
  ]
    .filter(Boolean)
    .join("\n");
}

/**
 * Starts the assigned bot on a ticket (or on a new comment). Returns the run id, or null when the
 * ticket has no bot or is finished. `startRun` enqueues the run (API or worker).
 */
export async function startTicketWork(
  db: Database,
  opts: { ticketId: string; actorUserId: string | null; comment?: string },
  startRun: (runId: string) => Promise<void>,
): Promise<string | null> {
  const [t] = await db.execute<TicketRow>(sql`
    select id, org_id, title, details_md, status, priority, due_at, assignee_bot_id, conversation_id,
           review_required, created_by_user_id, assignee_user_id, project_id
    from public.tasks where id = ${opts.ticketId}::uuid`);
  if (!t?.assignee_bot_id || FINISHED.has(t.status)) return null;
  const created = await db.transaction(async (tx) => {
    let conversationId = t.conversation_id;
    if (conversationId) {
      const [c] = await tx.execute<{ bot_id: string }>(
        sql`select bot_id from public.conversations where id = ${conversationId}::uuid`,
      );
      if (c?.bot_id !== t.assignee_bot_id) conversationId = null;
    }
    if (!conversationId) {
      const [c] = await tx.execute<{ id: string }>(sql`
        insert into public.conversations (org_id, bot_id, title, created_by)
        values (${t.org_id}::uuid, ${t.assignee_bot_id}::uuid, ${`Ticket: ${t.title}`.slice(0, 200)}, ${opts.actorUserId}::uuid)
        returning id`);
      conversationId = c?.id ?? null;
      await tx.execute(
        sql`update public.tasks set conversation_id = ${conversationId}::uuid where id = ${t.id}::uuid`,
      );
    }
    const [run] = await tx.execute<{ id: string }>(sql`
      insert into public.runs (org_id, bot_id, conversation_id, created_by, trigger, project_id)
      values (${t.org_id}::uuid, ${t.assignee_bot_id}::uuid, ${conversationId}::uuid, ${opts.actorUserId}::uuid, 'task', ${t.project_id ?? null}::uuid)
      returning id`);
    const text = opts.comment
      ? `New comment on the ticket "${t.title}" (id ${t.id}):\n\n${opts.comment}`
      : brief(t);
    await tx.execute(sql`
      insert into public.messages (org_id, conversation_id, role, author_user_id, content, run_id)
      values (${t.org_id}::uuid, ${conversationId}::uuid, 'user', ${opts.actorUserId}::uuid,
              ${contentKeys.sealJson(t.org_id, [{ type: "text", text }])}::jsonb, ${run?.id}::uuid)`);
    await tx.execute(
      sql`update public.conversations set last_message_at = now() where id = ${conversationId}::uuid`,
    );
    return run?.id ?? null;
  });
  if (!created) return null;
  try {
    await startRun(created);
  } catch {
    await db.execute(sql`update public.runs set status = 'failed', ended_at = now(),
      error = ${JSON.stringify({ code: "enqueue_failed", message: "The run could not be started." })}::jsonb
      where id = ${created}::uuid`);
  }
  return created;
}

/** A ticket run started: the ticket is in progress. */
export async function ticketStarted(db: Database, conversationId: string | null, botId: string) {
  if (!conversationId) return;
  await db.execute(sql`
    update public.tasks set status = 'in_progress', updated_at = now()
    where conversation_id = ${conversationId}::uuid and assignee_bot_id = ${botId}::uuid and status = 'todo'`);
}

/** A ticket run ended: move the ticket on if the bot didn't, and tell its owner when it's blocked. */
export async function ticketAfterRun(
  db: Database,
  info: { conversationId: string | null; botId: string; orgId: string },
  outcome: { ok: true; text: string } | { ok: false; message: string },
) {
  if (!info.conversationId) return;
  const [t] = await db.execute<TicketRow>(sql`
    select id, org_id, title, status, review_required, created_by_user_id, assignee_user_id
    from public.tasks where conversation_id = ${info.conversationId}::uuid and assignee_bot_id = ${info.botId}::uuid`);
  if (!t) return;
  if (outcome.ok) {
    if (!["todo", "in_progress"].includes(t.status)) return;
    const text = outcome.text.trim().slice(0, 4000) || "Finished.";
    const next = t.review_required ? "in_review" : "done";
    await db.execute(sql`
      update public.tasks set status = ${next}, result_md = ${contentKeys.seal(t.org_id, text)}, updated_at = now() where id = ${t.id}::uuid`);
    await addBotComment(db, t, info.botId, text);
    return;
  }
  if (t.status === "done") return;
  await db.execute(
    sql`update public.tasks set status = 'blocked', updated_at = now() where id = ${t.id}::uuid`,
  );
  await addBotComment(db, t, info.botId, `Blocked: ${outcome.message}`.slice(0, 4000));
  const owner = t.assignee_user_id ?? t.created_by_user_id;
  if (owner)
    await db.execute(sql`
      insert into public.notifications (user_id, org_id, kind, payload)
      values (${owner}::uuid, ${t.org_id}::uuid, 'ticket', ${JSON.stringify({
        title: `Blocked: ${t.title}`.slice(0, 200),
        body: outcome.message.slice(0, 300),
        link: "/tasks",
        task_id: t.id,
      })}::jsonb)`);
}

async function addBotComment(
  db: Database,
  t: { id: string; org_id: string },
  botId: string,
  body: string,
) {
  await db.execute(sql`
    insert into public.task_comments (org_id, task_id, author_type, author_bot_id, body_md)
    values (${t.org_id}::uuid, ${t.id}::uuid, 'bot', ${botId}::uuid, ${contentKeys.seal(t.org_id, body)})`);
}
