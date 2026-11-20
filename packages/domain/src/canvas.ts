/**
 * Bot widgets (docs/BOT-WIDGET-PLAN.md): the rules a canvas is held to, on every path.
 *
 * A canvas is what one bot keeps on the person's Canvas widget: a look and either a schedule of
 * up to 14 dated entries or a rotation, a list the canvas cycles through on a rhythm with no
 * further model runs. Everything here is pure: the limits, cutting the Lock Screen's short forms,
 * choosing the text colour for contrast, and working out from the clock which rotation item shows.
 */

export const CANVAS_TEMPLATES = ["text", "countdown", "number", "list", "picture"] as const;
export type CanvasTemplate = (typeof CANVAS_TEMPLATES)[number];
export const CANVAS_FONTS = ["plain", "serif", "rounded", "mono"] as const;
export type CanvasFont = (typeof CANVAS_FONTS)[number];

/** Built-in paintings a bot can ask for by name (§6.2), and whether text over them reads light. */
export const CANVAS_PAINTINGS = {
  sunrise: "dark",
  night_sky: "dark",
  ocean: "dark",
  forest: "dark",
  rain: "dark",
  meadow: "light",
  desert: "light",
  paper: "light",
} as const satisfies Record<string, Tone>;
export type CanvasPainting = keyof typeof CANVAS_PAINTINGS;
export const CANVAS_PAINTING_NAMES = Object.keys(CANVAS_PAINTINGS) as CanvasPainting[];

/** How dark a background is: text over a dark one is light, and the other way round. */
export type Tone = "light" | "dark";

/** §12.3. */
export const CANVAS_LIMITS = {
  perBot: 3,
  perPerson: 12,
  entries: 14,
  entryGapMs: 5 * 60_000,
  rotationItems: 400,
  itemsPerCall: 60,
  rotationPictures: 30,
  writesPerHour: 6,
  writesPerDay: 30,
  personWritesPerDay: 60,
  name: 40,
  title: 60,
  text: 280,
  footer: 40,
  short: 80,
  tiny: 24,
  listItems: 5,
  listRow: 60,
  unit: 16,
  icon: 32,
  pictureInBytes: 10 * 1024 * 1024,
  pictureSide: 1200,
  pictureOutBytes: 400 * 1024,
} as const;

export type CanvasBackground =
  | { kind: "auto" }
  | { kind: "color"; color: string }
  | { kind: "gradient"; from: string; to: string }
  | { kind: "picture"; picture: string; tone: Tone }
  | { kind: "painting"; name: CanvasPainting };

export interface CanvasLook {
  background: CanvasBackground;
  font: CanvasFont;
  align: "start" | "center";
  /** One emoji or an icon name from the app's set. */
  icon: string | null;
  /** #rrggbb for rings and bars; null for the bot's own. */
  accent: string | null;
}

export interface CanvasListItem {
  text: string;
  done: boolean;
}

/** One thing a canvas shows (§6.1). Fields a template doesn't use are absent. */
export interface CanvasEntryBody {
  template: CanvasTemplate;
  title?: string;
  text?: string;
  footer?: string;
  /** countdown: the moment counted to (ISO). */
  target?: string;
  count?: "down" | "up";
  /** number */
  value?: number;
  of?: number;
  unit?: string;
  /** list */
  items?: CanvasListItem[];
  /** picture: the stored picture's hash, and its tone. */
  picture?: { hash: string; tone: Tone };
  /** The Lock Screen rectangle's and watches' form, and the line above the clock's. */
  short: string;
  tiny: string;
  /** A per-entry change to the canvas's look (a rotation item's own colour). */
  look?: Partial<CanvasLook>;
}

export interface CanvasRhythm {
  /** "day", "week" or 1 to 23 hours. */
  every: "day" | "week" | number;
  /** "HH:MM" in the person's time zone, for days and weeks. */
  at: string;
  /** For weeks: 0 Sunday … 6 Saturday. */
  weekday?: number;
  order: "in_order" | "shuffle";
  at_end: "loop" | "stop";
}

