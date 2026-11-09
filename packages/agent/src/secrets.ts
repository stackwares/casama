import type { Database } from "@kasama/db";
import { sql } from "drizzle-orm";

export interface NamedSecret {
  name: string;
  value: string;
  allowedHosts: string[];
}

const PLACEHOLDER = /\{\{secret:([A-Z][A-Z0-9_]{0,63})\}\}/g;

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
  }>(sql`
    select s.name, v.decrypted_secret as value, s.allowed_hosts
    from public.secrets s left join vault.decrypted_secrets v on v.id = s.vault_secret_id
    where s.org_id = ${orgId}::uuid and (s.allowed_bot_ids is null or ${botId}::uuid = any(s.allowed_bot_ids))`);
  return rows
    .filter((r) => r.value)
    .map((r) => ({ name: r.name, value: r.value as string, allowedHosts: r.allowed_hosts ?? [] }));
}

export const hasPlaceholders = (v: unknown) => JSON.stringify(v ?? null).includes("{{secret:");

const hostAllowed = (host: string, allowed: string[]) => {
  const h = host.toLowerCase();
  return allowed.some((a) => {
    const rule = a.toLowerCase().replace(/^\*\./, "");
    return h === rule || h.endsWith(`.${rule}`);
  });
};

/**
 * Replaces {{secret:NAME}} placeholders in tool arguments, only when the destination host is in the
 * secret's allowed_hosts. Throws when a secret is unknown or the host is not allowed.
 */
export function resolvePlaceholders<T>(value: T, secrets: NamedSecret[], host: string | null): T {
  const byName = new Map(secrets.map((s) => [s.name, s]));
  const replace = (s: string) =>
    s.replace(PLACEHOLDER, (_m, name: string) => {
      const secret = byName.get(name);
      if (!secret)
        throw new SecretError(
          "unknown_secret",
          `Secret ${name} does not exist or this bot may not use it.`,
        );
      if (!host || !hostAllowed(host, secret.allowedHosts)) {
        throw new SecretError(
          "secret_host_not_allowed",
          `Secret ${name} may not be sent to ${host ?? "this destination"}.`,
        );
      }
      return secret.value;
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
