import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";

const ts = z.iso.datetime({ offset: true });

const Author = z
  .object({
    name: z.string(),
    url: z.string().optional(),
    handle: z
      .string()
      .optional()
      .openapi({ description: "Stable author id for author pages (D-315)" }),
  })
  .openapi("GalleryAuthor");

/** Every kind of gallery item a workspace or device can add (D-315). */
export const GalleryKind = z
  .enum(["theme", "scheme", "wallpaper", "skill", "app", "bot", "routine", "plugin"])
  .openapi("GalleryKind");

/** Every kind a gallery list can carry (`kinds=all`), starter sets included. */
export const GalleryAnyKind = z
  .enum(["theme", "scheme", "wallpaper", "skill", "app", "bot", "routine", "plugin", "set"])
  .openapi("GalleryAnyKind");

/** The kinds a workspace installs; looks stay on the device. */
export const GalleryWorkspaceKind = z
  .enum(["skill", "app", "bot", "routine", "plugin"])
  .openapi("GalleryWorkspaceKind");

export const GalleryChange = z
  .object({
    version: z.number().int(),
    date: z.string(),
    note: z.string(),
    breaking: z.boolean().optional(),
  })
  .openapi("GalleryChange");

export const GalleryAccess = z
  .object({
    reads: z.array(z.string()).optional(),
    writes: z.array(z.string()).optional(),
    runs_code: z.boolean().optional(),
    computer: z.boolean().optional(),
    credits: z.enum(["none", "low", "medium", "high"]).optional(),
  })
  .openapi("GalleryAccess", { description: "What an item can touch, in plain words" });

export const GalleryNeeds = z
  .object({
    apps: z.array(z.string()).optional(),
    skills: z.array(z.string()).optional(),
  })
  .openapi("GalleryNeeds");

export const GalleryInput = z
  .object({
    key: z.string(),
    label: z.string(),
    type: z.enum(["text", "choice", "time", "timezone"]),
    default: z.string().optional(),
    options: z.array(z.string()).optional(),
    help: z.string().optional(),
  })
  .openapi("GalleryInput", { description: "A question asked when a routine or bot is added" });

export const GalleryRef = z
  .object({ type: z.string(), id: z.string() })
  .openapi("GalleryRef", { description: "Another gallery item" });

export const GalleryStats = z
  .object({
    installers: z.number().int().optional(),
    trending: z.number().int().optional().openapi({ description: "New installers this week" }),
    active: z.number().int().optional().openapi({ description: "People who used it in 14 days" }),
    success: z
      .number()
      .optional()
      .openapi({ description: "Share of runs that finished, 0 to 1 (last 30 days)" }),
  })
  .openapi("GalleryStats", {
    description:
      "Aggregate use. Numbers are left out under 10 installers; success under 20 runs (D-315).",
  });

/** The gallery v2 fields every item kind may carry (D-315). All optional for older catalogs. */
export const galleryExtras = {
  added: z.string().optional().openapi({ description: "YYYY-MM-DD the item was added" }),
  updated: z.string().optional(),
  changelog: z.array(GalleryChange).optional(),
  pick: z.string().optional().openapi({ description: "Why a featured item is a pick" }),
  examples: z.array(z.string()).optional(),
  access: GalleryAccess.optional(),
  needs: GalleryNeeds.optional(),
  inputs: z.array(GalleryInput).optional(),
  remix_of: GalleryRef.optional(),
  replaced_by: GalleryRef.optional(),
  min_app: z.string().optional(),
  min_server: z.string().optional(),
  season: z.object({ from: z.string(), to: z.string() }).optional(),
  tested: z.object({ version: z.number().int(), date: z.string() }).optional(),
  source: z.string().optional().openapi({
    description: "The extra catalog it came from (GALLERY_SOURCES); ids are source:id",
  }),
  stats: GalleryStats.optional(),
  template: z.record(z.string(), z.unknown()).optional().openapi({
    description:
      "Routines and bots with install questions: the raw fields with {{key}} placeholders (document has the defaults filled)",
  }),
};

export const GalleryItem = z
  .object({
    id: z.string(),
    type: GalleryAnyKind.openapi({
      description:
        "Looks and skills; with kinds=all also app, bot, routine, plugin and set (D-315)",
    }),
    name: z.string(),
    author: Author,
    license: z.string(),
    tags: z.array(z.string()),
    featured: z.boolean(),
    retired: z.boolean(),
    version: z.number().int(),
    sha256: z.string(),
    category: z.string().optional(),
    icon: z.string().optional().openapi({ description: "A skill's Lucide icon name." }),
    description: z.string().optional().openapi({ description: "A skill's one-line description." }),
    requires: z.array(z.string()).optional().openapi({
      description:
        "Features the look needs from the app (doodles, mesh, scheme-colors). Apps hide items that need something they can't draw.",
    }),
    document: z.record(z.string(), z.unknown()).optional().openapi({
      description:
        "A theme, scheme or wallpaper document, so a list can draw previews without fetching each item; an app, bot, routine or plugin entry; a set's set.json (items).",
    }),
    files: z.array(z.string()),
    ...galleryExtras,
  })
  .openapi("GalleryItem");

