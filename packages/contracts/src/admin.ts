import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";

const ts = z.iso.datetime({ offset: true });

export const AdminOverview = z
  .object({
    version: z.string(),
    users: z.number().int(),
    orgs: z.number().int(),
    bots: z.number().int(),
    runs_24h: z.number().int(),
    failed_runs_24h: z.number().int(),
    cost_24h_usd: z.number(),
    computers_running: z.number().int(),
    devices_online: z.number().int(),
  })
  .openapi("AdminOverview");

const MarginTotals = {
  charged_usd: z.number().openapi({ description: "Taken from credits for usage" }),
  charged_tracked_usd: z
    .number()
    .openapi({ description: "The charged part whose cost is known per row (not computers)" }),
  upstream_usd: z.number().openapi({
    description: "What the server paid its providers, fees included, also for waived rows",
  }),
};

/** What usage on the server's keys earned against what it cost, for the instance owner (D-395). */
export const AdminMargin = z
  .object({
    days: z.number().int(),
    ...MarginTotals,
    by_day: z.array(z.object({ date: z.string(), ...MarginTotals })),
    by_kind: z.array(z.object({ kind: z.string(), ...MarginTotals })),
    top_orgs: z.array(
      z.object({
        org_id: Uuid,
        name: z.string(),
        plan_code: z.string().nullable(),
        ...MarginTotals,
      }),
    ),
  })
  .openapi("AdminMargin");

export const AdminUser = z
  .object({
    id: Uuid,
    email: z.string().nullable(),
    created_at: ts,
    last_sign_in_at: ts.nullable(),
    orgs: z.number().int(),
  })
  .openapi("AdminUser");

export const AdminOrg = z
  .object({
    id: Uuid,
    name: z.string(),
    plan_code: z.string().nullable(),
    limits: z.record(z.string(), z.number()),
    members: z.number().int(),
    bots: z.number().int(),
    cost_30d_usd: z.number(),
    suspended_at: z.string().nullable().optional(),
    suspended_reason: z.string().nullable().optional(),
  })
  .openapi("AdminOrg");

export const SuspendOrgRequest = z
  .object({ reason: z.string().trim().min(1).max(500) })
  .openapi("SuspendOrgRequest");

export const AbuseEvent = z
  .object({
    id: Uuid,
    org_id: Uuid.nullable(),
    org_name: z.string().nullable(),
    computer_id: Uuid.nullable(),
    kind: z.string(),
    action: z.string(),
    detail: z.record(z.string(), z.unknown()),
    created_at: z.string(),
  })
  .openapi("AbuseEvent");

export const SetOrgLimitsRequest = z
  .object({
    limits: z.record(z.string(), z.number().min(0)).openapi({
      description: "For example {max_bots, max_computers, monthly_usd}; replaces the org's limits",
    }),
  })
  .openapi("SetOrgLimitsRequest");

/** One hosted bot address with its recent sending health, for the instance owner. */
export const AdminMailAddress = z
  .object({
    id: Uuid,
    address: z.string(),
    org_id: Uuid.nullable(),
    org_name: z.string(),
    bot_id: Uuid.nullable(),
    bot_name: z.string(),
    status: z.enum(["active", "paused", "retired"]),
    auto_paused: z.boolean(),
    sent_30d: z.number().int(),
    bounced_30d: z.number().int(),
    complained_30d: z.number().int(),
    created_at: z.string(),
  })
  .openapi("AdminMailAddress");

export const SetMailAddressStatusRequest = z
  .object({ status: z.enum(["active", "paused"]) })
  .openapi("SetMailAddressStatusRequest");

/** The owner's admin PIN (D-452): whether one is set; the PIN itself never leaves the server. */
export const AdminPinState = z
  .object({
    set: z.boolean(),
    /** Turned off after too many wrong PINs in a row; set a new one. */
    disabled: z.boolean(),
    tries_left: z.number().int(),
  })
  .openapi("AdminPinState");

export const SetAdminPinRequest = z
  .object({ pin: z.string().regex(/^\d{6}$/) })
  .openapi("SetAdminPinRequest");

export const AdminPasskeyCheckRequest = z
  .object({
    /** The access token of the passkey sign-in the app made on the side, as proof. */
    token: z.string().min(1).max(8192),
  })
  .openapi("AdminPasskeyCheckRequest");

export const AdminPinCheckRequest = z
  .object({ pin: z.string().min(1).max(12) })
  .openapi("AdminPinCheckRequest");

