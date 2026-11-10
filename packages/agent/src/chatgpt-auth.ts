/**
 * ChatGPT plan sign-in (SPEC: Model gateway → ChatGPT plan sign-in), following OpenAI's
 * "Sign in with ChatGPT" plan usage for open-source apps (developers.openai.com/siwc):
 * authorization code with S256 PKCE on a loopback redirect, no client secret, a dynamic client
 * on first registration, rotating refresh tokens.
 */
import { createHash, randomBytes } from "node:crypto";

export const CHATGPT_AUTH_URL = "https://auth.openai.com";
export const CHATGPT_RESOURCE = "https://api.openai.com/v1";
/** The scope that grants plan usage; without it the person only signed in. */
export const CHATGPT_PLAN_SCOPE = "chatgpt.tokens.use.direct";
export const CHATGPT_SCOPES = `openid profile email offline_access resource.invoke ${CHATGPT_PLAN_SCOPE}`;
/** First registration: OpenAI issues a client for this person and ChatGPT workspace. */
export const CHATGPT_DYNAMIC_CLIENT = "dynamic_agent_client";

/** Refresh-token errors after which the person must sign in again. */
const DEAD_REFRESH_CODES = new Set([
  "invalid_grant",
  "invalid_refresh_token",
  "token_expired",
  "refresh_token_expired",
  "refresh_token_invalidated",
  "refresh_token_reused",
]);

export interface ChatGptEndpoints {
  authUrl?: string;
  fetch?: typeof fetch;
}

/** What Kasama keeps in Vault for one ChatGPT credential (JSON). */
export interface ChatGptTokens {
  access_token: string;
  refresh_token: string;
  id_token?: string;
  /** The issued client id (refreshes and revocation use it). */
  client_id: string;
  /** Epoch milliseconds. */
  expires_at: number;
  earliest_refresh_at?: number;
  scope?: string;
}

export interface TokenResponse {
  access_token: string;
  refresh_token?: string;
  id_token?: string;
  token_type?: string;
  expires_in?: number;
  scope?: string;
  earliest_refresh_at?: number | string;
}

export class ChatGptAuthError extends Error {
  /** invalid: sign in again; transient: try later; config: Kasama's setup is wrong. */
  readonly kind: "invalid" | "transient" | "config";
  readonly code?: string;
  readonly status?: number;
  constructor(
    message: string,
    kind: "invalid" | "transient" | "config",
    opts: { code?: string; status?: number } = {},
  ) {
    super(message);
    this.kind = kind;
    this.code = opts.code;
    this.status = opts.status;
  }
}

const b64url = (buf: Buffer) => buf.toString("base64url");

export function randomToken(bytes = 32) {
  return b64url(randomBytes(bytes));
}

export function pkcePair() {
  const verifier = randomToken(48);
  const challenge = b64url(createHash("sha256").update(verifier).digest());
  return { verifier, challenge };
}

const base = (ep: ChatGptEndpoints) => (ep.authUrl ?? CHATGPT_AUTH_URL).replace(/\/$/, "");

export function authorizeUrl(
  ep: ChatGptEndpoints,
  p: {
    clientId: string;
    agentName: string;
    hostId: string;
    redirectUri: string;
    state: string;
    nonce: string;
    challenge: string;
    loginHint?: string;
  },
) {
  const q = new URLSearchParams({
    client_id: p.clientId,
    ext_agent_host_id: p.hostId,
    response_type: "code",
    redirect_uri: p.redirectUri,
    scope: CHATGPT_SCOPES,
    resource: CHATGPT_RESOURCE,
    state: p.state,
    nonce: p.nonce,
    code_challenge_method: "S256",
    code_challenge: p.challenge,
  });
  // The product name is sent only on first registration, the same on every install.
  if (p.clientId === CHATGPT_DYNAMIC_CLIENT) q.set("agent_name_hint", p.agentName);
  if (p.loginHint) q.set("login_hint", p.loginHint);
  return `${base(ep)}/api/accounts/authorize?${q}`;
}

