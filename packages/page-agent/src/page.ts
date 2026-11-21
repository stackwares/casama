/**
 * One frame's snapshot and readable text, walked from the DOM in the shape `formatSnapshot` and
 * `readableText` (apps/extension/src/lib/act/snapshot.ts) give from Chrome's accessibility tree.
 * Frames inside are collected for the caller, which asks each one for its own part.
 */
import {
  CONTENT,
  ELEMENT,
  flagsOf,
  focusedHere,
  headingLevel,
  INTERACTIVE,
  isBlock,
  isSkipped,
  kids,
  nameOf,
  roleOf,
  selfHidden,
  shownValue,
  TEXT,
  textHidden,
} from "./dom.ts";
import {
  clean,
  DOC,
  docElement,
  getRect,
  join,
  list,
  localName,
  mathMin,
  nodeType,
  nodeValue,
  push,
  quote,
  rectHeight,
  rectWidth,
  strSlice,
  strTrim,
} from "./prims.ts";

/** One snapshot line; [target] is the element (or frame ref) its `[ref=…]` points at. */
export interface Line {
  pre: string;
  target?: Element;
  post: string;
}

const VALUE_ROLES: Record<string, true> = {
  textbox: true,
  searchbox: true,
  combobox: true,
  spinbutton: true,
  slider: true,
};

const NORMAL = 0;
const INSIDE_INTERACTIVE = 1;
const INSIDE_CONTENT = 2;

function indent(depth: number, interactiveOnly: boolean): string {
  if (interactiveOnly) return "";
  let s = "";
  for (let i = 0; i < depth && i < 40; i++) s += "  ";
  return s;
}

function isFrame(el: Element): boolean {
  const t = localName(el);
  return t === "iframe" || t === "frame";
}

function frameVisible(el: Element): boolean {
  const r = getRect(el);
  return rectWidth(r) >= 1 && rectHeight(r) >= 1;
}

export interface FrameSnapshot {
  lines: Line[];
  frames: Element[];
  trimmed: boolean;
}

/** This frame's snapshot lines, and the visible frames inside it (in page order). */
export function snapshotLines(interactiveOnly: boolean, maxLines: number): FrameSnapshot {
  const lines = list<Line>();
  const frames = list<Element>();
  const focused = focusedHere().el;
  let trimmed = false;
  const walk = (n: Node, depth: number, mode: number, level: number) => {
    if (level > 200) return;
    const cs = kids(n);
    for (let i = 0; i < cs.length; i++) {
      if (lines.length >= maxLines) {
        trimmed = true;
        return;
      }
      const c = cs[i] as Node;
      const t = nodeType(c);
      if (t === TEXT) {
        if (mode !== NORMAL || interactiveOnly) continue;
        const v = nodeValue(c) ?? "";
        if (!strTrim(v) || textHidden(c as Text, n as Element)) continue;
        push(lines, { pre: `${indent(depth, false)}- text ${quote(clean(v))}`, post: "" });
        continue;
      }
      if (t !== ELEMENT) continue;
      const el = c as Element;
      if (isSkipped(el) || selfHidden(el)) continue;
      if (isFrame(el)) {
        if (frames.length < 20 && frameVisible(el)) push(frames, el);
        continue;
      }
      const role = roleOf(el);
      if (INTERACTIVE[role] === true) {
        const name = nameOf(el, role);
        const value = VALUE_ROLES[role] === true ? clean(shownValue(el, role), 80) : "";
        push(lines, {
          pre: `${indent(depth, interactiveOnly)}- ${role}${name ? ` ${quote(name)}` : ""} `,
          target: el,
          post: `${flagsOf(el, role, focused)}${value ? `: ${quote(value)}` : ""}`,
        });
        // A link's or button's own text is its name; only controls inside it are listed.
        const tag = localName(el);
        if (tag !== "select" && tag !== "input" && tag !== "textarea")
          walk(el, depth + 1, INSIDE_INTERACTIVE, level + 1);
        continue;
      }
      if (mode !== INSIDE_INTERACTIVE && !interactiveOnly && CONTENT[role] === true) {
        const name = nameOf(el, role);
        if (name) {
          const label = role === "image" ? "img" : role;
          push(lines, {
            pre: `${indent(depth, false)}- ${label} ${quote(name)}${flagsOf(el, role, null)}`,
            post: "",
          });
          walk(el, depth + 1, INSIDE_CONTENT, level + 1);
          continue;
        }
      }
      walk(el, depth, mode, level + 1);
    }
  };
  const root = docElement(DOC);
  if (root && !selfHidden(root)) walk(root, 0, NORMAL, 0);
  return { lines, frames, trimmed };
}

const BLOCKS: Record<string, true> = {
  paragraph: true,
  listitem: true,
  row: true,
  heading: true,
  blockquote: true,
  article: true,
  section: true,
  main: true,
  region: true,
};

/**
 * This frame's visible text: headings as "#" lines, fields as `[name]`, hidden text left out.
 * Returns the frames inside it too.
 */
export function readLines(max: number): { text: string; frames: Element[] } {
  const out = list<string>();
  const frames = list<Element>();
  let line = "";
  let size = 0;
  const flush = () => {
    const t = clean(line, 100_000);
    if (t) {
      push(out, t);
      size += t.length + 1;
    }
    line = "";
  };
  const walk = (n: Node, level: number) => {
    if (level > 200) return;
    const cs = kids(n);
    for (let i = 0; i < cs.length; i++) {
      if (size > max) return;
      const c = cs[i] as Node;
      const t = nodeType(c);
      if (t === TEXT) {
        const v = nodeValue(c) ?? "";
        if (!strTrim(v) || textHidden(c as Text, n as Element)) continue;
        line += ` ${v}`;
        continue;
      }
      if (t !== ELEMENT) continue;
      const el = c as Element;
      if (isSkipped(el) || selfHidden(el)) continue;
      const tag = localName(el);
      if (isFrame(el)) {
        if (frames.length < 20 && frameVisible(el)) push(frames, el);
        continue;
      }
      if (tag === "br") {
        flush();
        continue;
      }
      const role = roleOf(el);
      if (role === "heading") {
        flush();
        const level = mathMin(headingLevel(el), 6);
        let hashes = "";
        for (let k = 0; k < level; k++) hashes += "#";
        line = `${hashes} ${clean(nameOf(el, role), 300)}`;
        flush();
        continue;
      }
      if (role === "textbox" || role === "searchbox") {
        line += ` [${clean(nameOf(el, role), 80) || "text field"}]`;
        continue;
      }
      if (tag === "select" || tag === "input" || tag === "textarea") continue;
      const block = BLOCKS[role] === true || isBlock(el);
      if (block) flush();
      walk(el, level + 1);
      if (block) flush();
    }
  };
  const root = docElement(DOC);
  if (root && !selfHidden(root)) walk(root, 0);
  flush();
  const text = join(out, "\n");
  return {
    text: text.length > max ? `${strSlice(text, 0, max)}\n… (trimmed)` : text,
    frames,
  };
}
