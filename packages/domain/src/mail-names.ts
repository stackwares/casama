/**
 * Hosted bot mail (BOT-EMAIL-PLAN §4.1): the rules for `name@<mail domain>`. Lowercase letters,
 * digits, dots, hyphens and underscores; starts and ends with a letter or digit; 3 to 40
 * characters; no two dots in a row. The namespace is shared by every workspace on Casama Cloud,
 * first come first served, and a claimed name is never reissued.
 */
export const MAIL_NAME_PATTERN = /^[a-z0-9][a-z0-9._-]{1,38}[a-z0-9]$/;
export const MAIL_NAME_MIN = 3;
export const MAIL_NAME_MAX = 40;

/** Names nobody may claim: roles, Casama's own names, and impersonation targets. */
export const RESERVED_MAIL_NAMES = [
  // Role names.
  "admin",
  "administrator",
  "support",
  "billing",
  "security",
  "abuse",
  "postmaster",
  "hostmaster",
  "webmaster",
  "noreply",
  "no-reply",
  "help",
  "info",
  "team",
  "hello",
  "hi",
  "mail",
  "mailer-daemon",
  "mailerdaemon",
  "newsletter",
  "news",
  "notifications",
  "notify",
  "alerts",
  "contact",
  "sales",
  "careers",
  "jobs",
  "press",
  "legal",
  "privacy",
  "terms",
  "api",
  "dev",
  "developer",
  "developers",
  "status",
  "root",
  "test",
  // Casama's own names.
  "casama",
  "stackwares",
  "oliver",
  // Banks, payment and mail providers, stores: impersonation targets.
  "paypal",
  "stripe",
  "visa",
  "mastercard",
  "amex",
  "chase",
  "bankofamerica",
  "wellsfargo",
  "apple",
  "google",
  "gmail",
  "outlook",
  "hotmail",
  "yahoo",
  "icloud",
  "amazon",
  "ebay",
  "walmart",
  "target",
  "bestbuy",
  "irs",
  "usps",
  "fedex",
  "ups",
  "dhl",
  // More brands and services (2026-11-20): distinctive ones also block as a part of a name below;
  // everyday words and first names (maya, smart, grab) only as the whole name.
  "microsoft",
  "office365",
  "microsoft365",
  "linkedin",
  "facebook",
  "instagram",
  "whatsapp",
  "twitter",
  "tiktok",
  "netflix",
  "spotify",
  "adobe",
  "dropbox",
  "docusign",
  "coinbase",
  "binance",
  "venmo",
  "cashapp",
  "zelle",
  "revolut",
  "citibank",
  "hsbc",
  "barclays",
  "santander",
  "americanexpress",
  "capitalone",
  "usbank",
  "roblox",
  "epicgames",
  "nintendo",
  "playstation",
  "xbox",
  "openai",
  "chatgpt",
  "anthropic",
  "shopify",
  "etsy",
  "airbnb",
  "uber",
  "expedia",
  "github",
  "gitlab",
  "okta",
  "cloudflare",
  "intuit",
  "quickbooks",
  "turbotax",
  "aliexpress",
  "alibaba",
  "temu",
  "shein",
  "samsung",
  "huawei",
  "xiaomi",
  "telegram",
  "discord",
  "reddit",
  "pinterest",
  "snapchat",
  "youtube",
  "protonmail",
  "godaddy",
  "namecheap",
  "metamask",
  "trezor",
  "kraken",
  "robinhood",
  "fidelity",
  "vanguard",
  "schwab",
  "etrade",
  "gcash",
  "paymaya",
  "bdo",
  "bpi",
  "metrobank",
  "landbank",
  "unionbank",
  "securitybank",
  "rcbc",
  "chinabank",
  "eastwestbank",
  "lazada",
  "shopee",
  "pldt",
  "philhealth",
  "pagibig",
  "meta",
  "wise",
  "discover",
  "citi",
  "signal",
  "zoom",
  "notion",
  "ledger",
  "steam",
  "booking",
  "slack",
  "azure",
  "aws",
  "proton",
  "zoho",
  "maya",
  "smart",
  "globe",
  "grab",
  "converge",
  "sss",
  "bir",
  "lto",
  "dfa",
  "psa",
  "twitch",
] as const;

