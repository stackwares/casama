/**
 * Voice work that needs provider keys (only the worker reads Vault): transcription, read-aloud
 * audio (cached per message and voice) and realtime call sessions (D-065).
 */
import type { CloudModelAssignment } from "@casama/domain";
import {
  createGeminiLiveSession,
  createRealtimeSession,
  DEFAULT_GEMINI_LIVE_MODEL,
  DEFAULT_REALTIME_MODEL,
  integrationToolName,
  type RealtimeProviderId,
  type RealtimeTool,
  START_TASK_TOOL,
  STT_PROVIDERS,
  type SttProviderId,
  synthesize,
  ToolRegistry,
  TTS_PROVIDERS,
  type TtsProviderId,
  transcribe,
  ttsCostUsd,
  VOICE_CALL_TOOLS,
  VOICE_PRICES,
  type VoiceBases,
} from "@casama/agent";
import type { Database } from "@casama/db";
import { sql } from "drizzle-orm";

export interface VoiceRuntime {
  db: Database;
  key: (
    orgId: string,
    providers: string[],
  ) => Promise<{ provider: string; key: string | null } | null>;
  bases?: VoiceBases;
  fetch?: typeof fetch;
  tools: ToolRegistry;
  computers: boolean;
  realtimeModel?: string;
  /** Gemini Live model (default gemini-3.8-live). */
  geminiLiveModel?: string;
  /**
   * The server's own Google AI key (GOOGLE_AI_API_KEY): live calls in workspaces without their own
   * Gemini or OpenAI key use it. On Casama Cloud those calls are paid from credits.
   */
  serverGeminiKey?: string;
  /** Casama Cloud's live assignment (D-188). Unset on a self-hosted server. */
  cloudModels?: () => Promise<CloudModelAssignment>;
}

type BotVoice = {
  tts_provider?: TtsProviderId;
  tts_voice?: string;
  stt_provider?: SttProviderId;
  realtime_voice?: string;
  /** Prefer one live-call provider when the workspace has keys for both. */
  realtime_provider?: RealtimeProviderId;
  /** Connected-app tools (full names) the bot also gets on calls, on top of the voice set. */
  call_tools?: string[];
};

/**
 * The connected-app tools a bot chose for calls, from each connection's cached tool list (no
 * refresh, so starting a call stays fast). Running them still goes through the bot's run, which
 * checks the bot may use them.
 */
async function chosenCallTools(db: Database, botId: string, chosen: string[]) {
  if (!chosen.length) return [] as RealtimeTool[];
  const rows = await db.execute<{
    kind: string;
    name: string;
    tools_cache: Array<{
      name: string;
      description?: string;
      inputSchema?: Record<string, unknown>;
    }>;
    tool_allowlist: string[] | null;
  }>(sql`
    select i.kind, i.name, i.tools_cache, bi.tool_allowlist
    from public.bot_integrations bi join public.integrations i on i.id = bi.integration_id
    where bi.bot_id = ${botId}::uuid and i.status <> 'error'`);
  const wanted = new Set(chosen);
  const out: RealtimeTool[] = [];
  for (const r of rows)
    for (const t of r.tools_cache ?? []) {
      if (r.tool_allowlist && !r.tool_allowlist.includes(t.name)) continue;
      const full = integrationToolName({ kind: r.kind as "mcp", name: r.name }, t.name);
      if (!wanted.has(full)) continue;
      out.push({
        name: ToolRegistry.wireName(full),
        description: `[${r.name}] ${t.description ?? ""}`.slice(0, 1024),
        parameters: t.inputSchema ?? { type: "object" },
      });
    }
  return out;
}

async function botVoice(db: Database, botId: string) {
  const [b] = await db.execute<{
    voice: BotVoice;
    persona_md: string;
    name: string;
    org_id: string;
  }>(sql`select voice, persona_md, name, org_id from public.bots where id = ${botId}::uuid`);
  if (!b) throw new Error("bot_not_found");
  return b;
}

