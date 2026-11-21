/**
 * Reading the DOM: the flattened tree (open shadow roots and slots), what's hidden (the rules of
 * `hiddenNodes` in apps/extension/src/lib/act/snapshot.ts), roles and names (a small version of
 * the browser's accessibility rules), and the facts the server's risk rules need.
 *
 * Page content is untrusted: nothing here evaluates it, and text that isn't visible never makes it
 * into a name.
 */
import {
  assignedNodes,
  clean,
  closest,
  collectionItem,
  css,
  DOC,
  docActiveElement,
  docCreateRange,
  docGetElementById,
  firstChild,
  formOf,
  formQuerySelector,
  fragGetElementById,
  getAttribute,
  getRect,
  getRootNode,
  hasAttribute,
  hash,
  includes,
  inputChecked,
  inputIndeterminate,
  inputReadOnly,
  inputValue,
  isContentEditable,
  join,
  LOCATION,
  labelsOf,
  list,
  localName,
  locHost,
  locHref,
  matches,
  nextSibling,
  nodeListItem,
  nodeListLength,
  nodeType,
  nodeValue,
  optionSelected,
  optionText,
  parentNode,
  parseNum,
  push,
  rangeRect,
  rangeSelectNodeContents,
  rectHeight,
  rectLeft,
  rectTop,
  rectWidth,
  rootActiveElement,
  scrollX,
  scrollY,
  selectMultiple,
  selectOptions,
  selectSelectedIndex,
  selectSize,
  shadowHost,
  shadowRoot,
  startsWith,
  strLower,
  strSlice,
  strTrim,
  style,
  textareaReadOnly,
  textareaValue,
  WeakMapCtor,
  WIN,
  weakMapGet,
  weakMapSet,
  words,
} from "./prims.ts";

export const ELEMENT = 1;
export const TEXT = 3;

/** Elements whose content is never shown or read. */
const SKIP_TAGS: Record<string, true> = {
  script: true,
  style: true,
  template: true,
  head: true,
  noscript: true,
  meta: true,
  link: true,
  title: true,
};

export function isSkipped(el: Element): boolean {
  return SKIP_TAGS[localName(el)] === true;
}

/** Children in the flattened tree: a shadow host's shadow root, a slot's assigned nodes. */
export function kids(n: Node): Node[] {
  const out = list<Node>();
  if (nodeType(n) === ELEMENT) {
    const el = n as Element;
    const root = shadowRoot(el);
    if (root) {
      for (let c = firstChild(root); c; c = nextSibling(c)) push(out, c);
      return out;
    }
    if (localName(el) === "slot") {
      const got = assignedNodes(el as HTMLSlotElement, { flatten: true });
      if (got?.length) {
        for (let i = 0; i < got.length; i++) push(out, got[i] as Node);
        return out;
      }
    }
  }
  for (let c = firstChild(n); c; c = nextSibling(c)) push(out, c);
  return out;
}

/** The parent in the flattened tree: a shadow root's host stands in for the root. */
function flatParent(n: Node): Node | null {
  const p = parentNode(n);
  if (p && nodeType(p) === 11) {
    try {
      return shadowHost(p);
    } catch {
      return null;
    }
  }
  return p;
}

const CLIPS = (v: string) => v === "hidden" || v === "clip";

/** Whether [el] itself hides what's inside it (its parent is visible). */
export function selfHidden(el: Element): boolean {
  if (hasAttribute(el, "hidden") || hasAttribute(el, "inert")) return true;
  if (getAttribute(el, "aria-hidden") === "true") return true;
  const s = style(el);
  const display = css(s, "display");
  if (display === "none") return true;
  const visibility = css(s, "visibility");
  if (visibility === "hidden" || visibility === "collapse") return true;
  const opacity = css(s, "opacity");
  if (opacity !== "" && parseNum(opacity) < 0.05) return true;
  if (zeroRect(css(s, "clip"))) return true;
  const clipPath = css(s, "clip-path");
  if (
    startsWith(clipPath, "inset(50%") ||
    startsWith(clipPath, "inset(100%") ||
    startsWith(clipPath, "circle(0")
  )
    return true;
  if (display === "contents") return false;
  const r = getRect(el);
  const w = rectWidth(r);
  const h = rectHeight(r);
  if ((CLIPS(css(s, "overflow-x")) || CLIPS(css(s, "overflow-y"))) && (w <= 1 || h <= 1))
    return true;
  // Pushed off the page to the left or above (left: -9999px).
  const x = rectLeft(r) + scrollX(WIN);
  const y = rectTop(r) + scrollY(WIN);
  if (x + w < 0 || y + h < 0) return true;
  return false;
}

