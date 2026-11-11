import { createRoute, z } from "@hono/zod-openapi";
import { jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";
import {
  InstallPluginRequest,
  Plugin,
  PluginPreview,
  PluginUpdatePreview,
  PreviewPluginRequest,
  UpdatePluginRequest,
} from "../plugins.ts";

const security = [{ bearerAuth: [] }];
const { 400: e400, 401: e401, 403: e403, 404: e404, 409: e409 } = problemResponses;
const idParam = z.object({ id: Uuid });
const tags = ["plugins"];

export const previewPlugin = createRoute({
  operationId: "previewPlugin",
  method: "post",
  path: "/v1/plugins/preview",
  tags,
  security,
  summary: "What an Agent Plugins 1.0 package from GitHub would add",
  request: { body: jsonBody(PreviewPluginRequest) },
  responses: { 200: jsonResponse("Preview", PluginPreview), 400: e400, 401: e401, 404: e404 },
});

export const installPlugin = createRoute({
  operationId: "installPlugin",
  method: "post",
  path: "/v1/plugins",
  tags,
  security,
  summary: "Install a plugin for a bot, pinned to the previewed commit",
  request: { body: jsonBody(InstallPluginRequest) },
  responses: {
    201: jsonResponse("Installed", Plugin),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
    409: e409,
  },
});

export const listPlugins = createRoute({
  operationId: "listPlugins",
  method: "get",
  path: "/v1/plugins",
  tags,
  security,
  request: { query: z.object({ bot_id: Uuid }) },
  responses: {
    200: jsonResponse("Plugins", z.object({ items: z.array(Plugin) }).openapi("PluginList")),
    401: e401,
  },
});

export const getPluginUpdate = createRoute({
  operationId: "getPluginUpdate",
  method: "get",
  path: "/v1/plugins/{id}/update",
  tags,
  security,
  summary: "The latest commit of the plugin's source and what changes",
  request: { params: idParam },
  responses: { 200: jsonResponse("Update", PluginUpdatePreview), 401: e401, 404: e404 },
});

export const updatePlugin = createRoute({
  operationId: "updatePlugin",
  method: "post",
  path: "/v1/plugins/{id}/update",
  tags,
  security,
  request: { params: idParam, body: jsonBody(UpdatePluginRequest) },
  responses: {
    200: jsonResponse("Updated", Plugin),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
    409: e409,
  },
});

export const uninstallPlugin = createRoute({
  operationId: "uninstallPlugin",
  method: "delete",
  path: "/v1/plugins/{id}",
  tags,
  security,
  summary: "Remove the plugin and everything it added",
  request: { params: idParam },
  responses: {
    200: jsonResponse("Removed", z.object({ deleted: Uuid }).openapi("DeletedPlugin")),
    401: e401,
    403: e403,
    404: e404,
  },
});
