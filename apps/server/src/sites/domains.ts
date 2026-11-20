/**
 * Connecting a domain a workspace owns (docs/SITES-AND-DOMAINS-PLAN.md §7.3–§7.5, §7.13, §7.17).
 *
 * A domain gets its own target (d-<16>.<zone>) and one or two hosts. Each host walks
 * pending_dns → pending_cert → active, and only a host with Casama's own proof is ever served
 * (`hostIsLive`): the edge saying "active" proves nothing about who owns the name. Upkeep looks at
 * waiting hosts every minute for their first hour and hourly after, re-checks live ones daily,
 * removes edge hostnames whose rows are gone, and pauses domains over the plan's limit.
 */
import { createHash, randomBytes } from "node:crypto";
import { linkDomainToPage, SiteError, settlePrimary, siteLimits, track } from "@casama/agent";
import type { Database } from "@casama/db";
import {
  domainTarget,
  HOST_MESSAGES,
  HOST_TIMINGS,
  hostCheckDue,
  hostIsLive,
  hostsFor,
  parseHost,
} from "@casama/domain";
import { sql } from "drizzle-orm";
import { CloudflareError } from "../cloudflare.ts";
import type { Env } from "../env.ts";
import { queueAccountEmail } from "../services/account-emails.ts";
import {
  APEX_ALIAS_PROVIDERS,
  DNS_PROVIDER_NAMES,
  type DnsLookup,
  DohLookup,
  dnsProviderFor,
} from "./dns.ts";
import { CloudflareHostnames, type HostnameProvider, OwnEdgeHostnames } from "./hostnames.ts";

type Exec = Pick<Database, "execute">;

/** At most this many unproved hosts a workspace (§7.4): the edge bills pending hostnames. */
export const MAX_PENDING_HOSTS = 10;
/** Claims of one host by other workspaces a day. */
export const CLAIMS_PER_DAY = 3;
/** Hosts looked at per upkeep pass (§12: at most 20 a minute). */
export const CHECKS_PER_PASS = 20;
/** A plan that no longer covers a domain: notices on day 0 and 10, paused on day 14 (§7.13). */
export const OVER_LIMIT_PAUSE_DAYS = 14;
export const OVER_LIMIT_NOTICE_DAYS = 10;
/** The cost notice: owners hear at 80 and 95 of the 100 included custom hostnames (§8). */
export const HOSTNAME_NOTICE_AT = [80, 95];

// ------------------------------------------------------------------ Settings

/** This server's id at /_casama/probe: CASAMA_INSTANCE_ID, or one derived from a server secret. */
export function siteInstanceId(env: Pick<Env, "CASAMA_INSTANCE_ID" | "DATABASE_URL">) {
  if (env.CASAMA_INSTANCE_ID) return env.CASAMA_INSTANCE_ID;
  return `casama-${createHash("sha256").update(`site-probe:${env.DATABASE_URL}`).digest("hex").slice(0, 20)}`;
}

/** Cloudflare for SaaS when its token is set, else Caddy on this server, else none. */
export function hostnameProviderFromEnv(env: Env, fetchFn?: typeof fetch): HostnameProvider | null {
  if (env.CASAMA_SITES_CF_ZONE_ID && env.CASAMA_SITES_CF_API_TOKEN)
    return new CloudflareHostnames({
      zoneId: env.CASAMA_SITES_CF_ZONE_ID,
      apiToken: env.CASAMA_SITES_CF_API_TOKEN,
      apiUrl: env.CASAMA_SITES_CF_API_URL,
      fetch: fetchFn,
    });
  if (env.CASAMA_SITES_OWN_EDGE)
    return new OwnEdgeHostnames({ instanceId: siteInstanceId(env), fetch: fetchFn });
  return null;
}

export const dnsLookupFromEnv = (env: Env, fetchFn?: typeof fetch): DnsLookup =>
  new DohLookup({
    urls: env.CASAMA_SITES_DOH_URLS.split(",")
      .map((u) => u.trim())
      .filter(Boolean),
    fetch: fetchFn,
  });

/** What the worker's domains upkeep runs with; null when connected domains can't exist here. */
export function domainsUpkeepFromEnv(env: Env): DomainsUpkeepOptions | null {
  const provider = hostnameProviderFromEnv(env);
  if (!env.CASAMA_SITES_ZONE || !provider) return null;
  return {
    env,
    zone: env.CASAMA_SITES_ZONE,
    provider,
    dns: dnsLookupFromEnv(env),
    adminEmails: env.INSTANCE_ADMIN_EMAILS,
  };
}

export type DomainsUpkeepOptions = Omit<DomainsContext, "db" | "notify"> & {
  adminEmails?: string;
};

export interface DomainsContext {
  db: Database;
  env: Env;
  zone: string;
  provider: HostnameProvider;
  dns: DnsLookup;
  /** In-app notices with a push; default: an inbox row only. */
  notify?: (
    userId: string,
    orgId: string,
    kind: string,
    payload: NoticePayload,
  ) => Promise<unknown>;
  now?: () => Date;
}

export interface NoticePayload {
  title: string;
  body: string;
  link?: string;
  [k: string]: unknown;
}

// ------------------------------------------------------------------ Rows

export type DomainRow = {
  id: string;
  name: string;
  kind: "connected" | "registered";
  org_id: string | null;
  target: string;
  verify_code: string;
  dns_provider: string | null;
  checked_at: Date | null;
  over_limit_since: Date | null;
  status: string | null;
  expires_at: Date | null;
  auto_renew: boolean;
  locked: boolean;
  privacy: boolean;
  transfer_after: Date | null;
  unlocked_at: Date | null;
  registrant_verified_at: Date | null;
  managed_records: string[];
  purchased_by: string | null;
  renew_price_usd: string | null;
  registrar: string | null;
  created_at: Date;
};

export type HostRow = {
  id: string;
  hostname: string;
  kind: "address" | "custom";
  org_id: string;
  page_id: string | null;
  domain_id: string | null;
  is_primary: boolean;
  status: string;
  status_reason: string | null;
  status_changed_at: Date;
  provider_ref: string | null;
  ownership_name: string | null;
  ownership_value: string | null;
  verified_at: Date | null;
  last_checked_at: Date | null;
  proof_missing_since: Date | null;
  created_at: Date;
};

