/** Calls for you (D-141): Twilio places the call, its media stream bridges to realtime voice. */
import { once } from "node:events";
import { createServer, type Server } from "node:http";
import type { AddressInfo } from "node:net";
import { fileURLToPath } from "node:url";
import { numberProblem, registerCallTools, ToolRegistry, twilioSignature } from "@casama/agent";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { WebSocket, WebSocketServer } from "ws";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = fileURLToPath(new URL("./fixtures/calls.json", import.meta.url));
const SID = `AC${"a".repeat(32)}`;
const TOKEN = "twilio-auth-token-0123456789";
let h: Harness;
let fake: Server;
let fakeUrl = "";
let realtime: WebSocketServer;
let realtimeUrl = "";
const twilioCalls: Array<{ params: Record<string, string> }> = [];
const twilioUpdates: Array<Record<string, string>> = [];
const aiSeen: string[] = [];
let aiAuth = "";

beforeAll(async () => {
  // A fake Twilio (REST + Lookup) and OpenAI client-secret endpoint.
  fake = createServer(async (req, res) => {
    const chunks: Buffer[] = [];
    for await (const c of req) chunks.push(c as Buffer);
    const body = Buffer.concat(chunks).toString();
    const url = new URL(req.url ?? "/", "http://x");
    const send = (s: number, x: unknown) =>
      res.writeHead(s, { "content-type": "application/json" }).end(JSON.stringify(x));
    if (url.pathname === `/2010-04-01/Accounts/${SID}.json`)
      return send(200, { sid: SID, status: "active" });
    if (url.pathname === `/2010-04-01/Accounts/${SID}/Calls.json`) {
      twilioCalls.push({ params: Object.fromEntries(new URLSearchParams(body)) });
      return send(201, { sid: `CA${twilioCalls.length}`, status: "queued" });
    }
    if (url.pathname.startsWith(`/2010-04-01/Accounts/${SID}/Calls/`)) {
      twilioUpdates.push(Object.fromEntries(new URLSearchParams(body)));
      return send(200, { sid: "CA1", status: "in-progress" });
    }
    if (url.pathname.startsWith("/v2/PhoneNumbers/"))
      return send(200, {
        caller_name: {
          caller_type: decodeURIComponent(url.pathname).endsWith("0100") ? "CONSUMER" : "BUSINESS",
        },
      });
    if (url.pathname === "/v1/realtime/client_secrets") {
      aiSeen.push(`secret:${body}`);
      return send(200, { value: "ek_phone", expires_at: Math.floor(Date.now() / 1000) + 600 });
    }
    send(404, {});
  }).listen(0, "127.0.0.1");
  await once(fake, "listening");
  fakeUrl = `http://127.0.0.1:${(fake.address() as AddressInfo).port}`;
  // A fake OpenAI realtime WebSocket: greets, hears "yes", confirms and ends the call.
  realtime = new WebSocketServer({ port: 0, host: "127.0.0.1" });
  await once(realtime, "listening");
  realtimeUrl = `ws://127.0.0.1:${(realtime.address() as AddressInfo).port}/v1/realtime`;
  realtime.on("connection", (ws, req) => {
    aiAuth = String(req.headers.authorization);
    let heard = 0;
    ws.on("message", (raw) => {
      const e = JSON.parse(String(raw)) as { type: string };
      aiSeen.push(e.type);
      if (e.type === "response.create") {
        ws.send(
          JSON.stringify({
            type: "response.output_audio.delta",
            delta: Buffer.from("hello-audio").toString("base64"),
          }),
        );
        ws.send(
          JSON.stringify({
            type: "response.output_audio_transcript.done",
            transcript: "Hi, I'm Max, an AI assistant calling on behalf of Ana to book a table.",
          }),
        );
      }
      if (e.type === "input_audio_buffer.append" && ++heard === 2) {
        ws.send(JSON.stringify({ type: "input_audio_buffer.speech_started" }));
        ws.send(
          JSON.stringify({
            type: "conversation.item.input_audio_transcription.completed",
            transcript: "Sure, 7pm for two works.",
          }),
        );
        ws.send(
          JSON.stringify({
            type: "response.output_audio_transcript.done",
            transcript: "Wonderful, thank you. Goodbye!",
          }),
        );
        ws.send(
          JSON.stringify({
            type: "response.function_call_arguments.done",
            name: "end_call",
            arguments: "{}",
          }),
        );
      }
    });
  });
  h = await startHarness({
    serve: true,
    env: { TWILIO_API_URL: fakeUrl, OPENAI_REALTIME_URL: realtimeUrl },
    worker: {
      fixtures: FIXTURES,
      egressExemptCidrs: ["127.0.0.1/32"],
      providerBases: { twilio: fakeUrl, twilioLookups: fakeUrl, openai: fakeUrl },
      publicApiUrl: "self",
    },
  });
}, 90_000);
afterAll(async () => {
  await h?.stop();
  fake?.close();
  realtime?.close();
});

