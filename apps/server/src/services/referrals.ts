/**
 * Invite friends (D-211). Anyone can sign up; each person has one invite code and link, and the
 * person who invited a friend earns free credits once the friend is real (a verified address and a
 * first finished run). The worker decides rewards every minute through `worker_reward_referrals`.
 */
import { randomInt } from "node:crypto";
import { track } from "@casama/agent";
import type { Database } from "@casama/db";
import { deterministicUuid } from "@casama/observability";
import { sql } from "drizzle-orm";
import type { Env } from "../env.ts";

export type ReferralConfig = {
  enabled: boolean;
  rewardUsd: number;
  /** The new person's welcome bonus. */
  welcomeUsd: number;
  cap: number;
  redeemDays: number;
  linkBase: string;
};

export function referralConfig(
  env: Pick<
    Env,
    | "REFERRALS"
    | "BILLING_ENABLED"
    | "REFERRAL_REWARD_USD"
    | "REFERRAL_WELCOME_USD"
    | "REFERRAL_REWARD_CAP"
    | "REFERRAL_REDEEM_DAYS"
    | "REFERRAL_LINK_BASE"
  >,
): ReferralConfig {
  const enabled = env.REFERRALS === "on" || (env.REFERRALS === "auto" && env.BILLING_ENABLED);
  return {
    enabled,
    // Credits only mean something where billing runs.
    rewardUsd: env.BILLING_ENABLED ? env.REFERRAL_REWARD_USD : 0,
    welcomeUsd: env.BILLING_ENABLED ? env.REFERRAL_WELCOME_USD : 0,
    cap: env.REFERRAL_REWARD_CAP,
    redeemDays: env.REFERRAL_REDEEM_DAYS,
    linkBase: env.REFERRAL_LINK_BASE.replace(/\/+$/, ""),
  };
}

/** Crockford base32, as for workspace codes (D-167); 6 characters so the two can't be confused. */
const ALPHABET = "0123456789ABCDEFGHJKMNPQRSTVWXYZ";
export const REFERRAL_CODE_LENGTH = 6;

export function newReferralCode() {
  let s = "";
  for (let i = 0; i < REFERRAL_CODE_LENGTH; i++) s += ALPHABET[randomInt(ALPHABET.length)];
  return s;
}

/** A code however it was typed or pasted ("k7m 2qx", a casama.ai/i/K7M2QX link) in its stored form. */
export function normalizeReferralCode(input: string): string | null {
  const last =
    input
      .trim()
      .replace(/[?#].*$/, "")
      .replace(/\/+$/, "")
      .split("/")
      .pop() ?? "";
  const s = last
    .toUpperCase()
    .replace(/[^0-9A-Z]/g, "")
    .replace(/O/g, "0")
    .replace(/[IL]/g, "1")
    .replace(/U/g, "V");
  if (s.length !== REFERRAL_CODE_LENGTH) return null;
  for (const ch of s) if (!ALPHABET.includes(ch)) return null;
  return s;
}

const usd = (n: number) => `$${Number.isInteger(n) ? n : n.toFixed(2)}`;

/**
 * Decides referrals whose friend qualified: credits to the inviter (under the cap) and the friend's
 * welcome bonus, a notification to each, and analytics. Returns how many were decided.
 */
export async function sweepReferralRewards(
  db: Database,
  cfg: Pick<ReferralConfig, "enabled" | "rewardUsd" | "welcomeUsd" | "cap">,
): Promise<number> {
  if (!cfg.enabled) return 0;
  const rows = await db.execute<{
    invitee_id: string;
    inviter_id: string | null;
    status: "rewarded" | "capped" | "none";
    reward_usd: string | null;
    org_id: string | null;
    rewarded_count: number;
    welcome_usd: string | null;
    welcome_org_id: string | null;
  }>(
    sql`select * from public.worker_reward_referrals(${cfg.rewardUsd}, ${cfg.welcomeUsd}, ${cfg.cap}, 100)`,
  );
  const notify = (userId: string, orgId: string, kind: string, payload: object) =>
    db.execute(sql`
      insert into public.notifications (user_id, org_id, kind, payload, push_status, push_after)
      values (${userId}::uuid, ${orgId}::uuid, ${kind}, ${JSON.stringify(payload)}::jsonb, 'deferred', now())`);
  for (const r of rows) {
    if (r.welcome_usd && r.welcome_org_id) {
      await notify(r.invitee_id, r.welcome_org_id, "referral_welcome", {
        title: "Your welcome bonus is here",
        body: `${usd(Number(r.welcome_usd))} of free usage, for joining with a friend's invite.`,
        link: "/settings/invite",
      });
    }
    if (r.status === "rewarded" && r.org_id && r.inviter_id) {
      const amount = Number(r.reward_usd ?? cfg.rewardUsd);
      await notify(r.inviter_id, r.org_id, "referral_rewarded", {
        title: "A friend joined Casama",
        body: `You earned ${usd(amount)} of free usage. Thanks for spreading the word.`,
        link: "/settings/invite",
      });
    }
    track(db, {
      event: "referral_rewarded",
      userId: r.inviter_id ?? r.invitee_id,
      orgId: r.org_id,
      uuid: deterministicUuid("referral_rewarded", r.invitee_id),
      properties: {
        outcome: r.status,
        rewarded_count: r.rewarded_count,
        welcome_given: Boolean(r.welcome_usd),
      },
    });
  }
  return rows.length;
}
