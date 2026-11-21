import type { Database, JwtClaims } from "@casama/db";
import { sql } from "drizzle-orm";
import { ApiError } from "./errors.ts";

const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/**
 * Refuses a token whose sign-in session is gone (D-474). An access token stays valid until it
 * expires (up to an hour), even after Sign Out Everywhere deleted its session, so routes that
 * mint longer-lived credentials (sign-in codes, watch keys, widget keys) check that the session
 * still exists. A token without a session id (Casama's own short-lived tokens) has none to check.
 */
export async function requireLiveSession(db: Database, claims: JwtClaims): Promise<void> {
  const session = claims.session_id;
  if (typeof session !== "string" || !session) return;
  if (!uuid.test(session)) throw new ApiError(401, "session_ended", "This sign-in has ended");
  const [row] = await db.execute<{ ok: boolean }>(sql`
    select true as ok from auth.sessions
    where id = ${session}::uuid and user_id = ${claims.sub}::uuid
      and (not_after is null or not_after > now())`);
  if (!row) throw new ApiError(401, "session_ended", "This sign-in has ended");
}
