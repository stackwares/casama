/**
 * The frame and banner on a tab a bot is working in (D-323 C4, C5): "<Bot> is working in this tab",
 * with Stop; touching the page pauses the bot ("You took over", with Hand back).
 *
 * It lives in an isolated world the page's scripts can't reach, in a closed shadow root, hidden from
 * the accessibility tree so a bot never sees (or clicks) it. It talks back through a debugger binding
 * that only that world has, and only real input from the person (isTrusted) counts. The background
 * ignores input that arrives within 500 ms of its own, since the bot's input is real input too.
 */
import { listen, send } from "./cdp.ts";

export const OVERLAY_WORLD = "casama-overlay";
const BINDING = "casamaOverlay";

export type OverlayState = "working" | "paused" | "asking" | "teaching";

export type OverlayEvent =
  | { type: "stop"; at: number }
  | { type: "takeover"; at: number }
  | { type: "handback"; at: number };

/** The overlay's script. [label] and [state] are filled in; it re-reads state from its dataset. */
function overlaySource(label: string, state: OverlayState) {
  return `(() => {
  // The banner belongs to the tab, not to every frame in it.
  if (window.top !== window) return;
  if (window.__casamaOverlay) { window.__casamaOverlay.set(${JSON.stringify(label)}, ${JSON.stringify(state)}); return; }
  const send = (type) => { try { ${BINDING}(JSON.stringify({ type, at: Date.now() })); } catch {} };
  let host, root, bar, text, btn, label = ${JSON.stringify(label)}, state = ${JSON.stringify(state)};
  const words = {
    working: (l) => [l + " is working in this tab", "Stop"],
    paused: () => ["You took over. The bot waits until you hand back.", "Hand back"],
    asking: (l) => [l + " is waiting for you in the Casama window", "Stop"],
    teaching: () => ["Recording what you do for a new skill. Passwords are never recorded.", "Stop recording"],
  };
  const paint = () => {
    if (!host) return;
    const [t, b] = words[state](label);
    text.textContent = t; btn.textContent = b;
    host.dataset.state = state;
  };
  const mount = () => {
    if (host && host.isConnected) return;
    host = document.createElement("casama-overlay");
    host.setAttribute("aria-hidden", "true");
    root = host.attachShadow({ mode: "closed" });
    root.innerHTML = '<style>' +
      ':host{all:initial}' +
      '.frame{position:fixed;inset:0;border:3px solid #7c5cff;pointer-events:none;z-index:2147483646;border-radius:2px}' +
      '.bar{position:fixed;top:8px;left:50%;transform:translateX(-50%);z-index:2147483647;display:flex;gap:12px;align-items:center;' +
      'background:#1d1b26;color:#fff;font:500 13px/1.3 system-ui,sans-serif;padding:8px 8px 8px 14px;border-radius:999px;box-shadow:0 4px 16px rgba(0,0,0,.3)}' +
      'button{all:unset;cursor:pointer;background:#fff;color:#1d1b26;font-weight:600;padding:5px 12px;border-radius:999px}' +
      '</style><div class="frame"></div><div class="bar"><span></span><button type="button"></button></div>';
    bar = root.querySelector(".bar"); text = bar.querySelector("span"); btn = bar.querySelector("button");
    btn.addEventListener("click", (e) => {
      if (!e.isTrusted) return;
      e.stopPropagation();
      send(state === "paused" ? "handback" : "stop");
    });
    (document.documentElement || document).appendChild(host);
    paint();
  };
  const touched = (e) => {
    if (!e.isTrusted || state !== "working") return;
    if (host && e.composedPath().includes(host)) return;
    send("takeover");
  };
  addEventListener("pointerdown", touched, true);
  addEventListener("keydown", touched, true);
  window.__casamaOverlay = {
    set(l, s) { label = l; state = s; mount(); paint(); },
    remove() { removeEventListener("pointerdown", touched, true); removeEventListener("keydown", touched, true); host && host.remove(); host = null; delete window.__casamaOverlay; },
  };
  if (document.documentElement) mount(); else addEventListener("DOMContentLoaded", mount, { once: true });
  // Pages that replace the whole document body still get the banner back.
  setInterval(() => { if (window.__casamaOverlay && (!host || !host.isConnected)) mount(); }, 1000);
})()`;
}

interface Shown {
  scriptId: string | null;
  label: string;
  state: OverlayState;
  stop: () => void;
}
const SHOWN = new Map<number, Shown>();

async function evalInWorld(tabId: number, expression: string) {
  const { frameTree } = await send<{ frameTree: { frame: { id: string } } }>(
    tabId,
    "Page.getFrameTree",
  );
  const { executionContextId } = await send<{ executionContextId: number }>(
    tabId,
    "Page.createIsolatedWorld",
    { frameId: frameTree.frame.id, worldName: OVERLAY_WORLD, grantUniveralAccess: false },
  );
  await send(tabId, "Runtime.evaluate", { expression, contextId: executionContextId });
}

/** Shows (or updates) the overlay on an attached tab; [onEvent] gets the person's presses. */
export async function showOverlay(
  tabId: number,
  label: string,
  state: OverlayState,
  onEvent: (e: OverlayEvent) => void,
) {
  const had = SHOWN.get(tabId);
  if (had) {
    had.label = label;
    had.state = state;
    await evalInWorld(tabId, overlaySource(label, state)).catch(() => {});
    if (had.scriptId) {
      // New pages in this tab start with the current words.
      await send(tabId, "Page.removeScriptToEvaluateOnNewDocument", {
        identifier: had.scriptId,
      }).catch(() => {});
      had.scriptId = await addScript(tabId, label, state);
    }
    return;
  }
  await send(tabId, "Runtime.addBinding", {
    name: BINDING,
    executionContextName: OVERLAY_WORLD,
  }).catch(() => {});
  const stop = listen(tabId, (method, p) => {
    if (method !== "Runtime.bindingCalled" || p.name !== BINDING) return;
    try {
      const e = JSON.parse(String(p.payload)) as OverlayEvent;
      if (e.type === "stop" || e.type === "takeover" || e.type === "handback") onEvent(e);
    } catch {
      // Not ours.
    }
  });
  const shown: Shown = { scriptId: null, label, state, stop };
  SHOWN.set(tabId, shown);
  shown.scriptId = await addScript(tabId, label, state);
  await evalInWorld(tabId, overlaySource(label, state)).catch(() => {});
}

async function addScript(tabId: number, label: string, state: OverlayState) {
  const r = await send<{ identifier: string }>(tabId, "Page.addScriptToEvaluateOnNewDocument", {
    source: overlaySource(label, state),
    worldName: OVERLAY_WORLD,
  }).catch(() => null);
  return r?.identifier ?? null;
}

export function overlayState(tabId: number) {
  return SHOWN.get(tabId)?.state ?? null;
}

/** Takes the overlay off (before detaching). */
export async function hideOverlay(tabId: number) {
  const s = SHOWN.get(tabId);
  if (!s) return;
  SHOWN.delete(tabId);
  s.stop();
  if (s.scriptId)
    await send(tabId, "Page.removeScriptToEvaluateOnNewDocument", { identifier: s.scriptId }).catch(
      () => {},
    );
  await evalInWorld(tabId, "window.__casamaOverlay && window.__casamaOverlay.remove()").catch(
    () => {},
  );
}

/** Forgets a tab whose debugger went away (nothing to remove: the page keeps no binding). */
export function forgetOverlay(tabId: number) {
  const s = SHOWN.get(tabId);
  s?.stop();
  SHOWN.delete(tabId);
}
