/**
 * Writes what the phone app's browser needs from the shared site rules, so the Dart copy can't
 * drift: the lists as an app asset, and the decisions for a set of addresses as a test fixture.
 * Run with `pnpm --filter @casama/domain gen:app-browser`; `--check` fails when either is stale.
 */
import { readFileSync, writeFileSync } from "node:fs";
import {
  type AppSitePolicy,
  appSiteDecision,
  CASAMA_DOMAINS,
  SENSITIVE_SITE_HOSTS,
  SENSITIVE_SITE_KINDS,
  SENSITIVE_SITE_WORDS,
} from "../src/index.ts";

const root = new URL("../../../", import.meta.url).pathname;
const ASSET = `${root}client/assets/app_browser/guard.json`;
const CASES = `${root}client/test/fixtures/app_browser_sites.json`;

const guard = {
  casama: CASAMA_DOMAINS,
  kinds: SENSITIVE_SITE_KINDS,
  hosts: SENSITIVE_SITE_HOSTS,
  // Regular expressions on the host, case-insensitive (the same source works in Dart).
  words: Object.fromEntries(
    Object.entries(SENSITIVE_SITE_WORDS).map(([k, re]) => [k, (re as RegExp).source]),
  ),
};

const policies: Record<string, AppSitePolicy> = {
  empty: { blocked_sites: [], allowed_sites: [], allowed_kinds: [], own_urls: [] },
  shop: {
    blocked_sites: ["ads.example", "*.tracker.example"],
    allowed_sites: ["shop.example", "*.docs.example"],
    allowed_kinds: [],
    own_urls: ["https://api.myserver.example:8443", "http://localhost:54321"],
  },
  banking_on: {
    blocked_sites: [],
    allowed_sites: ["paypal.com"],
    allowed_kinds: ["banking"],
    own_urls: [],
  },
};
const urls = [
  "about:blank",
  "file:///etc/passwd",
  "javascript:alert(1)",
  "ftp://shop.example/",
  "not a url",
  "https://chromewebstore.google.com/detail/x",
  "https://casama.ai/",
  "https://app.casama.ai/c/1",
  "https://x.casama.link/",
  "https://kasama.ai",
  "https://notcasama.ai/",
  "https://api.myserver.example:8443/v1",
  "https://api.myserver.example/other-port",
  "http://localhost:54321/auth",
  "https://shop.example/basket",
  "https://www.shop.example/",
  "https://WWW.Shop.Example./orders",
  "https://pay.shop.example/",
  "https://notshop.example/",
  "https://docs.example/",
  "https://a.docs.example/",
  "https://ads.example/x",
  "https://cdn.ads.example/x",
  "https://tracker.example/",
  "https://a.tracker.example/",
  "https://news.example/story",
  "https://www.paypal.com/signin",
  "https://chase.com/",
  "https://secure.bankofexample.com/",
  "https://1password.com/",
  "https://my.healthportal.example/",
  "https://www.irs.gov/",
  "https://accounts.google.com/",
];
const onces: string[][] = [[], ["news.example", "paypal.com"]];

const cases = [];
for (const [name, policy] of Object.entries(policies))
  for (const once of onces)
    for (const url of urls)
      cases.push({ policy: name, once, url, expect: appSiteDecision(url, policy, once) });

const out = (o: unknown) => `${JSON.stringify(o, null, 1)}\n`;
const files: Array<[string, string]> = [
  [ASSET, out(guard)],
  [CASES, out({ policies, cases })],
];
if (process.argv.includes("--check")) {
  for (const [path, want] of files) {
    let have = "";
    try {
      have = readFileSync(path, "utf8");
    } catch {}
    if (have !== want) {
      console.error(`${path} is stale: run pnpm --filter @casama/domain gen:app-browser`);
      process.exit(1);
    }
  }
} else for (const [path, want] of files) writeFileSync(path, want);
