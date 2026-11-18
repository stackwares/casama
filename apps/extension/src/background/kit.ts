/**
 * The page kit's other half (Phase 2): registers the content script on the sites the person gave
 * access to, once they've turned on the selection bar, the write button, site helpers or
 * highlights, and answers its messages. The kit never sees tokens or settings: it asks here, and
 * the guard is checked here for every page (G2).
 */
import type { HelperName, KitConfig, KitMessage } from "../content/protocol.ts";
import { HELPERS } from "../content/protocol.ts";
import { hasConsent } from "../lib/consent.ts";
import { setIntent } from "../lib/intent.ts";
import { blockedReason } from "../lib/page.ts";
import { noteHighlight, pageEntry } from "../lib/page-index.ts";
import { flag, remoteConfig } from "../lib/remote-config.ts";
import { getSettings, originsFor } from "../lib/settings.ts";
import { activeAccount, restrictStorage } from "../lib/store.ts";
import { here } from "../lib/workspace.ts";
import { openPanel } from "./menus.ts";

const ID = "casama-kit";

/** Brings the registered content script in line with the settings and granted site access. */
export async function syncKit(): Promise<string[]> {
  const s = await getSettings();
  const account = await activeAccount();
  // Only where Chrome keeps local storage (the refresh tokens) out of content scripts' reach.
  const want =
    (await restrictStorage()) &&
    (await hasConsent()) &&
    !!account &&
    s.siteAccess !== "click" &&
    (s.selectionBar || s.writeBox || s.highlights || HELPERS.some((n) => s.helpers[n]));
  const origins = want ? originsFor(s.siteAccess, s.sites) : [];
  const granted = await Promise.all(
    origins.map((o) => chrome.permissions.contains({ origins: [o] }).catch(() => false)),
  );
  const matches = origins.filter((_, i) => granted[i]);
  const existing = await chrome.scripting
    .getRegisteredContentScripts({ ids: [ID] })
    .catch(() => []);
  if (!matches.length) {
    if (existing.length) await chrome.scripting.unregisterContentScripts({ ids: [ID] });
    return [];
  }
  const script = {
    id: ID,
    js: ["content.js"],
    matches,
    runAt: "document_idle" as const,
    allFrames: false,
    persistAcrossSessions: true,
  };
  if (existing.length) await chrome.scripting.updateContentScripts([script]);
  else await chrome.scripting.registerContentScripts([script]);
  return matches;
}

/** Tells kits already running in open tabs to ask again, so turning something off reaches them. */
export async function refreshKits() {
  for (const t of await chrome.tabs.query({}).catch(() => []))
    if (t.id !== undefined) chrome.tabs.sendMessage(t.id, { type: "kit:refresh" }).catch(() => {});
}

/** Highlights and chats about a page belong to an account and workspace. */
export const ownerOf = (account: { id: string; orgId?: string }) =>
  `${account.id} ${account.orgId ?? ""}`;

const OFF: KitConfig = {
  off: true,
  selectionBar: false,
  writeBox: false,
  helpers: [],
  highlights: [],
  commands: [],
};

/** The person's page commands, fetched at most every ten minutes. */
async function commands(accountId: string): Promise<KitConfig["commands"]> {
  const cached = (await chrome.storage.session.get("pageCommands")).pageCommands as
    | { at: number; account: string; items: KitConfig["commands"] }
    | undefined;
  const mine = cached?.account === accountId ? cached : undefined;
  if (mine && Date.now() - mine.at < 10 * 60_000) return mine.items;
  try {
    const h = await here();
    if (!h) return [];
    const r = await h.api.unwrap(
      h.api.GET("/v1/me/page-commands", { signal: AbortSignal.timeout(8000) }),
    );
    const items = r.items.map((c) => ({ name: c.name, prompt: c.prompt }));
    await chrome.storage.session.set({
      pageCommands: { at: Date.now(), account: accountId, items },
    });
    return items;
  } catch {
    return mine?.items ?? [];
  }
}

