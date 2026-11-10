import { createRoute, z } from "@hono/zod-openapi";
import { jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";
import {
  DeviceGrant,
  DeviceKind,
  DevicePlace,
  DeviceReading,
  DeviceRequest,
  DeviceRequestResult,
  DeviceSource,
  ReportDeviceEventsRequest,
  SaveDevicePlaceRequest,
  SaveDeviceSourceRequest,
  SetDeviceGrantRequest,
  UploadDeviceReadingsRequest,
} from "../device-data.ts";

const security = [{ bearerAuth: [] }];
const { 400: e400, 401: e401, 404: e404 } = problemResponses;
const tags = ["devices"];
const key = z.object({ key: z.string().regex(/^[A-Za-z0-9_-]{8,100}$/) });

export const listDeviceSources = createRoute({
  operationId: "listDeviceSources",
  method: "get",
  path: "/v1/device-sources",
  tags,
  security,
  summary: "Your devices that share data (D-149)",
  responses: {
    200: jsonResponse("Devices", z.object({ items: z.array(DeviceSource) })),
    401: e401,
  },
});
export const saveDeviceSource = createRoute({
  operationId: "saveDeviceSource",
  method: "put",
  path: "/v1/device-sources/{key}",
  tags,
  security,
  summary: "Register this device and the kinds it shares; kinds turned off lose their data",
  request: { params: key, body: jsonBody(SaveDeviceSourceRequest) },
  responses: { 200: jsonResponse("Device", DeviceSource), 400: e400, 401: e401 },
});
export const deleteDeviceSource = createRoute({
  operationId: "deleteDeviceSource",
  method: "delete",
  path: "/v1/device-sources/{key}",
  tags,
  security,
  summary: "Forget this device and everything it shared",
  request: { params: key },
  responses: { 200: jsonResponse("Deleted", z.object({ ok: z.boolean() })), 401: e401, 404: e404 },
});
export const uploadDeviceReadings = createRoute({
  operationId: "uploadDeviceReadings",
  method: "post",
  path: "/v1/device-sources/{key}/readings",
  tags,
  security,
  summary: "Upload summaries (re-uploading the same external_id replaces it)",
  request: { params: key, body: jsonBody(UploadDeviceReadingsRequest) },
  responses: {
    200: jsonResponse("Stored", z.object({ stored: z.number().int() })),
    400: e400,
    401: e401,
    404: e404,
  },
});
export const listDeviceRequests = createRoute({
  operationId: "listDeviceRequests",
  method: "get",
  path: "/v1/device-sources/{key}/requests",
  tags,
  security,
  summary: "Work waiting for this device",
  request: { params: key },
  responses: {
    200: jsonResponse("Requests", z.object({ items: z.array(DeviceRequest) })),
    401: e401,
    404: e404,
  },
});
export const answerDeviceRequest = createRoute({
  operationId: "answerDeviceRequest",
  method: "post",
  path: "/v1/device-requests/{id}/result",
  tags,
  security,
  request: { params: z.object({ id: Uuid }), body: jsonBody(DeviceRequestResult) },
  responses: { 200: jsonResponse("Answered", z.object({ ok: z.boolean() })), 401: e401, 404: e404 },
});
export const listDeviceReadings = createRoute({
  operationId: "listDeviceReadings",
  method: "get",
  path: "/v1/device-readings",
  tags,
  security,
  summary: "What your devices have shared",
  request: {
    query: z.object({
      kind: DeviceKind.optional(),
      limit: z.coerce.number().int().min(1).max(200).optional(),
    }),
  },
  responses: {
    200: jsonResponse("Readings", z.object({ items: z.array(DeviceReading) })),
    401: e401,
  },
});
export const listDeviceGrants = createRoute({
  operationId: "listDeviceGrants",
  method: "get",
  path: "/v1/device-grants",
  tags,
  security,
  summary: "Which bots may read which kinds of your device data",
  request: { query: z.object({ bot_id: Uuid.optional() }) },
  responses: { 200: jsonResponse("Grants", z.object({ items: z.array(DeviceGrant) })), 401: e401 },
});
export const setDeviceGrant = createRoute({
  operationId: "setDeviceGrant",
  method: "put",
  path: "/v1/device-grants",
  tags,
  security,
  summary: "Allow or stop a bot reading one kind of your device data",
  request: { body: jsonBody(SetDeviceGrantRequest) },
  responses: {
    200: jsonResponse("Grants", z.object({ items: z.array(DeviceGrant) })),
    400: e400,
    401: e401,
    404: e404,
  },
});

export const reportDeviceEvents = createRoute({
  operationId: "reportDeviceEvents",
  method: "post",
  path: "/v1/device-sources/{key}/events",
  tags,
  security,
  summary: "Report events that start device-triggered routines (D-151)",
  request: { params: key, body: jsonBody(ReportDeviceEventsRequest) },
  responses: {
    200: jsonResponse("Accepted", z.object({ accepted: z.number().int(), runs: z.number().int() })),
    400: e400,
    401: e401,
    404: e404,
  },
});
export const listDevicePlaces = createRoute({
  operationId: "listDevicePlaces",
  method: "get",
  path: "/v1/device-places",
  tags,
  security,
  summary: "Your named places",
  responses: { 200: jsonResponse("Places", z.object({ items: z.array(DevicePlace) })), 401: e401 },
});
export const saveDevicePlace = createRoute({
  operationId: "saveDevicePlace",
  method: "post",
  path: "/v1/device-places",
  tags,
  security,
  summary: "Add or update a named place (up to 20)",
  request: { body: jsonBody(SaveDevicePlaceRequest) },
  responses: { 200: jsonResponse("Place", DevicePlace), 400: e400, 401: e401 },
});
export const deleteDevicePlace = createRoute({
  operationId: "deleteDevicePlace",
  method: "delete",
  path: "/v1/device-places/{id}",
  tags,
  security,
  request: { params: z.object({ id: Uuid }) },
  responses: { 200: jsonResponse("Deleted", z.object({ ok: z.boolean() })), 401: e401, 404: e404 },
});
