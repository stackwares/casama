/**
 * What the extension keeps, and where (plan §9.2):
 *
 * - `chrome.storage.session` (memory only, gone when Chrome quits, extension pages only): access
 *   tokens, and a sign-in handed over from the web app while the first-run screen is still open.
 * - `chrome.storage.local` (on disk, extension pages only): accounts with their refresh tokens,
 *   the chosen workspace, the first-run agreement, cached remote settings.
 * - `chrome.storage.sync`: never. It would copy sign-ins to every computer the person uses.
 *
 * Page scripts can't reach `chrome.storage` at all. Content scripts (none yet) could read local
 * storage by default, so both areas are limited to trusted contexts where Chrome allows it.
 *
 * Changes go through a Web Lock, which the service worker and every extension page share, so two
 * of them never refresh the same token or write over each other.
 */

export interface Account {
  /** `${server} ${userId}`: one sign-in per person per server. */
  id: string;
  /** The server's API address. */
  server: string;
  /** The server's Auth address and public key, from its /v1/config. */
  authUrl: string;
  anonKey: string;
  userId: string;
  email: string;
  refreshToken: string;
  /** The workspace picked in this browser; the first one when unset. */
  orgId?: string;
  /** Set once the browser registers as a device (Phase 1 push, Phase 3 pairing). */
  deviceToken?: string;
  addedAt: string;
}

export interface Consent {
  /** Bumped when what the extension sends changes; a new version asks again. */
  version: number;
  at: string;
}

export interface LocalState {
  accounts: Account[];
  activeAccountId: string | null;
  consent: Consent | null;
  /** Remote settings per server, as last fetched. */
  remoteConfig: Record<string, { fetchedAt: number; config: unknown }>;
  /** Sites each server adds to the guard (D-374), as last fetched. */
  guardSites: Record<string, { fetchedAt: number; hosts: unknown }>;
}

export interface AccessToken {
  token: string;
  /** Epoch milliseconds. */
  expiresAt: number;
}

export interface SessionState {
  tokens: Record<string, AccessToken>;
  /**
   * A sign-in link from the web app, waiting for the first-run agreement, with the servers the
   * page that sent it may sign in to (absent: any, for a local web app in the dev build).
   */
  pendingHandover: { link: string; at: number; allowedServers?: string[] } | null;
}

const LOCAL_DEFAULTS: LocalState = {
  accounts: [],
  activeAccountId: null,
  consent: null,
  remoteConfig: {},
  guardSites: {},
};
const SESSION_DEFAULTS: SessionState = { tokens: {}, pendingHandover: null };

let restricted = false;
/** Tests start each case from scratch. */
export function resetStoreForTests() {
  restricted = false;
}
/**
 * Keeps both areas away from content scripts. Current Chrome accepts it for both (checked in
 * Chromium 159 by the end-to-end harness); an older one that refuses it for local storage still
 * keeps it from page scripts, and only the refresh token is kept there.
 */
export async function restrictStorage(): Promise<boolean> {
  if (restricted) return localRestricted;
  restricted = true;
  const level = "TRUSTED_CONTEXTS" as chrome.storage.AccessLevel;
  for (const area of [chrome.storage.session, chrome.storage.local]) {
    try {
      await area.setAccessLevel({ accessLevel: level });
      if (area === chrome.storage.local) localRestricted = true;
    } catch {
      // Older Chrome only supports it for session storage, which is trusted-only by default.
    }
  }
  return localRestricted;
}
/**
 * Whether local storage (with the refresh tokens) is out of content scripts' reach. The page kit is
 * registered only when it is (background/kit.ts).
 */
let localRestricted = false;

async function read<T extends object>(area: chrome.storage.StorageArea, defaults: T): Promise<T> {
  await restrictStorage();
  const got = (await area.get(null)) as Partial<T>;
  const out = { ...defaults };
  for (const k of Object.keys(defaults) as (keyof T)[])
    if (got[k] !== undefined) out[k] = got[k] as T[keyof T];
  return structuredClone(out);
}

/** Runs [fn] while no other extension context changes storage. */
export function withLock<T>(name: string, fn: () => Promise<T>): Promise<T> {
  if (typeof navigator !== "undefined" && navigator.locks)
    return navigator.locks.request(`casama:${name}`, fn) as Promise<T>;
  return fn();
}

export const getLocal = () => read(chrome.storage.local, LOCAL_DEFAULTS);
export const getSession = () => read(chrome.storage.session, SESSION_DEFAULTS);

export function updateLocal(fn: (s: LocalState) => void): Promise<LocalState> {
  return withLock("local", async () => {
    const s = await getLocal();
    fn(s);
    await chrome.storage.local.set(s);
    return s;
  });
}

export function updateSession(fn: (s: SessionState) => void): Promise<SessionState> {
  return withLock("session", async () => {
    const s = await getSession();
    fn(s);
    await chrome.storage.session.set(s);
    return s;
  });
}

export async function activeAccount(): Promise<Account | null> {
  const s = await getLocal();
  return s.accounts.find((a) => a.id === s.activeAccountId) ?? s.accounts[0] ?? null;
}

export const accountId = (server: string, userId: string) => `${server} ${userId}`;
