/** Site hosts on the pages port (docs/SITES-AND-DOMAINS-PLAN.md §7.1, §7.2, §10 "Host routing"). */
import { PAGE_CSP, siteCsp } from "@casama/domain";
import { afterAll, beforeAll, expect, it } from "vitest";
import { clearHostCache } from "../src/pages/hosts.ts";
import { j } from "./helpers.ts";
import { PAGES_HOST, type SitesWorld, startSitesWorld, ZONE } from "./sites-fixture.ts";

let w: SitesWorld;
let pageId = "";
const site = `https://crumb.${ZONE}`;

beforeAll(async () => {
  w = await startSitesWorld();
  pageId = await w.publishFolder();
  const res = await w.h.request(`/v1/pages/${pageId}/site`, {
    method: "PUT",
    token: w.owner.token,
    json: { label: "crumb" },
  });
  expect(res.status).toBe(200);
}, 60_000);
afterAll(async () => w?.stop());

it("the pages origin still serves its own routes, untouched", async () => {
  const robots = await w.get(`https://${PAGES_HOST}/robots.txt`);
  expect(await robots.text()).toBe("User-agent: *\nDisallow: /\n");
  expect((await w.get(`https://${PAGES_HOST}/v/nope`)).status).toBe(404);
  expect((await w.get(`https://${PAGES_HOST}/s/nope`)).status).toBe(404);
  expect((await w.get(`https://${PAGES_HOST}/c/nope`)).status).toBe(404);
  expect((await w.get(`https://${PAGES_HOST}/t/nope`)).status).toBe(404);
  // A page shared the old way keeps its link on the pages origin.
  const plain = await w.tool("pages.publish", { title: "Plan", html: "<p>plan</p>" });
  const plainId = /page ([0-9a-f-]{36})/.exec(plain.content)![1]!;
  const share = await w.tool("pages.share", { page_id: plainId, visibility: "public" });
  const link = /(https:\/\/pages\.example\.com\/s\/[^\s)."]+)/.exec(share.content)![1]!;
  const res = await w.get(link);
  expect(res.status).toBe(200);
  expect(res.headers.get("content-security-policy")).toBe(PAGE_CSP);
  expect(await res.text()).toContain("casama-updated");
  // Any host that isn't a site, such as a Casama Link pages host, is the pages origin too.
  expect(await (await w.get("https://abc-p.link.example.org/robots.txt")).text()).toContain(
    "Disallow",
  );
  // And a site's public link is not opened on a site host.
  const onSite = await w.get(`${site}${new URL(link).pathname}`);
  expect(onSite.status).toBe(404);
  expect(await onSite.text()).not.toContain("plan");
});

it("serves the site at the root of its address", async () => {
  const home = await w.get(`${site}/`);
  expect(home.status).toBe(200);
  expect(home.headers.get("content-security-policy")).toBe(siteCsp(true));
  expect(home.headers.get("cache-control")).toBe("public, max-age=60");
  expect(home.headers.get("strict-transport-security")).toBe("max-age=31536000");
  expect(home.headers.get("x-robots-tag")).toBe("noindex, nofollow");
  expect(home.headers.get("etag")).toBeTruthy();
  const html = await home.text();
  expect(html).toContain("<h1>Crumb</h1>");
  expect(html).not.toContain("casama-updated");
  expect(html).not.toContain("<base");
  expect(html).toContain('id="casama-badge"');
  // Unchanged: answered from the browser's copy.
  const again = await w.get(`${site}/`, {
    headers: { "if-none-match": home.headers.get("etag")! },
  });
  expect(again.status).toBe(304);
});

it("serves files, /about → about.html, folders' index and the site's own 404", async () => {
  const about = await w.get(`${site}/about`);
  expect(about.status).toBe(200);
  const aboutHtml = await about.text();
  expect(aboutHtml).toContain("About us");
  // Every HTML file of a collecting site gets the form script.
  expect(aboutHtml).toContain('"/_casama/collect"');
  expect((await w.get(`${site}/about.html`)).status).toBe(200);
  expect(await (await w.get(`${site}/contact`)).text()).toContain("data-casama-form");
  expect(await (await w.get(`${site}/contact/`)).text()).toContain("data-casama-form");
  const logo = await w.get(`${site}/img/logo.png`);
  expect(logo.headers.get("content-type")).toBe("image/png");
  expect(logo.headers.get("cache-control")).toBe("public, max-age=300");
  const missing = await w.get(`${site}/nowhere`);
  expect(missing.status).toBe(404);
  expect(await missing.text()).toContain("Nothing here");
  expect((await w.get(`${site}/../about.html`)).status).toBeLessThan(500);
  expect((await w.get(`${site}/favicon.ico`)).status).toBe(204);
  expect(await (await w.get(`${site}/robots.txt`)).text()).toBe("User-agent: *\nDisallow: /\n");
  expect((await w.get(`${site}/sitemap.xml`)).status).toBe(404);
  expect((await w.get(`${site}/_casama/anything`)).status).toBe(404);
});

it("stores an answer sent to /_casama/collect", async () => {
  const res = await w.get(`${site}/_casama/collect`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ email: "visitor@example.com" }),
  });
  expect(res.status).toBe(201);
  const [row] = await w.h.tdb.admin<{ n: number }[]>`
    select count(*)::int as n from public.page_submissions where page_id = ${pageId}`;
  expect(row!.n).toBe(1);
});

it("a host under the zone with no site answers 404 and never reaches a pages route", async () => {
  const res = await w.get(`https://nobody.${ZONE}/robots.txt`);
  expect(res.status).toBe(404);
  expect(await res.text()).toContain("isn't available");
  expect((await w.get(`https://nobody.${ZONE}/s/anything`)).status).toBe(404);
  expect((await w.get(`https://deep.nobody.${ZONE}/`)).status).toBe(404);
});

