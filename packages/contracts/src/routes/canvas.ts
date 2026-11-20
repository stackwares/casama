import { createRoute, z } from "@hono/zod-openapi";
import { CanvasList, Canvas as CanvasOut, CanvasUpdate, SetCanvasGrant } from "../canvas.ts";
import { jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";

/**
 * Bot widgets (docs/BOT-WIDGET-PLAN.md §9.2). The two reads also take `Authorization: Widget <key>`;
 * changing, clearing and allowing need the session. Bots write through their `widget.*` tools.
 */
const security = [{ bearerAuth: [] }];
const { 400: e400, 401: e401, 403: e403, 404: e404, 429: e429 } = problemResponses;
const idParam = z.object({ id: Uuid });

export const getCanvases = createRoute({
  operationId: "getCanvases",
  method: "get",
  path: "/v1/canvases",
  tags: ["widgets"],
  security,
  summary:
    "What bots keep on the person's Canvas widgets: each canvas with the entry showing now and up to 13 planned. Takes the session or `Authorization: Widget <key>`; send `If-None-Match` with the last `version` to get 304",
  request: {
    query: z.object({
      org_id: Uuid.optional().openapi({
        description: "Needed with the session; a widget key reads its own workspace",
      }),
      sizes: z.string().max(200).optional().openapi({
        description:
          "Widget keys: the Canvas sizes this device draws, comma separated (home_small, lock_rect…), so bots can say where they show",
      }),
    }),
  },
  responses: {
    200: jsonResponse("The canvases", CanvasList),
    304: { description: "Not changed since the version in If-None-Match" },
    400: e400,
    401: e401,
    403: e403,
    404: e404,
    429: e429,
  },
});

export const getCanvasPicture = createRoute({
  operationId: "getCanvasPicture",
  method: "get",
  path: "/v1/canvases/{id}/pictures/{hash}",
  tags: ["widgets"],
  security,
  summary:
    "A canvas's picture or built-in painting as a JPEG; cached for good (the hash is in the path)",
  request: {
    params: z.object({
      id: Uuid,
      hash: z.string().regex(/^(painting-[a-z_]{2,20}|[0-9a-f]{16,64})$/),
    }),
  },
  responses: {
    200: { description: "JPEG", content: { "image/jpeg": { schema: z.string() } } },
    401: e401,
    404: e404,
    429: e429,
  },
});

export const updateCanvas = createRoute({
  operationId: "updateCanvas",
  method: "patch",
  path: "/v1/canvases/{id}",
  tags: ["widgets"],
  security,
  summary: "Pause a canvas or show it again; hide it on a locked phone, or not",
  request: { params: idParam, body: jsonBody(CanvasUpdate) },
  responses: { 200: jsonResponse("Updated", CanvasOut), 400: e400, 401: e401, 404: e404 },
});

export const deleteCanvas = createRoute({
  operationId: "deleteCanvas",
  method: "delete",
  path: "/v1/canvases/{id}",
  tags: ["widgets"],
  security,
  summary: "Clear a canvas (also Not now on a bot's first preview)",
  request: { params: idParam },
  responses: {
    200: jsonResponse("Deleted", z.object({ deleted: Uuid }).openapi("DeletedCanvas")),
    401: e401,
    404: e404,
  },
});

export const setCanvasGrant = createRoute({
  operationId: "setCanvasGrant",
  method: "put",
  path: "/v1/canvas-grants",
  tags: ["widgets"],
  security,
  summary:
    "Let a bot show things on the person's widgets (Show on my widgets), or stop it. Allowing shows what it left waiting; stopping clears what it showed",
  request: { body: jsonBody(SetCanvasGrant) },
  responses: {
    200: jsonResponse(
      "Saved",
      z
        .object({ allowed: z.boolean(), shown: z.number().int(), cleared: z.number().int() })
        .openapi("CanvasGrantSaved"),
    ),
    400: e400,
    401: e401,
    404: e404,
  },
});
