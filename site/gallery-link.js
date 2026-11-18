/**
 * https://casama.ai/gallery/<type>/<id> is a gallery item's share link (D-184). With the app installed
 * the phone opens it there; anywhere else it goes to the item's own page on the gallery
 * (https://gallery.casama.ai/i/<type>/<id>/, D-315), which shows it with Open in Casama and Get Casama.
 * https://casama.ai/gallery goes to the gallery itself.
 *
 * https://casama.ai/i/<code> is a friend's invite link (D-211): who invited you, the code to enter
 * after signing up, and a way to open or get the app. With the app installed the phone opens it there.
 *
 * https://casama.ai/open/<route> is how links in emails and invites open the app (D-326). With the
 * app installed, iOS, Android and the Mac App Store build open <route> there and never ask this
 * worker. Here, a Mac gets a page offering the Mac app (casama://app/<route>) or the browser; other
 * computers and phones go straight to the web app, which reads /open/<route> itself (so a link
 * opened signed out still ends there after signing in). Windows and Linux builds don't register
 * casama:// links, so only a Mac is offered the app.
 *
 * https://casama.ai/get is the one link behind the download QR code (D-377): an iPhone or iPad goes
 * to the App Store, an Android phone to Google Play, anything else to https://casama.ai/download.
 * https://casama.ai/get/<platform> is where each download button on the site leads, so a store
 * listing or release file changes here, in GET_LINKS, and nowhere else. /get/start is "Start free":
 * the web app, or the phone's app store once STORES_LIVE is on.
 *
 * /newsletter/* is the monthly email's sign-up and double opt-in (D-404, site/newsletter.js).
 *
 * /assets/film/* (D-390) comes here too, only to answer byte-range requests: static assets always
 * send the whole file with 200, and Safari won't play a video that way.
 */
import { handleNewsletter } from "./newsletter.js";

const TYPES = "theme|scheme|wallpaper|skill|app|bot|routine|plugin|set";
const GALLERY = "https://gallery.casama.ai";
const API = "https://api.casama.ai";
const WEB_APP = "https://app.casama.ai";
const DOWNLOAD_PAGE = "https://casama.ai/download";

// Where each download button goes (D-377). The App Store, Google Play and Firefox addresses are
// the listings' official ones (live once each listing is public). The Chrome Web Store and Edge
// items don't have ids yet, and no Windows or Linux build is published, so those point at the
// extension guide and the releases page: swap in the real address here when each one exists.
const APP_STORE = "https://apps.apple.com/app/id6833509960"; // "Casama AI": iPhone, iPad and Mac
const PLAY = "https://play.google.com/store/apps/details?id=ai.casama.app";
const RELEASES_REPO = "stackwares/casama-releases";
const RELEASES = `https://github.com/${RELEASES_REPO}/releases/latest`;
const EXTENSION_DOCS = "https://docs.casama.ai/guide/chrome";
export const GET_LINKS = {
  ios: APP_STORE,
  android: PLAY,
  mac: `${APP_STORE}?platform=mac`,
  // The newest build comes from the update feed (FEEDS); this one is used when the feed can't be read.
  "mac-dmg": `https://github.com/${RELEASES_REPO}/releases/download/v0.1.0/Casama-0.1.0-macos.dmg`,
  windows: RELEASES,
  "windows-zip": RELEASES,
  linux: RELEASES,
  "linux-arm64": RELEASES,
  chrome: EXTENSION_DOCS,
  edge: `${EXTENSION_DOCS}#edge-and-firefox`,
  firefox: "https://addons.mozilla.org/firefox/addon/casama/",
  web: WEB_APP,
};
// Downloads that follow the desktop apps' update feeds, which scripts/publish-desktop-release.sh
// moves to every new release, so these links never need editing after a release.
const FEEDS = {
  "mac-dmg": `https://raw.githubusercontent.com/${RELEASES_REPO}/main/appcast-macos.xml`,
  windows: `https://raw.githubusercontent.com/${RELEASES_REPO}/main/appcast-windows.xml`,
};
// "Start free" on casama.ai goes to /get/start. Phones and tablets go to their app store once this is
// true; until the listings are public everyone goes to the web app. Computers always do.
export const STORES_LIVE = false;

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    if (url.pathname === "/b") return countVisit(request, env, ctx);
    if (url.pathname.startsWith("/newsletter/")) return handleNewsletter(request, env, url);
    if (url.pathname.startsWith("/assets/film/")) return servePartial(request, env);
    if (url.pathname === "/open" || url.pathname.startsWith("/open/")) return openLink(request, url);
    if (url.pathname === "/get" || url.pathname.startsWith("/get/")) return getLink(request, url, env, ctx);
    const invite = /^\/i\/([0-9A-Za-z]{6})\/?$/.exec(url.pathname);
    if (invite) {
      // The funnel step only, never the code (D-398).
      trackFunnel(request, env, ctx, "invite_open");
      return invitePage(invite[1].toUpperCase());
    }
    if (/^\/gallery\/?$/.test(url.pathname)) return Response.redirect(`${GALLERY}/`, 302);
    const match = new RegExp(`^/gallery/(${TYPES})/([a-z0-9][a-z0-9-]{0,62})/?$`).exec(url.pathname);
    if (!match) return new Response("Not found", { status: 404 });
    trackFunnel(request, env, ctx, "gallery_open", { item_type: match[1] });
    return Response.redirect(`${GALLERY}/i/${match[1]}/${match[2]}/`, 302);
  },
};

