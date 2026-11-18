import { createRoute, z } from "@hono/zod-openapi";
import { jsonBody, jsonResponse, problemResponses } from "../common.ts";
import {
  SupportChatReply,
  SupportChatRequest,
  SupportConfig,
  SupportTicket,
  SupportTicketRequest,
  SupportTicketRow,
  SupportWebChatReply,
  SupportWebChatRequest,
  SupportWebConfig,
  SupportWebSession,
  SupportWebSessionRequest,
  SupportWebStats,
} from "../support.ts";

/**
 * Help & support (D-298): an assistant that knows the docs and can look at the person's own
 * workspace, and a message to the support team that the server emails on their behalf.
 */
const security = [{ bearerAuth: [] }];
const { 400: e400, 401: e401, 403: e403, 404: e404, 429: e429 } = problemResponses;

export const getSupportConfig = createRoute({
  operationId: "getSupportConfig",
  method: "get",
  path: "/v1/support",
  tags: ["support"],
  security,
  summary: "What help this server offers",
  responses: { 200: jsonResponse("Support", SupportConfig), 401: e401 },
});

export const supportChat = createRoute({
  operationId: "supportChat",
  method: "post",
  path: "/v1/support/chat",
  tags: ["support"],
  security,
  summary: "Ask the support assistant",
  request: { body: jsonBody(SupportChatRequest) },
  responses: {
    200: jsonResponse("The assistant's answer", SupportChatReply),
    400: e400,
    401: e401,
    403: e403,
    429: e429,
  },
});

export const createSupportTicket = createRoute({
  operationId: "createSupportTicket",
  method: "post",
  path: "/v1/support/tickets",
  tags: ["support"],
  security,
  summary: "Send a message to the support team",
  request: { body: jsonBody(SupportTicketRequest) },
  responses: {
    200: jsonResponse("Sent", SupportTicket),
    400: e400,
    401: e401,
    403: e403,
    429: e429,
  },
});

export const listSupportTickets = createRoute({
  operationId: "listSupportTickets",
  method: "get",
  path: "/v1/admin/support-tickets",
  tags: ["admin"],
  security,
  summary: "Messages sent to support from the app, newest first (instance owners)",
  request: { query: z.object({ status: z.enum(["open", "closed", "all"]).optional() }) },
  responses: {
    200: jsonResponse(
      "Tickets",
      z.object({ items: z.array(SupportTicketRow) }).openapi("SupportTicketList"),
    ),
    401: e401,
    403: e403,
  },
});

export const setSupportTicketStatus = createRoute({
  operationId: "setSupportTicketStatus",
  method: "post",
  path: "/v1/admin/support-tickets/{reference}",
  tags: ["admin"],
  security,
  summary: "Mark a support message closed or open again",
  request: {
    params: z.object({ reference: z.string().max(20) }),
    body: jsonBody(
      z.object({ status: z.enum(["open", "closed"]) }).openapi("SetSupportTicketStatus"),
    ),
  },
  responses: { 200: jsonResponse("Ticket", SupportTicketRow), 401: e401, 403: e403, 404: e404 },
});

// Casama Help on the websites (D-401): signed out, so no bearer security and no 401 for a missing
// token; the session from /v1/support/web/session is the visitor's pass.
export const getSupportWebConfig = createRoute({
  operationId: "getSupportWebConfig",
  method: "get",
  path: "/v1/support/web/config",
  tags: ["support"],
  summary: "Whether the website assistant answers, and the Turnstile site key",
  responses: { 200: jsonResponse("Website assistant", SupportWebConfig) },
});

export const createSupportWebSession = createRoute({
  operationId: "createSupportWebSession",
  method: "post",
  path: "/v1/support/web/session",
  tags: ["support"],
  summary: "Pass the Turnstile check and get a short website assistant session",
  request: { body: jsonBody(SupportWebSessionRequest) },
  responses: {
    200: jsonResponse("Session", SupportWebSession),
    400: e400,
    403: e403,
    429: e429,
  },
});

export const supportWebChat = createRoute({
  operationId: "supportWebChat",
  method: "post",
  path: "/v1/support/web/chat",
  tags: ["support"],
  summary: "Ask the website assistant (answers from the docs; sees no account)",
  request: { body: jsonBody(SupportWebChatRequest) },
  responses: {
    200: jsonResponse("The assistant's answer", SupportWebChatReply),
    400: e400,
    401: e401,
    403: e403,
    429: e429,
  },
});

export const getSupportWebStats = createRoute({
  operationId: "getSupportWebStats",
  method: "get",
  path: "/v1/admin/support-web",
  tags: ["admin"],
  security,
  summary:
    "Today's use of the website assistant and the questions it couldn't answer (instance owners)",
  responses: { 200: jsonResponse("Website assistant use", SupportWebStats), 401: e401, 403: e403 },
});
