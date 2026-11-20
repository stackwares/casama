import { CloudflareMailSender, type HostedMailSender, ResendMailSender } from "@casama/agent";
import { sql } from "drizzle-orm";
import type { Env } from "../env.ts";
import { noticeInstanceOwners } from "../sites/domains.ts";

export interface HostedMail {
  /** The domain bot addresses live on (`ada@<domain>`). */
  domain: string;
  /** Who sends hosted mail (Cloudflare, or Resend as the fallback). */
  sender: HostedMailSender;
  /** MAIL_SEND_PAUSED: nothing goes out while set. */
  sendPaused: boolean;
}

/**
 * Hosted bot mail from the server's settings (BOT-EMAIL-PLAN §9.3). Undefined without a mail
 * domain and a sender key: hosted addresses stay off on that server.
 */
export function hostedMailFromEnv(
  env: Pick<
    Env,
    | "MAIL_DOMAIN"
    | "MAIL_SENDER"
    | "MAIL_CF_ACCOUNT_ID"
    | "MAIL_CF_API_TOKEN"
    | "MAIL_CF_API_URL"
    | "MAIL_RESEND_API_KEY"
    | "MAIL_RESEND_API_URL"
    | "MAIL_SEND_PAUSED"
    | "MAIL_SEND_DAILY_MAX"
    | "INSTANCE_ADMIN_EMAILS"
  >,
): HostedMail | undefined {
  if (!env.MAIL_DOMAIN) return undefined;
  const sender: HostedMailSender | undefined =
    env.MAIL_SENDER === "resend"
      ? env.MAIL_RESEND_API_KEY
        ? new ResendMailSender({
            apiKey: env.MAIL_RESEND_API_KEY,
            apiBase: env.MAIL_RESEND_API_URL,
          })
        : undefined
      : env.MAIL_CF_ACCOUNT_ID && env.MAIL_CF_API_TOKEN
        ? new CloudflareMailSender({
            accountId: env.MAIL_CF_ACCOUNT_ID,
            apiToken: env.MAIL_CF_API_TOKEN,
            apiBase: env.MAIL_CF_API_URL,
          })
        : undefined;
  if (!sender) return undefined;
  const ceiling = env.MAIL_SEND_DAILY_MAX ?? (sender.name === "cloudflare" ? 900 : 0);
  return {
    domain: env.MAIL_DOMAIN,
    sender: withCeiling(sender, ceiling, env.INSTANCE_ADMIN_EMAILS),
    sendPaused: env.MAIL_SEND_PAUSED,
  };
}

/**
 * The sender with the day's ceiling across every workspace (BOT-EMAIL-NEXT-PLAN §4), and the
 * instance owner told once a day at 80% and at 100%.
 */
function withCeiling(
  inner: HostedMailSender,
  ceiling: number,
  adminEmails: string | undefined,
): HostedMailSender {
  if (ceiling <= 0) return inner;
  return {
    name: inner.name,
    customMessageId: inner.customMessageId,
    dailyCeiling: ceiling,
    send: (msg, f) => inner.send(msg, f),
    async onCeiling(db, sent, max) {
      const level = sent >= max ? "full" : "high";
      const [told] = await db.execute<{ id: string }>(sql`
        select id from public.notifications
        where kind = 'mail_send_ceiling' and payload ->> 'level' = ${level}
          and created_at > now() - interval '1 day' limit 1`);
      if (told) return;
      await noticeInstanceOwners(db, adminEmails, "mail_send_ceiling", {
        title:
          level === "full"
            ? `Bot mail stopped for today: ${max} sent`
            : `Bot mail is at ${Math.round((sent / max) * 100)}% of today's ${max}`,
        body:
          level === "full"
            ? "Every workspace's sends wait until the oldest of today's mail is a day old. Raise MAIL_SEND_DAILY_MAX once Cloudflare raises the allowance."
            : "Sends stop at the daily ceiling. Ask Cloudflare for a higher allowance before it's reached.",
        link: "/admin?tab=mail",
        level,
      });
    },
  };
}

/**
 * The sender the worker sends with: a stub that refuses while sending is paused, so paused
 * mail fails loudly in the channel's activity instead of going out.
 */
export function workerMailSender(mail: HostedMail | undefined): HostedMailSender | undefined {
  if (!mail) return undefined;
  if (!mail.sendPaused) return mail.sender;
  return {
    name: mail.sender.name,
    customMessageId: mail.sender.customMessageId,
    dailyCeiling: mail.sender.dailyCeiling,
    send: async () => {
      throw new Error("Hosted mail sending is paused on this server");
    },
  };
}
