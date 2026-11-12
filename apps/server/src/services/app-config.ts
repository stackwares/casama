/**
 * Remote app settings (D-241), kept in instance_settings (key "app_config") and read with a short
 * cache: apps fetch them often and without signing in.
 */
import { checkAppConfig, EMPTY_APP_CONFIG, type RemoteAppConfig } from "@casama/domain";
import { sql } from "drizzle-orm";
import type { AppDeps } from "../api/types.ts";

const KEY = "app_config";
const TTL_MS = 15_000;
let cached: { at: number; value: RemoteAppConfig } | null = null;

export async function getAppConfig(db: AppDeps["db"]): Promise<RemoteAppConfig> {
  if (cached && Date.now() - cached.at < TTL_MS) return cached.value;
  const [row] = await db.execute<{ value: unknown }>(
    sql`select value from public.instance_settings where key = ${KEY}`,
  );
  // A stored value that no longer passes (an older or hand-edited one) counts as empty.
  const value = row?.value
    ? (checkAppConfig(row.value).config ?? EMPTY_APP_CONFIG)
    : EMPTY_APP_CONFIG;
  cached = { at: Date.now(), value };
  return value;
}

export async function setAppConfig(db: AppDeps["db"], value: RemoteAppConfig) {
  await db.execute(sql`
    insert into public.instance_settings (key, value, updated_at)
    values (${KEY}, ${JSON.stringify(value)}::jsonb, now())
    on conflict (key) do update set value = excluded.value, updated_at = now()`);
  cached = { at: Date.now(), value };
  return value;
}

export function resetAppConfigCache() {
  cached = null;
}
