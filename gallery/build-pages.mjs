#!/usr/bin/env node
/**
 * Builds the gallery's static pages (D-315): one page per item at /i/<type>/<id>/ with its share
 * image (og.png, 1200 × 630), author pages at /by/<handle>/, the home page's share image and
 * sitemap.xml. Everything it writes is gitignored (gallery/.gitignore) and deployed with the site
 * by scripts/deploy-web.sh. The catalog files are only read.
 *
 *   node gallery/build-pages.mjs              # pages and images
 *   node gallery/build-pages.mjs --no-og      # pages only (fast; for local preview)
 *   node gallery/build-pages.mjs --dir <path> # another catalog folder laid out the same way
 *
 * Share images are SVG drawn here from the same colors, meshes and doodles as gallery.js, rendered
 * to PNG with resvg (@resvg/resvg-js, MPL-2.0, a root devDependency).
 */
import { createRequire } from "node:module";
import { existsSync, mkdirSync, readFileSync, rmSync, statSync, writeFileSync, readdirSync } from "node:fs";
import { dirname, join, relative } from "node:path";
import { fileURLToPath } from "node:url";
import vm from "node:vm";
import zlib from "node:zlib";

const here = dirname(fileURLToPath(import.meta.url));
const args = process.argv.slice(2);
const flag = (name) => args.includes(name);
const opt = (name) => { const i = args.indexOf(name); return i !== -1 ? args[i + 1] : null; };
const DIR = opt("--dir") ?? here;
const WITH_OG = !flag("--no-og");
const require = createRequire(import.meta.url);
const C = require(join(here, "catalog.js"));
const SITE = C.SITE;

// ---------------------------------------------------------------- gallery.js in Node
// The preview library runs in a small sandbox; only its pure parts are used (colors, meshes,
// patterns, icons). Its mesh canvas writes into a stand-in that keeps the pixels.
const G = (() => {
  const src = readFileSync(join(here, "gallery.js"), "utf8").replace("window.CasamaGallery = {", "window.CasamaGallery = { meshCanvas: meshCanvas,");
  const fakeCanvas = () => {
    const canvas = { pixels: null };
    canvas.getContext = () => ({
      createImageData: (w, h) => ({ width: w, height: h, data: new Uint8ClampedArray(w * h * 4) }),
      putImageData: (d) => { canvas.pixels = d; },
    });
    return canvas;
  };
  const ctx = { window: {}, document: { currentScript: null, createElement: fakeCanvas }, location: { href: `${SITE}/` }, URL };
  vm.createContext(ctx);
  vm.runInContext(src, ctx);
  return ctx.window.CasamaGallery;
})();
const lucide = JSON.parse(readFileSync(join(here, "assets/lucide/icon-nodes.json"), "utf8"));
const iconNodes = (name) => G.iconNodes(name) ?? lucide[name] ?? G.iconNodes("book-open");

// ---------------------------------------------------------------- catalog
function readJson(file, fallback) {
  const path = join(DIR, file);
  if (!existsSync(path)) return fallback;
  try { return JSON.parse(readFileSync(path, "utf8")); } catch (e) { console.warn(`Skipping ${file}: ${e.message}`); return fallback; }
}
const lists = ["index.json", "apps.json", "bots.json", "routines.json", "plugins.json"].map((f) => readJson(f, { items: [] }));
const items = lists.flatMap((l) => l.items ?? []).filter((i) => !i.retired && C.TYPES.includes(i.type));
const setsFile = readJson("sets.json", { items: [] });
const sets = (setsFile.items ?? setsFile.sets ?? []).filter((s) => !s.retired).map((s) => ({ ...s, type: "set" }));
const all = [...items, ...sets];
const byKey = new Map(all.map((i) => [`${i.type}/${i.id}`, i]));
const find = (type, id) => byKey.get(`${type}/${id}`);

// Authors: authors.json when the checker wrote it, else grouped from the items.
const authorsFile = readJson("authors.json", null);
const authors = new Map();
for (const item of all) {
  const key = C.authorKey(item);
  if (!authors.has(key)) authors.set(key, { handle: key, name: item.author?.name ?? key, url: item.author?.url, items: [] });
  authors.get(key).items.push(item);
}
for (const a of authorsFile?.authors ?? []) {
  const found = authors.get(a.handle);
  if (found) { found.name = a.name || found.name; found.url = a.url || found.url; }
}

// ---------------------------------------------------------------- html helpers
const esc = (v) => String(v ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);
const json = (v) => JSON.stringify(v).replace(/</g, "\\u003c");
function svgIcon(name, size = 20, extra = "") {
  return `<svg viewBox="0 0 24 24" width="${size}" height="${size}" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"${extra}>${G.nodesMarkup(iconNodes(name))}</svg>`;
}
function hint(type) {
  return {
    app: "Connect it in Casama from Settings → Connections, or open it from here.",
    bot: "Pick it in Casama when you make a new bot, or open it from here.",
    routine: "Find it under Ideas when you add a routine to a bot, or open it from here.",
    plugin: "Add it in Casama from a bot's Plugins page, at the reviewed version.",
    set: "Adds everything in the set at once; apps still ask you to sign in.",
  }[type] ?? "";
}
function appLogoHtml(item, size) {
  const doc = C.doc(item);
  const hex = /^[0-9A-Fa-f]{6}$/.test(doc.color || "") ? doc.color : "6B7280";
  const ink = inkOn(hex);
  const logo = `apps/${item.id}/logo.svg`;
  const inner = (item.files || []).includes(logo)
    ? `<i style="background:${ink};-webkit-mask:url(/${logo}) center/contain no-repeat;mask:url(/${logo}) center/contain no-repeat"></i>`
    : `<b style="color:${ink};font-size:${Math.round(size * 0.44)}px">${esc((item.name || "?").charAt(0).toUpperCase())}</b>`;
  return `<span class="app-logo" aria-hidden="true" style="width:${size}px;height:${size}px;border-radius:${Math.round(size * 0.28)}px;background:#${hex}">${inner}</span>`;
}
function inkOn(hex) {
  const n = parseInt(hex, 16);
  return (0.299 * (n >> 16) + 0.587 * ((n >> 8) & 255) + 0.114 * (n & 255)) / 255 > 0.6 ? "#1B1B1F" : "#FFFFFF";
}
function markHtml(item, size = 22) {
  if (item.type === "app") return appLogoHtml(item, size + 10);
  if (C.isLook(item)) return svgIcon(item.type === "wallpaper" ? "image" : "palette", size);
  const doc = C.doc(item);
  const icon = doc.icon || item.icon || { work: "briefcase", writing: "pen-line", research: "telescope", data: "table-2", money: "coins", build: "code", life: "compass" }[C.category(item)] || { skill: "book-open", bot: "bot", routine: "repeat", plugin: "puzzle", set: "package" }[item.type] || "book-open";
  return svgIcon(icon, size);
}
/** A short list row linking to an item's page; looks get a small preview drawn by page.js. */
function rowHtml(item) {
  const pic = C.isLook(item) ? `<span class="mini-pic" data-key="${esc(`${item.type}/${item.id}`)}"></span>` : `<span class="row-mark">${markHtml(item)}</span>`;
  return `<li><a class="skill row-link" href="${C.pagePath(item)}">${pic}<span><span class="skill-name">${esc(item.name)}</span><span class="skill-desc">${esc(C.SINGULAR[item.type])}${item.description ? ` · ${esc(item.description)}` : ""}</span></span><span class="skill-go">${svgIcon("chevron-right", 18)}</span></a></li>`;
}

