import { createRoute, z } from "@hono/zod-openapi";
import { jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";
import { MessageReactionList, MessageReactions, SetReactionRequest } from "../reactions.ts";

// Message reactions (D-331).
const security = [{ bearerAuth: [] }];
const { 400: e400, 401: e401, 404: e404, 429: e429 } = problemResponses;
const params = z.object({ id: Uuid, message_id: Uuid });

export const setReaction = createRoute({
  operationId: "setReaction",
  method: "put",
  path: "/v1/conversations/{id}/messages/{message_id}/reaction",
  tags: ["chat"],
  security,
  summary: "React to a message with an emoji",
  description:
    "Sets your reaction, replacing the one you had (one per person per message). Works on people's messages and bots' replies in any chat you can read. It doesn't start a run; the bot sees it the next time it works in the chat. 400 `invalid_emoji` when the text isn't exactly one emoji.",
  request: { params, body: jsonBody(SetReactionRequest) },
  responses: {
    200: jsonResponse("The message's reactions", MessageReactions),
    400: e400,
    401: e401,
    404: e404,
    429: e429,
  },
});

export const removeReaction = createRoute({
  operationId: "removeReaction",
  method: "delete",
  path: "/v1/conversations/{id}/messages/{message_id}/reaction",
  tags: ["chat"],
  security,
  summary: "Take back your reaction to a message",
  request: { params },
  responses: {
    200: jsonResponse("The message's reactions", MessageReactions),
    401: e401,
    404: e404,
    429: e429,
  },
});

export const listMessageReactions = createRoute({
  operationId: "listMessageReactions",
  method: "get",
  path: "/v1/conversations/{id}/messages/{message_id}/reactions",
  tags: ["chat"],
  security,
  summary: "Who reacted to a message, and with what",
  description: "Every reaction, oldest first, with each person's or bot's name and picture.",
  request: { params },
  responses: {
    200: jsonResponse("Reactions", MessageReactionList),
    401: e401,
    404: e404,
  },
});
