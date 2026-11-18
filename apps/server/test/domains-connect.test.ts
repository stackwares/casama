/** Connect a domain you own (docs/SITES-AND-DOMAINS-PLAN.md §7.3–§7.5, §7.13, §10 "Connecting"). */
import { afterAll, beforeAll, beforeEach, expect, it } from "vitest";
import { clearHostCache } from "../src/pages/hosts.ts";
import {
  checkDomain,
  type DomainsContext,
  dnsLookupFromEnv,
  domainsHourly,
  domainsMinute,
  hostnameProviderFromEnv,
} from "../src/sites/domains.ts";
import { type FakeCloudflare, startFakeCloudflare } from "./fake-cloudflare.ts";
import { type FakeDns, startFakeDns } from "./fake-dns.ts";
import { j } from "./helpers.ts";
import { type SitesWorld, startSitesWorld, ZONE } from "./sites-fixture.ts";

let w: SitesWorld;
let cf: FakeCloudflare;
let dns: FakeDns;
let ctx: DomainsContext;
let pageId = "";

const CF_NS = ["ada.ns.cloudflare.com", "bob.ns.cloudflare.com"];
const GODADDY_NS = ["ns01.domaincontrol.com", "ns02.domaincontrol.com"];

beforeAll(async () => {
  cf = await startFakeCloudflare(ZONE);
  dns = await startFakeDns();
  w = await startSitesWorld({ env: { ...cf.sitesEnv(), ...dns.env() } });
  const env = w.h.deps.env;
  ctx = {
    db: w.h.handle.db,
    env,
    zone: ZONE,
    provider: hostnameProviderFromEnv(env) as NonNullable<
      ReturnType<typeof hostnameProviderFromEnv>
    >,
    dns: dnsLookupFromEnv(env),
  };
  pageId = await w.publishFolder();
  expect(
    (
      await w.h.request(`/v1/pages/${pageId}/site`, {
        method: "PUT",
        token: w.owner.token,
        json: { label: "crumb" },
      })
    ).status,
  ).toBe(200);
}, 60_000);
afterAll(async () => {
  await w?.stop();
  await cf?.stop();
  await dns?.stop();
});
beforeEach(() => clearHostCache());

const connect = (
  name: string,
  extra: Record<string, unknown> = {},
  token = w.owner.token,
  org = w.orgId,
) => w.h.request(`/v1/orgs/${org}/domains`, { method: "POST", token, json: { name, ...extra } });
const hostRow = async (hostname: string) =>
  (
    await w.h.tdb.admin<
      {
        status: string;
        status_reason: string | null;
        verified_at: Date | null;
        provider_ref: string | null;
        is_primary: boolean;
      }[]
    >`select status, status_reason, verified_at, provider_ref, is_primary from public.site_hosts where hostname = ${hostname}`
  )[0];

it("tells the apps connected domains are on", async () => {
  const cfg = await j(await w.h.request("/v1/config"));
  expect(cfg.sites.custom_domains).toBe(true);
});

