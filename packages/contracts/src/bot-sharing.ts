import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";

export const BotAccessEntry = z
  .object({
    user_id: Uuid.nullable(),
    email: z.string().nullable(),
    role: z.enum(["owner", "admin", "member"]).nullable(),
    access: z.enum(["chat", "edit", "admin"]),
  })
  .openapi("BotAccessEntry");

export const BotAccess = z
  .object({
    visibility: z.enum(["private", "team"]),
    created_by: Uuid.nullable(),
    entries: z.array(BotAccessEntry),
    can_admin: z.boolean(),
    /** What the caller can do with this bot. */
    your_access: z.enum(["chat", "edit", "admin"]),
  })
  .openapi("BotAccess");

export const SetBotAccessRequest = z
  .object({
    visibility: z.enum(["private", "team"]),
    entries: z
      .array(
        z.object({
          user_id: Uuid.optional(),
          role: z.enum(["owner", "admin", "member"]).optional(),
          access: z.enum(["chat", "edit", "admin"]),
        }),
      )
      .max(200),
  })
  .openapi("SetBotAccessRequest");

export const WorkspaceMember = z
  .object({
    user_id: Uuid,
    email: z.string().nullable(),
    role: z.enum(["owner", "admin", "member"]),
  })
  .openapi("WorkspaceMember");
