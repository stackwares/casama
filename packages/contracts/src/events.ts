import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";

/**
 * Run event protocol. Every step of every run is an append-only event in run_events.
 * seq increases by 1 per run with no gaps. Clients ignore unknown types.
 */
export const RUN_EVENT_VERSION = 1;

const id = Uuid;
const ts = z.iso.datetime({ offset: true });

/** Payload schema per event type. Adding a type here is the only step needed to extend the protocol. */
export const runEventPayloads = {
  "run.started": z.object({ trigger: z.string(), model: z.string(), computer_id: id.nullable() }),
  "message.delta": z.object({ message_id: id, text: z.string() }),
  "message.completed": z.object({
    message_id: id,
    content: z.array(z.record(z.string(), z.unknown())),
  }),
  "tool.started": z.object({
    call_id: z.string(),
    tool: z.string(),
    args_redacted: z.record(z.string(), z.unknown()),
  }),
  "tool.output": z.object({ call_id: z.string(), chunk: z.string() }),
  "tool.completed": z.object({
    call_id: z.string(),
    result_preview: z.string(),
    artifact_path: z.string().nullable(),
    duration_ms: z.number().int().nonnegative(),
  }),
  "tool.failed": z.object({ call_id: z.string(), error_code: z.string(), message: z.string() }),
  "approval.requested": z.object({
    approval_id: id,
    tool: z.string(),
    args_redacted: z.record(z.string(), z.unknown()),
    risk: z.enum(["low", "medium", "high"]),
    expires_at: ts,
  }),
  "approval.resolved": z.object({
    approval_id: id,
    decision: z.enum(["approved", "denied", "expired"]),
    decided_by: id.nullable(),
  }),
  "secret.requested": z.object({
    request_id: id,
    name: z.string(),
    service: z.string(),
    allowed_hosts: z.array(z.string()),
    reason: z.string(),
    expires_at: ts,
  }),
  "secret.resolved": z.object({
    request_id: id,
    outcome: z.enum(["fulfilled", "declined", "expired"]),
  }),
  "takeover.requested": z.object({ computer_id: id, reason: z.string() }),
  "takeover.resolved": z.object({
    computer_id: id,
    outcome: z.enum(["completed", "dismissed", "expired"]),
    note: z.string().nullable(),
  }),
  "lease.changed": z.object({
    computer_id: id,
    holder_type: z.enum(["bot", "user"]),
    mode: z.enum(["view", "control"]),
  }),
  "computer.state": z.object({
    computer_id: id,
    state: z.enum(["provisioning", "starting", "running", "idle", "sleeping", "stopped", "error"]),
  }),
  "checkpoint.created": z.object({ checkpoint_id: id, label: z.string() }),
  "subrun.started": z.object({ child_run_id: id, bot_id: id, task: z.string() }),
  "subrun.completed": z.object({
    child_run_id: id,
    status: z.enum(["completed", "failed", "cancelled"]),
    summary: z.string(),
  }),
  "memory.written": z.object({
    memory_id: id,
    kind: z.enum(["fact", "episode", "summary", "preference"]),
  }),
  "skill.loaded": z.object({ skill_id: id, name: z.string() }),
  usage: z.object({
    tokens_in: z.number().int().nonnegative(),
    tokens_out: z.number().int().nonnegative(),
    cost_usd: z.number().nonnegative(),
  }),
  /** The run moved past a model it could not use, such as a ChatGPT plan at its limit. */
  "model.fallback": z.object({ from_model: z.string(), reason: z.string(), message: z.string() }),
  "run.completed": z.object({ final_message_id: id.nullable() }),
  "run.failed": z.object({ error_code: z.string(), message: z.string() }),
  "run.cancelled": z.object({ cancelled_by: id.nullable() }),
  /** An interactive UI the bot shows in the chat (D-086): A2UI v1.0 messages for one surface. */
  "ui.shown": z.object({
    surface_id: z.string(),
    messages: z.array(z.record(z.string(), z.unknown())),
  }),
} as const;

export type RunEventType = keyof typeof runEventPayloads;
export const RUN_EVENT_TYPES = Object.keys(runEventPayloads) as RunEventType[];

const envelopeShape = {
  v: z
    .number()
    .int()
    .min(1)
    .openapi({ description: `Protocol version, currently ${RUN_EVENT_VERSION}` }),
  run_id: id,
  seq: z.number().int().positive(),
  ts,
  bot_id: id,
};

/** OpenAPI component name for a type: "tool.completed" -> "ToolCompletedEvent". */
export const eventComponentName = (type: string) =>
  `${type
    .split(/[._]/)
    .map((p) => p.charAt(0).toUpperCase() + p.slice(1))
    .join("")}Event`;

const variants = RUN_EVENT_TYPES.map((type) =>
  z
    .object({ ...envelopeShape, type: z.literal(type), payload: runEventPayloads[type] })
    .openapi(eventComponentName(type)),
);

export const RunEvent = z
  .discriminatedUnion("type", variants as unknown as [(typeof variants)[0], ...typeof variants])
  .openapi("RunEvent");

export type RunEventOf<T extends RunEventType> = {
  v: number;
  run_id: string;
  seq: number;
  ts: string;
  bot_id: string;
  type: T;
  payload: z.infer<(typeof runEventPayloads)[T]>;
};
export type RunEvent = { [T in RunEventType]: RunEventOf<T> }[RunEventType];

/** Envelope as stored and sent on the wire, with an untyped payload (forward compatible). */
export const RunEventEnvelope = z
  .object({ ...envelopeShape, type: z.string(), payload: z.record(z.string(), z.unknown()) })
  .openapi("RunEventEnvelope");
export type RunEventEnvelope = z.infer<typeof RunEventEnvelope>;

/** Validate a payload for a known type. Throws on mismatch. */
export function parseRunEventPayload<T extends RunEventType>(type: T, payload: unknown) {
  return runEventPayloads[type].parse(payload) as z.infer<(typeof runEventPayloads)[T]>;
}

/** Parse an envelope; returns null for unknown types instead of throwing. */
export function parseRunEvent(input: unknown): RunEvent | null {
  const env = RunEventEnvelope.parse(input);
  if (!(env.type in runEventPayloads)) return null;
  return RunEvent.parse(env) as RunEvent;
}
