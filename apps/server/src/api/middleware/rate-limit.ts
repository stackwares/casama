import { createHash } from "node:crypto";
import type { Context, MiddlewareHandler } from "hono";
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
  /**
   * Counts by this instead of the caller's address when it returns something (for example the
   * bearer token, so callers that share an address, such as a hosted MCP client, don't share one
   * budget). Falls back to the signed-in user, then the address.
   */
  key?: (c: Context) => string | undefined;
}): MiddlewareHandler {
  const now = opts.now ?? Date.now;
  const windows = new Map<string, { start: number; count: number }>();
  return async (c, next) => {
    const user = c.get("claims" as never) as { sub?: string } | undefined;
    const ip = clientIp((n) => c.req.header(n), opts.trustedIpHeader);
    const own = opts.key?.(c);
    const key = own ? `k:${own}` : user?.sub ? `u:${user.sub}` : `ip:${ip}`;
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

/** A rateLimit key from the bearer token (hashed, so no secret is kept in memory). */
export function bearerKey(c: Context): string | undefined {
  const tok = (c.req.header("authorization") ?? "").replace(/^Bearer\s+/i, "").trim();
  return tok ? createHash("sha256").update(tok).digest("hex").slice(0, 32) : undefined;
}
