import { createRoute, z } from "@hono/zod-openapi";
import { jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";
import {
  BlockMailSenderRequest,
  ClaimMailAddressRequest,
  MailAddress,
  MailMessageDetail,
  MailMessageList,
  MailNameAvailability,
  MoveMailAddressRequest,
  UpdateMailAddressRequest,
} from "../mail.ts";

const security = [{ bearerAuth: [] }];
const { 400: e400, 401: e401, 403: e403, 404: e404, 409: e409 } = problemResponses;
const botParam = z.object({ id: Uuid });
const tags = ["mail"];

export const claimMailAddress = createRoute({
  operationId: "claimMailAddress",
  method: "post",
  path: "/v1/bots/{id}/email",
  tags,
  security,
  summary: "Claim a hosted email address for a bot",
  request: { params: botParam, body: jsonBody(ClaimMailAddressRequest) },
  responses: {
    201: jsonResponse("MailAddress", MailAddress),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
    409: e409,
  },
});

export const getMailAddress = createRoute({
  operationId: "getMailAddress",
  method: "get",
  path: "/v1/bots/{id}/email",
  tags,
  security,
  summary: "A bot's hosted email address",
  request: { params: botParam },
  responses: { 200: jsonResponse("MailAddress", MailAddress), 401: e401, 404: e404 },
});

export const checkMailName = createRoute({
  operationId: "checkMailName",
  method: "get",
  path: "/v1/bots/{id}/email/availability",
  tags,
  security,
  summary: "Whether a mail name is free, with alternatives",
  request: { params: botParam, query: z.object({ name: z.string().min(1).max(40) }) },
  responses: {
    200: jsonResponse("MailNameAvailability", MailNameAvailability),
    401: e401,
    404: e404,
  },
});

export const updateMailAddress = createRoute({
  operationId: "updateMailAddress",
  method: "patch",
  path: "/v1/bots/{id}/email",
  tags,
  security,
  summary: "Pause or resume a bot's hosted email address",
  request: { params: botParam, body: jsonBody(UpdateMailAddressRequest) },
  responses: {
    200: jsonResponse("MailAddress", MailAddress),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
  },
});

export const moveMailAddress = createRoute({
  operationId: "moveMailAddress",
  method: "post",
  path: "/v1/bots/{id}/email/move",
  tags,
  security,
  summary: "Move a hosted email address to another bot in the workspace",
  request: { params: botParam, body: jsonBody(MoveMailAddressRequest) },
  responses: {
    200: jsonResponse("MailAddress", MailAddress),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
    409: e409,
  },
});

export const releaseMailAddress = createRoute({
  operationId: "releaseMailAddress",
  method: "delete",
  path: "/v1/bots/{id}/email",
  tags,
  security,
  summary: "Release a hosted email address for good (its name is never reissued)",
  request: { params: botParam },
  responses: { 200: jsonResponse("MailAddress", MailAddress), 401: e401, 403: e403, 404: e404 },
});

export const listMailMessages = createRoute({
  operationId: "listMailMessages",
  method: "get",
  path: "/v1/bots/{id}/email/messages",
  tags,
  security,
  summary: "A bot's kept mail, newest first",
  request: {
    params: botParam,
    query: z.object({
      verdict: z.enum(["allowed", "stranger", "automatic"]).optional(),
      tag: z.string().max(100).optional(),
      sender: z.string().max(300).optional(),
      q: z.string().max(200).optional(),
      limit: z.coerce.number().int().min(1).max(100).optional(),
      cursor: z.string().max(100).optional(),
    }),
  },
  responses: { 200: jsonResponse("MailMessageList", MailMessageList), 401: e401, 404: e404 },
});

export const getMailMessage = createRoute({
  operationId: "getMailMessage",
  method: "get",
  path: "/v1/bots/{id}/email/messages/{messageId}",
  tags,
  security,
  summary: "One kept mail with its whole text",
  request: { params: botParam.extend({ messageId: Uuid }) },
  responses: { 200: jsonResponse("MailMessageDetail", MailMessageDetail), 401: e401, 404: e404 },
});

export const blockMailSender = createRoute({
  operationId: "blockMailSender",
  method: "post",
  path: "/v1/bots/{id}/email/block",
  tags,
  security,
  summary: "Refuse a sender's mail at the door",
  request: { params: botParam, body: jsonBody(BlockMailSenderRequest) },
  responses: {
    200: jsonResponse("MailAddress", MailAddress),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
  },
});

export const unblockMailSender = createRoute({
  operationId: "unblockMailSender",
  method: "delete",
  path: "/v1/bots/{id}/email/block",
  tags,
  security,
  summary: "Let a blocked sender's mail through again",
  request: { params: botParam, query: z.object({ sender: z.string().min(1).max(300) }) },
  responses: { 200: jsonResponse("MailAddress", MailAddress), 401: e401, 403: e403, 404: e404 },
});

export const downloadMailFile = createRoute({
  operationId: "downloadMailFile",
  method: "get",
  path: "/v1/bots/{id}/email/messages/{messageId}/files/{index}",
  tags,
  security,
  summary: "A kept mail's attachment",
  request: {
    params: botParam.extend({ messageId: Uuid, index: z.string().regex(/^[0-9]$/) }),
  },
  responses: {
    200: {
      description: "File contents",
      content: { "application/octet-stream": { schema: z.string().openapi({ format: "binary" }) } },
    },
    401: e401,
    404: e404,
  },
});
