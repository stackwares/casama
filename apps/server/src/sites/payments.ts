/**
 * Domain payments (docs/SITES-AND-DOMAINS-PLAN.md §2.4, §7.7), kept apart from plan billing so
 * another provider (Stripe, if Dodo says no) is one file. Dodo: a Pay What You Want product for a
 * price that changes per order, and an on-demand subscription (a "mandate") per workspace that
 * renewals and later purchases are charged on.
 */
import { BillingError, providerJson } from "../billing/types.ts";
import type { Env } from "../env.ts";

export interface DomainPayment {
  paymentId: string;
  status: string | null;
  /**
   * What the order costs in US dollars, before tax: null when the payment wasn't in dollars and
   * no dollar settlement amount is known (the order is then refunded as a mismatch).
   */
  amountUsd: number | null;
  /** The currency the customer paid in (ISO 4217, upper case), when the provider says. */
  currency: string | null;
  orderId: string | null;
  orgId: string | null;
  /** The mandate the payment was charged on, or the one its checkout made. */
  subscriptionId: string | null;
}

export interface DomainPayments {
  /** The products whose payments and subscriptions are domain ones, not plans. */
  owns(productId: string): boolean;
  /**
   * A browser checkout for exactly `priceUsd`. With `mandate`, the checkout also keeps an
   * on-demand subscription for later charges.
   */
  checkout(o: {
    orderId: string;
    orgId: string;
    name: string;
    priceUsd: number;
    mandate: boolean;
    email?: string | null;
    returnUrl: string;
  }): Promise<{ url: string; sessionId: string }>;
  /** Charges a saved mandate; the result arrives as a payment webhook. */
  charge(o: {
    mandateRef: string;
    orderId: string;
    orgId: string;
    priceUsd: number;
  }): Promise<{ paymentId: string }>;
  payment(paymentId: string): Promise<DomainPayment>;
  /** Whether a mandate can still be charged (not cancelled or failed). */
  mandateActive(mandateRef: string): Promise<boolean>;
  refund(paymentId: string, reason: string): Promise<{ refundId: string }>;
}

const cents = (usd: number) => Math.round(usd * 100);

export interface DodoDomainOptions {
  apiKey: string;
  environment?: "test" | "live";
  baseUrl?: string;
  /** The "Domain" Pay What You Want product. */
  productId: string;
  /** The "Domains renewal" on-demand subscription product. */
  renewalProductId?: string;
  fetch?: typeof fetch;
}

/**
 * The order's price in dollars, before tax (prices are set before tax, so compare without it).
 * Dollars in cents only: a payment in another currency (adaptive pricing) uses Dodo's dollar
 * settlement amount when it has one, and is otherwise unknown, never its local number read as
 * cents. A payment that names no currency is unknown too.
 */
function dodoAmountUsd(
  p: {
    total_amount?: number | null;
    tax?: number | null;
    settlement_amount?: number | null;
    settlement_tax?: number | null;
    settlement_currency?: string | null;
  },
  currency: string | null,
): number | null {
  if (currency === "USD" && typeof p.total_amount === "number")
    return (p.total_amount - (p.tax ?? 0)) / 100;
  if (p.settlement_currency?.toUpperCase() === "USD" && typeof p.settlement_amount === "number")
    return (p.settlement_amount - (p.settlement_tax ?? 0)) / 100;
  return null;
}

export class DodoDomainPayments implements DomainPayments {
  private readonly base: string;
  private readonly o: DodoDomainOptions;
  constructor(o: DodoDomainOptions) {
    this.o = o;
    this.base = (
      o.baseUrl ??
      (o.environment === "live" ? "https://live.dodopayments.com" : "https://test.dodopayments.com")
    ).replace(/\/$/, "");
  }

  private call<T>(path: string, init: RequestInit = {}) {
    return providerJson<T>(
      "Dodo Payments",
      (this.o.fetch ?? fetch)(`${this.base}${path}`, {
        ...init,
        headers: {
          authorization: `Bearer ${this.o.apiKey}`,
          "content-type": "application/json",
        },
        signal: AbortSignal.timeout(15_000),
      }),
    );
  }

