/**
 * Built-ins the page agent relies on, captured when the script starts. It runs at document start,
 * before any page script, so these are the browser's own. A page that later replaces
 * `String.prototype.trim`, `Element.prototype.getAttribute`, `JSON.stringify` or an array index
 * setter can't change what the agent reads or does.
 *
 * Rules for the rest of the source: no method calls on strings, arrays or DOM objects (use the
 * captured functions here), no regular expressions, no `for…of` or spread over arrays (iterators
 * can be replaced), and growing arrays come from `list()` (no prototype, so no inherited setters).
 * Object and array literals are fine: they define their properties without running setters.
 */

const FnProto = Function.prototype;
const O = Object;

type Uncurried<T, A extends unknown[], R> = (self: T, ...a: A) => R;
/** `f.call(self, ...a)` that keeps working after the page swaps `Function.prototype.call`. */
export const uncurry = FnProto.bind.bind(FnProto.call) as <T, A extends unknown[], R>(
  f: (this: T, ...a: A) => R,
) => Uncurried<T, A, R>;

export const getOwnDesc = O.getOwnPropertyDescriptor;
export const getProto = O.getPrototypeOf;
export const setProto = O.setPrototypeOf;
export const defineProp = O.defineProperty;
export const freeze = O.freeze;
export const create = O.create;
export const objectKeys = O.keys;

function lookup(o: object, k: string): PropertyDescriptor | undefined {
  let p: object | null = o;
  for (let i = 0; p && i < 20; i++) {
    const d = getOwnDesc(p, k);
    if (d) return d;
    p = getProto(p) as object | null;
  }
  return undefined;
}

/** A property getter of [o] (or its prototypes), callable on any instance. */
export function getter<R>(o: object | undefined, k: string): (self: unknown) => R {
  const g = o ? lookup(o, k)?.get : undefined;
  if (!g) return () => undefined as R;
  return uncurry(g as (this: unknown) => R);
}

/** A property setter of [o] (or its prototypes), callable on any instance. */
export function setter<V>(o: object | undefined, k: string): (self: unknown, v: V) => void {
  const s = o ? lookup(o, k)?.set : undefined;
  if (!s) return () => {};
  return uncurry(s as (this: unknown, v: V) => void);
}

/** A method of [o] (or its prototypes), callable on any instance; undefined when missing. */
// biome-ignore lint/suspicious/noExplicitAny: captured DOM methods take and return many shapes.
type AnyFn = (self: unknown, ...a: any[]) => any;
export function method(o: object | undefined, k: string): AnyFn | undefined {
  const d = o ? lookup(o, k) : undefined;
  const f = d?.value;
  return typeof f === "function" ? (uncurry(f) as AnyFn) : undefined;
}
function must(o: object | undefined, k: string): AnyFn {
  return method(o, k) ?? (() => undefined);
}

const W = globalThis as typeof globalThis & Window;
export const WIN = W;
export const DOC: Document = W.document;
export const TOP: Window | null = W.top;
export const PARENT: Window = W.parent;
export const IS_TOP = W.top === W;
const LOC = W.location;

// Language built-ins.
export const SP = String.prototype;
export const strSlice = must(SP, "slice") as (s: string, a: number, b?: number) => string;
export const strIndexOf = must(SP, "indexOf") as (s: string, t: string, from?: number) => number;
export const strLower = must(SP, "toLowerCase") as (s: string) => string;
export const strUpper = must(SP, "toUpperCase") as (s: string) => string;
export const strTrim = must(SP, "trim") as (s: string) => string;
export const strCode = must(SP, "charCodeAt") as (s: string, i: number) => number;
export const fromCharCode = String.fromCharCode;
export const toStr = String;
export const num = Number;
export const parseNum = W.parseFloat;
export const isNaNum = Number.isNaN;
export const arrJoin = must(Array.prototype, "join") as (a: unknown[], sep: string) => string;
export const isArray = Array.isArray;
export const mathMin = Math.min;
export const mathMax = Math.max;
export const mathRound = Math.round;
export const mathImul = Math.imul;
export const jsonStringify = JSON.stringify;
export const jsonParse = JSON.parse;
export const PromiseCtor = Promise;
export const WeakRefCtor = W.WeakRef;
export const weakDeref = must(W.WeakRef?.prototype, "deref") as <T>(r: unknown) => T | undefined;
export const WeakMapCtor = WeakMap;
export const weakMapGet = must(WeakMap.prototype, "get") as <V>(m: unknown, k: object) => V;
export const weakMapSet = must(WeakMap.prototype, "set") as (
  m: unknown,
  k: object,
  v: unknown,
) => void;
export const Uint8 = Uint8Array;
export const u8Subarray = must(Uint8Array.prototype, "subarray") as (
  a: Uint8Array,
  s: number,
  e: number,
) => Uint8Array;
export const u8Set = must(Uint8Array.prototype, "set") as (
  a: Uint8Array,
  b: Uint8Array,
  o: number,
) => void;
export const btoaFn = W.btoa;
export const atobFn = W.atob;
export const setTimeoutFn = W.setTimeout;
export const clearTimeoutFn = W.clearTimeout;
export const fetchFn = W.fetch;
export const getRandomValues = W.crypto
  ? (must(W.crypto, "getRandomValues") as (c: Crypto, a: Uint32Array) => Uint32Array)
  : undefined;
