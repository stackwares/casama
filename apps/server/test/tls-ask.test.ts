/**
 * A self-hosted server's Caddy asks before every on-demand certificate
 * (docs/SITES-AND-DOMAINS-PLAN.md §7.12, §10 "Self-host"): yes only for live site addresses and
 * domain hosts Casama has proof for.
 */
import { afterAll, beforeAll, beforeEach, expect, it } from "vitest";
import { clearHostCache } from "../src/pages/hosts.ts";
import { OwnEdgeHostnames } from "../src/sites/hostnames.ts";
import { j } from "./helpers.ts";
import { type SitesWorld, startSitesWorld, ZONE } from "./sites-fixture.ts";

let w: SitesWorld;
let domainId = "";

beforeAll(async () => {
  w = await startSitesWorld({ env: { CASAMA_SITES_OWN_EDGE: "true" } });
  const pageId = await w.publishFolder();
  await w.h.request(`/v1/pages/${pageId}/site`, {
    method: "PUT",
    token: w.owner.token,
    json: { label: "crumb" },
  });
  const [d] = await w.h.tdb.admin<{ id: string }[]>`
    insert into public.domains (name, kind, org_id, target, verify_code)
    values ('own-bakery.com', 'connected', ${w.orgId}, 'd-bbbbbbbbbbbbbbbb.sites.example.com', 'c') returning id`;
  domainId = d!.id;
  await w.h.tdb.admin`
    insert into public.site_hosts (hostname, kind, org_id, page_id, domain_id, status)
    values ('www.own-bakery.com', 'custom', ${w.orgId}, ${pageId}, ${domainId}, 'pending_dns')`;
}, 60_000);
afterAll(async () => w?.stop());
beforeEach(() => clearHostCache());

const ask = (domain: string) =>
  w.h.request(`/internal/tls-ask?domain=${encodeURIComponent(domain)}`);

it("says yes for a live site address, without the internal token", async () => {
  expect((await ask(`crumb.${ZONE}`)).status).toBe(200);
  expect((await ask(`CRUMB.${ZONE}.`)).status).toBe(200);
});

it("says no for any other name, including free labels under the zone", async () => {
  expect((await ask(`nobody.${ZONE}`)).status).toBe(404);
  expect((await ask("example.org")).status).toBe(404);
  expect((await ask("")).status).toBe(404);
  // The other internal routes still need the token.
  expect((await w.h.request("/internal/abuse", { method: "POST", json: {} })).status).toBe(401);
});

it("says yes for a domain host only once Casama has proof", async () => {
  expect((await ask("www.own-bakery.com")).status).toBe(404);
  await w.h.tdb.admin`
    update public.site_hosts set verified_at = now(), status = 'pending_cert' where hostname = 'www.own-bakery.com'`;
  clearHostCache();
  expect((await ask("www.own-bakery.com")).status).toBe(200);
  await w.h.tdb.admin`
    update public.site_hosts set status = 'suspended' where hostname = 'www.own-bakery.com'`;
  clearHostCache();
  expect((await ask("www.own-bakery.com")).status).toBe(404);
});

it("tells the apps connected domains work with the server's own edge", async () => {
  const cfg = await j(await w.h.request("/v1/config"));
  expect(cfg.sites.custom_domains).toBe(true);
});

it("the own edge makes a new ownership value every time, and is live once the probe answers", async () => {
  const fetchVia = (async (url: string) =>
    w.get(String(url), { headers: { host: new URL(String(url)).host } })) as typeof fetch;
  const edge = new OwnEdgeHostnames({ instanceId: "instance-test-1", fetch: fetchVia });
  const a = await edge.add("www.own-bakery.com");
  const b = await edge.add("www.own-bakery.com");
  expect(a.ownership.name).toBe("_casama.www.own-bakery.com");
  expect(a.ownership.value).not.toBe(b.ownership.value);
  expect(await edge.get(a.ref)).toEqual({ state: "active" });
  const wrong = new OwnEdgeHostnames({ instanceId: "someone-else", fetch: fetchVia });
  expect((await wrong.get(a.ref))?.state).toBe("pending");
});