/** A device whose secure hardware key confirms the owner with the screen lock (D-453). */
export const AdminDeviceKey = z
  .object({
    id: Uuid,
    name: z.string(),
    created_at: z.string().datetime({ offset: true }),
    last_used_at: z.string().datetime({ offset: true }).nullable(),
  })
  .openapi("AdminDeviceKey");

export const AdminDeviceKeyList = z
  .object({ items: z.array(AdminDeviceKey) })
  .openapi("AdminDeviceKeyList");

export const AddAdminDeviceKeyRequest = z
  .object({
    name: z.string().min(1).max(80),
    /** EC P-256 SubjectPublicKeyInfo, DER, base64. */
    public_key: z.string().min(80).max(400),
  })
  .openapi("AddAdminDeviceKeyRequest");

export const AdminDeviceChallengeRequest = z
  .object({ key_id: Uuid })
  .openapi("AdminDeviceChallengeRequest");

export const AdminDeviceChallenge = z
  .object({
    challenge_id: Uuid,
    /** Sign `casama-admin-check:<challenge>` (UTF-8) with the device's key, ECDSA SHA-256. */
    challenge: z.string(),
  })
  .openapi("AdminDeviceChallenge");

export const AdminDeviceCheckRequest = z
  .object({ challenge_id: Uuid, signature: z.string().min(1).max(512) })
  .openapi("AdminDeviceCheckRequest");

/** A passkey or PIN check recorded on this sign-in session (D-452). */
export const AdminCheck = z
  .object({ verified_at: z.string().datetime({ offset: true }) })
  .openapi("AdminCheck");

export const AdminMailReservedNames = z
  .object({ names: z.array(z.string()) })
  .openapi("AdminMailReservedNames");

export const AdminService = z
  .object({
    name: z.string(),
    configured: z.boolean(),
    healthy: z.boolean().nullable(),
    detail: z.string(),
  })
  .openapi("AdminService");

export const UpdateNotice = z
  .object({
    current: z.string(),
    latest: z.string().nullable(),
    update_available: z.boolean(),
    url: z.string().nullable(),
  })
  .openapi("UpdateNotice");

/** How apps without their own sign-in connect (D-173), set from the admin console. */
export const ConnectionSettings = z
  .object({
    composio: z.enum(["server", "own"]).openapi({
      description:
        "server: through this server's Composio account (one click). own: people use their own Composio, Pipedream or Zapier accounts.",
    }),
    google: z.enum(["composio", "direct"]).openapi({
      description:
        "Google's apps. composio: through this server's Composio account whenever it has one (the default; Google's own MCP servers need Developer Preview enrollment, D-166). direct: Google's own MCP servers with GOOGLE_OAUTH_CLIENT_ID. Casama Cloud always uses Composio.",
    }),
    composio_key: z
      .boolean()
      .openapi({ description: "Whether this server has a Composio key (COMPOSIO_API_KEY)." }),
    google_direct_available: z.boolean().openapi({
      description:
        "Whether Google's own servers can be chosen: this server has a Google client (GOOGLE_OAUTH_CLIENT_ID) and isn't Casama Cloud.",
    }),
  })
  .openapi("ConnectionSettings");

/** Either field may be left out to keep its current value. */
export const SetConnectionSettingsRequest = z
  .object({
    composio: z.enum(["server", "own"]).optional(),
    google: z.enum(["composio", "direct"]).optional(),
  })
  .openapi("SetConnectionSettingsRequest");

const modelId = z.string().trim().min(1).max(200);

/** The models Casama Cloud runs. People cannot change them; the instance owner can (D-188). */
export const CloudModels = z
  .object({
    chat: modelId.openapi({ description: "OpenRouter model for chat on Casama's key." }),
    background: modelId.openapi({
      description: "OpenRouter model for summaries, memory and briefs.",
    }),
    image: modelId.openapi({ description: "OpenRouter image model." }),
    image_resolution: z.enum(["1K", "2K", "4K"]),
    live: modelId.openapi({ description: "Gemini Live model for calls." }),
    tts: modelId.openapi({
      description:
        "OpenRouter text-to-speech model for read aloud (google/gemini-3.8-flash-lite-tts).",
    }),
    stt: modelId.openapi({
      description: "OpenRouter transcription model for dictation (openai/whisper-large-v3-turbo).",
    }),
    embedding: modelId.openapi({ description: "OpenAI embedding model." }),
    video: modelId.openapi({
      description: "OpenRouter video model (google/gemini-omni-1.2-flash).",
    }),
  })
  .openapi("CloudModels");

const decisionMode = z.enum(["off", "shadow", "on"]);
const prob = z.number().min(0).max(1);
const steps = z.number().int().min(1).max(100);

