/**
 * Checks an ID token from the native Apple or Google sign-in sheet (docs/WAITLIST-PLAN.md §7.3), so
 * an invite code can be claimed for the address inside it before the app signs in with the same
 * token. That is how an Apple "Hide My Email" address gets past the waitlist gate.
 *
 * The checks are the ones Supabase Auth makes when the app then signs in (token_oidc.go): the
 * signature against the provider's published keys, the issuer, the expiry, an audience Auth
 * accepts, and the nonce: the app requests the token with sha256(raw nonce) for both Apple and
 * Google, so the token's `nonce` must be the SHA-256 hex of the raw nonce it sends, and a token
 * with a nonce needs one sent (Auth: "Passed nonce and nonce in id_token should either both exist
 * or not").
 *
 * Keys are cached for as long as the provider's Cache-Control says (an hour when it doesn't), and
 * fetched again when a token names a key that isn't in the cache (providers rotate keys), at most
 * once every 30 seconds.
 */
import { createHash } from "node:crypto";
import { createLocalJWKSet, decodeProtectedHeader, type JSONWebKeySet, jwtVerify } from "jose";

export type IdTokenProvider = "apple" | "google";

const ISSUERS: Record<IdTokenProvider, string[]> = {
  apple: ["https://appleid.apple.com"],
  google: ["https://accounts.google.com", "accounts.google.com"],
};

export const JWKS_URLS: Record<IdTokenProvider, string> = {
  apple: "https://appleid.apple.com/auth/keys",
  google: "https://www.googleapis.com/oauth2/v3/certs",
};

const DEFAULT_MAX_AGE_S = 3600;
const MIN_MAX_AGE_S = 60;
const MAX_MAX_AGE_S = 86_400;
const REFETCH_COOLDOWN_MS = 30_000;

export class IdTokenError extends Error {
  /** bad_token: the token or its nonce doesn't pass. unconfigured: this server takes no such tokens. */
  readonly reason: "bad_token" | "unconfigured" | "keys_unavailable";
  constructor(reason: IdTokenError["reason"], message: string) {
    super(message);
    this.reason = reason;
  }
}

/** A JWKS fetch: the keys and how long they may be kept. */
export async function fetchJwks(
  url: string,
  fetchImpl: typeof fetch = fetch,
): Promise<{ keys: JSONWebKeySet; maxAgeS: number }> {
  const res = await fetchImpl(url, { headers: { accept: "application/json" } });
  if (!res.ok) throw new Error(`JWKS ${url} answered ${res.status}`);
  const keys = (await res.json()) as JSONWebKeySet;
  if (!keys || !Array.isArray(keys.keys)) throw new Error(`JWKS ${url} has no keys`);
  const m = /max-age=(\d+)/i.exec(res.headers.get("cache-control") ?? "");
  const age = m ? Number(m[1]) : DEFAULT_MAX_AGE_S;
  return { keys, maxAgeS: Math.min(MAX_MAX_AGE_S, Math.max(MIN_MAX_AGE_S, age)) };
}

export interface VerifiedIdToken {
  email: string;
  /** Apple's Hide My Email address. */
  privateRelay: boolean;
}

export class IdTokenVerifier {
  private cache = new Map<
    string,
    { keys: JSONWebKeySet; expires: number; fetchedAt: number; kids: Set<string> }
  >();

  private opts: {
    audiences: Record<IdTokenProvider, string[]>;
    fetch?: typeof fetch;
    now?: () => number;
  };

  constructor(opts: IdTokenVerifier["opts"]) {
    this.opts = opts;
  }

  private async keys(provider: IdTokenProvider, kid: string | undefined) {
    const url = JWKS_URLS[provider];
    const now = (this.opts.now ?? Date.now)();
    const hit = this.cache.get(url);
    if (hit && hit.expires > now) {
      const unknownKid = !!kid && !hit.kids.has(kid);
      if (!unknownKid || now - hit.fetchedAt < REFETCH_COOLDOWN_MS) return hit.keys;
    }
    try {
      const got = await fetchJwks(url, this.opts.fetch);
      const kids = new Set(got.keys.keys.map((k) => k.kid).filter((k): k is string => !!k));
      this.cache.set(url, {
        keys: got.keys,
        expires: now + got.maxAgeS * 1000,
        fetchedAt: now,
        kids,
      });
      return got.keys;
    } catch (err) {
      // Keys kept from before still work while the provider can't be reached.
      if (hit) return hit.keys;
      throw new IdTokenError("keys_unavailable", (err as Error).message);
    }
  }

  async verify(
    provider: IdTokenProvider,
    token: string,
    rawNonce?: string | null,
  ): Promise<VerifiedIdToken> {
    const audience = this.opts.audiences[provider].filter(Boolean);
    if (!audience.length)
      throw new IdTokenError("unconfigured", `This server doesn't take ${provider} sign-ins`);
    let kid: string | undefined;
    try {
      kid = decodeProtectedHeader(token).kid;
    } catch {
      throw new IdTokenError("bad_token", "Not a sign-in token");
    }
    const jwks = createLocalJWKSet(await this.keys(provider, kid));
    let payload: Record<string, unknown>;
    try {
      ({ payload } = await jwtVerify(token, jwks, {
        issuer: ISSUERS[provider],
        audience,
        algorithms: ["RS256", "ES256"],
        clockTolerance: 60,
        currentDate: this.opts.now ? new Date(this.opts.now()) : undefined,
      }));
    } catch (err) {
      throw new IdTokenError("bad_token", (err as Error).message);
    }
    const claimed = typeof payload.nonce === "string" ? payload.nonce : null;
    if (rawNonce) {
      const hashed = createHash("sha256").update(rawNonce).digest("hex");
      if (claimed !== hashed) throw new IdTokenError("bad_token", "The nonce doesn't match");
    } else if (claimed) {
      throw new IdTokenError("bad_token", "The token has a nonce, but none was sent");
    }
    const email = typeof payload.email === "string" ? payload.email.trim().toLowerCase() : "";
    if (!email) throw new IdTokenError("bad_token", "The token carries no email address");
    // Google marks addresses it hasn't checked; Apple's are always checked (sent as "true" or true).
    const verified = payload.email_verified;
    if (provider === "google" && verified !== true && verified !== "true")
      throw new IdTokenError("bad_token", "The token's email address isn't verified");
    const relay = payload.is_private_email === true || payload.is_private_email === "true";
    return { email, privateRelay: relay };
  }
}

/**
 * The audiences Casama's own Auth accepts: Apple's are the app's bundle id (the system sheet) and
 * the Services ID (the browser), the same two Auth is given in GOTRUE_EXTERNAL_APPLE_CLIENT_ID;
 * Google's are GOOGLE_AUTH_CLIENT_ID (the web client, which Android tokens are issued to, and the
 * iOS client), the same list Auth gets.
 */
export function idTokenAudiences(env: {
  APPLE_SIGNIN_APP_ID?: string;
  APPLE_SIGNIN_SERVICES_ID?: string;
  GOOGLE_AUTH_CLIENT_ID?: string;
}): Record<IdTokenProvider, string[]> {
  const list = (s?: string) =>
    (s ?? "")
      .split(",")
      .map((x) => x.trim())
      .filter(Boolean);
  return {
    apple: [...list(env.APPLE_SIGNIN_APP_ID), ...list(env.APPLE_SIGNIN_SERVICES_ID)],
    google: list(env.GOOGLE_AUTH_CLIENT_ID),
  };
}