const ordered = <T extends string>(preferred: T | undefined, all: T[]) =>
  preferred ? [preferred, ...all.filter((p) => p !== preferred)] : all;

async function ledger(
  db: Database,
  orgId: string,
  botId: string | null,
  kind: string,
  quantity: number,
  cost: number,
) {
  await db.execute(sql`insert into public.usage_ledger (org_id, bot_id, kind, quantity, cost_usd)
    values (${orgId}::uuid, ${botId}::uuid, ${kind}, ${quantity}, ${cost})`);
}

export async function voiceTranscribe(
  rt: VoiceRuntime,
  orgId: string,
  botId: string,
  audioB64: string,
  mime: string,
  language?: string,
) {
  const bot = await botVoice(rt.db, botId);
  if (bot.org_id !== orgId) throw new Error("bot_not_found");
  const assigned = await rt.cloudModels?.();
  // On Casama Cloud the person cannot pick a dictation service.
  const k = await rt.key(orgId, assigned ? STT_PROVIDERS : ordered(bot.voice.stt_provider, STT_PROVIDERS));
  if (!k?.key)
    return { ok: false as const, error: "Add an OpenAI or Deepgram key to use dictation." };
  const r = await transcribe(
    k.provider as SttProviderId,
    k.key,
    Buffer.from(audioB64, "base64"),
    mime,
    {
      bases: rt.bases,
      fetch: rt.fetch,
      language,
      model: k.provider === "openai" ? assigned?.stt : undefined,
    },
  );
  const seconds = Math.ceil(r.seconds ?? 0);
  await ledger(
    rt.db,
    orgId,
    botId,
    "stt_seconds",
    seconds,
    (seconds / 60) * VOICE_PRICES.sttPerMinute,
  );
  return { ok: true as const, text: r.text, provider: k.provider, seconds };
}

/** Synthesizes an assistant message once per voice and stores it in tts_cache. */
export async function voiceSpeak(rt: VoiceRuntime, orgId: string, messageId: string) {
  const [m] = await rt.db.execute<{
    content: Array<{ type: string; text?: string }>;
    bot_id: string;
  }>(sql`
    select m.content, c.bot_id from public.messages m join public.conversations c on c.id = m.conversation_id
    where m.id = ${messageId}::uuid and m.org_id = ${orgId}::uuid`);
  if (!m) return { ok: false as const, error: "Message not found." };
  const bot = await botVoice(rt.db, m.bot_id);
  const assigned = await rt.cloudModels?.();
  const google = assigned ? await rt.key(orgId, ["google"]) : null;
  const k =
    assigned && (google?.key || rt.serverGeminiKey)
      ? { provider: "google", key: google?.key ?? rt.serverGeminiKey ?? null }
      : await rt.key(orgId, assigned ? TTS_PROVIDERS : ordered(bot.voice.tts_provider, TTS_PROVIDERS));
  if (!k?.key)
    return {
      ok: false as const,
      error: "Add a Google AI, OpenAI, ElevenLabs, Cartesia or Fish Audio key to read aloud.",
    };
  const voiceKey = `${k.provider}:${bot.voice.tts_voice ?? ""}`;
  const [cached] = await rt.db.execute<{ mime: string }>(sql`
    select mime from public.tts_cache where message_id = ${messageId}::uuid and voice_key = ${voiceKey}`);
  if (cached) return { ok: true as const, voiceKey, cached: true };
  const text = m.content
    .filter((p) => p.type === "text")
    .map((p) => p.text ?? "")
    .join("\n")
    .replace(/```[\s\S]*?```/g, " (code omitted) ")
    .slice(0, 4000);
  if (!text.trim()) return { ok: false as const, error: "This message has no text to read." };
  const r = await synthesize(k.provider as TtsProviderId, k.key, text, bot.voice.tts_voice, {
    bases: rt.bases,
    fetch: rt.fetch,
    model: k.provider === "google" ? assigned?.tts : undefined,
  });
  await rt.db.execute(sql`insert into public.tts_cache (message_id, voice_key, mime, audio)
    values (${messageId}::uuid, ${voiceKey}, ${r.mime}, ${Buffer.from(r.audio)})
    on conflict do nothing`);
  await ledger(
    rt.db,
    orgId,
    m.bot_id,
    "tts_chars",
    text.length,
    ttsCostUsd(k.provider as TtsProviderId, text.length, r.audio),
  );
  return { ok: true as const, voiceKey, cached: false };
}

