/**
 * Sites and domains (docs/SITES-AND-DOMAINS-PLAN.md): a site is a public page served at its own
 * address, and on domains a workspace connects or buys. States are plain strings the app maps to
 * its own words; new values never break an installed app because they arrive in new fields only.
 */
import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";

const ts = z.iso.datetime({ offset: true });

/** What a site, domain or buying is allowed to do on this server (in GET /v1/config). */
export const SitesConfig = z
  .object({
    /** The sites zone: addresses are name.<zone>. null: no site addresses here. */
    zone: z.string().nullable(),
    /** People can connect a domain they own. */
    custom_domains: z.boolean(),
    /** People can buy a domain (Casama Cloud only). */
    buy_domains: z.boolean(),
    /** The endings on sale. */
    tlds: z.array(z.string()),
  })
  .openapi("SitesConfig");

export const SiteHost = z
  .object({
    id: Uuid,
    hostname: z.string(),
    /** address: the free name on the zone. custom: a host of a connected or bought domain. */
    kind: z.string().openapi({ example: "address" }),
    is_primary: z.boolean(),
    /** pending_dns, pending_cert, active, failed, disconnected, paused or suspended. */
    status: z.string().openapi({ example: "active" }),
    /** Why it isn't live: not_pointed, caa_blocks, held_elsewhere, timed_out, proof_gone… */
    status_reason: z.string().nullable(),
    domain_id: Uuid.nullable(),
    /** Visitors are served here now. */
    live: z.boolean(),
    url: z.string(),
  })
  .openapi("SiteHost");

export const Site = z
  .object({
    page_id: Uuid,
    title: z.string(),
    /** The address name (the first label of the address), when it has one. */
    label: z.string().nullable(),
    /** https://name.<zone>, when it has an address. */
    address_url: z.string().nullable(),
    /** Where visitors go: the primary host. */
    url: z.string().nullable(),
    /** The page is public and the primary host serves it. */
    live: z.boolean(),
    indexable: z.boolean(),
    badge: z.boolean(),
    /** The plan lets this site be listed by search engines and drop the badge on a domain. */
    can_index: z.boolean(),
    hosts: z.array(SiteHost),
    created_at: ts,
  })
  .openapi("Site");

export const SiteList = z.object({ items: z.array(Site) }).openapi("SiteList");

export const PublishSiteRequest = z
  .object({
    /** The address name: 3 to 40 letters, digits and hyphens. Kept when left out. */
    label: z.string().min(1).max(63).optional(),
    indexable: z.boolean().optional(),
    /** Only on a custom domain, and only on plans with custom domains. */
    badge: z.boolean().optional(),
  })
  .openapi("PublishSiteRequest");

export const SiteAddressCheck = z
  .object({
    label: z.string(),
    available: z.boolean(),
    /** too_short, too_long, bad_chars, reserved, brand, taken or retired. */
    reason: z.string().nullable(),
    message: z.string().nullable(),
    url: z.string().nullable(),
  })
  .openapi("SiteAddressCheck");

export const SiteReportRequest = z
  .object({
    /** The site's address or any of its hosts, or a full link to it. */
    address: z.string().min(3).max(500),
    reason: z.string().min(3).max(1000),
  })
  .openapi("SiteReportRequest");

export const SiteReportResult = z.object({ ok: z.boolean() }).openapi("SiteReportResult");

// ------------------------------------------------------------------ Domains (§7.3–§7.5)

export const DomainRecord = z
  .object({
    /** The host this record is for. */
    host: z.string(),
    /** CNAME, ALIAS, A, AAAA, TXT, or FORWARD (a forwarding rule at their registrar). */
    type: z.string().openapi({ example: "CNAME" }),
    name: z.string(),
    value: z.string(),
    /** point: makes the name reach Casama. proof: shows it's theirs. forward: sends it to www. claim: takes it over from another workspace. */
    purpose: z.string().openapi({ example: "point" }),
    required: z.boolean(),
    /** What public DNS shows now (only on GET /v1/domains/{id}); null when unknown. */
    seen: z.array(z.string()).nullable(),
    /** Whether what DNS shows matches; null when unknown. */
    ok: z.boolean().nullable(),
  })
  .openapi("DomainRecord");

