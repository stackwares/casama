import { randomBytes } from "node:crypto";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { startTicketWork } from "@kasama/agent";
import { routes } from "@kasama/contracts";
import { type Database, type JwtClaims, pgErrorCode, schema, withUserSession } from "@kasama/db";
import {
  BOT_TEMPLATES,
  isValidCron,
  isValidTimezone,
  nextRunAt,
  templateById,
} from "@kasama/domain";
import { and, desc, eq, sql } from "drizzle-orm";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { iso } from "../util.ts";

const { approvals, secrets, integrations, routines, tasks, bots } = schema;
const MAX_WEBHOOK_BODY = 1024 * 1024;

export function requireClaims(claims: JwtClaims | undefined): JwtClaims {
  if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
  return claims;
}

export const isAdmin = async (db: Database, claims: JwtClaims, orgId: string) => {
  const [r] = await withUserSession(db, claims, (tx) =>
    tx.execute<{ ok: boolean }>(sql`select public.has_role(${orgId}::uuid, 'admin') as ok`),
  );
  return !!r?.ok;
};
const isMember = async (db: Database, claims: JwtClaims, orgId: string) => {
  const [r] = await withUserSession(db, claims, (tx) =>
    tx.execute<{ ok: boolean }>(sql`select public.is_member(${orgId}::uuid) as ok`),
  );
  return !!r?.ok;
};

type ApprovalRow = typeof approvals.$inferSelect;
const approvalOut = (a: ApprovalRow) => ({
  id: a.id,
  bot_id: a.botId,
  run_id: a.runId,
  tool_name: a.toolName,
  args_redacted: a.argsRedacted as Record<string, unknown>,
  summary: a.summary,
  risk: a.risk as "high",
  status: a.status as "pending",
  decided_at: a.decidedAt ? iso(a.decidedAt) : null,
  expires_at: iso(a.expiresAt),
  created_at: iso(a.createdAt),
});

type SecretRow = typeof secrets.$inferSelect;
const secretOut = (s: SecretRow) => ({
  id: s.id,
  org_id: s.orgId,
  name: s.name,
  allowed_hosts: s.allowedHosts,
  allowed_bot_ids: s.allowedBotIds,
  created_at: iso(s.createdAt),
});

export type IntegrationRow = typeof integrations.$inferSelect;
export const integrationOut = (i: IntegrationRow, botIds?: string[]) => ({
  id: i.id,
  org_id: i.orgId,
  kind: i.kind as "mcp",
  name: i.name,
  status: i.status as "ok",
  error: i.error,
  tools: ((i.toolsCache as Array<{ name: string; description: string; risk?: string }>) ?? []).map(
    (t) => ({
      name: t.name,
      description: t.description,
      risk: t.risk as "low" | undefined,
    }),
  ),
  tools_cached_at: i.toolsCachedAt ? iso(i.toolsCachedAt) : null,
  created_at: iso(i.createdAt),
  app_id:
    typeof (i.config as Record<string, unknown>)?.app === "string"
      ? ((i.config as Record<string, string>).app ?? null)
      : null,
  auth: (((i.config as Record<string, unknown>)?.auth as string | undefined) ??
    (i.vaultSecretId ? "api_key" : "none")) as "oauth" | "api_key" | "none",
  risk_overrides: (i.riskOverrides as Record<string, "low" | "medium" | "high">) ?? {},
  ...(botIds ? { bot_ids: botIds } : {}),
  device:
    i.kind === "local_mcp"
      ? (() => {
          const c = i.config as Record<string, string | null>;
          return {
            id: String(c.device_id ?? ""),
            computer_id: c.computer_id ?? null,
            owner_user_id: String(c.owner_user_id ?? ""),
            label: String(c.label ?? i.name),
          };
        })()
      : null,
});

type RoutineRow = typeof routines.$inferSelect;
const routineOut = (r: RoutineRow) => ({
  id: r.id,
  bot_id: r.botId,
  name: r.name,
  instructions_md: r.instructionsMd,
  schedule_cron: r.scheduleCron,
  timezone: r.timezone,
  trigger: ((r.trigger as { type?: string })?.type ?? "schedule") as
    | "schedule"
    | "once"
    | "github"
    | "webhook",
  notify: r.notify,
  enabled: r.enabled,
  next_run_at: r.nextRunAt ? iso(r.nextRunAt) : null,
  last_run_at: r.lastRunAt ? iso(r.lastRunAt) : null,
  conversation_id: r.conversationId,
  created_at: iso(r.createdAt),
});

