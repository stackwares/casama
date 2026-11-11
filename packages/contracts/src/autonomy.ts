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

export const SecretKind = z.enum(["value", "totp"]).openapi("SecretKind", {
  description: "value: the secret itself; totp: a two-step seed bots use as {{totp:NAME}}",
});

export const Secret = z
  .object({
    id: Uuid,
    org_id: Uuid,
    name: z.string(),
    allowed_hosts: z.array(z.string()),
    allowed_bot_ids: z.array(Uuid).nullable(),
    kind: SecretKind,
    created_at: ts,
  })
  .openapi("Secret");

export const BotSecretRequest = z
  .object({
    id: Uuid,
    org_id: Uuid,
    bot_id: Uuid,
    run_id: Uuid,
    conversation_id: Uuid.nullable(),
    name: z.string(),
    service: z.string(),
    allowed_hosts: z.array(z.string()),
    reason: z.string(),
    kind: SecretKind,
    status: z.enum(["pending", "fulfilled", "declined", "expired"]),
    expires_at: ts,
    created_at: ts,
  })
  .openapi("BotSecretRequest", {
    description: "A bot asking for a secret; never holds a value",
  });

export const FulfillSecretRequestBody = z
  .object({
    value: z
      .string()
      .min(1)
      .max(10_000)
      .openapi({ description: "Stored in Vault; never returned, logged or shown to the bot" }),
  })
  .openapi("FulfillSecretRequestBody");

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
    kind: SecretKind.optional().openapi({
      description: "totp: value is an otpauth://totp link or a base32 key",
    }),
  })
  .openapi("CreateSecretRequest");

export const IntegrationKind = z
  .enum(["mcp", "openapi", "composio", "pipedream", "local_mcp", "a2a"])
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
    /** local_mcp: the computer it runs on and the person who owns it (D-096). */
    device: z
      .object({ id: Uuid, computer_id: Uuid.nullable(), owner_user_id: Uuid, label: z.string() })
      .nullable()
      .optional(),
  })
  .openapi("Integration");

