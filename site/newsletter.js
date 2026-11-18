/**
 * Casama's monthly email (D-404), on casama.ai's Worker. Resend holds the list: segment "Casama
 * newsletter", topic "Casama updates", sent from news@news.casama.ai. It is kept apart from app
 * mail, which ZeptoMail sends from notify.casama.ai and which is transactional only (D-318).
 *
 * Double opt-in, and nobody is stored before they confirm:
 *   POST /newsletter/subscribe   email (+ an empty "website" field that only bots fill in). Sends a
 *                                signed confirmation link. JSON in or Accept: application/json gets
 *                                JSON back; a plain form post gets a page.
 *   GET  /newsletter/confirm     the link from that email. It shows a Confirm button and changes
 *                                nothing, because mail scanners open links on their own.
 *   POST /newsletter/confirm     adds the person to the segment and topic in Resend.
 * Unsubscribing is Resend's own link in every broadcast ({{{RESEND_UNSUBSCRIBE_URL}}}).
 *
 * Secrets: RESEND_API_KEY and NEWSLETTER_SECRET (HMAC key for the links), both in Vaultwarden.
 * NEWSLETTER_LIMIT is a rate limit binding: a few requests a minute per IP and per address.
 */
export const RESEND = "https://api.resend.com";
export const SEGMENT_ID = "bcf1b930-13c0-4bbc-a720-aa4cfd544e3c";
export const TOPIC_ID = "4b2d83b2-6f0a-4d6b-9981-de572951bf3c";
const FROM = "Casama <news@news.casama.ai>";
const REPLY_TO = "hello@casama.ai";
const SITE = "https://casama.ai";
/** How long a confirmation link works. */
export const LINK_DAYS = 7;
const EMAIL_RE = /^[^\s@<>()",;:]{1,64}@[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?(?:\.[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?)+$/;

export function cleanEmail(raw) {
  const email = String(raw ?? "").trim().toLowerCase();
  return email.length <= 254 && EMAIL_RE.test(email) ? email : "";
}

/** Where on the site the form was, as a short slug ("home", "blog-..."), for the contact record. */
export function sourceFrom(referer) {
  try {
    const u = new URL(referer);
    if (!/(^|\.)casama\.ai$/.test(u.hostname)) return "other";
    const host = u.hostname.replace(/\.?casama\.ai$/, "").replace(/^www$/, "");
    const path = u.pathname.replace(/^\/+|\/+$/g, "").replace(/\.html$/, "").replace(/[^a-z0-9]+/gi, "-").toLowerCase();
    return [host, path || (host ? "" : "home")].filter(Boolean).join("-").slice(0, 60) || "home";
  } catch {
    return "unknown";
  }
}

const enc = new TextEncoder();
function b64url(bytes) {
  let s = "";
  for (const b of new Uint8Array(bytes)) s += String.fromCharCode(b);
  return btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}
async function hmac(secret, text) {
  const key = await crypto.subtle.importKey("raw", enc.encode(secret), { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  return b64url(await crypto.subtle.sign("HMAC", key, enc.encode(text)));
}
/** The signed query string for a confirmation link. */
export async function signLink(secret, email, source, now = Date.now()) {
  const t = String(Math.floor(now / 1000));
  const s = await hmac(secret, `${email}\n${t}\n${source}`);
  return new URLSearchParams({ e: email, t, src: source, s }).toString();
}
/** The email from a confirmation link's fields, or "" when the signature is wrong or it expired. */
export async function checkLink(secret, params, now = Date.now()) {
  const email = cleanEmail(params.get("e"));
  const t = params.get("t") ?? "";
  const source = params.get("src") ?? "";
  const sig = params.get("s") ?? "";
  if (!email || !/^\d{1,12}$/.test(t) || !sig) return "";
  const age = now / 1000 - Number(t);
  if (age < -300 || age > LINK_DAYS * 86400) return "";
  const want = await hmac(secret, `${email}\n${t}\n${source}`);
  if (want.length !== sig.length) return "";
  let diff = 0;
  for (let i = 0; i < want.length; i++) diff |= want.charCodeAt(i) ^ sig.charCodeAt(i);
  return diff === 0 ? email : "";
}

async function limited(env, key) {
  if (!env.NEWSLETTER_LIMIT) return false;
  try {
    const { success } = await env.NEWSLETTER_LIMIT.limit({ key });
    return !success;
  } catch {
    return false;
  }
}

function resend(env, method, path, body) {
  return fetch(`${RESEND}${path}`, {
    method,
    headers: { authorization: `Bearer ${env.RESEND_API_KEY}`, "content-type": "application/json" },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
}

export async function handleNewsletter(request, env, url) {
  const path = url.pathname.replace(/\/+$/, "");
  if (path === "/newsletter/subscribe" && request.method === "POST") return subscribe(request, env);
  if (path === "/newsletter/confirm" && request.method === "GET") return confirmPage(env, url);
  if (path === "/newsletter/confirm" && request.method === "POST") return confirm(request, env);
  return new Response("Not found", { status: 404 });
}

async function readForm(request) {
  const type = request.headers.get("content-type") ?? "";
  try {
    if (type.includes("application/json")) return await request.json();
    const form = await request.formData();
    return Object.fromEntries(form.entries());
  } catch {
    return {};
  }
}

async function subscribe(request, env) {
  const wantsJson =
    (request.headers.get("accept") ?? "").includes("application/json") ||
    (request.headers.get("content-type") ?? "").includes("application/json");
  const reply = (status, code, title, text) =>
    wantsJson
      ? Response.json({ ok: status < 400, code, message: text }, { status, headers: { "cache-control": "no-store" } })
      : page(status, title, text);

  const data = await readForm(request);
  // Bots fill in every field; people never see this one. Answer as if it worked.
  if (data.website) return reply(200, "sent", "Check your inbox", "We sent you a link to confirm.");
  const email = cleanEmail(data.email);
  if (!email) return reply(400, "bad_email", "That address doesn't look right", "Go back and check the email address.");
  const ip = request.headers.get("cf-connecting-ip") ?? "";
  if ((await limited(env, `ip:${ip}`)) || (await limited(env, `email:${email}`))) {
    return reply(429, "slow_down", "One moment", "That was a lot of tries. Wait a minute and try again.");
  }
  if (!env.RESEND_API_KEY || !env.NEWSLETTER_SECRET) {
    return reply(503, "unavailable", "Not working right now", "Sign-ups are paused for a moment. Try again later.");
  }
  const source = sourceFrom(request.headers.get("referer") ?? "");
  const link = `${SITE}/newsletter/confirm?${await signLink(env.NEWSLETTER_SECRET, email, source)}`;
  const res = await resend(env, "POST", "/emails", {
    from: FROM,
    to: [email],
    reply_to: REPLY_TO,
    subject: "Confirm Casama's monthly email",
    text: confirmText(link),
    html: confirmHtml(link),
    tags: [{ name: "kind", value: "newsletter_confirm" }],
  });
  if (!res.ok) {
    console.log(`newsletter: confirmation email failed (${res.status})`);
    return reply(502, "send_failed", "We couldn't send the email", "Something went wrong on our side. Try again in a few minutes.");
  }
  return reply(200, "sent", "Check your inbox", `We sent a link to ${email}. Open it to confirm, and you're on the list.`);
}

async function confirmPage(env, url) {
  const email = env.NEWSLETTER_SECRET ? await checkLink(env.NEWSLETTER_SECRET, url.searchParams) : "";
  if (!email) return expired();
  const fields = ["e", "t", "src", "s"]
    .map((k) => `<input type="hidden" name="${k}" value="${esc(url.searchParams.get(k) ?? "")}">`)
    .join("");
  return page(
    200,
    "Confirm your email",
    `Get Casama's monthly email at ${email}: what's new and what's next, once a month at most.`,
    `<form method="post" action="/newsletter/confirm">${fields}<button class="btn primary" type="submit">Confirm</button></form>`,
  );
}

async function confirm(request, env) {
  const data = await readForm(request);
  const params = new URLSearchParams(Object.entries(data).map(([k, v]) => [k, String(v)]));
  const email = env.NEWSLETTER_SECRET ? await checkLink(env.NEWSLETTER_SECRET, params) : "";
  if (!email) return expired();
  const ip = request.headers.get("cf-connecting-ip") ?? "";
  if (await limited(env, `ip:${ip}`)) return page(429, "One moment", "That was a lot of tries. Wait a minute and try again.");
  const ok = await addContact(env, email, params.get("src") ?? "");
  if (!ok) return page(502, "That didn't work", "Something went wrong on our side. Open the link again in a few minutes.");
  return page(
    200,
    "You're on the list",
    "Thanks. Casama's monthly email will come from news@news.casama.ai. Every email has a link to stop them.",
    `<a class="btn primary" href="${SITE}/">Back to casama.ai</a>`,
  );
}

/**
 * Creates the contact (or finds the one already there), then makes sure they are subscribed, in the
 * segment and opted in to the topic. Each call is safe to repeat, so confirming twice is fine.
 */
export async function addContact(env, email, source) {
  const created = await resend(env, "POST", "/contacts", {
    email,
    unsubscribed: false,
    segments: [{ id: SEGMENT_ID }],
    topics: [{ id: TOPIC_ID, subscription: "opt_in" }],
    properties: source ? { signup_source: source } : undefined,
  });
  if (!created.ok) {
    // An unknown property name is refused; try again without it.
    const plain = await resend(env, "POST", "/contacts", { email, unsubscribed: false });
    if (!plain.ok) {
      console.log(`newsletter: contact create failed (${created.status}, ${plain.status})`);
      return false;
    }
  }
  const who = encodeURIComponent(email);
  const steps = await Promise.all([
    resend(env, "PATCH", `/contacts/${who}`, { unsubscribed: false }),
    resend(env, "POST", `/contacts/${who}/segments/${SEGMENT_ID}`),
    resend(env, "PATCH", `/contacts/${who}/topics`, [{ id: TOPIC_ID, subscription: "opt_in" }]),
  ]);
  // Adding to a segment it's already in may answer with a conflict; that's still "in the segment".
  const bad = steps.filter((r) => !r.ok && r.status !== 409);
  if (bad.length) console.log(`newsletter: contact update failed (${steps.map((r) => r.status).join(",")})`);
  return bad.length === 0;
}

function expired() {
  return page(
    400,
    "This link has expired",
    `Confirmation links work for ${LINK_DAYS} days. Sign up again at the bottom of any casama.ai page and we'll send a new one.`,
    `<a class="btn primary" href="${SITE}/#newsletter">Sign up again</a>`,
  );
}

export function confirmText(link) {
  return [
    "Hi,",
    "",
    "Someone, hopefully you, asked to get Casama's monthly email at this address.",
    "Confirm here:",
    link,
    "",
    `The link works for ${LINK_DAYS} days. If you didn't ask for this, ignore this email and you won't hear from us.`,
    "",
    "Casama, by Stackwares",
    "https://casama.ai",
  ].join("\n");
}

export function confirmHtml(link) {
  const a = esc(link);
  const font = "font-family:Arial,Helvetica,sans-serif;";
  return `<!DOCTYPE html><html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><meta http-equiv="X-UA-Compatible" content="IE=edge"><title>Confirm Casama's monthly email</title></head>
<body style="margin:0;padding:0;background-color:#ffffff;">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" bgcolor="#ffffff"><tr><td align="center" style="padding-top:32px;padding-bottom:32px;padding-left:16px;padding-right:16px;">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="max-width:520px;">
<tr><td style="${font}font-size:22px;line-height:28px;font-weight:bold;color:#1d1b20;padding-bottom:20px;">Casama</td></tr>
<tr><td style="${font}font-size:16px;line-height:24px;color:#1d1b20;padding-bottom:16px;">Someone, hopefully you, asked to get Casama's monthly email at this address: what's new and what's next, once a month at most.</td></tr>
<tr><td style="padding-top:8px;padding-bottom:24px;"><table role="presentation" cellpadding="0" cellspacing="0" border="0"><tr><td bgcolor="#7a3fa8" style="background-color:#7a3fa8;border-radius:999px;"><a href="${a}" style="${font}display:inline-block;font-size:16px;line-height:20px;font-weight:bold;color:#ffffff;text-decoration:none;padding-top:14px;padding-bottom:14px;padding-left:28px;padding-right:28px;">Confirm my email</a></td></tr></table></td></tr>
<tr><td style="${font}font-size:14px;line-height:21px;color:#5d5a63;padding-bottom:8px;">The link works for ${LINK_DAYS} days. If you didn't ask for this, ignore this email and you won't hear from us.</td></tr>
<tr><td style="${font}font-size:14px;line-height:21px;color:#5d5a63;">Casama, by Stackwares · <a href="https://casama.ai" style="color:#7a3fa8;">casama.ai</a></td></tr>
</table></td></tr></table></body></html>`;
}

function page(status, title, text, extra = "") {
  const html = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex">
<title>${esc(title)} · Casama</title>
<link rel="icon" type="image/svg+xml" href="/assets/bots/casama-winky-animated.svg">
<style>${PAGE_CSS}</style>
</head>
<body>
<main>
  <a class="logo" href="${SITE}" aria-label="Casama home"><span data-casama-mark></span>Casama</a>
  <h1>${esc(title)}</h1>
  <p>${esc(text)}</p>
  ${extra}
</main>
<script src="/assets/brand/casama-mark.js"></script>
</body>
</html>`;
  return new Response(html, {
    status,
    headers: {
      "content-type": "text/html; charset=utf-8",
      "cache-control": "no-store",
      "x-robots-tag": "noindex",
      "referrer-policy": "no-referrer",
      "content-security-policy":
        "default-src 'none'; style-src 'unsafe-inline'; script-src 'self'; font-src 'self'; img-src 'self' data:; form-action 'self'; frame-ancestors 'none'",
    },
  });
}

function esc(value) {
  return String(value).replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);
}

/** Same look as the worker's other pages (gallery-link.js PAGE_CSS), plus a full-width button. */
const PAGE_CSS = `
  @font-face { font-family: "Google Sans"; src: url("/assets/fonts/GoogleSans-Regular.woff2") format("woff2"); font-weight: 400; font-display: swap; }
  @font-face { font-family: "Google Sans"; src: url("/assets/fonts/GoogleSans-Bold.woff2") format("woff2"); font-weight: 700; font-display: swap; }
  @font-face { font-family: "Libre Baskerville"; src: url("/assets/fonts/LibreBaskerville-Bold.woff2") format("woff2"); font-weight: 700; font-display: swap; }
  :root { --bg:#ffffff; --bg-2:#f4f4f6; --card:#f7f7f9; --ink:#1d1b20; --muted:#5d5a63; --line:#e3e2e7; --accent:#7a3fa8; --accent-ink:#fff; color-scheme: light; }
  @media (prefers-color-scheme: dark) { :root { --bg:#1c1c1e; --bg-2:#2a2a2d; --card:#242427; --ink:#f2f1f4; --muted:#b4b1b9; --line:#38383c; --accent:#d9b6f7; --accent-ink:#25102f; color-scheme: dark; } }
  * { box-sizing: border-box; }
  body { margin: 0; min-height: 100vh; display: grid; place-items: center; padding: 16px; background: var(--bg); color: var(--ink); font: 400 17px/1.55 "Google Sans", -apple-system, BlinkMacSystemFont, "Segoe UI", system-ui, sans-serif; -webkit-font-smoothing: antialiased; }
  main { width: 100%; max-width: 440px; background: var(--card); border: 1px solid var(--line); border-radius: 22px; padding: 32px 24px; text-align: center; }
  .logo { display: inline-flex; align-items: center; gap: 10px; font: 700 22px/1 "Libre Baskerville", Georgia, serif; letter-spacing: -0.03em; text-decoration: none; color: inherit; }
  [data-casama-mark] { display: block; flex: none; width: 34px; height: 34px; contain: layout paint style; opacity: 0; transition: opacity .4s ease; }
  [data-casama-mark].is-ready { opacity: 1; }
  h1 { font-size: 30px; font-weight: 700; line-height: 1.1; letter-spacing: -0.04em; margin: 22px 0 10px; }
  p { margin: 0 0 18px; color: var(--muted); overflow-wrap: anywhere; }
  form { margin: 0; }
  .btn { display: flex; width: 100%; align-items: center; justify-content: center; min-height: 52px; padding: 0 26px; border: 0; border-radius: 999px; text-decoration: none; font-family: inherit; font-weight: 700; font-size: 17px; line-height: 1; background: var(--bg-2); color: var(--ink); margin-top: 10px; cursor: pointer; transition: transform .14s cubic-bezier(.16,1,.3,1), filter .2s ease; }
  .btn.primary { background: var(--accent); color: var(--accent-ink); }
  .btn:active { transform: scale(.96); }
  @media (hover: hover) and (pointer: fine) { .btn:hover { filter: brightness(1.08); } }
  :focus-visible { outline: 3px solid var(--accent); outline-offset: 3px; }
`;
