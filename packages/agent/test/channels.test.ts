/** Chat apps (D-134): every adapter checks signatures, reads its provider's payload and sends replies. */
import { createHash, createHmac } from "node:crypto";
import { describe, expect, it } from "vitest";
import { ADAPTERS, messageMatches, senderAllowed, twilioSignature, type WebhookRequest } from "../src/channels/index.ts";

const now = () => String(Math.floor(Date.now() / 1000));
const req = (body: string, headers: Record<string, string> = {}, method = "POST", url = "https://api.example.com/hooks/channels/x"): WebhookRequest => ({
  method,
  url,
  headers: Object.fromEntries(Object.entries(headers).map(([k, v]) => [k.toLowerCase(), v])),
  body,
});
function recorder() {
  const calls: Array<{ url: string; init: RequestInit; body: string }> = [];
  const f = (async (url: string, init: RequestInit = {}) => {
    calls.push({ url, init, body: String(init.body ?? "") });
    return new Response(JSON.stringify({ ok: true, tenant_access_token: "t-1" }), { status: 200, headers: { "content-type": "application/json" } });
  }) as unknown as typeof fetch;
  return { calls, f };
}

describe("chat app adapters", () => {
  it("Telegram: secret header, text messages, sendMessage", async () => {
    const a = ADAPTERS.telegram;
    const body = JSON.stringify({ message: { text: "hi", chat: { id: 42 }, from: { id: 7, first_name: "Ana" } } });
    expect(a.verify(req(body, { "X-Telegram-Bot-Api-Secret-Token": "s3cret" }), {}, { webhook_secret: "s3cret" })).toBe(true);
    expect(a.verify(req(body, { "X-Telegram-Bot-Api-Secret-Token": "nope" }), {}, { webhook_secret: "s3cret" })).toBe(false);
    expect(a.normalize(req(body), {})).toEqual([{ threadKey: "chat:42", sender: "7", senderName: "Ana", text: "hi", reply: { chat_id: 42 } }]);
    const { calls, f } = recorder();
    await a.send({ api_base: "http://tg.test" }, { bot_token: "123:abc" }, { chat_id: 42 }, "hello", f);
    expect(calls[0]?.url).toBe("http://tg.test/bot123:abc/sendMessage");
    expect(JSON.parse(calls[0]!.body)).toEqual({ chat_id: 42, text: "hello" });
  });

  it("Email: Svix-style signature, thread by sender and subject, Re: replies", async () => {
    const a = ADAPTERS.email;
    const secret = `whsec_${Buffer.from("key-bytes").toString("base64")}`;
    const body = JSON.stringify({ type: "email.received", data: { from: "Lee <Lee@Vendor.com>", subject: "Invoice 12", text: "Attached.", message_id: "<m1@vendor>" } });
    const ts = now();
    const sig = createHmac("sha256", Buffer.from("key-bytes")).update(`msg_1.${ts}.${body}`).digest("base64");
    expect(a.verify(req(body, { "svix-id": "msg_1", "svix-timestamp": ts, "svix-signature": `v1,${sig}` }), {}, { signing_secret: secret })).toBe(true);
    expect(a.verify(req(body, { "svix-id": "msg_1", "svix-timestamp": "1000", "svix-signature": `v1,${sig}` }), {}, { signing_secret: secret })).toBe(false);
    const [m] = a.normalize(req(body), {});
    expect(m).toMatchObject({ threadKey: "lee@vendor.com|invoice 12", sender: "lee@vendor.com", subject: "Invoice 12", reply: { to: "lee@vendor.com", subject: "Re: Invoice 12", in_reply_to: "<m1@vendor>" } });
    const reply = a.normalize(req(JSON.stringify({ type: "email.received", data: { from: "lee@vendor.com", subject: "RE: Invoice 12", text: "More" } })), {})[0];
    expect(reply?.threadKey).toBe(m?.threadKey);
    const { calls, f } = recorder();
    await a.send({ address: "bot@kasama.test", api_base: "http://resend.test" }, { api_key: "re_1" }, m!.reply, "Thanks", f);
    expect(calls[0]?.url).toBe("http://resend.test/emails");
    expect(JSON.parse(calls[0]!.body)).toMatchObject({ from: "bot@kasama.test", to: ["lee@vendor.com"], subject: "Re: Invoice 12", headers: { "In-Reply-To": "<m1@vendor>" } });
  });

  it("SMS: Twilio signature over the URL and sorted params", async () => {
    const a = ADAPTERS.sms;
    const body = new URLSearchParams({ From: "+15550001", Body: "hey", To: "+15559999" }).toString();
    const url = "https://api.example.com/hooks/channels/x";
    const sig = twilioSignature(url, { Body: "hey", From: "+15550001", To: "+15559999" }, "tok");
    expect(a.verify(req(body, { "X-Twilio-Signature": sig }, "POST", url), {}, { auth_token: "tok" })).toBe(true);
    expect(a.verify(req(body, { "X-Twilio-Signature": sig }, "POST", `${url}?x=1`), {}, { auth_token: "tok" })).toBe(false);
    expect(a.normalize(req(body), {})).toEqual([{ threadKey: "sms:+15550001", sender: "+15550001", text: "hey", reply: { to: "+15550001" } }]);
    const { calls, f } = recorder();
    await a.send({ phone_number: "+15559999", api_base: "http://tw.test" }, { account_sid: "AC1", auth_token: "tok" }, { to: "+15550001" }, "yo", f);
    expect(calls[0]?.url).toBe("http://tw.test/2010-04-01/Accounts/AC1/Messages.json");
    expect(calls[0]?.body).toBe("To=%2B15550001&From=%2B15559999&Body=yo");
  });

  it("Slack: URL verification, v0 signature, threads, ignores bots", async () => {
    const a = ADAPTERS.slack;
    expect(a.handshake?.(req(JSON.stringify({ type: "url_verification", challenge: "abc" })), {}, {})).toEqual({ status: 200, body: "abc", type: "text/plain" });
    const body = JSON.stringify({ type: "event_callback", event: { type: "message", user: "U1", text: "hi", channel: "C1", ts: "1.1" } });
    const ts = now();
    const sig = `v0=${createHmac("sha256", "ss").update(`v0:${ts}:${body}`).digest("hex")}`;
    expect(a.verify(req(body, { "x-slack-request-timestamp": ts, "x-slack-signature": sig }), {}, { signing_secret: "ss" })).toBe(true);
    expect(a.verify(req(body, { "x-slack-request-timestamp": ts, "x-slack-signature": "v0=bad" }), {}, { signing_secret: "ss" })).toBe(false);
    expect(a.normalize(req(body), {})).toEqual([{ threadKey: "C1:1.1", sender: "U1", text: "hi", reply: { channel: "C1", thread_ts: "1.1" } }]);
    expect(a.normalize(req(JSON.stringify({ type: "event_callback", event: { type: "message", bot_id: "B1", text: "echo", channel: "C1", ts: "2" } })), {})).toEqual([]);
    const { calls, f } = recorder();
    await a.send({ api_base: "http://slack.test" }, { bot_token: "xoxb" }, { channel: "C1", thread_ts: "1.1" }, "ok", f);
    expect(calls[0]?.url).toBe("http://slack.test/api/chat.postMessage");
  });

  it("WhatsApp and Messenger: hub challenge, X-Hub-Signature-256, payloads", async () => {
    const wa = ADAPTERS.whatsapp;
    const hs = wa.handshake?.(req("", {}, "GET", "https://x/hooks?hub.mode=subscribe&hub.verify_token=vt&hub.challenge=99"), {}, { verify_token: "vt" });
    expect(hs).toEqual({ status: 200, body: "99", type: "text/plain" });
    expect(wa.handshake?.(req("", {}, "GET", "https://x/hooks?hub.mode=subscribe&hub.verify_token=no&hub.challenge=99"), {}, { verify_token: "vt" })?.status).toBe(403);
    const body = JSON.stringify({
      entry: [{ changes: [{ value: { contacts: [{ wa_id: "15550001", profile: { name: "Ana" } }], messages: [{ from: "15550001", type: "text", text: { body: "hola" } }] } }] }],
    });
    const sig = `sha256=${createHmac("sha256", "as").update(body).digest("hex")}`;
    expect(wa.verify(req(body, { "x-hub-signature-256": sig }), {}, { app_secret: "as" })).toBe(true);
    expect(wa.verify(req(body, { "x-hub-signature-256": "sha256=00" }), {}, { app_secret: "as" })).toBe(false);
    expect(wa.normalize(req(body), {})).toEqual([{ threadKey: "wa:15550001", sender: "15550001", senderName: "Ana", text: "hola", reply: { to: "15550001" } }]);
    const { calls, f } = recorder();
    await wa.send({ phone_number_id: "PN", api_base: "http://graph.test" }, { access_token: "EA" }, { to: "15550001" }, "hi", f);
    expect(calls[0]?.url).toBe("http://graph.test/v20.0/PN/messages");

    const fb = ADAPTERS.messenger;
    const fbBody = JSON.stringify({ entry: [{ messaging: [{ sender: { id: "PSID" }, message: { text: "yo" } }, { sender: { id: "PAGE" }, message: { text: "echo", is_echo: true } }] }] });
    expect(fb.normalize(req(fbBody), {})).toEqual([{ threadKey: "fb:PSID", sender: "PSID", text: "yo", reply: { recipient: "PSID" } }]);
    await fb.send({ api_base: "http://graph.test" }, { page_token: "PT" }, { recipient: "PSID" }, "hi", f);
    expect(calls[1]?.url).toBe("http://graph.test/v20.0/me/messages?access_token=PT");
  });

  it("Feishu: url_verification token, lark signature, tenant token then send", async () => {
    const a = ADAPTERS.feishu;
    expect(a.handshake?.(req(JSON.stringify({ type: "url_verification", token: "vt", challenge: "c1" })), {}, { verification_token: "vt" })?.body).toBe('{"challenge":"c1"}');
    expect(a.handshake?.(req(JSON.stringify({ type: "url_verification", token: "x", challenge: "c1" })), {}, { verification_token: "vt" })?.status).toBe(403);
    const body = JSON.stringify({
      header: { event_type: "im.message.receive_v1" },
      event: { sender: { sender_id: { open_id: "ou_1" } }, message: { chat_id: "oc_1", message_type: "text", content: JSON.stringify({ text: "@_user_1 hello" }) } },
    });
    const ts = now();
    const sig = createHash("sha256").update(`${ts}n1ek${body}`).digest("hex");
    expect(a.verify(req(body, { "x-lark-request-timestamp": ts, "x-lark-request-nonce": "n1", "x-lark-signature": sig }), {}, { encrypt_key: "ek" })).toBe(true);
    expect(a.normalize(req(body), {})).toEqual([{ threadKey: "chat:oc_1", sender: "ou_1", text: "hello", reply: { chat_id: "oc_1" } }]);
    const { calls, f } = recorder();
    await a.send({ app_id: "cli", api_base: "http://lark.test" }, { app_secret: "as" }, { chat_id: "oc_1" }, "hi", f);
    expect(calls.map((c) => c.url)).toEqual(["http://lark.test/open-apis/auth/v3/tenant_access_token/internal", "http://lark.test/open-apis/im/v1/messages?receive_id_type=chat_id"]);
    expect((calls[1]?.init.headers as Record<string, string>).authorization).toBe("Bearer t-1");
  });

  it("iMessage never accepts webhooks and sends through the Mac", async () => {
    const a = ADAPTERS.imessage;
    expect(a.verify(req("{}"), {}, {})).toBe(false);
    const { calls, f } = recorder();
    await a.send({ tunnel_url: "http://api.test/internal/local/c1/http" }, { internal_token: "it" }, { to: "+15550001" }, "hi", f);
    expect(calls[0]?.url).toBe("http://api.test/internal/local/c1/http/imessage/send");
  });

  it("allowlists and routine filters", () => {
    expect(senderAllowed(["*@example.com"], "Ana@Example.com")).toBe(true);
    expect(senderAllowed(["*@example.com"], "ana@example.com.evil")).toBe(false);
    expect(senderAllowed(["+15550001"], "+15550002")).toBe(false);
    const m = { threadKey: "t", sender: "lee@vendor.com", subject: "Invoice 12", text: "Attached", reply: {} };
    const c = { id: "c1", kind: "email" as const };
    expect(messageMatches({ type: "message", channel_kind: "email", sender: "*@vendor.com", subject_match: "invoice" }, c, m)).toBe(true);
    expect(messageMatches({ type: "message", subject_match: "receipt" }, c, m)).toBe(false);
    expect(messageMatches({ type: "message", channel_kind: "sms" }, c, m)).toBe(false);
  });
});
