/**
 * Voice work that needs provider keys (only the worker reads Vault): transcription, read-aloud
 * audio (cached per message and voice) and Gemini Live call sessions (D-065, D-260).
 */

import {
  createGeminiLiveSession,
  DEFAULT_GEMINI_LIVE_MODEL,
  integrationToolName,
  OPENROUTER_STT_MODEL,
  type RealtimeTool,
  START_TASK_TOOL,
  STT_PROVIDERS,
  type SttProviderId,
  synthesize,
  ToolRegistry,
  transcribe,
  ttsCostUsd,
  VOICE_CALL_TOOLS,
  VOICE_PRICES,
  type VoiceBases,
  VoiceError,
} from "@casama/agent";
import type { Database } from "@casama/db";
import type { CloudModelAssignment } from "@casama/domain";
import { cloudCharge, cloudOpenRouterCharge } from "@casama/domain";
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
  /** Gemini Live model (default gemini-3.8-live). */
  geminiLiveModel?: string;
  /**
   * The server's own Google AI key (GOOGLE_AI_API_KEY): live calls and read-aloud in workspaces
   * without their own Google key use it. On Casama Cloud those are paid from credits.
   */
  serverGeminiKey?: string;
  /** Casama Cloud's live assignment (D-188). Unset on a self-hosted server. */
  cloudModels?: () => Promise<CloudModelAssignment>;
  /** The server's shared OpenRouter key (CLOUD_MODEL_UPSTREAM_KEY): dictation without a key of their own. */
  platformOpenRouterKey?: string;
  /** Casama Cloud: usage on the shared key is charged to credits. */
  billPlatform?: boolean;
}

/**
 * A bot's voice settings. Rows saved before D-260 may still name a removed read-aloud or dictation
 * service (`tts_provider`, an `stt_provider` like "deepgram", `realtime_provider`); those are
 * ignored.
 */
