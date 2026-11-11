/**
 * Voice (Phase 6, D-065): speech-to-text, text-to-speech and realtime call sessions, each with the
 * org's own provider key. Request shapes follow each provider's public REST API; base URLs can be
 * overridden (tests use local mocks).
 */

export type SttProviderId = "openai" | "deepgram";
export type TtsProviderId = "google" | "openai" | "elevenlabs" | "cartesia" | "fish_audio";
/** Read-aloud model (D-187). Cheaper than gpt-4o-mini-tts and ElevenLabs Flash. */
export const GEMINI_TTS_MODEL = "gemini-3.8-flash-lite-tts";

export const DEFAULT_REALTIME_MODEL = "gpt-realtime-2.1";
/** Live calls: Gemini Live when the workspace has a Google AI key, else OpenAI Realtime. */
export type RealtimeProviderId = "gemini" | "openai";
/** The model credential each live-call provider uses, in the order they're tried. */
export const REALTIME_CREDENTIALS: Array<{ provider: RealtimeProviderId; credential: string }> = [
  { provider: "gemini", credential: "google" },
  { provider: "openai", credential: "openai" },
];
export const DEFAULT_GEMINI_LIVE_MODEL = "gemini-3.8-live";
/** Gemini's prebuilt voices (the Live API uses the same ones as its text-to-speech). */
export const GEMINI_VOICES = [
  "Zephyr",
  "Puck",
  "Charon",
  "Kore",
  "Fenrir",
  "Leda",
  "Orus",
  "Aoede",
  "Callirrhoe",
  "Autonoe",
  "Enceladus",
  "Iapetus",
  "Umbriel",
  "Algieba",
  "Despina",
  "Erinome",
  "Algenib",
  "Rasalgethi",
  "Laomedeia",
  "Achernar",
  "Alnilam",
  "Schedar",
  "Gacrux",
  "Pulcherrima",
  "Achird",
  "Zubenelgenubi",
  "Vindemiatrix",
  "Sadachbia",
  "Sadaltager",
  "Sulafat",
];
export const DEFAULT_GEMINI_VOICE = "Kore";

/**
 * The tools a bot gets on a live call. Every tool's definition is sent with the session (and may
 * count as input on every turn), so calls carry a small, conversational set; anything bigger goes
 * to a normal chat run through `start_task`.
 */
export const VOICE_CALL_TOOLS = new Set([
  "memory.search",
  "memory.write",
  "knowledge.search",
  "web.search",
  "notify.user",
  "routines.list",
  "routines.create",
  "routines.update",
  "routines.delete",
  "watchers.create",
  "watchers.list",
  "tasks.list",
  "tasks.create",
  "usage.report",
  "device.read",
]);

/** The call-only tool that hands a bigger job to a normal run in the call's chat. */
export const START_TASK_TOOL: RealtimeTool = {
  name: "start_task",
  description:
    "Hand a bigger job to yourself in the chat: anything that needs your computer, files, the browser, connected apps or several steps. Describe the task fully. It runs in the background and the result appears in this conversation; tell the user that.",
  parameters: {
    type: "object",
    properties: {
      task: { type: "string", description: "The complete task, as the user would write it" },
    },
    required: ["task"],
  },
};

/** Gemini Live's list prices (USD per 1M tokens); the same for every current Live model. */
export const GEMINI_LIVE_PRICES = {
  inputAudio: 3,
  inputText: 0.75,
  inputImage: 1,
  outputAudio: 12,
  outputText: 4.5,
};

/** Token counts from a Gemini Live call's `usageMetadata`, by direction and modality. */
export interface GeminiLiveUsage {
  input_audio_tokens: number;
  input_text_tokens: number;
  output_audio_tokens: number;
  output_text_tokens: number;
}

/** What a call cost from its token counts (thinking and tool-use prompts count as text). */
export function geminiLiveCost(u: GeminiLiveUsage) {
  const p = GEMINI_LIVE_PRICES;
  return (
    (u.input_audio_tokens * p.inputAudio +
      u.input_text_tokens * p.inputText +
      u.output_audio_tokens * p.outputAudio +
      u.output_text_tokens * p.outputText) /
    1_000_000
  );
}

