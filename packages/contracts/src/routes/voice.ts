import { createRoute, z } from "@hono/zod-openapi";
import { jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";
import {
  CallStepRequest,
  CallStepResult,
  PhoneCall,
  Transcription,
  VoiceHeartbeat,
  VoiceHeartbeatRequest,
  VoiceSession,
  VoiceSessionRequest,
  VoiceToolRequest,
  VoiceToolResult,
  VoiceTranscriptRequest,
  VoiceTurnsRequest,
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

export const saveVoiceTurns = createRoute({
  operationId: "saveVoiceTurns",
  method: "post",
  path: "/v1/voice/transcript/turns",
  tags: ["voice"],
  security,
  summary: "Save finished turns of a live call as they happen (idempotent by turn id)",
  request: { body: jsonBody(VoiceTurnsRequest) },
  responses: {
    200: jsonResponse("Saved", z.object({ saved: z.number().int() }).openapi("SavedTurns")),
    401: e401,
    404: e404,
  },
});

export const updateCallStep = createRoute({
  operationId: "updateCallStep",
  method: "post",
  path: "/v1/voice/live/{id}/steps/{step_id}",
  tags: ["voice"],
  security,
  summary: "Start a next step from a call's card as a chat run, or dismiss it",
  request: {
    params: z.object({ id: Uuid, step_id: z.string().min(1).max(20) }),
    body: jsonBody(CallStepRequest),
  },
  responses: { 200: jsonResponse("Step", CallStepResult), 401: e401, 404: e404, 409: e409 },
});

export const deleteLiveCall = createRoute({
  operationId: "deleteLiveCall",
  method: "delete",
  path: "/v1/voice/live/{id}",
  tags: ["voice"],
  security,
  summary: "Delete a call from its chat: its card and every turn of its transcript",
  request: { params: z.object({ id: Uuid }) },
  responses: {
    200: jsonResponse("Deleted", z.object({ deleted: z.number().int() }).openapi("DeletedCall")),
    401: e401,
    404: e404,
    409: e409,
  },
});

export const voiceHeartbeat = createRoute({
  operationId: "voiceHeartbeat",
  method: "post",
  path: "/v1/voice/live/{id}/heartbeat",
  tags: ["voice"],
  security,
  summary: "Keep a live call's server record open; calls silent for 2 minutes are ended and billed",
  request: { params: z.object({ id: Uuid }), body: jsonBody(VoiceHeartbeatRequest) },
  responses: { 200: jsonResponse("Call", VoiceHeartbeat), 401: e401, 404: e404 },
});

// Phone-call voice (D-135)
const callParam = z.object({ id: Uuid });
export const listRingingCalls = createRoute({
  operationId: "listRingingCalls",
  method: "get",
  path: "/v1/calls/ringing",
  tags: ["voice"],
  security: [{ bearerAuth: [] }],
  summary: "Calls ringing for you now (the in-app banner on desktop and web)",
  responses: {
    200: jsonResponse("Calls", z.object({ items: z.array(PhoneCall) }).openapi("PhoneCallList")),
    401: problemResponses[401],
  },
});
export const getVoiceCall = createRoute({
  operationId: "getVoiceCall",
  method: "get",
  path: "/v1/calls/{id}",
  tags: ["voice"],
  security: [{ bearerAuth: [] }],
  request: { params: callParam },
  responses: {
    200: jsonResponse("Call", PhoneCall),
    401: problemResponses[401],
    404: problemResponses[404],
  },
});
export const answerVoiceCall = createRoute({
  operationId: "answerVoiceCall",
  method: "post",
  path: "/v1/calls/{id}/answer",
  tags: ["voice"],
  security: [{ bearerAuth: [] }],
  summary: "Answer a call; then start a voice session with its call_id",
  request: { params: callParam },
  responses: {
    200: jsonResponse("Call", PhoneCall),
    401: problemResponses[401],
    404: problemResponses[404],
    409: problemResponses[409],
  },
});
export const declineVoiceCall = createRoute({
  operationId: "declineVoiceCall",
  method: "post",
  path: "/v1/calls/{id}/decline",
  tags: ["voice"],
  security: [{ bearerAuth: [] }],
  summary: "Decline a call; the reason arrives as a normal notification",
  request: { params: callParam },
  responses: {
    200: jsonResponse("Call", PhoneCall),
    401: problemResponses[401],
    404: problemResponses[404],
  },
});
