/**
 * Keeping a bought domain (docs/SITES-AND-DOMAINS-PLAN.md §7.8–§7.10): renewal notices with that
 * day's price, charges on the workspace's domain mandate, the renewal itself (with the same refund
 * rule as a registration), expiry, grace and redemption, registrant email reminders, relocking an
 * unused transfer unlock, a domain moved to another registrar, domains whose workspace was deleted,
 * and the daily reconcile with the registrar.
 *
 * Every step is keyed `<domain>:<expiry date>:<step>` in `domain_events.dedupe`, so a late or
 * repeated upkeep run never charges or emails twice.
 */
import { SiteError, track } from "@casama/agent";
import type { Database } from "@casama/db";
import {
  checkDnsChange,
  type DnsRecord,
  daysUntil,
  domainPriceUsd,
  EXPIRY_TIMELINE,
  relativeName,
  renewalPlan,
} from "@casama/domain";
import { sql } from "drizzle-orm";
import { queueAccountEmail } from "../services/account-emails.ts";
import {
  type BuyingContext,
  COST_SLACK_USD,
  getOrder,
  ORDER_WINDOW_MS,
  type OrderRow,
  priceSettings,
  RETRY_AFTER_MS,
  refreshFromRegistrar,
  refundOrder,
} from "./buying.ts";
import { type DomainRow, domainEvent, domainLink, getDomain, noticeAdmins } from "./domains.ts";
import { RegistrarError } from "./registrar.ts";

type Exec = Pick<Database, "execute">;

/** An unlock for a transfer that never started is undone after this (§7.10). */
export const RELOCK_AFTER_DAYS = 14;
/** Reminders to confirm the registrant email, in days after registration (§7.17). */
export const VERIFY_REMINDER_DAYS = [3, 7, 12] as const;
/** A transfer code needs a sign-in this recent (§7.10, §12). */
export const FRESH_SIGN_IN_MS = 10 * 60_000;
/** Upkeep reads at most this many domains from the registrar per run for the reconcile. */
export const RECONCILE_PER_RUN = 50;

const DAY_MS = 86_400_000;
const usd = (n: number | string) => `$${Number(n).toFixed(2)}`;
const isoDay = (d: Date | string) => new Date(d).toISOString().slice(0, 10);
const tldOf = (name: string) => name.split(".").slice(1).join(".");
const first = <T>(rows: readonly T[]) => rows[0] as T;

/** That day's renewal price (§12: never a number stored a year earlier), stored for the screen. */
export async function renewalPrice(ctx: Pick<BuyingContext, "db" | "registrar">, d: DomainRow) {
  let cost: number | null = null;
  try {
    cost = await ctx.registrar.renewCost(d.name);
  } catch {
    cost = null;
  }
  if (cost === null) {
    // No answer today: the stored price, which was computed from the registrar's last answer.
    if (d.renew_price_usd === null) return null;
    return { priceUsd: Number(d.renew_price_usd), costUsd: null as number | null };
  }
  const priceUsd = domainPriceUsd(cost, await priceSettings(ctx.db));
  await ctx.db.execute(sql`
    update public.domains set renew_price_usd = ${priceUsd}, updated_at = now() where id = ${d.id}::uuid`);
  return { priceUsd, costUsd: cost };
}

const mandateOf = async (db: Exec, orgId: string) =>
  (
    await db.execute<{ mandate_ref: string | null }>(
      sql`select mandate_ref from public.domain_contacts where org_id = ${orgId}::uuid`,
    )
  )[0]?.mandate_ref ?? null;

const liveOrder = async (db: Exec, name: string) =>
  (
    await db.execute<OrderRow>(sql`
      select * from public.domain_orders where name = ${name} and status in ('checkout', 'paid', 'registering')`)
  )[0] ?? null;

// ------------------------------------------------------------------ Renewing

/**
 * A renewal order (Renew Now, or a mandate charge). With `mandateRef`, the saved payment method is
 * charged and the paid webhook starts the renewal; without, a checkout address is answered.
 */
