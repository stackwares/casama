import { createRoute, z } from "@hono/zod-openapi";
import { Channel, ChannelEvent, CreateChannelRequest, UpdateChannelRequest } from "../channels.ts";
import { jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";

const security = [{ bearerAuth: [] }];
const { 400: e400, 401: e401, 403: e403, 404: e404 } = problemResponses;
const idParam = z.object({ id: Uuid });
const tags = ["channels"];

export const listChannels = createRoute({
  operationId: "listChannels",
  method: "get",
  path: "/v1/channels",
  tags,
  security,
  summary: "A bot's chat apps",
  request: { query: z.object({ bot_id: Uuid }) },
  responses: {
    200: jsonResponse("Channels", z.object({ items: z.array(Channel) }).openapi("ChannelList")),
    401: e401,
  },
});

export const createChannel = createRoute({
  operationId: "createChannel",
  method: "post",
  path: "/v1/channels",
  tags,
  security,
  summary: "Connect a chat app to a bot",
  request: { body: jsonBody(CreateChannelRequest) },
  responses: { 201: jsonResponse("Channel", Channel), 400: e400, 401: e401, 403: e403, 404: e404 },
});

export const updateChannel = createRoute({
  operationId: "updateChannel",
  method: "patch",
  path: "/v1/channels/{id}",
  tags,
  security,
  request: { params: idParam, body: jsonBody(UpdateChannelRequest) },
  responses: { 200: jsonResponse("Channel", Channel), 401: e401, 403: e403, 404: e404 },
});

export const deleteChannel = createRoute({
  operationId: "deleteChannel",
  method: "delete",
  path: "/v1/channels/{id}",
  tags,
  security,
  request: { params: idParam },
  responses: {
    200: jsonResponse("Deleted", z.object({ deleted: Uuid }).openapi("DeletedChannel")),
    401: e401,
    403: e403,
    404: e404,
  },
});

export const listChannelEvents = createRoute({
  operationId: "listChannelEvents",
  method: "get",
  path: "/v1/channels/{id}/events",
  tags,
  security,
  summary: "Recent messages in and out, including ignored senders",
  request: { params: idParam },
  responses: {
    200: jsonResponse(
      "Events",
      z.object({ items: z.array(ChannelEvent) }).openapi("ChannelEventList"),
    ),
    401: e401,
    404: e404,
  },
});

export const startSlackInstall = createRoute({
  operationId: "startSlackInstall",
  method: "get",
  path: "/v1/channels/slack/install",
  tags,
  security,
  summary: "Add Casama's Slack app to a Slack workspace for this bot (D-277)",
  description:
    "Returns the Slack sign-in address to open. After the person allows it, the bot answers @mentions and direct messages in that Slack workspace, and approvals show buttons in the thread. 409 when this server has no Slack app (self-hosters connect their own app with a bot token instead).",
  request: { query: z.object({ bot_id: Uuid }) },
  responses: {
    200: jsonResponse("Slack sign-in", z.object({ url: z.url() }).openapi("SlackInstallLink")),
    401: e401,
    403: e403,
    404: e404,
    409: problemResponses[409],
  },
});
