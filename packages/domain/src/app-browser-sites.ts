/**
 * Where a bot may work in the phone app's browser (docs/PHONE-BROWSER-PLAN.md §8.5). The app
 * decides this itself, in Dart, before a page loads; this is the reference it is tested against
 * (`scripts/app-browser-assets.ts` writes the cases), with the same order as Casama for Chrome's
 * `siteDecision`.
 */
import {
  browsable,
  hostOf,
  isCasamaAddress,
  type SensitiveSiteAdditions,
  type SensitiveSiteKind,
  sensitiveSiteKind,
  siteMatches,
} from "./browser-guard.ts";

export interface AppSitePolicy {
  blocked_sites: string[];
  allowed_sites: string[];
  allowed_kinds: string[];
  own_urls: string[];
}

export type AppSiteDecision =
  | { kind: "allowed" }
  | { kind: "ask"; host: string; site_kind?: SensitiveSiteKind }
  | {
      kind: "refused";
      host: string;
      why: "not_web" | "casama" | "blocked" | SensitiveSiteKind;
    };

export function appSiteDecision(
  url: string,
  policy: AppSitePolicy,
  /** Sites answered "once" in this run. */
  once: string[] = [],
  extra: SensitiveSiteAdditions = {},
): AppSiteDecision {
  if (url === "about:blank") return { kind: "allowed" };
  const host = hostOf(url);
  if (!host || !browsable(url)) return { kind: "refused", host: host ?? url, why: "not_web" };
  if (isCasamaAddress(url, policy.own_urls)) return { kind: "refused", host, why: "casama" };
  if (policy.blocked_sites.some((p) => siteMatches(host, p)))
    return { kind: "refused", host, why: "blocked" };
  const off = sensitiveSiteKind(host, policy.allowed_kinds as SensitiveSiteKind[], extra);
  if (off) return { kind: "refused", host, why: off };
  // A kind switched back on still asks, once per run.
  const kind = sensitiveSiteKind(host, [], extra);
  if (kind && !once.some((p) => siteMatches(host, p)))
    return { kind: "ask", host, site_kind: kind };
  if ([...policy.allowed_sites, ...once].some((p) => siteMatches(host, p)))
    return { kind: "allowed" };
  return { kind: "ask", host };
}
