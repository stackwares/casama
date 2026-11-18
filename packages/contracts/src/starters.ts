import { z } from "@hono/zod-openapi";

/** Starter requests for an empty chat (D-338). */
export const ChatStarter = z
  .object({
    emoji: z.string().openapi({ description: "Decoration only; tapping sends the text." }),
    text: z.string(),
  })
  .openapi("ChatStarter");

export const ChatStarters = z
  .object({
    items: z.array(ChatStarter),
    source: z.enum(["ai", "rules"]).openapi({
      description: "ai: a model wrote them for this person; rules: picked without a model.",
    }),
    refreshing: z.boolean().openapi({
      description: "A new list is being written; ask again in a few seconds to get it.",
    }),
  })
  .openapi("ChatStarters");
