/**
 * System permissions a bot may need on the person's own devices (D-376, docs/OS-PERMISSIONS-PLAN.md).
 *
 * Two gates guard a device: Casama's own grant (may this bot read my calendar, D-149/D-328) and
 * the operating system's permission (may the Casama app use the calendar at all). This file is
 * about the second. The app keeps the same table in Dart (`client/lib/features/permissions/`),
 * which is where checking, asking and opening settings actually happen.
 *
 * Only permissions Casama's builds declare are listed (Info.plist usage strings, the Android
 * manifest, macOS entitlements): a row the build can't turn on would be a dead end. Adding one
 * here belongs with the feature that needs it, together with its declaration.
 *
 * Ids are plain strings on the wire, so a newer server can name a permission an older app doesn't
 * know; the app then shows "Update Casama" for that row instead of failing.
 */

export const OS_PERMISSION_PLATFORMS = [
  "ios",
  "android",
  "macos",
  "windows",
  "linux",
  "web",
] as const;
export type OsPermissionPlatform = (typeof OS_PERMISSION_PLATFORMS)[number];

/**
 * How a platform lets the app get a permission:
 * - `prompt`: the system can ask once; after a "no" only its settings can change it.
 * - `settings`: only the system's settings can turn it on (no prompt exists).
 * - `casama`: it's one of Casama's own settings, changed in the app.
 */
export type OsPermissionAsk = "prompt" | "settings" | "casama";

export interface OsPermissionInfo {
  id: string;
  /** Short name for the card's row. */
  label: string;
  /** What it lets a bot do, in plain words; the default reason on a card. */
  why: string;
  /** Platforms that have it, and how it's asked for there. A platform not listed doesn't have it. */
  platforms: Partial<Record<OsPermissionPlatform, OsPermissionAsk>>;
  /** Platforms where a change only takes effect after Casama restarts. */
  relaunch?: OsPermissionPlatform[];
}

export const OS_PERMISSIONS = [
  {
    id: "location",
    label: "Location",
    why: "So I can use where you are",
    platforms: { ios: "prompt", android: "prompt", web: "prompt" },
  },
  {
    id: "location_always",
    label: "Location in the background",
    why: "So I can notice when you arrive or leave places",
    platforms: { ios: "prompt", android: "prompt" },
  },
  {
    id: "camera",
    label: "Camera",
    why: "So I can see through your camera when you ask",
    platforms: { ios: "prompt", web: "prompt" },
  },
  {
    id: "microphone",
    label: "Microphone",
    why: "So you can talk to me",
    platforms: {
      ios: "prompt",
      android: "prompt",
      macos: "prompt",
      windows: "settings",
      web: "prompt",
    },
  },
  {
    id: "speech",
    label: "Speech recognition",
    why: "So I can turn what you say into text",
    platforms: { ios: "prompt", macos: "prompt" },
  },
  {
    id: "photos",
    label: "Photos",
    why: "So I can find and use your photos",
    platforms: { ios: "prompt" },
  },
  {
    id: "contacts",
    label: "Contacts",
    why: "So I can look up the people you mention",
    platforms: { ios: "prompt", android: "prompt", macos: "prompt" },
  },
  {
    id: "calendar",
    label: "Calendars",
    why: "So I can see and add events",
    platforms: { ios: "prompt", android: "prompt" },
  },
  {
    id: "health",
    label: "Health",
    why: "So I can use your health summaries",
    platforms: { ios: "prompt", android: "prompt" },
  },
  {
    id: "notifications",
    label: "Notifications",
    why: "So I can let you know when something's ready",
    platforms: {
      ios: "prompt",
      android: "prompt",
      macos: "prompt",
      windows: "settings",
      web: "prompt",
    },
  },
  {
    id: "notification_access",
    label: "Notification access",
    why: "So I can read the notifications you share",
    platforms: { android: "settings" },
  },
  {
    id: "accessibility",
    label: "Accessibility",
    why: "So I can see and click in your apps",
    platforms: { macos: "prompt" },
  },
  {
    id: "screen_recording",
    label: "Screen Recording",
    why: "So I can take screenshots of your screen",
    platforms: { macos: "prompt" },
    relaunch: ["macos"],
  },
  {
    id: "automation",
    label: "Automation",
    why: "So I can control other apps for you",
    platforms: { macos: "prompt" },
  },
  {
    id: "full_disk",
    label: "Full Disk Access",
    why: "So I can open files in protected folders",
    platforms: { macos: "settings" },
  },
  {
    id: "shared_folders",
    label: "Shared folders",
    why: "So I can work with your files",
    platforms: { macos: "casama", windows: "casama", linux: "casama" },
  },
  {
    id: "local_tools",
    label: "Local tools",
    why: "So I can use the tools you run on this computer",
    platforms: { macos: "casama", windows: "casama", linux: "casama" },
  },
] as const satisfies readonly OsPermissionInfo[];

