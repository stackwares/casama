/**
 * Steps on one element of this frame: the covered check, clicks, filling and typing through the
 * browser's own editing path, keys, scrolling, upload fields and downloads.
 */
import {
  ELEMENT,
  focusedHere,
  hiddenUp,
  inputType,
  isDisabled,
  isEditable,
  isReadOnly,
  isSensitive,
  labelFor,
  readValue,
  roleOf,
  visibleText,
} from "./dom.ts";
import {
  atobFn,
  btoaFn,
  clean,
  clientHeight,
  clientWidth,
  closest,
  collectionItem,
  collectionLength,
  css,
  DataTransferCtor,
  DOC,
  dataTransferFiles,
  dataTransferItems,
  defineProp,
  dispatch,
  docBody,
  docCreateRange,
  docElementFromPoint,
  docExecCommand,
  docQuerySelectorAll,
  EventCtor,
  elScrollBy,
  FileCtor,
  fetchFn,
  focusEl,
  formOf,
  formQuerySelector,
  formRequestSubmit,
  fromCharCode,
  getRect,
  getRootNode,
  headersGet,
  InputEventCtor,
  includes,
  innerHeight,
  innerWidth,
  inputSelect,
  isContentEditable,
  itemsAdd,
  KeyboardEventCtor,
  LOCATION,
  list,
  localName,
  locHref,
  MouseEventCtor,
  matches,
  mathMax,
  mathMin,
  nodeContains,
  nodeListItem,
  nodeListLength,
  nodeType,
  num,
  optionText,
  optionValue,
  PointerEventCtor,
  parentNode,
  push,
  rangeSelectNodeContents,
  readerCancel,
  readerRead,
  rectHeight,
  rectLeft,
  rectTop,
  rectWidth,
  responseBody,
  responseHeaders,
  responseOk,
  responseStatus,
  responseUrl,
  rootElementFromPoint,
  scrollHeight,
  scrollIntoView,
  scrollIntoViewIfNeeded,
  scrollLeft,
  scrollTop,
  scrollWidth,
  scrollX,
  scrollY,
  selAddRange,
  selectOptions,
  selRemoveAllRanges,
  setInputFiles,
  setInputValue,
  setSelectSelectedIndex,
  setTextareaValue,
  setTextContent,
  shadowHost,
  startsWith,
  strCode,
  streamGetReader,
  strIndexOf,
  strLower,
  strSlice,
  strTrim,
  style,
  textareaSelect,
  Uint8,
  URLCtor,
  u8Set,
  u8Subarray,
  urlHref,
  urlPathname,
  urlProtocol,
  WIN,
  winGetSelection,
  winScrollBy,
} from "./prims.ts";

/** Marks the agent's own errors (checked by identity, not instanceof, which a page can hook). */
export const FAIL = {};
export class Fail {
  code: string;
  message: string;
  brand = FAIL;
  constructor(code: string, message: string) {
    this.code = code;
    this.message = message;
  }
}
export function isFail(e: unknown): e is Fail {
  return typeof e === "object" && e !== null && (e as Fail).brand === FAIL;
}

const reflectApply = Reflect.apply;
const decodeUri = decodeURIComponent;

/** Brings [el] into view if it isn't. */
export function reveal(el: Element): void {
  const r = getRect(el);
  const inView =
    rectTop(r) >= 0 &&
    rectLeft(r) >= 0 &&
    rectTop(r) + rectHeight(r) <= innerHeight(WIN) &&
    rectLeft(r) + rectWidth(r) <= innerWidth(WIN);
  if (inView) return;
  if (scrollIntoViewIfNeeded) scrollIntoViewIfNeeded(el, true);
  else scrollIntoView(el, { block: "center", inline: "center" });
}

/** The centre of the part of [el] inside the viewport. */
export function centerOf(el: Element): { x: number; y: number } {
  const r = getRect(el);
  if (rectWidth(r) < 1 || rectHeight(r) < 1)
    throw new Fail("covered", "That element isn't visible on the page. Take a new snapshot.");
  const left = mathMax(rectLeft(r), 0);
  const top = mathMax(rectTop(r), 0);
  const right = mathMin(rectLeft(r) + rectWidth(r), innerWidth(WIN));
  const bottom = mathMin(rectTop(r) + rectHeight(r), innerHeight(WIN));
  if (right - left < 1 || bottom - top < 1)
    throw new Fail("covered", "That element is off the screen and couldn't be scrolled to.");
  return { x: (left + right) / 2, y: (top + bottom) / 2 };
}

