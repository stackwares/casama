import { createRoute, z } from "@hono/zod-openapi";
import { jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";
import {
  PublishSiteRequest,
  Site,
  SiteAddressCheck,
  SiteList,
  SiteReportRequest,
  SiteReportResult,
} from "../sites.ts";

const security = [{ bearerAuth: [] }];
const { 400: e400, 401: e401, 403: e403, 404: e404, 409: e409, 429: e429 } = problemResponses;
const idParam = z.object({ id: Uuid });

export const listSites = createRoute({
  operationId: "listSites",
  method: "get",
  path: "/v1/orgs/{id}/sites",
  tags: ["sites"],
  security,
  summary: "The workspace's published sites with their hosts and states",
  request: { params: idParam },
  responses: { 200: jsonResponse("Sites", SiteList), 401: e401, 404: e404 },
});

export const checkSiteAddress = createRoute({
  operationId: "checkSiteAddress",
  method: "get",
  path: "/v1/sites/address",
  tags: ["sites"],
  security,
  summary: "Whether an address name is free, and why not when it isn't",
  request: { query: z.object({ org_id: Uuid, label: z.string().max(63) }) },
  responses: { 200: jsonResponse("Address", SiteAddressCheck), 401: e401, 404: e404 },
});

export const publishSite = createRoute({
  operationId: "publishSite",
  method: "put",
  path: "/v1/pages/{id}/site",
  tags: ["sites"],
  security,
  summary: "Publish a page to the web at its own address (makes the page public)",
  request: { params: idParam, body: jsonBody(PublishSiteRequest) },
  responses: {
    200: jsonResponse("Site", Site),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
    409: e409,
  },
});

export const unpublishSite = createRoute({
  operationId: "unpublishSite",
  method: "delete",
  path: "/v1/pages/{id}/site",
  tags: ["sites"],
  security,
  summary: "Take a site off the web: the page goes private, its address is kept",
  request: { params: idParam },
  responses: { 200: jsonResponse("Site", Site), 401: e401, 403: e403, 404: e404 },
});

export const createSiteReport = createRoute({
  operationId: "createSiteReport",
  method: "post",
  path: "/v1/site-reports",
  tags: ["sites"],
  summary: "Report a site by its address (no sign-in; from the sites zone's own page)",
  request: { body: jsonBody(SiteReportRequest) },
  responses: {
    202: jsonResponse("Report received", SiteReportResult),
    400: e400,
    429: e429,
  },
});