/** `rect(0px, 0px, 0px, 0px)` in any spacing. */
function zeroRect(clip: string): boolean {
  if (!startsWith(clip, "rect(")) return false;
  let t = "";
  for (let i = 5; i < clip.length; i++) {
    const c = clip[i];
    if (c === " " || c === "," || c === "p" || c === "x" || c === ")") continue;
    t += c;
  }
  return t === "0000";
}

/** Whether a text node (in a visible parent) is too small to see. */
export function textHidden(t: Text, parent: Element | null): boolean {
  if (parent) {
    const fs = parseNum(css(style(parent), "font-size") || "16");
    if (fs < 2) return true;
  }
  const r = docCreateRange(DOC);
  rangeSelectNodeContents(r, t);
  const box = rangeRect(r);
  return rectWidth(box) < 1 || rectHeight(box) < 1;
}

let hiddenMemo = new WeakMapCtor<Node, boolean>();
/** Forget cached visibility (each command starts fresh). */
export function resetMemo(): void {
  hiddenMemo = new WeakMapCtor<Node, boolean>();
}
/** Whether [el] or anything above it (in the flattened tree) hides it. */
export function hiddenUp(el: Element): boolean {
  const got = weakMapGet<boolean | undefined>(hiddenMemo, el);
  if (got !== undefined) return got;
  let h = false;
  const p = flatParent(el);
  if (p && nodeType(p) === ELEMENT) h = hiddenUp(p as Element);
  if (!h) h = selfHidden(el);
  weakMapSet(hiddenMemo, el, h);
  return h;
}

/** Elements a bot can act on; each gets a ref. */
export const INTERACTIVE: Record<string, true> = {
  button: true,
  link: true,
  textbox: true,
  searchbox: true,
  combobox: true,
  checkbox: true,
  radio: true,
  switch: true,
  slider: true,
  spinbutton: true,
  menuitem: true,
  menuitemcheckbox: true,
  menuitemradio: true,
  option: true,
  tab: true,
  treeitem: true,
  listbox: true,
};

/** Shown in a full snapshot besides interactive elements. */
export const CONTENT: Record<string, true> = {
  heading: true,
  img: true,
  image: true,
  cell: true,
  columnheader: true,
  rowheader: true,
  alert: true,
  status: true,
};

/** Roles that take their name from what's inside them. */
const NAME_FROM_CONTENT: Record<string, true> = {
  button: true,
  link: true,
  checkbox: true,
  radio: true,
  switch: true,
  tab: true,
  menuitem: true,
  menuitemcheckbox: true,
  menuitemradio: true,
  option: true,
  treeitem: true,
  heading: true,
  cell: true,
  columnheader: true,
  rowheader: true,
  alert: true,
  status: true,
  tooltip: true,
};

const TEXT_INPUTS: Record<string, true> = {
  "": true,
  text: true,
  email: true,
  tel: true,
  url: true,
  password: true,
  date: true,
  "datetime-local": true,
  month: true,
  time: true,
  week: true,
};
const NOT_EDITABLE_INPUTS: Record<string, true> = {
  checkbox: true,
  radio: true,
  submit: true,
  button: true,
  reset: true,
  image: true,
  file: true,
  hidden: true,
  range: true,
  color: true,
};

export function inputType(el: Element): string {
  return strLower(getAttribute(el, "type") ?? "");
}

function focusable(el: Element): boolean {
  return matches(el, "a[href],button,input,select,textarea,[tabindex],[contenteditable]");
}

