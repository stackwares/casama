import { describe, expect, it } from "vitest";
import { ADAPTERS, type ChannelKind } from "../src/channels/adapters.ts";
import {
  defaultName,
  fileLinkUrl,
  signFileLink,
  sniffMime,
  unlinkComputerFiles,
  verifyFileLink,
} from "../src/channels/files.ts";

/** Files in chat apps (D-342). */
type Call = { url: string; method: string; headers: Record<string, string>; body: unknown };
function provider(answer: (url: string) => unknown = () => ({ ok: true })) {
  const calls: Call[] = [];
  const f = (async (url: string, init: RequestInit = {}) => {
    calls.push({
      url,
      method: init.method ?? "GET",
      headers: Object.fromEntries(
        Object.entries((init.headers ?? {}) as Record<string, string>).map(([k, v]) => [
          k.toLowerCase(),
          v,
        ]),
      ),
      body: init.body,
    });
    const a = answer(url);
    if (a instanceof Response) return a;
    if (a instanceof Uint8Array)
      return new Response(a, { status: 200, headers: { "content-type": "image/jpeg" } });
    return new Response(JSON.stringify(a), {
      status: 200,
      headers: { "content-type": "application/json" },
    });
  }) as unknown as typeof fetch;
  return { calls, f };
}
const JPEG = new Uint8Array([0xff, 0xd8, 0xff, 0xe0, 1, 2, 3, 4]);
const PDF = new Uint8Array([0x25, 0x50, 0x44, 0x46, 0x2d, 0x31]);
const file = (
  mime: string,
  bytes = mime === "application/pdf" ? PDF : JPEG,
  name = mime === "application/pdf" ? "report.pdf" : "image.jpg",
) => ({
  name,
  mime,
  size: bytes.length,
  bytes,
  url: "https://api.example.com/hooks/files/tok",
});
const form = (c: Call | undefined) => c?.body as FormData;

describe("signed file links", () => {
  it("open until they expire, and can't be forged", () => {
    const now = Date.now();
    const t = signFileLink(
      "secret-0123456789",
      { kind: "media", id: "11111111-1111-1111-1111-111111111111" },
      now + 60_000,
    );
    expect(verifyFileLink("secret-0123456789", t, now)).toEqual({
      kind: "media",
      id: "11111111-1111-1111-1111-111111111111",
    });
    expect(verifyFileLink("secret-0123456789", t, now + 120_000)).toBeNull();
    expect(verifyFileLink("other-secret-000000", t, now)).toBeNull();
    const [body, mac] = t.split(".");
    const forged = Buffer.from(
      JSON.stringify({ m: "22222222-2222-2222-2222-222222222222", e: 9e9 }),
    ).toString("base64url");
    expect(verifyFileLink("secret-0123456789", `${forged}.${mac}`, now)).toBeNull();
    expect(verifyFileLink("secret-0123456789", `${body}`, now)).toBeNull();
    const c = signFileLink(
      "k".repeat(32),
      { kind: "creation", id: "33333333-3333-3333-3333-333333333333", version: 2 },
      now + 1000,
    );
    expect(verifyFileLink("k".repeat(32), c, now)).toEqual({
      kind: "creation",
      id: "33333333-3333-3333-3333-333333333333",
      version: 2,
    });
    expect(
      fileLinkUrl(
        { base: "https://api.example.com/", key: "k".repeat(32) },
        { kind: "media", id: "11111111-1111-1111-1111-111111111111" },
      ),
    ).toMatch(/^https:\/\/api\.example\.com\/hooks\/files\/[\w-]+\.[\w-]+$/);
  });
});

