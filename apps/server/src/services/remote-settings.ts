/**
 * Settings the owner changes in Admin without a release (docs/REMOTE-CONTENT-PLAN.md):
 * - the model catalog (`instance_settings` key `model_catalog`) and the cost tables
 *   (`billing_settings.cost_tables`), D-373;
 * - the browser guard's added sites (`instance_settings` key `browser_guard`), D-374;
 * - the check-in and setup prompts, from the gallery's `prompts.json` (not Admin), D-374;
 * - call limits: silence, abandoned calls, longest call, warnings, ring limits (`instance_settings`
 *   key `call_limits`), D-426.
 * They're loaded into the shared modules in @casama/domain, which the gateway, voice, media and
 * computer prices and the browser guard read. Every process loads them at start and every minute;
 * the API process that saves one applies it at once. A value that can't be read, or fails its
 * check, leaves the code's values in place.
 */

import { setPrompts } from "@casama/agent";
import type { Database } from "@casama/db";
import {
  type CallLimits,
  type CostTables,
  checkCallLimits,
  checkCostTables,
  checkGuardAdditions,
  checkModelCatalog,
  DEFAULT_DOMAIN_TLDS,
  type ModelCatalog,
  setCallLimits,
  setCostTables,
  setModelCatalog,
  setSensitiveSiteAdditions,
} from "@casama/domain";
import { sql } from "drizzle-orm";
import type { Env } from "../env.ts";
import { galleryPrompts } from "./gallery.ts";

type Exec = Pick<Database, "execute">;

export const MODEL_CATALOG_KEY = "model_catalog";
const EVERY_MS = 60_000;

/** The stored model catalog, as saved (empty when none). */
export async function storedModelCatalog(db: Exec): Promise<ModelCatalog> {
  const [row] = await db.execute<{ value: unknown }>(
    sql`select value from public.instance_settings where key = ${MODEL_CATALOG_KEY}`,
  );
  return checkModelCatalog(row?.value).catalog;
}

/** Saves a catalog that passed its check, and applies it in this process. */
export async function saveModelCatalog(db: Exec, catalog: ModelCatalog) {
  await db.execute(sql`
    insert into public.instance_settings (key, value, updated_at)
    values (${MODEL_CATALOG_KEY}, ${JSON.stringify(catalog)}::jsonb, now())
    on conflict (key) do update set value = excluded.value, updated_at = now()`);
  setModelCatalog(catalog);
}

/** The stored cost tables (empty when none). */
export async function storedCostTables(db: Exec): Promise<CostTables> {
  const [row] = await db.execute<{ cost_tables: unknown }>(
    sql`select cost_tables from public.billing_settings where id`,
  );
  return checkCostTables(row?.cost_tables).tables;
}

export async function saveCostTables(db: Exec, tables: CostTables, by: string) {
  await db.execute(sql`
    update public.billing_settings
       set cost_tables = ${JSON.stringify(tables)}::jsonb, updated_at = now(), updated_by = ${by}::uuid
     where id`);
  setCostTables(tables);
}

/** Loads the settings into this process. Failures keep what was loaded before. */
export async function loadRemoteSettings(db: Exec, warn?: (msg: string, e: unknown) => void) {
  try {
    const [row] = await db.execute<{ value: unknown }>(
      sql`select value from public.instance_settings where key = ${MODEL_CATALOG_KEY}`,
    );
    setModelCatalog(row?.value);
  } catch (e) {
    warn?.("model catalog not loaded", e);
  }
  try {
    const [row] = await db.execute<{ cost_tables: unknown }>(
      sql`select cost_tables from public.billing_settings where id`,
    );
    setCostTables(row?.cost_tables);
  } catch (e) {
    warn?.("cost tables not loaded", e);
  }
  try {
    const [row] = await db.execute<{ value: unknown }>(
      sql`select value from public.instance_settings where key = ${GUARD_SITES_KEY}`,
    );
    setSensitiveSiteAdditions(row?.value);
  } catch (e) {
    warn?.("browser guard sites not loaded", e);
  }
  try {
    const [row] = await db.execute<{ value: unknown }>(
      sql`select value from public.instance_settings where key = ${CALL_LIMITS_KEY}`,
    );
    setCallLimits(row?.value ?? null);
  } catch (e) {
    warn?.("call limits not loaded", e);
  }
}

/** Loads the settings now and every minute. Returns a stop function. */
export function startRemoteSettings(
  db: Exec,
  logger?: { warn(msg: string, data?: Record<string, unknown>): void },
) {
  const warn = (msg: string, e: unknown) => logger?.warn(msg, { error: (e as Error).message });
  void loadRemoteSettings(db, warn);
  const timer = setInterval(() => void loadRemoteSettings(db, warn), EVERY_MS);
  timer.unref?.();
  return () => clearInterval(timer);
}

