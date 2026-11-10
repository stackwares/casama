/**
 * Device triggers (SPEC: Device triggers; D-151). Events from a person's own devices start the
 * routines that person created: wake up, arrive at or leave a named place, leave now for the next
 * event, a finished workout, a notification from a watched app, Focus on or off. A wake-up also
 * brings the morning brief forward (check-ins, D-114).
 */
import { checkinCapReached, type MapsProvider, travelMinutes } from "@kasama/agent";
import type { Database } from "@kasama/db";
import { sql } from "drizzle-orm";
import { createRoutineRun } from "./routines.ts";

export type DeviceEventType =
  | "wake"
  | "arrive"
  | "leave"
  | "leave_now"
  | "workout_ended"
  | "notification"
  | "focus_on"
  | "focus_off"
  | "file_added"
  | "driving_on"
  | "driving_off";
export interface DeviceEvent {
  id: string;
  type: DeviceEventType;
  at: string;
  place?: string;
  app?: string;
  title?: string;
  text?: string;
  folder?: string;
  name?: string;
  /** Extra context for the run (leave-now: the event and travel time). */
  detail?: string;
}

/** One-time codes in notification text are masked (devices mask them too). */
export function maskCodes(text: string): string {
  return text.replace(/\b(?=[A-Z0-9-]*\d)[A-Z0-9]{3,4}-?[A-Z0-9]{3,4}\b|\b\d{4,8}\b/g, "••••");
}

const time = (iso: string) => new Date(iso).toISOString().slice(11, 16);
export function describeDeviceEvent(e: DeviceEvent): string {
  switch (e.type) {
    case "wake":
      return `The person woke up (at ${time(e.at)} UTC).`;
    case "arrive":
      return `The person arrived at ${e.place} (at ${time(e.at)} UTC).`;
    case "leave":
      return `The person left ${e.place} (at ${time(e.at)} UTC).`;
    case "leave_now":
      return e.detail ?? "It's time to leave for the next event.";
    case "workout_ended":
      return `The person finished a workout${e.title ? ` (${e.title})` : ""} at ${time(e.at)} UTC.`;
    case "notification":
      return `A notification from ${e.app}: ${maskCodes([e.title, e.text].filter(Boolean).join(" — "))}`;
    case "focus_on":
      return `The person turned on Focus / Do Not Disturb${e.title ? ` (${e.title})` : ""}.`;
    case "focus_off":
      return "The person turned off Focus / Do Not Disturb.";
    case "driving_on":
      return "The person started driving.";
    case "driving_off":
      return "The person stopped driving.";
    case "file_added":
      return `A new file arrived in the watched folder ${e.folder}: ${e.name}. It's on the person's own computer.`;
  }
}

type RoutineRow = Parameters<typeof createRoutineRun>[1] & {
  trigger: {
    type?: string;
    event?: string;
    place?: string;
    app?: string;
    folder?: string;
    pattern?: string;
  };
  kind?: string;
  last_run_at?: Date | null;
};

/** "*.pdf", "Invoice-*" → a case-insensitive whole-name match. */
export function matchesPattern(name: string, pattern: string): boolean {
  const re = pattern
    .replace(/[.+^${}()|[\]\\]/g, "\\$&")
    .replace(/\*/g, ".*")
    .replace(/\?/g, ".");
  return new RegExp(`^${re}$`, "i").test(name);
}

/**
 * Starts the person's routines for one event (once per event id). Returns the new run ids, for the
 * caller to start.
 */
export async function fireDeviceEvent(
  db: Database,
  userId: string,
  e: DeviceEvent,
): Promise<string[]> {
  return db.transaction(async (tx) => {
    const fresh = await tx.execute(sql`
      insert into public.device_event_log (user_id, event_id, type) values (${userId}::uuid, ${e.id}, ${e.type})
      on conflict do nothing returning event_id`);
    if (!fresh.length) return [];
    const routines = await tx.execute<RoutineRow>(sql`
      select * from public.routines where enabled and created_by = ${userId}::uuid
        and ((trigger ->> 'type' = 'device' and trigger ->> 'event' = ${e.type})
          or (${e.type} = 'wake' and kind = 'brief'))
      for update`);
    const runIds: string[] = [];
    for (const r of routines) {
      const t = r.trigger ?? {};
      if (t.place && (e.place ?? "").toLowerCase() !== t.place.toLowerCase()) continue;
      if (t.app && !(e.app ?? "").toLowerCase().includes(t.app.toLowerCase())) continue;
      if (t.folder && (e.folder ?? "").toLowerCase() !== t.folder.toLowerCase()) continue;
      if (t.pattern && !matchesPattern(e.name ?? "", t.pattern)) continue;
      // Wake-ups and briefs: once a morning.
      if (
        (e.type === "wake" || r.kind === "brief") &&
        r.last_run_at &&
        Date.now() - new Date(r.last_run_at).getTime() < 14 * 3600_000
      )
        continue;
      if (
        (r.kind === "brief" || r.kind === "scan") &&
        (await checkinCapReached(tx as Database, r.bot_id))
      )
        continue;
      runIds.push(await createRoutineRun(tx, r, "device", describeDeviceEvent(e)));
    }
    return runIds;
  });
}

export interface LeaveNowDeps {
  fetch: typeof fetch;
  bases?: { google_maps?: string; mapbox?: string };
  /** The workspace's maps key. */
  mapsKey: (orgId: string) => Promise<{ provider: MapsProvider; key: string } | null>;
  now?: () => Date;
}

