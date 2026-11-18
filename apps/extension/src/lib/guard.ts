/**
 * The guard (plan §6 G2, §11): pages the extension won't read, capture or (from Phase 3) act on.
 *
 * - Casama's own addresses, always: a bot must never be able to read or approve things in Casama.
 * - Kinds of site that are off by default (D-323): banking and payments, health portals, password
 *   managers and government ID sites. The lists are well-known hosts and the words their addresses
 *   tend to carry; a person can switch a kind back on.
 * - Sites the signed-in servers add to those kinds (D-374, lib/guard-sites.ts). Only additions: the
 *   built-in lists are checked whatever a server sends.
 * - The person's never-list.
 * - On the page itself: a filled-in password or card field (checked by the extractor).
 */
import {
  type SensitiveSiteAdditions,
  type SensitiveSiteKind,
  sensitiveSiteKind,
} from "../../../../packages/domain/src/browser-guard.ts";

export type GuardKind = "casama" | SensitiveSiteKind | "never";

const CASAMA = ["casama.ai", "casama.link", "kasama.ai"];

const within = (host: string, domain: string) => host === domain || host.endsWith(`.${domain}`);

export interface GuardOptions {
  neverList?: string[];
  /** Kinds switched back on by the person (never "casama"). */
  allowed?: GuardKind[];
  /** The signed-in servers' own addresses (host with port), which count as Casama's own pages. */
  ownHosts?: string[];
  /** Hosts the servers add to the off-by-default kinds (`guardAdditions()`). */
  extraHosts?: SensitiveSiteAdditions;
}

/** Why a page is off limits, or null when it isn't. */
export function guardUrl(url: string | undefined, opts: GuardOptions = {}): GuardKind | null {
  if (!url) return null;
  let u: URL;
  try {
    u = new URL(url);
  } catch {
    return null;
  }
  // A trailing dot (app.casama.ai.) is the same site.
  const host = u.hostname
    .toLowerCase()
    .replace(/\.$/, "")
    .replace(/^www\./, "");
  if (CASAMA.some((d) => within(host, d))) return "casama";
  const hostPort = u.host.toLowerCase().replace(/\.(?=:|$)/, "");
  if ((opts.ownHosts ?? []).some((h) => h.toLowerCase() === hostPort)) return "casama";
  if ((opts.neverList ?? []).some((d) => within(host, d))) return "never";
  return sensitiveSiteKind(
    host,
    (opts.allowed ?? []).filter((k): k is SensitiveSiteKind => k !== "casama" && k !== "never"),
    opts.extraHosts ?? {},
  );
}

export const GUARD_REASON: Record<GuardKind, string> = {
  casama: "Casama's own pages can't be read or sent to a bot.",
  banking: "Banking and payment sites are off by default.",
  health: "Health sites are off by default.",
  passwords: "Password managers are off by default.",
  government: "Government ID sites are off by default.",
  never: "You put this site on your never-list.",
};

/** Pages the extension can't script at all (Chrome's own, the store, other extensions). */
export function scriptable(url: string | undefined): boolean {
  if (!url) return false;
  if (!/^(https?|file):/.test(url)) return false;
  return !/^https:\/\/(chrome\.google\.com\/webstore|chromewebstore\.google\.com)/.test(url);
}
