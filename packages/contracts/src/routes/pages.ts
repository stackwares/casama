import { createRoute, z } from "@hono/zod-openapi";
import { jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";
import {
  Page,
  PageDetail,
  PageViewLink,
  PageViewLinkRequest,
  RevertPageRequest,
  UpdatePageRequest,
  UpdatePageResponse,
} from "../pages.ts";

const security = [{ bearerAuth: [] }];
const { 401: e401, 403: e403, 404: e404 } = problemResponses;
const idParam = z.object({ id: Uuid });

export const listPages = createRoute({
  operationId: "listPages",
  method: "get",
  path: "/v1/pages",
  tags: ["pages"],
  security,
  summary: "Pages you can open in a workspace (D-119)",
  request: { query: z.object({ org_id: Uuid, bot_id: Uuid.optional() }) },
  responses: {
    200: jsonResponse("Pages", z.object({ items: z.array(Page) }).openapi("PageList")),
    401: e401,
  },
});

export const getPage = createRoute({
  operationId: "getPage",
  method: "get",
  path: "/v1/pages/{id}",
  tags: ["pages"],
  security,
  request: { params: idParam },
  responses: { 200: jsonResponse("Page", PageDetail), 401: e401, 404: e404 },
});

export const createPageViewLink = createRoute({
  operationId: "createPageViewLink",
  method: "post",
  path: "/v1/pages/{id}/view-link",
  tags: ["pages"],
  security,
  summary: "A single-use link (60 s) that opens the page in a browser",
  request: { params: idParam, body: jsonBody(PageViewLinkRequest) },
  responses: { 200: jsonResponse("View link", PageViewLink), 401: e401, 404: e404 },
});

export const updatePage = createRoute({
  operationId: "updatePage",
  method: "patch",
  path: "/v1/pages/{id}",
  tags: ["pages"],
  security,
  summary: "Change who can open a page; making it public returns a new link",
  request: { params: idParam, body: jsonBody(UpdatePageRequest) },
  responses: { 200: jsonResponse("Page", UpdatePageResponse), 401: e401, 403: e403, 404: e404 },
});

export const revertPage = createRoute({
  operationId: "revertPage",
  method: "post",
  path: "/v1/pages/{id}/revert",
  tags: ["pages"],
  security,
  summary: "Bring back an earlier version (as a new version)",
  request: { params: idParam, body: jsonBody(RevertPageRequest) },
  responses: { 200: jsonResponse("Page", Page), 401: e401, 403: e403, 404: e404 },
});

export const deletePage = createRoute({
  operationId: "deletePage",
  method: "delete",
  path: "/v1/pages/{id}",
  tags: ["pages"],
  security,
  request: { params: idParam },
  responses: {
    200: jsonResponse("Deleted", z.object({ deleted: Uuid }).openapi("DeletedPage")),
    401: e401,
    403: e403,
    404: e404,
  },
});
