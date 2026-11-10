import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";

/** Device connections (D-149): data the user shares from their phone and computer. */
export const DeviceKind = z
  .enum(["calendar", "reminders", "contacts", "places", "photos", "health", "notifications", "activity"])
  .openapi("DeviceKind");

export const DeviceKindSettings = z
  .object({
    retention_days: z.number().int().min(0).max(365).optional().openapi({ description: "0 keeps nothing (live only); the default is 365 for daily summaries, 90 for places and notifications" }),
    private_model: z.boolean().optional().openapi({ description: "Only bots on a private (local) model may read this kind" }),
    extras: z
      .array(z.enum(["cycle", "glucose", "blood_pressure"]))
      .optional()
      .openapi({ description: "Health only: sensitive extras the person turned on (off by default)" }),
    apps: z
      .array(z.string().trim().min(1).max(200))
      .max(50)
      .optional()
      .openapi({ description: "Notifications only: the apps (names or package ids) whose notifications are shared; nothing else is" }),
  })
  .openapi("DeviceKindSettings");

export const DeviceSource = z
  .object({
    id: Uuid,
    device_key: z.string(),
    name: z.string(),
    platform: z.enum(["ios", "android", "macos", "windows", "linux", "web"]),
    kinds: z.record(z.string(), DeviceKindSettings),
    last_seen_at: z.iso.datetime({ offset: true }),
    created_at: z.iso.datetime({ offset: true }),
  })
  .openapi("DeviceSource");

export const SaveDeviceSourceRequest = z
  .object({
    name: z.string().trim().min(1).max(80),
    platform: z.enum(["ios", "android", "macos", "windows", "linux", "web"]),
    kinds: z.partialRecord(DeviceKind, DeviceKindSettings).openapi({ description: "The kinds turned on; a kind left out is turned off and its data deleted" }),
  })
  .openapi("SaveDeviceSourceRequest");

export const DeviceReadingInput = z
  .object({
    kind: DeviceKind,
    period_start: z.iso.datetime({ offset: true }),
    period_end: z.iso.datetime({ offset: true }),
    external_id: z.string().min(1).max(200),
    summary: z.record(z.string(), z.unknown()),
  })
  .openapi("DeviceReadingInput");

export const UploadDeviceReadingsRequest = z
  .object({
    readings: z.array(DeviceReadingInput).max(500),
    request_id: Uuid.optional().openapi({ description: "Answers this fresh-read request" }),
  })
  .openapi("UploadDeviceReadingsRequest");

export const DeviceReading = z
  .object({
    id: Uuid,
    source_id: Uuid,
    kind: DeviceKind,
    period_start: z.iso.datetime({ offset: true }),
    period_end: z.iso.datetime({ offset: true }),
    external_id: z.string(),
    summary: z.record(z.string(), z.unknown()),
    collected_at: z.iso.datetime({ offset: true }),
  })
  .openapi("DeviceReading");

export const DeviceRequest = z
  .object({
    id: Uuid,
    source_id: Uuid,
    kind: z.string(),
    action: z.enum(["read", "calendar.create", "reminders.create", "locate"]),
    params: z.record(z.string(), z.unknown()),
    created_at: z.iso.datetime({ offset: true }),
  })
  .openapi("DeviceRequest");

export const DeviceRequestResult = z
  .object({ ok: z.boolean(), result: z.record(z.string(), z.unknown()).optional(), error: z.string().max(1000).optional() })
  .openapi("DeviceRequestResult");

export const DeviceGrant = z
  .object({ bot_id: Uuid, bot_name: z.string(), kind: DeviceKind, created_at: z.iso.datetime({ offset: true }) })
  .openapi("DeviceGrant");

export const SetDeviceGrantRequest = z.object({ bot_id: Uuid, kind: DeviceKind, allowed: z.boolean() }).openapi("SetDeviceGrantRequest");

/**
 * Health summaries (D-150). Strict shapes: devices send daily and per-workout summaries only, so raw
 * samples (heart-rate series, sleep segments) never reach the server or a model.
 */
