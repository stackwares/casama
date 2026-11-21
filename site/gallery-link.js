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
 * https://casama.ai/invite/<code> is the invite page while Casama Cloud is invite-only (docs/WAITLIST-PLAN.md
 * §7): a member's 6-character code or a campaign code (4 to 32 letters, digits and hyphens). It shows who
 * invited you and claims the invite for an email address. /i/<code> gets the same claim form while
 * /v1/config says the sign-up gate is on, and /invite/<code> goes to /i/<code> for a member's code once
 * sign-up is open. While the gate is on, /get/start goes to /waitlist (a static page) instead of the app.
 * /waitlist/leave?t=<token> asks before it removes an address from the waitlist. The forms are
 * site/waitlist-ui.js, wired by site/assets/waitlist.js.
 *
 * https://casama.ai/g/<code> is a gift code for a free plan (docs/COMP-PLANS-PLAN.md): what it gives and
 * a button to redeem it in the web app. Redeeming happens only on the web (App Store 3.1.1), so there
 * is no app link for /g/ and no "Open in Casama"; the plan then shows up in every app by itself.
 *
 * /newsletter/* is the monthly email's sign-up and double opt-in (D-404, site/newsletter.js).
 *
 * /assets/film/* (D-390) comes here too, only to answer byte-range requests: static assets always
 * send the whole file with 200, and Safari won't play a video that way.
 */
import { handleNewsletter } from "./newsletter.js";
import { leaveBlock, NO_SCRIPT, redeemForm } from "./waitlist-ui.js";

const TYPES = "theme|scheme|wallpaper|skill|app|bot|routine|plugin|set";
const GALLERY = "https://gallery.casama.ai";
const API = "https://api.casama.ai";
const WEB_APP = "https://app.casama.ai";
const SITE = "https://casama.ai";
const DOWNLOAD_PAGE = "https://casama.ai/download";

