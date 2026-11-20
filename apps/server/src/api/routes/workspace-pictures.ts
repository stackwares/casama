/**
 * Workspace pictures (docs/WORKSPACE-PICTURES-PLAN.md): a workspace's own picture, its recent
 * ones, Re-crop's original, and drawing new ones. Mirrors bot-pictures.ts.
 */
import {
  BOT_PICTURE_STYLES,
  makeBotPicture,
  makeOriginal,
  PictureError,
  pictureAsPng,
  pictureAvatar,
  track,
} from "@casama/agent";
import { type BotPictureCrop, routes } from "@casama/contracts";
import { type JwtClaims, schema, withUserSession } from "@casama/db";
import type { OpenAPIHono, z } from "@hono/zod-openapi";
import { eq, sql } from "drizzle-orm";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { iso } from "../util.ts";

/** Uploads a workspace may take a day (camera, files, paste, drop). */
export const WORKSPACE_PICTURE_DAILY_UPLOADS = 20;
/** Drawn pictures a workspace may get a day ("Make one with AI"). */
export const WORKSPACE_PICTURE_DAILY_DRAWINGS = 20;

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

type ImageRow = {
  id: string;
  source: "upload" | "generated";
  colors: string;
  has_original: boolean;
  crop: Record<string, unknown> | null;
  created_at: Date | string;
};

