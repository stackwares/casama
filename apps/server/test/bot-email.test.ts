/** Hosted bot mail (BOT-EMAIL-PLAN Phases 1–2): claim, hook, inbox, routines, tools. */
import { createHash } from "node:crypto";
import { mkdtempSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import {
  type HostedMailMessage,
  loadChannel,
  mailHint,
  NotificationService,
  purgeExpiredMail,
  registerMailTools,
  sendThrough,
  signMailHook,
  ToolRegistry,
} from "@casama/agent";
import { FsObjectStore } from "@casama/sandbox";
import { sql } from "drizzle-orm";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { deleteKeptMail } from "../src/api/routes/mail.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
const sent: HostedMailMessage[] = [];

beforeAll(async () => {
  h = await startHarness({
    env: {
      MAIL_DOMAIN: "mail.test",
      MAIL_HOOK_SECRET: "hook-secret",
      INSTANCE_ADMIN_EMAILS: "admin@example.com,owner2@example.com",
    },
  });
  h.deps.hostedMail = {
    domain: "mail.test",
    sender: {
      name: "resend",
      customMessageId: true,
      send: async (msg) => {
        sent.push(msg);
        return { messageId: `<sent-${sent.length}@mail.test>` };
      },
    },
    sendPaused: false,
  };
  h.deps.notifications = new NotificationService(h.handle.db, {
    send: async () => ({ invalidTokens: [] }),
  });
  h.deps.objects = new FsObjectStore(mkdtempSync(join(tmpdir(), "casama-mail-")));
}, 60_000);
afterAll(async () => {
  await h?.stop();
});

async function setup(email: string, botName = "Ada") {
  const u = await h.user(email);
  const orgId = (
    await j(await h.request("/v1/orgs", { method: "POST", token: u.token, json: { name: "M" } }))
  ).id;
  const botId = (
    await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: u.token,
        json: { org_id: orgId, name: botName },
      }),
    )
  ).id;
  return { u, orgId, botId };
}

const mime = (o: {
  from: string;
  to: string;
  subject?: string;
  text?: string;
  auth?: string | null;
  auto?: boolean;
  messageId?: string;
}) =>
  Buffer.from(
    [
      `From: ${o.from}`,
      `To: ${o.to}`,
      `Subject: ${o.subject ?? "Hello"}`,
      `Message-ID: ${o.messageId ?? "<m1@example.com>"}`,
      ...(o.auth === undefined
        ? ["Authentication-Results: mx.cloudflare.net; spf=pass; dkim=pass; dmarc=pass"]
        : o.auth
          ? [`Authentication-Results: ${o.auth}`]
          : []),
      ...(o.auto ? ["Auto-Submitted: auto-replied"] : []),
      "Content-Type: text/plain",
      "",
      o.text ?? "Hi there",
      "",
    ].join("\r\n"),
  ).toString("base64");

const mimeFile = (o: { from: string; to: string; subject?: string; name?: string }) =>
  Buffer.from(
    [
      `From: ${o.from}`,
      `To: ${o.to}`,
      `Subject: ${o.subject ?? "Receipt"}`,
      "Message-ID: <file1@example.com>",
      "Authentication-Results: mx.cloudflare.net; spf=pass; dkim=pass; dmarc=pass",
      "Content-Type: multipart/mixed; boundary=b",
      "",
      "--b",
      "Content-Type: text/plain",
      "",
      "See attached.",
      "--b",
      `Content-Type: application/pdf; name="${o.name ?? "bill.pdf"}"`,
      `Content-Disposition: attachment; filename=${o.name ?? "bill.pdf"}`,
      "Content-Transfer-Encoding: base64",
      "",
      "aGVsbG8=",
      "--b--",
      "",
    ].join("\r\n"),
  ).toString("base64");

async function hook(to: string, raw: string, secret = "hook-secret") {
  const body = JSON.stringify({ to, from: "sender@example.com", raw });
  const at = String(Date.now());
  return h.request("/hooks/mail", {
    method: "POST",
    headers: { "x-mail-timestamp": at, "x-mail-signature": signMailHook(secret, at, body) },
    body,
  });
}

async function postEvent(event: unknown, secret = "hook-secret") {
  const body = JSON.stringify(event);
  const at = String(Date.now());
  return h.request("/hooks/mail/events", {
    method: "POST",
    headers: { "x-mail-timestamp": at, "x-mail-signature": signMailHook(secret, at, body) },
    body,
  });
}

const deliveryEvent = (
  type: string,
  sender: string,
  recipient: string,
  extra: Record<string, unknown> = {},
) => ({
  type: `cf.email.sending.message.${type}`,
  payload: {
    eventId: `ev-${Math.random().toString(36).slice(2)}`,
    messageId: "<sent-1@mail.test>",
    sender,
    recipient,
    ...extra,
  },
});

const runs = async (botId: string) =>
  (
    await h.handle.db.execute<{ n: number }>(
      sql`select count(*)::int as n from public.runs where bot_id = ${botId}::uuid`,
    )
  )[0]?.n ?? 0;

describe("claiming", () => {
  it("claims a name, allows the owner, and sends a welcome mail", async () => {
    const { u, botId } = await setup("owner@acme.org");
    const res = await h.request(`/v1/bots/${botId}/email`, {
      method: "POST",
      token: u.token,
      json: { name: "ada", surface: "profile" },
    });
    expect(res.status).toBe(201);
    expect(await j(res)).toMatchObject({
      local_part: "ada",
      address: "ada@mail.test",
      status: "active",
    });
    const [ch] = await h.handle.db.execute<{ config: unknown; allowed_senders: string[] }>(
      sql`select config, allowed_senders from public.channels where bot_id = ${botId}::uuid`,
    );
    expect(ch?.config).toMatchObject({ hosted: true, address: "ada@mail.test" });
    expect(ch?.allowed_senders).toEqual(["owner@acme.org"]);
    expect(sent.at(-1)).toMatchObject({
      from: "Ada <ada@mail.test>",
      to: ["owner@acme.org"],
    });
    // One bot, one address.
    expect(
      (
        await h.request(`/v1/bots/${botId}/email`, {
          method: "POST",
          token: u.token,
          json: { name: "ada2" },
        })
      ).status,
    ).toBe(409);
  });

  it("refuses bad, reserved and taken names", async () => {
    const { u, botId } = await setup("namer@example.com", "Namer");
    for (const name of ["ab", ".ada", "ad..a", "admin", "gmail"]) {
      const res = await h.request(`/v1/bots/${botId}/email`, {
        method: "POST",
        token: u.token,
        json: { name },
      });
      expect(res.status).toBe(400);
    }
    expect(
      (
        await h.request(`/v1/bots/${botId}/email`, {
          method: "POST",
          token: u.token,
          json: { name: "ada" },
        })
      ).status,
    ).toBe(409);
  });

  it("checks availability with alternatives", async () => {
    const { u, botId } = await setup("avail@example.com", "Avail");
    const res = await j(
      await h.request(`/v1/bots/${botId}/email/availability?name=ada`, { token: u.token }),
    );
    expect(res.available).toBe(false);
    expect(res.issue).toBe("That name is taken.");
    expect(res.suggestions.length).toBeGreaterThan(0);
    const free = await j(
      await h.request(`/v1/bots/${botId}/email/availability?name=front.desk`, { token: u.token }),
    );
    expect(free.available).toBe(true);
  });
});

describe("pause, move and release", () => {
  it("pauses and resumes", async () => {
    const { u, botId } = await setup("pauser@example.com", "Pauser");
    await h.request(`/v1/bots/${botId}/email`, {
      method: "POST",
      token: u.token,
      json: { name: "pauser" },
    });
    expect((await j(await h.request(`/v1/bots/${botId}/email`, { token: u.token }))).status).toBe(
      "active",
    );
    const paused = await j(
      await h.request(`/v1/bots/${botId}/email`, {
        method: "PATCH",
        token: u.token,
        json: { status: "paused" },
      }),
    );
    expect(paused.status).toBe("paused");
    const resumed = await j(
      await h.request(`/v1/bots/${botId}/email`, {
        method: "PATCH",
        token: u.token,
        json: { status: "active" },
      }),
    );
    expect(resumed.status).toBe("active");
  });

  it("moves to another bot in the workspace with its mail", async () => {
    const { u, orgId, botId } = await setup("mover@example.com", "Mover");
    const otherId = (
      await j(
        await h.request("/v1/bots", {
          method: "POST",
          token: u.token,
          json: { org_id: orgId, name: "Other" },
        }),
      )
    ).id;
    await h.request(`/v1/bots/${botId}/email`, {
      method: "POST",
      token: u.token,
      json: { name: "mover" },
    });
    await hook("mover@mail.test", mime({ from: "mover@example.com", to: "mover@mail.test" }));
    const moved = await j(
      await h.request(`/v1/bots/${botId}/email/move`, {
        method: "POST",
        token: u.token,
        json: { to_bot_id: otherId },
      }),
    );
    expect(moved.bot_id).toBe(otherId);
    expect((await h.request(`/v1/bots/${botId}/email`, { token: u.token })).status).toBe(404);
    // The mail row still keys on the address.
    const [row] = await h.handle.db.execute<{ n: number }>(sql`
      select count(*)::int as n from public.mail_messages m
      join public.mail_addresses a on a.id = m.address_id where a.local_part = 'mover'`);
    expect(row?.n).toBeGreaterThan(0);
  });

  it("releases for good and never reissues the name", async () => {
    const { u, orgId, botId } = await setup("leaver@example.com", "Leaver");
    await h.request(`/v1/bots/${botId}/email`, {
      method: "POST",
      token: u.token,
      json: { name: "leaver" },
    });
    const res = await j(
      await h.request(`/v1/bots/${botId}/email`, { method: "DELETE", token: u.token }),
    );
    expect(res.status).toBe("retired");
    // The name stays taken, even for a new bot.
    const bot2 = (
      await j(
        await h.request("/v1/bots", {
          method: "POST",
          token: u.token,
          json: { org_id: orgId, name: "Leaver2" },
        }),
      )
    ).id;
    expect(
      (
        await h.request(`/v1/bots/${bot2}/email`, {
          method: "POST",
          token: u.token,
          json: { name: "leaver" },
        })
      ).status,
    ).toBe(409);
    // Unknown to the hook from now on.
    expect(
      (await hook("leaver@mail.test", mime({ from: "a@b.c", to: "leaver@mail.test" }))).status,
    ).toBe(404);
  });
});

