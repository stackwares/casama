/**
 * Account emails (D-302): what Casama tells people by email about their plan and their first days.
 *
 * Billing changes (BillingService.applySnapshot) and an hourly sweep queue rows in
 * public.email_outbox; the worker sends them every minute. The outbox's dedupe key makes a retried
 * webhook, a re-fetched snapshot or a repeated sweep a no-op, and sending never holds up a webhook.
 *
 * Two classes:
 * - account emails (billing): always sent to the workspace's owners and admins;
 * - tips and news (welcome series): to the person, only while profiles.email_tips is on, only
 *   when EMAIL_POSTAL_ADDRESS is set, and with a one-click unsubscribe link.
 */
import { LOW_CREDIT_USD } from "@casama/agent";
import type { Database } from "@casama/db";
import {
  checkEmailCopy,
  EDITABLE_EMAIL_KINDS,
  type EditableEmailKind,
  type EmailCopySettings,
} from "@casama/domain";
import { sql } from "drizzle-orm";
import { emailLinkSecret, unsubscribeToken } from "../api/routes/moderation.ts";
import { appLink, type Env } from "../env.ts";
import type { EmailSender } from "./email.ts";
import { type BrandedEmail, renderEmailHtml, renderEmailText } from "./email-layout.ts";

export type AccountEmailKind =
  | "trial_started"
  | "trial_ending"
  | "plan_started"
  | "payment_failed"
  | "cancel_scheduled"
  | "expired"
  | "refunded"
  | "credits_low"
  | "credits_out"
  | "yearly_renewal"
  | "welcome"
  | "first_bot_nudge"
  | "week_one_tips"
  | "come_back"
  | "gallery_digest"
  // Domains (D-329): required notices, sent to owners and admins whatever their email settings.
  | "domain_needs_dns"
  | "domain_disconnected"
  | "domain_paused"
  | "domain_registered"
  | "domain_order_failed"
  | "domain_renewal"
  | "domain_renewed"
  | "domain_renewal_failed"
  | "domain_expired"
  | "domain_verify_email"
  | "domain_transfer_code"
  | "domain_released";

/** Monthly gallery picks (D-315): opt-in (profiles.gallery_digest), with its own unsubscribe. */
export const GALLERY_KINDS: AccountEmailKind[] = ["gallery_digest"];

/** The welcome series: opt-out, and only with a postal address in the footer. */
export const TIPS_KINDS: AccountEmailKind[] = [
  "welcome",
  "first_bot_nudge",
  "week_one_tips",
  "come_back",
];

export interface AccountEmailData {
  plan?: string;
  /** ISO date the trial, period or plan ends. */
  until?: string | null;
  /** app_store, google_play or dodo. */
  source?: string;
  balance?: number;
  price?: string | null;
  name?: string | null;
  /** Domain emails: the domain or host, and the domain's id for the link. */
  domain_name?: string;
  domain_id?: string;
  /** domain_order_failed: why, in words. */
  reason?: string;
  /** domain_renewal: whether the saved payment method will be charged; domain_expired: the last
   * day it can be renewed at the normal price. */
  auto?: boolean;
  last_day?: string | null;
  /** Rows queued with no workspace or person (a released domain's registrant): the address. */
  to?: string;
  /** gallery_digest: the items picked for this person. */
  items?: { type: string; id: string; name: string; description: string }[];
}

/** Queues an email; a second call with the same dedupe key does nothing. */
export async function queueAccountEmail(
  db: Database,
  e: {
    kind: AccountEmailKind;
    orgId?: string | null;
    userId?: string | null;
    dedupeKey: string;
    data?: AccountEmailData;
  },
) {
  await db.execute(sql`
    insert into public.email_outbox (kind, org_id, user_id, dedupe_key, data)
    values (${e.kind}, ${e.orgId ?? null}::uuid, ${e.userId ?? null}::uuid, ${e.dedupeKey}, ${JSON.stringify(e.data ?? {})}::jsonb)
    on conflict (dedupe_key) do nothing`);
}

const day = (iso?: string | null) =>
  iso
    ? new Date(iso).toLocaleDateString("en-US", {
        month: "long",
        day: "numeric",
        year: "numeric",
        timeZone: "UTC",
      })
    : "the end of the period";

/** Where to manage a subscription, said the way each store says it. */
function manageWhere(source?: string): string {
  if (source === "app_store")
    return "On iPhone or iPad: Settings > your name > Subscriptions > Casama. On a Mac: App Store > your name > Subscriptions.";
  if (source === "google_play")
    return "On Android: Play Store > your profile > Payments & subscriptions > Subscriptions > Casama.";
  return "In Casama: Settings > Billing > Manage subscription.";
}

