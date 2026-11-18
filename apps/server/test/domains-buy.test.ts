/** Buying a domain (docs/SITES-AND-DOMAINS-PLAN.md §7.6, §7.7, §7.11, §10 "Buying"). */
import { registerSiteTools, ToolRegistry } from "@casama/agent";
import { domainPriceUsd } from "@casama/domain";
import { afterAll, beforeAll, beforeEach, expect, it } from "vitest";
import { buyingFor } from "../src/api/routes/domains.ts";
import { clearHostCache } from "../src/pages/hosts.ts";
import { type BuyingContext, ordersUpkeep, registerOrder } from "../src/sites/buying.ts";
import { checkDomain } from "../src/sites/domains.ts";
import { CallBudget } from "../src/sites/registrar.ts";
import { billingEnv, type FakeBilling, startFakeBilling } from "./fake-billing.ts";
import { type FakeCloudflare, startFakeCloudflare } from "./fake-cloudflare.ts";
import { type FakeDns, startFakeDns } from "./fake-dns.ts";
import { type FakeRegistrar, registrarEnv, startFakeRegistrar } from "./fake-registrar.ts";
import { j } from "./helpers.ts";
import { type SitesWorld, startSitesWorld, ZONE } from "./sites-fixture.ts";

let w: SitesWorld;
let cf: FakeCloudflare;
let dns: FakeDns;
let fb: FakeBilling;
let reg: FakeRegistrar;
let ctx: BuyingContext;
let pageId = "";

const CONTACT = {
  first_name: "Ada",
  last_name: "Baker",
  organization: "Crumb Bakery",
  address1: "1 Flour Street",
  city: "Portland",
  state: "OR",
  zip: "97201",
  country: "US",
  phone: "+1 503 555 0100",
  email: "ada@crumb.example",
};

beforeAll(async () => {
  cf = await startFakeCloudflare(ZONE);
  dns = await startFakeDns();
  fb = await startFakeBilling();
  reg = await startFakeRegistrar();
  w = await startSitesWorld({
    env: {
      ...cf.sitesEnv(),
      ...dns.env(),
      ...billingEnv(fb),
      ...registrarEnv(reg),
      DODO_DOMAIN_PRODUCT_ID: "pdt_domain",
      DODO_DOMAIN_RENEWAL_PRODUCT_ID: "pdt_sub_domains",
    },
  });
  ctx = buyingFor(w.h.deps) as BuyingContext;
  expect(ctx).toBeTruthy();
  // The worker's workflow, run in place: one attempt per start, as DBOS would on first run.
  w.h.deps.workflows.startDomainOrder = async (id) => void (await registerOrder(ctx, id));
  // An established workspace (past its first 30 days) on a plan with domains.
  await w.h.tdb
    .admin`update public.organizations set created_at = now() - interval '40 days' where id = ${w.orgId}`;
  // Publishing needs a confirmed email where billing is on (§7.11).
  await w.h.tdb.admin`update auth.users set email_confirmed_at = now()`;
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
  await fb?.stop();
  await reg?.stop();
});
beforeEach(() => clearHostCache());

const grantDomains = (orgId: string, n = 5) =>
  w.h.tdb.admin`
    update public.entitlements set limits = jsonb_set(limits, '{max_custom_domains}', to_jsonb(${n}::int))
    where org_id = ${orgId}`;
const search = (q: string, token = w.owner.token, org = w.orgId) =>
  w.h.request(`/v1/domains/search?org_id=${org}&q=${encodeURIComponent(q)}`, { token });
const checkout = (
  name: string,
  extra: Record<string, unknown> = {},
  org = w.orgId,
  token = w.owner.token,
) =>
  w.h.request(`/v1/orgs/${org}/domains/checkout`, {
    method: "POST",
    token,
    json: { name, accept_terms: true, ...extra },
  });
const putContact = (org = w.orgId, token = w.owner.token, contact: object = CONTACT) =>
  w.h.request(`/v1/orgs/${org}/domain-contact`, { method: "PUT", token, json: contact });
