import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";

const ts = z.iso.datetime({ offset: true });

/** What drives the viewer and the filter (docs/LIBRARY-PLAN.md §4). */
export const CreationKind = z
  .enum(["page", "image", "video", "audio", "document", "file"])
  .openapi("CreationKind");

/** One thing a bot made (D-274). */
export const Creation = z
  .object({
    id: Uuid,
    org_id: Uuid,
    bot_id: Uuid.nullable(),
    bot_name: z.string().nullable(),
    made_for: Uuid.nullable(),
    conversation_id: Uuid.nullable(),
    run_id: Uuid.nullable(),
    kind: CreationKind,
    label: z
      .string()
      .nullable()
      .openapi({ description: "The bot's word for it: Site, Game, Report…" }),
    title: z.string(),
    page_id: Uuid.nullable(),
    media_id: Uuid.nullable(),
    mime: z.string().nullable(),
    size: z.number().int(),
    width: z.number().int().nullable(),
    height: z.number().int().nullable(),
    duration_s: z.number().nullable(),
    has_cover: z.boolean().openapi({
      description: "GET /v1/creations/{id}/cover returns a picture; otherwise the app draws one",
    }),
    has_preview: z.boolean().openapi({
      description: "GET /v1/creations/{id}/preview returns a PDF of it (documents; D-280)",
    }),
    version: z.number().int(),
    visibility: z.enum(["private", "workspace", "public"]).openapi({
      description: "Who can open it (D-281); a page's follows the page",
    }),
    pinned: z.boolean().openapi({ description: "Pinned by the person asking" }),
    last_opened_at: ts.nullable(),
    can_change: z.boolean(),
    public_url: z.string().nullable().optional().openapi({
      description: "The public link, only in the answer that made it public (D-281)",
    }),
    deleted_at: ts.nullable(),
    created_at: ts,
    updated_at: ts,
  })
  .openapi("Creation");

export const CreationList = z
  .object({
    items: z.array(Creation),
    next_cursor: z.string().nullable().openapi({ description: "Pass back as cursor for more" }),
    kinds: z
      .array(CreationKind)
      .openapi({ description: "The kinds this workspace has, for filter chips" }),
  })
  .openapi("CreationList");

export const CreationDetail = Creation.extend({
  siblings: z
    .array(Creation)
    .openapi({ description: "Other things the same run made, newest first" }),
}).openapi("CreationDetail");

export const UpdateCreationRequest = z
  .object({
    title: z.string().trim().min(1).max(200).optional(),
    label: z.string().trim().min(1).max(24).nullable().optional(),
    pinned: z.boolean().optional(),
    opened: z
      .literal(true)
      .optional()
      .openapi({ description: "Marks it opened now (Recently opened)" }),
    visibility: z.enum(["private", "workspace", "public"]).optional().openapi({
      description: "Making it public returns public_url once; public again gives a new link",
    }),
    expires_in_days: z.number().int().min(1).max(365).optional(),
  })
  .openapi("UpdateCreationRequest");

export const CreationListQuery = z.object({
  org_id: Uuid,
  kind: CreationKind.optional(),
  bot_id: Uuid.optional(),
  conversation_id: Uuid.optional(),
  project_id: Uuid.optional(),
  pinned: z.enum(["true", "false"]).optional(),
  sort: z
    .enum(["new", "opened"])
    .optional()
    .openapi({ description: "new (default) or recently opened" }),
  deleted: z
    .enum(["true", "false"])
    .optional()
    .openapi({ description: "true lists what was deleted in the last 30 days (for Undo)" }),
  q: z.string().trim().max(200).optional(),
  cursor: z.string().max(200).optional(),
  limit: z.coerce.number().int().min(1).max(100).optional(),
});
