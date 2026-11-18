import { createRoute, z } from "@hono/zod-openapi";
import { jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";
import {
  AddTeachStepRequest,
  MarkTeachSecretRequest,
  SaveTeachRequest,
  SaveTeachResponse,
  StartTeachRequest,
  TeachSession,
  TeachStep,
} from "../teach.ts";

const security = [{ bearerAuth: [] }];
const { 401: e401, 403: e403, 404: e404, 409: e409 } = problemResponses;
const idParam = z.object({ id: Uuid });
const tags = ["teach"];

export const startTeach = createRoute({
  operationId: "startTeach",
  method: "post",
  path: "/v1/teach",
  tags,
  security,
  summary: "Start recording a task while you have control of a computer",
  request: { body: jsonBody(StartTeachRequest) },
  responses: {
    201: jsonResponse("Recording", TeachSession),
    401: e401,
    403: e403,
    404: e404,
    409: e409,
  },
});

export const getTeach = createRoute({
  operationId: "getTeach",
  method: "get",
  path: "/v1/teach/{id}",
  tags,
  security,
  request: { params: idParam },
  responses: { 200: jsonResponse("Recording", TeachSession), 401: e401, 404: e404 },
});

export const addTeachStep = createRoute({
  operationId: "addTeachStep",
  method: "post",
  path: "/v1/teach/{id}/steps",
  tags,
  security,
  summary: "Record a step; the server captures the screen's state after it",
  request: { params: idParam, body: jsonBody(AddTeachStepRequest) },
  responses: { 201: jsonResponse("Step", TeachStep), 401: e401, 404: e404, 409: e409 },
});

export const markTeachSecret = createRoute({
  operationId: "markTeachSecret",
  method: "post",
  path: "/v1/teach/{id}/steps/{seq}/secret",
  tags,
  security,
  summary:
    "Mark a typed value as a secret: its text is deleted and it becomes a {{secret:NAME}} input",
  request: {
    params: z.object({ id: Uuid, seq: z.coerce.number().int().min(1) }),
    body: jsonBody(MarkTeachSecretRequest),
  },
  responses: { 200: jsonResponse("Step", TeachStep), 401: e401, 404: e404, 409: e409 },
});

export const stopTeach = createRoute({
  operationId: "stopTeach",
  method: "post",
  path: "/v1/teach/{id}/stop",
  tags,
  security,
  summary: "Stop recording; the bot drafts a skill from it",
  request: { params: idParam },
  responses: { 200: jsonResponse("Recording", TeachSession), 401: e401, 404: e404, 409: e409 },
});

export const saveTeach = createRoute({
  operationId: "saveTeach",
  method: "post",
  path: "/v1/teach/{id}/save",
  tags,
  security,
  summary: "Save the (edited) draft as one of the bot's skills, and optionally try it now",
  request: { params: idParam, body: jsonBody(SaveTeachRequest) },
  responses: {
    200: jsonResponse("Saved", SaveTeachResponse),
    401: e401,
    403: e403,
    404: e404,
    409: e409,
  },
});

export const cancelTeach = createRoute({
  operationId: "cancelTeach",
  method: "delete",
  path: "/v1/teach/{id}",
  tags,
  security,
  summary: "Discard a recording and everything it captured",
  request: { params: idParam },
  responses: {
    200: jsonResponse("Deleted", z.object({ deleted: Uuid }).openapi("DeletedTeach")),
    401: e401,
    404: e404,
  },
});
