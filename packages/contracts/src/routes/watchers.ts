import { createRoute, z } from "@hono/zod-openapi";
import { jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";
import { UpdateWatcherRequest, Watcher } from "../watchers.ts";

const security = [{ bearerAuth: [] }];
const { 401: e401, 404: e404 } = problemResponses;
const idParam = z.object({ id: Uuid });

export const listWatchers = createRoute({
  operationId: "listWatchers",
  method: "get",
  path: "/v1/watchers",
  tags: ["watchers"],
  security,
  request: { query: z.object({ bot_id: Uuid }) },
  responses: {
    200: jsonResponse("Watchers", z.object({ items: z.array(Watcher) }).openapi("WatcherList")),
    401: e401,
  },
});

export const updateWatcher = createRoute({
  operationId: "updateWatcher",
  method: "patch",
  path: "/v1/watchers/{id}",
  tags: ["watchers"],
  security,
  summary: "Pause or resume a watcher",
  request: { params: idParam, body: jsonBody(UpdateWatcherRequest) },
  responses: { 200: jsonResponse("Watcher", Watcher), 401: e401, 404: e404 },
});

export const deleteWatcher = createRoute({
  operationId: "deleteWatcher",
  method: "delete",
  path: "/v1/watchers/{id}",
  tags: ["watchers"],
  security,
  request: { params: idParam },
  responses: {
    200: jsonResponse("Deleted", z.object({ deleted: Uuid }).openapi("DeletedWatcher")),
    401: e401,
    404: e404,
  },
});