const domainUrl = (home: string, id?: string) =>
  id ? `${home}/settings/domains/${id}` : `${home}/settings/domains`;

// ---------------------------------------------------------------- editable copy (D-372)

const COPY_KEY = "email_copy";
const COPY_TTL_MS = 60_000;
let copyCache: { at: number; value: EmailCopySettings } | null = null;

/** The owner's words for the welcome series and gallery digest; empty when none are saved. */
export async function getEmailCopy(db: Database): Promise<EmailCopySettings> {
  if (copyCache && Date.now() - copyCache.at < COPY_TTL_MS) return copyCache.value;
  const [row] = await db.execute<{ value: unknown }>(
    sql`select value from public.instance_settings where key = ${COPY_KEY}`,
  );
  // A stored value that no longer passes counts as empty: the text in code is used.
  const value = row?.value ? (checkEmailCopy(row.value).copy ?? {}) : {};
  copyCache = { at: Date.now(), value };
  return value;
}

export async function setEmailCopy(db: Database, value: EmailCopySettings) {
  await db.execute(sql`
    insert into public.instance_settings (key, value, updated_at)
    values (${COPY_KEY}, ${JSON.stringify(value)}::jsonb, now())
    on conflict (key) do update set value = excluded.value, updated_at = now()`);
  copyCache = { at: Date.now(), value };
  return value;
}

export function resetEmailCopyCache() {
  copyCache = null;
}

/** The text in code for each editable email, in the setting's shape, for Admin to start from. */
export function defaultEmailCopy(): EmailCopySettings {
  const out: EmailCopySettings = {};
  for (const kind of EDITABLE_EMAIL_KINDS) {
    const { subject, email } = baseContent(kind, {}, "https://app.example");
    // The greeting ("Hi,") stays in code; a digest's item lines are filled in when it's sent.
    const intro = email.intro.slice(1);
    out[kind] = {
      subject,
      preheader:
        kind === "gallery_digest" ? "{count} new things that fit what you use." : email.preheader,
      title: email.title,
      intro: kind === "gallery_digest" ? intro.slice(0, 1) : intro,
      ...(email.button ? { button: email.button.label } : {}),
    };
  }
  return out;
}

/**
 * The subject and body of each kind. Plain, short, and one clear next step. `appUrl` is where app
 * links start: `appLink(env)`, so they open the installed app where there is one (D-326). The
 * welcome series and the gallery digest take the owner's words from `copy` where it has them.
 */
export function accountEmailContent(
  kind: AccountEmailKind,
  d: AccountEmailData,
  appUrl: string,
  copy: EmailCopySettings = {},
): { subject: string; email: BrandedEmail } {
  const base = baseContent(kind, d, appUrl);
  const own = (EDITABLE_EMAIL_KINDS as readonly string[]).includes(kind)
    ? copy[kind as EditableEmailKind]
    : undefined;
  if (!own) return base;
  const count = String(d.items?.length ?? 0);
  const [hi = "Hi,", ...rest] = base.email.intro;
  // A digest's item lines follow its first paragraph and stay generated.
  const generated = kind === "gallery_digest" ? rest.slice(1) : [];
  return {
    subject: (own.subject ?? base.subject).replaceAll("{count}", count),
    email: {
      ...base.email,
      ...(own.preheader ? { preheader: own.preheader.replaceAll("{count}", count) } : {}),
      ...(own.title ? { title: own.title } : {}),
      intro: own.intro ? [hi, ...own.intro, ...generated] : base.email.intro,
      ...(own.button && base.email.button
        ? { button: { ...base.email.button, label: own.button } }
        : {}),
    },
  };
}

