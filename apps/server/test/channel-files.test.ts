/** Files in chat apps (D-342): replies carry their files, photos people send reach the bot, signed links. */

import { once } from "node:events";
import { createServer, type Server } from "node:http";
import type { AddressInfo } from "node:net";
import { replyToChannel, signFileLink } from "@casama/agent";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { internalToken } from "../src/api/routes/local.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
let provider: Server;
let api = "";
const calls: Array<{ path: string; type: string; body: Buffer }> = [];
const JPEG = Buffer.from([0xff, 0xd8, 0xff, 0xe0, 1, 2, 3, 4, 5, 6, 7, 8]);

beforeAll(async () => {
  provider = createServer(async (req, res) => {
    const chunks: Buffer[] = [];
    for await (const c of req) chunks.push(c as Buffer);
    const path = req.url ?? "";
    calls.push({ path, type: req.headers["content-type"] ?? "", body: Buffer.concat(chunks) });
    // A file Telegram refuses, to check the reply falls back to a link.
    if (path.includes("/sendPhoto") && Buffer.concat(chunks).includes("poster.jpg")) {
      res
        .writeHead(400, { "content-type": "application/json" })
        .end(JSON.stringify({ ok: false, description: "Bad Request: file rejected" }));
      return;
    }
    if (path.startsWith("/file/")) {
      res.writeHead(200, { "content-type": "image/jpeg" }).end(JPEG);
      return;
    }
    const result = path.includes("/getFile")
      ? path.includes("big")
        ? { file_id: "big", file_size: 30 * 1024 * 1024 }
        : { file_id: "F1", file_path: "photos/file_1.jpg", file_size: JPEG.length }
      : path.includes("/send")
        ? { message_id: 900 + calls.length, chat: { id: 70 } }
        : true;
    res
      .writeHead(200, { "content-type": "application/json" })
      .end(JSON.stringify({ ok: true, result }));
  }).listen(0, "127.0.0.1");
  await once(provider, "listening");
  api = `http://127.0.0.1:${(provider.address() as AddressInfo).port}`;
  h = await startHarness();
}, 60_000);
afterAll(async () => {
  await h?.stop();
  provider?.close();
});

async function connect(email: string) {
  const u = await h.user(email);
  const orgId = (
    await j(await h.request("/v1/orgs", { method: "POST", token: u.token, json: { name: "F" } }))
  ).id;
  const botId = (
    await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: u.token,
        json: { org_id: orgId, name: "Files" },
      }),
    )
  ).id;
  const ch = await j(
    await h.request("/v1/channels", {
      method: "POST",
      token: u.token,
      json: {
        bot_id: botId,
        kind: "telegram",
        name: "Telegram",
        config: { api_base: api },
        secrets: { bot_token: "55:files" },
        allowed_senders: ["7"],
      },
    }),
  );
  const [s] = await h.tdb.admin<{ s: string }[]>`
    select v.decrypted_secret as s from public.channels c join vault.decrypted_secrets v on v.id = c.vault_secret_id where c.id = ${ch.id}`;
  const secret = JSON.parse(s!.s).webhook_secret as string;
  let n = 0;
  const post = (message: Record<string, unknown>) =>
    h.request(`/hooks/channels/${ch.id}`, {
      method: "POST",
      headers: { "content-type": "application/json", "x-telegram-bot-api-secret-token": secret },
      body: JSON.stringify({
        update_id: 9000 + ++n,
        message: { message_id: n, chat: { id: 70 }, ...message },
      }),
    });
  return { u, orgId, botId, ch, post };
}

const until = async <T>(fn: () => Promise<T | undefined | null>, ms = 10_000): Promise<T> => {
  const end = Date.now() + ms;
  for (;;) {
    const v = await fn();
    if (v) return v;
    if (Date.now() > end) throw new Error("timed out");
    await new Promise((r) => setTimeout(r, 50));
  }
};