const deliver = async (type: string, data: Record<string, unknown>) => {
  const wh = fb.dodo.webhook(type, data);
  return w.h.request("/hooks/billing/dodo", { method: "POST", headers: wh.headers, body: wh.body });
};
/** Pays a checkout in the fake and delivers what Dodo sends. */
const pay = async (sessionId: string, times = 1) => {
  const r = fb.dodo.complete(sessionId);
  if (r.subscriptionId)
    expect(
      (await deliver("subscription.active", { subscription_id: r.subscriptionId })).status,
    ).toBe(200);
  for (let i = 0; i < times; i++)
    expect((await deliver("payment.succeeded", { payment_id: r.paymentId })).status).toBe(200);
  return r;
};
const order = async (name: string) =>
  (
    await w.h.tdb.admin<
      {
        id: string;
        status: string;
        failure: string | null;
        checkout_ref: string | null;
        payment_ref: string | null;
        domain_id: string | null;
        paid_at: Date | null;
        attempts: number;
      }[]
    >`select id, status, failure, checkout_ref, payment_ref, domain_id, paid_at, attempts from public.domain_orders where name = ${name} order by created_at desc limit 1`
  )[0];
const notices = async (kind: string, orgId: string | null = w.orgId) =>
  (
    await w.h.tdb.admin<{ n: number }[]>`
      select count(*)::int as n from public.notifications where kind = ${kind}
        and (${orgId}::uuid is null or org_id = ${orgId}::uuid)`
  )[0]?.n ?? 0;
const emails = async (kind: string) =>
  (
    await w.h.tdb.admin<
      { n: number }[]
    >`select count(*)::int as n from public.email_outbox where kind = ${kind}`
  )[0]?.n ?? 0;

it("tells the apps buying is on", async () => {
  const cfg = await j(await w.h.request("/v1/config"));
  expect(cfg.sites.buy_domains).toBe(true);
  expect(cfg.sites.tlds).toContain("com");
});

it("search prices follow the formula; premium, taken and off-list names can't be bought", async () => {
  reg.premium.add("crumbloaf.io");
  reg.taken.add("crumbloaf.net");
  const res = await search("crumb loaf");
  expect(res.status).toBe(200);
  const body = await j(res);
  const by = (n: string) => body.items.find((i: { name: string }) => i.name === n);
  expect(by("crumbloaf.com")).toMatchObject({
    available: true,
    reason: null,
    price_usd: domainPriceUsd(12.03),
    renew_price_usd: domainPriceUsd(12.03),
  });
  expect(by("crumbloaf.com").price_usd).toBe(16.99);
  // .xyz: cheap first year, dear renewal; both shown.
  expect(by("crumbloaf.xyz")).toMatchObject({
    price_usd: domainPriceUsd(2),
    renew_price_usd: domainPriceUsd(12),
  });
  expect(by("crumbloaf.io")).toMatchObject({
    available: false,
    reason: "premium",
    price_usd: null,
  });
  expect(by("crumbloaf.net")).toMatchObject({ available: false, reason: "taken" });
  // The registrar was asked once for every candidate.
  expect(reg.requests.filter((r) => r.path.endsWith(":checkAvailability"))).toHaveLength(1);
  // A second search inside a minute comes from the cache.
  await search("crumb loaf");
  expect(reg.requests.filter((r) => r.path.endsWith(":checkAvailability"))).toHaveLength(1);
  expect(
    (await j(await search("crumbloaf.shop"))).items.some((i: { name: string }) =>
      i.name.endsWith(".shop"),
    ),
  ).toBe(false);
});

it("checkout needs a paid plan, the terms and the registrant's details", async () => {
  // Free: no domains (decision 4).
  await grantDomains(w.orgId, 0);
  expect((await checkout("crumbloaf.com")).status).toBe(402);
  await grantDomains(w.orgId, 5);
  expect((await checkout("crumbloaf.com", { accept_terms: false })).status).toBe(400);
  const noContact = await checkout("crumbloaf.com");
  expect(noContact.status).toBe(409);
  expect((await j(noContact)).code).toBe("contact_required");
  expect((await putContact(w.orgId, w.owner.token, { ...CONTACT, country: "USA" })).status).toBe(
    400,
  );
  const saved = await putContact();
  expect(saved.status).toBe(200);
  const state = await j(
    await w.h.request(`/v1/orgs/${w.orgId}/domain-contact`, { token: w.owner.token }),
  );
  expect(state.contact).toMatchObject({
    first_name: "Ada",
    country: "US",
    email: "ada@crumb.example",
  });
  expect(state.default_email).toBe(w.owner.email);
  // Not on sale here, or premium.
  expect((await j(await checkout("crumbloaf.shop"))).code).toBe("not_sold");
  expect((await j(await checkout("crumbloaf.io"))).code).toBe("not_sold");
  expect((await j(await checkout("crumbloaf.net"))).code).toBe("name_taken");
});

