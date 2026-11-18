import { createRoute, z } from "@hono/zod-openapi";
import { jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";
import {
  AdminLinkServer,
  AdminLinkServerList,
  ApprovedLinkSignIn,
  ApproveLinkSignInRequest,
  LinkServerList,
  LinkSignInRequest,
  RedeemedSignInCode,
  RedeemSignInCodeRequest,
  RemoteAccessStatus,
  SetRemoteAccessSettingsRequest,
  SignInCode,
  SuspendLinkServerRequest,
} from "../link.ts";

const security = [{ bearerAuth: [] }];
const { 400: e400, 401: e401, 403: e403, 404: e404, 409: e409, 429: e429 } = problemResponses;
const tags = ["casama-link"];
const orgParam = z.object({ id: Uuid });
const serverParam = z.object({ id: Uuid });

export const getLinkSignIn = createRoute({
  operationId: "getLinkSignIn",
  method: "get",
  path: "/v1/link/sign-ins/{user_code}",
  tags,
  security,
  summary: "The server a link code belongs to, shown before approving",
  request: { params: z.object({ user_code: z.string().min(8).max(16) }) },
  responses: { 200: jsonResponse("Link request", LinkSignInRequest), 401: e401, 404: e404 },
});

export const approveLinkSignIn = createRoute({
  operationId: "approveLinkSignIn",
  method: "post",
  path: "/v1/orgs/{id}/link/sign-ins/approve",
  tags,
  security,
  summary: "Link the server that shows this code to the workspace (admins)",
  description:
    "The server then receives a key that can hold an address and send push notifications. It can't spend the workspace's credits.",
  request: { params: orgParam, body: jsonBody(ApproveLinkSignInRequest) },
  responses: {
    200: jsonResponse("Linked", ApprovedLinkSignIn),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
  },
});

export const listLinkServers = createRoute({
  operationId: "listLinkServers",
  method: "get",
  path: "/v1/orgs/{id}/link/servers",
  tags,
  security,
  summary: "Servers linked to the workspace and their addresses (admins)",
  request: { params: orgParam },
  responses: { 200: jsonResponse("Servers", LinkServerList), 401: e401, 403: e403 },
});

export const removeLinkServer = createRoute({
  operationId: "removeLinkServer",
  method: "delete",
  path: "/v1/orgs/{id}/link/servers/{server_id}",
  tags,
  security,
  summary: "Remove a server's address, also when the server is offline or gone",
  request: { params: z.object({ id: Uuid, server_id: Uuid }) },
  responses: {
    200: jsonResponse("Removed", z.object({ removed: Uuid }).openapi("RemovedLinkServer")),
    401: e401,
    403: e403,
    404: e404,
  },
});

export const adminLinkServers = createRoute({
  operationId: "adminLinkServers",
  method: "get",
  path: "/v1/admin/link/servers",
  tags: ["admin"],
  security,
  summary: "Every linked server on this cloud (owner only)",
  responses: { 200: jsonResponse("Servers", AdminLinkServerList), 401: e401, 403: e403 },
});

export const suspendLinkServer = createRoute({
  operationId: "suspendLinkServer",
  method: "post",
  path: "/v1/admin/link/servers/{id}/suspend",
  tags: ["admin"],
  security,
  summary: "Take a server's address down until the suspension is lifted (owner only)",
  request: { params: serverParam, body: jsonBody(SuspendLinkServerRequest) },
  responses: {
    200: jsonResponse("Suspended", AdminLinkServer),
    401: e401,
    403: e403,
    404: e404,
  },
});

export const unsuspendLinkServer = createRoute({
  operationId: "unsuspendLinkServer",
  method: "delete",
  path: "/v1/admin/link/servers/{id}/suspend",
  tags: ["admin"],
  security,
  summary: "Lift a server's suspension; it gets its tunnel back when it next checks in",
  request: { params: serverParam },
  responses: {
    200: jsonResponse("Unsuspended", AdminLinkServer),
    401: e401,
    403: e403,
    404: e404,
  },
});

export const adminRemoteAccess = createRoute({
  operationId: "adminRemoteAccess",
  method: "get",
  path: "/v1/admin/remote-access",
  tags: ["admin"],
  security,
  summary: "This server's public address through Casama Link, and whether it works (owner only)",
  responses: { 200: jsonResponse("Status", RemoteAccessStatus), 401: e401, 403: e403 },
});

export const checkRemoteAccess = createRoute({
  operationId: "checkRemoteAccess",
  method: "post",
  path: "/v1/admin/remote-access/check",
  tags: ["admin"],
  security,
  summary: "Check the address now: Casama Cloud, the connector, and the address from outside",
  responses: { 200: jsonResponse("Status", RemoteAccessStatus), 401: e401, 403: e403 },
});

export const setRemoteAccessSettings = createRoute({
  operationId: "setRemoteAccessSettings",
  method: "put",
  path: "/v1/admin/remote-access/settings",
  tags: ["admin"],
  security,
  summary: "Casama Link settings on this server: private notifications (owner only)",
  request: { body: jsonBody(SetRemoteAccessSettingsRequest) },
  responses: { 200: jsonResponse("Status", RemoteAccessStatus), 400: e400, 401: e401, 403: e403 },
});

export const createSignInCode = createRoute({
  operationId: "createSignInCode",
  method: "post",
  path: "/v1/auth/pairing-codes",
  tags: ["auth"],
  security,
  summary: "A one-time code that signs another device in to this account (shown as a QR code)",
  responses: { 201: jsonResponse("Code", SignInCode), 401: e401, 409: e409, 429: e429 },
});

export const redeemSignInCode = createRoute({
  operationId: "redeemSignInCode",
  method: "post",
  path: "/v1/auth/pairing-codes/redeem",
  tags: ["auth"],
  summary: "Trade a scanned code for a one-time sign-in token (no sign-in needed)",
  request: { body: jsonBody(RedeemSignInCodeRequest) },
  responses: {
    200: jsonResponse("Token", RedeemedSignInCode),
    400: e400,
    404: e404,
    409: e409,
    429: e429,
  },
});
