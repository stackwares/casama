/**
 * ChatGPT plan sign-in (SPEC: Model gateway → ChatGPT plan sign-in; D-091).
 *
 * OpenAI accepts only loopback redirects, so the desktop app or the CLI listens on 127.0.0.1 and
 * relays the code here. The server keeps the PKCE verifier, exchanges the code, verifies the ID
 * token and writes the tokens to Vault: they never reach the client device.
 */

import {
  authorizeUrl,
  CHATGPT_DYNAMIC_CLIENT,
  ChatGptAuthError,
  exchangeCode,
  hasPlanScope,
  openIdConfig,
  pkcePair,
  randomToken,
  tokensFrom,
} from "@casama/agent";
import { PRODUCT_NAME, routes } from "@casama/contracts";
import { type JwtClaims, schema, withUserSession } from "@casama/db";
import { captureError } from "@casama/observability";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { eq, sql } from "drizzle-orm";
import { createRemoteJWKSet, jwtVerify } from "jose";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { credOut } from "./bots.ts";

const { modelCredentials } = schema;

function requireClaims(claims: JwtClaims | undefined): JwtClaims {
  if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
  return claims;
}

/** Whether this server offers ChatGPT plan sign-in (off on Casama Cloud until OpenAI approves). */
export function chatGptSignInEnabled(env: AppDeps["env"]) {
  if (env.CHATGPT_SIGN_IN === "on") return true;
  if (env.CHATGPT_SIGN_IN === "off") return false;
  return !env.BILLING_ENABLED;
}

interface FlowOAuth {
  kind: "chatgpt";
  code_verifier: string;
  nonce: string;
  redirect_uri: string;
  client_id: string;
  credential_id?: string;
}

const jwksCache = new Map<string, ReturnType<typeof createRemoteJWKSet>>();

