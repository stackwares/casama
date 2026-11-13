/**
 * Check-ins (SPEC: Post-v1 roadmap → Check-ins; D-114). Off by default per bot. When on, a morning
 * brief and a scan every few hours run as routines (kind brief and scan) on the bot's cheaper
 * model, within a daily cap. Scans leave suggestions; a scan that finds nothing writes nothing and
 * sends nothing.
 */
import type { Database } from "@casama/db";
import { isValidTimezone, nextRunAt, type QuietHours, quietUntil } from "@casama/domain";
import { sql } from "drizzle-orm";
import { z } from "zod";
import { actingUserOf } from "./acting.ts";
import { track } from "./analytics.ts";
import { deviceDataOfRun } from "./attention.ts";
import type { NotificationService } from "./notifications.ts";
import { ToolError, type ToolRegistry } from "./tools/registry.ts";

export const BRIEF_INSTRUCTIONS = [
  "Write my morning brief for today. Check what you can reach: calendar and email accounts you're connected to, tickets on the board assigned to you or me, active projects, and anything you're watching.",
  "Cover, briefly: today's meetings (time, title, who), emails that need a reply from me, tickets due or blocked, and projects that need a decision. Skip sections with nothing in them.",
  "Keep it to one screen. Don't take any actions; suggest them instead with suggestions.add when something clearly needs doing.",
].join("\n");

export const SCAN_INSTRUCTIONS = [
  "Check-in scan. Look over what you can reach (connected accounts, calendar, email, tickets, projects, things you're watching) for anything new since your last scan that I'd want help with. Think ahead: what's coming up in the next couple of days, and what would make it go smoothly?",
  "Group things that belong together (a trip, an event, a deadline and its prep) into one suggestion instead of several. When a plan has parts spread across apps (tickets, rides, stays, flights), you can offer to pull them into one shareable Page (pages.publish).",
  "For each item, call suggestions.add with a short title, why it matters, the action you'd take (a tool and its arguments) when there is one, the sources, its urgency (urgent only if it can't wait for my next look), and push_text: one short first-person line, the way you'd text a friend, ending in a question when you're offering to do something (\"Want me to book a ride to the show at 7?\"). When an offer only makes sense close to a time (leaving for the airport, booking the ride an hour before the show), set notify_at to that time.",
  "Keep the look light: recent mail (about 10 messages, newest first, without full bodies) and the next two days of calendar. Open a message only when it matters.",
  "Don't repeat anything already suggested or dismissed (listed below). Don't take actions yourself. If there's nothing new, reply with just NOTHING_NEW.",
].join("\n");
/** Added to the first scan after setup, which ends in one summary push instead of one per suggestion. */
export const SETUP_SCAN_INSTRUCTIONS = [
  "This is your first look since I set you up. Look across everything you can reach for the next few days and add up to 5 suggestions; their pushes are held, and I get one summary instead.",
  'Then reply with only that summary: one sentence that starts with "You\'re all set.", says how many things you found and names the best one, for example "You\'re all set. Found 3 things to start on, like booking a ride to the concert tomorrow night." If you found nothing, reply with just NOTHING_NEW.',
].join("\n");
const REASON_NOTES: Record<string, string> = {
  connection: "An app was just connected. Start with what it shows.",
  event:
    "Something just changed in a connected app (a new email or a calendar change). Look at what's new first.",
};
/** The text of a scan run's task: the instructions, why it runs now, and what not to repeat. */
export function scanTask(
  instructions: string,
  reason: string | null,
  context: string,
  note: string | null = null,
) {
  const extra =
    reason === "setup"
      ? `\n\n${SETUP_SCAN_INSTRUCTIONS}`
      : reason && REASON_NOTES[reason]
        ? `\n\n${REASON_NOTES[reason]}`
        : "";
  // What the app reported (sender and subject, event title and time), so the scan starts there.
  const what = note ? `\nWhat changed:\n${note}` : "";
  return `${instructions}${extra}${what}${context}`;
}

/**
 * Check-in runs (D-247 costs): they read and suggest, nothing else. The first scans on prod read
 * 38k–192k tokens over a dozen turns (lazy tool loading, listing connections and routines) and
 * stopped on approvals nobody was there to give, so check-ins get a short list of tools, a few
 * steps, capped app output, and never wait for an approval.
 */
