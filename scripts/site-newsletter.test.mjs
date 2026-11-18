// casama.ai's monthly email sign-up (D-404, site/newsletter.js).
// Run: node --test scripts/site-newsletter.test.mjs
import assert from "node:assert/strict";
import { afterEach, beforeEach, test } from "node:test";
import worker from "../site/gallery-link.js";
import { SEGMENT_ID, TOPIC_ID, checkLink, cleanEmail, signLink, sourceFrom } from "../site/newsletter.js";

let calls;
let failWith = 0;
const realFetch = globalThis.fetch;
beforeEach(() => {
  calls = [];
  failWith = 0;
  globalThis.fetch = async (url, init = {}) => {
    const u = String(url);
    if (u.startsWith("https://api.resend.com/")) {
      calls.push({ url: u, method: init.method, body: init.body ? JSON.parse(init.body) : undefined });
      if (failWith) return new Response("{}", { status: failWith });
      return Response.json({ id: "x" });
    }
    return new Response(null, { status: 204 });
  };
});
afterEach(() => {
  globalThis.fetch = realFetch;
});

function limiter(allow = true) {
  return { keys: [], async limit({ key }) { this.keys.push(key); return { success: allow }; } };
}
const env = () => ({ RESEND_API_KEY: "re_test", NEWSLETTER_SECRET: "s3cret", NEWSLETTER_LIMIT: limiter() });

function post(path, fields, { headers = {}, environment = env() } = {}) {
  const body = new URLSearchParams(fields);
  const req = new Request(`https://casama.ai${path}`, {
    method: "POST",
    body,
    headers: { "content-type": "application/x-www-form-urlencoded", "cf-connecting-ip": "203.0.113.7", ...headers },
  });
  return worker.fetch(req, environment, { waitUntil() {} });
}
function get(path, environment = env()) {
  return worker.fetch(new Request(`https://casama.ai${path}`), environment, { waitUntil() {} });
}

test("addresses are trimmed, lowercased and checked", () => {
  assert.equal(cleanEmail("  Ana@Example.COM "), "ana@example.com");
  assert.equal(cleanEmail("nope"), "");
  assert.equal(cleanEmail("a@b"), "");
  assert.equal(cleanEmail("a b@example.com"), "");
  assert.equal(cleanEmail(`${"a".repeat(250)}@example.com`), "");
});

test("the source is the page the form was on", () => {
  assert.equal(sourceFrom("https://casama.ai/"), "home");
  assert.equal(sourceFrom("https://casama.ai/blog/hello-world"), "blog-hello-world");
  assert.equal(sourceFrom("https://www.casama.ai/pricing.html"), "pricing");
  assert.equal(sourceFrom("https://docs.casama.ai/guide/x"), "docs-guide-x");
  assert.equal(sourceFrom("https://evil.example/"), "other");
  assert.equal(sourceFrom(""), "unknown");
});

test("a signed link checks out, and a changed, wrong-key or old one doesn't", async () => {
  const now = Date.UTC(2026, 10, 18);
  const q = new URLSearchParams(await signLink("k", "ana@example.com", "home", now));
  assert.equal(await checkLink("k", q, now + 1000), "ana@example.com");
  assert.equal(await checkLink("other", q, now), "");
  assert.equal(await checkLink("k", q, now + 8 * 86400 * 1000), "");
  const changed = new URLSearchParams(q);
  changed.set("e", "eve@example.com");
  assert.equal(await checkLink("k", changed, now), "");
  const src = new URLSearchParams(q);
  src.set("src", "pricing");
  assert.equal(await checkLink("k", src, now), "");
});

