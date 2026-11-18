/**
 * Connected domains (docs/SITES-AND-DOMAINS-PLAN.md §7.15): list, connect, read with what DNS
 * shows, Check Again, point at a site, disconnect. And `/internal/tls-ask`, which a self-hosted
 * server's Caddy asks before it gets a certificate for a name (§7.12).
 */
import { SiteError } from "@casama/agent";
import { routes } from "@casama/contracts";
import { type JwtClaims, withUserSession } from "@casama/db";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { sql } from "drizzle-orm";
import type { Hono } from "hono";
import { appLink } from "../../env.ts";
import { forgetHosts, lookupHost } from "../../pages/hosts.ts";
import {
  adminOverview,
  applyDomainPayment,
  applyDomainRefund,
  approveOrder,
  type BuyingContext,
  getContact,
  getOrder,
  orderView,
  registrarFromEnv,
  retryOrder,
  saveContact,
  searchDomains,
  startCheckout,
  suspendDomain,
  syncFromRegistrar,
  unsuspendDomain,
} from "../../sites/buying.ts";
import { buyingConfigured, sitesSettings } from "../../sites/config.ts";
import {
  checkDomain,
  choosePrimary,
  connectDomain,
  type DomainRow,
  type DomainsContext,
  disconnectDomain,
  dnsLookupFromEnv,
  domainHosts,
  domainView,
  getDomain,
  hostnameProviderFromEnv,
  linkPage,
  listDomains,
} from "../../sites/domains.ts";
import {
  changeRecord,
  issueTransferCode,
  listRecords,
  relockDomain,
  resendVerification,
  signedInRecently,
  startRenewal,
  subdomainRecord,
} from "../../sites/lifecycle.ts";
import { domainPaymentsFromEnv } from "../../sites/payments.ts";
import { RegistrarError } from "../../sites/registrar.ts";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { instanceOwnerCheck } from "./admin.ts";
import { isAdmin, requireClaims } from "./autonomy.ts";
import { siteErrorToApi } from "./sites.ts";

/** Check Again at most this often per domain. */
const CHECK_EVERY_MS = 10_000;
/** Domain searches per person per minute (§7.15). */
const SEARCHES_PER_MINUTE = 30;

/**
 * Buying's context, made once per app: the registrar keeps the account-wide call budget and the
 * search cache, so there must be one per process. null when this server doesn't sell domains
 * (remote switches aside: a payment that arrives after the switch is turned off still registers).
 */
const buyingCache = new WeakMap<AppDeps, BuyingContext | null>();
export function buyingFor(deps: AppDeps): BuyingContext | null {
  if (buyingCache.has(deps)) return buyingCache.get(deps) ?? null;
  const env = deps.env;
  const provider =
    deps.sites?.provider !== undefined
      ? deps.sites.provider
      : hostnameProviderFromEnv(env, deps.sites?.fetch);
  const registrar =
    deps.sites?.registrar !== undefined
      ? deps.sites.registrar
      : registrarFromEnv(env, deps.sites?.fetch);
  const payments = deps.sites?.payments ?? domainPaymentsFromEnv(env);
  const ctx =
    env.CASAMA_SITES_ZONE && provider && registrar && payments && buyingConfigured(env)
      ? {
          db: deps.db,
          env,
          zone: env.CASAMA_SITES_ZONE,
          provider,
          dns: deps.sites?.dns ?? dnsLookupFromEnv(env, deps.sites?.fetch),
          registrar,
          payments,
          adminEmails: env.INSTANCE_ADMIN_EMAILS,
          startOrder: (orderId: string) => deps.workflows.startDomainOrder(orderId),
        }
      : null;
  buyingCache.set(deps, ctx);
  return ctx;
}