export const isCheckinKind = (kind: string | null | undefined) =>
  kind === "brief" || kind === "scan";
export const CHECKIN_MAX_STEPS = 8;
export const CHECKIN_TOOL_OUTPUT_CHARS = 8000;
export const CHECKIN_APPROVAL_NOTE =
  "Check-ins don't run actions that need approval. Offer it instead: call suggestions.add with this tool and its arguments as the action.";
const CHECKIN_TOOLS = new Set([
  "suggestions.add",
  "memory.search",
  "tasks.list",
  "device.read",
  "projects.status",
]);
/** The reads a check-in needs from apps with many tools; other apps offer all their reads. */
const CHECKIN_APP_READS: Record<string, string[]> = {
  gmail: [
    "gmail_fetch_emails",
    "gmail_fetch_message_by_message_id",
    "gmail_fetch_message_by_thread_id",
    "gmail_list_threads",
  ],
  googlecalendar: ["googlecalendar_events_list", "googlecalendar_find_event"],
};

/** Whether a check-in run offers this tool: no computer, only reads and suggestions.add. */
export function checkinToolAllowed(def: {
  name: string;
  risk?: string;
  requires?: { computer?: boolean };
}) {
  if (def.requires?.computer) return false;
  if (CHECKIN_TOOLS.has(def.name)) return true;
  const m = /^(?:mcp|openapi|composio|pipedream|app)\.[^.]+\.(.+)$/.exec(def.name);
  if (!m || def.risk !== "low") return false;
  const tool = m[1] as string;
  const curated = CHECKIN_APP_READS[tool.split("_")[0] as string];
  return curated ? curated.includes(tool) : true;
}
export const NOTHING_NEW = "NOTHING_NEW";

export interface CheckinSettings {
  enabled: boolean;
  briefTime: string;
  scanEveryHours: number;
  dailyCapUsd: number;
}

/** Saves a bot's check-in settings and keeps its brief and scan routines in step. */
export async function applyCheckins(
  db: Database,
  a: { orgId: string; botId: string; userId: string } & CheckinSettings,
) {
  const [tz] = await db.execute<{ timezone: string | null }>(
    sql`select timezone from public.profiles where user_id = ${a.userId}::uuid`,
  );
  const zone = tz?.timezone && isValidTimezone(tz.timezone) ? tz.timezone : "UTC";
  const [hh, mm] = a.briefTime.split(":").map(Number);
  const briefCron = `${mm} ${hh} * * *`;
  const scanCron = `${(mm as number) % 60} */${a.scanEveryHours} * * *`;
  await db.transaction(async (tx) => {
    await tx.execute(sql`
      insert into public.bot_checkins (bot_id, org_id, user_id, enabled, brief_time, scan_every_hours, daily_cap_usd, updated_at)
      values (${a.botId}::uuid, ${a.orgId}::uuid, ${a.userId}::uuid, ${a.enabled}, ${a.briefTime}, ${a.scanEveryHours}, ${a.dailyCapUsd}, now())
      on conflict (bot_id) do update set user_id = excluded.user_id, enabled = excluded.enabled, brief_time = excluded.brief_time,
        scan_every_hours = excluded.scan_every_hours, daily_cap_usd = excluded.daily_cap_usd, updated_at = now()`);
    for (const [kind, name, cron, text, notify] of [
      ["brief", "Morning brief", briefCron, BRIEF_INSTRUCTIONS, true],
      ["scan", "Check-in scan", scanCron, SCAN_INSTRUCTIONS, false],
    ] as const) {
      const [existing] = await tx.execute<{ id: string }>(sql`
        select id from public.routines where bot_id = ${a.botId}::uuid and kind = ${kind} limit 1`);
      const next = nextRunAt(cron, zone).toISOString();
      if (existing)
        await tx.execute(sql`
          update public.routines set enabled = ${a.enabled}, schedule_cron = ${cron}, timezone = ${zone}, created_by = ${a.userId}::uuid,
            next_run_at = ${next}::timestamptz where id = ${existing.id}::uuid`);
      else if (a.enabled)
        await tx.execute(sql`
          insert into public.routines (org_id, bot_id, created_by, name, instructions_md, schedule_cron, timezone, trigger, notify, next_run_at, kind)
          values (${a.orgId}::uuid, ${a.botId}::uuid, ${a.userId}::uuid, ${name}, ${text}, ${cron}, ${zone},
                  '{"type":"schedule"}'::jsonb, ${notify}, ${next}::timestamptz, ${kind})`);
    }
  });
}

