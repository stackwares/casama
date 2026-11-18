/**
 * Sites (docs/SITES-AND-DOMAINS-PLAN.md §7.2, §7.18): a public page served at its own address,
 * `name.<sites zone>`. One content model: the site is the page; this file only keeps which address
 * it has and how it is served. Used by the API (Publish to the Web) and the bots' tools.
 */
import type { Database } from "@casama/db";
import {
  hostIsLive,
  labelUnderZone,
  PAGE_SITE_NOTE,
  SITE_LABEL_MESSAGES,
  type SiteLabelProblem,
  siteAddress,
  siteLabelProblem,
  suggestSiteLabel,
} from "@casama/domain";
import { sql } from "drizzle-orm";
import { z } from "zod";
import { actingUserOf } from "./acting.ts";
import { track } from "./analytics.ts";
import { hashPageToken, newPageToken } from "./pages.ts";
import { ToolError, type ToolRegistry } from "./tools/registry.ts";

/** A retired address can be taken again by others after this long (§7.14). */
export const SITE_LABEL_RETIRE_DAYS = 90;

export class SiteError extends Error {
  readonly code: string;
  readonly status: number;
  constructor(status: number, code: string, message: string) {
    super(message);
    this.name = "SiteError";
    this.code = code;
    this.status = status;
  }
}

type Exec = Pick<Database, "execute">;

/** The workspace's site and domain limits; null means no limit (self-hosted). */
export async function siteLimits(db: Exec, orgId: string) {
  const [e] = await db.execute<{ limits: Record<string, unknown> | null }>(
    sql`select limits from public.entitlements where org_id = ${orgId}::uuid order by created_at desc limit 1`,
  );
  const l = e?.limits ?? {};
  const num = (v: unknown) => (typeof v === "number" ? v : null);
  const maxSites = num(l.max_sites);
  const maxDomains = num(l.max_custom_domains);
  // Search engines and the badge switch come with custom domains (decisions 6 and 7).
  return { maxSites, maxDomains, canIndex: maxDomains === null || maxDomains > 0 };
}

/** Live sites of a workspace: published and public, the one given left out. */
async function liveSites(db: Exec, orgId: string, except?: string) {
  const [r] = await db.execute<{ n: number }>(sql`
    select count(*)::int as n from public.sites s join public.pages p on p.id = s.page_id
    where s.org_id = ${orgId}::uuid and p.visibility = 'public'
      and (${except ?? null}::uuid is null or s.page_id <> ${except ?? null}::uuid)`);
  return r?.n ?? 0;
}

export interface AddressCheck {
  label: string;
  available: boolean;
  reason: SiteLabelProblem | "taken" | "retired" | null;
  message: string | null;
  url: string | null;
}

/** Whether a name is free for this workspace (and this page, which may already hold it). */
export async function checkSiteAddress(
  db: Exec,
  o: { orgId: string; label: string; zone: string; pageId?: string },
): Promise<AddressCheck> {
  const label = o.label.trim().toLowerCase();
  const url = `https://${siteAddress(label, o.zone)}`;
  const problem = siteLabelProblem(label);
  if (problem)
    return {
      label,
      available: false,
      reason: problem,
      message: SITE_LABEL_MESSAGES[problem],
      url: null,
    };
  const [taken] = await db.execute<{ page_id: string | null }>(sql`
    select page_id from public.site_hosts where hostname = ${siteAddress(label, o.zone)}`);
  if (taken && (!o.pageId || taken.page_id !== o.pageId))
    return {
      label,
      available: false,
      reason: "taken",
      message: SITE_LABEL_MESSAGES.taken,
      url: null,
    };
  const [retired] = await db.execute<{ org_id: string | null }>(sql`
    select org_id from public.site_labels_retired
    where label = ${label} and retired_at > now() - make_interval(days => ${SITE_LABEL_RETIRE_DAYS})`);
  if (retired && retired.org_id !== o.orgId)
    return {
      label,
      available: false,
      reason: "retired",
      message: SITE_LABEL_MESSAGES.retired,
      url: null,
    };
  return { label, available: true, reason: null, message: null, url };
}