export function registerDomainRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;
  const provider = () =>
    deps.sites?.provider !== undefined
      ? deps.sites.provider
      : hostnameProviderFromEnv(deps.env, deps.sites?.fetch);
  const dns = () => deps.sites?.dns ?? dnsLookupFromEnv(deps.env, deps.sites?.fetch);

  /** Connected domains need a zone and an edge, and the remote switch on. */
  const ctx = async (): Promise<DomainsContext> => {
    const s = await sitesSettings(deps.env, db);
    const p = provider();
    if (!s.zone || !s.custom_domains || !p)
      throw new ApiError(
        409,
        "domains_off",
        "Using your own domain isn't turned on for this server.",
      );
    return { db, env: deps.env, zone: s.zone, provider: p, dns: dns() };
  };
  const member = async (claims: JwtClaims, orgId: string) => {
    const [r] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ ok: boolean }>(sql`select public.is_member(${orgId}::uuid) as ok`),
    );
    if (!r?.ok) throw new ApiError(404, "org_not_found", "Workspace not found");
  };
  const admin = async (claims: JwtClaims, orgId: string) => {
    await member(claims, orgId);
    if (!(await isAdmin(db, claims, orgId)))
      throw new ApiError(403, "forbidden", "Only workspace admins can manage domains");
  };
  /** A domain this person's workspace has (RLS: members read their domains). */
  const domainFor = async (claims: JwtClaims, id: string, needAdmin: boolean) => {
    const [d] = await withUserSession(db, claims, (tx) =>
      tx.execute<DomainRow>(sql`select * from public.domains where id = ${id}::uuid`),
    );
    if (!d?.org_id) throw new ApiError(404, "domain_not_found", "Domain not found");
    if (needAdmin) await admin(claims, d.org_id);
    return d;
  };
  const hostnamesOf = async (domainId: string) =>
    (await domainHosts(db, domainId)).map((h) => h.hostname);
  const fresh = async (id: string) => {
    const d = await getDomain(db, id);
    if (!d) throw new ApiError(404, "domain_not_found", "Domain not found");
    return d;
  };
  const wrap = async <T>(fn: () => Promise<T>) => {
    try {
      return await fn();
    } catch (err) {
      throw err instanceof SiteError ? siteErrorToApi(err) : err;
    }
  };

  // ---------------------------------------------------------------- Buying (§7.7)

  const buying = buyingFor(deps);
  // Domain payments ride the Dodo webhook; they're offered to buying before plan billing.
  if (buying && deps.billing)
    deps.billing.domains = {
      subscription: async (snap) => {
        if (!buying.payments.owns(snap.productId)) return false;
        if (["cancelled", "expired", "refunded", "on_hold"].includes(snap.status))
          await db.execute(sql`
            update public.domain_contacts set mandate_ref = null, updated_at = now()
            where mandate_ref = ${snap.externalId}`);
        return true;
      },
      payment: (paymentId) => applyDomainPayment(buying, paymentId),
      refund: (paymentId) => applyDomainRefund(buying, paymentId),
    };
  /** Buying needs this server to sell domains and its remote switch on. */
  const buyingCtx = async () => {
    const s = await sitesSettings(deps.env, db);
    if (!buying || !s.buy_domains)
      throw new ApiError(409, "buying_off", "Buying domains isn't available on this server.");
    return buying;
  };
  const searches = new Map<string, number[]>();
  const searchAllowed = (userId: string) => {
    const now = Date.now();
    const recent = (searches.get(userId) ?? []).filter((t) => now - t < 60_000);
    if (recent.length >= SEARCHES_PER_MINUTE) return false;
    recent.push(now);
    searches.set(userId, recent);
    if (searches.size > 10_000) searches.clear();
    return true;
  };
  const registrarError = (e: unknown) => {
    if (e instanceof RegistrarError)
      throw new ApiError(
        e.status === 429 ? 429 : 409,
        e.status === 429 ? "rate_limited" : "registrar_unavailable",
        e.status === 429 ? e.message : "The domain registrar didn't answer. Try again in a minute.",
      );
    throw e;
  };

  app.openapi(routes.searchDomains, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { org_id, q } = c.req.valid("query");
    await admin(claims, org_id);
    const ctx = await buyingCtx();
    if (!searchAllowed(claims.sub))
      throw new ApiError(429, "rate_limited", "Too many searches. Try again in a minute.");
    const r = await searchDomains(ctx, { orgId: org_id, userId: claims.sub, query: q }).catch(
      registrarError,
    );
    return c.json(r as never, 200);
  });

  app.openapi(routes.getDomainContact, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const orgId = c.req.valid("param").id;
    await admin(claims, orgId);
    const contact = await getContact(db, orgId);
    return c.json({ contact, default_email: claims.email ?? null } as never, 200);
  });

  app.openapi(routes.putDomainContact, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const orgId = c.req.valid("param").id;
    await admin(claims, orgId);
    const contact = await wrap(() =>
      saveContact(
        { db, registrar: buying?.registrar ?? null },
        { orgId, userId: claims.sub, contact: c.req.valid("json") },
      ),
    );
    return c.json({ contact, default_email: claims.email ?? null } as never, 200);
  });

  app.openapi(routes.domainCheckout, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const orgId = c.req.valid("param").id;
    await admin(claims, orgId);
    const ctx = await buyingCtx();
    const body = c.req.valid("json");
    const r = await wrap(() =>
      startCheckout(ctx, {
        orgId,
        userId: claims.sub,
        email: claims.email ?? null,
        name: body.name,
        pageId: body.page_id,
        acceptTerms: body.accept_terms,
        autoRenew: body.auto_renew,
        returnUrl: appLink(deps.env, "/settings/domains"),
      }),
    ).catch(registrarError);
    return c.json({ order: orderView(r.order), checkout_url: r.checkoutUrl } as never, 201);
  });

  app.openapi(routes.getDomainOrder, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const id = c.req.valid("param").id;
    // RLS: only the workspace's admins read its orders.
    const [o] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ id: string }>(sql`select id from public.domain_orders where id = ${id}::uuid`),
    );
    const order = o ? await getOrder(db, o.id) : null;
    if (!order) throw new ApiError(404, "order_not_found", "Order not found");
    return c.json(orderView(order) as never, 200);
  });

  // ---------------------------------------------------------------- Admin → Domains (§7.11)

  const requireOwner = instanceOwnerCheck(deps);
  const adminCtx = () => {
    if (!buying) throw new ApiError(409, "buying_off", "This server doesn't sell domains.");
    return buying;
  };

  app.openapi(routes.adminDomains, async (c) => {
    await requireOwner(requireClaims(c.get("claims")));
    return c.json((await adminOverview(db, buying?.registrar ?? null)) as never, 200);
  });

  app.openapi(routes.adminSuspendDomain, async (c) => {
    const claims = requireClaims(c.get("claims"));
    await requireOwner(claims);
    const id = c.req.valid("param").id;
    const before = await hostnamesOf(id);
    await wrap(() => suspendDomain({ db, registrar: buying?.registrar ?? null }, id, claims.sub));
    forgetHosts(...before);
    return c.body(null, 204);
  });

  app.openapi(routes.adminUnsuspendDomain, async (c) => {
    const claims = requireClaims(c.get("claims"));
    await requireOwner(claims);
    const id = c.req.valid("param").id;
    const p = provider();
    if (!p) throw new ApiError(409, "domains_off", "Domains aren't turned on for this server.");
    await wrap(() =>
      unsuspendDomain(
        { db, env: deps.env, provider: p, registrar: buying?.registrar ?? null },
        id,
        claims.sub,
      ),
    );
    forgetHosts(...(await hostnamesOf(id)));
    return c.body(null, 204);
  });

  app.openapi(routes.adminRetryDomainOrder, async (c) => {
    await requireOwner(requireClaims(c.get("claims")));
    const o = await wrap(() => retryOrder(adminCtx(), c.req.valid("param").id));
    return c.json(orderView(o) as never, 200);
  });

  app.openapi(routes.adminApproveDomainOrder, async (c) => {
    await requireOwner(requireClaims(c.get("claims")));
    const o = await wrap(() => approveOrder(adminCtx(), c.req.valid("param").id));
    return c.json(orderView(o) as never, 200);
  });

  // The registrar's webhook (§7.6): signature checked, stored once on the domain, then the domain
  // is read again from the registrar. Never trusted for what it says.
  (app as unknown as Hono<AppEnv>).post("/hooks/registrar/:id", async (c) => {
    if (!buying || c.req.param("id") !== buying.registrar.id)
      throw new ApiError(404, "not_found", "No such route");
    const rawBody = await c.req.text();
    let ev: Awaited<ReturnType<typeof buying.registrar.verifyWebhook>>;
    try {
      ev = await buying.registrar.verifyWebhook({ headers: c.req.raw.headers, rawBody });
    } catch (e) {
      if (e instanceof RegistrarError) throw new ApiError(401, e.code, e.message);
      throw e;
    }
    const duplicate = await syncFromRegistrar(buying, ev);
    return c.json({ ok: true, duplicate }, 200);
  });

  // ---------------------------------------------------------------- Keeping a domain (§7.8–§7.10)
  // Not behind the buying switch: renewing, DNS and leaving work whenever the server sells domains.

  app.openapi(routes.renewDomain, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const d = await domainFor(claims, c.req.valid("param").id, true);
    const ctx = adminCtx();
    const r = await wrap(() =>
      startRenewal(ctx, d, {
        by: claims.sub,
        email: claims.email ?? null,
        returnUrl: appLink(deps.env, `/settings/domains/${d.id}`),
      }),
    ).catch(registrarError);
    return c.json({ order: orderView(r.order), checkout_url: r.checkoutUrl } as never, 201);
  });

  app.openapi(routes.listDomainRecords, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const d = await domainFor(claims, c.req.valid("param").id, true);
    const items = await wrap(() => listRecords(adminCtx(), d)).catch(registrarError);
    return c.json({ items } as never, 200);
  });

  app.openapi(routes.addDomainRecord, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const d = await domainFor(claims, c.req.valid("param").id, true);
    const body = c.req.valid("json");
    const r = await wrap(() =>
      changeRecord(adminCtx(), d, "add", { ...body, priority: body.priority ?? null }, claims.sub),
    ).catch(registrarError);
    return c.json(r as never, 201);
  });

  app.openapi(routes.updateDomainRecord, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id, record_id } = c.req.valid("param");
    const d = await domainFor(claims, id, true);
    const body = c.req.valid("json");
    const r = await wrap(() =>
      changeRecord(
        adminCtx(),
        d,
        "change",
        { ...body, id: record_id } as Parameters<typeof changeRecord>[3],
        claims.sub,
      ),
    ).catch(registrarError);
    return c.json(r as never, 200);
  });

  app.openapi(routes.deleteDomainRecord, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id, record_id } = c.req.valid("param");
    const d = await domainFor(claims, id, true);
    await wrap(() =>
      changeRecord(
        adminCtx(),
        d,
        "delete",
        { id: record_id, host: "", type: "", answer: "", ttl: 300 },
        claims.sub,
      ),
    ).catch(registrarError);
    return c.body(null, 204);
  });

  app.openapi(routes.transferOutDomain, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const d = await domainFor(claims, c.req.valid("param").id, true);
    // The owner only, with a fresh sign-in (§7.10, §12: a stolen session can't move a domain).
    const [owner] = await db.execute<{ ok: boolean }>(sql`
      select exists (select 1 from public.memberships where org_id = ${d.org_id}::uuid
        and user_id = ${claims.sub}::uuid and role = 'owner') as ok`);
    if (!owner?.ok)
      throw new ApiError(403, "owner_only", "Only the workspace owner can move a domain away.");
    if (!signedInRecently(claims))
      throw new ApiError(
        401,
        "reauthentication_needed",
        "Sign in again to get a transfer code. It needs a sign-in from the last 10 minutes.",
      );
    const code = await wrap(() =>
      issueTransferCode(adminCtx(), d, {
        by: claims.sub,
        confirmName: c.req.valid("json").confirm_name,
      }),
    ).catch(registrarError);
    c.header("Cache-Control", "no-store");
    return c.json({ code }, 200);
  });

  app.openapi(routes.resendDomainVerification, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const d = await domainFor(claims, c.req.valid("param").id, true);
    await wrap(() => resendVerification(adminCtx(), d)).catch(registrarError);
    return c.body(null, 204);
  });

  // ---------------------------------------------------------------- Connected and bought domains

  app.openapi(routes.listDomains, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const orgId = c.req.valid("param").id;
    await member(claims, orgId);
    const items = await withUserSession(db, claims, (tx) =>
      listDomains(tx, deps.env, provider(), orgId),
    );
    return c.json({ items } as never, 200);
  });

  app.openapi(routes.connectDomain, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const orgId = c.req.valid("param").id;
    await admin(claims, orgId);
    const body = c.req.valid("json");
    const context = await ctx();
    const r = await wrap(() =>
      connectDomain(context, { orgId, userId: claims.sub, name: body.name, pageId: body.page_id }),
    );
    if (!r.domainId) return c.json({ domain: null, claim: r.claim }, 201);
    // A subdomain under a domain bought here: its record is made by itself (§7.9).
    const connected = await fresh(r.domainId);
    if (connected.kind === "connected" && buying)
      await subdomainRecord(buying, connected, true).catch(() => false);
    forgetHosts(...(await hostnamesOf(r.domainId)));
    const domain = await domainView(db, deps.env, context.provider, await fresh(r.domainId));
    return c.json({ domain, claim: null } as never, 201);
  });

  app.openapi(routes.getDomain, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const d = await domainFor(claims, c.req.valid("param").id, false);
    const view = await domainView(db, deps.env, provider(), d, { dns: dns(), events: true });
    return c.json(view as never, 200);
  });

  app.openapi(routes.checkDomain, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const d = await domainFor(claims, c.req.valid("param").id, true);
    if (d.checked_at && Date.now() - new Date(d.checked_at).getTime() < CHECK_EVERY_MS)
      throw new ApiError(429, "rate_limited", "Checked a moment ago. Try again in a few seconds.");
    const context = await ctx();
    await wrap(() => checkDomain(context, d.id, true));
    forgetHosts(...(await hostnamesOf(d.id)));
    const view = await domainView(db, deps.env, context.provider, await fresh(d.id), {
      dns: context.dns,
      events: true,
    });
    return c.json(view as never, 200);
  });

  app.openapi(routes.updateDomain, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const d = await domainFor(claims, c.req.valid("param").id, true);
    const body = c.req.valid("json");
    const before = await hostnamesOf(d.id);
    await wrap(async () => {
      if (body.page_id !== undefined) await linkPage({ db }, d.id, body.page_id);
      if (body.primary_host) await choosePrimary(db, d.id, body.primary_host);
      if (body.auto_renew !== undefined) {
        if (d.kind !== "registered")
          throw new SiteError(400, "not_registered", "Only domains bought through Casama renew.");
        await db.execute(
          sql`update public.domains set auto_renew = ${body.auto_renew}, updated_at = now() where id = ${d.id}::uuid`,
        );
      }
      if (body.locked) {
        if (d.kind !== "registered")
          throw new SiteError(400, "not_registered", "Only domains bought through Casama lock.");
        await relockDomain(adminCtx(), d, claims.sub);
      }
    });
    // The address hosts of the old and new site change primary too.
    const pages = await db.execute<{ hostname: string }>(sql`
      select hostname from public.site_hosts where page_id in (
        select page_id from public.site_hosts where domain_id = ${d.id}::uuid and page_id is not null)`);
    forgetHosts(...before, ...pages.map((p) => p.hostname));
    return c.json((await domainView(db, deps.env, provider(), await fresh(d.id))) as never, 200);
  });

  app.openapi(routes.deleteDomain, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const d = await domainFor(claims, c.req.valid("param").id, true);
    const before = await hostnamesOf(d.id);
    await wrap(() => disconnectDomain({ db }, d.id, claims.sub));
    if (d.kind === "connected" && buying)
      await subdomainRecord(buying, d, false).catch(() => false);
    forgetHosts(...before);
    return c.body(null, 204);
  });
}

/**
 * Caddy's on-demand TLS asks here before every new certificate (§7.12): yes only for a site
 * address that's live or a domain host Casama has proof for, so nobody can make the server
 * request certificates for any name. Internal network only (never in the Caddyfile's API paths
 * or the Helm ingress), and registered before the internal token check, since Caddy can't send it.
 */
export function registerTlsAsk(app: Hono<AppEnv>, deps: AppDeps) {
  app.get("/internal/tls-ask", async (c) => {
    const domain = (c.req.query("domain") ?? "").trim().toLowerCase().replace(/\.$/, "");
    if (!deps.env.CASAMA_SITES_ZONE || !domain) return c.text("no", 404);
    const row = await lookupHost(deps.db, domain).catch(() => null);
    const ok =
      !!row &&
      ((row.kind === "address" && row.status === "active") ||
        (row.kind === "custom" &&
          row.verified_at != null &&
          ["pending_cert", "active", "paused"].includes(row.status)));
    return ok ? c.text("ok", 200) : c.text("no", 404);
  });
}
