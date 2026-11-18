// SPDX-License-Identifier: Apache-2.0
// A shared format, also used by the Apache-2.0 SDKs and tools (LICENSING.md).
/**
 * A 5-field cron check with no dependencies, for the checks that must run with plain Node and
 * nothing installed (`casama-plugin-check`, the gallery checks it shares). The server still parses
 * schedules with cron-parser (`schedule.ts`); this accepts a subset of what that accepts: numbers,
 * `*`, ranges, steps, lists, month and weekday names, and `?` for a day. No `L`, `W` or `#`.
 */

const FIELDS: Array<{ min: number; max: number; names?: string[]; question?: boolean }> = [
  { min: 0, max: 59 },
  { min: 0, max: 23 },
  { min: 1, max: 31, question: true },
  {
    min: 1,
    max: 12,
    names: ["jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"],
  },
  // 0 and 7 are both Sunday.
  { min: 0, max: 7, names: ["sun", "mon", "tue", "wed", "thu", "fri", "sat"], question: true },
];

function value(raw: string, f: (typeof FIELDS)[number]): number | undefined {
  if (/^\d{1,2}$/.test(raw)) {
    const n = Number(raw);
    return n >= f.min && n <= f.max ? n : undefined;
  }
  const i = f.names?.indexOf(raw.toLowerCase()) ?? -1;
  if (i < 0) return undefined;
  return f.min === 1 ? i + 1 : i;
}

function part(raw: string, f: (typeof FIELDS)[number]): boolean {
  const [range, step, extra] = raw.split("/");
  if (extra !== undefined || range === undefined || range === "") return false;
  if (step !== undefined && !(/^\d{1,2}$/.test(step) && Number(step) >= 1)) return false;
  if (range === "*") return true;
  const [a, b, more] = range.split("-");
  if (more !== undefined || a === undefined) return false;
  const from = value(a, f);
  if (from === undefined) return false;
  if (b === undefined) return true;
  const to = value(b, f);
  return to !== undefined && to >= from;
}

/** Whether `expr` is a 5-field cron expression (minute hour day month weekday). */
export function isCronSyntax(expr: string): boolean {
  const fields = expr.trim().split(/\s+/);
  if (fields.length !== 5) return false;
  return fields.every((raw, i) => {
    const f = FIELDS[i] as (typeof FIELDS)[number];
    if (raw === "?") return f.question === true;
    return raw.split(",").every((p) => part(p, f));
  });
}

/** How many times a cron expression fires in one week (minute by minute over a fixed week, UTC). */
export function cronRunsPerWeek(expr: string): number {
  if (!isCronSyntax(expr)) return 0;
  const sets = expr
    .trim()
    .split(/\s+/)
    .map((raw, i) => expand(raw, FIELDS[i] as (typeof FIELDS)[number]));
  const [mins, hours, doms, months, dows] = sets as [
    Set<number>,
    Set<number>,
    Set<number>,
    Set<number>,
    Set<number>,
  ];
  if (dows.has(7)) dows.add(0);
  const domStar = expr.trim().split(/\s+/)[2] === "*" || expr.trim().split(/\s+/)[2] === "?";
  const dowStar = expr.trim().split(/\s+/)[4] === "*" || expr.trim().split(/\s+/)[4] === "?";
  // An average week: count over 52 whole weeks and divide, so monthly schedules count as a fraction.
  let days = 0;
  const start = Date.UTC(2026, 0, 5);
  for (let d = 0; d < 364; d++) {
    const date = new Date(start + d * 86_400_000);
    if (!months.has(date.getUTCMonth() + 1)) continue;
    const domOk = doms.has(date.getUTCDate());
    const dowOk = dows.has(date.getUTCDay());
    // Classic cron: when both day fields are restricted, either one matching is enough.
    const ok = domStar && dowStar ? true : domStar ? dowOk : dowStar ? domOk : domOk || dowOk;
    if (ok) days++;
  }
  return Math.round(((days * mins.size * hours.size) / 52) * 100) / 100;
}

function expand(raw: string, f: (typeof FIELDS)[number]): Set<number> {
  const out = new Set<number>();
  if (raw === "?") raw = "*";
  for (const p of raw.split(",")) {
    const [range, stepRaw] = p.split("/") as [string, string | undefined];
    const step = stepRaw ? Number(stepRaw) : 1;
    let from = f.min;
    let to = f.max;
    if (range !== "*") {
      const [a, b] = range.split("-") as [string, string | undefined];
      from = value(a, f) as number;
      to = b !== undefined ? (value(b, f) as number) : stepRaw ? f.max : from;
    }
    for (let n = from; n <= to; n += step) out.add(n);
  }
  return out;
}