/** What the workspace's plan allows for check-ins (D-247). Missing keys (self-hosted) mean no limit. */
export async function proactiveLimits(db: Database, orgId: string) {
  const [e] = await db.execute<{ limits: Record<string, unknown> | null }>(sql`
    select limits from public.entitlements where org_id = ${orgId}::uuid order by created_at desc limit 1`);
  const n = (k: string) => (typeof e?.limits?.[k] === "number" ? (e.limits[k] as number) : null);
  return {
    maxProactiveBots: n("max_proactive_bots"),
    minScanHours: n("min_scan_hours"),
    /** Whether app events (a new email, a calendar change) may start a scan. */
    eventScans: n("event_scans") === null ? true : (n("event_scans") as number) > 0,
    /** At most this many event scans a day per bot (6 unless the plan says otherwise). */
    eventScansPerDay: n("event_scans_day") ?? EVENT_SCANS_PER_DAY,
    cloudDailyUsd: n("cloud_daily_usd"),
  };
}

/**
 * Why the plan doesn't allow turning check-ins on for this bot this way, or null when it does: too
 * many bots already check in, or scans more often than the plan's floor.
 */
export async function checkinPlanError(
  db: Database,
  a: { orgId: string; botId: string; scanEveryHours: number },
): Promise<string | null> {
  const l = await proactiveLimits(db, a.orgId);
  if (l.minScanHours !== null && a.scanEveryHours < l.minScanHours)
    return `Your plan checks in every ${l.minScanHours} hours at most. Upgrade to check more often.`;
  if (l.maxProactiveBots !== null) {
    const [r] = await db.execute<{ n: number }>(sql`
      select count(*)::int as n from public.bot_checkins ck join public.bots b on b.id = ck.bot_id
      where ck.org_id = ${a.orgId}::uuid and ck.enabled and ck.bot_id <> ${a.botId}::uuid and b.archived_at is null`);
    if ((r?.n ?? 0) >= l.maxProactiveBots)
      return l.maxProactiveBots === 1
        ? "Your plan has one bot that checks in on its own. Turn it off there first, or upgrade for more."
        : `Your plan has ${l.maxProactiveBots} bots that check in on their own. Turn one off first, or upgrade for more.`;
  }
  return null;
}

/**
 * Proactive from the first minute (D-247): a person's first bot checks in by default, within the
 * plan. Does nothing when check-ins were ever set for the bot, or the plan has no room.
 */
export async function enableDefaultCheckins(
  db: Database,
  a: { orgId: string; botId: string; userId: string },
) {
  const [existing] = await db.execute<{ bot_id: string }>(
    sql`select bot_id from public.bot_checkins where bot_id = ${a.botId}::uuid`,
  );
  if (existing) return false;
  const l = await proactiveLimits(db, a.orgId);
  const scanEveryHours = Math.min(24, Math.max(3, Math.ceil(l.minScanHours ?? 3)));
  if (await checkinPlanError(db, { ...a, scanEveryHours })) return false;
  await applyCheckins(db, {
    ...a,
    enabled: true,
    briefTime: "08:00",
    scanEveryHours,
    dailyCapUsd: Math.max(0.1, Math.min(1, l.cloudDailyUsd ?? 1)),
  });
  return true;
}

/** A person who hasn't opened Casama for this long gets at most one scan a day. */
const IDLE_SLOW_DAYS = 7;
/** ...and after this long, no briefs or scans until they're back. */
const IDLE_STOP_DAYS = 30;
/** Where app events cover email and calendar, scheduled scans are a backstop this often. */
const BACKSTOP_HOURS = 6;

