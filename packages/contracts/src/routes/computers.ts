import { createRoute, z } from "@hono/zod-openapi";
import { IdempotencyKeyHeader, jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";
import {
  Checkpoint,
  Computer,
  ComputerFileEntry,
  CreateCheckpointRequest,
  CreateComputerRequest,
  Lease,
  ReleaseLeaseRequest,
  StreamSession,
  StreamSessionRequest,
  TakeLeaseRequest,
  TakeoverRequest,
  UpdateComputerRequest,
} from "../computers.ts";

const security = [{ bearerAuth: [] }];
const { 400: e400, 401: e401, 403: e403, 404: e404, 409: e409 } = problemResponses;
const idParam = z.object({ id: Uuid });
const pathQuery = z.object({ path: z.string().max(4000).optional() });

export const listComputers = createRoute({
  operationId: "listComputers",
  method: "get",
  path: "/v1/computers",
  tags: ["computers"],
  security,
  request: { query: z.object({ org_id: Uuid }) },
  responses: {
    200: jsonResponse(
      "Computers you can use",
      z.object({ items: z.array(Computer) }).openapi("ComputerList"),
    ),
    401: e401,
  },
});

export const getComputer = createRoute({
  operationId: "getComputer",
  method: "get",
  path: "/v1/computers/{id}",
  tags: ["computers"],
  security,
  request: { params: idParam },
  responses: { 200: jsonResponse("Computer", Computer), 401: e401, 404: e404 },
});

const lifecycle = (action: "start" | "stop" | "restart", summary: string) =>
  createRoute({
    operationId: `${action}Computer`,
    method: "post",
    path: `/v1/computers/{id}/${action}`,
    tags: ["computers"],
    security,
    summary,
    request: { params: idParam, headers: IdempotencyKeyHeader },
    responses: { 200: jsonResponse("Computer", Computer), 401: e401, 404: e404, 409: e409 },
  });
export const startComputer = lifecycle("start", "Start or restore the computer");
export const stopComputer = lifecycle(
  "stop",
  "Save the home directory to storage and stop (sleep)",
);
export const restartComputer = lifecycle("restart", "Sleep and start again with the same files");

export const listComputerFiles = createRoute({
  operationId: "listComputerFiles",
  method: "get",
  path: "/v1/computers/{id}/files/list",
  tags: ["computers"],
  security,
  summary: "List a directory (default ~/workspace)",
  request: { params: idParam, query: pathQuery },
  responses: {
    200: jsonResponse(
      "Entries",
      z
        .object({ path: z.string(), entries: z.array(ComputerFileEntry) })
        .openapi("ComputerFileList"),
    ),
    401: e401,
    404: e404,
  },
});

export const downloadComputerFile = createRoute({
  operationId: "downloadComputerFile",
  method: "get",
  path: "/v1/computers/{id}/files",
  tags: ["computers"],
  security,
  summary: "Download a file",
  request: { params: idParam, query: z.object({ path: z.string().min(1).max(4000) }) },
  responses: {
    200: {
      description: "File contents",
      content: { "application/octet-stream": { schema: z.string().openapi({ format: "binary" }) } },
    },
    401: e401,
    404: e404,
  },
});

export const uploadComputerFile = createRoute({
  operationId: "uploadComputerFile",
  method: "put",
  path: "/v1/computers/{id}/files",
  tags: ["computers"],
  security,
  summary: "Upload a file (request body is the raw contents, up to 100 MB)",
  request: {
    params: idParam,
    query: z.object({ path: z.string().min(1).max(4000) }),
    body: {
      content: { "application/octet-stream": { schema: z.string().openapi({ format: "binary" }) } },
      required: true,
    },
  },
  responses: {
    200: jsonResponse(
      "Uploaded",
      z.object({ path: z.string(), size: z.number().int() }).openapi("UploadResult"),
    ),
    400: e400,
    401: e401,
    404: e404,
  },
});

export const deleteComputerFile = createRoute({
  operationId: "deleteComputerFile",
  method: "delete",
  path: "/v1/computers/{id}/files",
  tags: ["computers"],
  security,
  request: { params: idParam, query: z.object({ path: z.string().min(1).max(4000) }) },
  responses: {
    200: jsonResponse("Deleted", z.object({ deleted: z.string() }).openapi("DeleteResult")),
    401: e401,
    404: e404,
  },
});

export const listCheckpoints = createRoute({
  operationId: "listCheckpoints",
  method: "get",
  path: "/v1/computers/{id}/checkpoints",
  tags: ["computers"],
  security,
  request: { params: idParam },
  responses: {
    200: jsonResponse(
      "Newest first",
      z.object({ items: z.array(Checkpoint) }).openapi("CheckpointList"),
    ),
    401: e401,
    404: e404,
  },
});

export const createCheckpoint = createRoute({
  operationId: "createCheckpoint",
  method: "post",
  path: "/v1/computers/{id}/checkpoints",
  tags: ["computers"],
  security,
  request: {
    params: idParam,
    headers: IdempotencyKeyHeader,
    body: jsonBody(CreateCheckpointRequest),
  },
  responses: { 201: jsonResponse("Saved", Checkpoint), 401: e401, 404: e404 },
});

export const restoreCheckpoint = createRoute({
  operationId: "restoreCheckpoint",
  method: "post",
  path: "/v1/computers/{id}/checkpoints/{cid}/restore",
  tags: ["computers"],
  security,
  summary: "Undo to a checkpoint (replaces the home directory)",
  request: { params: z.object({ id: Uuid, cid: Uuid }) },
  responses: { 200: jsonResponse("Computer", Computer), 401: e401, 404: e404 },
});

export const computerScreenshot = createRoute({
  operationId: "computerScreenshot",
  method: "get",
  path: "/v1/computers/{id}/screenshot",
  tags: ["computers"],
  security,
  summary: "PNG of the desktop, or of the bot's browser page on headless computers",
  request: { params: idParam },
  responses: {
    200: {
      description: "PNG image",
      content: { "image/png": { schema: z.string().openapi({ format: "binary" }) } },
    },
    401: e401,
    404: e404,
    409: e409,
  },
});

export const computerTerminal = createRoute({
  operationId: "computerTerminal",
  method: "get",
  path: "/v1/computers/{id}/terminal",
  tags: ["computers"],
  security,
  summary:
    "WebSocket terminal. Binary frames carry terminal bytes both ways. Browsers may pass the access token as ?access_token=.",
  request: {
    params: idParam,
    query: z.object({
      cols: z.coerce.number().int().optional(),
      rows: z.coerce.number().int().optional(),
      access_token: z.string().optional(),
    }),
  },
  responses: { 101: { description: "Switching to WebSocket" }, 401: e401, 404: e404 },
});

export const createComputer = createRoute({
  operationId: "createComputer",
  method: "post",
  path: "/v1/computers",
  tags: ["computers"],
  security,
  summary: "Create a private computer for a bot (or the team computer if it was removed)",
  request: { headers: IdempotencyKeyHeader, body: jsonBody(CreateComputerRequest) },
  responses: { 201: jsonResponse("Created", Computer), 400: e400, 401: e401, 403: e403, 409: e409 },
});

export const updateComputer = createRoute({
  operationId: "updateComputer",
  method: "patch",
  path: "/v1/computers/{id}",
  tags: ["computers"],
  security,
  request: { params: idParam, body: jsonBody(UpdateComputerRequest) },
  responses: { 200: jsonResponse("Updated", Computer), 400: e400, 401: e401, 403: e403, 404: e404 },
});

export const deleteComputer = createRoute({
  operationId: "deleteComputer",
  method: "delete",
  path: "/v1/computers/{id}",
  tags: ["computers"],
  security,
  summary: "Delete a computer and its files, snapshots and checkpoints",
  request: { params: idParam },
  responses: {
    200: jsonResponse("Deleted", z.object({ deleted: Uuid }).openapi("DeletedComputer")),
    401: e401,
    403: e403,
    404: e404,
  },
});

export const createStreamSession = createRoute({
  operationId: "createStreamSession",
  method: "post",
  path: "/v1/computers/{id}/stream-session",
  tags: ["computers"],
  security,
  summary: "Get a 5-minute live-view session (signaling URL, token, TURN credentials)",
  request: { params: idParam, body: jsonBody(StreamSessionRequest) },
  responses: {
    200: jsonResponse("Session", StreamSession),
    401: e401,
    403: e403,
    404: e404,
    409: e409,
  },
});

export const computerStream = createRoute({
  operationId: "computerStream",
  method: "get",
  path: "/v1/computers/{id}/stream",
  tags: ["computers"],
  summary:
    "WebSocket live-view signaling (Neko protocol). Authenticated by the stream-session token; input is accepted only in control mode while you hold the lease.",
  request: { params: idParam, query: z.object({ token: z.string() }) },
  responses: { 101: { description: "Switching to WebSocket" }, 401: e401, 404: e404 },
});

export const getLease = createRoute({
  operationId: "getLease",
  method: "get",
  path: "/v1/computers/{id}/lease",
  tags: ["computers"],
  security,
  summary: "Who controls the screen (the bot unless a person took over)",
  request: { params: idParam },
  responses: { 200: jsonResponse("Lease", Lease), 401: e401, 404: e404 },
});

export const takeLease = createRoute({
  operationId: "takeLease",
  method: "post",
  path: "/v1/computers/{id}/lease",
  tags: ["computers"],
  security,
  summary:
    "Take control (or renew it). The bot pauses screen actions; control returns after 15 minutes without renewal.",
  request: { params: idParam, body: jsonBody(TakeLeaseRequest) },
  responses: { 200: jsonResponse("Lease", Lease), 401: e401, 404: e404, 409: e409 },
});

export const releaseLease = createRoute({
  operationId: "releaseLease",
  method: "delete",
  path: "/v1/computers/{id}/lease",
  tags: ["computers"],
  security,
  summary: "Hand control back to the bot, optionally with a note",
  request: { params: idParam, body: jsonBody(ReleaseLeaseRequest) },
  responses: { 200: jsonResponse("Lease", Lease), 401: e401, 404: e404 },
});

export const listTakeovers = createRoute({
  operationId: "listTakeovers",
  method: "get",
  path: "/v1/takeovers",
  tags: ["computers"],
  security,
  summary: "Open requests from bots for a person to take over a screen",
  request: { query: z.object({ org_id: Uuid }) },
  responses: {
    200: jsonResponse(
      "Takeover requests",
      z.object({ items: z.array(TakeoverRequest) }).openapi("TakeoverRequestList"),
    ),
    401: e401,
  },
});

export const dismissTakeover = createRoute({
  operationId: "dismissTakeover",
  method: "post",
  path: "/v1/takeovers/{id}/dismiss",
  tags: ["computers"],
  security,
  summary: "Decline a takeover request; the bot continues without help",
  request: { params: idParam, body: jsonBody(ReleaseLeaseRequest) },
  responses: { 200: jsonResponse("Dismissed", TakeoverRequest), 401: e401, 404: e404, 409: e409 },
});
