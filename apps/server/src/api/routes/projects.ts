/**
 * Projects (D-113, D-295): create, view, approve the plan, sign off milestones, pause and resume,
 * and switch working by itself on or off. Reads run in the person's own database session, so
 * row-level security decides which projects they see (a personal one follows its chat).
 */

import {
  adoptChat,
  createProject,
  type ProjectRow,
  planningMessage,
  projectFolder,
  projectSpend,
  startProjectRun,
  teamFolder,
} from "@casama/agent";
import { routes } from "@casama/contracts";
import { type Database, type JwtClaims, withUserSession } from "@casama/db";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { sql } from "drizzle-orm";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { iso } from "../util.ts";
import { type CreationRow, creationColumns, creationJoins, creationOut } from "./creations.ts";

type Row = ProjectRow & {
  status_reason: string | null;
  created_at: Date | string;
  can_steer?: boolean;
};
/** What the Library holds for a project, as the person asking sees it. */
type Shelf = { count: number; latest: ReturnType<typeof creationOut> | null };

const WORKING = sql`('queued', 'running', 'waiting_approval', 'waiting_takeover')`;

const claimsOf = (c: { get(k: "claims"): JwtClaims | undefined }) => {
  const claims = c.get("claims");
  if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
  return claims;
};

/**
 * Where the lead bot works on its computer, under the home folder: `workspace`, or its own folder
 * on a team computer (D-148). The same pick of computer as `ComputerService.forBot`.
 */
async function workHome(db: Database, botId: string) {
  const [b] = await db.execute<{ kind: string | null }>(sql`
    select (select c.kind from public.computers c
       where c.org_id = b.org_id
         and (c.id = b.default_computer_id
              or (b.default_computer_id is null and (c.owner_bot_id = b.id or c.kind = 'team')))
       order by (c.id = b.default_computer_id) desc nulls last, (c.owner_bot_id = b.id) desc nulls last
       limit 1) as kind
    from public.bots b where b.id = ${botId}::uuid`);
  if (b?.kind !== "team") return "workspace";
  // Picked once from the bot's name (D-148), so it's the same folder the bot will work in.
  const folder = await teamFolder(db, botId).catch(() => null);
  return folder ? `workspace/bots/${folder}` : "workspace";
}

