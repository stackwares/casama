/**
 * Signing in and out, and keeping an access token fresh (plan §9.2). Three ways in, none of which
 * types a password into the extension:
 *
 * 1. The web app hands over a sign-in link (background/handover.ts), redeemed with [signInWithLink].
 * 2. A sign-in link or code pasted from "Sign In on Another Device" in any Casama app: the same.
 * 3. An emailed one-time code: [sendEmailCode], then [signInWithEmailCode].
 * 4. Google, Apple or another provider the server's Auth has on: [signInWithProvider], in a
 *    window the browser owns (identity.launchWebAuthFlow), so the password goes to the provider
 *    and never through the extension.
 *
 * Works from the service worker and from extension pages alike; storage.ts's lock keeps them from
 * racing on a refresh.
 */

import { CasamaError, createCasamaClient, type Schemas } from "@casama/client";
import {
  type AuthService,
  type AuthSession,
  authorizeUrl,
  enabledProviders,
  exchangeCode,
  logout,
  pkcePair,
  refreshSession,
  sendEmailCode as sendCode,
  verifyEmailCode,
  verifyTokenHash,
} from "./auth.ts";
import { browserName, FEATURES } from "./browser.ts";
import { InputError, normalizeServer, parseSignInLink, serverLabel } from "./servers.ts";
import {
  type Account,
  accountId,
  getLocal,
  getSession,
  updateLocal,
  updateSession,
  withLock,
} from "./store.ts";

/** The server (or its Auth service) didn't answer: offline, wrong address, or it doesn't allow the extension yet. */
export class UnreachableError extends Error {
  readonly url: string;
  constructor(url: string) {
    super(`Can't reach ${serverLabel(url)}.`);
    this.url = url;
  }
}

let fetchImpl: typeof fetch = (...args) => fetch(...args);
/** Tests swap in a fake fetch. */
export function setFetch(f: typeof fetch) {
  fetchImpl = f;
}

/** fetch that turns a network failure into [UnreachableError] for the address it was going to. */
const reaching =
  (base: string): typeof fetch =>
  async (input, init) => {
    try {
      return await fetchImpl(input, init);
    } catch (e) {
      if ((e as Error).name === "AbortError") throw e;
      // A timeout (TimeoutError) means it didn't answer: unreachable too.
      throw new UnreachableError(base);
    }
  };

export function publicClient(server: string) {
  return createCasamaClient({ apiUrl: server, fetch: reaching(server) });
}

/** A client signed in as [account], refreshing its token as needed. */
export function clientFor(account: Account) {
  return createCasamaClient({
    apiUrl: account.server,
    fetch: reaching(account.server),
    getToken: () => accessToken(account.id),
  });
}

/** The server's Auth address and key. Throws when it can't make sign-in codes and [needCodes]. */
export async function serverAuth(server: string, needCodes = false): Promise<AuthService> {
  const api = publicClient(server);
  let config: Schemas["PublicConfig"];
  try {
    config = await api.unwrap(api.GET("/v1/config"));
  } catch (e) {
    if (e instanceof CasamaError && e.status === 404)
      throw new InputError(`${serverLabel(server)} isn't a Casama server.`);
    throw e;
  }
  if (needCodes && config.sign_in_codes === false)
    throw new InputError(
      `${serverLabel(server)} can't make sign-in codes. Use an email code instead.`,
    );
  return { authUrl: config.supabase_url, anonKey: config.supabase_anon_key };
}

const authReaching = (svc: AuthService) => reaching(svc.authUrl);

function deviceName(): string {
  const nav = navigator as Navigator & { userAgentData?: { platform?: string } };
  const platform = nav.userAgentData?.platform || "";
  return platform ? `${browserName()} on ${platform}` : browserName();
}