it("two checkouts for one name: the second gets 409", async () => {
  const first = await checkout("crumbloaf.com", { page_id: pageId });
  expect(first.status).toBe(201);
  const { order: o, checkout_url } = await j(first);
  expect(o).toMatchObject({ name: "crumbloaf.com", price_usd: 16.99, status: "checkout" });
  expect(checkout_url).toContain("/pay/");
  // The checkout is for exactly the price, with the mandate for renewals (Renew automatically on).
  const ck = fb.dodo.checkouts.get((await order("crumbloaf.com"))?.checkout_ref as string);
  expect(ck?.on_demand?.product_price).toBe(1699);
  expect(ck?.product_id).toBe("pdt_sub_domains");
  expect(ck?.metadata.domain_order_id).toBe(o.id);
  const second = await checkout("crumbloaf.com");
  expect(second.status).toBe(409);
  expect((await j(second)).code).toBe("checkout_in_progress");
});

it("a paid webhook delivered three times registers once, with records, lock and privacy", async () => {
  const before = await order("crumbloaf.com");
  const paid = await pay(before?.checkout_ref as string, 3);
  const after = await order("crumbloaf.com");
  expect(after?.status).toBe("done");
  expect(reg.registrations).toHaveLength(1);
  expect(reg.registrations[0]).toMatchObject({
    name: "crumbloaf.com",
    clientReference: before?.id,
  });
  const nc = reg.domains.get("crumbloaf.com");
  expect(nc).toMatchObject({ locked: true, privacyEnabled: true, autorenewEnabled: false });
  expect(nc?.contacts.registrant).toMatchObject({ firstName: "Ada", phone: "+15035550100" });
  // The row: registered, a year, the transfer lock, the next price.
  const [d] = await w.h.tdb.admin<
    {
      id: string;
      kind: string;
      status: string;
      target: string;
      expires_at: Date;
      transfer_after: Date;
      managed_records: string[];
      renew_price_usd: string;
      auto_renew: boolean;
    }[]
  >`select id, kind, status, target, expires_at, transfer_after, managed_records, renew_price_usd::text, auto_renew from public.domains where name = 'crumbloaf.com'`;
  expect(d).toMatchObject({ kind: "registered", status: "active", auto_renew: true });
  expect(Number(d?.renew_price_usd)).toBe(16.99);
  expect(new Date(d!.transfer_after).getTime() - Date.now()).toBeGreaterThan(59 * 86_400_000);
  // DNS set by Casama: www → the target, the bare domain forwards to www (no ALIAS by default).
  const records = reg.records.get("crumbloaf.com") ?? [];
  expect(records).toEqual([
    expect.objectContaining({ host: "www", type: "CNAME", answer: d!.target }),
  ]);
  expect(d!.managed_records).toEqual([String(records[0]!.id)]);
  expect(reg.forwarding.get("crumbloaf.com")).toBe("https://www.crumbloaf.com");
  // The mandate is kept for renewals and the next purchase.
  const [c] = await w.h.tdb.admin<{ mandate_ref: string }[]>`
    select mandate_ref from public.domain_contacts where org_id = ${w.orgId}`;
  expect(c?.mandate_ref).toBe(paid.subscriptionId);
  const [r] = await w.h.tdb.admin<{ email: string }[]>`
    select email from public.domain_registrants where domain_id = ${d!.id}`;
  expect(r?.email).toBe("ada@crumb.example");
  expect(await notices("domain_registered")).toBe(1);
  expect(await emails("domain_registered")).toBe(1);
  // The order's state for the app.
  const view = await j(
    await w.h.request(`/v1/domain-orders/${before?.id}`, { token: w.owner.token }),
  );
  expect(view).toMatchObject({ status: "done", domain_id: d!.id });
  // The domain's screen: no records to add, the registrant step showing.
  const dv = await j(await w.h.request(`/v1/domains/${d!.id}`, { token: w.owner.token }));
  expect(dv).toMatchObject({
    kind: "registered",
    records: [],
    registrant_verified: false,
    page_id: pageId,
  });
});

