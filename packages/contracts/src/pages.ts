import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";

const ts = z.iso.datetime({ offset: true });

export const Page = z
  .object({
    id: Uuid,
    bot_id: Uuid,
    title: z.string(),
    visibility: z.enum(["private", "workspace", "public"]),
    version: z.number().int(),
    expires_at: ts.nullable(),
    refresh_routine_id: Uuid.nullable(),
    conversation_id: Uuid.nullable(),
    can_manage: z.boolean(),
    updated_at: ts,
    created_at: ts,
  })
  .openapi("BotPage");

export const PageVersion = z
  .object({ version: z.number().int(), created_at: ts })
  .openapi("PageVersion");

export const PageDetail = Page.extend({ versions: z.array(PageVersion) }).openapi("BotPageDetail");

export const PageViewLinkRequest = z
  .object({ format: z.enum(["html", "pdf"]).optional() })
  .openapi("PageViewLinkRequest");

export const PageViewLink = z
  .object({ url: z.url(), expires_at: ts })
  .openapi("PageViewLink");

export const UpdatePageRequest = z
  .object({
    visibility: z.enum(["private", "workspace", "public"]),
    expires_in_days: z.number().int().min(1).max(365).optional(),
  })
  .openapi("UpdatePageRequest");

export const UpdatePageResponse = z
  .object({ page: Page, public_url: z.url().nullable() })
  .openapi("UpdatePageResponse");

export const RevertPageRequest = z
  .object({ version: z.number().int().min(1) })
  .openapi("RevertPageRequest");
