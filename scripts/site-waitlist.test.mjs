// casama.ai's waitlist and invite pages (docs/WAITLIST-PLAN.md §5, §7, §12): the Worker routes
// (site/gallery-link.js), the page markup (site/waitlist-ui.js) and the puzzle solver
// (site/assets/waitlist.js). Run: node --test scripts/site-waitlist.test.mjs
import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { readFileSync } from "node:fs";
import { afterEach, beforeEach, test } from "node:test";
import vm from "node:vm";
import worker from "../site/gallery-link.js";
import { leaveBlock, redeemForm, waitlistPage } from "../site/waitlist-ui.js";

// ------------------------------------------------------------------ a fake API

let gate; // "on" | "off" | "fail" | "error"
let previews; // code -> preview object (absent: 404)
let referralPreview;
let calls;
const realFetch = globalThis.fetch;
beforeEach(() => {
  gate = "off";
  previews = {};
  referralPreview = { inviter_name: "Ada", welcome_usd: 2 };
  calls = [];
  globalThis.fetch = async (url, init = {}) => {
    const u = new URL(String(url));
    calls.push({ url: String(url), method: init.method ?? "GET" });
    const json = (body, status = 200) => new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json" } });
    if (u.origin === "https://www.google-analytics.com") return new Response(null, { status: 204 });
    if (u.pathname === "/v1/config") {
      if (gate === "fail") throw new Error("offline");
      if (gate === "error") return new Response("nope", { status: 500 });
      return json(gate === "on" ? { signup_gate: { mode: "invite_only", waitlist_url: "https://casama.ai/waitlist" } } : { name: "Casama" });
    }
    if (u.pathname === "/v1/invites/preview") {
      const p = previews[u.searchParams.get("code")];
      return p ? json(p) : json({ code: "invite_not_found", detail: "No such invite." }, 404);
    }
    if (u.pathname === "/v1/referral/preview") return json(referralPreview);
    return new Response(null, { status: 204 });
  };
});
afterEach(() => {
  globalThis.fetch = realFetch;
});

async function call(path, { ua = "Mozilla/5.0 (Macintosh)" } = {}) {
  const req = new Request(`https://casama.ai${path}`, { headers: { "user-agent": ua } });
  return worker.fetch(req, {}, { waitUntil() {} });
}

// ------------------------------------------------------------------ /get/start follows the gate

test("/get/start goes to the waitlist while the gate is on, on every device, keeping from and ref", async () => {
  gate = "on";
  for (const ua of ["Mozilla/5.0 (Macintosh)", "Mozilla/5.0 (iPhone)", "Mozilla/5.0 (Linux; Android 14)"]) {
    const res = await call("/get/start?from=pricing&ref=hn&junk=1", { ua });
    assert.equal(res.status, 302);
    assert.equal(res.headers.get("location"), "https://casama.ai/waitlist?from=pricing&ref=hn");
    assert.equal(res.headers.get("cache-control"), "private, no-store");
  }
  const bare = await call("/get/start");
  assert.equal(bare.headers.get("location"), "https://casama.ai/waitlist");
});

test("/get/start is the app when the gate is off, and when the config can't be read", async () => {
  for (const mode of ["off", "fail", "error"]) {
    gate = mode;
    const res = await call("/get/start?from=home");
    assert.equal(res.status, 302, mode);
    const to = new URL(res.headers.get("location"));
    assert.equal(to.origin, "https://app.casama.ai", mode);
    assert.equal(to.searchParams.get("utm_source"), "casama.ai", mode);
  }
});

test("other /get links ignore the gate and never read the config", async () => {
  gate = "on";
  const res = await call("/get/web");
  assert.equal(res.headers.get("location"), "https://app.casama.ai/?utm_source=casama.ai&utm_medium=website&utm_campaign=direct");
  assert.equal(calls.some((c) => c.url.endsWith("/v1/config")), false);
});

// ------------------------------------------------------------------ /invite/<code>

const personal = { kind: "personal", label: null, inviter_name: "Ada", available: true, welcome_usd: 2 };
const campaign = { kind: "campaign", label: "Hacker News readers", inviter_name: null, available: true, welcome_usd: 0 };

