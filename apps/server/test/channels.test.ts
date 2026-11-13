/** Chat apps (D-134): webhooks, the sender gate, one conversation per thread, routines on messages, replies. */

import { createHmac } from "node:crypto";
import { once } from "node:events";
import { createServer, type Server } from "node:http";
import type { AddressInfo } from "node:net";
import { replyToChannel } from "@casama/agent";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
let provider: Server;
let api = "";
const calls: Array<{ path: string; body: string }> = [];

beforeAll(async () => {
  provider = createServer(async (req, res) => {
    const chunks: Buffer[] = [];
    for await (const c of req) chunks.push(c as Buffer);
    calls.push({ path: req.url ?? "", body: Buffer.concat(chunks).toString() });
    res
      .writeHead(200, { "content-type": "application/json" })
      .end(JSON.stringify({ ok: true, result: true }));
  }).listen(0, "127.0.0.1");
  await once(provider, "listening");
  api = `http://127.0.0.1:${(provider.address() as AddressInfo).port}`;
  h = await startHarness();
}, 60_000);
afterAll(async () => {
  await h?.stop();
  provider?.close();
});

async function setup(email: string) {
  const u = await h.user(email);
  const orgId = (
    await j(await h.request("/v1/orgs", { method: "POST", token: u.token, json: { name: "Ch" } }))
  ).id;
  const botId = (
    await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: u.token,
        json: { org_id: orgId, name: "Front desk" },
      }),
    )
  ).id;
  return { u, orgId, botId };
}
const secretsOf = async (id: string) => {
  const [r] = await h.tdb.admin<{ s: string }[]>`
    select v.decrypted_secret as s from public.channels c join vault.decrypted_secrets v on v.id = c.vault_secret_id where c.id = ${id}`;
  return JSON.parse(r!.s) as Record<string, string>;
};

