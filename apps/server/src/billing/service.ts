/**
 * Billing service (D-070): webhook processing, purchase verification, entitlements and credits.
 * Entitlements are computed here and are the only thing quotas and paywalls read. A purchase
 * belongs to the workspace, so buying on one platform unlocks every platform.
 */
import { randomUUID } from "node:crypto";
import { milestone, track } from "@casama/agent";
import type { Database } from "@casama/db";
import { cloudModelDailyCap, setCloudMarkup } from "@casama/domain";
import { deterministicUuid, getProductAnalytics } from "@casama/observability";
import { sql } from "drizzle-orm";
import { type AccountEmailKind, queueAccountEmail } from "../services/account-emails.ts";
import { PAID_CHANGES, subscriptionChange } from "./analytics.ts";
import {
  BillingError,
  type BillingProvider,
  type BillingSource,
  ENTITLED,
  type ProviderId,
  type SubscriptionSnapshot,
  type SubscriptionStatus,
  type WebhookRequest,
} from "./types.ts";

type PlanRow = {
  code: string;
  name: string;
  interval: string;
  limits: Record<string, unknown>;
  dodo_product_id: string | null;
  store_product_ids: Record<string, string>;
  sort: number;
  price_label?: string | null;
  paywall_default?: boolean;
  paywall_popular?: boolean;
};

export interface BillingServiceOptions {
  db: Database;
  enabled: boolean;
  providers: Partial<Record<ProviderId, BillingProvider>>;
  /** Hourly price of a cloud computer (Casama Link), in USD. */
  cloudComputerUsdPerHour?: number;
  /** What an hour of a Casama Link computer costs the server, for the margin view (D-400). */
  cloudComputerCostPerHour?: number;
  /** The server pays for model calls with its own key, so the plan's daily cap applies (D-311). */
  cloudDailyCap?: boolean;
  /** The supervisor Casama Link computers run on, for putting them to sleep at zero credits. */
  linkSupervisor?: { url: string; token: string };
  logger?: { warn(msg: string, data?: Record<string, unknown>): void };
}

const month = (d = new Date()) => d.toISOString().slice(0, 7);
/** A Postgres array literal for ids and enum-like strings (no quotes or commas inside). */
const arr = (xs: readonly string[]) => `{${xs.join(",")}}`;

/**
 * Domain payments (D-329) arrive on the same Dodo webhook. They're offered here first; each method
 * answers true when the event was a domain one and is handled, so plan billing never sees it.
 */
export interface DomainBillingHook {
  subscription(snap: SubscriptionSnapshot): Promise<boolean>;
  payment(paymentId: string): Promise<boolean>;
  refund(paymentId: string): Promise<boolean>;
}

export class BillingService {
  /** Set when this server sells domains (sites/buying.ts). */
  domains?: DomainBillingHook;
  readonly db: Database;
  readonly enabled: boolean;
  readonly providers: Partial<Record<ProviderId, BillingProvider>>;
  private readonly opts: BillingServiceOptions;

  constructor(opts: BillingServiceOptions) {
    this.opts = opts;
    this.db = opts.db;
    this.enabled = opts.enabled;
    this.providers = opts.providers;
  }

  get defaultPlan() {
    return this.enabled ? "free" : "selfhost";
  }

  provider(id: ProviderId): BillingProvider {
    const p = this.providers[id];
    if (!p)
      throw new BillingError(
        "provider_not_configured",
        `${id} billing is not configured on this server`,
        409,
      );
    return p;
  }

  async plans() {
    return this.db.execute<PlanRow>(
      sql`select code, name, interval, limits, dodo_product_id, store_product_ids, sort, price_label, paywall_default, paywall_popular from public.plans where active order by sort`,
    );
  }

  async packs() {
    return this.db.execute<{
      code: string;
      name: string;
      credits_usd: string;
      dodo_product_id: string | null;
      store_product_ids: Record<string, string>;
      price_label: string | null;
    }>(
      sql`select code, name, credits_usd, dodo_product_id, store_product_ids, price_label from public.credit_packs where active order by credits_usd`,
    );
  }

  /** Maps a store product id to a plan (Google ids may be `product:basePlan` or `product`). */
  async planForProduct(source: BillingSource, productId: string) {
    const plans = await this.plans();
    const match = (p: PlanRow) => {
      if (source === "dodo") return p.dodo_product_id === productId;
      const id = p.store_product_ids?.[source];
      if (!id) return false;
      return id === productId || id.split(":")[0] === productId;
    };
    const plan =
      plans.find((p) => match(p) && p.store_product_ids?.[source] === productId) ??
      plans.find(match);
    if (!plan)
      throw new BillingError("unknown_product", `No plan uses ${source} product ${productId}`, 400);
    return plan;
  }

  // ---------------------------------------------------------------------------
  // Webhooks
  // ---------------------------------------------------------------------------

  async handleWebhook(source: ProviderId, req: WebhookRequest) {
    const provider = this.provider(source);
    await provider.verifyWebhook(req);
    const ev = await provider.parseEvent(req);
    const [stored] = await this.db.execute<{ id: string; processed_at: Date | null }>(sql`
      insert into public.billing_events (source, event_id, type, payload)
      values (${source}, ${ev.eventId}, ${ev.type}, ${JSON.stringify(ev.payload)}::jsonb)
      on conflict (source, event_id) do update set type = excluded.type
      returning id, processed_at`);
    if (stored?.processed_at) return { duplicate: true, type: ev.type };
    try {
      const domains = source === "dodo" ? this.domains : undefined;
      if (ev.kind === "subscription") {
        const snap = await provider.fetchSubscription(ev.externalId);
        if (!(await domains?.subscription(snap)))
          await this.applySnapshot(snap, { refund: ev.refund || ev.revoke });
      } else if (ev.kind === "payment") {
        if (!(await domains?.payment(ev.paymentId)))
          await this.applyPayment(provider, ev.paymentId);
      } else if (ev.kind === "refund") {
        if (!(await domains?.refund(ev.paymentId)))
          await this.applyRefund(provider, ev.paymentId, ev);
      } else if (ev.kind === "customers") {
        const refunded = new Set<string>();
        for (const storeId of ev.refundStoreIds) {
          const id = await provider.findSubscription?.(storeId);
          if (id) refunded.add(id);
        }
        for (const id of ev.customerIds) await this.syncStoreCustomer(id, { refunded });
      }
      await this.db.execute(
        sql`update public.billing_events set processed_at = now(), error = null where id = ${stored?.id}::uuid`,
      );
    } catch (err) {
      await this.db.execute(
        sql`update public.billing_events set error = ${(err as Error).message.slice(0, 500)} where id = ${stored?.id}::uuid`,
      );
      throw err;
    }
    return { duplicate: false, type: ev.type };
  }

