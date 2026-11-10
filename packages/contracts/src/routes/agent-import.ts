import { createRoute, z } from "@hono/zod-openapi";
import {
  AgentImportPlan,
  MemoryImportPrompt,
  ParsedMemoryImport,
  ParseMemoryImportRequest,
  SaveImportedMemoriesRequest,
  StartAgentImportRequest,
  WriteAgentImportFilesRequest,
  WriteAgentImportFilesResponse,
} from "../agent-import.ts";
import { jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";

const security = [{ bearerAuth: [] }];
const { 400: e400, 401: e401, 403: e403, 404: e404, 409: e409 } = problemResponses;
const tags = ["import"];

export const startAgentImport = createRoute({
  operationId: "startAgentImport",
  method: "post",
  path: "/v1/agent-imports",
  tags,
  security,
  summary: "Read an OpenClaw or Hermes Agent folder into a bot template for review (D-122)",
  request: { body: jsonBody(StartAgentImportRequest) },
  responses: { 201: jsonResponse("The mapping", AgentImportPlan), 400: e400, 401: e401 },
});

export const writeAgentImportFiles = createRoute({
  operationId: "writeAgentImportFiles",
  method: "post",
  path: "/v1/agent-imports/{id}/files",
  tags,
  security,
  summary: "Copy the files nothing mapped to into ~/imported/ on the bot's computer",
  request: { params: z.object({ id: Uuid }), body: jsonBody(WriteAgentImportFilesRequest) },
  responses: {
    200: jsonResponse("Written", WriteAgentImportFilesResponse),
    401: e401,
    403: e403,
    404: e404,
    409: e409,
  },
});

export const getMemoryImportPrompt = createRoute({
  operationId: "getMemoryImportPrompt",
  method: "get",
  path: "/v1/memory-import/prompt",
  tags,
  security,
  summary: "The prompt to paste into ChatGPT or Claude to get your saved memories",
  responses: { 200: jsonResponse("Prompt", MemoryImportPrompt), 401: e401 },
});

export const parseMemoryImport = createRoute({
  operationId: "parseMemoryImport",
  method: "post",
  path: "/v1/memory-import/parse",
  tags,
  security,
  request: { body: jsonBody(ParseMemoryImportRequest) },
  responses: { 200: jsonResponse("Memories", ParsedMemoryImport), 401: e401 },
});

export const saveImportedMemories = createRoute({
  operationId: "saveImportedMemories",
  method: "post",
  path: "/v1/bots/{id}/memories/import",
  tags,
  security,
  summary: "Add the memories the person kept",
  request: { params: z.object({ id: Uuid }), body: jsonBody(SaveImportedMemoriesRequest) },
  responses: {
    200: jsonResponse(
      "Saved",
      z.object({ saved: z.number().int() }).openapi("SavedImportedMemories"),
    ),
    401: e401,
    403: e403,
    404: e404,
  },
});
