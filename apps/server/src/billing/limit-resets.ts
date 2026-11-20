import { randomUUID } from "node:crypto";
import { type NotificationService, track } from "@casama/agent";
import { LimitResetCampaignInput, type LimitResetSettings } from "@casama/contracts";
import type { Database, Tx } from "@casama/db";
import { cloudMarkup, pushGroup, pushGroupOn } from "@casama/domain";
import type { z } from "@hono/zod-openapi";
import { sql } from "drizzle-orm";
import { BillingError } from "./types.ts";

type Input = z.infer<typeof LimitResetCampaignInput>;
type Settings = z.infer<typeof LimitResetSettings>;
type Campaign = Input & {
  id: string;
  state: string;
  created_by: string;
  created_at: Date;
  refilled_usd: string;
};
const fail = (message: string) => {
  throw new BillingError("reset_unavailable", message, 409);
};
const iso = (v: Date | string) => new Date(v).toISOString();
async function event(
  tx: Tx,
  actor: string | null,
  action: string,
  campaign: string | null,
  org: string | null = null,
  reset: string | null = null,
  before: unknown = null,
  after: unknown = null,
) {
  await tx.execute(
    sql`insert into public.limit_reset_events(actor_id,action,campaign_id,org_id,reset_id,"before","after") values (${actor}::uuid,${action},${campaign}::uuid,${org}::uuid,${reset}::uuid,${JSON.stringify(before)}::jsonb,${JSON.stringify(after)}::jsonb)`,
  );
}