it("after registration the host goes live with no DNS step by the person", async () => {
  const [d] = await w.h.tdb.admin<{ id: string; target: string }[]>`
    select id, target from public.domains where name = 'crumbloaf.com'`;
  // What the registrar's DNS answers once the record propagates.
  dns.set("www.crumbloaf.com", { cname: d!.target });
  await checkDomain(ctx, d!.id);
  cf.setHostname("www.crumbloaf.com", "active");
  await checkDomain(ctx, d!.id);
  const [h] = await w.h.tdb.admin<{ status: string }[]>`
    select status from public.site_hosts where hostname = 'www.crumbloaf.com'`;
  expect(h?.status).toBe("active");
  clearHostCache();
  const home = await w.get("https://www.crumbloaf.com/");
  expect(home.status).toBe(200);
  expect(await home.text()).toContain("<h1>Crumb</h1>");
});

it("the next purchase is charged on the saved mandate, with no browser step", async () => {
  const res = await checkout("crumbrolls.com");
  expect(res.status).toBe(201);
  const body = await j(res);
  expect(body.checkout_url).toBeNull();
  expect(fb.dodo.charges).toHaveLength(1);
  expect(fb.dodo.charges[0]?.amount).toBe(1699);
  const o = await order("crumbrolls.com");
  expect((await deliver("payment.succeeded", { payment_id: o?.payment_ref })).status).toBe(200);
  expect((await order("crumbrolls.com"))?.status).toBe("done");
  // A declined charge leaves nothing bought and frees the name.
  fb.dodo.failNextCharge = "failed";
  const declined = await j(await checkout("crumbbuns.com"));
  const o2 = await order("crumbbuns.com");
  expect(declined.order.status).toBe("checkout");
  expect((await deliver("payment.failed", { payment_id: o2?.payment_ref })).status).toBe(200);
  expect((await order("crumbbuns.com"))?.status).toBe("abandoned");
  expect(reg.domains.has("crumbbuns.com")).toBe(false);
});

it("the name gone between payment and registration is refunded by itself", async () => {
  // Without a saved mandate (cancelled at Dodo): a browser checkout again, from here on.
  const [m] = await w.h.tdb.admin<{ mandate_ref: string }[]>`
    select mandate_ref from public.domain_contacts where org_id = ${w.orgId}`;
  const mandate_ref = m?.mandate_ref as string;
  const sub = fb.dodo.subs.get(mandate_ref);
  if (sub) sub.status = "cancelled";
  expect((await deliver("subscription.cancelled", { subscription_id: mandate_ref })).status).toBe(
    200,
  );
  const c = await j(await checkout("crumbcake.com", { auto_renew: false }));
  expect(c.checkout_url).toContain("/pay/");
  const ref = (await order("crumbcake.com"))?.checkout_ref as string;
  // A Pay What You Want checkout for exactly the price when there's no mandate to keep.
  expect(fb.dodo.checkouts.get(ref)).toMatchObject({ product_id: "pdt_domain", amount: 1699 });
  reg.taken.add("crumbcake.com");
  const paid = await pay(ref);
  const o = await order("crumbcake.com");
  expect(o).toMatchObject({ status: "refunded", failure: "name_gone" });
  expect(fb.dodo.refunds.map((r) => r.paymentId)).toContain(paid.paymentId);
  expect(await notices("domain_order_failed")).toBeGreaterThanOrEqual(1);
  expect(await emails("domain_order_failed")).toBe(1);
  // The name is free to try again later.
  expect(reg.registrations.some((r) => r.name === "crumbcake.com")).toBe(false);
});

it("the cost rising over a dollar refunds instead of registering", async () => {
  const ref =
    (await j(await checkout("crumbpie.com", { auto_renew: false }))) &&
    (await order("crumbpie.com"))?.checkout_ref;
  reg.prices.set("com", { purchase: 14.5, renewal: 14.5 });
  try {
    await pay(ref as string);
  } finally {
    reg.prices.set("com", { purchase: 12.03, renewal: 12.03 });
  }
  expect(await order("crumbpie.com")).toMatchObject({ status: "refunded", failure: "cost_rose" });
});

