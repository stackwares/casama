import { createRoute, z } from "@hono/zod-openapi";
import { jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";
import { EncryptionStatus, SetEncryptionRequest } from "../encryption.ts";

const security = [{ bearerAuth: [] }];
const { 401: e401, 403: e403, 404: e404, 409: e409 } = problemResponses;
const params = z.object({ id: Uuid });
const tags = ["encryption"];

export const getEncryption = createRoute({
  operationId: "getEncryption",
  method: "get",
  path: "/v1/orgs/{id}/encryption",
  tags,
  security,
  summary: "Encryption at rest for a workspace",
  request: { params },
  responses: { 200: jsonResponse("Status", EncryptionStatus), 401: e401, 403: e403, 404: e404 },
});

export const setEncryption = createRoute({
  operationId: "setEncryption",
  method: "put",
  path: "/v1/orgs/{id}/encryption",
  tags,
  security,
  summary:
    "Turn encryption at rest on or off (owners); existing rows are sealed or opened in the background",
  request: { params, body: jsonBody(SetEncryptionRequest) },
  responses: {
    200: jsonResponse("Status", EncryptionStatus),
    401: e401,
    403: e403,
    404: e404,
    409: e409,
  },
});

export const rotateEncryptionKey = createRoute({
  operationId: "rotateEncryptionKey",
  method: "post",
  path: "/v1/orgs/{id}/encryption/rotate",
  tags,
  security,
  summary: "Rewrap the workspace's data key with the server's current key (rows are not rewritten)",
  request: { params },
  responses: {
    200: jsonResponse("Status", EncryptionStatus),
    401: e401,
    403: e403,
    404: e404,
    409: e409,
  },
});