/** /open/<route>: the Mac app or the web app (see the top of this file). */
export function openLink(request, url) {
  // The route, with one leading slash and no trailing one; "" is home.
  const route = url.pathname
    .slice("/open".length)
    .replace(/^\/+/, "/")
    .replace(/\/+$/, "");
  const web = `${WEB_APP}/open${route}${url.search}`;
  const headers = { "cache-control": "private, no-store", "x-robots-tag": "noindex" };
  if (!isMacBrowser(request.headers.get("user-agent") ?? "")) {
    return new Response(null, { status: 302, headers: { ...headers, location: web } });
  }
  const app = `casama://app${route || "/bots"}${url.search}`;
  return new Response(openPage(app, web), {
    status: 200,
    headers: {
      ...headers,
      "content-type": "text/html; charset=utf-8",
      "content-security-policy":
        "default-src 'none'; style-src 'unsafe-inline'; script-src 'self' 'unsafe-inline'; connect-src 'self'; font-src 'self'; img-src 'self' data:; frame-ancestors 'none'",
    },
  });
}

/** /get and /get/<platform>: a store, a release or the download page (see the top of this file). */
export async function getLink(request, url, env, ctx) {
  const platform = url.pathname.slice("/get".length).replace(/^\/+|\/+$/g, "").toLowerCase();
  let location = DOWNLOAD_PAGE;
  const ua = request.headers.get("user-agent") ?? "";
  if (platform === "start") {
    location = WEB_APP;
    if (STORES_LIVE && /iPhone|iPad|iPod/.test(ua)) location = GET_LINKS.ios;
    else if (STORES_LIVE && /Android/.test(ua)) location = GET_LINKS.android;
  } else if (platform) {
    location = Object.hasOwn(GET_LINKS, platform) ? GET_LINKS[platform] : DOWNLOAD_PAGE;
    if (Object.hasOwn(FEEDS, platform)) location = (await latestDownload(FEEDS[platform])) ?? location;
  } else {
    if (/iPhone|iPad|iPod/.test(ua)) location = GET_LINKS.ios;
    else if (/Android/.test(ua)) location = GET_LINKS.android;
  }
  // Funnel (D-398): the click itself, and where the visitor came from carried on to the web app and
  // Google Play, so their first visit or install is credited to the page that sent them.
  const campaign = campaignFor(refererPage(request));
  location = withAttribution(location, campaign);
  if (platform === "start") trackFunnel(request, env, ctx, "start_click", { via: "get" });
  else if (platform)
    trackFunnel(request, env, ctx, "download_click", { platform: Object.hasOwn(GET_LINKS, platform) ? platform : "other" });
  else trackFunnel(request, env, ctx, "qr_open");
  // The bare /get and /get/start depend on the device asking, so no shared cache may keep one answer for everyone.
  return new Response(null, {
    status: 302,
    headers: { location, "cache-control": "private, no-store", vary: "user-agent", "x-robots-tag": "noindex" },
  });
}