  /** Takes back the credits a refunded store pack added, once (D-248). */
  async applyPackRefund(references: string[]) {
    const [bought] = await this.db.execute<{
      org_id: string;
      delta: string;
      reference: string;
    }>(sql`
      select org_id, delta::text, reference from public.credit_ledger
      where reason = 'purchase' and reference = any(${arr(references)}::text[]) limit 1`);
    if (!bought) return;
    await this.credit(
      bought.org_id,
      -Number(bought.delta),
      "refund",
      bought.reference,
      "Credit pack refunded",
    );
  }

  /** Stores the provider's view of a subscription and recomputes the workspace's entitlement. */
  async applySnapshot(snap: SubscriptionSnapshot, opts: { orgId?: string; refund?: boolean } = {}) {
    const [existing] = await this.db.execute<{
      org_id: string;
      status: SubscriptionStatus;
      plan_code: string;
      current_period_end: Date | string | null;
      cancel_at_period_end: boolean;
      refunded_through: Date | string | null;
    }>(sql`
      select org_id, status, plan_code, current_period_end, cancel_at_period_end, refunded_through
      from public.subscriptions
      where source = ${snap.source} and external_id = ${snap.externalId}`);
    const orgId = existing?.org_id ?? snap.orgId ?? opts.orgId;
    if (!orgId)
      throw new BillingError("unknown_org", "This purchase is not linked to a workspace", 400);
    if (opts.orgId && orgId !== opts.orgId)
      throw new BillingError("purchase_in_use", "This purchase belongs to another workspace", 409);
    if (snap.orgId && snap.orgId !== orgId)
      throw new BillingError(
        "purchase_in_use",
        "This purchase was made for another workspace",
        409,
      );
    const plan = await this.planForProduct(snap.source, snap.productId);
    // A refund takes back the period it paid for (billing audit 2026-11-17; it used to be final):
    // re-fetches still say "refunded" until a later paid period, past the refunded one, arrives.
    const refundedThrough = existing?.refunded_through ? new Date(existing.refunded_through) : null;
    const stillRefunded =
      !opts.refund &&
      existing?.status === "refunded" &&
      (!refundedThrough || !snap.currentPeriodEnd || snap.currentPeriodEnd <= refundedThrough);
    const status = opts.refund || stillRefunded ? "refunded" : snap.status;
    const periodEnd =
      snap.currentPeriodEnd ??
      (existing?.current_period_end ? new Date(existing.current_period_end) : null);
    const newRefundedThrough = opts.refund
      ? (periodEnd ?? new Date()).toISOString()
      : (refundedThrough?.toISOString() ?? null);
    // One trial per person, by inbox (billing audit 2026-11-17): every subscription uses it, and
    // a web trial that started although it was used (two checkouts at once in two workspaces)
    // gives nothing until it is paid. Store trials are the store's to give: one started after the
    // person's trial was used keeps the plan for its free week but gets no trial credits from us.
    const [claim] = await this.db.execute<{ mine: boolean | null }>(sql`
      select public.claim_trial(o.created_by, ${`${snap.source}:${snap.externalId}`}) as mine
      from public.organizations o where o.id = ${orgId}::uuid`);
    const trialBlocked = !existing && snap.status === "trialing" && claim?.mine === false;
    await this.db.execute(sql`
      insert into public.subscriptions (org_id, source, external_id, customer_id, plan_code, status,
        current_period_end, cancel_at_period_end, raw, extra_seats, refunded_through, trial_blocked)
      values (${orgId}::uuid, ${snap.source}, ${snap.externalId}, ${snap.customerId ?? null}, ${plan.code},
        ${status}, ${snap.currentPeriodEnd?.toISOString() ?? null}::timestamptz, ${snap.cancelAtPeriodEnd},
        ${JSON.stringify(snap.raw ?? {})}::jsonb, ${snap.extraSeats ?? 0}, ${newRefundedThrough}::timestamptz,
        ${trialBlocked})
      on conflict (source, external_id) do update set
        plan_code = excluded.plan_code,
        status = excluded.status,
        refunded_through = excluded.refunded_through,
        current_period_end = excluded.current_period_end,
        cancel_at_period_end = excluded.cancel_at_period_end,
        customer_id = coalesce(excluded.customer_id, public.subscriptions.customer_id),
        raw = excluded.raw,
        extra_seats = excluded.extra_seats,
        updated_at = now()`);
    await this.trackSubscription(orgId, snap, plan, status, existing);
    await this.queueBillingEmail(orgId, snap, plan, status, existing).catch(() => undefined);
    // A refunded period doesn't keep the credits it brought (D-248): every paid grant since the
    // period started (for a yearly plan, each month's), plan-change top-ups included. Once per
    // subscription and period; it may leave the balance below zero, which stops paid usage.
    if (opts.refund) {
      const end = periodEnd ?? new Date();
      const start = new Date(end);
      if (plan.interval === "year") start.setUTCFullYear(start.getUTCFullYear() - 1);
      else start.setUTCMonth(start.getUTCMonth() - 1);
      const [g] = await this.db.execute<{ granted: string }>(sql`
        select coalesce(sum(delta), 0)::text as granted from public.credit_ledger
        where org_id = ${orgId}::uuid and reason = 'grant' and delta > 0
          and reference like 'monthly:%' and reference not like '%:free'
          and created_at >= ${start.toISOString()}::timestamptz`);
      const granted = Number(g?.granted ?? 0);
      if (granted > 0)
        await this.credit(
          orgId,
          -granted,
          "refund",
          `refund-grant:${snap.source}:${snap.externalId}:${end.toISOString().slice(0, 10)}`,
          `${plan.name} refunded: its credits for that period come back out`,
        );
    }
    return this.recompute(orgId);
  }

