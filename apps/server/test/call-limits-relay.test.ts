/**
 * Call limits on relayed calls (D-426): the relay warns the bot before a call's longest length,
 * asks it for a goodbye at the limit, closes the stream with 4410 and ends the call (billed, recap
 * posted), and takes no reconnect after. Money limits (here the bot's daily budget) end a call the
 * same way, and a call can't start already past one.
 */
import { createServer } from "node:http";
import type { AddressInfo } from "node:net";
import { fileURLToPath } from "node:url";
import { setCallLimits } from "@casama/domain";
import { sql } from "drizzle-orm";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { WebSocket, WebSocketServer } from "ws";
import { CALL_OVER_CLOSE, limitNote, relayTiming } from "../src/api/live-relay.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = fileURLToPath(new URL("./fixtures/chat.json", import.meta.url));

/** Gemini as far as a call needs it; it answers a goodbye note with a short spoken turn. */
async function fakeGemini() {
  const notes: string[] = [];
  const server = createServer((req, res) => {
    req.resume();
    req.on("end", () => {
      res.writeHead(200, { "content-type": "application/json" });
      res.end(JSON.stringify({ name: "auth_tokens/limits" }));
    });
  });
  const wss = new WebSocketServer({ noServer: true });
  server.on("upgrade", (req, socket, head) => {
    wss.handleUpgrade(req, socket, head, (ws) => {
      ws.on("message", (data) => {
        const text = data.toString();
        if (text.includes('"setup"'))
          ws.send(Buffer.from(JSON.stringify({ setupComplete: {} })), { binary: true });
        if (text.includes("Note from Casama")) {
          notes.push(text);
          ws.send(
            Buffer.from(
              JSON.stringify({
                serverContent: { modelTurn: { parts: [{ inlineData: { data: "AAAA" } }] } },
              }),
            ),
            { binary: true },
          );
          ws.send(Buffer.from(JSON.stringify({ serverContent: { turnComplete: true } })), {
            binary: true,
          });
        }
      });
    });
  });
  await new Promise<void>((r) => server.listen(0, "127.0.0.1", r));
  return {
    url: `http://127.0.0.1:${(server.address() as AddressInfo).port}`,
    notes,
    close: () => {
      wss.close();
      server.close();
    },
  };
}

const until = async (check: () => Promise<boolean> | boolean, ms = 10_000) => {
  const end = Date.now() + ms;
  while (Date.now() < end) {
    if (await check()) return true;
    await new Promise((r) => setTimeout(r, 50));
  }
  return false;
};

