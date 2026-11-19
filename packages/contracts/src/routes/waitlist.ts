import { createRoute, z } from "@hono/zod-openapi";
import { jsonBody, jsonResponse, problemResponses } from "../common.ts";
import {
  AddWaitlistEntriesRequest,
  AdmitWaitlistRequest,
  CreateInviteCampaignRequest,
  InviteCampaign,
  InviteCampaignList,
  InviteCodePreview,
  InviteRedeemed,
  JoinWaitlistRequest,
  LeaveWaitlistRequest,
  RedeemInviteRequest,
  SetSignupGateRequest,
  SignupGateState,
  UpdateInviteCampaignRequest,
  WaitlistChanged,
  WaitlistJoined,
  WaitlistPage,
  WaitlistQuery,
} from "../waitlist.ts";

/**
 * The waitlist and invite gate for Casama Cloud (docs/WAITLIST-PLAN.md). While the gate is on, a
 * new account is made only for an email address that was let in: from the waitlist, by claiming
 * an invite code together with an address, or by hand. Servers without the waitlist (self-hosted
 * ones) answer 404 waitlist_off on every route here.
 */
const security = [{ bearerAuth: [] }];
const { 400: e400, 401: e401, 403: e403, 404: e404, 409: e409, 429: e429 } = problemResponses;

export const joinWaitlist = createRoute({
  operationId: "joinWaitlist",
  method: "post",
  path: "/v1/waitlist",
  tags: ["waitlist"],
  summary: "Join the waitlist (no sign-in; needs a solved sign-up puzzle)",
  description:
    "Sends no email. Answers the same for every address, so nobody can find out who is on the list. Errors: 400 bad_email, 400 disposable_email, 403 proof_required, 404 waitlist_off, 429 too_many_attempts.",
  request: { body: jsonBody(JoinWaitlistRequest) },
  responses: {
    200: jsonResponse("On the list", WaitlistJoined),
    400: e400,
    403: e403,
    404: e404,
    429: e429,
  },
});

export const redeemInvite = createRoute({
  operationId: "redeemInvite",
  method: "post",
  path: "/v1/waitlist/redeem",
  tags: ["waitlist"],
  summary: "Claim an invite code for an email address (no sign-in; needs a solved puzzle)",
  description:
    "The address can then sign up with any sign-in method. Errors: 400 bad_email, 400 disposable_email, 403 proof_required, 404 invite_not_found, 404 waitlist_off, 429 too_many_attempts.",
  request: { body: jsonBody(RedeemInviteRequest) },
  responses: {
    200: jsonResponse("What the code did", InviteRedeemed),
    400: e400,
    403: e403,
    404: e404,
    429: e429,
  },
});

export const previewInviteCode = createRoute({
  operationId: "previewInviteCode",
  method: "get",
  path: "/v1/invites/preview",
  tags: ["waitlist"],
  summary: "What an invite code is, and whether it has an invite left (no sign-in)",
  request: { query: z.object({ code: z.string().min(1).max(200) }) },
  responses: { 200: jsonResponse("Invite", InviteCodePreview), 404: e404, 429: e429 },
});

export const leaveWaitlist = createRoute({
  operationId: "leaveWaitlist",
  method: "post",
  path: "/v1/waitlist/leave",
  tags: ["waitlist"],
  summary: "Take an address off the waitlist, with the token from its email (no sign-in)",
  request: { body: jsonBody(LeaveWaitlistRequest) },
  responses: { 200: jsonResponse("Removed", WaitlistJoined), 400: e400, 404: e404, 429: e429 },
});

// --- owner ---------------------------------------------------------------------------------------

export const adminWaitlist = createRoute({
  operationId: "adminWaitlist",
  method: "get",
  path: "/v1/admin/waitlist",
  tags: ["admin"],
  security,
  summary: "The waitlist: numbers, the gate and a page of entries (owner only)",
  request: { query: WaitlistQuery },
  responses: { 200: jsonResponse("Waitlist", WaitlistPage), 401: e401, 403: e403, 404: e404 },
});

