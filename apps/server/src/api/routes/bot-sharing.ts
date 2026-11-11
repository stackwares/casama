/** Bot sharing (D-131): a bot's visibility and access list (chat, edit, admin) by person or role. */

import { routes } from "@casama/contracts";
import { type JwtClaims, withUserSession } from "@casama/db";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { sql } from "drizzle-orm";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";

const claimsOf = (c: { get(k: "claims"): JwtClaims | undefined }) => {
  const claims = c.get("claims");
  if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
  return claims;
};

export function registerBotSharingRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;

  const view = async (claims: JwtClaims, id: string) => {
    const [b] = await withUserSession(db, claims, (tx) =>
      tx.execute<{
        org_id: string;
        visibility: "private" | "team";
        created_by: string | null;
        admin: boolean;
        manage: boolean;
      }>(sql`
        select org_id, visibility, created_by, public.can_admin_bot(id) as admin, public.can_manage_bot(id) as manage
        from public.bots where id = ${id}::uuid`),
    );
    if (!b) throw new ApiError(404, "bot_not_found", "Bot not found");
    const entries = await db.execute<{
      user_id: string | null;
      email: string | null;
      role: "member" | null;
      access: "chat";
    }>(sql`
      select a.user_id, u.email, a.role, a.access from public.bot_access a left join auth.users u on u.id = a.user_id
      where a.bot_id = ${id}::uuid order by a.role nulls last, u.email`);
    return {
      bot: b,
      out: {
        visibility: b.visibility,
        created_by: b.created_by,
        entries: [...entries],
        can_admin: b.admin,
        your_access: (b.admin ? "admin" : b.manage ? "edit" : "chat") as "admin" | "edit" | "chat",
      },
    };
  };

  app.openapi(routes.getBotAccess, async (c) => {
    const claims = claimsOf(c);
    return c.json((await view(claims, c.req.valid("param").id)).out, 200);
  });

  app.openapi(routes.setBotAccess, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    const { bot } = await view(claims, id);
    if (!bot.admin)
      throw new ApiError(
        403,
        "forbidden",
        "Only the bot's creator, its admins and workspace admins can change who has access",
      );
    const b = c.req.valid("json");
    for (const e of b.entries)
      if (!!e.user_id === !!e.role)
        throw new ApiError(400, "validation_failed", "Each entry names one person or one role");
    const people = b.entries.filter((e) => e.user_id).map((e) => e.user_id as string);
    if (people.length) {
      const members = await db.execute<{ user_id: string }>(sql`
        select user_id from public.memberships where org_id = ${bot.org_id}::uuid
          and user_id = any(array(select jsonb_array_elements_text(${JSON.stringify(people)}::jsonb))::uuid[])`);
      if (members.length !== new Set(people).size)
        throw new ApiError(400, "not_a_member", "Everyone on the list must be in this workspace");
    }
    await db.transaction(async (tx) => {
      await tx.execute(
        sql`update public.bots set visibility = ${b.visibility} where id = ${id}::uuid`,
      );
      await tx.execute(sql`delete from public.bot_access where bot_id = ${id}::uuid`);
      for (const e of b.entries)
        await tx.execute(sql`
          insert into public.bot_access (bot_id, org_id, user_id, role, access, created_by)
          values (${id}::uuid, ${bot.org_id}::uuid, ${e.user_id ?? null}::uuid, ${e.role ?? null}::public.org_role, ${e.access}, ${claims.sub}::uuid)
          on conflict do nothing`);
      await tx.execute(sql`insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id, metadata)
        values (${bot.org_id}::uuid, 'user', ${claims.sub}::uuid, 'bot.access_changed', 'bot', ${id}::uuid,
                ${JSON.stringify({ visibility: b.visibility, entries: b.entries.length })}::jsonb)`);
    });
    return c.json((await view(claims, id)).out, 200);
  });

  app.openapi(routes.listMembers, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    const [m] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ ok: boolean }>(sql`select public.is_member(${id}::uuid) as ok`),
    );
    if (!m?.ok) throw new ApiError(404, "org_not_found", "Workspace not found");
    const rows = await db.execute<{
      user_id: string;
      email: string | null;
      role: "member";
      name: string | null;
      pronouns: string | null;
    }>(sql`
      select m.user_id, u.email, m.role,
             coalesce(nullif(btrim(p.preferred_name), ''), nullif(btrim(p.display_name), '')) as name,
             nullif(btrim(p.pronouns), '') as pronouns
      from public.memberships m left join auth.users u on u.id = m.user_id
      left join public.profiles p on p.user_id = m.user_id
      where m.org_id = ${id}::uuid order by m.role, u.email`);
    return c.json({ items: [...rows] }, 200);
  });
}
