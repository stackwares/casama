/** Share a bot as a template (D-110): export, share links, preview and import. */
import { createHash, randomBytes } from "node:crypto";
import type { OpenAPIHono, z } from "@hono/zod-openapi";
import { type BotTemplateFile, routes } from "@kasama/contracts";
import { type Database, type JwtClaims, withUserSession, contentKeys } from "@kasama/db";
import { isValidCron, isValidTimezone, nextRunAt } from "@kasama/domain";
import { sql } from "drizzle-orm";
import { enforceLimit } from "../../billing/limits.ts";
import { checkBundle } from "../../services/skills.ts";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";

type Template = z.infer<typeof BotTemplateFile>;
const hash = (t: string) => createHash("sha256").update(t).digest("hex");

const claimsOf = (c: { get(k: "claims"): JwtClaims | undefined }) => {
  const claims = c.get("claims");
  if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
  return claims;
};

/** The bot as a template. Only what the caller can see; memories only when they manage the bot. */
export async function exportTemplate(
  db: Database,
  claims: JwtClaims,
  botId: string,
  withMemories: boolean,
): Promise<Template> {
  const [bot] = await withUserSession(db, claims, (tx) =>
    tx.execute<{
      name: string;
      persona_md: string;
      autonomy: Template["autonomy"];
      avatar_url: string | null;
      manage: boolean;
    }>(sql`
      select name, persona_md, autonomy, avatar_url, public.can_manage_bot(id) as manage from public.bots where id = ${botId}::uuid`),
  );
  if (!bot) throw new ApiError(404, "bot_not_found", "Bot not found");
  const skills = await db.execute<{
    id: string;
    name: string;
    description: string;
    body_md: string;
  }>(sql`
    select id, name, description, body_md from public.skills where bot_id = ${botId}::uuid and enabled order by name`);
  const files = skills.length
    ? await db.execute<{
        skill_id: string;
        path: string;
        content: string;
        executable: boolean;
      }>(sql`
        select skill_id, path, encode(content, 'base64') as content, executable from public.skill_files
        where skill_id in (select id from public.skills where bot_id = ${botId}::uuid) order by path`)
    : [];
  const routines = await db.execute<{
    name: string;
    instructions_md: string;
    schedule_cron: string;
  }>(sql`
    select name, instructions_md, schedule_cron from public.routines
    where bot_id = ${botId}::uuid and schedule_cron is not null order by name`);
  const connections = await db.execute<{ kind: string; name: string }>(sql`
    select distinct i.kind, i.name from public.bot_integrations bi join public.integrations i on i.id = bi.integration_id
    where bi.bot_id = ${botId}::uuid order by i.kind, i.name`);
  const memories =
    withMemories && bot.manage
      ? await db.execute<{
          kind: NonNullable<Template["memories"]>[number]["kind"];
          content: string;
        }>(sql`
          select kind, content from public.memories where bot_id = ${botId}::uuid order by pinned desc, importance desc limit 200`)
      : [];
  return {
    format: "kasama.bot",
    version: 1,
    name: bot.name,
    description: "",
    persona_md: bot.persona_md,
    autonomy: bot.autonomy,
    // Only built-in mascots travel; uploaded pictures stay in this workspace.
    avatar: bot.avatar_url?.startsWith("mascot:") ? bot.avatar_url : null,
    skills: skills.map((k) => ({
      name: k.name,
      description: k.description,
      body_md: k.body_md,
      files: files
        .filter((f) => f.skill_id === k.id)
        .map((f) => ({ path: f.path, content_base64: f.content, executable: f.executable })),
    })),
    routines: [...routines],
    connections: [...connections],
    memories: [...memories],
  };
}

