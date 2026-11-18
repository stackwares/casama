// SPDX-License-Identifier: Apache-2.0
// A shared format, also used by the Apache-2.0 SDKs and tools (LICENSING.md).
/**
 * The A2UI catalog the apps render (D-086): the basic catalog plus Casama's own cards (D-310,
 * D-335, D-337), and the checks a UI passes before it reaches the app. `ui.show` uses them for
 * what a bot shows, and plugin cards (D-345) for a plugin's card files and their filled cards.
 */

/** Why a UI or card was refused, in words a bot or a plugin's author can act on. */
export class UiCheckError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "UiCheckError";
  }
}

/** The A2UI v1.0 basic catalog the apps render (D-086). */
export const A2UI_BASIC_CATALOG = "https://a2ui.org/specification/v1_0/catalogs/basic/catalog.json";

export const UI_COMPONENTS = [
  "Text",
  "Row",
  "Column",
  "List",
  "Card",
  "Tabs",
  "Divider",
  "Button",
  "TextField",
  "CheckBox",
  "ChoicePicker",
  "Slider",
  "DateTimeInput",
  "Image",
  "Icon",
  "Video",
  "AudioPlayer",
  // Casama's own additions to the basic catalog (D-310, D-335); apps from before them leave them out.
  "Map",
  "MessageDraft",
  // D-337: cards for what bots read and do most.
  "Event",
  "Agenda",
  "MessageList",
  "Checklist",
  "Stats",
  "Results",
  "PersonPicker",
  "Schedule",
  "Details",
] as const;

/**
 * A2UI v1.0 binds data with "@path" and calls functions with "@call"; models often write "path"
 * and "call" (the v0.9 forms). Fix them up.
 */
export function normalizeBindings(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(normalizeBindings);
  if (!value || typeof value !== "object") return value;
  const obj = value as Record<string, unknown>;
  const keys = Object.keys(obj);
  if (keys.length === 1 && keys[0] === "path" && typeof obj.path === "string")
    return { "@path": obj.path };
  if (
    typeof obj.call === "string" &&
    keys.every((k) => k === "call" || k === "args" || k === "returnType")
  ) {
    const { call, args } = obj;
    return { "@call": call, ...(args === undefined ? {} : { args: normalizeBindings(args) }) };
  }
  return Object.fromEntries(Object.entries(obj).map(([k, v]) => [k, normalizeBindings(v)]));
}

/** The basic catalog's functions a check's condition may call, and the arguments each needs. */
const CHECK_FUNCTIONS: Record<string, string[]> = {
  required: ["value"],
  email: ["value"],
  length: ["value"],
  numeric: ["value"],
  regex: ["value", "pattern"],
  and: ["values"],
  or: ["values"],
  not: ["value"],
};

/** A check's condition: a bound boolean, or a call to one of [CHECK_FUNCTIONS], nested or not. */
function checkCondition(cond: unknown, where: string) {
  const c = (cond ?? {}) as Record<string, unknown>;
  if (typeof c["@path"] === "string") return;
  const name = c["@call"];
  const fix = `Use {"@call": "required", "args": {"value": {"@path": "/form/x"}}}; the functions are ${Object.keys(CHECK_FUNCTIONS).join(", ")}.`;
  if (typeof name !== "string" || !(name in CHECK_FUNCTIONS))
    throw new UiCheckError(`${where}: the condition isn't one a check can use. ${fix}`);
  const args = (c.args ?? {}) as Record<string, unknown>;
  for (const a of CHECK_FUNCTIONS[name] ?? [])
    if (args[a] === undefined) throw new UiCheckError(`${where}: ${name} needs args.${a}. ${fix}`);
  if ((name === "length" || name === "numeric") && args.min === undefined && args.max === undefined)
    throw new UiCheckError(`${where}: ${name} needs args.min or args.max.`);
  if (name === "and" || name === "or") {
    const values = args.values;
    if (!Array.isArray(values) || values.length < 2)
      throw new UiCheckError(`${where}: ${name} needs args.values with 2 or more conditions.`);
    values.forEach((v, i) => {
      checkCondition(v, `${where}, ${name} value ${i + 1}`);
    });
  }
  if (name === "not") checkCondition(args.value, `${where}, not`);
}

