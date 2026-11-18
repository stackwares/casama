/**
 * Sites and domains (docs/SITES-AND-DOMAINS-PLAN.md): the pure rules. A site is a public page
 * served at its own address (`name.<sites zone>`), and on domains a workspace connects or buys.
 * Everything here is free of I/O so the server, the worker and the tests share one answer.
 */
import { parse } from "tldts";
import { PAGE_CSP_ASSETS, PAGE_DATA_ID, scriptJson } from "./pages.ts";

// ------------------------------------------------------------------ Addresses

/** Address names: 3 to 40 letters, digits and hyphens, not starting or ending with a hyphen. */
export const SITE_LABEL_PATTERN = /^[a-z0-9](?:[a-z0-9-]{1,38}[a-z0-9])$/;

/**
 * Names nobody can take: the zone's own service names, names that look like sign-in or support
 * pages, and `d-…`, which is where every domain's own target lives (§7.4).
 */
export const RESERVED_SITE_LABELS = new Set([
  "www",
  "mail",
  "email",
  "webmail",
  "smtp",
  "imap",
  "pop",
  "ftp",
  "ns1",
  "ns2",
  "ns3",
  "dns",
  "api",
  "app",
  "apps",
  "auth",
  "oauth",
  "sso",
  "admin",
  "administrator",
  "root",
  "login",
  "signin",
  "sign-in",
  "signup",
  "account",
  "accounts",
  "secure",
  "security",
  "support",
  "help",
  "billing",
  "pay",
  "payment",
  "payments",
  "status",
  "abuse",
  "report",
  "casama",
  "casama-ai",
  "pages",
  "share",
  "view",
  "sites",
  "docs",
  "blog",
  "static",
  "assets",
  "cdn",
  "link",
  "gallery",
  "localhost",
  "test",
  "example",
  "_casama",
]);

/**
 * Brands that phishing pages pretend to be. A name is refused when one of its hyphen-separated
 * parts is a brand, or when it holds a brand together with a sign-in word.
 */
export const IMPERSONATED_BRANDS = [
  "paypal",
  "apple",
  "icloud",
  "appleid",
  "google",
  "gmail",
  "youtube",
  "microsoft",
  "outlook",
  "office365",
  "hotmail",
  "live",
  "amazon",
  "aws",
  "facebook",
  "meta",
  "instagram",
  "whatsapp",
  "messenger",
  "netflix",
  "spotify",
  "linkedin",
  "twitter",
  "tiktok",
  "snapchat",
  "telegram",
  "discord",
  "steam",
  "roblox",
  "dropbox",
  "docusign",
  "adobe",
  "chase",
  "wellsfargo",
  "bankofamerica",
  "citibank",
  "citi",
  "hsbc",
  "barclays",
  "santander",
  "natwest",
  "lloyds",
  "capitalone",
  "amex",
  "americanexpress",
  "visa",
  "mastercard",
  "discover",
  "stripe",
  "venmo",
  "cashapp",
  "zelle",
  "revolut",
  "wise",
  "coinbase",
  "binance",
  "kraken",
  "metamask",
  "trustwallet",
  "ledger",
  "blockchain",
  "dhl",
  "fedex",
  "ups",
  "usps",
  "royalmail",
  "irs",
  "hmrc",
  "ebay",
  "walmart",
  "costco",
  "bestbuy",
  "att",
  "verizon",
  "tmobile",
  "comcast",
  "xfinity",
  "yahoo",
  "aol",
  "openai",
  "chatgpt",
  "anthropic",
  "claude",
];

const SIGN_IN_WORDS = [
  "login",
  "logon",
  "signin",
  "secure",
  "verify",
  "verification",
  "account",
  "support",
  "wallet",
  "recovery",
  "recover",
  "update",
  "billing",
  "unlock",
  "auth",
  "password",
  "reset",
  "confirm",
];

export type SiteLabelProblem = "too_short" | "too_long" | "bad_chars" | "reserved" | "brand";

