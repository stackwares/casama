/**
 * Which browser this is, and what it can do (D-323 Phase 5, plan §13).
 *
 * - **Chrome** and the browsers built on it (Brave, Arc, Vivaldi, Opera) run the store build.
 * - **Edge** runs the same package from Edge Add-ons. It has the side panel, the debugger and tab
 *   capture, but no `chrome.gcm`, so approval notifications come from the minute check instead of pushes.
 * - **Firefox** gets its own build (`vite build --mode firefox`): Ask, Capture and Stay in the
 *   loop only, without the page kit (see [FEATURES.pageKit]). It has no debugger API (no Act), no side panel (its sidebar instead), no tab
 *   capture, no offscreen documents, no reading list, and no `externally_connectable` (no sign-in
 *   handed over from the web app). The browser as a device (E2–E7) stays with Chrome and Edge.
 */

export const IS_FIREFOX = __CASAMA_BROWSER__ === "firefox";

export type BrowserName = "Chrome" | "Edge" | "Firefox";

/** The browser's name, for words people read ("Edge didn't give the permission"). */
export function browserName(
  userAgent: string = globalThis.navigator?.userAgent ?? "",
): BrowserName {
  if (IS_FIREFOX || /\bFirefox\//.test(userAgent)) return "Firefox";
  if (/\bEdg\//.test(userAgent)) return "Edge";
  return "Chrome";
}

/** What this build can offer. Each one hides its buttons and settings where it's false. */
export const FEATURES = {
  /** C: bots in your own browser (the debugger and tab groups). */
  act: !IS_FIREFOX,
  /** E2–E7: this browser as a device source (Realtime requests, triggers, recap, captions). */
  device: !IS_FIREFOX,
  /** B12: record this tab. */
  record: !IS_FIREFOX,
  /** B11's reading list. */
  readingList: !IS_FIREFOX,
  /** E1: the web app hands the extension a sign-in (`externally_connectable`). */
  webAppSignIn: !IS_FIREFOX,
  /** Google and Apple sign-in (identity.launchWebAuthFlow); servers allow Chrome's redirect address only so far. */
  providerSignIn: !IS_FIREFOX,
  /** D2: Approve and Deny buttons on notifications (Firefox shows no buttons). */
  notificationButtons: !IS_FIREFOX,
  /**
   * A12–A20, B6–B9: the page kit (selection bar, write button, site helpers, highlights). Its
   * content script runs only when storage is closed to content scripts, and Firefox can't close
   * it (no `storage.local.setAccessLevel`), so the refresh token would be readable from pages.
   */
  pageKit: !IS_FIREFOX,
} as const;

/** Where people change the extension's keyboard shortcuts. */
export function shortcutsUrl(name: BrowserName = browserName()): string {
  if (name === "Firefox") return "about:addons";
  if (name === "Edge") return "edge://extensions/shortcuts";
  return "chrome://extensions/shortcuts";
}

/** Firefox's sidebar, where Chrome and Edge have the side panel. */
type SidebarAction = { open(): Promise<void>; toggle?(): Promise<void> };
export function sidebarAction(): SidebarAction | undefined {
  const g = globalThis as unknown as {
    browser?: { sidebarAction?: SidebarAction };
    chrome?: { sidebarAction?: SidebarAction };
  };
  return g.browser?.sidebarAction ?? g.chrome?.sidebarAction;
}

/** "Casama for Chrome", "Casama for Edge" or "Casama for Firefox". */
export function productName(name: BrowserName = browserName()): string {
  return `Casama for ${name}`;
}
