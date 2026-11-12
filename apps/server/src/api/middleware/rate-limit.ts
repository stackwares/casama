import type { MiddlewareHandler } from "hono";
import { ApiError } from "../errors.ts";
import { clientIp } from "../util.ts";

/**
 * Fixed-window rate limit per key (user id when signed in, else client IP).
 * In-memory: correct for the single API process the spec targets; swap for a shared store to scale out.
 */
export function rateLimit(opts: {
  perMinute: number;
  now?: () => number;
  /** TRUSTED_CLIENT_IP_HEADER: see clientIp. */
  trustedIpHeader?: string;
}): MiddlewareHandler {
  const now = opts.now ?? Date.now;
  const windows = new Map<string, { start: number; count: number }>();
  return async (c, next) => {
    const user = c.get("claims" as never) as { sub?: string } | undefined;
    const ip = clientIp((n) => c.req.header(n), opts.trustedIpHeader);
    const key = user?.sub ? `u:${user.sub}` : `ip:${ip}`;
    const t = now();
    let w = windows.get(key);
    if (!w || t - w.start >= 60_000) {
      w = { start: t, count: 0 };
      windows.set(key, w);
      if (windows.size > 50_000)
        for (const [k, v] of windows) if (t - v.start >= 60_000) windows.delete(k);
    }
    w.count++;
    if (w.count > opts.perMinute) {
      const retry = Math.max(1, Math.ceil((w.start + 60_000 - t) / 1000));
      throw new ApiError(429, "rate_limited", "Too many requests", {
        headers: { "retry-after": String(retry) },
      });
    }
    await next();
  };
}