/** The newest file in a Sparkle update feed (its first enclosure), or null when it can't be read. */
export async function latestDownload(feed) {
  try {
    const res = await fetch(feed, { cf: { cacheTtl: 300, cacheEverything: true } });
    if (!res.ok) return null;
    const match = /<enclosure[^>]*\surl="(https:\/\/github\.com\/[^"]+)"/.exec(await res.text());
    return match ? match[1] : null;
  } catch {
    return null;
  }
}

/** A Mac's browser (iPads asking for desktop pages say Macintosh too; they get the same choice). */
export function isMacBrowser(ua) {
  return /Macintosh|Mac OS X/.test(ua) && !/iPhone|iPod|Android/.test(ua);
}

function openPage(app, web) {
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex">
<title>Open in Casama</title>
<link rel="icon" type="image/svg+xml" href="/assets/bots/casama-winky-animated.svg">
<style>${PAGE_CSS}</style>
</head>
<body>
<main>
  <a class="logo" href="https://casama.ai" aria-label="Casama home"><span data-casama-mark></span>Casama</a>
  <h1>Open in Casama</h1>
  <p>Have the Casama app on this Mac? Open this there, or carry on in your browser.</p>
  <a class="btn primary" id="app" href="${esc(app)}">Open in the app</a>
  <a class="btn" id="web" href="${esc(web)}">Continue in browser</a>
  <label class="remember"><input type="checkbox" id="remember"> Always do this on this Mac</label>
  <p class="small">No app yet? <a href="https://casama.ai/download#mac">Get Casama for Mac</a>.</p>
</main>
<script>
(function () {
  var KEY = "casama.openWith";
  var app = document.getElementById("app"), web = document.getElementById("web");
  var remember = document.getElementById("remember");
  function get() { try { return localStorage.getItem(KEY); } catch (e) { return null; } }
  function set(v) { try { localStorage.setItem(KEY, v); } catch (e) {} }
  var saved = get();
  if (saved === "web") { location.replace(web.href); return; }
  if (saved === "app") { location.href = app.href; }
  app.addEventListener("click", function () { if (remember.checked) set("app"); });
  web.addEventListener("click", function () { if (remember.checked) set("web"); });
})();
</script>
<script src="/assets/brand/casama-mark.js"></script>
</body>
</html>`;
}

async function invitePage(code) {
  let preview = null;
  try {
    const res = await fetch(`${API}/v1/referral/preview?code=${code}`, { cf: { cacheTtl: 300 } });
    if (res.ok) preview = await res.json();
  } catch {
    // The page still shows the code and the app links when the API is briefly unreachable.
  }
  const name = preview?.inviter_name ?? "";
  const who = name ? `${name} invited you to Casama` : "You're invited to Casama";
  const bonus = Number(preview?.welcome_usd ?? 0);
  const dollars = Number.isInteger(bonus) ? `$${bonus}` : `$${bonus.toFixed(2)}`;
  const about =
    bonus > 0
      ? `AI teammates that get things done for you, each on its own computer. Sign up with this code and get ${dollars} of free usage after your first chat.`
      : "AI teammates that get things done for you, each on its own computer. Sign up, then enter the code so your friend gets the credit.";
  const html = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex">
<title>${esc(who)}</title>
<meta name="description" content="${esc(about)}">
<meta property="og:title" content="${esc(who)}">
<meta property="og:description" content="${esc(about)}">
<meta property="og:image" content="https://casama.ai/og-image.png">
<link rel="icon" type="image/svg+xml" href="/assets/bots/casama-winky-animated.svg">
<style>${PAGE_CSS}</style>
</head>
<body>
<main>
  <a class="logo" href="https://casama.ai" aria-label="Casama home"><span data-casama-mark></span>Casama</a>
  <h1>${esc(who)}</h1>
  <p>${esc(about)}</p>
  <div class="code" aria-label="Invite code">${esc(code)}</div>
  <a class="btn primary" href="casama://app/i/${esc(code)}">Open in Casama</a>
  <a class="btn" href="https://casama.ai/download">Get Casama</a>
  <p class="small">Already have the app? It opens this invite by itself. Otherwise, after signing up go to Settings → Invite friends and enter the code within a week.</p>
</main>
<script src="/assets/brand/casama-mark.js"></script>
</body>
</html>`;
  return new Response(html, {
    status: 200,
    headers: { "content-type": "text/html; charset=utf-8", "cache-control": "public, max-age=300" },
  });
}