it("answers the records for a bare domain, a www and a subdomain", async () => {
  dns.set("crumb-bakery.com", { ns: CF_NS });
  const res = await connect("https://WWW.Crumb-Bakery.com/menu", { page_id: pageId });
  expect(res.status).toBe(201);
  const { domain } = await j(res);
  expect(domain.name).toBe("crumb-bakery.com");
  expect(domain.dns_provider).toBe("cloudflare");
  expect(domain.target).toMatch(new RegExp(`^d-[a-z0-9]{16}\\.${ZONE.replace(/\./g, "\\.")}$`));
  expect(domain.hosts.map((h: { hostname: string }) => h.hostname).sort()).toEqual([
    "crumb-bakery.com",
    "www.crumb-bakery.com",
  ]);
  expect(domain.state).toBe("waiting_dns");
  const cname = domain.records.find(
    (r: { type: string; name: string }) => r.type === "CNAME" && r.name === "www.crumb-bakery.com",
  );
  expect(cname).toMatchObject({ value: domain.target, purpose: "point", required: true });
  // Cloudflare DNS flattens a CNAME at the bare domain; the TXT is required there.
  const bareTxt = domain.records.find(
    (r: { type: string; host: string }) => r.type === "TXT" && r.host === "crumb-bakery.com",
  );
  expect(bareTxt).toMatchObject({ name: "_cf-custom-hostname.crumb-bakery.com", required: true });
  // Registered at the edge at once, for the ownership record.
  expect(cf.hostnameFor("www.crumb-bakery.com")).toBeTruthy();

  // A DNS company without ALIAS: the bare domain forwards to www, and gets no host of its own.
  dns.set("plain-bread.com", { ns: GODADDY_NS });
  const plain = (await j(await connect("plain-bread.com"))).domain;
  expect(plain.hosts.map((h: { hostname: string }) => h.hostname)).toEqual(["www.plain-bread.com"]);
  expect(plain.records.some((r: { type: string }) => r.type === "FORWARD")).toBe(true);
  expect(plain.records.find((r: { type: string }) => r.type === "TXT").required).toBe(false);

  // A subdomain is one host.
  const shop = (await j(await connect("shop.rye-house.co.uk"))).domain;
  expect(shop.name).toBe("shop.rye-house.co.uk");
  expect(shop.hosts).toHaveLength(1);

  for (const bad of ["192.168.1.1", "localhost", `x.${ZONE}`, "bücher.de"])
    expect((await connect(bad)).status, bad).toBe(400);
});

it("serves nothing before proof, even when the edge says active", async () => {
  cf.setHostname("www.crumb-bakery.com", "active");
  const [d] = await w.h.tdb.admin<
    { id: string }[]
  >`select id from public.domains where name = 'crumb-bakery.com'`;
  await checkDomain(ctx, d!.id);
  expect((await hostRow("www.crumb-bakery.com"))?.status).toBe("pending_dns");
  expect((await w.get("https://www.crumb-bakery.com/")).status).toBe(404);
  expect((await w.get(`https://crumb.${ZONE}/`)).status).toBe(200);
});

it("a CNAME to another domain's target is not proof; its own target is", async () => {
  const [mine] = await w.h.tdb.admin<{ id: string; target: string }[]>`
    select id, target from public.domains where name = 'crumb-bakery.com'`;
  const [other] = await w.h.tdb.admin<{ target: string }[]>`
    select target from public.domains where name = 'plain-bread.com'`;
  cf.setHostname("www.crumb-bakery.com", "pending");
  dns.set("www.crumb-bakery.com", { cname: other!.target });
  await checkDomain(ctx, mine!.id);
  expect((await hostRow("www.crumb-bakery.com"))?.status).toBe("pending_dns");
  // Two resolvers that disagree prove nothing either.
  dns.set("www.crumb-bakery.com", { cname: mine!.target });
  dns.staleB.set("www.crumb-bakery.com", { cname: "old.example.net" });
  await checkDomain(ctx, mine!.id);
  expect((await hostRow("www.crumb-bakery.com"))?.status).toBe("pending_dns");
  dns.staleB.clear();
  // Proof A: the CNAME ends at this domain's own target.
  await checkDomain(ctx, mine!.id);
  const row = await hostRow("www.crumb-bakery.com");
  expect(row?.status).toBe("pending_cert");
  expect(row?.verified_at).toBeTruthy();
  expect(cf.hostnameFor("www.crumb-bakery.com")?.patches.length).toBeGreaterThan(0);
  // Proof B for the bare domain: the TXT the edge gave this registration.
  const bare = cf.hostnameFor("crumb-bakery.com")!;
  dns.add(bare.ownership_verification.name, { txt: [bare.ownership_verification.value] });
  await checkDomain(ctx, mine!.id);
  expect((await hostRow("crumb-bakery.com"))?.status).toBe("pending_cert");
});

