import type { Database } from "@kasama/db";
import { sql } from "drizzle-orm";
import type { ModelChoice, ProviderId, ResolvedModel } from "./gateway/types.ts";

/** Reads model keys from Vault. Only the worker's database role can read vault.decrypted_secrets. */
export class CredentialResolver {
  private readonly db: Database;
  constructor(db: Database) {
    this.db = db;
  }

  async resolve(orgId: string, choice: ModelChoice): Promise<ResolvedModel> {
    const rows = await this.db.execute<{
      provider: ProviderId;
      base_url: string | null;
      key: string | null;
    }>(sql`
      select c.provider, c.base_url, s.decrypted_secret as key
      from public.model_credentials c
      left join vault.decrypted_secrets s on s.id = c.vault_secret_id
      where c.id = ${choice.credential_id}::uuid and c.org_id = ${orgId}::uuid`);
    const row = rows[0];
    if (!row) throw new Error("model_credential_not_found");
    return {
      provider: row.provider,
      model: choice.model,
      apiKey: row.key ?? undefined,
      baseUrl: row.base_url ?? undefined,
      credentialId: choice.credential_id,
    };
  }

  /** First OpenAI credential of the org, used for embeddings. */
  async embeddingCredential(orgId: string): Promise<ResolvedModel | null> {
    const rows = await this.db.execute<{
      id: string;
      base_url: string | null;
      key: string | null;
    }>(sql`
      select c.id, c.base_url, s.decrypted_secret as key
      from public.model_credentials c
      left join vault.decrypted_secrets s on s.id = c.vault_secret_id
      where c.org_id = ${orgId}::uuid and c.provider = 'openai'
      order by c.created_at limit 1`);
    const row = rows[0];
    if (!row?.key) return null;
    return {
      provider: "openai",
      model: "text-embedding-3-small",
      apiKey: row.key,
      baseUrl: row.base_url ?? undefined,
      credentialId: row.id,
    };
  }
}

export interface ModelPolicy {
  primary?: ModelChoice;
  fallbacks?: ModelChoice[];
  cheap?: ModelChoice;
}
