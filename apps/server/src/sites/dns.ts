/**
 * DNS lookups for proving a connected domain is theirs (docs/SITES-AND-DOMAINS-PLAN.md §7.4).
 *
 * Asked over DNS-over-HTTPS (the JSON form Cloudflare and Google both answer) of two public
 * resolvers that must agree, each with a 5-second limit, so one resolver's stale cache or outage
 * never proves or disproves a host on its own. A lookup that can't be settled answers null, and
 * the caller treats that as "not now", never as "gone".
 */

export interface DnsLookup {
  /** Every CNAME on the way from [host] (lowercase, no trailing dot); null when unsettled. */
  cnames(host: string): Promise<string[] | null>;
  /** The TXT strings at [name]; null when unsettled. */
  txt(name: string): Promise<string[] | null>;
  /** The domain's nameservers; null when unsettled. */
  ns(domain: string): Promise<string[] | null>;
}

interface DohAnswer {
  name?: string;
  type?: number;
  data?: string;
}
interface DohResponse {
  Status?: number;
  Answer?: DohAnswer[];
}

const TYPES = { A: 1, NS: 2, CNAME: 5, TXT: 16 } as const;
const NXDOMAIN = 3;

const clean = (s: string) => s.trim().replace(/\.$/, "").toLowerCase();
/** TXT data comes quoted, possibly split in 255-character pieces: "abc" "def". */
const txtValue = (data: string) => {
  const parts = data.match(/"((?:[^"\\]|\\.)*)"/g);
  return parts ? parts.map((p) => p.slice(1, -1).replace(/\\(.)/g, "$1")).join("") : data.trim();
};

export class DohLookup implements DnsLookup {
  private readonly urls: string[];
  private readonly fetch: typeof fetch;
  private readonly timeoutMs: number;

  constructor(o: { urls: string[]; fetch?: typeof fetch; timeoutMs?: number }) {
    this.urls = o.urls.length ? o.urls : ["https://cloudflare-dns.com/dns-query"];
    this.fetch = o.fetch ?? fetch;
    this.timeoutMs = o.timeoutMs ?? 5000;
  }

  private async ask(url: string, name: string, type: keyof typeof TYPES): Promise<DohAnswer[]> {
    const q = new URL(url);
    q.searchParams.set("name", name);
    q.searchParams.set("type", type);
    const res = await this.fetch(q, {
      headers: { accept: "application/dns-json" },
      signal: AbortSignal.timeout(this.timeoutMs),
    });
    if (!res.ok) throw new Error(`resolver answered ${res.status}`);
    const json = (await res.json()) as DohResponse;
    if (json.Status === NXDOMAIN) return [];
    if (json.Status !== 0) throw new Error(`resolver status ${json.Status}`);
    return json.Answer ?? [];
  }

  /** Both resolvers' answers, mapped; null unless every resolver answered the same set. */
  private async agree(
    name: string,
    type: keyof typeof TYPES,
    pick: (answers: DohAnswer[]) => string[],
  ): Promise<string[] | null> {
    let results: string[][];
    try {
      results = await Promise.all(this.urls.map(async (u) => pick(await this.ask(u, name, type))));
    } catch {
      return null;
    }
    const key = (r: string[]) => [...new Set(r)].sort().join("\n");
    const first = key(results[0] ?? []);
    return results.every((r) => key(r) === first) ? [...new Set(results[0])] : null;
  }

  cnames(host: string) {
    // An A query returns the whole CNAME chain on the way to the address.
    return this.agree(host, "A", (a) =>
      a.filter((x) => x.type === TYPES.CNAME && x.data).map((x) => clean(x.data as string)),
    );
  }

  txt(name: string) {
    return this.agree(name, "TXT", (a) =>
      a.filter((x) => x.type === TYPES.TXT && x.data).map((x) => txtValue(x.data as string)),
    );
  }

  ns(domain: string) {
    return this.agree(domain, "NS", (a) =>
      a.filter((x) => x.type === TYPES.NS && x.data).map((x) => clean(x.data as string)),
    );
  }
}

/**
 * Each DNS company `dnsProviderFor` knows, by its own name (D-372): sent with a domain as
 * `dns_provider_name` and in the app settings, so the apps don't keep a copy.
 */
export const DNS_PROVIDER_NAMES: Record<string, string> = {
  cloudflare: "Cloudflare",
  godaddy: "GoDaddy",
  namecheap: "Namecheap",
  namecom: "Name.com",
  google: "Google",
  route53: "Amazon Route 53",
  dnsimple: "DNSimple",
  porkbun: "Porkbun",
  squarespace: "Squarespace",
  hover: "Hover",
  gandi: "Gandi",
  ns1: "NS1",
  vercel: "Vercel",
  netlify: "Netlify",
};

/** The DNS company behind a domain's nameservers, for the right instructions (§7.5). */
export function dnsProviderFor(nameservers: string[]): string | null {
  const ns = nameservers.join(" ");
  const known: Array<[RegExp, string]> = [
    [/\.ns\.cloudflare\.com\b/, "cloudflare"],
    [/\bdomaincontrol\.com\b/, "godaddy"],
    [/\bregistrar-servers\.com\b/, "namecheap"],
    [/\bname\.com\b/, "namecom"],
    [/\bgoogledomains\.com\b|\bns-cloud-[a-e]\d\.googledomains\.com\b/, "google"],
    [/\bawsdns-/, "route53"],
    [/\bdnsimple\.com\b/, "dnsimple"],
    [/\bporkbun\.com\b/, "porkbun"],
    [/\bsquarespacedns\.com\b|\bdomains\.squarespace\.com\b/, "squarespace"],
    [/\bhover\.com\b/, "hover"],
    [/\bgandi\.net\b/, "gandi"],
    [/\bnsone\.net\b/, "ns1"],
    [/\bvercel-dns\.com\b/, "vercel"],
    [/\bnetlify\b/, "netlify"],
  ];
  for (const [re, name] of known) if (re.test(ns)) return name;
  return null;
}

/**
 * DNS companies that take an ALIAS or ANAME record at the bare domain to any name (Route 53's
 * alias only reaches AWS, so it isn't here). Used only with CASAMA_SITES_APEX=aname, which waits
 * on the Phase 2 live check (§7.5); Cloudflare's flattened CNAME is always offered.
 */
export const APEX_ALIAS_PROVIDERS = new Set(["dnsimple", "namecom", "porkbun", "ns1"]);