export const adminAdmitWaitlist = createRoute({
  operationId: "adminAdmitWaitlist",
  method: "post",
  path: "/v1/admin/waitlist/admit",
  tags: ["admin"],
  security,
  summary: "Let people in: chosen entries, or the next N (owner only)",
  description:
    "They are let in as their “You're in” emails go out, a few a minute and never more than the day's number.",
  request: { body: jsonBody(AdmitWaitlistRequest) },
  responses: {
    200: jsonResponse("Chosen", WaitlistChanged),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
  },
});

export const adminAddWaitlistEntries = createRoute({
  operationId: "adminAddWaitlistEntries",
  method: "post",
  path: "/v1/admin/waitlist/entries",
  tags: ["admin"],
  security,
  summary: "Let addresses in by hand (owner only)",
  request: { body: jsonBody(AddWaitlistEntriesRequest) },
  responses: {
    200: jsonResponse("Let in", WaitlistChanged),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
  },
});

export const adminRemoveWaitlistEntry = createRoute({
  operationId: "adminRemoveWaitlistEntry",
  method: "delete",
  path: "/v1/admin/waitlist/entries/{id}",
  tags: ["admin"],
  security,
  summary: "Remove an entry; a removed address can no longer sign up (owner only)",
  request: { params: z.object({ id: z.uuid() }) },
  responses: { 204: { description: "Removed" }, 401: e401, 403: e403, 404: e404 },
});

export const adminSignupGate = createRoute({
  operationId: "adminSignupGate",
  method: "get",
  path: "/v1/admin/signup-gate",
  tags: ["admin"],
  security,
  summary: "The sign-up gate (owner only)",
  responses: { 200: jsonResponse("Gate", SignupGateState), 401: e401, 403: e403, 404: e404 },
});

export const adminSetSignupGate = createRoute({
  operationId: "adminSetSignupGate",
  method: "put",
  path: "/v1/admin/signup-gate",
  tags: ["admin"],
  security,
  summary: "Turn the gate on or off, set its opening time and numbers (owner only)",
  description: "Fields left out keep their value. Takes effect within 15 seconds, with no deploy.",
  request: { body: jsonBody(SetSignupGateRequest) },
  responses: {
    200: jsonResponse("Gate", SignupGateState),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
  },
});

export const adminInviteCampaigns = createRoute({
  operationId: "adminInviteCampaigns",
  method: "get",
  path: "/v1/admin/invite-campaigns",
  tags: ["admin"],
  security,
  summary: "Campaign invite codes (owner only)",
  responses: {
    200: jsonResponse("Campaigns", InviteCampaignList),
    401: e401,
    403: e403,
    404: e404,
  },
});

export const adminCreateInviteCampaign = createRoute({
  operationId: "adminCreateInviteCampaign",
  method: "post",
  path: "/v1/admin/invite-campaigns",
  tags: ["admin"],
  security,
  summary: "Make a campaign invite code with a total (owner only)",
  description: "Errors: 400 bad_code, 409 conflict when the code exists.",
  request: { body: jsonBody(CreateInviteCampaignRequest) },
  responses: {
    200: jsonResponse("Campaign", InviteCampaign),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
    409: e409,
  },
});

export const adminUpdateInviteCampaign = createRoute({
  operationId: "adminUpdateInviteCampaign",
  method: "patch",
  path: "/v1/admin/invite-campaigns/{code}",
  tags: ["admin"],
  security,
  summary: "Change a campaign code's total, dates or name, or turn it off (owner only)",
  request: {
    params: z.object({ code: z.string().min(4).max(32) }),
    body: jsonBody(UpdateInviteCampaignRequest),
  },
  responses: {
    200: jsonResponse("Campaign", InviteCampaign),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
  },
});
