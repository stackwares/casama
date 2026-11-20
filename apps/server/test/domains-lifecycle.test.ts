/**
 * Keeping a bought domain (docs/SITES-AND-DOMAINS-PLAN.md §7.8–§7.10, §10 Phase 4): with the clock
 * moved, a domain walks from 31 days before expiry through an automatic renewal, and another
 * through a failed charge, expiry and a late renewal, each notice once; lapsed and gone; DNS
 * records; the registrant reminders; moving out; a deleted workspace's domain released.
 */
import { afterAll, beforeAll, beforeEach, expect, it } from "vitest";
import { buyingFor } from "../src/api/routes/domains.ts";
import { clearHostCache } from "../src/pages/hosts.ts";
import { sendAccountEmails } from "../src/services/account-emails.ts";
import type { EmailMessage } from "../src/services/email.ts";
import { type BuyingContext, registerOrder } from "../src/sites/buying.ts";
import { domainsLifecycle, signedInRecently } from "../src/sites/lifecycle.ts";
import { billingEnv, type FakeBilling, startFakeBilling } from "./fake-billing.ts";
import { type FakeCloudflare, startFakeCloudflare } from "./fake-cloudflare.ts";
import { type FakeDns, startFakeDns } from "./fake-dns.ts";
import { type FakeRegistrar, registrarEnv, startFakeRegistrar } from "./fake-registrar.ts";
import { j } from "./helpers.ts";
import { type SitesWorld, startSitesWorld, ZONE } from "./sites-fixture.ts";

const DAY = 86_400_000;
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

const deliver = async (type: string, data: Record<string, unknown>) => {
  const wh = fb.dodo.webhook(type, data);
  return w.h.request("/hooks/billing/dodo", { method: "POST", headers: wh.headers, body: wh.body });
};
const pay = async (sessionId: string) => {
  const r = fb.dodo.complete(sessionId);
  if (r.subscriptionId)
    expect(
      (await deliver("subscription.active", { subscription_id: r.subscriptionId })).status,
    ).toBe(200);
  expect((await deliver("payment.succeeded", { payment_id: r.paymentId })).status).toBe(200);
  return r;
};
type Row = {
  id: string;
  status: string;
  expires_at: Date;
  target: string;
  locked: boolean;
  unlocked_at: Date | null;
  kind: string;
  auto_renew: boolean;
  released_at: Date | null;
  managed_records: string[];
  org_id: string | null;
};
const domain = async (name: string) =>
  (
    await w.h.tdb.admin<Row[]>`
      select id, status, expires_at, target, locked, unlocked_at, kind, auto_renew, released_at,
        managed_records, org_id
      from public.domains where name = ${name}`
  )[0] as Row;
const lastOrder = async (name: string) =>
  (
    await w.h.tdb.admin<
      {
        id: string;
        status: string;
        kind: string;
        payment_ref: string | null;
        checkout_ref: string | null;
      }[]
    >`select id, status, kind, payment_ref, checkout_ref from public.domain_orders where name = ${name}
      order by created_at desc limit 1`
  )[0];
const emails = async (kind: string) =>
  (
    await w.h.tdb.admin<{ n: number }[]>`
      select count(*)::int as n from public.email_outbox where kind = ${kind}`
  )[0]?.n ?? 0;
const notices = async (kind: string) =>
  (
    await w.h.tdb.admin<{ n: number }[]>`
      select count(*)::int as n from public.notifications where kind = ${kind} and org_id = ${w.orgId}`
  )[0]?.n ?? 0;

/** Expiry `days` from `base`, at Casama and the registrar alike. */
const expireIn = async (name: string, base: number, days: number) => {
  const at = new Date(base + days * DAY);
  await w.h.tdb.admin`update public.domains set expires_at = ${at} where name = ${name}`;
  const nc = reg.domains.get(name);
  if (nc) nc.expireDate = at.toISOString();
  return at;
};
const runAt = (base: number, days: number) =>
  domainsLifecycle({ ...ctx, now: () => new Date(base + days * DAY) });