// ---------------------------------------------------------------- prompts (#8)

const PROMPTS_EVERY_MS = 15 * 60_000;

/**
 * Takes the gallery's check-in and setup prompts. Entries that fail their check keep the built-in
 * text; a gallery that can't be reached keeps what was loaded last. Returns the versions in use.
 */
export async function loadGalleryPrompts(
  env: Env,
  fetchImpl: typeof fetch = fetch,
): Promise<Record<string, number> | null> {
  const items = await galleryPrompts(env, fetchImpl);
  if (!items) return null;
  return setPrompts(items);
}

/** Loads the prompts now and every 15 minutes (the gallery's own cache time). */
export function startGalleryPrompts(
  env: Env,
  logger?: { info(msg: string, data?: Record<string, unknown>): void },
) {
  let last = "";
  const load = async () => {
    const versions = await loadGalleryPrompts(env).catch(() => null);
    const now = JSON.stringify(versions);
    if (versions && now !== last) logger?.info("gallery prompts", { versions });
    if (versions) last = now;
  };
  void load();
  const timer = setInterval(() => void load(), PROMPTS_EVERY_MS);
  timer.unref?.();
  return () => clearInterval(timer);
}

// ---------------------------------------------------------------- domains (#11)

export interface DomainSaleSettings {
  /** What's on sale now: the saved list, else CASAMA_DOMAINS_TLDS, else the list in code. */
  tlds: string[];
  /** Whether `tlds` is the saved list (false: it comes from the env var or the code). */
  tlds_saved: boolean;
  cap_first_month: number;
  cap_per_month: number;
}

const cleanTld = (t: string) => t.trim().toLowerCase().replace(/^\./, "");
export const TLD = /^[a-z0-9-]{2,63}(\.[a-z0-9-]{2,63})?$/;

/** The env var's list (CASAMA_DOMAINS_TLDS), else the code's. */
export function envDomainTlds(envValue: string | undefined): string[] {
  return (envValue ?? DEFAULT_DOMAIN_TLDS.join(",")).split(",").map(cleanTld).filter(Boolean);
}

/**
 * Domain sale settings. Order (D-373): the list saved in Admin wins; with none saved, the env var
 * keeps working; without it, the list in code. The caps default to 3 and 10, as before.
 */
export async function domainSaleSettings(
  db: Exec,
  envValue: string | undefined,
): Promise<DomainSaleSettings> {
  const [r] = await db
    .execute<{ domain_tlds: string[] | null; first: number; per: number }>(
      sql`select domain_tlds, domain_cap_first_month as first, domain_cap_per_month as per from public.billing_settings where id`,
    )
    .catch(() => [] as Array<{ domain_tlds: string[] | null; first: number; per: number }>);
  const saved = (r?.domain_tlds ?? []).map(cleanTld).filter((t) => TLD.test(t));
  return {
    tlds: saved.length ? saved : envDomainTlds(envValue),
    tlds_saved: saved.length > 0,
    cap_first_month: r ? Number(r.first) : 3,
    cap_per_month: r ? Number(r.per) : 10,
  };
}

// ---------------------------------------------------------------- browser guard (#7, D-374)

export const GUARD_SITES_KEY = "browser_guard";

/** The added sites, as saved (every kind, empty lists when none). */
export async function storedGuardSites(db: Exec) {
  const [row] = await db.execute<{ value: unknown }>(
    sql`select value from public.instance_settings where key = ${GUARD_SITES_KEY}`,
  );
  return checkGuardAdditions(row?.value).hosts;
}

export async function saveGuardSites(db: Exec, hosts: Record<string, string[]>) {
  await db.execute(sql`
    insert into public.instance_settings (key, value, updated_at)
    values (${GUARD_SITES_KEY}, ${JSON.stringify(hosts)}::jsonb, now())
    on conflict (key) do update set value = excluded.value, updated_at = now()`);
  setSensitiveSiteAdditions(hosts);
}

// ---------------------------------------------------------------- call limits (D-426)

export const CALL_LIMITS_KEY = "call_limits";

/** The saved call limits (only the values the owner set). */
export async function storedCallLimits(db: Exec): Promise<Partial<CallLimits>> {
  const [row] = await db.execute<{ value: unknown }>(
    sql`select value from public.instance_settings where key = ${CALL_LIMITS_KEY}`,
  );
  return checkCallLimits(row?.value).limits;
}

/** Saves limits that passed their check, and applies them in this process. */
export async function saveCallLimits(db: Exec, limits: Partial<CallLimits>) {
  await db.execute(sql`
    insert into public.instance_settings (key, value, updated_at)
    values (${CALL_LIMITS_KEY}, ${JSON.stringify(limits)}::jsonb, now())
    on conflict (key) do update set value = excluded.value, updated_at = now()`);
  setCallLimits(limits);
}
