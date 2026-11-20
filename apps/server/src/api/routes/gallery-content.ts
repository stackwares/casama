/**
 * More from the open gallery (D-241): routine ideas and the reviewed plugin directory (starter
 * bots join GET /v1/templates, skills the skill catalog), plus the remote app settings.
 */
import { routes } from "@casama/contracts";
import type { JwtClaims } from "@casama/db";
import {
  checkAppConfig,
  checkEmailCopy,
  type GalleryLists,
  QUICK_REACTIONS,
  TOOL_APP_NAMES,
} from "@casama/domain";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { sql } from "drizzle-orm";
import { defaultEmailCopy, getEmailCopy, setEmailCopy } from "../../services/account-emails.ts";
import { getAppConfig, setAppConfig } from "../../services/app-config.ts";
import { galleryLists, galleryPlugins, galleryRoutines } from "../../services/gallery.ts";
import { galleryStats, withStats } from "../../services/gallery-usage.ts";
import { DNS_PROVIDER_NAMES } from "../../sites/dns.ts";
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
    const stats = await galleryStats(db, env).catch(() => ({}));
    const items = withStats("routine", await galleryRoutines(env, opts.galleryFetch), stats);
    items.sort((a, b) => Number(b.featured) - Number(a.featured) || a.name.localeCompare(b.name));
    return c.json({ items }, 200);
  });

  app.openapi(routes.listPluginDirectory, async (c) => {
    requireClaims(c.get("claims"));
    const stats = await galleryStats(db, env).catch(() => ({}));
    const items = withStats("plugin", await galleryPlugins(env, opts.galleryFetch), stats);
    items.sort((a, b) => a.name.localeCompare(b.name));
    return c.json({ items }, 200);
  });

  // No sign-in: an app checks this before anything else, including whether it may run at all.
  app.openapi(routes.getAppConfig, async (c) => {
    c.header("Cache-Control", "public, max-age=60");
    const config = await getAppConfig(db);
    // Names and the quick reactions come from here so the apps keep copies only as fallbacks (D-372).
    // bot_email is on only when this server actually has hosted mail configured (and not switched off).
    const flags = {
      ...config.flags,
      bot_email: config.flags?.bot_email !== false && !!deps.hostedMail,
    };
    return c.json(
      {
        ...config,
        flags,
        quick_reactions: config.quick_reactions ?? [...QUICK_REACTIONS],
        names: { apps: TOOL_APP_NAMES, dns_providers: DNS_PROVIDER_NAMES },
      },
      200,
    );
  });

  // Content lists from the gallery (D-372). A list the gallery doesn't have is left out, and the
  // app keeps its own copy for it.
  app.openapi(routes.listGalleryLists, async (c) => {
    requireClaims(c.get("claims"));
    const lists: GalleryLists = await galleryLists(env, opts.galleryFetch).catch(() => ({}));
    c.header("Cache-Control", "private, max-age=300");
    return c.json(
      {
        ...(lists.searchWords ? { search_words: lists.searchWords } : {}),
        ...(lists.starters ? { starters: lists.starters } : {}),
      },
      200,
    );
  });

  app.openapi(routes.adminEmailCopy, async (c) => {
    await requireOwner(requireClaims(c.get("claims")));
    return c.json({ copy: await getEmailCopy(db), defaults: defaultEmailCopy() }, 200);
  });

  app.openapi(routes.adminSetEmailCopy, async (c) => {
    const claims = requireClaims(c.get("claims"));
    await requireOwner(claims);
    const { copy, errors } = checkEmailCopy(c.req.valid("json"));
    if (!copy) throw new ApiError(400, "validation_failed", errors.join("; "));
    deps.logger.info("email copy changed", { by: claims.sub });
    return c.json({ copy: await setEmailCopy(db, copy), defaults: defaultEmailCopy() }, 200);
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
