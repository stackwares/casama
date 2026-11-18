/**
 * Casama's monthly email from the app (D-408). The list is in Resend (D-404): segment "Casama
 * newsletter", topic "Casama updates", contact property signup_source. casama.ai's Worker signs
 * people up with double opt-in (site/newsletter.js); the app's switch needs no confirmation email,
 * because the person's sign-in address is already verified.
 *
 * public.newsletter_subscriptions keeps the person's choice and what Resend was last told. Every
 * change is saved first and sent to Resend after; a failed call leaves `sync_due` set and the
 * worker tries again every 15 minutes, so Resend being down never breaks a save, a sign-up or an
 * account deletion. Off means unsubscribed in Resend (the contact stays, so it stays off). An email
 * change moves the contact; a deleted account's contact is removed.
 *
 * Only on Casama Cloud: without NEWSLETTER_RESEND_API_KEY the app hides the switch and nothing here
 * calls Resend.
 */
import { createHmac, timingSafeEqual } from "node:crypto";
import type { Database } from "@casama/db";
import { sql } from "drizzle-orm";

export const RESEND_API = "https://api.resend.com";
/** What the contact record says about where the person signed up. */
export const APP_SIGNUP_SOURCE = "app";
/** After this many failed tries in a row the worker stops retrying a row (a change resets it). */
export const MAX_SYNC_TRIES = 50;

export interface NewsletterConfig {
  apiKey: string;
  segmentId: string;
  topicId: string;
  webhookSecret?: string;
  fetch?: typeof fetch;
  base?: string;
}

export interface NewsletterEnv {
  NEWSLETTER_RESEND_API_KEY?: string;
  NEWSLETTER_WEBHOOK_SECRET?: string;
  NEWSLETTER_SEGMENT_ID?: string;
  NEWSLETTER_TOPIC_ID?: string;
}

/** The newsletter settings, or null when this server doesn't offer it (every self-hosted one). */
export function newsletterConfig(
  env: NewsletterEnv,
  doFetch?: typeof fetch,
): NewsletterConfig | null {
  const apiKey = env.NEWSLETTER_RESEND_API_KEY?.trim();
  if (!apiKey) return null;
  return {
    apiKey,
    segmentId: env.NEWSLETTER_SEGMENT_ID || "bcf1b930-13c0-4bbc-a720-aa4cfd544e3c",
    topicId: env.NEWSLETTER_TOPIC_ID || "4b2d83b2-6f0a-4d6b-9981-de572951bf3c",
    webhookSecret: env.NEWSLETTER_WEBHOOK_SECRET?.trim() || undefined,
    fetch: doFetch,
  };
}

async function resend(cfg: NewsletterConfig, method: string, path: string, body?: unknown) {
  return (cfg.fetch ?? fetch)(`${cfg.base ?? RESEND_API}${path}`, {
    method,
    headers: { authorization: `Bearer ${cfg.apiKey}`, "content-type": "application/json" },
    body: body === undefined ? undefined : JSON.stringify(body),
    signal: AbortSignal.timeout(10_000),
  });
}

const contactPath = (email: string) => `/contacts/${encodeURIComponent(email)}`;

/**
 * Subscribes an address: creates the contact (or finds the one already there, say from casama.ai),
 * then makes sure it's subscribed, in the segment and opted in to the topic. The same calls as the
 * website's addContact (site/newsletter.js), each safe to repeat.
 */
export async function subscribeContact(cfg: NewsletterConfig, email: string): Promise<boolean> {
  const created = await resend(cfg, "POST", "/contacts", {
    email,
    unsubscribed: false,
    segments: [{ id: cfg.segmentId }],
    topics: [{ id: cfg.topicId, subscription: "opt_in" }],
    properties: { signup_source: APP_SIGNUP_SOURCE },
  });
  if (!created.ok) {
    // Already there, or the property was refused: make sure the contact exists without it.
    const plain = await resend(cfg, "POST", "/contacts", { email, unsubscribed: false });
    if (!plain.ok && plain.status !== 409 && plain.status !== 422) return false;
  }
  const steps = await Promise.all([
    resend(cfg, "PATCH", contactPath(email), { unsubscribed: false }),
    resend(cfg, "POST", `${contactPath(email)}/segments/${cfg.segmentId}`),
    resend(cfg, "PATCH", `${contactPath(email)}/topics`, [
      { id: cfg.topicId, subscription: "opt_in" },
    ]),
  ]);
  // Adding to a segment it's already in may answer with a conflict; that's still "in the segment".
  return steps.every((r) => r.ok || r.status === 409);
}

