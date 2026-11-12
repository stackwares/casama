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
    /** link: a long token in a URL; code: a short code to type, valid for 48 hours (D-167). */
    kind: z.enum(["link", "code"]).optional(),
    /** People who use it ask to join and an admin approves. */
    requires_approval: z.boolean().optional(),
    /** The workspace's standing link, which admins can copy again. */
    is_default: z.boolean().optional(),
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
    requires_approval: z.boolean().optional(),
  })
  .openapi("CreateInviteLinkRequest");

export const UpdateDefaultInviteRequest = z
  .object({
    requires_approval: z.boolean().optional(),
    /** Revoke the standing link and make a new one. */
    reset: z.boolean().optional(),
  })
  .openapi("UpdateDefaultInviteRequest");

export const CreateInviteCodeRequest = z
  .object({ role: z.enum(["admin", "member"]).optional() })
  .openapi("CreateInviteCodeRequest");

export const InvitePreview = z
  .object({
    kind: z.enum(["link", "code", "email"]),
    workspace: z.object({
      name: z.string(),
      icon: z.string().nullable(),
      color: z.string().nullable(),
      member_count: z.number().int(),
    }),
    role: z.enum(["owner", "admin", "member"]),
    inviter_name: z.string().nullable(),
    requires_approval: z.boolean(),
    /** For an email invite: the address it was sent to, partly hidden (a•••@example.com). */
    email_hint: z.string().nullable(),
    /** Only when signed in. */
    already_member: z.boolean().nullable(),
  })
  .openapi("InvitePreview");

export const JoinRequestBody = z
  .object({
    invite: z.string().trim().min(6).max(512).openapi({
      description: "An invite link, its token, an email invite token, or a short invite code",
    }),
  })
  .openapi("JoinRequestBody");

export const JoinRequest = z
  .object({
    id: Uuid,
    org_id: Uuid,
    user_id: Uuid,
    email: z.string().nullable(),
    display_name: z.string().nullable(),
    role: z.enum(["admin", "member"]),
    status: z.enum(["pending", "approved", "declined"]),
    created_at: z.iso.datetime({ offset: true }),
  })
  .openapi("JoinRequest");

export const DecideJoinRequest = z.object({ approve: z.boolean() }).openapi("DecideJoinRequest");

export const PendingInvite = z
  .object({
    id: Uuid,
    email: z.string(),
    role: z.enum(["owner", "admin", "member"]),
    expires_at: z.iso.datetime({ offset: true }),
    created_at: z.iso.datetime({ offset: true }),
  })
  .openapi("PendingInvite");

export const CreateInvitesRequest = z
  .object({
    emails: z.array(z.email()).min(1).max(50),
    role: z.enum(["admin", "member"]).optional(),
  })
  .openapi("CreateInvitesRequest");

export const JoinDomains = z
  .object({
    items: z.array(z.string()),
    /** The admin's own verified email domain, if they have one. */
    my_domain: z.string().nullable(),
    /** Whether my_domain can be used (verified, and not a shared domain such as gmail.com). */
    can_use: z.boolean(),
  })
  .openapi("JoinDomains");

export const SetJoinDomainRequest = z
  .object({
    enabled: z.boolean(),
    /** When turning off: the domain to remove (defaults to your own). */
    domain: z.string().max(253).optional(),
  })
  .openapi("SetJoinDomainRequest");

export const JoinableWorkspace = z
  .object({
    id: Uuid,
    name: z.string(),
    icon: z.string().nullable(),
    color: z.string().nullable(),
    member_count: z.number().int(),
    domain: z.string(),
  })
  .openapi("JoinableWorkspace");

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
    description: "Suspended by the instance owner: bots don't run and computers don't start",
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
    /** Where a run's trace opens, with {trace_id} in it (Grafana, Jaeger, Honeycomb…; D-107). */
    trace_url_template: z.string().nullable().optional(),
    /**
     * Google client ids Auth accepts in an ID token (D-217). The apps sign in with Google's own
     * sheet only when their client id is listed here. Empty: Continue with Google opens the browser.
     */
    google_client_ids: z.array(z.string()).optional(),
  })
  .openapi("PublicConfig");

export const JoinResult = z
  .object({
    /** joined: now a member; member: already one; requested: waiting for an admin. */
    status: z.enum(["joined", "member", "requested"]),
    /** Set when joined or already a member. */
    organization: OrganizationWithRole.optional(),
    workspace_name: z.string(),
  })
  .openapi("JoinResult");
