import { createRoute, z } from "@hono/zod-openapi";
import { jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";
import {
  AccountDeletion,
  DeleteAccountRequest,
  OrgSettings,
  UpdateOrgSettingsRequest,
} from "../privacy.ts";

const security = [{ bearerAuth: [] }];
const { 400: e400, 401: e401, 403: e403, 404: e404 } = problemResponses;
const tags = ["privacy"];

export const exportMyData = createRoute({
  operationId: "exportMyData",
  method: "get",
  path: "/v1/me/export",
  tags,
  security,
  summary: "Download everything you can see as a ZIP of JSON files",
  responses: {
    200: {
      description: "ZIP archive",
      content: { "application/zip": { schema: z.string().openapi({ format: "binary" }) } },
    },
    401: e401,
  },
});

export const deleteMyAccount = createRoute({
  operationId: "deleteMyAccount",
  method: "delete",
  path: "/v1/me",
  tags,
  security,
  summary:
    "Delete your account: you are signed out now, and your data, workspaces you solely own and their computer snapshots are purged after the grace period",
  request: { body: jsonBody(DeleteAccountRequest) },
  responses: { 200: jsonResponse("Scheduled", AccountDeletion), 400: e400, 401: e401 },
});

export const renameTwoStepFactor = createRoute({
  operationId: "renameTwoStepFactor",
  method: "patch",
  path: "/v1/me/two-step/{id}",
  tags,
  security,
  summary: "Rename one of your authenticator apps (two-step sign-in)",
  request: {
    params: z.object({ id: Uuid }),
    body: jsonBody(z.object({ name: z.string().trim().min(1).max(60) })),
  },
  responses: { 204: { description: "Renamed" }, 400: e400, 401: e401, 404: e404 },
});

export const getOrgSettings = createRoute({
  operationId: "getOrgSettings",
  method: "get",
  path: "/v1/orgs/{id}/settings",
  tags,
  security,
  request: { params: z.object({ id: Uuid }) },
  responses: { 200: jsonResponse("Settings", OrgSettings), 401: e401, 404: e404 },
});

export const updateOrgSettings = createRoute({
  operationId: "updateOrgSettings",
  method: "patch",
  path: "/v1/orgs/{id}/settings",
  tags,
  security,
  summary: "Change workspace settings such as run event retention (admins)",
  request: { params: z.object({ id: Uuid }), body: jsonBody(UpdateOrgSettingsRequest) },
  responses: {
    200: jsonResponse("Settings", OrgSettings),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
  },
});

export const setAnalyticsOptOut = createRoute({
  operationId: "setAnalyticsOptOut",
  method: "post",
  path: "/v1/me/analytics-opt-out",
  tags,
  security,
  summary: "Update the user's analytics opt-out preference",
  request: { body: jsonBody(z.object({ opt_out: z.boolean() })) },
  responses: { 204: { description: "Updated" }, 401: e401 },
});
