/**
 * Packs (docs/PLUGINS-AND-PACKS-PLAN.md): a plugin with a `com.casama/` folder that brings bots,
 * skills, routines, apps and looks to a workspace. Every field newer than the first release of
 * packs is optional, so shipped apps keep parsing.
 */
import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";
import { GalleryInput } from "./gallery.ts";
import { PluginSecretInfo, PluginServerInfo, PluginSettingInfo } from "./plugins.ts";

const ts = z.iso.datetime({ offset: true });
const Commit = z.string().regex(/^[0-9a-f]{40}$/);

export const PackItemKind = z
  .enum(["bot", "skill", "routine", "app", "look", "tools", "include"])
  .openapi("PackItemKind");

export const PackSource = z
  .object({
    kind: z.enum(["github", "gallery", "share", "upload"]),
    repo: z.string().nullable(),
    path: z.string().nullable(),
    url: z.string().nullable(),
    gallery_id: z.string().nullable(),
  })
  .openapi("PackSource");

export const PackReach = z
  .object({
    runs_code: z.boolean(),
    computer: z.boolean(),
    hosts: z.array(z.string()),
    secrets: z.array(z.string()),
    settings: z.array(z.string()),
    runs_per_week: z.number(),
    computers: z.number().int(),
    knowledge_sources: z.number().int().optional(),
    knowledge_pages: z.number().int().optional().openapi({
      description: "Website pages its bots' knowledge reads at most (each sync costs a little)",
    }),
  })
  .openapi("PackReach", { description: "What a pack can reach, worked out from its files" });

export const PackBotPreview = z
  .object({
    id: z.string(),
    name: z.string(),
    description: z.string(),
    icon: z.string(),
    mascot: z.string(),
    autonomy: z.enum(["ask_always", "ask_risky"]),
    persona: z.string(),
    starters: z.array(z.string()),
    skills: z.array(z.string()),
    routines: z.array(z.string()),
    tools: z.array(z.string()),
    rules: z
      .array(
        z.object({
          match_kind: z.enum(["tool", "group", "category"]),
          match_value: z.string(),
          rule: z.enum(["ask", "hand_off"]),
        }),
      )
      .optional()
      .openapi({ description: "Rules that narrow what the bot may do" }),
    knowledge: z
      .array(
        z.object({
          kind: z.enum(["website", "github"]),
          name: z.string(),
          url: z.string(),
          max_pages: z.number().int(),
        }),
      )
      .optional(),
  })
  .openapi("PackBotPreview");

export const PackRoutinePreview = z
  .object({
    id: z.string(),
    name: z.string(),
    description: z.string(),
    instructions_md: z.string(),
    schedule_cron: z.string(),
    bot: z.string().nullable().openapi({ description: "The pack bot it runs on, by id" }),
    runs_per_week: z.number(),
  })
  .openapi("PackRoutinePreview");

export const PackSkillPreview = z
  .object({
    name: z.string(),
    description: z.string(),
    scope: z.enum(["workspace", "bot"]),
    bots: z.array(z.string()),
    runs_scripts: z.boolean(),
  })
  .openapi("PackSkillPreview");

export const PackAppPreview = z
  .object({
    id: z.string().openapi({ description: "The app's id in the catalog once installed" }),
    name: z.string(),
    description: z.string(),
    host: z.string(),
    url: z.string(),
    auth: z.array(z.string()),
    capabilities: z.array(z.string()),
    color: z.string(),
  })
  .openapi("PackAppPreview");

export const PackLookPreview = z
  .object({
    type: z.enum(["theme", "scheme", "wallpaper"]),
    id: z.string(),
    name: z.string(),
    document: z.record(z.string(), z.unknown()),
  })
  .openapi("PackLookPreview");

export const PackIncludePreview = z
  .object({
    type: z.string(),
    id: z.string().nullable(),
    url: z.string().nullable(),
    commit: z.string().nullable(),
    name: z.string(),
    found: z.boolean().openapi({ description: "Whether it was found in the gallery" }),
  })
  .openapi("PackIncludePreview");

