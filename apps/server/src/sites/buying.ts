/**
 * Buying a domain (docs/SITES-AND-DOMAINS-PLAN.md §7.6, §7.7, §7.11): search, the registrant's
 * details, checkout, the paid webhook, the registration (with its refund rule), and the upkeep of
 * open orders.
 *
 * Money rules, each guarded here: the price comes from `domainPriceUsd` only; one live checkout per
 * name (a unique index); the amount paid must equal the order's price; the order id is the
 * workflow id and the registrar's reference; the cost is read again before registering and a rise
 * over $1 refunds instead; a refund that fails goes to `needs_attention` with an owner notice.
 */
import { randomBytes } from "node:crypto";
import { linkDomainToPage, SiteError, siteLimits, track } from "@casama/agent";
import { contentKeys, type Database } from "@casama/db";
import {
  checkDomainContact,
  type DomainContact,
  domainCandidates,
  domainPriceUsd,
  domainTarget,
  parseHost,
  saleTld,
  TRANSFER_LOCK_DAYS,
} from "@casama/domain";
import { sql } from "drizzle-orm";
import type { Env } from "../env.ts";
import { domainSaleSettings } from "../services/remote-settings.ts";
import { buyingConfigured } from "./config.ts";
import {
  apexSupported,
  type DomainRow,
  type DomainsContext,
  domainEvent,
  domainHosts,
  domainLink,
  getDomain,
  type HostRow,
  newTargetLabel,
  noticeAdmins,
  noticeInstanceOwners,
  registerHost,
} from "./domains.ts";
import { NameComRegistrar } from "./namecom.ts";
import { type DomainPayments, domainPaymentsFromEnv } from "./payments.ts";
import { type Registrar, RegistrarError, type RegistrarEvent } from "./registrar.ts";

type Exec = Pick<Database, "execute">;

/** The terms a buyer accepts; bump when docs-site/guide/domain-terms.md changes. */
export const DOMAIN_TERMS_VERSION = "2026-11-16";
/**
 * Purchase caps (§7.11): in a workspace's first 30 days, and in any 30 days after. The defaults of
 * `billing_settings.domain_cap_*`, which Admin → Pricing changes (D-373).
 */
export const PURCHASE_CAPS = { firstMonth: 3, perMonth: 10 } as const;
/** A new workspace's first purchase waits for an instance owner (§7.11). */
export const APPROVAL_UNDER_MS = 86_400_000;
/** Checkouts not paid within this go to `abandoned`; registrar outages retry this long. */
export const ORDER_WINDOW_MS = 86_400_000;
/** The cost may rise this much between checkout and registration before we refund instead. */
export const COST_SLACK_USD = 1;
/** Waits between registration attempts while the registrar can't be reached. */
export const RETRY_AFTER_MS = [60_000, 5 * 60_000, 15 * 60_000, 60 * 60_000];

export interface BuyingContext extends DomainsContext {
  registrar: Registrar;
  payments: DomainPayments;
  /** Starts the registration workflow (the order id is its id, so a second start does nothing). */
  startOrder: (orderId: string) => Promise<void>;
  adminEmails?: string;
}

export function registrarFromEnv(env: Env, fetchFn?: typeof fetch): Registrar | null {
  if (env.CASAMA_DOMAINS_REGISTRAR === "namecom" && env.NAMECOM_USERNAME && env.NAMECOM_API_TOKEN)
    return new NameComRegistrar({
      username: env.NAMECOM_USERNAME,
      token: env.NAMECOM_API_TOKEN,
      apiUrl: env.NAMECOM_API_URL,
      webhookSecret: env.NAMECOM_WEBHOOK_SECRET,
      fetch: fetchFn,
    });
  return null;
}

/** The registrar and domain payments, when this server sells domains (Casama Cloud only). */
export function domainsBuyingFromEnv(env: Env) {
  if (!buyingConfigured(env)) return null;
  const registrar = registrarFromEnv(env);
  const payments = domainPaymentsFromEnv(env);
  return registrar && payments ? { registrar, payments } : null;
}

// ------------------------------------------------------------------ Rows

export type OrderRow = {
  id: string;
  org_id: string | null;
  domain_id: string | null;
  kind: "register" | "renew" | "restore";
  name: string;
  price_usd: string;
  cost_usd: string;
  status: string;
  charge_mode: "checkout" | "mandate";
  payment_ref: string | null;
  checkout_ref: string | null;
  page_id: string | null;
  auto_renew: boolean;
  needs_approval: boolean;
  approved_at: Date | null;
  attempts: number;
  next_attempt_at: Date | null;
  failure: string | null;
  paid_at: Date | null;
  refunded_at: Date | null;
  created_by: string | null;
  created_at: Date;
};

export const getOrder = async (db: Exec, id: string) =>
  (await db.execute<OrderRow>(sql`select * from public.domain_orders where id = ${id}::uuid`))[0] ??
  null;

const first = <T>(rows: readonly T[]) => rows[0] as T;
const iso = (d: Date | string | null) => (d ? new Date(d).toISOString() : null);

export function orderView(o: OrderRow) {
  return {
    id: o.id,
    kind: o.kind,
    name: o.name,
    price_usd: Number(o.price_usd),
    status: o.status,
    failure: o.failure,
    needs_approval: o.needs_approval && !o.approved_at,
    domain_id: o.domain_id,
    created_at: iso(o.created_at) as string,
    paid_at: iso(o.paid_at),
    refunded_at: iso(o.refunded_at),
  };
}

const usd = (n: number | string) => `$${Number(n).toFixed(2)}`;

/** Why an order failed, in the words the notice and email use. */
export const FAILURE_WORDS: Record<string, string> = {
  name_gone: "someone else registered it first",
  premium: "it turned out to be a premium name, which isn't sold here",
  cost_rose: "its price at the registrar went up",
  registrar_refused: "the registrar refused it",
  registrar_unavailable: "the registrar couldn't be reached for a day",
  amount_mismatch: "the amount paid didn't match the price",
  not_approved: "the purchase wasn't approved",
  not_renewable: "it can't be renewed any more",
};

// ------------------------------------------------------------------ Price

export async function priceSettings(db: Exec) {
  const [r] = await db
    .execute<{ domain_markup: string; domain_fee_usd: string }>(
      sql`select domain_markup::text, domain_fee_usd::text from public.billing_settings where id`,
    )
    .catch(() => []);
  return {
    markup: r ? Number(r.domain_markup) : 1.25,
    feeUsd: r ? Number(r.domain_fee_usd) : 1.5,
  };
}

