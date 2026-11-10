import type { Database } from "@kasama/db";
import { parseTotp, TotpError, totpCode } from "@kasama/domain";
import { sql } from "drizzle-orm";

export interface NamedSecret {
  name: string;
  value: string;
  allowedHosts: string[];
  /** value: the secret itself; totp: a two-step seed that only ever yields codes (D-102). */
  kind?: "value" | "totp";
}

const PLACEHOLDER = /\{\{(secret|totp):([A-Z][A-Z0-9_]{0,63})\}\}/g;

export class SecretError extends Error {
  readonly code: string;
  constructor(code: string, message: string) {
    super(message);
    this.code = code;
  }
}

/** Named secrets a bot may use. Read only by the worker (Vault). */
export async function loadSecrets(
  db: Database,
  orgId: string,
  botId: string,
): Promise<NamedSecret[]> {
  const rows = await db.execute<{
    name: string;
    value: string | null;
    allowed_hosts: string[];
    kind: "value" | "totp";
  }>(sql`
    select s.name, v.decrypted_secret as value, s.allowed_hosts, s.kind
    from public.secrets s left join vault.decrypted_secrets v on v.id = s.vault_secret_id
    where s.org_id = ${orgId}::uuid and (s.allowed_bot_ids is null or ${botId}::uuid = any(s.allowed_bot_ids))`);
  return rows
    .filter((r) => r.value)
    .map((r) => ({
      name: r.name,
      value: r.value as string,
      allowedHosts: r.allowed_hosts ?? [],
      kind: r.kind ?? "value",
    }));
}

export const hasPlaceholders = (v: unknown) => {
  const s = JSON.stringify(v ?? null);
  return s.includes("{{secret:") || s.includes("{{totp:");
};

const hostAllowed = (host: string, allowed: string[]) => {
  const h = host.toLowerCase();
  return allowed.some((a) => {
    const rule = a.toLowerCase().replace(/^\*\./, "");
    return h === rule || h.endsWith(`.${rule}`);
  });
};

/**
 * Replaces {{secret:NAME}} and {{totp:NAME}} placeholders in tool arguments, only when the
 * destination host is in the secret's allowed_hosts. A totp secret only ever yields its current
 * code (the seed never leaves); `onCode` lets the caller redact codes from output.
 */
export function resolvePlaceholders<T>(
  value: T,
  secrets: NamedSecret[],
  host: string | null,
  opts: { nowMs?: number; onCode?: (code: string, name: string) => void } = {},
): T {
  const byName = new Map(secrets.map((s) => [s.name, s]));
  const replace = (s: string) =>
    s.replace(PLACEHOLDER, (_m, type: string, name: string) => {
      const secret = byName.get(name);
      if (!secret)
        throw new SecretError(
          "unknown_secret",
          `Secret ${name} does not exist or this bot may not use it.`,
        );
      const isTotp = secret.kind === "totp";
      if (type === "totp" && !isTotp)
        throw new SecretError(
          "not_a_totp_secret",
          `${name} is not a sign-in code secret; use {{secret:${name}}}.`,
        );
      if (type === "secret" && isTotp)
        throw new SecretError(
          "totp_seed_protected",
          `${name} holds a sign-in code seed; use {{totp:${name}}} for its current code.`,
        );
      if (!host || !hostAllowed(host, secret.allowedHosts)) {
        throw new SecretError(
          "secret_host_not_allowed",
          `Secret ${name} may not be sent to ${host ?? "this destination"}.`,
        );
      }
      if (!isTotp) return secret.value;
      try {
        const code = totpCode(parseTotp(secret.value), opts.nowMs);
        opts.onCode?.(code, name);
        return code;
      } catch (err) {
        if (err instanceof TotpError)
          throw new SecretError("invalid_totp_secret", `${name}: ${err.message}`);
        throw err;
      }
    });
  const walk = (v: unknown): unknown => {
    if (typeof v === "string") return replace(v);
    if (Array.isArray(v)) return v.map(walk);
    if (v && typeof v === "object")
      return Object.fromEntries(Object.entries(v).map(([k, x]) => [k, walk(x)]));
    return v;
  };
  return walk(value) as T;
}