export async function kitConfig(url: string): Promise<KitConfig> {
  if (!(await hasConsent())) return OFF;
  const account = await activeAccount();
  if (!account) return OFF;
  if (await blockedReason(url)) return OFF;
  const s = await getSettings();
  const rc = await remoteConfig(account.server);
  if (!flag(rc, "chrome_extension", true)) return OFF;
  const helpers = HELPERS.filter((n) => s.helpers[n] && flag(rc, `chrome_helper_${n}`, true));
  const selectionBar = s.selectionBar && flag(rc, "chrome_selection_bar", true);
  return {
    selectionBar,
    writeBox: s.writeBox && flag(rc, "chrome_write_box", true),
    helpers,
    highlights: s.highlights ? ((await pageEntry(url, ownerOf(account)))?.highlights ?? []) : [],
    commands: selectionBar ? (await commands(account.id)).slice(0, 3) : [],
  };
}

async function saveHighlight(m: Extract<KitMessage, { type: "kit:highlight" }>, tabUrl: string) {
  const blocked = await blockedReason(tabUrl);
  if (blocked) return { error: blocked };
  const h = await here();
  if (!h) return { error: "Sign in to Casama first." };
  try {
    const r = await h.api.unwrap(
      h.api.POST("/v1/me/highlights", {
        body: {
          org_id: h.org.id,
          url: tabUrl,
          title: m.title.slice(0, 300),
          text: m.text,
          prefix: m.prefix.slice(-64),
          suffix: m.suffix.slice(0, 64),
        },
        signal: AbortSignal.timeout(15_000),
      }),
    );
    await noteHighlight(tabUrl, `${h.account.id} ${h.org.id}`, {
      id: r.id,
      text: r.text,
      prefix: r.prefix,
      suffix: r.suffix,
    });
    return { id: r.id };
  } catch (e) {
    return { error: (e as Error).message || "Couldn't save the highlight." };
  }
}

/** A message from the kit in a page. Anything else (or from elsewhere) is ignored. */
export function onKitMessage(
  m: KitMessage,
  sender: chrome.runtime.MessageSender,
  reply: (r: unknown) => void,
): boolean {
  const tab = sender.tab;
  if (sender.id !== chrome.runtime.id || !tab?.id || !tab.url || !m?.type?.startsWith("kit:"))
    return false;
  // The page's own address, from Chrome, not from the message.
  const url = tab.url;
  const tabId = tab.id;
  /** The same checks as at page load, again now: settings, sign-in or the guard may have changed. */
  const allowed = async (need: (c: KitConfig) => boolean) => {
    const c = await kitConfig(url).catch(() => OFF);
    return !c.off && need(c);
  };
  switch (m.type) {
    case "kit:config":
    case "kit:refresh":
      void kitConfig(url).then(reply, () => reply(OFF));
      return true;
    case "kit:ask":
      // Straight from the click: Chrome opens the side panel only during the gesture.
      void openPanel(tab);
      void allowed((c) => c.selectionBar || c.helpers.length > 0).then(async (ok) => {
        if (ok)
          await setIntent({
            text: m.prompt,
            send: m.send,
            selection: m.selection?.slice(0, 20_000),
            readText: m.readText,
            tabId,
          });
      });
      return false;
    case "kit:write":
      void openPanel(tab);
      void allowed((c) => c.writeBox).then(async (ok) => {
        if (ok)
          await setIntent({
            write: { mode: m.mode, fieldId: m.fieldId, text: m.text.slice(0, 8000) },
            tabId,
          });
      });
      return false;
    case "kit:watch-price":
      void openPanel(tab);
      void allowed((c) => c.helpers.includes("shopping")).then(async (ok) => {
        if (ok) await setIntent({ action: "watch", watchHint: "price", tabId });
      });
      return false;
    case "kit:highlight":
      void allowed((c) => c.selectionBar).then((ok) =>
        ok ? saveHighlight(m, url).then(reply) : reply({ error: "Highlights are off." }),
      );
      return true;
    case "kit:helper-missing":
      void noteHelperMissing(m.helper);
      return false;
  }
  return false;
}

/** Counts helpers that hid because a site changed, shown in Settings (no page data). */
async function noteHelperMissing(name: HelperName) {
  const got = ((await chrome.storage.session.get("helperMisses")).helperMisses ?? {}) as Record<
    string,
    number
  >;
  got[name] = (got[name] ?? 0) + 1;
  await chrome.storage.session.set({ helperMisses: got });
}
