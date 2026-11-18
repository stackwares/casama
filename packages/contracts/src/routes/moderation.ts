import { createRoute, z } from "@hono/zod-openapi";
import { jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";
import {
  BlockedPerson,
  BlockRequest,
  ContentReport,
  CreateReportRequest,
  EmailPreferences,
  NewsletterStatus,
  ReportReceipt,
  ReviewReportRequest,
  SetNewsletterRequest,
} from "../moderation.ts";

/**
 * Reporting and blocking (D-301), and account email preferences (D-302). Store rules for apps
 * with content from other people: a way to report it, a way to block people, and someone who acts.
 */
const security = [{ bearerAuth: [] }];
const { 400: e400, 401: e401, 403: e403, 404: e404, 429: e429 } = problemResponses;

export const createReport = createRoute({
  operationId: "createReport",
  method: "post",
  path: "/v1/reports",
  tags: ["moderation"],
  security,
  summary: "Report something or someone to the people who run this server",
  request: { body: jsonBody(CreateReportRequest) },
  responses: {
    200: jsonResponse("Reported", ReportReceipt),
    400: e400,
    401: e401,
    404: e404,
    429: e429,
  },
});

export const listBlocks = createRoute({
  operationId: "listBlocks",
  method: "get",
  path: "/v1/me/blocks",
  tags: ["moderation"],
  security,
  summary: "People you blocked",
  responses: {
    200: jsonResponse(
      "Blocked",
      z.object({ items: z.array(BlockedPerson) }).openapi("BlockedPersonList"),
    ),
    401: e401,
  },
});

export const blockPerson = createRoute({
  operationId: "blockPerson",
  method: "post",
  path: "/v1/me/blocks",
  tags: ["moderation"],
  security,
  summary: "Block someone: no invites or agent links from them, and their messages hidden",
  request: { body: jsonBody(BlockRequest) },
  responses: { 200: jsonResponse("Blocked", BlockedPerson), 400: e400, 401: e401, 404: e404 },
});

export const unblockPerson = createRoute({
  operationId: "unblockPerson",
  method: "delete",
  path: "/v1/me/blocks/{user_id}",
  tags: ["moderation"],
  security,
  request: { params: z.object({ user_id: Uuid }) },
  responses: { 204: { description: "Unblocked" }, 401: e401 },
});

export const listContentReports = createRoute({
  operationId: "listContentReports",
  method: "get",
  path: "/v1/admin/content-reports",
  tags: ["admin"],
  security,
  summary: "Reports from inside the app, open first (instance owners)",
  request: {
    query: z.object({ status: z.enum(["open", "actioned", "dismissed", "all"]).optional() }),
  },
  responses: {
    200: jsonResponse(
      "Reports",
      z.object({ items: z.array(ContentReport) }).openapi("ContentReportList"),
    ),
    401: e401,
    403: e403,
  },
});

export const reviewContentReport = createRoute({
  operationId: "reviewContentReport",
  method: "post",
  path: "/v1/admin/content-reports/{id}",
  tags: ["admin"],
  security,
  summary: "Close a report: acted on (optionally suspending the workspace) or dismissed",
  request: { params: z.object({ id: Uuid }), body: jsonBody(ReviewReportRequest) },
  responses: { 200: jsonResponse("Report", ContentReport), 401: e401, 403: e403, 404: e404 },
});

export const getEmailPreferences = createRoute({
  operationId: "getEmailPreferences",
  method: "get",
  path: "/v1/me/email-preferences",
  tags: ["account"],
  security,
  responses: { 200: jsonResponse("Email preferences", EmailPreferences), 401: e401 },
});

export const setEmailPreferences = createRoute({
  operationId: "setEmailPreferences",
  method: "put",
  path: "/v1/me/email-preferences",
  tags: ["account"],
  security,
  request: { body: jsonBody(EmailPreferences) },
  responses: { 200: jsonResponse("Email preferences", EmailPreferences), 400: e400, 401: e401 },
});

export const getNewsletter = createRoute({
  operationId: "getNewsletter",
  method: "get",
  path: "/v1/me/newsletter",
  tags: ["account"],
  security,
  summary: "Whether you get Casama's monthly email, and whether this server sends it",
  responses: { 200: jsonResponse("Monthly email", NewsletterStatus), 401: e401 },
});

export const setNewsletter = createRoute({
  operationId: "setNewsletter",
  method: "put",
  path: "/v1/me/newsletter",
  tags: ["account"],
  security,
  summary: "Turn Casama's monthly email on or off (only on servers that send it)",
  request: { body: jsonBody(SetNewsletterRequest) },
  responses: {
    200: jsonResponse("Monthly email", NewsletterStatus),
    400: e400,
    401: e401,
    404: e404,
  },
});