it("goes live when the edge has the certificate, and the site moves to the domain", async () => {
  const [d] = await w.h.tdb.admin<
    { id: string }[]
  >`select id from public.domains where name = 'crumb-bakery.com'`;
  cf.setHostname("www.crumb-bakery.com", "active");
  cf.setHostname("crumb-bakery.com", "active");
  await checkDomain(ctx, d!.id);
  expect((await hostRow("www.crumb-bakery.com"))?.status).toBe("active");
  expect((await hostRow("www.crumb-bakery.com"))?.is_primary).toBe(true);
  clearHostCache();
  const home = await w.get("https://www.crumb-bakery.com/");
  expect(home.status).toBe(200);
  expect(await home.text()).toContain("<h1>Crumb</h1>");
  const moved = await w.get(`https://crumb.${ZONE}/about`);
  expect(moved.status).toBe(301);
  expect(moved.headers.get("location")).toBe("https://www.crumb-bakery.com/about");
  const bare = await w.get("https://crumb-bakery.com/x?y=1");
  expect(bare.headers.get("location")).toBe("https://www.crumb-bakery.com/x?y=1");
  const [n] = await w.h.tdb.admin<{ n: number }[]>`
    select count(*)::int as n from public.notifications where kind = 'domain_live' and org_id = ${w.orgId}`;
  expect(n!.n).toBe(1);
  // The app's view.
  const view = await j(await w.h.request(`/v1/domains/${d!.id}`, { token: w.owner.token }));
  expect(view.state).toBe("live");
  expect(view.page_id).toBe(pageId);
  expect(
    view.records.find(
      (r: { name: string; type: string }) =>
        r.type === "CNAME" && r.name === "www.crumb-bakery.com",
    ).ok,
  ).toBe(true);
  expect(view.events.map((e: { kind: string }) => e.kind)).toContain("live");
});

it("disconnects after 7 days without proof, and Check Again brings it back", async () => {
  const [d] = await w.h.tdb.admin<{ id: string; target: string }[]>`
    select id, target from public.domains where name = 'crumb-bakery.com'`;
  dns.remove("www.crumb-bakery.com");
  await checkDomain(ctx, d!.id, false);
  const row = await hostRow("www.crumb-bakery.com");
  expect(row?.status).toBe("active");
  await w.h.tdb.admin`
    update public.site_hosts set proof_missing_since = now() - interval '8 days' where hostname = 'www.crumb-bakery.com'`;
  await checkDomain(ctx, d!.id, false);
  const gone = await hostRow("www.crumb-bakery.com");
  expect(gone?.status).toBe("disconnected");
  expect(gone?.status_reason).toBe("proof_gone");
  expect(cf.hostnameFor("www.crumb-bakery.com")).toBeUndefined();
  // The bare domain is still live, so it serves; the address is primary again otherwise.
  const [mail] = await w.h.tdb.admin<{ n: number }[]>`
    select count(*)::int as n from public.email_outbox where kind = 'domain_disconnected' and org_id = ${w.orgId}`;
  expect(mail!.n).toBe(1);
  // Check Again: back to waiting, registered at the edge again with a new ownership value.
  dns.set("www.crumb-bakery.com", { cname: d!.target });
  await checkDomain(ctx, d!.id, true);
  expect((await hostRow("www.crumb-bakery.com"))?.status).toBe("pending_cert");
  expect(cf.hostnameFor("www.crumb-bakery.com")).toBeTruthy();
  cf.setHostname("www.crumb-bakery.com", "active");
  await checkDomain(ctx, d!.id, false);
  expect((await hostRow("www.crumb-bakery.com"))?.status).toBe("active");
});

it("gives up on DNS after 7 days and on a certificate after 72 hours", async () => {
  const [d] = await w.h.tdb.admin<
    { id: string }[]
  >`select id from public.domains where name = 'plain-bread.com'`;
  await w.h.tdb.admin`
    update public.site_hosts set status_changed_at = now() - interval '8 days' where hostname = 'www.plain-bread.com'`;
  await checkDomain(ctx, d!.id, false);
  expect(await hostRow("www.plain-bread.com")).toMatchObject({
    status: "failed",
    status_reason: "not_pointed",
    provider_ref: null,
  });
  expect(cf.hostnameFor("www.plain-bread.com")).toBeUndefined();

  const [s] = await w.h.tdb.admin<{ id: string; target: string }[]>`
    select id, target from public.domains where name = 'shop.rye-house.co.uk'`;
  dns.set("shop.rye-house.co.uk", { cname: s!.target });
  await checkDomain(ctx, s!.id, false);
  expect((await hostRow("shop.rye-house.co.uk"))?.status).toBe("pending_cert");
  await w.h.tdb.admin`
    update public.site_hosts set status_changed_at = now() - interval '73 hours' where hostname = 'shop.rye-house.co.uk'`;
  await checkDomain(ctx, s!.id, false);
  expect((await hostRow("shop.rye-house.co.uk"))?.status).toBe("failed");
  expect((await hostRow("shop.rye-house.co.uk"))?.status_reason).toBe("timed_out");
});

