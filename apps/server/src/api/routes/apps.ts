/**
 * Built-in app connections (D-089). People pick an app (Stripe, Linear, Gmail…) and connect it in
 * one step: an API key is checked and saved at once; OAuth follows the MCP authorization spec
 * (protected-resource discovery, then dynamic client registration, a client metadata document or
 * an admin-registered client, with PKCE). The vendor redirects back to /oauth/callback, which
 * stores the tokens in Vault and lists the app's tools. Also: removing connections, tool risk
 * overrides, and guided Composio and Pipedream sign-ins.
 */
import { createHash, randomBytes } from "node:crypto";
import {
  composioDirectory,
  discoverZoho,
  loadIntegration,
  milestone,
  oauthSecretFrom,
  pipedreamDirectory,
  refreshIntegration,
  track,
  ZOHO_SCOPES,
  zohoAccountsServerOk,
  zohoServiceBases,
} from "@casama/agent";
import { routes } from "@casama/contracts";
import { pgErrorCode, schema, withUserSession } from "@casama/db";
import {
  APP_CATALOG,
  appByIdOrNull,
  appServerUrl,
  type CatalogApp,
  CHAT_SERVER_LIMIT,
  CUSTOM_APP,
  curateCatalog,
  customServerUrl,
  serverKey,
  serverSlug,
} from "@casama/domain";
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
import { appLogos } from "../../services/app-logos.ts";
import { getConnectionSettings } from "../../services/connection-settings.ts";
import { type GalleryCatalogApp, galleryApps, galleryLists } from "../../services/gallery.ts";
import { linkGalleryInstallQuietly } from "../../services/gallery-usage.ts";
import { packApps } from "../../services/pack-apps.ts";
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
  if (env.ZOHO_OAUTH_CLIENT_ID && env.ZOHO_OAUTH_CLIENT_SECRET) {
    for (const { id } of catalog.filter((a) => a.provider === "zoho"))
      out[id] ??= {
        client_id: env.ZOHO_OAUTH_CLIENT_ID,
        client_secret: env.ZOHO_OAUTH_CLIENT_SECRET,
      };
  }
  return out;
}

/** The authorization server announces only `none` for its token endpoint (no client secrets). */
export function publicClientOnly(metadata?: { token_endpoint_auth_methods_supported?: string[] }) {
  const methods = metadata?.token_endpoint_auth_methods_supported;
  return !!methods?.length && methods.every((m) => m === "none");
}

/** Marks a sign-in the callback is finishing; connectStatus reports it as still pending. */
const FLOW_IN_PROGRESS = "in progress";

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
  return (
    catalog
      .filter((a) => !(o.cloud && a.category === "google" && !o.composio))
      // Apps that only connect through Composio's managed sign-in (Zoho's, D-349) need Composio.
      .filter((a) => o.composio || a.auth.some((m) => m !== "managed"))
      // Casama's own Zoho sign-in (D-350) needs the server's Zoho client, and replaces the
      // Composio tiles where it's set up.
      .filter((a) => !(a.hiddenWithoutClient && !hasClient(a.id)))
      .filter((a) => !(a.replacedBy && hasClient(a.replacedBy)))
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
      })
  );
}

/**
 * Finishes a Zoho sign-in (D-350): trades the code at the person's own data centre (checked
 * against Zoho's list, so a forged callback can't send our client secret elsewhere), then finds
 * which of Mail, CRM, Desk and Books the account has. Refreshes go to the same accounts server
 * through the generic OAuth refresh, so the secret carries its token endpoint as metadata.
 */
