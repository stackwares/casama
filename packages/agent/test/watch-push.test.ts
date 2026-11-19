/** Pushes a watch reads (D-410, docs/WATCH-PROTOCOL.md §4): the watch's kinds and direct pushes. */

import {
  createServer,
  type Http2Server,
  type IncomingHttpHeaders,
  type ServerHttp2Stream,
} from "node:http2";
import type { AddressInfo } from "node:net";
import { createDb, type DbHandle } from "@casama/db";
import { startTestDatabase, type TestDatabase } from "@casama/db/testing";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import {
  ApnsBatchError,
  ApnsClient,
  ApnsWatchSender,
  apnsAlertBody,
  apnsReason,
  type WatchPushTarget,
  watchAppTopic,
} from "../src/apns.ts";
import {
  fcmMessage,
  NotificationService,
  type PushMessage,
  type PushSender,
  RecordingPushSender,
  watchGeneralText,
  watchKind,
} from "../src/notifications.ts";
import { PRIVATE_PUSH_BODY, PRIVATE_PUSH_TITLE, withoutText } from "../src/push-relay.ts";
import { loadWatchApproval, watchCanAllow } from "../src/watch.ts";

describe("watch kinds", () => {
  it("map the inbox's kinds to the watch's, leaving `kind` to the phones", () => {
    expect(watchKind("approval_request")).toBe("approval");
    expect(watchKind("suggestion")).toBe("suggestion");
    expect(watchKind("reply")).toBe("reply");
    expect(watchKind("reply", { failed: true })).toBe("failed");
    expect(watchKind("routine_result")).toBe("routine");
    expect(watchKind("routine_result", { brief: true })).toBe("brief");
    expect(watchKind("checkin_summary")).toBe("brief");
    expect(watchKind("takeover")).toBe("takeover");
    expect(watchKind("member_joined")).toBe("other");
  });

  it("go to the watch app's own topic as an alert with the phone copy's category and data", () => {
    expect(watchAppTopic()).toBe("ai.casama.app.watchkitapp");
    const body = JSON.parse(
      apnsAlertBody({
        title: "Ada",
        body: "All booked.",
        category: "REPLY",
        threadId: "c1",
        data: { watch_kind: "reply", message_id: "m1" },
        link: "/bots/b/chat",
        tag: "n-1",
      }),
    ) as { aps: Record<string, unknown>; watch_kind: string; link: string };
    expect(body.aps).toMatchObject({
      alert: { title: "Ada", body: "All booked." },
      category: "REPLY",
      "thread-id": "c1",
    });
    expect(body.watch_kind).toBe("reply");
    expect(body.link).toBe("/bots/b/chat");
  });

  it("have general words for when details are off: the bot and what kind of thing happened", () => {
    expect(watchGeneralText("approval", "Ada")).toEqual({ title: "Ada", body: "Needs your OK" });
    expect(watchGeneralText("suggestion", "Ada").body).toBe("Has a suggestion");
    expect(watchGeneralText("reply", "Ada").body).toBe("Replied");
    expect(watchGeneralText("failed", "Ada").body).toBe("Couldn't finish");
    expect(watchGeneralText("other")).toEqual({ title: "Casama", body: "New activity" });
  });

  it("give the relay nothing to read with private notifications on, in the data either", () => {
    const wear: PushMessage = {
      title: "Ada needs your approval",
      body: "Ada wants to run mail.send: Lunch",
      dataOnly: true,
      data: { watch_kind: "approval", approval_id: "a1", title: "old copy", body: "old copy" },
    };
    const bare = withoutText(wear);
    expect(JSON.stringify(bare)).not.toMatch(/Lunch|old copy|needs your approval/);
    expect(bare.data).toEqual({ watch_kind: "approval", approval_id: "a1" });
    // The cloud's sender puts the words a Wear OS watch reads back into the data: the bare ones.
    expect((fcmMessage("t", bare) as { data: Record<string, string> }).data).toMatchObject({
      title: PRIVATE_PUSH_TITLE,
      body: PRIVATE_PUSH_BODY,
      approval_id: "a1",
    });
  });
});

let tdb: TestDatabase;
let h: DbHandle;
/** The worker's own least-privilege role: it sends the pushes, and can't read as a person. */
let worker: DbHandle;
const ids: Record<string, string> = {};

/** A push sender that says some tokens are gone. */
const goneTokens = (gone: string[]): PushSender => ({
  async send(tokens: string[]) {
    return { invalidTokens: tokens.filter((t) => gone.includes(t)) };
  },
  async sendCall() {
    return { invalidTokens: [] };
  },
});

