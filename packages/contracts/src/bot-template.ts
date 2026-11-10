import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";

/**
 * A shareable bot (D-110): instructions, skills, routines and suggested connections. Never
 * secrets or keys; memories only when the person chose to include them. The same file is what
 * the community template repository accepts.
 */
export const BotTemplateFile = z
  .object({
    format: z.literal("kasama.bot"),
    version: z.number().int().min(1).max(1).openapi({ description: "Format version (1)" }),
    name: z.string().min(1).max(80),
    description: z.string().max(300).optional(),
    persona_md: z.string().max(20_000),
    autonomy: z.enum(["ask_always", "ask_risky", "autonomous"]),
    avatar: z.string().max(200).nullable().optional(),
    skills: z
      .array(
        z.object({
          name: z.string().regex(/^[a-z0-9][a-z0-9_-]{0,62}$/),
          description: z.string().min(1).max(300),
          body_md: z.string().max(50_000),
          files: z
            .array(
              z.object({
                path: z.string().max(300),
                content_base64: z.string().max(1_500_000),
                executable: z.boolean().optional(),
              }),
            )
            .max(60)
            .optional(),
        }),
      )
      .max(30)
      .optional(),
    routines: z
      .array(
        z.object({
          name: z.string().min(1).max(120),
          instructions_md: z.string().min(1).max(20_000),
          schedule_cron: z.string().max(100),
        }),
      )
      .max(20)
      .optional(),
    connections: z
      .array(z.object({ kind: z.string().max(40), name: z.string().max(120) }))
      .max(30)
      .optional()
      .openapi({ description: "Services to connect after importing (names only, no credentials)" }),
    memories: z
      .array(
        z.object({
          kind: z.enum(["fact", "episode", "summary", "preference"]),
          content: z.string().min(1).max(8000),
        }),
      )
      .max(200)
      .optional(),
  })
  .openapi("BotTemplateFile");

export const BotShareLink = z
  .object({
    token: z.string(),
    url: z.string(),
    expires_at: z.iso.datetime({ offset: true }).nullable(),
  })
  .openapi("BotShareLink");

export const CreateBotShareRequest = z
  .object({
    include_memories: z.boolean().default(false),
    expires_in_days: z.number().int().min(1).max(365).nullable().default(30),
  })
  .openapi("CreateBotShareRequest");

export const ImportBotRequest = z
  .object({
    org_id: Uuid,
    template: BotTemplateFile,
    credential_id: Uuid.openapi({ description: "The model key the new bot uses" }),
    model: z.string().min(1).max(200),
    include_memories: z.boolean().default(true),
    include_routines: z.boolean().default(true),
  })
  .openapi("ImportBotRequest");

export const ImportBotResponse = z
  .object({
    bot_id: Uuid,
    skills: z.number().int(),
    routines: z.number().int(),
    memories: z.number().int(),
    connections_to_add: z.array(z.object({ kind: z.string(), name: z.string() })),
  })
  .openapi("ImportBotResponse");
