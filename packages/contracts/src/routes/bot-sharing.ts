import { createRoute, z } from "@hono/zod-openapi";
import { BotAccess, SetBotAccessRequest, WorkspaceMember } from "../bot-sharing.ts";
import { jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";

const security = [{ bearerAuth: [] }];
const { 400: e400, 401: e401, 403: e403, 404: e404 } = problemResponses;
const idParam = z.object({ id: Uuid });

export const getBotAccess = createRoute({
  operationId: "getBotAccess",
  method: "get",
  path: "/v1/bots/{id}/access",
  tags: ["bots"],
  security,
  summary: "Who can chat with, edit or administer this bot",
  request: { params: idParam },
  responses: { 200: jsonResponse("Access", BotAccess), 401: e401, 404: e404 },
});

export const setBotAccess = createRoute({
  operationId: "setBotAccess",
  method: "put",
  path: "/v1/bots/{id}/access",
  tags: ["bots"],
  security,
  summary: "Replace the bot's visibility and access list",
  request: { params: idParam, body: jsonBody(SetBotAccessRequest) },
  responses: { 200: jsonResponse("Access", BotAccess), 400: e400, 401: e401, 403: e403, 404: e404 },
});

export const listMembers = createRoute({
  operationId: "listMembers",
  method: "get",
  path: "/v1/orgs/{id}/members",
  tags: ["workspaces"],
  security,
  summary: "The people in a workspace",
  request: { params: idParam },
  responses: {
    200: jsonResponse(
      "Members",
      z.object({ items: z.array(WorkspaceMember) }).openapi("WorkspaceMemberList"),
    ),
    401: e401,
    404: e404,
  },
});
