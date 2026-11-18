/**
 * Chat apps (SPEC: Channels; D-134). Every adapter checks the provider's webhook signature,
 * turns its payload into standard messages, and sends replies. Provider addresses can be pointed
 * elsewhere with `config.api_base` (tests, proxies, regional endpoints).
 */
import {
  createDecipheriv,
  createHash,
  createHmac,
  createPublicKey,
  timingSafeEqual,
  verify as verifySignature,
} from "node:crypto";
import { fileLinkLine, type InFile, MAX_FILE_IN, type OutFile, sizeText } from "./files.ts";
import {
  escapeHtml,
  toAdf,
  toEmailHtml,
  toPlain,
  toSlack,
  toTelegramHtml,
  toWhatsApp,
} from "./format.ts";
import { emojiFromSlack, slackNameOf, telegramReactionOf } from "./reaction-maps.ts";

export type ChannelKind =
  | "telegram"
  | "email"
  | "sms"
  | "slack"
  | "whatsapp"
  | "messenger"
  | "feishu"
  | "imessage"
  | "teams"
  | "discord"
  | "linear"
  | "jira";

export interface WebhookRequest {
  method: string;
  url: string;
  headers: Record<string, string>;
  body: string;
}

export interface InboundMessage {
  threadKey: string;
  sender: string;
  senderName?: string;
  text: string;
  subject?: string;
  /** How to reply in this thread. */
  reply: Record<string, unknown>;
  /**
   * The provider's id for this message, so a webhook delivered twice starts one run (D-270).
   * Messages without one are never deduplicated.
   */
  messageId?: string;
  /** The provider's id for fetching a body the webhook left out (Resend inbound email). */
  fetchId?: string;
  /**
   * The app's own id for this message, as reactions name it (D-331): "<chat>:<message id>" in
   * Telegram, "<channel>:<ts>" in Slack, the wamid in WhatsApp.
   */
  ref?: string;
  /** Photos, files and voice notes that came with it, downloaded after the sender check (D-342). */
  files?: InFile[];
}

/** Someone reacting to a message in a chat app (D-331 Phase 3). */
export interface InboundReaction {
  /** The message reacted to, as InboundMessage.ref names it. */
  ref: string;
  sender: string;
  senderName?: string;
  /** The emoji they reacted with; null when they took a reaction back. */
  emoji: string | null;
  /** The emoji they took back, when the app says which (Slack). */
  removed?: string | null;
}

/** A person pressing Approve or Deny on an approval posted into a chat app (D-277). */
export interface ChannelAction {
  approvalId: string;
  decision: "approved" | "denied";
  sender: string;
  senderName?: string;
  /** Where to replace the buttons with the outcome (Slack's response_url). */
  responseUrl?: string;
  /** The press itself and the message with the buttons, for apps that answer both (Telegram). */
  callbackId?: string;
  messageRef?: { chat_id: unknown; message_id: unknown };
}

export type Config = Record<string, unknown>;
export type Secrets = Record<string, string>;

export interface ChannelAdapter {
  kind: ChannelKind;
  /** The longest message the provider takes; longer replies go out in parts (D-270). */
  maxText?: number;
  /** Turns an encrypted webhook body into the plain one, before handshakes and parsing (Feishu). */
  decode?(req: WebhookRequest, cfg: Config, secrets: Secrets): WebhookRequest;
  /** Shows the sender the message arrived (a reaction), where the app has a way (D-277). */
  acknowledge?(
    cfg: Config,
    secrets: Secrets,
    message: InboundMessage,
    f: typeof fetch,
  ): Promise<void>;
  /** Posts an approval request with Approve and Deny buttons into the thread (D-277). */
  sendApproval?(
    cfg: Config,
    secrets: Secrets,
    reply: Record<string, unknown>,
    approval: { id: string; summary: string },
    f: typeof fetch,
  ): Promise<void>;
  /** For apps whose signature check needs the network (Teams' signed tokens, D-278). */
  verifyAsync?(
    req: WebhookRequest,
    cfg: Config,
    secrets: Secrets,
    f: typeof fetch,
  ): Promise<boolean>;
  /** The HTTP answer the app expects after a verified webhook, when it isn't a plain 200 (Discord). */
  respond?(req: WebhookRequest): { status: number; body: string; type: string } | null;
  /** Reads a button press from the app's interactivity webhook (D-277). */
  parseAction?(req: WebhookRequest): ChannelAction | null;
  /** Answers a button press and swaps the buttons for the outcome, where the app needs it (D-341). */
  settleAction?(
    cfg: Config,
    secrets: Secrets,
    action: ChannelAction,
    outcome: string,
    f: typeof fetch,
  ): Promise<void>;
  /**
   * Whether a file of this type and size can go as an attachment (D-342); one that can't goes as a
   * signed link. Checked before the bytes are read. Without it, every file goes as a link.
   */
  fileFits?(mime: string, size: number): boolean;
  /**
   * Sends one file. With a caption, the file and the reply's text go as one message; an app that
   * can't caption this file sends the text first itself. Returns the message's ref, like send.
   */
  sendFile?(
    cfg: Config,
    secrets: Secrets,
    reply: Record<string, unknown>,
    file: OutFile & { caption?: string },
    f: typeof fetch,
  ): Promise<string | null | undefined>;
  /** How long a caption may be, for apps where a short reply and its one file go as one message. */
  captionMax?: number;
  /** Sends the reply and all its files as one message (email). */
  sendBundle?(
    cfg: Config,
    secrets: Secrets,
    reply: Record<string, unknown>,
    text: string,
    files: OutFile[],
    f: typeof fetch,
  ): Promise<void>;
  /** Downloads a file someone sent, from what normalize put in InFile.fetch (D-342). */
  downloadFile?(
    cfg: Config,
    secrets: Secrets,
    where: Record<string, unknown>,
    f: typeof fetch,
  ): Promise<{ bytes: Uint8Array; mime?: string; name?: string }>;
  /** Shows "typing…" in the thread for a few seconds; repeated while a run works (D-341). */
  typing?(
    cfg: Config,
    secrets: Secrets,
    reply: Record<string, unknown>,
    f: typeof fetch,
  ): Promise<void>;
  /** Fills in what the webhook left out (an email's body), after the signature is checked. */
  enrich?(
    messages: InboundMessage[],
    cfg: Config,
    secrets: Secrets,
    f: typeof fetch,
  ): Promise<InboundMessage[]>;
  /** Answers the provider's setup handshake (URL verification), when this request is one. */
  handshake?(
    req: WebhookRequest,
    cfg: Config,
    secrets: Secrets,
  ): { status: number; body: string; type: string } | null;
  verify(req: WebhookRequest, cfg: Config, secrets: Secrets): boolean;
  normalize(req: WebhookRequest, cfg: Config): InboundMessage[];
  /** Reactions in a verified webhook (D-331 Phase 3), for apps that report them. */
  reactions?(req: WebhookRequest): InboundReaction[];
  /**
   * The bot reacting to a message in the app (null takes its reaction back). `previous` is the
   * bot's earlier reaction there, for apps that keep several per person (Slack).
   */
  react?(
    cfg: Config,
    secrets: Secrets,
    reply: Record<string, unknown>,
    ref: string,
    emoji: string | null,
    previous: string | null,
    f: typeof fetch,
  ): Promise<void>;
  /** Sends one message; returns the app's id for it (InboundMessage.ref's form) when it gives one. */
  send(
    cfg: Config,
    secrets: Secrets,
    reply: Record<string, unknown>,
    text: string,
    f: typeof fetch,
  ): Promise<string | null | undefined>;
}

const same = (a: string, b: string) => {
  const x = Buffer.from(a);
  const y = Buffer.from(b);
  return x.length === y.length && timingSafeEqual(x, y);
};
const h = (req: WebhookRequest, name: string) => req.headers[name.toLowerCase()] ?? "";
const json = (s: string) => {
  try {
    return JSON.parse(s) as Record<string, unknown>;
  } catch {
    return {};
  }
};
const base = (cfg: Config, dflt: string) => String(cfg.api_base ?? dflt).replace(/\/$/, "");
async function ok(res: Response, what: string) {
  if (!res.ok)
    throw new Error(`${what} answered ${res.status}: ${(await res.text()).slice(0, 200)}`);
  return res;
}
const plain = (s: string) => s.replace(/\s+/g, " ").trim();
/** A response's JSON, or {} when it has none (a reply's id is a bonus, never a failure). */
async function bodyJson(res: Response): Promise<Record<string, unknown>> {
  try {
    const v = (await res.json()) as unknown;
    return v && typeof v === "object" ? (v as Record<string, unknown>) : {};
  } catch {
    return {};
  }
}

const MB = 1024 * 1024;
const blobOf = (file: OutFile) => new Blob([new Uint8Array(file.bytes)], { type: file.mime });
/** A response's bytes, refusing a file over [max] (D-342). */
async function bytesOf(res: Response, what: string, max = MAX_FILE_IN) {
  await ok(res, what);
  const tooBig = (n: number) =>
    new Error(`too large (${sizeText(n)}; files up to ${sizeText(max)} come through)`);
  const len = Number(res.headers.get("content-length") ?? 0);
  if (len > max) throw tooBig(len);
  const bytes = new Uint8Array(await res.arrayBuffer());
  if (bytes.length > max) throw tooBig(bytes.length);
  return { bytes, mime: res.headers.get("content-type") ?? undefined };
}
const kindOf = (mime: string) =>
  mime.startsWith("image/")
    ? "image"
    : mime.startsWith("video/")
      ? "video"
      : mime.startsWith("audio/")
        ? "audio"
        : "file";

/** Said in place of a sticker or anything else the bot can't receive from this app. */
export const ATTACHMENT_NOTE =
  "[They sent something that doesn't come through from this app (a sticker, a location or a contact card): ask them to describe it, or to send it in the Casama app.]";

/**
 * Splits a reply into parts the provider accepts, at a paragraph, line, sentence or word break
 * where it can (D-270). Before, long replies were cut off at the limit.
 */
export function splitText(text: string, max: number): string[] {
  if (text.length <= max) return [text];
  const parts: string[] = [];
  let rest = text;
  while (rest.length > max) {
    const window = rest.slice(0, max);
    let cut = -1;
    for (const sep of ["\n\n", "\n", ". ", " "]) {
      const at = window.lastIndexOf(sep);
      if (at > max * 0.5) {
        cut = at + sep.length;
        break;
      }
    }
    if (cut <= 0) cut = max;
    parts.push(rest.slice(0, cut).trimEnd());
    rest = rest.slice(cut).trimStart();
  }
  if (rest) parts.push(rest);
  return parts;
}

