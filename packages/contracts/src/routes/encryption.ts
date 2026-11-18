import { createRoute, z } from "@hono/zod-openapi";
import { jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";
import { EncryptionStatus, ReplacedDataKeys, SetEncryptionRequest } from "../encryption.ts";

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

export const replaceEncryptionKey = createRoute({
  operationId: "replaceEncryptionKey",
  method: "post",
  path: "/v1/orgs/{id}/encryption/replace-key",
  tags,
  security,
  summary:
    "Replace the workspace's data key (owners); rows are resealed onto the new key in the background",
  request: { params },
  responses: {
    200: jsonResponse("Status", EncryptionStatus),
    401: e401,
    403: e403,
    404: e404,
    409: e409,
  },
});

export const adminReplaceDataKeys = createRoute({
  operationId: "adminReplaceDataKeys",
  method: "post",
  path: "/v1/admin/encryption/replace-keys",
  tags: ["admin", ...tags],
  security,
  summary:
    "Replace every data key on this server (instance owner), after a database leak; rows are resealed in the background",
  responses: {
    200: jsonResponse("Replaced", ReplacedDataKeys),
    401: e401,
    403: e403,
    409: e409,
  },
});
