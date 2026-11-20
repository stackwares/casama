import { CloudflareMailSender, type HostedMailSender, ResendMailSender } from "@casama/agent";
import type { Env } from "../env.ts";

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
  return { domain: env.MAIL_DOMAIN, sender, sendPaused: env.MAIL_SEND_PAUSED };
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
    send: async () => {
      throw new Error("Hosted mail sending is paused on this server");
    },
  };
}
