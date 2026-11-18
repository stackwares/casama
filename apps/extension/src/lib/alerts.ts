/**
 * Staying in the loop (plan §6 D1, D3; §9.4): the badge, Chrome notifications with Approve and
 * Deny, and pushes. Pushes come through chrome.gcm with the server's push sender id (data-only
 * FCM messages, D-323); a server without one is checked every minute while Chrome is open.
 */
import { FEATURES } from "./browser.ts";
import { clientFor } from "./session.ts";
import { getSettings } from "./settings.ts";
import { type Account, activeAccount, getLocal, updateLocal } from "./store.ts";
import { appUrl, here, rest } from "./workspace.ts";

export interface PushData {
  title?: string;
  body?: string;
  link?: string;
  kind?: string;
  notification_id?: string;
}

/** What a shown notification is about, so its buttons know what to do. */
interface Shown {
  accountId: string;
  approvalId?: string;
  link?: string;
}

export const approvalIdOf = (link: string | undefined) =>
  /^\/approvals\/([0-9a-f-]{36})$/i.exec(link ?? "")?.[1];

/** A push or a newly found approval as a Chrome notification. "Needs you" and "done" only. */
export async function showNotification(account: Account, data: PushData) {
  const settings = await getSettings();
  if (!settings.notifications) return;
  const approvalId = approvalIdOf(data.link);
  const id = `casama:${approvalId ?? data.notification_id ?? crypto.randomUUID()}`;
  const shown: Shown = { accountId: account.id, approvalId, link: data.link };
  await chrome.storage.session.set({ [`n:${id}`]: shown });
  await chrome.notifications.create(id, {
    type: "basic",
    iconUrl: chrome.runtime.getURL("icons/icon-128.png"),
    title: (data.title ?? "Casama").slice(0, 120),
    message: (data.body ?? "").slice(0, 240),
    priority: approvalId ? 2 : 0,
    requireInteraction: !!approvalId,
    // Firefox shows no buttons: a click opens the approval in the web app instead.
    ...(approvalId && FEATURES.notificationButtons
      ? { buttons: [{ title: "Approve" }, { title: "Deny" }] }
      : {}),
  });
}

async function shownFor(id: string): Promise<Shown | null> {
  return ((await chrome.storage.session.get(`n:${id}`))[`n:${id}`] as Shown | undefined) ?? null;
}

/** Approve (button 0) or Deny (button 1) straight from the notification. */
export async function onNotificationButton(id: string, button: number) {
  const shown = await shownFor(id);
  if (!shown?.approvalId) return;
  const account = (await getLocal()).accounts.find((a) => a.id === shown.accountId);
  if (!account) return;
  const api = clientFor(account);
  try {
    await api.decideApproval(shown.approvalId, button === 0 ? "approved" : "denied");
    await chrome.notifications.clear(id);
  } catch (e) {
    await chrome.notifications.create(`${id}:error`, {
      type: "basic",
      iconUrl: chrome.runtime.getURL("icons/icon-128.png"),
      title: "Couldn't answer the approval",
      message: (e as Error).message || "Open Casama to answer it.",
    });
  }
  await updateBadge().catch(() => {});
}

/** Clicking a notification opens what it's about in the Casama app. */
export async function onNotificationClick(id: string) {
  const shown = await shownFor(id);
  if (!shown) return;
  const account = (await getLocal()).accounts.find((a) => a.id === shown.accountId);
  if (account) await chrome.tabs.create({ url: appUrl(account, shown.link ?? "/inbox") });
  await chrome.notifications.clear(id);
}

/** D1: how many things wait for the person in this workspace. */
export async function updateBadge(): Promise<number> {
  const h = await here().catch(() => null);
  if (!h) {
    await chrome.action.setBadgeText({ text: "" });
    return 0;
  }
  const badges = await h.api.unwrap(
    h.api.GET("/v1/me/badges", { signal: AbortSignal.timeout(15_000) }),
  );
  const mine = badges.items.find((b) => b.org_id === h.org.id);
  const n = (mine?.approvals ?? 0) + (mine?.unread ?? 0);
  await chrome.action.setBadgeBackgroundColor({ color: mine?.approvals ? "#b3261e" : "#1a5fd0" });
  await chrome.action.setBadgeText({ text: n ? (n > 99 ? "99+" : String(n)) : "" });
  return n;
}

/**
 * Registers this browser for pushes on [account]'s server: chrome.gcm with the server's sender id,
 * then a devices row (platform chrome). Returns false when the server has no sender id or Chrome
 * can't register, so the caller checks by polling instead.
 */
export async function registerPush(account: Account): Promise<boolean> {
  // Firefox has no chrome.gcm, and Edge has none either: both check by polling.
  if (__CASAMA_BROWSER__ === "firefox") return false;
  const api = clientFor(account);
  const config = await api.unwrap(api.GET("/v1/config", { signal: AbortSignal.timeout(15_000) }));
  const sender = (config as { push_sender_id?: string }).push_sender_id;
  if (!sender || !chrome.gcm) return false;
  const token = await new Promise<string | null>((resolve) =>
    chrome.gcm.register([sender], (id) => resolve(chrome.runtime.lastError ? null : id)),
  );
  if (!token) return false;
  await rest(account, "devices?on_conflict=fcm_token", {
    method: "POST",
    headers: { prefer: "resolution=merge-duplicates,return=minimal" },
    body: JSON.stringify({ user_id: account.userId, platform: "chrome", fcm_token: token }),
  });
  await updateLocal((s) => {
    const a = s.accounts.find((x) => x.id === account.id);
    if (a) a.deviceToken = token;
  });
  return true;
}

/**
 * "Needs you" (approvals, secrets, a hand-off) and "done" (a routine's result, a bot's message, a
 * slow reply: D-325 sends that only after 10 seconds and never for a chat on screen).
 */
export const SHOWN_KINDS = new Set([
  "approval_request",
  "secret",
  "takeover",
  "routine_result",
  "bot_message",
  "suggestion",
  "project",
  "reply",
]);

/** A push arrived (chrome.gcm.onMessage). */
export async function onPush(data: PushData & { user_id?: string }) {
  // The push names its account; older servers don't, so the active one stands in.
  const accounts = (await getLocal()).accounts;
  const account = data.user_id
    ? accounts.find((a) => a.userId === data.user_id)
    : await activeAccount();
  if (!account) return;
  if (data.kind && SHOWN_KINDS.has(data.kind)) await showNotification(account, data);
  await updateBadge().catch(() => {});
}

/**
 * The fallback (§9.4): new approvals in the active workspace, found by asking. Each one is shown
 * once per Chrome session.
 */
export async function pollApprovals(): Promise<number> {
  const h = await here().catch(() => null);
  if (!h) return 0;
  const list = await h.api.unwrap(
    h.api.GET("/v1/approvals", {
      params: { query: { org_id: h.org.id, status: "pending" } },
      signal: AbortSignal.timeout(15_000),
    }),
  );
  const seen =
    ((await chrome.storage.session.get("seenApprovals")).seenApprovals as string[] | undefined) ??
    [];
  const fresh = list.items.filter((a) => !seen.includes(a.id));
  for (const a of fresh)
    await showNotification(h.account, {
      title: "A bot needs your approval",
      body: a.summary || a.tool_name,
      link: `/approvals/${a.id}`,
      kind: "approval_request",
    });
  await chrome.storage.session.set({
    seenApprovals: [...seen, ...fresh.map((a) => a.id)].slice(-500),
  });
  return fresh.length;
}