class RecordingWatch {
  readonly sent: Array<{ targets: WatchPushTarget[]; message: PushMessage }> = [];
  readonly gone: string[];
  constructor(gone: string[] = []) {
    this.gone = gone;
  }
  async sendWatch(targets: WatchPushTarget[], message: PushMessage) {
    this.sent.push({ targets, message });
    return { invalidTokens: targets.map((t) => t.token).filter((t) => this.gone.includes(t)) };
  }
}

const one = async <T>(q: Promise<unknown>) => ((await q) as T[])[0] as T;

beforeAll(async () => {
  tdb = await startTestDatabase();
  h = createDb(tdb.url, { max: 2 });
  await tdb.admin.unsafe("alter role casama_worker login password 'casama-worker-test'");
  worker = createDb(tdb.url.replace("postgres@", "casama_worker:casama-worker-test@"), { max: 2 });
  const a = tdb.admin;
  ids.me = (
    await one<{ id: string }>(a`insert into auth.users (id, email, aud, role)
      values (gen_random_uuid(), 'watch-push@example.com', 'authenticated', 'authenticated') returning id`)
  ).id;
  ids.org = (
    await one<{ id: string }>(
      a`insert into public.organizations (name, slug) values ('Push', 'watch-push') returning id`,
    )
  ).id;
  ids.otherOrg = (
    await one<{ id: string }>(
      a`insert into public.organizations (name, slug) values ('Other', 'watch-push-2') returning id`,
    )
  ).id;
  await a`insert into public.memberships (org_id, user_id, role) values
    (${ids.org}, ${ids.me}, 'owner'), (${ids.otherOrg}, ${ids.me}, 'owner')`;
  await a`insert into public.devices (user_id, platform, fcm_token) values (${ids.me}, 'ios', 'phone-1')`;
  // New accounts get quiet hours (22:00 to 07:00): off, so pushes go now whatever the clock says.
  await a`update public.profiles set quiet_hours = null where user_id = ${ids.me as string}`;
  const key = (n: number) => n.toString(16).padStart(64, "0");
  await a`insert into public.watch_keys (user_id, org_id, platform, key_hash, name, push_token, push_kind, push_sandbox)
    values (${ids.me}, ${ids.org}, 'watchos', ${key(1)}, 'Apple Watch', ${"ab".repeat(32)}, 'apns', true),
           (${ids.me}, ${ids.org}, 'wearos', ${key(2)}, 'Pixel Watch', 'wear-token-1', 'fcm', null),
           (${ids.me}, ${ids.otherOrg}, 'wearos', ${key(3)}, 'Work watch', 'wear-token-2', 'fcm', null),
           (${ids.me}, ${ids.otherOrg}, 'watchos', ${key(4)}, 'Work Apple Watch', ${"cd".repeat(32)}, 'apns', false)`;
  ids.bot = (
    await one<{ id: string }>(a`insert into public.bots (org_id, created_by, name)
      values (${ids.org}, ${ids.me}, 'Ada') returning id`)
  ).id;
}, 600_000);

/** A request waiting on the person, as the worker leaves one. */
const approval = async (risk: "low" | "medium" | "high", tool = "mail.send") => {
  const run = await one<{ id: string }>(tdb.admin`
    insert into public.runs (org_id, bot_id, trigger, status, created_by)
    values (${ids.org as string}, ${ids.bot as string}, 'chat', 'waiting_approval', ${ids.me as string}) returning id`);
  return (
    await one<{ id: string }>(tdb.admin`
      insert into public.approvals (org_id, bot_id, run_id, call_id, tool_name, args_redacted, summary, risk, expires_at)
      values (${ids.org as string}, ${ids.bot as string}, ${run.id}, 'c1', ${tool},
              ${tdb.admin.json({ to: "dana@example.com", subject: "Lunch" })}, 'Ada wants to run mail.send: Lunch',
              ${risk}, now() + interval '1 hour') returning id`)
  ).id;
};
const ask = (n: NotificationService, approvalId: string, risk: string) =>
  n.notify(ids.me as string, ids.org as string, "approval_request", {
    title: "Ada needs your approval",
    body: "Ada wants to run mail.send: Lunch",
    link: `/approvals/${approvalId}`,
    bot_id: ids.bot,
    approval_id: approvalId,
    risk,
  });

afterAll(async () => {
  await worker?.close();
  await h?.close();
  await tdb?.stop();
});