  owns(productId: string) {
    return productId === this.o.productId || productId === this.o.renewalProductId;
  }

  async checkout(o: Parameters<DomainPayments["checkout"]>[0]) {
    const metadata = { org_id: o.orgId, domain_order_id: o.orderId, domain: o.name };
    const mandate = o.mandate && this.o.renewalProductId;
    const body = mandate
      ? {
          // An on-demand subscription: charges the price now and keeps the mandate (§2.4).
          product_cart: [{ product_id: this.o.renewalProductId, quantity: 1 }],
          subscription_data: {
            on_demand: { mandate_only: false, product_price: cents(o.priceUsd) },
          },
        }
      : {
          product_cart: [{ product_id: this.o.productId, quantity: 1, amount: cents(o.priceUsd) }],
        };
    const r = await this.call<{ session_id: string; checkout_url: string | null }>("/checkouts", {
      method: "POST",
      body: JSON.stringify({
        ...body,
        customer: o.email ? { email: o.email } : undefined,
        return_url: o.returnUrl,
        metadata,
      }),
    });
    if (!r.checkout_url)
      throw new BillingError("provider_error", "Dodo returned no checkout URL", 502);
    return { url: r.checkout_url, sessionId: r.session_id };
  }

  async charge(o: Parameters<DomainPayments["charge"]>[0]) {
    const r = await this.call<{ payment_id: string }>(
      `/subscriptions/${encodeURIComponent(o.mandateRef)}/charge`,
      {
        method: "POST",
        body: JSON.stringify({
          product_price: cents(o.priceUsd),
          metadata: { org_id: o.orgId, domain_order_id: o.orderId },
        }),
      },
    );
    return { paymentId: r.payment_id };
  }

  async payment(paymentId: string): Promise<DomainPayment> {
    const p = await this.call<{
      payment_id: string;
      subscription_id?: string | null;
      metadata?: Record<string, unknown>;
      status?: string | null;
      total_amount?: number | null;
      /** Tax Dodo added on top, as merchant of record (minor units of `currency`). */
      tax?: number | null;
      currency?: string | null;
      /** The same payment in the merchant's settlement currency (adaptive pricing). */
      settlement_amount?: number | null;
      settlement_tax?: number | null;
      settlement_currency?: string | null;
    }>(`/payments/${encodeURIComponent(paymentId)}`);
    const meta = p.metadata ?? {};
    const currency = p.currency ? p.currency.toUpperCase() : null;
    return {
      paymentId: p.payment_id,
      status: p.status ?? null,
      amountUsd: dodoAmountUsd(p, currency),
      currency,
      orderId: typeof meta.domain_order_id === "string" ? meta.domain_order_id : null,
      orgId: typeof meta.org_id === "string" ? meta.org_id : null,
      subscriptionId: p.subscription_id ?? null,
    };
  }

  async mandateActive(mandateRef: string) {
    try {
      const s = await this.call<{ status: string }>(
        `/subscriptions/${encodeURIComponent(mandateRef)}`,
      );
      return s.status === "active";
    } catch (e) {
      if (e instanceof BillingError && e.status === 404) return false;
      throw e;
    }
  }

  async refund(paymentId: string, reason: string) {
    const r = await this.call<{ refund_id: string }>("/refunds", {
      method: "POST",
      body: JSON.stringify({ payment_id: paymentId, reason: reason.slice(0, 200) }),
    });
    return { refundId: r.refund_id };
  }
}

export function domainPaymentsFromEnv(env: Env): DomainPayments | null {
  if (!env.BILLING_ENABLED || !env.DODO_API_KEY || !env.DODO_DOMAIN_PRODUCT_ID) return null;
  return new DodoDomainPayments({
    apiKey: env.DODO_API_KEY,
    environment: env.DODO_ENVIRONMENT,
    baseUrl: env.DODO_API_URL,
    productId: env.DODO_DOMAIN_PRODUCT_ID,
    renewalProductId: env.DODO_DOMAIN_RENEWAL_PRODUCT_ID,
  });
}
