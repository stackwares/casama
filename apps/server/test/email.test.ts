import { describe, expect, it } from "vitest";
import { type MailTransport, smtpEmail } from "../src/services/email.ts";

describe("smtpEmail", () => {
  it("sends through the transport with the configured sender", async () => {
    const sent: Parameters<MailTransport["sendMail"]>[0][] = [];
    const transport: MailTransport = {
      async sendMail(mail) {
        sent.push(mail);
        return {};
      },
    };
    const email = await smtpEmail(
      { host: "smtp.example.com", port: 587, user: "u", pass: "p" },
      "Casama <hello@casama.ai>",
      transport,
    );
    expect(email.enabled).toBe(true);
    await email.send({ to: "ada@example.com", subject: "Join", text: "Hi", html: "<p>Hi</p>" });
    expect(sent).toEqual([
      {
        from: "Casama <hello@casama.ai>",
        to: "ada@example.com",
        subject: "Join",
        text: "Hi",
        html: "<p>Hi</p>",
      },
    ]);
  });

  it("passes transport failures to the caller", async () => {
    const email = await smtpEmail({ host: "h", port: 465 }, "x@example.com", {
      sendMail: async () => {
        throw new Error("535 auth failed");
      },
    });
    await expect(email.send({ to: "a@b.c", subject: "s", text: "t" })).rejects.toThrow("535");
  });

  it("builds a real nodemailer transport when none is given", async () => {
    const email = await smtpEmail({ host: "127.0.0.1", port: 2525 }, "x@example.com");
    expect(email.enabled).toBe(true);
  });
});
