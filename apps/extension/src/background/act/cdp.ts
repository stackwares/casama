/**
 * The one module that uses chrome.debugger (D-323 Phase 3, plan §9.5 and §17: kept behind one module).
 * The debugger is attached only to tabs in a bot's group while a run is using them, or to the tab
 * the person is teaching in, and detached again when idle.
 *
 * Per attached tab it keeps the last console messages, network requests and an open page dialog,
 * which the bot reads with browser.console, browser.network and answers with browser.dialog.
 */

const VERSION = "1.3";
const KEEP = 200;

export interface ConsoleLine {
  level: string;
  text: string;
}
export interface NetLine {
  id: string;
  method: string;
  url: string;
  status?: number;
  type?: string;
  failed?: string;
}

interface TabState {
  console: ConsoleLine[];
  network: Map<string, NetLine>;
  dialog: { type: string; message: string; defaultPrompt?: string } | null;
  /** Called on every event, for the overlay's bindings and the teach recorder. */
  listeners: Set<(method: string, params: Record<string, unknown>) => void>;
}

const TABS = new Map<number, TabState>();
const detaching = new Set<number>();
type DetachHandler = (tabId: number, reason: string) => void;
const detachHandlers = new Set<DetachHandler>();

export function onDetach(h: DetachHandler) {
  detachHandlers.add(h);
}

export function attached(tabId: number) {
  return TABS.has(tabId);
}

export async function attach(tabId: number): Promise<void> {
  if (TABS.has(tabId)) return;
  try {
    await chrome.debugger.attach({ tabId }, VERSION);
  } catch (e) {
    // Already attached by us in an earlier life of the service worker.
    if (!/already attached/i.test(String((e as Error).message))) throw e;
  }
  TABS.set(tabId, { console: [], network: new Map(), dialog: null, listeners: new Set() });
  await Promise.all([
    send(tabId, "Page.enable"),
    send(tabId, "Runtime.enable"),
    send(tabId, "DOM.enable"),
    send(tabId, "Network.enable", { maxTotalBufferSize: 1_000_000 }),
    send(tabId, "Log.enable"),
  ]).catch(() => {});
}

export async function detach(tabId: number): Promise<void> {
  const had = TABS.delete(tabId);
  if (!had) {
    const all = await chrome.debugger.getTargets().catch(() => []);
    if (!all.some((x) => x.tabId === tabId && x.attached)) return;
  }
  detaching.add(tabId);
  try {
    await chrome.debugger.detach({ tabId }).catch(() => {});
  } finally {
    detaching.delete(tabId);
  }
}

export async function send<T = Record<string, unknown>>(
  tabId: number,
  method: string,
  params: Record<string, unknown> = {},
  timeoutMs = 30_000,
): Promise<T> {
  let timer: ReturnType<typeof setTimeout> | undefined;
  try {
    return (await Promise.race([
      chrome.debugger.sendCommand({ tabId }, method, params),
      new Promise((_, reject) => {
        timer = setTimeout(() => reject(new Error(`${method} took too long`)), timeoutMs);
      }),
    ])) as T;
  } finally {
    clearTimeout(timer);
  }
}

export function listen(
  tabId: number,
  fn: (method: string, params: Record<string, unknown>) => void,
) {
  const s = TABS.get(tabId);
  s?.listeners.add(fn);
  return () => s?.listeners.delete(fn);
}

export function consoleOf(tabId: number) {
  return TABS.get(tabId)?.console ?? [];
}
export function networkOf(tabId: number) {
  return [...(TABS.get(tabId)?.network.values() ?? [])];
}
export function dialogOf(tabId: number) {
  return TABS.get(tabId)?.dialog ?? null;
}

const push = <T>(list: T[], x: T) => {
  list.push(x);
  if (list.length > KEEP) list.splice(0, list.length - KEEP);
};

const textOf = (args: Array<{ value?: unknown; description?: string }> | undefined) =>
  (args ?? [])
    .map((a) => (a.value !== undefined ? String(a.value) : (a.description ?? "")))
    .join(" ")
    .slice(0, 500);

