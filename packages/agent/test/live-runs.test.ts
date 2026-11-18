/** The island's server pushes (D-324, Phase 4): a followed run's state to the phones that follow it. */
import { readFileSync } from "node:fs";
import { createDb, type DbHandle } from "@casama/db";
import { startTestDatabase, type TestDatabase } from "@casama/db/testing";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { EventBus } from "../src/events.ts";
import {
  LIVE_STEP_WORDS,
  LiveRunPusher,
  type LiveTarget,
  type LiveUpdate,
  liveStepWords,
  sweepLiveTokens,
} from "../src/live-runs.ts";
import {
  fcmLiveMessage,
  LIVE_ACTIVITY_LABELS,
  liveData,
  RecordingPushSender,
} from "../src/notifications.ts";
import { liveWithoutText } from "../src/push-relay.ts";

describe("step words", () => {
  it("are the app's own (app_en.arb toolDoing), so a push reads like the app", () => {
    const arb = JSON.parse(
      readFileSync(new URL("../../../client/lib/l10n/app_en.arb", import.meta.url), "utf8"),
    ) as Record<string, string>;
    const select = arb.toolDoing as string;
    const words = Object.fromEntries(
      [...select.slice(select.indexOf("select,") + 7).matchAll(/(\w+)\{([^}]*)\}/g)].map((m) => [
        m[1],
        m[2],
      ]),
    );
    expect(LIVE_STEP_WORDS).toEqual(words);
  });

  it("a pushed start's labels are the app's island words", () => {
    const arb = JSON.parse(
      readFileSync(new URL("../../../client/lib/l10n/app_en.arb", import.meta.url), "utf8"),
    ) as Record<string, string>;
    const keys: Record<keyof typeof LIVE_ACTIVITY_LABELS, string> = {
      open: "islandOpen",
      stop: "islandStop",
      review: "islandReview",
      allow: "islandAllow",
      deny: "islandDeny",
      needs_ok: "islandNeedsOk",
      working: "islandWorking",
      take_over: "islandTakeOver",
      finished: "islandFinished",
      problem: "islandStoppedProblem",
      stale: "islandStale",
    };
    for (const [k, arbKey] of Object.entries(keys))
      expect(LIVE_ACTIVITY_LABELS[k as keyof typeof keys]).toBe(arb[arbKey]);
  });

  it("name the kind of step, never what it is about", () => {
    expect(liveStepWords("web.search")).toBe("Searching the web");
    expect(liveStepWords("shell.exec")).toBe("Working on its computer");
    expect(liveStepWords("browser.fill")).toBe("Typing on the page");
    expect(liveStepWords("gmail__send_email")).toBe("Working on it");
  });
});

const update = (over: Partial<LiveUpdate> = {}): LiveUpdate => ({
  run_id: "r1",
  bot_id: "b1",
  bot_name: "Ada",
  started_at: 1_000,
  link: "/bots/b1/chat?c=c1",
  state: {
    phase: "working",
    step: "Searching the web",
    detail: null,
    steps: 2,
    approval_id: null,
    risk: null,
    updated_at: 1_010,
    ended_at: null,
  },
  event: "update",
  priority: 5,
  stale_at: 1_130,
  dismiss_at: null,
  ...over,
});

