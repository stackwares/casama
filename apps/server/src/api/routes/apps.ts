/**
 * Built-in app connections (D-089). People pick an app (Stripe, Linear, Gmail…) and connect it in
 * one step: an API key is checked and saved at once; OAuth follows the MCP authorization spec
 * (protected-resource discovery, then dynamic client registration, a client metadata document or
 * an admin-registered client, with PKCE). The vendor redirects back to /oauth/callback, which
 * stores the tokens in Vault and lists the app's tools. Also: removing connections, tool risk
 * overrides, and guided Composio and Pipedream sign-ins.
 */
import { randomBytes } from "node:crypto";
import {
  composioDirectory,
  loadIntegration,
  milestone,
  oauthSecretFrom,
  pipedreamDirectory,
  refreshIntegration,
  track,
} from "@casama/agent";
import { routes } from "@casama/contracts";
import { pgErrorCode, schema, withUserSession } from "@casama/db";
import { APP_CATALOG, appByIdOrNull, type CatalogApp } from "@casama/domain";
import { captureError } from "@casama/observability";
import type { OpenAPIHono } from "@hono/zod-openapi";
import {
  discoverOAuthServerInfo,
  exchangeAuthorization,
  registerClient,
  startAuthorization,
} from "@modelcontextprotocol/sdk/client/auth.js";
import { and, eq, sql } from "drizzle-orm";
import type { Context } from "hono";
import { getConnectionSettings } from "../../services/connection-settings.ts";
import { type GalleryCatalogApp, galleryApps } from "../../services/gallery.ts";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { integrationOut, isAdmin, requireClaims } from "./autonomy.ts";

const { integrations } = schema;

type OAuthClient = { client_id: string; client_secret?: string };
/** Google's MCP servers share the server's one Google client (GOOGLE_OAUTH_CLIENT_ID). */
const isGoogleApp = (a: { id: string; category?: string }) =>
  a.category === "google" || a.id === "gmail_inbox";

export interface AppsOptions {
  /** Outbound fetch (tests point vendors at local fakes). */
  fetch?: typeof fetch;
  /** Extra or replacement catalog entries (tests, private deployments). */
  catalog?: CatalogApp[];
  /** Where gallery apps come from (D-239); tests serve gallery/ locally. Default: GALLERY_URL. */
  galleryFetch?: typeof fetch;
}

/** Admin-registered OAuth clients: MCP_OAUTH_CLIENTS (JSON by app id), and Google's own pair. */
export function preregisteredClients(
  env: AppDeps["env"],
  catalog: CatalogApp[] = APP_CATALOG,
): Record<string, OAuthClient> {
  let out: Record<string, OAuthClient> = {};
  if (env.MCP_OAUTH_CLIENTS) {
    try {
      out = JSON.parse(env.MCP_OAUTH_CLIENTS) as Record<string, OAuthClient>;
    } catch {
      // Ignored: a broken value shouldn't take the API down; the catalog shows OAuth as unavailable.
    }
  }
  if (env.GOOGLE_OAUTH_CLIENT_ID) {
    for (const { id } of catalog.filter(isGoogleApp))
      out[id] ??= {
        client_id: env.GOOGLE_OAUTH_CLIENT_ID,
        client_secret: env.GOOGLE_OAUTH_CLIENT_SECRET,
      };
  }
  return out;
}

/** The authorization server announces only `none` for its token endpoint (no client secrets). */
export function publicClientOnly(metadata?: { token_endpoint_auth_methods_supported?: string[] }) {
  const methods = metadata?.token_endpoint_auth_methods_supported;
  return !!methods?.length && methods.every((m) => m === "none");
}

/**
 * Where vendors send people back after signing in. Vendors only accept https or localhost, so a
 * server reached on a private network address over http (local development) comes back to
 * localhost on the same port: the sign-in then finishes in a browser on that machine.
 */
export function oauthRedirectFor(apiBase: string): string {
  const u = new URL(apiBase);
  const privateIp =
    /^(10\.|192\.168\.|172\.(1[6-9]|2\d|3[01])\.|169\.254\.)/.test(u.hostname) ||
    u.hostname.endsWith(".local");
  if (u.protocol === "http:" && privateIp) u.hostname = "localhost";
  return `${u.origin}/oauth/callback`;
}