/**
 * Decision models (D-454): which model answers, which are compared in shadow, and per use off,
 * shadow (asked and logged, never acted on) or on, with its thresholds. Owner only.
 */
export const DecisionSettings = z
  .object({
    model: z.string().trim().max(200).openapi({
      description:
        "OpenRouter decision model for uses that are on (pinned, e.g. typesafe/jev-1.14). Empty: nothing acts.",
    }),
    shadow_models: z.array(z.string().trim().min(1).max(200)).max(5),
    timeout_ms: z.number().int().min(200).max(5000),
    uses: z.object({
      scan_gate: z.object({ mode: decisionMode, skip_below: prob, max_skips_in_row: steps }),
      reply_check: z.object({
        mode: decisionMode,
        flag_above: prob,
        memory_skip_below: prob,
        correction_above: prob,
      }),
      push_score: z.object({ mode: decisionMode, hold_below: prob }),
      tool_gate: z.object({ mode: decisionMode, ask_below: prob }),
      long_run: z.object({
        mode: decisionMode,
        repeating_above: prob,
        first_step: steps,
        every: steps,
      }),
      effort: z.object({ mode: decisionMode, quick_above: prob }),
      watcher_gate: z.object({ mode: decisionMode, skip_below: prob }),
    }),
  })
  .openapi("DecisionSettings");

/** How one signal of one model did against what really happened, at each threshold. */
export const DecisionSignalResult = z
  .object({
    use: z.string(),
    signal: z
      .string()
      .openapi({ description: "What is measured, e.g. scan_gate or reply_check:memory" }),
    model: z.string(),
    rows: z.number().int(),
    answered: z.number().int(),
    errors: z.number().int(),
    latency_p50_ms: z.number(),
    latency_p95_ms: z.number(),
    cost_usd: z.number(),
    labelled: z.number().int(),
    positives: z.number().int().openapi({
      description: "Labelled rows where the thing happened (a find, a flag, an accept)",
    }),
    thresholds: z.array(
      z.object({
        threshold: z.number(),
        acted: z.number().int().openapi({ description: "Answered rows the code would act on" }),
        acted_positive: z.number().int(),
        acted_negative: z.number().int(),
        acted_severe: z
          .number()
          .int()
          .openapi({ description: "scan_gate: skipped scans whose suggestion was accepted" }),
      }),
    ),
  })
  .openapi("DecisionSignalResult");

export const DecisionResults = z
  .object({ days: z.number().int(), items: z.array(DecisionSignalResult) })
  .openapi("DecisionResults");

/** A plan as the instance owner edits it (D-244). */
export const AdminPlan = z
  .object({
    code: z.string(),
    name: z.string(),
    interval: z.enum(["none", "week", "month", "year"]),
    active: z.boolean(),
    sort: z.number().int(),
    price_label: z.string().nullable(),
    limits: z.record(z.string(), z.number()),
    credit_gate: z.boolean().openapi({
      description: "Runs on Casama's keys stop when the workspace's credits run out",
    }),
    store_product_ids: z.record(z.string(), z.string()),
    dodo_product_id: z.string().nullable(),
    paywall_default: z.boolean().openapi({
      description:
        "The paywall opens on this plan: its tier for a Free workspace, its period for everyone",
    }),
    paywall_popular: z.boolean().openapi({ description: 'Marked "Most popular" on the paywall' }),
    workspaces: z.number().int().openapi({ description: "Workspaces on this plan now" }),
  })
  .openapi("AdminPlan");

export const AdminCreditPack = z
  .object({
    code: z.string(),
    name: z.string(),
    credits_usd: z.number(),
    active: z.boolean(),
    price_label: z.string().nullable(),
    store_product_ids: z.record(z.string(), z.string()),
    dodo_product_id: z.string().nullable(),
  })
  .openapi("AdminCreditPack");

export const BillingSettings = z
  .object({
    markup: z.number().min(1).openapi({
      description: "Multiplier on what Casama pays for usage on its own keys (1.3 = 30% over cost)",
    }),
  })
  .openapi("BillingSettings");

export const AdminPricing = z
  .object({
    billing_enabled: z.boolean(),
    plans: z.array(AdminPlan),
    packs: z.array(AdminCreditPack),
    settings: BillingSettings,
  })
  .openapi("AdminPricing");

const productIds = z.record(z.string(), z.string().min(1).max(200));

