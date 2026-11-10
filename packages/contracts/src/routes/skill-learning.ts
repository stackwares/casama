import { createRoute, z } from "@hono/zod-openapi";
import { jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";
import { AcceptSkillProposalRequest, SkillProposal, SkillStats } from "../skill-learning.ts";

const security = [{ bearerAuth: [] }];
const { 401: e401, 403: e403, 404: e404, 409: e409 } = problemResponses;
const idParam = z.object({ id: Uuid });
const tags = ["skills"];

export const listSkillProposals = createRoute({
  operationId: "listSkillProposals",
  method: "get",
  path: "/v1/skill-proposals",
  tags,
  security,
  summary: "Skills and skill edits bots proposed from their runs (D-126)",
  request: { query: z.object({ org_id: Uuid, bot_id: Uuid.optional() }) },
  responses: {
    200: jsonResponse(
      "Proposals",
      z.object({ items: z.array(SkillProposal) }).openapi("SkillProposalList"),
    ),
    401: e401,
  },
});

export const acceptSkillProposal = createRoute({
  operationId: "acceptSkillProposal",
  method: "post",
  path: "/v1/skill-proposals/{id}/accept",
  tags,
  security,
  summary: "Save the proposed skill or edit, optionally changed first",
  request: { params: idParam, body: jsonBody(AcceptSkillProposalRequest) },
  responses: {
    200: jsonResponse("Accepted", SkillProposal),
    401: e401,
    403: e403,
    404: e404,
    409: e409,
  },
});

export const dismissSkillProposal = createRoute({
  operationId: "dismissSkillProposal",
  method: "post",
  path: "/v1/skill-proposals/{id}/dismiss",
  tags,
  security,
  request: { params: idParam },
  responses: {
    200: jsonResponse("Dismissed", SkillProposal),
    401: e401,
    403: e403,
    404: e404,
    409: e409,
  },
});

export const getSkillStats = createRoute({
  operationId: "getSkillStats",
  method: "get",
  path: "/v1/skills/{id}/stats",
  tags,
  security,
  summary: "Uses, success rate, last failure and history of a skill",
  request: { params: idParam },
  responses: { 200: jsonResponse("Stats", SkillStats), 401: e401, 404: e404 },
});