/**
 * Dev and e2e builds only: what Chrome's own "Cancel" on the debugging bar does, which Playwright
 * can't click. Detaches and tells the handlers it was the person.
 */
export async function simulateCancel(tabId: number) {
  const had = TABS.delete(tabId);
  if (!had) {
    const all = await chrome.debugger.getTargets().catch(() => []);
    if (!all.some((x) => x.tabId === tabId && x.attached)) return false;
  }
  detaching.add(tabId);
  try {
    await chrome.debugger.detach({ tabId }).catch(() => {});
  } finally {
    detaching.delete(tabId);
  }
  for (const h of detachHandlers) h(tabId, "canceled_by_user");
  return true;
}

let installed = false;
/** Wires the debugger's events once per service worker. */
export function installCdp() {
  if (installed) return;
  installed = true;
  void chrome.debugger
    ?.getTargets?.()
    .then((all) => {
      for (const t of all)
        if (t.attached && t.tabId !== undefined && !TABS.has(t.tabId))
          TABS.set(t.tabId, {
            console: [],
            network: new Map(),
            dialog: null,
            listeners: new Set(),
          });
    })
    .catch(() => {});
  chrome.debugger.onEvent.addListener((source, method, params) => {
    const tabId = source.tabId;
    if (tabId === undefined) return;
    const s = TABS.get(tabId);
    if (!s) return;
    const p = (params ?? {}) as Record<string, unknown>;
    switch (method) {
      case "Runtime.consoleAPICalled":
        push(s.console, {
          level: String(p.type),
          text: textOf(p.args as Array<{ value?: unknown; description?: string }>),
        });
        break;
      case "Runtime.exceptionThrown": {
        const d = p.exceptionDetails as { text?: string; exception?: { description?: string } };
        push(s.console, {
          level: "error",
          text: (d?.exception?.description ?? d?.text ?? "Uncaught error").slice(0, 500),
        });
        break;
      }
      case "Log.entryAdded": {
        const e = p.entry as { level: string; text: string };
        push(s.console, { level: e.level, text: e.text.slice(0, 500) });
        break;
      }
      case "Network.requestWillBeSent": {
        const r = p.request as { method: string; url: string };
        if (/^data:/.test(r.url)) break;
        s.network.set(String(p.requestId), {
          id: String(p.requestId),
          method: r.method,
          url: r.url.slice(0, 500),
          type: p.type as string | undefined,
        });
        if (s.network.size > KEEP) s.network.delete(s.network.keys().next().value as string);
        break;
      }
      case "Network.responseReceived": {
        const n = s.network.get(String(p.requestId));
        if (n) n.status = (p.response as { status: number }).status;
        break;
      }
      case "Network.loadingFailed": {
        const n = s.network.get(String(p.requestId));
        if (n) n.failed = String(p.errorText ?? "failed");
        break;
      }
      case "Page.javascriptDialogOpening":
        s.dialog = {
          type: String(p.type),
          message: String(p.message ?? "").slice(0, 1000),
          defaultPrompt: p.defaultPrompt as string | undefined,
        };
        break;
      case "Page.javascriptDialogClosed":
        s.dialog = null;
        break;
    }
    for (const l of s.listeners) {
      try {
        l(method, p);
      } catch {
        // A listener's mistake doesn't stop the others.
      }
    }
  });
  chrome.debugger.onDetach.addListener((source, reason) => {
    const tabId = source.tabId;
    if (tabId === undefined) return;
    TABS.delete(tabId);
    if (detaching.has(tabId)) return;
    for (const h of detachHandlers) h(tabId, reason);
  });
}

/**
 * A tab's address and title through the debugger, which needs no `tabs` permission or host access
 * (chrome.tabs leaves them empty without those, as in the store build's "on click" site access).
 */
export async function targetInfo(tabId: number): Promise<{ url: string; title: string }> {
  const all = await chrome.debugger.getTargets().catch(() => []);
  const t = all.find((x) => x.tabId === tabId && x.type === "page");
  return { url: t?.url ?? "", title: t?.title ?? "" };
}
