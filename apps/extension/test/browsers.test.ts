/**
 * Phase 5 (plan §13): Edge takes the Chrome package as it is; Firefox gets its own manifest from
 * the same code, without Act or the browser as a device.
 */
import { describe, expect, it } from "vitest";
import { browserName, FEATURES, productName, shortcutsUrl } from "../src/lib/browser.ts";
import { buildManifest, FIREFOX_MIN_VERSION, GECKO_ID } from "../src/manifest.ts";

const EDGE =
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36 Edg/142.0.0.0";
const CHROME =
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36";
const FIREFOX =
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:145.0) Gecko/20100101 Firefox/145.0";

describe("which browser", () => {
  it("names Chrome, Edge and Firefox from the user agent", () => {
    expect(browserName(CHROME)).toBe("Chrome");
    expect(browserName(EDGE)).toBe("Edge");
    expect(browserName(FIREFOX)).toBe("Firefox");
    expect(productName("Edge")).toBe("Casama for Edge");
  });

  it("sends people to each browser's shortcut settings", () => {
    expect(shortcutsUrl("Chrome")).toBe("chrome://extensions/shortcuts");
    expect(shortcutsUrl("Edge")).toBe("edge://extensions/shortcuts");
  });

  it("keeps every feature in the Chromium build (this test run is one)", () => {
    expect(Object.values(FEATURES).every(Boolean)).toBe(true);
  });
});

describe("Firefox's manifest", () => {
  const m = buildManifest("store", "0.1.0", "firefox") as unknown as Record<string, unknown> & {
    permissions: string[];
    optional_permissions: string[];
    commands: Record<string, { description?: string }>;
    browser_specific_settings: {
      gecko: {
        id: string;
        strict_min_version: string;
        data_collection_permissions: { required: string[]; optional: string[] };
      };
    };
  };

  it("has the sidebar and a background script, not the side panel and a service worker", () => {
    expect(m.sidebar_action).toMatchObject({ default_panel: "panel/panel.html" });
    expect(m.side_panel).toBeUndefined();
    expect(m.background).toEqual({ scripts: ["background.js"], type: "module" });
    expect(m.options_ui).toEqual({ page: "options/options.html", open_in_tab: true });
    expect(m.options_page).toBeUndefined();
  });

  it("asks for nothing Act, the device or Chrome-only APIs need", () => {
    for (const p of ["debugger", "tabGroups", "tabCapture", "sidePanel", "offscreen", "gcm"])
      expect(m.permissions).not.toContain(p);
    expect(m.permissions).toContain("identity");
    expect(m.optional_permissions).toEqual(["tabs", "bookmarks"]);
    expect(m.host_permissions).toBeUndefined();
    expect(m.optional_host_permissions).toEqual(["https://*/*", "http://*/*"]);
    // Firefox has no externally_connectable, no managed schema for Act's settings, and no key.
    expect(m.externally_connectable).toBeUndefined();
    expect(m.storage).toBeUndefined();
    expect(m.key).toBeUndefined();
    expect(m.minimum_chrome_version).toBeUndefined();
  });

  it("carries Firefox's id, its minimum version and the data it says it sends", () => {
    const gecko = m.browser_specific_settings.gecko;
    expect(gecko.id).toBe(GECKO_ID);
    expect(gecko.strict_min_version).toBe(FIREFOX_MIN_VERSION);
    expect(gecko.data_collection_permissions.required).toEqual([
      "authenticationInfo",
      "personalCommunications",
      "websiteContent",
    ]);
    expect(gecko.data_collection_permissions.optional).toEqual(["bookmarksInfo"]);
  });

  it("opens the sidebar from the first shortcut", () => {
    expect(Object.keys(m.commands)).toEqual([
      "_execute_sidebar_action",
      "ask-selection",
      "screenshot",
      "save-page",
    ]);
    expect(m.commands._execute_sidebar_action?.description).toBe("Open Casama");
  });

  it("gives the e2e build its permissions up front, as Chrome's e2e build has", () => {
    const e2e = buildManifest("e2e", "0.1.0", "firefox");
    expect(e2e.host_permissions).toEqual(["<all_urls>"]);
    expect(e2e.permissions).toContain("tabs");
    expect(e2e.name).toBe("Casama (dev)");
  });
});

describe("Edge", () => {
  it("takes the Chrome store package as it is", () => {
    expect(buildManifest("store", "0.1.0", "chromium")).toEqual(buildManifest("store", "0.1.0"));
  });
});
