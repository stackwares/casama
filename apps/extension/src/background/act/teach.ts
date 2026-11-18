/**
 * Teach by showing, in this browser (D-323 C11): the person does a task once in a tab and the steps
 * go to `/v1/teach`, which drafts a skill; the skill's steps replay in this browser (C12).
 *
 * What's recorded: pages opened by typing an address, clicks (as the element's role and name, not
 * coordinates), what was typed into fields (on change), and Enter. Password fields are never
 * recorded: the step says a password goes there and the text is not sent. The recorder runs in an
 * isolated world and only real input counts.
 */

import { siteDecision } from "../../lib/act/sites.ts";
import { guardAdditions } from "../../lib/guard-sites.ts";
import { clientFor } from "../../lib/session.ts";
import { getLocal } from "../../lib/store.ts";
import * as cdp from "./cdp.ts";
import { pairedDevice } from "./device.ts";
import { hideOverlay, showOverlay } from "./overlay.ts";

const WORLD = "casama-teach";
const BINDING = "casamaTeach";

export interface TeachState {
  sessionId: string;
  tabId: number;
  botId: string;
  steps: number;
  status: "recording" | "stopped";
}

let current: (TeachState & { off: () => void; scriptId: string | null; lastAct: number }) | null =
  null;

/** Steps waiting to be sent, in order; stopping waits for them. */
let queue: Promise<void> = Promise.resolve();

const RECORDER = `(() => {
  if (window.__casamaTeach) return;
  window.__casamaTeach = true;
  const send = (s) => { try { ${BINDING}(JSON.stringify(s)); } catch {} };
  const ROLE = { A: "link", BUTTON: "button", SELECT: "combobox", TEXTAREA: "textbox", SUMMARY: "button" };
  const INPUT = { checkbox: "checkbox", radio: "radio", submit: "button", button: "button", reset: "button", image: "button", search: "searchbox", range: "slider", number: "spinbutton" };
  const roleOf = (el) => el.getAttribute("role") || (el.tagName === "INPUT" ? (INPUT[(el.type || "text").toLowerCase()] || "textbox") : ROLE[el.tagName] || "generic");
  const nameOf = (el) => {
    const t = (s) => (s || "").replace(/\\s+/g, " ").trim().slice(0, 200);
    const by = el.getAttribute("aria-labelledby");
    if (by) { const n = by.split(/\\s+/).map((id) => document.getElementById(id)?.innerText || "").join(" "); if (t(n)) return t(n); }
    if (t(el.getAttribute("aria-label"))) return t(el.getAttribute("aria-label"));
    if (el.labels && el.labels.length) return t([...el.labels].map((l) => l.innerText).join(" "));
    if (/^(INPUT|TEXTAREA|SELECT)$/.test(el.tagName)) return t(el.getAttribute("placeholder") || el.getAttribute("title") || el.name || (el.type === "submit" ? el.value || "Submit" : ""));
    return t(el.innerText || el.value || el.getAttribute("title") || el.getAttribute("alt"));
  };
  const target = (el) => el && el.closest ? el.closest('a[href],button,input,select,textarea,summary,label,[role="button"],[role="link"],[role="tab"],[role="menuitem"],[role="option"],[role="checkbox"],[role="switch"],[contenteditable="true"]') : null;
  addEventListener("click", (e) => {
    if (!e.isTrusted) return;
    let el = target(e.composedPath()[0]);
    if (!el) return;
    if (el.tagName === "LABEL" && el.control) el = el.control;
    // Typing into a field is recorded on change, not the click that focused it.
    if (/^(INPUT|TEXTAREA)$/.test(el.tagName) && !/^(checkbox|radio|submit|button|reset|image|file)$/i.test(el.type || "")) return;
    const name = nameOf(el);
    if (name) send({ kind: "click", target: { role: roleOf(el), name } });
  }, true);
  // What each field last recorded, so a value is recorded once (on Enter or on change).
  const recorded = new WeakMap();
  const recordField = (el) => {
    if (!el || !/^(INPUT|TEXTAREA|SELECT)$/.test(el.tagName)) return;
    const type = (el.type || "").toLowerCase();
    if (/^(checkbox|radio|submit|button|reset|image|file|hidden)$/.test(type)) return;
    const value = el.tagName === "SELECT" ? (el.selectedOptions[0]?.text || el.value) : el.value;
    if (recorded.get(el) === value) return;
    recorded.set(el, value);
    const name = nameOf(el) || "field";
    const password = type === "password" || /password/.test(el.autocomplete || "");
    send({ kind: "type", target: { role: roleOf(el), name }, password, text: password ? "" : String(value).slice(0, 2000) });
  };
  const focused = () => {
    let el = document.activeElement;
    while (el && el.shadowRoot && el.shadowRoot.activeElement) el = el.shadowRoot.activeElement;
    return el;
  };
  addEventListener("change", (e) => {
    if (!e.isTrusted) return;
    recordField(e.composedPath()[0]);
  }, true);
  addEventListener("keydown", (e) => {
    if (!e.isTrusted || e.key !== "Enter" || e.isComposing) return;
    // Enter fires before the field's change event: what was typed comes first.
    recordField(focused());
    send({ kind: "key", key: "Enter" });
  }, true);
})()`;

