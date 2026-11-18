/**
 * Sites (docs/SITES-AND-DOMAINS-PLAN.md §7.15): Publish to the Web, the address check, the list,
 * and reports by address from the sites zone's own page.
 */
import {
  checkSiteAddress,
  listSiteRows,
  publishSite,
  SiteError,
  siteHostnames,
  siteLimits,
  unpublishSite,
} from "@casama/agent";
import { routes } from "@casama/contracts";
import { type Database, type JwtClaims, withUserSession } from "@casama/db";
import { HOSTNAME_PATTERN } from "@casama/domain";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { sql } from "drizzle-orm";
import { forgetHosts } from "../../pages/hosts.ts";
import { clientIp, fileReport } from "../../pages/shared.ts";
import { abuseControlsOn } from "../../services/abuse.ts";
import { sitesSettings } from "../../sites/config.ts";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { requireClaims } from "./autonomy.ts";

/** Reports by address from the zone's own page: a few an hour per visitor. */
const REPORTS_PER_HOUR = 10;

export const siteErrorToApi = (err: unknown) =>
  err instanceof SiteError ? new ApiError(err.status as 400, err.code, err.message) : err;

export function registerSiteRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;

  const zoneOrThrow = async () => {
    const s = await sitesSettings(deps.env, db);
    if (!s.zone)
      throw new ApiError(
        409,
        "sites_off",
        "Publishing sites to the web isn't turned on for this server.",
      );
    return s.zone;
  };
  const member = async (claims: JwtClaims, orgId: string) => {
    const [r] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ ok: boolean }>(sql`select public.is_member(${orgId}::uuid) as ok`),
    );
    if (!r?.ok) throw new ApiError(404, "org_not_found", "Workspace not found");
  };
  /** A page this person can change (the person it was made for or the bot's managers). */
  const managedPage = async (claims: JwtClaims, id: string) => {
    const [row] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ id: string; org_id: string; can_manage: boolean }>(sql`
        select id, org_id, (created_by = auth.uid() or public.can_manage_bot(bot_id)) as can_manage
        from public.pages where id = ${id}::uuid`),
    );
    if (!row) throw new ApiError(404, "page_not_found", "Page not found");
    if (!row.can_manage)
      throw new ApiError(
        403,
        "forbidden",
        "Only the person it was made for or the bot's managers can publish this page",
      );
    return row;
  };
  const siteOf = async (
    db2: Database,
    claims: JwtClaims,
    orgId: string,
    pageId: string,
    zone: string,
  ) => {
    const limits = await siteLimits(db2, orgId);
    const [site] = await withUserSession(db2, claims, (tx) =>
      listSiteRows(tx, { orgId, zone, pageId, canIndex: limits.canIndex }),
    );
    if (!site) throw new ApiError(404, "site_not_found", "This page isn't on the web");
    return site;
  };

  app.openapi(routes.listSites, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const orgId = c.req.valid("param").id;
    await member(claims, orgId);
    const { zone } = await sitesSettings(deps.env, db);
    const limits = await siteLimits(db, orgId);
    const items = await withUserSession(db, claims, (tx) =>
      listSiteRows(tx, { orgId, zone, canIndex: limits.canIndex }),
    );
    return c.json({ items }, 200);
  });

  app.openapi(routes.checkSiteAddress, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { org_id, label } = c.req.valid("query");
    await member(claims, org_id);
    const zone = await zoneOrThrow();
    return c.json(await checkSiteAddress(db, { orgId: org_id, label, zone }), 200);
  });

  app.openapi(routes.publishSite, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const zone = await zoneOrThrow();
    const page = await managedPage(claims, c.req.valid("param").id);
    const body = c.req.valid("json");
    // Who can publish: a confirmed email address (§7.11), where the abuse controls are on.
    if (abuseControlsOn(deps.env)) {
      const [u] = await db.execute<{ ok: boolean }>(
        sql`select email_confirmed_at is not null as ok from auth.users where id = ${claims.sub}::uuid`,
      );
      if (!u?.ok)
        throw new ApiError(
          403,
          "email_unconfirmed",
          "Confirm your email address before publishing a site.",
        );
    }
    const before = await siteHostnames(db, page.id);
    try {
      await publishSite(db, {
        pageId: page.id,
        orgId: page.org_id,
        userId: claims.sub,
        zone,
        label: body.label,
        indexable: body.indexable,
        badge: body.badge,
        surface: "app",
      });
    } catch (err) {
      throw siteErrorToApi(err);
    }
    forgetHosts(...before, ...(await siteHostnames(db, page.id)));
    return c.json(await siteOf(db, claims, page.org_id, page.id, zone), 200);
  });

  app.openapi(routes.unpublishSite, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const page = await managedPage(claims, c.req.valid("param").id);
    const { zone } = await sitesSettings(deps.env, db);
    await unpublishSite(db, { pageId: page.id, orgId: page.org_id, userId: claims.sub });
    forgetHosts(...(await siteHostnames(db, page.id)));
    return c.json(await siteOf(db, claims, page.org_id, page.id, zone ?? ""), 200);
  });

  const recent = new Map<string, number[]>();
  app.openapi(routes.createSiteReport, async (c) => {
    const { address, reason } = c.req.valid("json");
    const ip = clientIp((k) => c.req.header(k), deps.env.TRUSTED_CLIENT_IP_HEADER);
    const now = Date.now();
    const times = (recent.get(ip) ?? []).filter((t) => now - t < 3_600_000);
    if (times.length >= REPORTS_PER_HOUR)
      throw new ApiError(429, "too_many", "Too many reports from here. Try again later.");
    recent.set(ip, [...times, now]);
    if (recent.size > 10_000) recent.delete(recent.keys().next().value as string);
    const host = address
      .trim()
      .toLowerCase()
      .replace(/^[a-z][a-z0-9+.-]*:\/\//, "")
      .split(/[/?#]/)[0]
      ?.replace(/:\d+$/, "")
      .replace(/\.$/, "");
    // An unknown address is answered the same way, so the form can't be used to probe names.
    if (host && HOSTNAME_PATTERN.test(host)) {
      const [p] = await db.execute<{
        page_id: string;
        org_id: string;
        creation_id: string | null;
      }>(sql`
        select h.page_id, h.org_id, (select cr.id from public.creations cr where cr.page_id = h.page_id) as creation_id
        from public.site_hosts h where h.hostname = ${host} and h.page_id is not null`);
      if (p?.creation_id)
        await fileReport(db, {
          creationId: p.creation_id,
          orgId: p.org_id,
          pageId: p.page_id,
          reason: reason.trim().slice(0, 1000),
          ip,
        });
    }
    return c.json({ ok: true }, 202);
  });
}
