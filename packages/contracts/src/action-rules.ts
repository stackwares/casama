import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";

export const ActionCategory = z
  .enum(["send", "pay", "delete", "publish", "share", "sign_in"])
  .openapi("ActionCategory");

export const ActionRuleTarget = z
  .object({
    domains: z.array(z.string().min(3).max(253)).max(20).optional(),
    recipients: z.array(z.email()).max(50).optional(),
    max_amount: z.number().nonnegative().optional(),
  })
  .openapi("ActionRuleTarget");

export const ActionRuleOut = z
  .object({
    id: Uuid,
    org_id: Uuid,
    bot_id: Uuid.nullable(),
    match_kind: z.enum(["tool", "group", "category"]),
    match_value: z.string(),
    target: ActionRuleTarget.nullable(),
    rule: z.enum(["allow", "allow_within_limits", "ask", "hand_off"]),
    preview: z
      .string()
      .openapi({
        description: "In plain language, e.g. Sends messages to anyone at acme.com without asking",
      }),
    created_at: z.iso.datetime({ offset: true }),
  })
  .openapi("ActionRule");

export const CreateActionRuleRequest = z
  .object({
    org_id: Uuid,
    bot_id: Uuid.nullable()
      .optional()
      .openapi({ description: "Null or missing: the whole workspace (admins)" }),
    match_kind: z.enum(["tool", "group", "category"]),
    match_value: z.string().min(1).max(200),
    target: ActionRuleTarget.nullable().optional(),
    rule: z.enum(["allow", "allow_within_limits", "ask", "hand_off"]),
  })
  .openapi("CreateActionRuleRequest");
