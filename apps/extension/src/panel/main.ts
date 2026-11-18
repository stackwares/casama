/**
 * The side panel (plan §6 A, B, D): Chat, Inbox, Library and More. Before the first-run agreement,
 * signed out, or switched off remotely, it says so and sends the person to Settings.
 */

import { updateBadge } from "../lib/alerts.ts";
import { productName } from "../lib/browser.ts";
import { hasConsent } from "../lib/consent.ts";
import { h } from "../lib/dom.ts";
import { type Intent, takeIntent } from "../lib/intent.ts";
import { activeTab, blockedReason, readTab } from "../lib/page.ts";
import { gate, remoteConfig } from "../lib/remote-config.ts";
import { activeAccount } from "../lib/store.ts";
import { type Here, here } from "../lib/workspace.ts";
import { ChatView } from "./chat.ts";
import { InboxView } from "./inbox.ts";
import { LibraryView } from "./library.ts";
import { MoreView } from "./more.ts";
import { readLater, sendFile, watchPart } from "./page-tools.ts";
import { errorBox, message, toast } from "./shared.ts";

const app = document.getElementById("app")!;
const VERSION = __CASAMA_VERSION__;

function centered(
  title: string,
  text: string,
  action?: { label: string; testid: string; run: () => void },
) {
  app.replaceChildren(
    h(
      "div",
      { className: "center" },
      h("img", { src: "/icons/icon-128.png", alt: "", width: 72, height: 72 }),
      h("h1", {}, title),
      h("p", { className: "muted" }, text),
      action
        ? h(
            "button",
            { className: "primary", "data-testid": action.testid, onClick: action.run },
            action.label,
          )
        : "",
    ),
  );
}

const openSettings = () => chrome.runtime.openOptionsPage();

type TabName = "chat" | "inbox" | "library" | "more";
let views: { chat: ChatView; inbox: InboxView; library: LibraryView; more: MoreView } | null = null;
let current: TabName = "chat";
let shownKey = "";

async function start() {
  if (!(await hasConsent()))
    return centered(
      "Welcome to Casama",
      "Finish setting up in Settings first: it explains what's sent and lets you sign in.",
      {
        label: "Open Settings",
        testid: "finish-setup",
        run: openSettings,
      },
    );
  const account = await activeAccount();
  const g = gate(await remoteConfig(account?.server ?? "https://api.casama.ai"), VERSION);
  if (g.state === "off")
    return centered(
      `${productName()} is off`,
      "It's turned off for now. Casama will say when it's back.",
    );
  if (g.state === "update")
    return centered(
      "Update needed",
      `Update to ${g.minVersion} or newer to keep using ${productName()}.`,
    );
  if (g.state === "maintenance") return centered("Down for maintenance", g.message);
  if (!account)
    return centered(
      "Sign in to Casama",
      "Sign in once in Settings, with the web app, a sign-in link or an emailed code.",
      {
        label: "Sign in",
        testid: "sign-in",
        run: openSettings,
      },
    );
  let h_: Here | null;
  try {
    h_ = await here();
  } catch (e) {
    app.replaceChildren(
      h(
        "div",
        { className: "view" },
        errorBox(e, () => void start()),
      ),
    );
    return;
  }
  if (!h_)
    return centered("No workspace yet", "Create a workspace in the Casama app, then come back.");
  const key = `${h_.account.id} ${h_.org.id}`;
  if (key === shownKey && views) return;
  shownKey = key;
  shell(h_);
}

function shell(hereNow: Here) {
  views = {
    chat: new ChatView(hereNow),
    inbox: new InboxView(hereNow),
    library: new LibraryView(hereNow),
    more: new MoreView(hereNow),
  };
  const count = h("span", { className: "count", hidden: true });
  const tabs: Record<TabName, HTMLButtonElement> = {
    chat: h("button", { role: "tab", "data-testid": "tab-chat" }, "Chat") as HTMLButtonElement,
    inbox: h(
      "button",
      { role: "tab", "data-testid": "tab-inbox" },
      "Inbox",
      count,
    ) as HTMLButtonElement,
    library: h(
      "button",
      { role: "tab", "data-testid": "tab-library" },
      "Library",
    ) as HTMLButtonElement,
    more: h("button", { role: "tab", "data-testid": "tab-more" }, "More") as HTMLButtonElement,
  };
  views.more.hooks = {
    pageAction: async (action) => pageAction({ action }, await activeTab()),
    addTab: (label, text) => {
      views!.chat.addExtra({ kind: "tab", label, text });
      show("chat");
    },
    ask: async (text, readText) => {
      show("chat");
      await views!.chat.apply({ text, send: true, readText, at: Date.now() });
    },
  };
  views.inbox.onCount = (n) => {
    count.hidden = n === 0;
    count.textContent = String(n);
  };
  const body = h("div", { style: "flex:1;display:flex;flex-direction:column;min-height:0" });
  const show = (name: TabName) => {
    current = name;
    for (const [k, b] of Object.entries(tabs)) b.setAttribute("aria-selected", String(k === name));
    body.replaceChildren(views![name].el);
    if (name !== "chat") void views![name].load();
  };
  for (const [k, b] of Object.entries(tabs)) b.addEventListener("click", () => show(k as TabName));
  app.replaceChildren(
    h("nav", { className: "tabs", role: "tablist" }, ...Object.values(tabs)),
    body,
  );
  show("chat");
  void views.chat.load().then(() => void pickUpIntent());
  void views.inbox.load();
  void updateBadge().catch(() => {});
}