/** The look shared by the pages this worker serves (casama.link's, D-319). */
const PAGE_CSS = `
  @font-face { font-family: "Google Sans"; src: url("/assets/fonts/GoogleSans-Regular.woff2") format("woff2"); font-weight: 400; font-display: swap; }
  @font-face { font-family: "Google Sans"; src: url("/assets/fonts/GoogleSans-Bold.woff2") format("woff2"); font-weight: 700; font-display: swap; }
  @font-face { font-family: "Libre Baskerville"; src: url("/assets/fonts/LibreBaskerville-Bold.woff2") format("woff2"); font-weight: 700; font-display: swap; }
  @font-face { font-family: "JetBrains Mono"; src: url("/assets/fonts/JetBrainsMono-Regular.woff2") format("woff2"); font-weight: 400; font-display: swap; }
  :root { --bg:#ffffff; --bg-2:#f4f4f6; --card:#f7f7f9; --ink:#1d1b20; --muted:#5d5a63; --line:#e3e2e7; --accent:#7a3fa8; --accent-ink:#fff; color-scheme: light; }
  @media (prefers-color-scheme: dark) { :root { --bg:#1c1c1e; --bg-2:#2a2a2d; --card:#242427; --ink:#f2f1f4; --muted:#b4b1b9; --line:#38383c; --accent:#d9b6f7; --accent-ink:#25102f; color-scheme: dark; } }
  * { box-sizing: border-box; }
  body { margin: 0; min-height: 100vh; display: grid; place-items: center; padding: 16px; background: var(--bg); color: var(--ink); font: 400 17px/1.55 "Google Sans", -apple-system, BlinkMacSystemFont, "Segoe UI", system-ui, sans-serif; -webkit-font-smoothing: antialiased; }
  main { width: 100%; max-width: 440px; background: var(--card); border: 1px solid var(--line); border-radius: 22px; padding: 32px 24px; text-align: center; }
  .logo { display: inline-flex; align-items: center; gap: 10px; font: 700 22px/1 "Libre Baskerville", Georgia, serif; letter-spacing: -0.03em; text-decoration: none; color: inherit; }
  [data-casama-mark] { display: block; flex: none; width: 34px; height: 34px; contain: layout paint style; opacity: 0; transition: opacity .4s ease; }
  [data-casama-mark].is-ready { opacity: 1; }
  h1 { font-size: 30px; font-weight: 700; line-height: 1.1; letter-spacing: -0.04em; margin: 22px 0 10px; }
  p { margin: 0 0 18px; color: var(--muted); }
  .code { display: inline-block; margin: 4px 0 22px; padding: 12px 20px; border-radius: 16px; background: var(--bg); border: 1.5px solid var(--line); font: 400 26px/1 "JetBrains Mono", ui-monospace, SFMono-Regular, Menlo, monospace; letter-spacing: 6px; user-select: all; }
  .btn { display: flex; align-items: center; justify-content: center; min-height: 52px; padding: 0 26px; border-radius: 999px; text-decoration: none; font-weight: 700; font-size: 17px; background: var(--bg-2); color: var(--ink); margin-top: 10px; transition: transform .14s cubic-bezier(.16,1,.3,1), filter .2s ease; }
  .btn.primary { background: var(--accent); color: var(--accent-ink); }
  .btn:active { transform: scale(.96); }
  @media (hover: hover) and (pointer: fine) { .btn:hover { filter: brightness(1.08); } }
  :focus-visible { outline: 3px solid var(--accent); outline-offset: 3px; }
  .small { font-size: 15px; margin: 18px 0 0; }
  .remember { display: flex; align-items: center; justify-content: center; gap: 8px; margin: 16px 0 0; font-size: 15px; color: var(--muted); cursor: pointer; }
  .remember input { width: 18px; height: 18px; accent-color: var(--accent); }
  .small a { color: var(--accent); }
`;