/**
 * Whether a due brief or scan may run (D-247):
 *  - the bot is within the plan's number of bots that check in (oldest first, so a downgrade
 *    keeps the main one);
 *  - its person still uses Casama: idle 7 days, one scan a day; idle 30 days, nothing;
 *  - a scheduled scan respects the plan's floor, waits out quiet hours (the brief covers the
 *    night), and runs only every 6 hours where Composio events already cover email and calendar.
 * Asked-for scans skip the schedule rules (setup and new connections run whenever; app events
 * still wait out quiet hours). They were checked when asked for.
 */
export async function checkinAllowed(
  db: Database,
  r: { org_id: string; bot_id: string; kind?: unknown; last_run_at?: unknown },
  now = new Date(),
  opts: { eventsCoverMail?: boolean } = {},
) {
  const l = await proactiveLimits(db, r.org_id);
  if (l.maxProactiveBots !== null) {
    const rows = await db.execute<{ bot_id: string }>(sql`
      select ck.bot_id from public.bot_checkins ck join public.bots b on b.id = ck.bot_id
      where ck.org_id = ${r.org_id}::uuid and ck.enabled and b.archived_at is null
      order by b.created_at, b.id limit ${Math.max(0, Math.floor(l.maxProactiveBots))}`);
    if (!rows.some((x) => x.bot_id === r.bot_id)) return false;
  }
  const [ck] = await db.execute<{
    reason: string | null;
    requested: boolean;
    last_active: string | null;
    timezone: string | null;
    quiet_hours: QuietHours | null;
    triggers: boolean;
  }>(sql`
    select ck.scan_reason as reason, ck.scan_requested_at is not null as requested,
           public.user_last_active(ck.user_id) as last_active, p.timezone, p.quiet_hours,
           exists (select 1 from public.integrations i where i.org_id = ck.org_id and i.kind = 'composio'
                   and coalesce(i.config -> 'triggers', '{}'::jsonb) <> '{}'::jsonb) as triggers
    from public.bot_checkins ck left join public.profiles p on p.user_id = ck.user_id
    where ck.bot_id = ${r.bot_id}::uuid`);
  const idleDays = ck?.last_active
    ? (now.getTime() - new Date(ck.last_active).getTime()) / 86_400_000
    : 0;
  if (idleDays >= IDLE_STOP_DAYS) return false;
  if (r.kind !== "scan") return true;
  const reason = ck?.requested ? (ck.reason ?? "event") : null;
  const quiet = () =>
    quietUntil(
      now,
      ck?.timezone && isValidTimezone(ck.timezone) ? ck.timezone : "UTC",
      ck?.quiet_hours,
    ) !== null;
  if (reason === "setup" || reason === "connection") return true;
  if (reason === "event") return !quiet();
  if (quiet()) return false;
  if (!r.last_run_at) return true;
  let floorHours = l.minScanHours ?? 0;
  if (idleDays >= IDLE_SLOW_DAYS) floorHours = Math.max(floorHours, 24);
  if (ck?.triggers && opts.eventsCoverMail) floorHours = Math.max(floorHours, BACKSTOP_HOURS);
  // Ten minutes of slack, so an hourly cron on a one-hour plan never skips every other run.
  return (
    now.getTime() - new Date(r.last_run_at as string).getTime() >= floorHours * 3600_000 - 600_000
  );
}

/**
 * Event scans wait at least this long after the last scan, and a bot has a few a day (D-247
 * costs: every new email asked for one, so a busy inbox meant a scan every 30 minutes).
 */
const EVENT_SCAN_GAP_MS = 2 * 60 * 60_000;
const EVENT_SCANS_PER_DAY = 6;
const SCAN_NOTE_CHARS = 800;

/**
 * Asks for a scan soon (D-247): "setup" once after setup, "connection" for a new app, "event" when
 * a connected app reports something new. Event scans need a plan that allows them, come at most
 * every 2 hours and a few times a day. The note (what changed: sender and subject, event and
 * time) is handed to the scan so it starts there. Returns whether a scan is coming.
 */