/** Adds one `usageMetadata` message to running totals (each one covers the latest response). */
export function addGeminiUsage(total: GeminiLiveUsage, m: unknown): GeminiLiveUsage {
  if (!m || typeof m !== "object") return total;
  const u = m as {
    promptTokensDetails?: Array<{ modality?: string; tokenCount?: number }>;
    responseTokensDetails?: Array<{ modality?: string; tokenCount?: number }>;
    promptTokenCount?: number;
    responseTokenCount?: number;
    toolUsePromptTokenCount?: number;
    thoughtsTokenCount?: number;
  };
  const sum = (details: typeof u.promptTokensDetails, audio: boolean) =>
    (details ?? []).reduce(
      (n, d) => n + ((d.modality === "AUDIO") === audio ? (d.tokenCount ?? 0) : 0),
      0,
    );
  const inAudio = sum(u.promptTokensDetails, true);
  const inOther = u.promptTokensDetails
    ? sum(u.promptTokensDetails, false)
    : Math.max(0, (u.promptTokenCount ?? 0) - inAudio);
  const outAudio = sum(u.responseTokensDetails, true);
  const outOther = u.responseTokensDetails
    ? sum(u.responseTokensDetails, false)
    : Math.max(0, (u.responseTokenCount ?? 0) - outAudio);
  return {
    input_audio_tokens: total.input_audio_tokens + inAudio,
    input_text_tokens: total.input_text_tokens + inOther + (u.toolUsePromptTokenCount ?? 0),
    output_audio_tokens: total.output_audio_tokens + outAudio,
    output_text_tokens: total.output_text_tokens + outOther + (u.thoughtsTokenCount ?? 0),
  };
}

export const emptyGeminiUsage = (): GeminiLiveUsage => ({
  input_audio_tokens: 0,
  input_text_tokens: 0,
  output_audio_tokens: 0,
  output_text_tokens: 0,
});
// Dictation stays on OpenAI. Gemini 3.5 Transcribe's own page puts a file at about $0.005 a
// minute once the transcript text is included; gpt-4o-mini-transcribe is $0.003 (D-187).
export const STT_PROVIDERS: SttProviderId[] = ["openai", "deepgram"];
// Gemini Flash-Lite TTS first: about $0.009 a minute of speech through 2026, against about
// $0.018 for gpt-4o-mini-tts and $0.032 for ElevenLabs Flash (D-187).
export const TTS_PROVIDERS: TtsProviderId[] = ["google", "openai", "elevenlabs", "cartesia", "fish_audio"];

export const DEFAULT_VOICES: Record<TtsProviderId, string> = {
  google: DEFAULT_GEMINI_VOICE,
  openai: "alloy",
  elevenlabs: "21m00Tcm4TlvDq8EAChM", // "Rachel", a stock ElevenLabs voice
  cartesia: "a0e99841-438c-4a64-b679-ae501e7d6091",
  fish_audio: "",
};