/** Checks a component's `checks`: a list of {condition, message?}. */
function checkChecks(c: Record<string, unknown>) {
  if (c.checks === undefined) return;
  if (!Array.isArray(c.checks))
    throw new UiCheckError(`Component "${c.id}": checks must be a list of {condition, message}.`);
  c.checks.forEach((check, i) => {
    const where = `Component "${c.id}", check ${i + 1}`;
    const { condition, message } = (check ?? {}) as { condition?: unknown; message?: unknown };
    if (message !== undefined && typeof message !== "string")
      throw new UiCheckError(`${where}: message must be text.`);
    checkCondition(condition, where);
  });
}

/** Video and AudioPlayer play a media file the app loads itself, so the url must be http(s). */
function checkMedia(c: Record<string, unknown>, t = false) {
  const url = c.url;
  if (t && bound(url)) return;
  if (
    typeof url === "object" &&
    url !== null &&
    typeof (url as Record<string, unknown>)["@path"] === "string"
  )
    return;
  if (typeof url !== "string" || !/^https?:\/\/\S+$/i.test(url))
    throw new UiCheckError(
      `${c.component} "${c.id}" needs a url: an https link to the media file itself.`,
    );
}

/**
 * `template`: the list is a plugin's card file (D-345), so a string holding a `{{…}}` binding
 * stands for whatever the tool's result fills in and passes any field's check, and a list's
 * `{"each": …}` row counts as one row. The filled card is checked again without it.
 */
export interface CheckOptions {
  template?: boolean;
}

/** A `{{…}}` binding in a card file's string (D-345). */
export const BINDING = /\{\{[^{}]*\}\}/;
const bound = (v: unknown) => typeof v === "string" && BINDING.test(v);
const anyBound = (v: unknown) => v !== undefined && BINDING.test(JSON.stringify(v));

/** Wraps a flat component list in the A2UI messages for one new surface. */
export function surfaceMessages(
  surfaceId: string,
  components: Array<Record<string, unknown>>,
  data?: Record<string, unknown>,
) {
  return [
    { version: "1.0", createSurface: { surfaceId, catalogId: A2UI_BASIC_CATALOG } },
    ...(data ? [{ version: "1.0", updateDataModel: { surfaceId, path: "/", value: data } }] : []),
    { version: "1.0", updateComponents: { surfaceId, components } },
  ];
}
/** Checks the tree before it reaches the app: a root, unique ids, and child references that exist. */
export function checkComponents(
  components: Array<Record<string, unknown>>,
  opts: CheckOptions = {},
) {
  const t = opts.template === true;
  const ids = new Set<string>();
  for (const c of components) {
    if (t) {
      if (!c || typeof c !== "object" || typeof c.id !== "string" || !c.id)
        throw new UiCheckError("Each component needs an id.");
      if (!(UI_COMPONENTS as readonly string[]).includes(String(c.component)))
        throw new UiCheckError(
          `Component "${c.id}": "${String(c.component)}" isn't in Casama's catalog (${UI_COMPONENTS.join(", ")}).`,
        );
    }
    const id = String(c.id);
    if (ids.has(id)) throw new UiCheckError(`Two components have the id "${id}".`);
    ids.add(id);
  }
  if (!ids.has("root")) throw new UiCheckError('One component must have the id "root".');
  for (const c of components) {
    const refs = [
      ...(typeof c.child === "string" ? [c.child] : []),
      ...(Array.isArray(c.children)
        ? c.children.filter((x): x is string => typeof x === "string")
        : []),
      ...(Array.isArray(c.tabs)
        ? c.tabs
            .map((t) => (t as { child?: unknown })?.child)
            .filter((x): x is string => typeof x === "string")
        : []),
    ];
    if (c.component === "Map") checkMap(c, t);
    if (c.component === "MessageDraft") checkDraft(c);
    checkCard(c, t);
    checkReservedEvent(c);
    if (c.component === "Video" || c.component === "AudioPlayer") checkMedia(c, t);
    checkChecks(c);
    for (const r of refs) {
      if (!ids.has(r))
        throw new UiCheckError(`Component "${c.id}" refers to "${r}", which isn't in the list.`);
    }
  }
}

