/**
 * Check-ins (SPEC: Post-v1 roadmap → Check-ins; D-114). Off by default per bot. When on, a morning
 * brief and a scan every few hours run as routines (kind brief and scan) on the bot's cheaper
 * model, within a daily cap. Scans leave suggestions; a scan that finds nothing writes nothing and
 * sends nothing.
 */
import type { Database } from "@kasama/db";
import { isValidTimezone, nextRunAt } from "@kasama/domain";
import { sql } from "drizzle-orm";
import { z } from "zod";
import { actingUserOf } from "./acting.ts";
import type { NotificationService } from "./notifications.ts";
import { ToolError, type ToolRegistry } from "./tools/registry.ts";
import { deviceDataOfRun } from "./attention.ts";

export const BRIEF_INSTRUCTIONS = [
  "Write my morning brief for today. Check what you can reach: calendar and email accounts you're connected to, tickets on the board assigned to you or me, active projects, and anything you're watching.",
  "Cover, briefly: today's meetings (time, title, who), emails that need a reply from me, tickets due or blocked, and projects that need a decision. Skip sections with nothing in them.",
  "Keep it to one screen. Don't take any actions; suggest them instead with suggestions.add when something clearly needs doing.",
].join("\n");

export const SCAN_INSTRUCTIONS = [
  "Check-in scan. Look over what you can reach (connected accounts, tickets, projects, things you're watching) for anything new since your last scan that needs me.",
  "For each item that genuinely needs me, call suggestions.add with a short title, why it matters, the action you'd take (a tool and its arguments) when there is one, the sources, and its urgency (urgent only if it can't wait for my next look).",
  "Don't repeat anything already suggested or dismissed (listed below). Don't take actions yourself. If there's nothing new, reply with just NOTHING_NEW.",
].join("\n");

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
      "Suggest something for the person to do or approve, shown in their For you feed. Include the action you'd run if they accept (a tool name and its arguments), the sources, and the urgency. Only urgent suggestions send a notification.",
    risk: "low",
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
      const [row] = await db.execute<{ id: string }>(sql`
        insert into public.suggestions (org_id, bot_id, user_id, run_id, title, body_md, proposed_action, sources, urgency, expires_at)
        values (${ctx.orgId}::uuid, ${ctx.botId}::uuid, ${user}::uuid, ${ctx.runId}::uuid, ${args.title}, ${args.body ?? ""},
                ${args.action ? JSON.stringify(args.action) : null}::jsonb, ${JSON.stringify(args.sources ?? [])}::jsonb,
                ${args.urgency ?? "normal"}, now() + make_interval(hours => ${args.expires_in_hours ?? 72}))
        returning id`);
      // Attention rules (D-153): urgent ones push now; normal ones push unless the person is busy
      // or the bot is over its daily cap (then the next brief carries them); low ones wait for the brief.
      const [bot] = await db.execute<{ name: string }>(sql`select name from public.bots where id = ${ctx.botId}::uuid`);
      await deps.notifications
        ?.notify(
          user,
          ctx.orgId,
          "suggestion",
          { title: args.title, body: (args.body ?? "").slice(0, 240), link: "/inbox", suggestion_id: row?.id, bot_id: ctx.botId },
          { urgency: args.urgency ?? "normal", why: { rule: `A suggestion from ${bot?.name ?? "your bot"} during a check-in scan`, data: await deviceDataOfRun(db, ctx.runId).catch(() => []) } },
        )
        .catch(() => {});
      return { content: `Suggested: ${args.title}.`, preview: args.title };
    },
  });
}