const CRON_MACROS: Record<string, string> = {
  "@hourly": "0 * * * *",
  "@daily": "0 0 * * *",
  "@midnight": "0 0 * * *",
  "@weekly": "0 0 * * 0",
  "@monthly": "0 0 1 * *",
};
const DAY_KEYS = ["sun", "mon", "tue", "wed", "thu", "fri", "sat"];
const DAY_WORDS = [
  "Sundays",
  "Mondays",
  "Tuesdays",
  "Wednesdays",
  "Thursdays",
  "Fridays",
  "Saturdays",
];

function cronNum(s: string, min: number, max: number): number | null {
  if (!/^\d{1,2}$/.test(s)) return null;
  const n = Number(s);
  return n < min || n > max ? null : n;
}

/** `*` or `0` stepped by n, where [period] divides evenly by n. */
function cronStep(s: string, period: number): number | null {
  const m = /^(?:\*|0)\/(\d{1,2})$/.exec(s);
  if (!m) return null;
  const n = Number(m[1]);
  return n < 1 || n >= period || period % n !== 0 ? null : n;
}

function cronDay(s: string): number | null {
  const named = DAY_KEYS.indexOf(s.toLowerCase());
  if (named >= 0) return named;
  const n = cronNum(s, 0, 7);
  return n === null ? null : n % 7;
}

function cronDays(field: string): Set<number> | null {
  const days = new Set<number>();
  for (const part of field.split(",")) {
    const range = part.split("-");
    if (range.length === 1) {
      const d = cronDay(part);
      if (d === null) return null;
      days.add(d);
    } else if (range.length === 2) {
      const from = cronDay(range[0] as string);
      // A range may end on Sunday (`5-7`, `fri-sun`).
      const end = cronDay(range[1] as string);
      const to = end === 0 && range[1] !== "0" ? 7 : end;
      if (from === null || to === null || from > to) return null;
      for (let d = from; d <= to; d++) days.add(d % 7);
    } else return null;
  }
  return days;
}

/**
 * A schedule in English words (D-405, the widgets' "how often"), ported from the app's
 * `cron_words.dart` (D-182) with its `app_en.arb` wording: "Weekdays at 9:00", "Every 2 hours".
 * Times are 24-hour ("17:30"), in the routine's own timezone. Anything uncommon keeps its
 * expression.
 */
export function cronWords(cron: string): string {
  const raw = cron.trim();
  let text = raw.replace(/\s+/g, " ");
  text = CRON_MACROS[text.toLowerCase()] ?? text;
  const f = text.split(" ");
  if (f.length !== 5) return raw;
  const [min, hour, dom, month, dow] = f as [string, string, string, string, string];
  if (month !== "*") return raw;
  const at = (h: number, m: number) => `${h}:${String(m).padStart(2, "0")}`;
  const everyDay = dom === "*" && dow === "*";
  if (everyDay && hour === "*") {
    if (min === "*") return "Every minute";
    const n = cronStep(min, 60);
    if (n !== null) return n === 1 ? "Every minute" : `Every ${n} minutes`;
    const m = cronNum(min, 0, 59);
    if (m === null) return raw;
    return m === 0 ? "Every hour" : `Every hour at :${String(m).padStart(2, "0")}`;
  }
  const m = cronNum(min, 0, 59);
  if (m === null) return raw;
  if (everyDay) {
    const hours = cronStep(hour, 24);
    if (hours !== null) return m !== 0 ? raw : hours === 1 ? "Every hour" : `Every ${hours} hours`;
  }
  const h = cronNum(hour, 0, 23);
  if (h === null) return raw;
  if (everyDay) return `Every day at ${at(h, m)}`;
  if (dom === "*") {
    const days = cronDays(dow);
    if (!days?.size) return raw;
    if (days.size === 7) return `Every day at ${at(h, m)}`;
    const list = [...days].sort((a, b) => a - b);
    if (list.length === 5 && [1, 2, 3, 4, 5].every((d) => days.has(d)))
      return `Weekdays at ${at(h, m)}`;
    if (list.length === 2 && days.has(0) && days.has(6)) return `Weekends at ${at(h, m)}`;
    // The week starts on Monday.
    const names = [...list.filter((d) => d !== 0), ...(days.has(0) ? [0] : [])].map(
      (d) => DAY_WORDS[d] as string,
    );
    const words =
      names.length === 1
        ? (names[0] as string)
        : `${names.slice(0, -1).join(", ")} and ${names.at(-1)}`;
    return `${words} at ${at(h, m)}`;
  }
  if (dow !== "*") return raw;
  const d = cronNum(dom, 1, 31);
  return d === null ? raw : `Day ${d} of every month at ${at(h, m)}`;
}