const waitFor = async <T>(
  fn: () => Promise<T | undefined | null | false>,
  what: string,
  ms = 30_000,
): Promise<T> => {
  const until = Date.now() + ms;
  for (;;) {
    const v = await fn();
    if (v) return v;
    if (Date.now() > until) throw new Error(`timed out waiting for ${what}`);
    await new Promise((r) => setTimeout(r, 100));
  }
};

async function setup(email: string) {
  const u = await h.user(email);
  await h.tdb.admin`update public.profiles set display_name = 'Ana' where user_id = ${u.id}`;
  const orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: u.token, json: { name: "Calls" } }),
    )
  ).id;
  const cred = (
    await j(
      await h.request("/v1/credentials", {
        method: "POST",
        token: u.token,
        json: { org_id: orgId, provider: "openai", label: "o", api_key: "sk-openai-calls" },
      }),
    )
  ).id;
  const bot = await j(
    await h.request("/v1/bots", {
      method: "POST",
      token: u.token,
      json: {
        org_id: orgId,
        name: "Max",
        autonomy: "autonomous",
        model_policy: { primary: { credential_id: cred, model: "fixture-main" } },
      },
    }),
  );
  const set = await h.request(`/v1/orgs/${orgId}/telephony`, {
    method: "PUT",
    token: u.token,
    json: { account_sid: SID, auth_token: TOKEN, from_number: "+14155550000" },
  });
  expect(set.status).toBe(200);
  return { u, orgId, bot };
}

/** Plays Twilio: connects to the media stream from the TwiML and sends audio. */
async function answer(twiml: string) {
  const url = /<Stream url="([^"]+)">/.exec(twiml)![1]!;
  const token = /name="token" value="([^"]+)"/.exec(twiml)![1]!;
  const ws = new WebSocket(url);
  await once(ws, "open");
  const fromBridge: Array<{ event: string; media?: { payload: string } }> = [];
  ws.on("message", (m) => fromBridge.push(JSON.parse(String(m))));
  ws.send(JSON.stringify({ event: "connected" }));
  ws.send(
    JSON.stringify({
      event: "start",
      streamSid: "MZ1",
      start: { streamSid: "MZ1", callSid: "CA1", customParameters: { token } },
    }),
  );
  return { ws, fromBridge, url };
}

