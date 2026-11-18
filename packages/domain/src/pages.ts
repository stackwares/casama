/**
 * Pages (D-092, D-119): how a bot's page is turned into the document the pages origin serves. The
 * bot's HTML stays as written; the data block, theme variables, `noindex` and the "updated" line
 * are added around it. The same content security policy is sent as a header and written into the
 * document, so a local print (which never sees the header) still cannot reach the network.
 */

/** Inline scripts and styles only: no network requests, no forms that post out, no framing. */
export const PAGE_CSP = [
  "default-src 'none'",
  "script-src 'unsafe-inline'",
  "style-src 'unsafe-inline'",
  "img-src data: blob:",
  "font-src data:",
  "media-src data: blob:",
  "connect-src 'none'",
  "form-action 'none'",
  "frame-ancestors 'none'",
  "base-uri 'none'",
].join("; ");

/**
 * A page that takes input (D-279) may also send to its own origin, and only there: form responses
 * go to the page's collect address. Everything else stays as strict as PAGE_CSP.
 */
export const PAGE_CSP_COLLECT = PAGE_CSP.replace("connect-src 'none'", "connect-src 'self'");

/**
 * A page published from a folder (D-289) also loads its own files from its own origin: scripts,
 * styles, images, sounds and fonts under its assets address, and data it fetches from there. The
 * network beyond the pages origin stays closed.
 */
export const PAGE_CSP_ASSETS = [
  "default-src 'none'",
  "script-src 'self' 'unsafe-inline'",
  "style-src 'self' 'unsafe-inline'",
  "img-src 'self' data: blob:",
  "font-src 'self' data:",
  "media-src 'self' data: blob:",
  "connect-src 'self'",
  "form-action 'none'",
  "frame-ancestors 'none'",
  "base-uri 'self'",
].join("; ");

export const PAGE_HEADERS: Record<string, string> = {
  "content-security-policy": PAGE_CSP,
  "x-content-type-options": "nosniff",
  "referrer-policy": "no-referrer",
  "x-robots-tag": "noindex, nofollow",
  "cache-control": "private, no-store",
  "cross-origin-opener-policy": "same-origin",
  "permissions-policy": "camera=(), microphone=(), geolocation=(), payment=(), usb=()",
};

/** The id of the JSON block a page's script reads its data from. */
export const PAGE_DATA_ID = "casama-data";

/** How bots are told to build pages (in the pages.publish tool description). */
/** How bots are told to take input on a page published with collect (D-279). */
/** How bots are told to publish a site or game with files (D-289). */
export const PAGE_FOLDER_NOTE = `For a site or game with its own images, sounds, scripts or styles, put them in a folder with an index.html and pass folder instead of html: relative links (img/hero.png, js/game.js) work, and nothing outside Casama's page address can be loaded. Up to 300 files and 25 MB.`;

export const PAGE_COLLECT_NOTE = `With collect: true the page can take input: give a form the attribute data-casama-form (and optionally data-casama-sent="text to show after"), or call casama.submit({...}) from your script. Responses are stored; read them with pages.submissions. Never ask for passwords, card numbers or other secrets on a page.`;

export const PAGE_AUTHORING_NOTE = `One self-contained HTML document: inline <style> and <script> only (no external scripts, styles, fonts, images or requests; images as data: URLs). Read your data with JSON.parse(document.getElementById("${PAGE_DATA_ID}").textContent) so pages.update_data can change it without rewriting the layout. Use the CSS variables --k-bg, --k-fg, --k-muted, --k-accent, --k-surface and --k-font so the page follows light and dark mode. Make it work at phone width.`;

/** JSON that's safe inside a <script> element. */
export function scriptJson(value: unknown) {
  return JSON.stringify(value ?? {})
    .replaceAll("<", "\\u003c")
    .replaceAll(">", "\\u003e")
    .replaceAll("&", "\\u0026")
    .replaceAll(" ", "\\u2028")
    .replaceAll(" ", "\\u2029");
}