// ------------------------------------------------------------------ Search

export interface SearchItem {
  name: string;
  available: boolean;
  reason: "taken" | "premium" | "not_sold" | null;
  price_usd: number | null;
  renew_price_usd: number | null;
}

/** Candidates for what a person typed, checked in one registrar call (§7.7). */
export async function searchDomains(
  ctx: Pick<BuyingContext, "db" | "env" | "registrar">,
  o: { orgId: string; userId?: string | null; query: string },
): Promise<{ query: string; items: SearchItem[]; tlds: string[] }> {
  const { tlds } = await domainSaleSettings(ctx.db, ctx.env.CASAMA_DOMAINS_TLDS);
  const names = domainCandidates(o.query, tlds);
  if (!names.length) return { query: o.query, items: [], tlds };
  const settings = await priceSettings(ctx.db);
  const checked = await ctx.registrar.check(names, "search");
  const ours = await ctx.db.execute<{ name: string }>(sql`
    select name from public.domains where name = any(${`{${names.join(",")}}`}::text[])`);
  const held = new Set(ours.map((r) => r.name));
  const items = checked.map((c): SearchItem => {
    const sold = !!saleTld(c.name, tlds);
    const price = (cost: number | null) =>
      cost && cost > 0 ? domainPriceUsd(cost, settings) : null;
    const reason = !sold
      ? "not_sold"
      : c.premium
        ? "premium"
        : !c.available || held.has(c.name)
          ? "taken"
          : c.registerCostUsd === null
            ? "not_sold"
            : null;
    return {
      name: c.name,
      available: reason === null,
      reason,
      price_usd: reason === null ? price(c.registerCostUsd) : null,
      renew_price_usd: reason === null ? price(c.renewCostUsd ?? c.registerCostUsd) : null,
    };
  });
  track(ctx.db, {
    event: "domain_search",
    userId: o.userId,
    orgId: o.orgId,
    properties: { results: items.length, available: items.filter((i) => i.available).length },
  });
  return { query: o.query, items, tlds };
}

// ------------------------------------------------------------------ The registrant's details

export async function getContact(db: Exec, orgId: string): Promise<DomainContact | null> {
  const [r] = await db.execute<{ data: unknown }>(
    sql`select data from public.domain_contacts where org_id = ${orgId}::uuid`,
  );
  if (!r) return null;
  return contentKeys.open(r.data) as DomainContact;
}

const cleanContact = (c: DomainContact): DomainContact => ({
  first_name: c.first_name.trim(),
  last_name: c.last_name.trim(),
  organization: c.organization?.trim() || null,
  address1: c.address1.trim(),
  address2: c.address2?.trim() || null,
  city: c.city.trim(),
  state: c.state.trim(),
  zip: c.zip.trim(),
  country: c.country.trim().toUpperCase(),
  phone: c.phone.trim(),
  email: c.email.trim().toLowerCase(),
});

/**
 * Saves the registrant's details, sealed with the workspace's key (§7.14, §12: never logged, never
 * a tool input or an analytics property). Bought domains are updated at the registrar too, which
 * can start the registrant's email confirmation again (§2.3).
 */
export async function saveContact(
  ctx: Pick<BuyingContext, "db"> & { registrar?: Registrar | null },
  o: { orgId: string; userId: string; contact: DomainContact },
) {
  const contact = cleanContact(o.contact);
  const errors = checkDomainContact(contact);
  if (errors.length) throw new SiteError(400, "contact_invalid", errors.join(" "));
  await ctx.db.execute(sql`
    insert into public.domain_contacts (org_id, data, updated_by, updated_at)
    values (${o.orgId}::uuid, ${contentKeys.sealJson(o.orgId, contact)}::jsonb, ${o.userId}::uuid, now())
    on conflict (org_id) do update set data = excluded.data, updated_by = excluded.updated_by, updated_at = now()`);
  const domains = await ctx.db.execute<{ id: string; name: string }>(sql`
    select id, name from public.domains
    where org_id = ${o.orgId}::uuid and kind = 'registered' and status in ('active', 'expired')`);
  for (const d of domains) {
    await ctx.db.execute(sql`
      insert into public.domain_registrants (domain_id, email) values (${d.id}::uuid, ${contact.email})
      on conflict (domain_id) do update set email = excluded.email, updated_at = now()`);
    if (!ctx.registrar) continue;
    const ok = await ctx.registrar
      .setContact(d.name, contact)
      .then(() => true)
      .catch(() => false);
    await domainEvent(ctx.db, {
      domainId: d.id,
      orgId: o.orgId,
      kind: ok ? "contact_changed" : "contact_change_failed",
      detail: { by: o.userId },
    });
  }
  return contact;
}

// ------------------------------------------------------------------ Checkout

export interface CheckoutResult {
  order: OrderRow;
  checkoutUrl: string | null;
}

