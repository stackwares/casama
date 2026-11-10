/**
 * Quiet hours (SPEC: Post-v1 roadmap → App polish; D-109): a daily window in the person's
 * timezone when pushes wait. Windows may cross midnight (22:00 to 07:00).
 */
export interface QuietHours {
  enabled: boolean;
  /** "HH:MM", 24-hour, local time. */
  start: string;
  end: string;
}

const HM = /^([01]\d|2[0-3]):([0-5]\d)$/;
export const isValidQuietHours = (q: unknown): q is QuietHours =>
  !!q &&
  typeof q === "object" &&
  typeof (q as QuietHours).enabled === "boolean" &&
  HM.test((q as QuietHours).start) &&
  HM.test((q as QuietHours).end) &&
  (q as QuietHours).start !== (q as QuietHours).end;

const minutes = (hm: string) => {
  const [h, m] = hm.split(":").map(Number);
  return (h as number) * 60 + (m as number);
};

/** Minutes since local midnight in a timezone. */
function localMinutes(now: Date, timeZone: string) {
  const parts = new Intl.DateTimeFormat("en-US", {
    timeZone,
    hour: "2-digit",
    minute: "2-digit",
    hourCycle: "h23",
  }).formatToParts(now);
  const h = Number(parts.find((p) => p.type === "hour")?.value ?? 0);
  const m = Number(parts.find((p) => p.type === "minute")?.value ?? 0);
  return h * 60 + m;
}

/** When the quiet window ends, if `now` is inside it; null when pushes can go now. */
export function quietUntil(
  now: Date,
  timeZone: string,
  q: QuietHours | null | undefined,
): Date | null {
  if (!q?.enabled || !isValidQuietHours(q)) return null;
  const tz = (() => {
    try {
      new Intl.DateTimeFormat("en-US", { timeZone });
      return timeZone;
    } catch {
      return "UTC";
    }
  })();
  const t = localMinutes(now, tz);
  const s = minutes(q.start);
  const e = minutes(q.end);
  const inside = s < e ? t >= s && t < e : t >= s || t < e;
  if (!inside) return null;
  const wait = (e - t + 1440) % 1440 || 1440;
  // Round to the minute boundary; DST shifts within the window move the end by at most an hour.
  const end = new Date(now.getTime() + wait * 60_000);
  end.setUTCSeconds(0, 0);
  return end;
}
