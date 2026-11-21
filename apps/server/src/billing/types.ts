/**
 * One interface for every payment provider (D-070): Dodo Payments on web and desktop, and
 * RevenueCat for the App Store and Google Play (D-297). The server never trusts a webhook body: it
 * verifies the signature, stores the event once, then re-fetches the state from the provider.
 */

/** Where a subscription was bought, which is where it is changed or cancelled. */
export type BillingSource = "dodo" | "app_store" | "google_play";

/** Who the server talks to: Dodo for web checkout, RevenueCat for both app stores. */
export type ProviderId = "dodo" | "revenuecat";

export type SubscriptionStatus =
  | "active"
  | "trialing"
  | "grace"
  | "past_due"
  | "on_hold"
  | "paused"
  | "cancelled"
  | "expired"
  | "refunded"
  | "pending";

/** Statuses that grant the plan (until current_period_end, when set). */
export const ENTITLED: SubscriptionStatus[] = ["active", "trialing", "grace", "past_due"];

/** The provider's current view of one subscription. */
export interface SubscriptionSnapshot {
  source: BillingSource;
  externalId: string;
  /** Store product id (Google: `productId:basePlanId`). */
  productId: string;
  status: SubscriptionStatus;
  currentPeriodEnd: Date | null;
  cancelAtPeriodEnd: boolean;
  customerId?: string | null;
  /** The workspace the purchase was made for (checkout metadata, appAccountToken, obfuscated id). */
  orgId?: string | null;
  /** People bought on top of the plan's seats (a Dodo add-on, D-249). */
  extraSeats?: number;
  raw: unknown;
}

/** A one-time store purchase (a credit pack, D-244) as RevenueCat reports it. */
export interface StorePurchase {
  source: "app_store" | "google_play";
  /** RevenueCat's purchase id; credits are keyed by it. */
  id: string;
  /** Store product id. */
  productId: string;
  status: "owned" | "refunded";
  /** Bought with a store sandbox account (TestFlight, App Review, Play license testers). */
  sandbox?: boolean;
}

/** What one app-store customer (a workspace) bought. */
export interface StoreCustomer {
  subscriptions: SubscriptionSnapshot[];
  purchases: StorePurchase[];
}

export interface WebhookRequest {
  headers: Headers;
  rawBody: string;
  url: string;
}

/** What a verified webhook tells us to look at; details are always re-fetched. */
export type ParsedEvent = {
  eventId: string;
  type: string;
  payload: unknown;
} & (
  | { kind: "subscription"; externalId: string; refund?: boolean; revoke?: boolean }
  | { kind: "payment"; paymentId: string }
  | {
      kind: "refund";
      paymentId: string;
      refundId: string;
      /** A lost dispute (chargeback): always takes the period back. */
      dispute?: boolean;
      /** The provider says this refund is for part of the payment. */
      partial?: boolean;
    }
  /**
   * Something changed for these app-store customers (RevenueCat app user ids, which are workspace
   * ids): the server re-reads everything they bought. `refundStoreIds` are store transaction ids a
   * refund was reported for, since a subscription's state alone doesn't say it was refunded.
   */
  | { kind: "customers"; customerIds: string[]; refundStoreIds: string[] }
  | { kind: "ignored" }
);

export interface BillingProvider {
  readonly id: ProviderId;
  /** Throws BillingError when the signature or token is wrong. */
  verifyWebhook(req: WebhookRequest): Promise<void>;
  parseEvent(req: WebhookRequest): Promise<ParsedEvent>;
  /** Re-fetches a subscription by its external id. */
  fetchSubscription(externalId: string): Promise<SubscriptionSnapshot>;
  /** App stores (RevenueCat): every subscription and one-time purchase of one customer. */
  storeCustomer?(customerId: string): Promise<StoreCustomer>;
  /** App stores (RevenueCat): the subscription a store transaction id belongs to, if any. */
  findSubscription?(storeId: string): Promise<string | null>;
  createCheckout?(args: {
    productId: string;
    orgId: string;
    email?: string | null;
    customerId?: string | null;
    returnUrl: string;
    /** A free trial on this checkout only (D-249). */
    trialDays?: number;
  }): Promise<{ url: string; sessionId: string }>;
  /** Dodo: sets how many extra people a subscription pays for (an add-on, prorated; D-249). */
  setAddon?(args: {
    subscriptionId: string;
    productId: string;
    addonId: string;
    quantity: number;
  }): Promise<void>;
  customerPortal?(args: { customerId: string; returnUrl: string }): Promise<{ url: string }>;
  /** Dodo: moves an existing subscription to another product, prorated (D-248). */
  changePlan?(subscriptionId: string, productId: string): Promise<void>;
  /** Dodo: a payment and what it bought (credit packs, refunds). */
  fetchPayment?(paymentId: string): Promise<{
    paymentId: string;
    subscriptionId: string | null;
    customerId: string | null;
    orgId: string | null;
    productIds: string[];
    status: string | null;
    /** In minor units; null when the provider didn't say. */
    totalAmount?: number | null;
    /** Succeeded refunds so far, in minor units; null when the provider didn't say. */
    refundedAmount?: number | null;
    createdAt?: Date | null;
  }>;
  /** Metered plans: usage events (Dodo usage-based billing). */
  reportUsage?(
    events: Array<{
      eventId: string;
      customerId: string;
      name: string;
      timestamp: Date;
      metadata: Record<string, string | number>;
    }>,
  ): Promise<void>;
}

export class BillingError extends Error {
  readonly code: string;
  readonly status: number;
  constructor(code: string, message: string, status = 400) {
    super(message);
    this.code = code;
    this.status = status;
  }
}

/** fetch that turns provider errors into BillingError. */
export async function providerJson<T>(
  provider: string,
  res: Response | Promise<Response>,
): Promise<T> {
  let r: Response;
  try {
    r = await res;
  } catch (err) {
    throw new BillingError(
      "provider_unreachable",
      `${provider} could not be reached: ${(err as Error).message}`,
      502,
    );
  }
  if (r.status === 404) throw new BillingError("not_found", `${provider}: not found`, 404);
  if (!r.ok) {
    const text = await r.text().catch(() => "");
    throw new BillingError(
      "provider_error",
      `${provider} returned ${r.status}${text ? `: ${text.slice(0, 200)}` : ""}`,
      502,
    );
  }
  const text = await r.text();
  return (text ? JSON.parse(text) : {}) as T;
}