/** §7.7 step 1: every check in order, then a payment for exactly the order's price. */
export async function startCheckout(
  ctx: BuyingContext,
  o: {
    orgId: string;
    userId: string;
    email: string | null;
    name: string;
    pageId?: string | null;
    acceptTerms: boolean;
    autoRenew?: boolean;
    returnUrl: string;
  },
): Promise<CheckoutResult> {
  const { db } = ctx;
  if (o.acceptTerms !== true)
    throw new SiteError(400, "terms_required", "Accept the domain terms to buy a domain.");
  // The plan: buying is for paid plans (decision 4), and a bought domain counts (§7.13).
  const limits = await siteLimits(db, o.orgId);
  if (limits.maxDomains === 0)
    throw new SiteError(
      402,
      "plan_limit",
      "Buying a domain needs a paid plan. Upgrade to buy one.",
    );
  const [counts] = await db.execute<{
    domains: number;
    recent: number;
    ever: number;
    age_ms: number;
  }>(sql`
    select (select count(*)::int from public.domains where org_id = ${o.orgId}::uuid) as domains,
           (select count(*)::int from public.domain_orders where org_id = ${o.orgId}::uuid and kind = 'register'
              and status in ('checkout', 'paid', 'registering', 'registered', 'done')
              and created_at > now() - interval '30 days') as recent,
           (select count(*)::int from public.domain_orders where org_id = ${o.orgId}::uuid and kind = 'register'
              and status in ('registered', 'done')) as ever,
           (extract(epoch from now() - (select created_at from public.organizations where id = ${o.orgId}::uuid)) * 1000)::bigint as age_ms`);
  if (limits.maxDomains !== null && (counts?.domains ?? 0) >= limits.maxDomains)
    throw new SiteError(
      402,
      "plan_limit",
      `Your plan includes ${limits.maxDomains} domain${limits.maxDomains === 1 ? "" : "s"}. Remove one or upgrade to add another.`,
    );
  // The name: on sale here and not premium.
  const parsed = parseHost(o.name);
  const sale = await domainSaleSettings(ctx.db, ctx.env.CASAMA_DOMAINS_TLDS);
  const tlds = sale.tlds;
  const name = "problem" in parsed ? o.name.trim().toLowerCase() : parsed.domain;
  if ("problem" in parsed || parsed.subdomain !== "" || !saleTld(name, tlds))
    throw new SiteError(
      400,
      "not_sold",
      `Casama sells names ending in ${tlds.map((t) => `.${t}`).join(", ")}.`,
    );
  // The caps (§7.11).
  const ageMs = Number(counts?.age_ms ?? 0);
  const firstMonth = ageMs < 30 * 86_400_000;
  const cap = firstMonth ? sale.cap_first_month : sale.cap_per_month;
  if ((counts?.recent ?? 0) >= cap)
    throw new SiteError(
      429,
      "purchase_cap",
      `A workspace can buy ${cap} domains ${firstMonth ? "in its first 30 days" : "in 30 days"}. Ask support for more.`,
    );
  // The registrant.
  const contact = await getContact(db, o.orgId);
  if (!contact || checkDomainContact(contact).length)
    throw new SiteError(409, "contact_required", "Add the registrant's details first.");
  const pageId = o.pageId ?? null;
  if (pageId) {
    const [p] = await db.execute<{ ok: boolean }>(sql`
      select exists (select 1 from public.sites where page_id = ${pageId}::uuid and org_id = ${o.orgId}::uuid) as ok`);
    if (!p?.ok) throw new SiteError(409, "not_published", "Publish the page to the web first.");
  }
  // The registrar, once more: available, not premium, and what it costs today.
  const [c] = await ctx.registrar.check([name], "order");
  if (!c?.available) throw new SiteError(409, "name_taken", `${name} isn't available any more.`);
  if (c.premium)
    throw new SiteError(409, "not_sold", `${name} is a premium name, which isn't sold here.`);
  if (!c.registerCostUsd)
    throw new SiteError(409, "not_sold", `The registrar gave no price for ${name}.`);
  const price = domainPriceUsd(c.registerCostUsd, await priceSettings(db));
  const needsApproval = (counts?.ever ?? 0) === 0 && ageMs < APPROVAL_UNDER_MS;
  const autoRenew = o.autoRenew !== false;
  const [mandate] = await db.execute<{ mandate_ref: string | null }>(
    sql`select mandate_ref from public.domain_contacts where org_id = ${o.orgId}::uuid`,
  );
  const charge =
    !!mandate?.mandate_ref &&
    (await ctx.payments.mandateActive(mandate.mandate_ref).catch(() => false));

  let order: OrderRow;
  try {
    order = first(
      await db.execute<OrderRow>(sql`
      insert into public.domain_orders (org_id, kind, name, price_usd, cost_usd, status, charge_mode, page_id,
        terms_version, terms_accepted_at, auto_renew, needs_approval, created_by)
      values (${o.orgId}::uuid, 'register', ${name}, ${price}, ${c.registerCostUsd}, 'checkout',
        ${charge ? "mandate" : "checkout"}, ${pageId}::uuid, ${DOMAIN_TERMS_VERSION}, now(), ${autoRenew},
        ${needsApproval}, ${o.userId}::uuid)
      returning *`),
    );
  } catch (e) {
    if (
      String(
        (e as { code?: string; cause?: { code?: string } }).cause?.code ??
          (e as { code?: string }).code,
      ) === "23505" ||
      /domain_orders_one_live/.test(String((e as Error).message))
    )
      throw new SiteError(
        409,
        "checkout_in_progress",
        `Someone is already buying ${name}. Try again in a day if they don't.`,
      );
    throw e;
  }

  let checkoutUrl: string | null = null;
  try {
    if (charge && mandate?.mandate_ref) {
      const r = await ctx.payments.charge({
        mandateRef: mandate.mandate_ref,
        orderId: order.id,
        orgId: o.orgId,
        priceUsd: price,
      });
      order = first(
        await db.execute<OrderRow>(sql`
        update public.domain_orders set payment_ref = ${r.paymentId}, updated_at = now()
        where id = ${order.id}::uuid returning *`),
      );
    } else {
      const r = await ctx.payments.checkout({
        orderId: order.id,
        orgId: o.orgId,
        name,
        priceUsd: price,
        mandate: autoRenew,
        email: contact.email ?? o.email,
        returnUrl: o.returnUrl,
      });
      checkoutUrl = r.url;
      order = first(
        await db.execute<OrderRow>(sql`
        update public.domain_orders set checkout_ref = ${r.sessionId}, updated_at = now()
        where id = ${order.id}::uuid returning *`),
      );
    }
  } catch (e) {
    // No payment was opened: free the name for the next try.
    await db.execute(sql`
      update public.domain_orders set status = 'abandoned', failure = 'payment_unavailable', updated_at = now()
      where id = ${order.id}::uuid`);
    throw e;
  }
  track(db, {
    event: "domain_checkout_started",
    userId: o.userId,
    orgId: o.orgId,
    properties: {
      tld: parsed.publicSuffix,
      kind: "register",
      mode: charge ? "mandate" : "checkout",
    },
  });
  return { order, checkoutUrl };
}

// ------------------------------------------------------------------ The payment webhook

/**
 * §7.7 step 2, from the billing webhook: a payment whose metadata names a domain order. Answers
 * false when it isn't a domain payment, so plan billing handles it.
 */
