/**
 * Billing service (D-070): webhook processing, purchase verification, entitlements and credits.
 * Entitlements are computed here and are the only thing quotas and paywalls read. A purchase
 * belongs to the workspace, so buying on one platform unlocks every platform.
 */
import { randomUUID } from "node:crypto";
import { milestone, track } from "@casama/agent";
import type { Database } from "@casama/db";
import { setCloudMarkup } from "@casama/domain";
import { deterministicUuid, getProductAnalytics } from "@casama/observability";
import { sql } from "drizzle-orm";
import { PAID_CHANGES, subscriptionChange } from "./analytics.ts";
import {
  BillingError,
  type BillingProvider,
  type BillingSource,
  ENTITLED,
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
};

export interface BillingServiceOptions {
  db: Database;
  enabled: boolean;
  providers: Partial<Record<BillingSource, BillingProvider>>;
  /** Hourly price of a cloud computer (Cloud Connect), in USD. */
  cloudComputerUsdPerHour?: number;
  logger?: { warn(msg: string, data?: Record<string, unknown>): void };
}

const month = (d = new Date()) => d.toISOString().slice(0, 7);
/** A Postgres array literal for ids and enum-like strings (no quotes or commas inside). */
const arr = (xs: readonly string[]) => `{${xs.join(",")}}`;

export class BillingService {
  readonly db: Database;
  readonly enabled: boolean;
  readonly providers: Partial<Record<BillingSource, BillingProvider>>;
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

  provider(source: BillingSource): BillingProvider {
    const p = this.providers[source];
    if (!p)
      throw new BillingError(
        "provider_not_configured",
        `${source} billing is not configured on this server`,
        409,
      );
    return p;
  }