/** The element's role: explicit `role` first, else its implicit one. */
export function roleOf(el: Element): string {
  const explicit = words(strLower(getAttribute(el, "role") ?? ""));
  if (explicit.length) {
    const r = explicit[0] as string;
    if (!((r === "none" || r === "presentation") && focusable(el))) return r;
  }
  const tag = localName(el);
  switch (tag) {
    case "a":
    case "area":
      return hasAttribute(el, "href") ? "link" : "";
    case "button":
      return "button";
    case "input": {
      const t = inputType(el);
      if (t === "button" || t === "submit" || t === "reset" || t === "image" || t === "file")
        return "button";
      if (t === "checkbox") return "checkbox";
      if (t === "radio") return "radio";
      if (t === "range") return "slider";
      if (t === "number") return "spinbutton";
      if (t === "hidden" || t === "color") return "";
      if (t === "search") return hasAttribute(el, "list") ? "combobox" : "searchbox";
      return hasAttribute(el, "list") ? "combobox" : "textbox";
    }
    case "textarea":
      return "textbox";
    case "select":
      return selectMultiple(el) || selectSize(el) > 1 ? "listbox" : "combobox";
    case "option":
      return "option";
    case "summary":
      return "button";
    case "h1":
    case "h2":
    case "h3":
    case "h4":
    case "h5":
    case "h6":
      return "heading";
    case "img":
      return getAttribute(el, "alt") === "" ? "presentation" : "img";
    case "td":
      return "cell";
    case "th":
      return getAttribute(el, "scope") === "row" ? "rowheader" : "columnheader";
    case "output":
      return "status";
    case "p":
      return "paragraph";
    case "li":
      return "listitem";
    case "tr":
      return "row";
    case "blockquote":
      return "blockquote";
    case "article":
      return "article";
    case "section":
      return "section";
    case "main":
      return "main";
  }
  if (isContentEditable(el)) {
    const p = parentNode(el);
    if (!p || nodeType(p) !== ELEMENT || !isContentEditable(p as Element)) return "textbox";
  }
  return "";
}

/** Text a person can see inside [n], with images' alt text; form controls are skipped. */
export function visibleText(n: Node, max = 400): string {
  const out = list<string>();
  let size = 0;
  const walk = (node: Node, depth: number) => {
    if (size > max || depth > 60) return;
    const cs = kids(node);
    for (let i = 0; i < cs.length; i++) {
      const c = cs[i] as Node;
      const t = nodeType(c);
      if (t === TEXT) {
        const v = nodeValue(c) ?? "";
        if (!strTrim(v)) continue;
        if (textHidden(c as Text, node as Element)) continue;
        push(out, v);
        size += v.length;
      } else if (t === ELEMENT) {
        const el = c as Element;
        if (isSkipped(el) || selfHidden(el)) continue;
        const tag = localName(el);
        if (tag === "input" || tag === "select" || tag === "textarea" || tag === "iframe") continue;
        if (tag === "img") {
          const alt = getAttribute(el, "alt");
          if (alt) push(out, ` ${alt} `);
          continue;
        }
        const block = isBlock(el);
        if (block) push(out, " ");
        walk(el, depth + 1);
        if (block) push(out, " ");
      }
    }
  };
  walk(n, 0);
  return clean(join(out, ""), max);
}

export function isBlock(el: Element): boolean {
  const d = css(style(el), "display");
  return !(d === "inline" || d === "contents" || d === "" || startsWith(d, "inline"));
}

function byId(el: Element, id: string): Element | null {
  const root = getRootNode(el);
  if (root && nodeType(root) === 11) return fragGetElementById(root as ShadowRoot, id);
  return docGetElementById(DOC, id);
}