it("a registrar error is retried, then refunded after a day", async () => {
  await j(await checkout("crumbtart.com", { auto_renew: false }));
  reg.failNext("crumbtart.com", 503, 1000);
  await pay((await order("crumbtart.com"))?.checkout_ref as string);
  const o = await order("crumbtart.com");
  expect(o?.status).toBe("registering");
  expect(o?.attempts).toBe(1);
  // Too soon: the attempt waits for its time.
  expect(await registerOrder(ctx, o!.id)).toBe("retry");
  expect((await order("crumbtart.com"))?.attempts).toBe(1);
  const later = new Date(new Date(o!.paid_at as Date).getTime() + 25 * 3_600_000);
  expect(await registerOrder({ ...ctx, now: () => later }, o!.id)).toBe("refunded");
  expect(await order("crumbtart.com")).toMatchObject({
    status: "refunded",
    failure: "registrar_unavailable",
  });
  reg.failNext("crumbtart.com", 503, 0);
});

it("a refund that fails goes to needs_attention, tells the owner, and Retry finishes it", async () => {
  await j(await checkout("crumbscone.com", { auto_renew: false }));
  reg.taken.add("crumbscone.com");
  fb.dodo.failRefunds = true;
  await pay((await order("crumbscone.com"))?.checkout_ref as string);
  const o = await order("crumbscone.com");
  expect(o?.status).toBe("needs_attention");
  expect(o?.failure).toMatch(/^name_gone; refund failed/);
  expect(await notices("domain_order_attention", null)).toBe(1);
  // Admin → Domains shows it.
  const overview = await j(await w.h.request("/v1/admin/domains", { token: w.owner.token }));
  expect(overview.orders.map((x: { id: string }) => x.id)).toContain(o!.id);
  expect(overview.balance_usd).toBeGreaterThan(0);
  expect(overview.counts.registered).toBeGreaterThanOrEqual(2);
  fb.dodo.failRefunds = false;
  const retried = await w.h.request(`/v1/admin/domain-orders/${o!.id}/retry`, {
    method: "POST",
    token: w.owner.token,
  });
  expect(retried.status).toBe(200);
  expect((await j(retried)).status).toBe("refunded");
});

it("an amount that doesn't match the price is refunded", async () => {
  await j(await checkout("crumbmuffin.com", { auto_renew: false }));
  const r = fb.dodo.complete((await order("crumbmuffin.com"))?.checkout_ref as string);
  const p = fb.dodo.payments.get(r.paymentId);
  if (p) p.total_amount = 100;
  await deliver("payment.succeeded", { payment_id: r.paymentId });
  expect(await order("crumbmuffin.com")).toMatchObject({
    status: "refunded",
    failure: "amount_mismatch",
  });
  expect(reg.domains.has("crumbmuffin.com")).toBe(false);
});

it("a new workspace's first purchase waits for an instance owner", async () => {
  const other = await w.h.user(`new-${Math.random().toString(36).slice(2)}@example.com`);
  const orgId = (
    await j(
      await w.h.request("/v1/orgs", { method: "POST", token: other.token, json: { name: "New" } }),
    )
  ).id as string;
  await grantDomains(orgId);
  expect((await putContact(orgId, other.token)).status).toBe(200);
  // Not an admin of that workspace: 404 for the owner of the first.
  expect((await checkout("newbread.com", {}, orgId)).status).toBe(404);
  const c = await j(await checkout("newbread.com", { auto_renew: false }, orgId, other.token));
  expect(c.order.needs_approval).toBe(true);
  await pay((await order("newbread.com"))?.checkout_ref as string);
  expect((await order("newbread.com"))?.status).toBe("paid");
  expect(reg.domains.has("newbread.com")).toBe(false);
  expect(await notices("domain_order_approval", null)).toBe(1);
  // Only an instance owner approves.
  const id = (await order("newbread.com"))?.id;
  expect(
    (
      await w.h.request(`/v1/admin/domain-orders/${id}/approve`, {
        method: "POST",
        token: other.token,
      })
    ).status,
  ).toBe(403);
  const ok = await w.h.request(`/v1/admin/domain-orders/${id}/approve`, {
    method: "POST",
    token: w.owner.token,
  });
  expect(ok.status).toBe(200);
  expect((await order("newbread.com"))?.status).toBe("done");
  expect(reg.domains.has("newbread.com")).toBe(true);
});

it("the purchase caps hold (3 in a workspace's first 30 days)", async () => {
  const other = await w.h.user(`caps-${Math.random().toString(36).slice(2)}@example.com`);
  const orgId = (
    await j(
      await w.h.request("/v1/orgs", { method: "POST", token: other.token, json: { name: "Caps" } }),
    )
  ).id as string;
  await grantDomains(orgId, 20);
  await putContact(orgId, other.token);
  for (const n of ["capone.com", "captwo.com", "capthree.com"])
    expect((await checkout(n, { auto_renew: false }, orgId, other.token)).status).toBe(201);
  const fourth = await checkout("capfour.com", { auto_renew: false }, orgId, other.token);
  expect(fourth.status).toBe(429);
  expect((await j(fourth)).code).toBe("purchase_cap");
});