export const DomainEvent = z
  .object({
    /** connected, proved, live, needs_dns, failed, disconnected, paused, resumed, removed… */
    kind: z.string(),
    detail: z.record(z.string(), z.unknown()),
    created_at: ts,
  })
  .openapi("DomainEvent");

export const Domain = z
  .object({
    id: Uuid,
    name: z.string(),
    /** connected (owned elsewhere) or registered (bought through Casama). */
    kind: z.string().openapi({ example: "connected" }),
    /** The name this domain's records point at. */
    target: z.string(),
    /** The DNS company found from the nameservers (cloudflare, godaddy, namecheap…), when known. */
    dns_provider: z.string().nullable(),
    /** That company's name as it writes it (D-372), so the apps don't keep their own list. */
    dns_provider_name: z.string().nullable().optional(),
    /** The site it shows. */
    page_id: Uuid.nullable(),
    page_title: z.string().nullable(),
    /** The chip: live, waiting_dns, waiting_cert, paused or needs_attention. */
    state: z.string().openapi({ example: "live" }),
    live: z.boolean(),
    hosts: z.array(SiteHost),
    /** The records to add, in order. */
    records: z.array(DomainRecord),
    /** Bought domains: when it expires, whether it renews, the registrar's state and the next price. */
    expires_at: ts.nullable(),
    auto_renew: z.boolean(),
    registrar_status: z.string().nullable(),
    renew_price_usd: z.number().nullable(),
    locked: z.boolean(),
    transfer_after: ts.nullable(),
    /** Bought domains: whether the registrant confirmed their email (§2.3); null for connected ones. */
    registrant_verified: z.boolean().nullable(),
    checked_at: ts.nullable(),
    created_at: ts,
    /** History (only on GET /v1/domains/{id}). */
    events: z.array(DomainEvent).optional(),
  })
  .openapi("Domain");

export const DomainList = z.object({ items: z.array(Domain) }).openapi("DomainList");

export const ConnectDomainRequest = z
  .object({
    /** What they typed: bakery.com, www.bakery.com or shop.bakery.com. */
    name: z.string().min(1).max(300),
    /** A published site of the workspace to show on it. */
    page_id: Uuid.optional(),
  })
  .openapi("ConnectDomainRequest");

export const ConnectDomainResult = z
  .object({
    /** The domain, once it's this workspace's. */
    domain: Domain.nullable(),
    /** Another workspace proved this domain: add this record, then connect again to take it over. */
    claim: z.object({ type: z.string(), name: z.string(), value: z.string() }).nullable(),
  })
  .openapi("ConnectDomainResult");

export const UpdateDomainRequest = z
  .object({
    /** The site to show; null: none. */
    page_id: Uuid.nullable().optional(),
    /** The host visitors land on; it must be live. */
    primary_host: z.string().max(253).optional(),
    /** Bought domains: renew automatically. */
    auto_renew: z.boolean().optional(),
    /** Bought domains: Lock Again after a transfer code was issued (only true is accepted). */
    locked: z.literal(true).optional(),
  })
  .openapi("UpdateDomainRequest");

// ------------------------------------------------------------------ Keeping a domain (§7.8–§7.10)

export const DnsRecordItem = z
  .object({
    id: z.string(),
    /** Relative to the domain: "" for the domain itself, "www", "shop". */
    host: z.string(),
    /** A, AAAA, CNAME, MX, TXT or SRV (the site's own records may show ANAME). */
    type: z.string().openapi({ example: "MX" }),
    answer: z.string(),
    ttl: z.number().int(),
    priority: z.number().int().nullable(),
    /** Used by the Casama site: shown locked; disconnecting the site removes it. */
    managed: z.boolean(),
  })
  .openapi("DnsRecordItem");

export const DnsRecordList = z.object({ items: z.array(DnsRecordItem) }).openapi("DnsRecordList");

export const DnsRecordInput = z
  .object({
    host: z.string().max(253),
    type: z.string().max(10),
    answer: z.string().min(1).max(4096),
    ttl: z.number().int().min(300).max(86_400).default(300),
    priority: z.number().int().min(0).max(65_535).nullable().optional(),
  })
  .openapi("DnsRecordInput");

export const DnsRecordPatch = DnsRecordInput.partial().openapi("DnsRecordPatch");

export const TransferOutRequest = z
  .object({
    /** The domain's name, typed to confirm. */
    confirm_name: z.string().min(1).max(253),
  })
  .openapi("TransferOutRequest");

