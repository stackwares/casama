import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";

const ts = z.iso.datetime({ offset: true });
const Risk = z.enum(["low", "medium", "high"]);

export const PluginServerInfo = z
  .object({
    key: z.string(),
    type: z.enum(["stdio", "streamable-http", "sse"]),
    command: z.string().nullable(),
    args: z.array(z.string()),
    url: z.string().nullable(),
  })
  .openapi("PluginServerInfo");

export const PluginSecretInfo = z
  .object({ name: z.string(), description: z.string(), server: z.string() })
  .openapi("PluginSecretInfo");

export const PluginPreview = z
  .object({
    name: z.string(),
    version: z.string().nullable(),
    description: z.string(),
    repo: z.string(),
    path: z.string(),
    commit: z.string(),
    skills: z.array(z.object({ name: z.string(), description: z.string() })),
    servers: z.array(PluginServerInfo),
    secrets: z.array(PluginSecretInfo),
    hosts: z.array(z.string()),
    warnings: z.array(z.string()),
  })
  .openapi("PluginPreview");

export const PreviewPluginRequest = z
  .object({
    org_id: Uuid,
    url: z.string().min(1).max(500),
    /** Preview this commit instead of the latest (the plugin directory's reviewed commit, D-241). */
    commit: z
      .string()
      .regex(/^[0-9a-f]{40}$/)
      .optional(),
  })
  .openapi("PreviewPluginRequest");

export const InstallPluginRequest = z
  .object({
    org_id: Uuid,
    bot_id: Uuid,
    url: z.string().min(1).max(500),
    /** The commit the preview showed; installing pins it. */
    commit: z.string().regex(/^[0-9a-f]{40}$/),
    secrets: z.record(z.string(), z.string().max(10_000)).optional(),
  })
  .openapi("InstallPluginRequest");

export const InstalledPluginServer = PluginServerInfo.extend({
  integration_id: Uuid,
  status: z.enum(["pending", "ok", "error"]),
  error: z.string().nullable(),
  tools: z.array(z.object({ name: z.string(), risk: Risk })),
}).openapi("InstalledPluginServer");

export const Plugin = z
  .object({
    id: Uuid,
    bot_id: Uuid,
    name: z.string(),
    version: z.string().nullable(),
    description: z.string(),
    repo: z.string(),
    path: z.string(),
    commit: z.string(),
    skills: z.array(z.object({ id: Uuid, name: z.string() })),
    servers: z.array(InstalledPluginServer),
    hosts: z.array(z.string()),
    secrets: z.array(PluginSecretInfo),
    installed_at: ts,
    updated_at: ts,
  })
  .openapi("Plugin");

export const PluginUpdatePreview = z
  .object({
    up_to_date: z.boolean(),
    from_commit: z.string(),
    to_commit: z.string(),
    from_version: z.string().nullable(),
    to_version: z.string().nullable(),
    skills_added: z.array(z.string()),
    skills_removed: z.array(z.string()),
    skills_changed: z.array(z.string()),
    servers_added: z.array(z.string()),
    servers_removed: z.array(z.string()),
    servers_changed: z.array(z.string()),
    hosts_added: z.array(z.string()),
    secrets_added: z.array(z.string()),
    preview: PluginPreview,
  })
  .openapi("PluginUpdatePreview");

export const UpdatePluginRequest = z
  .object({
    commit: z.string().regex(/^[0-9a-f]{40}$/),
    secrets: z.record(z.string(), z.string().max(10_000)).optional(),
  })
  .openapi("UpdatePluginRequest");
