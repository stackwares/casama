import { createRoute, z } from "@hono/zod-openapi";
import { IdempotencyKeyHeader, jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";
import {
  CreateInviteRequest,
  CreateOrganizationRequest,
  Invite,
  Me,
  Membership,
  Organization,
  OrganizationWithRole,
} from "../workspaces.ts";

const security = [{ bearerAuth: [] }];
const { 400: e400, 401: e401, 403: e403, 404: e404, 409: e409 } = problemResponses;

export const getMe = createRoute({
  operationId: "getMe",
  method: "get",
  path: "/v1/me",
  tags: ["workspaces"],
  security,
  summary: "The signed-in user and their organizations",
  responses: { 200: jsonResponse("Current user", Me), 401: e401 },
});

export const listOrgs = createRoute({
  operationId: "listOrgs",
  method: "get",
  path: "/v1/orgs",
  tags: ["workspaces"],
  security,
  responses: {
    200: jsonResponse(
      "Organizations the user belongs to",
      z.object({ items: z.array(OrganizationWithRole) }).openapi("OrganizationList"),
    ),
    401: e401,
  },
});

export const createOrg = createRoute({
  operationId: "createOrg",
  method: "post",
  path: "/v1/orgs",
  tags: ["workspaces"],
  security,
  summary: "Create an organization; the caller becomes its owner",
  request: { headers: IdempotencyKeyHeader, body: jsonBody(CreateOrganizationRequest) },
  responses: { 201: jsonResponse("Created", Organization), 400: e400, 401: e401, 409: e409 },
});

export const createInvite = createRoute({
  operationId: "createInvite",
  method: "post",
  path: "/v1/orgs/{id}/invites",
  tags: ["workspaces"],
  security,
  summary: "Invite someone by email (owners and admins)",
  request: {
    params: z.object({ id: Uuid }),
    headers: IdempotencyKeyHeader,
    body: jsonBody(CreateInviteRequest),
  },
  responses: {
    201: jsonResponse("Invite created", Invite),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
  },
});

export const acceptInvite = createRoute({
  operationId: "acceptInvite",
  method: "post",
  path: "/v1/invites/{token}/accept",
  tags: ["workspaces"],
  security,
  summary: "Join an organization with an invite token",
  request: { params: z.object({ token: z.string().min(16).max(256) }) },
  responses: { 200: jsonResponse("Joined", Membership), 401: e401, 403: e403, 404: e404 },
});
