import { type Database, withUserSession } from "@kasama/db";
import { sql } from "drizzle-orm";
import type { MiddlewareHandler } from "hono";
import { ApiError } from "../errors.ts";
import type { AppEnv } from "../types.ts";

const MUTATING = new Set(["POST", "PUT", "PATCH", "DELETE"]);

/**
 * Idempotency-Key support: the first successful (non-5xx) JSON response for a (user, key) pair
 * is stored and replayed for retries. Reusing a key for a different request is a 422.
 */
export function idempotency(db: Database): MiddlewareHandler<AppEnv> {
  return async (c, next) => {
    const key = c.req.header("idempotency-key");
    const claims = c.get("claims");
    if (!key || !claims || !MUTATING.has(c.req.method)) return next();
    if (key.length > 255)
      throw new ApiError(400, "validation_failed", "Idempotency-Key is too long");

    const rows = await withUserSession(db, claims, (tx) =>
      tx.execute<{ method: string; path: string; status: number; response: unknown }>(
        sql`select method, path, status, response from public.idempotency_keys where user_id = ${claims.sub} and key = ${key}`,
      ),
    );
    const prior = rows[0];
    if (prior) {
      if (prior.method !== c.req.method || prior.path !== c.req.path) {
        throw new ApiError(
          422,
          "idempotency_key_reused",
          "This Idempotency-Key was used for a different request",
        );
      }
      c.header("idempotent-replayed", "true");
      return c.json(prior.response as object, prior.status as 200);
    }

    await next();

    const status = c.res.status;
    if (status >= 500 || !c.res.headers.get("content-type")?.includes("json")) return;
    const body = await c.res
      .clone()
      .json()
      .catch(() => null);
    if (body === null) return;
    await withUserSession(db, claims, (tx) =>
      tx.execute(sql`insert into public.idempotency_keys (user_id, key, method, path, status, response)
                     values (${claims.sub}, ${key}, ${c.req.method}, ${c.req.path}, ${status}, ${JSON.stringify(body)}::jsonb)
                     on conflict (user_id, key) do nothing`),
    );
  };
}