export async function startRenewal(
  ctx: BuyingContext,
  d: DomainRow,
  o: {
    by: string | null;
    mandateRef?: string | null;
    email?: string | null;
    returnUrl?: string;
    step?: string;
  },
): Promise<{ order: OrderRow; checkoutUrl: string | null }> {
  const { db } = ctx;
  if (!d.org_id) throw new SiteError(404, "domain_not_found", "Domain not found");
  if (d.kind !== "registered")
    throw new SiteError(409, "not_bought", "Only domains bought through Casama renew here.");
  if (d.status === "lapsed" || d.status === "gone")
    throw new SiteError(
      409,
      "restore_by_support",
      `${d.name} is past its renewal time. Write to support to ask about restoring it; there's a restore fee and it isn't guaranteed.`,
    );
  if (d.status === "moved_out" || d.status === "suspended")
    throw new SiteError(409, "not_renewable", `${d.name} can't be renewed here.`);
  if (await liveOrder(db, d.name))
    throw new SiteError(409, "checkout_in_progress", `A renewal of ${d.name} is already open.`);
  const price = await renewalPrice(ctx, d);
  if (!price?.costUsd)
    throw new SiteError(
      409,
      "registrar_unavailable",
      "The domain registrar didn't answer. Try again in a minute.",
    );
  const charge = !!o.mandateRef;
  let order: OrderRow;
  try {
    order = first(
      await db.execute<OrderRow>(sql`
        insert into public.domain_orders (org_id, domain_id, kind, name, price_usd, cost_usd, status, charge_mode,
          auto_renew, created_by)
        values (${d.org_id}::uuid, ${d.id}::uuid, 'renew', ${d.name}, ${price.priceUsd}, ${price.costUsd}, 'checkout',
          ${charge ? "mandate" : "checkout"}, ${d.auto_renew}, ${o.by}::uuid)
        returning *`),
    );
  } catch (e) {
    if (
      /domain_orders_one_live|23505/.test(
        String((e as Error).message) + String((e as { code?: string }).code),
      )
    )
      throw new SiteError(409, "checkout_in_progress", `A renewal of ${d.name} is already open.`);
    throw e;
  }
  let checkoutUrl: string | null = null;
  try {
    if (charge && o.mandateRef) {
      const r = await ctx.payments.charge({
        mandateRef: o.mandateRef,
        orderId: order.id,
        orgId: d.org_id,
        priceUsd: price.priceUsd,
      });
      order = first(
        await db.execute<OrderRow>(sql`
          update public.domain_orders set payment_ref = ${r.paymentId}, updated_at = now()
          where id = ${order.id}::uuid returning *`),
      );
    } else {
      const r = await ctx.payments.checkout({
        orderId: order.id,
        orgId: d.org_id,
        name: d.name,
        priceUsd: price.priceUsd,
        mandate: false,
        email: o.email ?? null,
        returnUrl: o.returnUrl ?? domainLink(d.id),
      });
      checkoutUrl = r.url;
      order = first(
        await db.execute<OrderRow>(sql`
          update public.domain_orders set checkout_ref = ${r.sessionId}, updated_at = now()
          where id = ${order.id}::uuid returning *`),
      );
    }
  } catch (e) {
    await db.execute(sql`
      update public.domain_orders set status = 'abandoned', failure = ${charge ? "charge_failed" : "payment_unavailable"},
        updated_at = now()
      where id = ${order.id}::uuid`);
    if (charge) {
      await renewalFailed(ctx, d, order, o.step ?? "charge");
      return { order: (await getOrder(db, order.id)) as OrderRow, checkoutUrl: null };
    }
    throw e;
  }
  track(db, {
    event: "domain_checkout_started",
    userId: o.by,
    orgId: d.org_id,
    properties: { tld: tldOf(d.name), kind: "renew", mode: charge ? "mandate" : "checkout" },
  });
  return { order, checkoutUrl };
}

/** A charge that failed (declined at once, or by a later `payment.failed`): notice and email. */
export async function renewalFailed(
  ctx: Pick<BuyingContext, "db" | "notify">,
  d: Pick<DomainRow, "id" | "name" | "org_id" | "expires_at">,
  order: Pick<OrderRow, "id">,
  step: string,
) {
  if (!d.org_id) return;
  await noticeAdmins(
    ctx,
    d.org_id,
    "domain_renewal",
    {
      title: `We couldn't renew ${d.name}`,
      // Facts only in the app (see renewalNotice); the email says how to pay.
      body: `The renewal charge for ${d.name} didn't go through. We'll try again in a few days.`,
      link: domainLink(d.id),
    },
    {
      kind: "domain_renewal_failed",
      dedupe: `domain_renewal_failed:${order.id}`,
      data: {
        domain_name: d.name,
        domain_id: d.id,
        until: d.expires_at ? new Date(d.expires_at).toISOString() : null,
      },
    },
  );
  track(ctx.db, {
    event: "domain_renewal_failed",
    orgId: d.org_id,
    properties: { tld: tldOf(d.name), kind: "renew", step },
  });
}