/** Why an address name can't be used, or null when it can. Expects the name lowercased. */
export function siteLabelProblem(label: string): SiteLabelProblem | null {
  if (label.length < 3) return "too_short";
  if (label.length > 40) return "too_long";
  if (!SITE_LABEL_PATTERN.test(label)) return "bad_chars";
  // Punycode (xn--) and other double hyphens at 3–4 are how look-alike names are spelled.
  if (label.slice(2, 4) === "--") return "bad_chars";
  if (RESERVED_SITE_LABELS.has(label) || label.startsWith("d-")) return "reserved";
  const parts = label.split("-");
  if (parts.some((p) => IMPERSONATED_BRANDS.includes(p))) return "brand";
  const squashed = label.replaceAll("-", "");
  if (
    IMPERSONATED_BRANDS.some((b) => b.length >= 4 && squashed.includes(b)) &&
    SIGN_IN_WORDS.some((w) => squashed.includes(w))
  )
    return "brand";
  return null;
}

/** A plain-words reason for each problem, for API errors and the app. */
export const SITE_LABEL_MESSAGES: Record<SiteLabelProblem | "taken" | "retired", string> = {
  too_short: "An address needs at least 3 characters.",
  too_long: "An address can be at most 40 characters.",
  bad_chars: "Use letters a to z, digits and hyphens, not starting or ending with a hyphen.",
  reserved: "That address is kept for Casama.",
  brand: "That address looks like another company's name, so it can't be used.",
  taken: "Someone already uses that address.",
  retired: "That address was used recently and can't be taken again yet.",
};

/** A site's address on the zone, one label deep so the zone's certificate covers it. */
export const siteAddress = (label: string, zone: string) => `${label}.${zone.toLowerCase()}`;

/** The label of a host directly under the zone, or null when it isn't one. */
export function labelUnderZone(host: string, zone: string | undefined | null) {
  if (!zone) return null;
  const z = zone.toLowerCase();
  if (!host.endsWith(`.${z}`)) return null;
  const label = host.slice(0, -(z.length + 1));
  return label && !label.includes(".") ? label : null;
}

/** An address name suggested from a page title: "Crumb & Co Bakery" → "crumb-co-bakery". */
export function suggestSiteLabel(title: string) {
  const s = title
    .normalize("NFKD")
    .replace(/[̀-ͯ]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 40)
    .replace(/-+$/g, "");
  return s.length >= 3 ? s : `${s || "site"}-${Math.random().toString(36).slice(2, 6)}`;
}

// ------------------------------------------------------------------ Hosts and domains

/** Host names are lowercase ASCII, at most 253 characters, labels at most 63. */
export const HOSTNAME_PATTERN =
  /^(?=.{1,253}$)(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z][a-z0-9-]{0,61}[a-z0-9]$/;

export type HostProblem = "empty" | "not_ascii" | "ip_address" | "invalid" | "no_domain" | "idn";

export interface ParsedHost {
  /** The exact host, lowercase, no port or trailing dot. */
  host: string;
  /** The registrable domain (`bakery.co.uk`). */
  domain: string;
  /** What's left of the domain (`www`, `shop`), or "" for the bare domain. */
  subdomain: string;
  publicSuffix: string;
}

/**
 * Turns what a person typed (`https://WWW.Bakery.com:443/menu`, `bakery.com.`) into a host, using
 * the Public Suffix List so `bakery.co.uk` is a bare domain. Returns the problem instead when it
 * isn't a name Casama can serve: an IP address, non-English letters, or no registrable domain.
 */
