import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";

const ts = z.iso.datetime({ offset: true });

export const BotLink = z
  .object({
    id: Uuid,
    bot_id: Uuid,
    name: z.string(),
    status: z.enum(["pending", "active", "revoked"]),
    peer_bot_name: z.string().nullable(),
    remote_url: z.string().nullable().openapi({ description: "The other Kasama server, when the contact is on another one" }),
    exchanges: z.number().int(),
    created_at: ts,
    activated_at: ts.nullable(),
  })
  .openapi("BotLink");

export const CreatedBotLink = BotLink.extend({
  /** Send this to your contact; it works once, for 7 days. */
  invite: z.string(),
}).openapi("CreatedBotLink");

export const CreateBotLinkRequest = z.object({ name: z.string().min(1).max(100).openapi({ description: "What you call this contact" }) }).openapi("CreateBotLinkRequest");
export const AcceptBotLinkRequest = z
  .object({ invite: z.string().min(10).max(2000), bot_id: Uuid, name: z.string().min(1).max(100) })
  .openapi("AcceptBotLinkRequest");

export const LinkExchange = z
  .object({
    id: Uuid,
    direction: z.enum(["out", "in"]),
    request: z.string(),
    response: z.string().nullable(),
    status: z.enum(["working", "answered", "failed"]),
    created_at: ts,
  })
  .openapi("LinkExchange");