export interface SiteHostOut {
  id: string;
  hostname: string;
  kind: string;
  is_primary: boolean;
  status: string;
  status_reason: string | null;
  domain_id: string | null;
  live: boolean;
  url: string;
}
export interface SiteOut {
  page_id: string;
  title: string;
  label: string | null;
  address_url: string | null;
  url: string | null;
  live: boolean;
  indexable: boolean;
  badge: boolean;
  can_index: boolean;
  hosts: SiteHostOut[];
  created_at: string;
}

type SiteRow = {
  page_id: string;
  org_id: string;
  title: string;
  indexable: boolean;
  badge: boolean;
  created_at: string | Date;
  servable: boolean;
};
type HostRow = {
  id: string;
  hostname: string;
  kind: string;
  is_primary: boolean;
  status: string;
  status_reason: string | null;
  domain_id: string | null;
  verified_at: string | null;
  page_id: string;
};

/** Whether a page can be served at all: public, not expired, not trashed or taken down, workspace not suspended. */
export const SERVABLE = sql`(p.visibility = 'public' and (p.expires_at is null or p.expires_at > now())
  and not exists (select 1 from public.creations cr where cr.page_id = p.id and (cr.deleted_at is not null or cr.taken_down_at is not null))
  and not exists (select 1 from public.organizations o where o.id = p.org_id and o.suspended_at is not null))`;

/**
 * Sites with their hosts. `db` decides what's visible: the caller's session (RLS) in the API, the
 * server's own connection in tools (which then filter by bot).
 */
export async function listSiteRows(
  db: Exec,
  o: { orgId: string; zone: string | null; pageId?: string; botId?: string; canIndex: boolean },
): Promise<SiteOut[]> {
  const sites = await db.execute<SiteRow>(sql`
    select s.page_id, s.org_id, p.title, s.indexable, s.badge, s.created_at, ${SERVABLE} as servable
    from public.sites s join public.pages p on p.id = s.page_id
    where s.org_id = ${o.orgId}::uuid
      and (${o.pageId ?? null}::uuid is null or s.page_id = ${o.pageId ?? null}::uuid)
      and (${o.botId ?? null}::uuid is null or p.bot_id = ${o.botId ?? null}::uuid)
    order by s.created_at desc limit 200`);
  if (!sites.length) return [];
  const hosts = await db.execute<HostRow>(sql`
    select id, hostname, kind, is_primary, status, status_reason, domain_id, verified_at, page_id
    from public.site_hosts where page_id = any(${`{${sites.map((s) => s.page_id).join(",")}}`}::uuid[])
    order by is_primary desc, kind, hostname`);
  return sites.map((s) => {
    const mine = hosts.filter((h) => h.page_id === s.page_id);
    const out = mine.map((h) => ({
      id: h.id,
      hostname: h.hostname,
      kind: h.kind,
      is_primary: h.is_primary,
      status: h.status,
      status_reason: h.status_reason,
      domain_id: h.domain_id,
      live: s.servable && hostIsLive(h),
      url: `https://${h.hostname}`,
    }));
    const address = mine.find((h) => h.kind === "address");
    const primary = out.find((h) => h.is_primary && h.live) ?? out.find((h) => h.live);
    return {
      page_id: s.page_id,
      title: s.title,
      label: address
        ? (labelUnderZone(address.hostname, o.zone) ?? address.hostname.split(".")[0] ?? null)
        : null,
      address_url: address ? `https://${address.hostname}` : null,
      url: primary?.url ?? null,
      live: !!primary,
      indexable: s.indexable,
      badge: s.badge,
      can_index: o.canIndex,
      hosts: out,
      created_at: new Date(s.created_at).toISOString(),
    };
  });
}

/**
 * Publish to the Web (§7.2): makes the page public (it asks first in the app and for bots) and
 * gives it an address. Changing the name is allowed once a day; the old name is retired.
 */
