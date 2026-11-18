/**
 * Site hosts (docs/SITES-AND-DOMAINS-PLAN.md §7.2): a published page served at the root of its own
 * address and its domains. Site hosts never mount the pages origin's routes (/p/, /s/, /c/, /t/,
 * /v/), so a public page link can't be opened on someone's domain, and each site is its own origin.
 */
import { createHash } from "node:crypto";
import type { Database } from "@casama/db";
import {
  hostIsLive,
  PAGE_HEADERS,
  renderSite,
  SITE_RESERVED_PREFIX,
  siteHeaders,
  sitePathCandidates,
  siteRobots,
  siteSitemap,
} from "@casama/domain";
import { captureError } from "@casama/observability";
import { sql } from "drizzle-orm";
import { Hono } from "hono";
import { type HostRow, lookupHost, requestHost } from "./hosts.ts";
import {
  clientIp,
  createReceiver,
  fileReport,
  REPORT_FORM_CSP,
  REPORT_THANKS,
  reportForm,
} from "./shared.ts";

type SitePage = {
  id: string;
  org_id: string;
  title: string;
  html: string;
  data: unknown;
  version: number;
  assets_version: number | null;
  collects: boolean;
  submit_routine_id: string | null;
  indexable: boolean;
  badge: boolean;
  primary_host: string | null;
  address_host: string | null;
};

const UNAVAILABLE = `<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="robots" content="noindex"><title>Not available</title><body style="font:16px system-ui;max-width:640px;margin:0 auto;padding:48px 16px;color:#1d1b20"><h1 style="font-size:20px">This site isn't available</h1><p>There's nothing here right now. If you made it, check its address in Casama.</p></body>`;
const NOT_FOUND = `<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Not found</title><body style="font:16px system-ui;max-width:640px;margin:0 auto;padding:48px 16px;color:#1d1b20"><h1 style="font-size:20px">Page not found</h1><p><a href="/">Go to the home page</a></p></body>`;

const BASE_HEADERS = {
  "x-content-type-options": "nosniff",
  "referrer-policy": "no-referrer",
  "x-robots-tag": "noindex, nofollow",
  "cache-control": "no-store",
};

/** A live, servable page behind a host: public, not expired, trashed, taken down or suspended. */
const LIVE_PAGE = sql`p.visibility = 'public' and (p.expires_at is null or p.expires_at > now())
  and not exists (select 1 from public.creations cr where cr.page_id = p.id and (cr.deleted_at is not null or cr.taken_down_at is not null))
  and o.suspended_at is null`;

