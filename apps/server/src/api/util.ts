export { slugify } from "@casama/domain";

import { createHash, randomBytes } from "node:crypto";

/** Normalizes Postgres timestamps (Date or text) to ISO 8601. */
export const iso = (v: string | Date) => (v instanceof Date ? v : new Date(v)).toISOString();

export const randomSuffix = () => randomBytes(3).toString("hex");
/** Invite tokens: prefixed so they never start with "-" (which CLIs would read as an option). */
export const newToken = () => `kinv_${randomBytes(32).toString("base64url")}`;
export const sha256Hex = (s: string) => createHash("sha256").update(s).digest("hex");

/**
 * The caller's address, for signed-out rate limits. `trusted` names a header the edge sets and a
 * client can't override (TRUSTED_CLIENT_IP_HEADER; Casama Cloud: cf-connecting-ip, because
 * Cloudflare Tunnel reaches Caddy from one local address and Caddy writes that address into
 * X-Forwarded-For). Otherwise the first X-Forwarded-For entry, which Caddy, the edge on
 * self-hosted servers, sets to the real peer.
 */
export function clientIp(header: (name: string) => string | undefined, trusted?: string): string {
  const fromEdge = trusted ? header(trusted)?.trim() : undefined;
  return (
    fromEdge ||
    header("x-forwarded-for")?.split(",")[0]?.trim() ||
    header("x-real-ip")?.trim() ||
    "unknown"
  );
}