function assertPrivatePage(res) {
  assert.equal(res.headers.get("x-robots-tag"), "noindex");
  assert.match(res.headers.get("content-type"), /text\/html/);
  assert.match(res.headers.get("content-security-policy"), /script-src 'self'/);
}

test("/invite/<code> for an available personal code names the inviter and claims for an email", async () => {
  gate = "on";
  previews.ABC123 = personal;
  const res = await call("/invite/abc123");
  assert.equal(res.status, 200);
  assertPrivatePage(res);
  const html = await res.text();
  assert.match(html, /<h1>Ada invited you to Casama<\/h1>/);
  assert.match(html, /data-wl-redeem[^>]*data-code="ABC123"/);
  assert.match(html, /Claim my invite/);
  assert.match(html, /name="email"/);
  assert.match(html, /<script src="\/assets\/waitlist\.js">/);
  assert.match(html, /<meta name="robots" content="noindex">/);
  assert.ok(calls.some((c) => c.url === "https://api.casama.ai/v1/invites/preview?code=ABC123"));
});

test("/invite/<code> for an available campaign code shows the label under the heading", async () => {
  gate = "on";
  previews["SHOWHN-DEC8"] = campaign;
  const res = await call("/invite/showhn-dec8");
  assert.equal(res.status, 200);
  const html = await res.text();
  assert.match(html, /<h1>You're invited to Casama<\/h1>\s*<p class="wl-label">Hacker News readers<\/p>/);
  assert.match(html, /data-code="SHOWHN-DEC8"/);
  assert.match(html, /Claim my invite/);
});

test("/invite/<code> for a personal code without a name says You're invited", async () => {
  gate = "on";
  previews.ABC123 = { ...personal, inviter_name: null };
  const html = await (await call("/invite/ABC123")).text();
  assert.match(html, /<h1>You're invited to Casama<\/h1>/);
});

test("/invite/<code> for a used-up code says so, keeps the code, and offers the waitlist", async () => {
  gate = "on";
  previews["SHOWHN-DEC8"] = { ...campaign, available: false };
  const res = await call("/invite/SHOWHN-DEC8");
  assert.equal(res.status, 200);
  const html = await res.text();
  assert.match(html, /<h1>These invites are gone\.<\/h1>/);
  assert.match(html, /data-wl-redeem[^>]*data-code="SHOWHN-DEC8"/);
  assert.match(html, /<button class="btn primary" type="submit">Join the waitlist<\/button>/);
  assert.doesNotMatch(html, /Claim my invite/);
});

test("/invite/<code> for an unknown code is a 404 page that links to the waitlist", async () => {
  gate = "on";
  const res = await call("/invite/NOPE-1234");
  assert.equal(res.status, 404);
  assertPrivatePage(res);
  const html = await res.text();
  assert.match(html, /couldn't find that invite/);
  assert.match(html, /href="https:\/\/casama\.ai\/waitlist"/);
  // Codes that can't be codes get the same page without asking the API.
  calls.length = 0;
  for (const path of ["/invite/abc", "/invite/has_underscore", `/invite/${"A".repeat(33)}`, "/invite/", "/invite"]) {
    const bad = await call(path);
    assert.equal(bad.status, 404, path);
    assert.match(await bad.text(), /couldn't find that invite/);
  }
  assert.equal(calls.some((c) => c.url.includes("/v1/invites/preview")), false);
});

test("/invite/<code> still shows the claim form when the preview can't be read", async () => {
  gate = "on";
  const real = globalThis.fetch;
  globalThis.fetch = async (url, init) => {
    if (String(url).includes("/v1/invites/preview")) throw new Error("offline");
    return real(url, init);
  };
  const res = await call("/invite/ABC123");
  assert.equal(res.status, 200);
  assert.match(await res.text(), /Claim my invite/);
});

test("/invite/<code> sends a member's code to /i/<code> once sign-up is open, and not a campaign code", async () => {
  gate = "off";
  const res = await call("/invite/abc123");
  assert.equal(res.status, 302);
  assert.equal(res.headers.get("location"), "https://casama.ai/i/ABC123");
  previews["SHOWHN-DEC8"] = campaign;
  assert.equal((await call("/invite/SHOWHN-DEC8")).status, 200);
  gate = "fail"; // an unreadable config never redirects
  previews.ABC123 = personal;
  assert.equal((await call("/invite/ABC123")).status, 200);
});

// ------------------------------------------------------------------ /i/<code>

test("/i/<code> is the page it always was while sign-up is open", async () => {
  gate = "off";
  const res = await call("/i/abc123");
  assert.equal(res.status, 200);
  assert.equal(res.headers.get("cache-control"), "public, max-age=300");
  const html = await res.text();
  assert.match(html, /<h1>Ada invited you to Casama<\/h1>/);
  assert.match(html, /Open in Casama/);
  assert.match(html, /Get Casama/);
  assert.doesNotMatch(html, /data-wl|waitlist|Claim my invite|<form/);
  // An unreadable config changes nothing either.
  for (const mode of ["fail", "error"]) {
    gate = mode;
    assert.equal(await (await call("/i/abc123")).text(), html, mode);
  }
});

test("/i/<code> gets the claim form while the gate is on, and keeps its buttons", async () => {
  gate = "on";
  const res = await call("/i/abc123");
  assert.equal(res.status, 200);
  const html = await res.text();
  assert.match(html, /<h1>Ada invited you to Casama<\/h1>/);
  assert.match(html, /data-wl-redeem[^>]*data-code="ABC123"/);
  assert.match(html, /Claim my invite/);
  assert.match(html, /<script src="\/assets\/waitlist\.js">/);
  assert.match(html, /Open in Casama/);
  assert.match(html, /Get Casama/);
});

// ------------------------------------------------------------------ escaping

const hostile = "<script>alert(1)</script>";
const hostileQuote = '"><img src=x onerror=alert(1)>';

test("names and labels from the API are escaped on every invite page", async () => {
  gate = "on";
  previews.ABC123 = { ...personal, inviter_name: hostile };
  previews["SHOWHN-DEC8"] = { ...campaign, label: hostile };
  previews["GONE-1"] = { ...campaign, label: hostileQuote, available: false };
  referralPreview = { inviter_name: hostile, welcome_usd: 2 };
  for (const path of ["/invite/ABC123", "/invite/SHOWHN-DEC8", "/invite/GONE-1", "/i/ABC123"]) {
    const html = await (await call(path)).text();
    assert.equal(html.includes(hostile), false, path);
    assert.equal(html.includes(hostileQuote), false, path);
    assert.equal(html.includes("<img src=x"), false, path);
    assert.equal(html.includes("onerror=alert(1)>"), false, path);
  }
  const html = await (await call("/invite/ABC123")).text();
  assert.match(html, /&lt;script&gt;alert\(1\)&lt;\/script&gt; invited you to Casama/);
  assert.match(await (await call("/invite/SHOWHN-DEC8")).text(), /<p class="wl-label">&lt;script&gt;alert\(1\)&lt;\/script&gt;<\/p>/);
  // The code in the URL is only ever letters, digits and hyphens; and attribute values can't break out.
  assert.match(redeemForm({ code: hostileQuote, label: "Go" }), /data-code="&quot;&gt;&lt;img src=x onerror=alert\(1\)&gt;"/);
});

// ------------------------------------------------------------------ /waitlist/leave and the page markup

test("/waitlist/leave only asks: opening it calls no API and removes nothing", async () => {
  const res = await call("/waitlist/leave?t=abc.def");
  assert.equal(res.status, 200);
  assertPrivatePage(res);
  assert.equal(res.headers.get("cache-control"), "private, no-store");
  assert.equal(res.headers.get("referrer-policy"), "no-referrer");
  const html = await res.text();
  assert.match(html, /Take your address off the waitlist\?/);
  assert.match(html, /Remove my address/);
  assert.match(html, /That link isn't valid any more\./);
  assert.equal(html.includes("abc.def"), false, "the token is never written into the page");
  assert.deepEqual(calls.filter((c) => c.url.includes("/v1/waitlist")), []);
  assert.equal(calls.some((c) => c.method === "POST"), false);
  assert.match(leaveBlock(), /data-wl-leave-button/);
});

test("the /waitlist page has the form, the code box, and no counters or share loops", () => {
  const html = waitlistPage();
  for (const text of [
    "What would you have a bot do first?",
    "I run Casama on my own server",
    "Also send me Casama's monthly email (once a month at most)",
    "Join the waitlist",
    "You're on the list.",
    "Have an invite code?",
    "Use my invite",
    "Already have an account?",
    "https://docs.casama.ai/self-hosting/",
    "hello@casama.ai",
  ]) {
    assert.ok(html.includes(text), text);
  }
  assert.match(html, /name="note" maxlength="280"/);
  assert.match(html, /name="newsletter">/, "the monthly email box is not ticked");
  assert.doesNotMatch(html, /checked/);
  assert.doesNotMatch(html, /position|share|move up|beta/i);
});

// ------------------------------------------------------------------ the SHA-256 and the puzzle solver

function load() {
  const sandbox = { window: {}, setTimeout };
  sandbox.window.setTimeout = setTimeout;
  vm.runInNewContext(readFileSync(new URL("../site/assets/waitlist.js", import.meta.url), "utf8"), sandbox);
  return sandbox.window.CasamaWaitlist;
}
const lib = load();
const nodeHash = (text) => createHash("sha256").update(text, "utf8").digest();
function zeroBits(digest) {
  let bits = 0;
  for (const byte of digest) {
    if (byte === 0) bits += 8;
    else return bits + Math.clz32(byte) - 24;
  }
  return bits;
}

test("sha256 matches Node's for the empty string, short, long and awkward inputs", () => {
  const inputs = [
    "",
    "abc",
    "The quick brown fox jumps over the lazy dog",
    "x".repeat(200),
    ...[1, 54, 55, 56, 57, 63, 64, 65, 119, 120, 127, 128, 129, 1000].map((n) => "a".repeat(n)),
    "héllo wörld ✓ 日本語 😀 \u{10FFFF}",
    "v1.18.1893456000.k3j2h4kj23h4.aGVsbG8gd29ybGQ:12345",
  ];
  for (const text of inputs) assert.equal(lib.sha256Hex(text), nodeHash(text).toString("hex"), JSON.stringify(text.slice(0, 20)) + ` (${text.length})`);
});

test("the solver's nonce really gives the leading zero bits, at difficulty 8 and 12", async () => {
  const challenges = [
    "v1.8.1893456000.abc123.sig",
    `v1.12.1893456000.${"r".repeat(22)}.${"m".repeat(43)}`, // about a full block of prefix, so two blocks per try
    `v1.12.1893456000.${"r".repeat(60)}.${"m".repeat(60)}`, // more than a block of prefix
  ];
  for (const challenge of challenges) {
    for (const difficulty of [8, 12]) {
      const nonce = lib.findNonce(challenge, difficulty);
      assert.equal(typeof nonce, "string");
      assert.ok(nonce.length >= 1 && nonce.length <= 64);
      assert.ok(zeroBits(nodeHash(`${challenge}:${nonce}`)) >= difficulty, `${challenge} d${difficulty}`);
      const solved = await lib.solve(challenge, difficulty, { chunk: 500 });
      assert.ok(zeroBits(nodeHash(`${challenge}:${solved}`)) >= difficulty, `solve ${challenge} d${difficulty}`);
    }
  }
});

test("the solver handles the real difficulty in good time and refuses odd puzzles", async () => {
  const challenge = `v1.18.1893456000.${"q".repeat(20)}.${"s".repeat(43)}`;
  const started = Date.now();
  const nonce = await lib.solve(challenge, 18);
  assert.ok(zeroBits(nodeHash(`${challenge}:${nonce}`)) >= 18);
  assert.ok(Date.now() - started < 20000, "18 bits take well under 20 seconds");
  await assert.rejects(() => lib.solve(challenge, 99), /Unexpected puzzle/);
  await assert.rejects(() => lib.solve(challenge, 1.5), /Unexpected puzzle/);
  assert.equal(lib.findNonce(challenge, 30, 100), null, "gives up at the limit");
  assert.equal(lib.leadingZeros(new Int32Array([0, 0x00ffffff, 1, 1, 1, 1, 1, 1]), 40), true);
  assert.equal(lib.leadingZeros(new Int32Array([0, 0x00ffffff, 1, 1, 1, 1, 1, 1]), 41), false);
});

// ------------------------------------------------------------------ waitlist placements (docs/WAITLIST-PLAN.md §12)

const site = (p) => readFileSync(new URL(`../site/${p}`, import.meta.url), "utf8");
const MARK = "<!-- waitlist copy: docs/WAITLIST-PLAN.md §12 -->";

test("the header has a Join the waitlist button and a quiet Sign in link on a written page, the home page and a hand-written page", () => {
  for (const p of ["about.html", "index.html", "download.html", "privacy.html", "blog/how-approvals-work.html"]) {
    const html = site(p);
    const header = html.slice(html.indexOf('<header class="site-header">'), html.indexOf("</header>"));
    assert.match(header, /<a class="btn sm primary" href="\/waitlist">Join the waitlist<\/a>/, p);
    assert.match(header, /<a class="header-signin" href="https:\/\/app\.casama\.ai">Sign in<\/a>/, p);
    assert.ok(header.includes(MARK), p);
  }
  assert.match(site("site.css"), /@media \(max-width: 480px\) \{ \.header-signin \{ display: none; \}/);
});

test("the home page has an email-only inline form in the hero and the bottom call to action", () => {
  const html = site("index.html");
  const forms = html.match(/<form class="wl-inline"[\s\S]*?<\/form>/g) ?? [];
  assert.equal(forms.length, 2);
  assert.ok(forms[0].includes('data-source="home-hero"') && forms[1].includes('data-source="home-cta"'));
  for (const f of forms) {
    assert.match(f, /type="email" name="email"/);
    assert.doesNotMatch(f, /name="note"|name="newsletter"/);
    assert.match(f, /action="\/waitlist" method="get"/); // works without JavaScript
  }
  assert.match(html, /<script src="\/assets\/waitlist\.js"><\/script>/);
});

test("blog posts and the changelog end with a waitlist box, not the newsletter box; the footer form stays", () => {
  for (const p of ["blog/how-approvals-work.html", "changelog.html"]) {
    const html = site(p);
    const box = html.match(/<aside class="news-box"[\s\S]*?<\/aside>/)?.[0] ?? "";
    assert.ok(box.includes("Casama Cloud is invite-only for now."), p);
    assert.ok(box.includes("data-wl-inline"), p);
    assert.ok(!box.includes("data-newsletter") && !/monthly email/.test(box), p);
    assert.ok(html.includes('<script src="/assets/waitlist.js"></script>'), p);
    assert.ok(html.includes('data-newsletter'), `${p} keeps the footer newsletter form`);
  }
  const dl = site("download.html");
  const card = dl.match(/<div class="dl-news-card">[\s\S]*?<\/form>/)[0];
  assert.ok(card.includes("data-wl-inline") && !card.includes("data-newsletter"));
  assert.ok(dl.includes('id="newsletter"'));
  // The standalone newsletter page still has its own box.
  assert.ok(site("newsletter.html").includes("data-newsletter"));
});

test("the footer's Product column has a Waitlist link right after Casama Cloud", () => {
  for (const p of ["index.html", "download.html", "about.html", "blog/how-approvals-work.html"]) {
    assert.match(site(p), /<a href="https:\/\/app\.casama\.ai">Casama Cloud<\/a>\s*(?:<!--[^>]*-->\s*)?<a href="\/waitlist">Waitlist<\/a>/, p);
  }
});

test("gallery item pages say Cloud is invite-only under the Open in Casama button", () => {
  const html = readFileSync(new URL("../gallery/i/app/beehiiv/index.html", import.meta.url), "utf8");
  const at = html.indexOf("Open in Casama");
  assert.ok(at > 0);
  assert.ok(html.indexOf('Casama Cloud is invite-only for now. <a href="https://casama.ai/waitlist">Join the waitlist</a>', at) > at);
});

test("the inline form shares waitlist.js's join code and shows the joined message", () => {
  const js = site("assets/waitlist.js");
  assert.match(js, /function bindInline/);
  assert.equal((js.match(/function searcher/g) ?? []).length, 1);
  assert.match(js, /form\[data-wl-inline\]/);
});
