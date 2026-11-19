/** The words a watch shows (D-410): requests, chats and runs, built from the person's own data. */
import { WatchApproval, WatchChat, WatchRun } from "@casama/contracts";
import { createDb, type DbHandle } from "@casama/db";
import { startTestDatabase, type TestDatabase } from "@casama/db/testing";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import {
  approvalDetails,
  approvalTitle,
  buildWatchChat,
  buildWatchRun,
  loadWatchApproval,
  messageAttachments,
  WATCH_LIMITS,
  watchApprovalView,
  watchPrefsFor,
  watchText,
} from "../src/watch.ts";

describe("request words", () => {
  it("says what an email, a message, a payment and an event are in everyday words", () => {
    const email = {
      to: "Dana Cruz <dana@example.com>",
      subject: "Thursday works",
      body: "Hi Dana,\nThursday at 3 is perfect.",
    };
    expect(approvalTitle("composio.gmail.GMAIL_SEND_EMAIL", email)).toBe(
      "Send an email to Dana Cruz",
    );
    expect(approvalDetails("composio.gmail.GMAIL_SEND_EMAIL", email)).toEqual([
      "To: Dana Cruz <dana@example.com>",
      "Subject: Thursday works",
      "Hi Dana,",
    ]);
    expect(
      approvalTitle("channel.send", { channel: "telegram", to: "Sam", text: "On my way" }),
    ).toBe("Send a message to Sam");
    expect(
      approvalDetails("channel.send", { channel: "telegram", to: "Sam", text: "On my way" }),
    ).toEqual(["To: Sam", "Via: telegram", "On my way"]);
    expect(
      approvalTitle("payments.request", {
        merchant: "Acme Hosting",
        amount: 240,
        currency: "USD",
        reason: "Monthly plan",
      }),
    ).toBe("Pay $240.00 to Acme Hosting");
    expect(
      approvalDetails("payments.request", { merchant: "Acme", amount: 1, reason: "Monthly plan" }),
    ).toEqual(["Monthly plan"]);
    expect(
      approvalTitle("mcp.googlecalendar.create_event", {
        summary: "Call with Dana",
        start: "Thu 3pm",
      }),
    ).toBe("Add an event: Call with Dana");
    expect(approvalTitle("shell.exec", { command: "ls" })).toBeNull();
    expect(approvalDetails("shell.exec", { command: "ls" })).toEqual([]);
  });

  it("never shows secrets, tokens or raw arguments", () => {
    const args = {
      to: "dana@example.com",
      password: "hunter2",
      api_key: "sk-live",
      // A made-up key shape, joined at run time so secret scanners don't take it for a real one.
      subject: ["sk", "live", "abcdefghijklmnopqrstuvwxyz0123456789"].join("_"),
      body: { nested: "json" },
    };
    const lines = approvalDetails("gmail.send_email", args);
    expect(lines).toEqual(["To: dana@example.com"]);
    expect(lines.join(" ")).not.toMatch(/hunter2|sk-live|sk_live|nested/);
    expect(approvalDetails("gmail.send_email", { to: "[REDACTED]" })).toEqual([]);
  });

  it("cuts long words with an ellipsis at a word", () => {
    const t = watchText("word ".repeat(400), 300);
    expect(t.cut).toBe(true);
    expect(t.text.length).toBeLessThanOrEqual(300);
    expect(t.text.endsWith("word…")).toBe(true);
    expect(watchText("short", 300)).toEqual({ text: "short", cut: false });
  });

  it("lists cards, pages, files and pictures as one line each, at most three", () => {
    expect(
      messageAttachments([
        { type: "text", text: "hi" },
        { type: "page", page_id: "x", title: "Q4 pricing" },
        { type: "file", path: "media:1", name: "cat.png", mime_type: "image/png" },
        { type: "ui", surface_id: "s", messages: [] },
        { type: "creation", kind: "document", title: "Plan" },
      ]),
    ).toEqual([
      { kind: "page", title: "Q4 pricing" },
      { kind: "image", title: "cat.png" },
      { kind: "card", title: "" },
    ]);
    expect(messageAttachments([{ type: "page", title: "Secret plan" }], true)).toEqual([
      { kind: "page", title: "" },
    ]);
  });

  it("says what a watch may do with a request", () => {
    const row = {
      id: "55555555-5555-4555-8555-555555555555",
      run_id: "44444444-4444-4444-8444-444444444444",
      bot_id: "22222222-2222-4222-8222-222222222222",
      org_id: "11111111-1111-4111-8111-111111111111",
      bot: "Milo",
      bot_avatar: "mascot:focused",
      status: "pending",
      summary: "Milo wants to run gmail.send_email: Thursday",
      tool_name: "gmail.send_email",
      args_redacted: { to: "dana@example.com" },
      risk: "medium",
      created_at: new Date().toISOString(),
      expires_at: new Date(Date.now() + 60_000).toISOString(),
      is_yours: true,
    };
    const v = watchApprovalView(row, { private: false, level: "medium" });
    expect(() => WatchApproval.parse(v)).not.toThrow();
    expect(v).toMatchObject({ title: "Send an email to dana@example.com", can_allow: "hold" });
    expect(watchApprovalView(row, { private: false, level: "low" })).toMatchObject({
      can_allow: "phone",
      why_phone: "setting",
    });
    const priv = watchApprovalView(row, { private: true, level: "medium" });
    expect(priv).toMatchObject({ title: "", details: [], bot: "Milo", risk: "medium" });
    // A tool nobody knows reads as its summary, without "Milo wants to run".
    expect(
      watchApprovalView(
        { ...row, tool_name: "shell.exec", args_redacted: {} },
        {
          private: false,
          level: "medium",
        },
      ).title,
    ).toBe("gmail.send_email: Thursday");
    expect(
      watchApprovalView(
        { ...row, expires_at: new Date(Date.now() - 1000).toISOString() },
        { private: false, level: "medium" },
      ).status,
    ).toBe("expired");
  });
});

