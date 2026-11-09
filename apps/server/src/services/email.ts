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
