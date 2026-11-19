/**
 * The waitlist and invite gate for Casama Cloud (docs/WAITLIST-PLAN.md).
 *
 * While the gate is on, Auth's before-user-created hook (routes/abuse.ts) lets a new account
 * through only for an email address that has been let in. A batch, an invite code and a
 * hand-added address all do the same thing: they mark that address `admitted` in
 * public.waitlist_entries. The gate is a setting (instance_settings key "signup_gate"), open
 * unless an owner turns it on, and the whole feature exists only where SIGNUP_WAITLIST says so
 * (auto: with billing, so a self-hosted server never sees it).
 */
import { createHash, createHmac, randomInt, randomUUID, timingSafeEqual } from "node:crypto";
import { readFileSync } from "node:fs";
import type { NotificationService } from "@casama/agent";
import { type Database, pgErrorMessage } from "@casama/db";
import { OPENROUTER_CREDIT_FEE } from "@casama/domain";
import { getProductAnalytics } from "@casama/observability";
import { sql } from "drizzle-orm";
import { appLink, type Env } from "../env.ts";
import { instanceOwners } from "./capacity.ts";
import type { EmailSender } from "./email.ts";
import { type BrandedEmail, renderEmailHtml, renderEmailText } from "./email-layout.ts";
import { type NewsletterConfig, newsletterState, setNewsletterChoice } from "./newsletter.ts";
import { normalizeReferralCode } from "./referrals.ts";

// --- is it there, and is it on ----------------------------------------------------------------

/** Whether this server has the waitlist at all: Casama Cloud (billing on) unless told otherwise. */
export function waitlistAvailable(env: Pick<Env, "SIGNUP_WAITLIST" | "BILLING_ENABLED">) {
  if (env.SIGNUP_WAITLIST === "on") return true;
  if (env.SIGNUP_WAITLIST === "off") return false;
  return env.BILLING_ENABLED;
}

export interface SignupGate {
  /** open: anyone can sign up. invite_only: only addresses that were let in. */
  mode: "open" | "invite_only";
  /** From this moment the gate counts as open, whatever `mode` says (launch day). */
  opens_at: string | null;
  /** Invites each member has, once they've finished a first chat. */
  invites_per_person: number;
  /** People the daily automatic batch lets in; 0: none. */
  daily_admit: number;
  /** "You're in" emails a day at most (the mail provider's cap is shared with sign-in links). */
  daily_emails_max: number;
  /** The hour (UTC, 0–23) the daily automatic batch runs. */
  batch_hour_utc: number;
}

export const DEFAULT_SIGNUP_GATE: SignupGate = {
  mode: "open",
  opens_at: null,
  invites_per_person: 3,
  daily_admit: 0,
  daily_emails_max: 25,
  batch_hour_utc: 15,
};

const wholeNumber = (v: unknown, max: number) =>
  typeof v === "number" && Number.isInteger(v) && v >= 0 && v <= max;

/** A stored or submitted setting, with defaults for whatever it leaves out. */
export function checkSignupGate(input: unknown): { gate: SignupGate | null; errors: string[] } {
  const errors: string[] = [];
  if (!input || typeof input !== "object" || Array.isArray(input))
    return { gate: null, errors: ["The setting must be an object"] };
  const v = input as Record<string, unknown>;
  const gate: SignupGate = { ...DEFAULT_SIGNUP_GATE };
  if (v.mode !== undefined) {
    if (v.mode === "open" || v.mode === "invite_only") gate.mode = v.mode;
    else errors.push("mode must be open or invite_only");
  }
  if (v.opens_at !== undefined && v.opens_at !== null) {
    if (typeof v.opens_at === "string" && !Number.isNaN(Date.parse(v.opens_at)))
      gate.opens_at = new Date(v.opens_at).toISOString();
    else errors.push("opens_at must be a date and time, or null");
  }
  for (const [key, max] of [
    ["invites_per_person", 100],
    ["daily_admit", 10_000],
    ["daily_emails_max", 100_000],
    ["batch_hour_utc", 23],
  ] as const) {
    if (v[key] === undefined) continue;
    if (wholeNumber(v[key], max)) gate[key] = v[key] as number;
    else errors.push(`${key} must be a whole number from 0 to ${max}`);
  }
  return errors.length ? { gate: null, errors } : { gate, errors };
}

const KEY = "signup_gate";
const TTL_MS = 15_000;
let cached: { at: number; value: SignupGate } | null = null;

/** The gate setting, read with a short cache: the hook asks on every new account. */
export async function getSignupGate(db: Database): Promise<SignupGate> {
  if (cached && Date.now() - cached.at < TTL_MS) return cached.value;
  const [row] = await db.execute<{ value: unknown }>(
    sql`select value from public.instance_settings where key = ${KEY}`,
  );
  // No row: open. A stored value that doesn't pass is a mistake someone made by hand, and reading
  // it as "open" would quietly take the gate down, so it throws and the hook refuses.
  let value = DEFAULT_SIGNUP_GATE;
  if (row?.value) {
    const { gate, errors } = checkSignupGate(row.value);
    if (!gate) throw new Error(`signup_gate setting is not valid: ${errors.join("; ")}`);
    value = gate;
  }
  cached = { at: Date.now(), value };
  return value;
}

export async function setSignupGate(db: Database, value: SignupGate) {
  await db.execute(sql`
    insert into public.instance_settings (key, value, updated_at)
    values (${KEY}, ${JSON.stringify(value)}::jsonb, now())
    on conflict (key) do update set value = excluded.value, updated_at = now()`);
  cached = { at: Date.now(), value };
  return value;
}

export function resetSignupGateCache() {
  cached = null;
}

/** Whether new accounts are by invitation right now. */
export function gateClosed(gate: SignupGate, now = Date.now()) {
  if (gate.mode !== "invite_only") return false;
  return !(gate.opens_at && Date.parse(gate.opens_at) <= now);
}