export async function publishSite(
  db: Database,
  o: {
    pageId: string;
    orgId: string;
    userId: string | null;
    zone: string;
    label?: string;
    indexable?: boolean;
    badge?: boolean;
    /** Where the publish came from, for analytics. */
    surface: "app" | "bot" | "api";
  },
) {
  const limits = await siteLimits(db, o.orgId);
  const [page] = await db.execute<{
    title: string;
    visibility: string;
    public_token_hash: string | null;
  }>(sql`
    select title, visibility, public_token_hash from public.pages where id = ${o.pageId}::uuid and org_id = ${o.orgId}::uuid`);
  if (!page) throw new SiteError(404, "page_not_found", "Page not found");
  const [existing] = await db.execute<{ label_changed_at: string | null }>(sql`
    select label_changed_at from public.sites where page_id = ${o.pageId}::uuid`);
  const [address] = await db.execute<{ id: string; hostname: string }>(sql`
    select id, hostname from public.site_hosts where page_id = ${o.pageId}::uuid and kind = 'address'`);
  // Over the limit: new sites can't go live, and existing ones can't change until back under.
  if (limits.maxSites !== null && (await liveSites(db, o.orgId, o.pageId)) >= limits.maxSites)
    throw new SiteError(
      402,
      "plan_limit",
      `Your plan allows ${limits.maxSites} live site${limits.maxSites === 1 ? "" : "s"}. Upgrade, or unpublish one first.`,
    );
  if (o.indexable && !limits.canIndex)
    throw new SiteError(402, "plan_limit", "Letting search engines find a site needs a paid plan.");
  if (o.badge === false && !limits.canIndex)
    throw new SiteError(402, "plan_limit", "Removing the badge needs a paid plan.");

  // The address: the one asked for, the one it has, or one made from the title.
  const currentLabel = address ? labelUnderZone(address.hostname, o.zone) : null;
  let label = o.label?.trim().toLowerCase() || currentLabel || null;
  if (label && label !== currentLabel) {
    const check = await checkSiteAddress(db, {
      orgId: o.orgId,
      label,
      zone: o.zone,
      pageId: o.pageId,
    });
    if (!check.available)
      throw new SiteError(
        check.reason === "taken" || check.reason === "retired" ? 409 : 400,
        check.reason === "taken" || check.reason === "retired"
          ? "address_taken"
          : "address_invalid",
        check.message ?? "That address can't be used.",
      );
    if (
      currentLabel &&
      existing?.label_changed_at &&
      Date.now() - new Date(existing.label_changed_at).getTime() < 86_400_000
    )
      throw new SiteError(
        409,
        "address_changed_recently",
        "A site's address can change once a day. Try again tomorrow.",
      );
  }
  if (!label) {
    const base = suggestSiteLabel(page.title).slice(0, 34).replace(/-+$/, "");
    for (let i = 0; i < 6 && !label; i++) {
      const candidate =
        i === 0 && base.length >= 3
          ? base
          : `${base || "site"}-${Math.random().toString(36).slice(2, 6)}`;
      if (
        (
          await checkSiteAddress(db, {
            orgId: o.orgId,
            label: candidate,
            zone: o.zone,
            pageId: o.pageId,
          })
        ).available
      )
        label = candidate;
    }
    if (!label) throw new SiteError(409, "address_taken", "Choose an address name for this site.");
  }
  const host = siteAddress(label, o.zone);

  await db.transaction(async (tx) => {
    await tx.execute(sql`
      insert into public.sites (page_id, org_id, created_by, indexable, badge)
      values (${o.pageId}::uuid, ${o.orgId}::uuid, ${o.userId}::uuid, ${o.indexable ?? false}, ${o.badge ?? true})
      on conflict (page_id) do update set
        indexable = coalesce(${o.indexable ?? null}::boolean, public.sites.indexable),
        badge = coalesce(${o.badge ?? null}::boolean, public.sites.badge),
        updated_at = now()`);
    if (!address || address.hostname !== host) {
      if (address) {
        await tx.execute(sql`delete from public.site_hosts where id = ${address.id}::uuid`);
        await tx.execute(
          sql`update public.sites set label_changed_at = now() where page_id = ${o.pageId}::uuid`,
        );
      }
      const [primary] = await tx.execute<{ id: string }>(sql`
        select id from public.site_hosts where page_id = ${o.pageId}::uuid and is_primary`);
      await tx.execute(sql`
        insert into public.site_hosts (hostname, kind, org_id, page_id, is_primary, status, verified_at)
        values (${host}, 'address', ${o.orgId}::uuid, ${o.pageId}::uuid, ${!primary}, 'active', now())`);
    }
    // Public, with no expiry. A page already public keeps its link.
    if (page.visibility !== "public" || !page.public_token_hash)
      await tx.execute(sql`
        update public.pages set visibility = 'public', expires_at = null,
          public_token_hash = coalesce(public_token_hash, ${hashPageToken(newPageToken())})
        where id = ${o.pageId}::uuid`);
    else
      await tx.execute(sql`update public.pages set expires_at = null where id = ${o.pageId}::uuid`);
    await tx.execute(sql`insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id, metadata)
      values (${o.orgId}::uuid, ${o.userId ? "user" : "system"}, ${o.userId}::uuid, 'site.published', 'page', ${o.pageId}::uuid,
              ${JSON.stringify({ host, title: page.title })}::jsonb)`);
  });
  if (!existing || page.visibility !== "public")
    track(db, {
      event: "site_published",
      userId: o.userId,
      orgId: o.orgId,
      properties: { surface: o.surface, indexable: !!o.indexable },
    });
  return { host, url: `https://${host}`, label };
}