export const SavePlanRequest = z
  .object({
    name: z.string().min(1).max(80).optional(),
    interval: z.enum(["none", "week", "month", "year"]).optional(),
    active: z.boolean().optional(),
    sort: z.number().int().optional(),
    price_label: z.string().max(80).nullable().optional(),
    limits: z.record(z.string(), z.number().min(0)).optional().openapi({
      description: "Replaces the plan's limits; every workspace on the plan gets them right away",
    }),
    credit_gate: z.boolean().optional(),
    store_product_ids: productIds.optional(),
    dodo_product_id: z.string().max(200).nullable().optional(),
    paywall_default: z.boolean().optional().openapi({
      description: "Open the paywall on this plan; turning it on turns it off on every other plan",
    }),
    paywall_popular: z.boolean().optional(),
  })
  .openapi("SavePlanRequest");

export const SaveCreditPackRequest = z
  .object({
    name: z.string().min(1).max(80).optional(),
    credits_usd: z.number().positive().max(10000).optional(),
    active: z.boolean().optional(),
    price_label: z.string().max(80).nullable().optional(),
    store_product_ids: productIds.optional(),
    dodo_product_id: z.string().max(200).nullable().optional(),
  })
  .openapi("SaveCreditPackRequest");

const AlertKind = z.enum(["early_warning", "capacity_full", "low_memory", "disk"]);

/** How full the server is and when it runs out of room for computers (D-252). */
export const ServerCapacity = z
  .object({
    budget_mb: z.number().int().openapi({
      description: "Memory hosted computers may use (COMPUTER_HOST_MEMORY_GB); 0 = none set",
    }),
    latest: z
      .object({
        at: z.string(),
        mem_total_mb: z.number().int(),
        mem_available_mb: z.number().int(),
        load1: z.number(),
        cpus: z.number().int(),
        disk_used_pct: z.number().nullable(),
        computers_running: z.number().int(),
        computers_mem_mb: z.number().int(),
      })
      .nullable(),
    days: z.array(
      z.object({
        day: z.string(),
        peak_computers_mem_mb: z.number().int(),
        peak_computers: z.number().int(),
        min_available_mb: z.number().int(),
        peak_load1: z.number(),
      }),
    ),
    refusals_30d: z.number().int(),
    full_in_weeks: z
      .number()
      .nullable()
      .openapi({ description: "Weeks until daily peaks reach the budget at the 30-day trend" }),
    alerts: z.array(z.object({ kind: AlertKind, day: z.string(), body: z.string() })),
  })
  .openapi("ServerCapacity");

/** A public link someone reported (D-281). */
export const ReportedCreation = z
  .object({
    id: Uuid,
    org_id: Uuid,
    org_name: z.string(),
    title: z.string(),
    kind: z.string(),
    reports: z.number().int(),
    reporters: z.number().int(),
    last_reason: z.string(),
    taken_down: z.boolean(),
    last_reported_at: z.iso.datetime({ offset: true }),
  })
  .openapi("ReportedCreation");

/** The admin bot (D-435): one of the owner's bots that may propose admin actions in their chat. */
export const AdminBotSetting = z
  .object({
    enabled: z.boolean(),
    bot_id: z.uuid().nullable().openapi({
      description:
        "The bot. It must be in a workspace whose every member is an instance owner (INSTANCE_ADMIN_EMAILS).",
    }),
    available: z.boolean().openapi({
      description: "False when INSTANCE_ADMIN_EMAILS isn't set: the admin bot can't be used.",
    }),
  })
  .openapi("AdminBotSetting");

export const SetAdminBotRequest = z
  .object({ enabled: z.boolean(), bot_id: z.uuid().nullable().optional() })
  .openapi("SetAdminBotRequest");

const casamaModelsSwitch = z.enum(["on", "off"]);

/**
 * Model access on Casama Cloud (docs/OWN-KEYS-PLAN.md §3.3, §6): whether workspaces may connect
 * their own model keys or ChatGPT plans, and whether Casama's own model keys are on or off per plan.
 */
export const AdminModelAccess = z
  .object({
    own_providers: z.boolean().openapi({
      description: "Whether Cloud workspaces may use their own model keys and ChatGPT plans.",
    }),
    casama_models: z.object({
      default: casamaModelsSwitch.openapi({
        description: "Default state for any plan not listed in plans.",
      }),
      plans: z.record(z.string(), casamaModelsSwitch).openapi({
        description: "Per-plan override (for example { free: 'off' }).",
      }),
    }),
    note: z.string().max(500).nullable().openapi({
      description: "Optional note shown on the blocked card when Casama's models are off.",
    }),
  })
  .openapi("AdminModelAccess");
