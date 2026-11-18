/** Read-aloud: Gemini TTS on OpenRouter, and its price (D-187, D-261). */
import { describe, expect, it } from "vitest";
import { asWav, synthesize, transcribe, ttsCostUsd, wavDurationS } from "../src/voice.ts";

describe("read aloud", () => {
  it("asks OpenRouter for Gemini TTS as PCM, wraps it in a WAV, and ignores a foreign voice id", async () => {
    let sent: Record<string, unknown> = {};
    let auth = "";
    let url = "";
    const pcm = new Uint8Array(4800);
    const fake = (async (u: string, init: RequestInit) => {
      url = u;
      auth = new Headers(init.headers).get("authorization") ?? "";
      sent = JSON.parse(String(init.body));
      return new Response(pcm, { headers: { "content-type": "audio/pcm;rate=24000;channels=1" } });
    }) as unknown as typeof fetch;
    const speech = await synthesize(
      "openrouter",
      "sk-or",
      "Water the fern.",
      "21m00Tcm4TlvDq8EAChM",
      { bases: { openrouter: "http://or.test/api/v1" }, fetch: fake },
    );
    expect(url).toBe("http://or.test/api/v1/audio/speech");
    expect(auth).toBe("Bearer sk-or");
    expect(sent).toEqual({
      model: "google/gemini-3.8-flash-lite-tts",
      input: "Water the fern.",
      voice: "Kore",
      response_format: "pcm",
    });
    expect(speech.mime).toBe("audio/wav");
    expect(speech.audio[0]).toBe(0x52);
    // 4800 bytes of 16-bit audio at 24 kHz is a tenth of a second.
    expect(wavDurationS(speech.audio)).toBeCloseTo(0.1, 6);
    expect(ttsCostUsd("openrouter", 16, speech.audio, new Date("2026-11-11"))).toBeCloseTo(
      0.1 * 25 * (6 / 1_000_000),
      8,
    );
    expect(ttsCostUsd("openrouter", 16, speech.audio, new Date("2027-01-01"))).toBeCloseTo(
      0.1 * 25 * (12 / 1_000_000),
      8,
    );
  });

  it("dictation goes to OpenRouter's transcription endpoint and keeps its reported cost", async () => {
    let url = "";
    let form: FormData | null = null;
    const fake = (async (u: string, init: RequestInit) => {
      url = u;
      form = init.body as FormData;
      return Response.json({
        text: " Water the fern on Fridays.",
        usage: { seconds: 2.52, cost: 0.0000083916 },
      });
    }) as unknown as typeof fetch;
    const r = await transcribe("openrouter", "sk-or", new Uint8Array([1, 2]), "audio/wav", {
      bases: { openrouter: "http://or.test/api/v1/" },
      fetch: fake,
    });
    expect(url).toBe("http://or.test/api/v1/audio/transcriptions");
    expect((form as unknown as FormData).get("model")).toBe("openai/whisper-large-v3-turbo");
    expect(r).toEqual({
      text: " Water the fern on Fridays.",
      seconds: 2.52,
      costUsd: 0.0000083916,
    });
  });

  it("keeps a WAV Gemini already wrapped", () => {
    const wav = asWav(new Uint8Array(4));
    expect(asWav(wav)).toBe(wav);
  });
});
