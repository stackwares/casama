export interface EmailMessage {
  to: string;
  subject: string;
  text: string;
  html?: string;
  /** Where replies go instead of the sender (support messages answer the person, D-298). */
  replyTo?: string;
  /** Extra headers, such as List-Unsubscribe on tips emails (D-302). */
  headers?: Record<string, string>;
}

/**
 * Whether an address can never receive mail: the names set aside for examples and tests
 * (RFC 2606, RFC 6761): example.com/.net/.org, and the .example, .test, .invalid and
 * .localhost top-level names. Sending to them only bounces, and hard bounces count against
 * the sender (ZeptoMail flagged 22 such bounces from test sign-ups in November 2026).
 */
export function isUndeliverableAddress(address: string): boolean {
  const domain = (address.split("@")[1] ?? "").trim().toLowerCase().replace(/\.$/, "");
  if (!domain) return true;
  if (["example.com", "example.net", "example.org", "localhost"].includes(domain)) return true;
  if (/\.(example|test|invalid|localhost)$/.test(domain)) return true;
  return /(^|\.)example\.(com|net|org)$/.test(domain);
}

/** Outbound transactional email. */
export interface EmailSender {
  readonly enabled: boolean;
  send(msg: EmailMessage): Promise<void>;
}

export const disabledEmail: EmailSender = {
  enabled: false,
  async send() {
    throw new Error("email is not configured");
  },
};

/** Transactional email through the Resend HTTP API. */
export function resendEmail(
  apiKey: string,
  from: string,
  fetchImpl: typeof fetch = fetch,
): EmailSender {
  return {
    enabled: true,
    async send(msg) {
      if (isUndeliverableAddress(msg.to)) return;
      const res = await fetchImpl("https://api.resend.com/emails", {
        method: "POST",
        headers: { authorization: `Bearer ${apiKey}`, "content-type": "application/json" },
        body: JSON.stringify({
          from,
          to: [msg.to],
          subject: msg.subject,
          text: msg.text,
          html: msg.html,
          ...(msg.replyTo ? { reply_to: msg.replyTo } : {}),
          ...(msg.headers ? { headers: msg.headers } : {}),
        }),
      });
      if (!res.ok) throw new Error(`email send failed with status ${res.status}`);
    },
  };
}

export interface SmtpSettings {
  host: string;
  port: number;
  user?: string;
  pass?: string;
}

/** The part of nodemailer's transport we use, so tests can pass a stand-in. */
export interface MailTransport {
  sendMail(mail: {
    from: string;
    to: string;
    subject: string;
    text: string;
    html?: string;
    replyTo?: string;
    headers?: Record<string, string>;
  }): Promise<unknown>;
}

/**
 * Transactional email over SMTP (for example Zoho, D-174). Port 465 uses TLS from the start;
 * other ports upgrade with STARTTLS, which is required.
 */
export async function smtpEmail(
  settings: SmtpSettings,
  from: string,
  transport?: MailTransport,
): Promise<EmailSender> {
  const mailer =
    transport ??
    (await import("nodemailer")).createTransport({
      host: settings.host,
      port: settings.port,
      secure: settings.port === 465,
      requireTLS: settings.port !== 465,
      auth: settings.user ? { user: settings.user, pass: settings.pass ?? "" } : undefined,
    });
  return {
    enabled: true,
    async send(msg) {
      if (isUndeliverableAddress(msg.to)) return;
      await mailer.sendMail({
        from,
        to: msg.to,
        subject: msg.subject,
        text: msg.text,
        html: msg.html,
        ...(msg.replyTo ? { replyTo: msg.replyTo } : {}),
        ...(msg.headers ? { headers: msg.headers } : {}),
      });
    },
  };
}