async function saveSession(
  server: string,
  svc: AuthService,
  s: AuthSession,
  opts: { activate: boolean },
): Promise<Account> {
  const id = accountId(server, s.user.id);
  let saved!: Account;
  await updateLocal((state) => {
    const old = state.accounts.find((a) => a.id === id);
    saved = {
      id,
      server,
      authUrl: svc.authUrl,
      anonKey: svc.anonKey,
      userId: s.user.id,
      email: s.user.email ?? old?.email ?? "",
      refreshToken: s.refresh_token,
      orgId: old?.orgId,
      deviceToken: old?.deviceToken,
      addedAt: old?.addedAt ?? new Date().toISOString(),
    };
    state.accounts = [...state.accounts.filter((a) => a.id !== id), saved];
    // Only a new sign-in switches accounts; a refresh in the background never does.
    if (opts.activate) state.activeAccountId = id;
  });
  await updateSession((state) => {
    state.tokens[id] = { token: s.access_token, expiresAt: Date.now() + s.expires_in * 1000 };
  });
  return saved;
}

/**
 * Routes 1 and 2: a sign-in link (or a bare code, with [fallbackServer]). The server trades the
 * code for a one-time Auth token; Auth's verify turns that into this browser's own session.
 */
export async function signInWithLink(
  input: string,
  opts: { fallbackServer?: string; allowedServers?: string[] } = {},
): Promise<Account> {
  const link = parseSignInLink(input);
  const server = link.server ?? (opts.fallbackServer && normalizeServer(opts.fallbackServer));
  if (!server) throw new InputError("Enter the server this code is for.");
  if (opts.allowedServers && !opts.allowedServers.includes(server))
    throw new InputError(
      `This sign-in is for ${serverLabel(server)}, which can't sign in this way.`,
    );
  const svc = await serverAuth(server, true);
  const api = publicClient(server);
  let redeemed: Schemas["RedeemedSignInCode"];
  try {
    redeemed = await api.unwrap(
      api.POST("/v1/auth/pairing-codes/redeem", {
        body: { code: link.code, device_name: deviceName() },
      }),
    );
  } catch (e) {
    if (e instanceof CasamaError && e.status === 404)
      throw new InputError("That code isn't valid any more. Show a new one in the app.");
    throw e;
  }
  const session = await verifyTokenHash(svc, redeemed.token_hash, authReaching(svc));
  return saveSession(server, svc, session, { activate: true });
}

/** Route 3, first step: email a one-time code to an existing account on [server]. */
export async function sendEmailCode(serverInput: string, email: string): Promise<string> {
  const server = normalizeServer(serverInput);
  const address = email.trim();
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(address))
    throw new InputError("Enter your email address.");
  const svc = await serverAuth(server);
  await sendCode(svc, address, authReaching(svc));
  return server;
}

/** Route 3, second step. */
export async function signInWithEmailCode(
  server: string,
  email: string,
  code: string,
): Promise<Account> {
  if (!/^\d{6,10}$/.test(code.replace(/\s+/g, "")))
    throw new InputError("Enter the code from the email.");
  const svc = await serverAuth(server);
  const session = await verifyEmailCode(svc, email.trim(), code, authReaching(svc));
  return saveSession(server, svc, session, { activate: true });
}

/** The providers [server] signs in with, best first; empty when it has none or can't say. */
export async function serverProviders(serverInput: string): Promise<string[]> {
  if (!FEATURES.providerSignIn || !chrome.identity?.launchWebAuthFlow) return [];
  const server = normalizeServer(serverInput);
  const svc = await serverAuth(server);
  const on = await enabledProviders(svc, authReaching(svc));
  const order = ["google", "apple"];
  return [...order.filter((p) => on.includes(p)), ...on.filter((p) => !order.includes(p)).sort()];
}