export class LimitResets {
  readonly db: Database;
  readonly billingEnabled: boolean;
  constructor(db: Database, billingEnabled: boolean) {
    this.db = db;
    this.billingEnabled = billingEnabled;
  }
  async settings(tx: Database | Tx = this.db): Promise<Settings> {
    const [s] = await tx.execute<Settings>(
      sql`select limit_resets_enabled as enabled,limit_resets_per_period as per_period,limit_resets_max_held as max_held,limit_resets_notify_owners as notify_owners from public.billing_settings where id`,
    );
    return s ?? { enabled: false, per_period: 1, max_held: 3, notify_owners: true };
  }
  async setSettings(actor: string, input: Settings) {
    return this.db.transaction(async (tx) => {
      await tx.execute(sql`select id from public.billing_settings where id for update`);
      const before = await this.settings(tx);
      await tx.execute(
        sql`update public.billing_settings set limit_resets_enabled=${input.enabled},limit_resets_per_period=${input.per_period},limit_resets_max_held=${input.max_held},limit_resets_notify_owners=${input.notify_owners} where id`,
      );
      await event(tx, actor, "settings", null, null, null, before, input);
      return input;
    });
  }
  async campaigns() {
    const rows = await this.db.execute<
      Campaign & { given: string; used: string; expired: string }
    >(sql`select c.*,
      (select count(*) from public.limit_resets r where r.campaign_id=c.id)::text as given,
      (select count(*) from public.limit_resets r where r.campaign_id=c.id and used_at is not null)::text as used,
      (select count(*) from public.limit_resets r where r.campaign_id=c.id and used_at is null and c.expires_at<=now())::text as expired
      from public.limit_reset_campaigns c order by c.created_at desc`);
    return rows.map((c) => ({
      ...c,
      starts_at: iso(c.starts_at),
      expires_at: iso(c.expires_at),
      created_at: iso(c.created_at),
      given: Number(c.given),
      used: Number(c.used),
      expired: Number(c.expired),
      refilled_usd: Number(c.refilled_usd),
      max_per_use_usd: c.max_per_use_usd == null ? null : Number(c.max_per_use_usd),
      budget_usd: c.budget_usd == null ? null : Number(c.budget_usd),
    }));
  }
  async audience(input: Input, tx: Database | Tx = this.db) {
    // Filters intersect; an explicit workspace list is still constrained by the other filters.
    return tx.execute<{ id: string; plan: string; amount: string }>(sql`select o.id,o.plan,
      (coalesce((p.limits->>'monthly_credits_usd')::numeric,0) / case when p.interval='week' then 4 else 1 end)::text as amount
      from public.organizations o join public.plans p on p.code=o.plan
      where (${JSON.stringify(input.audience.plan_codes)}::jsonb='[]'::jsonb or ${JSON.stringify(input.audience.plan_codes)}::jsonb ? o.plan)
      and (${input.audience.created_before}::timestamptz is null or o.created_at<${input.audience.created_before}::timestamptz)
      and (${JSON.stringify(input.audience.workspace_ids)}::jsonb='[]'::jsonb or ${JSON.stringify(input.audience.workspace_ids)}::jsonb ? o.id::text)
      and (${input.audience.limited_within_days}::integer is null or exists(select 1 from public.runs r where r.org_id=o.id and r.created_at>=now()-make_interval(days=>${input.audience.limited_within_days ?? 0}) and (r.error::text like '%limit%' or r.error::text like '%out_of_credits%' or r.error::text like '%cloud_daily_cap%')))`);
  }
  async preview(input: Input) {
    const rows = await this.audience(input);
    const by_plan: Record<string, number> = {};
    let credits_usd = 0;
    for (const r of rows) {
      by_plan[r.plan] = (by_plan[r.plan] ?? 0) + 1;
      credits_usd += Math.min(
        (Number(r.amount) * input.refill_percent) / 100,
        input.max_per_use_usd ?? Infinity,
      );
    }
    const [settings] = await this.db.execute<{ markup: string }>(
      sql`select markup::text as markup from public.billing_settings where id`,
    );
    const markup = Number(settings?.markup ?? cloudMarkup());
    return {
      workspaces: rows.length,
      by_plan,
      credits_usd,
      cost_usd: credits_usd / Math.max(1, markup),
    };
  }
  async create(actor: string, input: Input, workspace?: string) {
    const body = LimitResetCampaignInput.parse(
      workspace
        ? {
            ...input,
            audience: {
              plan_codes: [],
              workspace_ids: [workspace],
              created_before: null,
              limited_within_days: null,
            },
          }
        : input,
    );
    const id = await this.db.transaction(async (tx) => {
      const [c] = await tx.execute<{
        id: string;
      }>(sql`insert into public.limit_reset_campaigns(name,message,audience,starts_at,expires_at,refill_percent,reset_daily,reset_computer,max_per_use_usd,budget_usd,notify_arrival,notify_reminder,created_by)
      values (${body.name},${body.message},${JSON.stringify(body.audience)}::jsonb,${body.starts_at}::timestamptz,${body.expires_at}::timestamptz,${body.refill_percent},${body.reset_daily},${body.reset_computer},${body.max_per_use_usd},${body.budget_usd},${body.notify_arrival},${body.notify_reminder},${actor}::uuid) returning id`);
      await event(tx, actor, "created", c!.id, workspace ?? null, null, null, body);
      return c!.id;
    });
    return (await this.campaigns()).find((c) => c.id === id)!;
  }
  async update(actor: string, id: string, input: Input) {
    await this.db.transaction(async (tx) => {
      const [c] = await tx.execute<Campaign>(
        sql`select * from public.limit_reset_campaigns where id=${id}::uuid for update`,
      );
      if (!c) return fail("Campaign not found");
      if (!["draft", "scheduled", "live", "paused"].includes(c.state))
        fail("Campaign cannot be edited");
      if (["live", "paused"].includes(c.state)) {
        const fixed = (v: Input) =>
          JSON.stringify([
            [
              v.audience.plan_codes,
              v.audience.workspace_ids,
              v.audience.created_before == null ? null : iso(v.audience.created_before),
              v.audience.limited_within_days,
            ],
            v.name,
            v.notify_arrival,
            iso(v.starts_at),
            v.refill_percent,
            v.reset_daily,
            v.reset_computer,
            v.max_per_use_usd == null ? null : Number(v.max_per_use_usd),
          ]);
        if (fixed(c) !== fixed(input)) fail("The audience and refill are fixed after launch");
        if (Date.parse(input.expires_at) <= Date.now()) fail("Expiry must be in the future");
      }
      await tx.execute(
        sql`update public.limit_reset_campaigns set budget_notice_sent=case when budget_usd is distinct from ${input.budget_usd} then false else budget_notice_sent end,name=${input.name},message=${input.message},audience=${JSON.stringify(input.audience)}::jsonb,starts_at=${input.starts_at}::timestamptz,expires_at=${input.expires_at}::timestamptz,refill_percent=${input.refill_percent},reset_daily=${input.reset_daily},reset_computer=${input.reset_computer},max_per_use_usd=${input.max_per_use_usd},budget_usd=${input.budget_usd},notify_arrival=${input.notify_arrival},notify_reminder=${input.notify_reminder} where id=${id}::uuid`,
      );
      await event(tx, actor, "edited", id, null, null, c, input);
    });
    return (await this.campaigns()).find((c) => c.id === id)!;
  }
  async action(actor: string, id: string, action: string) {
    await this.db.transaction(async (tx) => {
      const [c] = await tx.execute<Campaign>(
        sql`select * from public.limit_reset_campaigns where id=${id}::uuid for update`,
      );
      if (!c) return fail("Campaign not found");
      const allowed: Record<string, string[]> = {
        schedule: ["draft"],
        pause: ["live"],
        resume: ["paused"],
        cancel: ["draft", "scheduled", "live", "paused"],
        delete: ["draft"],
      };
      if (!allowed[action]?.includes(c.state)) fail("Action is not allowed in this state");
      const state = (
        { schedule: "scheduled", pause: "paused", resume: "live", cancel: "cancelled" } as Record<
          string,
          string
        >
      )[action];
      if (action === "delete")
        await tx.execute(sql`delete from public.limit_reset_campaigns where id=${id}::uuid`);
      else
        await tx.execute(
          sql`update public.limit_reset_campaigns set state=${state} where id=${id}::uuid`,
        );
      await event(
        tx,
        actor,
        action,
        id,
        null,
        null,
        { state: c.state },
        { state: state ?? "deleted" },
      );
    });
  }
  async events(campaign?: string, org?: string, limit = 100) {
    const rows = await this.db.execute<{
      id: string;
      campaign_id: string | null;
      reset_id: string | null;
      org_id: string | null;
      actor_id: string | null;
      action: string;
      before: Record<string, unknown> | null;
      after: Record<string, unknown> | null;
      created_at: Date;
    }>(
      sql`select * from public.limit_reset_events where (${campaign ?? null}::uuid is null or campaign_id=${campaign ?? null}::uuid) and (${org ?? null}::uuid is null or org_id=${org ?? null}::uuid) order by created_at desc,id desc limit ${limit}`,
    );
    return rows.map((r) => ({ ...r, created_at: iso(r.created_at) }));
  }
  async tick() {
    if (!this.billingEnabled) return;
    await this.db.transaction(async (tx) => {
      // One issuer at a time prevents simultaneous campaigns exceeding the held limit.
      await tx.execute(sql`select pg_advisory_xact_lock(74392104)`);
      // Campaign lock serializes launch against edits; no org locks are acquired here.
      const campaigns = await tx.execute<Campaign>(
        sql`select * from public.limit_reset_campaigns where state in ('scheduled','live','paused') order by id for update skip locked`,
      );
      const settings = await this.settings(tx);
      for (const c of campaigns) {
        if (new Date(c.expires_at).getTime() <= Date.now()) {
          await tx.execute(
            sql`update public.limit_reset_campaigns set state='ended' where id=${c.id}::uuid`,
          );
          await event(tx, null, "ended", c.id);
          const expired = await tx.execute<{ id: string; org_id: string }>(
            sql`select id,org_id from public.limit_resets where campaign_id=${c.id}::uuid and used_at is null and revoked_at is null`,
          );
          for (const r of expired) await event(tx, null, "expired", c.id, r.org_id, r.id);
          continue;
        }
        if (c.state !== "scheduled" || new Date(c.starts_at).getTime() > Date.now()) continue;
        // Switched off: nothing reaches anyone. A due hand-out launches once it's switched back on.
        if (!settings.enabled) continue;
        const audience = await this.audience(c, tx);
        await tx.execute(sql`with issued as (
          insert into public.limit_resets(org_id,campaign_id)
          select x.id::uuid,${c.id}::uuid from jsonb_array_elements_text(${JSON.stringify(audience.map((o) => o.id))}::jsonb) as x(id)
          where (select count(*) from public.limit_resets r join public.limit_reset_campaigns c on c.id=r.campaign_id where r.org_id=x.id::uuid and r.used_at is null and r.revoked_at is null and c.expires_at>now() and c.state in ('live','paused'))<${settings.max_held}
          on conflict do nothing returning id,org_id
        ) insert into public.limit_reset_events(action,campaign_id,org_id,reset_id)
          select 'given',${c.id}::uuid,org_id,id from issued`);
        await tx.execute(
          sql`update public.limit_reset_campaigns set state='live' where id=${c.id}::uuid`,
        );
        await event(tx, null, "started", c.id);
      }
    });
  }
  private async context(tx: Database | Tx, org: string) {
    const [r] = await tx.execute<{
      amount: string;
      key: string;
      end: Date;
      remaining: string;
      daily: string;
      seconds: string;
      daily_offset: string;
      computer_offset: string;
    }>(sql`
      with e as (select e.*,p.interval from public.entitlements e join public.plans p on p.code=e.plan_code where e.org_id=${org}::uuid order by e.created_at desc limit 1),
      period as (select *,public.grant_month(subscription_id) as key from e)
      select least(coalesce((limits->>'monthly_credits_usd')::numeric,0)/case when interval='week' then 4 else 1 end,
        -- What this period really granted: a trial's smaller grant, a pro-rata top-up, or $0 for a
        -- person's second free workspace (D-246). A reset never refills past it.
        (select coalesce(sum(delta),0) from public.credit_ledger where org_id=${org}::uuid and reason='grant' and delta>0 and reference like 'monthly:'||period.key||':%'))::text as amount,key,
      case when interval='week' and length(key)=10 then coalesce(valid_until,key::date+interval '7 days') when interval='month' and valid_until is not null then valid_until when interval='year' and valid_until is not null then (select min(valid_until-interval '1 year'+make_interval(months=>n)) from generate_series(1,12) n where valid_until-interval '1 year'+make_interval(months=>n)>now()) else least(coalesce(valid_until,(key||'-01')::date+interval '1 month'),(key||'-01')::date+interval '1 month') end as end,
      (select coalesce(sum(remaining),0)::text from public.credit_lots where org_id=${org}::uuid and (expires_at is null or expires_at>now()) and ((reason='grant' and reference like 'monthly:'||period.key||':%') or (reason='reset' and reference in (select id::text from public.limit_resets where org_id=${org}::uuid and period_key=period.key)))) as remaining,
      (select coalesce(sum(cost_usd),0)::text from public.usage_ledger where org_id=${org}::uuid and billable and kind not in ('computer_seconds','stream_seconds') and created_at>=date_trunc('day',now() at time zone 'utc') at time zone 'utc') as daily,
      (select coalesce(sum(quantity),0)::text from public.usage_ledger where org_id=${org}::uuid and kind='computer_seconds' and created_at>=date_trunc('month',now() at time zone 'utc') at time zone 'utc') as seconds,
      public.limit_reset_offset(${org}::uuid,'daily')::text as daily_offset,public.limit_reset_offset(${org}::uuid,'computer')::text as computer_offset from period`);
    if (!r) return fail("Workspace has no billing period");
    return r;
  }
  async saved(org: string, owner: boolean) {
    if (!this.billingEnabled) return [];
    const settings = await this.settings();
    if (!settings.enabled) return [];
    const rows = await this.db.execute<{
      id: string;
      campaign_id: string;
      message: string;
      expires_at: Date;
      refill_percent: number;
      reset_daily: boolean;
      reset_computer: boolean;
      max_per_use_usd: string | null;
      state: string;
      budget_usd: string | null;
      refilled_usd: string;
    }>(
      sql`select r.id,r.campaign_id,c.message,c.expires_at,c.refill_percent,c.reset_daily,c.reset_computer,c.max_per_use_usd,c.state,c.budget_usd,c.refilled_usd from public.limit_resets r join public.limit_reset_campaigns c on c.id=r.campaign_id where r.org_id=${org}::uuid and r.used_at is null and r.revoked_at is null and c.expires_at>now() and c.state in ('live','paused') order by c.expires_at,r.id`,
    );
    // Most workspaces hold none: skip the period query, which reads the whole day's usage.
    if (!rows.length) return [];
    // A workspace without a billing period (no entitlement yet) shows its resets as unusable
    // instead of failing the billing summary they're part of.
    const period = await this.context(this.db, org).catch(() => null);
    const [uses] = period
      ? await this.db.execute<{ n: string }>(
          sql`select count(*)::text as n from public.limit_resets where org_id=${org}::uuid and period_key=${period.key} and used_at is not null`,
        )
      : [];
    return rows.map((r) => {
      if (!period)
        return {
          id: r.id,
          campaign_id: r.campaign_id,
          message: r.message,
          expires_at: iso(r.expires_at),
          refill_usd: 0,
          reset_daily: r.reset_daily,
          reset_computer: r.reset_computer,
          can_use: false,
          unavailable_reason: "no_billing_period",
        };
      const refill = Math.max(
        0,
        Math.min(
          (Number(period.amount) * r.refill_percent) / 100 - Number(period.remaining),
          Number(r.max_per_use_usd ?? Infinity),
        ),
      );
      const reason = !owner
        ? "owner_required"
        : r.state !== "live"
          ? "paused"
          : Number(uses?.n) >= settings.per_period
            ? "period_limit"
            : r.budget_usd !== null && Number(r.refilled_usd) + refill > Number(r.budget_usd)
              ? "budget"
              : refill <= 0 &&
                  !(r.reset_daily && Number(period.daily) > Number(period.daily_offset)) &&
                  !(r.reset_computer && Number(period.seconds) > Number(period.computer_offset))
                ? "nothing_to_refill"
                : null;
      return {
        id: r.id,
        campaign_id: r.campaign_id,
        message: r.message,
        expires_at: iso(r.expires_at),
        refill_usd: refill,
        reset_daily: r.reset_daily,
        reset_computer: r.reset_computer,
        can_use: reason === null,
        unavailable_reason: reason,
      };
    });
  }
  async redeem(org: string, actor: string) {
    if (!this.billingEnabled) fail("Billing is disabled");
    return this.db.transaction(async (tx) => {
      await tx.execute(sql`select id from public.organizations where id=${org}::uuid for update`);
      const [membership] = await tx.execute<{ ok: boolean }>(
        sql`select exists(select 1 from public.memberships where org_id=${org}::uuid and user_id=${actor}::uuid and role='owner') as ok`,
      );
      if (!membership?.ok)
        throw new BillingError("forbidden", "Only workspace owners can use resets", 403);
      await tx.execute(sql`select id from public.billing_settings where id for share`);
      const settings = await this.settings(tx);
      if (!settings.enabled) fail("Saved resets are disabled");
      const [r] = await tx.execute<{
        id: string;
        campaign_id: string;
        refill_percent: number;
        max_per_use_usd: string | null;
        budget_usd: string | null;
        refilled_usd: string;
        reset_daily: boolean;
        reset_computer: boolean;
      }>(
        sql`select r.id,r.campaign_id,c.refill_percent,c.max_per_use_usd,c.budget_usd,c.refilled_usd,c.reset_daily,c.reset_computer from public.limit_resets r join public.limit_reset_campaigns c on c.id=r.campaign_id where r.org_id=${org}::uuid and r.used_at is null and r.revoked_at is null and c.expires_at>now() and c.state='live' order by c.expires_at,r.id limit 1 for update of r,c`,
      );
      if (!r) return fail("No reset is available");
      // Settle this workspace's recorded usage before computing the top-up. The global
      // settlement job locks usage rows first, so never wait on its rows while holding org.
      const [pendingCount] = await tx.execute<{ n: string }>(
        sql`select count(*)::text as n from public.usage_ledger where org_id=${org}::uuid and billable and billed_at is null`,
      );
      const pending = await tx.execute<{ id: string; cost: string }>(
        sql`select id,cost_usd::text as cost from public.usage_ledger where org_id=${org}::uuid and billable and billed_at is null for update skip locked`,
      );
      if (pending.length !== Number(pendingCount?.n)) fail("Usage is settling; try again shortly");
      let charge = 0;
      for (const usage of pending) {
        charge += Number(usage.cost);
        await tx.execute(
          sql`update public.usage_ledger set billed_at=now() where id=${usage.id}::uuid`,
        );
      }
      if (charge !== 0)
        await tx.execute(
          sql`select public.credit_apply(${org}::uuid,${-charge},'usage',${`reset-settlement:${randomUUID()}`},'Usage settled before saved reset')`,
        );
      const period = await this.context(tx, org);
      const [uses] = await tx.execute<{ n: string }>(
        sql`select count(*)::text as n from public.limit_resets where org_id=${org}::uuid and period_key=${period.key} and used_at is not null`,
      );
      if (Number(uses?.n) >= settings.per_period)
        fail("The reset allowance for this period is used");
      const amount =
        Math.round(
          Math.max(
            0,
            Math.min(
              (Number(period.amount) * r.refill_percent) / 100 - Number(period.remaining),
              Number(r.max_per_use_usd ?? Infinity),
            ),
          ) * 1e6,
        ) / 1e6;
      if (
        amount <= 0 &&
        !(r.reset_daily && Number(period.daily) > Number(period.daily_offset)) &&
        !(r.reset_computer && Number(period.seconds) > Number(period.computer_offset))
      )
        fail("There is nothing to refill");
      if (new Date(period.end).getTime() <= Date.now())
        fail("Refresh billing before using this reset");
      if (r.budget_usd !== null && Number(r.refilled_usd) + amount > Number(r.budget_usd))
        fail("This reset is not available right now");
      if (amount > 0)
        await tx.execute(
          sql`select public.credit_apply(${org}::uuid,${amount},'reset',${r.id},'Saved reset')`,
        );
      await tx.execute(
        sql`update public.credit_lots set expires_at=${iso(period.end)}::timestamptz where org_id=${org}::uuid and reason='reset' and reference=${r.id}`,
      );
      // On a negative balance only the part above zero becomes credit; the rest pays the debt.
      // The workspace, the campaign total and its budget count what became spendable.
      const [lot] = await tx.execute<{ n: string }>(
        sql`select coalesce(sum(amount),0)::text as n from public.credit_lots where org_id=${org}::uuid and reason='reset' and reference=${r.id}`,
      );
      const refilled = Number(lot?.n ?? 0);
      await tx.execute(
        sql`update public.limit_resets set used_at=now(),used_by=${actor}::uuid,period_key=${period.key},period_end=${iso(period.end)}::timestamptz,refilled_usd=${refilled},
      daily_offset_usd=case when ${r.reset_daily} then (select coalesce(sum(cost_usd),0) from public.usage_ledger where org_id=${org}::uuid and billable and kind not in ('computer_seconds','stream_seconds') and created_at>=date_trunc('day',now() at time zone 'utc') at time zone 'utc') else 0 end,
      computer_offset_seconds=case when ${r.reset_computer} then (select coalesce(sum(quantity),0) from public.usage_ledger where org_id=${org}::uuid and kind='computer_seconds' and created_at>=date_trunc('month',now() at time zone 'utc') at time zone 'utc') else 0 end where id=${r.id}::uuid`,
      );
      await tx.execute(
        sql`update public.limit_reset_campaigns set refilled_usd=refilled_usd+${refilled} where id=${r.campaign_id}::uuid`,
      );
      await event(tx, actor, "used", r.campaign_id, org, r.id, null, {
        refilled_usd: refilled,
        ...(refilled !== amount ? { offered_usd: amount } : {}),
        period_key: period.key,
      });
      return { reset_id: r.id, refilled_usd: refilled };
    });
  }
  async resetAction(actor: string, id: string, action: "revoke" | "undo") {
    const [found] = await this.db.execute<{ org_id: string }>(
      sql`select org_id from public.limit_resets where id=${id}::uuid`,
    );
    if (!found) return fail("Reset not found");
    await this.db.transaction(async (tx) => {
      await tx.execute(
        sql`select id from public.organizations where id=${found.org_id}::uuid for update`,
      );
      const [r] = await tx.execute<{
        id: string;
        org_id: string;
        campaign_id: string;
        used_at: Date | null;
        revoked_at: Date | null;
        undone_at: Date | null;
      }>(sql`select * from public.limit_resets where id=${id}::uuid for update`);
      if (!r) return fail("Reset not found");
      if (action === "revoke") {
        if (r.used_at || r.revoked_at) fail("Only an unused reset can be taken back");
        await tx.execute(sql`update public.limit_resets set revoked_at=now() where id=${id}::uuid`);
        await event(tx, actor, "revoked", r.campaign_id, r.org_id, id, r, { revoked: true });
      } else {
        if (!r.used_at || r.undone_at) fail("Only a used reset can be undone once");
        const lots = await tx.execute<{ id: string; remaining: string; expires_at: Date | null }>(
          sql`select id,remaining::text,expires_at from public.credit_lots where org_id=${r.org_id}::uuid and reason='reset' and reference=${id} for update`,
        );
        const amount = lots.reduce((sum, l) => sum + Number(l.remaining), 0);
        // Zero this lot directly. credit_apply's generic debit would spend unrelated lots.
        await tx.execute(
          sql`update public.credit_lots set remaining=0 where org_id=${r.org_id}::uuid and reason='reset' and reference=${id}`,
        );
        if (amount > 0)
          await tx.execute(sql`insert into public.credit_ledger(org_id,delta,reason,reference,note,balance_after)
          select ${r.org_id}::uuid,${-amount},'adjustment',${`undo-reset:${id}`},'Unused saved reset credits taken back',coalesce((select balance_after from public.credit_ledger where org_id=${r.org_id}::uuid order by seq desc limit 1),0)-${amount}`);
        await tx.execute(
          sql`update public.limit_resets set undone_at=now(),daily_offset_usd=0,computer_offset_seconds=0 where id=${id}::uuid`,
        );
        await event(tx, actor, "undone", r.campaign_id, r.org_id, id, r, {
          taken_back_usd: amount,
        });
      }
    });
  }
  async notices(notes: NotificationService, adminEmails?: string) {
    if (!this.billingEnabled || !(await this.settings()).enabled) return;
    await this.db.transaction(async (tx) => {
      await tx.execute(sql`select pg_advisory_xact_lock(74392105)`);
      const rows = await tx.execute<{
        id: string;
        org_id: string;
        campaign_id: string;
        message: string;
        expires_at: Date;
        arrival_sent_at: Date | null;
        reminder_sent_at: Date | null;
        notify_arrival: boolean;
        notify_reminder: boolean;
      }>(
        sql`select r.*,c.message,c.expires_at,c.notify_arrival,c.notify_reminder from public.limit_resets r join public.limit_reset_campaigns c on c.id=r.campaign_id where c.state='live' and c.expires_at>now() and r.used_at is null and r.revoked_at is null and ((c.notify_arrival and r.arrival_sent_at is null) or (c.notify_reminder and r.reminder_sent_at is null and c.expires_at<=now()+interval '24 hours')) order by r.id limit 200 for update of r skip locked`,
      );
      if ((await this.settings(tx)).notify_owners) {
        const campaigns = await tx.execute<{
          id: string;
          state: string;
          end_notice_sent: boolean;
          budget_notice_sent: boolean;
          budget_usd: string | null;
          refilled_usd: string;
        }>(
          sql`select * from public.limit_reset_campaigns where (state='ended' and not end_notice_sent) or (state in ('live','paused') and budget_usd is not null and refilled_usd>=budget_usd and not budget_notice_sent) for update skip locked`,
        );
        const emails = (adminEmails ?? "")
          .split(",")
          .map((e) => e.trim().toLowerCase())
          .filter(Boolean);
        const owners = await tx.execute<{ user_id: string }>(
          sql`select * from public.limit_reset_instance_owners(array(select jsonb_array_elements_text(${JSON.stringify(emails)}::jsonb)))`,
        );
        for (const c of campaigns) {
          for (const owner of owners) {
            const after = await notes.quietUntil(owner.user_id, null);
            const payload = {
              title: c.state === "ended" ? "Reset campaign ended" : "Reset campaign budget reached",
              body: "Review saved resets in Admin.",
              link: "/admin?tab=resets",
              campaign_id: c.id,
            };
            const prefs = await notes.prefs(owner.user_id);
            await tx.execute(
              sql`insert into public.notifications(user_id,kind,payload,push_status,push_after) values (${owner.user_id}::uuid,'reset_admin',${JSON.stringify(payload)}::jsonb,${pushGroupOn(prefs, pushGroup("reset_admin")) ? "deferred" : "off"},${(after ?? new Date()).toISOString()}::timestamptz)`,
            );
          }
          await tx.execute(
            sql`update public.limit_reset_campaigns set end_notice_sent=case when state='ended' then true else end_notice_sent end,budget_notice_sent=case when state<>'ended' then true else budget_notice_sent end where id=${c.id}::uuid`,
          );
        }
      }
      for (const r of rows) {
        const arrival = r.notify_arrival && !r.arrival_sent_at;
        const reminder =
          r.notify_reminder &&
          !r.reminder_sent_at &&
          new Date(r.expires_at).getTime() <= Date.now() + 86400000;
        const owners = await tx.execute<{ user_id: string }>(
          sql`select user_id from public.memberships where org_id=${r.org_id}::uuid and role='owner'`,
        );
        for (const owner of owners) {
          const kind = arrival ? "reset_given" : "reset_expiring";
          const payload = {
            title: arrival ? "A reset is saved" : "Your saved reset expires soon",
            body: r.message,
            link: "/settings/billing",
            reset_id: r.id,
          };
          const after = await notes.quietUntil(owner.user_id, null);
          const prefs = await notes.prefs(owner.user_id);
          await tx.execute(
            sql`insert into public.notifications(user_id,org_id,kind,payload,push_status,push_after) values (${owner.user_id}::uuid,${r.org_id}::uuid,${kind},${JSON.stringify(payload)}::jsonb,${pushGroupOn(prefs, pushGroup(kind)) ? "deferred" : "off"},${(after ?? new Date()).toISOString()}::timestamptz)`,
          );
        }
        await tx.execute(
          sql`update public.limit_resets set arrival_sent_at=case when ${arrival} then now() else arrival_sent_at end,reminder_sent_at=case when ${reminder} then now() else reminder_sent_at end where id=${r.id}::uuid`,
        );
      }
    });
  }
  async analytics() {
    const rows = await this.db.execute<{
      id: string;
      action: string;
      org_id: string;
      campaign_id: string;
      actor_id: string | null;
      plan: string;
    }>(
      sql`select e.*,o.plan from public.limit_reset_events e join public.organizations o on o.id=e.org_id where e.action in ('given','used','expired') and not exists(select 1 from public.limit_reset_deliveries d where d.event_id=e.id) order by e.created_at limit 200`,
    );
    for (const e of rows) {
      track(this.db, {
        event: (
          { given: "reset_given", used: "reset_used", expired: "reset_expired" } as Record<
            string,
            string
          >
        )[e.action]!,
        userId: e.actor_id,
        orgId: e.org_id,
        uuid: e.id,
        properties: { plan: e.plan, campaign_id: e.campaign_id },
      });
      await this.db.execute(
        sql`insert into public.limit_reset_deliveries(event_id) values (${e.id}::uuid) on conflict do nothing`,
      );
    }
  }
  async *csv(campaign?: string, org?: string): AsyncGenerator<string, void, unknown> {
    yield "id,created_at,action,campaign_id,reset_id,org_id,actor_id,before,after\r\n";
    let cursor: string | null = null;
    for (;;) {
      const rows: Array<{
        id: string;
        created_at: Date;
        action: string;
        campaign_id: string | null;
        reset_id: string | null;
        org_id: string | null;
        actor_id: string | null;
        before: unknown;
        after: unknown;
      }> = await this.db.execute<{
        id: string;
        created_at: Date;
        action: string;
        campaign_id: string | null;
        reset_id: string | null;
        org_id: string | null;
        actor_id: string | null;
        before: unknown;
        after: unknown;
      }>(
        sql`select * from public.limit_reset_events where (${campaign ?? null}::uuid is null or campaign_id=${campaign ?? null}::uuid) and (${org ?? null}::uuid is null or org_id=${org ?? null}::uuid) and (${cursor}::uuid is null or (created_at,id)<(select created_at,id from public.limit_reset_events where id=${cursor}::uuid)) order by created_at desc,id desc limit 1000`,
      );
      if (!rows.length) return;
      const cell = (v: unknown) => `"${String(v ?? "").replaceAll('"', '""')}"`;
      for (const e of rows)
        yield `${[
          e.id,
          iso(e.created_at),
          e.action,
          e.campaign_id,
          e.reset_id,
          e.org_id,
          e.actor_id,
          JSON.stringify(e.before),
          JSON.stringify(e.after),
        ]
          .map(cell)
          .join(",")}\r\n`;
      cursor = rows[rows.length - 1]!.id;
    }
  }
}
