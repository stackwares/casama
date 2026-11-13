import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";

const ts = z.iso.datetime({ offset: true });

export const BotCheckins = z
  .object({
    enabled: z.boolean(),
    brief_time: z
      .string()
      .regex(/^([01]\d|2[0-3]):[0-5]\d$/)
      .openapi({ description: "Local time, HH:MM" }),
    scan_every_hours: z.number().int().min(1).max(24),
    daily_cap_usd: z.number().positive().max(100),
  })
  .openapi("BotCheckins");

export const Suggestion = z
  .object({
    id: Uuid,
    bot_id: Uuid,
    title: z.string(),
    body_md: z.string(),
    /** The bot's own line for it, as its push showed it ("Want me to…?"; D-247). */
    push_text: z.string().nullable().optional(),
    proposed_action: z
      .object({ tool: z.string(), args: z.record(z.string(), z.unknown()).optional() })
      .nullable(),
    sources: z.array(z.string()),
    urgency: z.enum(["low", "normal", "urgent"]),
    expires_at: ts,
    created_at: ts,
  })
  .openapi("Suggestion");

export const ForYouBrief = z
  .object({ bot_id: Uuid, conversation_id: Uuid, text: z.string(), created_at: ts })
  .openapi("ForYouBrief");

export const ForYouApproval = z
  .object({ id: Uuid, bot_id: Uuid, summary: z.string(), risk: z.string(), created_at: ts })
  .openapi("ForYouApproval");

export const ForYou = z
  .object({
    briefs: z.array(ForYouBrief),
    suggestions: z.array(Suggestion),
    approvals: z.array(ForYouApproval),
  })
  .openapi("ForYou");

export const DismissSuggestionRequest = z
  .object({ dont_suggest_again: z.boolean().default(false) })
  .openapi("DismissSuggestionRequest");

export const AcceptedSuggestion = z
  .object({ conversation_id: Uuid, run_id: Uuid })
  .openapi("AcceptedSuggestion");