/** Brand and Casama names blocked even as a dot/hyphen/underscore segment (e.g. `paypal.support`). */
const BRAND_RESERVED_NAMES = new Set<string>([
  "casama",
  "stackwares",
  "paypal",
  "stripe",
  "visa",
  "mastercard",
  "amex",
  "chase",
  "bankofamerica",
  "wellsfargo",
  "apple",
  "google",
  "gmail",
  "outlook",
  "hotmail",
  "yahoo",
  "icloud",
  "amazon",
  "ebay",
  "walmart",
  "target",
  "bestbuy",
  "irs",
  "usps",
  "fedex",
  "ups",
  "dhl",
  "microsoft",
  "office365",
  "microsoft365",
  "linkedin",
  "facebook",
  "instagram",
  "whatsapp",
  "twitter",
  "tiktok",
  "netflix",
  "spotify",
  "adobe",
  "dropbox",
  "docusign",
  "coinbase",
  "binance",
  "venmo",
  "cashapp",
  "zelle",
  "revolut",
  "citibank",
  "hsbc",
  "barclays",
  "santander",
  "americanexpress",
  "capitalone",
  "usbank",
  "roblox",
  "epicgames",
  "nintendo",
  "playstation",
  "xbox",
  "openai",
  "chatgpt",
  "anthropic",
  "shopify",
  "etsy",
  "airbnb",
  "uber",
  "expedia",
  "github",
  "gitlab",
  "okta",
  "cloudflare",
  "intuit",
  "quickbooks",
  "turbotax",
  "aliexpress",
  "alibaba",
  "temu",
  "shein",
  "samsung",
  "huawei",
  "xiaomi",
  "telegram",
  "discord",
  "reddit",
  "pinterest",
  "snapchat",
  "youtube",
  "protonmail",
  "godaddy",
  "namecheap",
  "metamask",
  "trezor",
  "kraken",
  "robinhood",
  "fidelity",
  "vanguard",
  "schwab",
  "etrade",
  "gcash",
  "paymaya",
  "bdo",
  "bpi",
  "metrobank",
  "landbank",
  "unionbank",
  "securitybank",
  "rcbc",
  "chinabank",
  "eastwestbank",
  "lazada",
  "shopee",
  "pldt",
  "philhealth",
  "pagibig",
]);

/**
 * Why a name can't be claimed, in the app's words; null when it's free to check against the
 * database. `instanceOwner`: the person running the instance may claim reserved names (Casama's own,
 * and the ones held in Admin); the shape rules still apply. Names held in Admin block only that
 * exact name, so holding `max` doesn't block `max.helper`.
 */
export function mailNameIssue(
  name: string,
  extraReserved: readonly string[] = [],
  o: { instanceOwner?: boolean } = {},
): string | null {
  const n = name.trim().toLowerCase();
  if (!n) return "Give the address a name.";
  if (n.length < MAIL_NAME_MIN || n.length > MAIL_NAME_MAX)
    return `Names are ${MAIL_NAME_MIN} to ${MAIL_NAME_MAX} characters.`;
  if (!MAIL_NAME_PATTERN.test(n) || n.includes(".."))
    return "Use lowercase letters, numbers, dots, hyphens and underscores; start and end with a letter or number.";
  if (o.instanceOwner) return null;
  const extra = new Set(extraReserved.map((s) => s.trim().toLowerCase()).filter(Boolean));
  const segments = n.split(/[._-]+/);
  if (
    (RESERVED_MAIL_NAMES as readonly string[]).includes(n) ||
    extra.has(n) ||
    segments.some((seg) => BRAND_RESERVED_NAMES.has(seg))
  )
    return "That name is reserved. Pick another.";
  return null;
}

