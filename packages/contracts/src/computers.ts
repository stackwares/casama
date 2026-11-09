import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";

const ts = z.iso.datetime({ offset: true });

export const ComputerState = z
  .enum(["provisioning", "starting", "running", "idle", "sleeping", "stopped", "error"])
  .openapi("ComputerState");

export const Computer = z
  .object({
    id: Uuid,
    org_id: Uuid,
    kind: z.enum(["private", "team", "local"]),
    name: z.string(),
    owner_bot_id: Uuid.nullable(),
    provider: z.string(),
    profile: z.enum(["headless", "desktop"]),
    state: ComputerState,
    size: z.object({ cpus: z.number().optional(), memory_mb: z.number().optional(), disk_gb: z.number().optional() }),
    has_snapshot: z.boolean(),
    last_active_at: ts.nullable(),
    error: z.string().nullable(),
    created_at: ts,
  })
  .openapi("Computer");

export const ComputerFileEntry = z
  .object({
    name: z.string(),
    path: z.string(),
    type: z.enum(["file", "dir", "link"]),
    size: z.number().int(),
    modified: z.string(),
  })
  .openapi("ComputerFileEntry");

export const Checkpoint = z
  .object({
    id: Uuid,
    computer_id: Uuid,
    run_id: Uuid.nullable(),
    label: z.string(),
    size: z.number().int(),
    created_at: ts,
  })
  .openapi("Checkpoint");

export const CreateCheckpointRequest = z.object({ label: z.string().trim().min(1).max(200) }).openapi("CreateCheckpointRequest");
