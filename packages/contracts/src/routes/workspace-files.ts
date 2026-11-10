import { createRoute, z } from "@hono/zod-openapi";
import { jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";
import { GitSyncStatus, ImportWorkspaceFilesRequest, SetGitSyncRequest, WorkspaceFilesExport, WorkspaceFilesResult } from "../workspace-files.ts";

const security = [{ bearerAuth: [] }];
const { 400: e400, 401: e401, 403: e403, 404: e404 } = problemResponses;
const idParam = z.object({ id: Uuid });
const tags = ["files"];

export const exportWorkspaceFiles = createRoute({
  operationId: "exportWorkspaceFiles",
  method: "post",
  path: "/v1/orgs/{id}/files/export",
  tags,
  security,
  summary: "Routines and skills as Markdown files, zipped (D-124)",
  request: { params: idParam },
  responses: { 200: jsonResponse("ZIP", WorkspaceFilesExport), 401: e401, 403: e403 },
});

export const importWorkspaceFiles = createRoute({
  operationId: "importWorkspaceFiles",
  method: "post",
  path: "/v1/orgs/{id}/files/import",
  tags,
  security,
  summary: "Create and update routines and skills from files (dry_run shows what would change)",
  request: { params: idParam, body: jsonBody(ImportWorkspaceFilesRequest) },
  responses: { 200: jsonResponse("Result", WorkspaceFilesResult), 400: e400, 401: e401, 403: e403 },
});

export const getGitSync = createRoute({
  operationId: "getGitSync",
  method: "get",
  path: "/v1/orgs/{id}/git-sync",
  tags,
  security,
  request: { params: idParam },
  responses: { 200: jsonResponse("Git sync", GitSyncStatus), 401: e401, 403: e403 },
});

export const setGitSync = createRoute({
  operationId: "setGitSync",
  method: "put",
  path: "/v1/orgs/{id}/git-sync",
  tags,
  security,
  request: { params: idParam, body: jsonBody(SetGitSyncRequest) },
  responses: { 200: jsonResponse("Git sync", GitSyncStatus), 400: e400, 401: e401, 403: e403 },
});

export const runGitSync = createRoute({
  operationId: "runGitSync",
  method: "post",
  path: "/v1/orgs/{id}/git-sync/run",
  tags,
  security,
  summary: "Sync on the worker's next minute",
  request: { params: idParam },
  responses: { 200: jsonResponse("Git sync", GitSyncStatus), 401: e401, 403: e403, 404: e404 },
});

export const deleteGitSync = createRoute({
  operationId: "deleteGitSync",
  method: "delete",
  path: "/v1/orgs/{id}/git-sync",
  tags,
  security,
  request: { params: idParam },
  responses: { 200: jsonResponse("Git sync", GitSyncStatus), 401: e401, 403: e403 },
});