export const CRYPTO = W.crypto;
export const URLCtor = W.URL;
export const urlHref = getter<string>(W.URL?.prototype, "href");
export const urlPathname = getter<string>(W.URL?.prototype, "pathname");
export const urlProtocol = getter<string>(W.URL?.prototype, "protocol");

// Window.
export const getComputedStyleFn = must(W, "getComputedStyle") as (
  w: Window,
  el: Element,
) => CSSStyleDeclaration;
export const styleValue = must(W.CSSStyleDeclaration?.prototype, "getPropertyValue") as (
  s: CSSStyleDeclaration,
  p: string,
) => string;
export const winPostMessage = must(W, "postMessage") as (
  w: Window,
  data: unknown,
  origin: string,
  transfer?: Transferable[],
) => void;
export const scrollX = getter<number>(W, "scrollX");
export const scrollY = getter<number>(W, "scrollY");
export const innerWidth = getter<number>(W, "innerWidth");
export const innerHeight = getter<number>(W, "innerHeight");
export const winScrollBy = must(W, "scrollBy") as (w: Window, o: ScrollToOptions) => void;
export const locHref = getter<string>(LOC, "href");
export const locHost = getter<string>(LOC, "host");
export const locOrigin = getter<string>(LOC, "origin");
export const LOCATION = LOC;
export const winGetSelection = must(W, "getSelection") as (w: Window) => Selection | null;

// Nodes and elements.
const NP = W.Node.prototype;
const EP = W.Element.prototype;
const HP = W.HTMLElement.prototype;
export const parentNode = getter<Node | null>(NP, "parentNode");
export const firstChild = getter<Node | null>(NP, "firstChild");
export const nextSibling = getter<Node | null>(NP, "nextSibling");
export const nodeType = getter<number>(NP, "nodeType");
export const nodeValue = getter<string | null>(NP, "nodeValue");
export const textContent = getter<string | null>(NP, "textContent");
export const setTextContent = setter<string>(NP, "textContent");
export const ownerDocument = getter<Document | null>(NP, "ownerDocument");
export const isConnected = getter<boolean>(NP, "isConnected");
export const nodeContains = must(NP, "contains") as (n: Node, o: Node | null) => boolean;
export const getRootNode = must(NP, "getRootNode") as (n: Node) => Node;
export const localName = getter<string>(EP, "localName");
export const shadowRoot = getter<ShadowRoot | null>(EP, "shadowRoot");
export const getAttribute = must(EP, "getAttribute") as (el: Element, n: string) => string | null;
export const hasAttribute = must(EP, "hasAttribute") as (el: Element, n: string) => boolean;
export const getRect = must(EP, "getBoundingClientRect") as (el: Element) => DOMRect;
export const closest = must(EP, "closest") as (el: Element, sel: string) => Element | null;
export const matches = must(EP, "matches") as (el: Element, sel: string) => boolean;
export const elQuerySelector = must(EP, "querySelector") as (
  el: Element,
  sel: string,
) => Element | null;
export const scrollIntoView = must(EP, "scrollIntoView") as (
  el: Element,
  o?: ScrollIntoViewOptions,
) => void;
export const scrollIntoViewIfNeeded = method(EP, "scrollIntoViewIfNeeded") as
  | ((el: Element, center?: boolean) => void)
  | undefined;