let tdb: TestDatabase;
let h: DbHandle;
const ids = { me: "", other: "", org: "", bot: "", conv: "", run: "", done: "", approval: "" };
const one = async <T>(q: Promise<unknown>) => ((await q) as unknown as T[])[0] as T;

beforeAll(async () => {
  tdb = await startTestDatabase();
  h = createDb(tdb.url, { max: 2 });
  const a = tdb.admin;
  ids.me = (
    await one<{ id: string }>(a`insert into auth.users (id, email, aud, role)
      values (gen_random_uuid(), 'watch-me@example.com', 'authenticated', 'authenticated') returning id`)
  ).id;
  ids.other = (
    await one<{ id: string }>(a`insert into auth.users (id, email, aud, role)
      values (gen_random_uuid(), 'watch-other@example.com', 'authenticated', 'authenticated') returning id`)
  ).id;
  ids.org = (
    await one<{ id: string }>(
      a`insert into public.organizations (name, slug) values ('Watch', 'watch-test') returning id`,
    )
  ).id;
  await a`insert into public.memberships (org_id, user_id, role) values
    (${ids.org}, ${ids.me}, 'member'), (${ids.org}, ${ids.other}, 'owner')`;
  ids.bot = (
    await one<{
      id: string;
    }>(a`insert into public.bots (org_id, created_by, name, avatar_url, status)
      values (${ids.org}, ${ids.me}, 'Milo', 'mascot:focused', 'working') returning id`)
  ).id;
  ids.conv = (
    await one<{
      id: string;
    }>(a`insert into public.conversations (org_id, bot_id, created_by, last_message_at)
      values (${ids.org}, ${ids.bot}, ${ids.me}, now()) returning id`)
  ).id;
  // Fourteen messages in one thread (each the parent of the next): the watch shows the last 12.
  let parent: string | null = null;
  for (let i = 0; i < 14; i++) {
    const role = i % 2 ? "assistant" : "user";
    const text =
      i === 13 ? `**Done.** ${"Long reply. ".repeat(200)}` : `Message ${i} ${"x ".repeat(200)}`;
    const content =
      i === 13
        ? [
            { type: "text", text },
            { type: "page", page_id: "p", title: "Q4 pricing" },
          ]
        : [{ type: "text", text }];
    const row: { id: string } = await one<{ id: string }>(a`
      insert into public.messages (org_id, conversation_id, role, content, parent_message_id, created_at)
      values (${ids.org}, ${ids.conv}, ${role}, ${a.json(content)}, ${parent},
              ${new Date(Date.now() - (20 - i) * 60_000).toISOString()}) returning id`);
    parent = row.id;
  }
  await a`update public.conversations set head_message_id = ${parent} where id = ${ids.conv}`;

  ids.run = (
    await one<{ id: string }>(a`
      insert into public.runs (org_id, bot_id, conversation_id, created_by, status, started_at)
      values (${ids.org}, ${ids.bot}, ${ids.conv}, ${ids.me}, 'running', now()) returning id`)
  ).id;
  await a`insert into public.run_events (run_id, seq, org_id, bot_id, type, payload) values
    (${ids.run}, 1, ${ids.org}, ${ids.bot}, 'run.started', '{}'),
    (${ids.run}, 2, ${ids.org}, ${ids.bot}, 'tool.started', ${a.json({ tool: "web.search" })}),
    (${ids.run}, 3, ${ids.org}, ${ids.bot}, 'tool.started', ${a.json({ tool: "web.fetch" })})`;

  // A finished run in an older chat, with its reply.
  const older = await one<{ id: string }>(a`
    insert into public.conversations (org_id, bot_id, created_by, last_message_at)
    values (${ids.org}, ${ids.bot}, ${ids.me}, now() - interval '1 day') returning id`);
  ids.done = (
    await one<{ id: string }>(a`
      insert into public.runs (org_id, bot_id, conversation_id, created_by, status, started_at, ended_at)
      values (${ids.org}, ${ids.bot}, ${older.id}, ${ids.me}, 'completed', now(), now()) returning id`)
  ).id;
  await a`insert into public.messages (org_id, conversation_id, role, content, run_id)
    values (${ids.org}, ${older.id}, 'assistant', ${a.json([{ type: "text", text: "All booked." }])}, ${ids.done})`;
  await a`update public.conversations set last_message_at = now() - interval '1 day' where id = ${older.id}`;
  await a`update public.conversations set last_message_at = now() where id = ${ids.conv}`;
}, 600_000);