describe("chat apps", () => {
  it("Telegram: sets the webhook, answers allowed senders in one conversation per chat, logs strangers, replies", async () => {
    const { u, botId } = await setup("tg@example.com");
    const res = await h.request("/v1/channels", {
      method: "POST",
      token: u.token,
      json: {
        bot_id: botId,
        kind: "telegram",
        name: "Telegram",
        config: { api_base: api },
        secrets: { bot_token: "123:abc" },
        allowed_senders: ["7"],
      },
    });
    expect(res.status).toBe(201);
    const ch = await j(res);
    expect(ch.webhook_url).toBe(`http://localhost/hooks/channels/${ch.id}`);
    expect(JSON.stringify(ch)).not.toContain("123:abc");
    const set = calls.find((c) => c.path === "/bot123:abc/setWebhook");
    const { webhook_secret } = await secretsOf(ch.id);
    expect(JSON.parse(set!.body)).toMatchObject({
      url: ch.webhook_url,
      secret_token: webhook_secret,
    });

    const post = (body: unknown, secret = webhook_secret) =>
      h.request(`/hooks/channels/${ch.id}`, {
        method: "POST",
        headers: { "content-type": "application/json", "x-telegram-bot-api-secret-token": secret! },
        body: JSON.stringify(body),
      });
    const msg = (from: number, text: string) => ({
      message: { text, chat: { id: from * 10 }, from: { id: from, first_name: "Ana" } },
    });

    expect((await post(msg(7, "hi"), "wrong")).status).toBe(401);
    expect((await post(msg(7, "Hi, are you open today?"))).status).toBe(200);
    expect((await post(msg(7, "And tomorrow?"))).status).toBe(200);
    expect((await post(msg(99, "spam"))).status).toBe(200);
    // The same update delivered twice starts one run (D-270).
    const repeat = { update_id: 5001, ...msg(7, "Is parking free?") };
    expect((await post(repeat)).status).toBe(200);
    expect((await post(repeat)).status).toBe(200);

    const runs = await h.tdb.admin<
      { conversation_id: string; trigger: string }[]
    >`select conversation_id, trigger from public.runs where bot_id = ${botId} order by created_at`;
    expect(runs.map((r) => r.trigger)).toEqual(["channel", "channel", "channel"]);
    expect(runs[0]!.conversation_id).toBe(runs[1]!.conversation_id);
    const [m] = await h.tdb.admin<{ content: Array<{ type: string; text?: string }> }[]>`
      select content from public.messages where conversation_id = ${runs[0]!.conversation_id} order by created_at limit 1`;
    expect(m!.content[0]!.text).toBe("(Telegram, from Ana)\nHi, are you open today?");

    const events = (await j(await h.request(`/v1/channels/${ch.id}/events`, { token: u.token })))
      .items as Array<{ status: string; sender: string }>;
    expect(events.find((e) => e.status === "ignored")?.sender).toBe("99");
    expect(events.filter((e) => e.status === "accepted")).toHaveLength(3);

    // The run's final answer goes back to the same chat.
    await replyToChannel(
      h.deps.db,
      { conversationId: runs[0]!.conversation_id },
      "Yes, 9 to 5.",
      fetch,
    );
    const sent = calls.find((c) => c.path === "/bot123:abc/sendMessage");
    expect(JSON.parse(sent!.body)).toEqual({ chat_id: 70, text: "Yes, 9 to 5." });

    // Turning it off stops answers; disconnecting removes its secrets.
    await h.request(`/v1/channels/${ch.id}`, {
      method: "PATCH",
      token: u.token,
      json: { enabled: false },
    });
    await post(msg(7, "still there?"));
    expect((await h.tdb.admin`select 1 from public.runs where bot_id = ${botId}`).length).toBe(3);
    const [vs] = await h.tdb.admin<
      { vault_secret_id: string }[]
    >`select vault_secret_id from public.channels where id = ${ch.id}`;
    const vault_secret_id = vs!.vault_secret_id;
    expect(
      (await h.request(`/v1/channels/${ch.id}`, { method: "DELETE", token: u.token })).status,
    ).toBe(200);
    expect(
      await h.tdb.admin`select 1 from vault.secrets where id = ${vault_secret_id}`,
    ).toHaveLength(0);
  });

  it("Email: an invoice from a vendor starts a message routine even though the vendor isn't allowed to chat", async () => {
    const { u, botId } = await setup("mail@example.com");
    const signing = `whsec_${Buffer.from("signing-key").toString("base64")}`;
    const ch = await j(
      await h.request("/v1/channels", {
        method: "POST",
        token: u.token,
        json: {
          bot_id: botId,
          kind: "email",
          name: "Inbox",
          config: { address: "bot@casama.test", api_base: api },
          secrets: { api_key: "re_1", signing_secret: signing },
          allowed_senders: ["*@example.com"],
        },
      }),
    );
    const routine = await h.request("/v1/routines", {
      method: "POST",
      token: u.token,
      json: {
        bot_id: botId,
        name: "File invoices",
        instructions: "File the invoice in the finance folder.",
        trigger: "message",
        message: { channel_kind: "email", sender: "*@vendor.com", subject_match: "invoice" },
      },
    });
    expect(routine.status).toBe(201);
    expect(await j(routine)).toMatchObject({
      trigger: "message",
      message: { sender: "*@vendor.com", subject_match: "invoice" },
    });
    const bad = await h.request("/v1/routines", {
      method: "POST",
      token: u.token,
      json: { bot_id: botId, name: "x", instructions: "y", trigger: "message" },
    });
    expect(bad.status).toBe(400);

    const send = async (from: string, subject: string, text: string) => {
      const body = JSON.stringify({ type: "email.received", data: { from, subject, text } });
      const ts = String(Math.floor(Date.now() / 1000));
      const sig = createHmac("sha256", Buffer.from("signing-key"))
        .update(`m.${ts}.${body}`)
        .digest("base64");
      return h.request(`/hooks/channels/${ch.id}`, {
        method: "POST",
        headers: {
          "content-type": "application/json",
          "svix-id": "m",
          "svix-timestamp": ts,
          "svix-signature": `v1,${sig}`,
        },
        body,
      });
    };
    expect(
      (await send("Lee <lee@vendor.com>", "Invoice 12 for October", "Total $400")).status,
    ).toBe(200);
    expect((await send("lee@vendor.com", "Lunch?", "Free Friday?")).status).toBe(200);
    expect((await send("ana@example.com", "Question", "Can you check my calendar?")).status).toBe(
      200,
    );

    const runs = await h.tdb.admin<
      { trigger: string; routine_id: string | null }[]
    >`select trigger, routine_id from public.runs where bot_id = ${botId} order by created_at`;
    expect(runs.map((r) => r.trigger)).toEqual(["message", "channel"]);
    const [routineMsg] = await h.tdb.admin<{ text: string }[]>`
      select m.content::text as text from public.messages m join public.runs r on r.id = m.run_id where r.bot_id = ${botId} and r.trigger = 'message'`;
    expect(routineMsg!.text).toContain("Invoice 12 for October");
    const events = (await j(await h.request(`/v1/channels/${ch.id}/events`, { token: u.token })))
      .items as Array<{ status: string; sender: string }>;
    expect(events.map((e) => e.status).sort()).toEqual(["accepted", "ignored", "routine"]);

    // The colleague's answer goes back as a reply in the same email thread, and a follow-up stays in it.
    const [conv] = await h.tdb.admin<
      { conversation_id: string }[]
    >`select conversation_id from public.runs where bot_id = ${botId} and trigger = 'channel'`;
    await replyToChannel(
      h.deps.db,
      { conversationId: conv!.conversation_id },
      "You're free after 3.",
      fetch,
    );
    const mail = calls.filter((c) => c.path === "/emails").at(-1);
    expect(JSON.parse(mail!.body)).toMatchObject({
      from: "bot@casama.test",
      to: ["ana@example.com"],
      subject: "Re: Question",
      text: "You're free after 3.",
    });
    await send("ana@example.com", "Re: Question", "Great, book 3:30");
    const convs = await h.tdb.admin<
      { conversation_id: string }[]
    >`select distinct conversation_id from public.runs where bot_id = ${botId} and trigger = 'channel'`;
    expect(convs).toHaveLength(1);
  });

  it("Meta setup handshake, missing credentials, and only bot managers can connect", async () => {
    const { u, orgId, botId } = await setup("wa@example.com");
    const missing = await h.request("/v1/channels", {
      method: "POST",
      token: u.token,
      json: {
        bot_id: botId,
        kind: "whatsapp",
        name: "WA",
        secrets: { access_token: "x" },
        allowed_senders: ["1"],
      },
    });
    expect(missing.status).toBe(400);
    const ch = await j(
      await h.request("/v1/channels", {
        method: "POST",
        token: u.token,
        json: {
          bot_id: botId,
          kind: "whatsapp",
          name: "WA",
          config: { phone_number_id: "PN" },
          secrets: { access_token: "EA", app_secret: "as" },
          allowed_senders: ["15550001"],
        },
      }),
    );
    expect(ch.verify_token).toMatch(/^[0-9a-f]{32}$/);
    const ok = await h.request(
      `/hooks/channels/${ch.id}?hub.mode=subscribe&hub.verify_token=${ch.verify_token}&hub.challenge=4242`,
    );
    expect(await ok.text()).toBe("4242");
    expect(
      (
        await h.request(
          `/hooks/channels/${ch.id}?hub.mode=subscribe&hub.verify_token=nope&hub.challenge=1`,
        )
      ).status,
    ).toBe(403);
    const listed = (await j(await h.request(`/v1/channels?bot_id=${botId}`, { token: u.token })))
      .items;
    expect(listed[0].verify_token).toBeNull();

    const member = await h.user("wa-member@example.com");
    await h.tdb
      .admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${member.id}, 'member')`;
    const denied = await h.request("/v1/channels", {
      method: "POST",
      token: member.token,
      json: {
        bot_id: botId,
        kind: "telegram",
        name: "T",
        secrets: { bot_token: "1:2" },
        allowed_senders: ["1"],
      },
    });
    expect([403, 404]).toContain(denied.status);
  });
});
