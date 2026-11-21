/**
 * Free plans for friends (docs/COMP-PLANS-PLAN.md). A comp is a `subscriptions` row with
 * source `comp`, so `BillingService.recompute` gives the workspace the plan's limits, name and
 * monthly credits, and drops it back when the comp ends. Instance owners grant comps by email or
 * make gift codes; a workspace owner redeems a code (on the web only: App Store 3.1.1).
 */
import { createHash, randomInt } from "node:crypto";
import { track } from "@casama/agent";
import { type Database, pgErrorCode } from "@casama/db";
import { deterministicUuid } from "@casama/observability";
import { sql } from "drizzle-orm";
import { queueAccountEmail } from "../services/account-emails.ts";
import type { BillingService } from "./service.ts";
import { BillingError, ENTITLED } from "./types.ts";

const arr = (xs: readonly string[]) => `{${xs.join(",")}}`;
/** How long before the end the friend hears that the comp is ending. */
export const COMP_REMINDER_DAYS = 7;
/** A paid plan started this long after a comp ended still counts as a conversion. */
const CONVERSION_DAYS = 30;

export interface CompSettings {
  enabled: boolean;
  grant_plans: string[];
  code_plans: string[];
  max_months: number;
  max_active: number;
}

export interface CompView {
  id: string;
  org_id: string;
  org_name: string | null;
  user_id: string | null;
  email: string | null;
  plan_code: string;
  months: number;
  starts_at: string;
  ends_at: string;
  from: "grant" | "code";
  code_id: string | null;
  note: string | null;
  ended_at: string | null;
  end_reason: string | null;
  created_at: string;
}

export interface CompCodeView {
  id: string;
  hint: string;
  plan_code: string;
  months: number;
  max_redemptions: number;
  redeemed_count: number;
  redeem_by: string | null;
  note: string | null;
  disabled: boolean;
  created_at: string;
}

export interface GrantInput {
  email?: string;
  user_id?: string;
  org_id?: string;
  plan_code: string;
  months: number;
  note?: string | null;
}

export interface CodeInput {
  plan_code: string;
  months: number;
  max_redemptions?: number;
  redeem_by?: string | null;
  note?: string | null;
}

// ---------------------------------------------------------------------------
// Codes: G- and 10 Crockford base32 characters, so they can't be mistaken for an invite code (6)
// or a workspace code (8). Only a hash is stored.

const ALPHABET = "0123456789ABCDEFGHJKMNPQRSTVWXYZ";
export const COMP_CODE_LENGTH = 10;

export function newCompCode() {
  let s = "";
  for (let i = 0; i < COMP_CODE_LENGTH; i++) s += ALPHABET[randomInt(ALPHABET.length)];
  return s;
}

/** How a code is shown and shared: G-XXXXX-XXXXX. */
export function formatCompCode(code: string) {
  return `G-${code.slice(0, 5)}-${code.slice(5)}`;
}

