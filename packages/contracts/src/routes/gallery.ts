import { createRoute, z } from "@hono/zod-openapi";
import { problemResponses } from "../common.ts";
import { GalleryDetail, GalleryList } from "../gallery.ts";

const security = [{ bearerAuth: [] }];
const { 401: e401, 404: e404 } = problemResponses;

export const listGallery = createRoute({
  operationId: "listGallery",
  method: "get",
  path: "/v1/gallery",
  tags: ["gallery"],
  security,
  summary: "Themes, color schemes, wallpapers and skills from the open gallery (D-184)",
  request: {
    query: z.object({
      type: z.enum(["theme", "scheme", "wallpaper", "skill"]).optional(),
      q: z.string().max(80).optional(),
      tag: z.string().max(24).optional(),
      featured: z.enum(["true", "false"]).optional(),
    }),
  },
  responses: {
    200: { description: "Gallery", content: { "application/json": { schema: GalleryList } } },
    401: e401,
    404: e404,
  },
});

export const getGalleryItem = createRoute({
  operationId: "getGalleryItem",
  method: "get",
  path: "/v1/gallery/{type}/{id}",
  tags: ["gallery"],
  security,
  summary: "One gallery item, including the document the app applies",
  request: {
    params: z.object({
      type: z.enum(["theme", "scheme", "wallpaper", "skill"]),
      id: z.string().min(1).max(64),
    }),
  },
  responses: {
    200: { description: "Item", content: { "application/json": { schema: GalleryDetail } } },
    401: e401,
    404: e404,
  },
});
