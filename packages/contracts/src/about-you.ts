import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";

/** About you (D-169): see routes/about-you.ts. */
export const AboutYou = z
  .object({
    display_name: z.string().nullable(),
    preferred_name: z.string().nullable(),
    pronouns: z.string().nullable(),
    about: z.string(),
    reply_style: z.string(),
    learn: z.boolean(),
    /** The one-time "What should bots call you?" card was answered or dismissed. */
    name_asked: z.boolean(),
    /** Profile photo (D-202): the current photo's id, served at /v1/photos/{id}. */
    photo_id: Uuid.nullable().optional(),
    /** The sign-in provider (Google) shared a photo that "Use my Google photo" can copy. */
    provider_photo: z.boolean().optional(),
    /** The sign-in photo was already copied once (or found missing); it isn't copied again by itself. */
    photo_import_tried: z.boolean().optional(),
  })
  .openapi("AboutYou");

/** A new profile photo: a JPEG, PNG or WebP of at most 1 MB, base64-encoded. */
export const SetProfilePhotoRequest = z
  .object({
    content_type: z.enum(["image/jpeg", "image/png", "image/webp"]),
    data: z.base64().max(1_400_000),
  })
  .openapi("SetProfilePhotoRequest");

export const ImportProfilePhotoRequest = z
  .object({
    /** Copy it even if there's a photo already or it was copied before ("Use my Google photo"). */
    replace: z.boolean().optional(),
  })
  .openapi("ImportProfilePhotoRequest");

export const UpdateAboutYouRequest = z
  .object({
    preferred_name: z.string().max(60).nullable().optional(),
    pronouns: z.string().max(40).nullable().optional(),
    about: z.string().max(1500).optional(),
    reply_style: z.string().max(600).optional(),
    learn: z.boolean().optional(),
    name_asked: z.literal(true).optional(),
  })
  .openapi("UpdateAboutYouRequest");

export const UserFact = z
  .object({
    id: Uuid,
    kind: z.enum(["fact", "preference"]),
    content: z.string(),
    pinned: z.boolean(),
    updated_at: z.iso.datetime({ offset: true }),
  })
  .openapi("UserFact");