describe("direct watch pushes", () => {
  it("reach the workspace's watches, Wear OS as data and Apple straight to Apple", async () => {
    const push = new RecordingPushSender();
    const watch = new RecordingWatch();
    const n = new NotificationService(h.db, push);
    n.watch = watch;
    await n.notify(ids.me as string, ids.org as string, "reply", {
      title: "Ada",
      body: "All booked.",
      link: "/bots/x/chat",
    });
    const phone = push.sent.find((s) => s.tokens.includes("phone-1"));
    expect(phone?.message.category).toBe("REPLY");
    // Every copy says which workspace it is about.
    expect(phone?.message.data).toMatchObject({
      kind: "reply",
      watch_kind: "reply",
      org_id: ids.org,
    });
    expect(phone?.message.data).not.toHaveProperty("can_allow");
    // A tag, so the iPhone's mirrored copy and the watch's own fold into one.
    expect(phone?.message.tag).toMatch(/^n-/);
    const wear = push.sent.find((s) => s.tokens.includes("wear-token-1"));
    expect(wear?.message.dataOnly).toBe(true);
    expect(wear?.message).toMatchObject({ title: "Ada", body: "All booked." });
    expect(wear?.message.data).toMatchObject({
      watch_kind: "reply",
      user_id: ids.me,
      org_id: ids.org,
    });
    // The words reach a Wear OS watch in the data, put there once by the sender.
    expect(wear?.message.data).not.toHaveProperty("title");
    expect(
      (fcmMessage("t", wear?.message as PushMessage) as { data: Record<string, string> }).data,
    ).toMatchObject({ title: "Ada", body: "All booked.", watch_kind: "reply", org_id: ids.org });
    // A Wear OS watch signed in to another workspace hears it too (it stops the phone's
    // notifications from bridging); `org_id` tells it this one isn't its own to answer.
    expect(wear?.tokens).toEqual(["wear-token-1", "wear-token-2"]);
    // An Apple Watch hears only about its own workspace: the iPhone mirrors the rest.
    expect(watch.sent).toHaveLength(1);
    expect(watch.sent[0]?.targets).toEqual([{ token: "ab".repeat(32), sandbox: true }]);
    expect(watch.sent[0]?.message.tag).toBe(phone?.message.tag);
    expect(watch.sent[0]?.message.data).toMatchObject({ org_id: ids.org });
  });

  it("reach an Apple Watch once when an old key in another workspace still holds its token", async () => {
    // A watch signed out and in again keeps Apple's token: the old key's row can outlive it.
    const stale = "f".repeat(64);
    await tdb.admin`insert into public.watch_keys (user_id, org_id, platform, key_hash, name, push_token, push_kind, push_sandbox)
      values (${ids.me as string}, ${ids.otherOrg as string}, 'watchos', ${stale}, 'Old key', ${"ab".repeat(32)}, 'apns', true)`;
    try {
      const watch = new RecordingWatch();
      const n = new NotificationService(h.db, new RecordingPushSender());
      n.watch = watch;
      await n.notify(ids.me as string, ids.org as string, "reply", {
        title: "Ada",
        body: "Done.",
        link: "/bots/x/chat",
      });
      expect(watch.sent).toHaveLength(1);
      expect(watch.sent[0]?.targets).toEqual([{ token: "ab".repeat(32), sandbox: true }]);
    } finally {
      await tdb.admin`delete from public.watch_keys where key_hash = ${stale}`;
    }
  });

  it("tell a watch whether it may allow a request: tap, hold or the phone", async () => {
    const seen = async (risk: "low" | "medium" | "high", tool?: string) => {
      const push = new RecordingPushSender();
      const watch = new RecordingWatch();
      // As the worker sends it: with its own role, which can't take the person's session.
      const n = new NotificationService(worker.db, push);
      n.watch = watch;
      await ask(n, await approval(risk, tool), risk);
      return {
        phone: push.sent.find((s) => s.tokens.includes("phone-1"))?.message,
        wear: push.sent.find((s) => s.tokens.includes("wear-token-1"))?.message,
        apple: watch.sent[0]?.message,
      };
    };
    const low = await seen("low");
    expect(low.wear?.data).toMatchObject({ watch_kind: "approval", risk: "low", can_allow: "tap" });
    expect(low.apple?.data).toMatchObject({ can_allow: "tap" });
    expect(low.apple?.category).toBe("APPROVAL");
    // The phone's copy is as it was.
    expect(low.phone?.data).not.toHaveProperty("can_allow");
    expect((await seen("medium")).wear?.data?.can_allow).toBe("hold");
    expect((await seen("high")).apple?.data?.can_allow).toBe("phone");
    // A paid data call is medium risk and still the phone's.
    expect((await seen("medium", "data.call")).wear?.data?.can_allow).toBe("phone");
    // The person's own limit counts.
    await tdb.admin`insert into public.watch_prefs (user_id, allow) values (${ids.me as string}, 'low')
      on conflict (user_id) do update set allow = 'low'`;
    expect((await seen("medium")).wear?.data?.can_allow).toBe("phone");
    expect((await seen("low")).wear?.data?.can_allow).toBe("tap");
    await tdb.admin`update public.watch_prefs set allow = 'medium' where user_id = ${ids.me as string}`;
    // Someone else's run is theirs only as an owner or admin, and (as for a watch key, which has
    // no second sign-in step) not in a workspace that asks owners for one.
    const other = (
      await one<{ id: string }>(tdb.admin`insert into auth.users (id, email, aud, role)
        values (gen_random_uuid(), 'watch-push-2@example.com', 'authenticated', 'authenticated') returning id`)
    ).id;
    const theirs = await approval("low");
    await tdb.admin`update public.runs set created_by = ${other}
      where id = (select run_id from public.approvals where id = ${theirs})`;
    const mine = { userId: ids.me as string, level: "medium" as const };
    expect(await watchCanAllow(worker.db, theirs, mine)).toBe("tap");
    // The same answer the watch's own view of it gives.
    expect((await loadWatchApproval(h.db, theirs, { ...mine, private: true }))?.can_allow).toBe(
      "tap",
    );
    await tdb.admin`update public.organizations set require_mfa = true where id = ${ids.org as string}`;
    expect(await watchCanAllow(worker.db, theirs, mine)).toBe("phone");
    expect((await loadWatchApproval(h.db, theirs, { ...mine, private: true }))?.can_allow).toBe(
      "phone",
    );
    await tdb.admin`update public.organizations set require_mfa = false where id = ${ids.org as string}`;
    expect(await watchCanAllow(worker.db, crypto.randomUUID(), mine)).toBe("phone");
  });

  it("carry general words to watches when details are off; the phone's copy keeps its own", async () => {
    await tdb.admin`insert into public.watch_prefs (user_id, show_details) values (${ids.me as string}, false)
      on conflict (user_id) do update set show_details = false`;
    try {
      const push = new RecordingPushSender();
      const watch = new RecordingWatch();
      const n = new NotificationService(worker.db, push);
      n.watch = watch;
      const id = await approval("low");
      await ask(n, id, "low");
      const phone = push.sent.find((s) => s.tokens.includes("phone-1"))?.message;
      expect(phone).toMatchObject({ title: "Ada needs your approval" });
      expect(phone?.body).toContain("Lunch");
      for (const m of [
        push.sent.find((s) => s.tokens.includes("wear-token-1"))?.message,
        watch.sent[0]?.message,
      ]) {
        expect(m).toMatchObject({ title: "Ada", body: "Needs your OK" });
        expect(JSON.stringify(m)).not.toMatch(/Lunch|mail\.send|dana@/);
        // What it is and where it leads stay.
        expect(m?.data).toMatchObject({
          watch_kind: "approval",
          approval_id: id,
          org_id: ids.org,
          can_allow: "tap",
          bot_name: "Ada",
        });
        expect(m?.category).toBe("APPROVAL");
        expect(m?.tag).toBe(phone?.tag);
      }
      await n.notify(ids.me as string, ids.org as string, "reply", {
        title: "Ada",
        body: "Your table is booked for two at eight.",
        bot_id: ids.bot,
      });
      const reply = watch.sent.at(-1)?.message;
      expect(reply).toMatchObject({ title: "Ada", body: "Replied" });
    } finally {
      await tdb.admin`update public.watch_prefs set show_details = true where user_id = ${ids.me as string}`;
    }
  });

  it("clear tokens Apple or Firebase say are gone", async () => {
    const push = goneTokens(["wear-token-1"]);
    const watch = new RecordingWatch(["ab".repeat(32)]);
    const n = new NotificationService(h.db, push);
    n.watch = watch;
    await n.notify(ids.me as string, ids.org as string, "reply", { title: "Ada", body: "Done." });
    const rows = await tdb.admin<
      { name: string; push_token: string | null; push_kind: string | null }[]
    >`
      select name, push_token, push_kind from public.watch_keys where org_id = ${ids.org as string} order by name`;
    expect(rows).toEqual([
      { name: "Apple Watch", push_token: null, push_kind: null },
      { name: "Pixel Watch", push_token: null, push_kind: null },
    ]);
  });

  it("hand off to the phone with no inbox row", async () => {
    const push = new RecordingPushSender();
    const n = new NotificationService(h.db, push);
    expect(
      await n.handoff(ids.me as string, { title: "Continue with Ada", link: "/bots/x/chat" }),
    ).toBe(1);
    expect(push.sent[0]?.tokens).toEqual(["phone-1"]);
    expect(push.sent[0]?.message).toMatchObject({
      title: "Continue with Ada",
      body: "From your watch",
      link: "/bots/x/chat",
    });
  });
});