describe("files in chat apps (D-342)", () => {
  it("a photo someone sends is saved and reaches the bot; strangers' files are never downloaded", async () => {
    const { botId, u, post } = await connect("files-in@example.com");
    expect(
      (
        await post({
          from: { id: 99, first_name: "Eve" },
          photo: [{ file_id: "S1", width: 9, height: 9 }],
        })
      ).status,
    ).toBe(200);
    expect(
      (
        await post({
          from: { id: 7, first_name: "Ana" },
          caption: "What's this?",
          photo: [{ file_id: "S2", width: 90, height: 90 }],
        })
      ).status,
    ).toBe(200);
    const m = await until(async () => {
      const [r] = await h.tdb.admin<{ content: Array<Record<string, unknown>> }[]>`
        select m.content from public.messages m join public.conversations c on c.id = m.conversation_id
        where c.bot_id = ${botId} and m.role = 'user' order by m.created_at limit 1`;
      return r;
    });
    const file = m.content.find((p) => p.type === "file") as Record<string, unknown>;
    expect(file).toMatchObject({ name: "photo.jpg", mime_type: "image/jpeg", uploaded: true });
    const id = String(file.path).replace(/^media:/, "");
    const [saved] = await h.tdb.admin<{ size: number; uploaded_by: string; in_library: boolean }[]>`
      select size, uploaded_by, in_library from public.chat_media where id = ${id}`;
    expect(saved).toEqual({ size: JPEG.length, uploaded_by: u.id, in_library: false });
    expect(calls.filter((c) => c.path.includes("getFile")).map((c) => c.path)).toEqual([
      "/bot55:files/getFile?file_id=S2",
    ]);

    // Too big for Telegram's bot limit: the run still starts, and the bot is told why.
    await post({
      from: { id: 7, first_name: "Ana" },
      document: { file_id: "big", file_name: "huge.mov", file_size: 30 * 1024 * 1024 },
    });
    const note = await until(async () => {
      const rows = await h.tdb.admin<{ content: Array<{ type: string; text?: string }> }[]>`
        select m.content from public.messages m join public.conversations c on c.id = m.conversation_id
        where c.bot_id = ${botId} and m.role = 'user' order by m.created_at`;
      return rows
        .map((r) => r.content.map((p) => p.text ?? "").join(""))
        .find((t) => t.includes("huge.mov"));
    });
    expect(note).toMatch(/too large \(30.0 MB/);
  });

  it("a reply's image goes as a photo after the text; one Telegram refuses goes as a signed link that opens", async () => {
    const { orgId, botId, post } = await connect("files-out@example.com");
    await post({ from: { id: 7, first_name: "Ana" }, text: "Draw a cat" });
    const run = await until(async () => {
      const [r] = await h.tdb.admin<{ id: string; conversation_id: string }[]>`
        select id, conversation_id from public.runs where bot_id = ${botId} limit 1`;
      return r;
    });
    const media = async (name: string, size: number) => {
      const [r] = await h.tdb.admin<{ id: string }[]>`
        insert into public.chat_media (org_id, bot_id, conversation_id, run_id, name, content_type, bytes, size)
        values (${orgId}, ${botId}, ${run.conversation_id}, ${run.id}, ${name}, 'image/jpeg', ${JPEG}, ${size})
        returning id`;
      return r!.id;
    };
    await media("cat.jpg", JPEG.length);
    const bigId = await media("poster.jpg", JPEG.length);
    const links = { base: "http://localhost", key: internalToken(h.deps.env) };
    const before = calls.length;
    await replyToChannel(
      h.deps.db,
      { conversationId: run.conversation_id, runId: run.id },
      "Here's your cat, and [the notes](~/notes.md).",
      fetch,
      undefined,
      { links },
    );
    const sent = calls.slice(before).filter((c) => c.path.startsWith("/bot55:files/send"));
    expect(sent.map((c) => c.path.split("/").pop())).toEqual([
      "sendMessage",
      "sendPhoto",
      "sendPhoto",
      "sendMessage",
    ]);
    expect(JSON.parse(sent[0]!.body.toString()).text).toBe("Here's your cat, and the notes.");
    expect(sent[1]!.type).toMatch(/^multipart\/form-data/);
    expect(sent[1]!.body.includes(JPEG)).toBe(true);
    const linkText = JSON.parse(sent[3]!.body.toString()).text as string;
    expect(linkText).toMatch(/poster\.jpg \(1 KB\)/);
    const url = linkText.match(/http:\/\/localhost(\/hooks\/files\/\S+?)(?=["<\s]|$)/)?.[1];
    expect(url).toBeTruthy();

    // The link opens without signing in, with ranges; forged or expired links get 404.
    const got = await h.request(url!);
    expect(got.status).toBe(200);
    expect(got.headers.get("content-type")).toBe("image/jpeg");
    expect(got.headers.get("content-disposition")).toContain("inline");
    expect(Buffer.from(await got.arrayBuffer())).toEqual(JPEG);
    const part = await h.request(url!, { headers: { range: "bytes=0-3" } });
    expect(part.status).toBe(206);
    expect(Buffer.from(await part.arrayBuffer())).toEqual(JPEG.subarray(0, 4));
    const expired = signFileLink(links.key, { kind: "media", id: bigId }, Date.now() - 1000);
    expect((await h.request(`/hooks/files/${expired}`)).status).toBe(404);
    const forged = signFileLink(
      "not-the-key-0000000000",
      { kind: "media", id: bigId },
      Date.now() + 60_000,
    );
    expect((await h.request(`/hooks/files/${forged}`)).status).toBe(404);
    // Deleting the file kills its links.
    await h.tdb.admin`delete from public.chat_media where id = ${bigId}`;
    expect((await h.request(url!)).status).toBe(404);
  });
});