// ------------------------------------------------------------------ Telegram (Bot API)
const hasAny = (o: Record<string, unknown>, keys: string[]) => keys.some((k) => o[k] != null);

const telegram: ChannelAdapter = {
  kind: "telegram",
  maxText: 4096,
  verify: (req, _c, s) =>
    !!s.webhook_secret && same(h(req, "x-telegram-bot-api-secret-token"), s.webhook_secret),
  normalize(req) {
    const u = json(req.body);
    const m = (u.message ?? u.edited_message) as Record<string, unknown> | undefined;
    const chat = m?.chat as Record<string, unknown> | undefined;
    const from = m?.from as Record<string, unknown> | undefined;
    if (!m || !chat || from?.is_bot) return [];
    // Photos come in several sizes, smallest first: the largest is the one to keep (D-342).
    const files: InFile[] = [];
    const photo = Array.isArray(m.photo)
      ? (m.photo as Array<Record<string, unknown>>).at(-1)
      : undefined;
    if (photo?.file_id)
      files.push({
        name: "photo.jpg",
        mime: "image/jpeg",
        size: Number(photo.file_size ?? 0) || undefined,
        fetch: { file_id: photo.file_id },
      });
    for (const key of ["document", "video", "voice", "audio", "video_note", "animation"]) {
      const d = m[key] as Record<string, unknown> | undefined;
      if (!d?.file_id || (key === "document" && m.animation)) continue;
      files.push({
        name:
          (d.file_name as string | undefined) ??
          (key === "voice" ? "voice.ogg" : key === "video_note" ? "video.mp4" : undefined),
        mime:
          (d.mime_type as string | undefined) ??
          (key === "voice" ? "audio/ogg" : key === "video_note" ? "video/mp4" : undefined),
        size: Number(d.file_size ?? 0) || undefined,
        fetch: { file_id: d.file_id },
      });
    }
    const text =
      typeof m.text === "string"
        ? m.text
        : [
            m.caption,
            !files.length && hasAny(m, ["sticker", "location", "contact", "poll"])
              ? ATTACHMENT_NOTE
              : "",
          ]
            .filter((x) => typeof x === "string" && x)
            .join("\n");
    if (!text && !files.length) return [];
    return [
      {
        messageId: u.update_id !== undefined ? `u${u.update_id}` : undefined,
        threadKey: `chat:${chat.id}`,
        sender: String(from?.id ?? chat.id),
        senderName:
          [from?.first_name, from?.last_name].filter(Boolean).join(" ") ||
          (from?.username as string | undefined),
        text,
        reply: { chat_id: chat.id },
        ref: m.message_id !== undefined ? `${chat.id}:${m.message_id}` : undefined,
        ...(files.length ? { files } : {}),
      },
    ];
  },
  // Bots download up to 20 MB (getFile), and send photos up to 10 MB and other files up to 50 MB.
  async downloadFile(cfg, s, where, f) {
    const api = base(cfg, "https://api.telegram.org");
    const r = (await (
      await ok(
        await f(
          `${api}/bot${s.bot_token}/getFile?file_id=${encodeURIComponent(String(where.file_id))}`,
        ),
        "Telegram",
      )
    ).json()) as { result?: { file_path?: string; file_size?: number } };
    if (!r.result?.file_path)
      throw new Error(
        (r.result?.file_size ?? 0) > 20 * MB
          ? "too large: Telegram lets bots download files up to 20 MB"
          : "Telegram didn't give the file",
      );
    return bytesOf(
      await f(`${api}/file/bot${s.bot_token}/${r.result.file_path}`),
      "Telegram",
      20 * MB,
    );
  },
  captionMax: 1024,
  fileFits: (_mime, size) => size <= 50 * MB,
  async sendFile(cfg, s, reply, file, f) {
    const photo = /^image\/(jpeg|png|webp)$/.test(file.mime) && file.size <= 10 * MB;
    const [method, field] = photo
      ? ["sendPhoto", "photo"]
      : file.mime === "image/gif"
        ? ["sendAnimation", "animation"]
        : file.mime === "video/mp4"
          ? ["sendVideo", "video"]
          : file.mime === "audio/ogg"
            ? ["sendVoice", "voice"]
            : /^audio\/(mpeg|mp4|m4a|x-m4a)$/.test(file.mime)
              ? ["sendAudio", "audio"]
              : ["sendDocument", "document"];
    const post = (html: boolean) => {
      const form = new FormData();
      form.set("chat_id", String(reply.chat_id));
      form.set(field as string, blobOf(file), file.name);
      if (file.caption) {
        form.set("caption", html ? toTelegramHtml(file.caption) : toPlain(file.caption));
        if (html) form.set("parse_mode", "HTML");
      }
      return f(`${base(cfg, "https://api.telegram.org")}/bot${s.bot_token}/${method}`, {
        method: "POST",
        body: form,
      });
    };
    let res = await post(true);
    if (res.status === 400 && file.caption) res = await post(false);
    const r = (await bodyJson(await ok(res, "Telegram"))) as { result?: { message_id?: number } };
    return r.result?.message_id !== undefined ? `${reply.chat_id}:${r.result.message_id}` : null;
  },
  // A reaction arrives as its own update (allowed_updates must name message_reaction; in groups
  // the bot must be an admin). Telegram sends the whole new set: the last emoji in it is theirs.
  reactions(req) {
    const r = json(req.body).message_reaction as Record<string, unknown> | undefined;
    const chat = r?.chat as Record<string, unknown> | undefined;
    const user = r?.user as Record<string, unknown> | undefined;
    if (!r || !chat || r.message_id === undefined || !user || user.is_bot) return [];
    const emojis = ((r.new_reaction ?? []) as Array<Record<string, unknown>>)
      .filter((x) => x.type === "emoji" && typeof x.emoji === "string")
      .map((x) => x.emoji as string);
    return [
      {
        ref: `${chat.id}:${r.message_id}`,
        sender: String(user.id),
        senderName:
          [user.first_name, user.last_name].filter(Boolean).join(" ") ||
          (user.username as string | undefined),
        emoji: emojis[emojis.length - 1] ?? null,
      },
    ];
  },
  async react(cfg, s, _reply, ref, emoji, _previous, f) {
    const at = ref.lastIndexOf(":");
    const shown = emoji === null ? null : telegramReactionOf(emoji);
    // Telegram lets bots use only some emoji; one it has nothing close to stays in Casama.
    if (at <= 0 || (emoji !== null && !shown)) return;
    await ok(
      await f(`${base(cfg, "https://api.telegram.org")}/bot${s.bot_token}/setMessageReaction`, {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({
          chat_id: ref.slice(0, at),
          message_id: Number(ref.slice(at + 1)),
          reaction: shown ? [{ type: "emoji", emoji: shown }] : [],
        }),
      }),
      "Telegram",
    );
  },
  // Seen: 👀 on the message as soon as it arrives (D-341), as Slack's adapter does.
  async acknowledge(cfg, s, m, f) {
    if (m.ref) await this.react?.(cfg, s, m.reply, m.ref, "👀", null, f);
  },
  async typing(cfg, s, reply, f) {
    await f(`${base(cfg, "https://api.telegram.org")}/bot${s.bot_token}/sendChatAction`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ chat_id: reply.chat_id, action: "typing" }),
    });
  },
  async sendApproval(cfg, s, reply, approval, f) {
    await ok(
      await f(`${base(cfg, "https://api.telegram.org")}/bot${s.bot_token}/sendMessage`, {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({
          chat_id: reply.chat_id,
          text: `<b>Approval needed</b>\n${escapeHtml(approval.summary)}`,
          parse_mode: "HTML",
          reply_markup: {
            inline_keyboard: [
              [
                { text: "Approve", callback_data: `approve:${approval.id}` },
                { text: "Deny", callback_data: `deny:${approval.id}` },
              ],
            ],
          },
        }),
      }),
      "Telegram",
    );
  },
  // A button press arrives as a callback_query update at the same webhook.
  parseAction(req) {
    const q = json(req.body).callback_query as Record<string, unknown> | undefined;
    const m = /^(approve|deny):([0-9a-f-]{36})$/.exec(String(q?.data ?? ""));
    const from = q?.from as Record<string, unknown> | undefined;
    if (!q || !m || !from?.id) return null;
    const msg = q.message as Record<string, unknown> | undefined;
    const chat = msg?.chat as Record<string, unknown> | undefined;
    return {
      approvalId: m[2] as string,
      decision: m[1] === "approve" ? "approved" : "denied",
      sender: String(from.id),
      senderName:
        [from.first_name, from.last_name].filter(Boolean).join(" ") ||
        (from.username as string | undefined),
      callbackId: String(q.id ?? ""),
      messageRef:
        chat && msg?.message_id !== undefined
          ? { chat_id: chat.id, message_id: msg.message_id }
          : undefined,
    };
  },
  async settleAction(cfg, s, action, outcome, f) {
    const api = `${base(cfg, "https://api.telegram.org")}/bot${s.bot_token}`;
    const post = (method: string, body: Record<string, unknown>) =>
      f(`${api}/${method}`, {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify(body),
      }).catch(() => {});
    await post("answerCallbackQuery", { callback_query_id: action.callbackId, text: outcome });
    // Decided: the buttons give way to who decided. Refused: the buttons stay for someone else.
    if (action.messageRef && /^(Approved|Denied) by /.test(outcome))
      await post("editMessageReplyMarkup", {
        ...action.messageRef,
        reply_markup: { inline_keyboard: [[{ text: outcome, callback_data: "noop" }]] },
      });
  },
  async send(cfg, s, reply, text, f) {
    // Markdown as Telegram's HTML (D-340); if Telegram can't read it, the same reply as plain text.
    const post = (body: Record<string, unknown>) =>
      f(`${base(cfg, "https://api.telegram.org")}/bot${s.bot_token}/sendMessage`, {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ chat_id: reply.chat_id, ...body }),
      });
    let first = await post({ text: toTelegramHtml(text), parse_mode: "HTML" });
    if (first.status === 400) first = await post({ text: toPlain(text) });
    const res = await ok(first, "Telegram");
    const r = (await bodyJson(res)) as { result?: { message_id?: number } };
    return r.result?.message_id !== undefined ? `${reply.chat_id}:${r.result.message_id}` : null;
  },
};