test("subscribing sends one confirmation email and stores nothing yet", async () => {
  const res = await post("/newsletter/subscribe", { email: "Ana@Example.com" }, { headers: { accept: "application/json", referer: "https://casama.ai/pricing" } });
  assert.equal(res.status, 200);
  assert.deepEqual(await res.json(), { ok: true, code: "sent", message: "We sent a link to ana@example.com. Open it to confirm, and you're on the list." });
  assert.equal(calls.length, 1);
  assert.equal(calls[0].url, "https://api.resend.com/emails");
  const mail = calls[0].body;
  assert.deepEqual(mail.to, ["ana@example.com"]);
  assert.equal(mail.from, "Casama <news@news.casama.ai>");
  const link = /https:\/\/casama\.ai\/newsletter\/confirm\?\S+/.exec(mail.text)[0];
  const q = new URL(link).searchParams;
  assert.equal(q.get("src"), "pricing");
  assert.equal(await checkLink("s3cret", q), "ana@example.com");
  assert.ok(mail.html.includes(link.replace(/&/g, "&amp;")));
});

test("a plain form post gets a page back", async () => {
  const res = await post("/newsletter/subscribe", { email: "ana@example.com" });
  assert.equal(res.status, 200);
  assert.match(res.headers.get("content-type"), /text\/html/);
  assert.match(await res.text(), /Check your inbox/);
});

test("bad addresses, bots and too many tries send nothing", async () => {
  let res = await post("/newsletter/subscribe", { email: "nope" }, { headers: { accept: "application/json" } });
  assert.equal(res.status, 400);
  res = await post("/newsletter/subscribe", { email: "bot@example.com", website: "http://spam" }, { headers: { accept: "application/json" } });
  assert.equal(res.status, 200);
  const e = env();
  e.NEWSLETTER_LIMIT = limiter(false);
  res = await post("/newsletter/subscribe", { email: "ana@example.com" }, { headers: { accept: "application/json" }, environment: e });
  assert.equal(res.status, 429);
  assert.equal(calls.length, 0);
});

test("a failed send says so", async () => {
  failWith = 500;
  const res = await post("/newsletter/subscribe", { email: "ana@example.com" }, { headers: { accept: "application/json" } });
  assert.equal(res.status, 502);
  assert.equal((await res.json()).ok, false);
});

test("opening the link only shows a Confirm button; posting it adds the contact", async () => {
  const qs = await signLink("s3cret", "ana@example.com", "home");
  const page = await get(`/newsletter/confirm?${qs}`);
  assert.equal(page.status, 200);
  const html = await page.text();
  assert.match(html, /<form method="post" action="\/newsletter\/confirm">/);
  assert.equal(calls.length, 0);

  const res = await post("/newsletter/confirm", Object.fromEntries(new URLSearchParams(qs)));
  assert.equal(res.status, 200);
  assert.match(await res.text(), /on the list/);
  const create = calls.find((c) => c.url === "https://api.resend.com/contacts");
  assert.equal(create.body.email, "ana@example.com");
  assert.deepEqual(create.body.segments, [{ id: SEGMENT_ID }]);
  assert.deepEqual(create.body.topics, [{ id: TOPIC_ID, subscription: "opt_in" }]);
  assert.deepEqual(create.body.properties, { signup_source: "home" });
  assert.ok(calls.some((c) => c.method === "POST" && c.url.endsWith(`/contacts/ana%40example.com/segments/${SEGMENT_ID}`)));
  assert.ok(calls.some((c) => c.method === "PATCH" && c.url.endsWith("/contacts/ana%40example.com") && c.body.unsubscribed === false));
});

test("a bad or expired link is refused and adds nobody", async () => {
  const qs = new URLSearchParams(await signLink("s3cret", "ana@example.com", "home", Date.now() - 8 * 86400 * 1000));
  assert.equal((await get(`/newsletter/confirm?${qs}`)).status, 400);
  qs.set("t", String(Math.floor(Date.now() / 1000)));
  assert.equal((await post("/newsletter/confirm", Object.fromEntries(qs))).status, 400);
  assert.equal(calls.length, 0);
});

test("other methods and paths under /newsletter/ are not found", async () => {
  assert.equal((await get("/newsletter/subscribe")).status, 404);
  assert.equal((await get("/newsletter/other")).status, 404);
});