async function pickUpIntent() {
  const intent = await takeIntent();
  if (intent && views) await runIntent(intent);
}

/** The tab a menu, shortcut or address-bar intent came from, or the one in use now. */
async function intentTab(intent: Intent) {
  if (intent.tabId !== undefined) {
    const t = await chrome.tabs.get(intent.tabId).catch(() => undefined);
    if (t) return t;
  }
  return activeTab();
}

async function runIntent(intent: Intent) {
  if (!views) return;
  const lib = views.library.captures;
  const tab = await intentTab(intent);
  // Nothing from a blocked page goes anywhere (G2): not its selection, link, image or address.
  const blocked =
    intent.action || intent.selection || intent.linkUrl || intent.imageUrl || intent.write
      ? await blockedReason(tab?.url)
      : null;
  if (blocked && intent.action) return toast(blocked);
  const selection = async () =>
    intent.selection ?? (await readTab(tab).catch(() => ({ selection: "" }))).selection ?? "";
  switch (intent.action) {
    case "save-page":
      await lib.savePage("markdown");
      return;
    case "save-image":
      if (intent.imageUrl) await lib.saveImage(intent.imageUrl);
      return;
    case "save-link":
      if (intent.linkUrl) await lib.saveLink(intent.linkUrl);
      return;
    case "save-note": {
      const text = await selection();
      if (text.trim()) await lib.saveNote(text, { url: tab?.url, title: tab?.title });
      return;
    }
    case "remember": {
      const text = await selection();
      if (text.trim()) await lib.remember(text);
      return;
    }
    case "knowledge":
      await lib.knowledge(undefined, false);
      return;
    case "task":
      await lib.task(undefined, true);
      return;
    case "watch":
    case "read-later":
    case "send-file":
      await pageAction(intent, tab);
      return;
  }
  if (blocked && intent.write) return toast(blocked);
  if (current !== "chat")
    (app.querySelector('[data-testid="tab-chat"]') as HTMLButtonElement | null)?.click();
  if (blocked) {
    toast(blocked);
    await views.chat.apply({
      ...intent,
      selection: undefined,
      linkUrl: undefined,
      imageUrl: undefined,
      send: false,
    });
    return;
  }
  await views.chat.apply(intent);
}

/** Phase 2 actions on the page: watch part of it, read it later, send a link's file. */
export async function pageAction(
  intent: Pick<Intent, "action" | "linkUrl" | "watchHint">,
  tab: chrome.tabs.Tab | undefined,
) {
  if (!views || !tab) return;
  const h_ = views.chat.hereNow;
  const bot = views.chat.currentBot;
  try {
    if (intent.action === "read-later") {
      await readLater(h_, tab);
      toast("Added. Your bot will sum it up in your next brief.");
    } else if (intent.action === "watch") {
      if (!bot) return toast("Pick a bot first.");
      const r = await watchPart(h_, bot, tab, intent.watchHint);
      if (r) toast(`Watching it. ${bot.name} will tell you when it changes.`);
    } else if (intent.action === "send-file" && intent.linkUrl) {
      if (!bot) return toast("Pick a bot first.");
      toast("Sending the file…");
      const r = await sendFile(h_, bot, intent.linkUrl, tab);
      toast(`${r.name} is in ${bot.name}'s computer, under Downloads.`);
    }
  } catch (e) {
    toast(message(e));
  }
}

// The open tab changed: the chips follow it, from its address and title only. The page itself is
// read when the person starts a message, switches a chip on, sends or saves (never in the background).
chrome.tabs.onActivated.addListener(() => void views?.chat.tabChanged());
chrome.tabs.onUpdated.addListener((_id, info, tab) => {
  if ((info.status === "complete" || info.url) && tab.active) void views?.chat.tabChanged();
});
chrome.storage.onChanged.addListener((changes, area) => {
  if (area === "session" && changes.intent?.newValue) void pickUpIntent();
  if (area === "local" && (changes.accounts || changes.activeAccountId || changes.consent))
    void start();
});

void start();
