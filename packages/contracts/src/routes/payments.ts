import { createRoute, z } from "@hono/zod-openapi";
import { jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";
import { PaymentRequest, PaymentSettings, SetPaymentSettingsRequest } from "../payments.ts";

const security = [{ bearerAuth: [] }];
const { 400: e400, 401: e401, 403: e403, 404: e404 } = problemResponses;
const params = z.object({ id: Uuid });
const tags = ["payments"];

export const getPaymentSettings = createRoute({
  operationId: "getPaymentSettings",
  method: "get",
  path: "/v1/orgs/{id}/payments",
  tags,
  security,
  request: { params },
  responses: { 200: jsonResponse("Settings", PaymentSettings), 401: e401, 403: e403, 404: e404 },
});
export const setPaymentSettings = createRoute({
  operationId: "setPaymentSettings",
  method: "put",
  path: "/v1/orgs/{id}/payments",
  tags,
  security,
  summary: "Connect the workspace's card issuing account for single-use cards (owners)",
  request: { params, body: jsonBody(SetPaymentSettingsRequest) },
  responses: {
    200: jsonResponse("Settings", PaymentSettings),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
  },
});
export const deletePaymentSettings = createRoute({
  operationId: "deletePaymentSettings",
  method: "delete",
  path: "/v1/orgs/{id}/payments",
  tags,
  security,
  request: { params },
  responses: { 200: jsonResponse("Settings", PaymentSettings), 401: e401, 403: e403, 404: e404 },
});
export const listPaymentRequests = createRoute({
  operationId: "listPaymentRequests",
  method: "get",
  path: "/v1/orgs/{id}/payments/requests",
  tags,
  security,
  summary: "Cards bots asked for (owners see all; others their own)",
  request: { params },
  responses: {
    200: jsonResponse(
      "Requests",
      z.object({ items: z.array(PaymentRequest) }).openapi("PaymentRequestList"),
    ),
    401: e401,
    404: e404,
  },
});
