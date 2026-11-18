import { createRoute, z } from "@hono/zod-openapi";
import { jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";
import {
  AdminDomains,
  ConnectDomainRequest,
  ConnectDomainResult,
  DnsRecordInput,
  DnsRecordItem,
  DnsRecordList,
  DnsRecordPatch,
  Domain,
  DomainCheckoutRequest,
  DomainCheckoutResult,
  DomainContact,
  DomainContactState,
  DomainList,
  DomainOrder,
  DomainSearchList,
  TransferOutRequest,
  TransferOutResult,
  UpdateDomainRequest,
} from "../sites.ts";

const security = [{ bearerAuth: [] }];
const { 400: e400, 401: e401, 403: e403, 404: e404, 409: e409, 429: e429 } = problemResponses;
const idParam = z.object({ id: Uuid });

export const listDomains = createRoute({
  operationId: "listDomains",
  method: "get",
  path: "/v1/orgs/{id}/domains",
  tags: ["domains"],
  security,
  summary: "The workspace's connected and bought domains",
  request: { params: idParam },
  responses: { 200: jsonResponse("Domains", DomainList), 401: e401, 404: e404 },
});

export const connectDomain = createRoute({
  operationId: "connectDomain",
  method: "post",
  path: "/v1/orgs/{id}/domains",
  tags: ["domains"],
  security,
  summary: "Connect a domain the workspace owns (admins); answers the records to add",
  request: { params: idParam, body: jsonBody(ConnectDomainRequest) },
  responses: {
    201: jsonResponse(
      "Connected, or the record that proves it to take it over",
      ConnectDomainResult,
    ),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
    409: e409,
    429: e429,
  },
});

export const getDomain = createRoute({
  operationId: "getDomain",
  method: "get",
  path: "/v1/domains/{id}",
  tags: ["domains"],
  security,
  summary: "A domain: its hosts, the records to add with what DNS shows now, and its history",
  request: { params: idParam },
  responses: { 200: jsonResponse("Domain", Domain), 401: e401, 404: e404 },
});

export const checkDomain = createRoute({
  operationId: "checkDomain",
  method: "post",
  path: "/v1/domains/{id}/check",
  tags: ["domains"],
  security,
  summary: "Check a domain's DNS now (admins; at most once every 10 seconds)",
  request: { params: idParam },
  responses: {
    200: jsonResponse("Domain", Domain),
    401: e401,
    403: e403,
    404: e404,
    429: e429,
  },
});

export const updateDomain = createRoute({
  operationId: "updateDomain",
  method: "patch",
  path: "/v1/domains/{id}",
  tags: ["domains"],
  security,
  summary: "Point a domain at a site, choose its primary host, or turn renewal on or off (admins)",
  request: { params: idParam, body: jsonBody(UpdateDomainRequest) },
  responses: {
    200: jsonResponse("Domain", Domain),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
    409: e409,
  },
});

export const deleteDomain = createRoute({
  operationId: "deleteDomain",
  method: "delete",
  path: "/v1/domains/{id}",
  tags: ["domains"],
  security,
  summary:
    "Disconnect a domain (admins). A bought domain stays registered; only its site link goes",
  request: { params: idParam },
  responses: { 204: { description: "Disconnected" }, 401: e401, 403: e403, 404: e404 },
});

// ------------------------------------------------------------------ Buying (§7.7)

export const searchDomains = createRoute({
  operationId: "searchDomains",
  method: "get",
  path: "/v1/domains/search",
  tags: ["domains"],
  security,
  summary: "Names, whether they're free, and their prices (admins; 30 a minute)",
  request: {
    query: z.object({ org_id: Uuid, q: z.string().min(1).max(100) }),
  },
  responses: {
    200: jsonResponse("Results", DomainSearchList),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
    409: e409,
    429: e429,
  },
});

export const getDomainContact = createRoute({
  operationId: "getDomainContact",
  method: "get",
  path: "/v1/orgs/{id}/domain-contact",
  tags: ["domains"],
  security,
  summary: "The registrant's details for the workspace's domains (admins)",
  request: { params: idParam },
  responses: {
    200: jsonResponse("Contact", DomainContactState),
    401: e401,
    403: e403,
    404: e404,
  },
});

export const putDomainContact = createRoute({
  operationId: "putDomainContact",
  method: "put",
  path: "/v1/orgs/{id}/domain-contact",
  tags: ["domains"],
  security,
  summary:
    "Save the registrant's details (admins); bought domains are updated at the registrar too",
  request: { params: idParam, body: jsonBody(DomainContact) },
  responses: {
    200: jsonResponse("Contact", DomainContactState),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
  },
});

export const domainCheckout = createRoute({
  operationId: "domainCheckout",
  method: "post",
  path: "/v1/orgs/{id}/domains/checkout",
  tags: ["domains"],
  security,
  summary:
    "Buy a domain (admins): a checkout for exactly its price, or a charge on the saved method",
  request: { params: idParam, body: jsonBody(DomainCheckoutRequest) },
  responses: {
    201: jsonResponse("The order and where to pay", DomainCheckoutResult),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
    409: e409,
    429: e429,
  },
});

export const getDomainOrder = createRoute({
  operationId: "getDomainOrder",
  method: "get",
  path: "/v1/domain-orders/{id}",
  tags: ["domains"],
  security,
  summary: "A domain order and where it is (admins of its workspace)",
  request: { params: idParam },
  responses: { 200: jsonResponse("Order", DomainOrder), 401: e401, 403: e403, 404: e404 },
});

// ------------------------------------------------------------------ Keeping a domain (§7.8–§7.10)

const recordParams = z.object({ id: Uuid, record_id: z.string().min(1).max(64) });

export const renewDomain = createRoute({
  operationId: "renewDomain",
  method: "post",
  path: "/v1/domains/{id}/renew",
  tags: ["domains"],
  security,
  summary: "Renew Now (admins): a checkout for one more year at today's price",
  request: { params: idParam },
  responses: {
    201: jsonResponse("The order and where to pay", DomainCheckoutResult),
    401: e401,
    403: e403,
    404: e404,
    409: e409,
  },
});

export const listDomainRecords = createRoute({
  operationId: "listDomainRecords",
  method: "get",
  path: "/v1/domains/{id}/records",
  tags: ["domains"],
  security,
  summary: "A bought domain's DNS records, read live from the registrar (admins)",
  request: { params: idParam },
  responses: {
    200: jsonResponse("Records", DnsRecordList),
    401: e401,
    403: e403,
    404: e404,
    409: e409,
  },
});

export const addDomainRecord = createRoute({
  operationId: "addDomainRecord",
  method: "post",
  path: "/v1/domains/{id}/records",
  tags: ["domains"],
  security,
  summary: "Add a DNS record to a bought domain (admins)",
  request: { params: idParam, body: jsonBody(DnsRecordInput) },
  responses: {
    201: jsonResponse("Record", DnsRecordItem),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
    409: e409,
  },
});

export const updateDomainRecord = createRoute({
  operationId: "updateDomainRecord",
  method: "patch",
  path: "/v1/domains/{id}/records/{record_id}",
  tags: ["domains"],
  security,
  summary: "Change a DNS record of a bought domain (admins); the site's own records are locked",
  request: { params: recordParams, body: jsonBody(DnsRecordPatch) },
  responses: {
    200: jsonResponse("Record", DnsRecordItem),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
    409: e409,
  },
});

export const deleteDomainRecord = createRoute({
  operationId: "deleteDomainRecord",
  method: "delete",
  path: "/v1/domains/{id}/records/{record_id}",
  tags: ["domains"],
  security,
  summary: "Delete a DNS record of a bought domain (admins); the site's own records are locked",
  request: { params: recordParams },
  responses: {
    204: { description: "Deleted" },
    400: e400,
    401: e401,
    403: e403,
    404: e404,
    409: e409,
  },
});

export const transferOutDomain = createRoute({
  operationId: "transferOutDomain",
  method: "post",
  path: "/v1/domains/{id}/transfer-out",
  tags: ["domains"],
  security,
  summary:
    "Move to Another Registrar (the workspace owner, signed in within 10 minutes): unlocks and returns the transfer code once",
  request: { params: idParam, body: jsonBody(TransferOutRequest) },
  responses: {
    200: jsonResponse("The transfer code", TransferOutResult),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
    409: e409,
  },
});

export const resendDomainVerification = createRoute({
  operationId: "resendDomainVerification",
  method: "post",
  path: "/v1/domains/{id}/verify-email",
  tags: ["domains"],
  security,
  summary: "Send the registrant verification email again (admins)",
  request: { params: idParam },
  responses: { 204: { description: "Sent" }, 401: e401, 403: e403, 404: e404, 409: e409 },
});

// ------------------------------------------------------------------ Admin (§7.11)

export const adminDomains = createRoute({
  operationId: "adminDomains",
  method: "get",
  path: "/v1/admin/domains",
  tags: ["admin"],
  security,
  summary: "Every domain, the registrar balance and orders that need attention (instance owners)",
  responses: { 200: jsonResponse("Domains", AdminDomains), 401: e401, 403: e403 },
});

export const adminSuspendDomain = createRoute({
  operationId: "adminSuspendDomain",
  method: "post",
  path: "/v1/admin/domains/{id}/suspend",
  tags: ["admin"],
  security,
  summary:
    "Suspend a domain for abuse: its sites stop and its records are removed (instance owners)",
  request: { params: idParam },
  responses: { 204: { description: "Suspended" }, 401: e401, 403: e403, 404: e404 },
});

export const adminUnsuspendDomain = createRoute({
  operationId: "adminUnsuspendDomain",
  method: "post",
  path: "/v1/admin/domains/{id}/unsuspend",
  tags: ["admin"],
  security,
  summary: "Lift a domain's suspension (instance owners)",
  request: { params: idParam },
  responses: { 204: { description: "Unsuspended" }, 401: e401, 403: e403, 404: e404 },
});

export const adminRetryDomainOrder = createRoute({
  operationId: "adminRetryDomainOrder",
  method: "post",
  path: "/v1/admin/domain-orders/{id}/retry",
  tags: ["admin"],
  security,
  summary: "Try a stuck order again: its registration, or its refund (instance owners)",
  request: { params: idParam },
  responses: {
    200: jsonResponse("Order", DomainOrder),
    401: e401,
    403: e403,
    404: e404,
    409: e409,
  },
});

export const adminApproveDomainOrder = createRoute({
  operationId: "adminApproveDomainOrder",
  method: "post",
  path: "/v1/admin/domain-orders/{id}/approve",
  tags: ["admin"],
  security,
  summary: "Approve a new workspace's first purchase so it registers (instance owners)",
  request: { params: idParam },
  responses: {
    200: jsonResponse("Order", DomainOrder),
    401: e401,
    403: e403,
    404: e404,
    409: e409,
  },
});