/** The renewal workflow's lease, like a registration's. */
const LEASE_MS = 2 * 60_000;

/**
 * One renewal attempt (§7.8): paid → renewed one year at the registrar with the order id as the
 * reference → receipt. A renewal already applied (a lost answer) is adopted, not repeated; the cost
 * is read again first; a refused renewal is refunded. Answers like `registerOrder`.
 */
export async function renewOrder(ctx: BuyingContext, orderId: string) {
  const { db } = ctx;
  const now = ctx.now?.() ?? new Date();
  const order = await getOrder(db, orderId);
  if (order?.kind !== "renew") return "skipped" as const;
  if (order.status === "done") return "done" as const;
  if (!["paid", "registering"].includes(order.status)) return "skipped" as const;
  const [claimed] = await db.execute<{ id: string }>(sql`
    update public.domain_orders set status = 'registering', attempts = attempts + 1, updated_at = now(),
      next_attempt_at = ${new Date(now.getTime() + LEASE_MS).toISOString()}::timestamptz
    where id = ${order.id}::uuid and status in ('paid', 'registering')
      and (next_attempt_at is null or next_attempt_at <= ${now.toISOString()}::timestamptz)
    returning id`);
  if (!claimed) return "retry" as const;
  const d = order.domain_id ? await getDomain(db, order.domain_id) : null;
  if (!d || !["active", "expired"].includes(d.status ?? ""))
    return refundOrder(ctx, order, "not_renewable");
  try {
    const before = d.expires_at ? new Date(d.expires_at) : now;
    const at = await ctx.registrar.get(d.name);
    if (!at) return refundOrder(ctx, order, "not_renewable");
    let expiresAt: Date;
    // A previous attempt renewed it and lost the answer: the registrar's expiry is a year on.
    if (at.expiresAt.getTime() - before.getTime() > 300 * DAY_MS) expiresAt = at.expiresAt;
    else {
      const cost = (await ctx.registrar.renewCost(d.name)) ?? Number.POSITIVE_INFINITY;
      if (cost > Number(order.cost_usd) + COST_SLACK_USD)
        return refundOrder(ctx, order, "cost_rose");
      ({ expiresAt } = await ctx.registrar.renew({
        name: d.name,
        maxCostUsd: Math.max(cost, Number(order.cost_usd)),
        reference: order.id,
      }));
    }
    await db.execute(sql`
      update public.domains set expires_at = ${expiresAt.toISOString()}::timestamptz,
        status = case when status = 'expired' then 'active' else status end, updated_at = now()
      where id = ${d.id}::uuid`);
    // An expired domain's hosts lost their proof: check them again now.
    if (d.status === "expired")
      await db.execute(sql`
        update public.site_hosts set last_checked_at = null where domain_id = ${d.id}::uuid`);
    const [done] = await db.execute<{ id: string }>(sql`
      update public.domain_orders set status = 'done', failure = null, next_attempt_at = null, updated_at = now()
      where id = ${order.id}::uuid and status <> 'done' returning id`);
    if (!done) return "done" as const;
    await domainEvent(db, {
      domainId: d.id,
      orgId: d.org_id,
      kind: "renewed",
      detail: { by: order.created_by, price_usd: Number(order.price_usd), expires_at: expiresAt },
      dedupe: `renewed:${order.id}`,
    });
    if (d.org_id) {
      await noticeAdmins(
        ctx,
        d.org_id,
        "domain_renewal",
        {
          title: `${d.name} is renewed`,
          body: `${d.name} is renewed for a year, until ${expiresAt.toISOString().slice(0, 10)}.`,
          link: domainLink(d.id),
        },
        {
          kind: "domain_renewed",
          dedupe: `domain_renewed:${order.id}`,
          data: {
            domain_name: d.name,
            domain_id: d.id,
            price: usd(order.price_usd),
            until: expiresAt.toISOString(),
          },
        },
      );
      track(db, {
        event: "domain_renewed",
        userId: order.created_by,
        orgId: d.org_id,
        properties: { tld: tldOf(d.name), kind: "renew", mode: order.charge_mode },
      });
    }
    return "done" as const;
  } catch (e) {
    if (e instanceof RegistrarError && !e.retryable && e.status !== 402 && e.status !== 401)
      return refundOrder(ctx, order, "registrar_refused");
    const paidAgo = now.getTime() - new Date(order.paid_at ?? order.created_at).getTime();
    if (paidAgo > ORDER_WINDOW_MS) return refundOrder(ctx, order, "registrar_unavailable");
    const wait = RETRY_AFTER_MS[Math.min(order.attempts, RETRY_AFTER_MS.length - 1)] as number;
    await db.execute(sql`
      update public.domain_orders set next_attempt_at = ${new Date(now.getTime() + wait).toISOString()}::timestamptz,
        failure = ${String((e as Error).message).slice(0, 200)}, updated_at = now()
      where id = ${order.id}::uuid`);
    return "retry" as const;
  }
}

