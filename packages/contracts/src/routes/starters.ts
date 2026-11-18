import { createRoute, z } from "@hono/zod-openapi";
import { jsonResponse, problemResponses, Uuid } from "../common.ts";
import { ChatStarters } from "../starters.ts";

/**
 * Starter requests (D-338): the tappable requests in an empty chat, written for the person from
 * their local time, the bot's apps, what they shared about themselves and what they asked lately.
 */
const security = [{ bearerAuth: [] }];
const { 401: e401, 404: e404 } = problemResponses;

export const getBotStarters = createRoute({
  operationId: "getBotStarters",
  method: "get",
  path: "/v1/bots/{id}/starters",
  tags: ["bots"],
  security,
  summary: "Starter requests for an empty chat with this bot, written for you",
  request: { params: z.object({ id: Uuid }) },
  responses: { 200: jsonResponse("Starters", ChatStarters), 401: e401, 404: e404 },
});
