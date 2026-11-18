/**
 * What a bot does on one tab, through the debugger (D-323 C2): snapshots with refs, real clicks and
 * keys, filling fields, scrolling, screenshots, reading, upload fields, downloads and tables.
 *
 * Page scripts can't be trusted (plan §11), so anything read from the page runs in an isolated world
 * (its own copy of the page's JavaScript globals), and a click first checks that the element is
 * really the one under the pointer, so a transparent layer can't take the click.
 */
import { EXTRACT_TABLES_JS } from "../../../../../packages/contracts/src/browser-scripts.ts";
import {
  type AXNode,
  type DomSnapshot,
  formatSnapshot,
  hiddenNodes,
  type Ref,
  readableText,
  SNAPSHOT_STYLES,
} from "../../lib/act/snapshot.ts";
import { send } from "./cdp.ts";

const WORLD = "casama-act";

export interface FrameAx {
  frameId: string;
  nodes: AXNode[];
}

async function frames(tabId: number): Promise<string[]> {
  type Tree = { frame: { id: string }; childFrames?: Tree[] };
  const { frameTree } = await send<{ frameTree: Tree }>(tabId, "Page.getFrameTree");
  const out: string[] = [];
  const walk = (t: Tree) => {
    out.push(t.frame.id);
    for (const c of t.childFrames ?? []) walk(c);
  };
  walk(frameTree);
  return out;
}

/** The accessibility trees of the page and its frames (same-process frames; others are skipped). */
async function axTrees(tabId: number): Promise<FrameAx[]> {
  await send(tabId, "Accessibility.enable").catch(() => {});
  const out: FrameAx[] = [];
  for (const frameId of (await frames(tabId)).slice(0, 20)) {
    const r = await send<{ nodes: AXNode[] }>(tabId, "Accessibility.getFullAXTree", {
      frameId,
    }).catch(() => null);
    if (r) out.push({ frameId, nodes: r.nodes });
  }
  return out;
}

async function hidden(tabId: number): Promise<Set<number>> {
  const snap = await send<DomSnapshot>(tabId, "DOMSnapshot.captureSnapshot", {
    computedStyles: [...SNAPSHOT_STYLES],
  }).catch(() => null);
  return snap ? hiddenNodes(snap) : new Set();
}

export async function snapshot(
  tabId: number,
  interactiveOnly: boolean,
): Promise<{ text: string; refs: Record<string, Ref> }> {
  const [trees, hide] = await Promise.all([axTrees(tabId), hidden(tabId)]);
  const refs: Record<string, Ref> = {};
  const parts: string[] = [];
  let next = 1;
  for (const [i, t] of trees.entries()) {
    const r = formatSnapshot(t.nodes, hide, { interactiveOnly, startAt: next });
    next = r.next;
    Object.assign(refs, r.refs);
    if (i === 0) parts.push(r.text);
    else if (Object.keys(r.refs).length || !interactiveOnly) parts.push(`- frame:\n${r.text}`);
  }
  return { text: parts.join("\n"), refs };
}

export async function read(tabId: number): Promise<string> {
  const [trees, hide] = await Promise.all([axTrees(tabId), hidden(tabId)]);
  return trees
    .map((t) => readableText(t.nodes, hide))
    .filter(Boolean)
    .join("\n\n");
}

/** A fresh isolated world in the main frame; returns its context id. */
async function world(tabId: number): Promise<number> {
  const { frameTree } = await send<{ frameTree: { frame: { id: string } } }>(
    tabId,
    "Page.getFrameTree",
  );
  const r = await send<{ executionContextId: number }>(tabId, "Page.createIsolatedWorld", {
    frameId: frameTree.frame.id,
    worldName: WORLD,
    grantUniveralAccess: false,
  });
  return r.executionContextId;
}

/** Runs [expression] in an isolated world of the page and returns its value. */
export async function evaluate<T>(
  tabId: number,
  expression: string,
  timeoutMs = 30_000,
): Promise<T> {
  const contextId = await world(tabId);
  const r = await send<{ result: { value?: T }; exceptionDetails?: { text: string } }>(
    tabId,
    "Runtime.evaluate",
    { expression, contextId, returnByValue: true, awaitPromise: true },
    timeoutMs,
  );
  if (r.exceptionDetails) throw new Error(r.exceptionDetails.text);
  return r.result.value as T;
}

