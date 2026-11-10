/**
 * Projects (SPEC: Post-v1 roadmap → Projects; D-113). The lead bot plans milestones and tickets,
 * the owner approves, then a heartbeat (every minute, in the worker) starts one session at a time
 * while tickets are ready. Each session is a normal run carrying the project id, so limits and
 * spend work as usual. The heartbeat stops at the budget or deadline, waits for milestone
 * sign-offs, and never runs a paused, blocked, done or cancelled project.
 */
import type { Database } from "@kasama/db";
import { sql } from "drizzle-orm";
import { z } from "zod";
import { actingUserOf } from "./acting.ts";
import type { NotificationService } from "./notifications.ts";
import { ToolError, type ToolRegistry } from "./tools/registry.ts";
import { contentKeys } from "@kasama/db";

type StartRun = (runId: string) => Promise<void>;

export type ProjectRow = {
  id: string;
  org_id: string;
  slug: string;
  title: string;
  goal_md: string;
  done_criteria_md: string;
  status: string;
  plan_status: string;
  lead_bot_id: string;
  owner_user_id: string | null;
  conversation_id: string | null;
  budget_usd: string | null;
  deadline_at: Date | string | null;
  plan_md: string;
  sessions: number;
  last_session_kind: string | null;
};

const COLUMNS = sql`id, org_id, slug, title, goal_md, done_criteria_md, status, plan_status, lead_bot_id, owner_user_id,
  conversation_id, budget_usd, deadline_at, plan_md, sessions, status_reason as last_session_kind`;

export const slugify = (s: string) =>
  s
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 50) || "project";

/** Total spend of a project's runs. */
export async function projectSpend(db: Database, projectId: string) {
  const [r] = await db.execute<{ s: string }>(sql`
    select coalesce(sum(cost_usd), 0) as s from public.runs where project_id = ${projectId}::uuid`);
  return Number(r?.s ?? 0);
}

async function notifyOwner(
  db: Database,
  notifications: NotificationService | undefined,
  p: ProjectRow,
  title: string,
  body: string,
) {
  if (!notifications || !p.owner_user_id) return;
  await notifications
    .notify(p.owner_user_id, p.org_id, "project", {
      title: `${p.title}: ${title}`.slice(0, 200),
      body: body.slice(0, 300),
      link: `/projects/${p.id}`,
      project_id: p.id,
      bot_id: p.lead_bot_id,
    })
    .catch(() => {});
  void db;
}

/** Posts a line into the project thread (as the lead bot's message). */
async function postToThread(db: Database, p: ProjectRow, text: string) {
  if (!p.conversation_id) return;
  await db.execute(sql`
    insert into public.messages (org_id, conversation_id, role, content)
    values (${p.org_id}::uuid, ${p.conversation_id}::uuid, 'assistant', ${contentKeys.sealJson(p.org_id, [{ type: "text", text }])}::jsonb)`);
  await db.execute(
    sql`update public.conversations set last_message_at = now() where id = ${p.conversation_id}::uuid`,
  );
}

const brief = (p: ProjectRow) =>
  [
    `Project: "${p.title}" (id ${p.id}). Work folder on your computer: projects/${p.slug}/.`,
    `Goal:\n${p.goal_md}`,
    p.done_criteria_md ? `Done when:\n${p.done_criteria_md}` : "",
    p.plan_md ? `Plan and notes so far:\n${p.plan_md}` : "",
  ]
    .filter(Boolean)
    .join("\n\n");

