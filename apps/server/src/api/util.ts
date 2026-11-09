export { slugify } from "@kasama/domain";

import { createHash, randomBytes } from "node:crypto";

/** Normalizes Postgres timestamps (Date or text) to ISO 8601. */
export const iso = (v: string | Date) => (v instanceof Date ? v : new Date(v)).toISOString();

export const randomSuffix = () => randomBytes(3).toString("hex");
/** Invite tokens: prefixed so they never start with "-" (which CLIs would read as an option). */
export const newToken = () => `kinv_${randomBytes(32).toString("base64url")}`;
export const sha256Hex = (s: string) => createHash("sha256").update(s).digest("hex");
