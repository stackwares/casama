/**
 * Casama Cloud abuse controls (SPEC: Phase 8 launch items; D-094): the sign-up gate (Firebase App
 * Check or a proof-of-work puzzle), and suspending workspaces.
 */
import { createHash, createHmac, randomBytes, timingSafeEqual } from "node:crypto";
import type { Database } from "@casama/db";
import { sql } from "drizzle-orm";
import { createRemoteJWKSet, jwtVerify } from "jose";
import type { Env } from "../env.ts";

/** On for Casama Cloud (billing on) unless turned off; self-hosted servers keep it off. */
export function abuseControlsOn(env: Pick<Env, "ABUSE_CONTROLS" | "BILLING_ENABLED">) {
  if (env.ABUSE_CONTROLS === "on") return true;
  if (env.ABUSE_CONTROLS === "off") return false;
  return env.BILLING_ENABLED;
}

export function signupProofKinds(env: Pick<Env, "SIGNUP_PROOFS">) {
  return env.SIGNUP_PROOFS.split(",")
    .map((s) => s.trim())
    .filter((s): s is "app_check" | "pow" => s === "app_check" || s === "pow");
}

// --- proof of work ---------------------------------------------------------------------------

const mac = (secret: string, payload: string) =>
  createHmac("sha256", secret).update(payload).digest("base64url").slice(0, 22);

/** A stateless, signed challenge: `v1.<difficulty>.<expires ms>.<random>.<mac>`. */
export function newChallenge(
  secret: string,
  difficulty: number,
  now = Date.now(),
  ttlMs = 600_000,
) {
  const exp = now + ttlMs;
  const rand = randomBytes(12).toString("base64url");
  const payload = `v1.${difficulty}.${exp}.${rand}`;
  return { challenge: `${payload}.${mac(secret, payload)}`, difficulty, expires_at: new Date(exp) };
}

/** Leading zero bits of a digest. */
export function leadingZeroBits(digest: Buffer) {
  let bits = 0;
  for (const byte of digest) {
    if (byte === 0) {
      bits += 8;
      continue;
    }
    bits += Math.clz32(byte) - 24;
    break;
  }
  return bits;
}

/** sha256(`<challenge>:<nonce>`) must start with `difficulty` zero bits. */
export function verifyPow(secret: string, challenge: string, nonce: string, now = Date.now()) {
  const parts = challenge.split(".");
  if (parts.length !== 5 || parts[0] !== "v1")
    return { ok: false, reason: "bad_challenge" } as const;
  const [, d, exp, rand, sig] = parts as [string, string, string, string, string];
  const expected = Buffer.from(mac(secret, `v1.${d}.${exp}.${rand}`));
  const got = Buffer.from(sig);
  if (got.length !== expected.length || !timingSafeEqual(got, expected))
    return { ok: false, reason: "bad_challenge" } as const;
  if (Number(exp) < now) return { ok: false, reason: "expired" } as const;
  if (nonce.length === 0 || nonce.length > 64) return { ok: false, reason: "bad_nonce" } as const;
  const digest = createHash("sha256").update(`${challenge}:${nonce}`).digest();
  if (leadingZeroBits(digest) < Number(d)) return { ok: false, reason: "not_solved" } as const;
  return { ok: true } as const;
}

/** Records a solved challenge; false when it was already used. */
export async function useChallenge(db: Database, challenge: string) {
  const hash = createHash("sha256").update(challenge).digest("hex");
  const rows = await db.execute<{ challenge_hash: string }>(sql`
    insert into public.used_signup_challenges (challenge_hash) values (${hash})
    on conflict do nothing returning challenge_hash`);
  return rows.length === 1;
}

// --- Firebase App Check ----------------------------------------------------------------------

const jwks = new Map<string, ReturnType<typeof createRemoteJWKSet>>();

/** Verifies an App Check token (RS256 JWT) for the given Firebase project number. */
export async function verifyAppCheck(
  token: string,
  opts: { projectNumber: string; jwksUrl: string; issuerBase?: string },
) {
  let set = jwks.get(opts.jwksUrl);
  if (!set) {
    set = createRemoteJWKSet(new URL(opts.jwksUrl));
    jwks.set(opts.jwksUrl, set);
  }
  const issuer = `${opts.issuerBase ?? "https://firebaseappcheck.googleapis.com"}/${opts.projectNumber}`;
  const { payload } = await jwtVerify(token, set, {
    issuer,
    audience: `projects/${opts.projectNumber}`,
    algorithms: ["RS256"],
  });
  return { appId: typeof payload.sub === "string" ? payload.sub : null };
}

// --- suspension ------------------------------------------------------------------------------

export interface SuspendDeps {
  db: Database;
  /** Stops a running computer (keeps its files). */
  stopComputer?: (computerId: string) => Promise<void>;
}

/** Suspends a workspace: no runs, no computers; data kept. Idempotent. */
export async function suspendOrg(
  deps: SuspendDeps,
  orgId: string,
  reason: string,
  by: { kind: "user" | "system"; id?: string },
) {
  const [row] = await deps.db.execute<{ id: string }>(sql`
    update public.organizations set suspended_at = coalesce(suspended_at, now()), suspended_reason = ${reason}
    where id = ${orgId}::uuid returning id`);
  if (!row) return false;
  await deps.db.execute(sql`
    update public.runs set cancel_requested_at = coalesce(cancel_requested_at, now())
    where org_id = ${orgId}::uuid and status in ('queued', 'running', 'waiting_approval', 'waiting_takeover')`);
  const computers = await deps.db.execute<{ id: string }>(sql`
    select id from public.computers where org_id = ${orgId}::uuid and kind <> 'local' and state in ('running', 'idle', 'starting', 'provisioning')`);
  for (const c of computers) await deps.stopComputer?.(c.id).catch(() => {});
  await deps.db.execute(sql`
    insert into public.abuse_events (org_id, kind, detail, action)
    values (${orgId}::uuid, 'suspended', ${JSON.stringify({ reason, by: by.kind, user_id: by.id ?? null })}::jsonb, 'workspace_suspended')`);
  await deps.db.execute(sql`
    insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id, metadata)
    values (${orgId}::uuid, ${by.kind}, ${by.id ?? null}::uuid, 'org.suspended', 'organization', ${orgId}::uuid, ${JSON.stringify({ reason })}::jsonb)`);
  return true;
}

export async function unsuspendOrg(db: Database, orgId: string, userId: string) {
  const [row] = await db.execute<{ id: string }>(sql`
    update public.organizations set suspended_at = null, suspended_reason = null
    where id = ${orgId}::uuid returning id`);
  if (!row) return false;
  await db.execute(sql`
    insert into public.abuse_events (org_id, kind, detail, action)
    values (${orgId}::uuid, 'unsuspended', ${JSON.stringify({ user_id: userId })}::jsonb, 'recorded')`);
  await db.execute(sql`
    insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id, metadata)
    values (${orgId}::uuid, 'user', ${userId}::uuid, 'org.unsuspended', 'organization', ${orgId}::uuid, '{}'::jsonb)`);
  return true;
}