export function createSitesApp(deps: {
  db: Database;
  objects?: import("@casama/sandbox").ObjectStore | null;
  workflows?: { startRun(runId: string): Promise<void> };
  /** This server's id, answered at /_casama/probe (self-hosted connected domains, §7.3). */
  instanceId?: string;
  /** TRUSTED_CLIENT_IP_HEADER: who a signed-out visitor is (reports, submissions). */
  env?: { TRUSTED_CLIENT_IP_HEADER?: string };
}) {
  const { db } = deps;
  const app = new Hono();
  const receive = createReceiver(deps);

  app.onError((err, c) => {
    captureError(err, { service: "casama-sites", path: c.req.path });
    return c.text("Something went wrong", 500);
  });

  const unavailable = () =>
    new Response(UNAVAILABLE, {
      status: 404,
      headers: { ...BASE_HEADERS, "content-type": "text/html; charset=utf-8" },
    });

  /** The page behind a host, checked on every request so a takedown is immediate. */
  const sitePage = async (pageId: string) => {
    const [p] = await db.execute<SitePage>(sql`
      select p.id, p.org_id, p.title, p.html, p.data, p.version, p.assets_version, p.collects, p.submit_routine_id,
        s.indexable, s.badge,
        (select ph.hostname from public.site_hosts ph where ph.page_id = p.id and ph.is_primary and ph.status = 'active'
           and (ph.kind = 'address' or ph.verified_at is not null)) as primary_host,
        (select ah.hostname from public.site_hosts ah where ah.page_id = p.id and ah.kind = 'address' and ah.status = 'active') as address_host
      from public.pages p join public.sites s on s.page_id = p.id join public.organizations o on o.id = p.org_id
      where p.id = ${pageId}::uuid and ${LIVE_PAGE}`);
    return p ?? null;
  };

  type Resolved =
    | { kind: "serve"; host: HostRow; page: SitePage; hostname: string }
    | { kind: "response"; response: Response };

  /** Which site a request is for, or the answer when it isn't served (§7.2, §7.13). */
  const resolve = async (req: Request, path: string): Promise<Resolved> => {
    const hostname = requestHost(req);
    const host = await lookupHost(db, hostname);
    if (!host?.page_id) return { kind: "response", response: unavailable() };
    const page = await sitePage(host.page_id);
    if (!page) return { kind: "response", response: unavailable() };
    // A domain over the plan's limit sends visitors to the site's own address, not cached.
    if (host.status === "paused" && page.address_host)
      return {
        kind: "response",
        response: new Response(null, {
          status: 302,
          headers: { location: `https://${page.address_host}${path}`, "cache-control": "no-store" },
        }),
      };
    if (!hostIsLive(host)) return { kind: "response", response: unavailable() };
    // Every host but the primary sends visitors there, keeping the path.
    if (
      page.primary_host &&
      page.primary_host !== hostname &&
      !path.startsWith(SITE_RESERVED_PREFIX)
    )
      return {
        kind: "response",
        response: new Response(null, {
          status: 301,
          headers: {
            location: `https://${page.primary_host}${path}`,
            "cache-control": "public, max-age=300",
          },
        }),
      };
    return { kind: "serve", host, page, hostname };
  };

  const etagOf = (page: SitePage, path: string) =>
    `"${createHash("sha256")
      .update(
        `${page.id}:${page.version}:${page.assets_version ?? 0}:${page.indexable}:${page.badge}:${path}`,
      )
      .digest("base64url")
      .slice(0, 22)}"`;

  const fileOf = async (page: SitePage, path: string) => {
    if (!page.assets_version || !deps.objects) return null;
    const [a] = await db.execute<{ mime: string; blob_key: string }>(sql`
      select mime, blob_key from public.page_assets
      where page_id = ${page.id}::uuid and version = ${page.assets_version} and path = ${path}`);
    if (!a) return null;
    const { readObject } = await import("@casama/sandbox");
    const bytes = await readObject(deps.objects, a.blob_key).catch(() => null);
    return bytes ? { mime: a.mime, bytes } : null;
  };
  const sitePaths = async (page: SitePage) =>
    page.assets_version
      ? (
          await db.execute<{ path: string }>(sql`
            select path from public.page_assets where page_id = ${page.id}::uuid and version = ${page.assets_version}`)
        ).map((r) => r.path)
      : [];

  const htmlResponse = (
    r: Extract<Resolved, { kind: "serve" }>,
    html: string,
    index: boolean,
    etag: string,
    status = 200,
  ) => {
    const { page, host } = r;
    const badge = host.kind === "address" || page.badge;
    return new Response(
      renderSite({
        title: page.title,
        html,
        data: page.data,
        index,
        indexable: page.indexable,
        badge,
        collects: page.collects,
      }),
      {
        status,
        headers: {
          ...siteHeaders({ indexable: page.indexable, collects: page.collects, html: true, etag }),
          "content-type": "text/html; charset=utf-8",
        },
      },
    );
  };

  const notModified = (req: Request, etag: string) =>
    req.headers.get("if-none-match") === etag
      ? new Response(null, { status: 304, headers: { etag } })
      : null;

  // ------------------------------------------------------------ Casama's own paths

  // Self-hosted connected domains (§7.3): the server proves it is the one answering.
  app.get("/_casama/probe", (c) =>
    c.text(deps.instanceId ?? "casama", 200, { "cache-control": "no-store" }),
  );

  app.post("/_casama/collect", async (c) => {
    const r = await resolve(c.req.raw, "/_casama/collect");
    if (r.kind !== "serve") return r.response;
    if (!r.page.collects) return Response.json({ error: "not_found" }, { status: 404 });
    return receive(c, r.page, null);
  });

  app.get("/_casama/report", async (c) => {
    const r = await resolve(c.req.raw, "/_casama/report");
    if (r.kind !== "serve") return r.response;
    return new Response(reportForm(r.page.title), {
      headers: {
        ...PAGE_HEADERS,
        "content-security-policy": REPORT_FORM_CSP,
        "content-type": "text/html; charset=utf-8",
      },
    });
  });
  app.post("/_casama/report", async (c) => {
    const r = await resolve(c.req.raw, "/_casama/report");
    if (r.kind !== "serve") return r.response;
    const form = await c.req.parseBody().catch(() => ({}) as Record<string, unknown>);
    const reason = String((form as Record<string, unknown>).reason ?? "")
      .trim()
      .slice(0, 1000);
    const [cr] = await db.execute<{ id: string }>(
      sql`select id from public.creations where page_id = ${r.page.id}::uuid`,
    );
    if (reason && cr)
      await fileReport(db, {
        creationId: cr.id,
        orgId: r.page.org_id,
        pageId: r.page.id,
        reason,
        ip: clientIp((k) => c.req.header(k), deps.env?.TRUSTED_CLIENT_IP_HEADER),
      });
    return new Response(REPORT_THANKS, {
      headers: { ...PAGE_HEADERS, "content-type": "text/html; charset=utf-8" },
    });
  });

  app.all(
    "/_casama/*",
    () =>
      new Response("Not found", {
        status: 404,
        headers: { ...BASE_HEADERS, "content-type": "text/plain" },
      }),
  );

  // ------------------------------------------------------------ The site

  app.get("/robots.txt", async (c) => {
    const r = await resolve(c.req.raw, "/robots.txt");
    if (r.kind !== "serve") return r.response;
    const own = await fileOf(r.page, "robots.txt");
    const body = own ? own.bytes : siteRobots(r.page.indexable, `https://${r.hostname}`);
    return new Response(body, {
      headers: {
        ...siteHeaders({ ...r.page, html: false }),
        "content-type": "text/plain; charset=utf-8",
      },
    });
  });

  app.get("/sitemap.xml", async (c) => {
    const r = await resolve(c.req.raw, "/sitemap.xml");
    if (r.kind !== "serve") return r.response;
    const own = await fileOf(r.page, "sitemap.xml");
    if (!own && !r.page.indexable)
      return new Response(NOT_FOUND, {
        status: 404,
        headers: {
          ...siteHeaders({ ...r.page, html: true }),
          "content-type": "text/html; charset=utf-8",
        },
      });
    const body = own ? own.bytes : siteSitemap(`https://${r.hostname}`, await sitePaths(r.page));
    return new Response(body, {
      headers: {
        ...siteHeaders({ ...r.page, html: false }),
        "content-type": "application/xml; charset=utf-8",
      },
    });
  });

  app.get("/favicon.ico", async (c) => {
    const r = await resolve(c.req.raw, "/favicon.ico");
    if (r.kind !== "serve") return r.response;
    const own = await fileOf(r.page, "favicon.ico");
    if (!own)
      return new Response(null, {
        status: 204,
        headers: { "cache-control": "public, max-age=300" },
      });
    return new Response(own.bytes, {
      headers: { ...siteHeaders({ ...r.page, html: false }), "content-type": own.mime },
    });
  });

  app.get("*", async (c) => {
    const url = new URL(c.req.url);
    const r = await resolve(c.req.raw, `${url.pathname}${url.search}`);
    if (r.kind !== "serve") return r.response;
    const candidates = sitePathCandidates(url.pathname);
    for (const path of candidates) {
      if (path === "index.html") {
        const etag = etagOf(r.page, "/");
        return notModified(c.req.raw, etag) ?? htmlResponse(r, r.page.html, true, etag);
      }
      const file = await fileOf(r.page, path);
      if (!file) continue;
      const etag = etagOf(r.page, path);
      const cached = notModified(c.req.raw, etag);
      if (cached) return cached;
      if (file.mime.startsWith("text/html"))
        return htmlResponse(r, new TextDecoder().decode(file.bytes), false, etag);
      return new Response(file.bytes, {
        headers: {
          ...siteHeaders({
            indexable: r.page.indexable,
            collects: r.page.collects,
            html: false,
            etag,
          }),
          "content-type": file.mime,
          "content-length": String(file.bytes.length),
        },
      });
    }
    // The site's own 404.html, or a plain one.
    const own = await fileOf(r.page, "404.html");
    if (own)
      return htmlResponse(
        r,
        new TextDecoder().decode(own.bytes),
        false,
        etagOf(r.page, "404"),
        404,
      );
    return new Response(NOT_FOUND, {
      status: 404,
      headers: {
        ...siteHeaders({ ...r.page, html: true }),
        "content-type": "text/html; charset=utf-8",
      },
    });
  });

  app.all("*", () => new Response("Method not allowed", { status: 405, headers: BASE_HEADERS }));

  return app;
}