export async function requestScan(
  db: Database,
  botId: string,
  reason: "setup" | "connection" | "event",
  note?: string | null,
) {
  let delay = reason === "setup" ? 60 : 120;
  if (reason === "event") {
    const [b] = await db.execute<{
      org_id: string;
      last_run_at: string | null;
      today: number;
    }>(sql`
      select ck.org_id, rt.last_run_at,
        (select count(*)::int from public.runs ru
         where ru.bot_id = ck.bot_id and ru.budget ->> 'scan_reason' = 'event'
           and ru.created_at > now() - interval '24 hours') as today
      from public.bot_checkins ck
      left join public.routines rt on rt.bot_id = ck.bot_id and rt.kind = 'scan'
      where ck.bot_id = ${botId}::uuid and ck.enabled limit 1`);
    if (!b) return false;
    const limits = await proactiveLimits(db, b.org_id);
    if (!limits.eventScans || b.today >= limits.eventScansPerDay) return false;
    if (b.last_run_at)
      delay = Math.max(
        delay,
        Math.ceil((new Date(b.last_run_at).getTime() + EVENT_SCAN_GAP_MS - Date.now()) / 1000),
      );
  }
  const [r] = await db.execute<{ ok: boolean }>(sql`
    select public.request_checkin_scan(${botId}::uuid, ${reason}, make_interval(secs => ${delay})) as ok`);
  if (r?.ok === true && note)
    await db.execute(sql`
      update public.bot_checkins
      set scan_note = left(concat_ws(E'\n', scan_note, ${note.replace(/\s+/g, " ").slice(0, 200)}::text), ${SCAN_NOTE_CHARS})
      where bot_id = ${botId}::uuid and scan_requested_at is not null`);
  return r?.ok === true;
}

/** Takes a bot's pending scan request (when a scan run starts): its reason and what changed. */
export async function takeScanRequest(
  db: Database,
  botId: string,
): Promise<{ reason: string; note: string | null } | null> {
  const [r] = await db.execute<{ reason: string | null; note: string | null }>(sql`
    select scan_reason as reason, scan_note as note from public.bot_checkins
    where bot_id = ${botId}::uuid and scan_requested_at is not null for update`);
  if (!r) return null;
  await db.execute(sql`
    update public.bot_checkins set scan_requested_at = null, scan_reason = null, scan_note = null
    where bot_id = ${botId}::uuid`);
  return { reason: r.reason ?? "event", note: r.note };
}

/**
 * After a check-in scan ends (D-247): the setup scan's one summary push ("You're all set. Found 3
 * things to start on, like…"), or a friendly hello when it found nothing.
 */
export async function afterCheckinRun(
  db: Database,
  notifications: NotificationService | undefined,
  run: { runId: string; orgId: string; botId: string; botName: string; finalText: string },
) {
  const [r] = await db.execute<{ reason: string | null; user_id: string | null }>(sql`
    select r.budget ->> 'scan_reason' as reason, ck.user_id from public.runs r
    left join public.bot_checkins ck on ck.bot_id = r.bot_id
    where r.id = ${run.runId}::uuid`);
  if (r?.reason !== "setup" || !r.user_id) return;
  const claimed = await db.execute<{ bot_id: string }>(sql`
    update public.bot_checkins set welcomed_at = now() where bot_id = ${run.botId}::uuid and welcomed_at is null returning bot_id`);
  if (!claimed.length || !notifications) return;
  const [c] = await db.execute<{ n: number }>(
    sql`select count(*)::int as n from public.suggestions where run_id = ${run.runId}::uuid`,
  );
  const text = run.finalText.replace(/\s+/g, " ").trim();
  const found = (c?.n ?? 0) > 0;
  const body = found
    ? text && !text.includes(NOTHING_NEW)
      ? text.slice(0, 240)
      : `You're all set. Found ${c?.n} ${c?.n === 1 ? "thing" : "things"} to start on.`
    : "You're all set. I'll keep an eye on things and tell you when something needs you.";
  track(db, {
    event: "proactive_message_sent",
    userId: r.user_id,
    orgId: run.orgId,
    properties: { kind: "summary", reason: "setup", found: c?.n ?? 0 },
  });
  await notifications.notify(
    r.user_id,
    run.orgId,
    "checkin_summary",
    { title: run.botName, body, link: "/inbox", bot_id: run.botId, run_id: run.runId },
    {
      urgency: "normal",
      why: { rule: `${run.botName}'s first look after setup (check-ins)`, data: [] },
      hold: false,
    },
  );
}