// ------------------------------------------------------------------ Upkeep

export interface LifecycleReport {
  notices: number;
  charges: number;
  states: number;
  reminders: number;
  relocked: number;
  released: number;
  reconciled: number;
}

/**
 * Hourly (§7.8): for each bought domain, the one step it's due, once. Domains whose workspace was
 * deleted are released (§7.10); unused transfer unlocks are undone; the registrant is reminded to
 * confirm their email; the oldest-read domains are read again from the registrar.
 */
export async function domainsLifecycle(ctx: BuyingContext): Promise<LifecycleReport> {
  const { db } = ctx;
  const now = ctx.now?.() ?? new Date();
  const report: LifecycleReport = {
    notices: 0,
    charges: 0,
    states: 0,
    reminders: 0,
    relocked: 0,
    released: 0,
    reconciled: 0,
  };
  report.released = await releaseOrphans(ctx);
  report.reconciled = await reconcile(ctx);
  const rows = await db.execute<DomainRow>(sql`
    select * from public.domains
    where kind = 'registered' and org_id is not null and status in ('active', 'expired', 'lapsed')
      and expires_at is not null
    order by expires_at`);
  for (const d of rows) {
    try {
      await domainStep(ctx, d, now, report);
    } catch {
      // One domain's trouble (the registrar, a payment) never stops the others.
    }
  }
  return report;
}