// ------------------------------------------------------------------ Email (Resend inbound, signed like Svix)
function svixValid(req: WebhookRequest, secret: string) {
  const id = h(req, "svix-id");
  const ts = h(req, "svix-timestamp");
  const sigs = h(req, "svix-signature");
  if (!id || !ts || !sigs || Math.abs(Date.now() / 1000 - Number(ts)) > 300) return false;
  const key = Buffer.from(secret.replace(/^whsec_/, ""), "base64");
  const want = createHmac("sha256", key).update(`${id}.${ts}.${req.body}`).digest("base64");
  return sigs.split(" ").some((s) => same(s.replace(/^v1,/, ""), want));
}
const addr = (v: unknown) => {
  const s = Array.isArray(v) ? String(v[0] ?? "") : String(v ?? "");
  return (/<([^>]+)>/.exec(s)?.[1] ?? s).trim().toLowerCase();
};
const baseSubject = (s: string) => s.replace(/^\s*((re|fwd?|aw|sv)\s*:\s*)+/i, "").trim();
const htmlText = (html: string) =>
  html
    .replace(/<(script|style)[\s\S]*?<\/\1>/gi, " ")
    .replace(/<br\s*\/?>|<\/p>|<\/div>/gi, "\n")
    .replace(/<[^>]+>/g, " ")
    .replace(/&nbsp;/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/[ \t]+/g, " ")
    .trim();
const email: ChannelAdapter = {
  kind: "email",
  fileFits: (_mime, size) => size <= 25 * MB,
  async downloadFile(_cfg, _s, where, f) {
    return bytesOf(await f(String(where.url)), "Resend");
  },
  // One email: the reply, with its files attached (Resend takes 40 MB after base64).
  async sendBundle(cfg, s, reply, text, files, f) {
    let used = 0;
    const attached = files.filter((x) => {
      used += x.size;
      return used <= 28 * MB;
    });
    await ok(
      await f(`${base(cfg, "https://api.resend.com")}/emails`, {
        method: "POST",
        headers: { "content-type": "application/json", authorization: `Bearer ${s.api_key}` },
        body: JSON.stringify({
          from: cfg.address,
          to: [reply.to],
          subject: reply.subject,
          text: toPlain(text),
          html: toEmailHtml(text),
          attachments: attached.map((x) => ({
            filename: x.name,
            content: Buffer.from(x.bytes).toString("base64"),
            content_type: x.mime,
          })),
          ...(reply.in_reply_to
            ? { headers: { "In-Reply-To": reply.in_reply_to, References: reply.in_reply_to } }
            : {}),
        }),
      }),
      "Resend",
    );
  },
  verify: (req, _c, s) => !!s.signing_secret && svixValid(req, s.signing_secret),
  async enrich(messages, cfg, s, f) {
    const out: InboundMessage[] = [];
    for (const m of messages) {
      if (!m.fetchId) {
        out.push(m);
        continue;
      }
      // Resend's received-email API (written from its docs; checked only against a mock).
      const api = `${base(cfg, "https://api.resend.com")}/emails/receiving/${encodeURIComponent(m.fetchId)}`;
      const auth = { headers: { authorization: `Bearer ${s.api_key}` } };
      let text = m.text;
      if (!text) {
        const res = await f(api, auth).catch(() => null);
        const body = res?.ok
          ? ((await res.json().catch(() => ({}))) as Record<string, unknown>)
          : {};
        text = String(body.text ?? "").trim() || htmlText(String(body.html ?? ""));
      }
      // Attachments come from their own list, each with a download address good for an hour (D-342).
      const res = await f(`${api}/attachments`, auth).catch(() => null);
      const list = res?.ok
        ? ((await res.json().catch(() => ({}))) as { data?: Array<Record<string, unknown>> })
        : {};
      const files: InFile[] = (list.data ?? [])
        .filter((a) => typeof a.download_url === "string")
        .map((a) => ({
          name: a.filename as string | undefined,
          mime: a.content_type as string | undefined,
          size: Number(a.size ?? 0) || undefined,
          fetch: { url: a.download_url },
        }));
      if (!text && !files.length) continue;
      const { fetchId: _f, ...rest } = m;
      out.push({ ...rest, text, ...(files.length ? { files } : {}) });
    }
    return out;
  },
  normalize(req) {
    const e = json(req.body);
    const d = (e.data ?? e) as Record<string, unknown>;
    if (e.type && e.type !== "email.received") return [];
    const from = addr(d.from);
    const subject = String(d.subject ?? "");
    const text =
      String(d.text ?? d.plain ?? "").trim() ||
      String(d.html ?? "")
        .replace(/<[^>]+>/g, " ")
        .trim();
    // Resend's inbound webhook carries only the envelope; the body is fetched in enrich (D-270),
    // and so are attachments (D-342).
    const fetchId = String(d.email_id ?? d.id ?? "") || undefined;
    const attached = Array.isArray(d.attachments) && (d.attachments as unknown[]).length > 0;
    if (!from || (!text && !fetchId)) return [];
    const headers = (d.headers ?? {}) as Record<string, unknown>;
    const messageId =
      String(d.message_id ?? headers["message-id"] ?? headers["Message-ID"] ?? "") || undefined;
    return [
      {
        messageId: messageId ?? fetchId,
        ...(!text || attached ? { fetchId } : {}),
        threadKey: `${from}|${baseSubject(subject).toLowerCase()}`,
        sender: from,
        subject,
        text,
        reply: {
          to: from,
          subject: subject && /^re:/i.test(subject) ? subject : `Re: ${subject || "your message"}`,
          in_reply_to: messageId,
        },
      },
    ];
  },
  async send(cfg, s, reply, text, f) {
    await ok(
      await f(`${base(cfg, "https://api.resend.com")}/emails`, {
        method: "POST",
        headers: { "content-type": "application/json", authorization: `Bearer ${s.api_key}` },
        body: JSON.stringify({
          from: cfg.address,
          to: [reply.to],
          subject: reply.subject,
          text: toPlain(text),
          html: toEmailHtml(text),
          ...(reply.in_reply_to
            ? { headers: { "In-Reply-To": reply.in_reply_to, References: reply.in_reply_to } }
            : {}),
        }),
      }),
      "Resend",
    );
  },
};

