import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";

const ts = z.iso.datetime({ offset: true });
export const ChannelKind = z.enum(["telegram", "email", "sms", "slack", "whatsapp", "messenger", "feishu", "imessage"]).openapi("ChannelKind");

export const Channel = z
  .object({
    id: Uuid,
    bot_id: Uuid,
    kind: ChannelKind,
    name: z.string(),
    config: z.record(z.string(), z.unknown()),
    allowed_senders: z.array(z.string()),
    enabled: z.boolean(),
    /** Where the provider sends messages (none for iMessage). */
    webhook_url: z.string().nullable(),
    /** WhatsApp and Messenger: the verify token to paste into Meta's setup (shown once). */
    verify_token: z.string().nullable(),
    last_inbound_at: ts.nullable(),
    last_error: z.string().nullable(),
    created_at: ts,
  })
  .openapi("Channel");

export const CreateChannelRequest = z
  .object({
    bot_id: Uuid,
    kind: ChannelKind,
    name: z.string().min(1).max(100),
    config: z.record(z.string(), z.unknown()).optional(),
    secrets: z.record(z.string(), z.string().max(5000)).optional(),
    allowed_senders: z.array(z.string().min(1).max(300)).max(200),
  })
  .openapi("CreateChannelRequest");

export const UpdateChannelRequest = z
  .object({ name: z.string().min(1).max(100).optional(), allowed_senders: z.array(z.string().min(1).max(300)).max(200).optional(), enabled: z.boolean().optional() })
  .openapi("UpdateChannelRequest");

export const ChannelEvent = z
  .object({
    id: Uuid,
    direction: z.enum(["in", "out"]),
    status: z.enum(["accepted", "ignored", "routine", "sent", "failed"]),
    sender: z.string().nullable(),
    preview: z.string().nullable(),
    detail: z.string().nullable(),
    created_at: ts,
  })
  .openapi("ChannelEvent");
