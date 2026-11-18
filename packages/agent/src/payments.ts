/**
 * Payments (SPEC: Payments; D-142). A `PaymentProvider` issues single-use virtual cards; the first
 * adapter is Stripe Issuing (the workspace's own issuing account), from Stripe's public API docs.
 *
 * `payments.request(merchant, amount, currency, reason)` always asks first, with the amount shown;
 * no autonomy setting, grant or rule skips that. The card is limited to that amount plus 5%, blocks
 * banned merchant categories, is approved at authorization only for the named merchant, and is
 * cancelled after one use or after an hour. Its details reach checkout only through
 * {{card:<request>:field}} placeholders in tools that accept secrets; the model never sees them.
 */
import type { Database } from "@casama/db";
import { sql } from "drizzle-orm";
import { z } from "zod";
import { actingUserOf } from "./acting.ts";
import { withTimeout } from "./safe-fetch.ts";
import { ToolError, type ToolRegistry } from "./tools/registry.ts";

/** Allowed over the approved amount (taxes, rounding). */
export const PAYMENT_TOLERANCE = 0.05;
export const CARD_TTL_MS = 60 * 60_000;

/** Merchant categories cards never work at: securities, crypto and quasi-cash, gift and stored-value cards, transfers, cash. */
export const BLOCKED_CATEGORIES = [
  "security_brokers_dealers",
  "non_fi_money_orders",
  "non_fi_stored_value_card_purchase_load",
  "wires_money_orders",
  "financial_institutions",
  "automated_cash_disburse",
  "manual_cash_disburse",
  "betting_casino_gambling",
];

const BANNED_TEXT =
  /\b(stocks?|shares|securities|brokerage|options? trading|forex|crypto(currency)?|bitcoin|btc|ethereum|eth|usdt|stablecoin|coinbase|binance|kraken|gift ?cards?|prepaid cards?|top[- ]?up card|money transfer|wire transfer|bank transfer|send money|venmo|zelle|cash ?app|paypal\.me|western union|moneygram|remitly)\b/i;

/** Why a purchase is banned outright (no rule can relax these), or null. */
export function bannedPurchase(merchant: string, reason: string): string | null {
  const t = `${merchant} ${reason}`;
  if (BANNED_TEXT.test(t))
    return "Bots can't pay for securities, crypto or gift cards, move money between accounts, or pay individuals.";
  return null;
}

export interface IssuedCard {
  id: string;
  last4: string;
}
export interface CardDetails {
  number: string;
  cvc: string;
  exp_month: number;
  exp_year: number;
  name: string;
}

export interface PaymentProvider {
  readonly name: string;
  issueCard(o: {
    amountCents: number;
    currency: string;
    merchant: string;
    requestId: string;
  }): Promise<IssuedCard>;
  cardDetails(cardId: string): Promise<CardDetails>;
  cancelCard(cardId: string): Promise<void>;
}

