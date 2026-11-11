import { createRoute, z } from "@hono/zod-openapi";
import { jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";
import {
  OutboundCall,
  SetTelephonyRequest,
  TakeOverCallRequest,
  TelephonySettings,
} from "../telephony.ts";

const security = [{ bearerAuth: [] }];
const { 400: e400, 401: e401, 403: e403, 404: e404, 409: e409 } = problemResponses;
const params = z.object({ id: Uuid });
const tags = ["telephony"];

export const getTelephony = createRoute({
  operationId: "getTelephony",
  method: "get",
  path: "/v1/orgs/{id}/telephony",
  tags,
  security,
  request: { params },
  responses: { 200: jsonResponse("Settings", TelephonySettings), 401: e401, 403: e403, 404: e404 },
});
export const setTelephony = createRoute({
  operationId: "setTelephony",
  method: "put",
  path: "/v1/orgs/{id}/telephony",
  tags,
  security,
  summary: "Connect the workspace's Twilio account for calls bots place",
  request: { params, body: jsonBody(SetTelephonyRequest) },
  responses: {
    200: jsonResponse("Settings", TelephonySettings),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
  },
});
export const deleteTelephony = createRoute({
  operationId: "deleteTelephony",
  method: "delete",
  path: "/v1/orgs/{id}/telephony",
  tags,
  security,
  request: { params },
  responses: { 200: jsonResponse("Settings", TelephonySettings), 401: e401, 403: e403, 404: e404 },
});
export const getOutboundCall = createRoute({
  operationId: "getOutboundCall",
  method: "get",
  path: "/v1/outbound-calls/{id}",
  tags,
  security,
  summary: "A call a bot placed, with its live transcript",
  request: { params },
  responses: { 200: jsonResponse("Call", OutboundCall), 401: e401, 404: e404 },
});
export const endOutboundCall = createRoute({
  operationId: "endOutboundCall",
  method: "post",
  path: "/v1/outbound-calls/{id}/end",
  tags,
  security,
  request: { params },
  responses: { 200: jsonResponse("Call", OutboundCall), 401: e401, 404: e404 },
});
export const takeOverOutboundCall = createRoute({
  operationId: "takeOverOutboundCall",
  method: "post",
  path: "/v1/outbound-calls/{id}/take-over",
  tags,
  security,
  summary: "Move the call to your own phone (saves the number to your profile)",
  request: { params, body: jsonBody(TakeOverCallRequest) },
  responses: {
    200: jsonResponse("Call", OutboundCall),
    400: e400,
    401: e401,
    404: e404,
    409: e409,
  },
});
