/**
 * Enterprise license keys (D-073): Ed25519-signed JWTs checked against the public key in this
 * folder. Claims: sub (customer), features, seats, exp.
 */
import { readFileSync } from "node:fs";
import { importSPKI, jwtVerify } from "jose";

export type EeFeature = "audit_export" | "sso" | "advanced_roles";

export interface License {
  customer: string;
  features: EeFeature[];
  seats: number;
  expiresAt: Date;
}

const PUBLIC_KEY = new URL("./license-public.pem", import.meta.url);

export async function verifyLicense(
  token: string | undefined,
  publicKeyPem?: string,
): Promise<License | null> {
  if (!token) return null;
  try {
    const key = await importSPKI(publicKeyPem ?? readFileSync(PUBLIC_KEY, "utf8"), "EdDSA");
    const { payload } = await jwtVerify(token, key, {
      issuer: "kasama-licensing",
      algorithms: ["EdDSA"],
    });
    return {
      customer: String(payload.sub),
      features: (payload.features as EeFeature[]) ?? [],
      seats: Number(payload.seats ?? 0),
      expiresAt: new Date((payload.exp ?? 0) * 1000),
    };
  } catch {
    return null;
  }
}
