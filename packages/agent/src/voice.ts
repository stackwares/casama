/**
 * Voice (Phase 6, D-065): speech-to-text, text-to-speech and live call sessions. Dictation and
 * read-aloud go through OpenRouter; live calls are Gemini Live on a Google AI key (D-260, D-261).
 * Request shapes follow each provider's public REST API; base URLs can be overridden (tests use
 * local mocks).
 */

import { callLifeSeconds, costTables } from "@casama/domain";
import { ToolRegistry } from "./tools/registry.ts";

/** Dictation and read-aloud run on OpenRouter only (D-261). */
export type SttProviderId = "openrouter";
export type TtsProviderId = "openrouter";
/** Read-aloud model on OpenRouter (D-187, D-261): Gemini 3.8 Flash-Lite TTS. */
export const OPENROUTER_TTS_MODEL = "google/gemini-3.8-flash-lite-tts";

/** Live calls, in the app and on the phone, are Gemini Live only (D-260). */
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

const TEXT = { type: "string" };
const args = (properties: Record<string, unknown>, required?: string[]) => ({
  type: "object",
  properties,
  ...(required ? { required } : {}),
});

/**
 * What a call is told about each built-in tool it gets: a short description and only the
 * arguments a spoken request needs. Gemini Live has no prompt cache and bills the declarations
 * again on every turn, so they stay small. The tool itself still runs with its full schema,
 * validation and approvals (`POST /v1/voice/tool`), so every argument here must be one the real
 * tool takes (voice-call-tools.test.ts checks that, and the total size).
 */
export const VOICE_CALL_TOOL_SPECS: Record<
  string,
  { description: string; parameters: Record<string, unknown> }
> = {
  "memory.search": {
    description: "Search your long-term memory about the user and past work.",
    parameters: args({ query: TEXT }, ["query"]),
  },
  "memory.write": {
    description:
      'Save a lasting fact or preference as one standalone sentence. about: "person" for a fact about the user, "work" (default) for your own notes. Never save health, religion, politics, sexuality or money troubles unless asked to.',
    parameters: args({ content: TEXT, about: { type: "string", enum: ["person", "work"] } }, [
      "content",
    ]),
  },
  "knowledge.search": {
    description:
      "Search the documents you and the workspace were given. Returns snippets with their source.",
    parameters: args({ query: TEXT }, ["query"]),
  },
  "web.search": {
    description: "Search the web. Returns titles, links and snippets.",
    parameters: args({ query: TEXT }, ["query"]),
  },
  "web.fetch": {
    description: "Read a web page's text (title and main content).",
    parameters: args({ url: TEXT }, ["url"]),
  },
  "notify.user": {
    description: "Send the user a push notification (sparingly).",
    parameters: args({ title: TEXT, message: TEXT }, ["title", "message"]),
  },
  "routines.list": {
    description: "List your routines and reminders: name, schedule, on or off, next run.",
    parameters: args({}),
  },
  "routines.create": {
    description:
      "Set a reminder or schedule work for yourself. Pass exactly one of in_minutes or run_at (runs once) or schedule_cron (repeats). Each run posts its reply in this chat and notifies the user.",
    parameters: args(
      {
        name: TEXT,
        instructions: {
          type: "string",
          description: "What to do when it runs, as a message to yourself",
        },
        in_minutes: { type: "integer", description: "Once, this many minutes from now" },
        run_at: { type: "string", description: "Once, at this ISO 8601 time with offset" },
        schedule_cron: {
          type: "string",
          description: "Repeating: 5-field cron in the user's timezone",
        },
      },
      ["name", "instructions"],
    ),
  },
  "tasks.list": {
    description: "List tickets on the board, newest first.",
    parameters: args({
      status: { type: "string", enum: ["todo", "in_progress", "in_review", "blocked", "done"] },
      mine: { type: "boolean", description: "Only tickets assigned to you" },
    }),
  },
  "tasks.create": {
    description:
      "Add a ticket to the board. assignee: a bot's name; that bot starts on it right away.",
    parameters: args({ title: TEXT, details: TEXT, assignee: TEXT }, ["title"]),
  },
  "usage.report": {
    description: "The workspace's usage and estimated cost.",
    parameters: args({
      period: {
        type: "string",
        enum: ["day", "week", "month", "year"],
        description: "Default month",
      },
    }),
  },
  "device.read": {
    description:
      "Read what the user shares from their phone, computer or browser. Returns summaries with their age.",
    parameters: args(
      {
        kind: {
          type: "string",
          enum: [
            "calendar",
            "reminders",
            "contacts",
            "places",
            "photos",
            "health",
            "notifications",
            "activity",
            "browser_tab",
            "browser_history",
          ],
        },
        from: {
          type: "string",
          description: "Range start, ISO 8601 with offset (default: a day ago)",
        },
        to: { type: "string", description: "Range end (default: in 14 days)" },
        query: { type: "string", description: "browser_history: words to find" },
      },
      ["kind"],
    ),
  },
};