/** Marks an address unsubscribed. An address Resend doesn't know is as unsubscribed as it gets. */
export async function unsubscribeContact(cfg: NewsletterConfig, email: string): Promise<boolean> {
  const r = await resend(cfg, "PATCH", contactPath(email), { unsubscribed: true });
  return r.ok || r.status === 404;
}

/** Removes an address from Resend altogether (account deletion, a changed email). */
export async function deleteContact(cfg: NewsletterConfig, email: string): Promise<boolean> {
  const r = await resend(cfg, "DELETE", contactPath(email));
  return r.ok || r.status === 404;
}

export interface NewsletterState {
  subscribed: boolean;
  asked: boolean;
}

export async function newsletterState(db: Database, userId: string): Promise<NewsletterState> {
  const [r] = await db.execute<{ subscribed: boolean; asked: boolean }>(sql`
    select subscribed, asked_at is not null as asked
    from public.newsletter_subscriptions where user_id = ${userId}::uuid`);
  return { subscribed: r?.subscribed ?? false, asked: r?.asked ?? false };
}

export type ChangedVia = "settings" | "signup" | "card";

/**
 * Saves the person's choice (and that they were asked), then tells Resend. A Resend failure is
 * logged and retried later; the saved choice stands either way. `subscribed` left out: only marks
 * that the app asked (the card closed without an answer).
 */
export async function setNewsletterChoice(
  db: Database,
  cfg: NewsletterConfig,
  userId: string,
  choice: { subscribed?: boolean; via: ChangedVia },
  log?: (msg: string, extra?: Record<string, unknown>) => void,
): Promise<NewsletterState> {
  if (choice.subscribed === undefined) {
    await db.execute(sql`
      insert into public.newsletter_subscriptions (user_id, asked_at) values (${userId}::uuid, now())
      on conflict (user_id) do update set asked_at = coalesce(public.newsletter_subscriptions.asked_at, now())`);
    return newsletterState(db, userId);
  }
  await db.execute(sql`
    insert into public.newsletter_subscriptions (user_id, subscribed, changed_via, changed_at, asked_at, sync_due, version)
    values (${userId}::uuid, ${choice.subscribed}, ${choice.via}, now(), now(), true, 1)
    on conflict (user_id) do update set
      subscribed = excluded.subscribed,
      changed_via = excluded.changed_via,
      changed_at = now(),
      asked_at = coalesce(public.newsletter_subscriptions.asked_at, now()),
      sync_due = true,
      sync_tries = 0,
      version = public.newsletter_subscriptions.version + 1`);
  await syncNewsletter(db, cfg, userId, log);
  return newsletterState(db, userId);
}

/**
 * Brings Resend in line with one person's row: removes an old address (deleted account, changed
 * email), then subscribes or unsubscribes the current one. Needs a connection that can read
 * auth.users (the API's). Never throws; answers whether Resend now matches.
 */