it("upkeep checks waiting hosts every minute and leaves fresh ones alone", async () => {
  const [d] = await w.h.tdb.admin<{ id: string; target: string }[]>`
    select id, target from public.domains where name = 'shop.rye-house.co.uk'`;
  await checkDomain(ctx, d!.id, true);
  expect((await hostRow("shop.rye-house.co.uk"))?.status).toBe("pending_cert");
  // Just checked: not due.
  const r1 = await domainsMinute(ctx);
  expect(r1.changed.find((c) => c.hostname === "shop.rye-house.co.uk")).toBeUndefined();
  cf.setHostname("shop.rye-house.co.uk", "active");
  const later = { ...ctx, now: () => new Date(Date.now() + 61_000) };
  const r2 = await domainsMinute(later);
  expect(r2.changed).toContainEqual({
    hostname: "shop.rye-house.co.uk",
    from: "pending_cert",
    to: "active",
  });
});

it("an unproved claim gives way after an hour; a proved one only to a new proof", async () => {
  const other = await w.h.user(`claimer-${Date.now()}@example.com`);
  const otherOrg = (
    await j(
      await w.h.request("/v1/orgs", {
        method: "POST",
        token: other.token,
        json: { name: "Other" },
      }),
    )
  ).id as string;
  // plain-bread.com is unproved here and less than an hour old.
  const early = await connect("plain-bread.com", {}, other.token, otherOrg);
  expect(early.status).toBe(409);
  expect((await j(early)).code).toBe("domain_in_use");
  await w.h.tdb
    .admin`update public.domains set created_at = now() - interval '2 hours' where name = 'plain-bread.com'`;
  const taken = await connect("plain-bread.com", {}, other.token, otherOrg);
  expect(taken.status).toBe(201);
  expect((await j(taken)).domain.name).toBe("plain-bread.com");
  const [told] = await w.h.tdb.admin<{ n: number }[]>`
    select count(*)::int as n from public.notifications where kind = 'domain_disconnected' and org_id = ${w.orgId}
      and payload->>'title' like '%another workspace%'`;
  expect(told!.n).toBe(1);

  // crumb-bakery.com is proved here: the other workspace must prove it with its own record.
  const claim = await j(await connect("crumb-bakery.com", {}, other.token, otherOrg));
  expect(claim.domain).toBeNull();
  expect(claim.claim).toMatchObject({ type: "TXT", name: "_casama-claim.crumb-bakery.com" });
  const again = await j(await connect("crumb-bakery.com", {}, other.token, otherOrg));
  expect(again.claim.value).toBe(claim.claim.value);
  expect((await hostRow("www.crumb-bakery.com"))?.status).toBe("active");
  // Three claims a day per host.
  expect((await connect("crumb-bakery.com", {}, other.token, otherOrg)).status).toBe(201);
  expect((await connect("crumb-bakery.com", {}, other.token, otherOrg)).status).toBe(429);
  await w.h.tdb.admin`delete from public.domain_events where kind = 'claim_attempt'`;
  dns.set("_casama-claim.crumb-bakery.com", { txt: [claim.claim.value] });
  const moved = await j(await connect("crumb-bakery.com", {}, other.token, otherOrg));
  expect(moved.domain.name).toBe("crumb-bakery.com");
  expect((await hostRow("www.crumb-bakery.com"))?.status).toBe("pending_dns");
  // The old registrations were queued for removal at the edge.
  const [queued] = await w.h.tdb.admin<{ n: number }[]>`
    select count(*)::int as n from public.provider_cleanups where done_at is null`;
  expect(queued!.n).toBeGreaterThan(0);
  // The site is back on its own address.
  clearHostCache();
  expect((await w.get(`https://crumb.${ZONE}/`)).status).toBe(200);
});