export function parseHost(input: string): ParsedHost | { problem: HostProblem } {
  let s = input.trim();
  if (!s) return { problem: "empty" };
  if (/[^\x21-\x7e]/.test(s)) return { problem: "not_ascii" };
  s = s.replace(/^[a-z][a-z0-9+.-]*:\/\//i, "");
  s = s.split(/[/?#]/)[0] ?? "";
  s = s.replace(/^[^@]*@/, "");
  if (s.startsWith("[")) return { problem: "ip_address" };
  s = s.replace(/:\d+$/, "").replace(/\.+$/, "").toLowerCase();
  if (!s) return { problem: "empty" };
  if (/^\d{1,3}(\.\d{1,3}){3}$/.test(s) || s.includes(":")) return { problem: "ip_address" };
  if (s.split(".").some((l) => l.startsWith("xn--"))) return { problem: "idn" };
  if (!HOSTNAME_PATTERN.test(s)) return { problem: "invalid" };
  const p = parse(s, { allowPrivateDomains: false });
  if (p.isIp) return { problem: "ip_address" };
  if (!p.domain || !p.publicSuffix || !p.isIcann) return { problem: "no_domain" };
  return { host: s, domain: p.domain, subdomain: p.subdomain ?? "", publicSuffix: p.publicSuffix };
}

export const HOST_MESSAGES: Record<HostProblem, string> = {
  empty: "Type a domain, such as bakery.com.",
  not_ascii: "Domains with letters outside a to z can't be used yet.",
  ip_address: "Use a domain name, not an IP address.",
  invalid: "That doesn't look like a domain. Try something like bakery.com.",
  no_domain: "That isn't a domain anyone can register. Try something like bakery.com.",
  idn: "Domains with letters outside a to z can't be used yet.",
};

/**
 * The hosts one entry makes (§7.5): `bakery.com` or `www.bakery.com` → the domain with `www`
 * (primary) and the bare name; `shop.bakery.com` → that one host.
 */
export function hostsFor(p: ParsedHost): { domain: string; hosts: string[]; primary: string } {
  if (p.subdomain === "" || p.subdomain === "www") {
    const www = `www.${p.domain}`;
    return { domain: p.domain, hosts: [www, p.domain], primary: www };
  }
  return { domain: p.host, hosts: [p.host], primary: p.host };
}

/** The name a domain's records point at (§7.4): its own, never reused. */
export function domainTarget(zone: string, random: string) {
  const code = random
    .toLowerCase()
    .replace(/[^a-z0-9]/g, "")
    .slice(0, 16);
  if (code.length < 16) throw new Error("a target needs 16 random letters and digits");
  return `d-${code}.${zone.toLowerCase()}`;
}

/** Host states (§7.4). */
export const HOST_STATUSES = [
  "pending_dns",
  "pending_cert",
  "active",
  "failed",
  "disconnected",
  "paused",
  "suspended",
] as const;
export type HostStatus = (typeof HOST_STATUSES)[number];

/** Reasons the edge or our checks give, in words the app can explain. */
export const HOST_REASONS = [
  "not_pointed",
  "caa_blocks",
  "held_elsewhere",
  "timed_out",
  "refused",
  "proof_gone",
  "plan_limit",
  "claimed_elsewhere",
  "suspended",
  "expired",
] as const;
export type HostReason = (typeof HOST_REASONS)[number];

/**
 * The only place that decides whether a host is served (§12): an address needs to be active; a
 * domain's host also needs Casama's own proof. The edge saying "active" alone is never enough.
 */
export function hostIsLive(row: {
  status: string;
  kind: string;
  verified_at: Date | string | null;
}) {
  if (row.status !== "active") return false;
  return row.kind === "address" || row.verified_at != null;
}

/** How long each waiting state lasts before it gives up (§7.4). */
export const HOST_TIMINGS = {
  /** Unproved claims are removed after a week (the edge bills pending hostnames). */
  pendingDnsMs: 7 * 86_400_000,
  /** A proved host whose certificate never came. */
  pendingCertMs: 72 * 3_600_000,
  /** Proof gone this long in a row disconnects a live host. */
  proofGoneMs: 7 * 86_400_000,
  /** After this another workspace may take over an unproved claim. */
  claimLockMs: 3_600_000,
  /** Looked at every minute for the first hour, then hourly. */
  fastCheckMs: 3_600_000,
} as const;

/** When an upkeep pass should look at a host next, given how long it has waited. */
export function hostCheckDue(o: {
  status: string;
  createdAt: Date;
  lastCheckedAt: Date | null;
  now: Date;
}) {
  if (!["pending_dns", "pending_cert", "active"].includes(o.status)) return false;
  if (!o.lastCheckedAt) return true;
  const since = o.now.getTime() - o.lastCheckedAt.getTime();
  if (o.status === "active") return since >= 86_400_000;
  const age = o.now.getTime() - o.createdAt.getTime();
  return age < HOST_TIMINGS.fastCheckMs ? since >= 55_000 : since >= 3_540_000;
}

// ------------------------------------------------------------------ Serving

/** Paths under this prefix belong to Casama on every site and are never a site's file. */
export const SITE_RESERVED_PREFIX = "/_casama/";

/** How bots are told to build a site (pages.publish and sites.publish). */
export const PAGE_SITE_NOTE =
  'If you have sites.publish, it puts a page on the web at its own address; build such a site with one index.html, relative links only (about.html, img/logo.png), a 404.html if you want your own not-found page, a <title> and <meta name="description"> on every page, a favicon.ico file, and nothing loaded from other sites (it won\'t load).';

export interface RenderableSite {
  title: string;
  html: string;
  /** The data block and theme go on the index only. */
  data?: unknown;
  index: boolean;
  /** Search engines may list it. */
  indexable: boolean;
  /** "Made with Casama · Report", always on site addresses (decision 7). */
  badge: boolean;
  /** The page takes input: every HTML file gets the form script. */
  collects: boolean;
}

const escapeHtml = (s: string) => s.replace(/[&<>"']/g, (c) => `&#${c.charCodeAt(0)};`);

/** A site's policy: its own files only, forms post back to it when it collects (§7.2). */
export const siteCsp = (collects: boolean) =>
  collects ? PAGE_CSP_ASSETS.replace("form-action 'none'", "form-action 'self'") : PAGE_CSP_ASSETS;

const SITE_THEME = `:root{--k-bg:#fbf8fd;--k-fg:#1d1b20;--k-muted:#625b71;--k-accent:#6750a4;--k-surface:#f3edf7;--k-font:system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;color-scheme:light dark}
@media (prefers-color-scheme:dark){:root{--k-bg:#141218;--k-fg:#e6e0e9;--k-muted:#cac4d0;--k-accent:#d0bcff;--k-surface:#211f26}}`;

const SITE_BADGE = `<div id="casama-badge" style="position:fixed;right:10px;bottom:10px;z-index:2147483647;font:12px/1.2 system-ui,-apple-system,sans-serif;background:rgba(20,18,24,.78);color:#fff;padding:6px 10px;border-radius:999px"><a href="https://casama.ai" rel="noopener" style="color:#fff;text-decoration:none">Made with Casama</a> · <a href="/_casama/report" style="color:#fff">Report</a></div>`;

/** The site runtime's endpoint: answers go to the site's own origin. */
export const SITE_COLLECT_PATH = "/_casama/collect";

const siteCollectScript = `<script>(function(){var u=${scriptJson(SITE_COLLECT_PATH)};
window.casama=window.casama||{};
window.casama.submit=function(d){return fetch(u,{method:"POST",headers:{"content-type":"application/json"},body:JSON.stringify(d||{}),credentials:"same-origin"}).then(function(r){if(!r.ok)throw new Error("Couldn't send ("+r.status+")");return r.json()})};
document.addEventListener("submit",function(e){var f=e.target;if(!f||!f.hasAttribute||!f.hasAttribute("data-casama-form"))return;e.preventDefault();var o={};new FormData(f).forEach(function(v,k){if(typeof v!=="string")return;if(k in o){o[k]=[].concat(o[k],v)}else{o[k]=v}});var b=f.querySelector("[type=submit]");if(b)b.disabled=true;window.casama.submit(o).then(function(){var t=f.getAttribute("data-casama-sent")||"Thanks, it's sent.";var p=document.createElement("p");p.textContent=t;p.setAttribute("role","status");f.replaceWith(p)}).catch(function(err){if(b)b.disabled=false;alert(err.message)})},true)})();</script>`;

/**
 * The document a site host serves (§7.2). Unlike renderPage: no "Updated" line, no `<base>` (the
 * site is at the root), `noindex` only when the site isn't indexable, the badge on addresses, and
 * the form script on every HTML file when the page collects.
 */
export function renderSite(s: RenderableSite) {
  const csp = siteCsp(s.collects);
  const head = [
    `<meta http-equiv="Content-Security-Policy" content="${csp}">`,
    `<meta charset="utf-8">`,
    /<meta[^>]+name=["']?viewport/i.test(s.html)
      ? ""
      : `<meta name="viewport" content="width=device-width,initial-scale=1">`,
    s.indexable ? "" : `<meta name="robots" content="noindex,nofollow">`,
    s.index ? `<style id="casama-theme">${SITE_THEME}</style>` : "",
    s.index
      ? `<script type="application/json" id="${PAGE_DATA_ID}">${scriptJson(s.data)}</script>`
      : "",
    s.collects ? siteCollectScript : "",
  ].join("");
  let html = s.html;
  if (!/<html[\s>]/i.test(html))
    html = `<!doctype html><html><head><title>${escapeHtml(s.title)}</title></head><body>${html}</body></html>`;
  if (!/<head[\s>]/i.test(html)) html = html.replace(/<html[^>]*>/i, (m) => `${m}<head></head>`);
  html = html.replace(/<head[^>]*>/i, (m) => `${m}${head}`);
  if (s.badge)
    html = /<\/body>/i.test(html)
      ? html.replace(/<\/body>(?![\s\S]*<\/body>)/i, `${SITE_BADGE}</body>`)
      : `${html}${SITE_BADGE}`;
  return html;
}

/** Response headers on a site host. */
export function siteHeaders(o: {
  indexable: boolean;
  collects: boolean;
  html: boolean;
  etag?: string;
}): Record<string, string> {
  return {
    "content-security-policy": siteCsp(o.collects),
    "x-content-type-options": "nosniff",
    "referrer-policy": "strict-origin-when-cross-origin",
    ...(o.indexable ? {} : { "x-robots-tag": "noindex, nofollow" }),
    "cache-control": o.html ? "public, max-age=60" : "public, max-age=300",
    "strict-transport-security": "max-age=31536000",
    "cross-origin-opener-policy": "same-origin",
    "permissions-policy": "camera=(), microphone=(), geolocation=(), payment=(), usb=()",
    ...(o.etag ? { etag: o.etag } : {}),
  };
}

/** The candidates a path may be, in order: `/about` → about, about.html, about/index.html. */
export function sitePathCandidates(path: string): string[] {
  let clean: string;
  try {
    clean = decodeURIComponent(path);
  } catch {
    return [];
  }
  clean = clean.replace(/^\/+/, "");
  if (clean.split("/").some((seg) => seg === ".." || seg === ".")) return [];
  if (clean.startsWith("_casama")) return [];
  if (!clean || clean.endsWith("/")) return [`${clean}index.html`];
  const last = clean.split("/").pop() ?? "";
  if (last.includes(".")) return [clean];
  return [clean, `${clean}.html`, `${clean}/index.html`];
}

/** The generated robots.txt: everything allowed with a sitemap when indexable, nothing when not. */
export function siteRobots(indexable: boolean, origin: string) {
  return indexable
    ? `User-agent: *\nAllow: /\nSitemap: ${origin.replace(/\/$/, "")}/sitemap.xml\n`
    : "User-agent: *\nDisallow: /\n";
}

/** The generated sitemap: the home page and every HTML file but 404.html. */
export function siteSitemap(origin: string, paths: string[]) {
  const base = origin.replace(/\/$/, "");
  const urls = new Set<string>([`${base}/`]);
  for (const p of [...paths].sort()) {
    if (!/\.html?$/i.test(p) || /(^|\/)404\.html?$/i.test(p) || p.startsWith("_casama")) continue;
    const url = p.endsWith("index.html") ? p.slice(0, -"index.html".length) : p;
    urls.add(`${base}/${url.split("/").map(encodeURIComponent).join("/")}`);
  }
  return `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${[
    ...urls,
  ]
    .map((u) => `  <url><loc>${escapeHtml(u)}</loc></url>`)
    .join("\n")}\n</urlset>\n`;
}

// ------------------------------------------------------------------ Selling domains

/** The endings on sale in v1 (§2.3, decision 14). */
export const DEFAULT_DOMAIN_TLDS = [
  "com",
  "net",
  "org",
  "co",
  "io",
  "app",
  "dev",
  "xyz",
  "me",
  "info",
] as const;

export interface DomainPriceSettings {
  markup: number;
  feeUsd: number;
}
export const DEFAULT_DOMAIN_PRICE: DomainPriceSettings = { markup: 1.25, feeUsd: 1.5 };

/**
 * What a person pays for a year (§8): cost × markup + fee, rounded up to the next .99. One
 * function for search, checkout and the renewal notice, so the price shown is the price charged.
 */
export function domainPriceUsd(costUsd: number, s: DomainPriceSettings = DEFAULT_DOMAIN_PRICE) {
  if (!(costUsd > 0)) throw new Error("a domain's cost must be above zero");
  const cents = Math.ceil(Math.round((costUsd * s.markup + s.feeUsd) * 1e6) / 1e4);
  const dollars = Math.ceil((cents + 1) / 100);
  return Math.round((dollars - 0.01) * 100) / 100;
}

/** Search candidates from what a person typed: the exact name on each ending, then variants. */
export function domainCandidates(query: string, tlds: readonly string[]): string[] {
  const q = query.trim().toLowerCase();
  const parsed = parseHost(q.includes(".") ? q : `${q}.com`);
  let base: string;
  let first: string | null = null;
  if (!("problem" in parsed) && q.includes(".")) {
    base = parsed.domain.slice(0, -(parsed.publicSuffix.length + 1));
    if (tlds.includes(parsed.publicSuffix)) first = parsed.domain;
  } else {
    base = q
      .normalize("NFKD")
      .replace(/[̀-ͯ]/g, "")
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/^-+|-+$/g, "");
  }
  base = base.replace(/\./g, "-").slice(0, 50);
  if (!base || base.length < 2) return [];
  const squashed = base.replaceAll("-", "");
  const names = new Set<string>();
  if (first) names.add(first);
  for (const t of tlds) names.add(`${squashed}.${t}`);
  if (base.includes("-")) for (const t of tlds.slice(0, 3)) names.add(`${base}.${t}`);
  for (const v of [`get${squashed}`, `${squashed}hq`, `try${squashed}`]) names.add(`${v}.com`);
  return [...names].filter((n) => HOSTNAME_PATTERN.test(n)).slice(0, 50);
}

/** The ending of a name on sale, or null when it isn't sold here. */
export function saleTld(name: string, tlds: readonly string[]) {
  const p = parseHost(name);
  if ("problem" in p || p.subdomain !== "") return null;
  return tlds.includes(p.publicSuffix) ? p.publicSuffix : null;
}

/** Transfers to another registrar may be refused for 60 days after registration (§2.3). */
export const TRANSFER_LOCK_DAYS = 60;

/** Days a bought domain stays in each state after its expiry (§7.8). */
export const EXPIRY_TIMELINE = {
  /** The registrar removes it from its API (Name.com). */
  lapsedAfterDays: 25,
  /** Registry grace (45) + redemption (30) + pending delete (5). */
  goneAfterDays: 80,
} as const;

export type RenewalNotice = "notice_30" | "notice_7" | "notice_1" | "expired_3" | "final_20";
export type RenewalCharge = "charge_14" | "charge_10" | "charge_7" | "charge_3";

const NOTICES: Array<[number, RenewalNotice]> = [
  [-20, "final_20"],
  [-3, "expired_3"],
  [1, "notice_1"],
  [7, "notice_7"],
  [30, "notice_30"],
];
const CHARGES: Array<[number, RenewalCharge]> = [
  [3, "charge_3"],
  [7, "charge_7"],
  [10, "charge_10"],
  [14, "charge_14"],
];

/**
 * What upkeep does for a bought domain `daysLeft` days before its expiry (negative: after). Each
 * step comes with its own name, which with the domain and expiry date is the dedupe key, so a
 * late or repeated run never charges or emails twice. Only the latest reached step of each kind
 * is returned: a run that was down for a week doesn't send the skipped notices in a burst.
 */
export function renewalPlan(daysLeft: number, autoRenew: boolean) {
  const state: "active" | "expired" | "lapsed" | "gone" =
    daysLeft <= -EXPIRY_TIMELINE.goneAfterDays
      ? "gone"
      : daysLeft <= -EXPIRY_TIMELINE.lapsedAfterDays
        ? "lapsed"
        : daysLeft <= 0
          ? "expired"
          : "active";
  const notice =
    daysLeft > 30 || state === "lapsed" || state === "gone"
      ? null
      : (NOTICES.find(([d]) => daysLeft <= d)?.[1] ?? null);
  const charge =
    autoRenew && daysLeft > 0 && daysLeft <= 14
      ? (CHARGES.find(([d]) => daysLeft <= d)?.[1] ?? null)
      : null;
  return { state, notice, charge };
}

/** Whole days from now until a date (negative after it), counted on the hour. */
export const daysUntil = (when: Date, now: Date) => (when.getTime() - now.getTime()) / 86_400_000;

// ------------------------------------------------------------------ DNS records

export const DNS_RECORD_TYPES = ["A", "AAAA", "CNAME", "MX", "TXT", "SRV"] as const;
export type DnsRecordType = (typeof DNS_RECORD_TYPES)[number];

export interface DnsRecord {
  id?: string;
  /** Relative to the domain: "" (or "@") for the domain itself, "www", "shop". */
  host: string;
  type: string;
  answer: string;
  ttl: number;
  priority?: number | null;
}

export const DNS_LIMITS = { maxRecords: 100, minTtl: 300, maxTxt: 2048 } as const;

const IPV4 = /^(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}$/;
const isIpv6 = (s: string) => {
  if (!/^[0-9a-f:]+$/i.test(s) || !s.includes(":")) return false;
  const parts = s.split("::");
  if (parts.length > 2) return false;
  const groups = parts.flatMap((p) => (p ? p.split(":") : []));
  if (groups.some((g) => g.length > 4 || !g)) return false;
  return parts.length === 2 ? groups.length < 8 : groups.length === 8;
};
const isHostname = (s: string) => HOSTNAME_PATTERN.test(s.replace(/\.$/, "").toLowerCase());
const RELATIVE =
  /^(\*|[a-z0-9_](?:[a-z0-9_-]{0,61}[a-z0-9])?)(\.[a-z0-9_](?:[a-z0-9_-]{0,61}[a-z0-9])?)*$/;

/** Normalises a record's name to the relative form: "@", "bakery.com", "WWW." → "", "", "www". */
export function relativeName(host: string, domain: string) {
  let h = host.trim().toLowerCase().replace(/\.$/, "");
  if (h === "@" || h === domain) return "";
  if (h.endsWith(`.${domain}`)) h = h.slice(0, -(domain.length + 1));
  return h;
}

/**
 * Checks one change against a domain's records before it's saved (§7.9). `managed` are the ids
 * Casama manages for the site: they can't be changed or removed here.
 */
export function checkDnsChange(o: {
  domain: string;
  existing: DnsRecord[];
  managed: string[];
  op: "add" | "change" | "delete";
  record: DnsRecord;
}): string[] {
  const errors: string[] = [];
  const { record: r } = o;
  if (o.op !== "add" && r.id && o.managed.includes(r.id))
    return ["This record is used by your Casama site. Disconnect the site to remove it."];
  if (o.op === "delete") return [];
  const host = relativeName(r.host, o.domain);
  if (host && (!RELATIVE.test(host) || `${host}.${o.domain}`.length > 253))
    errors.push("The name must be inside this domain, like www or shop.");
  const type = r.type.toUpperCase();
  if (!(DNS_RECORD_TYPES as readonly string[]).includes(type))
    errors.push(`Records can be ${DNS_RECORD_TYPES.join(", ")}.`);
  if (!Number.isInteger(r.ttl) || r.ttl < DNS_LIMITS.minTtl)
    errors.push(`The TTL must be at least ${DNS_LIMITS.minTtl} seconds.`);
  const answer = r.answer.trim();
  if (!answer) errors.push("The record needs a value.");
  else if (type === "A" && !IPV4.test(answer)) errors.push("An A record needs an IPv4 address.");
  else if (type === "AAAA" && !isIpv6(answer)) errors.push("An AAAA record needs an IPv6 address.");
  else if ((type === "CNAME" || type === "MX") && !isHostname(answer))
    errors.push(`A ${type} record points at a host name, like mail.example.com.`);
  else if (type === "TXT" && answer.length > DNS_LIMITS.maxTxt)
    errors.push(`A TXT record can be up to ${DNS_LIMITS.maxTxt} characters.`);
  else if (type === "SRV" && !/^\d{1,5} \d{1,5} \S+$/.test(answer))
    errors.push("An SRV record is written as weight port target, like 10 5060 sip.example.com.");
  if (type === "MX" && (r.priority == null || r.priority < 0 || r.priority > 65535))
    errors.push("An MX record needs a priority from 0 to 65535.");
  if (type === "CNAME" && host === "")
    errors.push("The domain itself can't have a CNAME record; use www.");
  const others = o.existing.filter(
    (e) => relativeName(e.host, o.domain) === host && (o.op === "add" || e.id !== r.id),
  );
  if (type === "CNAME" && others.length)
    errors.push("A CNAME record can't share its name with other records.");
  if (type !== "CNAME" && others.some((e) => e.type.toUpperCase() === "CNAME"))
    errors.push("That name already has a CNAME record, which can't share its name.");
  if (o.op === "add" && o.existing.length >= DNS_LIMITS.maxRecords)
    errors.push(`A domain can have up to ${DNS_LIMITS.maxRecords} records.`);
  return errors;
}

// ------------------------------------------------------------------ Registrant contact

export interface DomainContact {
  first_name: string;
  last_name: string;
  organization?: string | null;
  address1: string;
  address2?: string | null;
  city: string;
  state: string;
  zip: string;
  /** Two letters. */
  country: string;
  /** International form: +1.4155550100 or +14155550100. */
  phone: string;
  email: string;
}

/** Every required field, a two-letter country, a phone in international form, an email (§7.7). */
export function checkDomainContact(c: Partial<DomainContact>): string[] {
  const errors: string[] = [];
  const req = (k: keyof DomainContact, label: string) => {
    const v = c[k];
    if (typeof v !== "string" || !v.trim()) errors.push(`${label} is required.`);
    else if (v.length > 200) errors.push(`${label} is too long.`);
  };
  req("first_name", "First name");
  req("last_name", "Last name");
  req("address1", "Address");
  req("city", "City");
  req("state", "State or region");
  req("zip", "Postal code");
  if (!/^[A-Z]{2}$/.test(c.country ?? ""))
    errors.push("Country must be a two-letter code, like US.");
  if (!/^\+[1-9]\d{7,14}$/.test(registrarPhone(c.phone ?? "")))
    errors.push("Phone must be in international form, like +1 415 555 0100.");
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(c.email ?? "")) errors.push("Email isn't valid.");
  return errors;
}

/** The registrar's phone format: E.164, `+` and digits only (Name.com Core API v1). */
export function registrarPhone(phone: string) {
  return phone.replace(/[\s().-]/g, "");
}