function isShadowRoot(n: Node): boolean {
  return nodeType(n) === 11;
}

/** What's at (x, y), as seen from [el]'s own tree (document or shadow root). */
function hitAt(el: Element, x: number, y: number): Element | null {
  const root = getRootNode(el);
  if (isShadowRoot(root)) return rootElementFromPoint(root as ShadowRoot, x, y);
  return docElementFromPoint(DOC, x, y);
}

/** Whether [el] is what's under (x, y): nothing covers it. Returns the element hit when it is. */
export function onTop(el: Element, x: number, y: number): Element | null {
  const hit = hitAt(el, x, y);
  if (!hit) return null;
  if (hit === el || nodeContains(el, hit)) return hit;
  // The hit sits in a shadow tree inside [el]: step out through its hosts.
  let h: Node | null = hit;
  for (let i = 0; h && i < 30; i++) {
    const root = getRootNode(h);
    if (!isShadowRoot(root)) break;
    h = shadowHost(root);
    if (h === el || (h && nodeContains(el, h))) return hit;
  }
  // A label for this field counts as this field.
  return labelFor(hit, el) ? hit : null;
}

/** Scrolls [el] into view and checks nothing covers its centre. */
export function locate(el: Element): { x: number; y: number; hit: Element } {
  reveal(el);
  const { x, y } = centerOf(el);
  const hit = onTop(el, x, y);
  if (!hit)
    throw new Fail(
      "covered",
      "Something else on the page covers that element, so it wasn't touched. Take a new snapshot.",
    );
  return { x, y, hit };
}

const FOCUSABLE =
  'a[href],area[href],button,input:not([type="hidden"]),select,textarea,summary,iframe,[tabindex],[contenteditable]:not([contenteditable="false"])';

function mouseInit(x: number, y: number, buttons: number, detail: number) {
  return {
    bubbles: true,
    cancelable: true,
    composed: true,
    view: WIN,
    clientX: x,
    clientY: y,
    screenX: x,
    screenY: y,
    button: 0,
    buttons,
    detail,
  };
}

function pointer(type: string, target: Element, x: number, y: number, buttons: number): boolean {
  const ev = new PointerEventCtor(type, {
    ...mouseInit(x, y, buttons, 0),
    pointerId: 1,
    pointerType: "mouse",
    isPrimary: true,
    width: 1,
    height: 1,
    pressure: buttons ? 0.5 : 0,
  } as PointerEventInit);
  return dispatch(target, ev);
}

function mouse(type: string, target: Element, x: number, y: number, buttons: number): boolean {
  return dispatch(
    target,
    new MouseEventCtor(type, mouseInit(x, y, buttons, type === "click" ? 1 : 0)),
  );
}

/** The events of a mouse click at (x, y) on [target], with focus moving like a real click. */
export function clickAt(target: Element, x: number, y: number): void {
  pointer("pointerover", target, x, y, 0);
  mouse("mouseover", target, x, y, 0);
  const downOk = pointer("pointerdown", target, x, y, 1);
  const mouseOk = downOk ? mouse("mousedown", target, x, y, 1) : true;
  if (downOk && mouseOk) {
    const f = closest(target, FOCUSABLE);
    if (f) focusEl(f, { preventScroll: true });
  }
  pointer("pointerup", target, x, y, 0);
  if (downOk) mouse("mouseup", target, x, y, 0);
  mouse("click", target, x, y, 0);
}

function selectAll(el: Element): void {
  const tag = localName(el);
  if (tag === "input") inputSelect(el);
  else if (tag === "textarea") textareaSelect(el);
  else {
    const sel = winGetSelection(WIN);
    if (!sel) return;
    const r = docCreateRange(DOC);
    rangeSelectNodeContents(r, el);
    selRemoveAllRanges(sel);
    selAddRange(sel, r);
  }
}

function fire(el: Element, type: string, data?: string): void {
  if (type === "input")
    dispatch(
      el,
      new InputEventCtor("input", {
        bubbles: true,
        composed: true,
        inputType: data ? "insertText" : "deleteContentBackward",
        data: data ?? null,
      } as InputEventInit),
    );
  else dispatch(el, new EventCtor(type, { bubbles: true }));
}

