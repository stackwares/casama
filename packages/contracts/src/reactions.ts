import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";

/** Message reactions (D-331): one emoji per person (or bot) per message. */

export const ReactionEmoji = z.string().trim().min(1).max(64).openapi({
  description:
    "Exactly one emoji (skin tones, flags, keycaps and ZWJ sequences count as one). A text-style pictograph such as ❤ is stored in its emoji form ❤️",
  example: "👍",
});

export const ReactionSummary = z
  .object({
    emoji: z.string(),
    count: z.number().int(),
    mine: z.boolean().openapi({ description: "You reacted with this emoji" }),
    users: z.array(Uuid).openapi({ description: "People who reacted with it (the first 20)" }),
    bots: z.array(Uuid).openapi({ description: "Bots that reacted with it" }),
  })
  .openapi("ReactionSummary");

export const MessageReactions = z
  .object({
    message_id: Uuid,
    reactions: z.array(ReactionSummary).openapi({ description: "Grouped by emoji, most first" }),
  })
  .openapi("MessageReactions");

export const SetReactionRequest = z.object({ emoji: ReactionEmoji }).openapi("SetReactionRequest");

export const MessageReaction = z
  .object({
    emoji: z.string(),
    user_id: Uuid.nullable(),
    bot_id: Uuid.nullable(),
    name: z.string().openapi({ description: "The person's or bot's name" }),
    avatar_url: z.string().nullable(),
    source: z.enum(["app", "api", "channel", "bot"]),
    created_at: z.string(),
  })
  .openapi("MessageReaction");

export const MessageReactionList = z
  .object({ message_id: Uuid, items: z.array(MessageReaction) })
  .openapi("MessageReactionList");
