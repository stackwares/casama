import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";
import { RunEventEnvelope } from "./events.ts";

const ts = z.iso.datetime({ offset: true });

export const ReasoningEffort = z
  .enum(["none", "low", "medium", "high", "xhigh", "max"])
  .openapi("ReasoningEffort");

export const ModelChoice = z
  .object({
    credential_id: Uuid,
    model: z.string().min(1).max(200),
    reasoning_effort: ReasoningEffort.optional().openapi({
      description:
        "For reasoning models; the server default applies to the default model when unset",
    }),
  })
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

export const BotLastMessage = z
  .object({
    text: z.string().openapi({ description: "Plain text, one line, cut to 160 characters" }),
    from: z
      .enum(["you", "bot", "someone"])
      .openapi({ description: "you = the caller; someone = another person in the workspace" }),
    file_name: z.string().nullable().openapi({ description: "The first attached file, if any" }),
    file_mime: z.string().nullable(),
    conversation_id: Uuid,
    at: ts,
  })
  .openapi("BotLastMessage");

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
    folder_id: Uuid.nullable().openapi({ description: "Its sidebar folder (bot_folders)" }),
    sort_key: z.number().openapi({ description: "Order within its folder" }),
    archived_at: ts.nullable(),
    setup_status: z
      .enum(["pending", "done", "skipped"])
      .openapi({ description: "The setup interview" }),
    created_at: ts,
    last_message: BotLastMessage.nullable().optional().openapi({
      description:
        "The latest message in its direct chats you can see (listBots only); null when there is none",
    }),
  })
  .openapi("Bot");

export const StartSetupResponse = z
  .object({ conversation_id: Uuid, run_id: Uuid })
  .openapi("StartSetupResponse");

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
    kind: z.enum(["direct", "group"]),
    bot_ids: z.array(Uuid).openapi({ description: "Group chats: every bot, the lead first" }),
    created_at: ts,
  })
  .openapi("Conversation");

export const CreateConversationRequest = z
  .object({
    bot_id: Uuid.openapi({ description: "The bot, or a group chat's lead" }),
    title: z.string().max(200).optional(),
    bot_ids: z.array(Uuid).min(1).max(10).optional().openapi({
      description: "A group chat: the other bots (the lead may be listed too); 2 to 10 bots in all",
    }),
  })
  .openapi("CreateConversationRequest");

export const MessageAttachment = z
  .object({
    path: z
      .string()
      .min(1)
      .max(500)
      .regex(/^(?!\/)(?!.*\.\.)/, "A path under the home folder, without ..")
      .openapi({
        description:
          "Where the file is on the bot's computer, under its home folder (upload it first)",
      }),
    name: z.string().min(1).max(255),
    mime_type: z.string().max(120),
    size: z.number().int().min(0),
  })
  .openapi("MessageAttachment");

/** What the person did on a bot's interactive UI (D-086): the action and its resolved values. */
export const UiActionPart = z
  .object({
    surface_id: z.string().min(1).max(120),
    name: z.string().min(1).max(120),
    context: z.record(z.string(), z.unknown()).optional(),
  })
  .openapi("UiActionPart");

export const SendMessageRequest = z
  .object({
    text: z.string().trim().max(100_000).default(""),
    attachments: z.array(MessageAttachment).max(10).optional(),
    ui_action: UiActionPart.optional(),
    skills: z
      .array(z.string().regex(/^[a-z0-9][a-z0-9_-]{0,62}$/))
      .max(5)
      .optional()
      .openapi({
        description: "Skills picked with / in the composer; the run loads them up front",
      }),
  })
  .refine((b) => b.text.length > 0 || (b.attachments?.length ?? 0) > 0 || !!b.ui_action, {
    message: "Send some text or an attachment",
    path: ["text"],
  })
  .openapi("SendMessageRequest");

export const EditMessageRequest = z
  .object({ text: z.string().trim().min(1).max(100_000) })
  .openapi("EditMessageRequest");

export const SwitchBranchRequest = z
  .object({ message_id: Uuid.openapi({ description: "A message on the branch to show" }) })
  .openapi("SwitchBranchRequest");

export const SwitchBranchResponse = z
  .object({ head_message_id: Uuid })
  .openapi("SwitchBranchResponse");

export const SendMessageResponse = z
  .object({
    message_id: Uuid,
    run_id: Uuid,
    conversation_id: Uuid,
    run_ids: z.array(Uuid).optional().openapi({ description: "Group chats: every bot's run" }),
    joined: z.boolean().optional().openapi({
      description:
        "The bot was already working here: the message joined that run (run_id), which sees it before its next step",
    }),
  })
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
    trace_id: z.string().nullable().openapi({ description: "OpenTelemetry trace of this run" }),
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
    "deepgram",
    "elevenlabs",
    "cartesia",
    "fish_audio",
    "chatgpt",
    "treg",
    "google_maps",
    "mapbox",
  ])
  .openapi("ProviderId");

