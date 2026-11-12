/**
 * Invite friends (D-211): your invite code and link, entering a friend's code, and a public preview
 * of a code for the casama.ai/i/<code> page. Rewards are decided by the worker
 * (services/referrals.ts).
 */
import { track } from "@casama/agent";
import { routes } from "@casama/contracts";
import { type JwtClaims, pgErrorCode, pgErrorMessage, withUserSession } from "@casama/db";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { sql } from "drizzle-orm";
import {
  newReferralCode,
  normalizeReferralCode,
  referralConfig,
} from "../../services/referrals.ts";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { clientIp, iso } from "../util.ts";
import { failureLimiter } from "./joining.ts";

function requireClaims(claims: JwtClaims | undefined): JwtClaims {
  if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
  return claims;
}

const REDEEM_ERRORS: Record<string, [400 | 404 | 409, string]> = {
  referral_not_found: [404, "That invite code doesn't exist. Check it and try again."],
  referral_own_code: [400, "That's your own invite code. Share it with a friend instead."],
  referral_already: [409, "You've already used an invite code."],
  referral_window_closed: [
    400,
    "Invite codes can only be entered in the first days after signing up.",
  ],
  referral_mutual: [400, "You invited this person, so they can't invite you back."],
};

export function registerReferralRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;
  const cfg = referralConfig(deps.env);
  const limiter = failureLimiter();
  const limitKey = (c: { req: { header(n: string): string | undefined } }, claims?: JwtClaims) =>
    claims?.sub
      ? `u:${claims.sub}`
      : `ip:${clientIp((n) => c.req.header(n), deps.env.TRUSTED_CLIENT_IP_HEADER)}`;

  /** The person's code, made on first use (a clash with someone else's code just tries again). */
  const ensureCode = async (userId: string) => {
    for (let i = 0; i < 5; i++) {
      const [row] = await db
        .execute<{ code: string }>(sql`
        with ins as (
          insert into public.referral_codes (user_id, code) values (${userId}::uuid, ${newReferralCode()})
          on conflict (user_id) do nothing returning code
        )
        select code from ins union all
        select code from public.referral_codes where user_id = ${userId}::uuid
        limit 1`)
        .catch((err) => {
          if (pgErrorCode(err) === "23505") return [];
          throw err;
        });
      if (row) return row.code;
    }
    throw new ApiError(409, "conflict", "Could not make your invite code; try again");
  };

  const summary = async (claims: JwtClaims) => {
    const off = {
      enabled: false,
      code: null,
      link: null,
      reward_usd: 0,
      welcome_usd: 0,
      reward_cap: 0,
      invited: 0,
      rewarded: 0,
      pending: 0,
      earned_usd: 0,
      invited_by: null,
      redeem_until: null,
    };
    if (!cfg.enabled) return off;
    const code = await ensureCode(claims.sub);
    const [row] = await db.execute<{
      invited: number;
      rewarded: number;
      pending: number;
      earned: string | null;
      inviter_id: string | null;
      has_referral: boolean;
      my_status: string | null;
      my_welcome: string | null;
      signed_up: Date;
    }>(sql`
      select
        (select count(*)::int from public.referrals where inviter_id = ${claims.sub}::uuid) as invited,
        (select count(*)::int from public.referrals where inviter_id = ${claims.sub}::uuid and status = 'rewarded') as rewarded,
        (select count(*)::int from public.referrals where inviter_id = ${claims.sub}::uuid and status = 'pending') as pending,
        (select sum(reward_usd) from public.referrals where inviter_id = ${claims.sub}::uuid and status = 'rewarded') as earned,
        (select inviter_id from public.referrals where invitee_id = ${claims.sub}::uuid) as inviter_id,
        exists (select 1 from public.referrals where invitee_id = ${claims.sub}::uuid) as has_referral,
        (select status from public.referrals where invitee_id = ${claims.sub}::uuid) as my_status,
        (select welcome_usd from public.referrals where invitee_id = ${claims.sub}::uuid) as my_welcome,
        (select created_at from auth.users where id = ${claims.sub}::uuid) as signed_up`);
    if (!row) return off;
    let invitedBy: { name: string | null; welcome_earned_usd: number | null } | null = null;
    if (row.has_referral) {
      const [n] = row.inviter_id
        ? await db.execute<{ name: string | null }>(
            sql`select public.referral_inviter_name(${row.inviter_id}::uuid) as name`,
          )
        : [];
      invitedBy = {
        name: n?.name ?? null,
        welcome_earned_usd: row.my_status === "pending" ? null : Number(row.my_welcome ?? 0),
      };
    }
    const until = new Date(new Date(row.signed_up).getTime() + cfg.redeemDays * 86_400_000);
    return {
      enabled: true,
      code,
      link: `${cfg.linkBase}/${code}`,
      reward_usd: cfg.rewardUsd,
      welcome_usd: cfg.welcomeUsd,
      reward_cap: cfg.cap,
      invited: row.invited,
      rewarded: row.rewarded,
      pending: row.pending,
      earned_usd: Number(row.earned ?? 0),
      invited_by: invitedBy,
      redeem_until: !row.has_referral && until > new Date() ? iso(until) : null,
    };
  };

  app.openapi(routes.getReferral, async (c) => {
    const claims = requireClaims(c.get("claims"));
    return c.json(await summary(claims), 200);
  });

  app.openapi(routes.redeemReferral, async (c) => {
    const claims = requireClaims(c.get("claims"));
    if (!cfg.enabled) throw new ApiError(404, "referrals_off", "Invites aren't on for this server");
    const key = limitKey(c, claims);
    limiter.check(key);
    const code = normalizeReferralCode(c.req.valid("json").code);
    if (!code) {
      limiter.miss(key);
      throw new ApiError(404, "referral_not_found", REDEEM_ERRORS.referral_not_found?.[1] ?? "");
    }
    try {
      await withUserSession(db, claims, (tx) =>
        tx.execute(sql`select inviter_id from public.redeem_referral(${code}, ${cfg.redeemDays})`),
      );
    } catch (err) {
      const msg = pgErrorMessage(err) ?? "";
      const known = REDEEM_ERRORS[msg];
      if (!known) throw err;
      if (msg === "referral_not_found") limiter.miss(key);
      throw new ApiError(known[0], msg, known[1]);
    }
    track(db, {
      event: "referral_redeemed",
      userId: claims.sub,
      properties: { has_reward: cfg.rewardUsd > 0, has_welcome: cfg.welcomeUsd > 0 },
    });
    return c.json(await summary(claims), 200);
  });

  app.openapi(routes.previewReferral, async (c) => {
    if (!cfg.enabled) throw new ApiError(404, "referrals_off", "Invites aren't on for this server");
    const key = limitKey(c);
    limiter.check(key);
    const code = normalizeReferralCode(c.req.valid("query").code);
    const [row] = code
      ? await db.execute<{ inviter_name: string | null }>(
          sql`select inviter_name from public.referral_preview(${code})`,
        )
      : [];
    if (!row) {
      limiter.miss(key);
      throw new ApiError(404, "referral_not_found", "That invite code doesn't exist");
    }
    c.header("cache-control", "public, max-age=300");
    return c.json(
      { inviter_name: row.inviter_name, reward_usd: cfg.rewardUsd, welcome_usd: cfg.welcomeUsd },
      200,
    );
  });
}
