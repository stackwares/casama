/**
 * Chat apps (SPEC: Channels; D-134). Every adapter checks the provider's webhook signature,
 * turns its payload into standard messages, and sends replies. Provider addresses can be pointed
 * elsewhere with `config.api_base` (tests, proxies, regional endpoints).
 */
import { createHash, createHmac, timingSafeEqual } from "node:crypto";

export type ChannelKind = "telegram" | "email" | "sms" | "slack" | "whatsapp" | "messenger" | "feishu" | "imessage";

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
}

export type Config = Record<string, unknown>;
export type Secrets = Record<string, string>;

export interface ChannelAdapter {
  kind: ChannelKind;
  /** Answers the provider's setup handshake (URL verification), when this request is one. */
  handshake?(req: WebhookRequest, cfg: Config, secrets: Secrets): { status: number; body: string; type: string } | null;
  verify(req: WebhookRequest, cfg: Config, secrets: Secrets): boolean;
  normalize(req: WebhookRequest, cfg: Config): InboundMessage[];
  send(cfg: Config, secrets: Secrets, reply: Record<string, unknown>, text: string, f: typeof fetch): Promise<void>;
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
  if (!res.ok) throw new Error(`${what} answered ${res.status}: ${(await res.text()).slice(0, 200)}`);
  return res;
}
const plain = (s: string) => s.replace(/\s+/g, " ").trim();

// ------------------------------------------------------------------ Telegram (Bot API)
const telegram: ChannelAdapter = {
  kind: "telegram",
  verify: (req, _c, s) => !!s.webhook_secret && same(h(req, "x-telegram-bot-api-secret-token"), s.webhook_secret),
  normalize(req) {
    const u = json(req.body);
    const m = (u.message ?? u.edited_message) as Record<string, unknown> | undefined;
    const chat = m?.chat as Record<string, unknown> | undefined;
    const from = m?.from as Record<string, unknown> | undefined;
    if (!m || typeof m.text !== "string" || !chat || from?.is_bot) return [];
    return [
      {
        threadKey: `chat:${chat.id}`,
        sender: String(from?.id ?? chat.id),
        senderName: [from?.first_name, from?.last_name].filter(Boolean).join(" ") || (from?.username as string | undefined),
        text: m.text,
        reply: { chat_id: chat.id },
      },
    ];
  },
  async send(cfg, s, reply, text, f) {
    await ok(
      await f(`${base(cfg, "https://api.telegram.org")}/bot${s.bot_token}/sendMessage`, {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ chat_id: reply.chat_id, text: text.slice(0, 4096) }),
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
const email: ChannelAdapter = {
  kind: "email",
  verify: (req, _c, s) => !!s.signing_secret && svixValid(req, s.signing_secret),
  normalize(req) {
    const e = json(req.body);
    const d = (e.data ?? e) as Record<string, unknown>;
    if (e.type && e.type !== "email.received") return [];
    const from = addr(d.from);
    const subject = String(d.subject ?? "");
    const text = String(d.text ?? d.plain ?? "").trim() || String(d.html ?? "").replace(/<[^>]+>/g, " ").trim();
    if (!from || !text) return [];
    const headers = (d.headers ?? {}) as Record<string, unknown>;
    const messageId = String(d.message_id ?? headers["message-id"] ?? headers["Message-ID"] ?? "") || undefined;
    return [
      {
        threadKey: `${from}|${baseSubject(subject).toLowerCase()}`,
        sender: from,
        subject,
        text,
        reply: { to: from, subject: subject && /^re:/i.test(subject) ? subject : `Re: ${subject || "your message"}`, in_reply_to: messageId },
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
          ...(reply.in_reply_to ? { headers: { "In-Reply-To": reply.in_reply_to, References: reply.in_reply_to } } : {}),
        }),
      }),
      "Resend",
    );
  },
};

