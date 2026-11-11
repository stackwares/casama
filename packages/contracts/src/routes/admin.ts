import { createRoute, z } from "@hono/zod-openapi";
import {
  AbuseEvent,
  AdminOrg,
  AdminOverview,
  AdminService,
  AdminUser,
  SetOrgLimitsRequest,
  SuspendOrgRequest,
  UpdateNotice,
} from "../admin.ts";
import { jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";

const security = [{ bearerAuth: [] }];
const { 401: e401, 403: e403, 404: e404 } = problemResponses;
const get = <T extends z.ZodType>(operationId: string, path: string, summary: string, schema: T) =>
  createRoute({
    operationId,
    method: "get",
    path,
    tags: ["admin"],
    security,
    summary,
    responses: { 200: jsonResponse(summary, schema), 401: e401, 403: e403 },
  });

export const adminOverview = get(
  "adminOverview",
  "/v1/admin/overview",
  "Instance totals (owner only)",
  AdminOverview,
);
export const adminUsers = get(
  "adminUsers",
  "/v1/admin/users",
  "Everyone on this instance",
  z.object({ items: z.array(AdminUser) }).openapi("AdminUserList"),
);
export const adminOrgs = get(
  "adminOrgs",
  "/v1/admin/orgs",
  "Workspaces with their limits and spend",
  z.object({ items: z.array(AdminOrg) }).openapi("AdminOrgList"),
);
export const adminServices = get(
  "adminServices",
  "/v1/admin/services",
  "Configured providers and system health",
  z.object({ items: z.array(AdminService) }).openapi("AdminServiceList"),
);
export const adminUpdates = get(
  "adminUpdates",
  "/v1/admin/updates",
  "Whether a newer Casama release exists",
  UpdateNotice,
);

export const setOrgLimits = createRoute({
  operationId: "setOrgLimits",
  method: "patch",
  path: "/v1/admin/orgs/{id}/limits",
  tags: ["admin"],
  security,
  summary: "Set a workspace's quotas",
  request: { params: z.object({ id: Uuid }), body: jsonBody(SetOrgLimitsRequest) },
  responses: { 200: jsonResponse("Updated", AdminOrg), 401: e401, 403: e403, 404: e404 },
});

export const adminAbuseEvents = get(
  "adminAbuseEvents",
  "/v1/admin/abuse",
  "Recent abuse signals and actions (owner only)",
  z.object({ items: z.array(AbuseEvent) }).openapi("AbuseEventList"),
);

export const suspendOrg = createRoute({
  operationId: "suspendOrg",
  method: "post",
  path: "/v1/admin/orgs/{id}/suspend",
  tags: ["admin"],
  security,
  summary: "Suspend a workspace: stops its computers and runs, keeps its data",
  request: { params: z.object({ id: Uuid }), body: jsonBody(SuspendOrgRequest) },
  responses: { 200: jsonResponse("Suspended", AdminOrg), 401: e401, 403: e403, 404: e404 },
});

export const unsuspendOrg = createRoute({
  operationId: "unsuspendOrg",
  method: "delete",
  path: "/v1/admin/orgs/{id}/suspend",
  tags: ["admin"],
  security,
  summary: "Lift a workspace's suspension",
  request: { params: z.object({ id: Uuid }) },
  responses: { 200: jsonResponse("Unsuspended", AdminOrg), 401: e401, 403: e403, 404: e404 },
});
