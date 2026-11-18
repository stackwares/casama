/** Pushes a watch reads (D-410, docs/WATCH-PROTOCOL.md §4): the watch's kinds and direct pushes. */
import { createDb, type DbHandle } from "@casama/db";
import { startTestDatabase, type TestDatabase } from "@casama/db/testing";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { apnsAlertBody, type WatchPushTarget, watchAppTopic } from "../src/apns.ts";
import {
  NotificationService,
  type PushMessage,
  type PushSender,
  RecordingPushSender,
  watchKind,
} from "../src/notifications.ts";

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
});

let tdb: TestDatabase;
let h: DbHandle;
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
           (${ids.me}, ${ids.otherOrg}, 'wearos', ${key(3)}, 'Work watch', 'wear-token-2', 'fcm', null)`;
}, 600_000);

afterAll(async () => {
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
    expect(phone?.message.data).toMatchObject({ kind: "reply", watch_kind: "reply" });
    // A tag, so the iPhone's mirrored copy and the watch's own fold into one.
    expect(phone?.message.tag).toMatch(/^n-/);
    const wear = push.sent.find((s) => s.tokens.includes("wear-token-1"));
    expect(wear?.message.dataOnly).toBe(true);
    expect(wear?.message.data).toMatchObject({
      watch_kind: "reply",
      title: "Ada",
      body: "All booked.",
      user_id: ids.me,
    });
    // Not the watch signed in to another workspace.
    expect(push.sent.some((s) => s.tokens.includes("wear-token-2"))).toBe(false);
    expect(watch.sent).toHaveLength(1);
    expect(watch.sent[0]?.targets).toEqual([{ token: "ab".repeat(32), sandbox: true }]);
    expect(watch.sent[0]?.message.tag).toBe(phone?.message.tag);
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
