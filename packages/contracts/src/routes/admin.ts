import { createRoute, z } from "@hono/zod-openapi";
import {
  AbuseEvent,
  AdminCreditPack,
  AdminOrg,
  AdminOverview,
  AdminPlan,
  AdminPricing,
  AdminService,
  AdminUser,
  BillingSettings,
  CloudModels,
  ConnectionSettings,
  SaveCreditPackRequest,
  SavePlanRequest,
  ServerCapacity,
  SetConnectionSettingsRequest,
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

export const adminConnectionSettings = get(
  "adminConnectionSettings",
  "/v1/admin/connections",
  "How apps without their own sign-in connect (owner only)",
  ConnectionSettings,
);

export const adminCloudModels = get(
  "adminCloudModels",
  "/v1/admin/models",
  "The models Casama Cloud runs (owner only)",
  CloudModels,
);

export const setAdminCloudModels = createRoute({
  operationId: "setAdminCloudModels",
  method: "put",
  path: "/v1/admin/models",
  tags: ["admin"],
  security,
  summary: "Change the models Casama Cloud runs (owner only)",
  request: { body: jsonBody(CloudModels) },
  responses: { 200: jsonResponse("Updated", CloudModels), 401: e401, 403: e403 },
});

export const setAdminConnectionSettings = createRoute({
  operationId: "setAdminConnectionSettings",
  method: "put",
  path: "/v1/admin/connections",
  tags: ["admin"],
  security,
  summary: "Choose how apps without their own sign-in connect (owner only)",
  request: { body: jsonBody(SetConnectionSettingsRequest) },
  responses: { 200: jsonResponse("Updated", ConnectionSettings), 401: e401, 403: e403 },
});

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

const PlanCode = z.object({ code: z.string().regex(/^[a-z0-9_]{1,40}$/) });

export const adminCapacity = get(
  "adminCapacity",
  "/v1/admin/capacity",
  "Server capacity: host memory, computers' share of their budget, 30-day peaks and a forecast (owner only)",
  ServerCapacity,
);

export const adminPricing = get(
  "adminPricing",
  "/v1/admin/pricing",
  "Plans, credit packs and the usage markup (owner only)",
  AdminPricing,
);

export const savePlan = createRoute({
  operationId: "savePlan",
  method: "put",
  path: "/v1/admin/plans/{code}",
  tags: ["admin"],
  security,
  summary: "Create or change a plan; workspaces on it get the new limits right away",
  request: { params: PlanCode, body: jsonBody(SavePlanRequest) },
  responses: { 200: jsonResponse("Saved", AdminPlan), 401: e401, 403: e403, 404: e404 },
});

export const saveCreditPack = createRoute({
  operationId: "saveCreditPack",
  method: "put",
  path: "/v1/admin/credit-packs/{code}",
  tags: ["admin"],
  security,
  summary: "Create or change a credit pack",
  request: { params: PlanCode, body: jsonBody(SaveCreditPackRequest) },
  responses: { 200: jsonResponse("Saved", AdminCreditPack), 401: e401, 403: e403, 404: e404 },
});

export const setBillingSettings = createRoute({
  operationId: "setBillingSettings",
  method: "patch",
  path: "/v1/admin/billing-settings",
  tags: ["admin"],
  security,
  summary: "Change the markup on usage paid with Casama's keys",
  request: { body: jsonBody(BillingSettings) },
  responses: { 200: jsonResponse("Saved", BillingSettings), 401: e401, 403: e403 },
});