/** Starts a run in the project thread: planning, a work session, or a wrap-up check. */
export async function startProjectRun(
  db: Database,
  p: ProjectRow,
  kind: "plan" | "session" | "wrap_up",
  text: string,
  startRun: StartRun,
) {
  const runId = await db.transaction(async (tx) => {
    let conv = p.conversation_id;
    if (!conv) {
      const [c] = await tx.execute<{ id: string }>(sql`
        insert into public.conversations (org_id, bot_id, title, created_by, project_id)
        values (${p.org_id}::uuid, ${p.lead_bot_id}::uuid, ${`Project: ${p.title}`.slice(0, 200)}, ${p.owner_user_id}::uuid, ${p.id}::uuid)
        returning id`);
      conv = c?.id ?? null;
      await tx.execute(
        sql`update public.projects set conversation_id = ${conv}::uuid where id = ${p.id}::uuid`,
      );
    }
    const [run] = await tx.execute<{ id: string }>(sql`
      insert into public.runs (org_id, bot_id, conversation_id, created_by, trigger, project_id)
      values (${p.org_id}::uuid, ${p.lead_bot_id}::uuid, ${conv}::uuid, ${p.owner_user_id}::uuid, 'project', ${p.id}::uuid)
      returning id`);
    await tx.execute(sql`
      insert into public.messages (org_id, conversation_id, role, author_user_id, content, run_id)
      values (${p.org_id}::uuid, ${conv}::uuid, 'user', ${p.owner_user_id}::uuid,
              ${contentKeys.sealJson(p.org_id, [{ type: "text", text }])}::jsonb, ${run?.id}::uuid)`);
    if (kind !== "plan")
      await tx.execute(sql`
        update public.projects set sessions = sessions + 1, last_session_at = now(), status_reason = ${kind}, updated_at = now()
        where id = ${p.id}::uuid`);
    return run?.id as string;
  });
  try {
    await startRun(runId);
  } catch {
    await db.execute(sql`update public.runs set status = 'failed', ended_at = now(),
      error = ${JSON.stringify({ code: "enqueue_failed", message: "The run could not be started." })}::jsonb
      where id = ${runId}::uuid`);
  }
  return runId;
}

export const planningMessage = (p: ProjectRow) =>
  `${brief(p)}\n\nPlan this project. Break the goal into a few milestones, each with concrete tickets (assign tickets to other bots when they fit better; check the team with bots.list). Mark a milestone as needing sign-off when the owner should review it before the next begins. Then call projects.plan with the milestones and a short plan_md. Don't start the work yet: the owner approves the plan first.`;

async function pause(
  db: Database,
  n: NotificationService | undefined,
  p: ProjectRow,
  status: "paused" | "blocked",
  reason: string,
) {
  await db.execute(sql`
    update public.projects set status = ${status}, status_reason = ${reason}, updated_at = now() where id = ${p.id}::uuid`);
  await postToThread(db, p, reason);
  await notifyOwner(db, n, p, status === "paused" ? "Paused" : "Blocked", reason);
}

/**
 * One heartbeat for every active project. Returns the runs it started. Safe to repeat: a project
 * with a run in flight (its session or its tickets' runs) is left alone.
 */
