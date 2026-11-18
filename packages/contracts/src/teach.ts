import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";

const ts = z.iso.datetime({ offset: true });

/** The element a browser step acted on, found again by role and label (D-323 C11). */
export const TeachTarget = z
  .object({ role: z.string().max(50).optional(), name: z.string().min(1).max(200) })
  .openapi("TeachTarget");

export const TeachStep = z
  .object({
    seq: z.number().int(),
    kind: z.enum(["click", "type", "key", "scroll", "open"]),
    x: z.number().int().nullable(),
    y: z.number().int().nullable(),
    button: z.number().int().nullable(),
    text: z.string().nullable(),
    key: z.string().nullable(),
    dx: z.number().int().nullable(),
    dy: z.number().int().nullable(),
    secret_name: z.string().nullable(),
    password: z.boolean(),
    url: z.string().nullable(),
    target: TeachTarget.nullable().optional(),
    has_screenshot: z.boolean(),
    created_at: ts,
  })
  .openapi("TeachStep");

export const TeachDraft = z
  .object({
    name: z.string(),
    description: z.string(),
    body: z.string(),
    inputs: z.array(
      z.object({
        name: z.string(),
        description: z.string().optional(),
        secret: z.boolean().optional(),
      }),
    ),
    checks: z.array(z.string()),
  })
  .openapi("TeachDraft");

export const TeachSession = z
  .object({
    id: Uuid,
    bot_id: Uuid,
    computer_id: Uuid.nullable(),
    device_id: Uuid.nullable().optional().openapi({
      description: "A recording made in a browser tab (Casama for Chrome) belongs to the browser",
    }),
    status: z.enum(["recording", "drafting", "drafted", "saved", "cancelled", "failed"]),
    conversation_id: Uuid.nullable(),
    draft: TeachDraft.nullable(),
    skill_id: Uuid.nullable(),
    steps: z.array(TeachStep),
    started_at: ts,
    stopped_at: ts.nullable(),
    error_code: z.string().nullable().optional().openapi({
      description:
        "Why the draft couldn't be written, when status is failed: the drafting run's error code (out_of_credits, plan_limit, …)",
    }),
    error_message: z.string().nullable().optional().openapi({
      description: "The same, as a sentence to show the person",
    }),
  })
  .openapi("TeachSession");

export const StartTeachRequest = z
  .object({
    computer_id: Uuid.optional(),
    device_id: Uuid.optional().openapi({
      description: "Record in this browser (a paired Casama for Chrome) instead of a computer",
    }),
    bot_id: Uuid,
  })
  .refine((b) => !!b.computer_id !== !!b.device_id, "Give a computer_id or a device_id")
  .openapi("StartTeachRequest");

export const AddTeachStepRequest = z
  .object({
    kind: z.enum(["click", "type", "key", "scroll", "open"]),
    x: z.number().int().min(0).max(20_000).optional(),
    y: z.number().int().min(0).max(20_000).optional(),
    button: z.number().int().min(1).max(3).optional(),
    text: z.string().max(2000).optional(),
    key: z.string().max(40).optional(),
    dx: z.number().int().min(-10_000).max(10_000).optional(),
    dy: z.number().int().min(-10_000).max(10_000).optional(),
    // A browser recording sends what it saw itself; a computer's is captured by the server.
    target: TeachTarget.optional(),
    url: z.string().max(2000).optional(),
    password: z.boolean().optional().openapi({
      description: "Typed into a password field: the text is dropped and becomes a secret input",
    }),
    snapshot: z.string().max(20_000).optional(),
  })
  .openapi("AddTeachStepRequest");

export const MarkTeachSecretRequest = z
  .object({ secret_name: z.string().regex(/^[A-Z][A-Z0-9_]{0,63}$/) })
  .openapi("MarkTeachSecretRequest");

export const SaveTeachRequest = z
  .object({
    name: z.string().regex(/^[a-z0-9][a-z0-9_-]{0,62}$/),
    description: z.string().min(1).max(300),
    body: z.string().min(1).max(50_000),
    try_now: z.boolean().optional(),
  })
  .openapi("SaveTeachRequest");

export const SaveTeachResponse = z
  .object({ skill_id: Uuid, conversation_id: Uuid.nullable(), run_id: Uuid.nullable() })
  .openapi("SaveTeachResponse");
