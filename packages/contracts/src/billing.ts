import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";
import { BillingComp } from "./comps.ts";
import { SavedLimitReset } from "./limit-resets.ts";

const ts = z.iso.datetime({ offset: true });
const Source = z.enum(["dodo", "app_store", "google_play"]).openapi("BillingSource");
const Limits = z.record(z.string(), z.number());

export const Plan = z
  .object({
    code: z.string(),
    name: z.string(),
    /** `week` plans are only listed for apps that ask for them (`?periods=week`, D-432). */
    interval: z.enum(["none", "week", "month", "year"]),
    limits: Limits,
    price_label: z.string().nullable(),
    /** Can be bought with web checkout (Dodo). */
    web: z.boolean(),
    store_product_ids: z.record(z.string(), z.string()),
    /** The plan the paywall opens on: its tier for a Free workspace, its period for everyone (D-332). */
    paywall_default: z.boolean().optional(),
    /** Marked "Most popular" on the paywall (D-332). */
    paywall_popular: z.boolean().optional(),
  })
  .openapi("Plan");

export const CreditPack = z
  .object({
    code: z.string(),
    name: z.string(),
    credits_usd: z.number(),
    web: z.boolean(),
    /** The web price (D-244); store prices come from the store and are higher. */
    price_label: z.string().nullable().optional(),
    store_product_ids: z.record(z.string(), z.string()).optional(),
  })
  .openapi("CreditPack");

export const PlanCatalog = z
  .object({
    enabled: z.boolean(),
    plans: z.array(Plan),
    packs: z.array(CreditPack),
  })
  .openapi("PlanCatalog");

export const Subscription = z
  .object({
    id: Uuid,
    source: Source,
    plan_code: z.string(),
    status: z.string(),
    current_period_end: ts.nullable(),
    cancel_at_period_end: z.boolean(),
  })
  .openapi("Subscription");

export const BillingSummary = z
  .object({
    enabled: z.boolean().openapi({ description: "False on self-hosted servers: no paywall" }),
    plan_code: z.string(),
    plan_name: z.string(),
    interval: z.string(),
    limits: Limits,
    unlimited: z.boolean(),
    valid_until: ts.nullable(),
    source: z.enum(["default", "dodo", "app_store", "google_play"]),
    cancel_at_period_end: z.boolean(),
    extra_seats: z
      .number()
      .int()
      .optional()
      .openapi({ description: "People paid for beyond the plan's seats (D-249)" }),
    trial_available: z
      .boolean()
      .optional()
      .openapi({ description: "The owner can still start a plan's free trial (D-249)" }),
    resets: z.array(SavedLimitReset).optional(),
    credits_usd: z.number(),
    daily: z
      .object({
        used_usd: z.number().openapi({ description: "Spent today (UTC) on the server's keys" }),
        cap_usd: z.number().openapi({ description: "The plan's daily cap on the server's keys" }),
        resets_at: ts.openapi({ description: "Next midnight UTC, when the day's spend resets" }),
      })
      .nullable()
      .optional()
      .openapi({
        description:
          "Today's spend against the plan's daily cap; runs stop when it is reached (D-311). Null when no cap applies",
      }),
    computer_hours: z
      .object({
        used_hours: z
          .number()
          .openapi({ description: "Hosted computer hours used this month (UTC)" }),
        limit_hours: z.number().openapi({ description: "The plan's computer hours a month" }),
        resets_at: ts.openapi({
          description: "The first of next month (UTC), when the hours reset",
        }),
      })
      .nullable()
      .optional()
      .openapi({
        description:
          "This month's hosted computer hours against the plan's. Past them only computers stop; chat keeps running on credits (D-442). Null when no limit applies",
      }),
    comp: BillingComp.nullable().optional().openapi({
      description:
        "A plan given free by Casama, while it runs (docs/COMP-PLANS-PLAN.md). `source` then says default, for older apps",
    }),
    subscriptions: z.array(Subscription),
    providers: z.array(Source),
  })
  .openapi("BillingSummary");

export const CheckoutRequest = z
  .object({
    plan_code: z.string().optional(),
    pack_code: z.string().optional(),
    return_url: z.url().optional(),
  })
  .refine((v) => !!v.plan_code !== !!v.pack_code, {
    message: "Give exactly one of plan_code or pack_code",
  })
  .openapi("CheckoutRequest");

export const SeatsRequest = z
  .object({
    extra: z
      .number()
      .int()
      .min(0)
      .max(100)
      .openapi({ description: "People to pay for beyond the plan's seats" }),
  })
  .openapi("SeatsRequest");

export const PortalRequest = z.object({ return_url: z.url().optional() }).openapi("PortalRequest");

export const RedirectUrl = z.object({ url: z.url() }).openapi("RedirectUrl");

/**
 * A checkout page, or `changed: true` when an existing web subscription was moved to the plan in
 * place (D-248); `url` is then the return page, so older apps that open it still land somewhere.
 */
export const CheckoutResult = z
  .object({ url: z.url(), changed: z.boolean().optional() })
  .openapi("CheckoutResult");

export const PurchaseRequest = z
  .object({
    source: z.enum(["app_store", "google_play"]),
    product_id: z.string().min(1),
    transaction_id: z.string().optional().openapi({ description: "App Store transaction id" }),
    purchase_token: z.string().optional().openapi({ description: "Google Play purchase token" }),
  })
  .openapi("PurchaseRequest");

export const BillingUsageItem = z
  .object({
    kind: z.string(),
    instance: z.string().nullable().openapi({ description: "Casama Link instance, if any" }),
    quantity: z.number(),
    cost_usd: z.number(),
  })
  .openapi("BillingUsageItem");

export const CreditEntry = z
  .object({
    delta: z.number(),
    reason: z.string(),
    note: z.string().nullable(),
    balance_after: z.number(),
    created_at: ts,
  })
  .openapi("CreditEntry");

export const BillingUsage = z
  .object({
    period_start: ts,
    items: z.array(BillingUsageItem),
    total_usd: z.number(),
    credits: z.array(CreditEntry),
  })
  .openapi("BillingUsage");

export const LinkKey = z
  .object({
    id: Uuid,
    instance_name: z.string(),
    key_hint: z.string(),
    scopes: z.array(z.string()),
    last_used_at: ts.nullable(),
    created_at: ts,
  })
  .openapi("LinkKey");

export const CreateLinkKeyRequest = z
  .object({
    instance_name: z.string().min(1).max(80),
    scopes: z
      .array(z.enum(["computers", "models", "remote_access", "push"]))
      .min(1)
      .optional(),
  })
  .openapi("CreateLinkKeyRequest");

export const CreatedLinkKey = LinkKey.extend({
  key: z.string().openapi({ description: "Shown once; set it as CASAMA_CLOUD_KEY" }),
}).openapi("CreatedLinkKey");
