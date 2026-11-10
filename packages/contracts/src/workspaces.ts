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
    /** A Lucide icon name or an emoji (D-099). */
    icon: z.string().nullable().optional(),
    /** #rrggbb */
    color: z.string().nullable().optional(),
    created_at: z.iso.datetime({ offset: true }),
  })
  .openapi("Organization");

export const UpdateOrganizationRequest = z
  .object({
    name: z.string().trim().min(1).max(120).optional(),
    icon: z.string().max(40).nullable().optional(),
    color: z
      .string()
      .regex(/^#[0-9a-fA-F]{6}$/)
      .nullable()
      .optional(),
  })
  .openapi("UpdateOrganizationRequest");

export const InviteLink = z
  .object({
    id: Uuid,
    org_id: Uuid,
    role: z.enum(["admin", "member"]),
    token_hint: z.string(),
    expires_at: z.iso.datetime({ offset: true }).nullable(),
    max_uses: z.number().int().nullable(),
    uses: z.number().int(),
    revoked_at: z.iso.datetime({ offset: true }).nullable(),
    created_at: z.iso.datetime({ offset: true }),
  })
  .openapi("InviteLink");

export const CreatedInviteLink = InviteLink.extend({
  token: z.string().openapi({ description: "Shown once" }),
  url: z.string().openapi({ description: "The link to share (the app's /join/<token>)" }),
}).openapi("CreatedInviteLink");

export const CreateInviteLinkRequest = z
  .object({
    role: z.enum(["admin", "member"]).optional(),
    expires_in_days: z.number().int().min(1).max(365).optional(),
    max_uses: z.number().int().min(1).max(10000).optional(),
  })
  .openapi("CreateInviteLinkRequest");

export const WorkspaceBadge = z
  .object({ org_id: Uuid, approvals: z.number().int(), unread: z.number().int() })
  .openapi("WorkspaceBadge");
export type Organization = z.infer<typeof Organization>;

export const OrganizationWithRole = Organization.extend({
  role: OrgRole,
  require_mfa: z.boolean().optional().openapi({
    description: "Owners and admins need two-step sign-in (an aal2 session) to use their powers",
  }),
  suspended: z.boolean().optional().openapi({
    description:
      "Suspended by the instance owner: bots don't run and computers don't start (D-094)",
  }),
}).openapi("OrganizationWithRole");

export const SignupChallenge = z
  .object({
    challenge: z.string(),
    difficulty: z.number().int().openapi({
      description:
        "Find a nonce so that sha256(`<challenge>:<nonce>`) starts with this many zero bits",
    }),
    expires_at: z.string(),
  })
  .openapi("SignupChallenge");

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
    /** Whether the server can search wallpaper photos (UNSPLASH_ACCESS_KEY set). */
    wallpapers_enabled: z.boolean().optional(),
    /** Whether people can connect a ChatGPT plan here (desktop app and CLI sign-in). */
    chatgpt_sign_in: z.boolean().optional(),
    /**
     * Proofs a new account must carry in its user metadata (`signup_proof`), D-094. Empty: none.
     * app_check: a Firebase App Check token; pow: a solved GET /v1/signup/challenge puzzle.
     */
    signup_proofs: z.array(z.enum(["app_check", "pow"])).optional(),
  })
  .openapi("PublicConfig");
