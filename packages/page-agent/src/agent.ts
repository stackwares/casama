/**
 * Commands from native (or from the parent frame's agent): one JSON command in, one JSON answer
 * out. The README is the contract. Refs live in the frame that took the snapshot; refs to elements
 * in a child frame are forwarded to that frame's agent.
 */
import extractTables from "virtual:extract-tables";
import {
  clickAt,
  DOWNLOAD_MAX,
  download,
  Fail,
  fill,
  focusedForTyping,
  guardField,
  isFail,
  locate,
  press,
  reveal,
  scroll,
  typeInto,
  upload,
} from "./act.ts";
import { factsOf, fingerprintOf, resetMemo } from "./dom.ts";
import { type Answer, connect, type FrameLink, linkFor, request } from "./frames.ts";
import { type Line, readLines, snapshotLines } from "./page.ts";
import {
  clientLeft,
  clientTop,
  css,
  DOC,
  docElementFromPoint,
  docTitle,
  getRect,
  includes,
  isArray,
  isConnected,
  isNaNum,
  join,
  jsonParse,
  jsonStringify,
  LOCATION,
  list,
  localName,
  locHref,
  mathMin,
  num,
  objectKeys,
  ownerDocument,
  parseNum,
  push,
  record,
  rectLeft,
  rectTop,
  sleep,
  style,
  WeakRefCtor,
  weakDeref,
} from "./prims.ts";

type Args = Record<string, unknown>;

type Target =
  | { kind: "el"; el: WeakRef<Element> }
  | { kind: "frame"; link: FrameLink; key: string; frame: WeakRef<Element> };

/** A snapshot line, with what its ref points at (an element here, or a ref in a child frame). */
interface Out {
  pre: string;
  post: string;
  target?: Target;
}

let refs = record<Target>();
let maxDownload = DOWNLOAD_MAX;

/** Forget every ref (a new snapshot, or the page is going away). */
export function clearRefs(): void {
  refs = record<Target>();
}

/** Lowers the download cap (tests); it can't be raised past 20 MB. */
export function setDownloadCap(n: number): void {
  maxDownload = mathMin(n, DOWNLOAD_MAX);
}

/** Own properties only, into a record with no prototype: a page can't plant inherited fields. */
function own(v: unknown): Args {
  const out = record<unknown>();
  if (!v || typeof v !== "object" || isArray(v)) return out;
  const keys = objectKeys(v);
  for (let i = 0; i < keys.length; i++) {
    const k = keys[i] as string;
    out[k] = (v as Args)[k];
  }
  return out;
}

const str = (v: unknown, d = ""): string => (typeof v === "string" ? v : d);
const bool = (v: unknown, d: boolean): boolean => (typeof v === "boolean" ? v : d);
const int = (v: unknown, d: number): number => {
  const n = typeof v === "number" ? v : typeof v === "string" ? parseNum(v) : Number.NaN;
  return !isNaNum(n) && n >= 0 ? n - (n % 1) : d;
};

function wref(el: Element): WeakRef<Element> {
  return new WeakRefCtor(el);
}

const now = Date.now;
const FRAME_TIMEOUT = 1000;
const ACT_TIMEOUT = 15000;

/** This frame's lines plus each visible child frame's, frames asked in parallel. */
async function assemble(
  interactiveOnly: boolean,
  maxLines: number,
): Promise<{ lines: Out[]; trimmed: boolean }> {
  resetMemo();
  const own = snapshotLines(interactiveOnly, maxLines);
  const lines = list<Out>();
  if (!own.lines.length) push(lines, { pre: "(nothing on the page)", post: "" });
  for (let i = 0; i < own.lines.length; i++) {
    const l = own.lines[i] as Line;
    push(lines, {
      pre: l.pre,
      post: l.post,
      target: l.target ? { kind: "el", el: wref(l.target) } : undefined,
    });
  }
  let trimmed = own.trimmed;
  const asks = list<Promise<{ link: FrameLink; answer: Answer | null } | null>>();
  for (let i = 0; i < own.frames.length; i++) {
    const f = own.frames[i] as Element;
    push(
      asks,
      (async () => {
        const link = await connect(f, FRAME_TIMEOUT);
        if (!link) return null;
        const answer = await request(
          link,
          "frame_snapshot",
          { interactive_only: interactiveOnly, max_lines: maxLines },
          FRAME_TIMEOUT * 2,
        );
        return { link, answer };
      })(),
    );
  }
  for (let i = 0; i < asks.length; i++) {
    const got = await asks[i];
    const frameEl = own.frames[i] as Element;
    const remote = got?.answer?.ok ? got.answer.lines : null;
    if (!got || !isArray(remote)) {
      push(lines, { pre: "- frame: (not readable)", post: "" });
      continue;
    }
    if (got.answer?.trimmed === true) trimmed = true;
    if (!remote.length && interactiveOnly) continue;
    push(lines, { pre: "- frame:", post: "" });
    if (!remote.length) push(lines, { pre: "(nothing on the page)", post: "" });
    for (let k = 0; k < remote.length; k++) {
      const r = remote[k];
      if (!isArray(r)) continue;
      const key = typeof r[1] === "string" ? r[1] : "";
      push(lines, {
        pre: str(r[0]),
        post: str(r[2]),
        target: key ? { kind: "frame", link: got.link, key, frame: wref(frameEl) } : undefined,
      });
    }
  }
  return { lines, trimmed };
}