describe("the hook", () => {
  it("refuses unsigned and unknown mail", async () => {
    const { botId } = await setup("hooker@example.com", "Hooker");
    void botId;
    const body = JSON.stringify({
      to: "nobody@mail.test",
      raw: mime({ from: "a@b.c", to: "x@y.z" }),
    });
    const at = String(Date.now());
    expect(
      (
        await h.request("/hooks/mail", {
          method: "POST",
          headers: { "x-mail-timestamp": at, "x-mail-signature": "v1=nope" },
          body,
        })
      ).status,
    ).toBe(401);
    expect(
      (
        await h.request("/hooks/mail", {
          method: "POST",
          headers: {
            "x-mail-timestamp": at,
            "x-mail-signature": signMailHook("hook-secret", at, body),
          },
          body,
        })
      ).status,
    ).toBe(404);
  });

  it("answers allowed, confirmed mail in a chat", async () => {
    const { u, botId } = await setup("chatter@example.com", "Chatter");
    await h.request(`/v1/bots/${botId}/email`, {
      method: "POST",
      token: u.token,
      json: { name: "chatter" },
    });
    const before = await runs(botId);
    const res = await hook(
      "chatter@mail.test",
      mime({ from: "chatter@example.com", to: "chatter@mail.test", subject: "Receipts" }),
    );
    expect(res.status).toBe(200);
    expect(await runs(botId)).toBe(before + 1);
    const [conv] = await h.handle.db.execute<{ title: string }>(sql`
      select title from public.conversations c join public.channel_threads t on t.conversation_id = c.id
      where t.thread_key = 'chatter@example.com|receipts'`);
    expect(conv?.title).toContain("Receipts");
    const [msg] = await h.handle.db.execute<{ verdict: string; conversation_id: string | null }>(
      sql`select verdict, conversation_id from public.mail_messages where direction = 'in' order by created_at desc limit 1`,
    );
    expect(msg?.verdict).toBe("allowed");
    expect(msg?.conversation_id).toBeTruthy();
  });

  it("treats a faked allowed address as a stranger", async () => {
    const { u, botId } = await setup("faked@example.com", "Faked");
    await h.request(`/v1/bots/${botId}/email`, {
      method: "POST",
      token: u.token,
      json: { name: "faked" },
    });
    const before = await runs(botId);
    const res = await hook(
      "faked@mail.test",
      mime({
        from: "faked@example.com",
        to: "faked@mail.test",
        auth: "mx.cloudflare.net; spf=fail; dkim=fail; dmarc=fail",
      }),
    );
    expect(res.status).toBe(200);
    expect(await runs(botId)).toBe(before);
    const [ev] = await h.handle.db.execute<{ status: string; detail: string }>(sql`
      select status, detail from public.channel_events e join public.channels c on c.id = e.channel_id
      where c.bot_id = ${botId}::uuid order by e.created_at desc limit 1`);
    expect(ev?.status).toBe("ignored");
    expect(ev?.detail).toContain("treated as a stranger");
  });

  it("asks about confirmed mail from an unknown sender, once", async () => {
    const { u, botId } = await setup("second@example.com", "Second");
    await h.request(`/v1/bots/${botId}/email`, {
      method: "POST",
      token: u.token,
      json: { name: "second" },
    });
    await hook(
      "second@mail.test",
      mime({ from: "me@work.test", to: "second@mail.test", subject: "Fwd: bill" }),
    );
    const notes = await h.handle.db.execute<{ kind: string }>(
      sql`select kind from public.notifications where user_id = ${u.id}::uuid and kind = 'mail_unknown_sender'`,
    );
    expect(notes).toHaveLength(1);
    await hook(
      "second@mail.test",
      mime({
        from: "me@work.test",
        to: "second@mail.test",
        subject: "Fwd: another",
        messageId: "<m2@work.test>",
      }),
    );
    const notes2 = await h.handle.db.execute<{ kind: string }>(
      sql`select kind from public.notifications where user_id = ${u.id}::uuid and kind = 'mail_unknown_sender'`,
    );
    expect(notes2).toHaveLength(1);
  });

  it("starts nothing on automatic mail", async () => {
    const { u, botId } = await setup("auto@example.com", "Auto");
    await h.request(`/v1/bots/${botId}/email`, {
      method: "POST",
      token: u.token,
      json: { name: "auto" },
    });
    const before = await runs(botId);
    expect(
      (
        await hook(
          "auto@mail.test",
          mime({ from: "list@news.test", to: "auto@mail.test", auto: true }),
        )
      ).status,
    ).toBe(200);
    expect(await runs(botId)).toBe(before);
  });

  it("keeps mail for a paused address but starts nothing", async () => {
    const { u, botId } = await setup("paused@example.com", "Paused");
    await h.request(`/v1/bots/${botId}/email`, {
      method: "POST",
      token: u.token,
      json: { name: "paused" },
    });
    await h.request(`/v1/bots/${botId}/email`, {
      method: "PATCH",
      token: u.token,
      json: { status: "paused" },
    });
    const before = await runs(botId);
    expect(
      (
        await hook(
          "paused@mail.test",
          mime({ from: "paused@example.com", to: "paused@mail.test", subject: "Hi" }),
        )
      ).status,
    ).toBe(200);
    expect(await runs(botId)).toBe(before);
    const [row] = await h.handle.db.execute<{ n: number }>(sql`
      select count(*)::int as n from public.mail_messages m
      join public.mail_addresses a on a.id = m.address_id
      where a.local_part = 'paused' and m.direction = 'in'`);
    expect(row?.n).toBe(1);
  });

  it("checks existence over GET", async () => {
    const { u, botId } = await setup("headed@example.com", "Headed");
    await h.request(`/v1/bots/${botId}/email`, {
      method: "POST",
      token: u.token,
      json: { name: "headed" },
    });
    const at = String(Date.now());
    const sig = (to: string) => signMailHook("hook-secret", at, to);
    expect(
      (
        await h.request("/hooks/mail?to=headed%2Bshop@mail.test", {
          method: "GET",
          headers: { "x-mail-timestamp": at, "x-mail-signature": sig("headed+shop@mail.test") },
        })
      ).status,
    ).toBe(200);
    expect(
      (
        await h.request("/hooks/mail?to=nope@mail.test", {
          method: "GET",
          headers: { "x-mail-timestamp": at, "x-mail-signature": sig("nope@mail.test") },
        })
      ).status,
    ).toBe(404);
    // A signature for one address answers for no other.
    expect(
      (
        await h.request("/hooks/mail?to=headed@mail.test", {
          method: "GET",
          headers: { "x-mail-timestamp": at, "x-mail-signature": sig("nope@mail.test") },
        })
      ).status,
    ).toBe(401);
  });
});

describe("replies", () => {
  it("send through the hosted sender with threading, and stop at 10 an hour", async () => {
    const { u, botId } = await setup("replier@acme.org", "Replier");
    const claimed = await j(
      await h.request(`/v1/bots/${botId}/email`, {
        method: "POST",
        token: u.token,
        json: { name: "replier" },
      }),
    );
    const ch = (await loadChannel(h.handle.db, claimed.channel_id))!;
    const n = sent.length;
    const err = await sendThrough(
      h.handle.db,
      ch,
      { to: "replier@acme.org", subject: "Re: hi", in_reply_to: "<m1>" },
      "Hello **there**",
      fetch,
      "replier@acme.org|hi",
      undefined,
      undefined,
      h.deps.hostedMail!.sender,
    );
    expect(err).toBeNull();
    expect(sent[n]).toMatchObject({
      from: "Replier <replier@mail.test>",
      to: ["replier@acme.org"],
      headers: { "Auto-Submitted": "auto-replied", "In-Reply-To": "<m1>", References: "<m1>" },
    });
    expect(sent[n]?.html).toContain("there");
    // Casama's own Message-ID goes out and is kept; the sender's id is kept beside it.
    const ownId = sent[n]?.headers?.["Message-ID"] ?? "";
    expect(ownId).toMatch(/^<[0-9a-f-]{36}@mail\.test>$/);
    const [kept] = await h.handle.db.execute<{
      message_id: string;
      provider_message_id: string;
    }>(sql`
      select m.message_id, m.provider_message_id from public.mail_messages m
      join public.mail_addresses a on a.id = m.address_id
      where a.local_part = 'replier' and m.direction = 'out' order by m.created_at desc limit 1`);
    expect(kept?.message_id).toBe(ownId);
    expect(kept?.provider_message_id).toBe(`<sent-${n + 1}@mail.test>`);
    // Ten replies in the thread already: the thread stops without an allowed person's message,
    // and resets when an allowed person writes back (up to the hard hourly ceiling).
    const [a] = await h.handle.db.execute<{ id: string }>(
      sql`select id from public.mail_addresses where local_part = 'replier'`,
    );
    for (let i = 0; i < 10; i++)
      await h.handle.db.execute(sql`
        insert into public.mail_messages (address_id, org_id, direction, from_addr, verdict, thread_key)
        values (${a?.id}::uuid, ${ch.org_id}::uuid, 'out', 'replier@mail.test', 'allowed', 'replier@acme.org|hi')`);
    const err2 = await sendThrough(
      h.handle.db,
      ch,
      { to: "replier@acme.org", subject: "Re: hi" },
      "again",
      fetch,
      "replier@acme.org|hi",
      undefined,
      undefined,
      h.deps.hostedMail!.sender,
    );
    expect(err2).toContain("Waiting for a person");
    // An allowed human writing back resets the 10-without-human counter.
    await h.handle.db.execute(sql`
      insert into public.mail_messages (address_id, org_id, direction, from_addr, verdict, thread_key)
      values (${a?.id}::uuid, ${ch.org_id}::uuid, 'in', 'replier@acme.org', 'allowed', 'replier@acme.org|hi')`);
    const err3 = await sendThrough(
      h.handle.db,
      ch,
      { to: "replier@acme.org", subject: "Re: hi" },
      "after human",
      fetch,
      "replier@acme.org|hi",
      undefined,
      undefined,
      h.deps.hostedMail!.sender,
    );
    expect(err3).toBeNull();
    // Even with people writing back, a thread stops at 30 replies an hour.
    for (let i = 0; i < 20; i++)
      await h.handle.db.execute(sql`
        insert into public.mail_messages (address_id, org_id, direction, from_addr, verdict, thread_key)
        values (${a?.id}::uuid, ${ch.org_id}::uuid, 'out', 'replier@mail.test', 'allowed', 'replier@acme.org|hi')`);
    await h.handle.db.execute(sql`
      insert into public.mail_messages (address_id, org_id, direction, from_addr, verdict, thread_key)
      values (${a?.id}::uuid, ${ch.org_id}::uuid, 'in', 'replier@acme.org', 'allowed', 'replier@acme.org|hi')`);
    const err4 = await sendThrough(
      h.handle.db,
      ch,
      { to: "replier@acme.org", subject: "Re: hi" },
      "ceiling",
      fetch,
      "replier@acme.org|hi",
      undefined,
      undefined,
      h.deps.hostedMail!.sender,
    );
    expect(err4).toContain("hourly reply limit");
  });

  it("claims through the tool for whoever approved, when they manage the bot", async () => {
    const { u, orgId, botId } = await setup("tooler@example.com", "Tooler");
    const tools = new ToolRegistry();
    registerMailTools(tools, {
      db: h.handle.db,
      fetch,
      mail: { domain: "mail.test", sender: h.deps.hostedMail!.sender, sendPaused: false },
    });
    expect(tools.get("mail.claim")!.alwaysAsk).toBe(true);
    const runId = "00000000-0000-0000-0000-000000000001";
    await h.handle.db.execute(sql`
      insert into public.runs (id, org_id, bot_id, created_by, trigger)
      values (${runId}::uuid, ${orgId}::uuid, ${botId}::uuid, ${u.id}::uuid, 'chat')`);
    await h.handle.db.execute(sql`
      insert into public.approvals (org_id, bot_id, run_id, call_id, tool_name, args_redacted, summary, risk, status, decided_by, decided_at)
      values (${orgId}::uuid, ${botId}::uuid, ${runId}::uuid, 'call-1', 'mail.claim', '{}'::jsonb, 'claim', 'medium', 'approved', ${u.id}::uuid, now())`);
    const ctx = {
      runId,
      botId,
      orgId,
      actingUserId: u.id,
      callId: "call-1",
      output: async () => {},
      emit: async () => {},
    };
    const res = await tools.get("mail.claim")!.execute({ name: "tooler" } as never, ctx);
    expect(res.preview).toBe("tooler@mail.test");
  });

  it("refuses the tool to whoever doesn't manage the bot", async () => {
    const { orgId, botId } = await setup("boss2@example.com", "Bossy");
    const member = await h.user("member@example.com");
    await h.handle.db.execute(sql`
      insert into public.memberships (org_id, user_id, role)
      values (${orgId}::uuid, ${member.id}::uuid, 'member')`);
    const tools = new ToolRegistry();
    registerMailTools(tools, {
      db: h.handle.db,
      fetch,
      mail: { domain: "mail.test", sender: h.deps.hostedMail!.sender, sendPaused: false },
    });
    const ctx = {
      runId: "00000000-0000-0000-0000-000000000002",
      botId,
      orgId,
      actingUserId: member.id,
      output: async () => {},
      emit: async () => {},
    };
    await expect(
      tools.get("mail.claim")!.execute({ name: "sneaky" } as never, ctx),
    ).rejects.toThrow("Only people who manage this bot");
  });

  it("refuses while the address is paused", async () => {
    const { u, botId } = await setup("nopause@acme.org", "NoPause");
    const claimed = await j(
      await h.request(`/v1/bots/${botId}/email`, {
        method: "POST",
        token: u.token,
        json: { name: "nopause" },
      }),
    );
    await h.request(`/v1/bots/${botId}/email`, {
      method: "PATCH",
      token: u.token,
      json: { status: "paused" },
    });
    const ch = (await loadChannel(h.handle.db, claimed.channel_id))!;
    const err = await sendThrough(
      h.handle.db,
      ch,
      { to: "nopause@acme.org", subject: "hi" },
      "hello",
      fetch,
      undefined,
      undefined,
      undefined,
      h.deps.hostedMail!.sender,
    );
    expect(err).toContain("paused");
  });
});