describe("what a reply says about its files", () => {
  it("links to the bot's computer keep only their words; web links and code stay", () => {
    expect(
      unlinkComputerFiles("Here's [the report](~/report.pdf) and ![chart](workspace/chart.png)."),
    ).toBe("Here's the report and chart.");
    expect(unlinkComputerFiles("See [docs](https://x.io) and `[a](~/b.txt)`")).toBe(
      "See [docs](https://x.io) and `[a](~/b.txt)`",
    );
    expect(unlinkComputerFiles("[](/home/casama/out.csv)")).toBe("out.csv");
  });

  it("names and types for files that came without them", () => {
    expect(defaultName("image/jpeg")).toBe("image.jpg");
    expect(defaultName("video/mp4")).toBe("video.mp4");
    expect(defaultName("application/x-thing")).toBe("file");
    expect(sniffMime(JPEG)).toBe("image/jpeg");
    expect(sniffMime(PDF, "application/octet-stream")).toBe("application/pdf");
    expect(sniffMime(new Uint8Array([1, 2]), undefined, "notes.csv")).toBe("text/csv");
    expect(sniffMime(JPEG, "image/png")).toBe("image/png");
  });
});

describe("sending files", () => {
  it("Telegram: a picture as a photo with an HTML caption, a PDF as a document", async () => {
    const { calls, f } = provider(() => ({ ok: true, result: { message_id: 9 } }));
    const ref = await ADAPTERS.telegram.sendFile?.(
      { api_base: "http://tg.test" },
      { bot_token: "t" },
      { chat_id: 5 },
      { ...file("image/jpeg"), caption: "**Done**" },
      f,
    );
    expect(ref).toBe("5:9");
    expect(calls[0]?.url).toBe("http://tg.test/bott/sendPhoto");
    expect(form(calls[0]).get("chat_id")).toBe("5");
    expect(form(calls[0]).get("caption")).toBe("<b>Done</b>");
    expect(form(calls[0]).get("parse_mode")).toBe("HTML");
    expect((form(calls[0]).get("photo") as File).name).toBe("image.jpg");
    await ADAPTERS.telegram.sendFile?.(
      { api_base: "http://tg.test" },
      { bot_token: "t" },
      { chat_id: 5 },
      file("application/pdf"),
      f,
    );
    expect(calls[1]?.url).toBe("http://tg.test/bott/sendDocument");
    expect(ADAPTERS.telegram.fileFits?.("video/mp4", 49 * 1024 * 1024)).toBe(true);
    expect(ADAPTERS.telegram.fileFits?.("video/mp4", 51 * 1024 * 1024)).toBe(false);
  });

  it("Slack: upload address, bytes, then complete in the thread with the caption", async () => {
    const { calls, f } = provider((url) =>
      url.includes("getUploadURLExternal")
        ? { ok: true, upload_url: "https://files.slack.com/up/1", file_id: "F1" }
        : { ok: true },
    );
    await ADAPTERS.slack.sendFile?.(
      { api_base: "http://s.test" },
      { bot_token: "xoxb" },
      { channel: "C1", thread_ts: "1.1" },
      { ...file("image/jpeg"), caption: "**hi**" },
      f,
    );
    expect(calls.map((c) => c.url)).toEqual([
      "http://s.test/api/files.getUploadURLExternal",
      "https://files.slack.com/up/1",
      "http://s.test/api/files.completeUploadExternal",
    ]);
    expect(String(calls[0]?.body)).toBe(`filename=image.jpg&length=${JPEG.length}`);
    expect(JSON.parse(String(calls[2]?.body))).toEqual({
      files: [{ id: "F1", title: "image.jpg" }],
      channel_id: "C1",
      thread_ts: "1.1",
      initial_comment: "*hi*",
    });
  });

  it("WhatsApp: uploaded, then sent by id with the right kind; unsupported types go as links", async () => {
    const { calls, f } = provider((url) =>
      url.endsWith("/media") ? { id: "MID" } : { messages: [{ id: "wamid.1" }] },
    );
    const ref = await ADAPTERS.whatsapp.sendFile?.(
      { api_base: "http://g.test", phone_number_id: "P" },
      { access_token: "a" },
      { to: "1555" },
      { ...file("application/pdf"), caption: "Here" },
      f,
    );
    expect(ref).toBe("wamid.1");
    expect(form(calls[0]).get("messaging_product")).toBe("whatsapp");
    expect(JSON.parse(String(calls[1]?.body))).toEqual({
      messaging_product: "whatsapp",
      to: "1555",
      type: "document",
      document: { id: "MID", caption: "Here", filename: "report.pdf" },
    });
    expect(ADAPTERS.whatsapp.fileFits?.("image/jpeg", 4 * 1024 * 1024)).toBe(true);
    expect(ADAPTERS.whatsapp.fileFits?.("image/jpeg", 6 * 1024 * 1024)).toBe(false);
    expect(ADAPTERS.whatsapp.fileFits?.("application/zip", 1000)).toBe(false);
  });

  it("Messenger, Feishu and Jira send the words first, then the file", async () => {
    const m = provider();
    await ADAPTERS.messenger.sendFile?.(
      { api_base: "http://g.test" },
      { page_token: "pt" },
      { recipient: "R" },
      { ...file("image/jpeg"), caption: "Look" },
      m.f,
    );
    expect(JSON.parse(String(m.calls[0]?.body)).message).toEqual({ text: "Look" });
    expect(JSON.parse(String(form(m.calls[1]).get("message")))).toEqual({
      attachment: { type: "image", payload: { is_reusable: false } },
    });

    const fs = provider((url) =>
      url.includes("tenant_access_token")
        ? { tenant_access_token: "T" }
        : url.endsWith("/images")
          ? { data: { image_key: "IK" } }
          : { code: 0 },
    );
    await ADAPTERS.feishu.sendFile?.(
      { api_base: "http://f.test", app_id: "A" },
      { app_secret: "S" },
      { chat_id: "oc_1" },
      file("image/jpeg"),
      fs.f,
    );
    const sent = fs.calls.at(-1);
    expect(JSON.parse(String(sent?.body))).toEqual({
      receive_id: "oc_1",
      msg_type: "image",
      content: JSON.stringify({ image_key: "IK" }),
    });

    const j = provider();
    await ADAPTERS.jira.sendFile?.(
      { api_base: "http://j.test", email: "b@x.io" },
      { api_token: "jt" },
      { issue_key: "K-1" },
      file("application/pdf"),
      j.f,
    );
    expect(j.calls[0]?.url).toBe("http://j.test/rest/api/3/issue/K-1/attachments");
    expect(j.calls[0]?.headers["x-atlassian-token"]).toBe("no-check");
  });

  it("SMS sends pictures by MMS from the signed link; Teams puts small pictures inline", async () => {
    const s = provider();
    await ADAPTERS.sms.sendFile?.(
      { api_base: "http://t.test", phone_number: "+1" },
      { account_sid: "AC", auth_token: "a" },
      { to: "+2" },
      { ...file("image/jpeg"), caption: "**hi**" },
      s.f,
    );
    const p = new URLSearchParams(String(s.calls[0]?.body));
    expect(p.get("MediaUrl")).toBe("https://api.example.com/hooks/files/tok");
    expect(p.get("Body")).toBe("hi");
    expect(ADAPTERS.sms.fileFits?.("application/pdf", 100)).toBe(false);

    const t = provider((url) =>
      url.includes("oauth2") ? { access_token: "tok", expires_in: 3600 } : {},
    );
    await ADAPTERS.teams.sendFile?.(
      { api_base: "http://teams.test", app_id: "A", login_base: "http://login.test" },
      { app_secret: "s" },
      { conversation_id: "c1" },
      file("image/jpeg"),
      t.f,
    );
    const activity = JSON.parse(String(t.calls.at(-1)?.body));
    expect(activity.attachments[0].contentUrl).toBe(
      `data:image/jpeg;base64,${Buffer.from(JPEG).toString("base64")}`,
    );
    expect(ADAPTERS.teams.fileFits?.("image/jpeg", 2 * 1024 * 1024)).toBe(false);
  });

  it("Discord attaches the file to the command's reply; Linear uploads and links it in a comment", async () => {
    const d = provider();
    await ADAPTERS.discord.sendFile?.(
      { api_base: "http://d.test" },
      { bot_token: "b" },
      { application_id: "A", token: "T", at: Date.now(), channel_id: "C" },
      { ...file("image/jpeg"), caption: "Here" },
      d.f,
    );
    expect(d.calls[0]?.url).toBe("http://d.test/webhooks/A/T");
    expect(JSON.parse(String(form(d.calls[0]).get("payload_json")))).toEqual({
      content: "Here",
      attachments: [{ id: 0, filename: "image.jpg" }],
    });

    const l = provider((url) =>
      url.endsWith("/graphql")
        ? {
            data: {
              fileUpload: {
                uploadFile: {
                  uploadUrl: "https://up.test/x",
                  assetUrl: "https://uploads.linear.app/a/b",
                  headers: [{ key: "x-goog", value: "1" }],
                },
              },
            },
          }
        : {},
    );
    await ADAPTERS.linear.sendFile?.(
      { api_base: "http://l.test" },
      { api_key: "k" },
      { issue_id: "I" },
      file("image/jpeg"),
      l.f,
    );
    expect(l.calls[1]?.method).toBe("PUT");
    expect(l.calls[1]?.headers["x-goog"]).toBe("1");
    expect(JSON.parse(String(l.calls[2]?.body)).variables.input.body).toBe(
      "![image.jpg](https://uploads.linear.app/a/b)",
    );
  });

  it("email carries the reply and its files in one message", async () => {
    const { calls, f } = provider();
    await ADAPTERS.email.sendBundle?.(
      { api_base: "http://r.test", address: "b@x.io" },
      { api_key: "k" },
      { to: "a@x.io", subject: "Re: hi" },
      "**Done**",
      [file("application/pdf")],
      f,
    );
    const mail = JSON.parse(String(calls[0]?.body));
    expect(mail.text).toBe("Done");
    expect(mail.attachments).toEqual([
      {
        filename: "report.pdf",
        content: Buffer.from(PDF).toString("base64"),
        content_type: "application/pdf",
      },
    ]);
  });

  it("iMessage sends the file through the Mac, with the link as text for older Macs", async () => {
    const { calls, f } = provider();
    await ADAPTERS.imessage.sendFile?.(
      { tunnel_url: "http://mac.test" },
      { internal_token: "i" },
      { to: "+1" },
      file("image/jpeg"),
      f,
    );
    const body = JSON.parse(String(calls[0]?.body));
    expect(body.to).toBe("+1");
    expect(body.text).toContain("https://api.example.com/hooks/files/tok");
    expect(body.file).toEqual({ name: "image.jpg", data: Buffer.from(JPEG).toString("base64") });
  });
});

