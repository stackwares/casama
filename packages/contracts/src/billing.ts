import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";

const ts = z.iso.datetime({ offset: true });
const Source = z.enum(["dodo", "app_store", "google_play"]).openapi("BillingSource");
const Limits = z.record(z.string(), z.number());

export const Plan = z
  .object({
    code: z.string(),
    name: z.string(),
    interval: z.enum(["none", "month", "year"]),
    limits: Limits,
    price_label: z.string().nullable(),
    /** Can be bought with web checkout (Dodo). */
    web: z.boolean(),
    store_product_ids: z.record(z.string(), z.string()),
  })
  .openapi("Plan");

export const CreditPack = z
  .object({
    code: z.string(),
    name: z.string(),
    credits_usd: z.number(),
    web: z.boolean(),
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
    credits_usd: z.number(),
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

export const PortalRequest = z.object({ return_url: z.url().optional() }).openapi("PortalRequest");

export const RedirectUrl = z.object({ url: z.url() }).openapi("RedirectUrl");

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
    instance: z.string().nullable().openapi({ description: "Cloud Connect instance, if any" }),
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

export const ConnectKey = z
  .object({
    id: Uuid,
    instance_name: z.string(),
    key_hint: z.string(),
    scopes: z.array(z.string()),
    last_used_at: ts.nullable(),
    created_at: ts,
  })
  .openapi("ConnectKey");

export const CreateConnectKeyRequest = z
  .object({
    instance_name: z.string().min(1).max(80),
    scopes: z
      .array(z.enum(["computers", "models"]))
      .min(1)
      .optional(),
  })
  .openapi("CreateConnectKeyRequest");

export const CreatedConnectKey = ConnectKey.extend({
  key: z.string().openapi({ description: "Shown once; set it as CASAMA_CLOUD_KEY" }),
}).openapi("CreatedConnectKey");
