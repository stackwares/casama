/**
 * Hosted MCP endpoint (SPEC: Post-v1 roadmap → Hosted MCP endpoint; D-117). The same tools as the
 * stdio `@casama/mcp` server, over Streamable HTTP at /mcp. Callers bring an OAuth access token
 * (from the small authorization server below: metadata, dynamic client registration, PKCE codes
 * approved in the app), a workspace API key, or a Casama sign-in. Every call runs as that person,
 * so the bot's approvals, rules and budgets apply.
 */
import { createHash, randomBytes } from "node:crypto";
import { routes } from "@casama/contracts";
import { type JwtClaims, withUserSession } from "@casama/db";
import { CasamaApi, createCasamaMcpServer } from "@casama/mcp";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { WebStandardStreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/webStandardStreamableHttp.js";
import { sql } from "drizzle-orm";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { iso } from "../util.ts";

const hash = (t: string) => createHash("sha256").update(t).digest("hex");
const token = (prefix: string) => `${prefix}${randomBytes(32).toString("base64url")}`;
const ACCESS_TTL_S = 3600;
const REFRESH_TTL_DAYS = 60;

/** The in-process environment a tool call carries: who it acts as. Outside requests can't set it. */
export type InProcessEnv = { casamaClaims?: JwtClaims };

const claimsOf = (c: { get(k: "claims"): JwtClaims | undefined }) => {
  const claims = c.get("claims");
  if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
  return claims;
};

export function registerMcpRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;
  const base = (c: { req: { url: string } }) =>
    (deps.env.PUBLIC_API_URL ?? new URL(c.req.url).origin).replace(/\/$/, "");

  // --- the endpoint --------------------------------------------------------------

  /** Who a bearer token acts as, and in which workspace (null: a Casama sign-in, all workspaces). */
  const authorize = async (
    header: string | undefined,
  ): Promise<{ claims: JwtClaims; orgId: string | null } | null> => {
    if (!header?.startsWith("Bearer ")) return null;
    const t = header.slice(7).trim();
    if (t.startsWith("kmcp_") || t.startsWith("ksk_")) {
      const [row] = await db.execute<{ user_id: string; org_id: string }>(sql`
        update public.mcp_tokens set last_used_at = now()
        where token_hash = ${hash(t)} and kind in ('access', 'api_key') and revoked_at is null and (expires_at is null or expires_at > now())
          and exists (select 1 from public.memberships m where m.user_id = mcp_tokens.user_id and m.org_id = mcp_tokens.org_id)
        returning user_id, org_id`);
      return row
        ? { claims: { sub: row.user_id, role: "authenticated", aal: "aal1" }, orgId: row.org_id }
        : null;
    }
    try {
      return { claims: await deps.verifyToken(t), orgId: null };
    } catch {
      return null;
    }
  };

  app.all("/mcp", async (c) => {
    const who = await authorize(c.req.header("authorization"));
    if (!who) {
      c.header(
        "www-authenticate",
        `Bearer resource_metadata="${base(c)}/.well-known/oauth-protected-resource"`,
      );
      return c.json(
        { error: "unauthorized", error_description: "Connect with OAuth or a workspace API key" },
        401,
      );
    }
    // Tool calls reach the API in-process, as this person (the API's own checks apply).
    const api = new CasamaApi({
      apiUrl: "http://in-process",
      token: "in-process",
      fetch: (async (url: string | URL, init?: RequestInit) => {
        const u = new URL(String(url));
        return app.request(`${u.pathname}${u.search}`, init, {
          casamaClaims: who.claims,
        } satisfies InProcessEnv);
      }) as typeof fetch,
    });
    const server = createCasamaMcpServer(api, {
      pollMs: deps.env.NODE_ENV === "test" ? 100 : 1000,
      scopeOrgId: who.orgId ?? undefined,
      canDecideApprovals: async () => {
        if (!who.orgId) return true; // a full Casama sign-in decides like the app does
        const [o] = await db.execute<{ ok: boolean }>(
          sql`select mcp_decide_approvals as ok from public.organizations where id = ${who.orgId}::uuid`,
        );
        return o?.ok === true;
      },
    });
    const transport = new WebStandardStreamableHTTPServerTransport({
      sessionIdGenerator: undefined,
      enableJsonResponse: true,
    });
    await server.connect(transport);
    try {
      return await transport.handleRequest(c.req.raw);
    } finally {
      void server.close().catch(() => {});
    }
  });

  // --- OAuth (MCP authorization: metadata, dynamic client registration, PKCE) -----

  app.get("/.well-known/oauth-protected-resource", (c) =>
    c.json({
      resource: `${base(c)}/mcp`,
      authorization_servers: [base(c)],
      bearer_methods_supported: ["header"],
    }),
  );
  app.get("/.well-known/oauth-protected-resource/mcp", (c) =>
    c.json({
      resource: `${base(c)}/mcp`,
      authorization_servers: [base(c)],
      bearer_methods_supported: ["header"],
    }),
  );
  app.get("/.well-known/oauth-authorization-server", (c) =>
    c.json({
      issuer: base(c),
      authorization_endpoint: `${base(c)}/oauth/authorize`,
      token_endpoint: `${base(c)}/oauth/token`,
      registration_endpoint: `${base(c)}/oauth/register`,
      response_types_supported: ["code"],
      grant_types_supported: ["authorization_code", "refresh_token"],
      code_challenge_methods_supported: ["S256"],
      token_endpoint_auth_methods_supported: ["none"],
    }),
  );

  const oauthError = (
    c: { json: (b: unknown, s: 400 | 401) => Response },
    error: string,
    description: string,
    status: 400 | 401 = 400,
  ) => c.json({ error, error_description: description }, status);

  app.post("/oauth/register", async (c) => {
    const body = (await c.req.json().catch(() => null)) as {
      client_name?: string;
      redirect_uris?: unknown;
    } | null;
    const uris = Array.isArray(body?.redirect_uris)
      ? body.redirect_uris.filter((u): u is string => typeof u === "string")
      : [];
    const valid =
      uris.length > 0 &&
      uris.length <= 10 &&
      uris.every((u) => {
        try {
          const p = new URL(u);
          return (
            p.protocol === "https:" ||
            p.hostname === "localhost" ||
            p.hostname === "127.0.0.1" ||
            !["http:", "javascript:", "data:"].includes(p.protocol)
          );
        } catch {
          return false;
        }
      });
    if (!valid)
      return oauthError(
        c,
        "invalid_redirect_uri",
        "Give one to ten redirect_uris (https, or localhost)",
      );
    const clientId = `kcl_${randomBytes(16).toString("hex")}`;
    const name = (body?.client_name ?? "AI app").slice(0, 200) || "AI app";
    await db.execute(sql`
      insert into public.mcp_clients (client_id, name, redirect_uris)
      values (${clientId}, ${name}, array(select jsonb_array_elements_text(${JSON.stringify(uris)}::jsonb)))`);
    return c.json(
      {
        client_id: clientId,
        client_name: name,
        redirect_uris: uris,
        token_endpoint_auth_method: "none",
      },
      201,
    );
  });

  app.get("/oauth/authorize", async (c) => {
    const q = c.req.query();
    if (q.response_type !== "code")
      return oauthError(c, "unsupported_response_type", "Only response_type=code");
    if (!q.code_challenge || (q.code_challenge_method ?? "S256") !== "S256")
      return oauthError(c, "invalid_request", "PKCE with S256 is required");
    const [client] = await db.execute<{ redirect_uris: string[] }>(
      sql`select redirect_uris from public.mcp_clients where client_id = ${q.client_id ?? ""}`,
    );
    if (!client) return oauthError(c, "invalid_client", "Unknown client_id");
    if (!q.redirect_uri || !client.redirect_uris.includes(q.redirect_uri))
      return oauthError(c, "invalid_request", "redirect_uri isn't registered");
    const [r] = await db.execute<{ id: string }>(sql`
      insert into public.mcp_auth_requests (client_id, redirect_uri, code_challenge, state)
      values (${q.client_id}, ${q.redirect_uri}, ${q.code_challenge}, ${q.state ?? null}) returning id`);
    // The person approves in the Casama app, signed in, and picks the workspace.
    return c.redirect(`${deps.env.PUBLIC_APP_URL.replace(/\/$/, "")}/oauth/consent/${r?.id}`, 302);
  });

  app.post("/oauth/token", async (c) => {
    const form = await c.req.parseBody().catch(() => ({}) as Record<string, string>);
    const f = form as Record<string, string>;
    const issue = async (userId: string, orgId: string, clientId: string) => {
      const access = token("kmcp_");
      const refresh = token("kmcr_");
      await db.execute(sql`
        insert into public.mcp_tokens (token_hash, kind, user_id, org_id, client_id, expires_at)
        values (${hash(access)}, 'access', ${userId}::uuid, ${orgId}::uuid, ${clientId}, now() + make_interval(secs => ${ACCESS_TTL_S})),
               (${hash(refresh)}, 'refresh', ${userId}::uuid, ${orgId}::uuid, ${clientId}, now() + make_interval(days => ${REFRESH_TTL_DAYS}))`);
      return c.json({
        access_token: access,
        token_type: "Bearer",
        expires_in: ACCESS_TTL_S,
        refresh_token: refresh,
      });
    };
    if (f.grant_type === "authorization_code") {
      if (!f.code || !f.code_verifier)
        return oauthError(c, "invalid_request", "code and code_verifier are required");
      const [r] = await db.execute<{
        client_id: string;
        redirect_uri: string;
        code_challenge: string;
        user_id: string;
        org_id: string;
      }>(sql`
        update public.mcp_auth_requests set status = 'used'
        where code_hash = ${hash(f.code)} and status = 'approved' and expires_at > now()
        returning client_id, redirect_uri, code_challenge, user_id, org_id`);
      if (!r) return oauthError(c, "invalid_grant", "The code is invalid, used or expired");
      if (f.client_id && f.client_id !== r.client_id)
        return oauthError(c, "invalid_grant", "The code was issued to another client");
      if (f.redirect_uri && f.redirect_uri !== r.redirect_uri)
        return oauthError(c, "invalid_grant", "redirect_uri doesn't match");
      const challenge = createHash("sha256").update(f.code_verifier).digest("base64url");
      if (challenge !== r.code_challenge)
        return oauthError(c, "invalid_grant", "PKCE check failed");
      return issue(r.user_id, r.org_id, r.client_id);
    }
    if (f.grant_type === "refresh_token") {
      const [t] = await db.execute<{ user_id: string; org_id: string; client_id: string }>(sql`
        update public.mcp_tokens set revoked_at = now()
        where token_hash = ${hash(f.refresh_token ?? "")} and kind = 'refresh' and revoked_at is null and expires_at > now()
        returning user_id, org_id, client_id`);
      if (!t) return oauthError(c, "invalid_grant", "The refresh token is invalid or expired");
      return issue(t.user_id, t.org_id, t.client_id);
    }
    return oauthError(c, "unsupported_grant_type", "Use authorization_code or refresh_token");
  });

  // --- consent (the app) --------------------------------------------------------

  app.openapi(routes.getMcpAuthRequest, async (c) => {
    claimsOf(c);
    const [r] = await db.execute<{
      id: string;
      name: string;
      redirect_uri: string;
      expires_at: string;
    }>(sql`
      select r.id, k.name, r.redirect_uri, r.expires_at from public.mcp_auth_requests r join public.mcp_clients k on k.client_id = r.client_id
      where r.id = ${c.req.valid("param").id}::uuid and r.status = 'pending' and r.expires_at > now()`);
    if (!r)
      throw new ApiError(
        404,
        "request_not_found",
        "This connection request expired. Start again from the AI app.",
      );
    return c.json(
      {
        id: r.id,
        client_name: r.name,
        redirect_host: new URL(r.redirect_uri).host,
        expires_at: iso(r.expires_at),
      },
      200,
    );
  });

  app.openapi(routes.decideMcpAuthRequest, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    const { org_id, approve } = c.req.valid("json");
    const [member] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ ok: boolean }>(sql`select public.is_member(${org_id}::uuid) as ok`),
    );
    if (!member?.ok) throw new ApiError(403, "forbidden", "Pick a workspace you belong to");
    const code = token("kco_");
    const [r] = await db.execute<{ redirect_uri: string; state: string | null }>(sql`
      update public.mcp_auth_requests set status = ${approve ? "approved" : "denied"}, user_id = ${claims.sub}::uuid, org_id = ${org_id}::uuid,
        code_hash = ${approve ? hash(code) : null}, expires_at = now() + interval '5 minutes'
      where id = ${id}::uuid and status = 'pending' and expires_at > now() returning redirect_uri, state`);
    if (!r)
      throw new ApiError(
        409,
        "request_closed",
        "This connection request was already answered or expired",
      );
    const u = new URL(r.redirect_uri);
    if (approve) u.searchParams.set("code", code);
    else {
      u.searchParams.set("error", "access_denied");
    }
    if (r.state) u.searchParams.set("state", r.state);
    await db.execute(sql`insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, metadata)
      values (${org_id}::uuid, 'user', ${claims.sub}::uuid, ${approve ? "mcp.connected" : "mcp.refused"}, 'mcp_client', ${JSON.stringify({ request: id })}::jsonb)`);
    return c.json({ redirect_url: u.toString() }, 200);
  });

  // --- workspace API keys -------------------------------------------------------

  const admin = async (claims: JwtClaims, orgId: string) => {
    const [r] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ ok: boolean }>(sql`select public.has_role(${orgId}::uuid, 'admin') as ok`),
    );
    if (!r?.ok) throw new ApiError(403, "forbidden", "Only owners and admins manage API keys");
  };

  app.openapi(routes.listMcpKeys, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    await admin(claims, id);
    const rows = await db.execute<{
      id: string;
      name: string;
      hint: string;
      last_used_at: string | null;
      created_at: string;
    }>(sql`
      select id, coalesce(name, '') as name, coalesce(hint, '') as hint, last_used_at, created_at from public.mcp_tokens
      where org_id = ${id}::uuid and kind = 'api_key' and revoked_at is null order by created_at desc`);
    return c.json(
      {
        items: rows.map((r) => ({
          ...r,
          last_used_at: r.last_used_at ? iso(r.last_used_at) : null,
          created_at: iso(r.created_at),
        })),
      },
      200,
    );
  });

  app.openapi(routes.createMcpKey, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    await admin(claims, id);
    const key = token("ksk_");
    const [row] = await db.execute<{ id: string; created_at: string }>(sql`
      insert into public.mcp_tokens (token_hash, kind, user_id, org_id, name, hint)
      values (${hash(key)}, 'api_key', ${claims.sub}::uuid, ${id}::uuid, ${c.req.valid("json").name}, ${key.slice(-4)}) returning id, created_at`);
    await db.execute(sql`insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id)
      values (${id}::uuid, 'user', ${claims.sub}::uuid, 'mcp.key_created', 'mcp_key', ${row?.id}::uuid)`);
    return c.json(
      {
        id: row?.id as string,
        name: c.req.valid("json").name,
        hint: key.slice(-4),
        last_used_at: null,
        created_at: iso(row?.created_at as string),
        key,
        mcp_url: `${base(c)}/mcp`,
      },
      201,
    );
  });

  app.openapi(routes.revokeMcpKey, async (c) => {
    const claims = claimsOf(c);
    const { id, key_id } = c.req.valid("param");
    await admin(claims, id);
    const rows = await db.execute<{ id: string }>(sql`
      update public.mcp_tokens set revoked_at = now() where id = ${key_id}::uuid and org_id = ${id}::uuid and kind = 'api_key' and revoked_at is null returning id`);
    if (!rows[0]) throw new ApiError(404, "key_not_found", "Key not found");
    return c.json({ revoked: key_id }, 200);
  });
}