export async function syncNewsletter(
  db: Database,
  cfg: NewsletterConfig,
  userId: string,
  log?: (msg: string, extra?: Record<string, unknown>) => void,
): Promise<boolean> {
  try {
    const [row] = await db.execute<{
      subscribed: boolean;
      resend_email: string | null;
      version: number;
      email: string | null;
      verified: boolean;
      deleting: boolean;
    }>(sql`
      select n.subscribed, n.resend_email, n.version,
        lower(u.email::text) as email,
        (u.email_confirmed_at is not null) as verified,
        exists (select 1 from public.account_deletions d where d.user_id = n.user_id and d.completed_at is null) as deleting
      from public.newsletter_subscriptions n
      left join auth.users u on u.id = n.user_id
      where n.user_id = ${userId}::uuid`);
    if (!row) return true;
    let held = row.resend_email;
    let ok = true;
    // A deleted account, or an address that's no longer theirs: that contact goes.
    if (held && (row.deleting || !row.email || held !== row.email)) {
      ok = await deleteContact(cfg, held);
      if (ok) held = null;
    }
    const wanted = row.subscribed && !row.deleting && !!row.email && row.verified;
    // Only a confirmed address is added; an unconfirmed one waits (and is retried) until it is.
    if (row.subscribed && !row.deleting && row.email && !row.verified) ok = false;
    if (ok && wanted && row.email) {
      ok = await subscribeContact(cfg, row.email);
      if (ok) held = row.email;
    } else if (ok && !wanted && held) {
      ok = await unsubscribeContact(cfg, held);
    }
    // What Resend holds is recorded whatever happened; the change counts as sent only when every
    // call worked and nothing newer came in meanwhile.
    await db.execute(sql`
      update public.newsletter_subscriptions set
        resend_email = ${held},
        sync_due = case when ${ok} and version = ${row.version} then false else true end,
        sync_tries = case when ${ok} then 0 else sync_tries + 1 end,
        synced_at = case when ${ok} then now() else synced_at end
      where user_id = ${userId}::uuid`);
    if (!ok) log?.("newsletter sync failed, will retry", { user_id: userId });
    return ok;
  } catch (err) {
    log?.("newsletter sync failed, will retry", {
      user_id: userId,
      error: (err as Error).message,
    });
    await db
      .execute(sql`
        update public.newsletter_subscriptions set sync_due = true, sync_tries = sync_tries + 1
        where user_id = ${userId}::uuid`)
      .catch(() => {});
    return false;
  }
}

/** Retries every row whose last sync failed (or that an email change or deletion marked). */
export async function syncDueNewsletters(
  db: Database,
  cfg: NewsletterConfig,
  log?: (msg: string, extra?: Record<string, unknown>) => void,
  limit = 100,
): Promise<number> {
  const due = await db.execute<{ user_id: string }>(sql`
    select user_id from public.newsletter_subscriptions
    where sync_due and sync_tries < ${MAX_SYNC_TRIES}
    order by synced_at nulls first limit ${limit}`);
  let synced = 0;
  for (const { user_id } of due) if (await syncNewsletter(db, cfg, user_id, log)) synced++;
  return synced;
}

/** The worker's loop: every 15 minutes, with the API's database connection (it reads auth.users). */
export function startNewsletterSync(opts: {
  db: Database;
  config: NewsletterConfig;
  log?: (msg: string, extra?: Record<string, unknown>) => void;
  everyMs?: number;
}): () => Promise<void> {
  let busy = false;
  const tick = async () => {
    if (busy) return;
    busy = true;
    try {
      const n = await syncDueNewsletters(opts.db, opts.config, opts.log);
      if (n) opts.log?.("newsletter changes sent to Resend", { count: n });
    } catch (err) {
      opts.log?.("newsletter sync sweep failed", { error: (err as Error).message });
    } finally {
      busy = false;
    }
  };
  const timer = setInterval(tick, opts.everyMs ?? 15 * 60_000);
  timer.unref?.();
  void tick();
  return async () => clearInterval(timer);
}

/**
 * Account deletion: the switch goes off and the contact is removed from Resend now, not after the
 * grace period. That's the address the app added, or else the sign-in address (they may have
 * signed up on casama.ai with it). A failure leaves the row due, and the worker keeps trying until
 * the purge.
 */
export async function newsletterOnAccountDeletion(
  db: Database,
  cfg: NewsletterConfig,
  userId: string,
  log?: (msg: string, extra?: Record<string, unknown>) => void,
): Promise<void> {
  const rows = await db.execute<{ user_id: string }>(sql`
    insert into public.newsletter_subscriptions (user_id, subscribed, resend_email, sync_due, version)
    select u.id, false, lower(u.email::text), true, 1
    from auth.users u where u.id = ${userId}::uuid and u.email is not null
    on conflict (user_id) do update set
      subscribed = false,
      changed_at = now(),
      resend_email = coalesce(public.newsletter_subscriptions.resend_email, excluded.resend_email),
      sync_due = true,
      sync_tries = 0,
      version = public.newsletter_subscriptions.version + 1
    returning user_id`);
  if (rows.length) await syncNewsletter(db, cfg, userId, log);
}