describe("call limits on relayed calls (D-426)", () => {
  let gemini: Awaited<ReturnType<typeof fakeGemini>>;
  let h: Harness;
  let token: string;
  let orgId: string;
  let botId: string;
  const saved = { ...relayTiming };

  beforeAll(async () => {
    Object.assign(relayTiming, {
      guardMs: 300,
      firstGuardMs: 50,
      goodbyeMaxMs: 3_000,
      appEndGraceMs: 300,
    });
    gemini = await fakeGemini();
    h = await startHarness({
      serve: true,
      env: {
        GOOGLE_AI_API_KEY: "server-gemini-key",
        BILLING_ENABLED: "true",
        PUBLIC_API_URL: "https://api.example.test",
      },
      worker: { fixtures: FIXTURES, providerBases: { gemini: gemini.url } },
    });
    const owner = await h.user("limits-owner@example.com");
    token = owner.token;
    orgId = (await j(await h.request("/v1/orgs", { method: "POST", token, json: { name: "L" } })))
      .id;
    const llm = await j(
      await h.request("/v1/credentials", {
        method: "POST",
        token,
        json: { org_id: orgId, provider: "openrouter", label: "llm", api_key: "sk-llm" },
      }),
    );
    botId = (
      await j(
        await h.request("/v1/bots", {
          method: "POST",
          token,
          json: {
            org_id: orgId,
            name: "Limits",
            model_policy: { primary: { credential_id: llm.id, model: "fixture-main" } },
          },
        }),
      )
    ).id;
    await h.handle.db.execute(
      sql`select public.credit_apply(${orgId}::uuid, 5, 'adjustment', 'limits-topup')`,
    );
  }, 120_000);

  afterAll(async () => {
    Object.assign(relayTiming, saved);
    setCallLimits(null);
    await h?.stop();
    gemini?.close();
  });

  const local = (connectUrl: string) =>
    connectUrl.replace("wss://api.example.test", (h.serverUrl as string).replace(/^http/, "ws"));

  const start = async () =>
    j(await h.request("/v1/voice/session", { method: "POST", token, json: { bot_id: botId } }));

  /** The app's side: connect, send setup, and note how the stream closed. */
  const connect = async (s: { connect_url: string; client_secret: string; setup?: unknown }) => {
    const ws = new WebSocket(`${local(s.connect_url)}?access_token=${s.client_secret}`);
    const closed = new Promise<{ code: number; reason: string }>((r) =>
      ws.on("close", (code, reason) => r({ code, reason: reason.toString() })),
    );
    await new Promise<void>((resolve, reject) => {
      ws.on("open", () => ws.send(JSON.stringify({ setup: s.setup ?? {} })));
      ws.once("message", () => resolve());
      ws.on("error", reject);
    });
    return { ws, closed };
  };

  const call = async (id: string) =>
    (
      await h.handle.db.execute<{
        ended: boolean;
        end_reason: string | null;
        limit_reason: string | null;
        warned: boolean;
      }>(sql`
        select ended_at is not null as ended, end_reason, limit_reason,
          limit_warned_at is not null as warned
        from public.live_calls where id = ${id}::uuid`)
    )[0];

  it("sends the app its limits; a relayed call is ended by the server, not the app", async () => {
    setCallLimits({ silence_seconds: 30 });
    const s = await start();
    expect(s.limits).toEqual({
      silence_seconds: 30,
      heartbeat_seconds: 15,
      max_call_seconds: 3600,
      warning_seconds: 60,
      app_ends_at_max: false,
    });
    await h.request("/v1/voice/transcript", {
      method: "POST",
      token,
      json: {
        conversation_id: s.conversation_id,
        live_call_id: s.live_call_id,
        turns: [],
        seconds: 0,
      },
    });
  });

  it("warns the bot a minute before the longest length, then says goodbye, closes and ends the call", async () => {
    setCallLimits({ max_call_minutes: 5, warning_seconds: 60 });
    const s = await start();
    // Four and a half minutes in: inside the warning.
    await h.handle.db.execute(
      sql`update public.live_calls set started_at = now() - interval '270 seconds' where id = ${s.live_call_id}::uuid`,
    );
    const { ws, closed } = await connect(s);
    expect(await until(() => gemini.notes.length >= 1)).toBe(true);
    expect(gemini.notes[0]).toContain("5-minute limit in about a minute");
    expect(gemini.notes[0]).toContain('"turnComplete":true');
    expect(await call(s.live_call_id)).toMatchObject({
      warned: true,
      limit_reason: "max_length",
      ended: false,
    });
    // It warns once, however many checks run.
    await new Promise((r) => setTimeout(r, 800));
    expect(gemini.notes).toHaveLength(1);

    // Past five minutes: a goodbye, then the stream closes with "call over".
    await h.handle.db.execute(
      sql`update public.live_calls set started_at = now() - interval '301 seconds' where id = ${s.live_call_id}::uuid`,
    );
    const how = await closed;
    expect(how).toEqual({ code: CALL_OVER_CLOSE, reason: "call over: max_length" });
    expect(gemini.notes[1]).toContain("reached its 5-minute limit");
    expect(gemini.notes[1]).toContain("Say goodbye");
    ws.terminate();

    // The app didn't end it, so the relay does: billed, recap posted, reason kept.
    expect(await until(async () => (await call(s.live_call_id))?.ended === true)).toBe(true);
    expect(await call(s.live_call_id)).toMatchObject({ end_reason: "max_length" });
    const recap = async () =>
      (
        await h.handle.db.execute(sql`
          select 1 from public.messages where conversation_id = ${s.conversation_id}::uuid and role = 'assistant'`)
      ).length === 1;
    expect(await until(recap)).toBe(true);
    const [hold] = await h.handle.db.execute<{ settled: boolean }>(sql`
      select coalesce((meta->>'settled')::boolean, false) as settled from public.usage_ledger
      where meta->>'live_call_id' = ${s.live_call_id} and (meta->>'hold')::boolean`);
    expect(hold?.settled).toBe(true);

    // No reconnect after a call is over.
    const late = new WebSocket(`${local(s.connect_url)}?access_token=${s.client_secret}`);
    const lateCode = await new Promise<number>((r) => {
      late.on("unexpected-response", (_req, res) => r(res.statusCode ?? 0));
      late.on("open", () => r(101));
      late.on("error", () => r(-1));
    });
    expect(lateCode).toBe(410);
  }, 30_000);

  it("an app that ends the call itself after the close keeps the limit as the reason", async () => {
    setCallLimits({ max_call_minutes: 5 });
    gemini.notes.length = 0;
    const s = await start();
    await h.handle.db.execute(
      sql`update public.live_calls set started_at = now() - interval '301 seconds' where id = ${s.live_call_id}::uuid`,
    );
    relayTiming.appEndGraceMs = 5_000;
    const { closed } = await connect(s);
    expect((await closed).code).toBe(CALL_OVER_CLOSE);
    const r = await h.request("/v1/voice/transcript", {
      method: "POST",
      token,
      json: {
        conversation_id: s.conversation_id,
        live_call_id: s.live_call_id,
        turns: [{ role: "assistant", text: "That's our time, talk soon." }],
        seconds: 301,
      },
    });
    expect(r.status).toBe(200);
    relayTiming.appEndGraceMs = 300;
    expect(await call(s.live_call_id)).toMatchObject({ ended: true, end_reason: "max_length" });
  }, 30_000);

  it("ends the call when the bot's daily budget runs out, and refuses a call past it", async () => {
    setCallLimits({});
    gemini.notes.length = 0;
    const s = await start();
    // The hold alone is now over the bot's budget for today.
    await h.handle.db.execute(
      sql`update public.bots set budget = '{"daily_usd": 0.0001}'::jsonb where id = ${botId}::uuid`,
    );
    const { closed } = await connect(s);
    expect(await closed).toEqual({ code: CALL_OVER_CLOSE, reason: "call over: bot_budget" });
    expect(gemini.notes[0]).toContain("used your daily budget");
    expect(await until(async () => (await call(s.live_call_id))?.ended === true)).toBe(true);
    expect(await call(s.live_call_id)).toMatchObject({ end_reason: "bot_budget" });

    const refused = await h.request("/v1/voice/session", {
      method: "POST",
      token,
      json: { bot_id: botId },
    });
    expect(refused.status).toBe(402);
    expect((await j(refused)).code).toBe("daily_budget_exceeded");
    await h.handle.db.execute(
      sql`update public.bots set budget = '{}'::jsonb where id = ${botId}::uuid`,
    );
  }, 30_000);

  it("the notes name the reason", () => {
    expect(limitNote("credits", "warn")).toContain("nearly out of credits");
    expect(limitNote("daily_cap", "goodbye")).toContain("today's spending limit");
    expect(limitNote("quota", "warn")).toContain("monthly spending limit");
  });
});