/** Unpublish: the page goes private; its hosts are kept but serve nothing. */
export async function unpublishSite(
  db: Database,
  o: { pageId: string; orgId: string; userId: string | null },
) {
  await db.execute(sql`
    update public.pages set visibility = 'private', public_token_hash = null
    where id = ${o.pageId}::uuid and org_id = ${o.orgId}::uuid`);
  await db.execute(sql`insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id, metadata)
    values (${o.orgId}::uuid, 'user', ${o.userId}::uuid, 'site.unpublished', 'page', ${o.pageId}::uuid, '{}'::jsonb)`);
  track(db, { event: "site_unpublished", userId: o.userId, orgId: o.orgId });
}

/** The address host names a page has, so a caller can clear its lookup cache. */
export async function siteHostnames(db: Exec, pageId: string) {
  const rows = await db.execute<{ hostname: string }>(
    sql`select hostname from public.site_hosts where page_id = ${pageId}::uuid`,
  );
  return rows.map((r) => r.hostname);
}

/** The bots' tools (§7.18): publish one of their own pages, and see their sites. */
/**
 * Picks which host of a page visitors land on (§7.5). The current primary stays while it's live;
 * when it isn't, a live custom host takes over, else the address. `preferCustom` (a custom host
 * just went live, or a domain was just pointed here) moves the site from its address to its domain.
 */
export async function settlePrimary(db: Database, pageId: string, preferCustom = false) {
  const hosts = await db.execute<{
    id: string;
    hostname: string;
    kind: string;
    is_primary: boolean;
    status: string;
    verified_at: Date | null;
  }>(sql`
    select id, hostname, kind, is_primary, status, verified_at from public.site_hosts
    where page_id = ${pageId}::uuid
    order by kind desc, (hostname like 'www.%') desc, char_length(hostname)`);
  const live = hosts.filter(hostIsLive);
  const current = hosts.find((h) => h.is_primary);
  const custom = live.find((h) => h.kind === "custom");
  let pick = current && live.includes(current) ? current : (custom ?? live[0] ?? current);
  if (preferCustom && pick?.kind === "address" && custom) pick = custom;
  if (!pick || pick.id === current?.id) return pick?.hostname ?? null;
  const chosen = pick.id;
  await db.transaction(async (tx) => {
    await tx.execute(
      sql`update public.site_hosts set is_primary = false where page_id = ${pageId}::uuid and is_primary`,
    );
    await tx.execute(
      sql`update public.site_hosts set is_primary = true where id = ${chosen}::uuid`,
    );
  });
  return pick.hostname;
}