export function registerChatGptRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db, env } = deps;
  const ep = { authUrl: env.CHATGPT_AUTH_URL };

  /** One stable host id per server (never an email or a user id). */
  const hostId = async () => {
    await db.execute(sql`
      insert into public.instance_settings (key, value)
      values ('chatgpt_host_id', to_jsonb('urn:uuid:' || gen_random_uuid()::text))
      on conflict (key) do nothing`);
    const [row] = await db.execute<{ value: string }>(
      sql`select value #>> '{}' as value from public.instance_settings where key = 'chatgpt_host_id'`,
    );
    if (!row) throw new Error("chatgpt host id missing");
    return row.value;
  };

  app.openapi(routes.startChatGptSignIn, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const body = c.req.valid("json");
    if (!chatGptSignInEnabled(env))
      throw new ApiError(
        403,
        "chatgpt_sign_in_disabled",
        "ChatGPT plan sign-in is not available on this server",
      );
    const [{ member } = { member: false }] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ member: boolean }>(sql`select public.is_member(${body.org_id}::uuid) as member`),
    );
    if (!member) throw new ApiError(404, "org_not_found", "Workspace not found");

    let clientId = CHATGPT_DYNAMIC_CLIENT;
    let loginHint: string | undefined;
    if (body.credential_id) {
      const [cred] = await withUserSession(db, claims, (tx) =>
        tx
          .select()
          .from(modelCredentials)
          .where(eq(modelCredentials.id, body.credential_id ?? "")),
      );
      if (cred?.provider !== "chatgpt" || cred.orgId !== body.org_id)
        throw new ApiError(404, "credential_not_found", "Credential not found");
      if (cred.ownerUserId !== claims.sub)
        throw new ApiError(
          403,
          "forbidden",
          "Only the person who connected this plan can reconnect it",
        );
    }
    // A returning person reuses the client OpenAI issued them (never a new registration).
    const [prior] = await db.execute<{ client_id: string | null; email: string | null }>(sql`
      select oauth->>'client_id' as client_id, oauth->>'email' as email
      from public.model_credentials
      where provider = 'chatgpt' and owner_user_id = ${claims.sub}::uuid and oauth ? 'client_id'
      order by (id = ${body.credential_id ?? null}::uuid) desc nulls last, created_at desc limit 1`);
    if (prior?.client_id) clientId = prior.client_id;
    if (prior?.email) loginHint = prior.email;
    // OpenAI issues a client on the first callback even when the code exchange then fails, and its
    // docs say to retry with that issued id. Only the very next attempt does: the client is bound
    // to the account and workspace picked then, so if that retry never finishes (the person chose
    // another account and ChatGPT refused it on its own page), register again and let them pick.
    if (clientId === CHATGPT_DYNAMIC_CLIENT) {
      const [last] = await db.execute<{ client_id: string | null }>(sql`
        select oauth->>'issued_client_id' as client_id
        from public.integration_oauth_flows
        where app_id = 'chatgpt' and created_by = ${claims.sub}::uuid
        order by created_at desc limit 1`);
      if (last?.client_id) clientId = last.client_id;
    }

    const state = randomToken(32);
    const nonce = randomToken(24);
    const { verifier, challenge } = pkcePair();
    const redirectUri = `http://127.0.0.1:${body.redirect_port}/auth/callback`;
    const oauth: FlowOAuth = {
      kind: "chatgpt",
      code_verifier: verifier,
      nonce,
      redirect_uri: redirectUri,
      client_id: clientId,
      ...(body.credential_id ? { credential_id: body.credential_id } : {}),
    };
    const [flow] = await db.execute<{ expires_at: Date }>(sql`
      insert into public.integration_oauth_flows (state, org_id, created_by, app_id, name, oauth)
      values (${state}, ${body.org_id}::uuid, ${claims.sub}::uuid, 'chatgpt', 'ChatGPT', ${JSON.stringify(oauth)}::jsonb)
      returning expires_at`);
    const url = authorizeUrl(ep, {
      clientId,
      agentName: PRODUCT_NAME,
      hostId: await hostId(),
      redirectUri,
      state,
      nonce,
      challenge,
      loginHint,
    });
    return c.json(
      {
        authorize_url: url,
        redirect_uri: redirectUri,
        state,
        expires_at: new Date(flow?.expires_at ?? Date.now() + 900_000).toISOString(),
      },
      200,
    );
  });

  app.openapi(routes.completeChatGptSignIn, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const body = c.req.valid("json");
    // Sign-ins in progress are read with the server's role (RLS on, no policies), single use.
    const [flow] = await db.execute<{
      id: string;
      org_id: string;
      created_by: string | null;
      oauth: FlowOAuth;
      status: string;
      expired: boolean;
    }>(sql`
      select id, org_id, created_by, oauth, status, expires_at < now() as expired
      from public.integration_oauth_flows where state = ${body.state} and app_id = 'chatgpt'`);
    if (!flow || flow.created_by !== claims.sub)
      throw new ApiError(404, "sign_in_not_found", "This sign-in was not found. Start again.");
    if (flow.status !== "pending" || flow.expired)
      throw new ApiError(
        400,
        "sign_in_expired",
        "This sign-in expired or was already used. Start again.",
      );
    // The row keeps the code and the underlying reason, so a failed sign-in can be diagnosed later.
    const fail = async (code: string, message: string, detail = message) => {
      const reason = `${code}: ${detail}`.slice(0, 500);
      await db.execute(
        sql`update public.integration_oauth_flows set status = 'error', error = ${reason} where id = ${flow.id}::uuid`,
      );
      return new ApiError(400, code, message);
    };
    if (body.error || !body.code) {
      deps.logger.warn("chatgpt sign-in returned an error", {
        error: body.error ?? "no_code",
        description: body.error_description,
      });
      throw await fail(
        body.error === "access_denied" ? "chatgpt_sign_in_declined" : "chatgpt_sign_in_failed",
        body.error === "access_denied"
          ? "ChatGPT sign-in was cancelled."
          : `ChatGPT sign-in failed${body.error_description ? `: ${body.error_description}` : "."}`,
      );
    }
    const clientId = body.client_id ?? flow.oauth.client_id;
    if (body.client_id && body.client_id !== flow.oauth.client_id) {
      if (flow.oauth.client_id !== CHATGPT_DYNAMIC_CLIENT)
        throw await fail(
          "chatgpt_sign_in_failed",
          "ChatGPT returned a different client. Start again.",
          `expected ${flow.oauth.client_id}, got ${body.client_id}`,
        );
      // Kept before the exchange, so a retry after a failed exchange reuses this client.
      await db.execute(sql`
        update public.integration_oauth_flows
        set oauth = oauth || jsonb_build_object('issued_client_id', ${body.client_id}::text)
        where id = ${flow.id}::uuid`);
    }
    if (clientId === CHATGPT_DYNAMIC_CLIENT && !body.client_id)
      throw await fail(
        "chatgpt_sign_in_failed",
        "ChatGPT did not return a client id. Start again.",
      );

    let tokens: ReturnType<typeof tokensFrom>;
    let identity: { sub: string; email?: string };
    let scope: string | undefined;
    try {
      const resp = await exchangeCode(ep, {
        clientId,
        code: body.code,
        verifier: flow.oauth.code_verifier,
        redirectUri: flow.oauth.redirect_uri,
      });
      if (!resp.id_token) throw new ChatGptAuthError("ChatGPT returned no ID token", "invalid");
      const cfg = await openIdConfig(ep);
      const jwksUri = String(cfg.jwks_uri ?? `${env.CHATGPT_AUTH_URL}/.well-known/jwks.json`);
      let jwks = jwksCache.get(jwksUri);
      if (!jwks) {
        jwks = createRemoteJWKSet(new URL(jwksUri));
        jwksCache.set(jwksUri, jwks);
      }
      const { payload } = await jwtVerify(resp.id_token, jwks, {
        issuer: String(cfg.issuer ?? env.CHATGPT_AUTH_URL),
        audience: clientId,
      });
      if (payload.nonce !== flow.oauth.nonce)
        throw new ChatGptAuthError("ID token nonce mismatch", "invalid");
      if (typeof payload.sub !== "string")
        throw new ChatGptAuthError("ID token has no subject", "invalid");
      identity = {
        sub: payload.sub,
        email: typeof payload.email === "string" ? payload.email : undefined,
      };
      scope = resp.scope;
      tokens = tokensFrom(resp, clientId);
    } catch (err) {
      deps.logger.warn("chatgpt sign-in failed", { error: (err as Error).message });
      captureError(err, { service: "casama-api", step: "chatgpt-sign-in" });
      // OpenAI's guidance for a refused code: discard it and sign in again with the issued client,
      // which the next start picks up (issued_client_id above).
      const refused = err instanceof ChatGptAuthError && err.code === "invalid_grant";
      throw await fail(
        "chatgpt_sign_in_failed",
        refused
          ? "ChatGPT didn't accept this sign-in. Try again: the next one finishes setting up."
          : err instanceof ChatGptAuthError
            ? err.message
            : "ChatGPT sign-in could not be verified. Start again.",
        (err as Error).message,
      );
    }

    const status = scope === undefined || hasPlanScope(scope) ? "ok" : "plan_usage_off";
    const oauth = { client_id: clientId, sub: identity.sub, email: identity.email ?? null };
    const secret = JSON.stringify(tokens);
    const row = await db.transaction(async (tx) => {
      // Reconnect the given credential, or this person's existing plan for the same account.
      const [existing] = await tx.execute<{ id: string; vault_secret_id: string | null }>(sql`
        select id, vault_secret_id from public.model_credentials
        where provider = 'chatgpt' and org_id = ${flow.org_id}::uuid and owner_user_id = ${claims.sub}::uuid
          and (id = ${flow.oauth.credential_id ?? null}::uuid or oauth->>'sub' = ${identity.sub})
        order by (id = ${flow.oauth.credential_id ?? null}::uuid) desc nulls last limit 1`);
      let vaultId = existing?.vault_secret_id ?? null;
      if (vaultId) {
        await tx.execute(sql`select vault.update_secret(${vaultId}::uuid, ${secret})`);
      } else {
        const [created] = await tx.execute<{ id: string }>(
          sql`select vault.create_secret(${secret}, null, 'chatgpt plan') as id`,
        );
        vaultId = created?.id ?? null;
      }
      if (existing) {
        const [updated] = await tx
          .update(modelCredentials)
          .set({
            vaultSecretId: vaultId,
            status,
            oauth,
            refreshedAt: new Date().toISOString(),
          })
          .where(eq(modelCredentials.id, existing.id))
          .returning();
        return updated;
      }
      const [inserted] = await tx
        .insert(modelCredentials)
        .values({
          orgId: flow.org_id,
          provider: "chatgpt",
          label: "ChatGPT plan",
          vaultSecretId: vaultId,
          createdBy: claims.sub,
          ownerUserId: claims.sub,
          status,
          oauth,
          refreshedAt: new Date().toISOString(),
        })
        .returning();
      return inserted;
    });
    if (!row) throw new Error("chatgpt credential write returned nothing");
    await db.execute(
      sql`update public.integration_oauth_flows set status = 'connected' where id = ${flow.id}::uuid`,
    );
    await db.execute(sql`insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id, metadata)
      values (${row.orgId}::uuid, 'user', ${claims.sub}::uuid, 'credential.chatgpt_connected', 'model_credential', ${row.id}::uuid,
              ${JSON.stringify({ status })}::jsonb)`);
    return c.json(credOut(row), 200);
  });
}
