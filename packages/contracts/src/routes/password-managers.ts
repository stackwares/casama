import { createRoute, z } from "@hono/zod-openapi";
import { jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";
import { CreatePasswordManagerRequest, PasswordManager, PasswordManagerVault, UpdatePasswordManagerRequest } from "../password-managers.ts";

const security = [{ bearerAuth: [] }];
const { 400: e400, 401: e401, 403: e403, 404: e404 } = problemResponses;
const idParam = z.object({ id: Uuid });
const tags = ["password-managers"];

export const listPasswordManagers = createRoute({
  operationId: "listPasswordManagers",
  method: "get",
  path: "/v1/password-managers",
  tags,
  security,
  summary: "The workspace's password managers and your own (D-128)",
  request: { query: z.object({ org_id: Uuid }) },
  responses: { 200: jsonResponse("Password managers", z.object({ items: z.array(PasswordManager) }).openapi("PasswordManagerList")), 401: e401 },
});

export const createPasswordManager = createRoute({
  operationId: "createPasswordManager",
  method: "post",
  path: "/v1/password-managers",
  tags,
  security,
  summary: "Connect 1Password or Bitwarden; then choose which vaults bots may use",
  request: { body: jsonBody(CreatePasswordManagerRequest) },
  responses: { 201: jsonResponse("Connected", PasswordManager), 400: e400, 401: e401, 403: e403 },
});

export const listPasswordManagerVaults = createRoute({
  operationId: "listPasswordManagerVaults",
  method: "get",
  path: "/v1/password-managers/{id}/vaults",
  tags,
  security,
  request: { params: idParam },
  responses: { 200: jsonResponse("Vaults", z.object({ items: z.array(PasswordManagerVault) }).openapi("PasswordManagerVaultList")), 400: e400, 401: e401, 404: e404 },
});

export const updatePasswordManager = createRoute({
  operationId: "updatePasswordManager",
  method: "patch",
  path: "/v1/password-managers/{id}",
  tags,
  security,
  request: { params: idParam, body: jsonBody(UpdatePasswordManagerRequest) },
  responses: { 200: jsonResponse("Password manager", PasswordManager), 401: e401, 403: e403, 404: e404 },
});

export const deletePasswordManager = createRoute({
  operationId: "deletePasswordManager",
  method: "delete",
  path: "/v1/password-managers/{id}",
  tags,
  security,
  request: { params: idParam },
  responses: { 200: jsonResponse("Deleted", z.object({ deleted: Uuid }).openapi("DeletedPasswordManager")), 401: e401, 403: e403, 404: e404 },
});
