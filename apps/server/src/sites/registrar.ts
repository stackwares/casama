/**
 * The registrar behind domains bought through Casama (docs/SITES-AND-DOMAINS-PLAN.md §7.6). Every
 * domain sits in Casama's one reseller account with the person's own contact as registrant. The
 * first implementation is Name.com (`namecom.ts`); the interface keeps another a one-file switch.
 */
import type { DnsRecord, DomainContact } from "@casama/domain";

export interface AvailabilityResult {
  name: string;
  available: boolean;
  premium: boolean;
  /** What Casama pays, in USD; null when the registrar didn't say. */
  registerCostUsd: number | null;
  renewCostUsd: number | null;
}

export interface RegistrarDomain {
  expiresAt: Date;
  locked: boolean;
  autoRenew: boolean;
  privacy: boolean;
  nameservers: string[];
  contactVerified: boolean;
}

/** What a registrar's webhook says happened; the domain is always read again with `get`. */
export interface RegistrarEvent {
  id: string;
  kind: "contact_verified" | "expiry" | "lock" | "transfer_out" | "removed" | "balance" | "other";
  domain: string | null;
  raw: unknown;
}

export interface Registrar {
  readonly id: string;
  /** Up to 50 names in one call. */
  check(names: string[], purpose?: "search" | "order"): Promise<AvailabilityResult[]>;
  register(o: {
    name: string;
    contact: DomainContact;
    maxCostUsd: number;
    reference: string;
  }): Promise<{ expiresAt: Date }>;
  renew(o: { name: string; maxCostUsd: number; reference: string }): Promise<{ expiresAt: Date }>;
  /** What renewing this domain for a year costs Casama today, in USD (null: not said). */
  renewCost(name: string): Promise<number | null>;
  /** null when the domain isn't in the account any more. */
  get(name: string): Promise<RegistrarDomain | null>;
  setAutoRenew(name: string, on: boolean): Promise<void>;
  setLock(name: string, locked: boolean): Promise<void>;
  transferCode(name: string): Promise<string>;
  setContact(name: string, contact: DomainContact): Promise<void>;
  resendVerification(name: string): Promise<void>;
  records(name: string): Promise<DnsRecord[]>;
  putRecord(name: string, r: DnsRecord): Promise<DnsRecord>;
  deleteRecord(name: string, id: string): Promise<void>;
  /** Forwards the bare domain to a URL, or stops forwarding with null. */
  setForwarding(name: string, to: string | null): Promise<void>;
  /** null when the account pays by card and has no balance to watch. */
  balanceUsd(): Promise<number | null>;
  verifyWebhook(req: { headers: Headers; rawBody: string }): Promise<RegistrarEvent>;
}

export class RegistrarError extends Error {
  readonly status: number;
  readonly code: string;
  constructor(status: number, code: string, message: string) {
    super(message);
    this.name = "RegistrarError";
    this.status = status;
    this.code = code;
  }
  /** Worth trying again later: rate limits, the registrar's own failures, no answer. */
  get retryable() {
    return this.status === 429 || this.status >= 500;
  }
}

/**
 * The account-wide call budget (§7.6): Name.com allows 20 a second and 3,000 an hour. Search may
 * use at most 2,400 an hour, so registrations and renewals always have room.
 */
export class CallBudget {
  private readonly calls: number[] = [];
  private readonly searches: number[] = [];
  private last = 0;
  private readonly perHour: number;
  private readonly searchPerHour: number;
  private readonly minGapMs: number;
  constructor(perHour = 3000, searchPerHour = 2400, minGapMs = 50) {
    this.perHour = perHour;
    this.searchPerHour = searchPerHour;
    this.minGapMs = minGapMs;
  }

  private trim(list: number[], now: number) {
    while (list.length && now - (list[0] as number) > 3_600_000) list.shift();
  }

  /** Waits for a slot; throws when the hour's budget for this purpose is spent. */
  async take(purpose: "search" | "order" = "order") {
    const now = Date.now();
    this.trim(this.calls, now);
    this.trim(this.searches, now);
    if (this.calls.length >= this.perHour)
      throw new RegistrarError(429, "budget", "The registrar's hourly call limit is used up.");
    if (purpose === "search" && this.searches.length >= this.searchPerHour)
      throw new RegistrarError(429, "budget", "Domain search is busy. Try again in a few minutes.");
    const wait = this.last + this.minGapMs - now;
    if (wait > 0) await new Promise((r) => setTimeout(r, wait));
    this.last = Date.now();
    this.calls.push(this.last);
    if (purpose === "search") this.searches.push(this.last);
  }
}
