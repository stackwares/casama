import { createHash } from "node:crypto";
import { describe, expect, it } from "vitest";
import { buildManifest, DEV_EXTENSION_ID, DEV_KEY } from "../src/manifest.ts";

describe("manifest", () => {
  it("keeps the store build to app.casama.ai, Phase 1's permissions, and no key", () => {
    const m = buildManifest("store", "0.1.0");
    expect(m.manifest_version).toBe(3);
    expect(m.key).toBeUndefined();
    // Plan §8: no host permissions at install; Phase 3 adds the debugger and tab groups (C2, C3).
    expect(m.permissions).toEqual([
      "storage",
      "sidePanel",
      "activeTab",
      "scripting",
      "contextMenus",
      "alarms",
      "offscreen",
      "notifications",
      // Google and Apple sign-in (no install warning).
      "identity",
      "gcm",
      "unlimitedStorage",
      "debugger",
      "tabGroups",
      // Phase 4: record this tab (B12).
      "tabCapture",
    ]);
    // G9: administrators' settings.
    expect((m as { storage?: unknown }).storage).toEqual({ managed_schema: "managed_schema.json" });
    expect(m.host_permissions).toBeUndefined();
    expect(m.optional_host_permissions).toEqual(["https://*/*", "http://*/*"]);
    // Asked only when a feature needs it: Phase 2's "@" tabs, Phase 4's browser as a device.
    expect(m.optional_permissions).toEqual([
      "tabs",
      "history",
      "bookmarks",
      "readingList",
      "downloads",
      "idle",
    ]);
    expect(Object.keys(m.commands ?? {})).toHaveLength(4);
    expect(m.omnibox).toEqual({ keyword: "ca" });
    expect(m.side_panel).toEqual({ default_path: "panel/panel.html" });
    expect(m.externally_connectable).toEqual({ matches: ["https://app.casama.ai/*"] });
    expect(m.name).toBe("__MSG_extName__");
  });

  it("gives the dev build its fixed id and local web app addresses", () => {
    const m = buildManifest("dev", "0.1.0");
    expect(m.key).toBe(DEV_KEY);
    const hex = createHash("sha256")
      .update(Buffer.from(DEV_KEY, "base64"))
      .digest("hex")
      .slice(0, 32);
    const id = [...hex].map((c) => String.fromCharCode(97 + Number.parseInt(c, 16))).join("");
    expect(id).toBe(DEV_EXTENSION_ID);
    expect(m.externally_connectable?.matches).toContain("http://localhost/*");
  });
});
