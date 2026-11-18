/** Widget refresh pushes (D-405): what goes to Apple, Google and the relay, and how often. */
import { generateKeyPairSync } from "node:crypto";
import { once } from "node:events";
import { createServer, type Http2Server, type ServerHttp2Stream } from "node:http2";
import type { AddressInfo } from "node:net";
import { createDb, type DbHandle } from "@casama/db";
import { startTestDatabase, type TestDatabase } from "@casama/db/testing";
import { afterAll, beforeAll, beforeEach, describe, expect, it } from "vitest";
import { ApnsClient } from "../src/apns.ts";
import {
  APPLE_WIDGET_BODY,
  ApnsWidgetSender,
  GlancePusher,
  RecordingWidgetPushSender,
  widgetPushSender,
  widgetTopic,
} from "../src/glance-push.ts";
import { fcmGlanceMessage, RecordingPushSender } from "../src/notifications.ts";
import { CloudRelayPushSender } from "../src/push-relay.ts";

const keyP8 = generateKeyPairSync("ec", { namedCurve: "prime256v1" })
  .privateKey.export({ type: "pkcs8", format: "pem" })
  .toString();
const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

describe("Apple widget pushes", () => {
  let apns: Http2Server;
  let url = "";
  const seen: Array<{ path: string; headers: Record<string, string>; body: string }> = [];

  beforeAll(async () => {
    apns = createServer();
    apns.on("stream", (stream: ServerHttp2Stream, headers) => {
      let body = "";
      stream.on("data", (d) => {
        body += d;
      });
      stream.on("end", () => {
        seen.push({ path: String(headers[":path"]), headers: headers as never, body });
        const gone = String(headers[":path"]).endsWith("/dead");
        stream.respond({ ":status": gone ? 410 : 200 });
        stream.end(gone ? JSON.stringify({ reason: "Unregistered" }) : "");
      });
    });
    apns.listen(0, "127.0.0.1");
    await once(apns, "listening");
    url = `http://127.0.0.1:${(apns.address() as AddressInfo).port}`;
  });
  afterAll(() => apns?.close());
  beforeEach(() => {
    seen.length = 0;
  });

  it("sends a WidgetKit push with nothing in it to the app's widget topic", async () => {
    const sender = new ApnsWidgetSender(
      new ApnsClient({ keyP8, keyId: "KEY123", teamId: "TEAM123", url }),
      { appBundleId: "ai.casama.app" },
    );
    const urgent = await sender.send(
      [
        { token: "aa11", kind: "apns_widgets", sandbox: false },
        { token: "dead", kind: "apns_widgets", sandbox: false },
      ],
      { urgent: true },
    );
    expect(urgent.invalidTokens).toEqual(["dead"]);
    expect(seen.map((s) => s.path).sort()).toEqual(["/3/device/aa11", "/3/device/dead"]);
    const first = seen[0]!;
    expect(first.headers["apns-topic"]).toBe("ai.casama.app.push-type.widgets");
    expect(first.headers["apns-push-type"]).toBe("widgets");
    expect(first.headers["apns-priority"]).toBe("10");
    expect(first.headers.authorization).toMatch(/^bearer [\w-]+\.[\w-]+\.[\w-]+$/);
    expect(JSON.parse(first.body)).toEqual({ aps: { "content-changed": true } });
    expect(first.body).toBe(APPLE_WIDGET_BODY);

    seen.length = 0;
    await sender.send([{ token: "bb22", kind: "apns_widgets", sandbox: true }], { urgent: false });
    expect(seen[0]?.headers["apns-priority"]).toBe("5");
    expect(widgetTopic("ai.casama.app.dev")).toBe("ai.casama.app.dev.push-type.widgets");
  });

  it("uses Apple's sandbox for development tokens", async () => {
    let sandboxHits = 0;
    const sandbox = createServer();
    sandbox.on("stream", (stream: ServerHttp2Stream) => {
      sandboxHits++;
      stream.on("data", () => {});
      stream.on("end", () => {
        stream.respond({ ":status": 200 });
        stream.end();
      });
    });
    sandbox.listen(0, "127.0.0.1");
    await once(sandbox, "listening");
    const sandboxUrl = `http://127.0.0.1:${(sandbox.address() as AddressInfo).port}`;
    try {
      const sender = new ApnsWidgetSender(
        new ApnsClient({ keyP8, keyId: "K", teamId: "T", url, sandboxUrl }),
      );
      await sender.send(
        [
          { token: "prod1", kind: "apns_widgets", sandbox: false },
          { token: "dev1", kind: "apns_widgets", sandbox: true },
        ],
        { urgent: false },
      );
      expect(seen.map((s) => s.path)).toEqual(["/3/device/prod1"]);
      expect(sandboxHits).toBe(1);
    } finally {
      sandbox.close();
    }
  });

  it("shrugs off Apple being out of reach", async () => {
    const sender = new ApnsWidgetSender(
      new ApnsClient({ keyP8, keyId: "K", teamId: "T", url: "http://127.0.0.1:1" }),
    );
    expect(
      await sender.send([{ token: "x", kind: "apns_widgets", sandbox: false }], { urgent: true }),
    ).toEqual({ invalidTokens: [] });
  });
});

