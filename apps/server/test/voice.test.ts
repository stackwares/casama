import { createServer, type IncomingMessage } from "node:http";
import type { AddressInfo } from "node:net";
import { fileURLToPath } from "node:url";
import { sql } from "drizzle-orm";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = fileURLToPath(new URL("./fixtures/chat.json", import.meta.url));

/** One local server standing in for OpenAI, Deepgram and ElevenLabs (their REST shapes). */
async function mockVoiceProviders() {
  const calls: Array<{ path: string; headers: IncomingMessage["headers"]; body: string }> = [];
  const server = createServer((req, res) => {
    const chunks: Buffer[] = [];
    req.on("data", (c) => chunks.push(c));
    req.on("end", () => {
      const body = Buffer.concat(chunks);
      const path = (req.url ?? "").split("?")[0] ?? "";
      calls.push({ path, headers: req.headers, body: body.toString("latin1") });
      const json = (o: unknown) => {
        res.writeHead(200, { "content-type": "application/json" });
        res.end(JSON.stringify(o));
      };
      if (path === "/v1/audio/transcriptions")
        return json({ text: "remind me to water the plants", duration: 3.2 });
      if (path === "/v1/listen")
        return json({
          metadata: { duration: 2 },
          results: { channels: [{ alternatives: [{ transcript: "deepgram heard you" }] }] },
        });
      if (path.startsWith("/v1/text-to-speech/") || path === "/v1/audio/speech") {
        res.writeHead(200, { "content-type": "audio/mpeg" });
        return res.end(Buffer.from("ID3-fake-mp3"));
      }
      if (path === "/v1/realtime/client_secrets")
        return json({
          value: "ek_test_ephemeral",
          expires_at: Math.floor(Date.now() / 1000) + 600,
        });
      res.writeHead(404);
      res.end();
    });
  });
  await new Promise<void>((r) => server.listen(0, "127.0.0.1", r));
  return {
    url: `http://127.0.0.1:${(server.address() as AddressInfo).port}`,
    calls,
    close: () => server.close(),
  };
}