/** Buys a name through the real flow (the first purchase makes the mandate). */
async function buy(name: string) {
  const res = await w.h.request(`/v1/orgs/${w.orgId}/domains/checkout`, {
    method: "POST",
    token: w.owner.token,
    json: { name, accept_terms: true, page_id: pageId },
  });
  expect(res.status).toBe(201);
  const body = await j(res);
  const o = await lastOrder(name);
  if (body.checkout_url) await pay(o?.checkout_ref as string);
  else
    expect((await deliver("payment.succeeded", { payment_id: o?.payment_ref })).status).toBe(200);
  expect((await lastOrder(name))?.status).toBe("done");
  return domain(name);
}

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
  w.h.deps.workflows.startDomainOrder = async (id) => void (await registerOrder(ctx, id));
  await w.h.tdb
    .admin`update public.organizations set created_at = now() - interval '40 days' where id = ${w.orgId}`;
  await w.h.tdb.admin`update auth.users set email_confirmed_at = now()`;
  await w.h.tdb.admin`
    update public.entitlements set limits = jsonb_set(limits, '{max_custom_domains}', to_jsonb(10::int))
    where org_id = ${w.orgId}`;
  pageId = await w.publishFolder();
  await w.h.request(`/v1/pages/${pageId}/site`, {
    method: "PUT",
    token: w.owner.token,
    json: { label: "crumb" },
  });
  expect(
    (
      await w.h.request(`/v1/orgs/${w.orgId}/domain-contact`, {
        method: "PUT",
        token: w.owner.token,
        json: CONTACT,
      })
    ).status,
  ).toBe(200);
  await buy("crumbkeep.com");
  await buy("crumblate.com");
}, 90_000);
afterAll(async () => {
  await w?.stop();
  await cf?.stop();
  await dns?.stop();
  await fb?.stop();
  await reg?.stop();
});
beforeEach(() => clearHostCache());

it("31 days out through an automatic renewal: each notice once, one charge, one year", async () => {
  const base = Date.now();
  const first = await expireIn("crumbkeep.com", base, 31);
  // Keep the other domain out of the way.
  await expireIn("crumblate.com", base, 200);
  await runAt(base, 0);
  expect(await emails("domain_renewal")).toBe(0);
  // E − 30: notice 1 with that day's price, once however often upkeep runs.
  await runAt(base, 1);
  await runAt(base, 1.1);
  expect(await emails("domain_renewal")).toBe(1);
  const [mail] = await w.h.tdb.admin<{ data: { price: string; auto: boolean } }[]>`
    select data from public.email_outbox where kind = 'domain_renewal'`;
  expect(mail?.data).toMatchObject({ price: "$16.99", auto: true });
  expect(fb.dodo.charges).toHaveLength(1); // the second purchase's charge only
  // E − 14: the mandate is charged at today's price; the paid webhook renews it.
  reg.prices.set("com", { purchase: 12.03, renewal: 13 });
  await runAt(base, 17);
  await runAt(base, 17.2);
  expect(fb.dodo.charges).toHaveLength(2);
  const o = await lastOrder("crumbkeep.com");
  expect(o).toMatchObject({ kind: "renew", status: "checkout" });
  expect((await deliver("payment.succeeded", { payment_id: o?.payment_ref })).status).toBe(200);
  expect((await deliver("payment.succeeded", { payment_id: o?.payment_ref })).status).toBe(200);
  expect((await lastOrder("crumbkeep.com"))?.status).toBe("done");
  expect(reg.renewals).toHaveLength(1);
  expect(reg.renewals[0]).toMatchObject({ name: "crumbkeep.com", clientReference: o?.id });
  const after = await domain("crumbkeep.com");
  expect(after.expires_at.getTime() - first.getTime()).toBe(365 * DAY);
  expect(after.status).toBe("active");
  expect(await emails("domain_renewed")).toBe(1);
  // Nothing more is due for a year.
  await runAt(base, 18);
  await runAt(base, 25);
  expect(fb.dodo.charges).toHaveLength(2);
  expect(await emails("domain_renewal")).toBe(1);
  reg.prices.set("com", { purchase: 12.03, renewal: 12.03 });
});