export const elScrollBy = must(EP, "scrollBy") as (el: Element, o: ScrollToOptions) => void;
export const scrollTop = getter<number>(EP, "scrollTop");
export const scrollLeft = getter<number>(EP, "scrollLeft");
export const scrollHeight = getter<number>(EP, "scrollHeight");
export const scrollWidth = getter<number>(EP, "scrollWidth");
export const clientHeight = getter<number>(EP, "clientHeight");
export const clientWidth = getter<number>(EP, "clientWidth");
export const clientLeft = getter<number>(EP, "clientLeft");
export const clientTop = getter<number>(EP, "clientTop");
export const focusEl = must(HP, "focus") as (el: Element, o?: FocusOptions) => void;
export const isContentEditable = getter<boolean>(HP, "isContentEditable");
export const shadowHost = getter<Element>(W.ShadowRoot?.prototype, "host");
export const rootActiveElement = getter<Element | null>(W.ShadowRoot?.prototype, "activeElement");
export const rootElementFromPoint = must(W.ShadowRoot?.prototype, "elementFromPoint") as (
  r: ShadowRoot,
  x: number,
  y: number,
) => Element | null;
export const fragGetElementById = must(W.DocumentFragment?.prototype, "getElementById") as (
  r: DocumentFragment,
  id: string,
) => Element | null;
export const assignedNodes = must(W.HTMLSlotElement?.prototype, "assignedNodes") as (
  s: HTMLSlotElement,
  o: { flatten: boolean },
) => Node[];

// Form controls.
const IP = W.HTMLInputElement.prototype;
const TP = W.HTMLTextAreaElement.prototype;
const SLP = W.HTMLSelectElement.prototype;
const OP = W.HTMLOptionElement.prototype;
export const inputValue = getter<string>(IP, "value");
export const setInputValue = setter<string>(IP, "value");
export const inputChecked = getter<boolean>(IP, "checked");
export const inputIndeterminate = getter<boolean>(IP, "indeterminate");
export const inputSelect = must(IP, "select") as (el: Element) => void;
export const setInputFiles = setter<FileList>(IP, "files");
export const inputReadOnly = getter<boolean>(IP, "readOnly");
export const textareaValue = getter<string>(TP, "value");
export const setTextareaValue = setter<string>(TP, "value");
export const textareaSelect = must(TP, "select") as (el: Element) => void;
export const textareaReadOnly = getter<boolean>(TP, "readOnly");
export const selectOptions = getter<HTMLOptionsCollection>(SLP, "options");
export const selectSelectedIndex = getter<number>(SLP, "selectedIndex");
export const setSelectSelectedIndex = setter<number>(SLP, "selectedIndex");
export const selectMultiple = getter<boolean>(SLP, "multiple");
export const selectSize = getter<number>(SLP, "size");
export const optionText = getter<string>(OP, "text");
export const optionValue = getter<string>(OP, "value");
export const optionSelected = getter<boolean>(OP, "selected");
export const collectionLength = getter<number>(W.HTMLCollection?.prototype, "length");
export const collectionItem = must(W.HTMLCollection?.prototype, "item") as (
  c: HTMLCollection,
  i: number,
) => Element | null;
export const nodeListLength = getter<number>(W.NodeList?.prototype, "length");
export const nodeListItem = must(W.NodeList?.prototype, "item") as (
  c: NodeList,
  i: number,
) => Node | null;
/** `el.form` for whichever form-associated element [el] is. */
const formGetters = [
  getter<HTMLFormElement | null>(IP, "form"),
  getter<HTMLFormElement | null>(TP, "form"),
  getter<HTMLFormElement | null>(SLP, "form"),
  getter<HTMLFormElement | null>(W.HTMLButtonElement.prototype, "form"),
];
const labelsGetters = [
  getter<NodeList | null>(IP, "labels"),
  getter<NodeList | null>(TP, "labels"),
  getter<NodeList | null>(SLP, "labels"),
  getter<NodeList | null>(W.HTMLButtonElement.prototype, "labels"),
];
const FORM_TAGS = ["input", "textarea", "select", "button"];
export function formOf(el: Element): HTMLFormElement | null {
  const tag = localName(el);
  for (let i = 0; i < FORM_TAGS.length; i++)
    if (FORM_TAGS[i] === tag) return (formGetters[i] as (s: unknown) => HTMLFormElement | null)(el);
  return closest(el, "form") as HTMLFormElement | null;
}
export function labelsOf(el: Element): NodeList | null {
  const tag = localName(el);
  for (let i = 0; i < FORM_TAGS.length; i++)
    if (FORM_TAGS[i] === tag) return (labelsGetters[i] as (s: unknown) => NodeList | null)(el);
  return null;
}
export const labelControl = getter<Element | null>(W.HTMLLabelElement?.prototype, "control");
export const formQuerySelector = must(W.HTMLFormElement.prototype, "querySelector") as (
  f: HTMLFormElement,
  sel: string,
) => Element | null;
export const formRequestSubmit = method(W.HTMLFormElement.prototype, "requestSubmit") as
  | ((f: HTMLFormElement, submitter?: Element | null) => void)
  | undefined;
