import { createRoute, z } from "@hono/zod-openapi";
import { jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";
import { SecretStoreSettings, SetSecretStoreRequest } from "../secret-store.ts";

const security = [{ bearerAuth: [] }];
const { 400: e400, 401: e401, 403: e403, 404: e404 } = problemResponses;
const params = z.object({ id: Uuid });
const tags = ["secrets"];

export const getSecretStore = createRoute({
  operationId: "getSecretStore",
  method: "get",
  path: "/v1/orgs/{id}/secret-store",
  tags,
  security,
  request: { params },
  responses: { 200: jsonResponse("Store", SecretStoreSettings), 401: e401, 403: e403, 404: e404 },
});
export const setSecretStore = createRoute({
  operationId: "setSecretStore",
  method: "put",
  path: "/v1/orgs/{id}/secret-store",
  tags,
  security,
  summary: "Keep bots' named secrets in the workspace's Infisical project (admins)",
  request: { params, body: jsonBody(SetSecretStoreRequest) },
  responses: {
    200: jsonResponse("Store", SecretStoreSettings),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
  },
});
export const deleteSecretStore = createRoute({
  operationId: "deleteSecretStore",
  method: "delete",
  path: "/v1/orgs/{id}/secret-store",
  tags,
  security,
  summary: "Go back to Vault (secrets kept in Infisical are copied back first)",
  request: { params },
  responses: {
    200: jsonResponse("Store", SecretStoreSettings),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
  },
});
