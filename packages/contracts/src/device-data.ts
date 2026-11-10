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
    action: z.enum(["read", "calendar.create", "reminders.create"]),
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
