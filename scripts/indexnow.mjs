#!/usr/bin/env node
/**
 * Tells IndexNow (Bing, Yandex, Naver, Seznam, Yep and others; not Google) which pages changed in a
 * deploy, so they're crawled in minutes instead of days (docs/SEO-PLAN.md §10.4).
 *
 *   node scripts/indexnow.mjs snapshot <file>   save the live sitemaps before deploying
 *   node scripts/indexnow.mjs submit <file>     after deploying: send addresses that are new or
 *                                               whose lastmod changed since the snapshot
 *   node scripts/indexnow.mjs submit --all      send every address (first run)
 *
 * The key is public by design: each site serves it at /<key>.txt, which is how IndexNow checks the
 * sender owns the site.
 */
import { readFileSync, writeFileSync } from "node:fs";

const KEY = "50eae7b4e1579e7edc13bdca460cb2b1";
const HOSTS = ["casama.ai", "docs.casama.ai", "gallery.casama.ai", "casama.link"];

async function sitemap(host) {
  try {
    const res = await fetch(`https://${host}/sitemap.xml`, {
      headers: { "cache-control": "no-cache" },
    });
    if (!res.ok) return {};
    const xml = await res.text();
    const out = {};
    for (const m of xml.matchAll(/<url>\s*<loc>([^<]+)<\/loc>(?:\s*<lastmod>([^<]+)<\/lastmod>)?/g))
      out[m[1]] = m[2] ?? "";
    return out;
  } catch {
    return {};
  }
}

const [mode, arg] = process.argv.slice(2);
const live = Object.fromEntries(await Promise.all(HOSTS.map(async (h) => [h, await sitemap(h)])));
if (mode === "snapshot") {
  writeFileSync(arg, JSON.stringify(live));
  console.log(
    `IndexNow: saved ${Object.values(live).reduce((n, s) => n + Object.keys(s).length, 0)} live addresses`,
  );
} else if (mode === "submit") {
  const before = arg === "--all" ? {} : JSON.parse(readFileSync(arg, "utf8"));
  for (const host of HOSTS) {
    const old = before[host] ?? {};
    const urlList = Object.entries(live[host])
      .filter(([url, lastmod]) => !(url in old) || old[url] !== lastmod)
      .map(([url]) => url);
    if (!urlList.length) {
      console.log(`IndexNow: ${host}: nothing changed`);
      continue;
    }
    const res = await fetch("https://api.indexnow.org/indexnow", {
      method: "POST",
      headers: { "content-type": "application/json; charset=utf-8" },
      body: JSON.stringify({
        host,
        key: KEY,
        keyLocation: `https://${host}/${KEY}.txt`,
        urlList: urlList.slice(0, 10000),
      }),
    });
    console.log(`IndexNow: ${host}: sent ${urlList.length} addresses (HTTP ${res.status})`);
  }
} else {
  console.error("usage: indexnow.mjs snapshot <file> | submit <file> | submit --all");
  process.exit(1);
}
