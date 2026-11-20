/**
 * Claiming a hosted address, shared by the API and the mail.claim tool (BOT-EMAIL-PLAN §4.2):
 * one channels row of kind email plus one mail_addresses row, the claimant's account email on
 * the allowed list, a welcome mail, and the analytics event.
 */
import { type Database, withUserSession } from "@casama/db";
import { mailNameIssue, pgTextArray } from "@casama/domain";
import { sql } from "drizzle-orm";
import { track } from "../analytics.ts";
import { baseSubject } from "./adapters.ts";
import type { HostedMailSender } from "./hosted-mail.ts";
import { loadChannel, sendThrough } from "./service.ts";

export type ClaimMailErrorCode =
  | "invalid_name"
  | "plan_limit"
  | "address_exists"
  | "name_taken"
  | "forbidden";

export class ClaimMailError extends Error {
  readonly code: ClaimMailErrorCode;
  readonly status: 400 | 402 | 403 | 409;
  constructor(code: ClaimMailErrorCode, message: string) {
    super(message);
    this.code = code;
    this.status =
      code === "plan_limit"
        ? 402
        : code === "forbidden"
          ? 403
          : code === "invalid_name"
            ? 400
            : 409;
  }
}

export interface ClaimMailDeps {
  db: Database;
  domain: string;
  sender: HostedMailSender;
  sendPaused: boolean;
  fetch: typeof fetch;
  logger?: { warn(message: string, details?: Record<string, unknown>): void };
  /** Names the instance owner reserved on top of the built-in list. */
  extraReserved?: readonly string[];
}

export interface ClaimedMailAddress {
  id: string;
  bot_id: string;
  channel_id: string;
  local_part: string;
  status: "active" | "paused" | "retired";
  created_at: string;
  address: string;
}

/** Replacements a workspace may claim in 365 days on top of its plan's addresses. */
export const CLAIM_REPLACEMENTS_PER_YEAR = 3;

let reservedCache: { at: number; names: string[] } | null = null;

/**
 * Names the instance owner reserved on top of the built-in list (BOT-EMAIL-PLAN §4.1), cached
 * for a minute because claims read it. Each process caches its own copy.
 */
export async function loadExtraReservedNames(db: Database): Promise<string[]> {
  if (reservedCache && Date.now() - reservedCache.at < 60_000) return reservedCache.names;
  const [r] = await db.execute<{ value: unknown }>(
    sql`select value from public.instance_settings where key = 'mail_reserved_names'`,
  );
  const raw = (r?.value as { names?: unknown } | null | undefined)?.names;
  const names = Array.isArray(raw) ? raw.filter((n): n is string => typeof n === "string") : [];
  reservedCache = { at: Date.now(), names };
  return names;
}

export function resetExtraReservedNamesCache() {
  reservedCache = null;
}

/** Whether this person may claim for the bot (anyone who manages it, BOT-EMAIL-PLAN §13 Q8). */
export async function mailClaimAllowed(
  db: Database,
  botId: string,
  userId: string,
): Promise<boolean> {
  const [r] = await withUserSession(db, { sub: userId, role: "authenticated" }, (tx) =>
    tx.execute<{ manage: boolean }>(sql`select public.can_manage_bot(${botId}::uuid) as manage`),
  );
  return r?.manage === true;
}