it("a failed charge, expiry, a late renewal by hand: each notice once", async () => {
  const base = Date.now();
  await expireIn("crumbkeep.com", base, 300);
  const e = await expireIn("crumblate.com", base, 14.5);
  // E − 14: the charge is declined.
  fb.dodo.failNextCharge = "failed";
  await runAt(base, 1);
  const o = await lastOrder("crumblate.com");
  expect(o?.kind).toBe("renew");
  expect((await deliver("payment.failed", { payment_id: o?.payment_ref })).status).toBe(200);
  expect((await lastOrder("crumblate.com"))?.status).toBe("abandoned");
  expect(await emails("domain_renewal_failed")).toBe(1);
  // The mandate is cancelled at Dodo: no more charges, every notice still sent.
  const [m] = await w.h.tdb.admin<{ mandate_ref: string }[]>`
    select mandate_ref from public.domain_contacts where org_id = ${w.orgId}`;
  const sub = fb.dodo.subs.get(m?.mandate_ref as string);
  if (sub) sub.status = "cancelled";
  await deliver("subscription.cancelled", { subscription_id: m?.mandate_ref });
  const charges = fb.dodo.charges.length;
  await runAt(base, 8); // E − 6.5: notice 2
  await runAt(base, 14); // E − 0.5: last notice
  expect(fb.dodo.charges).toHaveLength(charges);
  const steps = await w.h.tdb.admin<{ detail: { step: string } }[]>`
    select detail from public.domain_events where kind = 'renewal_notice'
      and domain_id = (select id from public.domains where name = 'crumblate.com') order by created_at`;
  expect(steps.map((s) => s.detail.step)).toEqual(["notice_30", "notice_7", "notice_1"]);
  // E: expired (the registrar agrees), then the expired notice at E + 3, once.
  await runAt(base, 15);
  expect((await domain("crumblate.com")).status).toBe("expired");
  await runAt(base, 18);
  await runAt(base, 18.5);
  expect(await emails("domain_expired")).toBe(1);
  // Renew Now: a checkout for one year at today's price; paid, it's active again, a year on.
  const res = await w.h.request(`/v1/domains/${(await domain("crumblate.com")).id}/renew`, {
    method: "POST",
    token: w.owner.token,
  });
  expect(res.status).toBe(201);
  const body = await j(res);
  expect(body.order).toMatchObject({ price_usd: 16.99 });
  expect(body.checkout_url).toContain("/pay/");
  // A second Renew Now while one is open: 409.
  expect(
    (
      await w.h.request(`/v1/domains/${(await domain("crumblate.com")).id}/renew`, {
        method: "POST",
        token: w.owner.token,
      })
    ).status,
  ).toBe(409);
  await pay((await lastOrder("crumblate.com"))?.checkout_ref as string);
  const renewed = await domain("crumblate.com");
  expect(renewed.status).toBe("active");
  expect(renewed.expires_at.getTime() - e.getTime()).toBe(365 * DAY);
  expect(await emails("domain_renewed")).toBe(2);
});

it("lapsed after 25 days, gone after the registry's time: hosts removed, history kept", async () => {
  const base = Date.now();
  const [row] = await w.h.tdb.admin<{ id: string }[]>`
    insert into public.domains (name, kind, org_id, target, verify_code, registrar, status, expires_at)
    values ('crumbold.com', 'registered', ${w.orgId}, ${`d-0000000000000old.${ZONE}`}, 'x', 'namecom', 'active',
      ${new Date(base + 0.5 * DAY)})
    returning id`;
  await w.h.tdb.admin`
    insert into public.site_hosts (hostname, kind, org_id, domain_id, status)
    values ('www.crumbold.com', 'custom', ${w.orgId}, ${row!.id}, 'pending_dns')`;
  await runAt(base, 1);
  expect((await domain("crumbold.com")).status).toBe("expired");
  await runAt(base, 26);
  expect((await domain("crumbold.com")).status).toBe("lapsed");
  // A lapsed domain can't be renewed here.
  const res = await w.h.request(`/v1/domains/${row!.id}/renew`, {
    method: "POST",
    token: w.owner.token,
  });
  expect(res.status).toBe(409);
  expect((await j(res)).code).toBe("restore_by_support");
  await runAt(base, 81);
  expect((await domain("crumbold.com")).status).toBe("gone");
  const hosts = await w.h.tdb.admin`select 1 from public.site_hosts where domain_id = ${row!.id}`;
  expect(hosts).toHaveLength(0);
  const kinds = (
    await w.h.tdb.admin<{ kind: string }[]>`
      select kind from public.domain_events where domain_id = ${row!.id} order by created_at`
  ).map((e) => e.kind);
  expect(kinds).toEqual(expect.arrayContaining(["expired", "lapsed", "gone"]));
});

