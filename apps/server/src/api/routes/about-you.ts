/**
 * About you (D-169): the person's own profile. Reads and writes go through here rather than
 * straight to Supabase because the text is sealed with the person's key when they belong to a
 * workspace that encrypts (D-136); reads through this client are opened transparently.
 */
import { welcomeNameAnswered } from "@casama/agent";
import { routes } from "@casama/contracts";
import { contentKeys } from "@casama/db";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { sql } from "drizzle-orm";
import {
  fetchProviderPhoto,
  MAX_PHOTO_BYTES,
  providerPhotoUrl,
  sniffPhotoType,
} from "../../services/profile-photos.ts";
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
      photo_id: string | null;
      photo_import_tried_at: string | null;
      meta: Record<string, unknown> | null;
    }>(sql`
      select p.display_name, p.preferred_name, p.pronouns, a.about, a.reply_style, a.learn, a.name_asked_at,
             ph.id as photo_id, p.photo_import_tried_at, u.raw_user_meta_data as meta
      from public.profiles p left join public.user_about a on a.user_id = p.user_id
      left join public.profile_photos ph on ph.user_id = p.user_id
      left join auth.users u on u.id = p.user_id
      where p.user_id = ${userId}::uuid`);
    return {
      display_name: r?.display_name ?? null,
      preferred_name: r?.preferred_name ?? null,
      pronouns: r?.pronouns ?? null,
      about: r?.about ?? "",
      reply_style: r?.reply_style ?? "",
      learn: r?.learn ?? true,
      name_asked: !!r?.name_asked_at || !!orNull(r?.preferred_name),
      photo_id: r?.photo_id ?? null,
      provider_photo: !!providerPhotoUrl(r?.meta),
      photo_import_tried: !!r?.photo_import_tried_at,
    };
  };

  // Profile photos (D-202). A new photo replaces the old one under a new id, so cached copies of
  // the old address never show the new picture or the other way round.
  const savePhoto = async (
    userId: string,
    bytes: Uint8Array,
    type: string,
    source: "upload" | "provider",
  ) => {
    await db.execute(sql`
      insert into public.profile_photos (user_id, content_type, bytes, source)
      values (${userId}::uuid, ${type}, ${Buffer.from(bytes)}, ${source})
      on conflict (user_id) do update set id = gen_random_uuid(), content_type = excluded.content_type,
        bytes = excluded.bytes, source = excluded.source, created_at = now()`);
  };

  app.openapi(routes.setProfilePhoto, async (c) => {
    const userId = me(c);
    const b = c.req.valid("json");
    const bytes = new Uint8Array(Buffer.from(b.data, "base64"));
    if (bytes.length === 0 || bytes.length > MAX_PHOTO_BYTES)
      throw new ApiError(400, "photo_too_big", "Photos can be up to 1 MB");
    const type = sniffPhotoType(bytes);
    if (!type || type !== b.content_type)
      throw new ApiError(400, "photo_unreadable", "That file isn't a JPEG, PNG or WebP picture");
    await savePhoto(userId, bytes, type, "upload");
    return c.json(await read(userId), 200);
  });

  app.openapi(routes.deleteProfilePhoto, async (c) => {
    const userId = me(c);
    await db.execute(sql`delete from public.profile_photos where user_id = ${userId}::uuid`);
    // Removed on purpose: the sign-in photo doesn't come back by itself.
    await db.execute(sql`
      update public.profiles set photo_import_tried_at = coalesce(photo_import_tried_at, now())
      where user_id = ${userId}::uuid`);
    return c.json(await read(userId), 200);
  });

  app.openapi(routes.importProfilePhoto, async (c) => {
    const userId = me(c);
    const { replace = false } = c.req.valid("json");
    const [r] = await db.execute<{
      has_photo: boolean;
      tried: boolean;
      meta: Record<string, unknown> | null;
    }>(sql`
      select exists (select 1 from public.profile_photos where user_id = p.user_id) as has_photo,
             p.photo_import_tried_at is not null as tried, u.raw_user_meta_data as meta
      from public.profiles p left join auth.users u on u.id = p.user_id
      where p.user_id = ${userId}::uuid`);
    if (r && (replace || (!r.has_photo && !r.tried))) {
      const url = providerPhotoUrl(r.meta);
      const photo = url ? await fetchProviderPhoto(url) : null;
      if (photo) await savePhoto(userId, photo.bytes, photo.type, "provider");
      else if (replace)
        throw new ApiError(400, "photo_unavailable", "Couldn't get your photo from Google");
      await db.execute(sql`
        update public.profiles set photo_import_tried_at = now() where user_id = ${userId}::uuid`);
    }
    return c.json(await read(userId), 200);
  });

  // The picture itself, without a token: the id is random and changes with every new photo, and
  // only people who can see the profile are given it. Cached for good.
  app.get("/v1/photos/:id", async (c) => {
    const id = c.req.param("id");
    if (!/^[0-9a-f-]{36}$/i.test(id)) throw new ApiError(404, "photo_not_found", "No such photo");
    const [p] = await db.execute<{ content_type: string; bytes: Buffer }>(sql`
      select content_type, bytes from public.profile_photos where id = ${id}::uuid`);
    if (!p) throw new ApiError(404, "photo_not_found", "No such photo");
    return c.body(new Uint8Array(p.bytes), 200, {
      "content-type": p.content_type,
      "cache-control": "public, max-age=31536000, immutable",
      "content-security-policy": "default-src 'none'",
    });
  });

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
    // Answered here: a welcome chat still asking for the name moves on instead of asking again.
    if (b.name_asked || orNull(b.preferred_name)) await welcomeNameAnswered(db, userId);
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
