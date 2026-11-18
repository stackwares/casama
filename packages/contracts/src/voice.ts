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
    provider: z.enum(["gemini"]).openapi({
      description: "Gemini Live over a WebSocket, the only live-call provider (D-260)",
    }),
    model: z.string(),
    client_secret: z.string().openapi({
      description: "Gemini's single-use token (the access_token query parameter)",
    }),
    expires_at: ts,
    connect_url: z.string().openapi({
      description: "Open a WebSocket here with ?access_token=<client_secret>",
    }),
    setup: z.record(z.string(), z.unknown()).nullable().openapi({
      description: "Send {setup: <this>} as the first message (add sessionResumption to reconnect)",
    }),
    conversation_id: Uuid,
    tools: z.number().int(),
    /** The bot opens the conversation: it greets the person, or says why it phoned (D-234). */
    speak_first: z.boolean(),
    live_call_id: Uuid.openapi({
      description:
        "The server's record of this call (D-327): send turns, heartbeats and the final transcript with it",
    }),
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
    live_call_id: Uuid.optional().openapi({
      description: "The call this tool runs on (D-327): stop_task stops the jobs started on it",
    }),
  })
  .openapi("VoiceToolRequest");

export const VoiceToolResult = z
  .object({
    status: z.enum(["completed", "failed", "waiting_approval", "running"]),
    run_id: Uuid.openapi({
      description:
        "The tool's run; for stop_task, the run it stopped. All zeros when the tool started no run",
    }),
    output: z
      .string()
      .openapi({ description: "Give this to the realtime model as the function output" }),
    approval_id: Uuid.nullable(),
  })
  .openapi("VoiceToolResult");

const CallTurnRole = z.enum(["user", "assistant"]);
const CallTurnId = z.string().min(1).max(100).openapi({
  description: "The app's id for the turn; a turn sent twice with the same id is saved once",
});

const GeminiUsage = z.object({
  input_audio_tokens: z.number().int().min(0),
  input_text_tokens: z.number().int().min(0),
  output_audio_tokens: z.number().int().min(0),
  output_text_tokens: z.number().int().min(0),
});

export const VoiceTranscriptRequest = z
  .object({
    conversation_id: Uuid,
    live_call_id: Uuid.optional().openapi({
      description:
        "The call (D-327): ends its server record. Turns already sent with /v1/voice/transcript/turns aren't sent again",
    }),
    turns: z
      .array(
        z.object({
          role: CallTurnRole,
          text: z.string().min(1).max(20_000),
          id: CallTurnId.optional(),
        }),
      )
      .max(500),
    seconds: z
      .number()
      .int()
      .min(0)
      .max(24 * 3600),
    provider: z.enum(["gemini", "openai"]).optional().openapi({
      description:
        "Which live-call provider the call used. Every call is Gemini Live now (D-260); openai is still accepted from older apps.",
    }),
    usage: GeminiUsage.optional().openapi({
      description:
        "Gemini Live: the call's token counts from usageMetadata, so usage records the real cost instead of a per-minute estimate",
    }),
  })
  .openapi("VoiceTranscriptRequest");

/** Turns saved while the call goes on (D-327), so a call that dies keeps its transcript. */
export const VoiceTurnsRequest = z
  .object({
    live_call_id: Uuid,
    turns: z
      .array(z.object({ id: CallTurnId, role: CallTurnRole, text: z.string().min(1).max(20_000) }))
      .min(1)
      .max(100),
  })
  .openapi("VoiceTurnsRequest");

/** Every 30 seconds while a call is live (D-327); a call with no heartbeat for 2 minutes is ended by the server. */
export const VoiceHeartbeatRequest = z
  .object({
    usage: GeminiUsage.optional().openapi({
      description: "Gemini Live's token counts so far, billed if the call ends without the app",
    }),
  })
  .openapi("VoiceHeartbeatRequest");

export const VoiceHeartbeat = z
  .object({
    ended: z.boolean().openapi({
      description:
        "The server already ended this call (no heartbeat in time); the app should hang up",
    }),
  })
  .openapi("VoiceHeartbeat");