// --- what the hook says -------------------------------------------------------------------------

export const inviteOnlyMessage = (env: Pick<Env, "WAITLIST_URL">) =>
  `Casama Cloud is invite-only for now. Join the waitlist or enter an invite code at ${env.WAITLIST_URL.replace(/^https?:\/\//, "")}.`;

/** Sign in with Apple's "Hide My Email" address never matches the address an invite was for. */
export const RELAY_MESSAGE =
  "Casama Cloud is invite-only for now, and your invite is for another email address. With Apple, choose Share My Email, or use Continue with Email.";

export const isAppleRelay = (email: string) => /@privaterelay\.appleid\.com$/i.test(email.trim());

/** Whether this address may make an account while the gate is on. */
export async function signupAllowed(db: Database, email: string): Promise<boolean> {
  if (!email) return false;
  const [row] = await db.execute<{ ok: boolean }>(sql`
    select public.signup_admitted(${email}) or public.signup_invited_with_seat(${email}) as ok`);
  return !!row?.ok;
}

// --- addresses ---------------------------------------------------------------------------------

export function cleanEmail(input: string): string | null {
  const email = input.trim().toLowerCase();
  if (email.length > 254 || !/^[^\s@]+@[^\s@.]+(\.[^\s@.]+)+$/.test(email)) return null;
  return email;
}

let disposable: Set<string> | null = null;
function disposableDomains() {
  if (!disposable) {
    const text = readFileSync(
      new URL("../data/disposable-email-domains.txt", import.meta.url),
      "utf8",
    );
    disposable = new Set(
      text
        .split("\n")
        .map((l) => l.trim().toLowerCase())
        .filter((l) => l && !l.startsWith("#")),
    );
  }
  return disposable;
}

/** Whether the address is at a throwaway mail service (its domain, or a parent of it, is listed). */
export function isDisposableEmail(email: string) {
  const parts = (email.split("@")[1] ?? "").toLowerCase().split(".");
  const list = disposableDomains();
  for (let i = 0; i < parts.length - 1; i++) if (list.has(parts.slice(i).join("."))) return true;
  return false;
}

/** A keyed hash of the caller's address: enough to count joins from one place, not to find it. */
export const ipHash = (secret: string, ip: string) =>
  createHmac("sha256", `${secret}:waitlist-ip`).update(ip).digest("hex").slice(0, 32);

// --- codes -------------------------------------------------------------------------------------

const CAMPAIGN_CODE = /^[A-Z0-9][A-Z0-9-]{2,30}[A-Z0-9]$/;