describe("the kept inbox", () => {
  it("keeps strangers' and automatic mail for 30 days without starting anything", async () => {
    const { u, botId } = await setup("keeper@example.com", "Keeper");
    await h.request(`/v1/bots/${botId}/email`, {
      method: "POST",
      token: u.token,
      json: { name: "keeper" },
    });
    const before = await runs(botId);
    expect(
      (await hook("keeper@mail.test", mime({ from: "stranger@evil.test", to: "keeper@mail.test" })))
        .status,
    ).toBe(200);
    expect(
      (
        await hook(
          "keeper@mail.test",
          mime({
            from: "list@news.test",
            to: "keeper@mail.test",
            auto: true,
            messageId: "<news1@news.test>",
          }),
        )
      ).status,
    ).toBe(200);
    // A redelivery of the same Message-ID keeps nothing twice.
    expect(
      (await hook("keeper@mail.test", mime({ from: "stranger@evil.test", to: "keeper@mail.test" })))
        .status,
    ).toBe(200);
    expect(await runs(botId)).toBe(before);
    const rows = await h.handle.db.execute<{ verdict: string; expires_at: string }>(sql`
      select verdict, expires_at from public.mail_messages m
      join public.mail_addresses a on a.id = m.address_id
      where a.local_part = 'keeper' and m.direction = 'in' order by m.created_at`);
    expect(rows.map((r) => r.verdict)).toEqual(["stranger", "automatic"]);
    for (const r of rows) {
      const days = (new Date(r.expires_at).getTime() - Date.now()) / 86400000;
      expect(days).toBeGreaterThan(29);
      expect(days).toBeLessThan(31);
    }
  });

  it("lists and opens mail, and downloads its files", async () => {
    const { u, botId } = await setup("reader@acme.org", "Reader");
    await h.request(`/v1/bots/${botId}/email`, {
      method: "POST",
      token: u.token,
      json: { name: "reader" },
    });
    await hook("reader@mail.test", mimeFile({ from: "reader@acme.org", to: "reader@mail.test" }));
    const list = await j(await h.request(`/v1/bots/${botId}/email/messages`, { token: u.token }));
    expect(list.items.length).toBeGreaterThanOrEqual(2); // welcome + receipt
    const inbound = list.items.find((m: { direction: string }) => m.direction === "in");
    expect(inbound).toMatchObject({
      from_addr: "reader@acme.org",
      verdict: "allowed",
      sender_check: "pass",
      has_files: true,
      file_count: 1,
    });
    expect(inbound.snippet).toContain("See attached");
    const detail = await j(
      await h.request(`/v1/bots/${botId}/email/messages/${inbound.id}`, { token: u.token }),
    );
    expect(detail.text).toContain("See attached");
    expect(detail.files).toMatchObject([{ index: 0, name: "bill.pdf" }]);
    const file = await h.request(`/v1/bots/${botId}/email/messages/${inbound.id}/files/0`, {
      token: u.token,
    });
    expect(file.status).toBe(200);
    expect(await file.text()).toBe("hello");
  });

  it("refuses mail when the mailbox is full, and tells the owner once", async () => {
    const { u, orgId, botId } = await setup("full@example.com", "Full");
    await h.request(`/v1/bots/${botId}/email`, {
      method: "POST",
      token: u.token,
      json: { name: "full" },
    });
    await h.handle.db.execute(sql`
      insert into public.entitlements (org_id, plan_code, limits)
      values (${orgId}::uuid, 'free', '{"mail_storage_mb": 0}'::jsonb)`);
    const first = await hook(
      "full@mail.test",
      mime({ from: "full@example.com", to: "full@mail.test" }),
    );
    expect(first.status).toBe(413);
    expect(await first.json()).toMatchObject({ code: "mailbox_full" });
    expect(
      (await hook("full@mail.test", mime({ from: "full@example.com", to: "full@mail.test" })))
        .status,
    ).toBe(413);
    const notes = await h.handle.db.execute<{ id: string }>(
      sql`select id from public.notifications where user_id = ${u.id}::uuid and kind = 'mail_mailbox_full'`,
    );
    expect(notes).toHaveLength(1);
  });

  it("blocks and unblocks senders at the door", async () => {
    const { u, botId } = await setup("blocker@acme.org", "Blocker");
    await h.request(`/v1/bots/${botId}/email`, {
      method: "POST",
      token: u.token,
      json: { name: "blocker" },
    });
    const blocked = await j(
      await h.request(`/v1/bots/${botId}/email/block`, {
        method: "POST",
        token: u.token,
        json: { sender: "spammer@evil.test" },
      }),
    );
    expect(blocked.blocked_senders).toEqual(["spammer@evil.test"]);
    const refused = await hook(
      "blocker@mail.test",
      mime({ from: "spammer@evil.test", to: "blocker@mail.test" }),
    );
    expect(refused.status).toBe(404);
    expect(await refused.json()).toMatchObject({ code: "sender_blocked" });
    const [kept] = await h.handle.db.execute<{ n: number }>(sql`
      select count(*)::int as n from public.mail_messages m
      join public.mail_addresses a on a.id = m.address_id where a.local_part = 'blocker'`);
    expect(kept?.n).toBe(1); // the welcome only
    await h.request(`/v1/bots/${botId}/email/block?sender=spammer@evil.test`, {
      method: "DELETE",
      token: u.token,
    });
    expect(
      (
        await hook(
          "blocker@mail.test",
          mime({
            from: "spammer@evil.test",
            to: "blocker@mail.test",
            messageId: "<m2@evil.test>",
          }),
        )
      ).status,
    ).toBe(200);
  });

  it("purges expired mail and its stored originals", async () => {
    const { u, botId } = await setup("purger@example.com", "Purger");
    const claimed = await j(
      await h.request(`/v1/bots/${botId}/email`, {
        method: "POST",
        token: u.token,
        json: { name: "purger" },
      }),
    );
    await hook("purger@mail.test", mimeFile({ from: "x@y.test", to: "purger@mail.test" }));
    const [row] = await h.handle.db.execute<{ id: string; raw_key: string }>(sql`
      select m.id, m.raw_key from public.mail_messages m
      join public.mail_addresses a on a.id = m.address_id
      where a.local_part = 'purger' and m.direction = 'in'`);
    expect(row?.raw_key).toBeTruthy();
    await h.handle.db.execute(
      sql`update public.mail_messages set expires_at = now() - interval '1 hour' where id = ${row?.id}::uuid`,
    );
    expect(await purgeExpiredMail(h.handle.db, h.deps.objects)).toBe(1);
    const [gone] = await h.handle.db.execute<{ n: number }>(
      sql`select count(*)::int as n from public.mail_messages where id = ${row?.id}::uuid`,
    );
    expect(gone?.n).toBe(0);
    expect(
      await h.deps.objects!.get(row!.raw_key).then(
        () => true,
        () => false,
      ),
    ).toBe(false);
    void claimed;
  });
});