describe("the Apple sender", () => {
  // A P-256 key in PKCS#8, made for this test only.
  let keyP8 = "";
  let server: Http2Server;
  let url = "";
  /** What the stand-in for Apple answers, by device token; "hang" never answers. */
  const answers: Record<string, { status: number; reason?: string } | "hang"> = {};

  beforeAll(async () => {
    const { generateKeyPairSync } = await import("node:crypto");
    keyP8 = generateKeyPairSync("ec", { namedCurve: "P-256" })
      .privateKey.export({ type: "pkcs8", format: "pem" })
      .toString();
    server = createServer();
    server.on("stream", (stream: ServerHttp2Stream, headers: IncomingHttpHeaders) => {
      const token = String(headers[":path"]).split("/").pop() as string;
      const a = answers[token] ?? { status: 200 };
      if (a === "hang") return;
      stream.respond({ ":status": a.status });
      stream.end(a.reason ? JSON.stringify({ reason: a.reason }) : "");
    });
    await new Promise<void>((r) => server.listen(0, "127.0.0.1", r));
    url = `http://127.0.0.1:${(server.address() as AddressInfo).port}`;
  });
  afterAll(async () => {
    await new Promise((r) => server.close(r));
  });

  const client = () => new ApnsClient({ keyP8, keyId: "KEY", teamId: "TEAM", url });

  it("reads Apple's reason from its answer", () => {
    expect(apnsReason('{"reason":"BadDeviceToken"}')).toBe("BadDeviceToken");
    expect(apnsReason("")).toBe("");
  });

  it("clears dead tokens and ones made for another app, and says what else Apple refused", async () => {
    Object.assign(answers, {
      gone: { status: 410, reason: "Unregistered" },
      bad: { status: 400, reason: "BadDeviceToken" },
      other: { status: 400, reason: "DeviceTokenNotForTopic" },
      slow: { status: 429, reason: "TooManyRequests" },
      key: { status: 403, reason: "InvalidProviderToken" },
    });
    const heard: Array<{ reason: string; code?: number }> = [];
    const sender = new ApnsWatchSender(client(), { onError: (i) => heard.push(i) });
    const { invalidTokens } = await sender.sendWatch(
      ["fine", "gone", "bad", "other", "slow", "key"].map((token) => ({ token, sandbox: false })),
      { title: "Ada", body: "Replied" },
    );
    expect(invalidTokens).toEqual(["gone", "bad", "other"]);
    // Never a token: only why.
    expect(heard).toEqual([
      { reason: "TooManyRequests", code: 429, sandbox: false },
      { reason: "InvalidProviderToken", code: 403, sandbox: false },
    ]);
  });

  it("gives up on a push Apple doesn't answer, keeping what it had heard", async () => {
    Object.assign(answers, { gone: { status: 410, reason: "Unregistered" }, stuck: "hang" });
    const started = Date.now();
    const error = await client()
      .sendAll(["gone", "stuck", "never"], () => ({ "apns-topic": "t" }), "{}", { timeoutMs: 200 })
      .catch((e: unknown) => e);
    expect(error).toBeInstanceOf(ApnsBatchError);
    expect((error as ApnsBatchError).results.map((r) => r.token)).toEqual(["gone"]);
    expect(Date.now() - started).toBeLessThan(3000);
  });

  it("still clears the tokens Apple answered for when a batch breaks off", async () => {
    Object.assign(answers, { gone: { status: 410, reason: "Unregistered" }, stuck: "hang" });
    const heard: Array<{ reason: string }> = [];
    const hung = new ApnsClient({ keyP8, keyId: "KEY", teamId: "TEAM", url });
    const sendAll = hung.sendAll.bind(hung);
    hung.sendAll = (tokens, headers, body, o) =>
      sendAll(tokens, headers, body, { ...o, timeoutMs: 200 });
    const sender = new ApnsWatchSender(hung, { onError: (i) => heard.push(i) });
    const { invalidTokens } = await sender.sendWatch(
      ["gone", "stuck"].map((token) => ({ token, sandbox: false })),
      { title: "Ada", body: "Replied" },
    );
    expect(invalidTokens).toEqual(["gone"]);
    expect(heard).toHaveLength(1);
    expect(heard[0]?.reason).toContain("didn't answer");
  });
});