describe("Android and the relay", () => {
  it("sends Android a quiet data-only message that collapses", () => {
    expect(fcmGlanceMessage("tok")).toEqual({
      token: "tok",
      data: { kind: "glance" },
      android: { priority: "NORMAL", ttl: "3600s", collapse_key: "glance" },
    });
  });

  it("routes Apple tokens to the own key, Android to Firebase, and skips Apple without a key", async () => {
    const push = new RecordingPushSender();
    const apple = {
      sent: [] as unknown[],
      send: async (t: unknown[]) => (apple.sent.push(...t), { invalidTokens: [] }),
    };
    const both = widgetPushSender({ push, apple: apple as never });
    await both.sendWidgets(
      [
        { token: "a", kind: "apns_widgets", sandbox: false },
        { token: "f", kind: "fcm", sandbox: false },
      ],
      { urgent: false },
    );
    expect(apple.sent).toHaveLength(1);
    expect(push.glance.map((g) => g.tokens)).toEqual([["f"]]);

    let told = 0;
    const noKey = widgetPushSender({ push: new RecordingPushSender(), onNoApple: () => told++ });
    const target = [{ token: "a", kind: "apns_widgets" as const, sandbox: false }];
    await noKey.sendWidgets(target, { urgent: true });
    await noKey.sendWidgets(target, { urgent: true });
    expect(told).toBe(1);
  });

  it("hands both kinds to Casama Cloud's relay when the server has no Apple key", async () => {
    const bodies: Array<Record<string, unknown>> = [];
    const relay = new CloudRelayPushSender(
      { url: "https://cloud.example/", key: "ck_1" },
      {
        fetch: (async (u: string, init: RequestInit) => {
          expect(u).toBe("https://cloud.example/link/v1/push");
          bodies.push(JSON.parse(String(init.body)));
          return new Response(JSON.stringify({ invalid_tokens: ["f"] }), {
            headers: { "content-type": "application/json" },
          });
        }) as never,
      },
    );
    const sender = widgetPushSender({ push: relay });
    const out = await sender.sendWidgets(
      [
        { token: "a", kind: "apns_widgets", sandbox: true },
        { token: "f", kind: "fcm", sandbox: false },
      ],
      { urgent: true },
    );
    expect(bodies).toEqual([
      {
        tokens: ["a", "f"],
        widget: {
          targets: [
            { token: "a", kind: "apns_widgets", sandbox: true },
            { token: "f", kind: "fcm", sandbox: false },
          ],
          urgent: true,
        },
      },
    ]);
    expect(out.invalidTokens).toEqual(["f"]);
    // Plain glance pushes from a relayed server go the same way, as Android targets.
    await relay.sendGlance(["g"]);
    expect(bodies[1]).toMatchObject({ tokens: ["g"], widget: { urgent: false } });
  });
});