/**
 * The built-in tools a bot gets on a live call: a small, conversational set. Anything bigger,
 * including changing or deleting routines and watching things, goes to a normal chat run through
 * `start_task`.
 */
export const VOICE_CALL_TOOLS = new Set(Object.keys(VOICE_CALL_TOOL_SPECS));

/** The call-time declarations of these built-in tools (unknown names are left out). */
export function voiceCallTools(names: string[]): RealtimeTool[] {
  return names.flatMap((name) => {
    const spec = VOICE_CALL_TOOL_SPECS[name];
    return spec ? [{ name: ToolRegistry.wireName(name), ...spec }] : [];
  });
}

/** How much of a bot's persona a call carries (characters): it is billed again on every turn. */
export const CALL_PERSONA_CHARS = 1_500;

/**
 * A persona's start, for a call's instructions: cut at the last sentence or line end in the final
 * 200 characters when there is one, else at the limit.
 */
export function callPersona(persona: string, max = CALL_PERSONA_CHARS): string {
  if (persona.length <= max) return persona;
  const from = Math.max(0, max - 200);
  // One character past the limit, so a sentence that ends exactly at it counts.
  const tail = persona.slice(from, max + 1);
  let end = -1;
  for (const m of tail.matchAll(/[.!?](?=\s)|\n/g)) end = m.index + (m[0] === "\n" ? 0 : 1);
  if (end >= 0 && from + end > 0) return persona.slice(0, from + end).trimEnd();
  // A hard cut must not leave half of a surrogate pair.
  const last = persona.charCodeAt(max - 1);
  return persona.slice(0, last >= 0xd800 && last <= 0xdbff ? max - 1 : max);
}

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

/** A call tool the app answers itself (D-327): it opens the bot's screen on the call. */
export const SHOW_SCREEN_TOOL: RealtimeTool = {
  name: "show_screen",
  description:
    "Show the user your computer's screen in the app while you work on a task there (when they ask to see it, or something on screen needs them).",
  parameters: { type: "object", properties: {} },
};

/** Stops the jobs start_task began on this call (D-327). */
export const STOP_TASK_TOOL: RealtimeTool = {
  name: "stop_task",
  description:
    "Stop the task you started on this call with start_task, when the user asks you to stop or cancel it.",
  parameters: { type: "object", properties: {} },
};

/**
 * How many earlier turns a new call hears, and roughly how many tokens they may take (D-327).
 * They sit in the instructions, which every turn of the call is billed for again, so the budget is
 * small: the last few exchanges, each cut to its start.
 */
export const CALL_CONTEXT_TURNS = 20;
export const CALL_CONTEXT_TOKENS = 600;
/** One earlier turn's share of that budget, in characters. */
export const CALL_CONTEXT_TURN_CHARS = 300;

/**
 * The conversation's last turns, for a new call's instructions (D-327): "Earlier in this
 * conversation", oldest first, newest kept when the budget runs out (about 4 characters a token).
 * Empty when there's nothing to carry over.
 */
export function earlierInConversation(
  turns: Array<{ role: "user" | "assistant"; text: string }>,
  botName: string,
  maxTokens = CALL_CONTEXT_TOKENS,
): string {
  const budget = maxTokens * 4;
  const lines: string[] = [];
  let used = 0;
  for (const t of [...turns].reverse().slice(0, CALL_CONTEXT_TURNS)) {
    const text = t.text.replace(/\s+/g, " ").trim();
    if (!text) continue;
    const line = `${t.role === "user" ? "User" : botName}: ${text.length > CALL_CONTEXT_TURN_CHARS ? `${text.slice(0, CALL_CONTEXT_TURN_CHARS)}…` : text}`;
    if (used + line.length > budget) break;
    lines.unshift(line);
    used += line.length + 1;
  }
  if (!lines.length) return "";
  return [
    "Earlier in this conversation (by text or on an earlier call), for context. Don't repeat it back unless asked:",
    ...lines,
  ].join("\n");
}

/**
 * Gemini Live's list prices (USD per 1M tokens); the same for every current Live model. The
 * fallback for Admin → Pricing's `gemini_live` table (D-373): read them through `geminiLivePrices()`.
 */