/** What `widget_canvases.content` holds. */
export interface CanvasContent {
  look: CanvasLook;
  /** A schedule: the first shows from `at` null (now), the rest from their times. */
  entries?: Array<CanvasEntryBody & { at: string | null }>;
  rotation?: CanvasRhythm & {
    items: CanvasEntryBody[];
    /** When item 0 began showing. */
    started_at: string;
    /** The person's time zone when it was written. */
    tz: string;
  };
}

export class CanvasError extends Error {
  readonly code: string;
  constructor(code: string, message: string) {
    super(message);
    this.code = code;
  }
}

export const DEFAULT_LOOK: CanvasLook = {
  background: { kind: "auto" },
  font: "plain",
  align: "start",
  icon: null,
  accent: null,
};

// ------------------------------------------------------------------ text

const clean = (s: string) => s.replace(/\s+/g, " ").trim();

/** Cuts text to `max` characters at a word, with an ellipsis when anything went. */
export function cutAtWord(text: string, max: number): string {
  const t = clean(text);
  if (t.length <= max) return t;
  if (max <= 1) return "…".slice(0, max);
  const room = t.slice(0, max - 1);
  // The cut falls between words when the next character is a space.
  const atWord = /\s/.test(t[max - 1] ?? "") ? room : room.replace(/\s+\S*$/, "");
  const kept = atWord.length >= Math.floor((max - 1) / 2) ? atWord : room;
  return `${kept.replace(/[\s,;:.-]+$/, "")}…`;
}

/**
 * The short form of an entry when the bot gave none: its words cut at a word with the footer
 * kept ("Be still, and know that I am God. · Ps 46:10").
 */
export function makeShort(e: Partial<CanvasEntryBody>, max: number): string {
  const main = clean(
    e.template === "list"
      ? (e.items ?? [])
          .filter((i) => !i.done)
          .map((i) => i.text)
          .join(", ") ||
          (e.title ?? "")
      : e.template === "number"
        ? [e.value !== undefined ? fmtNumber(e.value, e.of) : "", e.unit, e.title]
            .filter(Boolean)
            .join(" ")
        : e.template === "countdown" || e.template === "picture"
          ? (e.text ?? e.title ?? "")
          : (e.text ?? e.title ?? ""),
  );
  const footer = clean(e.footer ?? "");
  if (!footer || e.template === "number" || e.template === "list") return cutAtWord(main, max);
  const whole = main ? `${main} · ${footer}` : footer;
  if (whole.length <= max) return whole;
  const room = max - footer.length - 3;
  if (room < 8) return cutAtWord(main || footer, max);
  return `${cutAtWord(main, room)} · ${footer}`;
}

const fmtNumber = (v: number, of?: number) => {
  const n = Number.isInteger(v) ? String(v) : String(Math.round(v * 100) / 100);
  return of !== undefined ? `${n}/${Number.isInteger(of) ? of : Math.round(of * 100) / 100}` : n;
};

// ------------------------------------------------------------------ colour

const HEX = /^#?([0-9a-f]{6})$/i;

/** "#AbC123" or "abc123" → "#abc123"; null when it isn't one. */
export function normalizeColor(c: string | undefined | null): string | null {
  const m = HEX.exec((c ?? "").trim());
  return m ? `#${(m[1] as string).toLowerCase()}` : null;
}

/** WCAG relative luminance of #rrggbb, 0 (black) to 1 (white). */
export function luminance(hex: string): number {
  const n = Number.parseInt(hex.replace("#", ""), 16);
  const ch = (v: number) => {
    const s = v / 255;
    return s <= 0.03928 ? s / 12.92 : ((s + 0.055) / 1.055) ** 2.4;
  };
  return 0.2126 * ch((n >> 16) & 255) + 0.7152 * ch((n >> 8) & 255) + 0.0722 * ch(n & 255);
}

/** The tone of a colour: whichever of white or black text has the better contrast on it. */
export function toneOf(hex: string): Tone {
  const l = luminance(hex);
  // Contrast with white: 1.05 / (l + 0.05); with black: (l + 0.05) / 0.05.
  return 1.05 / (l + 0.05) >= (l + 0.05) / 0.05 ? "dark" : "light";
}

/**
 * The text colour the server chooses (principle 4): "light" text on dark backgrounds, "dark" on
 * light ones, "auto" where the app's own colours decide (light and dark mode).
 */
