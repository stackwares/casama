/**
 * Shared helpers for the GA4 scripts (D-398): Google auth, the property id, and JSON calls to the
 * Analytics Admin and Data APIs. Used by scripts/ga4-setup.mts and scripts/ga4-funnels.mts.
 *
 * Auth, first match wins:
 *   GOOGLE_ACCESS_TOKEN        a bearer token, e.g. `gcloud auth print-access-token` for an account
 *                              with access to the property (needs analytics scopes)
 *   GA4_SERVICE_ACCOUNT_JSON   a service account's JSON key (the whole JSON, not a path), or
 *   GA4_SERVICE_ACCOUNT_FILE   a path to one. The account's email must be added in GA4 Admin →
 *                              Property access management (Editor for setup, Viewer for funnels).
 * Property: --property <id> or GA4_PROPERTY_ID; default 563408057 (Casama).
 */
import { createSign } from "node:crypto";
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

export const DEFAULT_PROPERTY = "563408057";
export const ADMIN = "https://analyticsadmin.googleapis.com";
export const DATA = "https://analyticsdata.googleapis.com";
export const SCOPES = [
  "https://www.googleapis.com/auth/analytics.edit",
  "https://www.googleapis.com/auth/analytics.readonly",
];

export const repoRoot = join(dirname(fileURLToPath(import.meta.url)), "..");

export interface CatalogEvent {
  name: string;
  by: string[];
  properties?: Record<string, { type?: string; values?: string[] }>;
  funnels?: string[];
}

export function loadCatalog(): { events: CatalogEvent[]; super_properties: string[] } {
  return JSON.parse(
    readFileSync(join(repoRoot, "packages/contracts/analytics/catalog.json"), "utf8"),
  );
}

/** The value after a flag (`--days 28`), or undefined. */
export function flag(argv: string[], name: string): string | undefined {
  const i = argv.indexOf(name);
  return i >= 0 ? argv[i + 1] : undefined;
}

export function propertyId(argv: string[], env: NodeJS.ProcessEnv = process.env): string {
  const id = (flag(argv, "--property") ?? env.GA4_PROPERTY_ID ?? DEFAULT_PROPERTY).replace(
    /^properties\//,
    "",
  );
  if (!/^\d+$/.test(id)) throw new Error(`GA4 property id must be numeric, got "${id}"`);
  return id;
}

interface ServiceAccount {
  client_email: string;
  private_key: string;
  token_uri?: string;
}

/** A signed JWT assertion for the OAuth 2.0 JWT bearer grant. */
export function jwtAssertion(account: ServiceAccount, scopes: string[], now = Date.now()): string {
  const b64 = (o: unknown) => Buffer.from(JSON.stringify(o)).toString("base64url");
  const iat = Math.floor(now / 1000);
  const unsigned = `${b64({ alg: "RS256", typ: "JWT" })}.${b64({
    iss: account.client_email,
    scope: scopes.join(" "),
    aud: account.token_uri ?? "https://oauth2.googleapis.com/token",
    iat,
    exp: iat + 3600,
  })}`;
  const sig = createSign("RSA-SHA256").update(unsigned).sign(account.private_key, "base64url");
  return `${unsigned}.${sig}`;
}

/** A bearer token from the environment (see the top of this file). */
export async function accessToken(
  env: NodeJS.ProcessEnv = process.env,
  doFetch: typeof fetch = fetch,
): Promise<string> {
  if (env.GOOGLE_ACCESS_TOKEN) return env.GOOGLE_ACCESS_TOKEN.trim();
  const raw =
    env.GA4_SERVICE_ACCOUNT_JSON ??
    (env.GA4_SERVICE_ACCOUNT_FILE ? readFileSync(env.GA4_SERVICE_ACCOUNT_FILE, "utf8") : undefined);
  if (!raw) {
    throw new Error(
      "No Google credentials: set GOOGLE_ACCESS_TOKEN, GA4_SERVICE_ACCOUNT_JSON or GA4_SERVICE_ACCOUNT_FILE",
    );
  }
  const account = JSON.parse(raw) as ServiceAccount;
  const aud = account.token_uri ?? "https://oauth2.googleapis.com/token";
  const res = await doFetch(aud, {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwtAssertion(account, SCOPES),
    }),
  });
  if (!res.ok) throw new Error(`Google token answered ${res.status}: ${await res.text()}`);
  return ((await res.json()) as { access_token: string }).access_token;
}

export type Api = <T = unknown>(method: string, url: string, body?: unknown) => Promise<T>;

/** JSON calls with the token; a non-2xx answer throws with Google's message. */
export function api(token: string, doFetch: typeof fetch = fetch): Api {
  return async <T,>(method: string, url: string, body?: unknown): Promise<T> => {
    const res = await doFetch(url, {
      method,
      headers: {
        authorization: `Bearer ${token}`,
        ...(body === undefined ? {} : { "content-type": "application/json" }),
      },
      body: body === undefined ? undefined : JSON.stringify(body),
    });
    const text = await res.text();
    if (!res.ok) throw new Error(`${method} ${url} answered ${res.status}: ${text.slice(0, 500)}`);
    return (text ? JSON.parse(text) : {}) as T;
  };
}

/** Every item of a paged Admin API list (`?pageToken=`). */
export async function listAll<T>(call: Api, url: string, key: string): Promise<T[]> {
  const out: T[] = [];
  let token: string | undefined;
  do {
    const sep = url.includes("?") ? "&" : "?";
    const page = await call<Record<string, unknown>>(
      "GET",
      `${url}${sep}pageSize=200${token ? `&pageToken=${encodeURIComponent(token)}` : ""}`,
    );
    out.push(...(((page[key] as T[] | undefined) ?? []) as T[]));
    token = page.nextPageToken as string | undefined;
  } while (token);
  return out;
}