function shell({ title, description, path, image, imageAlt, body, data, noindex, ld, type = "website" }) {
  const url = SITE + path;
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${esc(title)}</title>
<meta name="description" content="${esc(description)}">
<link rel="canonical" href="${url}">
${noindex ? '<meta name="robots" content="noindex">\n' : ""}<meta property="og:type" content="${type}">
<meta property="og:site_name" content="Casama Gallery">
<meta property="og:url" content="${url}">
<meta property="og:title" content="${esc(title)}">
<meta property="og:description" content="${esc(description)}">
<meta property="og:image" content="${image}">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
<meta property="og:image:alt" content="${esc(imageAlt || title)}">
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="${esc(title)}">
<meta name="twitter:description" content="${esc(description)}">
<meta name="twitter:image" content="${image}">
<meta name="theme-color" content="#ffffff" media="(prefers-color-scheme: light)">
<meta name="theme-color" content="#1c1c1e" media="(prefers-color-scheme: dark)">
<meta name="casama-stats" content="https://api.casama.ai/v1/gallery/stats">
<link rel="icon" type="image/svg+xml" href="/assets/casama-winky-animated.svg">
<link rel="stylesheet" href="/gallery.css">
<link rel="stylesheet" href="/app.css">
<link rel="stylesheet" href="/page.css">
${ld ? `<script type="application/ld+json">${JSON.stringify(ld).replace(/</g, "\\u003c")}</script>\n` : ""}<script>document.documentElement.setAttribute("data-theme", matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light");</script>
</head>
<body>
<a class="skip" href="#main">Skip to the content</a>
<header class="bar">
  <div class="wrap bar-inner">
    <a class="logo" href="https://casama.ai" aria-label="Casama home"><span data-casama-mark></span><span>Casama</span></a>
    <a class="brand-tag" href="/">Gallery</a>
    <nav class="bar-nav" aria-label="Gallery">
      <a href="/make.html">Make a look</a>
      <a href="/#contribute">Contribute</a>
      <a class="btn primary" href="https://casama.ai/download">Get Casama</a>
    </nav>
  </div>
</header>
<main class="wrap page" id="main">
${body}
</main>
<footer class="foot">
  <div class="wrap foot-inner">
    <p class="foot-name"><span data-casama-mark></span>Casama</p>
    <p class="small">Made in the open by Casama and its contributors. Every item lists its author and license. Developers: the whole catalog is open JSON, see <a href="/add/#data">Public data</a>.</p>
    <form class="foot-news" action="https://casama.ai/newsletter/subscribe" method="post">
      <label for="foot-news-email">Casama's monthly email: what's new, once a month at most.</label>
      <span class="foot-news-row"><input id="foot-news-email" type="email" name="email" required autocomplete="email" placeholder="you@example.com"><button type="submit">Subscribe</button></span>
      <input class="foot-news-hp" type="text" name="website" tabindex="-1" autocomplete="off" aria-hidden="true">
    </form>
    <p class="small">Community: <a href="https://discord.gg/e86XbXFHwz">Discord</a> · <a href="https://x.com/CasamaAI">X</a> · <a href="https://bsky.app/profile/casama.ai">Bluesky</a> · <a href="https://www.youtube.com/@casamaai">YouTube</a></p>
    <p class="small"><a href="/add/">Add to Casama badge</a> · <a href="https://casama.ai/privacy">Privacy</a> · <a href="https://casama.ai/terms">Terms</a> · <a href="https://github.com/${C.REPO}/issues/new">Report an item</a></p>
  </div>
</footer>
${data ? `<script type="application/json" id="page-data">${json(data)}</script>\n` : ""}<script src="/gallery.js"></script>
<script src="/page.js"></script>
<script src="/count.js" defer></script>
<script src="/assets/brand/casama-mark.js"></script>
</body>
</html>
`;
}

// ---------------------------------------------------------------- item pages
const AUTH = { oauth: "Sign in with the vendor", api_key: "An API key", none: "Nothing, it's public" };

function heroHtml(item) {
  const doc = C.doc(item);
  if (C.isLook(item)) return `<div class="item-pic look" id="pic" data-key="${esc(`${item.type}/${item.id}`)}"><div class="cg-frame" style="--ar:16 / 10"></div></div>`;
  if (item.type === "app")
    return `<div class="item-pic"><div class="app-hero">${appLogoHtml(item, 88)}<ul class="app-can">${(doc.capabilities || []).map((c) => `<li>${svgIcon("check", 16)}${esc(c)}</li>`).join("")}</ul>${doc.note ? `<p class="small">${esc(doc.note)}</p>` : ""}</div></div>`;
  if (item.type === "plugin")
    return `<div class="item-pic"><div class="app-hero">${svgIcon(doc.icon || "puzzle", 72)}<ul class="app-can">${(doc.adds || []).map((c) => `<li>${svgIcon("check", 16)}${esc(c)}</li>`).join("")}</ul></div></div>`;
  if (item.type === "set")
    return `<div class="item-pic"><ul class="skills set-list">${C.setItems(item).map((m) => find(m.type, m.id) || { ...m, name: m.id }).map(rowHtml).join("")}</ul></div>`;
  let text = "";
  if (item.type === "skill") {
    const path = (item.files || []).find((f) => /\/SKILL\.md$/.test(f));
    try { text = path ? readFileSync(join(DIR, path), "utf8").replace(/^---\n[\s\S]*?\n---\n?/, "").trim() : ""; } catch { text = ""; }
    text ||= item.description || "";
  } else if (item.type === "bot") text = doc.persona || "";
  else if (item.type === "routine") text = doc.instructions_md || "";
  const starters = item.type === "bot" && (doc.starters || []).length
    ? `<ul class="app-can">${doc.starters.map((s) => `<li>${svgIcon("message-circle", 16)}${esc(s)}</li>`).join("")}</ul>` : "";
  return `<div class="item-pic"><pre class="instructions full" aria-label="Instructions">${esc(text)}</pre>${starters}</div>`;
}

function factsHtml(item) {
  const doc = C.doc(item);
  const rows = [];
  const row = (label, html) => rows.push(`<tr><th scope="row">${esc(label)}</th><td>${html}</td></tr>`);
  if (item.type === "theme") {
    row("Fonts", esc([doc.headingFont, doc.bodyFont].filter((f, i, a) => f && a.indexOf(f) === i).join(" · ")));
    row("Background", esc(G.describeWallpaper(doc.wallpaper)));
  } else if (item.type === "scheme") row("Modes", "Light and dark");
  else if (item.type === "wallpaper") row("Kind", esc(G.describeWallpaper(doc)));
  else if (item.type === "bot") {
    row("Asks first", doc.autonomy === "ask_always" ? "Before every action" : "Before risky actions");
    const comes = (doc.skills || []).map((k) => `Skill: ${k.name}`).concat((doc.routines || []).map((r) => `Routine: ${r.name} (${C.schedule(r.schedule_cron)})`));
    if (comes.length) row("Comes with", esc(comes.join(" · ")));
  } else if (item.type === "routine") row("When", esc(C.schedule(doc.schedule_cron)));
  else if (item.type === "plugin") {
    const at = String(doc.url || "").replace(/\/tree\/[^/]+/, `/tree/${doc.commit}`);
    row("Reviewed code", `<a href="${esc(at)}" rel="noopener">${esc(String(doc.commit || "").slice(0, 7))} on GitHub</a>`);
  } else if (item.type === "app") {
    row("Connects to", `<code>${esc(doc.url || "-")}</code>`);
    row("Needs", esc((doc.auth || []).map((a) => AUTH[a] || a).join(" or ")));
    if (doc.homepage) row("Website", `<a href="${esc(doc.homepage)}" rel="noopener">${esc(doc.homepage.replace(/^https:\/\//, ""))}</a>`);
  }
  if (C.categoryLabel(item)) row("Category", esc(C.categoryLabel(item)));
  row("Made by", `<a href="${C.authorPath(C.authorKey(item))}">${esc(item.author?.name || "-")}</a>${esc(C.madeBy(item).filter((m) => m !== item.author?.name).map((m) => ` · ${m}`).join(""))}`);
  if (item.remix_of?.type && item.remix_of?.id) {
    const orig = find(item.remix_of.type, item.remix_of.id);
    row("Remix of", `<a href="${C.pagePath(item.remix_of)}">${esc(orig?.name ?? item.remix_of.id)}</a>`);
  }
  row("Version", esc(`Version ${item.version || 1}${item.updated ? ` · updated ${C.longDate(item.updated)}` : ""}`));
  if (item.added) row("Added", esc(C.longDate(item.added)));
  if (item.license) row("License", esc(item.license));
  if (item.type !== "set") row("Source", `<a href="${C.sourceLink(item)}" rel="noopener">On GitHub</a>`);
  return `<table class="facts"><tbody>${rows.join("")}</tbody></table>`;
}

function extrasHtml(item) {
  const out = [];
  const acc = C.access(item);
  if (acc.length) out.push(`<section class="block"><h2 class="h3">What it can access</h2><ul class="access">${acc.map((a) => `<li>${svgIcon(a.icon, 16)}<span><b>${esc(a.label)}</b> ${esc(a.text)}</span></li>`).join("")}</ul></section>`);
  const ex = C.examples(item);
  if (ex.length) out.push(`<section class="block"><h2 class="h3">Try it</h2><ul class="examples">${ex.map((p) => `<li><a href="${esc(C.askLink(p))}" title="Ask Casama">${svgIcon("message-circle", 16)}<span>${esc(p)}</span></a></li>`).join("")}</ul></section>`);
  const needs = C.needs(item);
  const need = needs.apps.map((id) => ({ type: "app", id })).concat(needs.skills.map((id) => ({ type: "skill", id })));
  if (need.length) out.push(`<section class="block"><h2 class="h3">Works with</h2><p class="inline-list">${need.map((n) => { const k = find(n.type, n.id); return k ? `<a href="${C.pagePath(n)}">${esc(k.name)}</a>` : esc(n.id); }).join(", ")}</p></section>`);
  const inp = C.inputs(item);
  if (inp.length) out.push(`<section class="block"><h2 class="h3">Asks you when you add it</h2><p class="small">${esc(inp.map((x) => x.label).join(" · "))}</p></section>`);
  return out.join("\n");
}

function changelogHtml(item) {
  const log = C.changelog(item);
  if (!log.length) return "";
  return `<details class="block changelog"><summary>What's new</summary><ul>${log.map((c) => `<li><b>Version ${esc(c.version)}</b> · ${esc(C.longDate(c.date))}${c.breaking ? " · changes how it works" : ""}<br>${esc(c.note)}</li>`).join("")}</ul></details>`;
}

function badgeHtml(item) {
  const url = C.pageUrl(item);
  const md = `[![Add to Casama](${SITE}/badge.svg)](${url})`;
  const html = `<a href="${url}"><img src="${SITE}/badge.svg" alt="Add to Casama" height="40"></a>`;
  return `<details class="block badge-snippet"><summary>Add a badge to your README</summary>
<p><a href="${C.pagePath(item)}"><img src="/badge.svg" alt="Add to Casama" height="40"></a></p>
<p class="small">Markdown</p><pre class="sample"><code>${esc(md)}</code></pre>
<p class="small">HTML</p><pre class="sample"><code>${esc(html)}</code></pre>
<button class="btn" type="button" data-copy="${esc(md)}">${svgIcon("copy", 17)}<span>Copy Markdown</span></button></details>`;
}

function related(item) {
  const same = all.filter((i) => i !== item && i.type === item.type);
  const cat = C.category(item);
  const tags = new Set(item.tags || []);
  return same.map((i) => ({ i, s: (cat && C.category(i) === cat ? 2 : 0) + (i.tags || []).filter((t) => tags.has(t)).length + (i.featured ? 0.5 : 0) }))
    .sort((a, b) => b.s - a.s || a.i.name.localeCompare(b.i.name)).slice(0, 6).map((x) => x.i);
}

function describe(item) {
  if (item.description) return item.description;
  const by = C.community(item) ? ` by ${item.author.name}` : "";
  return `${C.SINGULAR[item.type]} for Casama${by}. Free and open source${item.license ? ` (${item.license})` : ""}.`;
}

function itemPage(item) {
  const kind = C.SINGULAR[item.type];
  const about = describe(item);
  const open = C.openLink(item);
  const more = related(item);
  const looks = [item, ...more].filter(C.isLook);
  const tags = (item.tags || []).length ? `<div class="tags">${item.tags.map((t) => `<a class="tag" href="/?q=${encodeURIComponent(t)}">${esc(t)}</a>`).join("")}</div>` : "";
  const body = `<nav class="crumbs" aria-label="Breadcrumb"><a href="/">Gallery</a><span aria-hidden="true">/</span><a href="/c/${item.type}/">${esc(C.PLURAL[item.type])}</a></nav>
<article class="item">
${heroHtml(item)}
<div class="item-info">
  <p class="kind">${esc(kind)} · By <a href="${C.authorPath(C.authorKey(item))}">${esc(item.author?.name ?? "")}</a>${item.license ? ` · ${esc(item.license)}` : ""}</p>
  <h1 id="name">${esc(item.name)}</h1>
  <p class="stats-line" id="stats" hidden></p>
  ${item.pick ? `<p class="pick-note">${svgIcon("sparkles", 16)}<span>${esc(item.pick)}</span></p>` : ""}
  <p class="about">${esc(about)}</p>
  ${item.type === "app" ? `<p class="small">Connect ${esc(item.name)} once, choose which bots may use it, and ask in plain words. For each thing a bot can do in ${esc(item.name)}, you decide whether it may act alone or must ask you first.</p>` : ""}
  <div class="actions">
    <a class="btn primary" href="${esc(open)}">${svgIcon("external-link", 17)}${item.type === "skill" ? "Install in Casama" : item.type === "set" ? "Add all in Casama" : "Open in Casama"}</a>
    <a class="btn" href="https://casama.ai/download">Get Casama</a>
    <button class="btn quiet" type="button" data-copy="${esc(item.type === "set" ? C.pageUrl(item) : C.shareLink(item))}">${svgIcon("link", 17)}<span>Copy link</span></button>
  </div>
  <!-- waitlist copy: docs/WAITLIST-PLAN.md §12 -->
  <p class="small">Casama Cloud is invite-only for now. <a href="https://casama.ai/waitlist">Join the waitlist</a></p>
  ${hint(item.type) ? `<p class="small">${esc(hint(item.type))}</p>` : ""}
  ${extrasHtml(item)}
  ${factsHtml(item)}
  ${changelogHtml(item)}
  ${tags}
  ${badgeHtml(item)}
</div>
</article>
${more.length ? `<section class="section"><div class="section-head"><h2>More ${esc(C.PLURAL[item.type].toLowerCase())}</h2></div><ul class="skills">${more.map(rowHtml).join("")}</ul></section>` : ""}`;
  // Structured data: where the page sits, and what the item is (docs/SEO-PLAN.md part D).
  const ld = [
    { "@context": "https://schema.org", "@type": "BreadcrumbList", itemListElement: [
      { "@type": "ListItem", position: 1, name: "Casama Gallery", item: `${SITE}/` },
      { "@type": "ListItem", position: 2, name: C.PLURAL[item.type], item: `${SITE}/c/${item.type}/` },
      { "@type": "ListItem", position: 3, name: item.name, item: C.pageUrl(item) },
    ] },
    { "@context": "https://schema.org", "@type": "CreativeWork", name: item.name, description: about, url: C.pageUrl(item),
      genre: `${kind} for Casama`, isAccessibleForFree: true, inLanguage: "en",
      ...(item.author?.name ? { author: { "@type": item.author.name === "Casama" ? "Organization" : "Person", name: item.author.name, ...(item.author.url ? { url: item.author.url } : {}) } } : {}),
      ...(item.license ? { license: `https://spdx.org/licenses/${item.license}.html` } : {}),
      ...(item.added ? { datePublished: item.added } : {}), ...(item.updated ? { dateModified: item.updated } : {}),
      ...((item.tags || []).length ? { keywords: item.tags.join(", ") } : {}),
      isPartOf: { "@type": "WebSite", name: "Casama Gallery", url: `${SITE}/` } },
  ];
  // People search for an app by name plus "AI agent", so an app's page says so in its title.
  const isApp = item.type === "app";
  const can = isApp ? (C.doc(item).capabilities || []).slice(0, 3).map((c) => c[0].toLowerCase() + c.slice(1)).join(", ") : "";
  return shell({
    ld,
    title: isApp ? `${item.name} AI agent: use ${item.name} with a Casama bot` : `${item.name} · ${kind} for Casama`,
    description: isApp && can ? `${about} Connect ${item.name} to a Casama bot: ${can}. You choose what it must ask first.`.slice(0, 200) : about,
    path: C.pagePath(item),
    image: `${SITE}${C.pagePath(item)}og.png`,
    imageAlt: `${item.name}, a ${kind.toLowerCase()} for Casama`,
    body,
    data: { item: C.isLook(item) ? item : { type: item.type, id: item.id, name: item.name }, looks: looks.map(slim), stats: `${item.type}/${item.id}` },
  });
}
/** What page.js needs to draw a look's preview. */
function slim(i) { return { type: i.type, id: i.id, name: i.name, document: i.document, files: i.files }; }

function authorPage(a) {
  const list = [...a.items].sort((x, y) => C.TYPES.indexOf(x.type) - C.TYPES.indexOf(y.type) || x.name.localeCompare(y.name));
  const groups = [...new Set(list.map((i) => i.type))].map((t) => {
    const of = list.filter((i) => i.type === t);
    return `<section class="section"><div class="section-head"><h2>${esc(C.PLURAL[t])}<span class="n">${of.length}</span></h2></div><ul class="skills">${of.map(rowHtml).join("")}</ul></section>`;
  }).join("\n");
  const kinds = [...new Set(list.map((i) => i.type))].map((t) => C.count(list.filter((i) => i.type === t).length, t));
  const desc = `${a.name} made ${kinds.join(", ")} for Casama, free and open source.`;
  const body = `<nav class="crumbs" aria-label="Breadcrumb"><a href="/">Gallery</a><span aria-hidden="true">/</span><span>Authors</span></nav>
<div class="title-row"><h1>${esc(a.name)}</h1><p class="sub">${esc(desc)}${a.url ? ` <a href="${esc(a.url)}" rel="noopener">${esc(a.url.replace(/^https?:\/\//, "").replace(/\/$/, ""))}</a>` : ""}</p></div>
${groups}`;
  return shell({ title: `${a.name} · Casama Gallery`, description: desc, path: C.authorPath(a.handle), image: `${SITE}/og.png`, body, data: { looks: list.filter(C.isLook).map(slim) } });
}

// ---------------------------------------------------------------- share images (SVG → PNG)
const W = 1200, H = 630;
const INK = "#1b1b1f", MUTED = "#5b5b63", ACCENT = "#7a3fa8";
const SERIF = "Libre Baskerville", SANS = "Google Sans";

/** Rough text width for wrapping (no font metrics here). */
function textWidth(s, size, serif) {
  let w = 0;
  for (const ch of s) {
    if (/[il.,:;'!|]/.test(ch)) w += 0.28;
    else if (/[fjrt() ]/.test(ch)) w += 0.36;
    else if (/[mwMW@]/.test(ch)) w += 0.86;
    else if (/[A-Z]/.test(ch)) w += 0.68;
    else if (/[0-9]/.test(ch)) w += 0.56;
    else w += 0.53;
  }
  return w * size * (serif ? 1.1 : 1);
}
function wrap(text, size, max, lines, serif) {
  const words = String(text || "").split(/\s+/).filter(Boolean);
  const out = [];
  let cur = "";
  for (const word of words) {
    const next = cur ? `${cur} ${word}` : word;
    if (textWidth(next, size, serif) <= max || !cur) cur = next;
    else { out.push(cur); cur = word; }
  }
  if (cur) out.push(cur);
  if (out.length > lines) {
    const kept = out.slice(0, lines);
    let last = kept[lines - 1];
    while (textWidth(`${last}…`, size, serif) > max && last.includes(" ")) last = last.slice(0, last.lastIndexOf(" "));
    kept[lines - 1] = `${last.replace(/[,.;:]$/, "")}…`;
    return kept;
  }
  return out;
}
const x = (s) => esc(s);

/** A tiny PNG encoder for the mesh pixels (RGBA). */
function png(width, height, rgba) {
  const crcTable = new Int32Array(256).map((_, n) => { let c = n; for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1; return c; });
  const crc = (buf) => { let c = -1; for (const b of buf) c = crcTable[(c ^ b) & 255] ^ (c >>> 8); return (c ^ -1) >>> 0; };
  const chunk = (type, data) => {
    const len = Buffer.alloc(4); len.writeUInt32BE(data.length);
    const td = Buffer.concat([Buffer.from(type), data]);
    const c = Buffer.alloc(4); c.writeUInt32BE(crc(td));
    return Buffer.concat([len, td, c]);
  };
  const raw = Buffer.alloc((width * 4 + 1) * height);
  for (let y = 0; y < height; y++) {
    raw[y * (width * 4 + 1)] = 0;
    Buffer.from(rgba.buffer, rgba.byteOffset + y * width * 4, width * 4).copy(raw, y * (width * 4 + 1) + 1);
  }
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(width, 0); ihdr.writeUInt32BE(height, 4); ihdr[8] = 8; ihdr[9] = 6;
  return Buffer.concat([Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]), chunk("IHDR", ihdr), chunk("IDAT", zlib.deflateSync(raw)), chunk("IEND", Buffer.alloc(0))]);
}

const meshCanvas = (mesh) => G.meshCanvas(mesh);
const meshUri = new Map();
function meshImage(mesh) {
  const k = JSON.stringify(mesh);
  if (!meshUri.has(k)) {
    const c = meshCanvas(mesh);
    meshUri.set(k, `data:image/png;base64,${png(c.pixels.width, c.pixels.height, c.pixels.data).toString("base64")}`);
  }
  return meshUri.get(k);
}
let uid = 0;
/** A wallpaper's background in a w × h box: mesh (or photo), then its doodles. unit = one app pixel. */
function wallSvg(item, wall, c, w, h, unit) {
  if (!wall) return `<rect width="${w}" height="${h}" fill="${c.surf}"/>`;
  // A theme's image wallpaper carries a path into the wallpaper's own folder (`../<id>/<file>`).
  if (wall.kind === "image" && (item?.type === "wallpaper" || item?.type === "theme")) {
    const file = join(DIR, "wallpapers", item.id, wall.file || wall.thumb || "");
    if (existsSync(file) && statSync(file).isFile()) {
      const type = /\.png$/i.test(file) ? "png" : "jpeg";
      return `<image href="data:image/${type};base64,${readFileSync(file).toString("base64")}" width="${w}" height="${h}" preserveAspectRatio="xMidYMid slice"/>`;
    }
    return `<rect width="${w}" height="${h}" fill="${c.surf}"/>`;
  }
  if (wall.kind === "image") return `<rect width="${w}" height="${h}" fill="${c.surf}"/>`;
  let out = `<image href="${meshImage(G.meshOf(wall, c, false))}" width="${w}" height="${h}" preserveAspectRatio="none"/>`;
  const intensity = typeof wall.intensity === "number" ? wall.intensity : 0.5;
  const own = G.doodlesOf(wall);
  if ((own || (wall.pattern && wall.pattern !== "none")) && intensity > 0) {
    const ink = G.mix(c.p, "#000000", 0.25);
    const tile = G.patternSvg(wall.pattern, ink, 0.22 * intensity, own).replace(/^<svg[^>]*>/, "").replace(/<\/svg>$/, "");
    const size = 260 * unit, id = `p${++uid}`;
    out += `<defs><pattern id="${id}" patternUnits="userSpaceOnUse" width="${size}" height="${size}" viewBox="0 0 260 260">${tile}</pattern></defs><rect width="${w}" height="${h}" fill="url(#${id})"/>`;
  }
  return out;
}
/** The app's small chat in a look, in a w × h box. */
function chatSvg(item, w, h) {
  const look = G.lookOf(item, { alone: false });
  const c = G.scheme(look.scheme, false);
  const u = Math.min(w / 320, h / 200);
  const bot = c.lowest, me = G.mix(bot, c.p, 0.18);
  const head = `'${look.headingFont}', '${SERIF}'`, body = `'${look.bodyFont}', '${SANS}'`;
  const fs = 12.5 * u, pad = 14 * u;
  const bubble = (text, right, y) => {
    const tw = textWidth(text, fs) + 22 * u;
    const bx = right ? w - pad - tw : pad, bh = 30 * u;
    return `<rect x="${bx}" y="${y}" width="${tw}" height="${bh}" rx="${15 * u}" fill="${right ? me : bot}"/><text x="${bx + 11 * u}" y="${y + bh / 2 + fs * 0.35}" font-family="${x(body)}" font-size="${fs}" fill="${c.onSurf}">${x(text)}</text>`;
  };
  const compY = h - pad - 34 * u;
  const cloud = G.nodesMarkup(iconNodes("cloud"));
  const arrow = G.nodesMarkup(iconNodes("arrow-up"));
  return `<rect width="${w}" height="${h}" fill="${c.surf}"/>${wallSvg(item, look.wallpaper, c, w, h, u)}
<rect x="${pad}" y="${12 * u}" width="${110 * u}" height="${32 * u}" rx="${16 * u}" fill="${c.surf}" fill-opacity="0.78"/>
<circle cx="${pad + 16 * u}" cy="${28 * u}" r="${12 * u}" fill="${c.p}"/>
<g transform="translate(${pad + 16 * u - 6.5 * u} ${28 * u - 6.5 * u}) scale(${(13 * u) / 24})" fill="none" stroke="${c.onP}" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">${cloud}</g>
<text x="${pad + 36 * u}" y="${28 * u + 5.2 * u}" font-family="${x(head)}" font-size="${15 * u}" font-weight="700" fill="${c.onSurf}">Casama</text>
${bubble("Can you tidy up my notes?", true, compY - 12 * u - 30 * u - 8 * u - 30 * u)}
${bubble("Done! They are in three folders now.", false, compY - 12 * u - 30 * u)}
<rect x="${pad}" y="${compY}" width="${w - pad * 2 - 42 * u}" height="${34 * u}" rx="${17 * u}" fill="${c.lowest}" stroke="${c.outline}" stroke-opacity="0.6" stroke-width="${Math.max(1, u)}"/>
<text x="${pad + 13 * u}" y="${compY + 17 * u + fs * 0.35}" font-family="${x(body)}" font-size="${fs}" fill="${c.onSurfVar}">Message</text>
<circle cx="${w - pad - 17 * u}" cy="${compY + 17 * u}" r="${17 * u}" fill="${c.p}"/>
<g transform="translate(${w - pad - 17 * u - 8 * u} ${compY + 17 * u - 8 * u}) scale(${(16 * u) / 24})" fill="none" stroke="${c.onP}" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round">${arrow}</g>`;
}
function swatchSvg(item, w, h) {
  const c = G.scheme(item.document, false);
  const cells = [[c.p, c.onP], [c.pc, c.onPc], [c.s, c.onS], [c.t, c.onT], [c.surf, c.onSurf]];
  const lw = (w * 3) / 5, rw = w - lw, rh = h / 4;
  let out = `<rect width="${lw}" height="${h}" fill="${cells[0][0]}"/><text x="${w / 26}" y="${h - w / 26}" font-family="'${SERIF}'" font-weight="700" font-size="${w / 10}" fill="${cells[0][1]}">Aa</text>`;
  cells.slice(1).forEach(([bg, fg], i) => {
    out += `<rect x="${lw}" y="${i * rh}" width="${rw}" height="${rh}" fill="${bg}"/><text x="${lw + w / 32}" y="${(i + 1) * rh - w / 46}" font-family="'${SERIF}'" font-weight="700" font-size="${w / 24}" fill="${fg}">Aa</text>`;
  });
  return out;
}
function logoSvg(item, w, h) {
  const doc = C.doc(item);
  const hex = /^[0-9A-Fa-f]{6}$/.test(doc.color || "") ? doc.color : "6B7280";
  const ink = inkOn(hex);
  const file = join(DIR, "apps", item.id, "logo.svg");
  const s = Math.min(w, h) * 0.42;
  let mark;
  if ((item.files || []).includes(`apps/${item.id}/logo.svg`) && existsSync(file)) {
    const id = `t${++uid}`;
    mark = `<defs><filter id="${id}" x="0" y="0" width="1" height="1"><feFlood flood-color="${ink}"/><feComposite in2="SourceAlpha" operator="in"/></filter></defs><image href="data:image/svg+xml;base64,${readFileSync(file).toString("base64")}" x="${(w - s) / 2}" y="${(h - s) / 2}" width="${s}" height="${s}" filter="url(#${id})"/>`;
  } else {
    mark = `<text x="${w / 2}" y="${h / 2 + s * 0.36}" text-anchor="middle" font-family="'${SANS}'" font-weight="700" font-size="${s}" fill="${ink}">${x((item.name || "?").charAt(0).toUpperCase())}</text>`;
  }
  return `<rect width="${w}" height="${h}" fill="#${hex}"/>${mark}`;
}
/** Skills, bots, routines, plugins and sets: the icon and up to three lines of what it does. */
function cardSvg(item, w, h) {
  const doc = C.doc(item);
  const icon = doc.icon || item.icon || { skill: "book-open", bot: "bot", routine: "repeat", plugin: "puzzle", set: "package" }[item.type] || "book-open";
  const lines = C.examples(item).length ? C.examples(item)
    : item.type === "bot" ? (doc.starters || []) : item.type === "plugin" ? (doc.adds || [])
      : item.type === "set" ? C.setItems(item).map((m) => find(m.type, m.id)?.name ?? m.id)
        : item.type === "routine" ? [C.schedule(doc.schedule_cron)] : [];
  let out = `<rect width="${w}" height="${h}" fill="#f4f4f5"/><circle cx="${w / 2}" cy="${lines.length ? 120 : h / 2}" r="64" fill="${ACCENT}"/>
<g transform="translate(${w / 2 - 34} ${(lines.length ? 120 : h / 2) - 34}) scale(${68 / 24})" fill="none" stroke="#ffffff" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">${G.nodesMarkup(iconNodes(icon))}</g>`;
  lines.slice(0, 3).forEach((line, i) => {
    const text = wrap(line, 20, w - 96, 1)[0] ?? "";
    const tw = Math.min(w - 48, textWidth(text, 20) + 36), y = 222 + i * 72;
    out += `<rect x="${(w - tw) / 2}" y="${y}" width="${tw}" height="52" rx="26" fill="#ffffff"/><text x="${w / 2}" y="${y + 33}" text-anchor="middle" font-family="'${SANS}'" font-size="20" fill="${INK}">${x(text)}</text>`;
  });
  return out;
}
function previewSvg(item, w, h) {
  if (item.type === "theme") return chatSvg(item, w, h);
  if (item.type === "scheme") return swatchSvg(item, w, h);
  if (item.type === "wallpaper") {
    const c = G.scheme(null, false);
    return wallSvg(item, G.wallpaperOf(item), c, w, h, Math.min(w, h) / 320);
  }
  if (item.type === "app") return logoSvg(item, w, h);
  return cardSvg(item, w, h);
}
function boxed(inner, bx, by, w, h, r) {
  const id = `c${++uid}`;
  return `<defs><clipPath id="${id}"><rect x="${bx}" y="${by}" width="${w}" height="${h}" rx="${r}"/></clipPath></defs><g clip-path="url(#${id})"><svg x="${bx}" y="${by}" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}" overflow="hidden">${inner}</svg></g><rect x="${bx + 0.5}" y="${by + 0.5}" width="${w - 1}" height="${h - 1}" rx="${r}" fill="none" stroke="#000" stroke-opacity="0.08"/>`;
}
function textBlock({ eyebrow, title, desc, width = 520 }) {
  const titleSize = title.length > 26 ? 50 : 60;
  const tl = wrap(title, titleSize, width, 2, true);
  let y = 132;
  let out = `<text x="72" y="92" font-family="'${SERIF}'" font-weight="700" font-size="28" fill="${INK}">Casama <tspan fill="${MUTED}" font-weight="400">Gallery</tspan></text>`;
  y += 54;
  out += `<text x="72" y="${y}" font-family="'${SANS}'" font-weight="700" font-size="22" letter-spacing="1.5" fill="${ACCENT}">${x(eyebrow.toUpperCase())}</text>`;
  y += 22;
  tl.forEach((l) => { y += titleSize * 1.18; out += `<text x="72" y="${y}" font-family="'${SERIF}'" font-weight="700" font-size="${titleSize}" fill="${INK}">${x(l)}</text>`; });
  y += 22;
  wrap(desc, 27, width, tl.length > 1 ? 3 : 4).forEach((l) => { y += 38; out += `<text x="72" y="${y}" font-family="'${SANS}'" font-size="27" fill="${MUTED}">${x(l)}</text>`; });
  out += `<text x="72" y="${H - 64}" font-family="'${SANS}'" font-weight="700" font-size="22" fill="${INK}">gallery.casama.ai</text>`;
  return out;
}
function ogSvg(item) {
  const by = item.author?.name && item.author.name !== "Casama" ? ` · by ${item.author.name}` : "";
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}"><rect width="${W}" height="${H}" fill="#ffffff"/>
${textBlock({ eyebrow: C.SINGULAR[item.type] + by, title: item.name, desc: describe(item) })}
${boxed(previewSvg(item, 468, 486), 660, 72, 468, 486, 28)}</svg>`;
}
function homeOgSvg() {
  const looks = items.filter((i) => i.featured && (i.type === "theme" || i.type === "wallpaper" || i.type === "scheme"));
  const pick = ["theme", "wallpaper", "scheme", "theme"].map((t, n) => looks.filter((i) => i.type === t)[n === 3 ? 1 : 0]).filter(Boolean);
  const counts = C.TYPES.map((t) => [t, items.filter((i) => i.type === t).length]).filter(([, n]) => n);
  const desc = `${counts.map(([t, n]) => C.count(n, t)).slice(0, 4).join(", ")} and more. Free and open source.`;
  let tiles = "";
  pick.forEach((item, i) => { tiles += boxed(previewSvg(item, 228, 237), 660 + (i % 2) * 240, 72 + Math.floor(i / 2) * 249, 228, 237, 20); });
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}"><rect width="${W}" height="${H}" fill="#ffffff"/>
${textBlock({ eyebrow: "Open source", title: "Looks, skills, apps and bots", desc })}${tiles}</svg>`;
}

let Resvg = null;
let fontFiles = [];
function render(svg) {
  if (!Resvg) {
    ({ Resvg } = require("@resvg/resvg-js"));
    const fontDirs = [join(here, "assets/fonts"), join(here, "../site/assets/fonts")];
    const wanted = ["GoogleSans-Regular.ttf", "GoogleSans-Bold.ttf", "LibreBaskerville-Regular.ttf", "LibreBaskerville-Bold.ttf"];
    fontFiles = wanted.map((f) => fontDirs.map((d) => join(d, f)).find((p) => existsSync(p))).filter(Boolean);
  }
  const r = new Resvg(svg, { fitTo: { mode: "width", value: W }, font: { loadSystemFonts: false, fontFiles, defaultFontFamily: SANS, serifFamily: SERIF, sansSerifFamily: SANS } });
  return r.render().asPng();
}

// ---------------------------------------------------------------- write
function write(path, content) {
  const full = join(DIR, path);
  mkdirSync(dirname(full), { recursive: true });
  writeFileSync(full, content);
}
for (const out of ["i", "by"]) rmSync(join(DIR, out), { recursive: true, force: true });

const started = Date.now();
for (const item of all) {
  write(`${C.pagePath(item).slice(1)}index.html`, itemPage(item));
  if (WITH_OG) write(`${C.pagePath(item).slice(1)}og.png`, render(ogSvg(item)));
}
for (const a of authors.values()) write(`${C.authorPath(a.handle).slice(1)}index.html`, authorPage(a));
if (WITH_OG) write("og.png", render(homeOgSvg()));

// Group pages (docs/SEO-PLAN.md part D): one page per kind of item, and one per category of apps
// and skills, each with a short introduction and links to every item in it.
const GROUP_INTRO = {
  app: "Apps a Casama bot can connect to. Connect one once, choose which bots may use it, and ask in plain words. For each thing a bot can do in an app, you decide whether it may act alone or must ask you first.",
  skill: "Skills are written how-tos a bot loads when a task calls for them. Install one and every bot you choose knows how to do that job the same way each time.",
  bot: "Starter bots: a name, a role and instructions in one tap, some with skills and routines included. Change anything after you add one.",
  routine: "Routine ideas: work a bot starts without being asked, on a schedule or when something happens. Add one, pick the bot, and adjust the timing.",
  plugin: "Plugins give bots new skills and tools from a GitHub repository. Each one listed here was reviewed at the commit shown on its page.",
  set: "Starter sets bundle items that go together, so one tap adds a working setup.",
  theme: "Themes change the whole look of the Casama app: colors, fonts and background.",
  scheme: "Color schemes for the Casama app, each in light and dark.",
  wallpaper: "Wallpapers for the Casama app's chats.",
};
const groupPath = (type, cat) => `/c/${type}/${cat ? `${cat}/` : ""}`;
const groups = [];
for (const type of C.TYPES.concat("set")) {
  const of = all.filter((i) => i.type === type);
  if (!of.length || groups.some((g) => g.type === type && !g.cat)) continue;
  const cats = [...new Set(of.map((i) => C.category(i)).filter(Boolean))].filter((c) => (type === "app" || type === "skill") && of.filter((i) => C.category(i) === c).length >= 3);
  groups.push({ type, cat: "", items: of, cats });
  for (const cat of cats) groups.push({ type, cat, items: of.filter((i) => C.category(i) === cat), cats: [] });
}
function groupPage(g) {
  const plural = C.PLURAL[g.type];
  const label = g.cat ? C.categoryLabel(g.items[0]) : "";
  const name = g.cat ? `${label} ${plural.toLowerCase()}` : plural;
  const title = g.type === "app"
    ? (g.cat ? `${label} apps your AI agent can use · Casama Gallery` : "Apps your AI agent can connect to · Casama Gallery")
    : `${name} for Casama AI bots · Casama Gallery`;
  const intro = g.cat
    ? `${C.count(g.items.length, g.type)} in ${label.toLowerCase()}: ${g.items.slice(0, 6).map((i) => i.name).join(", ")}${g.items.length > 6 ? " and more" : ""}. ${GROUP_INTRO[g.type]}`
    : GROUP_INTRO[g.type];
  const sorted = [...g.items].sort((a, b) => a.name.localeCompare(b.name));
  const sub = g.cats.length ? `<p class="inline-list">${g.cats.map((c) => { const one = g.items.find((i) => C.category(i) === c); return `<a href="${groupPath(g.type, c)}">${esc(C.categoryLabel(one))}</a>`; }).join(" · ")}</p>` : "";
  const body = `<nav class="crumbs" aria-label="Breadcrumb"><a href="/">Gallery</a><span aria-hidden="true">/</span>${g.cat ? `<a href="${groupPath(g.type)}">${esc(plural)}</a><span aria-hidden="true">/</span><span>${esc(label)}</span>` : `<span>${esc(plural)}</span>`}</nav>
<div class="title-row"><h1>${esc(g.type === "app" && !g.cat ? "Apps your AI agent can connect to" : name)}</h1><p class="sub">${esc(intro)}</p></div>
${sub}
<section class="section"><div class="section-head"><h2>${esc(name)}<span class="n">${sorted.length}</span></h2></div><ul class="skills">${sorted.map(rowHtml).join("")}</ul></section>`;
  const path = groupPath(g.type, g.cat);
  return shell({
    title, description: intro.slice(0, 200), path, image: `${SITE}/og.png`, body,
    data: { looks: sorted.filter(C.isLook).map(slim) },
    ld: [{ "@context": "https://schema.org", "@type": "CollectionPage", name, description: intro, url: SITE + path,
      isPartOf: { "@type": "WebSite", name: "Casama Gallery", url: `${SITE}/` },
      mainEntity: { "@type": "ItemList", numberOfItems: sorted.length, itemListElement: sorted.map((i, n) => ({ "@type": "ListItem", position: n + 1, name: i.name, url: C.pageUrl(i) })) } }],
  });
}
for (const g of groups) write(`${groupPath(g.type, g.cat).slice(1)}index.html`, groupPage(g));

// sitemap.xml: the gallery, the developer page, every item and author.
const today = new Date().toISOString().slice(0, 10);
const urls = [
  { loc: `${SITE}/`, lastmod: today },
  { loc: `${SITE}/add/` },
  { loc: `${SITE}/make.html` },
  ...groups.map((g) => ({ loc: SITE + groupPath(g.type, g.cat), lastmod: g.items.map((i) => i.updated || i.added || "").sort().at(-1) })),
  ...all.map((i) => ({ loc: C.pageUrl(i), lastmod: i.updated || i.added })),
  ...[...authors.values()].map((a) => ({ loc: SITE + C.authorPath(a.handle) })),
];
write("sitemap.xml", `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
${urls.map((u) => `  <url><loc>${esc(u.loc)}</loc>${/^\d{4}-\d{2}-\d{2}$/.test(u.lastmod || "") ? `<lastmod>${u.lastmod}</lastmod>` : ""}</url>`).join("\n")}
</urlset>
`);

// llms.txt: what the gallery is and where its catalog lives, for AI agents.
write("llms.txt", `# Casama Gallery

> Free, open-source add-ons for Casama, the open-source app for AI teammates with their own computers: ${C.TYPES.map((t) => C.count(all.filter((i) => i.type === t).length, t)).join(", ")}. Every item has its own page and is reviewed before it is listed.

- [Casama](https://casama.ai/llms.txt): what Casama is, with links to its docs
- [Add something to the gallery](${SITE}/add/): how to propose an item by pull request

## Catalog (public JSON, no sign-in)

${["index", "apps", "bots", "routines", "plugins", "sets", "authors"].map((f) => `- [${f}.json](${SITE}/${f}.json)`).join("\n")}
- [Usage stats](https://api.casama.ai/v1/gallery/stats): installs and trending per item

## Items

${C.TYPES.map((t) => { const of = all.filter((i) => i.type === t); return of.length ? `### ${C.PLURAL[t]}\n\n${of.map((i) => `- [${i.name}](${C.pageUrl(i)}): ${describe(i)}`).join("\n")}` : ""; }).filter(Boolean).join("\n\n")}
`);

// A size check against Cloudflare's static asset limits (20,000 files, 25 MiB each).
function walk(d) { return readdirSync(d, { withFileTypes: true }).flatMap((e) => (e.isDirectory() ? walk(join(d, e.name)) : [join(d, e.name)])); }
const outFiles = ["i", "by", "c"].flatMap((d) => (existsSync(join(DIR, d)) ? walk(join(DIR, d)) : []));
const bytes = outFiles.reduce((n, f) => n + statSync(f).size, 0);
const biggest = outFiles.reduce((m, f) => Math.max(m, statSync(f).size), 0);
if (biggest > 25 * 1024 * 1024) throw new Error("A generated file is over Cloudflare's 25 MiB limit.");
console.log(`Gallery pages: ${all.length} items, ${authors.size} authors, ${outFiles.length} files, ${(bytes / 1048576).toFixed(1)} MiB (largest ${(biggest / 1024).toFixed(0)} KiB)${WITH_OG ? "" : ", no share images"}, in ${((Date.now() - started) / 1000).toFixed(1)} s → ${relative(process.cwd(), DIR) || "."}/i, /by, sitemap.xml`);
