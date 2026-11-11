/**
 * How apps without our own sign-in connect (D-173), changeable at runtime from the admin console:
 *
 * - "server": through the server's Composio account (COMPOSIO_API_KEY): one click, people sign
 *   in to the app itself. The default.
 * - "own": people use their own accounts (Composio, Pipedream or Zapier over MCP), even when the
 *   server has a Composio key.
 *
 * And for Google's apps (D-166): "composio" (the default) sends them through the server's Composio
 * account whenever it has one, because Google's own MCP servers refuse tool calls until the Cloud
 * project is enrolled in Workspace Developer Preview. "direct" uses Google's servers with the
 * server's own Google client, for self-hosters who have enrolled. Casama Cloud always uses Composio.
 *
 * Stored in instance_settings (key "connections") and read with a short cache, so a change
 * reaches every API process within seconds without a restart.
 */
import { sql } from "drizzle-orm";
import type { AppDeps } from "../api/types.ts";

export type ComposioMode = "server" | "own";
export type GoogleMode = "composio" | "direct";
export interface ConnectionSettings {
  composio: ComposioMode;
  google: GoogleMode;
}

const KEY = "connections";
const TTL_MS = 10_000;
const DEFAULTS: ConnectionSettings = { composio: "server", google: "composio" };

let cached: { at: number; value: ConnectionSettings } | null = null;

export async function getConnectionSettings(db: AppDeps["db"]): Promise<ConnectionSettings> {
  if (cached && Date.now() - cached.at < TTL_MS) return cached.value;
  const [row] = await db.execute<{ value: Partial<ConnectionSettings> | null }>(
    sql`select value from public.instance_settings where key = ${KEY}`,
  );
  const mode = row?.value?.composio;
  const google = row?.value?.google;
  const value: ConnectionSettings = {
    composio: mode === "own" || mode === "server" ? mode : DEFAULTS.composio,
    google: google === "direct" || google === "composio" ? google : DEFAULTS.google,
  };
  cached = { at: Date.now(), value };
  return value;
}

export async function setConnectionSettings(
  db: AppDeps["db"],
  value: ConnectionSettings,
): Promise<ConnectionSettings> {
  await db.execute(sql`
    insert into public.instance_settings (key, value, updated_at)
    values (${KEY}, ${JSON.stringify(value)}::jsonb, now())
    on conflict (key) do update set value = excluded.value, updated_at = now()`);
  cached = { at: Date.now(), value };
  return value;
}

/** Tests: forget the cached value. */
export function resetConnectionSettingsCache() {
  cached = null;
}

/**
 * How a new person can connect Google from the welcome chat (D-204), the same way the catalog
 * routes it (catalogFor): "composio" through the server's Composio account, "direct" through the
 * server's own Google client (self-hosted only), or null when Google can't be connected here.
 */
export async function googleConnectRoute(
  db: AppDeps["db"],
  env: Pick<AppDeps["env"], "COMPOSIO_API_KEY" | "GOOGLE_OAUTH_CLIENT_ID" | "BILLING_ENABLED">,
): Promise<GoogleMode | null> {
  const s = await getConnectionSettings(db);
  const composio = !!env.COMPOSIO_API_KEY && s.composio === "server";
  if (composio && (env.BILLING_ENABLED || s.google !== "direct")) return "composio";
  if (!env.BILLING_ENABLED && env.GOOGLE_OAUTH_CLIENT_ID) return "direct";
  return null;
}