type CalEvent = { title?: string; start?: string; location?: string };

/** Travel times worked out recently, per event (so the maps API is asked at most every 10 minutes). */
const travelCache = new Map<string, { minutes: number; at: number }>();
/** Leave-now only looks at events starting within this window (the location is asked for then too). */
const LEAVE_NOW_WINDOW_MIN = 120;

/**
 * Leave-now (run by the worker each minute): for each such routine, the creator's next calendar
 * event with a location in the next 3 hours; where they are now (a one-off read from an online
 * device, cleared once used); the travel time; and a run once it's time to go.
 */
export async function checkLeaveNow(db: Database, deps: LeaveNowDeps): Promise<string[]> {
  const now = deps.now?.() ?? new Date();
  const runIds: string[] = [];
  // "Where am I now" answers never outlive 10 minutes.
  await db.execute(
    sql`delete from public.device_requests where action = 'locate' and created_at < ${new Date(now.getTime() - 10 * 60_000).toISOString()}::timestamptz`,
  );
  const routines = await db.execute<{
    id: string;
    org_id: string;
    created_by: string;
    trigger: { minutes_before?: number };
  }>(sql`
    select id, org_id, created_by, trigger from public.routines
    where enabled and created_by is not null and trigger ->> 'type' = 'device' and trigger ->> 'event' = 'leave_now'`);
  for (const r of routines) {
    // One routine's failure (a maps or database error) never drops the others' runs (audit 2026-11).
    try {
      await (async () => {
        const days = await db.execute<{ summary: { events?: CalEvent[] } }>(sql`
          select summary from public.device_readings where user_id = ${r.created_by}::uuid and kind = 'calendar'
            and period_end >= ${now.toISOString()}::timestamptz and period_start <= ${new Date(now.getTime() + 3 * 3600_000).toISOString()}::timestamptz`);
        const next = days
          .flatMap((d) => d.summary?.events ?? [])
          .filter(
            (ev) =>
              ev.location &&
              ev.start &&
              new Date(ev.start) > now &&
              new Date(ev.start).getTime() - now.getTime() <= LEAVE_NOW_WINDOW_MIN * 60_000,
          )
          .sort((a, b) => String(a.start).localeCompare(String(b.start)))[0];
        if (!next?.start || !next.location) return;
        const eventId = `leave_now:${r.id}:${next.start}:${(next.title ?? "").slice(0, 60)}`;
        const [seen] = await db.execute(
          sql`select 1 from public.device_event_log where user_id = ${r.created_by}::uuid and event_id = ${eventId}`,
        );
        if (seen) return;
        // Where the person is now: a live read, never stored as a trail.
        const [loc] = await db.execute<{
          id: string;
          status: string;
          result: { lat?: number; lng?: number } | null;
        }>(sql`
          select id, status, result from public.device_requests where user_id = ${r.created_by}::uuid and action = 'locate'
            and created_at > ${new Date(now.getTime() - 10 * 60_000).toISOString()}::timestamptz order by created_at desc limit 1`);
        if (!loc) {
          const [src] = await db.execute<{ id: string }>(sql`
            select id from public.device_sources where user_id = ${r.created_by}::uuid and kinds ? 'places'
              and last_seen_at > ${new Date(now.getTime() - 60 * 60_000).toISOString()}::timestamptz order by last_seen_at desc limit 1`);
          if (src)
            await db.execute(
              sql`insert into public.device_requests (user_id, source_id, kind, action) values (${r.created_by}::uuid, ${src.id}::uuid, 'places', 'locate')`,
            );
          return;
        }
        if (
          loc.status !== "done" ||
          typeof loc.result?.lat !== "number" ||
          typeof loc.result?.lng !== "number"
        )
          return;
        const cached = travelCache.get(eventId);
        let minutes: number | null =
          cached && now.getTime() - cached.at < 10 * 60_000 ? cached.minutes : null;
        if (minutes === null) {
          const maps = await deps.mapsKey(r.org_id);
          if (!maps) return;
          minutes = await travelMinutes(
            maps.provider,
            maps.key,
            { lat: loc.result.lat, lng: loc.result.lng },
            next.location,
            { fetch: deps.fetch, bases: deps.bases },
          ).catch(() => null);
          if (minutes === null) return;
          travelCache.set(eventId, { minutes, at: now.getTime() });
          if (travelCache.size > 5000)
            travelCache.delete(travelCache.keys().next().value as string);
        }
        const buffer = r.trigger.minutes_before ?? 5;
        const leaveAt = new Date(next.start).getTime() - (minutes + buffer) * 60_000;
        if (now.getTime() < leaveAt) return;
        // Used: the location goes.
        await db.execute(
          sql`update public.device_requests set result = null where id = ${loc.id}::uuid`,
        );
        travelCache.delete(eventId);
        runIds.push(
          ...(await fireDeviceEvent(db, r.created_by, {
            id: eventId,
            type: "leave_now",
            at: now.toISOString(),
            detail: `Time to leave for "${next.title ?? "the next event"}" at ${next.location}, which starts at ${time(next.start)} UTC. Travel takes about ${minutes} minutes from where the person is now.`,
          })),
        );
      })();
    } catch (err) {
      console.error(
        JSON.stringify({
          msg: "leave-now check failed",
          routine_id: r.id,
          error: (err as Error).message,
        }),
      );
    }
  }
  return runIds;
}