export const GEMINI_LIVE_PRICES = {
  inputAudio: 3,
  inputText: 0.75,
  inputImage: 1,
  outputAudio: 12,
  outputText: 4.5,
};

/** Gemini Live's prices now: Admin → Pricing's values over the ones in code. */
export function geminiLivePrices(): typeof GEMINI_LIVE_PRICES {
  const o = costTables().gemini_live;
  if (!o) return GEMINI_LIVE_PRICES;
  return {
    inputAudio: o.input_audio ?? GEMINI_LIVE_PRICES.inputAudio,
    inputText: o.input_text ?? GEMINI_LIVE_PRICES.inputText,
    inputImage: o.input_image ?? GEMINI_LIVE_PRICES.inputImage,
    outputAudio: o.output_audio ?? GEMINI_LIVE_PRICES.outputAudio,
    outputText: o.output_text ?? GEMINI_LIVE_PRICES.outputText,
  };
}

/** Token counts from a Gemini Live call's `usageMetadata`, by direction and modality. */
export interface GeminiLiveUsage {
  input_audio_tokens: number;
  input_text_tokens: number;
  output_audio_tokens: number;
  output_text_tokens: number;
  /**
   * Prompt tokens in Gemini's total (`promptTokenCount`) that none of its per-kind counts
   * (`promptTokensDetails`) covers. Google's own answers say it bills the per-kind counts, which is
   * what the four fields above hold and what a call is charged for. The total came out larger in
   * every call we measured, by an amount that grows with the tool declarations, so it is kept
   * here, uncharged, until a day's invoice shows which of the two Google bills.
   */
  input_unattributed_tokens?: number;
}

/** What a call cost from its token counts (thinking and tool-use prompts count as text). */
export function geminiLiveCost(u: GeminiLiveUsage) {
  const p = geminiLivePrices();
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
  // Only when Gemini gave both: with no breakdown the whole total is already counted above.
  const unattributed = u.promptTokensDetails
    ? Math.max(0, (u.promptTokenCount ?? 0) - inAudio - inOther)
    : 0;
  const gap = (total.input_unattributed_tokens ?? 0) + unattributed;
  return {
    input_audio_tokens: total.input_audio_tokens + inAudio,
    input_text_tokens: total.input_text_tokens + inOther + (u.toolUsePromptTokenCount ?? 0),
    output_audio_tokens: total.output_audio_tokens + outAudio,
    output_text_tokens: total.output_text_tokens + outOther + (u.thoughtsTokenCount ?? 0),
    ...(gap > 0 ? { input_unattributed_tokens: gap } : {}),
  };
}

export const emptyGeminiUsage = (): GeminiLiveUsage => ({
  input_audio_tokens: 0,
  input_text_tokens: 0,
  output_audio_tokens: 0,
  output_text_tokens: 0,
});
export const STT_PROVIDERS: SttProviderId[] = ["openrouter"];
/**
 * Dictation model: Whisper Large V3 Turbo, $0.0002 a minute on OpenRouter (2026-11-13), the
 * cheapest good transcription model there (D-194, D-261).
 */
export const OPENROUTER_STT_MODEL = "openai/whisper-large-v3-turbo";
// Gemini Flash-Lite TTS: about $0.009 a minute of speech through 2026 (D-187).
export const TTS_PROVIDERS: TtsProviderId[] = ["openrouter"];

export interface VoiceBases {
  /** Gemini API (https://generativelanguage.googleapis.com); its WebSocket host is derived from it. */
  gemini?: string;
  /** OpenRouter (https://openrouter.ai/api/v1). */
  openrouter?: string;
}

export class VoiceError extends Error {
  readonly status?: number;
  /** The start of the provider's own error body, for logs (never shown to the person). */
  readonly detail?: string;
  constructor(message: string, status?: number, detail?: string) {
    super(detail ? `${message}: ${detail}` : message);
    this.status = status;
    this.detail = detail;
  }
}

async function ok(res: Response, provider: string) {
  if (res.ok) return res;
  // The status alone ("returned 400") hid why dictation failed; keep what the provider said.
  const detail = (await res.text().catch(() => "")).replace(/\s+/g, " ").trim().slice(0, 300);
  throw new VoiceError(`${provider} returned ${res.status}`, res.status, detail || undefined);
}

