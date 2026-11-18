/**
 * Tells the server which chat the side panel has on screen (D-325), the same way the app does, so
 * a reply to it doesn't push to any of the person's devices, this browser included.
 *
 * While a chat is open and the panel is visible, the focus is sent again every 30 seconds; the
 * server ignores one older than 45 seconds, so a closed panel never silences replies for long.
 * Hiding the panel or leaving the chat sends null at once. Everything here is best effort: a
 * server from before D-325 has no chat_focus table, and its pushes still come.
 */
import type { Account } from "./store.ts";
import { rest } from "./workspace.ts";

export const FOCUS_REFRESH_MS = 30_000;
const CLIENT_KEY = "chatFocusClientId";

/** One id per browser profile, like the app's per-install id. */
export async function focusClientId(): Promise<string> {
  const got = (await chrome.storage.local.get(CLIENT_KEY))[CLIENT_KEY];
  if (typeof got === "string" && got.length >= 8) return got;
  const id = `chrome-${crypto.randomUUID()}`;
  await chrome.storage.local.set({ [CLIENT_KEY]: id });
  return id;
}

/** The bits of `document` this needs (tests pass their own). */
export interface FocusDoc {
  readonly visibilityState: DocumentVisibilityState;
  addEventListener(type: "visibilitychange", listener: () => void): void;
}

export class ChatFocus {
  private account: Account | null = null;
  private conversation: string | null = null;
  private sent: { account: string; conversation: string | null } | null = null;
  private timer: ReturnType<typeof setInterval> | null = null;

  private readonly doc: FocusDoc;

  constructor(doc: FocusDoc = document) {
    this.doc = doc;
    doc.addEventListener("visibilitychange", () => this.sync());
  }

  /** The chat on screen for [account], or null when none is. */
  set(account: Account, conversationId: string | null) {
    if (this.account && this.account.id !== account.id && this.sent?.conversation) {
      // Another account took over the panel: clear the old one's focus first.
      void this.send(this.account, null);
    }
    this.account = account;
    this.conversation = conversationId;
    this.sync();
  }

  /** What the server should see now: the open chat while the panel is visible. */
  get focus(): string | null {
    return this.doc.visibilityState === "visible" ? this.conversation : null;
  }

  private sync() {
    const account = this.account;
    if (!account) return;
    const want = this.focus;
    if (this.timer) clearInterval(this.timer);
    this.timer = null;
    if (want) this.timer = setInterval(() => void this.send(account, want, true), FOCUS_REFRESH_MS);
    void this.send(account, want);
  }

  private async send(account: Account, conversationId: string | null, force = false) {
    const same = this.sent?.account === account.id && this.sent.conversation === conversationId;
    // Nothing to clear on a fresh start: a panel that never reported has no row.
    if (!force && (same || (!this.sent && conversationId === null))) return;
    this.sent = { account: account.id, conversation: conversationId };
    try {
      await rest(account, "chat_focus?on_conflict=user_id,client_id", {
        method: "POST",
        headers: { prefer: "resolution=merge-duplicates,return=minimal" },
        body: JSON.stringify({
          user_id: account.userId,
          client_id: await focusClientId(),
          conversation_id: conversationId,
          updated_at: new Date().toISOString(),
        }),
      });
    } catch {
      // Best effort (see above).
    }
  }
}
