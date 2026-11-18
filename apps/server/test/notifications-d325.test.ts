/** D-325: reply pushes, the chat on screen stays quiet, per-kind settings, per-platform fields. */
import {
  fcmMessage,
  NotificationService,
  type PushMessage,
  RecordingPushSender,
  type ReplyRun,
  replyPush,
} from "@casama/agent";
import { afterAll, beforeAll, beforeEach, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
let user: { id: string; token: string };
let orgId: string;
let botId: string;
let casamaBotId: string;
let conversationId: string;
const push = new RecordingPushSender();
let svc: NotificationService;

const last = () => push.sent.at(-1)?.message as PushMessage;
const latestRow = async () =>
  (
    await h.tdb.admin<
      {
        kind: string;
        push_status: string;
        read_at: Date | null;
        urgency: string | null;
        payload: Record<string, unknown>;
      }[]
    >`select kind, push_status, read_at, urgency, payload from public.notifications
      where user_id = ${user.id} order by created_at desc limit 1`
  )[0];

async function run(
  o: { trigger?: string; ageSeconds?: number; parent?: string | null; bot?: string } = {},
) {
  const [r] = await h.tdb.admin<{ id: string }[]>`
    insert into public.runs (org_id, bot_id, conversation_id, created_by, trigger, status, created_at, started_at, parent_run_id)
    values (${orgId}, ${o.bot ?? botId}, ${conversationId}, ${user.id}, ${o.trigger ?? "chat"}, 'completed',
            now() - make_interval(secs => ${o.ageSeconds ?? 20}), now() - make_interval(secs => ${o.ageSeconds ?? 20}),
            ${o.parent ?? null})
    returning id`;
  return r!.id;
}

const replyRun = (runId: string, over: Partial<ReplyRun> = {}): ReplyRun => ({
  runId,
  orgId,
  botId,
  botName: "Atlas",
  conversationId,
  createdBy: user.id,
  trigger: "chat",
  parentRunId: null,
  ...over,
});

beforeAll(async () => {
  h = await startHarness();
  user = await h.user("d325@example.com");
  orgId = (
    await j(await h.request("/v1/orgs", { method: "POST", token: user.token, json: { name: "N" } }))
  ).id;
  const [b] = await h.tdb.admin<{ id: string }[]>`
    insert into public.bots (org_id, name, created_by) values (${orgId}, 'Atlas', ${user.id}) returning id`;
  botId = b!.id;
  const [cb] = await h.tdb.admin<{ id: string }[]>`
    insert into public.bots (org_id, name, created_by) values (${orgId}, 'Casama', ${user.id}) returning id`;
  casamaBotId = cb!.id;
  const [c] = await h.tdb.admin<{ id: string }[]>`
    insert into public.conversations (org_id, bot_id, title, created_by)
    values (${orgId}, ${botId}, 'Trip to Lisbon', ${user.id}) returning id`;
  conversationId = c!.id;
  await h.tdb
    .admin`insert into public.devices (user_id, fcm_token, platform) values (${user.id}, 'tok-ios', 'ios')`;
  svc = new NotificationService(h.handle.db, push);
}, 60_000);
afterAll(async () => h?.stop());
beforeEach(async () => {
  push.sent.length = 0;
  await h.tdb
    .admin`update public.profiles set quiet_hours = null, push_prefs = '{}' where user_id = ${user.id}`;
  await h.tdb.admin`delete from public.chat_focus where user_id = ${user.id}`;
});

describe("FCM message per platform", () => {
  it("carries channel, priority, thread, badge, interruption and the web tag", () => {
    const m = fcmMessage("t", {
      title: "Atlas",
      body: "Done",
      link: "/x",
      tag: "reply-c",
      channel: "replies",
      priority: "high",
      threadId: "c",
      badge: 2,
      interruption: "time-sensitive",
      category: "APPROVAL",
      data: { kind: "reply" },
    }) as Record<string, any>;
    expect(m.android).toEqual({
      priority: "HIGH",
      notification: { tag: "reply-c", channel_id: "replies" },
    });
    expect(m.apns.headers).toEqual({ "apns-collapse-id": "reply-c", "apns-priority": "10" });
    expect(m.apns.payload.aps).toEqual({
      sound: "default",
      category: "APPROVAL",
      "thread-id": "c",
      badge: 2,
      "interruption-level": "time-sensitive",
    });
    expect(m.webpush).toEqual({ notification: { tag: "reply-c" } });
    expect(m.data).toEqual({ kind: "reply", link: "/x", tag: "reply-c" });
  });

  it("keeps the old shape when no new field is set", () => {
    const m = fcmMessage("t", { title: "a", body: "b" }) as Record<string, any>;
    expect(m).toEqual({
      token: "t",
      notification: { title: "a", body: "b" },
      data: {},
      apns: { payload: { aps: { sound: "default" } } },
    });
  });

  it("puts the channel and words in data-only pushes", () => {
    const m = fcmMessage("t", {
      title: "a",
      body: "b",
      dataOnly: true,
      channel: "needs_you",
      category: "APPROVAL",
    }) as Record<string, any>;
    expect(m.data).toEqual({ title: "a", body: "b", category: "APPROVAL", channel: "needs_you" });
    expect(m.android).toEqual({ priority: "HIGH" });
  });
});

describe("reply push", () => {
  it("tells the person who asked when a long chat run finishes", async () => {
    await replyPush(h.handle.db, svc, replyRun(await run()), {
      ok: true,
      text: "**Booked** the flight.",
    });
    expect(push.sent).toHaveLength(1);
    const m = last();
    expect(m).toMatchObject({
      title: "Atlas",
      body: "Booked the flight.",
      link: `/bots/${botId}/chat?c=${conversationId}`,
      tag: `reply-${conversationId}`,
      channel: "replies",
      priority: "high",
      threadId: conversationId,
    });
    expect(m.data).toMatchObject({
      kind: "reply",
      conversation_id: conversationId,
      bot_id: botId,
      tag: `reply-${conversationId}`,
    });
    const row = await latestRow();
    // Not proactive: it never counts toward the five-a-day cap.
    expect(row).toMatchObject({ kind: "reply", push_status: "sent", urgency: null });
  });

  it("stays quiet for quick runs, voice, chat apps, routines, sub-runs and no asker", async () => {
    await replyPush(h.handle.db, svc, replyRun(await run({ ageSeconds: 2 })), {
      ok: true,
      text: "x",
    });
    for (const trigger of ["voice", "message", "routine", "schedule"])
      await replyPush(h.handle.db, svc, replyRun(await run({ trigger }), { trigger }), {
        ok: true,
        text: "x",
      });
    const parent = await run();
    await replyPush(h.handle.db, svc, replyRun(await run(), { parentRunId: parent }), {
      ok: true,
      text: "x",
    });
    await replyPush(h.handle.db, svc, replyRun(await run(), { createdBy: null }), {
      ok: true,
      text: "x",
    });
    expect(push.sent).toHaveLength(0);
  });

  it("works for @mentions too", async () => {
    await replyPush(
      h.handle.db,
      svc,
      replyRun(await run({ trigger: "mention" }), { trigger: "mention" }),
      { ok: true, text: "On it" },
    );
    expect(push.sent).toHaveLength(1);
  });

  it("says Couldn't finish when the run failed", async () => {
    await replyPush(h.handle.db, svc, replyRun(await run()), {
      ok: false,
      message: "The model provider is down.",
    });
    expect(last().body).toBe("Couldn't finish: The model provider is down.");
    expect((await latestRow())?.payload.failed).toBe(true);
  });

  it("uses the chat's title for the default bot, and a card-only reply still says something", async () => {
    await replyPush(
      h.handle.db,
      svc,
      replyRun(await run({ bot: casamaBotId }), { botId: casamaBotId, botName: "Casama" }),
      { ok: true, text: "" },
    );
    expect(last()).toMatchObject({ title: "Trip to Lisbon", body: "Sent you a card" });
  });

  it("doesn't buzz a chat that's on screen on any device, but a stale focus doesn't count", async () => {
    await h.tdb
      .admin`insert into public.chat_focus (user_id, client_id, conversation_id) values (${user.id}, 'mac-install-1', ${conversationId})`;
    await replyPush(h.handle.db, svc, replyRun(await run()), { ok: true, text: "x" });
    expect(push.sent).toHaveLength(0);
    const row = await latestRow();
    expect(row?.push_status).toBe("off");
    expect(row?.read_at).not.toBeNull();
    await h.tdb
      .admin`update public.chat_focus set updated_at = now() - interval '60 seconds' where user_id = ${user.id}`;
    await replyPush(h.handle.db, svc, replyRun(await run()), { ok: true, text: "x" });
    expect(push.sent).toHaveLength(1);
  });

  it("waits for quiet hours to end", async () => {
    await h.tdb
      .admin`update public.profiles set timezone = 'UTC', quiet_hours = ${h.tdb.admin.json({ enabled: true, start: "00:00", end: "23:59" })} where user_id = ${user.id}`;
    await replyPush(h.handle.db, svc, replyRun(await run()), { ok: true, text: "x" });
    expect(push.sent).toHaveLength(0);
    expect((await latestRow())?.push_status).toBe("deferred");
  });

  it("hides the words when asked", async () => {
    await h.tdb
      .admin`update public.profiles set push_prefs = '{"hide_reply_text": true}' where user_id = ${user.id}`;
    await replyPush(h.handle.db, svc, replyRun(await run()), { ok: true, text: "Secret plans" });
    expect(last().body).toBe("Atlas replied");
    // The inbox row keeps the words; only the lock screen hides them.
    expect((await latestRow())?.payload.body).toBe("Secret plans");
    await replyPush(h.handle.db, svc, replyRun(await run()), { ok: false, message: "x" });
    expect(last().body).toBe("Couldn't finish");
  });
});

describe("per-kind settings", () => {
  it("keeps the inbox row and sends no push for a group that's off", async () => {
    await h.tdb
      .admin`update public.profiles set push_prefs = '{"routines": false}' where user_id = ${user.id}`;
    await svc.notify(user.id, orgId, "routine_result", { title: "Done", body: "x", bot_id: botId });
    expect(push.sent).toHaveLength(0);
    expect(await latestRow()).toMatchObject({
      kind: "routine_result",
      push_status: "off",
      read_at: null,
    });
    await svc.notify(user.id, orgId, "credits_low", { title: "Low", body: "x" });
    expect(push.sent).toHaveLength(1);
    expect(last()).toMatchObject({
      channel: "account",
      priority: "normal",
      threadId: "credits_low",
    });
  });
});

describe("approval pushes", () => {
  it("get Approve/Deny below high risk, time-sensitive when someone waits, and Android draws them itself", async () => {
    await h.tdb
      .admin`insert into public.devices (user_id, fcm_token, platform, push_version) values (${user.id}, 'tok-android-new', 'android', 2)`;
    await h.tdb
      .admin`insert into public.devices (user_id, fcm_token, platform) values (${user.id}, 'tok-android-old', 'android')`;
    await svc.notify(user.id, orgId, "approval_request", {
      title: "Atlas needs your approval",
      body: "Send email",
      approval_id: "00000000-0000-0000-0000-00000000a001",
      bot_id: botId,
      risk: "medium",
      urgent: true,
      conversation_id: conversationId,
    });
    expect(push.sent).toHaveLength(2);
    const plain = push.sent.find((s) => !s.message.dataOnly)!;
    const drawn = push.sent.find((s) => s.message.dataOnly)!;
    expect(plain.tokens.sort()).toEqual(["tok-android-old", "tok-ios"]);
    expect(drawn.tokens).toEqual(["tok-android-new"]);
    expect(plain.message).toMatchObject({
      category: "APPROVAL",
      channel: "needs_you",
      priority: "high",
      interruption: "time-sensitive",
    });
    expect(drawn.message.data).toMatchObject({
      approval_id: "00000000-0000-0000-0000-00000000a001",
      risk: "medium",
      kind: "approval_request",
    });

    push.sent.length = 0;
    await svc.notify(user.id, orgId, "approval_request", {
      title: "Atlas needs your approval",
      body: "Pay",
      approval_id: "00000000-0000-0000-0000-00000000a002",
      bot_id: botId,
      risk: "high",
    });
    for (const s of push.sent) {
      expect(s.message.category).toBeUndefined();
      expect(s.message.interruption).toBeUndefined();
    }
    await h.tdb.admin`delete from public.devices where fcm_token like 'tok-android-%'`;
  });
});

describe("badge", () => {
  it("counts unread notifications, not requests", async () => {
    await h.tdb.admin`update public.notifications set read_at = now() where user_id = ${user.id}`;
    await svc.notify(user.id, orgId, "credits_low", { title: "Low", body: "x" });
    expect(last().badge).toBe(1);
    await svc.notify(user.id, orgId, "approval_request", {
      title: "A",
      body: "x",
      approval_id: "00000000-0000-0000-0000-00000000a003",
      risk: "low",
    });
    // The approval row isn't counted as unread (no pending approvals rows exist here).
    expect(last().badge).toBe(1);
    expect(await svc.badge(user.id)).toBe(1);
  });
});
