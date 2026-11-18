// SPDX-License-Identifier: Apache-2.0
// A shared format, also used by the Apache-2.0 SDKs and tools (LICENSING.md).
/**
 * Cards for a plugin's tools (D-345). A plugin may ship `com.casama/cards/<tool>.json`: a card
 * from Casama's own A2UI catalog (a2ui.ts) with `{{result.path}}` bindings into the tool's
 * result. After a call to that tool the run fills it, checks the filled card the way `ui.show`
 * does, and shows it to the person; anything that doesn't fill or check stays text.
 *
 * Imported by relative path (plugin-check runs with plain Node), so no package imports here.
 */
import { BINDING, checkComponents, UI_COMPONENTS, UiCheckError } from "./a2ui.ts";

export const CARDS_DIR = "com.casama/cards/";
/** The card file format this Casama reads. A newer one is skipped, so older servers ignore it. */
export const CARD_FORMAT = 1;
export const CARD_MAX_BYTES = 64 * 1024;
export const CARDS_MAX = 100;
/** Components in one card (as `ui.show` allows). */
export const CARD_MAX_COMPONENTS = 60;
/** Rows one `each` makes when it doesn't say (`max` goes up to 60). */
export const CARD_EACH_DEFAULT = 20;
export const CARD_EACH_MAX = 60;
/** A filled string is cut at this length; a filled card over CARD_MAX_BYTES stays text. */
export const CARD_TEXT_MAX = 2000;

const CARD_FILE = /^com\.casama\/cards\/([A-Za-z0-9_.-]{1,128})\.json$/;
const PATH = /^(?:result|item)(?:\.[A-Za-z0-9_$-]+|\[\d+\])*$/;

/** A checked card: the tool it's for, its components (one is "root") and its optional `when`. */
export interface PluginCard {
  tool: string;
  /** The catalog component at the root, for listings ("Details"). */
  card: string;
  when?: string;
  components: Array<Record<string, unknown>>;
}

const isObj = (v: unknown): v is Record<string, unknown> =>
  typeof v === "object" && v !== null && !Array.isArray(v);

/** Checks one binding path; `item` and `index` only inside an `each`. */
function checkPath(path: string, inEach: boolean, where: string) {
  const p = path.trim();
  if (p === "index") {
    if (!inEach) throw new UiCheckError(`${where}: {{index}} works only inside an "each" row.`);
    return;
  }
  if (!PATH.test(p))
    throw new UiCheckError(
      `${where}: "${path}" isn't a binding Casama can fill. Use result.a.b, result.items[0].name, or item.x inside an "each" row.`,
    );
  if (p.startsWith("item") && !inEach)
    throw new UiCheckError(`${where}: "${path}" works only inside an "each" row.`);
}

/** Walks a card's template and checks every binding, `each` and `max`. */
function checkBindings(v: unknown, inEach: boolean, where: string) {
  if (typeof v === "string") {
    const rest = v.replace(/\{\{([^{}]*)\}\}/g, (_, p: string) => {
      checkPath(p, inEach, where);
      return "";
    });
    if (rest.includes("{{") || rest.includes("}}"))
      throw new UiCheckError(`${where}: a "{{" or "}}" isn't closed or opened.`);
    return;
  }
  if (Array.isArray(v)) {
    for (const x of v) checkBindings(x, inEach, where);
    return;
  }
  if (!isObj(v)) return;
  let inner = inEach;
  if ("each" in v) {
    if (typeof v.each !== "string")
      throw new UiCheckError(`${where}: "each" names a list in the result, like "result.items".`);
    checkPath(v.each, inEach, where);
    if (v.each.trim() === "index")
      throw new UiCheckError(`${where}: "each" names a list in the result, like "result.items".`);
    if (
      v.max !== undefined &&
      (typeof v.max !== "number" || !Number.isInteger(v.max) || v.max < 1 || v.max > CARD_EACH_MAX)
    )
      throw new UiCheckError(`${where}: "max" is a whole number from 1 to ${CARD_EACH_MAX}.`);
    inner = true;
  } else if ("max" in v && Object.keys(v).length === 1) {
    throw new UiCheckError(`${where}: "max" goes with "each".`);
  }
  for (const [k, x] of Object.entries(v)) {
    if (k === "each" || k === "max") continue;
    checkBindings(x, inner, where);
  }
}