const n = z.number().finite();
export const HealthDaySummary = z
  .object({
    type: z.literal("day"),
    date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
    sleep: z
      .object({
        start: z.string().max(40).optional(),
        end: z.string().max(40).optional(),
        minutes: n.min(0).max(1440),
        stages: z.object({ deep: n.min(0).optional(), rem: n.min(0).optional(), light: n.min(0).optional(), awake: n.min(0).optional() }).strict().optional(),
      })
      .strict()
      .optional(),
    steps: n.min(0).optional(),
    active_energy_kcal: n.min(0).optional(),
    workouts: n.int().min(0).optional(),
    resting_hr: n.min(0).max(300).optional(),
    hrv_ms: n.min(0).max(500).optional(),
    weight_kg: n.min(0).max(700).optional(),
    cycle: z.object({ flow: z.string().max(20).optional(), day: n.int().min(1).max(100).optional() }).strict().optional(),
    glucose: z.object({ avg_mg_dl: n.min(0), min_mg_dl: n.min(0).optional(), max_mg_dl: n.min(0).optional() }).strict().optional(),
    blood_pressure: z.object({ systolic: n.min(0), diastolic: n.min(0) }).strict().optional(),
  })
  .strict()
  .openapi("HealthDaySummary");

export const HealthWorkoutSummary = z
  .object({
    type: z.literal("workout"),
    activity: z.string().max(60),
    start: z.string().max(40),
    end: z.string().max(40),
    minutes: n.min(0).max(2880),
    energy_kcal: n.min(0).optional(),
    distance_m: n.min(0).optional(),
    avg_hr: n.min(0).max(300).optional(),
  })
  .strict()
  .openapi("HealthWorkoutSummary");

export const HealthSummary = z.discriminatedUnion("type", [HealthDaySummary, HealthWorkoutSummary]);

/** Device triggers (D-151): what a device reports. Places are named; no coordinates are sent. */
export const DeviceEventInput = z
  .object({
    id: z.string().min(1).max(200).openapi({ description: "Unique per event on the device, so a retry never fires twice" }),
    type: z.enum(["wake", "arrive", "leave", "workout_ended", "notification", "focus_on", "focus_off", "file_added", "driving_on", "driving_off"]),
    at: z.iso.datetime({ offset: true }),
    place: z.string().max(60).optional(),
    app: z.string().max(200).optional(),
    title: z.string().max(300).optional(),
    text: z.string().max(2000).optional(),
    folder: z.string().max(200).optional().openapi({ description: "file_added: the watched folder's name (Downloads)" }),
    name: z.string().max(300).optional().openapi({ description: "file_added: the new file's name" }),
  })
  .openapi("DeviceEventInput");

export const ReportDeviceEventsRequest = z.object({ events: z.array(DeviceEventInput).max(50) }).openapi("ReportDeviceEventsRequest");

export const DevicePlace = z
  .object({
    id: Uuid,
    name: z.string(),
    latitude: z.number(),
    longitude: z.number(),
    radius_m: z.number().int(),
    created_at: z.iso.datetime({ offset: true }),
  })
  .openapi("DevicePlace");

export const SaveDevicePlaceRequest = z
  .object({
    name: z.string().trim().min(1).max(60),
    latitude: z.number().min(-90).max(90),
    longitude: z.number().min(-180).max(180),
    radius_m: z.number().int().min(50).max(2000).optional(),
  })
  .openapi("SaveDevicePlaceRequest");

/**
 * Activity recap (D-152): one summary per hour of front-app time and window titles, kept by the
 * desktop app. Strict, so screenshots or keystrokes have nowhere to go.
 */
export const ActivitySummary = z
  .object({
    type: z.literal("hour"),
    hour: z.string().regex(/^\d{4}-\d{2}-\d{2}T\d{2}$/),
    total_minutes: n.min(0).max(60),
    apps: z
      .array(z.object({ app: z.string().max(100), minutes: n.min(0).max(60), titles: z.array(z.string().max(120)).max(5).optional() }).strict())
      .max(30),
  })
  .strict()
  .openapi("ActivitySummary");