describe("calls for you", () => {
  it("the bot calls a business, says it's an AI, talks and hangs up; the run gets the transcript", async () => {
    const { u, bot } = await setup("ana@example.com");
    const conv = await j(
      await h.request("/v1/conversations", {
        method: "POST",
        token: u.token,
        json: { bot_id: bot.id },
      }),
    );
    const runId = (
      await j(
        await h.request(`/v1/conversations/${conv.id}/messages`, {
          method: "POST",
          token: u.token,
          json: { text: "Call Luigi's and book us a table" },
        }),
      )
    ).run_id;

    const placed = await waitFor(async () => twilioCalls[0], "Twilio call");
    expect(placed.params).toMatchObject({
      To: "+14155550199",
      From: "+14155550000",
      Record: "false",
    });
    expect(placed.params.StatusCallback).toMatch(/\/hooks\/telephony\/[0-9a-f-]{36}$/);
    const callId = placed.params.StatusCallback!.split("/").pop()!;

    // A stream with the wrong token is dropped.
    const bad = new WebSocket(/<Stream url="([^"]+)">/.exec(placed.params.Twiml!)![1]!);
    await once(bad, "open");
    bad.send(
      JSON.stringify({
        event: "start",
        start: { streamSid: "MZ0", callSid: "CA1", customParameters: { token: "nope" } },
      }),
    );
    await once(bad, "close");

    const tw = await answer(placed.params.Twiml!);
    // The bot speaks first; its audio reaches Twilio.
    await waitFor(async () => tw.fromBridge.find((m) => m.event === "media"), "bot audio");
    expect(
      Buffer.from(
        tw.fromBridge.find((m) => m.event === "media")!.media!.payload,
        "base64",
      ).toString(),
    ).toBe("hello-audio");
    expect(aiAuth).toBe("Bearer ek_phone");
    const secretReq = JSON.parse(aiSeen.find((s) => s.startsWith("secret:"))!.slice(7));
    expect(secretReq.session.audio.input.format).toEqual({ type: "audio/pcmu" });
    expect(secretReq.session.instructions).toContain("AI assistant calling on behalf of Ana");
    expect(secretReq.session.tools.map((t: { name: string }) => t.name)).toEqual(["end_call"]);
    // The other side talks; barge-in clears the bot's audio; then end_call hangs up.
    for (let i = 0; i < 2; i++)
      tw.ws.send(
        JSON.stringify({
          event: "media",
          streamSid: "MZ1",
          media: { payload: Buffer.from(`callee-${i}`).toString("base64") },
        }),
      );
    await waitFor(async () => tw.fromBridge.find((m) => m.event === "clear"), "barge-in clear");
    await once(tw.ws, "close");

    // Twilio reports the call completed (signed).
    const path = `/hooks/telephony/${callId}`;
    const params = { CallSid: "CA1", CallStatus: "completed", CallDuration: "75" };
    const unsigned = await fetch(`${h.serverUrl}${path}`, {
      method: "POST",
      headers: { "content-type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams(params).toString(),
    });
    expect(unsigned.status).toBe(401);
    const signed = await fetch(`${h.serverUrl}${path}`, {
      method: "POST",
      headers: {
        "content-type": "application/x-www-form-urlencoded",
        "x-twilio-signature": twilioSignature(`${h.serverUrl}${path}`, params, TOKEN),
      },
      body: new URLSearchParams(params).toString(),
    });
    expect(signed.status).toBe(204);

    await waitFor(
      async () =>
        (await j(await h.request(`/v1/runs/${runId}`, { token: u.token }))).status === "completed",
      "run",
      60_000,
    );
    const call = await j(await h.request(`/v1/outbound-calls/${callId}`, { token: u.token }));
    expect(call).toMatchObject({ status: "completed", seconds: 75 });
    expect(call.transcript).toEqual([
      {
        role: "bot",
        text: "Hi, I'm Max, an AI assistant calling on behalf of Ana to book a table.",
      },
      { role: "callee", text: "Sure, 7pm for two works." },
      { role: "bot", text: "Wonderful, thank you. Goodbye!" },
    ]);
    const evs = (await j(await h.request(`/v1/runs/${runId}/events?limit=200`, { token: u.token })))
      .items as Array<{ type: string; payload: Record<string, unknown> }>;
    expect(evs.find((e) => e.type === "tool.completed")?.payload.result_preview).toBe(
      "completed · 3 lines",
    );
    const [usage] = await h.tdb.admin<
      { quantity: string }[]
    >`select quantity from public.usage_ledger where kind = 'phone_minutes'`;
    expect(Number(usage!.quantity)).toBe(2);
  }, 90_000);

  it("refuses emergency, short, denied, personal and over-cap numbers", async () => {
    expect(numberProblem("911")).toMatch(/Emergency/);
    expect(numberProblem("+1911")).not.toBeNull();
    expect(numberProblem("+112")).not.toBeNull();
    expect(numberProblem("555-0199")).toMatch(/international/);
    expect(numberProblem("+14155550199")).toBeNull();

    const { orgId, bot, u } = await setup("rules@example.com");
    const [run] = await h.tdb.admin<
      { id: string }[]
    >`insert into public.runs (org_id, bot_id, created_by) values (${orgId}, ${bot.id}, ${u.id}) returning id`;
    const ctx = {
      runId: run!.id,
      botId: bot.id,
      orgId,
      output: async () => {},
      emit: async () => {},
    } as never;
    const reg = new ToolRegistry();
    const { TwilioClient } = await import("@casama/agent");
    let cap = 1;
    registerCallTools(reg, {
      db: h.handle.db,
      publicApiUrl: h.serverUrl,
      maxWaitMs: 1,
      twilioFor: async () => ({
        accountSid: SID,
        authToken: TOKEN,
        fromNumber: "+14155550000",
        allowPersonal: false,
        dailyCap: cap,
        client: new TwilioClient({
          accountSid: SID,
          authToken: TOKEN,
          apiUrl: fakeUrl,
          lookupsUrl: fakeUrl,
        }),
      }),
    });
    const call = (number: string) =>
      reg.get("voice.call")!.execute({ number, purpose: "Ask opening hours" } as never, ctx);
    await expect(call("112")).rejects.toThrow(/Emergency/);
    await h.tdb
      .admin`insert into public.call_deny_list (prefix, reason) values ('+1900', 'premium rate')`;
    await expect(call("+19005550123")).rejects.toThrow(/may not call/);
    await expect(call("+14155550100")).rejects.toThrow(/personal number/);
    const ok = await call("+14155550123");
    expect(ok.content).toContain("still going");
    await expect(call("+14155550124")).rejects.toThrow(/daily limit of 1/);
    cap = 10;

    // The person ends the call, or takes it over to their own phone.
    const [c] = await h.tdb.admin<
      { id: string }[]
    >`select id from public.outbound_calls where number = '+14155550123'`;
    const taken = await h.request(`/v1/outbound-calls/${c!.id}/take-over`, {
      method: "POST",
      token: u.token,
      json: { phone: "+14155557777" },
    });
    expect(taken.status).toBe(200);
    expect(twilioUpdates.at(-1)!.Twiml).toContain(
      '<Dial callerId="+14155550000">+14155557777</Dial>',
    );
    expect((await j(taken)).status).toBe("taken_over");
    await call("+14155550125");
    const [c2] = await h.tdb.admin<
      { id: string }[]
    >`select id from public.outbound_calls where number = '+14155550125'`;
    expect(
      (
        await j(
          await h.request(`/v1/outbound-calls/${c2!.id}/end`, { method: "POST", token: u.token }),
        )
      ).status,
    ).toBe("ended_by_user");
    expect(twilioUpdates.at(-1)).toMatchObject({ Status: "completed" });
  });
});
