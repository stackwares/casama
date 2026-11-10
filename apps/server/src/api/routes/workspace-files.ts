/**
 * Routines and skills as files (D-124): export and import as Markdown, and optional git sync
 * through the workspace's GITHUB_TOKEN. The worker does the syncing; this sets it up and receives
 * the repo's push webhook. Workspace admins only, since the files cover every bot.
 */
import { createHmac, randomBytes, timingSafeEqual } from "node:crypto";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { applyWorkspaceFiles, exportWorkspaceFiles } from "@kasama/agent";
import { routes } from "@kasama/contracts";
import { type JwtClaims, withUserSession } from "@kasama/db";
import { sql } from "drizzle-orm";
import { unzipSync, zipSync } from "fflate";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { iso } from "../util.ts";

const claimsOf = (c: { get(k: "claims"): JwtClaims | undefined }) => {
  const claims = c.get("claims");
  if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
  return claims;
};

export function registerWorkspaceFileRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;
  const admin = async (claims: JwtClaims, orgId: string) => {
    const [r] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ ok: boolean }>(sql`select public.has_role(${orgId}::uuid, 'admin') as ok`),
    );
    if (!r?.ok)
      throw new ApiError(
        403,
        "forbidden",
        "Only workspace admins can export, import or sync routines and skills",
      );
  };
  const base = (c: { req: { url: string } }) =>
    (deps.env.PUBLIC_API_URL ?? new URL(c.req.url).origin).replace(/\/$/, "");

  const status = async (
    c: { req: { url: string } },
    orgId: string,
    secret: string | null = null,
  ) => {
    const [g] = await db.execute<{
      repo: string;
      branch: string;
      path: string;
      enabled: boolean;
      last_synced_at: string | null;
      last_commit: string | null;
      last_error: string | null;
      open_pr_url: string | null;
    }>(sql`select * from public.org_git_sync where org_id = ${orgId}::uuid`);
    const [t] = await db.execute<{ n: number }>(sql`
      select count(*)::int as n from public.secrets where org_id = ${orgId}::uuid and name = 'GITHUB_TOKEN' and 'api.github.com' = any(allowed_hosts)`);
    return {
      configured: !!g,
      repo: g?.repo ?? null,
      branch: g?.branch ?? null,
      path: g?.path ?? null,
      enabled: g?.enabled ?? false,
      has_token: (t?.n ?? 0) > 0,
      webhook_url: g ? `${base(c)}/hooks/git-sync/${orgId}` : null,
      webhook_secret: secret,
      last_synced_at: g?.last_synced_at ? iso(g.last_synced_at) : null,
      last_commit: g?.last_commit ?? null,
      last_error: g?.last_error ?? null,
      open_pr_url: g?.open_pr_url ?? null,
    };
  };

  app.openapi(routes.exportWorkspaceFiles, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    await admin(claims, id);
    const files = await exportWorkspaceFiles(db, id);
    const zip = zipSync(Object.fromEntries(files));
    return c.json(
      {
        zip_base64: Buffer.from(zip).toString("base64"),
        count: files.size,
        files: [...files].map(([path, b]) => ({
          path,
          content_base64: Buffer.from(b).toString("base64"),
        })),
      },
      200,
    );
  });

  app.openapi(routes.importWorkspaceFiles, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    await admin(claims, id);
    const b = c.req.valid("json");
    const files = new Map<string, Uint8Array>();
    if (b.zip_base64) {
      try {
        for (const [k, v] of Object.entries(unzipSync(Buffer.from(b.zip_base64, "base64"))))
          if (!k.endsWith("/")) files.set(k, v);
      } catch {
        throw new ApiError(400, "import_bad_zip", "That isn't a ZIP file we can read.");
      }
    } else
      for (const f of b.files ?? []) files.set(f.path, Buffer.from(f.content_base64, "base64"));
    // A ZIP of the folder itself: drop the shared top folder.
    const keys = [...files.keys()];
    const top = keys[0]?.split("/")[0];
    if (
      top &&
      keys.every((k) => k.startsWith(`${top}/`)) &&
      !["workspace"].includes(top) &&
      keys.some((k) => k === `${top}/kasama.json`)
    ) {
      for (const k of keys) {
        files.set(k.slice(top.length + 1), files.get(k) as Uint8Array);
        files.delete(k);
      }
    }
    for (const k of [...files.keys()])
      if (k.split("/").includes("..") || k.startsWith("/")) files.delete(k);
    const r = await applyWorkspaceFiles(db, id, files, {
      dryRun: b.dry_run ?? false,
      actorUserId: claims.sub,
    });
    if (!b.dry_run && (r.created.length || r.updated.length))
      await db.execute(sql`insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id, metadata)
        values (${id}::uuid, 'user', ${claims.sub}::uuid, 'files.imported', 'organization', ${id}::uuid, ${JSON.stringify({ created: r.created.length, updated: r.updated.length })}::jsonb)`);
    return c.json({ ...r, dry_run: b.dry_run ?? false }, 200);
  });

  app.openapi(routes.getGitSync, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    await admin(claims, id);
    return c.json(await status(c, id), 200);
  });

  app.openapi(routes.setGitSync, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    await admin(claims, id);
    const b = c.req.valid("json");
    const [existing] = await db.execute<{ repo: string; branch: string; path: string }>(
      sql`select repo, branch, path from public.org_git_sync where org_id = ${id}::uuid`,
    );
    let secret: string | null = null;
    const path = (b.path ?? "").replace(/^\/+|\/+$/g, "");
    if (path.split("/").includes(".."))
      throw new ApiError(400, "bad_path", "The folder can't contain ..");
    if (!existing) {
      secret = randomBytes(24).toString("hex");
      await db.execute(sql`
        insert into public.org_git_sync (org_id, repo, branch, path, enabled, webhook_secret_id, created_by)
        values (${id}::uuid, ${b.repo}, ${b.branch ?? "main"}, ${path}, ${b.enabled ?? true},
                (select vault.create_secret(${secret}, null, 'git sync webhook')), ${claims.sub}::uuid)`);
    } else {
      const moved =
        existing.repo !== b.repo ||
        existing.branch !== (b.branch ?? existing.branch) ||
        existing.path !== path;
      // Pointing at another repo, branch or folder starts from a clean slate.
      await db.execute(sql`
        update public.org_git_sync set repo = ${b.repo}, branch = ${b.branch ?? existing.branch}, path = ${path}, enabled = ${b.enabled ?? true},
          synced = case when ${moved} then '{}'::jsonb else synced end, dirty_at = now(), last_error = null
        where org_id = ${id}::uuid`);
    }
    await db.execute(sql`insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id, metadata)
      values (${id}::uuid, 'user', ${claims.sub}::uuid, 'git_sync.configured', 'organization', ${id}::uuid, ${JSON.stringify({ repo: b.repo })}::jsonb)`);
    return c.json(await status(c, id, secret), 200);
  });

  app.openapi(routes.runGitSync, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    await admin(claims, id);
    const rows = await db.execute(
      sql`update public.org_git_sync set dirty_at = now(), checked_at = null where org_id = ${id}::uuid returning org_id`,
    );
    if (!rows.length) throw new ApiError(404, "git_sync_not_found", "Git sync isn't set up");
    return c.json(await status(c, id), 200);
  });

  app.openapi(routes.deleteGitSync, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    await admin(claims, id);
    await db.execute(sql`
      with gone as (delete from public.org_git_sync where org_id = ${id}::uuid returning webhook_secret_id)
      delete from vault.secrets where id in (select webhook_secret_id from gone)`);
    return c.json(await status(c, id), 200);
  });

  // The repo's push webhook: checked with the secret, then synced on the worker's next minute.
  app.post("/hooks/git-sync/:org", async (c) => {
    const org = c.req.param("org");
    if (!/^[0-9a-f-]{36}$/.test(org)) return c.json({ code: "not_found" }, 404);
    const body = await c.req.text();
    const [g] = await db.execute<{ secret: string | null }>(sql`
      select v.decrypted_secret as secret from public.org_git_sync g left join vault.decrypted_secrets v on v.id = g.webhook_secret_id
      where g.org_id = ${org}::uuid and g.enabled`);
    const sig = c.req.header("x-hub-signature-256") ?? "";
    const want = g?.secret
      ? `sha256=${createHmac("sha256", g.secret).update(body).digest("hex")}`
      : "";
    if (
      !want ||
      sig.length !== want.length ||
      !timingSafeEqual(Buffer.from(sig), Buffer.from(want))
    )
      return c.json({ code: "bad_signature", message: "Signature doesn't match" }, 401);
    await db.execute(
      sql`update public.org_git_sync set checked_at = null where org_id = ${org}::uuid`,
    );
    return c.json({ ok: true }, 202);
  });
}
