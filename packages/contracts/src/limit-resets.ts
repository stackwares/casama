import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";

const timestamp = z.iso.datetime({ offset: true });
const money = z.number().nonnegative().max(1_000_000);
const total = z.number().nonnegative();
export const LimitResetAudience = z
  .object({
    plan_codes: z.array(z.string().min(1).max(80)).max(100).default([]),
    created_before: timestamp.nullable().default(null),
    limited_within_days: z.number().int().min(1).max(365).nullable().default(null),
    workspace_ids: z.array(Uuid).max(10000).default([]),
  })
  .openapi("LimitResetAudience");
export const LimitResetSettings = z
  .object({
    enabled: z.boolean(),
    per_period: z.number().int().min(1).max(100),
    max_held: z.number().int().min(1).max(100),
    notify_owners: z.boolean(),
  })
  .openapi("LimitResetSettings");
export const LimitResetCampaignInput = z
  .object({
    name: z.string().trim().min(1).max(120),
    message: z
      .string()
      .trim()
      .min(1)
      .max(120)
      .regex(/^[^\r\n]*$/),
    audience: LimitResetAudience,
    starts_at: timestamp,
    expires_at: timestamp,
    refill_percent: z.number().int().min(10).max(100).default(100),
    reset_daily: z.boolean().default(true),
    reset_computer: z.boolean().default(false),
    max_per_use_usd: money.nullable().default(null),
    budget_usd: money.nullable().default(null),
    notify_arrival: z.boolean().default(true),
    notify_reminder: z.boolean().default(true),
  })
  .refine((v) => Date.parse(v.expires_at) > Date.parse(v.starts_at), {
    message: "Expiry must be after the start",
    path: ["expires_at"],
  })
  .openapi("LimitResetCampaignInput");
export const LimitResetCampaign = LimitResetCampaignInput.safeExtend({
  id: Uuid,
  state: z.string(),
  created_by: Uuid,
  created_at: timestamp,
  given: z.number().int().nonnegative(),
  used: z.number().int().nonnegative(),
  expired: z.number().int().nonnegative(),
  refilled_usd: total,
}).openapi("LimitResetCampaign");
export const SavedLimitReset = z
  .object({
    id: Uuid,
    campaign_id: Uuid.nullable(),
    message: z.string(),
    expires_at: timestamp,
    refill_usd: money,
    reset_daily: z.boolean(),
    reset_computer: z.boolean(),
    can_use: z.boolean(),
    // A plain string, not an enum: a reason added later must not break older apps' parse.
    unavailable_reason: z.string().nullable().openapi({
      description:
        "Why it can't be used now: owner_required, paused, period_limit, budget, nothing_to_refill or no_billing_period; null when it can",
    }),
  })
  .openapi("SavedLimitReset");
export const LimitResetPreview = z
  .object({
    workspaces: z.number().int().nonnegative(),
    by_plan: z.record(z.string(), z.number().int().nonnegative()),
    credits_usd: total,
    cost_usd: total,
  })
  .openapi("LimitResetPreview");
export const LimitResetEvent = z
  .object({
    id: Uuid,
    campaign_id: Uuid.nullable(),
    reset_id: Uuid.nullable(),
    org_id: Uuid.nullable(),
    actor_id: Uuid.nullable(),
    action: z.string(),
    before: z.record(z.string(), z.unknown()).nullable(),
    after: z.record(z.string(), z.unknown()).nullable(),
    created_at: timestamp,
  })
  .openapi("LimitResetEvent");