const getDomain = async (db: Exec, id: string) =>
  (await db.execute<DomainRow>(sql`select * from public.domains where id = ${id}::uuid`))[0] ??
  null;

const domainHosts = (db: Exec, domainId: string) =>
  db.execute<HostRow>(sql`
    select * from public.site_hosts where domain_id = ${domainId}::uuid
    order by (hostname like 'www.%') desc, char_length(hostname), hostname`);

/** The host a domain is mostly about: `www` or the one subdomain, never the bare name if both. */
export function mainHost<T extends { hostname: string }>(domain: { name: string }, hosts: T[]) {
  return hosts.find((h) => h.hostname !== domain.name) ?? hosts[0] ?? null;
}

const event = async (
  db: Exec,
  e: { domainId: string; orgId: string | null; kind: string; detail?: unknown; dedupe?: string },
) => {
  const rows = await db.execute<{ id: string }>(sql`
    insert into public.domain_events (domain_id, org_id, kind, detail, dedupe)
    values (${e.domainId}::uuid, ${e.orgId}::uuid, ${e.kind}, ${JSON.stringify(e.detail ?? {})}::jsonb, ${e.dedupe ?? null})
    on conflict (dedupe) do nothing returning id`);
  return rows.length > 0;
};

// ------------------------------------------------------------------ Notices

/** An in-app notice to the workspace's owners and admins, once per dedupe key. */
export async function noticeAdmins(
  ctx: Pick<DomainsContext, "db" | "notify">,
  orgId: string,
  kind: string,
  payload: NoticePayload,
  email?: { kind: string; dedupe: string; data: Record<string, unknown> },
) {
  const people = await ctx.db.execute<{ user_id: string }>(sql`
    select user_id from public.memberships where org_id = ${orgId}::uuid and role in ('owner', 'admin')`);
  for (const p of people) {
    if (ctx.notify) await ctx.notify(p.user_id, orgId, kind, payload).catch(() => {});
    else
      await ctx.db.execute(sql`
        insert into public.notifications (user_id, org_id, kind, payload)
        values (${p.user_id}::uuid, ${orgId}::uuid, ${kind}, ${JSON.stringify(payload)}::jsonb)`);
  }
  if (email)
    await queueAccountEmail(ctx.db, {
      kind: email.kind as never,
      orgId,
      dedupeKey: email.dedupe,
      data: email.data as never,
    });
}

/**
 * A notice to the server's instance owners (INSTANCE_ADMIN_EMAILS; without it, the first account).
 * Answers how many were told.
 */
export async function noticeInstanceOwners(
  db: Exec,
  adminEmails: string | undefined,
  kind: string,
  payload: NoticePayload,
) {
  const admins = (adminEmails ?? "")
    .split(",")
    .map((e) => e.trim().toLowerCase())
    .filter(Boolean);
  const body = JSON.stringify(payload);
  const rows = admins.length
    ? await db.execute(sql`
        insert into public.notifications (user_id, kind, payload)
        select u.id, ${kind}, ${body}::jsonb from auth.users u where lower(u.email) in (select jsonb_array_elements_text(${JSON.stringify(admins)}::jsonb)) returning id`)
    : await db.execute(sql`
        insert into public.notifications (user_id, kind, payload)
        select u.id, ${kind}, ${body}::jsonb from auth.users u order by u.created_at limit 1 returning id`);
  return rows.length;
}

export const domainLink = (id: string) => `/settings/domains/${id}`;

// ------------------------------------------------------------------ Records to add

export interface DomainRecordView {
  host: string;
  /** CNAME, ALIAS, A, AAAA, TXT, or FORWARD (a forwarding rule at their registrar). */
  type: string;
  name: string;
  value: string;
  /** point: makes the name reach Casama. proof: shows it's theirs. forward: sends it to www. */
  purpose: "point" | "proof" | "forward" | "claim";
  required: boolean;
  /** What public DNS shows now, when looked up; null when not looked up or unsettled. */
  seen: string[] | null;
  ok: boolean | null;
}

/** Whether the bare domain can be a host of its own with this DNS company (§7.5). */
export function apexSupported(env: Env, provider: HostnameProvider, dnsProvider: string | null) {
  if (provider.kind === "own_edge")
    return !!(env.CASAMA_SITES_SERVER_IPV4 || env.CASAMA_SITES_SERVER_IPV6);
  if (dnsProvider === "cloudflare") return true;
  return (
    env.CASAMA_SITES_APEX === "aname" && !!dnsProvider && APEX_ALIAS_PROVIDERS.has(dnsProvider)
  );
}

const pagesHostOf = (env: Env) => new URL(env.PAGES_URL).hostname;

/** The records a person adds for a domain, in the order to add them (§7.4, §7.5, §7.12). */
export function domainRecords(
  env: Env,
  provider: HostnameProvider,
  domain: Pick<DomainRow, "name" | "target" | "dns_provider">,
  hosts: Pick<HostRow, "hostname" | "ownership_name" | "ownership_value">[],
): DomainRecordView[] {
  const out: DomainRecordView[] = [];
  const base = { seen: null, ok: null };
  const own = provider.kind === "own_edge";
  for (const h of hosts) {
    const bare = h.hostname === domain.name && hosts.length > 1;
    const isApex = h.hostname === domain.name;
    if (own && (isApex || env.CASAMA_SITES_SERVER_IPV4 || env.CASAMA_SITES_SERVER_IPV6)) {
      if (env.CASAMA_SITES_SERVER_IPV4)
        out.push({
          ...base,
          host: h.hostname,
          type: "A",
          name: h.hostname,
          value: env.CASAMA_SITES_SERVER_IPV4,
          purpose: "point",
          required: true,
        });
      if (env.CASAMA_SITES_SERVER_IPV6)
        out.push({
          ...base,
          host: h.hostname,
          type: "AAAA",
          name: h.hostname,
          value: env.CASAMA_SITES_SERVER_IPV6,
          purpose: "point",
          required: !env.CASAMA_SITES_SERVER_IPV4,
        });
    } else if (own) {
      out.push({
        ...base,
        host: h.hostname,
        type: "CNAME",
        name: h.hostname,
        value: pagesHostOf(env),
        purpose: "point",
        required: true,
      });
    } else {
      const type = isApex && domain.dns_provider !== "cloudflare" ? "ALIAS" : "CNAME";
      out.push({
        ...base,
        host: h.hostname,
        type,
        name: h.hostname,
        value: domain.target,
        purpose: "point",
        required: true,
      });
    }
    if (h.ownership_name && h.ownership_value)
      out.push({
        ...base,
        host: h.hostname,
        type: "TXT",
        name: h.ownership_name,
        value: h.ownership_value,
        purpose: "proof",
        // Proof A (the CNAME) is enough for a subdomain on Cloudflare; the bare domain and every
        // host on a self-hosted server need the TXT (§7.4, §7.12).
        required: own || isApex || bare,
      });
  }
  // A bare domain this DNS company can't point at Casama forwards to www at the registrar.
  const www = `www.${domain.name}`;
  if (hosts.length === 1 && hosts[0]?.hostname === www)
    out.push({
      ...base,
      host: domain.name,
      type: "FORWARD",
      name: domain.name,
      value: `https://${www}`,
      purpose: "forward",
      required: false,
    });
  return out;
}

