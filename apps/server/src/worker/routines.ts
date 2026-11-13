import { createHmac, timingSafeEqual } from "node:crypto";
import {
  checkinAllowed,
  checkinCapReached,
  describeEvent,
  SCAN_INSTRUCTIONS,
  scanContext,
  scanTask,
  takeHeldForBrief,
  takeScanRequest,
  wrapUntrusted,
} from "@casama/agent";
import type { Database } from "@casama/db";
import { contentKeys } from "@casama/db";
import { nextRunAt } from "@casama/domain";
import { sql } from "drizzle-orm";

interface RoutineRow {
  id: string;
  org_id: string;
  bot_id: string;
  conversation_id: string | null;
  created_by: string | null;
  name: string;
  instructions_md: string;
  schedule_cron: string | null;
  timezone: string;
  trigger: { type?: string; vault_secret_id?: string; events?: string[] };
  ends_at?: string | null;
  max_runs?: number | null;
  [key: string]: unknown;
}

/** A routine that hasn't passed its end time (D-262). For selects on `public.routines` as `rt`. */
const notEnded = sql`(rt.ends_at is null or rt.ends_at > now())`;

/**
 * Records a run on its routine. A run it started on its own counts toward max_runs (D-262), and
 * the run that reaches it switches the routine off; manual "run now" doesn't count.
 */
async function markRun(tx: Tx | Database, routineId: string, runId: string, counts: boolean) {
  await tx.execute(sql`
    update public.routines set last_run_id = ${runId}::uuid, last_run_at = now(),
      run_count = run_count + ${counts ? 1 : 0},
      enabled = enabled and not (${counts} and max_runs is not null and run_count + 1 >= max_runs),
      next_run_at = case when ${counts} and max_runs is not null and run_count + 1 >= max_runs
        then null else next_run_at end
    where id = ${routineId}::uuid`);
}

/** Switches off routines past their end time (D-262), event routines included. Every minute. */
export async function expireRoutines(db: Database, now = new Date()) {
  const rows = await db.execute<{ id: string }>(sql`
    update public.routines set enabled = false, next_run_at = null
    where enabled and ends_at is not null and ends_at <= ${now.toISOString()}::timestamptz
    returning id`);
  return rows.length;
}

type Tx = Parameters<Parameters<Database["transaction"]>[0]>[0];

