/**
 * Billing audit 2026-11-17: a live call paid from credits goes through the server's relay. The
 * app gets a relay secret, not the Gemini token; frames pass through unchanged; the call is charged
 * what Gemini reported through the relay, whatever the app says.
 */
import { createServer } from "node:http";
import type { AddressInfo } from "node:net";
import { fileURLToPath } from "node:url";
import { sql } from "drizzle-orm";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { WebSocket, WebSocketServer } from "ws";
import { relayedCalls } from "../src/api/live-relay.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = fileURLToPath(new URL("./fixtures/chat.json", import.meta.url));
const GEMINI_TOKEN = "auth_tokens/relay-test-token";

/** Gemini's token endpoint and its Live WebSocket, as far as a call needs them. */
async function fakeGemini() {
  const seen: { tokens: string[]; frames: string[] } = { tokens: [], frames: [] };
  const server = createServer((req, res) => {
    const path = (req.url ?? "").split("?")[0];
    req.resume();
    req.on("end", () => {
      if (path === "/v1beta/auth_tokens") {
        res.writeHead(200, { "content-type": "application/json" });
        return res.end(JSON.stringify({ name: GEMINI_TOKEN }));
      }
      res.writeHead(404);
      res.end();
    });
  });
  const wss = new WebSocketServer({ noServer: true });
  server.on("upgrade", (req, socket, head) => {
    const url = new URL(req.url ?? "/", "http://x");
    seen.tokens.push(url.searchParams.get("access_token") ?? "");
    wss.handleUpgrade(req, socket, head, (ws) => {
      ws.on("message", (data) => {
        const text = data.toString();
        seen.frames.push(text);
        if (text.includes('"setup"')) {
          // Gemini sends binary frames holding JSON.
          ws.send(Buffer.from(JSON.stringify({ setupComplete: {} })), { binary: true });
          ws.send(
            Buffer.from(
              JSON.stringify({
                serverContent: { modelTurn: { parts: [{ inlineData: { data: "AAAA" } }] } },
                usageMetadata: {
                  // The total holds 500 tokens that the per-kind count doesn't.
                  promptTokenCount: 4500,
                  promptTokensDetails: [{ modality: "AUDIO", tokenCount: 4000 }],
                  responseTokensDetails: [{ modality: "AUDIO", tokenCount: 2000 }],
                },
              }),
            ),
            { binary: true },
          );
        }
      });
    });
  });
  await new Promise<void>((r) => server.listen(0, "127.0.0.1", r));
  return {
    url: `http://127.0.0.1:${(server.address() as AddressInfo).port}`,
    seen,
    close: () => {
      wss.close();
      server.close();
    },
  };
}

