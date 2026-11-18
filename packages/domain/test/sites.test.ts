import { describe, expect, it } from "vitest";
import { PAGE_CSP_ASSETS } from "../src/pages.ts";
import {
  checkDnsChange,
  checkDomainContact,
  type DnsRecord,
  domainCandidates,
  domainPriceUsd,
  domainTarget,
  hostCheckDue,
  hostIsLive,
  hostsFor,
  labelUnderZone,
  parseHost,
  registrarPhone,
  renderSite,
  renewalPlan,
  saleTld,
  siteCsp,
  siteHeaders,
  siteLabelProblem,
  sitePathCandidates,
  siteRobots,
  siteSitemap,
  suggestSiteLabel,
} from "../src/sites.ts";

describe("address names", () => {
  it("takes ordinary names", () => {
    for (const ok of ["bakery", "crumb-and-co", "a1b", "x".repeat(40), "my-site-2026"])
      expect(siteLabelProblem(ok), ok).toBeNull();
  });
  it("refuses short, long and badly formed names", () => {
    expect(siteLabelProblem("ab")).toBe("too_short");
    expect(siteLabelProblem("x".repeat(41))).toBe("too_long");
    expect(siteLabelProblem("-bakery")).toBe("bad_chars");
    expect(siteLabelProblem("bakery-")).toBe("bad_chars");
    expect(siteLabelProblem("bak_ery")).toBe("bad_chars");
    expect(siteLabelProblem("Bakery")).toBe("bad_chars");
    expect(siteLabelProblem("xn--80ak6aa92e")).toBe("bad_chars");
    expect(siteLabelProblem("bäckerei")).toBe("bad_chars");
  });
  it("keeps the reserved names and every domain target", () => {
    for (const r of ["www", "mail", "api", "admin", "login", "secure", "support", "billing"])
      expect(siteLabelProblem(r)).toBe("reserved");
    expect(siteLabelProblem("status")).toBe("reserved");
    expect(siteLabelProblem("casama")).toBe("reserved");
    expect(siteLabelProblem("d-abcdefgh12345678")).toBe("reserved");
  });
  it("refuses names that pretend to be a brand", () => {
    expect(siteLabelProblem("paypal")).toBe("brand");
    expect(siteLabelProblem("paypal-help")).toBe("brand");
    expect(siteLabelProblem("secure-chase")).toBe("brand");
    expect(siteLabelProblem("appleidverify")).toBe("brand");
    expect(siteLabelProblem("coinbaselogin")).toBe("brand");
    // A brand inside an ordinary word is fine when nothing sign-in-like goes with it.
    expect(siteLabelProblem("pineapple-pies")).toBeNull();
    expect(siteLabelProblem("upstairs-cafe")).toBeNull();
  });
  it("suggests a name from a title", () => {
    expect(suggestSiteLabel("Crumb & Co Bakery")).toBe("crumb-co-bakery");
    expect(suggestSiteLabel("Café Olé")).toBe("cafe-ole");
    expect(suggestSiteLabel("X").length).toBeGreaterThanOrEqual(3);
  });
  it("finds the label of a host one level under the zone", () => {
    expect(labelUnderZone("bakery.sites.test", "sites.test")).toBe("bakery");
    expect(labelUnderZone("a.b.sites.test", "sites.test")).toBeNull();
    expect(labelUnderZone("sites.test", "sites.test")).toBeNull();
    expect(labelUnderZone("bakery.other.test", "sites.test")).toBeNull();
    expect(labelUnderZone("bakery.sites.test", undefined)).toBeNull();
  });
});