const escapeHtml = (s: string) => s.replace(/[&<>"']/g, (c) => `&#${c.charCodeAt(0)};`);

const THEME = `:root{--k-bg:#fbf8fd;--k-fg:#1d1b20;--k-muted:#625b71;--k-accent:#6750a4;--k-surface:#f3edf7;--k-font:system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;color-scheme:light dark}
@media (prefers-color-scheme:dark){:root{--k-bg:#141218;--k-fg:#e6e0e9;--k-muted:#cac4d0;--k-accent:#d0bcff;--k-surface:#211f26}}
#casama-updated{font:12px var(--k-font);color:var(--k-muted);text-align:center;padding:24px 16px}`;

export interface RenderablePage {
  title: string;
  html: string;
  data: unknown;
  updatedAt: Date;
  /** The address responses go to, for a page that takes input (D-279). */
  collect?: string;
  /** Where a visitor reports a public page (D-281). */
  reportUrl?: string;
  /** The folder its own files load from, for a page published from a folder (D-289). */
  assetsBase?: string;
}

/**
 * The small runtime a collecting page gets: `casama.submit(object)` sends a response, and any
 * <form data-casama-form> sends its fields, then shows its data-casama-sent text (D-279).
 */
const collectScript = (endpoint: string) => `<script>(function(){var u=${scriptJson(endpoint)};
window.casama=window.casama||{};
window.casama.submit=function(d){return fetch(u,{method:"POST",headers:{"content-type":"application/json"},body:JSON.stringify(d||{}),credentials:"same-origin"}).then(function(r){if(!r.ok)throw new Error("Couldn't send ("+r.status+")");return r.json()})};
document.addEventListener("submit",function(e){var f=e.target;if(!f||!f.hasAttribute||!f.hasAttribute("data-casama-form"))return;e.preventDefault();var o={};new FormData(f).forEach(function(v,k){if(typeof v!=="string")return;if(k in o){o[k]=[].concat(o[k],v)}else{o[k]=v}});var b=f.querySelector("[type=submit]");if(b)b.disabled=true;window.casama.submit(o).then(function(){var t=f.getAttribute("data-casama-sent")||"Thanks, it's sent.";var p=document.createElement("p");p.textContent=t;p.setAttribute("role","status");f.replaceWith(p)}).catch(function(err){if(b)b.disabled=false;alert(err.message)})},true)})();</script>`;

/** The served document: the bot's HTML with the head and foot additions. */
export function renderPage(p: RenderablePage) {
  // First in <head>, before anything the bot wrote. A later policy of the bot's own still applies
  // as well: a browser enforces every policy, so this one keeps blocking the network.
  const csp = p.assetsBase ? PAGE_CSP_ASSETS : p.collect ? PAGE_CSP_COLLECT : PAGE_CSP;
  const base = p.assetsBase ? `<base href="${escapeHtml(p.assetsBase)}">` : "";
  const head = `${base}<meta http-equiv="Content-Security-Policy" content="${csp}"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="robots" content="noindex,nofollow"><style id="casama-theme">${THEME}</style><script type="application/json" id="${PAGE_DATA_ID}">${scriptJson(p.data)}</script>${p.collect ? collectScript(p.collect) : ""}`;
  const foot = `<div id="casama-updated">Updated <time datetime="${p.updatedAt.toISOString()}">${escapeHtml(
    p.updatedAt.toISOString().slice(0, 16).replace("T", " "),
  )} UTC</time>${p.reportUrl ? ` · <a href="${escapeHtml(p.reportUrl)}" style="color:inherit">Report</a>` : ""}</div>`;
  let html = p.html;
  // A fragment gets a full document around it.
  if (!/<html[\s>]/i.test(html))
    html = `<!doctype html><html><head><title>${escapeHtml(p.title)}</title></head><body>${html}</body></html>`;
  if (!/<head[\s>]/i.test(html)) html = html.replace(/<html[^>]*>/i, (m) => `${m}<head></head>`);
  html = html.replace(/<head[^>]*>/i, (m) => `${m}${head}`);
  html = /<\/body>/i.test(html)
    ? html.replace(/<\/body>(?![\s\S]*<\/body>)/i, `${foot}</body>`)
    : `${html}${foot}`;
  return html;
}