export const iframeContentWindow = getter<Window | null>(
  W.HTMLIFrameElement.prototype,
  "contentWindow",
);
export const frameContentWindow = getter<Window | null>(
  W.HTMLFrameElement?.prototype,
  "contentWindow",
);

// Documents.
const DP = W.Document.prototype;
export const docActiveElement = getter<Element | null>(DP, "activeElement");
export const docElementFromPoint = must(DP, "elementFromPoint") as (
  d: Document,
  x: number,
  y: number,
) => Element | null;
export const docGetElementById = must(DP, "getElementById") as (
  d: Document,
  id: string,
) => Element | null;
export const docCreateRange = must(DP, "createRange") as (d: Document) => Range;
export const docExecCommand = must(DP, "execCommand") as (
  d: Document,
  cmd: string,
  ui: boolean,
  value?: string,
) => boolean;
export const docTitle = getter<string>(DP, "title");
export const docElement = getter<Element | null>(DP, "documentElement");
export const docBody = getter<HTMLElement | null>(DP, "body");
export const docScrollingElement = getter<Element | null>(DP, "scrollingElement");
export const docQuerySelectorAll = must(DP, "querySelectorAll") as (
  d: Document,
  sel: string,
) => NodeList;
export const rangeSelectNodeContents = must(W.Range.prototype, "selectNodeContents") as (
  r: Range,
  n: Node,
) => void;
export const rangeRect = must(W.Range.prototype, "getBoundingClientRect") as (r: Range) => DOMRect;
export const rangeCollapse = must(W.Range.prototype, "collapse") as (
  r: Range,
  toStart: boolean,
) => void;
export const selRemoveAllRanges = must(W.Selection?.prototype, "removeAllRanges") as (
  s: Selection,
) => void;
export const selAddRange = must(W.Selection?.prototype, "addRange") as (
  s: Selection,
  r: Range,
) => void;
const RP = W.DOMRect?.prototype ?? W.DOMRectReadOnly?.prototype;
export const rectLeft = getter<number>(RP, "left");
export const rectTop = getter<number>(RP, "top");
export const rectWidth = getter<number>(RP, "width");
export const rectHeight = getter<number>(RP, "height");

// Events.
const ETP = W.EventTarget.prototype;
export const addListener = must(ETP, "addEventListener") as (
  t: EventTarget,
  type: string,
  fn: (e: Event) => void,
  o?: boolean | AddEventListenerOptions,
) => void;
export const dispatch = must(ETP, "dispatchEvent") as (t: EventTarget, e: Event) => boolean;
export const EventCtor = W.Event;
export const MouseEventCtor = W.MouseEvent;
export const PointerEventCtor = W.PointerEvent ?? W.MouseEvent;
export const KeyboardEventCtor = W.KeyboardEvent;
export const InputEventCtor = W.InputEvent ?? W.Event;
export const FocusEventCtor = W.FocusEvent ?? W.Event;
export const MessageChannelCtor = W.MessageChannel;
export const eventDefaultPrevented = getter<boolean>(W.Event.prototype, "defaultPrevented");
export const stopImmediate = must(W.Event.prototype, "stopImmediatePropagation") as (
  e: Event,
) => void;
export const messageData = getter<unknown>(W.MessageEvent.prototype, "data");
export const messageSource = getter<MessageEventSource | null>(W.MessageEvent.prototype, "source");
export const messagePorts = getter<readonly MessagePort[]>(W.MessageEvent.prototype, "ports");
export const portPostMessage = must(W.MessagePort.prototype, "postMessage") as (
  p: MessagePort,
  m: unknown,
) => void;
export const portStart = must(W.MessagePort.prototype, "start") as (p: MessagePort) => void;
export const portClose = must(W.MessagePort.prototype, "close") as (p: MessagePort) => void;
export const channelPort1 = getter<MessagePort>(W.MessageChannel?.prototype, "port1");
export const channelPort2 = getter<MessagePort>(W.MessageChannel?.prototype, "port2");

