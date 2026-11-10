import { z } from "@hono/zod-openapi";

const ts = z.iso.datetime({ offset: true });

export const WorkspaceFilesExport = z
  .object({
    zip_base64: z.string(),
    count: z.number().int(),
    /** The same files, unzipped (the CLI writes them to a folder). */
    files: z.array(z.object({ path: z.string(), content_base64: z.string() })),
  })
  .openapi("WorkspaceFilesExport");

export const ImportWorkspaceFilesRequest = z
  .object({
    zip_base64: z.string().max(70_000_000).optional(),
    files: z
      .array(
        z.object({ path: z.string().min(1).max(1000), content_base64: z.string().max(14_000_000) }),
      )
      .max(5000)
      .optional(),
    dry_run: z.boolean().optional(),
  })
  .openapi("ImportWorkspaceFilesRequest");

export const WorkspaceFilesResult = z
  .object({
    created: z.array(z.string()),
    updated: z.array(z.string()),
    deleted: z.array(z.string()),
    unchanged: z.number().int(),
    errors: z.array(z.string()),
    dry_run: z.boolean(),
  })
  .openapi("WorkspaceFilesResult");

export const GitSyncStatus = z
  .object({
    configured: z.boolean(),
    repo: z.string().nullable(),
    branch: z.string().nullable(),
    path: z.string().nullable(),
    enabled: z.boolean(),
    has_token: z.boolean(),
    webhook_url: z.string().nullable(),
    /** Shown once, when git sync is first set up. */
    webhook_secret: z.string().nullable(),
    last_synced_at: ts.nullable(),
    last_commit: z.string().nullable(),
    last_error: z.string().nullable(),
    open_pr_url: z.string().nullable(),
  })
  .openapi("GitSyncStatus");

export const SetGitSyncRequest = z
  .object({
    repo: z.string().regex(/^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/),
    branch: z.string().min(1).max(200).optional(),
    path: z.string().max(200).optional(),
    enabled: z.boolean().optional(),
  })
  .openapi("SetGitSyncRequest");