/** `each` rows only go in a list: a card's rows, items, markers and the like. */
function checkEachPlacement(v: unknown, inList: boolean, where: string) {
  if (Array.isArray(v)) {
    for (const x of v) checkEachPlacement(x, true, where);
    return;
  }
  if (!isObj(v)) return;
  if ("each" in v && !inList)
    throw new UiCheckError(`${where}: an "each" row goes inside a list, like "rows": [ … ].`);
  for (const x of Object.values(v)) checkEachPlacement(x, false, where);
}

/**
 * Checks one card file (parsed JSON). Throws UiCheckError with what to fix.
 *
 * Two shapes: `{"format": 1, "card": "Details", …its fields…, "when"?}` for one component, or
 * `{"format": 1, "components": [ … ], "when"?}` for a tree of them (one has id "root").
 */
export function checkCardFile(raw: unknown, tool: string): PluginCard {
  if (!isObj(raw)) throw new UiCheckError("The file isn't a JSON object.");
  if (raw.format === undefined) throw new UiCheckError(`It needs "format": ${CARD_FORMAT}.`);
  if (raw.format !== CARD_FORMAT)
    throw new UiCheckError(
      typeof raw.format === "number" && raw.format > CARD_FORMAT
        ? `It's card format ${raw.format}; this Casama reads format ${CARD_FORMAT}.`
        : `"format" must be ${CARD_FORMAT}.`,
    );
  const when = raw.when;
  if (when !== undefined) {
    if (typeof when !== "string" || !when.trim().startsWith("result"))
      throw new UiCheckError('"when" is a path in the result, like "result.status".');
    checkPath(when, false, '"when"');
  }
  let components: Array<Record<string, unknown>>;
  if (raw.components !== undefined) {
    if (raw.card !== undefined) throw new UiCheckError('Give "card" or "components", not both.');
    const extra = Object.keys(raw).filter((k) => !["format", "when", "components"].includes(k));
    if (extra.length)
      throw new UiCheckError(
        `Unknown field ${extra[0]}; with "components", the card's fields go on them.`,
      );
    if (!Array.isArray(raw.components) || !raw.components.length)
      throw new UiCheckError('"components" is a list of 1 or more components.');
    if (raw.components.length > CARD_MAX_COMPONENTS)
      throw new UiCheckError(`A card has at most ${CARD_MAX_COMPONENTS} components.`);
    components = raw.components as Array<Record<string, unknown>>;
  } else {
    if (typeof raw.card !== "string")
      throw new UiCheckError(
        `It needs "card": a component of Casama's catalog (${UI_COMPONENTS.join(", ")}), or "components".`,
      );
    const { format: _f, when: _w, card, ...props } = raw;
    if ("id" in props || "component" in props)
      throw new UiCheckError('With "card", leave out "id" and "component".');
    components = [{ id: "root", component: card, ...props }];
  }
  for (const c of components) {
    if (!isObj(c)) throw new UiCheckError("Each component is an object.");
    const where = `Component "${String(c.id)}"`;
    if (typeof c.id === "string" && BINDING.test(c.id))
      throw new UiCheckError(`${where}: an id can't hold a binding.`);
    checkBindings(c, false, where);
    for (const [k, v] of Object.entries(c)) if (k !== "id") checkEachPlacement(v, false, where);
  }
  checkComponents(components, { template: true });
  const root = components.find((c) => c.id === "root") as Record<string, unknown>;
  return {
    tool,
    card: String(root.component),
    ...(when !== undefined ? { when: (when as string).trim() } : {}),
    components,
  };
}

/**
 * The card files in a plugin (path → text). A bad one is skipped with a warning, so the tool's
 * result stays text and the rest of the plugin installs.
 */
export function checkPluginCards(
  files: Map<string, string>,
  hasServers: boolean,
): { cards: PluginCard[]; warnings: string[] } {
  const warnings: string[] = [];
  const cards: PluginCard[] = [];
  const paths = [...files.keys()].filter((p) => p.startsWith(CARDS_DIR)).sort();
  if (paths.length && !hasServers) {
    warnings.push("Ignored com.casama/cards/: the plugin has no MCP servers");
    return { cards, warnings };
  }
  for (const path of paths) {
    const m = CARD_FILE.exec(path);
    if (!m) {
      warnings.push(`Ignored ${path}: a card is com.casama/cards/<tool>.json`);
      continue;
    }
    const tool = m[1] as string;
    const skip = (why: string) => warnings.push(`Skipped the card for ${tool}: ${why}`);
    if (cards.length >= CARDS_MAX) {
      skip(`a plugin has at most ${CARDS_MAX} cards`);
      continue;
    }
    const text = files.get(path) ?? "";
    if (text.length > CARD_MAX_BYTES) {
      skip(`over ${CARD_MAX_BYTES / 1024} KB`);
      continue;
    }
    let raw: unknown;
    try {
      raw = JSON.parse(text);
    } catch {
      skip("not valid JSON");
      continue;
    }
    try {
      cards.push(checkCardFile(raw, tool));
    } catch (err) {
      if (!(err instanceof UiCheckError)) throw err;
      skip(err.message);
    }
  }
  return { cards, warnings };
}

