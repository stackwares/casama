/**
 * Sign-in codes (SPEC: Post-v1 roadmap → Sign-in codes for bots; D-102). A `totp` secret holds a
 * two-step seed as an `otpauth://totp/...` link or a bare base32 key; codes follow RFC 6238.
 */
import { createHmac } from "node:crypto";

export interface TotpSeed {
  key: Buffer;
  algorithm: "sha1" | "sha256" | "sha512";
  digits: 6 | 7 | 8;
  period: number;
  label: string | null;
  issuer: string | null;
}

export class TotpError extends Error {}

const B32 = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";

export function base32Decode(input: string): Buffer {
  const clean = input.toUpperCase().replace(/[\s-]/g, "").replace(/=+$/, "");
  if (!clean || /[^A-Z2-7]/.test(clean))
    throw new TotpError("The key is not base32 (letters A–Z and digits 2–7).");
  let bits = 0;
  let value = 0;
  const out: number[] = [];
  for (const c of clean) {
    value = (value << 5) | B32.indexOf(c);
    bits += 5;
    if (bits >= 8) {
      out.push((value >>> (bits - 8)) & 0xff);
      bits -= 8;
    }
  }
  return Buffer.from(out);
}

/** Parses an otpauth://totp link or a bare base32 key. Throws TotpError with a readable reason. */
export function parseTotp(value: string): TotpSeed {
  const v = value.trim();
  if (!v.toLowerCase().startsWith("otpauth://")) {
    const key = base32Decode(v);
    if (key.length < 10) throw new TotpError("The key is too short to be a two-step key.");
    return { key, algorithm: "sha1", digits: 6, period: 30, label: null, issuer: null };
  }
  let url: URL;
  try {
    url = new URL(v);
  } catch {
    throw new TotpError("The link is not a valid otpauth:// link.");
  }
  if (url.host.toLowerCase() !== "totp")
    throw new TotpError("Only time-based (totp) codes are supported.");
  const secret = url.searchParams.get("secret");
  if (!secret) throw new TotpError("The link has no secret.");
  const key = base32Decode(secret);
  if (key.length < 10) throw new TotpError("The key is too short to be a two-step key.");
  const alg = (url.searchParams.get("algorithm") ?? "SHA1").toLowerCase();
  if (!["sha1", "sha256", "sha512"].includes(alg))
    throw new TotpError(`Unsupported algorithm ${alg}.`);
  const digits = Number(url.searchParams.get("digits") ?? 6);
  if (![6, 7, 8].includes(digits)) throw new TotpError("Codes must have 6, 7 or 8 digits.");
  const period = Number(url.searchParams.get("period") ?? 30);
  if (!Number.isInteger(period) || period < 10 || period > 300)
    throw new TotpError("The period must be 10–300 seconds.");
  const label = decodeURIComponent(url.pathname.replace(/^\//, "")) || null;
  return {
    key,
    algorithm: alg as TotpSeed["algorithm"],
    digits: digits as TotpSeed["digits"],
    period,
    label,
    issuer: url.searchParams.get("issuer"),
  };
}

/** The code for `seed` at `nowMs` (RFC 6238 / RFC 4226 dynamic truncation). */
export function totpCode(seed: TotpSeed, nowMs = Date.now()): string {
  const counter = Math.floor(nowMs / 1000 / seed.period);
  const msg = Buffer.alloc(8);
  msg.writeBigUInt64BE(BigInt(counter));
  const mac = createHmac(seed.algorithm, seed.key).update(msg).digest();
  const offset = (mac[mac.length - 1] as number) & 0x0f;
  const bin = (mac.readUInt32BE(offset) & 0x7fffffff) % 10 ** seed.digits;
  return String(bin).padStart(seed.digits, "0");
}