describe("host names", () => {
  it("normalises what people type", () => {
    expect(parseHost("https://WWW.Bakery.com:443/menu?x=1")).toEqual({
      host: "www.bakery.com",
      domain: "bakery.com",
      subdomain: "www",
      publicSuffix: "com",
    });
    expect(parseHost("bakery.com.")).toMatchObject({ host: "bakery.com", subdomain: "" });
    expect(parseHost("  shop.Bakery.com  ")).toMatchObject({ host: "shop.bakery.com" });
  });
  it("understands public suffixes such as co.uk", () => {
    expect(parseHost("bakery.co.uk")).toMatchObject({ domain: "bakery.co.uk", subdomain: "" });
    expect(parseHost("www.bakery.co.uk")).toMatchObject({
      domain: "bakery.co.uk",
      subdomain: "www",
    });
  });
  it("refuses IP addresses, non-English letters and non-domains", () => {
    expect(parseHost("1.2.3.4")).toEqual({ problem: "ip_address" });
    expect(parseHost("[::1]")).toEqual({ problem: "ip_address" });
    expect(parseHost("bäckerei.de")).toEqual({ problem: "not_ascii" });
    expect(parseHost("xn--bckerei-5wa.de")).toEqual({ problem: "idn" });
    expect(parseHost("co.uk")).toEqual({ problem: "no_domain" });
    expect(parseHost("localhost")).toEqual({ problem: "invalid" });
    expect(parseHost("bad_host.com")).toEqual({ problem: "invalid" });
    expect(parseHost("")).toEqual({ problem: "empty" });
  });
  it("turns an entry into hosts: www and the bare domain, or one subdomain", () => {
    const bare = parseHost("bakery.com");
    const www = parseHost("www.bakery.com");
    const shop = parseHost("shop.bakery.com");
    if ("problem" in bare || "problem" in www || "problem" in shop) throw new Error("parse");
    expect(hostsFor(bare)).toEqual({
      domain: "bakery.com",
      hosts: ["www.bakery.com", "bakery.com"],
      primary: "www.bakery.com",
    });
    expect(hostsFor(www)).toEqual(hostsFor(bare));
    expect(hostsFor(shop)).toEqual({
      domain: "shop.bakery.com",
      hosts: ["shop.bakery.com"],
      primary: "shop.bakery.com",
    });
  });
  it("makes a target per domain on the zone", () => {
    expect(domainTarget("Sites.Test", "AbCd1234efgh5678zz")).toBe("d-abcd1234efgh5678.sites.test");
    expect(() => domainTarget("sites.test", "short")).toThrow();
  });
  it("serves a domain's host only with Casama's own proof", () => {
    expect(hostIsLive({ status: "active", kind: "address", verified_at: null })).toBe(true);
    expect(hostIsLive({ status: "active", kind: "custom", verified_at: null })).toBe(false);
    expect(hostIsLive({ status: "active", kind: "custom", verified_at: new Date() })).toBe(true);
    for (const s of [
      "pending_dns",
      "pending_cert",
      "failed",
      "disconnected",
      "paused",
      "suspended",
    ])
      expect(hostIsLive({ status: s, kind: "custom", verified_at: new Date() })).toBe(false);
  });
  it("checks every minute for the first hour, then hourly, then daily once live", () => {
    const created = new Date("2026-11-16T00:00:00Z");
    const at = (m: number) => new Date(created.getTime() + m * 60_000);
    const due = (status: string, last: number | null, now: number) =>
      hostCheckDue({
        status,
        createdAt: created,
        lastCheckedAt: last === null ? null : at(last),
        now: at(now),
      });
    expect(due("pending_dns", null, 0)).toBe(true);
    expect(due("pending_dns", 10, 11)).toBe(true);
    expect(due("pending_dns", 10, 10.5)).toBe(false);
    expect(due("pending_dns", 90, 100)).toBe(false);
    expect(due("pending_dns", 90, 150)).toBe(true);
    expect(due("active", 0, 60 * 23)).toBe(false);
    expect(due("active", 0, 60 * 24)).toBe(true);
    expect(due("failed", null, 0)).toBe(false);
  });
});

