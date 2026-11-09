import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";
import { RunEventEnvelope } from "./events.ts";

const ts = z.iso.datetime({ offset: true });

export const ModelChoice = z
  .object({ credential_id: Uuid, model: z.string().min(1).max(200) })
  .openapi("ModelChoice");

export const ModelPolicy = z
  .object({
    primary: ModelChoice.optional(),
    fallbacks: z.array(ModelChoice).max(5).optional(),
    cheap: ModelChoice.optional().openapi({
      description: "Used for memory extraction, summaries and titles",
    }),
  })
  .openapi("ModelPolicy");

export const BotBudget = z
  .object({
    per_run_usd: z.number().nonnegative().optional(),
    daily_usd: z.number().nonnegative().optional(),
  })
  .openapi("BotBudget");

export const Autonomy = z.enum(["ask_always", "ask_risky", "autonomous"]).openapi("Autonomy");
export const Visibility = z.enum(["private", "team"]).openapi("Visibility");

export const Bot = z
  .object({
    id: Uuid,
    org_id: Uuid,
    name: z.string(),
    avatar_url: z.string().nullable(),
    persona_md: z.string(),
    model_policy: ModelPolicy,
    autonomy: Autonomy,
    visibility: Visibility,
    budget: BotBudget,
    status: z.enum(["idle", "working", "waiting", "disabled"]),
    default_computer_id: Uuid.nullable().openapi({
      description: "Its computer; null = its private computer, else the team computer",
    }),
    created_at: ts,
  })
  .openapi("Bot");

export const CreateBotRequest = z
  .object({
    org_id: Uuid,
    name: z.string().trim().min(1).max(80),
    persona_md: z.string().max(20000).optional(),
    avatar_url: z.url().optional(),
    model_policy: ModelPolicy.optional(),
    autonomy: Autonomy.optional(),
    visibility: Visibility.optional(),
    budget: BotBudget.optional(),
    template_id: z
      .string()
      .max(64)
      .optional()
      .openapi({ description: "Start from a starter template (persona, skills, routines)" }),
  })
  .openapi("CreateBotRequest");

export const Conversation = z
  .object({
    id: Uuid,
    bot_id: Uuid,
    title: z.string().nullable(),
    last_message_at: ts.nullable(),
    created_at: ts,
  })
  .openapi("Conversation");

export const CreateConversationRequest = z
  .object({ bot_id: Uuid, title: z.string().max(200).optional() })
  .openapi("CreateConversationRequest");

export const SendMessageRequest = z
  .object({ text: z.string().trim().min(1).max(100_000) })
  .openapi("SendMessageRequest");

export const SendMessageResponse = z
  .object({ message_id: Uuid, run_id: Uuid, conversation_id: Uuid })
  .openapi("SendMessageResponse");

export const RunStatus = z
  .enum([
    "queued",
    "running",
    "waiting_approval",
    "waiting_takeover",
    "completed",
    "failed",
    "cancelled",
  ])
  .openapi("RunStatus");

export const Run = z
  .object({
    id: Uuid,
    bot_id: Uuid,
    conversation_id: Uuid.nullable(),
    parent_run_id: Uuid.nullable(),
    trigger: z.string(),
    status: RunStatus,
    tokens_in: z.number().int(),
    tokens_out: z.number().int(),
    cost_usd: z.number(),
    last_seq: z.number().int(),
    started_at: ts.nullable(),
    ended_at: ts.nullable(),
    error: z.object({ code: z.string(), message: z.string() }).nullable(),
    created_at: ts,
  })
  .openapi("Run");

export const RunEventsPage = z
  .object({ items: z.array(RunEventEnvelope), run_status: RunStatus })
  .openapi("RunEventsPage");

export const ProviderId = z
  .enum([
    "openai",
    "anthropic",
    "google",
    "xai",
    "openrouter",
    "openai_compatible",
    "fal",
    "brave_search",
    "tavily",
  ])
  .openapi("ProviderId");

export const Credential = z
  .object({
    id: Uuid,
    org_id: Uuid,
    provider: ProviderId,
    label: z.string(),
    base_url: z.string().nullable(),
    key_hint: z.string().nullable().openapi({ description: "Last 4 characters of the key" }),
    last_tested_at: ts.nullable(),
    last_test_ok: z.boolean().nullable(),
    created_at: ts,
  })
  .openapi("Credential");

export const CreateCredentialRequest = z
  .object({
    org_id: Uuid,
    provider: ProviderId,
    label: z.string().trim().min(1).max(80),
    api_key: z
      .string()
      .min(1)
      .max(4000)
      .optional()
      .openapi({ description: "Stored in Vault; never returned" }),
    base_url: z.url().optional(),
  })
  .openapi("CreateCredentialRequest");

export const TestCredentialRequest = z
  .object({ model: z.string().min(1).max(200).optional() })
  .openapi("TestCredentialRequest");

export const CredentialTestResult = z
  .object({
    ok: z.boolean(),
    model: z.string(),
    latency_ms: z.number().int(),
    error: z.string().optional(),
  })
  .openapi("CredentialTestResult");

export const Memory = z
  .object({
    id: Uuid,
    kind: z.enum(["fact", "episode", "summary", "preference"]),
    content: z.string(),
    importance: z.number(),
    pinned: z.boolean(),
    created_at: ts,
    updated_at: ts,
  })
  .openapi("Memory");

export const UsageReport = z
  .object({
    period: z.enum(["day", "month"]),
    since: ts,
    total_cost_usd: z.number(),
    by_bot: z.array(
      z.object({
        bot_id: Uuid.nullable(),
        name: z.string().nullable(),
        cost_usd: z.number(),
        tokens_in: z.number().int(),
        tokens_out: z.number().int(),
      }),
    ),
  })
  .openapi("UsageReport");
