import type { Database } from "@casama/db";
import {
  CLOUD_LOCKED_MODEL,
  DEFAULT_MODELS,
  DEFAULT_REASONING_EFFORT,
  PLATFORM_OPENROUTER_CREDENTIAL_ID,
} from "@casama/domain";
import { sql } from "drizzle-orm";
import { ChatGptAuthError, type ChatGptTokens, refreshTokens, tokensFrom } from "./chatgpt-auth.ts";
import { CHATGPT_API_URL } from "./gateway/chatgpt.ts";
import {
  ModelCallError,
  type ModelChoice,
  type ProviderId,
  type ResolvedModel,
} from "./gateway/types.ts";

export { CLOUD_LOCKED_MODEL, PLATFORM_OPENROUTER_CREDENTIAL_ID };

export interface ChatGptConfig {
  /** OpenAI's auth server (tests point it at a fake). */
  authUrl?: string;
  /** The Responses API base (tests point it at a fake). */
  apiUrl?: string;
  fetch?: typeof fetch;
  /** Refresh when the access token has less than this left (default 5 minutes). */
  refreshSkewMs?: number;
  now?: () => number;
}

export interface ResolveContext {
  /** The person a run acts for; a personal credential (a ChatGPT plan) serves only its owner. */
  actingUserId: string | null;
}

/** Reads model keys from Vault. Only the worker's database role can read vault.decrypted_secrets. */
/** Cloudflare AI Gateway paths for each provider (replacing the provider's own base URL). */
export const AI_GATEWAY_PATHS: Partial<Record<ProviderId, string>> = {
  openai: "openai",
  anthropic: "anthropic/v1",
  google: "google-ai-studio/v1beta",
  xai: "grok/v1",
  openrouter: "openrouter/v1",
};

export interface AiGatewayConfig {
  /** https://gateway.ai.cloudflare.com/v1/<account>/<gateway> */
  url: string;
  /** For authenticated gateways (sent as cf-aig-authorization). */
  token?: string;
  /** Which providers go through it (default: all it supports). */
  providers?: ProviderId[];
}

export class CredentialResolver {
  private readonly db: Database;
  private readonly chatgpt: ChatGptConfig;
  private readonly gateway?: AiGatewayConfig;
  /** Casama Cloud's OpenRouter key. Workspaces without their own key run on this. */
  private readonly platformOpenRouterKey?: string;
  constructor(
    db: Database,
    opts: {
      chatgpt?: ChatGptConfig;
      aiGateway?: AiGatewayConfig;
      platformOpenRouterKey?: string;
    } = {},
  ) {
    this.db = db;
    this.chatgpt = opts.chatgpt ?? {};
    this.gateway = opts.aiGateway;
    this.platformOpenRouterKey = opts.platformOpenRouterKey;
  }

  /** The shared Cloud model, when this server has one. */
  platformChoice(model?: string): ModelChoice | null {
    if (!this.platformOpenRouterKey) return null;
    return {
      credential_id: PLATFORM_OPENROUTER_CREDENTIAL_ID,
      model: model || CLOUD_LOCKED_MODEL,
    };
  }

  /** Cloudflare AI Gateway (D-145): calls without their own base URL go through it, for caching, logs and limits. */
  private viaGateway(provider: ProviderId, baseUrl: string | null) {
    const path = AI_GATEWAY_PATHS[provider];
    const g = this.gateway;
    if (!g || baseUrl || !path || (g.providers && !g.providers.includes(provider)))
      return { baseUrl: baseUrl ?? undefined };
    return {
      baseUrl: `${g.url.replace(/\/$/, "")}/${path}`,
      headers: g.token ? { "cf-aig-authorization": `Bearer ${g.token}` } : undefined,
    };
  }

  private now() {
    return this.chatgpt.now?.() ?? Date.now();
  }