it("cleanup retries after an edge error, and deleting a workspace removes its hostnames", async () => {
  cf.failNext(/DELETE .*custom_hostnames/, 1, 500);
  const first = await domainsMinute(ctx);
  expect(first.cleanupFailed).toBeGreaterThan(0);
  const second = await domainsMinute(ctx);
  expect(second.cleaned).toBeGreaterThan(0);
  const [open] = await w.h.tdb.admin<{ n: number }[]>`
    select count(*)::int as n from public.provider_cleanups where done_at is null`;
  expect(open!.n).toBe(0);

  // A throwaway workspace with a connected domain, then deleted.
  const temp = await w.h.user(`temp-${Date.now()}@example.com`);
  const tempOrg = (
    await j(
      await w.h.request("/v1/orgs", { method: "POST", token: temp.token, json: { name: "Temp" } }),
    )
  ).id as string;
  dns.set("gone-soon.com", { ns: CF_NS });
  expect((await connect("gone-soon.com", {}, temp.token, tempOrg)).status).toBe(201);
  expect(cf.hostnameFor("www.gone-soon.com")).toBeTruthy();
  await w.h.tdb.admin`delete from public.organizations where id = ${tempOrg}`;
  const r = await domainsMinute(ctx);
  expect(r.orphans).toBe(1);
  expect(cf.hostnameFor("www.gone-soon.com")).toBeUndefined();
  expect(cf.hostnameFor("gone-soon.com")).toBeUndefined();
});

it("the plan's domain limit: 402 to add, then a pause after 14 days, undone by upgrading", async () => {
  await w.h.tdb.admin`
    update public.entitlements set limits = limits || '{"max_custom_domains": 1}'::jsonb where org_id = ${w.orgId}`;
  const over = await connect("one-more.com");
  expect(over.status).toBe(402);
  expect((await j(over)).code).toBe("plan_limit");
  // shop.rye-house.co.uk is live; drop the limit to 0 and it goes over.
  await w.h.tdb.admin`
    update public.entitlements set limits = limits || '{"max_custom_domains": 0}'::jsonb where org_id = ${w.orgId}`;
  await domainsHourly(ctx);
  const [d] = await w.h.tdb.admin<{ id: string; over_limit_since: Date | null }[]>`
    select id, over_limit_since from public.domains where name = 'shop.rye-house.co.uk'`;
  expect(d!.over_limit_since).toBeTruthy();
  expect((await hostRow("shop.rye-house.co.uk"))?.status).toBe("active");
  const [notice] = await w.h.tdb.admin<{ n: number }[]>`
    select count(*)::int as n from public.notifications where kind = 'domain_plan_limit' and org_id = ${w.orgId}`;
  expect(notice!.n).toBe(1);
  await domainsHourly(ctx);
  const [same] = await w.h.tdb.admin<{ n: number }[]>`
    select count(*)::int as n from public.notifications where kind = 'domain_plan_limit' and org_id = ${w.orgId}`;
  expect(same!.n).toBe(1);
  await w.h.tdb.admin`
    update public.domains set over_limit_since = now() - interval '15 days' where id = ${d!.id}`;
  const r = await domainsHourly(ctx);
  expect(r.paused).toBe(1);
  expect(await hostRow("shop.rye-house.co.uk")).toMatchObject({
    status: "paused",
    status_reason: "plan_limit",
  });
  const [mail] = await w.h.tdb.admin<{ n: number }[]>`
    select count(*)::int as n from public.email_outbox where kind = 'domain_paused' and org_id = ${w.orgId}`;
  expect(mail!.n).toBe(1);
  // Upgrading brings it back within the hour.
  await w.h.tdb.admin`
    update public.entitlements set limits = limits - 'max_custom_domains' where org_id = ${w.orgId}`;
  const back = await domainsHourly(ctx);
  expect(back.resumed).toBe(1);
  expect((await hostRow("shop.rye-house.co.uk"))?.status).toBe("pending_cert");
  await checkDomain(ctx, d!.id, false);
  expect((await hostRow("shop.rye-house.co.uk"))?.status).toBe("active");
});

