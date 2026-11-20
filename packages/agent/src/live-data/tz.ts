/** Time zone arithmetic with Intl (the IANA database Node ships). */

const fmts = new Map<string, Intl.DateTimeFormat>();
function fmt(tz: string) {
  let f = fmts.get(tz);
  if (!f) {
    f = new Intl.DateTimeFormat("en-US", {
      timeZone: tz,
      hourCycle: "h23",
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
      hour: "2-digit",
      minute: "2-digit",
      second: "2-digit",
      weekday: "short",
    });
    fmts.set(tz, f);
  }
  return f;
}

export function isZone(tz: string) {
  try {
    fmt(tz);
    return true;
  } catch {
    return false;
  }
}

export interface LocalParts {
  year: number;
  month: number;
  day: number;
  hour: number;
  minute: number;
  weekday: string;
  /** "2026-11-21" */
  date: string;
}

export function localParts(at: Date, tz: string): LocalParts {
  const parts = Object.fromEntries(
    fmt(tz)
      .formatToParts(at)
      .map((p) => [p.type, p.value]),
  );
  const year = Number(parts.year);
  const month = Number(parts.month);
  const day = Number(parts.day);
  return {
    year,
    month,
    day,
    hour: Number(parts.hour),
    minute: Number(parts.minute),
    weekday: String(parts.weekday),
    date: `${parts.year}-${parts.month}-${parts.day}`,
  };
}

/** Minutes the zone is ahead of UTC at [at]. */
export function offsetMinutes(at: Date, tz: string) {
  const p = localParts(at, tz);
  const asUtc = Date.UTC(p.year, p.month - 1, p.day, p.hour, p.minute);
  return Math.round((asUtc - Math.floor(at.valueOf() / 60000) * 60000) / 60000);
}

/** The instant a local wall time happens in [tz] ("2026-11-21", 0, 0 → that midnight). */
export function zonedTime(date: string, tz: string, hour = 0, minute = 0) {
  const [y, m, d] = date.split("-").map(Number) as [number, number, number];
  const guess = Date.UTC(y, m - 1, d, hour, minute);
  let off = offsetMinutes(new Date(guess), tz);
  let t = guess - off * 60000;
  const off2 = offsetMinutes(new Date(t), tz);
  if (off2 !== off) {
    off = off2;
    t = guess - off * 60000;
  }
  return new Date(t);
}

/** "2026-11-21" plus [days]. */
export function addDays(date: string, days: number) {
  const [y, m, d] = date.split("-").map(Number) as [number, number, number];
  return new Date(Date.UTC(y, m - 1, d + days)).toISOString().slice(0, 10);
}

/** An ISO time with the zone's offset ("2026-11-21T14:00+08:00"). */
export function isoInZone(at: Date, tz: string) {
  const p = localParts(at, tz);
  const off = offsetMinutes(at, tz);
  const sign = off < 0 ? "-" : "+";
  const a = Math.abs(off);
  const hh = String(Math.floor(a / 60)).padStart(2, "0");
  const mm = String(a % 60).padStart(2, "0");
  return `${p.date}T${String(p.hour).padStart(2, "0")}:${String(p.minute).padStart(2, "0")}${sign}${hh}:${mm}`;
}