/**
 * A static file with byte ranges (D-390). Workers static assets ignore Range and send the whole file
 * with 200, which Safari won't play as video. This asks ASSETS for the whole file and sends back
 * only the requested bytes with 206, streamed so the file is never held in memory.
 *
 * ASSETS doesn't say how long a file is, and a 206 has to. So the first range request for a file
 * reads it through once, counting bytes and keeping none, and the size is remembered by path and
 * ETag (a new upload has a new ETag) for as long as this isolate lives.
 */
const SIZES = new Map();

async function servePartial(request, env) {
  const headers = new Headers(request.headers);
  const range = headers.get("Range");
  headers.delete("Range");
  headers.delete("If-Range");
  const fetchWhole = () => env.ASSETS.fetch(new Request(request.url, { method: request.method, headers }));
  const res = await fetchWhole();
  const out = new Headers(res.headers);
  out.set("Accept-Ranges", "bytes");
  const whole = () => new Response(res.body, { status: res.status, headers: out });
  if (request.method !== "GET" || res.status !== 200 || !res.body || !range || res.headers.has("Content-Encoding")) return whole();
  const m = /^bytes=(\d*)-(\d*)$/.exec(range.trim());
  if (!m || (m[1] === "" && m[2] === "")) return whole();
  const key = `${new URL(request.url).pathname} ${res.headers.get("ETag")}`;
  let body = res.body;
  let size = Number(res.headers.get("Content-Length")) || SIZES.get(key);
  if (!size) {
    size = await countBytes(body);
    if (SIZES.size > 50) SIZES.clear();
    SIZES.set(key, size);
    body = null;
  }
  let start;
  let end;
  if (m[1] === "") {
    start = Math.max(0, size - Number(m[2]));
    end = size - 1;
  } else {
    start = Number(m[1]);
    end = m[2] === "" ? size - 1 : Math.min(Number(m[2]), size - 1);
  }
  if (start >= size || start > end) {
    if (body) body.cancel().catch(() => {});
    return new Response(null, { status: 416, headers: { "Content-Range": `bytes */${size}`, "Accept-Ranges": "bytes" } });
  }
  if (!body) body = (await fetchWhole()).body;
  const length = end - start + 1;
  out.set("Content-Range", `bytes ${start}-${end}/${size}`);
  out.set("Content-Length", String(length));
  const part = byteSlice(body, start, end);
  if (typeof FixedLengthStream === "function") {
    const fixed = new FixedLengthStream(length);
    part.pipeTo(fixed.writable).catch(() => {});
    return new Response(fixed.readable, { status: 206, headers: out });
  }
  return new Response(part, { status: 206, headers: out });
}

