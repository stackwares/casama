import { createRoute, z } from "@hono/zod-openapi";
import { jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";
import {
  Transcription,
  VoiceSession,
  VoiceSessionRequest,
  VoiceToolRequest,
  VoiceToolResult,
  VoiceTranscriptRequest,
} from "../voice.ts";

const security = [{ bearerAuth: [] }];
const { 400: e400, 401: e401, 404: e404, 409: e409 } = problemResponses;

export const transcribeAudio = createRoute({
  operationId: "transcribeAudio",
  method: "post",
  path: "/v1/voice/transcribe",
  tags: ["voice"],
  security,
  summary: "Dictation: send recorded audio (raw body, audio/* content type, up to 10 MB)",
  request: { query: z.object({ bot_id: Uuid, language: z.string().max(10).optional() }) },
  responses: {
    200: jsonResponse("Text", Transcription),
    400: e400,
    401: e401,
    404: e404,
    409: e409,
  },
});

export const messageSpeech = createRoute({
  operationId: "messageSpeech",
  method: "get",
  path: "/v1/messages/{id}/speech",
  tags: ["voice"],
  security,
  summary: "Read aloud: MP3 audio of an assistant message (cached per voice)",
  request: { params: z.object({ id: Uuid }) },
  responses: {
    200: {
      description: "MP3 audio",
      content: { "audio/mpeg": { schema: z.string().openapi({ format: "binary" }) } },
    },
    401: e401,
    404: e404,
    409: e409,
  },
});

export const createVoiceSession = createRoute({
  operationId: "createVoiceSession",
  method: "post",
  path: "/v1/voice/session",
  tags: ["voice"],
  security,
  summary: "Start a live call: mints an ephemeral realtime key with the bot's persona and tools",
  request: { body: jsonBody(VoiceSessionRequest) },
  responses: { 200: jsonResponse("Session", VoiceSession), 401: e401, 404: e404, 409: e409 },
});

export const voiceTool = createRoute({
  operationId: "voiceTool",
  method: "post",
  path: "/v1/voice/tool",
  tags: ["voice"],
  security,
  summary: "Run a tool call from a live call as an agent run (same approvals); waits up to 25 s",
  request: { body: jsonBody(VoiceToolRequest) },
  responses: { 200: jsonResponse("Result", VoiceToolResult), 401: e401, 404: e404 },
});

export const saveVoiceTranscript = createRoute({
  operationId: "saveVoiceTranscript",
  method: "post",
  path: "/v1/voice/transcript",
  tags: ["voice"],
  security,
  summary: "Save a call's transcript to the conversation and record its duration",
  request: { body: jsonBody(VoiceTranscriptRequest) },
  responses: {
    200: jsonResponse("Saved", z.object({ saved: z.number().int() }).openapi("SavedCount")),
    401: e401,
    404: e404,
  },
});