function baseContent(
  kind: AccountEmailKind,
  d: AccountEmailData,
  appUrl: string,
): { subject: string; email: BrandedEmail } {
  const billing = `${appUrl.replace(/\/$/, "")}/settings/billing`;
  const home = appUrl.replace(/\/$/, "");
  const hi = d.name ? `Hi ${d.name},` : "Hi,";
  const plan = d.plan ?? "your plan";
  switch (kind) {
    case "gallery_digest": {
      const items = d.items ?? [];
      return {
        subject: "New in the Casama gallery for you",
        email: {
          mascot: "starry",
          preheader: `${items.length} new ${items.length === 1 ? "thing" : "things"} that fit what you use.`,
          title: "New for you in the gallery",
          intro: [
            hi,
            "A few things added this month that fit the apps you've connected and what you've added before:",
            ...items.map(
              (i) =>
                `${i.name}${i.description ? `: ${i.description}` : ""} (https://gallery.casama.ai/i/${i.type}/${i.id}/)`,
            ),
          ],
          button: { label: "Open the gallery", url: `${home}/settings/gallery` },
        },
      };
    }
    case "trial_started":
      return {
        subject: `Your ${plan} trial has started`,
        email: {
          mascot: "starry",
          preheader: `Free until ${day(d.until)}.`,
          title: `Your ${plan} trial has started`,
          intro: [
            hi,
            `Everything in ${plan} is yours until ${day(d.until)}. After that it renews as a paid plan unless you cancel before then.`,
            `To cancel: ${manageWhere(d.source)}`,
          ],
          button: { label: "Open Billing", url: billing },
        },
      };
    case "trial_ending":
      return {
        subject: `Your ${plan} trial ends on ${day(d.until)}`,
        email: {
          mascot: "thinker",
          preheader: "Keep it, or cancel before then: nothing to do if you're staying.",
          title: "Your trial ends soon",
          intro: [
            hi,
            `Your ${plan} trial ends on ${day(d.until)}. If you do nothing, it continues as a paid plan and you keep everything you've set up.`,
            `If you'd rather not continue, cancel before then. ${manageWhere(d.source)}`,
          ],
          button: { label: "Open Billing", url: billing },
        },
      };
    case "plan_started":
      return {
        subject: `Welcome to ${plan}`,
        email: {
          mascot: "lovey",
          preheader: "Your plan is active.",
          title: `Welcome to ${plan}`,
          intro: [
            hi,
            `Thanks for choosing ${plan}. It's active now${d.until ? ` and renews on ${day(d.until)}` : ""}, and this month's credits are in your workspace.`,
            d.source === "dodo"
              ? "Your receipt and invoice come separately from our payment provider."
              : "Your receipt comes from the store you bought it in.",
          ],
          button: { label: "See your plan", url: billing },
        },
      };
    case "payment_failed":
      return {
        subject: "Your Casama payment didn't go through",
        email: {
          mascot: "focused",
          preheader: "Update your payment method to keep your plan.",
          title: "Your payment didn't go through",
          intro: [
            hi,
            `We couldn't renew ${plan}. You still have it for now, but bots that use Casama's models stop when the grace period ends.`,
            `Update your payment method: ${manageWhere(d.source)}`,
          ],
          button: { label: "Open Billing", url: billing },
          note: "If you already fixed it, you can ignore this email.",
        },
      };
    case "cancel_scheduled":
      return {
        subject: `Your ${plan} plan ends on ${day(d.until)}`,
        email: {
          mascot: "sleepy",
          preheader: "You keep it until then.",
          title: "Your plan won't renew",
          intro: [
            hi,
            `${plan} stays active until ${day(d.until)}. After that your workspace moves to the Free plan: your bots, chats and files stay, with Free's limits.`,
            "Changed your mind? You can turn renewal back on any time before then.",
          ],
          button: { label: "Open Billing", url: billing },
        },
      };
    case "expired":
      return {
        subject: "You're on the Free plan now",
        email: {
          mascot: "sleepy",
          preheader: "Your bots and files are still here.",
          title: "You're on the Free plan now",
          intro: [
            hi,
            `${plan} has ended, so your workspace is on the Free plan. Nothing was deleted; bots beyond Free's limits are paused until you upgrade again.`,
          ],
          button: { label: "See plans", url: billing },
        },
      };
    case "refunded":
      return {
        subject: "Your refund went through",
        email: {
          mascot: "cool",
          preheader: `${plan} was refunded.`,
          title: "Your refund went through",
          intro: [
            hi,
            `${plan} was refunded, so it has ended and this month's credits from it were taken back. Your workspace is on the Free plan.`,
          ],
          button: { label: "Open Billing", url: billing },
        },
      };
    case "domain_needs_dns": {
      const name = d.domain_name ?? "your domain";
      return {
        subject: `Casama can't see the DNS records for ${name} yet`,
        email: {
          mascot: "thinker",
          preheader: "Check the records are added exactly as shown.",
          title: `Still waiting for ${name}`,
          intro: [
            hi,
            `A day ago you started connecting ${name} to a Casama site, and Casama still can't see its DNS records. Check they're added exactly as the domain's screen shows, at the company that runs the domain's DNS.`,
            "Some DNS companies take a few hours. Casama keeps checking by itself for a week.",
          ],
          button: { label: "Open the domain", url: domainUrl(home, d.domain_id) },
        },
      };
    }
    case "domain_disconnected": {
      const name = d.domain_name ?? "your domain";
      return {
        subject: `${name} no longer shows your site`,
        email: {
          mascot: "thinker",
          preheader: "Its DNS record has been missing for 7 days.",
          title: `${name} was disconnected`,
          intro: [
            hi,
            `The DNS record that connects ${name} to your Casama site has been missing for 7 days, so ${name} no longer shows your site. Your site still works at its own address.`,
            "Put the record back, then tap Check Again on the domain's screen.",
          ],
          button: { label: "Open the domain", url: domainUrl(home, d.domain_id) },
        },
      };
    }
    case "domain_paused": {
      const name = d.domain_name ?? "your domain";
      return {
        subject: `${name} is paused`,
        email: {
          mascot: "sleepy",
          preheader: "Your plan no longer includes it.",
          title: `${name} is paused`,
          intro: [
            hi,
            `Your plan no longer includes ${name}, so its visitors are sent to the site's own address. Nothing was deleted: upgrade and it comes back within the hour.`,
          ],
          button: { label: "Open Billing", url: billing },
        },
      };
    }
    case "domain_registered": {
      const name = d.domain_name ?? "your domain";
      return {
        subject: `${name} is yours`,
        email: {
          mascot: "starry",
          preheader: "Confirm the registrant email to keep it working.",
          title: `${name} is registered`,
          intro: [
            hi,
            `${name} is registered to you for one year${d.price ? `, for ${d.price} plus tax` : ""}. Casama set up its DNS, and your site goes live on it within a few minutes.`,
            `Within 15 days, open the email the registrar sends to the registrant's address and confirm it. Domain rules require this, and ${name} stops working until it's done.`,
          ],
          button: { label: "Open the domain", url: domainUrl(home, d.domain_id) },
          note: "Sales are final once a domain is registered. It renews each year at the price shown on the domain's screen.",
        },
      };
    }
    case "domain_order_failed": {
      const name = d.domain_name ?? "the domain";
      return {
        subject: `We couldn't register ${name}, and refunded you`,
        email: {
          mascot: "thinker",
          preheader: "The full amount is on its way back.",
          title: `${name} couldn't be registered`,
          intro: [
            hi,
            `Your payment went through, but ${name} couldn't be registered${d.reason ? `: ${d.reason}` : ""}. We refunded the full amount${d.price ? ` (${d.price})` : ""}; it reaches your card in a few days.`,
            "You can search for another name any time.",
          ],
          button: { label: "Find a domain", url: domainUrl(home) },
        },
      };
    }
    case "domain_renewal": {
      const name = d.domain_name ?? "your domain";
      return {
        subject: `${name} renews on ${day(d.until)}`,
        email: {
          mascot: "focused",
          preheader: d.auto ? "Nothing to do: it renews by itself." : "Renew it to keep it.",
          title: `${name} renews on ${day(d.until)}`,
          intro: [
            hi,
            d.auto
              ? `${name} renews on ${day(d.until)} for ${d.price ?? "its renewal price"} plus tax. Your saved payment method is charged about two weeks before.`
              : `${name} expires on ${day(d.until)}. Renewing it for a year costs ${d.price ?? "its renewal price"} plus tax. Renew it before then to keep the domain and your site on it.`,
          ],
          button: {
            label: d.auto ? "Open the domain" : "Renew now",
            url: domainUrl(home, d.domain_id),
          },
          note: "This is a required notice about a domain you own, so it's sent even when other emails are off.",
        },
      };
    }
    case "domain_renewed": {
      const name = d.domain_name ?? "your domain";
      return {
        subject: `${name} is renewed`,
        email: {
          mascot: "starry",
          preheader: `It's yours until ${day(d.until)}.`,
          title: `${name} is renewed`,
          intro: [
            hi,
            `${name} is renewed for a year${d.price ? `, for ${d.price} plus tax` : ""}. It's yours until ${day(d.until)}.`,
          ],
          button: { label: "Open the domain", url: domainUrl(home, d.domain_id) },
          note: "This is a required notice about a domain you own, so it's sent even when other emails are off.",
        },
      };
    }
    case "domain_renewal_failed": {
      const name = d.domain_name ?? "your domain";
      return {
        subject: `We couldn't renew ${name}`,
        email: {
          mascot: "thinker",
          preheader: "Renew it by hand to keep it.",
          title: `${name} wasn't renewed`,
          intro: [
            hi,
            `${d.reason ?? "The charge on your saved payment method didn't go through"}, so ${name} wasn't renewed. It expires on ${day(d.until)}.`,
            "Renew it now to keep the domain and your site on it. We'll also try the charge again in a few days.",
          ],
          button: { label: "Renew now", url: domainUrl(home, d.domain_id) },
          note: "This is a required notice about a domain you own, so it's sent even when other emails are off.",
        },
      };
    }
    case "domain_expired": {
      const name = d.domain_name ?? "your domain";
      return {
        subject: `${name} has expired`,
        email: {
          mascot: "thinker",
          preheader: "It can still be renewed at the normal price for a while.",
          title: `${name} has expired`,
          intro: [
            hi,
            `${name} expired and stopped working, and so did your site on it. You can still renew it at the normal price${d.price ? ` (${d.price} plus tax)` : ""} until ${day(d.last_day)}.`,
            "After that the registrar takes it back. Getting it back then costs a restore fee and isn't guaranteed.",
          ],
          button: { label: "Renew now", url: domainUrl(home, d.domain_id) },
          note: "This is a required notice about a domain you own, so it's sent even when other emails are off.",
        },
      };
    }
    case "domain_verify_email": {
      const name = d.domain_name ?? "your domain";
      return {
        subject: `Confirm the registrant email for ${name}`,
        email: {
          mascot: "focused",
          preheader: "Domain rules require it, or the domain stops working.",
          title: `Confirm the email for ${name}`,
          intro: [
            hi,
            `The registrar sent an email to the registrant's address for ${name}. Open it and confirm. Domain rules require this, and ${name} stops working 15 days after it was bought until it's done.`,
            "Can't find it? Send it again from the domain's screen.",
          ],
          button: { label: "Open the domain", url: domainUrl(home, d.domain_id) },
          note: "This is a required notice about a domain you own, so it's sent even when other emails are off.",
        },
      };
    }
    case "domain_transfer_code": {
      const name = d.domain_name ?? "your domain";
      return {
        subject: `A transfer code for ${name} was issued`,
        email: {
          mascot: "focused",
          preheader: "If this wasn't you, lock the domain again now.",
          title: `A transfer code for ${name} was issued`,
          intro: [
            hi,
            `Someone in your workspace unlocked ${name} and got its transfer code, to move it to another registrar.`,
            "If that wasn't you or someone you trust, open the domain, tap Lock Again, and change your password.",
          ],
          button: { label: "Open the domain", url: domainUrl(home, d.domain_id) },
          note: "This is a required notice about a domain you own, so it's sent even when other emails are off.",
        },
      };
    }
    case "domain_released":
      return {
        subject: `${d.domain_name ?? "Your domain"} stays yours until ${day(d.until)}`,
        email: {
          mascot: "shy",
          preheader: "Its Casama workspace was deleted.",
          title: "Your domain is still yours",
          intro: [
            "Hi,",
            `The Casama workspace that held ${d.domain_name ?? "your domain"} was deleted. The domain stays registered to you until ${day(d.until)}, but it won't renew and its site is offline.`,
            "To keep it, move it to another registrar before then: write to support@casama.ai from this address and we'll send you its transfer code.",
          ],
          note: "This is a required notice about a domain you own, so it's sent even when other emails are off.",
        },
      };
    case "credits_low":
      return {
        subject: "Your Casama credits are running low",
        email: {
          mascot: "thinker",
          preheader: `$${(d.balance ?? 0).toFixed(2)} left.`,
          title: "Credits are running low",
          intro: [
            hi,
            `Your workspace has $${(d.balance ?? 0).toFixed(2)} of credits left. Bots that use Casama's models stop when it runs out.`,
          ],
          button: { label: "Add credits", url: billing },
        },
      };
    case "credits_out":
      return {
        subject: "Your bots are paused: out of credits",
        email: {
          mascot: "sleepy",
          preheader: "Add credits to start them again.",
          title: "Your bots are paused",
          intro: [
            hi,
            "Your workspace ran out of credits, so bots that use Casama's models are paused. Add credits or upgrade to start them again.",
          ],
          button: { label: "Add credits", url: billing },
        },
      };
    case "yearly_renewal":
      return {
        subject: `Your yearly ${plan} plan renews on ${day(d.until)}`,
        email: {
          mascot: "thinker",
          preheader: d.price ? `${d.price} on ${day(d.until)}.` : `On ${day(d.until)}.`,
          title: "Your yearly plan renews soon",
          intro: [
            hi,
            `${plan} renews on ${day(d.until)}${d.price ? ` for ${d.price}` : ""}. Nothing to do if you're staying.`,
            `To cancel or change it: ${manageWhere(d.source)}`,
          ],
          button: { label: "Open Billing", url: billing },
        },
      };
    case "welcome":
      return {
        subject: "Welcome to Casama",
        email: {
          mascot: "lovey",
          preheader: "Three things to try first.",
          title: "Welcome to Casama",
          intro: [
            hi,
            "Casama gives you AI teammates that remember, use apps and their own computers, and work on a schedule. Three things to try first:",
            "1. Make a bot from a template. 2. Give it a routine, like a morning summary. 3. Connect an app it should work with.",
            "Stuck? Settings > Help & support has Casama Help, which answers right away.",
          ],
          button: { label: "Open Casama", url: home },
        },
      };
    case "first_bot_nudge":
      return {
        subject: "Your first bot in two minutes",
        email: {
          mascot: "giggly",
          preheader: "Pick a template and say hello.",
          title: "Your first bot in two minutes",
          intro: [
            hi,
            "The quickest start: pick a template (a research helper, an inbox assistant, a planner), give it a name, and ask it something. It learns how you like things as you go.",
          ],
          button: { label: "Make a bot", url: `${home}/bots` },
        },
      };
    case "week_one_tips":
      return {
        subject: "Three things people love in Casama",
        email: {
          mascot: "wow",
          preheader: "Routines, computers and voice.",
          title: "Three things to try this week",
          intro: [
            hi,
            "Routines: ask a bot to do something every morning, and it will.",
            "Computers: a bot can use its own computer to browse, fill in forms and make files, and you can watch.",
            "Voice: call your bot and talk it through.",
          ],
          button: { label: "Open Casama", url: home },
        },
      };
    case "come_back":
      return {
        subject: "Your bots are still here",
        email: {
          mascot: "winky",
          preheader: "Pick up where you left off.",
          title: "Your bots are still here",
          intro: [
            hi,
            "Your bots, their memory and your files are where you left them. Anything you'd like them to take off your plate this week?",
          ],
          button: { label: "Open Casama", url: home },
        },
      };
  }
}