  /**
   * The customer's email about a subscription change (D-302): queued in the outbox, sent by the
   * worker. Keyed by subscription, change and period, so a re-fetched snapshot never sends twice.
   */
  private async queueBillingEmail(
    orgId: string,
    snap: SubscriptionSnapshot,
    plan: PlanRow,
    status: SubscriptionStatus,
    existing:
      | {
          status: SubscriptionStatus;
          plan_code: string;
          current_period_end: Date | string | null;
          cancel_at_period_end: boolean;
        }
      | undefined,
  ) {
    if (!this.enabled) return;
    const asDate = (d: Date | string | null) => (d ? new Date(d) : null);
    const change = subscriptionChange(
      existing && {
        status: existing.status,
        plan_code: existing.plan_code,
        period_end: asDate(existing.current_period_end),
      },
      { status, plan_code: plan.code, period_end: snap.currentPeriodEnd },
    );
    const kind: AccountEmailKind | null =
      change === "trial_started"
        ? "trial_started"
        : change === "started" || change === "trial_converted" || change === "plan_changed"
          ? "plan_started"
          : change === "grace"
            ? "payment_failed"
            : change === "expired"
              ? "expired"
              : change === "refunded"
                ? "refunded"
                : // Turning renewal off isn't a status change: it's the flag flipping on.
                  snap.cancelAtPeriodEnd &&
                    existing &&
                    !existing.cancel_at_period_end &&
                    ENTITLED.includes(status)
                  ? "cancel_scheduled"
                  : null;
    if (!kind) return;
    const until = snap.currentPeriodEnd?.toISOString() ?? null;
    await queueAccountEmail(this.db, {
      kind,
      orgId,
      dedupeKey: `${kind}:${snap.source}:${snap.externalId}:${until ?? ""}:${plan.code}`,
      data: { plan: plan.name, until, source: snap.source },
    });
  }

  /**
   * Product analytics for a subscription change (ANALYTICS-PLAN §6.8). Attributed to the workspace owner
   * (the webhook does not say who paid), carries ids and enums only, and a retry of the same period merges
   * in PostHog. `purchase` has no `value` yet: plans only have a text price label, not an amount.
   */
  private async trackSubscription(
    orgId: string,
    snap: SubscriptionSnapshot,
    plan: PlanRow,
    status: SubscriptionStatus,
    existing:
      | {
          status: SubscriptionStatus;
          plan_code: string;
          current_period_end: Date | string | null;
        }
      | undefined,
  ) {
    if (!getProductAnalytics().enabled) return;
    const asDate = (d: Date | string | null) => (d ? new Date(d) : null);
    const change = subscriptionChange(
      existing && {
        status: existing.status,
        plan_code: existing.plan_code,
        period_end: asDate(existing.current_period_end),
      },
      { status, plan_code: plan.code, period_end: snap.currentPeriodEnd },
    );
    if (!change) return;
    const [owner] = await this.db.execute<{ created_by: string | null }>(
      sql`select created_by from public.organizations where id = ${orgId}::uuid`,
    );
    const base = {
      store: snap.source,
      plan: plan.code,
      interval: plan.interval,
      product_id: snap.productId,
    };
    const once = deterministicUuid(
      "subscription",
      snap.source,
      snap.externalId,
      change,
      snap.currentPeriodEnd?.toISOString() ?? "",
    );
    track(this.db, {
      event: "subscription_changed",
      userId: owner?.created_by,
      orgId,
      uuid: once,
      properties: { ...base, change, from_status: existing?.status ?? "none", to_status: status },
    });
    if (PAID_CHANGES.includes(change))
      milestone(this.db, owner?.created_by, "first_purchase", orgId);
    if (PAID_CHANGES.includes(change))
      track(this.db, {
        event: "purchase",
        userId: owner?.created_by,
        orgId,
        uuid: deterministicUuid(
          "purchase",
          snap.source,
          snap.externalId,
          snap.currentPeriodEnd?.toISOString() ?? "",
        ),
        properties: { ...base, kind: change === "renewed" ? "renewal" : "new" },
      });
  }

  private async applyPayment(provider: BillingProvider, paymentId: string) {
    if (!provider.fetchPayment) return;
    const p = await provider.fetchPayment(paymentId);
    if (p.status && p.status !== "succeeded") return;
    const credits = await this.packCredits(p.productIds);
    if (credits <= 0) return; // subscription payments are handled by subscription events
    if (!p.orgId) throw new BillingError("unknown_org", "Payment has no workspace", 400);
    await this.credit(p.orgId, credits, "purchase", `dodo:${paymentId}`, "Credit pack");
    if (getProductAnalytics().enabled) {
      const [owner] = await this.db.execute<{ created_by: string | null }>(
        sql`select created_by from public.organizations where id = ${p.orgId}::uuid`,
      );
      track(this.db, {
        event: "purchase",
        userId: owner?.created_by,
        orgId: p.orgId,
        uuid: deterministicUuid("purchase", "dodo", paymentId),
        properties: { store: "dodo", kind: "credit_pack" },
      });
    }
  }

  private async applyRefund(
    provider: BillingProvider,
    paymentId: string,
    ev: { dispute?: boolean; partial?: boolean } = {},
  ) {
    if (!provider.fetchPayment) return;
    const p = await provider.fetchPayment(paymentId);
    if (p.subscriptionId) {
      const snap = await provider.fetchSubscription(p.subscriptionId);
      // Only a lost dispute, or a full refund of the payment for the current period, takes the
      // period back (billing audit 2026-11-17). A partial (goodwill) refund, or a refund of an
      // older renewal, leaves the plan the customer is still paying for.
      const full =
        ev.dispute === true ||
        (!ev.partial &&
          (p.totalAmount == null || p.refundedAmount == null || p.refundedAmount >= p.totalAmount));
      let current = true;
      if (p.createdAt && snap.currentPeriodEnd) {
        const plan = await this.planForProduct(snap.source, snap.productId);
        const start = new Date(snap.currentPeriodEnd);
        if (plan.interval === "year") start.setUTCFullYear(start.getUTCFullYear() - 1);
        else start.setUTCMonth(start.getUTCMonth() - 1);
        // Two days' slack: a renewal is charged around the period boundary.
        current = p.createdAt.getTime() >= start.getTime() - 2 * 86_400_000;
      }
      await this.applySnapshot(snap, { refund: ev.dispute === true || (full && current) });
    }
    const credits = await this.packCredits(p.productIds);
    if (credits > 0 && p.orgId)
      await this.credit(p.orgId, -credits, "refund", `dodo:${paymentId}`, "Credit pack refunded");
    if (p.orgId && getProductAnalytics().enabled)
      track(this.db, {
        event: "refund_issued",
        orgId: p.orgId,
        uuid: deterministicUuid("refund", "dodo", paymentId),
        properties: { store: "dodo", kind: credits > 0 ? "credit_pack" : "subscription" },
      });
  }

  private async packCredits(productIds: string[]) {
    if (!productIds.length) return 0;
    const packs = await this.packs();
    return productIds.reduce(
      (sum, id) => sum + Number(packs.find((p) => p.dodo_product_id === id)?.credits_usd ?? 0),
      0,
    );
  }

