/** Privacy (Phase 8, D-072): data export, account deletion, retention settings. */
import type { OpenAPIHono } from "@hono/zod-openapi";
import { routes } from "@kasama/contracts";
import { type JwtClaims, withUserSession } from "@kasama/db";
import { sql } from "drizzle-orm";
import { exportUserData, requestAccountDeletion } from "../../services/privacy.ts";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";

function requireClaims(claims: JwtClaims | undefined): JwtClaims {
  if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
  return claims;
}

export function registerPrivacyRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db, env } = deps;

  app.openapi(routes.exportMyData, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const zip = await exportUserData(db, claims);
    await db.execute(sql`
      insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id)
      select m.org_id, 'user', ${claims.sub}::uuid, 'privacy.export', 'user', ${claims.sub}::uuid
      from public.memberships m where m.user_id = ${claims.sub}::uuid`);
    const day = new Date().toISOString().slice(0, 10);
    return c.body(zip, 200, {
      "content-type": "application/zip",
      "content-disposition": `attachment; filename="kasama-export-${day}.zip"`,
      "cache-control": "no-store",
    }) as never;
  });

  app.openapi(routes.deleteMyAccount, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { confirm_email } = c.req.valid("json");
    const [u] = await db.execute<{ email: string | null }>(
      sql`select email from auth.users where id = ${claims.sub}::uuid`,
    );
    if (!u?.email || u.email.toLowerCase() !== confirm_email.toLowerCase())
      throw new ApiError(400, "confirm_mismatch", "Type your account's email to confirm");
    const r = await requestAccountDeletion(db, claims.sub, env.ACCOUNT_DELETION_GRACE_DAYS);
    deps.logger.info("account deletion requested", { user_id: claims.sub, orgs: r.solo.length });
    return c.json(
      { purge_after: r.purgeAfter.toISOString(), workspaces_deleted: r.solo.map((o) => o.name) },
      200,
    );
  });

  const role = async (claims: JwtClaims, orgId: string, needed: "member" | "admin") => {
    const [r] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ ok: boolean }>(sql`select public.has_role(${orgId}::uuid, ${needed}) as ok`),
    );
    if (!r?.ok) {
      if (needed === "member") throw new ApiError(404, "org_not_found", "Workspace not found");
      throw new ApiError(403, "forbidden", "Only owners and admins can change workspace settings");
    }
  };
  const settings = async (orgId: string) => {
    const [o] = await db.execute<{
      run_event_retention_days: number;
      require_mfa: boolean;
      llm_tracing: boolean;
    }>(
      sql`select run_event_retention_days, require_mfa, llm_tracing from public.organizations where id = ${orgId}::uuid`,
    );
    return {
      run_event_retention_days: o?.run_event_retention_days ?? 180,
      require_mfa: o?.require_mfa ?? false,
      llm_tracing: o?.llm_tracing ?? true,
    };
  };

  app.openapi(routes.getOrgSettings, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    await role(claims, id, "member");
    return c.json(await settings(id), 200);
  });

  app.openapi(routes.updateOrgSettings, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const body = c.req.valid("json");
    await role(claims, id, "admin");
    if (body.require_mfa === true && claims.aal !== "aal2") {
      // Turning it on without a second step would lock the person out of their own admin powers.
      throw new ApiError(
        403,
        "mfa_required",
        "Set up two-step sign-in and sign in with it before requiring it for the workspace",
      );
    }
    if (
      body.run_event_retention_days != null ||
      body.require_mfa != null ||
      body.llm_tracing != null
    ) {
      if (body.llm_tracing != null)
        await db.execute(sql`
          update public.organizations set llm_tracing = ${body.llm_tracing} where id = ${id}::uuid`);
      if (body.run_event_retention_days != null)
        await db.execute(sql`
          update public.organizations set run_event_retention_days = ${body.run_event_retention_days} where id = ${id}::uuid`);
      if (body.require_mfa != null)
        await db.execute(sql`
          update public.organizations set require_mfa = ${body.require_mfa} where id = ${id}::uuid`);
      await db.execute(sql`
        insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id, metadata)
        values (${id}::uuid, 'user', ${claims.sub}::uuid, 'org.settings', 'organization', ${id}::uuid, ${JSON.stringify(body)}::jsonb)`);
    }
    return c.json(await settings(id), 200);
  });

  // Kasama Cloud receives opt-in telemetry pings (D-074): counts only, validated strictly.
  if (deps.billing?.enabled) {
    app.post("/telemetry/v1/ping", async (c) => {
      const b = (await c.req.json().catch(() => null)) as Record<string, unknown> | null;
      const uuid = /^[0-9a-f-]{36}$/i;
      const n = (v: unknown) =>
        Number.isInteger(v) && (v as number) >= 0 && (v as number) < 1e7 ? (v as number) : null;
      if (
        !b ||
        typeof b.instance_id !== "string" ||
        !uuid.test(b.instance_id) ||
        typeof b.version !== "string" ||
        b.version.length > 32 ||
        n(b.weekly_active_bots) == null ||
        n(b.weekly_active_users) == null
      )
        throw new ApiError(400, "bad_ping", "Invalid telemetry ping");
      await db.execute(sql`
        insert into public.telemetry_pings (instance_id, version, weekly_active_bots, weekly_active_users)
        values (${b.instance_id}::uuid, ${b.version}, ${b.weekly_active_bots as number}, ${b.weekly_active_users as number})`);
      return c.json({ ok: true }, 200);
    });
  }
}