// ------------------------------------------------------------------ SMS (Twilio)
const form = (s: string) => Object.fromEntries(new URLSearchParams(s));
export function twilioSignature(url: string, params: Record<string, string>, token: string) {
  const data =
    url +
    Object.keys(params)
      .sort()
      .map((k) => k + params[k])
      .join("");
  return createHmac("sha1", token).update(data).digest("base64");
}
const sms: ChannelAdapter = {
  kind: "sms",
  maxText: 1600,
  verify: (req, cfg, s) =>
    !!s.auth_token &&
    same(
      h(req, "x-twilio-signature"),
      twilioSignature(String(cfg.webhook_url ?? req.url), form(req.body), s.auth_token),
    ),
  normalize(req) {
    const p = form(req.body);
    const files: InFile[] = [];
    for (let i = 0; i < Math.min(Number(p.NumMedia ?? 0), 10); i++)
      if (p[`MediaUrl${i}`])
        files.push({ mime: p[`MediaContentType${i}`], fetch: { url: p[`MediaUrl${i}`] } });
    const text = p.Body ?? "";
    if (!p.From || (!text && !files.length)) return [];
    return [
      {
        messageId: p.MessageSid || p.SmsSid || undefined,
        threadKey: `sms:${p.From}`,
        sender: p.From,
        text,
        reply: { to: p.From },
        ...(files.length ? { files } : {}),
      },
    ];
  },
  // Twilio's media addresses take the account's credentials and redirect to a signed copy.
  async downloadFile(_cfg, s, where, f) {
    const url = String(where.url);
    if (!/^https:\/\/([a-z0-9-]+\.)*twilio\.com\//.test(url))
      throw new Error("not a Twilio media address");
    return bytesOf(
      await f(url, {
        headers: {
          authorization: `Basic ${Buffer.from(`${s.account_sid}:${s.auth_token}`).toString("base64")}`,
        },
      }),
      "Twilio",
    );
  },
  // MMS fetches the file from a public address (the signed link): pictures up to 5 MB, in the US,
  // Canada and Australia; elsewhere Twilio sends a short link to it.
  captionMax: 1600,
  fileFits: (mime, size) => /^image\/(jpeg|png|gif)$/.test(mime) && size <= 5 * MB,
  async sendFile(cfg, s, reply, file, f) {
    if (!file.url) throw new Error("no public address for the file");
    await ok(
      await f(
        `${base(cfg, "https://api.twilio.com")}/2010-04-01/Accounts/${s.account_sid}/Messages.json`,
        {
          method: "POST",
          headers: {
            "content-type": "application/x-www-form-urlencoded",
            authorization: `Basic ${Buffer.from(`${s.account_sid}:${s.auth_token}`).toString("base64")}`,
          },
          body: new URLSearchParams({
            To: String(reply.to),
            From: String(cfg.phone_number),
            ...(file.caption ? { Body: toPlain(file.caption) } : {}),
            MediaUrl: file.url,
          }).toString(),
        },
      ),
      "Twilio",
    );
  },
  async send(cfg, s, reply, text, f) {
    await ok(
      await f(
        `${base(cfg, "https://api.twilio.com")}/2010-04-01/Accounts/${s.account_sid}/Messages.json`,
        {
          method: "POST",
          headers: {
            "content-type": "application/x-www-form-urlencoded",
            authorization: `Basic ${Buffer.from(`${s.account_sid}:${s.auth_token}`).toString("base64")}`,
          },
          body: new URLSearchParams({
            To: String(reply.to),
            From: String(cfg.phone_number),
            Body: toPlain(text),
          }).toString(),
        },
      ),
      "Twilio",
    );
  },
};

// ------------------------------------------------------------------ Slack (Events API, Web API)
const slack: ChannelAdapter = {
  kind: "slack",
  maxText: 39_000,
  handshake(req) {
    const b = json(req.body);
    return b.type === "url_verification"
      ? { status: 200, body: String(b.challenge ?? ""), type: "text/plain" }
      : null;
  },
  verify(req, _c, s) {
    const ts = h(req, "x-slack-request-timestamp");
    if (!s.signing_secret || !ts || Math.abs(Date.now() / 1000 - Number(ts)) > 300) return false;
    const want = `v0=${createHmac("sha256", s.signing_secret).update(`v0:${ts}:${req.body}`).digest("hex")}`;
    return same(h(req, "x-slack-signature"), want);
  },
  normalize(req) {
    const b = json(req.body);
    const e = b.event as Record<string, unknown> | undefined;
    const files = Array.isArray(e?.files) && (e.files as unknown[]).length > 0;
    // Direct messages arrive as "message"; in channels the bot hears an @mention ("app_mention").
    if (
      b.type !== "event_callback" ||
      !e ||
      (e.type !== "message" && e.type !== "app_mention") ||
      e.bot_id ||
      (e.subtype && e.subtype !== "file_share") ||
      (typeof e.text !== "string" && !files)
    )
      return [];
    const thread = String(e.thread_ts ?? e.ts);
    const text = typeof e.text === "string" ? e.text.replace(/<@[A-Z0-9]+>\s*/g, "").trim() : "";
    // Files need the files:read scope to download (D-342).
    const inFiles: InFile[] = files
      ? (e.files as Array<Record<string, unknown>>)
          .filter(
            (x) => typeof x.url_private_download === "string" || typeof x.url_private === "string",
          )
          .map((x) => ({
            name: x.name as string | undefined,
            mime: x.mimetype as string | undefined,
            size: Number(x.size ?? 0) || undefined,
            fetch: { url: x.url_private_download ?? x.url_private },
          }))
      : [];
    if (!text && !inFiles.length) return [];
    return [
      {
        // The same message can come as both "message" and "app_mention": one id for both.
        messageId: e.ts ? `${e.channel}:${e.ts}` : String(b.event_id ?? "") || undefined,
        threadKey: `${e.channel}:${thread}`,
        sender: String(e.user),
        text,
        reply: { channel: e.channel, thread_ts: thread, ts: e.ts },
        ref: e.ts ? `${e.channel}:${e.ts}` : undefined,
        ...(inFiles.length ? { files: inFiles } : {}),
      },
    ];
  },
  // The bot token goes only to Slack's own file host (a file shared from elsewhere can point
  // anywhere).
  async downloadFile(_cfg, s, where, f) {
    const url = String(where.url);
    if (!url.startsWith("https://files.slack.com/")) throw new Error("not a Slack file address");
    return bytesOf(await f(url, { headers: { authorization: `Bearer ${s.bot_token}` } }), "Slack");
  },
  // Uploads go in three steps (files.upload was retired in 2025) and need the files:write scope.
  captionMax: 3000,
  fileFits: (_mime, size) => size <= 1024 * MB,
  async sendFile(cfg, s, reply, file, f) {
    const api = base(cfg, "https://slack.com");
    const auth = { authorization: `Bearer ${s.bot_token}` };
    const step1 = (await (
      await ok(
        await f(`${api}/api/files.getUploadURLExternal`, {
          method: "POST",
          headers: { ...auth, "content-type": "application/x-www-form-urlencoded" },
          body: new URLSearchParams({ filename: file.name, length: String(file.size) }).toString(),
        }),
        "Slack",
      )
    ).json()) as { ok?: boolean; error?: string; upload_url?: string; file_id?: string };
    if (!step1.ok || !step1.upload_url || !step1.file_id)
      throw new Error(`Slack: ${step1.error ?? "no upload address"}`);
    await ok(
      await f(step1.upload_url, {
        method: "POST",
        headers: { "content-type": "application/octet-stream" },
        body: new Uint8Array(file.bytes),
      }),
      "Slack",
    );
    const done = (await (
      await ok(
        await f(`${api}/api/files.completeUploadExternal`, {
          method: "POST",
          headers: { ...auth, "content-type": "application/json; charset=utf-8" },
          body: JSON.stringify({
            files: [{ id: step1.file_id, title: file.name }],
            channel_id: reply.channel,
            ...(reply.thread_ts ? { thread_ts: reply.thread_ts } : {}),
            ...(file.caption ? { initial_comment: toSlack(file.caption) } : {}),
          }),
        }),
        "Slack",
      )
    ).json()) as { ok?: boolean; error?: string };
    if (!done.ok) throw new Error(`Slack: ${done.error ?? "upload not completed"}`);
  },
  // reaction_added / reaction_removed (needs the reactions:read scope and those events). Slack
  // keeps several reactions per person; Casama keeps their latest.
  reactions(req) {
    const b = json(req.body);
    const e = b.event as Record<string, unknown> | undefined;
    const item = e?.item as Record<string, unknown> | undefined;
    if (
      b.type !== "event_callback" ||
      !e ||
      (e.type !== "reaction_added" && e.type !== "reaction_removed") ||
      item?.type !== "message" ||
      !item.channel ||
      !item.ts ||
      !e.user ||
      typeof e.reaction !== "string"
    )
      return [];
    const emoji = emojiFromSlack(e.reaction);
    if (!emoji) return [];
    const ref = `${item.channel}:${item.ts}`;
    return [
      e.type === "reaction_added"
        ? { ref, sender: String(e.user), emoji }
        : { ref, sender: String(e.user), emoji: null, removed: emoji },
    ];
  },
  async react(cfg, s, _reply, ref, emoji, previous, f) {
    const at = ref.indexOf(":");
    if (at <= 0) return;
    const call = (method: string, name: string) =>
      f(`${base(cfg, "https://slack.com")}/api/reactions.${method}`, {
        method: "POST",
        headers: {
          "content-type": "application/json; charset=utf-8",
          authorization: `Bearer ${s.bot_token}`,
        },
        body: JSON.stringify({ channel: ref.slice(0, at), timestamp: ref.slice(at + 1), name }),
      });
    const old = previous ? slackNameOf(previous) : null;
    const next = emoji ? slackNameOf(emoji) : null;
    if (old && old !== next) await call("remove", old).catch(() => {});
    if (next && next !== old) {
      const r = (await bodyJson(await ok(await call("add", next), "Slack"))) as {
        ok?: boolean;
        error?: string;
      };
      if (r.ok === false && r.error !== "already_reacted") throw new Error(`Slack: ${r.error}`);
    }
  },
  async send(cfg, s, reply, text, f) {
    const res = await ok(
      await f(`${base(cfg, "https://slack.com")}/api/chat.postMessage`, {
        method: "POST",
        headers: {
          "content-type": "application/json; charset=utf-8",
          authorization: `Bearer ${s.bot_token}`,
        },
        body: JSON.stringify({
          channel: reply.channel,
          thread_ts: reply.thread_ts,
          text: toSlack(text),
        }),
      }),
      "Slack",
    );
    const r = (await res.json()) as { ok?: boolean; error?: string; channel?: string; ts?: string };
    if (r.ok === false) throw new Error(`Slack: ${r.error}`);
    return r.ts ? `${r.channel ?? reply.channel}:${r.ts}` : null;
  },
  async acknowledge(cfg, s, m, f) {
    if (!m.reply.ts) return;
    await f(`${base(cfg, "https://slack.com")}/api/reactions.add`, {
      method: "POST",
      headers: {
        "content-type": "application/json; charset=utf-8",
        authorization: `Bearer ${s.bot_token}`,
      },
      body: JSON.stringify({ channel: m.reply.channel, timestamp: m.reply.ts, name: "eyes" }),
    }).catch(() => {});
  },
  async sendApproval(cfg, s, reply, approval, f) {
    const res = await ok(
      await f(`${base(cfg, "https://slack.com")}/api/chat.postMessage`, {
        method: "POST",
        headers: {
          "content-type": "application/json; charset=utf-8",
          authorization: `Bearer ${s.bot_token}`,
        },
        body: JSON.stringify({
          channel: reply.channel,
          thread_ts: reply.thread_ts,
          text: `Approval needed: ${approval.summary}`,
          blocks: [
            {
              type: "section",
              text: { type: "mrkdwn", text: `*Approval needed*\n${approval.summary}` },
            },
            {
              type: "actions",
              elements: [
                {
                  type: "button",
                  style: "primary",
                  text: { type: "plain_text", text: "Approve" },
                  action_id: "casama_approve",
                  value: `approve:${approval.id}`,
                },
                {
                  type: "button",
                  style: "danger",
                  text: { type: "plain_text", text: "Deny" },
                  action_id: "casama_deny",
                  value: `deny:${approval.id}`,
                },
              ],
            },
          ],
        }),
      }),
      "Slack",
    );
    const r = (await res.json()) as { ok?: boolean; error?: string };
    if (r.ok === false) throw new Error(`Slack: ${r.error}`);
  },
  parseAction(req) {
    // Slack posts interactions as a form with one field, payload (JSON).
    const raw = new URLSearchParams(req.body).get("payload");
    const p = raw ? json(raw) : {};
    if (p.type !== "block_actions") return null;
    const action = ((p.actions ?? []) as Array<Record<string, unknown>>)[0];
    const m = /^(approve|deny):([0-9a-f-]{36})$/.exec(String(action?.value ?? ""));
    const user = (p.user as Record<string, unknown> | undefined)?.id;
    if (!m || !user) return null;
    return {
      approvalId: m[2] as string,
      decision: m[1] === "approve" ? "approved" : "denied",
      sender: String(user),
      responseUrl: typeof p.response_url === "string" ? p.response_url : undefined,
    };
  },
};

// ------------------------------------------------------------------ WhatsApp and Messenger (Meta)
const metaHandshake = (req: WebhookRequest, _c: Config, s: Secrets) => {
  if (req.method !== "GET") return null;
  const q = new URL(req.url).searchParams;
  return q.get("hub.mode") === "subscribe" &&
    s.verify_token &&
    q.get("hub.verify_token") === s.verify_token
    ? { status: 200, body: q.get("hub.challenge") ?? "", type: "text/plain" }
    : { status: 403, body: "", type: "text/plain" };
};
const metaVerify = (req: WebhookRequest, _c: Config, s: Secrets) =>
  !!s.app_secret &&
  same(
    h(req, "x-hub-signature-256"),
    `sha256=${createHmac("sha256", s.app_secret).update(req.body).digest("hex")}`,
  );
/** What WhatsApp takes as each kind of media, and how big (Cloud API). */
function whatsappKind(mime: string, size: number): string | null {
  if (/^image\/(jpeg|png)$/.test(mime)) return size <= 5 * MB ? "image" : null;
  if (/^video\/(mp4|3gpp)$/.test(mime)) return size <= 16 * MB ? "video" : null;
  if (/^audio\/(aac|amr|mpeg|mp4|ogg)$/.test(mime)) return size <= 16 * MB ? "audio" : null;
  if (
    /^(application\/pdf|text\/plain|application\/(msword|vnd\.ms-excel|vnd\.ms-powerpoint|vnd\.openxmlformats-officedocument\.[\w.]+))$/.test(
      mime,
    )
  )
    return size <= 100 * MB ? "document" : null;
  return null;
}
const whatsapp: ChannelAdapter = {
  kind: "whatsapp",
  maxText: 4096,
  async downloadFile(cfg, s, where, f) {
    const api = base(cfg, "https://graph.facebook.com");
    const auth = { headers: { authorization: `Bearer ${s.access_token}` } };
    const meta = (await (
      await ok(await f(`${api}/v20.0/${encodeURIComponent(String(where.id))}`, auth), "WhatsApp")
    ).json()) as { url?: string; mime_type?: string };
    if (!meta.url) throw new Error("WhatsApp didn't give the file");
    const got = await bytesOf(await f(meta.url, auth), "WhatsApp");
    return { ...got, mime: meta.mime_type ?? got.mime };
  },
  captionMax: 1024,
  fileFits: (mime, size) => whatsappKind(mime, size) !== null,
  // Uploaded first, then sent by its id (Meta's advice over links).
  async sendFile(cfg, s, reply, file, f) {
    const kind = whatsappKind(file.mime, file.size) ?? "document";
    const api = `${base(cfg, "https://graph.facebook.com")}/v20.0/${cfg.phone_number_id}`;
    const auth = { authorization: `Bearer ${s.access_token}` };
    const form = new FormData();
    form.set("messaging_product", "whatsapp");
    form.set("type", file.mime);
    form.set("file", blobOf(file), file.name);
    const up = (await (
      await ok(await f(`${api}/media`, { method: "POST", headers: auth, body: form }), "WhatsApp")
    ).json()) as { id?: string };
    if (!up.id) throw new Error("WhatsApp didn't take the file");
    // Audio takes no caption: the words go first, on their own.
    if (file.caption && kind === "audio") await this.send(cfg, s, reply, file.caption, f);
    const res = await ok(
      await f(`${api}/messages`, {
        method: "POST",
        headers: { ...auth, "content-type": "application/json" },
        body: JSON.stringify({
          messaging_product: "whatsapp",
          to: reply.to,
          type: kind,
          [kind]: {
            id: up.id,
            ...(file.caption && kind !== "audio" ? { caption: toWhatsApp(file.caption) } : {}),
            ...(kind === "document" ? { filename: file.name } : {}),
          },
        }),
      }),
      "WhatsApp",
    );
    const r = (await bodyJson(res)) as { messages?: Array<{ id?: string }> };
    return r.messages?.[0]?.id ?? null;
  },
  handshake: metaHandshake,
  verify: metaVerify,
  normalize(req) {
    const out: InboundMessage[] = [];
    for (const entry of (json(req.body).entry ?? []) as Array<Record<string, unknown>>)
      for (const ch of (entry.changes ?? []) as Array<Record<string, unknown>>) {
        const v = (ch.value ?? {}) as Record<string, unknown>;
        const names = new Map(
          ((v.contacts ?? []) as Array<Record<string, unknown>>).map((c) => [
            String(c.wa_id),
            String((c.profile as Record<string, unknown>)?.name ?? ""),
          ]),
        );
        for (const m of (v.messages ?? []) as Array<Record<string, unknown>>) {
          const body = (m.text as Record<string, unknown> | undefined)?.body;
          const media = ["image", "document", "audio", "video", "sticker"].includes(String(m.type));
          const item = m[String(m.type)] as Record<string, unknown> | undefined;
          const caption = item?.caption;
          // Media comes as an id to look up (D-342).
          const files: InFile[] =
            media && item?.id
              ? [
                  {
                    name: item.filename as string | undefined,
                    mime: item.mime_type as string | undefined,
                    fetch: { id: item.id },
                  },
                ]
              : [];
          const text =
            m.type === "text" && typeof body === "string"
              ? body
              : typeof caption === "string"
                ? caption
                : ["location", "contacts"].includes(String(m.type))
                  ? ATTACHMENT_NOTE
                  : "";
          if (!text && !files.length) continue;
          out.push({
            messageId: m.id ? String(m.id) : undefined,
            threadKey: `wa:${m.from}`,
            sender: String(m.from),
            senderName: names.get(String(m.from)),
            text,
            reply: { to: m.from },
            ref: m.id ? String(m.id) : undefined,
            ...(files.length ? { files } : {}),
          });
        }
      }
    return out;
  },
  // A reaction is a message of type "reaction"; an empty emoji takes it back.
  reactions(req) {
    const out: InboundReaction[] = [];
    for (const entry of (json(req.body).entry ?? []) as Array<Record<string, unknown>>)
      for (const ch of (entry.changes ?? []) as Array<Record<string, unknown>>) {
        const v = (ch.value ?? {}) as Record<string, unknown>;
        const names = new Map(
          ((v.contacts ?? []) as Array<Record<string, unknown>>).map((c) => [
            String(c.wa_id),
            String((c.profile as Record<string, unknown>)?.name ?? ""),
          ]),
        );
        for (const m of (v.messages ?? []) as Array<Record<string, unknown>>) {
          const r = m.reaction as Record<string, unknown> | undefined;
          if (m.type !== "reaction" || !r?.message_id || !m.from) continue;
          out.push({
            ref: String(r.message_id),
            sender: String(m.from),
            senderName: names.get(String(m.from)) || undefined,
            emoji: typeof r.emoji === "string" && r.emoji ? r.emoji : null,
          });
        }
      }
    return out;
  },
  async react(cfg, s, reply, ref, emoji, _previous, f) {
    if (!reply.to) return;
    await ok(
      await f(`${base(cfg, "https://graph.facebook.com")}/v20.0/${cfg.phone_number_id}/messages`, {
        method: "POST",
        headers: { "content-type": "application/json", authorization: `Bearer ${s.access_token}` },
        body: JSON.stringify({
          messaging_product: "whatsapp",
          recipient_type: "individual",
          to: reply.to,
          type: "reaction",
          reaction: { message_id: ref, emoji: emoji ?? "" },
        }),
      }),
      "WhatsApp",
    );
  },
  async send(cfg, s, reply, text, f) {
    const res = await ok(
      await f(`${base(cfg, "https://graph.facebook.com")}/v20.0/${cfg.phone_number_id}/messages`, {
        method: "POST",
        headers: { "content-type": "application/json", authorization: `Bearer ${s.access_token}` },
        body: JSON.stringify({
          messaging_product: "whatsapp",
          to: reply.to,
          type: "text",
          text: { body: toWhatsApp(text) },
        }),
      }),
      "WhatsApp",
    );
    const r = (await bodyJson(res)) as { messages?: Array<{ id?: string }> };
    return r.messages?.[0]?.id ?? null;
  },
};
const messenger: ChannelAdapter = {
  kind: "messenger",
  maxText: 2000,
  async downloadFile(_cfg, _s, where, f) {
    const url = String(where.url);
    if (!/^https:\/\//.test(url)) throw new Error("not a Messenger file address");
    return bytesOf(await f(url), "Messenger");
  },
  fileFits: (_mime, size) => size <= 25 * MB,
  // Sent as the file itself; Messenger has no captions, so the words go first.
  async sendFile(cfg, s, reply, file, f) {
    if (file.caption) await this.send(cfg, s, reply, file.caption, f);
    const form = new FormData();
    form.set("recipient", JSON.stringify({ id: reply.recipient }));
    form.set("messaging_type", "RESPONSE");
    form.set(
      "message",
      JSON.stringify({ attachment: { type: kindOf(file.mime), payload: { is_reusable: false } } }),
    );
    form.set("filedata", blobOf(file), file.name);
    await ok(
      await f(
        `${base(cfg, "https://graph.facebook.com")}/v20.0/me/messages?access_token=${encodeURIComponent(s.page_token ?? "")}`,
        { method: "POST", body: form },
      ),
      "Messenger",
    );
  },
  async typing(cfg, s, reply, f) {
    await f(
      `${base(cfg, "https://graph.facebook.com")}/v20.0/me/messages?access_token=${encodeURIComponent(s.page_token ?? "")}`,
      {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ recipient: { id: reply.recipient }, sender_action: "typing_on" }),
      },
    );
  },
  handshake: metaHandshake,
  verify: metaVerify,
  normalize(req) {
    const out: InboundMessage[] = [];
    for (const entry of (json(req.body).entry ?? []) as Array<Record<string, unknown>>)
      for (const m of (entry.messaging ?? []) as Array<Record<string, unknown>>) {
        const msg = m.message as Record<string, unknown> | undefined;
        const sender = (m.sender as Record<string, unknown> | undefined)?.id;
        const attachments = (Array.isArray(msg?.attachments) ? msg.attachments : []) as Array<
          Record<string, unknown>
        >;
        // Pictures, video, audio and files come with an address to fetch them from (D-342).
        const files: InFile[] = attachments
          .filter(
            (a) =>
              ["image", "video", "audio", "file"].includes(String(a.type)) &&
              typeof (a.payload as Record<string, unknown> | undefined)?.url === "string",
          )
          .map((a) => ({ fetch: { url: (a.payload as Record<string, unknown>).url } }));
        if (!msg || msg.is_echo || !sender) continue;
        const text =
          typeof msg.text === "string"
            ? msg.text
            : attachments.length && !files.length
              ? ATTACHMENT_NOTE
              : "";
        if (!text && !files.length) continue;
        out.push({
          messageId: msg.mid ? String(msg.mid) : undefined,
          threadKey: `fb:${sender}`,
          sender: String(sender),
          text,
          reply: { recipient: sender },
          ...(files.length ? { files } : {}),
        });
      }
    return out;
  },
  async send(cfg, s, reply, text, f) {
    await ok(
      await f(
        `${base(cfg, "https://graph.facebook.com")}/v20.0/me/messages?access_token=${encodeURIComponent(s.page_token ?? "")}`,
        {
          method: "POST",
          headers: { "content-type": "application/json" },
          body: JSON.stringify({
            recipient: { id: reply.recipient },
            messaging_type: "RESPONSE",
            message: { text: toPlain(text) },
          }),
        },
      ),
      "Messenger",
    );
  },
};