it("registrar webhooks are verified, stored once, and the domain is read again", async () => {
  const nc = reg.domains.get("crumbloaf.com");
  if (nc) nc.contactVerification = { status: "verified" };
  const wh = reg.webhook("contactVerificationApproved", "crumbloaf.com");
  const send = (h: Record<string, string>, body: string) =>
    w.h.request("/hooks/registrar/namecom", { method: "POST", headers: h, body });
  expect((await j(await send(wh.headers, wh.body))).duplicate).toBe(false);
  expect((await j(await send(wh.headers, wh.body))).duplicate).toBe(true);
  const bad = reg.webhook("contactVerificationApproved", "crumbloaf.com", { secret: "wrong" });
  expect((await send(bad.headers, bad.body)).status).toBe(401);
  const [d] = await w.h.tdb.admin<{ id: string; registrant_verified_at: Date | null }[]>`
    select id, registrant_verified_at from public.domains where name = 'crumbloaf.com'`;
  expect(d?.registrant_verified_at).toBeTruthy();
  expect(
    (await j(await w.h.request(`/v1/domains/${d!.id}`, { token: w.owner.token })))
      .registrant_verified,
  ).toBe(true);
  // The registrar's own auto-renew found on is turned back off.
  if (nc) nc.autorenewEnabled = true;
  const again = reg.webhook("domainLockChanged", "crumbloaf.com");
  await send(again.headers, again.body);
  expect(reg.domains.get("crumbloaf.com")?.autorenewEnabled).toBe(false);
});

it("Suspend stops the site, locks the domain and removes its records; Unsuspend restores them", async () => {
  const [d] = await w.h.tdb.admin<
    { id: string }[]
  >`select id from public.domains where name = 'crumbloaf.com'`;
  const s = await w.h.request(`/v1/admin/domains/${d!.id}/suspend`, {
    method: "POST",
    token: w.owner.token,
  });
  expect(s.status).toBe(204);
  const [h] = await w.h.tdb.admin<{ status: string }[]>`
    select status from public.site_hosts where hostname = 'www.crumbloaf.com'`;
  expect(h?.status).toBe("suspended");
  expect(reg.records.get("crumbloaf.com")).toEqual([]);
  expect(reg.forwarding.has("crumbloaf.com")).toBe(false);
  clearHostCache();
  expect((await w.get("https://www.crumbloaf.com/")).status).toBe(404);
  const overview = await j(await w.h.request("/v1/admin/domains", { token: w.owner.token }));
  expect(overview.domains.find((x: { id: string }) => x.id === d!.id)?.suspended).toBe(true);
  const u = await w.h.request(`/v1/admin/domains/${d!.id}/unsuspend`, {
    method: "POST",
    token: w.owner.token,
  });
  expect(u.status).toBe(204);
  expect((reg.records.get("crumbloaf.com") ?? []).some((r) => r.type === "CNAME")).toBe(true);
  const [h2] = await w.h.tdb.admin<{ status: string }[]>`
    select status from public.site_hosts where hostname = 'www.crumbloaf.com'`;
  expect(h2?.status).toBe("pending_dns");
});

it("billing audit 2026-11-17: a charge reversed after registration suspends the domain", async () => {
  expect((await checkout("crumbfold.com", { auto_renew: false })).status).toBe(201);
  const o = await order("crumbfold.com");
  // Charged on the saved mandate (an earlier purchase made one), or through a checkout.
  const paymentId = o?.checkout_ref
    ? (await pay(o.checkout_ref)).paymentId
    : (o?.payment_ref as string);
  if (!o?.checkout_ref)
    expect((await deliver("payment.succeeded", { payment_id: paymentId })).status).toBe(200);
  expect((await order("crumbfold.com"))?.status).toBe("done");
  const ownerNotices = await notices("domain_order_attention", null);
  // The card holder disputes the charge and wins.
  expect(
    (await deliver("dispute.lost", { payment_id: paymentId, dispute_id: "dp_1" })).status,
  ).toBe(200);
  const [d] = await w.h.tdb.admin<{ id: string; status: string; locked: boolean }[]>`
    select id, status, locked from public.domains where name = 'crumbfold.com'`;
  expect(d).toMatchObject({ status: "suspended", locked: true });
  expect(await notices("domain_order_attention", null)).toBe(ownerNotices + 1);
  // No transfer code for a suspended domain.
  const t = await w.h.request(`/v1/domains/${d!.id}/transfer-out`, {
    method: "POST",
    token: w.owner.token,
    json: { confirm_name: "crumbfold.com" },
  });
  expect(t.status).toBeGreaterThanOrEqual(400);
});