/** Transcribes audio on OpenRouter (an OpenAI-style multipart upload; D-261). */
export async function transcribe(
  _provider: SttProviderId,
  apiKey: string,
  audio: Uint8Array,
  mime: string,
  opts: { bases?: VoiceBases; fetch?: typeof fetch; language?: string; model?: string } = {},
): Promise<{ text: string; seconds: number | null; costUsd?: number }> {
  const f = opts.fetch ?? fetch;
  const base = (opts.bases?.openrouter ?? "https://openrouter.ai/api/v1").replace(/\/$/, "");
  const form = new FormData();
  const ext = mime.includes("wav")
    ? "wav"
    : mime.includes("mp4") || mime.includes("m4a")
      ? "m4a"
      : mime.includes("ogg")
        ? "ogg"
        : "webm";
  form.set("file", new Blob([new Uint8Array(audio)], { type: mime }), `audio.${ext}`);
  form.set("model", opts.model ?? OPENROUTER_STT_MODEL);
  if (opts.language) form.set("language", opts.language);
  const res = await ok(
    await f(`${base}/audio/transcriptions`, {
      method: "POST",
      headers: { authorization: `Bearer ${apiKey}` },
      body: form,
    }),
    "OpenRouter",
  );
  const j = (await res.json()) as {
    text?: string;
    duration?: number;
    usage?: { seconds?: number; cost?: number };
  };
  return {
    text: j.text ?? "",
    seconds: j.duration ?? j.usage?.seconds ?? null,
    costUsd: typeof j.usage?.cost === "number" ? j.usage.cost : undefined,
  };
}

/**
 * Speaks text on OpenRouter's speech endpoint (D-261). Gemini TTS there only returns raw PCM
 * (16-bit mono, 24 kHz unless the content type says otherwise), so it gets a WAV header.
 */
export async function synthesize(
  _provider: TtsProviderId,
  apiKey: string,
  text: string,
  voice: string | undefined,
  opts: { bases?: VoiceBases; fetch?: typeof fetch; model?: string } = {},
): Promise<{ audio: Uint8Array; mime: string }> {
  const f = opts.fetch ?? fetch;
  const base = (opts.bases?.openrouter ?? "https://openrouter.ai/api/v1").replace(/\/$/, "");
  const v = voice || DEFAULT_GEMINI_VOICE;
  const voiceName = GEMINI_VOICES.includes(v) || v.startsWith("voice_") ? v : DEFAULT_GEMINI_VOICE;
  const res = await ok(
    await f(`${base}/audio/speech`, {
      method: "POST",
      headers: { authorization: `Bearer ${apiKey}`, "content-type": "application/json" },
      body: JSON.stringify({
        model: opts.model ?? OPENROUTER_TTS_MODEL,
        input: text,
        voice: voiceName,
        response_format: "pcm",
      }),
    }),
    "OpenRouter",
  );
  const rate = Number(/rate=(\d+)/.exec(res.headers.get("content-type") ?? "")?.[1] ?? 24_000);
  const audio = new Uint8Array(await res.arrayBuffer());
  if (!audio.length) throw new VoiceError("OpenRouter returned no audio");
  return { audio: asWav(audio, rate || 24_000), mime: "audio/wav" };
}

