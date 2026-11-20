/**
 * Bot pictures (docs/BOT-PICTURES-PLAN.md §6): a bot's own picture, its recent ones, Re-crop's
 * original, and drawing new ones. The pictures live in public.bot_images and are served without a
 * token at /v1/bot-images/{id}, like profile photos (D-202).
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
import { botOut } from "./bots.ts";

/** Uploads a bot may take a day (camera, files, chat pictures). */
export const BOT_PICTURE_DAILY_UPLOADS = 20;
/** Drawn pictures a bot may get a day ("Make one with AI"). */
export const BOT_PICTURE_DAILY_DRAWINGS = 20;

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

type ImageRow = {
  id: string;
  source: "upload" | "chat" | "generated" | "bot";
  colors: string;
  has_original: boolean;
  crop: Record<string, unknown> | null;
  created_at: Date | string;
};

export function registerBotPictureRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;
  const claimsOf = (c: { get(k: "claims"): JwtClaims | undefined }) => {
    const claims = c.get("claims");
    if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
    return claims;
  };

  /** The bot as the caller sees it; 404 when they can't, 403 when they can't change it. */
  const bot = async (claims: JwtClaims, botId: string, need: "see" | "manage") => {
    const [b] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ org_id: string; name: string; avatar_url: string | null; manage: boolean }>(sql`
        select org_id, name, avatar_url, public.can_manage_bot(id) as manage
        from public.bots where id = ${botId}::uuid and public.can_access_bot(id)`),
    );
    if (!b) throw new ApiError(404, "bot_not_found", "Bot not found");
    if (need === "manage" && !b.manage)
      throw new ApiError(
        403,
        "forbidden",
        "Only people who manage this bot can change its picture",
      );
    return b;
  };

  const botResponse = async (botId: string) => {
    const [row] = await db.select().from(schema.bots).where(eq(schema.bots.id, botId));
    if (!row) throw new ApiError(404, "bot_not_found", "Bot not found");
    return botOut(row);
  };

  /** Counts one more upload or drawing for today; false when the bot is over its daily limit. */
  const spend = async (botId: string, kind: "uploads" | "drawings", n: number, limit: number) => {
    await db.execute(
      sql`delete from public.bot_image_counts where bot_id = ${botId}::uuid and day < current_date`,
    );
    const [r] = await db.execute<{ n: number }>(
      kind === "uploads"
        ? sql`insert into public.bot_image_counts (bot_id, uploads) values (${botId}::uuid, ${n})
              on conflict (bot_id, day) do update set uploads = bot_image_counts.uploads + ${n}
              returning uploads as n`
        : sql`insert into public.bot_image_counts (bot_id, drawings) values (${botId}::uuid, ${n})
              on conflict (bot_id, day) do update set drawings = bot_image_counts.drawings + ${n}
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

  // The picture itself, without a token: the id is random, only people who can see the bot are
  // given it, and a new picture gets a new id. Widgets ask for PNG at 128 px.
  app.openapi(routes.getBotImage, async (c) => {
    const id = c.req.param("id");
    const size = c.req.query("size") === "128" ? "small" : "large";
    const png = c.req.query("format") === "png";
    if (!UUID.test(id)) throw new ApiError(404, "picture_not_found", "No such picture");
    const [p] = await db.execute<{ bytes: Buffer }>(
      size === "small"
        ? sql`select small as bytes from public.bot_images where id = ${id}::uuid`
        : sql`select large as bytes from public.bot_images where id = ${id}::uuid`,
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

  app.openapi(routes.setBotPicture, async (c) => {
    const claims = claimsOf(c);
    const { id: botId } = c.req.valid("param");
    const body = c.req.valid("json");
    const b = await bot(claims, botId, "manage");
    if (!(await spend(botId, "uploads", 1, BOT_PICTURE_DAILY_UPLOADS)))
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
      made = await makeBotPicture(bytes, { botName: b.name });
      // The original is a nice-to-have (Re-crop): one that can't be kept doesn't stop the change.
      kept = original ? await makeOriginal(original).catch(() => null) : null;
    } catch (e) {
      if (e instanceof PictureError) throw new ApiError(400, e.code, e.message);
      throw e;
    }
    const [row] = await db.execute<{ id: string }>(sql`
      insert into public.bot_images (bot_id, org_id, created_by, source, large, small, original, original_type, crop, colors)
      values (${botId}::uuid, ${b.org_id}::uuid, ${claims.sub}::uuid, ${body.source ?? "upload"},
              ${made.large}, ${made.small}, ${kept?.bytes ?? null}, ${kept?.type ?? null},
              ${kept && body.crop ? JSON.stringify(body.crop) : null}::jsonb, ${made.colors})
      returning id`);
    if (!row) throw new ApiError(500, "picture_not_saved", "The picture couldn't be saved");
    await withUserSession(db, claims, (tx) =>
      tx.execute(
        sql`update public.bots set avatar_url = ${pictureAvatar(row.id, made.colors)} where id = ${botId}::uuid`,
      ),
    );
    return c.json(await botResponse(botId), 200);
  });

  app.openapi(routes.removeBotPicture, async (c) => {
    const claims = claimsOf(c);
    const { id: botId } = c.req.valid("param");
    await bot(claims, botId, "manage");
    // Back to the mascot it had before the picture, or its initials. The pictures stay in Recent.
    await withUserSession(db, claims, (tx) =>
      tx.execute(sql`
        update public.bots set avatar_url = prior_mascot
        where id = ${botId}::uuid and avatar_url like 'image:%'`),
    );
    return c.json(await botResponse(botId), 200);
  });

  app.openapi(routes.listBotPictures, async (c) => {
    const claims = claimsOf(c);
    const { id: botId } = c.req.valid("param");
    const candidates = c.req.valid("query").candidates === "true";
    const b = await bot(claims, botId, "see");
    const rows = await db.execute<ImageRow>(sql`
      select id, source, colors, original is not null as has_original, crop, created_at
      from public.bot_images
      where bot_id = ${botId}::uuid and candidate = ${candidates}
      order by coalesce(used_at, created_at) desc limit 8`);
    const inUse = inUseOf(b.avatar_url);
    const items = rows.map((r) => pictureOut(r, inUse));
    items.sort((x, y) => Number(y.in_use) - Number(x.in_use));
    return c.json({ items }, 200);
  });

  app.openapi(routes.useBotPicture, async (c) => {
    const claims = claimsOf(c);
    const { id: botId, image_id } = c.req.valid("param");
    await bot(claims, botId, "manage");
    const [img] = await db.execute<{ colors: string }>(sql`
      select colors from public.bot_images where id = ${image_id}::uuid and bot_id = ${botId}::uuid`);
    if (!img) throw new ApiError(404, "picture_not_found", "That picture is gone");
    await withUserSession(db, claims, (tx) =>
      tx.execute(
        sql`update public.bots set avatar_url = ${pictureAvatar(image_id, img.colors)} where id = ${botId}::uuid`,
      ),
    );
    return c.json(await botResponse(botId), 200);
  });

  app.openapi(routes.getBotPictureOriginal, async (c) => {
    const claims = claimsOf(c);
    const { id: botId, image_id } = c.req.valid("param");
    await bot(claims, botId, "manage");
    const [img] = await db.execute<{ original: Buffer | null; original_type: string | null }>(sql`
      select original, original_type from public.bot_images where id = ${image_id}::uuid and bot_id = ${botId}::uuid`);
    if (!img?.original || !img.original_type)
      throw new ApiError(404, "original_not_found", "The uncropped picture isn't kept any more");
    return c.body(new Uint8Array(img.original), 200, {
      "content-type": img.original_type,
      "cache-control": "private, no-store",
      "x-content-type-options": "nosniff",
    }) as never;
  });

  app.openapi(routes.generateBotPictures, async (c) => {
    const claims = claimsOf(c);
    const { id: botId } = c.req.valid("param");
    const body = c.req.valid("json");
    const b = await bot(claims, botId, "manage");
    if (!BOT_PICTURE_STYLES.includes(body.style))
      throw new ApiError(400, "invalid_style", "Unknown style");
    if (!(await spend(botId, "drawings", body.count ?? 2, BOT_PICTURE_DAILY_DRAWINGS)))
      throw new ApiError(
        429,
        "too_many_drawings",
        "That's a lot of drawings for one day. Try again tomorrow",
      );
    const out = await deps.workflows.generateBotPictures({
      orgId: b.org_id,
      botId,
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
      event: "bot_picture_drawn",
      userId: claims.sub,
      orgId: b.org_id,
      properties: { style: body.style, count: out.ids.length },
    });
    const rows = await db.execute<ImageRow>(sql`
      select id, source, colors, original is not null as has_original, crop, created_at
      from public.bot_images where id = any(${`{${out.ids.join(",")}}`}::uuid[]) order by created_at`);
    return c.json({ items: rows.map((r) => pictureOut(r, null)) }, 200);
  });
}