/** Numbers the refs e1, e2… and keeps them for later steps. */
function numberRefs(lines: Out[], maxLines: number): { text: string; arrays: unknown[][] } {
  clearRefs();
  const text = list<string>();
  const arrays = list<unknown[]>();
  let n = 1;
  for (let i = 0; i < lines.length && text.length < maxLines; i++) {
    const l = lines[i] as Out;
    if (l.target) {
      const key = `e${n++}`;
      refs[key] = l.target;
      push(text, `${l.pre}[ref=${key}]${l.post}`);
      push(arrays, [l.pre, key, l.post]);
    } else {
      push(text, l.pre + l.post);
      push(arrays, [l.pre, null, l.post]);
    }
  }
  return { text: join(text, "\n"), arrays };
}

async function snapshot(a: Args) {
  const interactiveOnly = bool(a.interactive_only, true);
  const maxLines = int(a.max_lines, 1500) || 1500;
  const { lines, trimmed } = await assemble(interactiveOnly, maxLines);
  const r = numberRefs(lines, maxLines);
  const cut = trimmed || lines.length > maxLines;
  return { text: cut ? `${r.text}\n… (snapshot trimmed)` : r.text, ...where() };
}

async function frameSnapshot(a: Args) {
  const interactiveOnly = bool(a.interactive_only, true);
  const maxLines = int(a.max_lines, 1500) || 1500;
  const { lines, trimmed } = await assemble(interactiveOnly, maxLines);
  // The "(nothing on the page)" line belongs to the parent's rendering, not ours.
  const kept = list<Out>();
  for (let i = 0; i < lines.length; i++) {
    const l = lines[i] as Out;
    if (i === 0 && !l.target && l.pre === "(nothing on the page)") continue;
    push(kept, l);
  }
  const r = numberRefs(kept, maxLines);
  return { lines: r.arrays, trimmed: trimmed || kept.length > maxLines };
}

async function readAll(max: number): Promise<string> {
  resetMemo();
  const own = readLines(max);
  const parts = list<string>();
  if (own.text) push(parts, own.text);
  const asks = list<Promise<Answer | null>>();
  for (let i = 0; i < own.frames.length; i++)
    push(
      asks,
      (async () => {
        const link = await connect(own.frames[i] as Element, FRAME_TIMEOUT);
        return link ? request(link, "frame_read", { max }, FRAME_TIMEOUT * 2) : null;
      })(),
    );
  for (let i = 0; i < asks.length; i++) {
    const got = await asks[i];
    const t = got?.ok ? str(got.text) : "";
    if (t) push(parts, t);
  }
  return join(parts, "\n\n");
}

function where() {
  return { url: locHref(LOCATION), title: docTitle(DOC) };
}

/** The element a ref points at in this frame, or the frame link to forward to. */
function resolve(ref: string): { el: Element } | { link: FrameLink; key: string; frame: Element } {
  const t = refs[ref];
  if (!t)
    throw new Fail("stale_ref", `There's no ${ref || "ref"} on the page now. Take a new snapshot.`);
  if (t.kind === "el") {
    const el = weakDeref<Element>(t.el);
    if (!el || !isConnected(el) || ownerDocument(el) !== DOC)
      throw new Fail("stale_ref", `${ref} is gone from the page. Take a new snapshot.`);
    return { el };
  }
  const frame = weakDeref<Element>(t.frame);
  if (!frame || !isConnected(frame))
    throw new Fail("stale_ref", `The frame holding ${ref} is gone. Take a new snapshot.`);
  return { link: t.link, key: t.key, frame };
}

