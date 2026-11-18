/** Privacy (Phase 8, D-072): data export, account deletion, retention settings. */

import { track } from "@casama/agent";
import { ANALYTICS_CLIENT_EVENTS, GA4_CLIENT_TWINS, routes } from "@casama/contracts";
import { type JwtClaims, withUserSession } from "@casama/db";
import { cleanSitePattern } from "@casama/domain";
import { getProductAnalytics } from "@casama/observability";
import type { OpenAPIHono } from "@hono/zod-openapi";
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
      "content-disposition": `attachment; filename="casama-export-${day}.zip"`,
      "cache-control": "no-store",
    }) as never;
  });

  // Supabase Auth can't rename a factor, so the API does it for the signed-in person's own factors.
  // Names stay unique per person: the hidden " · <time>" suffix the app adds at enrollment is kept.
  app.openapi(routes.renameTwoStepFactor, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const { name } = c.req.valid("json");
    const clean = name.replace(/\s*·\s*/g, " ").trim();
    const rows = await db.execute<{ id: string }>(sql`
      update auth.mfa_factors
      set friendly_name = ${clean} || ' · ' || coalesce(nullif(split_part(friendly_name, ' · ', 2), ''), extract(epoch from created_at)::bigint::text),
          updated_at = now()
      where id = ${id}::uuid and user_id = ${claims.sub}::uuid
      returning id`);
    if (!rows.length) throw new ApiError(404, "factor_not_found", "Authenticator not found");
    return c.body(null, 204) as never;
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
    track(db, {
      event: "account_deletion_requested",
      userId: claims.sub,
      properties: { owned_workspaces: r.solo.length },
    });
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
      require_app_lock: boolean;
      llm_tracing: boolean;
      mcp_decide_approvals: boolean;
      full_access: boolean;
      allow_bot_to_bot: boolean;
      a2a_enabled: boolean;
      analytics_opt_out: boolean;
      chrome_extension: boolean;
      chrome_act: boolean;
      chrome_blocked_sites: string[];
    }>(
      sql`select run_event_retention_days, require_mfa, require_app_lock, llm_tracing, mcp_decide_approvals, full_access, allow_bot_to_bot, a2a_enabled, analytics_opt_out,
            chrome_extension, chrome_act, chrome_blocked_sites from public.organizations where id = ${orgId}::uuid`,
    );
    return {
      run_event_retention_days: o?.run_event_retention_days ?? 180,
      require_mfa: o?.require_mfa ?? false,
      require_app_lock: o?.require_app_lock ?? false,
      llm_tracing: o?.llm_tracing ?? true,
      mcp_decide_approvals: o?.mcp_decide_approvals ?? false,
      full_access: o?.full_access ?? false,
      allow_bot_to_bot: o?.allow_bot_to_bot ?? true,
      a2a_enabled: o?.a2a_enabled ?? false,
      analytics_opt_out: o?.analytics_opt_out ?? false,
      chrome_extension: o?.chrome_extension ?? true,
      chrome_act: o?.chrome_act ?? true,
      chrome_blocked_sites: o?.chrome_blocked_sites ?? [],
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
      body.require_app_lock != null ||
      body.llm_tracing != null ||
      body.mcp_decide_approvals != null ||
      body.full_access != null ||
      body.allow_bot_to_bot != null ||
      body.a2a_enabled != null ||
      body.analytics_opt_out != null ||
      body.chrome_extension != null ||
      body.chrome_act != null ||
      body.chrome_blocked_sites != null
    ) {
      if (body.chrome_extension != null)
        await db.execute(sql`
          update public.organizations set chrome_extension = ${body.chrome_extension} where id = ${id}::uuid`);
      if (body.chrome_act != null)
        await db.execute(sql`
          update public.organizations set chrome_act = ${body.chrome_act} where id = ${id}::uuid`);
      if (body.chrome_blocked_sites != null) {
        const sites = [
          ...new Set(
            body.chrome_blocked_sites.map((x) => {
              const p = cleanSitePattern(x);
              if (!p)
                throw new ApiError(400, "bad_site", `"${x.slice(0, 80)}" isn't a site address`);
              return p;
            }),
          ),
        ];
        await db.execute(sql`
          update public.organizations set chrome_blocked_sites = ${`{${sites.join(",")}}`}::text[] where id = ${id}::uuid`);
      }
      if (body.a2a_enabled != null) {
        await db.execute(
          sql`update public.organizations set a2a_enabled = ${body.a2a_enabled} where id = ${id}::uuid`,
        );
        // Turning it off unpublishes every bot.
        if (!body.a2a_enabled)
          await db.execute(
            sql`update public.bots set a2a_published = false where org_id = ${id}::uuid`,
          );
      }
      if (body.allow_bot_to_bot != null)
        await db.execute(sql`
          update public.organizations set allow_bot_to_bot = ${body.allow_bot_to_bot} where id = ${id}::uuid`);
      if (body.mcp_decide_approvals != null)
        await db.execute(sql`
          update public.organizations set mcp_decide_approvals = ${body.mcp_decide_approvals} where id = ${id}::uuid`);
      if (body.full_access != null)
        await db.execute(sql`
          update public.organizations set full_access = ${body.full_access} where id = ${id}::uuid`);
      if (body.analytics_opt_out != null)
        await db.execute(sql`
          update public.organizations set analytics_opt_out = ${body.analytics_opt_out} where id = ${id}::uuid`);
      if (body.llm_tracing != null)
        await db.execute(sql`
          update public.organizations set llm_tracing = ${body.llm_tracing} where id = ${id}::uuid`);
      if (body.run_event_retention_days != null)
        await db.execute(sql`
          update public.organizations set run_event_retention_days = ${body.run_event_retention_days} where id = ${id}::uuid`);
      if (body.require_mfa != null)
        await db.execute(sql`
          update public.organizations set require_mfa = ${body.require_mfa} where id = ${id}::uuid`);
      if (body.require_app_lock != null)
        await db.execute(sql`
          update public.organizations set require_app_lock = ${body.require_app_lock} where id = ${id}::uuid`);
      await db.execute(sql`
        insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id, metadata)
        values (${id}::uuid, 'user', ${claims.sub}::uuid, 'org.settings', 'organization', ${id}::uuid, ${JSON.stringify(body)}::jsonb)`);
    }
    return c.json(await settings(id), 200);
  });

  app.openapi(routes.setAnalyticsOptOut, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { opt_out } = c.req.valid("json");
    await db.execute(sql`
      update public.profiles
      set analytics_opt_out = ${opt_out}
      where user_id = ${claims.sub}::uuid
    `);
    deps.logger.info("analytics opt-out updated", { user_id: claims.sub, opt_out });
    return c.body(null, 204) as never;
  });

  app.openapi(routes.relayAnalytics, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const body = c.req.valid("json");
    const analytics = getProductAnalytics();
    if (!analytics.enabled || !analytics.providers?.includes("ga4"))
      return c.body(null, 204) as never;
    const [profile] = await db.execute<{ analytics_opt_out: boolean | null }>(sql`
      select analytics_opt_out from public.profiles where user_id = ${claims.sub}::uuid`);
    if (profile?.analytics_opt_out) return c.body(null, 204) as never;
    for (const e of relayedGa4Events(body.platform, body.events)) {
      analytics.capture({ ...e, distinctId: claims.sub, only: "ga4" });
    }
    return c.body(null, 204) as never;
  });

  // Casama Cloud receives opt-in telemetry pings (D-074): counts only, validated strictly.
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