/** How many bytes a stream holds, read to the end without keeping any. */
async function countBytes(body) {
  const reader = body.getReader();
  let total = 0;
  for (;;) {
    const { done, value } = await reader.read();
    if (done) return total;
    total += value.byteLength;
  }
}

/** Bytes start..end (inclusive) of a stream; stops reading once it has them. */
function byteSlice(body, start, end) {
  const reader = body.getReader();
  let pos = 0;
  return new ReadableStream({
    async pull(controller) {
      for (;;) {
        const { done, value } = await reader.read();
        if (done) return controller.close();
        const from = pos;
        pos += value.byteLength;
        if (pos <= start) continue;
        controller.enqueue(value.subarray(Math.max(0, start - from), Math.min(value.byteLength, end + 1 - from)));
        if (pos > end) {
          reader.cancel().catch(() => {});
          controller.close();
        }
        return;
      }
    },
    cancel(reason) {
      return reader.cancel(reason);
    },
  });
}

function esc(value) {
  return String(value).replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c]);
}

/**
 * https://casama.ai/b counts a page view (docs/SEO-PLAN.md §10.5), so we can tell whether search
 * engines and AI assistants send anyone. site.js posts the page, the host of the site the visitor
 * came from and any utm_source. One row goes to Workers Analytics Engine: the page, the kind of
 * source, the site and the day. No cookie, no IP address and no full referring address. The docs,
 * the gallery and casama.link post here too, with `h` naming the site (D-398).
 */
