import { describe, expect, it } from "vitest";
import { base32Decode, parseTotp, totpCode } from "../src/totp.ts";

// RFC 6238 appendix B test vectors (8 digits).
const SHA1 = Buffer.from("12345678901234567890").toString("hex");
const b32 = (hex: string) => {
  const A = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";
  let bits = "";
  for (const b of Buffer.from(hex, "hex")) bits += b.toString(2).padStart(8, "0");
  let out = "";
  for (let i = 0; i < bits.length; i += 5)
    out += A[Number.parseInt(bits.slice(i, i + 5).padEnd(5, "0"), 2)];
  return out;
};

describe("totp", () => {
  it("matches the RFC 6238 vectors", () => {
    const seed = parseTotp(`otpauth://totp/Test?secret=${b32(SHA1)}&digits=8`);
    expect(totpCode(seed, 59_000)).toBe("94287082");
    expect(totpCode(seed, 1_111_111_109_000)).toBe("07081804");
    expect(totpCode(seed, 20_000_000_000_000)).toBe("65353130");
    const s256 = parseTotp(
      `otpauth://totp/T?secret=${b32(Buffer.from("12345678901234567890123456789012").toString("hex"))}&digits=8&algorithm=SHA256`,
    );
    expect(totpCode(s256, 59_000)).toBe("46119246");
  });

  it("reads bare keys and links, and explains bad ones", () => {
    expect(parseTotp("JBSW Y3DP EHPK 3PXP").digits).toBe(6);
    const s = parseTotp("otpauth://totp/Acme:ada@example.com?secret=JBSWY3DPEHPK3PXP&issuer=Acme");
    expect(s).toMatchObject({ issuer: "Acme", label: "Acme:ada@example.com", period: 30 });
    expect(() => parseTotp("otpauth://hotp/x?secret=JBSWY3DPEHPK3PXP")).toThrow(/time-based/);
    expect(() => parseTotp("not-base32!")).toThrow(/base32/);
    expect(() => base32Decode("")).toThrow();
  });
});
