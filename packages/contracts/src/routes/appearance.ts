import { createRoute, z } from "@hono/zod-openapi";
import { WallpaperDownloadRequest, WallpaperPhotoList } from "../appearance.ts";
import { jsonBody, jsonResponse, problemResponses } from "../common.ts";

const security = [{ bearerAuth: [] }];
const { 400: e400, 401: e401, 404: e404 } = problemResponses;

export const searchWallpapers = createRoute({
  operationId: "searchWallpapers",
  method: "get",
  path: "/v1/wallpapers",
  tags: ["appearance"],
  security,
  summary:
    "Search wallpaper photos. Only when the server has a photo source configured (config.wallpapers_enabled); 404 otherwise",
  request: {
    query: z.object({
      q: z.string().max(100).optional(),
      page: z.coerce.number().int().min(1).max(50).optional(),
    }),
  },
  responses: { 200: jsonResponse("Photos", WallpaperPhotoList), 401: e401, 404: e404 },
});

export const trackWallpaperDownload = createRoute({
  operationId: "trackWallpaperDownload",
  method: "post",
  path: "/v1/wallpapers/download",
  tags: ["appearance"],
  security,
  summary: "Tell the photo source a photo was chosen (Unsplash requires this)",
  request: { body: jsonBody(WallpaperDownloadRequest) },
  responses: { 204: { description: "Recorded" }, 400: e400, 401: e401, 404: e404 },
});