export const PackPreview = z
  .object({
    name: z.string(),
    title: z
      .string()
      .openapi({ description: "The name people see; `name` is the pack's identity" }),
    version: z.string().nullable(),
    description: z.string(),
    summary: z.string(),
    icon: z.string(),
    author: z.string().nullable(),
    license: z.string().nullable(),
    homepage: z.string().nullable(),
    source: PackSource,
    commit: z.string().nullable(),
    reviewed: z.boolean(),
    bots: z.array(PackBotPreview),
    routines: z.array(PackRoutinePreview),
    skills: z.array(PackSkillPreview),
    apps: z.array(PackAppPreview),
    looks: z.array(PackLookPreview),
    includes: z.array(PackIncludePreview),
    servers: z.array(PluginServerInfo),
    secrets: z.array(PluginSecretInfo),
    settings: z.array(PluginSettingInfo),
    inputs: z.array(GalleryInput),
    needs_apps: z.array(z.object({ id: z.string(), name: z.string() })),
    examples: z.array(z.string()),
    reach: PackReach,
    warnings: z.array(z.string()),
    installed: z
      .object({ id: Uuid, version: z.string().nullable(), commit: z.string().nullable() })
      .nullable()
      .openapi({ description: "This workspace already has it" }),
  })
  .openapi("PackPreview");

export const PackFileInput = z
  .object({
    path: z.string().min(1).max(500),
    base64: z.string().max(14_000_000),
    executable: z.boolean().optional(),
  })
  .openapi("PackFileInput");

const PackFrom = {
  url: z
    .string()
    .min(1)
    .max(500)
    .optional()
    .openapi({ description: "A GitHub repository or folder" }),
  commit: Commit.optional(),
  gallery_id: z.string().min(1).max(100).optional().openapi({
    description: "A reviewed pack from the plugin directory: installs its reviewed commit",
  }),
  share_token: z
    .string()
    .min(10)
    .max(200)
    .optional()
    .openapi({ description: "A shared pack link" }),
  files: z
    .array(PackFileInput)
    .max(400)
    .optional()
    .openapi({ description: "A pack file someone picked (the folder's files)" }),
};

export const PreviewPackRequest = z
  .object({ org_id: Uuid, ...PackFrom })
  .openapi("PreviewPackRequest", {
    description: "Give one of url, gallery_id, share_token, files",
  });

export const PackItemRef = z
  .object({ kind: PackItemKind, id: z.string().max(200) })
  .openapi("PackItemRef");

export const InstallPackRequest = z
  .object({
    org_id: Uuid,
    ...PackFrom,
    skip: z.array(PackItemRef).max(100).optional().openapi({ description: "Items left unticked" }),
    inputs: z.record(z.string(), z.string().max(120)).optional(),
    secrets: z.record(z.string(), z.string().max(10_000)).optional(),
    settings: z.record(z.string(), z.string().max(500)).optional(),
    bot_id: Uuid.optional().openapi({
      description: "Where tools and routines go when the pack brings no bot",
    }),
    routines_on: z.boolean().optional().openapi({
      description: "Start the pack's routines switched on (reviewed packs only)",
    }),
    device_id: Uuid.optional().openapi({
      description:
        "Run the pack's plugin tools (stdio servers) on this paired computer of yours instead of each bot's computer (D-344)",
    }),
  })
  .openapi("InstallPackRequest");

export const PackInstallItem = z
  .object({
    kind: PackItemKind,
    id: z.string(),
    name: z.string(),
    status: z.enum(["installed", "approval_pending", "skipped", "failed", "device"]),
    target_id: z.string().nullable(),
    error: z.string().nullable(),
  })
  .openapi("PackInstallItem");

export const PackItem = z
  .object({
    kind: PackItemKind,
    id: z.string(),
    name: z.string(),
    target_id: z.string().nullable(),
    bot_id: Uuid.nullable(),
    edited: z.boolean(),
  })
  .openapi("PackItem");

export const Pack = z
  .object({
    id: Uuid,
    org_id: Uuid,
    name: z.string(),
    title: z
      .string()
      .openapi({ description: "The name people see; `name` is the pack's identity" }),
    version: z.string().nullable(),
    description: z.string(),
    summary: z.string(),
    icon: z.string(),
    source: PackSource,
    commit: z.string().nullable(),
    reviewed: z.boolean(),
    items: z.array(PackItem),
    installed_at: ts,
    updated_at: ts,
  })
  .openapi("Pack");

export const PackList = z.object({ items: z.array(Pack) }).openapi("PackList");

export const PackInstallResult = z
  .object({
    status: z.enum(["installed", "approval_pending"]),
    approval_id: Uuid.nullable(),
    pack: Pack.optional(),
    items: z.array(PackInstallItem),
    missing: z.object({
      apps: z.array(z.object({ id: z.string(), name: z.string() })),
      skills: z.array(z.object({ id: z.string(), name: z.string() })),
    }),
    looks: z.array(PackLookPreview).openapi({ description: "Looks to offer on this device" }),
  })
  .openapi("PackInstallResult");

