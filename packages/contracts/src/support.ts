import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";

/** What a message to support is about; it leads the email subject so the inbox sorts itself. */
export const SupportTopic = z
  .enum(["billing", "broken", "account", "question", "other"])
  .openapi("SupportTopic");

/** What this server offers for help (D-298). */
export const SupportConfig = z
  .object({
    /** The support assistant answers here (Casama Cloud: it runs on the cloud's model key). */
    assistant: z.boolean(),
    /** Messages to people go through the server, which emails the support inbox. */
    tickets: z.boolean(),
    /** Where people can write directly when the app can't send for them. */
    email: z.string(),
    docs_url: z.string(),
  })
  .openapi("SupportConfig");

export const SupportMessage = z
  .object({ role: z.enum(["user", "assistant"]), content: z.string().min(1).max(4000) })
  .openapi("SupportMessage");

/** Which build the person is on, for the assistant and for the support email. */
const ClientInfo = {
  app_version: z.string().max(40).optional(),
  platform: z.string().max(40).optional(),
};

export const SupportChatRequest = z
  .object({
    /** The workspace open in the app; the assistant looks only at this one. */
    org_id: Uuid.optional(),
    messages: z.array(SupportMessage).min(1).max(40),
    ...ClientInfo,
  })
  .openapi("SupportChatRequest");

export const SupportSource = z
  .object({ title: z.string(), url: z.string() })
  .openapi("SupportSource");

export const SupportChatReply = z
  .object({
    reply: z.string(),
    /** Docs pages the answer drew on. */
    sources: z.array(SupportSource),
    /** Set when the assistant thinks a person should take over: a summary to send them. */
    handoff: z.object({ topic: SupportTopic, summary: z.string() }).nullable(),
  })
  .openapi("SupportChatReply");

export const SupportTicketRequest = z
  .object({
    org_id: Uuid.optional(),
    topic: SupportTopic,
    message: z.string().min(1).max(8000),
    /** The conversation with the assistant, when the person chose to include it. */
    transcript: z.array(SupportMessage).max(60).optional(),
    ...ClientInfo,
  })
  .openapi("SupportTicketRequest");

export const SupportTicket = z
  .object({
    /** A short reference for the person to quote, e.g. "C-7K2M9Q". */
    reference: z.string(),
    /** Where the reply will go. */
    reply_to: z.string(),
  })
  .openapi("SupportTicket");

/** A message to support in the instance owners' list (D-303). */
export const SupportTicketRow = z
  .object({
    reference: z.string(),
    topic: z.string(),
    subject: z.string(),
    status: z.enum(["open", "closed"]),
    user_email: z.string().nullable(),
    org_id: Uuid.nullable(),
    org_name: z.string().nullable(),
    created_at: z.iso.datetime({ offset: true }),
    closed_at: z.iso.datetime({ offset: true }).nullable(),
  })
  .openapi("SupportTicketRow");

/**
 * Casama Help on the websites (D-401): casama.ai and docs.casama.ai visitors, signed out. It knows
 * the same docs as the app's assistant but can't see any account, and is fenced by a Turnstile
 * check, short sessions and per-address limits.
 */
export const SupportWebConfig = z
  .object({
    /** The website assistant answers here; when false the widget shows the FAQ and the email. */
    assistant: z.boolean(),
    /** Cloudflare Turnstile site key for the check before a session; null when none is needed. */
    turnstile_site_key: z.string().nullable(),
    email: z.string(),
    docs_url: z.string(),
  })
  .openapi("SupportWebConfig");

export const SupportWebSessionRequest = z
  .object({ turnstile_token: z.string().max(4096) })
  .openapi("SupportWebSessionRequest");

export const SupportWebSession = z
  .object({
    /** Sent back with each message; tied to the visitor's address and short-lived. */
    session: z.string(),
    expires_at: z.iso.datetime({ offset: true }),
  })
  .openapi("SupportWebSession");

export const SupportWebChatRequest = z
  .object({
    session: z.string().max(400),
    messages: z
      .array(
        z.object({
          role: z.enum(["user", "assistant"]),
          content: z.string().min(1).max(4000),
        }),
      )
      .min(1)
      .max(20),
    /** The page the visitor is on, so answers can fit it. */
    page: z.string().max(200).optional(),
  })
  .openapi("SupportWebChatRequest");

export const SupportWebChatReply = z
  .object({ reply: z.string(), sources: z.array(SupportSource) })
  .openapi("SupportWebChatReply");

/** Today's use of the website assistant, for instance owners. */
export const SupportWebStats = z
  .object({
    on: z.boolean(),
    messages_today: z.number().int(),
    usd_today: z.number(),
    daily_budget_usd: z.number(),
    paused_addresses: z.number().int(),
    /** Questions it couldn't answer from the docs, newest first, with no identity attached. */
    gaps: z.array(
      z.object({
        question: z.string(),
        page: z.string().nullable(),
        created_at: z.iso.datetime({ offset: true }),
      }),
    ),
  })
  .openapi("SupportWebStats");
