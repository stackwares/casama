/**
 * Places a bot can't take a browser (D-323 Phase 3, plan §11), checked on the server for both browser
 * backends. The extension keeps the same lists in apps/extension/src/lib/guard.ts (a test checks they
 * agree) and also refuses the kinds of site that are off by default.
 *
 * Casama's own web app, API and sign-in addresses come first: a bot must never click Approve on its
 * own approval or change its own rules through Casama's screens.
 */

/** Casama's public domains; every subdomain counts. */
export const CASAMA_DOMAINS = ["casama.ai", "casama.link", "kasama.ai"] as const;

const within = (host: string, domain: string) => host === domain || host.endsWith(`.${domain}`);

/** The host of an address without a trailing dot or "www.", lowercased; null when it isn't one. */
export function hostOf(url: string): string | null {
  try {
    return new URL(url).hostname
      .toLowerCase()
      .replace(/\.$/, "")
      .replace(/^www\./, "");
  } catch {
    return null;
  }
}

/**
 * Whether [url] is one of Casama's own pages: a Casama domain, or this server's own addresses
 * ([ownUrls]: the API, the web app and sign-in, as configured).
 */
export function isCasamaAddress(url: string, ownUrls: Array<string | undefined | null> = []) {
  const host = hostOf(url);
  if (!host) return false;
  if (CASAMA_DOMAINS.some((d) => within(host, d))) return true;
  let hostPort: string;
  try {
    hostPort = new URL(url).host.toLowerCase().replace(/\.(?=:|$)/, "");
  } catch {
    return false;
  }
  for (const own of ownUrls) {
    if (!own) continue;
    try {
      if (new URL(own).host.toLowerCase() === hostPort) return true;
    } catch {
      // Not an address.
    }
  }
  return false;
}

/** Addresses a browser tool may open at all: web pages only, never browser or extension pages. */
export function browsable(url: string): boolean {
  return (
    /^https?:\/\//i.test(url) &&
    !/^https?:\/\/(chrome\.google\.com\/webstore|chromewebstore\.google\.com)/i.test(url)
  );
}

/**
 * A site list entry matches a host: "example.com" matches it and its subdomains; "*.example.com"
 * only subdomains.
 */
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

