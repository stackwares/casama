#!/usr/bin/env node
/**
 * Builds casama.ai's written pages (docs/SEO-PLAN.md §10.1): pricing, self-hosted, alternatives,
 * comparisons, use cases, question pages, the blog and the changelog.
 *
 *   node site/build.mjs           writes the pages
 *   node site/build.mjs --check   runs the checks and writes nothing
 *
 * In:  site/content/**.md (front matter + markdown), site/data/*.json, CHANGELOG.md, and the header
 *      and footer of site/index.html (so there is one copy of each).
 * Out: an .html page and a .md copy for each content file, sitemap.xml, the "Pages" part of
 *      llms.txt, and RSS feeds for the blog and changelog. Everything it writes is listed in
 *      site/.gitignore except sitemap.xml and llms.txt, which stay in the repo, and the list of
 *      starter bots in index.html (D-382), which it rewrites between its markers.
 *
 * No dependencies: it has its own small markdown renderer, enough for these pages.
 */
import { existsSync, mkdirSync, readdirSync, readFileSync, rmSync, statSync, writeFileSync } from "node:fs";
import { dirname, join, relative } from "node:path";
import { fileURLToPath } from "node:url";

const HERE = dirname(fileURLToPath(import.meta.url));
const ROOT = join(HERE, "..");
const CONTENT = join(HERE, "content");
const SITE = "https://casama.ai";
const CHECK_ONLY = process.argv.includes("--check");
const TODAY = new Date().toISOString().slice(0, 10);
/** A rival fact older than this fails the build, so a comparison never goes stale unnoticed. */
const MAX_SOURCE_AGE_DAYS = 45;
const MIN_WORDS = 300;

const read = (path) => readFileSync(path, "utf8");
const json = (name) => JSON.parse(read(join(HERE, "data", name)));
const product = json("product.json");
const plans = json("plans.json");
const rivalData = json("rivals.json");
const rivals = new Map(rivalData.rivals.map((r) => [r.id, r]));
const staticPages = json("static-pages.json");

/**
 * A page's picture: site/assets/blog/<name>.jpg for posts and site/assets/pages/<name>.jpg for core pages
 * such as self-hosted (1200x630), with a .webp beside it when there is one and alt text from that folder's
 * manifest.json. A page without a file simply has no picture.
 */
const ART_DIRS = { blog: "blog", "": "pages" };
const artAlts = new Map();
function altsIn(folder) {
  if (!artAlts.has(folder)) {
    try {
      const list = JSON.parse(read(join(HERE, "assets", folder, "manifest.json")));
      const rows = Array.isArray(list) ? list : (list.images ?? list.files ?? Object.entries(list).map(([slug, v]) => ({ slug, ...v })));
      artAlts.set(folder, new Map(rows.map((r) => [String(r.slug ?? r.file ?? "").replace(/\.(png|webp)$/, "").split("/").pop(), r.alt ?? r.alt_text ?? r.altText ?? ""])));
    } catch {
      artAlts.set(folder, new Map());
    }
  }
  return artAlts.get(folder);
}
function artFor(page) {
  const folder = ART_DIRS[page.section];
  if (!folder || page.isIndex) return null;
  const name = page.slug.split("/").pop();
  const dir = join(HERE, "assets", folder);
  if (!existsSync(join(dir, `${name}.jpg`))) return null;
  const alt = altsIn(folder).get(name) ?? "";
  if (!alt) fail(`${page.file}: its picture has no alt text in assets/${folder}/manifest.json`);
  return { png: `/assets/${folder}/${name}.jpg`, webp: existsSync(join(dir, `${name}.webp`)) ? `/assets/${folder}/${name}.webp` : null, alt };
}
/**
 * What a page shows when it's shared: a post its picture; any other page its card from
 * visuals/render-cards.mjs (site/assets/cards/<slug>.jpg: its title on the section's painted background);
 * then the home page's card.
 */
function shareFor(page) {
  const art = artFor(page);
  const card = existsSync(join(HERE, "assets", "cards", `${page.slug}.jpg`)) ? { png: `/assets/cards/${page.slug}.jpg`, alt: page.meta.h1 ?? page.meta.title } : null;
  return (page.section === "blog" ? (art ?? card) : (card ?? art)) ?? { png: "/og-image.png", alt: null };
}

const problems = [];
const fail = (message) => problems.push(message);

const esc = (s) =>
  String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
const slugify = (s) =>
  s.toLowerCase().replace(/<[^>]+>/g, "").replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
const longDate = (iso) =>
  new Date(`${iso}T00:00:00Z`).toLocaleDateString("en-US", { year: "numeric", month: "long", day: "numeric", timeZone: "UTC" });

// ---------------------------------------------------------------- markdown

/** Inline markdown: `code`, **bold**, *emphasis*, [text](url). */
function inline(text) {
  const codes = [];
  let out = esc(text).replace(/`([^`]+)`/g, (_m, code) => {
    codes.push(`<code>${code}</code>`);
    return `\u0000${codes.length - 1}\u0000`;
  });
  out = out
    .replace(/\[([^\]]+)\]\(([^)\s]+)\)/g, (_m, label, href) => `<a href="${href}">${label}</a>`)
    .replace(/\*\*([^*]+)\*\*/g, "<strong>$1</strong>")
    .replace(/(^|[\s(])\*([^*\s][^*]*)\*/g, "$1<em>$2</em>");
  return out.replace(/\u0000(\d+)\u0000/g, (_m, i) => codes[Number(i)]);
}

function table(rows) {
  const cells = (row) => row.replace(/^\s*\|/, "").replace(/\|\s*$/, "").split(/(?<!\\)\|/).map((c) => c.trim().replace(/\\\|/g, "|"));
  const head = cells(rows[0]);
  const body = rows.slice(2).map(cells);
  const us = head.findIndex((h) => h === "Casama");
  return `<div class="table-scroll"><table class="compare cols-${head.length}">