describe("voice (Phase 6)", () => {
  let h: Harness;
  let mock: Awaited<ReturnType<typeof mockVoiceProviders>>;
  let owner: { id: string; token: string };
  let orgId: string;
  let botId: string;
  let convId: string;

  const addKey = (provider: string, api_key: string) =>
    h.request("/v1/credentials", {
      method: "POST",
      token: owner.token,
      json: { org_id: orgId, provider, label: provider, api_key },
    });

  beforeAll(async () => {
    mock = await mockVoiceProviders();
    h = await startHarness({
      worker: {
        fixtures: FIXTURES,
        providerBases: { openai: mock.url, deepgram: mock.url, elevenlabs: mock.url },
      },
    });
    owner = await h.user("voice-owner@example.com");
    orgId = (
      await j(
        await h.request("/v1/orgs", {
          method: "POST",
          token: owner.token,
          json: { name: "Voice" },
        }),
      )
    ).id;
    const llm = await j(await addKey("openrouter", "sk-voice-llm-key"));
    expect((await addKey("openai", "sk-voice-openai-key")).status).toBe(201);
    const bot = await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: owner.token,
        json: {
          org_id: orgId,
          name: "Vox",
          persona_md: "You love plants.",
          autonomy: "autonomous",
          model_policy: { primary: { credential_id: llm.id, model: "fixture-main" } },
        },
      }),
    );
    botId = bot.id;
    convId = (
      await j(
        await h.request("/v1/conversations", {
          method: "POST",
          token: owner.token,
          json: { bot_id: botId },
        }),
      )
    ).id;
  }, 120_000);
  afterAll(async () => {
    await h?.stop();
    mock?.close();
  });

  it("dictation transcribes with the org's own key and records usage", async () => {
    const res = await h.request(`/v1/voice/transcribe?bot_id=${botId}`, {
      method: "POST",
      token: owner.token,
      headers: { "content-type": "audio/webm" },
      body: new Uint8Array([1, 2, 3, 4]),
    });
    expect(res.status).toBe(200);
    expect(await j(res)).toMatchObject({
      text: "remind me to water the plants",
      provider: "openai",
      seconds: 4,
    });
    const call = mock.calls.find((c) => c.path === "/v1/audio/transcriptions");
    expect(call?.headers.authorization).toBe("Bearer sk-voice-openai-key");
    const [u] = await h.handle.db.execute<{ q: string }>(
      sql`select sum(quantity)::text as q from public.usage_ledger where kind = 'stt_seconds'`,
    );
    expect(Number(u?.q)).toBe(4);
  }, 60_000);

  it("a bot can prefer Deepgram for dictation", async () => {
    expect((await addKey("deepgram", "dg-voice-key")).status).toBe(201);
    await h.handle.db.execute(
      sql`update public.bots set voice = '{"stt_provider":"deepgram"}' where id = ${botId}::uuid`,
    );
    const res = await j(
      await h.request(`/v1/voice/transcribe?bot_id=${botId}`, {
        method: "POST",
        token: owner.token,
        headers: { "content-type": "audio/wav" },
        body: new Uint8Array([9, 9]),
      }),
    );
    expect(res).toMatchObject({ text: "deepgram heard you", provider: "deepgram" });
    expect(mock.calls.find((c) => c.path === "/v1/listen")?.headers.authorization).toBe(
      "Token dg-voice-key",
    );
  }, 60_000);

  it("read aloud speaks a bot message once and serves it from the cache after", async () => {
    expect((await addKey("elevenlabs", "el-voice-key")).status).toBe(201);
    const [m] = await h.handle.db.execute<{ id: string }>(sql`
      insert into public.messages (org_id, conversation_id, role, content)
      values (${orgId}::uuid, ${convId}::uuid, 'assistant', '[{"type":"text","text":"Water the fern on Fridays."}]'::jsonb)
      returning id`);
    const first = await h.request(`/v1/messages/${m?.id}/speech`, { token: owner.token });
    expect(first.status).toBe(200);
    expect(first.headers.get("content-type")).toBe("audio/mpeg");
    expect(Buffer.from(await first.arrayBuffer()).toString()).toBe("ID3-fake-mp3");
    const second = await h.request(`/v1/messages/${m?.id}/speech`, { token: owner.token });
    expect(second.status).toBe(200);
    expect(mock.calls.filter((c) => c.path.startsWith("/v1/text-to-speech/"))).toHaveLength(1);
    expect(
      mock.calls.find((c) => c.path.startsWith("/v1/text-to-speech/"))?.headers["xi-api-key"],
    ).toBe("el-voice-key");
  }, 60_000);

  it("a live call session carries the persona and the bot's tools; tool calls run with approvals", async () => {
    const t0 = performance.now();
    const res = await h.request("/v1/voice/session", {
      method: "POST",
      token: owner.token,
      json: { bot_id: botId, conversation_id: convId },
    });
    const mintMs = performance.now() - t0;
    expect(res.status).toBe(200);
    const s = await j(res);
    expect(s).toMatchObject({
      provider: "openai",
      model: "gpt-realtime-2.1",
      client_secret: "ek_test_ephemeral",
      conversation_id: convId,
    });
    const minted = JSON.parse(
      mock.calls.find((c) => c.path === "/v1/realtime/client_secrets")?.body ?? "{}",
    );
    expect(minted.session.instructions).toContain("You love plants.");
    expect(minted.session.tools.map((t: { name: string }) => t.name)).toContain("memory__search");

    const t1 = performance.now();
    const tool = await j(
      await h.request("/v1/voice/tool", {
        method: "POST",
        token: owner.token,
        json: {
          bot_id: botId,
          conversation_id: convId,
          call_id: "c1",
          name: "memory__search",
          arguments: { query: "plants" },
        },
      }),
    );
    const toolMs = performance.now() - t1;
    console.log(
      `voice session minted in ${mintMs.toFixed(0)} ms; forwarded tool call answered in ${toolMs.toFixed(0)} ms`,
    );
    expect(tool.status).toBe("completed");
    expect(toolMs).toBeLessThan(1000);

    // Under "always ask", the same tool waits for approval instead of running.
    await h.handle.db.execute(
      sql`update public.bots set autonomy = 'ask_always' where id = ${botId}::uuid`,
    );
    const gated = await j(
      await h.request("/v1/voice/tool", {
        method: "POST",
        token: owner.token,
        json: {
          bot_id: botId,
          conversation_id: convId,
          call_id: "c2",
          name: "notify__user",
          arguments: { title: "Hi", message: "Water the fern" },
        },
      }),
    );
    expect(gated.status).toBe("waiting_approval");
    expect(gated.approval_id).toBeTruthy();
  }, 60_000);

  it("saves the call transcript and its duration", async () => {
    const res = await j(
      await h.request("/v1/voice/transcript", {
        method: "POST",
        token: owner.token,
        json: {
          conversation_id: convId,
          seconds: 90,
          turns: [
            { role: "user", text: "How often should I water the fern?" },
            { role: "assistant", text: "Once a week, on Fridays." },
          ],
        },
      }),
    );
    expect(res.saved).toBe(2);
    const msgs = await h.handle.db.execute<{ content: unknown }>(
      sql`select content from public.messages where conversation_id = ${convId}::uuid order by created_at`,
    );
    expect(JSON.stringify(msgs)).toContain("Once a week, on Fridays.");
    const [u] = await h.handle.db.execute<{ q: string }>(
      sql`select sum(quantity)::text as q from public.usage_ledger where kind = 'voice_seconds'`,
    );
    expect(Number(u?.q)).toBe(90);
  }, 60_000);
});
