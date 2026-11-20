// SPDX-License-Identifier: Apache-2.0
// A shared format, also used by the Apache-2.0 SDKs and tools (LICENSING.md).
/**
 * Live data cards and composed cards (docs/RICH-CARDS-PLAN.md). Data cards (weather, prices,
 * rates, hazards, travel, scores) are filled by the server from a named provider and carry a
 * `live` block with that provider and the time; a bot can't show one with `ui.show`, so a card
 * never holds a number the model typed (decision 8). Composed cards (a recipe, a comparison, a
 * calculator…) are what a bot writes itself and say where their content came from.
 */
import { UiCheckError } from "./ui-check-error.ts";

/** Cards only the server fills from a data tool (or a plugin's tool result, D-345). */
export const DATA_CARDS = [
  "Weather",
  "Forecast",
  "WeatherAlert",
  "AirQuality",
  "SunMoon",
  "Quote",
  "Watchlist",
  "Currency",
  "Holidays",
  "Quake",
  "Storm",
  "Flight",
  "Parcel",
  "Score",
  "Standings",
] as const;

/** Cards a bot may show itself with `ui.show`. */
export const COMPOSED_CARDS = [
  "WorldClock",
  "Countdown",
  "Summary",
  "Definition",
  "Media",
  "Recipe",
  "Comparison",
  "ProsCons",
  "Steps",
  "Timeline",
  "Calculator",
  "Random",
  "Translation",
  "Contact",
  "Quiz",
  "Nutrition",
  "Status",
] as const;

/** Containers that lay other cards out: a grid and a row you swipe. */
export const CARD_CONTAINERS = ["Dashboard", "Carousel"] as const;

export const LIVE_COMPONENTS = [...DATA_CARDS, ...COMPOSED_CARDS, ...CARD_CONTAINERS] as const;

export type DataCard = (typeof DATA_CARDS)[number];
export type ComposedCard = (typeof COMPOSED_CARDS)[number];

/** Where a data card's numbers came from and when: shown in its footer. */
export interface LiveBlock {
  /** The `live_cards` row the app refreshes; absent on snapshots and plugin cards. */
  ref?: string;
  source: { id?: string; name: string; url?: string; license?: string };
  fetchedAt: string;
  /** When the card should be fetched again if it's on screen. */
  staleAfter?: string;
  /** Minutes a quote lags the market, when it does. */
  delayed?: number | null;
  /** Other views the app may ask for (`/v1/live-cards/:id/view`). */
  views?: string[];
}

/** Where a composed card's content came from. */
export interface Provenance {
  kind: "web" | "bot" | "plugin";
  name?: string;
  url?: string;
}

type Field = "text" | "texts" | "number" | "bool" | "time" | "index";
type Rows = [key: string, fields: Record<string, Field>, max: number, required?: boolean];
interface Spec {
  fields: Record<string, Field>;
  rows?: Rows[];
  /** Lists of text with their size limits. */
  lists?: Array<[key: string, min: number, max: number]>;
  /** Allowed values for some text fields. */
  enums?: Record<string, readonly string[]>;
}

const ISO_TIME = /^\d{4}-\d{2}-\d{2}([T ]\d{2}:\d{2}(:\d{2}(\.\d+)?)?(Z|[+-]\d{2}:?\d{2})?)?$/;
const TZ = /^[A-Za-z_]+(\/[A-Za-z0-9_+-]+){0,2}$|^UTC$/;

