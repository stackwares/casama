/** Chat apps on real traffic (D-270): repeats, Feishu encryption, email bodies, long replies, attachments. */
import { createCipheriv, createHash, randomBytes } from "node:crypto";
import { describe, expect, it } from "vitest";
import {
  ADAPTERS,
  ATTACHMENT_NOTE,
  feishuDecrypt,
  splitText,
  type WebhookRequest,
} from "../src/channels/index.ts";

const req = (body: string): WebhookRequest => ({
  method: "POST",
  url: "https://api.example.com/hooks/channels/x",
  headers: {},
  body,
});

describe("chat apps on real traffic (D-270)", () => {
  it("every adapter gives each message the provider's id, so a repeat can be skipped", () => {
    expect(
      ADAPTERS.telegram.normalize(
        req(
          JSON.stringify({
            update_id: 77,
            message: { text: "hi", chat: { id: 1 }, from: { id: 2 } },
          }),
        ),
        {},
      )[0]?.messageId,
    ).toBe("u77");
    expect(
      ADAPTERS.slack.normalize(
        req(
          JSON.stringify({
            type: "event_callback",
            event_id: "Ev1",
            event: { type: "message", text: "hi", user: "U1", channel: "C1", ts: "1.2" },
          }),
        ),
        {},
      )[0]?.messageId,
    ).toBe("C1:1.2");
    expect(
      ADAPTERS.sms.normalize(req("From=%2B1555&Body=hi&MessageSid=SM9"), {})[0]?.messageId,
    ).toBe("SM9");
  });

  it("Feishu: an encrypted body is decrypted before it's read", () => {
    const key = "feishu-encrypt-key";
    const plain = JSON.stringify({
      header: { event_type: "im.message.receive_v1", event_id: "e-1" },
      event: {
        sender: { sender_id: { open_id: "ou_1" } },
        message: {
          chat_id: "oc_1",
          message_type: "text",
          content: JSON.stringify({ text: "hello" }),
        },
      },
    });
    const iv = randomBytes(16);
    const c = createCipheriv("aes-256-cbc", createHash("sha256").update(key).digest(), iv);
    const encrypt = Buffer.concat([iv, c.update(plain, "utf8"), c.final()]).toString("base64");
    expect(feishuDecrypt(encrypt, key)).toBe(plain);
    const a = ADAPTERS.feishu;
    const decoded = a.decode?.(req(JSON.stringify({ encrypt })), {}, { encrypt_key: key });
    expect(a.normalize(decoded as WebhookRequest, {})).toEqual([
      {
        messageId: "e-1",
        threadKey: "chat:oc_1",
        sender: "ou_1",
        text: "hello",
        reply: { chat_id: "oc_1" },
      },
    ]);
  });

  it("Email: a webhook without the body fetches it before the bot sees the message", async () => {
    const a = ADAPTERS.email;
    const msgs = a.normalize(
      req(
        JSON.stringify({
          type: "email.received",
          data: { email_id: "em_1", from: "Lee <lee@vendor.com>", subject: "Invoice" },
        }),
      ),
      {},
    );
    expect(msgs[0]).toMatchObject({ fetchId: "em_1", text: "" });
    const asked: string[] = [];
    const f = (async (url: string) => {
      asked.push(url);
      return new Response(JSON.stringify({ html: "<p>Please pay&nbsp;by Friday.</p>" }), {
        status: 200,
      });
    }) as unknown as typeof fetch;
    const out = await a.enrich?.(msgs, { api_base: "http://resend.test" }, { api_key: "re_1" }, f);
    expect(asked).toEqual(["http://resend.test/emails/receiving/em_1"]);
    expect(out?.[0]?.text).toBe("Please pay by Friday.");
    expect(out?.[0]).not.toHaveProperty("fetchId");
  });

  it("long replies are split at natural breaks, never cut off", () => {
    const para = "word ".repeat(300).trim();
    const text = `${para}\n\n${para}\n\n${para}`;
    const parts = splitText(text, 2000);
    expect(parts.length).toBeGreaterThan(1);
    for (const p of parts) expect(p.length).toBeLessThanOrEqual(2000);
    expect(parts.join(" ").replace(/\s+/g, " ")).toBe(text.replace(/\s+/g, " "));
    expect(splitText("short", 2000)).toEqual(["short"]);
  });

  it("a photo or file gets a note instead of being dropped", () => {
    const tg = ADAPTERS.telegram.normalize(
      req(
        JSON.stringify({
          update_id: 1,
          message: { photo: [{ file_id: "f" }], caption: "look", chat: { id: 1 }, from: { id: 2 } },
        }),
      ),
      {},
    );
    expect(tg[0]?.text).toBe(`look\n${ATTACHMENT_NOTE}`);
    const wa = ADAPTERS.whatsapp.normalize(
      req(
        JSON.stringify({
          entry: [
            {
              changes: [
                { value: { messages: [{ id: "w1", from: "1555", type: "image", image: {} }] } },
              ],
            },
          ],
        }),
      ),
      {},
    );
    expect(wa[0]?.text).toBe(ATTACHMENT_NOTE);
  });
});

describe("Slack as a place to work (D-277)", () => {
  it("hears @mentions without the mention, and reads Approve and Deny presses", () => {
    const [m] = ADAPTERS.slack.normalize(
      req(
        JSON.stringify({
          type: "event_callback",
          event: {
            type: "app_mention",
            text: "<@UBOT>  draft the memo",
            user: "U1",
            channel: "C9",
            ts: "5.5",
          },
        }),
      ),
      {},
    );
    expect(m).toMatchObject({
      text: "draft the memo",
      messageId: "C9:5.5",
      reply: { channel: "C9", thread_ts: "5.5", ts: "5.5" },
    });
    const id = "11111111-2222-3333-4444-555555555555";
    const body = `payload=${encodeURIComponent(JSON.stringify({ type: "block_actions", user: { id: "U1" }, actions: [{ value: `deny:${id}` }], response_url: "https://hooks.slack.test/r" }))}`;
    expect(ADAPTERS.slack.parseAction?.(req(body))).toEqual({
      approvalId: id,
      decision: "denied",
      sender: "U1",
      responseUrl: "https://hooks.slack.test/r",
    });
    expect(ADAPTERS.slack.parseAction?.(req("payload=%7B%7D"))).toBeNull();
  });
});
