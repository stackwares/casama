/** Phone-call voice (D-135): the bot rings the person's devices; answer, decline, miss, quiet hours. */
import { generateKeyPairSync, verify } from "node:crypto";
import { once } from "node:events";
import { createServer, type Http2Server, type ServerHttp2Stream } from "node:http2";
import type { AddressInfo } from "node:net";
import {
  ApnsVoipSender,
  expireCalls,
  NotificationService,
  RecordingPushSender,
  registerPhoneCallTools,
  ToolRegistry,
} from "@casama/agent";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
let apns: Http2Server;
let apnsUrl = "";
const apnsSeen: Array<{ path: string; headers: Record<string, string>; body: string }> = [];
const keys = generateKeyPairSync("ec", { namedCurve: "prime256v1" });
const keyP8 = keys.privateKey.export({ type: "pkcs8", format: "pem" }).toString();

let user: { id: string; token: string };
let orgId = "";
let botId = "";
let convId = "";
let runId = "";
const push = new RecordingPushSender();
let notifications: NotificationService;
const reg = new ToolRegistry();
const ctx = () => ({ runId, botId, orgId, output: async () => {}, emit: async () => {} }) as never;
const call = (reason: string) => reg.get("voice.call_user")!.execute({ reason } as never, ctx());

beforeAll(async () => {
  apns = createServer();
  apns.on("stream", (stream: ServerHttp2Stream, headers) => {
    let body = "";
    stream.on("data", (d) => {
      body += d;
    });
    stream.on("end", () => {
      apnsSeen.push({
        path: String(headers[":path"]),
        headers: headers as Record<string, string>,
        body,
      });
      stream.respond({ ":status": String(headers[":path"]).endsWith("/gone-token") ? 410 : 200 });
      stream.end();
    });
  });
  apns.listen(0, "127.0.0.1");
  await once(apns, "listening");
  apnsUrl = `http://127.0.0.1:${(apns.address() as AddressInfo).port}`;

  h = await startHarness();
  user = await h.user("caller@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: user.token, json: { name: "Calls" } }),
    )
  ).id;
  botId = (
    await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: user.token,
        json: { org_id: orgId, name: "Max" },
      }),
    )
  ).id;
  const [c] = await h.tdb.admin<{ id: string }[]>`
    insert into public.conversations (org_id, bot_id, title, created_by) values (${orgId}, ${botId}, 'Deploy', ${user.id}) returning id`;
  convId = c!.id;
  const [r] = await h.tdb.admin<{ id: string }[]>`
    insert into public.runs (org_id, bot_id, conversation_id, created_by) values (${orgId}, ${botId}, ${convId}, ${user.id}) returning id`;
  runId = r!.id;
  await h.tdb
    .admin`insert into public.devices (user_id, fcm_token, platform) values (${user.id}, 'android-1', 'android'), (${user.id}, 'ios-fcm', 'ios')`;
  await h.tdb
    .admin`insert into public.voip_tokens (user_id, token) values (${user.id}, 'iphone-token'), (${user.id}, 'gone-token')`;
  notifications = new NotificationService(h.handle.db, push);
  registerPhoneCallTools(reg, {
    db: h.handle.db,
    notifications,
    voip: new ApnsVoipSender({
      keyP8,
      keyId: "KEY123",
      teamId: "TEAM42",
      topic: "ai.casama.app.voip",
      url: apnsUrl,
    }),
  });
}, 60_000);
afterAll(async () => {
  await h?.stop();
  apns?.close();
});