describe("messages", () => {
  it("iPhone: a Live Activity push through Firebase, with both tokens and no alert", () => {
    const m = fcmLiveMessage(
      { token: "activity-token", platform: "ios", fcm_token: "fcm-1" },
      update(),
    );
    expect(m).toEqual({
      token: "fcm-1",
      apns: {
        live_activity_token: "activity-token",
        headers: { "apns-priority": "5" },
        payload: {
          aps: {
            timestamp: 1_010,
            event: "update",
            "content-state": update().state,
            "stale-date": 1_130,
          },
        },
      },
    });
    const end = fcmLiveMessage(
      { token: "activity-token", platform: "ios", fcm_token: "fcm-1" },
      update({ event: "end", priority: 10, dismiss_at: 1_910 }),
    ) as { apns: { headers: Record<string, string>; payload: { aps: Record<string, unknown> } } };
    expect(end.apns.headers["apns-priority"]).toBe("10");
    expect(end.apns.payload.aps["dismissal-date"]).toBe(1_910);
    expect(end.apns.payload.aps).not.toHaveProperty("alert");
    // Finished doesn't go stale while it stays on the Lock Screen.
    expect(end.apns.payload.aps).not.toHaveProperty("stale-date");
    // Without the phone's own Firebase token, Firebase can't address it.
    expect(
      fcmLiveMessage({ token: "activity-token", platform: "ios", fcm_token: null }, update()),
    ).toBeNull();
  });

  it("push-to-start: an iPhone gets the activity's fixed part and a silent alert", () => {
    const m = fcmLiveMessage(
      { token: "start-token", platform: "ios", fcm_token: "fcm-2" },
      update({ event: "start", priority: 10, bot_avatar: "mascot:winky" }),
    );
    const aps = (m as { apns: { payload: { aps: Record<string, unknown> } } }).apns.payload.aps;
    expect(aps).toMatchObject({
      event: "start",
      "attributes-type": "RunActivityAttributes",
      attributes: {
        run_id: "r1",
        bot_id: "b1",
        bot_name: "Ada",
        bot_avatar: "mascot:winky",
        started_at: 1_000,
        link: "/bots/b1/chat?c=c1",
        labels: LIVE_ACTIVITY_LABELS,
      },
      alert: { title: "Ada", body: "Searching the web" },
      "stale-date": 1_130,
    });
    expect(aps).not.toHaveProperty("sound");
    const android = fcmLiveMessage(
      { token: "fcm-a", platform: "android", fcm_token: null },
      update({ event: "start", priority: 10 }),
    );
    expect(android).toMatchObject({ data: { event: "start" }, android: { priority: "HIGH" } });
  });

  it("Android: a data message the app draws itself, strings only", () => {
    const m = fcmLiveMessage(
      { token: "fcm-a", platform: "android", fcm_token: null },
      update(),
    ) as {
      token: string;
      data: Record<string, string>;
      android: Record<string, string>;
    };
    expect(m.token).toBe("fcm-a");
    expect(m.data).toEqual(liveData(update()));
    expect(m.data).toMatchObject({ kind: "live", phase: "working", steps: "2", approval_id: "" });
    expect(Object.values(m.data).every((v) => typeof v === "string")).toBe(true);
    expect(m.android.priority).toBe("NORMAL");
    expect(
      (
        fcmLiveMessage(
          { token: "fcm-a", platform: "android", fcm_token: null },
          update({ priority: 10 }),
        ) as {
          android: Record<string, string>;
        }
      ).android.priority,
    ).toBe("HIGH");
  });

  it("private notifications: the relay gets the phase and times, no words", () => {
    const hidden = liveWithoutText(update());
    expect(hidden.bot_name).toBe("Casama");
    expect(liveWithoutText(update({ bot_avatar: "mascot:winky" })).bot_avatar).toBeNull();
    expect(hidden.state.step).toBe("");
    expect(hidden.state.phase).toBe("working");
    expect(hidden.state.steps).toBe(2);
  });
});