function checkFingerprint(el: Element, a: Args): string {
  const fp = fingerprintOf(factsOf(el));
  const want = str(a.fingerprint);
  if (want && want !== fp)
    throw new Fail(
      "page_changed",
      "That element changed since it was checked (its label or kind is different). Take a new snapshot.",
    );
  return fp;
}

/** The offset of a frame's content box in this frame's viewport. */
function frameOffset(frame: Element): { x: number; y: number } {
  const r = getRect(frame);
  const s = style(frame);
  return {
    x: rectLeft(r) + clientLeft(frame) + (parseNum(css(s, "padding-left")) || 0),
    y: rectTop(r) + clientTop(frame) + (parseNum(css(s, "padding-top")) || 0),
  };
}

async function forward(link: FrameLink, cmd: string, a: Args, key: string | null): Promise<Answer> {
  const args = record<unknown>();
  const keys = objectKeys(a);
  for (let i = 0; i < keys.length; i++) args[keys[i] as string] = a[keys[i] as string];
  if (key !== null) args.ref = key;
  const got = await request(link, cmd, args, ACT_TIMEOUT);
  if (!got) throw new Fail("stale_ref", "That frame stopped answering. Take a new snapshot.");
  return got;
}

/** Locates a ref inside a child frame and checks the frame itself isn't covered at that point. */
async function locateInFrame(t: { link: FrameLink; key: string; frame: Element }, a: Args) {
  reveal(t.frame);
  const got = await forward(t.link, "locate", a, t.key);
  if (!got.ok) return got;
  const off = frameOffset(t.frame);
  const x = off.x + num(got.x);
  const y = off.y + num(got.y);
  const hit = docElementFromPoint(DOC, x, y);
  if (hit !== t.frame)
    throw new Fail(
      "covered",
      "Something else on the page covers that element, so it wasn't touched. Take a new snapshot.",
    );
  return { ...got, x, y };
}

const FOCUS_FRAME = (el: Element | null) =>
  !!el && (localName(el) === "iframe" || localName(el) === "frame");

/** The focused element here, or the frame link holding focus. */
async function focusTarget(): Promise<{ el: Element | null } | { link: FrameLink }> {
  const el = focusedForTyping();
  if (el && FOCUS_FRAME(el)) {
    const link = await linkFor(el, FRAME_TIMEOUT);
    if (!link)
      throw new Fail(
        "out_of_sight",
        "Focus is in a part of the page Casama can't see into (another site's frame). Ask the person to do this step.",
      );
    return { link };
  }
  return { el };
}

type Result = Record<string, unknown>;