describe("renderSite", () => {
  const base = {
    title: "Bakery",
    html: "<html><head><title>Bakery</title></head><body><h1>Hi</h1></body></html>",
    data: { a: 1 },
    index: true,
    indexable: false,
    badge: true,
    collects: false,
  };
  it("has no updated line and no base, and is noindex until search engines are allowed", () => {
    const html = renderSite(base);
    expect(html).not.toContain("casama-updated");
    expect(html).not.toContain("<base");
    expect(html).toContain('<meta name="robots" content="noindex,nofollow">');
    expect(renderSite({ ...base, indexable: true })).not.toContain("noindex");
  });
  it("puts the policy first, and the data and theme on the index only", () => {
    const html = renderSite(base);
    expect(html.indexOf("Content-Security-Policy")).toBeLessThan(html.indexOf("<title>"));
    expect(html).toContain(`content="${PAGE_CSP_ASSETS}"`);
    expect(html).toContain("casama-data");
    const other = renderSite({ ...base, index: false });
    expect(other).not.toContain("casama-data");
    expect(other).not.toContain("casama-theme");
  });
  it("adds the badge only when asked", () => {
    expect(renderSite(base)).toContain('id="casama-badge"');
    expect(renderSite(base)).toContain('href="/_casama/report"');
    expect(renderSite({ ...base, badge: false })).not.toContain("casama-badge");
  });
  it("adds the form script to every HTML file of a site that collects", () => {
    for (const index of [true, false]) {
      const html = renderSite({ ...base, index, collects: true });
      expect(html).toContain('"/_casama/collect"');
      expect(html).toContain("form-action 'self'");
    }
    expect(renderSite(base)).not.toContain("/_casama/collect");
  });
  it("wraps a fragment", () => {
    expect(renderSite({ ...base, html: "<p>x</p>" })).toMatch(/^<!doctype html><html><head>/);
  });
  it("sends caching, HSTS and robots headers that differ from a page's", () => {
    const h = siteHeaders({ indexable: false, collects: false, html: true, etag: '"3:/"' });
    expect(h["cache-control"]).toBe("public, max-age=60");
    expect(h["strict-transport-security"]).toBe("max-age=31536000");
    expect(h["referrer-policy"]).toBe("strict-origin-when-cross-origin");
    expect(h["x-robots-tag"]).toBe("noindex, nofollow");
    expect(h.etag).toBe('"3:/"');
    const f = siteHeaders({ indexable: true, collects: true, html: false });
    expect(f["cache-control"]).toBe("public, max-age=300");
    expect(f["x-robots-tag"]).toBeUndefined();
    expect(f["content-security-policy"]).toBe(siteCsp(true));
    expect(siteCsp(false)).not.toMatch(/https?:/);
  });
});

describe("site paths", () => {
  it("tries the file, then .html, then a folder's index", () => {
    expect(sitePathCandidates("/about")).toEqual(["about", "about.html", "about/index.html"]);
    expect(sitePathCandidates("/img/hero.png")).toEqual(["img/hero.png"]);
    expect(sitePathCandidates("/blog/")).toEqual(["blog/index.html"]);
    expect(sitePathCandidates("/")).toEqual(["index.html"]);
  });
  it("never reaches outside the site or into Casama's paths", () => {
    expect(sitePathCandidates("/../x")).toEqual([]);
    expect(sitePathCandidates("/%2e%2e/x")).toEqual([]);
    expect(sitePathCandidates("/_casama/collect")).toEqual([]);
    expect(sitePathCandidates("/%E0%A4%A")).toEqual([]);
  });
  it("generates robots.txt and a sitemap", () => {
    expect(siteRobots(false, "https://b.sites.test")).toBe("User-agent: *\nDisallow: /\n");
    expect(siteRobots(true, "https://b.sites.test/")).toContain(
      "Sitemap: https://b.sites.test/sitemap.xml",
    );
    const map = siteSitemap("https://b.sites.test", [
      "about.html",
      "img/x.png",
      "404.html",
      "blog/index.html",
    ]);
    expect(map).toContain("<loc>https://b.sites.test/</loc>");
    expect(map).toContain("<loc>https://b.sites.test/about.html</loc>");
    expect(map).toContain("<loc>https://b.sites.test/blog/</loc>");
    expect(map).not.toContain("404");
    expect(map).not.toContain("x.png");
  });
});