/** Stripe Issuing (REST, form-encoded, Bearer secret key). */
export class StripeIssuingProvider implements PaymentProvider {
  readonly name = "stripe";
  private readonly o: { key: string; cardholder: string; api: string; fetch: typeof fetch };
  constructor(o: {
    secretKey: string;
    cardholderId: string;
    apiUrl?: string;
    fetch?: typeof fetch;
  }) {
    this.o = {
      key: o.secretKey,
      cardholder: o.cardholderId,
      api: (o.apiUrl ?? "https://api.stripe.com").replace(/\/$/, ""),
      fetch: withTimeout(o.fetch ?? fetch, 30_000),
    };
  }
  private async req<T>(method: string, path: string, params?: Array<[string, string]>) {
    const res = await this.o.fetch(`${this.o.api}${path}`, {
      method,
      headers: {
        authorization: `Bearer ${this.o.key}`,
        "content-type": "application/x-www-form-urlencoded",
      },
      body: params ? new URLSearchParams(params).toString() : undefined,
    });
    const text = await res.text();
    if (!res.ok) {
      let msg = text.slice(0, 200);
      try {
        msg = (JSON.parse(text) as { error?: { message?: string } }).error?.message ?? msg;
      } catch {}
      throw new Error(`Stripe: ${msg}`);
    }
    return JSON.parse(text) as T;
  }
  /** Creates the cardholder cards are issued to (once, from settings). */
  static async createCardholder(
    o: { secretKey: string; apiUrl?: string; fetch?: typeof fetch },
    c: {
      name: string;
      email: string;
      line1: string;
      city: string;
      state?: string;
      postal_code: string;
      country: string;
    },
  ) {
    const p = new StripeIssuingProvider({
      secretKey: o.secretKey,
      cardholderId: "",
      apiUrl: o.apiUrl,
      fetch: o.fetch,
    });
    return p.req<{ id: string }>("POST", "/v1/issuing/cardholders", [
      ["type", "individual"],
      ["name", c.name],
      ["email", c.email],
      ["status", "active"],
      ["billing[address][line1]", c.line1],
      ["billing[address][city]", c.city],
      ...(c.state ? ([["billing[address][state]", c.state]] as Array<[string, string]>) : []),
      ["billing[address][postal_code]", c.postal_code],
      ["billing[address][country]", c.country],
    ]);
  }
  async issueCard(o: {
    amountCents: number;
    currency: string;
    merchant: string;
    requestId: string;
  }) {
    const limit = Math.ceil(o.amountCents * (1 + PAYMENT_TOLERANCE));
    const r = await this.req<{ id: string; last4: string }>("POST", "/v1/issuing/cards", [
      ["cardholder", this.o.cardholder],
      ["currency", o.currency.toLowerCase()],
      ["type", "virtual"],
      ["status", "active"],
      ["spending_controls[spending_limits][0][amount]", String(limit)],
      ["spending_controls[spending_limits][0][interval]", "all_time"],
      ...BLOCKED_CATEGORIES.map(
        (c, i) => [`spending_controls[blocked_categories][${i}]`, c] as [string, string],
      ),
      ["metadata[casama_request]", o.requestId],
      ["metadata[merchant]", o.merchant.slice(0, 200)],
    ]);
    return { id: r.id, last4: r.last4 };
  }
  async cardDetails(cardId: string) {
    const r = await this.req<{
      number: string;
      cvc: string;
      exp_month: number;
      exp_year: number;
      cardholder?: { name?: string };
    }>(
      "GET",
      `/v1/issuing/cards/${encodeURIComponent(cardId)}?expand[]=number&expand[]=cvc&expand[]=cardholder`,
    );
    return {
      number: r.number,
      cvc: r.cvc,
      exp_month: r.exp_month,
      exp_year: r.exp_year,
      name: r.cardholder?.name ?? "",
    };
  }
  async cancelCard(cardId: string) {
    await this.req("POST", `/v1/issuing/cards/${encodeURIComponent(cardId)}`, [
      ["status", "canceled"],
    ]);
  }
}

/** Stripe's zero-decimal currencies: amounts are whole units (¥500 is 500, not 50000). */
const ZERO_DECIMAL = new Set([
  "BIF",
  "CLP",
  "DJF",
  "GNF",
  "JPY",
  "KMF",
  "KRW",
  "MGA",
  "PYG",
  "RWF",
  "UGX",
  "VND",
  "VUV",
  "XAF",
  "XOF",
  "XPF",
]);
/** Stripe's three-decimal currencies: amounts are thousandths. */
const THREE_DECIMAL = new Set(["BHD", "JOD", "KWD", "OMR", "TND"]);

/** How many minor units make one unit of `currency`, as Stripe counts them. */
export function minorUnitsPerUnit(currency: string) {
  const c = currency.toUpperCase();
  return ZERO_DECIMAL.has(c) ? 1 : THREE_DECIMAL.has(c) ? 1000 : 100;
}

/**
 * An amount in `currency` as Stripe's minor units (the `amount` Stripe sends and takes). Stripe
 * only accepts three-decimal amounts rounded to tens, so those round to the nearest 0.01.
 */
export function toMinorUnits(amount: number, currency: string) {
  const per = minorUnitsPerUnit(currency);
  return per === 1000 ? Math.round(amount * 100) * 10 : Math.round(amount * per);
}

export const fromMinorUnits = (minor: number, currency: string) =>
  minor / minorUnitsPerUnit(currency);

/** Minor units (as Stripe counts them) of `currency`, formatted for people. */
export const formatMoney = (minor: number, currency: string) =>
  new Intl.NumberFormat("en-US", { style: "currency", currency: currency.toUpperCase() }).format(
    fromMinorUnits(minor, currency),
  );

/** The currency the monthly caps (monthly_cap_usd, payments_monthly_cap_usd) are counted in. */
export const CAP_CURRENCY = "USD";

/** Loose merchant match for authorizations: a distinctive word of the approved merchant appears in the descriptor. */
export function merchantMatches(approved: string, descriptor: string) {
  const norm = (s: string) => s.toLowerCase().replace(/[^a-z0-9 ]+/g, " ");
  const d = norm(descriptor);
  const words = norm(approved)
    .split(/\s+/)
    .filter(
      (w) =>
        w.length >= 3 &&
        !["the", "inc", "llc", "ltd", "com", "www", "and", "shop", "store"].includes(w),
    );
  return words.length === 0 ? false : words.some((w) => d.includes(w));
}

