/**
 * Hosted bot mail (BOT-EMAIL-PLAN §5, §6): what the mail Worker posts to /hooks/mail, whether
 * the sender is real, and sending through Cloudflare Email Sending with Resend behind the same
 * interface. No process env here: the server builds the sender from its settings and passes it in.
 */
import { createHmac, timingSafeEqual } from "node:crypto";
import {
  type AuthResults,
  apiAuthResults,
  cloudflareAuthResults,
  isAutomaticMail,
  type SenderCheck,
  senderCheckFrom,
  senderCheckFromResend,
} from "@casama/domain";
import PostalMime from "postal-mime";
import { htmlText, type InboundMessage } from "./adapters.ts";

export {
  type AuthResults,
  apiAuthResults,
  cloudflareAuthResults,
  isAutomaticMail,
  type SenderCheck,
  senderCheckFrom,
  senderCheckFromResend,
};

/** A channel row's hosted flag (config.hosted), the self-hosted email chat app's opposite. */
export function isHostedEmail(c: { kind: string; config: Record<string, unknown> }): boolean {
  return c.kind === "email" && c.config.hosted === true;
}

/** The address a hosted channel sends from (config.address, set when the name was claimed). */
export function hostedFromAddress(c: { config: Record<string, unknown> }): string {
  return typeof c.config.address === "string" ? c.config.address : "";
}

// ------------------------------------------------------------------ signing

/** How long a hook signature stays valid (the Worker and the API each allow this much skew). */
export const MAIL_HOOK_SKEW_MS = 300_000;

/** `v1=<hex HMAC-SHA256(secret, timestamp + "." + body)>`, like the other hooks. */
export function signMailHook(secret: string, timestamp: string, body: string | Uint8Array): string {
  return `v1=${createHmac("sha256", secret).update(`${timestamp}.`).update(body).digest("hex")}`;
}

export function verifyMailHook(
  secret: string,
  timestamp: string,
  signature: string,
  body: string | Uint8Array,
  nowMs = Date.now(),
): boolean {
  if (!secret || !timestamp || !signature) return false;
  const at = Number(timestamp);
  if (!Number.isFinite(at) || Math.abs(nowMs - at) > MAIL_HOOK_SKEW_MS) return false;
  const want = signMailHook(secret, timestamp, body);
  const a = Buffer.from(signature);
  const b = Buffer.from(want);
  return a.length === b.length && timingSafeEqual(a, b);
}

// --------------------------------------------------------------- MIME parse

export interface ParsedMailFile {
  name?: string;
  mime?: string;
  size: number;
  bytes: Uint8Array;
}

export interface ParsedMail {
  from: string;
  fromName?: string;
  /** True when the message had multiple From headers or multiple addresses in From. */
  multipleFrom?: boolean;
  subject: string;
  messageId?: string;
  inReplyTo?: string;
  references?: string;
  text: string;
  headers: Array<{ key: string; value: string }>;
  files: ParsedMailFile[];
}

const toBytes = (c: ArrayBuffer | Uint8Array | string): Uint8Array =>
  typeof c === "string"
    ? Uint8Array.from(Buffer.from(c, "base64"))
    : c instanceof Uint8Array
      ? new Uint8Array(c)
      : new Uint8Array(c);

/** True if a raw From header value appears to contain more than one address (outside quoted strings). */
function hasMultipleAddresses(value: string): boolean {
  let inQuotes = false;
  let escaped = false;
  let atCount = 0;
  let commaCount = 0;
  for (let i = 0; i < value.length; i++) {
    const ch = value[i];
    if (escaped) {
      escaped = false;
      continue;
    }
    if (ch === "\\" && inQuotes) {
      escaped = true;
      continue;
    }
    if (ch === '"') {
      inQuotes = !inQuotes;
      continue;
    }
    if (!inQuotes) {
      if (ch === "@") atCount++;
      if (ch === ",") commaCount++;
    }
  }
  return atCount > 1 || commaCount > 0;
}

