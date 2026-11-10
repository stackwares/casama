/**
 * Attention rules (SPEC: Attention rules; D-153): a non-urgent proactive message waits (inbox only,
 * bundled into the next brief) while the person is in a Focus mode, driving or in a calendar
 * meeting, or once a bot has sent 5 non-urgent pushes in a day. Quiet hours (D-109) still defer
 * the push separately.
 */
import type { Database } from "@kasama/db";
import { sql } from "drizzle-orm";

export type HoldReason = "focus" | "meeting" | "driving" | "daily_cap" | "low_urgency";
export const PROACTIVE_DAILY_CAP = 5;

/** Why a proactive message reached the person: the rule and the data behind it. */
export interface Why {
  rule: string;
  data?: string[];
}

export async function attentionHold(db: Database, userId: string, botId: string | null, now = new Date()): Promise<HoldReason | null> {
  const iso = now.toISOString();
  // Focus / Do Not Disturb and driving: the latest on/off event from the person's devices (12 h).
  const [state] = await db.execute<{ focus: string | null; driving: string | null }>(sql`
    select
      (select type from public.device_event_log where user_id = ${userId}::uuid and type in ('focus_on', 'focus_off')
        and received_at > ${iso}::timestamptz - interval '12 hours' order by received_at desc limit 1) as focus,
      (select type from public.device_event_log where user_id = ${userId}::uuid and type in ('driving_on', 'driving_off')
        and received_at > ${iso}::timestamptz - interval '3 hours' order by received_at desc limit 1) as driving`);
  if (state?.focus === "focus_on") return "focus";
  if (state?.driving === "driving_on") return "driving";
  // A meeting on the calendar the person shares from their devices (D-149), happening now.
  const days = await db.execute<{ summary: { events?: Array<{ start?: string; end?: string; all_day?: boolean }> } }>(sql`
    select summary from public.device_readings where user_id = ${userId}::uuid and kind = 'calendar'
      and period_start <= ${iso}::timestamptz and period_end >= ${iso}::timestamptz - interval '1 day'`);
  const t = now.getTime();
  if (days.some((d) => (d.summary?.events ?? []).some((e) => !e.all_day && e.start && e.end && Date.parse(e.start) <= t && t < Date.parse(e.end)))) return "meeting";
  // Five non-urgent pushes per bot per day.
  if (botId) {
    const [n] = await db.execute<{ n: number }>(sql`
      select count(*)::int as n from public.notifications where user_id = ${userId}::uuid and urgency in ('low', 'normal')
        and push_status in ('sent', 'deferred') and payload ->> 'bot_id' = ${botId} and created_at > ${iso}::timestamptz - interval '24 hours'`);
    if ((n?.n ?? 0) >= PROACTIVE_DAILY_CAP) return "daily_cap";
  }
  return null;
}

/** The device kinds a run's model saw (from its device.data_used events), for "Why am I seeing this?". */
export async function deviceDataOfRun(db: Database, runId: string): Promise<string[]> {
  const rows = await db.execute<{ kind: string }>(sql`
    select distinct payload ->> 'kind' as kind from public.run_events where run_id = ${runId}::uuid and type = 'device.data_used'`);
  return rows.map((r) => r.kind).filter(Boolean);
}

/** The brief's "while you were busy" list; the held messages are marked as bundled. */
export async function takeHeldForBrief(db: Database, userId: string, orgId: string): Promise<string> {
  // Only this workspace's messages: a brief never carries another workspace's content (audit 2026-11).
  const rows = await db.execute<{ payload: { title?: string; body?: string; why?: Why }; held_reason: string | null }>(sql`
    update public.notifications set push_status = 'bundled'
    where id in (select id from public.notifications where user_id = ${userId}::uuid and org_id = ${orgId}::uuid and push_status = 'held'
                 and created_at > now() - interval '36 hours' order by created_at limit 30)
    returning payload, held_reason`);
  if (!rows.length) return "";
  const reason: Record<string, string> = { focus: "you were focused", meeting: "you were in a meeting", driving: "you were driving", daily_cap: "the bot had sent enough for the day", low_urgency: "it wasn't urgent" };
  return `These waited for this brief (mention them briefly):\n${rows
    .map((r) => `- ${r.payload.title ?? "Update"}${r.payload.body ? `: ${r.payload.body}` : ""} (held because ${reason[r.held_reason ?? ""] ?? "it could wait"})`)
    .join("\n")}`;
}