type Pending = {
  id: string;
  kind: AccountEmailKind;
  org_id: string | null;
  user_id: string | null;
  data: AccountEmailData;
  attempts: number;
};

/** Sends what's waiting (at most `limit` per call). Returns how many went out. */
export async function sendAccountEmails(
  opts: {
    db: Database;
    email: EmailSender;
    env: Pick<
      Env,
      | "PUBLIC_APP_URL"
      | "PUBLIC_OPEN_URL"
      | "PUBLIC_API_URL"
      | "EMAIL_POSTAL_ADDRESS"
      | "SUPABASE_JWT_SECRET"
      | "ACCOUNT_EMAILS"
    >;
  },
  limit = 50,
): Promise<number> {
  const { db, email, env } = opts;
  const rows = await db.execute<Pending>(sql`
    select id, kind, org_id, user_id, data, attempts from public.email_outbox
    where sent_at is null and skipped is null and attempts < 5
    order by created_at limit ${limit}`);
  // The owner's words for the welcome series and digest (D-372), read once per batch.
  const copy = rows.length ? await getEmailCopy(db).catch(() => ({})) : {};
  let sent = 0;
  for (const r of rows) {
    const skip = async (why: string) =>
      db.execute(sql`update public.email_outbox set skipped = ${why} where id = ${r.id}::uuid`);
    if (!env.ACCOUNT_EMAILS || !email.enabled) {
      await skip("email off");
      continue;
    }
    const galleryList = GALLERY_KINDS.includes(r.kind);
    const tips = TIPS_KINDS.includes(r.kind) || galleryList;
    if (tips && !env.EMAIL_POSTAL_ADDRESS) {
      await skip("no postal address");
      continue;
    }
    // Billing emails: the workspace's owners and admins. Personal ones: that person. A row with
    // neither (a released domain's registrant): the address it names.
    type Person = { id: string; email: string; name: string | null; tips: boolean | null };
    const people: readonly Person[] =
      !r.user_id && !r.org_id
        ? r.data.to
          ? [{ id: "", email: r.data.to, name: null, tips: null }]
          : []
        : await db.execute<Person>(
            r.user_id
              ? sql`select u.id, u.email, p.display_name as name,
                ${galleryList ? sql`coalesce(p.gallery_digest, false)` : sql`p.email_tips`} as tips from auth.users u
              left join public.profiles p on p.user_id = u.id
              where u.id = ${r.user_id}::uuid and u.email is not null and u.email_confirmed_at is not null`
              : sql`select u.id, u.email, p.display_name as name, p.email_tips as tips from public.memberships m
              join auth.users u on u.id = m.user_id left join public.profiles p on p.user_id = u.id
              where m.org_id = ${r.org_id}::uuid and m.role in ('owner', 'admin')
                and u.email is not null and u.email_confirmed_at is not null`,
          );
    const to = tips ? people.filter((p) => p.tips !== false) : people;
    if (!to.length) {
      await skip(people.length ? "unsubscribed" : "no recipient");
      continue;
    }
    try {
      for (const p of to) {
        const { subject, email: content } = accountEmailContent(
          r.kind,
          { ...r.data, name: p.name },
          appLink(env),
          copy,
        );
        const unsubscribe = tips
          ? `${(env.PUBLIC_API_URL ?? env.PUBLIC_APP_URL).replace(/\/$/, "")}/v1/email/unsubscribe/${unsubscribeToken(emailLinkSecret(env as Env), p.id)}${galleryList ? "?list=gallery" : ""}`
          : undefined;
        const withFooter: BrandedEmail = unsubscribe
          ? {
              ...content,
              unsubscribe: { url: unsubscribe, address: env.EMAIL_POSTAL_ADDRESS ?? "" },
            }
          : content;
        await email.send({
          to: p.email,
          subject,
          text: renderEmailText(withFooter),
          html: renderEmailHtml(withFooter),
          ...(unsubscribe
            ? {
                headers: {
                  "List-Unsubscribe": `<${unsubscribe}>`,
                  "List-Unsubscribe-Post": "List-Unsubscribe=One-Click",
                },
              }
            : {}),
        });
      }
      await db.execute(
        sql`update public.email_outbox set sent_at = now(), attempts = attempts + 1 where id = ${r.id}::uuid`,
      );
      sent++;
    } catch (err) {
      await db.execute(sql`
        update public.email_outbox set attempts = attempts + 1, last_error = ${String((err as Error).message ?? err).slice(0, 500)}
        where id = ${r.id}::uuid`);
    }
  }
  return sent;
}

