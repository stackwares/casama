import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";

/** Bot pictures (docs/BOT-PICTURES-PLAN.md §6). */

const ts = z.string().openapi({ format: "date-time" });

/** Where the last crop sat on the original, so Re-crop opens where it was left. */
export const BotPictureCrop = z
  .object({
    x: z
      .number()
      .min(-10)
      .max(10)
      .openapi({ description: "Centre of the frame on the original, 0–1 across" }),
    y: z
      .number()
      .min(-10)
      .max(10)
      .openapi({ description: "Centre of the frame on the original, 0–1 down" }),
    scale: z
      .number()
      .min(0.01)
      .max(100)
      .openapi({ description: "Frame side as a share of the original's shorter side" }),
    rotation: z.number().int().min(0).max(3).openapi({ description: "Quarter turns clockwise" }),
    mirror: z.boolean(),
    background: z
      .enum(["none", "bot", "white", "black"])
      .openapi({ description: "What fills see-through parts" }),
  })
  .openapi("BotPictureCrop");

export const SetBotPictureRequest = z
  .object({
    data: z
      .base64()
      .max(5_600_000)
      .openapi({ description: "The cropped square (PNG, JPEG or WebP), base64" }),
    original: z
      .base64()
      .max(5_600_000)
      .optional()
      .openapi({ description: "The picture before cropping, for Re-crop, base64" }),
    crop: BotPictureCrop.optional(),
    source: z.enum(["upload", "chat"]).optional().openapi({
      description: "upload (camera, files, paste, drop) or chat (a picture from a conversation)",
    }),
  })
  .openapi("SetBotPictureRequest");

export const BotPicture = z
  .object({
    id: Uuid,
    avatar_url: z.string().openapi({ description: "The bots.avatar_url value that uses it" }),
    source: z.enum(["upload", "chat", "generated", "bot"]),
    in_use: z.boolean(),
    has_original: z.boolean(),
    crop: BotPictureCrop.optional(),
    created_at: ts,
  })
  .openapi("BotPicture");

export const BotPictureList = z.object({ items: z.array(BotPicture) }).openapi("BotPictureList");

export const BotPictureStyle = z
  .enum(["cloud", "soft3d", "watercolor", "flat", "pixel", "line", "photo"])
  .openapi("BotPictureStyle");

export const GenerateBotPicturesRequest = z
  .object({
    style: BotPictureStyle,
    description: z.string().trim().max(400).optional().openapi({
      description: "What to draw; empty: Casama works it out from the bot's name and instructions",
    }),
    count: z.number().int().min(1).max(2).optional(),
  })
  .openapi("GenerateBotPicturesRequest");
