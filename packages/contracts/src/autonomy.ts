import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";

const ts = z.iso.datetime({ offset: true });
const Risk = z.enum(["low", "medium", "high"]).openapi("Risk");

export const Approval = z
  .object({
    id: Uuid,
    bot_id: Uuid,
    run_id: Uuid,
    tool_name: z.string(),
    args_redacted: z.record(z.string(), z.unknown()),
    summary: z.string(),
    risk: Risk,
    status: z.enum(["pending", "approved", "denied", "expired"]),
    decided_at: ts.nullable(),
    expires_at: ts,
    created_at: ts,
  })
  .openapi("Approval");

export const ApprovalDecisionRequest = z
  .object({
    decision: z.enum(["approved", "denied"]),
    always_allow: z
      .boolean()
      .optional()
      .openapi({ description: "Always allow this tool for this bot" }),
  })
  .openapi("ApprovalDecisionRequest");

export const Secret = z
  .object({
    id: Uuid,
    org_id: Uuid,
    name: z.string(),
    allowed_hosts: z.array(z.string()),
    allowed_bot_ids: z.array(Uuid).nullable(),
    created_at: ts,
  })
  .openapi("Secret");

export const CreateSecretRequest = z
  .object({
    org_id: Uuid,
    name: z
      .string()
      .regex(/^[A-Z][A-Z0-9_]{0,63}$/)
      .openapi({ description: "Referenced as {{secret:NAME}}" }),
    value: z
      .string()
      .min(1)
      .max(10_000)
      .openapi({ description: "Stored in Vault; never returned" }),
    allowed_hosts: z.array(z.string().min(1).max(253)).min(1).max(50),
    allowed_bot_ids: z.array(Uuid).optional(),
  })
  .openapi("CreateSecretRequest");

export const IntegrationKind = z
  .enum(["mcp", "openapi", "composio", "pipedream"])
  .openapi("IntegrationKind");

export const Integration = z
  .object({
    id: Uuid,
    org_id: Uuid,
    kind: IntegrationKind,
    name: z.string(),
    status: z.enum(["pending", "ok", "error"]),
    error: z.string().nullable(),
    tools: z.array(z.object({ name: z.string(), description: z.string(), risk: Risk.optional() })),
    tools_cached_at: ts.nullable(),
    created_at: ts,
    /** The catalog app this came from (stripe, linear…); null for custom connections. */
    app_id: z.string().nullable().optional(),
    /** How it signs in. */
    auth: z.enum(["oauth", "api_key", "none"]).nullable().optional(),
    /** Bots that may use it. */
    bot_ids: z.array(Uuid).optional(),
    /** Admin overrides of a tool's risk (low runs freely, high always asks). */
    risk_overrides: z.record(z.string(), Risk).optional(),
  })
  .openapi("Integration");

export const CreateIntegrationRequest = z
  .object({
    org_id: Uuid,
    kind: IntegrationKind,
    name: z.string().regex(/^[a-z][a-z0-9_]{0,39}$/),
    config: z.record(z.string(), z.unknown()).openapi({
      description:
        "mcp: {url, auth_header?}; openapi: {spec, base_url?, auth?: {type, header?, secret}}; composio: {toolkits[], user_id?}; pipedream: {project_id, client_id, apps[], environment?}",
    }),
    secret: z
      .string()
      .min(1)
      .max(10_000)
      .optional()
      .openapi({ description: "API key or client secret; stored in Vault" }),
  })
  .openapi("CreateIntegrationRequest");

export const IntegrationTestResult = z
  .object({ ok: z.boolean(), tools: z.array(z.string()), error: z.string().optional() })
  .openapi("IntegrationTestResult");

export const AttachIntegrationRequest = z
  .object({ integration_id: Uuid, tool_allowlist: z.array(z.string()).optional() })
  .openapi("AttachIntegrationRequest");

export const RoutineTrigger = z
  .enum(["schedule", "once", "github", "webhook"])
  .openapi("RoutineTrigger", {
    description: "schedule repeats on a cron; once runs a single time at run_at",
  });

export const Routine = z
  .object({
    id: Uuid,
    bot_id: Uuid,
    name: z.string(),
    instructions_md: z.string(),
    schedule_cron: z.string().nullable(),
    timezone: z.string(),
    trigger: RoutineTrigger,
    notify: z.boolean(),
    enabled: z.boolean(),
    next_run_at: ts.nullable(),
    last_run_at: ts.nullable(),
    conversation_id: Uuid.nullable(),
    created_at: ts,
  })
  .openapi("Routine");

export const CreateRoutineRequest = z
  .object({
    bot_id: Uuid,
    name: z.string().trim().min(1).max(120),
    instructions: z.string().min(1).max(20_000),
    trigger: RoutineTrigger.optional(),
    schedule_cron: z
      .string()
      .max(100)
      .optional()
      .openapi({ description: "5-field cron, required for schedule triggers" }),
    run_at: z.iso
      .datetime({ offset: true })
      .optional()
      .openapi({ description: "When a once routine runs (it switches itself off afterwards)" }),
    timezone: z
      .string()
      .max(64)
      .optional()
      .openapi({ description: "IANA timezone; defaults to your profile's" }),
    notify: z.boolean().optional(),
    events: z
      .array(z.string().max(64))
      .max(20)
      .optional()
      .openapi({ description: "GitHub event names to accept" }),
  })
  .openapi("CreateRoutineRequest");

export const CreatedRoutine = Routine.extend({
  webhook_url: z.string().optional(),
  webhook_secret: z
    .string()
    .optional()
    .openapi({ description: "Shown once; sign requests with HMAC-SHA256" }),
}).openapi("CreatedRoutine");

export const UpdateRoutineRequest = z
  .object({
    name: z.string().trim().min(1).max(120).optional(),
    instructions: z.string().min(1).max(20_000).optional(),
    schedule_cron: z.string().max(100).optional(),
    run_at: z.iso.datetime({ offset: true }).optional(),
    timezone: z.string().max(64).optional(),
    notify: z.boolean().optional(),
    enabled: z.boolean().optional(),
  })
  .openapi("UpdateRoutineRequest");

export const Template = z
  .object({
    id: z.string(),
    name: z.string(),
    description: z.string(),
    autonomy: z.enum(["ask_always", "ask_risky", "autonomous"]),
    skills: z.array(z.string()),
    routines: z.array(z.object({ name: z.string(), schedule_cron: z.string() })),
    /** The persona's standing instructions (system prompt), so the app can show and edit them. */
    persona: z.string().optional(),
    category: z.enum(["work", "research", "build", "create", "life"]).optional(),
    /** Lucide icon name, kebab-case. */
    icon: z.string().optional(),
    /** Suggested cloud mascot name (avatar `mascot:<name>`). */
    mascot: z.string().optional(),
    /** Example first messages. */
    starters: z.array(z.string()).optional(),
  })
  .openapi("Template");

export const Task = z
  .object({
    id: Uuid,
    title: z.string(),
    details_md: z.string(),
    status: z.enum(["todo", "doing", "done", "blocked"]),
    assignee_bot_id: Uuid.nullable(),
    created_by_bot_id: Uuid.nullable(),
    result_md: z.string().nullable(),
    updated_at: ts,
  })
  .openapi("Task");