it("upkeep abandons unpaid checkouts and warns owners when the registrar balance is low", async () => {
  await j(await checkout("crumbstale.com", { auto_renew: false }));
  await w.h.tdb
    .admin`update public.domain_orders set created_at = now() - interval '25 hours' where name = 'crumbstale.com'`;
  reg.balance = 20;
  const r = await ordersUpkeep(ctx);
  expect(r.abandoned).toBe(1);
  expect(r.warned).toBe(true);
  expect((await order("crumbstale.com"))?.status).toBe("abandoned");
  expect((await ordersUpkeep(ctx)).warned).toBe(false);
  reg.balance = 5000;
});

it("domains.search answers names, prices and the Find a Domain link; it never buys", async () => {
  const tools = new ToolRegistry();
  registerSiteTools(tools, {
    db: w.h.handle.db,
    zone: ZONE,
    domainSearch: async () => ({
      items: [
        {
          name: "crumbloaf.dev",
          available: true,
          reason: null,
          price_usd: 16.49,
          renew_price_usd: 18.99,
        },
        {
          name: "crumbloaf.io",
          available: false,
          reason: "premium",
          price_usd: null,
          renew_price_usd: null,
        },
      ],
      findUrl: (n) => `https://app.example.com/settings/domains/find?q=${n}`,
    }),
  });
  const tool = tools.get("domains.search");
  expect(tool?.risk).toBe("low");
  const out = await tool!.execute({ query: "crumb loaf" }, { orgId: w.orgId } as never);
  expect(out.content).toContain("crumbloaf.dev: $16.49");
  expect(out.content).toContain("find?q=crumbloaf.dev");
  expect(out.content).not.toContain("crumbloaf.io");
  expect(
    tools
      .available({ computer: true, desktop: true, vision: true })
      .some((t) => /^domains\.(buy|renew|transfer)/.test(t.name)),
  ).toBe(false);
});

it("the call budget keeps search from using up the registrar's hour", async () => {
  const b = new CallBudget(5, 2, 0);
  await b.take("search");
  await b.take("search");
  await expect(b.take("search")).rejects.toMatchObject({ status: 429 });
  await b.take("order");
  await b.take("order");
  await b.take("order");
  await expect(b.take("order")).rejects.toMatchObject({ status: 429 });
});

it("a payment in another currency counts only through its dollar settlement amount", async () => {
  // Paid in euros, no dollar settlement: the euro cents are never read as dollars.
  await j(await checkout("crumbeuro.com", { auto_renew: false }));
  const r = fb.dodo.complete((await order("crumbeuro.com"))?.checkout_ref as string);
  const p = fb.dodo.payments.get(r.paymentId);
  if (p) p.currency = "EUR";
  await deliver("payment.succeeded", { payment_id: r.paymentId });
  expect(await order("crumbeuro.com")).toMatchObject({
    status: "refunded",
    failure: "amount_mismatch",
  });
  expect(reg.domains.has("crumbeuro.com")).toBe(false);

  // Paid in yen with Dodo's dollar settlement matching the price: it goes through.
  await j(await checkout("crumbyen.com", { auto_renew: false }));
  const r2 = fb.dodo.complete((await order("crumbyen.com"))?.checkout_ref as string);
  const p2 = fb.dodo.payments.get(r2.paymentId);
  if (p2)
    Object.assign(p2, {
      currency: "JPY",
      settlement_currency: "USD",
      settlement_amount: p2.total_amount,
      settlement_tax: 0,
      total_amount: p2.total_amount * 150,
    });
  await deliver("payment.succeeded", { payment_id: r2.paymentId });
  expect((await order("crumbyen.com"))?.status).not.toBe("refunded");
  expect((await order("crumbyen.com"))?.failure).toBeNull();
});