/** Calls [fn] (source of `function (...args) {}`) with `this` = the element, in an isolated world. */
export async function onNode<T>(
  tabId: number,
  backendNodeId: number,
  fn: string,
  args: unknown[] = [],
): Promise<T> {
  const contextId = await world(tabId).catch(() => undefined);
  const { object } = await send<{ object: { objectId: string } }>(tabId, "DOM.resolveNode", {
    backendNodeId,
    ...(contextId ? { executionContextId: contextId } : {}),
  });
  const r = await send<{ result: { value?: T }; exceptionDetails?: { text: string } }>(
    tabId,
    "Runtime.callFunctionOn",
    {
      objectId: object.objectId,
      functionDeclaration: fn,
      arguments: args.map((value) => ({ value })),
      returnByValue: true,
      awaitPromise: true,
    },
  );
  if (r.exceptionDetails) throw new Error(r.exceptionDetails.text);
  return r.result.value as T;
}

export interface NodeInfo {
  tag: string;
  inputType: string;
  autocomplete: string;
  submits: boolean;
  passwordForm: boolean;
  href: string | null;
  isFile: boolean;
  formSubmitName: string;
  inForm: boolean;
  /** A text field or an editable area (contenteditable). */
  editable: boolean;
  role: string;
}

/** What risk.ts needs to know about an element. */
export function nodeInfo(tabId: number, backendNodeId: number) {
  return onNode<NodeInfo>(
    tabId,
    backendNodeId,
    `function () {
      const el = this.nodeType === 1 ? this : this.parentElement;
      const tag = (el?.tagName || "").toLowerCase();
      const form = el?.form || el?.closest?.("form") || null;
      const type = (el?.getAttribute?.("type") || "").toLowerCase();
      const submits = !!form && ((tag === "button" && type !== "button" && type !== "reset") || (tag === "input" && (type === "submit" || type === "image")));
      const passwordForm = !!form && !!form.querySelector('input[type="password"]');
      const btn = form ? form.querySelector('button:not([type="button"]):not([type="reset"]), input[type="submit"]') : null;
      const a = el?.closest?.("a[href]");
      return {
        tag, inputType: type, autocomplete: (el?.getAttribute?.("autocomplete") || "").toLowerCase(),
        submits, passwordForm, href: a ? a.href : null, isFile: tag === "input" && type === "file",
        inForm: !!form,
        editable: !!el && (el.isContentEditable || tag === "textarea" || (tag === "input" && !/^(checkbox|radio|submit|button|reset|image|file|hidden|range|color)$/.test(type))),
        role: (el?.getAttribute?.("role") || "").toLowerCase(),
        formSubmitName: btn ? (btn.innerText || btn.value || btn.getAttribute("aria-label") || "").trim().slice(0, 100) : "",
      };
    }`,
  );
}

/**
 * The focused element of the page, as a backend node id, looking inside open shadow roots and
 * same-origin frames. "unknown" when focus is somewhere Casama can't look: a frame from another
 * site (card and sign-in boxes) or a closed shadow root.
 */
export async function focusedNode(tabId: number): Promise<number | null | "unknown"> {
  const contextId = await world(tabId);
  const r = await send<{ result: { objectId?: string; value?: string } }>(
    tabId,
    "Runtime.evaluate",
    {
      expression: `(() => {
        let el = document.activeElement;
        for (let i = 0; i < 20 && el; i++) {
          if (el.shadowRoot && el.shadowRoot.activeElement) { el = el.shadowRoot.activeElement; continue; }
          if (el.tagName === "IFRAME" || el.tagName === "FRAME") {
            let doc = null;
            try { doc = el.contentDocument; } catch {}
            if (!doc) return "unknown";
            el = doc.activeElement;
            continue;
          }
          break;
        }
        if (!el || el === document.body || el.tagName === "BODY") return null;
        return el;
      })()`,
      contextId,
    },
  );
  if (r.result.value === "unknown") return "unknown";
  if (!r.result.objectId) return null;
  const d = await send<{
    node: { backendNodeId: number; shadowRoots?: Array<{ shadowRootType?: string }> };
  }>(tabId, "DOM.describeNode", { objectId: r.result.objectId, pierce: true, depth: 1 });
  // Focus inside a closed shadow root shows as its host: the real field is out of sight.
  if (d.node.shadowRoots?.some((s) => s.shadowRootType === "closed")) return "unknown";
  return d.node.backendNodeId;
}

async function center(tabId: number, backendNodeId: number) {
  await send(tabId, "DOM.scrollIntoViewIfNeeded", { backendNodeId }).catch(() => {});
  const { model } = await send<{ model: { content: number[]; width: number; height: number } }>(
    tabId,
    "DOM.getBoxModel",
    { backendNodeId },
  );
  const q = model.content;
  const x = ((q[0] ?? 0) + (q[2] ?? 0) + (q[4] ?? 0) + (q[6] ?? 0)) / 4;
  const y = ((q[1] ?? 0) + (q[3] ?? 0) + (q[5] ?? 0) + (q[7] ?? 0)) / 4;
  if (model.width < 1 || model.height < 1)
    throw new ActError("hidden", "That element isn't visible.");
  return { x, y };
}

