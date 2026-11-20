/**
 * What Casama Help can look up about the person asking (D-298): usage against the plan, credit
 * history, connected apps and keys, one bot in detail, and invites. All read-only, and only about
 * the person and the workspace open in the app.
 *
 * The assistant sees what the app would show the same person, no more: workspace queries run in
 * the person's own database session (row-level security applies), private bots of other people
 * stay hidden, spend per person is for admins only (as on the Usage page), and nothing returns
 * secrets, tokens or connection settings.
 */
import { type Database, type JwtClaims, withUserSession } from "@casama/db";
import { cloudModelDailyCap } from "@casama/domain";
import { sql } from "drizzle-orm";
import { gateClosed, getSignupGate, memberInvites } from "../../services/waitlist.ts";

type Billing = {
  enabled: boolean;
  summary(orgId: string): Promise<{
    plan_code: string;
    plan_name: string;
    interval: string;
    limits: Record<string, number>;
    unlimited: boolean;
    extra_seats: number;
    credits_usd: number;
  }>;
};

const iso = (d: Date | string | null | undefined) => (d ? new Date(d).toISOString() : null);
const usd = (v: unknown) => Math.round(Number(v ?? 0) * 100) / 100;
const clip = (v: unknown, n: number) => {
  if (v == null) return null;
  const s = typeof v === "string" ? v : JSON.stringify(v);
  return s.length > n ? `${s.slice(0, n)}…` : s;
};
const NO_WORKSPACE = "No workspace is open in the app.";

/** The tool definitions the model sees, next to the ones in support.ts. */
export const LOOKUP_TOOLS = [
  {
    type: "function",
    function: {
      name: "get_usage",
      description:
        "This month's spending in the workspace open in the app, measured against its plan: total, by bot and by kind, today's spend against the daily cap, computer hours, bots, computers and seats used against their limits, credits, and runs the limits stopped in the last 7 days.",
      parameters: { type: "object", properties: {} },
    },
  },
  {
    type: "function",
    function: {
      name: "get_credit_history",
      description:
        "The workspace's latest credit entries (purchases, monthly grants, usage charges, refunds, expiries) and the credits that will expire, with dates.",
      parameters: { type: "object", properties: {} },
    },
  },
  {
    type: "function",
    function: {
      name: "get_connections",
      description:
        "Apps connected to the workspace, chat channels (Telegram, WhatsApp and so on) linked to bots, and model keys, each with its status and last error. Use it when a bot can't reach an app, stopped answering in a chat app, or a model key fails.",
      parameters: { type: "object", properties: {} },
    },
  },
  {
    type: "function",
    function: {
      name: "get_bot",
      description:
        "One bot in the workspace in detail: status, setup, model, budget, routines with their next runs, connected apps, chat channels and its last runs with full errors.",
      parameters: {
        type: "object",
        properties: { name: { type: "string", description: "The bot's name, or part of it" } },
        required: ["name"],
      },
    },
  },
  {
    type: "function",
    function: {
      name: "get_invites",
      description:
        "Invites to workspaces sent to this person's email, and their requests to join workspaces. For an owner or admin, also the invites and join requests waiting in the open workspace. While Casama Cloud is invite-only, also this person's own invite code and how many invites they have left.",
      parameters: { type: "object", properties: {} },
    },
  },
] as const;