export function inkFor(bg: CanvasBackground): "light" | "dark" | "auto" {
  switch (bg.kind) {
    case "auto":
      return "auto";
    case "color":
      return toneOf(bg.color) === "dark" ? "light" : "dark";
    case "gradient": {
      const l = (luminance(bg.from) + luminance(bg.to)) / 2;
      return 1.05 / (l + 0.05) >= (l + 0.05) / 0.05 ? "light" : "dark";
    }
    case "picture":
      // A soft shade goes behind text on a picture, so it leans light.
      return bg.tone === "light" ? "dark" : "light";
    case "painting":
      return CANVAS_PAINTINGS[bg.name] === "light" ? "dark" : "light";
  }
}

// ------------------------------------------------------------------ checking

export interface EntryInput {
  template?: string;
  title?: string | null;
  text?: string | null;
  footer?: string | null;
  target?: string | null;
  count?: "down" | "up" | null;
  value?: number | null;
  of?: number | null;
  unit?: string | null;
  items?: Array<{ text: string; done?: boolean } | string> | null;
  short?: string | null;
  tiny?: string | null;
}

/**
 * Checks one entry and fills in its short forms. Text over a limit is cut at a word, and `cut`
 * says what was cut, so the bot can be told; a missing required field throws.
 */
export function checkEntry(
  input: EntryInput,
  o: { picture?: { hash: string; tone: Tone }; where?: string } = {},
): { entry: CanvasEntryBody; cut: string[] } {
  const where = o.where ? `${o.where}: ` : "";
  const template = (input.template ?? "text") as CanvasTemplate;
  if (!(CANVAS_TEMPLATES as readonly string[]).includes(template))
    throw new CanvasError(
      "bad_template",
      `${where}template must be one of ${CANVAS_TEMPLATES.join(", ")}.`,
    );
  const cut: string[] = [];
  const field = (name: "title" | "text" | "footer" | "unit", max: number) => {
    const v = input[name];
    if (v === undefined || v === null) return undefined;
    const t = clean(String(v));
    if (!t) return undefined;
    if (t.length > max) {
      cut.push(`${where}${name} cut to ${max} characters`);
      return cutAtWord(t, max);
    }
    return t;
  };
  const L = CANVAS_LIMITS;
  const e: CanvasEntryBody = { template, short: "", tiny: "" };
  const title = field("title", L.title);
  const text = field("text", L.text);
  const footer = field("footer", L.footer);
  if (title) e.title = title;
  if (text) e.text = text;
  if (footer) e.footer = footer;
  switch (template) {
    case "text":
      if (!text && !title)
        throw new CanvasError("missing_field", `${where}a text canvas needs text (or a title).`);
      break;
    case "countdown": {
      const t = input.target ? Date.parse(input.target) : Number.NaN;
      if (Number.isNaN(t))
        throw new CanvasError(
          "missing_field",
          `${where}a countdown needs target, the moment it counts to (ISO 8601 with its offset).`,
        );
      e.target = new Date(t).toISOString();
      e.count = input.count === "up" ? "up" : "down";
      if (!title)
        throw new CanvasError("missing_field", `${where}a countdown needs a title ("Trip").`);
      break;
    }
    case "number": {
      if (typeof input.value !== "number" || !Number.isFinite(input.value))
        throw new CanvasError("missing_field", `${where}a number canvas needs value.`);
      e.value = input.value;
      if (typeof input.of === "number" && Number.isFinite(input.of) && input.of > 0)
        e.of = input.of;
      const unit = field("unit", L.unit);
      if (unit) e.unit = unit;
      break;
    }
    case "list": {
      const raw = (input.items ?? []).map((i) =>
        typeof i === "string" ? { text: i, done: false } : { text: i.text, done: !!i.done },
      );
      const items = raw
        .map((i) => ({ text: clean(i.text ?? ""), done: i.done }))
        .filter((i) => i.text);
      if (!items.length)
        throw new CanvasError("missing_field", `${where}a list needs items (up to 5).`);
      if (items.length > L.listItems) cut.push(`${where}only the first ${L.listItems} items kept`);
      e.items = items.slice(0, L.listItems).map((i) => {
        if (i.text.length > L.listRow) cut.push(`${where}a list row cut to ${L.listRow}`);
        return { text: cutAtWord(i.text, L.listRow), done: i.done };
      });
      break;
    }
    case "picture":
      if (!o.picture)
        throw new CanvasError(
          "missing_field",
          `${where}a picture canvas needs picture (an https link, media:<id> or a file on your computer).`,
        );
      e.picture = o.picture;
      break;
  }
  const short = input.short ? clean(input.short) : "";
  const tiny = input.tiny ? clean(input.tiny) : "";
  if (short.length > L.short) cut.push(`${where}short cut to ${L.short} characters`);
  if (tiny.length > L.tiny) cut.push(`${where}tiny cut to ${L.tiny} characters`);
  e.short = short ? cutAtWord(short, L.short) : makeShort(e, L.short);
  e.tiny = tiny
    ? cutAtWord(tiny, L.tiny)
    : e.template === "countdown"
      ? cutAtWord(e.title ?? "", L.tiny)
      : makeShort({ ...e, footer: undefined }, L.tiny);
  return { entry: e, cut };
}

