/**
 * The manifest, built per target (D-323):
 *
 * - **dev**: an unpacked build for development and the end-to-end tests. It carries [DEV_KEY], so
 *   its id is always [DEV_EXTENSION_ID], and the web app may also hand it a sign-in from local
 *   addresses and the -dev web app.
 * - **e2e**: the dev build with site access already granted, for the end-to-end tests only
 *   (Playwright can't click Chrome's permission prompt). Built into dist/e2e; never shipped.
 * - **store**: what goes to the Chrome Web Store. No key (the store gives the id), and only
 *   https://app.casama.ai may talk to it.
 *
 * Permissions (plan §8): the Phase 1 set, none of which reads pages by itself. Pages are read only
 * when asked, through activeTab or the site access the person picks at first run (optional host
 * permissions, asked for then, never at install). `notifications` is the one install warning.
 *
 * Phase 3 adds `debugger` (bots in your own browser, C2: the "accept new permissions" prompt the
 * store shows once, decision 2) and `tabGroups` (the bot's named group, C3; no warning). The
 * debugger is attached only to tabs in a bot's group, while it works, or to a tab being taught.
 * Phase 4 adds `tabCapture` (record this tab, B12; no warning) and optional permissions for the
 * browser as a device.
 *
 * Phase 5 (plan §13): Edge takes the store build as it is. Firefox gets its own manifest from the
 * same code ([firefoxManifest]): Ask, Capture and Stay in the loop, without Act or the browser as a
 * device (src/lib/browser.ts says what each browser offers).
 */
export type Target = "dev" | "store" | "e2e";

/** The browser family a build is for. Chrome, Edge, Brave and the rest share `chromium`. */
export type Browser = "chromium" | "firefox";

/** Firefox's id for Casama. Firefox needs one in the manifest; Mozilla's add-ons site keeps it. */
export const GECKO_ID = "casama@casama.ai";

/**
 * Firefox 140 (an ESR): Mozilla's data consent at install (`data_collection_permissions`), plus
 * `scripting` with worlds, `storage.session` and MV3 host permissions as asked.
 */
export const FIREFOX_MIN_VERSION = "140.0";

/**
 * Public key for the dev build. Anyone may copy it; it fixes the id, it doesn't prove anything.
 * When the Chrome Web Store item exists, replace it with the item's public key (dashboard:
 * Package, View public key) and DEV_EXTENSION_ID with the item's id, so every build has the id
 * the server and the web app allow (test/ids.test.ts checks they agree).
 */
export const DEV_KEY =
  "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAuab6v3EXkPtAJyDMpsF2jQwkLWdFfslW0DkwQSCn3D6VxAiD4sb9qIes5wH7tu4BPB6r1tMPNDvi7GWf/TC0NRUfj2dmGCWHnYN4rI9uRj2sQ5zqBbWMKQHvAaZ9sPaynPMZQPbfLdAQx2Mbc24znUb5Efivi3kBfYw+jnlSkRpa8fIvF7tVdlVqu8Mnix8P+1Mnu0hJ9oW/TQWzCa7/oXRSydnuVzWAr3GpEX9iJHvHb7X/wjICILE3vnY6pTfBJTCdPaRtgR02+ck+w2zTdRwnnTrrdNokcebzSX5fzTJSUs0JQqfaVrtaYfuXILQr03mQhfEpraynqjdSGOJQ+QIDAQAB";
export const DEV_EXTENSION_ID = "kkfppfhkjnenffibmnkphnbejidkmbkj";

/**
 * Edge Add-ons gives the same store zip its own id (it ignores the manifest key). Submitted
 * 2026-11-21 (store/edge/listing.md). The server and the web app allow it next to the Chrome id.
 */
export const EDGE_EXTENSION_ID = "danikigkoiofpcecjobopcgdflgcmchm";

/** Pages that may hand the extension a sign-in (route 1 in the plan, §9.2). */
export function webAppOrigins(target: Target): string[] {
  const store = ["https://app.casama.ai/*"];
  return target !== "store"
    ? [...store, "https://app-dev.casama.ai/*", "http://localhost/*", "http://127.0.0.1/*"]
    : store;
}

/** Phase 1's required permissions (§8). */
export const PERMISSIONS = [
  "storage",
  "sidePanel",
  "activeTab",
  "scripting",
  "contextMenus",
  "alarms",
  "offscreen",
  "notifications",
  // Google and Apple sign-in in a window the browser owns (no install warning).
  "identity",
  "gcm",
  // Offline saves (B5) can pass the 10 MB storage.local quota; no install warning.
  "unlimitedStorage",
];

/** Phase 3: bots in your own browser (C1–C15). */
export const ACT_PERMISSIONS = ["debugger", "tabGroups"];

/** Phase 4: record this tab (B12). No install warning. */
export const CAPTURE_PERMISSIONS = ["tabCapture"];

/**
 * Asked for only when a feature that needs it is turned on (plan §8): `tabs` ("@" tabs, the tab in
 * front, triggers, the recap), `history` and `bookmarks` (history search, B11, bookmark triggers),
 * `readingList` (B11), `downloads` (download triggers) and `idle` (the recap counts only time at
 * the computer).
 */
export const OPTIONAL_PERMISSIONS = [
  "tabs",
  "history",
  "bookmarks",
  "readingList",
  "downloads",
  "idle",
];

