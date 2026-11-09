/**
 * Voice (Phase 6, D-065): speech-to-text, text-to-speech and realtime call sessions, each with the
 * org's own provider key. Request shapes follow each provider's public REST API; base URLs can be
 * overridden (tests use local mocks).
 */

export type SttProviderId = "openai" | "deepgram";
export type TtsProviderId = "openai" | "elevenlabs" | "cartesia" | "fish_audio";

export const DEFAULT_REALTIME_MODEL = "gpt-realtime-2.1";
export const STT_PROVIDERS: SttProviderId[] = ["openai", "deepgram"];
export const TTS_PROVIDERS: TtsProviderId[] = ["elevenlabs", "openai", "cartesia", "fish_audio"];

export const DEFAULT_VOICES: Record<TtsProviderId, string> = {
  openai: "alloy",
  elevenlabs: "21m00Tcm4TlvDq8EAChM", // "Rachel", a stock ElevenLabs voice
  cartesia: "a0e99841-438c-4a64-b679-ae501e7d6091",
  fish_audio: "",
};

export interface VoiceBases {
  openai?: string;
  deepgram?: string;
  elevenlabs?: string;
  cartesia?: string;
  fish_audio?: string;
}

export class VoiceError extends Error {
  readonly status?: number;
  constructor(message: string, status?: number) {
    super(message);
    this.status = status;
  }
}

async function ok(res: Response, provider: string) {
  if (res.ok) return res;
  throw new VoiceError(`${provider} returned ${res.status}`, res.status);
}

/** Transcribes audio with the user's key. */
export async function transcribe(
  provider: SttProviderId,
  apiKey: string,
  audio: Uint8Array,
  mime: string,
  opts: { bases?: VoiceBases; fetch?: typeof fetch; language?: string } = {},
): Promise<{ text: string; seconds: number | null }> {
  const f = opts.fetch ?? fetch;
  if (provider === "deepgram") {
    const base = opts.bases?.deepgram ?? "https://api.deepgram.com";
    const q = new URLSearchParams({ model: "nova-3", smart_format: "true" });
    if (opts.language) q.set("language", opts.language);
    const res = await ok(
      await f(`${base}/v1/listen?${q}`, {
        method: "POST",
        headers: { authorization: `Token ${apiKey}`, "content-type": mime },
        body: new Uint8Array(audio),
      }),
      "Deepgram",
    );
    const j = (await res.json()) as {
      metadata?: { duration?: number };
      results?: { channels?: Array<{ alternatives?: Array<{ transcript?: string }> }> };
    };
    return {
      text: j.results?.channels?.[0]?.alternatives?.[0]?.transcript ?? "",
      seconds: j.metadata?.duration ?? null,
    };
  }
  const base = opts.bases?.openai ?? "https://api.openai.com";
  const form = new FormData();
  const ext = mime.includes("wav")
    ? "wav"
    : mime.includes("mp4") || mime.includes("m4a")
      ? "m4a"
      : mime.includes("ogg")
        ? "ogg"
        : "webm";
  form.set("file", new Blob([new Uint8Array(audio)], { type: mime }), `audio.${ext}`);
  form.set("model", "gpt-4o-mini-transcribe");
  if (opts.language) form.set("language", opts.language);
  const res = await ok(
    await f(`${base}/v1/audio/transcriptions`, {
      method: "POST",
      headers: { authorization: `Bearer ${apiKey}` },
      body: form,
    }),
    "OpenAI",
  );
  const j = (await res.json()) as { text?: string; duration?: number };
  return { text: j.text ?? "", seconds: j.duration ?? null };
}

