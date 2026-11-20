import { loadExtraReservedNames, resetExtraReservedNamesCache } from "@casama/agent";
import type { Database } from "@casama/db";
import { sql } from "drizzle-orm";

/**
 * Mail names the instance owner reserved on top of the built-in list (BOT-EMAIL-PLAN §4.1):
 * an instance_settings row, cached for a minute because claims read it.
 */
export const mailReservedNames = loadExtraReservedNames;

export async function setMailReservedNames(db: Database, names: string[]): Promise<string[]> {
  const clean = [...new Set(names.map((n) => n.trim().toLowerCase()).filter(Boolean))].slice(
    0,
    500,
  );
  await db.execute(sql`
    insert into public.instance_settings (key, value, updated_at)
    values ('mail_reserved_names', ${JSON.stringify({ names: clean })}::jsonb, now())
    on conflict (key) do update set value = excluded.value, updated_at = now()`);
  resetExtraReservedNamesCache();
  return clean;
}

/** Tests reset the cache between runs. */
export const resetMailReservedNamesCache = resetExtraReservedNamesCache;