describe("routines on mail", () => {
  it("files receipts mailed to a plus tag", async () => {
    const { u, botId } = await setup("filer@example.com", "Filer");
    await h.request(`/v1/bots/${botId}/email`, {
      method: "POST",
      token: u.token,
      json: { name: "filer" },
    });
    const routine = await h.request("/v1/routines", {
      method: "POST",
      token: u.token,
      json: {
        bot_id: botId,
        name: "File receipts",
        instructions: "File the receipt.",
        trigger: "message",
        message: { channel_kind: "email", sender: "*", to_tag: "receipts" },
      },
    });
    expect(routine.status).toBe(201);
    const before = await runs(botId);
    await hook(
      "filer+receipts@mail.test",
      mime({ from: "shop@example.com", to: "filer+receipts@mail.test", subject: "Receipt" }),
    );
    const tagged = await h.tdb.admin<{ trigger: string; routine_id: string | null }[]>`
      select trigger, routine_id from public.runs where bot_id = ${botId} order by created_at`;
    expect(tagged.length).toBe(before + 1);
    expect(tagged.at(-1)?.trigger).toBe("message");
    // The bare address doesn't match the tag filter.
    await hook(
      "filer@mail.test",
      mime({
        from: "shop@example.com",
        to: "filer@mail.test",
        subject: "Hello",
        messageId: "<other@example.com>",
      }),
    );
    expect(await runs(botId)).toBe(before + 1);
  });

  it("caps stranger-started routine runs at 30 a day", async () => {
    const { u, orgId, botId } = await setup("capped@example.com", "Capped");
    const claimed = await j(
      await h.request(`/v1/bots/${botId}/email`, {
        method: "POST",
        token: u.token,
        json: { name: "capped" },
      }),
    );
    await h.request("/v1/routines", {
      method: "POST",
      token: u.token,
      json: {
        bot_id: botId,
        name: "Hear all",
        instructions: "Say hi.",
        trigger: "message",
        message: { channel_kind: "email", sender: "*" },
      },
    });
    for (let i = 0; i < 30; i++)
      await h.handle.db.execute(sql`
        insert into public.channel_events (channel_id, org_id, direction, status, sender, detail)
        values (${claimed.channel_id}::uuid, ${orgId}::uuid, 'in', 'routine', ${`s${i}@evil.test`},
                'Started by a new or unconfirmed sender')`);
    const before = await runs(botId);
    await hook("capped@mail.test", mime({ from: "new@evil.test", to: "capped@mail.test" }));
    expect(await runs(botId)).toBe(before);
    const [ev] = await h.handle.db.execute<{ detail: string }>(sql`
      select detail from public.channel_events where channel_id = ${claimed.channel_id}::uuid
      order by created_at desc limit 1`);
    expect(ev?.detail).toContain("30 a day");
  });

  it("unconfirmed mail starts no routine unless it opted in", async () => {
    const { u, botId } = await setup("optin@example.com", "Optin");
    await h.request(`/v1/bots/${botId}/email`, {
      method: "POST",
      token: u.token,
      json: { name: "optin" },
    });
    await h.request("/v1/routines", {
      method: "POST",
      token: u.token,
      json: {
        bot_id: botId,
        name: "Strict",
        instructions: "Say hi.",
        trigger: "message",
        message: { channel_kind: "email", sender: "*" },
      },
    });
    const before = await runs(botId);
    await hook(
      "optin@mail.test",
      mime({
        from: "fake@example.com",
        to: "optin@mail.test",
        auth: "mx.cloudflare.net; spf=fail; dkim=fail; dmarc=fail",
      }),
    );
    expect(await runs(botId)).toBe(before);
    await h.request("/v1/routines", {
      method: "POST",
      token: u.token,
      json: {
        bot_id: botId,
        name: "Lenient",
        instructions: "Say hi.",
        trigger: "message",
        message: { channel_kind: "email", sender: "*", allow_unconfirmed: true },
      },
    });
    await hook(
      "optin@mail.test",
      mime({
        from: "fake@example.com",
        to: "optin@mail.test",
        auth: "mx.cloudflare.net; spf=fail; dkim=fail; dmarc=fail",
        messageId: "<m2@example.com>",
      }),
    );
    expect(await runs(botId)).toBe(before + 1);
  });
});

