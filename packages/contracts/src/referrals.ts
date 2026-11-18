import { z } from "@hono/zod-openapi";

/** Invite friends (D-211): see routes/referrals.ts. */
export const Referral = z
  .object({
    /** Off on this server (self-hosted, or turned off): the app hides Invite friends. */
    enabled: z.boolean(),
    /** Your invite code (6 characters), made on first use. Null when off. */
    code: z.string().nullable(),
    /** Your invite link (casama.ai/i/<code>). Null when off. */
    link: z.string().nullable(),
    /** Free usage, in US dollars of credits, you earn per friend; 0 when there's no reward. */
    reward_usd: z.number(),
    /** The welcome bonus a friend gets with your code, in US dollars of credits; 0 when none. */
    welcome_usd: z.number(),
    /** How many friends can earn you a reward. */
    reward_cap: z.number().int(),
    /** Friends who entered your code. */
    invited: z.number().int(),
    /** Friends who earned you a reward so far. */
    rewarded: z.number().int(),
    /** Friends who entered your code but haven't finished their first chat yet. */
    pending: z.number().int(),
    /** Credits you've earned from invites, in US dollars. */
    earned_usd: z.number(),
    /**
     * Who invited you, when you entered someone's code, and your welcome bonus: what you got
     * (`welcome_earned_usd`), or null while it waits for your first chat.
     */
    invited_by: z
      .object({ name: z.string().nullable(), welcome_earned_usd: z.number().nullable() })
      .nullable(),
    /** Until when you can still enter a friend's code; null when you can't (any more). */
    redeem_until: z.iso.datetime().nullable(),
  })
  .openapi("Referral");

export const RedeemReferralRequest = z
  .object({ code: z.string().min(1).max(200) })
  .openapi("RedeemReferralRequest");

export const ReferralPreview = z
  .object({
    /** The inviter's first name, when they set one. */
    inviter_name: z.string().nullable(),
    reward_usd: z.number(),
    /** What a new person gets for signing up with this code (after a first chat). */
    welcome_usd: z.number(),
  })
  .openapi("ReferralPreview");
