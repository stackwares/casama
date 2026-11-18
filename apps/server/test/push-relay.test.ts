import {
  type CallPayload,
  CloudRelayPushSender,
  type LiveTarget,
  type LiveUpdate,
  PRIVATE_PUSH_BODY,
  PRIVATE_PUSH_TITLE,
  type PushMessage,
  type PushSender,
  type VoipSender,
  type WidgetPushSender,
  type WidgetPushTarget,
} from "@casama/agent";
import { afterAll, beforeAll, beforeEach, describe, expect, it } from "vitest";
import { resetLinkSettingsCache } from "../src/services/link-settings.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

/**
 * Casama Link's push relay (D-296): a self-hosted server can't address the store apps (only
 * Casama's Firebase key can), so a linked one hands its notifications to Casama Cloud. Firebase is
 * a recorder here.
 */
describe("Casama Link: the push relay", () => {
  const CLOUD = "https://cloud.test";
  let cloud: Harness;
  let owner: { id: string; token: string };
  let orgId: string;
  let key: string;
  let sent: Array<{ tokens: string[]; message: PushMessage }>;
  let calls: Array<{ tokens: string[]; data: Record<string, string>; ttlSeconds: number }>;
  let rings: Array<{ tokens: string[]; call: CallPayload }>;
  let lives: Array<{ targets: LiveTarget[]; update: LiveUpdate }>;
  let dead: string[];
  let refreshed: Array<{ targets: WidgetPushTarget[]; urgent: boolean }>;
  /** Casama Cloud's widget refresh sender (D-405): records, and reports the dead tokens. */
  const widgetSender: WidgetPushSender = {
    async sendWidgets(t, o) {
      refreshed.push({ targets: t, urgent: o.urgent });
      return { invalidTokens: t.map((x) => x.token).filter((x) => dead.includes(x)) };
    },
  };

  /** Casama Cloud's own Firebase sender: records, and reports the tokens marked dead. */
  const firebase: PushSender = {
    async send(tokens, message) {
      sent.push({ tokens, message });
      return { invalidTokens: tokens.filter((t) => dead.includes(t)) };
    },
    async sendCall(tokens, data, ttlSeconds) {
      calls.push({ tokens, data, ttlSeconds });
      return { invalidTokens: [] };
    },
    async sendLive(targets, update) {
      lives.push({ targets, update });
      return { invalidTokens: targets.map((t) => t.token).filter((t) => dead.includes(t)) };
    },
  };
  /** A followed run's state (D-324). */
  const live: LiveUpdate = {
    run_id: "r1",
    bot_id: "b1",
    bot_name: "Atlas",
    started_at: 1_000,
    link: "/bots/b1/chat?c=c1",
    state: {
      phase: "needsOk",
      step: "Sending a message",
      detail: null,
      steps: 3,
      approval_id: "a1",
      risk: "high",
      updated_at: 1_010,
      ended_at: null,
    },
    event: "update",
    priority: 10,
    stale_at: 1_130,
    dismiss_at: null,
  };
  const targets: LiveTarget[] = [
    { token: "activity-token-1", platform: "ios", fcm_token: "fcm-iphone-01" },
    { token: "token-android-1", platform: "android", fcm_token: null },
  ];
  /** Casama Cloud's own Apple key: records the rings, and reports tokens that are gone. */
  const apple: VoipSender = {
    async send(tokens, call) {
      rings.push({ tokens, call });
      return { invalidTokens: tokens.filter((t) => t.endsWith("gone")) };
    },
  };
  const makeKey = async (scopes: string[], name = "home") =>
    (
      await j(
        await cloud.request(`/v1/orgs/${orgId}/link/keys`, {
          method: "POST",
          token: owner.token,
          json: { instance_name: name, scopes },
        }),
      )
    ).key as string;
  const push = (body: unknown, withKey: string | null = key) =>
    cloud.request("/link/v1/push", {
      method: "POST",
      headers: withKey ? { authorization: `Bearer ${withKey}` } : undefined,
      json: body,
    });
  /** The network as a self-hosted server sees it: only Casama Cloud. */
  const net: typeof fetch = (input, init) =>
    Promise.resolve(cloud.app.request(String(input).slice(CLOUD.length), init as RequestInit));
  const message: PushMessage = {
    title: "Atlas",
    body: "The quarterly report is ready.",
    link: "/bots/b1/chat",
    data: { notification_id: "n1", bot_id: "b1" },
  };

  beforeAll(async () => {
    cloud = await startHarness({
      env: { BILLING_ENABLED: "true" },
      casamaLink: { push: firebase, voip: apple, widgets: widgetSender },
    });
    owner = await cloud.user("relay-owner@example.com");
    orgId = (
      await j(
        await cloud.request("/v1/orgs", {
          method: "POST",
          token: owner.token,
          json: { name: "Home" },
        }),
      )
    ).id;
    key = await makeKey(["push"]);
  }, 60_000);
  afterAll(() => cloud?.stop());
  beforeEach(() => {
    sent = [];
    calls = [];
    rings = [];
    lives = [];
    dead = [];
    refreshed = [];
  });

  it("passes a followed run's state on to the phones (D-324)", async () => {
    dead = ["activity-token-1"];
    const res = await push({
      tokens: targets.map((t) => t.token),
      live: { targets, update: live },
    });
    expect(res.status).toBe(200);
    expect(await j(res)).toEqual({ sent: 2, invalid_tokens: ["activity-token-1"] });
    expect(lives).toEqual([{ targets, update: live }]);
    // The targets must be the tokens it counts against the hourly limit.
    expect(
      (await push({ tokens: ["someone-else-01"], live: { targets: [targets[0]], update: live } }))
        .status,
    ).toBe(400);
    expect(
      (
        await push({
          tokens: ["activity-token-1"],
          live: {
            targets: [targets[0]],
            update: { ...live, state: { ...live.state, phase: "x" } },
          },
        })
      ).status,
    ).toBe(400);
  });

  it("refreshes a linked server's widgets, with nothing in the push (D-405)", async () => {
    const widgetTargets: WidgetPushTarget[] = [
      { token: "ab".repeat(32), kind: "apns_widgets", sandbox: true },
      { token: "token-android-w", kind: "fcm", sandbox: false },
    ];
    dead = ["token-android-w"];
    const res = await push({
      tokens: widgetTargets.map((t) => t.token),
      widget: { targets: widgetTargets, urgent: true },
    });
    expect(res.status).toBe(200);
    expect(await j(res)).toEqual({ sent: 2, invalid_tokens: ["token-android-w"] });
    expect(refreshed).toEqual([{ targets: widgetTargets, urgent: true }]);
    expect(sent).toEqual([]);
    // The targets must be the tokens counted; nothing else rides along; one kind per request.
    for (const bad of [
      { tokens: ["someone-else-01"], widget: { targets: [widgetTargets[0]] } },
      { tokens: ["token-android-w"], widget: { targets: [{ ...widgetTargets[1], kind: "x" }] } },
      {
        tokens: ["token-android-w"],
        widget: { targets: [widgetTargets[1]] },
        message,
      },
      { tokens: ["token-android-w"], widget: { targets: [] } },
    ])
      expect((await push(bad)).status, JSON.stringify(bad).slice(0, 80)).toBe(400);
    expect(refreshed).toHaveLength(1);

    // From the self-hosted side: the relay sender posts the same body.
    refreshed = [];
    const relay = new CloudRelayPushSender({ url: CLOUD, key }, { fetch: net });
    expect(await relay.sendWidgets(widgetTargets, { urgent: false })).toEqual({
      invalidTokens: ["token-android-w"],
    });
    expect(refreshed).toEqual([{ targets: widgetTargets, urgent: false }]);
  });

  it("sends a linked server's notification and says which tokens are dead", async () => {
    dead = ["token-gone-000"];
    const res = await push({ tokens: ["token-alive-00", "token-gone-000"], message });
    expect(res.status).toBe(200);
    expect(await j(res)).toEqual({ sent: 2, invalid_tokens: ["token-gone-000"] });
    expect(sent).toEqual([{ tokens: ["token-alive-00", "token-gone-000"], message }]);
    expect(
      (
        await j(
          await cloud.request("/link/v1/whoami", {
            headers: { authorization: `Bearer ${key}` },
          }),
        )
      ).push,
    ).toBe(true);
  });

  it("passes the D-325 fields through, and still takes messages without them", async () => {
    const rich: PushMessage = {
      ...message,
      tag: "reply-c1",
      channel: "replies",
      priority: "high",
      threadId: "c1",
      badge: 3,
      interruption: "time-sensitive",
      category: "APPROVAL",
    };
    expect((await push({ tokens: ["token-alive-00"], message: rich })).status).toBe(200);
    expect(sent[0]?.message).toEqual(rich);
    // The private switch still blanks the words, and keeps the routing fields.
    sent = [];
    const relay = new CloudRelayPushSender(
      { url: CLOUD, key },
      { fetch: net, private: () => true },
    );
    await relay.send(["token-alive-00"], rich);
    expect(sent[0]?.message).toEqual({
      ...rich,
      title: PRIVATE_PUSH_TITLE,
      body: PRIVATE_PUSH_BODY,
    });
  });

  it("rings a call the same way", async () => {
    const res = await push({
      tokens: ["token-android-1"],
      call: { data: { call_id: "c1", bot_name: "Atlas" }, ttl_seconds: 30 },
    });
    expect(res.status).toBe(200);
    expect(calls).toEqual([
      { tokens: ["token-android-1"], data: { call_id: "c1", bot_name: "Atlas" }, ttlSeconds: 30 },
    ]);
    expect(sent).toEqual([]);
  });

  it("refuses a key that can't push, no key, and requests that aren't notifications", async () => {
    expect((await push({ tokens: ["token-alive-00"], message }, null)).status).toBe(401);
    const spendOnly = await makeKey(["computers", "models"], "computers-only");
    const refused = await push({ tokens: ["token-alive-00"], message }, spendOnly);
    expect(refused.status).toBe(403);
    expect((await j(refused)).code).toBe("push_unavailable");

    for (const bad of [
      { tokens: [], message },
      { tokens: ["token-alive-00"] },
      { tokens: ["token-alive-00"], message, call: { data: {}, ttl_seconds: 30 } },
      { tokens: ["token-alive-00"], message: { ...message, data: { blob: "x".repeat(1025) } } },
      { tokens: Array.from({ length: 501 }, (_, i) => `token-many-${i}`), message },
    ])
      expect((await push(bad)).status, JSON.stringify(bad).slice(0, 60)).toBe(400);
    expect(sent).toEqual([]);
    // Long text is cut, not refused: the phone only shows so much.
    await push({
      tokens: ["token-alive-00"],
      message: { title: "T".repeat(500), body: "B".repeat(5000) },
    });
    expect(sent[0]?.message.title).toHaveLength(200);
    expect(sent[0]?.message.body).toHaveLength(1000);
  });

  it("holds each key to a number of pushes an hour", async () => {
    const busy = await makeKey(["push"], "busy-server");
    const batch = Array.from({ length: 500 }, (_, i) => `token-batch-${i}`);
    for (let i = 0; i < 4; i++)
      expect((await push({ tokens: batch, message }, busy)).status).toBe(200);
    const over = await push({ tokens: ["token-one-more"], message }, busy);
    expect(over.status).toBe(429);
    expect(Number(over.headers.get("retry-after"))).toBeGreaterThan(0);
    // Another server isn't held up by it.
    expect((await push({ tokens: ["token-alive-00"], message })).status).toBe(200);
  });

  it("sends nothing for a suspended workspace", async () => {
    await cloud.tdb.admin`update public.organizations set suspended_at = now() where id = ${orgId}`;
    try {
      const res = await push({ tokens: ["token-alive-00"], message });
      expect(res.status).toBe(403);
      expect((await j(res)).code).toBe("suspended");
      expect(sent).toEqual([]);
    } finally {
      await cloud.tdb
        .admin`update public.organizations set suspended_at = null where id = ${orgId}`;
    }
    expect((await push({ tokens: ["token-alive-00"], message })).status).toBe(200);
  });

  it("rings an iPhone through Apple's call pushes, and says so when this cloud rings none", async () => {
    const ring = {
      call_id: "c1",
      bot_id: "b1",
      bot_name: "Atlas",
      reason: "The invoice needs your OK",
      conversation_id: null,
    };
    const res = await push({
      tokens: ["voip-token-0001", "voip-token-gone"],
      voip: { call: ring },
    });
    expect(res.status).toBe(200);
    expect(await j(res)).toEqual({ sent: 2, invalid_tokens: ["voip-token-gone"] });
    expect(rings).toEqual([{ tokens: ["voip-token-0001", "voip-token-gone"], call: ring }]);
    expect(sent).toEqual([]);
    expect(calls).toEqual([]);
    // One thing at a time.
    expect(
      (await push({ tokens: ["voip-token-0001"], voip: { call: ring }, message })).status,
    ).toBe(400);

    // A cloud with no Apple key: the server is told once and stops asking; notifications go on.
    const plain = await startHarness({
      env: { BILLING_ENABLED: "true" },
      casamaLink: { push: firebase },
    });
    try {
      const u = await plain.user("no-apple@example.com");
      const org = (
        await j(
          await plain.request("/v1/orgs", { method: "POST", token: u.token, json: { name: "H" } }),
        )
      ).id;
      const k = (
        await j(
          await plain.request(`/v1/orgs/${org}/link/keys`, {
            method: "POST",
            token: u.token,
            json: { instance_name: "home", scopes: ["push"] },
          }),
        )
      ).key as string;
      let requests = 0;
      const relay = new CloudRelayPushSender(
        { url: CLOUD, key: k },
        {
          fetch: (input, init) => {
            requests++;
            return Promise.resolve(
              plain.app.request(String(input).slice(CLOUD.length), init as RequestInit),
            );
          },
        },
      );
      expect(await relay.voip().send(["voip-token-0001"], ring)).toEqual({ invalidTokens: [] });
      expect(await relay.voip().send(["voip-token-0001"], ring)).toEqual({ invalidTokens: [] });
      expect(requests).toBe(1);
      await relay.send(["token-alive-00"], message);
      expect(requests).toBe(2);
      expect(sent).toHaveLength(1);
    } finally {
      await plain.stop();
    }
  });

  describe("on the self-hosted server", () => {
    it("rings iPhones through the relay, with nothing to read when notifications are private", async () => {
      let on = false;
      const relay = new CloudRelayPushSender(
        { url: CLOUD, key },
        { fetch: net, private: () => on },
      );
      const ring = {
        call_id: "c1",
        bot_id: "b1",
        bot_name: "Atlas",
        reason: "The invoice needs your OK",
        conversation_id: "conv-1",
      };
      expect(await relay.voip().send(["voip-token-0001", "voip-token-gone"], ring)).toEqual({
        invalidTokens: ["voip-token-gone"],
      });
      expect(rings[0]?.call).toEqual(ring);
      on = true;
      await relay.voip().send(["voip-token-0001"], ring);
      expect(rings[1]?.call).toEqual({ ...ring, bot_name: PRIVATE_PUSH_TITLE, reason: "" });
      // Android rings carry the same and lose the same.
      await relay.sendCall(["token-android-1"], { kind: "call", ...ring }, 30);
      expect(calls[0]?.data).toEqual({
        kind: "call",
        ...ring,
        bot_name: PRIVATE_PUSH_TITLE,
        reason: "",
      });
      expect(JSON.stringify([rings[1], calls[0]])).not.toContain("invoice");
      expect(await relay.voip().send([], ring)).toEqual({ invalidTokens: [] });
    });

    it("sends through the relay and passes dead tokens back", async () => {
      dead = ["token-gone-000"];
      const relay = new CloudRelayPushSender({ url: CLOUD, key }, { fetch: net });
      const r = await relay.send(["token-alive-00", "token-gone-000"], message);
      expect(r).toEqual({ invalidTokens: ["token-gone-000"] });
      expect(sent[0]?.message).toEqual(message);
      await relay.sendCall(["token-android-1"], { call_id: "c1" }, 30);
      expect(calls[0]).toEqual({
        tokens: ["token-android-1"],
        data: { call_id: "c1" },
        ttlSeconds: 30,
      });
      // Nobody to tell: nothing is sent.
      await relay.send([], message);
      expect(sent).toHaveLength(1);
    });

    it("sends a run's state through the relay, without words when notifications are private", async () => {
      let on = false;
      const relay = new CloudRelayPushSender(
        { url: CLOUD, key },
        { fetch: net, private: () => on },
      );
      dead = ["token-android-1"];
      expect(await relay.sendLive(targets, live)).toEqual({ invalidTokens: ["token-android-1"] });
      expect(lives[0]?.update).toEqual(live);
      on = true;
      await relay.sendLive(targets, live);
      expect(lives[1]?.update).toEqual({
        ...live,
        bot_name: PRIVATE_PUSH_TITLE,
        // Shown as Casama: no bot's icon either.
        bot_avatar: null,
        state: { ...live.state, step: "", detail: null },
      });
      expect(JSON.stringify(lives[1])).not.toContain("Atlas");
      expect(await relay.sendLive([], live)).toEqual({ invalidTokens: [] });
      expect(lives).toHaveLength(2);
    });

    it("with private notifications on, no text leaves the server", async () => {
      let on = true;
      const relay = new CloudRelayPushSender(
        { url: CLOUD, key },
        { fetch: net, private: () => on },
      );
      await relay.send(["token-alive-00"], message);
      expect(sent[0]?.message).toEqual({
        ...message,
        title: PRIVATE_PUSH_TITLE,
        body: PRIVATE_PUSH_BODY,
      });
      // What takes the app to the right place still goes along.
      expect(sent[0]?.message.link).toBe("/bots/b1/chat");
      expect(sent[0]?.message.data).toEqual({ notification_id: "n1", bot_id: "b1" });
      expect(JSON.stringify(sent[0])).not.toContain("quarterly");
      // The switch works at once, without a restart.
      on = false;
      await relay.send(["token-alive-00"], message);
      expect(sent[1]?.message.body).toBe("The quarterly report is ready.");
    });

    it("a key the relay refuses is asked once, and a failure never fails the run", async () => {
      const errors: string[] = [];
      const spendOnly = await makeKey(["computers"], "no-push");
      let requests = 0;
      const counting: typeof fetch = (input, init) => {
        requests++;
        return net(input, init);
      };
      const relay = new CloudRelayPushSender(
        { url: CLOUD, key: spendOnly },
        { fetch: counting, onError: (e) => errors.push(e.message) },
      );
      expect(await relay.send(["token-alive-00"], message)).toEqual({ invalidTokens: [] });
      expect(await relay.send(["token-alive-00"], message)).toEqual({ invalidTokens: [] });
      expect(requests).toBe(1);
      expect(errors[0]).toContain("refused");

      const offline = new CloudRelayPushSender(
        { url: CLOUD, key },
        {
          fetch: async () => {
            throw new Error("getaddrinfo ENOTFOUND");
          },
          onError: (e) => errors.push(e.message),
        },
      );
      expect(await offline.send(["token-alive-00"], message)).toEqual({ invalidTokens: [] });
      expect(errors.at(-1)).toContain("ENOTFOUND");
    });
  });
});

