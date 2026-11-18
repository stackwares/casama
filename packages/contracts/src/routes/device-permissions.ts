import { createRoute, z } from "@hono/zod-openapi";
import { jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";
import {
  AskDevicePermissionRequest,
  AskDevicePermissionResult,
  DevicePermissions,
  DevicePermissionType,
  ReportDevicePermissionsRequest,
  SnoozeDevicePermissionsRequest,
} from "../device-permissions.ts";

const security = [{ bearerAuth: [] }];
const { 400: e400, 401: e401, 404: e404, 409: e409 } = problemResponses;
const tags = ["devices"];
const device = z.object({ type: DevicePermissionType, id: Uuid });

export const listDevicePermissions = createRoute({
  operationId: "listDevicePermissions",
  method: "get",
  path: "/v1/device-permissions",
  tags,
  security,
  summary: "System permissions on each of your own devices, as they last reported them",
  responses: {
    200: jsonResponse("Devices", z.object({ items: z.array(DevicePermissions) })),
    401: e401,
  },
});

export const reportDevicePermissions = createRoute({
  operationId: "reportDevicePermissions",
  method: "put",
  path: "/v1/device-permissions/{type}/{id}",
  tags,
  security,
  summary: "This device's system permissions as they are now (checked without prompting)",
  request: { params: device, body: jsonBody(ReportDevicePermissionsRequest) },
  responses: {
    200: jsonResponse("Saved", DevicePermissions),
    400: e400,
    401: e401,
    404: e404,
  },
});

export const askDevicePermission = createRoute({
  operationId: "askDevicePermission",
  method: "post",
  path: "/v1/device-permissions/{type}/{id}/ask",
  tags,
  security,
  summary:
    "Ask one of your devices to show a permission's prompt, open its settings or restart Casama",
  request: { params: device, body: jsonBody(AskDevicePermissionRequest) },
  responses: {
    200: jsonResponse("Sent", AskDevicePermissionResult),
    400: e400,
    401: e401,
    404: e404,
    409: e409,
  },
});

export const snoozeDevicePermissions = createRoute({
  operationId: "snoozeDevicePermissions",
  method: "post",
  path: "/v1/device-permissions/{type}/{id}/snooze",
  tags,
  security,
  summary: "Not now: this bot doesn't ask for these permissions on this device for 24 hours",
  request: { params: device, body: jsonBody(SnoozeDevicePermissionsRequest) },
  responses: {
    200: jsonResponse("Snoozed", z.object({ until: z.iso.datetime({ offset: true }) })),
    400: e400,
    401: e401,
    404: e404,
  },
});
