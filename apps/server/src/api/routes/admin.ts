import { checkVendor, listVendors, updateVendor } from "../../services/vendors/index.ts";
/** Owner admin console (Phase 6): instance totals, users, quotas, services, update notices. */

import { replaceAllDataKeys } from "@casama/agent";
import { routes } from "@casama/contracts";
import type { JwtClaims } from "@casama/db";
import { setCloudMarkup } from "@casama/domain";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { sql } from "drizzle-orm";
import { ee } from "../../ee.ts";
import { suspendOrg, unsuspendOrg } from "../../services/abuse.ts";
import { getAdminBot, isListedOwner, ownerEmails, setAdminBot } from "../../services/admin-bot.ts";
import { capacityReport } from "../../services/capacity.ts";
import { getCloudModels, setCloudModels } from "../../services/cloud-models.ts";
import {
  type ConnectionSettings,
  getConnectionSettings,
  setConnectionSettings,
} from "../../services/connection-settings.ts";
import {
  getDecisionSettings,
  loadDecisionResults,
  setDecisionSettings,
} from "../../services/decisions.ts";
import { mailReservedNames, setMailReservedNames } from "../../services/mail-reserved-names.ts";
import { CASAMA_VERSION } from "../../version.ts";
import {
  ADMIN_PIN_MAX_FAILURES,
  checkPin,
  hasFreshAuthentication,
  pinState,
  recordPasskeyCheck,
  requireSecondStep,
  setPin,
} from "../admin-security.ts";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { iso } from "../util.ts";

export { CASAMA_VERSION };

const num = (v: unknown) => Number(v ?? 0);

function requireClaims(claims: JwtClaims | undefined): JwtClaims {
  if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
  return claims;
}

/** Instance owners: INSTANCE_ADMIN_EMAILS, or the first user to sign up when unset. */
/** Whether someone runs this instance: INSTANCE_ADMIN_EMAILS, else its first account. */
export function isInstanceOwner({ db, env }: Pick<AppDeps, "db" | "env">) {
  return async (claims: JwtClaims) => {
    const allow = (env.INSTANCE_ADMIN_EMAILS ?? "")
      .split(",")
      .map((e) => e.trim().toLowerCase())
      .filter(Boolean);
    const [u] = await db.execute<{ email: string | null; first: boolean }>(sql`
      select u.email, u.id = (select id from auth.users order by created_at limit 1) as first
      from auth.users u where u.id = ${claims.sub}::uuid`);
    return allow.length ? allow.includes((u?.email ?? "").toLowerCase()) : !!u?.first;
  };
}

export function instanceOwnerCheck(deps: Pick<AppDeps, "db" | "env">) {
  const isOwner = isInstanceOwner(deps);
  return async (claims: JwtClaims) => {
    if (!(await isOwner(claims)))
      throw new ApiError(
        403,
        "not_instance_owner",
        "Only the instance owner can open the admin console",
      );
  };
}

