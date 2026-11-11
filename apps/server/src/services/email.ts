export interface EmailMessage {
  to: string;
  subject: string;
  text: string;
  html?: string;
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
      const res = await fetchImpl("https://api.resend.com/emails", {
        method: "POST",
        headers: { authorization: `Bearer ${apiKey}`, "content-type": "application/json" },
        body: JSON.stringify({
          from,
          to: [msg.to],
          subject: msg.subject,
          text: msg.text,
          html: msg.html,
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
      await mailer.sendMail({
        from,
        to: msg.to,
        subject: msg.subject,
        text: msg.text,
        html: msg.html,
      });
    },
  };
}
