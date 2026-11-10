/** Projects (D-113): create, view, approve the plan, sign off milestones, pause and resume. */
import type { OpenAPIHono } from "@hono/zod-openapi";
import {
  createProject,
  planningMessage,
  type ProjectRow,
  projectSpend,
  startProjectRun,
} from "@kasama/agent";
import { routes } from "@kasama/contracts";
import { type Database, type JwtClaims, withUserSession } from "@kasama/db";
import { sql } from "drizzle-orm";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { iso } from "../util.ts";

type Row = ProjectRow & { status_reason: string | null; created_at: Date | string };

const claimsOf = (c: { get(k: "claims"): JwtClaims | undefined }) => {
  const claims = c.get("claims");
  if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
  return claims;
};

async function out(db: Database, p: Row) {
  return {
    id: p.id,
    org_id: p.org_id,
    slug: p.slug,
    title: p.title,
    goal_md: p.goal_md,
    done_criteria_md: p.done_criteria_md,
    status: p.status as "active",
    plan_status: p.plan_status as "draft",
    status_reason:
      p.status_reason === "session" || p.status_reason === "wrap_up" ? null : p.status_reason,
    lead_bot_id: p.lead_bot_id,
    owner_user_id: p.owner_user_id,
    conversation_id: p.conversation_id,
    budget_usd: p.budget_usd === null ? null : Number(p.budget_usd),
    spent_usd: await projectSpend(db, p.id),
    deadline_at: p.deadline_at ? iso(p.deadline_at) : null,
    plan_md: p.plan_md,
    sessions: p.sessions,
    created_at: iso(p.created_at),
  };
}