describe("phone calls", () => {
  it("rings iOS through APNs VoIP, Android through high-priority FCM, and the app banner", async () => {
    const r = await call("The deploy failed and I need a yes or no on rolling back");
    expect(r.content).toContain("Calling them now");
    const [vc] = await h.tdb.admin<
      { id: string; status: string; conversation_id: string }[]
    >`select id, status, conversation_id from public.voice_calls where user_id = ${user.id}`;
    expect(vc).toMatchObject({ status: "ringing", conversation_id: convId });

    // APNs: a signed ES256 token, the VoIP push type and topic, the call in the payload.
    const sent = apnsSeen.find((s) => s.path === "/3/device/iphone-token")!;
    expect(sent.headers["apns-push-type"]).toBe("voip");
    expect(sent.headers["apns-topic"]).toBe("ai.casama.app.voip");
    const jwt = String(sent.headers.authorization).replace(/^bearer /, "");
    const [hd, pl, sig] = jwt.split(".");
    expect(JSON.parse(Buffer.from(hd!, "base64url").toString())).toEqual({
      alg: "ES256",
      kid: "KEY123",
    });
    expect(JSON.parse(Buffer.from(pl!, "base64url").toString()).iss).toBe("TEAM42");
    expect(
      verify(
        "sha256",
        Buffer.from(`${hd}.${pl}`),
        { key: keys.publicKey, dsaEncoding: "ieee-p1363" },
        Buffer.from(sig!, "base64url"),
      ),
    ).toBe(true);
    expect(JSON.parse(sent.body)).toMatchObject({
      kind: "call",
      call_id: vc!.id,
      bot_name: "Max",
      reason: expect.stringContaining("deploy failed"),
    });
    // A token APNs says is gone is removed.
    expect(
      (await h.tdb.admin`select token from public.voip_tokens where user_id = ${user.id}`).map(
        (t) => t.token,
      ),
    ).toEqual(["iphone-token"]);

    expect(push.calls).toHaveLength(1);
    expect(push.calls[0]).toMatchObject({
      tokens: ["android-1"],
      ttlSeconds: 45,
      data: { kind: "call", call_id: vc!.id, bot_id: botId },
    });
    const [banner] = await h.tdb.admin<
      { payload: { call_id: string } }[]
    >`select payload from public.notifications where user_id = ${user.id} and kind = 'call'`;
    expect(banner!.payload.call_id).toBe(vc!.id);

    await expect(call("again")).rejects.toThrow(/already ringing/);

    const ringing = (await j(await h.request("/v1/calls/ringing", { token: user.token }))).items;
    expect(ringing.map((c: { id: string }) => c.id)).toEqual([vc!.id]);

    // Answer: the live session uses the call's conversation and the bot speaks first.
    let greeting: string | undefined;
    (h.deps.workflows as { voiceSession: unknown }).voiceSession = async (
      _o: string,
      _b: string,
      g?: string,
    ) => {
      greeting = g;
      return {
        ok: true,
        model: "gpt-realtime",
        clientSecret: "ek_1",
        expiresAt: new Date().toISOString(),
        connectUrl: "http://x",
        tools: 3,
      };
    };
    expect(
      (await h.request(`/v1/calls/${vc!.id}/answer`, { method: "POST", token: user.token })).status,
    ).toBe(200);
    expect(
      (await h.request(`/v1/calls/${vc!.id}/answer`, { method: "POST", token: user.token })).status,
    ).toBe(409);
    const s = await j(
      await h.request("/v1/voice/session", {
        method: "POST",
        token: user.token,
        json: { bot_id: botId, call_id: vc!.id },
      }),
    );
    expect(s).toMatchObject({ conversation_id: convId, speak_first: true });
    expect(greeting).toContain("You called because: The deploy failed");
    const other = await h.user("other@example.com");
    expect((await h.request(`/v1/calls/${vc!.id}`, { token: other.token })).status).toBe(404);
  });

  it("a missed call and a declined call each become a normal push with the reason", async () => {
    await call("Your flight moved to 6am");
    await h.tdb
      .admin`update public.voice_calls set expires_at = now() - interval '1 second' where status = 'ringing'`;
    push.sent.length = 0;
    expect(await expireCalls({ db: h.handle.db, notifications })).toBe(1);
    expect(push.sent.map((p) => [p.message.title, p.message.body])).toEqual([
      ["Missed call from Max", "Your flight moved to 6am"],
    ]);

    await call("Can I book the 7am instead?");
    const [vc] = await h.tdb.admin<
      { id: string }[]
    >`select id from public.voice_calls where status = 'ringing'`;
    const d = await j(
      await h.request(`/v1/calls/${vc!.id}/decline`, { method: "POST", token: user.token }),
    );
    expect(d.status).toBe("declined");
    const [n] = await h.tdb.admin<
      { push_status: string; payload: { title: string; body: string } }[]
    >`
      select push_status, payload from public.notifications where kind = 'call_missed' and payload->>'call_id' = ${vc!.id}`;
    expect(n).toMatchObject({
      push_status: "deferred",
      payload: { title: "Max wanted to talk", body: "Can I book the 7am instead?" },
    });
  });

  it("doesn't ring during quiet hours; it leaves a notification instead", async () => {
    const hm = (d: Date) =>
      `${String(d.getUTCHours()).padStart(2, "0")}:${String(d.getUTCMinutes()).padStart(2, "0")}`;
    await h.tdb.admin`update public.profiles set timezone = 'UTC', quiet_hours = ${h.tdb.admin.json(
      {
        enabled: true,
        start: hm(new Date(Date.now() - 3_600_000)),
        end: hm(new Date(Date.now() + 3_600_000)),
      },
    )} where user_id = ${user.id}`;
    const before = (await h.tdb.admin`select 1 from public.voice_calls`).length;
    const r = await call("Quick question about lunch");
    expect(r.content).toContain("quiet hours");
    expect((await h.tdb.admin`select 1 from public.voice_calls`).length).toBe(before);
    const [n] = await h.tdb.admin<
      { push_status: string }[]
    >`select push_status from public.notifications where payload->>'body' = 'Quick question about lunch'`;
    expect(n?.push_status).toBe("deferred");
  });
});
