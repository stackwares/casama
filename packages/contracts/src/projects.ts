import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";
import { Creation } from "./creations.ts";

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
    autonomous: z.boolean().optional().openapi({
      description:
        "Plans for your approval, then works by itself in sessions (D-113). False: worked on together in its chat (D-295). Absent on older servers, where every project is autonomous",
    }),
    personal: z.boolean().optional().openapi({
      description:
        "Grew out of a person's own chat: seen by them and by whoever can open its chat, not the whole workspace",
    }),
    folder: z.string().optional().openapi({
      description:
        "Where its files live on the lead bot's computer, under the home folder (the folder is made when the bot first saves something there)",
    }),
    creations_count: z.number().int().optional().openapi({
      description: "How many things in the Library are filed under it, that you can see",
    }),
    // The newest of them, for a cover; absent when there is none.
    latest_creation: Creation.optional(),
    can_steer: z.boolean().optional().openapi({
      description: "Whether you may change it: its owner, an admin or the lead bot's managers",
    }),
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
    goal_md: z.string().trim().max(20_000).optional().openapi({
      description: "Needed when the project works by itself",
    }),
    done_criteria_md: z.string().max(10_000).optional(),
    lead_bot_id: Uuid,
    budget_usd: z.number().positive().max(10_000).nullable().optional(),
    deadline_at: ts.nullable().optional(),
    autonomous: z.boolean().optional().openapi({
      description:
        "true (the default, as before D-295): the lead bot drafts a plan for you to approve, then works by itself. false: a project you work on together in its chat",
    }),
    conversation_id: Uuid.optional().openapi({
      description:
        "With autonomous false: make this topic of yours the project's chat, and file what was made in it under the project. Without it the project gets a new topic",
    }),
  })
  .openapi("CreateProjectRequest");

export const UpdateProjectRequest = z
  .object({
    title: z.string().trim().min(1).max(200).optional(),
    status: z.enum(["active", "paused", "cancelled", "done"]).optional().openapi({
      description:
        "Resume, pause, cancel or finish. A finished project you work on together can be made active again",
    }),
    budget_usd: z.number().positive().max(10_000).nullable().optional(),
    deadline_at: ts.nullable().optional(),
    plan_md: z.string().max(20_000).optional(),
    goal_md: z.string().trim().max(20_000).optional(),
    done_criteria_md: z.string().max(10_000).optional(),
    autonomous: z.boolean().optional().openapi({
      description:
        "true: the lead bot drafts a plan for you to approve, then works by itself (needs a goal). false: back to working on it together; nothing more starts by itself",
    }),
  })
  .openapi("UpdateProjectRequest");