// ------------------------------------------------------------------ Feishu (open platform events v2)
/** Feishu's "encrypt" bodies: AES-256-CBC, key = SHA-256 of the encrypt key, IV = first 16 bytes. */
export function feishuDecrypt(encrypted: string, encryptKey: string) {
  const raw = Buffer.from(encrypted, "base64");
  const key = createHash("sha256").update(encryptKey).digest();
  const d = createDecipheriv("aes-256-cbc", key, raw.subarray(0, 16));
  return Buffer.concat([d.update(raw.subarray(16)), d.final()]).toString("utf8");
}
async function feishuToken(cfg: Config, s: Secrets, f: typeof fetch) {
  const tok = (await (
    await ok(
      await f(
        `${base(cfg, "https://open.feishu.cn")}/open-apis/auth/v3/tenant_access_token/internal`,
        {
          method: "POST",
          headers: { "content-type": "application/json" },
          body: JSON.stringify({ app_id: cfg.app_id, app_secret: s.app_secret }),
        },
      ),
      "Feishu",
    )
  ).json()) as { tenant_access_token?: string };
  return tok.tenant_access_token;
}
const feishu: ChannelAdapter = {
  kind: "feishu",
  maxText: 10_000,
  // With an encrypt key set (which Casama requires), every body arrives as {"encrypt": "..."}; it
  // was parsed as if it were plain, so nothing ever came through (D-270).
  decode(req, _c, s) {
    const enc = json(req.body).encrypt;
    if (typeof enc !== "string" || !s.encrypt_key) return req;
    try {
      return { ...req, body: feishuDecrypt(enc, s.encrypt_key) };
    } catch {
      return req;
    }
  },
  handshake(req, _c, s) {
    const b = json(req.body);
    if (b.type !== "url_verification") return null;
    return b.token === s.verification_token
      ? { status: 200, body: JSON.stringify({ challenge: b.challenge }), type: "application/json" }
      : { status: 403, body: "", type: "text/plain" };
  },
  verify(req, _c, s) {
    const ts = h(req, "x-lark-request-timestamp");
    const nonce = h(req, "x-lark-request-nonce");
    if (!s.encrypt_key || !ts) return false;
    const want = createHash("sha256")
      .update(ts + nonce + s.encrypt_key + req.body)
      .digest("hex");
    return same(h(req, "x-lark-signature"), want);
  },
  normalize(req) {
    const b = json(req.body);
    const header = b.header as Record<string, unknown> | undefined;
    const ev = b.event as Record<string, unknown> | undefined;
    if (header?.event_type !== "im.message.receive_v1" || !ev) return [];
    const msg = ev.message as Record<string, unknown>;
    const sender = ((ev.sender as Record<string, unknown>)?.sender_id as Record<string, unknown>)
      ?.open_id;
    if (!msg || !sender) return [];
    const content = json(String(msg.content ?? "{}"));
    // Pictures and files are fetched from the message's resources (D-342).
    const key = msg.message_type === "image" ? content.image_key : content.file_key;
    const files: InFile[] =
      ["image", "file", "audio", "media"].includes(String(msg.message_type)) && key
        ? [
            {
              name: content.file_name as string | undefined,
              fetch: {
                message_id: msg.message_id,
                key,
                type: msg.message_type === "image" ? "image" : "file",
              },
            },
          ]
        : [];
    const text =
      msg.message_type === "text"
        ? String(content.text ?? "")
            .replace(/@_user_\d+\s*/g, "")
            .trim()
        : msg.message_type === "sticker"
          ? ATTACHMENT_NOTE
          : "";
    if (!text && !files.length) return [];
    return [
      {
        messageId: String(header?.event_id ?? msg.message_id ?? "") || undefined,
        threadKey: `chat:${msg.chat_id}`,
        sender: String(sender),
        text,
        reply: { chat_id: msg.chat_id },
        ...(files.length ? { files } : {}),
      },
    ];
  },
  async downloadFile(cfg, s, where, f) {
    const b = base(cfg, "https://open.feishu.cn");
    const tok = await feishuToken(cfg, s, f);
    return bytesOf(
      await f(
        `${b}/open-apis/im/v1/messages/${encodeURIComponent(String(where.message_id))}/resources/${encodeURIComponent(String(where.key))}?type=${where.type === "image" ? "image" : "file"}`,
        { headers: { authorization: `Bearer ${tok}` } },
      ),
      "Feishu",
    );
  },
  fileFits: (mime, size) => size <= (mime.startsWith("image/") ? 10 : 30) * MB,
  // Uploaded first, then sent by key; no captions, so the words go first.
  async sendFile(cfg, s, reply, file, f) {
    if (file.caption) await this.send(cfg, s, reply, file.caption, f);
    const b = base(cfg, "https://open.feishu.cn");
    const tok = await feishuToken(cfg, s, f);
    const image = file.mime.startsWith("image/");
    const form = new FormData();
    if (image) {
      form.set("image_type", "message");
      form.set("image", blobOf(file), file.name);
    } else {
      const ext = file.name.split(".").pop()?.toLowerCase() ?? "";
      form.set(
        "file_type",
        ext === "pdf"
          ? "pdf"
          : /^docx?$/.test(ext)
            ? "doc"
            : /^xlsx?$/.test(ext)
              ? "xls"
              : /^pptx?$/.test(ext)
                ? "ppt"
                : ext === "mp4"
                  ? "mp4"
                  : ext === "opus"
                    ? "opus"
                    : "stream",
      );
      form.set("file_name", file.name);
      form.set("file", blobOf(file), file.name);
    }
    const up = (await (
      await ok(
        await f(`${b}/open-apis/im/v1/${image ? "images" : "files"}`, {
          method: "POST",
          headers: { authorization: `Bearer ${tok}` },
          body: form,
        }),
        "Feishu",
      )
    ).json()) as { data?: { image_key?: string; file_key?: string } };
    const key = image ? up.data?.image_key : up.data?.file_key;
    if (!key) throw new Error("Feishu didn't take the file");
    await ok(
      await f(`${b}/open-apis/im/v1/messages?receive_id_type=chat_id`, {
        method: "POST",
        headers: { "content-type": "application/json", authorization: `Bearer ${tok}` },
        body: JSON.stringify({
          receive_id: reply.chat_id,
          msg_type: image ? "image" : "file",
          content: JSON.stringify(image ? { image_key: key } : { file_key: key }),
        }),
      }),
      "Feishu",
    );
  },
  async send(cfg, s, reply, text, f) {
    const b = base(cfg, "https://open.feishu.cn");
    const tok = { tenant_access_token: await feishuToken(cfg, s, f) };
    await ok(
      await f(`${b}/open-apis/im/v1/messages?receive_id_type=chat_id`, {
        method: "POST",
        headers: {
          "content-type": "application/json",
          authorization: `Bearer ${tok.tenant_access_token}`,
        },
        body: JSON.stringify({
          receive_id: reply.chat_id,
          msg_type: "text",
          content: JSON.stringify({ text: toPlain(text) }),
        }),
      }),
      "Feishu",
    );
  },
};

