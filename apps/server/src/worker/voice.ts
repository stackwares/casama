/**
 * Voice work that needs provider keys (only the worker reads Vault): transcription, read-aloud
 * audio (cached per message and voice) and realtime call sessions (D-065).
 */
import {
  createRealtimeSession,
  DEFAULT_REALTIME_MODEL,
  type RealtimeTool,
  STT_PROVIDERS,
  type SttProviderId,
  synthesize,
  type ToolRegistry,
  TTS_PROVIDERS,
  type TtsProviderId,
  transcribe,
  VOICE_PRICES,
  type VoiceBases,
} from "@kasama/agent";
import type { Database } from "@kasama/db";
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
}

type BotVoice = {
  tts_provider?: TtsProviderId;
  tts_voice?: string;
  stt_provider?: SttProviderId;
  realtime_voice?: string;
};

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
  const k = await rt.key(orgId, ordered(bot.voice.stt_provider, STT_PROVIDERS));
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
  const k = await rt.key(orgId, ordered(bot.voice.tts_provider, TTS_PROVIDERS));
  if (!k?.key)
    return {
      ok: false as const,
      error: "Add an ElevenLabs, OpenAI, Cartesia or Fish Audio key to read aloud.",
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
    (text.length / 1000) * VOICE_PRICES.ttsPerThousandChars,
  );
  return { ok: true as const, voiceKey, cached: false };
}

/** Mints an ephemeral realtime key with the bot's persona and tools. */
export async function voiceSession(rt: VoiceRuntime, orgId: string, botId: string) {
  const bot = await botVoice(rt.db, botId);
  if (bot.org_id !== orgId) throw new Error("bot_not_found");
  const k = await rt.key(orgId, ["openai"]);
  if (!k?.key)
    return { ok: false as const, error: "Live calls need an OpenAI key (realtime voice)." };
  // Screen tools and takeover are not offered on calls; everything else runs through /v1/voice/tool.
  const defs = rt.tools
    .available({ computer: rt.computers, desktop: false, vision: false })
    .filter((d) => !d.screen && d.name !== "computer.request_takeover");
  const tools: RealtimeTool[] = rt.tools.specs(defs).map((s) => ({
    name: s.name,
    description: s.description.slice(0, 1024),
    parameters: s.inputSchema,
  }));
  const instructions = [
    `You are ${bot.name}, talking with the user on a live voice call. Keep replies short and natural.`,
    bot.persona_md,
    "Use tools when needed; tell the user briefly what you are doing. Some actions may need their approval in the Kasama app.",
  ]
    .filter(Boolean)
    .join("\n\n");
  const s = await createRealtimeSession(k.key, {
    model: rt.realtimeModel ?? DEFAULT_REALTIME_MODEL,
    voice: bot.voice.realtime_voice,
    instructions,
    tools,
    bases: rt.bases,
    fetch: rt.fetch,
  });
  return { ok: true as const, ...s, tools: tools.length };
}
