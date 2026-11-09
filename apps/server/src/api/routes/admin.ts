/** Owner admin console (Phase 6): instance totals, users, quotas, services, update notices. */
import type { OpenAPIHono } from "@hono/zod-openapi";
import { routes } from "@kasama/contracts";
import type { JwtClaims } from "@kasama/db";
import { sql } from "drizzle-orm";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { iso } from "../util.ts";

export const KASAMA_VERSION = "0.6.0";

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
        version: KASAMA_VERSION,
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
    }>(sql`
      select o.id, o.name, e.plan_code, e.limits,
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
  });

  app.openapi(routes.adminOrgs, async (c) => {
    await requireOwner(requireClaims(c.get("claims")));
    return c.json({ items: (await orgRows()).map(orgOut) }, 200);
  });

  app.openapi(routes.setOrgLimits, async (c) => {
    await requireOwner(requireClaims(c.get("claims")));
    const { id } = c.req.valid("param");
    const { limits } = c.req.valid("json");
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
        configured: !!env.RESEND_API_KEY,
        healthy: null,
        detail: env.RESEND_API_KEY ? "Resend" : "Off: invites return a code",
      },
      {
        name: "Error reporting",
        configured: !!(env.SENTRY_DSN || env.POSTHOG_API_KEY),
        healthy: null,
        detail: env.SENTRY_DSN ? "Sentry protocol" : env.POSTHOG_API_KEY ? "PostHog" : "Off",
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
        current: KASAMA_VERSION,
        latest,
        update_available: !!latest && newer(latest, KASAMA_VERSION),
        url: link,
      },
      200,
    );
  });
}
