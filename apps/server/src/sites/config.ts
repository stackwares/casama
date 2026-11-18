/**
 * What sites and domains may do on this server (docs/SITES-AND-DOMAINS-PLAN.md §7.20). Every part
 * is off until its setting is set, and each has a remote switch (D-239: flags `sites`,
 * `custom_domains`, `buy_domains`) that turns it back off without a deploy.
 */
import type { Database } from "@casama/db";
import type { Env } from "../env.ts";
import { getAppConfig } from "../services/app-config.ts";
import { domainSaleSettings, envDomainTlds } from "../services/remote-settings.ts";

export interface SitesSettings {
  zone: string | null;
  custom_domains: boolean;
  buy_domains: boolean;
  tlds: string[];
}

/**
 * The endings on sale from the env var (CASAMA_DOMAINS_TLDS) or the code, without the database.
 * A list saved in Admin → Pricing wins over both (`domainSaleSettings`, D-373).
 */
export const domainTlds = (env: Env) => envDomainTlds(env.CASAMA_DOMAINS_TLDS);

/** Connected domains need an edge: Cloudflare for SaaS on the zone, or Caddy on this server. */
export const hostnamesConfigured = (env: Env) =>
  !!(env.CASAMA_SITES_CF_ZONE_ID && env.CASAMA_SITES_CF_API_TOKEN) || env.CASAMA_SITES_OWN_EDGE;

/** Buying needs a registrar and payments; only on Casama Cloud (decision 10). */
export const buyingConfigured = (env: Env) =>
  env.CASAMA_DOMAINS_REGISTRAR !== "none" && env.BILLING_ENABLED && !env.CASAMA_SITES_OWN_EDGE;

export async function sitesSettings(env: Env, db: Database): Promise<SitesSettings> {
  const flags = env.CASAMA_SITES_ZONE
    ? ((await getAppConfig(db).catch(() => null))?.flags ?? {})
    : {};
  const zone = env.CASAMA_SITES_ZONE && flags.sites !== false ? env.CASAMA_SITES_ZONE : null;
  const custom = !!zone && hostnamesConfigured(env) && flags.custom_domains !== false;
  const buy = custom && buyingConfigured(env) && flags.buy_domains !== false;
  const tlds = buy ? (await domainSaleSettings(db, env.CASAMA_DOMAINS_TLDS)).tlds : [];
  return { zone, custom_domains: custom, buy_domains: buy, tlds };
}