async function domainStep(ctx: BuyingContext, d: DomainRow, now: Date, report: LifecycleReport) {
  const { db } = ctx;
  const orgId = d.org_id as string;
  const expiry = new Date(d.expires_at as Date);
  const key = (step: string) => `${d.id}:${isoDay(expiry)}:${step}`;
  const mandate = d.auto_renew ? await mandateOf(db, orgId) : null;
  const plan = renewalPlan(daysUntil(expiry, now), d.auto_renew && !!mandate);

  // The state first. Before calling a domain expired, ask the registrar: it may have been renewed.
  if (plan.state !== d.status) {
    if (plan.state === "expired" && d.status === "active") {
      const fresh = await refreshFromRegistrar(ctx, d).catch(() => undefined);
      if (fresh && fresh.expiresAt.getTime() > now.getTime()) return;
    }
    if (await toState(ctx, d, plan.state, key(plan.state))) report.states++;
  }

  // Unused transfer unlocks are undone.
  if (
    plan.state === "active" &&
    !d.locked &&
    d.unlocked_at &&
    now.getTime() - new Date(d.unlocked_at).getTime() > RELOCK_AFTER_DAYS * DAY_MS
  ) {
    await ctx.registrar.setLock(d.name, true);
    await db.execute(sql`
      update public.domains set locked = true, unlocked_at = null, updated_at = now() where id = ${d.id}::uuid`);
    await domainEvent(db, { domainId: d.id, orgId, kind: "relocked", detail: { by: "upkeep" } });
    report.relocked++;
  }

  // The registrant's email (§7.17): days 3, 7 and 12 after registration while unconfirmed.
  if (plan.state === "active" && !d.registrant_verified_at) {
    const age = (now.getTime() - new Date(d.created_at).getTime()) / DAY_MS;
    const due = [...VERIFY_REMINDER_DAYS].reverse().find((n) => age >= n && age < 15);
    if (
      due &&
      (await domainEvent(db, {
        domainId: d.id,
        orgId,
        kind: "verify_reminder",
        detail: { day: due },
        dedupe: `${d.id}:verify_${due}`,
      }))
    ) {
      await noticeAdmins(
        ctx,
        orgId,
        "domain_verify_email",
        {
          title: `Confirm the registrant email for ${d.name}`,
          body: `Open the email the registrar sent to the registrant's address and confirm it, or ${d.name} stops working 15 days after it was bought.`,
          link: domainLink(d.id),
        },
        {
          kind: "domain_verify_email",
          dedupe: `domain_verify_email:${d.id}:${due}`,
          data: { domain_name: d.name, domain_id: d.id },
        },
      );
      report.reminders++;
    }
  }

  // A notice: the latest reached step, once per expiry date.
  if (plan.notice) {
    const fresh = await domainEvent(db, {
      domainId: d.id,
      orgId,
      kind: "renewal_notice",
      detail: { step: plan.notice },
      dedupe: key(plan.notice),
    });
    if (fresh) {
      await renewalNotice(ctx, d, plan.notice, !!plan.charge || (d.auto_renew && !!mandate));
      report.notices++;
    }
  }

  // A charge on the mandate (E − 14, again on E − 10, E − 7, E − 3 while unrenewed).
  if (plan.charge && mandate && !(await liveOrder(db, d.name))) {
    const fresh = await domainEvent(db, {
      domainId: d.id,
      orgId,
      kind: "renewal_charge",
      detail: { step: plan.charge },
      dedupe: key(plan.charge),
    });
    if (fresh) {
      const active = await ctx.payments.mandateActive(mandate).catch(() => false);
      if (active) {
        await startRenewal(ctx, d, { by: null, mandateRef: mandate, step: plan.charge }).catch(
          () => {},
        );
        report.charges++;
      }
    }
  }
}

/**
 * The renewal and expiry notices (§7.8). The in-app notice (and its push) states facts only, with
 * no price and no call to renew: on Android and outside the App Store's US storefront the app may
 * not point at another way to pay (Play Payments §4, App Store 3.1.1(a)). The email carries that
 * day's price; outside the app that's allowed.
 */
async function renewalNotice(ctx: BuyingContext, d: DomainRow, step: string, auto: boolean) {
  const orgId = d.org_id as string;
  const price = await renewalPrice(ctx, d);
  const priceText = price ? usd(price.priceUsd) : null;
  const expiry = new Date(d.expires_at as Date);
  const until = expiry.toISOString();
  const day = until.slice(0, 10);
  const expired = step === "expired_3" || step === "final_20";
  const lastDay = new Date(expiry.getTime() + EXPIRY_TIMELINE.lapsedAfterDays * DAY_MS);
  await noticeAdmins(
    ctx,
    orgId,
    expired ? "domain_expired" : "domain_renewal",
    expired
      ? {
          title: `${d.name} has expired`,
          body: `${d.name} expired on ${day}. It can still be renewed until ${isoDay(lastDay)}.`,
          link: domainLink(d.id),
        }
      : {
          title: auto ? `${d.name} renews on ${day}` : `${d.name} expires on ${day}`,
          body: auto
            ? `${d.name} renews automatically on ${day}.`
            : `${d.name} expires on ${day}. Automatic renewal is off.`,
          link: domainLink(d.id),
        },
    {
      kind: expired ? "domain_expired" : "domain_renewal",
      dedupe: `domain_notice:${d.id}:${day}:${step}`,
      data: {
        domain_name: d.name,
        domain_id: d.id,
        price: priceText,
        until,
        auto,
        last_day: lastDay.toISOString(),
      },
    },
  );
}