  /**
   * Re-reads everything a workspace bought in the app stores (through RevenueCat, D-297) and
   * applies it: subscriptions become entitlements, credit packs add credits once, refunds take
   * them back. `refunded` holds RevenueCat subscription ids a refund was reported for.
   * Purchases RevenueCat lists under this workspace that are already linked to another workspace
   * are left alone and returned in `inUse`.
   */
  async syncStoreCustomer(orgId: string, opts: { refunded?: Set<string> } = {}) {
    const result = {
      found: [] as Array<{ source: string; productId: string }>,
      inUse: [] as string[],
    };
    const [org] = await this.db.execute<{ id: string }>(
      sql`select id from public.organizations where id = ${orgId}::uuid`,
    );
    if (!org) return result;
    const rc = this.provider("revenuecat");
    if (!rc.storeCustomer)
      throw new BillingError("unsupported", "This provider cannot list purchases", 400);
    const customer = await rc.storeCustomer(orgId);
    for (const snap of customer.subscriptions) {
      try {
        await this.applySnapshot(snap, { orgId, refund: opts.refunded?.has(snap.externalId) });
        result.found.push({ source: snap.source, productId: snap.productId });
      } catch (err) {
        if (err instanceof BillingError && err.code === "purchase_in_use") {
          result.inUse.push(snap.productId);
          continue;
        }
        // A store product no plan uses (an old or test product) doesn't block the rest.
        if (err instanceof BillingError && err.code === "unknown_product") {
          this.opts.logger?.warn("store subscription for an unknown product", {
            product_id: snap.productId,
          });
          continue;
        }
        throw err;
      }
    }
    const packs = await this.packs();
    for (const p of customer.purchases) {
      // A credit pack is a one-time purchase, not a subscription (D-244).
      const pack = packs.find((k) => k.store_product_ids?.[p.source] === p.productId);
      if (!pack) continue;
      const reference = `revenuecat:${p.id}`;
      if (p.status === "refunded") {
        await this.applyPackRefund([reference]);
        continue;
      }
      // A purchase credits one workspace once, whichever workspace reports it first.
      const [other] = await this.db.execute<{ org_id: string }>(sql`
        select org_id from public.credit_ledger where reason = 'purchase' and reference = ${reference} limit 1`);
      if (other && other.org_id !== orgId) {
        result.inUse.push(p.productId);
        continue;
      }
      await this.credit(orgId, Number(pack.credits_usd), "purchase", reference, pack.name);
      result.found.push({ source: p.source, productId: p.productId });
    }
    if (!customer.subscriptions.length) await this.recompute(orgId);
    return result;
  }

  /**
   * The app finished a purchase or a restore: re-read the workspace's store purchases and check
   * the product it reported is among them. The apps buy through RevenueCat with the workspace id
   * as the customer, so a purchase can't be claimed by another workspace (D-297).
   */
  async verifyPurchase(
    orgId: string,
    source: "app_store" | "google_play",
    args: { productId: string },
  ) {
    const r = await this.syncStoreCustomer(orgId);
    const base = (id: string) => id.split(":")[0];
    const matches = (id: string) => id === args.productId || base(id) === base(args.productId);
    if (r.found.some((f) => f.source === source && matches(f.productId)))
      return this.recompute(orgId);
    if (r.inUse.some(matches))
      throw new BillingError("purchase_in_use", "This purchase belongs to another workspace", 409);
    throw new BillingError(
      "purchase_not_found",
      "The store has no record of this purchase yet",
      409,
    );
  }

  // ---------------------------------------------------------------------------
  // Entitlements and credits
  // ---------------------------------------------------------------------------

  async credit(orgId: string, delta: number, reason: string, reference: string, note?: string) {
    const [r] = await this.db.execute<{ balance: string }>(
      sql`select public.credit_apply(${orgId}::uuid, ${delta}, ${reason}, ${reference}, ${note ?? null}) as balance`,
    );
    return Number(r?.balance ?? 0);
  }

  async balance(orgId: string) {
    const [r] = await this.db.execute<{ b: string }>(
      sql`select balance_after as b from public.credit_ledger where org_id = ${orgId}::uuid order by seq desc limit 1`,
    );
    return Number(r?.b ?? 0);
  }

  /**
   * Whether this is its owner's oldest workspace on the free plan (the one that gets free credits),
   * and its owner is the account that gets their inbox's free credits: "+tag" and Gmail-dot
   * accounts on one inbox, or a new account after deleting one, don't get more (billing audit
   * 2026-11-17, public.claim_free_credits).
   */
  private async firstFreeWorkspace(orgId: string) {
    const [r] = await this.db.execute<{ first: boolean }>(sql`
      select not exists (
        select 1 from public.organizations o
        join public.organizations me on me.id = ${orgId}::uuid
        where o.created_by = me.created_by and o.id <> me.id and o.plan = 'free'
          and (o.created_at, o.id) < (me.created_at, me.id)
      ) as first`);
    if (r && !r.first) return false;
    const [c] = await this.db.execute<{ ok: boolean | null }>(sql`
      select public.claim_free_credits(o.created_by) as ok
      from public.organizations o where o.id = ${orgId}::uuid`);
    return c?.ok ?? true;
  }

