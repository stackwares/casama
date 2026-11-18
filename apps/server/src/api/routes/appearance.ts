/** Wallpaper photo search through the server (D-087), so the source's key never ships in the app. */

import { routes } from "@casama/contracts";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { unsplashSource, type WallpaperSource } from "../../services/wallpapers.ts";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";

export function registerAppearanceRoutes(
  app: OpenAPIHono<AppEnv>,
  deps: AppDeps,
  source: WallpaperSource | null = deps.env.UNSPLASH_ACCESS_KEY
    ? unsplashSource({ accessKey: deps.env.UNSPLASH_ACCESS_KEY, apiUrl: deps.env.UNSPLASH_API_URL })
    : null,
) {
  const requireSource = (c: { get(k: "claims"): unknown }) => {
    if (!c.get("claims"))
      throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
    if (!source)
      throw new ApiError(
        404,
        "wallpapers_disabled",
        "Wallpaper photos aren't set up on this server",
      );
    return source;
  };

  app.openapi(routes.searchWallpapers, async (c) => {
    const src = requireSource(c);
    const { q, page = 1 } = c.req.valid("query");
    try {
      return c.json({ items: await src.search(q, page), source: src.name }, 200);
    } catch (e) {
      throw new ApiError(502, "wallpapers_unavailable", (e as Error).message);
    }
  });

  app.openapi(routes.trackWallpaperDownload, async (c) => {
    const src = requireSource(c);
    const { download_location } = c.req.valid("json");
    try {
      await src.trackDownload(download_location);
    } catch (e) {
      throw new ApiError(400, "invalid_download", (e as Error).message);
    }
    return c.body(null, 204);
  });
}