export async function finishZohoSignIn(o: {
  fetch: typeof fetch;
  code: string;
  oauth: { client: OAuthClient; code_verifier: string; redirect_uri: string };
  accountsServer: string;
  configured: string;
}) {
  const server = o.accountsServer.replace(/\/$/, "");
  if (!zohoAccountsServerOk(server, o.configured))
    throw new Error("Zoho sent the sign-in back from an unknown accounts server");
  const tokenEndpoint = `${server}/oauth/v2/token`;
  const res = await o.fetch(tokenEndpoint, {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded", accept: "application/json" },
    body: new URLSearchParams({
      grant_type: "authorization_code",
      code: o.code,
      client_id: o.oauth.client.client_id,
      client_secret: o.oauth.client.client_secret ?? "",
      redirect_uri: o.oauth.redirect_uri,
      code_verifier: o.oauth.code_verifier,
    }),
  });
  const tok = (await res.json().catch(() => ({}))) as {
    access_token?: string;
    refresh_token?: string;
    expires_in?: number;
    api_domain?: string;
    error?: string;
  };
  // Zoho answers token errors with HTTP 200 and an `error` field.
  if (!res.ok || !tok.access_token)
    throw new Error(`Zoho refused the sign-in (${tok.error ?? `HTTP ${res.status}`})`);
  const apiDomain = (tok.api_domain ?? "https://www.zohoapis.com").replace(/\/$/, "");
  // CRM and Books are called on api_domain: only Zoho's API hosts (or the configured stand-in).
  const apiHost = new URL(apiDomain);
  if (
    !(apiHost.protocol === "https:" && /(^|\.)zohoapis\.[a-z.]+$/.test(apiHost.hostname)) &&
    apiHost.origin !== new URL(o.configured).origin
  )
    throw new Error("Zoho sent an unexpected API address");
  const zoho = await discoverZoho(o.fetch, tok.access_token, {
    accounts_server: server,
    api_domain: apiDomain,
    ...zohoServiceBases(server),
  });
  if (!zoho.mail && !zoho.crm && !zoho.desk && !zoho.books)
    throw new Error("This Zoho account has none of Mail, CRM, Desk or Books set up");
  const secret = oauthSecretFrom(
    {
      access_token: tok.access_token,
      refresh_token: tok.refresh_token,
      expires_in: tok.expires_in,
    },
    {
      auth_server: server,
      metadata: {
        issuer: server,
        authorization_endpoint: `${server}/oauth/v2/auth`,
        token_endpoint: tokenEndpoint,
        response_types_supported: ["code"],
        grant_types_supported: ["authorization_code", "refresh_token"],
        token_endpoint_auth_methods_supported: ["client_secret_post"],
      },
      client: o.oauth.client,
    },
  );
  return { secret, config: { provider: "zoho", url: server, zoho } };
}