const isoWeek = (d: Date) => {
  const t = new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate()));
  t.setUTCDate(t.getUTCDate() + 4 - (t.getUTCDay() || 7));
  const y = new Date(Date.UTC(t.getUTCFullYear(), 0, 1));
  return `${t.getUTCFullYear()}-W${Math.ceil(((t.getTime() - y.getTime()) / 86_400_000 + 1) / 7)}`;
};

/**
 * The time-based emails (hourly): trials ending in 3 days, payments still failing after 3 days,
 * yearly web plans renewing in 7 days, credits low or gone, and the welcome series.
 */
export async function sweepAccountEmails(db: Database, opts: { billing: boolean; now?: Date }) {
  const now = opts.now ?? new Date();
  if (opts.billing) {
    const trials = await db.execute<{
      id: string;
      org_id: string;
      source: string;
      name: string;
      until: Date;
    }>(sql`
      select s.id, s.org_id, s.source, p.name, s.current_period_end as until
      from public.subscriptions s join public.plans p on p.code = s.plan_code
      where s.status = 'trialing' and s.cancel_at_period_end = false
        and s.current_period_end between ${now.toISOString()}::timestamptz and ${now.toISOString()}::timestamptz + interval '3 days'`);
    for (const t of trials)
      await queueAccountEmail(db, {
        kind: "trial_ending",
        orgId: t.org_id,
        dedupeKey: `trial_ending:${t.id}:${new Date(t.until).toISOString()}`,
        data: { plan: t.name, until: new Date(t.until).toISOString(), source: t.source },
      });
    const failing = await db.execute<{
      id: string;
      org_id: string;
      source: string;
      name: string;
      until: Date | null;
    }>(sql`
      select s.id, s.org_id, s.source, p.name, s.current_period_end as until
      from public.subscriptions s join public.plans p on p.code = s.plan_code
      where s.status in ('grace', 'past_due') and s.updated_at < ${now.toISOString()}::timestamptz - interval '3 days'`);
    for (const f of failing)
      await queueAccountEmail(db, {
        kind: "payment_failed",
        orgId: f.org_id,
        dedupeKey: `payment_failed_again:${f.id}:${f.until ? new Date(f.until).toISOString() : ""}`,
        data: { plan: f.name, source: f.source },
      });
    const yearly = await db.execute<{
      id: string;
      org_id: string;
      name: string;
      price: string | null;
      until: Date;
    }>(sql`
      select s.id, s.org_id, p.name, p.price_label as price, s.current_period_end as until
      from public.subscriptions s join public.plans p on p.code = s.plan_code
      where s.source = 'dodo' and p.interval = 'year' and s.status = 'active' and s.cancel_at_period_end = false
        and s.current_period_end between ${now.toISOString()}::timestamptz and ${now.toISOString()}::timestamptz + interval '7 days'`);
    for (const y of yearly)
      await queueAccountEmail(db, {
        kind: "yearly_renewal",
        orgId: y.org_id,
        dedupeKey: `yearly_renewal:${y.id}:${new Date(y.until).toISOString()}`,
        data: {
          plan: y.name,
          price: y.price,
          until: new Date(y.until).toISOString(),
          source: "dodo",
        },
      });
    // Credits: the latest balance per workspace that used paid models in the last day.
    const credits = await db.execute<{
      org_id: string;
      balance: string;
      last_topup: string | null;
    }>(sql`
      with bal as (
        select distinct on (l.org_id) l.org_id, l.balance_after as balance
        from public.credit_ledger l order by l.org_id, l.seq desc)
      select bal.org_id, bal.balance::text as balance,
             (select max(seq)::text from public.credit_ledger t where t.org_id = bal.org_id and t.delta > 0) as last_topup
      from bal
      where bal.balance < ${LOW_CREDIT_USD}
        and exists (select 1 from public.usage_ledger u where u.org_id = bal.org_id and u.billable
                    and u.created_at > ${now.toISOString()}::timestamptz - interval '1 day')`);
    for (const c of credits) {
      const balance = Number(c.balance);
      if (balance <= 0)
        await queueAccountEmail(db, {
          kind: "credits_out",
          orgId: c.org_id,
          // Once until credits are added again (a new top-up starts a new key).
          dedupeKey: `credits_out:${c.org_id}:${c.last_topup ?? "none"}`,
        });
      else
        await queueAccountEmail(db, {
          kind: "credits_low",
          orgId: c.org_id,
          dedupeKey: `credits_low:${c.org_id}:${isoWeek(now)}`,
          data: { balance },
        });
    }
  }
  // The welcome series. Only people who signed up recently, so turning this on never emails
  // everyone who signed up before.
  const fresh = await db.execute<{
    id: string;
    age_days: number;
    bots: number;
    msgs: number;
    recent: number;
  }>(sql`
    select u.id, extract(epoch from (${now.toISOString()}::timestamptz - u.created_at)) / 86400 as age_days,
           (select count(*)::int from public.bots b where b.created_by = u.id) as bots,
           (select count(*)::int from public.messages m where m.author_user_id = u.id) as msgs,
           (select count(*)::int from public.messages m where m.author_user_id = u.id
              and m.created_at > ${now.toISOString()}::timestamptz - interval '7 days') as recent
    from auth.users u
    where u.email_confirmed_at is not null
      and u.created_at > ${now.toISOString()}::timestamptz - interval '9 days'`);
  for (const f of fresh) {
    const age = Number(f.age_days);
    if (age < 2)
      await queueAccountEmail(db, { kind: "welcome", userId: f.id, dedupeKey: `welcome:${f.id}` });
    else if (age < 3 && (f.bots === 0 || f.msgs === 0))
      await queueAccountEmail(db, {
        kind: "first_bot_nudge",
        userId: f.id,
        dedupeKey: `first_bot_nudge:${f.id}`,
      });
    else if (age >= 7 && age < 9 && f.recent > 0)
      await queueAccountEmail(db, {
        kind: "week_one_tips",
        userId: f.id,
        dedupeKey: `week_one_tips:${f.id}`,
      });
  }
  // Quiet for two weeks after being active: one note a month at most.
  const quiet = await db.execute<{ id: string }>(sql`
    select m.author_user_id as id from public.messages m
    where m.author_user_id is not null
    group by m.author_user_id
    having count(*) >= 5
       and max(m.created_at) between ${now.toISOString()}::timestamptz - interval '15 days'
                                 and ${now.toISOString()}::timestamptz - interval '14 days'`);
  for (const q of quiet)
    await queueAccountEmail(db, {
      kind: "come_back",
      userId: q.id,
      dedupeKey: `come_back:${q.id}:${now.toISOString().slice(0, 7)}`,
    });
}

/** The worker's loop: send every minute, sweep every hour. Returns a stopper. */
export function startAccountEmails(opts: {
  db: Database;
  email: EmailSender;
  env: Env;
  billing: boolean;
  log?: (msg: string, extra?: Record<string, unknown>) => void;
}): () => Promise<void> {
  let sweptAt = 0;
  let busy = false;
  const tick = async () => {
    if (busy) return;
    busy = true;
    try {
      if (Date.now() - sweptAt > 3_600_000) {
        sweptAt = Date.now();
        await sweepAccountEmails(opts.db, { billing: opts.billing });
      }
      const n = await sendAccountEmails(opts);
      if (n) opts.log?.("account emails sent", { count: n });
    } catch (err) {
      opts.log?.("account emails failed", { error: (err as Error).message });
    } finally {
      busy = false;
    }
  };
  const timer = setInterval(tick, 60_000);
  timer.unref?.();
  void tick();
  return async () => clearInterval(timer);
}