// ------------------------------------------------------------------ iMessage (through the desktop companion)
/**
 * iMessage has no bot API: the user's own Mac, running the desktop app, reads new messages and
 * sends replies through Messages. Inbound messages are polled by the worker through the device
 * tunnel (see `pollIMessage`); sending goes the same way. No webhook.
 */
const imessage: ChannelAdapter = {
  kind: "imessage",
  verify: () => false,
  normalize: () => [],
  async send(cfg, s, reply, text, f) {
    await ok(
      await f(`${String(cfg.tunnel_url).replace(/\/$/, "")}/imessage/send`, {
        method: "POST",
        headers: {
          "content-type": "application/json",
          "x-casama-internal": s.internal_token ?? "",
        },
        body: JSON.stringify({ to: reply.to, text: toPlain(text) }),
      }),
      "The Mac",
    );
  },
  // The Mac sends the file through Messages (D-342). A desktop app from before files sends the
  // text instead, which carries the file's link.
  fileFits: (_mime, size) => size <= 50 * MB,
  async sendFile(cfg, s, reply, file, f) {
    if (file.caption) await this.send(cfg, s, reply, file.caption, f);
    await ok(
      await f(`${String(cfg.tunnel_url).replace(/\/$/, "")}/imessage/send`, {
        method: "POST",
        headers: {
          "content-type": "application/json",
          "x-casama-internal": s.internal_token ?? "",
        },
        body: JSON.stringify({
          to: reply.to,
          text: fileLinkLine(file, file.url),
          file: { name: file.name, data: Buffer.from(file.bytes).toString("base64") },
        }),
      }),
      "The Mac",
    );
  },
  async downloadFile(cfg, s, where, f) {
    return bytesOf(
      await f(
        `${String(cfg.tunnel_url).replace(/\/$/, "")}/imessage/attachment/${encodeURIComponent(String(where.id))}`,
        { headers: { "x-casama-internal": s.internal_token ?? "" } },
      ),
      "The Mac",
    );
  },
};

// ------------------------------------------------------------------ Discord (HTTP interactions; D-278)
/**
 * Discord bots hear messages only over a long-lived gateway connection, which a webhook server
 * doesn't keep. Casama uses Discord's HTTP interactions instead: people talk to the bot with its
 * /ask command (and in DMs with the bot, the same command). Replies go to the interaction's
 * follow-up address for its 15 minutes, then as a channel message with the bot token.
 */