/** Looks up what public DNS shows for each record (best effort, for the connect screen). */
export async function withSeen(dns: DnsLookup, records: DomainRecordView[]) {
  return Promise.all(
    records.map(async (r) => {
      if (r.type === "TXT") {
        const seen = await dns.txt(r.name);
        return { ...r, seen, ok: seen ? seen.includes(r.value) : null };
      }
      if (r.type === "CNAME" || r.type === "ALIAS") {
        const seen = await dns.cnames(r.name);
        // A flattened or proxied record shows no CNAME: the TXT proves those.
        return { ...r, seen, ok: seen ? seen.includes(r.value) : null };
      }
      return r;
    }),
  );
}

// ------------------------------------------------------------------ Proof

/**
 * Proof A or B (§7.4), checked against two resolvers that agree. On a self-hosted server only the
 * TXT counts: anyone can point a name at a public address. null: DNS couldn't say right now.
 */
export async function proveHost(
  ctx: Pick<DomainsContext, "dns" | "provider">,
  domain: Pick<DomainRow, "target">,
  host: Pick<HostRow, "hostname" | "ownership_name" | "ownership_value">,
): Promise<boolean | null> {
  const viaCname = ctx.provider.kind !== "own_edge";
  const [cnames, txt] = await Promise.all([
    viaCname ? ctx.dns.cnames(host.hostname) : Promise.resolve(null),
    host.ownership_name ? ctx.dns.txt(host.ownership_name) : Promise.resolve(null),
  ]);
  if (viaCname && cnames?.includes(domain.target)) return true;
  if (host.ownership_value && txt?.includes(host.ownership_value)) return true;
  if ((viaCname ? cnames === null : true) && txt === null) return null;
  return false;
}

// ------------------------------------------------------------------ Primary host

export { settlePrimary };

// ------------------------------------------------------------------ Connect

export interface ConnectResult {
  domainId: string | null;
  /** Another workspace has proved this domain: add this record to take it over (§7.4). */
  claim: { type: "TXT"; name: string; value: string } | null;
}

const random16 = () => {
  const alphabet = "abcdefghijklmnopqrstuvwxyz0123456789";
  return [...randomBytes(16)].map((b) => alphabet[b % alphabet.length]).join("");
};

/** A site page of this workspace, or a 409 telling them to publish it first. */
async function sitePageOf(db: Exec, orgId: string, pageId: string) {
  const [s] = await db.execute<{ page_id: string }>(sql`
    select page_id from public.sites where page_id = ${pageId}::uuid and org_id = ${orgId}::uuid`);
  if (!s)
    throw new SiteError(
      409,
      "not_published",
      "Publish the site to the web first, then use your own domain.",
    );
  return s.page_id;
}

/** Workspace admins connect a domain they own (POST /v1/orgs/{id}/domains). */
export async function connectDomain(
  ctx: DomainsContext,
  o: { orgId: string; userId: string; name: string; pageId?: string | null },
): Promise<ConnectResult> {
  const { db } = ctx;
  const parsed = parseHost(o.name);
  if ("problem" in parsed)
    throw new SiteError(400, "domain_invalid", HOST_MESSAGES[parsed.problem]);
  const { domain: name, hosts: wanted } = hostsFor(parsed);
  const zone = ctx.zone.toLowerCase();
  const own = [zone, pagesHostOf(ctx.env), new URL(ctx.env.PUBLIC_APP_URL).hostname];
  if (own.some((z) => name === z || name.endsWith(`.${z}`) || z.endsWith(`.${name}`)))
    throw new SiteError(400, "domain_invalid", "That domain belongs to this server.");
  const pageId = o.pageId ? await sitePageOf(db, o.orgId, o.pageId) : null;

  const [existing] = await db.execute<DomainRow & { proved: boolean }>(sql`
    select d.*, exists (select 1 from public.site_hosts h where h.domain_id = d.id and h.verified_at is not null) as proved
    from public.domains d where d.name = ${name}`);
  if (existing?.org_id === o.orgId) {
    if (pageId) await linkPage(ctx, existing.id, pageId);
    return { domainId: existing.id, claim: null };
  }
  if (existing) {
    const taken = await takeOver(ctx, existing, o.orgId);
    if (taken) return { domainId: null, claim: taken };
  }

  // Limits: the plan's domains (§7.13) and the unproved-claims guard (§7.4).
  const limits = await siteLimits(db, o.orgId);
  const [count] = await db.execute<{ domains: number; pending: number }>(sql`
    select (select count(*)::int from public.domains where org_id = ${o.orgId}::uuid) as domains,
           (select count(*)::int from public.site_hosts where org_id = ${o.orgId}::uuid
              and kind = 'custom' and status = 'pending_dns' and verified_at is null) as pending`);
  if (limits.maxDomains !== null && (count?.domains ?? 0) >= limits.maxDomains)
    throw new SiteError(
      402,
      "plan_limit",
      limits.maxDomains === 0
        ? "Your plan doesn't include your own domains. Upgrade to use one."
        : `Your plan includes ${limits.maxDomains} domain${limits.maxDomains === 1 ? "" : "s"}. Remove one or upgrade to add another.`,
    );
  if ((count?.pending ?? 0) >= MAX_PENDING_HOSTS)
    throw new SiteError(
      429,
      "too_many_pending",
      "Finish setting up the domains you've started before adding another.",
    );

  // Which DNS company: the instructions and whether the bare domain can be a host (§7.5).
  const ns = await ctx.dns.ns(name).catch(() => null);
  const dnsProvider = ns ? dnsProviderFor(ns) : null;
  const hosts =
    wanted.length > 1 && !apexSupported(ctx.env, ctx.provider, dnsProvider)
      ? wanted.filter((h) => h !== name)
      : wanted;

  const domainId = await db.transaction(async (tx) => {
    const [d] = await tx.execute<{ id: string }>(sql`
      insert into public.domains (name, kind, org_id, target, verify_code, dns_provider)
      values (${name}, 'connected', ${o.orgId}::uuid, ${domainTarget(zone, random16())}, ${randomBytes(12).toString("base64url")}, ${dnsProvider})
      returning id`);
    for (const host of hosts)
      await tx.execute(sql`
        insert into public.site_hosts (hostname, kind, org_id, page_id, domain_id, status)
        values (${host}, 'custom', ${o.orgId}::uuid, ${pageId}::uuid, ${d?.id}::uuid, 'pending_dns')`);
    return d?.id as string;
  });
  await event(db, { domainId, orgId: o.orgId, kind: "connected", detail: { by: o.userId, hosts } });
  // Registered at the edge at once: the ownership record comes from the edge (§7.4 step 1).
  for (const h of await domainHosts(db, domainId)) await register(ctx, h).catch(() => {});
  track(db, {
    event: "domain_connect_started",
    userId: o.userId,
    orgId: o.orgId,
    properties: { tld: parsed.publicSuffix, kind: "connected" },
  });
  return { domainId, claim: null };
}