afterAll(async () => {
  await h?.close();
  await tdb?.stop();
});

const chat = (o: Partial<Parameters<typeof buildWatchChat>[1]> = {}) =>
  buildWatchChat(h.db, {
    userId: ids.me,
    botId: ids.bot,
    private: false,
    hideReplyText: false,
    speech: true,
    ...o,
  });

describe("a bot's chat", () => {
  it("shows the last twelve messages, oldest first, cut to fit", async () => {
    const c = await chat();
    expect(c).not.toBeNull();
    expect(() => WatchChat.parse(c)).not.toThrow();
    expect(c?.conversation_id).toBe(ids.conv);
    expect(c?.messages).toHaveLength(WATCH_LIMITS.messages);
    const last = c?.messages.at(-1);
    expect(last?.role).toBe("assistant");
    expect(last?.text.startsWith("Done. Long reply.")).toBe(true);
    expect(last?.text.length).toBeLessThanOrEqual(WATCH_LIMITS.latestChars);
    expect(last).toMatchObject({ cut: true, can_speak: true });
    expect(last?.attachments).toEqual([{ kind: "page", title: "Q4 pricing" }]);
    const older = c?.messages[0];
    expect(older?.text.length).toBeLessThanOrEqual(WATCH_LIMITS.olderChars);
    expect(older?.cut).toBe(true);
    expect(older?.can_speak).toBe(false);
    expect(c?.run_id).toBe(ids.run);
    expect(c?.link).toBe(`/bots/${ids.bot}/chat?c=${ids.conv}`);
  });

  it("hides reply text and private words", async () => {
    const hidden = await chat({ hideReplyText: true });
    expect(hidden?.messages.filter((m) => m.role === "assistant").every((m) => m.text === "")).toBe(
      true,
    );
    expect(hidden?.messages.find((m) => m.role === "user")?.text).not.toBe("");
    const priv = await chat({ private: true });
    expect(priv?.messages.every((m) => m.text === "" && !m.can_speak)).toBe(true);
    expect(priv?.messages.at(-1)?.attachments).toEqual([{ kind: "page", title: "" }]);
  });

  it("is only the person's, in their workspace", async () => {
    expect(await chat({ orgId: "00000000-0000-4000-8000-000000000000" })).toBeNull();
    expect(await chat({ conversationId: "00000000-0000-4000-8000-000000000000" })).toBeNull();
  });
});