const ED25519_SPKI = Buffer.from("302a300506032b6570032100", "hex");
const INTERACTION_TTL_MS = 14 * 60_000;
const discord: ChannelAdapter = {
  kind: "discord",
  maxText: 2000,
  verify(req, cfg) {
    const sig = h(req, "x-signature-ed25519");
    const ts = h(req, "x-signature-timestamp");
    const key = String(cfg.public_key ?? "");
    if (!sig || !ts || !/^[0-9a-f]{64}$/i.test(key) || !/^[0-9a-f]{128}$/i.test(sig)) return false;
    try {
      return verifySignature(
        null,
        Buffer.from(ts + req.body),
        createPublicKey({
          key: Buffer.concat([ED25519_SPKI, Buffer.from(key, "hex")]),
          format: "der",
          type: "spki",
        }),
        Buffer.from(sig, "hex"),
      );
    } catch {
      return false;
    }
  },
  normalize(req) {
    const b = json(req.body);
    if (b.type !== 2) return [];
    const data = (b.data ?? {}) as Record<string, unknown>;
    const options = (data.options ?? []) as Array<Record<string, unknown>>;
    // Option type 3 is the question; type 11 an attachment, described under resolved (D-342).
    const text = String(
      options.find((o) => o.type !== 11 && typeof o.value === "string")?.value ?? "",
    ).trim();
    const resolved = ((data.resolved as Record<string, unknown> | undefined)?.attachments ??
      {}) as Record<string, Record<string, unknown>>;
    const files: InFile[] = options
      .filter((o) => o.type === 11 && resolved[String(o.value)]?.url)
      .map((o) => {
        const a = resolved[String(o.value)] as Record<string, unknown>;
        return {
          name: a.filename as string | undefined,
          mime: a.content_type as string | undefined,
          size: Number(a.size ?? 0) || undefined,
          fetch: { url: a.url },
        };
      });
    const user = ((b.member as Record<string, unknown> | undefined)?.user ?? b.user) as
      | Record<string, unknown>
      | undefined;
    if ((!text && !files.length) || !user?.id) return [];
    return [
      {
        messageId: b.id ? String(b.id) : undefined,
        threadKey: `discord:${b.channel_id}`,
        sender: String(user.id),
        senderName: (user.global_name ?? user.username) as string | undefined,
        text,
        reply: {
          channel_id: b.channel_id,
          application_id: b.application_id,
          token: b.token,
          at: Date.now(),
        },
        ...(files.length ? { files } : {}),
      },
    ];
  },
  async downloadFile(_cfg, _s, where, f) {
    const url = String(where.url);
    if (!/^https:\/\/(cdn|media)\.discordapp\.(com|net)\//.test(url))
      throw new Error("not a Discord file address");
    return bytesOf(await f(url), "Discord");
  },
  captionMax: 2000,
  fileFits: (_mime, size) => size <= 10 * MB,
  // The file goes with the reply to the command while it's fresh, then as a channel message.
  async sendFile(cfg, s, reply, file, f) {
    const api = base(cfg, "https://discord.com/api/v10");
    const fresh = reply.token && Date.now() - Number(reply.at ?? 0) < INTERACTION_TTL_MS;
    const form = new FormData();
    form.set(
      "payload_json",
      JSON.stringify({
        ...(file.caption ? { content: file.caption } : {}),
        attachments: [{ id: 0, filename: file.name }],
      }),
    );
    form.set("files[0]", blobOf(file), file.name);
    await ok(
      fresh
        ? await f(`${api}/webhooks/${reply.application_id}/${reply.token}`, {
            method: "POST",
            body: form,
          })
        : await f(`${api}/channels/${reply.channel_id}/messages`, {
            method: "POST",
            headers: { authorization: `Bot ${s.bot_token}` },
            body: form,
          }),
      "Discord",
    );
  },
  respond(req) {
    const b = json(req.body);
    // PING is Discord checking the address; a command gets "thinking…" while the bot works.
    if (b.type === 1)
      return { status: 200, body: JSON.stringify({ type: 1 }), type: "application/json" };
    if (b.type === 2)
      return { status: 200, body: JSON.stringify({ type: 5 }), type: "application/json" };
    return null;
  },
  async send(cfg, s, reply, text, f) {
    const api = base(cfg, "https://discord.com/api/v10");
    const fresh = reply.token && Date.now() - Number(reply.at ?? 0) < INTERACTION_TTL_MS;
    await ok(
      fresh
        ? await f(`${api}/webhooks/${reply.application_id}/${reply.token}`, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: JSON.stringify({ content: text }),
          })
        : await f(`${api}/channels/${reply.channel_id}/messages`, {
            method: "POST",
            headers: { "content-type": "application/json", authorization: `Bot ${s.bot_token}` },
            body: JSON.stringify({ content: text }),
          }),
      "Discord",
    );
  },
};

