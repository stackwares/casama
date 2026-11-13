/**
 * One interface for every payment source (D-070): Dodo Payments on web and desktop, the App Store
 * on iOS and Google Play on Android. The server never trusts a webhook body: it verifies the
 * signature, stores the event once, then re-fetches the subscription from the provider.
 */

export type BillingSource = "dodo" | "app_store" | "google_play";

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

/** A one-time purchase (credit pack). */
export interface OneTimePurchase {
  source: BillingSource;
  externalId: string;
  productId: string;
  orgId?: string | null;
  customerId?: string | null;
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
  | { kind: "refund"; paymentId: string; refundId: string }
  /** A store credit pack was refunded; `references` are the credit_ledger references it may be under. */
  | { kind: "pack_refund"; references: string[] }
  | { kind: "ignored" }
);

export interface BillingProvider {
  readonly id: BillingSource;
  /** Throws BillingError when the signature or token is wrong. */
  verifyWebhook(req: WebhookRequest): Promise<void>;
  parseEvent(req: WebhookRequest): Promise<ParsedEvent>;
  /** Re-fetches a subscription by its external id. */
  fetchSubscription(externalId: string): Promise<SubscriptionSnapshot>;
  /** Mobile: checks a purchase the app reports (transaction id or purchase token). */
  verifyPurchase?(args: {
    productId: string;
    transactionId?: string;
    purchaseToken?: string;
  }): Promise<SubscriptionSnapshot>;
  /**
   * Mobile: checks a one-time purchase (a credit pack) and marks it used, so it can be bought
   * again. Returns the store's id for that purchase, which credits are keyed by (D-244).
   */
  verifyConsumable?(args: {
    productId: string;
    transactionId?: string;
    purchaseToken?: string;
  }): Promise<{ purchaseId: string; revoked: boolean }>;
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
