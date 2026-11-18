/**
 * Casama Link's settings on a self-hosted server (D-296), kept in instance_settings.
 *
 * Private notifications: with it on, the push relay on Casama Cloud is given no text ("New
 * activity"), and the app loads what happened from this server when it opens. Read with a short
 * cache by the worker on every push, so the switch takes effect within seconds and without a
 * restart.
 */
import type { Database } from "@casama/db";
import { sql } from "drizzle-orm";

const KEY = "link_private_notifications";
const TTL_MS = 15_000;
let cached: { at: number; value: boolean } | null = null;

export async function privateNotifications(db: Database): Promise<boolean> {
  if (cached && Date.now() - cached.at < TTL_MS) return cached.value;
  const [row] = await db.execute<{ value: unknown }>(
    sql`select value from public.instance_settings where key = ${KEY}`,
  );
  const value = (row?.value as { on?: boolean } | undefined)?.on === true;
  cached = { at: Date.now(), value };
  return value;
}

export async function setPrivateNotifications(db: Database, on: boolean) {
  await db.execute(sql`
    insert into public.instance_settings (key, value, updated_at)
    values (${KEY}, ${JSON.stringify({ on })}::jsonb, now())
    on conflict (key) do update set value = excluded.value, updated_at = now()`);
  cached = { at: Date.now(), value: on };
  return on;
}

export function resetLinkSettingsCache() {
  cached = null;
}
