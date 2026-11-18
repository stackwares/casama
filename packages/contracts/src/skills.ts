import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";

const ts = z.iso.datetime({ offset: true });

export const CatalogSkill = z
  .object({
    id: z.string(),
    name: z.string(),
    description: z.string(),
    category: z.string(),
    icon: z.string().nullable().optional().openapi({
      description: "A Lucide icon name (kebab-case); apps fall back to the category's icon",
    }),
    files: z.array(z.string()),
    skill_md: z.string().optional().openapi({ description: "The raw SKILL.md, for a preview" }),
  })
  .openapi("CatalogSkill");

export const SkillCatalog = z
  .object({ categories: z.array(z.string()), items: z.array(CatalogSkill) })
  .openapi("SkillCatalog");

export const InstalledSkill = z
  .object({
    id: Uuid,
    org_id: Uuid,
    bot_id: Uuid.nullable(),
    name: z.string(),
    description: z.string(),
    source: z.enum(["manual", "catalog", "github", "bot", "gallery"]),
    source_ref: z.record(z.string(), z.unknown()),
    category: z.string().nullable(),
    file_count: z.number().int(),
    updated_at: ts,
  })
  .openapi("InstalledSkill");

export const InstallCatalogSkillRequest = z
  .object({
    org_id: Uuid,
    bot_id: Uuid.optional().openapi({
      description: "Install for one bot; default the whole workspace",
    }),
    catalog_id: z.string().min(1).max(64).optional(),
    gallery_id: z
      .string()
      .min(1)
      .max(64)
      .optional()
      .openapi({ description: "Install a skill from the gallery instead of the bundled catalog" }),
  })
  .refine((v) => Boolean(v.catalog_id) !== Boolean(v.gallery_id), {
    message: "Give a catalog skill or a gallery skill.",
  })
  .openapi("InstallCatalogSkillRequest");

export const GitHubSkillPreviewRequest = z
  .object({ org_id: Uuid, url: z.string().min(10).max(500) })
  .openapi("GitHubSkillPreviewRequest");

export const SkillPreviewFile = z
  .object({
    path: z.string(),
    size: z.number().int(),
    executable: z.boolean(),
    text: z
      .string()
      .nullable()
      .openapi({ description: "Contents of text files up to 100 KB; null for binaries" }),
  })
  .openapi("SkillPreviewFile");

export const GitHubSkillPreview = z
  .object({
    repo: z.string(),
    path: z.string(),
    ref: z.string().nullable(),
    commit: z.string().openapi({ description: "The pinned commit installs and updates use" }),
    name: z.string(),
    description: z.string(),
    skill_md: z.string(),
    files: z.array(SkillPreviewFile),
  })
  .openapi("GitHubSkillPreview");

export const InstallGitHubSkillRequest = z
  .object({
    org_id: Uuid,
    bot_id: Uuid.optional(),
    url: z.string().min(10).max(500),
    commit: z.string().regex(/^[0-9a-f]{40}$/),
  })
  .openapi("InstallGitHubSkillRequest");

export const SkillUpdateCheck = z
  .object({
    current_commit: z.string(),
    latest_commit: z.string(),
    has_update: z.boolean(),
    diff: z.array(z.string()).openapi({ description: "SKILL.md line diff (+, -, space)" }),
    files_added: z.array(z.string()),
    files_removed: z.array(z.string()),
    files_changed: z.array(z.string()),
  })
  .openapi("SkillUpdateCheck");

export const ApplySkillUpdateRequest = z
  .object({ commit: z.string().regex(/^[0-9a-f]{40}$/) })
  .openapi("ApplySkillUpdateRequest");
