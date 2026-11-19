/**
 * Sign in with Apple token revocation (D-420, App Store guideline 5.1.1(v)).
 *
 * Supabase Auth signs people in with Apple's ID token (the system sheet) or its own OAuth flow
 * (the browser), and neither leaves the server a token it can revoke. So the app hands over what
 * Apple gave it at sign-in: the sheet's one-time authorization code, which this module swaps for a
 * refresh token at Apple's token endpoint, or the browser flow's refresh token, which it checks
 * with Apple. The refresh token is kept in Vault (public.apple_sign_in_tokens). When the account
 * is deleted it is revoked at https://appleid.apple.com/auth/revoke, which also removes Casama
 * from the person's "Sign in with Apple" list.
 *
 * Every call to Apple carries a client secret: a short-lived ES256 JWT signed with the Sign in with
 * Apple key (APPLE_SIGNIN_KEY_P8, its key id and the team id), for the client id the token was
 * issued to (the app's bundle id for the sheet, the Services ID for the browser).
 *
 * Off (no-ops) unless the key, its id and the team id are set.
 */
import type { Database } from "@casama/db";
import { captureError } from "@casama/observability";
import { sql } from "drizzle-orm";
import { decodeJwt, importPKCS8, SignJWT } from "jose";
import { inlineOrFile } from "../billing/index.ts";

const APPLE = "https://appleid.apple.com";

export interface AppleSignInConfig {
  teamId: string;
  keyId: string;
  /** The .p8 key's PEM. */
  privateKey: string;
  /** The iOS and macOS app's bundle id: the system sheet's codes are issued to it. */
  appId: string;
  /** The Services ID: Supabase Auth's browser sign-in gets its tokens for it. */
  servicesId: string;
  /** Apple's host (tests). */
  baseUrl: string;
  fetch: typeof fetch;
}

/** From the environment (the API's parsed env or the worker's process.env). Null when off. */
export function appleSignInConfig(
  env: Record<string, unknown>,
  fetchImpl: typeof fetch = fetch,
): AppleSignInConfig | null {
  const s = (k: string) => {
    const v = env[k];
    return typeof v === "string" && v.trim() ? v.trim() : undefined;
  };
  const key = s("APPLE_SIGNIN_KEY_P8");
  const keyId = s("APPLE_SIGNIN_KEY_ID");
  const teamId = s("APPLE_SIGNIN_TEAM_ID");
  if (!key || !keyId || !teamId) return null;
  return {
    teamId,
    keyId,
    privateKey: inlineOrFile(key),
    appId: s("APPLE_SIGNIN_APP_ID") ?? "ai.casama.app",
    servicesId: s("APPLE_SIGNIN_SERVICES_ID") ?? "ai.casama.app.signin",
    baseUrl: (s("APPLE_SIGNIN_URL") ?? APPLE).replace(/\/+$/, ""),
    fetch: fetchImpl,
  };
}

/** The client secret Apple asks for on every token call: an ES256 JWT, good for five minutes. */
export async function appleClientSecret(cfg: AppleSignInConfig, clientId: string) {
  const key = await importPKCS8(cfg.privateKey, "ES256");
  const now = Math.floor(Date.now() / 1000);
  return new SignJWT({})
    .setProtectedHeader({ alg: "ES256", kid: cfg.keyId })
    .setIssuer(cfg.teamId)
    .setIssuedAt(now)
    .setExpirationTime(now + 300)
    .setAudience(APPLE)
    .setSubject(clientId)
    .sign(key);
}

export class AppleTokenError extends Error {
  readonly status: number;
  readonly code?: string;
  constructor(message: string, status: number, code?: string) {
    super(message);
    this.status = status;
    this.code = code;
  }
}

async function postForm(cfg: AppleSignInConfig, path: string, form: Record<string, string>) {
  const res = await cfg.fetch(`${cfg.baseUrl}${path}`, {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded", accept: "application/json" },
    body: new URLSearchParams(form).toString(),
    signal: AbortSignal.timeout(15_000),
  });
  const text = await res.text();
  let body: Record<string, unknown> = {};
  try {
    body = text ? (JSON.parse(text) as Record<string, unknown>) : {};
  } catch {
    // Apple answers revoke with an empty body.
  }
  if (!res.ok) {
    const code = typeof body.error === "string" ? body.error : undefined;
    throw new AppleTokenError(
      `Apple answered ${res.status}${code ? ` (${code})` : ""}`,
      res.status,
      code,
    );
  }
  return body;
}

/** Apple's user id from the id_token Apple just sent us over TLS (not verified again here). */
function subOf(idToken: unknown): string | null {
  if (typeof idToken !== "string") return null;
  try {
    const sub = decodeJwt(idToken).sub;
    return typeof sub === "string" && sub ? sub : null;
  } catch {
    return null;
  }
}

/**
 * Swaps the system sheet's authorization code for a refresh token (client id: the app). Returns the
 * refresh token and Apple's user id.
 */
