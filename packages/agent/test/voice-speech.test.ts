/** Read-aloud on Gemini, and its price (D-187). */
import { describe, expect, it } from "vitest";
import { asWav, synthesize, ttsCostUsd, wavDurationS } from "../src/voice.ts";

describe("read aloud", () => {
  it("asks Gemini Flash-Lite for a WAV and ignores a voice id from another provider", async () => {
    let sent: Record<string, unknown> = {};
    let auth = "";
    const pcm = new Uint8Array(4800);
    const fake = (async (_url: string, init: RequestInit) => {
      auth = new Headers(init.headers).get("x-goog-api-key") ?? "";
      sent = JSON.parse(String(init.body));
      return Response.json({
        candidates: [{ content: { parts: [{ inlineData: { data: Buffer.from(pcm).toString("base64") } }] } }],
      });
    }) as unknown as typeof fetch;
    const speech = await synthesize("google", "gem-key", "Water the fern.", "21m00Tcm4TlvDq8EAChM", {
      bases: { gemini: "http://gemini.test" },
      fetch: fake,
    });
    expect(auth).toBe("gem-key");
    expect(sent).toMatchObject({
      contents: [{ parts: [{ text: "Water the fern." }] }],
      generationConfig: {
        responseModalities: ["AUDIO"],
        speechConfig: { voiceConfig: { voice: "Kore" } },
      },
    });
    expect(speech.mime).toBe("audio/wav");
    expect(speech.audio[0]).toBe(0x52);
    // 4800 bytes of 16-bit audio at 24 kHz is a tenth of a second.
    expect(wavDurationS(speech.audio)).toBeCloseTo(0.1, 6);
    expect(ttsCostUsd("google", 16, speech.audio, new Date("2026-11-11"))).toBeCloseTo(0.1 * 25 * (6 / 1_000_000), 8);
    expect(ttsCostUsd("google", 16, speech.audio, new Date("2027-01-01"))).toBeCloseTo(0.1 * 25 * (12 / 1_000_000), 8);
  });

  it("keeps a WAV Gemini already wrapped, and prices other providers per character", () => {
    const wav = asWav(new Uint8Array(4));
    expect(asWav(wav)).toBe(wav);
    expect(ttsCostUsd("openai", 2000)).toBeCloseTo(0.03, 6);
  });
});