const SPECS: Record<ComposedCard, Spec> = {
  WorldClock: {
    fields: { title: "text", at: "time" },
    rows: [["places", { "name!": "text", "tz!": "text", country: "text" }, 8, true]],
  },
  Countdown: {
    fields: { "title!": "text", "target!": "time", start: "time", art: "text", tz: "text" },
    enums: {
      art: [
        "new_year",
        "birthday",
        "launch",
        "holiday",
        "trip",
        "wedding",
        "exam",
        "game",
        "event",
      ],
    },
  },
  Summary: {
    fields: { "title!": "text", subtitle: "text", imageUrl: "text", "text!": "text", url: "text" },
    rows: [["facts", { "label!": "text", "value!": "text" }, 12]],
  },
  Definition: {
    fields: { "word!": "text", phonetic: "text", audioUrl: "text", lang: "text" },
    rows: [["senses", { pos: "text", "meaning!": "text", example: "text" }, 10, true]],
    lists: [["synonyms", 0, 12]],
  },
  Media: {
    fields: {
      "kind!": "text",
      "title!": "text",
      subtitle: "text",
      imageUrl: "text",
      year: "text",
      rating: "number",
      ratingMax: "number",
      text: "text",
      url: "text",
    },
    rows: [
      ["facts", { "label!": "text", "value!": "text" }, 10],
      ["links", { "label!": "text", "url!": "text" }, 6],
    ],
    enums: { kind: ["book", "movie", "show", "song", "album", "game", "podcast", "app"] },
  },
  Recipe: {
    fields: {
      "title!": "text",
      imageUrl: "text",
      time: "text",
      servings: "number",
      calories: "number",
      url: "text",
    },
    rows: [["ingredients", { "text!": "text", qty: "number", unit: "text" }, 60, true]],
    lists: [["steps", 1, 40]],
  },
  Comparison: {
    fields: { title: "text" },
    lists: [["items", 2, 4]],
    rows: [["rows", { "label!": "text", "values!": "texts", best: "index" }, 20, true]],
  },
  ProsCons: {
    fields: { title: "text", verdict: "text" },
    lists: [
      ["pros", 1, 10],
      ["cons", 1, 10],
    ],
  },
  Steps: {
    fields: { title: "text" },
    rows: [["steps", { "title!": "text", detail: "text", imageUrl: "text" }, 20, true]],
  },
  Timeline: {
    fields: { title: "text" },
    rows: [
      ["events", { "when!": "text", "title!": "text", detail: "text", icon: "text" }, 30, true],
    ],
  },
  Calculator: {
    fields: { "kind!": "text", title: "text", currency: "text" },
    enums: { kind: ["loan", "savings", "tip", "percent", "vat", "unit"] },
  },
  Random: {
    fields: {
      "kind!": "text",
      title: "text",
      sides: "number",
      count: "number",
      min: "number",
      max: "number",
    },
    lists: [["options", 0, 30]],
    enums: { kind: ["dice", "coin", "number", "pick"] },
  },
  Translation: {
    fields: {
      "from!": "text",
      "to!": "text",
      "source!": "text",
      "translated!": "text",
      romanized: "text",
      note: "text",
    },
  },
  Contact: {
    fields: {
      "name!": "text",
      title: "text",
      company: "text",
      address: "text",
      avatarUrl: "text",
      url: "text",
    },
    lists: [
      ["phones", 0, 6],
      ["emails", 0, 6],
    ],
  },
  Quiz: {
    fields: { "question!": "text", answer: "index", explanation: "text", title: "text" },
    lists: [["options", 2, 6]],
  },
  Nutrition: {
    fields: { "title!": "text", serving: "text", "calories!": "number" },
    rows: [["rows", { "label!": "text", "value!": "text", daily: "number" }, 20]],
  },
  Status: {
    fields: {
      "title!": "text",
      kind: "text",
      "state!": "text",
      ref: "text",
      url: "text",
      subtitle: "text",
      app: "text",
    },
    // "jobs", not "checks": every A2UI component's `checks` are its input checks (D-322).
    rows: [
      ["jobs", { "name!": "text", "state!": "text", detail: "text" }, 30],
      ["stats", { "label!": "text", "value!": "text" }, 8],
    ],
    enums: { kind: ["pr", "issue", "ci", "deploy", "task", "service", "order", "other"] },
  },
};

