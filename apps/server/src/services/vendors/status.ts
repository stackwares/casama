/** Classify a quota reading. Missing or invalid readings must never look healthy. */
export function quotaStatus(
  used: number | null,
  limit: number | null,
  warnAt = 0.8,
): "ok" | "low" | "out" | "unknown" {
  if (
    used === null ||
    limit === null ||
    !Number.isFinite(used) ||
    !Number.isFinite(limit) ||
    used < 0 ||
    limit <= 0 ||
    !Number.isFinite(warnAt) ||
    warnAt <= 0 ||
    warnAt > 1
  ) {
    return "unknown";
  }
  if (used >= limit) return "out";
  return used / limit >= warnAt ? "low" : "ok";
}

/** A balance threshold is an amount in the reading's currency, not a quota percentage. */
export function balanceStatus(
  remaining: number | null,
  warnBelow: number,
): "ok" | "low" | "out" | "unknown" {
  if (
    remaining === null ||
    !Number.isFinite(remaining) ||
    !Number.isFinite(warnBelow) ||
    warnBelow < 0
  )
    return "unknown";
  if (remaining <= 0) return "out";
  return remaining <= warnBelow ? "low" : "ok";
}