export function registerBotTemplateRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;

  app.openapi(routes.exportBot, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    return c.json(
      await exportTemplate(db, claims, id, c.req.valid("query").memories === "true"),
      200,
    );
  });

  app.openapi(routes.createBotShare, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    const body = c.req.valid("json");
    const [bot] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ org_id: string; manage: boolean }>(
        sql`select org_id, public.can_manage_bot(id) as manage from public.bots where id = ${id}::uuid`,
      ),
    );
    if (!bot) throw new ApiError(404, "bot_not_found", "Bot not found");
    if (!bot.manage)
      throw new ApiError(403, "forbidden", "Only people who manage this bot can share it");
    const snapshot = await exportTemplate(db, claims, id, body.include_memories);
    const token = randomBytes(24).toString("base64url");
    const [row] = await db.execute<{ expires_at: string | null }>(sql`
      insert into public.bot_shares (org_id, bot_id, token_hash, snapshot, created_by, expires_at)
      values (${bot.org_id}::uuid, ${id}::uuid, ${hash(token)}, ${JSON.stringify(snapshot)}::jsonb, ${claims.sub}::uuid,
              ${body.expires_in_days ? new Date(Date.now() + body.expires_in_days * 86_400_000).toISOString() : null}::timestamptz)
      returning expires_at`);
    await db.execute(sql`insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id, metadata)
      values (${bot.org_id}::uuid, 'user', ${claims.sub}::uuid, 'bot.shared', 'bot', ${id}::uuid, ${JSON.stringify({ memories: body.include_memories })}::jsonb)`);
    return c.json(
      {
        token,
        url: `${deps.env.PUBLIC_APP_URL.replace(/\/$/, "")}/import/${token}`,
        expires_at: row?.expires_at ? new Date(row.expires_at).toISOString() : null,
      },
      201,
    );
  });

  app.openapi(routes.getBotShare, async (c) => {
    claimsOf(c);
    const { token } = c.req.valid("param");
    const [row] = await db.execute<{ snapshot: Template }>(sql`
      select snapshot from public.bot_shares where token_hash = ${hash(token)}
        and revoked_at is null and (expires_at is null or expires_at > now())`);
    if (!row)
      throw new ApiError(
        404,
        "share_not_found",
        "This link doesn't work anymore. Ask for a new one.",
      );
    return c.json(row.snapshot, 200);
  });

  app.openapi(routes.importBot, async (c) => {
    const claims = claimsOf(c);
    const body = c.req.valid("json");
    const t = {
      ...body.template,
      skills: (body.template.skills ?? []).map((k) => ({ ...k, files: k.files ?? [] })),
      routines: body.template.routines ?? [],
      connections: body.template.connections ?? [],
      memories: body.template.memories ?? [],
    };
    for (const k of t.skills)
      checkBundle(
        k.files.map((f) => ({
          path: f.path,
          content: Buffer.from(f.content_base64, "base64"),
          executable: f.executable ?? false,
        })),
      );
    for (const r of t.routines)
      if (!isValidCron(r.schedule_cron))
        throw new ApiError(400, "invalid_cron", `Routine "${r.name}" has an invalid schedule.`);
    await enforceLimit(db, body.org_id, "max_bots");
    const botId = await withUserSession(db, claims, async (tx) => {
      const [cred] = await tx.execute<{ id: string }>(sql`
        select id from public.model_credentials where id = ${body.credential_id}::uuid and org_id = ${body.org_id}::uuid`);
      if (!cred)
        throw new ApiError(400, "credential_not_found", "Pick a model key from this workspace");
      const [b] = await tx.execute<{ id: string }>(sql`
        insert into public.bots (org_id, created_by, name, persona_md, model_policy, autonomy, avatar_url)
        values (${body.org_id}::uuid, ${claims.sub}::uuid, ${t.name}, ${t.persona_md},
                ${JSON.stringify({ primary: { credential_id: body.credential_id, model: body.model } })}::jsonb,
                ${t.autonomy}, ${t.avatar?.startsWith("mascot:") ? t.avatar : null})
        returning id`);
      if (!b) throw new ApiError(403, "forbidden", "You can't create bots in this workspace");
      return b.id;
    });
    const [tz] = await db.execute<{ timezone: string | null }>(
      sql`select timezone from public.profiles where user_id = ${claims.sub}::uuid`,
    );
    const zone = tz?.timezone && isValidTimezone(tz.timezone) ? tz.timezone : "UTC";
    await db.transaction(async (tx) => {
      for (const k of t.skills) {
        const [s] = await tx.execute<{ id: string }>(sql`
          insert into public.skills (org_id, bot_id, name, description, body_md, source)
          values (${body.org_id}::uuid, ${botId}::uuid, ${k.name}, ${k.description}, ${k.body_md}, 'manual') returning id`);
        for (const f of k.files)
          await tx.execute(sql`
            insert into public.skill_files (org_id, skill_id, path, content, executable)
            values (${body.org_id}::uuid, ${s?.id}::uuid, ${f.path}, decode(${f.content_base64}, 'base64'), ${f.executable ?? false})`);
      }
      if (body.include_routines)
        for (const r of t.routines)
          await tx.execute(sql`
            insert into public.routines (org_id, bot_id, created_by, name, instructions_md, schedule_cron, timezone, trigger, notify, next_run_at)
            values (${body.org_id}::uuid, ${botId}::uuid, ${claims.sub}::uuid, ${r.name}, ${r.instructions_md}, ${r.schedule_cron},
                    ${zone}, '{"type":"schedule"}'::jsonb, true, ${nextRunAt(r.schedule_cron, zone).toISOString()}::timestamptz)`);
      if (body.include_memories)
        for (const m of t.memories)
          await tx.execute(sql`
            insert into public.memories (org_id, bot_id, kind, content) values (${body.org_id}::uuid, ${botId}::uuid, ${m.kind}, ${contentKeys.seal(body.org_id, m.content)})`);
    });
    await db.execute(sql`insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id, metadata)
      values (${body.org_id}::uuid, 'user', ${claims.sub}::uuid, 'bot.imported', 'bot', ${botId}::uuid, ${JSON.stringify({ name: t.name })}::jsonb)`);
    return c.json(
      {
        bot_id: botId,
        skills: t.skills.length,
        routines: body.include_routines ? t.routines.length : 0,
        memories: body.include_memories ? t.memories.length : 0,
        connections_to_add: t.connections,
      },
      201,
    );
  });
}
