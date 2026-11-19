/**
 * Call limits (D-426): how long a quiet call stays open, when the server gives up on a call whose
 * app went away, the longest a call may run, how early the bot is warned before a limit, and how
 * often bots may ring a person. Edited in Admin → Call limits (`instance_settings` key
 * `call_limits`), loaded by every process every minute. Each value is optional: one left out uses
 * the default here, and every value is kept inside its range, so a bad save can't turn a guardrail
 * off.
 */

export interface CallLimits {
  /** The app hangs up after this long with nobody speaking and no job running. */
  silence_seconds: number;
  /** How often the app tells the server the call is still open. */
  heartbeat_seconds: number;
  /** The server ends a call with no heartbeat for this long (the app was closed or lost). */
  abandoned_seconds: number;
  /** The longest a live call may run. */
  max_call_minutes: number;
  /** How long before a limit (length or money) the bot is told to warn the person. */
  warning_seconds: number;
  /** Rings a person can get from bots in one day (their time zone); 0 means bots never ring. */
  ring_daily_cap: number;
  /** After ringing a person, a bot waits this long before it may ring them again. */
  ring_cooldown_minutes: number;
}

export const DEFAULT_CALL_LIMITS: CallLimits = {
  silence_seconds: 60,
  heartbeat_seconds: 15,
  abandoned_seconds: 60,
  max_call_minutes: 60,
  warning_seconds: 60,
  ring_daily_cap: 3,
  ring_cooldown_minutes: 30,
};

/**
 * The range each value may take. Apps from before D-426 send a heartbeat every 30 seconds, so the
 * server waits at least 60 for one; anything shorter would end their calls by mistake.
 */
export const CALL_LIMIT_RANGES: Record<keyof CallLimits, readonly [number, number]> = {
  silence_seconds: [20, 900],
  heartbeat_seconds: [5, 60],
  abandoned_seconds: [60, 900],
  max_call_minutes: [5, 240],
  warning_seconds: [15, 300],
  ring_daily_cap: [0, 20],
  ring_cooldown_minutes: [0, 1440],
};

const KEYS = Object.keys(DEFAULT_CALL_LIMITS) as Array<keyof CallLimits>;

/** Checks an owner's save: unknown names and values out of range are refused with a reason. */
export function checkCallLimits(raw: unknown): { limits: Partial<CallLimits>; errors: string[] } {
  const errors: string[] = [];
  const limits: Partial<CallLimits> = {};
  if (raw === null || raw === undefined) return { limits, errors };
  if (typeof raw !== "object" || Array.isArray(raw))
    return { limits, errors: ["call limits must be an object"] };
  for (const [k, v] of Object.entries(raw as Record<string, unknown>)) {
    const key = KEYS.find((x) => x === k);
    if (!key) {
      errors.push(`unknown limit ${k} (${KEYS.join(", ")})`);
      continue;
    }
    if (v === null) continue;
    const [lo, hi] = CALL_LIMIT_RANGES[key];
    if (typeof v !== "number" || !Number.isInteger(v) || v < lo || v > hi)
      errors.push(`${k} must be a whole number from ${lo} to ${hi}`);
    else limits[key] = v;
  }
  return { limits, errors };
}

/**
 * The limits in use: the saved values over the defaults, each kept in range, and made to fit
 * together: a heartbeat at most a third of the time the server waits for one, and a warning at
 * most half the longest call.
 */
export function resolveCallLimits(saved: unknown): CallLimits {
  const out = { ...DEFAULT_CALL_LIMITS };
  if (saved && typeof saved === "object" && !Array.isArray(saved))
    for (const key of KEYS) {
      const v = (saved as Record<string, unknown>)[key];
      if (typeof v !== "number" || !Number.isFinite(v)) continue;
      const [lo, hi] = CALL_LIMIT_RANGES[key];
      out[key] = Math.min(hi, Math.max(lo, Math.round(v)));
    }
  out.heartbeat_seconds = Math.max(
    CALL_LIMIT_RANGES.heartbeat_seconds[0],
    Math.min(out.heartbeat_seconds, Math.floor(out.abandoned_seconds / 3)),
  );
  out.warning_seconds = Math.min(out.warning_seconds, (out.max_call_minutes * 60) / 2);
  return out;
}

let saved: Partial<CallLimits> = {};
let current: CallLimits = resolveCallLimits({});

/** Replaces the loaded limits (the server calls it every minute); bad values are left out. */
export function setCallLimits(raw: unknown) {
  saved = checkCallLimits(raw).limits;
  current = resolveCallLimits(saved);
}

/** The limits in use in this process. */
export function callLimits(): CallLimits {
  return current;
}

/**
 * How long a call's provider token lives: the longest call plus room for its goodbye and a
 * reconnect. Nothing about a call (its token, its clock for billing) outlives this.
 */
export function callLifeSeconds(limits: CallLimits = current): number {
  return limits.max_call_minutes * 60 + 5 * 60;
}