/** Values of a card's `state` field the apps color: anything else shows neutral. */
export const STATUS_STATES = [
  "open",
  "merged",
  "closed",
  "draft",
  "passed",
  "failed",
  "running",
  "queued",
  "cancelled",
  "done",
  "blocked",
  "up",
  "down",
  "degraded",
] as const;

const BOUND = /\{\{[^{}]*\}\}/;
const bound = (v: unknown) => typeof v === "string" && BOUND.test(v);

function fieldOk(kind: Field, v: unknown) {
  switch (kind) {
    case "text":
      return typeof v === "string" || typeof v === "number";
    case "texts":
      return Array.isArray(v) && v.every((x) => typeof x === "string" || typeof x === "number");
    case "number":
    case "index":
      return typeof v === "number" && Number.isFinite(v) && (kind === "number" || v >= 0);
    case "bool":
      return typeof v === "boolean";
    case "time":
      return typeof v === "string" && ISO_TIME.test(v.trim());
  }
}

const KIND_WORDS: Record<Field, string> = {
  text: "text",
  texts: "a list of text",
  number: "a number",
  index: "a position in the list, from 0",
  bool: "true or false",
  time: 'an ISO time like "2026-11-20T14:00"',
};

function checkFields(
  where: string,
  obj: Record<string, unknown>,
  fields: Record<string, Field>,
  t: boolean,
) {
  for (const [raw, kind] of Object.entries(fields)) {
    const key = raw.replace("!", "");
    const v = obj[key];
    if (v === undefined || v === null) {
      if (raw.endsWith("!")) throw new UiCheckError(`${where} needs ${key}.`);
      continue;
    }
    if (t && (bound(v) || JSON.stringify(v).match(BOUND))) continue;
    if (!fieldOk(kind, v)) throw new UiCheckError(`${where}: ${key} must be ${KIND_WORDS[kind]}.`);
  }
}

function checkUrl(where: string, key: string, v: unknown) {
  if (v === undefined || v === null || bound(v)) return;
  if (typeof v !== "string" || !/^https:\/\/\S+$/i.test(v))
    throw new UiCheckError(`${where}: ${key} must be an https link.`);
}

/**
 * Checks one of the cards in this file. `fromBot`: the component came from `ui.show`, which may
 * not show data cards. `template`: a plugin's card file (D-345).
 */
