import { randomBytes, scrypt as scryptCb, timingSafeEqual } from "node:crypto";
import { promisify } from "node:util";
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
  methods?: string[],
): boolean {
  const window = write ? ADMIN_WRITE_WINDOW_SECONDS : ADMIN_READ_WINDOW_SECONDS;
  return newestTimestamp(claims, methods, window, nowSeconds) !== null;
}

/** The newest real sign-in in the token's `amr` within the window, in seconds; null when none. */
function newestTimestamp(
  claims: JwtClaims,
  methods: string[] | undefined,
  window: number,
  nowSeconds: number,
): number | null {
  if (!Array.isArray(claims.amr)) return null;
  let newest: number | null = null;
  for (const entry of claims.amr as unknown[]) {
    if (!entry || typeof entry !== "object") continue;
    const { method, timestamp } = entry as Record<string, unknown>;
    if (
      typeof method === "string" &&
      interactiveMethods.has(method) &&
      (!methods || methods.includes(method)) &&
      typeof timestamp === "number" &&
      Number.isFinite(timestamp) &&
      timestamp > 0 &&
      timestamp <= nowSeconds &&
      nowSeconds - timestamp <= window &&
      (newest === null || timestamp > newest)
    )
      newest = timestamp;
  }
  return newest;
}

/** The checks themselves (D-452): they make a session fresh, so they can't require it. */
export const ADMIN_CHECK_PATHS = ["/v1/admin/checks/passkey", "/v1/admin/checks/pin"];

/** The admin console's own probe that needs no fresh sign-in (instance counts for navigation). */
export function adminPathExempt(method: string, path: string) {
  return (
    (method === "GET" && (path === "/v1/admin/overview" || path === "/v1/admin/pin")) ||
    (method === "POST" && ADMIN_CHECK_PATHS.includes(path))
  );
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
  nowSeconds = Date.now() / 1000,
): Promise<void> {
  if (claims.aal === "aal2") return;
  // A passkey is enough on its own, in the token or as a check on this session (D-452).
  if (hasFreshAuthentication(claims, write, nowSeconds, ["passkey"])) return;
  if (await hasFreshCheck(db, claims, write)) return;
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
  if (!hasFreshAuthentication(claims, true, nowSeconds) && !(await hasFreshCheck(db, claims, true)))
    throw refusal(true);
  await requireSecondStep(db, claims, true, nowSeconds);
}

/** The /v1/admin rule: a fresh sign-in in the token or a fresh check on this session (D-452). */
export async function requireFreshAdmin(
  db: Database,
  method: string,
  path: string,
  claims: JwtClaims | undefined,
): Promise<void> {
  if (adminPathExempt(method, path)) return;
  if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
  const write = !(method === "GET" || method === "HEAD");
  if (!hasFreshAuthentication(claims, write) && !(await hasFreshCheck(db, claims, write)))
    throw refusal(write);
  await requireSecondStep(db, claims, write);
}

// --- Checks on the sign-in session: passkey or admin PIN (D-452) ------------------------------

const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const sessionOf = (claims: JwtClaims) =>
  typeof claims.session_id === "string" && uuid.test(claims.session_id) ? claims.session_id : null;

/** A passkey or PIN check on this token's sign-in session within the read or write window. */
export async function hasFreshCheck(
  db: Database,
  claims: JwtClaims,
  write: boolean,
): Promise<boolean> {
  const session = sessionOf(claims);
  if (!session) return false;
  const window = write ? ADMIN_WRITE_WINDOW_SECONDS : ADMIN_READ_WINDOW_SECONDS;
  const [row] = await db.execute<{ fresh: boolean }>(sql`
    select exists (
      select 1 from public.admin_step_ups
      where session_id = ${session}::uuid and user_id = ${claims.sub}::uuid
        and verified_at <= now() and verified_at > now() - make_interval(secs => ${window})
    ) as fresh`);
  return !!row?.fresh;
}

async function recordCheck(
  db: Database,
  claims: JwtClaims,
  method: "passkey" | "pin",
  verifiedAtSeconds: number,
  proofSession: string | null,
): Promise<Date> {
  const session = sessionOf(claims);
  if (!session)
    throw new ApiError(403, "admin_check_failed", "This sign-in can't take an admin check.");
  const at = new Date(Math.floor(verifiedAtSeconds) * 1000);
  await db.execute(
    sql`delete from public.admin_step_ups where verified_at < now() - interval '1 day'`,
  );
  try {
    await db.execute(sql`
      insert into public.admin_step_ups (session_id, user_id, verified_at, method, proof_session_id)
      values (${session}::uuid, ${claims.sub}::uuid, ${at.toISOString()}::timestamptz, ${method},
              ${proofSession}::uuid)
      on conflict (session_id) do update
        set verified_at = greatest(public.admin_step_ups.verified_at, excluded.verified_at),
            method = excluded.method, proof_session_id = excluded.proof_session_id
        where public.admin_step_ups.user_id = excluded.user_id`);
  } catch {
    // proof_session_id is unique: the same passkey proof for a second session.
    throw new ApiError(403, "admin_check_failed", "That passkey check was already used.");
  }
  return at;
}

/**
 * A passkey check: the app ran Supabase's passkey sign-in on the side and sends its token as
 * proof. It must be this account's, signed by the Auth server, and its passkey sign-in under a
 * minute old. The check's time is the passkey's own, so sending a proof again gains nothing.
 */