/** The element's text or value, for checking an edit took. Never called on sensitive fields. */
function contentOf(el: Element): string {
  const tag = localName(el);
  if (tag === "input" || tag === "textarea") return readValue(el);
  return visibleText(el, 100_000);
}

function setNativeValue(el: Element, v: string): void {
  if (localName(el) === "textarea") setTextareaValue(el, v);
  else setInputValue(el, v);
}

function exec(cmd: string, value?: string): boolean {
  try {
    return docExecCommand(DOC, cmd, false, value);
  } catch {
    return false;
  }
}

/** Refuses fields a bot never types into. */
export function guardField(el: Element): void {
  if (isSensitive(el))
    throw new Fail(
      "unsupported",
      "That's a password, card or code field: it's typed by the person, not by a bot.",
    );
}

function pickOption(el: Element, text: string): string {
  const opts = selectOptions(el) as unknown as HTMLCollection;
  const n = collectionLength(opts);
  const want = strLower(strTrim(text));
  for (let pass = 0; pass < 2; pass++)
    for (let i = 0; i < n; i++) {
      const o = collectionItem(opts, i);
      if (!o) continue;
      const label = strLower(clean(optionText(o)));
      const value = strLower(optionValue(o));
      if (pass === 0 ? label === want || value === want : includes(label, want)) {
        setSelectSelectedIndex(el, i);
        fire(el, "input");
        fire(el, "change");
        return clean(optionText(o));
      }
    }
  throw new Fail("not_editable", `That list has no option "${clean(text, 80)}".`);
}

/** Replaces what's in a field with [text] (an empty string clears it). */
export function fill(el: Element, text: string): string {
  const tag = localName(el);
  if (tag === "select") {
    if (isDisabled(el)) throw new Fail("not_editable", "That list is turned off.");
    return `Picked "${pickOption(el, text)}".`;
  }
  if (!isEditable(el))
    throw new Fail(
      "not_editable",
      "That element isn't a text field. Use click for buttons and boxes.",
    );
  guardField(el);
  if (isDisabled(el) || isReadOnly(el))
    throw new Fail("not_editable", "That field is read-only or turned off.");
  reveal(el);
  focusEl(el, { preventScroll: true });
  selectAll(el);
  const before = contentOf(el);
  const ok = text ? exec("insertText", text) : exec("delete");
  const after = contentOf(el);
  const took = text ? ok && after !== before : after === "";
  if (!took) {
    if (tag === "input" || tag === "textarea") {
      setNativeValue(el, text);
      fire(el, "input", text);
    } else {
      setTextContent(el, text);
      fire(el, "input", text);
    }
  }
  if (tag === "input" || tag === "textarea") fire(el, "change");
  const now = contentOf(el);
  return now === text || tag !== "input" ? "" : ` It now shows "${clean(now, 80)}".`;
}

/** Inserts [text] where the caret is in the focused field. */
export function typeInto(el: Element, text: string): void {
  if (!isEditable(el))
    throw new Fail(
      "not_editable",
      "Nothing that takes text has focus. Click or fill a field first.",
    );
  guardField(el);
  if (isDisabled(el) || isReadOnly(el))
    throw new Fail("not_editable", "That field is read-only or turned off.");
  if (exec("insertText", text)) return;
  const tag = localName(el);
  if (tag !== "input" && tag !== "textarea")
    throw new Fail("unsupported", "The page didn't take the typed text.");
  setNativeValue(el, readValue(el) + text);
  fire(el, "input", text);
}

const KEYS: Record<string, { code: string; keyCode: number }> = {
  Enter: { code: "Enter", keyCode: 13 },
  Tab: { code: "Tab", keyCode: 9 },
  Escape: { code: "Escape", keyCode: 27 },
  Backspace: { code: "Backspace", keyCode: 8 },
  Delete: { code: "Delete", keyCode: 46 },
  " ": { code: "Space", keyCode: 32 },
  ArrowUp: { code: "ArrowUp", keyCode: 38 },
  ArrowDown: { code: "ArrowDown", keyCode: 40 },
  ArrowLeft: { code: "ArrowLeft", keyCode: 37 },
  ArrowRight: { code: "ArrowRight", keyCode: 39 },
  PageUp: { code: "PageUp", keyCode: 33 },
  PageDown: { code: "PageDown", keyCode: 34 },
  Home: { code: "Home", keyCode: 36 },
  End: { code: "End", keyCode: 35 },
};