/** Applies a starter template to a new bot: persona, autonomy, skills and routines. */
export async function applyTemplate(
  db: Database,
  botId: string,
  orgId: string,
  userId: string,
  templateId: string,
) {
  const t = templateById(templateId);
  if (!t) return;
  for (const s of t.skills) {
    await db.execute(sql`insert into public.skills (org_id, bot_id, name, description, body_md)
      values (${orgId}::uuid, ${botId}::uuid, ${s.name}, ${s.description}, ${s.body_md}) on conflict do nothing`);
  }
  const [p] = await db.execute<{ timezone: string }>(
    sql`select timezone from public.profiles where user_id = ${userId}::uuid`,
  );
  const tz = p?.timezone ?? "UTC";
  for (const r of t.routines ?? []) {
    await db.execute(sql`insert into public.routines (org_id, bot_id, created_by, name, instructions_md, schedule_cron, timezone, next_run_at)
      values (${orgId}::uuid, ${botId}::uuid, ${userId}::uuid, ${r.name}, ${r.instructions_md}, ${r.schedule_cron}, ${tz},
              ${nextRunAt(r.schedule_cron, tz).toISOString()}::timestamptz)`);
  }
}

export function registerAutonomyRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;
  const vault = async (value: string, description: string) => {
    const [r] = await db.execute<{ id: string }>(
      sql`select vault.create_secret(${value}, null, ${description}) as id`,
    );
    return r?.id as string;
  };

  // --- approvals ---------------------------------------------------------------

  app.openapi(routes.listApprovals, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { org_id, status } = c.req.valid("query");
    const rows = await withUserSession(db, claims, (tx) =>
      tx
        .select()
        .from(approvals)
        .where(
          status
            ? and(eq(approvals.orgId, org_id), eq(approvals.status, status))
            : eq(approvals.orgId, org_id),
        )
        .orderBy(desc(approvals.createdAt))
        .limit(200),
    );
    return c.json({ items: rows.map(approvalOut) }, 200);
  });

  app.openapi(routes.decideApproval, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const { decision, always_allow } = c.req.valid("json");
    let row: ApprovalRow | undefined;
    try {
      await withUserSession(db, claims, (tx) =>
        tx.execute(
          sql`select public.decide_approval(${id}::uuid, ${decision}, ${always_allow ?? false})`,
        ),
      );
      [row] = await db.select().from(approvals).where(eq(approvals.id, id));
    } catch (err) {
      const code = pgErrorCode(err);
      if (code === "P0002") throw new ApiError(404, "approval_not_found", "Approval not found");
      if (code === "55000")
        throw new ApiError(409, "approval_already_decided", "This approval was already decided");
      throw err;
    }
    if (!row) throw new ApiError(404, "approval_not_found", "Approval not found");
    await db.execute(sql`insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id, metadata)
      values (${row.orgId}::uuid, 'user', ${claims.sub}::uuid, ${`approval.${row.status}`}, 'approval', ${row.id}::uuid,
              ${JSON.stringify({ tool: row.toolName, always_allow: row.alwaysAllow })}::jsonb)`);
    await deps.workflows.signalRun(row.runId);
    return c.json(approvalOut(row), 200);
  });

  // --- secrets -------------------------------------------------------------------

  // --- secret requests from bots (D-101) --------------------------------------------

  type AskRow = {
    id: string;
    org_id: string;
    bot_id: string;
    run_id: string;
    conversation_id: string | null;
    name: string;
    service: string;
    allowed_hosts: string[];
    reason: string;
    status: "pending";
    expires_at: Date | string;
    created_at: Date | string;
    run_by: string | null;
  };
  const askOut = (r: AskRow) => ({
    id: r.id,
    org_id: r.org_id,
    bot_id: r.bot_id,
    run_id: r.run_id,
    conversation_id: r.conversation_id,
    name: r.name,
    service: r.service,
    allowed_hosts: r.allowed_hosts,
    reason: r.reason,
    status: r.status,
    expires_at: iso(r.expires_at),
    created_at: iso(r.created_at),
  });
  const ASK_COLUMNS = sql`s.id, s.org_id, s.bot_id, s.run_id, s.conversation_id, s.name, s.service, s.allowed_hosts,
    s.reason, case when s.status = 'pending' and s.expires_at <= now() then 'expired' else s.status end as status,
    s.expires_at, s.created_at, r.created_by as run_by`;

  /** The request, if this person can see it (RLS) and may answer it: an admin or the run's sender. */
  const askFor = async (claims: JwtClaims, id: string) => {
    const [row] = await withUserSession(db, claims, (tx) =>
      tx.execute<AskRow>(sql`select ${ASK_COLUMNS} from public.secret_requests s
        join public.runs r on r.id = s.run_id where s.id = ${id}::uuid`),
    );
    if (!row) throw new ApiError(404, "secret_request_not_found", "Secret request not found");
    if (row.run_by !== claims.sub && !(await isAdmin(db, claims, row.org_id)))
      throw new ApiError(
        403,
        "forbidden",
        "Only the person who started this chat or an admin can answer",
      );
    if (row.status !== "pending")
      throw new ApiError(409, "secret_request_closed", `This request is already ${row.status}`);
    return row;
  };

  app.openapi(routes.listSecretRequests, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const rows = await withUserSession(db, claims, (tx) =>
      tx.execute<AskRow>(sql`select ${ASK_COLUMNS} from public.secret_requests s
        join public.runs r on r.id = s.run_id
        where s.org_id = ${c.req.valid("query").org_id}::uuid and s.status = 'pending' and s.expires_at > now()
        order by s.created_at desc limit 50`),
    );
    return c.json({ items: rows.map(askOut) }, 200);
  });

  app.openapi(routes.fulfillSecretRequest, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const { value } = c.req.valid("json");
    const ask = await askFor(claims, id);
    const admin = await isAdmin(db, claims, ask.org_id);
    const secretId = await db.transaction(async (tx) => {
      const [existing] = await tx.execute<{ id: string; vault_secret_id: string | null }>(sql`
        select id, vault_secret_id from public.secrets where org_id = ${ask.org_id}::uuid and name = ${ask.name} for update`);
      if (existing) {
        // Replacing a workspace secret is an admin's call; the hosts become the requested ones.
        if (!admin)
          throw new ApiError(
            409,
            "secret_exists",
            `A secret named ${ask.name} already exists. Ask an admin to replace it.`,
          );
        if (existing.vault_secret_id)
          await tx.execute(
            sql`select vault.update_secret(${existing.vault_secret_id}::uuid, ${value})`,
          );
        else {
          const [v] = await tx.execute<{ id: string }>(
            sql`select vault.create_secret(${value}, null, 'named secret') as id`,
          );
          await tx.execute(
            sql`update public.secrets set vault_secret_id = ${v?.id}::uuid where id = ${existing.id}::uuid`,
          );
        }
        await tx.execute(
          sql`update public.secrets set allowed_hosts = array(select jsonb_array_elements_text(${JSON.stringify(ask.allowed_hosts)}::jsonb)) where id = ${existing.id}::uuid`,
        );
        return existing.id;
      }
      const [v] = await tx.execute<{ id: string }>(
        sql`select vault.create_secret(${value}, null, 'named secret') as id`,
      );
      // Only the bot that asked may use it, and only on the hosts it named.
      const [r] = await tx.execute<{ id: string }>(sql`
        insert into public.secrets (org_id, name, vault_secret_id, allowed_hosts, allowed_bot_ids, created_by)
        values (${ask.org_id}::uuid, ${ask.name}, ${v?.id}::uuid, array(select jsonb_array_elements_text(${JSON.stringify(ask.allowed_hosts)}::jsonb)), array[${ask.bot_id}::uuid], ${claims.sub}::uuid)
        returning id`);
      return r?.id;
    });
    const [done] = await db.execute<{ id: string }>(sql`
      update public.secret_requests set status = 'fulfilled', secret_id = ${secretId}::uuid, resolved_by = ${claims.sub}::uuid, resolved_at = now()
      where id = ${id}::uuid and status = 'pending' returning id`);
    if (!done)
      throw new ApiError(409, "secret_request_closed", "This request was already answered");
    await db.execute(sql`insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id, metadata)
      values (${ask.org_id}::uuid, 'user', ${claims.sub}::uuid, 'secret.request_fulfilled', 'secret', ${secretId}::uuid,
              ${JSON.stringify({ name: ask.name, bot_id: ask.bot_id, hosts: ask.allowed_hosts })}::jsonb)`);
    await deps.workflows.signalRun(ask.run_id);
    return c.json(askOut({ ...ask, status: "fulfilled" as never }), 200);
  });

  app.openapi(routes.declineSecretRequest, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const ask = await askFor(claims, id);
    await db.execute(sql`update public.secret_requests set status = 'declined', resolved_by = ${claims.sub}::uuid, resolved_at = now()
      where id = ${id}::uuid and status = 'pending'`);
    await deps.workflows.signalRun(ask.run_id);
    return c.json(askOut({ ...ask, status: "declined" as never }), 200);
  });

  app.openapi(routes.listSecrets, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const rows = await withUserSession(db, claims, (tx) =>
      tx
        .select()
        .from(secrets)
        .where(eq(secrets.orgId, c.req.valid("query").org_id))
        .orderBy(secrets.name),
    );
    return c.json({ items: rows.map(secretOut) }, 200);
  });

  app.openapi(routes.createSecret, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const body = c.req.valid("json");
    if (!(await isAdmin(db, claims, body.org_id)))
      throw new ApiError(403, "forbidden", "Only owners and admins can add secrets");
    try {
      const row = await db.transaction(async (tx) => {
        const [v] = await tx.execute<{ id: string }>(
          sql`select vault.create_secret(${body.value}, null, 'named secret') as id`,
        );
        const [r] = await tx
          .insert(secrets)
          .values({
            orgId: body.org_id,
            name: body.name,
            vaultSecretId: v?.id,
            allowedHosts: body.allowed_hosts.map((h) => h.toLowerCase()),
            allowedBotIds: body.allowed_bot_ids ?? null,
            createdBy: claims.sub,
          })
          .returning();
        return r;
      });
      if (!row) throw new Error("secret insert returned nothing");
      await db.execute(sql`insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id)
        values (${row.orgId}::uuid, 'user', ${claims.sub}::uuid, 'secret.created', 'secret', ${row.id}::uuid)`);
      return c.json(secretOut(row), 201);
    } catch (err) {
      if (pgErrorCode(err) === "23505")
        throw new ApiError(409, "secret_exists", `A secret named ${body.name} already exists`);
      throw err;
    }
  });

  app.openapi(routes.deleteSecret, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const rows = await withUserSession(db, claims, (tx) =>
      tx.delete(secrets).where(eq(secrets.id, id)).returning(),
    );
    if (!rows.length)
      throw new ApiError(404, "secret_not_found", "Secret not found (or you are not an admin)");
    const vaultId = rows[0]?.vaultSecretId;
    if (vaultId) await db.execute(sql`delete from vault.secrets where id = ${vaultId}::uuid`);
    await db.execute(sql`insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id, metadata)
      values (${rows[0]?.orgId}::uuid, 'user', ${claims.sub}::uuid, 'secret.deleted', 'secret', ${id}::uuid,
              ${JSON.stringify({ name: rows[0]?.name })}::jsonb)`);
    return c.json({ deleted: id }, 200);
  });

  // --- integrations ---------------------------------------------------------------

  app.openapi(routes.listIntegrations, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const rows = await withUserSession(db, claims, (tx) =>
      tx
        .select()
        .from(integrations)
        .where(eq(integrations.orgId, c.req.valid("query").org_id))
        .orderBy(integrations.name),
    );
    const links = await withUserSession(db, claims, (tx) =>
      tx.execute<{ integration_id: string; bot_id: string }>(sql`
        select integration_id, bot_id from public.bot_integrations
        where org_id = ${c.req.valid("query").org_id}::uuid`),
    );
    const byIntegration = new Map<string, string[]>();
    for (const l of links)
      byIntegration.set(l.integration_id, [
        ...(byIntegration.get(l.integration_id) ?? []),
        l.bot_id,
      ]);
    return c.json(
      { items: rows.map((r) => integrationOut(r, byIntegration.get(r.id) ?? [])) },
      200,
    );
  });

  app.openapi(routes.createIntegration, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const body = c.req.valid("json");
    if (!(await isAdmin(db, claims, body.org_id)))
      throw new ApiError(403, "forbidden", "Only owners and admins can add integrations");
    if (body.kind === "mcp" && typeof body.config.url !== "string") {
      throw new ApiError(400, "validation_failed", "MCP integrations need config.url", {
        errors: [{ path: "config.url", message: "Required" }],
      });
    }
    if ((body.kind === "composio" || body.kind === "pipedream") && !body.secret) {
      throw new ApiError(
        400,
        "validation_failed",
        `${body.kind} needs its API key or client secret`,
        { errors: [{ path: "secret", message: "Required" }] },
      );
    }
    let row: IntegrationRow | undefined;
    try {
      const vaultId = body.secret ? await vault(body.secret, `integration ${body.kind}`) : null;
      [row] = await db
        .insert(integrations)
        .values({
          orgId: body.org_id,
          kind: body.kind,
          name: body.name,
          config: body.config,
          vaultSecretId: vaultId,
          createdBy: claims.sub,
        })
        .returning();
    } catch (err) {
      if (pgErrorCode(err) === "23505")
        throw new ApiError(
          409,
          "integration_exists",
          `An integration named ${body.name} already exists`,
        );
      throw err;
    }
    if (!row) throw new Error("integration insert returned nothing");
    await db.execute(sql`insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id, metadata)
      values (${row.orgId}::uuid, 'user', ${claims.sub}::uuid, 'integration.created', 'integration', ${row.id}::uuid, ${JSON.stringify({ kind: row.kind })}::jsonb)`);
    // List tools right away (best effort) so the integration is ready to attach.
    await deps.workflows.testIntegration(row.id).catch(() => null);
    const [fresh] = await db.select().from(integrations).where(eq(integrations.id, row.id));
    return c.json(integrationOut(fresh ?? row), 201);
  });

  app.openapi(routes.testIntegration, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const [row] = await withUserSession(db, claims, (tx) =>
      tx.select().from(integrations).where(eq(integrations.id, id)),
    );
    if (!row) throw new ApiError(404, "integration_not_found", "Integration not found");
    if (!(await isAdmin(db, claims, row.orgId)))
      throw new ApiError(403, "forbidden", "Only owners and admins can test integrations");
    return c.json(await deps.workflows.testIntegration(id), 200);
  });

  app.openapi(routes.attachIntegration, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const body = c.req.valid("json");
    await withUserSession(db, claims, async (tx) => {
      const [bot] = await tx.select({ orgId: bots.orgId }).from(bots).where(eq(bots.id, id));
      if (!bot) throw new ApiError(404, "bot_not_found", "Bot not found");
      // A local MCP server runs on someone's own computer: only they choose which bots use it.
      const [local] = await tx.execute<{ owner: string | null }>(sql`
        select config->>'owner_user_id' as owner from public.integrations
        where id = ${body.integration_id}::uuid and kind = 'local_mcp'`);
      if (local && local.owner !== claims.sub)
        throw new ApiError(
          403,
          "forbidden",
          "Only the person whose computer runs this server can attach it",
        );
      try {
        await tx.execute(sql`
          insert into public.bot_integrations (org_id, bot_id, integration_id, tool_allowlist)
          values (${bot.orgId}::uuid, ${id}::uuid, ${body.integration_id}::uuid, ${body.tool_allowlist ? `{${body.tool_allowlist.map((t) => `"${t.replaceAll('"', "")}"`).join(",")}}` : null}::text[])
          on conflict (bot_id, integration_id) do update set tool_allowlist = excluded.tool_allowlist`);
      } catch (err) {
        if (pgErrorCode(err) === "42501")
          throw new ApiError(404, "not_found", "Bot or integration not found");
        throw err;
      }
    });
    return c.json({ ok: true }, 200);
  });

  // --- routines -------------------------------------------------------------------

  app.openapi(routes.listRoutines, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const rows = await withUserSession(db, claims, (tx) =>
      tx.select().from(routines).where(eq(routines.botId, id)).orderBy(routines.createdAt),
    );
    return c.json({ items: rows.map(routineOut) }, 200);
  });

  app.openapi(routes.createRoutine, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const body = c.req.valid("json");
    const trigger = body.trigger ?? "schedule";
    const [bot] = await withUserSession(db, claims, (tx) =>
      tx.select().from(bots).where(eq(bots.id, body.bot_id)),
    );
    if (!bot) throw new ApiError(404, "bot_not_found", "Bot not found");
    const [profile] = await db.execute<{ timezone: string }>(
      sql`select timezone from public.profiles where user_id = ${claims.sub}::uuid`,
    );
    const tz = body.timezone ?? profile?.timezone ?? "UTC";
    if (!isValidTimezone(tz))
      throw new ApiError(400, "validation_failed", `Unknown timezone ${tz}`, {
        errors: [{ path: "timezone", message: "Unknown timezone" }],
      });
    if (trigger === "schedule" && (!body.schedule_cron || !isValidCron(body.schedule_cron))) {
      throw new ApiError(400, "validation_failed", "A 5-field cron expression is required", {
        errors: [{ path: "schedule_cron", message: "Invalid cron" }],
      });
    }
    if (trigger === "once" && (!body.run_at || Date.parse(body.run_at) < Date.now() - 60_000)) {
      throw new ApiError(400, "validation_failed", "A once routine needs a run_at in the future", {
        errors: [{ path: "run_at", message: "Pick a time in the future" }],
      });
    }
    let webhookSecret: string | undefined;
    let triggerJson: Record<string, unknown> = { type: trigger };
    if (trigger === "github" || trigger === "webhook") {
      webhookSecret = randomBytes(24).toString("hex");
      triggerJson = {
        type: trigger,
        vault_secret_id: await vault(webhookSecret, "routine webhook"),
        ...(body.events ? { events: body.events } : {}),
      };
    }
    const cron = trigger === "schedule" ? (body.schedule_cron as string) : null;
    const [row] = await db
      .insert(routines)
      .values({
        orgId: bot.orgId,
        botId: bot.id,
        createdBy: claims.sub,
        name: body.name,
        instructionsMd: body.instructions,
        scheduleCron: cron,
        timezone: tz,
        trigger: triggerJson,
        notify: body.notify ?? true,
        nextRunAt: cron
          ? nextRunAt(cron, tz).toISOString()
          : trigger === "once"
            ? new Date(body.run_at as string).toISOString()
            : null,
      })
      .returning();
    if (!row) throw new Error("routine insert returned nothing");
    const base = new URL(c.req.url).origin;
    return c.json(
      {
        ...routineOut(row),
        ...(webhookSecret
          ? {
              webhook_secret: webhookSecret,
              webhook_url: `${base}/hooks/${trigger === "github" ? "github" : "custom"}/${row.id}`,
            }
          : {}),
      },
      201,
    );
  });

  app.openapi(routes.updateRoutine, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const body = c.req.valid("json");
    const [cur] = await withUserSession(db, claims, (tx) =>
      tx.select().from(routines).where(eq(routines.id, id)),
    );
    if (!cur) throw new ApiError(404, "routine_not_found", "Routine not found");
    const tz = body.timezone ?? cur.timezone;
    const isOnce = (cur.trigger as { type?: string })?.type === "once";
    const cron = isOnce ? null : (body.schedule_cron ?? cur.scheduleCron);
    if (!isValidTimezone(tz))
      throw new ApiError(400, "validation_failed", `Unknown timezone ${tz}`);
    if (body.schedule_cron && !isValidCron(body.schedule_cron))
      throw new ApiError(400, "validation_failed", "Invalid cron expression");
    const [row] = await withUserSession(db, claims, (tx) =>
      tx
        .update(routines)
        .set({
          name: body.name ?? cur.name,
          instructionsMd: body.instructions ?? cur.instructionsMd,
          scheduleCron: cron,
          timezone: tz,
          notify: body.notify ?? cur.notify,
          enabled: body.enabled ?? cur.enabled,
          nextRunAt: !(body.enabled ?? cur.enabled)
            ? null
            : isOnce
              ? body.run_at
                ? new Date(body.run_at).toISOString()
                : cur.nextRunAt
                  ? iso(cur.nextRunAt)
                  : null
              : cron
                ? nextRunAt(cron, tz).toISOString()
                : null,
        })
        .where(eq(routines.id, id))
        .returning(),
    );
    return c.json(routineOut(row as RoutineRow), 200);
  });

  app.openapi(routes.deleteRoutine, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const [row] = await withUserSession(db, claims, (tx) =>
      tx
        .delete(routines)
        .where(eq(routines.id, id))
        .returning({ id: routines.id, botId: routines.botId }),
    );
    if (!row) throw new ApiError(404, "routine_not_found", "Routine not found");
    return c.json({ deleted: row.id }, 200);
  });

  app.openapi(routes.runRoutine, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const [cur] = await withUserSession(db, claims, (tx) =>
      tx.select({ id: routines.id }).from(routines).where(eq(routines.id, id)),
    );
    if (!cur) throw new ApiError(404, "routine_not_found", "Routine not found");
    const { runRoutineNow } = await import("../../worker/routines.ts");
    const runId = await runRoutineNow(db, id);
    await deps.workflows.startRun(runId);
    return c.json({ run_id: runId }, 202);
  });

  // --- templates and tasks -----------------------------------------------------------

  app.openapi(routes.listTemplates, async (c) => {
    requireClaims(c.get("claims"));
    return c.json(
      {
        items: BOT_TEMPLATES.map((t) => ({
          id: t.id,
          name: t.name,
          description: t.description,
          autonomy: t.autonomy,
          skills: t.skills.map((s) => s.name),
          routines: (t.routines ?? []).map((r) => ({
            name: r.name,
            schedule_cron: r.schedule_cron,
          })),
          persona: t.persona,
          category: t.category,
          icon: t.icon,
          mascot: t.mascot,
          starters: t.starters,
        })),
      },
      200,
    );
  });

  type TaskRow = typeof tasks.$inferSelect;
  const taskOut = (t: TaskRow, comments = 0) => ({
    id: t.id,
    title: t.title,
    details_md: t.detailsMd,
    status: t.status as "todo",
    priority: t.priority as "none",
    assignee_bot_id: t.assigneeBotId,
    assignee_user_id: t.assigneeUserId ?? null,
    created_by_bot_id: t.createdByBotId,
    created_by_user_id: t.createdByUserId ?? null,
    result_md: t.resultMd,
    due_at: t.dueAt ? iso(t.dueAt) : null,
    labels: t.labels ?? [],
    position: Number(t.position ?? 0),
    review_required: t.reviewRequired ?? false,
    conversation_id: t.conversationId ?? null,
    comments,
    updated_at: iso(t.updatedAt),
    created_at: iso(t.createdAt),
  });
  const commentCounts = async (ids: string[]) => {
    if (!ids.length) return new Map<string, number>();
    const rows = await db.execute<{ task_id: string; n: number }>(sql`
      select task_id, count(*)::int as n from public.task_comments
      where task_id = any(${`{${ids.join(",")}}`}::uuid[]) group by task_id`);
    return new Map(rows.map((r) => [r.task_id, r.n]));
  };
  /** Bots and people a ticket is given to must be in its workspace. */
  const checkAssignees = async (orgId: string, botId?: string | null, userId?: string | null) => {
    if (botId) {
      const [b] = await db.execute<{ id: string }>(
        sql`select id from public.bots where id = ${botId}::uuid and org_id = ${orgId}::uuid`,
      );
      if (!b) throw new ApiError(400, "bad_assignee", "That bot is not in this workspace");
    }
    if (userId) {
      const [m] = await db.execute<{ id: string }>(
        sql`select id from public.memberships where user_id = ${userId}::uuid and org_id = ${orgId}::uuid`,
      );
      if (!m) throw new ApiError(400, "bad_assignee", "That person is not in this workspace");
    }
  };
  const startWork = (ticketId: string, actor: string, comment?: string) =>
    startTicketWork(db, { ticketId, actorUserId: actor, comment }, (runId) =>
      deps.workflows.startRun(runId),
    );

  app.openapi(routes.listTasks, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { org_id } = c.req.valid("query");
    if (!(await isMember(db, claims, org_id))) return c.json({ items: [] }, 200);
    const rows = await withUserSession(db, claims, (tx) =>
      tx
        .select()
        .from(tasks)
        .where(eq(tasks.orgId, org_id))
        .orderBy(tasks.position, desc(tasks.updatedAt))
        .limit(500),
    );
    const counts = await commentCounts(rows.map((r) => r.id));
    return c.json({ items: rows.map((t) => taskOut(t, counts.get(t.id) ?? 0)) }, 200);
  });

  app.openapi(routes.createTask, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const b = c.req.valid("json");
    if (!(await isMember(db, claims, b.org_id)))
      throw new ApiError(404, "org_not_found", "Workspace not found");
    await checkAssignees(b.org_id, b.assignee_bot_id, b.assignee_user_id);
    const [row] = await withUserSession(db, claims, (tx) =>
      tx
        .insert(tasks)
        .values({
          orgId: b.org_id,
          title: b.title,
          detailsMd: b.details_md ?? "",
          status: b.status ?? "todo",
          priority: b.priority ?? "none",
          assigneeBotId: b.assignee_bot_id ?? null,
          assigneeUserId: b.assignee_user_id ?? null,
          dueAt: b.due_at ?? null,
          labels: b.labels ?? [],
          reviewRequired: b.review_required ?? false,
          createdByUserId: claims.sub,
          position: Date.now() / 1000,
        })
        .returning(),
    );
    if (!row) throw new Error("task insert returned nothing");
    if (row.assigneeBotId) await startWork(row.id, claims.sub);
    const [fresh] = await db.select().from(tasks).where(eq(tasks.id, row.id));
    return c.json(taskOut(fresh ?? row), 201);
  });

  app.openapi(routes.updateTask, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const b = c.req.valid("json");
    const [cur] = await withUserSession(db, claims, (tx) =>
      tx.select().from(tasks).where(eq(tasks.id, id)),
    );
    if (!cur) throw new ApiError(404, "task_not_found", "Ticket not found");
    await checkAssignees(cur.orgId, b.assignee_bot_id, b.assignee_user_id);
    const [row] = await withUserSession(db, claims, (tx) =>
      tx
        .update(tasks)
        .set({
          ...(b.title !== undefined ? { title: b.title } : {}),
          ...(b.details_md !== undefined ? { detailsMd: b.details_md } : {}),
          ...(b.status !== undefined ? { status: b.status } : {}),
          ...(b.priority !== undefined ? { priority: b.priority } : {}),
          ...(b.assignee_bot_id !== undefined ? { assigneeBotId: b.assignee_bot_id } : {}),
          ...(b.assignee_user_id !== undefined ? { assigneeUserId: b.assignee_user_id } : {}),
          ...(b.due_at !== undefined ? { dueAt: b.due_at } : {}),
          ...(b.labels !== undefined ? { labels: b.labels } : {}),
          ...(b.review_required !== undefined ? { reviewRequired: b.review_required } : {}),
          ...(b.position !== undefined ? { position: b.position } : {}),
          updatedAt: sql`now()`,
        })
        .where(eq(tasks.id, id))
        .returning(),
    );
    if (!row) throw new ApiError(404, "task_not_found", "Ticket not found");
    // A newly assigned bot starts on it (moving a ticket by hand never wakes a bot).
    if (row.assigneeBotId && row.assigneeBotId !== cur.assigneeBotId && row.status !== "done")
      await startWork(row.id, claims.sub);
    const [fresh] = await db.select().from(tasks).where(eq(tasks.id, id));
    const counts = await commentCounts([id]);
    return c.json(taskOut(fresh ?? row, counts.get(id) ?? 0), 200);
  });

  app.openapi(routes.deleteTask, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const rows = await withUserSession(db, claims, (tx) =>
      tx.delete(tasks).where(eq(tasks.id, id)).returning({ id: tasks.id }),
    );
    if (!rows.length) throw new ApiError(404, "task_not_found", "Ticket not found");
    return c.body(null, 204);
  });

  const commentOut = (r: {
    id: string;
    task_id: string;
    author_type: string;
    author_user_id: string | null;
    author_bot_id: string | null;
    body_md: string;
    created_at: Date | string;
  }) => ({ ...r, author_type: r.author_type as "user", created_at: iso(r.created_at) });

  app.openapi(routes.listTaskComments, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const rows = await withUserSession(db, claims, (tx) =>
      tx.execute<Parameters<typeof commentOut>[0]>(sql`
        select id, task_id, author_type, author_user_id, author_bot_id, body_md, created_at
        from public.task_comments where task_id = ${id}::uuid order by created_at`),
    );
    return c.json({ items: rows.map(commentOut) }, 200);
  });

  app.openapi(routes.createTaskComment, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const { body_md } = c.req.valid("json");
    const [t] = await withUserSession(db, claims, (tx) =>
      tx.select().from(tasks).where(eq(tasks.id, id)),
    );
    if (!t) throw new ApiError(404, "task_not_found", "Ticket not found");
    const [row] = await withUserSession(db, claims, (tx) =>
      tx.execute<Parameters<typeof commentOut>[0]>(sql`
        insert into public.task_comments (org_id, task_id, author_type, author_user_id, body_md)
        values (${t.orgId}::uuid, ${id}::uuid, 'user', ${claims.sub}::uuid, ${body_md})
        returning id, task_id, author_type, author_user_id, author_bot_id, body_md, created_at`),
    );
    if (!row) throw new Error("comment insert returned nothing");
    await db.execute(sql`update public.tasks set updated_at = now() where id = ${id}::uuid`);
    // A person's comment on a bot's ticket wakes that bot.
    if (t.assigneeBotId && t.status !== "done") await startWork(id, claims.sub, body_md);
    return c.json(commentOut(row), 201);
  });

  // --- webhooks (no JWT; the worker verifies the HMAC signature) --------------------

  const webhook =
    (kind: "github" | "custom") => async (c: Parameters<Parameters<typeof app.openapi>[1]>[0]) => {
      const routineId = c.req.param("routine_id") as string;
      const length = Number(c.req.header("content-length") ?? 0);
      if (length > MAX_WEBHOOK_BODY) return c.json({ accepted: false }, 413 as never);
      const body = await c.req.text();
      if (body.length > MAX_WEBHOOK_BODY) return c.json({ accepted: false }, 413 as never);
      const headers: Record<string, string> = {};
      for (const h of [
        "x-hub-signature-256",
        "x-github-event",
        "x-kasama-signature",
        "x-kasama-event",
      ]) {
        const v = c.req.header(h);
        if (v) headers[h] = v;
      }
      await deps.workflows.routineWebhook(routineId, kind, body, headers);
      return c.json({ accepted: true }, 202);
    };
  app.openapi(routes.githubWebhook, webhook("github") as never);
  app.openapi(routes.customWebhook, webhook("custom") as never);
}