/** The raw message the Worker posted, parsed: sender, thread, text and files. */
export async function parseMime(raw: Uint8Array): Promise<ParsedMail> {
  const email = await PostalMime.parse(raw);
  const from = email.from && "address" in email.from ? (email.from.address ?? "") : "";
  const fromName =
    email.from && "name" in email.from && email.from.name ? email.from.name : undefined;
  const headers = (email.headers ?? []).map((h) => ({ key: h.key, value: h.value }));
  const fromHeaders = headers.filter((h) => h.key.toLowerCase() === "from");
  const multipleFrom =
    fromHeaders.length > 1 ||
    fromHeaders.some((h) => hasMultipleAddresses(h.value)) ||
    (email.from &&
      "group" in email.from &&
      Array.isArray(email.from.group) &&
      email.from.group.length > 1);
  const files: ParsedMailFile[] = [];
  for (const a of email.attachments ?? []) {
    const bytes = toBytes(a.content);
    if (!bytes.length) continue;
    files.push({
      ...(a.filename ? { name: a.filename } : {}),
      ...(a.mimeType ? { mime: a.mimeType } : {}),
      size: bytes.length,
      bytes,
    });
  }
  return {
    from: from.trim().toLowerCase(),
    ...(fromName ? { fromName } : {}),
    ...(multipleFrom ? { multipleFrom: true } : {}),
    subject: (email.subject ?? "").trim(),
    ...(email.messageId ? { messageId: email.messageId } : {}),
    ...(email.inReplyTo ? { inReplyTo: email.inReplyTo } : {}),
    ...(email.references ? { references: email.references } : {}),
    text: (email.text ?? "").trim() || htmlText(email.html ?? ""),
    headers,
    files,
  };
}

/**
 * A parsed mail as a channel message. Files ride along as base64: the hook already holds their
 * bytes, so there is nothing to download later.
 */
export function parsedToInbound(
  parsed: ParsedMail,
  threadKey: string,
  replySubject: string,
): InboundMessage {
  return {
    ...(parsed.messageId ? { messageId: parsed.messageId } : {}),
    threadKey,
    sender: parsed.from,
    ...(parsed.fromName ? { senderName: parsed.fromName } : {}),
    subject: parsed.subject,
    text: parsed.text,
    reply: {
      to: parsed.from,
      subject: replySubject,
      ...(parsed.messageId ? { in_reply_to: parsed.messageId } : {}),
    },
    ...(parsed.files.length
      ? {
          files: parsed.files.map((f) => ({
            ...(f.name ? { name: f.name } : {}),
            ...(f.mime ? { mime: f.mime } : {}),
            size: f.size,
            fetch: {
              hostedBytes: Buffer.from(f.bytes).toString("base64"),
              ...(f.mime ? { mime: f.mime } : {}),
              ...(f.name ? { name: f.name } : {}),
            },
          })),
        }
      : {}),
  };
}

// ------------------------------------------------------------------- sending

export interface HostedMailAttachment {
  name: string;
  mime: string;
  bytes: Uint8Array;
}

export interface HostedMailMessage {
  /** `Ada <ada@domain>`: the bot's name, its own address. */
  from: string;
  to: string[];
  cc?: string[];
  subject: string;
  text: string;
  html?: string;
  headers?: Record<string, string>;
  attachments?: HostedMailAttachment[];
}

export interface HostedMailSender {
  readonly name: "cloudflare" | "resend";
  /**
   * Whether it takes Casama's own Message-ID header. Cloudflare refuses the send when one is set
   * (checked 2026-11-20) and gives the mail its own `<…@domain>` Message-ID, which its delivery
   * events also carry; that one is kept instead.
   */
  readonly customMessageId: boolean;
  send(msg: HostedMailMessage, f: typeof fetch): Promise<{ messageId: string | null }>;
}

/** Largest mail either sender takes (Cloudflare's whole-message limit). */
export const HOSTED_MAIL_MAX_BYTES = 25 * 1024 * 1024;

const asError = async (res: Response, who: string): Promise<Error> => {
  const body = await res.text().catch(() => "");
  return new Error(`${who} answered ${res.status}: ${body.slice(0, 300) || res.statusText}`);
};

