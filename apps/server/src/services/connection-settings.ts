/**
 * How apps without our own sign-in connect (D-173), changeable at runtime from the admin console:
 *
 * - "server": through the server's Composio account (COMPOSIO_API_KEY): one click, people sign
 *   in to the app itself. The default.
 * - "own": people use their own accounts (Composio, Pipedream or Zapier over MCP), even when the
 *   server has a Composio key.
 *
 * Stored in instance_settings (key "connections") and read with a short cache, so a change
 * reaches every API process within seconds without a restart.
 */
import { sql } from "drizzle-orm";
import type { AppDeps } from "../api/types.ts";

export type ComposioMode = "server" | "own";
export interface ConnectionSettings {
  composio: ComposioMode;
}

const KEY = "connections";
const TTL_MS = 10_000;
const DEFAULTS: ConnectionSettings = { composio: "server" };

let cached: { at: number; value: ConnectionSettings } | null = null;

export async function getConnectionSettings(db: AppDeps["db"]): Promise<ConnectionSettings> {
  if (cached && Date.now() - cached.at < TTL_MS) return cached.value;
  const [row] = await db.execute<{ value: Partial<ConnectionSettings> | null }>(
    sql`select value from public.instance_settings where key = ${KEY}`,
  );
  const mode = row?.value?.composio;
  const value: ConnectionSettings = {
    composio: mode === "own" || mode === "server" ? mode : DEFAULTS.composio,
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