/**
 * Another workspace holds this name. An unproved claim older than an hour gives way; a proved one
 * moves only when the new workspace proves it again with its own TXT record (§7.4). Returns the
 * record to add while the proof isn't there yet, or null once the old row is gone.
 */
async function takeOver(
  ctx: DomainsContext,
  existing: DomainRow & { proved: boolean },
  orgId: string,
) {
  const { db } = ctx;
  if (existing.kind === "registered" && existing.org_id)
    throw new SiteError(409, "domain_in_use", "Another workspace uses this domain.");
  const [attempts] = await db.execute<{ n: number }>(sql`
    select count(*)::int as n from public.domain_events
    where domain_id = ${existing.id}::uuid and kind = 'claim_attempt' and created_at > now() - interval '1 day'`);
  if ((attempts?.n ?? 0) >= CLAIMS_PER_DAY)
    throw new SiteError(
      429,
      "too_many_claims",
      "This domain was claimed too many times today. Try again tomorrow.",
    );
  await event(db, { domainId: existing.id, orgId, kind: "claim_attempt" });
  const age = (ctx.now?.() ?? new Date()).getTime() - new Date(existing.created_at).getTime();
  if (existing.org_id && !existing.proved && age < HOST_TIMINGS.claimLockMs)
    throw new SiteError(
      409,
      "domain_in_use",
      "Another workspace started connecting this domain. Try again in an hour.",
    );
  if (existing.org_id && existing.proved) {
    // The new workspace's own code, kept as an event on the old row.
    const [prev] = await db.execute<{ code: string }>(sql`
      select detail->>'code' as code from public.domain_events
      where domain_id = ${existing.id}::uuid and kind = 'claim' and org_id = ${orgId}::uuid
      order by created_at desc limit 1`);
    const code = prev?.code ?? `casama-claim=${randomBytes(18).toString("base64url")}`;
    if (!prev) await event(db, { domainId: existing.id, orgId, kind: "claim", detail: { code } });
    const record = { type: "TXT" as const, name: `_casama-claim.${existing.name}`, value: code };
    const seen = await ctx.dns.txt(record.name);
    if (!seen?.includes(code)) return record;
  }
  // Give way: the old row and its hosts go (the delete trigger queues the edge cleanup).
  if (existing.org_id)
    await noticeAdmins(ctx, existing.org_id, "domain_disconnected", {
      title: `${existing.name} was connected by another workspace`,
      body: existing.proved
        ? `Someone proved they control ${existing.name} and connected it to their workspace. Your site still works at its own address.`
        : `${existing.name} was never set up here, and another workspace has now connected it.`,
      link: "/settings/domains",
    });
  await db.execute(sql`delete from public.domains where id = ${existing.id}::uuid`);
  return null;
}

/** Registers a host at the edge (or again, after it was removed there). */
async function register(ctx: DomainsContext, h: HostRow) {
  const r = await ctx.provider.add(h.hostname);
  await ctx.db.execute(sql`
    update public.site_hosts set provider_ref = ${r.ref}, ownership_name = ${r.ownership.name},
      ownership_value = ${r.ownership.value}
    where id = ${h.id}::uuid`);
  return {
    ...h,
    provider_ref: r.ref,
    ownership_name: r.ownership.name,
    ownership_value: r.ownership.value,
  };
}

/** Points a domain's hosts at a site page (or none). */
export async function linkPage(
  ctx: Pick<DomainsContext, "db">,
  domainId: string,
  pageId: string | null,
) {
  const d = await getDomain(ctx.db, domainId);
  if (!d?.org_id) throw new SiteError(404, "domain_not_found", "Domain not found");
  await linkDomainToPage(ctx.db, { domainId, orgId: d.org_id, pageId });
}

/** The site's primary host, chosen by a person: it must be live (PATCH primary_host). */
export async function choosePrimary(db: Database, domainId: string, hostname: string) {
  const [h] = await db.execute<HostRow>(sql`
    select * from public.site_hosts where domain_id = ${domainId}::uuid and hostname = ${hostname.toLowerCase()}`);
  if (!h) throw new SiteError(404, "host_not_found", "That host isn't part of this domain.");
  if (!h.page_id) throw new SiteError(409, "not_published", "Point the domain at a site first.");
  if (!hostIsLive(h)) throw new SiteError(409, "host_not_live", "That host isn't live yet.");
  await db.transaction(async (tx) => {
    await tx.execute(
      sql`update public.site_hosts set is_primary = false where page_id = ${h.page_id}::uuid and is_primary`,
    );
    await tx.execute(sql`update public.site_hosts set is_primary = true where id = ${h.id}::uuid`);
  });
}