async function tokenCall(ep: ChatGptEndpoints, form: Record<string, string>) {
  const f = ep.fetch ?? fetch;
  let res: Response;
  try {
    res = await f(`${base(ep)}/api/accounts/oauth/token`, {
      method: "POST",
      headers: { "content-type": "application/x-www-form-urlencoded", accept: "application/json" },
      body: new URLSearchParams(form),
      signal: AbortSignal.timeout(20_000),
    });
  } catch (err) {
    throw new ChatGptAuthError(
      `Could not reach ChatGPT sign-in: ${(err as Error).message}`,
      "transient",
    );
  }
  const text = await res.text();
  let body: Record<string, unknown> = {};
  try {
    body = JSON.parse(text) as Record<string, unknown>;
  } catch {
    // not JSON
  }
  if (!res.ok) {
    const code =
      typeof body.error === "string"
        ? body.error
        : typeof (body.error as { code?: string })?.code === "string"
          ? (body.error as { code: string }).code
          : undefined;
    const description =
      typeof body.error_description === "string" ? body.error_description : text.slice(0, 200);
    const kind =
      code && DEAD_REFRESH_CODES.has(code)
        ? "invalid"
        : code === "invalid_client"
          ? "config"
          : res.status >= 500 || res.status === 429
            ? "transient"
            : "invalid";
    throw new ChatGptAuthError(
      `ChatGPT sign-in failed (${code ?? res.status}): ${description}`,
      kind,
      {
        code,
        status: res.status,
      },
    );
  }
  if (typeof body.access_token !== "string")
    throw new ChatGptAuthError("ChatGPT sign-in returned no access token", "transient");
  return body as unknown as TokenResponse;
}

export function exchangeCode(
  ep: ChatGptEndpoints,
  p: { clientId: string; code: string; verifier: string; redirectUri: string },
) {
  return tokenCall(ep, {
    grant_type: "authorization_code",
    client_id: p.clientId,
    code: p.code,
    code_verifier: p.verifier,
    redirect_uri: p.redirectUri,
    resource: CHATGPT_RESOURCE,
  });
}

/** Refresh with the issued client id; `scope` is omitted on purpose. */
export function refreshTokens(ep: ChatGptEndpoints, p: { clientId: string; refreshToken: string }) {
  return tokenCall(ep, {
    grant_type: "refresh_token",
    client_id: p.clientId,
    refresh_token: p.refreshToken,
    resource: CHATGPT_RESOURCE,
  });
}

const epochMs = (v: number | string | undefined) => {
  if (v === undefined || v === null || v === "") return undefined;
  if (typeof v === "number") return v < 1e12 ? v * 1000 : v;
  const t = Date.parse(v);
  return Number.isNaN(t) ? undefined : t;
};

/** The Vault record for a token response (a refresh may omit the refresh token or id token). */
export function tokensFrom(
  resp: TokenResponse,
  clientId: string,
  prev?: ChatGptTokens,
  now = Date.now(),
): ChatGptTokens {
  const refresh = resp.refresh_token ?? prev?.refresh_token;
  if (!refresh) throw new ChatGptAuthError("ChatGPT sign-in returned no refresh token", "invalid");
  return {
    access_token: resp.access_token,
    refresh_token: refresh,
    id_token: resp.id_token ?? prev?.id_token,
    client_id: clientId,
    expires_at: now + (resp.expires_in ?? 3600) * 1000,
    earliest_refresh_at: epochMs(resp.earliest_refresh_at),
    scope: resp.scope ?? prev?.scope,
  };
}

export function hasPlanScope(scope: string | undefined) {
  return (scope ?? "").split(/\s+/).includes(CHATGPT_PLAN_SCOPE);
}

const configCache = new Map<string, { at: number; value: Record<string, unknown> }>();

/** OpenAI's OpenID configuration (issuer, jwks_uri, revocation_endpoint), cached for an hour. */
export async function openIdConfig(ep: ChatGptEndpoints): Promise<Record<string, unknown>> {
  const url = `${base(ep)}/.well-known/openid-configuration`;
  const hit = configCache.get(url);
  if (hit && Date.now() - hit.at < 3_600_000) return hit.value;
  const f = ep.fetch ?? fetch;
  const res = await f(url, { signal: AbortSignal.timeout(10_000) });
  if (!res.ok)
    throw new ChatGptAuthError(`OpenID configuration returned ${res.status}`, "transient");
  const value = (await res.json()) as Record<string, unknown>;
  configCache.set(url, { at: Date.now(), value });
  return value;
}

/** Revokes a refresh token. An empty 200 is success. */
export async function revokeToken(ep: ChatGptEndpoints, p: { clientId: string; token: string }) {
  const cfg = await openIdConfig(ep);
  const endpoint =
    typeof cfg.revocation_endpoint === "string"
      ? cfg.revocation_endpoint
      : `${base(ep)}/api/accounts/oauth/revoke`;
  const f = ep.fetch ?? fetch;
  const res = await f(endpoint, {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      token: p.token,
      token_type_hint: "refresh_token",
      client_id: p.clientId,
    }),
    signal: AbortSignal.timeout(15_000),
  });
  if (!res.ok) throw new ChatGptAuthError(`Revocation returned ${res.status}`, "transient");
}