/** A MessageDraft needs the message, and recipients as text. */
function checkDraft(c: Record<string, unknown>) {
  if (typeof c.body !== "string" || !c.body.trim())
    throw new UiCheckError(`MessageDraft "${c.id}" needs a body: the message itself.`);
  if (c.kind !== undefined && !["email", "message", "post"].includes(String(c.kind)))
    throw new UiCheckError(`MessageDraft "${c.id}": kind is "email", "message" or "post".`);
  for (const k of ["to", "cc", "bcc"]) {
    const v = c[k];
    if (v === undefined || typeof v === "string") continue;
    if (!Array.isArray(v) || v.some((x) => typeof x !== "string"))
      throw new UiCheckError(`MessageDraft "${c.id}": ${k} is a list of addresses or names.`);
  }
  for (const k of ["from", "subject", "title", "status", "app", "sendLabel"])
    if (c[k] !== undefined && typeof c[k] !== "string")
      throw new UiCheckError(`MessageDraft "${c.id}": ${k} must be text.`);
  if (c.action !== undefined || c.child !== undefined || c.children !== undefined)
    throw new UiCheckError(
      `MessageDraft "${c.id}" has its own buttons; give it no action or children.`,
    );
}

/** Events Casama's own cards send from their own buttons, by prefix. */
const CARD_EVENTS: Record<string, string> = {
  "draft.": "MessageDraft",
  "event.": "Event",
  "message.": "MessageList",
  "checklist.": "Checklist",
  "result.": "Results",
  "person.": "PersonPicker",
  "schedule.": "Schedule",
};

/**
 * Casama's cards send their events from their own buttons: a draft.send or event.add lets the
 * matching call through without asking again (D-335, D-337), so no other button may send one.
 */
function checkReservedEvent(c: Record<string, unknown>) {
  const name = (c.action as { event?: { name?: unknown } } | undefined)?.event?.name;
  if (typeof name !== "string") return;
  const prefix = Object.keys(CARD_EVENTS).find((p) => name.startsWith(p));
  if (prefix)
    throw new UiCheckError(
      `Component "${c.id}": "${prefix}" events belong to ${CARD_EVENTS[prefix]}. Show it as a ${CARD_EVENTS[prefix]} instead.`,
    );
}

type Field = "text" | "texts" | "number" | "bool" | "time";

/** Each card's fields: required ones end in "!", lists of rows name their rows' fields. */
const CARDS: Record<
  string,
  { fields: Record<string, Field>; rows?: [string, Record<string, Field>, number] }
> = {
  Event: {
    fields: {
      "title!": "text",
      "start!": "time",
      end: "time",
      allDay: "bool",
      location: "text",
      attendees: "texts",
      description: "text",
      app: "text",
      actions: "bool",
    },
  },
  Agenda: {
    fields: { title: "text", date: "text" },
    rows: [
      "events",
      { "title!": "text", "start!": "time", end: "time", allDay: "bool", location: "text" },
      40,
    ],
  },
  MessageList: {
    fields: { title: "text", app: "text", reply: "bool" },
    rows: [
      "messages",
      {
        "id!": "text",
        "from!": "text",
        subject: "text",
        preview: "text",
        time: "time",
        unread: "bool",
      },
      25,
    ],
  },
  Checklist: {
    fields: { title: "text" },
    rows: [
      "items",
      { "id!": "text", "text!": "text", done: "bool", due: "time", detail: "text" },
      40,
    ],
  },
  Stats: { fields: { title: "text" } },
  Results: {
    fields: { title: "text", layout: "text", choose: "bool" },
    rows: [
      "items",
      {
        id: "text",
        "title!": "text",
        subtitle: "text",
        imageUrl: "text",
        rating: "number",
        reviews: "number",
        price: "text",
        url: "text",
        badge: "text",
      },
      20,
    ],
  },
  PersonPicker: {
    fields: { label: "text", multiple: "bool" },
    rows: ["people", { id: "text", "name!": "text", detail: "text", avatarUrl: "text" }, 12],
  },
  Schedule: {
    fields: {
      kind: "text",
      "title!": "text",
      "when!": "text",
      next: "time",
      detail: "text",
      ref: "text",
    },
  },
  Details: {
    fields: { title: "text", footer: "text" },
    rows: ["rows", { "label!": "text", "value!": "text" }, 30],
  },
};

const ISO_TIME = /^\d{4}-\d{2}-\d{2}([T ]\d{2}:\d{2}(:\d{2}(\.\d+)?)?(Z|[+-]\d{2}:?\d{2})?)?$/;