const SOURCES = [
  ["chatgpt", /(^|\.)(chatgpt\.com|chat\.openai\.com)$/],
  ["perplexity", /(^|\.)perplexity\.ai$/],
  ["claude", /(^|\.)claude\.ai$/],
  ["gemini", /^gemini\.google\.com$/],
  ["copilot", /(^|\.)copilot\.microsoft\.com$/],
  ["other-ai", /(^|\.)(grok\.com|x\.ai|meta\.ai|you\.com|phind\.com|kagi\.com|duck\.ai|mistral\.ai|deepseek\.com)$/],
  ["google", /(^|\.)google\.[a-z.]+$/],
  ["bing", /(^|\.)bing\.com$/],
  ["search", /(^|\.)(duckduckgo\.com|search\.brave\.com|yandex\.[a-z.]+|ecosia\.org|startpage\.com|yahoo\.com)$/],
  ["github", /(^|\.)github\.com$/],
  ["community", /(^|\.)(reddit\.com|news\.ycombinator\.com|producthunt\.com|dev\.to|x\.com|twitter\.com|t\.co|linkedin\.com|youtube\.com)$/],
  ["casama", /(^|\.)(casama\.ai|casama\.link)$/],
];
export function visitSource(host, utm) {
  const from = String(utm || host || "").toLowerCase().replace(/^www\./, "");
  if (!from) return "direct";
  for (const [name, pattern] of SOURCES) if (pattern.test(from)) return name;
  return "other";
}
async function countVisit(request, env, ctx) {
  // docs.casama.ai, gallery.casama.ai and casama.link count here too (D-398).
  const origin = request.headers.get("origin") || "";
  const headers = { "cache-control": "no-store" };
  if (Object.hasOwn(SITE_ORIGINS, origin)) headers["access-control-allow-origin"] = origin;
  if (request.method !== "POST") return new Response(null, { status: 405, headers: { ...headers, allow: "POST" } });
  let body = {};
  try {
    body = JSON.parse((await request.text()).slice(0, 600));
  } catch {
    return new Response(null, { status: 204, headers });
  }
  const site = siteKey(body.h);
  if (site === null) return new Response(null, { status: 204, headers });
  const page = String(body.p || "/").slice(0, 120).replace(/[?#].*$/, "");
  if (body.e !== undefined) {
    // A beacon event (film_play, copy_install, plan_click, start_click), only from the closed list.
    const event = beaconEvent(body.e, body.d);
    if (event) trackFunnel(request, env, ctx, event.name, event.params, { site, page });
    return new Response(null, { status: 204, headers });
  }
  const source = visitSource(String(body.r || "").slice(0, 80), String(body.u || "").slice(0, 80));
  env?.VISITS?.writeDataPoint({ blobs: [source, page, site || "casama.ai"], doubles: [1], indexes: [source] });
  const ga = sendToGoogleAnalytics(request, env, { page, site, host: String(body.r || "").slice(0, 80), utm: String(body.u || "").slice(0, 80), source });
  if (ga) ctx?.waitUntil?.(ga);
  return new Response(null, { status: 204, headers });
}

/**
 * The same anonymous count, forwarded to Google Analytics 4 from here with the Measurement
 * Protocol (D-396), so no Google script or cookie ever reaches the visitor. Since D-398 each hit
 * carries a daily visitor id (visitorIds below), so GA4 can line one visit's page views and clicks up
 * into a funnel; it changes every day and can't be traced back. The country comes from Cloudflare
 * and no IP address is sent. Skipped when GA_API_SECRET isn't set (local runs, self-hosted copies).
 */
const GA_MEASUREMENT_ID = "G-4GVRF0K324";
export function gaPayload({ page, host, utm, source, country, mobile, rand = Math.random, ids, site = "", event, eventParams }) {
  const id = () => String(Math.floor(rand() * 2147483647));
  let params;
  if (event) {
    // A funnel event (D-398): its own params, and the page it happened on when known.
    params = { ...eventParams, session_id: ids?.sessionId ?? id(), engagement_time_msec: 1 };
    if (page) {
      params.page_location = `https://${SITE_HOSTS[site] ?? "casama.ai"}${page.startsWith("/") ? page : "/"}`;
      params.site = site || "casama.ai";
    }
  } else {
    const location = new URL(`https://${SITE_HOSTS[site] ?? "casama.ai"}${page.startsWith("/") ? page : "/"}`);
    if (utm) location.searchParams.set("utm_source", utm);
    params = { page_location: location.toString(), page_title: location.pathname, visit_source: source, site: site || "casama.ai", session_id: ids?.sessionId ?? id(), engagement_time_msec: 1 };
    if (host) params.page_referrer = `https://${host}/`;
  }
  const payload = { client_id: ids?.clientId ?? `${id()}.${id()}`, events: [{ name: event || "page_view", params }] };
  if (country && /^[A-Z]{2}$/.test(country)) payload.user_location = { country_id: country };
  payload.device = { category: mobile ? "mobile" : "desktop" };
  return payload;
}
async function sendToGoogleAnalytics(request, env, visit) {
  if (!env?.GA_API_SECRET) return null;
  const ua = request.headers.get("user-agent") || "";
  const ids = await visitorIds(env.GA_API_SECRET, new Date(), request.headers.get("cf-connecting-ip") || "", ua);
  const payload = gaPayload({ ...visit, ids, country: request.cf?.country, mobile: /Mobi|Android|iPhone|iPad/i.test(ua) });
  const endpoint = `https://www.google-analytics.com/mp/collect?measurement_id=${GA_MEASUREMENT_ID}&api_secret=${encodeURIComponent(env.GA_API_SECRET)}`;
  return fetch(endpoint, { method: "POST", body: JSON.stringify(payload) }).catch(() => {});
}

/**
 * Funnels without cookies (D-398). A visitor's GA4 client and session ids come from an HMAC of the
 * UTC day, the IP address and the browser's user agent, keyed with the GA secret: the same browser
 * keeps one id for the day (so page views, clicks and the hand-off line up into a funnel) and gets a
 * new one at midnight UTC. Nothing is stored and the IP address never leaves this Worker.
 */
export async function visitorIds(secret, date, ip, ua) {
  const enc = new TextEncoder();
  const key = await crypto.subtle.importKey("raw", enc.encode(secret), { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  const day = date.toISOString().slice(0, 10);
  const mac = new DataView(await crypto.subtle.sign("HMAC", key, enc.encode(`${day}|${ip}|${ua}`)));
  return {
    clientId: `${mac.getUint32(0) >>> 1}.${mac.getUint32(4) >>> 1}`,
    sessionId: String(mac.getUint32(8) >>> 1),
  };
}

/** Sends a funnel event to GA4 in the background; never delays the answer. */
function trackFunnel(request, env, ctx, name, params = {}, at = refererPage(request)) {
  if (!env?.GA_API_SECRET) return;
  const visit = { event: name, eventParams: params, page: at?.page, site: at?.site ?? "" };
  const ga = sendToGoogleAnalytics(request, env, visit);
  if (ga) ctx?.waitUntil?.(ga);
}

/** The sites that count through this Worker: casama.ai is "", the others post `h`. */
const SITE_HOSTS = { "": "casama.ai", docs: "docs.casama.ai", gallery: "gallery.casama.ai", link: "casama.link" };
const SITE_ORIGINS = { "https://docs.casama.ai": "docs", "https://gallery.casama.ai": "gallery", "https://casama.link": "link" };
/** `h` from a beacon: "" for casama.ai, a known site key, or null for anything else (dropped). */
export function siteKey(h) {
  if (h === undefined || h === null || h === "") return "";
  return typeof h === "string" && h !== "" && Object.hasOwn(SITE_HOSTS, h) ? h : null;
}

/** The page on one of our sites that sent this request (Referer), path only; null otherwise. */
export function refererPage(request) {
  try {
    const ref = new URL(request.headers.get("referer") || "");
    if (ref.protocol !== "https:") return null;
    const host = ref.hostname.replace(/^www\./, "");
    const site = Object.keys(SITE_HOSTS).find((k) => SITE_HOSTS[k] === host);
    if (site === undefined) return null;
    return { site, page: ref.pathname.slice(0, 120) };
  } catch {
    return null;
  }
}

/** utm_campaign for a hand-off: the sending page as a slug ("home", "pricing", "docs-guide-chrome"), or "direct". */
export function campaignFor(at) {
  if (!at) return "direct";
  const path = at.page.replace(/^\/+|\/+$/g, "").replace(/\.html$/, "").replace(/[^a-z0-9]+/gi, "-").toLowerCase();
  return [at.site, path || (at.site ? "" : "home")].filter(Boolean).join("-").slice(0, 100) || "home";
}

/** The web app and Google Play learn where the visitor came from (App Store links stay as they are). */
export function withAttribution(location, campaign) {
  const utm = `utm_source=casama.ai&utm_medium=website&utm_campaign=${encodeURIComponent(campaign)}`;
  if (location === WEB_APP || location.startsWith(`${WEB_APP}/`) || location.startsWith(`${WEB_APP}?`)) {
    const u = new URL(location);
    for (const [k, v] of new URLSearchParams(utm)) u.searchParams.set(k, v);
    return u.toString();
  }
  if (location.startsWith(PLAY)) return `${location}&referrer=${encodeURIComponent(utm)}`;
  return location;
}

/** Beacon events site.js may send, with their allowed params and values. Anything else is dropped. */
const BEACON_EVENTS = {
  film_play: {},
  copy_install: {},
  plan_click: { plan: ["free", "plus", "pro", "max", "self_hosted"] },
  start_click: { via: ["link"] },
};
export function beaconEvent(name, data) {
  if (typeof name !== "string" || !Object.hasOwn(BEACON_EVENTS, name)) return null;
  const allowed = BEACON_EVENTS[name];
  const params = {};
  for (const [key, values] of Object.entries(allowed)) {
    const v = data && typeof data === "object" ? String(data[key] ?? "").slice(0, 100) : "";
    if (!values.includes(v)) return null;
    params[key] = v;
  }
  return { name, params };
}
