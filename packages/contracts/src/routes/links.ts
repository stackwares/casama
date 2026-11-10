import { createRoute, z } from "@hono/zod-openapi";
import { jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";
import {
  AcceptBotLinkRequest,
  BotLink,
  CreateBotLinkRequest,
  CreatedBotLink,
  LinkExchange,
} from "../links.ts";

const security = [{ bearerAuth: [] }];
const { 400: e400, 401: e401, 403: e403, 404: e404, 409: e409 } = problemResponses;
const params = z.object({ id: Uuid });
const tags = ["links"];

export const listBotLinks = createRoute({
  operationId: "listBotLinks",
  method: "get",
  path: "/v1/bots/{id}/links",
  tags,
  security,
  request: { params },
  responses: {
    200: jsonResponse("Links", z.object({ items: z.array(BotLink) }).openapi("BotLinkList")),
    401: e401,
    404: e404,
  },
});
export const createBotLink = createRoute({
  operationId: "createBotLink",
  method: "post",
  path: "/v1/bots/{id}/links",
  tags,
  security,
  summary: "Invite a trusted contact's bot to link with this one (D-143)",
  request: { params, body: jsonBody(CreateBotLinkRequest) },
  responses: { 201: jsonResponse("Invite", CreatedBotLink), 401: e401, 403: e403, 404: e404 },
});
export const acceptBotLink = createRoute({
  operationId: "acceptBotLink",
  method: "post",
  path: "/v1/links/accept",
  tags,
  security,
  summary: "Accept a contact's invite with one of your bots (works across Kasama servers)",
  request: { body: jsonBody(AcceptBotLinkRequest) },
  responses: {
    201: jsonResponse("Link", BotLink),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
    409: e409,
  },
});
export const revokeBotLink = createRoute({
  operationId: "revokeBotLink",
  method: "delete",
  path: "/v1/links/{id}",
  tags,
  security,
  request: { params },
  responses: { 200: jsonResponse("Link", BotLink), 401: e401, 404: e404 },
});
export const listLinkExchanges = createRoute({
  operationId: "listLinkExchanges",
  method: "get",
  path: "/v1/links/{id}/exchanges",
  tags,
  security,
  request: { params },
  responses: {
    200: jsonResponse(
      "Exchanges",
      z.object({ items: z.array(LinkExchange) }).openapi("LinkExchangeList"),
    ),
    401: e401,
    404: e404,
  },
});