  async plans() {
    return this.db.execute<PlanRow>(
      sql`select code, name, interval, limits, dodo_product_id, store_product_ids, sort, price_label from public.plans where active order by sort`,
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

  async handleWebhook(source: BillingSource, req: WebhookRequest) {
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
      if (ev.kind === "subscription") {
        const snap = await provider.fetchSubscription(ev.externalId);
        await this.applySnapshot(snap, { refund: ev.refund || ev.revoke });
      } else if (ev.kind === "payment") {
        await this.applyPayment(provider, ev.paymentId);
      } else if (ev.kind === "refund") {
        await this.applyRefund(provider, ev.paymentId);
      } else if (ev.kind === "pack_refund") {
        await this.applyPackRefund(ev.references);
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
    }>(sql`
      select org_id, status, plan_code, current_period_end from public.subscriptions
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
    const status = opts.refund ? "refunded" : snap.status;
    await this.db.execute(sql`
      insert into public.subscriptions (org_id, source, external_id, customer_id, plan_code, status,
        current_period_end, cancel_at_period_end, raw, extra_seats)
      values (${orgId}::uuid, ${snap.source}, ${snap.externalId}, ${snap.customerId ?? null}, ${plan.code},
        ${status}, ${snap.currentPeriodEnd?.toISOString() ?? null}::timestamptz, ${snap.cancelAtPeriodEnd},
        ${JSON.stringify(snap.raw ?? {})}::jsonb, ${snap.extraSeats ?? 0})
      on conflict (source, external_id) do update set
        plan_code = excluded.plan_code,
        -- A refund is final even if a later re-fetch still reports the old state.
        status = case when public.subscriptions.status = 'refunded' then 'refunded' else excluded.status end,
        current_period_end = excluded.current_period_end,
        cancel_at_period_end = excluded.cancel_at_period_end,
        customer_id = coalesce(excluded.customer_id, public.subscriptions.customer_id),
        raw = excluded.raw,
        extra_seats = excluded.extra_seats,
        updated_at = now()`);
    await this.trackSubscription(orgId, snap, plan, status, existing);
    // A refunded subscription doesn't keep the credits it brought this month (D-248). Once per
    // subscription and month; it may leave the balance below zero, which stops paid usage.
    if (opts.refund && existing?.status !== "refunded") {
      const [g] = await this.db.execute<{ granted: string }>(sql`
        select coalesce(sum(delta), 0)::text as granted from public.credit_ledger
        where org_id = ${orgId}::uuid and reason = 'grant' and reference = ${`monthly:${month()}:${plan.code}`}`);
      const granted = Number(g?.granted ?? 0);
      if (granted > 0)
        await this.credit(
          orgId,
          -granted,
          "refund",
          `refund-grant:${snap.source}:${snap.externalId}:${month()}`,
          `${plan.name} refunded: its monthly credits come back out`,
        );
    }
    return this.recompute(orgId);
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

  private async applyRefund(provider: BillingProvider, paymentId: string) {
    if (!provider.fetchPayment) return;
    const p = await provider.fetchPayment(paymentId);
    if (p.subscriptionId) {
      const snap = await provider.fetchSubscription(p.subscriptionId);
      await this.applySnapshot(snap, { refund: true });
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

  /** Mobile purchase or restore: verify with the store, then link to the workspace. */
  async verifyPurchase(
    orgId: string,
    source: "app_store" | "google_play",
    args: { productId: string; transactionId?: string; purchaseToken?: string },
  ) {
    const provider = this.provider(source);
    // A credit pack is a one-time purchase, not a subscription (D-244).
    const pack = (await this.packs()).find((p) => p.store_product_ids?.[source] === args.productId);
    if (pack) {
      if (!provider.verifyConsumable)
        throw new BillingError("unsupported", `${source} cannot verify purchases`, 400);
      const { purchaseId, revoked } = await provider.verifyConsumable(args);
      if (revoked) throw new BillingError("purchase_refunded", "This purchase was refunded", 409);
      const reference = `${source}:${purchaseId}`;
      // A purchase credits one workspace once, whichever workspace reports it first.
      const [other] = await this.db.execute<{ org_id: string }>(sql`
        select org_id from public.credit_ledger where reason = 'purchase' and reference = ${reference} limit 1`);
      if (other && other.org_id !== orgId)
        throw new BillingError("purchase_used", "This purchase was already used", 409);
      await this.credit(orgId, Number(pack.credits_usd), "purchase", reference, pack.name);
      return this.recompute(orgId);
    }
    if (!provider.verifyPurchase)
      throw new BillingError("unsupported", `${source} cannot verify purchases`, 400);
    const snap = await provider.verifyPurchase(args);
    return this.applySnapshot(snap, { orgId });
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

  /** Whether this is its owner's oldest workspace on the free plan (the one that gets free credits). */
  private async firstFreeWorkspace(orgId: string) {
    const [r] = await this.db.execute<{ first: boolean }>(sql`
      select not exists (
        select 1 from public.organizations o
        join public.organizations me on me.id = ${orgId}::uuid
        where o.created_by = me.created_by and o.id <> me.id and o.plan = 'free'
          and (o.created_at, o.id) < (me.created_at, me.id)
      ) as first`);
    return r?.first ?? true;
  }

  /** Picks the best entitled subscription (or the default plan) and writes the entitlement. */
  async recompute(orgId: string) {
    const [best] = await this.db.execute<{
      id: string;
      plan_code: string;
      source: string;
      status: SubscriptionStatus;
      current_period_end: Date | null;
    }>(sql`
      select s.id, s.plan_code, s.source, s.status, s.current_period_end
      from public.subscriptions s
      join public.plans p on p.code = s.plan_code
      where s.org_id = ${orgId}::uuid and s.status = any(${arr(ENTITLED)}::text[])
        and (s.current_period_end is null or s.current_period_end > now())
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
    const monthly = Number(
      (trial ? plan.limits.trial_credits_usd : plan.limits.monthly_credits_usd) ?? 0,
    );
    if (this.enabled && monthly > 0) {
      const ref = `monthly:${month()}:${planCode}${trial ? ":trial" : ""}`;
      const [done] = await this.db.execute<{ granted: string; this_plan: boolean }>(sql`
        select coalesce(sum(delta), 0)::text as granted, bool_or(reference = ${ref}) as this_plan
        from public.credit_ledger
        where org_id = ${orgId}::uuid and reason = 'grant' and reference like ${`monthly:${month()}:%`}`);
      if (!done?.this_plan) {
        let amount = Math.max(0, monthly - Number(done?.granted ?? 0));
        let note = trial ? `${plan.name} trial credits` : `${plan.name} monthly credits`;
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
      valid_until: Date | null;
      source: string;
    }>(sql`
      select e.plan_code, p.name, p.interval, e.limits, e.valid_until, e.source
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
        Object.entries(ent?.limits ?? {}).filter(([, v]) => typeof v === "number"),
      ) as Record<string, number>,
      unlimited: !this.enabled || ent?.limits?.unlimited === true,
      valid_until: ent?.valid_until ? new Date(ent.valid_until).toISOString() : null,
      source: (ent?.source ?? "default") as "default" | BillingSource,
      cancel_at_period_end: active?.cancel_at_period_end ?? false,
      extra_seats: active?.extra_seats ?? 0,
      trial_available: this.enabled ? await this.trialAvailable(orgId) : false,
      credits_usd: this.enabled ? await this.balance(orgId) : 0,
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
      providers: (Object.keys(this.providers) as BillingSource[]).sort(),
    };
  }

  /** The workspace's subscription that is paid up now, if any. */
  async activeSubscription(orgId: string) {
    const [s] = await this.db.execute<{
      external_id: string;
      source: BillingSource;
      plan_code: string;
      extra_seats: number | null;
    }>(sql`
      select external_id, source, plan_code, extra_seats from public.subscriptions
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
      ) as ok`);
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
                and c.reference = 'monthly:' || ${month()} || ':' || e.plan_code))
      limit 500`);
    for (const d of due) await this.recompute(d.org_id);
    // Included credits lapse after the following month; packs and rewards after 12 months (D-246).
    await this.db.execute(sql`select public.expire_credits()`);
    return { orgs: usd.size, usd: [...usd.values()].reduce((a, b) => a + b, 0) };
  }

  /** Writes computer-seconds for cloud computers that are still running (Cloud Connect). */
  async flushCloudComputers(ref?: string, stop = false) {
    const rate = this.opts.cloudComputerUsdPerHour ?? 0.05;
    const rows = await this.db.execute<{
      ref: string;
      org_id: string;
      instance_name: string;
      seconds: number;
    }>(sql`
      with c as (
        select ref, running_since from public.cloud_connect_computers
        where running_since is not null ${ref ? sql`and ref = ${ref}` : sql``}
        for update
      )
      update public.cloud_connect_computers cc
      set running_since = case when ${stop}::boolean then null else now() end
      from c where cc.ref = c.ref
      returning cc.ref, cc.org_id, cc.instance_name,
        greatest(0, round(extract(epoch from now() - c.running_since)))::int as seconds`);
    for (const r of rows) {
      if (r.seconds <= 0) continue;
      await this.db.execute(sql`
        insert into public.usage_ledger (org_id, kind, quantity, cost_usd, billable, meta)
        values (${r.org_id}::uuid, 'computer_seconds', ${r.seconds}, ${(r.seconds / 3600) * rate}, true,
          ${JSON.stringify({ source: "cloud_connect", instance: r.instance_name, ref: r.ref })}::jsonb)`);
    }
  }
}