// ------------------------------------------------------------------ Microsoft Teams (Bot Framework; D-278)
const BOT_FRAMEWORK_OPENID = "https://login.botframework.com/v1/.well-known/openidconfiguration";
const jwksCache = new Map<string, ReturnType<typeof import("jose").createRemoteJWKSet>>();
async function teamsToken(cfg: Config, s: Secrets, f: typeof fetch) {
  const res = await ok(
    await f(
      `${String(cfg.login_base ?? "https://login.microsoftonline.com").replace(/\/$/, "")}/${String(cfg.tenant_id ?? "botframework.com")}/oauth2/v2.0/token`,
      {
        method: "POST",
        headers: { "content-type": "application/x-www-form-urlencoded" },
        body: new URLSearchParams({
          grant_type: "client_credentials",
          client_id: String(cfg.app_id),
          client_secret: s.app_password ?? "",
          scope: "https://api.botframework.com/.default",
        }).toString(),
      },
    ),
    "Microsoft sign-in",
  );
  return String(((await res.json()) as { access_token?: string }).access_token ?? "");
}
const teams: ChannelAdapter = {
  kind: "teams",
  maxText: 25_000,
  verify: () => false,
  async verifyAsync(req, cfg, _s, f) {
    const auth = h(req, "authorization");
    if (!auth.startsWith("Bearer ") || !cfg.app_id) return false;
    try {
      const { createRemoteJWKSet, jwtVerify } = await import("jose");
      const openid = String(cfg.openid_url ?? BOT_FRAMEWORK_OPENID);
      let jwks = jwksCache.get(openid);
      if (!jwks) {
        const meta = (await (await f(openid)).json()) as { jwks_uri?: string };
        if (!meta.jwks_uri) return false;
        jwks = createRemoteJWKSet(new URL(meta.jwks_uri));
        jwksCache.set(openid, jwks);
      }
      const { payload } = await jwtVerify(auth.slice(7), jwks, {
        issuer: String(cfg.issuer ?? "https://api.botframework.com"),
        audience: String(cfg.app_id),
        clockTolerance: 300,
      });
      // The token names the service it came from; the activity must say the same.
      const activity = json(req.body);
      return !payload.serviceurl || payload.serviceurl === activity.serviceUrl;
    } catch {
      return false;
    }
  },
  normalize(req) {
    const a = json(req.body);
    if (a.type !== "message") return [];
    const from = (a.from ?? {}) as Record<string, unknown>;
    const conv = (a.conversation ?? {}) as Record<string, unknown>;
    const text = String(a.text ?? "")
      .replace(/<at>[^<]*<\/at>\s*/g, "")
      .replace(/<[^>]+>/g, "")
      .trim();
    // Files in a personal chat come with a ready download address; pasted pictures need the
    // bot's token (D-342). The HTML copy of a message is skipped.
    const files: InFile[] = [];
    for (const x of (a.attachments ?? []) as Array<Record<string, unknown>>) {
      const content = (x.content ?? {}) as Record<string, unknown>;
      if (
        x.contentType === "application/vnd.microsoft.teams.file.download.info" &&
        content.downloadUrl
      )
        files.push({ name: x.name as string | undefined, fetch: { url: content.downloadUrl } });
      else if (String(x.contentType ?? "").startsWith("image/") && typeof x.contentUrl === "string")
        files.push({
          name: x.name as string | undefined,
          mime: String(x.contentType),
          fetch: { url: x.contentUrl, auth: true },
        });
    }
    if ((!text && !files.length) || !conv.id) return [];
    return [
      {
        messageId: a.id ? String(a.id) : undefined,
        threadKey: `teams:${conv.id}`,
        sender: String(from.aadObjectId ?? from.id ?? ""),
        senderName: from.name as string | undefined,
        text,
        reply: { service_url: a.serviceUrl, conversation_id: conv.id, activity_id: a.id },
        ...(files.length ? { files } : {}),
      },
    ];
  },
  async downloadFile(cfg, s, where, f) {
    const url = String(where.url);
    if (!/^https:\/\//.test(url)) throw new Error("not a Teams file address");
    const headers: Record<string, string> = where.auth
      ? { authorization: `Bearer ${await teamsToken(cfg, s, f)}` }
      : {};
    return bytesOf(await f(url, { headers }), "Teams");
  },
  // Pictures up to 1 MB go inline in the message; other files go as links (bots can't post files
  // into group chats and channels).
  captionMax: 25_000,
  fileFits: (mime, size) => /^image\/(png|jpeg|gif)$/.test(mime) && size <= MB,
  async sendFile(cfg, s, reply, file, f) {
    const token = await teamsToken(cfg, s, f);
    const service = base(cfg, String(reply.service_url ?? ""));
    if (!/^https:\/\//.test(service) && !cfg.api_base)
      throw new Error("Teams: the conversation has no service address");
    await ok(
      await f(
        `${service}/v3/conversations/${encodeURIComponent(String(reply.conversation_id))}/activities`,
        {
          method: "POST",
          headers: { "content-type": "application/json", authorization: `Bearer ${token}` },
          body: JSON.stringify({
            type: "message",
            ...(file.caption ? { text: file.caption } : {}),
            attachments: [
              {
                contentType: file.mime,
                contentUrl: `data:${file.mime};base64,${Buffer.from(file.bytes).toString("base64")}`,
                name: file.name,
              },
            ],
            ...(reply.activity_id ? { replyToId: reply.activity_id } : {}),
          }),
        },
      ),
      "Teams",
    );
  },
  async send(cfg, s, reply, text, f) {
    const token = await teamsToken(cfg, s, f);
    // The service address comes from the signed activity; api_base overrides it (tests, proxies).
    const service = base(cfg, String(reply.service_url ?? ""));
    if (!/^https:\/\//.test(service) && !cfg.api_base)
      throw new Error("Teams: the conversation has no service address");
    await ok(
      await f(
        `${service}/v3/conversations/${encodeURIComponent(String(reply.conversation_id))}/activities`,
        {
          method: "POST",
          headers: { "content-type": "application/json", authorization: `Bearer ${token}` },
          body: JSON.stringify({
            type: "message",
            text,
            ...(reply.activity_id ? { replyToId: reply.activity_id } : {}),
          }),
        },
      ),
      "Teams",
    );
  },
};

// ------------------------------------------------------------------ Linear and Jira (issues; D-285)
/**
 * An issue tracker as a chat app: assigning an issue to the bot's tracker user (or commenting on
 * one it was given) is a message, and the bot's reply is a comment on the issue. One conversation
 * per issue, so follow-up comments keep the context.
 */
/** Files uploaded to Linear and linked in an issue or comment's Markdown (D-342). */
function linearFiles(markdown: string): { files?: InFile[] } {
  const files: InFile[] = [];
  for (const m of markdown.matchAll(
    /!?\[([^\]\n]*)\]\((https:\/\/uploads\.linear\.app\/[^)\s]+)\)/g,
  ))
    if (files.length < 10) files.push({ name: m[1]?.trim() || undefined, fetch: { url: m[2] } });
  return files.length ? { files } : {};
}
const linear: ChannelAdapter = {
  kind: "linear",
  maxText: 50_000,
  async downloadFile(_cfg, s, where, f) {
    const url = String(where.url);
    if (!url.startsWith("https://uploads.linear.app/"))
      throw new Error("not a Linear file address");
    return bytesOf(await f(url, { headers: { authorization: s.api_key ?? "" } }), "Linear");
  },
  captionMax: 50_000,
  fileFits: (_mime, size) => size <= 50 * MB,
  // Uploaded to Linear's storage, then shown in a comment (pictures inline).
  async sendFile(cfg, s, reply, file, f) {
    const api = `${base(cfg, "https://api.linear.app")}/graphql`;
    const gql = async (query: string, variables: Record<string, unknown>) => {
      const r = (await (
        await ok(
          await f(api, {
            method: "POST",
            headers: { "content-type": "application/json", authorization: s.api_key ?? "" },
            body: JSON.stringify({ query, variables }),
          }),
          "Linear",
        )
      ).json()) as { data?: Record<string, unknown>; errors?: Array<{ message?: string }> };
      if (r.errors?.length) throw new Error(`Linear: ${r.errors[0]?.message ?? "error"}`);
      return r.data ?? {};
    };
    const up = (
      (
        await gql(
          "mutation($c: String!, $n: String!, $s: Int!) { fileUpload(contentType: $c, filename: $n, size: $s) { uploadFile { uploadUrl assetUrl headers { key value } } } }",
          { c: file.mime, n: file.name, s: file.size },
        )
      ).fileUpload as {
        uploadFile?: {
          uploadUrl: string;
          assetUrl: string;
          headers: Array<{ key: string; value: string }>;
        };
      }
    )?.uploadFile;
    if (!up) throw new Error("Linear didn't give an upload address");
    await ok(
      await f(up.uploadUrl, {
        method: "PUT",
        headers: {
          "content-type": file.mime,
          "cache-control": "public, max-age=31536000",
          ...Object.fromEntries(up.headers.map((h) => [h.key, h.value])),
        },
        body: new Uint8Array(file.bytes),
      }),
      "Linear",
    );
    const link = `${file.mime.startsWith("image/") ? "!" : ""}[${file.name.replace(/[[\]]/g, "")}](${up.assetUrl})`;
    await gql(
      "mutation($input: CommentCreateInput!) { commentCreate(input: $input) { success } }",
      {
        input: {
          issueId: reply.issue_id,
          body: file.caption ? `${file.caption}\n\n${link}` : link,
        },
      },
    );
  },
  verify(req, _c, s) {
    if (!s.webhook_secret) return false;
    const want = createHmac("sha256", s.webhook_secret).update(req.body).digest("hex");
    const ts = Number(json(req.body).webhookTimestamp ?? 0);
    return (
      same(h(req, "linear-signature"), want) && (!ts || Math.abs(Date.now() - ts) < 5 * 60_000)
    );
  },
  normalize(req, cfg) {
    const b = json(req.body);
    const data = (b.data ?? {}) as Record<string, unknown>;
    const actor = (b.actor ?? {}) as Record<string, unknown>;
    const me = String(cfg.assignee_id ?? "");
    if (!me || actor.id === me) return [];
    if (b.type === "Issue" && (b.action === "create" || b.action === "update")) {
      const assignedNow =
        data.assigneeId === me &&
        (b.action === "create" ||
          (b.updatedFrom as Record<string, unknown> | undefined)?.assigneeId !== undefined);
      if (!assignedNow) return [];
      return [
        {
          messageId: `${data.id}:assigned:${b.webhookTimestamp ?? b.createdAt ?? ""}`,
          threadKey: `linear:${data.id}`,
          sender: String(actor.id ?? ""),
          senderName: actor.name as string | undefined,
          subject: `${data.identifier ?? ""} ${data.title ?? ""}`.trim(),
          text: `You were assigned the Linear issue ${data.identifier ?? ""}: ${data.title ?? ""}\n\n${String(data.description ?? "").trim()}\n\nDo the work, then reply with what you did; your reply is posted as a comment on the issue.`.trim(),
          reply: { issue_id: data.id },
          ...linearFiles(String(data.description ?? "")),
        },
      ];
    }
    if (b.type === "Comment" && b.action === "create") {
      const issue = (data.issue ?? {}) as Record<string, unknown>;
      if (issue.assigneeId !== undefined && issue.assigneeId !== me) return [];
      const text = String(data.body ?? "").trim();
      if (!text || !data.issueId) return [];
      return [
        {
          messageId: String(data.id ?? "") || undefined,
          threadKey: `linear:${data.issueId}`,
          sender: String(actor.id ?? data.userId ?? ""),
          senderName: actor.name as string | undefined,
          text,
          reply: { issue_id: data.issueId },
          ...linearFiles(text),
        },
      ];
    }
    return [];
  },
  async send(cfg, s, reply, text, f) {
    const res = await ok(
      await f(`${base(cfg, "https://api.linear.app")}/graphql`, {
        method: "POST",
        headers: { "content-type": "application/json", authorization: s.api_key ?? "" },
        body: JSON.stringify({
          query:
            "mutation($input: CommentCreateInput!) { commentCreate(input: $input) { success } }",
          variables: { input: { issueId: reply.issue_id, body: text } },
        }),
      }),
      "Linear",
    );
    const r = (await res.json()) as { errors?: Array<{ message?: string }> };
    if (r.errors?.length) throw new Error(`Linear: ${r.errors[0]?.message ?? "error"}`);
  },
};

/** The plain text of a Jira description or comment (Atlassian Document Format, or a string). */
export function adfText(node: unknown): string {
  if (typeof node === "string") return node;
  if (!node || typeof node !== "object") return "";
  const n = node as { type?: string; text?: string; content?: unknown[] };
  if (n.type === "text") return n.text ?? "";
  const inner = (n.content ?? []).map(adfText).join("");
  return ["paragraph", "heading", "listItem", "codeBlock", "blockquote"].includes(n.type ?? "")
    ? `${inner}\n`
    : inner;
}
const jiraAuth = (cfg: Config, s: Secrets) =>
  `Basic ${Buffer.from(`${cfg.email}:${s.api_token}`).toString("base64")}`;
const jiraSite = (cfg: Config) => {
  const site = String(cfg.site_url ?? "").replace(/\/$/, "");
  if (!/^https:\/\//.test(site) && !cfg.api_base) throw new Error("Jira: set the site address");
  return base(cfg, site);
};
const jira: ChannelAdapter = {
  kind: "jira",
  maxText: 30_000,
  async downloadFile(cfg, s, where, f) {
    return bytesOf(
      await f(
        `${jiraSite(cfg)}/rest/api/3/attachment/content/${encodeURIComponent(String(where.id))}`,
        {
          headers: { authorization: jiraAuth(cfg, s) },
        },
      ),
      "Jira",
    );
  },
  // Attached to the issue (the site's own size limit applies; a refusal becomes a link).
  fileFits: () => true,
  async sendFile(cfg, s, reply, file, f) {
    if (file.caption) await this.send(cfg, s, reply, file.caption, f);
    const form = new FormData();
    form.set("file", blobOf(file), file.name);
    await ok(
      await f(
        `${jiraSite(cfg)}/rest/api/3/issue/${encodeURIComponent(String(reply.issue_key))}/attachments`,
        {
          method: "POST",
          headers: { authorization: jiraAuth(cfg, s), "X-Atlassian-Token": "no-check" },
          body: form,
        },
      ),
      "Jira",
    );
  },
  verify(req, _c, s) {
    if (!s.webhook_secret) return false;
    const want = `sha256=${createHmac("sha256", s.webhook_secret).update(req.body).digest("hex")}`;
    return same(h(req, "x-hub-signature"), want);
  },
  normalize(req, cfg) {
    const b = json(req.body);
    const issue = (b.issue ?? {}) as Record<string, unknown>;
    const fields = (issue.fields ?? {}) as Record<string, unknown>;
    const me = String(cfg.assignee_account_id ?? "");
    const user = (b.user ??
      (b.comment as Record<string, unknown> | undefined)?.author ??
      {}) as Record<string, unknown>;
    if (!me || user.accountId === me || !issue.id) return [];
    const assignee = (fields.assignee as Record<string, unknown> | undefined)?.accountId;
    if (b.webhookEvent === "jira:issue_created" || b.webhookEvent === "jira:issue_updated") {
      const items = ((b.changelog as Record<string, unknown> | undefined)?.items ?? []) as Array<
        Record<string, unknown>
      >;
      const assignedNow =
        assignee === me &&
        (b.webhookEvent === "jira:issue_created" ||
          items.some((i) => i.field === "assignee" && i.to === me));
      if (!assignedNow) return [];
      return [
        {
          messageId: `${issue.id}:assigned:${b.timestamp ?? ""}`,
          threadKey: `jira:${issue.id}`,
          sender: String(user.accountId ?? ""),
          senderName: user.displayName as string | undefined,
          subject: `${issue.key ?? ""} ${fields.summary ?? ""}`.trim(),
          text: `You were assigned the Jira issue ${issue.key ?? ""}: ${fields.summary ?? ""}\n\n${adfText(fields.description).trim()}\n\nDo the work, then reply with what you did; your reply is posted as a comment on the issue.`.trim(),
          reply: { issue_key: issue.key },
          // The issue's attachments come along (D-342).
          ...(() => {
            const files: InFile[] = ((fields.attachment ?? []) as Array<Record<string, unknown>>)
              .filter((a) => a.id)
              .slice(0, 10)
              .map((a) => ({
                name: a.filename as string | undefined,
                mime: a.mimeType as string | undefined,
                size: Number(a.size ?? 0) || undefined,
                fetch: { id: a.id },
              }));
            return files.length ? { files } : {};
          })(),
        },
      ];
    }
    if (b.webhookEvent === "comment_created" && assignee === me) {
      const comment = (b.comment ?? {}) as Record<string, unknown>;
      const text = adfText(comment.body).trim();
      if (!text) return [];
      return [
        {
          messageId: String(comment.id ?? "") || undefined,
          threadKey: `jira:${issue.id}`,
          sender: String(user.accountId ?? ""),
          senderName: user.displayName as string | undefined,
          text,
          reply: { issue_key: issue.key },
        },
      ];
    }
    return [];
  },
  async send(cfg, s, reply, text, f) {
    const site = String(cfg.site_url ?? "").replace(/\/$/, "");
    if (!/^https:\/\//.test(site) && !cfg.api_base) throw new Error("Jira: set the site address");
    await ok(
      await f(
        `${base(cfg, site)}/rest/api/3/issue/${encodeURIComponent(String(reply.issue_key))}/comment`,
        {
          method: "POST",
          headers: {
            "content-type": "application/json",
            authorization: `Basic ${Buffer.from(`${cfg.email}:${s.api_token}`).toString("base64")}`,
          },
          body: JSON.stringify({
            body: toAdf(text),
          }),
        },
      ),
      "Jira",
    );
  },
};

export const ADAPTERS: Record<ChannelKind, ChannelAdapter> = {
  telegram,
  email,
  sms,
  slack,
  whatsapp,
  messenger,
  feishu,
  imessage,
  teams,
  discord,
  linear,
  jira,
};

/** Whether a sender may talk to the bot (exact match, case-insensitive; "*@domain" for email). */
export function senderAllowed(allowed: string[], sender: string) {
  const s = sender.toLowerCase();
  return allowed.some((a) => {
    const x = a.trim().toLowerCase();
    return x === s || (x.startsWith("*@") && s.endsWith(x.slice(1)));
  });
}

export const previewOf = (text: string) => plain(text).slice(0, 200);