/** Mints an ephemeral realtime key with the bot's persona and tools. */
/**
 * `greeting`: an answered phone call (D-135); the bot speaks first.
 * `phone`: an outbound call for the person (D-141): μ-law audio, the call's instructions, and only
 * an end_call function.
 */
export async function voiceSession(
  rt: VoiceRuntime,
  orgId: string,
  botId: string,
  greeting?: string,
  phone?: boolean,
) {
  const bot = await botVoice(rt.db, botId);
  if (bot.org_id !== orgId) throw new Error("bot_not_found");
  const assigned = await rt.cloudModels?.();
  // Every call, including a phone call, uses Gemini Live when a Google key exists: the
  // workspace's own, otherwise the server's. OpenAI Realtime is only the last resort (D-187).
  const google = await rt.key(orgId, ["google"]);
  const openai = await rt.key(orgId, ["openai"]);
  const k = google?.key
    ? google
    : rt.serverGeminiKey
      ? { provider: "google", key: rt.serverGeminiKey }
      : openai;
  if (!k?.key)
    return {
      ok: false as const,
      code: "voice_key_missing",
      error: "Live calls need a Google AI (Gemini) or OpenAI key.",
    };
  const provider = k.provider === "google" ? "gemini" : "openai";
  // Calls get a small conversational tool set (each definition goes with the session and may
  // count on every turn); bigger jobs go to a normal chat run through start_task.
  const defs = rt.tools
    .available({ computer: rt.computers, desktop: false, vision: false })
    .filter((d) => VOICE_CALL_TOOLS.has(d.name));
  const tools: RealtimeTool[] = phone
    ? [
        {
          name: "end_call",
          description: "Hang up the call once you've said goodbye.",
          parameters: { type: "object", properties: {} },
        },
      ]
    : [
        ...rt.tools.specs(defs).map((s) => ({
          name: s.name,
          description: s.description.slice(0, 1024),
          parameters: s.inputSchema,
        })),
        ...(await chosenCallTools(rt.db, botId, bot.voice.call_tools ?? [])),
        START_TASK_TOOL,
      ];
  const instructions = [
    phone
      ? ""
      : `You are ${bot.name}, talking with the user on a live voice call. Keep replies short and natural.`,
    bot.persona_md,
    phone
      ? ""
      : 'Use tools when needed. Before you use a tool, always say a few words first so the caller isn\'t left in silence (like "Let me check that for you" or "One moment, looking that up"), then wait for the result before answering. If a tool says it is still working, tell the caller and keep the conversation going. Some actions may need their approval in the Casama app. For anything that needs your computer, files, the browser, connected apps or several steps, use start_task: it runs in the chat and the result appears there.',
    greeting,
  ]
    .filter(Boolean)
    .join("\n\n");
  if (provider === "gemini") {
    const s = await createGeminiLiveSession(k.key, {
      model: assigned?.live ?? rt.geminiLiveModel ?? DEFAULT_GEMINI_LIVE_MODEL,
      voice: bot.voice.realtime_voice,
      instructions,
      tools,
      bases: rt.bases,
      fetch: rt.fetch,
    });
    return { ok: true as const, ...s, tools: tools.length };
  }
  const s = await createRealtimeSession(k.key, {
    model: assigned?.realtime ?? rt.realtimeModel ?? DEFAULT_REALTIME_MODEL,
    voice: bot.voice.realtime_voice,
    instructions,
    tools,
    bases: rt.bases,
    fetch: rt.fetch,
    phone,
    transcriptionModel: assigned?.stt,
  });
  return { ok: true as const, ...s, setup: null, tools: tools.length };
}
