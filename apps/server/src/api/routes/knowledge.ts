/** Knowledge sources (D-125): add, list, resync and delete; the worker reads and indexes them. */

import { routes } from "@casama/contracts";
import { type JwtClaims, withUserSession } from "@casama/db";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { sql } from "drizzle-orm";
import { parseGitHubUrl } from "../../services/skills.ts";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { iso } from "../util.ts";

type Row = {
  id: string;
  org_id: string;
  bot_id: string | null;
  kind: "upload";
  name: string;
  config: Record<string, unknown>;
  status: "ready";
  error: string | null;
  documents: number;
  chunks: number;
  last_synced_at: string | null;
  created_at: string;
};
const out = ({ org_id: _o, ...r }: Row) => ({
  ...r,
  last_synced_at: r.last_synced_at ? iso(r.last_synced_at) : null,
  created_at: iso(r.created_at),
});

const claimsOf = (c: { get(k: "claims"): JwtClaims | undefined }) => {
  const claims = c.get("claims");
  if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
  return claims;
};

export function registerKnowledgeRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;

  /** Bot sources need someone who manages the bot; workspace sources need an admin. */
  const mayChange = async (claims: JwtClaims, orgId: string, botId: string | null) => {
    const [r] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ ok: boolean }>(
        botId
          ? sql`select public.can_manage_bot(${botId}::uuid) and exists (select 1 from public.bots where id = ${botId}::uuid and org_id = ${orgId}::uuid) as ok`
          : sql`select public.has_role(${orgId}::uuid, 'admin') as ok`,
      ),
    );
    if (!r?.ok)
      throw new ApiError(
        403,
        "forbidden",
        botId
          ? "Only people who manage this bot can change its knowledge"
          : "Only workspace admins can change shared knowledge",
      );
  };
  const visible = async (claims: JwtClaims, id: string) => {
    const [r] = await withUserSession(db, claims, (tx) =>
      tx.execute<Row>(sql`select * from public.knowledge_sources where id = ${id}::uuid`),
    );
    if (!r) throw new ApiError(404, "knowledge_source_not_found", "Knowledge source not found");
    return r;
  };

  app.openapi(routes.listKnowledgeSources, async (c) => {
    const claims = claimsOf(c);
    const { org_id, bot_id } = c.req.valid("query");
    const rows = await withUserSession(db, claims, (tx) =>
      tx.execute<Row>(sql`select * from public.knowledge_sources where org_id = ${org_id}::uuid
        and (bot_id is null or bot_id = ${bot_id ?? null}::uuid) order by bot_id nulls last, created_at`),
    );
    return c.json({ items: rows.map(out) }, 200);
  });

  app.openapi(routes.createKnowledgeSource, async (c) => {
    const claims = claimsOf(c);
    const b = c.req.valid("json");
    await mayChange(claims, b.org_id, b.bot_id ?? null);
    let config: Record<string, unknown> = {};
    if (b.kind === "upload") {
      if (!b.files?.length) throw new ApiError(400, "no_files", "Add at least one file");
      const total = b.files.reduce((n, f) => n + f.content_base64.length * 0.75, 0);
      if (total > 100_000_000)
        throw new ApiError(400, "too_large", "Uploads can total up to 100 MB per source");
    } else if (b.kind === "website") {
      let u: URL;
      try {
        u = new URL(b.url ?? "");
      } catch {
        throw new ApiError(400, "bad_url", "Give the website's address (https://…)");
      }
      if (!/^https?:$/.test(u.protocol))
        throw new ApiError(400, "bad_url", "Websites need an http or https address");
      config = { url: u.href, max_pages: b.max_pages ?? 50 };
    } else if (b.kind === "github") {
      const g = parseGitHubUrl(b.repo_url ?? "");
      config = { owner: g.owner, repo: g.repo, path: g.path, ref: g.ref ?? undefined };
    } else {
      if (!b.integration_id || !b.documents?.length)
        throw new ApiError(400, "bad_connection", "Pick a connection and the documents to read");
      const [i] = await db.execute<{ id: string }>(
        sql`select id from public.integrations where id = ${b.integration_id}::uuid and org_id = ${b.org_id}::uuid`,
      );
      if (!i) throw new ApiError(404, "integration_not_found", "Connection not found");
      config = { integration_id: b.integration_id, documents: b.documents };
    }
    const row = await db.transaction(async (tx) => {
      const [r] = await tx.execute<Row>(sql`
        insert into public.knowledge_sources (org_id, bot_id, kind, name, config, created_by)
        values (${b.org_id}::uuid, ${b.bot_id ?? null}::uuid, ${b.kind}, ${b.name}, ${JSON.stringify(config)}::jsonb, ${claims.sub}::uuid)
        returning *`);
      for (const f of b.files ?? [])
        await tx.execute(sql`
          insert into public.knowledge_uploads (source_id, org_id, name, content)
          values (${r?.id}::uuid, ${b.org_id}::uuid, ${f.name}, decode(${f.content_base64}, 'base64'))`);
      return r as Row;
    });
    return c.json(out(row), 201);
  });

  app.openapi(routes.resyncKnowledgeSource, async (c) => {
    const claims = claimsOf(c);
    const r = await visible(claims, c.req.valid("param").id);
    await mayChange(claims, r.org_id, r.bot_id);
    const [row] = await db.execute<Row>(sql`
      update public.knowledge_sources set next_sync_at = now(), status = case when status = 'syncing' then status else 'pending' end
      where id = ${r.id}::uuid returning *`);
    return c.json(out(row as Row), 200);
  });

  app.openapi(routes.deleteKnowledgeSource, async (c) => {
    const claims = claimsOf(c);
    const r = await visible(claims, c.req.valid("param").id);
    await mayChange(claims, r.org_id, r.bot_id);
    await db.execute(sql`delete from public.knowledge_sources where id = ${r.id}::uuid`);
    return c.json({ deleted: r.id }, 200);
  });
}