export const GalleryList = z
  .object({
    available: z.boolean().openapi({
      description: "False when the gallery host could not be read. Built-in looks still apply.",
    }),
    items: z.array(GalleryItem),
  })
  .openapi("GalleryList");

export const GalleryDetail = GalleryItem.extend({
  document: z.record(z.string(), z.unknown()).nullable(),
  skill_md: z.string().nullable(),
}).openapi("GalleryDetail");

// ---------------------------------------------------------------- stats (public)

export const GalleryStatsList = z
  .object({ items: z.record(z.string(), GalleryStats) })
  .openapi("GalleryStatsList", { description: 'Stats by item key, "<type>/<id>"' });

// ---------------------------------------------------------------- starter sets and authors

export const GallerySet = z
  .object({
    id: z.string(),
    name: z.string(),
    description: z.string(),
    icon: z.string(),
    author: Author,
    featured: z.boolean(),
    items: z.array(GalleryRef),
    source: z.string().optional(),
    added: z.string().optional(),
  })
  .openapi("GallerySet");

export const GallerySetList = z.object({ items: z.array(GallerySet) }).openapi("GallerySetList");

export const GalleryAuthorProfile = z
  .object({
    handle: z.string(),
    name: z.string(),
    url: z.string().optional(),
    items: z.array(GalleryRef),
  })
  .openapi("GalleryAuthorProfile");

export const GalleryAuthorList = z
  .object({ items: z.array(GalleryAuthorProfile) })
  .openapi("GalleryAuthorList");

// ---------------------------------------------------------------- installed and updates

const AccessDiff = z
  .object({
    reads: z.array(z.string()),
    writes: z.array(z.string()),
    runs_code: z.boolean(),
    computer: z.boolean(),
  })
  .openapi("GalleryAccessDiff", {
    description: "What the newer version can touch that this one can't",
  });

export const GalleryInstalledItem = z
  .object({
    type: GalleryWorkspaceKind,
    id: z.string(),
    name: z.string(),
    installed_version: z.number().int(),
    latest_version: z.number().int().nullable(),
    update: z.boolean(),
    breaking: z.boolean(),
    access_added: AccessDiff,
    retired: z.boolean(),
    replacement: GalleryRef.optional(),
    changelog: z
      .array(GalleryChange)
      .openapi({ description: "Entries newer than the installed one" }),
    installed_at: ts,
    target: z.object({ kind: GalleryWorkspaceKind, id: z.string() }),
  })
  .openapi("GalleryInstalledItem");

export const GalleryInstalledList = z
  .object({ items: z.array(GalleryInstalledItem) })
  .openapi("GalleryInstalledList");

export const GalleryUpdateRequest = z
  .object({
    org_id: Uuid,
    type: GalleryWorkspaceKind,
    id: z.string().min(1).max(100),
    accept_access: z
      .boolean()
      .optional()
      .openapi({ description: "Apply even though the update can touch more or is breaking" }),
  })
  .openapi("GalleryUpdateRequest");

export const GalleryUpdateResult = z
  .object({ updated: z.number().int(), version: z.number().int() })
  .openapi("GalleryUpdateResult");

// ---------------------------------------------------------------- install with needs and inputs

const Missing = z
  .object({
    apps: z.array(z.object({ id: z.string(), name: z.string() })),
    skills: z.array(z.object({ id: z.string(), name: z.string() })),
  })
  .openapi("GalleryMissing", { description: "What still has to be connected or added" });

export const GalleryInstallRequest = z
  .object({
    org_id: Uuid,
    type: GalleryWorkspaceKind,
    id: z.string().min(1).max(100),
    inputs: z.record(z.string(), z.string().max(120)).optional(),
    bot_id: Uuid.optional().openapi({
      description: "The bot a routine, skill or plugin goes to; a routine needs one",
    }),
  })
  .openapi("GalleryInstallRequest");

export const GalleryInstallResult = z
  .object({
    status: z.enum(["installed", "approval_pending"]),
    installed: z.object({ kind: GalleryWorkspaceKind, id: z.string() }).nullable(),
    approval_id: Uuid.nullable(),
    missing: Missing,
  })
  .openapi("GalleryInstallResult");

export const GallerySetInstallRequest = z
  .object({
    org_id: Uuid,
    bot_id: Uuid.optional().openapi({ description: "Where the set's routines go" }),
  })
  .openapi("GallerySetInstallRequest");