export function registerWorkspacePictureRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;
  const claimsOf = (c: { get(k: "claims"): JwtClaims | undefined }) => {
    const claims = c.get("claims");
    if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
    return claims;
  };

  /** The workspace as the caller sees it; 404 when not a member, 403 when not an admin. */
  const org = async (claims: JwtClaims, orgId: string, need: "see" | "manage") => {
    const [o] = await withUserSession(db, claims, (tx) =>
      tx.execute<{
        id: string;
        name: string;
        avatar_url: string | null;
        manage: boolean;
      }>(sql`
        select id, name, avatar_url, public.has_role(id, 'admin') as manage
        from public.organizations where id = ${orgId}::uuid`),
    );
    if (!o) throw new ApiError(404, "org_not_found", "Workspace not found");
    if (need === "manage" && !o.manage)
      throw new ApiError(
        403,
        "forbidden",
        "Only owners and admins can change this workspace's picture",
      );
    return o;
  };

  const orgResponse = async (orgId: string) => {
    const [row] = await db
      .select()
      .from(schema.organizations)
      .where(eq(schema.organizations.id, orgId));
    if (!row) throw new ApiError(404, "org_not_found", "Workspace not found");
    return {
      id: row.id,
      name: row.name,
      slug: row.slug,
      plan: row.plan,
      region: row.region,
      icon: row.icon ?? null,
      color: row.color ?? null,
      avatar_url: row.avatarUrl ?? null,
      created_at: iso(row.createdAt),
    };
  };

  /** Counts one more upload or drawing for today; false when over the daily limit. */
  const spend = async (orgId: string, kind: "uploads" | "drawings", n: number, limit: number) => {
    await db.execute(
      sql`delete from public.workspace_image_counts where org_id = ${orgId}::uuid and day < current_date`,
    );
    const [r] = await db.execute<{ n: number }>(
      kind === "uploads"
        ? sql`insert into public.workspace_image_counts (org_id, uploads) values (${orgId}::uuid, ${n})
              on conflict (org_id, day) do update set uploads = workspace_image_counts.uploads + ${n}
              returning uploads as n`
        : sql`insert into public.workspace_image_counts (org_id, drawings) values (${orgId}::uuid, ${n})
              on conflict (org_id, day) do update set drawings = workspace_image_counts.drawings + ${n}
              returning drawings as n`,
    );
    return (r?.n ?? 0) <= limit;
  };

  const pictureOut = (r: ImageRow, inUse: string | null) => ({
    id: r.id,
    avatar_url: pictureAvatar(r.id, r.colors),
    source: r.source,
    in_use: inUse === r.id,
    has_original: r.has_original,
    ...(r.crop ? { crop: r.crop as z.infer<typeof BotPictureCrop> } : {}),
    created_at: iso(r.created_at instanceof Date ? r.created_at : new Date(r.created_at)),
  });

  const inUseOf = (avatar: string | null) =>
    /^image:([0-9a-f-]{36}):/.exec(avatar ?? "")?.[1] ?? null;

  app.openapi(routes.getWorkspaceImage, async (c) => {
    const id = c.req.param("id");
    const size = c.req.query("size") === "128" ? "small" : "large";
    const png = c.req.query("format") === "png";
    if (!UUID.test(id)) throw new ApiError(404, "picture_not_found", "No such picture");
    const [p] = await db.execute<{ bytes: Buffer }>(
      size === "small"
        ? sql`select small as bytes from public.workspace_images where id = ${id}::uuid`
        : sql`select large as bytes from public.workspace_images where id = ${id}::uuid`,
    );
    if (!p) throw new ApiError(404, "picture_not_found", "No such picture");
    const body = png ? await pictureAsPng(p.bytes) : new Uint8Array(p.bytes);
    return c.body(new Uint8Array(body), 200, {
      "content-type": png ? "image/png" : "image/webp",
      "cache-control": "public, max-age=31536000, immutable",
      "content-security-policy": "default-src 'none'",
      "x-content-type-options": "nosniff",
    }) as never;
  });

  app.openapi(routes.setWorkspacePicture, async (c) => {
    const claims = claimsOf(c);
    const { id: orgId } = c.req.valid("param");
    const body = c.req.valid("json");
    const o = await org(claims, orgId, "manage");
    if (!(await spend(orgId, "uploads", 1, WORKSPACE_PICTURE_DAILY_UPLOADS)))
      throw new ApiError(
        429,
        "too_many_pictures",
        "That's a lot of new pictures for one day. Try again tomorrow",
      );
    const bytes = new Uint8Array(Buffer.from(body.data, "base64"));
    const original = body.original ? new Uint8Array(Buffer.from(body.original, "base64")) : null;
    let made: Awaited<ReturnType<typeof makeBotPicture>>;
    let kept: Awaited<ReturnType<typeof makeOriginal>> | null = null;
    try {
      made = await makeBotPicture(bytes, { botName: o.name });
      kept = original ? await makeOriginal(original).catch(() => null) : null;
    } catch (e) {
      if (e instanceof PictureError) throw new ApiError(400, e.code, e.message);
      throw e;
    }
    const [row] = await db.execute<{ id: string }>(sql`
      insert into public.workspace_images (org_id, created_by, source, large, small, original, original_type, crop, colors)
      values (${orgId}::uuid, ${claims.sub}::uuid, 'upload',
              ${made.large}, ${made.small}, ${kept?.bytes ?? null}, ${kept?.type ?? null},
              ${kept && body.crop ? JSON.stringify(body.crop) : null}::jsonb, ${made.colors})
      returning id`);
    if (!row) throw new ApiError(500, "picture_not_saved", "The picture couldn't be saved");
    await withUserSession(db, claims, (tx) =>
      tx.execute(
        sql`update public.organizations set avatar_url = ${pictureAvatar(row.id, made.colors)} where id = ${orgId}::uuid`,
      ),
    );
    return c.json(await orgResponse(orgId), 200);
  });

  app.openapi(routes.removeWorkspacePicture, async (c) => {
    const claims = claimsOf(c);
    const { id: orgId } = c.req.valid("param");
    await org(claims, orgId, "manage");
    await withUserSession(db, claims, (tx) =>
      tx.execute(sql`
        update public.organizations set avatar_url = null
        where id = ${orgId}::uuid`),
    );
    return c.json(await orgResponse(orgId), 200);
  });

  app.openapi(routes.listWorkspacePictures, async (c) => {
    const claims = claimsOf(c);
    const { id: orgId } = c.req.valid("param");
    const candidates = c.req.valid("query").candidates === "true";
    const o = await org(claims, orgId, "see");
    const rows = await db.execute<ImageRow>(sql`
      select id, source, colors, original is not null as has_original, crop, created_at
      from public.workspace_images
      where org_id = ${orgId}::uuid and candidate = ${candidates}
      order by coalesce(used_at, created_at) desc limit 8`);
    const inUse = inUseOf(o.avatar_url);
    const items = rows.map((r) => pictureOut(r, inUse));
    items.sort((x, y) => Number(y.in_use) - Number(x.in_use));
    return c.json({ items }, 200);
  });

  app.openapi(routes.useWorkspacePicture, async (c) => {
    const claims = claimsOf(c);
    const { id: orgId, image_id } = c.req.valid("param");
    await org(claims, orgId, "manage");
    const [img] = await db.execute<{ colors: string }>(sql`
      select colors from public.workspace_images where id = ${image_id}::uuid and org_id = ${orgId}::uuid`);
    if (!img) throw new ApiError(404, "picture_not_found", "That picture is gone");
    await withUserSession(db, claims, (tx) =>
      tx.execute(
        sql`update public.organizations set avatar_url = ${pictureAvatar(image_id, img.colors)} where id = ${orgId}::uuid`,
      ),
    );
    return c.json(await orgResponse(orgId), 200);
  });

  app.openapi(routes.getWorkspacePictureOriginal, async (c) => {
    const claims = claimsOf(c);
    const { id: orgId, image_id } = c.req.valid("param");
    await org(claims, orgId, "manage");
    const [img] = await db.execute<{ original: Buffer | null; original_type: string | null }>(sql`
      select original, original_type from public.workspace_images where id = ${image_id}::uuid and org_id = ${orgId}::uuid`);
    if (!img?.original || !img.original_type)
      throw new ApiError(404, "original_not_found", "The uncropped picture isn't kept any more");
    return c.body(new Uint8Array(img.original), 200, {
      "content-type": img.original_type,
      "cache-control": "private, no-store",
      "x-content-type-options": "nosniff",
    }) as never;
  });

  app.openapi(routes.generateWorkspacePictures, async (c) => {
    const claims = claimsOf(c);
    const { id: orgId } = c.req.valid("param");
    const body = c.req.valid("json");
    await org(claims, orgId, "manage");
    if (!BOT_PICTURE_STYLES.includes(body.style))
      throw new ApiError(400, "invalid_style", "Unknown style");
    if (!(await spend(orgId, "drawings", body.count ?? 2, WORKSPACE_PICTURE_DAILY_DRAWINGS)))
      throw new ApiError(
        429,
        "too_many_drawings",
        "That's a lot of drawings for one day. Try again tomorrow",
      );
    const out = await deps.workflows.generateWorkspacePictures({
      orgId,
      userId: claims.sub,
      style: body.style,
      description: body.description || undefined,
      count: body.count ?? 2,
    });
    if (!out.ok) {
      const status =
        out.code === "out_of_credits"
          ? 402
          : out.code === "content_refused" || out.code === "invalid_arguments"
            ? 400
            : out.code === "no_media_provider"
              ? 409
              : 502;
      throw new ApiError(status as 400, out.code, out.error);
    }
    track(db, {
      event: "workspace_picture_drawn",
      userId: claims.sub,
      orgId,
      properties: { style: body.style, count: out.ids.length },
    });
    const rows = await db.execute<ImageRow>(sql`
      select id, source, colors, original is not null as has_original, crop, created_at
      from public.workspace_images where id = any(${`{${out.ids.join(",")}}`}::uuid[]) order by created_at`);
    return c.json({ items: rows.map((r) => pictureOut(r, null)) }, 200);
  });
}
