/**
 * Casama Cloud's model assignment (D-188). Stored in instance_settings and read with a short
 * cache, so a change in the admin console reaches every process within seconds, without a restart.
 * Self-hosted servers never read it.
 */
import {
  type CloudModelAssignment,
  cloudModelAssignment,
} from "@casama/domain";
import type { Database } from "@casama/db";
import { sql } from "drizzle-orm";

const KEY = "cloud_models";
const TTL_MS = 10_000;

let cached: { at: number; value: CloudModelAssignment } | null = null;

export async function getCloudModels(db: Database): Promise<CloudModelAssignment> {
  if (cached && Date.now() - cached.at < TTL_MS) return cached.value;
  const [row] = await db.execute<{ value: unknown }>(
    sql`select value from public.instance_settings where key = ${KEY}`,
  );
  const value = cloudModelAssignment(row?.value);
  cached = { at: Date.now(), value };
  return value;
}

export async function setCloudModels(
  db: Database,
  value: CloudModelAssignment,
): Promise<CloudModelAssignment> {
  const stored = cloudModelAssignment(value);
  await db.execute(sql`
    insert into public.instance_settings (key, value, updated_at)
    values (${KEY}, ${JSON.stringify(stored)}::jsonb, now())
    on conflict (key) do update set value = excluded.value, updated_at = now()`);
  cached = { at: Date.now(), value: stored };
  return stored;
}

/** Tests: forget the cached assignment. */
export function resetCloudModelsCache() {
  cached = null;
}