export function checkLiveCard(
  c: Record<string, unknown>,
  opts: { template?: boolean; fromBot?: boolean } = {},
) {
  const name = String(c.component);
  const where = `${name} "${String(c.id)}"`;
  const t = opts.template === true;
  if ((DATA_CARDS as readonly string[]).includes(name)) {
    if (opts.fromBot)
      throw new UiCheckError(
        `${where}: ${name} cards are filled from live data by Casama's tools (live.*), never by hand. Call the matching live tool instead, which shows the card for you.`,
      );
    if (c.action !== undefined || c.child !== undefined || c.children !== undefined)
      throw new UiCheckError(`${where} has its own buttons; give it no action or children.`);
    return;
  }
  if ((CARD_CONTAINERS as readonly string[]).includes(name)) {
    const kids = c.children;
    if (!Array.isArray(kids) || kids.length < 1 || kids.length > 12)
      throw new UiCheckError(`${where} needs children: the ids of 1 to 12 cards.`);
    if (c.title !== undefined && typeof c.title !== "string")
      throw new UiCheckError(`${where}: title must be text.`);
    return;
  }
  const spec = SPECS[name as ComposedCard];
  if (!spec) return;
  if (c.action !== undefined || c.child !== undefined || c.children !== undefined)
    throw new UiCheckError(`${where} has its own buttons; give it no action or children.`);
  if (c.live !== undefined && opts.fromBot)
    throw new UiCheckError(`${where}: live is set by Casama's tools only; leave it out.`);
  checkFields(where, c, spec.fields, t);
  for (const [key, values] of Object.entries(spec.enums ?? {})) {
    const v = c[key];
    if (v === undefined || (t && bound(v))) continue;
    if (!values.includes(String(v)))
      throw new UiCheckError(`${where}: ${key} is one of ${values.join(", ")}.`);
  }
  for (const [key, min, max] of spec.lists ?? []) {
    const v = c[key];
    if (v === undefined) {
      if (min > 0) throw new UiCheckError(`${where} needs ${key}: a list of ${min} to ${max}.`);
      continue;
    }
    if (t && (bound(v) || (Array.isArray(v) && JSON.stringify(v).match(BOUND)))) continue;
    if (!Array.isArray(v) || v.length < min || v.length > max)
      throw new UiCheckError(`${where}: ${key} is a list of ${min} to ${max}.`);
    if (v.some((x) => typeof x !== "string" && typeof x !== "number"))
      throw new UiCheckError(`${where}: ${key} is a list of text.`);
  }
  for (const [key, fields, max, required] of spec.rows ?? []) {
    const rows = c[key];
    if (rows === undefined || rows === null) {
      if (required) throw new UiCheckError(`${where} needs ${key}: a list of 1 to ${max}.`);
      continue;
    }
    if (t && bound(rows)) continue;
    if (!Array.isArray(rows) || (required && !rows.length))
      throw new UiCheckError(`${where} needs ${key}: a list of 1 to ${max}.`);
    if (rows.length > max) throw new UiCheckError(`${where}: at most ${max} ${key}.`);
    rows.forEach((r, i) => {
      if (!r || typeof r !== "object" || Array.isArray(r))
        throw new UiCheckError(`${where}: ${key} ${i + 1} must be an object.`);
      // A plugin's `{"each": …}` row stands for every row it makes.
      if (t && "each" in (r as object)) return;
      checkFields(`${where}, ${key} ${i + 1}`, r as Record<string, unknown>, fields, t);
    });
  }
  for (const key of ["imageUrl", "avatarUrl", "audioUrl", "url"]) checkUrl(where, key, c[key]);
  // A Translation's `source` is the text it translates; every other card's names where it came from.
  for (const key of name === "Translation" ? [] : ["source"]) {
    const s = c[key];
    if (s === undefined || (t && bound(s))) continue;
    const { name: n, url } = (s ?? {}) as { name?: unknown; url?: unknown };
    if (typeof n !== "string" || !n.trim())
      throw new UiCheckError(`${where}: source is {name, url?}: where this came from.`);
    checkUrl(where, "source.url", url);
  }
  // Card-specific rules.
  if (name === "WorldClock")
    for (const p of (c.places as Array<Record<string, unknown>>) ?? [])
      if (!t && typeof p.tz === "string" && !TZ.test(p.tz))
        throw new UiCheckError(`${where}: tz "${p.tz}" isn't a time zone name like "Asia/Manila".`);
  if (name === "Comparison" && !t) {
    const n = (c.items as unknown[]).length;
    (c.rows as Array<{ values: unknown[]; best?: number }>).forEach((r, i) => {
      if (r.values.length !== n)
        throw new UiCheckError(`${where}, row ${i + 1}: values needs one per item (${n}).`);
      if (r.best !== undefined && r.best >= n)
        throw new UiCheckError(
          `${where}, row ${i + 1}: best is an item's position, 0 to ${n - 1}.`,
        );
    });
  }
  if (name === "Quiz" && !t && typeof c.answer === "number") {
    if (c.answer >= (c.options as unknown[]).length)
      throw new UiCheckError(`${where}: answer is the right option's position, from 0.`);
  }
  if (name === "Media" && !t && typeof c.rating === "number") {
    const max = typeof c.ratingMax === "number" ? c.ratingMax : 10;
    if (c.rating < 0 || c.rating > max)
      throw new UiCheckError(`${where}: rating is 0 to ${max} (ratingMax).`);
  }
}