// Where each download button goes (D-377). iOS and the sandboxed Mac build currently go to
// TestFlight; Google Play and Firefox use the listings' official addresses. Mac, Windows and Linux
// direct downloads go to the public GitHub Releases latest page.
const APP_STORE = "https://apps.apple.com/app/id6833509960"; // "Casama AI": iPhone, iPad and Mac
const TESTFLIGHT = "https://testflight.apple.com/join/n21dCaRu";
const PLAY = "https://play.google.com/store/apps/details?id=ai.casama.app";
const RELEASES_REPO = "stackwares/casama-releases";
const RELEASES = `https://github.com/${RELEASES_REPO}/releases/latest`;
const EXTENSION_DOCS = "https://docs.casama.ai/guide/chrome";
export const GET_LINKS = {
  ios: TESTFLIGHT,
  android: PLAY,
  mac: TESTFLIGHT,
  "mac-dmg": RELEASES,
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
    if (url.pathname === "/waitlist/leave") return leavePage();
    if (url.pathname === "/invite" || url.pathname.startsWith("/invite/")) {
      const code = /^\/invite\/([0-9A-Za-z-]{4,32})\/?$/.exec(url.pathname);
      if (!code) return inviteNotFound();
      trackFunnel(request, env, ctx, "invite_open");
      return inviteClaimPage(code[1].toUpperCase());
    }
    if (url.pathname === "/g" || url.pathname.startsWith("/g/")) {
      const gift = /^\/g\/([0-9A-Za-z-]{10,16})\/?$/.exec(url.pathname);
      return gift ? giftPage(gift[1].toUpperCase()) : giftNotFound();
    }
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
  if (platform === "start" && (await signupGated()) === true) {
    // Casama Cloud is invite-only: everyone goes to the waitlist, on every device.
    const to = new URL(`${SITE}/waitlist`);
    for (const key of ["from", "ref", "utm_campaign"]) {
      const value = url.searchParams.get(key);
      if (value) to.searchParams.set(key, value.slice(0, 64));
    }
    trackFunnel(request, env, ctx, "start_click", { via: "get" });
    return new Response(null, {
      status: 302,
      headers: { location: to.toString(), "cache-control": "private, no-store", vary: "user-agent", "x-robots-tag": "noindex" },
    });
  }
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

/**
 * Whether Casama Cloud's sign-up gate is on: true when /v1/config has `signup_gate`, false when it
 * doesn't, null when the config can't be read. Cached at the edge for a minute.
 */
export async function signupGated() {
  try {
    const res = await fetch(`${API}/v1/config`, { cf: { cacheTtl: 60, cacheEverything: true } });
    if (!res.ok) return null;
    const config = await res.json();
    return Boolean(config && config.signup_gate);
  } catch {
    return null;
  }
}

async function invitePage(code) {
  let preview = null;
  const [, gated] = await Promise.all([
    (async () => {
      try {
        const res = await fetch(`${API}/v1/referral/preview?code=${code}`, { cf: { cacheTtl: 300 } });
        if (res.ok) preview = await res.json();
      } catch {
        // The page still shows the code and the app links when the API is briefly unreachable.
      }
    })(),
    signupGated(),
  ]);
  // While sign-up is gated, the page also claims the invite for an email address. Otherwise it is
  // exactly the page it always was.
  const claim = gated === true;
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
<style>${PAGE_CSS}${claim ? FORM_CSS : ""}</style>
</head>
<body>
<main>
  <a class="logo" href="https://casama.ai" aria-label="Casama home"><span data-casama-mark></span>Casama</a>
  <h1>${esc(who)}</h1>
  <p>${esc(about)}</p>
  <div class="code" aria-label="Invite code">${esc(code)}</div>${
    claim ? `\n  ${redeemForm({ code, label: "Claim my invite", source: "invite" })}\n  ${NO_SCRIPT}` : ""
  }
  <a class="btn primary" href="casama://app/i/${esc(code)}">Open in Casama</a>
  <a class="btn" href="https://casama.ai/download">Get Casama</a>
  <p class="small">Already have the app? It opens this invite by itself. Otherwise, after signing up go to Settings → Invite friends and enter the code within a week.</p>
</main>${claim ? '\n<script src="/assets/waitlist.js"></script>' : ""}
<script src="/assets/brand/casama-mark.js"></script>
</body>
</html>`;
  return new Response(html, {
    status: 200,
    headers: { "content-type": "text/html; charset=utf-8", "cache-control": claim ? "public, max-age=60" : "public, max-age=300" },
  });
}

/** What the pages below may load and talk to: this site, and the API the forms post to. */
const FORM_CSP =
  "default-src 'none'; style-src 'unsafe-inline'; script-src 'self'; connect-src 'self' https://api.casama.ai; font-src 'self'; img-src 'self' data:; base-uri 'none'; form-action 'none'; frame-ancestors 'none'";

/** A page in the shared look with the waitlist script; noindex, and never cached by a shared cache for long. */
function formPage({ title, description = "", body, status = 200, cache = "public, max-age=60" }) {
  const html = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex">
<meta name="referrer" content="no-referrer">
<title>${esc(title)}</title>${description ? `\n<meta name="description" content="${esc(description)}">` : ""}
<meta property="og:title" content="${esc(title)}">${description ? `\n<meta property="og:description" content="${esc(description)}">` : ""}
<meta property="og:image" content="https://casama.ai/og-image.png">
<link rel="icon" type="image/svg+xml" href="/assets/bots/casama-winky-animated.svg">
<style>${PAGE_CSS}${FORM_CSS}</style>
</head>
<body>
<main>
  <a class="logo" href="https://casama.ai" aria-label="Casama home"><span data-casama-mark></span>Casama</a>
${body}
</main>
<script src="/assets/waitlist.js"></script>
<script src="/assets/brand/casama-mark.js"></script>
</body>
</html>`;
  return new Response(html, {
    status,
    headers: {
      "content-type": "text/html; charset=utf-8",
      "cache-control": cache,
      "content-security-policy": FORM_CSP,
      "referrer-policy": "no-referrer",
      "x-robots-tag": "noindex",
    },
  });
}

/** /invite/<code>: claim an invite for an email address (docs/WAITLIST-PLAN.md §7). */
async function inviteClaimPage(code) {
  // A member's code goes to the older page once sign-up is open to everyone.
  if (/^[0-9A-Z]{6}$/.test(code) && (await signupGated()) === false) {
    return new Response(null, { status: 302, headers: { location: `${SITE}/i/${code}`, "cache-control": "private, no-store", "x-robots-tag": "noindex" } });
  }
  let preview = null;
  try {
    const res = await fetch(`${API}/v1/invites/preview?code=${encodeURIComponent(code)}`, { cf: { cacheTtl: 60 } });
    if (res.status === 404) return inviteNotFound();
    if (res.ok) preview = await res.json();
  } catch {
    // The claim form still works when the preview can't be read: redeeming says what is true.
  }
  if (preview && preview.available === false) {
    return formPage({
      title: "These invites are gone",
      body: `  <h1>These invites are gone.</h1>
  <p>Join the waitlist and we'll put you near the front. Running Casama on your own server is open to everyone.</p>
  ${redeemForm({ code, label: "Join the waitlist", source: "invite" })}
  ${NO_SCRIPT}
  <p class="small"><a href="${esc(SITE)}/waitlist">More about the waitlist</a></p>`,
    });
  }
  const name = preview?.kind === "personal" && preview.inviter_name ? String(preview.inviter_name) : "";
  const label = preview?.kind === "campaign" && preview.label ? String(preview.label) : "";
  const who = name ? `${name} invited you to Casama` : "You're invited to Casama";
  const bonus = preview?.kind === "personal" ? Number(preview.welcome_usd ?? 0) : 0;
  const dollars = Number.isInteger(bonus) ? `$${bonus}` : `$${bonus.toFixed(2)}`;
  const about =
    "AI teammates that get things done for you, each on its own computer. Enter your email to claim your invite." +
    (bonus > 0 ? ` You'll get ${dollars} of free usage after your first chat.` : "");
  return formPage({
    title: who,
    description: about,
    body: `  <h1>${esc(who)}</h1>${label ? `\n  <p class="wl-label">${esc(label)}</p>` : ""}
  <p>${esc(about)}</p>
  ${redeemForm({ code, label: "Claim my invite", source: "invite" })}
  ${NO_SCRIPT}
  <p class="small">Already have an account? <a href="${WEB_APP}">Sign in</a></p>`,
  });
}

/** An invite code that doesn't exist, or can't be one. */
function inviteNotFound() {
  return formPage({
    title: "Invite not found",
    status: 404,
    body: `  <h1>We couldn't find that invite.</h1>
  <p>Check the code and try again, or join the waitlist and we'll email you when it's your turn.</p>
  <a class="btn primary" href="${SITE}/waitlist">Join the waitlist</a>`,
  });
}

/**
 * /g/<code>: a gift code for a free plan. Never cached by a shared cache (a code's uses run out), and
 * no analytics: the code is in the address.
 */
async function giftPage(code) {
  let preview = null;
  try {
    const res = await fetch(`${API}/v1/comp/preview?code=${encodeURIComponent(code)}`);
    if (res.status === 404) return giftNotFound();
    if (res.ok) preview = await res.json();
  } catch {
    // The page still offers the redeem button when the API is briefly unreachable.
  }
  const months = Number(preview?.months ?? 0);
  const plan = preview?.plan_name ?? "";
  const gives = plan && months ? `${months === 1 ? "1 month" : `${months} months`} of Casama ${plan}, free` : "A free Casama plan";
  const redeem = `${WEB_APP}/redeem?code=${encodeURIComponent(code)}`;
  return formPage({
    title: "A gift for you",
    description: `${gives}. Redeem it on the web, then use it in every Casama app.`,
    cache: "private, no-store",
    body: `  <h1>${esc(gives)}</h1>
  <p>Someone at Casama gave you this. Redeem it on the web with your Casama account (or make one), and the plan is there in every Casama app: iPhone, Android, Mac and the web. Nothing to pay, and no card.</p>
  <div class="code" aria-label="Gift code">${esc(code)}</div>
  <a class="btn primary" href="${esc(redeem)}">Redeem on the web</a>
  <a class="btn" href="${DOWNLOAD_PAGE}">Get Casama</a>
  <p class="small">One gift code per person. When the free time ends, your workspace moves to Free unless you choose a plan, and everything you made stays.</p>`,
  });
}

function giftNotFound() {
  return formPage({
    title: "Gift code not found",
    status: 404,
    cache: "private, no-store",
    body: `  <h1>This gift code can't be used.</h1>
  <p>It may be mistyped, used up, or past its date. Check it with the person who gave it to you.</p>
  <a class="btn primary" href="${SITE}">About Casama</a>`,
  });
}

/** /waitlist/leave?t=<token>: asks first. Mail scanners open links, so opening this never removes anything. */
function leavePage() {
  return formPage({
    title: "Leave the waitlist",
    cache: "private, no-store",
    body: `  ${leaveBlock()}
  <noscript><p class="wl-note">Removing your address needs JavaScript. Or email <a href="mailto:hello@casama.ai">hello@casama.ai</a>.</p></noscript>`,
  });
}

/** Extra rules for the pages with forms (the invite pages, /waitlist/leave). */
const FORM_CSS = `
  [hidden] { display: none !important; }
  .wl-form { display: grid; gap: 14px; margin-top: 18px; text-align: left; }
  .wl-field { display: grid; gap: 6px; }
  .wl-field span { font-size: 15px; color: var(--muted); }
  .wl-field input { width: 100%; min-height: 52px; padding: 0 20px; border-radius: 999px; border: 1.5px solid var(--line); background: var(--bg); color: var(--ink); font: inherit; }
  .wl-field input:focus-visible { outline: 3px solid var(--accent); outline-offset: 2px; border-color: transparent; }
  button.btn { width: 100%; border: 0; cursor: pointer; font-family: inherit; }
  .wl-form .btn { margin-top: 0; }
  button.btn[disabled] { opacity: .6; cursor: default; }
  .wl-status { margin: 0; min-height: 1.5em; font-size: 15px; color: var(--muted); }
  .wl-status.is-bad { color: var(--ink); font-weight: 700; }
  .wl-check { display: flex; align-items: flex-start; gap: 10px; color: var(--muted); font-size: 15px; cursor: pointer; }
  .wl-check input { flex: none; width: 18px; height: 18px; margin-top: 2px; accent-color: var(--accent); }
  .wl-actions { display: grid; gap: 10px; }
  .wl-actions .btn { margin-top: 0; }
  .wl-label { color: var(--ink); font-weight: 700; }
  .wl-result { margin-top: 18px; }
  .wl-result p { color: var(--ink); }
  .wl-note { font-size: 15px; }
  .wl-note a { color: var(--accent); }
`;

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
/**
 * Where a page view came from, as GA4's source / medium / campaign (docs/GA4-PLAN.md §Attribution). Measurement Protocol
 * hits don't get GA4's own session attribution from page_location or page_referrer, so without this
 * every session showed "(not set)". Google's documented fix is a `campaign_details` event, which
 * GA4 applies to the events after it. Search engines are organic, everything else from outside is
 * a referral (AI assistants included), no referrer is direct. A hop between our own sites returns
 * null so the session keeps the source it started with.
 */
const SEARCH_SOURCES = { google: "google", bing: "bing" };
export function trafficSource(source, host, utm) {
  if (source === "casama") return null;
  if (source === "direct") return { source: "(direct)", medium: "(none)", campaign: "(direct)" };
  const from = String(utm || host || "").toLowerCase().replace(/^www\./, "").slice(0, 100);
  if (SEARCH_SOURCES[source] || source === "search") {
    const name = SEARCH_SOURCES[source] ?? (from.match(/(duckduckgo|brave|yandex|ecosia|startpage|yahoo)/)?.[1] || from);
    return { source: name, medium: "organic", campaign: "(organic)" };
  }
  return { source: from || source, medium: "referral", campaign: "(referral)" };
}
export function gaPayload({ page, host, utm, source, country, mobile, rand = Math.random, ids, site = "", event, eventParams, now = Date.now() }) {
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
  const traffic = event ? null : trafficSource(source, host, utm);
  if (traffic) {
    // campaign_details applies to events at or after its own time, so it goes 1 ms before the page view.
    const micros = Math.floor(now) * 1000;
    payload.events[0].timestamp_micros = micros;
    payload.events.push({ name: "campaign_details", timestamp_micros: micros - 1000, params: { ...traffic, session_id: params.session_id, engagement_time_msec: 1 } });
  }
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
const SITE_HOSTS = { "": "casama.ai", docs: "docs.casama.ai", gallery: "gallery.casama.ai", link: "casama.link", status: "status.casama.ai" };
const SITE_ORIGINS = { "https://docs.casama.ai": "docs", "https://gallery.casama.ai": "gallery", "https://casama.link": "link", "https://status.casama.ai": "status" };
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
  // The waitlist page (D-427): seen, and a join that went through (the address never leaves the page).
  waitlist_view: {},
  waitlist_join: { form: ["page", "inline"] },
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