// Files and fetch.
export const DataTransferCtor = W.DataTransfer;
export const FileCtor = W.File;
export const dataTransferItems = getter<DataTransferItemList>(W.DataTransfer?.prototype, "items");
export const dataTransferFiles = getter<FileList>(W.DataTransfer?.prototype, "files");
export const itemsAdd = must(W.DataTransferItemList?.prototype, "add") as (
  l: DataTransferItemList,
  f: File,
) => void;
export const responseOk = getter<boolean>(W.Response?.prototype, "ok");
export const responseStatus = getter<number>(W.Response?.prototype, "status");
export const responseUrl = getter<string>(W.Response?.prototype, "url");
export const responseHeaders = getter<Headers>(W.Response?.prototype, "headers");
export const responseBody = getter<ReadableStream<Uint8Array> | null>(
  W.Response?.prototype,
  "body",
);
export const responseArrayBuffer = must(W.Response?.prototype, "arrayBuffer") as (
  r: Response,
) => Promise<ArrayBuffer>;
export const headersGet = must(W.Headers?.prototype, "get") as (
  h: Headers,
  n: string,
) => string | null;
export const streamGetReader = must(W.ReadableStream?.prototype, "getReader") as (
  s: ReadableStream<Uint8Array>,
) => ReadableStreamDefaultReader<Uint8Array>;
export const readerRead = must(W.ReadableStreamDefaultReader?.prototype, "read") as (
  r: ReadableStreamDefaultReader<Uint8Array>,
) => Promise<ReadableStreamReadResult<Uint8Array>>;
export const readerCancel = must(W.ReadableStreamDefaultReader?.prototype, "cancel") as (
  r: ReadableStreamDefaultReader<Uint8Array>,
) => Promise<void>;

// Safe helpers built on the captured functions.

/** An array with no prototype: index writes can't reach a setter the page put on Array.prototype. */
export function list<T>(): T[] {
  return setProto([], null) as T[];
}
export function push<T>(a: T[], v: T): void {
  a[a.length] = v;
}
export function join(a: unknown[], sep: string): string {
  return arrJoin(a, sep);
}
/** A plain record with no prototype. */
export function record<V>(): Record<string, V> {
  return create(null) as Record<string, V>;
}

const isSpace = (c: number) =>
  c === 32 || c === 9 || c === 10 || c === 13 || c === 12 || c === 160 || c === 0x200b;

/** Whitespace collapsed to single spaces, trimmed, cut to [max] with an ellipsis. */
export function clean(v: unknown, max = 150): string {
  const s = typeof v === "string" ? v : v == null ? "" : toStr(v);
  let space = false;
  let out = "";
  for (let i = 0; i < s.length; i++) {
    const c = strCode(s, i);
    if (isSpace(c)) {
      space = out.length > 0;
      continue;
    }
    if (space) out += " ";
    space = false;
    out += s[i];
    if (out.length > max + 8) break;
  }
  return out.length > max ? `${strSlice(out, 0, max - 1)}…` : out;
}

/** Whitespace-separated words of [s]. */
export function words(s: string | null | undefined): string[] {
  const out = list<string>();
  if (!s) return out;
  let w = "";
  for (let i = 0; i < s.length; i++) {
    if (isSpace(strCode(s, i))) {
      if (w) push(out, w);
      w = "";
    } else w += s[i];
  }
  if (w) push(out, w);
  return out;
}

export function startsWith(s: string, p: string): boolean {
  return strSlice(s, 0, p.length) === p;
}
export function includes(s: string, t: string): boolean {
  return strIndexOf(s, t) !== -1;
}

/** `"text"` with inner quotes escaped, as agent-browser prints names. */
export function quote(t: string): string {
  let out = '"';
  for (let i = 0; i < t.length; i++) out += t[i] === '"' ? '\\"' : t[i];
  return `${out}"`;
}

const HEX = "0123456789abcdef";
/** FNV-1a, 32 bits, as 8 hex digits. */
export function hash(s: string): string {
  let h = 0x811c9dc5;
  for (let i = 0; i < s.length; i++) {
    h ^= strCode(s, i);
    h = mathImul(h, 0x01000193);
  }
  let out = "";
  for (let i = 7; i >= 0; i--) out += HEX[(h >>> (i * 4)) & 15];
  return out;
}

export function sleep(ms: number): Promise<void> {
  return new PromiseCtor((r) => {
    setTimeoutFn(r, ms);
  });
}

/** A random hex token (per page). */
export function randomToken(): string {
  const a = new Uint32Array(4);
  if (getRandomValues && CRYPTO) getRandomValues(CRYPTO, a);
  else for (let i = 0; i < 4; i++) a[i] = (Math.random() * 0xffffffff) >>> 0;
  let out = "";
  for (let i = 0; i < 4; i++)
    for (let k = 7; k >= 0; k--) out += HEX[((a[i] ?? 0) >>> (k * 4)) & 15];
  return out;
}

export function style(el: Element): CSSStyleDeclaration {
  return getComputedStyleFn(WIN, el);
}
export function css(s: CSSStyleDeclaration, p: string): string {
  return styleValue(s, p);
}