/** Creates the run for a routine: its conversation (made on first use), the instructions as the message. */
export async function createRoutineRun(
  tx: Tx | Database,
  r: RoutineRow,
  trigger: "routine" | "webhook" | "calendar" | "message" | "device",
  eventText?: string,
  counts = true,
) {
  // Check-in scans (D-114) keep no conversation: a quiet scan writes nothing. Their instructions
  // travel as the run's task, with what was already suggested.
  if (r.kind === "scan") {
    // Proactive bots (D-247): why this scan runs now (setup, a new app, an app event, or its
    // schedule), and today's wording for scans made with the original instructions.
    const request = await takeScanRequest(tx as Database, r.bot_id);
    const reason = request?.reason ?? null;
    const instructions = r.instructions_md.startsWith("Check-in scan.")
      ? SCAN_INSTRUCTIONS
      : r.instructions_md;
    const task = scanTask(
      instructions,
      reason,
      await scanContext(tx as Database, r.bot_id, reason),
      request?.note ? wrapUntrusted("app event", request.note) : null,
    );
    const [run] = await tx.execute<{ id: string }>(sql`
      insert into public.runs (org_id, bot_id, created_by, trigger, routine_id, budget)
      values (${r.org_id}::uuid, ${r.bot_id}::uuid, ${r.created_by}::uuid, ${trigger}, ${r.id}::uuid, ${JSON.stringify({ task, ...(reason ? { scan_reason: reason } : {}) })}::jsonb)
      returning id`);
    await markRun(tx, r.id, run?.id as string, counts);
    return run?.id as string;
  }
  // Attention rules (D-153): a brief carries what waited while the person was busy.
  if (r.kind === "brief" && r.created_by) {
    const held = await takeHeldForBrief(tx as Database, r.created_by, r.org_id);
    if (held) eventText = eventText ? `${eventText}\n\n${held}` : held;
  }
  // Briefs always go to the person's General (D-253); other routines post where they were asked
  // for (D-155), else General too. Only a routine with nobody behind it gets a chat of its own.
  let conversationId = r.kind === "brief" ? null : r.conversation_id;
  if (!conversationId && r.created_by) {
    const [main] = await tx.execute<{ id: string }>(
      sql`select public.main_conversation(${r.org_id}::uuid, ${r.bot_id}::uuid, ${r.created_by}::uuid) as id`,
    );
    conversationId = main?.id ?? null;
    if (conversationId && r.kind !== "brief")
      await tx.execute(
        sql`update public.routines set conversation_id = ${conversationId}::uuid where id = ${r.id}::uuid`,
      );
  }
  if (!conversationId) {
    const [conv] = await tx.execute<{ id: string }>(sql`
      insert into public.conversations (org_id, bot_id, title, created_by) values (${r.org_id}::uuid, ${r.bot_id}::uuid, ${r.name}, ${r.created_by}::uuid)
      returning id`);
    conversationId = conv?.id ?? null;
    await tx.execute(
      sql`update public.routines set conversation_id = ${conversationId}::uuid where id = ${r.id}::uuid`,
    );
  }
  const [run] = await tx.execute<{ id: string }>(sql`
    insert into public.runs (org_id, bot_id, conversation_id, created_by, trigger, routine_id)
    values (${r.org_id}::uuid, ${r.bot_id}::uuid, ${conversationId}::uuid, ${r.created_by}::uuid, ${trigger}, ${r.id}::uuid)
    returning id`);
  const runId = run?.id as string;
  const text = eventText
    ? `${r.instructions_md}\n\nThe event that triggered this run:\n${wrapUntrusted(trigger === "calendar" ? "calendar" : trigger === "message" ? "message" : trigger === "device" ? "device event" : trigger === "routine" ? "held messages" : "webhook", eventText)}`
    : r.instructions_md;
  await tx.execute(sql`
    insert into public.messages (org_id, conversation_id, role, author_user_id, content, run_id)
    values (${r.org_id}::uuid, ${conversationId}::uuid, 'user', ${r.created_by}::uuid, ${contentKeys.sealJson(r.org_id, [{ type: "text", text, routine: { id: r.id, name: r.name } }])}::jsonb, ${runId}::uuid)`);
  await markRun(tx, r.id, runId, counts);
  return runId;
}

/**
 * Claims routines that are due (FOR UPDATE SKIP LOCKED, so several workers never double-run one),
 * creates their runs and moves next_run_at forward in each routine's timezone.
 */