export async function exchangeAppleCode(cfg: AppleSignInConfig, code: string) {
  const body = await postForm(cfg, "/auth/token", {
    client_id: cfg.appId,
    client_secret: await appleClientSecret(cfg, cfg.appId),
    code,
    grant_type: "authorization_code",
  });
  const refresh = typeof body.refresh_token === "string" ? body.refresh_token : null;
  const sub = subOf(body.id_token);
  if (!refresh || !sub) throw new AppleTokenError("Apple sent no refresh token", 502);
  return { refreshToken: refresh, sub, clientId: cfg.appId };
}

/**
 * Checks a refresh token from the browser sign-in (client id: the Services ID) and returns Apple's
 * user id. Apple lets a refresh token be checked about once a day, which a sign-in is.
 */
export async function checkAppleRefreshToken(cfg: AppleSignInConfig, refreshToken: string) {
  const body = await postForm(cfg, "/auth/token", {
    client_id: cfg.servicesId,
    client_secret: await appleClientSecret(cfg, cfg.servicesId),
    refresh_token: refreshToken,
    grant_type: "refresh_token",
  });
  const sub = subOf(body.id_token);
  if (!sub) throw new AppleTokenError("Apple sent no id token", 502);
  return { refreshToken, sub, clientId: cfg.servicesId };
}

/** Revokes one refresh token. Throws on anything but 200. */
export async function revokeAppleToken(
  cfg: AppleSignInConfig,
  clientId: string,
  refreshToken: string,
) {
  await postForm(cfg, "/auth/revoke", {
    client_id: clientId,
    client_secret: await appleClientSecret(cfg, clientId),
    token: refreshToken,
    token_type_hint: "refresh_token",
  });
}

/** True when [sub] is the person's Apple identity in Supabase Auth. */
export async function isAppleIdentity(db: Database, userId: string, sub: string) {
  const [t] = await db.execute<{ t: string | null }>(
    sql`select to_regclass('auth.identities')::text as t`,
  );
  if (!t?.t) return false;
  const rows = await db.execute<{ ok: number }>(sql`
    select 1 as ok from auth.identities
    where user_id = ${userId}::uuid and provider = 'apple' and provider_id = ${sub} limit 1`);
  return rows.length > 0;
}

/** Keeps the person's refresh token for [clientId], replacing an older one. */
export async function saveAppleToken(
  db: Database,
  userId: string,
  t: { clientId: string; sub: string; refreshToken: string },
) {
  await db.transaction(async (tx) => {
    const [s] = await tx.execute<{ id: string }>(
      sql`select vault.create_secret(${t.refreshToken}, null, 'sign in with apple') as id`,
    );
    await tx.execute(sql`
      insert into public.apple_sign_in_tokens (user_id, client_id, apple_sub, vault_secret_id)
      values (${userId}::uuid, ${t.clientId}, ${t.sub}, ${s?.id}::uuid)
      on conflict (user_id, client_id) do update
        set apple_sub = excluded.apple_sub, vault_secret_id = excluded.vault_secret_id, updated_at = now()`);
  });
}

type Log = (msg: string, extra?: Record<string, unknown>) => void;

/**
 * Revokes every Apple token kept for the person. Never throws: a failure is logged and reported.
 * A revoked token's row goes (and its Vault secret with it). With [forget], rows whose revoke
 * failed go too (the purge: nothing of the account may stay); otherwise they stay for the purge
 * to try again. Returns how many were revoked.
 */
export async function revokeAppleTokens(
  db: Database,
  cfg: AppleSignInConfig | null,
  userId: string,
  opts: { forget?: boolean; log?: Log } = {},
) {
  let revoked = 0;
  try {
    const rows = await db.execute<{ client_id: string; token: string | null }>(sql`
      select t.client_id, v.decrypted_secret as token
      from public.apple_sign_in_tokens t left join vault.decrypted_secrets v on v.id = t.vault_secret_id
      where t.user_id = ${userId}::uuid`);
    for (const r of rows) {
      let done = false;
      if (r.token && cfg) {
        try {
          await revokeAppleToken(cfg, r.client_id, r.token);
          done = true;
          revoked++;
        } catch (e) {
          // invalid_grant: the token is already revoked or expired, so nothing is left to revoke.
          if (e instanceof AppleTokenError && e.code === "invalid_grant") done = true;
          else {
            opts.log?.("apple token not revoked", {
              user_id: userId,
              client_id: r.client_id,
              error: (e as Error).message,
            });
            captureError(e, { step: "apple-revoke", user_id: userId, client_id: r.client_id });
          }
        }
      } else if (!cfg) {
        opts.log?.(
          "apple token not revoked: APPLE_SIGNIN_KEY_P8, APPLE_SIGNIN_KEY_ID and APPLE_SIGNIN_TEAM_ID are not set",
          {
            user_id: userId,
          },
        );
      } else done = true; // the secret is gone: nothing to revoke
      if (done || opts.forget)
        await db.execute(sql`
          delete from public.apple_sign_in_tokens where user_id = ${userId}::uuid and client_id = ${r.client_id}`);
    }
  } catch (e) {
    opts.log?.("apple tokens not revoked", { user_id: userId, error: (e as Error).message });
    captureError(e, { step: "apple-revoke", user_id: userId });
  }
  return revoked;
}