export async function applyDomainPayment(ctx: BuyingContext, paymentId: string) {
  const p = await ctx.payments.payment(paymentId);
  if (!p.orderId) return false;
  const order = await getOrder(ctx.db, p.orderId);
  if (!order) return true;
  if (p.status === "failed") {
    if (order.status === "checkout" && order.payment_ref === paymentId) {
      await ctx.db.execute(sql`
        update public.domain_orders set status = 'abandoned', failure = 'charge_failed', updated_at = now()
        where id = ${order.id}::uuid and status = 'checkout'`);
      if (order.kind === "renew" && order.domain_id) {
        const d = await getDomain(ctx.db, order.domain_id);
        if (d) await (await import("./lifecycle.ts")).renewalFailed(ctx, d, order, "charge");
      } else if (order.org_id)
        await noticeAdmins(ctx, order.org_id, "domain_order_failed", {
          title: `The payment for ${order.name} didn't go through`,
          body: `Your saved payment method was declined, so ${order.name} wasn't bought. Try again to pay another way.`,
          link: "/settings/domains",
        });
    }
    return true;
  }
  if (p.status && p.status !== "succeeded") return true;
  // A second payment for one order (two tabs, two checkouts): give it back.
  if (order.payment_ref && order.payment_ref !== paymentId && order.status !== "checkout") {
    await ctx.payments.refund(paymentId, "Duplicate payment for one domain order").catch(() => {});
    return true;
  }
  // A late payment for an abandoned checkout whose name another order now holds can't revive it
  // (one live order per name): refund it rather than fail the webhook forever (billing audit
  // 2026-11-17).
  if (order.status === "abandoned") {
    const [taken] = await ctx.db.execute<{ id: string }>(sql`
      select id from public.domain_orders
      where name = ${order.name} and id <> ${order.id}::uuid and status in ('checkout', 'paid', 'registering')
      limit 1`);
    if (taken) {
      await ctx.db.execute(sql`
        update public.domain_orders set payment_ref = coalesce(payment_ref, ${paymentId}), paid_at = now(), updated_at = now()
        where id = ${order.id}::uuid and status = 'abandoned'`);
      await refundOrder(ctx, { ...order, payment_ref: paymentId }, "name_gone");
      return true;
    }
  }
  if (p.amountUsd === null || Math.abs(p.amountUsd - Number(order.price_usd)) > 0.005) {
    const [moved] = await ctx.db.execute<{ id: string }>(sql`
      update public.domain_orders set status = 'paid', payment_ref = ${paymentId}, paid_at = now(), updated_at = now()
      where id = ${order.id}::uuid and status in ('checkout', 'abandoned') returning id`);
    // Only an order still before registration is refunded through its workflow; anything else
    // (a retried webhook on a registered order) gives back just this payment if it isn't the one
    // the order was bought with.
    if (moved) await refundOrder(ctx, { ...order, payment_ref: paymentId }, "amount_mismatch");
    else if (order.payment_ref !== paymentId)
      await ctx.payments
        .refund(paymentId, "Payment for a domain order that was already paid")
        .catch(() => {});
    return true;
  }
  const [paid] = await ctx.db.execute<OrderRow>(sql`
    update public.domain_orders set status = 'paid', payment_ref = ${paymentId}, paid_at = now(), updated_at = now()
    where id = ${order.id}::uuid and status in ('checkout', 'abandoned') returning *`);
  if (!paid) {
    // Two payments for one order at once: the other one won the update. Give this one back.
    const now = await getOrder(ctx.db, order.id);
    if (now?.payment_ref && now.payment_ref !== paymentId) {
      await ctx.payments
        .refund(paymentId, "Duplicate payment for one domain order")
        .catch(() => {});
      return true;
    }
  }
  // The checkout that made a mandate: kept for renewals and the next purchase (§2.4).
  if (
    paid &&
    p.subscriptionId &&
    order.charge_mode === "checkout" &&
    order.auto_renew &&
    order.org_id
  )
    await ctx.db.execute(sql`
      update public.domain_contacts set mandate_ref = ${p.subscriptionId}, updated_at = now()
      where org_id = ${order.org_id}::uuid`);
  const current = paid ?? (await getOrder(ctx.db, order.id));
  if (!current || !["paid", "registering"].includes(current.status)) return true;
  if (current.needs_approval && !current.approved_at) {
    if (paid)
      await noticeInstanceOwners(ctx.db, ctx.adminEmails, "domain_order_approval", {
        title: `Approve the purchase of ${order.name}`,
        body: `A workspace less than a day old paid ${usd(order.price_usd)} for ${order.name}. Approve it in Admin → Domains, or it's refunded after a day.`,
        link: "/settings/admin?tab=domains",
      });
    return true;
  }
  await ctx.startOrder(order.id);
  return true;
}

/**
 * A refund or chargeback of a domain payment: recorded on its order. When the domain was already
 * registered (or renewed) with that money, it is suspended: no site, no transfer code, no renewal,
 * locked at the registrar, until an instance owner looks at it in Admin → Domains (billing audit
 * 2026-11-17; before, a disputed charge kept the domain).
 */
export async function applyDomainRefund(
  ctx: Pick<BuyingContext, "db" | "payments" | "adminEmails"> & { registrar?: Registrar | null },
  paymentId: string,
) {
  const p = await ctx.payments.payment(paymentId).catch(() => null);
  if (!p?.orderId) return false;
  const [order] = await ctx.db.execute<{
    name: string;
    status: string;
    domain_id: string | null;
    refunded_at: string | null;
    payment_ref: string | null;
  }>(sql`
    select o.name, o.status, coalesce(o.domain_id, d.id) as domain_id, o.refunded_at::text, o.payment_ref
    from public.domain_orders o left join public.domains d on d.name = o.name and d.kind = 'registered'
    where o.id = ${p.orderId}::uuid`);
  await ctx.db.execute(sql`
    update public.domain_orders set refunded_at = coalesce(refunded_at, now()),
      status = case when status in ('refunding', 'needs_attention', 'paid', 'checkout', 'abandoned') then 'refunded' else status end,
      updated_at = now()
    where id = ${p.orderId}::uuid and (payment_ref is null or payment_ref = ${paymentId})`);
  // Our own refund of a second payment for the order isn't the order's money coming back.
  if (order?.payment_ref !== paymentId) return true;
  if (!order.refunded_at && order.domain_id && ["registered", "done"].includes(order.status)) {
    await suspendDomain(ctx, order.domain_id, "payment_reversed");
    await noticeInstanceOwners(ctx.db, ctx.adminEmails, "domain_order_attention", {
      title: `A paid domain's payment was reversed: ${order.name}`,
      body: `The payment for ${order.name} was refunded or charged back after it was registered. It's suspended (no site, no transfer, no renewal). Review it in Admin → Domains.`,
      link: "/settings/admin?tab=domains",
    });
  }
  return true;
}