describe("a run", () => {
  const run = (id: string, o: Partial<Parameters<typeof buildWatchRun>[2]> = {}) =>
    buildWatchRun(h.db, id, {
      userId: ids.me,
      private: false,
      level: "medium",
      hideReplyText: false,
      speech: true,
      ...o,
    });

  it("says what it is doing in the island's words", async () => {
    const r = await run(ids.run);
    expect(() => WatchRun.parse(r)).not.toThrow();
    expect(r).toMatchObject({
      phase: "working",
      step: "Reading a web page",
      steps: 2,
      approval: null,
      reply: null,
      bot: "Milo",
      link: `/bots/${ids.bot}/chat?c=${ids.conv}`,
    });
  });

  it("becomes the request when it needs an OK", async () => {
    ids.approval = (
      await one<{ id: string }>(tdb.admin`
        insert into public.approvals (org_id, bot_id, run_id, call_id, tool_name, args_redacted, summary, risk)
        values (${ids.org}, ${ids.bot}, ${ids.run}, 'c9', 'channel.send',
                ${tdb.admin.json({ channel: "telegram", to: "Sam", text: "Hello" })}, 'Milo wants to run channel.send', 'high')
        returning id`)
    ).id;
    await tdb.admin`update public.runs set status = 'waiting_approval' where id = ${ids.run}`;
    const r = await run(ids.run);
    expect(r).toMatchObject({ phase: "needs_ok", step: "Sending a message" });
    expect(r?.approval).toMatchObject({
      id: ids.approval,
      title: "Send a message to Sam",
      can_allow: "phone",
      why_phone: "high_risk",
    });
    expect(r?.link).toBe(`/approvals/${ids.approval}`);
    const a = await loadWatchApproval(h.db, ids.approval, {
      userId: ids.me,
      private: false,
      level: "medium",
    });
    expect(a?.org_id).toBe(ids.org);
    expect(
      await loadWatchApproval(h.db, ids.approval, {
        userId: ids.me,
        orgId: "00000000-0000-4000-8000-000000000000",
        private: false,
        level: "medium",
      }),
    ).toBeNull();
  });

  it("carries the reply once it finished", async () => {
    const r = await run(ids.done);
    expect(r).toMatchObject({ phase: "finished", step: "Finished" });
    expect(r?.reply).toMatchObject({ role: "assistant", text: "All booked.", can_speak: true });
    expect(r?.ended_at).toBeTruthy();
    const priv = await run(ids.done, { private: true });
    expect(priv).toMatchObject({ step: "" });
    expect(priv?.reply?.text).toBe("");
  });

  it("reads the person's settings, with defaults", async () => {
    expect(await watchPrefsFor(h.db, ids.me)).toEqual({
      allow: "medium",
      show_details: true,
      quick_replies: ["Yes", "No", "Tell me more", "Not now"],
    });
    await tdb.admin`insert into public.watch_prefs (user_id, allow, quick_replies) values (${ids.me}, 'low', ${["Sure"]})`;
    expect(await watchPrefsFor(h.db, ids.me)).toMatchObject({
      allow: "low",
      quick_replies: ["Sure"],
    });
  });
});
