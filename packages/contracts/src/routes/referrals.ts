import { createRoute, z } from "@hono/zod-openapi";
import { jsonBody, jsonResponse, problemResponses } from "../common.ts";
import { RedeemReferralRequest, Referral, ReferralPreview } from "../referrals.ts";

/**
 * Invite friends (D-211): anyone can sign up. Each person has one invite code and link; a new person
 * can enter a friend's code for a few days after signing up, and the friend earns free credits once
 * the new person verifies their address and finishes a first chat.
 */
const security = [{ bearerAuth: [] }];
const { 400: e400, 401: e401, 404: e404, 409: e409, 429: e429 } = problemResponses;
const tags = ["referrals"];

export const getReferral = createRoute({
  operationId: "getReferral",
  method: "get",
  path: "/v1/me/referral",
  tags,
  security,
  summary: "Your invite code and link, what you've earned, and who invited you",
  responses: { 200: jsonResponse("Invite friends", Referral), 401: e401 },
});

export const redeemReferral = createRoute({
  operationId: "redeemReferral",
  method: "post",
  path: "/v1/me/referral/redeem",
  tags,
  security,
  summary: "Enter a friend's invite code (a few days after signing up)",
  description:
    "Errors: 404 referral_not_found, 400 referral_own_code, 409 referral_already, 400 referral_window_closed, 400 referral_mutual, 404 referrals_off, 429 too_many_attempts.",
  request: { body: jsonBody(RedeemReferralRequest) },
  responses: {
    200: jsonResponse("Invite friends", Referral),
    400: e400,
    401: e401,
    404: e404,
    409: e409,
    429: e429,
  },
});

export const previewReferral = createRoute({
  operationId: "previewReferral",
  method: "get",
  path: "/v1/referral/preview",
  tags,
  summary: "Who an invite code is from (no sign-in)",
  request: { query: z.object({ code: z.string().min(1).max(200) }) },
  responses: { 200: jsonResponse("Invite", ReferralPreview), 404: e404, 429: e429 },
});