export const TransferOutResult = z
  .object({
    /** Shown once and never stored: give it to the new registrar. */
    code: z.string(),
  })
  .openapi("TransferOutResult");

// ------------------------------------------------------------------ Buying (§7.6, §7.7)

export const DomainSearchResult = z
  .object({
    name: z.string(),
    available: z.boolean(),
    /** Why it can't be bought here: taken, premium or not_sold. null when available. */
    reason: z.string().nullable(),
    /** The first year's price, before tax. */
    price_usd: z.number().nullable(),
    /** What it renews at each year, at today's cost. */
    renew_price_usd: z.number().nullable(),
  })
  .openapi("DomainSearchResult");

export const DomainSearchList = z
  .object({
    query: z.string(),
    items: z.array(DomainSearchResult),
    /** The endings on sale. */
    tlds: z.array(z.string()),
  })
  .openapi("DomainSearchList");

export const DomainContact = z
  .object({
    first_name: z.string().min(1).max(200),
    last_name: z.string().min(1).max(200),
    organization: z.string().max(200).nullable().optional(),
    address1: z.string().min(1).max(200),
    address2: z.string().max(200).nullable().optional(),
    city: z.string().min(1).max(200),
    state: z.string().min(1).max(200),
    zip: z.string().min(1).max(40),
    /** Two letters, like US. */
    country: z.string().length(2),
    /** International form, like +1 415 555 0100. */
    phone: z.string().min(5).max(40),
    email: z.email().max(254),
  })
  .openapi("DomainContact");

export const DomainContactState = z
  .object({
    /** The saved registrant details; null before the first purchase. */
    contact: DomainContact.nullable(),
    /** The account's confirmed email, to prefill the form. */
    default_email: z.string().nullable(),
  })
  .openapi("DomainContactState");

export const DomainOrder = z
  .object({
    id: Uuid,
    /** register, renew or restore. */
    kind: z.string(),
    name: z.string(),
    price_usd: z.number(),
    /** checkout, paid, registering, registered, done, abandoned, refunding, refunded or needs_attention. */
    status: z.string().openapi({ example: "registering" }),
    /** Why it failed, when it did: name_gone, premium, cost_rose, registrar_refused, registrar_unavailable… */
    failure: z.string().nullable(),
    /** Waiting for the server's owner to approve (a new workspace's first purchase). */
    needs_approval: z.boolean(),
    domain_id: Uuid.nullable(),
    created_at: ts,
    paid_at: ts.nullable(),
    refunded_at: ts.nullable(),
  })
  .openapi("DomainOrder");

export const DomainCheckoutRequest = z
  .object({
    name: z.string().min(3).max(253),
    /** A published site of the workspace to show on it. */
    page_id: Uuid.optional(),
    /** The domain terms were read and accepted. */
    accept_terms: z.literal(true),
    /** Renew automatically each year (keeps a payment method for renewals). Default on. */
    auto_renew: z.boolean().optional(),
  })
  .openapi("DomainCheckoutRequest");

export const DomainCheckoutResult = z
  .object({
    order: DomainOrder,
    /** Open this to pay; null when the workspace's saved payment method was charged. */
    checkout_url: z.string().nullable(),
  })
  .openapi("DomainCheckoutResult");

export const AdminDomain = z
  .object({
    id: Uuid,
    name: z.string(),
    kind: z.string(),
    org_id: Uuid.nullable(),
    org_name: z.string().nullable(),
    registrar_status: z.string().nullable(),
    expires_at: ts.nullable(),
    suspended: z.boolean(),
    created_at: ts,
  })
  .openapi("AdminDomain");

export const AdminDomainOrder = DomainOrder.extend({
  org_id: Uuid.nullable(),
  org_name: z.string().nullable(),
  attempts: z.number().int(),
}).openapi("AdminDomainOrder");

export const AdminDomains = z
  .object({
    counts: z.object({
      connected: z.number().int(),
      registered: z.number().int(),
      live_hosts: z.number().int(),
      suspended: z.number().int(),
    }),
    /** The registrar account's credit; null when it pays by card or can't be read. */
    balance_usd: z.number().nullable(),
    /** Orders waiting for approval, stuck, or whose refund failed. */
    orders: z.array(AdminDomainOrder),
    domains: z.array(AdminDomain),
  })
  .openapi("AdminDomains");
