import type { JwtClaims } from "@casama/db";
import { createRemoteJWKSet, decodeProtectedHeader, type JWTPayload, jwtVerify } from "jose";

export type TokenVerifier = (token: string) => Promise<JwtClaims>;

/**
 * Verifies Supabase access tokens: HS256 with the legacy secret when configured,
 * otherwise asymmetric keys from the project's JWKS endpoint.
 */
export function createTokenVerifier(opts: {
  supabaseUrl: string;
  jwtSecret?: string;
}): TokenVerifier {
  const secret = opts.jwtSecret ? new TextEncoder().encode(opts.jwtSecret) : undefined;
  const jwks = createRemoteJWKSet(
    new URL(`${opts.supabaseUrl.replace(/\/$/, "")}/auth/v1/.well-known/jwks.json`),
  );
  return async (token) => {
    const { alg } = decodeProtectedHeader(token);
    let payload: JWTPayload;
    if (alg === "HS256") {
      if (!secret) throw new Error("HS256 token but no SUPABASE_JWT_SECRET configured");
      ({ payload } = await jwtVerify(token, secret, {
        algorithms: ["HS256"],
        audience: "authenticated",
      }));
    } else {
      ({ payload } = await jwtVerify(token, jwks, { audience: "authenticated" }));
    }
    if (typeof payload.sub !== "string" || payload.role !== "authenticated")
      throw new Error("not a user token");
    return payload as JwtClaims;
  };
}