/** Checks a schedule: 1 to 14 entries, the first now, the rest at least 5 minutes apart. */
export function checkSchedule(
  entries: Array<CanvasEntryBody & { at: string | null }>,
  now: Date = new Date(),
) {
  if (!entries.length) throw new CanvasError("empty", "A canvas needs something to show.");
  if (entries.length > CANVAS_LIMITS.entries)
    throw new CanvasError(
      "too_many_entries",
      `A schedule holds at most ${CANVAS_LIMITS.entries} entries. For more, use a rotation (rotate).`,
    );
  let last = now.getTime() - CANVAS_LIMITS.entryGapMs;
  for (const [i, e] of entries.entries()) {
    if (i === 0) {
      last = now.getTime();
      continue;
    }
    const t = e.at ? Date.parse(e.at) : Number.NaN;
    if (Number.isNaN(t))
      throw new CanvasError("bad_time", `Schedule entry ${i + 1} needs at, when it shows from.`);
    if (t - last < CANVAS_LIMITS.entryGapMs)
      throw new CanvasError(
        "too_close",
        `Schedule entry ${i + 1} is less than 5 minutes after the one before it, or out of order.`,
      );
    last = t;
  }
}

// ------------------------------------------------------------------ rotations

/** "HH:MM" → minutes after midnight; null when it isn't a time. */
export function parseClock(at: string): number | null {
  const m = /^([01]?\d|2[0-3]):([0-5]\d)$/.exec(at.trim());
  return m ? Number(m[1]) * 60 + Number(m[2]) : null;
}

const fmtCache = new Map<string, Intl.DateTimeFormat>();
function zoneParts(t: number, tz: string) {
  let f = fmtCache.get(tz);
  if (!f) {
    f = new Intl.DateTimeFormat("en-US", {
      timeZone: tz,
      hourCycle: "h23",
      year: "numeric",
      month: "numeric",
      day: "numeric",
      hour: "numeric",
      minute: "numeric",
      second: "numeric",
    });
    if (fmtCache.size > 200) fmtCache.clear();
    fmtCache.set(tz, f);
  }
  const p: Record<string, number> = {};
  for (const x of f.formatToParts(new Date(t)))
    if (x.type !== "literal") p[x.type] = Number(x.value);
  return {
    y: p.year as number,
    mo: p.month as number,
    d: p.day as number,
    h: (p.hour as number) % 24,
    mi: p.minute as number,
    s: p.second as number,
  };
}

/** Days since 1970-01-01 of the local date at `t` in `tz`, and the minutes into that day. */
function localDay(t: number, tz: string) {
  const p = zoneParts(t, tz);
  return { day: Math.floor(Date.UTC(p.y, p.mo - 1, p.d) / 86_400_000), minutes: p.h * 60 + p.mi };
}

