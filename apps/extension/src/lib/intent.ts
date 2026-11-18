/**
 * Something the person started outside the panel (a right-click, a shortcut, the address bar) that
 * the panel picks up when it opens: kept in session storage for a minute.
 */
export interface Intent {
  /** Prefilled text; sent at once when [send] is set. */
  text?: string;
  send?: boolean;
  /** Context the menu already has (a selection, a link, an image). */
  selection?: string;
  linkUrl?: string;
  imageUrl?: string;
  /** Take a screenshot (or let them drag a box) and attach it. */
  attach?: "screenshot" | "region";
  /** Switch the page-text chip on (a site helper's question is about the whole page). */
  readText?: boolean;
  /** A16: write for a text box in the page; the reply goes back into it. */
  write?: { mode: "draft" | "rewrite" | "shorten" | "reply"; fieldId: string; text: string };
  /** What to point at for "watch": the price on a shopping page, or any part. */
  watchHint?: "price";
  /** A capture to make (B1–B4) instead of a message. */
  action?:
    | "save-page"
    | "save-image"
    | "save-link"
    | "save-note"
    | "remember"
    | "knowledge"
    | "task"
    // Phase 2: watch part of the page (B10), read it for me (B8), send a link's file to the
    // bot's computer (B6).
    | "watch"
    | "read-later"
    | "send-file";
  tabId?: number;
  at: number;
}

export async function setIntent(i: Omit<Intent, "at">) {
  await chrome.storage.session.set({ intent: { ...i, at: Date.now() } });
}

/** The waiting intent, once; null when there's none or it's stale. */
export async function takeIntent(): Promise<Intent | null> {
  const got = (await chrome.storage.session.get("intent")).intent as Intent | undefined;
  if (!got) return null;
  await chrome.storage.session.remove("intent");
  return Date.now() - got.at < 60_000 ? got : null;
}

/** Ready-made prompts for the right-click menu (A7). */
export const SELECTION_PROMPTS: Record<string, string> = {
  explain: "Explain this.",
  summarize: "Summarize this.",
  translate: "Translate this into English (or into my language if it's already English).",
  rewrite: "Rewrite this so it's clearer and shorter. Keep the meaning.",
};
