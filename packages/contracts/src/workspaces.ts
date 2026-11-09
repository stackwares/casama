import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";

export const OrgRole = z.enum(["owner", "admin", "member"]).openapi("OrgRole");
export type OrgRole = z.infer<typeof OrgRole>;

export const InviteRole = z.enum(["admin", "member"]).openapi("InviteRole");

export const Organization = z
  .object({
    id: Uuid,
    name: z.string(),
    slug: z.string(),
    plan: z.string(),
    region: z.string(),
    created_at: z.iso.datetime({ offset: true }),
  })
  .openapi("Organization");
export type Organization = z.infer<typeof Organization>;

export const OrganizationWithRole = Organization.extend({ role: OrgRole }).openapi(
  "OrganizationWithRole",
);

export const CreateOrganizationRequest = z
  .object({
    name: z.string().trim().min(1).max(120),
    slug: z
      .string()
      .regex(/^[a-z0-9](?:[a-z0-9-]{0,46}[a-z0-9])?$/)
      .optional()
      .openapi({ description: "Generated from the name when omitted" }),
  })
  .openapi("CreateOrganizationRequest");

export const CreateInviteRequest = z
  .object({
    email: z.email(),
    role: InviteRole.optional().openapi({ description: "Defaults to member" }),
  })
  .openapi("CreateInviteRequest");

export const Invite = z
  .object({
    id: Uuid,
    org_id: Uuid,
    email: z.string(),
    role: OrgRole,
    expires_at: z.iso.datetime({ offset: true }),
    email_sent: z.boolean(),
    accept_token: z.string().optional().openapi({
      description:
        "Returned only when no email provider is configured, so the inviter can share it directly",
    }),
  })
  .openapi("Invite");

export const Membership = z
  .object({
    id: Uuid,
    org_id: Uuid,
    user_id: Uuid,
    role: OrgRole,
    created_at: z.iso.datetime({ offset: true }),
  })
  .openapi("Membership");

export const Me = z
  .object({
    user_id: Uuid,
    email: z.string().nullable(),
    display_name: z.string().nullable(),
    locale: z.string(),
    timezone: z.string(),
    organizations: z.array(OrganizationWithRole),
  })
  .openapi("Me");

export const PublicConfig = z
  .object({
    product_name: z.string(),
    api_version: z.string(),
    supabase_url: z.string(),
    supabase_anon_key: z.string(),
    billing_enabled: z.boolean(),
    default_models: z
      .record(z.string(), z.string())
      .openapi({ description: "Default model id per provider (for example openrouter, openai)" }),
    default_reasoning_effort: z.enum(["none", "low", "medium", "high", "xhigh", "max"]),
  })
  .openapi("PublicConfig");