<thead><tr>${head.map((h, i) => `<th scope="col"${i === us ? ' class="us"' : ""}>${inline(h)}</th>`).join("")}</tr></thead>
<tbody>
${body.map((row) => `<tr>${row.map((c, i) => (i === 0 ? `<th scope="row">${inline(c)}</th>` : `<td${i === us ? ' class="us"' : ""} data-label="${esc(head[i] ?? "")}">${inline(c)}</td>`)).join("")}</tr>`).join("\n")}
</tbody></table></div>`;
}

/** A list, with nesting by indentation (two or more spaces deeper starts a child list). */
function list(lines) {
  const items = [];
  for (const line of lines) {
    const m = line.match(/^(\s*)([-*]|\d+\.)\s+(.*)$/);
    if (m) items.push({ indent: m[1].length, ordered: /\d/.test(m[2]), text: m[3] });
    else if (items.length) items[items.length - 1].text += ` ${line.trim()}`;
  }
  const build = (from, indent) => {
    const ordered = items[from].ordered;
    let html = ordered ? "<ol>" : "<ul>";
    let i = from;
    while (i < items.length && items[i].indent >= indent) {
      if (items[i].indent > indent) {
        const [child, next] = build(i, items[i].indent);
        html = html.replace(/<\/li>$/, `${child}</li>`);
        i = next;
        continue;
      }
      html += `<li>${inline(items[i].text)}</li>`;
      i++;
    }
    return [`${html}${ordered ? "</ol>" : "</ul>"}`, i];
  };
  return build(0, items[0].indent)[0];
}

/** Block markdown → HTML. `tokens` renders a `{{name: args}}` line. Returns the HTML and its h2s. */
function markdown(source, tokens = () => "") {
  const lines = source.replace(/\r/g, "").split("\n");
  const out = [];
  const headings = [];
  let i = 0;
  while (i < lines.length) {
    const line = lines[i];
    if (!line.trim()) { i++; continue; }
    const token = line.match(/^\{\{\s*([a-z-]+)\s*(?::\s*(.*?))?\s*\}\}$/);
    if (token) { out.push(tokens(token[1], (token[2] ?? "").split(",").map((s) => s.trim()).filter(Boolean))); i++; continue; }
    if (/^```/.test(line)) {
      const code = [];
      i++;
      while (i < lines.length && !/^```/.test(lines[i])) code.push(lines[i++]);
      i++;
      out.push(`<pre><code>${esc(code.join("\n"))}</code></pre>`);
      continue;
    }
    const h = line.match(/^(#{2,4})\s+(.*)$/);
    if (h) {
      const level = h[1].length;
      const id = slugify(h[2]);
      if (level === 2) headings.push({ id, text: h[2] });
      out.push(`<h${level} id="${id}">${inline(h[2])}</h${level}>`);
      i++;
      continue;
    }
    if (/^\s*\|/.test(line) && /^\s*\|[\s:|-]+\|\s*$/.test(lines[i + 1] ?? "")) {
      const rows = [];
      while (i < lines.length && /^\s*\|/.test(lines[i])) rows.push(lines[i++]);
      out.push(table(rows));
      continue;
    }
    if (/^\s*([-*]|\d{1,2}\.)\s+/.test(line)) {
      const block = [];
      while (i < lines.length && (/^\s*([-*]|\d+\.)\s+/.test(lines[i]) || (/^\s+\S/.test(lines[i]) && block.length))) block.push(lines[i++]);
      out.push(list(block));
      continue;
    }
    if (/^>/.test(line)) {
      const quote = [];
      while (i < lines.length && /^>/.test(lines[i])) quote.push(lines[i++].replace(/^>\s?/, ""));
      out.push(`<blockquote>${markdown(quote.join("\n")).html}</blockquote>`);
      continue;
    }
    if (/^</.test(line)) { out.push(line); i++; continue; }
    const para = [];
    while (i < lines.length && lines[i].trim() && !/^(#{2,4}\s|```|>|\s*\||\{\{|\s*([-*]|1\.)\s+)/.test(lines[i])) para.push(lines[i++].trim());
    out.push(`<p>${inline(para.join(" "))}</p>`);
  }
  return { html: out.join("\n"), headings };
}

const plainWords = (html) => html.replace(/<[^>]+>/g, " ").split(/\s+/).filter(Boolean).length;

// ---------------------------------------------------------------- content files

function frontMatter(source, file) {
  const m = source.match(/^---\n([\s\S]*?)\n---\n?/);
  if (!m) { fail(`${file}: no front matter`); return [{}, source]; }
  const meta = {};
  for (const line of m[1].split("\n")) {
    const kv = line.match(/^([a-z0-9_]+):\s*(.*)$/i);
    if (!kv) continue;
    let value = kv[2].trim();
    if (/^\[.*\]$/.test(value)) value = value.slice(1, -1).split(",").map((s) => s.trim()).filter(Boolean);
    else value = value.replace(/^"(.*)"$/, "$1");
    meta[kv[1]] = value;
  }
  return [meta, source.slice(m[0].length)];
}

function walk(dir, found = []) {
  if (!existsSync(dir)) return found;
  for (const name of readdirSync(dir).sort()) {
    const path = join(dir, name);
    if (statSync(path).isDirectory()) walk(path, found);
    else if (name.endsWith(".md")) found.push(path);
  }
  return found;
}

/** Section names, in the order they appear in the footer and llms.txt. */
const SECTIONS = {
  "": { name: "Casama", crumb: null },
  alternatives: { name: "Alternatives", crumb: "Alternatives" },
  compare: { name: "Comparisons", crumb: "Compare" },
  "use-cases": { name: "Use cases", crumb: "Use cases" },
  learn: { name: "Questions", crumb: "Learn" },
  blog: { name: "Blog", crumb: "Blog" },
};

const pages = walk(CONTENT).map((file) => {
  const rel = relative(CONTENT, file).replace(/\\/g, "/");
  const [meta, body] = frontMatter(read(file), rel);
  const section = rel.includes("/") ? rel.split("/")[0] : "";
  let slug = rel.replace(/\.md$/, "");
  // Posts are named 2026-11-18-title.md so they sort by date; the address drops the date.
  const dated = slug.match(/^blog\/(\d{4}-\d{2}-\d{2})-(.+)$/);
  if (dated) { slug = `blog/${dated[2]}`; meta.published ??= dated[1]; }
  const isIndex = slug === "index" || slug.endsWith("/index");
  const path = isIndex ? `/${slug.replace(/index$/, "")}` : `/${slug}`;
  if (!SECTIONS[section]) fail(`${rel}: unknown section "${section}"`);
  return { file: rel, meta, body, section, slug, path, isIndex, out: `${slug}.html`, url: `${SITE}${path}` };
});