export async function recordPasskeyCheck(
  db: Database,
  claims: JwtClaims,
  proof: JwtClaims,
  nowSeconds = Date.now() / 1000,
): Promise<Date> {
  const failed = () =>
    new ApiError(403, "admin_check_failed", "That passkey didn't confirm this account.");
  if (proof.sub !== claims.sub) throw failed();
  const proofSession = sessionOf(proof);
  if (!proofSession || proofSession === sessionOf(claims)) throw failed();
  const at = newestTimestamp(proof, ["passkey"], ADMIN_WRITE_WINDOW_SECONDS, nowSeconds);
  if (at === null) throw failed();
  return recordCheck(db, claims, "passkey", at, proofSession);
}

// --- The admin PIN ----------------------------------------------------------------------------

export const ADMIN_PIN_MAX_FAILURES = 5;
const scrypt = promisify(scryptCb) as (
  password: string,
  salt: Buffer,
  keylen: number,
  options: { N: number; r: number; p: number; maxmem: number },
) => Promise<Buffer>;
const PIN_PARAMS = { N: 2 ** 15, r: 8, p: 1 };

/** Six digits, and not an obvious one: all the same, a run, or a repeated pair or triple. */
export function pinProblem(pin: string): string | null {
  if (!/^\d{6}$/.test(pin)) return "The admin PIN is exactly 6 digits.";
  const d = [...pin].map(Number);
  const steps = new Set(d.slice(1).map((x, i) => (x - d[i]! + 10) % 10));
  if (steps.size === 1 && [0, 1, 9].includes([...steps][0]!))
    return "Pick a less obvious PIN: no repeated digits or runs.";
  if (pin === pin.slice(0, 2).repeat(3) || pin === pin.slice(0, 3).repeat(2))
    return "Pick a less obvious PIN: no repeated patterns.";
  return null;
}

export async function hashPin(pin: string): Promise<string> {
  const salt = randomBytes(16);
  const hash = await scrypt(pin, salt, 32, { ...PIN_PARAMS, maxmem: 64 * 1024 * 1024 });
  const { N, r, p } = PIN_PARAMS;
  return `scrypt$${N}$${r}$${p}$${salt.toString("base64url")}$${hash.toString("base64url")}`;
}

export async function pinMatches(pin: string, stored: string): Promise<boolean> {
  const [kind, n, r, p, salt, hash] = stored.split("$");
  if (kind !== "scrypt" || !salt || !hash) return false;
  const expected = Buffer.from(hash, "base64url");
  const got = await scrypt(pin, Buffer.from(salt, "base64url"), expected.length, {
    N: Number(n),
    r: Number(r),
    p: Number(p),
    maxmem: 64 * 1024 * 1024,
  });
  return got.length === expected.length && timingSafeEqual(got, expected);
}

export interface PinState {
  set: boolean;
  /** Turned off after too many wrong PINs; set a new one. */
  disabled: boolean;
  tries_left: number;
}

export async function pinState(db: Database, userId: string): Promise<PinState> {
  const [row] = await db.execute<{
    pin_hash: string | null;
    failures: number;
    disabled_at: string | null;
  }>(
    sql`select pin_hash, failures, disabled_at from public.admin_pins where user_id = ${userId}::uuid`,
  );
  return {
    set: !!row?.pin_hash,
    disabled: !row?.pin_hash && !!row?.disabled_at,
    tries_left: row?.pin_hash ? ADMIN_PIN_MAX_FAILURES - row.failures : 0,
  };
}

export async function setPin(db: Database, userId: string, pin: string | null): Promise<void> {
  if (pin !== null) {
    const problem = pinProblem(pin);
    if (problem) throw new ApiError(400, "admin_pin_weak", problem);
  }
  const hash = pin === null ? null : await hashPin(pin);
  await db.execute(sql`
    insert into public.admin_pins (user_id, pin_hash, failures, disabled_at, updated_at)
    values (${userId}::uuid, ${hash}, 0, null, now())
    on conflict (user_id) do update
      set pin_hash = excluded.pin_hash, failures = 0, disabled_at = null, updated_at = now()`);
}

/**
 * Checks the PIN and records the check. Wrong tries are counted per account on the server, under
 * a row lock so parallel guesses can't share a count; the fifth wrong one in a row turns the PIN
 * off. Answers whether the PIN was turned off just now, for the owner's email.
 */
export async function checkPin(
  db: Database,
  claims: JwtClaims,
  pin: string,
): Promise<{ ok: true; at: Date } | { ok: false; disabled: boolean; triesLeft: number }> {
  if (!sessionOf(claims))
    throw new ApiError(403, "admin_check_failed", "This sign-in can't take an admin check.");
  const result = await db.transaction(async (tx) => {
    const [row] = await tx.execute<{ pin_hash: string | null; failures: number }>(sql`
      select pin_hash, failures from public.admin_pins where user_id = ${claims.sub}::uuid for update`);
    if (!row?.pin_hash) throw new ApiError(409, "admin_pin_not_set", "No admin PIN is set.");
    if (/^\d{6}$/.test(pin) && (await pinMatches(pin, row.pin_hash))) {
      await tx.execute(
        sql`update public.admin_pins set failures = 0 where user_id = ${claims.sub}::uuid`,
      );
      return { ok: true as const };
    }
    const failures = row.failures + 1;
    const disabled = failures >= ADMIN_PIN_MAX_FAILURES;
    await tx.execute(sql`
      update public.admin_pins
         set failures = ${disabled ? 0 : failures},
             pin_hash = ${disabled ? null : row.pin_hash},
             disabled_at = ${disabled ? sql`now()` : sql`disabled_at`}
       where user_id = ${claims.sub}::uuid`);
    return {
      ok: false as const,
      disabled,
      triesLeft: disabled ? 0 : ADMIN_PIN_MAX_FAILURES - failures,
    };
  });
  if (!result.ok) return result;
  return { ok: true, at: await recordCheck(db, claims, "pin", Date.now() / 1000, null) };
}
