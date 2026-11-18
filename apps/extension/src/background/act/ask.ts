/**
 * Asking the person before a step (D-323 C6, C7): a small Casama window (an extension page, which
 * neither the page nor the bot can reach) and a notification with the same buttons. The first answer
 * wins; no answer in 5 minutes counts as no.
 *
 * Kinds: "site" (this once, always, never) and "step" (allow, deny).
 */

export type AskKind = "site" | "step";
export type SiteAnswer = "once" | "always" | "never";
export type StepAnswer = "allow" | "deny";
export type Answer = SiteAnswer | StepAnswer | "timeout";

export interface Ask {
  id: string;
  kind: AskKind;
  bot: string;
  title: string;
  detail: string;
  host?: string;
  /** The run or watcher that asked (its job key), so stopping one doesn't answer another's asks. */
  owner?: string;
  created: number;
}

const WAIT_MS = 5 * 60 * 1000;
const pending = new Map<
  string,
  {
    resolve: (a: Answer) => void;
    windowId?: number;
    timer: ReturnType<typeof setTimeout>;
    owner?: string;
  }
>();

async function saveAsks() {
  const all = ((await chrome.storage.session.get("actAsks")).actAsks as Ask[] | undefined) ?? [];
  return all.filter((a) => pending.has(a.id));
}

/** Asks and waits for the answer. */
export async function ask(input: Omit<Ask, "id" | "created">): Promise<Answer> {
  const a: Ask = { ...input, id: crypto.randomUUID(), created: Date.now() };
  const list = await saveAsks();
  const p = new Promise<Answer>((resolve) => {
    const timer = setTimeout(() => answer(a.id, "timeout"), WAIT_MS);
    pending.set(a.id, { resolve, timer, owner: a.owner });
  });
  await chrome.storage.session.set({ actAsks: [...list, a] });
  const url = chrome.runtime.getURL(`act/ask.html?id=${a.id}`);
  const w = await chrome.windows
    .create({ url, type: "popup", width: 440, height: 380, focused: true })
    .catch(() => null);
  const entry = pending.get(a.id);
  if (entry && w?.id !== undefined) entry.windowId = w.id;
  const buttons =
    a.kind === "site"
      ? [{ title: "Allow this once" }, { title: "Always allow" }]
      : [{ title: "Allow" }, { title: "Deny" }];
  await chrome.notifications
    ?.create(`act-ask:${a.id}`, {
      type: "basic",
      iconUrl: chrome.runtime.getURL("icons/icon-128.png"),
      title: a.title,
      message: a.detail,
      buttons,
      requireInteraction: true,
      priority: 2,
    })
    .catch?.(() => {});
  return p;
}

/** Records an answer (from the window, a notification or a stop) and closes what showed it. */
export function answer(id: string, value: Answer) {
  const e = pending.get(id);
  if (!e) return false;
  pending.delete(id);
  clearTimeout(e.timer);
  e.resolve(value);
  if (e.windowId !== undefined) void chrome.windows.remove(e.windowId).catch(() => {});
  void chrome.notifications?.clear(`act-ask:${id}`).catch?.(() => {});
  void saveAsks().then((list) => chrome.storage.session.set({ actAsks: list }));
  return true;
}

/** Answers every open ask with "deny" (unpairing). */
export function denyAll() {
  for (const id of [...pending.keys()]) answer(id, "deny");
}

/** Answers one run's (or watcher's) open asks with "deny" (it stopped or was cancelled). */
export function denyFor(owner: string) {
  for (const [id, e] of [...pending]) if (e.owner === owner) answer(id, "deny");
}

/** A notification button for an ask: site → [once, always]; step → [allow, deny]. */
export async function onAskNotification(notificationId: string, button: number) {
  if (!notificationId.startsWith("act-ask:")) return false;
  const id = notificationId.slice("act-ask:".length);
  const all = ((await chrome.storage.session.get("actAsks")).actAsks as Ask[] | undefined) ?? [];
  const a = all.find((x) => x.id === id);
  if (!a) return true;
  answer(
    id,
    a.kind === "site" ? (button === 0 ? "once" : "always") : button === 0 ? "allow" : "deny",
  );
  return true;
}

export function isPending(id: string) {
  return pending.has(id);
}
