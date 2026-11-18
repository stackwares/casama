// casama.ai's Worker (site/gallery-link.js): GA4 funnels without cookies (D-396, D-398).
// Run: node --test scripts/site-worker.test.mjs
import assert from "node:assert/strict";
import { afterEach, beforeEach, test } from "node:test";
import worker, {
  beaconEvent,
  campaignFor,
  gaPayload,
  refererPage,
  siteKey,
  visitorIds,
  withAttribution,
} from "../site/gallery-link.js";

let sent;
const realFetch = globalThis.fetch;
beforeEach(() => {
  sent = [];
  globalThis.fetch = async (url, init) => {
    if (String(url).startsWith("https://www.google-analytics.com/"))
      sent.push({ url: String(url), body: JSON.parse(init.body) });
    return new Response(null, { status: 204 });
  };
});
afterEach(() => {
  globalThis.fetch = realFetch;
});

const env = {
  GA_API_SECRET: "secret",
  VISITS: {
    rows: [],
    writeDataPoint(r) {
      this.rows.push(r);
    },
  },
};
async function call(path, { method = "GET", headers = {}, body, environment = env } = {}) {
  const waits = [];
  const ctx = { waitUntil: (p) => waits.push(p) };
  const req = new Request(`https://casama.ai${path}`, {
    method,
    body,
    headers: {
      "user-agent": "Mozilla/5.0 (iPhone)",
      "cf-connecting-ip": "203.0.113.7",
      ...headers,
    },
  });
  const res = await worker.fetch(req, environment, ctx);
  await Promise.all(waits);
  return res;
}

test("the visitor id is the same all day, and changes with the day, the IP and the browser", async () => {
  const day = new Date("2026-11-18T01:00:00Z");
  const later = new Date("2026-11-18T23:59:00Z");
  const a = await visitorIds("s", day, "1.2.3.4", "UA");
  assert.deepEqual(await visitorIds("s", later, "1.2.3.4", "UA"), a);
  assert.notDeepEqual(await visitorIds("s", new Date("2026-11-19T00:00:01Z"), "1.2.3.4", "UA"), a);
  assert.notDeepEqual(await visitorIds("s", day, "1.2.3.5", "UA"), a);
  assert.notDeepEqual(await visitorIds("s", day, "1.2.3.4", "UA2"), a);
  assert.match(a.clientId, /^\d+\.\d+$/);
  assert.match(a.sessionId, /^\d+$/);
});

test("page views and clicks from one browser share its client id, with no IP or invite code", async () => {
  await call("/b", {
    method: "POST",
    body: JSON.stringify({ p: "/pricing", r: "www.google.com", u: "" }),
  });
  await call("/get/start", { headers: { referer: "https://casama.ai/pricing?x=1" } });
  await call("/i/ABC123");
  assert.equal(sent.length, 3);
  const ids = new Set(sent.map((s) => s.body.client_id));
  assert.equal(ids.size, 1);
  assert.deepEqual(
    sent.map((s) => s.body.events[0].name),
    ["page_view", "start_click", "invite_open"],
  );
  const all = JSON.stringify(sent);
  assert.ok(!all.includes("203.0.113.7"));
  assert.ok(!all.includes("ABC123"));
  const start = sent[1].body.events[0].params;
  assert.equal(start.page_location, "https://casama.ai/pricing");
  assert.equal(start.via, "get");
});

test("each route sends its funnel event", async () => {
  await call("/get/android");
  await call("/get/nothing");
  await call("/get");
  await call("/gallery/theme/sunset");
  assert.deepEqual(
    sent.map((s) => [
      s.body.events[0].name,
      s.body.events[0].params.platform ?? s.body.events[0].params.item_type,
    ]),
    [
      ["download_click", "android"],
      ["download_click", "other"],
      ["qr_open", undefined],
      ["gallery_open", "theme"],
    ],
  );
});

test("nothing goes to Google without the secret, and the redirect still works", async () => {
  const res = await call("/get/start", { environment: {} });
  assert.equal(res.status, 302);
  assert.equal(sent.length, 0);
});

test("the web app and Google Play learn which page sent the visitor", async () => {
  const start = await call("/get/start", {
    headers: { referer: "https://docs.casama.ai/guide/chrome" },
  });
  const loc = new URL(start.headers.get("location"));
  assert.equal(loc.origin, "https://app.casama.ai");
  assert.equal(loc.searchParams.get("utm_source"), "casama.ai");
  assert.equal(loc.searchParams.get("utm_medium"), "website");
  assert.equal(loc.searchParams.get("utm_campaign"), "docs-guide-chrome");
  assert.equal(start.headers.get("cache-control"), "private, no-store");

  const play = await call("/get/android");
  const referrer = new URL(play.headers.get("location")).searchParams.get("referrer");
  assert.equal(referrer, "utm_source=casama.ai&utm_medium=website&utm_campaign=direct");

  const ios = await call("/get/ios");
  assert.equal(ios.headers.get("location"), "https://apps.apple.com/app/id6833509960");
  assert.equal(withAttribution("https://example.com/x", "home"), "https://example.com/x");
  assert.equal(campaignFor({ site: "", page: "/" }), "home");
  assert.equal(campaignFor({ site: "", page: "/compare/notion.html" }), "compare-notion");
});

test("beacon events come only from the closed list", async () => {
  assert.deepEqual(beaconEvent("film_play"), { name: "film_play", params: {} });
  assert.deepEqual(beaconEvent("plan_click", { plan: "pro" }), {
    name: "plan_click",
    params: { plan: "pro" },
  });
  assert.equal(beaconEvent("plan_click", { plan: "enterprise" }), null);
  assert.equal(beaconEvent("purchase", {}), null);
  assert.equal(beaconEvent("start_click", { via: "get" }), null);
  await call("/b", { method: "POST", body: JSON.stringify({ p: "/", e: "copy_install" }) });
  await call("/b", { method: "POST", body: JSON.stringify({ p: "/", e: "evil_event" }) });
  assert.deepEqual(
    sent.map((s) => s.body.events[0].name),
    ["copy_install"],
  );
});

test("the docs, gallery and casama.link count here, and unknown sites are dropped", async () => {
  env.VISITS.rows = [];
  const res = await call("/b", {
    method: "POST",
    headers: { origin: "https://docs.casama.ai" },
    body: JSON.stringify({ h: "docs", p: "/guide/chrome", r: "", u: "" }),
  });
  assert.equal(res.headers.get("access-control-allow-origin"), "https://docs.casama.ai");
  await call("/b", {
    method: "POST",
    headers: { origin: "https://evil.example" },
    body: JSON.stringify({ h: "evil", p: "/" }),
  });
  assert.equal(sent.length, 1);
  assert.equal(sent[0].body.events[0].params.page_location, "https://docs.casama.ai/guide/chrome");
  assert.equal(env.VISITS.rows[0].blobs[2], "docs");
  assert.equal(siteKey(undefined), "");
  assert.equal(siteKey("toString"), null);
  assert.equal(
    refererPage(
      new Request("https://casama.ai/get", { headers: { referer: "https://evil.example/x" } }),
    ),
    null,
  );
});

test("a page view without ids still gets random ones (gaPayload stays pure)", () => {
  const p = gaPayload({ page: "/", source: "direct", rand: () => 0.5 });
  assert.match(p.client_id, /^\d+\.\d+$/);
  assert.equal(p.events[0].name, "page_view");
});