export function registerAdminRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db, env } = deps;
  const requireOwner = instanceOwnerCheck(deps);

  app.openapi(routes.adminVendors, async (c) => {
    await requireOwner(requireClaims(c.get("claims")));
    return c.json({ items: await listVendors(db) }, 200);
  });
  app.openapi(routes.setAdminVendor, async (c) => {
    await requireOwner(requireClaims(c.get("claims")));
    const vendor = c.req.valid("param").vendor;
    if (!(await updateVendor(db, vendor, c.req.valid("json"))))
      throw new ApiError(404, "not_found", "Vendor not found");
    const result = (await listVendors(db)).find((v) => v.vendor === vendor);
    if (!result) throw new ApiError(404, "not_found", "Vendor not found");
    return c.json(result, 200);
  });
  app.openapi(routes.checkAdminVendor, async (c) => {
    await requireOwner(requireClaims(c.get("claims")));
    const result = await checkVendor(db, env, c.req.valid("param").vendor);
    if (!result) throw new ApiError(404, "not_found", "Vendor not found");
    return c.json(result, 200);
  });

  const connectionsOut = (settings: ConnectionSettings) => ({
    ...settings,
    composio_key: !!env.COMPOSIO_API_KEY,
    google_direct_available: !!env.GOOGLE_OAUTH_CLIENT_ID && !env.BILLING_ENABLED,
  });

  // The admin bot (D-435): which of the owner's bots may propose admin actions in their chat.
  const adminBotOut = async () => {
    const s = await getAdminBot(db);
    return { ...s, available: ownerEmails(env.INSTANCE_ADMIN_EMAILS).length > 0 };
  };
  app.openapi(routes.adminBot, async (c) => {
    await requireOwner(requireClaims(c.get("claims")));
    return c.json(await adminBotOut(), 200);
  });
  app.openapi(routes.setAdminBot, async (c) => {
    const claims = requireClaims(c.get("claims"));
    await requireOwner(claims);
    const body = c.req.valid("json");
    const current = await getAdminBot(db);
    const botId = body.bot_id === undefined ? current.bot_id : body.bot_id;
    const owners = { db, ownerEmails: ownerEmails(env.INSTANCE_ADMIN_EMAILS) };
    if (body.enabled) {
      if (!owners.ownerEmails.length)
        throw new ApiError(400, "validation_failed", "Set INSTANCE_ADMIN_EMAILS first");
      if (!(await isListedOwner(owners, claims.sub)))
        throw new ApiError(403, "not_instance_owner", "Only a listed instance owner can do this");
      if (!botId) throw new ApiError(400, "validation_failed", "Choose the bot");
      const [bot] = await db.execute<{ org_id: string }>(
        sql`select org_id from public.bots where id = ${botId}::uuid`,
      );
      if (!bot) throw new ApiError(400, "validation_failed", "No such bot");
      const members = await db.execute<{ user_id: string }>(
        sql`select user_id from public.memberships where org_id = ${bot.org_id}::uuid`,
      );
      for (const m of members)
        if (!(await isListedOwner(owners, m.user_id)))
          throw new ApiError(
            400,
            "validation_failed",
            "The admin bot must be in a workspace where everyone is an instance owner",
          );
    }
    await setAdminBot(db, { enabled: body.enabled, bot_id: botId ?? null });
    const [org] = botId
      ? await db.execute<{ org_id: string }>(
          sql`select org_id from public.bots where id = ${botId}::uuid`,
        )
      : [];
    if (org)
      await db.execute(sql`insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id, metadata)
        values (${org.org_id}::uuid, 'user', ${claims.sub}::uuid, 'admin_bot.setting', 'bot', ${botId}::uuid,
                ${JSON.stringify({ enabled: body.enabled })}::jsonb)`);
    deps.logger.info("admin bot setting changed", { by: claims.sub, enabled: body.enabled });
    return c.json(await adminBotOut(), 200);
  });

  app.openapi(routes.adminConnectionSettings, async (c) => {
    await requireOwner(requireClaims(c.get("claims")));
    const settings = await getConnectionSettings(db);
    return c.json(connectionsOut(settings), 200);
  });

  // After a database leak (D-238): every data key is replaced; the worker reseals rows.
  app.openapi(routes.adminReplaceDataKeys, async (c) => {
    const claims = requireClaims(c.get("claims"));
    await requireOwner(claims);
    try {
      const r = await replaceAllDataKeys(db);
      deps.logger.info("data keys replaced", { ...r, by: claims.sub });
      return c.json(r, 200);
    } catch (e) {
      if ((e as Error).message === "not_configured")
        throw new ApiError(409, "encryption_unavailable", "This server has no encryption key.");
      throw e;
    }
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

  // Decision models (D-454): settings and results, owner only.
  app.openapi(routes.adminDecisions, async (c) => {
    await requireOwner(requireClaims(c.get("claims")));
    return c.json(await getDecisionSettings(db), 200);
  });

  app.openapi(routes.setAdminDecisions, async (c) => {
    await requireOwner(requireClaims(c.get("claims")));
    const saved = await setDecisionSettings(db, c.req.valid("json"));
    deps.logger.info("decision settings changed", {
      model: saved.model,
      shadow_models: saved.shadow_models,
      modes: Object.fromEntries(Object.entries(saved.uses).map(([k, v]) => [k, v.mode])),
    });
    return c.json(saved, 200);
  });

  app.openapi(routes.adminDecisionResults, async (c) => {
    await requireOwner(requireClaims(c.get("claims")));
    const q = c.req.valid("query");
    return c.json(await loadDecisionResults(db, q.days ?? 14, q.use), 200);
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

  // What usage on the server's keys was charged against what it cost (D-395).
  app.openapi(routes.adminMargin, async (c) => {
    await requireOwner(requireClaims(c.get("claims")));
    const days = c.req.valid("query").days ?? 30;
    const since = sql`now() - make_interval(days => ${days}::int)`;
    const totals = sql`
      coalesce(sum(l.cost_usd) filter (where l.billable), 0)::text as charged,
      coalesce(sum(l.cost_usd) filter (where l.billable and l.upstream_cost_usd is not null), 0)::text as tracked,
      coalesce(sum(l.upstream_cost_usd), 0)::text as upstream`;
    // Only rows that were charged or cost the server something.
    const scope = sql`l.created_at > ${since} and (l.billable or l.upstream_cost_usd is not null)`;
    type Totals = { charged: string; tracked: string; upstream: string };
    const [[all], byDay, byKind, orgs] = await Promise.all([
      db.execute<Totals>(sql`select ${totals} from public.usage_ledger l where ${scope}`),
      db.execute<Totals & { day: string }>(sql`
        select to_char(date_trunc('day', l.created_at at time zone 'UTC'), 'YYYY-MM-DD') as day, ${totals}
        from public.usage_ledger l where ${scope} group by 1 order by 1`),
      db.execute<Totals & { kind: string }>(sql`
        select l.kind, ${totals} from public.usage_ledger l where ${scope}
        group by 1 order by sum(l.cost_usd) filter (where l.billable) desc nulls last`),
      db.execute<Totals & { org_id: string; name: string; plan_code: string | null }>(sql`
        select l.org_id, o.name, e.plan_code, ${totals}
        from public.usage_ledger l
        join public.organizations o on o.id = l.org_id
        left join lateral (select plan_code from public.entitlements where org_id = l.org_id
          order by created_at desc limit 1) e on true
        where ${scope}
        group by l.org_id, o.name, e.plan_code
        order by sum(l.cost_usd) filter (where l.billable) desc nulls last limit 20`),
    ]);
    const out = (t: Totals | undefined) => ({
      charged_usd: num(t?.charged),
      charged_tracked_usd: num(t?.tracked),
      upstream_usd: num(t?.upstream),
    });
    return c.json(
      {
        days,
        ...out(all),
        by_day: byDay.map((r) => ({ date: r.day, ...out(r) })),
        by_kind: byKind.map((r) => ({ kind: r.kind, ...out(r) })),
        top_orgs: orgs.map((r) => ({
          org_id: r.org_id,
          name: r.name,
          plan_code: r.plan_code,
          ...out(r),
        })),
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

  // Reported public links (D-281).
  const reportRows = (id?: string) =>
    db.execute<{
      id: string;
      org_id: string;
      org_name: string;
      title: string;
      kind: string;
      reports: number;
      reporters: number;
      last_reason: string;
      taken_down: boolean;
      last_reported_at: Date;
    }>(sql`
      select c.id, c.org_id, o.name as org_name, c.title, c.kind, count(r.id)::int as reports,
             count(distinct r.reporter)::int as reporters,
             (array_agg(r.reason order by r.created_at desc))[1] as last_reason,
             c.taken_down_at is not null as taken_down, max(r.created_at) as last_reported_at
      from public.creation_reports r
      join public.creations c on c.id = r.creation_id
      join public.organizations o on o.id = c.org_id
      ${id ? sql`where c.id = ${id}::uuid` : sql``}
      group by c.id, o.name order by count(r.id) desc, max(r.created_at) desc limit 200`);
  const reportOut = (r: Awaited<ReturnType<typeof reportRows>>[number]) => ({
    ...r,
    last_reported_at: new Date(r.last_reported_at).toISOString(),
  });

  app.openapi(routes.listReportedCreations, async (c) => {
    await requireOwner(requireClaims(c.get("claims")));
    return c.json({ items: (await reportRows()).map(reportOut) }, 200);
  });

  app.openapi(routes.takeDownCreation, async (c) => {
    const claims = requireClaims(c.get("claims"));
    await requireOwner(claims);
    const { id } = c.req.valid("param");
    const { down } = c.req.valid("json");
    const [row] = await db.execute<{ org_id: string; page_id: string | null }>(sql`
      update public.creations set taken_down_at = ${down ? sql`now()` : sql`null`} where id = ${id}::uuid
      returning org_id, page_id`);
    if (!row) throw new ApiError(404, "creation_not_found", "Not found");
    // A page's public link is the page's own: taking it down makes the page private.
    if (down && row.page_id)
      await db.execute(sql`
        update public.pages set visibility = 'private', public_token_hash = null where id = ${row.page_id}::uuid`);
    const [r] = await reportRows(id);
    if (!r) throw new ApiError(404, "creation_not_found", "No reports for that");
    return c.json(reportOut(r), 200);
  });

  // Hosted bot mail (BOT-EMAIL-PLAN Phase 3): every address with its recent sending health.
  const mailRows = (id?: string) =>
    db.execute<{
      id: string;
      local_part: string;
      org_id: string | null;
      org_name: string | null;
      bot_id: string | null;
      bot_name: string | null;
      status: "active" | "paused" | "retired";
      auto_paused_at: string | null;
      sent_30d: number;
      bounced_30d: number;
      complained_30d: number;
      created_at: string;
    }>(sql`
      select a.id, a.local_part, a.org_id, o.name as org_name, a.bot_id, b.name as bot_name,
             a.status, a.auto_paused_at,
             (select count(*)::int from public.mail_messages m
              where m.address_id = a.id and m.direction = 'out' and m.created_at > now() - interval '30 days') as sent_30d,
             (select count(*)::int from public.mail_events e
              where e.address_id = a.id and e.event = 'bounced' and e.created_at > now() - interval '30 days') as bounced_30d,
             (select count(*)::int from public.mail_events e
              where e.address_id = a.id and e.event = 'complained' and e.created_at > now() - interval '30 days') as complained_30d,
             a.created_at
      from public.mail_addresses a
      left join public.organizations o on o.id = a.org_id
      left join public.bots b on b.id = a.bot_id
      ${id ? sql`where a.id = ${id}::uuid` : sql``}
      order by a.created_at desc limit 500`);
  const mailOut = (domain: string, r: Awaited<ReturnType<typeof mailRows>>[number]) => ({
    id: r.id,
    address: `${r.local_part}@${domain}`,
    org_id: r.org_id,
    org_name: r.org_name ?? "(deleted)",
    bot_id: r.bot_id,
    bot_name: r.bot_name ?? "(deleted)",
    status: r.status,
    auto_paused: !!r.auto_paused_at,
    sent_30d: Number(r.sent_30d),
    bounced_30d: Number(r.bounced_30d),
    complained_30d: Number(r.complained_30d),
    created_at: iso(r.created_at),
  });

  app.openapi(routes.adminMailAddresses, async (c) => {
    const claims = requireClaims(c.get("claims"));
    await requireOwner(claims);
    const domain = deps.hostedMail?.domain ?? env.MAIL_DOMAIN ?? "mail";
    const [day] = await db.execute<{ n: number }>(sql`
      select count(*)::int as n from public.mail_messages
      where direction = 'out' and created_at > now() - interval '1 day'`);
    return c.json(
      {
        items: (await mailRows()).map((r) => mailOut(domain, r)),
        sent_today: day?.n ?? 0,
        send_ceiling: deps.hostedMail?.sender.dailyCeiling || null,
      },
      200,
    );
  });

  app.openapi(routes.setMailAddressStatus, async (c) => {
    const claims = requireClaims(c.get("claims"));
    await requireOwner(claims);
    const { id } = c.req.valid("param");
    const { status } = c.req.valid("json");
    // Lifting clears the automatic pause; pausing from here is the owner's own.
    const [row] = await db.execute<{ id: string }>(sql`
      update public.mail_addresses
      set status = ${status}, auto_paused_at = ${status === "active" ? sql`null` : sql`auto_paused_at`},
          updated_at = now()
      where id = ${id}::uuid and status <> 'retired' returning id`);
    if (!row) throw new ApiError(404, "address_not_found", "No such address");
    const domain = deps.hostedMail?.domain ?? env.MAIL_DOMAIN ?? "mail";
    const [r] = await mailRows(id);
    if (!r) throw new ApiError(404, "address_not_found", "No such address");
    return c.json(mailOut(domain, r), 200);
  });

  app.openapi(routes.adminMailReservedNames, async (c) => {
    const claims = requireClaims(c.get("claims"));
    await requireOwner(claims);
    return c.json({ names: await mailReservedNames(db) }, 200);
  });

  app.openapi(routes.setMailReservedNames, async (c) => {
    const claims = requireClaims(c.get("claims"));
    await requireOwner(claims);
    const { names } = c.req.valid("json");
    return c.json({ names: await setMailReservedNames(db, names) }, 200);
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
    // Its servers' addresses come down with it (D-296); they return after the suspension is lifted.
    await deps.casamaLink?.servers?.suspendOrg(id);
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
        limits = public.entitlement_limits(plan_code, subscription_id, ${JSON.stringify(limits)}::jsonb)
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
          const r = await fetch(`${env.SUPERVISOR_URL}/healthz`, {
            signal: AbortSignal.timeout(5000),
          });
          if (!r.ok) throw new Error();
        })
      : null;
    const license = ee
      ? await ee.verifyLicense(
          env.CASAMA_LICENSE_KEY,
          env.NODE_ENV === "test" ? env.CASAMA_LICENSE_PUBLIC_KEY : undefined,
        )
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
          : ee
            ? "None (open-source features only)"
            : "Open-source edition (built without ee/)",
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

  // ---------------------------------------------------------------------------
  // Pricing (D-244): plans, credit packs and the markup, changed live without a deploy.
  // ---------------------------------------------------------------------------

  type PlanRow = {
    code: string;
    name: string;
    interval: "none" | "week" | "month" | "year";
    active: boolean;
    sort: number;
    price_label: string | null;
    limits: Record<string, number | boolean>;
    store_product_ids: Record<string, string> | null;
    dodo_product_id: string | null;
    paywall_default: boolean;
    paywall_popular: boolean;
    workspaces: number;
  };
  type PackRow = {
    code: string;
    name: string;
    credits_usd: string;
    active: boolean;
    price_label: string | null;
    store_product_ids: Record<string, string> | null;
    dodo_product_id: string | null;
  };
  const planRows = (code?: string) =>
    db.execute<PlanRow>(sql`
      select p.code, p.name, p.interval, p.active, p.sort, p.price_label, p.limits, p.store_product_ids,
             p.dodo_product_id, p.paywall_default, p.paywall_popular,
             (select count(*)::int from public.organizations o where o.plan = p.code) as workspaces
      from public.plans p ${code ? sql`where p.code = ${code}` : sql``} order by p.sort, p.code`);
  const planOut = (p: PlanRow) => ({
    ...p,
    limits: Object.fromEntries(
      Object.entries(p.limits ?? {}).filter(([, v]) => typeof v === "number"),
    ) as Record<string, number>,
    credit_gate: p.limits?.credit_gate === true,
    store_product_ids: p.store_product_ids ?? {},
  });
  const packRows = (code?: string) =>
    db.execute<PackRow>(sql`
      select code, name, credits_usd, active, price_label, store_product_ids, dodo_product_id
      from public.credit_packs ${code ? sql`where code = ${code}` : sql``} order by credits_usd`);
  const packOut = (p: PackRow) => ({
    ...p,
    credits_usd: Number(p.credits_usd),
    store_product_ids: p.store_product_ids ?? {},
  });
  const markup = async () => {
    const [r] = await db.execute<{ markup: string }>(
      sql`select markup from public.billing_settings where id`,
    );
    return Number(r?.markup ?? 1.3);
  };

  app.openapi(routes.adminCapacity, async (c) => {
    await requireOwner(requireClaims(c.get("claims")));
    return c.json(
      await capacityReport(db, Math.round((env.COMPUTER_HOST_MEMORY_GB ?? 0) * 1024)),
      200,
    );
  });

  app.openapi(routes.adminPricing, async (c) => {
    await requireOwner(requireClaims(c.get("claims")));
    return c.json(
      {
        billing_enabled: env.BILLING_ENABLED,
        plans: (await planRows()).map(planOut),
        packs: (await packRows()).map(packOut),
        settings: { markup: await markup() },
      },
      200,
    );
  });

  app.openapi(routes.savePlan, async (c) => {
    await requireOwner(requireClaims(c.get("claims")));
    const { code } = c.req.valid("param");
    const b = c.req.valid("json");
    if (code === "selfhost")
      throw new ApiError(400, "plan_locked", "The self-hosted plan can't be changed");
    const [existing] = await planRows(code);
    if (!existing && (!b.name || !b.interval))
      throw new ApiError(400, "plan_incomplete", "A new plan needs a name and an interval");
    if (existing && b.active === false && existing.code === "free")
      throw new ApiError(400, "plan_locked", "The free plan is every workspace's default");
    const ids = b.store_product_ids === undefined ? null : JSON.stringify(b.store_product_ids);
    // credit_gate is stored with the limits; a save that leaves it out keeps the current value.
    const gate = b.credit_gate ?? existing?.limits?.credit_gate === true;
    const limits =
      b.limits === undefined && b.credit_gate === undefined
        ? null
        : JSON.stringify({
            ...(b.limits ??
              Object.fromEntries(
                Object.entries(existing?.limits ?? {}).filter(([, v]) => typeof v === "number"),
              )),
            ...(gate ? { credit_gate: true } : {}),
          });
    await db.transaction(async (tx) => {
      // One plan opens the paywall: picking this one unpicks the rest.
      if (b.paywall_default === true)
        await tx.execute(
          sql`update public.plans set paywall_default = false where paywall_default and code <> ${code}`,
        );
      await tx.execute(sql`
        insert into public.plans (code, name, interval, active, sort, price_label, limits, store_product_ids, dodo_product_id, paywall_default, paywall_popular)
        values (${code}, ${b.name ?? code}, ${b.interval ?? "month"}, ${b.active ?? true}, ${b.sort ?? 100},
                ${b.price_label ?? null}, coalesce(${limits}::jsonb, '{}'::jsonb), coalesce(${ids}::jsonb, '{}'::jsonb),
                ${b.dodo_product_id ?? null}, ${b.paywall_default ?? false}, ${b.paywall_popular ?? false})
        on conflict (code) do update set
          name = coalesce(${b.name ?? null}, plans.name),
          interval = coalesce(${b.interval ?? null}, plans.interval),
          active = coalesce(${b.active ?? null}::boolean, plans.active),
          sort = coalesce(${b.sort ?? null}::int, plans.sort),
          price_label = case when ${b.price_label !== undefined}::boolean then ${b.price_label ?? null} else plans.price_label end,
          limits = coalesce(${limits}::jsonb, plans.limits),
          store_product_ids = coalesce(${ids}::jsonb, plans.store_product_ids),
          dodo_product_id = case when ${b.dodo_product_id !== undefined}::boolean then ${b.dodo_product_id ?? null} else plans.dodo_product_id end,
          paywall_default = coalesce(${b.paywall_default ?? null}::boolean, plans.paywall_default),
          paywall_popular = coalesce(${b.paywall_popular ?? null}::boolean, plans.paywall_popular)`);
      // Every workspace on the plan gets the new limits now; owner overrides stay on top.
      if (limits)
        await tx.execute(sql`
          update public.entitlements e
             set limits = public.entitlement_limits(e.plan_code, e.subscription_id, e.overrides),
                 updated_at = now()
           where e.plan_code = ${code}`);
    });
    const [p] = await planRows(code);
    return c.json(planOut(p as PlanRow), 200);
  });

  app.openapi(routes.saveCreditPack, async (c) => {
    await requireOwner(requireClaims(c.get("claims")));
    const { code } = c.req.valid("param");
    const b = c.req.valid("json");
    const [existing] = await packRows(code);
    if (!existing && (!b.name || b.credits_usd === undefined))
      throw new ApiError(400, "pack_incomplete", "A new pack needs a name and an amount");
    const ids = b.store_product_ids === undefined ? null : JSON.stringify(b.store_product_ids);
    await db.execute(sql`
      insert into public.credit_packs (code, name, credits_usd, active, price_label, store_product_ids, dodo_product_id)
      values (${code}, ${b.name ?? code}, ${b.credits_usd ?? 1}, ${b.active ?? true}, ${b.price_label ?? null},
              coalesce(${ids}::jsonb, '{}'::jsonb), ${b.dodo_product_id ?? null})
      on conflict (code) do update set
        name = coalesce(${b.name ?? null}, credit_packs.name),
        credits_usd = coalesce(${b.credits_usd ?? null}::numeric, credit_packs.credits_usd),
        active = coalesce(${b.active ?? null}::boolean, credit_packs.active),
        price_label = case when ${b.price_label !== undefined}::boolean then ${b.price_label ?? null} else credit_packs.price_label end,
        store_product_ids = coalesce(${ids}::jsonb, credit_packs.store_product_ids),
        dodo_product_id = case when ${b.dodo_product_id !== undefined}::boolean then ${b.dodo_product_id ?? null} else credit_packs.dodo_product_id end`);
    const [p] = await packRows(code);
    return c.json(packOut(p as PackRow), 200);
  });

  app.openapi(routes.setBillingSettings, async (c) => {
    const claims = requireClaims(c.get("claims"));
    await requireOwner(claims);
    const { markup: m } = c.req.valid("json");
    await db.execute(sql`
      update public.billing_settings set markup = ${m}, updated_at = now(), updated_by = ${claims.sub}::uuid where id`);
    // This process takes it now; the worker picks it up within a minute.
    setCloudMarkup(m);
    return c.json({ markup: await markup() }, 200);
  });

  // --- Admin checks (D-452): a passkey or the admin PIN instead of signing in again ------------

  /** Setting or removing the PIN: a fresh real sign-in or passkey check, never the PIN itself. */
  const requireCheckWithoutPin = async (claims: JwtClaims) => {
    if (hasFreshAuthentication(claims, true)) {
      await requireSecondStep(db, claims, true);
      return;
    }
    const session = typeof claims.session_id === "string" ? claims.session_id : "";
    const [row] = await db.execute<{ ok: boolean }>(sql`
      select exists (
        select 1 from public.admin_step_ups
        where session_id::text = ${session} and user_id = ${claims.sub}::uuid and method = 'passkey'
          and verified_at <= now() and verified_at > now() - interval '60 seconds'
      ) as ok`);
    if (!row?.ok)
      throw new ApiError(
        403,
        "admin_pin_needs_sign_in",
        "Confirm with a passkey or your password to change the admin PIN.",
      );
  };

  app.openapi(routes.adminPin, async (c) => {
    const claims = requireClaims(c.get("claims"));
    await requireOwner(claims);
    return c.json(await pinState(db, claims.sub), 200);
  });

  app.openapi(routes.setAdminPin, async (c) => {
    const claims = requireClaims(c.get("claims"));
    await requireOwner(claims);
    await requireCheckWithoutPin(claims);
    await setPin(db, claims.sub, c.req.valid("json").pin);
    return c.json(await pinState(db, claims.sub), 200);
  });

  app.openapi(routes.removeAdminPin, async (c) => {
    const claims = requireClaims(c.get("claims"));
    await requireOwner(claims);
    await requireCheckWithoutPin(claims);
    await setPin(db, claims.sub, null);
    return c.json(await pinState(db, claims.sub), 200);
  });

  app.openapi(routes.adminPasskeyCheck, async (c) => {
    const claims = requireClaims(c.get("claims"));
    await requireOwner(claims);
    let proof: JwtClaims;
    try {
      proof = await deps.verifyToken(c.req.valid("json").token);
    } catch {
      throw new ApiError(403, "admin_check_failed", "That passkey didn't confirm this account.");
    }
    const at = await recordPasskeyCheck(db, claims, proof);
    return c.json({ verified_at: at.toISOString() }, 200);
  });

  app.openapi(routes.adminPinCheck, async (c) => {
    const claims = requireClaims(c.get("claims"));
    await requireOwner(claims);
    const result = await checkPin(db, claims, c.req.valid("json").pin);
    if (result.ok) return c.json({ verified_at: result.at.toISOString() }, 200);
    deps.logger.warn("wrong admin PIN", { user: claims.sub, disabled: result.disabled });
    if (result.disabled) {
      const to = typeof claims.email === "string" ? claims.email : null;
      if (to && deps.email.enabled)
        void deps.email
          .send({
            to,
            subject: "Your admin PIN was turned off",
            text:
              `Someone entered a wrong admin PIN ${ADMIN_PIN_MAX_FAILURES} times in a row on your ` +
              "Casama server's admin console, so the PIN is turned off. Unlock with a passkey or " +
              "your password, then set a new PIN in the admin console under Security. If this " +
              "wasn't you, change your password and sign out everywhere.",
          })
          .catch((e: unknown) =>
            deps.logger.warn("admin PIN email failed", { error: (e as Error).message }),
          );
      throw new ApiError(
        403,
        "admin_pin_disabled",
        "Too many wrong PINs: the admin PIN is turned off. Use a passkey or your password.",
      );
    }
    throw new ApiError(
      403,
      "admin_pin_wrong",
      `Wrong PIN. ${result.triesLeft} ${result.triesLeft === 1 ? "try" : "tries"} left.`,
    );
  });
}
