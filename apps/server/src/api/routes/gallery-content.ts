/**
 * More from the open gallery (D-241): routine ideas and the reviewed plugin directory (starter
 * bots join GET /v1/templates, skills the skill catalog), plus the remote app settings.
 */
import { routes } from "@casama/contracts";
import type { JwtClaims } from "@casama/db";
import { checkAppConfig } from "@casama/domain";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { sql } from "drizzle-orm";
import { getAppConfig, setAppConfig } from "../../services/app-config.ts";
import { galleryPlugins, galleryRoutines } from "../../services/gallery.ts";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { requireClaims } from "./autonomy.ts";

export interface GalleryContentOptions {
  /** Where the gallery is read from; tests serve gallery/ locally. Default: GALLERY_URL. */
  galleryFetch?: typeof fetch;
}

export function registerGalleryContentRoutes(
  app: OpenAPIHono<AppEnv>,
  deps: AppDeps,
  opts: GalleryContentOptions = {},
) {
  const { db, env } = deps;

  /** Instance owners: INSTANCE_ADMIN_EMAILS, or the first user to sign up when unset (as in Admin). */
  const requireOwner = async (claims: JwtClaims) => {
    const allow = (env.INSTANCE_ADMIN_EMAILS ?? "")
      .split(",")
      .map((e) => e.trim().toLowerCase())
      .filter(Boolean);
    const [u] = await db.execute<{ email: string | null; first: boolean }>(sql`
      select u.email, u.id = (select id from auth.users order by created_at limit 1) as first
      from auth.users u where u.id = ${claims.sub}::uuid`);
    const ok = allow.length ? allow.includes((u?.email ?? "").toLowerCase()) : !!u?.first;
    if (!ok)
      throw new ApiError(403, "not_instance_owner", "Only the instance owner can change this");
  };

  app.openapi(routes.listRoutineIdeas, async (c) => {
    requireClaims(c.get("claims"));
    const items = await galleryRoutines(env, opts.galleryFetch);
    items.sort((a, b) => Number(b.featured) - Number(a.featured) || a.name.localeCompare(b.name));
    return c.json({ items }, 200);
  });

  app.openapi(routes.listPluginDirectory, async (c) => {
    requireClaims(c.get("claims"));
    const items = await galleryPlugins(env, opts.galleryFetch);
    items.sort((a, b) => a.name.localeCompare(b.name));
    return c.json({ items }, 200);
  });

  // No sign-in: an app checks this before anything else, including whether it may run at all.
  app.openapi(routes.getAppConfig, async (c) => {
    c.header("Cache-Control", "public, max-age=60");
    return c.json(await getAppConfig(db), 200);
  });

  app.openapi(routes.adminAppConfig, async (c) => {
    await requireOwner(requireClaims(c.get("claims")));
    return c.json(await getAppConfig(db), 200);
  });

  app.openapi(routes.adminSetAppConfig, async (c) => {
    const claims = requireClaims(c.get("claims"));
    await requireOwner(claims);
    const { config, errors } = checkAppConfig(c.req.valid("json"));
    if (!config) throw new ApiError(400, "validation_failed", errors.join("; "));
    deps.logger.info("app config changed", { by: claims.sub });
    return c.json(await setAppConfig(db, config), 200);
  });
}
