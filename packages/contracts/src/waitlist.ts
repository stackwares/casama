import { z } from "@hono/zod-openapi";

/** The waitlist and invite gate for Casama Cloud: see routes/waitlist.ts. */

/** A solved GET /v1/signup/challenge puzzle (D-094), good once. */
export const WaitlistProof = z
  .object({ challenge: z.string().min(1).max(300), nonce: z.string().min(1).max(64) })
  .openapi("WaitlistProof");

export const JoinWaitlistRequest = z
  .object({
    email: z.string().min(3).max(254),
    proof: WaitlistProof,
    /** The page or app the form was on (home, pricing, app_ios…). */
    source: z.string().max(64).optional(),
    /** A campaign tag from the link that brought the person. */
    ref: z.string().max(64).optional(),
    /** One optional line: what they would have a bot do first. */
    note: z.string().max(280).optional(),
    /** They run Casama on their own server (and want an account for Casama Link). */
    self_hosting: z.boolean().optional(),
    /** A yes to Casama's monthly email, applied when they first sign in. Never assumed. */
    newsletter: z.boolean().optional(),
  })
  .openapi("JoinWaitlistRequest");

/** The same answer for a new address, one already waiting, one already in and one with an account. */
export const WaitlistJoined = z.object({ ok: z.literal(true) }).openapi("WaitlistJoined");

export const RedeemInviteRequest = z
  .object({
    email: z.string().min(3).max(254),
    /** A member's code, a campaign code, or the invite link itself. */
    code: z.string().min(1).max(200),
    proof: WaitlistProof,
    source: z.string().max(64).optional(),
    newsletter: z.boolean().optional(),
  })
  .openapi("RedeemInviteRequest");

export const InviteRedeemed = z
  .object({
    /**
     * admitted: this address can sign up now. waitlisted: the code is real but has no invite
     * left, so the address is on the waitlist, ahead of the people without one.
     */
    outcome: z.enum(["admitted", "waitlisted"]),
    kind: z.enum(["personal", "campaign"]),
  })
  .openapi("InviteRedeemed");

export const InviteCodePreview = z
  .object({
    kind: z.enum(["personal", "campaign"]),
    /** A campaign's name. */
    label: z.string().nullable(),
    /** The inviting member's first name, when they set one. */
    inviter_name: z.string().nullable(),
    /** Whether the code can still let someone in. */
    available: z.boolean(),
    /** What the friend gets for joining with a member's code (after a first chat), in US dollars. */
    welcome_usd: z.number(),
  })
  .openapi("InviteCodePreview");

export const LeaveWaitlistRequest = z
  .object({ token: z.string().min(10).max(200) })
  .openapi("LeaveWaitlistRequest");

// --- owner ---------------------------------------------------------------------------------------

export const SignupGate = z
  .object({
    /** open: anyone can sign up. invite_only: only addresses that were let in. */
    mode: z.enum(["open", "invite_only"]),
    /** From this moment the gate counts as open, whatever `mode` says. */
    opens_at: z.iso.datetime().nullable(),
    /** Invites each member has once they've finished a first chat. */
    invites_per_person: z.number().int().min(0).max(100),
    /** People the daily automatic batch lets in; 0: none. */
    daily_admit: z.number().int().min(0).max(10_000),
    /** "You're in" emails a day at most. */
    daily_emails_max: z.number().int().min(0).max(100_000),
  })
  .openapi("SignupGate");

export const SetSignupGateRequest = SignupGate.partial().openapi("SetSignupGateRequest");

export const SignupGateState = z
  .object({
    gate: SignupGate,
    /** Whether new accounts are by invitation at this moment (mode and opens_at together). */
    closed: z.boolean(),
  })
  .openapi("SignupGateState");

const Funnel = z.object({
  key: z.string(),
  listed: z.number().int(),
  admitted: z.number().int(),
  joined: z.number().int(),
  first_chat: z.number().int(),
});