export const PackKindDiff = z
  .object({
    added: z.array(z.string()),
    removed: z.array(z.string()),
    changed: z.array(z.object({ id: z.string(), diff: z.array(z.string()) })),
  })
  .openapi("PackKindDiff");

export const PackUpdatePreview = z
  .object({
    up_to_date: z.boolean(),
    can_check: z.boolean().openapi({ description: "False for a pack from a file or a link" }),
    from_commit: z.string().nullable(),
    to_commit: z.string().nullable(),
    from_version: z.string().nullable(),
    to_version: z.string().nullable(),
    bots: PackKindDiff,
    routines: PackKindDiff,
    skills: PackKindDiff,
    apps: PackKindDiff,
    looks: PackKindDiff,
    servers: PackKindDiff,
    hosts_added: z.array(z.string()),
    secrets_added: z.array(z.string()),
    schedules_changed: z.array(z.string()),
    runs_per_week: z.object({ from: z.number(), to: z.number() }),
    reach_grew: z.boolean(),
    edited: z
      .array(PackItemRef)
      .openapi({ description: "Items the person changed: they stay theirs" }),
    preview: PackPreview.optional(),
  })
  .openapi("PackUpdatePreview");

export const UpdatePackRequest = z
  .object({
    commit: Commit,
    take_theirs: z.array(PackItemRef).max(100).optional().openapi({
      description: "Edited items to replace with the pack's version anyway",
    }),
    confirm_reach: z.boolean().optional().openapi({
      description: "Required when the update reaches further (new hosts, secrets or servers)",
    }),
    secrets: z.record(z.string(), z.string().max(10_000)).optional(),
    settings: z.record(z.string(), z.string().max(500)).optional(),
  })
  .openapi("UpdatePackRequest");

export const ExportPackRequest = z
  .object({
    name: z.string().trim().min(1).max(64),
    summary: z.string().trim().min(1).max(160),
    description: z.string().max(300).optional(),
    icon: z.string().max(40).optional(),
    bot_ids: z.array(Uuid).max(5),
    workspace_skill_ids: z.array(Uuid).max(30).optional(),
    look: z
      .object({
        type: z.enum(["theme", "scheme", "wallpaper"]),
        name: z.string().min(1).max(60),
        document: z.record(z.string(), z.unknown()),
      })
      .optional()
      .openapi({ description: "This device's look, from the app" }),
  })
  .openapi("ExportPackRequest");

export const PackExportFile = z
  .object({
    path: z.string(),
    text: z.string().nullable(),
    base64: z.string().nullable(),
    executable: z.boolean(),
  })
  .openapi("PackExportFile");

export const SecretFinding = z
  .object({ path: z.string(), line: z.number().int(), what: z.string() })
  .openapi("PackSecretFinding");

export const PackExport = z
  .object({
    name: z.string(),
    files: z.array(PackExportFile),
    findings: z.array(SecretFinding).openapi({
      description: "Lines that look like keys: fix them before sharing",
    }),
  })
  .openapi("PackExport");

export const SharePackRequest = ExportPackRequest.extend({
  ignore_findings: z.boolean().optional().openapi({
    description: "Share even though lines look like keys (after checking them)",
  }),
}).openapi("SharePackRequest");

export const PackShare = z
  .object({
    id: Uuid,
    url: z.string(),
    token: z.string(),
    expires_at: ts,
    findings: z.array(SecretFinding),
  })
  .openapi("PackShare");

export const PackShareView = z
  .object({ id: Uuid, preview: PackPreview, expires_at: ts })
  .openapi("PackShareView");

export const GalleryPack = z
  .object({
    kind: z.enum(["set", "pack"]),
    id: z.string(),
    name: z.string(),
    summary: z.string(),
    icon: z.string(),
    author: z.object({
      name: z.string(),
      url: z.string().optional(),
      handle: z.string().optional(),
    }),
    featured: z.boolean(),
    reviewed: z.boolean(),
    url: z.string().nullable(),
    commit: z.string().nullable(),
    contents: z
      .object({
        bots: z.number().int(),
        skills: z.number().int(),
        routines: z.number().int(),
        apps: z.number().int(),
        looks: z.number().int(),
        tools: z.number().int(),
      })
      .nullable(),
    set_items: z.array(z.object({ type: z.string(), id: z.string() })).nullable(),
    tags: z.array(z.string()),
  })
  .openapi("GalleryPack");

export const GalleryPackList = z.object({ items: z.array(GalleryPack) }).openapi("GalleryPackList");
