/** Secret store settings (D-145): Vault by default, or the workspace's Infisical project (admins). */

import { InfisicalSecretStore, secretStoreFor } from "@casama/agent";
import { routes } from "@casama/contracts";
import { type JwtClaims, withUserSession } from "@casama/db";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { sql } from "drizzle-orm";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";

export function registerSecretStoreRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;
  const f = () => deps.apps?.fetch ?? fetch;
  const admin = async (claims: JwtClaims | undefined, orgId: string) => {
    if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
    const [r] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ member: boolean; admin: boolean }>(
        sql`select public.has_role(${orgId}::uuid, 'member') as member, public.has_role(${orgId}::uuid, 'admin') as admin`,
      ),
    );
    if (!r?.member) throw new ApiError(404, "org_not_found", "Workspace not found");
    if (!r.admin)
      throw new ApiError(403, "forbidden", "Only admins can change where secrets are kept");
    return claims;
  };
  const out = async (orgId: string) => {
    const [s] = await db.execute<{
      site_url: string;
      project_id: string;
      environment: string;
      secret_path: string;
    }>(sql`
      select site_url, project_id, environment, secret_path from public.org_secret_stores where org_id = ${orgId}::uuid`);
    return s
      ? { provider: "infisical" as const, ...s }
      : {
          provider: "vault" as const,
          site_url: null,
          project_id: null,
          environment: null,
          secret_path: null,
        };
  };

  app.openapi(routes.getSecretStore, async (c) => {
    const { id } = c.req.valid("param");
    await admin(c.get("claims"), id);
    return c.json(await out(id), 200);
  });

  app.openapi(routes.setSecretStore, async (c) => {
    const { id } = c.req.valid("param");
    const claims = await admin(c.get("claims"), id);
    const b = c.req.valid("json");
    const store = new InfisicalSecretStore({
      siteUrl: b.site_url,
      projectId: b.project_id,
      environment: b.environment ?? "prod",
      secretPath: b.secret_path ?? "/",
      clientId: b.client_id,
      clientSecret: b.client_secret,
      fetch: f(),
    });
    try {
      await store.list();
    } catch (e) {
      throw new ApiError(
        400,
        "infisical_failed",
        `Couldn't reach the Infisical project: ${(e as Error).message}`,
      );
    }
    let moved = 0;
    if (b.move_existing) {
      // Copy each Vault secret into Infisical, then drop it from Vault.
      const rows = await db.execute<{
        id: string;
        name: string;
        vault_secret_id: string;
        value: string | null;
      }>(sql`
        select s.id, s.name, s.vault_secret_id, v.decrypted_secret as value from public.secrets s
        join vault.decrypted_secrets v on v.id = s.vault_secret_id where s.org_id = ${id}::uuid and s.store = 'vault'`);
      for (const r of rows) {
        if (!r.value) continue;
        await store.put(r.name, r.value);
        await db.execute(
          sql`update public.secrets set store = 'infisical', vault_secret_id = null where id = ${r.id}::uuid`,
        );
        await db.execute(sql`delete from vault.secrets where id = ${r.vault_secret_id}::uuid`);
        moved++;
      }
    }
    await db.execute(sql`
      with old as (select vault_secret_id from public.org_secret_stores where org_id = ${id}::uuid)
      delete from vault.secrets where id in (select vault_secret_id from old)`);
    await db.execute(sql`
      insert into public.org_secret_stores (org_id, site_url, project_id, environment, secret_path, client_id, vault_secret_id, updated_at)
      values (${id}::uuid, ${b.site_url.replace(/\/$/, "")}, ${b.project_id}, ${b.environment ?? "prod"}, ${b.secret_path ?? "/"}, ${b.client_id},
              (select vault.create_secret(${b.client_secret}, null, 'infisical')), now())
      on conflict (org_id) do update set site_url = excluded.site_url, project_id = excluded.project_id, environment = excluded.environment,
        secret_path = excluded.secret_path, client_id = excluded.client_id, vault_secret_id = excluded.vault_secret_id, updated_at = now()`);
    await db.execute(sql`insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id, metadata)
      values (${id}::uuid, 'user', ${claims.sub}::uuid, 'secret_store.set', 'organization', ${id}::uuid, ${JSON.stringify({ provider: "infisical", moved })}::jsonb)`);
    return c.json(await out(id), 200);
  });

  app.openapi(routes.deleteSecretStore, async (c) => {
    const { id } = c.req.valid("param");
    const claims = await admin(c.get("claims"), id);
    // Copy Infisical-kept secrets back into Vault so nothing stops working.
    const store = await secretStoreFor(db, id, f());
    const rows = await db.execute<{ id: string; name: string }>(
      sql`select id, name from public.secrets where org_id = ${id}::uuid and store = 'infisical'`,
    );
    if (rows.length && store.kind === "infisical") {
      let values: Map<string, string>;
      try {
        values = await store.get(rows.map((r) => r.name));
      } catch (e) {
        throw new ApiError(
          400,
          "infisical_failed",
          `Couldn't read the secrets back from Infisical: ${(e as Error).message}`,
        );
      }
      for (const r of rows) {
        const v = values.get(r.name);
        if (!v) continue;
        await db.execute(
          sql`update public.secrets set store = 'vault', vault_secret_id = (select vault.create_secret(${v}, null, 'named secret')) where id = ${r.id}::uuid`,
        );
      }
    }
    await db.execute(sql`
      with gone as (delete from public.org_secret_stores where org_id = ${id}::uuid returning vault_secret_id)
      delete from vault.secrets where id in (select vault_secret_id from gone)`);
    await db.execute(sql`insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id, metadata)
      values (${id}::uuid, 'user', ${claims.sub}::uuid, 'secret_store.set', 'organization', ${id}::uuid, ${JSON.stringify({ provider: "vault" })}::jsonb)`);
    return c.json(await out(id), 200);
  });
}