// ------------------------------------------------------------------ SMS (Twilio)
const form = (s: string) => Object.fromEntries(new URLSearchParams(s));
export function twilioSignature(url: string, params: Record<string, string>, token: string) {
  const data = url + Object.keys(params).sort().map((k) => k + params[k]).join("");
  return createHmac("sha1", token).update(data).digest("base64");
}
const sms: ChannelAdapter = {
  kind: "sms",
  verify: (req, cfg, s) => !!s.auth_token && same(h(req, "x-twilio-signature"), twilioSignature(String(cfg.webhook_url ?? req.url), form(req.body), s.auth_token)),
  normalize(req) {
    const p = form(req.body);
    if (!p.From || !p.Body) return [];
    return [{ threadKey: `sms:${p.From}`, sender: p.From, text: p.Body, reply: { to: p.From } }];
  },
  async send(cfg, s, reply, text, f) {
    await ok(
      await f(`${base(cfg, "https://api.twilio.com")}/2010-04-01/Accounts/${s.account_sid}/Messages.json`, {
        method: "POST",
        headers: { "content-type": "application/x-www-form-urlencoded", authorization: `Basic ${Buffer.from(`${s.account_sid}:${s.auth_token}`).toString("base64")}` },
        body: new URLSearchParams({ To: String(reply.to), From: String(cfg.phone_number), Body: text.slice(0, 1600) }).toString(),
      }),
      "Twilio",
    );
  },
};

// ------------------------------------------------------------------ Slack (Events API, Web API)
const slack: ChannelAdapter = {
  kind: "slack",
  handshake(req) {
    const b = json(req.body);
    return b.type === "url_verification" ? { status: 200, body: String(b.challenge ?? ""), type: "text/plain" } : null;
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
    if (b.type !== "event_callback" || !e || e.type !== "message" || e.bot_id || e.subtype || typeof e.text !== "string") return [];
    const thread = String(e.thread_ts ?? e.ts);
    return [{ threadKey: `${e.channel}:${thread}`, sender: String(e.user), text: e.text, reply: { channel: e.channel, thread_ts: thread } }];
  },
  async send(cfg, s, reply, text, f) {
    const res = await ok(
      await f(`${base(cfg, "https://slack.com")}/api/chat.postMessage`, {
        method: "POST",
        headers: { "content-type": "application/json; charset=utf-8", authorization: `Bearer ${s.bot_token}` },
        body: JSON.stringify({ channel: reply.channel, thread_ts: reply.thread_ts, text }),
      }),
      "Slack",
    );
    const r = (await res.json()) as { ok?: boolean; error?: string };
    if (r.ok === false) throw new Error(`Slack: ${r.error}`);
  },
};

// ------------------------------------------------------------------ WhatsApp and Messenger (Meta)
const metaHandshake = (req: WebhookRequest, _c: Config, s: Secrets) => {
  if (req.method !== "GET") return null;
  const q = new URL(req.url).searchParams;
  return q.get("hub.mode") === "subscribe" && s.verify_token && q.get("hub.verify_token") === s.verify_token
    ? { status: 200, body: q.get("hub.challenge") ?? "", type: "text/plain" }
    : { status: 403, body: "", type: "text/plain" };
};
const metaVerify = (req: WebhookRequest, _c: Config, s: Secrets) =>
  !!s.app_secret && same(h(req, "x-hub-signature-256"), `sha256=${createHmac("sha256", s.app_secret).update(req.body).digest("hex")}`);
