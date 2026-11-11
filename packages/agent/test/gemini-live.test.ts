import { describe, expect, it } from "vitest";
import {
  addGeminiUsage,
  base64ToPcm16,
  createGeminiLiveSession,
  emptyGeminiUsage,
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
});
