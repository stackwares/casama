/** Hosted bot mail: hook signing, MIME parsing, senders, and the email adapter's hosted bits. */
import { describe, expect, it } from "vitest";
import {
  ADAPTERS,
  CloudflareMailSender,
  cloudflareAuthResults,
  isAutomaticMail,
  messageMatches,
  parsedToInbound,
  parseMime,
  ResendMailSender,
  senderCheckFrom,
  signMailHook,
  verifyMailHook,
  type WebhookRequest,
} from "../src/channels/index.ts";

const req = (body: string, headers: Record<string, string> = {}): WebhookRequest => ({
  method: "POST",
  url: "https://api.example.com/hooks/channels/x",
  headers: Object.fromEntries(Object.entries(headers).map(([k, v]) => [k.toLowerCase(), v])),
  body,
});
function recorder(status = 200, json: unknown = { ok: true }) {
  const calls: Array<{ url: string; init: RequestInit; body: string }> = [];
  const f = (async (url: string, init: RequestInit = {}) => {
    calls.push({ url, init, body: String(init.body ?? "") });
    return new Response(JSON.stringify(json), {
      status,
      headers: { "content-type": "application/json" },
    });
  }) as unknown as typeof fetch;
  return { calls, f };
}

describe("mail hook signing", () => {
  it("signs and verifies timestamped bodies, and rejects skew", () => {
    const body = "raw mime";
    const at = String(Date.now());
    const sig = signMailHook("s3cret", at, body);
    expect(verifyMailHook("s3cret", at, sig, body)).toBe(true);
    expect(verifyMailHook("wrong", at, sig, body)).toBe(false);
    expect(verifyMailHook("s3cret", at, sig, "other")).toBe(false);
    expect(verifyMailHook("s3cret", String(Date.now() - 600_000), sig, body)).toBe(false);
  });
});

describe("MIME parsing", () => {
  const raw = [
    "From: Ana Example <ana@example.com>",
    "To: ada@mail.test",
    "Subject: Aw: Re: Invoice 12",
    "Message-ID: <m1@example.com>",
    "Authentication-Results: mx.cloudflare.net; spf=pass; dkim=pass; dmarc=pass",
    "Content-Type: multipart/mixed; boundary=b",
    "",
    "--b",
    "Content-Type: text/plain",
    "",
    "See attached.",
    "--b",
    'Content-Type: application/pdf; name="bill.pdf"',
    "Content-Disposition: attachment; filename=bill.pdf",
    "Content-Transfer-Encoding: base64",
    "",
    "aGVsbG8=",
    "--b--",
    "",
  ].join("\r\n");
  it("reads sender, thread, text and files", async () => {
    const p = await parseMime(new TextEncoder().encode(raw));
    expect(p.from).toBe("ana@example.com");
    expect(p.fromName).toBe("Ana Example");
    expect(p.subject).toBe("Aw: Re: Invoice 12");
    expect(p.messageId).toBe("<m1@example.com>");
    expect(p.text).toBe("See attached.");
    expect(p.files).toHaveLength(1);
    expect(p.files[0]?.name).toBe("bill.pdf");
    expect(Buffer.from(p.files[0]!.bytes).toString()).toBe("hello");
    expect(senderCheckFrom({ spf: "pass", dkim: "pass", dmarc: "pass" })).toBe("pass");
  });

  it("turns HTML-only mail into text", async () => {
    const p = await parseMime(
      new TextEncoder().encode(
        "From: a@b.c\r\nSubject: hi\r\nContent-Type: text/html\r\n\r\n<b>Hey</b> there",
      ),
    );
    expect(p.text).toContain("Hey");
  });

  it("packs files as base64 for the channel message", async () => {
    const p = await parseMime(new TextEncoder().encode(raw));
    const m = parsedToInbound(p, "ana@example.com|invoice 12", "Re: Invoice 12");
    expect(m.threadKey).toBe("ana@example.com|invoice 12");
    expect(m.reply).toEqual({
      to: "ana@example.com",
      subject: "Re: Invoice 12",
      in_reply_to: "<m1@example.com>",
    });
    expect(m.files?.[0]?.fetch.hostedBytes).toBe("aGVsbG8=");
    // And the adapter turns them back into bytes.
    const dl = await ADAPTERS.email.downloadFile!(
      { hosted: true },
      {},
      m.files![0]!.fetch,
      recorder().f,
    );
    expect(Buffer.from(dl.bytes).toString()).toBe("hello");
  });
});