it("DNS records: read live, checked, the site's own locked", async () => {
  const d = await domain("crumbkeep.com");
  const base = `/v1/domains/${d.id}/records`;
  const list = await j(await w.h.request(base, { token: w.owner.token }));
  const managed = list.items.find((r: { managed: boolean }) => r.managed);
  expect(managed).toMatchObject({ host: "www", type: "CNAME", answer: d.target });
  const mx = await w.h.request(base, {
    method: "POST",
    token: w.owner.token,
    json: { host: "@", type: "MX", answer: "mail.example.net", ttl: 3600, priority: 10 },
  });
  expect(mx.status).toBe(201);
  const added = await j(mx);
  expect(added).toMatchObject({ host: "", type: "MX", priority: 10, managed: false });
  // A CNAME beside the managed www CNAME is refused; so is a short TTL.
  const clash = await w.h.request(base, {
    method: "POST",
    token: w.owner.token,
    json: { host: "www", type: "TXT", answer: "hello", ttl: 300 },
  });
  expect(clash.status).toBe(400);
  expect((await j(clash)).code).toBe("invalid_record");
  const changed = await w.h.request(`${base}/${added.id}`, {
    method: "PATCH",
    token: w.owner.token,
    json: { answer: "mx2.example.net" },
  });
  expect(changed.status).toBe(200);
  expect((await j(changed)).answer).toBe("mx2.example.net");
  // The site's record can't be removed here.
  expect(
    (await w.h.request(`${base}/${managed.id}`, { method: "DELETE", token: w.owner.token })).status,
  ).toBe(400);
  expect(
    (await w.h.request(`${base}/${added.id}`, { method: "DELETE", token: w.owner.token })).status,
  ).toBe(204);
  expect(reg.records.get("crumbkeep.com")?.some((r) => r.type === "MX")).toBe(false);
  // A connected domain has no records here.
  const [c] = await w.h.tdb.admin<{ id: string }[]>`
    insert into public.domains (name, kind, org_id, target, verify_code)
    values ('crumbown.com', 'connected', ${w.orgId}, ${`d-0000000000000own.${ZONE}`}, 'x')
    returning id`;
  expect((await w.h.request(`/v1/domains/${c!.id}/records`, { token: w.owner.token })).status).toBe(
    409,
  );
});

it("a subdomain under a bought domain makes its own record", async () => {
  const res = await w.h.request(`/v1/orgs/${w.orgId}/domains`, {
    method: "POST",
    token: w.owner.token,
    json: { name: "shop.crumbkeep.com", page_id: pageId },
  });
  expect(res.status).toBe(201);
  const d = await domain("crumbkeep.com");
  const sub = await domain("shop.crumbkeep.com");
  const shop = reg.records.get("crumbkeep.com")?.find((r) => r.host === "shop");
  expect(shop).toMatchObject({ type: "CNAME", answer: sub.target });
  expect(d.managed_records).toContain(String(shop?.id));
  // Disconnected: the record goes too.
  expect(
    (await w.h.request(`/v1/domains/${sub.id}`, { method: "DELETE", token: w.owner.token })).status,
  ).toBe(204);
  expect(reg.records.get("crumbkeep.com")?.some((r) => r.host === "shop")).toBe(false);
});

