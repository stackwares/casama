import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";

const ts = z.iso.datetime({ offset: true });

export const TeachStep = z
  .object({
    seq: z.number().int(),
    kind: z.enum(["click", "type", "key", "scroll"]),
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
      z.object({ name: z.string(), description: z.string().optional(), secret: z.boolean().optional() }),
    ),
    checks: z.array(z.string()),
  })
  .openapi("TeachDraft");

export const TeachSession = z
  .object({
    id: Uuid,
    bot_id: Uuid,
    computer_id: Uuid,
    status: z.enum(["recording", "drafting", "drafted", "saved", "cancelled", "failed"]),
    conversation_id: Uuid.nullable(),
    draft: TeachDraft.nullable(),
    skill_id: Uuid.nullable(),
    steps: z.array(TeachStep),
    started_at: ts,
    stopped_at: ts.nullable(),
  })
  .openapi("TeachSession");

export const StartTeachRequest = z
  .object({ computer_id: Uuid, bot_id: Uuid })
  .openapi("StartTeachRequest");

export const AddTeachStepRequest = z
  .object({
    kind: z.enum(["click", "type", "key", "scroll"]),
    x: z.number().int().min(0).max(20_000).optional(),
    y: z.number().int().min(0).max(20_000).optional(),
    button: z.number().int().min(1).max(3).optional(),
    text: z.string().max(2000).optional(),
    key: z.string().max(40).optional(),
    dx: z.number().int().min(-10_000).max(10_000).optional(),
    dy: z.number().int().min(-10_000).max(10_000).optional(),
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