// ------------------------------------------------------------------ Refunds

/** The refund is part of the workflow (§7.7): refunded, or `needs_attention` with an owner notice. */
export async function refundOrder(ctx: BuyingContext, order: OrderRow, failure: string) {
  const { db } = ctx;
  await db.execute(sql`
    update public.domain_orders set status = 'refunding', failure = ${failure}, updated_at = now()
    where id = ${order.id}::uuid and status not in ('refunded', 'done', 'registered')`);
  const tld = order.name.split(".").slice(1).join(".");
  try {
    if (!order.payment_ref) throw new Error("no payment to refund");
    await ctx.payments.refund(order.payment_ref, `Domain ${order.name} could not be registered`);
  } catch (e) {
    await db.execute(sql`
      update public.domain_orders set status = 'needs_attention',
        failure = ${`${failure}; refund failed: ${String((e as Error).message).slice(0, 200)}`}, updated_at = now()
      where id = ${order.id}::uuid`);
    await noticeInstanceOwners(db, ctx.adminEmails, "domain_order_attention", {
      title: `A domain refund failed: ${order.name}`,
      body: `${order.name} couldn't be registered (${FAILURE_WORDS[failure] ?? failure}) and the refund of ${usd(order.price_usd)} failed. Retry it in Admin → Domains.`,
      link: "/settings/admin?tab=domains",
    });
    return "needs_attention" as const;
  }
  await db.execute(sql`
    update public.domain_orders set status = 'refunded', refunded_at = now(), updated_at = now()
    where id = ${order.id}::uuid`);
  if (order.org_id) {
    const reason = FAILURE_WORDS[failure] ?? "something went wrong at the registrar";
    await noticeAdmins(
      ctx,
      order.org_id,
      "domain_order_failed",
      {
        title: `${order.name} couldn't be ${order.kind === "renew" ? "renewed" : "registered"}`,
        body: `Your payment went through, but ${order.name} couldn't be ${order.kind === "renew" ? "renewed" : "registered"}: ${reason}. We refunded ${usd(order.price_usd)}.`,
        link: "/settings/domains",
      },
      {
        kind: "domain_order_failed",
        dedupe: `domain_order_failed:${order.id}`,
        data: { domain_name: order.name, reason, price: usd(order.price_usd) },
      },
    );
    track(db, {
      event: "domain_order_failed",
      orgId: order.org_id,
      properties: { tld, kind: order.kind, reason: failure },
    });
  }
  return "refunded" as const;
}

// ------------------------------------------------------------------ Registration

export type AttemptResult =
  | "done"
  | "retry"
  | "refunded"
  | "needs_attention"
  | "waiting"
  | "skipped";

/** How long one attempt holds its order, so a second runner never registers at the same time. */
const ATTEMPT_LEASE_MS = 2 * 60_000;

/**
 * One registration attempt (§7.7 steps 3–5). Safe to run again at any point: an attempt holds a
 * lease on its order; a domain already in the account with no row is adopted; an existing row is
 * reused; records are set once. The worker's workflow repeats it while it answers `retry` (waiting
 * until `next_attempt_at`), and hourly upkeep picks up any order left behind. A registrar that
 * can't be reached for a day after payment means a refund.
 */
export async function registerOrder(ctx: BuyingContext, orderId: string): Promise<AttemptResult> {
  const { db } = ctx;
  const now = ctx.now?.() ?? new Date();
  const order = await getOrder(db, orderId);
  if (order?.kind === "renew") return (await import("./lifecycle.ts")).renewOrder(ctx, orderId);
  if (order?.kind !== "register") return "skipped";
  if (order.status === "done") return "done";
  if (!["paid", "registering", "registered"].includes(order.status)) return "skipped";
  if (order.needs_approval && !order.approved_at) {
    if (order.paid_at && now.getTime() - new Date(order.paid_at).getTime() > ORDER_WINDOW_MS)
      return refundOrder(ctx, order, "not_approved");
    return "waiting";
  }
  const [claimed] = await db.execute<{ id: string }>(sql`
    update public.domain_orders set
      status = case when status = 'paid' then 'registering' else status end,
      attempts = attempts + 1, updated_at = now(),
      next_attempt_at = ${new Date(now.getTime() + ATTEMPT_LEASE_MS).toISOString()}::timestamptz
    where id = ${order.id}::uuid and status in ('paid', 'registering', 'registered')
      and (next_attempt_at is null or next_attempt_at <= ${now.toISOString()}::timestamptz)
    returning id`);
  if (!claimed) return "retry";
  if (order.status === "registered" && order.domain_id)
    return (await finishRegistration(ctx, order, order.domain_id))
      ? "done"
      : retryLater(ctx, order, now, null);

  try {
    const [row] = await db.execute<{ id: string; org_id: string | null; kind: string }>(
      sql`select id, org_id, kind from public.domains where name = ${order.name}`,
    );
    if (row?.kind === "registered" && row.org_id === order.org_id)
      return (await finishRegistration(ctx, order, row.id))
        ? "done"
        : retryLater(ctx, order, now, null);
    // A previous attempt may have registered it and stopped before writing the row.
    let inAccount = row?.kind === "registered" ? null : await ctx.registrar.get(order.name);
    if (!inAccount) {
      const [c] = await ctx.registrar.check([order.name], "order");
      if (!c?.available) return refundOrder(ctx, order, "name_gone");
      if (c.premium) return refundOrder(ctx, order, "premium");
      const cost = c.registerCostUsd ?? Number.POSITIVE_INFINITY;
      if (cost > Number(order.cost_usd) + COST_SLACK_USD)
        return refundOrder(ctx, order, "cost_rose");
      const contact = order.org_id ? await getContact(db, order.org_id) : null;
      if (!contact) return refundOrder(ctx, order, "registrar_refused");
      try {
        inAccount = {
          ...(await ctx.registrar.register({
            name: order.name,
            contact,
            maxCostUsd: Math.max(cost, Number(order.cost_usd)),
            reference: order.id,
          })),
          locked: true,
          autoRenew: false,
          privacy: true,
          nameservers: [],
          contactVerified: false,
        };
      } catch (e) {
        // Refused: unless it's in the account after all (a lost answer), it really failed.
        const after = await ctx.registrar.get(order.name).catch(() => null);
        if (!after) throw e;
        inAccount = after;
      }
    }
    const domainId = await writeDomain(ctx, order, inAccount.expiresAt);
    return (await finishRegistration(ctx, order, domainId))
      ? "done"
      : retryLater(ctx, order, now, null);
  } catch (e) {
    if (e instanceof RegistrarError && !e.retryable && e.status !== 402 && e.status !== 401)
      return refundOrder(
        ctx,
        order,
        /not available|unavailable|taken/i.test(e.message) ? "name_gone" : "registrar_refused",
      );
    const paidAgo = now.getTime() - new Date(order.paid_at ?? order.created_at).getTime();
    if (paidAgo > ORDER_WINDOW_MS) return refundOrder(ctx, order, "registrar_unavailable");
    return retryLater(ctx, order, now, e);
  }
}