it("registrant reminders on days 3, 7 and 12, once each; Send Again", async () => {
  const d = await domain("crumbkeep.com");
  // Earlier tests moved the clock past these days: start this one clean.
  await w.h.tdb.admin`delete from public.domain_events where kind = 'verify_reminder'`;
  await w.h.tdb.admin`delete from public.email_outbox where kind = 'domain_verify_email'`;
  await w.h.tdb.admin`delete from public.notifications where kind = 'domain_verify_email'`;
  await w.h.tdb
    .admin`update public.domains set created_at = now() - interval '3 days 2 hours' where id = ${d.id}`;
  await domainsLifecycle(ctx);
  await domainsLifecycle(ctx);
  expect(await emails("domain_verify_email")).toBe(1);
  await w.h.tdb
    .admin`update public.domains set created_at = now() - interval '7 days 2 hours' where id = ${d.id}`;
  await domainsLifecycle(ctx);
  expect(await emails("domain_verify_email")).toBe(2);
  expect(await notices("domain_verify_email")).toBe(2);
  const before = reg.requests.filter((r) => /\/contacts\/verify\/\d+:resend$/.test(r.path)).length;
  expect(
    (
      await w.h.request(`/v1/domains/${d.id}/verify-email`, {
        method: "POST",
        token: w.owner.token,
      })
    ).status,
  ).toBe(204);
  expect(reg.requests.filter((r) => /\/contacts\/verify\/\d+:resend$/.test(r.path))).toHaveLength(
    before + 1,
  );
  // Confirmed at the registrar: no more reminders.
  const nc = reg.domains.get("crumbkeep.com");
  if (nc) nc.contactVerification = { status: "verified" };
  await w.h.tdb
    .admin`update public.domains set checked_at = null, created_at = now() - interval '12 days 2 hours' where id = ${d.id}`;
  await domainsLifecycle(ctx);
  expect(await emails("domain_verify_email")).toBe(2);
});

it("Move to Another Registrar: owner, fresh sign-in, after the lock date, code once", async () => {
  const d = await domain("crumbkeep.com");
  const url = `/v1/domains/${d.id}/transfer-out`;
  const fresh = await w.h.tokenFor(w.owner, {
    amr: [{ method: "password", timestamp: Math.floor(Date.now() / 1000) }],
  });
  expect(signedInRecently({ amr: [{ timestamp: Math.floor(Date.now() / 1000) - 3600 }] })).toBe(
    false,
  );
  // Explicitly old proof: harness sessions represent fresh sign-ins by default.
  const oldToken = await w.h.tokenFor(w.owner, {
    amr: [{ method: "password", timestamp: Math.floor(Date.now() / 1000) - 3600 }],
  });
  const stale = await w.h.request(url, {
    method: "POST",
    token: oldToken,
    json: { confirm_name: "crumbkeep.com" },
  });
  expect(stale.status).toBe(401);
  expect((await j(stale)).code).toBe("reauthentication_needed");
  // Inside the 60-day lock: the date.
  const locked = await w.h.request(url, {
    method: "POST",
    token: fresh,
    json: { confirm_name: "crumbkeep.com" },
  });
  expect(locked.status).toBe(409);
  expect((await j(locked)).code).toBe("transfer_locked");
  await w.h.tdb
    .admin`update public.domains set transfer_after = now() - interval '1 day' where id = ${d.id}`;
  expect(
    (await w.h.request(url, { method: "POST", token: fresh, json: { confirm_name: "crumb.com" } }))
      .status,
  ).toBe(400);
  const ok = await w.h.request(url, {
    method: "POST",
    token: fresh,
    json: { confirm_name: "crumbkeep.com" },
  });
  expect(ok.status).toBe(200);
  const { code } = await j(ok);
  expect(code).toBe(reg.authCodes.at(-1));
  expect(reg.domains.get("crumbkeep.com")?.locked).toBe(false);
  expect(await emails("domain_transfer_code")).toBe(1);
  expect(await notices("domain_transfer_code")).toBe(1);
  // The code isn't stored anywhere.
  const stored = await w.h.tdb.admin`
    select 1 from public.domain_events where detail::text like ${`%${code}%`}`;
  expect(stored).toHaveLength(0);
  // Lock Again.
  const relock = await w.h.request(`/v1/domains/${d.id}`, {
    method: "PATCH",
    token: w.owner.token,
    json: { locked: true },
  });
  expect(relock.status).toBe(200);
  expect(reg.domains.get("crumbkeep.com")?.locked).toBe(true);
  // Unlocked and left: upkeep relocks after 14 days.
  await w.h.request(url, { method: "POST", token: fresh, json: { confirm_name: "crumbkeep.com" } });
  await domainsLifecycle({ ...ctx, now: () => new Date(Date.now() + 15 * DAY) });
  expect(reg.domains.get("crumbkeep.com")?.locked).toBe(true);
  expect((await domain("crumbkeep.com")).unlocked_at).toBeNull();
});