async function out(db: Database, p: Row, shelf?: Shelf) {
  return {
    ...(p.can_steer === undefined ? {} : { can_steer: p.can_steer }),
    ...(shelf ? { creations_count: shelf.count } : {}),
    ...(shelf?.latest ? { latest_creation: shelf.latest } : {}),
    autonomous: p.autonomous,
    personal: p.personal,
    folder: `${await workHome(db, p.lead_bot_id)}/${projectFolder(p.slug)}`,
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
    p.status_reason as last_session_kind, p.created_at, p.autonomous, p.personal`;
  const STEER = (
    userId: string,
  ) => sql`(p.owner_user_id = ${userId}::uuid or public.has_role(p.org_id, 'admin')
    or public.can_manage_bot(p.lead_bot_id)) as can_steer`;

  /** The project (visible to members) and whether this person may steer it. */
  const visible = async (claims: JwtClaims, id: string) => {
    const [p] = await withUserSession(db, claims, (tx) =>
      tx.execute<Row & { can_steer: boolean }>(sql`
        select ${COLUMNS}, ${STEER(claims.sub)}
        from public.projects p where p.id = ${id}::uuid`),
    );
    if (!p) throw new ApiError(404, "project_not_found", "Project not found");
    return p as Row & { can_steer: boolean };
  };
  /** What the Library holds for these projects that this person can see: a count and the newest. */
  const shelves = async (claims: JwtClaims, orgId: string, only?: string) => {
    const scope = only ? sql`and c.project_id = ${only}::uuid` : sql`and c.project_id is not null`;
    const [counts, latest] = await withUserSession(db, claims, async (tx) => [
      await tx.execute<{ project_id: string; n: number }>(sql`
        select c.project_id, count(*)::int as n from public.creations c
        where c.org_id = ${orgId}::uuid and c.deleted_at is null ${scope} group by c.project_id`),
      await tx.execute<CreationRow & { project_id: string }>(sql`
        select distinct on (c.project_id) ${creationColumns} ${creationJoins(claims.sub)}
        where c.org_id = ${orgId}::uuid and c.deleted_at is null ${scope}
        order by c.project_id, c.created_at desc, c.id desc`),
    ]);
    const map = new Map<string, Shelf>();
    for (const r of counts) map.set(r.project_id, { count: r.n, latest: null });
    for (const r of latest) {
      const shelf = map.get(r.project_id);
      if (shelf) shelf.latest = creationOut(r);
    }
    return (id: string): Shelf => map.get(id) ?? { count: 0, latest: null };
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
  const row = async (id: string) => {
    const [p] = await db.execute<Row>(
      sql`select ${COLUMNS} from public.projects p where p.id = ${id}::uuid`,
    );
    return p as Row;
  };
  /** The project after a change, for someone who was just allowed to make it. */
  const reload = async (id: string) => out(db, { ...(await row(id)), can_steer: true });
  const startRun = (runId: string) => deps.workflows.startRun(runId);

  app.openapi(routes.listProjects, async (c) => {
    const claims = claimsOf(c);
    const orgId = c.req.valid("query").org_id;
    const rows = await withUserSession(db, claims, (tx) =>
      tx.execute<Row>(sql`select ${COLUMNS}, ${STEER(claims.sub)} from public.projects p where p.org_id = ${orgId}::uuid
        order by case p.status when 'active' then 0 when 'planning' then 1 when 'blocked' then 2 when 'paused' then 3 else 4 end, p.updated_at desc`),
    );
    const shelf = await shelves(claims, orgId);
    return c.json({ items: await Promise.all(rows.map((r) => out(db, r, shelf(r.id)))) }, 200);
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
    // Before D-295 every project planned and ran by itself, so that stays the default on the wire.
    const autonomous = body.autonomous ?? true;
    const goal = (body.goal_md ?? "").trim();
    if (autonomous && !goal)
      throw new ApiError(400, "goal_needed", "A project that works by itself needs a goal");
    if (autonomous && body.conversation_id)
      throw new ApiError(
        400,
        "bad_request",
        "A chat can only become a project you work on together",
      );
    // A topic of the person's own becomes the project's chat.
    if (body.conversation_id) {
      const [chat] = await withUserSession(db, claims, (tx) =>
        tx.execute<{
          bot_id: string;
          is_main: boolean;
          own: boolean;
          project_id: string | null;
          created_by: string | null;
        }>(sql`
          select c.bot_id, c.is_main, (c.personal and c.kind = 'direct') as own, c.project_id, c.created_by
          from public.conversations c
          where c.id = ${body.conversation_id}::uuid and c.org_id = ${body.org_id}::uuid`),
      );
      if (!chat) throw new ApiError(404, "conversation_not_found", "Chat not found");
      if (chat.created_by !== claims.sub)
        throw new ApiError(
          403,
          "forbidden",
          "Only the person who started a chat can make it a project",
        );
      if (chat.bot_id !== body.lead_bot_id || !chat.own)
        throw new ApiError(
          400,
          "not_a_topic",
          "Only your own chat with the bot can become a project",
        );
      if (chat.is_main)
        throw new ApiError(
          400,
          "general_not_project",
          "General can't become a project. Start a topic for it.",
        );
      if (chat.project_id)
        throw new ApiError(400, "already_project", "This chat already belongs to a project");
    }
    const p = await createProject(db, {
      orgId: body.org_id,
      title: body.title,
      goal,
      doneCriteria: body.done_criteria_md ?? "",
      leadBotId: body.lead_bot_id,
      ownerUserId: claims.sub,
      budgetUsd: body.budget_usd ?? null,
      deadline: body.deadline_at ? new Date(body.deadline_at) : null,
      autonomous,
      // One that grew out of a chat follows the chat; one made here is the workspace's.
      personal: !!body.conversation_id,
    });
    if (autonomous) await startProjectRun(db, p, "plan", planningMessage(p), startRun);
    else if (body.conversation_id) await adoptChat(db, p, body.conversation_id);
    else {
      // A new topic for it, under the person's General with the bot (made first when they have
      // none, so the project's chat never becomes General).
      await db.execute(
        sql`select public.main_conversation(${body.org_id}::uuid, ${body.lead_bot_id}::uuid, ${claims.sub}::uuid)`,
      );
      const [chat] = await db.execute<{ id: string }>(sql`
        insert into public.conversations (org_id, bot_id, title, created_by, personal, project_id)
        values (${body.org_id}::uuid, ${body.lead_bot_id}::uuid, ${p.title}, ${claims.sub}::uuid, true, ${p.id}::uuid)
        returning id`);
      await db.execute(
        sql`update public.projects set conversation_id = ${chat?.id}::uuid where id = ${p.id}::uuid`,
      );
    }
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
    const shelf = await shelves(claims, p.org_id, id);
    return c.json(
      {
        ...(await out(db, p, shelf(id))),
        // Nothing closes a milestone in a project worked on together: it's done when its to-dos are.
        milestones: milestones.map((m) =>
          p.autonomous || !m.tickets_total || m.tickets_done < m.tickets_total
            ? m
            : { ...m, status: "done" as const },
        ),
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
    const turnOn = body.autonomous === true && !p.autonomous;
    const turnOff = body.autonomous === false && p.autonomous;
    const autonomous = body.autonomous ?? p.autonomous;
    // A finished project worked on together can be picked up again; one that ran by itself can't.
    if (
      (body.status === "active" || turnOn) &&
      (p.status === "cancelled" || (p.status === "done" && (p.autonomous || turnOn)))
    )
      throw new ApiError(400, "project_closed", `This project is ${p.status}`);
    if (body.status === "active" && autonomous && p.plan_status !== "approved")
      throw new ApiError(400, "plan_not_approved", "Approve the plan first");
    if (autonomous && !(body.goal_md ?? p.goal_md).trim())
      throw new ApiError(400, "goal_needed", "A project that works by itself needs a goal");
    // Planning is posted in the project's chat, and nothing is posted there mid-run (D-253).
    const plans = turnOn && p.plan_status !== "approved";
    if (plans && p.conversation_id) {
      const [busy] = await db.execute<{ id: string }>(sql`
        select id from public.runs where conversation_id = ${p.conversation_id}::uuid and status in ${WORKING} limit 1`);
      if (busy)
        throw new ApiError(
          409,
          "busy",
          "The bot is working in this project's chat. Try again when it's done.",
        );
    }
    // Switched on: plan first, or carry on with a plan approved earlier. Switched off: nothing
    // waits on a plan, a budget or a question any more.
    const status =
      body.status ??
      (turnOn
        ? plans
          ? "planning"
          : "active"
        : turnOff && ["planning", "paused", "blocked"].includes(p.status)
          ? "active"
          : null);
    await db.execute(sql`
      update public.projects set
        title = coalesce(${body.title ?? null}, title),
        status = coalesce(${status}, status),
        status_reason = case when ${status}::text is not null then null else status_reason end,
        budget_usd = case when ${body.budget_usd !== undefined} then ${body.budget_usd ?? null}::numeric else budget_usd end,
        deadline_at = case when ${body.deadline_at !== undefined} then ${body.deadline_at ?? null}::timestamptz else deadline_at end,
        plan_md = coalesce(${body.plan_md ?? null}, plan_md),
        goal_md = coalesce(${body.goal_md ?? null}, goal_md),
        done_criteria_md = coalesce(${body.done_criteria_md ?? null}, done_criteria_md),
        autonomous = ${autonomous},
        updated_at = now()
      where id = ${id}::uuid`);
    if (plans) {
      const fresh = await row(id);
      await startProjectRun(db, fresh, "plan", planningMessage(fresh), startRun);
    }
    if (turnOn || turnOff)
      await db.execute(sql`insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id)
        values (${p.org_id}::uuid, 'user', ${claims.sub}::uuid, ${turnOn ? "project.autonomy_on" : "project.autonomy_off"}, 'project', ${id}::uuid)`);
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