it("sends a second host to the primary, keeping the path", async () => {
  const [d] = await w.h.tdb.admin<{ id: string }[]>`
    insert into public.domains (name, kind, org_id, target, verify_code)
    values ('crumb-bakery.com', 'connected', ${w.orgId}, 'd-aaaaaaaaaaaaaaaa.sites.example.com', 'c') returning id`;
  await w.h.tdb.admin`update public.site_hosts set is_primary = false where page_id = ${pageId}`;
  await w.h.tdb.admin`
    insert into public.site_hosts (hostname, kind, org_id, page_id, domain_id, is_primary, status, verified_at)
    values ('www.crumb-bakery.com', 'custom', ${w.orgId}, ${pageId}, ${d!.id}, true, 'active', now())`;
  clearHostCache();
  const moved = await w.get(`${site}/about?x=1`);
  expect(moved.status).toBe(301);
  expect(moved.headers.get("location")).toBe("https://www.crumb-bakery.com/about?x=1");
  const custom = await w.get("https://www.crumb-bakery.com/about");
  expect(custom.status).toBe(200);
  // Reports and answers still work on any host.
  expect((await w.get(`${site}/_casama/report`)).status).toBe(200);
  // A host without our proof is never served, whatever its state says.
  await w.h.tdb
    .admin`update public.site_hosts set verified_at = null where hostname = 'www.crumb-bakery.com'`;
  clearHostCache();
  expect((await w.get("https://www.crumb-bakery.com/")).status).toBe(404);
  // Back to the address as primary.
  await w.h.tdb.admin`delete from public.domains where id = ${d!.id}`;
  await w.h.tdb.admin`update public.site_hosts set is_primary = true where page_id = ${pageId}`;
  clearHostCache();
  expect((await w.get(`${site}/`)).status).toBe(200);
});

it("a private, trashed, taken-down or suspended site answers 404 on every host", async () => {
  const off = async () => (await w.get(`${site}/about`)).status;
  await w.h.tdb.admin`update public.pages set visibility = 'workspace' where id = ${pageId}`;
  expect(await off()).toBe(404);
  await w.h.tdb.admin`update public.pages set visibility = 'public' where id = ${pageId}`;
  expect(await off()).toBe(200);
  await w.h.tdb.admin`update public.creations set deleted_at = now() where page_id = ${pageId}`;
  expect(await off()).toBe(404);
  await w.h.tdb.admin`update public.creations set deleted_at = null where page_id = ${pageId}`;
  await w.h.tdb.admin`update public.creations set taken_down_at = now() where page_id = ${pageId}`;
  expect(await off()).toBe(404);
  await w.h.tdb.admin`update public.creations set taken_down_at = null where page_id = ${pageId}`;
  await w.h.tdb.admin`update public.organizations set suspended_at = now() where id = ${w.orgId}`;
  expect(await off()).toBe(404);
  await w.h.tdb.admin`update public.organizations set suspended_at = null where id = ${w.orgId}`;
  await w.h.tdb
    .admin`update public.pages set expires_at = now() - interval '1 minute' where id = ${pageId}`;
  expect(await off()).toBe(404);
  await w.h.tdb.admin`update public.pages set expires_at = null where id = ${pageId}`;
  expect(await off()).toBe(200);
});

it("the cache forgets a host when it changes through the API", async () => {
  expect((await w.get(`${site}/`)).status).toBe(200);
  await w.h.tdb.admin`update public.sites set label_changed_at = null where page_id = ${pageId}`;
  const res = await w.h.request(`/v1/pages/${pageId}/site`, {
    method: "PUT",
    token: w.owner.token,
    json: { label: "crumb-two" },
  });
  expect(res.status).toBe(200);
  expect((await w.get(`${site}/`)).status).toBe(404);
  expect((await w.get(`https://crumb-two.${ZONE}/`)).status).toBe(200);
  // Unpublish stops it at once on this server.
  await w.h.request(`/v1/pages/${pageId}/site`, { method: "DELETE", token: w.owner.token });
  expect((await w.get(`https://crumb-two.${ZONE}/`)).status).toBe(404);
  await w.h.request(`/v1/pages/${pageId}/site`, { method: "PUT", token: w.owner.token, json: {} });
  expect((await w.get(`https://crumb-two.${ZONE}/`)).status).toBe(200);
});

it("three reports take the site down on every address, and a report by address counts too", async () => {
  const host = `https://crumb-two.${ZONE}`;
  for (const ip of ["10.0.0.1", "10.0.0.2"]) {
    const r = await w.get(`${host}/_casama/report`, {
      method: "POST",
      headers: { "content-type": "application/x-www-form-urlencoded", "cf-connecting-ip": ip },
      body: "reason=phishing",
    });
    expect(r.status).toBe(200);
  }
  expect((await w.get(`${host}/`)).status).toBe(200);
  // The zone's own page reports by address, signed out.
  const byAddress = await w.h.request("/v1/site-reports", {
    method: "POST",
    headers: { "cf-connecting-ip": "10.0.0.3" },
    json: { address: `${host}/about`, reason: "pretends to be a bank" },
  });
  expect(byAddress.status).toBe(202);
  expect((await j(byAddress)).ok).toBe(true);
  expect((await w.get(`${host}/`)).status).toBe(404);
  const [p] = await w.h.tdb.admin<
    { visibility: string }[]
  >`select visibility from public.pages where id = ${pageId}`;
  expect(p!.visibility).toBe("private");
  // An unknown address gets the same answer.
  const unknown = await w.h.request("/v1/site-reports", {
    method: "POST",
    json: { address: "nothing.example.net", reason: "bad" },
  });
  expect(unknown.status).toBe(202);
});
