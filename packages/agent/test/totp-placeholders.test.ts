/** Sign-in codes (D-102): {{totp:NAME}} yields the current code only, only on allowed hosts. */
import { parseTotp, totpCode } from "@kasama/domain";
import { describe, expect, it } from "vitest";
import { Redactor } from "../src/redact.ts";
import { hasPlaceholders, type NamedSecret, resolvePlaceholders } from "../src/secrets.ts";

const SEED = "otpauth://totp/Acme:ada?secret=JBSWY3DPEHPK3PXP&issuer=Acme";
const secrets: NamedSecret[] = [
  { name: "ACME_2FA", value: SEED, allowedHosts: ["acme.example"], kind: "totp" },
  {
    name: "ACME_PASSWORD",
    value: "hunter2-very-long",
    allowedHosts: ["acme.example"],
    kind: "value",
  },
];

describe("{{totp:NAME}}", () => {
  it("becomes the current code on an allowed host and reports it for redaction", () => {
    const now = 1_700_000_000_000;
    const seen: string[] = [];
    const out = resolvePlaceholders({ text: "{{totp:ACME_2FA}}" }, secrets, "login.acme.example", {
      nowMs: now,
      onCode: (c) => seen.push(c),
    });
    const expected = totpCode(parseTotp(SEED), now);
    expect(out.text).toBe(expected);
    expect(seen).toEqual([expected]);
    expect(hasPlaceholders({ a: "{{totp:X}}" })).toBe(true);
  });

  it("never reveals the seed and refuses other hosts or the wrong kind", () => {
    expect(() => resolvePlaceholders("{{secret:ACME_2FA}}", secrets, "acme.example")).toThrow(
      /seed/,
    );
    expect(() => resolvePlaceholders("{{totp:ACME_PASSWORD}}", secrets, "acme.example")).toThrow(
      /not a sign-in code/,
    );
    expect(() => resolvePlaceholders("{{totp:ACME_2FA}}", secrets, "evil.example")).toThrow(
      /may not be sent/,
    );
    expect(resolvePlaceholders("{{secret:ACME_PASSWORD}}", secrets, "acme.example")).toBe(
      "hunter2-very-long",
    );
  });
});

describe("redactor merge (audit 2026-11)", () => {
  it("a rebuilt redactor keeps the values added during the run", () => {
    const before = new Redactor().add("login-password-123", "login");
    const after = new Redactor().add("new-secret-value", "API_KEY").merge(before);
    expect(after.text("pw login-password-123 and new-secret-value")).toBe("pw [secret:login] and [secret:API_KEY]");
  });
});
