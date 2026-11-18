/**
 * The service worker: the toolbar button opens the side panel; right-click, shortcuts and the
 * address bar hand their work to it; pushes and a minute check keep the badge and notifications
 * current; queued captures are retried; sign-ins come from the web app (Phase 0).
 */
import {
  onNotificationButton,
  onNotificationClick,
  onPush,
  pollApprovals,
  registerPush,
  updateBadge,
} from "../lib/alerts.ts";
import { IS_FIREFOX, sidebarAction } from "../lib/browser.ts";
import { flushQueue } from "../lib/capture.ts";
import { hasConsent } from "../lib/consent.ts";
import { guardAdditions } from "../lib/guard-sites.ts";
import { remoteConfig } from "../lib/remote-config.ts";
import { activeAccount, getLocal, restrictStorage } from "../lib/store.ts";
import { simulateCancel } from "./act/cdp.ts";
import { ensureConnected } from "./act/device.ts";
import { installAct, onActMessage, onAskNotification } from "./act/index.ts";
import { deviceTick, installDevice, onDeviceMessage } from "./device/index.ts";
import { handleHandover } from "./handover.ts";
import { onKitMessage, refreshKits, syncKit } from "./kit.ts";
import { installMenus, onCommand, onMenuClick, onOmnibox, trackWindows } from "./menus.ts";

const openOptions = () => chrome.runtime.openOptionsPage();

/** What's new and the uninstall feedback page (G6). */
const WHATS_NEW = "https://casama.ai/chrome/whats-new";
const UNINSTALL = "https://casama.ai/chrome/uninstalled";

async function setUp() {
  await restrictStorage();
  // Firefox has no side panel: its toolbar button opens the sidebar instead (below).
  if (__CASAMA_BROWSER__ !== "firefox")
    await chrome.sidePanel.setPanelBehavior({ openPanelOnActionClick: true }).catch(() => {});
  installMenus();
  await chrome.alarms.create("tick", { periodInMinutes: 1 });
  await chrome.alarms.create("queue", { periodInMinutes: 5 });
  if (__CASAMA_TARGET__ === "store")
    await chrome.runtime.setUninstallURL(UNINSTALL).catch(() => {});
  await syncKit().catch(() => {});
}

chrome.runtime.onInstalled.addListener((details) => {
  void setUp();
  if (details.reason === "install") void openOptions();
  if (details.reason === "update" && __CASAMA_TARGET__ === "store")
    void chrome.storage.local.set({
      whatsNew: { version: chrome.runtime.getManifest().version, url: WHATS_NEW },
    });
  void pushes();
});

chrome.runtime.onStartup.addListener(() => {
  void setUp();
  void activeAccount().then((a) => a && remoteConfig(a.server, { fresh: true }));
  // The guard's added sites (D-374): fetched now, so the first page read already has them.
  void guardAdditions(Number.POSITIVE_INFINITY);
  void pushes();
});

chrome.runtime.onMessageExternal.addListener((message, sender, sendResponse) => {
  handleHandover(message, sender.origin, __CASAMA_TARGET__, openOptions).then(sendResponse);
  return true;
});

chrome.runtime.onMessage.addListener(onKitMessage);
// The browser checks below are spelled out (not lib/browser.ts FEATURES) so the Firefox build drops the code
// behind them, and with it every API Firefox doesn't have (src/lib/browser.ts).
// Phase 3: this browser as a device bots can use, when paired. Not in Firefox (no debugger API).
if (__CASAMA_BROWSER__ !== "firefox") {
  chrome.runtime.onMessage.addListener(onActMessage);
  installAct();
}
// Phase 4: this browser as a device source (the tab in front, history search, triggers, recap).
if (__CASAMA_BROWSER__ !== "firefox") {
  chrome.runtime.onMessage.addListener(onDeviceMessage);
  installDevice();
}
// Phase 5: Firefox's toolbar button opens its sidebar, straight from the click.
if (IS_FIREFOX) chrome.action.onClicked.addListener(() => void sidebarAction()?.toggle?.());
if (__CASAMA_TARGET__ !== "store" && __CASAMA_BROWSER__ !== "firefox")
  (self as unknown as { __casamaTest: unknown }).__casamaTest = { simulateCancel };
chrome.permissions.onAdded.addListener(() => void syncKit().catch(() => {}));
chrome.permissions.onRemoved.addListener(() => void syncKit().catch(() => {}));

chrome.contextMenus.onClicked.addListener(onMenuClick);
chrome.commands.onCommand.addListener((command, tab) => void onCommand(command, tab));
chrome.omnibox.onInputEntered.addListener(onOmnibox);
trackWindows();
chrome.omnibox.setDefaultSuggestion({ description: "Ask Casama: %s" });

// Firefox shows no notification buttons, and its compatibility tables list onButtonClicked as
// missing (current releases do have the event): leave it out there, since a top-level throw would
// stop every listener below from registering.
if (__CASAMA_BROWSER__ !== "firefox")
  chrome.notifications.onButtonClicked.addListener((id, button) => {
    if (id.startsWith("act-")) return void onAskNotification(id, button);
    void onNotificationButton(id, button);
  });
chrome.notifications.onClicked.addListener((id) => {
  if (id.startsWith("act-")) return void chrome.notifications.clear(id);
  void onNotificationClick(id);
});

if (__CASAMA_BROWSER__ !== "firefox")
  chrome.gcm?.onMessage.addListener(
    (message) => void onPush(message.data as Record<string, string>),
  );

/** Registers for pushes on each server; remembers which can't take them, to check those instead. */
async function pushes() {
  if (!(await hasConsent())) return;
  const polled: string[] = [];
  for (const a of (await getLocal()).accounts) {
    const ok = await registerPush(a).catch(() => false);
    if (!ok) polled.push(a.id);
  }
  await chrome.storage.session.set({ polled });
}

chrome.alarms.onAlarm.addListener(async (alarm) => {
  if (!(await hasConsent())) return;
  if (alarm.name === "queue") await flushQueue().catch(() => {});
  if (alarm.name === "tick") {
    await updateBadge().catch(() => {});
    const active = await activeAccount();
    const polled =
      ((await chrome.storage.session.get("polled")).polled as string[] | undefined) ?? [];
    if (active && polled.includes(active.id)) await pollApprovals().catch(() => {});
    if (__CASAMA_BROWSER__ !== "firefox") await deviceTick().catch(() => {});
  }
});

// A new sign-in registers for pushes; any change updates the badge.
chrome.storage.onChanged.addListener((changes, area) => {
  if (area !== "local") return;
  if (changes.accounts) {
    const before = ((changes.accounts.oldValue as { id: string }[] | undefined) ?? []).map(
      (a) => a.id,
    );
    const added = ((changes.accounts.newValue as { id: string }[] | undefined) ?? []).some(
      (a) => !before.includes(a.id),
    );
    if (added) void pushes();
  }
  if (changes.accounts || changes.activeAccountId) void updateBadge().catch(() => {});
  if (__CASAMA_BROWSER__ !== "firefox" && (changes.consent || changes.accounts))
    void ensureConnected().catch(() => {});
  if (changes.settings || changes.consent || changes.accounts || changes.activeAccountId) {
    void syncKit().catch(() => {});
    void refreshKits();
  }
});

// Back online: send what waited.
self.addEventListener("online", () => void flushQueue().catch(() => {}));
