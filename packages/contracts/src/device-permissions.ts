import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";

/**
 * System permissions on the person's own devices (D-376): what each device reports, and the card
 * buttons that ask a device to prompt, open its settings or restart Casama. The list of
 * permissions lives in @casama/domain (`OS_PERMISSIONS`); ids are plain strings here so a newer
 * server can name one an older app doesn't know.
 */
export const OsPermissionId = z
  .string()
  .regex(/^[a-z][a-z_]{0,39}$/)
  .openapi("OsPermissionId", {
    description:
      "location, location_always, camera, microphone, speech, photos, contacts, calendar, health, notifications, notification_access, accessibility, screen_recording, automation, full_disk, shared_folders, local_tools; more may come",
  });

export const OsPermissionState = z
  .enum(["granted", "limited", "denied", "not_asked", "restricted", "unknown", "unavailable"])
  .openapi("OsPermissionState", {
    description:
      "not_asked: the system would still prompt. limited: usable with limits (some photos, approximate location). unknown: can't tell without trying. unavailable: not on this device or build",
  });

export const DevicePermissionType = z.enum(["computer", "source"]).openapi("DevicePermissionType", {
  description:
    "computer: a computer used for bots (a local device, D-066); source: a device that shares data (D-149)",
});

export const DevicePermissions = z
  .object({
    device_ref: z.string().openapi({ description: "`computer:<id>` or `source:<id>`" }),
    type: DevicePermissionType,
    id: Uuid,
    name: z.string(),
    platform: z.string(),
    permissions: z.record(z.string(), OsPermissionState),
    /** When the device last reported them; null if it never has. */
    reported_at: z.iso.datetime({ offset: true }).nullable(),
    online: z.boolean(),
  })
  .openapi("DevicePermissions");

export const ReportDevicePermissionsRequest = z
  .object({
    /** Every permission the device knows, as it is now (the whole map replaces the old one). */
    permissions: z
      .record(OsPermissionId, OsPermissionState)
      .refine((m) => Object.keys(m).length <= 60, "At most 60 permissions"),
  })
  .openapi("ReportDevicePermissionsRequest");

export const AskDevicePermissionRequest = z
  .object({
    permission: OsPermissionId,
    do: z.enum(["request", "open_settings", "relaunch"]).openapi({
      description:
        "request: show the system prompt, or open settings if the system won't ask again; open_settings: open the page with the switch; relaunch: restart Casama on that device",
    }),
    bot_id: Uuid.optional().openapi({ description: "The bot whose card this came from" }),
  })
  .openapi("AskDevicePermissionRequest");

export const AskDevicePermissionResult = z
  .object({
    via: z.enum(["socket", "notification"]).openapi({
      description:
        "socket: the computer got it at once; notification: the phone gets a notification to tap (phones can't show a prompt from the background)",
    }),
  })
  .openapi("AskDevicePermissionResult");

export const SnoozeDevicePermissionsRequest = z
  .object({
    bot_id: Uuid,
    permissions: z.array(OsPermissionId).min(1).max(20),
  })
  .openapi("SnoozeDevicePermissionsRequest");