/**
 * The catalog a server offers (D-172, like other agent apps do): an app whose own sign-in needs a
 * client this server doesn't have connects through Composio's sign-in on the server's Composio
 * account instead, when there is one. Google's apps (Developer Preview, D-166) go through Composio
 * whenever the server has it, even with a Google client, unless the owner chose Google's servers
 * (`googleDirect`, self-hosted only). On Casama Cloud they aren't offered without Composio.
 */
export function catalogFor<T extends CatalogApp>(
  catalog: T[],
  o: {
    cloud: boolean;
    composio: boolean;
    hasClient?: (id: string) => boolean;
    googleDirect?: boolean;
  },
): T[] {
  const hasClient = o.hasClient ?? (() => false);
  const googleViaComposio = o.cloud || !o.googleDirect;
  return catalog
    .filter((a) => !(o.cloud && a.category === "google" && !o.composio))
    .map((a) => {
      const ownSignIn =
        a.auth.includes("oauth") && (a.oauthClient !== "preregistered" || hasClient(a.id));
      const viaComposio =
        o.composio &&
        !!a.composio &&
        ((googleViaComposio && a.category === "google") ||
          (a.auth.includes("oauth") && !ownSignIn));
      if (!viaComposio) return a;
      return {
        ...a,
        auth: ["managed", ...a.auth.filter((m) => m !== "oauth")] as CatalogApp["auth"],
        oauthClient: undefined,
      };
    });
}

