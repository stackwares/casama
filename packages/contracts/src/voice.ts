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
        "An answered phone call: the session uses its conversation and the bot speaks first",
    }),
  })
  .openapi("VoiceSessionRequest");

export const VoiceSession = z
  .object({
    provider: z.enum(["gemini", "openai"]).openapi({
      description:
        "gemini: Gemini Live over a WebSocket; openai: OpenAI Realtime over WebRTC. Gemini is used when the workspace has a Google AI key",
    }),
    model: z.string(),
    client_secret: z.string().openapi({
      description:
        "Short-lived credential: Gemini's single-use token (the access_token query parameter) or OpenAI's ephemeral key",
    }),
    expires_at: ts,
    connect_url: z.string().openapi({
      description:
        "gemini: open a WebSocket here with ?access_token=<client_secret>; openai: POST the WebRTC offer SDP here with the ephemeral key",
    }),
    setup: z.record(z.string(), z.unknown()).nullable().openapi({
      description:
        "gemini: send {setup: <this>} as the first message (add sessionResumption to reconnect); null for openai",
    }),
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
    provider: z
      .enum(["gemini", "openai"])
      .optional()
      .openapi({ description: "Which live-call provider the call used, for the usage estimate" }),
    usage: z
      .object({
        input_audio_tokens: z.number().int().min(0),
        input_text_tokens: z.number().int().min(0),
        output_audio_tokens: z.number().int().min(0),
        output_text_tokens: z.number().int().min(0),
      })
      .optional()
      .openapi({
        description:
          "Gemini Live: the call's token counts from usageMetadata, so usage records the real cost instead of a per-minute estimate",
      }),
  })
  .openapi("VoiceTranscriptRequest");