describe("live calls on credits go through the relay", () => {
  let gemini: Awaited<ReturnType<typeof fakeGemini>>;
  let h: Harness;
  let token: string;
  let orgId: string;
  let botId: string;

  beforeAll(async () => {
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
    const owner = await h.user("relay-owner@example.com");
    token = owner.token;
    orgId = (await j(await h.request("/v1/orgs", { method: "POST", token, json: { name: "R" } })))
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
            name: "Relay",
            model_policy: { primary: { credential_id: llm.id, model: "fixture-main" } },
          },
        }),
      )
    ).id;
    await h.handle.db.execute(
      sql`select public.credit_apply(${orgId}::uuid, 5, 'adjustment', 'relay-topup')`,
    );
  }, 120_000);

  afterAll(async () => {
    await h?.stop();
    gemini?.close();
  });

  /** The session's connect_url, pointed at this test's server instead of PUBLIC_API_URL. */
  const local = (connectUrl: string) =>
    connectUrl.replace("wss://api.example.test", (h.serverUrl as string).replace(/^http/, "ws"));

  it("relays the call, keeps the Gemini token on the server and bills Gemini's counts", async () => {
    const s = await j(
      await h.request("/v1/voice/session", { method: "POST", token, json: { bot_id: botId } }),
    );
    expect(s.connect_url).toBe(`wss://api.example.test/v1/voice/live/${s.live_call_id}/relay`);
    expect(s.client_secret).not.toBe(GEMINI_TOKEN);
    expect(JSON.stringify(s)).not.toContain(GEMINI_TOKEN);

    // A wrong secret is refused.
    const bad = new WebSocket(`${local(s.connect_url)}?access_token=nope`);
    const badCode = await new Promise<number>((r) => {
      bad.on("unexpected-response", (_req, res) => r(res.statusCode ?? 0));
      bad.on("error", () => r(-1));
    });
    expect(badCode).toBe(401);

    // The app's side, as the app does it: connect, send setup, read binary JSON frames.
    const ws = new WebSocket(`${local(s.connect_url)}?access_token=${s.client_secret}`);
    const got: Array<{ binary: boolean; text: string }> = [];
    await new Promise<void>((resolve, reject) => {
      ws.on("open", () => ws.send(JSON.stringify({ setup: s.setup ?? {} })));
      ws.on("message", (data, binary) => {
        got.push({ binary, text: data.toString() });
        if (got.length === 2) resolve();
      });
      ws.on("error", reject);
    });
    expect(gemini.seen.tokens).toEqual([GEMINI_TOKEN]);
    expect(gemini.seen.frames[0]).toContain('"setup"');
    expect(got.every((g) => g.binary)).toBe(true);
    expect(JSON.parse(got[0]?.text ?? "{}")).toEqual({ setupComplete: {} });
    ws.close();
    await new Promise((r) => ws.on("close", r));

    // The app reports almost nothing; the call is charged what Gemini reported.
    const saved = await h.request("/v1/voice/transcript", {
      method: "POST",
      token,
      json: {
        conversation_id: s.conversation_id,
        live_call_id: s.live_call_id,
        turns: [{ role: "user", text: "hi" }],
        seconds: 5,
        provider: "gemini",
        usage: {
          input_audio_tokens: 1,
          input_text_tokens: 0,
          output_audio_tokens: 1,
          output_text_tokens: 0,
        },
      },
    });
    expect(saved.status).toBe(200);
    const [row] = await h.handle.db.execute<{
      meta: { provider_cost_usd: number; tokens: Record<string, number> };
    }>(sql`
      select meta from public.usage_ledger
      where org_id = ${orgId}::uuid and kind = 'voice_seconds' and meta->>'live_call_id' = ${s.live_call_id}
        and not coalesce((meta->>'hold')::boolean, false)`);
    expect(row?.meta.tokens).toMatchObject({ input_audio_tokens: 4000, output_audio_tokens: 2000 });
    // What the total holds beyond the per-kind counts is kept with the call, and not charged: a
    // day's invoice can then show which of the two Google bills.
    expect(row?.meta.tokens.input_unattributed_tokens).toBe(500);
    expect(row?.meta.provider_cost_usd).toBeCloseTo(4000 * 3e-6 + 2000 * 12e-6, 6);

    // The call is over: its relay can't be opened again.
    const late = new WebSocket(`${local(s.connect_url)}?access_token=${s.client_secret}`);
    const lateCode = await new Promise<number>((r) => {
      late.on("unexpected-response", (_req, res) => r(res.statusCode ?? 0));
      late.on("open", () => r(101));
      late.on("error", () => r(-1));
    });
    expect(lateCode).toBe(410);
  }, 60_000);

  it("a restart closes the relay with 1012 after saving its counts, and the call resumes (D-402)", async () => {
    const s = await j(
      await h.request("/v1/voice/session", { method: "POST", token, json: { bot_id: botId } }),
    );
    const open = async () => {
      const ws = new WebSocket(`${local(s.connect_url)}?access_token=${s.client_secret}`);
      let frames = 0;
      await new Promise<void>((resolve, reject) => {
        ws.on("open", () => ws.send(JSON.stringify({ setup: s.setup ?? {} })));
        ws.on("message", () => {
          frames++;
          if (frames === 2) resolve();
        });
        ws.on("error", reject);
      });
      return ws;
    };
    const first = await open();
    const closed = new Promise<{ code: number; reason: string }>((r) =>
      first.on("close", (code, reason) => r({ code, reason: reason.toString() })),
    );
    await relayedCalls.closeAll();
    expect(await closed).toEqual({ code: 1012, reason: "server restarting" });
    // What the relay had counted is written before it lets go.
    const [relay] = await h.handle.db.execute<{ usage: Record<string, number> }>(sql`
      select usage from public.live_call_relays where live_call_id = ${s.live_call_id}::uuid`);
    expect(relay?.usage).toMatchObject({ input_audio_tokens: 4000, output_audio_tokens: 2000 });
    expect(relayedCalls.size).toBe(0);

    // The app resumes on the same relay address and secret (here the same process; in a deploy
    // the new API) and its counts add up.
    const resumed = await open();
    expect(relayedCalls.size).toBe(1);
    resumed.close();
    await new Promise((r) => resumed.on("close", r));
    await new Promise((r) => setTimeout(r, 100));
    const [after] = await h.handle.db.execute<{ usage: Record<string, number> }>(sql`
      select usage from public.live_call_relays where live_call_id = ${s.live_call_id}::uuid`);
    expect(after?.usage).toMatchObject({ input_audio_tokens: 8000, output_audio_tokens: 4000 });
  }, 60_000);
});
