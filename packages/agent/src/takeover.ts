/**
 * Control leases and takeover requests (Phase 5). While a person controls a computer's screen,
 * screen tools wait; `computer.request_takeover` asks a person to step in and waits for them.
 * Every wait happens in the run loop (durable in the worker), never inside a tool step.
 */
import type { Database } from "@casama/db";
import { sql } from "drizzle-orm";
import type { EventBus } from "./events.ts";
import type { NotificationService } from "./notifications.ts";

export const TAKEOVER_TOOL = "computer.request_takeover";
export const TAKEOVER_TTL_MS = 24 * 3600 * 1000;

export interface UserLease {
  holderId: string;
  allowShell: boolean;
  expiresAt: string;
}

/** The person controlling this computer right now, if any. */
export async function activeUserLease(db: Database, computerId: string): Promise<UserLease | null> {
  const [row] = await db.execute<{
    holder_id: string;
    allow_shell: boolean;
    expires_at: string;
  }>(sql`
    select holder_id, allow_shell, expires_at from public.computer_leases
    where computer_id = ${computerId}::uuid and holder_type = 'user' and mode = 'control'
      and released_at is null and expires_at > now()
    order by created_at desc limit 1`);
  return row
    ? { holderId: row.holder_id, allowShell: row.allow_shell, expiresAt: String(row.expires_at) }
    : null;
}

type Bus = () => Promise<EventBus>;

/** Marks the run as paused for a person and records it on the timeline. */
export async function pauseForUser(db: Database, runId: string, computerId: string, bus: Bus) {
  await db.execute(sql`update public.runs set status = 'waiting_takeover', waiting_computer_id = ${computerId}::uuid
    where id = ${runId}::uuid and status in ('running', 'waiting_takeover')`);
  await (await bus()).append(runId, "lease.changed", {
    computer_id: computerId,
    holder_type: "user",
    mode: "control",
  });
}

/**
 * Resumes a run paused for a person. Either they handed back (returns their note, if any) or they
 * still have the screen but let the bot keep using shell and file tools (`stillInControl`).
 */
export async function resumeFromUser(
  db: Database,
  runId: string,
  computerId: string,
  bus: Bus,
): Promise<{ note: string | null; stillInControl: boolean }> {
  await db.execute(sql`update public.runs set status = 'running', waiting_computer_id = null
    where id = ${runId}::uuid and status = 'waiting_takeover'`);
  if ((await activeUserLease(db, computerId))?.allowShell) {
    await (await bus()).append(runId, "notice", {
      code: "shell_beside_user",
      message: "Carrying on with the terminal and files while you have the screen.",
    });
    return { note: null, stillInControl: true };
  }
  await (await bus()).append(runId, "lease.changed", {
    computer_id: computerId,
    holder_type: "bot",
    mode: "control",
  });
  const [row] = await db.execute<{ note: string | null }>(sql`
    select note from public.computer_leases where computer_id = ${computerId}::uuid and holder_type = 'user'
    order by created_at desc limit 1`);
  return { note: row?.note ?? null, stillInControl: false };
}

export const handBackMessage = (note: string | null) =>
  `[A person had control of the screen and has handed it back${note ? `. Their note: ${note}` : ""}. The screen may have changed: take a fresh snapshot before acting.]`;

/** Told when a person keeps the screen but lets the bot carry on with shell and file tools. */
export const besideUserMessage =
  "[A person has control of the screen and let you keep using shell and file tools meanwhile. Screen tools (browser, desktop) wait until they hand back, so do the work you can without the screen. Don't use the shell to look at or control the screen or the browser while they have it.]";

/** Creates a takeover request, pauses the run and notifies the bot's owners. */
export async function createTakeover(
  db: Database,
  info: { runId: string; orgId: string; botId: string; botName: string },
  computerId: string,
  reason: string,
  bus: Bus,
  notifications?: NotificationService,
) {
  const [row] = await db.execute<{ id: string }>(sql`
    insert into public.takeover_requests (org_id, bot_id, run_id, computer_id, reason, expires_at)
    values (${info.orgId}::uuid, ${info.botId}::uuid, ${info.runId}::uuid, ${computerId}::uuid, ${reason},
            now() + make_interval(secs => ${TAKEOVER_TTL_MS / 1000}))
    returning id`);
  const id = (row as { id: string }).id;
  await db.execute(sql`update public.runs set status = 'waiting_takeover', waiting_computer_id = ${computerId}::uuid
    where id = ${info.runId}::uuid`);
  await (await bus()).append(info.runId, "takeover.requested", { computer_id: computerId, reason });
  if (notifications) {
    const owners = await db.execute<{ user_id: string }>(sql`
      select distinct m.user_id from public.bots b join public.memberships m on m.org_id = b.org_id
      where b.id = ${info.botId}::uuid and (m.role in ('owner', 'admin') or m.user_id = b.created_by)`);
    await Promise.all(
      owners.map((o) =>
        notifications
          .notify(o.user_id, info.orgId, "takeover", {
            title: `${info.botName} needs your help`,
            body: reason,
            link: `/computer/live?c=${computerId}&takeover=${id}`,
            // Marked read once the takeover is answered (taken, dismissed or expired).
            takeover_id: id,
            bot_id: info.botId,
          })
          .catch(() => {}),
      ),
    );
  }
  return id;
}

/** pending | taken | completed | dismissed | expired (expiring it when past due). */
export async function takeoverState(db: Database, id: string): Promise<string> {
  await db.execute(sql`update public.takeover_requests set status = 'expired', resolved_at = now()
    where id = ${id}::uuid and status in ('pending', 'taken') and expires_at <= now()`);
  // Taken, but the person's control ran out without a hand back (app closed, lease lapsed): done.
  await db.execute(sql`update public.takeover_requests t set status = 'completed', resolved_at = now()
    where t.id = ${id}::uuid and t.status = 'taken' and not exists (
      select 1 from public.computer_leases l
      where l.computer_id = t.computer_id and l.holder_type = 'user' and l.released_at is null and l.expires_at > now())`);
  const [row] = await db.execute<{ status: string; cancel: Date | null }>(sql`
    select t.status, r.cancel_requested_at as cancel from public.takeover_requests t join public.runs r on r.id = t.run_id
    where t.id = ${id}::uuid`);
  if (row?.cancel) return "cancelled";
  return row?.status ?? "expired";
}

/** Ends the wait: resumes the run, records the outcome and returns what the model is told. */
export async function finishTakeover(db: Database, runId: string, id: string, bus: Bus) {
  const [t] = await db.execute<{ status: string; note: string | null; computer_id: string }>(sql`
    select status, note, computer_id from public.takeover_requests where id = ${id}::uuid`);
  const status = t?.status ?? "expired";
  const outcome =
    status === "completed" ? "completed" : status === "dismissed" ? "dismissed" : "expired";
  await db.execute(sql`update public.runs set status = 'running', waiting_computer_id = null
    where id = ${runId}::uuid and status = 'waiting_takeover'`);
  if (t)
    await (await bus()).append(runId, "takeover.resolved", {
      computer_id: t.computer_id,
      outcome,
      note: t.note,
    });
  const note = t?.note ? ` Their note: ${t.note}` : "";
  return outcome === "completed"
    ? `The person finished and handed control back.${note} Take a fresh snapshot before acting.`
    : outcome === "dismissed"
      ? `The person declined to take over.${note} Continue another way or explain what you need.`
      : "Nobody took over in time. Continue another way or explain what you need.";
}