/** Disconnect: a connected domain goes; a bought one stays registered and only its site link goes. */
export async function disconnectDomain(
  ctx: Pick<DomainsContext, "db">,
  domainId: string,
  userId: string,
) {
  const d = await getDomain(ctx.db, domainId);
  if (!d?.org_id) throw new SiteError(404, "domain_not_found", "Domain not found");
  const pages = await ctx.db.execute<{ page_id: string }>(sql`
    select distinct page_id from public.site_hosts where domain_id = ${domainId}::uuid and page_id is not null`);
  if (d.kind === "registered") await linkPage(ctx, domainId, null);
  else {
    await event(ctx.db, { domainId, orgId: d.org_id, kind: "removed", detail: { by: userId } });
    await ctx.db.execute(sql`delete from public.domains where id = ${domainId}::uuid`);
  }
  for (const p of pages) await settlePrimary(ctx.db, p.page_id);
  return d;
}

// ------------------------------------------------------------------ Checking

export interface CheckOutcome {
  hostname: string;
  from: string;
  to: string;
}

const setStatus = (db: Exec, id: string, status: string, reason: string | null) =>
  db.execute(sql`
    update public.site_hosts set status = ${status}, status_reason = ${reason},
      status_changed_at = now(), last_checked_at = now()
    where id = ${id}::uuid`);

/** Looks at one host and moves it along its states (§7.4). */
export async function checkHost(
  ctx: DomainsContext,
  hostIn: HostRow,
  domain: DomainRow,
  force = false,
): Promise<CheckOutcome> {
  const { db } = ctx;
  const now = ctx.now?.() ?? new Date();
  let h = hostIn;
  const out = (to: string) => ({ hostname: h.hostname, from: hostIn.status, to });
  // Check Again brings a failed or disconnected host back to the start.
  if (force && (h.status === "failed" || h.status === "disconnected")) {
    await setStatus(db, h.id, "pending_dns", null);
    h = { ...h, status: "pending_dns", status_changed_at: now, provider_ref: h.provider_ref };
  }
  if (!["pending_dns", "pending_cert", "active"].includes(h.status)) return out(h.status);
  const since = now.getTime() - new Date(h.status_changed_at).getTime();
  try {
    if (!h.provider_ref) h = await register(ctx, h);
  } catch (e) {
    await db.execute(
      sql`update public.site_hosts set last_checked_at = now() where id = ${h.id}::uuid`,
    );
    if (e instanceof CloudflareError && !e.retryable && h.status === "pending_dns")
      await db.execute(
        sql`update public.site_hosts set status_reason = 'refused' where id = ${h.id}::uuid`,
      );
    return out(h.status);
  }

  if (h.status === "pending_dns") {
    const proved = await proveHost(ctx, domain, h);
    if (proved) {
      await db.execute(sql`
        update public.site_hosts set verified_at = now(), proof_missing_since = null, status = 'pending_cert',
          status_reason = null, status_changed_at = now(), last_checked_at = now()
        where id = ${h.id}::uuid`);
      await event(db, {
        domainId: domain.id,
        orgId: domain.org_id,
        kind: "proved",
        detail: { host: h.hostname },
      });
      await ctx.provider.recheck(h.provider_ref as string).catch(() => {});
      return checkHost(
        ctx,
        { ...h, status: "pending_cert", verified_at: now, status_changed_at: now },
        domain,
      );
    }
    if (since > HOST_TIMINGS.pendingDnsMs) {
      await failHost(ctx, h, domain, "failed", "not_pointed");
      return out("failed");
    }
    await db.execute(sql`
      update public.site_hosts set last_checked_at = now(), status_reason = 'not_pointed' where id = ${h.id}::uuid`);
    await dnsReminders(ctx, h, domain, since);
    return out("pending_dns");
  }

  if (h.status === "pending_cert") {
    const edge = await ctx.provider.get(h.provider_ref as string).catch(() => undefined);
    if (edge === null) {
      // Gone at the edge: register again and keep waiting.
      await register(ctx, { ...h, provider_ref: null }).catch(() => {});
    } else if (edge?.state === "active") {
      await setStatus(db, h.id, "active", null);
      if (h.page_id) await settlePrimary(db, h.page_id, true);
      await wentLive(ctx, h, domain);
      return out("active");
    } else if (edge?.state === "failed" || since > HOST_TIMINGS.pendingCertMs) {
      await failHost(
        ctx,
        h,
        domain,
        "failed",
        edge?.state === "failed" ? (edge.reason ?? "refused") : "timed_out",
      );
      return out("failed");
    }
    await db.execute(sql`
      update public.site_hosts set last_checked_at = now(), status_reason = ${edge?.reason ?? null}
      where id = ${h.id}::uuid`);
    return out("pending_cert");
  }

  // Active: the daily re-check (§7.4). The proof must still be there, and the edge must still have it.
  const proved = await proveHost(ctx, domain, h);
  if (proved === false) {
    const missingSince = h.proof_missing_since ? new Date(h.proof_missing_since) : now;
    if (now.getTime() - missingSince.getTime() >= HOST_TIMINGS.proofGoneMs) {
      await failHost(ctx, h, domain, "disconnected", "proof_gone");
      return out("disconnected");
    }
    await db.execute(sql`
      update public.site_hosts set proof_missing_since = ${missingSince.toISOString()}::timestamptz, last_checked_at = now()
      where id = ${h.id}::uuid`);
    return out("active");
  }
  if (proved)
    await db.execute(
      sql`update public.site_hosts set proof_missing_since = null where id = ${h.id}::uuid`,
    );
  const edge = await ctx.provider.get(h.provider_ref as string).catch(() => undefined);
  if (edge === null) {
    await register(ctx, { ...h, provider_ref: null }).catch(() => {});
    await setStatus(db, h.id, "pending_cert", null);
    if (h.page_id) await settlePrimary(db, h.page_id);
    return out("pending_cert");
  }
  await db.execute(
    sql`update public.site_hosts set last_checked_at = now() where id = ${h.id}::uuid`,
  );
  return out("active");
}