function checkFields(
  where: string,
  obj: Record<string, unknown>,
  fields: Record<string, Field>,
  t = false,
) {
  for (const [raw, kind] of Object.entries(fields)) {
    const key = raw.replace("!", "");
    const v = obj[key];
    if (v === undefined || v === null) {
      if (raw.endsWith("!")) throw new UiCheckError(`${where} needs ${key}.`);
      continue;
    }
    if (t && (bound(v) || (kind === "texts" && Array.isArray(v) && anyBound(v)))) continue;
    const ok =
      kind === "text"
        ? typeof v === "string" || typeof v === "number"
        : kind === "texts"
          ? Array.isArray(v) && v.every((x) => typeof x === "string")
          : kind === "number"
            ? typeof v === "number" && Number.isFinite(v)
            : kind === "bool"
              ? typeof v === "boolean"
              : typeof v === "string" && ISO_TIME.test(v.trim());
    if (!ok)
      throw new UiCheckError(
        `${where}: ${key} must be ${
          {
            text: "text",
            texts: "a list of text",
            number: "a number",
            bool: "true or false",
            time: 'an ISO time like "2026-11-20T14:00"',
          }[kind]
        }.`,
      );
  }
}

/** Casama's cards (D-337): their fields, rows and buttons. */
function checkCard(c: Record<string, unknown>, t = false) {
  const spec = CARDS[String(c.component)];
  if (!spec) return;
  const where = `${c.component} "${c.id}"`;
  if (c.action !== undefined || c.child !== undefined || c.children !== undefined)
    throw new UiCheckError(`${where} has its own buttons; give it no action or children.`);
  checkFields(where, c, spec.fields, t);
  if (spec.rows) {
    const [key, fields, max] = spec.rows;
    const rows = c[key];
    if (t && bound(rows)) return;
    if (!Array.isArray(rows) || !rows.length)
      throw new UiCheckError(`${where} needs ${key}: a list of 1 to ${max}.`);
    if (rows.length > max) throw new UiCheckError(`${where}: at most ${max} ${key}.`);
    rows.forEach((r, i) => {
      if (!r || typeof r !== "object")
        throw new UiCheckError(`${where}: ${key} ${i + 1} must be an object.`);
      checkFields(`${where}, ${key} ${i + 1}`, r as Record<string, unknown>, fields, t);
    });
  }
  if (c.component === "Stats") checkStats(c, where, t);
}

function checkStats(c: Record<string, unknown>, where: string, t = false) {
  const stats = c.stats;
  const chart = c.chart as Record<string, unknown> | undefined;
  if (stats === undefined && chart === undefined)
    throw new UiCheckError(`${where} needs stats, a chart or both.`);
  if (t && (anyBound(stats) || anyBound(chart))) return;
  if (stats !== undefined) {
    if (!Array.isArray(stats) || stats.length > 8)
      throw new UiCheckError(`${where}: stats is a list of up to 8.`);
    for (const [i, s] of stats.entries())
      checkFields(`${where}, stat ${i + 1}`, (s ?? {}) as Record<string, unknown>, {
        "label!": "text",
        "value!": "text",
        unit: "text",
        change: "text",
        trend: "text",
        good: "text",
      });
  }
  if (chart !== undefined) {
    if (!chart || typeof chart !== "object")
      throw new UiCheckError(`${where}: chart must be an object.`);
    const labels = chart.labels;
    const series = chart.series;
    if (!Array.isArray(labels) || labels.length < 2 || labels.length > 60)
      throw new UiCheckError(`${where}: chart.labels is a list of 2 to 60.`);
    if (!Array.isArray(series) || !series.length || series.length > 4)
      throw new UiCheckError(`${where}: chart.series is a list of 1 to 4.`);
    for (const [i, s] of series.entries()) {
      const values = (s as { values?: unknown })?.values;
      if (
        !Array.isArray(values) ||
        values.length !== labels.length ||
        values.some((v) => typeof v !== "number" || !Number.isFinite(v))
      )
        throw new UiCheckError(
          `${where}: chart series ${i + 1} needs values: one number per label.`,
        );
    }
  }
}

/** A Map needs real coordinates: a place to center on, or markers or a path to fit. */
function checkMap(c: Record<string, unknown>, t = false) {
  if (t && (anyBound(c.center) || anyBound(c.markers) || anyBound(c.path))) return;
  const point = (p: unknown, what: string) => {
    const { lat, lng } = (p ?? {}) as { lat?: unknown; lng?: unknown };
    if (
      typeof lat !== "number" ||
      typeof lng !== "number" ||
      Math.abs(lat) > 90 ||
      Math.abs(lng) > 180
    )
      throw new UiCheckError(
        `Map "${c.id}": ${what} needs {lat, lng} as numbers in decimal degrees.`,
      );
  };
  const markers = Array.isArray(c.markers) ? c.markers : [];
  const path = Array.isArray(c.path) ? c.path : [];
  if (c.center != null) point(c.center, "center");
  for (const [i, m] of markers.entries()) point(m, `marker ${i + 1}`);
  for (const [i, p] of path.entries()) point(p, `path point ${i + 1}`);
  if (c.center == null && !markers.length && !path.length)
    throw new UiCheckError(`Map "${c.id}" needs a center, markers or a path.`);
}