type SuggestionPush = {
  id: string;
  org_id: string;
  bot_id: string;
  user_id: string;
  run_id: string | null;
  title: string;
  body_md: string;
  push_text: string | null;
  urgency: "low" | "normal" | "urgent";
};

/** A suggestion's push: from the bot, in its own words, with Do it / Not now on phones (D-247). */
async function pushSuggestion(
  db: Database,
  notifications: NotificationService,
  s: SuggestionPush,
  kind: "suggestion" | "timed" = "suggestion",
) {
  const [bot] = await db.execute<{ name: string }>(
    sql`select name from public.bots where id = ${s.bot_id}::uuid`,
  );
  await db.execute(sql`update public.suggestions set notified_at = now() where id = ${s.id}::uuid`);
  const [run] = s.run_id
    ? await db.execute<{ reason: string | null }>(
        sql`select budget ->> 'scan_reason' as reason from public.runs where id = ${s.run_id}::uuid`,
      )
    : [];
  track(db, {
    event: "proactive_message_sent",
    userId: s.user_id,
    orgId: s.org_id,
    properties: { kind, reason: run?.reason ?? (s.run_id ? "schedule" : "other") },
  });
  await notifications.notify(
    s.user_id,
    s.org_id,
    "suggestion",
    {
      title: bot?.name ?? s.title,
      body: (s.push_text?.trim() || s.title).slice(0, 240),
      link: "/inbox",
      suggestion_id: s.id,
      suggestion_title: s.title,
      bot_id: s.bot_id,
    },
    {
      urgency: s.urgency,
      why: {
        rule: `A suggestion from ${bot?.name ?? "your bot"} during a check-in scan`,
        data: s.run_id ? await deviceDataOfRun(db, s.run_id).catch(() => []) : [],
      },
    },
  );
}

/** Pushes suggestions whose time has come (every minute, from the worker). */
export async function sendDueSuggestions(
  db: Database,
  notifications: NotificationService | undefined,
  limit = 100,
) {
  if (!notifications) return 0;
  const due = await db.execute<SuggestionPush>(sql`
    update public.suggestions set notified_at = now()
    where id in (select id from public.suggestions
                 where status = 'pending' and notified_at is null and notify_at <= now() and expires_at > now()
                 order by notify_at limit ${limit} for update skip locked)
    returning id, org_id, bot_id, user_id, run_id, title, body_md, push_text, urgency`);
  for (const s of due) await pushSuggestion(db, notifications, s, "timed").catch(() => {});
  return due.length;
}

/** Whether a bot's check-ins have used today's cap (in UTC). */
export async function checkinCapReached(db: Database, botId: string) {
  const [r] = await db.execute<{ spent: string; cap: string | null }>(sql`
    select coalesce(sum(r.cost_usd), 0) as spent, (select daily_cap_usd from public.bot_checkins where bot_id = ${botId}::uuid) as cap
    from public.runs r join public.routines rt on rt.id = r.routine_id
    where r.bot_id = ${botId}::uuid and rt.kind in ('brief', 'scan') and r.created_at >= date_trunc('day', now())`);
  return r?.cap !== null && r?.cap !== undefined && Number(r.spent) >= Number(r.cap);
}

/** What a scan should not repeat: pending and recently dismissed suggestions. */
export async function scanContext(db: Database, botId: string) {
  const rows = await db.execute<{ title: string; status: string }>(sql`
    select title, status from public.suggestions
    where bot_id = ${botId}::uuid and (status = 'pending' or (status = 'dismissed' and created_at > now() - interval '14 days'))
    order by created_at desc limit 50`);
  return rows.length
    ? `\n\nAlready suggested or dismissed:\n${rows.map((r) => `- ${r.title} (${r.status})`).join("\n")}`
    : "";
}