export async function claimDueRoutines(
  db: Database,
  now = new Date(),
  limit = 50,
): Promise<string[]> {
  return db.transaction(async (tx) => {
    const due = await tx.execute<RoutineRow>(sql`
      select * from public.routines rt
      where enabled and next_run_at <= ${now.toISOString()}::timestamptz
        and (ends_at is null or ends_at > ${now.toISOString()}::timestamptz)
        and (schedule_cron is not null or trigger ->> 'type' = 'once')
      order by next_run_at limit ${limit}
      for update skip locked`);
    const runIds: string[] = [];
    for (const r of due) {
      // One bad routine (an invalid cron or timezone, a failing brief) doesn't stop the others:
      // each runs in its own savepoint, and a failure still moves its next run on (audit 2026-11).
      try {
        // The run id counts only once its savepoint has committed.
        const made = await tx.transaction(async (tx) => {
          let made: string | null = null;
          // Check-ins over today's cap skip this time (the schedule still moves on).
          // Bots past the plan's number that check in, and scheduled scans more often than its
          // floor, skip too (D-247).
          const capped =
            (r.kind === "brief" || r.kind === "scan") &&
            ((await checkinCapReached(tx as Database, r.bot_id)) ||
              !(await checkinAllowed(tx as Database, r, now, {
                eventsCoverMail: !!process.env.COMPOSIO_WEBHOOK_SECRET,
              })));
          // A brief that already ran this morning on wake-up (D-151) skips its scheduled time.
          // Only a wake-up brief counts: a brief scheduled twice a day keeps both runs.
          let briefed = false;
          if (
            r.kind === "brief" &&
            r.last_run_at &&
            now.getTime() - new Date(r.last_run_at as string).getTime() < 14 * 3600_000 &&
            r.last_run_id
          ) {
            const [last] = await tx.execute<{ trigger: string }>(
              sql`select trigger from public.runs where id = ${r.last_run_id as string}::uuid`,
            );
            briefed = last?.trigger === "device";
          }
          if (!capped && !briefed) made = await createRoutineRun(tx, r, "routine");
          if (r.trigger?.type === "once") {
            // A one-time routine runs once and switches itself off.
            await tx.execute(
              sql`update public.routines set enabled = false, next_run_at = null where id = ${r.id}::uuid`,
            );
            return made;
          }
          // A next run past the end time (D-262) ends the routine instead. markRun may have
          // switched it off already (its last allowed run).
          const next = nextRunAt(r.schedule_cron as string, r.timezone, now);
          await tx.execute(sql`
            update public.routines set
              enabled = enabled and (ends_at is null or ${next.toISOString()}::timestamptz <= ends_at),
              next_run_at = case when enabled and (ends_at is null or ${next.toISOString()}::timestamptz <= ends_at)
                then ${next.toISOString()}::timestamptz else null end
            where id = ${r.id}::uuid`);
          return made;
        });
        if (made) runIds.push(made);
      } catch (err) {
        console.error(
          JSON.stringify({
            msg: "routine claim failed",
            routine_id: r.id,
            error: (err as Error).message,
          }),
        );
        const next = (() => {
          try {
            return r.schedule_cron ? nextRunAt(r.schedule_cron, r.timezone, now) : null;
          } catch {
            return null;
          }
        })();
        await tx.execute(
          next
            ? sql`update public.routines set next_run_at = ${next.toISOString()}::timestamptz where id = ${r.id}::uuid`
            : sql`update public.routines set enabled = false, next_run_at = null where id = ${r.id}::uuid`,
        );
      }
    }
    return runIds;
  });
}

/**
 * Routines whose timezone moved with their person (D-250, profiles_follow_timezone): their next
 * run is recomputed in the new zone. Every minute, from the worker.
 */
export async function retimeRoutines(db: Database, now = new Date(), limit = 200) {
  return db.transaction(async (tx) => {
    const rows = await tx.execute<{ id: string; schedule_cron: string; timezone: string }>(sql`
      select id, schedule_cron, timezone from public.routines
      where retime_pending order by id limit ${limit} for update skip locked`);
    for (const r of rows) {
      let next: string | null = null;
      try {
        next = nextRunAt(r.schedule_cron, r.timezone, now).toISOString();
      } catch {
        next = null; // A bad cron keeps its old next run; claiming handles it as before.
      }
      await tx.execute(
        next
          ? sql`update public.routines set next_run_at = ${next}::timestamptz, retime_pending = false where id = ${r.id}::uuid`
          : sql`update public.routines set retime_pending = false where id = ${r.id}::uuid`,
      );
    }
    return rows.length;
  });
}

/** Chat apps (D-134): a routine started by an inbound email or chat message. */
export async function startRoutineForMessage(
  db: Database,
  routineId: string,
  eventText: string,
): Promise<string | null> {
  const [r] = await db.execute<RoutineRow>(
    sql`select * from public.routines rt where id = ${routineId}::uuid and enabled and ${notEnded}`,
  );
  if (!r) return null;
  return createRoutineRun(db, r, "message", eventText);
}