/**
 * The purge, last thing before the account's rows go: removes the address Resend still has. Reads
 * only newsletter_subscriptions, so the worker's own role can run it. Never throws.
 */
export async function forgetNewsletterContact(
  db: Database,
  cfg: NewsletterConfig | null,
  userId: string,
): Promise<boolean> {
  if (!cfg) return true;
  try {
    const [row] = await db.execute<{ resend_email: string | null }>(sql`
      select resend_email from public.newsletter_subscriptions where user_id = ${userId}::uuid`);
    if (!row?.resend_email) return true;
    return await deleteContact(cfg, row.resend_email);
  } catch {
    return false;
  }
}

// ---------------------------------------------------------------------------------------------
// Resend's webhook: someone unsubscribed from an email, so the app's switch goes off too.
// ---------------------------------------------------------------------------------------------

/** Svix signature (Resend's webhooks): HMAC-SHA256 over `id.timestamp.body`, key after `whsec_`. */
export function svixSignature(secret: string, id: string, ts: string, body: string) {
  const key = Buffer.from(secret.startsWith("whsec_") ? secret.slice(6) : secret, "base64");
  return createHmac("sha256", key).update(`${id}.${ts}.${body}`).digest("base64");
}

export function verifySvix(
  secret: string,
  headers: Headers,
  body: string,
  toleranceSeconds = 300,
  now = Date.now(),
): boolean {
  const id = headers.get("svix-id");
  const ts = headers.get("svix-timestamp");
  const sigs = headers.get("svix-signature");
  if (!id || !ts || !sigs) return false;
  const t = Number(ts);
  if (!Number.isFinite(t) || Math.abs(now / 1000 - t) > toleranceSeconds) return false;
  const expected = Buffer.from(svixSignature(secret, id, ts, body));
  return sigs.split(" ").some((s) => {
    const [version, sig] = s.split(",", 2);
    if (version !== "v1" || !sig) return false;
    const got = Buffer.from(sig);
    return got.length === expected.length && timingSafeEqual(got, expected);
  });
}

interface ResendEvent {
  type?: string;
  created_at?: string;
  data?: {
    email?: string;
    unsubscribed?: boolean;
    topics?: Array<{ id?: string; subscription?: string }>;
  };
}

/**
 * Turns the switch off for the person Resend names when they unsubscribed (contact.updated with
 * unsubscribed), opted out of the topic (contact.topics.updated), or the contact was deleted. An
 * event older than the person's last change in the app is ignored, so a late webhook can't undo
 * a newer "on". Answers how many rows changed.
 */
export async function applyResendEvent(
  db: Database,
  cfg: NewsletterConfig,
  event: ResendEvent,
): Promise<number> {
  const email = event.data?.email?.trim().toLowerCase();
  if (!email) return 0;
  const off =
    (event.type === "contact.updated" && event.data?.unsubscribed === true) ||
    event.type === "contact.deleted" ||
    (event.type === "contact.topics.updated" &&
      (event.data?.topics ?? []).some((t) => t.id === cfg.topicId && t.subscription === "opt_out"));
  if (!off) return 0;
  const at = event.created_at ? new Date(event.created_at) : new Date();
  const when = Number.isNaN(at.getTime()) ? new Date() : at;
  const rows = await db.execute<{ user_id: string }>(sql`
    update public.newsletter_subscriptions set
      subscribed = false,
      changed_via = 'email',
      changed_at = now(),
      version = version + 1,
      resend_email = case when ${event.type === "contact.deleted"} then null else resend_email end
    where lower(resend_email) = ${email}
      and (subscribed or ${event.type === "contact.deleted"})
      and changed_at < ${when.toISOString()}::timestamptz
    returning user_id`);
  return rows.length;
}
