import { createRoute, z } from "@hono/zod-openapi";
import {
  CreateHighlightRequest,
  CreatePageCommandRequest,
  CreatePageWatcherRequest,
  Highlight,
  PageCommand,
  PageHistory,
  UpdatePageCommandRequest,
} from "../browser.ts";
import { jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";
import { Watcher } from "../watchers.ts";

/** Casama for Chrome, Phase 2 (D-323): page commands, highlights, a page's history, page watchers. */
const security = [{ bearerAuth: [] }];
const { 400: e400, 401: e401, 404: e404, 409: e409 } = problemResponses;
const idParam = z.object({ id: Uuid });

export const listPageCommands = createRoute({
  operationId: "listPageCommands",
  method: "get",
  path: "/v1/me/page-commands",
  tags: ["browser"],
  security,
  summary: "Your saved prompts for the / menu in Casama for Chrome",
  responses: {
    200: jsonResponse(
      "Page commands",
      z.object({ items: z.array(PageCommand) }).openapi("PageCommandList"),
    ),
    401: e401,
  },
});

export const createPageCommand = createRoute({
  operationId: "createPageCommand",
  method: "post",
  path: "/v1/me/page-commands",
  tags: ["browser"],
  security,
  request: { body: jsonBody(CreatePageCommandRequest) },
  responses: {
    201: jsonResponse("Created", PageCommand),
    400: e400,
    401: e401,
    409: e409,
  },
});

export const updatePageCommand = createRoute({
  operationId: "updatePageCommand",
  method: "patch",
  path: "/v1/me/page-commands/{id}",
  tags: ["browser"],
  security,
  request: { params: idParam, body: jsonBody(UpdatePageCommandRequest) },
  responses: {
    200: jsonResponse("Updated", PageCommand),
    400: e400,
    401: e401,
    404: e404,
    409: e409,
  },
});

export const deletePageCommand = createRoute({
  operationId: "deletePageCommand",
  method: "delete",
  path: "/v1/me/page-commands/{id}",
  tags: ["browser"],
  security,
  request: { params: idParam },
  responses: {
    200: jsonResponse("Deleted", z.object({ deleted: Uuid }).openapi("DeletedPageCommand")),
    401: e401,
    404: e404,
  },
});

export const listHighlights = createRoute({
  operationId: "listHighlights",
  method: "get",
  path: "/v1/me/highlights",
  tags: ["browser"],
  security,
  summary: "Your highlights in a workspace, newest first; one page's when url is given",
  request: {
    query: z.object({ org_id: Uuid, url: z.string().max(2000).optional() }),
  },
  responses: {
    200: jsonResponse(
      "Highlights",
      z.object({ items: z.array(Highlight) }).openapi("HighlightList"),
    ),
    401: e401,
  },
});

export const createHighlight = createRoute({
  operationId: "createHighlight",
  method: "post",
  path: "/v1/me/highlights",
  tags: ["browser"],
  security,
  request: { body: jsonBody(CreateHighlightRequest) },
  responses: { 201: jsonResponse("Created", Highlight), 400: e400, 401: e401, 404: e404 },
});

export const deleteHighlight = createRoute({
  operationId: "deleteHighlight",
  method: "delete",
  path: "/v1/me/highlights/{id}",
  tags: ["browser"],
  security,
  request: { params: idParam },
  responses: {
    200: jsonResponse("Deleted", z.object({ deleted: Uuid }).openapi("DeletedHighlight")),
    401: e401,
    404: e404,
  },
});

export const getPageHistory = createRoute({
  operationId: "getPageHistory",
  method: "get",
  path: "/v1/me/page-history",
  tags: ["browser"],
  security,
  summary: "Your past chats that started from this page, and your highlights on it",
  request: { query: z.object({ org_id: Uuid, url: z.string().min(1).max(2000) }) },
  responses: { 200: jsonResponse("History", PageHistory), 401: e401 },
});

export const createPageWatcher = createRoute({
  operationId: "createPageWatcher",
  method: "post",
  path: "/v1/watchers",
  tags: ["watchers"],
  security,
  summary: "Watch part of a public page; the bot is woken when it changes",
  request: { body: jsonBody(CreatePageWatcherRequest) },
  responses: { 201: jsonResponse("Watcher", Watcher), 400: e400, 401: e401, 404: e404 },
});
