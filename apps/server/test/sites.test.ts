/** Publish to the Web (docs/SITES-AND-DOMAINS-PLAN.md §7.2, §7.15, §10 "Publishing"). */
import { afterAll, beforeAll, expect, it } from "vitest";
import { j } from "./helpers.ts";
import { type SitesWorld, startSitesWorld, ZONE } from "./sites-fixture.ts";

let w: SitesWorld;

beforeAll(async () => {
  w = await startSitesWorld();
}, 60_000);
afterAll(async () => w?.stop());

const publish = (pageId: string, json: unknown, token = w.owner.token) =>
  w.h.request(`/v1/pages/${pageId}/site`, { method: "PUT", token, json });

it("tells the apps about sites in the public config", async () => {
  const cfg = await j(await w.h.request("/v1/config"));
  expect(cfg.sites).toEqual({ zone: ZONE, custom_domains: false, buy_domains: false, tlds: [] });
});

it("publishing makes the page public and reserves its address", async () => {
  const pageId = await w.publishFolder("Rye House");
  const res = await publish(pageId, { label: "rye-house" });
  expect(res.status).toBe(200);
  const site = await j(res);
  expect(site).toMatchObject({
    page_id: pageId,
    label: "rye-house",
    address_url: `https://rye-house.${ZONE}`,
    url: `https://rye-house.${ZONE}`,
    live: true,
    indexable: false,
    badge: true,
  });
  expect(site.hosts).toHaveLength(1);
  const [p] = await w.h.tdb.admin<{ visibility: string; expires_at: Date | null }[]>`
    select visibility, expires_at from public.pages where id = ${pageId}`;
  expect(p).toEqual({ visibility: "public", expires_at: null });
  const list = await j(await w.h.request(`/v1/orgs/${w.orgId}/sites`, { token: w.owner.token }));
  expect(list.items.map((s: { page_id: string }) => s.page_id)).toContain(pageId);
  // Without a name, one comes from the title.
  const other = await w.publishFolder("Sour Dough Co");
  expect((await j(await publish(other, {}))).label).toBe("sour-dough-co");
});

it("refuses taken, reserved, brand and retired names", async () => {
  const pageId = await w.publishFolder("Another");
  const taken = await publish(pageId, { label: "rye-house" });
  expect(taken.status).toBe(409);
  expect((await j(taken)).code).toBe("address_taken");
  for (const label of ["admin", "paypal-login", "d-1234567890abcdef", "ab", "-x-"]) {
    const res = await publish(pageId, { label });
    expect(res.status, label).toBe(400);
    expect((await j(res)).code).toBe("address_invalid");
  }
  const check = await j(
    await w.h.request(`/v1/sites/address?org_id=${w.orgId}&label=rye-house`, {
      token: w.owner.token,
    }),
  );
  expect(check).toMatchObject({ available: false, reason: "taken" });
  const free = await j(
    await w.h.request(`/v1/sites/address?org_id=${w.orgId}&label=fresh-name`, {
      token: w.owner.token,
    }),
  );
  expect(free).toMatchObject({ available: true, url: `https://fresh-name.${ZONE}` });
  // A deleted site's name is retired for 90 days, except for its own workspace.
  await w.h.tdb
    .admin`insert into public.site_labels_retired (label, org_id) values ('old-name', null)`;
  const retired = await publish(pageId, { label: "old-name" });
  expect(retired.status).toBe(409);
  await w.h.tdb
    .admin`update public.site_labels_retired set org_id = ${w.orgId} where label = 'old-name'`;
  expect((await publish(pageId, { label: "old-name" })).status).toBe(200);
});

it("changes a name once a day and retires the old one", async () => {
  const pageId = await w.publishFolder("Changer");
  expect((await publish(pageId, { label: "changer-one" })).status).toBe(200);
  expect((await publish(pageId, { label: "changer-two" })).status).toBe(200);
  const again = await publish(pageId, { label: "changer-three" });
  expect(again.status).toBe(409);
  expect((await j(again)).code).toBe("address_changed_recently");
  const [r] = await w.h.tdb.admin<{ n: number }[]>`
    select count(*)::int as n from public.site_labels_retired where label = 'changer-one'`;
  expect(r!.n).toBe(1);
});

it("answers 402 over the plan's limit, and search engines need a paid plan", async () => {
  await w.h.tdb.admin`
    update public.entitlements set limits = limits || '{"max_sites": 1, "max_custom_domains": 0}'::jsonb where org_id = ${w.orgId}`;
  const pageId = await w.publishFolder("Too many");
  const res = await publish(pageId, { label: "too-many" });
  expect(res.status).toBe(402);
  expect((await j(res)).code).toBe("plan_limit");
  await w.h.tdb.admin`
    update public.entitlements set limits = limits - 'max_sites' where org_id = ${w.orgId}`;
  const indexed = await publish(pageId, { label: "too-many", indexable: true });
  expect(indexed.status).toBe(402);
  await w.h.tdb.admin`
    update public.entitlements set limits = limits - 'max_custom_domains' where org_id = ${w.orgId}`;
  const ok = await j(await publish(pageId, { label: "too-many", indexable: true }));
  expect(ok.indexable).toBe(true);
  expect(ok.can_index).toBe(true);
});

it("unpublishing stops serving and keeps the name", async () => {
  const pageId = await w.publishFolder("Pause me");
  await publish(pageId, { label: "pause-me" });
  const res = await w.h.request(`/v1/pages/${pageId}/site`, {
    method: "DELETE",
    token: w.owner.token,
  });
  expect(res.status).toBe(200);
  const site = await j(res);
  expect(site.live).toBe(false);
  expect(site.label).toBe("pause-me");
  expect((await w.get(`https://pause-me.${ZONE}/`)).status).toBe(404);
  const check = await j(
    await w.h.request(`/v1/sites/address?org_id=${w.orgId}&label=pause-me`, {
      token: w.owner.token,
    }),
  );
  expect(check.available).toBe(false);
});

it("another workspace can't publish or read", async () => {
  const pageId = await w.publishFolder("Private one");
  const stranger = await w.h.user("site-stranger@example.com");
  expect((await publish(pageId, { label: "stolen" }, stranger.token)).status).toBe(404);
  expect((await w.h.request(`/v1/orgs/${w.orgId}/sites`, { token: stranger.token })).status).toBe(
    404,
  );
  expect((await w.h.request(`/v1/orgs/${w.orgId}/sites`)).status).toBe(401);
  expect((await w.h.request(`/v1/pages/${pageId}/site`, { method: "PUT", json: {} })).status).toBe(
    401,
  );
});

it("the bot's sites.publish asks first, and sites.status lists what's live", async () => {
  expect(w.reg.get("sites.publish")?.risk).toBe("high");
  expect(w.reg.get("sites.publish")?.category).toBe("publish");
  expect(w.reg.get("sites.status")?.risk).toBe("low");
  const pageId = await w.publishFolder("Bot site");
  const r = await w.tool("sites.publish", { page_id: pageId, name: "bot-site" });
  expect(r.content).toContain(`https://bot-site.${ZONE}`);
  const status = await w.tool("sites.status", {});
  expect(status.content).toContain("bot-site");
  // Only its own pages.
  await expect(
    w.tool("sites.publish", { page_id: "00000000-0000-0000-0000-000000000000" }),
  ).rejects.toThrow(/no page/);
});
