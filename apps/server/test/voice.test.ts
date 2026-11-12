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
      if (path === "/v1/audio/transcriptions" && body.includes("BROKEN-CLIP")) {
        res.writeHead(400, { "content-type": "application/json" });
        return res.end(JSON.stringify({ error: { message: "Invalid file format." } }));
      }
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
      if (path.endsWith(":generateContent")) {
        return json({
          candidates: [
            {
              content: {
                parts: [{ inlineData: { data: Buffer.alloc(48).toString("base64") } }],
              },
            },
          ],
        });
      }
      if (path === "/v1beta/auth_tokens") return json({ name: "auth_tokens/gemini-test-token" });
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
        providerBases: {
          openai: mock.url,
          gemini: mock.url,
          deepgram: mock.url,
          elevenlabs: mock.url,
        },
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

  it("a workspace with no live-call key is told which key it needs", async () => {
    const other = await h.user("voice-nokey@example.com");
    const org = (
      await j(
        await h.request("/v1/orgs", {
          method: "POST",
          token: other.token,
          json: { name: "No keys" },
        }),
      )
    ).id;
    const llm = await j(
      await h.request("/v1/credentials", {
        method: "POST",
        token: other.token,
        json: { org_id: org, provider: "openrouter", label: "llm", api_key: "sk-other" },
      }),
    );
    const bot = await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: other.token,
        json: {
          org_id: org,
          name: "Quiet",
          model_policy: { primary: { credential_id: llm.id, model: "fixture-main" } },
        },
      }),
    );
    const res = await h.request("/v1/voice/session", {
      method: "POST",
      token: other.token,
      json: { bot_id: bot.id },
    });
    expect(res.status).toBe(409);
    expect((await j(res)).code).toBe("voice_key_missing");
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

  it("a clip the provider rejects comes back as transcription_failed, not a 500", async () => {
    const res = await h.request(`/v1/voice/transcribe?bot_id=${botId}`, {
      method: "POST",
      token: owner.token,
      headers: { "content-type": "audio/mp4" },
      body: new TextEncoder().encode("BROKEN-CLIP"),
    });
    expect(res.status).toBe(409);
    expect(await j(res)).toMatchObject({ code: "transcription_failed" });
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
    // No Google key yet, so automatic read-aloud uses the OpenAI key ahead of ElevenLabs.
    expect(mock.calls.filter((c) => c.path === "/v1/audio/speech")).toHaveLength(1);
    expect(mock.calls.find((c) => c.path === "/v1/audio/speech")?.headers.authorization).toBe(
      "Bearer sk-voice-openai-key",
    );
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

    // Under "always ask", a tool with side effects outside Casama waits for approval instead of running.
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
          name: "http__request",
          arguments: { url: "https://example.com/water", method: "POST" },
        },
      }),
    );
    expect(gated.status).toBe("waiting_approval");
    expect(gated.approval_id).toBeTruthy();
    // A message to the person themselves only touches Casama, so it never asks (D-155).
    const own = await j(
      await h.request("/v1/voice/tool", {
        method: "POST",
        token: owner.token,
        json: {
          bot_id: botId,
          conversation_id: convId,
          call_id: "c3",
          name: "notify__user",
          arguments: { title: "Hi", message: "Water the fern" },
        },
      }),
    );
    expect(own.status).toBe("completed");
  }, 60_000);

  it("with a Google AI key, live calls use Gemini Live with a locked, single-use token", async () => {
    expect((await addKey("google", "gemini-voice-key")).status).toBe(201);
    const res = await h.request("/v1/voice/session", {
      method: "POST",
      token: owner.token,
      json: { bot_id: botId, conversation_id: convId },
    });
    expect(res.status).toBe(200);
    const s = await j(res);
    expect(s).toMatchObject({
      provider: "gemini",
      model: "gemini-3.8-live",
      client_secret: "auth_tokens/gemini-test-token",
      conversation_id: convId,
    });
    expect(s.connect_url).toMatch(
      /^ws:\/\/127\.0\.0\.1:\d+\/ws\/google\.ai\.generativelanguage\.v1beta\.GenerativeService\.BidiGenerateContentConstrained$/,
    );
    const mint = mock.calls.findLast((c) => c.path === "/v1beta/auth_tokens");
    expect(mint?.headers["x-goog-api-key"]).toBe("gemini-voice-key");
    const body = JSON.parse(Buffer.from(mint?.body ?? "{}", "latin1").toString("utf8"));
    // Single use, and the bot's instructions, tools and voice can't be changed by the client.
    expect(body.uses).toBe(1);
    expect(body.fieldMask.split(",")).toEqual(
      expect.arrayContaining(["model", "systemInstruction", "tools", "generationConfig"]),
    );
    const setup = body.bidiGenerateContentSetup;
    expect(setup.model).toBe("models/gemini-3.8-live");
    expect(setup.systemInstruction.parts[0].text).toContain("You love plants.");
    const fns = setup.tools[0].functionDeclarations as Array<{
      name: string;
      parameters: Record<string, unknown>;
    }>;
    expect(fns.map((f) => f.name)).toContain("memory__search");
    // Function schemas are in Gemini's OpenAPI subset (no JSON Schema-only keywords).
    expect(JSON.stringify(fns)).not.toMatch(/"additionalProperties"|"\$schema"/);
    expect(setup.generationConfig.speechConfig.voiceConfig.prebuiltVoiceConfig.voiceName).toBe(
      "Kore",
    );
    // The app sends the same setup first.
    expect(s.setup).toEqual(setup);
    // Cost controls: a small conversational tool set plus start_task (no shell, browser or
    // computer tools), a 32k-token context cap, and turns without the silence between speech.
    const names = fns.map((f) => f.name);
    expect(names).toContain("start_task");
    expect(names.some((n) => /^(shell|browser|files|desktop)__/.test(n))).toBe(false);
    expect(names.length).toBeLessThanOrEqual(20);
    expect(setup.contextWindowCompression).toEqual({
      triggerTokens: 32000,
      slidingWindow: { targetTokens: 16000 },
    });
    expect(setup.realtimeInputConfig.turnCoverage).toBe("TURN_INCLUDES_ONLY_ACTIVITY");

    const [spoken] = await h.handle.db.execute<{ id: string }>(sql`
      insert into public.messages (org_id, conversation_id, role, content)
      values (${orgId}::uuid, ${convId}::uuid, 'assistant', '[{"type":"text","text":"The fern is watered."}]'::jsonb)
      returning id`);
    const audio = await h.request(`/v1/messages/${spoken?.id}/speech`, { token: owner.token });
    expect(audio.status).toBe(200);
    expect(audio.headers.get("content-type")).toBe("audio/wav");
    const tts = mock.calls.findLast((c) => c.path.endsWith(":generateContent"));
    expect(tts?.headers["x-goog-api-key"]).toBe("gemini-voice-key");
    expect(
      JSON.parse(Buffer.from(tts?.body ?? "{}", "latin1").toString("utf8")).generationConfig,
    ).toMatchObject({
      speechConfig: { voiceConfig: { voice: "Kore" } },
    });
  }, 60_000);

  it("connected-app tools a bot chose for calls join the voice set", async () => {
    const [i] = await h.handle.db.execute<{ id: string }>(sql`
      insert into public.integrations (org_id, kind, name, status, tools_cache, tools_cached_at)
      values (${orgId}::uuid, 'mcp', 'garden', 'ok', ${JSON.stringify([
        {
          name: "log_watering",
          description: "Log that a plant was watered",
          inputSchema: { type: "object", properties: { plant: { type: "string" } } },
        },
        {
          name: "delete_garden",
          description: "Delete everything",
          inputSchema: { type: "object" },
        },
      ])}::jsonb, now()) returning id`);
    await h.handle.db.execute(sql`
      insert into public.bot_integrations (org_id, bot_id, integration_id)
      values (${orgId}::uuid, ${botId}::uuid, ${i?.id}::uuid)`);
    await h.handle.db.execute(sql`
      update public.bots set voice = voice || '{"call_tools": ["mcp.garden.log_watering"]}'::jsonb
      where id = ${botId}::uuid`);
    const res = await h.request("/v1/voice/session", {
      method: "POST",
      token: owner.token,
      json: { bot_id: botId, conversation_id: convId },
    });
    expect(res.status).toBe(200);
    const mint = mock.calls.findLast((c) => c.path === "/v1beta/auth_tokens");
    const body = JSON.parse(Buffer.from(mint?.body ?? "{}", "latin1").toString("utf8"));
    const names = body.bidiGenerateContentSetup.tools[0].functionDeclarations.map(
      (f: { name: string }) => f.name,
    );
    // Only the chosen tool, not the connection's others.
    expect(names).toContain("mcp__garden__log_watering");
    expect(names).not.toContain("mcp__garden__delete_garden");
    expect(names).toContain("start_task");
  }, 60_000);

  it("start_task hands a bigger job to a normal run in the call's chat", async () => {
    const r = await j(
      await h.request("/v1/voice/tool", {
        method: "POST",
        token: owner.token,
        json: {
          bot_id: botId,
          conversation_id: convId,
          call_id: "c9",
          name: "start_task",
          arguments: { task: "Compare three fern fertilizers and save a table to ferns.md" },
        },
      }),
    );
    expect(r.status).toBe("completed");
    expect(r.output).toContain("Started in the background");
    const [run] = await h.handle.db.execute<{ trigger: string; conversation_id: string }>(
      sql`select trigger, conversation_id from public.runs where id = ${r.run_id}::uuid`,
    );
    expect(run).toMatchObject({ trigger: "chat", conversation_id: convId });
    const msgs = await h.handle.db.execute<{ content: unknown }>(
      sql`select content from public.messages where run_id = ${r.run_id}::uuid and role = 'user'`,
    );
    expect(JSON.stringify(msgs)).toContain("Compare three fern fertilizers");
    const empty = await h.request("/v1/voice/tool", {
      method: "POST",
      token: owner.token,
      json: { bot_id: botId, conversation_id: convId, call_id: "c10", name: "start_task" },
    });
    expect(empty.status).toBe(400);
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

    // A Gemini call reports its token counts, and usage records what they cost.
    await j(
      await h.request("/v1/voice/transcript", {
        method: "POST",
        token: owner.token,
        json: {
          conversation_id: convId,
          seconds: 60,
          provider: "gemini",
          turns: [{ role: "user", text: "Thanks!" }],
          usage: {
            input_audio_tokens: 1500,
            input_text_tokens: 4000,
            output_audio_tokens: 1500,
            output_text_tokens: 0,
          },
        },
      }),
    );
    const [g] = await h.handle.db.execute<{ cost: string; meta: { tokens?: unknown } }>(
      sql`select cost_usd::text as cost, meta from public.usage_ledger
          where kind = 'voice_seconds' and meta->>'provider' = 'gemini' order by created_at desc limit 1`,
    );
    // 1,500 × $3 + 4,000 × $0.75 + 1,500 × $12 per million tokens.
    expect(Number(g?.cost)).toBeCloseTo(0.0255, 6);
    expect(g?.meta.tokens).toMatchObject({ input_audio_tokens: 1500 });
  }, 60_000);
});
