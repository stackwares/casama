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
  })
  .openapi("AboutYou");

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
