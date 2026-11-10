import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";

const ts = z.iso.datetime({ offset: true });

export const LocalCapabilities = z
  .object({
    shell: z.boolean().optional(),
    files: z.boolean().optional(),
    browser: z.boolean().optional(),
    desktop: z.boolean().optional(),
    /** Local MCP servers on this computer (D-096). */
    mcp: z.boolean().optional(),
    /** Messages on a Mac: read new iMessages and send replies for an iMessage chat app (D-134). */
    messages: z.boolean().optional(),
  })
  .openapi("LocalCapabilities");

export const LocalMcpServerInfo = z
  .object({
    key: z.string().regex(/^[a-z][a-z0-9_]{0,30}$/),
    label: z.string().trim().min(1).max(80),
    kind: z.enum(["stdio", "loopback"]),
    summary: z
      .string()
      .max(300)
      .openapi({ description: "Shown to the workspace, e.g. the command without its environment" }),
    timeout_s: z.number().int().min(10).max(7200).optional().openapi({
      description: "Longest a call may take (default 1800 s); progress keeps it alive",
    }),
  })
  .openapi("LocalMcpServerInfo");

export const SetLocalMcpServersRequest = z
  .object({ servers: z.array(LocalMcpServerInfo).max(50) })
  .openapi("SetLocalMcpServersRequest");

export const LocalDevice = z
  .object({
    id: Uuid,
    org_id: Uuid,
    user_id: Uuid,
    computer_id: Uuid.nullable(),
    name: z.string(),
    platform: z.enum(["macos", "windows", "linux"]),
    capabilities: LocalCapabilities,
    allowed_roots: z.array(z.string()),
    allowed_bot_ids: z.array(Uuid),
    enabled: z.boolean(),
    online: z.boolean(),
    last_seen_at: ts.nullable(),
    created_at: ts,
  })
  .openapi("LocalDevice");

export const CreateLocalDeviceRequest = z
  .object({
    org_id: Uuid,
    name: z.string().trim().min(1).max(80),
    platform: z.enum(["macos", "windows", "linux"]),
  })
  .openapi("CreateLocalDeviceRequest");

export const CreatedLocalDevice = LocalDevice.extend({
  token: z
    .string()
    .openapi({ description: "Device token, shown once; the app keeps it in secure storage" }),
}).openapi("CreatedLocalDevice");

export const UpdateLocalDeviceRequest = z
  .object({
    name: z.string().trim().min(1).max(80).optional(),
    capabilities: LocalCapabilities.optional(),
    allowed_roots: z.array(z.string().min(1).max(1000)).max(20).optional(),
    allowed_bot_ids: z.array(Uuid).max(100).optional(),
    enabled: z.boolean().optional(),
  })
  .openapi("UpdateLocalDeviceRequest");