describe("domain prices", () => {
  it("is cost × 1.25 + $1.50 rounded up to .99", () => {
    expect(domainPriceUsd(12.03)).toBe(16.99);
    expect(domainPriceUsd(10)).toBe(14.99);
    // Rounded up, never down; an exact .99 stays.
    expect(domainPriceUsd(11.19)).toBe(15.99);
    expect(domainPriceUsd(12.392)).toBe(16.99);
    expect(domainPriceUsd(12.4)).toBe(17.99);
    expect(domainPriceUsd(20, { markup: 1, feeUsd: 0 })).toBe(20.99);
    expect(() => domainPriceUsd(0)).toThrow();
  });
  it("builds search candidates on the endings on sale", () => {
    const tlds = ["com", "net", "org", "io"];
    const names = domainCandidates("Crumb Bakery", tlds);
    expect(names.slice(0, 4)).toEqual([
      "crumbbakery.com",
      "crumbbakery.net",
      "crumbbakery.org",
      "crumbbakery.io",
    ]);
    expect(names).toContain("crumb-bakery.com");
    expect(names).toContain("getcrumbbakery.com");
    expect(domainCandidates("bakery.io", tlds)[0]).toBe("bakery.io");
    expect(domainCandidates("x", tlds)).toEqual([]);
    expect(domainCandidates("a".repeat(200), tlds).length).toBeLessThanOrEqual(50);
  });
  it("knows which endings are on sale", () => {
    expect(saleTld("bakery.com", ["com"])).toBe("com");
    expect(saleTld("bakery.co.uk", ["com"])).toBeNull();
    expect(saleTld("www.bakery.com", ["com"])).toBeNull();
  });
});

describe("renewals", () => {
  it("has the right step for every day from 31 days before expiry to deletion", () => {
    const seen: Array<string> = [];
    for (let d = 31; d >= -85; d--) {
      const p = renewalPlan(d, true);
      seen.push(`${d}:${p.state}:${p.notice ?? "-"}:${p.charge ?? "-"}`);
    }
    const at = (d: number) => seen[31 - d];
    expect(at(31)).toBe("31:active:-:-");
    expect(at(30)).toBe("30:active:notice_30:-");
    expect(at(15)).toBe("15:active:notice_30:-");
    expect(at(14)).toBe("14:active:notice_30:charge_14");
    expect(at(10)).toBe("10:active:notice_30:charge_10");
    expect(at(7)).toBe("7:active:notice_7:charge_7");
    expect(at(3)).toBe("3:active:notice_7:charge_3");
    expect(at(1)).toBe("1:active:notice_1:charge_3");
    expect(at(0)).toBe("0:expired:notice_1:-");
    expect(at(-3)).toBe("-3:expired:expired_3:-");
    expect(at(-20)).toBe("-20:expired:final_20:-");
    expect(at(-25)).toBe("-25:lapsed:-:-");
    expect(at(-80)).toBe("-80:gone:-:-");
    // Every day maps to a state and states only move forward.
    const order = ["active", "expired", "lapsed", "gone"];
    let last = 0;
    for (let d = 31; d >= -85; d--) {
      const i = order.indexOf(renewalPlan(d, true).state);
      expect(i).toBeGreaterThanOrEqual(last);
      last = i;
    }
  });
  it("charges nothing with Renew automatically off but still sends notices", () => {
    for (let d = 31; d >= -30; d--) expect(renewalPlan(d, false).charge).toBeNull();
    expect(renewalPlan(7, false).notice).toBe("notice_7");
  });
});