export interface RealtimeTool {
  name: string;
  description: string;
  parameters: Record<string, unknown>;
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

/**
 * When a call's conversation is trimmed (tokens): past the trigger, Gemini drops the oldest turns
 * down to the target. Two-way talk is about 1,500 tokens a minute, so the defaults trim after
 * about five minutes and keep the last two. Servers set them with VOICE_CONTEXT_TRIGGER_TOKENS and
 * VOICE_CONTEXT_TARGET_TOKENS.
 */
export const DEFAULT_VOICE_CONTEXT_TRIGGER_TOKENS = 8_000;
export const DEFAULT_VOICE_CONTEXT_TARGET_TOKENS = 3_000;

/**
 * Roughly how many tokens a call carries on every turn before anyone speaks: its instructions and
 * tool declarations, at about 3 characters a token, plus the 170 or so Gemini Live adds itself
 * (measured on gemini-3.8-live, 2026-11-17: 5,974 characters came to 1,970 tokens, 16,466 to 5,450).
 */
export function callCarriedTokens(instructions: string, declarations: unknown[]): number {
  const chars =
    instructions.length + (declarations.length ? JSON.stringify(declarations).length : 0);
  return Math.ceil(chars / 3) + 200;
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
    /**
     * When the conversation's oldest turns are dropped, and down to how much (tokens; defaults
     * 8,000 and 3,000). What the call always carries is added on top.
     */
    contextCompression?: { triggerTokens?: number; targetTokens?: number };
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
  const declarations = opts.tools.map((t) => ({
    name: t.name,
    description: t.description,
    parameters: geminiSchema(t.parameters),
  }));
  // Gemini counts the instructions and tool declarations toward both trim numbers and never drops
  // them, so the conversation's budget goes on top of them. Sent as they are, a bot with a long
  // persona or many tools would forget the call at every trim (measured 2026-11-17: with the
  // carried part above the trigger, the bot remembered nothing from one turn to the next).
  const carried = callCarriedTokens(opts.instructions, declarations);
  const setup: Record<string, unknown> = {
    model: `models/${model}`,
    generationConfig: {
      responseModalities: ["AUDIO"],
      speechConfig: { voiceConfig: { prebuiltVoiceConfig: { voiceName: voice } } },
    },
    systemInstruction: { parts: [{ text: opts.instructions }] },
    ...(declarations.length ? { tools: [{ functionDeclarations: declarations }] } : {}),
    // Barge-in: the person speaking interrupts the reply (the default); a short pause ends a turn.
    realtimeInputConfig: {
      automaticActivityDetection: { silenceDurationMs: 600, prefixPaddingMs: 200 },
      activityHandling: "START_OF_ACTIVITY_INTERRUPTS",
      // Turns hold speech only, not the silence between it.
      turnCoverage: "TURN_INCLUDES_ONLY_ACTIVITY",
    },
    inputAudioTranscription: {},
    outputAudioTranscription: {},
    // Keep the context small: Gemini Live bills every turn for the whole session so far and has
    // no prompt cache, so once the conversation passes the trigger (8,000 tokens) its oldest turns
    // are dropped down to the target (3,000). It was 32,000 down to 16,000 for everything, until
    // a 155-second call was billed 110,000 input tokens for about 3,900 tokens of speech. Trimming
    // also lets calls run past Gemini's 15-minute session limit. (Gemini's own default only starts
    // at about 105,000 tokens.)
    contextWindowCompression: {
      triggerTokens:
        carried + (opts.contextCompression?.triggerTokens ?? DEFAULT_VOICE_CONTEXT_TRIGGER_TOKENS),
      slidingWindow: {
        targetTokens:
          carried + (opts.contextCompression?.targetTokens ?? DEFAULT_VOICE_CONTEXT_TARGET_TOKENS),
      },
    },
  };
  const now = Date.now();
  // The token lives as long as the longest call allows (D-426), plus room for its goodbye.
  const expiresAt = new Date(now + callLifeSeconds() * 1000).toISOString();
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

/**
 * Rough list prices for the ledger (USD); real bills come from the provider. The fallback for
 * Admin → Pricing's `voice` table (D-373): read them through `voicePrices()`.
 */
export const VOICE_PRICES = {
  /** Whisper Large V3 Turbo on OpenRouter, when a response carries no cost (D-261). */
  sttPerMinute: 0.0002,
  /** Gemini 3.8 Flash-Lite TTS, about 800 characters of speech a minute (D-187). */
  geminiTtsPerThousandChars: 0.011,
  geminiLivePerMinute: 0.02,
};

/** The voice prices now: Admin → Pricing's values over the ones in code. */
export function voicePrices(): typeof VOICE_PRICES {
  const o = costTables().voice;
  if (!o) return VOICE_PRICES;
  return {
    sttPerMinute: o.stt_per_minute ?? VOICE_PRICES.sttPerMinute,
    geminiTtsPerThousandChars:
      o.gemini_tts_per_thousand_chars ?? VOICE_PRICES.geminiTtsPerThousandChars,
    geminiLivePerMinute: o.gemini_live_per_minute ?? VOICE_PRICES.geminiLivePerMinute,
  };
}

/**
 * What one read-aloud cost, estimated: OpenRouter's speech endpoint reports no cost, and Gemini
 * TTS bills the audio ($6 per 1M audio tokens, 25 a second; doubles on 2027-01-01).
 */
export function ttsCostUsd(
  _provider: TtsProviderId,
  chars: number,
  audio?: Uint8Array,
  now = new Date(),
): number {
  const perMillion = now >= new Date("2027-01-01T00:00:00Z") ? 12 : 6;
  const seconds = wavDurationS(audio);
  if (seconds != null) return seconds * 25 * (perMillion / 1_000_000);
  return (chars / 1000) * (perMillion === 12 ? 0.0225 : voicePrices().geminiTtsPerThousandChars);
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
  if (
    audio.length >= 12 &&
    audio[0] === 0x52 &&
    audio[1] === 0x49 &&
    audio[2] === 0x46 &&
    audio[3] === 0x46
  )
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