/** A campaign code in its stored form, or null when the text can't be one. */
export function campaignCodeForm(input: string): string | null {
  const last =
    input
      .trim()
      .replace(/[?#].*$/, "")
      .replace(/\/+$/, "")
      .split("/")
      .pop() ?? "";
  const s = last.toUpperCase().replace(/\s+/g, "");
  return CAMPAIGN_CODE.test(s) && (s.length >= 9 || s.includes("-")) ? s : null;
}

/**
 * One-time codes (the "You're in" email's, §7.3): 8 Crockford base32 characters shown as XXXX-XXXX.
 * A member's code has 6 characters and a workspace code 8 with no hyphen (the invite routes never
 * take workspace codes). A campaign may share the shape: a handed-out one-time code is looked up
 * first, by its hash.
 */
const ONE_TIME_ALPHABET = "0123456789ABCDEFGHJKMNPQRSTVWXYZ";

export function newOneTimeCode() {
  let s = "";
  for (let i = 0; i < 8; i++) s += ONE_TIME_ALPHABET[randomInt(ONE_TIME_ALPHABET.length)];
  return `${s.slice(0, 4)}-${s.slice(4)}`;
}

/** A one-time code in its stored form (XXXX-XXXX), or null when the text can't be one. */
export function oneTimeCodeForm(input: string): string | null {
  const last =
    input
      .trim()
      .replace(/[?#].*$/, "")
      .replace(/\/+$/, "")
      .split("/")
      .pop() ?? "";
  const s = last
    .toUpperCase()
    .replace(/[^0-9A-Z]/g, "")
    .replace(/O/g, "0")
    .replace(/[IL]/g, "1")
    .replace(/U/g, "V");
  if (s.length !== 8) return null;
  for (const ch of s) if (!ONE_TIME_ALPHABET.includes(ch)) return null;
  return `${s.slice(0, 4)}-${s.slice(4)}`;
}

/** What the database keeps of a one-time code: the same hash public.waitlist_claim computes. */
export const oneTimeCodeHash = (code: string) =>
  createHash("sha256").update(code.replace(/-/g, "")).digest("hex");

/**
 * An invite code however it was typed or pasted (a link, spaces, lower case) in its stored form:
 * a one-time code when one with that value was handed out, a campaign code when one with that name
 * exists, else a member's 6-character code.
 */
export async function resolveInviteCode(db: Database, input: string): Promise<string | null> {
  const oneTime = oneTimeCodeForm(input);
  if (oneTime) {
    const [row] = await db.execute<{ ok: boolean }>(sql`
      select true as ok from public.waitlist_entries
      where one_time_code_hash = ${oneTimeCodeHash(oneTime)} and status in ('admitted', 'joined')`);
    if (row) return oneTime;
  }
  const campaign = campaignCodeForm(input);
  if (campaign) {
    const [row] = await db.execute<{ code: string }>(
      sql`select code from public.invite_campaigns where code = ${campaign}`,
    );
    if (row) return row.code;
  }
  return normalizeReferralCode(input);
}

// --- analytics (§11) ----------------------------------------------------------------------------
// The people these events are about have no account yet, so they are personless: an entry's id
// when there is one, else a fresh id. Never an address or a code.

const eventId = (entryId?: string | null) => `waitlist:${entryId ?? randomUUID()}`;

/** How a claim came in: the website, the app, Auth's hook at sign-up, or a native sign-in token. */
export type ClaimVia = "web" | "app" | "signup" | "id_token";

export function claimVia(source: string | null | undefined, idToken: boolean): ClaimVia {
  if (idToken) return "id_token";
  return /^app/i.test(source ?? "") ? "app" : "web";
}

/** The waitlist_admitted event's `via`: batch (the daily automatic batch), hand (an owner), code. */
export function admittedVia(stored: string | null | undefined): "batch" | "hand" | "code" {
  if (stored === "auto") return "batch";
  if (stored === "batch" || stored === "admin" || !stored) return "hand";
  return "code";
}

export function trackJoined(entryId: string, selfHosting: boolean, source: string | null) {
  const a = getProductAnalytics();
  if (!a.enabled) return;
  a.capture({
    event: "waitlist_joined",
    distinctId: eventId(entryId),
    personless: true,
    properties: { source: short(source, 64) ?? "unknown", self_hosting: selfHosting },
  });
}

export function trackClaim(claim: ClaimResult, via: ClaimVia) {
  const a = getProductAnalytics();
  if (!a.enabled) return;
  const distinctId = eventId();
  a.capture({
    event: "invite_claimed",
    distinctId,
    personless: true,
    properties: { kind: claim.kind, outcome: claim.outcome, via },
  });
  if (claim.admittedNow)
    a.capture({
      event: "waitlist_admitted",
      distinctId,
      personless: true,
      properties: { via: "code" },
    });
}

function trackAdmitted(entryId: string, via: "batch" | "hand" | "code") {
  const a = getProductAnalytics();
  if (!a.enabled) return;
  a.capture({
    event: "waitlist_admitted",
    distinctId: eventId(entryId),
    personless: true,
    properties: { via },
  });
}

/** Why the hook turned a sign-up away. */
export type RefusalReason =
  | "gate"
  | "relay"
  | "allowlist"
  | "invited_only"
  | "code_not_found"
  | "code_used_up";

export function trackRefused(reason: RefusalReason) {
  const a = getProductAnalytics();
  if (!a.enabled) return;
  a.capture({
    event: "signup_refused",
    distinctId: eventId(),
    personless: true,
    properties: { reason },
  });
}

// --- joining and claiming ----------------------------------------------------------------------

export const NEWSLETTER_WORDING = "waitlist-2026-11";

export interface JoinInput {
  email: string;
  source?: string | null;
  ref?: string | null;
  note?: string | null;
  selfHosting?: boolean;
  newsletter?: boolean;
  ipHash?: string | null;
}

const short = (s: string | null | undefined, max: number) => {
  const t = (s ?? "").trim();
  return t ? t.slice(0, max) : null;
};

/** How many joins came from one place in the last day. */
export async function joinsFrom(db: Database, hash: string): Promise<number> {
  const [row] = await db.execute<{ n: number }>(sql`
    select count(*)::int as n from public.waitlist_entries
    where ip_hash = ${hash} and created_at > now() - interval '24 hours'`);
  return row?.n ?? 0;
}

/**
 * Puts an address on the list, or leaves it as it is when it's already there (a repeat can add
 * the self-hosting box, the first note and a yes to the monthly email, never take them away).
 * An address that already has an account is left off: the caller still answers "You're on the
 * list" (nothing may be probed), but a waiting row would never become `joined` and a batch would
 * send that person a "You're in" email. Returns null then.
 */
export async function joinWaitlist(
  db: Database,
  e: JoinInput,
): Promise<{ id: string; created: boolean } | null> {
  const news = !!e.newsletter;
  const [row] = await db.execute<{ id: string; created: boolean }>(sql`
    insert into public.waitlist_entries as w (
      email, email_key, source, ref, self_hosting, note, ip_hash,
      newsletter_opt_in, newsletter_consent_at, newsletter_wording)
    select ${e.email}, public.email_key(${e.email}), ${short(e.source, 64)}, ${short(e.ref, 64)},
      ${!!e.selfHosting}, ${short(e.note, 280)}, ${e.ipHash ?? null},
      ${news}, case when ${news} then now() end, case when ${news} then ${NEWSLETTER_WORDING} end
    where public.email_key(${e.email}) is not null
      and not exists (select 1 from auth.users u
                      where public.email_key(u.email::text) = public.email_key(${e.email}))
    on conflict (email_key) do update set
      self_hosting = w.self_hosting or excluded.self_hosting,
      note = coalesce(w.note, excluded.note),
      newsletter_opt_in = w.newsletter_opt_in or excluded.newsletter_opt_in,
      newsletter_consent_at = case when excluded.newsletter_opt_in and not w.newsletter_opt_in
        then now() else w.newsletter_consent_at end,
      newsletter_wording = case when excluded.newsletter_opt_in and not w.newsletter_opt_in
        then excluded.newsletter_wording else w.newsletter_wording end,
      updated_at = now()
    returning w.id, (xmax = 0) as created`);
  return row ?? null;
}

export type InviteKind = "personal" | "campaign" | "one_time";

export interface ClaimResult {
  outcome: "admitted" | "waitlisted";
  kind: InviteKind;
  label: string | null;
  inviterId: string | null;
  /** This claim let the address in (false: it was in already, or no invite was left). */
  admittedNow: boolean;
}

/** Claims an invite code for an address; null when the code doesn't exist. */
export async function claimInvite(
  db: Database,
  e: {
    email: string;
    code: string;
    perPerson: number;
    newsletter?: boolean;
    source?: string | null;
    ipHash?: string | null;
  },
): Promise<ClaimResult | null> {
  try {
    const [row] = await db.execute<{
      outcome: "admitted" | "waitlisted";
      kind: InviteKind;
      label: string | null;
      inviter_id: string | null;
      admitted_now: boolean;
    }>(sql`
      select outcome, kind, label, inviter_id, admitted_now from public.waitlist_claim(
        ${e.email}, ${e.code}, ${e.perPerson}, ${!!e.newsletter}, ${NEWSLETTER_WORDING},
        ${short(e.source, 64)}, ${e.ipHash ?? null})`);
    if (!row) return null;
    return {
      outcome: row.outcome,
      kind: row.kind,
      label: row.label,
      inviterId: row.inviter_id,
      admittedNow: !!row.admitted_now,
    };
  } catch (err) {
    if (pgErrorMessage(err) === "invite_not_found") return null;
    throw err;
  }
}

export async function previewInvite(db: Database, code: string, perPerson: number) {
  const [row] = await db.execute<{
    kind: InviteKind;
    label: string | null;
    inviter_name: string | null;
    available: boolean;
  }>(
    sql`select kind, label, inviter_name, available from public.invite_code_preview(${code}, ${perPerson})`,
  );
  return row ?? null;
}

/** A member's invites: how many they have, used, and whether they're unlocked yet. */
export async function memberInvites(db: Database, userId: string, perPerson: number) {
  const [row] = await db.execute<{ used: number; unlocked: boolean; bonus: number }>(sql`
    select public.invites_used(${userId}::uuid) as used,
      public.invites_unlocked(${userId}::uuid) as unlocked,
      coalesce((select invite_bonus from public.referral_codes where user_id = ${userId}::uuid), 0) as bonus`);
  const total = perPerson + (row?.bonus ?? 0);
  const used = row?.used ?? 0;
  return { total, used, left: Math.max(0, total - used), unlocked: !!row?.unlocked };
}

// --- the link that takes an address off the list -------------------------------------------------

const leaveMac = (secret: string, id: string) =>
  createHmac("sha256", `${secret}:waitlist-leave`).update(id).digest("base64url").slice(0, 32);

export const leaveToken = (secret: string, id: string) => `${id}.${leaveMac(secret, id)}`;

/** Removes the entry a leave token names. Answers whether the token was good. */
export async function leaveWaitlist(db: Database, secret: string, token: string) {
  const [id, mac] = token.split(".");
  if (!id || !mac || !/^[0-9a-f-]{36}$/i.test(id)) return false;
  const expected = Buffer.from(leaveMac(secret, id));
  const got = Buffer.from(mac);
  if (got.length !== expected.length || !timingSafeEqual(got, expected)) return false;
  // Someone who already made an account is no longer on any list; their row only records how
  // they got in, and deleting it would shut them out if they deleted the account and came back.
  await db.execute(
    sql`delete from public.waitlist_entries where id = ${id}::uuid and status <> 'joined'`,
  );
  return true;
}

// --- owner: numbers, the list, letting people in -------------------------------------------------

const UTC_MIDNIGHT = sql`date_trunc('day', now() at time zone 'utc') at time zone 'utc'`;
const FIRST_CHAT = sql`exists (select 1 from public.analytics_milestones m
  where m.user_id = w.user_id and m.milestone = 'first_value')`;

export async function waitlistStats(db: Database) {
  const [totals] = await db.execute<{
    waiting: number;
    queued: number;
    admitted: number;
    joined: number;
    first_chat: number;
    listed_today: number;
    admitted_today: number;
    emails_today: number;
  }>(sql`
    select
      count(*) filter (where w.status = 'waiting' and w.queued_at is null)::int as waiting,
      count(*) filter (where w.status = 'waiting' and w.queued_at is not null)::int as queued,
      count(*) filter (where w.status in ('admitted', 'joined'))::int as admitted,
      count(*) filter (where w.status = 'joined')::int as joined,
      count(*) filter (where w.status = 'joined' and ${FIRST_CHAT})::int as first_chat,
      count(*) filter (where w.created_at >= ${UTC_MIDNIGHT})::int as listed_today,
      count(*) filter (where w.admitted_at >= ${UTC_MIDNIGHT})::int as admitted_today,
      count(*) filter (where w.notified_at >= ${UTC_MIDNIGHT})::int as emails_today
    from public.waitlist_entries w`);
  const funnel = (by: ReturnType<typeof sql>) =>
    db.execute<{
      key: string;
      listed: number;
      admitted: number;
      joined: number;
      first_chat: number;
    }>(sql`
      select ${by} as key, count(*)::int as listed,
        count(*) filter (where w.status in ('admitted', 'joined'))::int as admitted,
        count(*) filter (where w.status = 'joined')::int as joined,
        count(*) filter (where w.status = 'joined' and ${FIRST_CHAT})::int as first_chat
      from public.waitlist_entries w group by 1 order by 2 desc, 1 limit 50`);
  // How people got in: a campaign by its code, every member's invites together.
  const bySource = await funnel(sql`coalesce(w.source, 'unknown')`);
  const byVia = await funnel(sql`case
    when w.admitted_via is null then 'waiting'
    when w.admitted_via like 'invite:%' then 'invite'
    else w.admitted_via end`);
  const [batch] = await db.execute<{
    day: string;
    ran_at: Date;
    admitted: number;
    skipped_reason: string | null;
    detail: string | null;
  }>(sql`
    select to_char(day, 'YYYY-MM-DD') as day, ran_at, admitted, skipped_reason, detail
    from public.waitlist_batches order by day desc limit 1`);
  const lastBatch = batch
    ? {
        day: batch.day,
        ran_at: new Date(batch.ran_at).toISOString(),
        admitted: batch.admitted,
        skipped_reason: batch.skipped_reason,
        detail: batch.detail,
      }
    : null;
  const empty = {
    waiting: 0,
    queued: 0,
    admitted: 0,
    joined: 0,
    first_chat: 0,
    listed_today: 0,
    admitted_today: 0,
    emails_today: 0,
  };
  return {
    ...(totals ?? empty),
    by_source: [...bySource],
    by_via: [...byVia],
    last_batch: lastBatch,
  };
}

export interface WaitlistFilter {
  status?: "waiting" | "queued" | "admitted" | "joined";
  source?: string;
  ref?: string;
  selfHosting?: boolean;
  q?: string;
}

const where = (f: WaitlistFilter) => sql`
  (${f.status ?? null}::text is null
    or (${f.status ?? null} = 'waiting' and w.status = 'waiting' and w.queued_at is null)
    or (${f.status ?? null} = 'queued' and w.status = 'waiting' and w.queued_at is not null)
    or (${f.status ?? null} in ('admitted', 'joined') and w.status = ${f.status ?? null}))
  and (${f.source ?? null}::text is null or w.source = ${f.source ?? null})
  and (${f.ref ?? null}::text is null or w.ref = ${f.ref ?? null} or w.invite_code = ${f.ref ?? null})
  and (${f.selfHosting ?? null}::boolean is null or w.self_hosting = ${f.selfHosting ?? null})
  and (${f.q ?? null}::text is null or w.email::text ilike '%' || ${f.q ?? null} || '%'
    or w.note ilike '%' || ${f.q ?? null} || '%')`;

/** The order batches take people in: a code that had run out, self-hosters, a note, then oldest. */
const BATCH_ORDER = sql`w.priority desc, w.self_hosting desc, (w.note is not null) desc, w.created_at, w.id`;

export type WaitlistRow = {
  id: string;
  email: string;
  status: "waiting" | "queued" | "admitted" | "joined";
  source: string | null;
  ref: string | null;
  self_hosting: boolean;
  note: string | null;
  priority: number;
  invite_code: string | null;
  admitted_via: string | null;
  admitted_at: Date | null;
  joined_at: Date | null;
  created_at: Date;
};

export async function listWaitlist(db: Database, f: WaitlistFilter, limit = 50, offset = 0) {
  const rows = await db.execute<WaitlistRow>(sql`
    select w.id, w.email::text as email,
      case when w.status = 'waiting' and w.queued_at is not null then 'queued' else w.status end as status,
      w.source, w.ref, w.self_hosting, w.note, w.priority, w.invite_code, w.admitted_via,
      w.admitted_at, w.joined_at, w.created_at
    from public.waitlist_entries w where ${where(f)}
    order by ${f.status === "waiting" || !f.status ? BATCH_ORDER : sql`w.updated_at desc, w.id`}
    limit ${Math.max(1, Math.min(limit, 200))} offset ${Math.max(0, offset)}`);
  return [...rows];
}

/**
 * Chooses people for the next "You're in" emails: the given entries, or the next `count` in batch
 * order (within a filter). They are let in as their emails go out. Returns how many were chosen.
 */
export async function queueWaitlist(
  db: Database,
  e: {
    ids?: string[];
    count?: number;
    filter?: WaitlistFilter;
    by?: string | null;
    via: "batch" | "auto";
  },
): Promise<number> {
  const pick = e.ids?.length
    ? sql`select w.id from public.waitlist_entries w
          where w.id in (select t::uuid from jsonb_array_elements_text(${JSON.stringify(e.ids)}::jsonb) t)
            and w.status = 'waiting' and w.queued_at is null`
    : sql`select w.id from public.waitlist_entries w
          where w.status = 'waiting' and w.queued_at is null
            and ${where({ ...(e.filter ?? {}), status: undefined })}
          order by ${BATCH_ORDER} limit ${Math.max(0, Math.min(e.count ?? 0, 5000))}
          for update skip locked`;
  const rows = await db.execute<{ id: string }>(sql`
    with pick as (${pick})
    update public.waitlist_entries w
      set queued_at = now(), queued_by = ${e.by ?? null}::uuid, admitted_via = ${e.via}, updated_at = now()
    from pick where w.id = pick.id returning w.id`);
  return rows.length;
}

/**
 * Adds addresses by hand. `notify`: they get the "You're in" email like a batch; otherwise they
 * are let in at once and nobody is emailed (the owner told them). Returns how many were let in or
 * chosen; addresses already in are left alone.
 */
export async function addWaitlistEntries(
  db: Database,
  emails: string[],
  e: { by?: string | null; notify?: boolean },
): Promise<number> {
  let n = 0;
  for (const email of emails) {
    const rows = await db.execute<{ id: string }>(
      e.notify
        ? sql`
        insert into public.waitlist_entries as w (email, email_key, source, queued_at, queued_by, admitted_via)
        select ${email}, public.email_key(${email}), 'admin', now(), ${e.by ?? null}::uuid, 'admin'
        where public.email_key(${email}) is not null
        on conflict (email_key) do update
          set queued_at = now(), queued_by = excluded.queued_by, admitted_via = 'admin', updated_at = now()
          where w.status = 'waiting' and w.queued_at is null
        returning w.id`
        : sql`
        insert into public.waitlist_entries as w (email, email_key, source, status, admitted_at, admitted_via, queued_by)
        select ${email}, public.email_key(${email}), 'admin', 'admitted', now(), 'admin', ${e.by ?? null}::uuid
        where public.email_key(${email}) is not null
        on conflict (email_key) do update
          set status = 'admitted', admitted_at = now(), admitted_via = 'admin', queued_at = null,
              queued_by = excluded.queued_by, updated_at = now()
          where w.status = 'waiting'
        returning w.id`,
    );
    n += rows.length;
    if (!e.notify) for (const r of rows) trackAdmitted(r.id, "hand");
  }
  return n;
}

export async function removeWaitlistEntry(db: Database, id: string) {
  const rows = await db.execute<{ id: string }>(
    sql`delete from public.waitlist_entries where id = ${id}::uuid returning id`,
  );
  return rows.length === 1;
}

export type InviteCampaign = {
  code: string;
  label: string;
  max_uses: number;
  used: number;
  per_day: number | null;
  starts_at: Date | null;
  expires_at: Date | null;
  disabled_at: Date | null;
  created_at: Date;
};

const CAMPAIGN_COLUMNS = sql`code, label, max_uses, used, per_day, starts_at, expires_at, disabled_at, created_at`;

export async function listCampaigns(db: Database) {
  return [
    ...(await db.execute<InviteCampaign>(
      sql`select ${CAMPAIGN_COLUMNS} from public.invite_campaigns order by created_at desc, code`,
    )),
  ];
}

export async function createCampaign(
  db: Database,
  c: {
    code: string;
    label: string;
    maxUses: number;
    perDay?: number | null;
    startsAt?: string | null;
    expiresAt?: string | null;
    by?: string | null;
  },
): Promise<InviteCampaign | null> {
  const [row] = await db.execute<InviteCampaign>(sql`
    insert into public.invite_campaigns (code, label, max_uses, per_day, starts_at, expires_at, created_by)
    values (${c.code}, ${c.label}, ${c.maxUses}, ${c.perDay ?? null},
      ${c.startsAt ?? null}::timestamptz, ${c.expiresAt ?? null}::timestamptz, ${c.by ?? null}::uuid)
    on conflict (code) do nothing returning ${CAMPAIGN_COLUMNS}`);
  return row ?? null;
}

export async function updateCampaign(
  db: Database,
  code: string,
  c: {
    label?: string;
    maxUses?: number;
    perDay?: number | null;
    startsAt?: string | null;
    expiresAt?: string | null;
    disabled?: boolean;
  },
): Promise<InviteCampaign | null> {
  const has = (k: keyof typeof c) => Object.hasOwn(c, k);
  const [row] = await db.execute<InviteCampaign>(sql`
    update public.invite_campaigns set
      label = coalesce(${c.label ?? null}, label),
      max_uses = coalesce(${c.maxUses ?? null}::int, max_uses),
      per_day = case when ${has("perDay")} then ${c.perDay ?? null}::int else per_day end,
      starts_at = case when ${has("startsAt")} then ${c.startsAt ?? null}::timestamptz else starts_at end,
      expires_at = case when ${has("expiresAt")} then ${c.expiresAt ?? null}::timestamptz else expires_at end,
      disabled_at = case when ${c.disabled ?? null}::boolean is null then disabled_at
        when ${c.disabled ?? null}::boolean then coalesce(disabled_at, now()) else null end
    where code = ${code} returning ${CAMPAIGN_COLUMNS}`);
  return row ?? null;
}

// --- the worker's part ---------------------------------------------------------------------------

export function youAreInEmail(
  env: Pick<Env, "PUBLIC_APP_URL" | "PUBLIC_OPEN_URL" | "WAITLIST_URL">,
  e: { email: string; leaveUrl: string; oneTimeCode?: string | null },
): BrandedEmail {
  return {
    mascot: "wow",
    preheader: "Casama Cloud is ready for you",
    title: "You're in",
    intro: [
      "Your turn came up: Casama Cloud is ready for you.",
      `Sign in with ${e.email}. Google, Apple and the email link all work, as long as it's this address.`,
      ...(e.oneTimeCode
        ? [
            `Signing in with another address, such as Apple's Hide My Email? Use the invite code ${e.oneTimeCode} once: tap I Have an Invite on the sign-in screen, or enter it at ${env.WAITLIST_URL.replace(/^https?:\/\//, "")}. It lets in one address.`,
          ]
        : []),
      "Then give a bot something real to do. It works on its own computer, and you can watch it or take over at any time.",
    ],
    button: { label: "Open Casama", url: appLink(env, "/") },
    note: `Don't have the app yet? Get it at casama.ai/download. You asked to hear from us when your turn came; this is the only email about it. To take your address off our list: ${e.leaveUrl}`,
  };
}

type Log = (msg: string, extra?: Record<string, unknown>) => void;

/**
 * Lets in the people chosen for a "You're in" email, a few at a time and never more than the
 * day's number: a person counts as let in when their email goes out. Without a mail sender they
 * are simply let in. Returns how many were let in.
 */
export async function sendWaitlistInvites(opts: {
  db: Database;
  email?: EmailSender;
  env: Pick<Env, "PUBLIC_APP_URL" | "PUBLIC_OPEN_URL" | "WAITLIST_URL">;
  /** Signs the "remove my address" link. */
  secret: string;
  perTick?: number;
  log?: Log;
}): Promise<number> {
  const { db } = opts;
  const gate = await getSignupGate(db);
  const mail = opts.email?.enabled ? opts.email : null;
  let room = opts.perTick ?? 5;
  if (mail) {
    const [sent] = await db.execute<{ n: number }>(sql`
      select count(*)::int as n from public.waitlist_entries w where w.notified_at >= ${UTC_MIDNIGHT}`);
    room = Math.min(room, gate.daily_emails_max - (sent?.n ?? 0));
  }
  if (room <= 0) return 0;
  const queued = await db.execute<{ id: string }>(sql`
    select w.id from public.waitlist_entries w
    where w.status = 'waiting' and w.queued_at is not null and w.notify_attempts < 8
    order by w.queued_at, w.id limit ${room}`);
  let n = 0;
  for (const q of queued) {
    // Taking the row first means two workers (a deploy hands over while both run) can't both
    // send; if the send then fails, the person goes back in line.
    // The email's one-time code (§7.3) is made here and only its hash is kept; a failed send that
    // is tried again gets a new one.
    const oneTime = mail ? newOneTimeCode() : null;
    const [row] = await db.execute<{ id: string; email: string; admitted_via: string | null }>(sql`
      update public.waitlist_entries w
        set status = 'admitted', admitted_at = now(), updated_at = now(),
            notified_at = case when ${!!mail} then now() end,
            one_time_code_hash = coalesce(${oneTime ? oneTimeCodeHash(oneTime) : null}, w.one_time_code_hash)
      where w.id = ${q.id}::uuid and w.status = 'waiting' and w.queued_at is not null
      returning w.id, w.email::text as email, w.admitted_via`);
    if (!row) continue;
    if (mail) {
      try {
        const message = youAreInEmail(opts.env, {
          email: row.email,
          leaveUrl: `${opts.env.WAITLIST_URL.replace(/\/$/, "")}/leave?t=${leaveToken(opts.secret, row.id)}`,
          oneTimeCode: oneTime,
        });
        await mail.send({
          to: row.email,
          subject: "You're in: Casama is ready for you",
          text: renderEmailText(message),
          html: renderEmailHtml(message),
        });
      } catch (err) {
        await db.execute(sql`
          update public.waitlist_entries
            set status = 'waiting', admitted_at = null, notified_at = null, updated_at = now(),
                notify_attempts = notify_attempts + 1,
                notify_error = ${String((err as Error).message ?? err).slice(0, 500)}
          where id = ${row.id}::uuid and status = 'admitted' and user_id is null`);
        opts.log?.("waitlist email failed", { id: row.id, error: (err as Error).message });
        continue;
      }
    }
    trackAdmitted(row.id, admittedVia(row.admitted_via));
    n++;
  }
  return n;
}

// --- the daily automatic batch (§6.4) ------------------------------------------------------------

/** The day is skipped when yesterday's busiest moment used this share of the computer budget… */
export const BATCH_PAUSE_COMPUTERS_SHARE = 7 / 9;
/** …or yesterday's model spend on Casama's key passed this share of OpenRouter's daily cap. */
export const BATCH_PAUSE_SPEND_SHARE = 0.6;

const utcDay = (t: number) => new Date(t).toISOString().slice(0, 10);

/** Yesterday (UTC) on this server: the busiest moment for computers, and model spend on Casama's key. */
export async function yesterdayLoad(db: Database, now = Date.now()) {
  const today = Date.parse(`${utcDay(now)}T00:00:00Z`);
  const from = new Date(today - 86_400_000).toISOString();
  const to = new Date(today).toISOString();
  // The same samples Admin's capacity card draws (D-252).
  const [peak] = await db.execute<{ mb: number | null; n: number | null }>(sql`
    select max(computers_mem_mb)::int as mb, max(computers_running)::int as n
    from public.capacity_samples where at >= ${from}::timestamptz and at < ${to}::timestamptz`);
  // What OpenRouter charged Casama's key, which its daily cap counts. A model call's two rows
  // (tokens in, tokens out) both carry the call's whole `provider_cost_usd` in meta, so those use
  // their split upstream cost, less OpenRouter's credit fee (D-395); other rows (voice) have one row
  // per call.
  const [spend] = await db.execute<{ usd: string }>(sql`
    select coalesce(sum(case
      when kind in ('tokens_in', 'tokens_out') then coalesce(upstream_cost_usd, 0) / ${OPENROUTER_CREDIT_FEE}
      when jsonb_typeof(meta -> 'provider_cost_usd') = 'number' then (meta ->> 'provider_cost_usd')::numeric
      else 0 end), 0)::text as usd
    from public.usage_ledger
    where created_at >= ${from}::timestamptz and created_at < ${to}::timestamptz
      and meta ->> 'key' = 'server'
      and coalesce(meta ->> 'provider', 'openrouter') = 'openrouter'`);
  return {
    peakComputersMb: peak?.mb ?? null,
    peakComputers: peak?.n ?? null,
    spendUsd: Number(spend?.usd ?? 0),
  };
}

export interface BatchResult {
  day: string;
  admitted: number;
  skipped: "capacity" | "model_spend" | "no_mail" | "nobody_waiting" | "error" | null;
  detail: string | null;
}

const gbText = (mb: number) => `${(mb / 1024).toFixed(1)} GB`;
const usdText = (n: number) => `$${n.toFixed(2)}`;

/**
 * Once a day, from the gate's hour (UTC), chooses `min(daily_admit, mail left today)` people in
 * batch order for "You're in" emails, the same way an owner's batch does (`admitted_via` auto). It
 * skips the day, and pushes the owners why, when yesterday was too busy for more people. The day's
 * row in public.waitlist_batches is claimed first, so two workers can't both run it. Returns null
 * when nothing was due.
 */
export async function runDailyBatch(opts: {
  db: Database;
  /** Memory hosted computers may use (COMPUTER_HOST_MEMORY_GB); 0: no capacity check. */
  budgetMb: number;
  /** OpenRouter's daily cap on Casama's key, in US dollars. */
  openRouterDailyCapUsd: number;
  notifications?: Pick<NotificationService, "notify">;
  adminEmails?: string;
  now?: number;
  log?: Log;
}): Promise<BatchResult | null> {
  const { db } = opts;
  const now = opts.now ?? Date.now();
  const gate = await getSignupGate(db);
  if (!gateClosed(gate, now) || gate.daily_admit <= 0) return null;
  if (new Date(now).getUTCHours() < gate.batch_hour_utc) return null;
  const day = utcDay(now);
  const claimed = await db.execute<{ day: string }>(sql`
    insert into public.waitlist_batches (day) values (${day}::date)
    on conflict (day) do nothing returning day`);
  if (!claimed.length) return null;
  const finish = async (r: BatchResult) => {
    await db.execute(sql`
      update public.waitlist_batches
        set admitted = ${r.admitted}, skipped_reason = ${r.skipped}, detail = ${r.detail}, ran_at = now()
      where day = ${day}::date`);
    return r;
  };
  try {
    const load = await yesterdayLoad(db, now);
    let skipped: BatchResult["skipped"] = null;
    let detail: string | null = null;
    if (
      opts.budgetMb > 0 &&
      load.peakComputersMb != null &&
      load.peakComputersMb >= opts.budgetMb * BATCH_PAUSE_COMPUTERS_SHARE
    ) {
      skipped = "capacity";
      detail = `Yesterday's busiest moment had ${load.peakComputers ?? 0} computers running, using ${gbText(load.peakComputersMb)} of the ${gbText(opts.budgetMb)} set aside for computers (the batch pauses at ${Math.round(BATCH_PAUSE_COMPUTERS_SHARE * 100)}%).`;
    } else if (
      opts.openRouterDailyCapUsd > 0 &&
      load.spendUsd > opts.openRouterDailyCapUsd * BATCH_PAUSE_SPEND_SHARE
    ) {
      skipped = "model_spend";
      detail = `Yesterday's model spend on Casama's key was ${usdText(load.spendUsd)}, over ${Math.round(BATCH_PAUSE_SPEND_SHARE * 100)}% of the ${usdText(opts.openRouterDailyCapUsd)} daily cap.`;
    }
    if (skipped) {
      const r = await finish({ day, admitted: 0, skipped, detail });
      opts.log?.("waitlist: daily batch skipped", { day, reason: skipped });
      try {
        const owners = await instanceOwners(db, opts.adminEmails);
        for (const o of owners)
          await opts.notifications?.notify(o.id, null, "server_capacity", {
            title: "Today's waitlist batch was skipped",
            body: `${detail} Nobody was let in automatically today. You can still let people in by hand in Admin > Waitlist.`,
            link: "/settings/admin",
          });
      } catch (err) {
        opts.log?.("waitlist batch push failed", { error: (err as Error).message });
      }
      return r;
    }
    // Mail left today: the day's number, less what went out and who is already chosen.
    const [mail] = await db.execute<{ sent: number; queued: number }>(sql`
      select count(*) filter (where w.notified_at >= ${UTC_MIDNIGHT})::int as sent,
        count(*) filter (where w.status = 'waiting' and w.queued_at is not null)::int as queued
      from public.waitlist_entries w`);
    const left = Math.max(0, gate.daily_emails_max - (mail?.sent ?? 0) - (mail?.queued ?? 0));
    const count = Math.min(gate.daily_admit, left);
    if (count <= 0)
      return await finish({
        day,
        admitted: 0,
        skipped: "no_mail",
        detail: `No "You're in" emails left today (${gate.daily_emails_max} a day).`,
      });
    const chosen = await queueWaitlist(db, { count, via: "auto" });
    opts.log?.("waitlist: daily batch chose people", { day, count: chosen });
    return await finish({
      day,
      admitted: chosen,
      skipped: chosen ? null : "nobody_waiting",
      detail: chosen ? null : "Nobody was waiting.",
    });
  } catch (err) {
    opts.log?.("waitlist daily batch failed", { day, error: (err as Error).message });
    return await finish({
      day,
      admitted: 0,
      skipped: "error",
      detail: String((err as Error).message ?? err).slice(0, 500),
    });
  }
}

/**
 * Ties people who were let in to the account they made, attaches a friend's referral, and applies
 * a yes to the monthly email they gave on the waitlist form (their address is verified by now, so
 * no confirmation email is needed, D-408). Returns how many accounts were tied.
 */
export async function linkWaitlistSignups(opts: {
  db: Database;
  referrals: boolean;
  newsletter?: NewsletterConfig | null;
  log?: Log;
}): Promise<number> {
  const rows = await opts.db.execute<{
    entry_id: string;
    user_id: string;
    newsletter: boolean;
    referral_attached: boolean;
  }>(sql`select * from public.worker_waitlist_link(${opts.referrals}, 100)`);
  for (const r of rows) {
    if (!r.newsletter || !opts.newsletter) continue;
    try {
      // A choice made in the app since then stands.
      const state = await newsletterState(opts.db, r.user_id);
      if (!state.asked)
        await setNewsletterChoice(
          opts.db,
          opts.newsletter,
          r.user_id,
          { subscribed: true, via: "signup" },
          opts.log,
        );
    } catch (err) {
      opts.log?.("waitlist newsletter choice failed", {
        user_id: r.user_id,
        error: (err as Error).message,
      });
    }
  }
  return rows.length;
}

/**
 * The worker's loop: the daily batch, emails and sign-ups every minute, tidying every hour.
 * Returns a stopper.
 */
export function startWaitlist(opts: {
  db: Database;
  email?: EmailSender;
  env: Pick<Env, "PUBLIC_APP_URL" | "PUBLIC_OPEN_URL" | "WAITLIST_URL">;
  secret: string;
  referrals: boolean;
  newsletter?: NewsletterConfig | null;
  /** The daily batch's pause rules and who hears about a skipped day. */
  budgetMb?: number;
  openRouterDailyCapUsd?: number;
  notifications?: Pick<NotificationService, "notify">;
  adminEmails?: string;
  log?: Log;
}): () => Promise<void> {
  let tidiedAt = 0;
  let busy = false;
  const tick = async () => {
    if (busy) return;
    busy = true;
    try {
      await runDailyBatch({
        db: opts.db,
        budgetMb: opts.budgetMb ?? 0,
        openRouterDailyCapUsd: opts.openRouterDailyCapUsd ?? 0,
        notifications: opts.notifications,
        adminEmails: opts.adminEmails,
        log: opts.log,
      });
      const sent = await sendWaitlistInvites(opts);
      if (sent) opts.log?.("waitlist: people let in", { count: sent });
      const linked = await linkWaitlistSignups(opts);
      if (linked) opts.log?.("waitlist: sign-ups tied to entries", { count: linked });
      if (Date.now() - tidiedAt > 3_600_000) {
        tidiedAt = Date.now();
        await opts.db.execute(sql`
          update public.waitlist_entries set ip_hash = null
          where ip_hash is not null and created_at < now() - interval '30 days'`);
      }
    } catch (err) {
      opts.log?.("waitlist loop failed", { error: (err as Error).message });
    } finally {
      busy = false;
    }
  };
  const timer = setInterval(tick, 60_000);
  timer.unref?.();
  void tick();
  return async () => clearInterval(timer);
}
