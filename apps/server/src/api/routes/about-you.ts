/**
 * About you (D-169): the person's own profile. Reads and writes go through here rather than
 * straight to Supabase because the text is sealed with the person's key when they belong to a
 * workspace that encrypts (D-136); reads through this client are opened transparently.
 */
import { routes } from "@casama/contracts";
import { contentKeys } from "@casama/db";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { sql } from "drizzle-orm";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";

type FactRow = {
  id: string;
  kind: "fact" | "preference";
  content: string;
  pinned: boolean;
  updated_at: string | Date;
};
const fact = (r: FactRow) => ({
  id: r.id,
  kind: r.kind,
  content: r.content,
  pinned: r.pinned,
  updated_at: new Date(r.updated_at).toISOString(),
});
const orNull = (s: string | null | undefined) => {
  const t = s?.trim().replace(/\s+/g, " ") ?? "";
  return t ? t : null;
};

export function registerAboutYouRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;
  const me = (c: { get(k: "claims"): AppEnv["Variables"]["claims"] }) => {
    const claims = c.get("claims");
    if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
    return claims.sub;
  };

  const read = async (userId: string) => {
    const [r] = await db.execute<{
      display_name: string | null;
      preferred_name: string | null;
      pronouns: string | null;
      about: string | null;
      reply_style: string | null;
      learn: boolean | null;
      name_asked_at: string | null;
    }>(sql`
      select p.display_name, p.preferred_name, p.pronouns, a.about, a.reply_style, a.learn, a.name_asked_at
      from public.profiles p left join public.user_about a on a.user_id = p.user_id
      where p.user_id = ${userId}::uuid`);
    return {
      display_name: r?.display_name ?? null,
      preferred_name: r?.preferred_name ?? null,
      pronouns: r?.pronouns ?? null,
      about: r?.about ?? "",
      reply_style: r?.reply_style ?? "",
      learn: r?.learn ?? true,
      name_asked: !!r?.name_asked_at || !!orNull(r?.preferred_name),
    };
  };

  app.openapi(routes.getAboutYou, async (c) => c.json(await read(me(c)), 200));

  app.openapi(routes.updateAboutYou, async (c) => {
    const userId = me(c);
    const b = c.req.valid("json");
    if (b.preferred_name !== undefined || b.pronouns !== undefined)
      await db.execute(sql`
        update public.profiles set
          preferred_name = case when ${b.preferred_name !== undefined} then ${orNull(b.preferred_name)} else preferred_name end,
          pronouns = case when ${b.pronouns !== undefined} then ${orNull(b.pronouns)} else pronouns end
        where user_id = ${userId}::uuid`);
    const seal = (t: string | undefined) =>
      t === undefined ? null : contentKeys.sealForUser(userId, t.trim());
    await db.execute(sql`
      insert into public.user_about (user_id, about, reply_style, learn, name_asked_at)
      values (${userId}::uuid, coalesce(${seal(b.about)}, ''), coalesce(${seal(b.reply_style)}, ''),
              coalesce(${b.learn ?? null}::boolean, true), ${b.name_asked || b.preferred_name ? sql`now()` : sql`null`})
      on conflict (user_id) do update set
        about = coalesce(${seal(b.about)}, public.user_about.about),
        reply_style = coalesce(${seal(b.reply_style)}, public.user_about.reply_style),
        learn = coalesce(${b.learn ?? null}::boolean, public.user_about.learn),
        name_asked_at = coalesce(public.user_about.name_asked_at, ${b.name_asked || b.preferred_name ? sql`now()` : sql`null`}),
        updated_at = now()`);
    return c.json(await read(userId), 200);
  });

  app.openapi(routes.listUserFacts, async (c) => {
    const rows = await db.execute<FactRow>(sql`
      select id, kind, content, pinned, updated_at from public.user_facts
      where user_id = ${me(c)}::uuid order by pinned desc, updated_at desc`);
    return c.json({ items: rows.map(fact) }, 200);
  });

  app.openapi(routes.addUserFacts, async (c) => {
    const userId = me(c);
    const added: FactRow[] = [];
    for (const f of c.req.valid("json").items) {
      const [r] = await db.execute<FactRow>(sql`
        insert into public.user_facts (user_id, kind, content)
        values (${userId}::uuid, ${f.kind ?? "fact"}, ${contentKeys.sealForUser(userId, f.content.trim())})
        returning id, kind, content, pinned, updated_at`);
      if (r) added.push(r);
    }
    return c.json({ items: added.map(fact) }, 200);
  });

  app.openapi(routes.updateUserFact, async (c) => {
    const userId = me(c);
    const { id } = c.req.valid("param");
    const b = c.req.valid("json");
    const [r] = await db.execute<FactRow>(sql`
      update public.user_facts set
        content = coalesce(${b.content === undefined ? null : contentKeys.sealForUser(userId, b.content.trim())}, content),
        pinned = coalesce(${b.pinned ?? null}::boolean, pinned),
        updated_at = now()
      where id = ${id}::uuid and user_id = ${userId}::uuid
      returning id, kind, content, pinned, updated_at`);
    if (!r) throw new ApiError(404, "fact_not_found", "No such fact");
    return c.json(fact(r), 200);
  });

  app.openapi(routes.deleteUserFact, async (c) => {
    const { id } = c.req.valid("param");
    const [r] = await db.execute<{ id: string }>(sql`
      delete from public.user_facts where id = ${id}::uuid and user_id = ${me(c)}::uuid returning id`);
    if (!r) throw new ApiError(404, "fact_not_found", "No such fact");
    return c.json({ deleted: r.id }, 200);
  });

  const member = async (userId: string, orgId: string) => {
    const [m] = await db.execute<{ ok: boolean }>(sql`
      select true as ok from public.memberships where org_id = ${orgId}::uuid and user_id = ${userId}::uuid`);
    if (!m) throw new ApiError(404, "workspace_not_found", "Workspace not found");
  };
  const shared = async (userId: string, orgId: string) => {
    const [r] = await db.execute<{ shared: boolean }>(
      sql`select public.profile_shared_in(${userId}::uuid, ${orgId}::uuid) as shared`,
    );
    return { org_id: orgId, shared: !!r?.shared };
  };

  app.openapi(routes.getProfileSpace, async (c) => {
    const userId = me(c);
    const { org_id } = c.req.valid("param");
    await member(userId, org_id);
    return c.json(await shared(userId, org_id), 200);
  });

  app.openapi(routes.setProfileSpace, async (c) => {
    const userId = me(c);
    const { org_id } = c.req.valid("param");
    await member(userId, org_id);
    await db.execute(sql`
      insert into public.profile_spaces (user_id, org_id, share_about)
      values (${userId}::uuid, ${org_id}::uuid, ${c.req.valid("json").shared})
      on conflict (user_id, org_id) do update set share_about = excluded.share_about, updated_at = now()`);
    return c.json(await shared(userId, org_id), 200);
  });
}
