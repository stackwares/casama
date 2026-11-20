import { createRoute, z } from "@hono/zod-openapi";
import {
  BotPictureList,
  GenerateBotPicturesRequest,
  SetBotPictureRequest,
} from "../bot-pictures.ts";
import { jsonBody, jsonResponse, Problem, problemResponses, Uuid } from "../common.ts";
import { Organization } from "../workspaces.ts";

// Workspace pictures (docs/WORKSPACE-PICTURES-PLAN.md). Mirrors bot-pictures.ts.

const security = [{ bearerAuth: [] }];
const { 400: e400, 401: e401, 403: e403, 404: e404, 429: e429 } = problemResponses;
const idParam = z.object({ id: Uuid });
const imageParams = z.object({ id: Uuid, image_id: Uuid });
const binary = (types: string[]) =>
  Object.fromEntries(types.map((t) => [t, { schema: z.string().openapi({ format: "binary" }) }]));

export const getWorkspaceImage = createRoute({
  operationId: "getWorkspaceImage",
  method: "get",
  path: "/v1/workspace-images/{id}",
  tags: ["workspaces"],
  summary: "A workspace's picture (no token; cached for good)",
  request: {
    params: z.object({ id: z.string().openapi({ format: "uuid" }) }),
    query: z.object({
      size: z.enum(["128", "512"]).optional().openapi({ description: "Pixels; default 512" }),
      format: z
        .enum(["webp", "png"])
        .optional()
        .openapi({ description: "Default webp; png when requested" }),
    }),
  },
  responses: {
    200: { description: "Picture", content: binary(["image/webp", "image/png"]) },
    404: e404,
  },
});

export const setWorkspacePicture = createRoute({
  operationId: "setWorkspacePicture",
  method: "put",
  path: "/v1/orgs/{id}/image",
  tags: ["workspaces"],
  security,
  summary: "Give a workspace a picture of its own",
  description:
    "Send the cropped square; the server makes the sizes the apps show, strips metadata and extracts colours. Twenty a day per workspace.",
  request: { params: idParam, body: jsonBody(SetBotPictureRequest) },
  responses: {
    200: jsonResponse("The workspace", Organization),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
    429: e429,
  },
});

export const removeWorkspacePicture = createRoute({
  operationId: "removeWorkspacePicture",
  method: "delete",
  path: "/v1/orgs/{id}/image",
  tags: ["workspaces"],
  security,
  summary: "Stop using a picture: back to the workspace's icon and colour",
  request: { params: idParam },
  responses: { 200: jsonResponse("The workspace", Organization), 401: e401, 403: e403, 404: e404 },
});

export const listWorkspacePictures = createRoute({
  operationId: "listWorkspacePictures",
  method: "get",
  path: "/v1/orgs/{id}/images",
  tags: ["workspaces"],
  security,
  summary: "A workspace's recent pictures, the one in use first, then by when they were last used",
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

export const useWorkspacePicture = createRoute({
  operationId: "useWorkspacePicture",
  method: "post",
  path: "/v1/orgs/{id}/images/{image_id}/use",
  tags: ["workspaces"],
  security,
  summary: "Switch to one of the workspace's recent or drawn pictures (also how Undo works)",
  request: { params: imageParams },
  responses: { 200: jsonResponse("The workspace", Organization), 401: e401, 403: e403, 404: e404 },
});

export const getWorkspacePictureOriginal = createRoute({
  operationId: "getWorkspacePictureOriginal",
  method: "get",
  path: "/v1/orgs/{id}/images/{image_id}/original",
  tags: ["workspaces"],
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

export const generateWorkspacePictures = createRoute({
  operationId: "generateWorkspacePictures",
  method: "post",
  path: "/v1/orgs/{id}/images/generate",
  tags: ["workspaces"],
  security,
  summary: "Draw emblem pictures for a workspace with AI",
  description:
    "Draws one or two candidates (normal image credits each, after Casama's safety check). They don't change the workspace until one is used; unused ones are deleted after a day.",
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
