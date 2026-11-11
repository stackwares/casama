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
    size: z.object({
      cpus: z.number().optional(),
      memory_mb: z.number().optional(),
      disk_gb: z.number().optional(),
    }),
    has_snapshot: z.boolean(),
    max_desktops: z.number().int().openapi({
      description: "Team computers: bots that may use the desktop at the same time",
    }),
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

export const CreateCheckpointRequest = z
  .object({ label: z.string().trim().min(1).max(200) })
  .openapi("CreateCheckpointRequest");

export const CreateComputerRequest = z
  .object({
    org_id: Uuid,
    name: z.string().trim().min(1).max(80),
    kind: z.enum(["team", "private"]),
    owner_bot_id: Uuid.optional().openapi({ description: "Required for private computers" }),
    profile: z.enum(["headless", "desktop"]).optional(),
    provider: z
      .enum([
        "docker",
        "e2b",
        "daytona",
        "casama-cloud",
        "novita",
        "kubernetes",
        "incus",
        "boat",
        "railway",
      ])
      .optional()
      .openapi({
        description: "Hosted providers must be configured on the supervisor",
      }),
  })
  .openapi("CreateComputerRequest");

export const UpdateComputerRequest = z
  .object({
    name: z.string().trim().min(1).max(80).optional(),
    profile: z
      .enum(["headless", "desktop"])
      .optional()
      .openapi({ description: "Takes effect on the next start (a running computer restarts)" }),
    max_desktops: z
      .number()
      .int()
      .min(1)
      .max(10)
      .optional()
      .openapi({ description: "Team computers only" }),
  })
  .openapi("UpdateComputerRequest");

export const StreamMode = z.enum(["view", "control"]).openapi("StreamMode");

export const IceServer = z
  .object({
    urls: z.array(z.string()),
    username: z.string().optional(),
    credential: z.string().optional(),
  })
  .openapi("IceServer");

export const StreamSessionRequest = z
  .object({ mode: StreamMode.optional() })
  .openapi("StreamSessionRequest");

export const StreamSession = z
  .object({
    signaling_url: z.string().openapi({
      description:
        "WebSocket URL (Neko signaling protocol, proxied by the API); includes the token",
    }),
    token: z
      .string()
      .openapi({ description: "Bound to you, this computer and the mode; 5 minutes" }),
    mode: StreamMode,
    expires_at: ts,
    ice_servers: z.array(IceServer),
    ice_transport_policy: z.enum(["all", "relay"]),
    screenshot_url: z.string().openapi({ description: "Fallback: poll about once a second" }),
  })
  .openapi("StreamSession");

export const Lease = z
  .object({
    computer_id: Uuid,
    holder_type: z.enum(["bot", "user"]),
    holder_id: Uuid.nullable(),
    mode: z.enum(["view", "control"]),
    expires_at: ts.nullable(),
    you: z.boolean().openapi({ description: "Whether you hold it" }),
  })
  .openapi("Lease");

export const TakeLeaseRequest = z
  .object({
    allow_shell: z.boolean().optional().openapi({
      description: "Let the bot keep using shell and file tools while you have control",
    }),
  })
  .openapi("TakeLeaseRequest");

export const ReleaseLeaseRequest = z
  .object({
    note: z.string().max(2000).optional().openapi({ description: "Told to the bot on hand-back" }),
  })
  .openapi("ReleaseLeaseRequest");

export const TakeoverRequest = z
  .object({
    id: Uuid,
    bot_id: Uuid,
    run_id: Uuid,
    computer_id: Uuid,
    reason: z.string(),
    status: z.enum(["pending", "taken", "completed", "dismissed", "expired"]),
    note: z.string().nullable(),
    expires_at: ts,
    created_at: ts,
  })
  .openapi("TakeoverRequest");
