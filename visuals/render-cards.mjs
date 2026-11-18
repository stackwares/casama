#!/usr/bin/env node
/**
 * Renders a share card for every casama.ai written page into site/assets/cards/<slug>.jpg (D-379).
 * A card is the section's painted background (visuals/cards/*.jpg), the page's title and the real mascot,
 * composed in visuals/compose/card.html and screenshotted with headless Chrome. site/build.mjs uses a
 * page's card as its og:image when the file exists, so a page without one still shares the home card.
 *
 *   node visuals/render-cards.mjs          new pages, and pages whose title changed
 *   node visuals/render-cards.mjs --all    every page again (after a background or template change)
 *
 * site/assets/cards/manifest.json records the title each card was drawn with.
 */
import { execFile } from "node:child_process";
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { createServer } from "node:http";
import { tmpdir } from "node:os";
import { dirname, extname, join, normalize } from "node:path";
import { fileURLToPath } from "node:url";
import { promisify } from "node:util";

const run = promisify(execFile);
const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const OUT = join(ROOT, "site", "assets", "cards");
const MANIFEST = join(OUT, "manifest.json");
const CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
const ALL = process.argv.includes("--all");

/**
 * Background and small label per section; anything else (about, pricing, blog index…) uses "pages".
 * m (left,top,size in px) moves the mascot off the painting's own subject.
 */
const LOOK = {
  learn: { bg: "learn.jpg", label: "Learn", m: "720,120,230" },
  alternatives: { bg: "alternatives.jpg", label: "Alternatives" },
  "use-cases": { bg: "use-cases.jpg", label: "Use cases", m: "730,330,210" },
  compare: { bg: "compare.jpg", label: "Compare", m: "880,370,200" },
  blog: { bg: "pages.jpg", label: "Blog" },
  "": { bg: "pages.jpg", label: "" },
};

const { stdout } = await run(process.execPath, [join(ROOT, "site", "build.mjs"), "--card-list"], {
  maxBuffer: 1 << 24,
});
// Blog posts share their own header picture (site/assets/blog/), so only the blog's index gets a card.
const pages = JSON.parse(stdout).filter((p) => p.section !== "blog" || p.slug === "blog/index");
const manifest = existsSync(MANIFEST) ? JSON.parse(readFileSync(MANIFEST, "utf8")) : {};
const todo = pages.filter(
  (p) => ALL || manifest[p.slug] !== p.title || !existsSync(join(OUT, `${p.slug}.jpg`)),
);

const TYPES = {
  ".html": "text/html",
  ".svg": "image/svg+xml",
  ".woff2": "font/woff2",
  ".jpg": "image/jpeg",
  ".png": "image/png",
};
const server = createServer((req, res) => {
  const path = normalize(decodeURIComponent(new URL(req.url, "http://x").pathname)).replace(
    /^(\.\.[/\\])+/,
    "",
  );
  const file = join(ROOT, path);
  if (!file.startsWith(ROOT) || !existsSync(file)) return res.writeHead(404).end();
  res
    .writeHead(200, { "content-type": TYPES[extname(file)] ?? "application/octet-stream" })
    .end(readFileSync(file));
});
await new Promise((ok) => server.listen(0, "127.0.0.1", ok));
const base = `http://127.0.0.1:${server.address().port}`;
const tmp = mkdtempSync(join(tmpdir(), "cards-"));

async function render(page) {
  const look = LOOK[page.section] ?? LOOK[""];
  const q = new URLSearchParams({
    bg: look.bg,
    title: page.title,
    label: look.label,
    ...(look.m ? { m: look.m } : {}),
  });
  const png = join(tmp, `${page.slug.replace(/\//g, "--")}.png`);
  await run(CHROME, [
    "--headless=new",
    "--disable-gpu",
    "--hide-scrollbars",
    "--force-device-scale-factor=1",
    "--virtual-time-budget=4000",
    "--window-size=1200,630",
    `--screenshot=${png}`,
    `${base}/visuals/compose/card.html?${q}`,
  ]);
  const jpg = join(OUT, `${page.slug}.jpg`);
  mkdirSync(dirname(jpg), { recursive: true });
  await run("sips", ["-s", "format", "jpeg", "-s", "formatOptions", "80", png, "--out", jpg]);
  manifest[page.slug] = page.title;
  console.log(`  ${page.slug}.jpg`);
}

for (let i = 0; i < todo.length; i += 6) await Promise.all(todo.slice(i, i + 6).map(render));
server.close();
rmSync(tmp, { recursive: true, force: true });
const sorted = Object.fromEntries(
  Object.entries(manifest)
    .filter(([slug]) => pages.some((p) => p.slug === slug))
    .sort(),
);
writeFileSync(MANIFEST, `${JSON.stringify(sorted, null, 2)}\n`);
console.log(`Cards: ${todo.length} drawn, ${pages.length} pages`);