export interface VoiceBases {
  openai?: string;
  /** Gemini API (https://generativelanguage.googleapis.com); its WebSocket host is derived from it. */
  gemini?: string;
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
  opts: { bases?: VoiceBases; fetch?: typeof fetch; language?: string; model?: string } = {},
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
  form.set("model", opts.model ?? "gpt-4o-mini-transcribe");
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

/** Speaks text with the user's key. Gemini returns WAV; the others return MP3. */
export async function synthesize(
  provider: TtsProviderId,
  apiKey: string,
  text: string,
  voice: string | undefined,
  opts: { bases?: VoiceBases; fetch?: typeof fetch; model?: string } = {},
): Promise<{ audio: Uint8Array; mime: string }> {
  const f = opts.fetch ?? fetch;
  const v = voice || DEFAULT_VOICES[provider];
  if (provider === "google") return synthesizeGemini(apiKey, text, v, opts);
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
    /** A phone call (D-141): 8 kHz G.711 μ-law audio in and out, as telephony carries. */
    phone?: boolean;
    /** OpenAI transcription model for the caller's speech. */
    transcriptionModel?: string;
  },
) {
  const f = opts.fetch ?? fetch;
  const base = opts.bases?.openai ?? "https://api.openai.com";
  const pcmu = opts.phone ? { format: { type: "audio/pcmu" } } : {};
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
            // Barge-in (D-144): the person talking over the bot interrupts its reply.
            input: {
              transcription: { model: opts.transcriptionModel ?? "gpt-4o-mini-transcribe" },
              turn_detection: {
                type: "server_vad",
                interrupt_response: true,
                create_response: true,
              },
              ...pcmu,
            },
            output: { voice: opts.voice ?? "marin", ...pcmu },
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

/**
 * Gemini's function declarations take an OpenAPI subset of JSON Schema: no `$schema`,
 * `additionalProperties`, `const` or type unions. This keeps what it understands.
 */
export function geminiSchema(schema: unknown): Record<string, unknown> {
  const walk = (node: unknown): unknown => {
    if (Array.isArray(node)) return node.map(walk);
    if (!node || typeof node !== "object") return node;
    const n = node as Record<string, unknown>;
    const out: Record<string, unknown> = {};
    for (const [k, v] of Object.entries(n)) {
      if (k === "properties" && v && typeof v === "object") {
        out.properties = Object.fromEntries(
          Object.entries(v as Record<string, unknown>).map(([pk, pv]) => [pk, walk(pv)]),
        );
      } else if (k === "items" || k === "anyOf") {
        out[k] = walk(v);
      } else if (k === "const") {
        out.enum = [v];
      } else if (k === "type" && Array.isArray(v)) {
        const types = v.filter((t) => t !== "null");
        out.type = types[0] ?? "string";
        if (types.length !== v.length) out.nullable = true;
      } else if (
        [
          "type",
          "description",
          "enum",
          "format",
          "required",
          "nullable",
          "minimum",
          "maximum",
          "minItems",
          "maxItems",
          "minLength",
          "maxLength",
          "pattern",
          "title",
        ].includes(k)
      ) {
        out[k] = v;
      }
    }
    if (Array.isArray(out.enum)) out.enum = out.enum.map(String);
    if (out.enum && !out.type) out.type = "string";
    return out;
  };
  const s = walk(schema) as Record<string, unknown>;
  if (!s.type) s.type = "object";
  if (s.type === "object" && !s.properties) s.properties = {};
  return s;
}

/** The setup fields a Gemini Live token locks, so a client can't change the bot's instructions or tools. */
export const GEMINI_LOCKED_FIELDS = [
  "model",
  "generationConfig",
  "systemInstruction",
  "tools",
  "realtimeInputConfig",
  "inputAudioTranscription",
  "outputAudioTranscription",
  "contextWindowCompression",
];

/**
 * Mints a single-use Gemini Live token whose setup (model, voice, instructions, tools) is locked
 * on the server. The app connects to `connectUrl` over a WebSocket and sends `setup` (adding
 * `sessionResumption` to reconnect); phone calls do the same from the API.
 */
export async function createGeminiLiveSession(
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
  const base = (opts.bases?.gemini ?? "https://generativelanguage.googleapis.com").replace(
    /\/$/,
    "",
  );
  const model = opts.model ?? DEFAULT_GEMINI_LIVE_MODEL;
  const voice =
    opts.voice && GEMINI_VOICES.includes(opts.voice) ? opts.voice : DEFAULT_GEMINI_VOICE;
  const setup: Record<string, unknown> = {
    model: `models/${model}`,
    generationConfig: {
      responseModalities: ["AUDIO"],
      speechConfig: { voiceConfig: { prebuiltVoiceConfig: { voiceName: voice } } },
    },
    systemInstruction: { parts: [{ text: opts.instructions }] },
    ...(opts.tools.length
      ? {
          tools: [
            {
              functionDeclarations: opts.tools.map((t) => ({
                name: t.name,
                description: t.description,
                parameters: geminiSchema(t.parameters),
              })),
            },
          ],
        }
      : {}),
    // Barge-in: the person speaking interrupts the reply (the default); a short pause ends a turn.
    realtimeInputConfig: {
      automaticActivityDetection: { silenceDurationMs: 600, prefixPaddingMs: 200 },
      activityHandling: "START_OF_ACTIVITY_INTERRUPTS",
      // Turns hold speech only, not the silence between it.
      turnCoverage: "TURN_INCLUDES_ONLY_ACTIVITY",
    },
    inputAudioTranscription: {},
    outputAudioTranscription: {},
    // Keep the context small: past 32k tokens the oldest turns are dropped down to 16k. This caps
    // what each turn costs and lets calls run past Gemini's 15-minute session limit. (Gemini's
    // default only starts at about 105k tokens.)
    contextWindowCompression: { triggerTokens: 32_000, slidingWindow: { targetTokens: 16_000 } },
  };
  const now = Date.now();
  const expiresAt = new Date(now + 30 * 60_000).toISOString();
  const res = await ok(
    await f(`${base}/v1beta/auth_tokens`, {
      method: "POST",
      headers: { "x-goog-api-key": apiKey, "content-type": "application/json" },
      body: JSON.stringify({
        uses: 1,
        expireTime: expiresAt,
        newSessionExpireTime: new Date(now + 2 * 60_000).toISOString(),
        bidiGenerateContentSetup: setup,
        fieldMask: GEMINI_LOCKED_FIELDS.join(","),
      }),
    }),
    "Gemini",
  );
  const j = (await res.json()) as { name: string; expireTime?: string };
  const ws = base.replace(/^http/, "ws");
  return {
    provider: "gemini" as const,
    model,
    clientSecret: j.name,
    expiresAt: j.expireTime ?? expiresAt,
    connectUrl: `${ws}/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContentConstrained`,
    setup,
  };
}

/** Rough list prices for the ledger (USD); real bills come from the provider. */
export const VOICE_PRICES = {
  sttPerMinute: 0.003,
  ttsPerThousandChars: 0.015,
  /** Gemini 3.8 Flash-Lite TTS, about 800 characters of speech a minute (D-187). */
  geminiTtsPerThousandChars: 0.011,
  realtimePerMinute: 0.06,
  geminiLivePerMinute: 0.02,
};

/** What one read-aloud cost. Gemini bills the audio, and that rate doubles on 2027-01-01. */
export function ttsCostUsd(provider: TtsProviderId, chars: number, audio?: Uint8Array, now = new Date()): number {
  if (provider !== "google") return (chars / 1000) * VOICE_PRICES.ttsPerThousandChars;
  const perMillion = now >= new Date("2027-01-01T00:00:00Z") ? 12 : 6;
  const seconds = wavDurationS(audio);
  if (seconds != null) return seconds * 25 * (perMillion / 1_000_000);
  return (chars / 1000) * (perMillion === 12 ? 0.0225 : VOICE_PRICES.geminiTtsPerThousandChars);
}

/** Seconds of 16-bit mono audio in a WAV, when the header is one we wrote or Gemini returned. */
export function wavDurationS(audio: Uint8Array | undefined): number | null {
  if (!audio || audio.length < 44 || audio[0] !== 0x52 || audio[1] !== 0x49) return null;
  const view = new DataView(audio.buffer, audio.byteOffset, audio.byteLength);
  const rate = view.getUint32(24, true);
  const bytes = view.getUint32(40, true);
  if (!rate || !bytes) return null;
  return bytes / 2 / rate;
}

/** Gemini returns a WAV. Raw 24 kHz PCM gets a header so players can open it. */
export function asWav(audio: Uint8Array, sampleRate = 24_000): Uint8Array {
  if (audio.length >= 12 && audio[0] === 0x52 && audio[1] === 0x49 && audio[2] === 0x46 && audio[3] === 0x46)
    return audio;
  const header = new ArrayBuffer(44);
  const v = new DataView(header);
  const str = (at: number, s: string) => {
    for (let i = 0; i < s.length; i++) v.setUint8(at + i, s.charCodeAt(i));
  };
  str(0, "RIFF");
  v.setUint32(4, 36 + audio.length, true);
  str(8, "WAVE");
  str(12, "fmt ");
  v.setUint32(16, 16, true);
  v.setUint16(20, 1, true);
  v.setUint16(22, 1, true);
  v.setUint32(24, sampleRate, true);
  v.setUint32(28, sampleRate * 2, true);
  v.setUint16(32, 2, true);
  v.setUint16(34, 16, true);
  str(36, "data");
  v.setUint32(40, audio.length, true);
  const out = new Uint8Array(44 + audio.length);
  out.set(new Uint8Array(header), 0);
  out.set(audio, 44);
  return out;
}

async function synthesizeGemini(
  apiKey: string,
  text: string,
  voice: string,
  opts: { bases?: VoiceBases; fetch?: typeof fetch; model?: string },
): Promise<{ audio: Uint8Array; mime: string }> {
  const f = opts.fetch ?? fetch;
  const base = (opts.bases?.gemini ?? "https://generativelanguage.googleapis.com").replace(/\/$/, "");
  const voiceName = GEMINI_VOICES.includes(voice) || voice.startsWith("voice_") ? voice : DEFAULT_GEMINI_VOICE;
  const model = opts.model ?? GEMINI_TTS_MODEL;
  const res = await ok(
    await f(`${base}/v1beta/models/${model}:generateContent`, {
      method: "POST",
      headers: { "x-goog-api-key": apiKey, "content-type": "application/json" },
      body: JSON.stringify({
        contents: [{ role: "user", parts: [{ text }] }],
        generationConfig: {
          responseModalities: ["AUDIO"],
          speechConfig: { voiceConfig: { voice: voiceName } },
        },
      }),
    }),
    "Gemini",
  );
  const body = (await res.json()) as {
    candidates?: Array<{ content?: { parts?: Array<{ inlineData?: { data?: string } }> } }>;
  };
  const b64 = body.candidates?.[0]?.content?.parts?.find((p) => p.inlineData?.data)?.inlineData?.data;
  if (!b64) throw new VoiceError("Gemini returned no audio");
  return { audio: asWav(Uint8Array.from(Buffer.from(b64, "base64"))), mime: "audio/wav" };
}

/** Telephony audio (8 kHz G.711 μ-law) ⇄ the 16-bit PCM Gemini Live speaks. */
export function mulawToPcm16(mulaw: Uint8Array): Int16Array {
  const out = new Int16Array(mulaw.length);
  for (let i = 0; i < mulaw.length; i++) {
    const u = ~(mulaw[i] as number) & 0xff;
    const sign = u & 0x80;
    const exponent = (u >> 4) & 0x07;
    const mantissa = u & 0x0f;
    const sample = (((mantissa << 3) + 0x84) << exponent) - 0x84;
    out[i] = sign ? -sample : sample;
  }
  return out;
}

export function pcm16ToMulaw(pcm: Int16Array): Uint8Array {
  const out = new Uint8Array(pcm.length);
  for (let i = 0; i < pcm.length; i++) {
    let s = pcm[i] as number;
    const sign = s < 0 ? 0x80 : 0;
    if (s < 0) s = -s;
    s = Math.min(s, 32635) + 0x84;
    let exponent = 7;
    for (let mask = 0x4000; (s & mask) === 0 && exponent > 0; mask >>= 1) exponent--;
    const mantissa = (s >> (exponent + 3)) & 0x0f;
    out[i] = ~(sign | (exponent << 4) | mantissa) & 0xff;
  }
  return out;
}

/** Linear resampling between PCM rates (8 ⇄ 16 ⇄ 24 kHz on phone calls). */
export function resamplePcm16(pcm: Int16Array, from: number, to: number): Int16Array {
  if (from === to || pcm.length === 0) return pcm;
  if (from > to && from % to === 0) {
    // Whole-number downsampling (24 → 8 kHz): average each group, a simple low-pass filter.
    const n = from / to;
    const out = new Int16Array(Math.floor(pcm.length / n));
    for (let i = 0; i < out.length; i++) {
      let sum = 0;
      for (let k = 0; k < n; k++) sum += pcm[i * n + k] as number;
      out[i] = Math.round(sum / n);
    }
    return out;
  }
  const length = Math.max(1, Math.round((pcm.length * to) / from));
  const out = new Int16Array(length);
  const step = from / to;
  for (let i = 0; i < length; i++) {
    const pos = i * step;
    const j = Math.floor(pos);
    const a = pcm[Math.min(j, pcm.length - 1)] as number;
    const b = pcm[Math.min(j + 1, pcm.length - 1)] as number;
    out[i] = Math.round(a + (b - a) * (pos - j));
  }
  return out;
}

export const pcm16ToBase64 = (pcm: Int16Array) =>
  Buffer.from(pcm.buffer, pcm.byteOffset, pcm.byteLength).toString("base64");

export function base64ToPcm16(b64: string): Int16Array {
  const buf = Buffer.from(b64, "base64");
  const copy = new Uint8Array(buf.length - (buf.length % 2));
  copy.set(buf.subarray(0, copy.length));
  return new Int16Array(copy.buffer);
}
