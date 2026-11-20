import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";

const ts = z.iso.datetime({ offset: true });

/** A bot's hosted address (`name@<mail domain>`), or its tombstone after release. */
export const MailAddress = z
  .object({
    id: Uuid,
    bot_id: Uuid,
    channel_id: Uuid,
    local_part: z.string(),
    /** The full address, composed with the server's mail domain. */
    address: z.string(),
    status: z.enum(["active", "paused", "retired"]),
    /** Senders refused at the door. */
    blocked_senders: z.array(z.string()),
    /** Whether mail from a new sender notifies (at most once a day). */
    notify_new_senders: z.boolean(),
    /** Bytes the mailbox holds: kept originals plus separately stored files. */
    storage_used: z.number().int().optional(),
    /** The plan's mailbox size in bytes; null when unlimited (self-hosted). */
    storage_limit: z.number().int().nullable().optional(),
    created_at: ts,
  })
  .openapi("MailAddress");

export const ClaimMailAddressRequest = z
  .object({
    name: z.string().min(1).max(40),
    /** Where the claim started (the onboarding funnel counts it). */
    surface: z.enum(["profile", "tool", "suggestion"]).optional(),
  })
  .openapi("ClaimMailAddressRequest");

export const UpdateMailAddressRequest = z
  .object({
    status: z.enum(["active", "paused"]).optional(),
    notify_new_senders: z.boolean().optional(),
  })
  .openapi("UpdateMailAddressRequest");

export const MoveMailAddressRequest = z
  .object({
    to_bot_id: Uuid,
  })
  .openapi("MoveMailAddressRequest");

export const MailNameAvailability = z
  .object({
    name: z.string(),
    available: z.boolean(),
    /** Why not, in the app's words, when it isn't available. */
    issue: z.string().nullable(),
    /** Free alternatives, best first. */
    suggestions: z.array(z.string()),
  })
  .openapi("MailNameAvailability");

/** One kept mail in the inbox list. */
export const MailMessage = z
  .object({
    id: Uuid,
    direction: z.enum(["in", "out"]),
    from_addr: z.string(),
    from_name: z.string().nullable(),
    to_tag: z.string(),
    subject: z.string(),
    snippet: z.string(),
    verdict: z.enum(["allowed", "stranger", "automatic"]),
    sender_check: z.enum(["pass", "fail", "none"]),
    has_files: z.boolean(),
    file_count: z.number().int(),
    size: z.number().int(),
    conversation_id: Uuid.nullable(),
    created_at: ts,
  })
  .openapi("MailMessage");

export const MailFile = z
  .object({
    index: z.number().int(),
    name: z.string(),
    mime: z.string(),
    size: z.number().int(),
  })
  .openapi("MailFile");

/** One kept mail opened: the whole text and its files. */
export const MailMessageDetail = MailMessage.extend({
  text: z.string(),
  files: z.array(MailFile),
}).openapi("MailMessageDetail");

export const MailMessageList = z
  .object({
    items: z.array(MailMessage),
    next_cursor: z.string().nullable(),
  })
  .openapi("MailMessageList");

export const BlockMailSenderRequest = z
  .object({
    sender: z.string().min(1).max(300),
  })
  .openapi("BlockMailSenderRequest");

/** Delete several kept mails: by id, or everything older than a date. */
export const DeleteMailMessagesRequest = z
  .object({
    ids: z.array(Uuid).min(1).max(200).optional(),
    /** Delete every kept mail that arrived or went out before this moment. */
    before: ts.optional(),
  })
  .refine((b) => !!b.ids !== !!b.before, { message: "Give ids or before, not both" })
  .openapi("DeleteMailMessagesRequest");

export const DeleteMailMessagesResult = z
  .object({
    /** Mails deleted. */
    deleted: z.number().int(),
    /** Bytes freed. */
    freed: z.number().int(),
  })
  .openapi("DeleteMailMessagesResult");
