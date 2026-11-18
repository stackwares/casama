/**
 * Check-ins (SPEC: Post-v1 roadmap → Check-ins; D-114). Off by default per bot. When on, a morning
 * brief and a scan every few hours run as routines (kind brief and scan) on the bot's cheaper
 * model, within a daily cap. Scans leave suggestions; a scan that finds nothing writes nothing and
 * sends nothing.
 */
import { contentKeys, type Database } from "@casama/db";
import { isValidTimezone, nextRunAt, type QuietHours, quietUntil } from "@casama/domain";
import { sql } from "drizzle-orm";
import { z } from "zod";
import { actingUserOf } from "./acting.ts";
import { track } from "./analytics.ts";
import { deviceDataOfRun } from "./attention.ts";
import { wrapUntrusted } from "./context.ts";
import { mainConversation, postFromBot } from "./general.ts";
import type { NotificationService } from "./notifications.ts";
import {
  BRIEF_OPENING,
  BUILT_IN_PROMPTS,
  composeBrief,
  composeScan,
  composeSetupScan,
  promptText,
  SCAN_OPENING,
} from "./prompts.ts";
import { ToolError, type ToolRegistry } from "./tools/registry.ts";

/** Today's brief and scan wording (D-374): the fixed parts in code, the rest from the gallery. */
export const briefInstructionsNow = () => composeBrief(promptText("checkin.brief"));
export const scanInstructionsNow = () => composeScan(promptText("checkin.scan"));
/** Added to the first scan after setup, which ends in one summary push instead of one per suggestion. */
export const setupScanInstructionsNow = () => composeSetupScan(promptText("checkin.setup_scan"));

/** The built-in wording, stored with a new brief or scan (runs use today's wording, below). */
export const BRIEF_INSTRUCTIONS = composeBrief(BUILT_IN_PROMPTS["checkin.brief"]);
export const SCAN_INSTRUCTIONS = composeScan(BUILT_IN_PROMPTS["checkin.scan"]);
export const SETUP_SCAN_INSTRUCTIONS = composeSetupScan(BUILT_IN_PROMPTS["checkin.setup_scan"]);
/** How a brief's reply says there's nothing to tell; such a brief posts in the chat without a push. */
export const QUIET_BRIEF = /^\W*quiet day\b/i;
/**
 * A brief's instructions: today's wording for briefs made with the original text (they start the
 * same way), so changes reach briefs set up before them; a brief the person rewrote keeps
 * theirs (D-312).
 */
export const briefInstructions = (stored: string) =>
  stored.startsWith(BRIEF_OPENING) ? briefInstructionsNow() : stored;
/** A scan's instructions, the same way: today's wording unless the person rewrote them. */
export const scanInstructions = (stored: string) =>
  stored.startsWith(SCAN_OPENING) ? scanInstructionsNow() : stored;

const REASON_NOTES: Record<string, () => string> = {
  connection: () => promptText("checkin.reason.connection"),
  event: () => promptText("checkin.reason.event"),
};
/** The text of a scan run's task: the instructions, why it runs now, and what not to repeat. */
export function scanTask(
  instructions: string,
  reason: string | null,
  context: string,
  note: string | null = null,
) {
  const reasonNote = reason ? REASON_NOTES[reason] : undefined;
  const extra =
    reason === "setup"
      ? `\n\n${setupScanInstructionsNow()}`
      : reasonNote
        ? `\n\n${reasonNote()}`
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

/**
 * When scans run: every N hours from midnight, at the brief's minute. Once a day is the exception:
 * "every 24 hours from midnight" is midnight, inside most people's quiet hours, where a scheduled
 * scan is skipped, so it would never run. It runs six hours after the brief instead (the brief
 * covers the morning, the scan the afternoon).
 */
export function scanCronFor(briefTime: string, everyHours: number) {
  const [hh, mm] = briefTime.split(":").map(Number) as [number, number];
  return everyHours >= 24
    ? `${mm % 60} ${(hh + 6) % 24} * * *`
    : `${mm % 60} */${everyHours} * * *`;
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
  const scanCron = scanCronFor(a.briefTime, a.scanEveryHours);
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
    /** The share of the day's limit on Casama's key that check-ins may use (0.4 unless set). */
    checkinDayShare: Math.min(1, Math.max(0, n("checkin_day_share") ?? CHECKIN_DAY_SHARE)),
  };
}

/**
 * Check-ins leave room for the person (docs/USAGE-PLAN.md step 5): all of a workspace's briefs and
 * scans together stop at this share of the day's limit on Casama's key. Without it a Free
 * workspace's scans could use the whole $0.25 and its owner's own message was then refused.
 */
