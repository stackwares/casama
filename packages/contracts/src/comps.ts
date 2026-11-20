import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";

/** Free plans for friends (docs/COMP-PLANS-PLAN.md). */
const timestamp = z.iso.datetime({ offset: true });
const planCode = z.string().trim().min(1).max(80);
const note = z.string().trim().max(200).nullable().optional();

export const CompSettings = z
  .object({
    enabled: z.boolean(),
    grant_plans: z.array(planCode).max(20).openapi({
      description: "Plans an instance owner may give directly (monthly paid plans only)",
    }),
    code_plans: z.array(planCode).max(20).openapi({
      description: "Plans a gift code may carry (monthly paid plans only)",
    }),
    max_months: z.number().int().min(1).max(36),
    max_active: z.number().int().min(1).max(100000),
  })
  .openapi("CompSettings");

export const Comp = z
  .object({
    id: Uuid,
    org_id: Uuid,
    org_name: z.string().nullable(),
    user_id: Uuid.nullable(),
    email: z.string().nullable().openapi({ description: "Masked, like fr••••@example.com" }),
    plan_code: z.string(),
    months: z.number().int(),
    starts_at: timestamp,
    ends_at: timestamp,
    from: z.enum(["grant", "code"]),
    code_id: Uuid.nullable(),
    note: z.string().nullable(),
    ended_at: timestamp.nullable(),
    // A plain string: a reason added later must not break older clients' parse.
    end_reason: z.string().nullable().openapi({
      description: "expired, revoked or replaced_by_purchase; null while it runs",
    }),
    created_at: timestamp,
  })
  .openapi("Comp");

export const GrantCompRequest = z
  .object({
    email: z.email().max(320).optional(),
    user_id: Uuid.optional(),
    org_id: Uuid.optional().openapi({
      description: "The workspace; default: the oldest one the person owns",
    }),
    plan_code: planCode,
    months: z.number().int().min(1).max(36),
    note,
  })
  .refine((v) => !!v.email !== !!v.user_id, { message: "Give exactly one of email or user_id" })
  .openapi("GrantCompRequest");

export const UpdateCompRequest = z
  .object({
    extend_months: z.number().int().min(1).max(36).optional(),
    revoke: z.literal(true).optional(),
  })
  .refine((v) => !!v.extend_months !== !!v.revoke, {
    message: "Give exactly one of extend_months or revoke",
  })
  .openapi("UpdateCompRequest");

export const CompCode = z
  .object({
    id: Uuid,
    hint: z.string().openapi({ description: "The code's last characters, like …7KQ2" }),
    plan_code: z.string(),
    months: z.number().int(),
    max_redemptions: z.number().int(),
    redeemed_count: z.number().int(),
    redeem_by: timestamp.nullable(),
    note: z.string().nullable(),
    disabled: z.boolean(),
    created_at: timestamp,
  })
  .openapi("CompCode");

export const CreatedCompCode = CompCode.safeExtend({
  code: z.string().openapi({ description: "The code, shown only now: G-XXXXX-XXXXX" }),
  link: z.string().openapi({ description: "casama.ai/g/<code>" }),
}).openapi("CreatedCompCode");

export const CreateCompCodeRequest = z
  .object({
    plan_code: planCode,
    months: z.number().int().min(1).max(36),
    max_redemptions: z.number().int().min(1).max(10000).default(1),
    redeem_by: timestamp.nullable().optional(),
    note,
  })
  .openapi("CreateCompCodeRequest");

export const UpdateCompCodeRequest = z
  .object({
    disabled: z.boolean().optional(),
    redeem_by: timestamp.nullable().optional(),
    max_redemptions: z.number().int().min(1).max(10000).optional(),
  })
  .openapi("UpdateCompCodeRequest");

export const CompCodePreview = z
  .object({
    plan_code: z.string(),
    plan_name: z.string(),
    months: z.number().int(),
  })
  .openapi("CompCodePreview");

export const RedeemCompRequest = z
  .object({
    code: z.string().trim().min(1).max(200),
    org_id: Uuid,
  })
  .openapi("RedeemCompRequest");

export const RedeemedComp = z
  .object({
    plan_code: z.string(),
    plan_name: z.string(),
    ends_at: timestamp,
    org_id: Uuid,
  })
  .openapi("RedeemedComp");

/** What the billing summary says about a running comp. */
export const BillingComp = z
  .object({
    plan_code: z.string(),
    ends_at: timestamp,
    from: z.enum(["grant", "code"]),
    keep_from: timestamp.openapi({
      description: "From this moment the comped plan can be bought to keep it",
    }),
  })
  .openapi("BillingComp");