/** Four shortcuts, Chrome's most (A8). People change them at chrome://extensions/shortcuts. */
export const COMMANDS: chrome.runtime.ManifestV3["commands"] = {
  _execute_action: {
    suggested_key: { default: "Alt+Shift+C" },
    description: "Open Casama",
  },
  "ask-selection": {
    suggested_key: { default: "Alt+Shift+A" },
    description: "Ask about the selection",
  },
  screenshot: {
    suggested_key: { default: "Alt+Shift+S" },
    description: "Send a screenshot to a bot",
  },
  "save-page": {
    suggested_key: { default: "Alt+Shift+L" },
    description: "Save the page to the Library",
  },
};

export function buildManifest(
  target: Target,
  version: string,
  browser: Browser = "chromium",
): chrome.runtime.ManifestV3 {
  if (browser === "firefox") return firefoxManifest(target, version);
  const icons = {
    "16": "icons/icon-16.png",
    "32": "icons/icon-32.png",
    "48": "icons/icon-48.png",
    "128": "icons/icon-128.png",
  };
  return {
    manifest_version: 3,
    name: target === "store" ? "__MSG_extName__" : "Casama (dev)",
    description: "__MSG_extDescription__",
    default_locale: "en",
    version,
    minimum_chrome_version: "116",
    icons,
    action: { default_title: "__MSG_actionTitle__", default_icon: icons },
    background: { service_worker: "background.js", type: "module" },
    options_page: "options/options.html",
    side_panel: { default_path: "panel/panel.html" },
    // The e2e build also has the optional permissions already, since Playwright can't click
    // Chrome's prompt.
    permissions: (target === "e2e"
      ? [...PERMISSIONS, ...ACT_PERMISSIONS, ...CAPTURE_PERMISSIONS, ...OPTIONAL_PERMISSIONS]
      : [
          ...PERMISSIONS,
          ...ACT_PERMISSIONS,
          ...CAPTURE_PERMISSIONS,
        ]) as chrome.runtime.ManifestPermission[],
    // G9: settings an administrator can set through Chrome's policies (lib/act/managed.ts).
    storage: { managed_schema: "managed_schema.json" },
    // Phase 2: `tabs` for "@" other tabs and "send these tabs", asked when first used. Phase 4:
    // the browser as a device, each asked when its switch is turned on.
    optional_permissions: OPTIONAL_PERMISSIONS as chrome.runtime.ManifestOptionalPermission[],
    optional_host_permissions: ["https://*/*", "http://*/*"],
    ...(target === "e2e" ? { host_permissions: ["<all_urls>"] } : {}),
    externally_connectable: { matches: webAppOrigins(target) },
    commands: COMMANDS,
    omnibox: { keyword: "ca" },
    content_security_policy: {
      extension_pages: "script-src 'self'; object-src 'self'",
    },
    ...(target === "store" ? {} : { key: DEV_KEY }),
  };
}

/** What Firefox can't do, so its build doesn't ask for it (plan §13). */
// identity: provider sign-in waits until servers allow Firefox's redirect address (plan §19).
const NOT_IN_FIREFOX = new Set(["sidePanel", "offscreen", "gcm", "identity"]);

/**
 * Firefox's manifest. Same pages and scripts; the sidebar instead of the side panel, a background
 * script instead of a service worker, its own id, and Mozilla's data consent at install:
 * page content, messages to bots and the sign-in go to the person's Casama server; bookmarks only
 * if they bring them in (asked then). No Act (`debugger`, `tabGroups`), no tab capture, no device
 * kinds, no `externally_connectable` (Firefox has none), no managed settings (Act's).
 */
function firefoxManifest(target: Target, version: string): chrome.runtime.ManifestV3 {
  const icons = {
    "16": "icons/icon-16.png",
    "32": "icons/icon-32.png",
    "48": "icons/icon-48.png",
    "128": "icons/icon-128.png",
  };
  const { _execute_action, ...commands } = COMMANDS ?? {};
  const optional = ["tabs", "bookmarks"];
  const permissions = PERMISSIONS.filter((p) => !NOT_IN_FIREFOX.has(p));
  return {
    manifest_version: 3,
    name: target === "store" ? "__MSG_extName__" : "Casama (dev)",
    description: "__MSG_extDescription__",
    default_locale: "en",
    version,
    icons,
    action: { default_title: "__MSG_actionTitle__", default_icon: icons },
    background: { scripts: ["background.js"], type: "module" },
    options_ui: { page: "options/options.html", open_in_tab: true },
    sidebar_action: {
      default_panel: "panel/panel.html",
      default_title: "__MSG_extName__",
      default_icon: icons,
      open_at_install: false,
    },
    // The e2e build has its optional permissions and every site already (no prompts to click).
    permissions: (target === "e2e"
      ? [...permissions, ...optional]
      : permissions) as chrome.runtime.ManifestPermission[],
    optional_permissions: optional as chrome.runtime.ManifestOptionalPermission[],
    optional_host_permissions: ["https://*/*", "http://*/*"],
    ...(target === "e2e" ? { host_permissions: ["<all_urls>"] } : {}),
    commands: {
      _execute_sidebar_action: { ..._execute_action, description: "Open Casama" },
      ...commands,
    },
    omnibox: { keyword: "ca" },
    content_security_policy: {
      extension_pages: "script-src 'self'; object-src 'self'",
    },
    browser_specific_settings: {
      gecko: {
        id: GECKO_ID,
        strict_min_version: FIREFOX_MIN_VERSION,
        data_collection_permissions: {
          required: ["authenticationInfo", "personalCommunications", "websiteContent"],
          optional: ["bookmarksInfo"],
        },
      },
    },
  } as unknown as chrome.runtime.ManifestV3;
}
