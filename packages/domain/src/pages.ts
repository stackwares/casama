/**
 * Pages (D-092, D-119): how a bot's page is turned into the document the pages origin serves. The
 * bot's HTML stays as written; the data block, theme variables, `noindex` and the "updated" line
 * are added around it, and the origin sends a strict content security policy with it.
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
}

/** The served document: the bot's HTML with the head and foot additions. */
export function renderPage(p: RenderablePage) {
  const head = `<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="robots" content="noindex,nofollow"><style id="casama-theme">${THEME}</style><script type="application/json" id="${PAGE_DATA_ID}">${scriptJson(p.data)}</script>`;
  const foot = `<div id="casama-updated">Updated <time datetime="${p.updatedAt.toISOString()}">${escapeHtml(
    p.updatedAt.toISOString().slice(0, 16).replace("T", " "),
  )} UTC</time></div>`;
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
