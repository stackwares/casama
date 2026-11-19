import { createRoute, z } from "@hono/zod-openapi";
import { IdempotencyKeyHeader, jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";
import {
  WatchApproval,
  WatchAsk,
  WatchAsked,
  WatchChat,
  WatchCode,
  WatchCodeClaim,
  WatchCodeInfo,
  WatchCodeRequest,
  WatchHandoff,
  WatchKey,
  WatchKeyRegister,
  WatchPrefs,
  WatchPrefsUpdate,
  WatchRun,
  WatchSelf,
  WatchSelfUpdate,
} from "../watch.ts";

/**
 * Casama on the wrist (D-410, docs/WATCH-PLAN.md §8.2, §8.4).
 *
 * - The phone (the person's session) registers, lists and removes watches, sets their limits and
 *   allows a code a watch shows.
 * - A watch calls with `Authorization: Watch <key>`. Besides the routes here it may call only:
 *   `GET /v1/glance`, `POST /v1/approvals/{id}/decision` (its limits enforced by the server),
 *   `POST /v1/suggestions/{id}/accept|dismiss`, `POST /v1/routines/{id}/run`,
 *   `POST /v1/runs/{id}/cancel`, `POST /v1/voice/transcribe` and `GET /v1/messages/{id}/speech`.
 * - Asking for a code is the one route that works signed out.
 */
const security = [{ bearerAuth: [] }];
const { 400: e400, 401: e401, 403: e403, 404: e404, 409: e409, 429: e429 } = problemResponses;
const idParam = z.object({ id: Uuid });
const codeParam = z.object({ code: z.string().min(8).max(12) });
const ok = (name: string) => z.object({ ok: z.literal(true) }).openapi(name);

// --- the phone ------------------------------------------------------------------------------

export const listWatchKeys = createRoute({
  operationId: "listWatchKeys",
  method: "get",
  path: "/v1/watch-keys",
  tags: ["watch"],
  security,
  summary: "The person's signed-in watches in a workspace",
  request: { query: z.object({ org_id: Uuid }) },
  responses: {
    200: jsonResponse(
      "Most recently used first",
      z.object({ items: z.array(WatchKey) }).openapi("WatchKeyList"),
    ),
    401: e401,
    404: e404,
  },
});

export const registerWatchKey = createRoute({
  operationId: "registerWatchKey",
  method: "post",
  path: "/v1/watch-keys",
  tags: ["watch"],
  security,
  summary:
    "Sign a watch in from the phone: register the fingerprint of the key the watch made. Registering the same fingerprint again updates it",
  request: { body: jsonBody(WatchKeyRegister) },
  responses: {
    201: jsonResponse("Signed in", WatchKey),
    400: e400,
    401: e401,
    404: e404,
    409: e409,
  },
});

export const deleteWatchKey = createRoute({
  operationId: "deleteWatchKey",
  method: "delete",
  path: "/v1/watch-keys/{id}",
  tags: ["watch"],
  security,
  summary: "Remove a watch: its key stops working at once",
  request: { params: idParam },
  responses: {
    200: jsonResponse("Removed", z.object({ deleted: Uuid }).openapi("DeletedWatchKey")),
    401: e401,
    404: e404,
  },
});

export const getWatchPrefs = createRoute({
  operationId: "getWatchPrefs",
  method: "get",
  path: "/v1/watch-prefs",
  tags: ["watch"],
  security,
  summary: "The person's watch settings: what a watch may allow, details, quick replies",
  responses: { 200: jsonResponse("Settings", WatchPrefs), 401: e401 },
});

export const updateWatchPrefs = createRoute({
  operationId: "updateWatchPrefs",
  method: "patch",
  path: "/v1/watch-prefs",
  tags: ["watch"],
  security,
  summary: "Change the person's watch settings",
  request: { body: jsonBody(WatchPrefsUpdate) },
  responses: { 200: jsonResponse("Settings", WatchPrefs), 400: e400, 401: e401 },
});

export const getWatchCode = createRoute({
  operationId: "getWatchCode",
  method: "get",
  path: "/v1/watch-codes/{code}",
  tags: ["watch"],
  security,
  summary: "Which watch shows this code, before allowing it. Five wrong tries end a code",
  request: { params: codeParam },
  responses: {
    200: jsonResponse("The watch", WatchCodeInfo),
    401: e401,
    404: e404,
    429: e429,
  },
});

export const claimWatchCode = createRoute({
  operationId: "claimWatchCode",
  method: "post",
  path: "/v1/watch-codes/{code}/claim",
  tags: ["watch"],
  security,
  summary: "Allow the watch showing this code: it is signed in to this workspace as the caller",
  request: { params: codeParam, body: jsonBody(WatchCodeClaim) },
  responses: {
    201: jsonResponse("Signed in", WatchKey),
    400: e400,
    401: e401,
    404: e404,
    409: e409,
    429: e429,
  },
});

// --- signed out -----------------------------------------------------------------------------

export const requestWatchCode = createRoute({
  operationId: "requestWatchCode",
  method: "post",
  path: "/v1/watch/codes",
  tags: ["watch"],
  summary:
    "A watch with no phone app at hand asks for a code to show (signed out; five an hour per address). It then tries GET /v1/watch/me with its key until the code is allowed",
  request: { body: jsonBody(WatchCodeRequest) },
  responses: { 201: jsonResponse("The code", WatchCode), 400: e400, 429: e429 },
});

// --- the watch ------------------------------------------------------------------------------

export const getWatchSelf = createRoute({
  operationId: "getWatchSelf",
  method: "get",
  path: "/v1/watch/me",
  tags: ["watch"],
  security,
  summary: "Who this watch is signed in as, its settings and what the server can do for it",
  responses: { 200: jsonResponse("This watch", WatchSelf), 401: e401, 429: e429 },
});

export const updateWatchSelf = createRoute({
  operationId: "updateWatchSelf",
  method: "put",
  path: "/v1/watch-keys/current",
  tags: ["watch"],
  security,
  summary: "A watch describes itself: its push token, app and system versions",
  request: { body: jsonBody(WatchSelfUpdate) },
  responses: {
    200: jsonResponse("Saved", ok("WatchSelfSaved")),
    400: e400,
    401: e401,
    429: e429,
  },
});

export const signOutWatch = createRoute({
  operationId: "signOutWatch",
  method: "delete",
  path: "/v1/watch-keys/current",
  tags: ["watch"],
  security,
  summary: "Sign out of this watch: its key is deleted",
  responses: { 200: jsonResponse("Signed out", ok("WatchSignedOut")), 401: e401 },
});

export const getWatchChat = createRoute({
  operationId: "getWatchChat",
  method: "get",
  path: "/v1/watch/chats/{bot_id}",
  tags: ["watch"],
  security,
  summary:
    "A bot's latest chat as plain text, cut to fit a watch; cards, pages and files as one line",
  request: {
    params: z.object({ bot_id: Uuid }),
    query: z.object({
      conversation_id: Uuid.optional().openapi({ description: "Default: the latest direct chat" }),
    }),
  },
  responses: { 200: jsonResponse("The chat", WatchChat), 401: e401, 404: e404, 429: e429 },
});

export const watchAsk = createRoute({
  operationId: "watchAsk",
  method: "post",
  path: "/v1/watch/ask",
  tags: ["watch"],
  security,
  summary:
    "Ask a bot or reply in a chat, with text or a recording (transcribed and sent in one step). Without conversation_id it starts a new chat",
  request: { headers: IdempotencyKeyHeader, body: jsonBody(WatchAsk) },
  responses: {
    201: jsonResponse("Sent", WatchAsked),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
    409: e409,
    429: e429,
  },
});

// Declared before getWatchRun: a WatchRun's `approval` is nullable, and the OpenAPI generator
// must meet WatchApproval as itself first, whatever order a loader walks these exports in.
export const getWatchApproval = createRoute({
  operationId: "getWatchApproval",
  method: "get",
  path: "/v1/watch/approvals/{id}",
  tags: ["watch"],
  security,
  summary: "A request in everyday words, and whether this watch may allow it (tap, hold, phone)",
  request: { params: idParam },
  responses: { 200: jsonResponse("The request", WatchApproval), 401: e401, 404: e404, 429: e429 },
});

export const getWatchRun = createRoute({
  operationId: "getWatchRun",
  method: "get",
  path: "/v1/watch/runs/{id}",
  tags: ["watch"],
  security,
  summary:
    "A run's whole state. With `stream=1` (or `Accept: text/event-stream`): server-sent `run` events, each a whole WatchRun, ended by the server after 110 seconds or when the run ends; ask again to go on",
  request: {
    params: idParam,
    query: z.object({ stream: z.enum(["0", "1"]).optional() }),
  },
  responses: { 200: jsonResponse("The run", WatchRun), 401: e401, 404: e404, 429: e429 },
});

export const watchHandoff = createRoute({
  operationId: "watchHandoff",
  method: "post",
  path: "/v1/watch/handoff",
  tags: ["watch"],
  security,
  summary: "Open on iPhone / phone: the person's phones get a notification that opens the link",
  request: { body: jsonBody(WatchHandoff) },
  responses: {
    200: jsonResponse("Sent", z.object({ sent: z.number().int() }).openapi("WatchHandoffSent")),
    400: e400,
    401: e401,
    429: e429,
  },
});
