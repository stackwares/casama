import { createHash } from "node:crypto";
import { once } from "node:events";
import { createServer, type IncomingMessage, type Server, type ServerResponse } from "node:http";
import type { AddressInfo } from "node:net";
import { loadIntegration, parseOAuthSecret } from "@kasama/agent";
import type { CatalogApp } from "@kasama/domain";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp.js";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

/**
 * A fake vendor: an MCP server behind OAuth 2.1 the way the MCP authorization spec describes it
 * (protected-resource metadata, authorization-server metadata, dynamic client registration, PKCE,
 * refresh tokens). Tokens expire after a second so the refresh path runs too.
 */
let vendor: Server;
let base = "";
const issued = { challenge: "", registered: 0, refreshed: 0 };
const valid = new Set(["key-123"]);

async function startVendor() {
  const json = (
    res: ServerResponse,
    status: number,
    data: unknown,
    headers: Record<string, string> = {},
  ) =>
    res
      .writeHead(status, { "content-type": "application/json", ...headers })
      .end(JSON.stringify(data));
  vendor = createServer(async (req: IncomingMessage, res) => {
    const chunks: Buffer[] = [];
    for await (const c of req) chunks.push(c as Buffer);
    const raw = Buffer.concat(chunks).toString();
    const url = new URL(req.url ?? "/", base);
    const p = url.pathname;
    if (p.startsWith("/.well-known/oauth-protected-resource"))
      return json(res, 200, {
        resource: `${base}/mcp`,
        authorization_servers: [base],
        scopes_supported: ["read"],
      });
    if (p === "/.well-known/oauth-authorization-server")
      return json(res, 200, {
        issuer: base,
        authorization_endpoint: `${base}/authorize`,
        token_endpoint: `${base}/token`,
        registration_endpoint: `${base}/register`,
        response_types_supported: ["code"],
        grant_types_supported: ["authorization_code", "refresh_token"],
        code_challenge_methods_supported: ["S256"],
        token_endpoint_auth_methods_supported: ["none"],
      });
    if (p === "/register") {
      issued.registered++;
      const body = JSON.parse(raw);
      return json(res, 201, {
        ...body,
        client_id: "kasama-client",
        token_endpoint_auth_method: "none",
      });
    }
    if (p === "/authorize") {
      // The person signs in and approves; the vendor sends the browser back with a code.
      issued.challenge = url.searchParams.get("code_challenge") ?? "";
      const back = new URL(url.searchParams.get("redirect_uri") ?? "");
      back.searchParams.set("code", "the-code");
      back.searchParams.set("state", url.searchParams.get("state") ?? "");
      return res.writeHead(302, { location: back.toString() }).end();
    }
    if (p === "/token") {
      const form = new URLSearchParams(raw);
      if (form.get("grant_type") === "authorization_code") {
        const verifier = form.get("code_verifier") ?? "";
        const challenge = createHash("sha256").update(verifier).digest("base64url");
        if (form.get("code") !== "the-code" || challenge !== issued.challenge)
          return json(res, 400, { error: "invalid_grant" });
        valid.add("at-1");
        return json(res, 200, {
          access_token: "at-1",
          refresh_token: "rt-1",
          expires_in: 1,
          token_type: "Bearer",
        });
      }
      if (form.get("grant_type") === "refresh_token" && form.get("refresh_token") === "rt-1") {
        issued.refreshed++;
        valid.add("at-2");
        return json(res, 200, { access_token: "at-2", expires_in: 3600, token_type: "Bearer" });
      }
      return json(res, 400, { error: "invalid_grant" });
    }
    if (p === "/mcp") {
      const token = (req.headers.authorization ?? "").replace(/^Bearer /, "");
      if (!valid.has(token))
        return json(
          res,
          401,
          { error: "invalid_token" },
          {
            "www-authenticate": `Bearer resource_metadata="${base}/.well-known/oauth-protected-resource/mcp"`,
          },
        );
      const server = new McpServer({ name: "acme", version: "1.0.0" });
      server.registerTool(
        "whoami",
        { description: "Who the token belongs to", annotations: { readOnlyHint: true } },
        async () => ({
          content: [{ type: "text", text: `token ${token}` }],
        }),
      );
      const transport = new StreamableHTTPServerTransport({ sessionIdGenerator: undefined });
      res.on("close", () => void transport.close());
      await server.connect(transport);
      return transport.handleRequest(req, res, raw ? JSON.parse(raw) : undefined);
    }
    json(res, 404, {});
  }).listen(0, "127.0.0.1");
  await once(vendor, "listening");
  base = `http://127.0.0.1:${(vendor.address() as AddressInfo).port}`;
}

let h: Harness;
let owner: { id: string; token: string };
let orgId: string;

beforeAll(async () => {
  await startVendor();
  const acme: CatalogApp = {
    id: "acme",
    name: "Acme",
    description: "A test vendor",
    category: "developer",
    color: "123456",
    homepage: base,
    url: `${base}/mcp`,
    auth: ["oauth", "api_key"],
    oauthClient: "dcr",
    apiKey: { label: "API key", url: base, steps: ["Make one"] },
    capabilities: ["Say who you are"],
  };
  const locked: CatalogApp = {
    ...acme,
    id: "locked",
    name: "Locked",
    oauthClient: "preregistered",
  };
  h = await startHarness({ apps: { catalog: [acme, locked] } });
  owner = await h.user("apps-owner@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "Apps" } }),
    )
  ).id;
});
afterAll(async () => {
  await h?.stop();
  vendor?.close();
});

