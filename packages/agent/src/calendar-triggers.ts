/**
 * Calendar triggers (SPEC: Post-v1 roadmap → Calendar triggers; D-132). A routine with a
 * `calendar_event` trigger runs a set time before or after events from a connected calendar
 * (Google or Outlook through their app connections), filtered by calendar, outside guests, title
 * and video link. The worker reads upcoming events every 5 minutes through the connection's own
 * list-events tool and schedules one fire per routine and event.
 */
import type { Database } from "@kasama/db";
import { sql } from "drizzle-orm";
import { createAdapter, loadIntegration } from "./integrations.ts";

export interface CalendarTrigger {
  type: "calendar_event";
  integration_id: string;
  /** Minutes relative to the event's start: -15 is 15 minutes before. */
  offset_minutes: number;
  calendar?: string;
  outside_guests?: boolean;
  title_match?: string;
  has_video_link?: boolean;
  checked_at?: string;
}

export interface CalEvent {
  id: string;
  title: string;
  start: string;
  end: string | null;
  attendees: string[];
  selfEmail: string | null;
  link: string | null;
  location: string | null;
  description: string | null;
  calendar: string | null;
}

export const CHECK_EVERY_MS = 5 * 60_000;
const LOOKAHEAD_MS = 36 * 60 * 60_000;
const VIDEO = /https?:\/\/[^\s"'<>]*(meet\.google\.com|zoom\.us|teams\.microsoft\.com|teams\.live\.com|webex\.com|whereby\.com)[^\s"'<>]*/i;

const str = (v: unknown) => (typeof v === "string" && v ? v : null);
const timeOf = (v: unknown) =>
  str(v) ?? (v && typeof v === "object" ? str((v as Record<string, unknown>).dateTime) ?? str((v as Record<string, unknown>).date) : null);

/** Events from a list-events tool's output: Google, Microsoft Graph and plain shapes. */
export function parseEvents(text: string): CalEvent[] {
  let raw: unknown;
  try {
    raw = JSON.parse(text);
  } catch {
    const m = /[[{][\s\S]*[\]}]/.exec(text);
    if (!m) return [];
    try {
      raw = JSON.parse(m[0]);
    } catch {
      return [];
    }
  }
  const obj = raw as Record<string, unknown>;
  const list = Array.isArray(raw) ? raw : ((obj.items ?? obj.events ?? obj.value ?? obj.data ?? []) as unknown[]);
  const out: CalEvent[] = [];
  for (const e of Array.isArray(list) ? list : []) {
    if (!e || typeof e !== "object") continue;
    const x = e as Record<string, unknown>;
    const start = timeOf(x.start) ?? str(x.startTime) ?? str(x.start_time);
    const id = str(x.id) ?? str(x.iCalUID);
    if (!start || !id || x.status === "cancelled" || x.isCancelled === true) continue;
    const attendees = (Array.isArray(x.attendees) ? x.attendees : []) as Array<Record<string, unknown>>;
    const emails = attendees
      .map((a) => str(a.email) ?? str((a.emailAddress as Record<string, unknown> | undefined)?.address))
      .filter((v): v is string => !!v)
      .map((v) => v.toLowerCase());
    const self = attendees.find((a) => a.self === true);
    const description = str(x.description) ?? str((x.body as Record<string, unknown> | undefined)?.content) ?? null;
    const location = str(x.location) ?? str((x.location as Record<string, unknown> | undefined)?.displayName) ?? null;
    const entry = ((x.conferenceData as Record<string, unknown> | undefined)?.entryPoints as Array<Record<string, unknown>> | undefined)?.find((p) => p.entryPointType === "video");
    const link =
      str(x.hangoutLink) ??
      str(entry?.uri) ??
      str((x.onlineMeeting as Record<string, unknown> | undefined)?.joinUrl) ??
      str(x.onlineMeetingUrl) ??
      (VIDEO.exec(`${location ?? ""} ${description ?? ""}`)?.[0] ?? null);
    out.push({
      id,
      title: str(x.summary) ?? str(x.title) ?? str(x.subject) ?? "(no title)",
      start,
      end: timeOf(x.end) ?? str(x.endTime) ?? null,
      attendees: emails,
      selfEmail: str(self?.email)?.toLowerCase() ?? str((x.organizer as Record<string, unknown> | undefined)?.self === true ? (x.organizer as Record<string, unknown>).email : null)?.toLowerCase() ?? null,
      link,
      location,
      description,
      calendar: str(x.calendarId) ?? str(x.calendar) ?? str((x.organizer as Record<string, unknown> | undefined)?.displayName) ?? null,
    });
  }
  return out;
}

const domainOf = (email: string) => email.split("@")[1]?.toLowerCase() ?? "";

/** Whether an event passes the trigger's filters. */
export function eventMatches(e: CalEvent, t: CalendarTrigger, ownDomain: string | null) {
  if (t.calendar && (e.calendar ?? "").toLowerCase() !== t.calendar.toLowerCase()) return false;
  if (t.title_match && !e.title.toLowerCase().includes(t.title_match.toLowerCase())) return false;
  if (t.has_video_link && !e.link) return false;
  if (t.outside_guests) {
    const mine = (e.selfEmail ? domainOf(e.selfEmail) : null) ?? ownDomain;
    if (!mine) return false;
    if (!e.attendees.some((a) => domainOf(a) !== mine)) return false;
  }
  return true;
}

/** The event as the run sees it. */
export function describeEvent(e: CalEvent) {
  return [
    `Event: ${e.title}`,
    `Starts: ${e.start}${e.end ? `, ends ${e.end}` : ""}`,
    e.attendees.length ? `Attendees: ${e.attendees.join(", ")}` : "",
    e.link ? `Video link: ${e.link}` : "",
    e.location ? `Location: ${e.location}` : "",
    e.description ? `Description: ${e.description.slice(0, 3000)}` : "",
  ]
    .filter(Boolean)
    .join("\n");
}

/** Arguments for a list-events tool, named the way its input schema names them. */
export function listArgs(schema: Record<string, unknown> | undefined, from: Date, to: Date) {
  const props = Object.keys(((schema?.properties as Record<string, unknown>) ?? {}) as object);
  const pick = (...names: string[]) => names.find((n) => props.includes(n));
  const fromKey = pick("timeMin", "time_min", "startDateTime", "start_time", "startTime", "start", "from") ?? "timeMin";
  const toKey = pick("timeMax", "time_max", "endDateTime", "end_time", "endTime", "end", "to") ?? "timeMax";
  const args: Record<string, unknown> = { [fromKey]: from.toISOString(), [toKey]: to.toISOString() };
  if (props.includes("singleEvents")) args.singleEvents = true;
  if (props.includes("orderBy")) args.orderBy = "startTime";
  return args;
}

/**
 * Reads upcoming events for calendar routines not checked in the last 5 minutes and schedules
 * their fires. Returns how many new fires were scheduled.
 */
export async function checkCalendarTriggers(d: { db: Database; fetch: typeof fetch }, now = new Date()) {
  const { db } = d;
  const due = await db.execute<{ id: string; org_id: string; created_by: string | null; trigger: CalendarTrigger }>(sql`
    select id, org_id, created_by, trigger from public.routines
    where enabled and trigger ->> 'type' = 'calendar_event'
      and (trigger ->> 'checked_at' is null or (trigger ->> 'checked_at')::timestamptz <= ${new Date(now.getTime() - CHECK_EVERY_MS + 1000).toISOString()}::timestamptz)
    limit 50`);
  let scheduled = 0;
  for (const r of due) {
    const t = r.trigger;
    await db.execute(sql`update public.routines set trigger = trigger || ${JSON.stringify({ checked_at: now.toISOString() })}::jsonb where id = ${r.id}::uuid`);
    const rec = await loadIntegration(db, t.integration_id, d.fetch).catch(() => null);
    if (!rec) continue;
    const [cache] = await db.execute<{ tools_cache: Array<{ name: string; inputSchema?: Record<string, unknown>; input_schema?: Record<string, unknown> }> }>(
      sql`select tools_cache from public.integrations where id = ${t.integration_id}::uuid`,
    );
    const tool = (cache?.tools_cache ?? []).find((x) => /list.*event|event.*list|search.*event|get.*events/i.test(x.name));
    if (!tool) continue;
    const offset = Number(t.offset_minutes) || 0;
    // Events whose fire time falls between a minute ago and the look-ahead.
    const from = new Date(now.getTime() - offset * 60_000 - 60_000);
    const to = new Date(now.getTime() + LOOKAHEAD_MS);
    const adapter = createAdapter(rec, { fetch: d.fetch, secrets: [] });
    let events: CalEvent[];
    try {
      events = parseEvents(await adapter.callTool(tool.name, listArgs(tool.inputSchema ?? tool.input_schema, from, to)));
    } catch {
      continue;
    } finally {
      await adapter.close?.();
    }
    const [own] = r.created_by
      ? await db.execute<{ domain: string | null }>(sql`select public.worker_user_email_domain(${r.created_by}::uuid) as domain`)
      : [];
    // Fires scheduled earlier for events that were cancelled, moved out of the window or no longer
    // match the filters are dropped (audit 2026-11: they used to fire anyway).
    const keep = events.filter((e) => eventMatches(e, t, own?.domain ?? null)).map((e) => e.id);
    await db.execute(sql`
      delete from public.calendar_fires where routine_id = ${r.id}::uuid and fired_at is null
        and fire_at >= ${now.toISOString()}::timestamptz and fire_at <= ${to.toISOString()}::timestamptz
        and event_id not in (select jsonb_array_elements_text(${JSON.stringify(keep)}::jsonb))`);
    for (const e of events) {
      if (!eventMatches(e, t, own?.domain ?? null)) continue;
      const fireAt = new Date(Date.parse(e.start) + offset * 60_000);
      if (Number.isNaN(fireAt.getTime()) || fireAt.getTime() < now.getTime() - 60_000) continue;
      const rows = await db.execute(sql`
        insert into public.calendar_fires (routine_id, event_id, org_id, fire_at, event)
        values (${r.id}::uuid, ${e.id}, ${r.org_id}::uuid, ${fireAt.toISOString()}::timestamptz, ${JSON.stringify(e)}::jsonb)
        on conflict (routine_id, event_id) do update set fire_at = excluded.fire_at, event = excluded.event
          where public.calendar_fires.fired_at is null
        returning routine_id`);
      scheduled += rows.length;
    }
  }
  return scheduled;
}
