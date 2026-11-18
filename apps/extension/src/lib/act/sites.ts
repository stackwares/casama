/**
 * Where a bot may work in the person's browser (D-323 C6, plan §11). Every page a bot opens or
 * lands on is checked here, on top of the server's own check of the addresses it asks for.
 *
 * Order: Casama's own addresses (always refused) → the workspace's and this browser's blocked sites,
 * an administrator's managed BlockedSites and the person's never-list → kinds of site that are off by
 * default (banking, health, password managers, government ID) unless switched back on, and even then
 * they ask → the allowed lists → otherwise ask: this once, always, or never.
 */
import type { SensitiveSiteAdditions } from "../../../../../packages/domain/src/browser-guard.ts";
import { GUARD_REASON, type GuardKind, guardUrl } from "../guard.ts";

export interface SitePolicy {
  blocked_sites: string[];
  allowed_sites: string[];
  allowed_kinds: string[];
  own_urls: string[];
}

export interface LocalSiteRules {
  /** chrome.storage.managed BlockedSites / AllowedSites, set by an administrator. */
  managedBlocked?: string[];
  managedAllowed?: string[];
  /** The person's never-list (G2), which covers acting too. */
  neverList?: string[];
  /** Hosts allowed "this once" for this run. */
  once?: string[];
  /** Hosts the signed-in servers add to the off-by-default kinds (D-374). */
  extraHosts?: SensitiveSiteAdditions;
}

export type SiteDecision =
  | { kind: "allowed" }
  | { kind: "ask"; host: string; reason: string; kindOfSite?: GuardKind }
  | { kind: "refused"; host: string; reason: string };

const within = (host: string, domain: string) => host === domain || host.endsWith(`.${domain}`);

/** "example.com" matches it and its subdomains; "*.example.com" only subdomains (as the server). */
export function siteMatches(host: string, pattern: string): boolean {
  const p = pattern
    .trim()
    .toLowerCase()
    .replace(/^https?:\/\//, "")
    .replace(/\/.*$/, "");
  if (!p) return false;
  if (p.startsWith("*.")) return host.endsWith(p.slice(1));
  return within(host, p.replace(/^www\./, ""));
}

export function hostOf(url: string): string | null {
  try {
    const u = new URL(url);
    if (!/^https?:$/.test(u.protocol)) return null;
    return u.hostname
      .toLowerCase()
      .replace(/\.$/, "")
      .replace(/^www\./, "");
  } catch {
    return null;
  }
}

const ownHosts = (urls: string[]) =>
  urls.flatMap((u) => {
    try {
      return [new URL(u).host.toLowerCase()];
    } catch {
      return [];
    }
  });

export function siteDecision(
  url: string,
  policy: SitePolicy,
  local: LocalSiteRules = {},
): SiteDecision {
  if (url === "about:blank") return { kind: "allowed" };
  const host = hostOf(url);
  if (!host) return { kind: "refused", host: url, reason: "Only web pages can be used." };
  if (/^https?:\/\/(chrome\.google\.com\/webstore|chromewebstore\.google\.com)/i.test(url))
    return { kind: "refused", host, reason: "The Chrome Web Store can't be used by a bot." };
  const kindOfSite = guardUrl(url, {
    ownHosts: ownHosts(policy.own_urls),
    allowed: policy.allowed_kinds as GuardKind[],
    extraHosts: local.extraHosts,
  });
  if (kindOfSite === "casama")
    return { kind: "refused", host, reason: "Casama's own pages can't be used by a bot." };
  const blocked = [...policy.blocked_sites, ...(local.managedBlocked ?? [])];
  if (blocked.some((p) => siteMatches(host, p)))
    return { kind: "refused", host, reason: "This site is blocked for bots." };
  if ((local.neverList ?? []).some((p) => siteMatches(host, p)))
    return { kind: "refused", host, reason: GUARD_REASON.never };
  if (kindOfSite)
    return {
      kind: "refused",
      host,
      reason: `${GUARD_REASON[kindOfSite]} Switch it on in Casama's options to let bots ask.`,
    };
  // A kind switched back on still asks, once per run.
  const kindAllowed = guardUrl(url, {
    ownHosts: ownHosts(policy.own_urls),
    extraHosts: local.extraHosts,
  });
  if (
    kindAllowed &&
    kindAllowed !== "casama" &&
    !(local.once ?? []).some((p) => siteMatches(host, p))
  )
    return { kind: "ask", host, reason: GUARD_REASON[kindAllowed], kindOfSite: kindAllowed };
  const allowed = [...policy.allowed_sites, ...(local.managedAllowed ?? []), ...(local.once ?? [])];
  if (allowed.some((p) => siteMatches(host, p))) return { kind: "allowed" };
  return { kind: "ask", host, reason: "A bot wants to work on this site." };
}