/** Reads a code however it's typed or pasted (with or without G-, dashes, or a casama.ai/g/ link). */
export function normalizeCompCode(input: string): string | null {
  const last =
    input
      .trim()
      .replace(/[?#].*$/, "")
      .replace(/\/+$/, "")
      .split("/")
      .pop() ?? "";
  let s = last
    .toUpperCase()
    .replace(/[^0-9A-Z]/g, "")
    .replace(/O/g, "0")
    .replace(/[IL]/g, "1")
    .replace(/U/g, "V");
  if (s.length === COMP_CODE_LENGTH + 1 && s.startsWith("G")) s = s.slice(1);
  if (s.length !== COMP_CODE_LENGTH) return null;
  for (const ch of s) if (!ALPHABET.includes(ch)) return null;
  return s;
}

export const hashCompCode = (code: string) => createHash("sha256").update(code).digest("hex");

/** fr••••@example.com: enough for the owner to recognise, not a full address in lists and logs. */
export function maskEmail(email: string | null | undefined) {
  if (!email) return null;
  const [local, domain] = email.split("@");
  if (!local || !domain) return null;
  return `${local.slice(0, 2)}${"•".repeat(Math.max(1, Math.min(4, local.length - 2)))}@${domain}`;
}

const iso = (d: Date | string | null | undefined) => (d ? new Date(d).toISOString() : null);
const addMonths = (d: Date, months: number) => {
  const r = new Date(d);
  r.setUTCMonth(r.getUTCMonth() + months);
  return r;
};

type CompRow = {
  id: string;
  org_id: string;
  org_name: string | null;
  user_id: string | null;
  email: string | null;
  plan_code: string;
  months: number;
  starts_at: Date;
  ends_at: Date;
  code_id: string | null;
  note: string | null;
  ended_at: Date | null;
  end_reason: string | null;
  created_at: Date;
};

const view = (r: CompRow): CompView => ({
  id: r.id,
  org_id: r.org_id,
  org_name: r.org_name,
  user_id: r.user_id,
  email: maskEmail(r.email),
  plan_code: r.plan_code,
  months: Number(r.months),
  starts_at: iso(r.starts_at) as string,
  ends_at: iso(r.ends_at) as string,
  from: r.code_id ? "code" : "grant",
  code_id: r.code_id,
  note: r.note,
  ended_at: iso(r.ended_at),
  end_reason: r.end_reason,
  created_at: iso(r.created_at) as string,
});

type CodeRow = {
  id: string;
  code_hint: string;
  plan_code: string;
  months: number;
  max_redemptions: number;
  redeemed_count: number;
  redeem_by: Date | null;
  note: string | null;
  disabled_at: Date | null;
  created_at: Date;
};

const codeView = (r: CodeRow): CompCodeView => ({
  id: r.id,
  hint: r.code_hint,
  plan_code: r.plan_code,
  months: Number(r.months),
  max_redemptions: Number(r.max_redemptions),
  redeemed_count: Number(r.redeemed_count),
  redeem_by: iso(r.redeem_by),
  note: r.note,
  disabled: r.disabled_at !== null,
  created_at: iso(r.created_at) as string,
});

export class Comps {
  private readonly db: Database;
  private readonly billing: BillingService;
  constructor(db: Database, billing: BillingService) {
    this.db = db;
    this.billing = billing;
  }

  // -------------------------------------------------------------------------
  // Settings

  async settings(): Promise<CompSettings> {
    await this.db.execute(
      sql`insert into public.billing_settings (id) values (true) on conflict (id) do nothing`,
    );
    const [r] = await this.db.execute<{
      comps_enabled: boolean;
      comp_grant_plans: string[];
      comp_code_plans: string[];
      comp_max_months: number;
      comp_max_active: number;
    }>(sql`
      select comps_enabled, comp_grant_plans, comp_code_plans, comp_max_months, comp_max_active
      from public.billing_settings where id`);
    return {
      enabled: r?.comps_enabled ?? false,
      grant_plans: r?.comp_grant_plans ?? ["plus", "pro", "max"],
      code_plans: r?.comp_code_plans ?? ["plus", "pro"],
      max_months: Number(r?.comp_max_months ?? 12),
      max_active: Number(r?.comp_max_active ?? 50),
    };
  }

  async setSettings(actorId: string, input: CompSettings): Promise<CompSettings> {
    const before = await this.settings();
    const monthly = await this.monthlyPlans();
    for (const code of [...input.grant_plans, ...input.code_plans])
      if (!monthly.has(code))
        throw new BillingError(
          "plan_not_allowed",
          `${code} can't be given free: only monthly paid plans can`,
          400,
        );
    await this.db.execute(sql`
      update public.billing_settings set comps_enabled = ${input.enabled},
        comp_grant_plans = ${arr(input.grant_plans)}::text[], comp_code_plans = ${arr(input.code_plans)}::text[],
        comp_max_months = ${input.max_months}, comp_max_active = ${input.max_active},
        updated_at = now(), updated_by = ${actorId}::uuid
      where id`);
    const after = await this.settings();
    await this.log({ actorId, action: "settings", detail: { before, after } });
    return after;
  }

  /** Paid monthly plans: the only ones a comp can carry (weekly and yearly grants assume a paid period). */
  private async monthlyPlans() {
    const rows = await this.db.execute<{ code: string }>(sql`
      select code from public.plans
      where interval = 'month' and code not in ('free', 'selfhost')
        and sort > coalesce((select sort from public.plans where code = 'free'), 0)`);
    return new Set(rows.map((r) => r.code));
  }

  private async requireOn() {
    if (!this.billing.enabled)
      throw new BillingError("billing_off", "Plans aren't sold on this server", 409);
    const s = await this.settings();
    if (!s.enabled)
      throw new BillingError("comps_off", "Free plans are switched off on this server", 409);
    return s;
  }

  private async checkPlan(planCode: string, allowed: string[], months: number, s: CompSettings) {
    if (!allowed.includes(planCode) || !(await this.monthlyPlans()).has(planCode))
      throw new BillingError("plan_not_allowed", "That plan can't be given free", 400);
    if (!Number.isInteger(months) || months < 1 || months > s.max_months)
      throw new BillingError(
        "months_not_allowed",
        `A free plan lasts 1 to ${s.max_months} months`,
        400,
      );
  }

  private async requireRoom(s: CompSettings) {
    const [r] = await this.db.execute<{ n: number }>(
      sql`select count(*)::int as n from public.comps where ended_at is null`,
    );
    if ((r?.n ?? 0) >= s.max_active)
      throw new BillingError(
        "comp_limit",
        `${s.max_active} free plans are already running, the most this server allows`,
        409,
      );
  }

  /** Refuses a comp a workspace couldn't use: one running already, or a paid plan at least as high. */
  private async requireUseful(orgId: string, planCode: string, redeeming = false) {
    const [r] = await this.db.execute<{ running: boolean; paying: boolean }>(sql`
      select
        exists (select 1 from public.comps where org_id = ${orgId}::uuid and ended_at is null) as running,
        exists (
          select 1 from public.subscriptions s join public.plans p on p.code = s.plan_code
          where s.org_id = ${orgId}::uuid and s.source <> 'comp'
            and s.status = any(${arr(ENTITLED)}::text[])
            and (s.current_period_end is null or s.current_period_end > now())
            and p.sort >= (select sort from public.plans where code = ${planCode})
        ) as paying`);
    if (r?.running)
      throw new BillingError(
        "comp_exists",
        redeeming
          ? "This workspace already has a free plan from Casama. Redeem the code once it ends, or in another workspace you own."
          : "This workspace already has a free plan. Extend that one instead.",
        409,
      );
    if (r?.paying)
      throw new BillingError(
        "already_paying",
        "This workspace already pays for this plan or a higher one",
        409,
      );
  }

  // -------------------------------------------------------------------------
  // Grants

  /** Finds the person and the workspace a grant goes to: the one named, else their oldest owned one. */
  private async target(input: Pick<GrantInput, "email" | "user_id" | "org_id">) {
    let userId = input.user_id ?? null;
    if (!userId && input.email) {
      const [u] = await this.db.execute<{ id: string | null }>(
        sql`select public.worker_user_by_email(${input.email}) as id`,
      );
      userId = u?.id ?? null;
    }
    if (!userId) throw new BillingError("user_not_found", "No account uses that email", 404);
    const [who] = await this.db.execute<{ email: string; banned: boolean }>(
      sql`select email, banned from public.worker_admin_user(${userId}::uuid)`,
    );
    if (!who) throw new BillingError("user_not_found", "No account uses that email", 404);
    if (who.banned) throw new BillingError("account_banned", "That account is banned", 409);
    const [org] = await this.db.execute<{ id: string }>(
      input.org_id
        ? sql`select org_id as id from public.memberships
              where org_id = ${input.org_id}::uuid and user_id = ${userId}::uuid`
        : sql`select m.org_id as id from public.memberships m join public.organizations o on o.id = m.org_id
              where m.user_id = ${userId}::uuid
              order by (m.role = 'owner') desc, o.created_at, o.id limit 1`,
    );
    if (!org)
      throw new BillingError(
        "no_workspace",
        input.org_id ? "That person isn't in that workspace" : "That person has no workspace yet",
        409,
      );
    return { userId, orgId: org.id, email: who.email };
  }

  async grant(actorId: string, input: GrantInput): Promise<CompView> {
    const s = await this.requireOn();
    await this.checkPlan(input.plan_code, s.grant_plans, input.months, s);
    const { userId, orgId } = await this.target(input);
    await this.requireUseful(orgId, input.plan_code);
    await this.requireRoom(s);
    const id = await this.create({
      orgId,
      userId,
      planCode: input.plan_code,
      months: input.months,
      note: input.note ?? null,
      grantedBy: actorId,
      codeId: null,
      redeemerKey: null,
    });
    await this.log({
      compId: id,
      orgId,
      actorId,
      action: "granted",
      detail: { plan_code: input.plan_code, months: input.months },
    });
    track(this.db, {
      event: "comp_granted",
      userId,
      orgId,
      properties: { plan: input.plan_code, months: input.months, from: "grant" },
    });
    return this.get(id);
  }

  /** Inserts the comp and its subscription row together, then gives the workspace the plan. */
  private async create(c: {
    orgId: string;
    userId: string;
    planCode: string;
    months: number;
    note: string | null;
    grantedBy: string | null;
    codeId: string | null;
    redeemerKey: string | null;
    tx?: Database;
  }) {
    const run = async (tx: Database) => {
      const now = new Date();
      const ends = addMonths(now, c.months);
      const [comp] = await tx.execute<{ id: string }>(sql`
        insert into public.comps (org_id, user_id, redeemer_key, plan_code, months, starts_at, ends_at,
          granted_by, code_id, note)
        values (${c.orgId}::uuid, ${c.userId}::uuid, ${c.redeemerKey}, ${c.planCode}, ${c.months},
          ${now.toISOString()}::timestamptz, ${ends.toISOString()}::timestamptz,
          ${c.grantedBy}::uuid, ${c.codeId}::uuid, ${c.note})
        returning id`);
      const compId = comp!.id;
      const [sub] = await tx.execute<{ id: string }>(sql`
        insert into public.subscriptions (org_id, source, external_id, plan_code, status, current_period_end,
          created_at, updated_at)
        values (${c.orgId}::uuid, 'comp', ${`comp:${compId}`}, ${c.planCode}, 'active',
          ${ends.toISOString()}::timestamptz, ${now.toISOString()}::timestamptz, now())
        returning id`);
      await tx.execute(
        sql`update public.comps set subscription_id = ${sub!.id}::uuid where id = ${compId}::uuid`,
      );
      return compId;
    };
    let id: string;
    try {
      id = c.tx
        ? await run(c.tx)
        : await this.db.transaction((tx) => run(tx as unknown as Database));
    } catch (err) {
      if (pgErrorCode(err) === "23505")
        throw new BillingError(
          "comp_exists",
          "This workspace already has a free plan, or this person already used a gift code",
          409,
        );
      throw err;
    }
    if (!c.tx) await this.billing.recompute(c.orgId);
    return id;
  }

  async extend(actorId: string, id: string, months: number): Promise<CompView> {
    const s = await this.requireOn();
    if (!Number.isInteger(months) || months < 1 || months > s.max_months)
      throw new BillingError("months_not_allowed", `Extend by 1 to ${s.max_months} months`, 400);
    const [c] = await this.db.execute<{
      org_id: string;
      ends_at: Date;
      subscription_id: string | null;
    }>(sql`
      select org_id, ends_at, subscription_id from public.comps where id = ${id}::uuid and ended_at is null`);
    if (!c) throw new BillingError("comp_not_found", "No running free plan with that id", 404);
    const ends = addMonths(new Date(c.ends_at), months);
    await this.db.transaction(async (tx) => {
      await tx.execute(sql`
        update public.comps set ends_at = ${ends.toISOString()}::timestamptz, months = months + ${months},
          reminder_sent_at = null
        where id = ${id}::uuid`);
      if (c.subscription_id)
        await tx.execute(sql`
          update public.subscriptions set current_period_end = ${ends.toISOString()}::timestamptz, updated_at = now()
          where id = ${c.subscription_id}::uuid`);
    });
    await this.log({
      compId: id,
      orgId: c.org_id,
      actorId,
      action: "extended",
      detail: { months, ends_at: ends.toISOString() },
    });
    await this.billing.recompute(c.org_id);
    return this.get(id);
  }

  async revoke(actorId: string, id: string): Promise<CompView> {
    const ended = await this.end(id, "revoked", actorId);
    if (!ended) throw new BillingError("comp_not_found", "No running free plan with that id", 404);
    return this.get(id);
  }

  /** Ends a running comp; credits already granted stay. Returns false when it wasn't running. */
  private async end(
    id: string,
    reason: "expired" | "revoked" | "replaced_by_purchase",
    actorId: string | null,
  ) {
    const [c] = await this.db.execute<{
      org_id: string;
      user_id: string | null;
      plan_code: string;
      subscription_id: string | null;
      months: number;
    }>(sql`
      update public.comps set ended_at = now(), end_reason = ${reason}, ended_by = ${actorId}::uuid
      where id = ${id}::uuid and ended_at is null
      returning org_id, user_id, plan_code, subscription_id, months`);
    if (!c) return false;
    if (c.subscription_id)
      await this.db.execute(sql`
        update public.subscriptions set status = 'expired',
          current_period_end = least(coalesce(current_period_end, now()), now()), updated_at = now()
        where id = ${c.subscription_id}::uuid`);
    await this.log({ compId: id, orgId: c.org_id, actorId, action: "ended", detail: { reason } });
    await this.billing.recompute(c.org_id);
    track(this.db, {
      event: "comp_ended",
      userId: c.user_id,
      orgId: c.org_id,
      uuid: deterministicUuid("comp_ended", id),
      properties: { plan: c.plan_code, months: Number(c.months), reason },
    });
    return true;
  }

  // -------------------------------------------------------------------------
  // Reading

  private compSelect(where: ReturnType<typeof sql>, limit = 200) {
    return this.db.execute<CompRow>(sql`
      select c.id, c.org_id, o.name as org_name, c.user_id,
        (select u.email from public.worker_admin_user(c.user_id) u) as email,
        c.plan_code, c.months, c.starts_at, c.ends_at, c.code_id, c.note, c.ended_at, c.end_reason, c.created_at
      from public.comps c left join public.organizations o on o.id = c.org_id
      where ${where}
      order by (c.ended_at is null) desc, c.created_at desc
      limit ${limit}`);
  }

  async get(id: string): Promise<CompView> {
    const [r] = await this.compSelect(sql`c.id = ${id}::uuid`, 1);
    if (!r) throw new BillingError("comp_not_found", "No free plan with that id", 404);
    return view(r);
  }

  async list(opts: { running?: boolean; limit?: number } = {}): Promise<CompView[]> {
    const rows = await this.compSelect(
      opts.running ? sql`c.ended_at is null` : sql`true`,
      Math.min(Math.max(opts.limit ?? 100, 1), 500),
    );
    return rows.map(view);
  }

  // -------------------------------------------------------------------------
  // Gift codes

  async createCode(actorId: string, input: CodeInput): Promise<CompCodeView & { code: string }> {
    const s = await this.requireOn();
    await this.checkPlan(input.plan_code, s.code_plans, input.months, s);
    const max = input.max_redemptions ?? 1;
    if (!Number.isInteger(max) || max < 1 || max > 10_000)
      throw new BillingError("bad_request", "A code can be used 1 to 10,000 times", 400);
    if (input.redeem_by && Date.parse(input.redeem_by) <= Date.now())
      throw new BillingError("bad_request", "The last day to redeem must be in the future", 400);
    const code = newCompCode();
    const [r] = await this.db.execute<CodeRow>(sql`
      insert into public.comp_codes (code_hash, code_hint, plan_code, months, max_redemptions, redeem_by, note, created_by)
      values (${hashCompCode(code)}, ${`…${code.slice(-4)}`}, ${input.plan_code}, ${input.months}, ${max},
        ${input.redeem_by ?? null}::timestamptz, ${input.note ?? null}, ${actorId}::uuid)
      returning id, code_hint, plan_code, months, max_redemptions, redeemed_count, redeem_by, note, disabled_at, created_at`);
    await this.log({
      codeId: r!.id,
      actorId,
      action: "code_created",
      detail: { plan_code: input.plan_code, months: input.months, max_redemptions: max },
    });
    return { ...codeView(r!), code: formatCompCode(code) };
  }

  async codes(limit = 200): Promise<CompCodeView[]> {
    const rows = await this.db.execute<CodeRow>(sql`
      select id, code_hint, plan_code, months, max_redemptions, redeemed_count, redeem_by, note, disabled_at, created_at
      from public.comp_codes order by created_at desc limit ${Math.min(Math.max(limit, 1), 500)}`);
    return rows.map(codeView);
  }

  async updateCode(
    actorId: string,
    id: string,
    patch: { disabled?: boolean; redeem_by?: string | null; max_redemptions?: number },
  ): Promise<CompCodeView> {
    const [cur] = await this.db.execute<CodeRow>(sql`
      select id, code_hint, plan_code, months, max_redemptions, redeemed_count, redeem_by, note, disabled_at, created_at
      from public.comp_codes where id = ${id}::uuid`);
    if (!cur) throw new BillingError("code_not_found", "No gift code with that id", 404);
    const max = patch.max_redemptions ?? Number(cur.max_redemptions);
    if (!Number.isInteger(max) || max < Number(cur.redeemed_count) || max > 10_000)
      throw new BillingError(
        "bad_request",
        `Uses must be between ${cur.redeemed_count} (already used) and 10,000`,
        400,
      );
    const redeemBy = patch.redeem_by === undefined ? iso(cur.redeem_by) : patch.redeem_by;
    const disabled = patch.disabled === undefined ? cur.disabled_at !== null : patch.disabled;
    const [r] = await this.db.execute<CodeRow>(sql`
      update public.comp_codes set max_redemptions = ${max}, redeem_by = ${redeemBy}::timestamptz,
        disabled_at = case when ${disabled} then coalesce(disabled_at, now()) else null end
      where id = ${id}::uuid
      returning id, code_hint, plan_code, months, max_redemptions, redeemed_count, redeem_by, note, disabled_at, created_at`);
    await this.log({ codeId: id, actorId, action: "code_updated", detail: { ...patch } });
    return codeView(r!);
  }

  /** What a code gives, for the casama.ai/g/ page and the redeem screen; null when it can't be used. */
  async preview(input: string) {
    const code = normalizeCompCode(input);
    if (!code || !this.billing.enabled) return null;
    const [r] = await this.db.execute<{ plan_code: string; plan_name: string; months: number }>(sql`
      select c.plan_code, p.name as plan_name, c.months from public.comp_codes c
      join public.plans p on p.code = c.plan_code
      join public.billing_settings b on b.id and b.comps_enabled
      where c.code_hash = ${hashCompCode(code)} and c.disabled_at is null
        and (c.redeem_by is null or c.redeem_by > now()) and c.redeemed_count < c.max_redemptions`);
    return r ? { plan_code: r.plan_code, plan_name: r.plan_name, months: Number(r.months) } : null;
  }

  /**
   * Redeems a gift code into a workspace the person owns (the route checks ownership). One gift
   * code per person and per inbox, ever; the code row is locked so two people can't both take
   * its last use.
   */
  async redeem(userId: string, orgId: string, input: string): Promise<CompView> {
    const s = await this.requireOn();
    const code = normalizeCompCode(input);
    if (!code) throw new BillingError("comp_code_invalid", "That code doesn't exist", 404);
    const [key] = await this.db.execute<{ k: string | null }>(
      sql`select public.user_email_key(${userId}::uuid) as k`,
    );
    const [who] = await this.db.execute<{ banned: boolean }>(
      sql`select banned from public.worker_admin_user(${userId}::uuid)`,
    );
    if (who?.banned)
      throw new BillingError("account_banned", "This account can't redeem codes", 403);
    const [used] = await this.db.execute<{ n: number }>(sql`
      select count(*)::int as n from public.comps
      where code_id is not null and (user_id = ${userId}::uuid or (${key?.k ?? null}::text is not null and redeemer_key = ${key?.k ?? null}))`);
    if ((used?.n ?? 0) > 0)
      throw new BillingError("comp_code_used", "You've already used a gift code", 409);
    const result = await this.db.transaction(async (raw) => {
      const tx = raw as unknown as Database;
      const [c] = await tx.execute<{
        id: string;
        plan_code: string;
        months: number;
        max_redemptions: number;
        redeemed_count: number;
        redeem_by: Date | null;
        disabled_at: Date | null;
      }>(sql`
        select id, plan_code, months, max_redemptions, redeemed_count, redeem_by, disabled_at
        from public.comp_codes where code_hash = ${hashCompCode(code)} for update`);
      if (!c) throw new BillingError("comp_code_invalid", "That code doesn't exist", 404);
      if (c.disabled_at || (c.redeem_by && new Date(c.redeem_by) <= new Date()))
        throw new BillingError("comp_code_expired", "That code has expired", 409);
      if (Number(c.redeemed_count) >= Number(c.max_redemptions))
        throw new BillingError("comp_code_used_up", "That code has been used up", 409);
      if (!s.code_plans.includes(c.plan_code))
        throw new BillingError("comp_code_expired", "That code has expired", 409);
      await this.requireUseful(orgId, c.plan_code, true);
      await this.requireRoom(s);
      const compId = await this.create({
        orgId,
        userId,
        planCode: c.plan_code,
        months: Number(c.months),
        note: null,
        grantedBy: null,
        codeId: c.id,
        redeemerKey: key?.k ?? null,
        tx,
      });
      await tx.execute(
        sql`update public.comp_codes set redeemed_count = redeemed_count + 1 where id = ${c.id}::uuid`,
      );
      return { compId, plan: c.plan_code, months: Number(c.months), codeId: c.id };
    });
    await this.billing.recompute(orgId);
    await this.log({
      compId: result.compId,
      codeId: result.codeId,
      orgId,
      actorId: userId,
      action: "redeemed",
      detail: { plan_code: result.plan, months: result.months },
    });
    track(this.db, {
      event: "comp_redeemed",
      userId,
      orgId,
      properties: { plan: result.plan, months: result.months },
    });
    return this.get(result.compId);
  }

  // -------------------------------------------------------------------------
  // The worker's minute (from BillingService.settle)

  async tick() {
    if (!this.billing.enabled) return { ended: 0, reminded: 0, converted: 0 };
    let ended = 0;
    // Ended by time.
    const due = await this.db.execute<{ id: string }>(
      sql`select id from public.comps where ended_at is null and ends_at <= now() order by ends_at limit 200`,
    );
    for (const d of due) if (await this.end(d.id, "expired", null)) ended++;
    // A paid plan at least as high took over. A trial isn't paid: trials ignore comps both ways
    // (D-461), so starting one doesn't throw away the rest of a comp.
    const replaced = await this.db.execute<{ id: string }>(sql`
      select c.id from public.comps c join public.plans cp on cp.code = c.plan_code
      where c.ended_at is null and exists (
        select 1 from public.subscriptions s join public.plans p on p.code = s.plan_code
        where s.org_id = c.org_id and s.source <> 'comp' and s.status = any(${arr(ENTITLED)}::text[])
          and s.status <> 'trialing'
          and (s.current_period_end is null or s.current_period_end > now()) and p.sort >= cp.sort)
      limit 200`);
    for (const r of replaced) if (await this.end(r.id, "replaced_by_purchase", null)) ended++;
    const reminded = await this.remind();
    const converted = await this.conversions();
    return { ended, reminded, converted };
  }

  /** One push and one email, a week before the end, for comps that lasted longer than that. */
  private async remind() {
    const rows = await this.db.execute<{
      id: string;
      org_id: string;
      user_id: string | null;
      plan_code: string;
      plan_name: string;
      ends_at: Date;
    }>(sql`
      update public.comps c set reminder_sent_at = now()
      from public.plans p
      where p.code = c.plan_code and c.id in (
        select id from public.comps
        where ended_at is null and reminder_sent_at is null
          and ends_at > now() and ends_at <= now() + make_interval(days => ${COMP_REMINDER_DAYS}::int)
          and starts_at < now() - make_interval(days => ${COMP_REMINDER_DAYS}::int)
        order by ends_at limit 200 for update skip locked)
      returning c.id, c.org_id, c.user_id, c.plan_code, p.name as plan_name, c.ends_at`);
    for (const r of rows) {
      const until = new Date(r.ends_at).toISOString();
      const day = new Date(r.ends_at).toLocaleDateString("en-US", {
        month: "long",
        day: "numeric",
        timeZone: "UTC",
      });
      if (r.user_id)
        await this.db.execute(sql`
          insert into public.notifications (user_id, org_id, kind, payload, push_status, push_after)
          values (${r.user_id}::uuid, ${r.org_id}::uuid, 'comp_ending', ${JSON.stringify({
            title: `Your free ${r.plan_name} ends on ${day}`,
            body: `Keep everything in ${r.plan_name} by choosing it before then.`,
            link: "/settings/billing",
          })}::jsonb, 'deferred', now())`);
      await queueAccountEmail(this.db, {
        kind: "comp_ending",
        orgId: r.org_id,
        dedupeKey: `comp_ending:${r.id}:${until}`,
        data: { plan: r.plan_name, until },
      }).catch(() => undefined);
    }
    return rows.length;
  }

  /** A paid subscription that started during a comp, or within 30 days of its end. */
  private async conversions() {
    const rows = await this.db.execute<{
      id: string;
      org_id: string;
      user_id: string | null;
      plan_code: string;
      paid_plan: string;
    }>(sql`
      with paid as (
        select c.id, (
          select s.plan_code from public.subscriptions s
          where s.org_id = c.org_id and s.source <> 'comp' and s.created_at >= c.starts_at
            and s.status = any(${arr(ENTITLED)}::text[]) and s.status <> 'trialing'
          order by s.created_at limit 1) as paid_plan
        from public.comps c
        where c.converted_at is null
          and (c.ended_at is null or c.ended_at > now() - make_interval(days => ${CONVERSION_DAYS}::int))
        for update of c skip locked)
      update public.comps c set converted_at = now()
      from paid
      where paid.id = c.id and paid.paid_plan is not null
      returning c.id, c.org_id, c.user_id, c.plan_code, paid.paid_plan`);
    for (const r of rows)
      track(this.db, {
        event: "comp_converted",
        userId: r.user_id,
        orgId: r.org_id,
        uuid: deterministicUuid("comp_converted", r.id),
        properties: { plan: r.plan_code, paid_plan: r.paid_plan },
      });
    return rows.length;
  }

  // -------------------------------------------------------------------------

  private async log(e: {
    compId?: string | null;
    codeId?: string | null;
    orgId?: string | null;
    actorId: string | null;
    action: string;
    detail?: Record<string, unknown>;
  }) {
    await this.db.execute(sql`
      insert into public.comp_events (comp_id, code_id, org_id, actor_id, action, detail)
      values (${e.compId ?? null}::uuid, ${e.codeId ?? null}::uuid, ${e.orgId ?? null}::uuid,
        ${e.actorId}::uuid, ${e.action}, ${JSON.stringify(e.detail ?? {})}::jsonb)`);
  }
}