describe("GlancePusher", () => {
  let tdb: TestDatabase;
  let h: DbHandle;
  let me = "";
  let runId = "";

  beforeAll(async () => {
    tdb = await startTestDatabase();
    h = createDb(tdb.url, { max: 2 });
    const a = tdb.admin;
    const [u] = await a<{ id: string }[]>`insert into auth.users (id, email, aud, role)
      values (gen_random_uuid(), 'push-me@example.com', 'authenticated', 'authenticated') returning id`;
    me = u!.id;
    const [o] = await a<
      { id: string }[]
    >`insert into public.organizations (name, slug) values ('P', 'push-test') returning id`;
    await a`insert into public.memberships (org_id, user_id, role) values (${o!.id}, ${me}, 'owner')`;
    const [b] = await a<
      { id: string }[]
    >`insert into public.bots (org_id, created_by, name) values (${o!.id}, ${me}, 'Ada') returning id`;
    const [r] = await a<
      { id: string }[]
    >`insert into public.runs (org_id, bot_id, created_by) values (${o!.id}, ${b!.id}, ${me}) returning id`;
    runId = r!.id;
    await a`insert into public.widget_keys (user_id, org_id, platform, key_hash, push_token, push_kind, push_sandbox) values
      (${me}, ${o!.id}, 'ios', ${"a".repeat(64)}, 'apple-token-1', 'apns_widgets', true),
      (${me}, ${o!.id}, 'android', ${"b".repeat(64)}, 'gone-token-1', 'fcm', null),
      (${me}, ${o!.id}, 'android', ${"c".repeat(64)}, null, null, null)`;
  }, 600_000);
  afterAll(async () => {
    await h?.close();
    await tdb?.stop();
  });

  it("tells needs-you changes at once and gathers the rest", async () => {
    const sender = new RecordingWidgetPushSender();
    // A still clock: the gathered push waits the whole window however slow the machine is.
    const p = new GlancePusher(h.db, sender, {
      batchEveryMs: 400,
      urgentDelayMs: 20,
      now: () => 1_000_000,
    });
    try {
      // A burst of urgent changes is one push, at priority 10.
      p.changed(me, { urgent: true });
      p.changed(me, { urgent: true });
      p.changed(me, { urgent: false });
      await sleep(80);
      await p.idle();
      expect(sender.sent).toHaveLength(1);
      expect(sender.sent[0]?.urgent).toBe(true);
      expect(sender.sent[0]?.targets.map((t) => t.token).sort()).toEqual([
        "apple-token-1",
        "gone-token-1",
      ]);
      expect(sender.sent[0]?.targets.find((t) => t.token === "apple-token-1")?.sandbox).toBe(true);

      // Gathered changes wait out the window after the last push, then go as one.
      p.changed(me, { urgent: false });
      p.changed(me, { urgent: false });
      p.notified(me, "run_completed");
      expect(p.pending(me)).toEqual({ urgent: false, batch: true });
      await sleep(30);
      expect(sender.sent).toHaveLength(1);
      await sleep(600);
      await p.idle();
      expect(sender.sent).toHaveLength(2);
      expect(sender.sent[1]?.urgent).toBe(false);

      // An approval in the inbox doesn't wait for the window.
      p.notified(me, "approval_request");
      await sleep(80);
      await p.idle();
      expect(sender.sent).toHaveLength(3);
      expect(sender.sent[2]?.urgent).toBe(true);
    } finally {
      p.stop();
    }
  });

  it("hears run events for people with a widget, and routine tools once they finish", async () => {
    const sender = new RecordingWidgetPushSender();
    const p = new GlancePusher(h.db, sender, { batchEveryMs: 0, urgentDelayMs: 10 });
    try {
      p.observe(runId, "message.delta", {});
      p.observe(runId, "tool.started", { call_id: "x", tool: "web.search" });
      p.observe(runId, "tool.completed", { call_id: "x" });
      await p.idle();
      await sleep(30);
      expect(sender.sent).toHaveLength(0);

      p.observe(runId, "tool.started", { call_id: "r1", tool: "routines.create" });
      await p.idle();
      await sleep(30);
      expect(sender.sent).toHaveLength(0);
      p.observe(runId, "tool.completed", { call_id: "r1" });
      await p.idle();
      await sleep(30);
      await p.idle();
      expect(sender.sent).toHaveLength(1);
      expect(sender.sent[0]?.urgent).toBe(false);

      p.observe(runId, "approval.requested", {});
      await p.idle();
      await sleep(40);
      await p.idle();
      expect(sender.sent).toHaveLength(2);
      expect(sender.sent[1]?.urgent).toBe(true);
    } finally {
      p.stop();
    }
  });

  it("forgets tokens the push service says are gone, keeping the key", async () => {
    const sender = new RecordingWidgetPushSender();
    sender.invalid = ["gone-token-1"];
    const p = new GlancePusher(h.db, sender);
    await p.send(me, true);
    const rows = await tdb.admin<
      { key_hash: string; push_token: string | null; push_kind: string | null }[]
    >`
      select key_hash, push_token, push_kind from public.widget_keys where user_id = ${me} order by key_hash`;
    expect(rows.map((r) => [r.key_hash[0], r.push_token, r.push_kind])).toEqual([
      ["a", "apple-token-1", "apns_widgets"],
      ["b", null, null],
      ["c", null, null],
    ]);
    // Nobody with a token: nothing sent.
    sender.sent.length = 0;
    await p.send("00000000-0000-0000-0000-000000000000", true);
    expect(sender.sent).toEqual([]);
    p.stop();
  });

  it("sends nothing after it stops", async () => {
    const sender = new RecordingWidgetPushSender();
    const p = new GlancePusher(h.db, sender, { urgentDelayMs: 10 });
    p.changed(me, { urgent: true });
    p.stop();
    p.changed(me, { urgent: true });
    await sleep(40);
    await p.idle();
    expect(sender.sent).toEqual([]);
  });
});