  /** Picks the best entitled subscription (or the default plan) and writes the entitlement. */
  async recompute(orgId: string) {
    const [best] = await this.db.execute<{
      id: string;
      plan_code: string;
      source: string;
      status: SubscriptionStatus;
      current_period_end: Date | null;
      trial_blocked: boolean;
    }>(sql`
      select s.id, s.plan_code, s.source, s.status, s.current_period_end, s.trial_blocked
      from public.subscriptions s
      join public.plans p on p.code = s.plan_code
      where s.org_id = ${orgId}::uuid and s.status = any(${arr(ENTITLED)}::text[])
        and (s.current_period_end is null or s.current_period_end > now())
        and not (s.status = 'trialing' and s.trial_blocked and s.source = 'dodo')
      order by p.sort desc, s.current_period_end desc nulls last limit 1`);
    const planCode = best?.plan_code ?? this.defaultPlan;
    const [plan] = await this.db.execute<PlanRow>(
      sql`select code, name, interval, limits, dodo_product_id, store_product_ids, sort from public.plans where code = ${planCode}`,
    );
    if (!plan) throw new Error(`plan ${planCode} missing`);
    const [current] = await this.db.execute<{ id: string; overrides: Record<string, unknown> }>(
      sql`select id, overrides from public.entitlements where org_id = ${orgId}::uuid order by created_at desc limit 1`,
    );
    const [lim] = await this.db.execute<{ limits: Record<string, unknown> }>(
      sql`select public.entitlement_limits(${planCode}, ${best?.id ?? null}::uuid, ${JSON.stringify(current?.overrides ?? {})}::jsonb) as limits`,
    );
    const limits = lim?.limits ?? plan.limits;
    const validUntil = best?.current_period_end
      ? new Date(best.current_period_end).toISOString()
      : null;
    if (current)
      await this.db.execute(sql`
        update public.entitlements set plan_code = ${planCode}, limits = ${JSON.stringify(limits)}::jsonb,
          valid_until = ${validUntil}::timestamptz, subscription_id = ${best?.id ?? null}::uuid,
          source = ${best?.source ?? "default"}, updated_at = now()
        where id = ${current.id}::uuid`);
    else
      await this.db.execute(sql`
        insert into public.entitlements (org_id, plan_code, limits, valid_until, subscription_id, source)
        values (${orgId}::uuid, ${planCode}, ${JSON.stringify(limits)}::jsonb, ${validUntil}::timestamptz,
          ${best?.id ?? null}::uuid, ${best?.source ?? "default"})`);
    await this.db.execute(
      sql`update public.organizations set plan = ${planCode} where id = ${orgId}::uuid`,
    );
    // Included credits, once a month. A plan change tops the month up to the new plan's amount
    // rather than granting it again, and only a person's first free workspace gets free credits
    // (D-246). A zero grant still marks the month as done, so settlement doesn't retry it.
    // A trial gets its own, smaller grant; paying tops the month up to the plan's amount (D-249).
    const trial = best?.status === "trialing" && plan.limits.trial_credits_usd != null;
    // A store trial after the person's trial was used: the plan, but no second trial grant.
    const monthly = Number(
      (trial
        ? best?.trial_blocked
          ? 0
          : plan.limits.trial_credits_usd
        : plan.limits.monthly_credits_usd) ?? 0,
    );
    if (this.enabled && monthly > 0) {
      // The month a grant belongs to follows the paid period, not the calendar (billing audit
      // 2026-11-17): see public.grant_month.
      const [gm] = await this.db.execute<{ m: string }>(
        sql`select public.grant_month(${best?.id ?? null}::uuid) as m`,
      );
      const label = gm?.m ?? month();
      const ref = `monthly:${label}:${planCode}${trial ? ":trial" : ""}`;
      const [done] = await this.db.execute<{
        granted: string;
        this_plan: boolean;
        paid_before: boolean;
      }>(sql`
        select coalesce(sum(delta), 0)::text as granted, bool_or(reference = ${ref}) as this_plan,
          coalesce(bool_or(delta > 0 and reference not like '%:free' and reference not like '%:trial'), false) as paid_before
        from public.credit_ledger
        where org_id = ${orgId}::uuid and reason = 'grant' and reference like ${`monthly:${label}:%`}`);
      if (!done?.this_plan) {
        let amount = Math.max(0, monthly - Number(done?.granted ?? 0));
        let note = trial ? `${plan.name} trial credits` : `${plan.name} monthly credits`;
        // Moving up from one paid plan to another mid-period is charged pro rata, so the extra
        // credits are too: the share of the period left. Before, upgrading the day before renewal
        // paid a day's difference for the whole month's extra credits, and downgrading back kept
        // them (billing audit 2026-11-17). Starting to pay (from Free or a trial) tops up in full.
        if (amount > 0 && done?.paid_before && best?.current_period_end && !trial) {
          const days = plan.interval === "year" ? 365 : 30;
          const left = (new Date(best.current_period_end).getTime() - Date.now()) / 86_400_000;
          const share = Math.min(1, Math.max(0, left / days));
          amount = Math.round(amount * share * 100) / 100;
          note = `${plan.name} monthly credits (the rest of this period)`;
        }
        if (planCode === "free" && amount > 0 && !(await this.firstFreeWorkspace(orgId))) {
          amount = 0;
          note = "Free credits go to your first free workspace";
        }
        await this.credit(orgId, amount, "grant", ref, note);
      }
    }
    return { planCode, limits, validUntil };
  }

  async summary(orgId: string) {
    const [ent] = await this.db.execute<{
      plan_code: string;
      name: string;
      interval: string;
      limits: Record<string, unknown>;
      plan_limits: Record<string, unknown>;
      valid_until: Date | null;
      source: string;
    }>(sql`
      select e.plan_code, p.name, p.interval, e.limits, p.limits as plan_limits, e.valid_until, e.source
      from public.entitlements e join public.plans p on p.code = e.plan_code
      where e.org_id = ${orgId}::uuid order by e.created_at desc limit 1`);
    const subs = await this.db.execute<{
      id: string;
      source: string;
      plan_code: string;
      status: string;
      current_period_end: Date | null;
      cancel_at_period_end: boolean;
      extra_seats: number;
    }>(sql`
      select id, source, plan_code, status, current_period_end, cancel_at_period_end, extra_seats
      from public.subscriptions where org_id = ${orgId}::uuid order by updated_at desc limit 20`);
    const active = subs.find(
      (s) =>
        ENTITLED.includes(s.status as never) &&
        (!s.current_period_end || new Date(s.current_period_end) > new Date()),
    );
    return {
      enabled: this.enabled,
      plan_code: ent?.plan_code ?? this.defaultPlan,
      plan_name: ent?.name ?? "Self-hosted",
      interval: ent?.interval ?? "none",
      limits: Object.fromEntries(
        Object.entries({
          ...ent?.limits,
          // Monthly credits are granted from the plan, never from owner overrides, so show what
          // actually arrives: an override must not promise "adds $15 every month" on Free.
          monthly_credits_usd: ent ? ent.plan_limits?.monthly_credits_usd : undefined,
        }).filter(([, v]) => typeof v === "number"),
      ) as Record<string, number>,
      unlimited: !this.enabled || ent?.limits?.unlimited === true,
      valid_until: ent?.valid_until ? new Date(ent.valid_until).toISOString() : null,
      source: (ent?.source ?? "default") as "default" | BillingSource,
      cancel_at_period_end: active?.cancel_at_period_end ?? false,
      extra_seats: active?.extra_seats ?? 0,
      trial_available: this.enabled ? await this.trialAvailable(orgId) : false,
      credits_usd: this.enabled ? await this.balance(orgId) : 0,
      daily: await this.dailyUsage(orgId, ent?.plan_code, ent?.limits),
      subscriptions: subs.map((s) => ({
        id: s.id,
        source: s.source as BillingSource,
        plan_code: s.plan_code,
        status: s.status,
        current_period_end: s.current_period_end
          ? new Date(s.current_period_end).toISOString()
          : null,
        cancel_at_period_end: s.cancel_at_period_end,
      })),
      // Where things can be bought; RevenueCat stands for both app stores.
      providers: (Object.keys(this.providers) as ProviderId[])
        .flatMap((p): BillingSource[] => (p === "revenuecat" ? ["app_store", "google_play"] : [p]))
        .sort(),
    };
  }