export const GallerySetInstallResult = z
  .object({
    items: z.array(
      z.object({
        type: GalleryKind,
        id: z.string(),
        status: z.enum(["installed", "approval_pending", "skipped", "failed", "device"]),
        installed: z.object({ kind: GalleryWorkspaceKind, id: z.string() }).nullable(),
        error: z.string().nullable(),
      }),
    ),
    missing: Missing,
  })
  .openapi("GallerySetInstallResult");

// ---------------------------------------------------------------- workspace controls

export const GalleryPolicy = z
  .object({
    mode: z.enum(["open", "approval", "allowlist"]),
    allow: z.array(z.string().max(120)).max(500),
    block: z.array(z.string().max(120)).max(500),
    approval_for: z.array(z.enum(["runs_code", "apps", "all"])).max(3),
  })
  .openapi("GalleryPolicy", {
    description:
      'Who may add what from the gallery. Item keys are "<type>/<id>". open: anything not blocked; approval: admins approve; allowlist: only listed items.',
  });

export const GalleryApproval = z
  .object({
    id: Uuid,
    org_id: Uuid,
    type: GalleryWorkspaceKind,
    pack: z
      .boolean()
      .optional()
      .openapi({ description: "A pack (shown as a plugin to older apps)" }),
    item_id: z.string(),
    name: z.string(),
    requested_by: Uuid.nullable(),
    requested_by_name: z.string().nullable(),
    reason: z.string(),
    status: z.enum(["pending", "approved", "denied", "failed"]),
    error: z.string().nullable(),
    created_at: ts,
    decided_at: ts.nullable(),
  })
  .openapi("GalleryApproval");

export const GalleryApprovalList = z
  .object({ items: z.array(GalleryApproval) })
  .openapi("GalleryApprovalList");

export const GalleryApprovalDecision = z
  .object({ decision: z.enum(["approved", "denied"]) })
  .openapi("GalleryApprovalDecision");

// ---------------------------------------------------------------- requests board

export const GalleryRequest = z
  .object({
    id: Uuid,
    kind: GalleryKind,
    title: z.string(),
    details: z.string(),
    status: z.enum(["open", "planned", "done", "declined"]),
    done_item_key: z.string().nullable(),
    votes: z.number().int(),
    voted: z.boolean(),
    mine: z.boolean(),
    created_at: ts,
  })
  .openapi("GalleryRequest");

export const GalleryRequestList = z
  .object({ items: z.array(GalleryRequest) })
  .openapi("GalleryRequestList");

export const CreateGalleryRequest = z
  .object({
    kind: GalleryKind,
    title: z.string().trim().min(4).max(80),
    details: z.string().max(500).optional(),
  })
  .openapi("CreateGalleryRequest");

export const UpdateGalleryRequest = z
  .object({
    status: z.enum(["open", "planned", "done", "declined"]),
    done_item_key: z.string().max(120).nullable().optional(),
  })
  .openapi("UpdateGalleryRequest");

// ---------------------------------------------------------------- submissions and author stats

export const GallerySubmissionKind = z
  .enum(["theme", "scheme", "wallpaper", "skill", "routine", "bot"])
  .openapi("GallerySubmissionKind");

export const CreateGallerySubmission = z
  .object({
    type: GallerySubmissionKind,
    id: z
      .string()
      .regex(/^[a-z0-9][a-z0-9-]{0,62}$/)
      .optional()
      .openapi({ description: "Folder name; made from the name when left out" }),
    item: z.record(z.string(), z.unknown()).openapi({ description: "item.json fields" }),
    files: z.record(z.string(), z.string()).openapi({
      description:
        "The item's other files by name: theme.json, scheme.json, wallpaper.json, SKILL.md (plus .md references), routine.json, bot.json",
    }),
    remix_of: GalleryRef.optional(),
  })
  .openapi("CreateGallerySubmission");

export const GallerySubmission = z
  .object({
    id: Uuid,
    type: GallerySubmissionKind,
    item_id: z.string(),
    name: z.string(),
    pr_url: z.string().nullable(),
    status: z.enum(["open", "merged", "closed", "failed"]),
    created_at: ts,
  })
  .openapi("GallerySubmission");

export const GallerySubmissionList = z
  .object({ items: z.array(GallerySubmission) })
  .openapi("GallerySubmissionList");

export const GalleryAuthorItem = z
  .object({
    type: GalleryKind,
    id: z.string(),
    name: z.string(),
    version: z.number().int().nullable(),
    stats: z.object({
      installers: z.number().int(),
      installers_7d: z.number().int(),
      active: z.number().int(),
      runs_ok: z.number().int(),
      runs_total: z.number().int(),
    }),
    reports_open: z.number().int(),
  })
  .openapi("GalleryAuthorItem");

export const GalleryAuthorItemList = z
  .object({ items: z.array(GalleryAuthorItem) })
  .openapi("GalleryAuthorItemList");