export async function projectHeartbeat(
  db: Database,
  startRun: StartRun,
  notifications?: NotificationService,
  now = new Date(),
) {
  const started: string[] = [];
  const projects = await db.execute<ProjectRow>(sql`
    select ${COLUMNS} from public.projects where status = 'active' and plan_status = 'approved' order by last_session_at nulls first limit 50`);
  for (const p of projects) {
    const [busy] = await db.execute<{ id: string }>(sql`
      select id from public.runs where project_id = ${p.id}::uuid
        and status in ('queued', 'running', 'waiting_approval', 'waiting_takeover') limit 1`);
    if (busy) continue;
    const spend = await projectSpend(db, p.id);
    if (p.budget_usd !== null && spend >= Number(p.budget_usd)) {
      await pause(
        db,
        notifications,
        p,
        "paused",
        `Budget reached: $${spend.toFixed(2)} of $${Number(p.budget_usd).toFixed(2)}. Raise the budget to continue.`,
      );
      continue;
    }
    if (p.deadline_at && new Date(p.deadline_at).getTime() <= now.getTime()) {
      await pause(
        db,
        notifications,
        p,
        "paused",
        "The deadline passed. Set a new deadline to continue.",
      );
      continue;
    }
    // The current milestone: the first one not done. Finished milestones close (or wait for sign-off).
    let milestone:
      | { id: string; name: string; requires_signoff: boolean; status: string }
      | undefined;
    for (;;) {
      [milestone] = await db.execute<{
        id: string;
        name: string;
        requires_signoff: boolean;
        status: string;
      }>(sql`
        select id, name, requires_signoff, status from public.project_milestones
        where project_id = ${p.id}::uuid and status <> 'done' order by position limit 1`);
      if (!milestone) break;
      const [open] = await db.execute<{ n: number }>(sql`
        select count(*)::int as n from public.tasks where milestone_id = ${milestone.id}::uuid and status <> 'done'`);
      if ((open?.n ?? 0) > 0) break;
      if (milestone.requires_signoff) {
        if (milestone.status === "open") {
          await db.execute(
            sql`update public.project_milestones set status = 'awaiting_signoff' where id = ${milestone.id}::uuid`,
          );
          await postToThread(
            db,
            p,
            `Milestone "${milestone.name}" is done and waits for the owner's sign-off.`,
          );
          await notifyOwner(db, notifications, p, "Milestone ready for sign-off", milestone.name);
        }
        break;
      }
      await db.execute(
        sql`update public.project_milestones set status = 'done' where id = ${milestone.id}::uuid`,
      );
      await postToThread(db, p, `Milestone "${milestone.name}" is done.`);
    }
    if (
      milestone?.status === "awaiting_signoff" ||
      (milestone?.requires_signoff &&
        milestone.status === "open" &&
        !(await hasOpen(db, milestone.id)))
    )
      continue;
    const ready = await db.execute<{
      id: string;
      title: string;
      priority: string;
      details_md: string;
      assignee_bot_id: string | null;
    }>(sql`
      select id, title, priority, details_md, assignee_bot_id from public.tasks
      where project_id = ${p.id}::uuid and status = 'todo'
        and (${milestone?.id ?? null}::uuid is null or milestone_id = ${milestone?.id ?? null}::uuid or milestone_id is null)
        and (assignee_bot_id is null or assignee_bot_id = ${p.lead_bot_id}::uuid)
      order by case priority when 'urgent' then 0 when 'high' then 1 when 'medium' then 2 when 'low' then 3 else 4 end, created_at
      limit 10`);
    if (ready.length) {
      const list = ready
        .map(
          (t) =>
            `- [${t.id}] ${t.title} (${t.priority})${t.details_md ? `: ${t.details_md.slice(0, 200)}` : ""}`,
        )
        .join("\n");
      const text = `${brief(p)}\n\nProject session ${p.sessions + 1}${milestone ? `, milestone "${milestone.name}"` : ""}. Ready tickets:\n${list}\n\nWork these tickets: do them yourself, or hand them to other bots (tasks.update with an assignee) or subagents. Keep each ticket's status current with tasks.update. Before you finish, call projects.update with plan_md saying what was done, what is next and any blocker. If you need a decision only the owner can make, call projects.update with status "blocked" and the question.`;
      started.push(await startProjectRun(db, p, "session", text, startRun));
      continue;
    }
    // Nothing ready: other bots may still be working, or everything is finished.
    const [left] = await db.execute<{ n: number }>(sql`
      select count(*)::int as n from public.tasks where project_id = ${p.id}::uuid and status <> 'done'`);
    if ((left?.n ?? 0) > 0) continue;
    if (milestone) continue;
    if (p.last_session_kind === "wrap_up") {
      await pause(
        db,
        notifications,
        p,
        "blocked",
        "All tickets are done, but the lead bot hasn't confirmed the done criteria. Check the project and mark it done, or add work.",
      );
      continue;
    }
    const text = `${brief(p)}\n\nEvery ticket is done. Check the work against the done criteria. If they're met, call projects.update with status "done" and a final plan_md summary. If not, add the missing work with projects.plan.`;
    started.push(await startProjectRun(db, p, "wrap_up", text, startRun));
  }
  return started;
}

async function hasOpen(db: Database, milestoneId: string) {
  const [r] = await db.execute<{ n: number }>(sql`
    select count(*)::int as n from public.tasks where milestone_id = ${milestoneId}::uuid and status <> 'done'`);
  return (r?.n ?? 0) > 0;
}

// ---------------------------------------------------------------------------
// Tools
// ---------------------------------------------------------------------------

const PRIORITY = z.enum(["urgent", "high", "medium", "low", "none"]);