/**
 * The desktop app's events as the GA4 sink takes them (D-399): only catalog events the app may send, with
 * only their catalog properties, plus screen views as GA4 page views (screen_view is reserved in the
 * Measurement Protocol). Each relayed twin-bearing event is followed by its GA4 recommended twin.
 */
export function relayedGa4Events(
  platform: "windows" | "linux",
  events: { name: string; properties?: Record<string, unknown> }[],
): { event: string; properties: Record<string, string | number | boolean> }[] {
  const out: { event: string; properties: Record<string, string | number | boolean> }[] = [];
  const base = { platform, source: "app" };
  for (const e of events) {
    const props = e.properties ?? {};
    if (e.name === "screen_view") {
      const screen = typeof props.screen === "string" ? props.screen.slice(0, 100) : "";
      if (!screen.startsWith("/")) continue;
      out.push({
        event: "page_view",
        properties: {
          ...base,
          page_title: screen,
          page_location: `https://app.casama.ai${screen}`,
          screen,
        },
      });
      continue;
    }
    if (!Object.hasOwn(ANALYTICS_CLIENT_EVENTS, e.name)) continue;
    const allowed = new Set([
      ...(ANALYTICS_CLIENT_EVENTS[e.name] ?? []),
      "distribution",
      "server_kind",
      "app_version",
    ]);
    const properties: Record<string, string | number | boolean> = { ...base };
    for (const [k, v] of Object.entries(props)) {
      if (!allowed.has(k)) continue;
      if (typeof v === "string") properties[k] = v.slice(0, 100);
      else if ((typeof v === "number" && Number.isFinite(v)) || typeof v === "boolean")
        properties[k] = v;
    }
    out.push({ event: e.name, properties });
    const twin = Object.hasOwn(GA4_CLIENT_TWINS, e.name) ? GA4_CLIENT_TWINS[e.name] : undefined;
    if (twin) {
      const tp: Record<string, string | number | boolean> = { ...base, ...twin.set };
      for (const k of twin.params) if (properties[k] !== undefined) tp[k] = properties[k]!;
      out.push({ event: twin.name, properties: tp });
    }
  }
  return out;
}