// ---------------------------------------------------------------- the FAQ (docs-site/faq.md)

// casama.ai/help, the pricing page's billing questions and their FAQPage data come from the docs'
// FAQ, so there is one copy of every answer. Its shape: "## Group", then "### Question?" and the
// answer in markdown. Its relative links are docs pages.
const DOCS = "https://docs.casama.ai";
const FAQ_FILE = join(ROOT, "docs-site", "faq.md");

function docsHref(href) {
  if (/^(https?:|mailto:)/i.test(href)) return href;
  if (href.startsWith("#")) return `${DOCS}/faq${href}`;
  const path = href.startsWith("/") ? href : `/${href.replace(/^\.\//, "")}`;
  return DOCS + path.replace(/\.md(?=$|#)/, "").replace(/\/index(?=$|#)/, "/");
}

const plainText = (html) =>
  html.replace(/<[^>]+>/g, " ").replace(/&quot;/g, '"').replace(/&#39;/g, "'").replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&amp;/g, "&").replace(/\s+/g, " ").trim();

function readFaq() {
  if (!existsSync(FAQ_FILE)) { fail("docs-site/faq.md is missing (casama.ai/help is built from it)"); return []; }
  const lines = read(FAQ_FILE).replace(/\r/g, "").replace(/^---\n[\s\S]*?\n---\n/, "").split("\n");
  const groups = [];
  const ids = new Set();
  const uniqueId = (text) => {
    let id = slugify(text) || "question";
    for (let n = 2; ids.has(id); n++) id = `${slugify(text)}-${n}`;
    ids.add(id);
    return id;
  };
  let question = null;
  let fence = false;
  for (const line of lines) {
    if (/^\s*(```|~~~)/.test(line)) fence = !fence;
    const h2 = !fence && line.match(/^##\s+(.+?)\s*(\{#[^}]*\})?\s*$/);
    const h3 = !fence && line.match(/^###\s+(.+?)\s*(\{#[^}]*\})?\s*$/);
    if (h2) {
      groups.push({ name: h2[1], id: uniqueId(`topic ${h2[1]}`), items: [] });
      question = null;
    } else if (h3) {
      if (!groups.length) groups.push({ name: "Questions", id: uniqueId("topic questions"), items: [] });
      question = { md: h3[1], body: [], group: groups.at(-1).name };
      groups.at(-1).items.push(question);
    } else if (question && (fence || !/^(#\s|:::)/.test(line))) {
      question.body.push(line.replace(/!\[[^\]]*\]\([^)]*\)/g, ""));
    }
  }
  for (const group of groups) {
    for (const q of group.items) {
      q.html = inline(q.md);
      q.text = plainText(q.html);
      q.id = uniqueId(q.text);
      q.answerHtml = markdown(q.body.join("\n")).html.replace(/href="([^"]+)"/g, (_m, href) => `href="${docsHref(href)}"`);
      q.answerText = plainText(q.answerHtml);
      q.answerMd = q.body.join("\n").trim().replace(/\]\(([^)\s]+)\)/g, (_m, href) => `](${docsHref(href)})`);
      delete q.body;
    }
  }
  const kept = groups.filter((g) => g.items.length);
  if (!kept.some((g) => g.items.length)) fail("docs-site/faq.md: no questions found (### headings under ## groups)");
  return kept;
}
const faqGroups = readFaq();

const faqDetails = (items) =>
  items.map((q) => `<details class="qa" id="${q.id}" data-help-q><summary>${q.html}</summary><div class="qa-a">${q.answerHtml}</div></details>`).join("\n");
const faqText = (items) => items.map((q) => `### ${q.md}\n\n${q.answerMd}`).join("\n\n");
const faqSchema = (items) => ({
  "@context": "https://schema.org",
  "@type": "FAQPage",
  mainEntity: items.map((q) => ({ "@type": "Question", name: q.text, acceptedAnswer: { "@type": "Answer", text: q.answerText } })),
});

/** Billing questions for the pricing page: a group named for billing, plans or pricing, else questions about money. */
function billingQuestions() {
  const groups = faqGroups.filter((g) => /billing|pricing|plans/i.test(g.name));
  if (groups.length) return groups.flatMap((g) => g.items);
  return faqGroups.flatMap((g) => g.items).filter((q) => /\b(credits?|plans?|price|pricing|billing|cancel|refunds?|trial|pay|paid|subscriptions?|free)\b/i.test(q.text)).slice(0, 6);
}

/** casama.ai/help: one search box over every question, the topics, and Casama Help inline ({{help}}). */
function helpPage(page) {
  const all = faqGroups.flatMap((g) => g.items);
  page.faq = all;
  page.scripts = ["/assets/support/help-page.js"];
  return `<div class="help" data-help>
<div class="help-search" role="search" data-help-search hidden>
  <label for="help-q" class="visually-hidden">Search the questions</label>
  <input id="help-q" type="search" name="q" placeholder="Search the questions" autocomplete="off" spellcheck="false" maxlength="200">
</div>
<nav class="help-chips" aria-label="Topics">${faqGroups.map((g) => `<a href="#${g.id}">${esc(g.name)}</a>`).join("")}<a href="#ask">Ask Casama Help</a></nav>
<p class="help-status visually-hidden" aria-live="polite" data-help-status></p>
${faqGroups.map((g) => `<section class="help-group" id="${g.id}" data-help-group>
<h2>${inline(g.name)}</h2>
<div class="faq-list">
${faqDetails(g.items)}
</div>
</section>`).join("\n")}
<p class="help-none" data-help-none hidden>No matching questions.</p>
<p class="help-ask" data-help-ask hidden><button type="button" class="btn sm primary" data-help-ask-btn>Ask Casama Help about “<span data-help-ask-text></span>”</button></p>
<section class="help-chat" id="ask" aria-labelledby="ask-title">
<h2 id="ask-title">Ask Casama Help</h2>
<p>Casama Help answers from our docs and links the pages it used. It can't see your account.</p>
<div class="help-chat-box" data-casama-help-inline><p class="help-chat-off">Casama Help needs JavaScript. You can still <a href="mailto:support@casama.ai">email support@casama.ai</a>.</p></div>
</section>
<section class="help-more" aria-label="More help">
<p><strong>Still stuck?</strong> Email <a href="mailto:support@casama.ai">support@casama.ai</a>.</p>
<p><strong>Signed up?</strong> Open <strong>Help &amp; support</strong> in the app for account help.</p>
</section>
</div>`;
}

/** The pricing page's billing questions from the FAQ ({{faq}}). */
function faqSection(page) {
  const items = billingQuestions();
  page.faq = [...(page.faq ?? []), ...items];
  const more = `<p><a class="text-link" href="/help">More questions on the help page</a></p>`;
  if (!items.length) return more;
  return `<h2 id="plans-and-billing-questions">Plans and billing questions</h2>\n<div class="faq-list">\n${faqDetails(items)}\n</div>\n${more}`;
}

// ---------------------------------------------------------------- tokens ({{…}} lines)

const casama = rivalData.casama;
const ROWS = rivalData.rows;

function sourceAge(rival) {
  for (const [key, fact] of Object.entries(rival.facts)) {
    if (!fact || fact.value == null) continue;
    if (!fact.source) fail(`rivals.json: ${rival.id}.${key} has no source`);
  }
  const age = (Date.parse(TODAY) - Date.parse(rival.checked ?? rivalData.checked)) / 86400000;
  if (age > MAX_SOURCE_AGE_DAYS) fail(`rivals.json: ${rival.id} was last checked ${Math.round(age)} days ago (limit ${MAX_SOURCE_AGE_DAYS}). Re-read its sources and update "checked".`);
}

function need(id, where) {
  const rival = rivals.get(id);
  if (!rival) { fail(`${where}: no rival "${id}" in rivals.json`); return null; }
  return rival;
}

function compareTable(ids, where, rowKeys) {
  const list = ids.map((id) => need(id, where)).filter(Boolean);
  list.forEach(sourceAge);
  const keys = rowKeys?.length ? rowKeys : ROWS.map((r) => r.key);
  const head = `| | Casama | ${list.map((r) => r.name).join(" | ")} |`;
  const rule = `|---|---|${list.map(() => "---").join("|")}|`;
  const cell = (v) => String(v ?? "Not confirmed").replace(/\|/g, "\\|");
  const body = keys.map((key) => {
    const row = ROWS.find((r) => r.key === key);
    if (!row) { fail(`${where}: no row "${key}" in rivals.json`); return ""; }
    return `| ${row.label} | ${cell(casama[key])} | ${list.map((r) => cell(r.facts[key]?.value)).join(" | ")} |`;
  });
  return markdown([head, rule, ...body].join("\n")).html;
}

function sourcesList(ids, where) {
  const list = ids.map((id) => need(id, where)).filter(Boolean);
  const items = list.map((r) => {
    const urls = [...new Set([...Object.values(r.facts).map((f) => f?.source), ...(r.best_at ?? []).map((b) => b.source), ...(r.limits ?? []).map((l) => l.source)].flat().filter(Boolean))];
    return `<li><strong>${esc(r.name)}</strong>, checked ${longDate(r.checked ?? rivalData.checked)}: ${urls.map((u) => `<a href="${esc(u)}" rel="nofollow">${esc(new URL(u).hostname.replace(/^www\./, "") + new URL(u).pathname.replace(/\/$/, ""))}</a>`).join(", ")}</li>`;
  });
  return `<ul class="sources">${items.join("\n")}<li><strong>Casama</strong>: <a href="/pricing">pricing</a>, <a href="https://docs.casama.ai/introduction">what Casama is</a>, <a href="https://github.com/stackwares/casama">source code</a></li></ul>`;
}

function bullets(ids, field, where) {
  const rival = need(ids[0], where);
  if (!rival) return "";
  return `<ul>${(rival[field] ?? []).map((b) => `<li>${inline(b.text)}</li>`).join("")}</ul>`;
}

function plansTable() {
  const rows = plans.plans.map((p) => `| **${p.name}** | ${p.price} | ${p.credits} | ${p.bots} | ${p.computers} | ${p.storage} | ${p.seats} |`);
  return markdown(["| Plan | Price | Credits each month | Bots | Cloud computers | Library | Seats |", "|---|---|---|---|---|---|---|", ...rows].join("\n")).html;
}

function pageList(sectionNames) {
  const inSection = pages.filter((p) => sectionNames.includes(p.section) && !p.isIndex);
  inSection.sort((a, b) => (b.meta.published ?? "").localeCompare(a.meta.published ?? "") || Number(a.meta.order ?? 99) - Number(b.meta.order ?? 99) || a.meta.title.localeCompare(b.meta.title));
  return `<ul class="page-list">${inSection.map((p) => `<li><a href="${p.path}">${artFor(p) ? `<img src="${artFor(p).webp ?? artFor(p).png}" width="1200" height="630" alt="" loading="lazy">` : ""}<strong>${esc(p.meta.card ?? p.meta.h1 ?? p.meta.title)}</strong><span>${esc(p.meta.description)}</span>${p.meta.published ? `<time datetime="${p.meta.published}">${longDate(p.meta.published)}</time>` : ""}</a></li>`).join("\n")}</ul>`;
}

/**
 * The monthly email's sign-up box (D-404): the {{ newsletter }} token, and the end of every blog post
 * and the changelog. It posts to the casama.ai Worker (site/newsletter.js) like the footer form, and
 * site.js sends it without leaving the page.
 */
const newsBox = (id, heading = "Get what's new, once a month") => `<aside class="news-box" aria-labelledby="${id}-h">
  <h2 id="${id}-h">${esc(heading)}</h2>
  <p>Casama's monthly email: what shipped, what's next and one good way to use it. One email a month at most, and every one has a link to stop them.</p>
  <form class="footer-news" action="/newsletter/subscribe" method="post" data-newsletter>
    <label class="visually-hidden" for="${id}-email">Email address</label>
    <div class="footer-news-row">
      <input id="${id}-email" type="email" name="email" required autocomplete="email" inputmode="email" placeholder="you@example.com">
      <button class="btn primary sm" type="submit">Subscribe</button>
    </div>
    <input class="footer-news-hp" type="text" name="website" tabindex="-1" autocomplete="off" aria-hidden="true">
    <p class="footer-news-note" role="status" aria-live="polite"></p>
  </form>
</aside>`;

const tokensFor = (page) => (name, args) => {
  if (name === "compare") {
    const rowAt = args.indexOf("rows");
    return compareTable(rowAt < 0 ? args : args.slice(0, rowAt), page.file, rowAt < 0 ? null : args.slice(rowAt + 1));
  }
  if (name === "sources") return sourcesList(args, page.file);
  if (name === "best-at") return bullets(args, "best_at", page.file);
  if (name === "limits") return bullets(args, "limits", page.file);
  if (name === "plans") return plansTable();
  if (name === "bots") return botDirectory();
  if (name === "list") return pageList(args);
  if (name === "help") return helpPage(page);
  if (name === "faq") return faqSection(page);
  if (name === "newsletter") return newsBox("news-page", "Sign up");
  if (name === "cta") return `<p class="page-cta"><a class="btn primary" href="https://app.casama.ai">Start free</a> <a class="text-link" href="https://docs.casama.ai/self-hosting/">Run it on your own server</a></p>`;
  fail(`${page.file}: unknown token {{${name}}}`);
  return "";
};

// ---------------------------------------------------------------- the page shell

const home = read(join(HERE, "index.html"));
const cut = (open, close) => {
  const a = home.indexOf(open);
  const b = home.indexOf(close, a);
  if (a < 0 || b < 0) { fail(`index.html: couldn't find ${open}`); return ""; }
  return home.slice(a, b + close.length).replace(/href="#/g, 'href="/#');
};
const HEADER = cut('<header class="site-header">', "</header>");
const FOOTER = cut('<footer class="site-footer">', "</footer>");
const CSP = home.match(/<meta http-equiv="Content-Security-Policy"[^>]*>/)?.[0] ?? "";

// ---------------------------------------------------------------- every starter bot (D-382)

// The home page lists all of Casama's starter bots, each under the name the app gives it, between
// the starter-bots markers in index.html. They come from the gallery's copies (gallery/bots, which
// win over the built-in ones on servers, D-372) and the names from packages/domain, so the page and
// the app never disagree.
const { BOT_TEMPLATES, starterBotName } = await import("../packages/domain/src/templates.ts");
const BOT_GROUPS = [
  ["work", "Work"],
  ["research", "Research"],
  ["build", "Build"],
  ["create", "Create"],
  ["life", "Life"],
];
const GALLERY_BOTS = join(ROOT, "gallery", "bots");

function starterBots() {
  const order = BOT_TEMPLATES.map((t) => t.id);
  const ids = readdirSync(GALLERY_BOTS).filter((id) => existsSync(join(GALLERY_BOTS, id, "bot.json")));
  const rank = (id) => (order.includes(id) ? order.indexOf(id) : order.length);
  return ids
    .map((id) => {
      const item = JSON.parse(read(join(GALLERY_BOTS, id, "item.json")));
      const bot = JSON.parse(read(join(GALLERY_BOTS, id, "bot.json")));
      return { id, job: item.name, author: item.author?.handle, retired: item.retired, name: starterBotName(id), ...bot };
    })
    .filter((b) => b.author === "casama" && !b.retired)
    .sort((a, b) => rank(a.id) - rank(b.id) || a.id.localeCompare(b.id));
}

function checkBots(bots) {
  for (const b of bots) {
    if (!existsSync(join(HERE, "assets", "bots", `casama-${b.mascot}.svg`))) fail(`gallery/bots/${b.id}: no mascot site/assets/bots/casama-${b.mascot}.svg`);
    if (!BOT_GROUPS.some(([key]) => key === b.category)) fail(`gallery/bots/${b.id}: unknown category ${b.category}`);
  }
  return bots;
}
const botGroups = (bots) => BOT_GROUPS.map(([key, label]) => [label, bots.filter((b) => b.category === key)]).filter(([, list]) => list.length);

/** casama.ai/bots: every starter bot by category, each linking to its gallery page ({{bots}}). */
function botDirectory() {
  const tile = (b) =>
    `<li id="${esc(b.id)}"><a class="bot-tile" href="https://gallery.casama.ai/i/bot/${esc(b.id)}/"><img src="/assets/bots/casama-${esc(b.mascot)}.svg" alt="" width="44" height="44" loading="lazy"><span class="bot-tile-text"><span class="bot-tile-name">${esc(b.name)} <span class="bot-tile-job">${esc(b.job)}</span></span><span class="bot-tile-desc">${esc(b.description)}</span></span></a></li>`;
  return botGroups(checkBots(starterBots()))
    .map(([label, list]) => `<h2 id="${slugify(label)}">${esc(label)}</h2>\n<ul class="bot-tiles">\n${list.map(tile).join("\n")}\n</ul>`)
    .join("\n");
}

/** The same list as plain markdown, for the page's .md copy. */
const botDirectoryText = () =>
  botGroups(starterBots())
    .map(([label, list]) => `## ${label}\n\n${list.map((b) => `- **${b.name}** (${b.job}): ${b.description} https://gallery.casama.ai/i/bot/${b.id}/`).join("\n")}`)
    .join("\n\n");

// The home page shows a row of them and links to the page: these, in this order.
// Casama itself leads (D-391).
const HOME_BOTS = ["casama", "travel-planner", "coder", "daily-briefing", "writer", "data-analyst", "fitness-coach", "meal-planner"];

function starterBotsHtml() {
  const bots = checkBots(starterBots());
  const picks = HOME_BOTS.map((id) => bots.find((b) => b.id === id) ?? (fail(`HOME_BOTS: no starter bot ${id}`), null)).filter(Boolean);
  const chip = (b) =>
    `        <li><a class="bot-chip" href="/bots#${esc(b.id)}"><img src="/assets/bots/casama-${esc(b.mascot)}.svg" alt="" width="28" height="28" loading="lazy">${esc(b.name)}<span>${esc(b.job)}</span></a></li>`;
  return [
    `<div class="starter-bots">`,
    `      <ul class="bot-chips" aria-label="More starter bots">`,
    ...picks.map(chip),
    `      </ul>`,
    `      <a class="text-link" href="/bots">See all ${bots.length} starter bots</a>`,
    `    </div>`,
  ].join("\n");
}

const BOTS_OPEN = "<!-- starter-bots: written by site/build.mjs -->";
const BOTS_CLOSE = "<!-- /starter-bots -->";
function homeWithBots() {
  const a = home.indexOf(BOTS_OPEN);
  const b = home.indexOf(BOTS_CLOSE, a);
  if (a < 0 || b < 0) { fail(`index.html: couldn't find ${BOTS_OPEN}`); return home; }
  return `${home.slice(0, a + BOTS_OPEN.length)}\n    ${starterBotsHtml()}\n    ${home.slice(b)}`;
}

// The home page's FAQ is hand-written; its FAQPage data is written from it, between these markers.
const FAQ_SCHEMA_OPEN = "<!-- faq-schema: written by site/build.mjs from the #faq section -->";
const FAQ_SCHEMA_CLOSE = "<!-- /faq-schema -->";
function homeWithFaqSchema(text) {
  const a = text.indexOf(FAQ_SCHEMA_OPEN);
  const b = text.indexOf(FAQ_SCHEMA_CLOSE, a);
  const start = text.indexOf('id="faq"');
  const end = text.indexOf("</section>", start);
  if (a < 0 || b < 0 || start < 0 || end < 0) { fail(`index.html: couldn't find ${FAQ_SCHEMA_OPEN} or the #faq section`); return text; }
  const items = [...text.slice(start, end).matchAll(/<details class="qa"[^>]*>\s*<summary>([\s\S]*?)<\/summary>([\s\S]*?)<\/details>/g)].map((m) => ({ text: plainText(m[1]), answerText: plainText(m[2]) }));
  if (!items.length) fail("index.html: no questions in the #faq section");
  const json = JSON.stringify(faqSchema(items), null, 2).replace(/</g, "\\u003c").replace(/\n/g, "\n  ");
  return `${text.slice(0, a + FAQ_SCHEMA_OPEN.length)}\n  <script type="application/ld+json">\n  ${json}\n  </script>\n  ${text.slice(b)}`;
}

const org = { "@type": "Organization", name: product.name, url: `${SITE}/`, logo: `${SITE}/favicon.png`, sameAs: product.profiles };
const authors = { casama: org, oliver: { "@type": "Person", name: "Oliver Martinez", url: `${SITE}/about#oliver` } };

function structuredData(page, crumbs) {
  const { meta } = page;
  const data = [];
  if (crumbs.length > 1) {
    data.push({ "@context": "https://schema.org", "@type": "BreadcrumbList", itemListElement: crumbs.map((c, i) => ({ "@type": "ListItem", position: i + 1, name: c.name, item: `${SITE}${c.path}` })) });
  }
  if (meta.schema === "software") {
    data.push({ "@context": "https://schema.org", "@type": "SoftwareApplication", name: product.name, description: product.description, url: `${SITE}/`, applicationCategory: "BusinessApplication", operatingSystem: product.platforms.join(", "), license: product.license_url, offers: [{ "@type": "Offer", name: "Self-hosted", price: "0", priceCurrency: "USD" }, ...plans.plans.map((p) => ({ "@type": "Offer", name: `Casama Cloud ${p.name}`, price: String(p.monthly), priceCurrency: "USD" }))] });
  } else if (meta.schema === "about") {
    data.push({ "@context": "https://schema.org", "@type": "AboutPage", url: page.url, name: meta.title, mainEntity: { ...org, description: product.description, parentOrganization: { "@type": "Organization", name: product.maker, url: product.maker_url }, email: product.email } });
  } else if (meta.schema !== "faq" && !page.isIndex) {
    data.push({ "@context": "https://schema.org", "@type": page.section === "blog" ? "BlogPosting" : "Article", headline: meta.h1 ?? meta.title, description: meta.description, url: page.url, mainEntityOfPage: page.url, inLanguage: "en", datePublished: meta.published ?? meta.updated, dateModified: meta.updated, image: `${SITE}${shareFor(page).png}`, author: authors[meta.author ?? "casama"], publisher: org });
  }
  if (page.faq?.length) data.push(faqSchema(page.faq));
  return data.length ? `<script type="application/ld+json">${JSON.stringify(data).replace(/</g, "\\u003c")}</script>` : "";
}

function render(page) {
  const { meta } = page;
  for (const key of ["title", "description", "updated"]) if (!meta[key]) fail(`${page.file}: front matter needs "${key}"`);
  if ((meta.description ?? "").length > 170) fail(`${page.file}: description is ${meta.description.length} characters (keep it to 170)`);
  if ((meta.title ?? "").length > 65) fail(`${page.file}: title is ${meta.title.length} characters (keep it to 65)`);
  const { html } = markdown(page.body, tokensFor(page));
  const words = plainWords(html);
  if (!page.isIndex && words < MIN_WORDS) fail(`${page.file}: ${words} words (pages need ${MIN_WORDS})`);
  const sec = SECTIONS[page.section] ?? SECTIONS[""];
  const crumbs = [{ name: "Casama", path: "/" }];
  if (sec.crumb) crumbs.push({ name: sec.crumb, path: `/${page.section}/` });
  if (!page.isIndex || !sec.crumb) crumbs.push({ name: meta.crumb ?? meta.h1 ?? meta.title, path: page.path });
  const h1 = meta.h1 ?? meta.title;
  const byline = page.section === "blog" && meta.author === "oliver" ? `By <a href="/about#oliver">Oliver Martinez</a> · ` : "";
  const dates = meta.published && meta.published !== meta.updated ? `Published <time datetime="${meta.published}">${longDate(meta.published)}</time> · Updated <time datetime="${meta.updated}">${longDate(meta.updated)}</time>` : `Updated <time datetime="${meta.updated}">${longDate(meta.updated)}</time>`;
  const mdPath = `/${page.slug}.md`;
  const art = artFor(page);
  const share = shareFor(page);
  const shareImage = `${SITE}${share.png}`;
  const figure = art
    ? `<figure class="page-art"><picture>${art.webp ? `<source srcset="${art.webp}" type="image/webp">` : ""}<img src="${art.png}" width="1200" height="630" alt="${esc(art.alt)}" fetchpriority="high"></picture></figure>`
    : "";
  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  ${CSP}
  <title>${esc(meta.title)}</title>
  <meta name="description" content="${esc(meta.description)}">
  <meta name="theme-color" content="#ffffff" media="(prefers-color-scheme: light)">
  <meta name="theme-color" content="#1c1c1e" media="(prefers-color-scheme: dark)">
  <link rel="canonical" href="${page.url}">
  <link rel="icon" type="image/svg+xml" href="/assets/bots/casama-winky-animated.svg">
  <link rel="apple-touch-icon" href="/favicon.png">
  <link rel="alternate" type="text/markdown" href="${mdPath}">
  <link rel="alternate" type="text/plain" href="/llms.txt" title="llms.txt">
${page.section === "blog" ? '  <link rel="alternate" type="application/rss+xml" href="/blog/rss.xml" title="Casama blog">\n' : ""}  <meta property="og:type" content="${page.isIndex || !page.section ? "website" : "article"}">
  <meta property="og:site_name" content="Casama">
  <meta property="og:url" content="${page.url}">
  <meta property="og:title" content="${esc(meta.title)}">
  <meta property="og:description" content="${esc(meta.description)}">
  <meta property="og:image" content="${shareImage}">
  <meta property="og:image:width" content="1200">
  <meta property="og:image:height" content="630">${share.alt ? `\n  <meta property="og:image:alt" content="${esc(share.alt)}">` : ""}
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="${esc(meta.title)}">
  <meta name="twitter:description" content="${esc(meta.description)}">
  <meta name="twitter:image" content="${shareImage}">
  <link rel="preload" href="/assets/fonts/GoogleSans-Regular.woff2" as="font" type="font/woff2" crossorigin>
  <link rel="stylesheet" href="/site.css">
  <link rel="stylesheet" href="/pages.css">
  ${structuredData(page, crumbs)}
</head>
<body>
  <a class="skip-link" href="#main">Skip to content</a>

  ${HEADER}

  <main id="main" class="wrap page">
    <nav class="crumbs" aria-label="Breadcrumb">${crumbs.slice(0, -1).map((c) => `<a href="${c.path}">${esc(c.name)}</a>`).join("")}<span aria-current="page">${esc(crumbs.at(-1).name)}</span></nav>
    <article class="prose">
      <h1>${inline(h1)}</h1>
      ${meta.lead ? `<p class="lead">${inline(meta.lead)}</p>` : ""}
      <p class="page-meta">${byline}${dates}</p>
      ${figure}
${html}
${(page.section === "blog" && !page.isIndex) || page.slug === "changelog" ? newsBox("news-end") : ""}
    </article>
  </main>

  ${FOOTER}

  <script src="/site.js"></script>
  <script src="/assets/brand/casama-mark.js"></script>
${(page.scripts ?? []).map((src) => `  <script src="${src}"></script>\n`).join("")}</body>
</html>
`;
}

/** The page as clean markdown for AI agents: tokens become their tables as plain text. */
function twin(page) {
  const { meta } = page;
  const body = page.body.replace(/^\{\{\s*([a-z-]+)\s*(?::\s*(.*?))?\s*\}\}$/gm, (_all, name, args = "") => {
    const ids = args.split(",").map((s) => s.trim()).filter(Boolean);
    if (name === "compare") {
      const rowAt = ids.indexOf("rows");
      const list = (rowAt < 0 ? ids : ids.slice(0, rowAt)).map((id) => rivals.get(id)).filter(Boolean);
      const keys = rowAt < 0 ? ROWS.map((r) => r.key) : ids.slice(rowAt + 1);
      return [`| | Casama | ${list.map((r) => r.name).join(" | ")} |`, `|---|---|${list.map(() => "---").join("|")}|`, ...keys.map((key) => `| ${ROWS.find((r) => r.key === key)?.label} | ${casama[key] ?? ""} | ${list.map((r) => r.facts[key]?.value ?? "Not confirmed").join(" | ")} |`)].join("\n");
    }
    if (name === "bots") return botDirectoryText();
    if (name === "plans") return plans.plans.map((p) => `- **${p.name}**: ${p.price}. ${p.credits} of credits a month, ${p.bots} bots, ${p.computers}, ${p.storage} Library, ${p.seats}.`).join("\n");
    if (name === "sources") return ids.map((id) => rivals.get(id)).filter(Boolean).map((r) => `- ${r.name} (checked ${r.checked ?? rivalData.checked}): ${[...new Set(Object.values(r.facts).map((f) => f?.source).filter(Boolean))].join(", ")}`).join("\n");
    if (name === "best-at" || name === "limits") return (rivals.get(ids[0])?.[name === "best-at" ? "best_at" : "limits"] ?? []).map((b) => `- ${b.text}`).join("\n");
    if (name === "list") return pages.filter((p) => ids.includes(p.section) && !p.isIndex).map((p) => `- [${p.meta.h1 ?? p.meta.title}](${p.url}.md): ${p.meta.description}`).join("\n");
    if (name === "help") return faqGroups.map((g) => `## ${g.name}\n\n${faqText(g.items)}`).join("\n\n") + "\n\nStill stuck? Email support@casama.ai. Signed up? Open Help & support in the app for account help.";
    if (name === "faq") { const items = billingQuestions(); return `${items.length ? `## Plans and billing questions\n\n${faqText(items)}\n\n` : ""}More questions: ${SITE}/help`; }
    if (name === "newsletter") return `Sign up with the form at ${SITE}/newsletter. You'll get an email with a link to confirm.`;
    if (name === "cta") return `Start free at https://app.casama.ai, or run it on your own server: https://docs.casama.ai/self-hosting/`;
    return "";
  });
  return `# ${meta.h1 ?? meta.title}\n\n${meta.lead ? `${meta.lead}\n\n` : ""}Updated ${meta.updated}. Page: ${page.url}\n\n${body.trim().replace(/\]\((\/[^)\s]*)\)/g, `](${SITE}$1)`)}\n`;
}

// ---------------------------------------------------------------- changelog

function changelog() {
  const source = read(join(ROOT, "CHANGELOG.md"));
  const start = source.indexOf("\n## ");
  const body = source.slice(start).replace(/^\[[^\]]+\]:\s*\S+$/gm, "").replace(/^## \[([^\]]+)\](.*)$/gm, (_m, v, rest) => `## ${v === "Unreleased" ? "Coming next" : `Version ${v}`}${rest.replace(/^\s*-\s*/, " · ")}`);
  const releases = [...source.matchAll(/^## \[(\d[^\]]*)\]\s*-\s*(\d{4}-\d{2}-\d{2})/gm)].map((m) => ({ version: m[1], date: m[2] }));
  const updated = releases[0]?.date ?? TODAY;
  return {
    file: "CHANGELOG.md", section: "", slug: "changelog", path: "/changelog", url: `${SITE}/changelog`, isIndex: false, out: "changelog.html",
    meta: { title: "Casama changelog: what's new in every version", h1: "Changelog", crumb: "Changelog", description: "Every change to Casama's server, apps, CLI, SDK and MCP server, version by version, newest first.", updated, lead: "What changed in Casama, newest first. The server, apps, CLI, SDK and MCP server share one version number." },
    body, releases,
  };
}

// ---------------------------------------------------------------- feeds, sitemap, llms.txt

const rss = (title, link, description, items) => `<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom"><channel>
<title>${esc(title)}</title><link>${link}</link><description>${esc(description)}</description><language>en</language>
<atom:link href="${link.replace(/\/$/, "")}/rss.xml" rel="self" type="application/rss+xml"/>
${items.map((i) => `<item><title>${esc(i.title)}</title><link>${i.link}</link><guid>${i.link}</guid><pubDate>${new Date(`${i.date}T00:00:00Z`).toUTCString()}</pubDate><description>${esc(i.description)}</description></item>`).join("\n")}
</channel></rss>
`;

function sitemap(all) {
  const entries = [...staticPages.pages.map((p) => ({ loc: `${SITE}${p.path}`, lastmod: p.lastmod })), ...all.map((p) => ({ loc: p.url, lastmod: p.meta.updated }))];
  return `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
${entries.map((e) => `  <url><loc>${e.loc}</loc><lastmod>${e.lastmod}</lastmod></url>`).join("\n")}
</urlset>
`;
}

const LLMS_MARK = "## Pages on casama.ai";
function llms(all) {
  const file = join(HERE, "llms.txt");
  const current = read(file);
  const head = (current.includes(LLMS_MARK) ? current.slice(0, current.indexOf(LLMS_MARK)) : `${current.trimEnd()}\n\n`);
  const groups = Object.entries(SECTIONS).map(([key, sec]) => {
    const list = all.filter((p) => p.section === key && !(p.isIndex && key));
    if (!list.length) return "";
    return `### ${key ? sec.name : "About the product"}\n\n${list.map((p) => `- [${p.meta.h1 ?? p.meta.title}](${SITE}/${p.slug}.md): ${p.meta.description}`).join("\n")}`;
  }).filter(Boolean);
  return `${head}${LLMS_MARK}\n\nEach link is the page's markdown copy. Facts about other products carry the date they were checked.\n\n${groups.join("\n\n")}\n`;
}

// ---------------------------------------------------------------- checks on hand-written pages

/** The homepage is hand-written; its prices must match data/plans.json. */
function checkHome() {
  for (const p of plans.plans) {
    if (p.monthly > 0 && !new RegExp(`\\$${p.monthly}\\b`).test(home)) fail(`index.html doesn't show ${p.name}'s price $${p.monthly} from data/plans.json`);
    if (!new RegExp(`"name": "Casama Cloud ${p.name}", "price": "${p.monthly}"`).test(home)) fail(`index.html's structured data doesn't list Casama Cloud ${p.name} at ${p.monthly}`);
  }
}

// ---------------------------------------------------------------- run

const all = [...pages, changelog()];
if (process.argv.includes("--card-list")) {
  // For visuals/render-cards.mjs: what each page's share card says.
  console.log(JSON.stringify(all.map((p) => ({ slug: p.slug, section: p.section, title: p.meta.h1 ?? p.meta.title }))));
  process.exit(0);
}
const titles = new Map();
const outputs = [];
for (const page of all) {
  const html = render(page);
  const seen = titles.get(page.meta.title);
  if (seen) fail(`${page.file} and ${seen} share the title "${page.meta.title}"`);
  titles.set(page.meta.title, page.file);
  outputs.push([page.out, html], [`${page.slug}.md`, twin(page)]);
}
checkHome();
const newHome = homeWithFaqSchema(homeWithBots());
if (newHome !== home) {
  // --check is run before commits: an out-of-date list fails it, a build writes it.
  if (CHECK_ONLY) fail("index.html: the starter bot list or the FAQ's structured data is out of date (run node site/build.mjs)");
  outputs.push(["index.html", newHome]);
}

const posts = pages.filter((p) => p.section === "blog" && !p.isIndex).sort((a, b) => b.meta.published.localeCompare(a.meta.published));
outputs.push(["blog/rss.xml", rss("Casama blog", `${SITE}/blog/`, "What shipped in Casama and why, and numbers from running AI teammates.", posts.map((p) => ({ title: p.meta.h1 ?? p.meta.title, link: p.url, date: p.meta.published, description: p.meta.description })))]);
const log = all.at(-1);
outputs.push(["changelog/rss.xml", rss("Casama changelog", `${SITE}/changelog`, "Every Casama release.", log.releases.map((r) => ({ title: `Casama ${r.version}`, link: `${SITE}/changelog#version-${slugify(r.version)}-${r.date}`, date: r.date, description: `What changed in Casama ${r.version}.` })))]);
outputs.push(["sitemap.xml", sitemap(all)], ["llms.txt", llms(all)]);

if (problems.length) {
  console.error(`site/build.mjs: ${problems.length} problem${problems.length === 1 ? "" : "s"}\n${problems.map((p) => `  - ${p}`).join("\n")}`);
  process.exit(1);
}
if (!CHECK_ONLY) {
  // Clear the last build's section folders first, so a deleted content file doesn't leave its page behind.
  for (const key of Object.keys(SECTIONS)) if (key) rmSync(join(HERE, key), { recursive: true, force: true });
  rmSync(join(HERE, "changelog"), { recursive: true, force: true });
  for (const [path, body] of outputs) {
    const target = join(HERE, path);
    mkdirSync(dirname(target), { recursive: true });
    writeFileSync(target, body);
  }
}
console.log(`Site pages: ${all.length} pages${CHECK_ONLY ? " checked" : " written"} (${Object.entries(SECTIONS).map(([k, s]) => `${all.filter((p) => p.section === k).length} ${k ? s.name.toLowerCase() : "core"}`).join(", ")})`);