/** The element's accessible name, from visible text and labelling attributes. */
export function nameOf(el: Element, role: string): string {
  const ids = words(getAttribute(el, "aria-labelledby"));
  if (ids.length) {
    const parts = list<string>();
    for (let i = 0; i < ids.length; i++) {
      const target = byId(el, ids[i] as string);
      if (target && !hiddenUp(target)) push(parts, visibleText(target));
    }
    const t = clean(join(parts, " "));
    if (t) return t;
  }
  const label = clean(getAttribute(el, "aria-label"));
  if (label) return label;
  const labels = labelsOf(el);
  if (labels) {
    const parts = list<string>();
    const n = nodeListLength(labels);
    for (let i = 0; i < n; i++) {
      const l = nodeListItem(labels, i) as Element | null;
      if (l && !hiddenUp(l)) push(parts, visibleText(l));
    }
    const t = clean(join(parts, " "));
    if (t) return t;
  }
  const tag = localName(el);
  if (tag === "img" || tag === "area" || (tag === "input" && inputType(el) === "image")) {
    const alt = clean(getAttribute(el, "alt"));
    if (alt) return alt;
  }
  if (tag === "input") {
    const t = inputType(el);
    if (t === "submit" || t === "button" || t === "reset") {
      const v = clean(getAttribute(el, "value"));
      if (v) return v;
      if (t === "submit") return "Submit";
      if (t === "reset") return "Reset";
    }
  }
  if (NAME_FROM_CONTENT[role] === true) {
    const t = visibleText(el, 150);
    if (t) return t;
  }
  const title = clean(getAttribute(el, "title"));
  if (title) return title;
  const ph = clean(getAttribute(el, "placeholder") ?? getAttribute(el, "aria-placeholder"));
  if (ph) return ph;
  return "";
}

/**
 * Fields whose contents belong to the person: passwords, cards and one-time codes. Their values
 * are never read, and `fill` and `type` refuse them.
 */
export function isSensitive(el: Element): boolean {
  if (localName(el) === "input" && inputType(el) === "password") return true;
  const tokens = words(strLower(getAttribute(el, "autocomplete") ?? ""));
  for (let i = 0; i < tokens.length; i++) {
    const t = tokens[i] as string;
    if (t === "one-time-code" || t === "current-password" || t === "new-password") return true;
    if (startsWith(t, "cc-")) return true;
  }
  return false;
}

/** A text field or an editable area. */
export function isEditable(el: Element): boolean {
  const tag = localName(el);
  if (tag === "textarea") return true;
  if (tag === "input") return NOT_EDITABLE_INPUTS[inputType(el)] !== true;
  return isContentEditable(el);
}

export function isTextInput(el: Element): boolean {
  return localName(el) === "input" && TEXT_INPUTS[inputType(el)] === true;
}

export function isReadOnly(el: Element): boolean {
  const tag = localName(el);
  if (tag === "input") return inputReadOnly(el);
  if (tag === "textarea") return textareaReadOnly(el);
  return false;
}

export function isDisabled(el: Element): boolean {
  if (getAttribute(el, "aria-disabled") === "true") return true;
  const tag = localName(el);
  if (
    tag === "input" ||
    tag === "button" ||
    tag === "select" ||
    tag === "textarea" ||
    tag === "option" ||
    tag === "fieldset"
  )
    return matches(el, ":disabled");
  return false;
}

/** What a field shows, for the snapshot. Never read for sensitive fields. */
export function shownValue(el: Element, role: string): string {
  if (isSensitive(el)) return "";
  const tag = localName(el);
  if (tag === "select") {
    const i = selectSelectedIndex(el);
    if (i < 0) return "";
    const o = collectionItem(selectOptions(el) as unknown as HTMLCollection, i);
    return o ? optionText(o) : "";
  }
  if (tag === "input" || tag === "textarea") return readValue(el);
  if (role === "textbox" && isContentEditable(el)) return visibleText(el, 200);
  const vt = getAttribute(el, "aria-valuetext") ?? getAttribute(el, "aria-valuenow");
  return vt ?? "";
}

/** The value of an input or textarea. The only place values are read; callers check isSensitive. */
export function readValue(el: Element): string {
  if (isSensitive(el)) return "";
  return localName(el) === "textarea" ? textareaValue(el) : inputValue(el);
}

