/** Gallery browse (D-184). Installing a skill stays on the skills route. */

import { routes } from "@casama/contracts";
import type { JwtClaims } from "@casama/db";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { galleryIndex, galleryItem } from "../../services/gallery.ts";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";

const claimsOf = (c: { get(k: "claims"): JwtClaims | undefined }) => {
  const claims = c.get("claims");
  if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
  return claims;
};

export function registerGalleryRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  app.openapi(routes.listGallery, async (c) => {
    claimsOf(c);
    const listed = await galleryIndex(deps.env);
    if (!listed.enabled)
      throw new ApiError(404, "gallery_disabled", "The gallery is turned off on this server.");
    const { type, q, tag, featured } = c.req.valid("query");
    const query = q?.trim().toLowerCase();
    const items = listed.items.filter((item) => {
      if (item.retired) return false;
      if (type && item.type !== type) return false;
      if (tag && !item.tags.includes(tag)) return false;
      if (featured === "true" && !item.featured) return false;
      if (featured === "false" && item.featured) return false;
      if (!query) return true;
      const hay = [item.name, item.author.name, item.id, ...item.tags].join(" ").toLowerCase();
      return hay.includes(query);
    });
    return c.json({ available: listed.available, items }, 200);
  });

  app.openapi(routes.getGalleryItem, async (c) => {
    claimsOf(c);
    const { type, id } = c.req.valid("param");
    const found = await galleryItem(deps.env, type, id);
    return c.json(
      {
        ...found.item,
        document: found.document,
        skill_md: found.skillMd,
      },
      200,
    );
  });
}