describe("LiveRunPusher", () => {
  let tdb: TestDatabase;
  let h: DbHandle;
  let org = "";
  let bot = "";
  let user = "";
  const ids = { conv: "", followed: "", unfollowed: "", stopped: "", gone: "", short: "" };

  beforeAll(async () => {
    tdb = await startTestDatabase();
    h = createDb(tdb.url, { max: 2 });
    [{ id: user }] = (await tdb.admin`
      insert into auth.users (id, email, aud, role)
      values (gen_random_uuid(), 'live@example.com', 'authenticated', 'authenticated') returning id`) as unknown as [
      { id: string },
    ];
    [{ id: org }] = (await tdb.admin`
      insert into public.organizations (name, slug) values ('Live', 'live-pusher') returning id`) as unknown as [
      { id: string },
    ];
    [{ id: bot }] = (await tdb.admin`
      insert into public.bots (org_id, created_by, name, avatar_url) values (${org}, ${user}, 'Ada', 'mascot:winky') returning id`) as unknown as [
      { id: string },
    ];
    const [{ id: conv }] = (await tdb.admin`
      insert into public.conversations (org_id, bot_id) values (${org}, ${bot}) returning id`) as unknown as [
      { id: string },
    ];
    ids.conv = conv;
    for (const name of ["followed", "unfollowed", "stopped", "gone", "short"]) {
      const [{ id }] = (await tdb.admin`
        insert into public.runs (org_id, bot_id, conversation_id, created_by, status, started_at)
        values (${org}, ${bot}, ${conv}, ${user}, 'running', now()) returning id`) as unknown as [
        { id: string },
      ];
      ids[name as keyof typeof ids] = id;
    }
    for (const run of [ids.followed, ids.stopped, ids.gone])
      await tdb.admin`
        insert into public.run_live_tokens (run_id, user_id, platform, token, fcm_token) values
          (${run}, ${user}, 'ios', ${`activity-${run}`}, 'fcm-iphone-1'),
          (${run}, ${user}, 'android', ${`fcm-android-${run}`}, null)`;
  });
  afterAll(async () => {
    await h?.close();
    await tdb?.stop();
  });

  const tokens = async (run: string) =>
    Number(
      (
        (await tdb.admin`select count(*)::int as n from public.run_live_tokens where run_id = ${run}`) as unknown as [
          { n: number },
        ]
      )[0].n,
    );

  it("follows a run: steps throttled, needs your OK and ended at once, tokens gone at the end", async () => {
    const push = new RecordingPushSender();
    const pusher = new LiveRunPusher(h.db, push, { stepEveryMs: 300 });
    const stop = EventBus.observe(pusher.observe);
    const bus = new EventBus(h.db);
    try {
      const run = ids.followed as string;
      await bus.append(run, "tool.started", {
        call_id: "c1",
        tool: "web.search",
        args_redacted: { query: "repotting ferns" },
      });
      await pusher.idle();
      expect(push.live).toHaveLength(1);
      const first = push.live[0]!;
      expect(first.targets.map((t) => t.platform).sort()).toEqual(["android", "ios"]);
      expect(first.update).toMatchObject({
        run_id: run,
        bot_id: bot,
        bot_name: "Ada",
        link: `/bots/${bot}/chat?c=${ids.conv}`,
        event: "update",
        priority: 5,
        state: { phase: "working", step: "Searching the web", detail: null, steps: 1 },
      });
      expect(first.update.stale_at - first.update.state.updated_at).toBe(120);
      // Nothing about what was searched leaves the server.
      expect(JSON.stringify(first.update)).not.toContain("ferns");

      // A second step right away waits for the throttle, then goes with the newest state.
      await bus.append(run, "tool.started", {
        call_id: "c2",
        tool: "files.read",
        args_redacted: {},
      });
      await bus.append(run, "tool.started", {
        call_id: "c3",
        tool: "files.write",
        args_redacted: {},
      });
      await pusher.idle();
      expect(push.live).toHaveLength(1);
      await new Promise((r) => setTimeout(r, 400));
      await pusher.idle();
      expect(push.live).toHaveLength(2);
      expect(push.live[1]!.update.state).toMatchObject({ step: "Writing a file", steps: 3 });

      // Needs your OK: at once, priority 10, general words only.
      await bus.append(run, "approval.requested", {
        approval_id: "7d4c2f1e-8a3b-4c5d-9e6f-0a1b2c3d4e5f",
        tool: "shell.exec",
        args_redacted: { command: "rm -rf ~/old-backups" },
        risk: "high",
        expires_at: new Date(Date.now() + 60_000).toISOString(),
      });
      await pusher.idle();
      expect(push.live).toHaveLength(3);
      expect(push.live[2]!.update).toMatchObject({
        priority: 10,
        link: "/approvals/7d4c2f1e-8a3b-4c5d-9e6f-0a1b2c3d4e5f",
        state: {
          phase: "needsOk",
          step: "Working on its computer",
          approval_id: "7d4c2f1e-8a3b-4c5d-9e6f-0a1b2c3d4e5f",
          risk: "high",
        },
      });
      expect(JSON.stringify(push.live[2]!.update)).not.toContain("backups");

      // Back to work: at once.
      await bus.append(run, "approval.resolved", {
        approval_id: "7d4c2f1e-8a3b-4c5d-9e6f-0a1b2c3d4e5f",
        decision: "approved",
        decided_by: null,
      });
      await pusher.idle();
      expect(push.live[3]!.update).toMatchObject({
        priority: 10,
        state: { phase: "working", approval_id: null },
      });

      // Finished: ends, stays 15 minutes, and the run's tokens go.
      await bus.append(run, "run.completed", { final_message_id: null });
      await pusher.idle();
      const end = push.live[4]!.update;
      expect(end).toMatchObject({
        event: "end",
        priority: 10,
        state: { phase: "finished", step: "Finished" },
      });
      expect(end.dismiss_at! - end.state.updated_at).toBe(900);
      expect(end.state.ended_at).not.toBeNull();
      expect(await tokens(run)).toBe(0);
      expect(push.live).toHaveLength(5);
    } finally {
      stop();
    }
  });

  it("a phone that registers a moment after the start still hears a short run end", async () => {
    const push = new RecordingPushSender();
    const pusher = new LiveRunPusher(h.db, push);
    pusher.observe(ids.short, "run.started", {});
    await pusher.idle();
    expect(push.live).toHaveLength(0);
    await tdb.admin`
      insert into public.run_live_tokens (run_id, user_id, platform, token, fcm_token)
      values (${ids.short}, ${user}, 'ios', 'activity-short-0001', 'fcm-iphone-1')`;
    pusher.observe(ids.short, "run.completed", { final_message_id: null });
    await pusher.idle();
    expect(push.live.map((l) => l.update.event)).toEqual(["end"]);
  });

  it("each push is stamped later than the one before, even within a second", async () => {
    const push = new RecordingPushSender();
    const pusher = new LiveRunPusher(h.db, push, { stepEveryMs: 0, now: () => 1_800_000_000_000 });
    await tdb.admin`
      insert into public.run_live_tokens (run_id, user_id, platform, token)
      values (${ids.unfollowed}, ${user}, 'android', 'stamp-token-0001')`;
    pusher.observe(ids.unfollowed, "run.started", {});
    pusher.observe(ids.unfollowed, "tool.started", { tool: "web.search" });
    pusher.observe(ids.unfollowed, "approval.requested", {
      approval_id: "a",
      tool: "shell",
      risk: "low",
    });
    await pusher.idle();
    const stamps = push.live.map((l) => l.update.state.updated_at);
    expect(stamps.length).toBeGreaterThan(1);
    expect([...stamps].sort()).toEqual(stamps);
    expect(new Set(stamps).size).toBe(stamps.length);
    await tdb.admin`delete from public.run_live_tokens where token = 'stamp-token-0001'`;
  });

  it("sends nothing for a run no phone follows", async () => {
    const push = new RecordingPushSender();
    const pusher = new LiveRunPusher(h.db, push);
    const stop = EventBus.observe(pusher.observe);
    try {
      await new EventBus(h.db).append(ids.unfollowed as string, "tool.started", {
        call_id: "c1",
        tool: "web.search",
        args_redacted: {},
      });
      await pusher.idle();
      expect(push.live).toHaveLength(0);
    } finally {
      stop();
    }
  });

  it("a stopped run leaves at once", async () => {
    const push = new RecordingPushSender();
    const pusher = new LiveRunPusher(h.db, push);
    const stop = EventBus.observe(pusher.observe);
    try {
      await new EventBus(h.db).append(ids.stopped as string, "run.cancelled", {
        cancelled_by: user,
      });
      await pusher.idle();
      const end = push.live[0]!.update;
      expect(end).toMatchObject({ event: "end", state: { phase: "problem" } });
      expect(end.dismiss_at).toBe(end.state.updated_at);
      expect(await tokens(ids.stopped as string)).toBe(0);
    } finally {
      stop();
    }
  });

  it("push-to-start: a person's run appears on their phones that aren't following it", async () => {
    const [{ id: run }] = (await tdb.admin`
      insert into public.runs (org_id, bot_id, conversation_id, created_by, status, started_at, trigger)
      values (${org}, ${bot}, ${ids.conv}, ${user}, 'running', now(), 'chat') returning id`) as unknown as [
      { id: string },
    ];
    const [{ id: routine }] = (await tdb.admin`
      insert into public.runs (org_id, bot_id, created_by, status, started_at, trigger)
      values (${org}, ${bot}, ${user}, 'running', now(), 'routine') returning id`) as unknown as [
      { id: string },
    ];
    // The iPhone that started it follows it already; another iPhone and an Android phone don't.
    await tdb.admin`
      insert into public.run_live_tokens (run_id, user_id, platform, token, fcm_token)
      values (${run}, ${user}, 'ios', 'activity-started-here', 'fcm-iphone-1')`;
    await tdb.admin`
      insert into public.live_start_tokens (user_id, platform, token, fcm_token) values
        (${user}, 'ios', 'start-iphone-1', 'fcm-iphone-1'),
        (${user}, 'ios', 'start-iphone-2', 'fcm-iphone-2'),
        (${user}, 'android', 'fcm-android-start', null),
        (${user}, 'android', 'fcm-shared-phone', null)`;
    // A phone that turned "Bots you start elsewhere" off.
    await tdb.admin`
      insert into public.live_start_tokens (user_id, platform, token, enabled)
      values (${user}, 'android', 'fcm-switched-off', false)`;
    // Someone else signed in on the shared phone since: it follows them now, not this person, even
    // with the setting off there.
    const [{ id: other }] = (await tdb.admin`
      insert into auth.users (id, email, aud, role)
      values (gen_random_uuid(), 'live-other@example.com', 'authenticated', 'authenticated') returning id`) as unknown as [
      { id: string },
    ];
    await tdb.admin`
      insert into public.live_start_tokens (user_id, platform, token, enabled, updated_at)
      values (${other}, 'android', 'fcm-shared-phone', false, now() + interval '1 minute')`;
    const push = new RecordingPushSender();
    const pusher = new LiveRunPusher(h.db, push, { startAfterMs: 10 });
    pusher.observe(run, "run.started", {});
    pusher.observe(routine, "run.started", {});
    await new Promise((r) => setTimeout(r, 60));
    await pusher.idle();
    const starts = push.live.filter((l) => l.update.event === "start");
    expect(starts).toHaveLength(1);
    // The bot's own icon goes along, so the phone draws its mascot, not a stand-in.
    expect(starts[0]!.update).toMatchObject({
      run_id: run,
      priority: 10,
      bot_name: "Ada",
      bot_avatar: "mascot:winky",
    });
    expect(starts[0]!.targets.map((t) => t.token).sort()).toEqual([
      "fcm-android-start",
      "start-iphone-2",
    ]);
    // The Android phone follows it from here: its updates and its end reach it.
    const rows = (await tdb.admin`
      select platform, token from public.run_live_tokens where run_id = ${run} order by platform`) as unknown as {
      platform: string;
      token: string;
    }[];
    expect(rows.map((r) => r.token)).toEqual(["fcm-android-start", "activity-started-here"]);
    await tdb.admin`delete from public.live_start_tokens where user_id in (${user}, ${other})`;
  });

  it("forgets tokens the push service says are gone", async () => {
    const sent: LiveTarget[][] = [];
    const pusher = new LiveRunPusher(h.db, {
      send: async () => ({ invalidTokens: [] }),
      sendLive: async (targets) => {
        sent.push(targets);
        return { invalidTokens: targets.filter((t) => t.platform === "ios").map((t) => t.token) };
      },
    });
    pusher.observe(ids.gone as string, "run.started", {});
    await pusher.idle();
    expect(sent).toHaveLength(1);
    const left = (await tdb.admin`
      select platform from public.run_live_tokens where run_id = ${ids.gone}`) as unknown as {
      platform: string;
    }[];
    expect(left.map((r) => r.platform)).toEqual(["android"]);
  });

  it("a server that can't push live doesn't listen", () => {
    expect(new LiveRunPusher(h.db, { send: async () => ({ invalidTokens: [] }) }).enabled).toBe(
      false,
    );
  });

  it("the sweep drops tokens 12 hours on", async () => {
    await tdb.admin`
      insert into public.run_live_tokens (run_id, user_id, platform, token, created_at)
      values (${ids.unfollowed}, ${user}, 'android', 'old-token-0001', now() - interval '13 hours'),
             (${ids.unfollowed}, ${user}, 'android', 'new-token-0001', now())`;
    expect(await sweepLiveTokens(h.db)).toBe(1);
    expect(await tokens(ids.unfollowed as string)).toBe(1);
  });
});