export function registerAppRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps, opts: AppsOptions = {}) {
  const { db, env } = deps;
  const fetchImpl = opts.fetch ?? fetch;
  const fullCatalog = opts.catalog ?? APP_CATALOG;
  // Casama Cloud's own Google app has no restricted scopes (D-130): inbox reading goes through
  // Composio's managed sign-in, or isn't offered when no Composio key is configured.
  const cloud = env.BILLING_ENABLED;
  const clients = preregisteredClients(env, [...fullCatalog, ...APP_CATALOG]);
  /** The server's Composio account is used when it has a key and the admin hasn't turned it off. */
  const serverComposio = async () =>
    !!env.COMPOSIO_API_KEY && (await getConnectionSettings(db)).composio === "server";
  /**
   * Built-in apps first, then the gallery's (D-239), which never replace one. The gallery's are
   * checked again on read and only connect through their own sign-in, a key or nothing.
   */
  const currentCatalog = async (): Promise<GalleryCatalogApp[]> => {
    const own = new Set(fullCatalog.map((a) => a.id));
    const extra = (await galleryApps(env, opts.galleryFetch)).filter((a) => !own.has(a.id));
    return catalogFor([...fullCatalog, ...extra], {
      cloud,
      composio: await serverComposio(),
      hasClient: (id) => !!clients[id],
      googleDirect: (await getConnectionSettings(db)).google === "direct",
    });
  };
  const findApp = async (id: string): Promise<GalleryCatalogApp | null> =>
    (await currentCatalog()).find((a) => a.id === id) ?? appByIdOrNull(id);

  const apiBase = (c: Context) =>
    (env.PUBLIC_API_URL ?? new URL(c.req.url).origin).replace(/\/$/, "");
  const redirectUri = (c: Context) => env.OAUTH_REDIRECT_URL ?? oauthRedirectFor(apiBase(c));
  const cimdUrl = (c: Context) => `${apiBase(c)}/oauth/client.json`;
  /**
   * Where Composio and Pipedream send the browser after a sign-in; names the connection to finish.
   * "app=1" comes first: a provider may append its own "?status=…" to the end of this address.
   */
  const doneUrl = (c: Context, integrationId: string, toApp = false) =>
    `${apiBase(c)}/oauth/done?${toApp ? "app=1&" : ""}integration=${encodeURIComponent(integrationId)}`;
  /** OAuth 2.1 servers only accept a return address on https, or on this machine (loopback). */
  const secureRedirect = (c: Context) => {
    const u = new URL(redirectUri(c));
    return u.protocol === "https:" || ["localhost", "127.0.0.1", "[::1]"].includes(u.hostname);
  };
  const oauthAvailable = (a: CatalogApp, c: Context) =>
    a.auth.includes("oauth") &&
    (a.oauthClient === "preregistered"
      ? !!clients[a.id]
      : a.oauthClient === "cimd"
        ? apiBase(c).startsWith("https://")
        : // Self-registration (dcr) is refused for a plain-http address such as a LAN IP.
          secureRedirect(c));

  const vault = async (value: string, description: string) => {
    const [r] = await db.execute<{ id: string }>(
      sql`select vault.create_secret(${value}, null, ${description}) as id`,
    );
    return r?.id as string;
  };

  /** A free integration name for an app: stripe, stripe_2, … */
  const freeName = async (orgId: string, base: string) => {
    const rows = await db.execute<{ name: string }>(
      sql`select name from public.integrations where org_id = ${orgId}::uuid and name like ${`${base}%`}`,
    );
    const taken = new Set(rows.map((r) => r.name));
    if (!taken.has(base)) return base;
    for (let i = 2; ; i++) if (!taken.has(`${base}_${i}`)) return `${base}_${i}`;
  };

  /** Saves a connection (new, or a reconnect replacing the credential) and lists its tools. */
  const saveConnection = async (args: {
    orgId: string;
    createdBy: string | null;
    app: CatalogApp;
    name: string;
    config: Record<string, unknown>;
    secret: string | null;
    integrationId?: string | null;
  }) => {
    const vaultId = args.secret ? await vault(args.secret, `integration ${args.app.id}`) : null;
    let id = args.integrationId ?? null;
    if (id) {
      const [old] = await db.execute<{ vault_secret_id: string | null }>(
        sql`select vault_secret_id from public.integrations where id = ${id}::uuid`,
      );
      await db.execute(sql`
        update public.integrations set config = ${JSON.stringify(args.config)}::jsonb, vault_secret_id = ${vaultId},
          status = 'pending', error = null where id = ${id}::uuid`);
      if (old?.vault_secret_id)
        await db.execute(sql`delete from vault.secrets where id = ${old.vault_secret_id}::uuid`);
    } else {
      try {
        const [row] = await db
          .insert(integrations)
          .values({
            orgId: args.orgId,
            kind: "mcp",
            name: args.name,
            config: args.config,
            vaultSecretId: vaultId,
            createdBy: args.createdBy,
          })
          .returning();
        id = row?.id ?? null;
      } catch (err) {
        if (pgErrorCode(err) === "23505")
          throw new ApiError(
            409 as never,
            "integration_exists",
            `${args.app.name} is already connected`,
          );
        throw err;
      }
    }
    if (!id) throw new Error("integration insert returned nothing");
    await refreshIntegration(db, id, { fetch: fetchImpl, secrets: [] });
    const [row] = await db.select().from(integrations).where(eq(integrations.id, id));
    // The connect funnel's server side (F4): did the connection come up? Ids and enums only.
    track(db, {
      event: row?.status === "ok" ? "connection_added" : "connection_failed",
      userId: args.createdBy,
      orgId: args.orgId,
      properties: {
        app_id: args.app.id,
        reconnect: Boolean(args.integrationId),
        ...(row?.status === "ok" ? {} : { reason: "connect_error" }),
      },
    });
    if (row?.status === "ok") milestone(db, args.createdBy, "first_connection", args.orgId);
    const bots = await db.execute<{ bot_id: string }>(
      sql`select bot_id from public.bot_integrations where integration_id = ${id}::uuid`,
    );
    return integrationOut(
      row!,
      bots.map((b) => b.bot_id),
    );
  };

  // ------------------------------------------------------------------ catalog

  app.openapi(routes.listApps, async (c) => {
    requireClaims(c.get("claims"));
    return c.json(
      {
        redirect_uri: redirectUri(c),
        apps: (await currentCatalog()).map((a) => ({
          id: a.id,
          name: a.name,
          description: a.description,
          category: a.category,
          color: a.color,
          homepage: a.homepage,
          url: a.url,
          auth: a.auth,
          ...(a.apiKey
            ? {
                api_key: {
                  label: a.apiKey.label,
                  placeholder: a.apiKey.placeholder,
                  url: a.apiKey.url,
                  steps: a.apiKey.steps,
                },
              }
            : {}),
          capabilities: a.capabilities,
          popular: a.popular ?? false,
          ...(a.note ? { note: a.note } : {}),
          oauth_available: oauthAvailable(a, c),
          ...(a.composio ? { composio: a.composio } : {}),
          ...(a.logoUrl ? { logo_url: a.logoUrl } : {}),
        })),
      },
      200,
    );
  });

  // Casama's OAuth client metadata document (for servers that use CIMD instead of registration).
  app.get("/oauth/client.json", (c) =>
    c.json({
      client_id: cimdUrl(c),
      client_name: "Casama",
      client_uri: env.PUBLIC_APP_URL,
      redirect_uris: [redirectUri(c)],
      grant_types: ["authorization_code", "refresh_token"],
      response_types: ["code"],
      token_endpoint_auth_method: "none",
    }),
  );

  // ------------------------------------------------------------------ connect

  app.openapi(routes.connectApp, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const body = c.req.valid("json");
    const a = await findApp(body.app_id);
    if (!a) throw new ApiError(404, "app_not_found", "No such app");
    if (!(await isAdmin(db, claims, body.org_id)))
      throw new ApiError(403, "forbidden", "Only owners and admins can connect apps");
    if (
      !a.auth.includes(body.method) &&
      !(body.method === "managed" && a.composio && (await serverComposio()))
    )
      throw new ApiError(400, "validation_failed", `${a.name} can't connect that way`);
    if (body.integration_id) {
      const [own] = await db.execute<{ ok: boolean }>(
        sql`select exists(select 1 from public.integrations where id = ${body.integration_id}::uuid and org_id = ${body.org_id}::uuid) as ok`,
      );
      if (!own?.ok) throw new ApiError(404, "integration_not_found", "Integration not found");
    }
    const name = body.integration_id ? a.id : await freeName(body.org_id, a.id);
    const config: Record<string, unknown> = { url: a.url, app: a.id, auth: body.method };

    if (body.method === "managed") {
      // Composio's sign-in on the server's own Composio account, one Composio user per workspace,
      // one connection ("apps") that gains each app's tools as it's connected (D-172).
      if (!env.COMPOSIO_API_KEY)
        throw new ApiError(400, "managed_unavailable", `${a.name} isn't available on this server`);
      const slug = a.composio ?? a.id;
      let [row] = await db.execute<{ id: string }>(
        sql`select id from public.integrations where org_id = ${body.org_id}::uuid and kind = 'composio' and config ->> 'managed' = 'true' limit 1`,
      );
      if (!row) {
        const secretId = await vault(env.COMPOSIO_API_KEY, "composio managed");
        [row] = await db.execute<{ id: string }>(sql`
          insert into public.integrations (org_id, kind, name, config, vault_secret_id, created_by)
          values (${body.org_id}::uuid, 'composio', ${await freeName(body.org_id, "apps")},
                  ${JSON.stringify({ managed: true, toolkits: [], ...(env.COMPOSIO_API_URL ? { base_url: env.COMPOSIO_API_URL } : {}) })}::jsonb,
                  ${secretId}::uuid, ${claims.sub}::uuid)
          returning id`);
      }
      const rec = await loadIntegration(db, row?.id as string, fetchImpl);
      if (!rec) throw new Error("managed integration missing");
      let out: { redirect_url: string };
      try {
        out = await composioDirectory(rec, fetchImpl).connect(
          slug,
          doneUrl(c, row?.id as string, body.return_to_app === true),
        );
      } catch (err) {
        throw new ApiError(400, "provider_error", (err as Error).message.slice(0, 300));
      }
      // The cached tool list predates this app: clear it so the next run (or the app's check once
      // the sign-in finishes) lists the new app's tools instead of waiting a day for the cache.
      await db.execute(sql`
        update public.integrations set config = jsonb_set(config, '{toolkits}', (
          select to_jsonb(array(select distinct x from jsonb_array_elements_text(coalesce(config -> 'toolkits', '[]'::jsonb) || to_jsonb(${slug}::text)) x)))
        ), tools_cached_at = null where id = ${row?.id}::uuid`);
      const [irow] = await db
        .select()
        .from(integrations)
        .where(eq(integrations.id, row?.id as string));
      return c.json(
        {
          status: "authorize" as const,
          authorize_url: out.redirect_url,
          integration: integrationOut(irow!, []),
        },
        200,
      );
    }

    if (body.method !== "oauth") {
      if (body.method === "api_key" && !body.api_key)
        throw new ApiError(400, "validation_failed", "Paste the key first", {
          errors: [{ path: "api_key", message: "Required" }],
        });
      if (a.apiKey?.header) config.auth_header = a.apiKey.header;
      const integration = await saveConnection({
        orgId: body.org_id,
        createdBy: claims.sub,
        app: a,
        name,
        config,
        secret: body.method === "api_key" ? (body.api_key ?? null) : null,
        integrationId: body.integration_id,
      });
      return c.json(
        (integration.status as string) === "error"
          ? {
              status: "error" as const,
              integration,
              error: integration.error ?? "Couldn't connect",
            }
          : { status: "connected" as const, integration },
        200,
      );
    }

    if (!oauthAvailable(a, c))
      throw new ApiError(
        400,
        "oauth_unavailable",
        a.oauthClient === "preregistered"
          ? `${a.name} needs an OAuth client set up on this server first (MCP_OAUTH_CLIENTS).`
          : `${a.name} sign-in needs this server to have a public https address (PUBLIC_API_URL).`,
      );
    try {
      const info = await discoverOAuthServerInfo(a.url, { fetchFn: fetchImpl as never });
      const metadata = info.authorizationServerMetadata;
      const resource = info.resourceMetadata?.resource;
      // Scopes the catalog chose win over what the server announces (Google's include full mailbox
      // access, GitHub's include publishing packages); an empty list sends none (Asana rejects
      // any scope). Apps without a choice follow what the server announces.
      const announced = (info.resourceMetadata?.scopes_supported as string[] | undefined)?.join(
        " ",
      );
      const scopes =
        a.scopes !== undefined ? (a.scopes.length ? a.scopes.join(" ") : undefined) : announced;
      let client: OAuthClient | undefined = clients[a.id];
      if (!client && a.oauthClient === "cimd") client = { client_id: cimdUrl(c) };
      if (!client) {
        if (!metadata?.registration_endpoint)
          throw new Error(
            `${a.name} doesn't allow automatic sign-up; an admin must register an OAuth client`,
          );
        client = await registerClient(info.authorizationServerUrl, {
          metadata,
          clientMetadata: {
            client_name: "Casama",
            client_uri: env.PUBLIC_APP_URL,
            redirect_uris: [redirectUri(c)],
            grant_types: ["authorization_code", "refresh_token"],
            response_types: ["code"],
            // A server that takes no client secret at its token endpoint gets asked for a public
            // client: Composio otherwise registers a confidential one with a secret, the SDK then
            // follows the announced methods and sends none, and the token exchange fails with
            // "Missing client_secret".
            ...(publicClientOnly(metadata) ? { token_endpoint_auth_method: "none" } : {}),
          },
          scope: scopes,
          fetchFn: fetchImpl as never,
        });
      }
      const state = randomBytes(24).toString("base64url");
      const { authorizationUrl, codeVerifier } = await startAuthorization(
        info.authorizationServerUrl,
        {
          metadata,
          clientInformation: client as never,
          redirectUrl: redirectUri(c),
          scope: scopes,
          state,
          resource: resource ? new URL(resource) : undefined,
        },
      );
      // Google only issues a refresh token when asked for offline access.
      // Each Google app is its own connection with only its own scopes (no incremental grants,
      // which would widen every token to all the Google apps connected before).
      if (isGoogleApp(a)) {
        authorizationUrl.searchParams.set("access_type", "offline");
        authorizationUrl.searchParams.set("prompt", "consent");
        // The account they signed in to Casama with, so Google skips its account chooser (D-204).
        if (typeof claims.email === "string" && claims.email)
          authorizationUrl.searchParams.set("login_hint", claims.email);
      }
      const [flow] = await db.execute<{ id: string }>(sql`
        insert into public.integration_oauth_flows (state, org_id, created_by, app_id, name, config, oauth, integration_id)
        values (${state}, ${body.org_id}::uuid, ${claims.sub}::uuid, ${a.id}, ${name}, ${JSON.stringify(config)}::jsonb,
          ${JSON.stringify({
            auth_server: String(info.authorizationServerUrl),
            metadata,
            client,
            code_verifier: codeVerifier,
            redirect_uri: redirectUri(c),
            resource,
            ...(body.return_to_app ? { return_to_app: true } : {}),
          })}::jsonb, ${body.integration_id ?? null})
        returning id`);
      return c.json(
        {
          status: "authorize" as const,
          authorize_url: authorizationUrl.toString(),
          flow_id: flow!.id,
        },
        200,
      );
    } catch (err) {
      if (err instanceof ApiError) throw err;
      deps.logger.warn("oauth start failed", { app: a.id, error: (err as Error).message });
      captureError(err, { service: "casama-api", step: "oauth-start", app_id: a.id });
      return c.json(
        {
          status: "error" as const,
          error: `Couldn't start ${a.name} sign-in: ${(err as Error).message}`,
        },
        200,
      );
    }
  });

  app.openapi(routes.connectStatus, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const [flow] = await db.execute<{
      org_id: string;
      created_by: string | null;
      status: string;
      error: string | null;
      integration_id: string | null;
      expired: boolean;
    }>(sql`
      select org_id, created_by, status, error, integration_id, expires_at < now() as expired
      from public.integration_oauth_flows where id = ${id}::uuid`);
    if (!flow || flow.created_by !== claims.sub)
      throw new ApiError(404, "flow_not_found", "Sign-in not found");
    if (flow.status === "connected" && flow.integration_id) {
      const [row] = await db
        .select()
        .from(integrations)
        .where(eq(integrations.id, flow.integration_id));
      const bots = await db.execute<{ bot_id: string }>(
        sql`select bot_id from public.bot_integrations where integration_id = ${flow.integration_id}::uuid`,
      );
      if (row)
        return c.json(
          {
            status: "connected" as const,
            integration: integrationOut(
              row,
              bots.map((b) => b.bot_id),
            ),
          },
          200,
        );
    }
    if (flow.status === "error")
      return c.json({ status: "error" as const, error: flow.error ?? "Sign-in failed" }, 200);
    return c.json({ status: flow.expired ? ("expired" as const) : ("pending" as const) }, 200);
  });

  // The vendor sends the browser here after sign-in. Public: the state is the credential.
  app.get("/oauth/callback", async (c) => {
    const state = c.req.query("state") ?? "";
    const [flow] = await db.execute<{
      id: string;
      org_id: string;
      created_by: string | null;
      app_id: string;
      name: string;
      config: Record<string, unknown>;
      oauth: {
        auth_server: string;
        metadata?: Record<string, unknown>;
        client: OAuthClient;
        code_verifier: string;
        redirect_uri: string;
        resource?: string;
        return_to_app?: boolean;
      };
      integration_id: string | null;
    }>(sql`
      update public.integration_oauth_flows set status = 'error', error = 'in progress'
      where state = ${state} and status = 'pending' and expires_at > now()
      returning id, org_id, created_by, app_id, name, config, oauth, integration_id`);
    const a = flow ? await findApp(flow.app_id) : null;
    if (!flow || !a)
      return c.html(
        resultPage("This sign-in link has expired. Go back to Casama and try again.", false),
        400,
      );
    const fail = async (message: string, reason = "oauth_error") => {
      await db.execute(
        sql`update public.integration_oauth_flows set status = 'error', error = ${message.slice(0, 500)} where id = ${flow.id}::uuid`,
      );
      track(db, {
        event: "connection_failed",
        userId: flow.created_by,
        orgId: flow.org_id,
        properties: { app_id: a.id, method: "oauth", reason },
      });
      if (flow.oauth.return_to_app) return c.redirect(appReturn("error"), 302);
      return c.html(resultPage(message, false), 400);
    };
    const denied = c.req.query("error");
    if (denied)
      return fail(
        `${a.name} sign-in was cancelled (${c.req.query("error_description") ?? denied}).`,
        "cancelled",
      );
    const code = c.req.query("code");
    if (!code) return fail(`${a.name} didn't send a sign-in code.`);
    try {
      const o = flow.oauth;
      const tokens = await exchangeAuthorization(o.auth_server, {
        metadata: o.metadata as never,
        clientInformation: o.client as never,
        authorizationCode: code,
        codeVerifier: o.code_verifier,
        redirectUri: o.redirect_uri,
        resource: o.resource ? new URL(o.resource) : undefined,
        fetchFn: fetchImpl as never,
      });
      const secret = oauthSecretFrom(tokens, {
        auth_server: o.auth_server,
        metadata: o.metadata,
        client: o.client,
        resource: o.resource,
      });
      const integration = await saveConnection({
        orgId: flow.org_id,
        createdBy: flow.created_by,
        app: a,
        name: flow.name,
        config: flow.config,
        secret: JSON.stringify(secret),
        integrationId: flow.integration_id,
      });
      await db.execute(sql`
        update public.integration_oauth_flows set status = 'connected', error = null, integration_id = ${integration.id}::uuid,
          oauth = oauth - 'code_verifier' - 'client' where id = ${flow.id}::uuid`);
      if (flow.oauth.return_to_app) return c.redirect(appReturn("ok"), 302);
      return c.html(
        resultPage(
          `${a.name} is connected. You can close this window and go back to Casama.`,
          true,
        ),
      );
    } catch (err) {
      deps.logger.warn("oauth callback failed", { app: a.id, error: (err as Error).message });
      captureError(err, { service: "casama-api", step: "oauth-callback", app_id: a.id });
      return fail(`Couldn't finish connecting ${a.name}: ${(err as Error).message}`);
    }
  });

  // ------------------------------------------------------------------ manage

  const ownIntegration = async (c: Context<AppEnv>, id: string, admin = true) => {
    const claims = requireClaims(c.get("claims"));
    const [row] = await withUserSession(db, claims, (tx) =>
      tx.select().from(integrations).where(eq(integrations.id, id)),
    );
    if (!row) throw new ApiError(404, "integration_not_found", "Integration not found");
    if (admin && !(await isAdmin(db, claims, row.orgId)))
      throw new ApiError(403, "forbidden", "Only owners and admins can change integrations");
    return row;
  };

  app.openapi(routes.updateIntegration, async (c) => {
    const { id } = c.req.valid("param");
    await ownIntegration(c, id);
    const body = c.req.valid("json");
    if (body.risk_overrides)
      await db
        .update(integrations)
        .set({ riskOverrides: body.risk_overrides })
        .where(eq(integrations.id, id));
    const [row] = await db.select().from(integrations).where(eq(integrations.id, id));
    return c.json(integrationOut(row!), 200);
  });

  app.openapi(routes.deleteIntegration, async (c) => {
    const { id } = c.req.valid("param");
    const row = await ownIntegration(c, id);
    await db
      .delete(integrations)
      .where(and(eq(integrations.id, id), eq(integrations.orgId, row.orgId)));
    if (row.vaultSecretId)
      await db.execute(sql`delete from vault.secrets where id = ${row.vaultSecretId}::uuid`);
    return c.json({ ok: true }, 200);
  });

  // ------------------------------------------------- Composio and Pipedream

  const directory = async (c: Context<AppEnv>, id: string, admin = false) => {
    const row = await ownIntegration(c, id, admin);
    if (row.kind !== "composio" && row.kind !== "pipedream")
      throw new ApiError(
        400,
        "not_a_provider",
        "Only Composio and Pipedream connections have an app directory",
      );
    const rec = await loadIntegration(db, id, fetchImpl);
    if (!rec) throw new ApiError(404, "integration_not_found", "Integration not found");
    return {
      row,
      rec,
      dir:
        row.kind === "composio"
          ? composioDirectory(rec, fetchImpl)
          : pipedreamDirectory(rec, fetchImpl),
    };
  };
  const providerError = (err: unknown) =>
    new ApiError(400, "provider_error", (err as Error).message.slice(0, 300));

  app.openapi(routes.listProviderApps, async (c) => {
    const { dir } = await directory(c, c.req.valid("param").id);
    try {
      return c.json({ items: await dir.apps(c.req.valid("query").q ?? "") }, 200);
    } catch (err) {
      throw providerError(err);
    }
  });

  app.openapi(routes.connectProviderApp, async (c) => {
    const { id } = c.req.valid("param");
    const { row, dir } = await directory(c, id, true);
    const { app: slug, return_to_app } = c.req.valid("json");
    try {
      const out = await dir.connect(slug, doneUrl(c, id, return_to_app === true));
      // The app's tools become available to bots once it's on the list.
      const config = row.config as Record<string, unknown>;
      const key = row.kind === "composio" ? "toolkits" : "apps";
      const list = new Set([...((config[key] as string[]) ?? []), slug]);
      await db
        .update(integrations)
        .set({ config: { ...config, [key]: [...list] }, toolsCachedAt: null })
        .where(eq(integrations.id, id));
      return c.json(out, 200);
    } catch (err) {
      throw providerError(err);
    }
  });

  app.openapi(routes.listProviderAccounts, async (c) => {
    const { dir } = await directory(c, c.req.valid("param").id);
    try {
      return c.json({ items: await dir.accounts() }, 200);
    } catch (err) {
      throw providerError(err);
    }
  });

  // Where Composio and Pipedream send people after signing in.
  // The app also watches for the sign-in, but Android can stop it while the browser is open; then
  // nothing would list the new app's tools and the connection would stay "pending". So the
  // server finishes it here too. Only a connection still waiting for its tools is refreshed, so
  // this unauthenticated page can't be used to make the server call the provider at will.
  // From the app's sign-in sheet ("app=1"), it ends on casama-auth://done, which closes the sheet.
  app.get("/oauth/done", async (c) => {
    // Leading match: a provider may append its own "?status=…" to a return address that has a query.
    const id = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/i.exec(
      c.req.query("integration") ?? "",
    )?.[0];
    if (id) {
      const [row] = await db
        .execute<{ id: string }>(sql`
          select id from public.integrations
          where id = ${id}::uuid and kind in ('composio', 'pipedream')
            and (status = 'pending' or (status = 'ok' and tools_cached_at is null))`)
        .catch(() => []);
      if (row)
        void refreshIntegration(db, row.id, { fetch: fetchImpl, secrets: [] }).catch((err) =>
          deps.logger.warn("sign-in refresh failed", {
            integration_id: row.id,
            error: (err as Error).message,
          }),
        );
    }
    if (c.req.query("app")?.startsWith("1")) {
      // A provider may add its own "?status=failed" after our address; the app checks either way.
      const failed = /status=(failed|error)/i.test(new URL(c.req.url).search);
      return c.redirect(appReturn(failed ? "error" : "ok"), 302);
    }
    return c.html(
      resultPage("You're signed in. You can close this window and go back to Casama.", true),
    );
  });
}

