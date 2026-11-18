import { createRoute, z } from "@hono/zod-openapi";
import { jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";
import {
  ExportPackRequest,
  GalleryPackList,
  InstallPackRequest,
  Pack,
  PackExport,
  PackInstallResult,
  PackList,
  PackPreview,
  PackShare,
  PackShareView,
  PackUpdatePreview,
  PreviewPackRequest,
  SharePackRequest,
  UpdatePackRequest,
} from "../packs.ts";

const security = [{ bearerAuth: [] }];
const { 400: e400, 401: e401, 403: e403, 404: e404, 409: e409 } = problemResponses;
const idParam = z.object({ id: Uuid });
const tags = ["packs"];

export const previewPack = createRoute({
  operationId: "previewPack",
  method: "post",
  path: "/v1/packs/preview",
  tags,
  security,
  summary: "Everything a pack would add, before anything is created",
  request: { body: jsonBody(PreviewPackRequest) },
  responses: {
    200: jsonResponse("Preview", PackPreview),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
  },
});

export const installPack = createRoute({
  operationId: "installPack",
  method: "post",
  path: "/v1/packs",
  tags,
  security,
  summary: "Install a pack for a workspace, pinned to the previewed commit",
  request: { body: jsonBody(InstallPackRequest) },
  responses: {
    201: jsonResponse("Installed", PackInstallResult),
    202: jsonResponse("Waiting for an admin", PackInstallResult),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
    409: e409,
  },
});

export const listPacks = createRoute({
  operationId: "listPacks",
  method: "get",
  path: "/v1/packs",
  tags,
  security,
  summary: "The packs a workspace installed",
  request: { query: z.object({ org_id: Uuid }) },
  responses: { 200: jsonResponse("Packs", PackList), 401: e401, 404: e404 },
});

export const getPack = createRoute({
  operationId: "getPack",
  method: "get",
  path: "/v1/packs/{id}",
  tags,
  security,
  summary: "One installed pack and what it made",
  request: { params: idParam },
  responses: { 200: jsonResponse("Pack", Pack), 401: e401, 404: e404 },
});

export const getPackUpdate = createRoute({
  operationId: "getPackUpdate",
  method: "get",
  path: "/v1/packs/{id}/update",
  tags,
  security,
  summary: "What a newer version of the pack changes, item by item",
  request: { params: idParam },
  responses: { 200: jsonResponse("Update", PackUpdatePreview), 401: e401, 404: e404 },
});

export const updatePack = createRoute({
  operationId: "updatePack",
  method: "post",
  path: "/v1/packs/{id}/update",
  tags,
  security,
  summary: "Update a pack; items the person edited stay theirs",
  request: { params: idParam, body: jsonBody(UpdatePackRequest) },
  responses: {
    200: jsonResponse("Updated", PackInstallResult),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
    409: e409,
  },
});

export const removePack = createRoute({
  operationId: "removePack",
  method: "delete",
  path: "/v1/packs/{id}",
  tags,
  security,
  summary:
    "Remove a pack: its tools and untouched items go; edited items and (by default) bots stay",
  request: {
    params: idParam,
    query: z.object({
      bots: z.enum(["keep", "delete"]).optional().openapi({
        description: "Also delete the bots it created (default keep)",
      }),
    }),
  },
  responses: {
    200: jsonResponse("Removed", z.object({ deleted: Uuid, kept: z.number().int() })),
    401: e401,
    403: e403,
    404: e404,
  },
});

export const exportPack = createRoute({
  operationId: "exportPack",
  method: "post",
  path: "/v1/orgs/{id}/packs/export",
  tags,
  security,
  summary: "Turn bots, skills, routines and a look into a pack's files (nothing private)",
  request: { params: idParam, body: jsonBody(ExportPackRequest) },
  responses: {
    200: jsonResponse("Files", PackExport),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
  },
});

export const sharePack = createRoute({
  operationId: "sharePack",
  method: "post",
  path: "/v1/orgs/{id}/packs/share",
  tags,
  security,
  summary: "Share a pack made from this workspace as a link (signed-in viewers, 30 days)",
  request: { params: idParam, body: jsonBody(SharePackRequest) },
  responses: {
    201: jsonResponse("Shared", PackShare),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
    409: e409,
  },
});

export const getPackShare = createRoute({
  operationId: "getPackShare",
  method: "get",
  path: "/v1/pack-shares/{token}",
  tags,
  security,
  summary: "A shared pack, for its preview",
  request: { params: z.object({ token: z.string().min(10).max(200) }) },
  responses: { 200: jsonResponse("Shared pack", PackShareView), 401: e401, 404: e404 },
});

export const revokePackShare = createRoute({
  operationId: "revokePackShare",
  method: "delete",
  path: "/v1/pack-shares/{token}",
  tags,
  security,
  summary: "End a pack share link (whoever made it, or a workspace admin)",
  request: { params: z.object({ token: z.string().min(10).max(200) }) },
  responses: {
    200: jsonResponse("Ended", z.object({ ok: z.boolean() })),
    401: e401,
    403: e403,
    404: e404,
  },
});

export const listGalleryPacks = createRoute({
  operationId: "listGalleryPacks",
  method: "get",
  path: "/v1/gallery/packs",
  tags,
  security,
  summary: "The Packs shelf: reviewed packs from the plugin directory and starter sets",
  responses: { 200: jsonResponse("Packs", GalleryPackList), 401: e401 },
});