export function registerSuggestionTools(
  registry: ToolRegistry,
  deps: { db: Database; notifications?: NotificationService },
) {
  const { db } = deps;
  registry.register({
    name: "suggestions.add",
    description:
      "Suggest something for the person to do or approve, shown in their For you feed and sent as a push from you. Include the action you'd run if they accept (a tool name and its arguments), the sources, the urgency (low ones wait for the brief), push_text (the one line the push shows, in your own voice, ending in a question when you offer to do something), and notify_at when the offer only makes sense close to a time.",
    risk: "low",
    // Only the bot's own state inside Casama: never asks (D-155).
    selfOnly: true,
    schema: z.object({
      title: z.string().min(1).max(200),
      body: z.string().max(5000).optional(),
      action: z
        .object({
          tool: z.string().min(1).max(120),
          args: z.record(z.string(), z.unknown()).optional(),
        })
        .optional(),
      sources: z.array(z.string().max(500)).max(10).optional(),
      urgency: z.enum(["low", "normal", "urgent"]).optional(),
      push_text: z
        .string()
        .max(200)
        .optional()
        .describe(
          'The push, in first person, like a text: "Want me to book a ride to the show at 7?"',
        ),
      notify_at: z
        .string()
        .datetime({ offset: true })
        .optional()
        .describe(
          "ISO time to send the push (for example an hour before an event); leave out to send now",
        ),
      expires_in_hours: z
        .number()
        .int()
        .min(1)
        .max(24 * 14)
        .optional(),
    }),
    async execute(args, ctx) {
      const user = (await actingUserOf(db, ctx.runId)) ?? null;
      if (!user) throw new ToolError("no_person", "There's nobody to suggest this to.");
      const [dup] = await db.execute<{ id: string }>(sql`
        select id from public.suggestions where bot_id = ${ctx.botId}::uuid and user_id = ${user}::uuid
          and lower(title) = lower(${args.title}) and (status = 'pending' or created_at > now() - interval '14 days') limit 1`);
      if (dup) return { content: "Already suggested; skipped.", preview: "duplicate" };
      // A time to push it (D-247): never in the past, and the suggestion lives until a while after.
      const notifyAt = args.notify_at ? new Date(args.notify_at) : null;
      const later = notifyAt && notifyAt.getTime() > Date.now() + 60_000 ? notifyAt : null;
      const expiresHours = Math.max(
        args.expires_in_hours ?? 72,
        later ? Math.ceil((later.getTime() - Date.now()) / 3600_000) + 6 : 0,
      );
      const [row] = await db.execute<{ id: string }>(sql`
        insert into public.suggestions (org_id, bot_id, user_id, run_id, title, body_md, proposed_action, sources, urgency, expires_at, push_text, notify_at)
        values (${ctx.orgId}::uuid, ${ctx.botId}::uuid, ${user}::uuid, ${ctx.runId}::uuid, ${args.title}, ${args.body ?? ""},
                ${args.action ? JSON.stringify(args.action) : null}::jsonb, ${JSON.stringify(args.sources ?? [])}::jsonb,
                ${args.urgency ?? "normal"}, now() + make_interval(hours => ${Math.min(expiresHours, 24 * 14)}),
                ${args.push_text ?? null}, ${later?.toISOString() ?? null}::timestamptz)
        returning id`);
      // The first scan after setup sends one summary instead (afterCheckinRun); a timed one waits.
      const [run] = await db.execute<{ reason: string | null }>(
        sql`select budget ->> 'scan_reason' as reason from public.runs where id = ${ctx.runId}::uuid`,
      );
      // Attention rules (D-153): urgent ones push now; normal ones push unless the person is busy
      // or the bot is over its daily cap (then the next brief carries them); low ones wait for the brief.
      if (row && deps.notifications && run?.reason !== "setup" && !later)
        await pushSuggestion(db, deps.notifications, {
          id: row.id,
          org_id: ctx.orgId,
          bot_id: ctx.botId,
          user_id: user,
          run_id: ctx.runId,
          title: args.title,
          body_md: args.body ?? "",
          push_text: args.push_text ?? null,
          urgency: args.urgency ?? "normal",
        }).catch(() => {});
      return {
        content: later
          ? `Suggested: ${args.title}. The push goes out at ${later.toISOString()}.`
          : `Suggested: ${args.title}.`,
        preview: args.title,
      };
    },
  });
}