/** expired → lapsed → gone (§7.8). Answers whether it changed. */
async function toState(
  ctx: BuyingContext,
  d: DomainRow,
  state: "active" | "expired" | "lapsed" | "gone",
  dedupe: string,
) {
  const { db } = ctx;
  if (state === "active") return false; // only a renewal makes a domain active again
  const [changed] = await db.execute<{ id: string }>(sql`
    update public.domains set status = ${state}, updated_at = now()
    where id = ${d.id}::uuid and status = ${d.status} returning id`);
  if (!changed) return false;
  await domainEvent(db, { domainId: d.id, orgId: d.org_id, kind: state, dedupe });
  if (state === "expired" && d.org_id)
    track(db, {
      event: "domain_expired",
      orgId: d.org_id,
      properties: { tld: tldOf(d.name), kind: "registered" },
    });
  if (state === "gone") {
    // The row and its history stay; the hosts go (the delete trigger removes them at the edge).
    await db.execute(sql`delete from public.site_hosts where domain_id = ${d.id}::uuid`);
    await db.execute(sql`
      update public.domains set managed_records = '{}', auto_renew = false where id = ${d.id}::uuid`);
  }
  return true;
}

/**
 * Domains whose workspace was deleted (§7.10): renewal off, released, and one email to the
 * registrant saying it's theirs until its expiry and how to get the transfer code.
 */
export async function releaseOrphans(ctx: BuyingContext) {
  const { db } = ctx;
  const rows = await db.execute<DomainRow & { registrant: string | null }>(sql`
    select d.*, r.email as registrant from public.domains d
    left join public.domain_registrants r on r.domain_id = d.id
    where d.kind = 'registered' and d.org_id is null and d.released_at is null`);
  for (const d of rows) {
    await ctx.registrar.setAutoRenew(d.name, false).catch(() => {});
    await db.execute(sql`
      update public.domains set auto_renew = false, released_at = now(), updated_at = now()
      where id = ${d.id}::uuid`);
    await db.execute(sql`delete from public.site_hosts where domain_id = ${d.id}::uuid`);
    await domainEvent(db, {
      domainId: d.id,
      orgId: null,
      kind: "released",
      dedupe: `released:${d.id}`,
    });
    if (d.registrant)
      await queueAccountEmail(db, {
        kind: "domain_released",
        dedupeKey: `domain_released:${d.id}`,
        data: {
          domain_name: d.name,
          until: d.expires_at ? new Date(d.expires_at).toISOString() : null,
          to: d.registrant,
        },
      });
  }
  return rows.length;
}

/**
 * The daily reconcile (§7.8): the domains read longest ago are read again from the registrar
 * (expiry, lock, privacy, the registrant's confirmation). One that's gone from the account after a
 * transfer unlock moved out.
 */
async function reconcile(ctx: BuyingContext) {
  const { db } = ctx;
  const rows = await db.execute<DomainRow>(sql`
    select * from public.domains
    where kind = 'registered' and org_id is not null and status in ('active', 'expired', 'suspended')
      and (checked_at is null or checked_at < now() - interval '1 day')
    order by checked_at nulls first limit ${RECONCILE_PER_RUN}`);
  let n = 0;
  for (const d of rows) {
    try {
      const r = await refreshFromRegistrar(ctx, d);
      await db.execute(sql`update public.domains set checked_at = now() where id = ${d.id}::uuid`);
      if (!r && d.unlocked_at) await movedOut(ctx, d);
      n++;
    } catch {
      // The registrar didn't answer: next run.
    }
  }
  return n;
}

// ------------------------------------------------------------------ Leaving (§7.10)

/**
 * The transfer finished: the domain isn't ours to manage any more. It becomes a connected domain,
 * so its site stays up while its DNS still proves its hosts (the normal checks remove them when it
 * doesn't).
 */
export async function movedOut(ctx: Pick<BuyingContext, "db" | "notify">, d: DomainRow) {
  const { db } = ctx;
  const [changed] = await db.execute<{ id: string }>(sql`
    update public.domains set kind = 'connected', registrar = null, status = null, expires_at = null,
      auto_renew = false, locked = false, unlocked_at = null, transfer_after = null, managed_records = '{}',
      renew_price_usd = null, updated_at = now()
    where id = ${d.id}::uuid and kind = 'registered' returning id`);
  if (!changed) return false;
  await db.execute(sql`delete from public.domain_registrants where domain_id = ${d.id}::uuid`);
  await db.execute(sql`
    update public.site_hosts set last_checked_at = null where domain_id = ${d.id}::uuid`);
  await domainEvent(db, {
    domainId: d.id,
    orgId: d.org_id,
    kind: "moved_out",
    dedupe: `moved_out:${d.id}:${isoDay(d.created_at)}`,
  });
  if (d.org_id)
    await noticeAdmins(ctx, d.org_id, "domain_disconnected", {
      title: `${d.name} moved to another registrar`,
      body: `${d.name} isn't managed by Casama any more. Its site stays up while its DNS still points here.`,
      link: domainLink(d.id),
    });
  return true;
}

