import { createRoute, z } from "@hono/zod-openapi";
import { jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";
import {
  Comp,
  CompCode,
  CompCodePreview,
  CompSettings,
  CreateCompCodeRequest,
  CreatedCompCode,
  GrantCompRequest,
  RedeemCompRequest,
  RedeemedComp,
  UpdateCompCodeRequest,
  UpdateCompRequest,
} from "../comps.ts";

/**
 * Free plans for friends (docs/COMP-PLANS-PLAN.md). Instance owners grant plans and make gift
 * codes; a workspace owner redeems a code on the web.
 */
const security = [{ bearerAuth: [] }];
const tags = ["comps"];
const errors = problemResponses;
const id = z.object({ id: Uuid });

export const adminCompSettings = createRoute({
  operationId: "adminCompSettings",
  method: "get",
  path: "/v1/admin/comp-settings",
  tags,
  security,
  summary: "Free plan settings (instance owner)",
  responses: { ...errors, 200: jsonResponse("Settings", CompSettings) },
});

export const setAdminCompSettings = createRoute({
  operationId: "setAdminCompSettings",
  method: "put",
  path: "/v1/admin/comp-settings",
  tags,
  security,
  summary: "Change free plan settings (instance owner)",
  request: { body: jsonBody(CompSettings) },
  responses: { ...errors, 200: jsonResponse("Settings", CompSettings) },
});

export const listAdminComps = createRoute({
  operationId: "listAdminComps",
  method: "get",
  path: "/v1/admin/comps",
  tags,
  security,
  summary: "Free plans, running first (instance owner)",
  request: {
    query: z.object({
      running: z.enum(["true", "false"]).optional(),
      limit: z.coerce.number().int().min(1).max(500).optional(),
    }),
  },
  responses: { ...errors, 200: jsonResponse("Free plans", z.array(Comp)) },
});

export const grantAdminComp = createRoute({
  operationId: "grantAdminComp",
  method: "post",
  path: "/v1/admin/comps",
  tags,
  security,
  summary: "Give someone a plan free for some months (instance owner)",
  description:
    "Errors: 409 comps_off, 400 plan_not_allowed, 400 months_not_allowed, 404 user_not_found, 409 account_banned, 409 no_workspace, 409 comp_exists, 409 already_paying, 409 comp_limit.",
  request: { body: jsonBody(GrantCompRequest) },
  responses: { ...errors, 200: jsonResponse("Free plan", Comp) },
});

export const updateAdminComp = createRoute({
  operationId: "updateAdminComp",
  method: "patch",
  path: "/v1/admin/comps/{id}",
  tags,
  security,
  summary: "Extend or end a free plan (instance owner)",
  request: { params: id, body: jsonBody(UpdateCompRequest) },
  responses: { ...errors, 200: jsonResponse("Free plan", Comp) },
});

export const listAdminCompCodes = createRoute({
  operationId: "listAdminCompCodes",
  method: "get",
  path: "/v1/admin/comp-codes",
  tags,
  security,
  summary: "Gift codes and how often they were used (instance owner)",
  responses: { ...errors, 200: jsonResponse("Gift codes", z.array(CompCode)) },
});

export const createAdminCompCode = createRoute({
  operationId: "createAdminCompCode",
  method: "post",
  path: "/v1/admin/comp-codes",
  tags,
  security,
  summary: "Make a gift code for one plan and length; the code is shown only once (instance owner)",
  request: { body: jsonBody(CreateCompCodeRequest) },
  responses: { ...errors, 200: jsonResponse("Gift code", CreatedCompCode) },
});

export const updateAdminCompCode = createRoute({
  operationId: "updateAdminCompCode",
  method: "patch",
  path: "/v1/admin/comp-codes/{id}",
  tags,
  security,
  summary: "Disable a gift code or change its limits (instance owner)",
  request: { params: id, body: jsonBody(UpdateCompCodeRequest) },
  responses: { ...errors, 200: jsonResponse("Gift code", CompCode) },
});

export const previewCompCode = createRoute({
  operationId: "previewCompCode",
  method: "get",
  path: "/v1/comp/preview",
  tags,
  summary: "What a gift code gives (no sign-in)",
  request: { query: z.object({ code: z.string().min(1).max(200) }) },
  responses: { ...errors, 200: jsonResponse("Gift code", CompCodePreview) },
});

export const redeemCompCode = createRoute({
  operationId: "redeemCompCode",
  method: "post",
  path: "/v1/me/comp/redeem",
  tags,
  security,
  summary: "Redeem a gift code into a workspace you own (web and desktop only)",
  description:
    "Errors: 404 comp_code_invalid, 409 comp_code_expired, 409 comp_code_used_up, 409 comp_code_used, 409 comp_exists, 409 already_paying, 409 comp_limit, 409 comps_off, 403 forbidden, 429 too_many_attempts.",
  request: { body: jsonBody(RedeemCompRequest) },
  responses: { ...errors, 200: jsonResponse("Free plan", RedeemedComp) },
});