describe("DNS records", () => {
  const existing: DnsRecord[] = [
    { id: "1", host: "www", type: "CNAME", answer: "d-x.sites.test", ttl: 300 },
    { id: "2", host: "", type: "TXT", answer: "v=spf1 -all", ttl: 300 },
    { id: "3", host: "mail", type: "A", answer: "1.2.3.4", ttl: 300 },
  ];
  const check = (op: "add" | "change" | "delete", record: DnsRecord) =>
    checkDnsChange({ domain: "bakery.com", existing, managed: ["1"], op, record });
  it("accepts ordinary records", () => {
    expect(
      check("add", { host: "@", type: "MX", answer: "mx.mail.test", ttl: 3600, priority: 10 }),
    ).toEqual([]);
    expect(
      check("add", { host: "shop", type: "CNAME", answer: "shops.example.com", ttl: 300 }),
    ).toEqual([]);
    expect(check("add", { host: "v6", type: "AAAA", answer: "2001:db8::1", ttl: 300 })).toEqual([]);
    expect(
      check("add", {
        host: "_sip._tcp",
        type: "SRV",
        answer: "10 5060 sip.example.com",
        ttl: 300,
        priority: 1,
      }),
    ).toEqual([]);
    expect(
      check("change", { id: "3", host: "mail", type: "A", answer: "5.6.7.8", ttl: 300 }),
    ).toEqual([]);
  });
  it("refuses a CNAME beside other records, bad values and short TTLs", () => {
    expect(
      check("add", { host: "mail", type: "CNAME", answer: "x.example.com", ttl: 300 }),
    ).toContain("A CNAME record can't share its name with other records.");
    expect(check("add", { host: "www", type: "TXT", answer: "x", ttl: 300 }).join()).toContain(
      "CNAME",
    );
    expect(
      check("add", { host: "@", type: "CNAME", answer: "x.example.com", ttl: 300 }).join(),
    ).toContain("www");
    expect(check("add", { host: "a", type: "A", answer: "999.1.1.1", ttl: 300 }).length).toBe(1);
    expect(check("add", { host: "a", type: "AAAA", answer: "1.2.3.4", ttl: 300 }).length).toBe(1);
    expect(
      check("add", { host: "a", type: "TXT", answer: "x".repeat(2049), ttl: 300 }).length,
    ).toBe(1);
    expect(check("add", { host: "a", type: "A", answer: "1.1.1.1", ttl: 60 }).length).toBe(1);
    expect(check("add", { host: "a", type: "CAA", answer: "0 issue x", ttl: 300 }).length).toBe(1);
    expect(
      check("add", { host: "@", type: "MX", answer: "mx.test.com", ttl: 300 }).join(),
    ).toContain("priority");
    expect(check("add", { host: "bad name", type: "A", answer: "1.1.1.1", ttl: 300 }).length).toBe(
      1,
    );
  });
  it("protects the records Casama manages", () => {
    expect(check("delete", existing[0]!)[0]).toContain("used by your Casama site");
    expect(check("change", { ...existing[0]!, answer: "elsewhere.com" })[0]).toContain("Casama");
    expect(check("delete", existing[1]!)).toEqual([]);
  });
  it("caps a domain at 100 records", () => {
    const many = Array.from({ length: 100 }, (_, i) => ({
      id: String(i),
      host: `h${i}`,
      type: "A",
      answer: "1.1.1.1",
      ttl: 300,
    }));
    expect(
      checkDnsChange({
        domain: "bakery.com",
        existing: many,
        managed: [],
        op: "add",
        record: { host: "x", type: "A", answer: "1.1.1.1", ttl: 300 },
      }).join(),
    ).toContain("100");
  });
});

describe("registrant contact", () => {
  const ok = {
    first_name: "Ana",
    last_name: "Cruz",
    address1: "1 Main St",
    city: "Austin",
    state: "TX",
    zip: "78701",
    country: "US",
    phone: "+1 415 555 0100",
    email: "ana@example.com",
  };
  it("needs every field in the right form", () => {
    expect(checkDomainContact(ok)).toEqual([]);
    expect(checkDomainContact({ ...ok, country: "USA" }).join()).toContain("two-letter");
    expect(checkDomainContact({ ...ok, phone: "415 555 0100" }).join()).toContain("international");
    expect(checkDomainContact({ ...ok, email: "nope" }).join()).toContain("Email");
    expect(checkDomainContact({ ...ok, city: " " }).join()).toContain("City");
  });
  it("writes the phone the way the registrar wants it", () => {
    expect(registrarPhone("+1 415 555 0100")).toBe("+14155550100");
    expect(registrarPhone("+44.2071234567")).toBe("+442071234567");
    expect(registrarPhone("+63 (917) 123-4567")).toBe("+639171234567");
  });
});