/** A fresh sign-in (§12): the session's most recent sign-in method is under ten minutes old. */
export function signedInRecently(claims: Record<string, unknown>, now = Date.now()) {
  const amr = Array.isArray(claims.amr) ? (claims.amr as Array<{ timestamp?: number }>) : [];
  const latest = Math.max(0, ...amr.map((a) => Number(a?.timestamp ?? 0)));
  return latest > 0 && now - latest * 1000 <= FRESH_SIGN_IN_MS;
}

/**
 * Move to Another Registrar (§7.10): the owner typed the name; after the transfer lock the domain is
 * unlocked and its code returned once (never stored). The owner is emailed and admins told.
 */
export async function issueTransferCode(
  ctx: BuyingContext,
  d: DomainRow,
  o: { by: string; confirmName: string },
) {
  const { db } = ctx;
  const now = ctx.now?.() ?? new Date();
  if (d.kind !== "registered" || !d.org_id)
    throw new SiteError(409, "not_bought", "Only domains bought through Casama move from here.");
  if (o.confirmName.trim().toLowerCase() !== d.name)
    throw new SiteError(400, "confirm_name", `Type ${d.name} to confirm.`);
  if (d.status !== "active")
    throw new SiteError(
      409,
      "not_transferable",
      `${d.name} can't be moved while it's ${d.status}.`,
    );
  if (d.transfer_after && new Date(d.transfer_after).getTime() > now.getTime())
    throw new SiteError(
      409,
      "transfer_locked",
      `Domain rules keep a new domain where it was bought for 60 days. ${d.name} can move from ${isoDay(d.transfer_after)}.`,
    );
  await ctx.registrar.setLock(d.name, false);
  const code = await ctx.registrar.transferCode(d.name);
  await db.execute(sql`
    update public.domains set locked = false, unlocked_at = now(), updated_at = now() where id = ${d.id}::uuid`);
  await domainEvent(db, {
    domainId: d.id,
    orgId: d.org_id,
    kind: "transfer_code",
    detail: { by: o.by },
  });
  const [owner] = await db.execute<{ user_id: string }>(sql`
    select user_id from public.memberships where org_id = ${d.org_id}::uuid and role = 'owner'
    order by created_at limit 1`);
  await noticeAdmins(ctx, d.org_id, "domain_transfer_code", {
    title: `A transfer code for ${d.name} was issued`,
    body: `${d.name} was unlocked to move to another registrar. If that wasn't expected, open it and tap Lock Again.`,
    link: domainLink(d.id),
  });
  if (owner)
    await queueAccountEmail(db, {
      kind: "domain_transfer_code",
      userId: owner.user_id,
      dedupeKey: `domain_transfer_code:${d.id}:${now.getTime()}`,
      data: { domain_name: d.name, domain_id: d.id },
    });
  track(db, {
    event: "domain_transfer_out",
    userId: o.by,
    orgId: d.org_id,
    properties: { tld: tldOf(d.name), kind: "registered" },
  });
  return code;
}

/** Lock Again (§7.10). */
export async function relockDomain(ctx: BuyingContext, d: DomainRow, by: string) {
  await ctx.registrar.setLock(d.name, true);
  await ctx.db.execute(sql`
    update public.domains set locked = true, unlocked_at = null, updated_at = now() where id = ${d.id}::uuid`);
  await domainEvent(ctx.db, { domainId: d.id, orgId: d.org_id, kind: "relocked", detail: { by } });
}

/** Sends the registrant verification email again. */
export async function resendVerification(ctx: BuyingContext, d: DomainRow) {
  if (d.kind !== "registered")
    throw new SiteError(409, "not_bought", "Only domains bought through Casama have a registrant.");
  if (d.registrant_verified_at)
    throw new SiteError(409, "already_verified", "The registrant email is already confirmed.");
  await ctx.registrar.resendVerification(d.name);
  await domainEvent(ctx.db, { domainId: d.id, orgId: d.org_id, kind: "verify_email_sent" });
}