describe("mail tools", () => {
  function mailTools() {
    const tools = new ToolRegistry();
    registerMailTools(tools, {
      db: h.handle.db,
      fetch,
      mail: { domain: "mail.test", sender: h.deps.hostedMail!.sender, sendPaused: false },
      objects: h.deps.objects,
    });
    return tools;
  }

  it("searches and reads kept mail", async () => {
    const { u, orgId, botId } = await setup("tooler2@example.com", "Tooler2");
    await h.request(`/v1/bots/${botId}/email`, {
      method: "POST",
      token: u.token,
      json: { name: "tooler2" },
    });
    await hook(
      "tooler2@mail.test",
      mime({ from: "tooler2@example.com", to: "tooler2@mail.test", subject: "Receipts" }),
    );
    const tools = mailTools();
    const ctx = {
      runId: "00000000-0000-0000-0000-000000000101",
      botId,
      orgId,
      actingUserId: u.id,
      output: async () => {},
      emit: async () => {},
    };
    const found = await tools.get("mail.search")!.execute({ subject: "receipts" } as never, ctx);
    expect(found.content).toContain("tooler2@example.com");
    const id = /- ([0-9a-f-]{36}) ·/.exec(found.content)?.[1];
    expect(id).toBeTruthy();
    const read = await tools.get("mail.read")!.execute({ id } as never, ctx);
    expect(read.content).toContain("Hi there");
    expect(read.content).toContain("outside Casama");
    const none = await tools.get("mail.search")!.execute({ sender: "nobody@x.test" } as never, ctx);
    expect(none.content).toBe("No mail matches.");
  });

  it("waits for a code that arrives mid-wait", async () => {
    const { u, orgId, botId } = await setup("waiter@example.com", "Waiter");
    await h.request(`/v1/bots/${botId}/email`, {
      method: "POST",
      token: u.token,
      json: { name: "waiter" },
    });
    const tools = mailTools();
    const ctx = {
      runId: "00000000-0000-0000-0000-000000000102",
      botId,
      orgId,
      actingUserId: u.id,
      output: async () => {},
      emit: async () => {},
    };
    const waiting = tools
      .get("mail.wait")!
      .execute({ from: "shop@example.com", timeout_s: 30 } as never, ctx);
    await new Promise((r) => setTimeout(r, 500));
    await hook(
      "waiter@mail.test",
      mime({
        from: "shop@example.com",
        to: "waiter@mail.test",
        subject: "Your code",
        text: "Your code is 481516.",
      }),
    );
    const got = await waiting;
    expect(got.content).toContain("481516");
  });

  it("sends to new people with a footer, and their replies come back as chats", async () => {
    const { u, orgId, botId } = await setup("sender2@example.com", "Sender2");
    await h.request(`/v1/bots/${botId}/email`, {
      method: "POST",
      token: u.token,
      json: { name: "sender2" },
    });
    const tools = mailTools();
    const def = tools.get("mail.send")!;
    expect(def.askEvenWithFullAccess).toBe(true);
    const gate = (args: Record<string, unknown>) =>
      def.alwaysAskForAsync!(args as never, { orgId, botId, db: h.handle.db });
    expect(await gate({ to: ["sender2@example.com"], subject: "s", text: "t" })).toBe(false);
    expect(await gate({ to: ["newperson@somewhere.com"], subject: "s", text: "t" })).toBe(true);
    const ctx = {
      runId: "00000000-0000-0000-0000-000000000201",
      botId,
      orgId,
      actingUserId: u.id,
      output: async () => {},
      emit: async () => {},
    };
    const n = sent.length;
    const res = await def.execute(
      {
        to: ["newperson@somewhere.com"],
        subject: "Table for two",
        text: "Hi, a table please",
      } as never,
      ctx,
    );
    expect(res.preview).toContain("newperson@somewhere.com");
    expect(sent[n]?.text).toContain("Sent by Sender2, an AI assistant working for");
    const [out] = await h.handle.db.execute<{ to_new: boolean }>(sql`
      select to_new from public.mail_messages m join public.mail_addresses a on a.id = m.address_id
      where a.local_part = 'sender2' and m.direction = 'out' order by m.created_at desc limit 1`);
    expect(out?.to_new).toBe(true);
    const [ledger] = await h.handle.db.execute<{ kind: string; billable: boolean }>(
      sql`select kind, billable from public.usage_ledger where bot_id = ${botId}::uuid and kind = 'emails_sent'`,
    );
    expect(ledger?.billable).toBe(false);
    // The reply lands in a chat, without joining the allowed list.
    const before = await runs(botId);
    await hook(
      "sender2@mail.test",
      mime({
        from: "newperson@somewhere.com",
        to: "sender2@mail.test",
        subject: "Re: Table for two",
        text: "Sure, 7pm?",
      }),
    );
    expect(await runs(botId)).toBe(before + 1);
    const [ch] = await h.handle.db.execute<{ allowed_senders: string[] }>(
      sql`select allowed_senders from public.channels where bot_id = ${botId}::uuid`,
    );
    expect(ch?.allowed_senders).toEqual(["sender2@example.com"]);
    // A second mail to the same person carries no footer.
    const n2 = sent.length;
    await def.execute(
      { to: ["newperson@somewhere.com"], subject: "Re: Table", text: "See you then" } as never,
      ctx,
    );
    expect(sent[n2]?.text).not.toContain("Sent by");
  });

  it("refuses suppressed, undeliverable and over-limit recipients", async () => {
    const { u, orgId, botId } = await setup("guarded@example.com", "Guarded");
    await h.request(`/v1/bots/${botId}/email`, {
      method: "POST",
      token: u.token,
      json: { name: "guarded" },
    });
    const tools = mailTools();
    const def = tools.get("mail.send")!;
    const ctx = {
      runId: "00000000-0000-0000-0000-000000000202",
      botId,
      orgId,
      actingUserId: u.id,
      output: async () => {},
      emit: async () => {},
    };
    await h.handle.db.execute(sql`
      insert into public.mail_suppressions (address_id, email, reason)
      select id, 'gone@somewhere.com', 'bounce' from public.mail_addresses where local_part = 'guarded'`);
    await expect(
      def.execute({ to: ["gone@somewhere.com"], subject: "s", text: "t" } as never, ctx),
    ).rejects.toThrow("suppressed");
    await expect(
      def.execute({ to: ["x@example.com"], subject: "s", text: "t" } as never, ctx),
    ).rejects.toThrow("can't receive mail");
    await expect(
      def.execute(
        {
          to: ["a@x.com", "b@x.com", "c@x.com", "d@x.com", "e@x.com", "f@x.com"],
          subject: "s",
          text: "t",
        } as never,
        ctx,
      ),
    ).rejects.toThrow("at most 5 people");
    await h.handle.db.execute(sql`
      insert into public.entitlements (org_id, plan_code, limits)
      values (${orgId}::uuid, 'free', '{"mail_sent_day": 100, "mail_new_day": 0}'::jsonb)`);
    await expect(
      def.execute({ to: ["fresh@somewhere.com"], subject: "s", text: "t" } as never, ctx),
    ).rejects.toThrow("new people");
  });

  it("records delivery events, suppresses on hard bounces and complaints", async () => {
    const { u, botId } = await setup("events@example.com", "Events");
    await h.request(`/v1/bots/${botId}/email`, {
      method: "POST",
      token: u.token,
      json: { name: "events" },
    });
    expect(
      (await postEvent(deliveryEvent("delivered", "events@mail.test", "a@somewhere.com"))).status,
    ).toBe(200);
    expect(
      (
        await postEvent(
          deliveryEvent("bounced", "events@mail.test", "bad@somewhere.com", {
            bounce: { type: "hard", reason: "550 User unknown" },
          }),
        )
      ).status,
    ).toBe(200);
    expect(
      (
        await postEvent(
          deliveryEvent("bounced", "events@mail.test", "soft@somewhere.com", {
            bounce: { type: "soft", reason: "421 Try later" },
          }),
        )
      ).status,
    ).toBe(200);
    expect(
      (await postEvent(deliveryEvent("complained", "events@mail.test", "mad@somewhere.com")))
        .status,
    ).toBe(200);
    // Unknown types and addresses are acknowledged, not retried.
    expect((await postEvent({ type: "cf.email.sending.message.deferred" })).status).toBe(200);
    expect(
      (await postEvent(deliveryEvent("delivered", "nobody@mail.test", "a@somewhere.com"))).status,
    ).toBe(200);
    expect((await postEvent({}, "wrong")).status).toBe(401);
    const events = await h.handle.db.execute<{ event: string; hard: boolean }>(sql`
      select event, hard from public.mail_events e
      join public.mail_addresses a on a.id = e.address_id where a.local_part = 'events'`);
    expect(events).toHaveLength(4);
    const supps = await h.handle.db.execute<{ email: string; reason: string }>(sql`
      select email, reason from public.mail_suppressions s
      join public.mail_addresses a on a.id = s.address_id where a.local_part = 'events'`);
    expect(supps).toEqual([
      { email: "bad@somewhere.com", reason: "bounce" },
      { email: "mad@somewhere.com", reason: "complaint" },
    ]);
  });

  it("pauses itself after two complaints, and only the instance owner lifts it", async () => {
    const { u, botId } = await setup("abused@example.com", "Abused");
    await h.request(`/v1/bots/${botId}/email`, {
      method: "POST",
      token: u.token,
      json: { name: "abused" },
    });
    await postEvent(deliveryEvent("complained", "abused@mail.test", "a@somewhere.com"));
    const [first] = await h.handle.db.execute<{ status: string }>(
      sql`select status from public.mail_addresses where local_part = 'abused'`,
    );
    expect(first?.status).toBe("active");
    await postEvent(deliveryEvent("complained", "abused@mail.test", "b@somewhere.com"));
    const [paused] = await h.handle.db.execute<{ status: string; auto_paused_at: string | null }>(
      sql`select status, auto_paused_at from public.mail_addresses where local_part = 'abused'`,
    );
    expect(paused?.status).toBe("paused");
    expect(paused?.auto_paused_at).toBeTruthy();
    const notes = await h.handle.db.execute<{ id: string }>(
      sql`select id from public.notifications where user_id = ${u.id}::uuid and kind = 'mail_auto_paused'`,
    );
    expect(notes).toHaveLength(1);
    // The owner can't lift it from the app.
    const lift = await h.request(`/v1/bots/${botId}/email`, {
      method: "PATCH",
      token: u.token,
      json: { status: "active" },
    });
    expect(lift.status).toBe(403);
  });

  it("the instance owner sees addresses, lifts pauses and reserves names", async () => {
    const admin = await h.user("admin@example.com");
    const { u, botId } = await setup("admintest@acme.org", "AdminTest");
    await h.request(`/v1/bots/${botId}/email`, {
      method: "POST",
      token: u.token,
      json: { name: "admintest" },
    });
    await postEvent(
      deliveryEvent("bounced", "admintest@mail.test", "bad@somewhere.com", {
        bounce: { type: "hard", reason: "550 nope" },
      }),
    );
    expect((await h.request("/v1/admin/mail", { token: u.token })).status).toBe(403);
    const list = await j(await h.request("/v1/admin/mail", { token: admin.token }));
    const row = list.items.find((r: { address: string }) => r.address === "admintest@mail.test");
    expect(row).toMatchObject({ sent_30d: 1, bounced_30d: 1, complained_30d: 0 });
    // Pause and lift from Admin.
    const [addr] = await h.handle.db.execute<{ id: string }>(
      sql`select id from public.mail_addresses where local_part = 'admintest'`,
    );
    const paused = await j(
      await h.request(`/v1/admin/mail/addresses/${addr?.id}`, {
        method: "PATCH",
        token: admin.token,
        json: { status: "paused" },
      }),
    );
    expect(paused.status).toBe("paused");
    const lifted = await j(
      await h.request(`/v1/admin/mail/addresses/${addr?.id}`, {
        method: "PATCH",
        token: admin.token,
        json: { status: "active" },
      }),
    );
    expect(lifted.status).toBe("active");
    expect(lifted.auto_paused).toBe(false);
    // Reserved names take effect on claims.
    const saved = await j(
      await h.request("/v1/admin/mail-reserved-names", {
        method: "PUT",
        token: admin.token,
        json: { names: ["mayor"] },
      }),
    );
    expect(saved.names).toEqual(["mayor"]);
    const second = await setup("admintest2@example.com", "AdminTest2");
    const refused = await h.request(`/v1/bots/${second.botId}/email`, {
      method: "POST",
      token: second.u.token,
      json: { name: "mayor" },
    });
    expect(refused.status).toBe(400);
  });

  it("notes the address in context on runs with one", async () => {
    const { u, botId } = await setup("noted@example.com", "Noted");
    expect(await mailHint(h.handle.db, botId)).toBeNull();
    await h.request(`/v1/bots/${botId}/email`, {
      method: "POST",
      token: u.token,
      json: { name: "noted" },
    });
    const hint = await mailHint(h.handle.db, botId);
    expect(hint).toContain("noted@mail.test");
    expect(hint).toContain("mail.wait");
    expect(hint).not.toContain("paused");
    await h.request(`/v1/bots/${botId}/email`, {
      method: "PATCH",
      token: u.token,
      json: { status: "paused" },
    });
    expect(await mailHint(h.handle.db, botId)).toContain("paused");
  });

  it("a stop-note suppresses the sender without starting anything", async () => {
    const { u, botId } = await setup("stopper@example.com", "Stopper");
    await h.request(`/v1/bots/${botId}/email`, {
      method: "POST",
      token: u.token,
      json: { name: "stopper" },
    });
    const before = await runs(botId);
    expect(
      (
        await hook(
          "stopper@mail.test",
          mime({ from: "tired@news.test", to: "stopper@mail.test", subject: "x", text: "STOP" }),
        )
      ).status,
    ).toBe(200);
    expect(await runs(botId)).toBe(before);
    const [sup] = await h.handle.db.execute<{ reason: string }>(sql`
      select reason from public.mail_suppressions s
      join public.mail_addresses a on a.id = s.address_id where a.local_part = 'stopper'`);
    expect(sup?.reason).toBe("stop");
  });

  it("reads files into the chat", async () => {
    const { u, orgId, botId } = await setup("filereader@example.com", "FileReader");
    await h.request(`/v1/bots/${botId}/email`, {
      method: "POST",
      token: u.token,
      json: { name: "filereader" },
    });
    await hook(
      "filereader@mail.test",
      mimeFile({ from: "filereader@example.com", to: "filereader@mail.test" }),
    );
    const [conv] = await h.handle.db.execute<{ id: string }>(sql`
      insert into public.conversations (org_id, bot_id, title, created_by)
      values (${orgId}::uuid, ${botId}::uuid, 't', ${u.id}::uuid) returning id`);
    const runId = "00000000-0000-0000-0000-000000000103";
    await h.handle.db.execute(sql`
      insert into public.runs (id, org_id, bot_id, conversation_id, created_by, trigger)
      values (${runId}::uuid, ${orgId}::uuid, ${botId}::uuid, ${conv?.id}::uuid, ${u.id}::uuid, 'chat')`);
    const tools = mailTools();
    const ctx = {
      runId,
      botId,
      orgId,
      actingUserId: u.id,
      output: async () => {},
      emit: async () => {},
    };
    const [row] = await h.handle.db.execute<{ id: string }>(sql`
      select m.id from public.mail_messages m join public.mail_addresses a on a.id = m.address_id
      where a.local_part = 'filereader' and m.direction = 'in'`);
    const read = await tools.get("mail.read")!.execute({ id: row?.id } as never, ctx);
    expect(read.content).toContain("bill.pdf (media:");
    const [media] = await h.handle.db.execute<{ n: number }>(
      sql`select count(*)::int as n from public.chat_media where conversation_id = ${conv?.id}::uuid`,
    );
    expect(media?.n).toBe(1);
  });
});

