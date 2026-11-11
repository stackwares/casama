/** Owner admin console (Phase 6): instance totals, users, quotas, services, update notices. */

import { routes } from "@casama/contracts";
import type { JwtClaims } from "@casama/db";
import { verifyLicense } from "@casama/ee";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { sql } from "drizzle-orm";
import { suspendOrg, unsuspendOrg } from "../../services/abuse.ts";
import { getCloudModels, setCloudModels } from "../../services/cloud-models.ts";
import {
  type ConnectionSettings,
  getConnectionSettings,
  setConnectionSettings,
} from "../../services/connection-settings.ts";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { iso } from "../util.ts";

export const CASAMA_VERSION = "0.8.0";

const num = (v: unknown) => Number(v ?? 0);

function requireClaims(claims: JwtClaims | undefined): JwtClaims {
  if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
  return claims;
}

export function registerAdminRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db, env } = deps;

  /** Instance owners: INSTANCE_ADMIN_EMAILS, or the first user to sign up when unset. */
  const requireOwner = async (claims: JwtClaims) => {
    const allow = (env.INSTANCE_ADMIN_EMAILS ?? "")
      .split(",")
      .map((e) => e.trim().toLowerCase())
      .filter(Boolean);
    const [u] = await db.execute<{ email: string | null; first: boolean }>(sql`
      select u.email, u.id = (select id from auth.users order by created_at limit 1) as first
      from auth.users u where u.id = ${claims.sub}::uuid`);
    const ok = allow.length ? allow.includes((u?.email ?? "").toLowerCase()) : !!u?.first;
    if (!ok)
      throw new ApiError(
        403,
        "not_instance_owner",
        "Only the instance owner can open the admin console",
      );
  };

  const connectionsOut = (settings: ConnectionSettings) => ({
    ...settings,
    composio_key: !!env.COMPOSIO_API_KEY,
    google_direct_available: !!env.GOOGLE_OAUTH_CLIENT_ID && !env.BILLING_ENABLED,
  });

  app.openapi(routes.adminConnectionSettings, async (c) => {
    await requireOwner(requireClaims(c.get("claims")));
    const settings = await getConnectionSettings(db);
    return c.json(connectionsOut(settings), 200);
  });

  app.openapi(routes.adminCloudModels, async (c) => {
    await requireOwner(requireClaims(c.get("claims")));
    return c.json(await getCloudModels(db), 200);
  });

  app.openapi(routes.setAdminCloudModels, async (c) => {
    await requireOwner(requireClaims(c.get("claims")));
    const saved = await setCloudModels(db, c.req.valid("json"));
    deps.logger.info("cloud models changed", {
      chat: saved.chat,
      live: saved.live,
      image: saved.image,
    });
    return c.json(saved, 200);
  });

  app.openapi(routes.setAdminConnectionSettings, async (c) => {
    await requireOwner(requireClaims(c.get("claims")));
    const body = c.req.valid("json");
    if (body.google === "direct" && env.BILLING_ENABLED)
      throw new ApiError(
        400,
        "validation_failed",
        "Casama Cloud connects Google's apps through Composio (Developer Preview terms bar public apps)",
      );
    const current = await getConnectionSettings(db);
    const settings = await setConnectionSettings(db, {
      composio: body.composio ?? current.composio,
      google: body.google ?? current.google,
    });
    deps.logger.info("connection settings changed", {
      composio: settings.composio,
      google: settings.google,
    });
    return c.json(connectionsOut(settings), 200);
  });

  app.openapi(routes.adminOverview, async (c) => {
    await requireOwner(requireClaims(c.get("claims")));
    const [r] = await db.execute<Record<string, unknown>>(sql`select
      (select count(*) from auth.users) as users,
      (select count(*) from public.organizations) as orgs,
      (select count(*) from public.bots) as bots,
      (select count(*) from public.runs where created_at > now() - interval '24 hours') as runs,
      (select count(*) from public.runs where created_at > now() - interval '24 hours' and status = 'failed') as failed,
      (select coalesce(sum(cost_usd), 0) from public.usage_ledger where created_at > now() - interval '24 hours') as cost,
      (select count(*) from public.computers where state in ('running', 'idle') and kind <> 'local') as computers`);
    return c.json(
      {
        version: CASAMA_VERSION,
        users: num(r?.users),
        orgs: num(r?.orgs),
        bots: num(r?.bots),
        runs_24h: num(r?.runs),
        failed_runs_24h: num(r?.failed),
        cost_24h_usd: num(r?.cost),
        computers_running: num(r?.computers),
        devices_online: deps.devices?.deviceIds().size ?? 0,
      },
      200,
    );
  });

  app.openapi(routes.adminUsers, async (c) => {
    await requireOwner(requireClaims(c.get("claims")));
    const rows = await db.execute<{
      id: string;
      email: string | null;
      created_at: Date;
      last_sign_in_at: Date | null;
      orgs: number;
    }>(sql`
      select u.id, u.email, u.created_at, u.last_sign_in_at,
             (select count(*)::int from public.memberships m where m.user_id = u.id) as orgs
      from auth.users u order by u.created_at limit 1000`);
    return c.json(
      {
        items: rows.map((u) => ({
          id: u.id,
          email: u.email,
          created_at: iso(u.created_at),
          last_sign_in_at: u.last_sign_in_at ? iso(u.last_sign_in_at) : null,
          orgs: u.orgs,
        })),
      },
      200,
    );
  });

  const orgRows = async (id?: string) =>
    db.execute<{
      id: string;
      name: string;
      plan_code: string | null;
      limits: Record<string, number> | null;
      members: number;
      bots: number;
      cost: string;
      suspended_at: Date | null;
      suspended_reason: string | null;
    }>(sql`
      select o.id, o.name, e.plan_code, e.limits, o.suspended_at, o.suspended_reason,
             (select count(*)::int from public.memberships m where m.org_id = o.id) as members,
             (select count(*)::int from public.bots b where b.org_id = o.id) as bots,
             (select coalesce(sum(cost_usd), 0)::text from public.usage_ledger l where l.org_id = o.id and l.created_at > now() - interval '30 days') as cost
      from public.organizations o
      left join lateral (select plan_code, limits from public.entitlements where org_id = o.id order by created_at desc limit 1) e on true
      ${id ? sql`where o.id = ${id}::uuid` : sql``}
      order by o.created_at limit 1000`);
  const orgOut = (o: Awaited<ReturnType<typeof orgRows>>[number]) => ({
    id: o.id,
    name: o.name,
    plan_code: o.plan_code,
    limits: Object.fromEntries(
      Object.entries(o.limits ?? {}).filter(([, v]) => typeof v === "number"),
    ),
    members: o.members,
    bots: o.bots,
    cost_30d_usd: Number(o.cost),
    suspended_at: o.suspended_at ? iso(o.suspended_at) : null,
    suspended_reason: o.suspended_reason,
  });

  app.openapi(routes.suspendOrg, async (c) => {
    const claims = requireClaims(c.get("claims"));
    await requireOwner(claims);
    const { id } = c.req.valid("param");
    const { reason } = c.req.valid("json");
    const ok = await suspendOrg(
      { db, stopComputer: deps.computers ? (cid) => deps.computers!.sleep(cid) : undefined },
      id,
      reason,
      { kind: "user", id: claims.sub },
    );
    if (!ok) throw new ApiError(404, "org_not_found", "Workspace not found");
    const [o] = await orgRows(id);
    return c.json(orgOut(o as NonNullable<typeof o>), 200);
  });

  app.openapi(routes.unsuspendOrg, async (c) => {
    const claims = requireClaims(c.get("claims"));
    await requireOwner(claims);
    const { id } = c.req.valid("param");
    if (!(await unsuspendOrg(db, id, claims.sub)))
      throw new ApiError(404, "org_not_found", "Workspace not found");
    const [o] = await orgRows(id);
    return c.json(orgOut(o as NonNullable<typeof o>), 200);
  });

  app.openapi(routes.adminAbuseEvents, async (c) => {
    await requireOwner(requireClaims(c.get("claims")));
    const rows = await db.execute<{
      id: string;
      org_id: string | null;
      org_name: string | null;
      computer_id: string | null;
      kind: string;
      action: string;
      detail: Record<string, unknown>;
      created_at: Date;
    }>(sql`
      select e.id, e.org_id, o.name as org_name, e.computer_id, e.kind, e.action, e.detail, e.created_at
      from public.abuse_events e left join public.organizations o on o.id = e.org_id
      order by e.created_at desc limit 200`);
    return c.json({ items: rows.map((r) => ({ ...r, created_at: iso(r.created_at) })) }, 200);
  });

  app.openapi(routes.adminOrgs, async (c) => {
    await requireOwner(requireClaims(c.get("claims")));
    return c.json({ items: (await orgRows()).map(orgOut) }, 200);
  });

  app.openapi(routes.setOrgLimits, async (c) => {
    const claims = requireClaims(c.get("claims"));
    await requireOwner(claims);
    const { id } = c.req.valid("param");
    const { limits } = c.req.valid("json");
    await db.execute(sql`insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id, metadata)
      select o.id, 'user', ${claims.sub}::uuid, 'admin.limits', 'organization', o.id, ${JSON.stringify({ limits })}::jsonb
      from public.organizations o where o.id = ${id}::uuid`);
    // Owner overrides sit on top of the plan's limits and survive billing changes (D-070).
    const updated = await db.execute<{ id: string }>(sql`
      update public.entitlements set overrides = ${JSON.stringify(limits)}::jsonb,
        limits = (select p.limits from public.plans p where p.code = plan_code) || ${JSON.stringify(limits)}::jsonb
      where id = (select id from public.entitlements where org_id = ${id}::uuid order by created_at desc limit 1)
      returning id`);
    if (!updated.length) throw new ApiError(404, "org_not_found", "Workspace not found");
    const [o] = await orgRows(id);
    return c.json(orgOut(o as NonNullable<typeof o>), 200);
  });

  app.openapi(routes.adminServices, async (c) => {
    await requireOwner(requireClaims(c.get("claims")));
    const check = async (fn: () => Promise<void>) =>
      fn().then(
        () => true,
        () => false,
      );
    const [workers] = await db
      .execute<{ n: number }>(
        sql`select count(*)::int as n from dbos.workflow_status where updated_at > (extract(epoch from now() - interval '10 minutes') * 1000)`,
      )
      .catch(() => [{ n: -1 }]);
    const supervisor = env.SUPERVISOR_URL
      ? await check(async () => {
          const r = await fetch(`${env.SUPERVISOR_URL}/healthz`);
          if (!r.ok) throw new Error();
        })
      : null;
    const license = await verifyLicense(
      env.CASAMA_LICENSE_KEY,
      env.NODE_ENV === "test" ? env.CASAMA_LICENSE_PUBLIC_KEY : undefined,
    );
    const items = [
      {
        name: "Database",
        configured: true,
        healthy: await check(async () => void (await db.execute(sql`select 1`))),
        detail: "Postgres (Supabase)",
      },
      {
        name: "Worker",
        configured: true,
        healthy: workers?.n === -1 ? null : true,
        detail:
          workers?.n === -1
            ? "Unknown"
            : `${workers?.n ?? 0} workflows updated in the last 10 minutes`,
      },
      {
        name: "Sandbox supervisor",
        configured: !!env.SUPERVISOR_URL,
        healthy: supervisor,
        detail: env.SUPERVISOR_URL ? "Docker computers" : "Not configured: only personal computers",
      },
      {
        name: "Live view relay",
        configured: !!env.TURN_SECRET,
        healthy: null,
        detail: env.TURN_SECRET
          ? `TURN at ${env.TURN_PUBLIC_HOST}:${env.TURN_PORT}`
          : "Not configured",
      },
      {
        name: "Personal computers",
        configured: env.LOCAL_COMPUTERS,
        healthy: null,
        detail: `${deps.devices?.deviceIds().size ?? 0} connected`,
      },
      {
        name: "Email",
        configured: !!(env.RESEND_API_KEY || env.SMTP_HOST),
        healthy: null,
        detail: env.RESEND_API_KEY
          ? "Resend"
          : env.SMTP_HOST
            ? "SMTP"
            : "Off: invites return a code",
      },
      {
        name: "Error reporting",
        configured: !!(env.SENTRY_DSN || env.POSTHOG_API_KEY),
        healthy: null,
        detail: env.SENTRY_DSN ? "Sentry protocol" : env.POSTHOG_API_KEY ? "PostHog" : "Off",
      },
      {
        name: "Enterprise license",
        configured: !!license,
        healthy: license ? license.expiresAt > new Date() : null,
        detail: license
          ? `${license.customer}: ${license.features.join(", ")} until ${license.expiresAt.toISOString().slice(0, 10)}`
          : "None (Apache-2.0 features only)",
      },
      {
        name: "Telemetry",
        configured: env.TELEMETRY === "on",
        healthy: null,
        detail: env.TELEMETRY === "on" ? "On: weekly anonymous counts" : "Off",
      },
      {
        name: "Billing",
        configured: env.BILLING_ENABLED,
        healthy: null,
        detail: env.BILLING_ENABLED ? "On" : "Off (self-hosted)",
      },
    ];
    return c.json({ items }, 200);
  });

  app.openapi(routes.adminUpdates, async (c) => {
    await requireOwner(requireClaims(c.get("claims")));
    const url = env.UPDATE_CHECK_URL;
    let latest: string | null = null;
    let link: string | null = null;
    if (url) {
      try {
        const r = await fetch(url, {
          headers: { accept: "application/vnd.github+json" },
          signal: AbortSignal.timeout(5000),
        });
        if (r.ok) {
          const j = (await r.json()) as { tag_name?: string; html_url?: string };
          latest = j.tag_name?.replace(/^v/, "") ?? null;
          link = j.html_url ?? null;
        }
      } catch {}
    }
    const newer = (a: string, b: string) => {
      const pa = a.split(".").map(Number);
      const pb = b.split(".").map(Number);
      for (let i = 0; i < 3; i++)
        if ((pa[i] ?? 0) !== (pb[i] ?? 0)) return (pa[i] ?? 0) > (pb[i] ?? 0);
      return false;
    };
    return c.json(
      {
        current: CASAMA_VERSION,
        latest,
        update_available: !!latest && newer(latest, CASAMA_VERSION),
        url: link,
      },
      200,
    );
  });
}