type BotVoice = {
  tts_voice?: string;
  stt_provider?: string;
  realtime_voice?: string;
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

/** The bot's preferred service first, when it is still one Casama offers. */
const ordered = <T extends string>(preferred: string | undefined, all: T[]) =>
  preferred && (all as string[]).includes(preferred)
    ? [preferred as T, ...all.filter((p) => p !== preferred)]
    : all;

/** Whether a credit-gated workspace still has credits once unsettled usage is counted. */
async function hasCredits(db: Database, orgId: string) {
  const [r] = await db.execute<{
    credits: string | null;
    unbilled: string;
    gate: boolean | null;
  }>(sql`
    select
      (select balance_after from public.credit_ledger where org_id = ${orgId}::uuid order by seq desc limit 1) as credits,
      (select coalesce(sum(cost_usd), 0) from public.usage_ledger
        where org_id = ${orgId}::uuid and billable and billed_at is null) as unbilled,
      (select (limits->>'credit_gate')::boolean from public.entitlements
        where org_id = ${orgId}::uuid order by created_at desc limit 1) as gate`);
  return !r?.gate || Number(r.credits ?? 0) - Number(r.unbilled) > 0;
}

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
  // On Casama Cloud, or with the server's shared key, the person cannot pick a dictation service.
  const own = await rt.key(
    orgId,
    assigned || rt.platformOpenRouterKey
      ? STT_PROVIDERS
      : ordered(bot.voice.stt_provider, STT_PROVIDERS),
  );
  // No key of their own: the server's shared OpenRouter key, on the server's model (D-194).
  const shared = !own?.key && !!rt.platformOpenRouterKey;
  const k = shared ? { provider: "openrouter", key: rt.platformOpenRouterKey ?? null } : own;
  // The app reads these codes: with no service it switches to the phone's own dictation, and a
  // failed clip is offered again instead of a bare "Something went wrong".
  if (!k?.key)
    return {
      ok: false as const,
      code: "dictation_unavailable",
      error: "Add an OpenAI key to use dictation.",
    };
  // On the server's key with billing on, dictation needs credits; without them the app falls back
  // to the phone's own dictation (D-246).
  if (shared && rt.billPlatform === true && !(await hasCredits(rt.db, orgId)))
    return {
      ok: false as const,
      code: "dictation_unavailable",
      error: "The workspace is out of credits, so dictation uses your device for now.",
    };
  let r: Awaited<ReturnType<typeof transcribe>>;
  try {
    r = await transcribe(
      k.provider as SttProviderId,
      k.key,
      Buffer.from(audioB64, "base64"),
      mime,
      {
        bases: rt.bases,
        fetch: rt.fetch,
        language,
        model: k.provider === "openai" ? assigned?.stt : shared ? OPENROUTER_STT_MODEL : undefined,
      },
    );
  } catch (e) {
    if (!(e instanceof VoiceError)) throw e;
    console.error(
      JSON.stringify({
        level: "warn",
        service: "server-worker",
        msg: "transcription failed",
        provider: k.provider,
        status: e.status,
        detail: e.detail,
        mime,
        bytes: Math.floor((audioB64.length * 3) / 4),
      }),
    );
    // A bad key is the person's to fix; anything else (an unreadable clip, a provider hiccup)
    // is worth one more try.
    const badKey = !shared && (e.status === 401 || e.status === 403);
    return {
      ok: false as const,
      code: badKey ? "dictation_unavailable" : "transcription_failed",
      error: badKey
        ? `Your ${k.provider} key was refused. Check it in Settings → Model keys.`
        : "Couldn't turn that recording into text.",
    };
  }
  const seconds = Math.ceil(r.seconds ?? 0);
  if (shared) {
    const cost = r.costUsd ?? (seconds / 60) * 0.0002;
    const billable = rt.billPlatform === true;
    await rt.db.execute(sql`insert into public.usage_ledger (org_id, bot_id, kind, quantity, cost_usd, billable, meta)
      values (${orgId}::uuid, ${botId}::uuid, 'stt_seconds', ${seconds},
              ${billable ? cloudOpenRouterCharge(cost) : cost}, ${billable},
              ${JSON.stringify({ provider: "openrouter", model: OPENROUTER_STT_MODEL, provider_cost_usd: cost, ...(billable ? { key: "server" } : {}) })}::jsonb)`);
    return { ok: true as const, text: r.text, provider: k.provider, seconds };
  }
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
  // Gemini reads aloud: the workspace's Google key first, else the server's own (D-260).
  const google = await rt.key(orgId, ["google"]);
  const k = google?.key
    ? { provider: "google" as const, key: google.key }
    : rt.serverGeminiKey
      ? { provider: "google" as const, key: rt.serverGeminiKey }
      : null;
  if (!k)
    return {
      ok: false as const,
      error: "Add a Google AI key to read aloud.",
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
  // Read-aloud on the server's Google key is charged with markup and needs credits (D-246).
  const onServerKey = k.provider === "google" && !google?.key && rt.billPlatform === true;
  if (onServerKey && !(await hasCredits(rt.db, orgId)))
    return {
      ok: false as const,
      code: "out_of_credits",
      error: "The workspace is out of credits. Add credits or change plans in Billing.",
    };
  const r = await synthesize(k.provider, k.key, text, bot.voice.tts_voice, {
    bases: rt.bases,
    fetch: rt.fetch,
    model: assigned?.tts,
  });
  await rt.db.execute(sql`insert into public.tts_cache (message_id, voice_key, mime, audio)
    values (${messageId}::uuid, ${voiceKey}, ${r.mime}, ${Buffer.from(r.audio)})
    on conflict do nothing`);
  const cost = ttsCostUsd(k.provider, text.length, r.audio);
  if (onServerKey)
    await rt.db.execute(sql`insert into public.usage_ledger (org_id, bot_id, kind, quantity, cost_usd, billable, meta)
      values (${orgId}::uuid, ${m.bot_id}::uuid, 'tts_chars', ${text.length}, ${cloudCharge(cost)}, true,
              ${JSON.stringify({ provider: "google", provider_cost_usd: cost, key: "server" })}::jsonb)`);
  else await ledger(rt.db, orgId, m.bot_id, "tts_chars", text.length, cost);
  return { ok: true as const, voiceKey, cached: false };
}

/**
 * Mints a single-use Gemini Live token with the bot's persona and tools.
 *
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
  // Every call, including a phone call, is Gemini Live: the workspace's Google key, otherwise the
  // server's own (D-260).
  const google = await rt.key(orgId, ["google"]);
  const key = google?.key ?? rt.serverGeminiKey;
  if (!key)
    return {
      ok: false as const,
      code: "voice_key_missing",
      error: "Live calls need a Google AI (Gemini) key. Add one in Settings → Model keys.",
    };
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
  const s = await createGeminiLiveSession(key, {
    model: assigned?.live ?? rt.geminiLiveModel ?? DEFAULT_GEMINI_LIVE_MODEL,
    voice: bot.voice.realtime_voice,
    instructions,
    tools,
    bases: rt.bases,
    fetch: rt.fetch,
  });
  return { ok: true as const, ...s, tools: tools.length };
}