export type OsPermissionId = (typeof OS_PERMISSIONS)[number]["id"];
export const OS_PERMISSION_IDS = OS_PERMISSIONS.map((p) => p.id) as OsPermissionId[];

/**
 * What a device reports for each permission, without prompting:
 * granted · limited (iOS photos, Android approximate location) · denied (said no or turned off) ·
 * not_asked (the system would still prompt) · restricted (parental controls, MDM) ·
 * unknown (the system can't tell without trying, e.g. local network) · unavailable (not on this
 * device or this build).
 */
export const OS_PERMISSION_STATES = [
  "granted",
  "limited",
  "denied",
  "not_asked",
  "restricted",
  "unknown",
  "unavailable",
] as const;
export type OsPermissionState = (typeof OS_PERMISSION_STATES)[number];

/** What a card's button asks a device to do. */
export const OS_PERMISSION_ACTIONS = ["request", "open_settings", "relaunch"] as const;
export type OsPermissionAction = (typeof OS_PERMISSION_ACTIONS)[number];

const BY_ID = new Map<string, OsPermissionInfo>(OS_PERMISSIONS.map((p) => [p.id, p]));

export function osPermission(id: string): OsPermissionInfo | undefined {
  return BY_ID.get(id);
}

/** Casama's platform names for devices ("macos", "ios", …) mapped onto the table's columns. */
export function osPermissionPlatform(platform: string): OsPermissionPlatform | null {
  const p = platform.toLowerCase();
  if (p === "mac" || p === "darwin") return "macos";
  if (p === "chrome" || p === "browser") return "web";
  return (OS_PERMISSION_PLATFORMS as readonly string[]).includes(p)
    ? (p as OsPermissionPlatform)
    : null;
}

/** Whether a device on this platform can have the permission at all. */
export function osPermissionOn(id: string, platform: string): boolean {
  const p = osPermissionPlatform(platform);
  return !!p && !!osPermission(id)?.platforms[p];
}

/** A state that still blocks the bot (limited counts as usable). */
export function osPermissionMissing(state: string | undefined): boolean {
  return state === "denied" || state === "not_asked" || state === "restricted";
}

/** "Accessibility and Screen Recording", "Location, Camera and Photos". */
export function osPermissionList(ids: readonly string[]): string {
  const names = ids.map((id) => osPermission(id)?.label ?? id);
  if (names.length <= 1) return names[0] ?? "";
  return `${names.slice(0, -1).join(", ")} and ${names[names.length - 1]}`;
}

/** A device a card is about: `computer:<local_devices.id>` or `source:<device_sources.id>`. */
export type DeviceRefType = "computer" | "source";
export const deviceRef = (type: DeviceRefType, id: string) => `${type}:${id}`;
export function parseDeviceRef(ref: string): { type: DeviceRefType; id: string } | null {
  const m = /^(computer|source):([0-9a-f-]{36})$/i.exec(ref);
  return m ? { type: m[1] as DeviceRefType, id: m[2]!.toLowerCase() } : null;
}

/**
 * Device data kinds (D-149) and the system permission each one needs on a platform, when Casama's
 * build for that platform asks for one. Notifications on iOS and macOS aren't readable at all;
 * computer activity needs Accessibility for window titles on a Mac.
 */
export function osPermissionForKind(kind: string, platform: string): OsPermissionId | null {
  const p = osPermissionPlatform(platform);
  const pick: Record<string, OsPermissionId | undefined> = {
    calendar: "calendar",
    contacts: "contacts",
    places: p === "ios" || p === "android" ? "location_always" : "location",
    photos: "photos",
    health: "health",
    notifications: p === "android" ? "notification_access" : undefined,
    activity: p === "macos" ? "accessibility" : undefined,
  };
  const id = pick[kind];
  return id && osPermissionOn(id, platform) ? id : null;
}

/**
 * The permission a failed tool on someone's own computer points at, from its error. Only clear
 * signals count: agent-desktop's PERM_DENIED names the permission in its message (checked
 * against agent-desktop 1.3.1 on macOS 27), computerd and the desktop context tools use fixed
 * codes, and an MCP server may name one with `casama_permission` (passed through as the code
 * `permission_needed:<id>`).
 */
export function osPermissionsFromToolError(code: string, message: string): OsPermissionId[] {
  const c = code.toLowerCase();
  const named = /^permission_needed:([a-z_]+)$/.exec(c);
  if (named) return BY_ID.has(named[1]!) ? [named[1] as OsPermissionId] : [];
  if (c === "no_folders") return ["shared_folders"];
  if (c === "screen_recording_denied") return ["screen_recording"];
  if (c === "perm_denied" || c === "permission_denied") {
    const m = message.toLowerCase();
    const out: OsPermissionId[] = [];
    if (/screen ?recording|screen capture/.test(m)) out.push("screen_recording");
    if (/accessibility|device control/.test(m)) out.push("accessibility");
    if (/automation|apple ?events/.test(m)) out.push("automation");
    return out;
  }
  return [];
}