async function retryLater(ctx: BuyingContext, order: OrderRow, now: Date, e: unknown) {
  const wait = RETRY_AFTER_MS[Math.min(order.attempts, RETRY_AFTER_MS.length - 1)] as number;
  await ctx.db.execute(sql`
    update public.domain_orders set next_attempt_at = ${new Date(now.getTime() + wait).toISOString()}::timestamptz,
      failure = ${e ? String((e as Error).message).slice(0, 200) : null}, updated_at = now()
    where id = ${order.id}::uuid`);
  return "retry" as const;
}

/** The `domains` row for a registration (step 4), reusing a row a previous attempt wrote. */
async function writeDomain(ctx: BuyingContext, order: OrderRow, expiresAt: Date) {
  const { db } = ctx;
  if (!order.org_id) throw new Error("the workspace is gone");
  const settings = await priceSettings(db);
  const [c] = await ctx.registrar.check([order.name], "order").catch(() => []);
  const renewCost = c?.renewCostUsd ?? Number(order.cost_usd);
  const contact = await getContact(db, order.org_id);
  const id = await db.transaction(async (tx) => {
    // A connected row for this name was someone's unproved claim: the name was free to register,
    // so it was never theirs. Its admins are told.
    const [old] = await tx.execute<{ id: string; org_id: string | null; kind: string }>(
      sql`select id, org_id, kind from public.domains where name = ${order.name} for update`,
    );
    if (old?.kind === "registered") return old.id;
    if (old) await tx.execute(sql`delete from public.domains where id = ${old.id}::uuid`);
    const [d] = await tx.execute<{ id: string }>(sql`
      insert into public.domains (name, kind, org_id, target, verify_code, dns_provider, registrar, status,
        expires_at, auto_renew, locked, privacy, transfer_after, renew_price_usd, purchased_by)
      values (${order.name}, 'registered', ${order.org_id}::uuid, ${domainTarget(ctx.zone, newTargetLabel())},
        ${randomBytes(12).toString("base64url")}, ${ctx.registrar.id}, ${ctx.registrar.id}, 'active',
        ${expiresAt.toISOString()}::timestamptz, ${order.auto_renew}, true, true,
        now() + make_interval(days => ${TRANSFER_LOCK_DAYS}), ${domainPriceUsd(renewCost, settings)},
        ${order.created_by}::uuid)
      returning id`);
    const domainId = d?.id as string;
    if (contact?.email)
      await tx.execute(sql`
        insert into public.domain_registrants (domain_id, email) values (${domainId}::uuid, ${contact.email})
        on conflict (domain_id) do nothing`);
    // www always; the bare domain as its own host when the registrar's DNS can point it (§7.5).
    const hosts = [`www.${order.name}`];
    if (apexSupported(ctx.env, ctx.provider, ctx.registrar.id)) hosts.push(order.name);
    for (const host of hosts)
      await tx.execute(sql`
        insert into public.site_hosts (hostname, kind, org_id, domain_id, status)
        values (${host}, 'custom', ${order.org_id}::uuid, ${domainId}::uuid, 'pending_dns')
        on conflict (hostname) do nothing`);
    await tx.execute(sql`
      update public.domain_orders set status = 'registered', domain_id = ${domainId}::uuid, failure = null,
        next_attempt_at = null, updated_at = now()
      where id = ${order.id}::uuid`);
    return domainId;
  });
  await db.execute(sql`
    update public.domain_orders set status = 'registered', domain_id = ${id}::uuid, updated_at = now()
    where id = ${order.id}::uuid and status = 'registering'`);
  return id;
}

/**
 * Step 4's DNS and step 5's notices, once: the hosts at the edge, the records at the registrar
 * (www CNAME to the target; the bare domain by ANAME plus its ownership TXT, or forwarding to www),
 * the site chosen at checkout, then `done`. Answers false when something must be tried again.
 */
async function finishRegistration(ctx: BuyingContext, order: OrderRow, domainId: string) {
  const { db } = ctx;
  const domain = await getDomain(db, domainId);
  if (!domain?.org_id) return true;
  if (!domain.managed_records.length) {
    const ok = await setManagedRecords(ctx, domain).catch(() => false);
    if (!ok) return false;
  }
  if (order.page_id)
    await linkDomainToPage(db, { domainId, orgId: domain.org_id, pageId: order.page_id }).catch(
      () => {},
    );
  const [done] = await db.execute<{ id: string }>(sql`
    update public.domain_orders set status = 'done', updated_at = now()
    where id = ${order.id}::uuid and status <> 'done' returning id`);
  if (!done) return true;
  await domainEvent(db, {
    domainId,
    orgId: domain.org_id,
    kind: "registered",
    detail: {
      by: order.created_by,
      price_usd: Number(order.price_usd),
      expires_at: domain.expires_at,
    },
    dedupe: `registered:${order.id}`,
  });
  await noticeAdmins(
    ctx,
    domain.org_id,
    "domain_registered",
    {
      title: `${domain.name} is yours`,
      body: `${domain.name} is registered for a year. Your site goes live on it within a few minutes. Confirm the registrant email the registrar sends within 15 days.`,
      link: domainLink(domainId),
    },
    {
      kind: "domain_registered",
      dedupe: `domain_registered:${order.id}`,
      data: { domain_name: domain.name, domain_id: domainId, price: usd(order.price_usd) },
    },
  );
  track(db, {
    event: "domain_purchased",
    userId: order.created_by,
    orgId: domain.org_id,
    properties: { tld: domain.name.split(".").slice(1).join("."), kind: "register" },
  });
  return true;
}