describe("Casama Link: private notifications on a self-hosted server", () => {
  let h: Harness;
  let owner: { token: string };
  let member: { token: string };
  beforeAll(async () => {
    resetLinkSettingsCache();
    h = await startHarness({
      env: { CASAMA_CLOUD_URL: "https://cloud.test", CASAMA_CLOUD_KEY: "kcc_linked" },
    });
    owner = await h.user("private-owner@example.com");
    member = await h.user("private-member@example.com");
  }, 60_000);
  afterAll(() => h?.stop());

  it("the owner turns it on and off; the status says how notifications leave the server", async () => {
    const before = await j(await h.request("/v1/admin/remote-access", { token: owner.token }));
    expect(before).toMatchObject({ linked: true, push: "relay", private_notifications: false });

    const denied = await h.request("/v1/admin/remote-access/settings", {
      method: "PUT",
      token: member.token,
      json: { private_notifications: true },
    });
    expect(denied.status).toBe(403);

    const on = await h.request("/v1/admin/remote-access/settings", {
      method: "PUT",
      token: owner.token,
      json: { private_notifications: true },
    });
    expect(on.status).toBe(200);
    expect((await j(on)).private_notifications).toBe(true);
    // Read back from the database, as the worker does.
    resetLinkSettingsCache();
    expect(
      (await j(await h.request("/v1/admin/remote-access", { token: owner.token })))
        .private_notifications,
    ).toBe(true);
  });
});