interface Combo {
  key: string;
  code: string;
  keyCode: number;
  ctrl: boolean;
  alt: boolean;
  shift: boolean;
  meta: boolean;
}

export function parseCombo(combo: string): Combo {
  const parts = list<string>();
  let cur = "";
  for (let i = 0; i < combo.length; i++) {
    if (combo[i] === "+" && cur) {
      push(parts, cur);
      cur = "";
    } else cur += combo[i];
  }
  push(parts, cur);
  let key = (parts[parts.length - 1] as string) || combo;
  const c: Combo = {
    key,
    code: "",
    keyCode: 0,
    ctrl: false,
    alt: false,
    shift: false,
    meta: false,
  };
  for (let i = 0; i < parts.length - 1; i++) {
    const m = strLower(parts[i] as string);
    if (m === "control" || m === "ctrl") c.ctrl = true;
    else if (m === "alt" || m === "option") c.alt = true;
    else if (m === "shift") c.shift = true;
    else if (m === "meta" || m === "cmd" || m === "command") c.meta = true;
  }
  if (key === "Space" || key === "Spacebar") key = " ";
  if (key === "Esc") key = "Escape";
  if (key === "Return") key = "Enter";
  c.key = key;
  const known = KEYS[key];
  if (known) {
    c.code = known.code;
    c.keyCode = known.keyCode;
  } else if (key.length === 1) {
    const up = key >= "a" && key <= "z" ? fromCharCode(strCode(key, 0) - 32) : key;
    c.code = up >= "A" && up <= "Z" ? `Key${up}` : up >= "0" && up <= "9" ? `Digit${up}` : "";
    c.keyCode = strCode(up, 0);
  } else c.code = key;
  return c;
}

function keyEvent(type: string, target: EventTarget, c: Combo): boolean {
  const printable = c.key.length === 1;
  const ev = new KeyboardEventCtor(type, {
    key: c.key,
    code: c.code,
    bubbles: true,
    cancelable: true,
    composed: true,
    view: WIN,
    ctrlKey: c.ctrl,
    altKey: c.alt,
    shiftKey: c.shift,
    metaKey: c.meta,
  });
  const kc = type === "keypress" ? (printable ? strCode(c.key, 0) : c.keyCode) : c.keyCode;
  try {
    defineProp(ev, "keyCode", { get: () => kc });
    defineProp(ev, "which", { get: () => kc });
    if (type === "keypress") defineProp(ev, "charCode", { get: () => kc });
  } catch {}
  return dispatch(target, ev);
}

function tabOrder(): Element[] {
  const all = docQuerySelectorAll(DOC, FOCUSABLE);
  const out = list<Element>();
  const n = nodeListLength(all);
  for (let i = 0; i < n; i++) {
    const el = nodeListItem(all, i) as Element;
    if (matches(el, '[tabindex="-1"]') || isDisabled(el) || hiddenUp(el)) continue;
    push(out, el);
  }
  return out;
}

function moveFocus(from: Element | null, back: boolean): void {
  const order = tabOrder();
  if (!order.length) return;
  let i = -1;
  for (let k = 0; k < order.length; k++) if (order[k] === from) i = k;
  const next = back
    ? order[i <= 0 ? order.length - 1 : i - 1]
    : order[i < 0 || i >= order.length - 1 ? 0 : i + 1];
  if (next) {
    reveal(next);
    focusEl(next, { preventScroll: true });
  }
}

const ACTIVATES: Record<string, true> = {
  button: true,
  link: true,
  checkbox: true,
  radio: true,
  switch: true,
  tab: true,
  menuitem: true,
  option: true,
};

