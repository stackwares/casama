import { createRoute, z } from "@hono/zod-openapi";
import {
  AppCatalog,
  ConnectAppRequest,
  ConnectAppResponse,
  ConnectFlowStatus,
  ProviderAccount,
  ProviderApp,
  ProviderConnectRequest,
  UpdateIntegrationRequest,
} from "../apps.ts";
import { Integration } from "../autonomy.ts";
import { jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";

const security = [{ bearerAuth: [] }];
const { 400: e400, 401: e401, 403: e403, 404: e404 } = problemResponses;
const idParam = z.object({ id: Uuid });
const Ok = z.object({ ok: z.boolean() });

export const listApps = createRoute({
  operationId: "listApps",
  method: "get",
  path: "/v1/apps",
  tags: ["integrations"],
  security,
  summary: "Built-in apps (vendors' hosted MCP servers) people can connect in one step",
  responses: { 200: jsonResponse("Catalog", AppCatalog), 401: e401 },
});

export const connectApp = createRoute({
  operationId: "connectApp",
  method: "post",
  path: "/v1/apps/connect",
  tags: ["integrations"],
  security,
  summary: "Connect a built-in app: with an API key at once, or start an OAuth sign-in",
  request: { body: jsonBody(ConnectAppRequest) },
  responses: {
    200: jsonResponse("Connected, or a sign-in to open", ConnectAppResponse),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
  },
});

export const connectStatus = createRoute({
  operationId: "connectStatus",
  method: "get",
  path: "/v1/apps/connect/{id}",
  tags: ["integrations"],
  security,
  summary: "Whether an OAuth sign-in has finished",
  request: { params: idParam },
  responses: { 200: jsonResponse("Status", ConnectFlowStatus), 401: e401, 404: e404 },
});

export const updateIntegration = createRoute({
  operationId: "updateIntegration",
  method: "patch",
  path: "/v1/integrations/{id}",
  tags: ["integrations"],
  security,
  request: { params: idParam, body: jsonBody(UpdateIntegrationRequest) },
  responses: { 200: jsonResponse("Updated", Integration), 401: e401, 403: e403, 404: e404 },
});

export const deleteIntegration = createRoute({
  operationId: "deleteIntegration",
  method: "delete",
  path: "/v1/integrations/{id}",
  tags: ["integrations"],
  security,
  summary: "Disconnect: removes it from every bot and deletes its stored credential",
  request: { params: idParam },
  responses: { 200: jsonResponse("Removed", Ok), 401: e401, 403: e403, 404: e404 },
});

export const listProviderApps = createRoute({
  operationId: "listProviderApps",
  method: "get",
  path: "/v1/integrations/{id}/provider/apps",
  tags: ["integrations"],
  security,
  summary: "Search a Composio or Pipedream connection's app directory",
  request: { params: idParam, query: z.object({ q: z.string().max(100).optional() }) },
  responses: {
    200: jsonResponse("Apps", z.object({ items: z.array(ProviderApp) }).openapi("ProviderAppList")),
    400: e400,
    401: e401,
    404: e404,
  },
});

export const connectProviderApp = createRoute({
  operationId: "connectProviderApp",
  method: "post",
  path: "/v1/integrations/{id}/provider/connect",
  tags: ["integrations"],
  security,
  summary: "Add an app to a Composio or Pipedream connection and start signing in to it",
  request: { params: idParam, body: jsonBody(ProviderConnectRequest) },
  responses: {
    200: jsonResponse(
      "Sign-in page",
      z.object({ redirect_url: z.string() }).openapi("ProviderConnectResponse"),
    ),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
  },
});

export const listProviderAccounts = createRoute({
  operationId: "listProviderAccounts",
  method: "get",
  path: "/v1/integrations/{id}/provider/accounts",
  tags: ["integrations"],
  security,
  summary: "Accounts signed in through a Composio or Pipedream connection",
  request: { params: idParam },
  responses: {
    200: jsonResponse(
      "Accounts",
      z.object({ items: z.array(ProviderAccount) }).openapi("ProviderAccountList"),
    ),
    400: e400,
    401: e401,
    404: e404,
  },
});