export async function claimBotMailAddress(
  deps: ClaimMailDeps,
  o: {
    orgId: string;
    botId: string;
    botName: string;
    name: string;
    /** Whose account email goes on the allowed list, and who the welcome goes to. */
    claimerUserId: string | null;
    manage: boolean;
    surface: string;
    /** The claimer runs this instance: reserved names are theirs to claim. */
    instanceOwner?: boolean;
  },
): Promise<ClaimedMailAddress> {
  const { db } = deps;
  const name = o.name.trim().toLowerCase();
  const issue = mailNameIssue(name, deps.extraReserved ?? [], { instanceOwner: o.instanceOwner });
  if (issue) throw new ClaimMailError("invalid_name", issue);
  if (!o.manage)
    throw new ClaimMailError("forbidden", "Only people who manage this bot can claim its address");
  const [owner] = o.claimerUserId
    ? await db.execute<{ email: string | null }>(
        sql`select email from auth.users where id = ${o.claimerUserId}::uuid`,
      )
    : [];
  const address = `${name}@${deps.domain}`;
  let row: Omit<ClaimedMailAddress, "address">;
  try {
    row = await db.transaction(async (tx) => {
      // Serialize claims and releases per workspace so parallel claims or archive+claim cycles
      // can't bypass plan limits, the claims-a-year cap, or an automatic abuse pause.
      await tx.execute(sql`select pg_advisory_xact_lock(hashtext(${`mail_address:${o.orgId}`}))`);
      const [autoPaused] = await tx.execute<{ id: string }>(sql`
        select id from public.mail_addresses
        where org_id = ${o.orgId}::uuid and auto_paused_at is not null limit 1`);
      if (autoPaused)
        throw new ClaimMailError(
          "forbidden",
          "An address in this workspace was paused automatically. Ask the instance owner to review it in Admin before claiming a new one.",
        );
      const [e] = await tx.execute<{ plan_code: string; limits: Record<string, unknown> }>(
        sql`select plan_code, limits from public.entitlements where org_id = ${o.orgId}::uuid order by created_at desc limit 1`,
      );
      const max = e?.limits?.max_mail_addresses;
      if (e?.plan_code !== "selfhost") {
        if (typeof max !== "number" || max <= 0) {
          throw new ClaimMailError(
            "plan_limit",
            "Your plan doesn't include bot email addresses. Upgrade to add one.",
          );
        }
        const [n] = await tx.execute<{ live: number; year: number }>(sql`
          select count(*) filter (where status in ('active', 'paused'))::int as live,
                 count(*) filter (where created_at > now() - interval '365 days')::int as year
          from public.mail_addresses where org_id = ${o.orgId}::uuid`);
        if ((n?.live ?? 0) >= max) {
          track(db, {
            event: "limit_reached",
            userId: o.claimerUserId,
            orgId: o.orgId,
            properties: { kind: "max_mail_addresses", surface: "bot" },
          });
          throw new ClaimMailError(
            "plan_limit",
            `Your plan allows ${max} bot ${max === 1 ? "address" : "addresses"}. Upgrade to add more.`,
          );
        }
        // Releasing (or archiving a bot) always works; what's capped is claiming, so nobody
        // cycles through names: the plan's addresses plus 3 replacements in any 365 days.
        if ((n?.year ?? 0) >= max + CLAIM_REPLACEMENTS_PER_YEAR)
          throw new ClaimMailError(
            "plan_limit",
            `This workspace claimed ${n?.year ?? 0} addresses in the last year, the most it can. A new one can be claimed when the oldest of them is a year old.`,
          );
      }
      const [mine] = await tx.execute<{ id: string }>(sql`
        select id from public.mail_addresses where bot_id = ${o.botId}::uuid and status in ('active', 'paused')`);
      if (mine) throw new ClaimMailError("address_exists", "This bot already has an address");
      const [taken] = await tx.execute<{ id: string }>(
        sql`select id from public.mail_addresses where local_part = ${name}`,
      );
      if (taken) throw new ClaimMailError("name_taken", "That name is taken. Pick another.");
      const [ch] = await tx.execute<{ id: string }>(sql`
        insert into public.channels (org_id, bot_id, kind, name, config, allowed_senders, created_by)
        values (${o.orgId}::uuid, ${o.botId}::uuid, 'email', 'Email',
                ${JSON.stringify({ hosted: true, address })}::jsonb,
                ${owner?.email ? pgTextArray([owner.email.toLowerCase()]) : "{}"}::text[],
                ${o.claimerUserId}::uuid)
        returning id`);
      const [a] = await tx.execute<Omit<ClaimedMailAddress, "address">>(sql`
        insert into public.mail_addresses (local_part, org_id, bot_id, channel_id, created_by)
        values (${name}, ${o.orgId}::uuid, ${o.botId}::uuid, ${ch?.id}::uuid, ${o.claimerUserId}::uuid)
        returning id, bot_id, channel_id, local_part, status, created_at`);
      return a as Omit<ClaimedMailAddress, "address">;
    });
  } catch (err) {
    // Lost a race: the name went (unique name) or the bot got one (live-bot index).
    if ((err as { code?: string }).code === "23505") {
      if ((err as { constraint?: string }).constraint === "mail_addresses_live_bot_idx")
        throw new ClaimMailError("address_exists", "This bot already has an address");
      throw new ClaimMailError("name_taken", "That name was just taken. Pick another.");
    }
    throw err;
  }
  track(db, {
    event: "bot_email_claimed",
    userId: o.claimerUserId,
    orgId: o.orgId,
    properties: { surface: o.surface },
  });
  // The first mail, from the new address to the owner: it lands in their mail app, where
  // replying and forwarding start. Best effort: a failed welcome must not fail the claim.
  if (!deps.sendPaused && owner?.email) {
    const subject = `Meet ${o.botName}, by email`;
    const ch = await loadChannel(db, row.channel_id);
    if (ch)
      await sendThrough(
        db,
        ch,
        { to: owner.email.toLowerCase(), subject },
        [
          `I'm ${o.botName}, your AI assistant, writing from my own new address: ${address}.`,
          "",
          "Reply to this mail, or forward me anything — a bill, a booking, a newsletter — and I'll read it and answer here.",
          "",
          `— ${o.botName}`,
        ].join("\n"),
        deps.fetch,
        `${owner.email.toLowerCase()}|${baseSubject(subject).toLowerCase()}`,
        undefined,
        undefined,
        deps.sender,
      ).catch((err: Error) => deps.logger?.warn("welcome mail failed", { error: err.message }));
  }
  return { ...row, address };
}
