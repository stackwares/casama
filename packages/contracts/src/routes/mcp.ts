import { createRoute, z } from "@hono/zod-openapi";
import { jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";
import {
  CreatedMcpKey,
  CreateMcpKeyRequest,
  McpAuthRequestInfo,
  McpConsentRequest,
  McpConsentResult,
  McpKey,
} from "../mcp.ts";

const security = [{ bearerAuth: [] }];
const { 400: e400, 401: e401, 403: e403, 404: e404, 409: e409 } = problemResponses;

export const listMcpKeys = createRoute({
  operationId: "listMcpKeys",
  method: "get",
  path: "/v1/orgs/{id}/mcp-keys",
  tags: ["mcp"],
  security,
  request: { params: z.object({ id: Uuid }) },
  responses: {
    200: jsonResponse("Keys", z.object({ items: z.array(McpKey) }).openapi("McpKeyList")),
    401: e401,
    403: e403,
  },
});

export const createMcpKey = createRoute({
  operationId: "createMcpKey",
  method: "post",
  path: "/v1/orgs/{id}/mcp-keys",
  tags: ["mcp"],
  security,
  summary:
    "A workspace API key for the hosted MCP endpoint (admins); it acts as you in this workspace",
  request: { params: z.object({ id: Uuid }), body: jsonBody(CreateMcpKeyRequest) },
  responses: { 201: jsonResponse("Created", CreatedMcpKey), 401: e401, 403: e403 },
});

export const revokeMcpKey = createRoute({
  operationId: "revokeMcpKey",
  method: "delete",
  path: "/v1/orgs/{id}/mcp-keys/{key_id}",
  tags: ["mcp"],
  security,
  request: { params: z.object({ id: Uuid, key_id: Uuid }) },
  responses: {
    200: jsonResponse("Revoked", z.object({ revoked: Uuid }).openapi("RevokedKey")),
    401: e401,
    403: e403,
    404: e404,
  },
});

export const getMcpAuthRequest = createRoute({
  operationId: "getMcpAuthRequest",
  method: "get",
  path: "/v1/oauth/requests/{id}",
  tags: ["mcp"],
  security,
  summary: "An AI app asking to connect, for the consent screen",
  request: { params: z.object({ id: Uuid }) },
  responses: { 200: jsonResponse("Request", McpAuthRequestInfo), 401: e401, 404: e404 },
});

export const decideMcpAuthRequest = createRoute({
  operationId: "decideMcpAuthRequest",
  method: "post",
  path: "/v1/oauth/requests/{id}/consent",
  tags: ["mcp"],
  security,
  summary: "Allow or refuse an AI app's access to one workspace; returns where to send the browser",
  request: { params: z.object({ id: Uuid }), body: jsonBody(McpConsentRequest) },
  responses: {
    200: jsonResponse("Result", McpConsentResult),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
    409: e409,
  },
});
