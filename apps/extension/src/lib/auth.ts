/**
 * The few Auth calls the extension makes, straight to the server's Auth service (Supabase Auth,
 * whose address and public key come from the server's /v1/config). No Supabase SDK: it would
 * keep its own copy of the session in storage we don't control.
 */

export interface AuthService {
  authUrl: string;
  anonKey: string;
}

export interface AuthSession {
  access_token: string;
  refresh_token: string;
  expires_in: number;
  user: { id: string; email?: string };
}

export class AuthError extends Error {
  readonly status: number;
  readonly code?: string;
  constructor(message: string, status: number, code?: string) {
    super(message);
    this.status = status;
    this.code = code;
  }
}

/** Plain-language messages for the Auth errors a person can hit here. */
function messageFor(status: number, code: string | undefined, raw: string): string {
  switch (code) {
    case "otp_expired":
      return "That code is wrong or has run out. Ask for a new one.";
    case "otp_disabled":
    case "signup_disabled":
    case "user_not_found":
      return "There's no Casama account with that email on this server. Create one in the app first.";
    case "over_email_send_rate_limit":
    case "over_request_rate_limit":
      return "Too many tries. Wait a minute, then try again.";
    case "refresh_token_not_found":
    case "refresh_token_already_used":
    case "session_not_found":
      return "You were signed out. Sign in again.";
  }
  if (status === 429) return "Too many tries. Wait a minute, then try again.";
  if (status >= 500) return "Sign-in isn't available right now. Try again in a moment.";
  return raw || "Sign-in didn't work. Try again.";
}

async function call<T>(
  svc: AuthService,
  path: string,
  init: { body?: unknown; token?: string; fetch?: typeof fetch; method?: "GET" | "POST" },
): Promise<T> {
  const base = svc.authUrl.replace(/\/+$/, "");
  const res = await (init.fetch ?? fetch)(`${base}/auth/v1${path}`, {
    method: init.method ?? "POST",
    headers: {
      apikey: svc.anonKey,
      authorization: `Bearer ${init.token ?? svc.anonKey}`,
      "content-type": "application/json",
    },
    body: init.body === undefined ? undefined : JSON.stringify(init.body),
    signal: AbortSignal.timeout(20_000),
  });
  const text = await res.text();
  let json: Record<string, unknown> = {};
  try {
    json = text ? (JSON.parse(text) as Record<string, unknown>) : {};
  } catch {
    // Not JSON: an error page from something in front of Auth.
  }
  if (!res.ok) {
    const code = (json.error_code ?? json.code ?? json.error) as string | undefined;
    const raw = (json.msg ?? json.message ?? json.error_description ?? "") as string;
    throw new AuthError(
      messageFor(res.status, typeof code === "string" ? code : undefined, raw),
      res.status,
      typeof code === "string" ? code : undefined,
    );
  }
  return json as T;
}

function checkSession(s: Partial<AuthSession>): AuthSession {
  if (!s.access_token || !s.refresh_token || !s.user?.id)
    throw new AuthError("Sign-in didn't finish. Try again.", 502);
  return { expires_in: 3600, ...s } as AuthSession;
}

/** Finishes a sign-in code: the one-time token the server got for it (type magiclink). */
export async function verifyTokenHash(svc: AuthService, tokenHash: string, f?: typeof fetch) {
  return checkSession(
    await call<AuthSession>(svc, "/verify", {
      body: { type: "magiclink", token_hash: tokenHash },
      fetch: f,
    }),
  );
}

/** Emails a one-time code to an existing account. Never creates one. */
export async function sendEmailCode(svc: AuthService, email: string, f?: typeof fetch) {
  await call(svc, "/otp", { body: { email, create_user: false }, fetch: f });
}

export async function verifyEmailCode(
  svc: AuthService,
  email: string,
  code: string,
  f?: typeof fetch,
) {
  return checkSession(
    await call<AuthSession>(svc, "/verify", {
      body: { type: "email", email, token: code.replace(/\s+/g, "") },
      fetch: f,
    }),
  );
}

export async function refreshSession(svc: AuthService, refreshToken: string, f?: typeof fetch) {
  return checkSession(
    await call<AuthSession>(svc, "/token?grant_type=refresh_token", {
      body: { refresh_token: refreshToken },
      fetch: f,
    }),
  );
}

/** Ends the session: this browser's only (local), or every device's (global, "sign out everywhere"). */
export async function logout(
  svc: AuthService,
  accessToken: string,
  f?: typeof fetch,
  scope: "local" | "global" = "local",
) {
  await call(svc, `/logout?scope=${scope}`, { token: accessToken, fetch: f });
}

/** The sign-in providers (Google, Apple, …) this server's Auth has turned on. */
export async function enabledProviders(svc: AuthService, f?: typeof fetch): Promise<string[]> {
  const settings = await call<{ external?: Record<string, boolean> }>(svc, "/settings", {
    method: "GET",
    fetch: f,
  });
  return Object.entries(settings.external ?? {})
    .filter(([name, on]) => on && name !== "email" && name !== "phone")
    .map(([name]) => name);
}

/** Where Auth sends the browser to sign in with [provider] (PKCE: Auth returns a code, not tokens). */
export function authorizeUrl(
  svc: AuthService,
  provider: string,
  redirectTo: string,
  codeChallenge: string,
): string {
  const q = new URLSearchParams({
    provider,
    redirect_to: redirectTo,
    code_challenge: codeChallenge,
    code_challenge_method: "s256",
  });
  return `${svc.authUrl.replace(/\/+$/, "")}/auth/v1/authorize?${q}`;
}

/** Trades the code a provider sign-in came back with for a session. */
export async function exchangeCode(
  svc: AuthService,
  code: string,
  verifier: string,
  f?: typeof fetch,
) {
  return checkSession(
    await call<AuthSession>(svc, "/token?grant_type=pkce", {
      body: { auth_code: code, code_verifier: verifier },
      fetch: f,
    }),
  );
}

/** A PKCE pair: the verifier stays here, the challenge goes to Auth. */
export async function pkcePair(): Promise<{ verifier: string; challenge: string }> {
  const b64url = (bytes: Uint8Array) =>
    btoa(String.fromCharCode(...bytes))
      .replace(/\+/g, "-")
      .replace(/\//g, "_")
      .replace(/=+$/, "");
  const verifier = b64url(crypto.getRandomValues(new Uint8Array(32)));
  const digest = new Uint8Array(
    await crypto.subtle.digest("SHA-256", new TextEncoder().encode(verifier)),
  );
  return { verifier, challenge: b64url(digest) };
}
