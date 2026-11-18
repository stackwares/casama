/**
 * The person's settings for this browser (plan §6 G1–G5), in chrome.storage.local next to the
 * accounts. Never synced: site lists say where someone goes.
 */
import { HELPERS, type HelperName } from "../content/protocol.ts";
import { withLock } from "./store.ts";

/** G1: when the extension may read the open tab. Reading still happens only when asked. */
export type SiteAccess = "click" | "sites" | "all";

export interface Chips {
  /** The page's address and title. */
  page: boolean;
  selection: boolean;
  /** The page's readable text. */
  text: boolean;
  screenshot: boolean;
}

export interface Settings {
  siteAccess: SiteAccess;
  /** Hosts picked for "sites" access, e.g. "docs.example.com". */
  sites: string[];
  /** G2: hosts never read or captured, on top of the built-in guard. */
  neverList: string[];
  /** G3: which context chips start switched on. */
  chips: Chips;
  /** D3: Chrome notifications for "needs you" and "done". */
  notifications: boolean;
  /** Asked once, after the first-run agreement. */
  siteAccessChosen: boolean;
  /** Bot picked in the panel, per account and workspace. */
  lastBot: Record<string, string>;
  /** A15: the bar beside selected text, on sites Casama has access to. Opt-in. */
  selectionBar: boolean;
  /** A16: the write button in text boxes. Opt-in. */
  writeBox: boolean;
  /** A17: each site helper's switch. */
  helpers: Record<HelperName, boolean>;
  /** B7: show highlights again on the pages they were made on. */
  highlights: boolean;
  /** F2: trim long pages to the parts that matter before they're sent. */
  sendLess: boolean;
  /** E7: meeting notes from Google Meet captions (behind a server flag). Off by default. */
  meetingCaptions: boolean;
}

export const DEFAULT_SETTINGS: Settings = {
  siteAccess: "click",
  sites: [],
  neverList: [],
  chips: { page: true, selection: true, text: false, screenshot: false },
  notifications: true,
  siteAccessChosen: false,
  lastBot: {},
  selectionBar: false,
  writeBox: false,
  helpers: Object.fromEntries(HELPERS.map((n) => [n, true])) as Record<HelperName, boolean>,
  highlights: true,
  sendLess: true,
  meetingCaptions: false,
};

export async function getSettings(): Promise<Settings> {
  const got = (await chrome.storage.local.get("settings")).settings as
    | Partial<Settings>
    | undefined;
  return {
    ...DEFAULT_SETTINGS,
    ...got,
    chips: { ...DEFAULT_SETTINGS.chips, ...got?.chips },
    helpers: { ...DEFAULT_SETTINGS.helpers, ...got?.helpers },
    lastBot: { ...got?.lastBot },
  };
}

export function updateSettings(fn: (s: Settings) => void): Promise<Settings> {
  return withLock("settings", async () => {
    const s = await getSettings();
    fn(s);
    await chrome.storage.local.set({ settings: s });
    return s;
  });
}

/** A host as typed or pasted ("https://Mail.Example.com/x" → "mail.example.com"), or null. */
export function cleanHost(input: string): string | null {
  const t = input.trim().toLowerCase();
  if (!t) return null;
  try {
    const host = new URL(/^[a-z]+:\/\//.test(t) ? t : `https://${t}`).hostname;
    return /^[a-z0-9.-]+\.[a-z]{2,}$|^localhost$/.test(host) ? host.replace(/^www\./, "") : null;
  } catch {
    return null;
  }
}

/** The host permissions a site access mode needs. */
export function originsFor(access: SiteAccess, sites: string[]): string[] {
  if (access === "all") return ["https://*/*", "http://*/*"];
  if (access === "sites") return sites.flatMap((s) => [`https://${s}/*`, `https://*.${s}/*`]);
  return [];
}
