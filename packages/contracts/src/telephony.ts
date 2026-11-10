import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";

const ts = z.iso.datetime({ offset: true });
const e164 = z.string().regex(/^\+[1-9][0-9]{7,14}$/);

export const TelephonySettings = z
  .object({
    connected: z.boolean(),
    account_sid: z.string().nullable(),
    from_number: z.string().nullable(),
    allow_personal_numbers: z.boolean(),
    daily_cap: z.number().int(),
  })
  .openapi("TelephonySettings");

export const SetTelephonyRequest = z
  .object({
    account_sid: z.string().regex(/^AC[0-9a-fA-F]{32}$/),
    /** Leave out to keep the saved token. */
    auth_token: z.string().min(16).max(200).optional(),
    from_number: e164,
    allow_personal_numbers: z.boolean().optional(),
    daily_cap: z.number().int().min(0).max(500).optional(),
  })
  .openapi("SetTelephonyRequest");

export const OutboundCall = z
  .object({
    id: Uuid,
    bot_id: Uuid,
    number: z.string(),
    purpose: z.string(),
    status: z.enum(["queued", "ringing", "in_progress", "completed", "failed", "busy", "no_answer", "ended_by_user", "taken_over"]),
    transcript: z.array(z.object({ role: z.enum(["bot", "callee"]), text: z.string() })),
    seconds: z.number().int().nullable(),
    started_at: ts.nullable(),
    ended_at: ts.nullable(),
    created_at: ts,
  })
  .openapi("OutboundCall");

export const TakeOverCallRequest = z.object({ phone: e164.optional() }).openapi("TakeOverCallRequest");