/** failed or disconnected: the edge hostname goes (it's billed), the row and records stay. */
async function failHost(
  ctx: DomainsContext,
  h: HostRow,
  domain: DomainRow,
  status: "failed" | "disconnected",
  reason: string,
) {
  if (h.provider_ref) await ctx.provider.remove(h.provider_ref).catch(() => {});
  await ctx.db.execute(sql`
    update public.site_hosts set status = ${status}, status_reason = ${reason}, status_changed_at = now(),
      last_checked_at = now(), provider_ref = null, verified_at = case when ${status} = 'disconnected' then null else verified_at end
    where id = ${h.id}::uuid`);
  if (h.page_id) await settlePrimary(ctx.db, h.page_id);
  await event(ctx.db, {
    domainId: domain.id,
    orgId: domain.org_id,
    kind: status,
    detail: { host: h.hostname, reason },
  });
  if (!domain.org_id) return;
  const main = mainHost(domain, await domainHosts(ctx.db, domain.id));
  if (main?.id !== h.id) return;
  if (status === "disconnected")
    await noticeAdmins(
      ctx,
      domain.org_id,
      "domain_disconnected",
      {
        title: `${h.hostname} was disconnected`,
        body: `The DNS record that connects ${h.hostname} to your site has been missing for 7 days, so it no longer shows your site. Check Again once the record is back.`,
        link: domainLink(domain.id),
      },
      {
        kind: "domain_disconnected",
        dedupe: `domain_disconnected:${h.id}:${new Date().toISOString().slice(0, 10)}`,
        data: { domain_name: h.hostname, domain_id: domain.id },
      },
    );
  else
    await noticeAdmins(ctx, domain.org_id, "domain_needs_dns", {
      title: `${h.hostname} couldn't be connected`,
      body:
        reason === "not_pointed"
          ? `The DNS records for ${h.hostname} weren't found in 7 days. Add them, then tap Check Again.`
          : `${h.hostname} couldn't get its certificate. Open the domain to see why, then tap Check Again.`,
      link: domainLink(domain.id),
    });
  track(ctx.db, {
    event: "domain_connect_failed",
    orgId: domain.org_id,
    properties: { kind: domain.kind, reason },
  });
}

async function wentLive(ctx: DomainsContext, h: HostRow, domain: DomainRow) {
  await event(ctx.db, {
    domainId: domain.id,
    orgId: domain.org_id,
    kind: "live",
    detail: { host: h.hostname },
  });
  if (!domain.org_id) return;
  const main = mainHost(domain, await domainHosts(ctx.db, domain.id));
  if (main?.id !== h.id) return;
  await noticeAdmins(ctx, domain.org_id, "domain_live", {
    title: `${h.hostname} is live`,
    body: h.page_id
      ? `Your site now opens at https://${h.hostname}.`
      : `${h.hostname} is ready. Point it at a site to show it there.`,
    link: domainLink(domain.id),
  });
  track(ctx.db, {
    event: "domain_connected",
    orgId: domain.org_id,
    properties: { kind: domain.kind },
  });
}

/** DNS still not found after 1 hour, 1 day and 6 days; an email at 1 day (§7.17). */
async function dnsReminders(ctx: DomainsContext, h: HostRow, domain: DomainRow, waitedMs: number) {
  if (!domain.org_id || domain.kind !== "connected") return;
  const main = mainHost(domain, await domainHosts(ctx.db, domain.id));
  if (main?.id !== h.id) return;
  const steps: Array<[number, string, boolean]> = [
    [6 * 86_400_000, "6d", false],
    [86_400_000, "1d", true],
    [3_600_000, "1h", false],
  ];
  const step = steps.find(([ms]) => waitedMs >= ms);
  if (!step) return;
  const since = new Date(h.status_changed_at).toISOString();
  const fresh = await event(ctx.db, {
    domainId: domain.id,
    orgId: domain.org_id,
    kind: "needs_dns",
    detail: { host: h.hostname, after: step[1] },
    dedupe: `needs_dns:${h.id}:${since}:${step[1]}`,
  });
  if (!fresh) return;
  await noticeAdmins(
    ctx,
    domain.org_id,
    "domain_needs_dns",
    {
      title: `Still waiting for ${h.hostname}'s DNS`,
      body: `Casama can't see the records for ${h.hostname} yet. Check they're added exactly as shown; some DNS companies take a few hours.`,
      link: domainLink(domain.id),
    },
    step[2]
      ? {
          kind: "domain_needs_dns",
          dedupe: `domain_needs_dns:${h.id}:${since}`,
          data: { domain_name: h.hostname, domain_id: domain.id },
        }
      : undefined,
  );
}

/** Check Again (POST /v1/domains/{id}/check): every host now, and the edge asked to look now. */
export async function checkDomain(ctx: DomainsContext, domainId: string, force = true) {
  const domain = await getDomain(ctx.db, domainId);
  if (!domain) throw new SiteError(404, "domain_not_found", "Domain not found");
  const outcomes: CheckOutcome[] = [];
  for (const h of await domainHosts(ctx.db, domainId)) {
    if (force && h.status === "pending_cert" && h.provider_ref)
      await ctx.provider.recheck(h.provider_ref).catch(() => {});
    outcomes.push(await checkHost(ctx, h, domain, force));
  }
  await ctx.db.execute(
    sql`update public.domains set checked_at = now() where id = ${domainId}::uuid`,
  );
  return outcomes;
}

// ------------------------------------------------------------------ Upkeep

export interface UpkeepReport {
  checked: number;
  changed: CheckOutcome[];
  cleaned: number;
  cleanupFailed: number;
  orphans: number;
}

