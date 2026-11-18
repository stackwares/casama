/**
 * Accessibility snapshots for bots working in this browser (D-323 Phase 3, plan §9.5): built from
 * Chrome's accessibility tree (DevTools Protocol) in the same shape agent-browser gives on a bot's
 * computer, `- role "name" [ref=e1]`, so skills and replays work in both.
 *
 * Text that isn't visible is left out (plan §11: pages are untrusted): anything Chrome's tree ignores
 * (display: none, aria-hidden), plus what DOMSnapshot shows as transparent, hidden, tiny (1 px boxes,
 * fonts under 2 px) or pushed off the page. Pure functions, so they're tested without a browser.
 */

export interface AXValue {
  value?: unknown;
}
export interface AXNode {
  nodeId: string;
  ignored?: boolean;
  role?: AXValue;
  name?: AXValue;
  value?: AXValue;
  properties?: Array<{ name: string; value: AXValue }>;
  childIds?: string[];
  parentId?: string;
  backendDOMNodeId?: number;
}

export interface DomSnapshot {
  documents: Array<{
    nodes: { parentIndex?: number[]; backendNodeId?: number[]; nodeType?: number[] };
    layout: { nodeIndex: number[]; styles: number[][]; bounds: number[][] };
  }>;
  strings: string[];
}

/** The styles asked for, in this order, when taking a DOMSnapshot. */
export const SNAPSHOT_STYLES = [
  "display",
  "visibility",
  "opacity",
  "font-size",
  "overflow-x",
  "overflow-y",
  "clip",
  "clip-path",
] as const;

/** Elements a bot can act on; each gets a ref. */
export const INTERACTIVE = new Set([
  "button",
  "link",
  "textbox",
  "searchbox",
  "combobox",
  "checkbox",
  "radio",
  "switch",
  "slider",
  "spinbutton",
  "menuitem",
  "menuitemcheckbox",
  "menuitemradio",
  "option",
  "tab",
  "treeitem",
  "listbox",
]);

/** Shown in a full snapshot besides interactive elements. */
const CONTENT = new Set([
  "heading",
  "StaticText",
  "img",
  "image",
  "cell",
  "columnheader",
  "rowheader",
  "alert",
  "status",
]);

export interface Ref {
  backendNodeId: number;
  role: string;
  name: string;
}

/**
 * Backend node ids of everything that isn't visibly on the page. Hidden elements hide everything
 * inside them; a zero-size box only counts when it also clips what's inside (the "visually hidden"
 * trick), since empty containers often hold visible, positioned children.
 */