describe("built-in app connections", () => {
  it("lists the catalog with the redirect address and which apps can sign in", async () => {
    const cat = await j(await h.request("/v1/apps", { token: owner.token }));
    expect(cat.redirect_uri).toMatch(/\/oauth\/callback$/);
    const byId = Object.fromEntries(cat.apps.map((a: { id: string }) => [a.id, a]));
    expect(byId.acme.oauth_available).toBe(true);
    // Apps that need an admin-registered client say so until one is configured.
    expect(byId.locked.oauth_available).toBe(false);
    const start = await h.request("/v1/apps/connect", {
      method: "POST",
      token: owner.token,
      json: { org_id: orgId, app_id: "locked", method: "oauth" },
    });
    expect(start.status).toBe(400);
  });

  it("connects with OAuth: registers a client, signs in with PKCE, lists tools, refreshes tokens", async () => {
    const start = await j(
      await h.request("/v1/apps/connect", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, app_id: "acme", method: "oauth" },
      }),
    );
    expect(start.status).toBe("authorize");
    expect(issued.registered).toBe(1);
    const authorize = new URL(start.authorize_url);
    expect(authorize.searchParams.get("code_challenge_method")).toBe("S256");
    expect(authorize.searchParams.get("resource")).toBe(`${base}/mcp`);

    // Still waiting while the person is on the vendor's page.
    expect(
      (await j(await h.request(`/v1/apps/connect/${start.flow_id}`, { token: owner.token })))
        .status,
    ).toBe("pending");

    const redirect = await fetch(authorize, { redirect: "manual" });
    const back = new URL(redirect.headers.get("location") ?? "");
    const page = await h.request(`${back.pathname}${back.search}`);
    expect(page.status).toBe(200);
    expect(await page.text()).toContain("Acme is connected");

    const done = await j(
      await h.request(`/v1/apps/connect/${start.flow_id}`, { token: owner.token }),
    );
    expect(done.status).toBe("connected");
    expect(done.integration).toMatchObject({
      app_id: "acme",
      auth: "oauth",
      status: "ok",
      name: "acme",
    });
    expect(done.integration.tools.map((t: { name: string }) => t.name)).toEqual(["whoami"]);
    expect(done.integration.tools[0].risk).toBe("low");

    // The token lasts a second; loading the connection refreshes it and saves the new one.
    await new Promise((r) => setTimeout(r, 1100));
    const rec = await loadIntegration(h.deps.db, done.integration.id);
    expect(parseOAuthSecret(rec?.secret)?.access_token).toBe("at-2");
    expect(parseOAuthSecret(rec?.secret)?.refresh_token).toBe("rt-1");
    expect(issued.refreshed).toBe(1);

    // The sign-in link works once.
    const again = await h.request(`${back.pathname}${back.search}`);
    expect(again.status).toBe(400);
  });

  it("connects with an API key, names the second connection apart, and removes it cleanly", async () => {
    const bad = await j(
      await h.request("/v1/apps/connect", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, app_id: "acme", method: "api_key", api_key: "wrong" },
      }),
    );
    expect(bad.status).toBe("error");
    const good = await j(
      await h.request("/v1/apps/connect", {
        method: "POST",
        token: owner.token,
        json: {
          org_id: orgId,
          app_id: "acme",
          method: "api_key",
          api_key: "key-123",
          integration_id: bad.integration.id,
        },
      }),
    );
    expect(good.status).toBe("connected");
    expect(good.integration).toMatchObject({ name: "acme_2", auth: "api_key", status: "ok" });

    const list = await j(
      await h.request(`/v1/integrations?org_id=${orgId}`, { token: owner.token }),
    );
    expect(list.items.map((i: { name: string }) => i.name).sort()).toEqual(["acme", "acme_2"]);

    const patched = await j(
      await h.request(`/v1/integrations/${good.integration.id}`, {
        method: "PATCH",
        token: owner.token,
        json: { risk_overrides: { whoami: "high" } },
      }),
    );
    expect(patched.risk_overrides).toEqual({ whoami: "high" });

    const [secretRow] = await h.tdb.admin<{ vault_secret_id: string }[]>`
      select vault_secret_id from public.integrations where id = ${good.integration.id}`;
    const del = await h.request(`/v1/integrations/${good.integration.id}`, {
      method: "DELETE",
      token: owner.token,
    });
    expect(del.status).toBe(200);
    const [countRow] = await h.tdb.admin<
      { n: number }[]
    >`select count(*)::int as n from vault.secrets where id = ${secretRow?.vault_secret_id ?? ""}`;
    expect(countRow?.n).toBe(0);
  });

  it("only lets admins connect apps", async () => {
    const stranger = await h.user("apps-stranger@example.com");
    const res = await h.request("/v1/apps/connect", {
      method: "POST",
      token: stranger.token,
      json: { org_id: orgId, app_id: "acme", method: "none" },
    });
    expect(res.status).toBe(403);
  });
});
