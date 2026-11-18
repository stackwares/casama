import { createRoute, z } from "@hono/zod-openapi";
import {
  BillingSummary,
  BillingUsage,
  CheckoutRequest,
  CheckoutResult,
  CreatedLinkKey,
  CreateLinkKeyRequest,
  LinkKey,
  PlanCatalog,
  PortalRequest,
  PurchaseRequest,
  RedirectUrl,
  SeatsRequest,
} from "../billing.ts";
import { jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";

const security = [{ bearerAuth: [] }];
const { 400: e400, 401: e401, 403: e403, 404: e404, 409: e409 } = problemResponses;
const orgParam = z.object({ id: Uuid });
const tags = ["billing"];

export const listPlans = createRoute({
  operationId: "listPlans",
  method: "get",
  path: "/v1/billing/plans",
  tags,
  security,
  summary: "Plans and credit packs on this server",
  responses: { 200: jsonResponse("Catalog", PlanCatalog), 401: e401 },
});

export const getBilling = createRoute({
  operationId: "getBilling",
  method: "get",
  path: "/v1/orgs/{id}/billing",
  tags,
  security,
  summary: "The workspace's plan, entitlement, subscriptions and credits",
  request: { params: orgParam },
  responses: { 200: jsonResponse("Billing", BillingSummary), 401: e401, 404: e404 },
});

export const createCheckout = createRoute({
  operationId: "createCheckout",
  method: "post",
  path: "/v1/orgs/{id}/billing/checkout",
  tags,
  security,
  summary: "Start a web checkout (Dodo Payments) for a plan or credit pack",
  description:
    "The server doesn't know which device asks. Store rules are the client's to follow: an Android app must not offer web checkout (Google Play billing only), and an iPhone, iPad or Mac App Store app only on the US storefront.",
  request: { params: orgParam, body: jsonBody(CheckoutRequest) },
  responses: {
    200: jsonResponse("Checkout page, or the plan changed in place", CheckoutResult),
    400: e400,
    401: e401,
    403: e403,
    409: e409,
  },
});

export const billingPortal = createRoute({
  operationId: "billingPortal",
  method: "post",
  path: "/v1/orgs/{id}/billing/portal",
  tags,
  security,
  summary: "Open the customer portal for a web subscription",
  request: { params: orgParam, body: jsonBody(PortalRequest) },
  responses: { 200: jsonResponse("Portal", RedirectUrl), 401: e401, 403: e403, 409: e409 },
});

export const setBillingSeats = createRoute({
  operationId: "setBillingSeats",
  method: "put",
  path: "/v1/orgs/{id}/billing/seats",
  tags,
  security,
  summary: "Pay for more or fewer people than the plan includes (web subscriptions on Pro or Max)",
  request: { params: orgParam, body: jsonBody(SeatsRequest) },
  responses: {
    200: jsonResponse("Billing after the change", BillingSummary),
    400: e400,
    401: e401,
    403: e403,
    409: e409,
  },
});

export const verifyPurchase = createRoute({
  operationId: "verifyPurchase",
  method: "post",
  path: "/v1/orgs/{id}/billing/purchases",
  tags,
  security,
  summary: "Verify an App Store or Google Play purchase (also used by Restore Purchases)",
  request: { params: orgParam, body: jsonBody(PurchaseRequest) },
  responses: {
    200: jsonResponse("Billing after the purchase", BillingSummary),
    400: e400,
    401: e401,
    403: e403,
    409: e409,
  },
});

export const billingUsage = createRoute({
  operationId: "billingUsage",
  method: "get",
  path: "/v1/orgs/{id}/billing/usage",
  tags,
  security,
  summary: "This month's bill: billable usage by kind and instance, and recent credit entries",
  request: { params: orgParam },
  responses: { 200: jsonResponse("Usage", BillingUsage), 401: e401, 404: e404 },
});

export const listLinkKeys = createRoute({
  operationId: "listLinkKeys",
  method: "get",
  path: "/v1/orgs/{id}/link/keys",
  tags,
  security,
  summary: "Casama Link keys for self-hosted instances",
  request: { params: orgParam },
  responses: {
    200: jsonResponse("Keys", z.object({ items: z.array(LinkKey) }).openapi("LinkKeyList")),
    401: e401,
    403: e403,
  },
});

export const createLinkKey = createRoute({
  operationId: "createLinkKey",
  method: "post",
  path: "/v1/orgs/{id}/link/keys",
  tags,
  security,
  summary: "Create a Casama Link key (shown once)",
  request: { params: orgParam, body: jsonBody(CreateLinkKeyRequest) },
  responses: {
    201: jsonResponse("Created", CreatedLinkKey),
    400: e400,
    401: e401,
    403: e403,
    409: e409,
  },
});

export const revokeLinkKey = createRoute({
  operationId: "revokeLinkKey",
  method: "delete",
  path: "/v1/orgs/{id}/link/keys/{key_id}",
  tags,
  security,
  request: { params: z.object({ id: Uuid, key_id: Uuid }) },
  responses: {
    200: jsonResponse("Revoked", z.object({ revoked: Uuid }).openapi("RevokedLinkKey")),
    401: e401,
    403: e403,
    404: e404,
  },
});
