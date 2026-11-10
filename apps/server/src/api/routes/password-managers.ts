/**
 * Password managers (D-128): connect 1Password (Connect) or Bitwarden (`bw serve`) for the whole
 * workspace (admins) or yourself, and choose the vaults or collections bots may use. The token is
 * stored in Vault and never returned.
 */
import type { OpenAPIHono } from "@hono/zod-openapi";
import { clientFor } from "@kasama/agent";
import { routes } from "@kasama/contracts";
import { type JwtClaims, withUserSession } from "@kasama/db";
import { sql } from "drizzle-orm";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { iso } from "../util.ts";

type Row = {
  id: string;
  org_id: string;
  user_id: string | null;
  provider: "1password";
  name: string;
  url: string;
  allowed_vaults: string[];
  allowed_bot_ids: string[] | null;
  status: "ok";
  last_error: string | null;
  created_at: string;
};
const out = ({ org_id: _o, user_id, ...r }: Row) => ({
  ...r,
  scope: user_id ? ("personal" as const) : ("workspace" as const),
  created_at: iso(r.created_at),
});

const claimsOf = (c: { get(k: "claims"): JwtClaims | undefined }) => {
  const claims = c.get("claims");
  if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
  return claims;
};

export function registerPasswordManagerRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;
  const fetchOut = () => deps.apps?.fetch ?? fetch;

  const mine = async (claims: JwtClaims, id: string) => {
    const [r] = await withUserSession(db, claims, (tx) =>
      tx.execute<Row & { admin: boolean }>(
        sql`select *, public.has_role(org_id, 'admin') as admin from public.password_managers where id = ${id}::uuid`,
      ),
    );
    if (!r) throw new ApiError(404, "password_manager_not_found", "Password manager not found");
    if (r.user_id ? r.user_id !== claims.sub : !r.admin)
      throw new ApiError(
        403,
        "forbidden",
        "Only workspace admins can change the workspace's password managers",
      );
    return r;
  };
  const client = async (r: Row) => {
    const [t] = await db.execute<{ token: string | null }>(sql`
      select v.decrypted_secret as token from public.password_managers m left join vault.decrypted_secrets v on v.id = m.vault_secret_id where m.id = ${r.id}::uuid`);
    return clientFor(r.provider, r.url, t?.token ?? "", fetchOut());
  };

  app.openapi(routes.listPasswordManagers, async (c) => {
    const claims = claimsOf(c);
    const rows = await withUserSession(db, claims, (tx) =>
      tx.execute<Row>(
        sql`select * from public.password_managers where org_id = ${c.req.valid("query").org_id}::uuid order by user_id nulls first, created_at`,
      ),
    );
    return c.json({ items: rows.map(out) }, 200);
  });

  app.openapi(routes.createPasswordManager, async (c) => {
    const claims = claimsOf(c);
    const b = c.req.valid("json");
    const [ok] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ member: boolean; admin: boolean }>(
        sql`select public.is_member(${b.org_id}::uuid) as member, public.has_role(${b.org_id}::uuid, 'admin') as admin`,
      ),
    );
    if (!ok?.member) throw new ApiError(404, "org_not_found", "Workspace not found");
    if (b.scope === "workspace" && !ok.admin)
      throw new ApiError(
        403,
        "forbidden",
        "Only workspace admins can connect a password manager for everyone",
      );
    // Check it works before saving.
    try {
      await clientFor(b.provider, b.url, b.token, fetchOut()).vaults();
    } catch (err) {
      throw new ApiError(
        400,
        "password_manager_unreachable",
        `Couldn't reach it: ${(err as Error).message}`,
      );
    }
    const [row] = await db.execute<Row>(sql`
      insert into public.password_managers (org_id, user_id, provider, name, url, vault_secret_id, created_by)
      values (${b.org_id}::uuid, ${b.scope === "personal" ? claims.sub : null}::uuid, ${b.provider}, ${b.name}, ${b.url},
              (select vault.create_secret(${b.token}, null, 'password manager')), ${claims.sub}::uuid)
      returning *`);
    await db.execute(sql`insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id, metadata)
      values (${b.org_id}::uuid, 'user', ${claims.sub}::uuid, 'password_manager.connected', 'password_manager', ${row?.id}::uuid,
              ${JSON.stringify({ provider: b.provider, scope: b.scope })}::jsonb)`);
    return c.json(out(row as Row), 201);
  });

  app.openapi(routes.listPasswordManagerVaults, async (c) => {
    const claims = claimsOf(c);
    const r = await mine(claims, c.req.valid("param").id);
    const cl = await client(r);
    let vaults: Array<{ id: string; name: string }>;
    try {
      vaults = await cl.vaults();
    } catch (err) {
      throw new ApiError(
        400,
        "password_manager_unreachable",
        `Couldn't reach it: ${(err as Error).message}`,
      );
    }
    const items = await Promise.all(
      vaults.map(async (v) => ({
        id: v.id,
        name: v.name,
        allowed: r.allowed_vaults.includes(v.id),
        logins: r.allowed_vaults.includes(v.id)
          ? await cl
              .items([v.id])
              .then((x) => x.length)
              .catch(() => null)
          : null,
      })),
    );
    return c.json({ items }, 200);
  });

  app.openapi(routes.updatePasswordManager, async (c) => {
    const claims = claimsOf(c);
    const r = await mine(claims, c.req.valid("param").id);
    const b = c.req.valid("json");
    const [row] = await db.execute<Row>(sql`
      update public.password_managers set allowed_vaults = array(select jsonb_array_elements_text(${JSON.stringify(b.allowed_vaults)}::jsonb)),
        allowed_bot_ids = case when ${b.allowed_bot_ids === undefined} then allowed_bot_ids
          when ${b.allowed_bot_ids === null} then null
          else array(select jsonb_array_elements_text(${JSON.stringify(b.allowed_bot_ids ?? [])}::jsonb))::uuid[] end
      where id = ${r.id}::uuid returning *`);
    await db.execute(sql`insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id, metadata)
      values (${r.org_id}::uuid, 'user', ${claims.sub}::uuid, 'password_manager.vaults_changed', 'password_manager', ${r.id}::uuid,
              ${JSON.stringify({ vaults: b.allowed_vaults.length })}::jsonb)`);
    return c.json(out(row as Row), 200);
  });

  app.openapi(routes.deletePasswordManager, async (c) => {
    const claims = claimsOf(c);
    const r = await mine(claims, c.req.valid("param").id);
    await db.execute(sql`
      with gone as (delete from public.password_managers where id = ${r.id}::uuid returning vault_secret_id)
      delete from vault.secrets where id in (select vault_secret_id from gone)`);
    return c.json({ deleted: r.id }, 200);
  });
}