/** Sets the site's records at the registrar and remembers their ids as managed (§7.9). */
export async function setManagedRecords(
  ctx: Pick<BuyingContext, "db" | "env" | "provider" | "registrar">,
  domain: DomainRow,
) {
  const { db } = ctx;
  const hosts: HostRow[] = [];
  for (const h of await domainHosts(db, domain.id))
    hosts.push(h.provider_ref ? h : await registerHost(ctx as unknown as DomainsContext, h));
  const ids: string[] = [];
  const existing = await ctx.registrar.records(domain.name);
  const put = async (host: string, type: string, answer: string) => {
    const same = existing.find(
      (r) => r.host === host && r.type === type && r.answer.replace(/\.$/, "") === answer,
    );
    const r =
      same ?? (await ctx.registrar.putRecord(domain.name, { host, type, answer, ttl: 300 }));
    if (r.id) ids.push(r.id);
  };
  const bare = hosts.find((h) => h.hostname === domain.name);
  for (const h of hosts) {
    if (h.hostname === domain.name) {
      await put("", "ANAME", domain.target);
      if (h.ownership_name && h.ownership_value)
        await put(h.ownership_name.slice(0, -(domain.name.length + 1)), "TXT", h.ownership_value);
    } else await put(h.hostname.slice(0, -(domain.name.length + 1)), "CNAME", domain.target);
  }
  if (!bare) await ctx.registrar.setForwarding(domain.name, `https://www.${domain.name}`);
  await db.execute(sql`
    update public.domains set managed_records = ${`{${ids.join(",")}}`}::text[], updated_at = now()
    where id = ${domain.id}::uuid`);
  return true;
}

// ------------------------------------------------------------------ The registrar's view

/**
 * Reads a bought domain from the registrar and stores what changed: expiry, lock, privacy and
 * whether the registrant confirmed their email. The registrar's own auto-renew is turned off
 * whenever it's found on (§12: only our upkeep renews). null when the registrar doesn't have it.
 */
export async function refreshFromRegistrar(
  ctx: Pick<BuyingContext, "db" | "registrar">,
  d: Pick<DomainRow, "id" | "name" | "org_id">,
) {
  const r = await ctx.registrar.get(d.name);
  if (!r) {
    await domainEvent(ctx.db, {
      domainId: d.id,
      orgId: d.org_id,
      kind: "registrar_missing",
      dedupe: `registrar_missing:${d.id}:${new Date().toISOString().slice(0, 10)}`,
    });
    return null;
  }
  await ctx.db.execute(sql`
    update public.domains set expires_at = ${r.expiresAt.toISOString()}::timestamptz, locked = ${r.locked},
      privacy = ${r.privacy},
      registrant_verified_at = case when ${r.contactVerified} then coalesce(registrant_verified_at, now()) else null end,
      updated_at = now()
    where id = ${d.id}::uuid`);
  if (r.autoRenew) await ctx.registrar.setAutoRenew(d.name, false).catch(() => {});
  return r;
}

/** A verified registrar webhook: stored once on its domain, then the domain is read again. */
export async function syncFromRegistrar(
  ctx: Pick<BuyingContext, "db" | "registrar" | "notify">,
  ev: RegistrarEvent,
): Promise<boolean> {
  if (!ev.domain) return false;
  const [d] = await ctx.db.execute<DomainRow>(sql`
    select * from public.domains where name = ${ev.domain} and kind = 'registered'`);
  if (!d) return false;
  const fresh = await domainEvent(ctx.db, {
    domainId: d.id,
    orgId: d.org_id,
    kind: `registrar_${ev.kind}`,
    detail: { event: ev.id },
    dedupe: `registrar:${ev.id}`,
  });
  if (!fresh) return true;
  const r = await refreshFromRegistrar(ctx, d);
  // Gone from the account after a transfer unlock: it moved to another registrar (§7.10).
  if (!r && d.unlocked_at) await (await import("./lifecycle.ts")).movedOut(ctx, d);
  return false;
}

// ------------------------------------------------------------------ Upkeep and admin

/**
 * Open orders (hourly in the worker): checkouts not paid within a day are abandoned, paid orders
 * whose workflow never started are started again (same id: never twice), stuck refunds are tried
 * again, and the registrar's balance is watched.
 */
export async function ordersUpkeep(ctx: BuyingContext) {
  const { db } = ctx;
  const abandoned = await db.execute<{ id: string }>(sql`
    update public.domain_orders set status = 'abandoned', updated_at = now()
    where status = 'checkout' and created_at < now() - interval '24 hours' returning id`);
  // Left behind by a workflow (a crash, a lost enqueue, waiting for approval): attempted here; the
  // lease in registerOrder keeps it from running twice at once.
  const stuck = await db.execute<{ id: string }>(sql`
    select id from public.domain_orders
    where kind in ('register', 'renew') and status in ('paid', 'registering', 'registered')
      and updated_at < now() - interval '10 minutes'
      and (next_attempt_at is null or next_attempt_at <= now())
    order by created_at limit 20`);
  for (const o of stuck) await registerOrder(ctx, o.id).catch(() => {});
  const refunding = await db.execute<OrderRow>(sql`
    select * from public.domain_orders where status = 'refunding' and updated_at < now() - interval '10 minutes' limit 20`);
  for (const o of refunding) await refundOrder(ctx, o, o.failure ?? "registrar_refused");
  let balance: number | null = null;
  let warned = false;
  try {
    balance = await ctx.registrar.balanceUsd();
  } catch {
    balance = null;
  }
  if (balance !== null && balance < ctx.env.CASAMA_DOMAINS_BALANCE_ALERT) {
    const [recent] = await db.execute<{ n: number }>(sql`
      select count(*)::int as n from public.notifications
      where kind = 'domains_balance' and created_at > now() - interval '1 day'`);
    if ((recent?.n ?? 0) === 0)
      warned =
        (await noticeInstanceOwners(db, ctx.adminEmails, "domains_balance", {
          title: "The registrar balance is low",
          body: `The domain registrar account has ${usd(balance)} left. Registrations and renewals fail when it runs out: add credit at the registrar.`,
          link: "/settings/admin?tab=domains",
        })) > 0;
  }
  return {
    abandoned: abandoned.length,
    restarted: stuck.length,
    refunds: refunding.length,
    balance,
    warned,
  };
}