export class ActError extends Error {
  readonly code: string;
  constructor(code: string, message: string) {
    super(message);
    this.code = code;
  }
}

/** Whether the element really is what's under the point (not covered by another layer). */
async function onTop(tabId: number, backendNodeId: number, x: number, y: number) {
  const hit = await send<{ backendNodeId: number }>(tabId, "DOM.getNodeForLocation", {
    x: Math.round(x),
    y: Math.round(y),
    includeUserAgentShadowDOM: true,
  }).catch(() => null);
  if (!hit) return true;
  if (hit.backendNodeId === backendNodeId) return true;
  const contextId = await world(tabId);
  const resolve = (id: number) =>
    send<{ object: { objectId: string } }>(tabId, "DOM.resolveNode", {
      backendNodeId: id,
      executionContextId: contextId,
    });
  const [a, b] = await Promise.all([resolve(backendNodeId), resolve(hit.backendNodeId)]);
  const r = await send<{ result: { value?: boolean } }>(tabId, "Runtime.callFunctionOn", {
    objectId: a.object.objectId,
    functionDeclaration: `function (hit) {
      const host = (n) => { const r = n.getRootNode && n.getRootNode(); return r && r.host ? r.host : null; };
      let h = hit;
      while (h) { if (h === this || this.contains(h)) return true; h = host(h); }
      // A label for this field counts as this field.
      return !!(hit.closest && hit.closest("label") && hit.closest("label").control === this);
    }`,
    arguments: [{ objectId: b.object.objectId }],
    returnByValue: true,
  });
  return r.result.value === true;
}

export interface Pointer {
  /** Called right before input is sent, so the overlay doesn't take it for the person's. */
  beforeInput(): void;
}

export async function click(tabId: number, backendNodeId: number, p: Pointer) {
  const { x, y } = await center(tabId, backendNodeId);
  if (!(await onTop(tabId, backendNodeId, x, y)))
    throw new ActError(
      "covered",
      "Something else on the page covers that element, so it wasn't clicked. Take a new snapshot.",
    );
  p.beforeInput();
  const base = { x, y, button: "left", clickCount: 1 };
  await send(tabId, "Input.dispatchMouseEvent", { type: "mouseMoved", x, y });
  await send(tabId, "Input.dispatchMouseEvent", { type: "mousePressed", ...base });
  await send(tabId, "Input.dispatchMouseEvent", { type: "mouseReleased", ...base });
}

export async function fill(tabId: number, backendNodeId: number, text: string, p: Pointer) {
  await send(tabId, "DOM.scrollIntoViewIfNeeded", { backendNodeId }).catch(() => {});
  await send(tabId, "DOM.focus", { backendNodeId });
  await onNode(
    tabId,
    backendNodeId,
    `function () {
      if (typeof this.select === "function" && /^(input|textarea)$/i.test(this.tagName)) this.select();
      else if (this.isContentEditable) { const r = document.createRange(); r.selectNodeContents(this); const s = getSelection(); s.removeAllRanges(); s.addRange(r); }
    }`,
  );
  p.beforeInput();
  if (text) await send(tabId, "Input.insertText", { text });
  else await key(tabId, "Delete", p);
}

export async function type(tabId: number, text: string, p: Pointer) {
  p.beforeInput();
  await send(tabId, "Input.insertText", { text });
}

const KEYS: Record<string, { code: string; keyCode: number; text?: string }> = {
  Enter: { code: "Enter", keyCode: 13, text: "\r" },
  Tab: { code: "Tab", keyCode: 9 },
  Escape: { code: "Escape", keyCode: 27 },
  Backspace: { code: "Backspace", keyCode: 8 },
  Delete: { code: "Delete", keyCode: 46 },
  Space: { code: "Space", keyCode: 32, text: " " },
  ArrowUp: { code: "ArrowUp", keyCode: 38 },
  ArrowDown: { code: "ArrowDown", keyCode: 40 },
  ArrowLeft: { code: "ArrowLeft", keyCode: 37 },
  ArrowRight: { code: "ArrowRight", keyCode: 39 },
  PageUp: { code: "PageUp", keyCode: 33 },
  PageDown: { code: "PageDown", keyCode: 34 },
  Home: { code: "Home", keyCode: 36 },
  End: { code: "End", keyCode: 35 },
};
const MODS: Record<string, number> = { Alt: 1, Control: 2, Ctrl: 2, Meta: 4, Cmd: 4, Shift: 8 };

