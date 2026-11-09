import { CronExpressionParser } from "cron-parser";

/** Validates an IANA timezone name. */
export function isValidTimezone(tz: string) {
  try {
    new Intl.DateTimeFormat("en-US", { timeZone: tz });
    return true;
  } catch {
    return false;
  }
}

/** Validates a 5-field cron expression (minute hour day month weekday). */
export function isValidCron(expr: string) {
  if (expr.trim().split(/\s+/).length !== 5) return false;
  try {
    CronExpressionParser.parse(expr);
    return true;
  } catch {
    return false;
  }
}

/** The next time a cron expression fires after `after`, in the routine's timezone (DST aware). */
export function nextRunAt(expr: string, timezone: string, after: Date = new Date()): Date {
  const it = CronExpressionParser.parse(expr, { currentDate: after, tz: timezone });
  return it.next().toDate();
}
