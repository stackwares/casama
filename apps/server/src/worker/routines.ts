import { createHmac, timingSafeEqual } from "node:crypto";
import { checkinCapReached, describeEvent, scanContext, takeHeldForBrief, wrapUntrusted } from "@kasama/agent";
import type { Database } from "@kasama/db";
import { nextRunAt } from "@kasama/domain";
import { sql } from "drizzle-orm";
import { contentKeys } from "@kasama/db";

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
  [key: string]: unknown;
}

type Tx = Parameters<Parameters<Database["transaction"]>[0]>[0];

/** Creates the run for a routine: its conversation (made on first use), the instructions as the message. */
export async function createRoutineRun(
  tx: Tx | Database,
  r: RoutineRow,
  trigger: "routine" | "webhook" | "calendar" | "message" | "device",
  eventText?: string,
) {
  // Check-in scans (D-114) keep no conversation: a quiet scan writes nothing. Their instructions
  // travel as the run's task, with what was already suggested.
  if (r.kind === "scan") {
    const task = `${r.instructions_md}${await scanContext(tx as Database, r.bot_id)}`;
    const [run] = await tx.execute<{ id: string }>(sql`
      insert into public.runs (org_id, bot_id, created_by, trigger, routine_id, budget)
      values (${r.org_id}::uuid, ${r.bot_id}::uuid, ${r.created_by}::uuid, ${trigger}, ${r.id}::uuid, ${JSON.stringify({ task })}::jsonb)
      returning id`);
    await tx.execute(
      sql`update public.routines set last_run_id = ${run?.id}::uuid, last_run_at = now() where id = ${r.id}::uuid`,
    );
    return run?.id as string;
  }
  // Attention rules (D-153): a brief carries what waited while the person was busy.
  if (r.kind === "brief" && r.created_by) {
    const held = await takeHeldForBrief(tx as Database, r.created_by);
    if (held) eventText = eventText ? `${eventText}\n\n${held}` : held;
  }
  let conversationId = r.conversation_id;
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
    values (${r.org_id}::uuid, ${conversationId}::uuid, 'user', ${r.created_by}::uuid, ${contentKeys.sealJson(r.org_id, [{ type: "text", text }])}::jsonb, ${runId}::uuid)`);
  await tx.execute(
    sql`update public.routines set last_run_id = ${runId}::uuid, last_run_at = now() where id = ${r.id}::uuid`,
  );
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
      select * from public.routines
      where enabled and next_run_at <= ${now.toISOString()}::timestamptz
        and (schedule_cron is not null or trigger ->> 'type' = 'once')
      order by next_run_at limit ${limit}
      for update skip locked`);
    const runIds: string[] = [];
    for (const r of due) {
      // Check-ins over today's cap skip this time (the schedule still moves on).
      const capped =
        (r.kind === "brief" || r.kind === "scan") &&
        (await checkinCapReached(tx as Database, r.bot_id));
      // A brief that already ran this morning on wake-up (D-151) skips its scheduled time.
      const briefed = r.kind === "brief" && r.last_run_at && now.getTime() - new Date(r.last_run_at as string).getTime() < 14 * 3600_000;
      if (!capped && !briefed) runIds.push(await createRoutineRun(tx, r, "routine"));
      if (r.trigger?.type === "once") {
        // A one-time routine runs once and switches itself off.
        await tx.execute(
          sql`update public.routines set enabled = false, next_run_at = null where id = ${r.id}::uuid`,
        );
        continue;
      }
      const next = nextRunAt(r.schedule_cron as string, r.timezone, now);
      await tx.execute(
        sql`update public.routines set next_run_at = ${next.toISOString()}::timestamptz where id = ${r.id}::uuid`,
      );
    }
    return runIds;
  });
}

/** Chat apps (D-134): a routine started by an inbound email or chat message. */
export async function startRoutineForMessage(db: Database, routineId: string, eventText: string): Promise<string | null> {
  const [r] = await db.execute<RoutineRow>(sql`select * from public.routines where id = ${routineId}::uuid and enabled`);
  if (!r) return null;
  return createRoutineRun(db, r, "message", eventText);
}

/** Calendar triggers (D-132): routine runs for events whose time has come, with the event in context. */
export async function fireDueCalendarRuns(db: Database, now = new Date()): Promise<string[]> {
  return db.transaction(async (tx) => {
    const due = await tx.execute<{ routine_id: string; event_id: string; event: import("@kasama/agent").CalEvent }>(sql`
      select f.routine_id, f.event_id, f.event from public.calendar_fires f join public.routines r on r.id = f.routine_id
      where f.fired_at is null and r.enabled and f.fire_at <= ${now.toISOString()}::timestamptz
      order by f.fire_at limit 50 for update of f skip locked`);
    const runIds: string[] = [];
    for (const f of due) {
      const [r] = await tx.execute<RoutineRow>(sql`select * from public.routines where id = ${f.routine_id}::uuid`);
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
  return createRoutineRun(db, r, "routine");
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
  if (!r?.enabled) return { ok: false, reason: "routine_not_found" };
  const expected = kind === "github" ? "github" : "webhook";
  if (r.trigger?.type !== expected) return { ok: false, reason: "wrong_trigger" };
  if (!r.secret) return { ok: false, reason: "no_secret" };
  const signature =
    kind === "github" ? headers["x-hub-signature-256"] : headers["x-kasama-signature"];
  if (!signature || !safeEqual(signature, signBody(r.secret, body)))
    return { ok: false, reason: "bad_signature" };
  const event = kind === "github" ? headers["x-github-event"] : headers["x-kasama-event"];
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