const whatsapp: ChannelAdapter = {
  kind: "whatsapp",
  handshake: metaHandshake,
  verify: metaVerify,
  normalize(req) {
    const out: InboundMessage[] = [];
    for (const entry of (json(req.body).entry ?? []) as Array<Record<string, unknown>>)
      for (const ch of (entry.changes ?? []) as Array<Record<string, unknown>>) {
        const v = (ch.value ?? {}) as Record<string, unknown>;
        const names = new Map(((v.contacts ?? []) as Array<Record<string, unknown>>).map((c) => [String(c.wa_id), String((c.profile as Record<string, unknown>)?.name ?? "")]));
        for (const m of (v.messages ?? []) as Array<Record<string, unknown>>) {
          const body = (m.text as Record<string, unknown> | undefined)?.body;
          if (m.type !== "text" || typeof body !== "string") continue;
          out.push({ threadKey: `wa:${m.from}`, sender: String(m.from), senderName: names.get(String(m.from)), text: body, reply: { to: m.from } });
        }
      }
    return out;
  },
  async send(cfg, s, reply, text, f) {
    await ok(
      await f(`${base(cfg, "https://graph.facebook.com")}/v20.0/${cfg.phone_number_id}/messages`, {
        method: "POST",
        headers: { "content-type": "application/json", authorization: `Bearer ${s.access_token}` },
        body: JSON.stringify({ messaging_product: "whatsapp", to: reply.to, type: "text", text: { body: text.slice(0, 4096) } }),
      }),
      "WhatsApp",
    );
  },
};
const messenger: ChannelAdapter = {
  kind: "messenger",
  handshake: metaHandshake,
  verify: metaVerify,
  normalize(req) {
    const out: InboundMessage[] = [];
    for (const entry of (json(req.body).entry ?? []) as Array<Record<string, unknown>>)
      for (const m of (entry.messaging ?? []) as Array<Record<string, unknown>>) {
        const msg = m.message as Record<string, unknown> | undefined;
        const sender = (m.sender as Record<string, unknown> | undefined)?.id;
        if (!msg || msg.is_echo || typeof msg.text !== "string" || !sender) continue;
        out.push({ threadKey: `fb:${sender}`, sender: String(sender), text: msg.text, reply: { recipient: sender } });
      }
    return out;
  },
  async send(cfg, s, reply, text, f) {
    await ok(
      await f(`${base(cfg, "https://graph.facebook.com")}/v20.0/me/messages?access_token=${encodeURIComponent(s.page_token ?? "")}`, {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ recipient: { id: reply.recipient }, messaging_type: "RESPONSE", message: { text: text.slice(0, 2000) } }),
      }),
      "Messenger",
    );
  },
};

// ------------------------------------------------------------------ Feishu (open platform events v2)
const feishu: ChannelAdapter = {
  kind: "feishu",
  handshake(req, _c, s) {
    const b = json(req.body);
    if (b.type !== "url_verification") return null;
    return b.token === s.verification_token ? { status: 200, body: JSON.stringify({ challenge: b.challenge }), type: "application/json" } : { status: 403, body: "", type: "text/plain" };
  },
  verify(req, _c, s) {
    const ts = h(req, "x-lark-request-timestamp");
    const nonce = h(req, "x-lark-request-nonce");
    if (!s.encrypt_key || !ts) return false;
    const want = createHash("sha256").update(ts + nonce + s.encrypt_key + req.body).digest("hex");
    return same(h(req, "x-lark-signature"), want);
  },
  normalize(req) {
    const b = json(req.body);
    const header = b.header as Record<string, unknown> | undefined;
    const ev = b.event as Record<string, unknown> | undefined;
    if (header?.event_type !== "im.message.receive_v1" || !ev) return [];
    const msg = ev.message as Record<string, unknown>;
    const sender = ((ev.sender as Record<string, unknown>)?.sender_id as Record<string, unknown>)?.open_id;
    if (msg?.message_type !== "text" || !sender) return [];
    const text = String(json(String(msg.content ?? "{}")).text ?? "").replace(/@_user_\d+\s*/g, "").trim();
    if (!text) return [];
    return [{ threadKey: `chat:${msg.chat_id}`, sender: String(sender), text, reply: { chat_id: msg.chat_id } }];
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
        headers: { "content-type": "application/json", authorization: `Bearer ${tok.tenant_access_token}` },
        body: JSON.stringify({ receive_id: reply.chat_id, msg_type: "text", content: JSON.stringify({ text }) }),
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
        headers: { "content-type": "application/json", "x-kasama-internal": s.internal_token ?? "" },
        body: JSON.stringify({ to: reply.to, text }),
      }),
      "The Mac",
    );
  },
};

export const ADAPTERS: Record<ChannelKind, ChannelAdapter> = { telegram, email, sms, slack, whatsapp, messenger, feishu, imessage };

/** Whether a sender may talk to the bot (exact match, case-insensitive; "*@domain" for email). */
export function senderAllowed(allowed: string[], sender: string) {
  const s = sender.toLowerCase();
  return allowed.some((a) => {
    const x = a.trim().toLowerCase();
    return x === s || (x.startsWith("*@") && s.endsWith(x.slice(1)));
  });
}

export const previewOf = (text: string) => plain(text).slice(0, 200);
