import { createRoute, z } from "@hono/zod-openapi";
import {
  BotPictureList,
  GenerateBotPicturesRequest,
  SetBotPictureRequest,
} from "../bot-pictures.ts";
import { Bot } from "../bots.ts";
import { jsonBody, jsonResponse, Problem, problemResponses, Uuid } from "../common.ts";

// Bot pictures (docs/BOT-PICTURES-PLAN.md §6). The picture itself is served at
// GET /v1/bot-images/{id} without a token: the id is random, only handed to people who can see the
// bot, and a new picture always gets a new id, so it's cached for good.

const security = [{ bearerAuth: [] }];
const { 400: e400, 401: e401, 403: e403, 404: e404, 429: e429 } = problemResponses;
const idParam = z.object({ id: Uuid });
const imageParams = z.object({ id: Uuid, image_id: Uuid });
const binary = (types: string[]) =>
  Object.fromEntries(types.map((t) => [t, { schema: z.string().openapi({ format: "binary" }) }]));

export const getBotImage = createRoute({
  operationId: "getBotImage",
  method: "get",
  path: "/v1/bot-images/{id}",
  tags: ["bots"],
  summary: "A bot's picture (no token; cached for good)",
  request: {
    params: z.object({ id: z.string().openapi({ format: "uuid" }) }),
    query: z.object({
      size: z.enum(["128", "512"]).optional().openapi({ description: "Pixels; default 512" }),
      format: z
        .enum(["webp", "png"])
        .optional()
        .openapi({ description: "Default webp; png for widgets" }),
    }),
  },
  responses: {
    200: { description: "Picture", content: binary(["image/webp", "image/png"]) },
    404: e404,
  },
});

export const setBotPicture = createRoute({
  operationId: "setBotPicture",
  method: "put",
  path: "/v1/bots/{id}/image",
  tags: ["bots"],
  security,
  summary: "Give a bot a picture of its own",
  description:
    "Send the cropped square; the server makes the sizes the apps show, drops the picture's metadata (camera, place) and takes the bot's colours from it. Twenty a day per bot.",
  request: { params: idParam, body: jsonBody(SetBotPictureRequest) },
  responses: {
    200: jsonResponse("The bot", Bot),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
    429: e429,
  },
});

export const removeBotPicture = createRoute({
  operationId: "removeBotPicture",
  method: "delete",
  path: "/v1/bots/{id}/image",
  tags: ["bots"],
  security,
  summary: "Stop using a picture: back to the mascot it had before, or its initials",
  request: { params: idParam },
  responses: { 200: jsonResponse("The bot", Bot), 401: e401, 403: e403, 404: e404 },
});

export const listBotPictures = createRoute({
  operationId: "listBotPictures",
  method: "get",
  path: "/v1/bots/{id}/images",
  tags: ["bots"],
  security,
  summary: "A bot's recent pictures, the one in use first, then by when they were last used",
  request: {
    params: idParam,
    query: z.object({
      candidates: z
        .enum(["true", "false"])
        .optional()
        .openapi({ description: "true: the drawn pictures nobody has used yet instead" }),
    }),
  },
  responses: { 200: jsonResponse("Pictures", BotPictureList), 401: e401, 403: e403, 404: e404 },
});

export const useBotPicture = createRoute({
  operationId: "useBotPicture",
  method: "post",
  path: "/v1/bots/{id}/images/{image_id}/use",
  tags: ["bots"],
  security,
  summary: "Switch to one of the bot's recent or drawn pictures (also how Undo works)",
  request: { params: imageParams },
  responses: { 200: jsonResponse("The bot", Bot), 401: e401, 403: e403, 404: e404 },
});

export const getBotPictureOriginal = createRoute({
  operationId: "getBotPictureOriginal",
  method: "get",
  path: "/v1/bots/{id}/images/{image_id}/original",
  tags: ["bots"],
  security,
  summary: "The picture before it was cropped, for Re-crop",
  request: { params: imageParams },
  responses: {
    200: { description: "Picture", content: binary(["image/jpeg", "image/png", "image/webp"]) },
    401: e401,
    403: e403,
    404: e404,
  },
});

export const generateBotPictures = createRoute({
  operationId: "generateBotPictures",
  method: "post",
  path: "/v1/bots/{id}/images/generate",
  tags: ["bots"],
  security,
  summary: "Draw pictures for a bot with AI",
  description:
    "Draws one or two candidates (normal image credits each, after Casama's safety check). They don't change the bot until one is used; unused ones are deleted after a day.",
  request: { params: idParam, body: jsonBody(GenerateBotPicturesRequest) },
  responses: {
    200: jsonResponse("Candidates", BotPictureList),
    400: e400,
    401: e401,
    402: {
      description: "Not enough credits",
      content: { "application/problem+json": { schema: Problem } },
    },
    403: e403,
    404: e404,
    429: e429,
  },
});