/** Route 4: sign in with [provider] on [serverInput]. */
export async function signInWithProvider(serverInput: string, provider: string): Promise<Account> {
  const server = normalizeServer(serverInput);
  const svc = await serverAuth(server);
  const redirect = chrome.identity.getRedirectURL("auth");
  const { verifier, challenge } = await pkcePair();
  let back: string | undefined;
  try {
    back = await chrome.identity.launchWebAuthFlow({
      url: authorizeUrl(svc, provider, redirect, challenge),
      interactive: true,
    });
  } catch {
    // Closed by the person, or the server sent the window somewhere other than back here.
    throw new InputError(
      `Sign-in didn't come back. If the window ended on another page, ${serverLabel(server)} doesn't allow this browser's sign-in yet: use an email code instead.`,
    );
  }
  const url = new URL(back ?? redirect);
  const params = new URLSearchParams(url.search || url.hash.slice(1));
  const err = params.get("error_description") ?? params.get("error");
  if (err) throw new InputError(err.replace(/\+/g, " "));
  const code = params.get("code");
  if (!code) throw new InputError("Sign-in didn't finish. Try again.");
  const session = await exchangeCode(svc, code, verifier, authReaching(svc));
  return saveSession(server, svc, session, { activate: true });
}

const EARLY_MS = 60_000;

/**
 * A current access token for [id], refreshed when it has less than a minute left. Returns null
 * when the account is gone or its sign-in was ended elsewhere (it is then removed here too).
 */
export async function accessToken(id: string): Promise<string | null> {
  const cached = (await getSession()).tokens[id];
  if (cached && cached.expiresAt - Date.now() > EARLY_MS) return cached.token;
  return withLock(`refresh ${id}`, async () => {
    // Someone else may have refreshed it while this waited.
    const again = (await getSession()).tokens[id];
    if (again && again.expiresAt - Date.now() > EARLY_MS) return again.token;
    const account = (await getLocal()).accounts.find((a) => a.id === id);
    if (!account) return null;
    const svc = { authUrl: account.authUrl, anonKey: account.anonKey };
    let s: AuthSession;
    try {
      s = await refreshSession(svc, account.refreshToken, authReaching(svc));
    } catch (e) {
      // A refused refresh token means the session ended (signed out everywhere, password changed).
      if (!(e instanceof UnreachableError) && (e as { status?: number }).status === 400) {
        await forgetLocked(id);
        return null;
      }
      throw e;
    }
    await saveSession(account.server, svc, s, { activate: false });
    return s.access_token;
  });
}

/** Forgets [id] here. Callers hold the account's refresh lock. */
async function forgetLocked(id: string) {
  await updateLocal((state) => {
    state.accounts = state.accounts.filter((a) => a.id !== id);
    if (state.activeAccountId === id) state.activeAccountId = state.accounts[0]?.id ?? null;
  });
  await updateSession((state) => {
    delete state.tokens[id];
  });
}

/** Forgets [id] under its refresh lock, so a refresh in flight can't bring it back. */
const forget = (id: string) => withLock(`refresh ${id}`, () => forgetLocked(id));

/**
 * Signs [id] out: ends the session at Auth (refreshing first when the access token ran out, as it
 * has after Chrome restarts), and always forgets it here, even when Auth can't be reached.
 */
export async function signOut(id: string): Promise<void> {
  const account = (await getLocal()).accounts.find((a) => a.id === id);
  if (account) {
    const token = await accessToken(id).catch(() => null);
    const svc = { authUrl: account.authUrl, anonKey: account.anonKey };
    // This browser stops taking that account's notifications.
    if (token && account.deviceToken)
      await fetchImpl(
        `${account.authUrl}/rest/v1/devices?fcm_token=eq.${encodeURIComponent(account.deviceToken)}`,
        {
          method: "DELETE",
          headers: { apikey: account.anonKey, authorization: `Bearer ${token}` },
          signal: AbortSignal.timeout(10_000),
        },
      ).catch(() => {});
    if (token) await logout(svc, token, authReaching(svc)).catch(() => {});
  }
  await forget(id);
}

export async function switchAccount(id: string) {
  await updateLocal((state) => {
    if (state.accounts.some((a) => a.id === id)) state.activeAccountId = id;
  });
}

export async function chooseWorkspace(id: string, orgId: string) {
  await updateLocal((state) => {
    const a = state.accounts.find((x) => x.id === id);
    if (a) a.orgId = orgId;
  });
}