export const CreateIntegrationRequest = z
  .object({
    org_id: Uuid,
    kind: IntegrationKind,
    name: z.string().regex(/^[a-z][a-z0-9_]{0,39}$/),
    config: z.record(z.string(), z.unknown()).openapi({
      description:
        "mcp: {url, auth_header?}; a2a: {url} (the agent's address or agent card; secret: its bearer token); openapi: {spec, base_url?, auth?: {type, header?, secret}}; composio: {toolkits[], user_id?}; pipedream: {project_id, client_id, apps[], environment?}",
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
  .enum(["schedule", "once", "github", "webhook", "calendar_event", "message", "device"])
  .openapi("RoutineTrigger", {
    description: "schedule repeats on a cron; once runs a single time at run_at",
  });

export const CalendarTriggerConfig = z
  .object({
    integration_id: Uuid.openapi({ description: "A connected Google or Outlook calendar" }),
    offset_minutes: z
      .number()
      .int()
      .min(-1440)
      .max(1440)
      .openapi({ description: "Relative to the event's start; -15 is 15 minutes before" }),
    calendar: z.string().max(200).optional(),
    outside_guests: z.boolean().optional(),
    title_match: z.string().max(200).optional(),
    has_video_link: z.boolean().optional(),
  })
  .openapi("CalendarTriggerConfig");

export const MessageTriggerConfig = z
  .object({
    channel_id: Uuid.optional(),
    channel_kind: z
      .enum(["telegram", "email", "sms", "slack", "whatsapp", "messenger", "feishu", "imessage"])
      .optional(),
    sender: z
      .string()
      .max(300)
      .optional()
      .openapi({ description: "An address or id; *@domain for email" }),
    subject_match: z.string().max(200).optional(),
    text_match: z.string().max(200).optional(),
  })
  .openapi("MessageTriggerConfig");

/** Device triggers (D-151): events from the routine creator's own phone or computer. */
export const DeviceTriggerConfig = z
  .object({
    event: z.enum([
      "wake",
      "arrive",
      "leave",
      "leave_now",
      "workout_ended",
      "notification",
      "focus_on",
      "focus_off",
      "file_added",
    ]),
    place: z
      .string()
      .trim()
      .min(1)
      .max(60)
      .optional()
      .openapi({ description: "arrive and leave: a named place (Home, Work, Gym)" }),
    app: z
      .string()
      .trim()
      .min(1)
      .max(200)
      .optional()
      .openapi({ description: "notification: the watched app (its name or package id)" }),
    minutes_before: z
      .number()
      .int()
      .min(0)
      .max(120)
      .optional()
      .openapi({ description: "leave_now: extra minutes on top of the travel time (default 5)" }),
    folder: z
      .string()
      .trim()
      .min(1)
      .max(200)
      .optional()
      .openapi({ description: "file_added: a folder the desktop app watches (Downloads)" }),
    pattern: z
      .string()
      .trim()
      .min(1)
      .max(100)
      .optional()
      .openapi({ description: "file_added: a file name pattern like *.pdf" }),
  })
  .openapi("DeviceTriggerConfig");

export const Routine = z
  .object({
    id: Uuid,
    bot_id: Uuid,
    name: z.string(),
    instructions_md: z.string(),
    schedule_cron: z.string().nullable(),
    timezone: z.string(),
    trigger: RoutineTrigger,
    calendar: CalendarTriggerConfig.nullable().optional(),
    message: MessageTriggerConfig.nullable().optional(),
    device: DeviceTriggerConfig.nullable().optional(),
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
    calendar: CalendarTriggerConfig.optional().openapi({
      description: "Required for calendar_event triggers",
    }),
    message: MessageTriggerConfig.optional().openapi({
      description:
        "Filters for message triggers: an email or chat message that matches starts the routine",
    }),
    device: DeviceTriggerConfig.optional().openapi({
      description: "Required for device triggers: the event on your own phone or computer",
    }),
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

export const TaskStatus = z
  .enum(["todo", "in_progress", "in_review", "blocked", "done"])
  .openapi("TaskStatus");
export const TaskPriority = z
  .enum(["urgent", "high", "medium", "low", "none"])
  .openapi("TaskPriority");

export const Task = z
  .object({
    id: Uuid,
    title: z.string(),
    details_md: z.string(),
    status: TaskStatus,
    priority: TaskPriority,
    assignee_bot_id: Uuid.nullable(),
    assignee_user_id: Uuid.nullable(),
    created_by_bot_id: Uuid.nullable(),
    created_by_user_id: Uuid.nullable(),
    result_md: z.string().nullable(),
    due_at: ts.nullable(),
    labels: z.array(z.string()),
    position: z.number(),
    review_required: z.boolean(),
    project_id: Uuid.nullable().openapi({ description: "Its project" }),
    milestone_id: Uuid.nullable(),
    parent_task_id: Uuid.nullable(),
    conversation_id: Uuid.nullable(),
    comments: z.number().int().openapi({ description: "How many comments the ticket has" }),
    updated_at: ts,
    created_at: ts,
  })
  .openapi("Task");

export const CreateTaskRequest = z
  .object({
    org_id: Uuid,
    title: z.string().trim().min(1).max(300),
    details_md: z.string().max(10_000).optional(),
    status: TaskStatus.optional(),
    priority: TaskPriority.optional(),
    assignee_bot_id: Uuid.nullable()
      .optional()
      .openapi({ description: "The bot starts on it at once" }),
    assignee_user_id: Uuid.nullable().optional(),
    due_at: ts.nullable().optional(),
    labels: z.array(z.string().trim().min(1).max(40)).max(10).optional(),
    review_required: z.boolean().optional(),
  })
  .openapi("CreateTaskRequest");

export const UpdateTaskRequest = CreateTaskRequest.omit({ org_id: true })
  .partial()
  .extend({ position: z.number().optional() })
  .openapi("UpdateTaskRequest");

export const TaskComment = z
  .object({
    id: Uuid,
    task_id: Uuid,
    author_type: z.enum(["user", "bot"]),
    author_user_id: Uuid.nullable(),
    author_bot_id: Uuid.nullable(),
    body_md: z.string(),
    created_at: ts,
  })
  .openapi("TaskComment");

export const CreateTaskCommentRequest = z
  .object({ body_md: z.string().trim().min(1).max(20_000) })
  .openapi("CreateTaskCommentRequest");