/** Speaks text with the user's key; returns MP3 audio. */
export async function synthesize(
  provider: TtsProviderId,
  apiKey: string,
  text: string,
  voice: string | undefined,
  opts: { bases?: VoiceBases; fetch?: typeof fetch } = {},
): Promise<{ audio: Uint8Array; mime: string }> {
  const f = opts.fetch ?? fetch;
  const v = voice || DEFAULT_VOICES[provider];
  let res: Response;
  switch (provider) {
    case "openai":
      res = await f(`${opts.bases?.openai ?? "https://api.openai.com"}/v1/audio/speech`, {
        method: "POST",
        headers: { authorization: `Bearer ${apiKey}`, "content-type": "application/json" },
        body: JSON.stringify({
          model: "gpt-4o-mini-tts",
          voice: v,
          input: text,
          response_format: "mp3",
        }),
      });
      break;
    case "elevenlabs":
      res = await f(
        `${opts.bases?.elevenlabs ?? "https://api.elevenlabs.io"}/v1/text-to-speech/${encodeURIComponent(v)}?output_format=mp3_44100_128`,
        {
          method: "POST",
          headers: { "xi-api-key": apiKey, "content-type": "application/json" },
          body: JSON.stringify({ text, model_id: "eleven_flash_v2_5" }),
        },
      );
      break;
    case "cartesia":
      res = await f(`${opts.bases?.cartesia ?? "https://api.cartesia.ai"}/tts/bytes`, {
        method: "POST",
        headers: {
          "X-API-Key": apiKey,
          "Cartesia-Version": "2025-04-16",
          "content-type": "application/json",
        },
        body: JSON.stringify({
          model_id: "sonic-2",
          transcript: text,
          voice: { mode: "id", id: v },
          output_format: { container: "mp3", sample_rate: 44100, bit_rate: 128000 },
        }),
      });
      break;
    case "fish_audio":
      res = await f(`${opts.bases?.fish_audio ?? "https://api.fish.audio"}/v1/tts`, {
        method: "POST",
        headers: { authorization: `Bearer ${apiKey}`, "content-type": "application/json" },
        body: JSON.stringify({ text, format: "mp3", ...(v ? { reference_id: v } : {}) }),
      });
      break;
  }
  await ok(res, provider);
  return { audio: new Uint8Array(await res.arrayBuffer()), mime: "audio/mpeg" };
}

export interface RealtimeTool {
  name: string;
  description: string;
  parameters: Record<string, unknown>;
}

/** Mints an ephemeral key for a realtime voice call; the app then connects to OpenAI directly. */
export async function createRealtimeSession(
  apiKey: string,
  opts: {
    model?: string;
    voice?: string;
    instructions: string;
    tools: RealtimeTool[];
    bases?: VoiceBases;
    fetch?: typeof fetch;
  },
) {
  const f = opts.fetch ?? fetch;
  const base = opts.bases?.openai ?? "https://api.openai.com";
  const model = opts.model ?? DEFAULT_REALTIME_MODEL;
  const res = await ok(
    await f(`${base}/v1/realtime/client_secrets`, {
      method: "POST",
      headers: { authorization: `Bearer ${apiKey}`, "content-type": "application/json" },
      body: JSON.stringify({
        expires_after: { anchor: "created_at", seconds: 600 },
        session: {
          type: "realtime",
          model,
          instructions: opts.instructions,
          audio: {
            input: { transcription: { model: "gpt-4o-mini-transcribe" } },
            output: { voice: opts.voice ?? "marin" },
          },
          tools: opts.tools.map((t) => ({ type: "function", ...t })),
          tool_choice: "auto",
        },
      }),
    }),
    "OpenAI",
  );
  const j = (await res.json()) as { value: string; expires_at: number };
  return {
    provider: "openai" as const,
    model,
    clientSecret: j.value,
    expiresAt: new Date(j.expires_at * 1000).toISOString(),
    connectUrl: `${base}/v1/realtime/calls`,
  };
}

/** Rough list prices for the ledger (USD); real bills come from the provider. */
export const VOICE_PRICES = {
  sttPerMinute: 0.003,
  ttsPerThousandChars: 0.015,
  realtimePerMinute: 0.06,
};