/** A key or a combination such as "Enter", "Control+a" or "Shift+Tab". */
export async function key(tabId: number, combo: string, p: Pointer) {
  const parts = combo.split("+").filter(Boolean);
  const k = parts.pop() ?? combo;
  let modifiers = 0;
  for (const m of parts) modifiers |= MODS[m] ?? 0;
  const known = KEYS[k === " " ? "Space" : k];
  const single = k.length === 1 ? k : undefined;
  const ev = {
    key: known ? (k === "Space" ? " " : k) : k,
    code: known?.code ?? (single ? `Key${single.toUpperCase()}` : k),
    windowsVirtualKeyCode: known?.keyCode ?? (single ? single.toUpperCase().charCodeAt(0) : 0),
    modifiers,
  };
  const text = modifiers & ~8 ? undefined : (known?.text ?? single);
  p.beforeInput();
  await send(tabId, "Input.dispatchKeyEvent", {
    type: text ? "keyDown" : "rawKeyDown",
    ...ev,
    ...(text ? { text } : {}),
  });
  await send(tabId, "Input.dispatchKeyEvent", { type: "keyUp", ...ev });
}

export async function scroll(tabId: number, direction: "up" | "down", amount: number, p: Pointer) {
  const { layoutViewport } = await send<{
    layoutViewport: { clientWidth: number; clientHeight: number };
  }>(tabId, "Page.getLayoutMetrics");
  p.beforeInput();
  await send(tabId, "Input.dispatchMouseEvent", {
    type: "mouseWheel",
    x: Math.round(layoutViewport.clientWidth / 2),
    y: Math.round(layoutViewport.clientHeight / 2),
    deltaX: 0,
    deltaY: direction === "down" ? amount : -amount,
  });
}

export async function screenshot(tabId: number) {
  const r = await send<{ data: string }>(
    tabId,
    "Page.captureScreenshot",
    { format: "jpeg", quality: 70, captureBeyondViewport: false },
    20_000,
  );
  return { data: r.data, media_type: "image/jpeg" };
}

export async function upload(
  tabId: number,
  backendNodeId: number,
  file: { name: string; media_type: string; data: string },
) {
  return onNode<string>(
    tabId,
    backendNodeId,
    `function (name, type, b64) {
      if (!(this instanceof HTMLInputElement) || this.type !== "file") throw new Error("That isn't an upload field.");
      const bin = atob(b64); const bytes = new Uint8Array(bin.length);
      for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
      const dt = new DataTransfer(); dt.items.add(new File([bytes], name, { type }));
      this.files = dt.files;
      this.dispatchEvent(new Event("input", { bubbles: true }));
      this.dispatchEvent(new Event("change", { bubbles: true }));
      return name;
    }`,
    [file.name, file.media_type, file.data],
  );
}

/** Downloads [url] with the page's own sign-in (same rules as the page's own requests). */
export async function download(tabId: number, url: string, max: number) {
  return evaluate<{ name: string; media_type: string; data: string } | { error: string }>(
    tabId,
    `(async () => {
      const res = await fetch(${JSON.stringify(url)}, { credentials: "include" });
      if (!res.ok) return { error: "The site answered " + res.status };
      const len = Number(res.headers.get("content-length") || 0);
      if (len > ${max}) return { error: "The file is over 20 MB" };
      const buf = new Uint8Array(await res.arrayBuffer());
      if (buf.length > ${max}) return { error: "The file is over 20 MB" };
      let bin = ""; for (let i = 0; i < buf.length; i += 0x8000) bin += String.fromCharCode.apply(null, buf.subarray(i, i + 0x8000));
      const cd = res.headers.get("content-disposition") || "";
      const m = /filename\\*?=(?:UTF-8'')?"?([^";]+)"?/i.exec(cd);
      const name = decodeURIComponent((m && m[1]) || new URL(res.url).pathname.split("/").pop() || "download");
      return { name, media_type: (res.headers.get("content-type") || "application/octet-stream").split(";")[0], data: btoa(bin) };
    })()`,
    120_000,
  );
}

export function extractTables(tabId: number) {
  return evaluate<unknown>(tabId, EXTRACT_TABLES_JS).then((v) =>
    typeof v === "string" ? v : JSON.stringify(v, null, 1),
  );
}

/** Goes to [url] in the tab and waits for it to load (at most 30 s). */
export async function navigate(tabId: number, url: string) {
  const r = await send<{ errorText?: string }>(tabId, "Page.navigate", { url });
  if (r.errorText && r.errorText !== "net::ERR_ABORTED")
    throw new ActError("load_failed", `The page didn't load (${r.errorText}).`);
  await settle(tabId, 300, 120);
}

/** Waits until the page settles after a step (load and a short quiet spell). */
export async function settle(tabId: number, ms = 400, tries = 20) {
  await new Promise((r) => setTimeout(r, ms));
  for (let i = 0; i < tries; i++) {
    const t = await chrome.tabs.get(tabId).catch(() => null);
    if (!t || t.status === "complete") return;
    await new Promise((r) => setTimeout(r, 250));
  }
}