export interface PaymentDeps {
  db: Database;
  providerFor: (orgId: string) => Promise<{
    provider: PaymentProvider;
    monthlyCapUsd: number;
    botMonthlyCapUsd: number;
  } | null>;
}

const CARD = /\{\{card:([0-9a-f-]{36}):(number|cvc|exp_month|exp_year|exp|name)\}\}/g;
export const hasCardPlaceholders = (v: unknown) => JSON.stringify(v ?? null).includes("{{card:");

/** Fills {{card:<request>:field}} for this run's issued, unexpired cards; values go to `onValue` for redaction. */
export async function resolveCardPlaceholders<T>(
  deps: PaymentDeps,
  run: { orgId: string; runId: string },
  value: T,
  opts: { onValue?: (v: string, label: string) => void } = {},
): Promise<T> {
  const ids = [...new Set([...JSON.stringify(value).matchAll(CARD)].map((m) => m[1] as string))];
  if (!ids.length) return value;
  const p = await deps.providerFor(run.orgId);
  if (!p) throw new ToolError("no_payments", "Payments aren't set up for this workspace.");
  const details = new Map<string, CardDetails>();
  for (const id of ids) {
    const [r] = await deps.db.execute<{
      provider_card_id: string | null;
      status: string;
      expired: boolean;
    }>(sql`
      select provider_card_id, status, expires_at < now() as expired from public.payment_requests
      where id = ${id}::uuid and org_id = ${run.orgId}::uuid and run_id = ${run.runId}::uuid`);
    if (!r?.provider_card_id)
      throw new ToolError("card_not_found", "That card isn't one this task was given.");
    if (r.status !== "issued" || r.expired)
      throw new ToolError(
        "card_unusable",
        `That card was ${r.expired ? "expired" : r.status}; request a new one.`,
      );
    details.set(id, await p.provider.cardDetails(r.provider_card_id));
  }
  const replace = (s: string) =>
    s.replace(CARD, (_m, id: string, field: string) => {
      const d = details.get(id) as CardDetails;
      const v =
        field === "exp"
          ? `${String(d.exp_month).padStart(2, "0")}/${String(d.exp_year).slice(-2)}`
          : field === "exp_month"
            ? String(d.exp_month).padStart(2, "0")
            : field === "exp_year"
              ? String(d.exp_year)
              : String(d[field as "number" | "cvc" | "name"]);
      opts.onValue?.(v, `card:${field}`);
      return v;
    });
  const walk = (v: unknown): unknown =>
    typeof v === "string"
      ? replace(v)
      : Array.isArray(v)
        ? v.map(walk)
        : v && typeof v === "object"
          ? Object.fromEntries(Object.entries(v).map(([k, x]) => [k, walk(x)]))
          : v;
  return walk(value) as T;
}

/** Cards past their hour are cancelled (every minute, from the worker). */
export async function expireCards(deps: PaymentDeps) {
  const due = await deps.db.execute<{ id: string; org_id: string; provider_card_id: string }>(sql`
    select id, org_id, provider_card_id from public.payment_requests where status = 'issued' and expires_at < now() limit 100`);
  for (const r of due) {
    const p = await deps.providerFor(r.org_id).catch(() => null);
    await p?.provider.cancelCard(r.provider_card_id).catch(() => {});
    await deps.db.execute(
      sql`update public.payment_requests set status = 'expired' where id = ${r.id}::uuid and status = 'issued'`,
    );
  }
  return due.length;
}