describe("hosted senders", () => {
  const msg = {
    from: "Ada <ada@mail.test>",
    to: ["ana@example.com"],
    subject: "Re: hi",
    text: "Hello",
    html: "<p>Hello</p>",
    headers: { "In-Reply-To": "<m1>" },
  };
  it("Cloudflare: REST send with a named sender object", async () => {
    const { calls, f } = recorder(200, { success: true, result: { message_id: "<c1>" } });
    const s = new CloudflareMailSender({
      accountId: "acct",
      apiToken: "tok",
      apiBase: "http://cf.test/v4",
    });
    expect(await s.send(msg, f)).toEqual({ messageId: "<c1>" });
    expect(calls[0]?.url).toBe("http://cf.test/v4/accounts/acct/email/sending/send");
    expect(JSON.parse(calls[0]!.body)).toMatchObject({
      from: { name: "Ada", address: "ada@mail.test" },
      to: "ana@example.com",
      headers: { "In-Reply-To": "<m1>" },
    });
    expect(s.customMessageId).toBe(false);
    // Cloudflare refuses a send that sets its own Message-ID: one never reaches it.
    await s.send({ ...msg, headers: { ...msg.headers, "Message-ID": "<x@mail.test>" } }, f);
    expect(Object.keys(JSON.parse(calls[1]!.body).headers)).not.toContain("Message-ID");
  });

  it("Cloudflare: refusals and HTTP errors throw", async () => {
    const bad = new CloudflareMailSender({ accountId: "a", apiToken: "t" });
    await expect(
      bad.send(msg, recorder(200, { success: false, errors: [{ message: "bad domain" }] }).f),
    ).rejects.toThrow("bad domain");
    await expect(bad.send(msg, recorder(403, {}).f)).rejects.toThrow("Cloudflare answered 403");
  });

  it("Resend: the fallback behind the same interface", async () => {
    const { calls, f } = recorder(200, { id: "r1" });
    const s = new ResendMailSender({ apiKey: "k", apiBase: "http://re.test" });
    expect(await s.send(msg, f)).toEqual({ messageId: "r1" });
    expect(calls[0]?.url).toBe("http://re.test/emails");
    expect(JSON.parse(calls[0]!.body)).toMatchObject({
      from: "Ada <ada@mail.test>",
      to: ["ana@example.com"],
    });
  });
});

describe("self-hosted sender check", () => {
  it("reads Authentication-Results from the webhook's headers", () => {
    const body = JSON.stringify({
      type: "email.received",
      data: {
        from: "ana@example.com",
        subject: "hi",
        text: "hello",
        headers: { "Authentication-Results": "router.example; dmarc=pass" },
      },
    });
    expect(ADAPTERS.email.normalize(req(body), {})[0]?.senderCheck).toBe("pass");
  });

  it("marks mail without results as none", () => {
    const body = JSON.stringify({
      type: "email.received",
      data: { from: "ana@example.com", subject: "hi", text: "hello" },
    });
    expect(ADAPTERS.email.normalize(req(body), {})[0]?.senderCheck).toBe("none");
  });

  it("reads results from the receiving API's authentication object", async () => {
    const enrich = (body: unknown) =>
      ADAPTERS.email.enrich!(
        [{ threadKey: "t", sender: "ana@example.com", text: "", reply: {}, fetchId: "e1" }],
        {},
        { api_key: "k" },
        recorder(200, body).f,
      );
    // No text and no files: dropped, as before.
    expect(await enrich({ text: "", html: "", headers: [{ name: "X", value: "y" }] })).toEqual([]);
    expect(
      (
        await enrich({
          text: "hi",
          authentication: { spf: "pass", dkim: "pass", dmarc: "pass" },
        })
      )[0]?.senderCheck,
    ).toBe("pass");
    // Gray is Resend's word for "no DMARC policy": DKIM passing confirms, SPF alone doesn't.
    expect(
      (
        await enrich({
          text: "hi",
          authentication: { spf: "gray", dkim: "pass", dmarc: "gray" },
        })
      )[0]?.senderCheck,
    ).toBe("pass");
    expect(
      (
        await enrich({
          text: "hi",
          authentication: { spf: "pass", dkim: "gray", dmarc: "gray" },
        })
      )[0]?.senderCheck,
    ).toBe("fail");
    expect(
      (
        await enrich({
          text: "hi",
          authentication: { spf: "fail", dkim: "fail", dmarc: "fail" },
        })
      )[0]?.senderCheck,
    ).toBe("fail");
    // Without the object, headers are parsed on the off chance they appear.
    expect(
      (
        await enrich({
          text: "hi",
          headers: { "Authentication-Results": "router.example; dmarc=pass" },
        })
      )[0]?.senderCheck,
    ).toBe("pass");
  });
});