export function registerAppRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps, opts: AppsOptions = {}) {
  const { db, env } = deps;
  const fetchImpl = opts.fetch ?? fetch;
  const fullCatalog = opts.catalog ?? APP_CATALOG;
  // Casama Cloud's own Google app has no restricted scopes (D-130): inbox reading goes through
  // Composio's managed sign-in, or isn't offered when no Composio key is configured.
  const cloud = env.BILLING_ENABLED;
  const clients = preregisteredClients(env, [...fullCatalog, ...APP_CATALOG]);
  const builtInIds = new Set([...fullCatalog, ...APP_CATALOG].map((a) => a.id));
  /** The server's Composio account is used when it has a key and the admin hasn't turned it off. */
  const serverComposio = async () =>
    !!env.COMPOSIO_API_KEY && (await getConnectionSettings(db)).composio === "server";
  /**
   * Built-in apps first, then the gallery's (D-239), which never replace one. The gallery's are
   * checked again on read and only connect through their own sign-in, a key or nothing.
   */
  const currentCatalog = async (orgId?: string): Promise<GalleryCatalogApp[]> => {
    const own = new Set(fullCatalog.map((a) => a.id));
    const extra = (await galleryApps(env, opts.galleryFetch)).filter((a) => !own.has(a.id));
    // A workspace's packs bring their own apps (`<pack>.<app>`), shown only in that workspace.
    const fromPacks = orgId ? await packApps(db, orgId) : [];
    // The gallery's curation (D-372): names, descriptions, colors, Popular and order of built-in
    // apps only. Sign-in details never come from it.
    const curation = (await galleryLists(env, opts.galleryFetch).catch(() => null))?.appCuration;
    const base = curateCatalog([...fullCatalog, ...extra, ...fromPacks], curation, builtInIds);
    return catalogFor(base, {
      cloud,
      composio: await serverComposio(),
      hasClient: (id) => !!clients[id],
      googleDirect: (await getConnectionSettings(db)).google === "direct",
    });
  };
  const findApp = async (id: string, orgId?: string): Promise<GalleryCatalogApp | null> =>
    (await currentCatalog(orgId)).find((a) => a.id === id) ?? appByIdOrNull(id);

  const apiBase = (c: Context) =>
    (env.PUBLIC_API_URL ?? new URL(c.req.url).origin).replace(/\/$/, "");
  const redirectUri = (c: Context) => env.OAUTH_REDIRECT_URL ?? oauthRedirectFor(apiBase(c));
  const cimdUrl = (c: Context) => `${apiBase(c)}/oauth/client.json`;
  /** A built-in app's mark on this API, or undefined (gallery and pack apps bring their own). */
  const builtInLogoUrl = (c: Context, id: string) => {
    const logo = builtInIds.has(id) ? appLogos().get(id) : undefined;
    return logo ? `${apiBase(c)}/v1/apps/logos/${id}.svg?v=${logo.version}` : undefined;
  };
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
  const freeName = async (orgId: string, rawBase: string) => {
    // An extra catalog's app id is `source:id` (D-315); connection names keep to tool-name characters.
    const base = rawBase.replace(/[^a-z0-9_-]/gi, "_");
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
    // Offered by a bot in a chat (D-473): the person tapped that bot's card, so it gets it.
    const offeredBy = args.config.added_in_chat_by;
    if (typeof offeredBy === "string" && !args.integrationId)
      await db.execute(sql`
        insert into public.bot_integrations (org_id, bot_id, integration_id)
        select ${args.orgId}::uuid, b.id, ${id}::uuid from public.bots b
        where b.id = ${offeredBy}::uuid and b.org_id = ${args.orgId}::uuid
        on conflict do nothing`);
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
        ...(row?.status === "ok" ? {} : { reason: "link_error" }),
      },
    });
    if (row?.status === "ok") milestone(db, args.createdBy, "first_connection", args.orgId);
    // A gallery app (D-315): remember it for Installed and updates, and count the person.
    if (row?.status === "ok" && !builtInIds.has(args.app.id) && args.app.id !== CUSTOM_APP)
      await linkGalleryInstallQuietly(
        db,
        env,
        {
          orgId: args.orgId,
          userId: args.createdBy,
          type: "app",
          id: args.app.id,
          targetKind: "app",
          targetId: id,
          version: (args.app as GalleryCatalogApp).version,
          access: (args.app as GalleryCatalogApp).access,
        },
        (m, e) => deps.logger.warn(m, e),
      );
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
    const claims = requireClaims(c.get("claims"));
    const orgId = c.req.valid("query").org_id;
    const member = orgId
      ? (
          await withUserSession(db, claims, (tx) =>
            tx.execute<{ ok: boolean }>(sql`select public.is_member(${orgId}::uuid) as ok`),
          )
        )[0]?.ok
      : false;
    const starterApps = (await galleryLists(env, opts.galleryFetch).catch(() => null))?.appCuration
      ?.starter_apps;
    return c.json(
      {
        redirect_uri: redirectUri(c),
        ...(starterApps?.length ? { starter_apps: starterApps } : {}),
        apps: (await currentCatalog(member ? orgId : undefined)).map((a) => ({
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
          ...(a.logoUrl
            ? { logo_url: a.logoUrl }
            : builtInLogoUrl(c, a.id)
              ? { logo_url: builtInLogoUrl(c, a.id) }
              : {}),
        })),
      },
      200,
    );
  });

  // Built-in apps' marks, for apps built before the mark was bundled (see services/app-logos.ts).
  // Only ids with a file are served, so the path can't name anything else.
  app.get("/v1/apps/logos/:file", (c) => {
    const m = /^([a-z0-9_]+)\.svg$/.exec(c.req.param("file"));
    const logo = m ? appLogos().get(m[1]!) : undefined;
    if (!logo) return c.text("Not found", 404);
    return c.body(logo.svg, 200, {
      "content-type": "image/svg+xml; charset=utf-8",
      "cache-control": "public, max-age=86400",
      "x-content-type-options": "nosniff",
      // Opened directly it's still just a picture: no scripts, nothing loaded from elsewhere.
      "content-security-policy": "default-src 'none'; style-src 'unsafe-inline'; sandbox",
    });
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

  /** A server outside the catalog (D-473), in the shape the connect code takes. */
  const customApp = (label: string, url: string): CatalogApp => ({
    id: CUSTOM_APP,
    name: label,
    description: "",
    category: "developer",
    color: "64748B",
    homepage: new URL(url).origin,
    url,
    auth: ["oauth", "api_key", "none"],
    oauthClient: "dcr",
    capabilities: [],
  });

  /**
   * Asks a server how it lets people in (D-473): an `initialize` without credentials. It answers
   * (no sign-in), refuses and describes a browser sign-in, or just refuses (a key).
   */
  const probe = async (u: URL) => {
    const legacy = u.pathname.endsWith("/sse");
    let res: Response;
    try {
      res = await fetchImpl(u, {
        method: legacy ? "GET" : "POST",
        headers: legacy
          ? { accept: "text/event-stream" }
          : { "content-type": "application/json", accept: "application/json, text/event-stream" },
        body: legacy
          ? undefined
          : JSON.stringify({
              jsonrpc: "2.0",
              id: 1,
              method: "initialize",
              params: {
                protocolVersion: "2025-06-18",
                capabilities: {},
                clientInfo: { name: "Casama", version: "1" },
              },
            }),
        signal: AbortSignal.timeout(10_000),
      });
    } catch (err) {
      throw new ApiError(400, "server_unreachable", `Couldn't reach ${u.host}`, {
        errors: [{ path: "url", message: (err as Error).message.slice(0, 200) }],
      });
    }
    await res.body?.cancel().catch(() => undefined);
    if (res.ok) return { auth: "none" as const };
    if (res.status !== 401 && res.status !== 403)
      throw new ApiError(
        400,
        "not_a_server",
        `${u.host} didn't answer like an MCP server (HTTP ${res.status})`,
      );
    try {
      const info = await discoverOAuthServerInfo(u, { fetchFn: fetchImpl as never });
      const metadata = info.authorizationServerMetadata;
      if (metadata?.authorization_endpoint && customServerUrl(metadata.authorization_endpoint))
        return {
          auth: "oauth" as const,
          signInHost: new URL(metadata.authorization_endpoint).host,
          registers:
            !!metadata.registration_endpoint ||
            metadata.client_id_metadata_document_supported === true,
        };
    } catch {
      // No sign-in described: it wants a key.
    }
    return { auth: "key" as const };
  };

  /** The catalog app whose server is at this address, if any. */
  const appAt = async (u: URL, orgId: string) => {
    const key = serverKey(u);
    return (
      (await currentCatalog(orgId)).find((a) => {
        try {
          return !a.provider && serverKey(new URL(a.url)) === key;
        } catch {
          return false;
        }
      }) ?? null
    );
  };

  /**
   * Starts a browser sign-in the MCP way: discovery, a client (registered here, Casama's client
   * document, or one the admin set up), PKCE, and a flow row the callback finishes.
   */
  const startOAuth = async (
    c: Context<AppEnv>,
    a: CatalogApp,
    o: {
      orgId: string;
      sub: string;
      email?: unknown;
      name: string;
      config: Record<string, unknown>;
      integrationId?: string | null;
      returnToApp?: boolean;
    },
  ) => {
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
      // A server outside the catalog (D-473): Casama's client document where the server reads
      // those and this API is public, else it registers itself.
      const customCimd =
        a.id === CUSTOM_APP &&
        metadata?.client_id_metadata_document_supported === true &&
        apiBase(c).startsWith("https://");
      if (!client && (a.oauthClient === "cimd" || customCimd)) client = { client_id: cimdUrl(c) };
      if (!client) {
        if (!metadata?.registration_endpoint)
          throw new Error(
            a.id === CUSTOM_APP
              ? `${a.name} doesn't let new apps sign in by themselves; connect it with a key instead`
              : `${a.name} doesn't allow automatic sign-up; an admin must register an OAuth client`,
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
      // A server nobody checked names its own sign-in page, and the app opens it: https only.
      if (a.id === CUSTOM_APP && !customServerUrl(authorizationUrl.toString()))
        throw new Error("its sign-in page isn't an https address");
      // Google only issues a refresh token when asked for offline access.
      // Each Google app is its own connection with only its own scopes (no incremental grants,
      // which would widen every token to all the Google apps connected before).
      if (isGoogleApp(a)) {
        authorizationUrl.searchParams.set("access_type", "offline");
        authorizationUrl.searchParams.set("prompt", "consent");
        // The account they signed in to Casama with, so Google skips its account chooser (D-204).
        if (typeof o.email === "string" && o.email)
          authorizationUrl.searchParams.set("login_hint", o.email);
      }
      const [flow] = await db.execute<{ id: string }>(sql`
      insert into public.integration_oauth_flows (state, org_id, created_by, app_id, name, config, oauth, integration_id)
      values (${state}, ${o.orgId}::uuid, ${o.sub}::uuid, ${a.id}, ${o.name}, ${JSON.stringify(o.config)}::jsonb,
        ${JSON.stringify({
          auth_server: String(info.authorizationServerUrl),
          metadata,
          client,
          code_verifier: codeVerifier,
          redirect_uri: redirectUri(c),
          resource,
          ...(o.returnToApp ? { return_to_app: true } : {}),
        })}::jsonb, ${o.integrationId ?? null})
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
  };

  // ------------------------------------------------------------------ connect

  app.openapi(routes.connectApp, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const body = c.req.valid("json");
    const a = await findApp(body.app_id, body.org_id);
    if (!a) throw new ApiError(404, "app_not_found", "No such app");
    if (!(await isAdmin(db, claims, body.org_id)))
      throw new ApiError(403, "forbidden", "Only owners and admins can connect apps");
    // Composio's managed sign-in only while the server's Composio is on, even for apps that list it.
    if (
      body.method === "managed"
        ? !(a.composio && (await serverComposio()))
        : !a.auth.includes(body.method)
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
      let secret = body.method === "api_key" ? (body.api_key ?? null) : null;
      if (body.method === "api_key" && a.apiKey?.serverUrl) {
        // The pasted value is the person's server URL with its key in it (Zoho MCP).
        const u = appServerUrl(body.api_key ?? "", a.apiKey.serverUrl.hosts);
        if (!u)
          throw new ApiError(400, "validation_failed", `That isn't a ${a.name} MCP server URL`, {
            errors: [{ path: "api_key", message: `Paste the URL from ${a.apiKey.url}` }],
          });
        config.url = u.origin;
        config.url_in_secret = true;
        secret = u.toString();
      }
      const integration = await saveConnection({
        orgId: body.org_id,
        createdBy: claims.sub,
        app: a,
        name,
        config,
        secret,
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
    if (a.provider === "zoho") {
      // Casama's own Zoho sign-in (D-350): Zoho has no MCP discovery; its accounts server and
      // Casama's client are known. The sign-in starts on the US server, which hands people in
      // other data centres to theirs; the callback says which.
      const client = clients[a.id] as OAuthClient;
      const start = env.ZOHO_ACCOUNTS_URL.replace(/\/$/, "");
      const state = randomBytes(24).toString("base64url");
      const verifier = randomBytes(32).toString("base64url");
      const challenge = createHash("sha256").update(verifier).digest("base64url");
      const url = new URL(`${start}/oauth/v2/auth`);
      url.search = new URLSearchParams({
        response_type: "code",
        client_id: client.client_id,
        scope: ZOHO_SCOPES,
        redirect_uri: redirectUri(c),
        access_type: "offline",
        prompt: "consent",
        state,
        code_challenge: challenge,
        code_challenge_method: "S256",
      }).toString();
      const [flow] = await db.execute<{ id: string }>(sql`
        insert into public.integration_oauth_flows (state, org_id, created_by, app_id, name, config, oauth, integration_id)
        values (${state}, ${body.org_id}::uuid, ${claims.sub}::uuid, ${a.id}, ${name},
          ${JSON.stringify({ ...config, provider: "zoho" })}::jsonb,
          ${JSON.stringify({
            auth_server: start,
            client,
            code_verifier: verifier,
            redirect_uri: redirectUri(c),
            ...(body.return_to_app ? { return_to_app: true } : {}),
          })}::jsonb, ${body.integration_id ?? null})
        returning id`);
      return c.json(
        { status: "authorize" as const, authorize_url: url.toString(), flow_id: flow!.id },
        200,
      );
    }
    return startOAuth(c, a, {
      orgId: body.org_id,
      sub: claims.sub,
      email: claims.email,
      name,
      config,
      integrationId: body.integration_id,
      returnToApp: body.return_to_app,
    });
  });

  // ------------------------------------------- servers outside the catalog (D-473)

  app.openapi(routes.probeServer, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const body = c.req.valid("json");
    if (!(await isAdmin(db, claims, body.org_id)))
      throw new ApiError(403, "forbidden", "Only owners and admins can connect apps");
    const u = customServerUrl(body.url);
    if (!u) throw new ApiError(400, "validation_failed", "Use an https address");
    const known = await appAt(u, body.org_id);
    if (known) return c.json({ auth: "none" as const, host: u.host, app_id: known.id }, 200);
    const p = await probe(u);
    return c.json(
      {
        auth: p.auth,
        host: u.host,
        ...(p.auth === "oauth"
          ? {
              ...(p.signInHost !== u.host ? { sign_in_host: p.signInHost } : {}),
              oauth_available: secureRedirect(c) && p.registers,
            }
          : {}),
      },
      200,
    );
  });

  app.openapi(routes.connectServer, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const body = c.req.valid("json");
    if (!(await isAdmin(db, claims, body.org_id)))
      throw new ApiError(403, "forbidden", "Only owners and admins can connect apps");
    const u = customServerUrl(body.url);
    if (!u) throw new ApiError(400, "validation_failed", "Use an https address");
    // An address with a query holds its own key, like one the person says does: it goes to Vault.
    const privateUrl = body.private_url === true || u.search !== "";
    if (privateUrl && body.method !== "none")
      throw new ApiError(
        400,
        "validation_failed",
        "An address that holds its own key connects as it is, without a sign-in or another key",
      );
    if (body.method === "api_key" && !body.api_key)
      throw new ApiError(400, "validation_failed", "Paste the key first", {
        errors: [{ path: "api_key", message: "Required" }],
      });
    if (body.bot_id) {
      const [bot] = await db.execute<{ id: string }>(
        sql`select id from public.bots where id = ${body.bot_id}::uuid and org_id = ${body.org_id}::uuid`,
      );
      if (!bot) throw new ApiError(404, "bot_not_found", "Bot not found");
    }
    const [count] = await db.execute<{ n: number }>(sql`
      select count(*)::int as n from public.integrations
      where org_id = ${body.org_id}::uuid and config ->> 'unverified' = 'true'`);
    if ((count?.n ?? 0) >= CHAT_SERVER_LIMIT)
      throw new ApiError(
        400,
        "server_limit",
        `This workspace already has ${CHAT_SERVER_LIMIT} servers added this way. Remove one first.`,
      );
    const label = body.name.trim();
    const a = customApp(label, u.toString());
    const name = await freeName(body.org_id, serverSlug(label));
    const config: Record<string, unknown> = {
      ...(privateUrl ? { url: u.origin, url_in_secret: true } : { url: u.toString() }),
      auth: body.method,
      label,
      unverified: true,
      ...(body.method === "api_key" && body.auth_header ? { auth_header: body.auth_header } : {}),
      ...(body.bot_id ? { added_in_chat_by: body.bot_id } : {}),
    };
    await db.execute(sql`
      insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, metadata)
      values (${body.org_id}::uuid, 'user', ${claims.sub}::uuid, 'integration.connect_started', 'integration',
        ${JSON.stringify({ host: u.host, method: body.method, bot_id: body.bot_id ?? null })}::jsonb)`);
    if (body.method === "oauth") {
      if (!secureRedirect(c))
        throw new ApiError(
          400,
          "oauth_unavailable",
          `${label} sign-in needs this server to have a public https address (PUBLIC_API_URL).`,
        );
      return startOAuth(c, a, {
        orgId: body.org_id,
        sub: claims.sub,
        name,
        config,
        returnToApp: body.return_to_app,
      });
    }
    const integration = await saveConnection({
      orgId: body.org_id,
      createdBy: claims.sub,
      app: a,
      name,
      config,
      secret: privateUrl ? u.toString() : body.method === "api_key" ? (body.api_key ?? null) : null,
    });
    if ((integration.status as string) === "error") {
      // A server that never answered leaves nothing behind (and no dead tools on the bot).
      const [gone] = await db.execute<{ vault_secret_id: string | null }>(
        sql`delete from public.integrations where id = ${integration.id}::uuid returning vault_secret_id`,
      );
      if (gone?.vault_secret_id)
        await db.execute(sql`delete from vault.secrets where id = ${gone.vault_secret_id}::uuid`);
      return c.json(
        { status: "error" as const, error: integration.error ?? "Couldn't connect" },
        200,
      );
    }
    return c.json({ status: "connected" as const, integration }, 200);
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
    // The callback holds the flow while it trades the code and lists the server's tools, which
    // takes a few seconds: still pending, not an error (the app showed "failed" for a connection
    // that then worked, and a second Connect made a duplicate).
    if (flow.status === "error" && flow.error === FLOW_IN_PROGRESS)
      return c.json({ status: "pending" as const }, 200);
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
      update public.integration_oauth_flows set status = 'error', error = ${FLOW_IN_PROGRESS}
      where state = ${state} and status = 'pending' and expires_at > now()
      returning id, org_id, created_by, app_id, name, config, oauth, integration_id`);
    const a = !flow
      ? null
      : flow.app_id === CUSTOM_APP
        ? customApp(String(flow.config.label ?? "Server"), String(flow.config.url))
        : await findApp(flow.app_id, flow.org_id);
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
    if (a.provider === "zoho") {
      try {
        const { secret, config } = await finishZohoSignIn({
          fetch: fetchImpl,
          code,
          oauth: flow.oauth,
          accountsServer: c.req.query("accounts-server") ?? flow.oauth.auth_server,
          configured: env.ZOHO_ACCOUNTS_URL,
        });
        const integration = await saveConnection({
          orgId: flow.org_id,
          createdBy: flow.created_by,
          app: a,
          name: flow.name,
          config: { ...flow.config, ...config },
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
        deps.logger.warn("zoho callback failed", { error: (err as Error).message });
        captureError(err, { service: "casama-api", step: "oauth-callback", app_id: a.id });
        return fail(`Couldn't finish connecting ${a.name}: ${(err as Error).message}`);
      }
    }
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
:root{color-scheme:light dark}body{margin:0;min-height:100vh;display:grid;place-items:center;font:16px/1.5 system-ui,sans-serif;background:#fff;color:#18181b}
@media (prefers-color-scheme:dark){body{background:#1c1c1e;color:#f4f4f5}}
main{max-width:420px;margin:24px;padding:32px;text-align:center}
.icon{width:56px;height:56px;border-radius:50%;margin:0 auto 16px;display:grid;place-items:center;font-size:28px;color:#fff;background:${ok ? "#22a06b" : "#d9534f"}}
h1{font-size:20px;margin:0 0 8px}</style></head><body><main><div class="icon">${ok ? "&#10003;" : "!"}</div>
<h1>${ok ? "All set" : "Something went wrong"}</h1><p>${esc}</p></main>
<script>${ok ? "setTimeout(function(){window.close()},1500)" : ""}</script></body></html>`;
}
