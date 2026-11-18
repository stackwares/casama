/**
 * The account and workspace things happen in: the active account, its client and its chosen
 * workspace (the first one when none was picked). Shared by the panel and the service worker.
 */
import type { CasamaClient, Schemas } from "@casama/client";
import { accessToken, clientFor } from "./session.ts";
import { type Account, activeAccount, updateLocal } from "./store.ts";

export interface Here {
  account: Account;
  api: CasamaClient;
  org: Schemas["OrganizationWithRole"];
  orgs: Schemas["OrganizationWithRole"][];
}

const T = () => AbortSignal.timeout(20_000);

/** The active account and workspace, or null when signed out or not in a workspace. */
export async function here(): Promise<Here | null> {
  const account = await activeAccount();
  if (!account) return null;
  const api = clientFor(account);
  const orgs = (await api.unwrap(api.GET("/v1/orgs", { signal: T() }))).items;
  const org = orgs.find((o) => o.id === account.orgId) ?? orgs[0];
  if (!org) return null;
  if (account.orgId !== org.id)
    await updateLocal((s) => {
      const a = s.accounts.find((x) => x.id === account.id);
      if (a) a.orgId = org.id;
    });
  return { account, api, org, orgs };
}

/**
 * A PostgREST call to the server's database API as the person (suggestions and the devices row
 * live there, as in the app). Row-level security decides what they may see.
 */
export async function rest(
  account: Account,
  path: string,
  init: RequestInit = {},
): Promise<Response> {
  const token = await accessToken(account.id);
  if (!token) throw new Error("You're signed out. Sign in again in Settings.");
  const headers = new Headers(init.headers);
  headers.set("apikey", account.anonKey);
  headers.set("authorization", `Bearer ${token}`);
  if (init.body && !headers.has("content-type")) headers.set("content-type", "application/json");
  const res = await fetch(`${account.authUrl}/rest/v1/${path}`, {
    ...init,
    headers,
    signal: init.signal ?? T(),
  });
  if (!res.ok) throw new Error(`The server refused it (${res.status}).`);
  return res;
}

/** Where the person's Casama app is for this server, for "Open in Casama" links. */
export function appUrl(account: Account, path = ""): string {
  const base =
    account.server === "https://api.casama.ai"
      ? "https://app.casama.ai"
      : account.server.replace("://api-dev.", "://app-dev.").replace("://api.", "://app.");
  return `${base}${path}`;
}