/** Presses a key (or combination) on the focused element, with the browser's default action. */
export function press(el: Element | null, combo: string): void {
  const c = parseCombo(combo);
  const target: EventTarget = el ?? docBody(DOC) ?? DOC;
  const printable = c.key.length === 1 && !c.ctrl && !c.meta && !c.alt;
  const editable = !!el && isEditable(el);
  if (el && editable && printable && isSensitive(el)) guardField(el);
  const down = keyEvent("keydown", target, c);
  if (down && (printable || c.key === "Enter") && !c.ctrl && !c.meta)
    keyEvent("keypress", target, c);
  if (down && el) {
    const tag = localName(el);
    const role = roleOf(el);
    if (c.key === "Enter" && !c.ctrl && !c.meta && !c.alt) {
      if (tag === "textarea") exec("insertText", "\n");
      else if (editable && isContentEditable(el)) exec("insertParagraph");
      else if (tag === "input" && editable) submitForm(el);
      else if (ACTIVATES[role] === true && role !== "checkbox" && role !== "radio") activate(el);
    } else if (c.key === "Tab") moveFocus(el, c.shift);
    else if (c.key === " " && !editable && ACTIVATES[role] === true) activate(el);
    else if ((c.key === "Backspace" || c.key === "Delete") && editable)
      exec(c.key === "Backspace" ? "delete" : "forwardDelete");
    else if ((c.ctrl || c.meta) && strLower(c.key) === "a" && editable) exec("selectAll");
    else if (printable && editable && !isDisabled(el) && !isReadOnly(el)) exec("insertText", c.key);
  } else if (down && !el && c.key === "Tab") moveFocus(null, c.shift);
  keyEvent("keyup", target, c);
}

function activate(el: Element): void {
  dispatch(
    el,
    new MouseEventCtor("click", {
      bubbles: true,
      cancelable: true,
      composed: true,
      view: WIN,
      detail: 0,
    }),
  );
}

/** Enter in a form field: the form's implicit submission. */
function submitForm(el: Element): void {
  const form = formOf(el);
  if (!form) return;
  const btn = formQuerySelector(
    form,
    'button:not([type="button"]):not([type="reset"]), input[type="submit"], input[type="image"]',
  );
  if (btn && isDisabled(btn)) return;
  if (formRequestSubmit) formRequestSubmit(form, btn);
  else if (btn) activate(btn);
}

/** The element to scroll for a step: the scrollable box at the middle of the screen, else the page. */
function scroller(vertical: boolean): Element | null {
  let el: Node | null = docElementFromPoint(DOC, innerWidth(WIN) / 2, innerHeight(WIN) / 2);
  for (let i = 0; el && i < 100; i++) {
    if (nodeType(el) === ELEMENT) {
      const e = el as Element;
      const s = style(e);
      const o = css(s, vertical ? "overflow-y" : "overflow-x");
      const room = vertical ? scrollHeight(e) - clientHeight(e) : scrollWidth(e) - clientWidth(e);
      if ((o === "auto" || o === "scroll" || o === "overlay") && room > 1) return e;
    }
    const p: Node | null = parentNode(el);
    el = p && nodeType(p) === 11 ? shadowHost(p) : p;
  }
  return null;
}

export function scroll(direction: string, amount: number): string {
  const vertical = direction === "up" || direction === "down";
  const sign = direction === "up" || direction === "left" ? -1 : 1;
  const opts = vertical
    ? { top: sign * amount, left: 0, behavior: "instant" as ScrollBehavior }
    : { top: 0, left: sign * amount, behavior: "instant" as ScrollBehavior };
  const box = scroller(vertical);
  const pos = () =>
    box ? (vertical ? scrollTop(box) : scrollLeft(box)) : vertical ? scrollY(WIN) : scrollX(WIN);
  const before = pos();
  if (box) elScrollBy(box, opts);
  else winScrollBy(WIN, opts);
  const moved = pos() !== before;
  return moved ? `Scrolled ${direction}.` : `Scrolled ${direction}; already at the end.`;
}

/** Puts a file into an upload field. */
export function upload(el: Element, name: string, mediaType: string, data: string): void {
  if (localName(el) !== "input" || inputType(el) !== "file")
    throw new Fail("not_file_input", "That element isn't an upload field.");
  if (!DataTransferCtor || !FileCtor)
    throw new Fail("unsupported", "This browser can't put files into upload fields.");
  let bin: string;
  try {
    bin = atobFn(data);
  } catch {
    throw new Fail("error", "The file data isn't valid base64.");
  }
  const bytes = new Uint8(bin.length);
  for (let i = 0; i < bin.length; i++) bytes[i] = strCode(bin, i);
  const dt = new DataTransferCtor();
  itemsAdd(dataTransferItems(dt), new FileCtor([bytes], name, { type: mediaType }));
  setInputFiles(el, dataTransferFiles(dt));
  fire(el, "input");
  fire(el, "change");
}

