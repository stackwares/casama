import { createRoute, z } from "@hono/zod-openapi";
import { jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";
import {
  Glance,
  WidgetKey,
  WidgetKeyCreate,
  WidgetKeyCreated,
  WidgetKeyUpdate,
  WidgetPushToken,
} from "../glance.ts";

/**
 * Widgets (D-405, docs/WIDGETS-PLAN.md §8). The glance and the push-token route also take
 * `Authorization: Widget <key>`: a widget key reads the glance and creation covers and registers
 * its own push token, nothing else. Creating, changing and deleting keys needs the session.
 */
const security = [{ bearerAuth: [] }];
const { 400: e400, 401: e401, 403: e403, 404: e404, 429: e429 } = problemResponses;
const idParam = z.object({ id: Uuid });

export const getGlance = createRoute({
  operationId: "getGlance",
  method: "get",
  path: "/v1/glance",
  tags: ["widgets"],
  security,
  summary:
    "What the person's widgets show, in one small document (D-405). Takes the session or `Authorization: Widget <key>`; send `If-None-Match` with the last `version` to get 304 when nothing changed",
  request: {
    query: z.object({
      org_id: Uuid.optional().openapi({
        description: "Needed with the session; a widget key reads its own workspace",
      }),
    }),
  },
  responses: {
    200: jsonResponse("The glance", Glance),
    304: { description: "Not changed since the version in If-None-Match" },
    400: e400,
    401: e401,
    403: e403,
    404: e404,
    429: e429,
  },
});

export const createWidgetKey = createRoute({
  operationId: "createWidgetKey",
  method: "post",
  path: "/v1/widget-keys",
  tags: ["widgets"],
  security,
  summary:
    "A key this device's widgets fetch the glance with, shown once. It reads the glance and creation covers and nothing else",
  request: { body: jsonBody(WidgetKeyCreate) },
  responses: {
    201: jsonResponse("Created", WidgetKeyCreated),
    400: e400,
    401: e401,
    404: e404,
  },
});

export const updateWidgetKey = createRoute({
  operationId: "updateWidgetKey",
  method: "patch",
  path: "/v1/widget-keys/{id}",
  tags: ["widgets"],
  security,
  summary: "Make the glance this key reads private (counts and general words only), or not",
  request: { params: idParam, body: jsonBody(WidgetKeyUpdate) },
  responses: { 200: jsonResponse("Updated", WidgetKey), 400: e400, 401: e401, 404: e404 },
});

export const deleteWidgetKey = createRoute({
  operationId: "deleteWidgetKey",
  method: "delete",
  path: "/v1/widget-keys/{id}",
  tags: ["widgets"],
  security,
  summary: "Forget a widget key (sign-out): its widgets stop fetching",
  request: { params: idParam },
  responses: {
    200: jsonResponse("Deleted", z.object({ deleted: Uuid }).openapi("DeletedWidgetKey")),
    401: e401,
    404: e404,
  },
});

export const setWidgetPushToken = createRoute({
  operationId: "setWidgetPushToken",
  method: "put",
  path: "/v1/widget-keys/current/push-token",
  tags: ["widgets"],
  security,
  summary:
    "Where to send refresh pushes for a key's widgets: the widget extension calls it with `Authorization: Widget <key>`, the app with the session and `?key_id=`",
  request: {
    query: z.object({ key_id: Uuid.optional() }),
    body: jsonBody(WidgetPushToken),
  },
  responses: {
    200: jsonResponse("Saved", z.object({ ok: z.literal(true) }).openapi("WidgetPushTokenSaved")),
    400: e400,
    401: e401,
    404: e404,
    429: e429,
  },
});