/** A tool's result as a card sees it: structured content, else the text as JSON, else the text. */
export function cardResult(structured: unknown, text: string): unknown {
  if (structured !== undefined && structured !== null) return structured;
  const t = text.trim();
  if (t.startsWith("{") || t.startsWith("[")) {
    try {
      return JSON.parse(t);
    } catch {}
  }
  return text;
}

interface Scope {
  result: unknown;
  item?: unknown;
  index?: number;
}

function lookup(path: string, scope: Scope): unknown {
  const p = path.trim();
  if (p === "index") return scope.index;
  const parts = p.match(/[^.[\]]+/g) ?? [];
  let v: unknown = parts[0] === "item" ? scope.item : scope.result;
  for (const k of parts.slice(1)) {
    if (Array.isArray(v) && /^\d+$/.test(k)) v = v[Number(k)];
    else if (isObj(v) && Object.hasOwn(v, k)) v = v[k];
    else return undefined;
  }
  return v;
}

const hasValue = (v: unknown) =>
  v !== undefined &&
  v !== null &&
  v !== false &&
  v !== "" &&
  !(Array.isArray(v) && !v.length) &&
  !(isObj(v) && !Object.keys(v).length);

const cut = (s: string) => (s.length > CARD_TEXT_MAX ? `${s.slice(0, CARD_TEXT_MAX - 1)}…` : s);

function asText(v: unknown): string {
  if (v === undefined || v === null) return "";
  if (typeof v === "string") return v;
  if (typeof v === "number" || typeof v === "boolean") return String(v);
  if (Array.isArray(v) && v.every((x) => ["string", "number", "boolean"].includes(typeof x)))
    return v.join(", ");
  return JSON.stringify(v);
}

const SKIP = Symbol("skip");

function fill(v: unknown, scope: Scope): unknown {
  if (typeof v === "string") {
    const exact = /^\{\{([^{}]*)\}\}$/.exec(v);
    if (exact) {
      const got = lookup(exact[1] as string, scope);
      if (got === undefined || got === null) return SKIP;
      return typeof got === "string" ? cut(got) : got;
    }
    if (!BINDING.test(v)) return v;
    return cut(v.replace(/\{\{([^{}]*)\}\}/g, (_, p: string) => asText(lookup(p, scope))));
  }
  if (Array.isArray(v)) {
    const out: unknown[] = [];
    for (const x of v) {
      if (isObj(x) && typeof x.each === "string") {
        const list = lookup(x.each, scope);
        if (!Array.isArray(list)) continue;
        const { each: _e, max, ...row } = x;
        const n = typeof max === "number" ? max : CARD_EACH_DEFAULT;
        list.slice(0, n).forEach((item, index) => {
          const f = fill(row, { result: scope.result, item, index });
          if (f !== SKIP) out.push(f);
        });
        continue;
      }
      const f = fill(x, scope);
      if (f !== SKIP) out.push(f);
    }
    return out;
  }
  if (isObj(v)) {
    const out: Record<string, unknown> = {};
    for (const [k, x] of Object.entries(v)) {
      const f = fill(x, scope);
      if (f !== SKIP) out[k] = f;
    }
    return out;
  }
  return v;
}

/**
 * Fills a card from a tool's result and checks it the way `ui.show` checks a bot's UI. Null when
 * `when` has no value in the result; throws UiCheckError when the filled card doesn't pass. Either
 * way the result stays text.
 */
export function fillCard(card: PluginCard, result: unknown): Array<Record<string, unknown>> | null {
  const scope: Scope = { result };
  if (card.when && !hasValue(lookup(card.when, scope))) return null;
  const out = fill(card.components, scope) as Array<Record<string, unknown>>;
  if (JSON.stringify(out).length > CARD_MAX_BYTES)
    throw new UiCheckError("The filled card is too big.");
  checkComponents(out);
  return out;
}