/**
 * The end of a sign-in started from the app's sign-in sheet (ASWebAuthenticationSession, Custom
 * Tabs): reaching this address closes the sheet. A fixed address, so this is never an open redirect.
 */
function appReturn(status: "ok" | "error") {
  return `casama-auth://done?status=${status}`;
}

/** A small page shown in the browser after a sign-in; it tries to close itself. */
function resultPage(message: string, ok: boolean) {
  const esc = message.replace(
    /[&<>"]/g,
    (ch) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[ch]!,
  );
  return `<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Casama</title><style>
:root{color-scheme:light dark}body{margin:0;min-height:100vh;display:grid;place-items:center;font:16px/1.5 system-ui,sans-serif;background:linear-gradient(160deg,#efe4fb,#dcebff);color:#1c1530}
@media (prefers-color-scheme:dark){body{background:linear-gradient(160deg,#25102f,#151f3f);color:#f3eefc}}
main{max-width:420px;margin:24px;padding:32px;border-radius:24px;background:rgba(255,255,255,.7);text-align:center;box-shadow:0 20px 60px rgba(60,20,120,.18)}
@media (prefers-color-scheme:dark){main{background:rgba(30,20,50,.7)}}
.icon{width:56px;height:56px;border-radius:50%;margin:0 auto 16px;display:grid;place-items:center;font-size:28px;color:#fff;background:${ok ? "#22a06b" : "#d9534f"}}
h1{font-size:20px;margin:0 0 8px}</style></head><body><main><div class="icon">${ok ? "&#10003;" : "!"}</div>
<h1>${ok ? "All set" : "Something went wrong"}</h1><p>${esc}</p></main>
<script>${ok ? "setTimeout(function(){window.close()},1500)" : ""}</script></body></html>`;
}