export function registerProjectTools(
  registry: ToolRegistry,
  deps: { db: Database; startRun?: StartRun; notifications?: NotificationService },
) {
  const { db } = deps;
  const load = async (orgId: string, ref: string) => {
    const [p] = await db.execute<ProjectRow>(sql`
      select ${COLUMNS} from public.projects
      where org_id = ${orgId}::uuid and (id::text = ${ref} or slug = ${ref} or lower(title) = lower(${ref})) limit 1`);
    if (!p) throw new ToolError("project_not_found", `No project ${ref}.`);
    return p;
  };
  const botId = async (orgId: string, name: string | undefined) => {
    if (!name) return null;
    const [b] = await db.execute<{ id: string }>(sql`
      select id from public.bots where org_id = ${orgId}::uuid and archived_at is null and (id::text = ${name} or lower(name) = lower(${name})) limit 1`);
    if (!b) throw new ToolError("bot_not_found", `No bot named ${name}.`);
    return b.id;
  };

  registry.register({
    name: "projects.create",
    description:
      "Start a project: a goal, what done looks like, a lead bot (default you), and optionally a budget and deadline. The lead bot then plans it for the person to approve.",
    risk: "medium",
    schema: z.object({
      title: z.string().min(1).max(200),
      goal: z.string().min(1).max(20_000),
      done_criteria: z.string().max(10_000).optional(),
      lead_bot: z.string().max(100).optional(),
      budget_usd: z.number().positive().max(10_000).optional(),
      deadline: z.string().max(40).optional().describe("ISO date or time"),
    }),
    async execute(args, ctx) {
      const lead = (await botId(ctx.orgId, args.lead_bot)) ?? ctx.botId;
      const owner = await actingUserOf(db, ctx.runId);
      const deadline = args.deadline ? new Date(args.deadline) : null;
      if (deadline && Number.isNaN(deadline.getTime()))
        throw new ToolError("invalid_deadline", "deadline must be an ISO date.");
      const p = await createProject(db, {
        orgId: ctx.orgId,
        title: args.title,
        goal: args.goal,
        doneCriteria: args.done_criteria ?? "",
        leadBotId: lead,
        ownerUserId: owner,
        budgetUsd: args.budget_usd ?? null,
        deadline,
      });
      if (deps.startRun) await startProjectRun(db, p, "plan", planningMessage(p), deps.startRun);
      return {
        content: `Created the project "${p.title}" (${p.id}). The lead bot is planning it; the owner approves the plan before work starts.`,
        preview: `project ${p.title}`,
      };
    },
  });

  registry.register({
    name: "projects.plan",
    description:
      "Set a project's plan: milestones in order, each with tickets (title, details, priority, an optional assignee bot) and whether the owner signs it off before the next. Before approval this replaces the proposed plan; after approval it adds work.",
    risk: "low",
    schema: z.object({
      project: z.string().min(1).max(200),
      plan_md: z.string().max(20_000),
      milestones: z
        .array(
          z.object({
            name: z.string().min(1).max(120),
            requires_signoff: z.boolean().optional(),
            tickets: z
              .array(
                z.object({
                  title: z.string().min(1).max(300),
                  details: z.string().max(10_000).optional(),
                  priority: PRIORITY.optional(),
                  assignee_bot: z.string().max(100).optional(),
                }),
              )
              .min(1)
              .max(30),
          }),
        )
        .min(1)
        .max(12),
    }),
    async execute(args, ctx) {
      const p = await load(ctx.orgId, args.project);
      if (["done", "cancelled"].includes(p.status))
        throw new ToolError("project_closed", `This project is ${p.status}.`);
      const assignees = new Map<string, string | null>();
      for (const m of args.milestones)
        for (const t of m.tickets)
          if (t.assignee_bot) assignees.set(t.assignee_bot, await botId(ctx.orgId, t.assignee_bot));
      const approved = p.plan_status === "approved";
      let count = 0;
      await db.transaction(async (tx) => {
        if (!approved) {
          await tx.execute(
            sql`delete from public.tasks where project_id = ${p.id}::uuid and status = 'todo'`,
          );
          await tx.execute(
            sql`delete from public.project_milestones where project_id = ${p.id}::uuid`,
          );
        }
        const [{ base } = { base: 0 }] = await tx.execute<{ base: number }>(sql`
          select coalesce(max(position), 0)::int as base from public.project_milestones where project_id = ${p.id}::uuid`);
        for (const [i, m] of args.milestones.entries()) {
          const [ms] = await tx.execute<{ id: string }>(sql`
            insert into public.project_milestones (org_id, project_id, name, position, requires_signoff)
            values (${p.org_id}::uuid, ${p.id}::uuid, ${m.name}, ${base + i + 1}, ${m.requires_signoff ?? false}) returning id`);
          for (const t of m.tickets) {
            await tx.execute(sql`
              insert into public.tasks (org_id, created_by_bot_id, assignee_bot_id, title, details_md, priority, project_id, milestone_id, created_by_user_id)
              values (${p.org_id}::uuid, ${ctx.botId}::uuid, ${t.assignee_bot ? (assignees.get(t.assignee_bot) ?? null) : null}::uuid,
                      ${t.title}, ${contentKeys.seal(p.org_id, t.details ?? "")}, ${t.priority ?? "medium"}, ${p.id}::uuid, ${ms?.id}::uuid, ${p.owner_user_id}::uuid)`);
            count++;
          }
        }
        await tx.execute(sql`
          update public.projects set plan_md = ${args.plan_md}, version = version + 1, updated_at = now(),
            plan_status = case when plan_status = 'approved' then 'approved' else 'proposed' end
          where id = ${p.id}::uuid`);
      });
      if (!approved)
        await notifyOwner(
          db,
          deps.notifications,
          p,
          "Plan ready to approve",
          `${args.milestones.length} milestones, ${count} tickets`,
        );
      return {
        content: approved
          ? `Added ${args.milestones.length} milestones and ${count} tickets to the project.`
          : `Proposed the plan: ${args.milestones.length} milestones, ${count} tickets. The owner approves it before work starts.`,
        preview: `${count} tickets`,
      };
    },
  });

  registry.register({
    name: "projects.update",
    description:
      'Update a project: plan_md (what was done, what is next, blockers), or its status: "blocked" with the question for the owner, or "done" when the done criteria are met.',
    risk: "low",
    schema: z.object({
      project: z.string().min(1).max(200),
      plan_md: z.string().max(20_000).optional(),
      status: z.enum(["blocked", "done"]).optional(),
      question: z
        .string()
        .max(2000)
        .optional()
        .describe("With status blocked: what you need from the owner"),
    }),
    async execute(args, ctx) {
      const p = await load(ctx.orgId, args.project);
      if (args.plan_md !== undefined)
        await db.execute(
          sql`update public.projects set plan_md = ${args.plan_md}, version = version + 1, updated_at = now() where id = ${p.id}::uuid`,
        );
      if (args.status === "blocked") {
        const q = args.question ?? "The lead bot needs your input.";
        await pause(db, deps.notifications, p, "blocked", `Blocked: ${q}`);
      } else if (args.status === "done") {
        await db.execute(
          sql`update public.projects set status = 'done', status_reason = null, updated_at = now() where id = ${p.id}::uuid`,
        );
        await notifyOwner(
          db,
          deps.notifications,
          p,
          "Done",
          "The lead bot marked the project done.",
        );
      }
      return {
        content: `Updated the project${args.status ? ` (now ${args.status})` : ""}.`,
        preview: args.status ?? "plan updated",
      };
    },
  });

  registry.register({
    name: "projects.status",
    readOnly: true,
    description:
      "A project's status: milestones, ticket counts, spend against budget and the plan.",
    risk: "low",
    schema: z.object({ project: z.string().min(1).max(200) }),
    async execute(args, ctx) {
      const p = await load(ctx.orgId, args.project);
      const ms = await db.execute<{
        name: string;
        status: string;
        open: number;
        total: number;
      }>(sql`
        select m.name, m.status,
          (select count(*)::int from public.tasks t where t.milestone_id = m.id and t.status <> 'done') as open,
          (select count(*)::int from public.tasks t where t.milestone_id = m.id) as total
        from public.project_milestones m where m.project_id = ${p.id}::uuid order by m.position`);
      const spend = await projectSpend(db, p.id);
      return {
        content: [
          `"${p.title}" is ${p.status}${p.plan_status !== "approved" ? ` (plan ${p.plan_status})` : ""}.`,
          `Spend: $${spend.toFixed(2)}${p.budget_usd ? ` of $${Number(p.budget_usd).toFixed(2)}` : ""}.`,
          ...ms.map((m) => `- ${m.name}: ${m.total - m.open}/${m.total} done (${m.status})`),
          p.plan_md ? `\nPlan:\n${p.plan_md}` : "",
        ].join("\n"),
        preview: p.status,
      };
    },
  });
}

/** Creates a project row with a unique slug. */
export async function createProject(
  db: Database,
  a: {
    orgId: string;
    title: string;
    goal: string;
    doneCriteria: string;
    leadBotId: string;
    ownerUserId: string | null;
    budgetUsd: number | null;
    deadline: Date | null;
  },
): Promise<ProjectRow> {
  const base = slugify(a.title);
  for (let i = 0; i < 20; i++) {
    const slug = i ? `${base}-${i + 1}` : base;
    const rows = await db.execute<ProjectRow>(sql`
      insert into public.projects (org_id, slug, title, goal_md, done_criteria_md, lead_bot_id, owner_user_id, budget_usd, deadline_at)
      values (${a.orgId}::uuid, ${slug}, ${a.title}, ${a.goal}, ${a.doneCriteria}, ${a.leadBotId}::uuid, ${a.ownerUserId}::uuid,
              ${a.budgetUsd}, ${a.deadline?.toISOString() ?? null}::timestamptz)
      on conflict (org_id, slug) do nothing
      returning ${COLUMNS}`);
    if (rows[0]) return rows[0];
  }
  throw new ToolError("slug_taken", "Too many projects with that title.");
}