/** Admin → Domains (§7.15): counts, the balance, orders that need a person, every domain. */
export async function adminOverview(db: Exec, registrar: Registrar | null) {
  const [counts] = await db.execute<{
    connected: number;
    registered: number;
    live_hosts: number;
    suspended: number;
  }>(sql`
    select (select count(*)::int from public.domains where kind = 'connected') as connected,
           (select count(*)::int from public.domains where kind = 'registered') as registered,
           (select count(*)::int from public.site_hosts where kind = 'custom' and status = 'active') as live_hosts,
           (select count(distinct domain_id)::int from public.site_hosts where status = 'suspended') as suspended`);
  const orders = await db.execute<OrderRow & { org_name: string | null }>(sql`
    select o.*, g.name as org_name from public.domain_orders o left join public.organizations g on g.id = o.org_id
    where o.status in ('needs_attention', 'refunding') or (o.status in ('paid', 'registering') and (o.needs_approval and o.approved_at is null or o.attempts > 1))
    order by o.created_at desc limit 100`);
  const domains = await db.execute<DomainRow & { org_name: string | null; suspended: boolean }>(sql`
    select d.*, g.name as org_name,
      (d.status = 'suspended' or exists (select 1 from public.site_hosts h where h.domain_id = d.id and h.status = 'suspended')) as suspended
    from public.domains d left join public.organizations g on g.id = d.org_id
    order by d.created_at desc limit 500`);
  return {
    counts: counts ?? { connected: 0, registered: 0, live_hosts: 0, suspended: 0 },
    balance_usd: registrar ? await registrar.balanceUsd().catch(() => null) : null,
    orders: orders.map((o) => ({
      ...orderView(o),
      org_id: o.org_id,
      org_name: o.org_name,
      attempts: o.attempts,
    })),
    domains: domains.map((d) => ({
      id: d.id,
      name: d.name,
      kind: d.kind,
      org_id: d.org_id,
      org_name: d.org_name,
      registrar_status: d.status,
      expires_at: iso(d.expires_at),
      suspended: d.suspended,
      created_at: iso(d.created_at) as string,
    })),
  };
}

/**
 * Suspend for abuse (§7.10, §7.11): hosts stop and leave the edge; a bought domain is locked at
 * the registrar and its site records are removed.
 */
export async function suspendDomain(
  ctx: Pick<BuyingContext, "db"> & { registrar?: Registrar | null },
  domainId: string,
  by: string,
) {
  const { db } = ctx;
  const d = await getDomain(db, domainId);
  if (!d) throw new SiteError(404, "domain_not_found", "Domain not found");
  await db.transaction(async (tx) => {
    await tx.execute(sql`
      insert into public.provider_cleanups (kind, ref, hostname)
      select 'hostname', provider_ref, hostname from public.site_hosts
      where domain_id = ${domainId}::uuid and provider_ref is not null`);
    await tx.execute(sql`
      update public.site_hosts set status = 'suspended', status_reason = 'abuse', status_changed_at = now(),
        provider_ref = null, verified_at = null, is_primary = false
      where domain_id = ${domainId}::uuid`);
    if (d.kind === "registered")
      await tx.execute(
        sql`update public.domains set status = 'suspended', updated_at = now() where id = ${domainId}::uuid`,
      );
  });
  if (d.kind === "registered" && ctx.registrar) {
    await ctx.registrar.setLock(d.name, true).catch(() => {});
    for (const id of d.managed_records)
      await ctx.registrar.deleteRecord(d.name, id).catch(() => {});
    await ctx.registrar.setForwarding(d.name, null).catch(() => {});
    await db.execute(
      sql`update public.domains set managed_records = '{}', locked = true where id = ${domainId}::uuid`,
    );
  }
  await domainEvent(db, { domainId, orgId: d.org_id, kind: "suspended", detail: { by } });
  return d;
}

export async function unsuspendDomain(
  ctx: Pick<BuyingContext, "db" | "env" | "provider"> & { registrar?: Registrar | null },
  domainId: string,
  by: string,
) {
  const { db } = ctx;
  const d = await getDomain(db, domainId);
  if (!d) throw new SiteError(404, "domain_not_found", "Domain not found");
  await db.execute(sql`
    update public.site_hosts set status = 'pending_dns', status_reason = null, status_changed_at = now(),
      last_checked_at = null
    where domain_id = ${domainId}::uuid and status = 'suspended'`);
  if (d.kind === "registered") {
    const expired = d.expires_at && new Date(d.expires_at).getTime() < Date.now();
    await db.execute(sql`
      update public.domains set status = ${expired ? "expired" : "active"}, updated_at = now()
      where id = ${domainId}::uuid and status = 'suspended'`);
    if (ctx.registrar)
      await setManagedRecords(
        { ...ctx, registrar: ctx.registrar },
        (await getDomain(db, domainId)) as DomainRow,
      ).catch(() => {});
  }
  await domainEvent(db, { domainId, orgId: d.org_id, kind: "unsuspended", detail: { by } });
  return d;
}

/** Retry a stuck order: a failed refund is tried again; a registration is started again. */
export async function retryOrder(ctx: BuyingContext, orderId: string) {
  const order = await getOrder(ctx.db, orderId);
  if (!order) throw new SiteError(404, "order_not_found", "Order not found");
  if (order.status === "needs_attention" || order.status === "refunding") {
    await refundOrder(ctx, order, (order.failure ?? "registrar_refused").split(";")[0] as string);
  } else if (["paid", "registering", "registered"].includes(order.status)) {
    // A fresh day of retries from now.
    await ctx.db.execute(sql`
      update public.domain_orders set paid_at = now(), next_attempt_at = null, updated_at = now()
      where id = ${order.id}::uuid`);
    await registerOrder(ctx, order.id);
  } else throw new SiteError(409, "order_not_stuck", "This order isn't waiting for anything.");
  return (await getOrder(ctx.db, orderId)) as OrderRow;
}

export async function approveOrder(ctx: BuyingContext, orderId: string) {
  const [o] = await ctx.db.execute<OrderRow>(sql`
    update public.domain_orders set approved_at = now(), updated_at = now()
    where id = ${orderId}::uuid and needs_approval and approved_at is null
      and status in ('checkout', 'paid', 'registering') returning *`);
  if (!o) throw new SiteError(409, "order_not_waiting", "This order isn't waiting for approval.");
  if (o.status !== "checkout") await ctx.startOrder(o.id);
  return o;
}