describe("audit hardening", () => {
  it("refuses deleting a hosted email channel from Chat apps", async () => {
    const { u, botId } = await setup("nodelete@acme.org", "NoDelete");
    const claimed = await j(
      await h.request(`/v1/bots/${botId}/email`, {
        method: "POST",
        token: u.token,
        json: { name: "nodelete" },
      }),
    );
    const del = await h.request(`/v1/channels/${claimed.channel_id}`, {
      method: "DELETE",
      token: u.token,
    });
    expect(del.status).toBe(400);
    const [still] = await h.handle.db.execute<{ status: string }>(
      sql`select status from public.mail_addresses where local_part = 'nodelete'`,
    );
    expect(still?.status).toBe("active");
  });

  it("retires the address, expires kept mail, and stops inbound mail when a bot is archived", async () => {
    const { u, botId } = await setup("archiver@acme.org", "Archiver");
    await h.request(`/v1/bots/${botId}/email`, {
      method: "POST",
      token: u.token,
      json: { name: "archiver" },
    });
    await h.handle.db.execute(
      sql`update public.bots set archived_at = now() where id = ${botId}::uuid`,
    );
    const [addr] = await h.handle.db.execute<{ status: string; channel_id: string }>(
      sql`select status, channel_id from public.mail_addresses where local_part = 'archiver'`,
    );
    expect(addr?.status).toBe("retired");
    const [ch] = await h.handle.db.execute<{ enabled: boolean }>(
      sql`select enabled from public.channels where id = ${addr?.channel_id}::uuid`,
    );
    expect(ch?.enabled).toBe(false);
    const [msg] = await h.handle.db.execute<{ expires_at: string | null }>(
      sql`select expires_at from public.mail_messages m join public.mail_addresses a on a.id = m.address_id where a.local_part = 'archiver' limit 1`,
    );
    expect(msg?.expires_at).not.toBeNull();
    const res = await hook(
      "archiver@mail.test",
      mime({ from: "archiver@acme.org", to: "archiver@mail.test" }),
    );
    expect(res.status).toBe(404);
  });

  it("rejects multi-address strings even when domain wildcard is allowed", async () => {
    const { u, botId } = await setup("multi@acme.org", "Multi");
    const claimed = await j(
      await h.request(`/v1/bots/${botId}/email`, {
        method: "POST",
        token: u.token,
        json: { name: "multi" },
      }),
    );
    await h.handle.db.execute(
      sql`update public.channels set allowed_senders = '{"*@acme.org"}'::text[] where id = ${claimed.channel_id}::uuid`,
    );
    const tools = new ToolRegistry();
    registerMailTools(tools, { db: h.handle.db, fetch, mail: h.deps.hostedMail });
    const ask = await tools.get("mail.send")!.alwaysAskForAsync!(
      { to: ["evil@x.com, boss@acme.org"], subject: "hi", text: "hi" },
      { db: h.handle.db, botId, orgId: "" },
    );
    expect(ask).toBe(true);
  });

  it("fails sender check when a message carries multiple From addresses", async () => {
    const { u, botId } = await setup("twofrom@acme.org", "TwoFrom");
    await h.request(`/v1/bots/${botId}/email`, {
      method: "POST",
      token: u.token,
      json: { name: "twofrom" },
    });
    const raw = Buffer.from(
      [
        "Authentication-Results: mx.cloudflare.net; spf=pass; dkim=pass; dmarc=pass header.from=acme.org",
        "From: twofrom@acme.org, evil@other.org",
        "To: twofrom@mail.test",
        "Subject: Spoof",
        "Message-ID: <twofrom@acme.org>",
        "Content-Type: text/plain; charset=utf-8",
        "",
        "Hi",
      ].join("\r\n"),
    ).toString("base64");
    const res = await hook("twofrom@mail.test", raw);
    expect(res.status).toBe(200);
    const [m] = await h.handle.db.execute<{ sender_check: string; verdict: string }>(sql`
      select m.sender_check, m.verdict from public.mail_messages m
      join public.mail_addresses a on a.id = m.address_id
      where a.local_part = 'twofrom' and m.direction = 'in'`);
    expect(m).toMatchObject({ sender_check: "fail", verdict: "stranger" });
  });

  it("accepts raw message/rfc822 posts signed by SHA-256 and rejects oversized payloads", async () => {
    const { u, botId } = await setup("rawpost@acme.org", "RawPost");
    await h.request(`/v1/bots/${botId}/email`, {
      method: "POST",
      token: u.token,
      json: { name: "rawpost" },
    });
    const rawMime = [
      "Authentication-Results: mx.cloudflare.net; spf=pass; dkim=pass; dmarc=pass header.from=acme.org",
      "From: rawpost@acme.org",
      "To: rawpost@mail.test",
      "Subject: Raw binary",
      "Message-ID: <rawbin@acme.org>",
      "Content-Type: text/plain; charset=utf-8",
      "",
      "Streamed raw body",
    ].join("\r\n");
    const bytes = new TextEncoder().encode(rawMime);
    const digest = createHash("sha256").update(bytes).digest("hex");
    const at = String(Date.now());
    const sig = signMailHook("hook-secret", at, `rawpost@mail.test\nrawpost@acme.org\n${digest}`);
    const res = await h.request("/hooks/mail", {
      method: "POST",
      headers: {
        "content-type": "message/rfc822",
        "x-mail-to": "rawpost@mail.test",
        "x-mail-from": "rawpost@acme.org",
        "x-mail-timestamp": at,
        "x-mail-signature": sig,
      },
      body: bytes,
    });
    expect(res.status).toBe(200);
    // Content-Length over limit fails with 413 before signature verification.
    const big = await h.request("/hooks/mail", {
      method: "POST",
      headers: {
        "content-type": "message/rfc822",
        "content-length": String(26 * 1024 * 1024),
        "x-mail-to": "rawpost@mail.test",
        "x-mail-timestamp": at,
        "x-mail-signature": "bad",
      },
      body: "x",
    });
    expect(big.status).toBe(413);
  });

  it("routes CC'd recipient replies into the bot's thread and marks mail.claim askEvenWithFullAccess", async () => {
    const { u, orgId, botId } = await setup("ccowner@acme.org", "CCBot");
    await h.request(`/v1/bots/${botId}/email`, {
      method: "POST",
      token: u.token,
      json: { name: "ccbot" },
    });
    const tools = new ToolRegistry();
    registerMailTools(tools, { db: h.handle.db, fetch, mail: h.deps.hostedMail });
    expect(tools.get("mail.claim")?.askEvenWithFullAccess).toBe(true);
    const [a] = await h.handle.db.execute<{ id: string }>(
      sql`select id from public.mail_addresses where local_part = 'ccbot'`,
    );
    await h.handle.db.execute(sql`
      insert into public.mail_messages
        (address_id, org_id, direction, from_addr, to_addrs, subject, message_id, thread_key, verdict)
      values (${a?.id}::uuid, ${orgId}::uuid, 'out', 'ccbot@mail.test',
              '{"primary@partner.org","ccperson@partner.org"}'::text[], 'Dinner', '<out1@mail.test>',
              'primary@partner.org|dinner', 'allowed')`);
    const res = await hook(
      "ccbot@mail.test",
      mime({
        from: "ccperson@partner.org",
        to: "ccbot@mail.test",
        subject: "Re: Dinner",
        text: "See you at 7",
      }),
    );
    expect(res.status).toBe(200);
    const [inbound] = await h.handle.db.execute<{ verdict: string }>(sql`
      select verdict from public.mail_messages where address_id = ${a?.id}::uuid and from_addr = 'ccperson@partner.org'`);
    expect(inbound?.verdict).toBe("allowed");
  });

  it("prevents escaping an automatic pause by archiving the bot and claiming on another bot", async () => {
    const { u, orgId, botId } = await setup("escaper@acme.org", "Escaper");
    await h.request(`/v1/bots/${botId}/email`, {
      method: "POST",
      token: u.token,
      json: { name: "escaper1" },
    });
    await h.handle.db.execute(sql`
      update public.mail_addresses set status = 'paused', auto_paused_at = now()
      where local_part = 'escaper1'`);
    // Cannot release an auto-paused address.
    const rel = await h.request(`/v1/bots/${botId}/email`, { method: "DELETE", token: u.token });
    expect(rel.status).toBe(403);
    // Archiving the bot retires the address, but auto_paused_at still blocks new claims in the workspace.
    await h.handle.db.execute(
      sql`update public.bots set archived_at = now() where id = ${botId}::uuid`,
    );
    const [bot2] = await h.handle.db.execute<{ id: string }>(sql`
      insert into public.bots (org_id, name, created_by) values (${orgId}::uuid, 'Escaper2', ${u.id}::uuid) returning id`);
    const claim2 = await h.request(`/v1/bots/${bot2?.id}/email`, {
      method: "POST",
      token: u.token,
      json: { name: "escaper2" },
    });
    expect(claim2.status).toBe(403);
  });

  it("always releases, and caps claims at the plan's addresses plus 3 a year", async () => {
    const { u, orgId } = await setup("cycler@acme.org", "Cycler");
    const newBot = async (name: string) =>
      (
        await j(
          await h.request("/v1/bots", {
            method: "POST",
            token: u.token,
            json: { org_id: orgId, name },
          }),
        )
      ).id as string;
    const claim = (botId: string, name: string) =>
      h.request(`/v1/bots/${botId}/email`, { method: "POST", token: u.token, json: { name } });
    // A plan with 1 address, so 4 claims in a year. Releasing and archiving both free the slot.
    await h.handle.db.execute(sql`
      insert into public.entitlements (org_id, plan_code, limits)
      values (${orgId}::uuid, 'free', '{"max_mail_addresses": 1, "mail_sent_day": 20, "mail_new_day": 0, "mail_storage_mb": 100}'::jsonb)`);
    for (let i = 1; i <= 4; i++) {
      const botId = await newBot(`Cycler${i}`);
      expect((await claim(botId, `cycler${i}`)).status).toBe(201);
      if (i % 2)
        expect(
          (await h.request(`/v1/bots/${botId}/email`, { method: "DELETE", token: u.token })).status,
        ).toBe(200);
      else
        await h.handle.db.execute(
          sql`update public.bots set archived_at = now() where id = ${botId}::uuid`,
        );
    }
    const fifth = await claim(await newBot("Cycler5"), "cycler5");
    expect(fifth.status).toBe(402);
    expect(((await fifth.json()) as { detail?: string }).detail ?? "").toContain("last year");
    // A year on, the oldest claim no longer counts.
    await h.handle.db.execute(sql`
      update public.mail_addresses set created_at = now() - interval '366 days' where local_part = 'cycler1'`);
    expect((await claim(await newBot("Cycler6"), "cycler6")).status).toBe(201);
  });

  it("moving makes the mover the one the address acts for", async () => {
    const { u, orgId, botId } = await setup("mover2@acme.org", "Mover2");
    const claimed = await j(
      await h.request(`/v1/bots/${botId}/email`, {
        method: "POST",
        token: u.token,
        json: { name: "mover2" },
      }),
    );
    await h.handle.db.execute(
      sql`update public.channels set created_by = null where id = ${claimed.channel_id}::uuid`,
    );
    const [bot2] = await h.handle.db.execute<{ id: string }>(sql`
      insert into public.bots (org_id, name, created_by) values (${orgId}::uuid, 'Mover3', ${u.id}::uuid) returning id`);
    const res = await h.request(`/v1/bots/${botId}/email/move`, {
      method: "POST",
      token: u.token,
      json: { to_bot_id: bot2!.id },
    });
    expect(res.status).toBe(200);
    const [ch] = await h.handle.db.execute<{ bot_id: string; created_by: string }>(
      sql`select bot_id, created_by from public.channels where id = ${claimed.channel_id}::uuid`,
    );
    expect(ch).toMatchObject({ bot_id: bot2!.id, created_by: u.id });
  });

  it("mail.wait finds a code that came before it was called, but not an old one", async () => {
    const { u, orgId, botId } = await setup("early@example.com", "Early");
    await h.request(`/v1/bots/${botId}/email`, {
      method: "POST",
      token: u.token,
      json: { name: "early" },
    });
    const tools = new ToolRegistry();
    registerMailTools(tools, {
      db: h.handle.db,
      fetch,
      mail: { domain: "mail.test", sender: h.deps.hostedMail!.sender, sendPaused: false },
    });
    const ctx = {
      runId: "00000000-0000-0000-0000-000000000301",
      botId,
      orgId,
      actingUserId: u.id,
      output: async () => {},
      emit: async () => {},
    };
    await hook(
      "early@mail.test",
      mime({
        from: "codes@shop.test",
        to: "early@mail.test",
        subject: "Old code",
        text: "Your code is 111111.",
        messageId: "<old-code@shop.test>",
      }),
    );
    await h.handle.db.execute(sql`
      update public.mail_messages set created_at = now() - interval '1 hour' where message_id = '<old-code@shop.test>'`);
    await hook(
      "early@mail.test",
      mime({
        from: "codes@shop.test",
        to: "early@mail.test",
        subject: "Your code",
        text: "Your code is 424242.",
        messageId: "<new-code@shop.test>",
      }),
    );
    const wait = tools.get("mail.wait")!;
    const got = await wait.execute({ from: "shop.test", timeout_s: 10 } as never, ctx);
    expect(got.content).toContain("424242");
    await h.handle.db.execute(sql`
      update public.mail_messages set created_at = now() - interval '1 hour' where message_id = '<new-code@shop.test>'`);
    const none = await wait.execute({ from: "shop.test", timeout_s: 10 } as never, ctx);
    expect(none.content).toContain("arrived in time");
  }, 30_000);

  it("never refuses a retry of kept mail for space", async () => {
    const { u, orgId, botId } = await setup("retry@example.com", "Retry");
    await h.request(`/v1/bots/${botId}/email`, {
      method: "POST",
      token: u.token,
      json: { name: "retry" },
    });
    const first = mime({
      from: "retry@example.com",
      to: "retry@mail.test",
      messageId: "<r1@example.com>",
    });
    expect((await hook("retry@mail.test", first)).status).toBe(200);
    await h.handle.db.execute(sql`
      insert into public.entitlements (org_id, plan_code, limits)
      values (${orgId}::uuid, 'free', '{"mail_storage_mb": 0}'::jsonb)`);
    expect((await hook("retry@mail.test", first)).status).toBe(200);
    const [n] = await h.handle.db.execute<{ n: number }>(sql`
      select count(*)::int as n from public.mail_messages m join public.mail_addresses a on a.id = m.address_id
      where a.local_part = 'retry' and m.direction = 'in'`);
    expect(n?.n).toBe(1);
    const other = mime({
      from: "retry@example.com",
      to: "retry@mail.test",
      messageId: "<r2@example.com>",
    });
    expect((await hook("retry@mail.test", other)).status).toBe(413);
  });

  it("matches thread replies by subject only for a real subject within 90 days", async () => {
    const { u, orgId, botId } = await setup("threads@example.com", "Threads");
    await h.request(`/v1/bots/${botId}/email`, {
      method: "POST",
      token: u.token,
      json: { name: "threads" },
    });
    const [a] = await h.handle.db.execute<{ id: string }>(
      sql`select id from public.mail_addresses where local_part = 'threads'`,
    );
    const out = (o: { subject: string; key: string; mid: string; age: string }) =>
      h.handle.db.execute(sql`
        insert into public.mail_messages
          (address_id, org_id, direction, from_addr, to_addrs, subject, thread_key, message_id, verdict, created_at)
        values (${a!.id}::uuid, ${orgId}::uuid, 'out', 'threads@mail.test', '{x@partner.test}', ${o.subject},
                ${o.key}, ${o.mid}, 'allowed', now() - ${o.age}::interval)`);
    await out({ subject: "", key: "x@partner.test|", mid: "<e@mail.test>", age: "1 day" });
    await out({
      subject: "Quote",
      key: "x@partner.test|quote",
      mid: "<q@mail.test>",
      age: "100 days",
    });
    const verdict = async (mid: string) =>
      (
        await h.handle.db.execute<{ verdict: string }>(sql`
          select verdict from public.mail_messages where address_id = ${a!.id}::uuid and message_id = ${mid}`)
      )[0]?.verdict;
    await hook(
      "threads@mail.test",
      mime({
        from: "x@partner.test",
        to: "threads@mail.test",
        subject: "",
        messageId: "<in1@partner.test>",
      }),
    );
    expect(await verdict("<in1@partner.test>")).toBe("stranger");
    await hook(
      "threads@mail.test",
      mime({
        from: "x@partner.test",
        to: "threads@mail.test",
        subject: "Re: Quote",
        messageId: "<in2@partner.test>",
      }),
    );
    expect(await verdict("<in2@partner.test>")).toBe("stranger");
    // In-Reply-To naming the bot's own mail counts at any age.
    const raw = Buffer.from(
      Buffer.from(
        mime({
          from: "x@partner.test",
          to: "threads@mail.test",
          subject: "Re: Quote",
          messageId: "<in3@partner.test>",
        }),
        "base64",
      )
        .toString()
        .replace("Subject:", "In-Reply-To: <q@mail.test>\r\nSubject:"),
    ).toString("base64");
    await hook("threads@mail.test", raw);
    expect(await verdict("<in3@partner.test>")).toBe("allowed");
  });

  it("the stranger routine cap stops routines, not a confirmed thread reply", async () => {
    const { u, orgId, botId } = await setup("busy@example.com", "Busy");
    const claimed = await j(
      await h.request(`/v1/bots/${botId}/email`, {
        method: "POST",
        token: u.token,
        json: { name: "busy" },
      }),
    );
    await h.request("/v1/routines", {
      method: "POST",
      token: u.token,
      json: {
        bot_id: botId,
        name: "Hear all",
        instructions: "Say hi.",
        trigger: "message",
        message: { channel_kind: "email", sender: "*" },
      },
    });
    for (let i = 0; i < 30; i++)
      await h.handle.db.execute(sql`
        insert into public.channel_events (channel_id, org_id, direction, status, sender, detail)
        values (${claimed.channel_id}::uuid, ${orgId}::uuid, 'in', 'routine', ${`s${i}@evil.test`},
                'Started by a new or unconfirmed sender')`);
    await h.handle.db.execute(sql`
      insert into public.mail_messages
        (address_id, org_id, direction, from_addr, to_addrs, subject, thread_key, message_id, verdict)
      select id, ${orgId}::uuid, 'out', 'busy@mail.test', '{vendor@supply.test}', 'Order', 'vendor@supply.test|order',
             '<order@mail.test>', 'allowed'
      from public.mail_addresses where local_part = 'busy'`);
    const before = await runs(botId);
    await hook(
      "busy@mail.test",
      mime({
        from: "vendor@supply.test",
        to: "busy@mail.test",
        subject: "Re: Order",
        messageId: "<v1@supply.test>",
      }),
    );
    // The reply starts its chat run; the routine doesn't.
    expect(await runs(botId)).toBe(before + 1);
    const [r] = await h.handle.db.execute<{ trigger: string }>(sql`
      select trigger from public.runs where bot_id = ${botId}::uuid order by created_at desc limit 1`);
    expect(r?.trigger).toBe("channel");
  });

  it("keeps Cloudflare's own Message-ID, never sending one of ours", async () => {
    const { u, botId } = await setup("cfid@example.com", "Cfid");
    const claimed = await j(
      await h.request(`/v1/bots/${botId}/email`, {
        method: "POST",
        token: u.token,
        json: { name: "cfid" },
      }),
    );
    const ch = (await loadChannel(h.handle.db, claimed.channel_id))!;
    const seen: HostedMailMessage[] = [];
    const cf = {
      name: "cloudflare" as const,
      customMessageId: false,
      send: async (msg: HostedMailMessage) => {
        seen.push(msg);
        return { messageId: "<cf-generated@mail.test>" };
      },
    };
    const err = await sendThrough(
      h.handle.db,
      ch,
      { to: "cfid@acme.org", subject: "hi" },
      "hello",
      fetch,
      "cfid@acme.org|hi",
      undefined,
      undefined,
      cf,
    );
    expect(err).toBeNull();
    expect(Object.keys(seen[0]?.headers ?? {})).not.toContain("Message-ID");
    const [row] = await h.handle.db.execute<{
      message_id: string;
      provider_message_id: string;
    }>(sql`
      select m.message_id, m.provider_message_id from public.mail_messages m
      join public.mail_addresses a on a.id = m.address_id where a.local_part = 'cfid' and m.direction = 'out'`);
    expect(row).toMatchObject({
      message_id: "<cf-generated@mail.test>",
      provider_message_id: "<cf-generated@mail.test>",
    });
  });

  it("the instance owner claims reserved and held names; others can't", async () => {
    const owner = await setup("owner2@example.com", "Ownerbot");
    const other = await setup("notowner@example.com", "Otherbot");
    await h.request("/v1/admin/mail-reserved-names", {
      method: "PUT",
      token: owner.u.token,
      json: { names: ["zenaida"] },
    });
    const check = async (who: typeof owner, name: string) =>
      j(
        await h.request(`/v1/bots/${who.botId}/email/availability?name=${name}`, {
          token: who.u.token,
        }),
      );
    expect((await check(other, "zenaida")).available).toBe(false);
    expect((await check(other, "zenaida")).domain).toBe("mail.test");
    expect((await check(other, "zenaida.helper")).available).toBe(true);
    expect((await check(owner, "zenaida")).available).toBe(true);
    expect(
      (
        await h.request(`/v1/bots/${other.botId}/email`, {
          method: "POST",
          token: other.u.token,
          json: { name: "oliver" },
        })
      ).status,
    ).toBe(400);
    const res = await h.request(`/v1/bots/${owner.botId}/email`, {
      method: "POST",
      token: owner.u.token,
      json: { name: "oliver" },
    });
    expect(res.status).toBe(201);
  });
});

