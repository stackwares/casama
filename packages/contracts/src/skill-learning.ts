import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";

const ts = z.iso.datetime({ offset: true });

export const SkillProposal = z
  .object({
    id: Uuid,
    bot_id: Uuid,
    kind: z.enum(["new", "edit"]),
    skill_id: Uuid.nullable(),
    name: z.string(),
    description: z.string(),
    body_md: z.string(),
    previous_body_md: z.string().nullable(),
    tools: z.array(z.string()),
    reason: z.string(),
    status: z.enum(["pending", "accepted", "dismissed", "applied"]),
    created_at: ts,
  })
  .openapi("SkillProposal");

export const AcceptSkillProposalRequest = z
  .object({
    name: z.string().regex(/^[a-z0-9][a-z0-9_-]{0,62}$/).optional(),
    description: z.string().min(1).max(300).optional(),
    body_md: z.string().min(1).max(50_000).optional(),
  })
  .openapi("AcceptSkillProposalRequest");

export const SkillStats = z
  .object({
    uses: z.number().int(),
    successes: z.number().int(),
    failures: z.number().int(),
    corrections: z.number().int(),
    success_rate: z.number().nullable(),
    last_failure_at: ts.nullable(),
    last_failure_run_id: Uuid.nullable(),
    revisions: z.array(z.object({ id: Uuid, description: z.string(), body_md: z.string(), by_bot: z.boolean(), created_at: ts })),
  })
  .openapi("SkillStats");
