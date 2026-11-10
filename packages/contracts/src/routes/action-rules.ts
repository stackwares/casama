import { createRoute, z } from "@hono/zod-openapi";
import { ActionRuleOut, CreateActionRuleRequest } from "../action-rules.ts";
import { jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";

const security = [{ bearerAuth: [] }];
const { 400: e400, 401: e401, 403: e403, 404: e404 } = problemResponses;

export const listActionRules = createRoute({
  operationId: "listActionRules",
  method: "get",
  path: "/v1/action-rules",
  tags: ["action-rules"],
  security,
  summary: "A bot's rules plus the workspace's (or only the workspace's without bot_id)",
  request: { query: z.object({ org_id: Uuid, bot_id: Uuid.optional() }) },
  responses: {
    200: jsonResponse(
      "Rules",
      z.object({ items: z.array(ActionRuleOut) }).openapi("ActionRuleList"),
    ),
    401: e401,
  },
});

export const createActionRule = createRoute({
  operationId: "createActionRule",
  method: "post",
  path: "/v1/action-rules",
  tags: ["action-rules"],
  security,
  request: { body: jsonBody(CreateActionRuleRequest) },
  responses: { 201: jsonResponse("Created", ActionRuleOut), 400: e400, 401: e401, 403: e403 },
});

export const deleteActionRule = createRoute({
  operationId: "deleteActionRule",
  method: "delete",
  path: "/v1/action-rules/{id}",
  tags: ["action-rules"],
  security,
  request: { params: z.object({ id: Uuid }) },
  responses: {
    200: jsonResponse("Deleted", z.object({ deleted: Uuid }).openapi("DeletedRule")),
    401: e401,
    403: e403,
    404: e404,
  },
});
