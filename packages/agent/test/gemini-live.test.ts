import { describe, expect, it } from "vitest";
import {
  addGeminiUsage,
  base64ToPcm16,
  callCarriedTokens,
  createGeminiLiveSession,
  emptyGeminiUsage,
  GEMINI_LOCKED_FIELDS,
  geminiLiveCost,
  geminiSchema,
  mulawToPcm16,
  pcm16ToBase64,
  pcm16ToMulaw,
  resamplePcm16,
} from "../src/voice.ts";

describe("Gemini Live", () => {
  it("cleans tool schemas down to Gemini's OpenAPI subset", () => {
    const s = geminiSchema({
      $schema: "http://json-schema.org/draft-07/schema#",
      type: "object",
      additionalProperties: false,
      properties: {
        query: { type: "string", description: "What to look for", default: "x" },
        limit: { type: ["integer", "null"], minimum: 1 },
        kind: { const: "fact" },
        tags: { type: "array", items: { type: "string", additionalProperties: false } },
        mode: { enum: [1, 2] },
      },
      required: ["query"],
    });
    expect(s).toEqual({
      type: "object",
      properties: {
        query: { type: "string", description: "What to look for" },
        limit: { type: "integer", nullable: true, minimum: 1 },
        kind: { enum: ["fact"], type: "string" },
        tags: { type: "array", items: { type: "string" } },
        mode: { enum: ["1", "2"], type: "string" },
      },
      required: ["query"],
    });
    expect(geminiSchema({})).toEqual({ type: "object", properties: {} });
  });

  it("mints a single-use token whose setup locks the instructions and tools", async () => {
    let sent: {
      url: string;
      headers: Record<string, string>;
      body: Record<string, unknown>;
    } | null = null;
    const fakeFetch = (async (url: string, init: RequestInit) => {
      sent = {
        url,
        headers: init.headers as Record<string, string>,
        body: JSON.parse(String(init.body)),
      };
      return new Response(JSON.stringify({ name: "auth_tokens/t1" }), { status: 200 });
    }) as unknown as typeof fetch;
    const s = await createGeminiLiveSession("key-1", {
      instructions: "Be brief.",
      voice: "not-a-gemini-voice",
      tools: [{ name: "end_call", description: "Hang up", parameters: { type: "object" } }],
      fetch: fakeFetch,
    });
    expect(sent!.url).toBe("https://generativelanguage.googleapis.com/v1beta/auth_tokens");
    expect(sent!.headers["x-goog-api-key"]).toBe("key-1");
    expect(sent!.body.uses).toBe(1);
    expect(s.clientSecret).toBe("auth_tokens/t1");
    expect(s.connectUrl).toBe(
      "wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContentConstrained",
    );
    const setup = s.setup as {
      generationConfig: {
        speechConfig: { voiceConfig: { prebuiltVoiceConfig: { voiceName: string } } };
      };
      systemInstruction: { parts: Array<{ text: string }> };
    };
    // An OpenAI voice name falls back to Gemini's default voice.
    expect(setup.generationConfig.speechConfig.voiceConfig.prebuiltVoiceConfig.voiceName).toBe(
      "Kore",
    );
    expect(setup.systemInstruction.parts[0]?.text).toBe("Be brief.");
    expect(sent!.body.bidiGenerateContentSetup).toEqual(s.setup);
  });

  it("trims a call's conversation at 8,000 tokens down to 3,000 unless told otherwise", async () => {
    const fakeFetch = (async () =>
      new Response(JSON.stringify({ name: "auth_tokens/t1" }), {
        status: 200,
      })) as unknown as typeof fetch;
    const base = { instructions: "Be brief.", tools: [], fetch: fakeFetch };
    // Gemini counts what the call always carries toward both numbers, so it goes on top.
    const carried = callCarriedTokens("Be brief.", []);
    expect(carried).toBe(203);
    expect((await createGeminiLiveSession("k", base)).setup.contextWindowCompression).toEqual({
      triggerTokens: carried + 8000,
      slidingWindow: { targetTokens: carried + 3000 },
    });
    const set = await createGeminiLiveSession("k", {
      ...base,
      contextCompression: { triggerTokens: 12_000, targetTokens: 5_000 },
    });
    expect(set.setup.contextWindowCompression).toEqual({
      triggerTokens: carried + 12000,
      slidingWindow: { targetTokens: carried + 5000 },
    });
    // One of the two set: the other keeps its default.
    const half = await createGeminiLiveSession("k", {
      ...base,
      contextCompression: { triggerTokens: 20_000 },
    });
    expect(half.setup.contextWindowCompression).toEqual({
      triggerTokens: carried + 20000,
      slidingWindow: { targetTokens: carried + 3000 },
    });
    // Locked with the rest of the setup, so the app can't raise it.
    expect(GEMINI_LOCKED_FIELDS).toContain("contextWindowCompression");
  });

  it("leaves the same room for the conversation however much a call carries", async () => {
    const fakeFetch = (async () =>
      new Response(JSON.stringify({ name: "auth_tokens/t1" }), {
        status: 200,
      })) as unknown as typeof fetch;
    // A long persona and a bot's own connected-app tools: more than the whole 8,000 on their own.
    const instructions = "You are careful. ".repeat(600);
    const tools = Array.from({ length: 12 }, (_, i) => ({
      name: `app__tool_${i}`,
      description: "Does one thing in a connected app. ".repeat(40),
      parameters: { type: "object", properties: { id: { type: "string" } } },
    }));
    const s = await createGeminiLiveSession("k", { instructions, tools, fetch: fakeFetch });
    const setup = s.setup as {
      tools: Array<{ functionDeclarations: unknown[] }>;
      contextWindowCompression: { triggerTokens: number; slidingWindow: { targetTokens: number } };
    };
    const carried = callCarriedTokens(instructions, setup.tools[0]?.functionDeclarations ?? []);
    expect(carried).toBeGreaterThan(8000);
    const { triggerTokens, slidingWindow } = setup.contextWindowCompression;
    expect(slidingWindow.targetTokens - carried).toBe(3000);
    expect(triggerTokens - carried).toBe(8000);
    // About 3 characters a token, as measured on gemini-3.8-live, plus what Gemini adds itself.
    expect(callCarriedTokens("x".repeat(3000), [])).toBe(1200);
    expect(callCarriedTokens("", [{ name: "a" }])).toBe(
      Math.ceil('[{"name":"a"}]'.length / 3) + 200,
    );
  });

  it("converts phone audio between μ-law and PCM within G.711's error", () => {
    const pcm = Int16Array.from([0, 100, -100, 1000, -1000, 8000, -8000, 32000, -32000]);
    const back = mulawToPcm16(pcm16ToMulaw(pcm));
    for (let i = 0; i < pcm.length; i++) {
      const v = pcm[i] as number;
      expect(Math.abs((back[i] as number) - v)).toBeLessThanOrEqual(
        Math.max(8, Math.abs(v) * 0.07),
      );
    }
  });

  it("resamples between 8, 16 and 24 kHz", () => {
    const up = resamplePcm16(Int16Array.from([0, 100, 200, 300]), 8000, 16000);
    expect(up.length).toBe(8);
    expect(Array.from(up.slice(0, 4))).toEqual([0, 50, 100, 150]);
    // 24 → 8 kHz averages each group of three.
    expect(Array.from(resamplePcm16(Int16Array.from([3, 6, 9, 30, 30, 30]), 24000, 8000))).toEqual([
      6, 30,
    ]);
    const same = Int16Array.from([1, 2]);
    expect(resamplePcm16(same, 16000, 16000)).toBe(same);
  });

  it("round-trips PCM through base64", () => {
    const pcm = Int16Array.from([1, -2, 32767, -32768]);
    expect(Array.from(base64ToPcm16(pcm16ToBase64(pcm)))).toEqual(Array.from(pcm));
  });
  it("adds up usageMetadata by modality and prices it", () => {
    let u = emptyGeminiUsage();
    u = addGeminiUsage(u, {
      promptTokenCount: 5500,
      promptTokensDetails: [
        { modality: "AUDIO", tokenCount: 1500 },
        { modality: "TEXT", tokenCount: 4000 },
      ],
      responseTokensDetails: [{ modality: "AUDIO", tokenCount: 1500 }],
      toolUsePromptTokenCount: 100,
    });
    // Without per-modality details, the remainder counts as text.
    u = addGeminiUsage(u, { promptTokenCount: 200, responseTokenCount: 50 });
    u = addGeminiUsage(u, null);
    expect(u).toEqual({
      input_audio_tokens: 1500,
      input_text_tokens: 4300,
      output_audio_tokens: 1500,
      output_text_tokens: 50,
    });
    expect(geminiLiveCost(u)).toBeCloseTo((1500 * 3 + 4300 * 0.75 + 1500 * 12 + 50 * 4.5) / 1e6, 9);
  });
  it("keeps what the prompt total holds beyond its per-kind counts, without charging it", () => {
    let u = emptyGeminiUsage();
    // Two turns of a call: the total is larger than audio plus text both times.
    for (const total of [2478, 2560])
      u = addGeminiUsage(u, {
        promptTokenCount: total,
        promptTokensDetails: [
          { modality: "AUDIO", tokenCount: 300 },
          { modality: "TEXT", tokenCount: 1682 },
        ],
        responseTokensDetails: [{ modality: "AUDIO", tokenCount: 90 }],
      });
    expect(u).toEqual({
      input_audio_tokens: 600,
      input_text_tokens: 3364,
      output_audio_tokens: 180,
      output_text_tokens: 0,
      input_unattributed_tokens: 496 + 578,
    });
    // The charge is for the per-kind counts, as Google says it bills.
    expect(geminiLiveCost(u)).toBeCloseTo((600 * 3 + 3364 * 0.75 + 180 * 12) / 1e6, 9);
    // A total with no breakdown is counted whole as text, so nothing is left over.
    expect(
      addGeminiUsage(emptyGeminiUsage(), { promptTokenCount: 200 }).input_unattributed_tokens,
    ).toBeUndefined();
  });
});