const COMMANDS: Record<string, (a: Args) => Promise<Result>> = {
  async ping() {
    return {};
  },
  snapshot,
  frame_snapshot: frameSnapshot,
  async read(a) {
    const max = int(a.max, 60_000) || 60_000;
    return { text: await readAll(max), ...where() };
  },
  async frame_read(a) {
    return { text: await readAll(int(a.max, 60_000) || 60_000) };
  },
  async url() {
    return where();
  },
  async probe(a) {
    if (a.focused === true) {
      const t = await focusTarget();
      if ("link" in t) return forward(t.link, "probe", a, null);
      if (!t.el) throw new Fail("not_editable", "Nothing on the page has focus.");
      resetMemo();
      const facts = factsOf(t.el);
      return { facts, fingerprint: fingerprintOf(facts) };
    }
    const r = resolve(str(a.ref));
    if ("link" in r) return forward(r.link, "probe", a, r.key);
    resetMemo();
    const facts = factsOf(r.el);
    return { facts, fingerprint: fingerprintOf(facts) };
  },
  async locate(a) {
    const r = resolve(str(a.ref));
    if ("link" in r) return locateInFrame(r, a);
    resetMemo();
    const fingerprint = checkFingerprint(r.el, a);
    const { x, y } = locate(r.el);
    return { x, y, fingerprint };
  },
  async click(a) {
    const r = resolve(str(a.ref));
    if ("link" in r) {
      const at = await locateInFrame(r, a);
      if (!at.ok) return at;
      return forward(r.link, "click", a, r.key);
    }
    resetMemo();
    checkFingerprint(r.el, a);
    const facts = factsOf(r.el);
    const { x, y, hit } = locate(r.el);
    if (a.synthetic !== false) clickAt(hit, x, y);
    return { text: `Clicked "${facts.name || facts.role || facts.tag}".` };
  },
  async fill(a) {
    const r = resolve(str(a.ref));
    if ("link" in r) return forward(r.link, "fill", a, r.key);
    resetMemo();
    checkFingerprint(r.el, a);
    const facts = factsOf(r.el);
    const note = fill(r.el, str(a.text));
    if (includes(note, "Picked")) return { text: note };
    return { text: `Filled "${facts.name || facts.role}".${note}` };
  },
  async type(a) {
    const t = await focusTarget();
    if ("link" in t) return forward(t.link, "type", a, null);
    if (!t.el)
      throw new Fail(
        "not_editable",
        "Nothing that takes text has focus. Click or fill a field first.",
      );
    resetMemo();
    checkFingerprint(t.el, a);
    guardField(t.el);
    typeInto(t.el, str(a.text));
    return { text: "Typed." };
  },
  async press(a) {
    const key = str(a.key);
    if (!key) throw new Fail("error", "No key to press.");
    const t = await focusTarget();
    if ("link" in t) return forward(t.link, "press", a, null);
    resetMemo();
    if (t.el) checkFingerprint(t.el, a);
    press(t.el, key);
    return { text: `Pressed ${key}.` };
  },
  async scroll(a) {
    const d = str(a.direction, "down");
    if (d !== "up" && d !== "down" && d !== "left" && d !== "right")
      throw new Fail("error", "Scroll up, down, left or right.");
    return { text: scroll(d, int(a.amount, 600) || 600) };
  },
  async wait(a) {
    const text = str(a.text);
    const ms = mathMin(int(a.ms, text ? 30_000 : 1000), 30_000);
    if (!text) {
      await sleep(ms);
      return { text: "Done waiting." };
    }
    const until = now() + ms;
    for (;;) {
      if (includes(await readAll(200_000), text)) return { text: `"${text}" is on the page.` };
      if (now() >= until) break;
      await sleep(500);
    }
    throw new Fail("timeout", `"${text}" didn't show up within ${mathMin(ms / 1000, 30)} seconds.`);
  },
  async extract() {
    const v = extractTables() as unknown;
    return { text: typeof v === "string" ? v : jsonStringify(v, null, 1) };
  },
  async upload(a) {
    const r = resolve(str(a.ref));
    if ("link" in r) return forward(r.link, "upload", a, r.key);
    const name = str(a.name, "file");
    upload(r.el, name, str(a.media_type, "application/octet-stream"), str(a.data));
    return { text: `Put ${name} in the upload field.` };
  },
  async download(a) {
    const url = str(a.url);
    if (!url) throw new Fail("error", "No address to download.");
    const cap = typeof a.max_bytes === "number" ? mathMin(a.max_bytes, maxDownload) : maxDownload;
    const file = await download(url, cap);
    return { text: `Downloaded ${file.name}.`, file };
  },
};

/** Runs one command and gives its answer. Never throws. */
export async function handle(command: unknown): Promise<Answer> {
  let c: Args;
  try {
    c = own(typeof command === "string" ? jsonParse(command) : command);
  } catch {
    return { id: null, ok: false, code: "error", message: "The command isn't valid JSON." };
  }
  const id = typeof c.id === "string" || typeof c.id === "number" ? c.id : null;
  const cmd = str(c.cmd);
  const run = COMMANDS[cmd];
  if (!run) return { id, ok: false, code: "unsupported", message: `Unknown command "${cmd}".` };
  try {
    const result = await run(own(c.args));
    if (result && (result as Answer).ok === false && "code" in result)
      return { ...(result as Answer), id };
    return { ...result, id, ok: true };
  } catch (e) {
    if (isFail(e)) return { id, ok: false, code: e.code, message: e.message };
    return {
      id,
      ok: false,
      code: "error",
      message: `The page script failed: ${e instanceof Error ? e.message : str(e, "unknown error")}`,
    };
  }
}

/** A JSON-safe copy (fresh plain objects, nothing the page could have touched). */
export function plain(a: Answer): Answer {
  return jsonParse(jsonStringify(a)) as Answer;
}
