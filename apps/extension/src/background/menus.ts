/**
 * The right-click menu (A7), keyboard shortcuts (A8) and the address bar (A9). Each one opens the
 * side panel with what it started; the panel does the rest where the person can see it.
 */
import { IS_FIREFOX, sidebarAction } from "../lib/browser.ts";
import { focusedField } from "../lib/inject.ts";
import { type Intent, SELECTION_PROMPTS, setIntent } from "../lib/intent.ts";
import { blockedReason } from "../lib/page.ts";
import { cachedRemoteConfig, promptFor, type RemoteAppConfig } from "../lib/remote-config.ts";
import { activeAccount } from "../lib/store.ts";

type Context = "selection" | "link" | "image" | "page";
type Item = { id: string; title: string; contexts: [Context, ...Context[]] };

export const MENU: Item[] = [
  { id: "ask-selection", title: "Ask Casama about “%s”", contexts: ["selection"] },
  { id: "explain", title: "Explain", contexts: ["selection"] },
  { id: "summarize", title: "Summarize", contexts: ["selection"] },
  { id: "translate", title: "Translate", contexts: ["selection"] },
  { id: "rewrite", title: "Rewrite", contexts: ["selection"] },
  { id: "remember", title: "Remember this", contexts: ["selection"] },
  { id: "save-note", title: "Save as a note in the Library", contexts: ["selection"] },
  { id: "ask-link", title: "Ask Casama about this link", contexts: ["link"] },
  { id: "save-link", title: "Save this link to the Library", contexts: ["link"] },
  { id: "send-file", title: "Send this link's file to the bot's computer", contexts: ["link"] },
  { id: "ask-image", title: "Ask Casama about this image", contexts: ["image"] },
  { id: "save-image", title: "Save this image to the Library", contexts: ["image"] },
  { id: "ask-page", title: "Ask Casama about this page", contexts: ["page"] },
  { id: "save-page", title: "Save this page to the Library", contexts: ["page"] },
  { id: "knowledge", title: "Add this page to a bot's knowledge", contexts: ["page"] },
  { id: "task", title: "Make a task from this page", contexts: ["page"] },
  { id: "read-later", title: "Read it for me (in my next brief)", contexts: ["page"] },
  { id: "watch", title: "Watch part of this page for changes", contexts: ["page"] },
];

export function installMenus() {
  chrome.contextMenus.removeAll(() => {
    const parent = chrome.contextMenus.create({
      id: "casama",
      title: "Casama",
      contexts: ["selection", "link", "image", "page"] as never,
    });
    for (const m of MENU)
      chrome.contextMenus.create({ ...m, contexts: m.contexts as never, parentId: parent });
  });
}

/** What a menu item asks the panel to do. */
export function intentFor(
  info: chrome.contextMenus.OnClickData,
  tabId?: number,
  config?: RemoteAppConfig | null,
): Omit<Intent, "at"> | null {
  const id = String(info.menuItemId);
  const selection = info.selectionText;
  // The server's owner may reword these (D-372); the built-in text otherwise.
  if (id in SELECTION_PROMPTS)
    return {
      text: promptFor(config, `selection.${id}`, SELECTION_PROMPTS[id] as string),
      send: true,
      selection,
      tabId,
    };
  switch (id) {
    case "ask-selection":
      return { selection, tabId };
    case "remember":
      return { action: "remember", selection, tabId };
    case "save-note":
      return { action: "save-note", selection, tabId };
    case "ask-link":
      return { linkUrl: info.linkUrl, text: "What's at this link?", tabId };
    case "save-link":
    case "send-file":
      return { action: id, linkUrl: info.linkUrl, tabId };
    case "ask-image":
      return { imageUrl: info.srcUrl, text: "What's in this image?", tabId };
    case "save-image":
      return { action: "save-image", imageUrl: info.srcUrl, tabId };
    case "ask-page":
      return { tabId };
    case "save-page":
    case "knowledge":
    case "task":
    case "read-later":
    case "watch":
      return { action: id, tabId };
    default:
      return null;
  }
}

/** Opens the panel for [tab]. Must run straight from the click, before any await. */
export function openPanel(tab?: chrome.tabs.Tab): Promise<void> {
  // Firefox: the sidebar, which also opens only from the person's own click or keypress.
  if (IS_FIREFOX) {
    const sidebar = sidebarAction();
    return sidebar ? sidebar.open().catch(() => openPanelTab()) : openPanelTab();
  }
  if (tab?.id !== undefined)
    return chrome.sidePanel.open({ tabId: tab.id }).catch(() => openPanelTab());
  if (tab?.windowId !== undefined)
    return chrome.sidePanel.open({ windowId: tab.windowId }).catch(() => openPanelTab());
  return openPanelTab();
}

/** Where the side panel can't open (no gesture), the panel opens as a tab instead. */
async function openPanelTab() {
  await chrome.tabs.create({ url: chrome.runtime.getURL("panel/panel.html?tab=1") });
}

export function onMenuClick(info: chrome.contextMenus.OnClickData, tab?: chrome.tabs.Tab) {
  if (!intentFor(info, tab?.id)) return;
  // The panel opens inside the click (a user gesture); the intent follows with the server's
  // wording from the last settings fetched, never waiting on the network.
  void openPanel(tab);
  void (async () => {
    const account = await activeAccount().catch(() => null);
    const config = account ? await cachedRemoteConfig(account.server) : null;
    const intent = intentFor(info, tab?.id, config);
    if (intent) await setIntent(intent);
  })();
}

export const COMMANDS = {
  "ask-selection": { attach: undefined },
  screenshot: { attach: "screenshot" as const },
  "save-page": { action: "save-page" as const },
};

export async function onCommand(command: string, tab?: chrome.tabs.Tab) {
  if (!(command in COMMANDS)) return;
  const opened = openPanel(tab);
  const c = COMMANDS[command as keyof typeof COMMANDS];
  // A16's shortcut: in a text box, "ask about the selection" writes for the box instead.
  // Nothing is read on a blocked page, not even to look for the box (G2).
  if (command === "ask-selection" && tab?.id !== undefined && !(await blockedReason(tab.url))) {
    const field = await chrome.scripting
      .executeScript({ target: { tabId: tab.id }, func: focusedField })
      .then((r) => r[0]?.result ?? null)
      .catch(() => null);
    if (field === "secret") {
      await setIntent({ tabId: tab.id });
      return opened;
    }
    if (field) {
      await setIntent({
        write: {
          mode: field.text.trim() ? "rewrite" : "draft",
          fieldId: field.id,
          text: field.text,
        },
        tabId: tab.id,
      });
      return opened;
    }
  }
  await setIntent({ ...c, tabId: tab?.id });
  await opened;
}

/**
 * The window used last, kept current so the address bar can open the side panel straight from the
 * keypress: Chrome only opens it during the user's gesture, which an await would lose.
 */
let lastWindow: number | undefined;
export function trackWindows() {
  void chrome.windows
    .getLastFocused()
    .then((w) => {
      lastWindow ??= w.id;
    })
    .catch(() => {});
  chrome.windows.onFocusChanged.addListener((id) => {
    if (id !== chrome.windows.WINDOW_ID_NONE) lastWindow = id;
  });
}

/** `ca <question>` in the address bar. */
export function onOmnibox(text: string) {
  const q = text.trim();
  if (!q) return;
  void openPanel(
    lastWindow !== undefined ? ({ windowId: lastWindow } as chrome.tabs.Tab) : undefined,
  );
  void setIntent({ text: q, send: true });
}