  async resolve(orgId: string, choice: ModelChoice, ctx?: ResolveContext): Promise<ResolvedModel> {
    const reasoningEffort =
      choice.reasoning_effort ??
      (Object.values(DEFAULT_MODELS).includes(choice.model) ? DEFAULT_REASONING_EFFORT : undefined);
    if (choice.credential_id === PLATFORM_OPENROUTER_CREDENTIAL_ID) {
      if (!this.platformOpenRouterKey) throw new Error("model_credential_not_found");
      return {
        provider: "openrouter",
        model: choice.model || CLOUD_LOCKED_MODEL,
        apiKey: this.platformOpenRouterKey,
        ...this.viaGateway("openrouter", null),
        credentialId: choice.credential_id,
        reasoningEffort,
        platformKey: true,
        openRouterUser: orgId,
      };
    }
    const rows = await this.db.execute<{
      provider: ProviderId;
      base_url: string | null;
      key: string | null;
      owner_user_id: string | null;
      status: string;
      settings: { fallback_on_limit?: boolean } | null;
    }>(sql`
      select c.provider, c.base_url, s.decrypted_secret as key, c.owner_user_id, c.status, c.settings
      from public.model_credentials c
      left join vault.decrypted_secrets s on s.id = c.vault_secret_id
      where c.id = ${choice.credential_id}::uuid and c.org_id = ${orgId}::uuid`);
    const row = rows[0];
    if (!row) throw new Error("model_credential_not_found");
    if (row.provider === "chatgpt") {
      const fallbackOnLimit = row.settings?.fallback_on_limit === true;
      const fail = (code: string, message: string, retryable: boolean) =>
        new ModelCallError(message, { code, retryable, credentialId: choice.credential_id });
      if (ctx && row.owner_user_id !== ctx.actingUserId)
        throw fail(
          "chatgpt_plan_not_yours",
          "This bot's ChatGPT plan belongs to someone else. Connect your own plan or add a key.",
          true,
        );
      if (row.status === "needs_reconnect")
        throw fail(
          "chatgpt_needs_reconnect",
          "The ChatGPT sign-in is no longer valid; sign in again.",
          fallbackOnLimit,
        );
      if (row.status === "plan_usage_off")
        throw fail(
          "chatgpt_plan_usage_off",
          "ChatGPT plan usage was not granted; sign in again and allow it, or add an API key.",
          fallbackOnLimit,
        );
      let tokens = parseTokens(row.key);
      if (!tokens) throw fail("chatgpt_needs_reconnect", "The ChatGPT sign-in is missing.", false);
      if (tokens.expires_at - this.now() < (this.chatgpt.refreshSkewMs ?? 5 * 60_000))
        tokens = await this.refreshChatGpt(choice.credential_id);
      return {
        provider: "chatgpt",
        model: choice.model,
        apiKey: tokens.access_token,
        baseUrl: this.chatgpt.apiUrl ?? CHATGPT_API_URL,
        credentialId: choice.credential_id,
        reasoningEffort,
        fallbackOnLimit,
      };
    }
    return {
      provider: row.provider,
      model: choice.model,
      apiKey: row.key ?? undefined,
      ...this.viaGateway(row.provider, row.base_url),
      credentialId: choice.credential_id,
      reasoningEffort,
    };
  }

