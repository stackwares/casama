import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";

const ts = z.iso.datetime({ offset: true });

export const ProjectStatus = z
  .enum(["planning", "active", "paused", "blocked", "done", "cancelled"])
  .openapi("ProjectStatus");

export const ProjectMilestone = z
  .object({
    id: Uuid,
    name: z.string(),
    position: z.number().int(),
    requires_signoff: z.boolean(),
    status: z.enum(["open", "awaiting_signoff", "done"]),
    tickets_done: z.number().int(),
    tickets_total: z.number().int(),
  })
  .openapi("ProjectMilestone");

export const Project = z
  .object({
    id: Uuid,
    org_id: Uuid,
    slug: z.string(),
    title: z.string(),
    goal_md: z.string(),
    done_criteria_md: z.string(),
    status: ProjectStatus,
    plan_status: z.enum(["draft", "proposed", "approved"]),
    status_reason: z.string().nullable(),
    lead_bot_id: Uuid,
    owner_user_id: Uuid.nullable(),
    conversation_id: Uuid.nullable(),
    budget_usd: z.number().nullable(),
    spent_usd: z.number(),
    deadline_at: ts.nullable(),
    plan_md: z.string(),
    sessions: z.number().int(),
    created_at: ts,
  })
  .openapi("Project");

export const ProjectRun = z
  .object({
    id: Uuid,
    bot_id: Uuid,
    trigger: z.string(),
    status: z.string(),
    cost_usd: z.number(),
    created_at: ts,
  })
  .openapi("ProjectRun");

export const ProjectDetail = Project.extend({
  milestones: z.array(ProjectMilestone),
  runs: z.array(ProjectRun),
}).openapi("ProjectDetail");

export const CreateProjectRequest = z
  .object({
    org_id: Uuid,
    title: z.string().trim().min(1).max(200),
    goal_md: z.string().trim().min(1).max(20_000),
    done_criteria_md: z.string().max(10_000).optional(),
    lead_bot_id: Uuid,
    budget_usd: z.number().positive().max(10_000).nullable().optional(),
    deadline_at: ts.nullable().optional(),
  })
  .openapi("CreateProjectRequest");

export const UpdateProjectRequest = z
  .object({
    title: z.string().trim().min(1).max(200).optional(),
    status: z
      .enum(["active", "paused", "cancelled"])
      .optional()
      .openapi({ description: "Resume, pause or cancel" }),
    budget_usd: z.number().positive().max(10_000).nullable().optional(),
    deadline_at: ts.nullable().optional(),
    plan_md: z.string().max(20_000).optional(),
  })
  .openapi("UpdateProjectRequest");