/** Every minute: due hosts, the edge cleanup queue, and connected domains whose workspace is gone. */
export async function domainsMinute(ctx: DomainsContext): Promise<UpkeepReport> {
  const { db } = ctx;
  const now = ctx.now?.() ?? new Date();
  const candidates = await db.execute<HostRow & { d: DomainRow }>(sql`
    select h.*, to_jsonb(d.*) as d from public.site_hosts h join public.domains d on d.id = h.domain_id
    where h.kind = 'custom' and h.status in ('pending_dns', 'pending_cert', 'active')
    order by h.last_checked_at nulls first limit 500`);
  const due = candidates
    .filter((h) =>
      hostCheckDue({
        status: h.status,
        createdAt: new Date(h.status_changed_at),
        lastCheckedAt: h.last_checked_at ? new Date(h.last_checked_at) : null,
        now,
      }),
    )
    .slice(0, CHECKS_PER_PASS);
  const changed: CheckOutcome[] = [];
  for (const h of due) {
    const { d, ...host } = h;
    const r = await checkHost(ctx, host as HostRow, d).catch(() => null);
    if (r && r.from !== r.to) changed.push(r);
  }

  // Edge hostnames whose rows are gone (§7.14): retried every minute, then hourly.
  const open = await db.execute<{ id: string; ref: string; attempts: number }>(sql`
    select id, ref, attempts from public.provider_cleanups
    where done_at is null and kind = 'hostname' and (attempts < 30 or extract(minute from now()) = 0)
    order by created_at limit 20`);
  let cleaned = 0;
  let cleanupFailed = 0;
  for (const c of open) {
    try {
      await ctx.provider.remove(c.ref);
      await db.execute(
        sql`update public.provider_cleanups set done_at = now(), attempts = attempts + 1 where id = ${c.id}::uuid`,
      );
      cleaned++;
    } catch (e) {
      cleanupFailed++;
      await db.execute(sql`
        update public.provider_cleanups set attempts = attempts + 1, last_error = ${String((e as Error).message).slice(0, 300)}
        where id = ${c.id}::uuid`);
    }
  }

  // A deleted workspace leaves its connected domains without an owner: they go (§7.10).
  const orphans = await db.execute<{ id: string }>(sql`
    delete from public.domains where kind = 'connected' and org_id is null returning id`);
  return { checked: due.length, changed, cleaned, cleanupFailed, orphans: orphans.length };
}

export interface HourlyReport {
  paused: number;
  resumed: number;
  usage: { used: number; allocated: number } | null;
  warned: boolean;
}

/** Hourly: the plan-limit pause rule (§7.13) and the custom hostname cost notice (§8). */
export async function domainsHourly(
  ctx: DomainsContext,
  adminEmails?: string,
): Promise<HourlyReport> {
  const { db } = ctx;
  const now = ctx.now?.() ?? new Date();
  let paused = 0;
  let resumed = 0;
  const orgs = await db.execute<{ org_id: string; n: number; max: number | null }>(sql`
    select d.org_id, count(*)::int as n,
      (select (e.limits->>'max_custom_domains')::int from public.entitlements e
        where e.org_id = d.org_id and jsonb_typeof(e.limits->'max_custom_domains') = 'number'
        order by e.created_at desc limit 1) as max
    from public.domains d where d.org_id is not null group by d.org_id`);
  for (const o of orgs) {
    const over = o.max === null ? 0 : Math.max(0, o.n - o.max);
    // The newest domains over the limit; the rest are fine.
    const ranked = await db.execute<{
      id: string;
      name: string;
      over_limit_since: Date | null;
    }>(sql`
      select id, name, over_limit_since from public.domains where org_id = ${o.org_id}::uuid
      order by created_at desc, id`);
    const overList = ranked.slice(0, over);
    const okList = ranked.slice(over);
    for (const d of okList) {
      if (!d.over_limit_since) continue;
      await db.execute(
        sql`update public.domains set over_limit_since = null where id = ${d.id}::uuid`,
      );
      const back = await db.execute<{
        id: string;
        page_id: string | null;
        verified_at: Date | null;
      }>(sql`
        update public.site_hosts set status = case when verified_at is not null then 'pending_cert' else 'pending_dns' end,
          status_reason = null, status_changed_at = now(), last_checked_at = null
        where domain_id = ${d.id}::uuid and status = 'paused' and status_reason = 'plan_limit'
        returning id, page_id, verified_at`);
      if (back.length) {
        resumed++;
        await event(db, { domainId: d.id, orgId: o.org_id, kind: "resumed" });
      }
    }
    for (const d of overList) {
      const since = d.over_limit_since ? new Date(d.over_limit_since) : now;
      if (!d.over_limit_since)
        await db.execute(
          sql`update public.domains set over_limit_since = ${since.toISOString()}::timestamptz where id = ${d.id}::uuid`,
        );
      const days = Math.floor((now.getTime() - since.getTime()) / 86_400_000);
      const key = since.toISOString().slice(0, 10);
      if (days >= OVER_LIMIT_PAUSE_DAYS) {
        const hosts = await db.execute<{ id: string; page_id: string | null }>(sql`
          update public.site_hosts set status = 'paused', status_reason = 'plan_limit', status_changed_at = now()
          where domain_id = ${d.id}::uuid and status in ('pending_dns', 'pending_cert', 'active')
          returning id, page_id`);
        for (const p of new Set(hosts.map((x) => x.page_id).filter(Boolean)))
          await settlePrimary(db, p as string);
        if (hosts.length) {
          paused++;
          await event(db, {
            domainId: d.id,
            orgId: o.org_id,
            kind: "paused",
            detail: { reason: "plan_limit" },
          });
          await noticeAdmins(
            ctx,
            o.org_id,
            "domain_disconnected",
            {
              title: `${d.name} is paused`,
              body: `Your plan no longer includes ${d.name}, so visitors are sent to the site's own address. Upgrade to bring it back; nothing was deleted.`,
              link: domainLink(d.id),
            },
            {
              kind: "domain_paused",
              dedupe: `domain_paused:${d.id}:${key}`,
              data: { domain_name: d.name, domain_id: d.id },
            },
          );
        }
      } else
        for (const [day, step] of [
          [OVER_LIMIT_NOTICE_DAYS, "10"],
          [0, "0"],
        ] as const) {
          if (days < day) continue;
          const fresh = await event(db, {
            domainId: d.id,
            orgId: o.org_id,
            kind: "over_limit",
            detail: { day: step },
            dedupe: `over_limit:${d.id}:${key}:${step}`,
          });
          if (fresh)
            await noticeAdmins(ctx, o.org_id, "domain_plan_limit", {
              title: `${d.name} will pause in ${OVER_LIMIT_PAUSE_DAYS - days} days`,
              body: `Your plan includes fewer domains than your workspace uses. On day ${OVER_LIMIT_PAUSE_DAYS}, ${d.name} will send visitors to the site's own address. Upgrade or remove a domain to keep it.`,
              link: domainLink(d.id),
            });
          break;
        }
    }
  }

  // The cost notice: Cloudflare includes 100 custom hostnames and bills each one past that.
  const usage = await ctx.provider.usage().catch(() => null);
  let warned = false;
  if (usage) {
    const at = HOSTNAME_NOTICE_AT.filter((n) => usage.used >= n).pop();
    if (at !== undefined) {
      const [recent] = await db.execute<{ n: number }>(sql`
        select count(*)::int as n from public.notifications
        where kind = 'domains_capacity' and created_at > now() - interval '1 day'`);
      if ((recent?.n ?? 0) === 0) {
        warned =
          (await noticeInstanceOwners(db, adminEmails, "domains_capacity", {
            title: "Custom hostnames are close to the included amount",
            body: `${usage.used} of ${usage.allocated} custom hostnames are in use. Cloudflare charges $0.10 a month for each one past the included 100.`,
            link: "/settings/admin",
          })) > 0;
      }
    }
  }
  return { paused, resumed, usage, warned };
}