describe("hosted routine gate", () => {
  const hosted = { id: "c1", kind: "email" as const, config: { hosted: true } };
  const plain = { id: "c1", kind: "email" as const };
  const m = (senderCheck?: "pass" | "fail" | "none") => ({
    threadKey: "t",
    sender: "stranger@evil.test",
    text: "hello",
    reply: {},
    ...(senderCheck ? { senderCheck } : {}),
  });
  it("unconfirmed hosted mail starts no routine unless it opted in", () => {
    expect(messageMatches({ type: "message", sender: "*" }, hosted, m("fail"))).toBe(false);
    expect(messageMatches({ type: "message", sender: "*" }, hosted, m("none"))).toBe(false);
    expect(messageMatches({ type: "message", sender: "*" }, hosted, m("pass"))).toBe(true);
    expect(
      messageMatches({ type: "message", sender: "*", allow_unconfirmed: true }, hosted, m("fail")),
    ).toBe(true);
  });

  it("leaves other channels alone", () => {
    expect(messageMatches({ type: "message", sender: "*" }, plain, m("fail"))).toBe(true);
    expect(isAutomaticMail([{ key: "precedence", value: "bulk" }], "n@ews.test")).toBe(true);
  });

  it("filters by plus tag", () => {
    const tagged = { ...m("pass"), toTag: "receipts" };
    const t = (to_tag: string) => ({ type: "message" as const, sender: "*", to_tag });
    expect(messageMatches(t("receipts"), hosted, tagged)).toBe(true);
    expect(messageMatches(t("news"), hosted, tagged)).toBe(false);
    expect(messageMatches(t("receipts"), hosted, m("pass"))).toBe(false);
  });

  it("hears automatic mail only when asked", () => {
    const auto = { ...m("pass"), automatic: true };
    expect(messageMatches({ type: "message", sender: "*" }, hosted, auto)).toBe(false);
    expect(
      messageMatches({ type: "message", sender: "*", include_automatic: true }, hosted, auto),
    ).toBe(true);
  });
});

describe("hosted sender check against planted headers", () => {
  const crlf = (lines: string[]) => new TextEncoder().encode(lines.join("\r\n"));
  const check = async (raw: Uint8Array) => {
    const m = await parseMime(raw);
    return senderCheckFrom(cloudflareAuthResults(m.headers), m.from.split("@")[1]);
  };

  it("trusts Cloudflare's topmost header over one the sender planted below it", async () => {
    const raw = crlf([
      "Authentication-Results: mx.cloudflare.net; dkim=fail header.d=bank.test; spf=fail smtp.mailfrom=evil.test; dmarc=fail header.from=bank.test",
      "Authentication-Results: mx.cloudflare.net; dmarc=pass header.from=bank.test",
      "From: Bank <alerts@bank.test>",
      "To: ada@mail.test",
      "Subject: reset",
      "",
      "Click here.",
    ]);
    expect(await check(raw)).toBe("fail");
  });

  it("ignores a planted pass inside another clause or a comment", async () => {
    const raw = crlf([
      "Authentication-Results: mx.cloudflare.net; dkim=fail (dmarc=pass) header.d=x.test header.b=dmarc=pass; spf=none; dmarc=fail header.from=bank.test",
      "From: alerts@bank.test",
      "Subject: hi",
      "",
      "x",
    ]);
    expect(await check(raw)).toBe("fail");
  });

  it("counts nothing when the topmost header isn't Cloudflare's", async () => {
    const raw = crlf([
      "Authentication-Results: mx.evil.test; dmarc=pass header.from=bank.test",
      "Authentication-Results: mx.cloudflare.net; dmarc=pass header.from=bank.test",
      "From: alerts@bank.test",
      "Subject: hi",
      "",
      "x",
    ]);
    expect(await check(raw)).toBe("none");
  });

  it("passes an aligned DMARC pass from Cloudflare's header", async () => {
    const raw = crlf([
      "Authentication-Results: mx.cloudflare.net; dkim=pass header.d=bank.test; spf=pass smtp.mailfrom=bank.test; dmarc=pass header.from=bank.test",
      "From: alerts@bank.test",
      "Subject: hi",
      "",
      "x",
    ]);
    expect(await check(raw)).toBe("pass");
  });
});