describe("storage, deleting and the sending ceiling (BOT-EMAIL-NEXT-PLAN)", () => {
  const claim = async (email: string, name: string) => {
    const { u, orgId, botId } = await setup(email, name);
    const claimed = await j(
      await h.request(`/v1/bots/${botId}/email`, {
        method: "POST",
        token: u.token,
        json: { name: name.toLowerCase() },
      }),
    );
    const [a] = await h.handle.db.execute<{ id: string }>(
      sql`select id from public.mail_addresses where local_part = ${name.toLowerCase()}`,
    );
    return { u, orgId, botId, claimed, addressId: a!.id };
  };

  it("counts the original and the files, and shows it on the address", async () => {
    const { u, orgId, botId, addressId } = await claim("store@example.com", "Store");
    await hook("store@mail.test", mimeFile({ from: "x@y.test", to: "store@mail.test" }));
    const [r] = await h.handle.db.execute<{ size: number; raw_size: number }>(sql`
      select size, raw_size from public.mail_messages where address_id = ${addressId}::uuid and direction = 'in'`);
    expect(r!.raw_size).toBeGreaterThan(0);
    // The attachment ("hello", 5 bytes) is stored on its own too.
    expect(r!.size).toBe(r!.raw_size + 5);
    // Self-hosted: no mailbox limit.
    const addr = await j(await h.request(`/v1/bots/${botId}/email`, { token: u.token }));
    expect(addr.storage_used).toBeGreaterThanOrEqual(r!.size);
    expect(addr.storage_limit).toBeNull();
    await h.handle.db.execute(sql`
      insert into public.entitlements (org_id, plan_code, limits)
      values (${orgId}::uuid, 'plus', '{"max_mail_addresses": 2, "mail_storage_mb": 500}'::jsonb)`);
    const plus = await j(await h.request(`/v1/bots/${botId}/email`, { token: u.token }));
    expect(plus.storage_limit).toBe(500 * 1024 * 1024);
  });

  it("expires originals after 30 days, keeping the text and the files", async () => {
    const { addressId } = await claim("aged@example.com", "Aged");
    await hook("aged@mail.test", mimeFile({ from: "x@y.test", to: "aged@mail.test" }));
    const [r] = await h.handle.db.execute<{ id: string; raw_key: string; size: number }>(sql`
      select id, raw_key, size from public.mail_messages where address_id = ${addressId}::uuid and direction = 'in'`);
    await h.handle.db.execute(
      sql`update public.mail_messages set created_at = now() - interval '31 days', expires_at = null where id = ${r!.id}::uuid`,
    );
    await purgeExpiredMail(h.handle.db, h.deps.objects);
    const [after] = await h.handle.db.execute<{
      raw_key: string | null;
      size: number;
      files: unknown[];
    }>(sql`
      select raw_key, size, files from public.mail_messages where id = ${r!.id}::uuid`);
    expect(after).toMatchObject({ raw_key: null, size: 5 });
    expect(after!.files).toHaveLength(1);
    expect(
      await h.deps.objects!.get(r!.raw_key).then(
        () => true,
        () => false,
      ),
    ).toBe(false);
  });

  it("deletes mail by id and by age; only people who manage the bot", async () => {
    const { u, botId, addressId } = await claim("deleter@example.com", "Deleter");
    for (const n of [1, 2, 3])
      await hook(
        "deleter@mail.test",
        mime({
          from: "deleter@example.com",
          to: "deleter@mail.test",
          subject: `s${n}`,
          messageId: `<d${n}@example.com>`,
        }),
      );
    // Older than the reply-loop window, so nothing is held back.
    await h.handle.db.execute(sql`
      update public.mail_messages set created_at = now() - interval '2 hours' where address_id = ${addressId}::uuid`);
    const list = await j(await h.request(`/v1/bots/${botId}/email/messages`, { token: u.token }));
    expect(list.items).toHaveLength(3);
    const stranger = await h.user("not-a-member@example.com");
    expect(
      (
        await h.request(`/v1/bots/${botId}/email/messages/${list.items[0].id}`, {
          method: "DELETE",
          token: stranger.token,
        })
      ).status,
    ).toBeGreaterThanOrEqual(403);
    const one = await j(
      await h.request(`/v1/bots/${botId}/email/messages/${list.items[0].id}`, {
        method: "DELETE",
        token: u.token,
      }),
    );
    expect(one.deleted).toBe(1);
    expect(
      (
        await h.request(`/v1/bots/${botId}/email/messages/${list.items[0].id}`, {
          method: "DELETE",
          token: u.token,
        })
      ).status,
    ).toBe(404);
    const older = await j(
      await h.request(`/v1/bots/${botId}/email/messages/delete`, {
        method: "POST",
        token: u.token,
        json: { before: new Date().toISOString() },
      }),
    );
    expect(older.deleted).toBe(2);
    const [left] = await h.handle.db.execute<{ n: number }>(sql`
      select count(*)::int as n from public.mail_messages where address_id = ${addressId}::uuid`);
    expect(left!.n).toBe(0);
    expect(
      (
        await h.request(`/v1/bots/${botId}/email/messages/delete`, {
          method: "POST",
          token: u.token,
          json: {},
        })
      ).status,
    ).toBe(400);
  });

  it("deleting sent mail can't reset the daily cap", async () => {
    const { orgId, botId, claimed } = await claim("capkeep@acme.org", "Capkeep");
    await h.handle.db.execute(sql`
      insert into public.entitlements (org_id, plan_code, limits)
      values (${orgId}::uuid, 'free', '{"max_mail_addresses": 1, "mail_sent_day": 2, "mail_new_day": 0, "mail_storage_mb": 100}'::jsonb)`);
    const ch = (await loadChannel(h.handle.db, claimed.channel_id))!;
    const send = () =>
      sendThrough(
        h.handle.db,
        ch,
        { to: "capkeep@acme.org", subject: "hi" },
        "x",
        fetch,
        undefined,
        undefined,
        undefined,
        h.deps.hostedMail!.sender,
      );
    // The welcome mail was the first; one more fills the cap.
    expect(await send()).toBeNull();
    expect(await send()).toContain("limit");
    const u = (
      await h.handle.db.execute<{ id: string }>(sql`
      select id from public.mail_messages m where m.direction = 'out' and m.address_id =
        (select id from public.mail_addresses where local_part = 'capkeep')`)
    ).map((r) => r.id);
    const res = await deleteKeptMail(
      h.handle.db,
      h.deps.objects,
      (
        await h.handle.db.execute<{ id: string }>(
          sql`select id from public.mail_addresses where local_part = 'capkeep'`,
        )
      )[0]!.id,
      { ids: u },
    );
    expect(res.deleted).toBe(u.length);
    // Held as empty rows: still counted, gone from the inbox.
    expect(await send()).toContain("limit");
    const [held] = await h.handle.db.execute<{ n: number; text: number }>(sql`
      select count(*)::int as n, count(*) filter (where subject <> '')::int as text
      from public.mail_messages where id = any(${`{${u.join(",")}}`}::uuid[]) and deleted_at is not null`);
    expect(held).toMatchObject({ n: u.length, text: 0 });
    void botId;
  });

  it("stops every workspace at the daily ceiling and tells the instance owner", async () => {
    const { claimed } = await claim("ceiling@acme.org", "Ceiling");
    const ch = (await loadChannel(h.handle.db, claimed.channel_id))!;
    const [all] = await h.handle.db.execute<{ n: number }>(sql`
      select count(*)::int as n from public.mail_messages where direction = 'out' and created_at > now() - interval '1 day'`);
    const told: Array<[number, number]> = [];
    const sender = {
      name: "cloudflare" as const,
      customMessageId: false,
      dailyCeiling: all!.n + 1,
      send: async () => ({ messageId: `<c-${Math.random()}@mail.test>` }),
      onCeiling: async (_db: unknown, sent: number, max: number) => {
        told.push([sent, max]);
      },
    };
    const send = () =>
      sendThrough(
        h.handle.db,
        ch,
        { to: "ceiling@acme.org", subject: "hi" },
        "x",
        fetch,
        undefined,
        undefined,
        undefined,
        sender,
      );
    expect(await send()).toBeNull();
    expect(await send()).toContain("Mail is busy right now");
    expect(told.length).toBe(2);
    expect(told[1]![0]).toBe(told[1]![1]);
  });

  it("warns at 90% and points a full mailbox to deleting", async () => {
    const { u, orgId, addressId } = await claim("nearly@example.com", "Nearly");
    await h.handle.db.execute(sql`
      insert into public.entitlements (org_id, plan_code, limits)
      values (${orgId}::uuid, 'free', '{"max_mail_addresses": 1, "mail_sent_day": 20, "mail_new_day": 0, "mail_storage_mb": 1}'::jsonb)`);
    await h.handle.db.execute(sql`
      insert into public.mail_messages (address_id, org_id, direction, from_addr, verdict, size)
      values (${addressId}::uuid, ${orgId}::uuid, 'in', 'old@example.com', 'allowed', ${Math.floor(0.95 * 1024 * 1024)})`);
    expect(
      (
        await hook(
          "nearly@mail.test",
          mime({
            from: "nearly@example.com",
            to: "nearly@mail.test",
            messageId: "<n1@example.com>",
          }),
        )
      ).status,
    ).toBe(200);
    const almost = await h.handle.db.execute<{ id: string }>(sql`
      select id from public.notifications where user_id = ${u.id}::uuid and kind = 'mail_mailbox_almost_full'`);
    expect(almost).toHaveLength(1);
    await h.handle.db.execute(sql`
      update public.mail_messages set size = 1024 * 1024 where address_id = ${addressId}::uuid and from_addr = 'old@example.com'`);
    expect(
      (
        await hook(
          "nearly@mail.test",
          mime({
            from: "nearly@example.com",
            to: "nearly@mail.test",
            messageId: "<n2@example.com>",
          }),
        )
      ).status,
    ).toBe(413);
    const [full] = await h.handle.db.execute<{ payload: { body: string; link: string } }>(sql`
      select payload from public.notifications where user_id = ${u.id}::uuid and kind = 'mail_mailbox_full'`);
    expect(full!.payload.body).toContain("Delete old mail");
    expect(full!.payload.link).toContain("/email");
  });

  it("tells a bot without an address that it may offer one, while there is room", async () => {
    const { orgId, botId } = await setup("offer@example.com", "Offer");
    await h.handle.db.execute(sql`
      insert into public.entitlements (org_id, plan_code, limits)
      values (${orgId}::uuid, 'free', '{"max_mail_addresses": 1}'::jsonb)`);
    expect(await mailHint(h.handle.db, botId)).toBeNull();
    expect(await mailHint(h.handle.db, botId, { offer: true })).toContain("mail.claim");
    await h.handle.db.execute(sql`
      insert into public.entitlements (org_id, plan_code, limits)
      values (${orgId}::uuid, 'free', '{"max_mail_addresses": 0}'::jsonb)`);
    expect(await mailHint(h.handle.db, botId, { offer: true })).toBeNull();
  });
});
