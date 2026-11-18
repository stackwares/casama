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