export const DOWNLOAD_MAX = 20 * 1024 * 1024;

function filenameFrom(cd: string): string {
  const lower = strLower(cd);
  let i = strIndexOf(lower, "filename*=");
  let star = true;
  if (i < 0) {
    i = strIndexOf(lower, "filename=");
    star = false;
  }
  if (i < 0) return "";
  let v = strSlice(cd, i + (star ? 10 : 9));
  const semi = strIndexOf(v, ";");
  if (semi >= 0) v = strSlice(v, 0, semi);
  v = strTrim(v);
  if (star) {
    const q = strIndexOf(v, "''");
    if (q >= 0) v = strSlice(v, q + 2);
  }
  if (startsWith(v, '"')) v = strSlice(v, 1, v.length - (v[v.length - 1] === '"' ? 1 : 0));
  try {
    return decodeUri(v);
  } catch {
    return v;
  }
}

function base64(bytes: Uint8Array): string {
  let bin = "";
  for (let i = 0; i < bytes.length; i += 0x8000)
    bin += reflectApply(
      fromCharCode,
      null,
      u8Subarray(bytes, i, mathMin(i + 0x8000, bytes.length)) as unknown as number[],
    );
  return btoaFn(bin);
}

/** Fetches [url] with the page's own sign-in; refuses files over [max] bytes. */
export async function download(
  url: string,
  max: number,
): Promise<{ name: string; media_type: string; data: string }> {
  let u: URL;
  try {
    u = new URLCtor(url, locHref(LOCATION));
  } catch {
    throw new Fail("error", "That isn't a web address.");
  }
  const proto = urlProtocol(u);
  if (proto !== "https:" && proto !== "http:" && proto !== "blob:" && proto !== "data:")
    throw new Fail("unsupported", "Only web addresses can be downloaded.");
  let res: Response;
  try {
    res = await fetchFn(urlHref(u), { credentials: "include" });
  } catch {
    throw new Fail("error", "The download didn't start (the site refused it or is unreachable).");
  }
  if (!responseOk(res)) throw new Fail("error", `The site answered ${responseStatus(res)}.`);
  const headers = responseHeaders(res);
  const len = num(headersGet(headers, "content-length") || 0);
  const tooBig = () =>
    new Fail("too_large", `The file is over ${mathMax(1, (max / 1048576) | 0)} MB.`);
  if (len > max) throw tooBig();
  const body = responseBody(res);
  const chunks = list<Uint8Array>();
  let total = 0;
  if (body) {
    const reader = streamGetReader(body);
    for (;;) {
      const r = await readerRead(reader);
      if (r.done) break;
      const v = r.value as Uint8Array;
      total += v.length;
      if (total > max) {
        readerCancel(reader).catch(() => {});
        throw tooBig();
      }
      push(chunks, v);
    }
  }
  const bytes = new Uint8(total);
  let off = 0;
  for (let i = 0; i < chunks.length; i++) {
    const c = chunks[i] as Uint8Array;
    u8Set(bytes, c, off);
    off += c.length;
  }
  const finalUrl = responseUrl(res) || urlHref(u);
  let name = filenameFrom(headersGet(headers, "content-disposition") ?? "");
  if (!name) {
    try {
      const p = urlPathname(new URLCtor(finalUrl));
      let last = "";
      for (let i = p.length - 1; i >= 0 && p[i] !== "/"; i--) last = p[i] + last;
      name = decodeUri(last);
    } catch {}
  }
  const ct = headersGet(headers, "content-type") ?? "";
  const semi = strIndexOf(ct, ";");
  return {
    name: name || "download",
    media_type: strTrim(semi >= 0 ? strSlice(ct, 0, semi) : ct) || "application/octet-stream",
    data: base64(bytes),
  };
}

/** The focused element (in this frame) for type and press, or the reason it can't be used. */
export function focusedForTyping(): Element | null {
  const f = focusedHere();
  if (f.closedShadow)
    throw new Fail(
      "out_of_sight",
      "Focus is inside part of the page Casama can't see into. Ask the person to type it.",
    );
  return f.el;
}