// ------------------------------------------------------------------ DNS records (§7.9)

export interface RecordView extends DnsRecord {
  id: string;
  managed: boolean;
}

const recordView = (r: DnsRecord, managed: string[]): RecordView => ({
  id: r.id as string,
  host: r.host,
  type: r.type.toUpperCase(),
  answer: r.answer,
  ttl: r.ttl,
  priority: r.priority ?? null,
  managed: !!r.id && managed.includes(r.id),
});

const recordsDomain = (d: DomainRow) => {
  if (d.kind !== "registered" || !["active", "expired"].includes(d.status ?? ""))
    throw new SiteError(
      409,
      "not_bought",
      "DNS records are managed here only for domains bought through Casama.",
    );
};

export async function listRecords(ctx: Pick<BuyingContext, "registrar">, d: DomainRow) {
  recordsDomain(d);
  return (await ctx.registrar.records(d.name)).map((r) => recordView(r, d.managed_records));
}

/** Adds, changes or deletes one record after the checks in `checkDnsChange`. */
export async function changeRecord(
  ctx: Pick<BuyingContext, "db" | "registrar">,
  d: DomainRow,
  op: "add" | "change" | "delete",
  record: DnsRecord,
  by: string,
) {
  recordsDomain(d);
  const existing = await ctx.registrar.records(d.name);
  const current = record.id ? existing.find((r) => r.id === record.id) : undefined;
  if (op !== "add" && !current) throw new SiteError(404, "record_not_found", "Record not found");
  const full: DnsRecord =
    op === "delete"
      ? (current as DnsRecord)
      : {
          ...(op === "change" ? current : {}),
          ...record,
          host: relativeName(record.host ?? current?.host ?? "", d.name),
          type: (record.type ?? current?.type ?? "").toUpperCase(),
        };
  const errors = checkDnsChange({
    domain: d.name,
    existing,
    managed: d.managed_records,
    op,
    record: full,
  });
  if (errors.length) throw new SiteError(400, "invalid_record", errors.join(" "));
  let out: DnsRecord | null = null;
  if (op === "delete") await ctx.registrar.deleteRecord(d.name, record.id as string);
  else out = await ctx.registrar.putRecord(d.name, full);
  await domainEvent(ctx.db, {
    domainId: d.id,
    orgId: d.org_id,
    kind: `record_${op === "add" ? "added" : op === "change" ? "changed" : "deleted"}`,
    detail: { by, host: full.host, type: full.type },
  });
  return out ? recordView(out, d.managed_records) : null;
}

/**
 * A subdomain connected under a bought domain (§7.9): the registrar's DNS is ours, so its CNAME to
 * the subdomain's own target is made (or removed) by itself and kept with the managed records.
 */
export async function subdomainRecord(
  ctx: Pick<BuyingContext, "db" | "registrar">,
  sub: { name: string; target: string; org_id: string | null },
  on: boolean,
) {
  const { name: hostname, target } = sub;
  if (!sub.org_id) return false;
  // Only a domain the same workspace bought: never another workspace's DNS.
  const [d] = await ctx.db.execute<DomainRow>(sql`
    select * from public.domains where kind = 'registered' and status = 'active'
      and org_id = ${sub.org_id}::uuid and ${hostname} like '%.' || name order by char_length(name) desc limit 1`);
  if (!d || hostname === `www.${d.name}`) return false;
  const host = relativeName(hostname, d.name);
  const existing = await ctx.registrar.records(d.name);
  const same = existing.filter(
    (r) =>
      r.host === host && r.type.toUpperCase() === "CNAME" && r.answer.replace(/\.$/, "") === target,
  );
  const ids = new Set(d.managed_records);
  if (on) {
    const r =
      same[0] ??
      (await ctx.registrar.putRecord(d.name, { host, type: "CNAME", answer: target, ttl: 300 }));
    if (r.id) ids.add(r.id);
  } else
    for (const r of same) {
      await ctx.registrar.deleteRecord(d.name, r.id as string);
      ids.delete(r.id as string);
    }
  await ctx.db.execute(sql`
    update public.domains set managed_records = ${`{${[...ids].join(",")}}`}::text[], updated_at = now()
    where id = ${d.id}::uuid`);
  return true;
}