async function world(tabId: number) {
  const { frameTree } = await cdp.send<{ frameTree: { frame: { id: string } } }>(
    tabId,
    "Page.getFrameTree",
  );
  const { executionContextId } = await cdp.send<{ executionContextId: number }>(
    tabId,
    "Page.createIsolatedWorld",
    {
      frameId: frameTree.frame.id,
      worldName: WORLD,
      grantUniveralAccess: false,
    },
  );
  return executionContextId;
}

async function api() {
  const d = await pairedDevice();
  if (!d) throw new Error("Pair this browser first (Let bots use this browser).");
  const account = (await getLocal()).accounts.find((a) => a.id === d.accountId);
  if (!account) throw new Error("Sign in to the account this browser was paired with.");
  return { d, api: clientFor(account) };
}

async function publish() {
  await chrome.storage.session.set({
    actTeach: current
      ? {
          sessionId: current.sessionId,
          tabId: current.tabId,
          botId: current.botId,
          steps: current.steps,
          status: current.status,
        }
      : null,
  });
}

/** Starts recording in [tabId] for [botId]. */
export async function startTeach(tabId: number, botId: string): Promise<TeachState> {
  if (current) throw new Error("A recording is already running.");
  // Through the debugger: chrome.tabs leaves the address empty without host access.
  const url = (await cdp.targetInfo(tabId)).url;
  const d0 = siteDecision(
    url,
    { blocked_sites: [], allowed_sites: [], allowed_kinds: [], own_urls: [] },
    { extraHosts: await guardAdditions() },
  );
  if (d0.kind === "refused") throw new Error(d0.reason);
  const { d, api: client } = await api();
  const session = await client.unwrap(
    client.POST("/v1/teach", { body: { device_id: d.deviceId, bot_id: botId } }),
  );
  await cdp.attach(tabId);
  await cdp
    .send(tabId, "Runtime.addBinding", { name: BINDING, executionContextName: WORLD })
    .catch(() => {});
  // One step at a time: the server numbers steps in the order they arrive.
  queue = Promise.resolve();
  const add = (step: Record<string, unknown>) => {
    if (!current) return queue;
    current.steps++;
    void publish();
    queue = queue
      .then(() =>
        client.POST("/v1/teach/{id}/steps", {
          params: { path: { id: session.id } },
          body: step as never,
        }),
      )
      .then(
        () => {},
        () => {},
      );
    return queue;
  };
  let first = true;
  const off = cdp.listen(tabId, (method, p) => {
    if (method === "Runtime.bindingCalled" && p.name === BINDING) {
      try {
        const s = JSON.parse(String(p.payload)) as Record<string, unknown>;
        if (current) current.lastAct = Date.now();
        void add({ ...s, url: undefined });
      } catch {
        // Not ours.
      }
    }
    if (method === "Page.frameNavigated") {
      const f = p.frame as { parentId?: string; url: string };
      if (f.parentId) return;
      // A page opened by typing an address (not one a click or Enter led to).
      if (!first && current && Date.now() - current.lastAct > 2500 && /^https?:/.test(f.url))
        void add({ kind: "open", url: f.url });
      first = false;
    }
  });
  const { identifier } = await cdp
    .send<{ identifier: string }>(tabId, "Page.addScriptToEvaluateOnNewDocument", {
      source: RECORDER,
      worldName: WORLD,
    })
    .catch(() => ({ identifier: "" }));
  await cdp
    .send(tabId, "Runtime.evaluate", { expression: RECORDER, contextId: await world(tabId) })
    .catch(() => {});
  current = {
    sessionId: session.id,
    tabId,
    botId,
    steps: 0,
    status: "recording",
    off,
    scriptId: identifier || null,
    lastAct: 0,
  };
  await showOverlay(tabId, "Casama", "teaching", (e) => {
    if (e.type === "stop") void stopTeach();
  });
  // The page it starts on is the first step.
  if (/^https?:/.test(url)) await add({ kind: "open", url });
  await publish();
  return { sessionId: session.id, tabId, botId, steps: current.steps, status: "recording" };
}

/** Stops recording; the server drafts the skill. */
export async function stopTeach(): Promise<string | null> {
  const c = current;
  if (!c) return null;
  current = null;
  c.off();
  await hideOverlay(c.tabId).catch(() => {});
  if (c.scriptId)
    await cdp
      .send(c.tabId, "Page.removeScriptToEvaluateOnNewDocument", { identifier: c.scriptId })
      .catch(() => {});
  await cdp.detach(c.tabId);
  await queue;
  const { api: client } = await api();
  await client.POST("/v1/teach/{id}/stop", { params: { path: { id: c.sessionId } } });
  await chrome.storage.session.set({
    actTeach: {
      sessionId: c.sessionId,
      tabId: c.tabId,
      botId: c.botId,
      steps: c.steps,
      status: "stopped",
    },
  });
  return c.sessionId;
}

/** The person closed the tab or pressed Chrome's Cancel: the recording ends. */
export function onTeachTabGone(tabId: number) {
  if (current?.tabId === tabId) void stopTeach().catch(() => {});
}