export function supportLookups(
  db: Database,
  billing: Billing,
  opts: {
    /** Casama Cloud's waitlist (D-427) exists on this server, and the link base for invite codes. */
    waitlist?: { inviteBase: string } | null;
  } = {},
) {
  const asPerson = <T>(claims: JwtClaims, fn: Parameters<typeof withUserSession<T>>[2]) =>
    withUserSession(db, claims, fn);

  const usage = async (claims: JwtClaims, orgId: string | null) => {
    if (!orgId) return NO_WORKSPACE;
    const s = await billing.summary(orgId);
    // Totals and counts cover the whole workspace (the caller checked membership); naming bots
    // and reading runs happens in the person's session, so private bots stay private.
    return asPerson(claims, async (tx) => {
      const month = sql`date_trunc('month', now() at time zone 'utc') at time zone 'utc'`;
      const day = sql`date_trunc('day', now() at time zone 'utc') at time zone 'utc'`;
      const paid = sql`u.org_id = ${orgId}::uuid and u.created_at >= ${month} and coalesce(u.meta ->> 'waived', '') <> 'failed_run'`;
      const [t] = await db.execute<{
        total: string | null;
        waived: string | null;
        today: string | null;
        computer_seconds: string | null;
        unbilled: string | null;
        bots: number;
        computers: number;
        members: number;
        quota: string | null;
      }>(sql`
        select
          (select sum(u.cost_usd) from public.usage_ledger u where ${paid}) as total,
          (select sum(u.cost_usd) from public.usage_ledger u where u.org_id = ${orgId}::uuid
             and u.created_at >= ${month} and u.meta ->> 'waived' = 'failed_run') as waived,
          (select sum(u.cost_usd) from public.usage_ledger u where u.org_id = ${orgId}::uuid and u.billable
             and u.kind <> all('{computer_seconds,stream_seconds}'::text[]) and u.created_at >= ${day}) as today,
          (select sum(u.quantity) from public.usage_ledger u where u.org_id = ${orgId}::uuid
             and u.kind = 'computer_seconds' and u.created_at >= ${month}) as computer_seconds,
          (select sum(u.cost_usd) from public.usage_ledger u where u.org_id = ${orgId}::uuid
             and u.billable and u.billed_at is null) as unbilled,
          (select count(*)::int from public.bots where org_id = ${orgId}::uuid and archived_at is null) as bots,
          (select count(*)::int from public.computers where org_id = ${orgId}::uuid and provider <> 'local') as computers,
          (select count(*)::int from public.memberships where org_id = ${orgId}::uuid) as members,
          (select max_cost_usd from public.quotas where org_id = ${orgId}::uuid and period = 'month') as quota`);
      const byBot = await tx.execute<{ name: string | null; cost: string }>(sql`
        select case when u.bot_id is null then null
                    when public.can_access_bot(u.bot_id) then (select b.name from public.bots b where b.id = u.bot_id)
                    else 'a private bot' end as name,
               sum(u.cost_usd) as cost
        from public.usage_ledger u
        where ${paid} group by 1 order by cost desc limit 6`);
      const byKind = await db.execute<{ kind: string; quantity: string; cost: string }>(sql`
        select u.kind, sum(u.quantity) as quantity, sum(u.cost_usd) as cost from public.usage_ledger u
        where ${paid} group by 1 order by cost desc limit 8`);
      const stops = await tx.execute<{ code: string; n: number; last: Date }>(sql`
        select r.error ->> 'code' as code, count(*)::int as n, max(r.created_at) as last from public.runs r
        where r.org_id = ${orgId}::uuid and r.status = 'failed' and r.created_at > now() - interval '7 days'
          and r.error ->> 'code' is not null and public.can_access_bot(r.bot_id)
        group by 1 order by n desc limit 8`);
      const lim = s.limits;
      const of = (used: number, limit: number | undefined) =>
        limit == null ? { used } : { used, limit };
      const hours = Math.round((Number(t?.computer_seconds ?? 0) / 3600) * 10) / 10;
      return {
        period: "this month (UTC)",
        plan: s.plan_name,
        unlimited: s.unlimited,
        spent_usd: usd(t?.total),
        waived_for_failed_runs_usd: usd(t?.waived),
        by_bot: byBot.map((b) => ({ bot: b.name ?? "workspace (no bot)", usd: usd(b.cost) })),
        by_kind: byKind.map((k) => ({
          kind: k.kind,
          quantity: Number(k.quantity),
          usd: usd(k.cost),
        })),
        ...(billing.enabled
          ? {
              today_on_casama_keys_usd: {
                used: usd(t?.today),
                daily_cap: cloudModelDailyCap(s.plan_code, lim.cloud_daily_usd),
              },
              credits_usd: usd(s.credits_usd),
              not_yet_charged_usd: usd(t?.unbilled),
              credits_needed_to_run: (lim as Record<string, unknown>).credit_gate === true,
              monthly_credits_included_usd: lim.monthly_credits_usd ?? null,
            }
          : {}),
        monthly_spending_cap_usd: t?.quota == null ? null : usd(t.quota),
        computer_hours: of(hours, lim.computer_hours),
        computer_hours_note:
          "Only Casama's cloud computers use computer hours. A person's own computer (connected from the desktop app) never does, and is never stopped by them.",
        bots: of(t?.bots ?? 0, lim.max_bots),
        computers: of(t?.computers ?? 0, lim.max_computers),
        seats: of(t?.members ?? 0, lim.seats == null ? undefined : lim.seats + s.extra_seats),
        stopped_runs_last_7_days: stops.map((r) => ({
          reason: r.code,
          runs: r.n,
          last: iso(r.last),
        })),
      };
    });
  };

  const creditHistory = async (_claims: JwtClaims, orgId: string | null) => {
    if (!orgId) return NO_WORKSPACE;
    if (!billing.enabled) return "This server is self-hosted: there are no credits.";
    {
      const entries = await db.execute<{
        delta: string;
        reason: string;
        note: string | null;
        balance_after: string;
        created_at: Date;
      }>(sql`
        select delta, reason, note, balance_after, created_at from public.credit_ledger
        where org_id = ${orgId}::uuid order by seq desc limit 20`);
      const lots = await db.execute<{
        reason: string;
        remaining: string;
        expires_at: Date | null;
      }>(sql`
        select reason, remaining, expires_at from public.credit_lots
        where org_id = ${orgId}::uuid and remaining > 0 and expires_at is not null and expires_at > now()
        order by expires_at limit 10`);
      if (!entries.length) return "No credit entries yet in this workspace.";
      return {
        balance_usd: usd(entries[0]?.balance_after),
        entries: entries.map((e) => ({
          at: iso(e.created_at),
          change_usd: Math.round(Number(e.delta) * 10_000) / 10_000,
          reason: e.reason,
          note: clip(e.note, 160),
          balance_after_usd: usd(e.balance_after),
        })),
        expiring: lots.map((l) => ({
          reason: l.reason,
          usd: usd(l.remaining),
          expires_at: iso(l.expires_at),
        })),
      };
    }
  };

  const connections = async (claims: JwtClaims, orgId: string | null) => {
    if (!orgId) return NO_WORKSPACE;
    return asPerson(claims, async (tx) => {
      const apps = await tx.execute<{
        name: string;
        kind: string;
        status: string;
        error: string | null;
        bots: number;
        created_at: Date;
      }>(sql`
        select i.name, i.kind, i.status, i.error, i.created_at,
               (select count(*)::int from public.bot_integrations bi where bi.integration_id = i.id) as bots
        from public.integrations i where i.org_id = ${orgId}::uuid order by i.created_at desc limit 30`);
      const channels = await tx.execute<{
        bot: string;
        kind: string;
        name: string;
        enabled: boolean;
        last_inbound_at: Date | null;
        last_error: string | null;
      }>(sql`
        select b.name as bot, c.kind, c.name, c.enabled, c.last_inbound_at, c.last_error
        from public.channels c join public.bots b on b.id = c.bot_id
        where c.org_id = ${orgId}::uuid and public.can_access_bot(c.bot_id)
        order by c.created_at desc limit 20`);
      const keys = await tx.execute<{
        provider: string;
        label: string;
        status: string;
        last_test_ok: boolean | null;
        last_tested_at: Date | null;
        mine: boolean;
      }>(sql`
        select k.provider, k.label, k.status, k.last_test_ok, k.last_tested_at,
               k.owner_user_id is not null as mine
        from public.model_credentials k
        where k.org_id = ${orgId}::uuid and (k.owner_user_id is null or k.owner_user_id = ${claims.sub}::uuid)
        order by k.created_at desc limit 20`);
      return {
        apps: apps.map((a) => ({
          name: a.name,
          kind: a.kind,
          status: a.status,
          error: clip(a.error, 300),
          used_by_bots: a.bots,
          connected: iso(a.created_at),
        })),
        chat_channels: channels.map((c) => ({
          bot: c.bot,
          kind: c.kind,
          name: c.name,
          enabled: c.enabled,
          last_message_in: iso(c.last_inbound_at),
          last_error: clip(c.last_error, 300),
        })),
        model_keys: keys.map((k) => ({
          provider: k.provider,
          label: k.label,
          status: k.status,
          last_test: k.last_tested_at
            ? { ok: k.last_test_ok, at: iso(k.last_tested_at) }
            : "never tested",
          personal: k.mine,
        })),
      };
    });
  };

  const bot = async (claims: JwtClaims, orgId: string | null, query: string) => {
    if (!orgId) return NO_WORKSPACE;
    const q = query.trim().slice(0, 80);
    if (!q) return "Say which bot.";
    return asPerson(claims, async (tx) => {
      const found = await tx.execute<{
        id: string;
        name: string;
        status: string;
        setup_status: string | null;
        autonomy: string;
        visibility: string;
        archived_at: Date | null;
        model_policy: Record<string, unknown>;
        budget: Record<string, unknown>;
        created_at: Date;
      }>(sql`
        select b.id, b.name, b.status, b.setup_status, b.autonomy::text as autonomy,
               b.visibility::text as visibility, b.archived_at, b.model_policy, b.budget, b.created_at
        from public.bots b
        where b.org_id = ${orgId}::uuid and public.can_access_bot(b.id)
          and b.name ilike ${`%${q.replace(/[\\%_]/g, (c) => `\\${c}`)}%`}
        order by (lower(b.name) = lower(${q})) desc, b.archived_at nulls first, b.created_at limit 6`);
      const b = found[0];
      if (!b) return "No bot by that name that this person can see in the open workspace.";
      if (found.length > 1 && b.name.toLowerCase() !== q.toLowerCase())
        return { several_match: found.map((f) => f.name), ask: "Ask which one they mean." };
      const [routines, apps, channels, runs] = await Promise.all([
        tx.execute<{
          name: string;
          enabled: boolean;
          schedule_cron: string | null;
          timezone: string;
          trigger: Record<string, unknown>;
          next_run_at: Date | null;
          last_run_at: Date | null;
          ends_at: Date | null;
          max_runs: number | null;
          run_count: number;
        }>(sql`
          select name, enabled, schedule_cron, timezone, trigger, next_run_at, last_run_at, ends_at, max_runs, run_count
          from public.routines where bot_id = ${b.id}::uuid order by created_at limit 10`),
        tx.execute<{ name: string; status: string; error: string | null }>(sql`
          select i.name, i.status, i.error from public.bot_integrations bi
          join public.integrations i on i.id = bi.integration_id where bi.bot_id = ${b.id}::uuid limit 20`),
        tx.execute<{ kind: string; name: string; enabled: boolean; last_error: string | null }>(sql`
          select kind, name, enabled, last_error from public.channels where bot_id = ${b.id}::uuid limit 10`),
        tx.execute<{
          trigger: string;
          status: string;
          created_at: Date;
          cost_usd: string | null;
          error: unknown;
        }>(sql`
          select trigger, status, created_at, cost_usd, error from public.runs
          where bot_id = ${b.id}::uuid order by created_at desc limit 5`),
      ]);
      const primary = (b.model_policy?.primary ?? null) as { model?: string } | null;
      return {
        id: b.id,
        name: b.name,
        status: b.status,
        setup: b.setup_status,
        archived: b.archived_at ? iso(b.archived_at) : false,
        visibility: b.visibility,
        autonomy: b.autonomy,
        model: primary?.model ?? "Casama picks",
        budget_usd: b.budget,
        created: iso(b.created_at),
        routines: routines.map((r) => ({
          name: r.name,
          enabled: r.enabled,
          schedule: r.schedule_cron ? `${r.schedule_cron} (${r.timezone})` : r.trigger?.type,
          next_run: iso(r.next_run_at),
          last_run: iso(r.last_run_at),
          ends: iso(r.ends_at),
          runs: r.max_runs ? `${r.run_count} of ${r.max_runs}` : r.run_count,
        })),
        apps: apps.map((a) => ({ name: a.name, status: a.status, error: clip(a.error, 200) })),
        chat_channels: channels.map((c) => ({
          kind: c.kind,
          name: c.name,
          enabled: c.enabled,
          last_error: clip(c.last_error, 200),
        })),
        last_runs: runs.map((r) => ({
          trigger: r.trigger,
          status: r.status,
          at: iso(r.created_at),
          usd: r.cost_usd == null ? null : Math.round(Number(r.cost_usd) * 1000) / 1000,
          error: clip(r.error, 800),
        })),
      };
    });
  };

  const invites = async (claims: JwtClaims, orgId: string | null) => {
    const [u] = await db.execute<{ email: string | null }>(
      sql`select email from auth.users where id = ${claims.sub}::uuid`,
    );
    const email = u?.email ?? claims.email ?? null;
    const mine = email
      ? await db.execute<{
          workspace: string;
          role: string;
          expires_at: Date | null;
          accepted_at: Date | null;
        }>(sql`
          select o.name as workspace, i.role::text as role, i.expires_at, i.accepted_at
          from public.invites i join public.organizations o on o.id = i.org_id
          where lower(i.email) = lower(${email}) order by i.created_at desc limit 10`)
      : [];
    const asked = await db.execute<{ workspace: string; status: string; created_at: Date }>(sql`
      select o.name as workspace, j.status, j.created_at
      from public.join_requests j join public.organizations o on o.id = j.org_id
      where j.user_id = ${claims.sub}::uuid order by j.created_at desc limit 10`);
    const now = Date.now();
    const out: Record<string, unknown> = {
      invites_to_me: mine.map((i) => ({
        workspace: i.workspace,
        role: i.role,
        state: i.accepted_at
          ? "accepted"
          : i.expires_at && new Date(i.expires_at).getTime() < now
            ? "expired"
            : "waiting",
        expires: iso(i.expires_at),
      })),
      my_join_requests: asked.map((j) => ({
        workspace: j.workspace,
        status: j.status,
        asked: iso(j.created_at),
      })),
    };
    // Casama Cloud while it's invite-only (D-427): the person's own invites, so Help can say how
    // many friends they can still let in and where to send them.
    if (opts.waitlist) {
      try {
        const gate = await getSignupGate(db);
        if (gateClosed(gate)) {
          const mineLeft = await memberInvites(db, claims.sub, gate.invites_per_person);
          const [rc] = await db.execute<{ code: string }>(
            sql`select code from public.referral_codes where user_id = ${claims.sub}::uuid`,
          );
          out.cloud_invite_only = {
            new_accounts:
              "by invitation: join the waitlist at casama.ai/waitlist, or claim an invite code there or with I Have an Invite on the app's sign-in screen",
            my_invite_code: rc?.code ?? null,
            my_invite_link: rc?.code ? `${opts.waitlist.inviteBase}/${rc.code}` : null,
            invites_total: mineLeft.total,
            invites_used: mineLeft.used,
            invites_left: mineLeft.unlocked ? mineLeft.left : 0,
            invites_unlocked: mineLeft.unlocked,
            ...(mineLeft.unlocked
              ? {}
              : {
                  how_to_unlock:
                    "Invites unlock after this person's first finished chat with a bot",
                }),
          };
        }
      } catch {
        // The rest of the answer still helps.
      }
    }
    if (orgId) {
      const admin = await asPerson(claims, async (tx) => {
        const [r] = await tx.execute<{ ok: boolean }>(
          sql`select public.has_role(${orgId}::uuid, 'admin') as ok`,
        );
        return r?.ok === true;
      });
      if (admin) {
        const sent = await db.execute<{ email: string; role: string; expires_at: Date | null }>(sql`
          select email, role::text as role, expires_at from public.invites
          where org_id = ${orgId}::uuid and accepted_at is null order by created_at desc limit 15`);
        const waiting = await db.execute<{ name: string | null; created_at: Date }>(sql`
          select coalesce(p.display_name, 'someone') as name, j.created_at
          from public.join_requests j left join public.profiles p on p.user_id = j.user_id
          where j.org_id = ${orgId}::uuid and j.status = 'pending' order by j.created_at desc limit 15`);
        out.open_workspace = {
          invites_not_accepted: sent.map((i) => ({
            email: i.email,
            role: i.role,
            state: i.expires_at && new Date(i.expires_at).getTime() < now ? "expired" : "waiting",
          })),
          join_requests_waiting: waiting.map((w) => ({ name: w.name, asked: iso(w.created_at) })),
        };
      }
    }
    return out;
  };

  return { usage, creditHistory, connections, bot, invites };
}