/** A site list entry as stored: a bare host or *.host, at most 253 characters. */
export function cleanSitePattern(raw: string): string | null {
  const p = raw
    .trim()
    .toLowerCase()
    .replace(/^https?:\/\//, "")
    .replace(/[/?#].*$/, "")
    .replace(/:\d+$/, "")
    .replace(/^www\./, "");
  if (!p || p.length > 253) return null;
  return /^(\*\.)?[a-z0-9-]+(\.[a-z0-9-]+)+$/.test(p) || p === "localhost" ? p : null;
}

/**
 * Kinds of site that are off by default for the extension (D-323): banking and payments, health
 * portals, password managers and government ID sites. The lists are well-known hosts and the words
 * their addresses tend to carry. The extension's guard uses these lists; the server uses them to
 * refuse browser triggers on such sites ("when I open my bank's site").
 */
export type SensitiveSiteKind = "banking" | "health" | "passwords" | "government";

export const SENSITIVE_SITE_HOSTS: Record<SensitiveSiteKind, readonly string[]> = {
  banking: [
    "paypal.com",
    "stripe.com",
    "wise.com",
    "chase.com",
    "bankofamerica.com",
    "wellsfargo.com",
    "citi.com",
    "capitalone.com",
    "americanexpress.com",
    "hsbc.com",
    "barclays.co.uk",
    "revolut.com",
    "monzo.com",
    "n26.com",
    "schwab.com",
    "fidelity.com",
    "vanguard.com",
    "robinhood.com",
    "coinbase.com",
    "binance.com",
    "kraken.com",
    "venmo.com",
    "bdo.com.ph",
    "bpi.com.ph",
    "gcash.com",
    "maya.ph",
  ],
  health: [
    "mychart.org",
    "epic.com",
    "patient.info",
    "healthvault.com",
    "kaiserpermanente.org",
    "nhs.uk",
    "zocdoc.com",
    "doximity.com",
    "teladoc.com",
    "23andme.com",
  ],
  passwords: [
    "1password.com",
    "bitwarden.com",
    "lastpass.com",
    "dashlane.com",
    "keepersecurity.com",
    "nordpass.com",
    "proton.me",
    "passwords.google.com",
  ],
  government: [
    "irs.gov",
    "ssa.gov",
    "login.gov",
    "id.me",
    "gov.uk",
    "service.gov.uk",
    "usps.com",
    "dmv.ca.gov",
    "philsys.gov.ph",
    "bir.gov.ph",
  ],
};

export const SENSITIVE_SITE_WORDS: Partial<Record<SensitiveSiteKind, RegExp>> = {
  banking: /(^|[.-])(bank|banking|onlinebanking|netbanking|ebanking|creditunion)([.-]|$)/,
  health: /(^|[.-])(mychart|patientportal|patient|health|clinic|hospital)([.-]|$)/,
  government: /(^|\.)gov(\.[a-z]{2})?$|(^|\.)gob\.[a-z]{2}$|(^|\.)gouv\.[a-z]{2}$/,
};

export const SENSITIVE_SITE_KINDS = ["passwords", "banking", "health", "government"] as const;

/** Hosts added to the lists above without a release (D-374). */
export type SensitiveSiteAdditions = Partial<Record<SensitiveSiteKind, readonly string[]>>;

/** How many hosts one kind may add; more is refused on save and cut on load. */
export const MAX_GUARD_ADDITIONS = 500;

/**
 * Checks added sites (D-374): known kinds, plain hosts. Additions only ever add to the lists in
 * code, so there's nothing here that could remove a site. `hosts` keeps what passed (kinds this
 * version doesn't know are skipped); a save is refused when `errors` isn't empty.
 */
export function checkGuardAdditions(raw: unknown): {
  hosts: Record<SensitiveSiteKind, string[]>;
  errors: string[];
} {
  const hosts: Record<SensitiveSiteKind, string[]> = {
    passwords: [],
    banking: [],
    health: [],
    government: [],
  };
  const errors: string[] = [];
  if (raw === undefined || raw === null) return { hosts, errors };
  if (typeof raw !== "object" || Array.isArray(raw))
    return { hosts, errors: ["the added sites must map kinds to lists of hosts"] };
  for (const [kind, list] of Object.entries(raw as Record<string, unknown>)) {
    if (!(SENSITIVE_SITE_KINDS as readonly string[]).includes(kind)) {
      errors.push(`${kind} isn't a kind (${SENSITIVE_SITE_KINDS.join(", ")})`);
      continue;
    }
    if (!Array.isArray(list)) {
      errors.push(`${kind} must be a list of hosts`);
      continue;
    }
    if (list.length > MAX_GUARD_ADDITIONS)
      errors.push(`${kind} has more than ${MAX_GUARD_ADDITIONS} hosts`);
    const out = hosts[kind as SensitiveSiteKind];
    for (const h of list.slice(0, MAX_GUARD_ADDITIONS)) {
      const clean = typeof h === "string" ? cleanSitePattern(h)?.replace(/^\*\./, "") : null;
      if (!clean || clean === "localhost" || !clean.includes(".")) {
        errors.push(`${kind}: ${String(h).slice(0, 80)} isn't a host like bank.example`);
        continue;
      }
      if (!out.includes(clean)) out.push(clean);
    }
  }
  return { hosts, errors };
}

let additions: SensitiveSiteAdditions = {};

/** Replaces the added sites the server checks (it loads them every minute); bad entries are left out. */
export function setSensitiveSiteAdditions(raw: unknown) {
  additions = checkGuardAdditions(raw).hosts;
}
export function sensitiveSiteAdditions(): SensitiveSiteAdditions {
  return additions;
}

/**
 * The off-by-default kind [host] belongs to, or null. [allowed]: kinds the person switched back on.
 * [extra]: hosts added without a release (D-374); the server's loaded list unless given. They only
 * add: a host in the lists above stays guarded whatever [extra] holds.
 */
export function sensitiveSiteKind(
  host: string,
  allowed: readonly SensitiveSiteKind[] = [],
  extra: SensitiveSiteAdditions = additions,
): SensitiveSiteKind | null {
  const h = host
    .toLowerCase()
    .replace(/\.$/, "")
    .replace(/^www\./, "");
  for (const kind of SENSITIVE_SITE_KINDS) {
    if (allowed.includes(kind)) continue;
    if (
      SENSITIVE_SITE_HOSTS[kind].some((d) => within(h, d)) ||
      SENSITIVE_SITE_WORDS[kind]?.test(h) ||
      extra[kind]?.some((d) => within(h, d))
    )
      return kind;
  }
  return null;
}

/**
 * A browser trigger's site (D-323 E4), cleaned, or why it can't be one: Casama's own and the
 * off-by-default kinds of site never start routines ("when I open my bank's site" doesn't work).
 */
export function browserTriggerSite(raw: string): { site: string } | { error: string } {
  const site = cleanSitePattern(raw)?.replace(/^\*\./, "");
  if (!site) return { error: "site_opened needs a site like wiki.example.com" };
  if (CASAMA_DOMAINS.some((d) => within(site, d)))
    return { error: "Casama's own pages can't start a routine" };
  const kind = sensitiveSiteKind(site);
  if (kind)
    return {
      error: `${site} is a ${kind === "passwords" ? "password manager" : kind === "government" ? "government ID" : kind} site; those never start routines`,
    };
  return { site };
}
