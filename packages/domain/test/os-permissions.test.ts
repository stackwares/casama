import { describe, expect, it } from "vitest";
import {
  deviceRef,
  OS_PERMISSION_IDS,
  OS_PERMISSIONS,
  osPermissionForKind,
  osPermissionList,
  osPermissionMissing,
  osPermissionOn,
  osPermissionPlatform,
  osPermissionsFromToolError,
  parseDeviceRef,
} from "../src/os-permissions.ts";

describe("system permissions (D-376)", () => {
  it("has unique ids, labels, reasons and at least one platform each", () => {
    expect(new Set(OS_PERMISSION_IDS).size).toBe(OS_PERMISSIONS.length);
    for (const p of OS_PERMISSIONS) {
      expect(p.id).toMatch(/^[a-z][a-z_]{0,39}$/);
      expect(p.label.length).toBeGreaterThan(0);
      expect(p.why).toMatch(/^So /);
      expect(Object.keys(p.platforms).length).toBeGreaterThan(0);
    }
  });

  it("knows which platform has which permission", () => {
    expect(osPermissionOn("screen_recording", "macos")).toBe(true);
    expect(osPermissionOn("screen_recording", "ios")).toBe(false);
    expect(osPermissionOn("location", "ios")).toBe(true);
    expect(osPermissionOn("notification_access", "android")).toBe(true);
    expect(osPermissionOn("notification_access", "ios")).toBe(false);
    expect(osPermissionOn("shared_folders", "windows")).toBe(true);
    expect(osPermissionOn("nope", "macos")).toBe(false);
    expect(osPermissionOn("location", "toaster")).toBe(false);
    expect(osPermissionPlatform("Darwin")).toBe("macos");
    expect(osPermissionPlatform("web")).toBe("web");
  });

  it("maps device kinds to the permission each needs", () => {
    expect(osPermissionForKind("places", "ios")).toBe("location_always");
    // Android has no background location (D-414): Places there only reads location while open.
    expect(osPermissionForKind("places", "android")).toBe("location");
    expect(osPermissionOn("location_always", "android")).toBe(false);
    expect(osPermissionForKind("calendar", "android")).toBe("calendar");
    expect(osPermissionForKind("notifications", "android")).toBe("notification_access");
    expect(osPermissionForKind("notifications", "ios")).toBeNull();
    expect(osPermissionForKind("activity", "macos")).toBe("accessibility");
    // The Mac build doesn't declare calendars: no row it couldn't turn on.
    expect(osPermissionForKind("calendar", "macos")).toBeNull();
  });

  it("reads the permission out of a failed tool's error", () => {
    // agent-desktop 1.3.1's own words on macOS 27.
    expect(
      osPermissionsFromToolError("perm_denied", "Screen Recording permission not granted"),
    ).toEqual(["screen_recording"]);
    expect(
      osPermissionsFromToolError("perm_denied", "Accessibility permission not granted"),
    ).toEqual(["accessibility"]);
    expect(osPermissionsFromToolError("no_folders", "")).toEqual(["shared_folders"]);
    expect(osPermissionsFromToolError("screen_recording_denied", "")).toEqual(["screen_recording"]);
    expect(osPermissionsFromToolError("permission_needed:camera", "")).toEqual(["camera"]);
    expect(osPermissionsFromToolError("permission_needed:made_up", "")).toEqual([]);
    expect(osPermissionsFromToolError("perm_denied", "something else")).toEqual([]);
    expect(osPermissionsFromToolError("timeout", "Accessibility")).toEqual([]);
  });

  it("names lists and refs", () => {
    expect(osPermissionList(["accessibility", "screen_recording"])).toBe(
      "Accessibility and Screen Recording",
    );
    expect(osPermissionList(["location", "camera", "photos"])).toBe("Location, Camera and Photos");
    expect(osPermissionMissing("denied")).toBe(true);
    expect(osPermissionMissing("not_asked")).toBe(true);
    expect(osPermissionMissing("limited")).toBe(false);
    expect(osPermissionMissing(undefined)).toBe(false);
    const id = "8f14e45f-ceea-467e-a2a4-0a1b2c3d4e5f";
    expect(parseDeviceRef(deviceRef("computer", id))).toEqual({ type: "computer", id });
    expect(parseDeviceRef(`source:${id}`)).toEqual({ type: "source", id });
    expect(parseDeviceRef(`phone:${id}`)).toBeNull();
    expect(parseDeviceRef("computer:not-a-uuid")).toBeNull();
  });
});