/** The flags agent-browser prints after an element. */
export function flagsOf(el: Element, role: string, focused: Element | null): string {
  const out = list<string>();
  const tag = localName(el);
  let checked: string | null = null;
  if (tag === "input" && (role === "checkbox" || role === "radio")) {
    if (inputIndeterminate(el)) checked = "mixed";
    else if (inputChecked(el)) checked = "true";
  } else checked = getAttribute(el, "aria-checked");
  if (checked === "true") push(out, "[checked]");
  if (checked === "mixed") push(out, "[mixed]");
  if (isDisabled(el)) push(out, "[disabled]");
  let expanded = getAttribute(el, "aria-expanded");
  if (expanded === null && tag === "summary") {
    const details = parentNode(el) as Element | null;
    if (details && nodeType(details) === ELEMENT && localName(details) === "details")
      expanded = hasAttribute(details, "open") ? "true" : "false";
  }
  if (expanded === "true") push(out, "[expanded]");
  if (expanded === "false") push(out, "[collapsed]");
  const selected =
    tag === "option" ? optionSelected(el) : getAttribute(el, "aria-selected") === "true";
  if (selected) push(out, "[selected]");
  if (focused && focused === el) push(out, "[focused]");
  if (role === "heading") {
    const lvl = headingLevel(el);
    if (lvl) push(out, `[level=${lvl}]`);
  }
  return out.length ? ` ${join(out, " ")}` : "";
}

export function headingLevel(el: Element): number {
  const aria = parseNum(getAttribute(el, "aria-level") ?? "");
  if (aria >= 1) return aria - (aria % 1);
  const tag = localName(el);
  if (tag.length === 2 && tag[0] === "h") {
    const n = parseNum(strSlice(tag, 1));
    if (n >= 1 && n <= 6) return n;
  }
  return 2;
}

/** The focused element, looking inside open shadow roots. Frames are the caller's business. */
export function focusedHere(): { el: Element | null; closedShadow: boolean } {
  let el = docActiveElement(DOC);
  for (let i = 0; i < 30 && el; i++) {
    const root = shadowRoot(el);
    if (!root) break;
    const inner = rootActiveElement(root);
    if (!inner) break;
    el = inner;
  }
  if (!el) return { el: null, closedShadow: false };
  const tag = localName(el);
  if (tag === "body" || tag === "html") return { el: null, closedShadow: false };
  // A custom element that isn't focusable itself but holds focus: it's inside a closed shadow root.
  const closedShadow =
    includes(tag, "-") &&
    !shadowRoot(el) &&
    !hasAttribute(el, "tabindex") &&
    !isContentEditable(el);
  return { el, closedShadow };
}

export interface Facts {
  role: string;
  name: string;
  url: string;
  tag: string;
  inputType: string;
  autocomplete: string;
  submits: boolean;
  passwordForm: boolean;
  inForm: boolean;
  submitName: string;
  editable: boolean;
  isFile: boolean;
  host: string;
}

const SUBMIT_SEL =
  'button:not([type="button"]):not([type="reset"]), input[type="submit"], input[type="image"]';

/** What packages/domain/src/browser-risk.ts needs to know about an element. Nothing from values. */
export function factsOf(el: Element): Facts {
  const tag = localName(el);
  const type = tag === "input" || tag === "button" ? inputType(el) : "";
  const form = formOf(el);
  const submits =
    !!form &&
    ((tag === "button" && type !== "button" && type !== "reset") ||
      (tag === "input" && (type === "submit" || type === "image")));
  const passwordForm = !!form && !!formQuerySelector(form, 'input[type="password"]');
  const btn = form ? formQuerySelector(form, SUBMIT_SEL) : null;
  const role = roleOf(el);
  return {
    role,
    name: nameOf(el, role),
    url: locHref(LOCATION),
    tag,
    inputType: type,
    autocomplete: strLower(getAttribute(el, "autocomplete") ?? ""),
    submits,
    passwordForm,
    inForm: !!form,
    submitName: btn ? clean(nameOf(btn, roleOf(btn)), 100) : "",
    editable: isEditable(el),
    isFile: tag === "input" && type === "file",
    host: locHost(LOCATION),
  };
}

export function fingerprintOf(f: Facts): string {
  return hash(
    `${f.role}|${f.name}|${f.tag}|${f.inputType}|${f.autocomplete}|${f.submits}|${f.passwordForm}|${f.host}`,
  );
}

/** The label element [hit] sits in, when it labels [el]. */
export function labelFor(hit: Element, el: Element): boolean {
  const l = closest(hit, "label");
  if (!l) return false;
  const labels = labelsOf(el);
  if (!labels) return false;
  const n = nodeListLength(labels);
  for (let i = 0; i < n; i++) if (nodeListItem(labels, i) === l) return true;
  return false;
}