it("a finished transfer turns the domain into a connected one", async () => {
  const fresh = await w.h.tokenFor(w.owner, {
    amr: [{ method: "password", timestamp: Math.floor(Date.now() / 1000) }],
  });
  const d = await domain("crumbkeep.com");
  await w.h.request(`/v1/domains/${d.id}/transfer-out`, {
    method: "POST",
    token: fresh,
    json: { confirm_name: "crumbkeep.com" },
  });
  // The new registrar has it: gone from our account, and the registrar says so.
  reg.domains.delete("crumbkeep.com");
  const wh = reg.webhook("domain.transfer.out.completed", "crumbkeep.com");
  const res = await w.h.request(`/hooks/registrar/${ctx.registrar.id}`, {
    method: "POST",
    headers: wh.headers,
    body: wh.body,
  });
  expect(res.status).toBe(200);
  const after = await domain("crumbkeep.com");
  expect(after).toMatchObject({ kind: "connected", status: null, managed_records: [] });
  const [ev] = await w.h.tdb.admin`
    select 1 from public.domain_events where domain_id = ${d.id} and kind = 'moved_out'`;
  expect(ev).toBeTruthy();
});

it("a deleted workspace's domain: renewal off, hosts gone, one email to the registrant", async () => {
  const d = await domain("crumblate.com");
  // Moved to its own workspace, then that workspace is deleted.
  const other = (
    await j(
      await w.h.request("/v1/orgs", {
        method: "POST",
        token: w.owner.token,
        json: { name: "Gone" },
      }),
    )
  ).id as string;
  await w.h.tdb.admin`update public.domains set org_id = ${other} where id = ${d.id}`;
  await w.h.tdb.admin`update public.site_hosts set org_id = ${other} where domain_id = ${d.id}`;
  await w.h.tdb.admin`delete from public.organizations where id = ${other}`;
  const orphan = await domain("crumblate.com");
  expect(orphan.org_id).toBeNull();
  await domainsLifecycle(ctx);
  await domainsLifecycle(ctx);
  const released = await domain("crumblate.com");
  expect(released.auto_renew).toBe(false);
  expect(released.released_at).not.toBeNull();
  expect(
    await w.h.tdb.admin`select 1 from public.site_hosts where domain_id = ${d.id}`,
  ).toHaveLength(0);
  expect(await emails("domain_released")).toBe(1);
  // The email goes to the registrant's address, with no account behind it.
  const sent: EmailMessage[] = [];
  await sendAccountEmails(
    {
      db: w.h.handle.db,
      email: { enabled: true, send: async (m) => void sent.push(m) },
      env: {
        PUBLIC_APP_URL: "https://app.example.com",
        ACCOUNT_EMAILS: true,
        SUPABASE_JWT_SECRET: "x".repeat(40),
      } as never,
    },
    500,
  );
  const mail = sent.find((m) => m.subject.includes("stays yours"));
  expect(mail?.to).toBe("ada@crumb.example");
  expect(mail?.text).toContain("won't renew");
});
