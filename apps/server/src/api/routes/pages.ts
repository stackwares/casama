/** Pages (D-119): list, open (single-use view links to the pages origin), share, revert, delete. */
import type { OpenAPIHono } from "@hono/zod-openapi";
import { hashPageToken, newPageToken, savePageVersion, setPageVisibility } from "@kasama/agent";
import { routes } from "@kasama/contracts";
import { type JwtClaims, withUserSession } from "@kasama/db";
import { sql } from "drizzle-orm";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { iso } from "../util.ts";

type Row = {
  id: string;
  org_id: string;
  bot_id: string;
  title: string;
  visibility: "private" | "workspace" | "public";
  version: number;
  expires_at: string | null;
  refresh_routine_id: string | null;
  conversation_id: string | null;
  can_manage: boolean;
  updated_at: string;
  created_at: string;
};
const COLS = sql`id, org_id, bot_id, title, visibility, version, expires_at, refresh_routine_id, conversation_id,
  (created_by = auth.uid() or public.can_manage_bot(bot_id)) as can_manage, updated_at, created_at`;
const out = ({ org_id: _org, ...r }: Row) => ({
  ...r,
  expires_at: r.expires_at ? iso(r.expires_at) : null,
  updated_at: iso(r.updated_at),
  created_at: iso(r.created_at),
});

const claimsOf = (c: { get(k: "claims"): JwtClaims | undefined }) => {
  const claims = c.get("claims");
  if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
  return claims;
};

export const VIEW_LINK_SECONDS = 60;

export function registerPageRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;
  const pagesUrl = () => deps.env.PAGES_URL.replace(/\/$/, "");

  /** A page this person can open (RLS), or 404. */
  const visible = async (claims: JwtClaims, id: string) => {
    const [row] = await withUserSession(db, claims, (tx) =>
      tx.execute<Row>(sql`select ${COLS} from public.pages where id = ${id}::uuid`),
    );
    if (!row) throw new ApiError(404, "page_not_found", "Page not found");
    return row;
  };
  const managed = async (claims: JwtClaims, id: string) => {
    const row = await visible(claims, id);
    if (!row.can_manage)
      throw new ApiError(403, "forbidden", "Only the person it was made for or the bot's managers can change this page");
    return row;
  };

  app.openapi(routes.listPages, async (c) => {
    const claims = claimsOf(c);
    const { org_id, bot_id } = c.req.valid("query");
    const rows = await withUserSession(db, claims, (tx) =>
      tx.execute<Row>(sql`select ${COLS} from public.pages where org_id = ${org_id}::uuid
        and (${bot_id ?? null}::uuid is null or bot_id = ${bot_id ?? null}::uuid) order by updated_at desc limit 200`),
    );
    return c.json({ items: rows.map(out) }, 200);
  });

  app.openapi(routes.getPage, async (c) => {
    const claims = claimsOf(c);
    const row = await visible(claims, c.req.valid("param").id);
    const versions = await withUserSession(db, claims, (tx) =>
      tx.execute<{ version: number; created_at: string }>(sql`
        select version, created_at from public.page_versions where page_id = ${row.id}::uuid order by version desc`),
    );
    return c.json({ ...out(row), versions: versions.map((v) => ({ ...v, created_at: iso(v.created_at) })) }, 200);
  });

  app.openapi(routes.createPageViewLink, async (c) => {
    const claims = claimsOf(c);
    const row = await visible(claims, c.req.valid("param").id);
    const token = newPageToken();
    const expires = new Date(Date.now() + VIEW_LINK_SECONDS * 1000);
    await db.execute(sql`
      insert into public.page_view_tokens (token_hash, page_id, user_id, kind, format, expires_at)
      values (${hashPageToken(token)}, ${row.id}::uuid, ${claims.sub}::uuid, 'link', ${c.req.valid("json").format ?? "html"}, ${expires.toISOString()}::timestamptz)`);
    return c.json({ url: `${pagesUrl()}/v/${token}`, expires_at: expires.toISOString() }, 200);
  });

  app.openapi(routes.updatePage, async (c) => {
    const claims = claimsOf(c);
    const row = await managed(claims, c.req.valid("param").id);
    const { visibility, expires_in_days } = c.req.valid("json");
    const url = await setPageVisibility(db, row.id, visibility, { expiresInDays: expires_in_days, pagesUrl: pagesUrl() });
    if (visibility === "public" || row.visibility === "public")
      await db.execute(sql`insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id, metadata)
        values (${row.org_id}::uuid, 'user', ${claims.sub}::uuid, ${visibility === "public" ? "page.made_public" : "page.unpublished"}, 'page', ${row.id}::uuid,
                ${JSON.stringify({ title: row.title, visibility, expires_in_days: expires_in_days ?? null })}::jsonb)`);
    return c.json({ page: out(await visible(claims, row.id)), public_url: url }, 200);
  });

  app.openapi(routes.revertPage, async (c) => {
    const claims = claimsOf(c);
    const row = await managed(claims, c.req.valid("param").id);
    const { version } = c.req.valid("json");
    const [v] = await db.execute<{ html: string; data: unknown }>(sql`
      select html, data from public.page_versions where page_id = ${row.id}::uuid and version = ${version}`);
    if (!v) throw new ApiError(404, "version_not_found", "That version isn't kept any more (pages keep their last 20)");
    await savePageVersion(db, row.id, { html: v.html, data: v.data });
    return c.json(out(await visible(claims, row.id)), 200);
  });

  app.openapi(routes.deletePage, async (c) => {
    const claims = claimsOf(c);
    const row = await managed(claims, c.req.valid("param").id);
    await withUserSession(db, claims, (tx) => tx.execute(sql`delete from public.pages where id = ${row.id}::uuid`));
    if (row.refresh_routine_id)
      await db.execute(sql`update public.routines set enabled = false where id = ${row.refresh_routine_id}::uuid`);
    return c.json({ deleted: row.id }, 200);
  });
}