  /**
   * Today's spend on the server's keys against the plan's daily cap, or null when no cap applies.
   * The same sum the run admission checks (packages/agent run.ts `cloud_today`), so the app shows
   * the limit that actually stops runs (D-311).
   */
  async dailyUsage(
    orgId: string,
    planCode: string | undefined,
    limits: Record<string, unknown> | undefined,
  ) {
    if (!this.enabled || !this.opts.cloudDailyCap || limits?.unlimited === true) return null;
    const [r] = await this.db.execute<{ today: string }>(sql`
      select coalesce(sum(cost_usd), 0)::text as today from public.usage_ledger
      where org_id = ${orgId}::uuid and billable
        and kind <> all('{computer_seconds,stream_seconds}'::text[])
        and created_at >= date_trunc('day', now() at time zone 'utc') at time zone 'utc'`);
    const now = new Date();
    const resets = new Date(
      Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + 1),
    );
    return {
      used_usd: Math.round(Number(r?.today ?? 0) * 1e6) / 1e6,
      cap_usd: cloudModelDailyCap(planCode ?? this.defaultPlan, limits?.cloud_daily_usd),
      resets_at: resets.toISOString(),
    };
  }

  /** The workspace's subscription that is paid up now, if any. */
  async activeSubscription(orgId: string) {
    const [s] = await this.db.execute<{
      external_id: string;
      source: BillingSource;
      plan_code: string;
      extra_seats: number | null;
      status: SubscriptionStatus;
    }>(sql`
      select external_id, source, plan_code, extra_seats, status from public.subscriptions
      where org_id = ${orgId}::uuid and status = any(${arr(ENTITLED)}::text[])
        and (current_period_end is null or current_period_end > now())
      order by updated_at desc limit 1`);
    return s ?? null;
  }

  private async planOf(orgId: string) {
    const [e] = await this.db.execute<{ plan_code: string }>(
      sql`select plan_code from public.entitlements where org_id = ${orgId}::uuid order by created_at desc limit 1`,
    );
    return e?.plan_code ?? this.defaultPlan;
  }

  async checkout(
    orgId: string,
    what: { planCode?: string; packCode?: string },
    email: string | null,
    returnUrl: string,
  ) {
    const dodo = this.provider("dodo");
    let productId: string | null | undefined;
    if (what.planCode) {
      const plan = (await this.plans()).find((p) => p.code === what.planCode);
      if (!plan || plan.interval === "none")
        throw new BillingError("unknown_plan", "That plan cannot be bought", 400);
      productId = plan.dodo_product_id;
      // One subscription per workspace (D-248): a web subscriber changes plans in place, and a
      // store subscriber changes plans in that store.
      const current = await this.activeSubscription(orgId);
      if (current) {
        if (current.plan_code === what.planCode)
          throw new BillingError("already_subscribed", "This workspace already has that plan", 409);
        if (current.source !== "dodo")
          throw new BillingError(
            "subscribed_in_store",
            `This workspace subscribes through ${current.source === "app_store" ? "the App Store" : "Google Play"}. Change plans there.`,
            409,
          );
        if (!productId)
          throw new BillingError("unknown_product", "That item is not for sale on the web", 400);
        // A trial is of one plan: switching during it would hand out another plan's limits and
        // full credits before anything is paid (billing audit 2026-11-17).
        if (current.status === "trialing")
          throw new BillingError(
            "trialing",
            "You can change plans once the trial ends, or cancel the trial and choose another plan.",
            409,
          );
        const dodo = this.provider("dodo");
        // Extra people bought on the old plan move to the new one when it sells them (D-249).
        const seats = Number(current.extra_seats ?? 0);
        const [cfg] =
          seats > 0
            ? await this.db.execute<{ month: string | null; year: string | null }>(
                sql`select dodo_seat_addon_month as month, dodo_seat_addon_year as year from public.billing_settings where id`,
              )
            : [];
        const addonId = plan.interval === "year" ? cfg?.year : cfg?.month;
        if (seats > 0 && addonId && typeof plan.limits.extra_seat_usd === "number")
          await (dodo.setAddon as NonNullable<BillingProvider["setAddon"]>)({
            subscriptionId: current.external_id,
            productId,
            addonId,
            quantity: seats,
          });
        else
          await (dodo.changePlan as NonNullable<BillingProvider["changePlan"]>)(
            current.external_id,
            productId,
          );
        await this.applySnapshot(await dodo.fetchSubscription(current.external_id), { orgId });
        return { url: returnUrl, sessionId: null, changed: true };
      }
    } else if (what.packCode) {
      // Credit packs are for paying plans; a free workspace upgrades instead (D-246).
      if ((await this.planOf(orgId)) === "free")
        throw new BillingError("paid_plan_required", "Credit packs come with a paid plan", 402);
      productId = (await this.packs()).find((p) => p.code === what.packCode)?.dodo_product_id;
    }
    if (!productId)
      throw new BillingError("unknown_product", "That item is not for sale on the web", 400);
    const [sub] = await this.db.execute<{ customer_id: string | null }>(sql`
      select customer_id from public.subscriptions where org_id = ${orgId}::uuid and source = 'dodo' and customer_id is not null
      order by updated_at desc limit 1`);
    const trialDays = what.planCode ? await this.trialDays(orgId, what.planCode) : 0;
    return (dodo.createCheckout as NonNullable<BillingProvider["createCheckout"]>)({
      productId,
      orgId,
      email,
      customerId: sub?.customer_id ?? null,
      returnUrl,
      trialDays,
    });
  }

  /**
   * Whether this workspace's owner can still start a free trial (D-249): one trial per person,
   * across all their workspaces, and never after any subscription. The stores apply their own
   * rule (one introductory offer per Apple ID or Google account) to store purchases.
   */
  async trialAvailable(orgId: string) {
    const [r] = await this.db.execute<{ ok: boolean }>(sql`
      select not exists (
        select 1 from public.subscriptions s
        join public.organizations o on o.id = s.org_id
        join public.organizations me on me.id = ${orgId}::uuid
        where o.created_by = me.created_by
      ) and not coalesce((
        select public.trial_used(o.created_by) from public.organizations o
        where o.id = ${orgId}::uuid), false) as ok`);
    return r?.ok ?? false;
  }

  /** The free-trial days a web checkout of this plan gets, or 0. */
  private async trialDays(orgId: string, planCode: string) {
    const plan = (await this.plans()).find((p) => p.code === planCode);
    const days = Number(plan?.limits.trial_days ?? 0);
    return days > 0 && (await this.trialAvailable(orgId)) ? days : 0;
  }

  /**
   * Sets how many people the workspace pays for beyond its plan's seats (D-249). Only a web
   * subscription can carry them (a Dodo add-on, prorated now); store subscriptions cannot.
   */
  async setExtraSeats(orgId: string, extra: number) {
    const [cur] = await this.db.execute<{
      external_id: string;
      source: BillingSource;
      plan_code: string;
      status: SubscriptionStatus;
    }>(sql`
      select s.external_id, s.source, s.plan_code, s.status from public.subscriptions s
      join public.plans p on p.code = s.plan_code
      where s.org_id = ${orgId}::uuid and s.status = any(${arr(ENTITLED)}::text[])
        and (s.current_period_end is null or s.current_period_end > now())
      order by p.sort desc, s.current_period_end desc nulls last limit 1`);
    if (!cur)
      throw new BillingError("paid_plan_required", "Extra people come with Pro or Max", 402);
    const plan = (await this.plans()).find((p) => p.code === cur.plan_code);
    if (!plan || typeof plan.limits.extra_seat_usd !== "number")
      throw new BillingError("paid_plan_required", "Extra people come with Pro or Max", 402);
    if (cur.source !== "dodo")
      throw new BillingError(
        "subscribed_in_store",
        "Extra people are bought with a web subscription. This workspace subscribes in the app store.",
        409,
      );
    if (cur.status === "trialing" && extra > 0)
      throw new BillingError("trialing", "Extra people can be added once the trial ends", 409);
    const [m] = await this.db.execute<{ n: number }>(
      sql`select count(*)::int as n from public.memberships where org_id = ${orgId}::uuid`,
    );
    const base = Number(plan.limits.seats ?? 0);
    if ((m?.n ?? 0) > base + extra)
      throw new BillingError(
        "seats_in_use",
        `This workspace has ${m?.n} people. Remove someone first.`,
        409,
      );
    const [cfg] = await this.db.execute<{ month: string | null; year: string | null }>(
      sql`select dodo_seat_addon_month as month, dodo_seat_addon_year as year from public.billing_settings where id`,
    );
    const addonId = plan.interval === "year" ? cfg?.year : cfg?.month;
    if (!addonId || !plan.dodo_product_id)
      throw new BillingError("unknown_product", "Extra people are not for sale yet", 400);
    const dodo = this.provider("dodo");
    await (dodo.setAddon as NonNullable<BillingProvider["setAddon"]>)({
      subscriptionId: cur.external_id,
      productId: plan.dodo_product_id,
      addonId,
      quantity: extra,
    });
    await this.applySnapshot(await dodo.fetchSubscription(cur.external_id), { orgId });
    return this.summary(orgId);
  }

  async portal(orgId: string, returnUrl: string) {
    const dodo = this.provider("dodo");
    const [sub] = await this.db.execute<{ customer_id: string | null }>(sql`
      select customer_id from public.subscriptions where org_id = ${orgId}::uuid and source = 'dodo' and customer_id is not null
      order by updated_at desc limit 1`);
    if (!sub?.customer_id)
      throw new BillingError(
        "no_web_subscription",
        "This workspace has no web subscription to manage",
        409,
      );
    return (dodo.customerPortal as NonNullable<BillingProvider["customerPortal"]>)({
      customerId: sub.customer_id,
      returnUrl,
    });
  }

  // ---------------------------------------------------------------------------
  // Periodic settlement (worker, every minute)
  // ---------------------------------------------------------------------------

  /**
   * Bills running cloud computers, turns billable usage into credit deductions, reports usage of
   * metered Dodo plans, and refreshes entitlements that expired or are due a monthly grant.
   */
  /** Loads server-wide settings changed from the Admin screen (D-244): the usage markup. */
  async loadSettings() {
    // The database needs to know whether this server bills, so a workspace made any way starts on
    // the free plan rather than the unlimited self-hosted one (D-246).
    await this.db
      .execute(
        sql`update public.billing_settings set enabled = ${this.enabled} where id and enabled <> ${this.enabled}`,
      )
      .catch(() => undefined);
    const [r] = await this.db
      .execute<{ markup: string }>(sql`select markup from public.billing_settings where id`)
      .catch(() => [] as Array<{ markup: string }>);
    if (r) setCloudMarkup(Number(r.markup));
  }

  async settle() {
    if (!this.enabled) return { orgs: 0, usd: 0 };
    await this.loadSettings();
    await this.flushCloudComputers();
    // Link computers of workspaces out of credits or computer hours go to sleep (never blocks settling).
    await this.sleepLinkComputers().catch((err) =>
      this.opts.logger?.warn("link computer sweep failed", { error: (err as Error).message }),
    );
    const usd = await this.db.transaction(async (tx) => {
      const rows = await tx.execute<{
        id: string;
        org_id: string;
        kind: string;
        quantity: string;
        cost_usd: string;
        created_at: Date;
      }>(sql`
        select id, org_id, kind, quantity, cost_usd, created_at from public.usage_ledger
        where billable and billed_at is null order by created_at limit 5000 for update skip locked`);
      if (!rows.length) return new Map<string, number>();
      await tx.execute(
        sql`update public.usage_ledger set billed_at = now() where id = any(${arr(rows.map((r) => r.id))}::uuid[])`,
      );
      const byOrg = new Map<string, number>();
      for (const r of rows) byOrg.set(r.org_id, (byOrg.get(r.org_id) ?? 0) + Number(r.cost_usd));
      const batch = randomUUID();
      // Negative when a hold was larger than the usage it stood in for (D-248): money back.
      for (const [org, cost] of byOrg)
        if (cost !== 0)
          await tx.execute(
            sql`select public.credit_apply(${org}::uuid, ${-cost}, 'usage', ${`usage:${batch}`}, 'Usage')`,
          );
      // Metered plans also report usage to Dodo (best effort; events are idempotent by id).
      const dodo = this.providers.dodo;
      if (dodo?.reportUsage) {
        const metered = await tx.execute<{ org_id: string; customer_id: string }>(sql`
          select s.org_id, s.customer_id from public.subscriptions s join public.plans p on p.code = s.plan_code
          where s.source = 'dodo' and s.status = any(${arr(ENTITLED)}::text[]) and s.customer_id is not null
            and (p.limits->>'metered')::boolean is true and s.org_id = any(${arr([...byOrg.keys()])}::uuid[])`);
        const customers = new Map(metered.map((m) => [m.org_id, m.customer_id]));
        const events = rows
          .filter((r) => customers.has(r.org_id))
          .map((r) => ({
            eventId: r.id,
            customerId: customers.get(r.org_id) as string,
            name: r.kind,
            timestamp: new Date(r.created_at),
            metadata: { quantity: Number(r.quantity), cost_usd: Number(r.cost_usd) },
          }));
        if (events.length)
          await dodo
            .reportUsage(events)
            .catch((err) =>
              this.opts.logger?.warn("dodo usage report failed", { error: (err as Error).message }),
            );
      }
      return byOrg;
    });
    const due = await this.db.execute<{ org_id: string }>(sql`
      select e.org_id from public.entitlements e join public.plans p on p.code = e.plan_code
      where (e.valid_until is not null and e.valid_until < now())
         or e.plan_code = 'selfhost'
         or ((p.limits->>'monthly_credits_usd')::numeric > 0 and not exists (
              select 1 from public.credit_ledger c where c.org_id = e.org_id and c.reason = 'grant'
                and c.reference in ('monthly:' || public.grant_month(e.subscription_id) || ':' || e.plan_code,
                                    'monthly:' || public.grant_month(e.subscription_id) || ':' || e.plan_code || ':trial')))
      -- Lapsed subscriptions first, so they lose paid limits even when many workspaces are due.
      order by (e.valid_until is not null and e.valid_until < now()) desc, e.valid_until nulls last
      limit 500`);
    for (const d of due) await this.recompute(d.org_id);
    // Included credits lapse after the following month; packs and rewards after 12 months (D-246).
    await this.db.execute(sql`select public.expire_credits()`);
    return { orgs: usd.size, usd: [...usd.values()].reduce((a, b) => a + b, 0) };
  }

  /**
   * Writes computer-seconds for cloud computers that are still running (Casama Link). The claimed
   * interval and its usage row commit together, so a crash between them can't lose that time.
   */
  async flushCloudComputers(ref?: string, stop = false) {
    const rate = this.opts.cloudComputerUsdPerHour ?? 0.05;
    const costRate = this.opts.cloudComputerCostPerHour ?? null;
    await this.db.transaction(async (tx) => {
      const rows = await tx.execute<{
        ref: string;
        org_id: string;
        instance_name: string;
        seconds: number;
      }>(sql`
        with c as (
          select ref, running_since from public.link_computers
          where running_since is not null ${ref ? sql`and ref = ${ref}` : sql``}
          for update
        )
        update public.link_computers cc
        set running_since = case when ${stop}::boolean then null else now() end
        from c where cc.ref = c.ref
        returning cc.ref, cc.org_id, cc.instance_name,
          greatest(0, round(extract(epoch from now() - c.running_since)))::int as seconds`);
      for (const r of rows) {
        if (r.seconds <= 0) continue;
        await tx.execute(sql`
          insert into public.usage_ledger (org_id, kind, quantity, cost_usd, upstream_cost_usd, billable, meta)
          values (${r.org_id}::uuid, 'computer_seconds', ${r.seconds}, ${(r.seconds / 3600) * rate},
            ${costRate == null ? null : (r.seconds / 3600) * costRate}, true,
            ${JSON.stringify({ source: "casama_link", instance: r.instance_name, ref: r.ref })}::jsonb)`);
      }
    });
  }

  /**
   * Puts to sleep the Casama Link computers whose workspace has no credits left (after usage not
   * yet settled) or used its computer hours for the month, as the worker does for hosted computers
   * (billing audit 2026-11-17). The snapshot is kept on the computer's row, so the next wake-up
   * through the proxy restores from it rather than the self-hosted server's older one.
   */
  async sleepLinkComputers(supervisor = this.opts.linkSupervisor) {
    if (!this.enabled || !supervisor) return { slept: 0 };
    const rows = await this.db.execute<{ ref: string; org_id: string; reason: string }>(sql`
      select lc.ref, lc.org_id::text,
        case when s.broke then 'out_of_credits' else 'computer_hours' end as reason
      from public.link_computers lc
      left join lateral (select e.limits from public.entitlements e where e.org_id = lc.org_id
        order by e.created_at desc limit 1) e on true
      cross join lateral (select
        coalesce((e.limits->>'credit_gate')::boolean, false)
          and coalesce((select balance_after from public.credit_ledger where org_id = lc.org_id order by seq desc limit 1), 0)
            - (select coalesce(sum(cost_usd), 0) from public.usage_ledger
                where org_id = lc.org_id and billable and billed_at is null) <= 0 as broke,
        coalesce((select coalesce(sum(quantity), 0) from public.usage_ledger
            where org_id = lc.org_id and kind = 'computer_seconds'
              and created_at >= date_trunc('month', now() at time zone 'utc') at time zone 'utc') / 3600.0
          >= (e.limits->>'computer_hours')::numeric, false) as over_hours) s
      where lc.running_since is not null and (s.broke or s.over_hours)
      limit 200`);
    let slept = 0;
    const base = supervisor.url.replace(/\/$/, "");
    for (const r of rows) {
      try {
        const res = await fetch(`${base}/computers/${r.ref}/sleep`, {
          method: "POST",
          headers: { authorization: `Bearer ${supervisor.token}` },
        });
        if (res.ok) {
          const snapshot = await res.json();
          await this.db.execute(sql`
            update public.link_computers set swept_snapshot = ${JSON.stringify(snapshot)}::jsonb
            where ref = ${r.ref}`);
        } else if (res.status !== 404 && res.status !== 409) {
          // 404/409: no longer running there; the meter still stops below.
          throw new Error(`supervisor ${res.status}: ${(await res.text()).slice(0, 200)}`);
        }
        await this.flushCloudComputers(r.ref, true);
        slept++;
      } catch (err) {
        this.opts.logger?.warn("link computer sleep failed", {
          ref: r.ref,
          org_id: r.org_id,
          reason: r.reason,
          error: (err as Error).message,
        });
      }
    }
    return { slept };
  }
}
