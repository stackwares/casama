import { createRoute, z } from "@hono/zod-openapi";
import { jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";
import {
  LimitResetCampaign,
  LimitResetCampaignInput,
  LimitResetEvent,
  LimitResetPreview,
  LimitResetSettings,
  SavedLimitReset,
} from "../limit-resets.ts";

const security = [{ bearerAuth: [] }];
const tags = ["limit-resets"];
const base = "/v1/admin/limit-resets";
const errors = problemResponses;
const id = z.object({ id: Uuid });
export const listSavedLimitResets = createRoute({
  operationId: "listSavedLimitResets",
  method: "get",
  path: "/v1/orgs/{id}/billing/resets",
  tags,
  security,
  summary: "Saved resets for a workspace",
  request: { params: id },
  responses: { ...errors, 200: jsonResponse("Saved resets", z.array(SavedLimitReset)) },
});
export const redeemSavedLimitReset = createRoute({
  operationId: "redeemSavedLimitReset",
  method: "post",
  path: "/v1/orgs/{id}/billing/resets/redeem",
  tags,
  security,
  summary: "Use the first expiring reset as the workspace owner",
  request: { params: id },
  responses: {
    ...errors,
    200: jsonResponse("Refill", z.object({ reset_id: Uuid, refilled_usd: z.number() })),
  },
});
export const adminLimitResetSettings = createRoute({
  operationId: "adminLimitResetSettings",
  method: "get",
  path: `${base}/settings`,
  tags,
  security,
  summary: "Saved reset settings (instance owner)",
  responses: { ...errors, 200: jsonResponse("Settings", LimitResetSettings) },
});
export const setAdminLimitResetSettings = createRoute({
  operationId: "setAdminLimitResetSettings",
  method: "put",
  path: `${base}/settings`,
  tags,
  security,
  summary: "Change saved reset settings (instance owner)",
  request: { body: jsonBody(LimitResetSettings) },
  responses: { ...errors, 200: jsonResponse("Settings", LimitResetSettings) },
});
export const adminLimitResetCampaigns = createRoute({
  operationId: "adminLimitResetCampaigns",
  method: "get",
  path: base,
  tags,
  security,
  summary: "List reset campaigns (instance owner)",
  responses: { ...errors, 200: jsonResponse("Campaigns", z.array(LimitResetCampaign)) },
});
export const previewAdminLimitResetCampaign = createRoute({
  operationId: "previewAdminLimitResetCampaign",
  method: "post",
  path: `${base}/preview`,
  tags,
  security,
  summary: "Preview audience and maximum refill cost (instance owner)",
  request: { body: jsonBody(LimitResetCampaignInput) },
  responses: { ...errors, 200: jsonResponse("Preview", LimitResetPreview) },
});
export const createAdminLimitResetCampaign = createRoute({
  operationId: "createAdminLimitResetCampaign",
  method: "post",
  path: base,
  tags,
  security,
  summary: "Create a draft reset campaign (instance owner)",
  request: { body: jsonBody(LimitResetCampaignInput) },
  responses: { ...errors, 200: jsonResponse("Campaign", LimitResetCampaign) },
});
export const updateAdminLimitResetCampaign = createRoute({
  operationId: "updateAdminLimitResetCampaign",
  method: "put",
  path: `${base}/{id}`,
  tags,
  security,
  summary: "Edit a reset campaign (instance owner)",
  request: { params: id, body: jsonBody(LimitResetCampaignInput) },
  responses: { ...errors, 200: jsonResponse("Campaign", LimitResetCampaign) },
});
export const actionAdminLimitResetCampaign = createRoute({
  operationId: "actionAdminLimitResetCampaign",
  method: "post",
  path: `${base}/{id}/action`,
  tags,
  security,
  summary: "Schedule, pause, resume, cancel or delete a draft (instance owner)",
  request: {
    params: id,
    body: jsonBody(
      z.object({ action: z.enum(["schedule", "pause", "resume", "cancel", "delete"]) }),
    ),
  },
  responses: { ...errors, 200: jsonResponse("Done", z.object({ ok: z.boolean() })) },
});
export const adminWorkspaceLimitResets = createRoute({
  operationId: "adminWorkspaceLimitResets",
  method: "get",
  path: `${base}/workspaces/{id}`,
  tags,
  security,
  summary: "Workspace reset history (instance owner)",
  request: { params: id },
  responses: { ...errors, 200: jsonResponse("History", z.array(LimitResetEvent)) },
});
export const giveAdminWorkspaceLimitReset = createRoute({
  operationId: "giveAdminWorkspaceLimitReset",
  method: "post",
  path: `${base}/workspaces/{id}`,
  tags,
  security,
  summary: "Give a one-off reset (instance owner)",
  request: { params: id, body: jsonBody(LimitResetCampaignInput) },
  responses: { ...errors, 200: jsonResponse("Campaign", LimitResetCampaign) },
});
export const actionAdminWorkspaceLimitReset = createRoute({
  operationId: "actionAdminWorkspaceLimitReset",
  method: "post",
  path: `${base}/resets/{id}/action`,
  tags,
  security,
  summary: "Revoke an unused reset or undo unspent refill credit (instance owner)",
  request: { params: id, body: jsonBody(z.object({ action: z.enum(["revoke", "undo"]) })) },
  responses: { ...errors, 200: jsonResponse("Done", z.object({ ok: z.boolean() })) },
});
export const adminLimitResetEvents = createRoute({
  operationId: "adminLimitResetEvents",
  method: "get",
  path: `${base}/events`,
  tags,
  security,
  summary: "Append-only reset log (instance owner)",
  request: {
    query: z.object({
      campaign_id: Uuid.optional(),
      org_id: Uuid.optional(),
      limit: z.coerce.number().int().min(1).max(1000).default(100),
    }),
  },
  responses: { ...errors, 200: jsonResponse("Events", z.array(LimitResetEvent)) },
});
export const exportAdminLimitResetEvents = createRoute({
  operationId: "exportAdminLimitResetEvents",
  method: "get",
  path: `${base}/events.csv`,
  tags,
  security,
  summary: "Export the full saved-reset audit log as CSV (instance owner)",
  request: { query: z.object({ campaign_id: Uuid.optional(), org_id: Uuid.optional() }) },
  responses: {
    ...errors,
    200: { description: "Audit CSV", content: { "text/csv": { schema: z.string() } } },
  },
});
