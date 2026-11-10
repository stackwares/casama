import { createRoute, z } from "@hono/zod-openapi";
import { IdempotencyKeyHeader, jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";
import {
  CreatedInviteLink,
  CreateInviteLinkRequest,
  CreateInviteRequest,
  CreateOrganizationRequest,
  Invite,
  InviteLink,
  Me,
  Membership,
  Organization,
  OrganizationWithRole,
  UpdateOrganizationRequest,
  WorkspaceBadge,
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

export const updateOrg = createRoute({
  operationId: "updateOrg",
  method: "patch",
  path: "/v1/orgs/{id}",
  tags: ["workspaces"],
  security,
  summary: "Rename a workspace or change its icon and color (admins)",
  request: { params: z.object({ id: Uuid }), body: jsonBody(UpdateOrganizationRequest) },
  responses: {
    200: jsonResponse("Updated", Organization),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
  },
});

export const listInviteLinks = createRoute({
  operationId: "listInviteLinks",
  method: "get",
  path: "/v1/orgs/{id}/invite-links",
  tags: ["workspaces"],
  security,
  request: { params: z.object({ id: Uuid }) },
  responses: {
    200: jsonResponse(
      "Invite links (admins)",
      z.object({ items: z.array(InviteLink) }).openapi("InviteLinkList"),
    ),
    401: e401,
    403: e403,
  },
});

export const createInviteLink = createRoute({
  operationId: "createInviteLink",
  method: "post",
  path: "/v1/orgs/{id}/invite-links",
  tags: ["workspaces"],
  security,
  summary: "Create a shareable invite link (admins); the token is shown once",
  request: { params: z.object({ id: Uuid }), body: jsonBody(CreateInviteLinkRequest) },
  responses: { 201: jsonResponse("Created", CreatedInviteLink), 400: e400, 401: e401, 403: e403 },
});

export const revokeInviteLink = createRoute({
  operationId: "revokeInviteLink",
  method: "delete",
  path: "/v1/orgs/{id}/invite-links/{link_id}",
  tags: ["workspaces"],
  security,
  request: { params: z.object({ id: Uuid, link_id: Uuid }) },
  responses: { 204: { description: "Revoked" }, 401: e401, 403: e403, 404: e404 },
});

export const acceptInviteLink = createRoute({
  operationId: "acceptInviteLink",
  method: "post",
  path: "/v1/invite-links/{token}/accept",
  tags: ["workspaces"],
  security,
  summary: "Join a workspace with an invite link",
  request: { params: z.object({ token: z.string().min(16).max(256) }) },
  responses: { 200: jsonResponse("Joined", OrganizationWithRole), 401: e401, 404: e404 },
});

export const workspaceBadges = createRoute({
  operationId: "workspaceBadges",
  method: "get",
  path: "/v1/me/badges",
  tags: ["workspaces"],
  security,
  summary: "Pending approvals and unread notifications per workspace",
  responses: {
    200: jsonResponse(
      "Badges",
      z.object({ items: z.array(WorkspaceBadge) }).openapi("WorkspaceBadgeList"),
    ),
    401: e401,
  },
});
