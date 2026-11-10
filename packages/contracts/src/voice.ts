import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";

const ts = z.iso.datetime({ offset: true });

export const Transcription = z
  .object({ text: z.string(), provider: z.string(), seconds: z.number() })
  .openapi("Transcription");

export const VoiceSessionRequest = z
  .object({
    bot_id: Uuid,
    conversation_id: Uuid.optional(),
    call_id: Uuid.optional().openapi({
      description:
        "An answered phone call (D-135): the session uses its conversation and the bot speaks first",
    }),
  })
  .openapi("VoiceSessionRequest");

export const VoiceSession = z
  .object({
    provider: z.literal("openai"),
    model: z.string(),
    client_secret: z.string().openapi({ description: "Ephemeral key, valid for about 10 minutes" }),
    expires_at: ts,
    connect_url: z
      .string()
      .openapi({ description: "POST the WebRTC offer SDP here with the ephemeral key" }),
    conversation_id: Uuid,
    tools: z.number().int(),
    /** The bot opens the conversation (an answered phone call). */
    speak_first: z.boolean(),
  })
  .openapi("VoiceSession");

export const PhoneCall = z
  .object({
    id: Uuid,
    bot_id: Uuid,
    bot_name: z.string(),
    reason: z.string(),
    status: z.enum(["ringing", "answered", "declined", "missed", "cancelled"]),
    conversation_id: Uuid.nullable(),
    expires_at: ts,
    created_at: ts,
  })
  .openapi("PhoneCall");

export const VoiceToolRequest = z
  .object({
    bot_id: Uuid,
    conversation_id: Uuid,
    call_id: z.string().min(1).max(200),
    name: z.string().min(1).max(200),
    arguments: z.record(z.string(), z.unknown()).optional(),
  })
  .openapi("VoiceToolRequest");

export const VoiceToolResult = z
  .object({
    status: z.enum(["completed", "failed", "waiting_approval", "running"]),
    run_id: Uuid,
    output: z
      .string()
      .openapi({ description: "Give this to the realtime model as the function output" }),
    approval_id: Uuid.nullable(),
  })
  .openapi("VoiceToolResult");

export const VoiceTranscriptRequest = z
  .object({
    conversation_id: Uuid,
    turns: z
      .array(z.object({ role: z.enum(["user", "assistant"]), text: z.string().min(1).max(20_000) }))
      .max(500),
    seconds: z
      .number()
      .int()
      .min(0)
      .max(24 * 3600),
  })
  .openapi("VoiceTranscriptRequest");