/** The instant a local date (days since 1970) and minute is at in `tz` (DST aware). */
function zonedInstant(day: number, minutes: number, tz: string) {
  const wall = day * 86_400_000 + minutes * 60_000;
  const offsetAt = (t: number) => {
    const p = zoneParts(t, tz);
    return Date.UTC(p.y, p.mo - 1, p.d, p.h, p.mi, p.s) - Math.floor(t / 1000) * 1000;
  };
  let t = wall - offsetAt(wall);
  // Once more, for when the guess fell on the other side of a clock change.
  t = wall - offsetAt(t);
  return t;
}

/** The slot a moment falls in: how many switches have happened since a fixed origin. */
function slotAt(r: CanvasRhythm & { started_at: string; tz: string }, t: number) {
  if (typeof r.every === "number") {
    const start = Date.parse(r.started_at);
    return Math.floor((t - start) / (r.every * 3_600_000));
  }
  const at = parseClock(r.at) ?? 0;
  const { day, minutes } = localDay(t, r.tz);
  const switchDay = minutes >= at ? day : day - 1;
  if (r.every === "day") return switchDay;
  // Weeks: 1970-01-01 was a Thursday (4).
  const anchor = ((((r.weekday ?? 1) - 4) % 7) + 7) % 7;
  return Math.floor((switchDay - anchor) / 7);
}

/** When a slot's switch happens. */
function slotTime(r: CanvasRhythm & { started_at: string; tz: string }, slot: number) {
  if (typeof r.every === "number") return Date.parse(r.started_at) + slot * r.every * 3_600_000;
  const at = parseClock(r.at) ?? 0;
  if (r.every === "day") return zonedInstant(slot, at, r.tz);
  const anchor = ((((r.weekday ?? 1) - 4) % 7) + 7) % 7;
  return zonedInstant(slot * 7 + anchor, at, r.tz);
}

