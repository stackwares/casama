/**
 * Billing service (D-070): webhook processing, purchase verification, entitlements and credits.
 * Entitlements are computed here and are the only thing quotas and paywalls read. A purchase
 * belongs to the workspace, so buying on one platform unlocks every platform.
 */
import { randomUUID } from "node:crypto";
import type { Database } from "@casama/db";
import { sql } from "drizzle-orm";
import {
  BillingError,
  type BillingProvider,
  type BillingSource,
  ENTITLED,
  type SubscriptionSnapshot,
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
      sql`select code, name, interval, limits, dodo_product_id, store_product_ids, sort from public.plans where active order by sort`,
    );
  }

  async packs() {
    return this.db.execute<{
      code: string;
      name: string;
      credits_usd: string;
      dodo_product_id: string | null;
      store_product_ids: Record<string, string>;
    }>(
      sql`select code, name, credits_usd, dodo_product_id, store_product_ids from public.credit_packs where active order by credits_usd`,
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

  /** Stores the provider's view of a subscription and recomputes the workspace's entitlement. */
  async applySnapshot(snap: SubscriptionSnapshot, opts: { orgId?: string; refund?: boolean } = {}) {
    const [existing] = await this.db.execute<{ org_id: string }>(sql`
      select org_id from public.subscriptions where source = ${snap.source} and external_id = ${snap.externalId}`);
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
        current_period_end, cancel_at_period_end, raw)
      values (${orgId}::uuid, ${snap.source}, ${snap.externalId}, ${snap.customerId ?? null}, ${plan.code},
        ${status}, ${snap.currentPeriodEnd?.toISOString() ?? null}::timestamptz, ${snap.cancelAtPeriodEnd},
        ${JSON.stringify(snap.raw ?? {})}::jsonb)
      on conflict (source, external_id) do update set
        plan_code = excluded.plan_code,
        -- A refund is final even if a later re-fetch still reports the old state.
        status = case when public.subscriptions.status = 'refunded' then 'refunded' else excluded.status end,
        current_period_end = excluded.current_period_end,
        cancel_at_period_end = excluded.cancel_at_period_end,
        customer_id = coalesce(excluded.customer_id, public.subscriptions.customer_id),
        raw = excluded.raw,
        updated_at = now()`);
    return this.recompute(orgId);
  }

  private async applyPayment(provider: BillingProvider, paymentId: string) {
    if (!provider.fetchPayment) return;
    const p = await provider.fetchPayment(paymentId);
    if (p.status && p.status !== "succeeded") return;
    const credits = await this.packCredits(p.productIds);
    if (credits <= 0) return; // subscription payments are handled by subscription events
    if (!p.orgId) throw new BillingError("unknown_org", "Payment has no workspace", 400);
    await this.credit(p.orgId, credits, "purchase", `dodo:${paymentId}`, "Credit pack");
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

  /** Picks the best entitled subscription (or the default plan) and writes the entitlement. */
  async recompute(orgId: string) {
    const [best] = await this.db.execute<{
      id: string;
      plan_code: string;
      source: string;
      current_period_end: Date | null;
    }>(sql`
      select s.id, s.plan_code, s.source, s.current_period_end from public.subscriptions s
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
    const limits = { ...plan.limits, ...(current?.overrides ?? {}) };
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
    // Included credits, once per month per plan.
    const monthly = Number(plan.limits.monthly_credits_usd ?? 0);
    if (this.enabled && monthly > 0)
      await this.credit(
        orgId,
        monthly,
        "grant",
        `monthly:${month()}:${planCode}`,
        `${plan.name} monthly credits`,
      );
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
    }>(sql`
      select id, source, plan_code, status, current_period_end, cancel_at_period_end
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
    } else if (what.packCode) {
      productId = (await this.packs()).find((p) => p.code === what.packCode)?.dodo_product_id;
    }
    if (!productId)
      throw new BillingError("unknown_product", "That item is not for sale on the web", 400);
    const [sub] = await this.db.execute<{ customer_id: string | null }>(sql`
      select customer_id from public.subscriptions where org_id = ${orgId}::uuid and source = 'dodo' and customer_id is not null
      order by updated_at desc limit 1`);
    return (dodo.createCheckout as NonNullable<BillingProvider["createCheckout"]>)({
      productId,
      orgId,
      email,
      customerId: sub?.customer_id ?? null,
      returnUrl,
    });
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
  async settle() {
    if (!this.enabled) return { orgs: 0, usd: 0 };
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
      for (const [org, cost] of byOrg)
        if (cost > 0)
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
         or ((p.limits->>'monthly_credits_usd')::numeric > 0 and not exists (
              select 1 from public.credit_ledger c where c.org_id = e.org_id and c.reason = 'grant'
                and c.reference = 'monthly:' || ${month()} || ':' || e.plan_code))
      limit 500`);
    for (const d of due) await this.recompute(d.org_id);
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
