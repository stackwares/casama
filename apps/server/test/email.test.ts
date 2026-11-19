import { describe, expect, it } from "vitest";
import {
  type EmailSender,
  isUndeliverableAddress,
  type MailTransport,
  resendEmail,
  smtpEmail,
  withBackupEmail,
} from "../src/services/email.ts";

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
    await email.send({ to: "ada@casama.ai", subject: "Join", text: "Hi", html: "<p>Hi</p>" });
    expect(sent).toEqual([
      {
        from: "Casama <hello@casama.ai>",
        to: "ada@casama.ai",
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

describe("undeliverable addresses", () => {
  it("knows the names set aside for examples and tests", () => {
    for (const bad of [
      "test@example.com",
      "island-1@EXAMPLE.com",
      "a@mail.example.org",
      "a@example.net",
      "a@host.test",
      "a@x.invalid",
      "a@localhost",
      "a@box.localhost",
      "a@shop.example",
      "no-domain",
    ])
      expect(isUndeliverableAddress(bad), bad).toBe(true);
    for (const good of [
      "ada@casama.ai",
      "a@gmail.com",
      "a@example.co",
      "a@myexample.com",
      "a@test.io",
    ])
      expect(isUndeliverableAddress(good), good).toBe(false);
  });

  it("skips them instead of sending, over SMTP and Resend", async () => {
    let smtpCalls = 0;
    const smtp = await smtpEmail({ host: "h", port: 587 }, "x@casama.ai", {
      sendMail: async () => {
        smtpCalls++;
        return {};
      },
    });
    await smtp.send({ to: "test@example.com", subject: "s", text: "t" });
    expect(smtpCalls).toBe(0);

    let fetches = 0;
    const resend = resendEmail("key", "x@casama.ai", (async () => {
      fetches++;
      return new Response("{}");
    }) as unknown as typeof fetch);
    await resend.send({ to: "island-9@example.com", subject: "s", text: "t" });
    expect(fetches).toBe(0);
    await resend.send({ to: "ada@casama.ai", subject: "s", text: "t" });
    expect(fetches).toBe(1);
  });
});

describe("withBackupEmail", () => {
  const msg = { to: "ada@casama.ai", subject: "Join", text: "Hi" };
  const sender = (fail: boolean, log: string[], name: string): EmailSender => ({
    enabled: true,
    async send() {
      log.push(name);
      if (fail) throw new Error(`${name} down`);
    },
  });

  it("uses only the main sender when it works", async () => {
    const log: string[] = [];
    await withBackupEmail(sender(false, log, "main"), sender(false, log, "backup")).send(msg);
    expect(log).toEqual(["main"]);
  });

  it("sends through the backup when the main sender fails", async () => {
    const log: string[] = [];
    const errors: unknown[] = [];
    await withBackupEmail(sender(true, log, "main"), sender(false, log, "backup"), (e) =>
      errors.push(e),
    ).send(msg);
    expect(log).toEqual(["main", "backup"]);
    expect(errors).toHaveLength(1);
  });

  it("throws the main sender's error when both fail", async () => {
    const log: string[] = [];
    await expect(
      withBackupEmail(sender(true, log, "main"), sender(true, log, "backup")).send(msg),
    ).rejects.toThrow("main down");
    expect(log).toEqual(["main", "backup"]);
  });
});
