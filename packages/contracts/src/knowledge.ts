import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";

const ts = z.iso.datetime({ offset: true });

export const KnowledgeSource = z
  .object({
    id: Uuid,
    bot_id: Uuid.nullable(),
    kind: z.enum(["upload", "website", "github", "connection"]),
    name: z.string(),
    config: z.record(z.string(), z.unknown()),
    status: z.enum(["pending", "syncing", "ready", "error"]),
    error: z.string().nullable(),
    documents: z.number().int(),
    chunks: z.number().int(),
    last_synced_at: ts.nullable(),
    created_at: ts,
  })
  .openapi("KnowledgeSource");

export const CreateKnowledgeSourceRequest = z
  .object({
    org_id: Uuid,
    /** Omit for the whole workspace (admins). */
    bot_id: Uuid.optional(),
    kind: z.enum(["upload", "website", "github", "connection"]),
    name: z.string().min(1).max(200),
    /** upload */
    files: z
      .array(
        z.object({ name: z.string().min(1).max(300), content_base64: z.string().max(34_000_000) }),
      )
      .max(50)
      .optional(),
    /** website */
    url: z.string().max(2000).optional(),
    max_pages: z.number().int().min(1).max(200).optional(),
    /** github: https://github.com/owner/repo[/tree/ref/path] */
    repo_url: z.string().max(500).optional(),
    /** How often to sync, in hours (1 to 168; 24 by default). Not for uploads. */
    sync_every_hours: z.number().int().min(1).max(168).optional(),
    /** connection */
    integration_id: Uuid.optional(),
    documents: z
      .array(
        z.object({
          tool: z.string().min(1).max(200),
          args: z.record(z.string(), z.unknown()).optional(),
          title: z.string().min(1).max(300),
          url: z.string().max(2000).optional(),
        }),
      )
      .max(100)
      .optional(),
  })
  .openapi("CreateKnowledgeSourceRequest");