export const CredentialStatus = z
  .enum(["ok", "plan_usage_off", "needs_reconnect"])
  .openapi("CredentialStatus", {
    description:
      "ok; plan_usage_off: signed in to ChatGPT without granting plan usage; needs_reconnect: sign in again",
  });

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
    owner_user_id: Uuid.nullable().openapi({
      description: "Set for personal credentials (a ChatGPT plan): only the owner's runs use it",
    }),
    status: CredentialStatus,
    account: z
      .string()
      .nullable()
      .openapi({ description: "The signed-in ChatGPT account's email (chatgpt only)" }),
    fallback_on_limit: z.boolean().openapi({
      description: "chatgpt: use the bot's next model when the plan limit is reached",
    }),
    created_at: ts,
  })
  .openapi("Credential");

export const UpdateCredentialRequest = z
  .object({
    label: z.string().trim().min(1).max(80).optional(),
    fallback_on_limit: z.boolean().optional(),
  })
  .openapi("UpdateCredentialRequest");

export const ChatGptSignInStartRequest = z
  .object({
    org_id: Uuid,
    redirect_port: z.number().int().min(1024).max(65535).openapi({
      description:
        "The client's loopback port; OpenAI redirects to http://127.0.0.1:<port>/auth/callback",
    }),
    credential_id: Uuid.optional().openapi({ description: "Reconnect this ChatGPT credential" }),
  })
  .openapi("ChatGptSignInStartRequest");

export const ChatGptSignInStart = z
  .object({
    authorize_url: z.string(),
    redirect_uri: z.string(),
    state: z.string(),
    expires_at: ts,
  })
  .openapi("ChatGptSignInStart");

export const ChatGptSignInCompleteRequest = z
  .object({
    state: z.string().min(16).max(200),
    code: z.string().min(1).max(4000).optional(),
    client_id: z
      .string()
      .min(1)
      .max(200)
      .optional()
      .openapi({ description: "The issued client id from the callback (first sign-in)" }),
    error: z.string().max(200).optional(),
    error_description: z.string().max(1000).optional(),
  })
  .openapi("ChatGptSignInCompleteRequest");

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

export const ModelOption = z
  .object({
    id: z.string(),
    name: z.string(),
    context_length: z.number().int().optional(),
    featured: z
      .boolean()
      .optional()
      .openapi({ description: "Recommended by Casama; listed first" }),
  })
  .openapi("ModelOption");

export const ModelOptionList = z
  .object({
    items: z.array(ModelOption),
    source: z.enum(["live", "featured"]).openapi({
      description:
        "live: the provider's own list; featured: Casama's short list (provider unreachable or fixture mode)",
    }),
    error: z.string().optional(),
  })
  .openapi("ModelOptionList");

export const Memory = z
  .object({
    /** A uuid in the built-in store; the provider's id with a memory backend (D-137). */
    id: z.string(),
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
    period: z.enum(["day", "week", "month", "year"]),
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
    /** Per UTC day in the period, oldest first (days without usage are left out). */
    by_day: z
      .array(
        z.object({
          day: z.string(),
          cost_usd: z.number(),
          tokens_in: z.number().int(),
          tokens_out: z.number().int(),
        }),
      )
      .optional(),
    by_model: z
      .array(
        z.object({
          model: z.string().nullable(),
          cost_usd: z.number(),
          tokens_in: z.number().int(),
          tokens_out: z.number().int(),
        }),
      )
      .optional(),
    /** Everything metered: tokens, computer and live-view seconds, read-aloud characters. */
    by_kind: z
      .array(z.object({ kind: z.string(), quantity: z.number(), cost_usd: z.number() }))
      .optional(),
    runs: z.number().int().optional(),
  })
  .openapi("UsageReport");

export const StartWelcomeRequest = z
  .object({
    first_name: z.string().max(80).optional(),
    bot_name: z.string().min(1).max(80).optional(),
  })
  .openapi("StartWelcomeRequest");
export const WelcomeChat = z
  .object({ org_id: Uuid, bot_id: Uuid, conversation_id: Uuid, created: z.boolean() })
  .openapi("WelcomeChat");

export const MemoryBackend = z
  .object({
    provider: z.enum(["postgres", "honcho", "supermemory"]),
    base_url: z.string().nullable(),
    workspace: z.string().nullable(),
    updated_at: z.iso.datetime({ offset: true }).nullable(),
  })
  .openapi("MemoryBackend");

export const SetMemoryBackendRequest = z
  .object({
    provider: z.enum(["honcho", "supermemory"]),
    api_key: z.string().min(8).max(500),
    base_url: z.url().optional(),
    workspace: z.string().min(1).max(100).optional(),
    /** Copy the bots' current memories into the new backend. */
    copy_existing: z.boolean().optional(),
  })
  .openapi("SetMemoryBackendRequest");

/** Agent-to-agent (D-140): whether a bot is published, and its agent card. */
export const BotA2a = z
  .object({ workspace_enabled: z.boolean(), published: z.boolean(), agent_card_url: z.string() })
  .openapi("BotA2a");