/** Points a workspace's domain at one of its sites (or none), moving the primary host along. */
export async function linkDomainToPage(
  db: Database,
  o: { domainId: string; orgId: string; pageId: string | null },
) {
  if (o.pageId) {
    const [s] = await db.execute<{ page_id: string }>(sql`
      select page_id from public.sites where page_id = ${o.pageId}::uuid and org_id = ${o.orgId}::uuid`);
    if (!s)
      throw new SiteError(
        409,
        "not_published",
        "Publish the site to the web first, then use your own domain.",
      );
  }
  const [old] = await db.execute<{ page_id: string | null }>(sql`
    select page_id from public.site_hosts where domain_id = ${o.domainId}::uuid and page_id is not null limit 1`);
  await db.execute(sql`
    update public.site_hosts set page_id = ${o.pageId}::uuid, is_primary = false
    where domain_id = ${o.domainId}::uuid`);
  if (old?.page_id && old.page_id !== o.pageId) await settlePrimary(db, old.page_id);
  if (o.pageId) await settlePrimary(db, o.pageId, true);
}

export function registerSiteTools(
  registry: ToolRegistry,
  deps: {
    db: Database;
    zone: string | null;
    requireVerifiedEmail?: boolean;
    /**
     * Domain search (D-329), when this server sells domains: names and prices, and the app link
     * that opens Find a Domain with a name filled in. null: buying is switched off right now.
     */
    domainSearch?: (
      orgId: string,
      query: string,
    ) => Promise<{
      items: Array<{
        name: string;
        available: boolean;
        reason: string | null;
        price_usd: number | null;
        renew_price_usd: number | null;
      }>;
      findUrl: (name: string) => string;
    } | null>;
  },
) {
  const { db, zone } = deps;
  if (!zone) return;
  if (deps.domainSearch) {
    const search = deps.domainSearch;
    registry.register({
      name: "domains.search",
      description:
        "Look up domain names for a site: whether each is free and what it costs a year (plus tax) and renews at. Read only: it never buys. Reply with a few good options and the link for each, which opens Find a Domain in the app where a person can buy it.",
      risk: "low",
      schema: z.object({
        query: z.string().min(2).max(100).describe("A name or a few words, like crumb bakery"),
      }),
      async execute(args, ctx) {
        const r = await search(ctx.orgId, args.query);
        if (!r) throw new ToolError("buying_off", "Buying domains isn't available right now.");
        const free = r.items.filter((i) => i.available);
        if (!free.length)
          return { content: `No names for "${args.query}" are free here. Try other words.` };
        const lines = free
          .slice(0, 8)
          .map(
            (i) =>
              `- ${i.name}: $${i.price_usd?.toFixed(2)} the first year, renews at $${i.renew_price_usd?.toFixed(2)} (${r.findUrl(i.name)})`,
          );
        return {
          content: `Free names (prices before tax; a person buys in Settings > Domains > Find a Domain):\n${lines.join("\n")}`,
        };
      },
    });
  }
  registry.register({
    name: "sites.publish",
    description: `Put one of your pages on the web at its own address, https://<name>.${zone}, so anyone can open it and search engines can find it once the person allows it. It makes the page public, so it always asks first. Pick a short address name (3 to 40 letters, digits and hyphens) or leave it out to use one made from the title. ${PAGE_SITE_NOTE}`,
    risk: "high",
    category: "publish",
    schema: z.object({
      page_id: z.uuid(),
      name: z.string().min(3).max(40).optional().describe("The address name, like crumb-bakery"),
    }),
    async execute(args, ctx) {
      const [p] = await db.execute<{ id: string; title: string }>(sql`
        select id, title from public.pages where id = ${args.page_id}::uuid and bot_id = ${ctx.botId}::uuid`);
      if (!p) throw new ToolError("page_not_found", "You have no page with that id.");
      const [verified] = deps.requireVerifiedEmail
        ? await db.execute<{ ok: boolean }>(
            sql`select public.worker_owner_email_verified(${ctx.orgId}::uuid) as ok`,
          )
        : [];
      if (verified && verified.ok === false)
        throw new ToolError(
          "email_unconfirmed",
          "The workspace owner needs to confirm their email address before sites can be published.",
        );
      const user = await actingUserOf(db, ctx.runId).catch(() => null);
      try {
        const r = await publishSite(db, {
          pageId: p.id,
          orgId: ctx.orgId,
          userId: user ?? null,
          zone,
          label: args.name,
          surface: "bot",
        });
        return {
          content: `"${p.title}" is live at ${r.url}. Search engines don't list it until the person turns that on in the Library.`,
          preview: r.url,
        };
      } catch (err) {
        if (err instanceof SiteError) throw new ToolError(err.code, err.message);
        throw err;
      }
    },
  });
  registry.register({
    name: "sites.status",
    readOnly: true,
    description:
      "Your pages that are on the web: their addresses, domains and whether each is live.",
    risk: "low",
    schema: z.object({}),
    async execute(_args, ctx) {
      const limits = await siteLimits(db, ctx.orgId);
      const sites = await listSiteRows(db, {
        orgId: ctx.orgId,
        zone,
        botId: ctx.botId,
        canIndex: limits.canIndex,
      });
      if (!sites.length) return { content: "None of your pages are on the web yet." };
      return {
        content: sites
          .map(
            (s) =>
              `- "${s.title}" (page ${s.page_id}): ${s.live ? `live at ${s.url}` : "not live"}${s.hosts
                .map(
                  (h) =>
                    `\n  ${h.hostname}: ${h.live ? "live" : h.status}${h.status_reason ? ` (${h.status_reason})` : ""}`,
                )
                .join("")}`,
          )
          .join("\n"),
      };
    },
  });
  registry.register({
    name: "domains.connect",
    description:
      "Show one of your sites on a domain the workspace already has (connected or bought in Settings > Domains). It changes what visitors see at that domain, so it always asks first. Publish the page with sites.publish first. This never buys, renews or moves a domain.",
    risk: "high",
    category: "publish",
    schema: z.object({
      domain: z.string().min(3).max(253).describe("The domain, like crumbbakery.com"),
      page_id: z.uuid(),
    }),
    async execute(args, ctx) {
      const name = args.domain
        .trim()
        .toLowerCase()
        .replace(/^https?:\/\//, "")
        .replace(/\/.*$/, "")
        .replace(/\.$/, "");
      const [p] = await db.execute<{ id: string; title: string }>(sql`
        select id, title from public.pages where id = ${args.page_id}::uuid and bot_id = ${ctx.botId}::uuid`);
      if (!p) throw new ToolError("page_not_found", "You have no page with that id.");
      const [d] = await db.execute<{ id: string; name: string }>(sql`
        select d.id, d.name from public.domains d
        where d.org_id = ${ctx.orgId}::uuid
          and (d.name = ${name} or d.name = ${name.replace(/^www\./, "")}
               or exists (select 1 from public.site_hosts h where h.domain_id = d.id and h.hostname = ${name}))
        limit 1`);
      if (!d)
        throw new ToolError(
          "domain_not_found",
          "The workspace has no such domain. A person connects or buys domains in Settings > Domains.",
        );
      try {
        await linkDomainToPage(db, { domainId: d.id, orgId: ctx.orgId, pageId: p.id });
      } catch (err) {
        if (err instanceof SiteError) throw new ToolError(err.code, err.message);
        throw err;
      }
      const hosts = await db.execute<{
        hostname: string;
        status: string;
        verified_at: Date | null;
        kind: string;
      }>(sql`
        select hostname, status, verified_at, kind from public.site_hosts where domain_id = ${d.id}::uuid`);
      const live = hosts.filter(hostIsLive).map((h) => `https://${h.hostname}`);
      return {
        content: live.length
          ? `"${p.title}" now shows at ${live.join(" and ")}.`
          : `"${p.title}" will show at ${d.name} once its DNS is set up; the domain isn't live yet (see Settings > Domains).`,
        preview: live[0],
      };
    },
  });
}