/** A small seeded random number source (mulberry32 over a string hash). */
function seeded(seed: string) {
  let h = 1779033703 ^ seed.length;
  for (let i = 0; i < seed.length; i++) {
    h = Math.imul(h ^ seed.charCodeAt(i), 3432918353);
    h = (h << 13) | (h >>> 19);
  }
  let a = h >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

/** The order of a lap: the same for the same canvas and lap on every device and every read. */
export function lapOrder(n: number, order: "in_order" | "shuffle", seed: string, lap: number) {
  const idx = Array.from({ length: n }, (_, i) => i);
  if (order === "in_order" || n < 2) return idx;
  const rnd = seeded(`${seed}:${lap}`);
  for (let i = n - 1; i > 0; i--) {
    const j = Math.floor(rnd() * (i + 1));
    [idx[i], idx[j]] = [idx[j] as number, idx[i] as number];
  }
  return idx;
}

export interface RotationSpot {
  /** Switches since the rotation started (0 for the first item). */
  step: number;
  /** Which item shows. */
  item: number;
  lap: number;
  /** Items left to show before it loops or stops (this one excluded). */
  left: number;
  /** A stopping rotation that reached its last item. */
  ended: boolean;
}

/** Which item of a rotation shows at `t`: worked out from the clock, nothing is stored. */
export function rotationAt(
  r: NonNullable<CanvasContent["rotation"]>,
  seed: string,
  t: number = Date.now(),
): RotationSpot {
  const n = r.items.length;
  const start = Date.parse(r.started_at);
  const step = Math.max(0, slotAt(r, Math.max(t, start)) - slotAt(r, start));
  if (r.at_end === "stop" && step >= n - 1) {
    const order = lapOrder(n, r.order, seed, 0);
    return { step, item: order[n - 1] as number, lap: 0, left: 0, ended: true };
  }
  const lap = Math.floor(step / n);
  const pos = step % n;
  const order = lapOrder(n, r.order, seed, lap);
  return { step, item: order[pos] as number, lap, left: n - 1 - pos, ended: false };
}

/**
 * The next entries of a rotation as a schedule: the one showing now (`at` null) and the next
 * ones with the times they switch, up to `count`. Widgets treat them exactly like a schedule.
 */
export function dealRotation(
  r: NonNullable<CanvasContent["rotation"]>,
  seed: string,
  t: number = Date.now(),
  count: number = CANVAS_LIMITS.entries,
): Array<CanvasEntryBody & { at: string | null }> {
  const n = r.items.length;
  if (!n) return [];
  const start = Date.parse(r.started_at);
  const base = slotAt(r, start);
  const first = rotationAt(r, seed, t);
  const out: Array<CanvasEntryBody & { at: string | null }> = [
    { ...(r.items[first.item] as CanvasEntryBody), at: null },
  ];
  if (first.ended) return out;
  for (let k = 1; out.length < count; k++) {
    const step = first.step + k;
    if (r.at_end === "stop" && step > n - 1) break;
    const lap = Math.floor(step / n);
    const item = lapOrder(n, r.order, seed, lap)[step % n] as number;
    out.push({
      ...(r.items[item] as CanvasEntryBody),
      at: new Date(slotTime(r, base + step)).toISOString(),
    });
  }
  return out;
}

/** The entries a canvas shows from now: a schedule's still-current ones, or a rotation dealt. */
export function currentEntries(
  content: CanvasContent,
  seed: string,
  t: number = Date.now(),
): Array<CanvasEntryBody & { at: string | null }> {
  if (content.rotation) return dealRotation(content.rotation, seed, t);
  const list = content.entries ?? [];
  // Drop entries already replaced by a later one that has started.
  let from = 0;
  for (const [i, e] of list.entries()) if (i > 0 && e.at && Date.parse(e.at) <= t) from = i;
  return list.slice(from).map((e, i) => (i === 0 ? { ...e, at: null } : e));
}

/** A rhythm in words, for the bot ("every day at 06:00, shuffled, looping"). */
export function rhythmWords(r: CanvasRhythm): string {
  const days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
  const every =
    typeof r.every === "number"
      ? r.every === 1
        ? "every hour"
        : `every ${r.every} hours`
      : r.every === "day"
        ? `every day at ${r.at}`
        : `every ${days[r.weekday ?? 1]} at ${r.at}`;
  return `${every}, ${r.order === "shuffle" ? "shuffled" : "in order"}, ${r.at_end === "loop" ? "starting again at the end" : "stopping on the last one"}`;
}

/**
 * Splits a rotation file into items: JSON (an array of strings or of objects with the entry
 * fields), CSV with a header row (title, text, footer, short, tiny…), or one item per line.
 */
export function parseItemsFile(text: string, name = ""): EntryInput[] {
  const t = text.replace(/^\uFEFF/, "").trim();
  if (!t) return [];
  if (/\.json$/i.test(name) || t.startsWith("[") || t.startsWith("{")) {
    let v: unknown;
    try {
      v = JSON.parse(t);
    } catch {
      throw new CanvasError("bad_file", "The items file looks like JSON but doesn't parse.");
    }
    const arr = Array.isArray(v)
      ? v
      : Array.isArray((v as { items?: unknown }).items)
        ? (v as { items: unknown[] }).items
        : null;
    if (!arr)
      throw new CanvasError("bad_file", "A JSON items file is a list, or an object with items.");
    return arr.map((x) => (typeof x === "string" ? { text: x } : ((x ?? {}) as EntryInput)));
  }
  const lines = t.split(/\r?\n/).filter((l) => l.trim());
  const head = lines[0]?.toLowerCase() ?? "";
  if (/\.csv$/i.test(name) || /^"?(title|text|template)"?\s*,/.test(head)) {
    const rows = lines.map(parseCsvLine);
    const cols = (rows[0] ?? []).map((c) => c.trim().toLowerCase());
    return rows.slice(1).map((r) => {
      const o: Record<string, unknown> = {};
      for (const [i, c] of cols.entries()) {
        const v = r[i]?.trim();
        if (!v) continue;
        o[c] = c === "value" || c === "of" ? Number(v) : v;
      }
      return o as EntryInput;
    });
  }
  return lines.map((l) => ({ text: l.trim() }));
}

function parseCsvLine(line: string): string[] {
  const out: string[] = [];
  let cur = "";
  let q = false;
  for (let i = 0; i < line.length; i++) {
    const c = line[i] as string;
    if (q) {
      if (c === '"' && line[i + 1] === '"') {
        cur += '"';
        i++;
      } else if (c === '"') q = false;
      else cur += c;
    } else if (c === '"') q = true;
    else if (c === ",") {
      out.push(cur);
      cur = "";
    } else cur += c;
  }
  out.push(cur);
  return out;
}
