import { createRoute, z } from "@hono/zod-openapi";
import { IdempotencyKeyHeader, jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";
import {
  CreatedInviteLink,
  CreateInviteCodeRequest,
  CreateInviteLinkRequest,
  CreateInviteRequest,
  CreateInvitesRequest,
  CreateOrganizationRequest,
  DecideJoinRequest,
  Invite,
  InviteLink,
  InvitePreview,
  JoinableWorkspace,
  JoinDomains,
  JoinRequest,
  JoinRequestBody,
  JoinResult,
  Me,
  Membership,
  Organization,
  OrganizationWithRole,
  PendingInvite,
  SetJoinDomainRequest,
  UpdateDefaultInviteRequest,
  UpdateOrganizationRequest,
  WorkspaceBadge,
} from "../workspaces.ts";

const security = [{ bearerAuth: [] }];
const { 400: e400, 401: e401, 403: e403, 404: e404, 409: e409, 429: e429 } = problemResponses;

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

// --- joining (D-167) ---------------------------------------------------------------

const orgParam = z.object({ id: Uuid });

export const getDefaultInvite = createRoute({
  operationId: "getDefaultInvite",
  method: "get",
  path: "/v1/orgs/{id}/default-invite",
  tags: ["workspaces"],
  security,
  summary: "The workspace's standing invite link (admins); made on first use",
  request: { params: orgParam },
  responses: { 200: jsonResponse("The link", CreatedInviteLink), 401: e401, 403: e403 },
});

export const updateDefaultInvite = createRoute({
  operationId: "updateDefaultInvite",
  method: "patch",
  path: "/v1/orgs/{id}/default-invite",
  tags: ["workspaces"],
  security,
  summary: "Make the standing link ask an admin first, or reset it (admins)",
  request: { params: orgParam, body: jsonBody(UpdateDefaultInviteRequest) },
  responses: { 200: jsonResponse("The link", CreatedInviteLink), 400: e400, 401: e401, 403: e403 },
});

export const createInviteCode = createRoute({
  operationId: "createInviteCode",
  method: "post",
  path: "/v1/orgs/{id}/invite-codes",
  tags: ["workspaces"],
  security,
  summary: "A short invite code to read out or type, valid for 48 hours (admins)",
  request: { params: orgParam, body: jsonBody(CreateInviteCodeRequest) },
  responses: { 201: jsonResponse("Created", CreatedInviteLink), 400: e400, 401: e401, 403: e403 },
});

export const previewInvite = createRoute({
  operationId: "previewInvite",
  method: "get",
  path: "/v1/join/preview",
  tags: ["workspaces"],
  summary: "What an invite link, code or email invite opens, before joining (no sign-in needed)",
  request: { query: z.object({ invite: z.string().trim().min(6).max(512) }) },
  responses: { 200: jsonResponse("Preview", InvitePreview), 404: e404, 429: e429 },
});

export const joinWithInvite = createRoute({
  operationId: "joinWithInvite",
  method: "post",
  path: "/v1/join",
  tags: ["workspaces"],
  security,
  summary: "Join with an invite link, code or email invite (or ask to join)",
  request: { body: jsonBody(JoinRequestBody) },
  responses: {
    200: jsonResponse("Result", JoinResult),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
    429: e429,
  },
});

export const listJoinRequests = createRoute({
  operationId: "listJoinRequests",
  method: "get",
  path: "/v1/orgs/{id}/join-requests",
  tags: ["workspaces"],
  security,
  summary: "People waiting to join (admins)",
  request: { params: orgParam },
  responses: {
    200: jsonResponse(
      "Pending requests",
      z.object({ items: z.array(JoinRequest) }).openapi("JoinRequestList"),
    ),
    401: e401,
    403: e403,
  },
});

export const decideJoinRequest = createRoute({
  operationId: "decideJoinRequest",
  method: "post",
  path: "/v1/orgs/{id}/join-requests/{request_id}",
  tags: ["workspaces"],
  security,
  summary: "Approve or decline a request to join (admins)",
  request: {
    params: z.object({ id: Uuid, request_id: Uuid }),
    body: jsonBody(DecideJoinRequest),
  },
  responses: { 200: jsonResponse("Decided", JoinRequest), 401: e401, 403: e403, 404: e404 },
});

export const listInvites = createRoute({
  operationId: "listInvites",
  method: "get",
  path: "/v1/orgs/{id}/invites",
  tags: ["workspaces"],
  security,
  summary: "Email invites not yet accepted (admins)",
  request: { params: orgParam },
  responses: {
    200: jsonResponse(
      "Pending invites",
      z.object({ items: z.array(PendingInvite) }).openapi("PendingInviteList"),
    ),
    401: e401,
    403: e403,
  },
});

export const createInvites = createRoute({
  operationId: "createInvites",
  method: "post",
  path: "/v1/orgs/{id}/invites/batch",
  tags: ["workspaces"],
  security,
  summary: "Invite several people by email at once (admins)",
  request: { params: orgParam, body: jsonBody(CreateInvitesRequest) },
  responses: {
    201: jsonResponse("Invites", z.object({ items: z.array(Invite) }).openapi("InviteList")),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
  },
});

export const resendInvite = createRoute({
  operationId: "resendInvite",
  method: "post",
  path: "/v1/orgs/{id}/invites/{invite_id}/resend",
  tags: ["workspaces"],
  security,
  summary: "Send an email invite again with a new link, valid 7 more days (admins)",
  request: { params: z.object({ id: Uuid, invite_id: Uuid }) },
  responses: { 200: jsonResponse("Resent", Invite), 401: e401, 403: e403, 404: e404 },
});

export const revokeInvite = createRoute({
  operationId: "revokeInvite",
  method: "delete",
  path: "/v1/orgs/{id}/invites/{invite_id}",
  tags: ["workspaces"],
  security,
  request: { params: z.object({ id: Uuid, invite_id: Uuid }) },
  responses: { 204: { description: "Revoked" }, 401: e401, 403: e403, 404: e404 },
});

export const getJoinDomains = createRoute({
  operationId: "getJoinDomains",
  method: "get",
  path: "/v1/orgs/{id}/join-domains",
  tags: ["workspaces"],
  security,
  summary: "Email domains whose verified addresses can join without an invite (admins)",
  request: { params: orgParam },
  responses: { 200: jsonResponse("Domains", JoinDomains), 401: e401, 403: e403 },
});

export const setJoinDomain = createRoute({
  operationId: "setJoinDomain",
  method: "put",
  path: "/v1/orgs/{id}/join-domains",
  tags: ["workspaces"],
  security,
  summary: "Let people with a verified address at your own email domain join (admins)",
  request: { params: orgParam, body: jsonBody(SetJoinDomainRequest) },
  responses: { 200: jsonResponse("Domains", JoinDomains), 400: e400, 401: e401, 403: e403 },
});

export const listJoinableWorkspaces = createRoute({
  operationId: "listJoinableWorkspaces",
  method: "get",
  path: "/v1/me/joinable-workspaces",
  tags: ["workspaces"],
  security,
  summary: "Workspaces open to the signed-in person's verified email domain",
  responses: {
    200: jsonResponse(
      "Workspaces",
      z.object({ items: z.array(JoinableWorkspace) }).openapi("JoinableWorkspaceList"),
    ),
    401: e401,
  },
});

export const joinByDomain = createRoute({
  operationId: "joinByDomain",
  method: "post",
  path: "/v1/orgs/{id}/join",
  tags: ["workspaces"],
  security,
  summary: "Join a workspace open to your verified email domain",
  request: { params: orgParam },
  responses: { 200: jsonResponse("Joined", OrganizationWithRole), 401: e401, 404: e404 },
});