const INPUTS = new Set(["TextField", "CheckBox", "ChoicePicker", "Slider", "DateTimeInput"]);

/**
 * A UI with inputs but no button can't be answered: picking changes only the card. Models leave
 * the button out now and then, so add a Send button whose context carries every bound input.
 */
export function ensureSubmit(components: Array<Record<string, unknown>>) {
  const inputs = components.filter((c) => INPUTS.has(String(c.component)));
  if (!inputs.length || components.some((c) => c.component === "Button" && c.action))
    return components;
  const context: Record<string, unknown> = {};
  for (const c of inputs) {
    const path = (c.value as { "@path"?: unknown } | undefined)?.["@path"];
    if (typeof path !== "string") continue;
    const key = path.split("/").filter(Boolean).pop() ?? String(c.id);
    context[key in context ? String(c.id) : key] = { "@path": path };
  }
  if (!Object.keys(context).length) return components;
  // Any checks on the inputs go on the added button too, so it stays off until they pass.
  const checks = inputs.flatMap((c) => (Array.isArray(c.checks) ? c.checks : []));
  const ids = new Set(components.map((c) => String(c.id)));
  const fresh = (base: string) => {
    let id = base;
    for (let n = 2; ids.has(id); n++) id = `${base}_${n}`;
    ids.add(id);
    return id;
  };
  const send = fresh("send");
  const label = fresh("send_text");
  const added: Array<Record<string, unknown>> = [
    {
      id: send,
      component: "Button",
      child: label,
      variant: "primary",
      action: { event: { name: "submit", context } },
      ...(checks.length ? { checks } : {}),
    },
    { id: label, component: "Text", text: "Send" },
  ];
  const root = components.find((c) => c.id === "root") as Record<string, unknown>;
  const children = root.children;
  if (root.component === "Column" && Array.isArray(children))
    return [
      ...components.map((c) => (c === root ? { ...root, children: [...children, send] } : c)),
      ...added,
    ];
  // Any other root goes under a new column with the button below it.
  const body = fresh("root_body");
  return [
    { id: "root", component: "Column", children: [body, send] },
    ...components.map((c) => (c === root ? { ...root, id: body } : c)),
    ...added,
  ];
}

/**
 * A card whose only button is "Go" leaves the person no way to say no but typing. When a UI has
 * exactly one button with an action, add a borderless Skip beside it; its "skip" event reaches
 * the bot as the person's answer, like any other button.
 */
export function ensureWayOut(components: Array<Record<string, unknown>>) {
  const buttons = components.filter((c) => c.component === "Button" && c.action);
  const only = buttons.length === 1 ? buttons[0] : undefined;
  if (!only) return components;
  const onlyId = String(only.id);
  const parent = components.find(
    (c) => Array.isArray(c.children) && (c.children as unknown[]).includes(onlyId),
  );
  if (!parent) return components; // A lone button as the root, or under a Card: leave it be.
  const ids = new Set(components.map((c) => String(c.id)));
  const fresh = (base: string) => {
    let id = base;
    for (let n = 2; ids.has(id); n++) id = `${base}_${n}`;
    ids.add(id);
    return id;
  };
  const skip = fresh("skip");
  const label = fresh("skip_text");
  const added = [
    {
      id: skip,
      component: "Button",
      child: label,
      variant: "borderless",
      action: { event: { name: "skip" } },
    },
    { id: label, component: "Text", text: "Skip" },
  ];
  const children = parent.children as string[];
  // Already in a row: Skip goes after it. In a column: the button and Skip share a new row.
  if (parent.component === "Row") {
    const at = children.indexOf(onlyId);
    const next = [...children.slice(0, at + 1), skip, ...children.slice(at + 1)];
    return [...components.map((c) => (c === parent ? { ...c, children: next } : c)), ...added];
  }
  const row = fresh("actions");
  return [
    ...components.map((c) =>
      c === parent ? { ...c, children: children.map((x) => (x === onlyId ? row : x)) } : c,
    ),
    { id: row, component: "Row", children: [onlyId, skip] },
    ...added,
  ];
}
