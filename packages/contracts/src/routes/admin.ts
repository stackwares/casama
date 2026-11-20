import { createRoute, z } from "@hono/zod-openapi";
import {
  AbuseEvent,
  AdminBotSetting,
  AdminCheck,
  AdminCreditPack,
  AdminMailAddress,
  AdminMailReservedNames,
  AdminMargin,
  AdminOrg,
  AdminOverview,
  AdminPasskeyCheckRequest,
  AdminPinCheckRequest,
  AdminPinState,
  AdminPlan,
  AdminPricing,
  AdminService,
  AdminUser,
  BillingSettings,
  CloudModels,
  ConnectionSettings,
  ReportedCreation,
  SaveCreditPackRequest,
  SavePlanRequest,
  ServerCapacity,
  SetAdminBotRequest,
  SetAdminPinRequest,
  SetConnectionSettingsRequest,
  SetMailAddressStatusRequest,
  SetOrgLimitsRequest,
  SuspendOrgRequest,
  UpdateNotice,
} from "../admin.ts";
import { jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";
import { AdminVendor, VendorSettings } from "../vendors.ts";

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
export const adminMargin = createRoute({
  operationId: "adminMargin",
  method: "get",
  path: "/v1/admin/margin",
  tags: ["admin"],
  security,
  summary: "Usage charged against what it cost the server (owner only)",
  request: {
    query: z.object({ days: z.coerce.number().int().min(1).max(90).optional() }),
  },
  responses: {
    200: jsonResponse("Usage charged against its cost", AdminMargin),
    401: e401,
    403: e403,
  },
});
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

export const adminBot = get(
  "adminBot",
  "/v1/admin/admin-bot",
  "The admin bot: which bot may propose admin actions in the owner's chat (owner only)",
  AdminBotSetting,
);

export const setAdminBot = createRoute({
  operationId: "setAdminBot",
  method: "put",
  path: "/v1/admin/admin-bot",
  tags: ["admin"],
  security,
  summary: "Turn the admin bot on or off, or choose its bot (owner only)",
  description:
    "Every admin action the bot proposes still waits for the owner's approval in the app (D-435).",
  request: { body: jsonBody(SetAdminBotRequest) },
  responses: {
    200: jsonResponse("Updated", AdminBotSetting),
    400: problemResponses[400],
    401: e401,
    403: e403,
  },
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

export const listReportedCreations = createRoute({
  operationId: "listReportedCreations",
  method: "get",
  path: "/v1/admin/reports",
  tags: ["admin"],
  security,
  summary: "Public links people reported, most reported first (owner only; D-281)",
  responses: {
    200: jsonResponse(
      "Reports",
      z.object({ items: z.array(ReportedCreation) }).openapi("ReportedCreationList"),
    ),
    401: e401,
    403: e403,
  },
});

export const takeDownCreation = createRoute({
  operationId: "takeDownCreation",
  method: "post",
  path: "/v1/admin/creations/{id}/takedown",
  tags: ["admin"],
  security,
  summary: "Stop a creation's public link at once, or lift that (owner only; D-281)",
  request: {
    params: z.object({ id: Uuid }),
    body: jsonBody(z.object({ down: z.boolean() }).openapi("TakeDownRequest")),
  },
  responses: { 200: jsonResponse("Done", ReportedCreation), 401: e401, 403: e403, 404: e404 },
});

export const adminVendors = get(
  "adminVendors",
  "/v1/admin/vendors",
  "Vendor usage (owner only)",
  z.object({ items: z.array(AdminVendor) }).openapi("AdminVendorList"),
);
export const setAdminVendor = createRoute({
  operationId: "setAdminVendor",
  method: "put",
  path: "/v1/admin/vendors/{vendor}",
  tags: ["admin"],
  security,
  request: {
    params: z.object({ vendor: z.string().min(1).max(80) }),
    body: jsonBody(VendorSettings),
  },
  responses: { 200: jsonResponse("Updated vendor", AdminVendor), ...problemResponses },
});
export const checkAdminVendor = createRoute({
  operationId: "checkAdminVendor",
  method: "post",
  path: "/v1/admin/vendors/{vendor}/check",
  tags: ["admin"],
  security,
  request: { params: z.object({ vendor: z.string().min(1).max(80) }) },
  responses: { 200: jsonResponse("Latest vendor reading", AdminVendor), ...problemResponses },
});

export const adminMailAddresses = createRoute({
  operationId: "adminMailAddresses",
  method: "get",
  path: "/v1/admin/mail",
  tags: ["admin"],
  security,
  summary: "Hosted bot addresses with recent sending health (owner only)",
  responses: {
    200: jsonResponse(
      "Mail addresses",
      z.object({
        items: z.array(AdminMailAddress),
        /** Mails every workspace sent in the last 24 hours. */
        sent_today: z.number().int().optional(),
        /** The day's ceiling across every workspace (MAIL_SEND_DAILY_MAX); null: none. */
        send_ceiling: z.number().int().nullable().optional(),
      }),
    ),
    401: e401,
    403: e403,
  },
});

export const setMailAddressStatus = createRoute({
  operationId: "setMailAddressStatus",
  method: "patch",
  path: "/v1/admin/mail/addresses/{id}",
  tags: ["admin"],
  security,
  summary: "Pause an address, or lift a pause including an automatic one (owner only)",
  request: { params: z.object({ id: Uuid }), body: jsonBody(SetMailAddressStatusRequest) },
  responses: {
    200: jsonResponse("Mail address", AdminMailAddress),
    401: e401,
    403: e403,
    404: e404,
  },
});

export const adminMailReservedNames = createRoute({
  operationId: "adminMailReservedNames",
  method: "get",
  path: "/v1/admin/mail-reserved-names",
  tags: ["admin"],
  security,
  summary: "Instance-added reserved mail names (owner only)",
  responses: { 200: jsonResponse("Reserved names", AdminMailReservedNames), 401: e401, 403: e403 },
});

export const setMailReservedNames = createRoute({
  operationId: "setMailReservedNames",
  method: "put",
  path: "/v1/admin/mail-reserved-names",
  tags: ["admin"],
  security,
  summary: "Replace the instance-added reserved mail names (owner only)",
  request: { body: jsonBody(AdminMailReservedNames) },
  responses: { 200: jsonResponse("Reserved names", AdminMailReservedNames), 401: e401, 403: e403 },
});

// --- Admin checks (D-452): a passkey or the admin PIN instead of signing in again --------------

export const adminPin = createRoute({
  operationId: "adminPin",
  method: "get",
  path: "/v1/admin/pin",
  tags: ["admin"],
  security,
  summary: "Whether the owner has an admin PIN (owner only)",
  responses: { 200: jsonResponse("Admin PIN", AdminPinState), 401: e401, 403: e403 },
});

export const setAdminPin = createRoute({
  operationId: "setAdminPin",
  method: "put",
  path: "/v1/admin/pin",
  tags: ["admin"],
  security,
  summary: "Set or change the admin PIN (owner only; a fresh passkey or sign-in, not the PIN)",
  request: { body: jsonBody(SetAdminPinRequest) },
  responses: { 200: jsonResponse("Admin PIN", AdminPinState), ...problemResponses },
});

export const removeAdminPin = createRoute({
  operationId: "removeAdminPin",
  method: "delete",
  path: "/v1/admin/pin",
  tags: ["admin"],
  security,
  summary: "Remove the admin PIN (owner only; a fresh passkey or sign-in, not the PIN)",
  responses: { 200: jsonResponse("Admin PIN", AdminPinState), ...problemResponses },
});

export const adminPasskeyCheck = createRoute({
  operationId: "adminPasskeyCheck",
  method: "post",
  path: "/v1/admin/checks/passkey",
  tags: ["admin"],
  security,
  summary: "Record a passkey check on this sign-in session (owner only)",
  request: { body: jsonBody(AdminPasskeyCheckRequest) },
  responses: { 200: jsonResponse("Check recorded", AdminCheck), ...problemResponses },
});

export const adminPinCheck = createRoute({
  operationId: "adminPinCheck",
  method: "post",
  path: "/v1/admin/checks/pin",
  tags: ["admin"],
  security,
  summary: "Check the admin PIN and record it on this sign-in session (owner only)",
  request: { body: jsonBody(AdminPinCheckRequest) },
  responses: { 200: jsonResponse("Check recorded", AdminCheck), ...problemResponses },
});
