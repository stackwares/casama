import { createRoute, z } from "@hono/zod-openapi";
import { jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";
import {
  Creation,
  CreationDetail,
  CreationList,
  CreationListQuery,
  UpdateCreationRequest,
} from "../creations.ts";

const security = [{ bearerAuth: [] }];
const { 401: e401, 403: e403, 404: e404 } = problemResponses;
const idParam = z.object({ id: Uuid });
const binary = (types: string[]) =>
  Object.fromEntries(types.map((t) => [t, { schema: z.string().openapi({ format: "binary" }) }]));

export const listCreations = createRoute({
  operationId: "listCreations",
  method: "get",
  path: "/v1/creations",
  tags: ["creations"],
  security,
  summary: "The Library: things bots made that you can open, newest first (D-274)",
  request: { query: CreationListQuery },
  responses: { 200: jsonResponse("Creations", CreationList), 401: e401 },
});

export const getCreation = createRoute({
  operationId: "getCreation",
  method: "get",
  path: "/v1/creations/{id}",
  tags: ["creations"],
  security,
  request: { params: idParam },
  responses: { 200: jsonResponse("Creation", CreationDetail), 401: e401, 404: e404 },
});

export const updateCreation = createRoute({
  operationId: "updateCreation",
  method: "patch",
  path: "/v1/creations/{id}",
  tags: ["creations"],
  security,
  summary: "Rename, relabel, pin or mark opened",
  request: { params: idParam, body: jsonBody(UpdateCreationRequest) },
  responses: { 200: jsonResponse("Creation", Creation), 401: e401, 403: e403, 404: e404 },
});

export const deleteCreation = createRoute({
  operationId: "deleteCreation",
  method: "delete",
  path: "/v1/creations/{id}",
  tags: ["creations"],
  security,
  summary: "Hides it now; the bytes go after 30 days unless it's restored",
  request: { params: idParam },
  responses: { 200: jsonResponse("Deleted", Creation), 401: e401, 403: e403, 404: e404 },
});

export const restoreCreation = createRoute({
  operationId: "restoreCreation",
  method: "post",
  path: "/v1/creations/{id}/restore",
  tags: ["creations"],
  security,
  request: { params: idParam },
  responses: { 200: jsonResponse("Restored", Creation), 401: e401, 403: e403, 404: e404 },
});

export const getCreationContent = createRoute({
  operationId: "getCreationContent",
  method: "get",
  path: "/v1/creations/{id}/content",
  tags: ["creations"],
  security,
  summary: "The bytes (pictures, videos, sound; one byte range honoured). Pages open by view link",
  request: { params: idParam },
  responses: {
    200: { description: "Contents", content: binary(["application/octet-stream"]) },
    206: { description: "A byte range", content: binary(["application/octet-stream"]) },
    401: e401,
    404: e404,
  },
});

export const getCreationCover = createRoute({
  operationId: "getCreationCover",
  method: "get",
  path: "/v1/creations/{id}/cover",
  tags: ["creations"],
  security,
  summary: "The picture for its card, when it has one (has_cover)",
  request: { params: idParam },
  responses: {
    200: { description: "Cover", content: binary(["image/jpeg", "image/png", "image/webp"]) },
    401: e401,
    404: e404,
  },
});

export const getCreationPreview = createRoute({
  operationId: "getCreationPreview",
  method: "get",
  path: "/v1/creations/{id}/preview",
  tags: ["creations"],
  security,
  summary: "A PDF of a document, made when it was kept, so it opens without its computer (D-280)",
  request: { params: idParam },
  responses: {
    200: { description: "PDF", content: binary(["application/pdf"]) },
    401: e401,
    404: e404,
  },
});

export const duplicateCreation = createRoute({
  operationId: "duplicateCreation",
  method: "post",
  path: "/v1/creations/{id}/duplicate",
  tags: ["creations"],
  security,
  summary: "A private copy to change while the original stays as it is (D-291)",
  request: { params: idParam },
  responses: { 201: jsonResponse("The copy", Creation), 401: e401, 403: e403, 404: e404 },
});