  /**
   * Refreshes a ChatGPT credential's tokens. Refresh tokens rotate on every use, so refreshes are
   * serialized with an advisory lock per credential; a waiter re-reads and reuses the new pair.
   */
  async refreshChatGpt(
    credentialId: string,
    opts: { force?: boolean } = {},
  ): Promise<ChatGptTokens> {
    const outcome = await this.db
      .transaction(async (tx) => {
        await tx.execute(sql`select pg_advisory_xact_lock(hashtextextended(${credentialId}, 0))`);
        const [row] = await tx.execute<{ vault_secret_id: string | null; key: string | null }>(sql`
        select c.vault_secret_id, s.decrypted_secret as key
        from public.model_credentials c
        left join vault.decrypted_secrets s on s.id = c.vault_secret_id
        where c.id = ${credentialId}::uuid and c.provider = 'chatgpt'`);
        const prev = parseTokens(row?.key ?? null);
        if (!row?.vault_secret_id || !prev) return { dead: "missing" } as const;
        const now = this.now();
        const skew = this.chatgpt.refreshSkewMs ?? 5 * 60_000;
        // Another run refreshed while this one waited for the lock.
        if (!opts.force && prev.expires_at - now >= skew) return { tokens: prev } as const;
        if (prev.earliest_refresh_at && now < prev.earliest_refresh_at && prev.expires_at > now)
          return { tokens: prev } as const;
        let next: ChatGptTokens;
        try {
          const resp = await refreshTokens(
            { authUrl: this.chatgpt.authUrl, fetch: this.chatgpt.fetch },
            { clientId: prev.client_id, refreshToken: prev.refresh_token },
          );
          next = tokensFrom(resp, prev.client_id, prev, now);
        } catch (err) {
          if (err instanceof ChatGptAuthError && err.kind === "invalid")
            return { dead: err.code ?? "invalid" } as const;
          throw err;
        }
        await tx.execute(
          sql`select vault.update_secret(${row.vault_secret_id}::uuid, ${JSON.stringify(next)})`,
        );
        await tx.execute(
          sql`update public.model_credentials set refreshed_at = now(), status = 'ok' where id = ${credentialId}::uuid`,
        );
        return { tokens: next } as const;
      })
      .catch((err: unknown) => {
        // Network and server errors never delete or invalidate the credential.
        throw new ModelCallError(
          `Could not refresh the ChatGPT sign-in: ${(err as Error).message}`,
          {
            retryable: true,
            code: "chatgpt_unavailable",
            credentialId,
            cause: err,
          },
        );
      });
    if ("dead" in outcome) {
      await this.markNeedsReconnect(credentialId);
      throw new ModelCallError("The ChatGPT sign-in is no longer valid; sign in again.", {
        retryable: false,
        code: "chatgpt_needs_reconnect",
        credentialId,
      });
    }
    return outcome.tokens;
  }

  /** Marks a ChatGPT credential as needing a new sign-in and tells its owner (once). */
  async markNeedsReconnect(credentialId: string) {
    const [row] = await this.db.execute<{
      owner_user_id: string | null;
      org_id: string;
      label: string;
    }>(sql`
      update public.model_credentials set status = 'needs_reconnect'
      where id = ${credentialId}::uuid and provider = 'chatgpt' and status <> 'needs_reconnect'
      returning owner_user_id, org_id, label`);
    if (!row?.owner_user_id) return;
    await this.db.execute(sql`
      insert into public.notifications (user_id, org_id, kind, payload)
      values (${row.owner_user_id}::uuid, ${row.org_id}::uuid, 'credential', ${JSON.stringify({
        title: "Reconnect your ChatGPT plan",
        body: "Your ChatGPT sign-in stopped working. Sign in again from the desktop app or the CLI.",
        link: "/settings",
        credential_id: credentialId,
      })}::jsonb)`);
  }

  /** The tokens of a ChatGPT credential (revocation and model lists). */
  async chatGptTokens(credentialId: string): Promise<ChatGptTokens | null> {
    const [row] = await this.db.execute<{ key: string | null }>(sql`
      select s.decrypted_secret as key
      from public.model_credentials c
      left join vault.decrypted_secrets s on s.id = c.vault_secret_id
      where c.id = ${credentialId}::uuid and c.provider = 'chatgpt'`);
    return parseTokens(row?.key ?? null);
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

function parseTokens(key: string | null): ChatGptTokens | null {
  if (!key) return null;
  try {
    const t = JSON.parse(key) as ChatGptTokens;
    return typeof t.access_token === "string" && typeof t.refresh_token === "string" ? t : null;
  } catch {
    return null;
  }
}

export interface ModelPolicy {
  primary?: ModelChoice;
  fallbacks?: ModelChoice[];
  cheap?: ModelChoice;
}