/** Calendar triggers (D-132): routine runs for events whose time has come, with the event in context. */
export async function fireDueCalendarRuns(db: Database, now = new Date()): Promise<string[]> {
  return db.transaction(async (tx) => {
    const due = await tx.execute<{
      routine_id: string;
      event_id: string;
      event: import("@casama/agent").CalEvent;
    }>(sql`
      select f.routine_id, f.event_id, f.event from public.calendar_fires f join public.routines r on r.id = f.routine_id
      where f.fired_at is null and r.enabled and (r.ends_at is null or r.ends_at > now()) and f.fire_at <= ${now.toISOString()}::timestamptz
        and f.fire_at > ${new Date(now.getTime() - 10 * 60_000).toISOString()}::timestamptz
      order by f.fire_at limit 50 for update of f skip locked`);
    const runIds: string[] = [];
    for (const f of due) {
      const [r] = await tx.execute<RoutineRow>(
        sql`select * from public.routines where id = ${f.routine_id}::uuid`,
      );
      if (!r) continue;
      const runId = await createRoutineRun(tx, r, "calendar", describeEvent(f.event));
      runIds.push(runId);
      await tx.execute(sql`
        update public.calendar_fires set fired_at = now(), run_id = ${runId}::uuid where routine_id = ${f.routine_id}::uuid and event_id = ${f.event_id}`);
    }
    return runIds;
  });
}

/** Manual "run now". */
export async function runRoutineNow(db: Database, routineId: string) {
  const [r] = await db.execute<RoutineRow>(
    sql`select * from public.routines where id = ${routineId}::uuid`,
  );
  if (!r) throw new Error("routine_not_found");
  return createRoutineRun(db, r, "routine", undefined, false);
}

const safeEqual = (a: string, b: string) => {
  const x = Buffer.from(a);
  const y = Buffer.from(b);
  return x.length === y.length && timingSafeEqual(x, y);
};

export const signBody = (secret: string, body: string) =>
  `sha256=${createHmac("sha256", secret).update(body).digest("hex")}`;

/**
 * A GitHub or custom webhook for a routine: verifies the HMAC signature with the routine's secret
 * (in Vault, so this runs in the worker) and starts a run with the event as untrusted context.
 */
export async function handleRoutineWebhook(
  db: Database,
  routineId: string,
  kind: "github" | "custom",
  body: string,
  headers: Record<string, string>,
): Promise<{ ok: boolean; reason?: string; runId?: string }> {
  const [r] = await db.execute<RoutineRow & { secret: string | null }>(sql`
    select rt.*, v.decrypted_secret as secret from public.routines rt
    left join vault.decrypted_secrets v on v.id = (rt.trigger ->> 'vault_secret_id')::uuid
    where rt.id = ${routineId}::uuid`);
  if (!r?.enabled || (r.ends_at && new Date(r.ends_at).getTime() <= Date.now()))
    return { ok: false, reason: "routine_not_found" };
  const expected = kind === "github" ? "github" : "webhook";
  if (r.trigger?.type !== expected) return { ok: false, reason: "wrong_trigger" };
  if (!r.secret) return { ok: false, reason: "no_secret" };
  const signature =
    kind === "github" ? headers["x-hub-signature-256"] : headers["x-casama-signature"];
  if (!signature || !safeEqual(signature, signBody(r.secret, body)))
    return { ok: false, reason: "bad_signature" };
  const event = kind === "github" ? headers["x-github-event"] : headers["x-casama-event"];
  if (r.trigger.events?.length && (!event || !r.trigger.events.includes(event)))
    return { ok: false, reason: "event_ignored" };
  const runId = await createRoutineRun(
    db,
    r,
    "webhook",
    `${event ? `Event: ${event}\n` : ""}${body.slice(0, 50_000)}`,
  );
  return { ok: true, runId };
}