describe("receiving files", () => {
  it("Telegram: getFile, then the file; over 20 MB says why", async () => {
    const { calls, f } = provider((url) =>
      url.includes("getFile") ? { ok: true, result: { file_path: "photos/a.jpg" } } : JPEG,
    );
    const got = await ADAPTERS.telegram.downloadFile?.(
      { api_base: "http://tg.test" },
      { bot_token: "t" },
      { file_id: "F" },
      f,
    );
    expect(calls.map((c) => c.url)).toEqual([
      "http://tg.test/bott/getFile?file_id=F",
      "http://tg.test/file/bott/photos/a.jpg",
    ]);
    expect(got?.bytes).toEqual(JPEG);
    const big = provider(() => ({ ok: true, result: { file_size: 30 * 1024 * 1024 } }));
    await expect(
      ADAPTERS.telegram.downloadFile?.({}, { bot_token: "t" }, { file_id: "F" }, big.f),
    ).rejects.toThrow(/20 MB/);
  });

  it("the bot token only goes to Slack's own file host; Twilio's credentials only to Twilio", async () => {
    const { calls, f } = provider(() => JPEG);
    await expect(
      ADAPTERS.slack.downloadFile?.({}, { bot_token: "x" }, { url: "https://evil.test/a" }, f),
    ).rejects.toThrow();
    await ADAPTERS.slack.downloadFile?.(
      {},
      { bot_token: "x" },
      { url: "https://files.slack.com/a" },
      f,
    );
    expect(calls[0]?.headers.authorization).toBe("Bearer x");
    await expect(
      ADAPTERS.sms.downloadFile?.(
        {},
        { account_sid: "A", auth_token: "B" },
        { url: "https://evil.test/m" },
        f,
      ),
    ).rejects.toThrow();
  });

  it("WhatsApp looks the media up, then downloads it with the token", async () => {
    const { calls, f } = provider((url) =>
      url.endsWith("/MID") ? { url: "https://lookaside.test/m", mime_type: "image/jpeg" } : JPEG,
    );
    const got = await ADAPTERS.whatsapp.downloadFile?.(
      { api_base: "http://g.test" },
      { access_token: "a" },
      { id: "MID" },
      f,
    );
    expect(calls[1]?.headers.authorization).toBe("Bearer a");
    expect(got?.mime).toBe("image/jpeg");
  });

  it("every app that receives files can download them", () => {
    const receiving: ChannelKind[] = [
      "telegram",
      "email",
      "sms",
      "slack",
      "whatsapp",
      "messenger",
      "feishu",
      "imessage",
      "teams",
      "discord",
      "linear",
      "jira",
    ];
    for (const k of receiving) expect(typeof ADAPTERS[k].downloadFile, k).toBe("function");
    for (const k of receiving)
      expect(typeof (ADAPTERS[k].sendFile ?? ADAPTERS[k].sendBundle), k).toBe("function");
  });

  it("Discord's attachment option, Slack's files and Linear's uploads come through as files", () => {
    const req = (body: unknown) => ({
      method: "POST",
      url: "http://x",
      headers: {},
      body: JSON.stringify(body),
    });
    const [d] = ADAPTERS.discord.normalize(
      req({
        type: 2,
        id: "i1",
        channel_id: "C",
        user: { id: "U" },
        data: {
          options: [{ type: 11, name: "file", value: "9" }],
          resolved: {
            attachments: {
              9: {
                url: "https://cdn.discordapp.com/a.png",
                filename: "a.png",
                content_type: "image/png",
                size: 5,
              },
            },
          },
        },
      }),
      {},
    );
    expect(d?.files).toEqual([
      {
        name: "a.png",
        mime: "image/png",
        size: 5,
        fetch: { url: "https://cdn.discordapp.com/a.png" },
      },
    ]);
    const [s] = ADAPTERS.slack.normalize(
      req({
        type: "event_callback",
        event: {
          type: "message",
          subtype: "file_share",
          user: "U",
          channel: "D1",
          ts: "1.1",
          text: "",
          files: [
            {
              name: "a.pdf",
              mimetype: "application/pdf",
              size: 3,
              url_private_download: "https://files.slack.com/a.pdf",
            },
          ],
        },
      }),
      {},
    );
    expect(s?.files?.[0]?.fetch).toEqual({ url: "https://files.slack.com/a.pdf" });
    const [l] = ADAPTERS.linear.normalize(
      req({
        type: "Comment",
        action: "create",
        actor: { id: "P" },
        data: { id: "c1", issueId: "I", body: "see ![shot](https://uploads.linear.app/x/y.png)" },
      }),
      { assignee_id: "BOT" },
    );
    expect(l?.files).toEqual([
      { name: "shot", fetch: { url: "https://uploads.linear.app/x/y.png" } },
    ]);
  });
});
