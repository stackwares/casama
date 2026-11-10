import { createRoute, z } from "@hono/zod-openapi";
import {
  BotShareLink,
  BotTemplateFile,
  CreateBotShareRequest,
  ImportBotRequest,
  ImportBotResponse,
} from "../bot-template.ts";
import { jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";

const security = [{ bearerAuth: [] }];
const { 400: e400, 401: e401, 403: e403, 404: e404 } = problemResponses;
const idParam = z.object({ id: Uuid });

export const exportBot = createRoute({
  operationId: "exportBot",
  method: "get",
  path: "/v1/bots/{id}/export",
  tags: ["bots"],
  security,
  summary: "A bot as a shareable template file (no secrets; memories only when asked)",
  request: {
    params: idParam,
    query: z.object({ memories: z.enum(["true", "false"]).optional() }),
  },
  responses: { 200: jsonResponse("Template", BotTemplateFile), 401: e401, 404: e404 },
});

export const createBotShare = createRoute({
  operationId: "createBotShare",
  method: "post",
  path: "/v1/bots/{id}/share",
  tags: ["bots"],
  security,
  summary:
    "Make a share link for a bot template (a snapshot; anyone signed in with the link can import it)",
  request: { params: idParam, body: jsonBody(CreateBotShareRequest) },
  responses: { 201: jsonResponse("Link", BotShareLink), 401: e401, 403: e403, 404: e404 },
});

export const getBotShare = createRoute({
  operationId: "getBotShare",
  method: "get",
  path: "/v1/bot-shares/{token}",
  tags: ["bots"],
  security,
  summary: "Read a shared bot template, to preview before importing",
  request: { params: z.object({ token: z.string().min(16).max(100) }) },
  responses: { 200: jsonResponse("Template", BotTemplateFile), 401: e401, 404: e404 },
});

export const importBot = createRoute({
  operationId: "importBot",
  method: "post",
  path: "/v1/bots/import",
  tags: ["bots"],
  security,
  summary: "Create a bot from a template file",
  request: { body: jsonBody(ImportBotRequest) },
  responses: { 201: jsonResponse("Imported", ImportBotResponse), 400: e400, 401: e401, 403: e403 },
});
