import { createRoute, z } from "@hono/zod-openapi";
import { jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";
import { Replay, ReplayFromTeachRequest, RunReplayRequest, RunReplayResponse } from "../replays.ts";

const security = [{ bearerAuth: [] }];
const { 400: e400, 401: e401, 403: e403, 404: e404, 409: e409 } = problemResponses;
const idParam = z.object({ id: Uuid });
const tags = ["replays"];

export const listReplays = createRoute({
  operationId: "listReplays",
  method: "get",
  path: "/v1/replays",
  tags,
  security,
  summary: "A bot's saved replays (D-127)",
  request: { query: z.object({ bot_id: Uuid }) },
  responses: { 200: jsonResponse("Replays", z.object({ items: z.array(Replay) }).openapi("ReplayList")), 401: e401 },
});

export const runReplay = createRoute({
  operationId: "runReplay",
  method: "post",
  path: "/v1/replays/{id}/run",
  tags,
  security,
  summary: "Run a replay without the model; the bot takes over if a step fails",
  request: { params: idParam, body: jsonBody(RunReplayRequest) },
  responses: { 202: jsonResponse("Started", RunReplayResponse), 400: e400, 401: e401, 403: e403, 404: e404 },
});

export const deleteReplay = createRoute({
  operationId: "deleteReplay",
  method: "delete",
  path: "/v1/replays/{id}",
  tags,
  security,
  request: { params: idParam },
  responses: { 200: jsonResponse("Deleted", z.object({ deleted: Uuid }).openapi("DeletedReplay")), 401: e401, 403: e403, 404: e404 },
});

export const replayFromTeach = createRoute({
  operationId: "replayFromTeach",
  method: "post",
  path: "/v1/teach/{id}/replay",
  tags,
  security,
  summary: "Save a teach recording as a replay",
  request: { params: idParam, body: jsonBody(ReplayFromTeachRequest) },
  responses: { 201: jsonResponse("Replay", Replay), 401: e401, 403: e403, 404: e404, 409: e409 },
});
