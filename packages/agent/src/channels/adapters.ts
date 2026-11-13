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
}

/** A person pressing Approve or Deny on an approval posted into a chat app (D-277). */
export interface ChannelAction {
  approvalId: string;
  decision: "approved" | "denied";
  sender: string;
  /** Where to replace the buttons with the outcome (Slack's response_url). */
  responseUrl?: string;
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
  send(
    cfg: Config,
    secrets: Secrets,
    reply: Record<string, unknown>,
    text: string,
    f: typeof fetch,
  ): Promise<void>;
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

/** Said in place of a photo, file or voice note the bot can't receive from this app yet. */
export const ATTACHMENT_NOTE =
  "[They sent an attachment (a photo, file or voice note). It doesn't come through from this app yet: ask them to describe it or send it in the Casama app.]";

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
    const text =
      typeof m.text === "string"
        ? m.text
        : [
            m.caption,
            hasAny(m, ["photo", "document", "voice", "audio", "video", "sticker"])
              ? ATTACHMENT_NOTE
              : "",
          ]
            .filter((x) => typeof x === "string" && x)
            .join("\n");
    if (!text) return [];
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
      },
    ];
  },
  async send(cfg, s, reply, text, f) {
    await ok(
      await f(`${base(cfg, "https://api.telegram.org")}/bot${s.bot_token}/sendMessage`, {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ chat_id: reply.chat_id, text }),
      }),
      "Telegram",
    );
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
  verify: (req, _c, s) => !!s.signing_secret && svixValid(req, s.signing_secret),
  async enrich(messages, cfg, s, f) {
    const out: InboundMessage[] = [];
    for (const m of messages) {
      if (!m.fetchId) {
        out.push(m);
        continue;
      }
      // Resend's received-email API (written from its docs; checked only against a mock).
      const res = await f(
        `${base(cfg, "https://api.resend.com")}/emails/receiving/${encodeURIComponent(m.fetchId)}`,
        { headers: { authorization: `Bearer ${s.api_key}` } },
      ).catch(() => null);
      const body = res?.ok ? ((await res.json().catch(() => ({}))) as Record<string, unknown>) : {};
      const text =
        String(body.text ?? "").trim() ||
        htmlText(String(body.html ?? "")) ||
        ((body.attachments as unknown[] | undefined)?.length ? ATTACHMENT_NOTE : "");
      if (!text) continue;
      const { fetchId: _f, ...rest } = m;
      out.push({ ...rest, text });
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
    // Resend's inbound webhook carries only the envelope; the body is fetched in enrich (D-270).
    const fetchId = String(d.email_id ?? d.id ?? "") || undefined;
    if (!from || (!text && !fetchId)) return [];
    const headers = (d.headers ?? {}) as Record<string, unknown>;
    const messageId =
      String(d.message_id ?? headers["message-id"] ?? headers["Message-ID"] ?? "") || undefined;
    return [
      {
        messageId: messageId ?? fetchId,
        ...(text ? {} : { fetchId }),
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
          text,
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
    const text = p.Body || (Number(p.NumMedia ?? 0) > 0 ? ATTACHMENT_NOTE : "");
    if (!p.From || !text) return [];
    return [
      {
        messageId: p.MessageSid || p.SmsSid || undefined,
        threadKey: `sms:${p.From}`,
        sender: p.From,
        text,
        reply: { to: p.From },
      },
    ];
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
            Body: text,
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
    const files = Array.isArray(e?.files) && (e?.files as unknown[]).length > 0;
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
    const said = typeof e.text === "string" ? e.text.replace(/<@[A-Z0-9]+>\s*/g, "").trim() : "";
    const text = [said, files ? ATTACHMENT_NOTE : ""].filter(Boolean).join("\n");
    if (!text) return [];
    return [
      {
        // The same message can come as both "message" and "app_mention": one id for both.
        messageId: e.ts ? `${e.channel}:${e.ts}` : String(b.event_id ?? "") || undefined,
        threadKey: `${e.channel}:${thread}`,
        sender: String(e.user),
        text,
        reply: { channel: e.channel, thread_ts: thread, ts: e.ts },
      },
    ];
  },
  async send(cfg, s, reply, text, f) {
    const res = await ok(
      await f(`${base(cfg, "https://slack.com")}/api/chat.postMessage`, {
        method: "POST",
        headers: {
          "content-type": "application/json; charset=utf-8",
          authorization: `Bearer ${s.bot_token}`,
        },
        body: JSON.stringify({ channel: reply.channel, thread_ts: reply.thread_ts, text }),
      }),
      "Slack",
    );
    const r = (await res.json()) as { ok?: boolean; error?: string };
    if (r.ok === false) throw new Error(`Slack: ${r.error}`);
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
const whatsapp: ChannelAdapter = {
  kind: "whatsapp",
  maxText: 4096,
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
          const caption = (m[String(m.type)] as Record<string, unknown> | undefined)?.caption;
          const text =
            m.type === "text" && typeof body === "string"
              ? body
              : media
                ? [typeof caption === "string" ? caption : "", ATTACHMENT_NOTE]
                    .filter(Boolean)
                    .join("\n")
                : "";
          if (!text) continue;
          out.push({
            messageId: m.id ? String(m.id) : undefined,
            threadKey: `wa:${m.from}`,
            sender: String(m.from),
            senderName: names.get(String(m.from)),
            text,
            reply: { to: m.from },
          });
        }
      }
    return out;
  },
  async send(cfg, s, reply, text, f) {
    await ok(
      await f(`${base(cfg, "https://graph.facebook.com")}/v20.0/${cfg.phone_number_id}/messages`, {
        method: "POST",
        headers: { "content-type": "application/json", authorization: `Bearer ${s.access_token}` },
        body: JSON.stringify({
          messaging_product: "whatsapp",
          to: reply.to,
          type: "text",
          text: { body: text },
        }),
      }),
      "WhatsApp",
    );
  },
};
const messenger: ChannelAdapter = {
  kind: "messenger",
  maxText: 2000,
  handshake: metaHandshake,
  verify: metaVerify,
  normalize(req) {
    const out: InboundMessage[] = [];
    for (const entry of (json(req.body).entry ?? []) as Array<Record<string, unknown>>)
      for (const m of (entry.messaging ?? []) as Array<Record<string, unknown>>) {
        const msg = m.message as Record<string, unknown> | undefined;
        const sender = (m.sender as Record<string, unknown> | undefined)?.id;
        const attached =
          Array.isArray(msg?.attachments) && (msg?.attachments as unknown[]).length > 0;
        if (!msg || msg.is_echo || !sender || (typeof msg.text !== "string" && !attached)) continue;
        out.push({
          messageId: msg.mid ? String(msg.mid) : undefined,
          threadKey: `fb:${sender}`,
          sender: String(sender),
          text: typeof msg.text === "string" ? msg.text : ATTACHMENT_NOTE,
          reply: { recipient: sender },
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
            message: { text },
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
    const text =
      msg.message_type === "text"
        ? String(json(String(msg.content ?? "{}")).text ?? "")
            .replace(/@_user_\d+\s*/g, "")
            .trim()
        : ["image", "file", "audio", "media", "sticker"].includes(String(msg.message_type))
          ? ATTACHMENT_NOTE
          : "";
    if (!text) return [];
    return [
      {
        messageId: String(header?.event_id ?? msg.message_id ?? "") || undefined,
        threadKey: `chat:${msg.chat_id}`,
        sender: String(sender),
        text,
        reply: { chat_id: msg.chat_id },
      },
    ];
  },
  async send(cfg, s, reply, text, f) {
    const b = base(cfg, "https://open.feishu.cn");
    const tok = (await (
      await ok(
        await f(`${b}/open-apis/auth/v3/tenant_access_token/internal`, {
          method: "POST",
          headers: { "content-type": "application/json" },
          body: JSON.stringify({ app_id: cfg.app_id, app_secret: s.app_secret }),
        }),
        "Feishu",
      )
    ).json()) as { tenant_access_token?: string };
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
          content: JSON.stringify({ text }),
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
        body: JSON.stringify({ to: reply.to, text }),
      }),
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
    const text = String(options.find((o) => typeof o.value === "string")?.value ?? "").trim();
    const user = ((b.member as Record<string, unknown> | undefined)?.user ?? b.user) as
      | Record<string, unknown>
      | undefined;
    if (!text || !user?.id) return [];
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
      },
    ];
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
    if (a.type !== "message" || typeof a.text !== "string") return [];
    const from = (a.from ?? {}) as Record<string, unknown>;
    const conv = (a.conversation ?? {}) as Record<string, unknown>;
    const text = a.text
      .replace(/<at>[^<]*<\/at>\s*/g, "")
      .replace(/<[^>]+>/g, "")
      .trim();
    if (!text || !conv.id) return [];
    return [
      {
        messageId: a.id ? String(a.id) : undefined,
        threadKey: `teams:${conv.id}`,
        sender: String(from.aadObjectId ?? from.id ?? ""),
        senderName: from.name as string | undefined,
        text,
        reply: { service_url: a.serviceUrl, conversation_id: conv.id, activity_id: a.id },
      },
    ];
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
const linear: ChannelAdapter = {
  kind: "linear",
  maxText: 50_000,
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
const jira: ChannelAdapter = {
  kind: "jira",
  maxText: 30_000,
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
            body: {
              type: "doc",
              version: 1,
              content: text
                .split(/\n{2,}/)
                .map((p) => ({
                  type: "paragraph",
                  content: p.trim() ? [{ type: "text", text: p }] : [],
                })),
            },
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
