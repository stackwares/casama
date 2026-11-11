import { createRoute, z } from "@hono/zod-openapi";
import { jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";
import { CreateKnowledgeSourceRequest, KnowledgeSource } from "../knowledge.ts";

const security = [{ bearerAuth: [] }];
const { 400: e400, 401: e401, 403: e403, 404: e404 } = problemResponses;
const idParam = z.object({ id: Uuid });
const tags = ["knowledge"];

export const listKnowledgeSources = createRoute({
  operationId: "listKnowledgeSources",
  method: "get",
  path: "/v1/knowledge-sources",
  tags,
  security,
  summary: "A bot's knowledge sources and the workspace's shared ones",
  request: { query: z.object({ org_id: Uuid, bot_id: Uuid.optional() }) },
  responses: {
    200: jsonResponse(
      "Sources",
      z.object({ items: z.array(KnowledgeSource) }).openapi("KnowledgeSourceList"),
    ),
    401: e401,
  },
});

export const createKnowledgeSource = createRoute({
  operationId: "createKnowledgeSource",
  method: "post",
  path: "/v1/knowledge-sources",
  tags,
  security,
  summary:
    "Add files, a website, a GitHub repository or documents from a connection; the worker reads it within a minute",
  request: { body: jsonBody(CreateKnowledgeSourceRequest) },
  responses: {
    201: jsonResponse("Source", KnowledgeSource),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
  },
});

export const resyncKnowledgeSource = createRoute({
  operationId: "resyncKnowledgeSource",
  method: "post",
  path: "/v1/knowledge-sources/{id}/sync",
  tags,
  security,
  request: { params: idParam },
  responses: { 200: jsonResponse("Source", KnowledgeSource), 401: e401, 403: e403, 404: e404 },
});

export const deleteKnowledgeSource = createRoute({
  operationId: "deleteKnowledgeSource",
  method: "delete",
  path: "/v1/knowledge-sources/{id}",
  tags,
  security,
  request: { params: idParam },
  responses: {
    200: jsonResponse("Deleted", z.object({ deleted: Uuid }).openapi("DeletedKnowledgeSource")),
    401: e401,
    403: e403,
    404: e404,
  },
});