export function registerPaymentTools(registry: ToolRegistry, deps: PaymentDeps) {
  const { db } = deps;
  registry.register({
    name: "payments.request",
    description:
      "Get a single-use virtual card to pay a merchant for the person (checkout on a website). Give the merchant, the exact amount in US dollars (currency USD; cards are only issued in USD), and why. The person always approves the amount first. The card works once, for that merchant and amount (plus a little for tax), for one hour. Fill checkout with the placeholders this returns; you never see the card details. Never for securities, crypto, gift cards, transfers or paying individuals.",
    risk: "high",
    alwaysAsk: true,
    askEvenWithFullAccess: true,
    category: "send",
    schema: z.object({
      merchant: z.string().min(2).max(200),
      amount: z.number().positive().max(100_000),
      // The monthly caps are in dollars, so cards are too (execute checks again).
      currency: z
        .string()
        .regex(/^[A-Za-z]{3}$/)
        .refine((c) => c.toUpperCase() === CAP_CURRENCY, {
          message: "Cards are only issued in US dollars (USD).",
        }),
      reason: z.string().min(1).max(500),
    }),
    async approvalDetails(args) {
      return {
        amount: formatMoney(toMinorUnits(args.amount, args.currency), args.currency),
        price: formatMoney(toMinorUnits(args.amount, args.currency), args.currency),
        merchant: args.merchant,
      };
    },
    async execute(args, ctx) {
      const banned = bannedPurchase(args.merchant, args.reason);
      if (banned) throw new ToolError("payment_banned", banned);
      const currency = args.currency.toUpperCase();
      // The monthly caps are in dollars and other currencies can't be added to them (no exchange
      // rate here), so a card in another currency would get past them: refuse it instead.
      if (currency !== CAP_CURRENCY)
        throw new ToolError(
          "payment_currency",
          "Cards are only issued in US dollars, the currency of the monthly limits. Ask for the amount in USD.",
        );
      const p = await deps.providerFor(ctx.orgId);
      if (!p)
        throw new ToolError(
          "no_payments",
          "Payments aren't set up. An owner connects a card issuing account in workspace settings → Payments.",
        );
      const user = await actingUserOf(db, ctx.runId);
      if (!user) throw new ToolError("no_person", "There's nobody to pay for.");
      // Minor units of the currency, as Stripe counts them (cents for USD).
      const cents = toMinorUnits(args.amount, currency);
      // Monthly caps, counted on approved amounts in this calendar month (UTC), in dollars only.
      const [spent] = await db.execute<{ org: string; bot: string; bot_cap: string | null }>(sql`
        select coalesce(sum(amount_cents) filter (where true), 0)::text as org,
               coalesce(sum(amount_cents) filter (where bot_id = ${ctx.botId}::uuid), 0)::text as bot,
               (select payments_monthly_cap_usd::text from public.bots where id = ${ctx.botId}::uuid) as bot_cap
        from public.payment_requests where org_id = ${ctx.orgId}::uuid and status in ('issued', 'used') and currency = ${CAP_CURRENCY}
          and created_at >= date_trunc('month', now())`);
      const botCap =
        spent?.bot_cap !== null && spent?.bot_cap !== undefined
          ? Number(spent.bot_cap)
          : p.botMonthlyCapUsd;
      if (Number(spent?.org ?? 0) + cents > toMinorUnits(p.monthlyCapUsd, CAP_CURRENCY))
        throw new ToolError(
          "payment_cap",
          `This would go over the workspace's monthly limit of ${formatMoney(toMinorUnits(p.monthlyCapUsd, CAP_CURRENCY), CAP_CURRENCY)}.`,
        );
      if (Number(spent?.bot ?? 0) + cents > toMinorUnits(botCap, CAP_CURRENCY))
        throw new ToolError(
          "payment_cap",
          `This would go over this bot's monthly limit of ${formatMoney(toMinorUnits(botCap, CAP_CURRENCY), CAP_CURRENCY)}.`,
        );
      const [row] = await db.execute<{ id: string }>(sql`
        insert into public.payment_requests (org_id, bot_id, run_id, user_id, merchant, amount_cents, currency, reason, expires_at)
        values (${ctx.orgId}::uuid, ${ctx.botId}::uuid, ${ctx.runId}::uuid, ${user}::uuid, ${args.merchant}, ${cents}, ${currency}, ${args.reason},
                now() + make_interval(secs => ${CARD_TTL_MS / 1000}))
        returning id`);
      const id = row?.id as string;
      try {
        const card = await p.provider.issueCard({
          amountCents: cents,
          currency,
          merchant: args.merchant,
          requestId: id,
        });
        await db.execute(
          sql`update public.payment_requests set status = 'issued', provider_card_id = ${card.id}, last4 = ${card.last4} where id = ${id}::uuid`,
        );
      } catch (e) {
        await db.execute(
          sql`update public.payment_requests set status = 'failed', error = ${(e as Error).message.slice(0, 500)} where id = ${id}::uuid`,
        );
        throw new ToolError("card_failed", `The card couldn't be issued: ${(e as Error).message}`);
      }
      const f = (field: string) => `{{card:${id}:${field}}}`;
      return {
        content: [
          `A single-use card is ready for ${args.merchant}: up to ${formatMoney(Math.ceil(cents * (1 + PAYMENT_TOLERANCE)), currency)}, valid for one hour, one purchase.`,
          `Fill checkout with these placeholders (browser and computer tools fill them in; you never see the numbers): number ${f("number")}, expiry ${f("exp")} (or month ${f("exp_month")} and year ${f("exp_year")}), security code ${f("cvc")}, name on card ${f("name")}.`,
          "If checkout asks for a billing address, use the person's details from memory or ask them.",
        ].join("\n"),
        preview: `${formatMoney(cents, currency)} at ${args.merchant}`,
      };
    },
  });
}