export function registerProjectRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;
  const COLUMNS = sql`p.id, p.org_id, p.slug, p.title, p.goal_md, p.done_criteria_md, p.status, p.plan_status, p.lead_bot_id,
    p.owner_user_id, p.conversation_id, p.budget_usd, p.deadline_at, p.plan_md, p.sessions, p.status_reason,
    p.status_reason as last_session_kind, p.created_at`;

  /** The project (visible to members) and whether this person may steer it. */
  const visible = async (claims: JwtClaims, id: string) => {
    const [p] = await withUserSession(db, claims, (tx) =>
      tx.execute<Row & { can_steer: boolean }>(sql`
        select ${COLUMNS}, (p.owner_user_id = ${claims.sub}::uuid or public.has_role(p.org_id, 'admin')
                            or public.can_manage_bot(p.lead_bot_id)) as can_steer
        from public.projects p where p.id = ${id}::uuid`),
    );
    if (!p) throw new ApiError(404, "project_not_found", "Project not found");
    return p;
  };
  const steer = async (claims: JwtClaims, id: string) => {
    const p = await visible(claims, id);
    if (!p.can_steer)
      throw new ApiError(
        403,
        "forbidden",
        "Only the project's owner, an admin or the lead bot's managers can do that",
      );
    return p;
  };
  const reload = async (id: string) => {
    const [p] = await db.execute<Row>(
      sql`select ${COLUMNS} from public.projects p where p.id = ${id}::uuid`,
    );
    return out(db, p as Row);
  };
  const startRun = (runId: string) => deps.workflows.startRun(runId);

  app.openapi(routes.listProjects, async (c) => {
    const claims = claimsOf(c);
    const rows = await withUserSession(db, claims, (tx) =>
      tx.execute<Row>(sql`select ${COLUMNS} from public.projects p where p.org_id = ${c.req.valid("query").org_id}::uuid
        order by case p.status when 'active' then 0 when 'planning' then 1 when 'blocked' then 2 when 'paused' then 3 else 4 end, p.updated_at desc`),
    );
    return c.json({ items: await Promise.all(rows.map((r) => out(db, r))) }, 200);
  });

  app.openapi(routes.createProject, async (c) => {
    const claims = claimsOf(c);
    const body = c.req.valid("json");
    const [lead] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ id: string; ok: boolean }>(sql`
        select id, public.can_access_bot(id) as ok from public.bots
        where id = ${body.lead_bot_id}::uuid and org_id = ${body.org_id}::uuid and archived_at is null`),
    );
    if (!lead?.ok) throw new ApiError(400, "bot_not_found", "Pick a lead bot from this workspace");
    const p = await createProject(db, {
      orgId: body.org_id,
      title: body.title,
      goal: body.goal_md,
      doneCriteria: body.done_criteria_md ?? "",
      leadBotId: body.lead_bot_id,
      ownerUserId: claims.sub,
      budgetUsd: body.budget_usd ?? null,
      deadline: body.deadline_at ? new Date(body.deadline_at) : null,
    });
    await startProjectRun(db, p, "plan", planningMessage(p), startRun);
    await db.execute(sql`insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id)
      values (${body.org_id}::uuid, 'user', ${claims.sub}::uuid, 'project.created', 'project', ${p.id}::uuid)`);
    return c.json(await reload(p.id), 201);
  });

  app.openapi(routes.getProject, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    const p = await visible(claims, id);
    const milestones = await db.execute<{
      id: string;
      name: string;
      position: number;
      requires_signoff: boolean;
      status: "open";
      tickets_done: number;
      tickets_total: number;
    }>(sql`
      select m.id, m.name, m.position, m.requires_signoff, m.status,
        (select count(*)::int from public.tasks t where t.milestone_id = m.id and t.status = 'done') as tickets_done,
        (select count(*)::int from public.tasks t where t.milestone_id = m.id) as tickets_total
      from public.project_milestones m where m.project_id = ${id}::uuid order by m.position`);
    const runs = await db.execute<{
      id: string;
      bot_id: string;
      trigger: string;
      status: string;
      cost_usd: string;
      created_at: string;
    }>(sql`
      select id, bot_id, trigger, status, cost_usd, created_at from public.runs where project_id = ${id}::uuid
      order by created_at desc limit 100`);
    return c.json(
      {
        ...(await out(db, p)),
        milestones: [...milestones],
        runs: runs.map((r) => ({
          ...r,
          cost_usd: Number(r.cost_usd),
          created_at: iso(r.created_at),
        })),
      },
      200,
    );
  });

  app.openapi(routes.updateProject, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    const body = c.req.valid("json");
    const p = await steer(claims, id);
    if (body.status === "active" && ["done", "cancelled"].includes(p.status))
      throw new ApiError(400, "project_closed", `This project is ${p.status}`);
    if (body.status === "active" && p.plan_status !== "approved")
      throw new ApiError(400, "plan_not_approved", "Approve the plan first");
    await db.execute(sql`
      update public.projects set
        title = coalesce(${body.title ?? null}, title),
        status = coalesce(${body.status ?? null}, status),
        status_reason = case when ${body.status ?? null}::text is not null then null else status_reason end,
        budget_usd = case when ${body.budget_usd !== undefined} then ${body.budget_usd ?? null}::numeric else budget_usd end,
        deadline_at = case when ${body.deadline_at !== undefined} then ${body.deadline_at ?? null}::timestamptz else deadline_at end,
        plan_md = coalesce(${body.plan_md ?? null}, plan_md),
        updated_at = now()
      where id = ${id}::uuid`);
    if (body.status === "cancelled")
      await db.execute(sql`update public.runs set cancel_requested_at = now()
        where project_id = ${id}::uuid and status in ('queued', 'running', 'waiting_approval', 'waiting_takeover')`);
    return c.json(await reload(id), 200);
  });

  app.openapi(routes.approveProjectPlan, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    const p = await steer(claims, id);
    if (p.plan_status !== "proposed")
      throw new ApiError(409, "no_plan", "There's no proposed plan to approve yet");
    await db.execute(sql`
      update public.projects set plan_status = 'approved', status = 'active', status_reason = null, updated_at = now()
      where id = ${id}::uuid`);
    await db.execute(sql`insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id)
      values (${p.org_id}::uuid, 'user', ${claims.sub}::uuid, 'project.plan_approved', 'project', ${id}::uuid)`);
    return c.json(await reload(id), 200);
  });

  app.openapi(routes.signOffMilestone, async (c) => {
    const claims = claimsOf(c);
    const { id, milestone_id } = c.req.valid("param");
    await steer(claims, id);
    const [m] = await db.execute<{ id: string }>(sql`
      update public.project_milestones set status = 'done', signed_off_by = ${claims.sub}::uuid, signed_off_at = now()
      where id = ${milestone_id}::uuid and project_id = ${id}::uuid and status = 'awaiting_signoff' returning id`);
    if (!m)
      throw new ApiError(409, "not_awaiting_signoff", "That milestone isn't waiting for sign-off");
    return c.json(await reload(id), 200);
  });
}