it("warns the instance owner at 80 custom hostnames", async () => {
  const usage = { used: 81, allocated: 100 };
  const r = await domainsHourly({
    ...ctx,
    provider: { ...ctx.provider, kind: ctx.provider.kind, usage: async () => usage } as never,
  });
  expect(r.warned).toBe(true);
  const again = await domainsHourly({
    ...ctx,
    provider: { ...ctx.provider, kind: ctx.provider.kind, usage: async () => usage } as never,
  });
  expect(again.warned).toBe(false);
});

it("routes: members read, admins change, others get nothing; Check Again is throttled", async () => {
  const [d] = await w.h.tdb.admin<
    { id: string }[]
  >`select id from public.domains where name = 'shop.rye-house.co.uk'`;
  const member = await w.h.user(`member-${Date.now()}@example.com`);
  await w.h.tdb
    .admin`insert into public.memberships (org_id, user_id, role) values (${w.orgId}, ${member.id}, 'member')`;
  expect((await w.h.request(`/v1/domains/${d!.id}`, { token: member.token })).status).toBe(200);
  expect((await w.h.request(`/v1/orgs/${w.orgId}/domains`, { token: member.token })).status).toBe(
    200,
  );
  expect((await connect("member-try.com", {}, member.token)).status).toBe(403);
  expect(
    (await w.h.request(`/v1/domains/${d!.id}/check`, { method: "POST", token: member.token }))
      .status,
  ).toBe(403);
  const stranger = await w.h.user(`stranger-${Date.now()}@example.com`);
  expect((await w.h.request(`/v1/domains/${d!.id}`, { token: stranger.token })).status).toBe(404);
  expect((await w.h.request(`/v1/domains/${d!.id}`)).status).toBe(401);

  await w.h.tdb.admin`update public.domains set checked_at = null where id = ${d!.id}`;
  expect(
    (await w.h.request(`/v1/domains/${d!.id}/check`, { method: "POST", token: w.owner.token }))
      .status,
  ).toBe(200);
  expect(
    (await w.h.request(`/v1/domains/${d!.id}/check`, { method: "POST", token: w.owner.token }))
      .status,
  ).toBe(429);

  // Point it at the site, choose the primary, then disconnect.
  const patched = await w.h.request(`/v1/domains/${d!.id}`, {
    method: "PATCH",
    token: w.owner.token,
    json: { page_id: pageId },
  });
  expect(patched.status).toBe(200);
  expect((await j(patched)).page_id).toBe(pageId);
  expect((await hostRow("shop.rye-house.co.uk"))?.is_primary).toBe(true);
  const back = await w.h.request(`/v1/domains/${d!.id}`, {
    method: "PATCH",
    token: w.owner.token,
    json: { primary_host: `crumb.${ZONE}` },
  });
  expect(back.status).toBe(404);
  expect(
    (await w.h.request(`/v1/domains/${d!.id}`, { method: "DELETE", token: w.owner.token })).status,
  ).toBe(204);
  const [gone] = await w.h.tdb.admin<
    { n: number }[]
  >`select count(*)::int as n from public.domains where id = ${d!.id}`;
  expect(gone!.n).toBe(0);
  clearHostCache();
  expect((await w.get(`https://crumb.${ZONE}/`)).status).toBe(200);
});

it("the bot's domains.connect points a domain the workspace has at its page, and asks first", async () => {
  expect(w.reg.get("domains.connect")?.risk).toBe("high");
  expect(w.reg.get("domains.connect")?.category).toBe("publish");
  dns.set("bot-bakery.com", { ns: CF_NS });
  await w.h.tdb.admin`
    update public.entitlements set limits = limits - 'max_custom_domains' where org_id = ${w.orgId}`;
  expect((await connect("bot-bakery.com")).status).toBe(201);
  const r = await w.tool("domains.connect", { domain: "bot-bakery.com", page_id: pageId });
  expect(r.content).toContain("once its DNS is set up");
  const [h] = await w.h.tdb.admin<{ page_id: string }[]>`
    select page_id from public.site_hosts where hostname = 'www.bot-bakery.com'`;
  expect(h!.page_id).toBe(pageId);
  await expect(
    w.tool("domains.connect", { domain: "not-ours.com", page_id: pageId }),
  ).rejects.toThrow(/no such domain/);
});