export function hiddenNodes(snap: DomSnapshot): Set<number> {
  const out = new Set<number>();
  const s = (i: number | undefined) => (i === undefined || i < 0 ? "" : (snap.strings[i] ?? ""));
  for (const doc of snap.documents) {
    const ids = doc.nodes.backendNodeId ?? [];
    const parents = doc.nodes.parentIndex ?? [];
    const types = doc.nodes.nodeType ?? [];
    const layoutOf = new Map<number, number>();
    for (const [li, n] of doc.layout.nodeIndex.entries()) layoutOf.set(n, li);
    const hidden: boolean[] = [];
    for (let i = 0; i < ids.length; i++) {
      const p = parents[i] ?? -1;
      let h = p >= 0 ? !!hidden[p] : false;
      const li = layoutOf.get(i);
      const text = types[i] === 3;
      if (!h && li !== undefined) {
        const st = doc.layout.styles[li] ?? [];
        const [display, visibility, opacity, fontSize, ox, oy, clip = "", clipPath = ""] =
          SNAPSHOT_STYLES.map((_, k) => s(st[k]));
        const [x = 0, y = 0, w = 0, hh = 0] = doc.layout.bounds[li] ?? [];
        const clips = /hidden|clip/.test(`${ox} ${oy}`);
        if (display === "none" || visibility === "hidden" || visibility === "collapse") h = true;
        else if (opacity !== "" && Number(opacity) < 0.05) h = true;
        else if (text && Number.parseFloat(fontSize || "16") < 2) h = true;
        else if (/rect\(0(px)?,? 0(px)?,? 0(px)?,? 0(px)?\)/.test(clip)) h = true;
        else if (/inset\((50|100)%\)|circle\(0/.test(clipPath)) h = true;
        else if (!text && clips && (w <= 1 || hh <= 1)) h = true;
        else if (text && (w < 1 || hh < 1)) h = true;
        // Pushed off the page to the left or above (left: -9999px).
        else if (x + w < 0 || y + hh < 0) h = true;
      } else if (!h && li === undefined && text) h = true;
      hidden[i] = h;
      if (h && ids[i] !== undefined) out.add(ids[i] as number);
    }
  }
  return out;
}

const clean = (v: unknown, max = 150) => {
  const t = String(v ?? "")
    .replace(/\s+/g, " ")
    .trim();
  return t.length > max ? `${t.slice(0, max - 1)}…` : t;
};
const quote = (t: string) => `"${t.replaceAll('"', '\\"')}"`;
const prop = (n: AXNode, name: string) => n.properties?.find((p) => p.name === name)?.value?.value;

/** The flags agent-browser prints after an element. */
function flags(n: AXNode, role: string): string {
  const out: string[] = [];
  const checked = prop(n, "checked");
  if (checked === "true" || checked === true) out.push("[checked]");
  if (checked === "mixed") out.push("[mixed]");
  if (prop(n, "disabled") === true) out.push("[disabled]");
  const expanded = prop(n, "expanded");
  if (expanded === true) out.push("[expanded]");
  if (expanded === false) out.push("[collapsed]");
  if (prop(n, "selected") === true) out.push("[selected]");
  if (prop(n, "focused") === true) out.push("[focused]");
  if (role === "heading" && prop(n, "level")) out.push(`[level=${prop(n, "level")}]`);
  return out.length ? ` ${out.join(" ")}` : "";
}

export interface SnapshotOptions {
  interactiveOnly?: boolean;
  /** Refs continue from here (frames after the main page). */
  startAt?: number;
  maxLines?: number;
}

/** The snapshot text and what each ref points at. */
export function formatSnapshot(
  nodes: AXNode[],
  hidden: Set<number>,
  opts: SnapshotOptions = {},
): { text: string; refs: Record<string, Ref>; next: number } {
  const byId = new Map(nodes.map((n) => [n.nodeId, n]));
  const root = nodes.find((n) => !n.parentId || !byId.has(n.parentId));
  const refs: Record<string, Ref> = {};
  const lines: string[] = [];
  const max = opts.maxLines ?? 1500;
  let next = opts.startAt ?? 1;
  const seen = new Set<string>();
  const walk = (n: AXNode | undefined, depth: number) => {
    if (!n || seen.has(n.nodeId) || lines.length >= max) return;
    seen.add(n.nodeId);
    const invisible = n.backendDOMNodeId !== undefined && hidden.has(n.backendDOMNodeId);
    // Hidden: nothing under it is shown either.
    if (invisible) return;
    const role = String(n.role?.value ?? "");
    const name = clean(n.name?.value);
    let shown = false;
    if (!n.ignored && INTERACTIVE.has(role) && n.backendDOMNodeId !== undefined) {
      const ref = `e${next++}`;
      refs[ref] = { backendNodeId: n.backendDOMNodeId, role, name };
      const value = clean(n.value?.value, 80);
      const indent = opts.interactiveOnly ? "" : "  ".repeat(depth);
      lines.push(
        `${indent}- ${role}${name ? ` ${quote(name)}` : ""} [ref=${ref}]${flags(n, role)}${value && ["textbox", "searchbox", "combobox", "spinbutton", "slider"].includes(role) ? `: ${quote(value)}` : ""}`,
      );
      shown = true;
    } else if (!opts.interactiveOnly && !n.ignored && CONTENT.has(role) && name) {
      const label = role === "StaticText" ? "text" : role;
      lines.push(`${"  ".repeat(depth)}- ${label} ${quote(name)}${flags(n, role)}`);
      shown = true;
    }
    // A link's or button's own text is its name: no need to repeat it underneath.
    if (shown && INTERACTIVE.has(role)) {
      for (const c of n.childIds ?? []) markSeen(byId.get(c));
      return;
    }
    for (const c of n.childIds ?? []) walk(byId.get(c), shown ? depth + 1 : depth);
  };
  const markSeen = (n: AXNode | undefined) => {
    if (!n || seen.has(n.nodeId)) return;
    const role = String(n.role?.value ?? "");
    // Interactive elements inside interactive ones (a checkbox in a list item link) still count.
    if (INTERACTIVE.has(role)) return;
    seen.add(n.nodeId);
    for (const c of n.childIds ?? []) markSeen(byId.get(c));
  };
  walk(root, 0);
  // Anything the tree didn't reach from the root (rare) is skipped.
  if (lines.length >= max) lines.push("… (snapshot trimmed)");
  return { text: lines.join("\n") || "(nothing on the page)", refs, next };
}

const BLOCKS = new Set([
  "paragraph",
  "listitem",
  "row",
  "heading",
  "blockquote",
  "article",
  "section",
  "main",
  "region",
]);

/**
 * The page's visible text, for browser.read and watchers: headings as "#" lines, links as their
 * text, hidden text left out like the snapshot.
 */
export function readableText(nodes: AXNode[], hidden: Set<number>, max = 60_000): string {
  const byId = new Map(nodes.map((n) => [n.nodeId, n]));
  const root = nodes.find((n) => !n.parentId || !byId.has(n.parentId));
  const out: string[] = [];
  let line = "";
  let size = 0;
  const flush = () => {
    const t = line.replace(/\s+/g, " ").trim();
    if (t) {
      out.push(t);
      size += t.length + 1;
    }
    line = "";
  };
  const seen = new Set<string>();
  const walk = (n: AXNode | undefined) => {
    if (!n || seen.has(n.nodeId) || size > max) return;
    seen.add(n.nodeId);
    if (n.backendDOMNodeId !== undefined && hidden.has(n.backendDOMNodeId)) return;
    const role = String(n.role?.value ?? "");
    if (role === "heading" && !n.ignored) {
      flush();
      const level = Number(prop(n, "level") ?? 2);
      line = `${"#".repeat(Math.min(Math.max(level, 1), 6))} ${clean(n.name?.value, 300)}`;
      flush();
      return;
    }
    if (role === "StaticText" && !n.ignored) {
      line += ` ${String(n.name?.value ?? "")}`;
      return;
    }
    if ((role === "textbox" || role === "searchbox") && !n.ignored) {
      line += ` [${clean(n.name?.value, 80) || "text field"}]`;
      return;
    }
    const block = BLOCKS.has(role);
    if (block) flush();
    for (const c of n.childIds ?? []) walk(byId.get(c));
    if (block) flush();
  };
  walk(root);
  flush();
  const text = out.join("\n");
  return text.length > max ? `${text.slice(0, max)}\n… (trimmed)` : text;
}
