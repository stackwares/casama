/**
 * Secret store (SPEC: Ops extras; D-145). Bots' named secrets ({{secret:NAME}}) are kept in a
 * `SecretStore`: Supabase Vault by default, or the workspace's own Infisical project (universal-auth
 * machine identity), from Infisical's public API docs. Casama keeps each secret's name, kind,
 * allowed hosts and bots; with Infisical the value stays in Infisical and is read when a bot uses it.
 */
import type { Database } from "@casama/db";
import { sql } from "drizzle-orm";

export interface SecretStore {
  readonly kind: "vault" | "infisical";
  /** Saves a value; returns the Vault id for Vault (null otherwise). */
  put(name: string, value: string, existingVaultId?: string | null): Promise<string | null>;
  /** Values for these names (missing names are left out). */
  get(names: string[]): Promise<Map<string, string>>;
  delete(name: string, vaultId?: string | null): Promise<void>;
}

export class VaultSecretStore implements SecretStore {
  readonly kind = "vault" as const;
  private readonly db: Database;
  constructor(db: Database) {
    this.db = db;
  }
  async put(_name: string, value: string, existingVaultId?: string | null) {
    if (existingVaultId) {
      await this.db.execute(sql`select vault.update_secret(${existingVaultId}::uuid, ${value})`);
      return existingVaultId;
    }
    const [v] = await this.db.execute<{ id: string }>(
      sql`select vault.create_secret(${value}, null, 'named secret') as id`,
    );
    return v?.id ?? null;
  }
  async get() {
    return new Map<string, string>(); // Vault values are joined in SQL where they're read.
  }
  async delete(_name: string, vaultId?: string | null) {
    if (vaultId) await this.db.execute(sql`delete from vault.secrets where id = ${vaultId}::uuid`);
  }
}

export interface InfisicalConfig {
  siteUrl: string;
  projectId: string;
  environment: string;
  secretPath: string;
  clientId: string;
  clientSecret: string;
}

export class InfisicalSecretStore implements SecretStore {
  readonly kind = "infisical" as const;
  private readonly o: InfisicalConfig & { fetch: typeof fetch };
  private token: { value: string; until: number } | null = null;
  constructor(o: InfisicalConfig & { fetch?: typeof fetch }) {
    this.o = { ...o, siteUrl: o.siteUrl.replace(/\/$/, ""), fetch: o.fetch ?? fetch };
  }
  private async access() {
    if (this.token && this.token.until > Date.now() + 30_000) return this.token.value;
    const res = await this.o.fetch(`${this.o.siteUrl}/api/v1/auth/universal-auth/login`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ clientId: this.o.clientId, clientSecret: this.o.clientSecret }),
    });
    if (!res.ok) throw new Error(`Infisical sign-in failed (${res.status})`);
    const b = (await res.json()) as { accessToken: string; expiresIn: number };
    this.token = { value: b.accessToken, until: Date.now() + b.expiresIn * 1000 };
    return b.accessToken;
  }
  private async req(
    method: string,
    path: string,
    body?: Record<string, unknown>,
    query?: Record<string, string>,
  ) {
    const qs = query ? `?${new URLSearchParams(query).toString()}` : "";
    const res = await this.o.fetch(`${this.o.siteUrl}${path}${qs}`, {
      method,
      headers: {
        authorization: `Bearer ${await this.access()}`,
        "content-type": "application/json",
      },
      body: body ? JSON.stringify(body) : undefined,
    });
    return res;
  }
  private scope() {
    return {
      workspaceId: this.o.projectId,
      environment: this.o.environment,
      secretPath: this.o.secretPath,
    };
  }
  async put(name: string, value: string) {
    const path = `/api/v3/secrets/raw/${encodeURIComponent(name)}`;
    let res = await this.req("POST", path, { ...this.scope(), secretValue: value, type: "shared" });
    // Already there: update it.
    if (res.status === 400 || res.status === 409)
      res = await this.req("PATCH", path, { ...this.scope(), secretValue: value, type: "shared" });
    if (!res.ok) throw new Error(`Infisical didn't save ${name} (${res.status})`);
    return null;
  }
  async list() {
    const res = await this.req("GET", "/api/v3/secrets/raw", undefined, this.scope());
    if (!res.ok) throw new Error(`Infisical didn't list secrets (${res.status})`);
    const b = (await res.json()) as { secrets: Array<{ secretKey: string; secretValue: string }> };
    return b.secrets;
  }
  async get(names: string[]) {
    const want = new Set(names);
    return new Map(
      (await this.list())
        .filter((s) => want.has(s.secretKey))
        .map((s) => [s.secretKey, s.secretValue] as [string, string]),
    );
  }
  async delete(name: string) {
    await this.req("DELETE", `/api/v3/secrets/raw/${encodeURIComponent(name)}`, {
      ...this.scope(),
      type: "shared",
    });
  }
}

/** The workspace's secret store (Infisical when configured, else Vault). */
export async function secretStoreFor(
  db: Database,
  orgId: string,
  f?: typeof fetch,
): Promise<SecretStore> {
  const [c] = await db.execute<{
    site_url: string;
    project_id: string;
    environment: string;
    secret_path: string;
    client_id: string;
    secret: string | null;
  }>(sql`
    select s.site_url, s.project_id, s.environment, s.secret_path, s.client_id, v.decrypted_secret as secret
    from public.org_secret_stores s left join vault.decrypted_secrets v on v.id = s.vault_secret_id where s.org_id = ${orgId}::uuid`);
  if (!c?.secret) return new VaultSecretStore(db);
  return new InfisicalSecretStore({
    siteUrl: c.site_url,
    projectId: c.project_id,
    environment: c.environment,
    secretPath: c.secret_path,
    clientId: c.client_id,
    clientSecret: c.secret,
    fetch: f,
  });
}
