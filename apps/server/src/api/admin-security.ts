import type { Database, JwtClaims } from "@casama/db";
import { sql } from "drizzle-orm";
import { ApiError } from "./errors.ts";

export const ADMIN_READ_WINDOW_SECONDS = 300;
export const ADMIN_WRITE_WINDOW_SECONDS = 60;

// Explicitly exclude refresh, invite, recovery and anonymous sessions. Unknown future methods
// fail closed until reviewed. These are authentication-server claims, never request-body data.
const interactiveMethods = new Set([
  "password",
  "otp",
  "totp",
  "oauth",
  "sso/saml",
  "magiclink",
  "passkey",
]);

const refusal = (write: boolean) =>
  new ApiError(
    403,
    write ? "admin_confirmation_required" : "admin_reauthentication_required",
    write
      ? "Confirm this admin action with a fresh sign-in."
      : "Unlock the admin console with a fresh sign-in.",
  );

/** Whether the token carries a real sign-in within the window (reads 5 minutes, writes 1). */
export function hasFreshAuthentication(
  claims: JwtClaims,
  write: boolean,
  nowSeconds = Date.now() / 1000,
): boolean {
  const window = write ? ADMIN_WRITE_WINDOW_SECONDS : ADMIN_READ_WINDOW_SECONDS;
  return (
    Array.isArray(claims.amr) &&
    claims.amr.some((entry: unknown) => {
      if (!entry || typeof entry !== "object") return false;
      const { method, timestamp } = entry as Record<string, unknown>;
      return (
        typeof method === "string" &&
        interactiveMethods.has(method) &&
        typeof timestamp === "number" &&
        Number.isFinite(timestamp) &&
        timestamp > 0 &&
        timestamp <= nowSeconds &&
        nowSeconds - timestamp <= window
      );
    })
  );
}

/** The admin console's own probe that needs no fresh sign-in (instance counts for navigation). */
export function adminPathExempt(method: string, path: string) {
  return method === "GET" && path === "/v1/admin/overview";
}

export function requireFreshAdminAuthentication(
  method: string,
  path: string,
  claims: JwtClaims | undefined,
  nowSeconds = Date.now() / 1000,
): void {
  // Navigation probes this owner-only endpoint without opening the console.
  if (adminPathExempt(method, path)) return;
  if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
  const write = !(method === "GET" || method === "HEAD");
  if (!hasFreshAuthentication(claims, write, nowSeconds)) throw refusal(write);
}

/**
 * An account with two-step sign-in must have passed it in this session (aal2). Without this, a
 * fresh password alone (an aal1 session) would count, and the authenticator would protect nothing.
 */
export async function requireSecondStep(
  db: Database,
  claims: JwtClaims,
  write: boolean,
): Promise<void> {
  if (claims.aal === "aal2") return;
  const [row] = await db.execute<{ has: boolean }>(sql`
    select exists (
      select 1 from auth.mfa_factors where user_id = ${claims.sub}::uuid and status = 'verified'
    ) as has`);
  if (row?.has) throw refusal(write);
}

/**
 * Owner-only actions outside /v1/admin (sign-in codes, admin bot approvals, gallery requests): the
 * same one-minute fresh sign-in, and the second step when the account has one.
 */
export async function requireFreshOwnerAction(
  db: Database,
  claims: JwtClaims,
  nowSeconds = Date.now() / 1000,
): Promise<void> {
  if (!hasFreshAuthentication(claims, true, nowSeconds)) throw refusal(true);
  await requireSecondStep(db, claims, true);
}
