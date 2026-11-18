import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";

const ts = z.iso.datetime({ offset: true });

/** What can be reported from inside the app (D-301). Public links have their own form (D-281). */
export const ReportTargetKind = z
  .enum(["gallery_item", "bot", "message", "user", "workspace"])
  .openapi("ReportTargetKind");

/**
 * What a report may point at. Requests on the gallery's board (D-315) can be reported too; the
 * owners' queue shows them as gallery items (`request/<id>`), so older apps read every report.
 * A shared pack link (`pack_share`, by the share's id) shows as `pack_share/<id>` the same way.
 */
export const ReportTarget = z
  .enum(["gallery_item", "gallery_request", "pack_share", "bot", "message", "user", "workspace"])
  .openapi("ReportTarget");

export const ReportReason = z
  .enum(["spam", "sexual", "violence", "harassment", "illegal", "impersonation", "other"])
  .openapi("ReportReason");

export const CreateReportRequest = z
  .object({
    target_kind: ReportTarget,
    target_id: z.string().min(1).max(200),
    reason: ReportReason,
    note: z.string().max(2000).optional(),
  })
  .openapi("CreateReportRequest");

export const ReportReceipt = z.object({ id: Uuid }).openapi("ReportReceipt");

export const BlockedPerson = z
  .object({ user_id: Uuid, name: z.string(), blocked_at: ts })
  .openapi("BlockedPerson");

export const BlockRequest = z.object({ user_id: Uuid }).openapi("BlockRequest");

/** A report in the instance owners' queue. */
export const ContentReport = z
  .object({
    id: Uuid,
    target_kind: ReportTargetKind,
    target_id: z.string(),
    target_org_id: Uuid.nullable(),
    target_org_name: z.string().nullable(),
    reason: ReportReason,
    note: z.string().nullable(),
    snapshot: z.string().nullable(),
    reporter_email: z.string().nullable(),
    /** Open reports about the same thing, this one included. */
    same_target: z.number().int(),
    status: z.enum(["open", "actioned", "dismissed"]),
    created_at: ts,
  })
  .openapi("ContentReport");

export const ReviewReportRequest = z
  .object({
    decision: z.enum(["actioned", "dismissed"]),
    /** Also suspend the workspace the content belongs to. */
    suspend_workspace: z.boolean().optional(),
  })
  .openapi("ReviewReportRequest");

/** Account emails (D-302): tips and news can be turned off; billing and security emails can't. */
export const EmailPreferences = z
  .object({
    tips: z.boolean(),
    gallery_digest: z.boolean().optional().openapi({
      description: "Monthly gallery picks by email (opt-in, D-315)",
    }),
  })
  .openapi("EmailPreferences");

/**
 * Casama's monthly email (D-408): what's new and what's next, once a month at most. Opt-in, off
 * by default; only on servers that send it (Casama Cloud).
 */
export const NewsletterStatus = z
  .object({
    /** Whether this server sends it. False: the app hides the switch. */
    available: z.boolean(),
    subscribed: z.boolean(),
    /** The app already asked (the sign-up box or the one-time card), so the card stays away. */
    asked: z.boolean(),
  })
  .openapi("NewsletterStatus");

export const SetNewsletterRequest = z
  .object({
    /** Left out: only records that the app asked (the card was closed without an answer). */
    subscribed: z.boolean().optional(),
    /** Where the choice was made (default settings). */
    from: z.enum(["settings", "signup", "card"]).optional(),
  })
  .openapi("SetNewsletterRequest");