export const WaitlistStats = z
  .object({
    /** On the list, not yet chosen. */
    waiting: z.number().int(),
    /** Chosen; their "You're in" email is on its way. */
    queued: z.number().int(),
    /** Let in (whether or not they signed up yet). */
    admitted: z.number().int(),
    /** Made an account. */
    joined: z.number().int(),
    /** Finished a first chat. */
    first_chat: z.number().int(),
    listed_today: z.number().int(),
    admitted_today: z.number().int(),
    emails_today: z.number().int(),
    /** By the page or app people joined from. */
    by_source: z.array(Funnel),
    /** By how people got in: batch, auto, admin, invite, campaign:<code>, or still waiting. */
    by_via: z.array(Funnel),
  })
  .openapi("WaitlistStats");

export const WaitlistEntry = z
  .object({
    id: z.uuid(),
    email: z.string(),
    status: z.enum(["waiting", "queued", "admitted", "joined"]),
    source: z.string().nullable(),
    ref: z.string().nullable(),
    self_hosting: z.boolean(),
    note: z.string().nullable(),
    priority: z.number().int(),
    invite_code: z.string().nullable(),
    admitted_via: z.string().nullable(),
    admitted_at: z.iso.datetime().nullable(),
    joined_at: z.iso.datetime().nullable(),
    created_at: z.iso.datetime(),
  })
  .openapi("WaitlistEntry");

export const WaitlistPage = z
  .object({ stats: WaitlistStats, gate: SignupGateState, items: z.array(WaitlistEntry) })
  .openapi("WaitlistPage");

export const WaitlistQuery = z.object({
  status: z.enum(["waiting", "queued", "admitted", "joined"]).optional(),
  source: z.string().max(64).optional(),
  ref: z.string().max(64).optional(),
  self_hosting: z.enum(["true", "false"]).optional(),
  q: z.string().max(100).optional(),
  limit: z.coerce.number().int().min(1).max(200).optional(),
  offset: z.coerce.number().int().min(0).optional(),
});

export const AdmitWaitlistRequest = z
  .object({
    /** These entries… */
    ids: z.array(z.uuid()).max(500).optional(),
    /** …or the next `count` in batch order, within the filter. */
    count: z.number().int().min(1).max(5000).optional(),
    source: z.string().max(64).optional(),
    ref: z.string().max(64).optional(),
    self_hosting: z.boolean().optional(),
  })
  .openapi("AdmitWaitlistRequest");

export const AddWaitlistEntriesRequest = z
  .object({
    emails: z.array(z.string().min(3).max(254)).min(1).max(500),
    /** true: they get the "You're in" email. false (default): let in at once, nobody is emailed. */
    notify: z.boolean().optional(),
  })
  .openapi("AddWaitlistEntriesRequest");

export const WaitlistChanged = z
  .object({
    /** How many people this let in or chose. */
    count: z.number().int(),
    /** Addresses that couldn't be read as an email address. */
    skipped: z.array(z.string()).optional(),
  })
  .openapi("WaitlistChanged");

export const InviteCampaign = z
  .object({
    code: z.string(),
    label: z.string(),
    max_uses: z.number().int(),
    used: z.number().int(),
    per_day: z.number().int().nullable(),
    starts_at: z.iso.datetime().nullable(),
    expires_at: z.iso.datetime().nullable(),
    disabled: z.boolean(),
    created_at: z.iso.datetime(),
    /** The link to share. */
    link: z.string(),
  })
  .openapi("InviteCampaign");

export const InviteCampaignList = z
  .object({ items: z.array(InviteCampaign) })
  .openapi("InviteCampaignList");

export const CreateInviteCampaignRequest = z
  .object({
    /** 9 or more characters, or with a hyphen: letters, digits and hyphens (SHOWHN-DEC8). */
    code: z.string().min(4).max(32),
    label: z.string().min(1).max(80),
    max_uses: z.number().int().min(0).max(1_000_000),
    per_day: z.number().int().min(1).max(1_000_000).nullable().optional(),
    starts_at: z.iso.datetime().nullable().optional(),
    expires_at: z.iso.datetime().nullable().optional(),
  })
  .openapi("CreateInviteCampaignRequest");

export const UpdateInviteCampaignRequest = z
  .object({
    label: z.string().min(1).max(80).optional(),
    max_uses: z.number().int().min(0).max(1_000_000).optional(),
    per_day: z.number().int().min(1).max(1_000_000).nullable().optional(),
    starts_at: z.iso.datetime().nullable().optional(),
    expires_at: z.iso.datetime().nullable().optional(),
    disabled: z.boolean().optional(),
  })
  .openapi("UpdateInviteCampaignRequest");
