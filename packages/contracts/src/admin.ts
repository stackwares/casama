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
    realtime: modelId.openapi({
      description: "OpenAI Realtime model, used only with no Google key.",
    }),
    tts: modelId.openapi({ description: "Gemini text-to-speech model for read aloud." }),
    stt: modelId.openapi({ description: "OpenAI transcription model for dictation." }),
    embedding: modelId.openapi({ description: "OpenAI embedding model." }),
    video: modelId.openapi({
      description:
        "Video model. Gemini Omni Flash (gemini-omni-1.2-flash) on a Google AI key, or a fal model id when that is the only video key.",
    }),
  })
  .openapi("CloudModels");

/** A plan as the instance owner edits it (D-244). */
export const AdminPlan = z
  .object({
    code: z.string(),
    name: z.string(),
    interval: z.enum(["none", "month", "year"]),
    active: z.boolean(),
    sort: z.number().int(),
    price_label: z.string().nullable(),
    limits: z.record(z.string(), z.number()),
    credit_gate: z.boolean().openapi({
      description: "Runs on Casama's keys stop when the workspace's credits run out",
    }),
    store_product_ids: z.record(z.string(), z.string()),
    dodo_product_id: z.string().nullable(),
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
    interval: z.enum(["none", "month", "year"]).optional(),
    active: z.boolean().optional(),
    sort: z.number().int().optional(),
    price_label: z.string().max(80).nullable().optional(),
    limits: z.record(z.string(), z.number().min(0)).optional().openapi({
      description: "Replaces the plan's limits; every workspace on the plan gets them right away",
    }),
    credit_gate: z.boolean().optional(),
    store_product_ids: productIds.optional(),
    dodo_product_id: z.string().max(200).nullable().optional(),
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
    budget_mb: z
      .number()
      .int()
      .openapi({
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