/** Cloudflare Email Sending over its REST API (BOT-EMAIL-PLAN §6.4). */
export class CloudflareMailSender implements HostedMailSender {
  readonly name = "cloudflare" as const;
  readonly customMessageId = false;
  private base: string;
  private accountId: string;
  private apiToken: string;
  constructor(o: { accountId: string; apiToken: string; apiBase?: string }) {
    this.accountId = o.accountId;
    this.apiToken = o.apiToken;
    this.base = (o.apiBase ?? "https://api.cloudflare.com/client/v4").replace(/\/$/, "");
  }
  async send(msg: HostedMailMessage, f: typeof fetch): Promise<{ messageId: string | null }> {
    // Bytes, not characters; attachments grow by a third as base64 in the message.
    const size =
      Buffer.byteLength(msg.text) +
      Buffer.byteLength(msg.html ?? "") +
      (msg.attachments ?? []).reduce((n, a) => n + Math.ceil(a.bytes.length / 3) * 4, 0);
    if (size > HOSTED_MAIL_MAX_BYTES)
      throw new Error(`Mail is too large (${(size / 1048576).toFixed(1)} MiB; at most 25 MiB)`);
    // Cloudflare sets the Message-ID itself and refuses a send that sets one.
    const kept = Object.entries(msg.headers ?? {}).filter(([k]) => k.toLowerCase() !== "message-id");
    const cfHeaders = kept.length ? Object.fromEntries(kept) : undefined;
    // Named senders go as an object (the REST API's field is `address`, not `email`).
    const named = msg.from.match(/^\s*(.*?)\s*<([^<>@\s]+@[^<>@\s]+)>\s*$/);
    const from =
      named?.[1]?.trim() && named[2] ? { name: named[1].trim(), address: named[2] } : msg.from;
    const res = await f(`${this.base}/accounts/${this.accountId}/email/sending/send`, {
      method: "POST",
      headers: { "content-type": "application/json", authorization: `Bearer ${this.apiToken}` },
      body: JSON.stringify({
        from,
        to: msg.to.length === 1 ? msg.to[0] : msg.to,
        ...(msg.cc?.length ? { cc: msg.cc } : {}),
        subject: msg.subject,
        text: msg.text,
        ...(msg.html ? { html: msg.html } : {}),
        ...(cfHeaders ? { headers: cfHeaders } : {}),
        ...(msg.attachments?.length
          ? {
              attachments: msg.attachments.map((a) => ({
                content: Buffer.from(a.bytes).toString("base64"),
                filename: a.name,
                type: a.mime,
                disposition: "attachment",
              })),
            }
          : {}),
      }),
    });
    if (!res.ok) throw await asError(res, "Cloudflare");
    const body = (await res.json().catch(() => ({}))) as {
      success?: boolean;
      result?: { message_id?: string; suppressed_recipients?: string[] };
      errors?: Array<{ message?: string }>;
    };
    if (body.success === false)
      throw new Error(
        `Cloudflare refused the mail: ${
          (body.errors ?? [])
            .map((e) => e.message)
            .filter(Boolean)
            .join("; ")
            .slice(0, 300) || "unknown reason"
        }`,
      );
    return { messageId: body.result?.message_id ?? null };
  }
}

/** The fallback sender (BOT-EMAIL-PLAN §6.4): the same Resend call the email chat app makes. */
export class ResendMailSender implements HostedMailSender {
  readonly name = "resend" as const;
  readonly customMessageId = true;
  private base: string;
  private apiKey: string;
  constructor(o: { apiKey: string; apiBase?: string }) {
    this.apiKey = o.apiKey;
    this.base = (o.apiBase ?? "https://api.resend.com").replace(/\/$/, "");
  }
  async send(msg: HostedMailMessage, f: typeof fetch): Promise<{ messageId: string | null }> {
    const res = await f(`${this.base}/emails`, {
      method: "POST",
      headers: { "content-type": "application/json", authorization: `Bearer ${this.apiKey}` },
      body: JSON.stringify({
        from: msg.from,
        to: msg.to,
        ...(msg.cc?.length ? { cc: msg.cc } : {}),
        subject: msg.subject,
        text: msg.text,
        ...(msg.html ? { html: msg.html } : {}),
        ...(msg.headers ? { headers: msg.headers } : {}),
        ...(msg.attachments?.length
          ? {
              attachments: msg.attachments.map((a) => ({
                filename: a.name,
                content: Buffer.from(a.bytes).toString("base64"),
                content_type: a.mime,
              })),
            }
          : {}),
      }),
    });
    if (!res.ok) throw await asError(res, "Resend");
    const body = (await res.json().catch(() => ({}))) as { id?: string };
    return { messageId: body.id ?? null };
  }
}
