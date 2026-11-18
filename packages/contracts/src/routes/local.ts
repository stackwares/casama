import { createRoute, z } from "@hono/zod-openapi";
import { Integration } from "../autonomy.ts";
import { jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";
import {
  CodingAgentList,
  CodingAgentTestResult,
  CreatedLocalDevice,
  CreateLocalDeviceRequest,
  LocalDevice,
  OwnCodingAgentList,
  SetLocalMcpServersRequest,
  SetOwnCodingAgentsRequest,
  TestOwnCodingAgentRequest,
  UpdateLocalDeviceRequest,
} from "../local.ts";

const security = [{ bearerAuth: [] }];
const { 400: e400, 401: e401, 403: e403, 404: e404, 409: e409 } = problemResponses;
const idParam = z.object({ id: Uuid });

export const createLocalDevice = createRoute({
  operationId: "createLocalDevice",
  method: "post",
  path: "/v1/local-devices",
  tags: ["local computer"],
  security,
  summary: "Pair this machine as a bot computer (desktop companion); returns a device token once",
  request: { body: jsonBody(CreateLocalDeviceRequest) },
  responses: { 201: jsonResponse("Paired", CreatedLocalDevice), 400: e400, 401: e401, 403: e403 },
});

export const listLocalDevices = createRoute({
  operationId: "listLocalDevices",
  method: "get",
  path: "/v1/local-devices",
  tags: ["local computer"],
  security,
  request: { query: z.object({ org_id: Uuid }) },
  responses: {
    200: jsonResponse(
      "Your devices (admins see all)",
      z.object({ items: z.array(LocalDevice) }).openapi("LocalDeviceList"),
    ),
    401: e401,
  },
});

export const updateLocalDevice = createRoute({
  operationId: "updateLocalDevice",
  method: "patch",
  path: "/v1/local-devices/{id}",
  tags: ["local computer"],
  security,
  summary: "Change capabilities, shared folders, allowed bots or turn the device off",
  request: { params: idParam, body: jsonBody(UpdateLocalDeviceRequest) },
  responses: { 200: jsonResponse("Updated", LocalDevice), 400: e400, 401: e401, 404: e404 },
});

export const deleteLocalDevice = createRoute({
  operationId: "deleteLocalDevice",
  method: "delete",
  path: "/v1/local-devices/{id}",
  tags: ["local computer"],
  security,
  request: { params: idParam },
  responses: {
    200: jsonResponse("Unpaired", z.object({ deleted: Uuid }).openapi("DeletedDevice")),
    401: e401,
    404: e404,
  },
});

export const localComputerConnect = createRoute({
  operationId: "localComputerConnect",
  method: "get",
  path: "/v1/local-computer/connect",
  tags: ["local computer"],
  summary:
    "WebSocket for the desktop companion (authorization: Device <token>, or ?token=). The API sends tool requests; the app answers from its embedded computerd.",
  request: { query: z.object({ token: z.string().optional() }) },
  responses: { 101: { description: "Switching to WebSocket" }, 401: e401 },
});

export const setLocalMcpServers = createRoute({
  operationId: "setLocalMcpServers",
  method: "put",
  path: "/v1/local-devices/{id}/mcp-servers",
  tags: ["local computer"],
  security,
  summary:
    "Register the local MCP servers on this computer (no secrets); each becomes a local_mcp integration",
  request: { params: idParam, body: jsonBody(SetLocalMcpServersRequest) },
  responses: {
    200: jsonResponse(
      "The device's local MCP integrations",
      z.object({ items: z.array(Integration) }).openapi("LocalMcpIntegrationList"),
    ),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
  },
});

export const listCodingAgents = createRoute({
  operationId: "listCodingAgents",
  method: "get",
  path: "/v1/coding-agents",
  tags: ["local computer"],
  security,
  summary:
    "The coding agents this server's bots can hand tasks to (D-370): the signed gallery's list over the built-in one",
  responses: { 200: jsonResponse("The catalog", CodingAgentList), 401: e401 },
});

export const listOwnCodingAgents = createRoute({
  operationId: "listOwnCodingAgents",
  method: "get",
  path: "/v1/local-devices/{id}/coding-agents",
  tags: ["local computer"],
  security,
  summary: "Your own coding agents on this computer (D-371); only the device's owner sees them",
  request: { params: idParam },
  responses: { 200: jsonResponse("Yours", OwnCodingAgentList), 401: e401, 404: e404 },
});

export const setOwnCodingAgents = createRoute({
  operationId: "setOwnCodingAgents",
  method: "put",
  path: "/v1/local-devices/{id}/coding-agents",
  tags: ["local computer"],
  security,
  summary:
    "Replace your own coding agents on this computer (D-371); only the device's owner can, admins included",
  request: { params: idParam, body: jsonBody(SetOwnCodingAgentsRequest) },
  responses: {
    200: jsonResponse("Saved", OwnCodingAgentList),
    400: e400,
    401: e401,
    404: e404,
  },
});

export const testOwnCodingAgent = createRoute({
  operationId: "testOwnCodingAgent",
  method: "post",
  path: "/v1/local-devices/{id}/coding-agents/test",
  tags: ["local computer"],
  security,
  summary:
    'Run an agent on this computer with a tiny task ("Reply with just the word pong") and return what it printed',
  request: { params: idParam, body: jsonBody(TestOwnCodingAgentRequest) },
  responses: {
    200: jsonResponse("What happened", CodingAgentTestResult),
    400: e400,
    401: e401,
    404: e404,
    409: e409,
  },
});
