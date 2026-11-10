import { createRoute, z } from "@hono/zod-openapi";
import { jsonResponse, problemResponses, Uuid } from "../common.ts";

const security = [{ bearerAuth: [] }];
const { 401: e401, 404: e404 } = problemResponses;

/** Attention rules (D-153): "Less like this" on a proactive message, saved as the bot's memory. */
export const lessLikeThis = createRoute({
  operationId: "lessLikeThis",
  method: "post",
  path: "/v1/notifications/{id}/less-like-this",
  tags: ["notifications"],
  security,
  summary: "Tell the bot to send fewer messages like this one",
  request: { params: z.object({ id: Uuid }) },
  responses: { 200: jsonResponse("Saved", z.object({ ok: z.boolean() })), 401: e401, 404: e404 },
});
