import { createRoute } from "@hono/zod-openapi";
import { jsonBody, jsonResponse, problemResponses } from "../common.ts";
import {
  EmailCopySettings,
  GalleryLists,
  PluginDirectory,
  RemoteAppConfig,
  RoutineIdeaList,
  SetEmailCopyRequest,
  SetRemoteAppConfigRequest,
} from "../gallery-content.ts";

const security = [{ bearerAuth: [] }];
const { 400: e400, 401: e401, 403: e403 } = problemResponses;

export const listRoutineIdeas = createRoute({
  operationId: "listRoutineIdeas",
  method: "get",
  path: "/v1/routine-ideas",
  tags: ["routines"],
  security,
  summary: "Routine ideas from the gallery, to fill in a new routine",
  responses: { 200: jsonResponse("Routine ideas", RoutineIdeaList), 401: e401 },
});

export const listPluginDirectory = createRoute({
  operationId: "listPluginDirectory",
  method: "get",
  path: "/v1/plugin-directory",
  tags: ["plugins"],
  security,
  summary: "Reviewed plugins from the gallery, each pinned to the commit that was reviewed",
  responses: { 200: jsonResponse("Plugins", PluginDirectory), 401: e401 },
});

export const getAppConfig = createRoute({
  operationId: "getAppConfig",
  method: "get",
  path: "/v1/app-config",
  tags: ["system"],
  summary: "Remote app settings: minimum versions, maintenance, announcements, flags (no auth)",
  responses: { 200: jsonResponse("Remote app settings", RemoteAppConfig) },
});

export const adminAppConfig = createRoute({
  operationId: "adminAppConfig",
  method: "get",
  path: "/v1/admin/app-config",
  tags: ["admin"],
  security,
  summary: "Remote app settings (owner only)",
  responses: { 200: jsonResponse("Remote app settings", RemoteAppConfig), 401: e401, 403: e403 },
});

export const adminSetAppConfig = createRoute({
  operationId: "adminSetAppConfig",
  method: "put",
  path: "/v1/admin/app-config",
  tags: ["admin"],
  security,
  summary: "Replace the remote app settings (owner only)",
  request: { body: jsonBody(SetRemoteAppConfigRequest) },
  responses: {
    200: jsonResponse("Remote app settings", RemoteAppConfig),
    400: e400,
    401: e401,
    403: e403,
  },
});

export const listGalleryLists = createRoute({
  operationId: "listGalleryLists",
  method: "get",
  path: "/v1/gallery/lists",
  tags: ["gallery"],
  security,
  summary: "Content lists from the gallery: search words and empty-state starters (D-372)",
  responses: { 200: jsonResponse("Lists", GalleryLists), 401: e401 },
});

export const adminEmailCopy = createRoute({
  operationId: "adminEmailCopy",
  method: "get",
  path: "/v1/admin/email-copy",
  tags: ["admin"],
  security,
  summary: "The words of the welcome emails and gallery digest, and the defaults (owner only)",
  responses: { 200: jsonResponse("Email copy", EmailCopySettings), 401: e401, 403: e403 },
});

export const adminSetEmailCopy = createRoute({
  operationId: "adminSetEmailCopy",
  method: "put",
  path: "/v1/admin/email-copy",
  tags: ["admin"],
  security,
  summary: "Replace the words of the welcome emails and gallery digest (owner only)",
  request: { body: jsonBody(SetEmailCopyRequest) },
  responses: {
    200: jsonResponse("Email copy", EmailCopySettings),
    400: e400,
    401: e401,
    403: e403,
  },
});