export const CHECKIN_DAY_SHARE = 0.4;

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
    // No more than check-ins' share of the day's limit, where the plan has one.
    dailyCapUsd: Math.max(
      0.1,
      Math.min(1, l.cloudDailyUsd === null ? 1 : l.cloudDailyUsd * l.checkinDayShare),
    ),
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
  // The welcome's catch-up already was the summary (D-257): no second "You're all set".
  if (await hadCatchup(db, run.botId)) return;
  const [c] = await db.execute<{ n: number }>(
    sql`select count(*)::int as n from public.suggestions where run_id = ${run.runId}::uuid`,
  );
  const n = c?.n ?? 0;
  const body = summaryText(run.finalText, n);
  // The same words open the person's General (D-253); the suggestions follow as cards. When the
  // chat just said "You're all set" (the welcome's last line), the post doesn't say it again.
  const conversationId = await mainConversation(db, run.orgId, run.botId, r.user_id);
  const said = await lastBotText(db, conversationId);
  await postFromBot(db, {
    orgId: run.orgId,
    conversationId,
    botId: run.botId,
    parts: [{ type: "text", text: ALL_SET.test(said) ? withoutAllSet(body) : body }],
  }).catch(() => null);
  track(db, {
    event: "proactive_message_sent",
    userId: r.user_id,
    orgId: run.orgId,
    properties: { kind: "summary", reason: "setup", found: n },
  });
  await notifications.notify(
    r.user_id,
    run.orgId,
    "checkin_summary",
    {
      title: run.botName,
      body,
      // General itself, not whichever chat with the bot was open or newest.
      link: `/bots/${run.botId}/chat?c=${conversationId}`,
      bot_id: run.botId,
      conversation_id: conversationId,
      run_id: run.runId,
    },
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
    ? await db.execute<{ reason: string | null; kind: string | null }>(
        sql`select r.budget ->> 'scan_reason' as reason, rt.kind from public.runs r
            left join public.routines rt on rt.id = r.routine_id where r.id = ${s.run_id}::uuid`,
      )
    : [];
  // A brief's suggestions are cards under it, and its own push covers them (D-312); a timed or
  // urgent one still pushes.
  const fromBrief = run?.kind === "brief";
  if (fromBrief && kind === "suggestion" && s.urgency !== "urgent") return;
  track(db, {
    event: "proactive_message_sent",
    userId: s.user_id,
    orgId: s.org_id,
    properties: { kind, reason: run?.reason ?? (s.run_id ? "schedule" : "other") },
  });
  // Opens General, where the suggestion is a card (D-253). The link names it: without a `c` the
  // app opens whichever chat with the bot was open or newest.
  const general = await mainConversation(db, s.org_id, s.bot_id, s.user_id).catch(() => null);
  await notifications.notify(
    s.user_id,
    s.org_id,
    "suggestion",
    {
      title: bot?.name ?? s.title,
      body: (s.push_text?.trim() || s.title).slice(0, 240),
      link: `/bots/${s.bot_id}/chat${general ? `?c=${general}` : ""}`,
      ...(general ? { conversation_id: general } : {}),
      suggestion_id: s.id,
      suggestion_title: s.title,
      bot_id: s.bot_id,
    },
    {
      urgency: s.urgency,
      why: {
        rule: `A suggestion from ${bot?.name ?? "your bot"} during ${fromBrief ? "your morning brief" : "a check-in scan"}`,
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

/**
 * Whether a bot's check-ins have used today's cap, in the person's own day (D-312): a UTC day
 * started at 08:00 in Manila, the same minute as the brief. Also true once all of the workspace's
 * check-ins together have used their share of the day's limit on Casama's key, so the person's own
 * messages always have room.
 */
export async function checkinCapReached(db: Database, botId: string) {
  const [r] = await db.execute<{
    spent: string;
    cap: string | null;
    org_id: string | null;
    org_spent: string;
  }>(sql`
    with c as (
      select bc.daily_cap_usd as cap, bc.org_id,
        coalesce((select p.timezone from public.profiles p where p.user_id = bc.user_id
                   and p.timezone in (select name from pg_timezone_names)), 'UTC') as tz
      from public.bot_checkins bc where bc.bot_id = ${botId}::uuid),
    today as (
      select r.bot_id, r.cost_usd from public.runs r join public.routines rt on rt.id = r.routine_id
      where r.org_id = (select org_id from c) and rt.kind in ('brief', 'scan')
        and r.created_at >= (date_trunc('day', now() at time zone coalesce((select tz from c), 'UTC')) at time zone coalesce((select tz from c), 'UTC')))
    select coalesce(sum(cost_usd) filter (where bot_id = ${botId}::uuid), 0) as spent,
           coalesce(sum(cost_usd), 0) as org_spent,
           (select cap from c) as cap, (select org_id from c) as org_id
    from today`);
  if (r?.cap !== null && r?.cap !== undefined && Number(r.spent) >= Number(r.cap)) return true;
  if (!r?.org_id) return false;
  const l = await proactiveLimits(db, r.org_id);
  return l.cloudDailyUsd !== null && Number(r.org_spent) >= l.cloudDailyUsd * l.checkinDayShare;
}

/** The digest of what a bot's last finished scan read first (checkin-prefetch.ts). */
export async function lastScanDigest(db: Database, botId: string): Promise<string | null> {
  const [r] = await db.execute<{ scan_digest: string | null }>(
    sql`select scan_digest from public.bot_checkins where bot_id = ${botId}::uuid`,
  );
  return r?.scan_digest ?? null;
}

export async function saveScanDigest(db: Database, botId: string, digest: string) {
  await db.execute(
    sql`update public.bot_checkins set scan_digest = ${digest} where bot_id = ${botId}::uuid`,
  );
}

/** What a scan should not repeat: pending and recently dismissed suggestions. */
export async function scanContext(db: Database, botId: string, reason?: string | null) {
  const rows = await db.execute<{ title: string; status: string }>(sql`
    select title, status from public.suggestions
    where bot_id = ${botId}::uuid and (status = 'pending' or (status = 'dismissed' and created_at > now() - interval '14 days'))
    order by created_at desc limit 50`);
  const already = rows.length
    ? `\n\nAlready suggested or dismissed:\n${rows.map((r) => `- ${r.title} (${r.status})`).join("\n")}`
    : "";
  return already + (reason === "setup" ? await catchupContext(db, botId) : "");
}

/** The welcome catch-up the person already got (D-257), so the setup scan doesn't repeat it. */
async function catchupContext(db: Database, botId: string) {
  const rows = await db.execute<{ content: unknown }>(sql`
    select m.content from public.messages m
    join public.conversations c on c.id = m.conversation_id
    where c.bot_id = ${botId}::uuid and c.purpose = 'welcome' and (c.welcome ->> 'catchup')::boolean is true
      and m.role = 'assistant' and m.run_id is not null
    order by m.created_at limit 6`);
  const text = rows
    .flatMap((r) => {
      const parts = contentKeys.open(r.content);
      return Array.isArray(parts)
        ? parts.map((p) => (p && typeof p === "object" && "text" in p ? String(p.text ?? "") : ""))
        : [];
    })
    .join("\n")
    .trim()
    .slice(0, 2000);
  return text
    ? `\n\nThe person already got this catch-up in the welcome chat. Don't suggest the same items again; only what it missed:\n${wrapUntrusted("welcome catch-up", text)}`
    : "";
}

const ALL_SET = /^you(?:'|\u2019)re all set[.;,!]?\s*/i;

/**
 * The setup scan's summary: the model's sentence, with the count it gives set to the suggestions it
 * really saved (it sometimes counts one it never added), or a plain line when it gave none.
 */
export function summaryText(finalText: string, n: number) {
  if (n <= 0)
    return "You're all set. I'll keep an eye on things and tell you when something needs you.";
  const things = `${n} ${n === 1 ? "thing" : "things"}`;
  const text = finalText.replace(/\s+/g, " ").trim();
  if (!text || text.includes(NOTHING_NEW)) return `You're all set. Found ${things} to start on.`;
  return text
    .replace(/\bFound (?:\d+|one|two|three|four|five) things?\b/i, `Found ${things}`)
    .slice(0, 240);
}

/** The summary without its opening "You're all set." ("Found 3 things to start on, like…"). */
export function withoutAllSet(text: string) {
  const rest = text.replace(ALL_SET, "");
  return rest ? rest.charAt(0).toUpperCase() + rest.slice(1) : text;
}

/** The text of the bot's last message in a conversation, or "" when it has none or ended in a card. */
async function lastBotText(db: Database, conversationId: string) {
  const [m] = await db.execute<{ role: string; content: unknown }>(sql`
    select role, content from public.messages where conversation_id = ${conversationId}::uuid
    order by created_at desc limit 1`);
  if (m?.role !== "assistant") return "";
  const parts = contentKeys.open(m.content);
  if (!Array.isArray(parts)) return "";
  return parts
    .map((p) =>
      p && typeof p === "object" && p.type === "text" && typeof p.text === "string" ? p.text : "",
    )
    .join(" ")
    .trim();
}

/** Whether the bot's welcome already gave a Google catch-up (D-257): then it is the summary. */
async function hadCatchup(db: Database, botId: string) {
  const [r] = await db.execute<{ yes: boolean }>(sql`
    select exists (select 1 from public.conversations where bot_id = ${botId}::uuid and purpose = 'welcome'
      and (welcome ->> 'catchup')::boolean is true) as yes`);
  return r?.yes === true;
}

export function registerSuggestionTools(
  registry: ToolRegistry,
  deps: { db: Database; notifications?: NotificationService },
) {
  const { db } = deps;
  registry.register({
    name: "suggestions.add",
    description:
      "Suggest something for the person to do or approve, posted as a card in your main chat with them (after your reply) and sent as a push from you. Include the action you'd run if they accept (a tool name and its arguments), the sources, the urgency (low ones wait for the brief), push_text (the one line the push shows, in your own voice, ending in a question when you offer to do something), and notify_at when the offer only makes sense close to a time.",
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
