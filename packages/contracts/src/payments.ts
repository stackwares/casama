import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";

const ts = z.iso.datetime({ offset: true });

export const PaymentSettings = z
  .object({
    connected: z.boolean(),
    provider: z.enum(["stripe"]).nullable(),
    monthly_cap_usd: z.number(),
    bot_monthly_cap_usd: z.number(),
    spent_this_month_usd: z.number(),
    webhook_url: z.string().nullable(),
  })
  .openapi("PaymentSettings");

export const SetPaymentSettingsRequest = z
  .object({
    /** The workspace's own Stripe secret key with Issuing (stored in Vault). */
    secret_key: z.string().min(10).max(300),
    /** The signing secret of the Stripe webhook pointed at webhook_url (issuing_authorization.request and .created). */
    webhook_secret: z.string().min(10).max(300),
    cardholder: z.object({
      name: z.string().min(1).max(100),
      email: z.email(),
      line1: z.string().min(1).max(200),
      city: z.string().min(1).max(100),
      state: z.string().max(100).optional(),
      postal_code: z.string().min(1).max(20),
      country: z.string().length(2),
    }),
    monthly_cap_usd: z.number().min(0).max(100_000).optional(),
    bot_monthly_cap_usd: z.number().min(0).max(100_000).optional(),
  })
  .openapi("SetPaymentSettingsRequest");

export const PaymentRequest = z
  .object({
    id: Uuid,
    bot_id: Uuid,
    merchant: z.string(),
    amount_cents: z.number().int(),
    currency: z.string(),
    reason: z.string(),
    status: z.enum(["requested", "issued", "used", "declined", "expired", "failed", "canceled"]),
    last4: z.string().nullable(),
    spent_cents: z.number().int().nullable(),
    expires_at: ts,
    created_at: ts,
  })
  .openapi("PaymentRequest");
