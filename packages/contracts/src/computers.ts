import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";
import { LocalCapabilities } from "./local.ts";

const ts = z.iso.datetime({ offset: true });

export const ComputerState = z
  .enum(["provisioning", "starting", "running", "idle", "sleeping", "stopped", "error"])
  .openapi("ComputerState");

/** A personal computer's device (kind "local"): what the desktop app reports (D-227). */
export const ComputerDevice = z
  .object({
    platform: z.enum(["macos", "windows", "linux"]),
    online: z.boolean(),
    last_seen_at: ts.nullable(),
    capabilities: LocalCapabilities,
  })
  .openapi("ComputerDevice");

/** A reset running on the computer, or the last one (D-240). */
export const ComputerOperation = z
  .object({
    kind: z.enum(["reset_system", "erase"]),
    step: z.enum(["saving", "wiping", "restarting", "done", "failed"]),
    checkpoint_id: Uuid.nullable().openapi({
      description: "The restore point saved first: restoring it undoes the reset",
    }),
    error: z.string().nullable(),
    started_at: ts,
    finished_at: ts.nullable(),
  })
  .openapi("ComputerOperation");

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
    os: z.string().nullable().optional().openapi({
      description:
        'The operating system to show, e.g. "Ubuntu 24.04" or "macOS 26.2"; null when unknown (D-227)',
    }),
    device: ComputerDevice.nullable().optional().openapi({
      description: "Personal computers only: the paired device",
    }),
    idle_sleep_minutes: z.number().int().optional().openapi({
      description: "Minutes without activity before it sleeps (D-240); 5 unless changed",
    }),
    operation: ComputerOperation.nullable().optional().openapi({
      description: "The last reset: in progress, done (with its undo point) or failed (D-240)",
    }),
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
    idle_sleep_minutes: z
      .number()
      .int()
      .min(5)
      .max(60)
      .optional()
      .openapi({ description: "Minutes without activity before it sleeps: 5, 15, 30 or 60" }),
  })
  .openapi("UpdateComputerRequest");

/** CPU, memory and disk right now (D-240). Read only from a computer that is already running. */
export const ComputerVitals = z
  .object({
    cpu_percent: z.number().openapi({ description: "Of the CPUs it has, 0-100" }),
    memory_used_bytes: z.number().int(),
    memory_limit_bytes: z.number().int(),
    disk_used_bytes: z.number().int(),
    disk_limit_bytes: z.number().int(),
    at: ts,
  })
  .openapi("ComputerVitals");

export const StorageCategory = z
  .object({
    id: z.enum(["files", "apps", "caches", "browser", "other"]),
    bytes: z.number().int(),
  })
  .openapi("StorageCategory");

/** What takes up the home folder (D-240). */
export const ComputerStorage = z
  .object({
    used_bytes: z.number().int(),
    limit_bytes: z.number().int(),
    categories: z.array(StorageCategory),
    cleanable_bytes: z
      .number()
      .int()
      .openapi({ description: "Caches and temporary files that Free up space removes" }),
  })
  .openapi("ComputerStorage");

export const CleanStorageResult = z
  .object({ freed_bytes: z.number().int(), storage: ComputerStorage })
  .openapi("CleanStorageResult");

export const ComputerProcess = z
  .object({
    pid: z.number().int(),
    name: z.string(),
    command: z.string(),
    cpu_percent: z.number(),
    memory_bytes: z.number().int(),
    elapsed_seconds: z.number().int(),
    system: z.boolean().openapi({ description: "Part of the computer itself; can't be stopped" }),
  })
  .openapi("ComputerProcess");

export const ResetComputerRequest = z
  .object({
    mode: z.enum(["system", "erase"]).openapi({
      description:
        "system: a fresh system, ~/workspace kept. erase: everything removed, like a new computer.",
    }),
    checkpoint: z
      .boolean()
      .optional()
      .openapi({ description: "Save a restore point first (default true)" }),
  })
  .openapi("ResetComputerRequest");

export const ComputerUsageDay = z
  .object({ date: z.string().openapi({ example: "2026-11-12" }), seconds: z.number().int() })
  .openapi("ComputerUsageDay");

/** Time on and its cost this calendar month (UTC), including the time it has been on now. */
export const ComputerUsage = z
  .object({
    month_start: z.string(),
    seconds: z.number().int(),
    cost_usd: z.number(),
    days: z.array(ComputerUsageDay),
  })
  .openapi("ComputerUsage");

export const ComputerHistoryEntry = z
  .object({
    id: Uuid,
    action: z.string().openapi({
      description:
        "computer.started, computer.slept, computer.restarted, computer.reset, computer.erased, checkpoint.created, checkpoint.restored, computer.storage_cleaned, computer.process_stopped, computer.updated",
    }),
    actor_type: z.enum(["user", "bot", "system"]),
    actor_id: Uuid.nullable(),
    actor_name: z.string().nullable(),
    metadata: z.record(z.string(), z.unknown()),
    created_at: ts,
  })
  .openapi("ComputerHistoryEntry");

export const ComputerBotUse = z
  .object({ bot_id: Uuid, name: z.string(), last_active_at: ts.nullable() })
  .openapi("ComputerBotUse");

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