// ------------------------------------------------------------------ Reading

export interface DomainView {
  id: string;
  name: string;
  kind: string;
  target: string;
  dns_provider: string | null;
  dns_provider_name: string | null;
  page_id: string | null;
  page_title: string | null;
  /** live, waiting_dns, waiting_cert, paused or needs_attention: the chip. */
  state: string;
  live: boolean;
  hosts: Array<{
    id: string;
    hostname: string;
    kind: string;
    is_primary: boolean;
    status: string;
    status_reason: string | null;
    domain_id: string | null;
    live: boolean;
    url: string;
  }>;
  records: DomainRecordView[];
  expires_at: string | null;
  auto_renew: boolean;
  registrar_status: string | null;
  renew_price_usd: number | null;
  locked: boolean;
  transfer_after: string | null;
  /** Bought domains: whether the registrant confirmed their email (§2.3). */
  registrant_verified: boolean | null;
  checked_at: string | null;
  created_at: string;
  events?: Array<{ kind: string; detail: Record<string, unknown>; created_at: string }>;
}

const iso = (d: Date | string | null) => (d ? new Date(d).toISOString() : null);

export function domainState(
  domain: Pick<DomainRow, "name">,
  hosts: Pick<HostRow, "hostname" | "status" | "kind" | "verified_at">[],
) {
  const main = mainHost(domain, hosts);
  if (!main) return "needs_attention";
  if (hostIsLive(main)) return "live";
  if (main.status === "pending_dns") return "waiting_dns";
  if (main.status === "pending_cert") return "waiting_cert";
  if (main.status === "paused") return "paused";
  return "needs_attention";
}

/** A domain as the app shows it. `dns`: also look up what public DNS shows for each record. */
export async function domainView(
  db: Exec,
  env: Env,
  provider: HostnameProvider | null,
  domain: DomainRow,
  o: { dns?: DnsLookup; events?: boolean } = {},
): Promise<DomainView> {
  const hosts = await domainHosts(db, domain.id);
  const [page] = await db.execute<{ id: string; title: string; servable: boolean }>(sql`
    select p.id, p.title, (p.visibility = 'public') as servable from public.pages p
    where p.id = (select page_id from public.site_hosts where domain_id = ${domain.id}::uuid and page_id is not null limit 1)`);
  // A bought domain's records are set by Casama at its registrar (§7.7 step 4).
  let records =
    provider && domain.kind === "connected" ? domainRecords(env, provider, domain, hosts) : [];
  if (o.dns && records.length) records = await withSeen(o.dns, records);
  const events = o.events
    ? (
        await db.execute<{ kind: string; detail: Record<string, unknown>; created_at: Date }>(sql`
          select kind, detail, created_at from public.domain_events
          where domain_id = ${domain.id}::uuid and kind not in ('claim', 'claim_attempt')
          order by created_at desc limit 50`)
      ).map((e) => ({ kind: e.kind, detail: e.detail, created_at: iso(e.created_at) as string }))
    : undefined;
  const state = domainState(domain, hosts);
  return {
    id: domain.id,
    name: domain.name,
    kind: domain.kind,
    target: domain.target,
    dns_provider: domain.dns_provider,
    dns_provider_name: domain.dns_provider
      ? (DNS_PROVIDER_NAMES[domain.dns_provider] ?? null)
      : null,
    page_id: page?.id ?? null,
    page_title: page?.title ?? null,
    state,
    live: state === "live",
    hosts: hosts.map((h) => ({
      id: h.id,
      hostname: h.hostname,
      kind: h.kind,
      is_primary: h.is_primary,
      status: h.status,
      status_reason: h.status_reason,
      domain_id: h.domain_id,
      live: !!page?.servable && hostIsLive(h),
      url: `https://${h.hostname}`,
    })),
    records,
    expires_at: iso(domain.expires_at),
    auto_renew: domain.auto_renew,
    registrar_status: domain.status,
    renew_price_usd: domain.renew_price_usd === null ? null : Number(domain.renew_price_usd),
    locked: domain.locked,
    transfer_after: iso(domain.transfer_after),
    registrant_verified:
      domain.kind === "registered" ? domain.registrant_verified_at != null : null,
    checked_at: iso(domain.checked_at),
    created_at: iso(domain.created_at) as string,
    ...(events ? { events } : {}),
  };
}

export async function listDomains(
  db: Exec,
  env: Env,
  provider: HostnameProvider | null,
  orgId: string,
) {
  const rows = await db.execute<DomainRow>(sql`
    select * from public.domains where org_id = ${orgId}::uuid order by created_at desc`);
  return Promise.all(rows.map((d) => domainView(db, env, provider, d)));
}

export {
  domainHosts,
  event as domainEvent,
  getDomain,
  random16 as newTargetLabel,
  register as registerHost,
};