/** A claimable base from a bot's display name; `fallback` when nothing usable is left. */
export function mailBaseName(botName: string, fallback = "assistant"): string {
  let s = botName
    .normalize("NFKD")
    .replace(/[̀-ͯ]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9._-]+/g, ".")
    .replace(/\.+/g, ".")
    .replace(/^[._-]+|[._-]+$/g, "")
    .slice(0, MAIL_NAME_MAX)
    .replace(/[._-]+$/g, "");
  if (/^[0-9._-]+$/.test(s)) s = "";
  if (!s) return fallback;
  if (s.length < MAIL_NAME_MIN) s = `${s}.bot`;
  return s;
}

/**
 * Free names for the claim sheet, best first: the bot's name, then with the owner's name, then
 * numbered. `taken` is checked in order; at most `limit` names come back.
 */
export function suggestMailNames(
  botName: string,
  ownerName: string | null,
  taken: (name: string) => boolean,
  extraReserved: readonly string[] = [],
  limit = 3,
): string[] {
  const base = mailBaseName(botName);
  const ownerParts = (ownerName ?? "")
    .normalize("NFKD")
    .replace(/[̀-ͯ]/g, "")
    .toLowerCase()
    .split(/[^a-z0-9]+/)
    .filter((p) => p.length >= 2);
  const candidates = [
    base,
    ...ownerParts.slice(0, 2).map((p) => `${base}.${p}`.slice(0, MAIL_NAME_MAX)),
    `${base}.bot`.slice(0, MAIL_NAME_MAX),
    ...[2, 3, 4, 5, 6, 7, 8, 9].map((i) => `${base}${i}`.slice(0, MAIL_NAME_MAX)),
    ...[2, 3, 4, 5].map((i) => `${base}-${i}`.slice(0, MAIL_NAME_MAX)),
  ];
  const out: string[] = [];
  for (const c of candidates) {
    if (out.length >= limit) break;
    if (out.includes(c)) continue;
    if (mailNameIssue(c, extraReserved)) continue;
    if (!taken(c)) out.push(c);
  }
  return out;
}

/** Splits `ada+shop@domain` into its name and tag; the tag is empty when there is none. */
export function splitMailTag(address: string): { name: string; tag: string } {
  const local = address.split("@")[0] ?? "";
  const plus = local.indexOf("+");
  if (plus < 0) return { name: local.toLowerCase(), tag: "" };
  return { name: local.slice(0, plus).toLowerCase(), tag: local.slice(plus + 1) };
}

/**
 * A string list as a Postgres `text[]` literal, quoted so any characters in the values (quotes,
 * backslashes, commas in odd addresses) can't break out of it. The driver sends JS arrays as
 * JSON, so array parameters go through this instead.
 */
export function pgTextArray(items: readonly string[]): string {
  return `{${items.map((s) => `"${s.replace(/\\/g, "\\\\").replace(/"/g, '\\"')}"`).join(",")}}`;
}

/**
 * User text for a LIKE pattern: `%`, `_` and backslashes lose their magic (backslash is LIKE's
 * default escape, so no `escape` clause is needed).
 */
export function likeEscape(s: string): string {
  return s.replace(/\\/g, "\\\\").replace(/%/g, "\\%").replace(/_/g, "\\_");
}

/** Whether a string is a single email address (no commas, semicolons, whitespace, or multiple `@`). */
export function isSingleEmailAddress(address: string): boolean {
  const s = address.trim();
  return /^[^\s,;<>@]+@[^\s,;<>@]+\.[^\s,;<>@]+$/.test(s);
}

/** Reserved and example domains no mail ever goes to. */
export function isUndeliverableAddress(address: string): boolean {
  if (!isSingleEmailAddress(address)) return true;
  const domain = (address.split("@")[1] ?? "").trim().toLowerCase().replace(/\.$/, "");
  if (!domain) return true;
  if (["example.com", "example.net", "example.org", "localhost"].includes(domain)) return true;
  if (/\.(example|test|invalid|localhost)$/.test(domain)) return true;
  return /(^|\.)example\.(com|net|org)$/.test(domain);
}
